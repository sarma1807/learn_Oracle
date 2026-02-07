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

DASHED_LINE=$(seq 1 50 | xargs -I {} printf "%s" "-")

echo "${DASHED_LINE}"
echo "creating OS groups required for Oracle ..."

# oracle inventory group
groupadd --gid 54321 oinstall     > /dev/null 2>&1

# oracle asm groups
groupadd --gid 54327 asmdba       > /dev/null 2>&1
groupadd --gid 54328 asmoper      > /dev/null 2>&1
groupadd --gid 54329 asmadmin     > /dev/null 2>&1

# oracle database groups
groupadd --gid 54322 dba          > /dev/null 2>&1
groupadd --gid 54324 backupdba    > /dev/null 2>&1
groupadd --gid 54325 dgdba        > /dev/null 2>&1
groupadd --gid 54326 kmdba        > /dev/null 2>&1
groupadd --gid 54330 racdba       > /dev/null 2>&1

# optional group
groupadd --gid 54323 oper         > /dev/null 2>&1

echo "creating OS users  required for Oracle ..."

# grid infrastructure user
useradd --uid 54331 --gid oinstall --groups asmadmin,asmdba,racdba                  grid     > /dev/null 2>&1

# oracle database user
useradd --uid 54321 --gid oinstall --groups dba,asmdba,backupdba,dgdba,kmdba,racdba oracle   > /dev/null 2>&1

# if users already exist, then update their groups
usermod --gid oinstall --groups asmadmin,asmdba,racdba                    grid     > /dev/null 2>&1
usermod --gid oinstall --groups dba,asmdba,backupdba,dgdba,kmdba,racdba   oracle   > /dev/null 2>&1

echo "setting 'oracle' as default password for OS users ..."

# setup default passwords
echo   grid:oracle | chpasswd  > /dev/null 2>&1
echo oracle:oracle | chpasswd  > /dev/null 2>&1

echo "${DASHED_LINE}"
# report os groups
OS_GROUP_COUNT=$(cat /etc/group | cut -f1 -d":" | egrep "^oinstall|^asmdba|^asmoper|^asmadmin|^dba|^backupdba|^dgdba|^kmdba|^racdba|^oper" | wc -l)
echo "created following ${OS_GROUP_COUNT} OS groups :"
cat /etc/group | cut -f1 -d":" | egrep "^oinstall|^asmdba|^asmoper|^asmadmin|^dba|^backupdba|^dgdba|^kmdba|^racdba|^oper"

echo "${DASHED_LINE}"
# report os users
echo "created following OS users :"
echo ""
echo "os user : grid"
GRID_HOME=$(cat /etc/passwd | egrep grid | cut -f6 -d":" | xargs)
GRID_SHEL=$(cat /etc/passwd | egrep grid | cut -f7 -d":" | xargs)
echo "home folder for grid user : ${GRID_HOME}"
echo "      shell for grid user : ${GRID_SHEL}"
id grid
echo ""
echo "os user : oracle"
ORACLE_HOME=$(cat /etc/passwd | egrep oracle | cut -f6 -d":" | xargs)
ORACLE_SHEL=$(cat /etc/passwd | egrep oracle | cut -f7 -d":" | xargs)
echo "home folder for oracle user : ${GRID_HOME}"
echo "      shell for oracle user : ${GRID_SHEL}"
id oracle

echo "${DASHED_LINE}"

############################

