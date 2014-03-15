#!/bin/bash
#
#  Backup script
#               Author: Brian Cheldelin

POOL_NAME="tank"
BACKUP_DIR="/mnt/lfs"

# List Of ZFS directories
ZFS_DIR_LIST=($(zfs list -H -o name | xargs -I {} basename {}))
unset ZFS_DIR_LIST[0] # Removes leading "tank"

# List of Lustre directories
LFS_DIR_LIST=($(find "${BACKUP_DIR}"/* -maxdepth 0 -type d -printf "%f\n"))
unset ZFS_DIR_LIST[0] # Remove parant tank element

# List of Unwanted Directories to backup
declare -a UNWANTED_DIR=(accounting checkpoint graveyard data module)

# List of Previously Backed up directories
touch backup.log
DONE_DIR_LIST=($(cat backup.log))

function destroyElement() {
    local z=0;
    for str in "${LFS_DIR_LIST[@]}"; do
        if [ "$str" = "$1" ]; then
            LFS_DIR_LIST=(${LFS_DIR_LIST[@]:0:$z} ${LFS_DIR_LIST[@]:$(($z + 1))})
        else
            ((z++))
        fi
    done
}

for str in ""${UNWANTED_DIR[@]}" "${DONE_DIR_LIST[@]}""; do
         destroyElement $str
done

# Create List of zfs directories to create
ZFS_DIR_CREATE=($(comm -3 -1 <(printf "%s\n" "${ZFS_DIR_LIST[@]}") <(printf "%s\n" "${LFS_DIR_LIST[@]}")))

# Check that each entry in LFS_DIR_LIST has an entry in ZFS_DIR_LIST
#       If not create a zfs mount point
if [ "${#ZFS_DIR_CREATE[*]}" -ne 0 ]; then
        for i in  "${ZFS_DIR_CREATE[@]}";       do
                zfs create ${POOL_NAME}/${i}
        done
fi

printf "%s\n" "${LFS_DIR_LIST[@]}" | xargs -P 1 -i ./sync.sh ${BACKUP_DIR} ${POOL_NAME} {}
