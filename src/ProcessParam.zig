pub export var sceProcessParam: ProcessParam linksection(".data.sce_process_param") = .{
    .struct_byte_len = @sizeOf(ProcessParam),
    .magic = ProcessParam.MAGIC,
    .struct_version = 5,
    .sdk_version = .{
        .major = 8,
        .minor = 8,
        .patch = 0x12,
    },
    .process_name = null,
    .main_thread_name = null,
    .main_thread_priority = null,
    .main_thread_stack_size = null,
    .libc_param = &sceLibcParam,
    .kernel_mem_param = &sceKernelMemParam,
    .kernel_fs_param = &sceKernelFsParam,
    .process_preload_enabled = null,
};

pub export var sceLibcParam: LibcParam = .{
    .struct_byte_len = @sizeOf(LibcParam),
    .struct_version = 14,
    .is_enabled = @intFromBool(true),
    .heap_size = &sceLibcHeapSize,
    .heap_delayed_alloc = null,
    .heap_extended_alloc = &sceLibcHeapExtendedAlloc,
    .heap_initial_size = null,
    .malloc_replace = &_sceLibcMallocReplace,
    .new_replace = &_sceLibcNewReplace,
    .heap_high_address_alloc = null,
    .is_libc_needed = null,
    .heap_memory_lock = null,
    .internal_memory_size = null,
    .malloc_replace_for_tls = &_sceLibcMallocReplaceForTls,
    .heap_debug_flags = null,
    .std_thread_stack_size = null,
    .internal_memory_debug_flags = null,
    .worker_thread_num = null,
    .worker_thread_priority = null,
    .thread_unnamed_objects = null,
};

pub export var _sceLibcMallocReplace: LibcMallocReplace = .{
    .struct_byte_len = @sizeOf(LibcMallocReplace),
    .struct_version = 2,
    .p_user_malloc_init = null,
    .p_user_malloc_finalize = null,
    .p_user_malloc = null,
    .p_user_free = null,
    .p_user_calloc = null,
    .p_user_realloc = null,
    .p_user_memalign = null,
    .p_user_reallocalign = null,
    .p_user_posix_memalign = null,
    .p_user_malloc_stats = null,
    .p_user_malloc_stats_fast = null,
    .p_user_malloc_usable_size = null,
    .p_user_aligned_alloc = null,
};

pub export var _sceLibcNewReplace: LibcNewReplace = .{
    .struct_byte_len = @sizeOf(LibcNewReplace),
    .struct_version = 3,
    .p_user_new = null,
    .p_user_new2 = null,
    .p_user_new_array = null,
    .p_user_new_array2 = null,
    .p_user_delete = null,
    .p_user_delete2 = null,
    .p_user_delete_array = null,
    .p_user_delete_array2 = null,
    .p_user_delete3 = null,
    .p_user_delete4 = null,
    .p_user_delete_array3 = null,
    .p_user_delete_array4 = null,
    .p_user_new3 = null,
    .p_user_new4 = null,
    .p_user_new_array3 = null,
    .p_user_new_array4 = null,
    .p_user_delete5 = null,
    .p_user_delete6 = null,
    .p_user_delete7 = null,
    .p_user_delete_array5 = null,
    .p_user_delete_array6 = null,
    .p_user_delete_array7 = null,
};

pub export var _sceLibcMallocReplaceForTls: LibcMallocReplaceForTls = .{
    .struct_byte_len = @sizeOf(LibcMallocReplaceForTls),
    .struct_version = 1,
    .p_user_malloc_init_for_tls = null,
    .p_user_malloc_fini_for_tls = null,
    .p_user_malloc_for_tls = null,
    .p_user_posix_memalign_for_tls = null,
    .p_user_free_for_tls = null,
};

pub export var sceKernelMemParam: KernelMemParam = .{
    .struct_byte_len = @sizeOf(KernelMemParam),
    .extended_page_table = null,
    .flexible_memory_size = null,
    .enable_extended_memory_1 = null,
    .extended_gpu_page_table = null,
    .enable_extended_memory_2 = null,
    .extended_cpu_page_table = null,
};

pub export var sceKernelFsParam: KernelFsParam = .{
    .struct_byte_len = @sizeOf(KernelFsParam),
    .dup_dent = null,
};

pub export var sceProcessName: ?[*:0]const u8 = null;
pub export var sceMainThreadName: ?[*:0]const u8 = null;
pub export var sceMainThreadPriority: i32 = 0;
pub export var sceMainThreadStackSize: u64 = 0;
pub export var sceProcessPreloadEnabled: u64 = 0;

pub export var sceLibcHeapSize: u64 = 0xffffffffffffffff;
pub export var sceLibcHeapDelayedAlloc: u32 = 0;
pub export var sceLibcHeapExtendedAlloc: u32 = 1;
pub export var sceLibcHeapInitialSize: u64 = 0;
pub export var sceLibcHeapHighAddressAlloc: u64 = 0;
pub export var Need_sceLibc: u32 = 0;
pub export var sceLibcHeapMemoryLock: u32 = 0;
pub export var sceKernelInternalMemorySize: u64 = 0;
pub export var sceLibcHeapDebugFlags: u32 = 0;
pub export var sceLibcStdThreadStackSize: u64 = 0;
pub export var sceKernelInternalMemoryDebugFlags: u32 = 0;
pub export var sceLibcWorkerThreadNum: u32 = 0;
pub export var sceLibcWorkerThreadPriority: u32 = 0;
pub export var sceLibcThreadUnnamedObjects: u32 = 0;

pub export var sceKernelExtendedPageTable: u64 = 0;
pub export var sceKernelFlexibleMemorySize: u64 = 448 * 1024 * 1024;
pub export var sceKernelExtendedMemory1: u8 = 0;
pub export var sceKernelExtendedMemory2: u8 = 0;
pub export var sceKernelExtendedCpuPageTable: u64 = 0;
pub export var sceKernelExtendedGpuPageTable: u64 = 0;

pub export var sceKernelFsDupDent: u32 = 0;

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
    is_enabled: u32,

    heap_size: *u64,
    heap_delayed_alloc: ?*u32,
    heap_extended_alloc: ?*u32,
    heap_initial_size: ?*u64,
    malloc_replace: *const LibcMallocReplace,
    new_replace: *const LibcNewReplace,
    heap_high_address_alloc: ?*u64,
    is_libc_needed: ?*u32,
    heap_memory_lock: ?*u32,
    internal_memory_size: ?*u64,
    malloc_replace_for_tls: *const LibcMallocReplaceForTls,
    _: u64 = 0,
    heap_debug_flags: ?*u32,
    std_thread_stack_size: ?*u64,
    _2: u64 = 0,
    internal_memory_debug_flags: ?*u32,
    worker_thread_num: ?*u32,
    worker_thread_priority: ?*u32,
    thread_unnamed_objects: ?*u32,

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

    p_user_malloc_init: ?*anyopaque,
    p_user_malloc_finalize: ?*anyopaque,
    p_user_malloc: ?*anyopaque,
    p_user_free: ?*anyopaque,
    p_user_calloc: ?*anyopaque,
    p_user_realloc: ?*anyopaque,
    p_user_memalign: ?*anyopaque,
    p_user_reallocalign: ?*anyopaque,
    p_user_posix_memalign: ?*anyopaque,
    p_user_malloc_stats: ?*anyopaque,
    p_user_malloc_stats_fast: ?*anyopaque,
    p_user_malloc_usable_size: ?*anyopaque,
    p_user_aligned_alloc: ?*anyopaque,

    comptime {
        if (@sizeOf(LibcMallocReplace) != 0x78) {
            @compileError("LibcMallocReplace must be 0x78 long");
        }
    }
};

const LibcNewReplace = extern struct {
    struct_byte_len: u64,
    struct_version: u32,
    _: u32 = 0,

    p_user_new: ?*anyopaque,
    p_user_new2: ?*anyopaque,
    p_user_new_array: ?*anyopaque,
    p_user_new_array2: ?*anyopaque,
    p_user_delete: ?*anyopaque,
    p_user_delete2: ?*anyopaque,
    p_user_delete_array: ?*anyopaque,
    p_user_delete_array2: ?*anyopaque,
    p_user_delete3: ?*anyopaque,
    p_user_delete4: ?*anyopaque,
    p_user_delete_array3: ?*anyopaque,
    p_user_delete_array4: ?*anyopaque,
    p_user_new3: ?*anyopaque,
    p_user_new4: ?*anyopaque,
    p_user_new_array3: ?*anyopaque,
    p_user_new_array4: ?*anyopaque,
    p_user_delete5: ?*anyopaque,
    p_user_delete6: ?*anyopaque,
    p_user_delete7: ?*anyopaque,
    p_user_delete_array5: ?*anyopaque,
    p_user_delete_array6: ?*anyopaque,
    p_user_delete_array7: ?*anyopaque,

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

    p_user_malloc_init_for_tls: ?*anyopaque,
    p_user_malloc_fini_for_tls: ?*anyopaque,
    p_user_malloc_for_tls: ?*anyopaque,
    p_user_posix_memalign_for_tls: ?*anyopaque,
    p_user_free_for_tls: ?*anyopaque,

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
    enable_extended_memory_1: ?*u8,
    extended_gpu_page_table: ?*u64,
    enable_extended_memory_2: ?*u8,
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
