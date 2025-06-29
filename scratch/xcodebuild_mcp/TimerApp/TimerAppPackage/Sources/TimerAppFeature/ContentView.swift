import SwiftUI

public struct ContentView: View {
    @State private var timeRemaining = 0
    @State private var initialTime = 0
    @State private var isRunning = false
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var showingTimePicker = false
    @State private var pulseAnimation = false
    @State private var rotationAnimation = 0.0
    
    @Environment(\.colorScheme) var colorScheme
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    var progress: Double {
        guard initialTime > 0 else { return 0 }
        return Double(initialTime - timeRemaining) / Double(initialTime)
    }
    
    var gradientColors: [Color] {
        if colorScheme == .dark {
            return [Color(red: 0.2, green: 0.1, blue: 0.4), Color(red: 0.1, green: 0.05, blue: 0.2)]
        } else {
            return [Color(red: 0.9, green: 0.7, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 0.9)]
        }
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.5, green: 0.2, blue: 1.0),
                Color(red: 0.9, green: 0.3, blue: 0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background circles
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: index == 0 ? -100 : (index == 1 ? 100 : 0),
                        y: index == 0 ? -50 : (index == 1 ? 50 : 100)
                    )
                    .blur(radius: 30)
                    .opacity(0.5)
                    .animation(
                        Animation.easeInOut(duration: Double(index + 3))
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
            }
            
            VStack(spacing: 40) {
                // Title
                Text("TIMER")
                    .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                if showingTimePicker {
                    // Time picker with glassmorphism
                    VStack(spacing: 20) {
                        HStack(spacing: 30) {
                            TimePickerColumn(value: $hours, range: 0..<24, label: "H")
                            TimePickerColumn(value: $minutes, range: 0..<60, label: "M")
                            TimePickerColumn(value: $seconds, range: 0..<60, label: "S")
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showingTimePicker = false
                                timeRemaining = hours * 3600 + minutes * 60 + seconds
                                initialTime = timeRemaining
                            }
                        }) {
                            Text("Set Timer")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 44)
                                .background(accentGradient)
                                .clipShape(Capsule())
                                .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                } else {
                    // Timer display
                    ZStack {
                        // Outer glow
                        Circle()
                            .stroke(
                                accentGradient,
                                lineWidth: 2
                            )
                            .frame(width: 250, height: 250)
                            .blur(radius: 15)
                            .opacity(isRunning ? 0.8 : 0.3)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRunning)
                        
                        // Progress ring
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 20)
                            .frame(width: 220, height: 220)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                accentGradient,
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)
                        
                        // Rotating decoration
                        if isRunning {
                            Circle()
                                .fill(accentGradient)
                                .frame(width: 12, height: 12)
                                .offset(y: -110)
                                .rotationEffect(.degrees(rotationAnimation))
                                .shadow(color: .purple, radius: 5)
                        }
                        
                        // Time display
                        VStack(spacing: 10) {
                            if timeRemaining == 0 && initialTime == 0 {
                                Button(action: {
                                    withAnimation(.spring()) {
                                        showingTimePicker = true
                                    }
                                }) {
                                    VStack(spacing: 5) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(accentGradient)
                                        Text("Set Timer")
                                            .font(.system(size: 18, weight: .light))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Text(timeString(from: timeRemaining))
                                    .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.9)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                                
                                if timeRemaining == 0 && !isRunning {
                                    Text("Complete!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(accentGradient)
                                        .opacity(pulseAnimation ? 1 : 0.5)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulseAnimation)
                                }
                            }
                        }
                    }
                    .frame(width: 250, height: 250)
                    
                    // Control buttons
                    if timeRemaining > 0 || initialTime > 0 {
                        HStack(spacing: 20) {
                            // Play/Pause button
                            Button(action: {
                                withAnimation(.spring()) {
                                    if isRunning {
                                        isRunning = false
                                    } else if timeRemaining > 0 {
                                        isRunning = true
                                    } else {
                                        timeRemaining = initialTime
                                        isRunning = true
                                    }
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(accentGradient)
                                        .offset(x: isRunning ? 0 : 2)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .scaleEffect(isRunning ? 1.1 : 1)
                            .animation(.spring(), value: isRunning)
                            
                            // Reset button
                            Button(action: {
                                withAnimation(.spring()) {
                                    isRunning = false
                                    timeRemaining = 0
                                    initialTime = 0
                                    showingTimePicker = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear {
            pulseAnimation = true
        }
        .onReceive(timer) { _ in
            if isRunning && timeRemaining > 0 {
                timeRemaining -= 1
                rotationAnimation += 360.0 / Double(initialTime)
                if timeRemaining == 0 {
                    isRunning = false
                    NSSound.beep()
                    // Add haptic feedback if available
                    NSHapticFeedbackManager.defaultPerformer.perform(
                        .generic,
                        performanceTime: .default
                    )
                }
            }
        }
    }
    
    private func timeString(from totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct TimePickerColumn: View {
    @Binding var value: Int
    let range: Range<Int>
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Picker("", selection: $value) {
                ForEach(range, id: \.self) { i in
                    Text("\(i)")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                        .tag(i)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 70, height: 40)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    ContentView()
}