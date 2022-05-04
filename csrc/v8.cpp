#define V8_COMPRESS_POINTERS

#include <v8.h>
#include <libplatform/libplatform.h>
#include <iostream>

extern "C"
{
	void v8_hs_initialize()
	{
		std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
		v8::Platform *platform_ptr = platform.get();
		platform.release();
		v8::V8::InitializePlatform(platform_ptr);
		v8::V8::Initialize();
	}

	void *v8_hs_new_isolate()
	{
		v8::Isolate::CreateParams create_params;
		create_params.array_buffer_allocator =
			v8::ArrayBuffer::Allocator::NewDefaultAllocator();
		v8::Isolate *isolate = v8::Isolate::New(create_params);
		return static_cast<void *>(isolate);
	}

	void v8_hs_delete_isolate(void *isolate_)
	{
		v8::Isolate *isolate = static_cast<v8::Isolate *>(isolate_);
		isolate->Dispose();
	}
}
