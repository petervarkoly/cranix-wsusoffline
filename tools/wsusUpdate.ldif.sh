#!/bin/bash

. /etc/sysconfig/ldap
SCHOOL_LDAPBASE=`echo $BASE_CONFIG_DN | sed s/ou=ldapconfig,//`

echo "dn: configurationKey=wsusUpdate,o=osssoftware,ou=Computers,$SCHOOL_LDAPBASE
objectClass: top
objectClass: SchoolConfiguration
configurationKey: wsusUpdate
configurationValue: NAME=wsusUpdate
configurationValue: TYPE=WPKG
configurationValue: CATEGORIE=MicrosoftSoftware
configurationValue: DESCRIPTION=Windows Offline Update
configurationValue: VERSION=0
configurationValue: PRODUCT_ID=
configurationValue: PREVIUS_PACKAGES=wsusUpdate
configurationValue: UPDATETYPE=package
configurationValue: LINK_MANUFACTURER=http://www.openschoolserver.net
configurationValue: NOTICE_INSTALLING=Test
configurationValue: LICENSING=http://www.openschoolserver.net
configurationValue: LICENSALLOCATIONTYPE=NO_LICENSE_KEY
configurationValue: FILE_REQUIREMENTE=1
configurationValue: PKG_REQUIREMENTE=
configurationValue: REPO_PKG_VERSION=1
configurationValue: SWCOMPATIBLE=Win7-x86;Win7-x64;Win8-x86;Win8-x64;Win81-x86;Win81-x64;WinXPsp3-x86
configurationValue: OPTIONS_INSTALLATION=wpkg.js /nonotify /quiet /install:wsu
 sUpdate /log_file_path:WPKGLOGFILE /logfilePattern:wsusUpdate.log
configurationValue: OPTIONS_DEINSTALLATION=wpkg.js /nonotify /quiet /remove:ws
 usUpdate /log_file_path:WPKGLOGFILE /logfilePattern:wsusUpdate.log
" | oss_ldapadd
