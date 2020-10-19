trap "kill 0" SIGINT

BUILDS_FOLDER=Builds
rm -rf $BUILDS_FOLDER
mkdir $BUILDS_FOLDER

APPCENTER_USERNAME=<ORG_USER_NAME_HERE>
IOS_APPCENTER_IDENTIFIER=<IOS_APPCENTER_IDENTIFIER_HERE>
ANDROID_APPCENTER_IDENTIFIER=<ANDROID_APPCENTER_IDENTIFIER_HERE>

APP_CENTER_TOKEN_IOS=<IOS_TOKEN_APPCENTER_HERE>
APP_CENTER_TOKEN_ANDROID=<ANDROID_TOKEN_APPCENTER_HERE>

############### BUILDING/Integration ###############
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
	echo '    <string>development</string>' >> $EXPORT_FILE
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

############### DEPLYOMENT ###############
publish_ios(){
	# Publishing IPA to AppCenter
	ipaPath=$(find ~/ipas -name "*.ipa" | head -1)
	echo "Found ipa at $ipaPath"

	if [[ -z ${ipaPath} ]]
	then
	    echo "No IPAs were found, skip publishing to App Center 💥"
	else
	    echo "Publishing IPA to App Center 🚀"
	    appcenter distribute release \
	        --group Collaborators \
	        --file "${ipaPath}" \
	        --release-notes 'App submission via Codemagic' \
	        --app $APPCENTER_USERNAME/$IOS_APPCENTER_IDENTIFIER \
	        --token "${APP_CENTER_TOKEN_IOS}" \
	        --quiet
	fi
}

publish_android(){
	# Publishing APK to AppCenter
	apkPath=$(find build -name "*.apk" | head -1)
	echo "Found apk at $apkPath"
	
	if [[ -z ${apkPath} ]]
	then
	    echo "No APKs were found, skip publishing to App Center 💥"
	else
	    echo "Publishing APK to App Center 🚀"
	    appcenter distribute release \
	        --group Collaborators \
	        --file "${apkPath}" \
	        --release-notes 'App submission via Codemagic' \
	        --app $APPCENTER_USERNAME/$ANDROID_APPCENTER_IDENTIFIER \
	        --token "${APP_CENTER_TOKEN_ANDROID}" \
	        --quiet
	fi
}


build_android &
build_ios &
wait

publish_ios &
publish_android &
wait
