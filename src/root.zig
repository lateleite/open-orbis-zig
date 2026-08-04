pub const Kernel = @import("Kernel.zig");
pub const Pad = @import("Pad.zig");
pub const UserService = @import("UserService.zig");
pub const VideoOut = @import("VideoOut.zig");

const ProcessParam = @import("ProcessParam.zig");
const ModuleParam = @import("ModuleParam.zig");

pub fn useProcessSection() void {
    _ = &ProcessParam.sceProcessParam;
}

pub fn useModuleSection() void {
    _ = &ModuleParam.sceModuleParam;
}

test {
    // check if everything compiles
    _ = &Kernel;
    _ = &Pad;
    _ = &UserService;
    _ = &VideoOut;
}
