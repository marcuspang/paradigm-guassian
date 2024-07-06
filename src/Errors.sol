// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// must be in the range of 0 < sigma <= 1e37
error InvalidSigma();
// must be in the range of -1e38 <= mu <= 1e38
error InvalidMu();
// must be in the range of -1e41 <= x <= 1e41
error InvalidX();
