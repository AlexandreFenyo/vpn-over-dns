#!/bin/zsh

source ../../scripts/setenv.sh
cd ..

rm -f src/Main.swf releases/vpnoverdns.air src/Main-app-noext.xml

mxmlc -swf-version=27 -incremental=false -output src/Main.swf "-compiler.source-path+=locale/{locale}" +configname=airmobile -source-path+=src -locale=en_US -locale=fr_FR -library-path+=FB-libs "-library-path+=locale\{locale}\fiber_rb.swc" -library-path+="..\dns-flex\target\dns.swc" -- src/Main.mxml

cd src
cat Main-app.xml | fgrep -v '<extensionID>net.fenyo.extension.DnsExtension</extensionID>' > Main-app-noext.xml
"$APACHE_FLEX_HOME/bin/adt.bat" -package -storetype pkcs12 -storepass PASSWORD -keystore ../../general/certs/fenyomobile.p12 -target air ../releases/vpnoverdns.air Main-app-noext.xml Main.swf assets/icon-{16,32,36,48,57,72,114,128}.png
