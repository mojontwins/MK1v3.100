/* bin2tap - minimal clone of the classic bin2tap command line used by MK1:
 *     bin2tap [-o out.tap] [-a address] [-n name] in.bin
 * Writes a standard ZX Spectrum CODE header block + data block.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void block(FILE *f, unsigned char flag, const unsigned char *d, int n) {
	unsigned char x = flag; int i;
	fputc((n + 2) & 255, f); fputc((n + 2) >> 8, f); fputc(flag, f);
	for (i = 0; i < n; i++) { fputc(d[i], f); x ^= d[i]; }
	fputc(x, f);
}

int main(int argc, char **argv) {
	const char *in = NULL, *out = NULL, *name = NULL; int addr = 32768, i;
	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-o") && i + 1 < argc) out = argv[++i];
		else if (!strcmp(argv[i], "-a") && i + 1 < argc) addr = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-n") && i + 1 < argc) name = argv[++i];
		else in = argv[i];
	}
	if (!in) { fprintf(stderr, "usage: bin2tap [-o out.tap] [-a addr] [-n name] in.bin\n"); return 1; }

	FILE *fi = fopen(in, "rb"); if (!fi) { perror(in); return 1; }
	fseek(fi, 0, SEEK_END); long n = ftell(fi); rewind(fi);
	if (n > 65535) { fprintf(stderr, "%s: too big\n", in); return 1; }
	unsigned char *d = malloc(n ? n : 1); if (fread(d, 1, n, fi) != (size_t)n) return 1; fclose(fi);

	char outbuf[1024];
	if (!out) { snprintf(outbuf, sizeof outbuf, "%s", in); char *p = strrchr(outbuf, '.'); if (p) *p = 0; strcat(outbuf, ".tap"); out = outbuf; }

	/* Header name: given name, or the input base name, padded to 10 chars */
	unsigned char h[17]; char nm[11]; const char *b = name;
	if (!b) { b = strrchr(out, '/'); b = b ? b + 1 : out; }
	memset(nm, ' ', 10); nm[10] = 0;
	for (i = 0; i < 10 && b[i] && b[i] != '.'; i++) nm[i] = b[i];
	h[0] = 3; memcpy(h + 1, nm, 10);
	h[11] = n & 255; h[12] = n >> 8; h[13] = addr & 255; h[14] = addr >> 8; h[15] = 0; h[16] = 0x80;

	FILE *fo = fopen(out, "wb"); if (!fo) { perror(out); return 1; }
	block(fo, 0x00, h, 17);
	block(fo, 0xff, d, (int)n);
	fclose(fo); free(d);
	return 0;
}
