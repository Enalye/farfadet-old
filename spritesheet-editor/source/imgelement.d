module imgelement;

import atelier;

enum ImgType {
    SpriteType, TilesetType, BorderedBrushType, BorderlessBrushType, NinePatchType
}

class ImgElementData {
    //General data
    ImgType type;

    Vec4i clip;

    //Tileset specific data
    int columns = 1, lines = 1, maxtiles;

    //NinePatch specific data
    int top, bottom, left, right;
}