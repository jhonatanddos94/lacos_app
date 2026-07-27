'use strict';

const path = require('path');

const suites = [
  './functions/ping.test.js',
  './functions/health.test.js',
  './functions/exchangeSession.test.js',
  './services/firebaseAuthService.test.js',
  './services/parseUserService.test.js',
  './services/sessionService.test.js',
  './config/firebaseConfig.test.js',
  './scripts/assertStagingEnv.test.js',
];

async function main() {
  let failed = 0;

  for (const relativePath of suites) {
    const absolutePath = path.join(__dirname, relativePath);
    const suiteName = path.basename(relativePath);
    process.stdout.write(`RUN  ${suiteName} ... `);

    try {
      // Clear require cache so env mutations do not leak across suites oddly
      delete require.cache[require.resolve(absolutePath)];
      const suite = require(absolutePath);
      await suite.run();
      process.stdout.write('OK\n');
    } catch (error) {
      failed += 1;
      process.stdout.write('FAIL\n');
      console.error(error);
    }
  }

  if (failed > 0) {
    console.error(`\n${failed} test suite(s) failed`);
    process.exit(1);
  }

  console.log(`\n${suites.length} test suite(s) passed`);
}

main();
