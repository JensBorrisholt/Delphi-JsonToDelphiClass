# Development and Testing

## Repository layout

- `Generator LIB/Core` — validation, errors, model, builder, type unification, and shared settings.
- `Generator LIB/Delphi` — Delphi facade, naming, settings, and writer.
- `Generator LIB/CSharp` — C# facade, naming, settings, and writer.
- `Generator GUI` — VCL desktop client and syntax highlighting.
- `Runtime` — support required by generated Delphi DTOs.
- `Components` — GUI services, resources, and VCL/FMX demo templates.
- `Demo Data` — representative JSON inputs and regression examples.
- `Generator LIB/Tests` — core, backend, smoke, and compatibility tests.
- `Unit Test` — runtime-focused DUnitX tests.
- `End To End Test` — full generation/build test application.

## Where a change belongs

- JSON syntax, locations, or shape errors: `Core.Validation`.
- Type inference, numeric promotion, nullability, or object merging: `Core.TypeUnification` and `Core.Builder`.
- Model ownership or metadata: `Core.Model`.
- Delphi identifiers/types/source layout: Delphi naming or writer.
- C# identifiers/types/source layout: C# naming or writer.
- Serialization behavior of generated Delphi DTOs: `Runtime`.
- Editor, visualization, settings UI, output selection, or demo workflow: `Generator GUI`/`Components`.

Keep the core free of Delphi- or C#-specific identifiers and type spellings. Add a semantic kind to the neutral model only when it describes the input independently of an output language.

## Test layers

- Core tests cover validation, model construction, builder behavior, type unification, and object matrices.
- Backend tests cover Delphi and C# naming and emitted source.
- Smoke tests compile generated output and exercise representative demo cases.
- Legacy compatibility tests protect intentional historical output behavior.
- Runtime tests cover DTO serialization, JSON-name handling, matrices, nullability, and zero suppression.
- End-to-end tests cover the complete generator integration.
- Component smoke tests build generated VCL/FMX demo projects and their embedded resources.

## Build commands

From a PowerShell prompt at the repository root:

```powershell
& '.\Unit Test\build.ps1'
& '.\End To End Test\build.ps1'
& '.\Components\Tests\build.ps1'
```

The minimum supported compiler is Delphi 2009. The scripts currently reference a RAD Studio 37/Delphi 13 compiler at `C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe`; this is only the checked-in development configuration. Update the local path when using another supported compiler version.

The generator-library projects and test runners can also be built through their `.dproj` files or from the repository project group.

## Adding a backend

1. Add a backend directory under `Generator LIB`.
2. Implement backend settings derived from `TGeneratorSettings`.
3. Implement naming and reserved-word rules without changing the model.
4. Implement a writer that consumes `TGeneratorModel` read-only.
5. Add a small public facade following the Delphi/C# parse-and-generate pattern.
6. Add unit tests for every neutral type, arrays/matrices, optional/nullable fields, naming collisions, and required imports.
7. Add smoke compilation in the target toolchain when practical.

## Documentation maintenance

Update [Features](Features) when externally visible behavior changes and [Architecture](Architecture) when responsibilities or dependency direction changes. Settings and runtime additions should be documented on their dedicated pages in the same change.
