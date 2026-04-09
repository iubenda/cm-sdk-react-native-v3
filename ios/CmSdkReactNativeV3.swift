import Foundation
import UIKit
import WebKit
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
    return ["didReceiveConsent", "didShowConsentLayer", "didCloseConsentLayer", "didReceiveError", "onClickLink", "didChangeATTStatus"]
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
    print("[CMP iOS] didReceiveConsent called")
    print("[CMP iOS] consent parameter length: \(consent.count)")
    print("[CMP iOS] consent first 60 chars: \(String(consent.prefix(60)))")
    if let firstChar = consent.first {
      print("[CMP iOS] consent first char: '\(firstChar)' code: \(firstChar.asciiValue ?? 0)")
    }
    if let lastChar = consent.last {
      print("[CMP iOS] consent last char: '\(lastChar)' code: \(lastChar.asciiValue ?? 0)")
    }
    print("[CMP iOS] jsonObject keys: \(jsonObject.keys)")
    if let cmpString = jsonObject["cmpString"] as? String {
      print("[CMP iOS] jsonObject.cmpString exists! Length: \(cmpString.count)")
      print("[CMP iOS] Are consent param and jsonObject.cmpString same? \(consent == cmpString)")
    }
    
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
      shouldHandleLinkClicks = false
      sendEventIfListening(name: "didCloseConsentLayer", body: nil)
    } else {
      print("CmSdkReactNativeV3: Ignoring didCloseConsentLayer - consent layer was not shown")
    }
  }

  @objc public func didReceiveError(error: String) {
    sendEventIfListening(name: "didReceiveError", body: ["error": error])
  }

  // MARK: - Configuration methods

  @objc(setWebViewConfig:resolve:reject:)
  func setWebViewConfig(_ config: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      runOnMainThread {
        let cornerRadius = CGFloat(config["cornerRadius"] as? Double ?? 5)
        let respectsSafeArea = config["respectsSafeArea"] as? Bool ?? true
        let allowsOrientationChanges = config["allowsOrientationChanges"] as? Bool ?? true
        let darkMode = config["darkMode"] as? Bool ?? false

        let position = self.mapPosition(config: config, respectsSafeArea: respectsSafeArea)
        let backgroundStyle = self.mapBackgroundStyle(config: config)

        let uiConfig = ConsentLayerUIConfig(
          position: position,
          backgroundStyle: backgroundStyle,
          cornerRadius: cornerRadius,
          respectsSafeArea: respectsSafeArea,
          allowsOrientationChanges: allowsOrientationChanges,
          darkMode: darkMode
        )

        self.cmpManager.setWebViewConfig(uiConfig)
        resolve(nil)
      }
  }

  private func mapPosition(config: [String: Any], respectsSafeArea: Bool) -> Position {
    if let positionValue = config["position"] as? String, positionValue == "custom",
       let rectValue = config["customRect"] as? [String: Any],
       let rect = rectFromDictionary(rectValue, respectsSafeArea: respectsSafeArea) {
      return .custom(rect)
    }

    let insets = currentSafeAreaInsets()
    let screenBounds = UIScreen.main.bounds
    let usableHeight = screenBounds.height - (respectsSafeArea ? (insets.top + insets.bottom) : 0)
    let halfHeight = usableHeight / 2

    guard let positionValue = config["position"] as? String else {
      return .fullScreen
    }

    switch positionValue {
    case "halfScreenTop":
      let originY = respectsSafeArea ? insets.top : 0
      return .custom(CGRect(x: 0, y: originY, width: screenBounds.width, height: halfHeight))
    case "halfScreenBottom":
      let originY = (respectsSafeArea ? insets.top : 0) + halfHeight
      return .custom(CGRect(x: 0, y: originY, width: screenBounds.width, height: halfHeight))
    default:
      return .fullScreen
    }
  }

  private func mapBackgroundStyle(config: [String: Any]) -> BackgroundStyle {
    guard let backgroundConfig = config["backgroundStyle"] as? [String: Any],
          let type = backgroundConfig["type"] as? String else {
      return .dimmed(.black, 0.5)
    }

    switch type {
    case "dimmed":
      let colorInput = backgroundConfig["color"] ?? "black"
      let color = RCTConvert.uiColor(colorInput) ?? .black
      let opacity = CGFloat(backgroundConfig["opacity"] as? Double ?? 0.5)
      return .dimmed(color, opacity)
    case "color":
      let colorInput = backgroundConfig["color"] ?? "black"
      let color = RCTConvert.uiColor(colorInput) ?? .black
      return .color(color)
    case "blur":
      let styleString = backgroundConfig["blurEffectStyle"] as? String ?? "dark"
      let blurStyle: UIBlurEffect.Style
      switch styleString {
      case "extraLight": blurStyle = .extraLight
      case "light": blurStyle = .light
      default: blurStyle = .dark
      }
      return .blur(blurStyle)
    case "none":
      return .none
    default:
      return .dimmed(.black, 0.5)
    }
  }

  private func rectFromDictionary(_ dict: [String: Any], respectsSafeArea: Bool) -> CGRect? {
    guard
      let x = dict["x"] as? Double,
      let y = dict["y"] as? Double,
      let width = dict["width"] as? Double,
      let height = dict["height"] as? Double
    else {
      return nil
    }

    let insets = respectsSafeArea ? currentSafeAreaInsets() : .zero
    return CGRect(
      x: CGFloat(x) + insets.left,
      y: CGFloat(y) + insets.top,
      width: CGFloat(width) - (insets.left + insets.right),
      height: CGFloat(height) - (insets.top + insets.bottom)
    )
  }

  private func currentSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    let work = {
      if #available(iOS 13.0, *) {
        let windowScene = UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .first { $0.activationState == .foregroundActive }
        let window = windowScene?.windows.first { $0.isKeyWindow }
        insets = window?.safeAreaInsets ?? .zero
      } else {
        insets = UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
      }
    }

    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.sync { work() }
    }

    return insets
  }

  @objc(setUrlConfig:resolve:reject:)
  func setUrlConfig(_ config: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    runOnMainThread { [self] in
          do {
              guard let id = config["id"] as? String,
                    let domain = config["domain"] as? String,
                    let language = config["language"] as? String,
                    let appName = config["appName"] as? String else {
                  throw NSError(domain: "CmSdkReactNativeV3", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid config parameters"])
              }
              let jsonConfig = config["jsonConfig"] as? String
              let noHash = config["noHash"] as? Bool ?? false
              let webViewConnectionTimeoutMillis = (config["webViewConnectionTimeoutMillis"] as? NSNumber)?.intValue ?? 3000
              let forceRegulation = config["forceRegulation"] as? String
              print("ID: \(id) - Domain: \(domain)")

              let urlConfig = UrlConfig(
                id: id,
                domain: domain,
                language: language,
                appName: appName,
                jsonConfig: jsonConfig,
                noHash: noHash,
                webViewConnectionTimeoutMillis: webViewConnectionTimeoutMillis,
                forceRegulation: forceRegulation
              )
              print("urlConfig = \(urlConfig)")
              self.cmpManager.setUrlConfig(urlConfig)
              resolve(nil)
          } catch {
              reject("ERROR", "Failed to set URL config: \(error.localizedDescription)", error)
          }
      }
  }

  // MARK: - New methods

  @objc(setATTStatus:resolve:reject:)
  func setATTStatus(_ status: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      cmpManager.setATTStatus(status.intValue)
      resolve(nil)
  }

  @objc(getUserStatus:reject:)
  func getUserStatus(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
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
  }

  @objc(isConsentRequired:reject:)
  func isConsentRequired(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    cmpManager.isConsentRequired { isRequired, error in
      if let error = error {
        reject("ERROR", "Failed to check if consent is required: \(error.localizedDescription)", error)
      } else {
        resolve(isRequired)
      }
    }
  }

  @objc(getStatusForPurpose:resolve:reject:)
  func getStatusForPurpose(_ purposeId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let status = cmpManager.getStatusForPurpose(id: purposeId)
      resolve(stringValue(for: status))
  }

  @objc(getStatusForVendor:resolve:reject:)
  func getStatusForVendor(_ vendorId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let status = cmpManager.getStatusForVendor(id: vendorId)
      resolve(stringValue(for: status))
  }

  @objc(getGoogleConsentModeStatus:reject:)
  func getGoogleConsentModeStatus(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let status = cmpManager.getGoogleConsentModeStatus()
      resolve(status)
  }

  @objc(checkAndOpen:resolve:reject:)
  func checkAndOpen(_ jumpToSettings: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      runOnMainThread {
        self.updatePresentingViewControllerIfNeeded()
        self.cmpManager.checkAndOpen(jumpToSettings: jumpToSettings) { error in
            if let error = error {
                reject("ERROR", "Failed to check and open: \(error.localizedDescription)", error)
            } else {
                resolve(true)
            }
        }
      }
  }

  @objc(forceOpen:resolve:reject:)
  func forceOpen(_ jumpToSettings: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      runOnMainThread {
        self.updatePresentingViewControllerIfNeeded()
        self.cmpManager.forceOpen(jumpToSettings: jumpToSettings) { error in
            if let error = error {
                reject("ERROR", "Failed to force open: \(error.localizedDescription)", error)
            } else {
                resolve(true)
            }
        }
      }
  }

  @objc(exportCMPInfo:reject:)
  func exportCMPInfo(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      let info = self.cmpManager.exportCMPInfo()
      resolve(info)
  }

  @objc(acceptVendors:resolve:reject:)
  func acceptVendors(_ vendors: [String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.acceptVendors(vendors) { error in
        self.resolveBooleanCompletion(error: error, successMessage: "Failed to accept vendors", resolve: resolve, reject: reject)
      }
  }

  @objc(rejectVendors:resolve:reject:)
  func rejectVendors(_ vendors: [String], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.rejectVendors(vendors) { error in
        self.resolveBooleanCompletion(error: error, successMessage: "Failed to reject vendors", resolve: resolve, reject: reject)
      }
  }

  @objc(acceptPurposes:updatePurpose:resolve:reject:)
  func acceptPurposes(_ purposes: [String], updatePurpose: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.acceptPurposes(purposes, updatePurpose: updatePurpose) { error in
        self.resolveBooleanCompletion(error: error, successMessage: "Failed to accept purposes", resolve: resolve, reject: reject)
      }
  }

  @objc(rejectPurposes:updateVendor:resolve:reject:)
  func rejectPurposes(_ purposes: [String], updateVendor: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.rejectPurposes(purposes, updateVendor: updateVendor) { error in
        self.resolveBooleanCompletion(error: error, successMessage: "Failed to reject purposes", resolve: resolve, reject: reject)
      }
  }

  @objc(rejectAll:reject:)
  func rejectAll(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.cmpManager.rejectAll { error in
       if let error = error {
           reject("ERROR", "Failed to reject all: \(error.localizedDescription)", error)
       } else {
           resolve(true)
       }
     }
  }

  @objc(acceptAll:reject:)
  func acceptAll(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.cmpManager.acceptAll { error in
      if let error = error {
         reject("ERROR", "Failed to accept all: \(error.localizedDescription)", error)
      } else {
         resolve(true)
      }
    }
  }

  @objc(importCMPInfo:resolve:reject:)
  func importCMPInfo(_ cmpString: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.importCMPInfo(cmpString) { error in
         if let error = error {
             reject("ERROR", "Failed to import CMP info: \(error.localizedDescription)", error)
         } else {
             resolve(true)
         }
     }
  }

  @objc(resetConsentManagementData:reject:)
  func resetConsentManagementData(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      self.cmpManager.resetConsentManagementData { error in
        if let error = error {
          reject("ERROR", "Failed to reset consent management data: \(error.localizedDescription)", error)
          return
        }

        self.clearWebViewData {
          resolve(true)
        }
      }
  }

  @objc(configureAutomaticFirebaseConsentUpdates:resolve:reject:)
  func configureAutomaticFirebaseConsentUpdates(_ enabled: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    CMPManager.configureAutomaticFirebaseConsentUpdates(enabled)
    resolve(nil)
  }

  @objc(setAutomaticFirebaseConsentUpdatesEnabled:resolve:reject:)
  func setAutomaticFirebaseConsentUpdatesEnabled(_ enabled: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    cmpManager.setAutomaticFirebaseConsentUpdatesEnabled(enabled)
    resolve(nil)
  }

  @objc(isAutomaticFirebaseConsentUpdatesEnabled:reject:)
  func isAutomaticFirebaseConsentUpdatesEnabled(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    resolve(cmpManager.isAutomaticFirebaseConsentUpdatesEnabled())
  }

  @objc(updateFirebaseConsent:reject:)
  func updateFirebaseConsent(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    resolve(cmpManager.updateFirebaseConsent())
  }

  @objc(isFirebaseAnalyticsAvailable:reject:)
  func isFirebaseAnalyticsAvailable(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    resolve(cmpManager.isFirebaseAnalyticsAvailable())
  }

  // MARK: - Event emitter methods
  
  @objc(addListener:)
  override func addListener(_ eventName: String) {
    super.addListener(eventName)
  }
  
  @objc(removeListeners:)
  override func removeListeners(_ count: Double) {
    super.removeListeners(Double(Int(count)))
  }

  private func clearWebViewData(completion: @escaping () -> Void) {
    let dataStore = WKWebsiteDataStore.default()
    let types = WKWebsiteDataStore.allWebsiteDataTypes()
    let domainsToClear = [
      "consentmanager.net",
      "delivery.consentmanager.net",
      "a.delivery.consentmanager.net"
    ]

    DispatchQueue.main.async {
      dataStore.fetchDataRecords(ofTypes: types) { records in
        let toDelete = records.filter { record in
          domainsToClear.contains { domain in
            record.displayName.contains(domain)
          }
        }

        let deleteAndComplete = {
          self.clearCookiesForDomains(domainsToClear)
          completion()
        }

        guard !toDelete.isEmpty else {
          deleteAndComplete()
          return
        }

        dataStore.removeData(ofTypes: types, for: toDelete) {
          deleteAndComplete()
        }
      }
    }
  }

  private func clearCookiesForDomains(_ domains: [String]) {
    let cookieStorage = HTTPCookieStorage.shared
    cookieStorage.cookies?.forEach { cookie in
      if domains.contains(where: { domain in cookie.domain.contains(domain) }) {
        cookieStorage.deleteCookie(cookie)
      }
    }
  }

  private func stringValue(for status: UniqueConsentStatus) -> String {
    switch status {
    case .choiceDoesntExist:
      return "choiceDoesntExist"
    case .granted:
      return "granted"
    case .denied:
      return "denied"
    @unknown default:
      return "choiceDoesntExist"
    }
  }

  private func resolveBooleanCompletion(
    error: NSError?,
    successMessage: String,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    if let error = error {
      reject("ERROR", "\(successMessage): \(error.localizedDescription)", error)
    } else {
      resolve(true)
    }
  }

  private func updatePresentingViewControllerIfNeeded() {
    if let viewController = currentPresentingViewController() {
      cmpManager.setPresentingViewController(viewController)
    }
  }

  private func currentPresentingViewController() -> UIViewController? {
    if #available(iOS 13.0, *) {
      let windowScene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
      let rootViewController = windowScene?.windows.first { $0.isKeyWindow }?.rootViewController
      return topMostViewController(from: rootViewController)
    }

    return topMostViewController(from: UIApplication.shared.keyWindow?.rootViewController)
  }

  private func topMostViewController(from rootViewController: UIViewController?) -> UIViewController? {
    var current = rootViewController
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }
}
