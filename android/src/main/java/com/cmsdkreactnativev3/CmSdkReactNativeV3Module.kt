package com.cmsdkreactnativev3

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.LifecycleEventListener
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import net.consentmanager.cm_sdk_android_v3.CMPManager
import net.consentmanager.cm_sdk_android_v3.CMPManagerDelegate
import net.consentmanager.cm_sdk_android_v3.ConsentLayerUIConfig
import net.consentmanager.cm_sdk_android_v3.ConsentStatus
import net.consentmanager.cm_sdk_android_v3.UrlConfig
import net.consentmanager.cm_sdk_android_v3.UserConsentStatus

class CmSdkReactNativeV3Module(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), LifecycleEventListener, CMPManagerDelegate {

  private lateinit var cmpManager: CMPManager
  private val scope = CoroutineScope(Dispatchers.Main)
  private var urlConfig: UrlConfig
  private var webViewConfig: ConsentLayerUIConfig
  private val uiThreadHandler = Handler(Looper.getMainLooper())

  init {
    reactContext.addLifecycleEventListener(this)
    urlConfig = UrlConfig("", "", "", "")
    webViewConfig = ConsentLayerUIConfig(
      position = ConsentLayerUIConfig.Position.FULL_SCREEN,
      cornerRadius = 0f,
      respectsSafeArea = true,
      allowsOrientationChanges = true
    )
  }

  override fun getName(): String = NAME

  private fun runOnUiThread(runnable: Runnable) {
    uiThreadHandler.post(runnable)
  }

  @ReactMethod
  fun setWebViewConfig(config: ReadableMap, promise: Promise) {
    runOnUiThread {
      try {
        val position = when (config.getString("position")) {
          "fullScreen" -> ConsentLayerUIConfig.Position.FULL_SCREEN
          "halfScreenBottom" -> ConsentLayerUIConfig.Position.HALF_SCREEN_BOTTOM
          "halfScreenTop" -> ConsentLayerUIConfig.Position.HALF_SCREEN_TOP
          else -> ConsentLayerUIConfig.Position.FULL_SCREEN
        }

        this.webViewConfig = ConsentLayerUIConfig(
          position = position,
          cornerRadius = (config.getDouble("cornerRadius") ?: 0.0).toFloat(),
          respectsSafeArea = config.getBoolean("respectsSafeArea"),
          allowsOrientationChanges = config.getBoolean("allowsOrientationChanges")
        )

        // Store this config to use when initializing CMPManager
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to set WebView config: ${e.message}")
      }
    }
  }

  @ReactMethod
  fun setUrlConfig(config: ReadableMap, promise: Promise) {
    runOnUiThread {
      try {
        val id = config.getString("id") ?: throw IllegalArgumentException("Missing 'id'")
        val domain = config.getString("domain") ?: throw IllegalArgumentException("Missing 'domain'")
        val language = config.getString("language") ?: throw IllegalArgumentException("Missing 'language'")
        val appName = config.getString("appName") ?: throw IllegalArgumentException("Missing 'appName'")

        this.urlConfig = UrlConfig(id, domain, language, appName)

        initializeCMPManager()

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to set URL config: ${e.message}")
      }
    }
  }

  private fun initializeCMPManager() {
    val activity = currentActivity ?: throw IllegalStateException("Current activity is null")
    cmpManager = CMPManager.getInstance(
      activity,
      urlConfig,
      webViewConfig,
      this
    )
    cmpManager.setActivity(activity)
  }

  // MARK: - New methods

  /**
   * Gets the comprehensive user consent status
   */
  @ReactMethod
  fun getUserStatus(promise: Promise) {
    try {
      val userStatus = cmpManager.getUserStatus()
      val result = Arguments.createMap().apply {
        putString("hasUserChoice", userStatus.hasUserChoice.toString())
        putString("tcf", userStatus.tcf)
        putString("addtlConsent", userStatus.addtlConsent)
        putString("regulation", userStatus.regulation)

        // Convert vendors map
        val vendorsMap = Arguments.createMap()
        userStatus.vendors.forEach { (vendorId, status) ->
          vendorsMap.putString(vendorId, status.toString())
        }
        putMap("vendors", vendorsMap)

        // Convert purposes map
        val purposesMap = Arguments.createMap()
        userStatus.purposes.forEach { (purposeId, status) ->
          purposesMap.putString(purposeId, status.toString())
        }
        putMap("purposes", purposesMap)
      }

      promise.resolve(result)
    } catch (e: Exception) {
      promise.reject("ERROR", "Failed to get user status: ${e.message}", e)
    }
  }

  /**
   * Gets the consent status for a specific purpose
   */
  @ReactMethod
  fun getStatusForPurpose(purposeId: String, promise: Promise) {
    try {
      val status = cmpManager.getStatusForPurpose(purposeId)
      promise.resolve(status.toString())
    } catch (e: Exception) {
      promise.reject("ERROR", "Failed to get status for purpose: ${e.message}", e)
    }
  }

  /**
   * Gets the consent status for a specific vendor
   */
  @ReactMethod
  fun getStatusForVendor(vendorId: String, promise: Promise) {
    try {
      val status = cmpManager.getStatusForVendor(vendorId)
      promise.resolve(status.toString())
    } catch (e: Exception) {
      promise.reject("ERROR", "Failed to get status for vendor: ${e.message}", e)
    }
  }

  /**
   * Gets Google Consent Mode v2 compatible settings
   */
  @ReactMethod
  fun getGoogleConsentModeStatus(promise: Promise) {
    try {
      val consentModeStatus = cmpManager.getGoogleConsentModeStatus()
      val result = Arguments.createMap()

      consentModeStatus.forEach { (key, value) ->
        result.putString(key, value)
      }

      promise.resolve(result)
    } catch (e: Exception) {
      promise.reject("ERROR", "Failed to get Google Consent Mode status: ${e.message}", e)
    }
  }

  /**
   * Replacement for openConsentLayer - force opens the consent UI
   */
  @ReactMethod
  fun forceOpen(jumpToSettings: Boolean, promise: Promise) {
    scope.launch {
      try {
        cmpManager.forceOpen(jumpToSettings) { result ->
          if (result.isSuccess) {
            promise.resolve(true)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to force open consent layer: ${e.message}", e)
      }
    }
  }

  /**
   * Replacement for checkWithServerAndOpenIfNecessary - checks with server and opens if needed
   */
  @ReactMethod
  fun checkAndOpen(jumpToSettings: Boolean, promise: Promise) {
    scope.launch {
      try {
        cmpManager.checkAndOpen(jumpToSettings) { result ->
          if (result.isSuccess) {
            promise.resolve(true)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to check and open consent: ${e.message}", e)
      }
    }
  }

  /**
   * Import a CMP information string
   */
  @ReactMethod
  fun importCMPInfo(cmpString: String, promise: Promise) {
    scope.launch {
      try {
        cmpManager.importCMPInfo(cmpString) { result ->
          if (result.isSuccess) {
            promise.resolve(true)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to import CMP info: ${e.message}", e)
      }
    }
  }

  /**
   * Reset all consent management data
   */
  @ReactMethod
  fun resetConsentManagementData(promise: Promise) {
    try {
      cmpManager.resetConsentManagementData()
      promise.resolve(true)
    } catch (e: Exception) {
      promise.reject("ERROR", "Failed to reset consent management data: ${e.message}", e)
    }
  }

  // MARK: - Deprecated methods (kept for backward compatibility)

  @ReactMethod
  fun checkWithServerAndOpenIfNecessary(promise: Promise) {
    scope.launch {
      try {
        // Call the new method instead, but keep the API signature the same
        cmpManager.checkAndOpen(false) { result ->
          if (result.isSuccess) {
            promise.resolve(true)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to check with server: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun openConsentLayer(promise: Promise) {
    scope.launch {
      try {
        // Call the new method instead, but keep the API signature the same
        cmpManager.forceOpen(false) { result ->
          if (result.isSuccess) {
            promise.resolve(true)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to open consent layer: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun jumpToSettings(promise: Promise) {
    scope.launch {
      try {
        cmpManager.forceOpen(true) { result ->
          if (result.isSuccess) {
            promise.resolve(true)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to jump to settings: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun checkIfConsentIsRequired(promise: Promise) {
    scope.launch {
      try {
        cmpManager.checkIfConsentIsRequired { isRequired ->
          promise.resolve(isRequired)
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to check if consent is required: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun hasUserChoice(promise: Promise) {
    promise.resolve(cmpManager.hasUserChoice())
  }

  @ReactMethod
  fun hasPurposeConsent(purposeId: String, promise: Promise) {
    promise.resolve(cmpManager.hasPurposeConsent(purposeId))
  }

  @ReactMethod
  fun hasVendorConsent(vendorId: String, promise: Promise) {
    promise.resolve(cmpManager.hasVendorConsent(vendorId))
  }

  @ReactMethod
  fun exportCMPInfo(promise: Promise) {
    promise.resolve(cmpManager.exportCMPInfo())
  }

  @ReactMethod
  fun getAllPurposesIDs(promise: Promise) {
    promise.resolve(cmpManager.getAllPurposesIDs().toWritableArray())
  }

  @ReactMethod
  fun getEnabledPurposesIDs(promise: Promise) {
    promise.resolve(cmpManager.getEnabledPurposesIDs().toWritableArray())
  }

  @ReactMethod
  fun getDisabledPurposesIDs(promise: Promise) {
    promise.resolve(cmpManager.getDisabledPurposesIDs().toWritableArray())
  }

  @ReactMethod
  fun getAllVendorsIDs(promise: Promise) {
    promise.resolve(cmpManager.getAllVendorsIDs().toWritableArray())
  }

  @ReactMethod
  fun getEnabledVendorsIDs(promise: Promise) {
    promise.resolve(cmpManager.getEnabledVendorsIDs().toWritableArray())
  }

  @ReactMethod
  fun getDisabledVendorsIDs(promise: Promise) {
    promise.resolve(cmpManager.getDisabledVendorsIDs().toWritableArray())
  }

  @ReactMethod
  fun acceptVendors(vendors: ReadableArray, promise: Promise) {
    scope.launch {
      try {
        Log.d("CmSdkReactNativeV3", "Accepting vendors: $vendors")

        cmpManager.acceptVendors(vendors.toListOfStrings()) { result ->
          if (result.isSuccess) {
            promise.resolve(null)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to accept vendors: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun rejectVendors(vendors: ReadableArray, promise: Promise) {
    scope.launch {
      try {
        Log.d("CmSdkReactNativeV3", "Rejecting vendors: $vendors")
        cmpManager.rejectVendors(vendors.toListOfStrings()) { result ->
          if (result.isSuccess) {
            promise.resolve(null)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to reject vendors: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun acceptPurposes(purposes: ReadableArray, updatePurpose: Boolean, promise: Promise) {
    scope.launch {
      try {
        Log.d("Cmsdkreactnativev3", "Rejecting purposes: $purposes")

        cmpManager.acceptPurposes(purposes.toListOfStrings(), updatePurpose) { result ->
          if (result.isSuccess) {
            promise.resolve(null)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to accept purposes: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun rejectPurposes(purposes: ReadableArray, updateVendor: Boolean, promise: Promise) {
    scope.launch {
      try {
        Log.d("Cmsdkreactnativev3", "Rejecting purposes: $purposes")
        cmpManager.rejectPurposes(purposes.toListOfStrings(), updateVendor) { result ->
          if (result.isSuccess) {
            promise.resolve(null)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to reject purposes: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun rejectAll(promise: Promise) {
    scope.launch {
      try {
        cmpManager.rejectAll { result ->
          if (result.isSuccess) {
            promise.resolve(null)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to reject all: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun acceptAll(promise: Promise) {
    scope.launch {
      try {
        cmpManager.acceptAll { result ->
          if (result.isSuccess) {
            promise.resolve(null)
          } else {
            promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
          }
        }
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to accept all: ${e.message}", e)
      }
    }
  }
  private fun ReadableArray.toListOfStrings(): List<String> {
    val list = mutableListOf<String>()
    for (i in 0 until this.size()) {
      when (this.getType(i)) {
        ReadableType.String -> list.add(this.getString(i) ?: "")
        ReadableType.Number -> list.add(this.getDouble(i).toString())
        ReadableType.Boolean -> list.add(this.getBoolean(i).toString())
        else -> throw IllegalArgumentException("Unsupported type in ReadableArray at index $i")
      }
    }
    return list
  }

  // LifecycleEventListener methods
  override fun onHostResume() {
    if (::cmpManager.isInitialized) {
      cmpManager.onApplicationResume()
      currentActivity?.let { cmpManager.setActivity(it) }
    }
  }

  override fun onHostPause() {
    if (::cmpManager.isInitialized) {
      cmpManager.onApplicationPause()
    }
  }

  override fun onHostDestroy() {
    if (::cmpManager.isInitialized) {
      cmpManager.onActivityDestroyed()
    }
  }

  private fun sendEvent(eventName: String, params: WritableMap?) {
    reactApplicationContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(eventName, params)
  }

  private fun List<String>.toWritableArray(): WritableArray {
    return Arguments.createArray().apply {
      this@toWritableArray.forEach { pushString(it) }
    }
  }

  companion object {
    const val NAME = "CmSdkReactNativeV3"
  }

  override fun didReceiveConsent(consent: String, jsonObject: Map<String, Any>) {
    val params = Arguments.createMap().apply {
      putString("consent", consent)
      putString("jsonObject", jsonObject.toString())
    }
    sendEvent("didReceiveConsent", params)
  }

  override fun didShowConsentLayer() {
    sendEvent("didShowConsentLayer", null)
  }

  override fun didCloseConsentLayer() {
    sendEvent("didCloseConsentLayer", null)
  }

  override fun didReceiveError(error: String) {
    val params = Arguments.createMap().apply {
      putString("error", error)
    }
    sendEvent("didReceiveError", params)
  }
}
