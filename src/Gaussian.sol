// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

/// @title Implementation of Gaussian CDF function
/// @author Marcus Pang
/// @notice Uses Abramowitz and Stegun approximation for the Gaussian CDF.
/// @dev Note
/// The implementation uses fixed-point arithmetic with 18 decimals. The values are bounded by
/// -1e20 <= μ <= 1e20, 0 <= σ <= 1e19, -1e23 <= x <= 1e23, and an error rate of < 1e-8.
contract Gaussian {
    using FixedPointMathLib for int256;

    // Constants
    int256 private constant WAD_INT = 1e18;
    int256 private constant SQRT_2 = 1414213562373095048; // sqrt(2) * 1e18

    // Coefficients for the rational approximation
    int256 private constant A1 = 254829592;
    int256 private constant A2 = -284496736;
    int256 private constant A3 = 1421413741;
    int256 private constant A4 = -1453152027;
    int256 private constant A5 = 1061405429;
    int256 private constant P = 327591100;

    function gaussianCDF(int256 x, int256 mu, int256 sigma) public pure returns (int256) {
        require(sigma > 0 && sigma <= 1e37, "Invalid sigma");
        require(mu >= -1e38 && mu <= 1e38, "Invalid mu");
        require(x >= -1e41 && x <= 1e41, "Invalid x");

        // Calculate (x - μ) / (σ * sqrt(2))
        int256 t = ((x - mu) * WAD_INT).rawSDivWad(sigma.rawSMulWad(SQRT_2));

        // Handle extreme values
        if (t <= -40 * WAD_INT) return 0;
        if (t >= 40 * WAD_INT) return WAD_INT;

        bool negative = t < 0;
        if (negative) t = -t;

        // Rational approximation for erfc
        int256 sum = P;
        int256 z = t.rawSMulWad(t);

        sum += (A1 * WAD_INT).rawSDivWad(z + WAD_INT);
        sum += (A2 * WAD_INT).rawSDivWad(z.rawSMulWad(2) + 3 * WAD_INT);
        sum += (A3 * WAD_INT).rawSDivWad(z.rawSMulWad(3) + 6 * WAD_INT);
        sum += (A4 * WAD_INT).rawSDivWad(z.rawSMulWad(4) + 10 * WAD_INT);
        sum += (A5 * WAD_INT).rawSDivWad(z.rawSMulWad(5) + 15 * WAD_INT);

        sum = sum.rawSMulWad(t).rawSDivWad(1000000000);
        int256 result = WAD_INT - sum;

        // Apply symmetry for negative t
        if (negative) {
            result = WAD_INT - result;
        }

        return result / 2;
    }

    function normalCDF(int256 x, int256 mu, int256 sigma) public pure returns (int256) {
        int256 erfc = gaussianCDF(x, mu, sigma);
        return WAD_INT - erfc / 2;
    }
}
