//
//  MeetingRoomViewModel.swift
//  pAI
//
//  Created by Tan Xin Jie on 26/2/25.
//

import SwiftUI
import FirebaseFirestore

class MeetingRoomsViewModel: ObservableObject {
    @Published var rooms: [MeetingRoom] = []
    private var db = Firestore.firestore()
    
    init() {
        fetchMeetingRooms()
    }
    
    func fetchMeetingRooms() {
        db.collection("meetingRooms").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching rooms: \(error.localizedDescription)")
                return
            }
            
            self.rooms = snapshot?.documents.compactMap { doc in
                try? doc.data(as: MeetingRoom.self)
            } ?? []
        }
    }
    
    func deleteMeetingRooms() {
        let db = Firestore.firestore()
        let collectionRef = db.collection("meetingRooms")
        
        collectionRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            
            for document in snapshot!.documents {
                collectionRef.document(document.documentID).delete { error in
                    if let error = error {
                        print("Error deleting document \(document.documentID): \(error)")
                    }
                }
            }
        }
    }
    
    func addDummyMeetingRooms() {
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
                "availability": timeSlots
            ]) { error in
                if let error = error {
                    print("Error adding \(roomId): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func bookMeetingRoom(roomId: String, timeSlot: String) async {
        let db = Firestore.firestore()
        let roomRef = db.collection("meetingRooms").document(roomId)
        
        do {
            let snapshot = try await roomRef.getDocument()
            if let data = snapshot.data(), var availability = data["availability"] as? [String],
               let index = availability.firstIndex(of: timeSlot) {
                availability.remove(at: index)
                try await roomRef.updateData(["availability": availability])
            }
        } catch {
            DispatchQueue.main.async {
                print("\(error.localizedDescription)")
            }
        }
    }
    
    func extractRoomTimeAndMessage(from responseText: String) -> (String, String, String)? {
        // Use regex to extract the JSON block
        let pattern = #"\{[\s\S]*?\}"#  // Matches the first valid JSON object
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: responseText, range: NSRange(responseText.startIndex..., in: responseText)),
              let range = Range(match.range, in: responseText) else {
            print("No JSON block found in AI response")
            return nil
        }
        
        let jsonString = String(responseText[range])
        
        // Convert extracted JSON string into Data
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert extracted JSON to Data")
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String],
               let room = json["room"], let time = json["time"], let message = json["message"] {
                return (room, time, message)
            }
        } catch {
            print("JSON Parsing Error: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    
    func generateTimeSlots() -> [String] {
        let startHour = 9
        let endHour = 17
        var slots: [String] = []
        
        for hour in startHour..<endHour {
            slots.append(String(format: "%02d:00", hour))
            slots.append(String(format: "%02d:30", hour))
        }
        
        return slots
    }
}

struct MeetingRoom: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var capacity: Int
    var location: String
    var availability: [String]
}
