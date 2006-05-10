/*
 * Build with: gcc -W -Wall -shared -o q.so q.c
 */

#include <dlfcn.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <stdio.h>

void go(void) __attribute__((constructor));

void go(void) {
	void* qh;
	unsigned char *__real_errno_location, *__vm_errno_location;

	qh = dlopen("libc.so.6", RTLD_GLOBAL);
	__real_errno_location = dlsym(qh, "__errno_location");
	__vm_errno_location = dlsym(NULL, "__errno_location");
	printf("Got eroloc %p & %p\n", __vm_errno_location, __real_errno_location);
	if (__real_errno_location && __vm_errno_location && __real_errno_location != __vm_errno_location) {
		unsigned int errnobase = (int)__vm_errno_location;
		unsigned int mpbase = errnobase & ~0xFFF;
		unsigned int mplen = 4096;
		if (errnobase + 5 > mpbase + mplen) {
			mplen = mplen + 4096;
		}
		mprotect((void*)mpbase, mplen, PROT_READ|PROT_WRITE|PROT_EXEC);
		*__vm_errno_location = 0xE9;
		*(int*)(__vm_errno_location + 1) = __real_errno_location - __vm_errno_location - 5;
		mprotect((void*)mpbase, mplen, PROT_READ|PROT_EXEC);
	}
}
