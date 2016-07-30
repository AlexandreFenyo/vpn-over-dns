#!/bin/zsh

source ../../scripts/setenv.sh
cd ..

rm -f src/Main.swf releases/vpnoverdns.apk

mxmlc -swf-version=27 -incremental=false -output src/Main.swf "-compiler.source-path+=locale/{locale}" +configname=airmobile -source-path+=src -locale=en_US -locale=fr_FR -library-path+=FB-libs "-library-path+=locale\{locale}\fiber_rb.swc" -library-path+="..\dns-flex\target\dns.swc" -- src/Main.mxml

cd src
"$APACHE_FLEX_HOME/bin/adt.bat" -package -target apk-captive-runtime -storetype pkcs12 -storepass PASSWORD -keystore ../../general/certs/fenyomobile.p12 ../releases/vpnoverdns.apk Main-app.xml Main.swf assets/icon-{16,32,36,48,57,72,114,128}.png -extdir ../../dns-ane/target
