export function wrapI64Polyfill(original) {
    return {
        clock_time_get: (arg0, arg1_head, arg1_tail, arg2) => {
            return original.clock_time_get(arg0, (arg1_head << 4) + arg1_tail, arg2);
        },
        fd_advise: (arg0, arg1_head, arg1_tail, arg2_head, arg2_tail, arg3) => {
            return original.fd_advise(arg0, (arg1_head << 4) + arg1_tail, (arg2_head << 4) + arg2_tail, arg3);
        },
        fd_allocate: (arg0, arg1_head, arg1_tail, arg2_head, arg2_tail) => {
            return original.fd_allocate(arg0, (arg1_head << 4) + arg1_tail, (arg2_head << 4) + arg2_tail);
        },
        fd_fdstat_set_rights: (arg0, arg1_head, arg1_tail, arg2_head, arg2_tail) => {
            return original.fd_fdstat_set_rights(arg0, (arg1_head << 4) + arg1_tail, (arg2_head << 4) + arg2_tail);
        },
        fd_filestat_set_size: (arg0, arg1_head, arg1_tail) => {
            return original.fd_filestat_set_size(arg0, (arg1_head << 4) + arg1_tail);
        },
        fd_filestat_set_times: (arg0, arg1_head, arg1_tail, arg2_head, arg2_tail, arg3) => {
            return original.fd_filestat_set_times(arg0, (arg1_head << 4) + arg1_tail, (arg2_head << 4) + arg2_tail, arg3);
        },
        fd_pread: (arg0, arg1, arg2, arg3_head, arg3_tail, arg4) => {
            return original.fd_pread(arg0, arg1, arg2, (arg3_head << 4) + arg3_tail, arg4);
        },
        fd_pwrite: (arg0, arg1, arg2, arg3_head, arg3_tail, arg4) => {
            return original.fd_pwrite(arg0, arg1, arg2, (arg3_head << 4) + arg3_tail, arg4);
        },
        fd_readdir: (arg0, arg1, arg2, arg3_head, arg3_tail, arg4) => {
            return original.fd_readdir(arg0, arg1, arg2, (arg3_head << 4) + arg3_tail, arg4);
        },
        fd_seek: (arg0, arg1_head, arg1_tail, arg2, arg3) => {
            return original.fd_seek(arg0, (arg1_head << 4) + arg1_tail, arg2, arg3);
        },
        path_filestat_set_times: (arg0, arg1, arg2, arg3, arg4_head, arg4_tail, arg5_head, arg5_tail, arg6) => {
            return original.path_filestat_set_times(arg0, arg1, arg2, arg3, (arg4_head << 4) + arg4_tail, (arg5_head << 4) + arg5_tail, arg6);
        },
        path_open: (arg0, arg1, arg2, arg3, arg4, arg5_head, arg5_tail, arg6_head, arg6_tail, arg7, arg8) => {
            return original.path_open(arg0, arg1, arg2, arg3, arg4, (arg5_head << 4) + arg5_tail, (arg6_head << 4) + arg6_tail, arg7, arg8);
        }
    };
}