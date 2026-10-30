/* Linux drop-in replacement for the old Windows-only libfbpng used by the
 * MK1 utilities. Implements the same C ABI declared in fbpng.bi on top of
 * stb_image / stb_image_write. Always returns new-style 32bpp FB images.
 * FreeBASIC strings are passed byref as FBSTRING descriptors.
 */
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image.h"
#include "stb_image_write.h"
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

extern void *fb_GfxImageCreate(int w, int h, unsigned int color, int depth, int flags);
extern void fb_GfxImageDestroy(void *img);

typedef struct { char *data; intptr_t len; intptr_t size; } FBSTRING;

typedef struct __attribute__((packed)) {
	uint32_t type; int32_t bpp; uint32_t width, height, pitch; uint8_t reserved[12];
} FBIMAGE;

static void *to_fb(unsigned char *rgba, int w, int h) {
	/* Allocate through the FB runtime so ImageDestroy can free it (FB uses aligned blocks). */
	FBIMAGE *img = fb_GfxImageCreate(w, h, 0, 32, 0);
	if (!img) return NULL;
	uint32_t pitch = img->pitch;
	uint8_t *px = (uint8_t *)(img + 1);
	for (int y = 0; y < h; y++) {
		uint32_t *row = (uint32_t *)(px + (size_t)y * pitch);
		for (int x = 0; x < w; x++) {
			unsigned char *s = rgba + ((size_t)y * w + x) * 4;
			row[x] = ((uint32_t)s[3] << 24) | ((uint32_t)s[0] << 16) | ((uint32_t)s[1] << 8) | s[2];
		}
	}
	return img;
}

void *png_load(FBSTRING *fn, int target) {
	int w, h, n; (void)target;
	if (!fn || !fn->data) return NULL;
	unsigned char *d = stbi_load(fn->data, &w, &h, &n, 4);
	if (!d) return NULL;
	void *r = to_fb(d, w, h); stbi_image_free(d); return r;
}

void *png_load_mem(void *buf, intptr_t len, int target) {
	int w, h, n; (void)target;
	unsigned char *d = stbi_load_from_memory(buf, (int)len, &w, &h, &n, 4);
	if (!d) return NULL;
	void *r = to_fb(d, w, h); stbi_image_free(d); return r;
}

intptr_t png_save(FBSTRING *fn, void *vimg) {
	FBIMAGE *img = vimg; if (!img || !fn || !fn->data) return 0;
	int w = img->width, h = img->height;
	unsigned char *out = malloc((size_t)w * h * 4);
	uint8_t *px = (uint8_t *)(img + 1);
	for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
		uint32_t c = ((uint32_t *)(px + (size_t)y * img->pitch))[x];
		unsigned char *d = out + ((size_t)y * w + x) * 4;
		d[0] = c >> 16; d[1] = c >> 8; d[2] = c; d[3] = 255;
	}
	int ok = stbi_write_png(fn->data, w, h, 4, out, w * 4);
	free(out); return ok ? -1 : 0;
}

void png_destroy(void *b) { fb_GfxImageDestroy(b); }

void png_dimensions(FBSTRING *fn, uintptr_t *w, uintptr_t *h) {
	int iw = 0, ih = 0, n; if (fn && fn->data) stbi_info(fn->data, &iw, &ih, &n);
	*w = iw; *h = ih;
}

void png_dimensions_mem(void *buf, uintptr_t *w, uintptr_t *h) {
	int iw = 0, ih = 0, n; stbi_info_from_memory(buf, 1 << 24, &iw, &ih, &n);
	*w = iw; *h = ih;
}
