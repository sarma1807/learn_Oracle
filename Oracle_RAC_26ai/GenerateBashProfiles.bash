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
HOST_NUMBER=$(hostname -s | rev | cut -c1)
GI_USERS_LIST="root grid"
DB_USERS_LIST="oracle"

# process program inputs - start
MAKE_CHANGES=false
for input_arg in "$@"; do
  case "${input_arg}" in
    --make_changes) MAKE_CHANGES=true ;;
    *)
      echo ""
      echo "This script will remove and re-create a new version of ~/.bash_profile file with custom configuration."
      echo ""
      echo "Usage : $0 --make_changes    # program will perform changes on the system"
      echo ""
      exit 1
      ;;
  esac
done
# process program inputs - end

echo "${DASHED_LINE}"

# process each user from list GI_USERS_LIST
for USER_NAME in ${GI_USERS_LIST}; do
  # get user home folder location
  USER_HOME=$(cat /etc/passwd | egrep "${USER_NAME}:" | grep -v "nologin" | cut -f6 -d":" | xargs)

  if [ -z "${USER_HOME}" ]; then
    echo "ERROR : unable to identify/locate '${USER_NAME}' user."
  else
    USER_BASH_PROFILE="${USER_HOME}/.bash_profile"

    # write entries to .bash_profile - start
    echo "# .bash_profile"                                               > ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "# Get the aliases and functions"                              >> ${USER_BASH_PROFILE}
    echo "if [ -f ~/.bashrc ]; then"                                    >> ${USER_BASH_PROFILE}
    echo "  . ~/.bashrc"                                                >> ${USER_BASH_PROFILE}
    echo "fi"                                                           >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "# User specific environment and startup programs"             >> ${USER_BASH_PROFILE}
    echo "# shell prompt"                                               >> ${USER_BASH_PROFILE}
    echo "export PS1=\"[\u@\h \W]( \""                                  >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "# Oracle ASM instance related environment variables"          >> ${USER_BASH_PROFILE}
    echo "export CVUQDISK_GRP=oinstall"                                 >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "export ORACLE_SID=+ASM${HOST_NUMBER}"                         >> ${USER_BASH_PROFILE}
    echo "export ORACLE_BASE=/u01/app/grid"                             >> ${USER_BASH_PROFILE}
    echo "export ORACLE_HOME=/u01/app/26ai/gridHome01"                  >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "export PATH=\$PATH:.:\$ORACLE_HOME/bin"                       >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "echo -----------------------------------------------------"   >> ${USER_BASH_PROFILE}
    echo "echo -e \"ORACLE_BASE : \${ORACLE_BASE}\""                    >> ${USER_BASH_PROFILE}
    echo "echo -e \"ORACLE_HOME : \${ORACLE_HOME}\""                    >> ${USER_BASH_PROFILE}
    echo "echo -e \"ORACLE_SID  : \${ORACLE_SID}\""                     >> ${USER_BASH_PROFILE}
    echo "echo -----------------------------------------------------"   >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    # write entries to .bash_profile - end

    if [[ "${USER_NAME}" == "root" ]]; then
      sed -i "s/](/]#/g" ${USER_BASH_PROFILE}
    else
      sed -i "s/](/]$/g" ${USER_BASH_PROFILE}
    fi

    echo "re-created '${USER_BASH_PROFILE}' for ${USER_NAME}"
  fi
done

# process each user from list DB_USERS_LIST
for USER_NAME in ${DB_USERS_LIST}; do
  # get user home folder location
  USER_HOME=$(cat /etc/passwd | egrep "${USER_NAME}:" | grep -v "nologin" | cut -f6 -d":" | xargs)

  if [ -z "${USER_HOME}" ]; then
    echo "ERROR : unable to identify/locate '${USER_NAME}' user."
  else
    USER_BASH_PROFILE="${USER_HOME}/.bash_profile"

    # write entries to .bash_profile - start
    echo "# .bash_profile"                                               > ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "# Get the aliases and functions"                              >> ${USER_BASH_PROFILE}
    echo "if [ -f ~/.bashrc ]; then"                                    >> ${USER_BASH_PROFILE}
    echo "  . ~/.bashrc"                                                >> ${USER_BASH_PROFILE}
    echo "fi"                                                           >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "# User specific environment and startup programs"             >> ${USER_BASH_PROFILE}
    echo "# shell prompt"                                               >> ${USER_BASH_PROFILE}
    echo "export PS1=\"[\u@\h \W]\$ \""                                 >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "# Oracle DB instance related environment variables"           >> ${USER_BASH_PROFILE}
    echo "export CVUQDISK_GRP=oinstall"                                 >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "export ORACLE_UNQNAME=ora26ai"                                >> ${USER_BASH_PROFILE}
    echo "export ORACLE_SID=ora26ai${HOST_NUMBER}"                      >> ${USER_BASH_PROFILE}
    echo "export ORACLE_BASE=/u01/app/oracle"                           >> ${USER_BASH_PROFILE}
    echo "export ORACLE_HOME=/u01/app/oracle/product/26ai/dbHome01"     >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "export PATH=\$PATH:.:\$ORACLE_HOME/bin"                       >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo "echo -----------------------------------------------------"   >> ${USER_BASH_PROFILE}
    echo "echo -e \"ORACLE_BASE : \${ORACLE_BASE}\""                    >> ${USER_BASH_PROFILE}
    echo "echo -e \"ORACLE_HOME : \${ORACLE_HOME}\""                    >> ${USER_BASH_PROFILE}
    echo "echo -e \"ORACLE_SID  : \${ORACLE_SID}\""                     >> ${USER_BASH_PROFILE}
    echo "echo -----------------------------------------------------"   >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    echo ""                                                             >> ${USER_BASH_PROFILE}
    # write entries to .bash_profile - end

    echo "re-created '${USER_HOME}/.bash_profile' for ${USER_NAME}"
  fi
done

echo "${DASHED_LINE}"

############################

