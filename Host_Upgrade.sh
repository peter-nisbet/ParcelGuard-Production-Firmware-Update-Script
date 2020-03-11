#
# This script performs a firmware update to the Parcel Guard
# PCB. This is the host computer script which will push the 
# target update script to the Parcel Guard. The Parcel Guard
# will execute target script and download all necessary files
# to update the board.
#
# V1.1	Written by: Peter Nisbet C.E.T
#

# Pull FTP credentials and ota package information from 
# config file.
source pg_fwupdate.config
source ota_checksum.sh

# Perform check if OTA package exists in the Hosts home 
# directory.If not then download and perform SHA256 hash
# checksum. If the file is already downloaded perform 
# SHA256 hash checksum on the ota_pack.
if [ -f /home/$USER/$ota_files ]
then
	echo "OTA_Pack already downloaded."
	checksum1=$(sha256sum /home/$USER/$ota_files)
	checksum2=$( echo "${checksum1}" | head -c 64 )
	echo $checksum2
else
	echo "Download the OTA_Pack into home directory."	
	./ota_checksum.sh
	checksum1=$(sha256sum /home/$USER/$ota_files)
	checksum2=$( echo "${checksum1}" | head -c 64 )
	echo $checksum2
fi
sleep 1s

# Perform ARP-SCAN to obtain IP address from MAC of PCB.
ipaddress=$(sudo arp-scan --localnet | grep -i $1)
ip=$( echo "${ipaddress}" | cut -f1 ) 

# Connect to Parcel Guard ADB, enable root access.
adb connect $ip
sleep 3s

# get current firmware version from ota.cfg file. Clean up value by removing
# carriage return and leading text.
value=$( adb -s $ip shell cat /system/etc/ota.cfg | grep fwvesion )
v=$( echo "${value}" | cut -f2 -d ":" | tr -d "\r")

echo "Current firmware version:" $v

# Perform a check to ensure board has an earlier version of firmware than 
# what is being flashed to board.
if [ $allow_any_fw == "1" ]
then
	firmware_check $v $fw_ver
fi

# Check to ensure that board has a valid firmware version.
if [ $v != "3.1.2" ] && [ $v != "3.0.1" ] && [ $compatible_ver_flag = "1" ]
then
	echo "Firmware version" $v "not supported. Please return to VVDN."
	exit
fi

sleep 3s

# Push the target firmware update script to the Parcel Guard
# PCB.
adb -s $ip push /home/$USER/Firmware_Upgrade.sh /sdcard
sleep 3s

# Move firmware update script from sdcard to root directory to be executed.
echo "Copy Firmware_Upgrade.sh from sdcard directory to /."
adb -s $ip shell su 0 cp /sdcard/Firmware_Upgrade.sh /

# Set execute permissions on Firmware_Upgrade.sh.
echo "Set execute permission for Firmware_Upgrade.sh."
adb -s $ip shell su 0 chmod +x Firmware_Upgrade.sh

# Log in to root shell and execute the firmware upgrade script,
# passing the FTP server credentials, ota_file name and SHA256 
# HASH checksum value.
adb -s $ip shell su 0 ./Firmware_Upgrade.sh $ftpuser $ftppwd $serverip $ota_files $checksum2
