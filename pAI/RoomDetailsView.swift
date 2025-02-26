//
//  RoomDetailsView.swift
//  pAI
//
//  Created by Tan Xin Jie on 26/2/25.
//

import SwiftUI

struct RoomDetailsView: View {
    var room: MeetingRoom
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Capacity: \(room.capacity)")
            Text("Location: \(room.location)")
            Text("Availability")
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(room.availability, id: \.self){
                    Button("\($0)"){
                        
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle(room.name)
    }
}

#Preview {
    RoomDetailsView(room: MeetingRoom(
        id: "example_room",
        name: "Room Example",
        capacity: 2,
        location: "Level ??, Block ?",
        availability: ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30",
                       "12:00", "12:30", "13:00", "13:30", "14:00", "14:30"]
    ))
}
