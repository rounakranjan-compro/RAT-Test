const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

function runTests(testFile) {
  const runId = new Date().toISOString().replace(/[:.]/g, '-');
  const startTime = Date.now();
  

  const retries = process.env.PW_RETRIES || '2';
  const headed = process.env.PW_HEADED === 'true';
  const testRunId = process.env.TEST_RUN_ID || runId;
  const environment = process.env.ENVIRONMENT || 'QA';
  

  const os = require('os');
  const platform = os.platform();


  const hasDisplay = platform === 'darwin' || !!process.env.DISPLAY;
  const isRender = !!process.env.RENDER;
  const canRunHeaded = headed && hasDisplay && !isRender;
  

  let command = `npx playwright test ${testFile}`;
  if (canRunHeaded) {
    command += ' --headed';
  }
  
  console.log('\n' + '='.repeat(60));
  console.log('Test Execution Configuration:');
  console.log(`  Test File: ${testFile}`);
  console.log(`  Environment: ${environment}`);
  console.log(`  Runner Mode: ${canRunHeaded ? 'headed' : 'headless'}`);
  if (headed && !canRunHeaded) {
    console.log(`  ⚠️  Headed mode requested but not available - running headless`);
  }
  console.log(`  Retries: ${retries}`);
  console.log(`  Test Run ID: ${testRunId}`);
  console.log(`  Command: ${command}`);
  console.log('='.repeat(60) + '\n');

  return new Promise((resolve) => {
    const childProcess = exec(command, {
      cwd: __dirname,
      maxBuffer: 10 * 1024 * 1024,
      env: {
        ...process.env,
        PW_RETRIES: retries,
        TEST_RUN_ID: testRunId,
        ENVIRONMENT: environment
      }
    });

    childProcess.stdout.on('data', (data) => {
      process.stdout.write(data);
    });

    childProcess.stderr.on('data', (data) => {
      process.stderr.write(data);
    });

   childProcess.on('close', (exitCode) => {
      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      
      const artifactsDir = path.join(__dirname, 'artifacts');
      const attempt = process.env.RUN_ATTEMPT || 'default' // ↓ ADDED

      // ↓ CHANGED: use testRunId + attempt directly instead of scanning for latest
      const outputDir = path.join(artifactsDir, `run-${testRunId}`, `attempt-${attempt}`)

      const result = {
        runId: testRunId,
        success: exitCode === 0,
        exitCode: exitCode,
        testFile: testFile,
        duration: parseFloat(duration),
        outputDir: outputDir,
        timestamp: new Date().toISOString(),
        environment: environment,
        runnerMode: canRunHeaded ? 'headed' : 'headless',
        retries: parseInt(retries)
      };

      if (outputDir) {
        const jsonReport = path.join(outputDir, 'result.json');
        if (fs.existsSync(jsonReport)) {
          try {
            const report = JSON.parse(fs.readFileSync(jsonReport, 'utf8'));
            result.stats = getStats(report);
            result.tests = getTestDetails(report);
            result.reports = {
              json: jsonReport,
              html: path.join(outputDir, 'index.html')
            };
          } catch (err) {
            console.error('Error reading report:', err.message);
          }
        }
      }

      console.log('\n' + '='.repeat(60));
      console.log('Test Execution Summary:');
      console.log(`  Duration: ${duration}s`);
      console.log(`  Exit Code: ${exitCode}`);
      console.log(`  Status: ${exitCode === 0 ? 'PASSED ✓' : 'FAILED ✗'}`);
      console.log(`  Environment: ${environment}`);
      console.log(`  Runner Mode: ${canRunHeaded ? 'headed' : 'headless'}`);
      console.log(`  Retries Used: ${retries}`);
      if (result.stats) {
        console.log(`  Tests: ${result.stats.passed} passed, ${result.stats.failed} failed, ${result.stats.total} total`);
      }
      console.log('='.repeat(60));
      
      console.log('\n---RESULT---');
      console.log(JSON.stringify(result));
      console.log('---END---');

      resolve(result);
    });

    childProcess.on('error', (error) => {
      console.error('Error:', error.message);
      const result = {
        runId: testRunId,
        success: false,
        exitCode: 1,
        testFile: testFile,
        error: error.message,
        timestamp: new Date().toISOString(),
        environment: environment,
        runnerMode: canRunHeaded ? 'headed' : 'headless',
        retries: parseInt(retries)
      };
      
      console.log('\n---RESULT---');
      console.log(JSON.stringify(result));
      console.log('---END---');
      
      resolve(result);
    });
  });
}

function getStats(report) {
  const stats = { total: 0, passed: 0, failed: 0, skipped: 0 };
  
  const countTests = (suites) => {
    suites.forEach(suite => {
      if (suite.specs) {
        suite.specs.forEach(spec => {
          stats.total++;
          if (spec.ok) {
            stats.passed++;
          } else if (spec.tests && spec.tests.every(t => t.results.every(r => r.status === 'skipped'))) {
            stats.skipped++;
          } else {
            stats.failed++;
          }
        });
      }
      if (suite.suites) {
        countTests(suite.suites);
      }
    });
  };
  
  if (report.suites) {
    countTests(report.suites);
  }
  
  return stats;
}

function getTestDetails(report) {
  const tests = [];
  
  const processSpecs = (suites) => {
    suites.forEach(suite => {
      if (suite.specs) {
        suite.specs.forEach(spec => {
          tests.push({
            title: spec.title,
            file: suite.file || '',
            status: spec.ok ? 'passed' : 'failed',
            duration: spec.tests ? spec.tests[0].results[0].duration : 0
          });
        });
      }
      if (suite.suites) {
        processSpecs(suite.suites);
      }
    });
  };
  
  if (report.suites) {
    processSpecs(report.suites);
  }
  
  return tests;
}

if (require.main === module) {
  let testFile = process.argv[2];
  
  if (!testFile) {
    console.error('Error: Please provide a test file');
    console.error('Usage: node run.js <test-file>');
    console.error('Example: node run.js login.spec.js');
    console.error('\nEnvironment Variables:');
    console.error('  PW_RETRIES - Number of retries (default: 2)');
    console.error('  PW_HEADED - Run in headed mode (default: false)');
    console.error('  TEST_RUN_ID - Test run identifier');
    console.error('  ENVIRONMENT - Test environment (QA, DEV, etc.)');
    process.exit(1);
  }

  if (!testFile.startsWith('tests/') && !testFile.startsWith('tests\\')) {
    testFile = 'tests/' + testFile;
  }

  const testFilePath = path.join(__dirname, testFile);
  if (!fs.existsSync(testFilePath)) {
    console.error(`Error: Test file not found: ${testFile}`);
    console.error(`Looking for: ${testFilePath}`);
    process.exit(1);
  }

  testFile = testFile.replace(/\\/g, '/');

  runTests(testFile)
    .then((result) => {
      process.exit(0);
    })
    .catch((error) => {
      console.error('Fatal error:', error);
      const errorResult = {
        runId: process.env.TEST_RUN_ID || new Date().toISOString().replace(/[:.]/g, '-'),
        success: false,
        exitCode: 1,
        testFile: testFile,
        error: error.message,
        timestamp: new Date().toISOString(),
        environment: process.env.ENVIRONMENT || 'QA',
        runnerMode: process.env.PW_HEADED === 'true' ? 'headed' : 'headless',
        retries: parseInt(process.env.PW_RETRIES || '2')
      };
      console.log(JSON.stringify(errorResult));
      process.exit(0);
    });
}

module.exports = { runTests };