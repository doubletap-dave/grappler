#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

# Pre-PHASE 2: GRAFANA: Create a systemd startup scripts
grafanaService() {
	sudo wget -O /lib/systemd/system/grafana.service http://linktogithub/grappler/helpers
}

# Pre-PHASE 2: GRAFANA: Set Grafana admin password
grafanaSetAdminPw() {
	clear
	echo -e "Please enter a password for Grafana"
	read -p ">>> " -s gAdminPw
	echo -e "\n"
	echo -e "Please re-enter the password"
	read -p ">>> " -s gAdminPw_2
	echo -e "\n"
	
	# Make sure the entered passwords are the same
	while [[ "$gAdminPw" != "$gAdminPw_2" ]]
		do
			clear
			echo -e "Passwords do not match, please try again.\n"
			echo -e "Please enter a password for Grafana"
			read -p ">>> " -s gAdminPw
			echo -e "\n"
			echo -e "Please re-enter the password"
			read -p ">>> " -s gAdminPw_2
			echo -e "\n"
	done
}

# PHASE 2a: GRAFANA: Create Grafana container
grafanaCreateContainer() {
	docker create --name=grafana -p 3000:3000 --volumes-from grafana-storage -e "GF_SECURITY_ADMIN_PASSWORD=${gAdminPw}" grafana/grafana
}

# PHASE 2b: GRAFANA: Start and enable the Grafana container
grafanaStartEnableContainer() {
	docker start grafana
	sudo systemctl enable grafana.service
	sudo systemctl start grafana
}

# PHASE 2c: GRAFANA: Create Grafana update scripts and make it executable
grafanaCreateUpdateScript() {
	sudo wget -O $HOME/grapplerupdaters/grapplerupdater.sh # add link after upload
	sudo chmod +x $HOME/grapplerupdaters/grapplerupdater.sh
}