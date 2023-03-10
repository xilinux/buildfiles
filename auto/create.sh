#!/bin/sh
read -p "package name> " name
read -p "package version> " version
read -p "description> " desc
deps=$(find repo -type d -maxdepth 1 -mindepth 1 | sed 's/.*\///g' | rev | cut -f1 -d/ | rev |fzf -m --prompt="dependencies> " | tr '\n' ' ')
read -p "source url> " url
read -p "additional urls> " additional
type=$(find ./templates -type f | sed "s/.xibuild//g" | rev | cut -f1 -d/ | rev | fzf --prompt="build type> ")

clear
echo Name: $name
echo Deps: $deps
echo Desc: $desc
echo Vers: $version
echo Sour: $url
echo Addi: $additional
echo Type: $type
read -p "Ok? " go

template=./templates/$type.xibuild
package=repo/$name
buildfile=$package/$name.xibuild

[ -f $buildfile ] && read -p "Buildfile already exists, overwrite? " go
mkdir -p $package

url=$(echo $url | sed "s/$version/\$PKG_VER/g" | sed "s/pkgver/PKG_VER/g")
makedeps=""

case $type in
    make|configure)
        makedeps="make $makedeps" 
        ;;
    meson)
        makedeps="meson ninja $makedeps" 
        ;;
    cmake)
        makedeps="cmake $makedeps" 
        ;;
    python)
        makedeps="python python-setuptools $makedeps" 
        ;;
esac

cat > $buildfile << EOF
#!/bin/sh

NAME="$name"
DESC="$desc"

MAKEDEPS="$makedeps"
DEPS="$deps"

PKG_VER=$version
SOURCE="$url"
EOF

 
[ "${#additional}" = 0 ] || {
    filenames=""
    for l in $additional; do
        filename=$(basename $l)
        curl -SsL $l > $package/$filename  
        filenames="$filename $filenames"
        sleep 2
    done
    echo "ADDITIONAL=\"$filenames\"" >> $buildfile
    
    echo $filenames | grep -q ".patch " && {
    cat >> $buildfile << EOF

prepare () {
    apply_patches
}
EOF
    }
}

echo >> $buildfile
cat $template >> $buildfile
vim $buildfile

# remove any things i may have copied from alpine's build scripts
sed -i "s/\$pkgname/$name/g" $buildfile
sed -i "s/\$pkgver/\$PKG_VER/g" $buildfile
sed -i "s/\$pkgdir/\$PKG_DEST/g" $buildfile
sed -i "s/\$srcdir/\$BUILD_ROOT/g" $buildfile
sed -i "s/\$builddir/\$BUILD_ROOT/g" $buildfile
