#!/bin/bash

#   ***************************************************************************
#     build-all.sh - builds android QGIS
#      --------------------------------------
#      Date                 : 01-Jun-2011
#      Copyright            : (C) 2011 by Marco Bernasocchi
#      Email                : marco at bernawebdesign.ch
#   ***************************************************************************
#   *                                                                         *
#   *   This program is free software; you can redistribute it and/or modify  *
#   *   it under the terms of the GNU General Public License as published by  *
#   *   the Free Software Foundation; either version 2 of the License, or     *
#   *   (at your option) any later version.                                   *
#   *                                                                         *
#   ***************************************************************************/


set -e
start_time=`date +%s`
#######Load config#######
source `dirname $0`/config.conf
export QGIS_ANDROID_BUILD_ALL=1

if [[ "$BUILD_TYPE" = "Release" && ! -n "${RELEASE_NAME+x}" ]]; then
    echo "script aborted, SET: BUILD_TYPE=Release RELEASE_NAME=alpha5 ./server-cron-build.sh";
    exit 0;
fi 

cd $QGIS_DIR
git reset --hard HEAD
git pull

cd $ROOT_DIR
git reset --hard HEAD
git pull

rm -Rf $APK_DIR/bin/*

BUILD_TYPE=$BUILD_TYPE ANDROID_TARGET_ARCH=armeabi $SCRIPT_DIR/build-qgis.sh
BUILD_TYPE=$BUILD_TYPE ANDROID_TARGET_ARCH=armeabi-v7a $SCRIPT_DIR/build-qgis.sh
$SCRIPT_DIR/update-apk-env.sh

cd $APK_DIR
if [[ "$BUILD_TYPE" = "Release" ]]; then
    ant release
    cp -vf $APK_DIR/bin/qgis-release.apk /home/mbernasocchi/www/download/qgis-master-$RELEASE_NAME.apk
    echo "master-$RELEASE_NAME" | cat - /home/mbernasocchi/www/download/versions.txt > /tmp/out && mv /tmp/out /home/mbernasocchi/www/download/versions.txt
    
    #remove v7a optimized libs
    rm -vrf $APK_DIR/libs/armeabi-v7a
    ant release
    cp -vf $APK_DIR/bin/qgis-release.apk /home/mbernasocchi/www/download/qgis-master-$RELEASE_NAME-armeabi.apk
    echo "master-$RELEASE_NAME-armeabi" | cat - /home/mbernasocchi/www/download/versions.txt > /tmp/out && mv /tmp/out /home/mbernasocchi/www/download/versions.txt
else 
    ant release
    cp -vf $APK_DIR/bin/qgis-release.apk /home/mbernasocchi/www/download/qgis-nightly.apk
    
    #remove v7a optimized libs
    rm -vrf $APK_DIR/libs/armeabi-v7a
    ant release
    cp -vf $APK_DIR/bin/qgis-release.apk /home/mbernasocchi/www/download/qgis-nightly-armeabi.apk
fi

end_time=`date +%s`
seconds=`expr $end_time - $start_time`
minutes=$((seconds / 60))
seconds=$((seconds % 60))

SUBJECT="Android CRON build"
EMAIL="marco@bernawebdesign.ch"
EMAILMESSAGE="/tmp/emailmessage.txt"
echo "Successfully built all in $minutes minutes and $seconds seconds"> $EMAILMESSAGE
mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE
