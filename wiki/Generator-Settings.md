# Generator Settings

Settings inherit from `TGeneratorSettings`, which supports UTF-8 `Load` and `Save` using the runtime's JSON serialization.

## Delphi settings

- `AddJsonPropertyAttributes` (default: `False`) — adds explicit JSON-name mapping attributes where applicable.
- `PostFixClassNames` (default: `False`) — enables a suffix on generated class names.
- `PostFix` (default: `DTO`) — sets the suffix used when class postfixing is enabled.
- `UsePascalCase` (default: `True`) — converts generated identifiers to PascalCase.
- `SuppressZeroDate` (default: `True`) — adds zero-date suppression support to applicable fields.

`ClassPostFix` returns either the configured postfix or an empty string, according to `PostFixClassNames`.

## C# settings

- `NamespaceName` (default: `Generated`) — sets the file-scoped namespace for generated types.
- `UsePascalCase` (default: `True`) — converts generated identifiers to PascalCase.
- `UseNullableTypes` (default: `False`) — enables nullable declarations where the model permits them.
- `AddJsonPropertyNameAttributes` (default: `False`) — emits `JsonPropertyName` mappings.
- `UseRecords` (default: `False`) — generates records instead of classes.
- `GenerateImmutableClasses` (default: `False`) — uses init-only property semantics.
- `UseReadonlyLists` (default: `False`) — exposes read-only list interfaces where supported.

Settings affect only the writer and naming policy. They must not change JSON validation or mutate the neutral model.

## Persistence

```pascal
Settings.Save('generator-settings.json');
Settings.Load('generator-settings.json');
```

Files are read and written as UTF-8. Because settings are regular `TJsonDTO` descendants, new published configuration properties participate in persistence automatically.
