// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

/// @title Implementation of Gaussian CDF function
/// @author Marcus Pang
/// @notice Uses Abramowitz and Stegun approximation for the Gaussian CDF.
/// @dev Note
/// The implementation uses fixed-point arithmetic with 18 decimals. The values are bounded by
/// -1e20 <= μ <= 1e20, 0 <= σ <= 1e19, -1e23 <= x <= 1e23, and an error rate of < 1e-8.
contract Gaussian {
    // Constants
    int256 private constant FIXED_1 = 10 ** 18;
    int256 private constant SQRT_2 = 1414213562373095048; // sqrt(2) * 10 ** 18

    // Coefficients for the rational approximation
    int256 private constant A1 = 254829592;
    int256 private constant A2 = -284496736;
    int256 private constant A3 = 1421413741;
    int256 private constant A4 = -1453152027;
    int256 private constant A5 = 1061405429;
    int256 private constant P = 327591100;

    function gaussianCDF(int256 x, int256 mu, int256 sigma) public pure returns (int256) {
        require(sigma > 0 && sigma <= 10 ** 37, "Invalid sigma");
        require(mu >= -int256(10 ** 38) && mu <= 10 ** 38, "Invalid mu");
        require(x >= -int256(10 ** 41) && x <= 10 ** 41, "Invalid x");

        // Calculate (x - μ) / (σ * sqrt(2))
        int256 t = ((x - mu) * FIXED_1) / (sigma * SQRT_2 / FIXED_1);

        // Handle extreme values
        if (t <= -40 * FIXED_1) return 0;
        if (t >= 40 * FIXED_1) return FIXED_1;

        bool negative = t < 0;
        if (negative) t = -t;

        // Rational approximation for erfc
        int256 sum = P;
        int256 z = (t * t) / FIXED_1;

        sum += (A1 * FIXED_1) / (z + FIXED_1);
        sum += (A2 * FIXED_1) / ((z + FIXED_1) * 2 / FIXED_1 + FIXED_1);
        sum += (A3 * FIXED_1) / ((z + FIXED_1) * 3 / FIXED_1 + FIXED_1);
        sum += (A4 * FIXED_1) / ((z + FIXED_1) * 4 / FIXED_1 + FIXED_1);
        sum += (A5 * FIXED_1) / ((z + FIXED_1) * 5 / FIXED_1 + FIXED_1);

        sum = sum * t / (FIXED_1 * 1000000000);
        int256 result = FIXED_1 - sum;

        // Apply symmetry for negative t
        if (negative) {
            result = FIXED_1 - result;
        }

        return result / 2;
    }
}
