# Compilation

The C compilation process generally consists of the following stages:

- **Preprocessing**: Expansion of header files and preprocessor macros
- **Compilation**: Preprocessed C to ASM (.s)
- **Assembly**: ASM to machine code object files (.o)
- **Linking**: Links individual object files into single binary executable

## Compilation in individual steps with GCC

Assuming the following file available as `src/hello_world.c`:

```C
#include <stdio.h>

#define MSG "Hello, World!\n"

int main(int argc, char* argv[])
{
    printf("%s", MSG);

    return 0;
}
```

### Preprocessing phase

This following code will show the preprocesser output for our C source file:
```bash
$ arm-none-eabi-gcc -E -P src/hello_world.c
```

- `-E` tells GCC to stop after preprocessing
- `-P` omits debug output for improved readability

### Compilation phase

The following command will run the preprocessor, and generate an ASM output
file named `hello_world.s`, with **ARMv7-M** as a target architecture.

> We indicate the target architecture here since the default architecture
  for `arm-none-eabi-gcc` 9.3.1 is `arm7tdmi`

```bash
$ arm-none-eabi-gcc -march=armv7-m -S src/hello_world.c
````

The `-S` flag tells the compiler to stop after generating the ASM code.

This will result in the following output:
```arm
        .arch armv7-m
        .eabi_attribute 20, 1
        .eabi_attribute 21, 1
        .eabi_attribute 23, 3
        .eabi_attribute 24, 1
        .eabi_attribute 25, 1
        .eabi_attribute 26, 1
        .eabi_attribute 30, 6
        .eabi_attribute 34, 1
        .eabi_attribute 18, 4
        .file   "hello_world.c"
        .text
        .section        .rodata
        .align  2
.LC0:
        .ascii  "Hello, World!\000"
        .text
        .align  1
        .global main
        .syntax unified
        .thumb
        .thumb_func
        .fpu softvfp
        .type   main, %function
main:
        @ args = 0, pretend = 0, frame = 8
        @ frame_needed = 1, uses_anonymous_args = 0
        push    {r7, lr}
        sub     sp, sp, #8
        add     r7, sp, #0
        str     r0, [r7, #4]
        str     r1, [r7]
        ldr     r0, .L3
        bl      puts
        movs    r3, #0
        mov     r0, r3
        adds    r7, r7, #8
        mov     sp, r7
        @ sp needed
        pop     {r7, pc}
.L4:
        .align  2
.L3:
        .word   .LC0
        .size   main, .-main
```

> Note that GCC has optimised the `printf` call to use `puts` instead, and that
  the location of our `Hello, World!\n` string is loaded into `r0` via `.L3`.

### Assembly phase

The following command will generate machine code (`hello_world.o`) from the
src file:

```bash
$ arm-none-eabi-gcc -march=armv7-m -c src/hello_world.c
```

You can verify the output using the `file` command:

```bash
$ file hello_world.o
hello_world.o: ELF 32-bit LSB relocatable, ARM, EABI5 version 1 (SYSV), not stripped
```

Of note is that this file is marked as `relocatable`, meaning that any
addresses used in this code can be moved around without breaking any
assumptions in the code.

### Linking phase

```bash
$ arm-none-eabi-gcc -march=armv7-m --specs=nosys.specs src/hello_world.c
$ file a.out
```

The `--specs=nosys.specs` flag enables semihosting, which enables an ARM target
to use the IO facilities (`printf`, etc.) on a host computer with a debugger.
Without this additional flag, the call to printf won't resolve to a matching
function during the compilation process.

```bash
$ file a.out
a.out: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, not stripped
```

Notice the `LSB executable` and `statically linked` fields.

Statically linked means that this executable has no external dependencies. If
it did, it would be `dynamically linked`, which is often the case for classic
desktop applications which depend on external libraries.

#### Symbol Analysis (stripped/non-stripped executables)

Since this executable is also `not stripped` (the `-s` flag wasn't added),
symbolic information is available, we means can run the following command:

```bash
$ arm-none-eabi-readelf --syms a.out | grep main
   281: 00008089     0 FUNC    GLOBAL DEFAULT    2 _mainCRTStartup
   315: 000080fd    32 FUNC    GLOBAL DEFAULT    2 main
```

This shows us that `main` is located at address 0x000080FD, and is 32-byte long
function.

To generate a `stripped` binary, we would add the `-s` flag, as follows,
which means the entire symbols table read by `readelf` won't be available:

```bash
$ arm-none-eabi-gcc -march=armv7-m --specs=nosys.specs -s src/hello_world.c -o a.out.stripped
$ file a.out.stripped
a.out: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, stripped
$ arm-none-eabi-readelf --syms a.out.stripped
```
