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
file for anaylsis, which can be done with a debugger as shown below.

#### Dumping images with a Segger J-Link

```bash
$ JLinkExe ...
```

#### Converting binary files to ELF

You can convert a binary image, such as a firmware dump, into an appropriate
ELF image as follows:

> `.data=0x10000000` should be updated with the appropriate offset address for
  ROM data on the embedded device, which is the start of flash memory.

```bash
arm-none-eabi-objcopy -I binary -O elf32-little \
    --change-section-address .data=0x10000000 \
    firmware.bin firmware.elf
```

## Object file disassembly

You rarely have access to `.o` ASM build artifacts, but analysing them can
still be useful when debugging systems you have full control over yourself.

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

## Executable/binary disassembly

### Non-stripped binaries

These are generally rare in the real world, so we'll concentrate on stripped
binaries in these notes, but it's still useful to compare stripped and
non-stripped output, or you may have access to non-stripped binaries when
debugging your own systems:

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

Now contrast this with the real-world (i.e. dumped) stripped output below.

### Stripped binaries

Disassemble `a.out.stripped` to `a.out.stripped.dis` for analysis:

```bash
$ arm-none-eabi-objdump -d a.out.stripped > a.out.stripped.dis
```

This will yield the following information:

```
$ cat a.out.dis
a.out:     file format elf32-littlearm


Disassembly of section .init:

00008000 <.init>:
    8000:	bf00b5f8 	svclt	0x0000b5f8
    8004:	bc08bcf8 	stclt	12, cr11, [r8], {248}	; 0xf8
    8008:	4770469e 			; <UNDEFINED> instruction: 0x4770469e

Disassembly of section .text:

0000800c <.text>:
    800c:	2100b508 	tstcs	r0, r8, lsl #10
    8010:	f0004604 			; <UNDEFINED> instruction: 0xf0004604
    8014:	4b04f97b 	blmi	0x146608
    8018:	6bc36818 	blvs	0xff0e2080
...
Disassembly of section .fini:

00009fd4 <.fini>:
    9fd4:	bf00b5f8 	svclt	0x0000b5f8
    9fd8:	bc08bcf8 	stclt	12, cr11, [r8], {248}	; 0xf8
    9fdc:	4770469e 			; <UNDEFINED> instruction: 0x4770469e
```

The stripped output also includes the same three sections:

- `.init`: 
- `.text`: This section contains the project code
- `.fini`:

Unlike an executable containing symbol information, however, everything now
exists in a single large function or code entry. Not having code broken up into
logical chunks makes analysis much harder, but this is usually what we'll have
to deal with in the real world.
