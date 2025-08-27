import Foundation
import cm_sdk_ios_v3
import React

@objc(CmSdkReactNativeV3)
class CmSdkReactNativeV3: RCTEventEmitter, CMPManagerDelegate {
  func didChangeATTStatus(oldStatus: Int, newStatus: Int, lastUpdated: Date?) {
    sendEventIfListening(name: "didChangeATTStatus", body: [
      "oldStatus": oldStatus,
      "newStatus": newStatus,
      "lastUpdated": lastUpdated?.timeIntervalSince1970 ?? 0
    ])
  }

  private let cmpManager: CMPManager
  private var hasListeners: Bool = false
  private var isConsentLayerShown: Bool = false
  private var shouldHandleLinkClicks: Bool = false

  override init() {
    self.cmpManager = CMPManager.shared
    super.init()
    self.cmpManager.delegate = self

    self.cmpManager.setLinkClickHandler { [weak self] url in
      let urlString = url.absoluteString

      guard let strongSelf = self, strongSelf.shouldHandleLinkClicks else {
        print("CmSdkReactNativeV3: Allowing navigation during SDK initialization: \(urlString)")
        return false
      }

      print("CmSdkReactNativeV3: Link clicked: \(urlString)")
      strongSelf.sendEventIfListening(name: "onClickLink", body: ["url": urlString])

      if !urlString.contains("google.com") ||
         urlString.contains("privacy") ||
         urlString.contains("terms") {
        return true
      } else {
        return false
      }
    }
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  override func supportedEvents() -> [String]! {
    return ["didReceiveConsent", "didShowConsentLayer", "didCloseConsentLayer", "didReceiveError", "onClickLink"]
  }

  override func startObserving() {
    hasListeners = true
  }

  override func stopObserving() {
    hasListeners = false
  }

  private func sendEventIfListening(name: String, body: [String: Any]?) {
    if hasListeners {
      self.sendEvent(withName: name, body: body)
    }
  }

  private func runOnMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync(execute: block)
    }
  }

  // MARK: - CMPManagerDelegate methods

  @objc public func didReceiveConsent(consent: String, jsonObject: [String: Any]) {
    sendEventIfListening(name: "didReceiveConsent", body: [
      "consent": consent,
      "jsonObject": jsonObject
    ])
  }

  @objc public func didShowConsentLayer() {
    isConsentLayerShown = true
    shouldHandleLinkClicks = true
    sendEventIfListening(name: "didShowConsentLayer", body: nil)
  }

  @objc public func didCloseConsentLayer() {
    if isConsentLayerShown {
      isConsentLayerShown = false
      sendEventIfListening(name: "didCloseConsentLayer", body: nil)
    } else {
      print("CmSdkReactNativeV3: Ignoring didCloseConsentLayer - consent layer was not shown")
    }
  }

  @objc public func didReceiveError(error: String) {
    sendEventIfListening(name: "didReceiveError", body: ["error": error])
  }

  // MARK: - Configuration methods

  @objc(setWebViewConfig:withResolver:withRejecter:)
  func setWebViewConfig(_ config: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let uiConfig = ConsentLayerUIConfig(
        position: .fullScreen,
        backgroundStyle: .dimmed(.black, 0.5),
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

  // MARK: - New methods

  @objc(getUserStatus:withRejecter:)
  func getUserStatus(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      do {
          let status = cmpManager.getUserStatus()
          let response: [String: Any] = [
              "status": status.status,
              "vendors": status.vendors,
              "purposes": status.purposes,
              "tcf": status.tcf,
              "addtlConsent": status.addtlConsent,
              "regulation": status.regulation
          ]
          resolve(response)
      } catch {
          reject("ERROR", "Failed to get user status: \(error.localizedDescription)", error)
      }
  }

  @objc(getStatusForPurpose:withResolver:withRejecter:)
  func getStatusForPurpose(_ purposeId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let status = cmpManager.getStatusForPurpose(id: purposeId)
      resolve(status.rawValue)
  }

  @objc(getStatusForVendor:withResolver:withRejecter:)
  func getStatusForVendor(_ vendorId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let status = cmpManager.getStatusForVendor(id: vendorId)
      resolve(status.rawValue)
  }

  @objc(getGoogleConsentModeStatus:withRejecter:)
  func getGoogleConsentModeStatus(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let status = cmpManager.getGoogleConsentModeStatus()
      resolve(status)
  }

  @objc(checkAndOpen:withResolver:withRejecter:)
  func checkAndOpen(_ jumpToSettings: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      cmpManager.checkAndOpen(jumpToSettings: jumpToSettings) { error in
          if let error = error {
              reject("ERROR", "Failed to check and open: \(error.localizedDescription)", error)
          } else {
              resolve(true)
          }
      }
  }

  @objc(forceOpen:withResolver:withRejecter:)
  func forceOpen(_ jumpToSettings: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      cmpManager.forceOpen(jumpToSettings: jumpToSettings) { error in
          if let error = error {
              reject("ERROR", "Failed to force open: \(error.localizedDescription)", error)
          } else {
              resolve(true)
          }
      }
  }

  // MARK: - Deprecated but maintained methods

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
    self.cmpManager.rejectAll { error in
       if let error = error {
           reject("ERROR", "Failed to reject all: \(error.localizedDescription)", error)
       } else {
           resolve(true)
       }
     }
  }

  @objc(acceptAll:withRejecter:)
  func acceptAll(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.cmpManager.acceptAll { error in
      if let error = error {
         reject("ERROR", "Failed to accept all: \(error.localizedDescription)", error)
      } else {
         resolve(true)
      }
    }
  }

  @objc(importCMPInfo:withResolver:withRejecter:)
  func importCMPInfo(_ cmpString: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.importCMPInfo(cmpString) { error in
         if let error = error {
             reject("ERROR", "Failed to import CMP info: \(error.localizedDescription)", error)
         } else {
             resolve(true)
         }
     }
  }

  @objc(resetConsentManagementData:withRejecter:)
  func resetConsentManagementData(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.resetConsentManagementData(completion: { success in resolve(success)})
      resolve(nil)
  }
}
