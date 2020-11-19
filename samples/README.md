# Samples

This folder contains some simple embedded firmware images.

## LPC55S69-EVK

The images below target the LPC55S69 MCU from NXP (ARM Cortex M33, ARMv8-M),
and make use of [Zephyr RTOS](https://github.com/zephyrproject-rtos/zephyr) and
the [LPC55S69-EVK](https://www.nxp.com/design/development-boards/lpcxpresso-boards/lpcxpresso55s69-development-board:LPC55S69-EVK)
development board.

The images were built with Zephyr's `west` build tool via:

```bash
$ west build -b lpcxpresso55s69_cpu0 samples/hello_world
```

These images perform a minimal initialisation of the LPC55S69, output
`Hello, World!` to the serial port, and wait in an infinite loop.

Two versions of the firmware are present:

- `lpc55s69_zephyr.bin` is a stripped (no symbolic information) binary images
- `lpc55s69_zephyr.elf` is a non stripped (contains symbolic information) ELF
  image, which can be used to compare any disassembly output from the .bin
  file for validation purposes.
