import Flutter
import MapKit

enum LadeparkPlatformChannels {
  private static var channel: FlutterMethodChannel?
  private static var pendingLocation: [String: Double]?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "de.ladeparkexplorer/platform",
      binaryMessenger: messenger
    )
    self.channel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "resolveDatasetPath":
        resolveDatasetPath(call.arguments, result: result)
      case "openAppleMapsDirections":
        openAppleMapsDirections(call.arguments, result: result)
      case "isGoogleMapsAvailable":
        result(UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!))
      case "openGoogleMapsDirections":
        openGoogleMapsDirections(call.arguments, result: result)
      case "takePendingLocation":
        result(pendingLocation)
        pendingLocation = nil
      case "geocodePlace":
        geocodePlace(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func geocodePlace(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let query = values["query"] as? String,
      !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      result(FlutterError(code: "invalid_place_query", message: nil, details: nil))
      return
    }
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.resultTypes = .address
    request.region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
      span: MKCoordinateSpan(latitudeDelta: 8.8, longitudeDelta: 12.5)
    )
    MKLocalSearch(request: request).start { response, error in
      guard error == nil, let items = response?.mapItems else {
        result(FlutterError(code: "place_search_unavailable", message: nil, details: nil))
        return
      }
      let item = items.first(where: { $0.placemark.countryCode == "DE" }) ?? items.first
      guard let coordinate = item?.placemark.coordinate else {
        result(nil)
        return
      }
      result([
        "latitude": coordinate.latitude,
        "longitude": coordinate.longitude,
      ])
    }
  }

  static func receiveLocationURL(_ url: URL) -> Bool {
    guard let location = parseLocationURL(url) else { return false }
    pendingLocation = location
    channel?.invokeMethod("locationReceived", arguments: location)
    return true
  }

  private static func parseLocationURL(_ url: URL) -> [String: Double]? {
    guard url.scheme?.lowercased() == "ladeparkexplorer" else { return nil }
    guard
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let latitudeText = components.queryItems?.first(where: { $0.name == "lat" })?.value,
      let longitudeText = components.queryItems?.first(where: { $0.name == "lon" })?.value,
      let latitude = Double(latitudeText),
      let longitude = Double(longitudeText),
      (-90...90).contains(latitude),
      (-180...180).contains(longitude)
    else { return nil }
    return ["latitude": latitude, "longitude": longitude]
  }

  private static func resolveDatasetPath(_ arguments: Any?, result: FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let preferred = values["preferred"] as? String,
      let fallback = values["fallback"] as? String
    else {
      result(FlutterError(code: "invalid_dataset_request", message: nil, details: nil))
      return
    }
    for assetPath in [preferred, fallback] {
      let path = Bundle.main.bundleURL
        .appendingPathComponent("Frameworks/App.framework/flutter_assets")
        .appendingPathComponent(assetPath)
        .path
      if FileManager.default.fileExists(atPath: path) {
        result(path)
        return
      }
    }
    result(
      FlutterError(
        code: "dataset_not_found",
        message: "Kein gebündelter Ladepark-Datensatz gefunden.",
        details: nil
      )
    )
  }

  private static func openAppleMapsDirections(_ arguments: Any?, result: FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let latitude = values["latitude"] as? Double,
      let longitude = values["longitude"] as? Double
    else {
      result(FlutterError(code: "invalid_navigation_target", message: nil, details: nil))
      return
    }
    let placemark = MKPlacemark(
      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    )
    let destination = MKMapItem(placemark: placemark)
    destination.name = values["name"] as? String ?? "Ladepark"
    destination.openInMaps(
      launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    )
    result(nil)
  }

  private static func openGoogleMapsDirections(
    _ arguments: Any?,
    result: @escaping FlutterResult
  ) {
    guard
      let values = arguments as? [String: Any],
      let latitude = values["latitude"] as? Double,
      let longitude = values["longitude"] as? Double,
      var components = URLComponents(string: "comgooglemaps://")
    else {
      result(FlutterError(code: "invalid_navigation_target", message: nil, details: nil))
      return
    }
    components.queryItems = [
      URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"),
      URLQueryItem(name: "directionsmode", value: "driving"),
    ]
    guard
      let url = components.url,
      UIApplication.shared.canOpenURL(url)
    else {
      result(FlutterError(code: "google_maps_unavailable", message: nil, details: nil))
      return
    }
    UIApplication.shared.open(url, options: [:]) { success in
      if success {
        result(nil)
      } else {
        result(FlutterError(code: "google_maps_open_failed", message: nil, details: nil))
      }
    }
  }
}
