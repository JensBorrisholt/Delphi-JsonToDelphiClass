# Matrix implementation plan

This document tracks the implementation of first-class two-dimensional array
support in the Delphi and C# generators.

## Goals

- Generate `TMatrix<T>` for two-dimensional Delphi arrays of scalar values.
- Generate `TObjectMatrix<T>` for two-dimensional Delphi arrays of objects.
- Generate `Matrix<T>` for two-dimensional C# arrays.
- Support rectangular and jagged JSON arrays.
- Preserve type-unification, nullability and structural object merging.
- Remove the old Delphi `List2D` and `RefreshArray2D` API instead of keeping
  compatibility wrappers.

## Phase 1: Shared model

- [x] Remove the builder restriction on two-dimensional object arrays.
- [x] Verify that the model represents both cases without language-specific
      collection types:
  - `Array<Array<Integer>>`
  - `Array<Array<Object(Person)>>`
- [x] Merge object structures across every row of a nested array.
- [x] Preserve nullable leaf types across rows.
- [x] Preserve accurate JSON paths and source ranges for type conflicts.
- [x] Add model-builder tests for primitive and object matrices.

### Completion criteria

- [x] The builder accepts a two-dimensional object array.
- [x] Row order does not affect the resulting model.
- [x] No Delphi or C# collection names exist in the shared model.

## Phase 2: Delphi runtime types

Create:

```text
Runtime/JsonToDelphi.Runtime.Matrix.pas
```

Implement:

```pascal
TMatrix<T> = class(TObjectList<TList<T>>)
TObjectMatrix<T: class> = class(TObjectList<TObjectList<T>>)
```

- [x] Give both types constructors with explicit ownership semantics.
- [x] Add assignment from `TArray<TArray<T>>`.
- [x] Add conversion back to `TArray<TArray<T>>`.
- [x] Support empty matrices.
- [x] Support empty rows.
- [x] Support rows with different lengths.
- [x] Support repeated assignment without leaking previous rows or objects.
- [x] Decide and document ownership when assigning object arrays.

### Required runtime tests

- [x] `TMatrix<Integer>` assignment and conversion.
- [x] `TMatrix<string>` assignment and conversion.
- [x] Empty and jagged rows.
- [x] `TObjectMatrix<TTestObject>` assignment and conversion.
- [x] Matrix owns its row lists.
- [x] Object matrix rows own their objects.
- [x] Repeated assignment releases old content correctly.

### Completion criteria

- [x] Runtime tests compile and pass without memory leaks.
- [x] Ownership behavior is documented in the unit.

## Phase 3: Delphi generator

- [x] Generate `TMatrix<T>` when `ArrayDepth = 2` and the leaf is not an object.
- [x] Generate `TObjectMatrix<TClass>` when `ArrayDepth = 2` and the leaf is an
      object.
- [x] Add `JsonToDelphi.Runtime.Matrix` to generated `uses` clauses only when
      required.
- [x] Replace generated `TObjectList<TList<T>>` declarations.
- [x] Replace calls to `List2D` and `RefreshArray2D` with the matrix API.
- [x] Remove `List2D` and `RefreshArray2D` from `TArrayMapper`.
- [x] Verify constructors, getters, destructors and serialization hooks.
- [x] Verify nullable scalar matrix elements.
- [x] Verify structurally merged object matrix elements.

### Expected Delphi output

```pascal
property Matrix: TMatrix<Integer> read GetMatrix;
property People: TObjectMatrix<TPerson> read GetPeople;
```

### Completion criteria

- [x] Generated scalar matrix code compiles and round-trips JSON.
- [x] Generated object matrix code compiles and round-trips JSON.
- [x] Generated code contains no `List2D` or `RefreshArray2D` references.

## Phase 4: C# matrix type

`Matrix<T>` is emitted once in each generated source file that needs it. This
keeps generated C# self-contained and allows `System.Text.Json` to serialize it
without a converter. Matrix properties remain concrete `Matrix<T>` collections
when readonly-list output is enabled; records and immutable classes expose them
through `init` accessors.

Use one matrix type for scalar and object elements because C# garbage
collection handles object lifetime:

```csharp
public sealed class Matrix<T> : List<List<T>>
{
}
```

- [x] Decide whether `Matrix<T>` is emitted in the generated source file or
      supplied by a reusable C# runtime library.
- [x] Generate the type only when a two-dimensional array exists.
- [x] Generate `Matrix<int>`, `Matrix<Person>` and nullable variants correctly.
- [x] Ensure JSON serialization and deserialization work without custom code,
      or add the required converter.
- [x] Ensure records, immutable classes and readonly-list settings have defined
      matrix behavior.

### Expected C# output

```csharp
public Matrix<int> Matrix { get; set; }
public Matrix<Person> People { get; set; }
```

### Completion criteria

- [x] Generated scalar and object matrix code compiles.
- [x] Both matrix types round-trip through the configured JSON serializer.

## Phase 5: Demo data and end-to-end tests

- [x] Add a primitive matrix demo.
- [x] Add an object matrix demo.
- [x] Add a jagged matrix demo.
- [x] Add nullable matrix elements.
- [x] Add object fields that require structural merging across rows.
- [x] Run each demo through both generators.
- [x] Compile generated Delphi output.
- [x] Compile generated C# output.
- [x] Verify JSON round-trip after modifying matrix content.

Suggested demo files:

```text
Demo Data/Matrix - Numbers.json
Demo Data/Matrix - Objects.json
Demo Data/Matrix - Jagged.json
Demo Data/Matrix - Nullable.json
```

## Final regression checklist

- [x] Generator unit tests pass.
- [x] Runtime unit tests pass.
- [x] Generator smoke tests pass.
- [x] Delphi GUI compiles.
- [x] Generator library compiles.
- [x] End-to-end test project compiles.
- [x] Existing one-dimensional scalar arrays still work.
- [x] Existing one-dimensional object arrays still work.
- [x] Existing generated DTO serialization behavior is unchanged outside the
      intentional 2D API change.
- [x] No compatibility methods or obsolete 2D collection code remain.
- [x] README documents the new matrix API.

## Decisions to make before implementation

- [ ] Delphi object-array ownership during `TObjectMatrix.Assign`.
- [ ] Whether `Matrix<T>` is generated inline or supplied as C# runtime code.
- [ ] C# behavior when immutable/readonly generation is enabled.
- [ ] Fallback behavior for empty or all-null matrices where the leaf type
      cannot be inferred.

## Recommended execution order

1. Shared model and builder tests.
2. Delphi runtime types and ownership tests.
3. Delphi writer and generated-code tests.
4. C# matrix type and writer tests.
5. Demo data and cross-language end-to-end regression.
6. Documentation and removal of obsolete APIs.
