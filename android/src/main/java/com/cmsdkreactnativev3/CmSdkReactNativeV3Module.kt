package com.cmsdkreactnativev3

import android.os.Handler
import android.os.Looper
import android.util.Log
import android.app.Activity
import android.webkit.CookieManager
import android.webkit.WebStorage
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.LifecycleEventListener
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import net.consentmanager.cm_sdk_android_v3.CMPManager
import net.consentmanager.cm_sdk_android_v3.CMPManagerDelegate
import net.consentmanager.cm_sdk_android_v3.ConsentLayerUIConfig
import net.consentmanager.cm_sdk_android_v3.ConsentStatus
import net.consentmanager.cm_sdk_android_v3.UrlConfig
import net.consentmanager.cm_sdk_android_v3.UserChoiceStatus

class CmSdkReactNativeV3Module(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext), LifecycleEventListener, CMPManagerDelegate {

  private lateinit var cmpManager: CMPManager
  private val scope = CoroutineScope(Dispatchers.Main)
  private var urlConfig: UrlConfig
  private var webViewConfig: ConsentLayerUIConfig
  private val uiThreadHandler = Handler(Looper.getMainLooper())
  private var isInitialized = false
  private var storedATTStatus: Int = 0
  private var isWebViewConfigSet = false
  private var automaticConsentUpdatesEnabled = true


  init {
    reactContext.addLifecycleEventListener(this)
    urlConfig = UrlConfig("", "", "", "")
    webViewConfig = ConsentLayerUIConfig(
      position = ConsentLayerUIConfig.Position.FULL_SCREEN,
      backgroundStyle = ConsentLayerUIConfig.BackgroundStyle.dimmed(android.graphics.Color.BLACK, 0.5f),
      cornerRadius = dpToPx(5f),
      respectsSafeArea = true,
      isCancelable = false,
      allowsOrientationChanges = true
    )
  }

  override fun getName(): String = NAME
  
  override fun invalidate() {
    super.invalidate()
    if (::cmpManager.isInitialized) {
      cmpManager.onActivityDestroyed()
    }
  }

  private fun runOnUiThread(runnable: Runnable) {
    uiThreadHandler.post(runnable)
  }

  private val currentActivitySafe: Activity?
    get() = reactApplicationContext.currentActivity

  @ReactMethod
  fun addListener(eventName: String?) {
    // Required for NativeEventEmitter - React Native calls this automatically
  }

  @ReactMethod
  fun removeListeners(count: Double) {
    // Required for NativeEventEmitter - React Native calls this automatically
  }





  @ReactMethod
  fun setATTStatus(status: Double, promise: Promise) {
    try {
      this.storedATTStatus = status.toInt()
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("ERROR", "Failed to set ATT status: ${e.message}")
    }
  }

  @ReactMethod
  fun setWebViewConfig(config: ReadableMap, promise: Promise) {
    try {
      if (::cmpManager.isInitialized && isInitialized) {
        Log.w("CmSdkReactNativeV3", "setWebViewConfig called after CMPManager initialization. Config changes will not be applied. Set config before setUrlConfig.")
        promise.resolve(null)
        return
      }

      val position = when (config.getString("position")) {
        "fullScreen" -> ConsentLayerUIConfig.Position.FULL_SCREEN
        "halfScreenBottom" -> ConsentLayerUIConfig.Position.HALF_SCREEN_BOTTOM
        "halfScreenTop" -> ConsentLayerUIConfig.Position.HALF_SCREEN_TOP
        else -> ConsentLayerUIConfig.Position.FULL_SCREEN
      }

      val cornerRadiusDp = if (config.hasKey("cornerRadius")) config.getDouble("cornerRadius").toFloat() else 0f
      val cornerRadius = dpToPx(cornerRadiusDp)

      this.webViewConfig = ConsentLayerUIConfig(
        position = position,
        backgroundStyle = mapBackgroundStyle(config),
        cornerRadius = cornerRadius,
        respectsSafeArea = if (config.hasKey("respectsSafeArea")) config.getBoolean("respectsSafeArea") else true,
        isCancelable = false,
        allowsOrientationChanges = if (config.hasKey("allowsOrientationChanges")) config.getBoolean("allowsOrientationChanges") else true,
        darkMode = if (config.hasKey("darkMode")) config.getBoolean("darkMode") else false,
        navigationBarColor = readOptionalColor(config, "navigationBarColor")
      )
      isWebViewConfigSet = true

      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject("ERROR", "Failed to set WebView config: ${e.message}")
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
        val jsonConfig = if (config.hasKey("jsonConfig")) config.getString("jsonConfig") else null
        val noHash = if (config.hasKey("noHash")) config.getBoolean("noHash") else false
        val webViewConnectionTimeoutMillis = if (config.hasKey("webViewConnectionTimeoutMillis")) config.getDouble("webViewConnectionTimeoutMillis").toLong() else 3000L
        val forceRegulation = if (config.hasKey("forceRegulation")) config.getString("forceRegulation") else null

        this.urlConfig = UrlConfig(
          id = id,
          domain = domain,
          language = language,
          appName = appName,
          jsonConfig = jsonConfig,
          noHash = noHash,
          webViewConnectionTimeoutMillis = webViewConnectionTimeoutMillis,
          forceRegulation = forceRegulation
        )
        // Ensure we initialize manager only once and with whatever webViewConfig is currently set
        if (!::cmpManager.isInitialized) {
          initializeCMPManager()
        }

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to set URL config: ${e.message}")
      }
    }
  }

  private fun initializeCMPManager() {
    val activity = currentActivitySafe ?: throw IllegalStateException("Current activity is null. Wait until the app is active before calling setUrlConfig().")
    Log.d("CmSdkReactNativeV3", "Initializing CMPManager with activity: $activity, delegate: $this")

    cmpManager = CMPManager.getInstance(
      activity,
      urlConfig,
      webViewConfig,
      this
    )
    configureCmpManager(activity)
  }

  private fun configureCmpManager(activity: Activity) {
    cmpManager.setActivity(activity)

    cmpManager.setOnClickLinkCallback { url ->
      Log.d("CmSdkReactNativeV3", "Link clicked: $url")
      val params = Arguments.createMap().apply {
        putString("url", url)
      }
      sendEvent("onClickLink", params)

      when {
        !url.contains("google.com") -> true
        url.contains("privacy") || url.contains("terms") -> true
        else -> false
      }
    }

    if (!isGloballyInitialized) {
      globalCMPManager = cmpManager
      isGloballyInitialized = true
    }
    isInitialized = true

    Log.d("CmSdkReactNativeV3", "CMPManager initialized/reconfigured with current configs")
  }

  /**
   * Gets the comprehensive user consent status
   */
  @ReactMethod
  fun getUserStatus(promise: Promise) {
    withCmpManager(promise) { manager ->
      try {
        val userStatus = manager.getUserStatus()
        val normalizedStatus = mapUserChoiceStatus(userStatus.hasUserChoice)
        val result = Arguments.createMap().apply {
          putString("status", normalizedStatus)
          putString("hasUserChoice", normalizedStatus)
          putString("tcf", userStatus.tcf)
          putString("addtlConsent", userStatus.addtlConsent)
          putString("regulation", userStatus.regulation)

          val vendorsMap = Arguments.createMap()
          userStatus.vendors.forEach { (vendorId, status) ->
            vendorsMap.putString(vendorId, mapConsentStatus(status))
          }
          putMap("vendors", vendorsMap)

          val purposesMap = Arguments.createMap()
          userStatus.purposes.forEach { (purposeId, status) ->
            purposesMap.putString(purposeId, mapConsentStatus(status))
          }
          putMap("purposes", purposesMap)
        }

        promise.resolve(result)
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to get user status: ${e.message}", e)
      }
    }
  }

  private fun dpToPx(dp: Float): Float {
    val metrics = reactApplicationContext.resources.displayMetrics
    return android.util.TypedValue.applyDimension(android.util.TypedValue.COMPLEX_UNIT_DIP, dp, metrics)
  }

  /**
   * Gets the consent status for a specific purpose
   */
  @ReactMethod
  fun getStatusForPurpose(purposeId: String, promise: Promise) {
    withCmpManager(promise) { manager ->
      try {
        val status = manager.getStatusForPurpose(purposeId)
        promise.resolve(mapConsentStatus(status))
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to get status for purpose: ${e.message}", e)
      }
    }
  }

  /**
   * Gets the consent status for a specific vendor
   */
  @ReactMethod
  fun getStatusForVendor(vendorId: String, promise: Promise) {
    withCmpManager(promise) { manager ->
      try {
        val status = manager.getStatusForVendor(vendorId)
        promise.resolve(mapConsentStatus(status))
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to get status for vendor: ${e.message}", e)
      }
    }
  }

  /**
   * Gets Google Consent Mode v2 compatible settings
   */
  @ReactMethod
  fun getGoogleConsentModeStatus(promise: Promise) {
    withCmpManager(promise) { manager ->
      try {
        val consentModeStatus = manager.getGoogleConsentModeStatus()
        val result = Arguments.createMap()

        consentModeStatus.forEach { (key, value) ->
          result.putString(key, value)
        }

        promise.resolve(result)
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to get Google Consent Mode status: ${e.message}", e)
      }
    }
  }

  /**
   * Checks if consent is required without opening the consent UI
   */
  @ReactMethod
  fun isConsentRequired(promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        val activity = currentActivitySafe ?: run {
          promise.reject("NO_ACTIVITY", "Current activity is null. Wait until the app is active before calling isConsentRequired().")
          return@withCmpManager
        }

        try {
          manager.setActivity(activity)
          manager.isConsentRequired { result ->
            if (result.isSuccess) {
              promise.resolve(result.getOrNull() ?: false)
            } else {
              promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
            }
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to check if consent is required: ${e.message}", e)
        }
      }
    }
  }

  /**
   * Replacement for openConsentLayer - force opens the consent UI
   */
  @ReactMethod
  fun forceOpen(jumpToSettings: Boolean, promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        val activity = currentActivitySafe ?: run {
          promise.reject("NO_ACTIVITY", "Current activity is null. Wait until the app is active before calling forceOpen().")
          return@withCmpManager
        }

        try {
          manager.setActivity(activity)
          manager.forceOpen(jumpToSettings) { result ->
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
  }

  /**
   * Replacement for checkWithServerAndOpenIfNecessary - checks with server and opens if needed
   */
  @ReactMethod
  fun checkAndOpen(jumpToSettings: Boolean, promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        val activity = currentActivitySafe ?: run {
          promise.reject("NO_ACTIVITY", "Current activity is null. Wait until the app is active before calling checkAndOpen().")
          return@withCmpManager
        }

        try {
          manager.setActivity(activity)
          manager.checkAndOpen(jumpToSettings) { result ->
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
  }

  /**
   * Import a CMP information string
   */
  @ReactMethod
  fun importCMPInfo(cmpString: String, promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        try {
          manager.importCMPInfo(cmpString) { result ->
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
  }

  /**
   * Reset all consent management data
   */
  @ReactMethod
  fun resetConsentManagementData(promise: Promise) {
    withCmpManager(promise) { manager ->
      runOnUiThread {
        try {
          manager.resetConsentManagementData()
          clearWebViewStorage {
            promise.resolve(true)
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to reset consent management data: ${e.message}", e)
        }
      }
    }
  }

  @ReactMethod
  fun exportCMPInfo(promise: Promise) {
    withCmpManager(promise) { manager ->
      promise.resolve(manager.exportCMPInfo())
    }
  }

  @ReactMethod
  fun acceptVendors(vendors: ReadableArray, promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        try {
          Log.d("CmSdkReactNativeV3", "Accepting vendors: $vendors")

          manager.acceptVendors(vendors.toListOfStrings()) { result ->
            if (result.isSuccess) {
              promise.resolve(true)
            } else {
              promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
            }
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to accept vendors: ${e.message}", e)
        }
      }
    }
  }

  @ReactMethod
  fun rejectVendors(vendors: ReadableArray, promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        try {
          Log.d("CmSdkReactNativeV3", "Rejecting vendors: $vendors")
          manager.rejectVendors(vendors.toListOfStrings()) { result ->
            if (result.isSuccess) {
              promise.resolve(true)
            } else {
              promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
            }
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to reject vendors: ${e.message}", e)
        }
      }
    }
  }

  @ReactMethod
  fun acceptPurposes(purposes: ReadableArray, updatePurpose: Boolean, promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        try {
          Log.d("Cmsdkreactnativev3", "Accepting purposes: $purposes")

          manager.acceptPurposes(purposes.toListOfStrings(), updatePurpose) { result ->
            if (result.isSuccess) {
              promise.resolve(true)
            } else {
              promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
            }
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to accept purposes: ${e.message}", e)
        }
      }
    }
  }

  @ReactMethod
  fun rejectPurposes(purposes: ReadableArray, updateVendor: Boolean, promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        try {
          Log.d("Cmsdkreactnativev3", "Rejecting purposes: $purposes")
          manager.rejectPurposes(purposes.toListOfStrings(), updateVendor) { result ->
            if (result.isSuccess) {
              promise.resolve(true)
            } else {
              promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
            }
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to reject purposes: ${e.message}", e)
        }
      }
    }
  }

  @ReactMethod
  fun rejectAll(promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        try {
          manager.rejectAll { result ->
            if (result.isSuccess) {
              promise.resolve(true)
            } else {
              promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
            }
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to reject all: ${e.message}", e)
        }
      }
    }
  }

  @ReactMethod
  fun acceptAll(promise: Promise) {
    scope.launch {
      withCmpManager(promise) { manager ->
        try {
          manager.acceptAll { result ->
            if (result.isSuccess) {
              promise.resolve(true)
            } else {
              promise.reject("ERROR", result.exceptionOrNull()?.message ?: "Unknown error")
            }
          }
        } catch (e: Exception) {
          promise.reject("ERROR", "Failed to accept all: ${e.message}", e)
        }
      }
    }
  }

  @ReactMethod
  fun setAutomaticConsentUpdatesEnabled(enabled: Boolean, promise: Promise) {
    withCmpManager(promise) { manager ->
      try {
        automaticConsentUpdatesEnabled = enabled
        manager.setAutomaticConsentUpdatesEnabled(enabled)
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to set automatic consent updates: ${e.message}", e)
      }
    }
  }

  @ReactMethod
  fun updateThirdPartyConsent(promise: Promise) {
    withCmpManager(promise) { manager ->
      try {
        val result = Arguments.createMap()
        manager.updateThirdPartyConsent(reactApplicationContext).forEach { (key, value) ->
          result.putBoolean(key, value)
        }
        promise.resolve(result)
      } catch (e: Exception) {
        promise.reject("ERROR", "Failed to update third-party consent: ${e.message}", e)
      }
    }
  }

  private fun mapBackgroundStyle(config: ReadableMap): ConsentLayerUIConfig.BackgroundStyle {
    val backgroundConfig = if (config.hasKey("backgroundStyle")) config.getMap("backgroundStyle") else null
    val type = backgroundConfig?.getString("type") ?: return ConsentLayerUIConfig.BackgroundStyle.dimmed(android.graphics.Color.BLACK, 0.5f)

    return when (type) {
      "dimmed" -> ConsentLayerUIConfig.BackgroundStyle.dimmed(
        readOptionalColor(backgroundConfig, "color") ?: android.graphics.Color.BLACK,
        if (backgroundConfig.hasKey("opacity")) backgroundConfig.getDouble("opacity").toFloat() else 0.5f
      )
      "color" -> ConsentLayerUIConfig.BackgroundStyle.solid(
        readOptionalColor(backgroundConfig, "color") ?: android.graphics.Color.BLACK
      )
      "blur" -> ConsentLayerUIConfig.BackgroundStyle.blur(
        readOptionalColor(backgroundConfig, "fallbackColor") ?: android.graphics.Color.BLACK,
        if (backgroundConfig.hasKey("fallbackOpacity")) backgroundConfig.getDouble("fallbackOpacity").toFloat() else 0.5f
      )
      "none" -> ConsentLayerUIConfig.BackgroundStyle.none()
      else -> ConsentLayerUIConfig.BackgroundStyle.dimmed(android.graphics.Color.BLACK, 0.5f)
    }
  }

  private fun readOptionalColor(config: ReadableMap, key: String): Int? {
    return if (config.hasKey(key) && !config.isNull(key)) config.getDouble(key).toInt() else null
  }

  private fun mapConsentStatus(status: ConsentStatus): String {
    return when (status) {
      ConsentStatus.CHOICE_DOESNT_EXIST -> "choiceDoesntExist"
      ConsentStatus.GRANTED -> "granted"
      ConsentStatus.DENIED -> "denied"
    }
  }

  private fun mapUserChoiceStatus(status: UserChoiceStatus): String {
    return when (status) {
      UserChoiceStatus.CHOICE_EXISTS -> "choiceExists"
      UserChoiceStatus.CHOICE_DOESNT_EXIST -> "choiceDoesntExist"
    }
  }

  private fun withCmpManager(promise: Promise, block: (CMPManager) -> Unit) {
    if (!::cmpManager.isInitialized) {
      promise.reject("NOT_INITIALIZED", "CMPManager is not initialized. Call setUrlConfig() first.")
      return
    }

    block(cmpManager)
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

  override fun onHostResume() {
    if (::cmpManager.isInitialized) {
      cmpManager.onApplicationResume()
      currentActivitySafe?.let { cmpManager.setActivity(it) }
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
    Log.d("CmSdkReactNativeV3", "sendEvent called: $eventName")
    reactApplicationContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(eventName, params)
  }

  private fun List<String>.toWritableArray(): WritableArray {
    return Arguments.createArray().apply {
      this@toWritableArray.forEach { pushString(it) }
    }
  }

  private fun clearWebViewStorage(onComplete: () -> Unit) {
    try {
      val cookieManager = CookieManager.getInstance()
      cookieManager.removeAllCookies {
        cookieManager.flush()
        WebStorage.getInstance().deleteAllData()
        onComplete()
      }
    } catch (e: Exception) {
      Log.w("CmSdkReactNativeV3", "Failed to clear WebView storage: ${e.message}")
      onComplete()
    }
  }

  companion object {
    const val NAME = "CmSdkReactNativeV3"
    private var globalCMPManager: CMPManager? = null
    private var isGloballyInitialized = false
  }

  override fun didReceiveConsent(consent: String, jsonObject: Map<String, Any>) {
    Log.d("CmSdkReactNativeV3", "didReceiveConsent called from native SDK with consent: ${consent.take(50)}...")
    Log.d("CmSdkReactNativeV3", "Consent string length: ${consent.length}")
    Log.d("CmSdkReactNativeV3", "Consent string class: ${consent.javaClass.name}")
    Log.d("CmSdkReactNativeV3", "First char code: ${if (consent.isNotEmpty()) consent[0].code else "empty"}")
    Log.d("CmSdkReactNativeV3", "Last char code: ${if (consent.isNotEmpty()) consent[consent.length - 1].code else "empty"}")
    
    val params = Arguments.createMap().apply {
      putString("consent", consent)
      putMap("jsonObject", convertMapToWritableMap(jsonObject))
    }
    sendEvent("didReceiveConsent", params)
  }

  private fun convertMapToWritableMap(map: Map<String, Any>): WritableMap {
    val writableMap = Arguments.createMap()
    map.forEach { (key, value) ->
      when (value) {
        is String -> writableMap.putString(key, value)
        is Int -> writableMap.putInt(key, value)
        is Long -> writableMap.putDouble(key, value.toDouble())
        is Double -> writableMap.putDouble(key, value)
        is Float -> writableMap.putDouble(key, value.toDouble())
        is Boolean -> writableMap.putBoolean(key, value)
        is Map<*, *> -> {
          @Suppress("UNCHECKED_CAST")
          writableMap.putMap(key, convertMapToWritableMap(value as Map<String, Any>))
        }
        is List<*> -> writableMap.putArray(key, convertListToWritableArray(value))
        else -> writableMap.putString(key, value.toString())
      }
    }
    return writableMap
  }

  private fun convertListToWritableArray(list: List<*>): WritableArray {
    val writableArray = Arguments.createArray()
    list.forEach { item ->
      when (item) {
        is String -> writableArray.pushString(item)
        is Int -> writableArray.pushInt(item)
        is Long -> writableArray.pushDouble(item.toDouble())
        is Double -> writableArray.pushDouble(item)
        is Float -> writableArray.pushDouble(item.toDouble())
        is Boolean -> writableArray.pushBoolean(item)
        is Map<*, *> -> {
          @Suppress("UNCHECKED_CAST")
          writableArray.pushMap(convertMapToWritableMap(item as Map<String, Any>))
        }
        is List<*> -> writableArray.pushArray(convertListToWritableArray(item))
        else -> writableArray.pushString(item.toString())
      }
    }
    return writableArray
  }

  override fun didShowConsentLayer() {
    Log.d("CmSdkReactNativeV3", "didShowConsentLayer called from native SDK - forwarding to React Native")
    sendEvent("didShowConsentLayer", null)
  }

  override fun didCloseConsentLayer() {
    Log.d("CmSdkReactNativeV3", "didCloseConsentLayer called from native SDK - forwarding to React Native")
    sendEvent("didCloseConsentLayer", null)
  }

  override fun didReceiveError(error: String) {
    val params = Arguments.createMap().apply {
      putString("error", error)
    }
    sendEvent("didReceiveError", params)
  }
}
