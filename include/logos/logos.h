#ifndef __LOGOS_H
#define __LOGOS_H

#ifndef LOGOS_INLINE
	#if defined(__GNUC__)
		#define LOGOS_INLINE static __inline__ __attribute__((always_inline))
	#elif defined(__cplusplus)
		#define LOGOS_INLINE static inline
	#else
		#define LOGOS_INLINE static
	#endif
#endif

#endif
