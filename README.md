# (C bindings for) D3D12 Memory Allocator

Bindings are for **Version 2.1.0-development (2024-07-05)**!

This repository aims to provide C bindings for D3D12 Memory Allocator. At the
moment, the bindings are completely handcrafted, but I am considering
generating them from _the_ source.

Due to the nature of these bindings, it is possible to use them _instead of_
the original library.

## Repository tour

### Concept

_The_ bindings _mimic_ how Microsoft exposes C bindings for their C++ interfaces.
_Mimic_ because in fact, D3D12 Memory Allocator itself does not implement a
D3D12-Memory-Allocator-or-such interface, sort of. It does implement `IUnknown`
interface, but then, it simply defines datatypes that inherit from
`IUnknownImpl` (Aforementioned `IUnknown` implementation), but derived
datatypes are not interfaces that are then internally implemented. Therefore,
in these bindings, there is no concept of virtual table and such, because
`D3D12MA::Allocator` itself and related datatypes have little to do with this
concept.

Procedures are done in `COBJMACROS`-style, allowing you to write, for example:
```c
D3D12MAAllocator_GetBudget(pSelf, pLocalBudget, pNonLocalBudget)
```
Which should look familiar to those of you acquainted with Microsoft-provided
codebases.

The style or appearance of the API is similar to what is commonly known from C
APIs for many Windows libraries. Naturally, most functions and data types are
not prefixed with `I`, as they are not interfaces. Nevertheless, it should
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

## Example usage

```c
D3D12MA_ALLOCATION_DESC allocation_desc = {0};
{
 allocation_desc.HeapType = D3D12_HEAP_TYPE_DEFAULT;
}
D3D12_RESOURCE_DESC resource_desc = {0};
{
 resource_desc.Dimension          = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
 resource_desc.Alignment          = 0;
 resource_desc.Width              = 1024;
 resource_desc.Height             = 1024;
 resource_desc.DepthOrArraySize   = 1;
 resource_desc.MipLevels          = 1;
 resource_desc.Format             = DXGI_FORMAT_R8G8B8A8_UNORM;
 resource_desc.SampleDesc.Count   = 1;
 resource_desc.SampleDesc.Quality = 0;
 resource_desc.Layout             = D3D12_TEXTURE_LAYOUT_UNKNOWN;
 resource_desc.Flags              = D3D12_RESOURCE_FLAG_NONE;
}
D3D12MAAllocation *allocation = 0;
D3D12Resource *resource = 0;
HRESULT error = D3D12MAAllocator_CreateResource(allocator,
                                                &allocation_desc,
                                                &resource_desc,
                                                D3D12_RESOURCE_STATE_COPY_DEST,
                                                &clear_value,
                                                &allocation,
                                                &IID_ID3D12Resource,
                                                &resource); // NOTE(mwalky): or `(void **)(&resource)`
```

## C integration

### Steps

To use this library in any C codebase, create a file `d3d12ma_main.cpp`, which
should look like this:
```c
// NOTE(mwalky): `d3d12ma_main.cpp`

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
the main executable is sufficient. Assuming single compilation unit build, make
`main.c` file.
```c
// NOTE(mwalky): perhaps `main.c`

#pragma comment(lib, "user32")
#pragma comment(lib, "dxgi")
#pragma comment(lib, "d3d12")

#include "windows.h"
#include "initguid.h" // NOTE(mwalky): for GUIDs

#define COBJMACROS
#include "dxgi1_6.h"
#include "d3d12.h"

#define D3D12MA_D3D12_HEADERS_ALREADY_INCLUDED
#include "d3d12ma/d3d12ma.h"

int
main(void)
{
 return 0;
}
```
And finally, `build.bat` (Assuming that `main.c`, `d3d12ma.h`, `d3d12ma.cpp`
and `d3d12_main.cpp` are in the same directory as `build.bat`).
```batchfile
call cl /Od /I..\ /nologo /FC /Z7 main.c d3d12ma_main.cpp /link /MANIFEST:EMBED /INCREMENTAL:NO /out:main.exe
```
Calling `cl` requires Command Prompt (`cmd`) equipped with MSVC. This can be
achieved by calling `vcvarsall.bat amd64` bundled either with Visual Studio
Build Tools or Visual Studio itself. Provided either Visual Studio Build Tools
or Visual Studio is installed, you might simply want to run
`x64 Native Tools Command Prompt for VS <year>`, which spawns `cmd` with
`vcvarsall.bat amd64` called automatically at its start-up.

Obviously, a build system is a matter of choice. You may use whichever you
prefer, but keep in mind the considerations above regarding single and multiple
compilation unit situations.

### Further notes

Originally, D3D12 Memory Allocator can be configured by defining appropriate
options, e.g. `D3D12MA_SORT`~, before including the implementation~. Since
`d3d12ma.cpp` contains the entire original implementation of D3D12 Memory
Allocator in itself, as its files have been inlined, configuring D3D12 Memory
Allocator is as simple as this (returning to the `d3d12ma_main.cpp` file):
```c
// NOTE(mwalky): `d3d12ma_main.cpp`

#define D3D12MA_SORT(beg, end, cmp) your_desired_sort_func(beg, end, cmp)
#include "d3d12ma.h"

#include "d3d12ma.cpp"
```
Remember that extra care has to be taken if you intend to use these build
options in a multiple unit build.

Finally, it is possible to use this library with Agility SDK (again, back to
`d3d12ma_main.cpp` file):
```c
// NOTE(mwalky): `d3d12ma_main.cpp`

#include "dxgi1_6.h"
#include "path/to/d3d12.h"

extern "C" __declspec(dllexport) extern UINT D3D12SDKVersion = <version_of_d3d12>;
extern "C" __declspec(dllexport) extern PSZ D3D12SDKPath = u8".\\path\\to\\d3d12\\binaries";

#define D3D12MA_D3D12_HEADERS_ALREADY_INCLUDED
#include "d3d12ma.h"

#include "d3d12ma.cpp"
```
Refer to [Getting Started with the Agility SDK](https://devblogs.microsoft.com/directx/gettingstarted-dx12agility)
for more details w.r.t. Agility SDK.

Examples can be found in `code/samples` (`samples_*_main.c` and
`samples_*_d3d12_main.cpp` files).

## C++ integration

You might actaully want to read 'C integration' section, as is supplies some
important information w.r.t. usage. For C++ codebases, the process is simpler.
As mentioned, the library is set up as a direct source-include library. For a
single unit build, you can include `d3d12ma.h` and `d3d12ma.cpp`. For a
multiple unit build, you can include `d3d12ma.h` where necessary and add
`d3d12ma.cpp` as a separate compilation unit. Remember, extra care!

Examples can be found in `code/samples` (`samples_*_main.cpp`, not
`samples_*_d3d12_main.cpp` files!).

## Disclaimers

These are bindings for [D3D12 Memory Allocator](https://github.com/GPUOpen-LibrariesAndSDKs/D3D12MemoryAllocator)
developed by Advanced Micro Devices, Inc. I do not own D3D12 Memory Allocator
in any way. Its documentation mentions that D3D12 Memory Allocator is a C++
library and so it should remain, but bindings or ports to any other programming
languages are welcome as external projects. Hence this effort.

This `README.md` file does not provide any documentation for D3D12
Memory Allocator itself. Refer to [the documentation](https://gpuopen-librariesandsdks.github.io/D3D12MemoryAllocator/html/).
However, it does explain how the bindings relate to the original project.

The codebase introduces some concepts found in MIT licensed
[The RAD Debugger Project](https://github.com/EpicGamesExt/raddebugger), such
as context cracking.
