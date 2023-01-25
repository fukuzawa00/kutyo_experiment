#!/usr/bin/sh
LANG=${LANG:="C"}
export LANG
TEXTDOMAIN=${TEXTDOMAIN:='my_domain'}
export TEXTDOMAIN

help() {
        gettext ${TEXTDOMAIN} "Usage: my_script  ...¥n"
}

do_print() {
        str=`gettext ${TEXTDOMAIN} "arg is"`
        printf "%s %s¥n" "$str" $1
}

if [ $# -le 0 ]
then
        help
        exit 0
fi

str=`gettext ${TEXTDOMAIN} "arg is"`
while [ $# -ne 0 ]
do
        do_print $1
        shift
done
