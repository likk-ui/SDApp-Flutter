# SDApp Flutter 项目

视力训练应用的 Flutter 跨平台版本，可同时运行在 iOS 和 Android 上。

## 功能

- 用户登录系统
- 主界面（显示剩余时间、今日训练时长）
- 光栅训练模块（视光训练动画）
- 在线播放器模块（动画片播放）

## 构建 iOS 版本

### 前置条件

1. 安装 Flutter SDK: https://flutter.dev/docs/get-started/install
2. macOS 系统（iOS 构建需要 Xcode）

### 构建步骤

```bash
# 1. 进入项目目录
cd SDApp_Flutter

# 2. 安装依赖
flutter pub get

# 3. 构建 iOS
flutter build ios --release
```

### 生成 IPA 文件

```bash
flutter build ios --release --no-codesign
```

然后使用 Xcode 签名并导出 IPA：
1. 打开 `build/ios/iphoneos/Runner.app`
2. 在 Xcode 中选择 Product → Archive
3. 导出 IPA

## 文件结构

```
SDApp_Flutter/
├── lib/
│   ├── main.dart           # 主入口
│   ├── screens/
│   │   ├── login_screen.dart    # 登录页面
│   │   ├── home_screen.dart     # 主界面
│   │   ├── section1_screen.dart # 光栅训练
│   │   └── section2_screen.dart  # 在线播放器
│   └── services/
│       └── api_service.dart     # API 服务
├── ios/                    # iOS 配置
├── android/               # Android 配置
├── assets/                # 资源文件
└── pubspec.yaml           # 项目配置
```

## API 配置

修改 `lib/services/api_service.dart` 中的 `baseUrl` 为您的后端地址：

```dart
static const String baseUrl = 'http://your-api-server.com/api.php';
```

## 许可证

MIT