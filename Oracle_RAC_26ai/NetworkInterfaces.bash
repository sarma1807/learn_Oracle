#!/bin/bash
############################
# Author  : Sarma Pydipally
# Created : 04-FEB-2026
############################

# check if script is being executed as root - if not exit with error
if [[ ${EUID} -ne 0 ]]; then
  echo "ERROR : this script must be executed as root user"
  exit 1
fi

DASHED_LINE=$(seq 1 50 | xargs -I {} printf "%s" "-")

# define custom names file for network interfaces
CUSTOM_NETWORK_INTERFACES_FILE=/etc/udev/rules.d/70-custom-ifnames.rules

# get list of network interface names
NETWORK_INTERFACES=$(ip link show | grep -v altname | grep enp | cut -f2 -d":" | sort | uniq | xargs)

# count network interfaces
NO_OF_NET_INTERFACES=$(echo ${NETWORK_INTERFACES} | wc -w | xargs)

# check if expected network interfaces are found - if not found exit with error
if [[ ${NO_OF_NET_INTERFACES} -eq 0 ]]; then
  echo "ERROR : could not find 'enp*' network interfaces"
  exit 1
fi

# process program inputs - start
MAKE_CHANGES=false
for input_arg in "$@"; do
  case "${input_arg}" in
    --make_changes) MAKE_CHANGES=true ;;
    *)
      echo ""
      echo "This script can rename network interfaces to standard names (example : rename enp0s? to eth?)"
      echo ""
      echo "Usage : $0    # run program in REPORT ONLY mode - no changes will be performed on the system"
      echo ""
      echo "Usage : $0 --make_changes    # program will perform changes on the system"
      echo ""
      exit 1
      ;;
  esac
done
# process program inputs - end

echo "${DASHED_LINE}"

if ! ${MAKE_CHANGES}; then
  # running in REPORT ONLY mode
  # report network interfaces
  echo "found ${NO_OF_NET_INTERFACES} network interfaces [ ${NETWORK_INTERFACES} ]"
  echo "network interfaces can be renamed to standard names (example : rename enp0s? to eth?)"
  echo "use [ --make_changes ] flag, if you want to perform changes"
  echo "${DASHED_LINE}"
  exit 1
else
  # report network interfaces
  echo "found ${NO_OF_NET_INTERFACES} network interfaces [ ${NETWORK_INTERFACES} ]"
  echo "${DASHED_LINE}"
fi


# remove custom names file for network interfaces
rm -f ${CUSTOM_NETWORK_INTERFACES_FILE}

# build custom names file and network configuration file for each network interface
NET_INTERFACE_ID=0
NEW_NETWORK_INTERFACES=""
for NET_INTERFACE in ${NETWORK_INTERFACES}; do
  # define custom name for network interface
  echo "re-configuring network interface '${NET_INTERFACE}' ..."

  NEW_NETWORK_INTERFACES="${NEW_NETWORK_INTERFACES} eth${NET_INTERFACE_ID}"
  echo SUBSYSTEM==~net~,ACTION==~add~,ATTR{address}==~`ip link show ${NET_INTERFACE} | grep ether | xargs | cut -d" " -f2`~,ATTR{type}==~1~,NAME=~eth${NET_INTERFACE_ID}~ >> ${CUSTOM_NETWORK_INTERFACES_FILE}

  # prepare network interface configuration file
  cp -u /etc/NetworkManager/system-connections/${NET_INTERFACE}.nmconnection /etc/NetworkManager/system-connections/eth${NET_INTERFACE_ID}.nmconnection
  sed -i "s/${NET_INTERFACE}/eth${NET_INTERFACE_ID}/g" /etc/NetworkManager/system-connections/eth${NET_INTERFACE_ID}.nmconnection
  sed -i '/^uuid/d' /etc/NetworkManager/system-connections/eth${NET_INTERFACE_ID}.nmconnection

  ((NET_INTERFACE_ID++))
done

# clean up custom names file
sed -i 's/~/"/g' ${CUSTOM_NETWORK_INTERFACES_FILE}

echo "${DASHED_LINE}"

# cleanup leading and trailing spaces
NEW_NETWORK_INTERFACES=$(echo "${NEW_NETWORK_INTERFACES}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# final message
echo "current network interfaces [ ${NETWORK_INTERFACES} ] will be renamed to [ ${NEW_NETWORK_INTERFACES} ]"
echo "changes will be applied during next system restart."
echo "COMPLETED re-configuring network interfaces."

echo "${DASHED_LINE}"

############################

