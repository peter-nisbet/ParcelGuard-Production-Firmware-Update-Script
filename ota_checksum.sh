# 
# Script to pull ota firmware image for checksum verification
# during Parcel Guard Update process.
#

# Pull FTP credentials from config file.
source pg_fwupdate.config

# Start FTP connection to server without auto login, execute
# binary mode file transfer, download the ota image to home
# directory of Host machine then quit script.
ftp -n $serverip <<END_SCRIPT
quote USER $ftpuser
quote PASS $ftppwd
binary
cd files
get $ota_files
quit
END_SCRIPT

number_check() {
	if [ $1 -gt $2 ]
	then
		echo "higher"
	elif [ $1 -eq $2 ]
	then
		echo "same"
	else
		echo "lower"
	fi
}

firmware_check() {
	local v1=$( echo "$1" | cut -f1 -d "." )
	local v2=$( echo "$1" | cut -f2 -d "." )
	local v3=$( echo "$1" | cut -f3 -d "." )
	local v4=$( echo "$2" | cut -f1 -d "." )
	local v5=$( echo "$2" | cut -f2 -d "." )
	local v6=$( echo "$2" | cut -f3 -d "." )

	check1=$(number_check $v1 $v4)
	check2=$(number_check $v2 $v5)
	check3=$(number_check $v3 $v6)

	if [ $check1 == "higher" ]
	then
		echo "Firmware newer1."
		exit
	else
		if [ $check2 == "higher" ] && [ $check1 == "same" ]
		then
			echo "Firmware newer2."
			exit
		else
			if [ $check3 != "lower" ] && [ $check2 == "same" ] && [ $check1 == "same" ]
			then
				echo "Firmware same or newer3."
				exit
			else
				echo "Ready to update to:" $2
			fi
		fi
	fi

}
