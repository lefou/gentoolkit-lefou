#!/usr/bin/perl -w
#
# Copyright (c) 2005 - 2007 by Tobias Roeser
# All rights reserved
# $Id$
#

use strict;

my $VERSION = "0.6.8_pre3";
my $verbose = 0;
my $pretend = 0;

$verbose && print "emaskclean $VERSION.\nCopyright (c) 2005 - 2007 by Tobias Roeser\nAll rights reserved.\n";

# Which backend?
my $backend = resolveVariable("GENTOOLKIT_LEFOU_BACKEND");

if ($backend eq "portage") {
	cleanPackageForPortage("keywords");
	cleanPackageForPortage("unmask");
}
elsif ($backend eq "paludis") {
	print "No paludis support currently. Sorry.\n"
}
else {
	print "Unsupported backend \"$backend\"\n";
}

##############################################################################
# Functions

sub cleanPackageForPortage {

	my $type = shift;
	my $unmaskMode = 1;
	
	if ($type eq "keywords") {
		$unmaskMode = 0;
	}
	elsif ($type eq "unmask") {
		$unmaskMode = 1;
	}
	else {
		print "Unsupported clean method.\n";
		return -1;
	}

	print "Cleaning $type...\n";

	my $line = "";
	my @target;
	my $sourceFile = "";
	if ($unmaskMode == 1) {
		$sourceFile = resolveVariable("portage_PACKAGE_UNMASK", "/etc/portage/package.unmask");
	} else {
		$sourceFile = resolveVariable("portage_PACKAGE_KEYWORDS", "/etc/portage/package.keywords");
	}
	my $packageDB = "/var/db/pkg";
	my $skipped = 0;
	my $passed = 0;
	my $removed = 0;
	my $isInstalled = "";
	
	open(FILE, "<$sourceFile") || die "could not open source file «$sourceFile»";
	my @source = <FILE>;
	close(FILE);
	
	foreach $line (@source) {
		my $removeThisLine = 0;
		if ($line =~ /^=([^\s]+)\s*(.*)$/) {
			my $package = $1;
			my $keyword = $2;
			
			if ($unmaskMode == 1) {
				# unmask mode
					$isInstalled = `[ -d "$packageDB/$package" ] && echo "yes" || echo "no" `;
					if($isInstalled =~ /no/) {
						$removed++;
						$removeThisLine = 1;
						print "Remove package '$package'\n";
					}
					else {
						$passed++;
						$verbose && print "Pass package '$package'\n";
					}
			}
			else { 
				if($keyword =~ /~x86|[*][*]/) {
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

	print "Processed ", ($skipped + $removed + $passed), " lines: Passed $passed, Skipped $skipped, Removed $removed packages.\n";

	if ($pretend == 0) {
		
		my $res = `mv "$sourceFile" "$sourceFile.emaskclean"`;
		if ($res ne "") {
			die "Errors while making backup copy.";
		}

		open(FILE, ">$sourceFile") || die "Could not open $sourceFile for writing.";
		print FILE @target;
		close(FILE);		
	}

	return 0;
}

# Function: resolveVariable(variableName, defaultIfVariableNotSet)
# Return: the content of the variable
sub resolveVariable {

	my $variableName = shift;
	my $variableDefault = shift;
	my $resolvedValue = "";

	# check the environment for variable
	$resolvedValue = `echo \"\${$variableName}\"`;
	chomp($resolvedValue);

	# next check in user's configuration
	if ($resolvedValue eq "" ) {
		$resolvedValue = `source \${HOME}/.gentoolkit-lefou.conf 2>/dev/null && echo \"\${$variableName}\"`;
		chomp($resolvedValue);
	}

	# next check in global configuration
	if ($resolvedValue eq "" ) {
		$resolvedValue = `source /etc/gentoolkit-lefou.conf 2>/dev/null && echo \"\${$variableName}\"`;
		chomp($resolvedValue);
	}

	if ($resolvedValue eq "") {
		$verbose && print "Could not resolve $variableName, using default value \"$variableName\"\n";
		$resolvedValue = $variableDefault;
	}
	else {
		$verbose && print "Resolve $variableName with \"$resolvedValue\"\n";
	}

	return($resolvedValue);
}

