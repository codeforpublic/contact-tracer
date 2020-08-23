#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

#import <React/RCTEventEmitter.h>

@import CoreBluetooth;
@import CoreLocation; //Added by Urng 20200712

@interface ContactTracerModule : RCTEventEmitter <RCTBridgeModule, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@end
