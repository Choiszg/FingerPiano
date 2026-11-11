import CoreMotion
import Combine

/// 通过手表的加速度计 + 陀螺仪，识别「抖某一根手指」的手腕惯性特征，
/// 把 拇指→小指 映射到 do→so。首次使用需校准（每根手指抖几次建模板）。
final class MotionManager: ObservableObject {
    private let motion = CMMotionManager()
    private let queue = OperationQueue()

    @Published var running = false
    @Published var lastFinger = -1          // 最近触发的手指下标（用于 UI 高亮）
    @Published var calibFinger = -1         // 正在校准的手指下标；-2 表示完成；-1 空闲
    @Published var calibCount = 0           // 当前手指已采集样本数

    /// 灵敏度 0..1：越高阈值越低，越容易触发。
    var sensitivity: Double = 0.5

    /// 识别到音符时的回调（主线程）。
    var onNote: ((Int) -> Void)?

    // MARK: - 校准状态
    var calibrating = false
    private var curFinger = 0
    private var curSamples: [[Double]] = []
    /// 每根手指一个归一化特征向量（6 维单位向量），未校准则为空。
    var templates: [[Double]] = []

    // MARK: - 运行期状态
    private var prev: (ax: Double, ay: Double, az: Double,
                       rx: Double, ry: Double, rz: Double, mag: Double)?
    private var lastFire: TimeInterval = 0
    private let sampleLen = 6

    // MARK: - 生命周期
    func start() {
        guard motion.isDeviceMotionAvailable else {
            print("[motion] device motion unavailable")
            return
        }
        motion.deviceMotionUpdateInterval = 1.0 / 100.0
        queue.qualityOfService = .userInteractive
        motion.startDeviceMotionUpdates(to: queue) { [weak self] dm, _ in
            guard let self = self, let dm = dm else { return }
            let ua = dm.userAcceleration
            let rr = dm.rotationRate
            let mag = sqrt(ua.x*ua.x + ua.y*ua.y + ua.z*ua.z)
            self.process(ax: ua.x, ay: ua.y, az: ua.z,
                         rx: rr.x, ry: rr.y, rz: rr.z, mag: mag)
        }
        DispatchQueue.main.async { self.running = true }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        DispatchQueue.main.async { self.running = false }
    }

    // MARK: - 核心处理
    private func process(ax: Double, ay: Double, az: Double,
                         rx: Double, ry: Double, rz: Double, mag: Double) {
        let now = Date().timeIntervalSince1970
        defer { prev = (ax, ay, az, rx, ry, rz, mag) }
        guard let p = prev else { return }

        let jerk = abs(mag - p.mag)
        // 灵敏度高 → 阈值低
        let threshold = 0.25 + (1.0 - sensitivity) * 1.1
        guard jerk > threshold else { return }
        guard now - lastFire > 0.35 else { return }   // 防抖：350ms 内只认一次
        lastFire = now

        // 以当前采样点构造 6 维方向特征（加速度 + 角速度），归一化为单位向量
        let raw = [ax, ay, az, rx, ry, rz]
        guard let f = normalize(raw), !f.contains(where: { $0.isNaN || $0.isInfinite }) else { return }

        if calibrating {
            curSamples.append(f)
            DispatchQueue.main.async { self.calibCount = self.curSamples.count }
            if curSamples.count >= 4 { finishFinger() }
        } else {
            if let idx = classify(f) {
                DispatchQueue.main.async {
                    self.lastFinger = idx
                    self.onNote?(idx)
                }
            }
        }
    }

    // MARK: - 校准流程
    func beginCalibration() {
        templates = []
        calibrating = true
        curFinger = 0
        startFinger(0)
    }

    private func startFinger(_ i: Int) {
        curFinger = i
        curSamples = []
        DispatchQueue.main.async { self.calibFinger = i; self.calibCount = 0 }
    }

    private func finishFinger() {
        // 取该手指所有样本的平均向量再归一化，作为模板
        var sum = [Double](repeating: 0, count: sampleLen)
        for s in curSamples { for i in 0..<sampleLen { sum[i] += s[i] } }
        let avg = normalize(sum.map { $0 / Double(curSamples.count) }) ?? sum
        templates.append(avg)
        DispatchQueue.main.async { self.calibFinger = -1 }

        if curFinger < NOTES.count - 1 {
            startFinger(curFinger + 1)
        } else {
            calibrating = false
            DispatchQueue.main.async { self.calibFinger = -2 }   // 全部完成
        }
    }

    // MARK: - 识别
    /// 返回余弦相似度最高的手指下标；低于门限则返回 nil（避免误触）。
    private func classify(_ f: [Double]) -> Int? {
        guard templates.count == NOTES.count else { return nil }
        var best = -1, bestSim = -1.0
        for i in 0..<NOTES.count {
            let sim = cosine(f, templates[i])
            if sim > bestSim { bestSim = sim; best = i }
        }
        return bestSim > 0.55 ? best : nil
    }

    // MARK: - 工具
    private func normalize(_ v: [Double]) -> [Double]? {
        let n = sqrt(v.reduce(0) { $0 + $1 * $1 })
        guard n > 1e-6 else { return nil }
        return v.map { $0 / n }
    }

    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        var dot = 0.0, na = 0.0, nb = 0.0
        for i in 0..<a.count {
            dot += a[i] * b[i]; na += a[i] * a[i]; nb += b[i] * b[i]
        }
        guard na > 0, nb > 0 else { return 0 }
        return dot / (sqrt(na) * sqrt(nb))
    }
}
