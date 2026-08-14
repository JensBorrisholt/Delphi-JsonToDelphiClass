$ErrorActionPreference = 'Stop'

$testDirectory = $PSScriptRoot
$componentDirectory = Split-Path $testDirectory -Parent
$repositoryDirectory = Split-Path $componentDirectory -Parent
$compiler = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe'
$dcuDirectory = Join-Path $testDirectory 'build\dcu'
$binaryDirectory = Join-Path $testDirectory 'build\bin'
$unitPaths = @(
  $componentDirectory
  (Join-Path $repositoryDirectory 'Generator LIB\Core')
  (Join-Path $repositoryDirectory 'Generator LIB\Delphi')
  (Join-Path $repositoryDirectory 'Runtime')
) -join ';'

New-Item -ItemType Directory -Force -Path $dcuDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $binaryDirectory | Out-Null

& (Join-Path $componentDirectory 'build-resources.ps1')

Push-Location $testDirectory
try {
  & $compiler -B -Q "-U$unitPaths" "-I$unitPaths" `
    "-N0$dcuDirectory" "-E$binaryDirectory" 'DemoProjectSmokeTest.dpr'
  if ($LASTEXITCODE -ne 0) {
    throw "Demo-project smoke-test compilation failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
