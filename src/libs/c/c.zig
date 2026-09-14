const orbis = @import("orbis");

export fn __dummy__libc_func() i32 {
    return 0;
}

export var my_rw_data: i32 = 123456;

comptime {
    orbis.useModuleSection();
    _ = &sceKernelGetDirectMemorySize; // force reference so libkernel is loaded
    _ = &my_rw_data;
}

extern "kernel" fn sceKernelGetDirectMemorySize() void;
