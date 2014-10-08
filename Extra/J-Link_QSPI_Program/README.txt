Programs binary images into external SPI Flash devices on an RSKRZA1 board.


<> The u-boot image is only programmed into SPI Flash 0.
<> The Device Tree blob is only programmed into SPI Flash 0.
<> The Kernel is programed into both SPI Flash devices (dual mode).
<> The Root File System image is programed into both SPI Flash devices (dual mode).


NOTE: The file extensions have to be .bin so the SEGGER JLINK programmer knows what it is programming.

