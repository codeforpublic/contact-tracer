//
//  ContactTracerModule.m
//  ContactTracerReact
//
//  Created by Sittiphol Phanvilai on 31/3/2563 BE.
//

#import "ContactTracerModule.h"

#import "React/RCTBridgeModule.h"
#import <React/RCTEventEmitter.h>

@import CoreBluetooth;
@import CoreLocation;                  //Added by Urng 20200712

@implementation ContactTracerModule {
    CBCentralManager* centralManager;
    CBPeripheralManager* peripheralManager;
    RCTPromiseResolveBlock bluetoothOnResolve;
    CLLocationManager* locationManager;//Added by Urng 20200712
    BOOL isBluetoothOn;
    
    CBUUID* cbuuid;
    CBUUID* kDataClass;
    
    NSUUID *beaconuuid;               //Added by Urng 20200712
    NSString *beaconID;               //Added by Urng 20200712
    CLBeaconRegion *beaconRegion;     //Added by Urng 20200712
}

RCT_EXPORT_MODULE()

// Constructor
- (id) init {
    self = [super init];
    
    centralManager = nil;
    peripheralManager = nil;
    locationManager = nil;                                    //Added by Urng 20200712
    
    NSString *bluetoothUUID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"contact_tracer_bluetooth_uuid"];
    NSString *beaconUUID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"beacon_uuid"];
    if (bluetoothUUID == nil)
        bluetoothUUID = @"00008FFF-0000-1000-8000-00805f9b34fc";
        
    if (beaconUUID == nil) {                                  //Added by Urng 20200712
        beaconUUID = @"26600EFA-ED3D-971A-3676-295C85BE6CE5"; //Added by Urng 20200712
        beaconID = @"morchana.in.th";                         //Added by Urng 20200712
    }                                                         //Added by Urng 20200712
        
    NSString *bluetoothDataClass = [[bluetoothUUID substringWithRange:NSMakeRange(4, 4)] uppercaseString];

    cbuuid = [CBUUID UUIDWithString:bluetoothUUID];
    beaconuuid = [[NSUUID alloc] initWithUUIDString:beaconUUID];            //Added by Urng 20200712
    
    kDataClass = [CBUUID UUIDWithString:bluetoothDataClass];

    isBluetoothOn = false;
    
    beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconuuid //Added by Urng 20200712
                                        identifier:beaconID];               //Added by Urng 20200712
    
    
    return self;
}

// Declare Events that can be sent to JS
- (NSArray<NSString *> *)supportedEvents
{
    return @[@"AdvertiserMessage", @"NearbyDeviceFound",@"NearbyBeaconFound"];
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_METHOD(initialize: (RCTPromiseResolveBlock)resolve
                    rejecter: (RCTPromiseRejectBlock)reject)
{
    bool pendingCallback = false;
    
    bluetoothOnResolve = resolve;
    if (centralManager == nil) {
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
        // Callback will be called in centralManager delegate
        pendingCallback = true;
    }
    if (peripheralManager == nil) {
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    
    // Resolve now since there would be no delegate called
    if (!pendingCallback)
        resolve(@(true));
        
    if (locationManager == nil) {                                             //Added by Urng 20200712
        __strong typeof(self) strongSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
           // do work here
            strongSelf->locationManager = [[CLLocationManager alloc] init];   //Added by Urng 20200712
            strongSelf->locationManager.delegate = strongSelf;                //Added by Urng 20200712
            if ([strongSelf->locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])  //Added by Urng 20200712
            {
              //[locationManager requestWhenInUseAuthorization];              //Added by Urng 20200712
              [strongSelf->locationManager requestAlwaysAuthorization];       //Added by Urng 20200712
            }
            
            
            // Callback will be called in locationManager delegate            //Added by Urng 20200712
            //pendingCallback = true;  //Added by Urng 20200712
        });
    }
    
    // Resolve now since there would be no delegate called                    //Added by Urng 20200712
    if (!pendingCallback)                                                     //Added by Urng 20200712
        resolve(@(true));                                                     //Added by Urng 20200712
        
}

RCT_EXPORT_METHOD(isTracerServiceEnabled: (RCTPromiseResolveBlock)resolve
                                rejecter: (RCTPromiseRejectBlock)reject)
{
    BOOL result = [self _isTracerServiceEnabled];
    resolve(@(result));
}

- (void)_setTracerServiceEnabled: (BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:@"tracerServiceEnabled"];
}

- (BOOL)_isTracerServiceEnabled {
    BOOL tracerServiceEnabled = [NSUserDefaults.standardUserDefaults boolForKey:@"tracerServiceEnabled"];
    return tracerServiceEnabled;
}

RCT_EXPORT_METHOD(enableTracerService: (RCTPromiseResolveBlock)resolve
                             rejecter: (RCTPromiseRejectBlock)reject)
{
    [self emitAdvertiserMessage:@"Enabling Tracer Service"];
    [self _setTracerServiceEnabled:true];
    [self startScanning];
    [self startAdvertising];
    resolve(@(true));
}

RCT_EXPORT_METHOD(disableTracerService: (RCTPromiseResolveBlock)resolve
                              rejecter: (RCTPromiseRejectBlock)reject)
{
    [self emitAdvertiserMessage:@"Disabling Tracer Service"];
    [self _setTracerServiceEnabled:false];
    [self stopScanning];
    [self stopAdvertising];
    resolve(@(true));
}

- (void) _refreshTracerServiceStatus
{
    if ([self _isTracerServiceEnabled]) {
        [self startScanning];
        [self startAdvertising];
    } else {
        [self stopScanning];
        [self stopAdvertising];
    }
}

RCT_EXPORT_METHOD(refreshTracerServiceStatus: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    [self _refreshTracerServiceStatus];
    BOOL result = [self _isTracerServiceEnabled];
    resolve(@(result));
}

RCT_EXPORT_METHOD(stopTracerService: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    [self stopScanning];
    [self stopAdvertising];
}

RCT_EXPORT_METHOD(isBLEAvailable: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    resolve(@(true));
}

RCT_EXPORT_METHOD(isMultipleAdvertisementSupported: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    resolve(@(true));
}

RCT_EXPORT_METHOD(isBluetoothTurnedOn: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    resolve(@(isBluetoothOn));
}

RCT_EXPORT_METHOD(tryToTurnBluetoothOn: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    resolve(@(true));
}

RCT_EXPORT_METHOD(setUserId: (NSString*)userId
                  resolver: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"userId"];
    resolve(userId);
}

RCT_EXPORT_METHOD(getUserId: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject)
{
    resolve([self _getUserId]);
}

- (NSString*) _getUserId {
    NSString* userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"userId"];
    if (userId == nil)
        return @"NOIDIOS";
    return userId;
}

// Delegate

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (@available(iOS 10.0, *)) {
        if (central.state == CBManagerStatePoweredOn) {
            NSLog(@"Bluetooth is On");
            [self emitAdvertiserMessage:@"Bluetooth is On. You can start scanning now."];
            bluetoothOnResolve(@(true));
        } else {
            NSLog(@"Bluetooth is not active");
            [self emitAdvertiserMessage:@"Bluetooth is not active. Scanning function is disabled."];
            bluetoothOnResolve(@(false));
        }
    } else {
        // Fallback on earlier versions
    }
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSDictionary* adData = [advertisementData objectForKey:@"kCBAdvDataServiceData"];
    if (adData == nil)
        return;
    
    NSString* nearbyDeviceUserId;
    
    NSData* data = [adData objectForKey:kDataClass];
    if (data == nil) {
        nearbyDeviceUserId = [peripheral name];
    } else {
        nearbyDeviceUserId = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    [self emitNearbyDeviceFound:nearbyDeviceUserId rssi:[RSSI stringValue]];
    
    NSLog(@"nFound Nearby Device: %@", nearbyDeviceUserId);
    NSLog(@"RSSI: %@", [RSSI stringValue]);
}

- (void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    switch (peripheral.state) {
        case CBManagerStateUnknown:
            NSLog(@"Bluetooth Device is UNKNOWN");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"Bluetooth Device is UNSUPPORTED");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"Bluetooth Device is UNAUTHORIZED");
            break;
        case CBManagerStateResetting:
            NSLog(@"Bluetooth Device is RESETTING");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Bluetooth Device is POWERED OFF");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@"Bluetooth Device is POWERED ON");
            isBluetoothOn = true;
            [self emitAdvertiserMessage:@"Bluetooth Device is POWERED ON. You can start advertising now."];
            break;
        default:
            NSLog(@"Unknown State");
            break;
    }
}


- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region  //Added by Urng 20200712
{
    NSLog(@"Enter Beacon Region!");
    [locationManager startRangingBeaconsInRegion:beaconRegion];
    [locationManager stopRangingBeaconsInRegion:beaconRegion];
}
 
-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region  //Added by Urng 20200712
{
    [locationManager stopRangingBeaconsInRegion:beaconRegion];
    NSLog(@"Exit Beacon Region!");
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region  withError:(NSError *)error //Added by Urng 20200712
{
//    NSLog(@"RangingBeaconsDidFailForRegion: %@", region);
//    NSLog(@"error: %@", error);
}

-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region //Added by Urng 20200712
{
    // Beacon found!

    NSLog(@"Beacon Found!");
    for (CLBeacon *foundBeacon in beacons) {
        NSString *uuid = foundBeacon.proximityUUID.UUIDString;
        NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
        NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
        NSLog(@"uuid: %@", uuid);
        NSLog(@"major: %@", major);
        NSLog(@"minor: %@", minor);

        [self emitNearbyBeaconFound: uuid major: major  mainor: minor ];
    }    
    NSLog(@"------------------------------------");
}

// Advertiser

- (void) startAdvertising
{
    if (peripheralManager == nil)
        return;
    
    NSString* userId = [self _getUserId];
    
    [peripheralManager startAdvertising:@{
        CBAdvertisementDataLocalNameKey: userId,
        CBAdvertisementDataServiceUUIDsKey: @[cbuuid]
    }];
    NSLog(@"Started Advertising");
    [self emitAdvertiserMessage:@"Starting Advertising"];
}

- (void) stopAdvertising
{
    if (peripheralManager == nil)
        return;
    [peripheralManager stopAdvertising];
    NSLog(@"Stop Advertising");
    [self emitAdvertiserMessage:@"Stopping Advertising"];
}

// Scanner

- (void) startScanning
{
    if (centralManager == nil)
        return;
    [self emitAdvertiserMessage:@"Start Scanning for Nearby Device\n"];
    [centralManager scanForPeripheralsWithServices:@[cbuuid] options:nil];
    
    if (locationManager == nil)  //Added by Urng 20200712
        return;                  //Added by Urng 20200712
    NSLog(@"Start Scanning Beacon");  //Added by Urng 20200712
    [locationManager startRangingBeaconsInRegion:beaconRegion];  //Added by Urng 20200712
}

- (void) stopScanning
{
    if (centralManager == nil)
        return;
    [self emitAdvertiserMessage:@"Stop Scanning for Nearby Device\n"];
    [centralManager stopScan];
    
    if (locationManager == nil)  //Added by Urng 20200712
        return;                  //Added by Urng 20200712
    NSLog(@"Stop Scanning Beacon"); //Added by Urng 20200712
    [locationManager stopRangingBeaconsInRegion:beaconRegion];  //Added by Urng 20200712
    
}

// Event

- (void) emitAdvertiserMessage: (NSString*)message
{
    [self sendEventWithName:@"AdvertiserMessage" body:@{@"message": message}];
}

- (void) emitNearbyDeviceFound: (NSString*)name rssi: (NSString*)rssi
{
    [self sendEventWithName:@"NearbyDeviceFound" body:@{@"name": name, @"rssi": rssi}];
}

- (void) emitNearbyBeaconFound: (NSString*)uuid major: (NSString*)major  mainor: (NSString*)minor  //Added by Urng 20200712
{
    [self sendEventWithName:@"NearbyBeaconFound" body:@{@"uuid": uuid, @"major": major, @"minor": minor}];
}

@end
