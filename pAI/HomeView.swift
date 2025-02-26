//
//  ContentView.swift
//  pAI
//
//  Created by Tan Xin Jie on 26/2/25.
//

import SwiftUI
import FirebaseFirestore
import SwiftSpeech
import GoogleGenerativeAI

struct HomeView: View {
    @StateObject private var viewModel = MeetingRoomsViewModel()
    
    @State private var aiResponse: String = "Ask me about available meeting rooms..."
    
    @State private var userInput: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List(viewModel.rooms) { room in
                    VStack(alignment: .leading) {
                        NavigationLink (destination: RoomDetailsView(room: room)) {
                            Text(room.name).font(.headline)
                        }
                    }
                }
                Text(aiResponse)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding()
                
                SwiftSpeech.Demos.Basic(localeIdentifier: "en_US")
                    .onRecognizeLatest(update: $userInput)
                    .onStopRecording { session in
                        Task {
                            await processUserRequest(userInput)
                        }
                    }
            }
            .navigationTitle("Meeting Rooms")
            .toolbar {
                Button("Reset") {
                    viewModel.deleteMeetingRooms()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.addDummyMeetingRooms()
                    }
                }
            }
        }
    }
    
    func processUserRequest(_ input: String) async {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_KEY") as? String else {
            fatalError("Missing GEMINI_KEY")
        }
        let model = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKey)
        
        let availableRooms = viewModel.rooms
            .map { "\($0.name) (\($0.location)) (\($0.capacity) people), available at \($0.availability.joined(separator: ", "))" }
            .joined(separator: "\n")
        
        let meetingRoomsData = availableRooms.isEmpty
        ? "There are currently no available meeting rooms."
        : "Here is the current meeting room availability:\n\(availableRooms)"
        
        let prompt = """
            You are an intelligent office assistant helping users find the most suitable meeting room.
        
            ### User Request:
            "\(input)"
        
            ### Available Rooms:
            \(meetingRoomsData)
        
            ### Instructions:
            - Find the most **suitable** meeting room based on the user's request based on (availability > capacity > time > location).
            - If the requested time is **not available**, book another suitable room else the closest nearest time and **briefly explain the change to the user**.
            - If no rooms are available at any time, respond politely.
            - Use a natural tone but keep it relatively brief.
            - Respond in **this exact JSON format**:
            ```json
            {
                "room": "Room A",
                "time": "14:00",
                "message": "[your response here]"
            }
            ```
        """
        
        do {
            let response = try await model.generateContent(prompt)
            let aiText = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "{}"
            
            // Parse JSON response from Gemini
            if let (roomName, timeSlot, userMessage) = viewModel.extractRoomTimeAndMessage(from: aiText) {
                DispatchQueue.main.async {
                    aiResponse = userMessage
                }
                if roomName != "None" {
                    await viewModel.bookMeetingRoom(roomId: roomName, timeSlot: timeSlot)
                }
            } else {
                DispatchQueue.main.async {
                    aiResponse = "No available rooms found."
                }
            }
        } catch {
            DispatchQueue.main.async {
                aiResponse = "Error: \(error.localizedDescription)"
            }
        }
    }
    
}

#Preview {
    HomeView()
}
