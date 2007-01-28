#!/usr/bin/perl -w
#
# Copyright (c) 2005 by Tobias Roeser
# All rights reserved
#

my $repeat = "yes";
my $auto = "no";

while( "$repeat" eq "yes" ) {

	my @result = split( /\n/, `emerge --nocolor --pretend @ARGV`);

	my $resultMsg = join( "\n", @result );
	my $need_unmask = "no";

	if( $resultMsg =~ /One of the following masked packages is required/ ) {
		$need_unmask = "yes";

		my $line = "";
		my @options;
		my $count = 0;
		my $package_to_unmask = "";
		my $cause = "";

		# find relevant lines
		foreach $line (@result) {
			#print "$line" if $line =~ /^- [^\s]* \(/;
			if( $line =~ /^- ([^\s]* \(masked by:.*\))$/ ) {
				$count++;
				push( @options, $1 );
			}
			elsif( $line =~ /dependency (required by\s+[^)]*)\)/ ) {
				$cause = "($1)";
			}
		}

		print "These are the packages I can unmask: $cause\n\n";
		for( my $i = 1; $i <= $count; $i++ ) {
				print "   $i. $options[$i - 1]\n";
		}

		if( $count == 0 ) {
			print "!!! No package found to unmask\n";
		}
		elsif( $count ==1 && "$auto" eq "yes" ) {
				if( $options[0] =~ /^(.*) \(masked by: ~x86 keyword\)\s*$/ ) {
					print "      --> auto-unmask this package\n\n";
					print `eunstable $1`, "\n";
				}
				elsif( $options[0] =~ /^(.*) \(masked by: package.mask, ~x86 keyword\)\s*$/ ) {
					print "      --> auto-unmask this package\n\n";
					print `efullunmask $1`, "\n";
				}
				elsif( $options[0] =~ /^(.*) \(masked by: package.mask\)\s*$/ ) {
					print "      --> auto-unmask this package\n\n";
					print `eunmask $1`, "\n";
				}
			}
		else {	
			# Let the user decide, which package to unmask
			print "\nWhat package to unmask (1 - $count, 'a' to auto-unmask, ^C to cancel) ? ";
			seek( STDIN, 0, 2 );
			read( STDIN, $package_to_unmask, 2 );
			print "\n";
			if( $package_to_unmask =~ /^\d+$/ && $package_to_unmask > 0 && $package_to_unmask <= $count ) {
				if( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: ~x86 keyword\)\s*$/ ) {
					print `eunstable $1`, "\n";
				}
				elsif( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: package.mask, ~x86 keyword\)\s*$/ ) {
					print `efullunmask $1`, "\n";
				}
				elsif( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: package.mask\)\s*$/ ) {
					print `eunmask $1`, "\n";
				}
				else {
					print "!!! Not suported yet.\n";
				}
			}
			elsif( $package_to_unmask =~ /^[aA]/  ) {
				print "Auto-unmask enabled\n";
				$auto = "yes";
			}
		}

		# provide actions
	}
	elsif( $resultMsg =~ /emerge: there are no ebuilds to satisfy/ ) {
		print "!!! Some requirements could not be resolved\n";
		print $resultMsg, "\n";
		$repeat = "no";
	}
	else {
		print "!!! Nothing to unmask\n";
		$repeat = "no";
	}
}

