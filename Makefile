VERSION         = $(shell cat VERSION)
RELEASE         = $(shell cat RELEASE)
NRELEASE        = $(shell echo $(RELEASE) + 1 | bc )
HERE            = $(shell pwd)
PACKAGE         = oss-wsusoffline
DESTDIR         = /
SUBDIRS         = Makefile alibs lang templates tools
DATE            = $(shell date "+%Y%m%d")


install: 
	mkdir -p $(DESTDIR)/usr/share/oss/tools/wsusoffline/
	mkdir -p $(DESTDIR)/usr/share/oss/templates/wsusoffline/
	mkdir -p $(DESTDIR)/usr/share/oss/plugins/clients/start/
	mkdir -p $(DESTDIR)/srv/salt/_modules/
	install -m 644 templates/* $(DESTDIR)/usr/share/oss/templates/wsusoffline/
	install -m 755 tools/* $(DESTDIR)/usr/share/oss/tools/wsusoffline/
	install -m 755 plugins/120_start_wsus.sh $(DESTDIR)/usr/share/oss/plugins/clients/start/
	install -m 644 salt/oss_update.py $(DESTDIR)/srv/salt/_modules/


dist:  
	rm -rf $(PACKAGE)
	mkdir -p $(PACKAGE)
	for i in $(SUBDIRS); do /bin/ln -s ../$$i $(PACKAGE)/$$i; done
	sed    s/VERSION/$(VERSION)/  $(PACKAGE).spec.in > $(PACKAGE).spec
	sed -i s/RELEASE/$(NRELEASE)/ $(PACKAGE).spec
	tar hjcvpf $(PACKAGE).tar.bz2 $(PACKAGE)
	if [ -d /data1/OSC/home\:varkoly\:OSS-4-0/$(PACKAGE) ] ; then \
	    cd /data1/OSC/home\:varkoly\:OSS-4-0/$(PACKAGE); osc up; cd $(HERE);\
	    cp  wsusoffline*.zip UpdateInstaller.ini /data1/OSC/home\:varkoly\:OSS-4-0/$(PACKAGE); \
	    mv $(PACKAGE).tar.bz2 $(PACKAGE).spec /data1/OSC/home\:varkoly\:OSS-4-0/$(PACKAGE); \
	    cd /data1/OSC/home\:varkoly\:OSS-4-0/$(PACKAGE); \
	    osc vc; \
	    osc ci -m "New Build Version"; \
	fi
	echo $(NRELEASE) > RELEASE
	git commit -a -m "New release"
	git push



