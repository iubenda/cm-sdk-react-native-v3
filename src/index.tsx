import { NativeModules, Platform } from 'react-native';

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

export const setUrlConfig = CmSdkReactNativeV3.setUrlConfig;
export const setWebViewConfig = CmSdkReactNativeV3.setWebViewConfig;
export const checkWithServerAndOpenIfNecessary =
  CmSdkReactNativeV3.checkWithServerAndOpenIfNecessary;
export const openConsentLayer = CmSdkReactNativeV3.openConsentLayer;
export const jumpToSettings = CmSdkReactNativeV3.jumpToSettings;
export const checkIfConsentIsRequired =
  CmSdkReactNativeV3.checkIfConsentIsRequired;
export const hasUserChoice = CmSdkReactNativeV3.hasUserChoice;
export const hasPurposeConsent = CmSdkReactNativeV3.hasPurposeConsent;
export const hasVendorConsent = CmSdkReactNativeV3.hasVendorConsent;
export const exportCMPInfo = CmSdkReactNativeV3.exportCMPInfo;
export const getAllPurposesIDs = CmSdkReactNativeV3.getAllPurposesIDs;
export const getEnabledPurposesIDs = CmSdkReactNativeV3.getEnabledPurposesIDs;
export const getDisabledPurposesIDs = CmSdkReactNativeV3.getDisabledPurposesIDs;
export const getAllVendorsIDs = CmSdkReactNativeV3.getAllVendorsIDs;
export const getEnabledVendorsIDs = CmSdkReactNativeV3.getEnabledVendorsIDs;
export const getDisabledVendorsIDs = CmSdkReactNativeV3.getDisabledVendorsIDs;
export const acceptVendors = CmSdkReactNativeV3.acceptVendors;
export const rejectVendors = CmSdkReactNativeV3.rejectVendors;
export const acceptPurposes = CmSdkReactNativeV3.acceptPurposes;
export const rejectPurposes = CmSdkReactNativeV3.rejectPurposes;
export const rejectAll = CmSdkReactNativeV3.rejectAll;
export const acceptAll = CmSdkReactNativeV3.acceptAll;
export const importCMPInfo = CmSdkReactNativeV3.importCMPInfo;
export const resetConsentManagementData =
  CmSdkReactNativeV3.resetConsentManagementData;
export const requestATTAuthorization =
  CmSdkReactNativeV3.requestATTAuthorization;
export const getATTAuthorizationStatus =
  CmSdkReactNativeV3.getATTAuthorizationStatus;

export default CmSdkReactNativeV3;
