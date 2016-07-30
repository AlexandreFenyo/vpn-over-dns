#!/bin/zsh

source ../../scripts/setenv.sh
( cd ../app ; mvn "-Dandroid.sdk.path=D:\Program Files (x86)\Android\android-sdk" clean )
rm -rf ../app/target
