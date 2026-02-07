#!/bin/bash
############################
# Author  : Sarma Pydipally
# Created : 07-FEB-2026
############################

# check if script is being executed as root - if not exit with error
if [[ ${EUID} -ne 0 ]]; then
  echo "ERROR : this script must be executed as root user"
  exit 1
fi

DASHED_LINE=$(seq 1 50 | xargs -I {} printf "%s" "-")
USERS_LIST="grid oracle"

# process program inputs - start
DISTRIBUTE_SSHKEYS=false
VERIFY_SSHKEYS=false
PRINT_HELP=true
for input_arg in "$@"; do
  case "${input_arg}" in
    --servers=*) INPUT_SERVERS_LIST="${input_arg#*=}" ; INPUT_SERVERS="${INPUT_SERVERS_LIST//,/ }" ;;
    --distribute_sshkeys) DISTRIBUTE_SSHKEYS=true  ; VERIFY_SSHKEYS=true ; PRINT_HELP=false ;;
    --verify_sshkeys)     DISTRIBUTE_SSHKEYS=false ; VERIFY_SSHKEYS=true ; PRINT_HELP=false ;;
    *) PRINT_HELP=true ;;
  esac
done
# process program inputs - end

# validate input
if [ -z "${INPUT_SERVERS_LIST}" ]; then PRINT_HELP=true ; fi

# print help and exit
if ${PRINT_HELP}; then
  echo ""
  echo "NOTE : THIS SCRIPT ASSUMES THE PASSWORD FOR 'grid AND oracle' USERS IS 'oracle'. IF NOT, IT WILL FAIL TO EXECUTE."
  echo ""
  echo "This can distribute and verify password-less ssh for 'grid and oracle' users between servers."
  echo ""
  echo 'provide list of servers to which ssh keys will be distributed using --servers="<server1>,<server2>"'
  echo 'example : --servers="oramad1,oramad2,oramad3"'
  echo "make sure to add these servers to /etc/hosts file."
  echo ""
  echo "Usage 1 : $0 --servers=\"<server_list>\" --distribute_sshkeys    # distribute ssh keys to all servers"
  echo "Usage 2 : $0 --servers=\"<server_list>\" --verify_sshkeys        # verify password-less ssh configuration"
  echo ""
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

# verify if users exist on system
VALID_USERS_LIST=""
echo "${DASHED_LINE}"
for USER_NAME in ${USERS_LIST}; do
  # get user home folder location
  USER_HOME=$(cat /etc/passwd | egrep "${USER_NAME}:" | cut -f6 -d":" | xargs)

  if [ -z "${USER_HOME}" ]; then
    echo "ERROR : unable to identify/locate '${USER_NAME}' user on this system."
  else
    VALID_USERS_LIST="${VALID_USERS_LIST} ${USER_NAME}"
    echo "INFO : found '${USER_NAME}' user on this system."
  fi
done
echo "${DASHED_LINE}"

# count valid users and exit if valid users = zero
NO_OF_VALID_USERS=$(echo ${VALID_USERS_LIST} | wc -w | xargs)
if [[ ${NO_OF_VALID_USERS} -eq 0 ]]; then
  echo "ERROR : [ ${USERS_LIST} ] users are missing on this system."
  exit 1
fi


# distribute_sshkeys
if ${DISTRIBUTE_SSHKEYS}; then
  echo "${DASHED_LINE}"
  echo "distributing ssh keys to all servers ..."
  for USER_NAME in ${VALID_USERS_LIST}; do
    echo "${DASHED_LINE}"
    echo "for '${USER_NAME}' user : "
    for SERVERNAME in ${INPUT_SERVERS}; do
      echo "distributing ssh keys to '${SERVERNAME}' server ..."
      SSH_OUTPUT=$(su - ${USER_NAME} -c "sshpass -p 'oracle' ssh-copy-id -o StrictHostKeyChecking=no ${SERVERNAME}" 2>&1)
      echo "${SSH_OUTPUT}" | egrep -i "ERROR"
    done
  done
  echo "${DASHED_LINE}"
fi


# verify_sshkeys
if ${VERIFY_SSHKEYS}; then
  echo "${DASHED_LINE}"
  echo "verifying password-less ssh with all servers ..."
  for USER_NAME in ${VALID_USERS_LIST}; do
    echo "${DASHED_LINE}"
    echo "for '${USER_NAME}' user : "
    # get user home folder location
    USER_HOME=$(cat /etc/passwd | egrep "${USER_NAME}:" | cut -f6 -d":" | xargs)
    USER_SSH_DIR="${USER_HOME}/.ssh"
    if [ -d "${USER_SSH_DIR}" ] && ( [ -f "${USER_SSH_DIR}/id_rsa" ] || [ -f "${USER_SSH_DIR}/id_rsa.pub" ] ); then
      echo "ssh keys EXIST in ${USER_SSH_DIR}"
      for SERVERNAME in ${INPUT_SERVERS}; do
        echo "verifying password-less ssh with '${SERVERNAME}' server ..."
        su - ${USER_NAME} -c "ssh -o BatchMode=yes -o ConnectTimeout=5 ${SERVERNAME} echo 'ssh connection successful'"
        if [ $? -ne 0 ]; then echo 'ssh connection failed' ; fi
      done
    else
      echo "could NOT find ssh keys in RSA format."
      echo "skipping verification of password-less ssh with '${SERVERNAME}' server ..."
    fi
  done
  echo "${DASHED_LINE}"
  echo "INFO : remember to run $0 with --distribute_sshkeys on all other servers"
  echo "${DASHED_LINE}"
fi

############################

