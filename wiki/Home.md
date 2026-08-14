# Delphi JsonToDelphiClass Wiki

JsonToDelphiClass converts a representative JSON document into strongly typed Delphi or C# source code. The repository also contains the Delphi runtime used by generated DTOs, a Windows desktop application, demo-project templates, and automated tests.

## Start here

- [Architecture](Architecture) explains the compiler-style generation pipeline and the repository's major components.
- [Features](Features) is the feature catalogue, including type inference, matrices, serialization, and the desktop tools.
- [Getting Started](Getting-Started) shows how to build and use the desktop generator and the generator API.
- [Generator Settings](Generator-Settings) documents the Delphi- and C#-specific options.
- [Runtime Library](Runtime-Library) explains the units that generated Delphi code depends on.
- [Development and Testing](Development-and-Testing) describes the project layout, extension points, and test suites.

## At a glance

```text
JSON source
  |
  v
Validation
  |
  v
Neutral type model
  |
  +-- Delphi writer --> .pas unit + Delphi runtime
  |
  `-- C# writer -----> .cs source
```

The language-neutral model is the architectural boundary. Validation, source locations, type inference, nullability, object merging, and array analysis happen before a language writer chooses identifiers or target-language types.

## Supported products

- **Generator GUI** (`Generator GUI`)  
  VCL desktop application for interactive conversion and visualization.

- **Generator library** (`Generator LIB`)  
  Shared model plus Delphi and C# generators.

- **Delphi runtime** (`Runtime`)  
  JSON DTO serialization and generated-code support.

- **Demo project support** (`Components`)  
  Embedded VCL/FMX templates and GUI services.

The minimum supported compiler is Delphi 2009. The checked-in build scripts currently point to a RAD Studio 37/Delphi 13 installation and may need a local path adjustment. The desktop GUI also requires the `VCL.Ribbon` package. Much of the runtime uses only Delphi RTL units and is designed for cross-platform generated applications.
