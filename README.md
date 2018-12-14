# nayt
Add host entry in DNS zone file

This script should not be used for generals purposes. This is for a project, script syntax may be particular.

Download the script
-
```sh
git clone https://github.com/JackScripter/nayt.git
chmod +x nayt/nayt.sh
```
Syntax
-
**Example 1:** ./nayt.sh -r zone.com srv-web 172.16.0.10

This will create an A record in the file zone.com for IP 172.16.0.10 with hostname srv-web. Will also create a PTR record in file zone.com.rev for the specific host. The script will increment the serial by 1 in both file.

**Example 2:** ./nayt.sh zone.com MX mail

This will create a MX record in file zone.com for hostname mail. The DNS entry will be 'IN  MX  10  mail.zone.com.'.

**Example 3:** ./nayt.sh zone.com A srv-ftp 10.50.1.2

This will create an A record for host srv-ftp with IP 10.50.1.2 in file zone.com.


Bug report
-
Report any bug to jackscripter45@gmail.com
