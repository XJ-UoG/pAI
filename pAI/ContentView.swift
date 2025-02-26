//
//  ContentView.swift
//  pAI
//
//  Created by Tan Xin Jie on 26/2/25.
//

import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @State private var rooms: [String] = []
    let db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Meeting Rooms")
                .font(.title)
            
            List(rooms, id: \.self) { room in
                Text(room)
            }
            
            Button("Reset") {
                addRoom(name: "Room A")
                fetchRooms()
            }
            .padding()
        }
        .onAppear {
            fetchRooms()
        }
    }
    
    func addRoom(name: String) {
        db.collection("meetingRooms").document(name).setData(["capacity": 10]) { error in
            if let error = error {
                print("Error adding room: \(error)")
            } else {
                print("Room \(name) added!")
            }
        }
    }
    
    func fetchRooms() {
        db.collection("meetingRooms").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching rooms: \(error)")
            } else {
                self.rooms = snapshot?.documents.map { $0.documentID } ?? []
            }
        }
    }
}


#Preview {
    ContentView()
}
