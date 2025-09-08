/*
 * Copyright 2011-2025 Branimir Karadzic. All rights reserved.
 * License: https://github.com/bkaradzic/bgfx/blob/master/LICENSE
 */

#ifndef BGFX_GLCONTEXT_CGL_H_HEADER_GUARD
#define BGFX_GLCONTEXT_CGL_H_HEADER_GUARD

#if BGFX_USE_CGL
namespace bgfx { namespace gl
{
	struct SwapChainGL;

    struct CGLImp;

	struct GlContext
	{
        GlContext();
        ~GlContext();

		void create(uint32_t _width, uint32_t _height, uint32_t _flags);
		void destroy();
		void resize(uint32_t _width, uint32_t _height, uint32_t _flags);

		uint64_t getCaps() const;
		SwapChainGL* createSwapChain(void* _nwh, int _w, int _h);
		void destroySwapChain(SwapChainGL*  _swapChain);
		void swap(SwapChainGL* _swapChain = NULL);
		void makeCurrent(SwapChainGL* _swapChain = NULL);

		void import();

        bool isValid() const;
        
        CGLImp* m_imp;
        SwapChainGL* m_current;
		// true when MSAA is handled by the context instead of using MSAA FBO
        bool m_msaaContext;
	};
} /* namespace gl */ } // namespace bgfx

#endif // BGFX_USE_CGL

#endif // BGFX_GLCONTEXT_CGL_H_HEADER_GUARD
