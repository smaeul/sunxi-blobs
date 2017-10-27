# Overview

The goal of this project is to understand the various blobs provided by
Allwinner for their `sunxi` series of ARM SoCs. This includes understanding the
interfaces the blobs provide and the bits of undocumented hardware they use.
Currently, the tools in this repository are set up to process two types of
blobs: the boot ROMs and the ARISC firmware.

From the original, untouched blobs, the tools here can generate ELF objects with
symbols, annotated assembly listings, and SVG graphs documenting the control
flow of code within the blob.

## Boot ROMs (BROM)

The boot ROM, is flashed into the SoC hardware, and is generally the same for
every chip of the same model. It comes in two flavors: normal (NBROM) and secure
(SBROM). The secure boot ROM is much larger and more complicated because it must
verify the next stage of firmware before running it. Unfortunately, only one of
the ROMs is visible at a time, depending on the state of the device's "secure
boot" eFuse.

The BROM blobs in this repository were dumped from running devices using `md`
from within u-boot.

## ARISC firmware

These files are closed-source firmware provided by Allwinner with their board
support package (BSP), usually with the name `scp.bin`. Slightly different
versions of the firmware are provided in the BSPs from different board
manufacturers. By looking at the changes between versions (and knowing the order
from the embedded version number), we can determine the history of changes made
to the firmware.

While the firmware is proprietary, source code is provided in an AES-encrypted
tarball in [various released Linux kernel trees][tinalinux].

[tinalinux]:
https://github.com/tinalinux/linux-3.10/tree/r18-v0.9/drivers/arisc/binary

# Prerequisites

These tools require a cross `binutils` (or full toolchain) for each architecture
of blobs you want to process. Note that even on SoCs that support AArch64, the
BROM is still AArch32, so you will need ARM cross tools for them. Cross
toolchains can be downloaded from Linaro for ARM, [GitHub][or1k-toolchains] for
OpenRISC, or they can be built manually with [musl-cross-make][musl-cross-make].
If your cross toolchain is named differently, edit the top of the `Makefile` to
provide your path or prefix.

[musl-cross-make]: https://github.com/smaeul/musl-cross-make
[or1k-toolchains]: https://github.com/openrisc/or1k-gcc/releases

Beyond that, the scripts only require `bash` and standard POSIX utilities.

# Using the tools

`make BLOB=<soc>/<blob_name>` will build a single blob all the way from the
hexdump to the call graph. You can simply run `make` to build all files for all
blobs. You can run `make <soc>/<blob_name>/<file>` for any file (`annotated.s`
`blob.elf`, `blob.s`, `callgraph.dot`, and `callgraph.svg`) to only make that
file and its dependencies.

There are some additional scripts that are useful for processing newly-found
blobs or forr other specific use cases. They are not hooked up to the
`Makefile`, so they must be run manually. Documentation is at the top of each
script.

# Contributing

After modifying the annotations in `annotated.s`, run `make save` to copy them
back to the `comments` file. You can then commit your changes to `comments`. If
you find a new, previously-unmarked function, create a symbol for it in the
`symbols` file. *Add two blank lines before the first instruction in
`annotated.s` and run `make save` before running `make` again*. This is
important to keep the comments aligned, as `objdump` will place a blank line and
a line with the symbol name before the function.

Please run `make check` to check the consistency of your symbols and sections
files.
