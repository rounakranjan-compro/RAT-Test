const fs = require('fs');
const path = require('path');
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

async function uploadArtifacts() {
  const artifactsDir = path.join(__dirname, 'artifacts');
  const railsApiUrl = process.env.RAILS_API_URL;
  const testRunId = process.env.TEST_RUN_ID;
  const testId = process.env.TEST_ID;

  console.log('=== UPLOAD ARTIFACTS ===');
  console.log('railsApiUrl:', railsApiUrl);
  console.log('testRunId:', testRunId);
  console.log('testId:', testId);

  if (!testRunId || !testId || !railsApiUrl) {
    console.log('Missing required env vars - skipping Rails notification');
    return;
  }

  const url = `${railsApiUrl}/api/tests/${testId}/test_runs/${testRunId}/artifacts`;
  console.log('Sending to URL:', url);

  if (!fs.existsSync(artifactsDir)) {
    console.log('No artifacts directory found - sending basic result');
    await notifyRails(url, [], [], true);
    return;
  }

  console.log('=== ARTIFACTS DIR CONTENTS ===');
  console.log('artifactsDir:', artifactsDir);
  fs.readdirSync(artifactsDir).forEach(f => console.log(' -', f));

  const runs = fs.readdirSync(artifactsDir).filter(d => d.startsWith('run-'));
  console.log('runs found:', runs);

  if (!runs.length) {
    console.log('No run folders found - sending basic result');
    await notifyRails(url, [], [], true);
    return;
  }

  const latestRun = runs[runs.length - 1];
  const runDir = path.join(artifactsDir, latestRun);
  console.log('runDir:', runDir);
  console.log('runDir contents:');
  if (fs.existsSync(runDir)) {
    fs.readdirSync(runDir).forEach(f => console.log(' -', f));
  }

  // Search for result.json in runDir or subfolders
  let resultJsonPath = path.join(runDir, 'result.json');

  if (!fs.existsSync(resultJsonPath)) {
    console.log('result.json not in root, searching subfolders...');
    const subFolders = fs.readdirSync(runDir);
    for (const subFolder of subFolders) {
      const subFolderPath = path.join(runDir, subFolder);
      console.log('Subfolder contents of', subFolder, ':');
      if (fs.statSync(subFolderPath).isDirectory()) {
        fs.readdirSync(subFolderPath).forEach(f => console.log('   -', f));
      }
      const subPath = path.join(runDir, subFolder, 'result.json');
      console.log('Checking:', subPath);
      if (fs.existsSync(subPath)) {
        resultJsonPath = subPath;
        console.log('Found result.json at:', resultJsonPath);
        break;
      }
    }
  }

  if (!fs.existsSync(resultJsonPath)) {
    console.log('No result.json found anywhere - sending basic result');
    await notifyRails(url, [], [], true);
    return;
  }

  const resultData = JSON.parse(fs.readFileSync(resultJsonPath, 'utf8'));
  
  const stats = resultData?.stats;
  const success = (stats?.unexpected === 0) && (stats?.expected > 0);

  console.log('=== RESULT DATA ===');
  console.log('stats:', JSON.stringify(stats));
  console.log('success:', success);

  const results = resultData?.suites?.[0]?.specs?.[0]?.tests?.[0]?.results || [];
  const failedResult = results.find(r => r.errors?.length);

  const uploadedArtifacts = [];

  if (failedResult) {
    for (const att of (failedResult.attachments || [])) {
      if (att.name === 'error-context' || !att.path) continue;
      if (!fs.existsSync(att.path)) continue;

      try {
        const result = await cloudinary.uploader.upload(att.path, {
          resource_type: 'auto',
          folder: process.env.ENVIRONMENT || 'QA'
        });
        uploadedArtifacts.push({
          kind: att.name,
          file_url: result.secure_url
        });
        console.log(`Uploaded ${att.name}: ${result.secure_url}`);
      } catch (err) {
        console.error(`Failed to upload ${att.name}:`, err.message);
      }
    }
  }

  await notifyRails(url, uploadedArtifacts, failedResult?.errors || [], success);
}

async function notifyRails(url, artifacts, errors, success) {
  try {
    const body = JSON.stringify({ artifacts, errors, success });
    console.log('Request body:', body);

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body
    });

    const responseText = await response.text();
    console.log('Rails API response status:', response.status);
    console.log('Rails API response body:', responseText);
  } catch (err) {
    console.error('Failed to notify Rails API:', err.message);
  }
}

uploadArtifacts().catch(console.error);
