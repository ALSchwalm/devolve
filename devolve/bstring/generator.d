module devolve.bstring.generator;
import std.math;
import std.conv;

template integralType(uint size) if (size > 0) {
    static if (size <= 8) {
        alias integralType = ubyte;
    }
    else static if (size <= 16) {
        alias integralType = ushort;
    }
    else static if (size <= 32) {
        alias integralType = uint;
    }
    else static if (size <= 64) {
        alias integralType = ulong;
    }
    else {
        static assert(false, format("Value %d to large for integral type. "
                                    "Arbitrary length bstring not yet supported", size));
    }
}

/**
 * Create the initial population using some preset value.
 */
template preset (alias val) {
    auto preset(T)() {
        return to!T(val);
    }
}

