export const wrapWASI = (wasiObject) => {
    // PATCH: @wasmer-js/wasi@0.x forgets to call `refreshMemory` in `clock_res_get`,
    // which writes its result to memory view. Without the refresh the memory view,
    // it accesses a detached array buffer if the memory is grown by malloc.
    // But they wasmer team discarded the 0.x codebase at all and replaced it with
    // a new implementation written in Rust. The new version 1.x is really unstable
    // and not production-ready as far as katei investigated in Apr 2022.
    // So override the broken implementation of `clock_res_get` here instead of
    // fixing the wasi polyfill.
    // Reference: https://github.com/wasmerio/wasmer-js/blob/55fa8c17c56348c312a8bd23c69054b1aa633891/packages/wasi/src/index.ts#L557
    const original_clock_res_get = wasiObject.wasiImport["clock_res_get"];

    wasiObject.wasiImport["clock_res_get"] = (clockId, resolution) => {
        wasiObject.refreshMemory();
        return original_clock_res_get(clockId, resolution);
    };
    return wasiObject.wasiImport;
};
