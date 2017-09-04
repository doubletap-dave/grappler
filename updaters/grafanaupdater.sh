#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.
#
# 

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

timestamper() {
	date +"%Y-%m-%d_%H-%M-%S"
}
timestamper

# GRAFANA: Set Grafana admin password
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
grafanaSetAdminPw && clear

echo "Pulling latest from grafana/grafana"
docker pull grafana/grafana

echo "Stopping grafana container"
docker stop grafana

echo "Backing up old grafana container to grafana__$(timestamper)"
docker rename grafana grafana__$(timestamper)

echo "Creating and starting new grafana container"
docker create --name=grafana -p 3000:3000 --volumes-from grafana-storage -e "GF_SECURITY_ADMIN_PASSWORD=gAdminPw" \
grafana/grafana

docker start grafana