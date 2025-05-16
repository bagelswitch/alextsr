# alextsr
MS-DOS TSR to set up a hotkey combo to force display mode 03h (co80), while maintaining display memory contents (in the text-mode area B800:0000). 
This is needed on the Bell Alex Telecomputer when using an EGA card, as the included software enters an incompatible display mode on startup (and does not use BIOS interrupt 10h to do so, so this behavior cannot be easily intercepted).
