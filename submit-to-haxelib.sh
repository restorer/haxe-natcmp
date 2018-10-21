#!/bin/bash

pushd `dirname "$0"`

[ -e natcmp.zip ] && rm natcmp.zip

zip -r -9 natcmp.zip * \
    -x submit-to-haxelib.sh

[ -e natcmp.zip ] && haxelib submit natcmp.zip
[ -e natcmp.zip ] && rm natcmp.zip

popd
