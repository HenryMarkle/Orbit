# Orbit
A simple renderer with an embedded Lua runtime.

## Build From Source

### Prerequisites

- C/C++ compiler (W64devkit for Windows)
- CMake
- Git

First, clone the project, then:

### Windows

in **/build**:

```bash
cmake .. -G "MinGW Makefiles"
```

and then:

```bash
mingw32-make
```

### Linux

in the root directory
```bash
cmake --build build
```

---

The output executable will be in **/build/bin**