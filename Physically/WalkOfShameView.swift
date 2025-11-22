import SwiftUI
import Combine

struct WalkOfShameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var inputText = ""
    @State private var timeRemaining = 15
    @State private var timerActive = false
    @State private var showFailAlert = false
    
    let challengeText = "I am choosing to scroll instead of growing stronger."
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Walk of Shame")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.red)
            
            Text("Type the following to unlock for 15 minutes:")
                .multilineTextAlignment(.center)
            
            Text(challengeText)
                .font(.headline)
                .italic()
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .multilineTextAlignment(.center)
            
            TextField("Type here...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            if timerActive {
                Text("Time Remaining: \(timeRemaining)s")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(timeRemaining < 5 ? .red : .primary)
            }
            
            Button(action: {
                validateInput()
            }) {
                Text("Unlock with Shame")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onReceive(timer) { _ in
            if timerActive {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timerActive = false
                    // Time's up, but we don't necessarily fail them immediately, 
                    // just maybe make them restart or show a message.
                    // For now, let's just stop the timer.
                }
            }
        }
        .alert("Incorrect", isPresented: $showFailAlert) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text("You must type the sentence exactly.")
        }
    }
    
    func startTimer() {
        timeRemaining = 15
        timerActive = true
        inputText = ""
    }
    
    func validateInput() {
        if inputText == challengeText {
            BlockingManager.shared.unblockTemporarily()
            dismiss()
        } else {
            showFailAlert = true
        }
    }
}
