const std = @import("std");
const assert = std.debug.assert;
const math = std.math;
const Kernel = @import("Kernel.zig");
const UserService = @import("UserService.zig");

pub const E = enum(u32) {
    OK = 0,

    INVALID_VALUE = 0x290001,
    INVALID_ADDRESS = 0x290002,
    INVALID_PIXEL_FORMAT = 0x290003,
    INVALID_PITCH = 0x290004,
    INVALID_RESOLUTION = 0x290005,
    INVALID_FLIP_MODE = 0x290006,
    INVALID_TILING_MODE = 0x290007,
    INVALID_ASPECT_RATIO = 0x290008,
    RESOURCE_BUSY = 0x290009,
    INVALID_INDEX = 0x29000a,
    INVALID_HANDLE = 0x29000b,
    INVALID_EVENT_QUEUE = 0x29000c,
    INVALID_EVENT = 0x29000d,
    NO_EMPTY_SLOT = 0x29000f,
    SLOT_OCCUPIED = 0x290010,
    FLIP_QUEUE_FULL = 0x290012,
    INVALID_MEMORY = 0x290013,
    MEMORY_NOT_PHYSICALLY_CONTIGUOUS = 0x290014,
    MEMORY_INVALID_ALIGNMENT = 0x290015,
    UNSUPPORTED_OUTPUT_MODE = 0x290016,
    OVERFLOW = 0x290017,
    NO_DEVICE = 0x290018,
    UNAVAILABLE_OUTPUT_MODE = 0x290019,
    INVALID_OPTION = 0x29001a,
    PORT_UNSUPPORTED_FUNCTION = 0x29001b,
    UNSUPPORTED_OPERATION = 0x29001c,
    FATAL = 0x2900ff,
    UNKNOWN = 0x2900fe,
    NOMEM = 0x29100c,
    _,
};

fn convertErrno(val: i32) E {
    assert(val < 0);
    const val_unsigned: u32 = @bitCast(val);
    return @enumFromInt(val_unsigned - 0x80000000);
}

pub const AspectRatio = enum(i32) {
    @"16_9" = 0,
};
pub const Bus = enum(i32) {
    Main = 0,
    Social = 5,
    Live = 6,
};
pub const FlipRate = enum(i32) {
    @"60hz" = 0,
    @"30hz" = 1,
    @"20hz" = 2,
};
pub const FlipType = enum(i32) {
    vsync = 1,
    hsync = 2,
};
pub const PixelFormat = enum(i32) {
    a8r8g8b8_srgb = -0x80000000, // 0x80000000
    a8b8g8r8_srgb = -0x7fffde00, // 0x80002200
    a2r10g10b10_srgb = -0x78000000,
    a2r10g10b10 = -0x77fa0000,
    a2r10g10b10_bt2020_pq = -0x778c0000,
    a16r16g16b16_float = -0x3efa0000,
};
pub const TilingMode = enum(i32) {
    tiled = 0,
    linear = 1,
};

pub const BufferAttribute = extern struct {
    pub const Option = enum(u32) {
        none = 0,
        vr = 7,
        strict_colormetry = 8,
    };

    pixel_format: PixelFormat,
    tiling_mode: TilingMode,
    aspect_ratio: AspectRatio,
    width: u32,
    height: u32,
    pitch_in_pixel: u32,
    option: Option,
    _: u32 = 0,
    _2: u64 = 0,
};
pub const FlipStatus = extern struct {
    count: u64,
    process_time: u64,
    tsc: u64,
    flip_arg: i64,
    submit_tsc: u64,
    _: u64 = 0,
    gc_queue_num: i32,
    flip_pending_num: i32,
    current_buffer: i32,
    _2: u32 = 0,
};
pub const ResolutionStatus = extern struct {
    width: u32,
    height: u32,
    pane_width: u32,
    pane_height: u32,
    refresh_rate: u64,
    screen_inches: f32,
    flags: u16,
    _: u16 = 0,
    _2: [3]u32 = .{ 0, 0, 0 },
};

pub const UnexpectedError = error{
    Unexpected,
};
fn unexpectedErrno(err: i32) UnexpectedError {
    std.debug.print("unexpected errno: {d}\n", .{err});
    std.debug.dumpCurrentStackTrace(.{});
    return error.Unexpected;
}

pub const Display = extern struct {
    pub const Handle = i32;

    handle: Handle,

    pub const OpenError = error{
        ResourceBusy,
    } || UnexpectedError;

    pub fn open(
        user_id: UserService.UserId,
        bus_type: Bus,
        index: i32,
        param: ?*const anyopaque,
    ) OpenError!Display {
        const result = sceVideoOutOpen(user_id, bus_type, index, param);
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_VALUE => unreachable,
            E.RESOURCE_BUSY => return error.ResourceBusy,
            else => return unexpectedErrno(result),
        };
        return .{
            .handle = result,
        };
    }

    pub fn close(self: *Display) void {
        const result = sceVideoOutClose(self.handle);
        // intentionally force all errors as unreachable,
        // since this is supposed to be the deinit() equivalent of VideoOut's handles
        if (result < 0) unreachable;
        self.handle = 0;
    }

    pub fn addFlipEvent(self: *Display, queue: Kernel.Equeue, user_data: ?*anyopaque) UnexpectedError!void {
        const result = sceVideoOutAddFlipEvent(queue, self.handle, user_data);
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_EVENT_QUEUE => unreachable,
            E.INVALID_HANDLE => unreachable,
            else => return unexpectedErrno(result),
        };
    }

    pub fn getResolutionStatus(self: Display) UnexpectedError!ResolutionStatus {
        var status: ResolutionStatus = undefined;
        const result = sceVideoOutGetResolutionStatus(self.handle, &status);
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_ADDRESS => unreachable,
            E.INVALID_HANDLE => unreachable,
            else => return unexpectedErrno(result),
        };
        return status;
    }

    pub const RegisterBuffersError = error{
        InvalidAddress,
        InvalidAspectRatio,
        InvalidIndex,
        InvalidMemory,
        InvalidOption,
        InvalidPixelFormat,
        InvalidResolution,
        InvalidTilingMode,
        MemoryInvalidAlignment,
        MemoryNotPhysicallyContiguous,
        NoEmptySlot,
        SlotOccupied,
        TooManyBuffers,
    } || UnexpectedError;

    pub fn registerBuffers(
        self: *Display,
        start_index: u31,
        addresses: []const [*]const u8,
        attribute: *const BufferAttribute,
    ) RegisterBuffersError!u31 {
        const num_addresses = math.cast(i32, addresses.len) orelse return error.TooManyBuffers;
        _ = math.add(i32, start_index, num_addresses) catch return error.TooManyBuffers;

        const result = sceVideoOutRegisterBuffers(
            self.handle,
            start_index,
            addresses.ptr,
            num_addresses,
            attribute,
        );
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_ADDRESS => return error.InvalidAddress,
            E.INVALID_ASPECT_RATIO => return error.InvalidAspectRatio,
            E.INVALID_HANDLE => unreachable,
            E.INVALID_INDEX => return error.InvalidIndex,
            E.INVALID_MEMORY => return error.InvalidMemory,
            E.INVALID_OPTION => return error.InvalidOption,
            E.INVALID_PIXEL_FORMAT => return error.InvalidPixelFormat,
            E.INVALID_RESOLUTION => return error.InvalidResolution,
            E.INVALID_TILING_MODE => return error.InvalidTilingMode,
            E.INVALID_VALUE => unreachable,
            E.MEMORY_INVALID_ALIGNMENT => return error.MemoryInvalidAlignment,
            E.MEMORY_NOT_PHYSICALLY_CONTIGUOUS => return error.MemoryNotPhysicallyContiguous,
            E.NO_EMPTY_SLOT => return error.NoEmptySlot,
            E.SLOT_OCCUPIED => return error.SlotOccupied,
            else => return unexpectedErrno(result),
        };
        return @truncate(@as(u32, @intCast(result)));
    }

    pub fn setFlipRate(self: *Display, flip_rate: FlipRate) void {
        const result = sceVideoOutSetFlipRate(self.handle, flip_rate);
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_HANDLE => unreachable,
            E.INVALID_VALUE => unreachable,
            else => unreachable,
        };
    }

    pub const SubmitFlipError = error{
        FlipQueueFull,
        InvalidAddress,
        InvalidAspectRatio,
        InvalidIndex,
        InvalidMemory,
        InvalidOption,
        InvalidPixelFormat,
        InvalidResolution,
        InvalidTilingMode,
        UnsupportedOperation,
    } || UnexpectedError;

    pub fn submitFlip(self: *Display, buffer_index: u31, flip_type: FlipType, flip_arg: u64) SubmitFlipError!void {
        const result = sceVideoOutSubmitFlip(self.handle, buffer_index, flip_type, flip_arg);
        if (result < 0) switch (convertErrno(result)) {
            E.FLIP_QUEUE_FULL => return error.FlipQueueFull,
            E.INVALID_FLIP_MODE => unreachable,
            E.INVALID_HANDLE => unreachable,
            E.INVALID_INDEX => return error.InvalidIndex,
            E.INVALID_VALUE => unreachable,
            E.UNSUPPORTED_OPERATION => return error.UnsupportedOperation,
            else => return unexpectedErrno(result),
        };
    }
};

comptime {
    assert(@sizeOf(BufferAttribute) == 0x28);
    assert(@sizeOf(FlipStatus) == 0x40);
    assert(@sizeOf(ResolutionStatus) == 0x30);
}

pub extern "SceVideoOut" fn sceVideoOutOpen(user_id: UserService.UserId, bus_type: Bus, index: i32, param: ?*const anyopaque) callconv(.c) i32;
pub extern "SceVideoOut" fn sceVideoOutClose(handle: Display.Handle) callconv(.c) i32;

pub extern "SceVideoOut" fn sceVideoOutAddFlipEvent(queue: Kernel.Equeue, handle: Display.Handle, user_data: ?*anyopaque) callconv(.c) i32;
pub extern "SceVideoOut" fn sceVideoOutGetResolutionStatus(handle: Display.Handle, status: *ResolutionStatus) callconv(.c) i32;
pub extern "SceVideoOut" fn sceVideoOutRegisterBuffers(
    handle: Display.Handle,
    start_index: i32,
    addresses: [*]const [*]const u8,
    num_buffers: i32,
    attribute: *const BufferAttribute,
) callconv(.c) i32;
pub extern "SceVideoOut" fn sceVideoOutSetFlipRate(handle: Display.Handle, flip_rate: FlipRate) callconv(.c) i32;
pub extern "SceVideoOut" fn sceVideoOutSubmitFlip(
    handle: Display.Handle,
    buffer_index: i32,
    flip_type: FlipType,
    flip_arg: u64,
) callconv(.c) i32;
