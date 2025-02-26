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
            - Respond in a short, natural, and helpful manner.
            - If multiple rooms are available, suggest the most **suitable** one based on capacity, location, and time.
            - If no rooms are available, let the user know politely and suggest alternative times if possible.
            - Avoid repeating information unnecessarily.
        
            ### Example Responses:
            - "Room A is a great choice for your meeting at 2 PM. It’s spacious and located nearby."
            - "Room C is available at 3 PM and fits your team perfectly."
            - "Unfortunately, no rooms are free at 2 PM, but Room B is open at 2:30 PM if that works."
        """
        
        
        do {
            let response = try await model.generateContent(prompt)
            DispatchQueue.main.async {
                aiResponse = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "No response received"
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
