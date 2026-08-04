const std = @import("std");
const assert = std.debug.assert;

pub const UserId = i32;

pub const E = enum(u32) {
    OK = 0,

    INTERNAL = 0x960001,
    NOT_INITIALIZED = 0x960002,
    ALREADY_INITIALIZED = 0x960003,
    NO_MEMORY = 0x960004,
    INVALID_ARGUMENT = 0x960005,
    OPERATION_NOT_SUPPORTED = 0x960006,
    NO_EVENT = 0x960007,
    NOT_LOGGED_IN = 0x960009,
    BUFFER_TOO_SHORT = 0x96000a,
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
    std.debug.print("unexpected errno: {d}\n", .{err});
    std.debug.dumpCurrentStackTrace(null);
    return error.Unexpected;
}

pub const InitializeOptions = extern struct {
    const PRIORITY_LOWEST = 0x2ff;
    const PRIORITY_NORMAL = 0x2bc;
    const PRIORITY_HIGHEST = 0x100;

    priority: i32 = PRIORITY_NORMAL,
};

pub const InitializeError = error{
    AlreadyInitialized,
    OutOfMemory,
    InvalidPriority,
} || UnexpectedError;

pub fn initialize(options: InitializeOptions) InitializeError!void {
    const result = sceUserServiceInitialize(&options);
    if (result < 0) switch (convertErrno(result)) {
        E.ALREADY_INITIALIZED => return error.AlreadyInitialized,
        E.NO_MEMORY => return error.OutOfMemory,
        E.INVALID_ARGUMENT => return error.InvalidPriority,
        else => return unexpectedErrno(result),
    };
}

pub fn terminate() void {
    const result = sceUserServiceTerminate();
    if (result < 0) switch (convertErrno(result)) {
        E.NOT_INITIALIZED => {}, // don't do anything if it's not initialized TODO: should this error out?
        else => unreachable,
    };
}

pub const GetInitialUserError = error{
    NeedsInit,
    OperationNotSuppoted,
} || UnexpectedError;

pub fn getInitialUser() GetInitialUserError!UserId {
    var user_id: UserId = undefined;
    const result = sceUserServiceGetInitialUser(&user_id);
    if (result < 0) switch (convertErrno(result)) {
        E.NOT_INITIALIZED => return error.NeedsInit,
        E.INVALID_ARGUMENT => unreachable,
        E.OPERATION_NOT_SUPPORTED => return error.OperationNotSuppoted,
        else => return unexpectedErrno(result),
    };
    return user_id;
}

comptime {
    assert(@sizeOf(InitializeOptions) == 0x4);
}

pub extern "SceUserService" fn sceUserServiceInitialize(options: *const InitializeOptions) callconv(.c) i32;
pub extern "SceUserService" fn sceUserServiceTerminate() callconv(.c) i32;
pub extern "SceUserService" fn sceUserServiceGetInitialUser(out_user_id: *UserId) callconv(.c) i32;
