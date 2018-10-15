#!/opt/LifeKeeper/bin/perl
#
#	Copyright (c) 2018 SIOS Technology Corp.
# enhancedNasMounter
# Description:
#
# Revision: v05.00.21
# Author:  cmr
#
# MR            date    user    description
# ==            ====    ====    ==========
#              16Apr18  CR      Initial PoC deployment
#              23May18  CR      Customer fixes; down server
#              27Jul18  CR      Customer fixes; perl path
#              24Sep18  CR      Make skipping the unmount the new default
########################## end CHANGE LOG ##################################

use Getopt::Std; # use the standard getopt package
BEGIN { require '/etc/default/LifeKeeper.pl'; }
package enhancedNasMounter;

#use lib "$ENV{LKROOT}/lkadm/subsys/scsi/netraid/bin";
use RKActionHandler;
use strict;
our $me = LK::lcduname();
our $default = "/etc/default/LifeKeeper";
our $lkroot="$ENV{LKROOT}";
our $lktmp="$ENV{LKROOT}/tmp";
our $DEFAULT_MOUNT_OPTIONS="default,soft";
our $GLOBAL_NAS_APP_SKIP_REMOVE =($ENV{GLOBAL_NAS_APP_SKIP_REMOVE} =~ /(^\d+)$/)?$ENV{GLOBAL_NAS_APP_SKIP_REMOVE}:1;
our $NAS_APP_DEBUG=($ENV{NAS_APP_DEBUG} =~ /(^\d+)$/)?$ENV{NAS_APP_DEBUG}:0;

sub usage {
        print STDERR "\n$_[0]\n" if ($_[0]);
        print STDERR "Usage:\t$0 -t tag -i id\n";
        print STDERR "Configuration requires the gen/app resource contain at minimum the mntpt host export \n";
        print STDERR "
				system_mount_point nfs_host nfs_export nfs_options
		Example Node1:
                /sapmnt/JS1 peter /exports/sapmnt/JS1 rw-sync-bg-nfsvers=4
        \n";
}

sub new
{
	my $proto = shift;
	my $tag=shift;
	my $sys=shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{'fromtag'}=0;
	bless ($self, $class);
	my $ret=$self->getLK($tag,$sys);
	if ($ret){
		bless ($self, $class);
		return $self;
	}
	print STDERR "CRITICAL: A gen/app internal object could not be created on $me using $tag and getLK()\n";
	return;
}

# 1 - yes, got it
# 0 - errors
sub getLK
{
	my $self=shift;
	my $tag=shift;
	my $sys=shift;
	if ($sys eq '' ){
		$sys = $me;
	}
	if ( $tag eq '' ){
		usage('The gen/app tag or the gen/app id were not found or specified');
		return 0;
	}

	# get the 
	my @appIns = split /\001/, LK::ins_list($sys, '', '', '', $tag, '');
	@appIns or do {
        print STDERR ("Resource $tag is not LifeKeeper protected\n");
        return 0;
	};
	my @appInfo = split /\s+/, $appIns[5];

	$self->{'mntPoint'} = $appInfo[0];
	if ( $self->{'mntPoint'} eq '' ){ 
		usage("No mntPoint specified in the $tag info field\n");
		return 0;
	}
	$self->{'mntHost'} = $appInfo[1];
	if ( $self->{'mntHost'} eq '' ){ 
		usage("No mntHost specified in the $tag info field\n");
		return 0;
	}
	$self->{'mntExport'} = $appInfo[2];
	if ( $self->{'mntExport'} eq '' ){ 
		usage("No mntExport specified in the $tag info field\n");
		return 0;
	}
	my $mntOptions = $appInfo[3];
	$mntOptions=~s/-/,/g; # if you want to use mntOptions store , as - 
	$mntOptions=~s/!/=/g;  # don't believe the gen/app allows '!'

	if ($mntOptions eq '' ){
		$mntOptions=$DEFAULT_MOUNT_OPTIONS;
	}
	$self->{'mntOptions'}=$mntOptions;
	$self->{'tag'}=$tag;
	my $mntFullCmd="mount $self->{'mntHost'}:$self->{'mntExport'} $self->{'mntPoint'} -t nfs -o $self->{'mntOptions'}"; #horse
	$self->{'mntFullCmd'}=$mntFullCmd;
	$self->{'umountFullCmd'}="umount $self->{'mntPoint'}";
	my $tmpVar="SKIP_REMOVE_$tag";
	$tmpVar =($ENV{"$tmpVar"} =~ /(^\d+)$/)?$ENV{"$tmpVar"}:1;
	$self->{'SKIP_REMOVE'} = ($tmpVar || $GLOBAL_NAS_APP_SKIP_REMOVE);
	$self->{'WISDOM'} = $ENV{'SECRET_KEY'};
	if ($NAS_APP_DEBUG) {
		print STDERR "INFORMATION:getLK() mntFullCmd=$self->{'mntFullCmd'}\n";
		print STDERR "INFORMATION:getLK() unmntFullCmd=$self->{'umountFullCmd'}\n";
		print STDERR "INFORMATION:getLK() SKIP_REMOVE is set to $self->{'SKIP_REMOVE'}\n";
	}
	$self->{'fromtag'}=1;
	return 1;
}


# 0 - failed
# 1 - success
sub mountFS
{
	my $self=shift;
	my $mntPoint=$self->{'mntPoint'};
	if ( $self->{'mntPoint'} eq '' ){ 
		usage("No mntPoint specified in the info field\n");
		return 0;
	}
	
	if ( $self->{'mntFullCmd'} eq '' ){ 
		usage("No mntFullCmd created from the info field\n");
		return 0;
	}
	
	my $appMountCmd = "mount | grep -wq $mntPoint || $self->{'mntFullCmd'}";
	($NAS_APP_DEBUG) && print STDERR "Running command $appMountCmd on $me\n";
	system ("mkdir -p $mntPoint; $appMountCmd");
	my $ret = ($? >> 8 );
	if ( $ret ){
		print STDERR "The $self->{'mntFullCmd'} of the mount point $mntPoint on $me returned $ret\n";
		print STDERR "Failing the current action\n";
		return 0;
	}

	my @failedSys=();
	my $target;
	foreach (LK::eqv_list('', $me, $self->{'tag'})) {
		$target = (split /\x01/, $_)[2];
		next if ($target eq $me );
		my $isalive=LK::sys_getstate('', $target );
		if ($isalive != $LK::ALIVE ){
			print STDERR "Target node $target is down, skipping the mount on the target system\n";
			next;
		}
		($NAS_APP_DEBUG) && print STDERR "Running commands (mkdir -p $mntPoint; $appMountCmd) on $target\n";
		system ("$ENV{LKROOT}/bin/lcdremexec -d $target -- \"mkdir -p $mntPoint; $appMountCmd\"");
		my $ret = ($? >> 8 );
		if ($ret ){
			print STDERR "Error: The $self->{'mntFullCmd'} of the mount point $mntPoint on $target returned $ret\n";
			push @failedSys, $target;
		}
	}
	
	if ( @failedSys ) {
		print STDERR "Errors mounting the $mntPoint on one or target systems (failedSystems=@failedSys)\n";
	}
	return 1;
}

# 0 - failed
# 1 - success
sub unMountFS
{
	my $self=shift;
	my $mntPoint=$self->{'mntPoint'};
	if ( $self->{'mntPoint'} eq '' ){ 
		usage("No mntPoint specified in the info field\n");
		return 0;
	}
	if ($self->{'SKIP_REMOVE'}){
		($NAS_APP_DEBUG) && print STDERR "INFORMATION: Tunable SKIP_REMOVE_$self->{'tag'} or GLOBAL_NAS_APP_SKIP_REMOVE is set in $default SKIP_REMOVE = $self->{'SKIP_REMOVE'}\n";
		($NAS_APP_DEBUG > 1 ) && $self->NoOpQuote();
		return 1;
	}

	my $appUnmountCmd = "mount | grep -wq $mntPoint && $self->{'umountFullCmd'}";
	($NAS_APP_DEBUG) && print STDERR "Running command $appUnmountCmd on $me\n";
	system ("$appUnmountCmd");
	my $ret = ($? >> 8 );
	my @mounts=grep /\s+$mntPoint\s+/,`cat /etc/mtab 2>/dev/null`;
	if ( @mounts ){
		print STDERR "The $self->{'umountFullCmd'} of the mount point $mntPoint on $me returned $ret\n";
		return 0;
	}

	my @failedSys=();
	my $target;
	foreach (LK::eqv_list('', $me, $self->{'tag'})) {
		$target = (split /\x01/, $_)[2];
		next if ($target eq $me );
		my $isalive=LK::sys_getstate('', $target );
		if ($isalive != $LK::ALIVE ){
			print STDERR "Target node $target is down, skipping the mount on the target system\n";
			next;
		}
		($NAS_APP_DEBUG) && print STDERR "Running command $appUnmountCmd on $target\n";
		system ("$ENV{LKROOT}/bin/lcdremexec -d $target -- \"$appUnmountCmd\"");
		my $ret = ($? >> 8 );
		($NAS_APP_DEBUG) && print STDERR "Running command cat /etc/mtab on $target\n";
		@mounts=grep /\s+$mntPoint\s+/,`$ENV{LKROOT}/bin/lcdremexec -d $target -- "cat /etc/mtab 2>/dev/null"`;
		if ( @mounts ){
			print STDERR "Error: The $self->{'umountFullCmd'} of the mount point $mntPoint on $target returned $ret (mounts=@mounts)\n";
			push @failedSys, $target;
		}
	}
	
	if ( @failedSys ) {
		print STDERR "Errors unmounting the $mntPoint on one or target systems (failedSystems=@failedSys)\n";
	}
	return 1;
}

sub NoOpQuote
{
	my $self=shift;
	my $tag=$self->{'tag'};
	my $outputFile="$lktmp/out$$";
	my $getCMD="LANG=C wget -nv -S 'http://labs.bible.org/api/?passage=random&formatting=plain' -O $outputFile";
	chomp (my $out= `$getCMD 2>&1`);
	if ($? != 0 ){
        print STDERR "ERROR: The command failed via $getCMD: out=$out\n";
	}
	if ( -f $outputFile ){
        chomp ($out=`LANG=C cat $outputFile`);
        if ($out ne '' ){
                print STDERR "\n#################################################\n";
                print STDERR "\t$out\n";
                print STDERR "\n#################################################\n\n";
        }
        unlink $outputFile;
	}
}

1;
