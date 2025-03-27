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
import CmSdkReactNativeV3 from 'cm-sdk-react-native-v3';

const HomeScreen: React.FC = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  useEffect(() => {
    initializeConsent();
  }, []);

  const initializeConsent = async () => {
    try {
      await CmSdkReactNativeV3.setUrlConfig({
        id: '26cba6cf81e76',
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

      await CmSdkReactNativeV3.checkAndOpen(false);
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
      title: 'Get User Status',
      onPress: () => handleApiCall(
        async () => {
          const result = await CmSdkReactNativeV3.getUserStatus();
          console.log('User Status Full Response:', JSON.stringify(result, null, 2));
          return result;
        },
        () => 'Check logs for User Status'
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
      title: 'Get Status for Purpose c53',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.getStatusForPurpose('c53'),
        (result) => `Purpose Status: ${result}`
      ),
    },
    {
      title: 'Get Status for Vendor s2789',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.getStatusForVendor('s2789'),
        (result) => `Vendor Status: ${result}`
      ),
    },
    {
      title: 'Get Google Consent Mode Status',
      onPress: () => handleApiCall(
        CmSdkReactNativeV3.getGoogleConsentModeStatus,
        (result) => `Google Consent: ${JSON.stringify(result)}`
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
        () => CmSdkReactNativeV3.checkAndOpen(false),
        () => 'Check and Open operation completed'
      ),
    },
    {
      title: 'Check and Open Settings Page',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.checkAndOpen(true),
        () => 'Settings page opened if needed'
      ),
    },
    {
      title: 'Force Open Consent Layer',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.forceOpen(false),
        () => 'Consent Layer opened'
      ),
    },
    {
      title: 'Force Open Settings Page',
      onPress: () => handleApiCall(
        () => CmSdkReactNativeV3.forceOpen(true),
        () => 'Settings page opened'
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
        <Text style={styles.subtitle}>Using New API</Text>
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
    marginBottom: 10,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    marginBottom: 20,
    textAlign: 'center',
    color: '#555',
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
