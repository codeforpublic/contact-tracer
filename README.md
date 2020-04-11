# Contact Tracer for React Native (iOS and Android)

React Native module to scan for nearby device using Bluetooth Low Energy for iOS and Android

# Installation

```
npm install react-native-contact-tracer --save
```

# Declare Bluetooth UUID for your service

The unique Bluetooth service UUID is required and it also has to be in the following format:

```
0000XXXX-0000-1000-8000-00805f9b34fb
```

Replace XXXX with your any preferred ID.

On Android, add the following line to `res/value/strings.xml`

```
<string name="contact_tracer_bluetooth_uuid">0000XXXX-0000-1000-8000-00805f9b34fb</string>
```

On iOS, Add `contact_tracer_bluetooth_uuid` key in Info.plist with the preffered UUID as value.

```
	<key>contact_tracer_bluetooth_uuid</key>
	<string>0000XXXX-0000-1000-8000-00805f9b34fb</string>
```

# To run the example

Example is already embedded in this repo. To run example, simply do the following:

```
cd example
npm install
```

for Android, run the following command.

```
npx react-native run-android
```

for iOS, you need to install Pod first by.

```
cd ios
pod install
cd ..
npx react-native run-ios
```
