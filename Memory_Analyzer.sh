#!/bin/bash

#Memory Analyzer. Objectives: HDD and memory files investigation, automatic data extraction with carvers, 
#memory analysis with Volatility.

start=$(date +%s) #sript start time (Unix time)

HOME=$(pwd) #Set HOME variable to the current working directory

if [ $(whoami) == "root" ] #Checking current user, if not root exit
then
echo "[→] Welcome to Memory Analyzer!"
else
echo "[-] You need to be root to run this script. Exiting..."
exit
fi

function FILENAME() # Get info from the user: filename for analysis 
{
echo "[→] Please specify filename including full path for analysis:"
read file
if [ -f $file ] #Check if the user submitted the file correctly. If yes, create a directory for results. If not - option to resubmit. 
then
echo "[+] You submitted: $file"
base_name=$(basename $file)
mkdir -p $HOME/Analyzer/$base_name
else 
echo "[-] Error: File not found. Please check file path and try again"
FILENAME
fi
}
FILENAME

function TOOLS() #Check if automatic carving forensic tools are installed
{
echo ""
echo "[→] Checking if automatic carving tools are installed..."
echo ""
sleep 1
TOOLS="binwalk foremost bulk_extractor strings" #loop through tools checking if they are installed
#and installing tools that are missing   
for t in $TOOLS
do	
if command -v $t > /dev/null 2>&1
then
echo "[+] $t is already installed"
else
echo "[-] $t is not installed, installing..."
apt-get update > /dev/null 2>&1
apt-get install -y $t > /dev/null 2>&1
echo "[+] $t installed successfully"
fi
done
}
TOOLS


function CARVERS() #Automatic file carving. Option for the user to choose a carver or use all available carvers
{
echo ""
echo "[→] Extracting data with carvers"
echo ""

read -p "[→] Carving mode:
Enter C to choose a carver to use
Enter A to use all available carvers (Binwalk, Foremost, Bulk_extractor, Strings)" mode
case $mode in 
A) #Analysis using all available carvers
echo "[→] Extracting data with Binwalk...This might take a few minutes" #Carving with Binwalk
binwalk -e -C $HOME/Analyzer/$base_name/binwalk_results --run-as=root $file -f $HOME/Analyzer/$base_name/log.txt > /dev/null 2>&1
mv $HOME/Analyzer/$base_name/log.txt $HOME/Analyzer/$base_name/binwalk_results #saving binwalk log alongside the extracted data
echo "[+] Done"
echo "[→] Extracting data with Foremost..." #Carving with Foremost
foremost -o $HOME/Analyzer/$base_name/foremost_results $file > /dev/null 2>&1 
chmod -R 777 $HOME/Analyzer/$base_name/foremost_results #Change output folder permissions to allow regular users to see the results
echo "[+] Done"
echo "[→] Extracting data with Bulk_Extractor... it might take a while" #Carving with Bulk_Extractor
bulk_extractor -o $HOME/Analyzer/$base_name/bulk_results $file > /dev/null 2>&1
find $HOME/Analyzer/$base_name/bulk_results -type f -empty -delete #Delete irrelevant empty files
echo "[+] Done"
echo "[→] Extracting data with Strings. Looking for keywords: exe, password, username, http..." 
#Analysis with Strings. Looking for most popular keywords
mkdir -p $HOME/Analyzer/$base_name/Strings
strings $file >> $HOME/Analyzer/$base_name/Strings/Strings_full.txt
strings $file | grep -i -e exe -e password -e username -e email > $HOME/Analyzer/$base_name/Strings/Strings_keywords.txt
function KEYWORD #You can submit your own search keyword if you wish 
{
echo "[→] Do you want to submit your keyword y/n?"
read keyword
case $keyword in
y) 
echo "[→] Enter your keyword:"
read key
strings $file | grep -i $key | tee -a $HOME/Analyzer/$base_name/Strings/Strings_$key.txt 
echo "[+] Done. Results are saved"
echo "[→] Do you want to submit another keyword? y/n"
read keyword2
if [ $keyword2 == "y" ]
then 
KEYWORD
else
echo ""
fi
;;
n)
echo ""
;;
esac
echo "[+] Done"
}
KEYWORD
echo "" 
echo "[+] All results are saved in: Analyzer/$base_name"
;;
C)
function CARVER2
{
echo ""
echo "[→] Do you want to use another carver? y/n"
read answer
if [ $answer == "y" ]
then
CARVERS
elif [ $answer == "n" ]
then
echo "[+] All results are saved in: Analyzer/$base_name"
else
echo "[-] invalid input. Try again:"
CARVER2 
fi 
}
echo "[→] Which carver do you want to use?" #Analysis with carvers chosen by the user 
read -p "Enter 1 for Binwalk
2 for Foremost
3 for Bulk_Extractor
4 for Strings (looking for human-readable data)" carver
case $carver in
1)
echo "[→] Extracting data with Binwalk...This might take a few minutes" #Carving with Binwalk
binwalk -e -C $HOME/Analyzer/$base_name/binwalk_results --run-as=root $file -f $HOME/Analyzer/$base_name/log.txt > /dev/null 2>&1
mv $HOME/Analyzer/$base_name/log.txt $HOME/Analyzer/$base_name/binwalk_results #saving binwalk log alongside the extracted data
echo "[+] Done"
CARVER2
;;
2)
echo "[→] Extracting data with Foremost..." #Carving with Foremost
foremost -o $HOME/Analyzer/$base_name/foremost_results $file > /dev/null 2>&1 
chmod -R 777 $HOME/Analyzer/$base_name/foremost_results #change output folder permissions to allow regular users to see the results
echo "[+] Done"
CARVER2
;;
3)
echo "[→] Extracting data with Bulk_Extractor... it might take a while" #Carving with Bulk_Extractor
bulk_extractor -o $HOME/Analyzer/$base_name/bulk_results $file > /dev/null 2>&1
find $HOME/Analyzer/$base_name/bulk_results -type f -empty -delete #delete irrelevant empty files
echo "[+] Done"
CARVER2
;;
4)
echo "[→] Extracting data with Strings. Looking for keywords: exe, password, username, http..." 
#Analysis with Strings. Looking for most popular keywords
mkdir -p $HOME/Analyzer/$base_name/Strings
strings $file >> $HOME/Analyzer/$base_name/Strings/Strings_full.txt
strings $file | grep -i -e exe -e password -e username -e email > $HOME/Analyzer/$base_name/Strings/Strings_keywords.txt
function KEYWORD #You can submit your own search keyword if you wish 
{
echo "[→] Do you want to submit your keyword y/n?"
read keyword
case $keyword in
y) 
echo "[→] Enter your keyword:"
read key
strings $file | grep -i $key | tee -a $HOME/Analyzer/$base_name/Strings/Strings_$key.txt
echo "[+] Done. Results are saved"
echo "[→] Do you want to submit another keyword? y/n"
read keyword2
if [ $keyword2 == "y" ]
then 
KEYWORD
else
echo ""
fi
;;
n)
echo ""
;;
esac
echo "[+] Done"
}
KEYWORD

CARVER2
;;
*)
echo "[-] Invalid input. Try again"
sleep 0.5
CARVERS
esac
;;
*)
echo "[-] Invalid input. Try again:"
CARVERS 
esac
}
CARVERS

function PCAP() #Check if a network file (pcap) wak extracted 
{
	echo ""
	file_count=$(find $HOME/Analyzer/$base_name/ -type f | wc -l) #number of found files
	if [ -f $HOME/Analyzer/$base_name/bulk_results/packets.pcap ]
	then
	echo -e "[!]Detected pcap network file. Saved in:\n$HOME/Analyzer/$base_name/bulk_results"
	echo "[+] Network file size: $(ls -lh $HOME/Analyzer/$base_name/bulk_results/packets.pcap | awk '{print $5}' )"
	else
	echo ""
	fi
}
PCAP 


function VOL () #Memory analysis with Volatility 
{
echo -e "[→]Analyzing file with Volatility. Trying to extract profile...\nThis might take a few minutes" 
mkdir -p $HOME/Analyzer/$base_name/vol
./vol -f $file imageinfo > $HOME/Analyzer/$base_name/vol/profile.txt 2>/dev/null #MemAnalyzer uses preinstalled
#volatility tool and runs it from the same directory as the file to analyze. Please install volatility
#tool and save it in a folder together with a file to analyze before running the script. 

if #Checks if the submitted file is a memory file that can be analyzed with Volatility
grep -q "No suggestion" $HOME/Analyzer/$base_name/vol/profile.txt
then
    echo "[-]$file can't be analyzed with Volatility"
else
    profile=$(cat $HOME/Analyzer/$base_name/vol/profile.txt | grep "Suggested Profile" | awk '{print $4}' | sed 's/,//g')
    echo "[+]Extracted profile is: $profile"
    PLUGINS="pstree pslist psscan connscan netscan hivelist hivedump consoles" 


for p in $PLUGINS #loop through volatility plugins and save each plugin resilts into a different file
do 
echo "[→]Running $p plugin"
./vol -f $file --profile=$profile $p > $HOME/Analyzer/$base_name/vol/volatility_results_$p 2>/dev/null 
done
fi
}

VOL

function FINISH () #display general statistics, option to zip the results
{
echo ""
echo "[→] Statistics:"
echo ""
end=$(date +%s) #script end time (Unix time)
runtime=$(($end - $start)) #script runtime (Unix tiime)
echo "$file" >> $HOME/Analyzer/$base_name/report.txt
echo "[+]Analysis completed in $(($runtime / 60)) minutes and $(($runtime % 60)) seconds" | tee -a $HOME/Analyzer/$base_name/report.txt
echo "[+]Found $file_count files" | tee -a $HOME/Analyzer/$base_name/report.txt
echo "[+]All results are saved in $HOME/Analyzer/$base_name"
read -p "[→] Do you want to zip the extracted files? y/n" answer
if [ $answer == "y" ] 
then
tar -cf $HOME/Analyzer/$base_name.tar $HOME/Analyzer/$base_name > /dev/null 2>&1
echo "[+] Done. Archive $base_name.tar is saved in $HOME/Analyzer. Bye-bye"
else
echo "[+] Bye-bye"
fi
  
}
FINISH



