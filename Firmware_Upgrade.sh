#
# Target side firmware upgrade script for Parcel Guard.
# This script runs as root on the android system and 
# pulls all necessary update files to perform the update
# from a local FTP server.
#
# V1.0	Written by: Peter Nisbet C.E.T
# 

# Create directory to store the firmware update files.
echo "Making folder ota in location /data/ota"
mkdir /data/ota

# Use busybox ftp client to pull the firmwareinfo.xml. 
echo "Starting firmwareinfo.xml download."
busybox ftpget -u $1 -p $2 $3 /data/ota/firmwareinfo.xml /files/firmwareinfo.xml
echo "firmwareinfo.xml download complete!"

# Use busybox ftp client to pull the ota_pack.
echo "Starting ota_pack download."
busybox ftpget -u $1 -p $2 $3 /data/ota/$4 /files/$4
echo "ota_pack download complete!"

# Calculate SHA256 Hash sum and compare to that from host
# to verify integrity of the downloaded file. If checksum
# matches then send update command and delete WiFi credentials
# on PCB.If checksum fails then exit script.
sha256check=$( echo $(busybox sha256sum /data/ota/$4) | cut -d" " -f1)
echo $sha256check

if [ $sha256check = $5 ]; then
	echo "Starting ota.cfg download."
	busybox ftpget -u $1 -p $2 $3 /system/etc/ota.cfg /files/ota.cfg
	echo "ota.cfg download complete!"
	echo "Deleting WiFi Credentials."
	rm /data/misc/wifi/wpa_supplicant.conf
	echo "Rebooting Parcel Guard PCB."
	echo "Done Wait atleast 5 minutes before removing PCB."
	reboot
else
	echo "Firmware upgrade failed please rerun script."
	exit
fi

