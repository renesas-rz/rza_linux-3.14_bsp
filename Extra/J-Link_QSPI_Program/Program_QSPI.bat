@echo off

rem <> J-Link Verison 4.88b
set BASE=C:\Program Files (x86)\SEGGER\JLink_V488b
if exist "%BASE%\JLink.exe" goto PATH_SET

rem <> J-Link Verison 4.85e
set BASE=C:\Program Files (x86)\SEGGER\JLinkARM_V485e
if exist "%BASE%\JLink.exe" goto PATH_SET

rem <> J-Link Verison 4.84c
set BASE=C:\Program Files (x86)\SEGGER\JLinkARM_V48c
if exist "%BASE%\JLink.exe" goto PATH_SET

echo ===================================================================
echo ERROR: You need to set the path for JLink.exe 
echo ===================================================================
pause
exit
:PATH_SET


echo .
echo ------------------------------------------------------------------------
echo .
:OPTIONS
echo OPTIONS
echo 1 = Program u-boot
echo 2 = Program Device Tree Blob
echo 3 = Program Kernel (uImage)
echo 4 = Program Kernel (xipImage)
echo 5 = Program Rootfs
echo 9 = Exit
SET /P REPLY=Choose option: 
if "%REPLY%"== "1" (goto PROGRAM)
if "%REPLY%"== "2" (goto PROGRAM)
if "%REPLY%"== "3" (goto PROGRAM)
if "%REPLY%"== "4" (goto PROGRAM)
if "%REPLY%"== "5" (goto PROGRAM)
if "%REPLY%"== "9" (exit)
echo ERROR: Please select from the list only.
goto OPTIONS

:PROGRAM
echo.
echo.
echo Remove power (5V) to the board before continuing. 
echo Set SW6 as instructed below:
echo SW6-1 OFF, SW6-2 ON, SW6-3 OFF, SW6-4 ON, SW6-5 ON, SW6-6 ON
echo.
echo.      ON
echo.    +-------------+
echo.    ^|   -   - - - ^|
echo.    ^| -   -       ^|
echo.    +-------------+
echo.      1 2 3 4 5 6 
echo.
echo Reconnect power (5V) to the board before continuing. 
pause

echo ------------------------------------------------------------------------

if "%REPLY%"== "1" GOTO UBOOT
if "%REPLY%"== "2" GOTO DTB
if "%REPLY%"== "3" GOTO KERNEL_UIMAGE
if "%REPLY%"== "4" GOTO KERNEL_XIP
if "%REPLY%"== "5" GOTO ROOTFS
GOTO PROG_DONE

@REM =====u-boot========
:UBOOT
"%BASE%\JLink.exe" -speed 12000 -if JTAG -device R7S721001 -CommanderScript load_spi_uboot.txt
GOTO PROG_DONE

@REM =====Device Tree Blob========
:DTB
"%BASE%\JLink.exe" -speed 12000 -if JTAG -device R7S721001 -CommanderScript load_spi_dtb.txt
GOTO PROG_DONE

@REM =====Kernel (uImage)========
:KERNEL_UIMAGE
"%BASE%\JLink.exe" -speed 12000 -if JTAG -device R7S721001_DualSPI -CommanderScript load_spi_kernel_uImage.txt
GOTO PROG_DONE

@REM =====Kernel (xipImage)========
:KERNEL_XIP
"%BASE%\JLink.exe" -speed 12000 -if JTAG -device R7S721001_DualSPI -CommanderScript load_spi_kernel_xipImage.txt
GOTO PROG_DONE

@REM =====Rootfs========
:ROOTFS
"%BASE%\JLink.exe" -speed 12000 -if JTAG -device R7S721001_DualSPI -CommanderScript load_spi_rootfs.txt
GOTO PROG_DONE

:PROG_DONE

echo ------------------------------------------------------------------------

pause
echo.
echo.
echo. NOTE:
echo.       When you are done programming, have to remove power from the board for 5 seconds
echo.       in order to be able to boot from QSPI again.
echo.
echo.
echo.
goto END


:END
pause
