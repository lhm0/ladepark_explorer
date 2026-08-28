import Flutter
import CoreLocation
import MapKit
import UIKit

final class LadeparkMapViewFactory: NSObject, FlutterPlatformViewFactory {
  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  private let messenger: FlutterBinaryMessenger

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LadeparkMapView(
      frame: frame,
      viewId: viewId,
      arguments: args as? [String: Any],
      messenger: messenger
    )
  }
}

final class LadeparkMapView: NSObject, FlutterPlatformView, MKMapViewDelegate,
  CLLocationManagerDelegate
{
  init(
    frame: CGRect,
    viewId: Int64,
    arguments: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    mapView = MKMapView(frame: frame)
    channel = FlutterMethodChannel(
      name: "de.ladeparkexplorer/map/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()
    mapView.delegate = self
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    mapView.isScrollEnabled = true
    mapView.isZoomEnabled = true
    mapView.isRotateEnabled = true
    mapView.isPitchEnabled = true
    mapView.register(
      MKMarkerAnnotationView.self,
      forAnnotationViewWithReuseIdentifier: Self.groupReuseIdentifier
    )
    mapView.register(
      MKMarkerAnnotationView.self,
      forAnnotationViewWithReuseIdentifier: Self.routeStopReuseIdentifier
    )
    mapView.register(
      MKMarkerAnnotationView.self,
      forAnnotationViewWithReuseIdentifier: Self.corridorReuseIdentifier
    )
    configureInitialRegion(arguments)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private static let groupReuseIdentifier = "charging-group"
  private static let routeStopReuseIdentifier = "route-stop"
  private static let corridorReuseIdentifier = "route-corridor"
  private let mapView: MKMapView
  private let channel: FlutterMethodChannel
  private let locationManager = CLLocationManager()
  private var groupsById: [String: ChargingGroupAnnotation] = [:]
  private var pendingLocationResult: FlutterResult?
  private var pendingRadiusKm = 25.0
  private var routeOverlay: MKPolyline?
  private var routeSegmentOverlays: [(polyline: MKPolyline, colour: UIColor)] = []
  private var routeStopAnnotations: [RouteStopAnnotation] = []
  private var corridorAnnotations: [CorridorParkAnnotation] = []

  func view() -> UIView {
    mapView
  }

  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    sendVisibleBounds()
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let cluster = view.annotation as? MKClusterAnnotation {
      mapView.showAnnotations(cluster.memberAnnotations, animated: true)
      mapView.deselectAnnotation(cluster, animated: false)
      return
    }
    if let park = view.annotation as? CorridorParkAnnotation {
      mapView.deselectAnnotation(park, animated: false)
      let groupId = park.groupId
      DispatchQueue.main.async { [weak self] in
        self?.channel.invokeMethod("corridorParkSelected", arguments: groupId)
      }
      return
    }
    if let stop = view.annotation as? RouteStopAnnotation {
      mapView.deselectAnnotation(stop, animated: false)
      let groupId = stop.groupId
      DispatchQueue.main.async { [weak self] in
        self?.channel.invokeMethod("routeStopSelected", arguments: groupId)
      }
      return
    }
    guard let group = view.annotation as? ChargingGroupAnnotation else { return }
    mapView.deselectAnnotation(group, animated: false)
    let groupId = group.groupId
    DispatchQueue.main.async { [weak self] in
      self?.channel.invokeMethod("groupSelected", arguments: groupId)
    }
  }

  func mapView(
    _ mapView: MKMapView,
    viewFor annotation: MKAnnotation
  ) -> MKAnnotationView? {
    if let stop = annotation as? RouteStopAnnotation {
      let view = mapView.dequeueReusableAnnotationView(
        withIdentifier: Self.routeStopReuseIdentifier,
        for: stop
      ) as! MKMarkerAnnotationView
      view.annotation = stop
      view.markerTintColor = .systemBlue
      view.glyphText = "\(stop.number)"
      view.clusteringIdentifier = nil
      view.displayPriority = .required
      view.zPriority = .max
      return view
    }
    if let park = annotation as? CorridorParkAnnotation {
      let view = mapView.dequeueReusableAnnotationView(
        withIdentifier: Self.corridorReuseIdentifier,
        for: park
      ) as! MKMarkerAnnotationView
      view.annotation = park
      view.markerTintColor = .systemOrange
      view.glyphImage = UIImage(systemName: "bolt.fill")
      view.clusteringIdentifier = nil
      view.displayPriority = .required
      return view
    }
    if annotation is MKClusterAnnotation {
      return nil
    }
    guard let group = annotation as? ChargingGroupAnnotation else { return nil }
    let view = mapView.dequeueReusableAnnotationView(
      withIdentifier: Self.groupReuseIdentifier,
      for: group
    ) as! MKMarkerAnnotationView
    view.annotation = group
    configure(view, for: group)
    return view
  }

  private func configure(
    _ view: MKMarkerAnnotationView,
    for group: ChargingGroupAnnotation
  ) {
    if group.isFavorite {
      view.clusteringIdentifier = nil
      view.zPriority = .max
      view.markerTintColor = .systemGreen
      view.glyphImage = UIImage(systemName: "bolt.heart.fill")
        ?? UIImage(systemName: "heart.fill")
      view.displayPriority = .required
    } else {
      view.clusteringIdentifier = "charging-group-cluster"
      view.zPriority = .defaultUnselected
      view.markerTintColor = group.hpcEvseCount > 0 ? .systemGreen : .systemTeal
      view.glyphImage = UIImage(systemName: "bolt.fill")
      view.displayPriority = group.hpcEvseCount > 0 ? .required : .defaultHigh
    }
  }

  private func configureInitialRegion(
    _ arguments: [String: Any]?,
    animated: Bool = false
  ) {
    let center = CLLocationCoordinate2D(
      latitude: arguments?["latitude"] as? Double ?? 51.1657,
      longitude: arguments?["longitude"] as? Double ?? 10.4515
    )
    let span = MKCoordinateSpan(
      latitudeDelta: arguments?["latitudeDelta"] as? Double ?? 8.8,
      longitudeDelta: arguments?["longitudeDelta"] as? Double ?? 12.5
    )
    mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: animated)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showGroups":
      guard let groups = call.arguments as? [[String: Any]] else {
        result(FlutterError(code: "invalid_groups", message: nil, details: nil))
        return
      }
      updateGroups(groups)
      result(nil)
    case "requestVisibleBounds":
      sendVisibleBounds()
      result(nil)
    case "focusUserLocation":
      requestUserLocation(call.arguments, result: result)
    case "focusCoordinate":
      guard
        let values = call.arguments as? [String: Any],
        let latitude = values["latitude"] as? Double,
        let longitude = values["longitude"] as? Double,
        let radiusKm = values["radiusKm"] as? Double
      else {
        result(FlutterError(code: "invalid_coordinate", message: nil, details: nil))
        return
      }
      show(
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        radiusKm: radiusKm,
        animated: true
      )
      result(nil)
    case "showGermanyOverview":
      configureInitialRegion(nil, animated: true)
      result(nil)
    case "showRoute":
      guard
        let values = call.arguments as? [String: Any],
        let rawPoints = values["polyline"] as? [[String: Any]]
      else {
        result(FlutterError(code: "invalid_route", message: nil, details: nil))
        return
      }
      showRoute(
        rawPoints.compactMap(routeCoordinate(from:)),
        segmentColors: (values["segmentColors"] as? [Any])?.compactMap {
          ($0 as? NSNumber)?.int64Value
        },
        fit: (values["fit"] as? Bool) ?? true
      )
      result(nil)
    case "showRouteStops":
      guard
        let values = call.arguments as? [String: Any],
        let rawStops = values["stops"] as? [[String: Any]]
      else {
        result(FlutterError(code: "invalid_route_stops", message: nil, details: nil))
        return
      }
      showRouteStops(rawStops)
      result(nil)
    case "showRouteCorridor":
      guard
        let values = call.arguments as? [String: Any],
        let rawParks = values["parks"] as? [[String: Any]]
      else {
        result(FlutterError(code: "invalid_corridor", message: nil, details: nil))
        return
      }
      showRouteCorridor(rawParks)
      result(nil)
    case "clearRoute":
      clearRoute()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func showRouteStops(_ stops: [[String: Any]]) {
    mapView.removeAnnotations(routeStopAnnotations)
    routeStopAnnotations = stops.enumerated().compactMap { index, stop in
      guard
        let latitude = stop["latitude"] as? Double,
        let longitude = stop["longitude"] as? Double,
        let groupId = stop["groupId"] as? String
      else { return nil }
      return RouteStopAnnotation(
        groupId: groupId,
        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        number: index + 1
      )
    }
    mapView.addAnnotations(routeStopAnnotations)
  }

  private func showRouteCorridor(_ parks: [[String: Any]]) {
    mapView.removeAnnotations(corridorAnnotations)
    corridorAnnotations = parks.compactMap { park in
      guard
        let latitude = park["latitude"] as? Double,
        let longitude = park["longitude"] as? Double,
        let groupId = park["groupId"] as? String
      else { return nil }
      return CorridorParkAnnotation(
        groupId: groupId,
        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      )
    }
    mapView.addAnnotations(corridorAnnotations)
  }

  private func showRoute(
    _ coordinates: [CLLocationCoordinate2D],
    segmentColors: [Int64]?,
    fit: Bool
  ) {
    clearRouteOverlays()
    guard coordinates.count >= 2 else { return }

    if let segmentColors, segmentColors.count == coordinates.count - 1 {
      for index in 0..<(coordinates.count - 1) {
        var pair = [coordinates[index], coordinates[index + 1]]
        let polyline = MKPolyline(coordinates: &pair, count: 2)
        routeSegmentOverlays.append((polyline, colour(fromArgb: segmentColors[index])))
        mapView.addOverlay(polyline, level: .aboveRoads)
      }
    } else {
      let overlay = MKPolyline(coordinates: coordinates, count: coordinates.count)
      routeOverlay = overlay
      mapView.addOverlay(overlay, level: .aboveRoads)
    }

    guard fit else { return }
    var boundingCoordinates = coordinates
    let boundingPolyline = MKPolyline(
      coordinates: &boundingCoordinates,
      count: boundingCoordinates.count
    )
    mapView.setVisibleMapRect(
      boundingPolyline.boundingMapRect,
      edgePadding: UIEdgeInsets(top: 72, left: 48, bottom: 160, right: 48),
      animated: true
    )
  }

  private func colour(fromArgb argb: Int64) -> UIColor {
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private func clearRouteOverlays() {
    if let overlay = routeOverlay {
      mapView.removeOverlay(overlay)
      routeOverlay = nil
    }
    if !routeSegmentOverlays.isEmpty {
      mapView.removeOverlays(routeSegmentOverlays.map { $0.polyline })
      routeSegmentOverlays = []
    }
  }

  private func clearRoute() {
    clearRouteOverlays()
    if !routeStopAnnotations.isEmpty {
      mapView.removeAnnotations(routeStopAnnotations)
      routeStopAnnotations = []
    }
    if !corridorAnnotations.isEmpty {
      mapView.removeAnnotations(corridorAnnotations)
      corridorAnnotations = []
    }
  }

  private func routeCoordinate(from value: [String: Any]) -> CLLocationCoordinate2D? {
    guard
      let latitude = value["latitude"] as? Double,
      let longitude = value["longitude"] as? Double
    else { return nil }
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  func mapView(
    _ mapView: MKMapView,
    rendererFor overlay: MKOverlay
  ) -> MKOverlayRenderer {
    guard let polyline = overlay as? MKPolyline else {
      return MKOverlayRenderer(overlay: overlay)
    }
    let renderer = MKPolylineRenderer(polyline: polyline)
    let segmentColour = routeSegmentOverlays.first { $0.polyline === polyline }?.colour
    renderer.strokeColor =
      segmentColour ?? UIColor.systemBlue.withAlphaComponent(0.85)
    renderer.lineWidth = 5
    renderer.lineJoin = .round
    renderer.lineCap = .round
    return renderer
  }

  private func requestUserLocation(_ arguments: Any?, result: @escaping FlutterResult) {
    guard pendingLocationResult == nil else {
      result(
        FlutterError(
          code: "location_request_in_progress",
          message: "Eine Standortabfrage läuft bereits.",
          details: nil
        )
      )
      return
    }
    let values = arguments as? [String: Any]
    pendingRadiusKm = values?["radiusKm"] as? Double ?? 25
    pendingLocationResult = result
    switch locationManager.authorizationStatus {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      locationManager.requestLocation()
    case .denied, .restricted:
      finishLocationError(
        code: "location_permission_denied",
        message: "Der Standortzugriff ist nicht erlaubt."
      )
    @unknown default:
      finishLocationError(
        code: "location_unavailable",
        message: "Der Standort ist nicht verfügbar."
      )
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard pendingLocationResult != nil else { return }
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      manager.requestLocation()
    case .denied, .restricted:
      finishLocationError(
        code: "location_permission_denied",
        message: "Der Standortzugriff ist nicht erlaubt."
      )
    case .notDetermined:
      break
    @unknown default:
      finishLocationError(
        code: "location_unavailable",
        message: "Der Standort ist nicht verfügbar."
      )
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last, let result = pendingLocationResult else { return }
    pendingLocationResult = nil
    mapView.showsUserLocation = true
    show(location.coordinate, radiusKm: pendingRadiusKm, animated: true)
    result([
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishLocationError(
      code: "location_unavailable",
      message: "Der aktuelle Standort konnte nicht bestimmt werden."
    )
  }

  private func finishLocationError(code: String, message: String) {
    guard let result = pendingLocationResult else { return }
    pendingLocationResult = nil
    result(FlutterError(code: code, message: message, details: nil))
  }

  private func show(
    _ coordinate: CLLocationCoordinate2D,
    radiusKm: Double,
    animated: Bool
  ) {
    let region = MKCoordinateRegion(
      center: coordinate,
      latitudinalMeters: max(1_000, radiusKm * 2_200),
      longitudinalMeters: max(1_000, radiusKm * 2_200)
    )
    mapView.setRegion(region, animated: animated)
  }

  private func updateGroups(_ values: [[String: Any]]) {
    let incomingIds = Set(values.compactMap { $0["groupId"] as? String })
    let removed = groupsById.values.filter { !incomingIds.contains($0.groupId) }
    mapView.removeAnnotations(removed)
    removed.forEach { groupsById.removeValue(forKey: $0.groupId) }

    for value in values {
      guard
        let groupId = value["groupId"] as? String,
        let latitude = value["latitude"] as? Double,
        let longitude = value["longitude"] as? Double,
        let evseCount = value["evseCount"] as? Int,
        let hpcEvseCount = value["hpcEvseCount"] as? Int,
        let isFavorite = value["isFavorite"] as? Bool
      else { continue }
      if let annotation = groupsById[groupId] {
        let favoriteStatusChanged = annotation.isFavorite != isFavorite
        if favoriteStatusChanged {
          mapView.removeAnnotation(annotation)
        }
        annotation.coordinate = CLLocationCoordinate2D(
          latitude: latitude,
          longitude: longitude
        )
        annotation.evseCount = evseCount
        annotation.hpcEvseCount = hpcEvseCount
        annotation.isFavorite = isFavorite
        if favoriteStatusChanged {
          mapView.addAnnotation(annotation)
        } else if let view = mapView.view(for: annotation) as? MKMarkerAnnotationView {
          configure(view, for: annotation)
        }
      } else {
        let annotation = ChargingGroupAnnotation(
          groupId: groupId,
          coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
          evseCount: evseCount,
          hpcEvseCount: hpcEvseCount,
          isFavorite: isFavorite
        )
        groupsById[groupId] = annotation
        mapView.addAnnotation(annotation)
      }
    }
  }

  private func sendVisibleBounds() {
    let region = mapView.region
    let halfLatitude = region.span.latitudeDelta / 2
    let halfLongitude = region.span.longitudeDelta / 2
    channel.invokeMethod(
      "boundsChanged",
      arguments: [
        "south": max(-90, region.center.latitude - halfLatitude),
        "west": normalizeLongitude(region.center.longitude - halfLongitude),
        "north": min(90, region.center.latitude + halfLatitude),
        "east": normalizeLongitude(region.center.longitude + halfLongitude),
      ]
    )
  }

  private func normalizeLongitude(_ longitude: Double) -> Double {
    var result = longitude
    while result < -180 { result += 360 }
    while result > 180 { result -= 360 }
    return result
  }

}

final class ChargingGroupAnnotation: NSObject, MKAnnotation {
  init(
    groupId: String,
    coordinate: CLLocationCoordinate2D,
    evseCount: Int,
    hpcEvseCount: Int,
    isFavorite: Bool
  ) {
    self.groupId = groupId
    self.coordinate = coordinate
    self.evseCount = evseCount
    self.hpcEvseCount = hpcEvseCount
    self.isFavorite = isFavorite
    super.init()
  }

  let groupId: String
  @objc dynamic var coordinate: CLLocationCoordinate2D
  var evseCount: Int
  var hpcEvseCount: Int
  var isFavorite: Bool
  var title: String? { "\(evseCount) Ladepunkte" }
}

final class RouteStopAnnotation: NSObject, MKAnnotation {
  init(groupId: String, coordinate: CLLocationCoordinate2D, number: Int) {
    self.groupId = groupId
    self.coordinate = coordinate
    self.number = number
    super.init()
  }

  let groupId: String
  let coordinate: CLLocationCoordinate2D
  let number: Int
  var title: String? { "Ladestopp \(number)" }
}

final class CorridorParkAnnotation: NSObject, MKAnnotation {
  init(groupId: String, coordinate: CLLocationCoordinate2D) {
    self.groupId = groupId
    self.coordinate = coordinate
    super.init()
  }

  let groupId: String
  let coordinate: CLLocationCoordinate2D
}
