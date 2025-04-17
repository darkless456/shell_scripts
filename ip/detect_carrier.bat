@echo off
setlocal enabledelayedexpansion

REM 获取公网IP地址
for /f "delims=" %%i in ('powershell -c "(Invoke-WebRequest -Uri 'https://api.ipify.org' -TimeoutSec 5).Content.Trim()"') do set "ip=%%i"
if "%ip%"=="" (
    echo 无法获取IP地址
    exit /b 1
)

REM 使用国内接口查询运营商（GBK编码）
for /f "tokens=*" %%o in ('powershell -c "$response = Invoke-WebRequest -Uri 'http://whois.pconline.com.cn/ipJson.jsp?ip=%ip%' -TimeoutSec 5; $gbk = [System.Text.Encoding]::GetEncoding('GBK'); $json = $gbk.GetString($response.Content); ($json | ConvertFrom-Json).addr.split()[-1]"') do set "operator=%%o"

REM 判断运营商并显示结果
if "%operator%"=="电信" (
    echo 中国电信
) else if "%operator%"=="移动" (
    echo 中国移动
) else if "%operator%"=="联通" (
    echo 中国联通
) else (
    echo 其他运营商
)

REM 国际接口方案（替换查询部分）
@REM for /f "tokens=*" %%o in ('powershell -c "(Invoke-RestMethod -Uri 'http://ip-api.com/json/%ip%?fields=org').org"') do set "operator=%%o"

@REM if not "%operator:Mobile=%"=="%operator%" (
@REM     echo 中国移动
@REM ) else if not "%operator:Telecom=%"=="%operator%" (
@REM     echo 中国电信
@REM ) else if not "%operator:Unicom=%"=="%operator%" (
@REM     echo 中国联通
@REM ) else (
@REM     echo 其他运营商
@REM )

endlocal

