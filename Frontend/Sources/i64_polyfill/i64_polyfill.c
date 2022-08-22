#include <stdint.h>

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_clock_time_get(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("clock_time_get"),
));
uint32_t __imported_wasi_snapshot_preview1_clock_time_get(
    uint32_t arg0,
    uint64_t arg1,
    uint32_t arg2
) {
    uint32_t arg1_head = (arg1 & 0xffff0000) >> 4;
    uint32_t arg1_tail = (arg1 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_clock_time_get(arg0, arg1_head, arg1_tail, arg2);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_advise(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint32_t arg5
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_advise"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_advise(
    uint32_t arg0,
    uint64_t arg1,
    uint64_t arg2,
    uint32_t arg3
) {
    uint32_t arg1_head = (arg1 & 0xffff0000) >> 4;
    uint32_t arg1_tail = (arg1 & 0x0000ffff);uint32_t arg2_head = (arg2 & 0xffff0000) >> 4;
    uint32_t arg2_tail = (arg2 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_advise(arg0, arg1_head, arg1_tail, arg2_head, arg2_tail, arg3);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_allocate(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_allocate"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_allocate(
    uint32_t arg0,
    uint64_t arg1,
    uint64_t arg2
) {
    uint32_t arg1_head = (arg1 & 0xffff0000) >> 4;
    uint32_t arg1_tail = (arg1 & 0x0000ffff);uint32_t arg2_head = (arg2 & 0xffff0000) >> 4;
    uint32_t arg2_tail = (arg2 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_allocate(arg0, arg1_head, arg1_tail, arg2_head, arg2_tail);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_fdstat_set_rights(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_fdstat_set_rights"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_fdstat_set_rights(
    uint32_t arg0,
    uint64_t arg1,
    uint64_t arg2
) {
    uint32_t arg1_head = (arg1 & 0xffff0000) >> 4;
    uint32_t arg1_tail = (arg1 & 0x0000ffff);uint32_t arg2_head = (arg2 & 0xffff0000) >> 4;
    uint32_t arg2_tail = (arg2 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_fdstat_set_rights(arg0, arg1_head, arg1_tail, arg2_head, arg2_tail);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_filestat_set_size(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_filestat_set_size"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_filestat_set_size(
    uint32_t arg0,
    uint64_t arg1
) {
    uint32_t arg1_head = (arg1 & 0xffff0000) >> 4;
    uint32_t arg1_tail = (arg1 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_filestat_set_size(arg0, arg1_head, arg1_tail);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_filestat_set_times(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint32_t arg5
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_filestat_set_times"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_filestat_set_times(
    uint32_t arg0,
    uint64_t arg1,
    uint64_t arg2,
    uint32_t arg3
) {
    uint32_t arg1_head = (arg1 & 0xffff0000) >> 4;
    uint32_t arg1_tail = (arg1 & 0x0000ffff);uint32_t arg2_head = (arg2 & 0xffff0000) >> 4;
    uint32_t arg2_tail = (arg2 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_filestat_set_times(arg0, arg1_head, arg1_tail, arg2_head, arg2_tail, arg3);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_pread(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint32_t arg5
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_pread"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_pread(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint64_t arg3,
    uint32_t arg4
) {
    uint32_t arg3_head = (arg3 & 0xffff0000) >> 4;
    uint32_t arg3_tail = (arg3 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_pread(arg0, arg1, arg2, arg3_head, arg3_tail, arg4);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_pwrite(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint32_t arg5
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_pwrite"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_pwrite(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint64_t arg3,
    uint32_t arg4
) {
    uint32_t arg3_head = (arg3 & 0xffff0000) >> 4;
    uint32_t arg3_tail = (arg3 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_pwrite(arg0, arg1, arg2, arg3_head, arg3_tail, arg4);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_readdir(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint32_t arg5
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_readdir"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_readdir(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint64_t arg3,
    uint32_t arg4
) {
    uint32_t arg3_head = (arg3 & 0xffff0000) >> 4;
    uint32_t arg3_tail = (arg3 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_readdir(arg0, arg1, arg2, arg3_head, arg3_tail, arg4);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_fd_seek(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("fd_seek"),
));
uint32_t __imported_wasi_snapshot_preview1_fd_seek(
    uint32_t arg0,
    uint64_t arg1,
    uint32_t arg2,
    uint32_t arg3
) {
    uint32_t arg1_head = (arg1 & 0xffff0000) >> 4;
    uint32_t arg1_tail = (arg1 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_fd_seek(arg0, arg1_head, arg1_tail, arg2, arg3);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_path_filestat_set_times(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint32_t arg5,
    uint32_t arg6,
    uint32_t arg7,
    uint32_t arg8
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("path_filestat_set_times"),
));
uint32_t __imported_wasi_snapshot_preview1_path_filestat_set_times(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint64_t arg4,
    uint64_t arg5,
    uint32_t arg6
) {
    uint32_t arg4_head = (arg4 & 0xffff0000) >> 4;
    uint32_t arg4_tail = (arg4 & 0x0000ffff);uint32_t arg5_head = (arg5 & 0xffff0000) >> 4;
    uint32_t arg5_tail = (arg5 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_path_filestat_set_times(arg0, arg1, arg2, arg3, arg4_head, arg4_tail, arg5_head, arg5_tail, arg6);
}

uint32_t i64_polyfill___imported_wasi_snapshot_preview1_path_open(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint32_t arg5,
    uint32_t arg6,
    uint32_t arg7,
    uint32_t arg8,
    uint32_t arg9,
    uint32_t arg10
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("path_open"),
));
uint32_t __imported_wasi_snapshot_preview1_path_open(
    uint32_t arg0,
    uint32_t arg1,
    uint32_t arg2,
    uint32_t arg3,
    uint32_t arg4,
    uint64_t arg5,
    uint64_t arg6,
    uint32_t arg7,
    uint32_t arg8
) {
    uint32_t arg5_head = (arg5 & 0xffff0000) >> 4;
    uint32_t arg5_tail = (arg5 & 0x0000ffff);uint32_t arg6_head = (arg6 & 0xffff0000) >> 4;
    uint32_t arg6_tail = (arg6 & 0x0000ffff);
    return i64_polyfill___imported_wasi_snapshot_preview1_path_open(arg0, arg1, arg2, arg3, arg4, arg5_head, arg5_tail, arg6_head, arg6_tail, arg7, arg8);
}