# Welcome to the LorielleOS mod

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


```lua
wget https://raw.githubusercontent.com/Shaunythunder/LorielleOS-Mod/refs/heads/disc_imager_start/bootstrap.lua /tmp/bootstrap.lua
lua /tmp/bootstrap.lua