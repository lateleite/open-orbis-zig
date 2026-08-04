const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const page_size_min = std.heap.page_size_min;

pub const page_size_default = 16 << 10; // 16kb
pub const page_size_large = 2048 << 10; // 2mb

pub const off_t = i64;

pub const E = enum(u16) {
    SUCCESS = 0,

    //
    // FreeBSD's 9.0 error codes
    //
    PERM = 1,
    NOENT = 2,
    SRCH = 3,
    INTR = 4,
    IO = 5,
    NXIO = 6,
    @"2BIG" = 7,
    NOEXEC = 8,
    BADF = 9,
    CHILD = 10,
    DEADLK = 11,
    NOMEM = 12,
    ACCES = 13,
    FAULT = 14,
    NOTBLK = 15,
    BUSY = 16,
    EXIST = 17,
    XDEV = 18,
    NODEV = 19,
    NOTDIR = 20,
    ISDIR = 21,
    INVAL = 22,
    NFILE = 23,
    MFILE = 24,
    NOTTY = 25,
    TXTBSY = 26,
    FBIG = 27,
    NOSPC = 28,
    SPIPE = 29,
    ROFS = 30,
    MLINK = 31,
    PIPE = 32,
    DOM = 33,
    RANGE = 34,
    AGAIN = 35,
    INPROGRESS = 36,
    ALREADY = 37,
    NOTSOCK = 38,
    DESTADDRREQ = 39,
    MSGSIZE = 40,
    PROTOTYPE = 41,
    NOPROTOOPT = 42,
    PROTONOSUPPORT = 43,
    SOCKTNOSUPPORT = 44,
    OPNOTSUPP = 45,
    PFNOSUPPORT = 46,
    AFNOSUPPORT = 47,
    ADDRINUSE = 48,
    ADDRNOTAVAIL = 49,
    NETDOWN = 50,
    NETUNREACH = 51,
    NETRESET = 52,
    CONNABORTED = 53,
    CONNRESET = 54,
    NOBUFS = 55,
    ISCONN = 56,
    NOTCONN = 57,
    SHUTDOWN = 58,
    TOOMANYREFS = 59,
    TIMEDOUT = 60,
    CONNREFUSED = 61,
    LOOP = 62,
    NAMETOOLONG = 63,
    HOSTDOWN = 64,
    HOSTUNREACH = 65,
    NOTEMPTY = 66,
    PROCLIM = 67,
    USERS = 68,
    DQUOT = 69,
    STALE = 70,
    REMOTE = 71,
    BADRPC = 72,
    RPCMISMATCH = 73,
    PROGUNAVAIL = 74,
    PROGMISMATCH = 75,
    PROCUNAVAIL = 76,
    NOLCK = 77,
    NOSYS = 78,
    FTYPE = 79,
    AUTH = 80,
    NEEDAUTH = 81,
    IDRM = 82,
    NOMSG = 83,
    OVERFLOW = 84,
    CANCELED = 85,
    ILSEQ = 86,
    NOATTR = 87,
    DOOFUS = 88,
    BADMSG = 89,
    MULTIHOP = 90,
    NOLINK = 91,
    PROTO = 92,
    NOTCAPABLE = 93,
    CAPMODE = 94,

    //
    // PS4's Orbis OS special error codes
    //
    // from Sce.PlayStation.Orbis.dll's Sce.PlayStation.Orbis.Sys.ErrorCode
    NOBLK = 95,
    ICV = 96,
    NOPLAYGOENT = 97,
    REVOKE = 98,
    SDKVERSION = 99,
    // from libSceLibcInternal's _Strerror
    FILEPOS = 152,
    NOMSGAVAIL = 1040, // "No message available"
    NOSTREAM = 1050, // "No stream resources"
    NOTASTREAM = 1051, // "Not a stream"
    NOTRECOVERABLE = 1056, // "State not recoverable"
    OTHER = 1062, // "Other"
    OWNERDEAD = 1064, // "Owner dead"
    STREAMTIMEOUT = 1074, // "Stream timeout"
    _,
};

fn convertErrno(val: i32) E {
    assert(val < 0);
    return @enumFromInt(0x7FFE0000 - val);
}

pub const UnexpectedError = error{
    Unexpected,
};
fn unexpectedErrno(err: E) UnexpectedError {
    std.debug.print("unexpected errno: {}\n", .{err});
    std.debug.dumpCurrentStackTrace(.{});
    return error.Unexpected;
}

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
        if (result < 0) switch (convertErrno(result)) {
            E.FAULT => unreachable,
            E.INVAL => unreachable,
            E.MFILE => return error.SystemResources,
            E.NOMEM => return error.SystemResources,
            E.NAMETOOLONG => return error.NameTooLong,
            else => |err| return unexpectedErrno(err),
        };
        return .{
            .handle = handle,
        };
    }

    pub fn deinit(self: *Self) void {
        const result = sceKernelDeleteEqueue(self.handle);
        if (result < 0) switch (convertErrno(result)) {
            E.BADF => unreachable,
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
        if (result < 0) switch (convertErrno(result)) {
            E.FAULT => unreachable,
            E.INVAL => unreachable,
            E.MFILE => return error.SystemResources,
            E.NOMEM => return error.SystemResources,
            E.NAMETOOLONG => return error.NameTooLong,
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
    if (status < 0) switch (convertErrno(status)) {
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
    if (status < 0) switch (convertErrno(status)) {
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
    if (status < 0) switch (convertErrno(status)) {
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
