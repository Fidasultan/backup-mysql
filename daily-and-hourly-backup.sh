#!/bin/bash

#----------------------------------------
# OPTIONS
#----------------------------------------
USER='mysql-username'       # MySQL User
PASSWORD='mysql-password' # MySQL Password
BACKUP_PATH='/home/backup/mysql'
#----------------------------------------

# Create the backup folder
if [ ! -d $BACKUP_PATH ]; then
  mkdir -p $BACKUP_PATH
fi

# Get list of database names
databases=`mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | tr -d "|" | grep -v Database`

# Create a new backup directory for today's date
TODAY=$(date +"%Y-%m-%d")
BACKUP_DIR=$BACKUP_PATH/$TODAY

if [ ! -d $BACKUP_DIR ]; then
  mkdir -p $BACKUP_DIR
fi

# Perform a full backup once a day
if [ ! -f $BACKUP_DIR/full-backup.sql.gz ]; then
  echo "Performing full backup of all databases"
  mysqldump -u $USER -p$PASSWORD --all-databases | gzip > $BACKUP_DIR/full-backup.sql.gz
fi

# Perform an incremental backup every hour
INCREMENTAL_DIR=$BACKUP_DIR/incremental

if [ ! -d $INCREMENTAL_DIR ]; then
  mkdir -p $INCREMENTAL_DIR
fi

LAST_INCREMENTAL=$(ls $INCREMENTAL_DIR | tail -n 1 2>/dev/null)
LAST_BACKUP=$(ls $BACKUP_DIR | grep full-backup.sql.gz 2>/dev/null)

if [ "$LAST_INCREMENTAL" == "" ]; then
  echo "Performing initial incremental backup"
  mysqldump -u $USER -p$PASSWORD --all-databases --single-transaction --flush-logs --master-data=2 | gzip > $INCREMENTAL_DIR/incremental-backup-$(date +"%H%M%S").sql.gz
elif [ "$LAST_BACKUP" != "" ]; then
  echo "Performing incremental backup"
  mysqlbinlog --no-defaults --raw --read-from-remote-server --host=127.0.0.1 --user=$USER --password=$PASSWORD --stop-never-slave-server-id=1 --result-file=$INCREMENTAL_DIR/binlog-$(date +"%H%M%S").log $(grep -m 1 "^LOG" $LAST_BACKUP | sed "s/.*'\(.*\)'.*/\1/")
  mysqldump -u $USER -p$PASSWORD --all-databases --single-transaction --flush-logs --master-data=2 | gzip > $INCREMENTAL_DIR/incremental-backup-$(date +"%H%M%S").sql.gz
fi

# Delete backups older than 7 days
find $BACKUP_PATH/* -type d -ctime +7 | xargs rm -rf
