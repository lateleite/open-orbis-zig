const options = @import("options");

pub export var processParam: ProcessParam linksection(".data.sce_process_param") = .{
    .struct_byte_len = @sizeOf(ProcessParam),
    .magic = ProcessParam.MAGIC,
    .struct_version = 5,
    .sdk_version = .{
        .major = options.sdk_version_major,
        .minor = options.sdk_version_minor,
        .patch = options.sdk_version_patch,
    },
    .process_name = if (options.process_name) |name|
        name.ptr
    else
        null,
    .main_thread_name = if (options.main_thread_name) |name|
        name.ptr
    else
        null,
    .main_thread_priority = if (options.main_thread_priority) |val|
        &val
    else
        null,
    .main_thread_stack_size = if (options.main_thread_stack_size) |val|
        &val
    else
        null,
    .libc_param = &libcParam,
    .kernel_mem_param = &kernelMemParam,
    .kernel_fs_param = &kernelFsParam,
    .process_preload_enabled = if (options.process_preload_enabled) |val|
        &val
    else
        null,
};

pub export var libcParam: LibcParam = .{
    .struct_byte_len = @sizeOf(LibcParam),
    .struct_version = 14,
    .is_internal_heap = @intFromBool(true),
    .malloc_replace = &libcMallocReplace,
    .new_replace = &libcNewReplace,
    .is_libc_needed = null,
    .malloc_replace_for_tls = &libcMallocReplaceForTls,
};

pub export var libcMallocReplace: LibcMallocReplace = .{
    .struct_byte_len = @sizeOf(LibcMallocReplace),
    .struct_version = 1,
};

pub export var libcNewReplace: LibcNewReplace = .{
    .struct_byte_len = @sizeOf(LibcNewReplace),
    .struct_version = 3,
};

pub export var libcMallocReplaceForTls: LibcMallocReplaceForTls = .{
    .struct_byte_len = @sizeOf(LibcMallocReplaceForTls),
    .struct_version = 1,
};

pub export var kernelMemParam: KernelMemParam = .{
    .struct_byte_len = @sizeOf(KernelMemParam),
    .extended_page_table = if (options.extended_page_table) |val|
        &val
    else
        null,
    .flexible_memory_size = if (options.flexible_memory_size) |val|
        &val
    else
        null,
    .extended_memory_1 = if (options.extended_memory_1) |val|
        &val
    else
        null,
    .extended_gpu_page_table = if (options.extended_gpu_page_table) |val|
        &val
    else
        null,
    .extended_memory_2 = if (options.extended_memory_2) |val|
        &val
    else
        null,
    .extended_cpu_page_table = if (options.extended_cpu_page_table) |val|
        &val
    else
        null,
};

pub export var kernelFsParam: KernelFsParam = .{
    .struct_byte_len = @sizeOf(KernelFsParam),
    .dup_dent = null,
};

const ProcessParam = extern struct {
    struct_byte_len: u64,
    magic: [4]u8,
    struct_version: u32,
    sdk_version: packed struct(u64) {
        major: u8,
        minor: u12,
        patch: u12,
        _: u32 = 0,
    },
    process_name: ?[*:0]const u8,
    main_thread_name: ?[*:0]const u8,
    main_thread_priority: ?*i32,
    main_thread_stack_size: ?*u64,
    libc_param: ?*const LibcParam,
    kernel_mem_param: ?*const KernelMemParam,
    kernel_fs_param: ?*const KernelFsParam,
    process_preload_enabled: ?*u64,
    _: u64 = 0,

    const MAGIC: [4]u8 = .{ 'O', 'R', 'B', 'I' };

    comptime {
        if (@sizeOf(ProcessParam) != 0x60) {
            @compileError("ProcessParam must be 0x60 long");
        }
    }
};

const LibcParam = extern struct {
    struct_byte_len: u64,
    struct_version: u32,
    is_internal_heap: u32,

    _unused_fields: [4]u64 = @splat(0),

    malloc_replace: *const LibcMallocReplace,
    new_replace: *const LibcNewReplace,

    _unused_fields2: [1]u64 = @splat(0),

    is_libc_needed: ?*u32,

    _unused_fields3: [2]u64 = @splat(0),

    malloc_replace_for_tls: *const LibcMallocReplaceForTls,

    _unused_fields4: [8]u64 = @splat(0),

    comptime {
        if (@sizeOf(LibcParam) != 0xa8) {
            @compileError("LibcParam must be 0xa8 long");
        }
    }
};

const LibcMallocReplace = extern struct {
    struct_byte_len: u64,
    struct_version: u32,
    _: u32 = 0,

    _unused_fields: [12]u64 = @splat(0),

    comptime {
        if (@sizeOf(LibcMallocReplace) != 0x70) {
            @compileError("LibcMallocReplace must be 0x70 long");
        }
    }
};

const LibcNewReplace = extern struct {
    struct_byte_len: u64,
    struct_version: u32,
    _: u32 = 0,

    _unused_fields: [22]u64 = @splat(0),

    comptime {
        if (@sizeOf(LibcNewReplace) != 0xc0) {
            @compileError("LibcNewReplace must be 0xc0 long");
        }
    }
};

const LibcMallocReplaceForTls = extern struct {
    struct_byte_len: u64,
    struct_version: u32,
    _: u32 = 0,

    _unused_fields: [5]u64 = @splat(0),

    comptime {
        if (@sizeOf(LibcMallocReplaceForTls) != 0x38) {
            @compileError("LibcMallocReplaceForTls must be 0x38 long");
        }
    }
};

const KernelMemParam = extern struct {
    struct_byte_len: u64,

    extended_page_table: ?*u64,
    flexible_memory_size: ?*u64,
    extended_memory_1: ?*bool,
    extended_gpu_page_table: ?*u64,
    extended_memory_2: ?*bool,
    extended_cpu_page_table: ?*u64,

    comptime {
        if (@sizeOf(KernelMemParam) != 0x38) {
            @compileError("KernelMemParam must be 0x38 long");
        }
    }
};

const KernelFsParam = extern struct {
    struct_byte_len: u64,

    dup_dent: ?*u32,

    comptime {
        if (@sizeOf(KernelFsParam) != 0x10) {
            @compileError("KernelFsParam must be 0x10 long");
        }
    }
};
