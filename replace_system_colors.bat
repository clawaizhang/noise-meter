@echo off
setlocal enabledelayedexpansion

echo Starting system colors replacement...

REM 定义system color到APP color的映射
set "mapping[sys.color.background_primary]=app.color.background_primary"
set "mapping[sys.color.background_secondary]=app.color.background_secondary"
set "mapping[sys.color.brand]=app.color.brand_primary"
set "mapping[sys.color.font_primary]=app.color.content_primary"
set "mapping[sys.color.font_secondary]=app.color.content_secondary"
set "mapping[sys.color.font_tertiary]=app.color.content_tertiary"
set "mapping[sys.color.font_emphasize]=app.color.font_emphasize"
set "mapping[sys.color.comp_background_primary]=app.color.comp_background_primary"
set "mapping[sys.color.comp_background_secondary]=app.color.comp_background_secondary"
set "mapping[sys.color.comp_background_tertiary]=app.color.comp_background_tertiary"
set "mapping[sys.color.comp_background_emphasize]=app.color.comp_background_emphasize"
set "mapping[sys.color.confirm]=app.color.success"
set "mapping[sys.color.warning]=app.color.warning"
set "mapping[sys.color.alert]=app.color.feedback_warning"
set "mapping[sys.color.icon_primary]=app.color.icon_primary"
set "mapping[sys.color.icon_secondary]=app.color.icon_secondary"
set "mapping[sys.color.icon_emphasize]=app.color.font_emphasize"
set "mapping[sys.color.interactive_active]=app.color.interactive_active"
set "mapping[sys.color.font_on_primary]=app.color.content_on_primary"
set "mapping[sys.color.font_on_secondary]=app.color.content_on_secondary"
set "mapping[sys.color.font_on_tertiary]=app.color.content_on_tertiary"
set "mapping[sys.color.comp_divider]=app.color.comp_divider"
set "mapping[sys.color.black]=app.color.black"
set "mapping[sys.color.transparent]=app.color.transparent"
set "mapping[sys.color.ohos_id_color_palette2]=app.color.ohos_id_color_palette2"
set "mapping[sys.color.ohos_id_color_palette3]=app.color.ohos_id_color_palette3"
set "mapping[sys.color.ohos_id_color_palette4]=app.color.ohos_id_color_palette4"
set "mapping[sys.color.ohos_id_color_palette5]=app.color.ohos_id_color_palette5"
set "mapping[sys.color.ohos_id_color_text_secondary]=app.color.ohos_id_color_text_secondary"
set "mapping[sys.color.recommended_hover]=app.color.recommended_hover"
set "mapping[sys.color.advanced_hover]=app.color.advanced_hover"

REM 递归查找所有.ets文件
set /a fileCount=0
for /r %%f in ("..\entry\src\main\ets\**\*.ets") do (
    set /a fileCount+=1
    echo Processing %%f...
    
    REM 临时文件
    set "tempFile=%%f.tmp"
    
    REM 逐行读取并替换
    for /f "useback tokens=1,2 delims=" %%a in (%%f) do (
        set "line=%%a"
        for /f "tokens=1,2 delims==" %%b in ("!mapping!") do (
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