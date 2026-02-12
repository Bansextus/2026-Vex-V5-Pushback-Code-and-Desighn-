import SwiftUI
import AppKit

struct ContentView: View {
    @State private var poses: [Pose] = []
    @State private var currentIndex = 0
    @State private var playing = false
    @State private var playbackRate = 1.0
    @State private var lastTimestamp: Date? = nil
    @State private var logName: String = ""
    @State private var errorMessage: String = ""

    @State private var fieldSize = "144"
    @State private var trackWidth = "12"
    @State private var maxSpeed = "60"

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            header
            FieldReplayView(poses: poses, fieldSizeIn: fieldSizeValue, index: currentIndex)
                .frame(maxWidth: 720)

            controls
            readout
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.92), Color(red: 0.96, green: 0.93, blue: 0.88)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onReceive(timer) { now in
            guard playing, poses.count > 1 else { return }
            guard let last = lastTimestamp else {
                lastTimestamp = now
                return
            }

            let dt = now.timeIntervalSince(last) * playbackRate
            lastTimestamp = now

            let currentTime = poses[currentIndex].t
            let targetTime = currentTime + dt

            while currentIndex < poses.count - 1 && poses[currentIndex + 1].t <= targetTime {
                currentIndex += 1
            }

            if currentIndex >= poses.count - 1 {
                playing = false
            }
        }
        .frame(minWidth: 840, minHeight: 860)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bonkers Field Replay")
                    .font(.system(size: 20, weight: .bold))
                Text(logName.isEmpty ? "No log loaded" : logName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Log") {
                openLogFile()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.99, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.78, green: 0.7, blue: 0.63), lineWidth: 2)
        )
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(playing ? "Pause" : "Play") {
                    togglePlay()
                }
                .buttonStyle(.bordered)

                Button("Reset") {
                    resetPlayback()
                }
                .buttonStyle(.bordered)

                Picker("Speed", selection: $playbackRate) {
                    Text("0.5x").tag(0.5)
                    Text("1x").tag(1.0)
                    Text("2x").tag(2.0)
                    Text("4x").tag(4.0)
                }
                .pickerStyle(.segmented)
            }

            Slider(value: Binding(
                get: { Double(currentIndex) },
                set: { value in
                    playing = false
                    lastTimestamp = nil
                    currentIndex = min(max(Int(value.rounded()), 0), max(poses.count - 1, 0))
                }
            ), in: 0...Double(max(poses.count - 1, 0)), step: 1)

            HStack(spacing: 12) {
                settingsField("Field Size (in)", text: $fieldSize)
                settingsField("Track Width (in)", text: $trackWidth)
                settingsField("Max Speed (in/s)", text: $maxSpeed)
                Button("Apply") {
                    applySettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.99, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.78, green: 0.7, blue: 0.63), lineWidth: 2)
        )
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: 6) {
            if poses.isEmpty {
                Text(errorMessage.isEmpty ? "Load a log file (.txt or .csv) to begin." : errorMessage)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(errorMessage.isEmpty ? .secondary : .red)
            } else {
                let pose = poses[currentIndex]
                Text(String(format: "t=%.2fs  x=%.1fin  y=%.1fin", pose.t, pose.x, pose.y))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                Text(String(format: "left=%.0f  right=%.0f", pose.leftCmd, pose.rightCmd))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                Text(String(format: "A1=%.0f A2=%.0f A3=%.0f A4=%.0f", pose.axis1, pose.axis2, pose.axis3, pose.axis4))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                Text("last=\(pose.action)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 1.0, green: 0.99, blue: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.78, green: 0.7, blue: 0.63), lineWidth: 2)
        )
    }

    private func settingsField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .frame(width: 120)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var fieldSizeValue: Double {
        Double(fieldSize) ?? 144.0
    }

    private func togglePlay() {
        if poses.isEmpty { return }
        playing.toggle()
        lastTimestamp = nil
    }

    private func resetPlayback() {
        playing = false
        currentIndex = 0
        lastTimestamp = nil
    }

    private func applySettings() {
        guard let loaded = currentLogURL else { return }
        loadLog(url: loaded)
    }

    @State private var currentLogURL: URL? = nil

    private func openLogFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["csv", "txt"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            loadLog(url: url)
        }
    }

    private func loadLog(url: URL) {
        do {
            let samples = try ReplayEngine.parseLog(url: url)
            let settings = ReplaySettings(
                fieldSizeIn: fieldSizeValue,
                trackWidthIn: Double(trackWidth) ?? 12.0,
                maxSpeedInPerS: Double(maxSpeed) ?? 60.0,
                dtFallback: 0.02
            )
            poses = ReplayEngine.integrate(samples: samples, settings: settings)
            currentIndex = 0
            playing = false
            lastTimestamp = nil
            errorMessage = poses.isEmpty ? "Log file has no data rows." : ""
            logName = url.lastPathComponent
            currentLogURL = url
        } catch {
            errorMessage = "Failed to load log: \(error.localizedDescription)"
            poses = []
            logName = ""
            currentLogURL = nil
        }
    }
}
