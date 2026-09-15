# 奶娃喝水

奶娃喝水是一款净水设备管理应用，支持短信与登录凭证登录、设备扫码绑定、开始与停止接水、设备状态查询、喝水记录、桌面快捷组件，以及胖乖洗澡二维码跳转。

## 应用截图

| 登录 | 首页 |
| --- | --- |
| ![登录页](lib/static/index.jpg) | ![首页](lib/static/logo.png) |

| 我的 | 胖乖跳转 |
| --- | --- |
| ![个人页](lib/static/me.jpg) | ![胖乖跳转页](lib/static/胖乖.jpg) |

## 本地运行

```bash
flutter pub get
flutter run
```

Android 可执行：

```bash
flutter build apk --release
```

## 构建与安装

GitHub Actions 在推送 `vX.Y.Z` 版本标签后会同时构建：

- `NaiWawate-android.apk`：Android 安装包。
- `NaiWawate-ios-unsigned.ipa`：iOS 未签名安装包。

未签名 IPA 不能直接安装到 iPhone。可使用 Sideloadly、AltStore 等工具通过自己的 Apple ID 重签后安装。

应用内“检查更新”会读取 GitHub 最新 Release：Android 跳转 APK 下载，iOS 跳转 IPA 下载页面。

## 发布版本

GitHub Release 的版本号来自 Git 标签。提交完成后执行以下命令即可发布：

```bash
git tag v1.0.1
git push origin v1.0.1
```

工作流会自动：

- 构建 Android APK 与未签名 iOS IPA。
- 创建名为 `NaiWawate v1.0.1` 的 GitHub Release。
- 上传 `NaiWawate-android.apk` 和 `NaiWawate-ios-unsigned.ipa`。

请将 `v1.0.1` 替换为实际版本号，并同步更新 `pubspec.yaml` 中的 `version`。
