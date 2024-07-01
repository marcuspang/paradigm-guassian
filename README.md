# Gaussian CDF

This repository contains 2 implementations of the Gaussian CDF function:

1. The first implementation uses the Abramowitz and Stegun approximation, which unfortunately has an error rate of exactly 1e-8, and does not fit the constraints.
2. The second implementation uses the Dia (2023) approximation, which has an error rate of < 1e-8 (2 \*\* -53 for normal distribution) and fits the constraints, but uses significantly more gas.

Hence, my submission is the second implementation.

## Gas Benchmarks

See [gas-snapshot](./.gas-snapshot) for more information.

Benchmarks were done on test cases generated using [generate_test.js](./generate_test.js).

On large test case sizes, the second implementation takes 50% more gas than the first implementation.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```
