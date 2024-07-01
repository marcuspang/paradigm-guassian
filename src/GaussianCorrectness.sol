// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import "./Errors.sol";

/// @title Implementation of Gaussian CDF function
/// @author Marcus Pang
/// @notice Uses Dia (2023) approximation for the Gaussian CDF.
/// @dev Note
/// The implementation uses fixed-point arithmetic with 18 decimals. The values are bounded by
/// -1e20 <= μ <= 1e20, 0 <= σ <= 1e19, -1e23 <= x <= 1e23, and an error rate of < 1e-8.
contract GaussianCorrectness {
    using FixedPointMathLib for int256;

    // Constants
    int256 private constant WAD_INT = 1e18;
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
        if (sigma <= 0 || sigma > 1e37) revert InvalidSigma();
        if (mu < -1e38 || mu > 1e38) revert InvalidMu();
        if (x < -1e41 || x > 1e41) revert InvalidX();

        // Standardize x
        int256 z = ((x - mu) * WAD_INT) / sigma;

        int256 numerator = 0;
        int256 denominator = z + B_0;

        for (uint256 i = 0; i < 5; i++) {
            int256 z_squared = z.rawSMulWad(z);
            numerator += (C_2[i].rawSMulWad(z_squared) + C_1[i]).rawSMulWad(z);
            denominator = denominator.rawSMulWad(z_squared + B_2[i].rawSMulWad(z) + B_1[i]);
        }

        // Compute M
        int256 m = numerator.rawSDivWad(denominator);

        // Compute exp(-z^2/2)
        int256 exp_term = (-z.rawSMulWad(z) / 2).expWad();

        // Compute erfc using the relation from Proposition 10
        erfc = (SQRT_2PI.rawSMulWad(m)).rawSMulWad(exp_term);
    }

    function normalCDF(int256 x, int256 mu, int256 sigma) public view returns (int256) {
        if (x < mu) {
            return WAD_INT - normalCDF(2 * mu - x, mu, sigma);
        } else {
            int256 erfc = gaussianCDF(x, mu, sigma);
            return WAD_INT - erfc / 2;
        }
    }
}
