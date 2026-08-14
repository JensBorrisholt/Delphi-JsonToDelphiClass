# Runtime Library

Generated Delphi DTOs use units from `Runtime`. Include the required runtime units in the application's search path or copy them beside the generated unit. Demo-project generation performs this packaging automatically.

## Primary API: TJsonDTO

All generated root and object DTOs derive from `TJsonDTO`.

```pascal
var
  Customer: TCustomerDTO;
begin
  Customer := TCustomerDTO.Create;
  try
    Customer.AsJson := JsonText; // deserialize
    JsonText := Customer.AsJson; // serialize
  finally
    Customer.Free;
  end;
end;
```

`TJsonDTO` configures Delphi REST JSON serialization for ISO-8601 UTC dates. `ToString` returns `AsJson`, and `Clone<T>` creates a deep logical copy by serializing and loading a new DTO instance.

## Collections

`TArrayMapper` bridges dynamic arrays used internally by Delphi's serializer and the `TList<T>`/`TObjectList<T>` API exposed by generated classes. `GenericListReflectAttribute` resolves the matching published property via RTTI so serialization emits collection elements instead of implementation fields.

Object lists own their objects where generated code requires ownership. Do not manually free an item that remains owned by its `TObjectList<T>`.

## Matrices

`JsonToDelphi.Runtime.Matrix` defines:

- `TMatrix<T>` for two-dimensional scalar values;
- `TObjectMatrix<T>` for two-dimensional object values.

Both own their row lists. `TObjectMatrix<T>` also owns each object in those rows. `TJsonDTO.LoadObjectMatrix` and `SaveObjectMatrix` provide explicit mapping because Delphi's default REST serializer cannot reliably round-trip nested object collections directly.

## Attributes and helpers

- `JsonToDelphi.Runtime.JSONName` maps a Delphi member to its original JSON property name.
- `[SuppressZero]` writes an empty value for a zero `TDateTime` and restores it on input.
- `JsonToDelphi.Runtime.JsonValueHelper` classifies Delphi `TJSONValue` instances for the generator and compatibility code.
- `JsonToDelphi.Runtime.JSONConverter` supplies JSON formatting/minification and BSON-related GUI output.
- `JsonToDelphi.Runtime.Threading` and utility units support application-level operations.

## Compatibility code

`JsonToDelphi.Runtime.Mapper`, `StubField`, `SubTypes`, `ReservedWords`, and related units contain the historical mapper surface used by compatibility paths. New generation work should use `Generator LIB/Core` and a language backend instead of adding new inference logic to the legacy mapper.
