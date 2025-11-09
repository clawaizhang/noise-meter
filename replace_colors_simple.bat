@echo off
setlocal enabledelayedexpansion

echo Starting system colors replacement...

REM 递归查找所有.ets文件
set /a fileCount=0
for /r %%f in (*.ets) do (
    set /a fileCount+=1
    echo Processing %%f...
    
    REM 临时文件
    set "tempFile=%%f.tmp"
    
    REM 逐行读取并替换
    for /f "useback tokens=1,2 delims=" %%a in (%%f) do (
        set "line=%%a"
        for /f "tokens=1,2 delims==" %%b in ("!line!") do (
            set "sysColor=%%b"
            set "appColor=%%c"
            set "line=!line:$sysColor=$appColor!"
        )
        
        REM 写入临时文件
        echo.!line!>>"!tempFile!"
    )
    
    REM 替换原文件
    move "!tempFile!" "%%f"
)

echo Processed !fileCount! .ets files
echo System colors replacement completed!
pause