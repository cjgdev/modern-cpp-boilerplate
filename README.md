# Modern C++14 Boilerplate

## Getting Started

### Requirements

- Cmake >= 2.8.2
- Git
- Python >= 3.0
- Vagrant (Plugins: Omnibus, Cachier)

### Clone the repository:

```bash
git clone --recursive git@github.com:bigdatadev/modern-cpp-boilerplate.git
```

## Example of usage (also see scripts/build.py --help):

Valid configurations:
- Debug          _(-g)_
- Release        _(-O3 -DNDEBUG)_
- RelWithDebInfo _(-O2 -g -DNDEBUG)_
- MinSizeRel     _(-Os -DNDEBUG)_

### Build Debug Makefile project with gcc:

```bash
./scripts/build.py --toolchain gcc --config Debug
```

### Build and test Release Makefile project with gcc:

```bash
./scripts/build.py --toolchain gcc --config Release --test
```

### Static analysis:

```bash
./scripts/build.py --toolchain analyze --config Release --test
```

### Runtime analysis:

```bash
./scripts/build.py --toolchain sanitize-address --config Release --test
```

```bash
./scripts/build.py --toolchain sanitize-leak --config Release --test
```

```bash
./scripts/build.py --toolchain sanitize-memory --config Release --test
```

```bash
./scripts/build.py --toolchain sanitize-thread --config Release --test
```

