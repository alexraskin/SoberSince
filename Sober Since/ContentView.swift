import SwiftUI
import Combine
import UserNotifications

class TimerManager: ObservableObject {
    @Published var currentDateTime: Date = Date()
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

class QuoteFetcher: ObservableObject {
    @Published var quote: String = "Loading quote..."
    @Published var fetchError: Bool = false

    func fetchQuote(completion: ((String?) -> Void)? = nil) {
        guard let url = URL(string: "https://api.quotable.io/random") else {
            completion?(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(QuoteResponse.self, from: data) {
                    DispatchQueue.main.async {
                        let quoteText = "\(decodedResponse.content) — \(decodedResponse.author)"
                        self.quote = quoteText
                        self.fetchError = false
                        completion?(quoteText)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.fetchError = true
                        completion?(nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.fetchError = true
                    completion?(nil)
                }
            }
        }.resume()
    }
}

struct QuoteResponse: Codable {
    var content: String
    var author: String
}


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
    @Environment(\.colorScheme) var colorScheme: ColorScheme

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
                easterEggView
                
                logoView

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
                requestNotificationPermission()
            }
        }
    }
    
    private var easterEggView: some View {
        Group {
            if showEasterEgg {
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
                    self.showEasterEgg = true
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
                .frame(alignment: .center)
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
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                scheduleDailyNotification()
            }
        }
    }
    
    func scheduleDailyNotification() {
        if notificationsEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Daily Quote"
            content.body = "Remember to stay strong and keep going!"
            content.sound = UNNotificationSound.default
            
            let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: notificationTime))
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}

struct SettingsView: View {
    @Binding var sobrietyStartTimestamp: Double
    @Binding var userName: String
    @Binding var notificationsEnabled: Bool
    @Binding var notificationTime: Double
    @Binding var showingSettings: Bool
    @Binding var dateError: Bool
    @State private var showingResetAlert = false

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
                                requestNotificationPermission()
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
                                scheduleDailyNotification()
                            }
                        }), displayedComponents: .hourAndMinute)
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
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                scheduleDailyNotification()
            }
        }
    }
    
    func scheduleDailyNotification() {
        let quoteFetcher = QuoteFetcher()
        quoteFetcher.fetchQuote { quote in
            guard let quote = quote, notificationsEnabled else { return }

            let content = UNMutableNotificationContent()
            content.title = "Daily Quote"
            content.body = quote
            content.sound = UNNotificationSound.default
            
            let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: notificationTime))
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
}
