#!/bin/bash

# email subject
SUBJECT="VIRUS DETECTED ON $(hostname -f)!!!"
# Email To ?
EMAIL="root"
# Log location
LOG=/var/log/clamav/clamscan-$(date +'%Y-%m-%d').log
# Excluded Directories
EXCLUDES=""
INCLUDES=$(/usr/bin/findmnt --noheadings --output "TARGET" --list --types $(echo -n "zfs," ; /usr/bin/grep -v nodev /proc/filesystems | /usr/bin/paste -sd, - | /usr/bin/tr -d \\t)" | paste -sd" " -)

FILES_TO_SCAN=$(mktemp -t clamscan.XXXXXX) || exit 1

echo "" >> ${LOG}
echo "-- Start $0 at $(date)" >> ${LOG}
echo "" >> ${LOG}

check_scan () {

    # Check the last set of results. If there are any "Infected" counts that aren't zero, we have a problem.
    if [ $(grep "Infected files:" ${LOG}  |grep -v "Infected files: 0" | wc -l) != 0 ]
    then
        echo "" >> ${LOG}
        echo "-- Infection detected, sending alert to $EMAIL" >> ${LOG}
        echo "" >> ${LOG}
        EMAILMESSAGE=$(mktemp /tmp/virus-alert.XXXXX)
        echo "To: ${EMAIL}" >>  ${EMAILMESSAGE}
        echo "From: root@$(hostname -f)" >>  ${EMAILMESSAGE}
        echo "Subject: ${SUBJECT}" >>  ${EMAILMESSAGE}
        echo "Importance: High" >> ${EMAILMESSAGE}
        echo "X-Priority: 1" >> ${EMAILMESSAGE}
        #echo "$(tail -n 50 ${LOG})" >> ${EMAILMESSAGE}
        cat ${EMAILMESSAGE} | /bin/mail -a "$LOG" -s "$SUBJECT" "$EMAIL";
    fi

}

# Update ClamAV database
echo >> $LOG;
echo "-- Looking for ClamAV database updates at $(date)" >> $LOG;
echo >> $LOG;
/usr/bin/freshclam >> $LOG 2>&1;
echo >> $LOG;

FULL_EXCLUDES="-path /sys -o -path /proc"
for X in $EXCLUDES ; do
        FULL_EXCLUDES="$FULL_EXCLUDES -o -path $X"
done

echo "" >> ${LOG}
echo "-- Clamscan started at $(date)" >> ${LOG}
echo "" >> ${LOG}
#echo "Command line: find / -xdev -type d \( $FULL_EXCLUDES \) -prune -o \( -mtime -2 -o -ctime -2 \) -type f -print0 | xargs -0 -r clamscan --exclude-dir=/proc/ --exclude-dir=/sys/ --quiet --infected --log=${LOG}" >> ${LOG}
echo "Command line:" >> ${LOG}


#find $INCLUDES -xdev -type f \( -mtime 2 -o -ctime 2 \) -print0 | xargs -0 -r ls -l 
# -print0 | xargs -0 -r clamscan --exclude-dir=/proc/ --exclude-dir=/sys/ --quiet --infected --log=${LOG}
#find $INCLUDES -xdev -type d \( $FULL_EXCLUDES \) -prune -o \( -mtime -2 -o -ctime -2 \) -type f -print0 | xargs -0 -r clamscan --exclude-dir=/proc/ --exclude-dir=/sys/ --quiet --infected --log=${LOG}

echo "    find: find $INCLUDES -xdev -type d \( $FULL_EXCLUDES \) -prune -o \( -mtime -2 -o -ctime -2 \) -type f -fprint $FILES_TO_SCAN" >> ${LOG}
find $INCLUDES -xdev -type d \( $FULL_EXCLUDES \) -prune -o \( -mtime -2 -o -ctime -2 \) -type f -fprint $FILES_TO_SCAN

echo "    clamscan: clamscan --exclude-dir=/proc/ --exclude-dir=/sys/ --quiet --infected --log=${LOG} -f $FILES_TO_SCAN |grep -v "No such file or directory" "  >> ${LOG}
clamscan --exclude-dir=/proc/ --exclude-dir=/sys/ --quiet --infected --log=${LOG} -f $FILES_TO_SCAN >> ${LOG} 2>&1

echo "" >> ${LOG}

rm  $FILES_TO_SCAN

check_scan

echo "" >> ${LOG}
echo "-- Scan Complete $(date)" >> ${LOG}
echo "" >> ${LOG}

echo "" >> ${LOG}
echo "-- Cleaning Log Files at $(date)" >> ${LOG}
echo "" >> ${LOG}

find /var/log/clamav -mtime +30 -exec rm  {} \;

echo "" >> ${LOG}
echo "***End $0 at $(date)" >> ${LOG}
echo "" >> ${LOG}

