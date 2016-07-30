#!/bin/zsh

source ../../scripts/setenv.sh

cd ..
rm -rf ane
rm -f target/net.fenyo.extension.DnsExtension.ane
mkdir -p ane/tmp/{Windows-x86,Android-ARM,iPhone-ARM,default}
cd ane/tmp
cp ../../../dns-flex/target/dns.swc .
unzip dns.swc
cp ../../../dns-android/app/target/dns-android-2.0-SNAPSHOT.jar Android-ARM/DnsExtension.jar
cp library.swf Windows-x86
cp library.swf Android-ARM
cp library.swf iPhone-ARM
cp library.swf default
cp ../../extension.xml .
adt.bat -package -target ane net.fenyo.extension.DnsExtension.ane extension.xml -swc dns.swc -platform Windows-x86 -C ./Windows-x86/ . -platform Android-ARM -C ./Android-ARM/ . -platform iPhone-ARM -C ./iPhone-ARM/ . -platform default -C ./default/ .
cp net.fenyo.extension.DnsExtension.ane ../../target
