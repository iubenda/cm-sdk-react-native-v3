package com.cmsdkreactnativev3

import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager

class CmSdkReactNativeV3Package : TurboReactPackage() {
  override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
    return if (name == CmSdkReactNativeV3Module.NAME) {
      CmSdkReactNativeV3Module(reactContext)
    } else {
      null
    }
  }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
    return ReactModuleInfoProvider {
      mapOf(
        CmSdkReactNativeV3Module.NAME to ReactModuleInfo(
          _name = CmSdkReactNativeV3Module.NAME,
          _className = CmSdkReactNativeV3Module.NAME,
          _canOverrideExistingModule = false,
          _needsEagerInit = false,
          isCxxModule = false,
          isTurboModule = true
        )
      )
    }
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }
}
