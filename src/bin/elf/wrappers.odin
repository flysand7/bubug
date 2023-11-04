package elf

sym_info_unwrap :: #force_inline proc "contextless" (info: u8) -> (bind: Sym_Binding, type: Sym_Type) {
    bind = cast(Sym_Binding) ((info & 0xf0) >> 4)
    type = cast(Sym_Type) (info & 0x0f)
    return
}

sym_info_wrap :: #force_inline proc "contextless" (bind: Sym_Binding, type: Sym_Type) -> (u8) {
    return ((cast(u8) bind) << 4) | (cast(u8) type)
}

// TODO(flysand): toolchain-specific notes

// TODO(flysand): cpu-specific relocation types

rel_info_unwrap :: #force_inline proc "contextless" (info: u64) -> (sym: u32, type: u32) {
    sym  = cast(u32) (info >> 32)
    type = cast(u32) (info & 0xffffffff)
    return
}

rel_info_wrap :: #force_inline proc "contextless" (sym: u32, type: u32) -> (u64) {
    return (cast(u64) sym << 32) | (cast(u64) type)
}

hash_cstring :: proc "contextless" (name: cstring) -> (u64) {
    h := u64(0)
    g := u64(0)
    bytes := cast([^]u8) name
    for index := 0; bytes[index] != 0; index += 1 {
        h = (h << 4) + cast(u64) bytes[index]
        g = h & 0xf0000000
        if g != 0 {
            h ~= g >> 24
        }
        h &= 0x0fffffff
    }
    return h
}

hash_string :: proc "contextless" (name: string) -> (u64) {
    h := u64(0)
    g := u64(0)
    // Converting a string to byte slice
    // we don't want to loop the decoded runes because
    //  (a) Rune decoding has side effects
    //  (b) Hash is built on bytes anyway
    bytes := (cast([^]u8) raw_data(name))[:len(name)]
    for b in bytes {
        h = (h << 4) + cast(u64) b
        g = h & 0xf0000000
        if g != 0 {
            h ~= g >> 24
        }
        h &= 0x0fffffff
    }
    return h
}

hash :: proc {
    hash_string,
    hash_cstring,
}
