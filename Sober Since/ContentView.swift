import SwiftUI

struct ContentView: View {
    @State private var sobrietyStartDate: Date = UserDefaults.standard.object(forKey: "sobrietyStartDate") as? Date ?? Date()
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack {
                List(0..<10) { item in
                    GifImage("catGIF")
                        .frame(width: 200, height: 200)

                }
                if userName.isEmpty || sobrietyStartDate == Date() {

                    Button("Please enter your Name and Sobriety Date") {
                        showingSettings = true
                    }
                    .padding()
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(sobrietyStartDate: $sobrietyStartDate, userName: $userName, showingSettings: $showingSettings)
                    }
                } else {
                    Text("👋 Hello, \(userName)")
                        .padding()
                    Text("You have been sober for \(formatDuration(sobrietyStartDate, Date())) 🎉")
                        .bold()
                        .padding()
                    Button("Settings") {
                        showingSettings = true
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(sobrietyStartDate: $sobrietyStartDate, userName: $userName, showingSettings: $showingSettings)
                    }
                    
                }

                Spacer()
                Link("Github", destination: URL(string: "https://github.com/alexraskin/SoberSince")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding()
                Text("Made with ❤️ in Arizona")
                    .font(.footnote)
            }
            .navigationTitle("Sobriety Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
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

struct SettingsView: View {
    @Binding var sobrietyStartDate: Date
    @Binding var userName: String
    @Binding var showingSettings: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Enter your name", text: $userName)
                    DatePicker("Sobriety Start Date", selection: $sobrietyStartDate, displayedComponents: .date)
                    Button("Reset User Data") {
                        // Resetting user data
                        UserDefaults.standard.removeObject(forKey: "userName")
                        UserDefaults.standard.removeObject(forKey: "sobrietyStartDate")
                        userName = ""
                        sobrietyStartDate = Date()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UserDefaults.standard.set(sobrietyStartDate, forKey: "sobrietyStartDate")
                        UserDefaults.standard.set(userName, forKey: "userName")
                        showingSettings = false // Dismiss the sheet
                    }
                    
                }
            }
        }
    }
}
