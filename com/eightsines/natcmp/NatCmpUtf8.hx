package com.eightsines.natcmp;

#if (js || flash || java || cs || (haxe_ver >= "4.0.0" && lua && !lua_vanilla))

class NatCmpUtf8 {
    public static inline function natCmpUtf8(a : String, b : String) : Int {
        return NatCmp.natCmp(a, b);
    }

    public static inline function natCaseCmpUtf8(a : String, b : String) : Int {
        return NatCmp.natCaseCmp(a, b);
    }
}

#else

#if (haxe_ver >= "4.0.0" && lua && lua_vanilla)
    // As for Haxe 4.0.0-preview.5, Utf8 is broken for lua && lua_vanilla
    import com.eightsines.natcmp.luavanillafix.Utf8;
#else
    import haxe.Utf8;
#end

/**
    NatCmp -- Perform 'natural order' comparisons of strings in Haxe.
    Copyright (C) 2018 by Viachaslau Tratsiak <viachaslau.tratsiak@gmail.com>

    Based on:
    - https://github.com/sourcefrog/natsort -- Copyright (C) 2000, 2004 by Martin Pool <mbp sourcefrog net>
    - https://github.com/php/php-src/blob/master/ext/standard/strnatcmp.c -- Copyright (C) Andrei Zmievski <andrei@ispi.net>

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
       claim that you wrote the original software. If you use this software
       in a product, an acknowledgment in the product documentation would be
       appreciated but is not required.
    2. Altered source versions must be plainly marked as such, and must not be
       misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.
**/
class NatCmpUtf8 {
    private static var upperCaseMap : Map<Int, Int>;

    public static function natCmpUtf8(a : String, b : String) : Int {
        return natCmpUtf8Impl(a, b, false);
    }

    public static inline function natCaseCmpUtf8(a : String, b : String) : Int {
        return natCmpUtf8Impl(a, b, true);
    }

    private static function natCmpUtf8Impl(a : String, b : String, ignoreCase : Bool) : Int {
        var lenA = Utf8.length(a);
        var lenB = Utf8.length(b);

        if (lenA == 0 || lenB == 0) {
            return (lenA == lenB ? 0 : (lenA > lenB ? 1 : -1));
        }

        var idxA = 0;
        var idxB = 0;
        var chA = Utf8.charCodeAt(a, 0);
        var chB = Utf8.charCodeAt(b, 0);
        var bias : Int;

        while ((idxA + 1 < lenA) && chA == "0".code && isDigit(Utf8.charCodeAt(a, idxA + 1))) {
            chA = Utf8.charCodeAt(a, ++idxA);
        }

        while ((idxB + 1 < lenB) && chB == "0".code && isDigit(Utf8.charCodeAt(b, idxB + 1))) {
            chB = Utf8.charCodeAt(b, ++idxB);
        }

        while (true) {
            while (idxA < lenA && isSpace(chA)) {
                chA = safeCharCodeAt(a, lenA, ++idxA);
            }

            while (idxB < lenB && isSpace(chB)) {
                chB = safeCharCodeAt(b, lenB, ++idxB);
            }

            if (isDigit(chA) && isDigit(chB)) {
                if (chA == "0".code || chB == "0".code) {
                    // Compare two left-aligned numbers: the first to have
                    // a different value wins.

                    while (true) {
                        if ((idxA >= lenA || !isDigit(chA)) && (idxB >= lenB || !isDigit(chB))) {
                            break;
                        }

                        if (idxA >= lenA || !isDigit(chA)) {
                            return -1;
                        }

                        if (idxB >= lenB || !isDigit(chB)) {
                            return 1;
                        }

                        if (chA < chB) {
                            return -1;
                        }

                        if (chA > chB) {
                            return 1;
                        }

                        chA = safeCharCodeAt(a, lenA, ++idxA);
                        chB = safeCharCodeAt(b, lenB, ++idxB);
                    }
                } else {
                    // The longest run of digits wins.  That aside, the greatest
                    // value wins, but we can't know that it will until we've scanned
                    // both numbers to know that they have the same magnitude, so we
                    // remember it in BIAS.

                    bias = 0;

                    while (true) {
                        if ((idxA >= lenA || !isDigit(chA)) && (idxB >= lenB || !isDigit(chB))) {
                            if (bias != 0) {
                                return bias;
                            }

                            break;
                        }

                        if (idxA >= lenA || !isDigit(chA)) {
                            return -1;
                        }

                        if (idxB >= lenB || !isDigit(chB)) {
                            return 1;
                        }

                        if (bias == 0 && chA != chB) {
                            bias = (chA < chB ? -1 : 1);
                        }

                        chA = safeCharCodeAt(a, lenA, ++idxA);
                        chB = safeCharCodeAt(b, lenB, ++idxB);
                    }
                }

                if (idxA >= lenA && idxB >= lenB) {
                    return 0;
                }

                if (idxA >= lenA) {
                    return -1;
                }

                if (idxB >= lenB) {
                    return 1;
                }
            }

            if (ignoreCase) {
                chA = upperCaseMap.exists(chA) ? upperCaseMap[chA] : chA;
                chB = upperCaseMap.exists(chB) ? upperCaseMap[chB] : chB;
            }

            if (chA < chB) {
                return -1;
            }

            if (chA > chB) {
                return 1;
            }

            chA = safeCharCodeAt(a, lenA, ++idxA);
            chB = safeCharCodeAt(b, lenB, ++idxB);

            if (idxA >= lenA && idxB >= lenB) {
                return 0;
            }

            if (idxA >= lenA) {
                return -1;
            }

            if (idxB >= lenB) {
                return 1;
            }
        }
    }

    private static inline function safeCharCodeAt(s : String, len : Int, index : Int) : Int {
        return (index < len ? Utf8.charCodeAt(s, index) : 0);
    }

    private static inline function isDigit(c : Int) : Bool {
        return (c >= "0".code && c <= "9".code);
    }

    private static inline function isSpace(c : Int) : Bool {
        return (c == " ".code
            || c == "\t".code
            || c == "\n".code
            || c == "\r".code
            || c == 11 // "\v".code
            || c == 12 // "\f".code
        );
    }

    private static function __init__() {
        upperCaseMap = new Map<Int, Int>();
        fillLowerToUpperMap(upperCaseMap);
    }

    /**
        Adapted from https://github.com/restorer/zame-haxe-stringutils/blob/master/org/zamedev/lib/internal/Utf8ExtInternal.hx

        Workarounds to fix "too many local variables (limit is 200)" in Lua:
        1. Pass "map" as parameter instead of using upperCaseMap directly;
        2. Use no-inline fillMapRange() and fillMapRangeDbl() functions.
    **/
    private static function fillLowerToUpperMap(map : Map<Int, Int>) {
        fillMapRange(map, 26, 0x61, 0x41); // a - z => A - Z (LATIN SMALL LETTER A - LATIN SMALL LETTER Z)
        map[0xB5] = 0x39C; // µ => Μ (MICRO SIGN)
        fillMapRange(map, 23, 0xE0, 0xC0); // à - ö => À - Ö (LATIN SMALL LETTER A WITH GRAVE - LATIN SMALL LETTER O WITH DIAERESIS)
        fillMapRange(map, 7, 0xF8, 0xD8); // ø - þ => Ø - Þ (LATIN SMALL LETTER O WITH STROKE - LATIN SMALL LETTER THORN)
        map[0xFF] = 0x178; // ÿ => Ÿ (LATIN SMALL LETTER Y WITH DIAERESIS)
        fillMapRangeDbl(map, 24, 0x101, 0x100); // ā - į => Ā - Į (LATIN SMALL LETTER A WITH MACRON - LATIN SMALL LETTER I WITH OGONEK)
        map[0x131] = 0x49; // ı => I (LATIN SMALL LETTER DOTLESS I)
        fillMapRangeDbl(map, 3, 0x133, 0x132); // ĳ - ķ => Ĳ - Ķ (LATIN SMALL LIGATURE IJ - LATIN SMALL LETTER K WITH CEDILLA)
        fillMapRangeDbl(map, 8, 0x13A, 0x139); // ĺ - ň => Ĺ - Ň (LATIN SMALL LETTER L WITH ACUTE - LATIN SMALL LETTER N WITH CARON)
        fillMapRangeDbl(map, 23, 0x14B, 0x14A); // ŋ - ŷ => Ŋ - Ŷ (LATIN SMALL LETTER ENG - LATIN SMALL LETTER Y WITH CIRCUMFLEX)
        fillMapRangeDbl(map, 3, 0x17A, 0x179); // ź - ž => Ź - Ž (LATIN SMALL LETTER Z WITH ACUTE - LATIN SMALL LETTER Z WITH CARON)
        map[0x17F] = 0x53; // ſ => S (LATIN SMALL LETTER LONG S)
        map[0x180] = 0x243; // ƀ => Ƀ (LATIN SMALL LETTER B WITH STROKE)
        fillMapRangeDbl(map, 2, 0x183, 0x182); // ƃ - ƅ => Ƃ - Ƅ (LATIN SMALL LETTER B WITH TOPBAR - LATIN SMALL LETTER TONE SIX)
        map[0x188] = 0x187; // ƈ => Ƈ (LATIN SMALL LETTER C WITH HOOK)
        map[0x18C] = 0x18B; // ƌ => Ƌ (LATIN SMALL LETTER D WITH TOPBAR)
        map[0x192] = 0x191; // ƒ => Ƒ (LATIN SMALL LETTER F WITH HOOK)
        map[0x195] = 0x1F6; // ƕ => Ƕ (LATIN SMALL LETTER HV)
        map[0x199] = 0x198; // ƙ => Ƙ (LATIN SMALL LETTER K WITH HOOK)
        map[0x19A] = 0x23D; // ƚ => Ƚ (LATIN SMALL LETTER L WITH BAR)
        map[0x19E] = 0x220; // ƞ => Ƞ (LATIN SMALL LETTER N WITH LONG RIGHT LEG)
        fillMapRangeDbl(map, 3, 0x1A1, 0x1A0); // ơ - ƥ => Ơ - Ƥ (LATIN SMALL LETTER O WITH HORN - LATIN SMALL LETTER P WITH HOOK)
        map[0x1A8] = 0x1A7; // ƨ => Ƨ (LATIN SMALL LETTER TONE TWO)
        map[0x1AD] = 0x1AC; // ƭ => Ƭ (LATIN SMALL LETTER T WITH HOOK)
        map[0x1B0] = 0x1AF; // ư => Ư (LATIN SMALL LETTER U WITH HORN)
        fillMapRangeDbl(map, 2, 0x1B4, 0x1B3); // ƴ - ƶ => Ƴ - Ƶ (LATIN SMALL LETTER Y WITH HOOK - LATIN SMALL LETTER Z WITH STROKE)
        map[0x1B9] = 0x1B8; // ƹ => Ƹ (LATIN SMALL LETTER EZH REVERSED)
        map[0x1BD] = 0x1BC; // ƽ => Ƽ (LATIN SMALL LETTER TONE FIVE)
        map[0x1BF] = 0x1F7; // ƿ => Ƿ (LATIN LETTER WYNN)
        map[0x1C6] = 0x1C4; // ǆ => Ǆ (LATIN SMALL LETTER DZ WITH CARON)
        map[0x1C9] = 0x1C7; // ǉ => Ǉ (LATIN SMALL LETTER LJ)
        map[0x1CC] = 0x1CA; // ǌ => Ǌ (LATIN SMALL LETTER NJ)
        fillMapRangeDbl(map, 8, 0x1CE, 0x1CD); // ǎ - ǜ => Ǎ - Ǜ (LATIN SMALL LETTER A WITH CARON - LATIN SMALL LETTER U WITH DIAERESIS AND GRAVE)
        map[0x1DD] = 0x18E; // ǝ => Ǝ (LATIN SMALL LETTER TURNED E)
        fillMapRangeDbl(map, 9, 0x1DF, 0x1DE); // ǟ - ǯ => Ǟ - Ǯ (LATIN SMALL LETTER A WITH DIAERESIS AND MACRON - LATIN SMALL LETTER EZH WITH CARON)
        map[0x1F0] = 0x4A; // ǰ => J (LATIN SMALL LETTER J)
        map[0x1F3] = 0x1F1; // ǳ => Ǳ (LATIN SMALL LETTER DZ)
        map[0x1F5] = 0x1F4; // ǵ => Ǵ (LATIN SMALL LETTER G WITH ACUTE)
        fillMapRangeDbl(map, 20, 0x1F9, 0x1F8); // ǹ - ȟ => Ǹ - Ȟ (LATIN SMALL LETTER N WITH GRAVE - LATIN SMALL LETTER H WITH CARON)
        fillMapRangeDbl(map, 9, 0x223, 0x222); // ȣ - ȳ => Ȣ - Ȳ (LATIN SMALL LETTER OU - LATIN SMALL LETTER Y WITH MACRON)
        map[0x23C] = 0x23B; // ȼ => Ȼ (LATIN SMALL LETTER C WITH STROKE)
        fillMapRange(map, 2, 0x23F, 0x2C7E); // ȿ - ɀ => Ȿ - Ɀ (LATIN SMALL LETTER S WITH SWASH TAIL - LATIN SMALL LETTER Z WITH SWASH TAIL)
        map[0x242] = 0x241; // ɂ => Ɂ (LATIN SMALL LETTER GLOTTAL STOP)
        fillMapRangeDbl(map, 5, 0x247, 0x246); // ɇ - ɏ => Ɇ - Ɏ (LATIN SMALL LETTER E WITH STROKE - LATIN SMALL LETTER Y WITH STROKE)
        map[0x250] = 0x2C6F; // ɐ => Ɐ (LATIN SMALL LETTER TURNED A)
        map[0x251] = 0x2C6D; // ɑ => Ɑ (LATIN SMALL LETTER ALPHA)
        map[0x252] = 0x2C70; // ɒ => Ɒ (LATIN SMALL LETTER TURNED ALPHA)
        map[0x253] = 0x181; // ɓ => Ɓ (LATIN SMALL LETTER B WITH HOOK)
        map[0x254] = 0x186; // ɔ => Ɔ (LATIN SMALL LETTER OPEN O)
        fillMapRange(map, 2, 0x256, 0x189); // ɖ - ɗ => Ɖ - Ɗ (LATIN SMALL LETTER D WITH TAIL - LATIN SMALL LETTER D WITH HOOK)
        map[0x259] = 0x18F; // ə => Ə (LATIN SMALL LETTER SCHWA)
        map[0x25B] = 0x190; // ɛ => Ɛ (LATIN SMALL LETTER OPEN E)
        map[0x25C] = 0xA7AB; // ɜ => Ɜ (LATIN SMALL LETTER REVERSED OPEN E)
        map[0x260] = 0x193; // ɠ => Ɠ (LATIN SMALL LETTER G WITH HOOK)
        map[0x261] = 0xA7AC; // ɡ => Ɡ (LATIN SMALL LETTER SCRIPT G)
        map[0x263] = 0x194; // ɣ => Ɣ (LATIN SMALL LETTER GAMMA)
        map[0x265] = 0xA78D; // ɥ => Ɥ (LATIN SMALL LETTER TURNED H)
        map[0x266] = 0xA7AA; // ɦ => Ɦ (LATIN SMALL LETTER H WITH HOOK)
        map[0x268] = 0x197; // ɨ => Ɨ (LATIN SMALL LETTER I WITH STROKE)
        map[0x269] = 0x196; // ɩ => Ɩ (LATIN SMALL LETTER IOTA)
        map[0x26A] = 0xA7AE; // ɪ => Ɪ (LATIN LETTER SMALL CAPITAL I)
        map[0x26B] = 0x2C62; // ɫ => Ɫ (LATIN SMALL LETTER L WITH MIDDLE TILDE)
        map[0x26C] = 0xA7AD; // ɬ => Ɬ (LATIN SMALL LETTER L WITH BELT)
        map[0x26F] = 0x19C; // ɯ => Ɯ (LATIN SMALL LETTER TURNED M)
        map[0x271] = 0x2C6E; // ɱ => Ɱ (LATIN SMALL LETTER M WITH HOOK)
        map[0x272] = 0x19D; // ɲ => Ɲ (LATIN SMALL LETTER N WITH LEFT HOOK)
        map[0x275] = 0x19F; // ɵ => Ɵ (LATIN SMALL LETTER BARRED O)
        map[0x27D] = 0x2C64; // ɽ => Ɽ (LATIN SMALL LETTER R WITH TAIL)
        map[0x280] = 0x1A6; // ʀ => Ʀ (LATIN LETTER SMALL CAPITAL R)
        map[0x283] = 0x1A9; // ʃ => Ʃ (LATIN SMALL LETTER ESH)
        map[0x287] = 0xA7B1; // ʇ => Ʇ (LATIN SMALL LETTER TURNED T)
        map[0x288] = 0x1AE; // ʈ => Ʈ (LATIN SMALL LETTER T WITH RETROFLEX HOOK)
        map[0x289] = 0x244; // ʉ => Ʉ (LATIN SMALL LETTER U BAR)
        fillMapRange(map, 2, 0x28A, 0x1B1); // ʊ - ʋ => Ʊ - Ʋ (LATIN SMALL LETTER UPSILON - LATIN SMALL LETTER V WITH HOOK)
        map[0x28C] = 0x245; // ʌ => Ʌ (LATIN SMALL LETTER TURNED V)
        map[0x292] = 0x1B7; // ʒ => Ʒ (LATIN SMALL LETTER EZH)
        map[0x29D] = 0xA7B2; // ʝ => Ʝ (LATIN SMALL LETTER J WITH CROSSED-TAIL)
        map[0x29E] = 0xA7B0; // ʞ => Ʞ (LATIN SMALL LETTER TURNED K)
        fillMapRangeDbl(map, 2, 0x371, 0x370); // ͱ - ͳ => Ͱ - Ͳ (GREEK SMALL LETTER HETA - GREEK SMALL LETTER ARCHAIC SAMPI)
        map[0x377] = 0x376; // ͷ => Ͷ (GREEK SMALL LETTER PAMPHYLIAN DIGAMMA)
        fillMapRange(map, 3, 0x37B, 0x3FD); // ͻ - ͽ => Ͻ - Ͽ (GREEK SMALL REVERSED LUNATE SIGMA SYMBOL - GREEK SMALL REVERSED DOTTED LUNATE SIGMA SYMBOL)
        map[0x390] = 0x3AA; // ΐ => Ϊ (GREEK SMALL LETTER IOTA WITH DIALYTIKA)
        map[0x3AC] = 0x386; // ά => Ά (GREEK SMALL LETTER ALPHA WITH TONOS)
        fillMapRange(map, 3, 0x3AD, 0x388); // έ - ί => Έ - Ί (GREEK SMALL LETTER EPSILON WITH TONOS - GREEK SMALL LETTER IOTA WITH TONOS)
        map[0x3B0] = 0x3AB; // ΰ => Ϋ (GREEK SMALL LETTER UPSILON WITH DIALYTIKA)
        fillMapRange(map, 17, 0x3B1, 0x391); // α - ρ => Α - Ρ (GREEK SMALL LETTER ALPHA - GREEK SMALL LETTER RHO)
        map[0x3C2] = 0x3A3; // ς => Σ (GREEK SMALL LETTER FINAL SIGMA)
        fillMapRange(map, 9, 0x3C3, 0x3A3); // σ - ϋ => Σ - Ϋ (GREEK SMALL LETTER SIGMA - GREEK SMALL LETTER UPSILON WITH DIALYTIKA)
        map[0x3CC] = 0x38C; // ό => Ό (GREEK SMALL LETTER OMICRON WITH TONOS)
        fillMapRange(map, 2, 0x3CD, 0x38E); // ύ - ώ => Ύ - Ώ (GREEK SMALL LETTER UPSILON WITH TONOS - GREEK SMALL LETTER OMEGA WITH TONOS)
        map[0x3D0] = 0x392; // ϐ => Β (GREEK BETA SYMBOL)
        map[0x3D1] = 0x398; // ϑ => Θ (GREEK THETA SYMBOL)
        map[0x3D5] = 0x3A6; // ϕ => Φ (GREEK PHI SYMBOL)
        map[0x3D6] = 0x3A0; // ϖ => Π (GREEK PI SYMBOL)
        map[0x3D7] = 0x3CF; // ϗ => Ϗ (GREEK KAI SYMBOL)
        fillMapRangeDbl(map, 12, 0x3D9, 0x3D8); // ϙ - ϯ => Ϙ - Ϯ (GREEK SMALL LETTER ARCHAIC KOPPA - COPTIC SMALL LETTER DEI)
        map[0x3F0] = 0x39A; // ϰ => Κ (GREEK KAPPA SYMBOL)
        map[0x3F1] = 0x3A1; // ϱ => Ρ (GREEK RHO SYMBOL)
        map[0x3F2] = 0x3F9; // ϲ => Ϲ (GREEK LUNATE SIGMA SYMBOL)
        map[0x3F3] = 0x37F; // ϳ => Ϳ (GREEK LETTER YOT)
        map[0x3F5] = 0x395; // ϵ => Ε (GREEK LUNATE EPSILON SYMBOL)
        map[0x3F8] = 0x3F7; // ϸ => Ϸ (GREEK SMALL LETTER SHO)
        map[0x3FB] = 0x3FA; // ϻ => Ϻ (GREEK SMALL LETTER SAN)
        fillMapRange(map, 32, 0x430, 0x410); // а - я => А - Я (CYRILLIC SMALL LETTER A - CYRILLIC SMALL LETTER YA)
        fillMapRange(map, 16, 0x450, 0x400); // ѐ - џ => Ѐ - Џ (CYRILLIC SMALL LETTER IE WITH GRAVE - CYRILLIC SMALL LETTER DZHE)
        fillMapRangeDbl(map, 17, 0x461, 0x460); // ѡ - ҁ => Ѡ - Ҁ (CYRILLIC SMALL LETTER OMEGA - CYRILLIC SMALL LETTER KOPPA)
        fillMapRangeDbl(map, 27, 0x48B, 0x48A); // ҋ - ҿ => Ҋ - Ҿ (CYRILLIC SMALL LETTER SHORT I WITH TAIL - CYRILLIC SMALL LETTER ABKHASIAN CHE WITH DESCENDER)
        fillMapRangeDbl(map, 7, 0x4C2, 0x4C1); // ӂ - ӎ => Ӂ - Ӎ (CYRILLIC SMALL LETTER ZHE WITH BREVE - CYRILLIC SMALL LETTER EM WITH TAIL)
        map[0x4CF] = 0x4C0; // ӏ => Ӏ (CYRILLIC SMALL LETTER PALOCHKA)
        fillMapRangeDbl(map, 48, 0x4D1, 0x4D0); // ӑ - ԯ => Ӑ - Ԯ (CYRILLIC SMALL LETTER A WITH BREVE - CYRILLIC SMALL LETTER EL WITH DESCENDER)
        fillMapRange(map, 38, 0x561, 0x531); // ա - ֆ => Ա - Ֆ (ARMENIAN SMALL LETTER AYB - ARMENIAN SMALL LETTER FEH)
        fillMapRange(map, 6, 0x13F8, 0x13F0); // ᏸ - ᏽ => Ᏸ - Ᏽ (CHEROKEE SMALL LETTER YE - CHEROKEE SMALL LETTER MV)
        map[0x1C80] = 0x412; // ᲀ => В (CYRILLIC SMALL LETTER ROUNDED VE)
        map[0x1C81] = 0x414; // ᲁ => Д (CYRILLIC SMALL LETTER LONG-LEGGED DE)
        map[0x1C82] = 0x41E; // ᲂ => О (CYRILLIC SMALL LETTER NARROW O)
        fillMapRange(map, 2, 0x1C83, 0x421); // ᲃ - ᲄ => С - Т (CYRILLIC SMALL LETTER WIDE ES - CYRILLIC SMALL LETTER TALL TE)
        map[0x1C85] = 0x422; // ᲅ => Т (CYRILLIC SMALL LETTER THREE-LEGGED TE)
        map[0x1C86] = 0x42A; // ᲆ => Ъ (CYRILLIC SMALL LETTER TALL HARD SIGN)
        map[0x1C87] = 0x462; // ᲇ => Ѣ (CYRILLIC SMALL LETTER TALL YAT)
        map[0x1C88] = 0xA64A; // ᲈ => Ꙋ (CYRILLIC SMALL LETTER UNBLENDED UK)
        map[0x1D79] = 0xA77D; // ᵹ => Ᵹ (LATIN SMALL LETTER INSULAR G)
        map[0x1D7D] = 0x2C63; // ᵽ => Ᵽ (LATIN SMALL LETTER P WITH STROKE)
        fillMapRangeDbl(map, 75, 0x1E01, 0x1E00); // ḁ - ẕ => Ḁ - Ẕ (LATIN SMALL LETTER A WITH RING BELOW - LATIN SMALL LETTER Z WITH LINE BELOW)
        map[0x1E96] = 0x48; // ẖ => H (LATIN SMALL LETTER H)
        map[0x1E97] = 0x54; // ẗ => T (LATIN SMALL LETTER T)
        map[0x1E98] = 0x57; // ẘ => W (LATIN SMALL LETTER W)
        map[0x1E99] = 0x59; // ẙ => Y (LATIN SMALL LETTER Y)
        map[0x1E9B] = 0x1E60; // ẛ => Ṡ (LATIN SMALL LETTER LONG S WITH DOT ABOVE)
        fillMapRangeDbl(map, 48, 0x1EA1, 0x1EA0); // ạ - ỿ => Ạ - Ỿ (LATIN SMALL LETTER A WITH DOT BELOW - LATIN SMALL LETTER Y WITH LOOP)
        fillMapRange(map, 8, 0x1F00, 0x1F08); // ἀ - ἇ => Ἀ - Ἇ (GREEK SMALL LETTER ALPHA WITH PSILI - GREEK SMALL LETTER ALPHA WITH DASIA AND PERISPOMENI)
        fillMapRange(map, 6, 0x1F10, 0x1F18); // ἐ - ἕ => Ἐ - Ἕ (GREEK SMALL LETTER EPSILON WITH PSILI - GREEK SMALL LETTER EPSILON WITH DASIA AND OXIA)
        fillMapRange(map, 8, 0x1F20, 0x1F28); // ἠ - ἧ => Ἠ - Ἧ (GREEK SMALL LETTER ETA WITH PSILI - GREEK SMALL LETTER ETA WITH DASIA AND PERISPOMENI)
        fillMapRange(map, 8, 0x1F30, 0x1F38); // ἰ - ἷ => Ἰ - Ἷ (GREEK SMALL LETTER IOTA WITH PSILI - GREEK SMALL LETTER IOTA WITH DASIA AND PERISPOMENI)
        fillMapRange(map, 6, 0x1F40, 0x1F48); // ὀ - ὅ => Ὀ - Ὅ (GREEK SMALL LETTER OMICRON WITH PSILI - GREEK SMALL LETTER OMICRON WITH DASIA AND OXIA)
        map[0x1F50] = 0x3A5; // ὐ => Υ (GREEK SMALL LETTER UPSILON)
        map[0x1F51] = 0x1F59; // ὑ => Ὑ (GREEK SMALL LETTER UPSILON WITH DASIA)
        map[0x1F52] = 0x3A5; // ὒ => Υ (GREEK SMALL LETTER UPSILON)
        map[0x1F53] = 0x1F5B; // ὓ => Ὓ (GREEK SMALL LETTER UPSILON WITH DASIA AND VARIA)
        map[0x1F54] = 0x3A5; // ὔ => Υ (GREEK SMALL LETTER UPSILON)
        map[0x1F55] = 0x1F5D; // ὕ => Ὕ (GREEK SMALL LETTER UPSILON WITH DASIA AND OXIA)
        map[0x1F56] = 0x3A5; // ὖ => Υ (GREEK SMALL LETTER UPSILON)
        map[0x1F57] = 0x1F5F; // ὗ => Ὗ (GREEK SMALL LETTER UPSILON WITH DASIA AND PERISPOMENI)
        fillMapRange(map, 8, 0x1F60, 0x1F68); // ὠ - ὧ => Ὠ - Ὧ (GREEK SMALL LETTER OMEGA WITH PSILI - GREEK SMALL LETTER OMEGA WITH DASIA AND PERISPOMENI)
        fillMapRange(map, 2, 0x1F70, 0x1FBA); // ὰ - ά => Ὰ - Ά (GREEK SMALL LETTER ALPHA WITH VARIA - GREEK SMALL LETTER ALPHA WITH OXIA)
        fillMapRange(map, 4, 0x1F72, 0x1FC8); // ὲ - ή => Ὲ - Ή (GREEK SMALL LETTER EPSILON WITH VARIA - GREEK SMALL LETTER ETA WITH OXIA)
        fillMapRange(map, 2, 0x1F76, 0x1FDA); // ὶ - ί => Ὶ - Ί (GREEK SMALL LETTER IOTA WITH VARIA - GREEK SMALL LETTER IOTA WITH OXIA)
        fillMapRange(map, 2, 0x1F78, 0x1FF8); // ὸ - ό => Ὸ - Ό (GREEK SMALL LETTER OMICRON WITH VARIA - GREEK SMALL LETTER OMICRON WITH OXIA)
        fillMapRange(map, 2, 0x1F7A, 0x1FEA); // ὺ - ύ => Ὺ - Ύ (GREEK SMALL LETTER UPSILON WITH VARIA - GREEK SMALL LETTER UPSILON WITH OXIA)
        fillMapRange(map, 2, 0x1F7C, 0x1FFA); // ὼ - ώ => Ὼ - Ώ (GREEK SMALL LETTER OMEGA WITH VARIA - GREEK SMALL LETTER OMEGA WITH OXIA)
        fillMapRange(map, 8, 0x1F80, 0x1F88); // ᾀ - ᾇ => ᾈ - ᾏ (GREEK SMALL LETTER ALPHA WITH PSILI AND YPOGEGRAMMENI - GREEK SMALL LETTER ALPHA WITH DASIA AND PERISPOMENI AND YPOGEGRAMMENI)
        fillMapRange(map, 8, 0x1F90, 0x1F98); // ᾐ - ᾗ => ᾘ - ᾟ (GREEK SMALL LETTER ETA WITH PSILI AND YPOGEGRAMMENI - GREEK SMALL LETTER ETA WITH DASIA AND PERISPOMENI AND YPOGEGRAMMENI)
        fillMapRange(map, 8, 0x1FA0, 0x1FA8); // ᾠ - ᾧ => ᾨ - ᾯ (GREEK SMALL LETTER OMEGA WITH PSILI AND YPOGEGRAMMENI - GREEK SMALL LETTER OMEGA WITH DASIA AND PERISPOMENI AND YPOGEGRAMMENI)
        fillMapRange(map, 3, 0x1FB0, 0x1FB8); // ᾰ - ᾲ => Ᾰ - Ὰ (GREEK SMALL LETTER ALPHA WITH VRACHY - GREEK SMALL LETTER ALPHA WITH VARIA)
        map[0x1FB3] = 0x1FBC; // ᾳ => ᾼ (GREEK SMALL LETTER ALPHA WITH YPOGEGRAMMENI)
        map[0x1FB4] = 0x386; // ᾴ => Ά (GREEK SMALL LETTER ALPHA WITH TONOS)
        map[0x1FB6] = 0x391; // ᾶ => Α (GREEK SMALL LETTER ALPHA)
        map[0x1FB7] = 0x391; // ᾷ => Α (GREEK SMALL LETTER ALPHA)
        map[0x1FBE] = 0x399; // ι => Ι (GREEK PROSGEGRAMMENI)
        map[0x1FC2] = 0x1FCA; // ῂ => Ὴ (GREEK SMALL LETTER ETA WITH VARIA)
        map[0x1FC3] = 0x1FCC; // ῃ => ῌ (GREEK SMALL LETTER ETA WITH YPOGEGRAMMENI)
        map[0x1FC4] = 0x389; // ῄ => Ή (GREEK SMALL LETTER ETA WITH TONOS)
        map[0x1FC6] = 0x397; // ῆ => Η (GREEK SMALL LETTER ETA)
        map[0x1FC7] = 0x397; // ῇ => Η (GREEK SMALL LETTER ETA)
        fillMapRange(map, 2, 0x1FD0, 0x1FD8); // ῐ - ῑ => Ῐ - Ῑ (GREEK SMALL LETTER IOTA WITH VRACHY - GREEK SMALL LETTER IOTA WITH MACRON)
        map[0x1FD2] = 0x3AA; // ῒ => Ϊ (GREEK SMALL LETTER IOTA WITH DIALYTIKA)
        map[0x1FD3] = 0x3AA; // ΐ => Ϊ (GREEK SMALL LETTER IOTA WITH DIALYTIKA)
        map[0x1FD6] = 0x399; // ῖ => Ι (GREEK SMALL LETTER IOTA)
        map[0x1FD7] = 0x3AA; // ῗ => Ϊ (GREEK SMALL LETTER IOTA WITH DIALYTIKA)
        fillMapRange(map, 2, 0x1FE0, 0x1FE8); // ῠ - ῡ => Ῠ - Ῡ (GREEK SMALL LETTER UPSILON WITH VRACHY - GREEK SMALL LETTER UPSILON WITH MACRON)
        map[0x1FE2] = 0x3AB; // ῢ => Ϋ (GREEK SMALL LETTER UPSILON WITH DIALYTIKA)
        map[0x1FE3] = 0x3AB; // ΰ => Ϋ (GREEK SMALL LETTER UPSILON WITH DIALYTIKA)
        map[0x1FE4] = 0x3A1; // ῤ => Ρ (GREEK SMALL LETTER RHO)
        map[0x1FE5] = 0x1FEC; // ῥ => Ῥ (GREEK SMALL LETTER RHO WITH DASIA)
        map[0x1FE6] = 0x3A5; // ῦ => Υ (GREEK SMALL LETTER UPSILON)
        map[0x1FE7] = 0x3AB; // ῧ => Ϋ (GREEK SMALL LETTER UPSILON WITH DIALYTIKA)
        map[0x1FF2] = 0x1FFA; // ῲ => Ὼ (GREEK SMALL LETTER OMEGA WITH VARIA)
        map[0x1FF3] = 0x1FFC; // ῳ => ῼ (GREEK SMALL LETTER OMEGA WITH YPOGEGRAMMENI)
        map[0x1FF4] = 0x38F; // ῴ => Ώ (GREEK SMALL LETTER OMEGA WITH TONOS)
        map[0x1FF6] = 0x3A9; // ῶ => Ω (GREEK SMALL LETTER OMEGA)
        map[0x1FF7] = 0x3A9; // ῷ => Ω (GREEK SMALL LETTER OMEGA)
        map[0x214E] = 0x2132; // ⅎ => Ⅎ (TURNED SMALL F)
        map[0x2184] = 0x2183; // ↄ => Ↄ (LATIN SMALL LETTER REVERSED C)
        fillMapRange(map, 47, 0x2C30, 0x2C00); // ⰰ - ⱞ => Ⰰ - Ⱞ (GLAGOLITIC SMALL LETTER AZU - GLAGOLITIC SMALL LETTER LATINATE MYSLITE)
        map[0x2C61] = 0x2C60; // ⱡ => Ⱡ (LATIN SMALL LETTER L WITH DOUBLE BAR)
        map[0x2C65] = 0x23A; // ⱥ => Ⱥ (LATIN SMALL LETTER A WITH STROKE)
        map[0x2C66] = 0x23E; // ⱦ => Ⱦ (LATIN SMALL LETTER T WITH DIAGONAL STROKE)
        fillMapRangeDbl(map, 3, 0x2C68, 0x2C67); // ⱨ - ⱬ => Ⱨ - Ⱬ (LATIN SMALL LETTER H WITH DESCENDER - LATIN SMALL LETTER Z WITH DESCENDER)
        map[0x2C73] = 0x2C72; // ⱳ => Ⱳ (LATIN SMALL LETTER W WITH HOOK)
        map[0x2C76] = 0x2C75; // ⱶ => Ⱶ (LATIN SMALL LETTER HALF H)
        fillMapRangeDbl(map, 50, 0x2C81, 0x2C80); // ⲁ - ⳣ => Ⲁ - Ⳣ (COPTIC SMALL LETTER ALFA - COPTIC SMALL LETTER OLD NUBIAN WAU)
        fillMapRangeDbl(map, 2, 0x2CEC, 0x2CEB); // ⳬ - ⳮ => Ⳬ - Ⳮ (COPTIC SMALL LETTER CRYPTOGRAMMIC SHEI - COPTIC SMALL LETTER CRYPTOGRAMMIC GANGIA)
        map[0x2CF3] = 0x2CF2; // ⳳ => Ⳳ (COPTIC SMALL LETTER BOHAIRIC KHEI)
        fillMapRange(map, 38, 0x2D00, 0x10A0); // ⴀ - ⴥ => Ⴀ - Ⴥ (GEORGIAN SMALL LETTER AN - GEORGIAN SMALL LETTER HOE)
        map[0x2D27] = 0x10C7; // ⴧ => Ⴧ (GEORGIAN SMALL LETTER YN)
        map[0x2D2D] = 0x10CD; // ⴭ => Ⴭ (GEORGIAN SMALL LETTER AEN)
        fillMapRangeDbl(map, 23, 0xA641, 0xA640); // ꙁ - ꙭ => Ꙁ - Ꙭ (CYRILLIC SMALL LETTER ZEMLYA - CYRILLIC SMALL LETTER DOUBLE MONOCULAR O)
        fillMapRangeDbl(map, 14, 0xA681, 0xA680); // ꚁ - ꚛ => Ꚁ - Ꚛ (CYRILLIC SMALL LETTER DWE - CYRILLIC SMALL LETTER CROSSED O)
        fillMapRangeDbl(map, 7, 0xA723, 0xA722); // ꜣ - ꜯ => Ꜣ - Ꜯ (LATIN SMALL LETTER EGYPTOLOGICAL ALEF - LATIN SMALL LETTER CUATRILLO WITH COMMA)
        fillMapRangeDbl(map, 31, 0xA733, 0xA732); // ꜳ - ꝯ => Ꜳ - Ꝯ (LATIN SMALL LETTER AA - LATIN SMALL LETTER CON)
        fillMapRangeDbl(map, 2, 0xA77A, 0xA779); // ꝺ - ꝼ => Ꝺ - Ꝼ (LATIN SMALL LETTER INSULAR D - LATIN SMALL LETTER INSULAR F)
        fillMapRangeDbl(map, 5, 0xA77F, 0xA77E); // ꝿ - ꞇ => Ꝿ - Ꞇ (LATIN SMALL LETTER TURNED INSULAR G - LATIN SMALL LETTER INSULAR T)
        map[0xA78C] = 0xA78B; // ꞌ => Ꞌ (LATIN SMALL LETTER SALTILLO)
        fillMapRangeDbl(map, 2, 0xA791, 0xA790); // ꞑ - ꞓ => Ꞑ - Ꞓ (LATIN SMALL LETTER N WITH DESCENDER - LATIN SMALL LETTER C WITH BAR)
        fillMapRangeDbl(map, 10, 0xA797, 0xA796); // ꞗ - ꞩ => Ꞗ - Ꞩ (LATIN SMALL LETTER B WITH FLOURISH - LATIN SMALL LETTER S WITH OBLIQUE STROKE)
        fillMapRangeDbl(map, 2, 0xA7B5, 0xA7B4); // ꞵ - ꞷ => Ꞵ - Ꞷ (LATIN SMALL LETTER BETA - LATIN SMALL LETTER OMEGA)
        map[0xAB53] = 0xA7B3; // ꭓ => Ꭓ (LATIN SMALL LETTER CHI)
        fillMapRange(map, 80, 0xAB70, 0x13A0); // ꭰ - ꮿ => Ꭰ - Ꮿ (CHEROKEE SMALL LETTER A - CHEROKEE SMALL LETTER YA)
        fillMapRange(map, 26, 0xFF41, 0xFF21); // ａ - ｚ => Ａ - Ｚ (FULLWIDTH LATIN SMALL LETTER A - FULLWIDTH LATIN SMALL LETTER Z)
        fillMapRange(map, 40, 0x10428, 0x10400); // 𐐨 - 𐑏 => 𐐀 - 𐐧 (DESERET SMALL LETTER LONG I - DESERET SMALL LETTER EW)
        fillMapRange(map, 36, 0x104D8, 0x104B0); // 𐓘 - 𐓻 => 𐒰 - 𐓓 (OSAGE SMALL LETTER A - OSAGE SMALL LETTER ZHA)
        fillMapRange(map, 51, 0x10CC0, 0x10C80); // 𐳀 - 𐳲 => 𐲀 - 𐲲 (OLD HUNGARIAN SMALL LETTER A - OLD HUNGARIAN SMALL LETTER US)
        fillMapRange(map, 32, 0x118C0, 0x118A0); // 𑣀 - 𑣟 => 𑢠 - 𑢿 (WARANG CITI SMALL LETTER NGAA - WARANG CITI SMALL LETTER VIYO)
        fillMapRange(map, 34, 0x1E922, 0x1E900); // 𞤢 - 𞥃 => 𞤀 - 𞤡 (ADLAM SMALL LETTER ALIF - ADLAM SMALL LETTER SHA)
    }

    private static #if !lua inline #end function fillMapRange(map : Map<Int, Int>, length : Int, key : Int, value : Int) : Void {
        for (i in 0 ... length) {
            map[key + i] = value + i;
        }
    }

    private static #if !lua inline #end function fillMapRangeDbl(map : Map<Int, Int>, length : Int, key : Int, value : Int) : Void {
        for (i in 0 ... length) {
            map[key + i + i] = value + i + i;
        }
    }
}

#end
