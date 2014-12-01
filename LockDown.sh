#!/bin/bash
# Written by Tim Fowler
# VPN Lockdown

# Variables

break="================================================================================================="

####################### LockDown Banner ##########################

BANNER(){
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
echo "   VPN LockDown is a simple wrapper around OpenVPN and IPTABLES that is designed"
echo "   to prevent data leakage in the event your VPN tunnel fails"
echo
echo $break
}

### At program execution

clear
BANNER

######################### IP function ############################

GET_IP() {
  IP=$(wget https://duckduckgo.com/?q=whats+my+ip -q -O - | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>')
  echo $break
  echo
  echo -e "Your current IP address is: \e[1;34m$IP\e[0m"
  echo 
  echo $break
  echo
}

######################## Menu function ###########################

GET_MENU(){
  while :
do 
cat << !

       ~~: MENU :~~

  1. Enable VPN

  2. Disable VPN

  3. Activate LockDown

  4. Deactivate LockDown

  5. Get Status

  6. Get Current IP address

  7. Help

  8. Quit

!

echo -n "Command: "
read choice

case $choice in
  1) V_START
      echo "Press ENTER to return to MENU."
      read pause
      clear
      BANNER ;;

  2) V_STOP
     echo
     echo "Press ENTER to return to MENU."
     read pause
     clear
     BANNER ;;

  3) L_START
     echo "Press ENTER to return to MENU."
      read pause
      clear
      BANNER ;;

  4)  L_STOP ;;

  5) STATUS
      echo "Press ENTER to return to MENU."
      read pause
      clear
      BANNER ;;

  6) GET_IP
     echo "Press ENTER to return to MENU."
      read pause
      clear
      BANNER ;;

  7) clear
     BANNER
     HELP
     echo 
     echo "Press ENTER to return to MENU."
     read pause
     clear
     BANNER ;;
8) echo
     echo "Now Exiting..."
     echo
     sleep 1
     exit ;;

  *) echo 
     echo "You made an invalid selection. Please choose an option from the menu"
     echo
     echo "Press ENTER to return to MENU."
     read pause
     clear
     BANNER ;;
esac
done
}

######################## Help function ###########################

HELP() {
 echo "$(basename "$0") [-h] [-f n] [ -i]-- program to calculate the answer to life, the universe and everything

 where:
     -c Checks the status of your VPN and if LockDown is enabled
     -v Starts your VPN (agrument for file is required)
     -s Stops your VPN
     -i Check current IP
     -h  show this help text"
}

###################### LockDown function #########################

L_START() {
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
        echo
        echo "You must have your VPN running in order to start LockDown"   
        echo
        echo "Run LockDown with the -v option"
        echo
      fi
}

####################### Status function ##########################

STATUS() {
  echo
  echo $break
  if [ "$(pgrep openvpn)" ]; then
      echo
      echo "OpenVPN Status: Active"
    else
      echo
      echo "OpenVPN Status: Inactive"
    fi
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
    echo "LockDown Status: Custom iptables configuration"
    echo 
    echo "If you have another iptables firewall you may need to disable that while connected to the vpn."
    echo
  fi
}

######################## Stop function ###########################

L_STOP() {
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
        echo
        echo "Exiting now..."
        echo
        sleep 2
      exit 0
    else
      echo "VPN is not running"
      sleep 1
      iptables -F
      iptables -A INPUT -j ACCEPT
        iptables -A OUTPUT -j ACCEPT
         echo
         echo "Iptables have been cleared."
        sleep 2
      echo
      echo "Exiting now..."
      echo
      sleep 2
      exit 0
    fi
}

######################## VPN function ############################

V_START() {
  echo
  echo -n "Please provide the path to your VPN file: "
  read path
    if [ -f $path ]; then
      file=$path
      IP=$(wget https://duckduckgo.com/?q=whats+my+ip -q -O - | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>')
      echo
      echo "You have selected to start your vpn"
      echo
      echo -e "Your current IP address is: \e[1;34m$IP\e[0m"
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
          echo
        else
          echo
          echo -e "Your VPN IP address is: \e[1;34m$VPN_IP\e[0m" 
          echo
        fi
    else
      echo
      echo "The file path you specified does not exist."
      echo
   fi
}

V_STOP(){
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
      echo
      echo "Exiting now..."
      echo
      sleep 2
      exit 0
    else
      echo "VPN is not running"
      sleep 2
    fi
}
#################### Commandline Functions ######################

while getopts "vshcli" FLAG; do
  case $FLAG in
    i)  # Grab IP
      clear
      echo 
      echo "Checking your IP address"
      GET_IP
      exit 0
      ;;  
    v) #VPN option
       V_START
       exit 0
       ;;
    s) #Stop VPN
		  L_STOP
      echo
      echo "Exiting now..."
      echo
      sleep 2
      exit 0
		  ;;
	  c) # Check status of OpenVPN and LockDown
		  STATUS
      exit 0
		  ;;		
	  l) # Enable LockDown
		  L_START
      exit 0
  		;;
    h)  #show help
      HELP
      exit 1
      ;;
    *) # Knock Knock
      HELP
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

GET_MENU

exit 0