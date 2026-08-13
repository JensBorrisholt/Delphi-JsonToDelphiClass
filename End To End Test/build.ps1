$ErrorActionPreference = 'Stop'

$projectDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$compiler = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe'
$outputDirectory = Join-Path $projectDirectory 'build\bin'
$dcuDirectory = Join-Path $projectDirectory 'build\dcu'
$searchPath = '..\Components;..\Generator LIB\Core;..\Generator LIB\Delphi;..\Generator LIB\CSharp;..\Runtime'

New-Item -ItemType Directory -Force -Path $outputDirectory, $dcuDirectory |
  Out-Null

Push-Location $projectDirectory
try {
  & $compiler -B -Q "-U$searchPath" "-I$searchPath" "-E$outputDirectory" `
    "-N0$dcuDirectory" '-NSSystem;Winapi;System.Win;Vcl;Fmx' `
    '.\EndToEndTest.dpr'
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}
