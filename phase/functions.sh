#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

# Create installation log folder
sudo mkdir $HOME/grapplerupdaters && sudo mkdir $HOME/grapplerhelpers

# Create aliases
alias install="sudo yum install -y"
alias installd="sudo dnf install -y"

# We fancy, huh?
showLogo() {
	clear
	echo "
		  ____ ____ ____ ___  ___  _    ____ ____ 
		  | __ |__/ |__| |__] |__] |    |___ |__/ 
		  |__] |  \ |  | |    |    |___ |___ |  \ 
                                        
		       Grafana stack installer v1.0
"
}

# Load helper scripts
loadHelpers() {
	source $HOME/grapplerhelpers/strings.sh 
}
loadHelpers()

# Owner checkerizer
checkOwner () {
	chown ${USER:=$(/usr/bin/id -run)}:${USER} -R /docker > /dev/null 2>&1 >> dgc_install.log;
}

# PREREQ: Check machine of VM IP address
checkIp() {
	ip=$(ip route get 1 | awk '{print $NF;exit}')
}

# PREREQ: Required packages installer
requiredPackages() {
	install epel-release && install dnf dnf-plugins-core newt && dnf makecache fast
	installd device-mapper-persistent-data lvm2 sshpass net-snmp net-snmp-devel.x86_64 net-snmp-utils.x86_64 open-vm-tools
}
