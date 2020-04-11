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

@implementation ContactTracerModule {
    CBCentralManager* centralManager;
    CBPeripheralManager* peripheralManager;
    RCTPromiseResolveBlock bluetoothOnResolve;
    BOOL isBluetoothOn;
    
    CBUUID* cbuuid;
    CBUUID* kDataClass;
}

RCT_EXPORT_MODULE()

// Constructor
- (id) init {
    self = [super init];
    
    centralManager = nil;
    peripheralManager = nil;
    
    NSString *bluetoothUUID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"contact_tracer_bluetooth_uuid"];
    if (bluetoothUUID == nil)
        bluetoothUUID = @"000086e0-0000-1000-8000-00805f9b34fb";
    
    NSString *bluetoothDataClass = [bluetoothUUID substringWithRange:NSMakeRange(4, 4)];

    cbuuid = [CBUUID UUIDWithString:bluetoothUUID];
    kDataClass = [CBUUID UUIDWithString:bluetoothDataClass];

    isBluetoothOn = false;
    
    return self;
}

// Declare Events that can be sent to JS
- (NSArray<NSString *> *)supportedEvents
{
    return @[@"AdvertiserMessage", @"NearbyDeviceFound"];
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
}

- (void) stopScanning
{
    if (centralManager == nil)
        return;
    [self emitAdvertiserMessage:@"Stop Scanning for Nearby Device\n"];
    [centralManager stopScan];
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

@end
