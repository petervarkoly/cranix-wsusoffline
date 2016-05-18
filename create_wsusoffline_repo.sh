#!/bin/bash
REPO="/repo/www/addons/oss-wsusoffline"
PACKAGES="oss-wsusoffline cabextract libmspack md5deep"
rm -r binaries
for i in $PACKAGES
do
	osc getbinaries home:openschoolserver $i SLE_11_SP3  x86_64
	osc getbinaries home:openschoolserver $i SLE_11_SP3  i586
done

rm -r $REPO
mkdir -p $REPO/{noarch,x86_64,i586,src}
mv binaries/*.src.rpm    $REPO/src/
mv binaries/*.noarch.rpm $REPO/noarch/
mv binaries/*.x86_64.rpm $REPO/x86_64/
mv binaries/*.i586.rpm   $REPO/i586/
createrepo $REPO
cp /data1/OSC/home:openschoolserver/oss-key.gpg $(REPO)/repodata/repomd.xml.key
gpg -a --detach-sign $REPO/repodata/repomd.xml 
