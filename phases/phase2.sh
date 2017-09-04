#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

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

# PHASE 2a: GRAFANA: Create persistent storage for Grafana
grafanaCreatePersistentStorage() {
	docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest > /dev/null 2>&1 >> dgc_install.log
}

# PHASE 2b: GRAFANA: Create Grafana container
grafanaCreateContainer() {
	docker create --name=grafana -p 3000:3000 --volumes-from grafana-storage -e "GF_SECURITY_ADMIN_PASSWORD=${gAdminPw}" grafana/grafana
}

# PHASE 2c: GRAFANA: Start and enable the Grafana container
grafanaStartEnable() {
	docker start grafana
	sudo systemctl enable grafana.service
	sudo systemctl start grafana
}

# PHASE 2d: GRAFANA: Create Grafana update scripts and make it executable
grafanaCreateUpdateScript() {
	sudo wget -O $HOME/grappler/updaters/grafanaupdater.sh https://raw.githubusercontent.com/topiaryx/grappler/master/updaters/grafanaupdater.sh
	sudo chmod +x $HOME/grappler/updaters/grapplerupdater.sh
}

grafana() {
	grafanaSetAdminPw && clear
	echo -e "Creating Persistent storage for Grafana...\n" && grafanaCreatePersistentStorage
	echo -e "Creating Docker container for Grafana...\n" && grafanaCreateContainer
	echo -e "Starting and enabling Grafana...\n" && grafanaStartEnable
	echo -e "Creating update scripts for Grafana...\n" && grafanaCreateUpdateScript
	echo -e "\nPhase 1 and 2 complete, beginning Phase 3" && clear
}