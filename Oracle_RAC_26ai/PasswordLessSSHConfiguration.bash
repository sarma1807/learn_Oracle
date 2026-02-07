#!/bin/bash
############################
# Author  : Sarma Pydipally
# Created : 06-FEB-2026
############################

# check if script is being executed as root - if not exit with error
if [[ ${EUID} -ne 0 ]]; then
  echo "ERROR : this script must be executed as root user" >&2
  exit 1
fi

# process program inputs - start
MAKE_CHANGES=false
PRINT_HELP=false
for input_arg in "$@"; do
  case "${input_arg}" in
    --servers=*) INPUT_SERVERS="${input_arg#*=}" ;;
    --make_changes) MAKE_CHANGES=true ;;
    *) PRINT_HELP=true ;;
  esac
done
# process program inputs - end

# validate input
if [ -z "${INPUT_SERVERS}" ]; then PRINT_HELP=true ; fi
if ! ${MAKE_CHANGES}; then PRINT_HELP=true ; fi

# print help and exit
if ${PRINT_HELP}; then
  echo "" >&2
  echo "WARNING : THIS SCRIPT WILL DELETE ALL EXISTING SSH KEYS FOR 'grid AND oracle' USERS." >&2
  echo "   NOTE : THIS SCRIPT ASSUMES THE PASSWORD FOR 'grid AND oracle' USERS IS 'oracle'. IF NOT, IT WILL FAIL TO EXECUTE." >&2
  echo "" >&2
  echo "This script will configure password-less ssh for 'grid and oracle' users between servers." >&2
  echo "" >&2
  echo 'provide list of servers to which ssh keys will be distributed using --servers="<server1>,<server2>"' >&2
  echo 'example : --servers="oramad1,oramad2,oramad3"' >&2
  echo "make sure to add these servers to /etc/hosts file." >&2
  echo "" >&2
  echo "Usage : $0 --servers=\"<server_list>\" --make_changes    # program will perform changes on the system" >&2
  echo "" >&2
  exit 1
fi


# verify if sshpass is available
CHECK_SSHPASS=$(sshpass 2>&1 >/dev/null)
DO_WE_HAVE_SSHPASS=$(echo ${CHECK_SSHPASS} | rev | cut -f1 -d":" | rev | xargs)
if [[ "${DO_WE_HAVE_SSHPASS}" == "command not found" ]]; then
  echo ""
  echo "ERROR : sshpass is not available on this system."
  echo " INFO : sshpass can be installed by running following command as root user :"
  echo "dnf install sshpass --assumeyes"
  echo ""
  exit 1
fi


# print dashed line
echo $(seq 1 50 | xargs -I {} printf "%s" "-")

# grid user - start
echo "working on ssh keys for 'grid' user ..."
GRID_HOME=$(cat /etc/passwd | egrep grid | cut -f6 -d":" | xargs)
if [ -z "${GRID_HOME}" ]; then
  echo "ERROR : unable to identify/locate 'grid' user."
  echo "skipping password-less ssh configuration changes for 'grid' user."
else
  echo "removing existing ssh keys from 'grid' user ..."
  rm -Rf ${GRID_HOME}/.ssh/id_rsa     > /dev/null 2>&1
  rm -Rf ${GRID_HOME}/.ssh/id_rsa.pub > /dev/null 2>&1

  echo "generating new ssh keys for 'grid' user ..."
  su - grid -c "ssh-keygen -t rsa -b 4096 -N '' <<<$'\n'" | egrep -v "^Generating public|^Enter file|Created directory|^Your|^The key fingerprint|^SHA256"

  echo "attempting to exchange ssh keys for 'grid' user with all servers ..."
  IFS=','
  for SERVERNAME in ${INPUT_SERVERS}; do
    # su - grid -c "sshpass -p 'oracle' ssh-copy-id -o StrictHostKeyChecking=no ${SERVERNAME}" > /dev/null 2>&1
    su - grid -c "sshpass -p 'oracle' ssh-copy-id -o StrictHostKeyChecking=no ${SERVERNAME}"
  done

  # print dashed line
  echo $(seq 1 50 | xargs -I {} printf "%s" "-")
  echo "attempting to verify ssh keys configuration for 'grid' user by logging into all servers ..."
  IFS=','
  for SERVERNAME in ${INPUT_SERVERS}; do
    su - grid -c "ssh ${SERVERNAME} 'echo `date` from `hostname` as `whoami` user.'"
  done
fi
# grid user - end

# print dashed line
echo $(seq 1 50 | xargs -I {} printf "%s" "-")

# oracle user - start
echo "working on ssh keys for 'oracle' user ..."
ORACLE_HOME=$(cat /etc/passwd | egrep oracle | cut -f6 -d":" | xargs)
if [ -z "${ORACLE_HOME}" ]; then
  echo "ERROR : unable to identify/locate 'oracle' user."
  echo "skipping password-less ssh configuration changes for 'oracle' user."
else
  echo "removing existing ssh keys from 'oracle' user ..."
  rm -Rf ${ORACLE_HOME}/.ssh/id_rsa     > /dev/null 2>&1
  rm -Rf ${ORACLE_HOME}/.ssh/id_rsa.pub > /dev/null 2>&1

  echo "generating new ssh keys for 'oracle' user ..."
  su - oracle -c "ssh-keygen -t rsa -b 4096 -N '' <<<$'\n'" | egrep -v "^Generating public|^Enter file|Created directory|^Your|^The key fingerprint|^SHA256"

  echo "attempting to exchange ssh keys for 'oracle' user with all servers ..."
  IFS=','
  for SERVERNAME in ${INPUT_SERVERS}; do
    # su - oracle -c "sshpass -p 'oracle' ssh-copy-id -o StrictHostKeyChecking=no ${SERVERNAME}" > /dev/null 2>&1
    su - oracle -c "sshpass -p 'oracle' ssh-copy-id -o StrictHostKeyChecking=no ${SERVERNAME}"
  done

  # print dashed line
  echo $(seq 1 50 | xargs -I {} printf "%s" "-")
  echo "attempting to verify ssh keys configuration for 'oracle' user by logging into all servers ..."
  IFS=','
  for SERVERNAME in ${INPUT_SERVERS}; do
    su - oracle -c "ssh ${SERVERNAME} 'echo `date` from `hostname` as `whoami` user.'"
  done
fi
# oracle user - end

# print dashed line
echo $(seq 1 50 | xargs -I {} printf "%s" "-")

echo "you should carefully review above output and fix ERRORs."

# print dashed line
echo $(seq 1 50 | xargs -I {} printf "%s" "-")

############################

