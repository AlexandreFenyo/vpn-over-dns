#!/bin/zsh

source ../../scripts/setenv.sh
rm -rf ../app/target
cd ../app ; mvn "-Dandroid.release=true" "-Dandroid.sdk.path=$ANDROID_HOME" clean generate-sources install
