// Tabla de niveles de la prueba (tests/levels). Con SCRIPTED=1 (run.sh)
// cada nivel lleva su script.
#ifdef ACTIVATE_SCRIPTING
	#define TEST_SCRIPT1 RES_SCRIPT1C
	#define TEST_SCRIPT2 RES_SCRIPT2C
#else
	#define TEST_SCRIPT1 NO_RESOURCE
	#define TEST_SCRIPT2 NO_RESOURCE
#endif

const LEVEL levels [MAX_LEVELS] = {
	// bundle      tileset      spriteset    música  script
	{ RES_LEVEL1C, NO_RESOURCE, NO_RESOURCE, 1,      TEST_SCRIPT1 },
	{ RES_LEVEL2C, RES_TS2C,    NO_RESOURCE, 1,      TEST_SCRIPT2 },
};
