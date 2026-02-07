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

# get list of network interface names
NETWORK_INTERFACES=$(ip link show | egrep -v "altname|link" | grep eth | cut -f2 -d":" | sort | uniq | xargs)

# count network interfaces
NO_OF_NET_INTERFACES=$(echo $NETWORK_INTERFACES | wc -w | xargs)

# check if expected network interfaces are found - if not found exit with error
if [[ ${NO_OF_NET_INTERFACES} -eq 0 ]]; then
  echo "ERROR : could not find 'eth*' network interfaces"
  exit 1
fi

# process program inputs - start
INPUT_HOST_NAME=""
IGNORE_PRIVATE_INTERFACE=false
for input_arg in "$@"; do
  case "${input_arg}" in
    --full_host_name=*) INPUT_HOST_NAME="${input_arg#*=}" ;;
    --ignore_private_interface) IGNORE_PRIVATE_INTERFACE=true ;;
    *)
      echo "Please provide full hostname for this host and make sure this entry has beed added in /etc/hosts file."
      echo "Usage : $0 --full_host_name=<hostname> [ --ignore_private_interface ]"
      exit 1
      ;;
  esac
done

if [ -z "${INPUT_HOST_NAME}" ]; then
      echo "Please provide full hostname for this host and make sure this entry has beed added in /etc/hosts file."
  echo "Usage : $0 --full_host_name=<hostname> [ --ignore_private_interface ]"
  exit 1
fi
# process program inputs - end

# get input hostname entry from /etc/hosts file
HOST_FILE_ENTRY=$(cat /etc/hosts | grep "${INPUT_HOST_NAME}" | xargs)
HOST_FILE_ENTRY_COUNT=$(cat /etc/hosts | grep "${INPUT_HOST_NAME}" | wc -l)

# error if provided input hostname entry is NOT found in /etc/hosts file
if [[ ${HOST_FILE_ENTRY_COUNT} -eq 0 ]]; then
  echo "ERROR : could not find '${INPUT_HOST_NAME}' in /etc/hosts file"
  exit 1
fi

# error if provided input hostname entry is found multiple times in /etc/hosts file
if [[ ${HOST_FILE_ENTRY_COUNT} -gt 1 ]]; then
  echo "ERROR : found multiple entries matching '${INPUT_HOST_NAME}' in /etc/hosts file"
  exit 1
fi

# get input hostname private entry from /etc/hosts file
HFN=$(echo ${HOST_FILE_ENTRY} | cut -f3 -d" ")                      ### host full name
HSN=$(echo ${HOST_FILE_ENTRY} | cut -f3 -d" " | cut -f1 -d".")      ### host short name
HDN=$(echo ${HOST_FILE_ENTRY} | cut -f3 -d" " | cut -f2-3 -d".")    ### host domain name
HPN="${HSN}-priv.${HDN}"                                            ### host private full name
PRIV_HOST_FILE_ENTRY=$(cat /etc/hosts | grep "${HPN}" | xargs)
PRIV_HOST_FILE_ENTRY_COUNT=$(cat /etc/hosts | grep "${HPN}" | wc -l)


if ! ${IGNORE_PRIVATE_INTERFACE}; then
  # error if provided input hostname private entry is NOT found in /etc/hosts file
  if [[ ${PRIV_HOST_FILE_ENTRY_COUNT} -eq 0 ]]; then
    echo "ERROR : could not find '${HPN}' in /etc/hosts file"
    exit 1
  fi
  
  # error if provided input hostname private entry is found multiple times in /etc/hosts file
  if [[ ${PRIV_HOST_FILE_ENTRY_COUNT} -gt 1 ]]; then
    echo "ERROR : found multiple entries matching '${HPN}' in /etc/hosts file"
    exit 1
  fi
fi

echo "${DASHED_LINE}"

# report /etc/hosts entry
echo "found entry [ ${HOST_FILE_ENTRY} ] in /etc/hosts file"
if ! ${IGNORE_PRIVATE_INTERFACE}; then
  echo "found entry [ ${PRIV_HOST_FILE_ENTRY} ] in /etc/hosts file"
fi

# report network interfaces
echo "found ${NO_OF_NET_INTERFACES} network interfaces [ ${NETWORK_INTERFACES} ]"

echo "${DASHED_LINE}"

# configure hostname - start
echo "configuring full hostname for current host as [ ${HFN} ]"
hostnamectl set-hostname ${HFN}
if [[ $? -ne 0 ]]; then
  echo "ERROR : failed to configure hostname"
fi
# configure hostname - end

echo "${DASHED_LINE}"

# configure each network interface
for NET_INTERFACE in ${NETWORK_INTERFACES}; do

  if [[ "${NET_INTERFACE}" == "eth0" ]]; then
    HIP=$(echo ${HOST_FILE_ENTRY} | cut -f1 -d" ")    ### host public static ip
    # configure ipv4 with static ip
    nmcli connection modify ${NET_INTERFACE} ipv4.addresses ${HIP}/24 ipv4.method manual
    if [[ $? -ne 0 ]]; then
      echo "ERROR : failed to re-configured network interface '${NET_INTERFACE}' with Static IP '${HIP}'"
    else
      echo "re-configured network interface '${NET_INTERFACE}' with Static IP '${HIP}'"
    fi
    # disable ipv6
    nmcli connection modify ${NET_INTERFACE} ipv6.method disabled
    if [[ $? -ne 0 ]]; then
      echo "ERROR : failed to disable IPv6 for network interface '${NET_INTERFACE}'"
    else
      echo "disabled IPv6 for network interface '${NET_INTERFACE}'"
    fi
  fi

  if [[ "${NET_INTERFACE}" == "eth1" ]]; then
    # enable dynamic ip/dhcp for ipv4
    nmcli connection modify ${NET_INTERFACE} ipv4.method auto
    if [[ $? -ne 0 ]]; then
      echo "ERROR : failed to enable Dynamic IP/DHCP for network interface '${NET_INTERFACE}'"
    else
      echo "enabled Dynamic IP/DHCP for network interface '${NET_INTERFACE}'"
    fi
    # disable ipv6
    nmcli connection modify ${NET_INTERFACE} ipv6.method disabled
    if [[ $? -ne 0 ]]; then
      echo "ERROR : failed to disable IPv6 for network interface '${NET_INTERFACE}'"
    else
      echo "disabled IPv6 for network interface '${NET_INTERFACE}'"
    fi
  fi

  if ! ${IGNORE_PRIVATE_INTERFACE}; then
    if [[ "${NET_INTERFACE}" == "eth2" ]]; then
      PHIP=$(echo ${PRIV_HOST_FILE_ENTRY} | cut -f1 -d" ")    ### host private static ip
      # configure ipv4 with static ip
      nmcli connection modify ${NET_INTERFACE} ipv4.addresses ${PHIP}/24 ipv4.method manual
      if [[ $? -ne 0 ]]; then
        echo "ERROR : failed to re-configured network interface '${NET_INTERFACE}' with Static IP '${PHIP}'"
      else
        echo "re-configured network interface '${NET_INTERFACE}' with Static IP '${PHIP}'"
      fi
      # disable ipv6
      nmcli connection modify ${NET_INTERFACE} ipv6.method disabled
      if [[ $? -ne 0 ]]; then
        echo "ERROR : failed to disable IPv6 for network interface '${NET_INTERFACE}'"
      else
        echo "disabled IPv6 for network interface '${NET_INTERFACE}'"
      fi
    fi
  fi

done

echo "${DASHED_LINE}"

# final message
echo "changes will be applied during next system restart."
echo "COMPLETED re-configuring network interfaces."

echo "${DASHED_LINE}"

############################

