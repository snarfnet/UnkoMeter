# Submission Checklist

## 1. App Store Connect

- Create a new app named `UnkoMeter`.
- Platform: iOS
- Bundle ID: `com.tokyonasu.UnkoMeter`
- SKU: `unkometer-ios`
- Primary language: Japanese
- Category: Health & Fitness

## 2. Apple Developer Signing

Create these items in Apple Developer:

- App ID for `com.tokyonasu.UnkoMeter`
- App Store distribution certificate
- App Store provisioning profile named `UnkoMeter App Store`

The profile name must match `ExportOptions.plist` and the upload workflow.

## 3. GitHub Secrets

Add these repository secrets in GitHub:

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_API_KEY_P8`

Encoding commands on macOS:

```sh
base64 -i distribution_certificate.p12 | pbcopy
base64 -i UnkoMeter_App_Store.mobileprovision | pbcopy
```

For `ASC_API_KEY_P8`, paste the full `.p8` file text, including the BEGIN and END lines.

## 4. App Privacy

Use `AppStore/privacy-answers-ja.md`.

Current answer:

Data Not Collected

## 5. Metadata

Use `AppStore/metadata-ja.md`.

Privacy Policy URL:

https://github.com/snarfnet/UnkoMeter/blob/main/docs/privacy-policy.md

Support URL:

https://github.com/snarfnet/UnkoMeter

## 6. Upload

After secrets are set, run the GitHub Actions workflow:

`Upload to App Store Connect`

When Apple finishes processing the build, choose it in App Store Connect and submit for review.

