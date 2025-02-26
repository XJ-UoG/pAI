//
//  pAIApp.swift
//  pAI
//
//  Created by Tan Xin Jie on 26/2/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        addDummyMeetingRooms()
        return true
    }
}

func addDummyMeetingRooms() {
    let db = Firestore.firestore()
    let meetingRoomsRef = db.collection("meetingRooms")

    let rooms = [
        ["name": "Room A", "capacity": 4, "location": "Level 3, Block A"],
        ["name": "Room B", "capacity": 8, "location": "Level 2, Block B"],
        ["name": "Room C", "capacity": 12, "location": "Level 1, Block C"]
    ]

    let timeSlots = generateTimeSlots()

    for room in rooms {
        let roomId = room["name"] as! String

        meetingRoomsRef.document(roomId).setData([
            "name": roomId,
            "capacity": room["capacity"] as! Int,
            "location": room["location"] as! String,
            "availability": timeSlots,
        ]) { error in
            if let error = error {
                print("Error adding \(roomId): \(error.localizedDescription)")
            } else {
                print("Added \(roomId)")
            }
        }
    }
}

func generateTimeSlots() -> [String] {
    let startHour = 9
    let endHour = 17
    var slots: [String] = []

    for hour in startHour..<endHour {
        slots.append(String(format: "%02d:00", hour))  // "09:00"
        slots.append(String(format: "%02d:30", hour))  // "09:30"
    }

    return slots
}


@main
struct pAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
