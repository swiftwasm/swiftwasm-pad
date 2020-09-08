function decodeBigInt(head, tail) {
  return (head << 4) + tail;
}

export function wrapI64Polyfill(wasi) {
    const wasi_path_open = wasi.wasiImport.path_open;
    return {
      path_open: (
        dirfd,
        dirflags,
        pathPtr,
        pathLen,
        oflags,
        fsRightsBaseHead,
        fsRightsBaseTail,
        fsRightsInheritingHead,
        fsRightsInheritingTail,
        fsFlags,
        fd
      ) => {
        return wasi_path_open(
          dirfd,
          dirflags,
          pathPtr,
          pathLen,
          oflags,
          decodeBigInt(fsRightsBaseHead, fsRightsBaseTail),
          decodeBigInt(fsRightsInheritingHead, fsRightsInheritingTail),
          fsFlags,
          fd
        );
      }
    };
}