#!/bin/bash

# Cleanup previous artifacts
echo "Performing cleanup"
rm -f firmware.* lpc55s69_zephyr.*

# Convert samples/lpc55s69_zephyr.bin to firmware.elf
echo "BIN2ELF: samples/lpc55s69_zephyr.bin -> firmware.elf"
scripts/bin2elf.sh samples/lpc55s69_zephyr.bin firmware.elf 0

# Disassemble firmware.elf
echo "DISASM:  firmware.elf -> firmware.elf.dis (stripped)"
arm-none-eabi-objdump -marm -Mforce-thumb -d firmware.elf > firmware.elf.dis

# Disassemble samples/lpc55s69_zephyr.elf (not stripped reference)
echo "DISASM:  samples/lpc55s59_zephyr.elf -> lpc55s69_zephyr.elf.dis (not stripped)"
arm-none-eabi-objdump -marm -D samples/lpc55s69_zephyr.elf > lpc55s69_zephyr.elf.dis
