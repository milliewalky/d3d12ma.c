@echo off
setlocal
cd /D "%~dp0"

:: ~~ prep dirs ~~

if not exist build mkdir build
if not exist local mkdir local

:: ~~ here: d3d12 agility sdk ~~

xcopy /y /q /s /e /i data build

:: ~~ build ~~

pushd build
call cl /Od /I..\code\ /I..\local\ /nologo /FC /Z7 ..\code\samples\simple\simple_main.c                                   ..\code\samples\simple\simple_d3d12ma_main.cpp                         /link /MANIFEST:EMBED /INCREMENTAL:NO /out:simple.exe                 || exit /b 1
call cl /Od /I..\code\ /I..\local\ /nologo /FC /Z7 ..\code\samples\simple_agility_sdk\simple_agility_sdk_main.c           ..\code\samples\simple_agility_sdk\simple_agility_sdk_d3d12ma_main.cpp /link /MANIFEST:EMBED /INCREMENTAL:NO /out:simple_agility_sdk.exe     || exit /b 1
call cl /Od /I..\code\ /I..\local\ /nologo /FC /Z7 ..\code\samples\simple_cpp\simple_cpp_main.cpp                                                                                                /link /MANIFEST:EMBED /INCREMENTAL:NO /out:simple_cpp.exe             || exit /b 1
call cl /Od /I..\code\ /I..\local\ /nologo /FC /Z7 ..\code\samples\simple_cpp_agility_sdk\simple_cpp_agility_sdk_main.cpp                                                                        /link /MANIFEST:EMBED /INCREMENTAL:NO /out:simple_cpp_agility_sdk.exe || exit /b 1
popd
