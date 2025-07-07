#!/bin/bash

pushd ./sources/Android/android-communications/scripts
./build_sdk.sh
popd
mv ./sources/Android/android-communications/SdkBuild/polar-ble-sdk.aar ./examples/example-android/polar-sensor-data-collector/polar-ble-sdk/