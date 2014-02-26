/** Fixed-Sized Bit-Array.
    Copyright: Per Nordlöw 2014-.
    License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors: $(WEB Per Nordlöw)
 */
module devolve.bstring.bitset;

import core.bitop;
import std.format;
import std.range;
import std.string;

/**
 * Statically sized bitarray
 */
struct BitSet(size_t len, Block = size_t)
{
    enum bitsPerBlocks = Block.sizeof * 8;
    enum noBlocks = (len + (bitsPerBlocks-1)) / bitsPerBlocks;
    Block[noBlocks] _data;

    @property inout (Block*) ptr() inout { return _data.ptr; }

    void clear() @safe nothrow { _data[] = 0; }

    /**
     * Gets the amount of native words backing this $(D BitSet).
     */
    @property static size_t dim() @safe pure nothrow { return noBlocks; }

    /**
     * Gets the amount of bits in the $(D BitSet).
     */
    @property static const size_t length() @safe pure nothrow { return len; }

    BitSet opAssign(BitSet rhs) @safe nothrow { this._data = rhs._data; return this; }

    /**
     * Gets the $(D i)'th bit in the $(D BitSet).
     */
    bool opIndex(size_t i) const @trusted pure nothrow in {
        assert(i < len);
    } body {
        // Andrei: review for @@@64-bit@@@
        return cast(bool) bt(ptr, i);
    }

    /**
     * Gets the $(D i)'th bit in the $(D BitSet).
     * Statically verifies that i is < BitSet length.
     */
    bool at(size_t i)() const @trusted pure nothrow in {
        static assert(i < len);
    } body {
        return cast(bool) bt(ptr, i);
    }

    unittest {
        BitSet!2 bs = [0, 1];
        assert(bs.at!0 == false);
        assert(bs.at!1 == true);
        // Note: This fails during compile-time: assert(bs.at!2 == false);
    }

    /**
     * Sets the $(D i)'th bit in the $(D BitSet).
     */
    import std.traits: isIntegral;
    bool opIndexAssign(Index)(bool b, Index i) @trusted pure nothrow if (isIntegral!Index) in {
        import std.traits: isMutable;
        // See also: http://stackoverflow.com/questions/19906516/static-parameter-function-specialization-in-d
        /* static if (!isMutable!Index) { */
        /*     import std.conv: to; */
        /*     static assert(i < len, */
        /*                   "Index " ~ to!string(i) ~ " must be smaller than BitSet length " ~  to!string(len)); */
        /* } */
        assert(i < len);
    } body {
        b ? bts(ptr, i) : btr(ptr, i);
        return b;
    }

    unittest {
        BitSet!2 bs;
        bs[0] = true;
        assert(bs[0]);
        import std.conv: to;
    }

    /**
     * Duplicates the $(D BitSet) and its contents.
     */
    @property BitSet dup() const @safe pure nothrow { return this; }

    /**
     * Support for $(D foreach) loops for $(D BitSet).
     */
    int opApply(scope int delegate(ref bool) dg)
    {
        int result;

        for (size_t i = 0; i < len; i++)
        {
            bool b = opIndex(i);
            result = dg(b);
            this[i] = b;
            if (result)
                break;
        }
        return result;
    }

    /** ditto */
    int opApply(scope int delegate(bool) dg) const
    {
        int result;
        for (size_t i = 0; i < len; i++)
        {
            bool b = opIndex(i);
            result = dg(b);
            if (result)
                break;
        }
        return result;
    }

    /** ditto */
    int opApply(scope int delegate(ref size_t, ref bool) dg)
    {
        int result;
        for (size_t i = 0; i < len; i++)
        {
            bool b = opIndex(i);
            result = dg(i, b);
            this[i] = b;
            if (result)
                break;
        }
        return result;
    }

    /** ditto */
    int opApply(scope int delegate(size_t, bool) dg) const
    {
        int result;
        for (size_t i = 0; i < len; i++)
        {
            bool b = opIndex(i);
            result = dg(i, b);
            if (result)
                break;
        }
        return result;
    }

    unittest
    {
        debug(bitset) printf("BitSet.opApply unittest\n");
        static bool[] ba = [1,0,1];
        auto a = BitSet!3(ba);
        size_t i;
        foreach (b;a)
        {
            switch (i)
            {
            case 0: assert(b == true); break;
            case 1: assert(b == false); break;
            case 2: assert(b == true); break;
            default: assert(0);
            }
            i++;
        }
        foreach (j,b;a)
        {
            switch (j)
            {
            case 0: assert(b == true); break;
            case 1: assert(b == false); break;
            case 2: assert(b == true); break;
            default: assert(0);
            }
        }
    }

    @property Block reverseBlock(in Block block) {
        static if (Block.sizeof == 4)
            return cast(uint)block.bitswap;
        else static if (Block.sizeof == 8)
            return (((cast(Block)((cast(uint)(block)).bitswap)) << 32) +
                    (cast(Block)((cast(uint)(block >> 32)).bitswap)));
        else
            return block;
    }

    /**
     * Reverses the bits of the $(D BitSet) in place.
     */
    @property BitSet reverse() out (result) { assert(result == this); }
    body
    {
        static if (length == noBlocks * bitsPerBlocks)  {
            static if (noBlocks == 1) {
                _data[0] = reverseBlock(_data[0]);
            }
            else static if (noBlocks == 2) {
                const tmp = _data[1];
                _data[1] = reverseBlock(_data[0]);
                _data[0] = reverseBlock(tmp);
            }
            else static if (noBlocks == 3) {
                const tmp = _data[2];
                _data[2] = reverseBlock(_data[0]);
                _data[1] = reverseBlock(_data[1]);
                _data[0] = reverseBlock(tmp);
            }
            else {
                size_t lo = 0;
                size_t hi = _data.length - 1;
                for (; lo < hi; lo++, hi--)
                {
                    immutable t = reverseBlock(_data[lo]);
                    _data[lo] = reverseBlock(_data[hi]);
                    _data[hi] = t;
                }
                if (lo == hi) {
                    _data[lo] = reverseBlock(_data[lo]);
                }
            }
        } else {
            static if (length >= 2)
            {
                size_t lo = 0;
                size_t hi = len - 1;
                for (; lo < hi; lo++, hi--)
                {
                    immutable t = this[lo];
                    this[lo] = this[hi];
                    this[hi] = t;
                }
            }
        }
        return this;
    }

    unittest
    {
        enum len = 64;
        static bool[len] data = [0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0];
        auto b = BitSet!len(data);
        b.reverse;
        for (size_t i = 0; i < data.length; i++) {
            assert(b[i] == data[len - 1 - i]);
        }
    }

    unittest
    {
        enum len = 64*2;
        static bool[len] data = [0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0];
        auto b = BitSet!len(data);
        b.reverse;
        for (size_t i = 0; i < data.length; i++) {
            assert(b[i] == data[len - 1 - i]);
        }
    }

    unittest
    {
        enum len = 64*3;
        static bool[len] data = [0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0,
                                 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0, 0,1,1,0,1,0,1,0];
        auto b = BitSet!len(data);
        b.reverse;
        for (size_t i = 0; i < data.length; i++) {
            assert(b[i] == data[len - 1 - i]);
        }
    }


    /**
     * Sorts the $(D BitSet)'s elements.
     */
    @property BitSet sort() out (result) { assert(result == this); }
    body
    {
        if (len >= 2)
        {
            size_t lo, hi;
            lo = 0;
            hi = len - 1;
            while (1)
            {
                while (1)
                {
                    if (lo >= hi)
                        goto Ldone;
                    if (this[lo] == true)
                        break;
                    lo++;
                }
                while (1)
                {
                    if (lo >= hi)
                        goto Ldone;
                    if (this[hi] == false)
                        break;
                    hi--;
                }
                this[lo] = false;
                this[hi] = true;
                lo++;
                hi--;
            }
        }
    Ldone:
        return this;
    }

    /**
     * Support for operators == and != for $(D BitSet).
     */
    const bool opEquals(in BitSet a2)
    {
        size_t i;

        if (this.length != a2.length)
            return 0;                // not equal
        auto p1 = this.ptr;
        auto p2 = a2.ptr;
        auto n = this.length / bitsPerBlocks;
        for (i = 0; i < n; i++)
        {
            if (p1[i] != p2[i])
                return 0;                // not equal
        }

        n = this.length & (bitsPerBlocks-1);
        size_t mask = (1 << n) - 1;
        //printf("i = %d, n = %d, mask = %x, %x, %x\n", i, n, mask, p1[i], p2[i]);
        return (mask == 0) || (p1[i] & mask) == (p2[i] & mask);
    }
    unittest {
        debug(bitset) printf("BitSet.opEquals unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,1]);
        auto c = BitSet!5([1,0,1,0,1]);
        assert(a != b);
        assert(a == c);
    }

    /**
     * Supports comparison operators for $(D BitSet).
     */
    int opCmp(in BitSet a2) const
    {
        uint i;

        auto len = this.length;
        if (a2.length < len)
            len = a2.length;
        auto p1 = this.ptr;
        auto p2 = a2.ptr;
        auto n = len / bitsPerBlocks;
        for (i = 0; i < n; i++)
        {
            if (p1[i] != p2[i])
                break;                // not equal
        }
        for (size_t j = 0; j < len-i * bitsPerBlocks; j++)
        {
            size_t mask = cast(size_t)(1 << j);
            auto c = (cast(long)(p1[i] & mask) - cast(long)(p2[i] & mask));
            if (c)
                return c > 0 ? 1 : -1;
        }
        return cast(int)this.length() - cast(int)a2.length;
    }

    unittest
    {
        debug(bitset) printf("BitSet.opCmp unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,1]);
        auto c = BitSet!5([1,0,1,0,1]);
        assert(a <  b);
        assert(a <= b);
        assert(a == c);
        assert(a <= c);
        assert(a >= c);
    }

    /**
     * Support for hashing for $(D BitSet).
     */
    extern(D) size_t toHash() const @trusted pure nothrow
    {
        size_t hash = 3557;
        auto n  = len / 8;
        for (size_t i = 0; i < n; i++)
        {
            hash *= 3559;
            hash += (cast(byte*)this.ptr)[i];
        }
        for (size_t i = 8*n; i < len; i++)
        {
            hash *= 3571;
            hash += bt(this.ptr, i);
        }
        return hash;
    }

    /**
     * Set this $(D BitSet) to the contents of $(D ba).
     */
    this(bool[] ba) in { assert(ba.length <= len); }
    body
    {
        foreach (i, b; ba)
        {
            this[i] = b;
        }
    }

    bool opCast(T : bool)() const @safe pure nothrow { return !this.empty ; }

    unittest {
        static bool[] ba = [1,0,1,0,1];
        auto a = BitSet!5(ba);
        assert(a);
        assert(!a.empty);
    }

    unittest {
        static bool[] ba = [0,0,0];
        auto a = BitSet!3(ba);
        assert(!a);
        assert(a.empty);
    }

    /**
     * Check if this $(D BitSet) has only zeros.
     */
    bool allZero() const @safe pure nothrow
    {
        foreach (block; _data)
        {
            if (block != 0) {
                return false;
            }
        }
        return true;
    }
    alias allZero empty;


    /**
     * Map the $(D BitSet) onto $(D v), with $(D numbits) being the number of bits
     * in the array. Does not copy the data.
     *
     * This is the inverse of $(D opCast).
     */
    /* void init(void[] v, size_t numbits) in { */
    /*     assert(numbits <= v.length * 8); */
    /*     assert((v.length & 3) == 0); // must be whole bytes */
    /* } body { */
    /*     _data[] = cast(size_t*)v.ptr[0..v.length]; */
    /* } */

    /**
     * Convert to $(D void[]).
     */
    void[] opCast(T : void[])()
    {
        return cast(void[])ptr[0 .. dim];
    }

    /**
     * Convert to $(D size_t[]).
     */
    size_t[] opCast(T : size_t[])()
    {
        return ptr[0 .. dim];
    }

    unittest
    {
        debug(bitset) printf("BitSet.opCast unittest\n");
        static bool[] ba = [1,0,1,0,1];
        auto a = BitSet!5(ba);
        void[] v = cast(void[])a;
        assert(v.length == a.dim * size_t.sizeof);
    }

    /** Support for unary operator ~ for $(D BitSet). */
    BitSet opCom() const
    {
        BitSet!len result;
        for (size_t i = 0; i < dim; i++)
            result.ptr[i] = ~this.ptr[i];
        immutable rem = len & (bitsPerBlocks-1); // number of rest bits in last block
        if (rem < bitsPerBlocks) // rest bits in last block
            // make remaining bits zero in last block
            result.ptr[dim - 1] &= ~(~(cast(Block)0) << rem);
        return result;
    }

    /** Support for binary operator & for $(D BitSet). */
    BitSet opAnd(in BitSet e2) const
    {
        BitSet!len result;
        for (size_t i = 0; i < dim; i++)
            result.ptr[i] = this.ptr[i] & e2.ptr[i];
        return result;
    }
    unittest {
        debug(bitset) printf("BitSet.opAnd unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        auto c = a & b;
        auto d = BitSet!5([1,0,1,0,0]);
        assert(c == d);
    }

    /** Support for binary operator | for $(D BitSet). */
    BitSet opOr(in BitSet e2) const
    {
        BitSet!len result;
        for (size_t i = 0; i < dim; i++)
            result.ptr[i] = this.ptr[i] | e2.ptr[i];
        return result;
    }
    unittest {
        debug(bitset) printf("BitSet.opOr unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        auto c = a | b;
        auto d = BitSet!5([1,0,1,1,1]);
        assert(c == d);
    }

    /** Support for binary operator ^ for $(D BitSet). */
    BitSet opXor(in BitSet e2) const
    {
        BitSet!len result;
        for (size_t i = 0; i < dim; i++)
            result.ptr[i] = this.ptr[i] ^ e2.ptr[i];
        return result;
    }
    unittest {
        debug(bitset) printf("BitSet.opXor unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        auto c = a ^ b;
        auto d = BitSet!5([0,0,0,1,1]);
        assert(c == d);
    }

    /**
     * Support for binary operator - for $(D BitSet).
     *
     * $(D a - b) for $(D BitSet) means the same thing as $(D a &amp; ~b).
     */
    BitSet opSub(in BitSet e2) const
    {
        BitSet!len result;
        for (size_t i = 0; i < dim; i++)
            result.ptr[i] = this.ptr[i] & ~e2.ptr[i];
        return result;
    }
    unittest {
        debug(bitset) printf("BitSet.opSub unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        auto c = a - b;
        auto d = BitSet!5([0,0,0,0,1]);
        assert(c == d);
    }

    /**
     * Support for operator &= for $(D BitSet).
     */
    BitSet opAndAssign(in BitSet e2)
    {
        for (size_t i = 0; i < dim; i++)
            ptr[i] &= e2.ptr[i];
        return this;
    }
    unittest {
        debug(bitset) printf("BitSet.opAndAssign unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        a &= b;
        auto c = BitSet!5([1,0,1,0,0]);
        assert(a == c);
    }


    /**
     * Support for operator |= for $(D BitSet).
     */
    BitSet opOrAssign(in BitSet e2)
    {
        for (size_t i = 0; i < dim; i++)
            ptr[i] |= e2.ptr[i];
        return this;
    }
    unittest {
        debug(bitset) printf("BitSet.opOrAssign unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        a |= b;
        auto c = BitSet!5([1,0,1,1,1]);
        assert(a == c);
    }

    /**
     * Support for operator ^= for $(D BitSet).
     */
    BitSet opXorAssign(in BitSet e2)
    {
        for (size_t i = 0; i < dim; i++)
            ptr[i] ^= e2.ptr[i];
        return this;
    }
    unittest {
        debug(bitset) printf("BitSet.opXorAssign unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        a ^= b;
        auto c = BitSet!5([0,0,0,1,1]);
        assert(a == c);
    }

    /**
     * Support for operator -= for $(D BitSet).
     *
     * $(D a -= b) for $(D BitSet) means the same thing as $(D a &amp;= ~b).
     */
    BitSet opSubAssign(in BitSet e2)
    body
    {
        for (size_t i = 0; i < dim; i++)
            ptr[i] &= ~e2.ptr[i];
        return this;
    }
    unittest {
        debug(bitset) printf("BitSet.opSubAssign unittest\n");
        auto a = BitSet!5([1,0,1,0,1]);
        auto b = BitSet!5([1,0,1,1,0]);
        a -= b;
        auto c = BitSet!5([0,0,0,0,1]);
        assert(a == c);
    }

    /**
     * Return a string representation of this BitSet.
     *
     * Two format specifiers are supported:
     * $(LI $(B %s) which prints the bits as an array, and)
     * $(LI $(B %b) which prints the bits as 8-bit byte packets)
     * separated with an underscore.
     */
    void toString(scope void delegate(const(char)[]) sink,
                  FormatSpec!char fmt) const
    {
        switch(fmt.spec)
        {
        case 'b':
            return formatBitString(sink);
        case 's':
            return formatBitSet(sink);
        default:
            throw new Exception("Unknown format specifier: %" ~ fmt.spec);
        }
    }

    unittest
    {
        auto b = BitSet!16(([0, 0, 0, 0, 1, 1, 1, 1,
                             0, 0, 0, 0, 1, 1, 1, 1]));

        auto s1 = format("%s", b);
        assert(s1 == "[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1]");

        auto s2 = format("%b", b);
        assert(s2 == "00001111_00001111");
    }

    private void formatBitString(scope void delegate(const(char)[]) sink) const
    {
        if (!length)
            return;

        auto leftover = len % 8;
        foreach (idx; 0 .. leftover)
        {
            char[1] res = cast(char)(bt(ptr, idx) + '0');
            sink.put(res[]);
        }

        if (leftover && len > 8)
            sink.put("_");

        size_t count;
        foreach (idx; leftover .. len)
        {
            char[1] res = cast(char)(bt(ptr, idx) + '0');
            sink.put(res[]);
            if (++count == 8 && idx != len - 1)
            {
                sink.put("_");
                count = 0;
            }
        }
    }

    private void formatBitSet(scope void delegate(const(char)[]) sink) const
    {
        sink("[");
        foreach (idx; 0 .. len)
        {
            char[1] res = cast(char)(bt(ptr, idx) + '0');
            sink(res[]);
            if (idx+1 < len)
                sink(", ");
        }
        sink("]");
    }
}


unittest
{
    import std.range: isIterable;
    static assert(isIterable!(BitSet!256));
}

unittest
{
    const b0 = BitSet!0([]);
    assert(format("%s", b0) == "[]");
    assert(format("%b", b0) is null);

    const b1 = BitSet!1([1]);
    assert(format("%s", b1) == "[1]");
    assert(format("%b", b1) == "1");

    const b4 = BitSet!4([0, 0, 0, 0]);
    assert(format("%b", b4) == "0000");

    const b8 = BitSet!8([0, 0, 0, 0, 1, 1, 1, 1]);
    assert(format("%s", b8) == "[0, 0, 0, 0, 1, 1, 1, 1]");
    assert(format("%b", b8) == "00001111");

    const b16 = BitSet!16([0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1]);
    assert(format("%s", b16) == "[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1]");
    assert(format("%b", b16) == "00001111_00001111");

    const b9 = BitSet!9([1, 0, 0, 0, 0, 1, 1, 1, 1]);
    assert(format("%b", b9) == "1_00001111");

    const b17 = BitSet!17([1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1]);
    assert(format("%b", b17) == "1_00001111_00001111");
}
