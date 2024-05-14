//
//  QuoteFetcher.swift
//  Sober Since
//
//  Created by Alex Raskin on 5/13/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("sobrietyStartTimestamp") private var sobrietyStartTimestamp: Double = Date().timeIntervalSince1970
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notificationTime") private var notificationTime: Double = Date().timeIntervalSince1970

    @State private var showingSettings: Bool = false
    @State private var dateError: Bool = false
    @State private var tapCount: Int = 0
    @State private var showEasterEgg: Bool = false
    @StateObject var quoteFetcher = QuoteFetcher()
    @EnvironmentObject var timerManager: TimerManager

    var sobrietyStartDate: Date {
        get {
            Date(timeIntervalSince1970: sobrietyStartTimestamp)
        }
        set {
            sobrietyStartTimestamp = newValue.timeIntervalSince1970
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if showEasterEgg {
                    easterEggView
                        .transition(.scale)
                } else {
                    logoView
                        .transition(.scale)
                }

                if userName.isEmpty || sobrietyStartDate == Date() {
                    startButton
                } else {
                    userInfoView
                }
                
                if dateError {
                    Text("Please enter your Sobriety date.")
                        .foregroundColor(.red)
                }
                
                if !userName.isEmpty {
                    quoteView
                }
                
                Spacer()
                settingsButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue]), startPoint: .top, endPoint: .bottom)
            )
            .onAppear {
                NotificationManager.requestNotificationPermission()
            }
        }
        .animation(.easeInOut, value: showEasterEgg) // Apply animation when showEasterEgg changes
    }
    
    private var easterEggView: some View {
        VStack {
            Text("🎉 Surprise! 🎉")
                .font(.largeTitle)
                .padding()
                .bold()
            Image("funnyCAT")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            self.showEasterEgg = false
                        }
                    }
                }
        }
    }
    
    private var logoView: some View {
        Image("logoDARK")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .onTapGesture {
                self.tapCount += 1
                if self.tapCount == 5 {
                    withAnimation {
                        self.showEasterEgg = true
                    }
                    self.tapCount = 0
                }
            }
    }
    
    private var startButton: some View {
        Button("Start") {
            showingSettings = true
        }
        .bold()
        .foregroundColor(.cyan)
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView(sobrietyStartTimestamp: $sobrietyStartTimestamp, userName: $userName, notificationsEnabled: $notificationsEnabled, notificationTime: $notificationTime, showingSettings: $showingSettings, dateError: $dateError)
        }
    }
    
    private var userInfoView: some View {
        VStack {
            Text("👋 Hello, \(userName)")
                .padding()
                .bold()
            Text("You have been sober for \(formatDuration(sobrietyStartDate, timerManager.currentDateTime))")
                .bold()
                .padding()
                .frame(maxWidth: .infinity) // Make sure the text does not exceed the screen width
                .multilineTextAlignment(.center) // Center-align the text
                .padding()
        }
    }
    
    private var quoteView: some View {
        VStack {
            if quoteFetcher.fetchError {
                Text("Failed to fetch quote. Please try again.")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text(quoteFetcher.quote)
                    .padding()
                    .onAppear {
                        quoteFetcher.fetchQuote()  // Fetch the quote when the view appears
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue]), startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding()
            }
        }
    }
    
    private var settingsButton: some View {
        Button("Settings") {
            showingSettings = true
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView(sobrietyStartTimestamp: $sobrietyStartTimestamp, userName: $userName, notificationsEnabled: $notificationsEnabled, notificationTime: $notificationTime, showingSettings: $showingSettings, dateError: $dateError)
        }
        .foregroundColor(.white)
    }
    
    func formatDuration(_ from: Date, _ to: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: from, to: to)
        var durationString = ""
        if let year = components.year, year > 0 { durationString += "\(year) year\(year > 1 ? "s" : ""), " }
        if let month = components.month, month > 0 { durationString += "\(month) month\(month > 1 ? "s" : ""), " }
        if let day = components.day, day > 0 { durationString += "\(day) day\(day > 1 ? "s" : ""), " }
        if let hour = components.hour, hour > 0 { durationString += "\(hour) hour\(hour > 1 ? "s" : ""), " }
        if let minute = components.minute, minute > 0 { durationString += "\(minute) minute\(minute > 1 ? "s" : ""), " }
        if let second = components.second, second >= 0 { durationString += "\(second) second\(second != 1 ? "s" : "")" }
        return durationString.trimmingCharacters(in: CharacterSet(charactersIn: ", "))
    }
}
