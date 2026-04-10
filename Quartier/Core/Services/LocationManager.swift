//
//  LocationManager.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-03-10.


import Foundation
import MapKit
import Combine
import CoreLocation

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager: CLLocationManager
    
    
    @Published var userLocation: CLLocationCoordinate2D?
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let latestLocation = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = latestLocation.coordinate
        }
    }
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access is restricted.")
            manager.stopUpdatingLocation()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()

        default:
            break
            
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error){
        print("Failed to find user's location: \(error.localizedDescription )")
        manager.stopUpdatingLocation()
    }
    
}
