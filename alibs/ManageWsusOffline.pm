# OSS LMD ManangeWsusOffline module
# Copyright (c) 2014 Peter Varkoly <peter@varkoly.de> Nürnberg, Germany.  All rights reserved.

BEGIN{ push @INC,"/usr/share/oss/lib/"; }

package ManageWsusOffline;

use strict;
use Config::Crontab;
use oss_base;
use oss_utils;
use Data::Dumper;
use vars qw(@ISA);
@ISA = qw(oss_base);

sub new
{
        my $this    = shift;
        my $connect = shift || undef;
        my $self    = oss_base->new($connect);
        return bless $self, $this;
}

my $ctFile = "/etc/cron.d/oss.wsusoffline";

sub interface
{
        return [
                "getCapabilities",
                "default",
                "apply",
		"addDownload",
		"createDownload",
		"addUpdate",
		"createUpdate"
        ];
}

sub getCapabilities
{
        return [
                { title        => 'OSS Windows Client Update Scheduler' },
                { type         => 'command' },
                { allowedRole  => 'root' },
                { allowedRole  => 'sysadmins' },
                { category     => 'Network' },
                { order        => 70 },
                { variable     => [ "time",    [ type => "time" ] ] },
                { variable     => [ "delete",  [ type => "boolean" ] ] },
                { variable     => [ "mo",  [ type => "boolean" ] ] },
                { variable     => [ "tu",  [ type => "boolean" ] ] },
                { variable     => [ "we",  [ type => "boolean" ] ] },
                { variable     => [ "th",  [ type => "boolean" ] ] },
                { variable     => [ "fr",  [ type => "boolean" ] ] },
                { variable     => [ "sa",  [ type => "boolean" ] ] },
                { variable     => [ "su",  [ type => "boolean" ] ] },
                { variable     => [ "excludesp",  [ type => "boolean", label => "Do not download servicepacks" ] ] },
                { variable     => [ "dotnet",     [ type => "boolean", label => "Download .NET framework" ] ] },
                { variable     => [ "msse",       [ type => "boolean", label => "Download Microsoft Security Essentials files" ] ] },
                { variable     => [ "wddefs",     [ type => "boolean", label => "Download Microsoft Defender definition files" ] ] },
                { variable     => [ "nocleanup",  [ type => "boolean", label => "Do not cleanup client directory" ] ] },
		{ variable     => [ "hwconfig",   [ type => "list", size=>"6",  multiple=>"true" ]] },
		{ variable     => [ "pcs",        [ type => "list", size=>"6",  multiple=>"true" ]] },
		{ variable     => [ "rooms",      [ type => "list", size=>"6",  multiple=>"true" ]] },
                { variable     => [ "OS", [ type => "popup" ] ] },
                { variable     => [ "language", [ type => "popup" ] ] },
                { variable     => [ "command",  [ type => "hidden" ] ] }
        ];
}

sub default
{
        my $this  = shift;
        my @ret   = ();
        my @table = ('times', { head => [ "description", "time", "mo","tu","we","th","fr","sa","su","delete" ] } );

        my $ct    = new Config::Crontab( -file => $ctFile );
        $ct->system(1);
        $ct->read;
        my $i = 1;
	for my $bblock ( $ct->select_blocks ) {
		my $block = ($bblock->select( -type => 'event'))[0];
		my $com   = ($bblock->select( -type => 'comment'))[0];
		next if ( !defined $block || !defined $com );
		my $time = sprintf("%02i:%02i",$block->hour,$block->minute);
		my $dow  = $block->dow;
		my $desc = $com->data; $desc =~ s/^##//;
		push @table, { line => [ $i ,   { description => $desc },
						{ time => $time },
						{ mo => $dow=~ /1/ },
						{ tu => $dow=~ /2/ }, 
						{ we => $dow=~ /3/ }, 
						{ th => $dow=~ /4/ }, 
						{ fr => $dow=~ /5/ }, 
						{ sa => $dow=~ /6/ }, 
						{ su => $dow=~ /7/ }, 
						{ delete => 0 } ,
						{ command => $block->command } ]};
		$i++;
	}
	push @ret, { table    => \@table };
	push @ret, { action => 'addDownload'  };
	push @ret, { action => 'addUpdate'  };
	push @ret, { action => 'apply'  };
	return \@ret;

}

sub apply
{
        my $this  = shift;
        my $reply = shift;
        system("rm $ctFile");
        my $ct    = new Config::Crontab( -file => $ctFile );
        $ct->system(1);
        $ct->read;
        for my $i ( sort keys %{$reply->{times}} )
        {
            if( $reply->{times}->{$i}->{delete} ) {
		my( $cmd, $par ) = split / /, $reply->{times}->{$i}->{command};
print "$par\n";
	        unlink $par if( -r $par );
		next;
	    }
            my ($hour, $minute) = split(":", $reply->{times}->{$i}->{time});
	    my @dow   = ();
	    push @dow, "1" if( $reply->{times}->{$i}->{mo} );
	    push @dow, "2" if( $reply->{times}->{$i}->{tu} );
	    push @dow, "3" if( $reply->{times}->{$i}->{we} );
	    push @dow, "4" if( $reply->{times}->{$i}->{th} );
	    push @dow, "5" if( $reply->{times}->{$i}->{fr} );
	    push @dow, "6" if( $reply->{times}->{$i}->{sa} );
	    push @dow, "7" if( $reply->{times}->{$i}->{su} );
	    my $sdow = join(",",@dow);
            my $event = new Config::Crontab::Event( -minute  => sprintf("%i",$minute),
                                                -hour    => sprintf("%i",$hour),
                                                -dow     => $sdow,
                                                -user    => 'root',
                                                -command => $reply->{times}->{$i}->{command} );
	    my $comment = new Config::Crontab::Comment(-data => "##".$reply->{times}->{$i}->{description} );
	    my $block = new Config::Crontab::Block;
	    $block->last($comment,$event);
	    $ct->last($block);
	}
        $ct->write;
        $this->default;
}

sub addUpdate
{
        my $this  = shift;
	my $reply = shift;
        my @ret   = ();
        my @pcs   = ();
	my @rooms = $this->get_rooms();
	foreach my $pc ( keys %{$this->get_workstations} ){
	   push @pcs, get_name_of_dn($pc);
	}
	@pcs = sort(@pcs);
	push @ret, { description => $reply->{description} || 'Update' };
	if( defined $reply->{warning} )
	{
	    push @ret, { NOTICE => $reply->{warning} };
	}
	push @ret, { pcs      => \@pcs };
	push @ret, { rooms    => \@rooms };
	push @ret, { hwconfig => $this->get_HW_configurations(0) };
	push @ret, { time => $reply->{time} || '00:00' };
	push @ret, { mo => $reply->{mo} || 0 };
	push @ret, { tu => $reply->{tu} || 0 };
	push @ret, { we => $reply->{we} || 0 };
	push @ret, { th => $reply->{th} || 0 };
	push @ret, { fr => $reply->{fr} || 1 };
	push @ret, { sa => $reply->{sa} || 0 };
	push @ret, { su => $reply->{su} || 0 };
	push @ret, { action => 'cancel' };
	push @ret, { name => 'action', value => 'createUpdate', attributes => [ label => 'insert' ] };
	return \@ret;
}

sub createUpdate
{
        my $this  = shift;
	my $reply = shift;
	my $tmpf  = `mktemp /var/adm/oss/wsusXXXXXXXXXX`; chomp $tmpf;
	my @dow   = ();
	push @dow, "1" if( $reply->{mo} );
	push @dow, "2" if( $reply->{tu} );
	push @dow, "3" if( $reply->{we} );
	push @dow, "4" if( $reply->{th} );
	push @dow, "5" if( $reply->{fr} );
	push @dow, "6" if( $reply->{sa} );
	push @dow, "7" if( $reply->{su} );
        my $sdow = join(",",@dow);
	open CONFIG, ">$tmpf";
	if( $reply->{pcs} ) {
	    foreach my $pc ( split /\n/, $reply->{pcs} ) {
		print CONFIG "pc $pc\n";
	    }
	}
	elsif( $reply->{hwconfig} )
	{
	    foreach my $hw ( split /\n/, $reply->{hwconfig} ) {
		print CONFIG "hwconfig $hw\n";
	    }
	}
	elsif( $reply->{rooms} )
	{
	    foreach my $room ( split /\n/, $reply->{rooms} ) {
		print CONFIG "room $room\n";
	    }
	}
	else
	{
	    unlink($tmpf);
	    $reply->{warning} = "Select workstations, hwconfiguration or romms .";
	    $this->addUpdate($reply);
	}
	close CONFIG;
        my $ct    = new Config::Crontab( -file => $ctFile );
        $ct->system(1);
        $ct->read;
        my ($hour, $minute) = split(":", $reply->{time});
	$tmpf =~ s#/var/adm/oss/wsus##;
	my $command = "/usr/share/oss/tools/wsus_update.pl $tmpf";
        my $event = new Config::Crontab::Event( -minute  => sprintf("%i",$minute),
                                                -hour    => sprintf("%i",$hour),
                                                -dow     => $sdow,
                                                -user    => 'root',
                                                -command => $command );
	if( $reply->{description} eq 'Update' ) {
	   $reply->{description} .= ' '.$tmpf;
	}
	my $comment = new Config::Crontab::Comment(-data => "##".$reply->{description} );
        my $block = new Config::Crontab::Block;
        $block->last($comment,$event);
        $ct->last($block);
        $ct->write;
        $this->default;

}

sub addDownload
{
        my $this  = shift;
	my $reply = shift;
        my @ret   = ();
	push @ret, { description => $reply->{description} || 'Download' };
	push @ret, { time => $reply->{time} || '00:00' };
	push @ret, { mo => $reply->{mo} || 0 };
	push @ret, { tu => $reply->{tu} || 0 };
	push @ret, { we => $reply->{we} || 0 };
	push @ret, { th => $reply->{th} || 0 };
	push @ret, { fr => $reply->{fr} || 1 };
	push @ret, { sa => $reply->{sa} || 0 };
	push @ret, { su => $reply->{su} || 0 };
	push @ret, { OS => getOS($reply->{OS})};
	push @ret, { language => getLang($reply->{language})};
	push @ret, { excludesp => $reply->{excludesp} || 1 };
	push @ret, { dotnet    => $reply->{dotnet} || 1 };
	push @ret, { msse      => $reply->{msse} || 1 };
	push @ret, { wddefs    => $reply->{wddefs} || 1 };
	push @ret, { nocleanup => $reply->{nocleanup} || 1 };
	push @ret, { action => 'cancel' };
	push @ret, { name => 'action', value => 'createDownload', attributes => [ label => 'insert' ] };
	return \@ret;

}

sub createDownload
{
        my $this  = shift;
	my $reply = shift;
	my @dow   = ();
	push @dow, "1" if( $reply->{mo} );
	push @dow, "2" if( $reply->{tu} );
	push @dow, "3" if( $reply->{we} );
	push @dow, "4" if( $reply->{th} );
	push @dow, "5" if( $reply->{fr} );
	push @dow, "6" if( $reply->{sa} );
	push @dow, "7" if( $reply->{su} );

        my $ct    = new Config::Crontab( -file => $ctFile );
        $ct->system(1);
        $ct->read;
        my ($hour, $minute) = split(":", $reply->{time});
        my $sdow = join(",",@dow);
	my $OS = $reply->{OS}; 
	$OS = "w2k3-x64" if( $OS eq "wxp-x64" );
	#Create command:
	my $command = "/srv/itool/wsusoffline/sh/DownloadUpdates.sh $OS ".$reply->{language};
	$command .= " /excludesp" if( $reply->{excludesp} );
	$command .= " /dotnet" if( $reply->{dotnet} );
	$command .= " /msse" if( $reply->{msse} );
	$command .= " /wddefs" if( $reply->{wddefs} );
	$command .= " /nocleanup" if( $reply->{nocleanup} );
        my $event = new Config::Crontab::Event( -minute  => sprintf("%i",$minute),
                                                -hour    => sprintf("%i",$hour),
                                                -dow     => $sdow,
                                                -user    => 'root',
                                                -command => $command );
	if( $reply->{description} eq 'Download' ) {
	   $reply->{description} .= ' '.$OS.' '.$reply->{language};
	}
	my $comment = new Config::Crontab::Comment(-data => "##".$reply->{description} );
        my $block = new Config::Crontab::Block;
        $block->last($comment,$event);
        $ct->last($block);
        $ct->write;
        $this->default;

}

sub getOS
{
	my $def = shift || 0;
	my @OS = ( [ "wxp", "Windos XP" ], [ "wxp-x64", "Windos XP 64 bit" ],
		   [ "w2k3", "Windows Server 2003" ],[ "w2k3-x64", "Windows Server 2003 64 bit" ],
		   [ "w60", "Windows Vista / Server 2008" ],[ "w60-x64", "Windows Vista 64 bit/ Server 2008" ],
		   [ "w61", "Windows 7" ],[ "w61-x64", "Windows 7 64 bit/ Server 2008 R2 64" ],
		   [ "w62", "Windows 8" ],[ "w62-x64", "Windows 8 64 bit/ Server 2012" ],
		   [ "w63", "Windows 8.1" ],[ "w63-x64", "Windows 8.1 64 bit" ],
		   [ "all-x86", "All 32 bit" ],[ "all-x64", "All 64 bit" ],
		   [ "o2k3", "Office 2003" ],[ "o2k7", "Office 2007" ],[ "o2k10", "Office 2010" ],[ "o2k13", "Office 2013" ],[ "ofc", "All Office updates" ] );
	push @OS, ('---DEFAULTS---',$def) if( $def);
	return \@OS;
}

sub getLang
{
	my $def = shift || 0;
	my @ret = qw( enu deu nld esn fra ptg ptb ita rus plk ell csy dan nor sve fin jpn kor chs cht hun trk ara heb );
	push @ret, ('---DEFAULTS---',$def) if( $def);
	return \@ret;
}

1;
