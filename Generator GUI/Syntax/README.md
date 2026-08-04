# Syntax highlighting

This folder follows the token-based highlighter structure from the supplied
Markdown Viewer package:

1. `Pkg.Json.Syntax.Types` defines language-independent tokens.
2. `Pkg.Json.Syntax.Highlighter` provides the common lexer contract.
3. `Pkg.Json.Syntax.Json` and `Pkg.Json.Syntax.Delphi` contain language rules.
4. `Pkg.Json.Syntax.Factory` owns and selects highlighter instances.
5. `Pkg.Json.Syntax.RichEdit` renders tokens and owns the colour theme.

Language recognition does not belong in the form or in the RichEdit renderer.
Add or change lexical rules in the appropriate language unit. Change visual
colours and font styles only in the RichEdit renderer.
