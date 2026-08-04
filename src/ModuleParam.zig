pub export const sceModuleParam: ModuleParam linksection(".data.sce_module_param") = .{
    .struct_byte_len = @sizeOf(ModuleParam),
    .magic = ModuleParam.MAGIC,
    .version = .{
        .major = 8,
        .minor = 8,
        .patch = 0x11,
    },
};

const ModuleParam = extern struct {
    struct_byte_len: u64,
    magic: [8]u8,
    version: packed struct(u64) {
        major: u8,
        minor: u12,
        patch: u12,
        _: u32 = 0,
    },
    _: u64 = 0,

    const MAGIC: [8]u8 = .{ 0xbf, 0xf4, 0x13, 0x3c, 0x01, 0, 0, 0 };

    comptime {
        if (@sizeOf(ModuleParam) != 0x20) {
            @compileError("ModuleParam must be 0x20 long");
        }
    }
};
