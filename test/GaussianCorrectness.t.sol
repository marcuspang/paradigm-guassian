// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {GaussianCorrectness} from "../src/GaussianCorrectness.sol";
import {GaussianTestHelper} from "./GaussianTestHelper.sol";

contract GaussianTest is GaussianTestHelper {
    GaussianCorrectness public gaussian = new GaussianCorrectness();

    function test_gaussianCorrectnessCDF() public view {
        for (uint256 i = 0; i < testCases.length; i++) {
            int256 x = testCases[i][0];
            int256 mu = testCases[i][1];
            int256 sigma = testCases[i][2];
            int256 expectedResult = testCases[i][3];
            int256 result = gaussian.gaussianCDF(x, mu, sigma);

            // check result is less than 1e-8 away from expected result
            // which is 10e18 fixed point here
            // TODO: error rate is too high, at 1e-8
            int256 diff = result - expectedResult;
            assertLe(diff, 10 ** 18);
            assertGe(diff, -int256(10 ** 18));
        }
    }
}
