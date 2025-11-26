import { NativeModules, Platform, NativeEventEmitter, processColor } from 'react-native';
import NativeCmSdkReactNativeV3, {
  type ConsentReceivedEvent,
  type ErrorEvent,
  type LinkClickEvent,
  type ATTStatusChangeEvent,
  type UrlConfig,
  type WebViewConfig,
  type WebViewRect,
  type WebViewBackgroundStyle,
  WebViewPosition,
  type UserStatus,
  type GoogleConsentModeStatus,
  type CmSdkReactNativeV3Module,
} from './NativeCmSdkReactNativeV3';

// Re-export enums/constants for consumers
export { WebViewPosition };

const LINKING_ERROR =
  `The package 'react-native-cm-sdk-react-native-v3' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CmSdkReactNativeV3: CmSdkReactNativeV3Module =
  NativeCmSdkReactNativeV3 ??
  (NativeModules.CmSdkReactNativeV3 as CmSdkReactNativeV3Module | undefined) ??
  (new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  ) as CmSdkReactNativeV3Module);

const eventEmitter = new NativeEventEmitter(CmSdkReactNativeV3);

export const addConsentListener = (
  callback: (consent: string, jsonObject: Object) => void
) => {
  return eventEmitter.addListener('didReceiveConsent', (event: ConsentReceivedEvent) => {
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
  return eventEmitter.addListener('didReceiveError', (event: ErrorEvent) => {
    callback(event.error);
  });
};

export const addClickLinkListener = (callback: (url: string) => void) => {
  return eventEmitter.addListener('onClickLink', (event: LinkClickEvent) => {
    callback(event.url);
  });
};

export const addATTStatusChangeListener = (callback: (event: ATTStatusChangeEvent) => void) => {
  return eventEmitter.addListener('didChangeATTStatus', callback);
};

// Core configuration methods
export const setUrlConfig = (config: UrlConfig): Promise<void> => {
  return CmSdkReactNativeV3.setUrlConfig(config);
};

export const setWebViewConfig = (config: WebViewConfig): Promise<void> => {
  const normalized = normalizeWebViewConfig(config);
  return CmSdkReactNativeV3.setWebViewConfig(normalized);
};

export const setATTStatus = (status: number): Promise<void> => {
  return CmSdkReactNativeV3.setATTStatus(status);
};

// Main interaction methods
export const checkAndOpen = (jumpToSettings: boolean): Promise<boolean> => {
  return CmSdkReactNativeV3.checkAndOpen(jumpToSettings);
};

export const forceOpen = (jumpToSettings: boolean): Promise<boolean> => {
  return CmSdkReactNativeV3.forceOpen(jumpToSettings);
};

// Consent status methods
export const getUserStatus = (): Promise<UserStatus> => {
  return CmSdkReactNativeV3.getUserStatus();
};

// Helpers
const normalizeWebViewConfig = (config: WebViewConfig): WebViewConfig => {
  const position = (config.position as WebViewPosition | undefined) ?? WebViewPosition.FullScreen;
  const allowedPositions = [
    WebViewPosition.FullScreen,
    WebViewPosition.HalfScreenTop,
    WebViewPosition.HalfScreenBottom,
    WebViewPosition.Custom,
  ];
  if (!allowedPositions.includes(position)) {
    throw new Error(`Invalid WebView position: ${position}`);
  }

  if (position === WebViewPosition.Custom && !config.customRect) {
    throw new Error('customRect is required when position is "custom"');
  }

  const backgroundStyle = (() => {
    if (!config.backgroundStyle) {
      return { type: 'dimmed', color: normalizeColor('black'), opacity: 0.5 } as WebViewBackgroundStyle;
    }
    const { type } = config.backgroundStyle;
    switch (type) {
    case 'dimmed':
      return {
        type,
        color: normalizeColor(config.backgroundStyle.color ?? 'black'),
        opacity: config.backgroundStyle.opacity ?? 0.5,
      } as WebViewBackgroundStyle;
    case 'color':
        if (!config.backgroundStyle.color) throw new Error('color is required for backgroundStyle "color"');
        return { type, color: normalizeColor(config.backgroundStyle.color) } as WebViewBackgroundStyle;
    case 'blur':
      return { type, blurEffectStyle: config.backgroundStyle.blurEffectStyle ?? 'dark' } as WebViewBackgroundStyle;
    case 'none':
      return { type } as WebViewBackgroundStyle;
    default:
      throw new Error(`Invalid backgroundStyle type: ${(config.backgroundStyle as any).type}`);
    }
  })();

  return {
    position,
    customRect: config.customRect,
    cornerRadius: config.cornerRadius ?? 5,
    respectsSafeArea: config.respectsSafeArea ?? true,
    allowsOrientationChanges: config.allowsOrientationChanges ?? true,
    backgroundStyle,
  };
};

const normalizeColor = (color: string | number | undefined) => {
  if (color === undefined) return undefined;
  const processed = processColor(color);
  if (processed == null) throw new Error(`Invalid color value: ${color}`);
  return processed;
};

export const getStatusForPurpose = (purposeId: string): Promise<string> => {
  return CmSdkReactNativeV3.getStatusForPurpose(purposeId);
};

export const getStatusForVendor = (vendorId: string): Promise<string> => {
  return CmSdkReactNativeV3.getStatusForVendor(vendorId);
};

export const getGoogleConsentModeStatus = (): Promise<GoogleConsentModeStatus> => {
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
export const acceptVendors = (vendors: string[]): Promise<boolean> => {
  return CmSdkReactNativeV3.acceptVendors(vendors);
};

export const rejectVendors = (vendors: string[]): Promise<boolean> => {
  return CmSdkReactNativeV3.rejectVendors(vendors);
};

export const acceptPurposes = (purposes: string[], updatePurpose: boolean): Promise<boolean> => {
  return CmSdkReactNativeV3.acceptPurposes(purposes, updatePurpose);
};

export const rejectPurposes = (purposes: string[], updateVendor: boolean): Promise<boolean> => {
  return CmSdkReactNativeV3.rejectPurposes(purposes, updateVendor);
};

export const rejectAll = (): Promise<boolean> => {
  return CmSdkReactNativeV3.rejectAll();
};

export const acceptAll = (): Promise<boolean> => {
  return CmSdkReactNativeV3.acceptAll();
};

// Re-export types for consumer convenience
export type {
  ConsentReceivedEvent,
  ErrorEvent,
  LinkClickEvent,
  ATTStatusChangeEvent,
  UrlConfig,
  WebViewRect,
  WebViewBackgroundStyle,
  WebViewConfig,
  UserStatus,
  GoogleConsentModeStatus,
};

export default CmSdkReactNativeV3;
