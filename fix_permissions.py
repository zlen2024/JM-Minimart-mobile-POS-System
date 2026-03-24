import re

# Android
with open('android/app/src/main/AndroidManifest.xml', 'r') as f:
    android = f.read()

if '<uses-permission android:name="android.permission.CAMERA"/>' not in android:
    android = android.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
                              '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.CAMERA"/>')
    with open('android/app/src/main/AndroidManifest.xml', 'w') as f:
        f.write(android)

# iOS
import plistlib
import os

if os.path.exists('ios/Runner/Info.plist'):
    with open('ios/Runner/Info.plist', 'rb') as f:
        plist = plistlib.load(f)

    plist['NSCameraUsageDescription'] = "This app requires camera access to scan barcodes for point of sale transactions."

    with open('ios/Runner/Info.plist', 'wb') as f:
        plistlib.dump(plist, f)
else:
    print("Warning: ios/Runner/Info.plist not found.")
