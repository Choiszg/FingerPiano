import Foundation

/// 五指 → 五音（do re mi fa so）。拇指到小指依次对应。
struct Note {
    let name: String      // 唱名
    let freq: Double      // 频率 Hz
    let finger: String    // 对应手指
    let color: String     // 用于 UI 高亮（十六进制）
}

let NOTES: [Note] = [
    Note(name: "Do", freq: 261.63, finger: "拇指", color: "#FF5A5F"),
    Note(name: "Re", freq: 293.66, finger: "食指", color: "#FF9F0A"),
    Note(name: "Mi", freq: 329.63, finger: "中指", color: "#FFD60A"),
    Note(name: "Fa", freq: 349.23, finger: "无名指", color: "#30D158"),
    Note(name: "So", freq: 392.00, finger: "小指", color: "#0A84FF"),
]
