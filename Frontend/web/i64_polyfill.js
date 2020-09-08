export function wrapI64Polyfill(original) {
  return {
      clock_time_get: (arg0, arg1_head, arg1_tail, arg2) => {
          return original.clock_time_get(arg0, (arg1_head << 4) + arg1_tail, arg2);
      },
      path_open: (arg0, arg1, arg2, arg3, arg4, arg5_head, arg5_tail, arg6_head, arg6_tail, arg7, arg8) => {
          return original.path_open(arg0, arg1, arg2, arg3, arg4, (arg5_head << 4) + arg5_tail, (arg6_head << 4) + arg6_tail, arg7, arg8);
      },
      fd_readdir: (arg0, arg1, arg2, arg3_head, arg3_tail, arg4) => {
          return original.fd_readdir(arg0, arg1, arg2, (arg3_head << 4) + arg3_tail, arg4);
      },
      fd_seek: (arg0, arg1_head, arg1_tail, arg2, arg3) => {
          return original.fd_seek(arg0, (arg1_head << 4) + arg1_tail, arg2, arg3);
      }
  };
}