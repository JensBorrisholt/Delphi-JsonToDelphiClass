$ErrorActionPreference = 'Stop'

$projectDirectory = $PSScriptRoot
$dcuDirectory = Join-Path $projectDirectory 'build\dcu'
$binaryDirectory = Join-Path $projectDirectory 'build\bin'
$libraryDirectory = Join-Path $projectDirectory '..\Lib'
$compiler = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe'

New-Item -ItemType Directory -Force -Path $dcuDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $binaryDirectory | Out-Null

Push-Location $projectDirectory
try {
  & $compiler -B -Q "-U$projectDirectory;$libraryDirectory" "-I$projectDirectory;$libraryDirectory" `
    "-N0$dcuDirectory" "-E$binaryDirectory" 'GeneratorLIBRefactored.dpr'
  if ($LASTEXITCODE -ne 0) {
    throw "Library compilation failed with exit code $LASTEXITCODE"
  }

  Push-Location (Join-Path $projectDirectory 'Tests')
  try {
    & $compiler -B -Q "-U$projectDirectory;$libraryDirectory" "-I$projectDirectory;$libraryDirectory" `
      "-N0$dcuDirectory" "-E$binaryDirectory" 'GeneratorSmokeTests.dpr'
    if ($LASTEXITCODE -ne 0) {
      throw "Test compilation failed with exit code $LASTEXITCODE"
    }

    & $compiler -B -Q "-U$projectDirectory;$libraryDirectory" "-I$projectDirectory;$libraryDirectory" `
      "-N0$dcuDirectory" "-E$binaryDirectory" 'LegacyCompatibilityTests.dpr'
    if ($LASTEXITCODE -ne 0) {
      throw "Compatibility test compilation failed with exit code $LASTEXITCODE"
    }
  }
  finally {
    Pop-Location
  }

  & (Join-Path $binaryDirectory 'GeneratorSmokeTests.exe')
  if ($LASTEXITCODE -ne 0) {
    throw "Generator tests failed with exit code $LASTEXITCODE"
  }

  & (Join-Path $binaryDirectory 'LegacyCompatibilityTests.exe')
  if ($LASTEXITCODE -ne 0) {
    throw "Compatibility tests failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
