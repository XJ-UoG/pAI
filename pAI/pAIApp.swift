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
        return true
    }
}

@main
struct pAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView()
            }
        }
    }
}
