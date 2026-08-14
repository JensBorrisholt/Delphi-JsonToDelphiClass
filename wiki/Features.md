# Features

## Source generation

- Generates a complete Delphi unit or C# source file from a JSON object or array.
- Supports nested objects, scalar arrays, object arrays, nested arrays, and two-dimensional matrices.
- Reuses compatible object models and merges fields found across array elements.
- Produces valid target-language identifiers and escapes or transforms reserved words.
- Supports configurable class and property naming.
- Emits the imports/usings required by the inferred types.

## Type inference

- **Integer:** `Integer` or `Int64` in Delphi; `int` or `long` in C#.
- **Fractional number:** `Double` in Delphi; `double` in C#.
- **Boolean:** `Boolean` in Delphi; `bool` in C#.
- **String:** `string` in both languages.
- **ISO date:** `TDate` in Delphi; `DateOnly` in C#.
- **ISO date-time:** `TDateTime` in Delphi; `DateTime` in C#.
- **ISO time:** `TTime` in Delphi; `TimeOnly` in C#.
- **GUID string:** `TGUID` in Delphi; `Guid` in C#.
- **URI string:** `TURI` in Delphi; `Uri` in C#.
- **Null:** merged with other observations and represented through the model's nullability information.

Numeric observations are promoted when compatible. Nullability is propagated through arrays, including nested arrays. More than two array dimensions are currently rejected.

## Collections and matrices

- Delphi collections use `TList<T>` or `TObjectList<T>` with generated lifetime-management code.
- Scalar matrices use `TMatrix<T>`.
- Object matrices use `TObjectMatrix<T>`, which owns row lists and their contained objects.
- C# matrices use a generated `Matrix<T>` based on `List<List<T>>` and work with `System.Text.Json`.
- Jagged row lengths are allowed; conflicting leaf types are diagnosed.

## Delphi JSON round trips

Generated Delphi classes inherit from `TJsonDTO`. The runtime provides:

- `AsJson` for serialization and deserialization;
- `Clone<T>` through a JSON round trip;
- generic list reflection without leaking internal list implementation details;
- optional JSON-name attributes;
- zero-date suppression through `[SuppressZero]`;
- explicit object-matrix load/save support;
- ISO-8601 date handling and pretty printing.

## Desktop application

The VCL application provides:

- simultaneous selectable Delphi, C#, BSON, and minified-JSON outputs;
- syntax highlighting appropriate to the selected language;
- JSON formatting and file open/save commands;
- JSON structure visualization;
- bundled demo-data browser;
- VCL or FMX demo-project generation using the current JSON;
- settings dialogs for both language backends;
- path-aware error selection in the JSON editor;
- asynchronous GitHub release checks.

## Known boundaries

- Input must have an object or array at the root.
- An empty array has no observable element type; generation can only use an unknown placeholder until a type is available.
- Arrays deeper than two dimensions are not supported.
- Semantic string detection is intentionally conservative and based on recognizable date, time, GUID, and URI formats.
