#!/bin/zsh

source ../../scripts/setenv.sh
# pour maven
( cd ../app ; mvn install:install-file "-Dfile=$APACHE_FLEX_HOME\lib\android\FlashRuntimeExtensions.jar" -DgroupId=fr.fenyo -DartifactId=FRE -Dversion=4.14.1 -Dpackaging=jar )
# pour Android Studio
mkdir ../libs
cp "$APACHE_FLEX_HOME\lib\android\FlashRuntimeExtensions.jar" ../libs
