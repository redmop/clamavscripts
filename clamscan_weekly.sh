#!/bin/bash

# email subject
SUBJECT="VIRUS DETECTED ON $(hostname -f)!!!"
# Email To ?
EMAIL="USER@EXAMPLE.ORG"
# Log location
LOG=/var/log/clamav/clamscan-$(date +'%Y-%m-%d').log
# Excluded Directories
EXCLUDES=""

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
        echo "$(tail -n 50 ${LOG})" >> ${EMAILMESSAGE}
        #sendmail -t < ${EMAILMESSAGE}
        cat ${EMAILMESSAGE} | /bin/mail -a "$LOG" -s "$SUBJECT" "$EMAIL";
        #/usr/bin/mutt -s "${SUBJECT}" $EMAIL < ${EMAILMESSAGE}
    fi

}

# Update ClamAV database
echo >> $LOG;
echo "-- Looking for ClamAV database updates at $(date)" >> $LOG;
echo >> $LOG;
/usr/bin/freshclam >> $LOG;
echo >> $LOG;


# Build Exclude Lists
for X in $SCAN_EXCLUDE_DIR ; do
        FULL_EXCLUDES="$FULL_EXCLUDES --exclude-dir=$X"
done

echo "" >> ${LOG}
echo "-- Clamscan started at $(date)" >> ${LOG}
echo "" >> ${LOG}
echo "Command line: clamscan -r / --exclude-dir=/sys/ $FULL_EXCLUDES --quiet --infected --log=${LOG} --cross-fs=no" >> ${LOG}
echo "" >> ${LOG}

clamscan -r / --exclude-dir=/sys/ $FULL_EXCLUDES --quiet --infected --log=${LOG} --cross-fs=no
check_scan

echo "" >> ${LOG}
echo "-- Scan Complete $(date)" >> ${LOG}
echo "" >> ${LOG}

echo "" >> ${LOG}
echo "-- Cleaning Log Files at $(date)" >> ${LOG}
echo "" >> ${LOG}

find /var/log/clamav -mtime 30 -exec rm -v {} \;

echo "" >> ${LOG}
echo "***End $0 at $(date)" >> ${LOG}
echo "" >> ${LOG}
