# App Privacy Answers

App Store Connectの「App Privacy」で使う回答メモです。

## Data Collection

このアプリ本体は、トイレ時間、便の状態、メモを端末内だけに保存します。

ただし、広告表示のためにGoogle Mobile Ads SDKを使います。App Store Connectのプライバシー回答では、Google Mobile Ads SDKが扱う可能性のあるデータを申告してください。

アプリ本体:

- 記録は端末内のUserDefaultsに保存
- ログインなし
- 独自サーバー送信なし
- HealthKitなし

広告SDK:

- Google Mobile Ads SDKを使用
- バナー広告を表示
- 広告配信、広告効果測定、不正利用防止のためにデータを扱う可能性あり

## Tracking

Google Mobile Ads SDKを使うため、App Store Connectでは広告SDKの扱いに合わせて回答してください。IDFAを使う設定にする場合は、トラッキングありになります。

## Data Linked to the User

広告SDKのデータが該当する可能性があります。

## Health & Fitness Data

ユーザーは便の状態や体調メモを入力できますが、このデータはアプリ外に送信しません。Appleのプライバシー定義では、端末内だけで処理されるデータは「収集」に該当しません。

## Privacy Nutrition Label

広告SDKあり。Google Mobile Ads SDKのデータ利用に合わせて回答。
