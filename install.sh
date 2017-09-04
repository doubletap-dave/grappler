#!/usr/bin/env bash
#
# Grappler: Grafana stack installer for CentOS 7+
# Installs Docker, Grafana, InfluxDB, Graphite and Telegraf 
#
# This file is released under whatever license.

# Install with this command:
#
# curl -sSL https://grappler.davemobley.net | bash

rootCheck() {
  if [ "$UID" -ne "$ROOT_UID" ]
    then
      echo "Must be root to run this script."
      exit $E_NOTROOT
  fi
}
rootCheck

