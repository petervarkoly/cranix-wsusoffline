#!/bin/bash

. /etc/sysconfig/schoolserver
REPO_USER=${SCHOOL_REG_CODE:0:9}
REPO_PASSWORD=${SCHOOL_REG_CODE:10:9}

echo "[oss-wsusoffline]
name=oss-wsusoffline
enabled=1
autorefresh=1
baseurl=https://$REPO_USER:$REPO_PASSWORD@repo.openschoolserver.net/addons/oss-wsusoffline
path=/
type=rpm-md
keeppackages=0
" > /tmp/oss-wsusoffline.repo

wget -O repomd.xml.key https://$REPO_USER:$REPO_PASSWORD@repo.openschoolserver.net/addons/oss-wsusoffline/repodata/repomd.xml.key
gpg --import repomd.xml.key
zypper ar /tmp/oss-wsusoffline.repo
zypper --gpg-auto-import-keys ref
zypper -n install oss-wsusoffline

