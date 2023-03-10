#!/bin/sh

[ -f /usr/lib/colors.sh ] && . /usr/lib/colors.sh

if [ $# = 0 ]; then
    printf "Name of package: python-"
    read name
else
    name=$1
fi

json_url=https://pypi.org/pypi/$name/json

if [ "$(curl -s -o /dev/null -w "%{http_code}" $json_url)" != 200 ] ; then
   echo "Failed to find $name" 
   exit 1
fi

json=$(curl -SsL $json_url)
version=$(printf "%s" "$json" | jq -r '.info.version')
desc=$(printf "%s" "$json" | jq -r '.info.summary')
#url=$(printf "%s" "$json" | jq -r '.urls[] | select((.version="1.0.3")) | .url' | grep -v "whl" | sed "s/$version/\$PKG_VER/g")

url="https://files.pythonhosted.org/packages/source/${name%${name#?}}/$name/$name-\$PKG_VER.tar.gz"

deps=$(printf "%s" "$json" | jq -r '.info.requires_dist | .[]' | cut -d' ' -f1 | tr '\n' ' ')
if [ ${#deps} != 0 ]; then
    package_deps=$(echo $deps | sed 's/\(\w*\)/python-\1/g')
    echo $package_deps
fi

echo PKG_VER: $version
echo DESC: $desc
echo SOURCE: $url
echo DEPS: $package_deps

file=repo/python-$name/python-$name.xibuild
inp=templates/pypi.xibuild
if [ -f $file ]; then
    inp=$file
    echo "replacing existing"
fi

tmp=/tmp/python-$name.xibuild
rm -f $tmp
cat $inp > $tmp

sed -i "s@^SOURCE=.*@SOURCE=$url@g" $tmp
sed -i "s@^PKG_VER=.*@PKG_VER=$version@g" $tmp
sed -i "s@^DESC=.*@DESC=\"$desc\"@g" $tmp

if [ ${#deps} != 0 ]; then
    printf "${LIGHT_BLUE}Please ensure the following exist: ${BLUE}${deps}${RESET}\n"
    sed -i "s/^DEPS=.*/DEPS=\"$package_deps\"/g" $tmp
fi

mkdir -p repo/python-$name
mv $tmp $file

printf "${GREEN}Written to $file${RESET}\n"

