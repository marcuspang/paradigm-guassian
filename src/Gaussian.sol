// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import "./Errors.sol";

/// @title Implementation of Gaussian CDF function
/// @author Marcus Pang
/// @notice Uses Abramowitz and Stegun approximation for the Gaussian CDF.
/// @dev Note
/// The implementation uses fixed-point arithmetic with 18 decimals. The values are bounded by
/// -1e20 <= μ <= 1e20, 0 <= σ <= 1e19, -1e23 <= x <= 1e23, and an error rate of <= 1e-8.
contract Gaussian {
    using FixedPointMathLib for int256;

    // Constants
    int256 private constant WAD_INT = 1e18;
    int256 private constant SQRT_2 = 1414213562373095048; // sqrt(2) * 1e18

    // Coefficients for the rational approximation
    uint256 private constant PACKED_CONSTANTS_1 = 0x15495E6ABF87CBF8F30A1400;
    uint256 private constant PACKED_CONSTANTS_2 = 0x138BDF8C3F38D0C0A93ED740;

    // Magic numbers for unpacking (start bit, bit length)
    uint8[6] private UNPACK_INFO = [0, 28, 30, 31, 30, 28];

    function unpackConstant(uint256 packed, uint8 index) private view returns (int256) {
        uint8 start = 0;
        for (uint8 i = 0; i < index; i++) {
            start += UNPACK_INFO[i];
        }
        uint8 length = UNPACK_INFO[index];
        uint256 mask = (1 << length) - 1;
        int256 value = int256((packed >> start) & mask);

        // Sign extension for negative values
        if (index == 1 || index == 3) {
            // A2 and A4 are negative
            if ((value & int256(1 << (length - 1))) != 0) {
                value |= int256(type(uint256).max << length);
            }
        }
        return value;
    }

    function gaussianCDF(int256 x, int256 mu, int256 sigma) public view returns (int256) {
        if (sigma <= 0 || sigma > 1e37) revert InvalidSigma();
        if (mu < -1e38 || mu > 1e38) revert InvalidMu();
        if (x < -1e41 || x > 1e41) revert InvalidX();

        // Calculate (x - μ) / (σ * sqrt(2))
        int256 t = ((x - mu) * WAD_INT).rawSDivWad(sigma.rawSMulWad(SQRT_2));

        // Handle extreme values
        if (t <= -40 * WAD_INT) return 0;
        if (t >= 40 * WAD_INT) return WAD_INT;

        bool negative = t < 0;
        if (negative) t = -t;

        // Rational approximation for erfc
        int256 sum = unpackConstant(PACKED_CONSTANTS_2, 5); // P
        int256 z = t.rawSMulWad(t);

        // Unpack A1 to A5 constants
        int256 A1 = unpackConstant(PACKED_CONSTANTS_1, 0);
        int256 A2 = unpackConstant(PACKED_CONSTANTS_1, 1);
        int256 A3 = unpackConstant(PACKED_CONSTANTS_1, 2);
        int256 A4 = unpackConstant(PACKED_CONSTANTS_1, 3);
        int256 A5 = unpackConstant(PACKED_CONSTANTS_1, 4);

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

    function normalCDF(int256 x, int256 mu, int256 sigma) public view returns (int256) {
        int256 erfc = gaussianCDF(x, mu, sigma);
        return WAD_INT - erfc / 2;
    }
}
