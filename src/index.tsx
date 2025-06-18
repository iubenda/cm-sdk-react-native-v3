import { NativeModules, Platform, NativeEventEmitter, DeviceEventEmitter } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-cm-sdk-react-native-v3' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CmSdkReactNativeV3 = NativeModules.CmSdkReactNativeV3
  ? NativeModules.CmSdkReactNativeV3
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

const isIOS = Platform.OS === 'ios';
const eventEmitter = isIOS ? new NativeEventEmitter(CmSdkReactNativeV3) : DeviceEventEmitter;

export const addConsentListener = (
  callback: (consent: string, jsonObject: any) => void
) => {
  return eventEmitter.addListener('didReceiveConsent', (event) => {
    callback(event.consent, event.jsonObject);
  });
};

export const addShowConsentLayerListener = (callback: () => void) => {
  return eventEmitter.addListener('didShowConsentLayer', callback);
};

export const addCloseConsentLayerListener = (callback: () => void) => {
  return eventEmitter.addListener('didCloseConsentLayer', callback);
};

export const addErrorListener = (callback: (error: string) => void) => {
  return eventEmitter.addListener('didReceiveError', (event) => {
    callback(event.error);
  });
};

// Core configuration methods
export const setUrlConfig = CmSdkReactNativeV3.setUrlConfig;
export const setWebViewConfig = CmSdkReactNativeV3.setWebViewConfig;

// Main interaction methods (new API)
export const checkAndOpen = CmSdkReactNativeV3.checkAndOpen;
export const forceOpen = CmSdkReactNativeV3.forceOpen;
export const jumpToSettings = CmSdkReactNativeV3.jumpToSettings;

// Consent status methods
export const getUserStatus = CmSdkReactNativeV3.getUserStatus;
export const getStatusForPurpose = CmSdkReactNativeV3.getStatusForPurpose;
export const getStatusForVendor = CmSdkReactNativeV3.getStatusForVendor;
export const getGoogleConsentModeStatus = CmSdkReactNativeV3.getGoogleConsentModeStatus;
export const exportCMPInfo = CmSdkReactNativeV3.exportCMPInfo;
export const importCMPInfo = CmSdkReactNativeV3.importCMPInfo;
export const resetConsentManagementData = CmSdkReactNativeV3.resetConsentManagementData;

// Consent modification methods
export const acceptVendors = CmSdkReactNativeV3.acceptVendors;
export const rejectVendors = CmSdkReactNativeV3.rejectVendors;
export const acceptPurposes = CmSdkReactNativeV3.acceptPurposes;
export const rejectPurposes = CmSdkReactNativeV3.rejectPurposes;
export const rejectAll = CmSdkReactNativeV3.rejectAll;
export const acceptAll = CmSdkReactNativeV3.acceptAll;

// Deprecated methods (kept for backward compatibility)
export const checkWithServerAndOpenIfNecessary = CmSdkReactNativeV3.checkWithServerAndOpenIfNecessary;
export const openConsentLayer = CmSdkReactNativeV3.openConsentLayer;
export const checkIfConsentIsRequired = CmSdkReactNativeV3.checkIfConsentIsRequired;
export const hasUserChoice = CmSdkReactNativeV3.hasUserChoice;
export const hasPurposeConsent = CmSdkReactNativeV3.hasPurposeConsent;
export const hasVendorConsent = CmSdkReactNativeV3.hasVendorConsent;
export const getAllPurposesIDs = CmSdkReactNativeV3.getAllPurposesIDs;
export const getEnabledPurposesIDs = CmSdkReactNativeV3.getEnabledPurposesIDs;
export const getDisabledPurposesIDs = CmSdkReactNativeV3.getDisabledPurposesIDs;
export const getAllVendorsIDs = CmSdkReactNativeV3.getAllVendorsIDs;
export const getEnabledVendorsIDs = CmSdkReactNativeV3.getEnabledVendorsIDs;
export const getDisabledVendorsIDs = CmSdkReactNativeV3.getDisabledVendorsIDs;

export default CmSdkReactNativeV3;
