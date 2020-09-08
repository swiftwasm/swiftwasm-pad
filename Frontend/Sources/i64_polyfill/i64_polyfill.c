#include <stddef.h>
#include <stdint.h>

typedef uint16_t __wasi_errno_t;
typedef int __wasi_fd_t;
typedef uint32_t __wasi_lookupflags_t;
typedef uint16_t __wasi_oflags_t;
typedef uint64_t __wasi_rights_t;

typedef uint32_t __wasi_rights_head_t;
typedef uint32_t __wasi_rights_tail_t;

typedef uint16_t __wasi_fdflags_t;

__wasi_errno_t __wasi_i64_polyfill_path_open(
    __wasi_fd_t fd,

    /**
     * Flags determining the method of how the path is resolved.
     */
    __wasi_lookupflags_t dirflags,

    /**
     * The relative path of the file or directory to open, relative to the
     * `path_open::fd` directory.
     */
    const char *path,

    /**
     * The length of the buffer pointed to by `path`.
     */
    size_t path_len,

    /**
     * The method by which to open the file.
     */
    __wasi_oflags_t oflags,

    /**
     * The initial rights of the newly created file descriptor. The
     * implementation is allowed to return a file descriptor with fewer rights
     * than specified, if and only if those rights do not apply to the type of
     * file being opened.
     * The *base* rights are rights that will apply to operations using the file
     * descriptor itself, while the *inheriting* rights are rights that apply to
     * file descriptors derived from it.
     */
    __wasi_rights_head_t fs_rights_base_head,
    __wasi_rights_tail_t fs_rights_base_tail,
    __wasi_rights_head_t fs_rights_inherting_head,
    __wasi_rights_tail_t fs_rights_inherting_tail,

    __wasi_fdflags_t fdflags,

    /**
     * The file descriptor of the file that has been opened.
     */
    __wasi_fd_t *opened_fd
) __attribute__((
    __import_module__("i64_polyfill"),
    __import_name__("path_open"),
    __warn_unused_result__
));

__wasi_errno_t __wasi_path_open(
    __wasi_fd_t fd,
    __wasi_lookupflags_t dirflags,
    const char *path,
    size_t path_len,
    __wasi_oflags_t oflags,
    __wasi_rights_t fs_rights_base,
    __wasi_rights_t fs_rights_inherting,
    __wasi_fdflags_t fdflags,
    __wasi_fd_t *opened_fd
) {
  __wasi_rights_head_t fs_rights_base_head = (fs_rights_base & 0xffff0000) >> 4;
  __wasi_rights_tail_t fs_rights_base_tail = (fs_rights_base & 0x0000ffff);
  __wasi_rights_head_t fs_rights_inherting_head = (fs_rights_inherting & 0xffff0000) >> 4;
  __wasi_rights_tail_t fs_rights_inherting_tail = (fs_rights_inherting & 0x0000ffff);
  return __wasi_i64_polyfill_path_open(fd, dirflags, path, path_len, oflags,
                                       fs_rights_base_head, fs_rights_base_tail,
                                       fs_rights_inherting_head, fs_rights_inherting_tail,
                                       fdflags, opened_fd);
}
