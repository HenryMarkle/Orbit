#include <Orbit/Lua/memory.h>

extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

namespace Orbit::Lua {

// Alternative simpler version using aligned_alloc (C11/POSIX)
#ifdef _POSIX_C_SOURCE
void* AlignedAllocator(void *ud, void *ptr, size_t osize, size_t nsize) {
    (void)ud;
    
    if (nsize == 0) {
        free(ptr);
        return NULL;
    }
    
    if (ptr == NULL) {
        // aligned_alloc requires size to be multiple of alignment
        size_t aligned_size = ALIGN_UP(nsize);
        return aligned_alloc(ALIGN_SIZE, aligned_size);
    }
    
    // For realloc, we need to allocate new, copy, and free old
    size_t aligned_size = ALIGN_UP(nsize);
    void *new_ptr = aligned_alloc(ALIGN_SIZE, aligned_size);
    if (!new_ptr) return NULL;
    
    size_t copy_size = (osize < nsize) ? osize : nsize;
    memcpy(new_ptr, ptr, copy_size);
    free(ptr);
    
    return new_ptr;
}
#else
void* AlignedAllocator(void *ud, void *ptr, size_t osize, size_t nsize) {
    (void)ud;  // Unused parameter
    
    if (nsize == 0) {
        // Free memory
        if (ptr) {
            // Get the original pointer stored before the aligned block
            void **real_ptr = (void**)((char*)ptr - sizeof(void*));
            free(*real_ptr);
        }
        return NULL;
    }
    
    if (ptr == NULL) {
        // Allocate new memory
        size_t aligned_size = ALIGN_UP(nsize);
        // Allocate extra space for storing original pointer and alignment
        size_t total_size = aligned_size + ALIGN_SIZE + sizeof(void*);
        
        void *real_ptr = malloc(total_size);
        if (!real_ptr) return NULL;
        
        // Calculate aligned address
        uintptr_t addr = (uintptr_t)real_ptr + sizeof(void*);
        uintptr_t aligned_addr = ALIGN_UP(addr);
        
        // Store original pointer just before the aligned block
        void **stored_ptr = (void**)(aligned_addr - sizeof(void*));
        *stored_ptr = real_ptr;
        
        return (void*)aligned_addr;
    }
    
    // Realloc case
    void **real_ptr_loc = (void**)((char*)ptr - sizeof(void*));
    void *old_real_ptr = *real_ptr_loc;
    
    // Allocate new aligned block
    size_t aligned_size = ALIGN_UP(nsize);
    size_t total_size = aligned_size + ALIGN_SIZE + sizeof(void*);
    
    void *new_real_ptr = malloc(total_size);
    if (!new_real_ptr) return NULL;
    
    // Calculate new aligned address
    uintptr_t addr = (uintptr_t)new_real_ptr + sizeof(void*);
    uintptr_t aligned_addr = ALIGN_UP(addr);
    
    // Store original pointer
    void **new_stored_ptr = (void**)(aligned_addr - sizeof(void*));
    *new_stored_ptr = new_real_ptr;
    
    // Copy old data
    size_t copy_size = (osize < nsize) ? osize : nsize;
    memcpy((void*)aligned_addr, ptr, copy_size);
    
    // Free old memory
    free(old_real_ptr);
    
    return (void*)aligned_addr;
}

#endif
};

