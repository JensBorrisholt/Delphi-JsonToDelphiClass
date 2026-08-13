$ErrorActionPreference = 'Stop'

$testDirectory = $PSScriptRoot
$refactoredDirectory = Split-Path $testDirectory -Parent
$libraryDirectory = Join-Path $refactoredDirectory 'Runtime'
$dunitXDirectory = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\source\DunitX'
$compiler = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe'
$dcuDirectory = Join-Path $testDirectory 'build\dcu'
$binaryDirectory = Join-Path $testDirectory 'build\bin'

New-Item -ItemType Directory -Force -Path $dcuDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $binaryDirectory | Out-Null

Push-Location $testDirectory
try {
  & $compiler -B -Q -DCI `
    "-U$libraryDirectory;$dunitXDirectory" `
    "-I$libraryDirectory;$dunitXDirectory" `
    "-N0$dcuDirectory" "-E$binaryDirectory" `
    'JsonToDelphiClassTests.dpr'
  if ($LASTEXITCODE -ne 0) {
    throw "Unit test compilation failed with exit code $LASTEXITCODE"
  }

  & (Join-Path $binaryDirectory 'JsonToDelphiClassTests.exe')
  if ($LASTEXITCODE -ne 0) {
    throw "Unit tests failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
