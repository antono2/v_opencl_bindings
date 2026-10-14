/* Optional process-lifetime OpenCL dispatch. Never unload while native objects exist. */
#ifndef V_OPENCL_RUNTIME_H
#define V_OPENCL_RUNTIME_H
#include <stdlib.h>
#ifdef _WIN32
#include <windows.h>
static INIT_ONCE vcl_once = INIT_ONCE_STATIC_INIT;
static HMODULE vcl_library;
static BOOL CALLBACK vcl_load(PINIT_ONCE once, PVOID parameter, PVOID *context) {
    const char *path = getenv("OPENCL_LIBRARY");
    vcl_library = LoadLibraryA(path && *path ? path : "OpenCL.dll");
    return TRUE;
}
static void *vcl_symbol(const char *name) {
    InitOnceExecuteOnce(&vcl_once, vcl_load, NULL, NULL);
    return vcl_library ? (void *)GetProcAddress(vcl_library, name) : NULL;
}
#else
#include <dlfcn.h>
#include <pthread.h>
static pthread_once_t vcl_once = PTHREAD_ONCE_INIT;
static void *vcl_library;
static void vcl_load(void) {
    const char *path = getenv("OPENCL_LIBRARY");
    if (path && *path) {
        vcl_library = dlopen(path, RTLD_NOW | RTLD_LOCAL);
        return;
    }
#ifdef __APPLE__
    vcl_library = dlopen("/System/Library/Frameworks/OpenCL.framework/OpenCL", RTLD_NOW | RTLD_LOCAL);
#else
    vcl_library = dlopen("libOpenCL.so.1", RTLD_NOW | RTLD_LOCAL);
#endif
}
static void *vcl_symbol(const char *name) {
    pthread_once(&vcl_once, vcl_load);
    return vcl_library ? dlsym(vcl_library, name) : NULL;
}
#endif
#endif
