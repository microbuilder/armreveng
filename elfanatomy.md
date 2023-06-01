# Anatomy of an ARM ELF File

Information on the structure and analysis of 32-bit ARM ELF image dumps.

## What is an ELF File?

ELF is a common output format used by numerous compilers, including GCC.
The files are made up of `sections`, including program data and debug
data. Debug data is often based on the related DWARF format, and is typically
placed in `.debug_*` sections in the ELF file.

## Prerequisites

### Sample ELF file

This page uses the `samples/lpc55s69_zephyr.bin` firmware image dump, converted
to an ELF file, as an example. You can generate this ELF file via:

```bash
$ scripts/bin2elf.sh samples/lpc55s69_zephyr.bin firmware.elf 0
```

## Sections

ELF images are arranged into sections, with the name and number of sections
varying based on the image you are analysing.

### Stripped ELF files

A stripped ARM ELF file, such as we'd get with a firmware dump that we've
converted to an ELF file, will have a `.text` section, containing the full
machine code, and likely a footer named `.shstrtab`:

```bash
$ arm-none-eabi-readelf --sections --wide firmware.elf
There are 3 section headers, starting at offset 0x13660:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        00000000 010000 00364c 00  AX  0   0  1
  [ 2] .shstrtab         STRTAB          00000000 01364c 000011 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  y (purecode), p (processor specific)
```

The `.text` section has the `PROGBITS` type, is 13900 B long (0x364C), and has
the `AX` flags

As shown in the `Key to Flags` text above, this corresponds to:

- `A (alloc)`, meaning that this section occupies memory during execution.
- `X (execute)`, meaning that this section contains executable machine code.

The fact that the `W (write)` flag isn't set means this data is also read-only.

Our entire firmware image is held here, and this is what we will attempt to
analyse in more detail.

### Non stripped ELF files

By way of constrast, listing the sections of a non-stripped executable would
yield far more sections, and additional useful information in the ELF file:

```bash
$ arm-none-eabi-readelf --sections --wide samples/lpc55s69_zephyr.elf 
There are 25 section headers, starting at offset 0x98034:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] rom_start         PROGBITS        10000000 0000b4 000130 00 WAX  0   0  4
  [ 2] text              PROGBITS        10000130 0001e4 002f90 00  AX  0   0  4
  [ 3] .ARM.exidx        ARM_EXIDX       100030c0 003174 000008 00  AL  2   0  4
  [ 4] initlevel         PROGBITS        100030c8 00317c 000060 00   A  0   0  4
  [ 5] sw_isr_table      PROGBITS        10003128 0031dc 0001e0 00  WA  0   0  4
  [ 6] rodata            PROGBITS        10003308 0033bc 0002b8 00   A  0   0  4
  [ 7] .ramfunc          PROGBITS        30000000 003700 000000 00   W  0   0  1
  [ 8] datas             PROGBITS        30000000 003674 000018 00  WA  0   0  4
  [ 9] devices           PROGBITS        30000018 00368c 000074 00   A  0   0  4
  [10] bss               NOBITS          30000090 003700 00024b 00  WA  0   0  8
  [11] noinit            NOBITS          300002e0 003700 000d40 00  WA  0   0  8
  [12] .comment          PROGBITS        00000000 003700 00004c 01  MS  0   0  1
  [13] .debug_aranges    PROGBITS        00000000 003750 001218 00      0   0  8
  [14] .debug_info       PROGBITS        00000000 004968 0423d7 00      0   0  1
  [15] .debug_abbrev     PROGBITS        00000000 046d3f 00a251 00      0   0  1
  [16] .debug_line       PROGBITS        00000000 050f90 019456 00      0   0  1
  [17] .debug_frame      PROGBITS        00000000 06a3e8 0028e0 00      0   0  4
  [18] .debug_str        PROGBITS        00000000 06ccc8 00dc77 01  MS  0   0  1
  [19] .debug_loc        PROGBITS        00000000 07a93f 011dbc 00      0   0  1
  [20] .debug_ranges     PROGBITS        00000000 08c700 003da8 00      0   0  8
  [21] .ARM.attributes   ARM_ATTRIBUTES  00000000 0904a8 000034 00      0   0  1
  [22] .symtab           SYMTAB          00000000 0904dc 0043f0 10     23 613  4
  [23] .strtab           STRTAB          00000000 0948cc 003673 00      0   0  1
  [24] .shstrtab         STRTAB          00000000 097f3f 0000f4 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  y (purecode), p (processor specific)
```

Noteworthy sections include:

- `text` contains executable source code (functions, etc.)
- `rodata` contains constant values (located in flash memory)
- `datas` (sometimes `data`) contains default values of initialised variables
  (located in SRAM)
- `bss` is space reserved for uninitialised variables (located in SRAM)

> NOTE: If you don't see sections like `rodata` in your disassembly output,
  you likely ran `objdump` with the `-d` flag, which only disassembles
  executable sections. Use the `-D` flag to disassemble the contents of every
  section in the image, including `rodata`.

## ABI Details from ELF Files

You can get basic ABI (Application Binary Interface) details from a file via:

```bash
$ arm-none-eabi-readelf -A samples/lpc55s69_zephyr.elf 
Attribute Section: aeabi
File Attributes
  Tag_CPU_name: "Cortex-M33"
  Tag_CPU_arch: v8-M.mainline
  Tag_CPU_arch_profile: Microcontroller
  Tag_THUMB_ISA_use: Yes
  Tag_ABI_PCS_wchar_t: 4
  Tag_ABI_FP_denormal: Needed
  Tag_ABI_FP_exceptions: Needed
  Tag_ABI_FP_number_model: IEEE 754
  Tag_ABI_align_needed: 8-byte
  Tag_ABI_enum_size: small
  Tag_ABI_optimization_goals: Aggressive Size
  Tag_CPU_unaligned_access: v6
  Tag_DSP_extension: Allowed
```

## TODO: Parsing stripped `.text` sections

How do we bridge the gap in understanding between the large `.text` section in
the stripped binary, and the various sections in the non stripped file?
