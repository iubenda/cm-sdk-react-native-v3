#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// Swift method declarations - bridges Swift methods to Objective-C
@interface RCT_EXTERN_MODULE(CmSdkReactNativeV3, RCTEventEmitter)

// Core methods
RCT_EXTERN_METHOD(setUrlConfig:(NSDictionary *)config
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setWebViewConfig:(NSDictionary *)config
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setATTStatus:(double)status
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

// Main methods
RCT_EXTERN_METHOD(checkAndOpen:(BOOL)jumpToSettings
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(forceOpen:(BOOL)jumpToSettings
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserStatus:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(isConsentRequired:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getStatusForPurpose:(NSString *)purposeId
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getStatusForVendor:(NSString *)vendorId
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getGoogleConsentModeStatus:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(exportCMPInfo:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

// Consent modification methods
RCT_EXTERN_METHOD(acceptVendors:(NSArray *)vendors
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rejectVendors:(NSArray *)vendors
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(acceptPurposes:(NSArray *)purposes
        updatePurpose:(BOOL)updatePurpose
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rejectPurposes:(NSArray *)purposes
        updateVendor:(BOOL)updateVendor
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rejectAll:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(acceptAll:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(importCMPInfo:(NSString *)cmpString
        resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(resetConsentManagementData:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject)

// Event emitter support methods
RCT_EXTERN_METHOD(addListener:(NSString *)eventName)
RCT_EXTERN_METHOD(removeListeners:(double)count)

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
