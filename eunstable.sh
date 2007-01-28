#!/bin/bash

keyword="~x86"
unmask=false
unstable=false

###USE_PORTAGE### # portage/emerge
###USE_PORTAGE### CONF_KEYWORDS="/etc/portage/package.keywords"
###USE_PORTAGE### CONF_UNMASK="/etc/portage/package.unmask"

###USE_PALUDIS### # paludis
###USE_PALUDIS### CONF_KEYWORDS="/etc/paludis/keywords.conf"
###USE_PALUDIS### CONF_UNMASK="/etc/paludis/package_unmask.conf"

if [ "$(basename $0)" == "eunstable" ]; then
    unstable=true
elif [ "$(basename $0)" == "eunmask" ]; then
    unmask=true
elif [ "$(basename $0)" == "efullunmask" ]; then
    unmask=true
    unstable=true
else
    echo "!!! Wrong call"
    echo "!!! this script must be called \"eunstable\", \"eunmask\" or \"efullunmask\""
    echo "!!! Abort"
    exit 1
fi

for package in $*; do
    
    if [ $unmask == true ]; then
	echo ">>> Adding \"=$package\" to ${CONF_UNMASK}"
	cp ${CONF_UNMASK} ${CONF_UNMASK}.eunmask
	echo "=$package" >> ${CONF_UNMASK}
    fi

    if [ $unstable == true ]; then
	echo ">>> Adding \"=$package $keyword\" to ${CONF_KEYWORDS}"
	cp ${CONF_KEYWORDS} ${CONF_KEYWORDS}.eunstable
	echo "=$package $keyword" >> ${CONF_KEYWORDS}
    fi

done
