import SwiftUI

struct ContentView: View {
    @State private var sobrietyStartDate: Date = UserDefaults.standard.object(forKey: "sobrietyStartDate") as? Date ?? Date()
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var showingSettings = false
    @State private var dateError: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                GifImage("catGIF")
                        .frame(width: 200, height: 200)

                if userName.isEmpty || sobrietyStartDate == Date() {

                    Button("Please enter your Name and Sobriety Date") {
                        showingSettings = true
                    }
                    .padding()
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(sobrietyStartDate: $sobrietyStartDate, userName: $userName, showingSettings: $showingSettings, dateError: $dateError)
                    }
                
                } else {
                    Text("👋 Hello, \(userName)")
                        .padding()
                    Text("You have been sober for \(formatDuration(sobrietyStartDate, Date()))")
                        .bold()
                        .padding()
                    Button("Settings") {
                        showingSettings = true
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(sobrietyStartDate: $sobrietyStartDate, userName: $userName, showingSettings: $showingSettings, dateError: $dateError)
                    }
                    
                }
                if dateError {
                    Text("Please enter a past date.")
                        .foregroundColor(.red)
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
        let components = calendar.dateComponents([.year, .day], from: from, to: to)
        let totalDays = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        
        var result = ""
        if let year = components.year, year > 0 {
            result += "\(year) year\(year > 1 ? "s" : "")"
            result += " or \(totalDays) days"
        } else {
            result += "\(totalDays) day\(totalDays > 1 ? "s" : "")"
        }
        return result
    }
}

struct SettingsView: View {
    @Binding var sobrietyStartDate: Date
    @Binding var userName: String
    @Binding var showingSettings: Bool
    @Binding var dateError: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Enter your name", text: $userName)
                    DatePicker("Sobriety Start Date", selection: $sobrietyStartDate, displayedComponents: .date)
                        .onChange(of: sobrietyStartDate) { newValue in
                            if newValue > Date() {
                                sobrietyStartDate = Date()
                                dateError = true
                            } else {
                                dateError = false
                            }
                        }
                    Button("Reset User Data") {
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
                        showingSettings = false
                    }
                    
                }
            }
        }
    }
}
