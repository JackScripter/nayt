# nayt
Add host entry in DNS zone file

This script is not finished and is should not be used for generals purposes. This is for a project, script syntax is particular at this moment.

Syntax
-
Example 1: ./nayt.sh -r unezonerandom.com 172.16.0.10 srv-web \n
This will create an A record in the file unezonerandom.com for IP 172.16.0.10 with hostname srv-web. Will also create a PTR record in file unezonerandom.com.rev for the specific host. The script will increment the serial by 1 in both file.
