# 五指弹琴 · 腕部感应版（watchOS 原生 App）

把 **Apple Watch 戴在手腕上抖不同手指** → 手表加速度计/陀螺仪识别手势 → 播放对应音符：

| 手指 | 唱名 | 频率 |
|---|---|---|
| 拇指 | Do  | 261.63 Hz |
| 食指 | Re  | 293.66 Hz |
| 中指 | Mi  | 329.63 Hz |
| 无名指 | Fa | 349.23 Hz |
| 小指 | So  | 392.00 Hz |

不需要越狱、不需要付费证书（免费 Apple ID 即可，7 天续签一次）。
你的环境：**手表 watchOS 11.5 + iPhone iOS 16.7（已通过你的渠道配对）**。
watchOS 11 能跑现代 watch 应用，所以走「原生 watch App + 免费签名侧载」这条路是通的。

---

## 一、准备编译环境（Windows 用户）

watchOS App 必须用 **Xcode（仅 macOS）** 编译，Windows 上无法直接编。二选一：

1. **macOS 虚拟机**（推荐，本地最稳）：在 Windows 上用 VMware Workstation / VirtualBox 装一台 macOS Sequoia 虚拟机，再装 Xcode 16+（watchOS 11 SDK 需要 Xcode 16）。
2. **云 Mac**：MacStadium / 临时租一台，把工程拷过去编译后部署。

> 你的 iPhone 是 iOS 16.7，不影响「往手表部署 watch App」——Xcode 是把 watch App 装进已配对的手表，iPhone 系统版本只决定手机端 App，不阻断手表端部署。

---

## 二、在 Xcode 里建工程并粘贴代码

1. 打开 Xcode 16 → `File → New → Project → watchOS → Watch App for iOS App`（勾选 Include Companion App）。
2. 产品名 `FingerPiano`，Team 先留空，语言 Swift，界面 SwiftUI。
3. Xcode 会生成：
   - `FingerPiano Watch App/` （手表端）
   - `FingerPiano/` 或 `FingerPiano iOS/` （手机端载体）
4. **删除** 手表端自动生成的 `App.swift / ContentView.swift` 等，把我们提供的这 5 个文件**整目录覆盖**进手表端 Target：
   - `App.swift`
   - `Notes.swift`
   - `AudioEngine.swift`
   - `MotionManager.swift`
   - `ContentView.swift`
5. 手机端载体保留默认即可；如果想用我们的极简版，把 `FingerPianoiOS/App.swift` 覆盖进 iOS Target（可选）。
6. 确认手表端 `FingerPianoWatchApp` 的 `@main` 在手表 Target，iOS 端 `@main` 在 iOS Target，互不冲突。

---

## 三、签名并装到手表（免费 Apple ID）

1. Xcode 顶部选 Scheme = **FingerPiano Watch App**，运行设备选 **你的实体手表**。
2. `Signing & Capabilities`：
   - 点 `Team` → `Add Account` → 登录你的 **普通 Apple ID**（小号更稳）。
   - Bundle Identifier 改成**你独有的**，例如 `com.<你的名>.fingerpiano`（默认的 `com.example` 会被拒）。
3. iPhone 用数据线连 Mac 并**信任电脑**；手表需已通过你的渠道配对到这台 iPhone。
4. 点 ▶ Run。首次安装会在手表上弹「未受信任的开发者」：
   手表 → `设置 → 通用 → 设备管理 → 信任你的 Apple ID`。
5. 手表上出现「五指弹琴」即可打开。

> 免费签名有效期 **7 天**。到期手表端打不开，重新连 Mac 点一次 Run 即可续签（或用 SideStore/AltStore 的 watch 部署通道免电脑续签）。

---

## 四、使用

1. 打开 App，先看顶部状态：若显示「尚未校准」，点 **校准五指**。
2. 按提示依次抖 **拇指 → 食指 → 中指 → 无名指 → 小指**，每根抖 4 次（手表会显示 `x/4`）。
   - 建议：手放松垂下，手腕自然，每抖一下间隔 >0.5 秒。
   - 不同手指抖动手腕的惯性方向不同，手表据此建模板。
3. 校准完成后顶部显示「已校准 · 抖手指演奏」。之后戴表直接抖对应手指即出 do→so。
4. 灵敏度滑块：环境晃动手抖误触多就调低，反应慢就调高。

---

## 五、原理（给想调参的人）

- `MotionManager` 以 100Hz 读 `CMDeviceMotion.userAcceleration`（去重力加速度）+ `rotationRate`。
- 用加速度**突变（jerk）** 触发一次「手指抖动事件」，取当前采样点 6 维 `[ax,ay,az,rx,ry,rz]` 归一化为单位向量作为特征。
- 校准阶段为每根手指建一个平均单位向量模板；演奏时取余弦相似度最高的模板，超过 0.55 门限才出声（防误触）。
- `AudioEngine` 用 `AVAudioEngine` + 多谐波指数衰减包络**实时合成**钢琴音，无需任何音频文件。

可调参数（都在 `MotionManager.swift`）：
- `threshold = 0.25 + (1 - sensitivity) * 1.1`：灵敏度映射。
- `now - lastFire > 0.35`：防抖窗口（秒）。
- `curSamples.count >= 4`：每指校准采集次数。
- `bestSim > 0.55`：识别门限，调高更准但更难触发。

---

## 六、iPhone 端兜底（无 Mac 时）

目录同级 `../index.html` 是一个**网页版五指弹琴**：Safari 打开 → 分享 → 添加到主屏幕，用**手机自身**动作感应（非手表）演奏，iOS 16.7 直接能跑。
它满足「免费、iOS 16、不越狱」的兜底需求；但你要的「手表腕部感应」只有上面的原生 watch App 能实现。

---

## 七、不想装虚拟机？用 GitHub Actions 云 Mac 帮你编译

watchOS 编译只能在 macOS + Xcode 上跑，本机 Windows 出不了包。但**不用在你电脑上装虚拟机**：把工程推到 GitHub，GitHub 的云 Mac 自动编译 + 签名，产出 .ipa 给你下载。

### 1. 准备仓库
```bash
cd "C:/Users/choiszg/WorkBuddy/2026-11-12-02-09-01/finger-piano/watch-app"
git init
git add .
git commit -m "FingerPiano watch app"
git branch -M main
git remote add origin https://github.com/<你的名>/FingerPiano.git
git push -u origin main
```
（需要 GitHub 账号；push 时按提示用 token / 账号密码认证。）

### 2. 在仓库设置里加 3 个 Secrets
`Settings → Secrets and variables → Actions → New repository secret`：
- `APPLE_ID`：你的普通 Apple ID（建议小号）
- `APPLE_PASSWORD`：**App 专用密码**（appleid.apple.com → 登录与安全 → App 专用密码生成），不是账号密码
- `TEAM_ID`：Apple ID 对应的 10 位 Team ID（appleid.apple.com → 左下角「团队」处）

### 3. 运行工作流
`Actions → Build FingerPiano (watchOS) → Run workflow`。
- 第一步（编译校验）**永远跑**，证明代码能编过；
- 填了 Secrets 才会跑「Archive + sign」，结束后在 `Artifacts → FingerPiano-ipa` 下载签名好的 .ipa。

### 4. 安装到手表
把下载的 iOS .ipa（里面已嵌入手表 App）用你现有的侧载/配对渠道装到已配对的 iPhone：
- 装好 iPhone 端后，配对的手表会自动拉取手表 App（标准 watch-in-iOS 嵌入结构）；
- 或按你原来的「渠道」把 .ipa 推到手表。
- 首次打开：手表 → 设置 → 通用 → 设备管理 → 信任你的 Apple ID。
- 免费签名 **7 天**，到期重跑一次 workflow 重新下载安装即可。

> 注意：免费 Apple ID 自动签名在 CI 里偶尔会因 watchOS 描述文件创建失败而 export 报错；若遇到，本地用 Xcode 跑一次 Run 即可（仍不需要在本机装 macOS 虚拟机，CI 失败只是云端签名策略问题）。
> 没 GitHub 也不想弄 Secrets 的话，工作流仍会跑「编译校验」给你确认代码没问题，只是不出 .ipa——这时最简方案是借一台 Mac（朋友/网吧/云 Mac）跑一次 Xcode Run。
