# iOS 部署指南

## ⚠️ 重要提示

**Windows 无法直接构建 iOS 版本**，需要以下方案之一：

---

## 方案1: 使用 Codemagic CI/CD（推荐，免费）

### 步骤1: 上传代码到 GitHub

```bash
# 在项目根目录执行
git init
git add .
git commit -m "Initial commit"

# 创建 GitHub 仓库后执行
git remote add origin https://github.com/你的用户名/breakfast-checkin.git
git push -u origin main
```

### 步骤2: 注册 Codemagic

1. 访问 [codemagic.io](https://codemagic.io)
2. 用 GitHub 账号登录
3. 点击 "Add application"
4. 选择你的 GitHub 仓库

### 步骤3: 配置构建

1. 在 Codemagic 中点击 "Start new build"
2. 选择 Workflow: `ios-build`（已配置在 codemagic.yaml）
3. 点击 "Start build"

等待约 10-15 分钟，构建完成后会收到邮件，下载 IPA 文件。

### 步骤4: 安装到手机

#### 方法A: TestFlight（推荐）
需要 Apple Developer 账号（$99/年）

1. 在 App Store Connect 创建应用
2. 上传 IPA 到 TestFlight
3. 在 iPhone 上下载 TestFlight APP
4. 接受邀请安装测试版

#### 方法B: Ad Hoc 分发（无需付费）
1. 注册免费 Apple ID
2. 使用 [ Diawi ](https://www.diawi.com/) 或 [ InstallOnAir ](https://installonair.com/)
3. 上传 IPA 文件
4. 在 iPhone 上打开生成的链接安装

**注意**: Ad Hoc 方式安装后，需要在 iPhone 设置中信任开发者证书：
`设置 → 通用 → VPN与设备管理 → 信任 [你的Apple ID]`

---

## 方案2: 使用 Mac 电脑（如果你有的话）

### 要求
- Mac 电脑（MacBook / iMac / Mac mini）
- Xcode（免费，App Store下载）
- Apple ID（免费注册）

### 步骤

```bash
# 1. 克隆代码到 Mac
git clone https://github.com/你的用户名/breakfast-checkin.git
cd breakfast-checkin

# 2. 获取依赖
flutter pub get

# 3. 打开 iOS 项目
cd ios
pod install
cd ..

# 4. 用 Xcode 打开
open ios/Runner.xcworkspace
```

在 Xcode 中：
1. 选择你的 Apple ID 作为 Team
2. 连接 iPhone
3. 选择你的设备作为目标
4. 点击运行按钮

---

## 方案3: 找有 Mac 的朋友帮忙

1. 把代码发给他
2. 让他按方案2构建
3. 导出 IPA 文件发给你
4. 你用 Diawi 安装

---

## 快速测试（无需构建）

如果你想先体验APP，可以：

1. **用浏览器打开 Web 版**：
   ```
   http://localhost:8080
   ```
   （按之前步骤启动服务器）

2. **用 Android 手机测试**（如果有）：
   Windows 可以直接构建 Android APK

---

## 常见问题

### Q: 为什么 Windows 不能构建 iOS？
A: Apple 限制 iOS 开发必须在 macOS + Xcode 环境下进行。

### Q: 免费 Apple ID 有什么限制？
A: 
- 免费账号：App 7天后过期，需要重新安装
- 付费账号（$99/年）：App 1年后过期，可上架 App Store

### Q: Codemagic 收费吗？
A: 免费版每月 500 分钟构建时间，足够个人使用。

---

## 需要帮助？

告诉我你当前的情况，我可以提供更具体的指导：
1. 有 Mac 电脑吗？
2. 有 Apple ID 吗？
3. 有 GitHub 账号吗？
4. 有 Android 手机可以测试吗？
