const fs = require('fs');
const path = require('path');
const https = require('https');
const crypto = require('crypto');
const forge = require('node-forge');

const KEY_ID = process.env.ASC_KEY_ID || 'WDXGY9WX55';
const ISSUER_ID = process.env.ASC_ISSUER_ID || '2be0734f-943a-4d61-9dc9-5d9045c46fec';
const API_KEY_PATH = process.env.ASC_KEY_PATH || `${process.env.USERPROFILE}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`;
const BUNDLE_IDENTIFIER = process.env.BUNDLE_IDENTIFIER || 'com.tokyonasu.UnkoMeter';
const BUNDLE_NAME = process.env.BUNDLE_NAME || 'UnkoMeter';
const OUTPUT_DIR = process.env.SIGNING_OUTPUT_DIR || `${process.env.USERPROFILE}/UnkoMeter_SIGNING`;

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

function api(method, requestPath, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const req = https.request({
      hostname: 'api.appstoreconnect.apple.com',
      path: requestPath,
      method,
      headers: {
        Authorization: `Bearer ${makeJWT()}`,
        'Content-Type': 'application/json',
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

function makeCSR() {
  const keys = forge.pki.rsa.generateKeyPair(2048);
  const csr = forge.pki.createCertificationRequest();
  csr.publicKey = keys.publicKey;
  csr.setSubject([{ name: 'commonName', value: `${BUNDLE_NAME} GitHub Actions Distribution` }]);
  csr.sign(keys.privateKey, forge.md.sha256.create());
  return {
    privateKey: keys.privateKey,
    privateKeyPem: forge.pki.privateKeyToPem(keys.privateKey),
    csrPem: forge.pki.certificationRequestToPem(csr),
  };
}

async function getOrCreateBundleId() {
  const query = encodeURIComponent(BUNDLE_IDENTIFIER);
  const existing = await api('GET', `/v1/bundleIds?filter[identifier]=${query}&limit=1`);
  if (existing.data && existing.data.length > 0) {
    return existing.data[0];
  }

  return (await api('POST', '/v1/bundleIds', {
    data: {
      type: 'bundleIds',
      attributes: {
        name: BUNDLE_NAME,
        identifier: BUNDLE_IDENTIFIER,
        platform: 'IOS',
      },
    },
  })).data;
}

async function createCertificate(csrPem) {
  const body = (certificateType) => ({
    data: {
      type: 'certificates',
      attributes: {
        certificateType,
        csrContent: csrPem,
      },
    },
  });

  try {
    return (await api('POST', '/v1/certificates', body('DISTRIBUTION'))).data;
  } catch (error) {
    if (!String(error.message).includes('CERTIFICATE_TYPE')) {
      throw error;
    }
    return (await api('POST', '/v1/certificates', body('IOS_DISTRIBUTION'))).data;
  }
}

async function createProfile(bundleId, certificateId) {
  const stamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  return (await api('POST', '/v1/profiles', {
    data: {
      type: 'profiles',
      attributes: {
        name: `${BUNDLE_NAME} App Store ${stamp}`,
        profileType: 'IOS_APP_STORE',
      },
      relationships: {
        bundleId: { data: { type: 'bundleIds', id: bundleId } },
        certificates: { data: [{ type: 'certificates', id: certificateId }] },
      },
    },
  })).data;
}

function writeCertificateFiles(privateKey, privateKeyPem, certData) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const password = crypto.randomBytes(24).toString('base64url');
  const certDer = Buffer.from(certData.attributes.certificateContent, 'base64');
  const certAsn1 = forge.asn1.fromDer(certDer.toString('binary'));
  const cert = forge.pki.certificateFromAsn1(certAsn1);
  const p12Asn1 = forge.pkcs12.toPkcs12Asn1(privateKey, [cert], password, {
    algorithm: '3des',
    friendlyName: `${BUNDLE_NAME} Apple Distribution`,
  });
  const p12Der = forge.asn1.toDer(p12Asn1).getBytes();

  const files = {
    privateKey: path.join(OUTPUT_DIR, 'distribution_private_key.pem'),
    certificate: path.join(OUTPUT_DIR, 'distribution.cer'),
    p12: path.join(OUTPUT_DIR, 'distribution.p12'),
    p12Password: path.join(OUTPUT_DIR, 'distribution_p12_password.txt'),
  };

  fs.writeFileSync(files.privateKey, privateKeyPem);
  fs.writeFileSync(files.certificate, certDer);
  fs.writeFileSync(files.p12, Buffer.from(p12Der, 'binary'));
  fs.writeFileSync(files.p12Password, password);

  return files;
}

function writeProfileFiles(profileData) {
  const files = {
    profile: path.join(OUTPUT_DIR, 'AppStore.mobileprovision'),
    profileName: path.join(OUTPUT_DIR, 'profile_name.txt'),
  };

  fs.writeFileSync(files.profile, Buffer.from(profileData.attributes.profileContent, 'base64'));
  fs.writeFileSync(files.profileName, profileData.attributes.name);
  return files;
}

async function main() {
  const bundle = await getOrCreateBundleId();
  console.log(`Bundle ID ready: ${bundle.attributes.identifier}`);

  const { privateKey, privateKeyPem, csrPem } = makeCSR();
  const cert = await createCertificate(csrPem);
  writeCertificateFiles(privateKey, privateKeyPem, cert);
  console.log('Distribution certificate files created.');

  const profile = await createProfile(bundle.id, cert.id);
  writeProfileFiles(profile);
  console.log(`Provisioning profile created: ${profile.attributes.name}`);
  console.log(`Output: ${OUTPUT_DIR}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
