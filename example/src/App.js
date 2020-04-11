/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

import React from 'react';
import {
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  StatusBar,
  Switch,
  NativeModules,
  NativeEventEmitter,
  DeviceEventEmitter,
} from 'react-native';

import {Colors} from 'react-native/Libraries/NewAppScreen';
import {requestLocationPermission} from './Permission';
import {setUserId, getUserId} from './User';
import 'react-native-get-random-values';
import {nanoid} from 'nanoid';

const eventEmitter = new NativeEventEmitter(NativeModules.ContactTracerModule);

class App extends React.Component {
  constructor() {
    super();
    this.state = {
      userId: '',
      serviceEnabled: false,
      statusText: '',
    };
  }

  componentDidMount() {
    getUserId()
      .then((userId) => {
        if (userId == null) {
          // User ID not existed, generate a new one
          // User ID maximum length is 20
          userId = nanoid().substr(0, 20);
          // Save generated ID
          setUserId(userId).then(() => {});
        }
        this.setState({userId: userId});
        return userId;
      })
      .then((userId) => {
        this.initializeContactTracer(userId);
      });

    // Register for event from Native code
    this.registerListeners();

    this.appendStatusText('Welcome to Contact Tracer Example');
  }

  componentWillUnmount() {
    // Unegister for event from Native code
    this.unregisterListeners();
  }

  /******************
   * Initialization *
   ******************/

  // Initialize Contact Tracer
  async initializeContactTracer(anonymousId) {
    // Set User ID in native level for furthur use
    NativeModules.ContactTracerModule.setUserId(
      anonymousId,
    ).then((anonymousId) => {});

    // Check if Tracer Service has been enabled
    NativeModules.ContactTracerModule.isTracerServiceEnabled()
      .then((enabled) => {
        this.setState({
          serviceEnabled: enabled,
        });
        // Refresh Tracer Service Status in case the service is down
        // to make sure Service is started again
        NativeModules.ContactTracerModule.refreshTracerServiceStatus();
      })
      .then(() => {});

    // Check if BLE is available
    await NativeModules.ContactTracerModule.initialize()
      .then((result) => {
        return NativeModules.ContactTracerModule.isBLEAvailable();
      })
      // For NativeModules.ContactTracerModule.isBLEAvailable()
      .then((isBLEAvailable) => {
        if (isBLEAvailable) {
          this.appendStatusText('BLE is available');
          // BLE is available, continue requesting Location Permission
          return requestLocationPermission();
        } else {
          // BLE is not available, don't do anything furthur since BLE is required
          this.appendStatusText('BLE is NOT available');
        }
      })
      // For requestLocationPermission()
      .then((locationPermissionGranted) => {
        this.setState({
          isLocationPermissionGranted: locationPermissionGranted,
        });
        if (locationPermissionGranted) {
          // Location permission is granted, try turning on Bluetooth now
          this.appendStatusText('Location permission is granted');
          return NativeModules.ContactTracerModule.tryToTurnBluetoothOn();
        } else {
          // Location permission is required, we cannot continue working without this permission
          this.appendStatusText('Location permission is NOT granted');
        }
      })
      // For NativeModules.ContactTracerModule.tryToTurnBluetoothOn()
      .then((bluetoothOn) => {
        this.setState({
          isBluetoothOn: bluetoothOn,
        });

        if (bluetoothOn) {
          this.appendStatusText('Bluetooth is On');
          // See if Multiple Advertisement is supported
          // Refresh Tracer Service Status in case the service is down
          NativeModules.ContactTracerModule.refreshTracerServiceStatus();
          return NativeModules.ContactTracerModule.isMultipleAdvertisementSupported();
        } else {
          this.appendStatusText('Bluetooth is Off');
        }
      })
      // For NativeModules.ContactTracerModule.isMultipleAdvertisementSupported()
      .then((supported) => {
        if (supported)
          this.appendStatusText('Mulitple Advertisement is supported');
        else this.appendStatusText('Mulitple Advertisement is NOT supported');
      });

    return '';
  }

  /**
   * Initialize Listeners
   */

  registerListeners() {
    // Register Event Emitter
    if (Platform.OS == 'ios') {
      console.log('add listener');
      this.advertiserEventSubscription = eventEmitter.addListener(
        'AdvertiserMessage',
        this.onAdvertiserMessageReceived,
      );

      this.nearbyDeviceFoundEventSubscription = eventEmitter.addListener(
        'NearbyDeviceFound',
        this.onNearbyDeviceFoundReceived,
      );
    } else {
      console.log('add listener');
      this.advertiserEventSubscription = DeviceEventEmitter.addListener(
        'AdvertiserMessage',
        this.onAdvertiserMessageReceived,
      );

      this.nearbyDeviceFoundEventSubscription = DeviceEventEmitter.addListener(
        'NearbyDeviceFound',
        this.onNearbyDeviceFoundReceived,
      );
    }
  }

  /**
   * Destroy Listeners
   */
  unregisterListeners() {
    // Unregister Event Emitter
    if (this.advertiserEventSubscription != null) {
      this.advertiserEventSubscription.remove();
      this.advertiserEventSubscription = null;
    }
    if (this.nearbyDeviceFoundEventSubscription != null) {
      this.nearbyDeviceFoundEventSubscription.remove();
      this.nearbyDeviceFoundEventSubscription = null;
    }
  }

  /**************************
   * Event Emitting Handler *
   **************************/

  onAdvertiserMessageReceived = (e) => {
    this.appendStatusText(e['message']);
  };

  onNearbyDeviceFoundReceived = (e) => {
    this.appendStatusText('');
    this.appendStatusText('***** RSSI: ' + e['rssi']);
    this.appendStatusText('***** Found Nearby Device: ' + e['name']);
    this.appendStatusText('');
  };

  /*********
   * Utils *
   *********/

  appendStatusText(text) {
    this.setState({statusText: text + '\n' + this.state.statusText});
  }

  /******************
   * Event Handling *
   ******************/

  onServiceCheckBoxChanged() {
    if (this.state.serviceEnabled) {
      // To Disable
      NativeModules.ContactTracerModule.disableTracerService();
    } else {
      // To Enable
      NativeModules.ContactTracerModule.enableTracerService();
    }
    this.setState({serviceEnabled: !this.state.serviceEnabled});
  }

  render() {
    return (
      <>
        <StatusBar barStyle="dark-content" />
        <SafeAreaView>
          <View>
            <View style={styles.headerArea}>
              <Text style={styles.mediumText}>
                User ID:{' '}
                <Text style={styles.highlight}>{this.state.userId}</Text>
              </Text>
              <View style={styles.serviceCheckBoxArea}>
                <Text style={styles.mediumText}>Service:</Text>
                <Switch
                  value={this.state.serviceEnabled}
                  disabled={!this.state.isLocationPermissionGranted}
                  onValueChange={() => this.onServiceCheckBoxChanged()}
                />
              </View>
            </View>
          </View>
          <ScrollView
            contentInsetAdjustmentBehavior="automatic"
            style={styles.scrollView}>
            <View style={styles.statusTextArea}>
              <Text style={styles.statusText}>{this.state.statusText}</Text>
            </View>
          </ScrollView>
        </SafeAreaView>
      </>
    );
  }
}

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: Colors.white,
  },
  headerArea: {
    marginTop: 32,
    marginBottom: 24,
    paddingHorizontal: 24,
  },
  mediumText: {
    fontSize: 18,
    fontWeight: '400',
    color: Colors.dark,
  },
  serviceCheckBoxArea: {
    flexDirection: 'row',
    fontSize: 16,
    marginTop: 12,
  },
  statusTextArea: {
    padding: 24,
  },
  statusText: {
    fontSize: 16,
    color: Colors.black,
  },
  scanButton: {
    height: 24,
  },
  highlight: {
    fontWeight: '700',
  },
});

export default App;
