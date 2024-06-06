# (C bindings for) D3D12 Memory Allocator

_**NOTE**: These are bindings for [D3D12 Memory Allocator](https://github.com/GPUOpen-LibrariesAndSDKs/D3D12MemoryAllocator)
developed by Advanced Micro Devices, Inc. I do not own D3D12 Memory Allocator
in any way. Its documentation mentions that D3D12 Memory Allocator is a C++
library and so it should remain, but bindings or ports to any other programming
languages are welcome as external projects. Hence this effort._

_**NOTE2**: This `README.md` file does not provide any documentation for D3D12
Memory Allocator itself. Refer to [the documentation](https://gpuopen-librariesandsdks.github.io/D3D12MemoryAllocator/html/).
However, it does explain how the bindings relate to the original project._

_**NOTE3**: The codebase introduces some concepts found in MIT licensed
[The RAD Debugger Project](https://github.com/EpicGamesExt/raddebugger), such
as context cracking._

Bindings are for **Version 2.1.0-development (2024-07-05)**!

This repository aims to provide C bindings for D3D12 Memory Allocator. At the
moment, the bindings are completely handcrafted, but I am considering
generating them from _the_ source.

Due to the nature of these bindings, it is possible to use them _instead of_
the original library.

## Repository tour

### Concept

_The_ bindings _mimic_ how Microsoft exposes C bindings for their C++ interfaces.
_Mimic_ because in fact, D3D12 Memory Allocator itself does not implement an
interface, sort of. It does implement `IUnknown` interface, but then, it
simply defines datatypes that inherit from `IUnknownImpl` (Aforementioned
`IUnknown` implementation), but derived datatypes are not interfaces that are
then internally implemented. Therefore, in these bindings, there is no concept
of virtual table and such, because `D3D12MA::Allocator` and related datatypes
have little to do with this concept.

Procedures are done in `COBJMACROS`-style, allowing you to write, for example:
```c
D3D12MAAllocator_GetBudget(pSelf, pLocalBudget, pNonLocalBudget)
```
Which should look familiar to those of you acquainted with Microsoft-provided
codebases.

The style or appearance of the API is similar to what is commonly known from C
APIs for many Windows libraries. Naturally, most functions and data types are
not prefixed with `I`, as these are not interfaces. Nevertheless, it should
remain consistent. Below are examples of typical mappings:
- `D3D12MA::ALLOCATOR_DESC` → `D3D12MA_ALLOCATOR_DESC`
- `D3D12MA::Allocator` → `D3D12MAAllocator`
- `const D3D12_FEATURE_DATA_D3D12_OPTIONS &options = allocator->GetD3D12Options()` → `const D3D12_FEATURE_DATA_D3D12_OPTIONS *options = D3D12MAAllocator_GetD3D12Options(allocator)`

### Top-level directories

- `data/third_party/d3d12`: Small binary files which are used when building,
  either to embed within build artifacts, or to package with them. Here
  specifically: `d3d12`, which contains Agility SDK binaries.
- `code`: All source code.
  - `d3d12ma`: Bindings to D3D12 Memory Allocator.
  - `samples`: Basic samples that initialise the allocator and query for data
    that a properly initialised allocator _should_ provide. I might want to
    extend it in the future, so that this contains more sophisticated samples.
    _The_ samples encompass both C and C++ code cases.
  - `third_party/d3d12`: Third party libraries, but at this moment and here
    specifically: Agility SDK headers.

After setting up the codebase and building, the following directories will
also exist:

- `build`: All build artifacts. Not checked in to version control.
- `local`: Local files, used for local build configuration input files.
  At this very moment, this directory is completetly obsolete.

### C integration

To use this library in any C codebase, create a file `d3d12ma_main.cpp`, which
should look like this:
```c
#include "d3d12ma.h"

#include "d3d12ma.cpp"
```
The library is written as a direct source-include. Since D3D12 Memory Allocator
is originally a C++ library, the compilation unit must compile _the_ code in
C++ mode. The resulting OBJ file must then be linked against your executable.
For single compilation unit builds, including `d3d12ma.h` once is sufficient.
In the case of multiple compilation unit builds, `d3d12ma.h` must be included
wherever necessary. Of course, the compiled OBJ with the implementation must be
linked wherever required. For single compilation unit builds, linking against
the main executable is sufficient.

Originally, D3D12 Memory Allocator can be configured by defining appropriate
options, e.g. `D3D12MA_SORT`, before including the implementation. Since
`d3d12ma.cpp` contains the entire original implementation of D3D12 Memory
Allocator in itself, as its files have been inlined, configuring D3D12 Memory
Allocator is as simple as this (returning to the `d3d12ma_main.cpp` file):
```c
#include "d3d12ma.h"

#define D3D12MA_SORT(beg, end, cmp) your_desired_sort_func(beg, end, cmp)
#include "d3d12ma.cpp"
```
Remember that extra care has to be taken if you intend to use these build
options in a multiple unit build.

Finally, it is possible to use this library with Agility SDK (again, back to
`d3d12ma_main.cpp` file):
```c
#include "path/to/d3d12.h"

extern UINT D3D12SDKVersion = 613;
extern char *D3D12SDKPath = u8".\\path\\to\\d3d12\\binaries";

#include "d3d12ma.h"

#define D3D12MA_D3D12_HEADERS_ALREADY_INCLUDED
#include "d3d12ma.cpp"
```
Examples can be found in `code/samples/simple` and
`code/samples/simple_agility_sdk`.

### C++ integration

You might actaully want to read 'C integration' section, as is supplies some
important information w.r.t. usage. For C++ codebases, the process is simpler.
As mentioned, the library is set up as a direct source-include library. For a
single unit build, you can include `d3d12ma.h` and `d3d12ma.cpp`. For a
multiple unit build, you can include `d3d12ma.h` where necessary and add
`d3d12ma.cpp` as a separate compilation unit. Remember, extra care!

Examples can be found in `code/samples/simple_cpp` and
`code/samples/simple_cpp_agility_sdk`.
