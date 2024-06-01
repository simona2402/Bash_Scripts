#!/bin/bash

# Local Network Scanner. Objectives: scan local network for open ports and running services, 
#map vulnerabilities, look for login weak passwords. Basic and Full Scan modes.  


HOME=$(pwd) #Set HOME variable to the current working directory


function USERS() # Get info from the user: users list 
{
echo ""
echo "[*] Check for weak passwords"
echo "[→] Please upload users list into $HOME/Scanner/$DIR"
read -p "[→] Once uploaded, enter file name:" userslist
if [ -f $HOME/Scanner/$DIR/$userslist ] #Checking if users list was submitted correctly
then
echo "[+] You submitted: $userslist"
else 
echo "[-] Error: File not found. Please check file path and try again"
USERS
fi
}

function PASSWD() # Get info from the user: passwords list. Option to use default 10k-most-common  passwords list from Github.  
# Check for weak passwords and display if found
{
read -p "[→] Do you want to submit your own password list? [y/n]" list
case $list in
y)
echo "[→] Please upload your password list into $HOME/Scanner/$DIR"
read -p "[→] Once uploaded, enter file name:" passlist
if [ -f $HOME/Scanner/$DIR/$passlist ] # Checking if password list was submitted correctly
then
echo "[+] You submitted: $passlist"
else 
echo "[-] Error: File not found. Please check file path and try again" 
PASSWD
fi
;;
n)
echo "[*] Using 10,000 most common passwords list from Github. Downloading..." # If a user doesn't want to use his own password list
#download password list from Github. 
passlist=$(wget -P $HOME/Scanner/$DIR https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt)
;;
*)
echo "[-] Invalid input. Try again"
PASSWD
esac
 
echo "[*] Checking for login weak passwords. This might take a while..."  
medusa -H $HOME/Scanner/$DIR/live_hosts.txt -U $HOME/Scanner/$DIR/$userslist -P $HOME/Scanner/$DIR/$passlist -M ssh -f | grep SUCCESS >> $HOME/Scanner/$DIR/weak_pass.txt 
medusa -H $HOME/Scanner/$DIR/live_hosts.txt -U $HOME/Scanner/$DIR/$userslist -P $HOME/Scanner/$DIR/$passlist -M ftp -f | grep SUCCESS >> $HOME/Scanner/$DIR/weak_pass.txt
medusa -H $HOME/Scanner/$DIR/live_hosts.txt -U $HOME/Scanner/$DIR/$userslist -P $HOME/Scanner/$DIR/$passlist -M smbnt -f | grep SUCCESS >> $HOME/Scanner/$DIR/weak_pass.txt
medusa -H $HOME/Scanner/$DIR/live_hosts.txt -U $HOME/Scanner/$DIR/$userslist -P $HOME/Scanner/$DIR/$passlist -M rdp -f | grep SUCCESS >> $HOME/Scanner/$DIR/weak_pass.txt
echo ""
echo "[*] Weak passwords (if found):"
cat $HOME/Scanner/$DIR/weak_pass.txt #Display passwords check results
rm $HOME/Scanner/$DIR/$userslist > /dev/null 2>&1 # Delete users and passwords lists
rm $HOME/Scanner/$DIR/$passlist > /dev/null 2>&1
rm $HOME/Scanner/$DIR/10k-most-common.txt > /dev/null 2>&1
} 


function BASIC() #Basic Scan - map network devices, scan for open ports and services 
{
nmap -sn $RANGE | grep for | awk '{print $5}' > $HOME/Scanner/$DIR/temp_hosts.txt
GATEWAY=$(route | awk '{print $2}' | head -3 | tail -1) # Exclude router and user's machine from detected live hosts list
MYIP=$(hostname -I)
cat $HOME/Scanner/$DIR/temp_hosts.txt | grep -v $GATEWAY | grep -v $MYIP >> $HOME/Scanner/$DIR/live_hosts.txt 
rm $HOME/Scanner/$DIR/temp_hosts.txt
echo "[+] Done. Live hosts are:"
cat $HOME/Scanner/$DIR/live_hosts.txt #Display live hosts
echo ""
echo "[*] Scanning all 65,535 ports for open ports and services. This might take a while..."
for i in $(cat $HOME/Scanner/$DIR/live_hosts.txt) #loop through live hosts, scan all 65,535 ports   
do
nmap -Pn -sV -p- $i | grep -e open -e scan >> $HOME/Scanner/$DIR/ports_services.txt 
done
echo "[+] Done. Open ports and services are:"
cat $HOME/Scanner/$DIR/ports_services.txt #Display ports scanning results
USERS
PASSWD
}

function FULL() # Full Scan - Basic (map network devices, scan for open ports  and services) + vulnerabilities check 
{
BASIC 
echo "[*] Scanning for vulnerabilities. Might take a few minutes..."
for i in $(cat $HOME/Scanner/$DIR/live_hosts.txt) # Loop through live hosts list using NSE vuln category
do
nmap -sV --script=vuln $i >> $HOME/Scanner/$DIR/vulnerabilities.txt
done
echo "[+] Done. Discovered vulnerabilities are:"
sleep 0.5
cat $HOME/Scanner/$DIR/vulnerabilities.txt # Display vulnerabilities scan results

}


function START() # Request info from the user: network range, output directory and scan mode (Basic or Full)
{  
echo "[*] Welcome to Network Scanner"
read -p "[→] Please enter network range to scan:" RANGE
read -p "[→] Please enter a name for the output directory:" DIR
mkdir -p $HOME/Scanner/$DIR
echo "[*] Results will be saved in Scanner/$DIR"
echo ""
echo -e "[→] Choose Basic or Full scan mode.\nBasic mode scans the network for TCP and UDP ports, service versions and weak passwords.\nFull mode includes also vulnerability analysis (takes more time to complete).\nEnter B for Basic or F for Full scan mode:"
read MODE
case $MODE in
B)
echo "[*] Starting Basic Scan. Looking for live hosts..."
BASIC
;;
F)
echo "[*] Starting Full Scan. Looking for live hosts..."
FULL
;;
*)
echo "[-]Wrong input. Exiting..."
;;
esac
}
START


if [ -f $HOME/Scanner/$DIR/vulnerabilities.txt ];
then 
echo ""
echo "[+] Full scan completed."
sleep 1
else
echo ""
echo "[+] Basic scan completed."
sleep 1
fi


function RESULTS()
{
read -p "[→] Do you want to search within the results? [y/n]" search #An option for the user to search results using keywords
case $search in 
n)
read -p "[→] Do you want to save results into a Zip file? [y/n]" zip #An options to save results into a zip file
if [ $zip == "n" ]
then 
echo "[+] All results are saved in $HOME/Scanner/$DIR. Buy-Buy"
exit
elif [ $zip == "y" ]
then
zip $HOME/Scanner/$DIR.zip $HOME/Scanner/$DIR/* > /dev/null 2>&1 
echo "[+] Archive $DIR.zip created in $HOME/Scanner. Bye-Bye"
else 
echo "[-] Wrong input. Try again..."
RESULTS
fi
;;
y)
echo "[→] Enter key word"
read word
grep -i $word $HOME/Scanner/$DIR/*
RESULTS
;;
*)
echo "[-] Wrong input. Try again..."
RESULTS
;;
esac
}
RESULTS
