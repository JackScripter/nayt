#!/bin/bash
# v0.2
##### COLOR CODE #####
declare -r DEF='\e[0m'          # Default
declare -r RED='\e[31m'         # Red
declare -r GREEN='\e[92m'       # Green
######################

# Check first arg
function Help() {
        echo "To create an A record and create a PTR record in reverse zone automatically, use the first synthax."
        echo "Synthax 1: ./nayt.sh -r zone.ca Host_IP Hostname"
        echo "The zone file name MUST BE the same as the domain name. The FQDN will be automatically set to HOSTNAME.ZONENAME. so don't use FQDN as hostname."
}
if [[ "$1" =~ '.' ]]; then ZONE="$1"; RECORD="$2"; HOST="$3"; BIND="$4"; MODE=1                                 # Don't update reverse zone.
elif [[ "$1" == "-r" ]]; then ZONE="$2"; ZONE_REV="${ZONE}.rev"; RECORD='A'; HOST="$3"; BIND="$4"; MODE=2       # Update reverse zone.
elif [[ "$1" =~ "-h" ]]; then Help
else echo -e "INVALID SYNTHAX\nSynthax 1: nayt.sh -r zone.ca IPv4 hostname\nSynthax 2: nayt.sh zone.ca [A/MX/CNAME] IP/host bind/FQDN"; fi

possibleOS=`cat /etc/os-release | grep '^ID' | cut -d'=' -f2`
if [[ "$possibleOS" =~ "centos" ]]; then declare -r OS="centos"; declare -r ZONE_PATH='/var/named'
elif [[ "$possibleOS" =~ "debian" ]]; then declare -r OS="debian"; declare -r ZONE_PATH='/etc/bind'; fi

function Error() {
        case $1 in
                1) echo -e "${RED}ERROR - Forwarding zone file $ZONE_PATH/$ZONE cannot be found.${DEF}";;
                2) echo -e "${RED}ERROR - Reverse zone file $ZONE_PATH/$ZONE_REV cannot be found.${DEF}";;
                3) echo -e "${RED}ERROR - Invalid IPv4 address.${DEF}";;
        esac
        exit 0
}
if ! [ -f $ZONE_PATH/$ZONE ]; then Error 1; fi
if ! [ -f $ZONE_PATH/$ZONE_REV ] && [[ "$1" == "-r" ]]; then Error 2; fi
function VerifyIP() {
        IFS='.' inarr=(${1});
        appender=''
        for i in {0..3}; do
                if ! [[ ${inarr[i]} =~ $INT ]]; then Error 3 ${inarr[i]}; fi
                if [[ $i == 0 || $i == 3 ]]; then
                        if [[ ${inarr[i]} -le 0 || ${inarr[i]} -ge 255 ]]; then Error 3; fi
                fi # Check first and last digit, can't be 0 or 255
                if [[ $i == 1 || $i == 2 ]]; then
                        if [[ ${inarr[i]} -lt 0 || ${inarr[i]} -gt 255 ]]; then Error 3; fi
                fi # Allow the 2nd and 3th digit to be 0 or 255
                appender+=${inarr[$i]}.
        done # Check IP validation
}
function ForwardReverse() {
        # Forwarding
        echo -e "${BIND}.${ZONE}.\tIN\tA\t$HOST" >> $ZONE_PATH/$ZONE && echo -e "Forwarding file\t[$GREEN OK$DEF ]" || echo -e "Forwarding file\t[$RED FAILED$DEF ]" # Create A record in forwarding file zone
        LINE=`grep -ni "; serial" $ZONE_PATH/$ZONE | cut -d':' -f1` # Line that contain the serial
        SERIAL=`grep -ni "; serial" $ZONE_PATH/$ZONE | sed -r 's/([^0-9]*([0-9]*)){1}.*/\1/'` #0.2
        NEWSERIAL=$(($SERIAL+1))
        sed -i "${LINE}s/$SERIAL/$NEWSERIAL/" $ZONE_PATH/$ZONE
        # Reverse
        hostIP=`echo $HOST | cut -d'.' -f4`
        echo -e "$hostIP\tIN\tPTR\t${BIND}.${ZONE}." >> $ZONE_PATH/$ZONE_REV && echo -e "Reverse file\t[$GREEN OK$DEF ]" || echo -e "Reverse file\t[$RED FAILED$DEF ]"       # Associate A record to a PTR in reverse zone.
        LINE=`grep -ni "; serial" $ZONE_PATH/$ZONE_REV | cut -d':' -f1` # Line that contain the serial
        SERIAL=`grep -ni "; serial" $ZONE_PATH/$ZONE_REV | sed -r 's/([^0-9]*([0-9]*)){1}.*/\1/'` #0.2
        NEWSERIAL=$(($SERIAL+1))
        sed -i "${LINE}s/$SERIAL/$NEWSERIAL/" $ZONE_PATH/$ZONE_REV
}
function Main() {
        # Synthax 1: nayt.sh -r zone.ca host bind               # Only for A record.
        # Synthax 2: nayt.sh zone.ca [A/MX/CNAME] host bind     # Only for forwarding zone.
        #VerifyIP $HOST
        #IP=${appender::-1} # Remove last character .
        if [[ $MODE == 2 ]]; then ForwardReverse; fi
        #if [[ $MODE == 1 ]]; then
}
Main
