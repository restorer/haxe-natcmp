# NatCmp

Perform 'natural order' comparisons of strings in Haxe ('a1' < 'a12').

Based on [natsort](https://github.com/sourcefrog/natsort) and [strnatcmp](https://github.com/php/php-src/blob/master/ext/standard/strnatcmp.c).
Read more in original [README](https://github.com/sourcefrog/natsort/blob/master/README.md).

## API

- `NatCmp.natCmp(a : String, b : String) : Int`
- `NatCmp.natCaseCmp(a : String, b : String) : Int` - compare ignore case
- `NatCmpUtf8.natCmpUtf8(a : String, b : String) : Int` - Utf8 version of `natCmp`
- `NatCmpUtf8.natCaseCmpUtf8(a : String, b : String) : Int` - Utf8 version of `natCaseCmp`

## C# note

As far as I know, by default Haxe generated `string.Compare()` for string comparision, and it result depends on current culture. This may be inconsistent with other compile targets. Eg. `"A" < "a"` is true for every target except in C# (via Mono at macOS), where `"A" > "a"`.

So by default, C# builds may be different to builds for other targets. Use `-D natcmp_cs_compareordinal` for more consistent behaviour.
