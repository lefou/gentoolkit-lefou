#!/bin/bash
##############################################################
# Clean Up /etc/portage/package.unmask file
# Copyrigth (c) by Tobias Roeser, 2005-2007
# All rights reserved
##############################################################

PACKAGE_DB=/var/db/pkg
ARCH="~x86"

###USE_PORTAGE### UNMASK_FILE=/etc/portage/package.unmask
###USE_PORTAGE### KEYWORDS_FILE=/etc/portage/package.keywords

###USE_PALUDIS### UNMASK_FILE=/etc/paludis/package_unmask.conf
###USE_PALUDIS### KEYWORDS_FILE=/etc/paludis/keywords.conf

verbose=0

cleaner() {
	file="$1"
	suffix="$2"
	if [ -z "${file}" ] ; then
		echo "No file given"
		return; 
	fi
	if [ ! -w "${file}" ] ; then
		echo "cannot read/write ${file}"
		return;
	fi 

	echo "cleaning ${file}"

	##############################################################
	# make a backup
	cp ${file} ${file}.emaskclean

        if [ -e ${file}.emaskclean.new ]; then 
		rm ${file}.emaskclean.new || echo "!!! Error 1"
        	[ -e ${file}.emaskclean.new ] && exit 1;
	fi
	
	##############################################################
    for i in $(cat ${file} | sed -e "s/${suffix}\s*$//"); do
	package=${i/#=/}
        #count=0
	if [ "$i" == "=$package" ]; then

    	    # Method A: ask equery
	    #count=$(equery -q list $package | wc -l)

	    # Method B: look into pachage database /var/db/pkg (faster)
	    if [ -d "$PACKAGE_DB/$package" ]; then
		# package is installed
		[ $verbose -gt 1 ] && echo "Leave line: $i"
	    else
		# package is not installed
		echo "Remove line: $i ${suffix}"
		continue;
	    fi
	else 
	    [ $verbose -gt 1 ] && echo "Ignore line: $i ${suffix}"
	fi
	echo "$i ${suffix}" >> ${file}.emaskclean.new 
    done

    ##############################################################
    # move new file to current
    mv ${file}.emaskclean.new ${file} || ( echo "!!! Error 2" )

}

cleaner ${UNMASK_FILE}

cleaner ${KEYWORDS_FILE} ${ARCH}
