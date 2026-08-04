const std = @import("std");
const assert = std.debug.assert;
const Kernel = @import("Kernel.zig");
const UserService = @import("UserService.zig");

pub const E = enum(u32) {
    OK = 0,

    INVALID_ARG = 0x920001,
    INVALID_PORT = 0x920002,
    INVALID_HANDLE = 0x920003,
    ALREADY_OPENED = 0x920004,
    NOT_INITIALIZED = 0x920005,
    INVALID_LIGHTBAR_SETTING = 0x920006,
    DEVICE_NOT_CONNECTED = 0x920007,
    DEVICE_NO_HANDLE = 0x920008,
    FATAL = 0x9200ff,
    NOT_PERMITTED = 0x920101,
    INVALID_BUFFER_LENGTH = 0x920102,
    INVALID_REPORT_LENGTH = 0x920103,
    INVALID_REPORT_ID = 0x920104,
    SEND_AGAIN = 0x920105,
    _,
};

fn convertErrno(val: i32) E {
    assert(val < 0);
    const val_unsigned: u32 = @bitCast(val);
    return @enumFromInt(val_unsigned - 0x80000000);
}

pub const UnexpectedError = error{
    Unexpected,
};
fn unexpectedErrno(err: i32) UnexpectedError {
    std.debug.print("unexpected errno: {d} (0x{x})\n", .{ err, @as(u32, @bitCast(err)) });
    std.debug.dumpCurrentStackTrace(null);
    return error.Unexpected;
}

pub fn globalInit() void {
    const result = scePadInit();
    if (result != 0) unreachable;
}

pub const Controller = struct {
    pub const Handle = i32;
    handle: Handle,

    pub const PortType = enum(i32) {
        standard = 0,
    };

    pub const OpenError = error{
        AlreadyOpen,
        NeedsGlobalInit,
    } || UnexpectedError;

    pub fn open(
        user_id: UserService.UserId,
        port_type: PortType,
        index: i32,
    ) OpenError!Controller {
        const result = scePadOpen(user_id, port_type, index);
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_ARG => unreachable,
            E.ALREADY_OPENED => return error.AlreadyOpen,
            E.NOT_INITIALIZED => return error.NeedsGlobalInit,
            else => return unexpectedErrno(result),
        };
        return .{
            .handle = result,
        };
    }

    pub fn close(self: *Controller) void {
        const result = scePadClose(self.handle);
        // intentionally force all errors as unreachable,
        // since this is supposed to be the deinit() equivalent of VideoOut's handles
        if (result < 0) unreachable;
        self.handle = 0;
    }

    pub const GetHandleError = error{
        NeedsGlobalInit,
        UnknownDevice,
    } || UnexpectedError;

    pub fn getHandle(
        user_id: UserService.UserId,
        port_type: PortType,
        index: i32,
    ) GetHandleError!Controller {
        const result = scePadGetHandle(user_id, port_type, index);
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_ARG => unreachable,
            E.DEVICE_NO_HANDLE => return error.UnknownDevice,
            E.NOT_INITIALIZED => return error.NeedsGlobalInit,
            else => return unexpectedErrno(result),
        };
        return .{
            .handle = result,
        };
    }

    pub const ReadStateError = error{
        NeedsGlobalInit,
    } || UnexpectedError;

    pub fn readState(self: Controller) ReadStateError!Data {
        var state: Data = undefined;
        const result = scePadReadState(self.handle, &state);
        if (result < 0) switch (convertErrno(result)) {
            E.INVALID_ARG => unreachable,
            E.INVALID_HANDLE => unreachable,
            E.NOT_INITIALIZED => return error.NeedsGlobalInit,
            else => return unexpectedErrno(result),
        };
        return state;
    }

    pub const Data = extern struct {
        pub const Buttons = packed struct(u32) {
            _: u1 = 0,
            l3: bool = false,
            r3: bool = false,
            options: bool = false,
            up: bool = false,
            right: bool = false,
            down: bool = false,
            left: bool = false,
            l2: bool = false,
            r2: bool = false,
            l1: bool = false,
            r1: bool = false,
            triangle: bool = false,
            circle: bool = false,
            cross: bool = false,
            square: bool = false,
            touch_pad: bool = false,
            _2: u15 = 0,
        };

        pub const AnalogStick = packed struct(u16) {
            x: u8,
            y: u8,
        };

        pub const AnalogButtons = packed struct(u16) {
            l2: u8,
            r2: u8,
        };

        pub const TouchData = extern struct {
            pub const Finger = packed struct(u64) {
                x: u16,
                y: u16,
                id: u8,
                _: u24 = 0,
            };

            num_fingers: u8,
            fingers: [2]Finger align(8),
        };

        pub const empty = Data{
            .buttons = .{},
            .left_stick = .{ .x = 0, .y = 0 },
            .right_stick = .{ .x = 0, .y = 0 },
            .analog_buttons = .{ .l2 = 0, .r2 = 0 },

            .orientation = @splat(0.0),
            .acceleration = @splat(0.0),
            .angular_velocity = @splat(0.0),

            .touch = .{
                .num_fingers = 0,
                .fingers = [2]TouchData.Finger{ .{ .x = 0, .y = 0, .id = 0 }, .{ .x = 0, .y = 0, .id = 0 } },
            },

            .is_connected = false,
            .timestamp = 0,

            .num_connected = 0,
        };

        buttons: Buttons,
        left_stick: AnalogStick align(1),
        right_stick: AnalogStick align(1),
        analog_buttons: AnalogButtons align(1),

        orientation: [4]f32 align(4),
        acceleration: [3]f32 align(4),
        angular_velocity: [3]f32 align(4),

        touch: TouchData align(4),

        is_connected: bool align(4),
        timestamp: u64 align(4),

        extension_data: [16]u8 = @splat(0),
        num_connected: u8,

        _unknown: [15]u8 align(1) = @splat(0),
    };
};

comptime {
    assert(@sizeOf(Controller.Data.AnalogStick) == 0x2);
    assert(@sizeOf(Controller.Data.AnalogButtons) == 0x2);
    assert(@sizeOf(Controller.Data.TouchData.Finger) == 0x8);
    assert(@sizeOf(Controller.Data.TouchData) == 0x18);
    assert(@sizeOf(Controller.Data) == 0x78);
}

pub extern "ScePad" fn scePadInit() callconv(.c) i32;
pub extern "ScePad" fn scePadOpen(user_id: UserService.UserId, port_type: Controller.PortType, index: i32) callconv(.c) i32;
pub extern "ScePad" fn scePadClose(handle: Controller.Handle) callconv(.c) i32;
pub extern "ScePad" fn scePadGetHandle(user_id: UserService.UserId, port_type: Controller.PortType, index: i32) callconv(.c) i32;
pub extern "ScePad" fn scePadReadState(handle: Controller.Handle, out_state: *Controller.Data) callconv(.c) i32;
