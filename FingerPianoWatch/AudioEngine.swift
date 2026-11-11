import AVFoundation

/// 用 AVAudioEngine 合成钢琴音色（多谐波 + 指数衰减包络），无需任何音频素材文件。
final class AudioEngine: ObservableObject {
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    private var buffers: [Int: AVAudioPCMBuffer] = [:]

    init() {
        engine.attach(player)
        let fmt = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(player, to: engine.mainMixerNode, format: fmt)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[audio] session error: \(error)")
        }

        engine.prepare()
        do { try engine.start() } catch { print("[audio] start error: \(error)") }
        player.play()
    }

    /// 为某个音生成（并缓存）一段钢琴音色 buffer。
    private func buffer(for freq: Double, key: Int) -> AVAudioPCMBuffer {
        if let cached = buffers[key] { return cached }

        let sr = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let duration = 1.6
        let frames = AVAudioFrameCount(sr * duration)
        let fmt = engine.mainMixerNode.outputFormat(forBus: 0)
        let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames)!
        buf.frameLength = frames

        let ch = buf.floatChannelData![0]
        // 谐波结构：基频 + 若干泛音，模拟钢琴频谱
        let harmonics: [(mult: Double, amp: Double)] = [
            (1, 1.0), (2, 0.50), (3, 0.28), (4, 0.14), (5, 0.07), (6, 0.03)
        ]
        for i in 0..<Int(frames) {
            let t = Double(i) / sr
            let env = exp(-2.8 * t) * min(1.0, t / 0.004)   // 快速起音 + 指数衰减
            var s: Float = 0
            for h in harmonics {
                s += Float(h.amp * sin(2.0 * Double.pi * freq * h.mult * t))
            }
            ch[i] = s * Float(env) * 0.25
        }
        buffers[key] = buf
        return buf
    }

    /// 演奏一个音（key 对应 NOTES 的下标）。
    func play(freq: Double, key: Int) {
        player.scheduleBuffer(buffer(for: freq, key: key))
    }
}
