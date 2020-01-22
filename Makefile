HERE            = $(shell pwd)
PACKAGE         = oss-wsusoffline
DESTDIR         = /
SUBDIRS         = Makefile salt plugins
DATE            = $(shell date "+%Y%m%d")
REPO		= /data1/OSC/home:varkoly:OSS-4-1:leap15.1


install: 
	mkdir -p $(DESTDIR)/usr/share/oss/plugins/clients/start/
	mkdir -p $(DESTDIR)/srv/salt/_modules/
	install -m 755 plugins/120_start_wsus.sh $(DESTDIR)/usr/share/oss/plugins/clients/start/
	install -m 644 salt/oss_update.py $(DESTDIR)/srv/salt/_modules/


dist:  
	rm -rf $(PACKAGE)
	mkdir -p $(PACKAGE)
	for i in $(SUBDIRS); do /bin/ln -s ../$$i $(PACKAGE)/$$i; done
	tar hjcvpf $(PACKAGE).tar.bz2 $(PACKAGE)
	if [ -d $(REPO)/$(PACKAGE) ] ; then \
	    cd $(REPO)/$(PACKAGE); osc up; cd $(HERE);\
	    cp  wsusoffline*.zip UpdateInstaller.ini $(REPO)/$(PACKAGE); \
	    mv $(PACKAGE).tar.bz2 $(REPO)/$(PACKAGE); \
	    cd $(REPO)/$(PACKAGE); \
	    osc vc; \
	    osc ci -m "New Build Version"; \
	fi

