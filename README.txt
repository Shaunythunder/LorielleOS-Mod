# Welcome to the LorielleOS mod (WIP)

This is a modified version of OpenOS 1.8.6 that has been customized for use in Greg Tech New Horizons.

=======USER WARNING======
This operating system has a installation process that wipes the destination hard drive. 
The reason for this is that OpenOS must be installed on a computer before this OS can be installed.
-------END WARNING-------

## Features

**Planned but not yet implemented:**
- Real world timestamping
- Command line history navigation

Features will be added as issues come up.

## Installation Instructions

**Requirements:**
- Internet card
- Disk drive  
- OpenOS floppy

**Steps:**
1. Insert the OpenOS floppy
2. Start the computer
3. Run the following command:
wget https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/refs/heads/main/disk_imager.lua /tmp/disk_imager.lua
    3a. The first command will cause the installer to get wiped whenever you shut off the computer as it is in RAM. If you would like to keep it.
        run the following command.
    3b. wget https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/refs/heads/main/disk_imager.lua disk_imager.lua
    3c. For dev: wget http://localhost:8000/disk_imager.lua /tmp/disk_imager.lua && lua /tmp/disk_imager.lua
4. Type the following commands:
    4a. cd /mnt
    4b. ls
5. Remove your hard drive.
6. Type ls
7. Insert hard drive
8. Type ls. note down which 3 digit address disappeared and reappeared. This is your blank hard drive. You will need this number for the installer.
    8a. If you are using a floppy. Follow steps 4 through 8 but with your floppy disk. 
    8b. You will either need openOS or LorielleOS installed on your computer to do this.
9. Type cd
10. Type /tmp/disk_imager.lua to launch the installer.