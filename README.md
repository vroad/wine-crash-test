# Wine Crash Test

This repository shows how `wine64` can crash inside a Nix development shell.

## Reproducing the crash

Running the command below attempts to start a Windows command prompt but immediately fails with a segmentation fault:

```bash
nix develop -c wine64 cmd
```

The crash only occurs when the development shell is **impure** (use `--impure`).

```
Segmentation fault (core dumped)
```

Depending on which environment variables are set before running `nix develop`, the failure may also not appear.
I could not reproduce the issue in a pure shell created with `nix develop -i`.

## Environment variables related issue?

My environment variables dumped with `nix develop -c bash -c 'declare -px > env.sh`: https://gist.github.com/vroad/6e668513430025f9c376e63840ab1772

In my case, removing variables that contains long values fixes the issue, but I have no idea why. For example, I could not reproduce the issue with the commands that

```bash
L=20000; for i in {1..30}; do export VAR$i="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c $L)"; done
```

## Inspecting the dump with `coredumpctl`

Systemd stores a core dump that can be listed with:

```bash
coredumpctl --since '1 minutes ago'
```

Example output:

```
TIME                           PID  UID GID SIG     COREFILE EXE                                                                           SIZE
Fri 2025-07-25 18:21:37 JST 195556 1000 100 SIGSEGV present  /nix/store/plf20lkzn7xhbq92n2qxb3p7r7pjivym-wine64-10.0/bin/wine64-preloader 26.3K
```

More details about a particular dump can be retrieved with:

```bash
coredumpctl info 195556
```

Which prints information including a stack trace similar to:

```
           PID: 195166 (.wine64)
           UID: 1000 (nixos)
           GID: 100 (users)
        Signal: 11 (SEGV)
     Timestamp: Fri 2025-07-25 18:18:50 JST (34s ago)
  Command Line: /nix/store/plf20lkzn7xhbq92n2qxb3p7r7pjivym-wine64-10.0/bin/.wine64 cmd
    Executable: /nix/store/plf20lkzn7xhbq92n2qxb3p7r7pjivym-wine64-10.0/bin/wine64-preloader
 Control Group: /user.slice/user-1000.slice/user@1000.service/app.slice/app-org.kde.konsole@58166e96f84e44d3a9cf9b573621dc19.service
          Unit: user@1000.service
     User Unit: app-org.kde.konsole@58166e96f84e44d3a9cf9b573621dc19.service
         Slice: user-1000.slice
     Owner UID: 1000 (nixos)
       Boot ID: d0bc8e1cf0404e86ae97ae7a41772455
    Machine ID: 6e0bd192dca84d80a071c75e4c331bc0
      Hostname: b550i
       Storage: /var/lib/systemd/coredump/core.\x2ewine64.1000.d0bc8e1cf0404e86ae97ae7a41772455.195166.1753435130000000.zst (present)
  Size on Disk: 26.3K
       Message: Process 195166 (.wine64) of user 1000 dumped core.
                
                Module /nix/store/plf20lkzn7xhbq92n2qxb3p7r7pjivym-wine64-10.0/bin/.wine64 without build-id.
                Stack trace of thread 195166:
                #0  0x00007ffff7fbdda2 open_verify.constprop.0 (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x4da2)
                #1  0x00007ffff7fbe150 open_path (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x5150)
                #2  0x00007ffff7fc163b _dl_map_object (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x863b)
                #3  0x00007ffff7fbb8f5 openaux (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x28f5)
                #4  0x00007ffff7fba4f1 _dl_catch_exception (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x14f1)
                #5  0x00007ffff7fbbd85 _dl_map_object_deps (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x2d85)
                #6  0x00007ffff7fd9749 dl_main (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x20749)
                #7  0x00007ffff7fd6123 _dl_sysdep_start (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x1d123)
                #8  0x00007ffff7fd7b22 _dl_start (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x1eb22)
                #9  0x00007ffff7fd6788 _start (/nix/store/zdpby3l6azi78sl83cpad2qjpfj25aqx-glibc-2.40-66/lib/ld-linux-x86-64.so.2 + 0x1d788)
                ELF object binary architecture: AMD x86-64

```
