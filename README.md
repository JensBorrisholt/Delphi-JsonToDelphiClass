# Delphi-JsonToDelphiClass

**Delphi JSON to Class Generator for Object Pascal and Delphi DTOs**

Delphi-JsonToDelphiClass is a Delphi JSON to class generator that converts representative JSON documents into strongly typed Delphi classes and DTOs. It automates Delphi DTO generation for Object Pascal and Embarcadero Delphi and includes the runtime support needed for JSON serialization, deserialization, and JSON data binding.

It is both a visual JSON to Delphi class generator and a reusable code-generation library. The project includes a VCL desktop GUI, Delphi runtime units, demo-project generation, and a C# source-generation backend. JSON is validated and converted into a language-neutral model before the selected backend emits source code.

[![Delphi JSON to class generator showing JSON input and generated Object Pascal code](Images/Mainform_4.2.png)](Images/Mainform_4.2.png)

*JsonToDelphiClass 4.2 with JSON input, selectable output formats, and generated Delphi source.*

## Delphi JSON to class generation example

Given this JSON input:

```json
{
  "name": "John",
  "age": 42
}
```

Using `Person` as the root class name generates a Delphi class in this style:

```pascal
type
  TPerson = class(TJsonDTO)
  private
    FAge: Integer;
    FName: string;
  published
    property Age: Integer read FAge write FAge;
    property Name: string read FName write FName;
  end;
```

`TJsonDTO` supplies the JSON round-trip API:

```pascal
Person.AsJson := JsonText;  // deserialize JSON into the DTO
JsonText := Person.AsJson;  // serialize the DTO back to JSON
```

## Delphi JSON to class generator features

- Generates a complete Delphi unit from a JSON object or root array.
- Generates a complete C# source file from the same validated, language-neutral model.
- Handles nested JSON objects, scalar arrays, object arrays, optional fields, null values, and compatible structures found across array elements.
- Detects `Integer`, `Int64`, `Double`, `Boolean`, and string values.
- Detects ISO-8601 dates and date-times, standalone times, GUIDs, and URI values, with language-specific output types.
- Supports scalar and object matrices represented by two-dimensional JSON arrays, including jagged row lengths.
- Creates valid Delphi or C# identifiers and handles reserved words and JSON property-name mapping.
- Uses `TList<T>` and `TObjectList<T>` in generated Delphi APIs and emits ownership code for complex values.
- Provides JSON serialization/deserialization, DTO cloning, JSON pretty printing, generic-list mapping, zero-date suppression, and object-matrix mapping through the Delphi runtime.
- Includes a VCL GUI with JSON and source syntax highlighting, JSON formatting, BSON and minified-JSON output, a class visualizer, bundled demo data, and path-aware generation errors.
- Checks GitHub releases asynchronously and reports available updates in the desktop application.
- Generates runnable VCL or FMX demo projects from the current JSON document.
- Provides configurable Delphi class naming and JSON attributes plus C# namespaces, records, init-only properties, nullable types, `JsonPropertyName` attributes, and read-only list interfaces.
- Includes unit, generator, compatibility, smoke, and end-to-end tests.

An empty array has no observable element type. Arrays deeper than two dimensions are currently not supported.

## Getting Started with JSON to Delphi generation

### Requirements

- Delphi 2009 or newer.
- The `VCL.Ribbon` package for the Generator GUI. Install it through Delphi's GetIt Package Manager.
- PowerShell when using the checked-in build scripts.

The build scripts currently point to a local RAD Studio 37/Delphi 13 compiler installation. That path is a development configuration, not the minimum supported Delphi version, and can be adjusted for another supported installation.

### Desktop generator

1. Open `JsonToDelphi.groupproj` or `Generator GUI/JsonToDelphiClass.dproj` in Delphi.
2. Build and run the `JsonToDelphiClass` application.
3. Paste JSON, open a JSON file, or select a bundled sample from **Demo Data**.
4. Enter the root class name and Delphi unit name.
5. Select one or more outputs: **Delphi Unit**, **C# Source**, **BSON**, **Minify JSON**, or **Demo project**.
6. Click **Generate output**, review the result, and save the active output.

The generated Delphi unit depends on units from the `Runtime` directory. Demo-project generation packages the generated DTO, sample JSON, and required runtime files automatically.

### Reusable Delphi generator API

The GUI is a client of the generator library; generation can also be embedded in another Delphi application:

```pascal
uses
  JsonToDelphi.Generator.Delphi;

var
  Generator: TJsonToDelphiGenerator;
  DelphiSource: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.RootClassName := 'Person';
    Generator.DestinationUnitName := 'Person.DTO';
    DelphiSource := Generator.Parse(JsonText).GenerateUnit;
  finally
    Generator.Free;
  end;
end;
```

Add `Generator LIB/Core`, `Generator LIB/Delphi`, and `Runtime` to the unit search path. Use `JsonToDelphi.Generator.CSharp` in the same pattern when generating C# source.

For architecture, settings, runtime behavior, and development details, see the [JSON to Delphi Class Generator documentation](https://github.com/JensBorrisholt/Delphi-JsonToDelphiClass/wiki).

## What's New

### 14 August 2026

- Renamed historical `Pkg.*` units to the `JsonToDelphi.*` namespace and renamed `Lib` to `Runtime`.
- Centralized numeric promotion, nullability, nested-array analysis, and structural object merging in the shared type-unification layer.
- Added `TMatrix<T>` and `TObjectMatrix<T>` to the Delphi runtime and a self-contained `Matrix<T>` type for generated C#.
- Added matrix and type-unification samples, explicit Delphi object-matrix mapping, and ownership fixes for nested object arrays.
- Simplified the generated VCL/FMX demo project's JSON tree view implementation.

### 12 August 2026

- Added semantic detection and Delphi/C# mappings for ISO dates, standalone times, GUIDs, and URIs.
- Redesigned the Generator GUI and settings dialog.
- Added the integrated demo-data browser, JSON class visualizer, framework-selectable demo-project generation, and expanded automated tests.

### 5 August 2026

- Added C# as a second generator backend, including complete source files and language-specific settings.
- Separated the generator into language-neutral `Core`, `Delphi`, and `CSharp` areas.
- Added shared JSON persistence for backend settings.

See the [complete changelog](CHANGELOG.md) for all fixes, features, historical examples, acknowledgements, and earlier release notes.

## Project History and Credits

This repository originated as a fork of [PKGeorgiev/Delphi-JsonToDelphiClass](https://github.com/PKGeorgiev/Delphi-JsonToDelphiClass). During years of continued development, the codebase has been comprehensively rewritten, reorganized, and expanded with a new generator architecture, additional output backends, runtime capabilities, GUI tooling, and automated tests. The original GitHub fork relationship is retained as part of the project's history.

The historical `Pkg` unit prefix came from the initials of the original project creator, Petar Georgiev. Current units use the product-oriented `JsonToDelphi` namespace while the project's origin and GitHub fork relationship remain unchanged.

Thanks to everyone who has contributed code, testing, bug reports, and suggestions. Individual contributions and acknowledgements — including links retained from the previous README — are preserved in the [complete changelog](CHANGELOG.md).

Source code and binary releases are available through [GitHub Releases](https://github.com/JensBorrisholt/Delphi-JsonToDelphiClass/releases). Please report problems or suggestions using [GitHub Issues](https://github.com/JensBorrisholt/Delphi-JsonToDelphiClass/issues).

## License

Delphi-JsonToDelphiClass is open-source software licensed under the [MIT License](LICENSE).
