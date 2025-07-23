flutter build apk --debug
#./pgyer_upload.sh -k  ad683f2646611907457c2cd2058a03a2 build/app/outputs/flutter-apk/app-release.apk
./pgyer_upload.sh -k  ad683f2646611907457c2cd2058a03a2 build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk