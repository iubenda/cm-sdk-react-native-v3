import Foundation
import cm_sdk_ios_v3

@objc(CmSdkReactNativeV3)
class CmSdkReactNativeV3: NSObject {
  
  private let cmpManager: CMPManager
  
  override init() {
    self.cmpManager = CMPManager.shared
    super.init()
  }

  private func runOnMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync(execute: block)
    }
  }

  @objc(setWebViewConfig:withResolver:withRejecter:)
  func setWebViewConfig(_ config: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let position: ConsentLayerUIConfig.Position
      switch config["position"] as? String {
      case "fullScreen":
          position = .fullScreen
      case "halfScreenBottom":
        position = .halfScreenBottom
      case "halfScreenTop":
        position = .halfScreenTop
      default:
          position = .fullScreen // Default value
      }
      
      let backgroundStyle: ConsentLayerUIConfig.BackgroundStyle
      if let opacity = config["backgroundOpacity"] as? CGFloat {
          backgroundStyle = .dimmed(.black, opacity)
      } else {
          backgroundStyle = .dimmed(.black, 0.5) // Default value
      }
      
      let uiConfig = ConsentLayerUIConfig(
          position: position,
          backgroundStyle: backgroundStyle,
          cornerRadius: CGFloat(config["cornerRadius"] as? Double ?? 5),
          respectsSafeArea: config["respectsSafeArea"] as? Bool ?? true,
          allowsOrientationChanges: config["allowsOrientationChanges"] as? Bool ?? true
      )
      runOnMainThread{
        self.cmpManager.setWebViewConfig(uiConfig)
        resolve(nil)
      }
  }

  @objc(setUrlConfig:withResolver:withRejecter:)
  func setUrlConfig(_ config: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    runOnMainThread { [self] in
          do {
              guard let id = config["id"] as? String,
                    let domain = config["domain"] as? String,
                    let language = config["language"] as? String,
                    let appName = config["appName"] as? String else {
                  throw NSError(domain: "CmSdkReactNativeV3", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid config parameters"])
              }
              print("ID: \(id) - Domain: \(domain)")
              
              let urlConfig = UrlConfig(id: id, domain: domain, language: language, appName: appName)
              print("urlConfig = \(urlConfig)")
              self.cmpManager.setUrlConfig(urlConfig)
              resolve(nil)
          } catch {
              reject("ERROR", "Failed to set URL config: \(error.localizedDescription)", error)
          }
      }
  }
  
  @objc(checkWithServerAndOpenIfNecessary:withRejecter:)
  func checkWithServerAndOpenIfNecessary(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      DispatchQueue.main.async { [weak self] in
          guard let self = self else {
              reject("ERROR", "Bridge object deallocated", nil)
              return
          }
          self.cmpManager.checkWithServerAndOpenIfNecessary { success in
              resolve(success)
          }
      }
  }
  
  @objc(openConsentLayer:withRejecter:)
  func openConsentLayer(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      DispatchQueue.main.async { [weak self] in
          guard let self = self else {
              reject("ERROR", "Bridge object deallocated", nil)
              return
          }
          self.cmpManager.openConsentLayer { success in
              resolve(success)
          }
      }
  }
  
  @objc(jumpToSettings:withRejecter:)
  func jumpToSettings(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      DispatchQueue.main.async { [weak self] in
          guard let self = self else {
              reject("ERROR", "Bridge object deallocated", nil)
              return
          }
        self.cmpManager.jumpToSettings(completion: { success in resolve(success)})
          resolve(nil)
      }
  }
  
  @objc(checkIfConsentIsRequired:withRejecter:)
  func checkIfConsentIsRequired(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.checkIfConsentIsRequired { success in
          resolve(success)
      }
  }  

  @objc(hasUserChoice:withRejecter:)
  func hasUserChoice(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let result = self.cmpManager.hasUserChoice()
      resolve(result)
  }
  
  @objc(hasPurposeConsent:withResolver:withRejecter:)
  func hasPurposeConsent(_ purposeId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let result = self.cmpManager.hasPurposeConsent(id: purposeId)
        resolve(result)
  }
  
  @objc(hasVendorConsent:withResolver:withRejecter:)
  func hasVendorConsent(_ vendorId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let result = self.cmpManager.hasVendorConsent(id: vendorId)
        resolve(result)
  }
  
  @objc(exportCMPInfo:withRejecter:)
  func exportCMPInfo(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let info = self.cmpManager.exportCMPInfo()
      resolve(info)
  }
  
  @objc(getAllPurposesIDs:withRejecter:)
  func getAllPurposesIDs(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let purposeIDs = self.cmpManager.getAllPurposesIDs()
      resolve(purposeIDs)
  }
  
  @objc(getEnabledPurposesIDs:withRejecter:)
  func getEnabledPurposesIDs(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let purposeIDs = self.cmpManager.getEnabledPurposesIDs()
      resolve(purposeIDs)
  }
  
  @objc(getDisabledPurposesIDs:withRejecter:)
  func getDisabledPurposesIDs(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let purposeIDs = self.cmpManager.getDisabledPurposesIDs()
      resolve(purposeIDs)
  }
  
  @objc(getAllVendorsIDs:withRejecter:)
  func getAllVendorsIDs(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let vendorIDs = self.cmpManager.getAllVendorsIDs()
      resolve(vendorIDs)
  }
  
  @objc(getEnabledVendorsIDs:withRejecter:)
  func getEnabledVendorsIDs(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let vendorIDs = self.cmpManager.getEnabledVendorsIDs()
      resolve(vendorIDs)
  }
  
  @objc(getDisabledVendorsIDs:withRejecter:)
  func getDisabledVendorsIDs(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let vendorIDs = self.cmpManager.getDisabledVendorsIDs()
      resolve(vendorIDs)
  }
  
  @objc(acceptVendors:withResolver:withRejecter:)
  func acceptVendors(_ vendors: [String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.acceptVendors(vendors) { success in
          resolve(success)
          }
  }
  
  @objc(rejectVendors:withResolver:withRejecter:)
  func rejectVendors(_ vendors: [String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.rejectVendors(vendors) { success in
          resolve(success)
      }
  }
  
  @objc(acceptPurposes:updatePurpose:withResolver:withRejecter:)
  func acceptPurposes(_ purposes: [String], updatePurpose: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.acceptPurposes(purposes, updatePurpose: updatePurpose) { success in
          resolve(success)
      }
  }
  
  @objc(rejectPurposes:updateVendor:withResolver:withRejecter:)
  func rejectPurposes(_ purposes: [String], updateVendor: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.rejectPurposes(purposes, updateVendor: updateVendor) { success in
          resolve(success)
      }
  }
  
  @objc(rejectAll:withRejecter:)
  func rejectAll(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.rejectAll { success in
          resolve(success)
      }
  }
  
  @objc(acceptAll:withRejecter:)
  func acceptAll(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.acceptAll { success in
          resolve(success)
      }
  }
  
  @objc(importCMPInfo:withResolver:withRejecter:)
  func importCMPInfo(_ cmpString: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.importCMPInfo(cmpString, completion: { success in resolve(success)})
          resolve(true)
  }
  
  @objc(resetConsentManagementData:withRejecter:)
  func resetConsentManagementData(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.resetConsentManagementData(completion: { success in resolve(success)})
      resolve(nil)
  }
  
  @objc(requestATTAuthorization:withRejecter:)
  func requestATTAuthorization(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      DispatchQueue.main.async { [weak self] in
          guard let self = self else {
              reject("ERROR", "Bridge object deallocated", nil)
              return
          }
          if #available(iOS 14, *) {
              self.cmpManager.requestATTAuthorization { status in
                  resolve(status.rawValue)
              }
          } else {
              reject("ERROR", "ATT is only available on iOS 14 and later", nil)
          }
      }
  }
  
  @objc(getATTAuthorizationStatus:withRejecter:)
  func getATTAuthorizationStatus(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      if #available(iOS 14, *) {
          let status = self.cmpManager.getATTAuthorizationStatus()
          resolve(status.rawValue)
      } else {
          reject("ERROR", "ATT is only available on iOS 14 and later", nil)
      }
  }
}
