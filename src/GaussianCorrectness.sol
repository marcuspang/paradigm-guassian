// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Implementation of Gaussian CDF function
/// @author Marcus Pang
/// @notice Uses Dia (2023) approximation for the Gaussian CDF.
/// @dev Note
/// The implementation uses fixed-point arithmetic with 18 decimals. The values are bounded by
/// -1e20 <= μ <= 1e20, 0 <= σ <= 1e19, -1e23 <= x <= 1e23, and an error rate of < 1e-8.
contract GaussianCorrectness {
    // Constants
    int256 private constant FIXED_1 = 10 ** 18;
    int256 private constant SQRT_2PI = 2506628274631000502; // sqrt(2π) * 1e18

    // Precomputed coefficients from the paper, scaled by 1e18
    int256 private constant B_0 = 2926786005158048154;
    int256[5] private B_1 = [
        int256(8972806590468173504),
        int256(10271570611713630789),
        int256(12723232619077609280),
        int256(16886395620079369078),
        int256(24123337745724791104)
    ];
    int256[5] private B_2 = [
        int256(5815825189335273905),
        int256(5703479358980514367),
        int256(5518624830257079631),
        int256(5261842395796042073),
        int256(4920813466328820329)
    ];
    int256[5] private C_1 = [
        int256(11615112262606032471),
        int256(18253232353473465248),
        int256(18388712257739384869),
        int256(18611933189717757950),
        int256(24148040728127628211)
    ];
    int256[5] private C_2 = [
        int256(3833629478001461794),
        int256(7307562585536735411),
        int256(8427423004580432404),
        int256(5664795188784707648),
        int256(4913960988952400752)
    ];

    function gaussianCDF(int256 x, int256 mu, int256 sigma) public view returns (int256 erfc) {
        require(sigma > 0 && sigma <= 10 ** 37, "Invalid sigma");
        require(mu >= -int256(10 ** 38) && mu <= 10 ** 38, "Invalid mu");
        require(x >= -int256(10 ** 41) && x <= 10 ** 41, "Invalid x");

        // Standardize x
        int256 z = ((x - mu) * FIXED_1) / sigma;

        int256 numerator = 0;
        int256 denominator = z + B_0;

        for (uint256 i = 0; i < 5; i++) {
            int256 z_squared = (z * z) / FIXED_1;
            numerator += (C_2[i] * z_squared / FIXED_1 + C_1[i]) * z / FIXED_1;

            int256 term = z_squared + B_2[i] * z / FIXED_1 + B_1[i];

            // Check for potential overflow and scale down if necessary
            while (denominator != 0 && (denominator > type(int256).max / term || denominator < type(int256).min / term))
            {
                numerator /= 2;
                denominator /= 2;
                term /= 2;
            }

            denominator = (denominator * term) / FIXED_1;
        }

        // Compute M
        int256 m = numerator / denominator;

        // Compute exp(-z^2/2)
        int256 exp_term = exp(-(z * z) / (2 * FIXED_1));

        // Compute erfc using the relation from Proposition 10
        erfc = (SQRT_2PI * m * exp_term) / (FIXED_1 * FIXED_1);
    }

    function normalCDF(int256 x, int256 mu, int256 sigma) public view returns (int256) {
        if (x < mu) {
            return FIXED_1 - normalCDF(2 * mu - x, mu, sigma);
        } else {
            int256 erfc = gaussianCDF(x, mu, sigma);
            return FIXED_1 - erfc / 2;
        }
    }

    // Helper function to compute exp(-x) for x >= 0
    function exp(int256 x) private pure returns (int256) {
        // Handle the case where x is zero
        if (x == 0) return FIXED_1;

        // Handle very large negative values
        if (x < -41 * FIXED_1) return 0;

        // Handle very large positive values
        if (x > 130 * FIXED_1) return type(int256).max;

        bool is_negative = x < 0;
        if (is_negative) x = -x;

        // Use the first few terms of the Taylor series for e^x
        int256 result = FIXED_1;
        int256 term = FIXED_1;
        for (int256 i = 1; i <= 32; i++) {
            term = (term * x) / (i * FIXED_1);

            // Check for potential overflow
            if (result > type(int256).max - term) {
                result = type(int256).max;
                break;
            }

            result += term;

            // Break if the term becomes too small to affect the result
            if (term < FIXED_1 / 1e6) break;
        }

        if (is_negative) {
            // For negative x, we compute e^(-x) and then take its reciprocal
            // We need to be careful about potential division by zero
            if (result == 0) return type(int256).max;
            return (FIXED_1 * FIXED_1) / result;
        } else {
            return result;
        }
    }
}
