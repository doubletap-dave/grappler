#!/bin/bash

#### File: functions.sh
#### Version: 1.5a
#### Description: Functions needed in order to install Docker, Grafana, InfluxDB and Graphite
#### Author: Dave (/u/topiaryx) - topiaryx@gmail.com - 28 August 2017 - Utah

#### Load helper scripts
load_helpers() {
  source $(dirname "$0")/strings.sh
}
load_helpers

#### PREREQ: Check machine or VM IP address
check_ip() {
	ip=$(ip route get 1 | awk '{print $NF;exit}');
}

#### PREREQ: Package installer
prereq_installer() {
  yum install -y epel-release && yum update -y
  yum install -y dnf && dnf install -y yum-utils device-mapper-persistent-data lvm2 
  dnf install -y sshpass net-snmp net-snmp-devel.x86_64 net-snmp-utils.x86_64 open-vm-tools
}

#### DOCKER: Remove old installations
remove_docker() {
  dnf remove -y docker docker-ce docker-common docker-selinux docker-engine
}

#### DOCKER: Add repo
add_docker_repo() {
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
}

#### DOCKER: Install
docker_install() {
  dnf makecache && dnf install -y docker-ce
}

#### DOCKER: Run and enable
docker_run() {
  systemctl start docker && systemctl enable docker
}

#### DOCKER: Verify
docker_verify() {
  docker run hello-world
  docker ps -a | grep -i "hello-world" | gawk '{print $1}' | xargs docker rm;
  docker rmi -f hello-world
}

#### GRAFANA: Request admin password
grafana_get_admin_pw() {
  echo -e "Please enter an admin password for Grafana"
  read -p ">>> " -s g_adminpw
  echo -e "\n\n"
  
  echo -e "Please re-enter the password"
  read -p ">>> " -s g_adminpw_2
  echo -e "\n\n"
  
  while [["$g_adminpw" != "$g_adminpw_2" ]];
    do
      echo
      echo -e "Passwords do not match, please try again!"
      echo
      
      echo -e "Please enter an admin password for Grafana"
      read -p ">>> " -s g_adminpw
      echo -e "\n\n"
  
      echo -e "Please re-enter the password"
      read -p ">>> " -s g_adminpw_2
      echo -e "\n\n"
  done
}

#### GRAFANA: Create persistent storage
grafana_create_persistent_storage() {
  docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest > /dev/null 2>&1 >> \
  dgc_install.log
}

#### GRAFANA: Create container
grafana_create_container() {
  docker create --name=grafana --restart always -p 3000:3000 --volumes-from grafana-storage -e \
	"GF_SECURITY_ADMIN_PASSWORD=${g_adminpw}" grafana/grafana > /dev/null 2>&1 >> dgc_install.log
}

#### GRAFANA: Start
grafana_start() {
  docker start grafana  > /dev/null 2>&1 >> dgc_install.log
}

#### INFLUXDB: Create persistent storage
influxdb_create_persistent_storage() {
  mkdir -p /docker/containers/influxdb/conf/ > /dev/null 2>&1 >> dgc_install.log
  mkdir -p /docker/containers/influxdb/db/ > /dev/null 2>&1 >> dgc_install.log
}

#### INFLUXDB: Generate default configuration
influxdb_generate_default_config() {
  docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf 2 \
  > /dev/null 2>&1 >> dgc_install.log
}

#### INFLUXDB: Create container
influxdb_create_container() {
  docker create --name influxdb --restart always -e PUID=1000 -e PGID=1000 -p 8083:8083 -p 8086:8086 \
    -v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
		-v /docker/containers/influxdb/db:/var/lib/influxdb influxdb -config /etc/influxdb/influxdb.conf \
    > /dev/null 2>&1 >> dgc_install.log;
}

#### INFLUXDB: Start
influxdb_start() {
  docker start influxdb > /dev/null 2>&1 >> dgc_install.log;
}

#### GRAPHITE: Create container
graphite_create_container() {
  docker run -d --name graphite --restart always -p 80:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 \
 	-p 8125:8125/udp -p 8126:8126 hopsoft/graphite-statsd > /dev/null 2>&1 >> dgc_install.log;
}

#### POST: Add Docker to sudoers
docker_sudo() {
  usermod -aG docker $(logname) > /dev/null 2>&1 >> dgc_install.log;
}

#### POST: Check ownership
check_ownership () {
	chown ${USER:=$(/usr/bin/id -run)}:${USER} -R /docker > /dev/null 2>&1 >> dgc_install.log;
}

#### POST: Reboot
restart_me() {
  clear && p-all_complete
  echo
  echo -e "The machines needs to be restarted in order to apply changes and finalize the installation."
  echo -e "After the restart, Grafana can be accessed via http://${ip}:3000 with the user 'admin' and the password you created earlier in the installation."
  echo
  echo -n "Press any key to restart..."
  read -rsn1
  reboot
  
}

#### INSTALLATION

prereq_noupdate() {
  pre1b
  echo " "
  prereq_installer
  clear
}

prereq_update() {
  pre1a
  pre1b
  echo " "
  prereq_installer && dnf upgrade -y
  clear
}

install_docker() {
  p1a
  echo " "
  remove_docker
  clear
  
  p1a_c
  p1b
  echo " "
  add_docker_repo
  clear
  
  p1a_c
  p1b_c
  p1c
  echo " "
  docker_install
  clear
  
  p1a_c
  p1b_c
  p1c_c
  p1d
  echo " "
  docker_run
  clear
  
  p1a_c
  p1b_c
  p1c_c
  p1d_c
  p1e
  echo " "
  docker_verify
  clear
  
  docker_sudo
}

install_grafana() {
  p1_complete
  echo " "
  grafana_get_admin_pw
  clear
  
  p1_complete
  echo " "
  p2a
  grafana_create_persistent_storage
  clear
  
  p1_complete
  p2a_c
  echo " "
  p2b
  grafana_create_container
  clear
  
  p1_complete
  p2a_c
  p2b_c
  echo " "
  p2c
  grafana_start
  clear
}

install_influxdb() {
  p1-p2_complete
  p3a
  echo " "
  influxdb_create_persistent_storage
  clear
  
  p1-p2_complete
  p3a_c
  p3b
  echo " "
  influxdb_generate_default_config
  clear
  
  p1-p2_complete
  p3a_c
  p3b_c
  p3c
  echo " "
  influxdb_create_container
  clear
  
  p1-p2_complete
  p3a_c
  p3b_c
  p3c_c
  p3d
  echo " "
  influxdb_start
  clear
}

install_graphite() {
  p1-p3_complete
  p4a
  echo " "
  graphite_create_container
  clear
  p-all_complete
}

install_noupdate() {
  prereq_noupdate
  install_docker
  install_grafana
  install_influxdb
  install_graphite
  check_ownership
  restart_me
}

install_update() {
  prereq_update
  install_docker
  install_grafana
  install_influxdb
  install_graphite
  check_ownership
  restart_me
}