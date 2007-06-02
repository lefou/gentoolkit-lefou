#!/usr/bin/perl -w
#
# Copyright (c) 2005 - 2007 by Tobias Roeser
# All rights reserved
# $Id$
#

my $VERSION = 0.6.8;
my $verbose = 0;
my $pretend = 0;


# Which backend ?
my $backend = `echo \"\${GENTOOLKIT_LEFOU_BACKEND}\"`;

if( "$backend" eq "" ) {
	$backend = `source /etc/gentoolkit-lefou.conf 2>/dev/null && echo \"\${GENTOOLKIT_LEFOU_BACKEND}\"`;
}
if( "$backend" eq "" ) {
	$backend = `source \${HOME}/gentoolkit-lefou.conf 2>/dev/null && echo \"\${GENTOOLKIT_LEFOU_BACKEND}\"`;
}

my $usePaludis = 0;
if( "$backend" eq "paludis" ) {
	$usePaludis = 1;
}
else {
	$usePaludis = 0;
}

if( $usePaludis == 1 ) {

	print "No paludis support currently. Sorry."

}
else {

	my $line = "";
	my @target;
	my $sourceFile = "/etc/portage/package.keywords";
	my $packageDB = "/var/db/pkg";
	my $skipped = 0;
	my $passed = 0;
	my $removed = 0;
	
	open(FILE, "<$sourceFile") || die "could not open source file";
	my @source = <FILE>;
	close(FILE);
	
	foreach $line (@source) {
		my $removeThisLine = 0;
		if ($line =~ /^=([^\s]+)\s*(.*)$/) {
			my $package = $1;
			my $keyword = $2;
			
			if ($keyword =~ /~x86|[*][*]/) {
				# check
				$isInstalled = `[ -d "$packageDB/$package" ] && echo "yes" || echo "no" `;
				if($isInstalled =~ /no/) {
					$removed++;
					$removeThisLine = 1;
					print "Remove package '$package' with keyword '$keyword'\n";
				}
				else {
					$passed++;
					$verbose && print "Pass package '$package' with keyword '$keyword'\n";
				}
			}
			else {
				$skipped++;
				$verbose && print "Skipping keyword '$keyword'\n";
			}
		}
		else {
			$skipped++;
			$verbose && print "Skip generic line: $line"
		}

		if($removeThisLine == 0) {
			push(@target, $line);
		}

	}

	#print "\nTARGET\n------\n";
	#print @target;

	$verbose && print "Processed ", ($skipped + $removed + $passed), " lines: Passed $passed, Removed $removed, Skipped $skipped packages.\n";

	if ($pretend == 0) {
		
		my $res = `mv "$sourceFile" "$sourceFile.emaskclean"`;
		if ($res ne "") {
			die "Errors while making backup copy.";
		}

		open(FILE, ">$sourceFile") || die "Could not open $sourceFile for writing.";
		print FILE @target;
		close(FILE);		
	}
}
