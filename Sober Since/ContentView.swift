import SwiftUI
import Combine

class TimerManager: ObservableObject {
    @Published var currentDateTime = Date()
    var timerSubscription: AnyCancellable?

    init() {
        startTimer()
    }
    
    func startTimer() {
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] date in
            self?.currentDateTime = date
        }
    }
    
    deinit {
        timerSubscription?.cancel()
    }
}

struct ContentView: View {
    @State private var sobrietyStartDate: Date = UserDefaults.standard.object(forKey: "sobrietyStartDate") as? Date ?? Date()
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var currentDateTime: Date = Date()
    @State private var showingSettings = false
    @State private var dateError: Bool = false
    @State private var tapCount = 0
    @State private var showEasterEgg = false
    @ObservedObject var timerManager = TimerManager()
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        NavigationView {
            VStack {
                if showEasterEgg {
                    Text("🎉 Surprise! 🎉")
                        .font(.largeTitle)
                        .padding()
                        .bold()
                    Image("funnyCAT") // Make sure you have a 'funnyCat' image in your assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                } else {
                    if colorScheme == .dark {
                        Image("logoDARK") // Replace "LogoDark" with your dark mode logo asset name
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .onTapGesture {
                                self.tapCount += 1
                                if self.tapCount == 5 {
                                    self.showEasterEgg = true
                                    self.tapCount = 0
                                    
                                }
                                
                            }
                    } else {
                        Image("logoLIGHT")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .onTapGesture {
                                self.tapCount += 1
                                if self.tapCount == 5 {
                                    self.showEasterEgg = true
                                    self.tapCount = 0
                                }
                            }
                    }
                }

                if userName.isEmpty || sobrietyStartDate == Date() {

                    Button("Start") {
                        showingSettings = true
                    }
                    .bold()
                    .foregroundColor(.cyan)
                    .padding()
                    .sheet(isPresented: $showingSettings) {
                        SettingsView(sobrietyStartDate: $sobrietyStartDate, userName: $userName, showingSettings: $showingSettings, dateError: $dateError)
                    }
                
                } else {
                    Text("👋 Hello, \(userName)")
                        .padding()
                        .bold()
                    Text("You have been sober for \(formatDuration(sobrietyStartDate, timerManager.currentDateTime))")
                        .bold()
                        .padding()
                        .frame(alignment: .center)
                    
                }
                if dateError {
                    Text("Please enter your Sobriety date.")
                        .foregroundColor(.red)
                }
                Spacer()
                Button("Settings") {
                    showingSettings = true
                }
                .padding()
                .sheet(isPresented: $showingSettings) {
                    SettingsView(sobrietyStartDate: $sobrietyStartDate, userName: $userName, showingSettings: $showingSettings, dateError: $dateError)
                }

            }
        }
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


struct SettingsView: View {
    @Binding var sobrietyStartDate: Date
    @Binding var userName: String
    @Binding var showingSettings: Bool
    @Binding var dateError: Bool

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("Enter your name", text: $userName)
                        DatePicker("Sobriety Start Date", selection: $sobrietyStartDate, displayedComponents: .date)
                            .onChange(of: sobrietyStartDate) { newValue in
                                if newValue > Date() {
                                    sobrietyStartDate = Date()  // Reset to today if future date is chosen
                                    dateError = true
                                } else {
                                    dateError = false
                                }
                            }
                        Button("Reset User Data") {
                            UserDefaults.standard.removeObject(forKey: "userName")
                            UserDefaults.standard.removeObject(forKey: "sobrietyStartDate")
                            userName = ""
                            sobrietyStartDate = Date() // Reset to current date or some default
                        }
                    }
                }
                Spacer() // Pushes the content to the top and link and text to the bottom
                Link("Github", destination: URL(string: "https://github.com/alexraskin/SoberSince")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .padding()
                Text("Made with ❤️ in Arizona")
                    .font(.footnote)
                    .padding()
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

