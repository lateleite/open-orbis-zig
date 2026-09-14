//
// port of OpenOrbis-Toolchain's right.sprx
//
const orbis = @import("orbis");

export fn sceGameRightGetVersion() callconv(.c) u32 {
    return 1;
}

export fn sceGameRightGetString() callconv(.c) [*]const u8 {
    return STRING_DATA.ptr;
}

export fn sceGameRightGetStringSizeInBytes() callconv(.c) i32 {
    return STRING_DATA.len;
}

export fn sceGameRightGetLogoPngImage() callconv(.c) [*]const u8 {
    return LOGO_DATA.ptr;
}

export fn sceGameRightGetLogoPngImageSizeInBytes() callconv(.c) i32 {
    return LOGO_DATA.len;
}

const STRING_DATA: [:0]const u8 =
    \\Homebrew was built with the OpenOrbis PS4 Toolchain.
    \\
    \\https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain
;

const LOGO_DATA = @embedFile("logo.png");

comptime {
    orbis.useModuleSection();
}
