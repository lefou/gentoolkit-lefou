#!/usr/bin/perl -w
#
# Copyright (c) 2005 - 2007 by Tobias Roeser
# All rights reserved
# $Id$
#

my $VERSION = "0.6.8_pre3";

# Which backend?
my $backend = resolveVariable("GENTOOLKIT_LEFOU_BACKEND");

# Which arch ?
my $arch = resolveVariable("GENTOOLKIT_LEFOU_ARCH");

print "using arch: $arch\n";

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
					if( $options[0] =~ /^([^\s]+): Masked by keyword \(.*~([a-zA-Z0-9]+?)/ ) {
						if($2 eq $arch) {
							print "      --> auto-unmask this package\n\n";
							print `eunstable $1`, "\n";
						}
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
					if( $options[$package_to_unmask - 1] =~ /^([^\s]+): Masked by keyword \(.*~([a-zA-Z0-9]+?)/ ) {
						if($2 eq $arch) {
							print `eunstable $1`;
							$handled++;
						}
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

		my @result = split( /\n/, `emerge --color=n --pretend @ARGV`);
	
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
					if( $options[0] =~ /^(.*) \(masked by: ~([a-zA-Z0-9]+?) keyword\)\s*$/ ) {
						if($2 eq $arch) {
							print "      --> auto-unmask this package\n\n";
							print `eunstable $1`, "\n";
						}
					}
					elsif( $options[0] =~ /^(.*) \(masked by: package.mask, ~([a-zA-Z0-9]+?) keyword\)\s*$/ ) {
						if($2 eq $arch) {
							print "      --> auto-unmask this package\n\n";
							print `efullunmask $1`, "\n";
						}
					}
					elsif( $options[0] =~ /^(.*) \(masked by: package.mask\)\s*$/ ) {
						print "      --> auto-unmask this package\n\n";
						print `eunmask $1`, "\n";
					}
					elsif( $options[0] =~ /^(.*) \(masked by: missing keyword\)\s*$/ ) {
						print "      --> auto-unmask this package\n\n";
						print `enokeyword $1`, "\n";
					}
					elsif( $options[0] =~ /^(.*) \(masked by: package.mask, missing keyword\)\s*$/ ) {
						print "      --> auto-unmask this package\n\n";
						print `eunmask $1`;
						print `enokeyword $1`, "\n";
					}
				}
			else {	
				# Let the user decide, which package to unmask
				print "\nWhat package to unmask (1 - $count, 'a' to auto-unmask, ^C to cancel) ? ";
				seek( STDIN, 0, 2 );
				read( STDIN, $package_to_unmask, 2 );
				print "\n";
				if( $package_to_unmask =~ /^\d+$/ && $package_to_unmask > 0 && $package_to_unmask <= $count ) {
					if( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: ~([a-zA-Z0-9]+?) keyword\)\s*$/ ) {
						if($2 eq $arch) {
							print `eunstable $1`, "\n";
						}
					}
					elsif( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: package.mask, ~([a-zA-Z0-9]+?) keyword\)\s*$/ ) {
						if($2 eq $arch) {
							print `efullunmask $1`, "\n";
						}
					}
					elsif( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: package.mask\)\s*$/ ) {
						print `eunmask $1`, "\n";
					}
					elsif( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: missing keyword\)\s*$/ ) {
						print `enokeyword $1`, "\n";
					}
					elsif( $options[$package_to_unmask - 1] =~ /^(.*) \(masked by: package.mask, missing keyword\)\s*$/ ) {
						print `eunmask $1`;
						print `enokeyword $1`, "\n";
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
			print "\nDo you want to run emerge now? [y/N] ";
			my $emerge = "n";
                        seek( STDIN, 0, 2 );
                        read( STDIN, $emerge, 2 );
                        print "\n";
			if( $emerge =~ /^y|Y$/ ) {
				exec ("emerge", @ARGV);
			}

		}
	}

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

