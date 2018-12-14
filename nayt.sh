#!/bin/bash
# v0.3
##### COLOR CODE #####
declare -r DEF='\e[0m'          # Default
declare -r RED='\e[31m'         # Red
declare -r GREEN='\e[92m'       # Green
######################

function Help() {
        echo -e "\nTo create an A record and create a PTR record in reverse zone automatically, use the first syntax.\n"
        echo "Syntax 1: ./nayt.sh -r zone.ca Hostname IP"
        echo "Syntax 2: ./nayt.sh zone.ca [A/CNAME] CName Hostname"
        echo -e "Syntax 3: ./nayt.sh zone.ca MX Hostname\n"
        echo "The zone file name MUST BE the same as the domain name."
        echo "When -r or MX is specified, the FQDN will be automatically set to HOSTNAME.ZONENAME. so don't use FQDN as hostname."
} #0.3
if [[ "$1" =~ '.' ]]; then ZONE="$1"; RECORD="$2"; BIND="$3"; if ! [[ "$RECORD" == "MX" ]]; then HOST="$4"; fi; MODE=1   #0.3: Don't update reverse zone.
elif [[ "$1" == "-r" ]]; then ZONE="$2"; ZONE_REV="${ZONE}.rev"; RECORD='A'; HOST="$4"; BIND="$3"; MODE=2       # Update reverse zone.
elif [[ "$1" =~ "-h" ]]; then Help; exit 1
else Help; exit 1; fi

possibleOS=`cat /etc/os-release | grep '^ID' | cut -d'=' -f2`
if [[ "$possibleOS" =~ "centos" ]]; then declare -r OS="centos"; declare -r ZONE_PATH='/var/named'
elif [[ "$possibleOS" =~ "debian" ]]; then declare -r OS="debian"; declare -r ZONE_PATH='/etc/bind'; fi

function Error() {
        case $1 in
                1) echo -e "${RED}ERROR - Forwarding zone file $ZONE_PATH/$ZONE cannot be found.${DEF}";;
                2) echo -e "${RED}ERROR - Reverse zone file $ZONE_PATH/$ZONE_REV cannot be found.${DEF}";;
                3) echo -e "${RED}ERROR - Invalid record type.${DEF}";;
                4) echo -e "${RED}Dude, I can't write to $ZONE_PATH/$ZONE. Give me access !${DEF}";;
                5) echo -e "${RED}I need to write into $ZONE_PATH/$ZONE_REV but I can't !${DEF}";;
        esac
        exit 1
} #0.3
if ! [ -f $ZONE_PATH/$ZONE ]; then Error 1; fi
if ! [ -f $ZONE_PATH/$ZONE_REV ] && [[ "$1" == "-r" ]]; then Error 2; fi
function IncrementSerial() {
        LINE=`grep -ni "; serial" $1 | cut -d':' -f1` # Line that contain the serial
        SERIAL=`grep -i "; serial" $1 | sed -r 's/([^0-9]*([0-9]*)){1}.*/\1/'`
        NEWSERIAL=$(($SERIAL+1))
        sed -i "${LINE}s/$SERIAL/$NEWSERIAL/" $1
} #0.3
function ForwardReverse() {
        # Forwarding
        #echo -e "$BIND\tIN\tA\t$HOST" >> $ZONE_PATH/$ZONE  # Create A record in forwarding file zone
        echo -e "${BIND}.${ZONE}.\tIN\tA\t$HOST" >> $ZONE_PATH/$ZONE #0.3: Auto add FQDN
        IncrementSerial "$ZONE_PATH/$ZONE"
        # Reverse
        hostIP=`echo $HOST | cut -d'.' -f4`
        echo -e "$hostIP\tIN\tPTR\t${BIND}.${ZONE}." >> $ZONE_PATH/$ZONE_REV       # Associate A record to a PTR in reverse zone.
        IncrementSerial "$ZONE_PATH/$ZONE_REV"
}
function Forward() {
        if [[ "$RECORD" == "CNAME" ]]; then echo -e "$BIND\tIN\tCNAME\t$HOST" >> $ZONE_PATH/$ZONE && IncrementSerial "$ZONE_PATH/$ZONE"
        elif [[ "$RECORD" == "A" ]]; then echo -e "$BIND\tIN\tA\t$HOST" >> $ZONE_PATH/$ZONE && IncrementSerial "$ZONE_PATH/$ZONE"
        elif [[ "$RECORD" == "MX" ]]; then echo -e "\tIN\tMX\t10\t${BIND}.${ZONE}." >> $ZONE_PATH/$ZONE && IncrementSerial "$ZONE_PATH/$ZONE"
        else Error 3; fi
} #0.3
function Main() {
        # Syntax 1: nayt.sh -r zone.ca host bind               # Only for A record.
        # Syntax 2: nayt.sh zone.ca [A/CNAME] host bind        # Only for forwarding zone.
        # Syntax 3: nayt.sh zone.ca MX bind                    # Only for forwarding zone and a MX.
        if ! [ -w "$ZONE_PATH/$ZONE" ]; then Error 4; fi        # Check if file is writable
        if [[ $MODE == 2 ]]; then if ! [ -w "$ZONE_PATH/$ZONE_REV" ]; then Error 5; fi; ForwardReverse
        elif [[ $MODE == 1 ]]; then Forward; fi         #0.3
}
Main
