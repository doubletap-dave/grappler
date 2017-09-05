#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker and creates containers for Grafana, InfluxDB, Telegraf and Graphite
#
# Released under the MIT license.

# To install, use the following commands
# wget https://raw.githubusercontent.com/topiaryx/grappler/master.sh && bash master.sh

#### Preliminary checks and other administravia ####

# Make sure we are root, or have root permissions
checkRoot() {
	if [ "$UID" -ne "$ROOT_UID" ]
    then
		echo "Must be root to run this script, please try again..."
		exit $E_NOTROOT
	fi
}
checkRoot

# Get the IP of the machine for later use
ip=$(ip route get 1 | awk '{print $NF;exit}')

clear

# Create log directory and update folders
echo -e "Making log and update folders..."
mkdir $HOME/grappler && mkdir $HOME/grappler/updaters && mkdir $HOME/grappler/log
echo -e "Making log and update folders...DONE!"

# Copy Grafana and InfluxDB service files
sudo wget -O /lib/systemd/system/grafana.service https://raw.githubusercontent.com/topiaryx/grappler/master/helpers/grafana.service
sudo wget -O /lib/systemd/system/influxdb.service https://raw.githubusercontent.com/topiaryx/grappler/master/helpers/influxdb.service

clear

# Welcome logo... obviously
echo "
		____ ____ ____ ___  ___  _    ____ ____ 
		| __ |__/ |__| |__] |__] |    |___ |__/ 
		|__] |  \ |  | |    |    |___ |___ |  \ 
                                        
		     Grafana stack installer v1.0
"

# Install setup files
echo -e "Installing setup files and prerequisite packages..."
sudo yum install -y epel-release && sudo yum install -y dnf dnf-plugins-core && dnf makecache fast
sudo dnf install -y device-mapper-persistent-data lvm2 sshpass net-snmp net-snmp-devel.x86_64 net-snmp-utils.x86_64 open-vm-tools
echo -e "Installing setup files and prerequisite packages...DONE"

dockerRemove() {
	sudo dnf remove -y docker docker-ce docker-common docker-selinux docker-engine
}
dockerRemove

# PHASE 1b: DOCKER: Add Docker repo
dockerAddRepo() {
	sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && dnf makecache fast
}
dockerAddRepo

# PHASE 1c: DOCKER: Install Docker
dockerInstall() {
	sudo dnf install -y docker-ce
}
dockerInstall

# PHASE 1d: DOCKER: Run and Enable :)
dockerRun() {
	sudo systemctl start docker && systemctl enable docker
}
dockerRun

# PHASE 1e: DOCKER: Add Docker to sudoers
dockerSudo() {
	sudo usermod -aG docker $(logname) > /dev/null 2>&1 >> $HOME/grappler/install.log;
}
dockerSudo

# PHASE 1f: DOCKER: Testing Docker
dockerTest() {
	docker run hello-world
	docker ps -a | grep -i "hello-world" | gawk '{print $1}' | xargs docker rm;
	docker rmi -f hello-world
}
dockerTest

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
grafanaSetAdminPw

# PHASE 2a: GRAFANA: Create persistent storage for Grafana
grafanaCreatePersistentStorage() {
	docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest > /dev/null 2>&1 >> $HOME/grappler/install.log
}
grafanaCreatePersistentStorage

# PHASE 2b: GRAFANA: Create Grafana container
grafanaCreateContainer() {
	docker create --name=grafana -p 3000:3000 --volumes-from grafana-storage -e "GF_SECURITY_ADMIN_PASSWORD=${gAdminPw}" grafana/grafana
}
grafanaCreateContainer

# PHASE 2c: GRAFANA: Start and enable the Grafana container
grafanaStartEnable() {
	docker start grafana
	sudo systemctl enable grafana.service
	sudo systemctl start grafana
}
grafanaStartEnable

# PHASE 2d: GRAFANA: Create Grafana update scripts and make it executable
grafanaCreateUpdateScript() {
	sudo wget -O $HOME/grappler/updaters/grafanaupdater.sh https://raw.githubusercontent.com/topiaryx/grappler/master/updaters/grafanaupdater.sh
	sudo chmod +x $HOME/grappler/updaters/grapplerupdater.sh
}
grafanaCreateUpdateScript

# Pre-PHASE 3: INFLUXDB: Get a name for the InfluxDB database
influxdbSetDbName() {
	echo -e "Please enter a name for your InfluxDB database name: "
	read -p ">>> " influxDbName
	clear
}
influxdbSetDbName

# PHASE 3a: INFLUXDB: Create InfluxDB persistent data
influxdbCreatePersistentStorage() {
	sudo mkdir -p /docker/containers/influxdb/conf/ > /dev/null 2>&1 >> $HOME/grappler/install.log
	sudo mkdir -p /docker/containers/influxdb/db/ > /dev/null 2>&1 >> $HOME/grappler/install.log
	checkOwner
}
influxdbCreatePersistentStorage

# PHASE 3b: INFLUXDB: Generate InfluxDB default configuration
influxdbGenerateDefaultConfig() {
	docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf
}
influxdbGenerateDefaultConfig

# PHASE 3b: INFLUXDB: Create InfluxDB container
influxdbCreateContainer() {
	docker create --name influxdb --restart always -e PUID=1000 -e PGID=1000 -p 8083:8083 -p 8086:8086 \
    -v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
	-v /docker/containers/influxdb/db:/var/lib/influxdb influxdb -config /etc/influxdb/influxdb.conf \
    > /dev/null 2>&1 >> $HOME/grappler/install.log;
}
influxdbCreateContainer

# PHASE 3c: INFLUXDB: Start and enable the InfluxDB container
influxdbStartEnable() {
	docker start influxdb
	sudo systemctl enable influxdb.service
	sudo systemctl start influxdb
}
influxdbStartEnable

# PHASE 3d: INFLUXDB: Create initial InfluxDB database
influxdbCreateDb() {
	sudo curl -G http://localhost:8086/query --data-urlencode "q=CREATE DATABASE ${influxDbName}" # Will spit out a deprecation error... disregard
}
influxdbCreateDb

# PHASE 3e: INFLUXDB: Create InfluxDB update scripts and make it executable
grafanaCreateUpdateScript() {
	sudo wget -O $HOME/grappler/updaters/influxdbupdater.sh https://raw.githubusercontent.com/topiaryx/grappler/master/updaters/influxdbupdater.sh
	sudo chmod +x $HOME/grappler/updaters/influxdbupdater.sh
}
grafanaCreateUpdateScript

# PHASE 4a: TELEGRAF: Create Telegraf persistent data
telegrafCreatePersistentStorage() {
	sudo mkdir -p /docker/containers/telegraf/
}
telegrafCreatePersistentStorage

# PHASE 4b: TELEGRAF: Create Telegraf default configuration
telegrafGenerateDefaultConfiguration() {
	docker run --rm telegraf -sample-config > /docker/containers/telegraf/conf/telegraf.conf
}
telegrafGenerateDefaultConfiguration

# PHASE 4c: TELEGRAF: Create telegraf update scripts and make it executable
telegrafCreateUpdateScript() {
	sudo wget -O $HOME/grappler/updaters/telegrafupdater.sh https://raw.githubusercontent.com/topiaryx/grappler/master/updaters/telegrafupdater.sh
	sudo chmod +x $HOME/grappler/updaters/telegrafupdater.sh
}
telegrafCreateUpdateScript

# PHASE 4e: TELEGRAF: Start and enable the Telegraf cotainer
telegrafStartEnable() {
	docker start influxdb
	sudo systemctl enable influxdb.service
	sudo systemctl start influxdb
}
telegrafStartEnable

# PHASE 5: GRAPHITE: Create Graphite container
graphiteCreateContainer() {
  docker run -d --name graphite --restart always -p 80:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 \
 	-p 8125:8125/udp -p 8126:8126 hopsoft/graphite-statsd > /dev/null 2>&1 >> $HOME/grappler/install.log;
}
graphiteCreateContainer

checkOwner () {
	chown ${USER:=$(/usr/bin/id -run)}:${USER} -R /docker > /dev/null 2>&1 >> $HOME/grappler/install.log;
}
checkOwner

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
restartMe