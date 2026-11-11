import SwiftUI

/// 手机端只是「载体」，真正的交互在手表上。
/// 用 Xcode 的「Watch App for iOS App」模板时，把本文件放进 iOS Target 即可。
@main
struct FingerPianoiOSApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Image(systemName: "applewatch")
                    .font(.system(size: 44))
                Text("五指弹琴")
                    .font(.title2).bold()
                Text("请在已配对的 Apple Watch 上打开本 App，\n戴表抖拇指→小指即可奏 do→so")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
