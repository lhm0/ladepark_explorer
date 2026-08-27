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
    configureInitialRegion(arguments)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private static let groupReuseIdentifier = "charging-group"
  private let mapView: MKMapView
  private let channel: FlutterMethodChannel
  private let locationManager = CLLocationManager()
  private var groupsById: [String: ChargingGroupAnnotation] = [:]
  private var pendingLocationResult: FlutterResult?
  private var pendingRadiusKm = 25.0

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
    default:
      result(FlutterMethodNotImplemented)
    }
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
