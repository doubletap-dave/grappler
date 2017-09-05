#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
#  Released under the MIT license.

# Install with this command:
# curl -sSL https://grappler.davemobley.net | bash

# Make sure we are root or have root permissions
rootCheck() {
  if [ "$UID" -ne "$ROOT_UID" ]
    then
      echo "Must be root to run this script, please try again..."
      exit $E_NOTROOT
  fi
}
rootCheck

# Create aliases
aliasCreate() {
	alias instally="sudo yum install -y"
	alias installd="sudo dnf install -y"
}

# Create installation log folder
makeDirs() {
	echo -e "Making installer directories...\n"
	mkdir $HOME/grappler && mkdir $HOME/grappler/updaters
	mkdir $HOME/grappler/helpers && mkdir $HOME/grappler/log
	mkdir $HOME/grappler/phases
}

# Get helper scripts
getHelpers() {
	echo -e "Getting helpers and services...\n"
	wget -O $HOME/grappler/phases/phase1.sh https://raw.githubusercontent.com/topiaryx/grappler/master/phases/phase1.sh
	wget -O $HOME/grappler/phases/phase2.sh https://raw.githubusercontent.com/topiaryx/grappler/master/phases/phase2.sh
	wget -O $HOME/grappler/phases/phase3.sh https://raw.githubusercontent.com/topiaryx/grappler/master/phases/phase3.sh
	wget -O $HOME/grappler/phases/phase4.sh https://raw.githubusercontent.com/topiaryx/grappler/master/phases/phase4.sh
	wget -O $HOME/grappler/phases/phase5.sh https://raw.githubusercontent.com/topiaryx/grappler/master/phases/phase5.sh
	sudo wget -O /lib/systemd/system/grafana.service https://raw.githubusercontent.com/topiaryx/grappler/master/helpers/grafana.service
	sudo wget -O /lib/systemd/system/influxdb.service https://raw.githubusercontent.com/topiaryx/grappler/master/helpers/influxdb.service
}

# Load helper scripts
loadHelpers() {
	source $HOME/grappler/phases/phase1.sh
	source $HOME/grappler/phases/phase2.sh
	source $HOME/grappler/phases/phase3.sh
	source $HOME/grappler/phases/phase4.sh
	source $HOME/grappler/phases/phase5.sh
}

# We fancy, huh? Not really, haha...
showLogo() {
	clear
	echo "
		____ ____ ____ ___  ___  _    ____ ____ 
		| __ |__/ |__| |__] |__] |    |___ |__/ 
		|__] |  \ |  | |    |    |___ |___ |  \ 
                                        
		     Grafana stack installer v1.0
"
}

# Owner checkerizer
checkOwner () {
	chown ${USER:=$(/usr/bin/id -run)}:${USER} -R /docker > /dev/null 2>&1 >> dgc_install.log;
}

# PREREQ: Check machine of VM IP address
checkIp() {
	ip=$(ip route get 1 | awk '{print $NF;exit}')
}
checkIp

# PREREQ: Required packages installer
required() {
	instally epel-release && instally dnf dnf-plugins-core newt && dnf makecache fast
	installd device-mapper-persistent-data lvm2 sshpass net-snmp net-snmp-devel.x86_64 net-snmp-utils.x86_64 open-vm-tools
}

restartMe() {
	clear
	echo
	echo -e "The machines needs to be restarted in order to apply changes and finalize the installation."
	echo -e "After the restart, Grafana can be accessed via http://${ip}:3000 with the user 'admin' and the password you created earlier in the installation."
	echo
	echo -n "Press any key to restart..."
	read -rsn1
	reboot
}

# INSTALL ALL THE THINGS!
installUpdate() {
	aliasCreate && required && dnf update -y && docker && grafana && influxdb && telegraf && graphite && checkOwner && restartMe
}

installNoUpdate() {
	aliasCreate && required && docker && grafana && influxdb && telegraf && graphite && checkOwner && restartMe
}

makeDirs
getHelpers
loadHelpers

showLogo
while true; do
    echo -e "Welcome to Grappler, the Docker/Grafana/InfluxDB and Graphite Install-o-matic 9000!"
    echo
    echo -e "Do you want to update your system? [y/n]: "
    read onsey
    case $onsey in
        [yY] ) installUpdate ; break;; 
        [nN] ) installNoUpdate; break;;
           * ) echo -e "Please answer 'y' or 'n' ";;
    esac
done