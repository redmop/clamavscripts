#!/bin/bash
 
# email subject
SUBJECT="VIRUS DETECTED ON $(hostname -f)!!!"
# Email To ?
EMAIL="USER@EXAMPLE.ORG"
# Log location
LOG=/var/log/clamav/scan.log
EXCLUDES=""

echo "" >> ${LOG}
echo "***Start $0 at $(date)" >> ${LOG}
 
check_scan () {

    # Check the last set of results. If there are any "Infected" counts that aren't zero, we have a problem.
    if [ `tail -n 12 ${LOG}  | grep Infected | grep -v 0 | wc -l` != 0 ]
    then
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

for X in $EXCLUDES ; do
        FULL_EXCLUDES="$FULL_EXCLUDES --exclude-dir=$X/"
done

clamscan -r / --exclude-dir=/sys/ --quiet --infected --log=${LOG}
 
check_scan

echo "***End $0 at $(date)" >> ${LOG}
echo "" >> ${LOG}
