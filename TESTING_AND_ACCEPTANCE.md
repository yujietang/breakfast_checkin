# 胆结石早餐打卡 App - 测试与验收指南

## 一、测试概述

本文档提供胆结石早餐打卡 App 的完整测试与验收方法，包括单元测试、集成测试以及 Web 端和安卓端的验收流程。

---

## 二、单元测试

### 2.1 运行单元测试

```bash
# 运行所有单元测试
flutter test

# 运行特定测试文件
flutter test test/models/user_data_test.dart
flutter test test/models/stone_level_test.dart
flutter test test/models/achievement_test.dart
flutter test test/utils/time_utils_test.dart

# 运行 Widget 测试
flutter test test/widget_test.dart
```

### 2.2 单元测试覆盖范围

| 测试文件 | 测试内容 |
|---------|---------|
| `test/models/user_data_test.dart` | UserData 模型、结石等级计算、会员状态、急救卡逻辑 |
| `test/models/stone_level_test.dart` | StoneLevel 定义、等级转换、皮肤系统 |
| `test/models/achievement_test.dart` | Achievement 定义、解锁条件、成就类型 |
| `test/utils/time_utils_test.dart` | 时间窗口检查、日期计算、连续天数计算 |
| `test/widget_test.dart` | 基础 Widget 渲染、导航组件 |

### 2.3 预期测试结果

所有单元测试应该通过，输出类似：
```
00:00 +15: All tests passed!
```

---

## 三、集成测试 / 系统测试

### 3.1 运行集成测试

```bash
# 运行集成测试
flutter test integration_test/app_test.dart

# 在特定设备上运行
flutter test integration_test/app_test.dart -d <device_id>
```

### 3.2 集成测试场景

| 测试场景 | 验证内容 |
|---------|---------|
| 应用启动 | 应用正常启动，显示首页 |
| 免责声明 | 首次启动显示免责声明弹窗 |
| 底部导航 | 4个标签页正常切换 |
| 首页显示 | 打卡按钮、结石视觉、连续天数显示 |
| 统计页面 | 日历、成就墙、月度趋势图显示 |
| 商店页面 | 会员卡片、皮肤列表显示 |
| 数据导出 | 导出对话框正常弹出 |

---

## 四、Web 端验收方法

### 4.1 构建 Web 版本

```bash
# 构建 Web 版本（release 模式）
flutter build web --release

# 构建完成后，文件位于 build/web/ 目录
```

### 4.2 Web 端验收清单

#### 4.2.1 功能验收

| 验收项 | 验收方法 | 预期结果 |
|-------|---------|---------|
| 页面加载 | 打开 `build/web/index.html` | 页面正常加载，无白屏 |
| 免责声明 | 首次访问或使用无痕模式 | 弹出免责声明弹窗 |
| 同意声明 | 点击"我已阅读并同意" | 弹窗关闭，进入首页 |
| 底部导航 | 点击4个底部导航项 | 页面正常切换，无卡顿 |
| 打卡功能 | 在 05:00-11:00 点击打卡按钮 | 显示打卡成功弹窗 |
| 结石显示 | 观察首页中央胆囊图形 | 根据状态显示不同等级结石 |
| 时间限制 | 在非打卡时间尝试打卡 | 显示时间限制提示 |
| 统计页面 | 切换到统计页 | 显示日历热力图、成就、趋势图 |
| 数据导出 | 点击导出按钮 | 弹出导出对话框 |
| 商店页面 | 点击商店图标 | 显示会员卡片和皮肤列表 |

#### 4.2.2 兼容性验收

| 浏览器 | 验收方法 |
|-------|---------|
| Chrome | 打开 DevTools，检查 Console 无错误 |
| Firefox | 检查页面布局正常，功能可用 |
| Edge | 检查页面布局正常，功能可用 |
| Safari | 检查页面布局正常，功能可用 |

#### 4.2.3 响应式验收

| 设备类型 | 验收方法 |
|---------|---------|
| 桌面端 (>1024px) | 页面布局正常，元素不挤压 |
| 平板 (768px-1024px) | 自适应布局，触摸友好 |
| 手机 (<768px) | 移动适配，底部导航正常 |

### 4.3 Web 端启动本地服务器测试

```bash
# 方法1：使用 Python
python -m http.server 8080 --directory build/web

# 方法2：使用 Node.js npx
npx serve build/web -l 8080

# 方法3：使用 VS Code Live Server 插件
# 右键 build/web/index.html -> Open with Live Server

# 访问 http://localhost:8080 进行测试
```

---

## 五、安卓端验收方法

### 5.1 构建安卓版本

```bash
# 构建 APK（调试版）
flutter build apk --debug

# 构建 APK（发布版）
flutter build apk --release

# 构建完成后，文件位于：
# build/app/outputs/flutter-apk/app-debug.apk
# build/app/outputs/flutter-apk/app-release.apk

# 构建 App Bundle（用于 Google Play）
flutter build appbundle --release
```

### 5.2 安装到设备

```bash
# 使用 adb 安装
adb install build/app/outputs/flutter-apk/app-debug.apk

# 或使用 Flutter 直接安装运行
flutter run
```

### 5.3 安卓端验收清单

#### 5.3.1 功能验收

| 验收项 | 验收方法 | 预期结果 |
|-------|---------|---------|
| 应用安装 | 安装 APK 并打开 | 应用正常启动，无崩溃 |
| 启动画面 | 观察启动过程 | 显示启动画面，无白屏 |
| 免责声明 | 首次启动 | 显示免责声明弹窗，不可跳过 |
| 不同意退出 | 点击"不同意" | 应用退出或停留在弹窗 |
| 首页显示 | 进入首页 | 显示结石视觉、打卡按钮、连续天数 |
| 打卡成功 | 在时间内点击打卡 | 显示成功动画和提示 |
| 本地通知 | 设置提醒时间 | 到时间收到通知 |
| 补卡功能 | 昨天未打卡时使用急救卡 | 补卡成功，连续天数保留 |
| 成就解锁 | 达到成就条件 | 显示成就解锁提示 |
| 数据导出 | 点击导出 | 生成 CSV 文件可分享 |

#### 5.3.2 性能验收

| 验收项 | 验收方法 | 预期结果 |
|-------|---------|---------|
| 启动时间 | 从点击图标到首页显示 | < 3 秒 |
| 内存占用 | Android Studio Profiler | < 150 MB |
| 页面切换 | 点击底部导航 | 流畅无卡顿 |
| 打卡响应 | 点击打卡按钮 | < 500ms 响应 |

#### 5.3.3 兼容性验收

| 系统版本 | 验收方法 |
|---------|---------|
| Android 14 (API 34) | 功能正常，UI 正常 |
| Android 13 (API 33) | 功能正常，UI 正常 |
| Android 12 (API 31) | 功能正常，UI 正常 |
| Android 11 (API 30) | 功能正常，UI 正常 |
| Android 10 (API 29) | 功能正常，UI 正常 |

#### 5.3.4 权限验收

| 权限 | 验收方法 |
|-----|---------|
| 通知权限 | 首次启动请求通知权限，可正常设置提醒 |
| 存储权限 | 导出数据时请求存储权限（如需要） |

### 5.4 手动测试用例

#### 用例 1：正常打卡流程
```
1. 打开应用（在 05:00-11:00 之间）
2. 确认已接受免责声明
3. 点击"吃早餐"按钮
4. 验证显示打卡成功弹窗
5. 验证按钮变为"已打卡"
6. 验证连续天数增加
```

#### 用例 2：漏打卡后补卡
```
1. 模拟昨天未打卡状态（清除昨天数据）
2. 今天打开应用
3. 验证显示"补打卡"按钮
4. 点击"补打卡"按钮
5. 验证补卡成功
6. 验证连续天数恢复
```

#### 用例 3：结石等级变化
```
1. 连续打卡 7 天以上，验证结石等级为 0
2. 漏打卡 1 天，验证结石等级变为 1
3. 漏打卡 2-3 天，验证结石等级变为 2
4. 继续漏打卡，验证等级递增
5. 打卡后验证等级下降
```

#### 用例 4：成就解锁
```
1. 连续打卡 7 天
2. 验证解锁"7天完美"成就
3. 查看统计页面成就墙
4. 验证成就徽章显示
```

---

## 六、常见问题排查

### 6.1 Web 端问题

| 问题 | 解决方案 |
|-----|---------|
| 白屏 | 检查 `index.html` 中 base href 设置 |
| 资源加载失败 | 确保使用相对路径或正确配置 base href |
| 本地存储不工作 | Web 版使用替代存储方案 |

### 6.2 安卓端问题

| 问题 | 解决方案 |
|-----|---------|
| 安装失败 | 检查 `minSdkVersion` 和 `targetSdkVersion` |
| 通知不显示 | 检查通知权限和渠道配置 |
| 数据库错误 | 检查数据库版本迁移 |

---

## 七、验收通过标准

### 7.1 单元测试
- [ ] 所有单元测试通过
- [ ] 代码覆盖率 > 70%

### 7.2 功能验收
- [ ] 所有功能验收项通过
- [ ] 无 P0/P1 级别 Bug

### 7.3 性能验收
- [ ] 启动时间 < 3 秒
- [ ] 内存占用 < 150 MB
- [ ] 页面切换流畅

### 7.4 兼容性验收
- [ ] Web 端兼容主流浏览器
- [ ] 安卓端兼容 Android 10+

---

## 八、附录

### 8.1 测试命令汇总

```bash
# 获取 Flutter 环境信息
flutter doctor

# 获取可用设备
flutter devices

# 运行单元测试
flutter test

# 运行集成测试
flutter test integration_test/

# 构建 Web
flutter build web

# 构建安卓 APK
flutter build apk --release

# 构建安卓 App Bundle
flutter build appbundle --release
```

### 8.2 相关文件

| 文件 | 说明 |
|-----|------|
| `lib/models/*.dart` | 数据模型 |
| `lib/screens/*.dart` | 页面 |
| `lib/widgets/*.dart` | 组件 |
| `test/*.dart` | 单元测试 |
| `integration_test/*.dart` | 集成测试 |
