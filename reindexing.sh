#!/bin/ksh
#
MAILINGLIST1="CentralServiceDesk@libertyglobal.com,CSDITApplications@libertyglobal.com,LGI.SSO.AM@accenture.com"
MAILINGLIST2="LGI.SSO.AM@accenture.com"
MAILSUBJECT="LDAP Reindexing for slave1"
#
 cat /u01/appl/db2inst1/LDAPReindexing/mailbody.txt | mailx -s "$MAILSUBJECT" "$MAILINGLIST1"
/sys_mgmt/etc/stop_all_ldap.sh
#
# Check presence of process db2sysc (DB2). When present, stop it
#
DB2SYSC=`pgrep db2sysc | wc -l`
if [ $DB2SYSC != 0 ]; then
su - db2inst1 -c "db2 terminate"
su - db2inst1 -c "db2 force applications all"
sleep 60
su - db2inst1 -c "db2stop"
fi
#
# Check presence of process ibmslapd. If present, stop it
#
IBMSLAPD=`pgrep ibmslapd | wc -l`
if [ $IBMSLAPD != 0 ]; then
/opt/ibm/ldap/V6.3.1/sbin/idsslapd -I db2inst1 -k
fi
#
## Execute this script only as db2inst1!
su - db2inst1 -c "/opt/ibm/ldap/V6.3.1/sbin/idsdbmaint -I db2inst1 -i"
if [ $? -eq 0 ]
then
  echo "Successfully completed index reorganization"
else
  cat /u01/appl/db2inst1/LDAPReindexing/result_fail.txt | mailx -s "$MAILSUBJECT" "$MAILINGLIST2" 
fi
#
/sys_mgmt/etc/idsdbmaint.sh
if [ $? -eq 0 ]
then
  echo "Successfully completed row compression"
else
  cat /u01/appl/db2inst1/LDAPReindexing/result_fail.txt | mailx -s "$MAILSUBJECT" "$MAILINGLIST2" 
fi
#
/sys_mgmt/etc/start_all_ldap.sh

cat /u01/appl/db2inst1/LDAPReindexing/result.txt | mailx -s "$MAILSUBJECT" "$MAILINGLIST1"

