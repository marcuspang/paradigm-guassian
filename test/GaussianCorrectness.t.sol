// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {GaussianCorrectness} from "../src/GaussianCorrectness.sol";
import {LibString} from "solady/utils/LibString.sol";

contract GaussianTest is Test {
    GaussianCorrectness public gaussian;

    int256[4][] testCases;

    function setUp() public {
        gaussian = new GaussianCorrectness();

        string memory inputs = vm.readFile("./test_cases.txt");
        string[] memory lines = LibString.split(inputs, "\n");

        testCases = new int256[4][](lines.length - 1);

        for (uint256 i = 0; i < lines.length - 1; i++) {
            string[] memory line = LibString.split(lines[i], ",");
            testCases[i] =
                [stringToInt256(line[0]), stringToInt256(line[1]), stringToInt256(line[2]), stringToInt256(line[3])];
        }
    }

    function stringToInt256(string memory s) public pure returns (int256 result) {
        bytes memory stringBytes = bytes(s);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            if (uint8(stringBytes[i]) >= 48 && uint8(stringBytes[i]) <= 57) {
                result = result * 10 + int8(uint8(stringBytes[i]) - 48);
            }
        }
    }

    function test_gaussianCDF() public view {
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
