#!/usr/bin/perl -w
#
# Copyright (c) 2005 - 2007 by Tobias Roeser
# All rights reserved
# $Id$
#

my $VERSION = 0.6.7;

# Which backend ?
my $backend = `echo \"\${GENTOOLKIT_LEFOU_BACKEND}\"`;

if( "$backend" eq "" ) {
	$backend = `source /etc/gentoolkit-lefou.conf 2>/dev/null && echo \"\${GENTOOLKIT_LEFOU_BACKEND}\"`;
}
if( "$backend" eq "" ) {
	$backend = `source \${HOME}/gentoolkit-lefou.conf 2>/dev/null && echo \"\${GENTOOLKIT_LEFOU_BACKEND}\"`;
}

my $repeat = "yes";
my $auto = "no";

my $usePaludis = 1;
if( "$backend" eq "paludis" ) {
	$usePaludis = 1;
}
else {
	$usePaludis = 0;
}

if( $usePaludis == 1 ) {

	while( "$repeat" eq "yes" ) {

		my @result = split( /\n/, `paludis --install --pretend --no-color @ARGV 2>&1`);

		my $resultMsg = join( "\n", @result );
		my $need_unmask = "no";

		if( $resultMsg =~ /Masked by keyword/ ) {
			
			$need_unmask = "yes";
			my $line = "";
			my @options;
			my $count = 0;
			my $package_to_unmask = "";
			my $cause = "";

			# find relevant lines
			foreach $line (@result) {
				if( $line =~ /^\s+[*] ([^\s]* Masked by keyword.*)$/ ) {
					$count++;
					push( @options, $1 );
				}
				elsif( $line =~ /^\s*[*] When adding package [']([^']*)[']:/ ) {
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
					if( $options[0] =~ /^([^\s]+): Masked by keyword \(.*~x86/ ) {
						print "      --> auto-unmask this package\n\n";
						print `eunstable $1`, "\n";
					}
					if( $options[0] =~ /^([^\s]*): .*repository mask/ ) {
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
					my $handled = 0;
					if( $options[$package_to_unmask - 1] =~ /^([^\s]+): Masked by keyword \(.*~x86/ ) {
						print `eunstable $1`;
						$handled++;
					}
					if( $options[$package_to_unmask - 1] =~ /^([^\s]*): .*repository mask/ ) {
						print `eunmask $1`;
						$handled++;
					}
					if( $handled == 0 ) {
						print "!!! Not suported yet.";
					}
					print "\n";
				}
				elsif( $package_to_unmask =~ /^[aA]/  ) {
					print "Auto-unmask enabled\n";
					$auto = "yes";
				}
			}
	
			# provide actions
		}
		else {
			print "!!! Nothing to unmask\n";
			$repeat = "no";
		}
	}
}
else {
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

}
