//
//  FeedVM.swift
//  ALP_MAD
//
//  Created by MacBook Pro on 30/05/24.
//  Copyright © 2024 test. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Firebase
import Photos
import UIKit
import FirebaseStorage

struct Feed: Identifiable {
    var id: String
    var image: String
    var date: Date
    var caption: String
    var user_name: String
    var user_picture: String
}

class FeedVM: ObservableObject {
    @Published var feeds = [Feed]()
    
    let db = Firestore.firestore()
    
    func fetchFeeds() {
        // Get authenticated user's UID
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return
        }
        
        // Fetch user data to get couple_id
        db.collection("users").document(uid).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("User document does not exist")
                return
            }
            
            guard let couple_id = data["couple_id"] as? String else {
                print("User does not have a couple_id")
                return
            }
            
            // Fetch feeds using couple_id
            self.db.collection("couples").document(couple_id).collection("feeds").getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching feeds: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No feeds found")
                    return
                }
                
                self.feeds = documents.compactMap { document -> Feed? in
                    let data = document.data()
                    let id = document.documentID
                    let image = data["image"] as? String ?? ""
                    let caption = data["caption"] as? String ?? ""
                    let timestamp = data["date"] as? Timestamp
                    let date = timestamp?.dateValue() ?? Date()
                    let user_name = data["user_name"] as? String ?? ""
                    let user_picture = data["user_picture"] as? String ?? ""
                    return Feed(id: id, image: image, date: date, caption: caption, user_name: user_name, user_picture: user_picture)
                }
                
                self.feeds.sort(by: { $0.date > $1.date })
                self.loadImages()
            }
        }
    }
    
    private func loadImages() {
        for index in feeds.indices {
            let image_path = feeds[index].image
            let storageRef = Storage.storage().reference().child(image_path)
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching image URL: \(error)")
                    return
                }
                
                guard let url = url else { return }
                
                DispatchQueue.main.async {
                    self.feeds[index].image = url.absoluteString
                }
            }
            
            let user_picture_path = feeds[index].user_picture
            let userPictureRef = Storage.storage().reference().child(user_picture_path)
            
            userPictureRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching user picture URL: \(error)")
                    return
                }
                
                guard let url = url else { return }
                
                DispatchQueue.main.async {
                    self.feeds[index].user_picture = url.absoluteString
                }
            }
        }
    }
}
