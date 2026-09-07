#pragma once

#if defined(__linux__)
#include <dlfcn.h>

static VkResult particles_volk_initialize(void) {
	static void *vulkan_loader;
	if (vulkan_loader == NULL) {
		vulkan_loader = dlopen("libvulkan.so.1", RTLD_NOW | RTLD_LOCAL);
	}
	if (vulkan_loader == NULL) {
		return VK_ERROR_INITIALIZATION_FAILED;
	}
	PFN_vkGetInstanceProcAddr get_instance_proc_addr =
		(PFN_vkGetInstanceProcAddr)dlsym(vulkan_loader, "vkGetInstanceProcAddr");
	if (get_instance_proc_addr == NULL) {
		return VK_ERROR_INITIALIZATION_FAILED;
	}
	volkInitializeCustom(get_instance_proc_addr);
	return vkCreateInstance != NULL ? VK_SUCCESS : VK_ERROR_INITIALIZATION_FAILED;
}
#else
static VkResult particles_volk_initialize(void) {
	return volkInitialize();
}
#endif
