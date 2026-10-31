// Ninjajar - levelset.h: la tabla de niveles (ver src/dev/levels.h)
//
// Es la secuencia del original (level_sequence): los niveles se juegan en
// este orden y "level" (LEVEL en los scripts, WARP TO LEVEL, las
// contraseñas) es la posición en ella. La tienda (mapa B) sale varias veces:
// su script mira LEVEL para saber cuál es.

const LEVEL levels [MAX_LEVELS] = {
	// bundle      tileset    spriteset  música  script
	{ RES_LEVELDC, RES_TS1C,  RES_SS1C,  19,     RES_SCRIPTDC   },	//  0: Tutorial
	{ RES_LEVEL5C, RES_TS5C,  RES_SS0C,  0,      RES_SCRIPT5C   },	//  1: Intro
	{ RES_LEVEL0C, RES_TS0C,  RES_SS0C,  17,     NO_RESOURCE    },	//  2: Montaña
	{ RES_LEVEL2C, RES_TS2C,  RES_SS2C,  1,      NO_RESOURCE    },	//  3: Lago verde
	{ RES_LEVELBC, RES_TSBC,  RES_SS0C,  6,      RES_SCRIPTBC   },	//  4: Tienda
	{ RES_LEVEL4C, RES_TS4C,  RES_SS4C,  2,      RES_SCRIPT4C   },	//  5: Llanos del marrano (club)
	{ RES_LEVEL6C, RES_TS2C,  RES_SS2C,  1,      NO_RESOURCE    },	//  6: Pozo poroso
	{ RES_LEVEL8C, RES_TS8C,  RES_SS4C,  0,      RES_SCRIPT8C   },	//  7: Isla de la bruja Sarollán
	{ RES_LEVELBC, RES_TSBC,  RES_SS0C,  6,      RES_SCRIPTBC   },	//  8: Tienda
	{ RES_LEVEL7C, RES_TS4C,  RES_SS4C,  2,      NO_RESOURCE    },	//  9: Llanos 2
	{ RES_LEVEL3C, RES_TS3C,  RES_SS1C,  2,      NO_RESOURCE    },	// 10: Cueva Kave
	{ RES_LEVEL1C, RES_TS1C,  RES_SS1C,  0,      NO_RESOURCE    },	// 11: Bosque de los monos
	{ RES_LEVELBC, RES_TSBC,  RES_SS0C,  6,      RES_SCRIPTBC   },	// 12: Tienda
	{ RES_LEVELAC, RES_TSAC,  RES_SS2C,  11,     RES_SCRIPTAC   },	// 13: Lago oscuro
	{ RES_LEVEL9C, RES_TS9C,  RES_SS1C,  3,      RES_SCRIPT9C   },	// 14: Castillo de la carne de membrillo
	{ RES_LEVELBC, RES_TSBC,  RES_SS0C,  6,      RES_SCRIPTBC   },	// 15: Tienda
	{ RES_LEVELFC, RES_TS0C,  RES_SS0C,  0,      NO_RESOURCE    },	// 16: Pozo de Zenman
	{ RES_LEVELEC, RES_TS3C,  RES_SS1C,  2,      NO_RESOURCE    },	// 17: Cueva de Anju
	{ RES_LEVELCC, RES_TSCC,  RES_SS0C,  2,      RES_SCRIPTCC   },	// 18: Lava
	{ RES_LEVELBC, RES_TSBC,  RES_SS0C,  6,      RES_SCRIPTBC   },	// 19: Tienda
	{ RES_LEVELBC, RES_TSBC,  RES_SS0C,  6,      RES_SCRIPTBC   },	// 20: Tienda
	{ RES_LEVELYC, RES_TSYC,  RES_SS0C,  17,     RES_SCRIPTYC   },	// 21: Final malo (playa)
	{ RES_LEVELZC, RES_TSZC,  RES_SS1C,  3,      RES_SCRIPTZC   },	// 22: Castillo de Gonzalo
	{ RES_LEVELXC, RES_TSXC,  RES_SS0C,  3,      RES_SCRIPTXC   } 	// 23: Final bueno
};
