#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(CmSdkReactNativeV3, RCTEventEmitter)

// Core methods
RCT_EXTERN_METHOD(setUrlConfig:(NSDictionary *)config
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setWebViewConfig:(NSDictionary *)config
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setATTStatus:(NSInteger)status
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

// New methods
RCT_EXTERN_METHOD(checkAndOpen:(BOOL)jumpToSettings
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(forceOpen:(BOOL)jumpToSettings
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserStatus:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getStatusForPurpose:(NSString *)purposeId
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getStatusForVendor:(NSString *)vendorId
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getGoogleConsentModeStatus:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(exportCMPInfo:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

// Consent modification methods
RCT_EXTERN_METHOD(acceptVendors:(NSArray *)vendors
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rejectVendors:(NSArray *)vendors
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(acceptPurposes:(NSArray *)purposes
        updatePurpose:(BOOL)updatePurpose
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rejectPurposes:(NSArray *)purposes
        updateVendor:(BOOL)updateVendor
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(rejectAll:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(acceptAll:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(importCMPInfo:(NSString *)cmpString
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(resetConsentManagementData:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

// Event emitter support methods (required for TurboModule)
RCT_EXTERN_METHOD(addListener:(NSString *)eventName)
RCT_EXTERN_METHOD(removeListeners:(double)count)

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
