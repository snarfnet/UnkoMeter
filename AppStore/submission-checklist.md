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

- `DIST_CERT_BASE64`
- `DIST_CERT_PASSWORD`
- `PROVISION_PROFILE_BASE64`
- `PROVISION_PROFILE_NAME`
- `APP_STORE_CONNECT_API_KEY_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_KEY_ISSUER_ID`

Encoding commands on macOS:

```sh
base64 -i distribution_certificate.p12 | pbcopy
base64 -i UnkoMeter_App_Store.mobileprovision | pbcopy
```

The current project includes `scripts/create_app_store_signing.js` to generate the certificate and provisioning profile through the App Store Connect API.

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
