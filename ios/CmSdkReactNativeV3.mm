#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(CmSdkReactNativeV3, RCTEventEmitter)

// Event emitter methods
RCT_EXTERN_METHOD(supportedEvents)

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

// Legacy methods
RCT_EXTERN_METHOD(checkWithServerAndOpenIfNecessary:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(openConsentLayer:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(jumpToSettings:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(checkIfConsentIsRequired:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

// Consent status methods
RCT_EXTERN_METHOD(hasUserChoice:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(hasPurposeConsent:(NSString *)purposeId
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(hasVendorConsent:(NSString *)vendorId
        withResolver:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(exportCMPInfo:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

// Purpose and vendor methods
RCT_EXTERN_METHOD(getAllPurposesIDs:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getEnabledPurposesIDs:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getDisabledPurposesIDs:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getAllVendorsIDs:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getEnabledVendorsIDs:(RCTPromiseResolveBlock)resolve
        withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getDisabledVendorsIDs:(RCTPromiseResolveBlock)resolve
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

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
