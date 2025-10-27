import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.technophere.kpass/cookies", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getCookiesForUrl":
        guard let args = call.arguments as? [String: Any], let urlStr = args["url"] as? String, let url = URL(string: urlStr) else {
          result(FlutterError(code: "ARG_ERROR", message: "url is required", details: nil))
          return
        }
        if #available(iOS 11.0, *) {
          let dataStore = WKWebsiteDataStore.default()
          dataStore.httpCookieStore.getAllCookies { cookies in
            // Return all cookies unfiltered to ensure HttpOnly/secure cookies are included
            let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            result(cookieHeader)
          }
        } else {
          result("")
        }
      case "httpGet":
        guard let args = call.arguments as? [String: Any], let urlStr = args["url"] as? String, let url = URL(string: urlStr) else {
          result(FlutterError(code: "ARG_ERROR", message: "url is required", details: nil))
          return
        }
        if #available(iOS 11.0, *) {
          let dataStore = WKWebsiteDataStore.default()
          dataStore.httpCookieStore.getAllCookies { cookies in
            // Inject cookies into shared storage for URLSession
            let shared = HTTPCookieStorage.shared
            for c in cookies {
              shared.setCookie(c)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
              if let error = error {
                result(FlutterError(code: "HTTP_ERROR", message: error.localizedDescription, details: nil))
                return
              }
              guard let http = response as? HTTPURLResponse else {
                result(FlutterError(code: "HTTP_ERROR", message: "No response", details: nil))
                return
              }
              let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
              result(["status": http.statusCode, "body": body])
            }
            task.resume()
          }
        } else {
          result(FlutterError(code: "UNSUPPORTED", message: "iOS < 11 not supported", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
