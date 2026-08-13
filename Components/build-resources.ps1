$ErrorActionPreference = 'Stop'

$componentDirectory = $PSScriptRoot
$runtimeUnit = Join-Path $componentDirectory '..\Runtime\JsonToDelphi.Runtime.DTO.pas'
$templateDirectory = Join-Path $componentDirectory 'DemoTemplate'
$zipFile = Join-Path $componentDirectory 'DemoTemplate.zip'
$resourceScript = Join-Path $componentDirectory 'DemoTemplate.rc'
$resourceFile = Join-Path $componentDirectory 'DemoTemplate.res'
$resourceCompiler = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\brcc32.exe'

Add-Type -AssemblyName System.IO.Compression
if (Test-Path -LiteralPath $zipFile) {
  Remove-Item -LiteralPath $zipFile
}

$stream = [System.IO.File]::Open($zipFile, [System.IO.FileMode]::CreateNew)
try {
  $archive = [System.IO.Compression.ZipArchive]::new(
    $stream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
  try {
    Get-ChildItem -LiteralPath $templateDirectory -Recurse -File | ForEach-Object {
      $relativeName = $_.FullName.Substring($templateDirectory.Length + 1).Replace('\', '/')
      $templateEntry = $archive.CreateEntry($relativeName)
      $templateEntryStream = $templateEntry.Open()
      try {
        $templateSource = [System.IO.File]::OpenRead($_.FullName)
        try {
          $templateSource.CopyTo($templateEntryStream)
        }
        finally {
          $templateSource.Dispose()
        }
      }
      finally {
        $templateEntryStream.Dispose()
      }
    }

    $entry = $archive.CreateEntry('JsonToDelphi.Runtime.DTO.pas')
    $entryStream = $entry.Open()
    try {
      $source = [System.IO.File]::OpenRead($runtimeUnit)
      try {
        $source.CopyTo($entryStream)
      }
      finally {
        $source.Dispose()
      }
    }
    finally {
      $entryStream.Dispose()
    }
  }
  finally {
    $archive.Dispose()
  }
}
finally {
  $stream.Dispose()
}

Push-Location $componentDirectory
try {
  & $resourceCompiler -fo $resourceFile $resourceScript
  if ($LASTEXITCODE -ne 0) {
    throw "Resource compilation failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}
