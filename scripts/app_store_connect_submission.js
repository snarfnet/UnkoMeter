const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');

const KEY_ID = process.env.ASC_KEY_ID || 'WDXGY9WX55';
const ISSUER_ID = process.env.ASC_ISSUER_ID || '2be0734f-943a-4d61-9dc9-5d9045c46fec';
const API_KEY_PATH = process.env.ASC_KEY_PATH || `${process.env.USERPROFILE}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`;
const APP_ID = process.env.ASC_APP_ID || '6770552894';
const VERSION_STRING = process.env.APP_VERSION || '1.0';
const LOCALE = process.env.APP_LOCALE || 'ja';
const ROOT = path.resolve(__dirname, '..');

const metadata = {
  promotionalText: 'トイレ時間、便の状態、食事メモを残して、自分の腸のリズムを見つけよう。',
  description: [
    'UnkoMeterは、毎日のトイレ時間と便の状態をさっと残せる腸活ログアプリです。',
    '',
    '開始ボタンを押して、終わったら状態を選んで保存。快便、硬め、ゆるめ、色の違和感を記録できます。食べたものや体調をメモしておくと、あとで自分のパターンを見つけやすくなります。',
    '',
    '主な機能:',
    '',
    '- トイレ時間のタイマー記録',
    '- 便の状態を5タイプから選択',
    '- 食事や体調のメモ',
    '- 今月の快便率、平均時間、状態別の傾向',
    '- 最近の記録一覧',
    '- 気になる記録に出やすい食べ物メモの表示',
    '',
    '名前は少しゆるめ。でも中身は、毎日続けやすい体調メモです。',
    '',
    '注意:',
    'このアプリは医療診断を行うものではありません。長く続く不調、強い痛み、血便などがある場合は、医療機関に相談してください。',
  ].join('\n'),
  keywords: '腸活,便記録,トイレ,健康管理,体調メモ,便秘,下痢,食事記録,快便,ヘルスケア',
  supportUrl: 'https://github.com/snarfnet/UnkoMeter',
  marketingUrl: 'https://github.com/snarfnet/UnkoMeter',
};

const appInfoMetadata = {
  subtitle: 'トイレ時間と便の状態を軽く記録',
  privacyPolicyUrl: 'https://github.com/snarfnet/UnkoMeter/blob/main/docs/privacy-policy.md',
};

function makeJWT() {
  const key = fs.readFileSync(API_KEY_PATH, 'utf8');
  const now = Math.floor(Date.now() / 1000) - 60;
  const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({ iss: ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })).toString('base64url');
  const sign = crypto.createSign('SHA256');
  sign.update(`${header}.${payload}`);
  sign.end();
  return `${header}.${payload}.${sign.sign({ key, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
}

function api(method, requestPath, body = undefined, extraHeaders = {}) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = https.request({
      hostname: 'api.appstoreconnect.apple.com',
      path: requestPath,
      method,
      headers: {
        Authorization: `Bearer ${makeJWT()}`,
        'Content-Type': 'application/json',
        ...extraHeaders,
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    }, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        let parsed = raw;
        try {
          parsed = raw ? JSON.parse(raw) : {};
        } catch {}
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(parsed);
        } else {
          reject(new Error(`HTTP ${res.statusCode} ${method} ${requestPath}\n${JSON.stringify(parsed, null, 2)}`));
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function upload(url, method, headers, body) {
  return new Promise((resolve, reject) => {
    const target = new URL(url);
    const req = https.request({
      hostname: target.hostname,
      path: `${target.pathname}${target.search}`,
      method,
      headers: {
        ...headers,
        'Content-Length': body.length,
      },
    }, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(raw);
        } else {
          reject(new Error(`Upload failed ${res.statusCode} ${method} ${url}\n${raw}`));
        }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function getAppStoreVersion() {
  const response = await api('GET', `/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&limit=10`);
  const existing = response.data.find((version) => version.attributes.versionString === VERSION_STRING)
    || response.data.find((version) => version.attributes.appStoreState === 'PREPARE_FOR_SUBMISSION');
  if (existing) return existing;

  return (await api('POST', '/v1/appStoreVersions', {
    data: {
      type: 'appStoreVersions',
      attributes: {
        platform: 'IOS',
        versionString: VERSION_STRING,
        releaseType: 'AFTER_APPROVAL',
      },
      relationships: {
        app: { data: { type: 'apps', id: APP_ID } },
      },
    },
  })).data;
}

async function getLocalization(versionId) {
  const response = await api('GET', `/v1/appStoreVersions/${versionId}/appStoreVersionLocalizations?limit=10`);
  let localization = response.data.find((item) => item.attributes.locale === LOCALE)
    || response.data.find((item) => item.attributes.locale.startsWith('ja'))
    || response.data[0];
  if (localization) return localization;

  return (await api('POST', '/v1/appStoreVersionLocalizations', {
    data: {
      type: 'appStoreVersionLocalizations',
      attributes: { locale: LOCALE },
      relationships: {
        appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } },
      },
    },
  })).data;
}

async function updateLocalization(localizationId) {
  await api('PATCH', `/v1/appStoreVersionLocalizations/${localizationId}`, {
    data: {
      type: 'appStoreVersionLocalizations',
      id: localizationId,
      attributes: metadata,
    },
  });
}

async function updateAppInfoLocalization() {
  const infos = await api('GET', `/v1/apps/${APP_ID}/appInfos?limit=10`);
  const info = infos.data[0];
  if (!info) {
    console.log('No app info found.');
    return;
  }

  const localizations = await api('GET', `/v1/appInfos/${info.id}/appInfoLocalizations?limit=10`);
  const localization = localizations.data.find((item) => item.attributes.locale === LOCALE)
    || localizations.data.find((item) => item.attributes.locale.startsWith('ja'))
    || localizations.data[0];
  if (!localization) {
    console.log('No app info localization found.');
    return;
  }

  await api('PATCH', `/v1/appInfoLocalizations/${localization.id}`, {
    data: {
      type: 'appInfoLocalizations',
      id: localization.id,
      attributes: {
        ...appInfoMetadata,
        name: localization.attributes.name || 'うんこ記録！',
      },
    },
  });
  console.log('Updated app info metadata.');
}

async function getOrCreateScreenshotSet(localizationId, screenshotDisplayType) {
  const query = `/v1/appStoreVersionLocalizations/${localizationId}/appScreenshotSets?filter[screenshotDisplayType]=${screenshotDisplayType}&include=appScreenshots&limit=10`;
  const response = await api('GET', query);
  if (response.data.length > 0) return response.data[0];

  return (await api('POST', '/v1/appScreenshotSets', {
    data: {
      type: 'appScreenshotSets',
      attributes: { screenshotDisplayType },
      relationships: {
        appStoreVersionLocalization: {
          data: { type: 'appStoreVersionLocalizations', id: localizationId },
        },
      },
    },
  })).data;
}

async function deleteScreenshots(setId) {
  const response = await api('GET', `/v1/appScreenshotSets/${setId}/appScreenshots?limit=10`);
  for (const screenshot of response.data) {
    await api('DELETE', `/v1/appScreenshots/${screenshot.id}`);
  }
}

async function createScreenshot(setId, filePath) {
  const buffer = fs.readFileSync(filePath);
  const fileName = path.basename(filePath);
  const created = (await api('POST', '/v1/appScreenshots', {
    data: {
      type: 'appScreenshots',
      attributes: {
        fileSize: buffer.length,
        fileName,
      },
      relationships: {
        appScreenshotSet: { data: { type: 'appScreenshotSets', id: setId } },
      },
    },
  })).data;

  for (const operation of created.attributes.uploadOperations) {
    const offset = Number(operation.offset || 0);
    const length = Number(operation.length || buffer.length);
    const part = buffer.subarray(offset, offset + length);
    const headers = Object.fromEntries((operation.requestHeaders || []).map((header) => [header.name, header.value]));
    await upload(operation.url, operation.method, headers, part);
  }

  await api('PATCH', `/v1/appScreenshots/${created.id}`, {
    data: {
      type: 'appScreenshots',
      id: created.id,
      attributes: { uploaded: true },
    },
  });
}

async function uploadScreenshots(localizationId) {
  const groups = [
    {
      type: 'APP_IPHONE_67',
      files: ['iphone-67-01-record.png', 'iphone-67-02-stats.png', 'iphone-67-03-notes.png'],
    },
    {
      type: 'APP_IPAD_PRO_3GEN_129',
      files: ['ipad-129-01-record.png', 'ipad-129-02-stats.png', 'ipad-129-03-notes.png'],
    },
  ];

  for (const group of groups) {
    const set = await getOrCreateScreenshotSet(localizationId, group.type);
    await deleteScreenshots(set.id);
    for (const fileName of group.files) {
      await createScreenshot(set.id, path.join(ROOT, 'AppStoreAssets', 'screenshots', fileName));
    }
    console.log(`Uploaded screenshots: ${group.type}`);
  }
}

async function latestProcessedBuild() {
  const response = await api('GET', `/v1/builds?filter[app]=${APP_ID}&sort=-uploadedDate&limit=10`);
  return response.data.find((build) => build.attributes.processingState === 'VALID') || response.data[0];
}

async function attachBuild(versionId) {
  const build = await latestProcessedBuild();
  if (!build) {
    console.log('No uploaded build found yet.');
    return null;
  }
  if (build.attributes.processingState !== 'VALID') {
    console.log(`Build exists but is not ready yet: ${build.attributes.version} (${build.attributes.processingState})`);
    return build;
  }

  await api('PATCH', `/v1/appStoreVersions/${versionId}/relationships/build`, {
    data: { type: 'builds', id: build.id },
  }, { 'Content-Type': 'application/vnd.api+json' });
  console.log(`Attached build: ${build.attributes.version} (${build.attributes.buildNumber})`);
  return build;
}

async function updateReviewDetails(versionId) {
  const response = await api('GET', `/v1/appStoreVersions/${versionId}/appStoreReviewDetail`);
  const detail = response.data;
  if (!detail) return;

  await api('PATCH', `/v1/appStoreReviewDetails/${detail.id}`, {
    data: {
      type: 'appStoreReviewDetails',
      id: detail.id,
      attributes: {
        contactFirstName: 'UnkoMeter',
        contactLastName: 'Support',
        contactPhone: '+810000000000',
        contactEmail: 'support@example.com',
        demoAccountRequired: false,
        notes: 'The app stores toilet duration, stool condition, and optional notes locally on device using UserDefaults. It uses Google Mobile Ads SDK to show banner ads. It does not require login. The app is not a medical diagnostic tool.',
      },
    },
  });
}

async function status() {
  const app = await api('GET', `/v1/apps/${APP_ID}`);
  const versions = await api('GET', `/v1/apps/${APP_ID}/appStoreVersions?filter[platform]=IOS&limit=10`);
  console.log(JSON.stringify({
    app: {
      id: app.data.id,
      name: app.data.attributes.name,
      bundleId: app.data.attributes.bundleId,
      sku: app.data.attributes.sku,
      primaryLocale: app.data.attributes.primaryLocale,
    },
    versions: versions.data.map((version) => ({
      id: version.id,
      versionString: version.attributes.versionString,
      state: version.attributes.appStoreState,
      createdDate: version.attributes.createdDate,
    })),
  }, null, 2));
}

async function builds() {
  const response = await api('GET', `/v1/builds?filter[app]=${APP_ID}&sort=-uploadedDate&limit=10`);
  console.log(JSON.stringify(response.data.map((build) => ({
    id: build.id,
    version: build.attributes.version,
    buildNumber: build.attributes.buildNumber,
    processingState: build.attributes.processingState,
    uploadedDate: build.attributes.uploadedDate,
    expired: build.attributes.expired,
  })), null, 2));
}

async function sync() {
  const version = await getAppStoreVersion();
  console.log(`Version: ${version.attributes.versionString} (${version.attributes.appStoreState})`);
  await updateAppInfoLocalization();
  const localization = await getLocalization(version.id);
  console.log(`Localization: ${localization.attributes.locale}`);
  await updateLocalization(localization.id);
  console.log('Updated metadata.');
  await uploadScreenshots(localization.id);
  await updateReviewDetails(version.id);
  console.log('Updated review details.');
  await attachBuild(version.id);
}

const command = process.argv[2] || 'status';
const actions = { sync, status, builds };

(actions[command] || status)().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
