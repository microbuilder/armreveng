#!/bin/sh
# Convert a raw binary image into an ELF file suitable for loading into a disassembler
# Source: https://gist.github.com/tangrs/4030336
# Usage: bin2elf.sh input.bin output.elf baseaddr

cat > raw$$.ld <<EOF
SECTIONS
{
EOF

echo " . = $3;" >> raw$$.ld

cat >> raw$$.ld <<EOF
  .text : { *(.text) }
}
EOF

arm-none-eabi-ld -b binary -r -o raw$$.elf $1
arm-none-eabi-objcopy  --rename-section .data=.text \
    --set-section-flags .data=alloc,code,load raw$$.elf
arm-none-eabi-ld raw$$.elf -T raw$$.ld -o $2
arm-none-eabi-strip -s $2

rm -rf raw$$.elf raw$$.ld
