trap "kill 0" SIGINT

BUILDS_FOLDER=Builds
rm -rf $BUILDS_FOLDER
mkdir $BUILDS_FOLDER

build_ios(){
	EXPORT_FILE=exportOptions.plist
	DEPLOYMENT_POSTPROCESSING=YES

	cd ios
	echo "IOS: Building Project 1/3"
	xcodebuild -workspace snoonu.xcworkspace -scheme Staging -sdk iphoneos -configuration Development archive -archivePath $PWD/build/snoonu.xcarchive >/dev/null 2>&1


	# Adding export file plist
	rm $EXPORT_FILE
	echo '<?xml version="1.0" encoding="UTF-8"?>' > $EXPORT_FILE
	echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $EXPORT_FILE
	echo '<plist version="1.0">' >> $EXPORT_FILE
	echo '<dict>' >> $EXPORT_FILE
	echo '    <key>method</key>' >> $EXPORT_FILE
	echo '    <string>app-store</string>' >> $EXPORT_FILE
	echo '    <key>orxynet</key>' >> $EXPORT_FILE
	echo '    <string>9U9YQN5235</string>' >> $EXPORT_FILE
	echo '</dict>' >> $EXPORT_FILE
	echo '</plist>' >> $EXPORT_FILE

	echo "IOS: Generating IPA 2/3"
	xcodebuild -exportArchive -archivePath $PWD/build/snoonu.xcarchive -exportOptionsPlist exportOptions.plist -exportPath $PWD/build -allowProvisioningUpdates >/dev/null 2>&1



	echo "IOS: IPA Generated ✅"

	cd ..


	cp ios/build/*.ipa $BUILDS_FOLDER
}

build_android(){
	cd android
	
	echo "Android: Building APK 1/2"

	./gradlew clean && ./gradlew assembleRelease >/dev/null 2>&1
	
	cd ..
	cp android/app/build/outputs/apk/staging/release/app-staging-release.apk $BUILDS_FOLDER
	
	echo "Android: APK Generated ✅"
}

build_android &
# build_ios &
wait
