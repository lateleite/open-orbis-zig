const std = @import("std");
const Io = std.Io;
const math = std.math;
const ps4 = std.os.ps4;
const assert = std.debug.assert;
const page_size_min = std.heap.page_size_min;

pub const page_size_default = 16 << 10; // 16kb
pub const page_size_large = 2048 << 10; // 2mb

pub const off_t = i64;

//
// cpu
//
pub const CpuMask = enum(u64) {
    @"6CpuAll" = 0x3f,
    @"7CpuAll" = 0x7f,
    _,
};
pub const SchedParam = extern struct {
    sched_priority: i32,
};
pub const Useconds = u32;

//
// equeue
//
pub const MAX_EQUEUE_NAME_LEN = 32;

pub const EventFilter = enum(i16) {
    Read = -1,
    Write = -2,
    File = -4,
    Timer = -7,
    User = -11,
    VideoOut = -13,
    Gnm = -14,
    HrTimer = -15,
};
pub const Event = extern struct {
    ident: u64 = 0,
    filter: EventFilter,
    flags: u16 = 0,
    fflags: u32 = 0,
    data: i64 = 0,
    udata: ?*anyopaque = null,
};

pub const EqueueHandle = *anyopaque;

pub const Equeue = extern struct {
    handle: EqueueHandle,

    const Self = @This();

    pub const CreateError = error{
        NameTooLong,
        SystemResources,
    } || UnexpectedError;

    pub fn init(name: [:0]const u8) CreateError!Equeue {
        var handle: *anyopaque = undefined;
        const result = sceKernelCreateEqueue(&handle, name);
        if (result < 0) switch (convertSceErrno(result)) {
            .FAULT => unreachable,
            .INVAL => unreachable,
            .MFILE => return error.SystemResources,
            .NOMEM => return error.SystemResources,
            .NAMETOOLONG => return error.NameTooLong,
            else => |err| return unexpectedErrno(err),
        };
        return .{
            .handle = handle,
        };
    }

    pub fn deinit(self: *Self) void {
        const result = sceKernelDeleteEqueue(self.handle);
        if (result < 0) switch (convertSceErrno(result)) {
            .BADF => unreachable,
            else => unreachable,
        };
    }

    pub const WaitError = error{
        NameTooLong,
        SystemResources,
    } || UnexpectedError;

    pub fn wait(self: *Self, events_buffer: []Event, timeout: ?*Useconds) WaitError![]Event {
        const max_events: i32 = @min(events_buffer.len, math.maxInt(u31));
        var num_written: i32 = 0;
        const result = sceKernelWaitEqueue(
            self.handle,
            events_buffer.ptr,
            max_events,
            &num_written,
            timeout,
        );
        if (result < 0) switch (convertSceErrno(result)) {
            .FAULT => unreachable,
            .INVAL => unreachable,
            .MFILE => return error.SystemResources,
            .NOMEM => return error.SystemResources,
            .NAMETOOLONG => return error.NameTooLong,
            else => |err| return unexpectedErrno(err),
        };
        const cast_written = math.cast(u32, num_written) orelse return error.Unexpected;
        return events_buffer[0..cast_written];
    }

    pub fn waitSingle(self: *Self, timeout: ?*Useconds) WaitError!Event {
        var ev: [1]Event = undefined;
        _ = try self.wait(&ev, timeout);
        return ev[0];
    }
};

comptime {
    assert(@sizeOf(Equeue) == 0x8);
}

pub extern "kernel" fn sceKernelCreateEqueue(out_queue: *EqueueHandle, name: ?[*:0]const u8) i32;
pub extern "kernel" fn sceKernelDeleteEqueue(queue: EqueueHandle) i32;
pub extern "kernel" fn sceKernelWaitEqueue(
    queue: EqueueHandle,
    event: [*]Event,
    max_events: i32,
    num_events_written: *i32,
    timeout: ?*Useconds,
) i32;

//
// filesystem
//
pub const FileOpenError = std.Io.File.OpenError || error{WouldBlock};

pub fn fileOpenAbsolute(path: [:0]const u8, flags: ps4.O, perm: ps4.mode_t) FileOpenError!ps4.fd_t {
    while (true) {
        const rc = _open(path.ptr, flags, perm);
        switch (ps4.errno(rc)) {
            .SUCCESS => return @intCast(rc),
            .INTR => continue,

            .FAULT => unreachable,
            .INVAL => return error.BadPathName,
            .BADF => unreachable,
            .ACCES => return error.AccessDenied,
            .FBIG => return error.FileTooBig,
            .OVERFLOW => return error.FileTooBig,
            .ISDIR => return error.IsDir,
            .LOOP => return error.SymLinkLoop,
            .MFILE => return error.ProcessFdQuotaExceeded,
            .NAMETOOLONG => return error.NameTooLong,
            .NFILE => return error.SystemFdQuotaExceeded,
            .NODEV => return error.NoDevice,
            .NOENT => return error.FileNotFound,
            .SRCH => return error.FileNotFound,
            .NOMEM => return error.SystemResources,
            .NOSPC => return error.NoSpaceLeft,
            .NOTDIR => return error.NotDir,
            .PERM => return error.PermissionDenied,
            .EXIST => return error.PathAlreadyExists,
            .BUSY => return error.DeviceBusy,
            .OPNOTSUPP => return error.FileLocksUnsupported,
            .AGAIN => return error.WouldBlock,
            .TXTBSY => return error.FileBusy,
            .NXIO => return error.NoDevice,
            .ILSEQ => return error.BadPathName,
            else => |err| return unexpectedErrno(err),
        }
    }
}

pub fn fileClose(fd: ps4.fd_t) void {
    switch (ps4.errno(ps4.close(fd))) {
        .SUCCESS, .INTR => {}, // INTR still a success, see https://github.com/ziglang/zig/issues/2425
        .BADF => unreachable, // use after free
        else => unreachable, // unexpected failure
    }
}

pub fn createDirAbsolute(path: [:0]const u8, mode: ps4.mode_t) std.Io.Dir.CreateDirError!void {
    while (true) {
        const rc = ps4.errno(mkdir(path.ptr, mode));
        switch (rc) {
            .SUCCESS => return,
            .INTR => continue,

            .ACCES => return error.AccessDenied,
            .PERM => return error.PermissionDenied,
            .DQUOT => return error.DiskQuota,
            .EXIST => return error.PathAlreadyExists,
            .LOOP => return error.SymLinkLoop,
            .MLINK => return error.LinkQuotaExceeded,
            .NAMETOOLONG => return error.NameTooLong,
            .NOENT => return error.FileNotFound,
            .NOMEM => return error.SystemResources,
            .NOSPC => return error.NoSpaceLeft,
            .NOTDIR => return error.NotDir,
            .ROFS => return error.ReadOnlyFileSystem,
            .ILSEQ => return error.BadPathName,
            .BADF => unreachable,
            .FAULT => unreachable,
            else => |err| return unexpectedErrno(err),
        }
    }
}

extern "kernel" fn _open(path: [*:0]const u8, flags: ps4.O, perm: ps4.mode_t) i32;
extern "kernel" fn mkdir(path: [*:0]const u8, mode: ps4.mode_t) i32;

//
// memory
//
pub const MAP = packed struct(u32) {
    TYPE: enum(u4) {
        SHARED = 0x01,
        PRIVATE = 0x02,
    },
    FIXED: bool = false,
    _5: u2 = 0,
    /// if `FIXED` is true, the specified region must be free of any mappings, or it will fail
    FIXED_NOREPLACE: bool = false,
    /// forces an anonymous map without backing physical memory
    RESERVE: bool = false,
    HASSEMAPHORE: bool = false,
    STACK: bool = false,
    NOSYNC: bool = false,
    ANONYMOUS: bool = false,
    /// consequences unknown, used by sceKernelMapNamedSystemFlexibleMemory
    SYSTEM_OWNED: bool = false,
    /// sets the start area to an address obtained through the ASLR's random generator
    RANDOMIZED: bool = false,
    _15: u1 = 0,
    /// requests large 2MB pages for the mapping
    PAGE_2MB: bool = false,
    NOCORE: bool = false,
    PREFAULT_READ: bool = false,
    /// maps the contents of a SELF file specified in `fd`, potentially decrypting and decompressing its source data
    SELF: bool = false,
    _20: u1 = 0,
    /// allows the caller to reserve a virtual address outside the user's (program's) range.
    /// requires some special process capability/priviledge.
    ALLOW_NON_USER_AREA: bool = false,
    /// disables joining the requested mapping with any neighboring existing mappings
    NO_COALESCING: bool = false,
    _23: u1 = 0,
    ALIGNMENT: u5 = 0,
};

pub const MapDirectMemoryFlags = packed struct(u32) {
    _: u4 = 0,
    fixed: bool = false,
    _5: u2 = 0,
    /// if `fixed` is true, the specified region must be free of any mappings, or it will fail
    fixed_no_replace: bool = false,
    _8: u2 = 0,
    /// if enabled then it forces mmap() to be used with a `/dev/dmem `` device as its `fd`,
    /// otherwise use the newer `sys_mmap_dmem` syscall.
    force_old_map_method: bool = false,
    _11: u10 = 0,
    /// allows the caller to reserve a virtual address outside the user's (program's) range.
    /// requires some special process capability/priviledge.
    allow_non_user_area: bool = false,
    /// disables joining the requested mapping with any neighboring existing mappings
    no_coalescing: bool = false,
    _23: u9 = 0,
};

pub const MapFlexibleMemoryFlags = packed struct(u32) {
    _: u4 = 0,
    fixed: bool = false,
    _5: u2 = 0,
    /// if `fixed` is true, the specified region must be free of any mappings, or it will fail
    fixed_noreplace: bool = false,
    _9: u14 = 0,
    /// disables joining the requested mapping with any neighboring existing mappings
    no_coalescing: bool = false,
    _23: u9 = 0,
};

pub const MemoryType = enum(i32) {
    onion_write_back = 0,
    garlic_write_combined = 3,
    garlic_write_back = 10,
};

pub const PROT = packed struct(i32) {
    /// page can be read
    READ: bool = false,
    /// page can be written (and read implicitly)
    WRITE: bool = false,
    /// page can be executed
    EXEC: bool = false,
    _: u1 = 0,
    /// page can be read by the GPU
    GPU_READ: bool = false,
    /// page can be written by the GPU
    GPU_WRITE: bool = false,
    _2: u26 = 0,

    pub fn isCpu(self: PROT) bool {
        return self.READ or self.WRITE or self.EXEC;
    }

    pub fn isGpu(self: PROT) bool {
        return self.GPU_READ or self.GPU_WRITE;
    }
};

pub const VirtualQueryInfo = extern struct {
    virtual_start: usize,
    virtual_end: usize,
    physical_address: off_t,
    protection: PROT,
    memory_type: MemoryType,
    memory_flags: packed struct(u8) {
        flexible: bool,
        direct: bool,
        stack: bool,
        pooled: bool,
        committed: bool,
        _: u3 = 0,
    },
    name: [32:0]u8,
};

pub const AllocateDirectMemoryError = error{CantAllocate} || UnexpectedError;

pub fn allocateDirectMemory(
    length: usize,
    alignment: usize,
    memory_type: MemoryType,
) AllocateDirectMemoryError!off_t {
    var phys_addr: off_t = undefined;
    const status = sceKernelAllocateDirectMemory(
        0,
        @bitCast(sceKernelGetDirectMemorySize()),
        length,
        alignment,
        memory_type,
        &phys_addr,
    );
    if (status < 0) switch (convertSceErrno(status)) {
        .INVAL => unreachable,
        .AGAIN => return error.CantAllocate,
        else => |err| return unexpectedErrno(err),
    };

    return phys_addr;
}

pub const MapDirectMemoryError = error{
    AccessDenied,
    AlreadyMapped,
    OutOfMemory,
} || UnexpectedError;

pub fn mapDirectMemory(
    phys_address: off_t,
    desired_virtual_address: ?[*]align(page_size_min) u8,
    length: usize,
    alignment: usize,
    protection: PROT,
    flags: MapDirectMemoryFlags,
) MapDirectMemoryError![]align(page_size_min) u8 {
    var out_addr: ?[*]align(page_size_min) u8 = if (desired_virtual_address) |addr| addr else null;

    const status = sceKernelMapDirectMemory(&out_addr, length, protection, flags, phys_address, alignment);
    if (status < 0) switch (convertSceErrno(status)) {
        .ACCES => return error.AccessDenied,
        .BUSY => return error.AlreadyMapped,
        .INVAL => unreachable,
        .NOMEM => return error.OutOfMemory,
        else => |err| return unexpectedErrno(err),
    };

    if (out_addr) |a| {
        return a[0..length];
    } else {
        unreachable;
    }
}

pub fn munmap(
    address: []align(page_size_min) u8,
) void {
    const status = sceKernelMunmap(address.ptr, address.len);
    if (status < 0) unreachable;
}

pub fn releaseDirectMemory(
    phys_address: off_t,
    length: usize,
) void {
    const status = sceKernelReleaseDirectMemory(phys_address, length);
    if (status < 0) unreachable;
}

pub const VirtualQueryInfoError = error{NotMapped} || UnexpectedError;

pub fn virtualQueryInfo(
    address: [*]const u8,
) VirtualQueryInfoError!VirtualQueryInfo {
    var query_info: VirtualQueryInfo = undefined;
    const status = sceKernelVirtualQuery(address, 0, &query_info, @sizeOf(@TypeOf(query_info)));
    if (status < 0) switch (convertSceErrno(status)) {
        .ACCES => return error.NotMapped,
        .FAULT => unreachable,
        .INVAL => unreachable,
        else => |err| return unexpectedErrno(err),
    };
    return query_info;
}

comptime {
    assert(@sizeOf(VirtualQueryInfo) == 0x48);
}

pub extern "kernel" fn sceKernelAllocateDirectMemory(
    search_start: off_t,
    search_end: off_t,
    length: usize,
    alignment: usize,
    memory_type: MemoryType,
    out_address: *off_t,
) callconv(.c) i32;
pub extern "kernel" fn sceKernelGetDirectMemorySize() usize;
pub extern "kernel" fn sceKernelMapDirectMemory(
    address: ?*?[*]align(page_size_min) u8,
    length: usize,
    protection: PROT,
    flags: MapDirectMemoryFlags,
    physical_address: off_t,
    alignment: usize,
) callconv(.c) i32;
pub extern "kernel" fn sceKernelMunmap(
    address: [*]align(page_size_min) u8,
    length: usize,
) callconv(.c) i32;
pub extern "kernel" fn sceKernelReleaseDirectMemory(
    physical_address: off_t,
    length: usize,
) callconv(.c) i32;
pub extern "kernel" fn sceKernelVirtualQuery(
    address: [*]const u8,
    flags: i32,
    out_query_info: *VirtualQueryInfo,
    size_of_query_info: usize,
) callconv(.c) i32;

fn convertSceErrno(val: i32) ps4.E {
    assert(val < 0);
    return @fromBackingInt(@intCast(0x7FFE0000 - val));
}

pub const UnexpectedError = error{
    Unexpected,
};
fn unexpectedErrno(err: ps4.E) UnexpectedError {
    std.debug.print("unexpected errno: {}\n", .{err});
    std.debug.dumpCurrentStackTrace(.{});
    return error.Unexpected;
}
