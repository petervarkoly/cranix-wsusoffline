VERSION         = $(shell test -e ../VERSION && cp ../VERSION VERSION ; cat VERSION)
RELEASE         = $(shell cat RELEASE)
NRELEASE        = $(shell echo $(RELEASE) + 1 | bc )
HERE            = $(shell pwd)
PACKAGE         = oss-wsusoffline
DESTDIR         = /
SUBDIRS         = alibs tools wsusUpdate.xml Makefile
DATE            = $(shell date "+%Y%m%d")


install: 
	mkdir -p $(DESTDIR)/srv/itool/swrepository/wpkg/packages/
	mkdir -p $(DESTDIR)/usr/share/lmd/{alibs,lang}
	mkdir -p $(DESTDIR)/usr/share/oss/tools/oss-wsusoffline/wsus_update.pl
	install -m 644 wsusUpdate.xml $(DESTDIR)/srv/itool/swrepository/wpkg/packages/
	install -m 644 alibs/ManageWsusOffline.pm $(DESTDIR)/usr/share/lmd/alibs
	install -m 755 tools/* $(DESTDIR)/usr/share/oss/tools/oss-wsusoffline/

dist:  
	rm -rf $(PACKAGE)
	mkdir -p $(PACKAGE)
	for i in $(SUBDIRS); do /bin/ln -s ../$$i $(PACKAGE)/$$i; done
	sed    s/VERSION/$(VERSION)/  $(PACKAGE).spec.in > $(PACKAGE).spec
	sed -i s/RELEASE/$(NRELEASE)/ $(PACKAGE).spec
	tar hjcvpf $(PACKAGE).tar.bz2 $(PACKAGE)
	if [ -d /data1/OSC/home\:openschoolserver/$(PACKAGE) ] ; then \
	        cd /data1/OSC/home\:openschoolserver/$(PACKAGE); osc up; cd $(HERE);\
	        cp $(PACKAGE).tar.bz2  $(PACKAGE).spec /data1/OSC/home\:openschoolserver/$(PACKAGE); \
	        cp wsusoffline90.zip  $(PACKAGE).spec /data1/OSC/home\:openschoolserver/$(PACKAGE); \
	        cd /data1/OSC/home\:openschoolserver/$(PACKAGE); \
	        osc vc; \
	        osc ci -m "New Build Version"; \
	fi 
	echo $(NRELEASE) > RELEASE
	git commit -a -m "New release"
	git push



