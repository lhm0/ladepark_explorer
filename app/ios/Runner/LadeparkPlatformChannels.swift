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
      case "openAppleMapsRoute":
        openAppleMapsRoute(call.arguments, result: result)
      case "isGoogleMapsAvailable":
        result(UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!))
      case "openGoogleMapsDirections":
        openGoogleMapsDirections(call.arguments, result: result)
      case "openGoogleMapsRoute":
        openGoogleMapsRoute(call.arguments, result: result)
      case "takePendingLocation":
        result(pendingLocation)
        pendingLocation = nil
      case "geocodePlace":
        geocodePlace(call.arguments, result: result)
      case "planRoute":
        planRoute(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Route planning (FR-ROUTE-001, FR-ROUTE-002; ADR-0019)

  private enum RouteErrorCode: Error {
    case offline, throttled, notFound, failed

    var channelCode: String {
      switch self {
      case .offline: return "route_offline"
      case .throttled: return "route_throttled"
      case .notFound: return "route_not_found"
      case .failed: return "route_failed"
      }
    }
  }

  private static func planRoute(_ arguments: Any?, result: @escaping FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let origin = routeCoordinate(from: values["origin"]),
      let destination = routeCoordinate(from: values["destination"])
    else {
      result(FlutterError(code: "route_invalid_request", message: nil, details: nil))
      return
    }
    let intermediates = (values["waypoints"] as? [[String: Any]])?
      .compactMap { routeCoordinate(from: $0) } ?? []
    let includeAlternatives = values["includeAlternatives"] as? Bool ?? false
    let stops = [origin] + intermediates + [destination]
    var pairs: [(CLLocationCoordinate2D, CLLocationCoordinate2D)] = []
    for index in 0..<(stops.count - 1) {
      pairs.append((stops[index], stops[index + 1]))
    }

    // Alternatives are only meaningful for a single origin-to-destination leg.
    if pairs.count == 1, includeAlternatives {
      calculateLeg(pairs[0], alternatives: true) { outcome in
        switch outcome {
        case .failure(let code):
          result(FlutterError(code: code.channelCode, message: nil, details: nil))
        case .success(let routes):
          result(routes.map { routeOption(from: [$0]) })
        }
      }
      return
    }

    calculateLegs(pairs, collected: []) { outcome in
      switch outcome {
      case .failure(let code):
        result(FlutterError(code: code.channelCode, message: nil, details: nil))
      case .success(let routes):
        result([routeOption(from: routes)])
      }
    }
  }

  private static func calculateLegs(
    _ pairs: [(CLLocationCoordinate2D, CLLocationCoordinate2D)],
    collected: [MKRoute],
    completion: @escaping (Result<[MKRoute], RouteErrorCode>) -> Void
  ) {
    guard let next = pairs.first else {
      completion(.success(collected))
      return
    }
    calculateLeg(next, alternatives: false) { outcome in
      switch outcome {
      case .failure(let code):
        completion(.failure(code))
      case .success(let routes):
        guard let route = routes.first else {
          completion(.failure(.notFound))
          return
        }
        calculateLegs(
          Array(pairs.dropFirst()),
          collected: collected + [route],
          completion: completion
        )
      }
    }
  }

  private static func calculateLeg(
    _ pair: (CLLocationCoordinate2D, CLLocationCoordinate2D),
    alternatives: Bool,
    completion: @escaping (Result<[MKRoute], RouteErrorCode>) -> Void
  ) {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: pair.0))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: pair.1))
    request.transportType = .automobile
    request.requestsAlternateRoutes = alternatives
    MKDirections(request: request).calculate { response, error in
      if let error {
        completion(.failure(classifyRouteError(error)))
        return
      }
      guard let routes = response?.routes, !routes.isEmpty else {
        completion(.failure(.notFound))
        return
      }
      completion(.success(routes))
    }
  }

  private static func classifyRouteError(_ error: Error) -> RouteErrorCode {
    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
      return .offline
    }
    if nsError.domain == MKError.errorDomain,
      let raw = UInt(exactly: nsError.code),
      let code = MKError.Code(rawValue: raw)
    {
      switch code {
      case .loadingThrottled:
        return .throttled
      case .placemarkNotFound, .directionsNotFound:
        return .notFound
      default:
        return .failed
      }
    }
    return .failed
  }

  private static func routeOption(from routes: [MKRoute]) -> [String: Any] {
    var coordinates: [CLLocationCoordinate2D] = []
    var legs: [[String: Any]] = []
    var totalDistance = 0.0
    var totalTime = 0.0
    for route in routes {
      let routeCoordinates = polylineCoordinates(route.polyline)
      legs.append([
        "startLatitude": routeCoordinates.first?.latitude ?? 0,
        "startLongitude": routeCoordinates.first?.longitude ?? 0,
        "endLatitude": routeCoordinates.last?.latitude ?? 0,
        "endLongitude": routeCoordinates.last?.longitude ?? 0,
        "distanceKm": route.distance / 1000.0,
        "travelTimeSeconds": route.expectedTravelTime,
      ])
      totalDistance += route.distance
      totalTime += route.expectedTravelTime
      coordinates.append(contentsOf: routeCoordinates)
    }
    let simplified = decimate(coordinates, tolerance: 0.00015, limit: 500)
    let latitudes = simplified.map { $0.latitude }
    let longitudes = simplified.map { $0.longitude }
    return [
      "totalDistanceKm": totalDistance / 1000.0,
      "totalTravelTimeSeconds": totalTime,
      "bounds": [
        "south": latitudes.min() ?? 0,
        "west": longitudes.min() ?? 0,
        "north": latitudes.max() ?? 0,
        "east": longitudes.max() ?? 0,
      ],
      "polyline": simplified.map {
        ["latitude": $0.latitude, "longitude": $0.longitude]
      },
      "legs": legs,
    ]
  }

  private static func polylineCoordinates(_ polyline: MKPolyline) -> [CLLocationCoordinate2D] {
    var coordinates = [CLLocationCoordinate2D](
      repeating: kCLLocationCoordinate2DInvalid,
      count: polyline.pointCount
    )
    polyline.getCoordinates(
      &coordinates,
      range: NSRange(location: 0, length: polyline.pointCount)
    )
    return coordinates
  }

  /// Douglas–Peucker simplification with a hard point cap. Keeps the polyline
  /// small enough for the method channel and the later corridor search.
  private static func decimate(
    _ points: [CLLocationCoordinate2D],
    tolerance: Double,
    limit: Int
  ) -> [CLLocationCoordinate2D] {
    guard points.count > 2 else { return points }
    var keep = [Bool](repeating: false, count: points.count)
    keep[0] = true
    keep[points.count - 1] = true
    var stack: [(Int, Int)] = [(0, points.count - 1)]
    while let (start, end) = stack.popLast() {
      guard end > start + 1 else { continue }
      var maxDistance = 0.0
      var farthest = start
      for index in (start + 1)..<end {
        let distance = perpendicularDistance(points[index], points[start], points[end])
        if distance > maxDistance {
          maxDistance = distance
          farthest = index
        }
      }
      if maxDistance > tolerance {
        keep[farthest] = true
        stack.append((start, farthest))
        stack.append((farthest, end))
      }
    }
    var result = points.enumerated().filter { keep[$0.offset] }.map { $0.element }
    if result.count > limit {
      let stride = Int(ceil(Double(result.count) / Double(limit)))
      var thinned = result.enumerated()
        .filter { $0.offset % stride == 0 }
        .map { $0.element }
      if let last = result.last,
        thinned.last?.latitude != last.latitude
          || thinned.last?.longitude != last.longitude
      {
        thinned.append(last)
      }
      result = thinned
    }
    return result
  }

  private static func perpendicularDistance(
    _ point: CLLocationCoordinate2D,
    _ lineStart: CLLocationCoordinate2D,
    _ lineEnd: CLLocationCoordinate2D
  ) -> Double {
    let dx = lineEnd.longitude - lineStart.longitude
    let dy = lineEnd.latitude - lineStart.latitude
    let length = hypot(dx, dy)
    if length == 0 {
      return hypot(
        point.longitude - lineStart.longitude,
        point.latitude - lineStart.latitude
      )
    }
    let cross = abs(
      dx * (lineStart.latitude - point.latitude)
        - (lineStart.longitude - point.longitude) * dy
    )
    return cross / length
  }

  private static func routeCoordinate(from value: Any?) -> CLLocationCoordinate2D? {
    guard
      let values = value as? [String: Any],
      let latitude = values["latitude"] as? Double,
      let longitude = values["longitude"] as? Double
    else { return nil }
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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

  // MARK: - Handing the planned route to a navigation app (FR-ROUTE-011)

  private static func coordinate(from value: Any?) -> CLLocationCoordinate2D? {
    guard
      let map = value as? [String: Any],
      let latitude = map["latitude"] as? Double,
      let longitude = map["longitude"] as? Double
    else { return nil }
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  private static func openAppleMapsRoute(_ arguments: Any?, result: FlutterResult) {
    guard
      let values = arguments as? [String: Any],
      let rawWaypoints = values["waypoints"] as? [[String: Any]],
      rawWaypoints.count >= 2
    else {
      result(FlutterError(code: "invalid_navigation_target", message: nil, details: nil))
      return
    }
    let items: [MKMapItem] = rawWaypoints.compactMap { raw in
      guard let point = coordinate(from: raw) else { return nil }
      let item = MKMapItem(placemark: MKPlacemark(coordinate: point))
      item.name = raw["name"] as? String
      return item
    }
    guard items.count >= 2 else {
      result(FlutterError(code: "invalid_navigation_target", message: nil, details: nil))
      return
    }
    MKMapItem.openMaps(
      with: items,
      launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    )
    result(nil)
  }

  private static func openGoogleMapsRoute(
    _ arguments: Any?,
    result: @escaping FlutterResult
  ) {
    guard
      let values = arguments as? [String: Any],
      let origin = coordinate(from: values["origin"]),
      let destination = coordinate(from: values["destination"]),
      var components = URLComponents(string: "comgooglemaps://")
    else {
      result(FlutterError(code: "invalid_navigation_target", message: nil, details: nil))
      return
    }
    components.queryItems = [
      URLQueryItem(name: "saddr", value: "\(origin.latitude),\(origin.longitude)"),
      URLQueryItem(
        name: "daddr",
        value: "\(destination.latitude),\(destination.longitude)"
      ),
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
