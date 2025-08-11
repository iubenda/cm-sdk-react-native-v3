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
export interface UrlConfig {
  id: string;
  domain: string;
  language: string;
  appName: string;
}

export const setUrlConfig = (config: UrlConfig): Promise<void> => {
  return CmSdkReactNativeV3.setUrlConfig(config);
};

export interface WebViewConfig {
  position?: 'fullScreen' | 'halfScreenBottom' | 'halfScreenTop';
  cornerRadius?: number;
  respectsSafeArea?: boolean;
  allowsOrientationChanges?: boolean;
}

export const setWebViewConfig: (config: WebViewConfig) => Promise<void> = (
  config
) => {
  return CmSdkReactNativeV3.setWebViewConfig(config);
};

// Main interaction methods (new API)
export const checkAndOpen = (jumpToSettings: boolean): Promise<boolean> => {
  return CmSdkReactNativeV3.checkAndOpen(jumpToSettings);
};

export const forceOpen = (jumpToSettings: boolean): Promise<boolean> => {
  return CmSdkReactNativeV3.forceOpen(jumpToSettings);
};

export const jumpToSettings = (): Promise<boolean> => {
  return CmSdkReactNativeV3.jumpToSettings();
};

// Consent status methods
export interface UserStatus {
  hasUserChoice: string;
  tcf: string;
  addtlConsent: string;
  regulation: string;
  vendors: Record<string, string>;
  purposes: Record<string, string>;
}

export const getUserStatus = (): Promise<UserStatus> => {
  return CmSdkReactNativeV3.getUserStatus();
};

export const getStatusForPurpose = (purposeId: string): Promise<string> => {
  return CmSdkReactNativeV3.getStatusForPurpose(purposeId);
};

export const getStatusForVendor = (vendorId: string): Promise<string> => {
  return CmSdkReactNativeV3.getStatusForVendor(vendorId);
};

export enum ConsentType {
  ANALYTICS_STORAGE = 'analytics_storage',
  AD_STORAGE = 'ad_storage',
  AD_USER_DATA = 'ad_user_data',
  AD_PERSONALIZATION = 'ad_personalization',
}

export enum ConsentModeStatus {
  GRANTED = 'granted',
  DENIED = 'denied',
}

export const getGoogleConsentModeStatus = (): Promise<
  Record<ConsentType, ConsentModeStatus>
> => {
  return CmSdkReactNativeV3.getGoogleConsentModeStatus();
};

export const exportCMPInfo = (): Promise<string> => {
  return CmSdkReactNativeV3.exportCMPInfo();
};

export const importCMPInfo = (cmpString: string): Promise<boolean> => {
  return CmSdkReactNativeV3.importCMPInfo(cmpString);
};

export const resetConsentManagementData = (): Promise<boolean> => {
  return CmSdkReactNativeV3.resetConsentManagementData();
};

// Consent modification methods
export const acceptVendors = (vendors: string[]): Promise<void> => {
  return CmSdkReactNativeV3.acceptVendors(vendors);
};

export const rejectVendors = (vendors: string[]): Promise<void> => {
  return CmSdkReactNativeV3.rejectVendors(vendors);
};

export const acceptPurposes = (
  purposes: string[],
  updatePurpose: boolean
): Promise<void> => {
  return CmSdkReactNativeV3.acceptPurposes(purposes, updatePurpose);
};

export const rejectPurposes = (
  purposes: string[],
  updateVendor: boolean
): Promise<void> => {
  return CmSdkReactNativeV3.rejectPurposes(purposes, updateVendor);
};

export const rejectAll = (): Promise<void> => {
  return CmSdkReactNativeV3.rejectAll();
};

export const acceptAll = (): Promise<void> => {
  return CmSdkReactNativeV3.acceptAll();
};

// Deprecated methods (kept for backward compatibility)
export const checkWithServerAndOpenIfNecessary = (): Promise<boolean> => {
  return CmSdkReactNativeV3.checkWithServerAndOpenIfNecessary();
};

export const openConsentLayer = (): Promise<boolean> => {
  return CmSdkReactNativeV3.openConsentLayer();
};

export const checkIfConsentIsRequired = (): Promise<boolean> => {
  return CmSdkReactNativeV3.checkIfConsentIsRequired();
};

// Status checking methods
export const hasUserChoice = (): Promise<boolean> => {
  return CmSdkReactNativeV3.hasUserChoice();
};

export const hasPurposeConsent = (purposeId: string): Promise<boolean> => {
  return CmSdkReactNativeV3.hasPurposeConsent(purposeId);
};

export const hasVendorConsent = (vendorId: string): Promise<boolean> => {
  return CmSdkReactNativeV3.hasVendorConsent(vendorId);
};

// ID retrieval methods
export const getAllPurposesIDs = (): Promise<string[]> => {
  return CmSdkReactNativeV3.getAllPurposesIDs();
};

export const getEnabledPurposesIDs = (): Promise<string[]> => {
  return CmSdkReactNativeV3.getEnabledPurposesIDs();
};

export const getDisabledPurposesIDs = (): Promise<string[]> => {
  return CmSdkReactNativeV3.getDisabledPurposesIDs();
};

export const getAllVendorsIDs = (): Promise<string[]> => {
  return CmSdkReactNativeV3.getAllVendorsIDs();
};

export const getEnabledVendorsIDs = (): Promise<string[]> => {
  return CmSdkReactNativeV3.getEnabledVendorsIDs();
};

export const getDisabledVendorsIDs = (): Promise<string[]> => {
  return CmSdkReactNativeV3.getDisabledVendorsIDs();
};

export default CmSdkReactNativeV3;
