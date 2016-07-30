#!/bin/zsh

source ../../scripts/setenv.sh
cd ..
rm -f target/dns.swc
( cd src ; find . -name '*.as' ) | tr / . | sed 's/\.as$//' | sed 's/^..//' | xargs "$APACHE_FLEX_HOME"/bin/compc -debug=true -swf-version=27 -incremental=false +configname=airmobile +flexsdk.framework.lib.dir="$APACHE_FLEX_HOME" -output target/dns.swc -sp src --

