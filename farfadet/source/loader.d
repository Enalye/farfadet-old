module loader;

import std.file, std.path, std.conv;
import atelier;

void loadAssets() {
    loadTextures();
    loadFonts();
}

void loadTextures() {
    auto textureCache = new ResourceCache!Texture;
    auto spriteCache = new ResourceCache!Sprite;
    auto tilesetCache = new ResourceCache!Tileset;
    auto ninePathCache = new ResourceCache!NinePatch;

    setResourceCache!Texture(textureCache);
    setResourceCache!Sprite(spriteCache);
    setResourceCache!Tileset(tilesetCache);
    setResourceCache!NinePatch(ninePathCache);

	auto files = dirEntries("data/images/", "{*.json}", SpanMode.depth);
    foreach(file; files) {
        JSONValue json = parseJSON(readText(file));

        if(getJsonStr(json, "DOCTYPE") != "IMAGE")
            continue;

        auto srcImage = getJsonStr(json, "texture");
        auto texture = new Texture(srcImage);
        textureCache.set(texture, srcImage);

        auto elementsNode = getJsonArray(json, "elements");

		foreach(JSONValue elementNode; elementsNode) {
            string name = getJsonStr(elementNode, "name");

            auto clipNode = getJson(elementNode, "clip");
            Vec4i clip;
            clip.x = getJsonInt(clipNode, "x", 0);
            clip.y = getJsonInt(clipNode, "y", 0);
            clip.z = getJsonInt(clipNode, "w", 1);
            clip.w = getJsonInt(clipNode, "h", 1);

            switch(getJsonStr(elementNode, "type", "null")) {
            case "sprite":
                auto sprite = new Sprite;
                sprite.clip = clip;
                sprite.size = to!Vec2f(clip.zw);
                sprite.texture = texture;
                spriteCache.set(sprite, name);
                break;
            case "tileset":
                auto tileset = new Tileset;
                tileset.clip = clip;
                tileset.size = to!Vec2f(clip.zw);
                tileset.texture = texture;

                tileset.columns = getJsonInt(elementNode, "columns", 1);
                tileset.lines = getJsonInt(elementNode, "lines", 1);
                tileset.maxtiles = getJsonInt(elementNode, "maxtiles", 0);

                tilesetCache.set(tileset, name);
                break;
            case "ninepatch":
                auto ninePath = new NinePatch;
                ninePath.clip = clip;
                ninePath.size = to!Vec2f(clip.zw);
                ninePath.texture = texture;

                ninePath.top = getJsonInt(elementNode, "top", 0);
                ninePath.bottom = getJsonInt(elementNode, "bottom", 0);
                ninePath.left = getJsonInt(elementNode, "left", 0);
                ninePath.right = getJsonInt(elementNode, "right", 0);

                ninePathCache.set(ninePath, name);
                break;
            default:
                break;
            }
        }
    }
}

void loadFonts() {
    auto fontCache = new ResourceCache!Font;
	setResourceCache!Font(fontCache);


    auto files = dirEntries("media/font/", "{*.ttf}", SpanMode.depth);
    foreach(file; files) {
        fontCache.set(new Font(file), baseName(file, ".ttf"));
    }

    //Font
	setTextStandardFont(new FontCache(fetch!Font("VeraMono")));
	setTextItalicFont(new FontCache(fetch!Font("VeraMoIt")));
	setTextBoldFont(new FontCache(fetch!Font("VeraMoBd")));
	setTextItalicBoldFont(new FontCache(fetch!Font("VeraMoBI")));
}