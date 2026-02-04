#!/bin/bash
############################
# Author  : Sarma Pydipally
# Created : 04-FEB-2026
############################

# check if script is being executed as root - if not exit with error
if [[ ${EUID} -ne 0 ]]; then
  echo "ERROR : this script must be executed as root user" >&2
  exit 1
fi

# process program inputs - start
MAKE_CHANGES=false
for input_arg in "$@"; do
  case "${input_arg}" in
    --make_changes) MAKE_CHANGES=true ;;
    *)
      echo "" >&2
      echo "This script prepares disks for Oracle ASM usage" >&2
      echo "*** WARNING : THIS SCRIPT CAN DESTROY CONTENTS/PARTITIONS OF THE DISKS ***" >&2
      echo "" >&2
      echo "Usage : $0    # run program in REPORT ONLY mode - no changes will be performed on the system" >&2
      echo "" >&2
      echo "Usage : $0 --make_changes    # program will perform changes on the system" >&2
      echo "" >&2
      exit 1
      ;;
  esac
done
# process program inputs - end

# input asm disks list file
ASM_DISKS_FILE=/etc/oracle-asm-disks
touch ${ASM_DISKS_FILE} > /dev/null 2>&1
# load defined asm disks list from file
LIST_OF_DISKS_FOR_ASM=$(egrep -v "^#" ${ASM_DISKS_FILE} | sort | uniq | xargs)
# count LIST_OF_DISKS_FOR_ASM
COUNT_OF_DISKS_FOR_ASM=$(echo ${LIST_OF_DISKS_FOR_ASM} | wc -w | xargs)

# if asm disks are not defined inside input file
if [[ ${COUNT_OF_DISKS_FOR_ASM} -eq 0 ]]; then
  echo "reading ASM Disks File : ${ASM_DISKS_FILE}"
  echo "ERROR : could not find any disks listed for Oracle ASM usage in above listed 'ASM Disks File' file" >&2
  echo "USAGE :" >&2
  echo "- add entries for disks, which you want to use for Oracle ASM in above listed 'ASM Disks File' file" >&2
  echo "- add one disk per line entry" >&2
  echo "EXAMPLES OF VALID ENTRIES :" >&2
  echo "/dev/sdb" >&2
  echo "/dev/sdc" >&2
  echo "/dev/sdd" >&2
  echo "DO NOT ADD PARTITION NAMES, SUCH AS FOLLOWING :" >&2
  echo "/dev/sdx1" >&2
  echo "/dev/sdx2" >&2
  echo "/dev/sdy1" >&2
  exit 1
fi


# get list of available disks
LIST_OF_AVAILABLE_DISKS=$(ls -l /dev/sd? | rev | cut -f1 -d" " | rev | xargs)

# for safety suspected "boot disks" will be excluded from this operation
# get boot disk details
LIST_OF_BOOT_DISKS_1=$(df -hP | grep -i boot | cut -f1 -d" " | xargs)
LIST_OF_BOOT_DISKS_2=$(df -hP | grep -i boot | cut -f1 -d" " | rev | cut -c 2- | rev | xargs)

# get common entries between LIST_OF_DISKS_FOR_ASM and LIST_OF_AVAILABLE_DISKS
LIST_OF_VALID_ASM_DISKS_TEMP_1=$(comm -12 <(echo "${LIST_OF_DISKS_FOR_ASM}" | tr ' ' '\n' | sort) <(echo "${LIST_OF_AVAILABLE_DISKS}" | tr ' ' '\n' | sort) | xargs)

# remove LIST_OF_BOOT_DISKS_1 and LIST_OF_BOOT_DISKS_2 from LIST_OF_VALID_ASM_DISKS_TEMP_1
LIST_OF_VALID_ASM_DISKS_TEMP_2=$(comm -23 <(echo ${LIST_OF_VALID_ASM_DISKS_TEMP_1} | tr ' ' '\n' | sort) <(echo ${LIST_OF_BOOT_DISKS_1} | tr ' ' '\n' | sort) | xargs)
LIST_OF_VALID_ASM_DISKS_FINAL=$(comm -23 <(echo ${LIST_OF_VALID_ASM_DISKS_TEMP_2} | tr ' ' '\n' | sort) <(echo ${LIST_OF_BOOT_DISKS_2} | tr ' ' '\n' | sort) | xargs)
LIST_OF_VALID_ASM_DISKS_FINAL_COUNT=$(echo ${LIST_OF_VALID_ASM_DISKS_FINAL} | wc -w | xargs)


# check if final list of disks for Oracle ASM use is empty - if yes then exit with error
if [[ ${LIST_OF_VALID_ASM_DISKS_FINAL_COUNT} -eq 0 ]]; then
  echo "ERROR : could not identify any disks for Oracle ASM usage" >&2
  echo "ASM Disks File : ${ASM_DISKS_FILE}"
  echo "USAGE :" >&2
  echo "- add entries for disks, which you want to use for Oracle ASM in above listed 'ASM Disks File' file" >&2
  echo "- add one disk per line entry" >&2
  echo "EXAMPLES OF VALID ENTRIES :" >&2
  echo "/dev/sdb" >&2
  echo "/dev/sdc" >&2
  echo "/dev/sdd" >&2
  echo "DO NOT ADD PARTITION NAMES, SUCH AS FOLLOWING :" >&2
  echo "/dev/sdx1" >&2
  echo "/dev/sdx2" >&2
  echo "/dev/sdy1" >&2
  exit 1
fi


# if we reached here - means we found few disks for Oracle ASM usage

# define udev rules file for asm devices
CUSTOM_ASM_UDEV_RULES_FILE=/etc/udev/rules.d/99-oracle-asmdevices.rules
touch ${CUSTOM_ASM_UDEV_RULES_FILE} > /dev/null 2>&1
sed -i 's/"/~/g' ${CUSTOM_ASM_UDEV_RULES_FILE}


# print dashed line
echo $(seq 1 50 | xargs -I {} printf "%s" "-")

# print final list of disks for Oracle ASM usage
echo "identified ${LIST_OF_VALID_ASM_DISKS_FINAL_COUNT} disk(s) [ ${LIST_OF_VALID_ASM_DISKS_FINAL} ] which can be used for Oracle ASM"

if ! ${MAKE_CHANGES}; then
  # running in REPORT ONLY mode
  echo "use [ --make_changes ] flag, if you want to perform changes"
  # print dashed line
  echo $(seq 1 50 | xargs -I {} printf "%s" "-")
  exit 1
else
  # proceed to next steps
  # print dashed line
  echo $(seq 1 50 | xargs -I {} printf "%s" "-")
fi


# process each disk and prepare it for Oracle ASM usage
for ASMDISK in ${LIST_OF_VALID_ASM_DISKS_FINAL}; do
  echo "re-configuring '${ASMDISK}' disk for Oracle ASM usage..."

  echo "deleting any existing partitions ..."
  echo -e "d\nw" | fdisk ${ASMDISK} > /dev/null 2>&1

  echo "creating new partition ..."
  echo -e "n\np\n1\n\n\nw" | fdisk ${ASMDISK} > /dev/null 2>&1

  ### ${ASMDISK} like /dev/sdb
  ASMDISK_PART="${ASMDISK}1"     ### like /dev/sdb1
  ASMDISK_PART_ALONE=$(echo "${ASMDISK_PART}" | rev | cut -f1 -d"/" | rev)     ### like sdb1

  DISK_SCSI_ID=$(/usr/lib/udev/scsi_id -g -u -d ${ASMDISK_PART})
  if [[ $? -ne 0 ]]; then
    echo "ERROR : failed to identify scsi_id for the disk"
  else
    # if there is an existing entry for same disk, then mark it for deletion
    SEARCH_FOR="KERNEL==~${ASMDISK_PART_ALONE}~"
    sed -i "s/${SEARCH_FOR}/### DELETE THIS ENTRY ### ${SEARCH_FOR}/g" ${CUSTOM_ASM_UDEV_RULES_FILE}

    # count entries in udev rules file - ignore any COMMENTED lines
    UDEV_ENTRIES=$(cat ${CUSTOM_ASM_UDEV_RULES_FILE} | egrep -v "^#" | wc -l)
    ((UDEV_ENTRIES++))
    NEXT_ASMDISK_NUMBER=$(printf "%03d" "${UDEV_ENTRIES}")

    # build and add new entry to udev rules file for this asm disk
    FINAL_UDEV_ENTRY="KERNEL==~${ASMDISK_PART_ALONE}~, SUBSYSTEM==~block~, PROGRAM==~/usr/lib/udev/scsi_id -g -u -d ${ASMDISK_PART}~, RESULT==~${DISK_SCSI_ID}~, SYMLINK+=~oracleasm/asmdisk_${NEXT_ASMDISK_NUMBER}~, OWNER=~grid~, GROUP=~asmdba~, MODE=~0660~"
    echo "${FINAL_UDEV_ENTRY}" >> ${CUSTOM_ASM_UDEV_RULES_FILE}
    echo "added entry to asm devices udev rules file for this disk ..."
  fi

  # print dashed line
  echo $(seq 1 50 | xargs -I {} printf "%s" "-")
done

# clean up udev rules file for Oracle ASM disks
sed -i "/# DELETE THIS ENTRY #/d" ${CUSTOM_ASM_UDEV_RULES_FILE}
sed -i 's/~/"/g' ${CUSTOM_ASM_UDEV_RULES_FILE}

# display udev rules file for asm devices
echo "udev rules file for Oracle ASM devices : ${CUSTOM_ASM_UDEV_RULES_FILE}"
echo "contents of this file :"
cat ${CUSTOM_ASM_UDEV_RULES_FILE}
# print dashed line
echo $(seq 1 50 | xargs -I {} printf "%s" "-")

# final message
echo "[ ${LIST_OF_VALID_ASM_DISKS_FINAL} ] disk(s) are now ready for Oracle ASM usage."
echo "changes will be applied during next system restart."
echo "COMPLETED re-configuring disk(s) for Oracle ASM usage."

# print dashed line
echo $(seq 1 50 | xargs -I {} printf "%s" "-")

############################

