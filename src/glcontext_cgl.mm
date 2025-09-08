/*
 * Copyright 2011-2025 Branimir Karadzic. All rights reserved.
 * License: https://github.com/bkaradzic/bgfx/blob/master/LICENSE
 */

#include "bgfx_p.h"
#include <Cocoa/Cocoa.h>
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLTypes.h>
#include <OpenGL/CGLContext.h>
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#if (BGFX_CONFIG_RENDERER_OPENGLES || BGFX_CONFIG_RENDERER_OPENGL)
#    include "renderer_gl.h"

#if BGFX_USE_CGL

#define _CGL_CHECK(_check, _call)                                   \
	BX_MACRO_BLOCK_BEGIN                                            \
	BX_MACRO_BLOCK_END

#if BGFX_CONFIG_DEBUG
#	define EGL_CHECK(_call) _CGL_CHECK(BX_ASSERT, _call)
#else
#	define EGL_CHECK(_call) _call
#endif // BGFX_CONFIG_DEBUG

namespace bgfx { namespace gl
{
#	define GL_IMPORT(_optional, _proto, _func, _import) _proto _func
#	include "glimports.h"
#	undef GL_IMPORT

	struct SwapChainGL
	{
		SwapChainGL(CGLContextObj _context, NSWindow* _nwh, int _width, int _height)
		{

			
		}

		~SwapChainGL()
		{
			
		}

		void makeCurrent()
		{
		}

		void swapBuffers()
		{
		}
	};

    struct CGLImp
    {
        NSApplication* m_app{nullptr};
        NSWindow* m_window{nullptr};
        NSView* m_contentView{nullptr};
        NSOpenGLContext* m_context{nullptr};
        NSOpenGLPixelFormat* m_pixelFormat{nullptr};
        CGLContextObj m_cglContext{nullptr};
        CGLPixelFormatObj m_cglPixelFormat;
    };

    GlContext::GlContext()
    {
        m_imp = new CGLImp();
        m_msaaContext = false;
        m_current = nullptr;
    }

    GlContext::~GlContext()
    {
        destroy();
        if (m_imp)
        {
            delete m_imp;
            m_imp = nullptr;
        }
    }

	void GlContext::create(uint32_t _width, uint32_t _height, uint32_t _flags)
	{
		BX_UNUSED(_flags);

        if (NULL != g_platformData.nwh && NULL == g_platformData.context )
        {
            NSOpenGLPixelFormatAttribute attrs[] = {
                NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
                NSOpenGLPFAAccelerated,
                NSOpenGLPFADoubleBuffer,
                0
            };
            NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

            NSWindow* window = (NSWindow*)g_platformData.nwh;
            NSRect frame = [window contentView].frame;

            NSOpenGLView* view = [[NSOpenGLView alloc] initWithFrame:frame pixelFormat:fmt];
            [window setContentView:view];
            [window makeKeyAndOrderFront:nil];

            // Optional: get CGLContextObj
            m_imp->m_cglContext = [view.openGLContext CGLContextObj];
            [view.openGLContext makeCurrentContext];
            
            m_imp->m_context = [view openGLContext];
        }

		import();

		g_internalData.context = m_imp->m_cglContext;
	}

	void GlContext::destroy()
	{
        CGLSetCurrentContext(NULL);   // Unbind context first
        if (m_imp->m_cglContext)
        {
            CGLDestroyContext(m_imp->m_cglContext);
            m_imp->m_cglContext = nullptr;
        }
        if (m_imp->m_cglPixelFormat)
        {
            CGLReleasePixelFormat(m_imp->m_cglPixelFormat);
            m_imp->m_cglPixelFormat = nullptr;
        }
	}

	void GlContext::resize(uint32_t _width, uint32_t _height, uint32_t _flags)
	{

	}

	uint64_t GlContext::getCaps() const
	{
		return BX_ENABLED(0
			| BX_PLATFORM_LINUX
			| BX_PLATFORM_WINDOWS
			| BX_PLATFORM_ANDROID
            | BX_PLATFORM_OSX
			)
			? BGFX_CAPS_SWAP_CHAIN
			: 0
			;
	}

	SwapChainGL* GlContext::createSwapChain(void* _nwh, int _width, int _height)
	{
		return BX_NEW(g_allocator, SwapChainGL)(m_imp->m_cglContext, (NSWindow*)_nwh, _width, _height);
	}

	void GlContext::destroySwapChain(SwapChainGL* _swapChain)
	{
		bx::deleteObject(g_allocator, _swapChain);
	}

	void GlContext::swap(SwapChainGL* _swapChain)
	{
		makeCurrent(_swapChain);

		if (NULL == _swapChain)
		{
			if (NULL != m_imp->m_context)
			{
                [m_imp->m_context flushBuffer];
			}
		}
		else
		{
			_swapChain->swapBuffers();
		}
	}

	void GlContext::makeCurrent(SwapChainGL* _swapChain)
	{
		if (m_current != _swapChain)
		{
            m_current = _swapChain;

			if (NULL == _swapChain)
			{
				if (NULL != m_imp->m_context)
				{
                    [m_imp->m_context makeCurrentContext];
				}
			}
			else
			{
				_swapChain->makeCurrent();
			}
		}
	}

    bool GlContext::isValid() const
    {
        return NULL != m_imp->m_cglContext;
    }

    void* CGLGetProcAddress(const char* name) {
        static void* image = NULL;
        if (!image) {
            image = bx::dlopen("/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL");
        }
        return image ? bx::dlsym(image, name) : NULL;
    }

	void GlContext::import()
	{
		BX_TRACE("Import:");

#		define GL_EXTENSION(_optional, _proto, _func, _import)                           \
			{                                                                            \
				if (NULL == _func)                                                       \
				{                                                                        \
					_func = reinterpret_cast<_proto>(CGLGetProcAddress(#_import) );      \
					BX_TRACE("\t%p " #_func " (" #_import ")", _func);                   \
					BGFX_FATAL(_optional || NULL != _func                                \
						, Fatal::UnableToInitialize                                      \
						, "Failed to create OpenGL context. CGLGetProcAddress(\"%s\")" \
						, #_import);                                                     \
				}                                                                        \
			}

#	include "glimports.h"

#	undef GL_EXTENSION
	}

} /* namespace gl */ } // namespace bgfx

#	endif // BGFX_USE_CGL
#endif // (BGFX_CONFIG_RENDERER_OPENGLES || BGFX_CONFIG_RENDERER_OPENGL)
