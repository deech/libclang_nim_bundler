import nimscript_utils/programs
import nimscript_utils/cmake
import nimscript_utils/env
import nimscript_utils/github
import os
import strformat

if (not (missingPrograms(@["cmake"]).len == 0)):
  raise newException(Defect, "'cmake' could not be found")

let cmakeFlags* : seq[string] =
  when defined(windows):
    @["-Thost=x64",
      "-G \"Visual Studio 16 2019\"",
      "-A x64", "-DCMAKE_BUILD_TYPE=Release",
      "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=\"AVR\"",
      "-DLLVM_ENABLE_LIBXML2=OFF",
      "-DLLVM_USE_CRT_RELEASE=MT",
      "-DCMAKE_INSTALL_PREFIX=.."
    ]
  else:
    @["-DCMAKE_INSTALL_PREFIX=.."]

let
  libclangDir* = "libclang-static-build"
  rootDir* = os.getTempDir() / "nim" / "third-party"
  includePath* = rootDir / libclangDir / "include"
  libraryPath* = rootDir / libclangDir / "lib"
  libclangStaticBindingsCommit* = "e4a81120fa1e13ed712fcbadca785bef30bde37d"

proc build*() =
  if not ((system.existsFile(rootDir / libclangDir / "lib" / "libclang_bundled.a")) or (system.existsDir (rootDir / libclangDir / "include" / "clang-c"))):
    if (not system.existsDir(rootDir)):
      mkdir rootDir
    let dir = downloadGithubCommit(
                user="deech",
                project=libclangDir,
                commit= libclangStaticBindingsCommit,
                outdir = rootDir,
                overwrite = false,
              )
    if (not system.existsDir(rootDir / libclangDir)):
      mvDir dir,(rootDir / libclangDir)
    runCmake(parent=rootDir / libclangDir, flags=cmakeFlags)
  for e in @["CPATH", "C_INCLUDE_PATH", "CPLUS_INCLUDE_PATH"]:
    pushEnv(e, includePath)

proc macosLibZ3Adjustment*(exec: string) =
  exec(fmt"install_name_tool -change libz3.dylib {libraryPath}/libz3.dylib {exec}")
  exec(fmt"install_name_tool -add_rpath {libraryPath} {exec}")
