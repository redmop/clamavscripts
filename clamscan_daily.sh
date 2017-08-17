#!/bin/bash
 
# email subject
SUBJECT="VIRUS DETECTED ON $(hostname)!!!"
# Email To ?
EMAIL="USER@DOMAIN"
# Log location
LOG=/var/log/clamav/scan.log
EXCLUDES=
echo "" >> ${LOG}
echo "***Start $0 at $(date)" >> ${LOG}

check_scan () {
 
    # Check the last set of results. If there are any "Infected" counts that aren't zero, we have a problem.
    if [ `tail -n 12 ${LOG}  | grep Infected | grep -v 0 | wc -l` != 0 ]
    then
        EMAILMESSAGE=$(mktemp /tmp/virus-alert.XXXXX)
        echo "To: ${EMAIL}" >>  ${EMAILMESSAGE}
        echo "From: root@$(hostname-f)" >>  ${EMAILMESSAGE}
        echo "Subject: ${SUBJECT}" >>  ${EMAILMESSAGE}
        echo "Importance: High" >> ${EMAILMESSAGE}
        echo "X-Priority: 1" >> ${EMAILMESSAGE}
        echo "$(tail -n 50 ${LOG})" >> ${EMAILMESSAGE}
        #sendmail -t < ${EMAILMESSAGE}
        cat ${EMAILMESSAGE} | /bin/mail -a "$LOG" -s "$SUBJECT" "$EMAIL";
        #/usr/bin/mutt -s "${SUBJECT}" $EMAIL < ${EMAILMESSAGE}
    fi
 
}
for X in $EXCLUDES ; do
        FULL_EXCLUDES="$FULL_EXCLUDES  -and -not -wholename '/$X/*'"
done 
echo find / -not -wholename '/sys/*' -and -not -wholename '/proc/*' $FULL_EXCLUDES -mtime -2 -type f -print0
#find / -not -wholename '/sys/*' -and -not -wholename '/proc/*' $FULL_EXCLUDES -mtime -2 -type f -print0 | xargs -0 -r clamscan --exclude-dir=/proc/ --exclude-dir=/sys/ --quiet --infected --log=${LOG}
#check_scan
 
#find / -not -wholename '/sys/*' -and -not -wholename '/proc/*' $FULL_EXCLUDES -ctime -2 -type f -print0 | xargs -0 -r clamscan --exclude-dir=/proc/ --exclude-dir=/sys/ --quiet --infected --log=${LOG}
#check_scan

echo "***End $0 at $(date)" >> ${LOG}
echo "" >> ${LOG}
