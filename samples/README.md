# Samples

This folder some simple embedded firmware images. 

## LPC55S69-EVK

The following images target theLPC55S69 MCU from NXP (an ARM Cortex M33 MCU),
and make use of [Zephyr RTOS](https://github.com/zephyrproject-rtos/zephyr) and
the [LPC55S69-EVK](https://www.nxp.com/design/development-boards/lpcxpresso-boards/lpcxpresso55s69-development-board:LPC55S69-EVK)
development board.

The firmware images have been built with the following settings:

```bash
$ west build -b lpcxpresso55s69_cpu0 samples/hello_world
```

Two versions of the firmware are present:

- `lpc55s69_zephyr.bin` is a stripped (no symbolic information) binary images
- `lpc55s69_zephyr.eld` is a non stripped (contains cymbolic information) ELF
  image, which can be used to compare any disassembly output from the .bin
  file for validation purposes.
