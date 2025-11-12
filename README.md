# MuseScore 3.6.2 Headless Mode Wrapper
Install MuseScore 3.6.2 on an Ubuntu server and run it in headless mode.  
Tested on:
* Ubuntu 22.04.4 LTS

<br>

## Quick Start
```bash
git clone https://github.com/halsoo/musescore-3.6.2-headless.git
cd musescore-3.6.2-headless
./install_musescore-3.6.2.sh
```

### What is happening under the hood?
1. Installs the following dependencies:
    ```
    xvfb
    libnss3-dev libegl1-mesa-dev libglu1-mesa-dev
    freeglut3-dev mesa-common-dev libjack-jackd2-dev
    libxss1 libgconf-2-4 libxtst6 libxrandr2 
    libasound2-dev libxss1 libgconf-2-4
    ```
1. Downloads [MuseScore 3.6.2 AppImage](https://github.com/musescore/MuseScore/releases/download/v3.6.2/MuseScore-3.6.2.548021370-x86_64.AppImage)
1. Extracts the downloaded AppImage to `$HOME/mscore-3.6.2/`
1. Tests the extracted AppImage
1. Copies `wrapper_command.sh` to `/usr/local/bin/musescore` and `/usr/local/bin/mscore`
1. Tests the copied commands

<br>

## How to uninstall
```bash
cd musescore-3.6.2-headless
./uninstall_musescore-3.6.2.sh
```