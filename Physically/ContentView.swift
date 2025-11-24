//
//  ContentView.swift
//  Physically
//
//  Created by Pratik Bhyan on 19/11/25.
//

import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var userStats: [UserStats]
    @State private var showSquatView = false
    @State private var showPushupView = false
    @State private var showSettingsView = false
    @State private var showExerciseSelection = false
    
    // Blocking Manager for Picker
    @ObservedObject var blockingManager = BlockingManager.shared
    @State private var isPickerPresented = false
    
    var currentUserStats: UserStats {
        if let stats = userStats.first {
            return stats
        } else {
            return UserStats()
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Liquid Background (Banked Minutes)
                LiquidView(bankedMinutes: currentUserStats.bankedMinutes)
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    // Header with Settings
                    HStack {
                        Spacer()
                        Button(action: { showSettingsView = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Banked Minutes Display (Central)
                    VStack {
                        Text("\(Int(currentUserStats.bankedMinutes))")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        Text("MINUTES BANKED")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(2)
                    }
                    
                    Spacer()
                    
                    // Active Sessions List
                    if !blockingManager.activeSessions.isEmpty {
                        VStack(spacing: 15) {
                            Text("Active Sessions")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                                .tracking(1)
                            
                            ForEach(Array(blockingManager.activeSessions.keys), id: \.self) { token in
                                if let endTime = blockingManager.activeSessions[token], endTime > Date() {
                                    HStack {
                                        Label(token)
                                            .labelStyle(.iconOnly)
                                            .scaleEffect(1.2)
                                        
                                        Spacer()
                                        
                                        Text(timerInterval: Date()...endTime, countsDown: true)
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Button(action: {
                                            blockingManager.cancelSession(for: token)
                                        }) {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.red)
                                                .padding(8)
                                                .background(Color.red.opacity(0.2))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        .padding(.horizontal)
                    }
                    
                    // 1. Select Apps to Block (Direct Picker)
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "shield.fill")
                            Text("Select Apps to Block")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)
                    .familyActivityPicker(isPresented: $isPickerPresented, selection: $blockingManager.selection)
                    .onChange(of: blockingManager.selection) {
                        blockingManager.updateShield()
                    }
                    
                    // 2. Add to Balance
                    Button(action: {
                        showExerciseSelection = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Balance")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cyan)
                        .cornerRadius(15)
                        .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .confirmationDialog("Choose Exercise", isPresented: $showExerciseSelection, titleVisibility: .visible) {
                        Button("Squats") { showSquatView = true }
                        Button("Pushups") { showPushupView = true }
                        Button("Cancel", role: .cancel) { }
                    }
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView(userStats: currentUserStats)
            }
            .fullScreenCover(isPresented: $showSquatView) {
                SquatView()
            }
            .fullScreenCover(isPresented: $showPushupView) {
                PushupView()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerSquatSession"))) { _ in
                showSquatView = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerPushupSession"))) { _ in
                showPushupView = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerExerciseSelection"))) { _ in
                showExerciseSelection = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerBankedUnlock"))) { notification in
                if let tokenData = notification.userInfo?["tokenData"] as? Data {
                    pendingUnlockToken = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData)
                } else {
                    pendingUnlockToken = nil
                }
                showBankedMinutesInput = true
            }
            .alert("Use Banked Minutes", isPresented: $showBankedMinutesInput) {
                TextField("Minutes", text: $minutesToUse)
                    .keyboardType(.numberPad)
                Button("Unlock") {
                    processBankedUnlock()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have \(Int(currentUserStats.bankedMinutes)) minutes available.\nHow many do you want to use?")
            }
            .alert("Insufficient Minutes", isPresented: $showInsufficientFundsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You don't have enough minutes banked for that amount.")
            }
        }
    }
    
    @State private var showBankedMinutesInput = false
    @State private var minutesToUse = ""
    @State private var showInsufficientFundsAlert = false
    @State private var pendingUnlockToken: ApplicationToken?
    
    private func processBankedUnlock() {
        guard let minutes = Int(minutesToUse), minutes > 0 else { return }
        
        if currentUserStats.bankedMinutes >= Double(minutes) {
            currentUserStats.bankedMinutes -= Double(minutes)
            BlockingManager.shared.unblockTemporarily(duration: TimeInterval(minutes * 60), for: pendingUnlockToken)
            minutesToUse = "" // Reset
            pendingUnlockToken = nil
        } else {
            showInsufficientFundsAlert = true
        }
    }
    
    private func canTakeDebt() -> Bool {
        guard let lastDate = currentUserStats.lastDebtDate else { return true }
        return !Calendar.current.isDateInToday(lastDate)
    }
    
    private func handleDebtRequest() {
        if canTakeDebt() {
            currentUserStats.lastDebtDate = Date()
            currentUserStats.debtMinutes += 15
            currentUserStats.bankedMinutes += 15
            BlockingManager.shared.unblockTemporarily(duration: 900)
        }
    }
        }
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                Spacer()
            }
            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    #Preview {
        ContentView()
    }
}
