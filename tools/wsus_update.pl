#!/usr/bin/perl
# Copyright (c) 2014 Peter Varkoly, Germany. All rights reserved.

BEGIN{ push @INC,"/usr/share/oss/lib/"; }
use strict;
use oss_base;
use oss_utils;

my $file = shift;
my @PCs  = ();
my @UPCs = ();
my $oss  = oss_base->new;

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
        push @PCs, @{$oss->get_workstations_of_room($name)};
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
	    push @PCs, $entry->dn;
	}
    }
}

foreach my $PC ( @PCs )
{
   push @UPCs, $oss->get_user_dn(get_name_of_dn($PC));
}

$oss->software_install_cmd(\@UPCs,['wsusUpdate'],1);

