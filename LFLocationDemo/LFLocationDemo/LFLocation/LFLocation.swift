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
    case error(error: Error)
}

typealias LFLocationHandler = (_ state: LocationState, _ locations: [CLLocation]?) -> Void

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
    public static func currentLocation(timeOut: TimeInterval, handler: @escaping LFLocationHandler) {
        let location = LFLocation(timeOut: timeOut)
        location.locationHandler = handler
        if location.serviceEnable {
            location.locationManager.requestWhenInUseAuthorization()
            location.locationManager.startUpdatingLocation()
            RunLoop.current.add(location.requestTimer, forMode: .default)
        } else {
            handler(.noService, nil)
        }
    }
    
    
}

extension CLLocation {
    func coorindate() -> (Double, Double) {
        return (self.coordinate.longitude, self.coordinate.latitude)
    }
}
