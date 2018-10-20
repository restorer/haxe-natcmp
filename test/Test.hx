package ;

import com.eightsines.natcmp.NatCmp;
import com.eightsines.natcmp.NatCmpUtf8;
import haxe.CallStack;

using com.eightsines.natcmp.NatCmp;
using com.eightsines.natcmp.NatCmpUtf8;

/**
    Ported from https://github.com/sourcefrog/natsort and https://github.com/php/php-src/tree/master/ext/standard/tests/strings
**/
class Test {
    // Runner

    public static function main() : Void {
        try {
            testBasic();
            testLeftAlign();
            testWhitespace();
            testDates();
            testFractions();
            testVersions();
            testVersionsVariation();
            testWords();
            testIgnoreCase();
            testIgnoreCaseVariation();

            testBasicUtf8();
            testLeftAlignUtf8();
            testWhitespaceUtf8();
            testDatesUtf8();
            testFractionsUtf8();
            testVersionsUtf8();
            testVersionsVariationUtf8();
            testWordsUtf8();
            testIgnoreCaseUtf8();
            testIgnoreCaseVariationUtf8();

            println("OK");
        } catch (e : String) {
            println('Failed: ${e}');
            println(CallStack.toString(CallStack.exceptionStack().slice(1)));
        }
    }

    // NatCmp

    private static function testBasic() : Void {
        assertEquals("abc1".natCmp("abc10"), -1);
        assertEquals("abc1".natCmp("abc15"), -1);
        assertEquals("abc1".natCmp("abc2"), -1);
        assertEquals("abc10".natCmp("abc15"), -1);
        assertEquals("abc2".natCmp("abc15"), -1);

        assertEquals("abc1".natCmp("ABC10"), 1);
        assertEquals("abc1".natCmp("ABC15"), 1);
        assertEquals("abc1".natCmp("ABC2"), 1);
        assertEquals("abc10".natCmp("ABC15"), 1);
        assertEquals("abc2".natCmp("ABC15"), 1);

        assertEquals("abc10".natCmp("abc10"), 0);
        assertEquals("abc10".natCmp("ABC10"), 1);

        assertEquals("abc10".natCmp("abc1"), 1);
        assertEquals("abc15".natCmp("abc1"), 1);
        assertEquals("abc2".natCmp("abc1"), 1);
        assertEquals("abc15".natCmp("abc10"), 1);
        assertEquals("abc15".natCmp("abc2"), 1);

        assertEquals("abc10".natCmp("ABC1"), 1);
        assertEquals("abc15".natCmp("ABC1"), 1);
        assertEquals("abc2".natCmp("ABC1"), 1);
        assertEquals("abc15".natCmp("ABC10"), 1);
        assertEquals("abc15".natCmp("ABC2"), 1);
    }

    private static function testLeftAlign() : Void {
        assertEquals(" 00".natCmp(" 0"), 1);
        assertEquals(" 0".natCmp(" 00"), -1);
    }

    private static function testWhitespace() : Void {
        assertEquals("foo ".natCmp("foo "), 0);
        assertEquals("foo".natCmp("foo"), 0);
        assertEquals(" foo".natCmp(" foo"), 0);
    }

    private static function testDates() : Void {
        var test = [
            "2000-1-10",
            "2000-1-2",
            "1999-12-25",
            "2000-3-23",
            "1999-3-3",
        ];

        var sorted = [
            "1999-3-3",
            "1999-12-25",
            "2000-1-2",
            "2000-1-10",
            "2000-3-23",
        ];

        test.sort(NatCmp.natCmp);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testFractions() : Void {
        var test = [
            "Fractional release numbers",
            "1.011.02",
            "1.010.12",
            "1.009.02",
            "1.009.20",
            "1.009.10",
            "1.002.08",
            "1.002.03",
            "1.002.01",
        ];

        var sorted = [
            "1.002.01",
            "1.002.03",
            "1.002.08",
            "1.009.02",
            "1.009.10",
            "1.009.20",
            "1.010.12",
            "1.011.02",
            "Fractional release numbers",
        ];

        test.sort(NatCmp.natCmp);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testVersions() : Void {
        var test = [
            "1.001",
            "1.2",
            "1.002",
            "1.02",
            "1.09",
            "1.101",
            "1.102",
            "1.010",
            "1.10",
            "1.200",
            "1.199",
            "1.198",
            "1.1",
        ];

        var sorted = [
            "1.001",
            "1.002",
            "1.010",
            "1.02",
            "1.09",
            "1.1",
            "1.2",
            "1.10",
            "1.101",
            "1.102",
            "1.198",
            "1.199",
            "1.200",
        ];

        test.sort(NatCmp.natCmp);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testVersionsVariation() : Void {
        assertEquals("v1.1.0".natCmp("v1.2.0"), -1);
        assertEquals("v1.2.0".natCmp("v1.10.0"), -1);
        assertEquals("v1.2.0".natCmp("v1.1.0"), 1);
        assertEquals("v1.10.0".natCmp("v1.2.0"), 1);
        assertEquals("v1.0.0".natCmp("v1.0.0"), 0);
    }

    private static function testWords() : Void {
        var test = [
            "fred",
            "pic2",
            "pic100a",
            "pic120",
            "pic121",
            "jane",
            "tom",
            "pic02a",
            "pic3",
            "pic4",
            "1-20",
            "pic100",
            "pic02000",
            "10-20",
            "1-02",
            "1-2",
            "x2-y7",
            "x8-y8",
            "x2-y08",
            "x2-g8",
            "pic01",
            "pic02",
            "pic 6",
            "pic   7",
            "pic 5",
            "pic05",
            "pic 5 ",
            "pic 5 something",
            "pic 4 else",
        ];

        var sorted = [
            "1-02",
            "1-2",
            "1-20",
            "10-20",
            "fred",
            "jane",
            "pic01",
            "pic02",
            "pic02a",
            "pic02000",
            "pic05",
            "pic2",
            "pic3",
            "pic4",
            "pic 4 else",
            "pic 5",
            "pic 5 ",
            "pic 5 something",
            "pic 6",
            "pic   7",
            "pic100",
            "pic100a",
            "pic120",
            "pic121",
            "tom",
            "x2-g8",
            "x2-y08",
            "x2-y7",
            "x8-y8",
        ];

        test.sort(NatCmp.natCmp);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testIgnoreCase() : Void {
        assertEquals("A".natCaseCmp("a"), 0);
        assertEquals("a10".natCaseCmp("A20"), -1);
        assertEquals("A1b".natCaseCmp("a"), 1);
        assertEquals("x2-y7".natCaseCmp("x8-y8"), -1);
        assertEquals("1.010".natCaseCmp("1.001"), 1);
        assertEquals(" ab".natCaseCmp(" aB"), 0);
        assertEquals("acc ".natCaseCmp("acc"), 1);
        assertEquals("11.5".natCaseCmp("10.5"), 1);
        assertEquals("10.5".natCaseCmp("105"), -1);
        assertEquals("Rfc822.txt".natCaseCmp("rfc2086.txt"), -1);
        assertEquals("Rfc822.txt".natCaseCmp("rfc822.TXT"), 0);
        assertEquals("pIc 6".natCaseCmp("pic   7"), -1);
        assertEquals("0xFFF".natCaseCmp("0Xfff"), 0);
    }

    private static function testIgnoreCaseVariation() : Void {
        assertEquals("0".natCaseCmp(""), 1);
        assertEquals("fooBar".natCaseCmp(""), 1);
        assertEquals("".natCaseCmp("-1"), -1);
        assertEquals("Hello WORLD".natCaseCmp("HELLO world"), 0);
    }

    // Utf8

    private static function testBasicUtf8() : Void {
        assertEquals("абв1".natCmpUtf8("абв10"), -1);
        assertEquals("абв1".natCmpUtf8("абв15"), -1);
        assertEquals("абв1".natCmpUtf8("абв2"), -1);
        assertEquals("абв10".natCmpUtf8("абв15"), -1);
        assertEquals("абв2".natCmpUtf8("абв15"), -1);

        assertEquals("абв1".natCmpUtf8("АБВ10"), 1);
        assertEquals("абв1".natCmpUtf8("АБВ15"), 1);
        assertEquals("абв1".natCmpUtf8("АБВ2"), 1);
        assertEquals("абв10".natCmpUtf8("АБВ15"), 1);
        assertEquals("абв2".natCmpUtf8("АБВ15"), 1);

        assertEquals("абв10".natCmpUtf8("абв10"), 0);
        assertEquals("абв10".natCmpUtf8("АБВ10"), 1);

        assertEquals("абв10".natCmpUtf8("абв1"), 1);
        assertEquals("абв15".natCmpUtf8("абв1"), 1);
        assertEquals("абв2".natCmpUtf8("абв1"), 1);
        assertEquals("абв15".natCmpUtf8("абв10"), 1);
        assertEquals("абв15".natCmpUtf8("абв2"), 1);

        assertEquals("абв10".natCmpUtf8("АБВ1"), 1);
        assertEquals("абв15".natCmpUtf8("АБВ1"), 1);
        assertEquals("абв2".natCmpUtf8("АБВ1"), 1);
        assertEquals("абв15".natCmpUtf8("АБВ10"), 1);
        assertEquals("абв15".natCmpUtf8("АБВ2"), 1);
    }

    private static function testLeftAlignUtf8() : Void {
        assertEquals(" 00".natCmpUtf8(" 0"), 1);
        assertEquals(" 0".natCmpUtf8(" 00"), -1);
    }

    private static function testWhitespaceUtf8() : Void {
        assertEquals("абв ".natCmpUtf8("абв "), 0);
        assertEquals("абв".natCmpUtf8("абв"), 0);
        assertEquals(" абв".natCmpUtf8(" абв"), 0);
    }

    private static function testDatesUtf8() : Void {
        var test = [
            "2000-1-10",
            "2000-1-2",
            "1999-12-25",
            "2000-3-23",
            "1999-3-3",
        ];

        var sorted = [
            "1999-3-3",
            "1999-12-25",
            "2000-1-2",
            "2000-1-10",
            "2000-3-23",
        ];

        test.sort(NatCmpUtf8.natCmpUtf8);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testFractionsUtf8() : Void {
        var test = [
            "Дробные номера релизов",
            "1.011.02",
            "1.010.12",
            "1.009.02",
            "1.009.20",
            "1.009.10",
            "1.002.08",
            "1.002.03",
            "1.002.01",
        ];

        var sorted = [
            "1.002.01",
            "1.002.03",
            "1.002.08",
            "1.009.02",
            "1.009.10",
            "1.009.20",
            "1.010.12",
            "1.011.02",
            "Дробные номера релизов",
        ];

        test.sort(NatCmpUtf8.natCmpUtf8);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testVersionsUtf8() : Void {
        var test = [
            "1.001",
            "1.2",
            "1.002",
            "1.02",
            "1.09",
            "1.101",
            "1.102",
            "1.010",
            "1.10",
            "1.200",
            "1.199",
            "1.198",
            "1.1",
        ];

        var sorted = [
            "1.001",
            "1.002",
            "1.010",
            "1.02",
            "1.09",
            "1.1",
            "1.2",
            "1.10",
            "1.101",
            "1.102",
            "1.198",
            "1.199",
            "1.200",
        ];

        test.sort(NatCmpUtf8.natCmpUtf8);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testVersionsVariationUtf8() : Void {
        assertEquals("в1.1.0".natCmpUtf8("в1.2.0"), -1);
        assertEquals("в1.2.0".natCmpUtf8("в1.10.0"), -1);
        assertEquals("в1.2.0".natCmpUtf8("в1.1.0"), 1);
        assertEquals("в1.10.0".natCmpUtf8("в1.2.0"), 1);
        assertEquals("в1.0.0".natCmpUtf8("в1.0.0"), 0);
    }

    private static function testWordsUtf8() : Void {
        var test = [
            "фред",
            "пик2",
            "пик100a",
            "пик120",
            "пик121",
            "жане",
            "том",
            "пик02a",
            "пик3",
            "пик4",
            "1-20",
            "пик100",
            "пик02000",
            "10-20",
            "1-02",
            "1-2",
            "х2-у7",
            "х8-у8",
            "х2-у08",
            "х2-г8",
            "пик01",
            "пик02",
            "пик 6",
            "пик   7",
            "пик 5",
            "пик05",
            "пик 5 ",
            "пик 5 сометхинг",
            "пик 4 елсе",
        ];

        var sorted = [
            "1-02",
            "1-2",
            "1-20",
            "10-20",
            "жане",
            "пик01",
            "пик02",
            "пик02a",
            "пик02000",
            "пик05",
            "пик2",
            "пик3",
            "пик4",
            "пик 4 елсе",
            "пик 5",
            "пик 5 ",
            "пик 5 сометхинг",
            "пик 6",
            "пик   7",
            "пик100",
            "пик100a",
            "пик120",
            "пик121",
            "том",
            "фред",
            "х2-г8",
            "х2-у08",
            "х2-у7",
            "х8-у8",
        ];

        test.sort(NatCmpUtf8.natCmpUtf8);
        assertEquals(Std.string(test), Std.string(sorted));
    }

    private static function testIgnoreCaseUtf8() : Void {
        assertEquals("я".natCaseCmpUtf8("я"), 0);
        assertEquals("я10".natCaseCmpUtf8("Я20"), -1);
        assertEquals("я1b".natCaseCmpUtf8("я"), 1);
        assertEquals("э2-ю7".natCaseCmpUtf8("э8-ю8"), -1);
        assertEquals("1.010".natCaseCmpUtf8("1.001"), 1);
        assertEquals(" аб".natCaseCmpUtf8(" аБ"), 0);
        assertEquals("авв ".natCaseCmpUtf8("авв"), 1);
        assertEquals("11.5".natCaseCmpUtf8("10.5"), 1);
        assertEquals("10.5".natCaseCmpUtf8("105"), -1);
        assertEquals("Абв822.txt".natCaseCmpUtf8("абв2086.txt"), -1);
        assertEquals("Абв822.txt".natCaseCmpUtf8("абв822.TXT"), 0);
        assertEquals("аБв 6".natCaseCmpUtf8("абв   7"), -1);
        assertEquals("0щФФФ".natCaseCmpUtf8("0Щффф"), 0);
    }

    private static function testIgnoreCaseVariationUtf8() : Void {
        assertEquals("0".natCaseCmpUtf8(""), 1);
        assertEquals("абвГде".natCaseCmpUtf8(""), 1);
        assertEquals("".natCaseCmpUtf8("-1"), -1);
        assertEquals("Привет МИР".natCaseCmpUtf8("ПРИВЕТ мир"), 0);
    }

    // Internal

    private static function assertEquals<T>(actual : T, expected : T) : Void {
        if (actual != expected) {
            throw 'expected "${expected}" but was "${actual}"';
        }
    }

    private static inline function println(str : String) : Void {
        #if sys
            Sys.println(str);
        #elseif js
            if (untyped __js__("typeof process") != "undefined"
                && untyped __js__("process").stdout != null
                && untyped __js__("process").stdout.write != null
            ) {
                untyped __js__("process").stdout.write(str);
            } else if (untyped __js__("typeof console") != "undefined"
                && untyped __js__("console").log != null
            ) {
                untyped __js__("console").log(str);
            } else {
                trace(str);
            }
        #else
            trace(str);
        #end
    }
}
