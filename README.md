# Orbit
A simple renderer with an embedded Lua runtime.

## Build From Source

### Prerequisites

- C/C++ compiler
- CMake
- Git

First, clone the project, then in the root directory:

```bash
cmake --build build
```

---

The output executable will be in **/build/bin**

## How to use

Three folders need to exist in the same directory of the executable:
- data
- logs
- scripts

There needs to be at least one Lua script file in the `scripts` directory, with both `initFrame()` and `exitFrame()` functions defined.

Lastly, run the executable and see what works and doesn't.