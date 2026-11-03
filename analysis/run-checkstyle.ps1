$ErrorActionPreference = 'Stop'

$analysisDir = $PSScriptRoot
$projectDir = Split-Path $analysisDir -Parent
$checkstyleJar = Join-Path $analysisDir 'checkstyle-14.4.0-all.jar'
$javaExe = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\java.exe' } else { 'java' }

if (-not (Test-Path -LiteralPath $checkstyleJar)) {
    throw "Descarga Checkstyle 14.4.0 y guarda checkstyle-14.4.0-all.jar en $analysisDir"
}

$sourceDir = Join-Path $projectDir 'backend\src'
& $javaExe -jar $checkstyleJar -c /google_checks.xml -f xml `
    -o (Join-Path $analysisDir 'checkstyle-findings.xml') $sourceDir
$xmlExitCode = $LASTEXITCODE

& $javaExe -jar $checkstyleJar -c /google_checks.xml -f plain `
    -o (Join-Path $analysisDir 'checkstyle-findings.txt') $sourceDir
$plainExitCode = $LASTEXITCODE

if ($xmlExitCode -ne 0 -or $plainExitCode -ne 0) {
    throw "Checkstyle terminó con códigos XML=$xmlExitCode y texto=$plainExitCode"
}

Write-Output 'Análisis terminado. Revisa checkstyle-findings.xml y checkstyle-findings.txt.'
