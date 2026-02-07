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

USERS_LIST="grid oracle"

for USER_NAME in ${USERS_LIST}; do
  USER_HOME=$(cat /etc/passwd | egrep "${USER_NAME}:" | cut -f6 -d":" | xargs)
  USER_SSH_DIR="${USER_HOME}/.ssh"
  rm -Rf ${USER_SSH_DIR} > /dev/null 2>&1
done

############################

