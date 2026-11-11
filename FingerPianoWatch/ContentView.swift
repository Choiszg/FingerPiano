import SwiftUI

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    @StateObject private var audio = AudioEngine()
    @State private var sens: Double = 0.5

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("五指弹琴").font(.headline)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ForEach(0..<NOTES.count, id: \.self) { i in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(dotColor(i))
                            .frame(width: 14, height: 14)
                        Text(NOTES[i].finger)
                            .frame(width: 56, alignment: .leading)
                            .font(.caption)
                        Text(NOTES[i].name)
                            .bold()
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                }

                if motion.calibrating || motion.calibFinger == -2 {
                    ProgressView(value: Double(motion.calibCount), total: 4)
                        .padding(.horizontal)
                    Text(calibText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: toggleCalib) {
                    Text(motion.calibrating ? "校准中…" : "校准五指")
                }
                .disabled(motion.calibrating && motion.calibFinger != -2)

                HStack {
                    Text("灵敏度").font(.caption2)
                    Slider(value: $sens, in: 0...1) { }
                }
                .onChange(of: sens) { _, v in motion.sensitivity = v }
            }
            .padding(4)
        }
        .onAppear {
            motion.onNote = { i in
                audio.play(freq: NOTES[i].freq, key: i)
            }
            motion.sensitivity = sens
            motion.start()
        }
        .onDisappear { motion.stop() }
    }

    private func dotColor(_ i: Int) -> Color {
        if motion.lastFinger == i { return Color(hex: NOTES[i].color) }
        return Color.gray.opacity(0.35)
    }

    private var subtitle: String {
        if !motion.running { return "腕部感应：未开启" }
        if motion.templates.count == NOTES.count { return "已校准 · 抖手指演奏" }
        return "尚未校准 · 点下方按钮"
    }

    private var calibText: String {
        if motion.calibFinger == -2 {
            return "校准完成！戴表抖拇指→小指即可奏 do→so"
        }
        if motion.calibFinger < 0 { return "" }
        return "请抖 \(NOTES[motion.calibFinger].finger)\n（\(motion.calibCount)/4）"
    }

    private func toggleCalib() {
        if motion.calibFinger == -2 {
            // 已校准完成，再点则重新校准
            motion.beginCalibration()
        } else if !motion.calibrating {
            motion.beginCalibration()
        }
    }
}

import SwiftUI
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(.sRGB,
                  red: Double((int >> 16) & 0xFF) / 255,
                  green: Double((int >> 8) & 0xFF) / 255,
                  blue: Double(int & 0xFF) / 255,
                  opacity: 1)
    }
}
