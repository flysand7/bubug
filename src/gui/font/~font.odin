package font

import stbi "vendor:stb/image"

import "core:testing"
import "core:fmt"
import "core:os"

@(test, private)
test_packing :: proc(t: ^testing.T) {
    bitmap := make_bitmap(4096, 4096)
    mapping, mapping_ok := pack_rune_ranges(
        bitmap,
        "/usr/share/fonts/noto/NotoSerif-Medium.ttf",
        []Rune_Range {
            { ' ',  '~' },          // ASCII
            { '\u00a0', '\u00ff' }, // Latin-1 supplement
            { '\u0100', '\u024f' }, // Latin-extended A and B
            { '\u0370', '\u03ff' }, // Greek
            { '\u0400', '\u04ff' }, // Cyrillic
        },
        10,
    )
    assert(mapping_ok)
    write_status := stbi.write_bmp("test/font.bmp",
        auto_cast bitmap.size_x,
        auto_cast bitmap.size_y,
        1,
        bitmap.buffer,
    )
    file, file_err := os.open("test/font.map", os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0o777)
    if file_err != os.ERROR_NONE {
        fmt.println("Unable to open file for writing: test/font.map")
        os.exit(1)
    }
    if write_status == 0 {
        fmt.println("Failed to write font.jpg")
        testing.fail_now(t)
    }
    fmt.fprintf(file, "{{\n")
    for char, rect in mapping {
        fmt.fprintf(file,
            `    {{"char": "\u%04x", "rect": [%f, %f, %f, %f]}}
`,
            cast(u32) char,
            rect.left, rect.top, rect.right, rect.bottom)
    }
    fmt.fprintf(file, "}}\n")
    os.close(file)
}

@(test, private)
test_font :: proc(t: ^testing.T) {
    font, font_ok := font_load("/usr/share/fonts/noto/NotoSerif-Medium.ttf")
    if !font_ok {
        fmt.println("Failed to load a font")
        testing.fail_now(t)
    }
    glyph, glyph_ok := font_glyph(font, 'Q', 9)
    if !glyph_ok {
        fmt.println("Failed to load a glyph")
        testing.fail_now(t)
    }
    debug_print_glyph_to_console(glyph)
}

@(private)
debug_print_glyph_to_console :: proc(glyph: Glyph) {
    brightness_map := " .,;!v#"
    for y in 0 ..< glyph.bitmap.size_y {
        for x in 0 ..< glyph.bitmap.size_x {
            pixel: int
            if !glyph.bitmap.mono {
                pixel = auto_cast glyph.bitmap.buffer[x+y*glyph.bitmap.size_x]
            } else {
                pixel_byte := glyph.bitmap.buffer[(x+y*glyph.bitmap.size_x)/8]
                pixel = auto_cast (pixel_byte >> (cast(u8)x % 8))
            }
            normalized_pixel := (cast(f32) pixel / 256.0)
            max_brightness   := cast(f32) len(brightness_map)
            brightness := int(normalized_pixel * max_brightness)
            fmt.printf("%c", cast(rune) brightness_map[brightness])
        }
        fmt.println()
    }
}


