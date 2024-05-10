//
//  Sober_SinceApp.swift
//  Sober Since
//
//  Created by Alex Raskin on 5/9/24.
//

import SwiftUI

struct ContentView: View {
    @State private var sobrietyStartDate: Date = {
        UserDefaults.standard.object(forKey: "sobrietyStartDate") as? Date ?? Date()
    }()
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var tempUserName: String = ""
    @State private var showingDatePicker: Bool = UserDefaults.standard.object(forKey: "sobrietyStartDate") == nil

    var body: some View {
        VStack {
            if userName.isEmpty {
                TextField("Enter your name", text: $tempUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Save") {
                    userName = tempUserName
                    UserDefaults.standard.set(userName, forKey: "userName")
                    showingDatePicker = true  // Show date picker when name is first saved
                }
                .padding()
            } else {
                Text("👋 Hi \(userName),")
                    .font(.largeTitle)
                    .padding()
                if showingDatePicker {
                    DatePicker("Start Date", selection: $sobrietyStartDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                    Button("Confirm Date") {
                        UserDefaults.standard.set(sobrietyStartDate, forKey: "sobrietyStartDate")
                        showingDatePicker = false // Hide date picker after confirming date
                    }
                    .padding()
                }
                Text("You have been sober for \(formatDuration(sobrietyStartDate, Date())) 🎉")
                    .padding()
                Button("Reset") {
                    UserDefaults.standard.removeObject(forKey: "userName")
                    UserDefaults.standard.removeObject(forKey: "sobrietyStartDate")
                    userName = ""
                    tempUserName = ""
                    showingDatePicker = true // Allow re-entry of name and date
                }
                .padding()
            }
        }
    }

    func formatDuration(_ from: Date, _ to: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: from, to: to)
        var parts: [String] = []
        if let year = components.year, year > 0 {
            parts.append("\(year) year" + (year > 1 ? "s" : ""))
        }
        if let month = components.month, month > 0 {
            parts.append("\(month) month" + (month > 1 ? "s" : ""))
        }
        if let day = components.day, day > 0 {
            parts.append("\(day) day" + (day > 1 ? "s" : ""))
        }
        return parts.joined(separator: ", ")
    }
}

@main
struct SobrietyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
