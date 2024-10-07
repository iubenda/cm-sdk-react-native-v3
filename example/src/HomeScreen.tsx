import React, { useState, useEffect } from 'react';
import {
  View,
  SafeAreaView,
  ScrollView,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import CmSdkReactNativeV3 from 'react-native-cm-sdk-react-native-v3';

const HomeScreen: React.FC = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  useEffect(() => {
    initializeConsent();
  }, []);

  const initializeConsent = async () => {
    try {
      await CmSdkReactNativeV3.setUrlConfig({
        id: '09cb5dca91e6b',
        domain: 'delivery.consentmanager.net',
        language: 'EN',
        appName: 'CMDemoAppReactNative',
      });

      await CmSdkReactNativeV3.setWebViewConfig({
        position: 'fullScreen',
        backgroundStyle: { type: 'dimmed', color: 'black', opacity: 0.5 },
        cornerRadius: 5,
        respectsSafeArea: true,
        allowsOrientationChanges: true,
      });

      await CmSdkReactNativeV3.checkWithServerAndOpenIfNecessary();
      console.log('CMPManager initialized and open consent layer opened if necessary');
    } catch (error) {
      console.error('Error initializing consent:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const showToast = (message: string) => {
    setToastMessage(message);
    setTimeout(() => setToastMessage(null), 2000);
  };

  const handleApiCall = async (
    apiCall: () => Promise<any>,
    successMessage: (result: any) => string,
    errorMessage: string = 'An error occurred'
  ) => {
    try {
      const result = await apiCall();
      showToast(successMessage(result));
    } catch (error) {
      showToast(`${errorMessage}: ${error}`);
    }
  };

  const buttons = [
    {
      title: 'Has User Choice?',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.hasUserChoice,
        (result) => `Has User Choice: ${result}`
      ),
    },
    {
      title: 'Get CMP String',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.exportCMPInfo,
        (result) => `CMP String: ${result}`
      ),
    },
    {
      title: 'Get All Purposes',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.getAllPurposesIDs,
        (result) => `All Purposes: ${result.join(', ')}`
      ),
    },
    {
      title: 'Has Purpose ID c53?',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.hasPurposeConsent('c53'),
        (result) => `Has Purpose: ${result}`
      ),
    },
    {
      title: 'Get Enabled Purposes',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.getEnabledPurposesIDs,
        (result) => `Enabled Purposes: ${result.join(', ')}`
      ),
    },
    {
      title: 'Get Disabled Purposes',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.getDisabledPurposesIDs,
        (result) => `Disabled Purposes: ${result.join(', ')}`
      ),
    },
    {
      title: 'Enable Purposes c52 and c53',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.acceptPurposes(['c52', 'c53'], true),
        () => 'Purposes enabled'
      ),
    },
    {
      title: 'Disable Purposes c52 and c53',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.rejectPurposes(['c52', 'c53'], true),
        () => 'Purposes disabled'
      ),
    },
    {
      title: 'Get All Vendors',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.getAllVendorsIDs,
        (result) => `All Vendors: ${result.join(', ')}`
      ),
    },
    {
      title: 'Has Vendor ID s2789?',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.hasVendorConsent('s2789'),
        (result) => `Has Vendor: ${result}`
      ),
    },
    {
      title: 'Get Enabled Vendors',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.getEnabledVendorsIDs,
        (result) => `Enabled Vendors: ${result.join(', ')}`
      ),
    },
    {
      title: 'Get Disabled Vendors',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.getDisabledVendorsIDs,
        (result) => `Disabled Vendors: ${result.join(', ')}`
      ),
    },
    {
      title: 'Enable Vendors s2790 and s2791',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.acceptVendors(['s2790', 's2791']),
        () => 'Vendors Enabled'
      ),
    },
    {
      title: 'Disable Vendors s2790 and s2791',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.rejectVendors(['s2790', 's2791']),
        () => 'Vendors Disabled'
      ),
    },
    {
      title: 'Reject All',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.rejectAll,
        () => 'All consents rejected'
      ),
    },
    {
      title: 'Accept All',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.acceptAll,
        () => 'All consents accepted'
      ),
    },
    {
      title: 'Check and Open Consent Layer',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.checkWithServerAndOpenIfNecessary,
        () => 'Check and Open Consent Layer operation done successfully'
      ),
    },
    {
      title: 'Check Consent Required',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.checkIfConsentIsRequired,
        (result) => `Needs Consent: ${result}`
      ),
    },
    {
      title: 'Open Consent Layer',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.openConsentLayer,
        () => 'Consent Layer opened successfully'
      ),
    },
    {
      title: 'Import CMP String',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.importCMPInfo(
          'Q1FERkg3QVFERkg3QUFmR01CSVRCQkVnQUFBQUFBQUFBQWlnQUFBQUFBQUEjXzUxXzUyXzUzXzU0XzU1XzU2XyNfczI3ODlfczI3OTBfczI3OTFfczI2OTdfczk3MV9VXyMxLS0tIw'
        ),
        () => 'New consent string imported successfully'
      ),
    },
    {
      title: 'Reset all CMP Info',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.resetConsentManagementData,
        () => 'All consents reset'
      ),
    },
    {
      title: 'Request ATT Authorization',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.requestATTAuthorization,
        (status) => `ATT Status: ${status}`
      ),
    },
  ];

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#0000ff" />
        <Text>Initializing Consent Manager...</Text>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={styles.title}>CM React Native DemoApp</Text>
        {buttons.map((button, index) => (
          <TouchableOpacity
            key={index}
            style={styles.button}
            onPress={button.onPress}
          >
            <Text style={styles.buttonText}>{button.title}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
      {toastMessage && (
        <View style={styles.toast}>
          <Text style={styles.toastText}>{toastMessage}</Text>
        </View>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scrollContent: {
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  button: {
    backgroundColor: 'blue',
    padding: 10,
    borderRadius: 5,
    marginBottom: 10,
  },
  buttonText: {
    color: 'white',
    textAlign: 'center',
  },
  toast: {
    position: 'absolute',
    bottom: 50,
    left: 20,
    right: 20,
    backgroundColor: 'rgba(0,0,0,0.7)',
    padding: 10,
    borderRadius: 5,
  },
  toastText: {
    color: 'white',
    textAlign: 'center',
  },
});

export default HomeScreen;
