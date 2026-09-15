# iOS GitHub Actions

工作流文件为 `.github/workflows/ios-build.yml`。推送到 GitHub 后，在仓库的 Actions 页面选择“构建 iOS”，再点击“Run workflow”。

默认模式输出未签名 IPA，可作为 Sideloadly、AltStore 等工具的本地重签输入。未签名 IPA 不能直接安装到 iPhone。

要输出可分发的 Ad Hoc IPA，触发时勾选“使用 Apple 证书签名并导出 IPA”，并在 GitHub 仓库的 Settings > Secrets and variables > Actions 中设置：

- `IOS_CERTIFICATE_BASE64`：发布证书 `.p12` 文件的 Base64 内容。
- `IOS_CERTIFICATE_PASSWORD`：导出 `.p12` 时设置的密码。
- `IOS_PROVISIONING_PROFILE_BASE64`：匹配当前 Bundle Identifier 的 Ad Hoc 描述文件 `.mobileprovision` 的 Base64 内容。
- `KEYCHAIN_PASSWORD`：任意用于 CI 临时钥匙串的高强度密码。

PowerShell 中可生成 Base64：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('certificate.p12'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('profile.mobileprovision'))
```

证书和描述文件必须来自同一 Apple Developer Team，并与 `ios/Runner.xcodeproj` 中配置的 Bundle Identifier 匹配。
