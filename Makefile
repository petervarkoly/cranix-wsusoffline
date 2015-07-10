VERSION         = $(shell test -e ../VERSION && cp ../VERSION VERSION ; cat VERSION)
RELEASE         = $(shell cat RELEASE)
NRELEASE        = $(shell echo $(RELEASE) + 1 | bc )
HERE            = $(shell pwd)
PACKAGE         = oss-wsusoffline
DESTDIR         = /
SUBDIRS         = alibs tools lang wsusUpdate.xml
DATE            = $(shell date "+%Y%m%d")


install: 
	mkdir -p $(DESTDIR)/usr/share/lmd/{alibs,lang}
	mkdir -p $(DESTDIR)/usr/share/oss/tools/oss-wsusoffline/
	mkdir -p $(DESTDIR)/usr/share/oss/templates/oss-wsusoffline/
	install -m 644 alibs/ManageWsusOffline.pm $(DESTDIR)/usr/share/lmd/alibs
	install -m 644 lang/*ini $(DESTDIR)/usr/share/lmd/lang
	install -m 644 templates/* $(DESTDIR)/usr/share/oss/templates/oss-wsusoffline/
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
	        cd /data1/OSC/home\:openschoolserver/$(PACKAGE); \
	        osc vc; \
	        osc ci -m "New Build Version"; \
	fi 
	echo $(NRELEASE) > RELEASE
	git commit -a -m "New release"
	git push



