#define V8_COMPRESS_POINTERS

#include <v8.h>
#include <libplatform/libplatform.h>

extern "C"
{
	void v8_hs_initialize()
	{
		std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
		v8::V8::InitializePlatform(platform.get());
		v8::V8::Initialize();
	}
}
