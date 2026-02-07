#!/bin/bash
############################
# Author  : Sarma Pydipally
# Created : 04-FEB-2026
############################

# check if script is being executed as root - if not exit with error
if [[ ${EUID} -ne 0 ]]; then
  echo "ERROR : This script must be executed as root user"
  exit 1
fi

rm -f /etc/udev/rules.d/70-custom-ifnames.rules
cat /dev/null > /etc/hostname
rm -f /etc/NetworkManager/system-connections/eth?.nmconnection

echo "system will restart in 10 seconds ..."
sleep 10
shutdown -r now

############################

