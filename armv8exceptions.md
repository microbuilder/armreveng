# ARMv8-M Exception/Stack Handling

ARMv8-M exception handling, triggers, and stack frames.

> Most of these concepts also apply to ARMv7-M (M4, M7) and ARMv6-M (M0)
  devices, aside from some security-related exceptions.

## ARMv8-M Operational Modes

ARMv8-M devices have the following operation modes or states:

| Mode     | Secure                                     | Non-Secure          |
|---------:|:------------------------------------------:|:-------------------:|
| Handler  | S Handler (Privileged)                     | NS Handler (Privileged) |
| Thread   | Privileged S Thread, Unprivileged S Thread | Privileged NS Thread, Unpriviliged NS Thread |

### Thread vs. Handler Modes

- The processer runs in **thread** mode out of reset
- When an exception occurs, the processor switches to **handler** mode (which
  is alway privileged).

The process of switching modes can be seen in the following diagram:

```
RESET
  |
  v
Thread
 Mode
  |
  |
  x --> Exception --> Handler Mode
  |<----------------+        v
  |                 |  +-----------+
  |                 |  + Exception +
  |                 |  +  handler  +
  |                 |  +   runs    +
  |                 |  +-----------+
  |                 |        |
  -                 +--------+
```

### Privileged vs. Unprivileged Levels

These two levels limit the access of instructions that change the processor
state.

- Privileged level allows access to all instructions and resources, and has
  exclusive access to the `CONTROL` register to change the privilege level for
  software in thread mode.
- Unprivileged level allows access to the `SVC` instruction to make Supervisor
  calls to transfer control to privileged software.
- Unprivileged level may have restricted access to the system timer, `NVIC` or
  `SCB`, and may have restricted memory/peripheral access.

## Exception Handling

When we enter an exception handler, the following stack operations take place:

- The stack frame includes the return address, which is the next instruction
  in the interrupted program. On exception return, this value is restored to
  the `PC` register.
- In parallel to the stacking operation, the processor writes an `EXC_RETURN`
  value to the `LR` register (`R14`).

The stack frame and `EXC_RETURN` values are described below.

### Stack Frames

On taking an exception, state context is saved onto the stack that the `SP`
register points to. The basic state context consists of eight 32-bit words:
`xPSR`, the return address, `LR`, `R12`, `R3`, `R2`, `R1`, `R0`. A secure
stack frame includes additional information.

> NOTE: If `CONTROL.FPCA` is 1 when the exception is taken, the floating-point
  context will be also saved on the stack, which isn't shown below:

```
ADDR    BASIC STACK FRAME       SECURE STACK FRAME
----    -----------------       ------------------
0x68    [ Orig. SP  ]           [  Orig. SP ]
0x64    [   xPSR    ]           [   xPSR    ] --+
0x60    [ Ret. Addr ] PC        [ Ret. Addr ]   | PC
0x5C    [ LR (R14)  ]           [ LR (R14)  ]   |
0x58    [    R12    ]           [    R12    ]   |-> State Context
0x54    [    R3     ]           [    R3     ]   |
0x50    [    R2     ]           [    R2     ]   |
0x4C    [    R1     ]           [    R1     ]   |
0x48    [    R0     ] New SP    [    RO     ] --+
0x44                            [    R11    ] --+
0x40                            [    R10    ]   |
0x3C                            [    R9     ]   |
0x38                            [    R8     ]   |
0x34                            [    R7     ]   |-> Additional State Context
0x30                            [    R6     ]   |
0x2C                            [    R5     ]   |
0x28                            [    R4     ]   |
                                [ Reserved  ]   |
                                [ Integ Sig ] --+  New SP
```

### `EXC_RETURN` Register

```
 31 .. 24 23      ..      7 6   5    4    3     2    1    0
+--------+-----------------+-+----+-----+----+-----+----+--+
|  0xFF  |     RESERVED    |S|DCRS|FType|Mode|SPSel|RSVD|ES|
````

- **S[6]**:
  - 0 = NS stack used
  - 1 = S stack used
  - Used with the `mode` bit + `CONTROL.SPSEL` to determine which of the four
    stack pointers is used to unstack the register state.
- **FType[4]**: 
  - 1 = Standard (integer-only) stack frame
  - 0 = Extended (floating-point) stack frame
- **Mode [3]**:
  - 0 = Handler mode (return to)
  - 1 = Thread mode (return to)
- **SPSel[2]**
  - 0 = Exception frame resides on main stack pointer
  - 1 = Exception frame resides on process stack pointer.
- **ES[0]**
  - 0 = Exception taken to NS domain
  - 1 = Exception taken to S domain

## Standard Exceptions

For the ARMv8-M, the initial 15 vector table entries are described in
[Arm Cortex-M33 Devices Generic User Guide: Vector Table](https://developer.arm.com/documentation/100235/0002/the-cortex-m33-processor/exception-model/vector-table), and shown below:

> NOTE: ARMv8-M processors generally include ARM TrustZone, where both
  Secure (S) and Non-Secure (NS) processing environments exist, and a
  vector table will be present for each processing environment.

![ARMv8-M vector table](img/armv8m_vectortable.svg "ARMv8-M vector table")

### Reset (1)

Invoked on power-up or a warm reset.

When the processor starts, execution restarts fro mthe address that is
provided by the reset entry in the vector table.

### NMI (2)

Non-maskable interrupt.

Signaled by peripheral or triggered in SW. Highest priority interrupt other
than reset. Always enabled.

### HardFault (3)

Occurs due to an error in exception handling, or because of an exception can't
be handled by other exception mechanisms.

A security violation is a non-secure NMI handler would trigger a secure
HardFault exception.

### MemManage (4)

Memory protection related fault. Determined by the MPU or fixed memory
protection constraints.

Accessing **Execute Never (XN)** memory regions will trigger this.

### BusFault (5)

Memory related fault for an instruction or data memory transaction.

### UsageFault (6)

Instruction execution fault:

- Undefined instruction
- Illegal unaligned access
- Invalid state on instruction execution
- Errorn on exception return

The core can be configured to report:

- Unaligned address on word/half-word
- Division by zero

### SecureFault(7)

Triggered by various security checks whth the Main Extension, for example
jumping from NS code to a S code address.

This is normally terminal, and will halt or restart the system.

### SVCall (11)

Supervisor Call (SVC) triggered by the `SVC` instruction.

Often used in RTOSes for kernel access, etc.

### PendSV (14)

In an RTOS can be used for context switching when no other exception is active.

### SysTick (15)

Generated by the system timer when it reaches zero.