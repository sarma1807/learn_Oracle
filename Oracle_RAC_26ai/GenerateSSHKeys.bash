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
GENERATE_SSHKEYS=false
VERIFY_ONLY=true
for input_arg in "$@"; do
  case "${input_arg}" in
    --generate_sshkeys) GENERATE_SSHKEYS=true ; VERIFY_ONLY=false ;;
    *) VERIFY_ONLY=true ;;
  esac
done
# process program inputs - end

if ${VERIFY_ONLY}; then
  # process each user from list
  for USER_NAME in ${USERS_LIST}; do
    echo "${DASHED_LINE}"
    echo "verifying ssh keys for '${USER_NAME}' user ..."

    # get user home folder location
    USER_HOME=$(cat /etc/passwd | egrep "${USER_NAME}:" | cut -f6 -d":" | xargs)

    if [ -z "${USER_HOME}" ]; then
      echo "ERROR : unable to identify/locate '${USER_NAME}' user."
    else
      # check if ssh keys exist in user home
      USER_SSH_DIR="${USER_HOME}/.ssh"
      if [ -d "${USER_SSH_DIR}" ] && ( [ -f "${USER_SSH_DIR}/id_rsa" ] || [ -f "${USER_SSH_DIR}/id_rsa.pub" ] ); then
        echo "for ${USER_NAME} user : ssh keys EXIST in ${USER_SSH_DIR}"
      else
        echo "for ${USER_NAME} user : could NOT find ssh keys in RSA format."
      fi
    fi
  done
  echo "${DASHED_LINE}"

  # display program help
  echo ""
  echo "This program can re-generate new ssh keys for [ ${USERS_LIST} ] users."
  echo "Usage : $0 --generate_sshkeys    # program will REMOVE existing ssh keys and will generate new ssh keys"
  echo ""

  echo "${DASHED_LINE}"
  exit
fi


# if we reached here - means user has request to remove existing ssh keys and re-generate new ssh keys

# process each user from list
for USER_NAME in ${USERS_LIST}; do
  echo "${DASHED_LINE}"
  echo "removing existing ssh keys for '${USER_NAME}' user ..."

  # get user home folder location
  USER_HOME=$(cat /etc/passwd | egrep "${USER_NAME}:" | cut -f6 -d":" | xargs)

  if [ -z "${USER_HOME}" ]; then
    echo "ERROR : unable to identify/locate '${USER_NAME}' user."
  else
    # remove existing ssh keys in user home
    USER_SSH_DIR="${USER_HOME}/.ssh"
    rm -f ${USER_SSH_DIR}/id_rsa     > /dev/null 2>&1
    rm -f ${USER_SSH_DIR}/id_rsa.pub > /dev/null 2>&1

    # generate new ssh keys
    echo "generating new ssh keys for '${USER_NAME}' user ..."
    su - ${USER_NAME} -c "ssh-keygen -t rsa -b 4096 -N '' <<<$'\n'" | egrep -v "^Generating public|^Enter file|Created directory|^Your|^The key fingerprint|^SHA256"
  fi
done
echo "${DASHED_LINE}"

echo "you should carefully review above output and fix ERRORs."

echo "${DASHED_LINE}"

############################

