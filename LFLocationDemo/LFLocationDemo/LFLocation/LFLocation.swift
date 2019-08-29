//
//  LFLocation.swift
//  LFLocationDemo
//
//  Created by LeonDeng on 2019/8/26.
//  Copyright © 2019 LeonDeng. All rights reserved.
//

import CoreLocation

enum LocationState {
    case success
    case timeOut
    case unauth
    case noService
    case error(error: Error?)
}

typealias LFLocationHandler = (_ state: LocationState, _ locations: [CLLocation]?) -> Void

typealias LFCoordinateHandler = (_ state: LocationState, _ longtitude: Double, _ latitude: Double) -> Void

typealias LFDescriptionHandler = (_ state: LocationState, _ country: String?, _ province: String?, _ city: String?, _ area: String?) -> Void

class LFLocation: NSObject {
    
    private var timeOut: Double
    
    private var locationHandler: LFLocationHandler?
    
    private lazy var requestTimer: Timer = { [unowned self] in
        let locationTimer = Timer(timeInterval: self.timeOut, repeats: false) { (timer) in
            
            if let handler = self.locationHandler {
                handler(.timeOut, nil)
            }
            
            timer.invalidate()
        }
        return locationTimer
    }()
    
    private let locationManager: CLLocationManager = CLLocationManager()
    
    public var serviceEnable: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    init(filter: CLLocationDistance, accuracy: CLLocationAccuracy, timeOut: TimeInterval) {
        self.timeOut = timeOut
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = filter
        locationManager.desiredAccuracy = accuracy
    }
    
    convenience init(timeOut: TimeInterval) {
        self.init(filter: 200, accuracy: kCLLocationAccuracyBest, timeOut: timeOut)
    }
    
    deinit {
        print("LFLocation was deinited")
    }
}

extension LFLocation: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let handler = self.locationHandler {
            handler(.error(error: error), nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let handler = self.locationHandler {
            handler(.success, locations)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .notDetermined {
            if let handler = self.locationHandler {
                handler(.unauth, nil)
            }
        }
    }
}

extension LFLocation {
    
    public func location(timeOut: TimeInterval, handler: @escaping LFLocationHandler) {
        self.timeOut = timeOut
        self.locationHandler = handler
        if self.serviceEnable {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        } else {
            handler(.noService, nil)
        }
    }
    
    public func coordinate(timeOut: TimeInterval, handler: @escaping LFCoordinateHandler) {
        self.timeOut = timeOut
        self.locationHandler = { (state, location) in
            handler(state, location?.last?.coordinate.longitude ?? 0, location?.last?.coordinate.latitude ?? 0)
        }
        if self.serviceEnable {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        } else {
            handler(.noService, 0, 0)
        }
    }
    
    public func locationDescription(timeOut: TimeInterval, handler: @escaping LFDescriptionHandler) {
        self.timeOut = timeOut
        RunLoop.current.add(self.requestTimer, forMode: RunLoop.Mode.default)
        self.locationHandler = { (state, location) in
            if let lastLocation = location?.last {
                let geoDecoder = CLGeocoder()
                geoDecoder.reverseGeocodeLocation(lastLocation) { (placeMarks, error) in
                    guard error == nil else {
                        handler(.error(error: error), nil, nil, nil, nil)
                        return
                    }
                    for placeMark in placeMarks! {
                        let country = placeMark.country
                        let province = placeMark.administrativeArea
                        let city = placeMark.locality
                        let area = placeMark.thoroughfare
                        handler(.success, country, province, city, area)
                    }
                }
            } else {
                handler(.success, nil, nil, nil, nil)
            }
           
        }
        if self.serviceEnable {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        } else {
            handler(.noService, nil, nil, nil, nil)
        }
    }
    
    public static func currentLocation(timeOut: TimeInterval, handler: @escaping LFLocationHandler) {
        let location = LFLocation(timeOut: timeOut)
        location.location(timeOut: timeOut, handler: handler)
    }
    
    public static func currentLocationDescription(timeOut: TimeInterval, handler: @escaping LFDescriptionHandler) {
        let location = LFLocation(timeOut: timeOut)
        location.locationDescription(timeOut: timeOut, handler: handler)
    }
    
    public static func currentCoordinate(timeOut: TimeInterval, handler: @escaping LFCoordinateHandler) {
        let location = LFLocation(timeOut: timeOut)
        location.coordinate(timeOut: timeOut, handler: handler)
    }
}
