# ARM Initialisation

Information on the initialisation of ARMv6-M Thumb and ARMv7-M/ARMv8-M THUMB-2
images.

## Prerequisites

### Sample ELF file

This page uses the `samples/lpc55s69_zephyr.bin` firmware image dump, converted
to an ELF file, as an example. You can generate this ELF file via:

```bash
$ scripts/bin2elf.sh samples/lpc55s69_zephyr.bin firmware.elf 0
```

You should also disassemble this image to a text file via:

```bash
$ arm-none-eabi-objdump -marm -Mforce-thumb -d firmware.elf > firmware.elf.dis
```

> **IMPORTANT**: Note the `-Mforce-thumb` flag, which is required to parse the
  data as 16-bit THUMB instructions, NOT classic 32-bit ARM instructions.

### Documentation

Depending on the ARM Cortex-M device being used, the appropriate ARM
Architecture Reference Manual should also be consulted. We'll be using the
ARMv8-M manual here since the NXP LPC55S69 is an ARM Cortex-M33.

| Instruction Set    | Associated ARM Cortex Device(s) |
| ------------------ | ------------------------------- |
| ARMv6-M (Thumb)    | ARM Cortex M0, ARM Cortex-M0+   |
| ARMv7-M (Thumb-2)  | ARM Cortex-M3                   |
| ARMv7E-M (Thumb-2) | ARM Cortex M4(F), ARM Cortex M7 |
| ARMv8-M (Thumb-2)  | ARM Cortex M23, ARM Cortex M33  |

The appropriate document can be accessed from the list below:

- [ARM v6-M Architecture Reference Manual](https://static.docs.arm.com/ddi0419/d/DDI0419D_armv6m_arm.pdf)
- [ARM v7-M Architecture Reference Manual](https://static.docs.arm.com/ddi0403/eb/DDI0403E_B_armv7m_arm.pdf)
- [ARM v8-M Architecture Reference Manual](https://static.docs.arm.com/ddi0553/a/DDI0553A_e_armv8m_arm.pdf)

You will also want to download the [LPC55S69 User Manual](https://www.nxp.com/webapp/Download?colCode=UM11126),
which contains technical details about the LPC55S69 (login may be required).

## Vector Table Setup

All ARM Cortex-M devices have a similar device initialisation process, with
only minor variation in the contents of the startup vector table. The first
record in the firmware image points to the bottom of the stack memory, and
subsequent records point to important sections of code in the binary image.

### Initial stack pointer (ISP)

The NXP LPC55S59 is an ARM Cortex-M33, meaning that it is based on the ARMv8-M
architecture. As such, we know that the first word (32 bits or 4 B) in our
firmware is the address of the **initial stack pointer**, 0x200006e0 in this
case.

The means that **stack memory** starts at 0x200006e0, and will grow upwards
from there towards 0x20000000.

> NOTE: All values seen in the disassembly have 0x10000000 added to them due to
  the way the LPC55S69 duplicates secure and non-secure addresses in memory by
  placing secure equivalents to non-secure addresses 0x100000000 higher
  (setting bit 28 to 1). We can simply subtract the 0x10000000 for analysis
  purposes for now.

### Vector table

The next 15+n words are the **vector table**.

> For details on the intended usage of these exceptions, see:
  [ARMv8-M Exception Types](armv8exceptions.md).

The initial 15 vector table entries are common to any ARM Cortex-M33, and are
described in [Arm Cortex-M33 Devices Generic User Guide: Vector Table](https://developer.arm.com/documentation/100235/0002/the-cortex-m33-processor/exception-model/vector-table), and shown below:

![ARMv8-M vector table](img/armv8m_vectortable.svg "ARMv8-M vector table")

Subsequent values are defined by the silicon vendor. The user manual for the LPC55S69 (Chapter 3:
Nested Vectored Interrupt Controller) informs us that there are 59 of
these, for a total of 15+59 exception handlers plus the ISP, so 75 words or
300 B, meaning the vector table ends after 0x12C.

```
00000000 <.text>:
<START OF VECTOR TABLE>
       0:	06e0      	lsls	r0, r4, #27
       2:	3000      	adds	r0, #0        # Initial Stack Pointer
<START OF ARM INTERRUPTS>
       4:	0c15      	lsrs	r5, r2, #16
       6:	1000      	asrs	r0, r0, #32   # 1 ARM: Reset
       8:	0b8d      	lsrs	r5, r1, #14
       a:	1000      	asrs	r0, r0, #32   # 2 ARM: NMI
       c:	0c41      	lsrs	r1, r0, #17
       e:	1000      	asrs	r0, r0, #32   # 3 ARM: HardFault
      10:	0c41      	lsrs	r1, r0, #17
      12:	1000      	asrs	r0, r0, #32   # 4 ARM: MemManage
      14:	0c41      	lsrs	r1, r0, #17
      16:	1000      	asrs	r0, r0, #32   # 5 ARM: BusFault
      18:	0c41      	lsrs	r1, r0, #17
      1a:	1000      	asrs	r0, r0, #32   # 6 ARM: UsageFault
      1c:	0c41      	lsrs	r1, r0, #17
      1e:	1000      	asrs	r0, r0, #32   # 7 ARM: SecureFault
... <RESERVED REGION>
      2c:	0a65      	lsrs	r5, r4, #9
      2e:	1000      	asrs	r0, r0, #32   # 11 ARM: SVCall
      30:	0c41      	lsrs	r1, r0, #17
      32:	1000      	asrs	r0, r0, #32   # 12 ARM: DebugMonitor
      34:	0000      	movs	r0, r0
      36:	0000      	movs	r0, r0        # 13 ARM: Reserved
      38:	0a0d      	lsrs	r5, r1, #8
      3a:	1000      	asrs	r0, r0, #32   # 14 ARM: PendSV
      3c:	0849      	lsrs	r1, r1, #1
      3e:	1000      	asrs	r0, r0, #32   # 15 ARM: SysTick
<END OF ARM INTERRUPTS>
<START OF VENDOR INTERRUPTS>
      40:	0bed      	lsrs	r5, r5, #15
      42:	1000      	asrs	r0, r0, #32   # 16 NXP: WDT/BOD/Flash
... <REMOVED FOR BREVITY SAKE>
     128:	0bed      	lsrs	r5, r5, #15
     12a:	1000      	asrs	r0, r0, #32   # 16+58 NXP: SDMA1
     12c:	0bed      	lsrs	r5, r5, #15
     12e:	1000      	asrs	r0, r0, #32   # 16+59 NXP: HS_SPI
<END OF VECTOR TABLE>
<START OF CODE SECTION>
     130:	b953      	cbnz	r3, 0x148
     132:	b94a      	cbnz	r2, 0x148
     134:	2900      	cmp	r1, #0
     136:	bf08      	it	eq
     138:	2800      	cmpeq	r0, #0
     13a:	bf1c      	itt	ne
```

> IMPORTANT: Because ARM Cortex-M devices use **16-bit THUMB-2** instructions
  and **LSB byte ordering**, you should substract 1 from the referenced address
  to get to the top of the half-word, meaning we want to look at 0xC14
  (byte 3092) for the reset vector, for example.

> NOTE: The ASM output in the vector table here (`lsls`, `adds`, before
  address 0x130) can be ignored, since this section isn't actually code, but a
  set of vectors that must be place at the start of every valid image.

## Initial Code Execution

### Reset vector

The important value above is the **Reset** vector at 0x4, which points to
**0xC15** in our `.text` section. This is the address that the ARM processor
will jump to when it powers up or comes out of reset, and where any code
analysis will likely begin.

Skipping ahead to 0xc14, we find the following code:

```
     c14:	2020      	movs	r0, #32
     c16:	f380 8811 	msr	BASEPRI, r0
     c1a:	4808      	ldr	r0, [pc, #32]	; (0xc3c)
     c1c:	f44f 6100 	mov.w	r1, #2048	; 0x800
     c20:	1840      	adds	r0, r0, r1
     c22:	f380 8809 	msr	PSP, r0
     c26:	f3ef 8014 	mrs	r0, CONTROL
     c2a:	2102      	movs	r1, #2
     c2c:	4308      	orrs	r0, r1
     c2e:	f380 8814 	msr	CONTROL, r0
     c32:	f3bf 8f6f 	isb	sy
     c36:	f7ff ffb7 	bl	0xba8
     c3a:	0000      	movs	r0, r0
     c3c:	0820      	lsrs	r0, r4, #32
     c3e:	3000      	adds	r0, #0
     ...
```

If this was a non stripped ELF image generated by GCC, this would resolve to
`__start`, which is the earliest code that is executed by an image, run before
we get anywhere near `main`.

Although this is cheating, analyzing the matching non stripped disassembly of
`samples/lpc55s69_zephyr.elf` would show the following for the same address,
very closely matching the disassembly output above, although there are some key
differences (0xc3c + 0xc3e, missing function names on branches, etc.):

```
10000c14 <__start>:
10000c14:	2020      	movs	r0, #32
10000c16:	f380 8811 	msr	BASEPRI, r0
10000c1a:	4808      	ldr	r0, [pc, #32]	; (10000c3c <__start+0x28>)
10000c1c:	f44f 6100 	mov.w	r1, #2048	; 0x800
10000c20:	1840      	adds	r0, r0, r1
10000c22:	f380 8809 	msr	PSP, r0
10000c26:	f3ef 8014 	mrs	r0, CONTROL
10000c2a:	2102      	movs	r1, #2
10000c2c:	4308      	orrs	r0, r1
10000c2e:	f380 8814 	msr	CONTROL, r0
10000c32:	f3bf 8f6f 	isb	sy
10000c36:	f7ff ffb7 	bl	10000ba8 <z_arm_prep_c>
10000c3a:	0000      	.short	0x0000
10000c3c:	30000820 	.word	0x30000820
```