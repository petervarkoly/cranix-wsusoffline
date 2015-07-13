#!/usr/bin/perl
# Copyright (c) 2014 Peter Varkoly, Germany. All rights reserved.

BEGIN{ push @INC,"/usr/share/oss/lib/"; }
use strict;
use oss_base;
use oss_utils;

my $week = shift;
my $file = shift;
my @PCs  = ();
my @UPCs = ();
my $oss  = oss_base->new;
my $NW   = `date +%W`; chomp $NW;

exit if( $week && $NW % $week );

my $OSSDATE = `/usr/share/oss/tools/oss_date.sh`; chomp $OSSDATE;

open (INPUT,"</var/adm/oss/wsus$file"); 
while(<INPUT>)
{
    my( $type, $name ) = split / /, $_;
    if( $type eq 'pc' )
    {
        push @PCs, $name;
    }
    elsif( $type eq 'room' )
    {
	my $roompc = $oss->get_workstations_of_room($name);
	foreach my $PC (  @$roompc )
	{
        	push @PCs, $PC;
	}
    }
    elsif( $type eq 'hwconfig' )
    {
        my $result = $oss->{LDAP}->search(  base    => $oss->{SYSCONFIG}->{DHCP_BASE},
                                     scope   => 'sub',
                                     filter  => "(&(objectclass=dhcpHost)(cvalue=HW=$name))",
				     attrs   => [ 'dn' ]
            );
        foreach my $entry ( $result->entries )
        {
	    push @PCs, get_name_of_dn($entry->dn);
	}
    }
}

foreach my $PC ( @PCs )
{
   push @UPCs, $oss->get_user_dn($PC);
}

#Create the package xml
system("sed 's/#OSSDATE#/$OSSDATE/g' /usr/share/oss/templates/oss-wsusoffline/wsusUpdate.xml > /srv/itool/swrepository/wpkg/packages/wsusUpdate-$OSSDATE.xml");
#Create the package in ldap
system("sed 's/#OSSDATE#/$OSSDATE/g' /usr/share/oss/templates/oss-wsusoffline/wsusUpdate.ldif > /var/adm/oss/wsus$file.ldif");
system("sed -i 's/#LDAPBASE#/".$oss->{LDAP_BASE}."/g' /var/adm/oss/wsus$file.ldif");
system("/usr/sbin/oss_ldapadd < /var/adm/oss/wsus$file.ldif");

$oss->makeInstallDeinstallCmd('install',\@UPCs,["configurationKey=wsusUpdate-$OSSDATE,o=osssoftware,".$oss->{SYSCONFIG}->{COMPUTERS_BASE}]);
makeInstallationNow(\@PCs);

