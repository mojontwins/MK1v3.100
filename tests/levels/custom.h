// custom.h de la prueba de niveles: TEST_START_LEVEL elige el nivel inicial
// y el gancho de entrada de pantalla deja una marca en memoria para el test.
#define HOOK_AFTER_TITLE
unsigned char hook_after_title (void) {
	return TEST_START_LEVEL;
}

unsigned char test_screens_entered;
#define HOOK_ENTERING_SCREEN
void hook_entering_screen (void) {
	test_screens_entered ++;
}
