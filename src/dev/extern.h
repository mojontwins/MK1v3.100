// La Churrera Engine 3.100
// Copyleft 2010-2014 the Mojon Twins

// extern.h
// Código propio del juego al que llama el script. Solo se incluye si algún
// script usa EXTERN, TEXT BOX o DIALOG (ver msc.h).

// EXTERN n, m
#ifdef MSC_AU_E4
	void do_extern_action (unsigned char n, unsigned char m) {
		// Escribe aquí tu código: n dice qué hacer y m es un parámetro.
	}
#endif

// TEXT BOX "...": el texto ya descodificado está en msc_text_buf (ASCII, con
// '\n' entre líneas de MSC_TEXT_WIDTH caracteres como mucho). Cada juego lo
// muestra a su manera (un recuadro, esperar una tecla, repintar...).
#ifdef MSC_AU_E6
	void text_box (void) {
	}
#endif

// $F = DIALOG "OPCIÓN 1", "OPCIÓN 2", "OPCIÓN 3": las opciones están en
// msc_options [0], [1] y [2] (las que no hay, vacías) y cuántas hay en
// msc_n_options. Se presentan, el jugador elige y se devuelve 1, 2 o 3.
#ifdef MSC_RV_E6
	unsigned char dialog_box (void) {
		return 1;
	}
#endif
