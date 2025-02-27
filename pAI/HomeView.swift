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
    @EnvironmentObject var viewModel: PAIViewModel
    
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
                Text(viewModel.response)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding()
                
                SwiftSpeech.Demos.Basic(localeIdentifier: "en_US")
                    .onRecognizeLatest(update: $userInput)
                    .onStopRecording { session in
                        Task {
                            await viewModel.processUserRequest(userInput)
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
}

#Preview {
    HomeView()
        .environmentObject(PAIViewModel())
}
