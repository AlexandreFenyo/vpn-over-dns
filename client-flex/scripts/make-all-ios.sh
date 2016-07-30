#!/bin/zsh

source ../../scripts/setenv-ios.sh
cd ..

cp ../dns-flex/archives/dns.swc ../dns-flex/target

rm -f src/Main.swf # releases/vpnoverdns.apk

mxmlc -incremental=false -output src/Main.swf "-compiler.source-path+=locale/{locale}" +configname=airmobile -source-path+=src -locale=en_US -locale=fr_FR -library-path+=FB-libs "-library-path+=locale/{locale}/fiber_rb.swc" -library-path+="../dns-flex/target/dns.swc" -- src/Main.mxml

cd src
$APACHE_FLEX_HOME/bin/adt -package -target ipa-test -storetype pkcs12 -storepass PASSWORD -keystore ../../general/certs/fenyomobile.p12 ../releases/vpnoverdns.ipa Main-app.xml Main.swf assets/icon-{16,32,36,48,57,72,114,128}.png -extdir ../../dns-ane/target
