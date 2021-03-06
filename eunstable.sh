#!/bin/bash
#
# Copyright (c) 2005 - 2007 by Tobias Roeser
# All rights reserved
# $Id$
#

VERSION=0.6.8

# Which backend ?
GENTOOLKIT_LEFOU_BACKEND="${GENTOOLKIT_LEFOU_BACKEND:-$(source /etc/gentoolkit-lefou.conf 2>/dev/null && echo "${GENTOOLKIT_LEFOU_BACKEND}")}"
GENTOOLKIT_LEFOU_BACKEND="${GENTOOLKIT_LEFOU_BACKEND:-$(source ${HOME}/.gentoolkit-lefou.conf 2>/dev/null && echo "${GENTOOLKIT_LEFOU_BACKEND}")}"

if [ "${GENTOOLKIT_LEFOU_BACKEND}" = "portage" ] ; then
        CONF_UNMASK=/etc/portage/package.unmask
        CONF_KEYWORDS=/etc/portage/package.keywords
elif [ "${GENTOOLKIT_LEFOU_BACKEND}" = "paludis" ] ; then
        CONF_UNMASK=/etc/paludis/package_unmask.conf
        CONF_KEYWORDS=/etc/paludis/keywords.conf
else
        echo "No backend defined."
        exit 1
fi

# Which arch
GENTOOLKIT_LEFOU_ARCH="${GENTOOLKIT_LEFOU_ARCH:-$(source /etc/gentoolkit-lefou.conf 2>/dev/null && echo "${GENTOOLKIT_LEFOU_ARCH}")}"
keyword="~${GENTOOLKIT_LEFOU_ARCH:-x86}"

unmask=false
unstable=false
nokeyword=false

if [ "$(basename $0)" == "eunstable" ]; then
    unstable=true
elif [ "$(basename $0)" == "eunmask" ]; then
    unmask=true
elif [ "$(basename $0)" == "efullunmask" ]; then
    unmask=true
    unstable=true
elif [ "$(basename $0)" == "enokeyword" ]; then
    nokeyword=true
else
    echo "!!! Wrong call"
    echo "!!! this script must be called \"eunstable\", \"eunmask\", \"efullunmask\" or \"enokeyword\""
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

    if [ $nokeyword == true ]; then
	echo ">>> Adding \"=$package **\" to ${CONF_KEYWORDS}"
	cp ${CONF_KEYWORDS} ${CONF_KEYWORDS}.enokeyword
	echo "=$package **" >> ${CONF_KEYWORDS}
    fi

done

