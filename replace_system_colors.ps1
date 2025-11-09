# 定义system color到APP color的映射
$colorMapping = @{
    'sys.color.background_primary' = 'app.color.background_primary'
    'sys.color.background_secondary' = 'app.color.background_secondary'
    'sys.color.brand' = 'app.color.brand_primary'
    'sys.color.font_primary' = 'app.color.content_primary'
    'sys.color.font_secondary' = 'app.color.content_secondary'
    'sys.color.font_tertiary' = 'app.color.content_tertiary'
    'sys.color.font_emphasize' = 'app.color.font_emphasize'
    'sys.color.comp_background_primary' = 'app.color.comp_background_primary'
    'sys.color.comp_background_secondary' = 'app.color.comp_background_secondary'
    'sys.color.comp_background_tertiary' = 'app.color.comp_background_tertiary'
    'sys.color.comp_background_emphasize' = 'app.color.comp_background_emphasize'
    'sys.color.confirm' = 'app.color.success'
    'sys.color.warning' = 'app.color.warning'
    'sys.color.alert' = 'app.color.feedback_warning'
    'sys.color.icon_primary' = 'app.color.icon_primary'
    'sys.color.icon_secondary' = 'app.color.icon_secondary'
    'sys.color.icon_emphasize' = 'app.color.font_emphasize'
    'sys.color.interactive_active' = 'app.color.interactive_active'
    'sys.color.font_on_primary' = 'app.color.content_on_primary'
    'sys.color.font_on_secondary' = 'app.color.content_on_secondary'
    'sys.color.font_on_tertiary' = 'app.color.content_on_tertiary'
    'sys.color.comp_divider' = 'app.color.comp_divider'
    'sys.color.black' = 'app.color.black'
    'sys.color.transparent' = 'app.color.transparent'
    'sys.color.ohos_id_color_palette2' = 'app.color.ohos_id_color_palette2'
    'sys.color.ohos_id_color_palette3' = 'app.color.ohos_id_color_palette3'
    'sys.color.ohos_id_color_palette4' = 'app.color.ohos_id_color_palette4'
    'sys.color.ohos_id_color_palette5' = 'app.color.ohos_id_color_palette5'
    'sys.color.ohos_id_color_text_secondary' = 'app.color.ohos_id_color_text_secondary'
    'sys.color.recommended_hover' = 'app.color.recommended_hover'
    'sys.color.advanced_hover' = 'app.color.advanced_hover'
}

# 递归查找所有.ets文件
function Find-EtsFiles($dir) {
    $files = Get-ChildItem -Path $dir -Recurse -File | Where-Object { $_.Extension -eq ".ets" }
    return $files
}

# 替换文件中的system colors
function Replace-ColorsInFile($filePath) {
    $content = Get-Content -Path $filePath -Raw
    $modified = $false
    
    # 替换每个system color
    $colorMapping.GetEnumerator() | ForEach-Object {
        $sysColor = $_.Key
        $appColor = $_.Value
        $regex = [regex]::Escape($sysColor) + [regex]::Escape('$r(') + [regex]::Escape("') + [regex]::Escape($sysColor) + [regex]::Escape("')")
        
        if ($content -match $regex) {
            $content = $content -replace $regex, "`$r('$appColor')"
            $modified = $true
        }
    }
    
    # 如果有修改，写回文件
    if ($modified) {
        Set-Content -Path $filePath -Value $content -NoNewline
        Write-Host "Updated: $filePath"
    }
}

# 主函数
$etsDir = ".\entry\src\main\ets"
$etsFiles = Find-EtsFiles $etsDir

Write-Host "Found $($etsFiles.Count) .ets files"

$etsFiles | ForEach-Object {
    Replace-ColorsInFile $_.FullName
}

Write-Host "System colors replacement completed!"