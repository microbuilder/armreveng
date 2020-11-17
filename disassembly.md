# Disassembly

Notes on disassembly of ARM binaries and object files.

## Prerequisites

### Sample build artifacts

Parts of this section assume the object and executable output of the sample
code described in [compilation](compilation.md), which can be generated
as follows:

```bash
# Generate machine code output (hello_world.o)
$ arm-none-eabi-gcc -march=armv7-m -c src/hello_world.c
# Generate a non-stripped binary (a.out)
$ arm-none-eabi-gcc -march=armv7-m --specs=nosys.specs src/hello_world.c
# Generate a stripped binary (a.out.stripped)
$ arm-none-eabi-gcc -march=armv7-m --specs=nosys.specs -s src/hello_world.c -o a.out.stripped
```

### Other input files

You may also wish to capture a binary firmware dump, and convert it to an ELF
file for analysis, which can be done with a debugger as shown below.

#### Dumping binary images with a Segger J-Link

The `savebin` command can be used to dump flash memory to a file, and has the
following syntax:

`savebin <filename>, <addr>, <NumBytes> (hex)`

Values must be provided in hex, so dumping 640 KB flash = 655360 B = `0xA0000`.

```bash
$ JLinkExe -device lpc55s69 -if swd -speed 2000 -autoconnect 1
J-Link>savebin firmware.bin 0x0 0xA0000
```

#### Converting binary dumps to ELF executables

You can convert a raw binary image, such as a firmware dump, into an
ELF image with the following script:

> Script source: https://gist.github.com/tangrs/4030336

```bash
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
```

For example, assuming a base flash address of 0x0, we can convert
`samples/lpc55s69_zephyr.bin` to `firmware.elf` via:

```bash
$ scripts/bin2elf.sh samples/lpc55s69_zephyr.bin firmware.elf 0
```

## Object file disassembly

You rarely have access to `.o` ASM build artifacts, but analysing them can
still be useful when debugging your own projects where you have full access to
the compiler output.

### Dump read-only data

```bash
$ arm-none-eabi-objdump -sj .rodata hello_world.o

hello_world.o:     file format elf32-littlearm

Contents of section .rodata:
 0000 48656c6c 6f2c2057 6f726c64 2100      Hello, World!.
```

### Dump assembly code

```bash
$ arm-none-eabi-objdump -d hello_world.o

hello_world.o:     file format elf32-littlearm


Disassembly of section .text:

00000000 <main>:
   0:   b580            push    {r7, lr}
   2:   b082            sub     sp, #8
   4:   af00            add     r7, sp, #0
   6:   6078            str     r0, [r7, #4]
   8:   6039            str     r1, [r7, #0]
   a:   4804            ldr     r0, [pc, #16]   ; (1c <main+0x1c>)
   c:   f7ff fffe       bl      0 <puts>
  10:   2300            movs    r3, #0
  12:   4618            mov     r0, r3
  14:   3708            adds    r7, #8
  16:   46bd            mov     sp, r7
  18:   bd80            pop     {r7, pc}
  1a:   bf00            nop
  1c:   00000000        .word   0x00000000
```

This matches the ASM output we generated quite closely. 

- The instruction at 0xA (`ldr     r0, [pc, #16]   ; (1c <main+0x1c>)`) loads
  our `"Hello, World!\n"` string reference at 0x1C (pointing to `.rodata 0000`)
  into `r0`.
- The instruction at 0xC will make the call to `puts`, with `r0` being the
  first parameter for this call according to ARM standards.

## Executable disassembly

### Non-stripped executables

These are generally rare in the real world, so we'll concentrate on stripped
binaries in these notes, but it's still useful to compare stripped and
non-stripped output, or you may have access to non-stripped binaries when
debugging your own systems:

Check that we have a `not stripped` ELF file:

```bash
$ file a.out
a.out: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, not stripped
```

Disassemble `a.out` to `a.out.dis` for analysis:

```bash
$ arm-none-eabi-objdump -d a.out > a.out.dis
```

Here, we can clearly see the individual functions in the `.text` section,
such as:

```
...
Disassembly of section .text:
...
00008088 <_mainCRTStartup>:
    8088:	4b17      	ldr	r3, [pc, #92]	; (80e8 <_mainCRTStartup+0x60>)
    808a:	2b00      	cmp	r3, #0
    808c:	bf08      	it	eq
    808e:	4b13      	ldreq	r3, [pc, #76]	; (80dc <_mainCRTStartup+0x54>)
    8090:	469d      	mov	sp, r3
    8092:	f7ff fff5 	bl	8080 <_stack_init>
...
000080fc <main>:
    80fc:	b580      	push	{r7, lr}
    80fe:	b082      	sub	sp, #8
    8100:	af00      	add	r7, sp, #0
    8102:	6078      	str	r0, [r7, #4]
    8104:	6039      	str	r1, [r7, #0]
    8106:	4804      	ldr	r0, [pc, #16]	; (8118 <main+0x1c>)
    8108:	f000 f8ca 	bl	82a0 <puts>
    810c:	2300      	movs	r3, #0
    810e:	4618      	mov	r0, r3
    8110:	3708      	adds	r7, #8
    8112:	46bd      	mov	sp, r7
    8114:	bd80      	pop	{r7, pc}
    8116:	bf00      	nop
    8118:	00009fe0 	.word	0x00009fe0
...
000082a0 <puts>:
    82a0:	4b02      	ldr	r3, [pc, #8]	; (82ac <puts+0xc>)
    82a2:	4601      	mov	r1, r0
    82a4:	6818      	ldr	r0, [r3, #0]
    82a6:	f7ff bfad 	b.w	8204 <_puts_r>
    82aa:	bf00      	nop
    82ac:	0001a014 	.word	0x0001a014
...
```

Now contrast this with the real-world (i.e. dumped/stripped) output below.

### Stripped executables

Check that we have a `stripped` ELF file:

```bash
$ file a.out.stripped
a.out.stripped: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, stripped
```

Disassemble `a.out.stripped` to `a.out.stripped.dis` for analysis:

```bash
$ arm-none-eabi-objdump -marm -Mforce-thumb -d a.out.stripped > a.out.stripped.dis
```

> **IMPORTANT**: Note the `-Mforce-thumb` flag, which is required to parse the
  data at 16-bit THUMB instructions, NOT classic 32-bit ARM instructions.

This will yield the following information:

```
$ cat a.out.stripped.dis

a.out.stripped:     file format elf32-littlearm


Disassembly of section .init:

00008000 <.init>:
    8000:	b5f8      	push	{r3, r4, r5, r6, r7, lr}
    8002:	bf00      	nop
    8004:	bcf8      	pop	{r3, r4, r5, r6, r7}
    8006:	bc08      	pop	{r3}
    8008:	469e      	mov	lr, r3
    800a:	4770      	bx	lr

Disassembly of section .text:

0000800c <.text>:
    800c:	b508      	push	{r3, lr}
    800e:	2100      	movs	r1, #0
    8010:	4604      	mov	r4, r0
    8012:	f000 f97b 	bl	0x830c
...
Disassembly of section .fini:

00009fd4 <.fini>:
    9fd4:	b5f8      	push	{r3, r4, r5, r6, r7, lr}
    9fd6:	bf00      	nop
    9fd8:	bcf8      	pop	{r3, r4, r5, r6, r7}
    9fda:	bc08      	pop	{r3}
    9fdc:	469e      	mov	lr, r3
    9fde:	4770      	bx	lr
```

The stripped output includes the same three sections as non-stripped files:

- `.init`: Process initialisation code (run before `main` entry point)
- `.text`: This section contains the project code
- `.fini`: Process termination code (run on exit, after `main` returns)

Unlike an executable containing symbol information, however, everything now
exists in a single large function or code entry.

Not having code broken up into logical chunks makes analysis much harder, but
this is usually what we'll have to deal with in the real world. Thankfully,
there are tools to help detect function definitions within disassembled blobs
like this, which we'll look at elsewhere.

### Dumped/converted executables (`bin2elf.sh`)

If we were disassembling a firmware dump that had been converted to an ELF
file, we would get the following output, where only the `.text` section would
be present:

```bash
$ arm-none-eabi-objdump -marm -Mforce-thumb -d firmware.elf > firmware.elf.dis
```

> **IMPORTANT**: Note the `-Mforce-thumb` flag, which is required to parse the
  data at 16-bit THUMB instructions, NOT classic 32-bit ARM instructions.

```bash
$ cat firmware.elf.dis
firmware.elf:     file format elf32-littlearm


Disassembly of section .text:

00000000 <.text>:
       0:	06e0      	lsls	r0, r4, #27
       2:	3000      	adds	r0, #0
       4:	0c15      	lsrs	r5, r2, #16
       6:	1000      	asrs	r0, r0, #32
       8:	0b8d      	lsrs	r5, r1, #14
       a:	1000      	asrs	r0, r0, #32
       c:	0c41      	lsrs	r1, r0, #17
       e:	1000      	asrs	r0, r0, #32
...
```

> NOTE: All values here have 0x10000000 added to them due to the way the
  LPC55S69 duplicates secure and non-secure addresses in memory by placing
  secure equivalents to non-secure addresses 0x100000000 higher (setting
  bit 28 to 1).

The first value in the dumped image is 0x300006E0, which is the **secure**
equivalent of 0x200006E0, which means our **initial stack pointer** starts
1760 B into the SRAM range of this chip (SRAM starting at 0x2000000 in the
LPC55S69's memory map).

The second record in the vector table is the **reset vector**, which is where
code execution will begin coming out of reset. We can then jump to 0xC14 in the
disassembled code -- 0xC14 instead of 0xC15 since ARM Cortex-M devices use
16-bit THUMB instructions -- and start to trace code execution in assembly from
there.

> The ASM output in the vector table here (`lsls`, `adds`, etc.) can be ignored,
  since this section isn't actually code, but a set of vectors that must be at
  the start of every valid image.

> NOTE: We can also go straight from a stripped .bin file to the decompiled
  output via: `arm-none-eabi-objdump -D -b binary -marm -Mforce-thumb firmware.bin`,
  although in that case the contents of the `.text` section will appear under
  `.data`. The `bin2elf.sh` script renames the section for you.

Continue on to [elfdumps](elfdumps.md) for details on analysing the `.text`
section in more detail.
