#!/bin/bash

###USE_PORTAGE### ETC_PORTAGE_DIR="/etc/portage"
###USE_PORTAGE### SORT_FILES="package.keywords package.use package.unmask"

###USE_PALUDIS### ETC_PORTAGE_DIR="/etc/paludis"
###USE_PALUDIS### SORT_FILES="keywords.conf use.conf package_unmask.conf"

for i in ${SORT_FILES}; do 
    SORTFILE="${ETC_PORTAGE_DIR}/${i}"
    echo -n "sorting ${SORTFILE}... "
    cp "${SORTFILE}" "${SORTFILE}.esort"
    sort --unique "${SORTFILE}.esort" > "${SORTFILE}" && echo "done" || echo "error"
done
