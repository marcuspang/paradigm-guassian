const fs = require("fs");
const gaussian = require("gaussian");

function toFixedPoint(value, decimals = 18) {
  return BigInt(Math.round(value * 10 ** decimals));
}

function generateTestCases(numCases = 100) {
  const testCases = [];

  for (let i = 0; i < numCases; i++) {
    const mu = (Math.random() * 2 - 1) * 1e20; // -1e20 to 1e20
    const sigma = Math.random() * 1e19; // 0 to 1e19
    const distribution = gaussian(mu, sigma * sigma);

    // Generate x within [-1e23, 1e23]
    const x = (Math.random() * 2 - 1) * 1e23;

    const expected_cdf = distribution.cdf(x);

    // Convert to fixed-point representation
    const x_fixed = toFixedPoint(x);
    const mu_fixed = toFixedPoint(mu);
    const sigma_fixed = toFixedPoint(sigma);
    const expected_cdf_fixed = toFixedPoint(expected_cdf);

    testCases.push(
      `${x_fixed},${mu_fixed},${sigma_fixed},${expected_cdf_fixed}`
    );
  }

  return testCases;
}

function writeTestCasesToFile(filename, testCases) {
  const content = testCases.join("\n");
  fs.writeFileSync(filename, content, "utf8");
  console.log(`Test cases written to ${filename}`);
}

const testCases = generateTestCases(5000);
writeTestCasesToFile("large_test_cases.txt", testCases);
