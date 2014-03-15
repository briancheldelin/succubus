#!/bin/bash
#
#  Backup script
#   Author: Brian Cheldelin

#echo "root=$1 pool=$2 user=$3"

rsync -aq $1/$3/ /$2/$3
echo $3 >> backup.log
