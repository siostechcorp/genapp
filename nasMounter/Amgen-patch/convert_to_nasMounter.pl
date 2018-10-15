#!/opt/LifeKeeper/bin/perl
#
#	Copyright (c) 2018 SIOS Technology Corp.
# Description: Convert Amgen gen/app to newer gen/app
#
# Revision: v01
# Author:  cmr
#
# MR            date    user    description
# ==            ====    ====    ==========
# 001          12Oct18   CR      Initial PoC deployment
########################## end CHANGE LOG ##################################

use Getopt::Std; # use the standard getopt package
BEGIN { require '/etc/default/LifeKeeper.pl'; }
use RKActionHandler;
use strict;
our $me = LK::lcduname();
our $default = "/etc/default/LifeKeeper";
our $lkroot="$ENV{LKROOT}";
our $lktmp="$ENV{LKROOT}/tmp";
our $DEFAULT_MOUNT_OPTIONS="soft";
chomp (my $mycmd=`basename $0`);
my $myZip="SIOS_enhancedNasMounter_gen_app";
my $pmInZip="enhancedNasMounter.pm";
my $appLib="$ENV{LKROOT}/lkadm/subsys/gen/app/lib";
chomp (my $dirname=`dirname $0`);
my $setupDir="/tmp/setupLK$$"; 
my @failedSys=();
my $tag;
my $tarFilePath;
my $mntPoint;
my $nfsServerIP;
my $nfsExport;
my $mntOptions;
my $target;
my @downSys=();
my @targetList=();
my %eqvTags;
my $logSelected="$ENV{LKSYSLOGSELECTOR}";

# simple logger
sub logmsg
{
	my $cmdC="logger -p ${logSelected}.info -t '******* [SIOS MARKER] [Psalm 34:8] *******'";
	my $msg=shift;
	print STDERR "$msg\n";
	system ("$cmdC $msg");
}

# sleep routine with status .
sub showWait
{
	my $maxWait=shift;
	if ($maxWait eq '' || $maxWait < 2 ){ 
		$maxWait=5; #why 5?  Just because I like 5
	}
	foreach (1..$maxWait){
		print STDERR ".";
		sleep 1;
	}
	print "\n";
}

# function to ask if the customer wants to continue after a
# particular section or after an error
sub doContinue
{
	print "Do you wish to continue (Y|N)\n";
	my $userInput=<STDIN>;
	chomp ($userInput);
	if ($userInput =~ /y/i ){
		return 0;
	}
	print "You pressed $userInput.\n";
	print "If you want to continue: Press Y.  To exit: Press any key.\nIf you press any key other than Y, the script will exit\n";
	$userInput=<STDIN>;
	chomp ($userInput);
	if ($userInput =~ /Y/i ){
		return 0;
	}
	exit 1;
}

# usage
sub myUsage
{
	print STDERR "Usage:
	full_path_to_tarfile
	tag
	mntPoint
	nfsServerIP
	nfsExport
	mntOptions
	EXAMPLE: ${dirname}/${mycmd} $dirname/${myZip}-5.00.21.tgz nasSQA /sapmnt/SQA 172.17.2.13 /export/sapmnt/SQA rw-sync-soft-bg-intr-timeo=30-retrans=2
	\n";
	exit 1;
}

# find the resource state for the SPS-L resource
sub checkResourceState { # params: tag 

	$tag = shift;
	@_ = LK::ins_list('', '', '', '', $tag, '');
	@_ = split /\001/, $_[0];
	return $_[6]; # state is the 7th field
};

# this is the code to copy the script files into
# the right gen/app location by server and tag
sub doCopy
{
	my $sys=shift;
	my $copyTag=shift;
	my $ret=0;
	if ($sys eq '' || $copyTag eq '' ){
		logmsg ("No system... developer (or user) error.  Please report this to 'support\@us.sios.com'");
		exit 1;
	}
	my $actionPath="$lkroot/subsys/gen/resources/app/actions";
	my $recoverPath="$lkroot/subsys/gen/resources/app/recovery";
	my $loopStatus=0;
		
	foreach my $script ("restore", "remove", "recover", "quickCheck"){
		# if I can't find the script in the local directory, error
		if ( ! -f $script ){
			logmsg ("The file $script could not be found on $me");
			logmsg ("System $sys could not be updated");
			exit 1;
		}
		# check if the script exists on the system (targetted) before copying
		my $scriptPath;
		if ( "$script" =~ /recover/i ){
			$scriptPath="$recoverPath/\!$script/$copyTag";
		}else{
			$scriptPath="$actionPath/\!$script/$copyTag";
		}
		system ("lcdremexec -d $sys -- \"[ -f $scriptPath ]\"");
		my $fileExists=($? >> 8);
		logmsg "FileCheck: Return=$fileExists: File checked=$scriptPath";
		if ($fileExists){
				logmsg ("The file $scriptPath does not exist on $sys, it will not be updated on this node");
				next;
		}
		if ($sys eq $me ){
			system ("cp -vf $script $scriptPath");
		}else{
			system ("lcdrcp $script \"$sys:$scriptPath\"");
		}
		$ret = ($? >> 8 );
		if ($ret ){
			logmsg ("Unable to update the script $script on $sys");
			$loopStatus++;
		}
	}
	if ($loopStatus){
		logmsg ("One or more scripts failed to be copied on $sys, copy all the scripts manually from $me ");
		exit 1;
	}
	logmsg ("Updates for the scripts were successful on $sys");
}
# end functions
logmsg ("$mycmd start");
$tarFilePath=shift;
$tag=shift;
$mntPoint=shift;
$nfsServerIP=shift;
$nfsExport=shift;
$mntOptions=shift;


if ( $tarFilePath eq '' || ! -f $tarFilePath ){
	print STDERR "You must specify the full path of the tarfile from SIOS Technology Corp\n";
	print STDERR "This tarfile ${myZip}-<version>.tgz ( contains the gen/app scripts for the enhancednasMounter)\n";
	print STDERR "Please download this file to the same directory that you are running this script or change directory to the location containing the downloaded tar file\n";
	myUsage();
}

# this might not be needed b/c I couldn't get the script to run as any
# non-root user, but we want to be sure
(my $eUid) = (getpwuid($<))[2];
if ($eUid != 0 ){
	logmsg ("This script must be run by the root user with id=0 and group=0");
	exit 1;
}

# Make sur ethe zip file specified is an actual zip file
system ("file $tarFilePath | grep -iq 'gzip compressed'");
my $ret = ($? >> 8 );
if ($ret != 0 ){
	logmsg ("Invalid zip file path $tarFilePath specified. The file is not a tar zip archive '.tgz'");
	myUsage();
}

if ($tag eq '' || $nfsExport eq '' || $mntPoint eq '' || $nfsServerIP eq '' ){
	myUsage();
}

# check input arguments
#tag to use 
@_ = LK::ins_list('', '', '', '', $tag, '');
my $ret=($? >> 8);
if (@_ == 0 ){
	logmsg ("Invalid tag specified");
	myUsage();
}

#IP
system ("ping -c1 -W2 $nfsServerIP > /dev/null 2>&1");
$ret = ($? >> 8 );
if ($ret ){
	logmsg("Unable to ping the IP $nfsServerIP.  Verify that the IP specified '$nfsServerIP' is valid");
	doContinue();
}
# mount
my $showCmdName="showmount";
my $showCmd=`which $showCmdName 2>/dev/null`;
chomp ($showCmd);
if ( ! -x $showCmd ){
	logmsg ("Unable to find the showmounts command.");
	doContinue();
}else{
	system ("$showCmd --exports $nfsServerIP 2>/dev/null | grep -wq $nfsExport");
	$ret = ($? >> 8 );
	if ($ret ){
		logmsg("Unable to find the export $nfsExport on the server $nfsServerIP");
		doContinue();
	}
}

if ($mntOptions eq '' ){
	$mntOptions=$DEFAULT_MOUNT_OPTIONS;
}
logmsg ("$mycmd options: tag=$tag mntPoint=$mntPoint nfsServerIP=$nfsServerIP nfsExport=$nfsExport mntOptions=$mntOptions");

# check the state.   We want to run on the ISP node so we can
# stop the resource on the primary during the update
# this is easier than making sure it is stopped everywhere
my $state = checkResourceState($tag);
if ("$state" ne "ISP")
{
	logmsg ("The resource is not ISP on $me");
	logmsg ("This update sctipt expected the resource ot be ISP");
	doContinue();
}

# create a location to untar files
system ("mkdir -p $setupDir");
if (! -d $setupDir ){
	logmsg ("Unable to make directory $setupDir");
	exit 1;
}
# do the work for the tar file
system ("tar -xzvf $tarFilePath --directory=$setupDir ");
# check tar output - so we don't get further along and fail
$ret=0;
foreach my $script ("restore", "remove", "recover", "quickCheck"){
	if ( ! -f "$setupDir/$script" ){
		logmsg ("Tar archive did not contain $script, or extract to $setupDir/$script failed");
		$ret=1;
	}
	
}
if ($ret ){
	logmsg ("Extraction failed");
	exit 1;
}

# convert the mntOptions to what can actually be saved inside the gen/app
$mntOptions=~s/,/-/g;
logmsg ("All input options have been 'reasonably' verified. Do you wish to make the changes to your system.");
doContinue();

# setup scripts
logmsg("Setting up scripts");
my $origDir=$dirname;
chdir $setupDir;
chomp (my $currentDir=`pwd`);
if ( "$currentDir" ne "$setupDir" ){
	logmsg ("Could not change to $setupDir currdir=$currentDir");
	exit 1;
}

# this calls the nasMounter specific setup script.  The nasMounter setup script
# will plae the .pm file in the correct location on the source
system ("$currentDir/setup");
$ret = ($? >> 8 );
if ( $ret ){
	logmsg ("Setup script $currentDir/setup failed");
	exit 1;
}

logmsg ("$pmInZip setup has been completed");
logmsg ("To continue the update, the resource $tag will need to be put in maintenance mode");
doContinue();
system ("$lkroot/bin/ins_setstate -t $tag -S OSU -R 'OPERATION UPDATE $$'");
$ret = ($? >> 8 );
if ( $ret ){
	logmsg ("Unable to set the resource $tag to the correct state");
	exit 1;
}
logmsg ("Slight wait for checks to complete $ENV{LKCHECKINTERVAL}");
showWait($ENV{LKCHECKINTERVAL}); #change this to the lkcheckinterval

#internal kit stuff now
doCopy($me,$tag);

logmsg ("Updating the info field on $me");
system ("$lkroot/bin/ins_setinfo -t $tag -v '$mntPoint $nfsServerIP $nfsExport $mntOptions'");
$ret = ($? >> 8 );
if ( $ret ){
	logmsg ("Unable to update the info field on $me");
	exit 1;
}
# we have to do a lot of stuff on the target too
$target;
foreach (LK::eqv_list('', $me, $tag)) {
	($target,my $targetTag) = (split /\x01/, $_)[2,3];
	next if ($target eq $me );
	$eqvTags{$target}=$targetTag;
	push @targetList, $target;
	my $isalive=LK::sys_getstate('', $target );
	if ($isalive != $LK::ALIVE ){
		logmsg ("Target node $target is down, skipping the mount on the target system");
		push @downSys, $target;
		next;
	}
}

if (@downSys){
	logmsg ("The following systems were down and can not be updated: @downSys");
	logmsg ("All systems must be up for this script to work properly");
	exit 1;
}

@downSys=();
@failedSys=();
foreach $target (@targetList)
{
	logmsg ("Update for $pmInZip for $target starting");
	my $isalive=LK::sys_getstate('', $target );
	if ($isalive != $LK::ALIVE ){
		logmsg ("Target node $target is down, skipping the mount on the target system");
		push @downSys, $target;
		next;
	}
	if ( ! -f $pmInZip ){
		logmsg ("The pm file $pmInZip was not found on $me");
		logmsg ("System $target could not be updated");
		exit 1;
	}
	system ("$lkroot/bin/lcdrcp $pmInZip $target:${appLib}/$pmInZip");
	$ret = ($? >> 8 );
	if ( $ret ){
		logmsg("Unable to copy the $pmInZip file to the target system $target");
		exit 1;
	}
	# now copy the restore stuff
	logmsg ("Updates for the 'action/*' and recovery files on $target");
	doCopy($target,$eqvTags{$target});

	logmsg ("Updating the info field on $target");
	system ("$lkroot/bin/ins_setinfo -d $target -t $eqvTags{$target} -v '$mntPoint $nfsServerIP $nfsExport $mntOptions'");
	$ret = ($? >> 8 );
	if ( $ret ){
		push @failedSys,$target;
	}
}

if (@downSys){
	logmsg ("The following systems were down and could not be updated: @downSys");
	exit 1;
}

if (@failedSys){
	logmsg ("One or more nodes failed to be updated.  List equals '@failedSys'");
	logmsg ("You will need to repeat the update process described in the Readme on each failed node");
	exit 1;
}
logmsg ("Update of instance $tag was successful");
chdir $origDir;
chomp (my $currentDir=`pwd`);
if ( "$currentDir" ne "$origDir" ){
	logmsg ("Could not change to $origDir currdir=$currentDir");
	logmsg ("Please manually remove $setupDir");
}else{
	logmsg ("Cleaning up $setupDir");
	if ( -d $setupDir && -e "$setupDir/$pmInZip" ){
		system ("rm -rvf $setupDir");
	}
}
logmsg ("To continue the update, the resource $tag will need to be taken out of maintenance mode");
doContinue();
system ("$lkroot/bin/ins_setstate -t $tag -S ISP -R 'FINISHED OPERATION UPDATE $$'");
$ret = ($? >> 8 );
if ( $ret ){
	logmsg ("Unable to set the resource $tag to the correct state");
	logmsg ("Please manually restore the resource $tag to ISP using the GUI In-service operation");
}
logmsg ("$mycmd end");
exit 0;
