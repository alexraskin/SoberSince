//
//  QuoteFetcher.swift
//  Sober Since
//
//  Created by Alex Raskin on 5/13/24.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Binding var sobrietyStartTimestamp: Double
    @Binding var userName: String
    @Binding var notificationsEnabled: Bool
    @Binding var notificationTime: Double
    @Binding var showingSettings: Bool
    @Binding var dateError: Bool
    @State private var showingResetAlert = false
    @State private var appStoreVersion: String = "Loading..."
    @State private var isLoadingVersion = true

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
                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("Enter your name", text: $userName)
                        DatePicker("Sobriety Start Date", selection: Binding(get: {
                            sobrietyStartDate
                        }, set: { newValue in
                            sobrietyStartTimestamp = newValue.timeIntervalSince1970
                            if newValue > Date() {
                                sobrietyStartTimestamp = Date().timeIntervalSince1970  // Reset to today if future date is chosen
                                dateError = true
                            } else {
                                dateError = false
                            }
                        }), displayedComponents: .date)
                    }
                    Section(header: Text("Notifications")) {
                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { value in
                                if value {
                                    NotificationManager.requestNotificationPermission()
                                } else {
                                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                                }
                            }
                        if notificationsEnabled {
                            DatePicker("Notification Time", selection: Binding(get: {
                                Date(timeIntervalSince1970: notificationTime)
                            }, set: { newValue in
                                notificationTime = newValue.timeIntervalSince1970
                                if notificationsEnabled {
                                    NotificationManager.scheduleMilestoneNotifications()
                                }
                            }), displayedComponents: .hourAndMinute)
                        }
                    }
                    Section(header: Text("About")) {
                        Text("This app helps you track your sobriety milestones and stay motivated.")
                        Link("Privacy Policy", destination: URL(string: "https://github.com/alexraskin/SoberSince?tab=readme-ov-file#privacy-policy")!)
                            .foregroundColor(.blue)
                        Link("Send Feedback", destination: URL(string: "mailto:root@00z.sh")!)
                            .foregroundColor(.blue)
                    }
                    Section(header: Text("App Info")) {
                        Text("Version \(appStoreVersion)")
                            .onAppear {
                                fetchAppStoreVersion()
                            }
                    }
                    Button("Reset User Data") {
                        self.showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    .alert(isPresented: $showingResetAlert) {
                        Alert(
                            title: Text("Reset User Data?"),
                            message: Text("Are you sure you would like to reset your Sobriety date and name? This action cannot be undone."),
                            primaryButton: .destructive(Text("Reset")) {
                                UserDefaults.standard.removeObject(forKey: "userName")
                                UserDefaults.standard.removeObject(forKey: "sobrietyStartTimestamp")
                                userName = ""
                                sobrietyStartTimestamp = Date().timeIntervalSince1970
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }

                Spacer()

                VStack {
                    Link("GitHub Page", destination: URL(string: "https://github.com/alexraskin/SoberSince")!)
                        .padding()
                        .foregroundColor(.blue)
                    Text("Made with ❤️ in Arizona")
                        .padding(.bottom, 20)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UserDefaults.standard.set(sobrietyStartTimestamp, forKey: "sobrietyStartTimestamp")
                        UserDefaults.standard.set(userName, forKey: "userName")
                        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
                        UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
                        showingSettings = false
                    }
                }
            }
        }
    }
    private func fetchAppStoreVersion() {
           guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=com.yourcompany.yourapp") else {
               return
           }

           URLSession.shared.dataTask(with: url) { data, response, error in
               guard let data = data, error == nil else {
                   DispatchQueue.main.async {
                       self.appStoreVersion = "N/A"
                       self.isLoadingVersion = false
                   }
                   return
               }

               do {
                   if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let version = results.first?["version"] as? String {
                       DispatchQueue.main.async {
                           self.appStoreVersion = version
                           self.isLoadingVersion = false
                       }
                   }
               } catch {
                   DispatchQueue.main.async {
                       self.appStoreVersion = "N/A"
                       self.isLoadingVersion = false
                   }
                   print("Failed to parse JSON: \(error)")
               }
           }.resume()
       }
}
