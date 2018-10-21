package com.eightsines.natcmp;

#if php

class NatCmp {
    public static inline function natCmp(a : String, b : String) : Int {
        #if (haxe_ver >= "4.0.0")
            return php.Syntax.code("strnatcmp({0}, {1})", a, b);
        #else
            return untyped __php__("strnatcmp({0}, {1})", a, b);
        #end
    }

    public static inline function natCaseCmp(a : String, b : String) : Int {
        #if (haxe_ver >= "4.0.0")
            return php.Syntax.code("strnatcasecmp({0}, {1})", a, b);
        #else
            return untyped __php__("strnatcasecmp({0}, {1})", a, b);
        #end
    }
}

#else

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
class NatCmp {
    public static inline function natCmp(a : String, b : String) : Int {
        return natCmpImpl(a, b, false);
    }

    public static inline function natCaseCmp(a : String, b : String) : Int {
        return natCmpImpl(a, b, true);
    }

    private static function natCmpImpl(a : String, b : String, ignoreCase : Bool) : Int {
        var lenA = a.length;
        var lenB = b.length;

        if (lenA == 0 || lenB == 0) {
            return (lenA == lenB ? 0 : (lenA > lenB ? 1 : -1));
        }

        var idxA = 0;
        var idxB = 0;
        var chA = a.charAt(0);
        var chB = b.charAt(0);
        var bias : Int;

        while ((idxA + 1 < lenA) && chA == "0" && isDigit(a.charAt(idxA + 1))) {
            chA = a.charAt(++idxA);
        }

        while ((idxB + 1 < lenB) && chB == "0" && isDigit(b.charAt(idxB + 1))) {
            chB = b.charAt(++idxB);
        }

        while (true) {
            while (idxA < lenA && isSpace(chA)) {
                chA = safeCharAt(a, lenA, ++idxA);
            }

            while (idxB < lenB && isSpace(chB)) {
                chB = safeCharAt(b, lenB, ++idxB);
            }

            if (isDigit(chA) && isDigit(chB)) {
                if (chA == "0" || chB == "0") {
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

                        #if (cs && natcmp_cs_compareordinal)
                            if (untyped __cs__("string.CompareOrdinal({0}, {1}) < 0", chA, chB)) {
                                return -1;
                            }

                            if (untyped __cs__("string.CompareOrdinal({0}, {1}) > 0", chA, chB)) {
                                return 1;
                            }
                        #else
                            if (chA < chB) {
                                return -1;
                            }

                            if (chA > chB) {
                                return 1;
                            }
                        #end

                        chA = safeCharAt(a, lenA, ++idxA);
                        chB = safeCharAt(b, lenB, ++idxB);
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
                            #if (cs && natcmp_cs_compareordinal)
                                bias = (untyped __cs__("string.CompareOrdinal({0}, {1}) < 0", chA, chB) ? -1 : 1);
                            #else
                                bias = (chA < chB ? -1 : 1);
                            #end
                        }

                        chA = safeCharAt(a, lenA, ++idxA);
                        chB = safeCharAt(b, lenB, ++idxB);
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
                chA = chA.toUpperCase();
                chB = chB.toUpperCase();
            }

            #if (cs && natcmp_cs_compareordinal)
                if (untyped __cs__("string.CompareOrdinal({0}, {1}) < 0", chA, chB)) {
                    return -1;
                }

                if (untyped __cs__("string.CompareOrdinal({0}, {1}) > 0", chA, chB)) {
                    return 1;
                }
            #else
                if (chA < chB) {
                    return -1;
                }

                if (chA > chB) {
                    return 1;
                }
            #end

            chA = safeCharAt(a, lenA, ++idxA);
            chB = safeCharAt(b, lenB, ++idxB);

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

    private static inline function safeCharAt(s : String, len : Int, index : Int) : String {
        return (index < len ? s.charAt(index) : "");
    }

    private static inline function isDigit(c : String) : Bool {
        return (c >= "0" && c <= "9");
    }

    private static inline function isSpace(c : String) : Bool {
        return (c == " "
            || c == "\t"
            || c == "\n"
            || c == "\r"
            || c == String.fromCharCode(11) // "\v"
            || c == String.fromCharCode(12) // "\f"
        );
    }
}

#end
