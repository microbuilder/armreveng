# ARM Reverse Engineering Notes

This repository contains some personal notes on reverse engineering and binary
analysis for ARM-based embedded systems (mainly Cortex M).

> **WARNING**: This repository is a work in progress. Any information found
  here may or may not be reliably vetted. Any suggestions or improvements
  are welcome, but the official ARM documentation should be your go to source
  of information.

## Contents

### Reverse Engineering

- [Compilation](compilation.md): The GCC compiler and compilation process
- [Disassembly](disassembly.md): Binary disassembly
- [ELF Anatomy](elfanatomy.md): Totally SFW ELF anatomy lesson
- [ARM Initialisation](arminit.md): Cortex-M image initialisation process

### ARM Assembly

- [ARM Assembly Primer](armasm_primer.md): ARM THUMB(-2) assembly basics
- [ASM to Machine Code](asm2machine.md): ARM ASM to machine code and back again
- [GNU Inline Functions](armasm_gnu_inline.md): GNU ARM inline assembly syntax

## License

Copyright (C) 2020 Kevin Townsend. All rights reserved.

TODO: Review appropriate license options.
