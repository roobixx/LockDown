#!/bin/bash
# Written by Tim Fowler
# VPN Lockdown
clear

# Variables

break="================================================================================================="

# VPN LockDown Script Banner

echo " __      _______  _   _ _                _    _____                      ";
echo " \ \    / /  __ \| \ | | |              | |  |  __ \                     ";
echo "  \ \  / /| |__) |  \| | |     ___   ___| | _| |  | | _____      ___ __  ";
echo "   \ \/ / |  ___/| . \` | |    / _ \ / __| |/ / |  | |/ _ \ \ /\ / / '_ \ ";
echo "    \  /  | |    | |\  | |___| (_) | (__|   <| |__| | (_) \ V  V /| | | |";
echo "     \/   |_|    |_| \_|______\___/ \___|_|\_\_____/ \___/ \_/\_/ |_| |_|";
echo -e "                                         \e[1;34mVersion 0.1  Created by roobixx\e[0m    ";
echo "                                                                         ";
echo 
echo $break
echo
echo "VPN LockDown is designed to prevent data leakage in the event your vpn tunnel goes down."
echo
echo $break
#path=$file

ip () {
	IP=$(wget https://duckduckgo.com/?q=whats+my+ip -q -O - | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>')
	echo
	echo "Your current IP address is: $IP"
	echo 
}

status() {
  echo 
  echo $break
  IP=$(wget https://duckduckgo.com/?q=whats+my+ip -q -O - | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>')
  IPTABLES=$(iptables -S)
  OFF="-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-A INPUT -j ACCEPT
-A OUTPUT -j ACCEPT"
  ON="-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-A INPUT -i tun+ -j ACCEPT
-A INPUT -s 127.0.0.1/32 -j ACCEPT
-A INPUT -s $IP/32 -j ACCEPT
-A OUTPUT -o tun+ -j ACCEPT
-A OUTPUT -d 127.0.0.1/32 -j ACCEPT
-A OUTPUT -d $IP/32 -j ACCEPT"
  if [ "$IPTABLES" = "$OFF" ]; then
    echo
    echo "LockDown Status: Inactive"
    echo
    echo $break
    echo
  elif [ "$IPTABLES" = "$ON" ]; then
  	echo
    echo "LockDown Status: Active"
    echo
    echo $break
  else
    echo "Status: Custom iptables configuration"
    echo 
    echo "Either deactivate or reactivate. If you have another iptables firewall you may need to disable that while connected to the vpn."
  fi
}

vpn () {
	sleep 1
}

#Help function
function HELP {
 echo "$(basename "$0") [-h] [-f n] [ -i]-- program to calculate the answer to life, the universe and everything

 where:
     -c Checks the status of your VPN and if LockDown is enabled
     -v Starts your VPN (agrument for file is required)
     -s Stops your VPN
     -i Check current IP
     -h  show this help text"
  exit 1
}

while getopts i:v:shcled FLAG; do
  case $FLAG in
    i)  # Grab IP
      ip
      ;;  
    v) #VPN option
	  if [ -f $OPTARG ]; then
	  	file=$OPTARG
	  else
	  	echo "no file given"
	  fi
	  echo "You have selected to start your vpn"
	  echo
	  echo "Starting Your VPN"
	  cd
	  vpn=$(sudo openvpn --config $file > /dev/null 2>&1 &)
	  $vpn 
	  echo
	  echo "Please wait for the VPN to come up"
	  sleep 20
	  VPN_IP=$(wget https://duckduckgo.com/?q=whats+my+ip -q -O - | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>')
	  echo
	  if [ $IP = $VPN_IP ]; then 
	  	echo "Your VPN has not started successfully"
	  	exit 1
	  else
	  	  echo "Your current IP address is: $VPN_IP" 
	  fi
      ;;
    s) #Stop VPN
		echo
		echo "Checking VPN Status"
		echo
		sleep 1
		if [ "$(pgrep openvpn)" ]; then
			echo "VPN is running"
			sleep 2
			echo
			echo "Stopping VPN"
			sleep 2
			sudo killall openvpn
			echo
			echo "VPN Stopped"
			sleep 2
			iptables -F
  			iptables -A INPUT -j ACCEPT
  			iptables -A OUTPUT -j ACCEPT
  			echo
  			echo "Iptables have been cleared."
  			sleep 2
			clear
		else
			echo "VPN is not running"
			sleep 1
			iptables -F
 			iptables -A INPUT -j ACCEPT
  			iptables -A OUTPUT -j ACCEPT
  			 echo "Iptables have been cleared."
  			sleep 2
			echo
			echo "Exiting now..."
			exit 0
		fi
		exit 0
		;;
	c) #Check if OpenVPN is running
		if [ "$(pgrep openvpn)" ]; then
			echo
			echo "OpenVPN Status: Active"
		else
			echo
			echo "OpenVPN Status: Inactive"
		fi
		status
		;;		
	l) # Enable LockDown
		if [ "$(pgrep openvpn)" ]; then
			 echo "~~~ Warning ~~~"
 			 echo 
 			 echo "ATTEMPTING TO CONNECT TO VPN SERVER NOW."
 			 echo 
 			 echo "YOU MUST BE CONNECTED TO THE VPN BEFORE PROCEEDING OR THE IPTABLES WILL NOT BE CONFIGURED PROPERLY."
 			 echo 
 			 echo "Press ENTER to proceed."
 			 read pause

  			IP=$(wget https://duckduckgo.com/?q=whats+my+ip -q -O - | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>')
 			iptables -F
  			iptables -A INPUT -i tun+ -j ACCEPT
 			iptables -A OUTPUT -o tun+ -j ACCEPT
  			iptables -A INPUT -s 127.0.0.1 -j ACCEPT
  			iptables -A OUTPUT -d 127.0.0.1 -j ACCEPT
  			iptables -A INPUT -s $IP -j ACCEPT
  			iptables -A OUTPUT -d $IP -j ACCEPT
  			echo "Iptables have been set."
  			sleep 2
 
  		else
  			echo "You must have your VPN running in order to start LockDown"	 
  			echo
  			echo "Run LockDown with the -v option"
  			echo
  		fi
  		exit 0
  		;;
    h)  #show help
      HELP
      ;;
    *) #unrecognized option - show help
      HELP
      ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

exit 0