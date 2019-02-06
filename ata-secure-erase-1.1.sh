#!/bin/bash

### Check if root

if [[ $EUID -ne 0 ]]
then
	echo "This script must be run as root"

	exit 1

fi

### If no disk provided

if [[ ! $1 ]]
then
	echo "Please provide a disk"
	echo ""
	echo "Available disks are:"
	echo -e "$(ls /dev/sd[a-k] )"
	echo ""
	echo "Example: sudo ./ata-secure-erase-1.1.sh /dev/sda"

	exit 1

fi

### If not a disk

if [[ $1 != "$(ls $1 2> /dev/null)" && $1 =~ /dev/sd* ]]
then
	echo "That's not a disk... Quit that."
	echo ""

	exit 1

fi

### If disk is mounted

if [[ $(grep $1 /proc/mounts) ]]
then
	echo ""
	echo "Device is mounted"
	echo ""
	echo "If this is not the currently running volume (USB drive), "
	echo "unmount the device before erasing"
	echo ""

	exit 1

fi

clear

echo ""
echo ""
echo "################################################"
echo ""
echo "    Auto ATA Secure Erase Script"
echo ""
echo "    Maximillian Schmidt"
echo "    OSU UIT, Service Desk"
echo ""
echo "    Version: 1.1.0"
echo ""
echo "    WARNING: This script irrecoverably destroys"
echo "             data! Please be sure you intend"
echo "             to get nothing back from the"
echo "             internal SSD housed in this device!"
echo ""
echo "             YOU WILL ONLY BE WARNED AND ASKED"
echo "             ONCE! BE ULTRA-HYPER SURE!"
echo ""
echo "################################################"
echo ""
echo ""


echo "Script assumes $1 is the SSD to be erased"
echo ""
echo "Please double check by using the Gnome Disk manager"
echo "Close the application to continue"
printf "(Starting in 5s) "

for i in `seq 1 5`
do
	printf "."
	sleep 1

done

echo ""


gnome-disks


clear


### Confirm erase

echo "LAST CHANCE"
echo ""

bloweraway="t"

while [[ $bloweraway != 'y' && $bloweraway != 'n' && $bloweraway != 'Y' && $bloweraway != 'N' ]]
do
	read -n1 -p "Erase SSD? (on touch of 'y' or 'n') " bloweraway
	echo ""

done

echo ""

if [[ $bloweraway == 'n' || $bloweraway == 'N' ]]
then
	echo "Come back when you are ready!"
	echo ""

	exit 0

fi

### Check if device is frozen

frozen="$(hdparm -I /dev/sda | grep 'frozen')"

if [[ $frozen != *"not"* ]]
then
	echo "/dev/sda is frozen!"
	echo ""
	printf "Trying suspend in 3s "

	for i in `seq 1 3`
	do
		printf "."
		sleep 1

	done

	systemctl suspend

	echo "Suspend command issued..."

	sleep 7

	clear

	echo "Man that was a short nap..."

fi


### Check if still frozen

frozen="$(hdparm -I /dev/sda | grep 'frozen')"

if [[ $frozen != *"not"* ]]
then
	echo "ERROR:  /dev/sda is still frozen!"
	echo ""
	echo "See: https://ata.wiki.kernel.org/index.php/ATA_Secure_Erase"
	echo "for further options to thaw the drive"

elif [[ $frozen == *"not"* ]]
then
	echo ""
	echo "/dev/sda thawed"
	echo ""

else
	echo "Hull breach!"

	exit 1

fi


### Do the real damage 

if [[ $bloweraway == 'y' || $bloweraway == 'Y' ]]
then
	echo "STARTING ERASE - "
	echo ""

	# Set password
	echo "Setting user password..."
	hdparm --user-master u --security-set-pass Blue32 /dev/sda
	echo ""

	# Issue ATA Secure Erase command
	echo "Issuing ATA Secure Erase command..."
	time hdparm --user-master u --security-erase Blue32 /dev/sda
	echo ""

fi


### Verify security removed, indicating drive is wiped

wiped="$(hdparm -I /dev/sda | grep 'enabled')"

if [[ $wiped == *"not"* ]]
then
	echo ""
	echo "Drive successfully erased!"
	echo "Exiting..."
	echo ""

	exit 0

else
	echo ""
	echo "ERROR: Drive did not successfully erase!"	
	echo "Please manually check on the disk or wiki"
	echo ""

	exit 1

fi

exit 2