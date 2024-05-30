//
//  MainPageVM.swift
//  ALP_MAD
//
//  Created by MacBook Pro on 24/05/24.
//  Copyright © 2024 test. All rights reserved.
//

import Foundation
import MapKit
import FirebaseFirestore

final class MainPageViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published private(set) var UID: String? = ""  // Private setter to control modification
    
    var locationManager: CLLocationManager?
    private var updateLocationTimer: Timer?
    private var fetchLocationsTimer: Timer?
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -7.28522, longitude: 112.63184),
        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025))
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var userLocations: [IdentifiableCoordinate] = []
    
    private var db = Firestore.firestore()
    
    override init() {
        super.init()
        checkIfLocationServiceIsEnabled()
    }
    
    func getUserUID() {
        do {
            let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
            self.UID = uid
            print("UID main page: \(uid)")
            initializeLocationUpdates()
        } catch {
            print("Error getting authenticated user UID: \(error)")
        }
    }
    
    func checkIfLocationServiceIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
        } else {
            print("Show alert location is off")
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            alertMessage = "Your location is restricted likely due to parental control."
            showAlert = true
        case .denied:
            alertMessage = "Location permission has been turned off. Please enable it in Settings."
            showAlert = true
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = locationManager.location {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                fetchUserUIDs()
            }
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
        self.UID = ""
        print("User logged out, UID is now: \(String(describing: self.UID))")
    }
    
    func fetchUserUIDs() {
        db.collection("couples").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            var userUIDs: [String] = []
            
            for document in querySnapshot!.documents {
                let data = document.data()
                if let user1 = data["user_1"] as? String, let user2 = data["user_2"] as? String {
                    userUIDs.append(user1)
                    userUIDs.append(user2)
                }
            }
            
            self.fetchUserLocations(userUIDs: userUIDs)
        }
    }
    
    func fetchUserLocations(userUIDs: [String]) {
        db.collection("users").whereField(FieldPath.documentID(), in: userUIDs).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            var locations: [IdentifiableCoordinate] = []
            
            for document in querySnapshot!.documents {
                let data = document.data()
                if let geoPoint = data["location"] as? GeoPoint {
                    let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    let identifiableCoordinate = IdentifiableCoordinate(coordinate: coordinate)
                    locations.append(identifiableCoordinate)
                }
            }
            
            self.userLocations = locations
        }
    }
    
    func initializeLocationUpdates() {
        startUpdatingLocation()
        startFetchingLocations()
    }
    
    func startUpdatingLocation() {
        print("Starting to update location with UID: \(String(describing: self.UID))")
        
        updateLocationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateUserLocation()
        }
    }
    
    func startFetchingLocations() {
        fetchLocationsTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchUserUIDs()
        }
    }
    
    func stopUpdatingLocation() {
        updateLocationTimer?.invalidate()
        updateLocationTimer = nil
    }
    
    func stopFetchingLocations() {
        fetchLocationsTimer?.invalidate()
        fetchLocationsTimer = nil
    }
    
    func updateUserLocation() {
        do {
            let uid = try AuthenticationManager.shared.getAuthenticatedUser().uid
            self.UID = uid
        } catch {
            print("Error")
        }
        print("Attempting to update location with UID: \(String(describing: self.UID))")
        
        guard let uid = self.UID, !uid.isEmpty else {
            print("No valid UID, skipping location update")
            return
        }
        
        guard let location = locationManager?.location else {
            print("Location manager or location not available")
            return
        }
        
        let geoPoint = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        db.collection("users").document(uid).updateData([
            "location": geoPoint
        ]) { error in
            if let error = error {
                print("Error updating location: \(error)")
            } else {
                print("User location updated successfully")
            }
        }
        
    }
    
    deinit {
        stopUpdatingLocation()
        stopFetchingLocations()
    }
}