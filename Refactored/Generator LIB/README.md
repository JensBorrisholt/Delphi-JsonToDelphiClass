# Refactored generator library

This directory is an isolated replacement candidate for `Generator LIB`.
Nothing in the existing projects references it yet.

The generator is split into five responsibilities:

- `Options`: an immutable snapshot of the application's single settings object.
- `Model`: JSON-language-neutral classes and fields.
- `Naming`: conversion from JSON names to valid Delphi identifiers.
- `Builder`: conversion from JSON to the generator model.
- `DelphiWriter`: conversion from the model to a Delphi unit.
- `Generator`: the small public facade coordinating builder and writer.

`GeneratorLIBRefactored.dpr` retains the existing exported `GenerateUnit`
function, including its calling convention. The current GUI, demo generator and
original DLL project are deliberately unchanged.

Run `build.ps1` to compile the library and smoke tests. All compiler output is
kept below the ignored `build` directory; source directories must remain free
of DCUs and binaries.
