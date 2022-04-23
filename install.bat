@echo off

if not exist %WORKING_DIR% mkdir %WORKING_DIR%

::..............................................................................

if /i "%BUILD_PROJECT%" == "llvm" goto :llvm
if /i "%BUILD_PROJECT%" == "clang" goto :clang

echo Invalid argument: '%1'
exit -1

::..............................................................................

:llvm

:: download LLVM sources

if /i "%BUILD_MASTER%" == "true" (
	git clone --depth=1 %LLVM_MASTER_URL% %WORKING_DIR%\llvm-git
	move %WORKING_DIR%\llvm-git\llvm %WORKING_DIR%
) else (
	powershell "Invoke-WebRequest -Uri %LLVM_DOWNLOAD_URL% -OutFile %WORKING_DIR%\%LLVM_DOWNLOAD_FILE%"
	7z x -y %WORKING_DIR%\%LLVM_DOWNLOAD_FILE% -o%WORKING_DIR%
	7z x -y %WORKING_DIR%\llvm-project-%LLVM_VERSION%.src.tar -o%WORKING_DIR%
	move %WORKING_DIR%\llvm-project-%LLVM_VERSION%.src %WORKING_DIR%\llvm-project
	dir %WORKING_DIR%
)

if "%CONFIGURATION%" == "Debug" goto dbg
goto :eof

:: . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

:: on Debug builds:
:: - patch llvm-config/CMakeLists.txt to always build and install llvm-config
:: - patch AddLLVM.cmake to also install PDBs on Debug builds

:dbg

echo set_target_properties(llvm-config PROPERTIES EXCLUDE_FROM_ALL FALSE) >> %WORKING_DIR%\llvm-project\llvm\tools\llvm-config\CMakeLists.txt
echo install(TARGETS llvm-config RUNTIME DESTINATION bin) >> %WORKING_DIR%\llvm-project\llvm\tools\llvm-config\CMakeLists.txt

perl pdb-patch.pl %WORKING_DIR%\llvm-project\llvm\cmake\modules\AddLLVM.cmake

goto :eof

