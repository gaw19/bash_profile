#!/bin/bash

REV=$1
[[ ! -z $REV ]] || REV=$(git rev-parse --short HEAD)
LOGFILE=$2

CHANGELOG=$(git --no-pager log --merges HEAD...$REV --pretty=format:"* %cd %p %d%n%p" |
sed -r 's/(\(.*rpm-([0-9_]+)-x86_64.*\))/\2/g' |
awk '
{
    if($1 =="*" ) {
        cmd="git --no-pager show -s --format=\"%cn <%ce>\" " $9;
        $5="";
        $7="";
        cmd | getline name
        $8=name;
        $9="";
        gsub(/_/, ".", $NP);
        gsub(/[ ]+/," ");
        print $0
    } else {
        system("git show -s --format=\"- %B\" " $2)
    }
}' |
awk '
{
   if ($0 ~ /^*.*)$/ ) {
      gsub(/\(.*\)/, "");
   }
   print $0;
}')$'\n'

if [ -z $LOGFILE ] || [ ! -f $LOGFILE ]; then
    echo "${CHANGELOG}"
elif [ ! -z "$(git status $2 | grep $2)" ]; then
    echo "Uncommitted change in $2"
else
    echo "$CHANGELOG" >> NewChangeLog
    cat $2 >> NewChangeLog
    mv NewChangeLog $2
    echo "Change log updated in $2"
fi
