# 奶娃喝水

奶娃喝水是一款净水设备管理应用，支持短信与登录凭证登录、设备扫码绑定、开始与停止接水、设备状态查询、喝水记录、桌面快捷组件，以及胖乖洗澡二维码跳转。

## 本地运行

```bash
flutter pub get
flutter run
```

Android 可执行：

```bash
flutter build apk --release
```

## iOS 构建与安装

GitHub Actions 在 `main` 分支每次推送后会构建未签名 IPA，可在 Actions 的构建产物中下载。

未签名 IPA 不能直接安装到 iPhone。可使用 Sideloadly、AltStore 等工具通过自己的 Apple ID 重签后安装。

更完整的 iOS 签名说明见 [docs/ios-github-actions.md](docs/ios-github-actions.md)。

## 发布版本

GitHub Release 的版本号来自 Git 标签。提交完成后执行以下命令即可发布：

```bash
git tag v1.0.1
git push origin v1.0.1
```

工作流会自动：

- 使用 macOS runner 构建未签名 iOS IPA。
- 创建名为 `奶娃喝水 v1.0.1` 的 GitHub Release。
- 将 `naiva-drink-unsigned.ipa` 上传到该 Release。

请将 `v1.0.1` 替换为实际版本号，并同步更新 `pubspec.yaml` 中的 `version`。
