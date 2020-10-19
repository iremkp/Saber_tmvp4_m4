# Saber_tmvp4_m4

This repository contains codes for multiplication in the quotient ring of polynomials Z<sub>2<sup>16</sup></sub>[x] /(x<sup>256</sup>+1), 
and application to the lattice-based key encapsulation mechanism Saber on ARM Cortex-M4.

## Setup and installation

Check [this document](https://github.com/mupq/polymul-z2mx-m4/blob/master/README.md) 
for requirements, and setup/installation instructions.

## Testing and Benchmarking LightSaber, Saber, and FireSaber

To generate the testing and benchmarking binaries for LightSaber, Saber, FireSaber schemes, 
and for multiplication in Z<sub>2<sup>16</sup></sub>[x] /(x<sup>256</sup>+1) run `make`.
This will build
- a `test-{scheme}.bin` which runs key generation, encapsulation, and decapsulation and checks if the obtained keys are the same. This should print `OK KEYS`
- a `benchmark-{scheme}.bin` which prints the cycle counts spent in key generation, encapsulation, and decapsulation
- a `stack-{scheme}.bin` which prints the stack usage of key generation, encapsulation, and decapsulation

for each scheme {lightsaber, saber, firesaber}, and
- a `benchmark-tmvp4_256_16.bin` which prints the cycle count spent in multiplication in the ring Z<sub>2<sup>16</sup></sub>[x] /(x<sup>256</sup>+1)
- a `stack-tmvp4_256_16.bin` which prints the stack usage of multiplication in the ring Z<sub>2<sup>16</sup></sub>[x] /(x<sup>256</sup>+1).

To flash the binaries to the board, and to receive and print the output from the board run `read_guest.py {binary}`.

To run all benchmarks for all schemes run `benchmarks-saber.py`.

## Licence

Most parts of the codes in this repository are taken from [PQM4](https://github.com/mupq/pqm4), 
and [polymul-z2mx-m4](https://github.com/mupq/polymul-z2mx-m4).
See [license of PQM4](https://github.com/mupq/pqm4#license), and 
[license of polymul-z2mx-m4](https://github.com/mupq/polymul-z2mx-m4/blob/master/LICENSE) for detailed information.

