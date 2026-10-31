/*
    cpcrslib_mt.h

    CPCRSLIB "Mojon Tilemap" para SDCC, recortada para MK1 v3.100. Solo
    declara lo que el motor usa (ver cpcrslib.lst y README.md).

    Convención: las funciones con un argumento lo reciben en HL (L si es de
    8 bits), __z88dk_fastcall. cpc_TestKey devuelve en L (__sdcccall(0)).
    Las que usan IX tienen una entrada que lo guarda.

    El juego aporta viewport_x y viewport_y (cpc/sysvars.h), tiles (el
    tileset, cpc/tileset.h) y, en la variante fg, behindtilemasks.
*/

#ifndef _CPCRSLIB_MT_H
#define _CPCRSLIB_MT_H

// Pantalla, tilemap y tiles tocados

void cpc_ShowTileMap (unsigned char only_copy) __z88dk_fastcall;
void cpc_UpdScr (void);
void cpc_ShowTouchedTiles (void);
void cpc_ResetTouchedTiles (void);

// Modo de vídeo

void cpc_SetMode (unsigned char mode) __z88dk_fastcall;
void cpc_MakeM1RotationLUTs (void);

// Teclado

unsigned char cpc_TestKey (unsigned char tecla) __sdcccall(0) __z88dk_fastcall;

// Sprites: una rutina por tamaño y formato de pixel. Reciben la dirección
// de la estructura del sprite (SPR, cpc/sysvars.h).

void cpc_PutSpTileMap4x8Px (void *sprite) __z88dk_fastcall;
void cpc_PutSpTileMap8x8Px (void *sprite) __z88dk_fastcall;
void cpc_PutSpTileMap8x8PxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutSpTileMap8x16Px (void *sprite) __z88dk_fastcall;
void cpc_PutSpTileMap8x24Px (void *sprite) __z88dk_fastcall;
void cpc_PutSpTileMap16x16PxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutSpTileMap16x24PxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutSpTileMap12x24CA (void *sprite) __z88dk_fastcall;
void cpc_PutSPTileMap2Bx8 (void *sprite) __z88dk_fastcall;
void cpc_PutSPTileMap4Bx16 (void *sprite) __z88dk_fastcall;
void cpc_PutSPTileMap4Bx24 (void *sprite) __z88dk_fastcall;

void cpc_PutTrSp4x8TileMapPx (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp4x8TileMapGPx (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x8TileMapPx (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x8TileMapPxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x8TileMapGPxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x16TileMapPx (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x16TileMapGPx (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x16TileMapGPxP (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x24TileMapPx (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x24TileMapGPx (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp8x24TileMapGPxP (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp16x16TileMapPxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp16x16TileMapPxM1LUT (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp16x16TileMapGPxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp16x16TileMapGPxM1P (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp16x24TileMapPxM1 (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp16x24TileMapGPxM1P (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp12x24TileMapGCA (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp2Bx8TileMap (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp2Bx8TileMapG (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp4Bx16TileMap (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp4Bx16TileMapG (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp4Bx24TileMap (void *sprite) __z88dk_fastcall;
void cpc_PutTrSp4Bx24TileMapG (void *sprite) __z88dk_fastcall;

#endif
