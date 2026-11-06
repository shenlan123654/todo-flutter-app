# 便宜启程 · iOS 版

这是「便宜启程」的 Flutter iOS 工程，功能包括：

- 每日清单：添加/编辑/删除、每天重复或仅一次、勾选、每日自动重置
- 提醒：本地通知，完成 / 稍后10分钟
- 我的：今日、本周、本月完成率，打卡天数与连续打卡
- 设置：提醒总开关、震动提示（Android）、默认提醒时间、权限检查、清除数据、大西洋Fire！
- 自定义：主页面/其它页面背景、字体颜色与大小、任务方框样式、任务图标（emoji/PNG）、应用内 Logo
- 其它工具：大西洋记事本（文字、图片、剪贴板）、rote听歌（导入 MP3、循环、倍速、后台播放）

> 本次只维护 iOS 方向。`android/` 目录还在，但安卓构建/打包先不处理。

## 本机限制

- 当前电脑是 Windows，**不能编译 iOS、不能运行 iOS 模拟器**。
- 没有生成 IPA；必须 macOS + Xcode 或云端 Mac（Codemagic）才能构建和签名。
- 需要 Apple Developer Program（$99/年）才能用 TestFlight 或上架。

## 在 Mac 上本地构建

1. 安装 macOS 14+、Xcode 16+、Flutter 3.47.9、CocoaPods。
2. 进入项目目录：

```bash
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

3. 在 Xcode 里选择 Runner target：
   - Signing & Capabilities → 选择你的 Team
   - Bundle Identifier：`com.pianyi.qicheng.flutter`（可改成你自己的唯一 ID）
   - 确认 Background Modes 里有 Audio（Info.plist 已声明）
4. 连接 iPhone，选择真机，Run；首次运行在手机上允许通知、相册权限。

## TestFlight / 上架

1. Xcode：Product → Archive → Distribute App → App Store Connect → Upload。
2. App Store Connect 创建 App（Bundle ID 选 `com.pianyi.qicheng.flutter`），在 TestFlight 里添加测试员。
3. 外部测试首个构建需要 Beta 审核；正式上架还需要隐私清单、截图、中国区 App 备案（ICP）。

## 云端 Mac（Codemagic）

项目根目录已包含 `codemagic.yaml`：

- `ios-compile-check`：不签名，只验证能否编译，适合先看日志。
- `ios-testflight`：需要先在 Codemagic 里连接 Apple Developer 和 App Store Connect，自动签名并上传 TestFlight。

没有苹果账号时只能跑第一个 workflow；第二个会在签名阶段失败。

## iOS 与安卓的差异

- 自定义铃声：iOS 通知铃声必须打包进 App，**当前版本只用系统默认铃声**，不能运行时导入。
- 震动开关 / 通知音量：iOS 系统控制，App 内不提供独立开关。
- 提醒：iOS 本地通知不需要精确闹钟权限，但**一个 App 最多 64 条待发通知**；本工程按任务数量自动控制提前天数。
- 剪贴板：iOS 16+ 读取剪贴板会弹“允许粘贴”，需要用户点一下。
- 桌面图标：固定，不能运行时替换；应用内 Logo 可以换。

## 代码检查

在 Windows 上可以跑：

```bash
flutter analyze   # 只剩少量 info，无 error
flutter test      # 8 个统计/打卡/提醒单测通过
```

iOS 的真实编译、通知、后台播放、锁屏控制必须在 Mac/iPhone 上验证。
