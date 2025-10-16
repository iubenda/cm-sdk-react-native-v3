import { NativeModules, Platform, NativeEventEmitter } from 'react-native';
import NativeCmSdkReactNativeV3 from './NativeCmSdkReactNativeV3';

const LINKING_ERROR =
  `The package 'react-native-cm-sdk-react-native-v3' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

// Use TurboModule if available (New Architecture), fallback to legacy NativeModules
const CmSdkReactNativeV3 = NativeCmSdkReactNativeV3 ?? (NativeModules.CmSdkReactNativeV3
  ? NativeModules.CmSdkReactNativeV3
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    ));

const eventEmitter = new NativeEventEmitter(CmSdkReactNativeV3);

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

export const addClickLinkListener = (callback: (url: string) => void) => {
  return eventEmitter.addListener('onClickLink', (event) => {
    callback(event.url);
  });
};

// Core configuration methods
export const setUrlConfig = CmSdkReactNativeV3.setUrlConfig;
export const setWebViewConfig = CmSdkReactNativeV3.setWebViewConfig;
export const setATTStatus = CmSdkReactNativeV3.setATTStatus;

// Main interaction methods
export const checkAndOpen = CmSdkReactNativeV3.checkAndOpen;
export const forceOpen = CmSdkReactNativeV3.forceOpen;

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

export default CmSdkReactNativeV3;
