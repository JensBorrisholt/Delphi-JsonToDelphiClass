# Architecture

## Design goals

The generator is structured like a small compiler. Parsing and inference are independent of the output language, generation state belongs to one generator instance, and writers do not mutate the shared model. This makes diagnostics testable and allows another language backend to be added without duplicating JSON analysis.

## Generation pipeline

```text
TJsonToDelphiGenerator / TJsonToCSharpGenerator
                      |
                      v
          TJsonSourceValidator
          - validates JSON array shapes
          - records JSON paths and source ranges
                      |
                      v
            TJsonModelBuilder
          - walks objects and arrays
          - infers semantic types
          - merges compatible observations
          - marks optional and nullable fields
                      |
                      v
            TGeneratorModel
          - classes and fields
          - recursive types
          - stable JSON identity
                      |
             +--------+--------+
             v                 v
   TDelphiUnitWriter       TCSharpWriter
   + TDelphiNaming         + TCSharpNaming
```

### 1. Public facades

`TJsonToDelphiGenerator` and `TJsonToCSharpGenerator` are the public entry points. Each owns a fresh `TGeneratorModel`, accepts optional backend settings, parses JSON through the shared builder, and delegates source emission to its writer.

### 2. Validation and diagnostics

`TJsonSourceValidator` validates source structure and records `TJsonSourceLocation` values by JSON path. `EJsonGenerator` carries the path, position, and selection length. The desktop GUI uses those values to select the failing input text.

### 3. Neutral model and type unification

`TJsonModelBuilder` creates `TGeneratorClass`, `TGeneratorField`, and recursive `TGeneratorType` objects. An array of arrays of numbers is represented as nested array types, not as a Delphi or C# declaration.

`TGeneratorTypeUnifier` combines repeated observations. It promotes compatible numeric types, propagates nullability, merges structurally related objects, and rejects incompatible values with a path-aware error. Objects found in arrays are also compared so fields absent from some elements become optional.

### 4. Language backends

Each backend contains three distinct concerns:

- facade: controls one parse-and-generate operation;
- naming: creates valid identifiers and handles reserved words;
- writer: maps neutral types to target-language declarations and emits a complete source file.

Delphi output integrates with `TJsonDTO` and the runtime collection helpers. C# output uses `System.Text.Json` conventions and emits a self-contained source file, including required `using` directives and nullable-context configuration.

## Application layers

The VCL GUI is a client of the generator library. It handles editing, syntax highlighting, demo data, visualization, output selection, file operations, update checks, and demo-project extraction. Type inference does not live in the form.

Generated Delphi DTOs depend on the `Runtime` units for round-trip serialization, collection mapping, JSON-name attributes, semantic values, and matrix ownership.

## Dependency direction

```text
Generator GUI ------> Generator LIB/Core <------ Delphi backend
      |                       ^                  C# backend
      v                       |
Components              Runtime DTO support

Generated Delphi code -------------------------> Runtime
```

Core must remain language-neutral. Target-language naming, reserved-word handling, type spelling, attributes, and source formatting belong in the relevant backend.
