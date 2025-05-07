@echo off

setlocal EnableExtensions enableDelayedExpansion

if not exist deps mkdir deps

pushd deps
set zstd_version=v1.5.7
set zstd_filename=zstd-%zstd_version%-win64.zip
set zstd_url=https://github.com/facebook/zstd/releases/download/%zstd_version%/%zstd_filename%
if not exist zstd (
    powershell Invoke-WebRequest -Uri %zstd_url% -OutFile %zstd_filename%
    if %errorlevel% neq 0 goto :End

    powershell Expand-Archive -Force -Path %zstd_filename% -DestinationPath zstd
    del /F %zstd_filename%
)

if not exist zlib (
    git clone https://github.com/madler/zlib.git
    cd zlib
    git checkout master
    nmake -f win32/Makefile.msc

    if %errorlevel% neq 0 goto :End
)
popd 

if not exist build mkdir build
pushd build

cmake .. -DCURL_USE_OPENSSL=0 -DCURL_USE_SCHANNEL=1 -DZstd_LIBRARY=../../deps/zstd/static/libzstd_static.lib -DZstd_INCLUDE_DIR=../deps/zstd/include -DBUILD_STATIC_CURL=1 -DBUILD_SHARED_LIBS=0 -A x64 -DSIZEOF_CURL_OFF_T=8 -DCURL_ZSTD=1 -DCURL_ZLIB=1 -DZLIB_LIBRARY=../../deps/zlib/zlib.lib -DZLIB_INCLUDE_DIR=../deps/zlib -DCMAKE_INSTALL_PREFIX=../dist
if %errorlevel% neq 0 goto :End

cmake --build . --config Release --target INSTALL
if %errorlevel% neq 0 goto :End
popd

explorer dist

:End
endlocal
