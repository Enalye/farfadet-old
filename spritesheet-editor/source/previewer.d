module previewer;

import std.conv: to;
import atelier;
import imgelement;

class PreviewerGui: GuiElement {
    private {
        Sprite _sprite;
        Tileset _tileset;
        Animation _animation;
        NinePatch _ninePatch;
        Texture _texture;
    }

    //General data
    ImgType type;

    Vec4i clip;

    //Tileset specific data
    int columns = 1, lines = 1, maxtiles;

    //NinePatch specific data
    int top, bottom, left, right;

    Slider playbackSpeedSlider;

    bool isActive;

    this() {
        size(Vec2f.one * (screenWidth - screenHeight) / 2f);
        _sprite = new Sprite;
        _tileset = new Tileset;
        _animation = new Animation;
        _animation.tileset = _tileset;
        _animation.start(1f, TimeMode.Loop);
        _ninePatch = new NinePatch;
        _ninePatch.size = size;
    }

    override void onCallback(string id) {
        if(id == "speed") {
            _animation.timer.duration = 1f / playbackSpeedSlider.fvalue;
        }
    }

    override void update(float deltaTime) {
        if(_sprite !is null) {
            _sprite.clip = clip;
            _sprite.size = size;
        }
        if(_tileset !is null) {
            _tileset.clip = clip;
            _tileset.columns = columns;
            _tileset.lines = lines;
            _tileset.maxtiles = maxtiles;
            _tileset.size = size;
            _animation.update(deltaTime);
        }
        if(_ninePatch !is null) {
            _ninePatch.clip = clip;
            _ninePatch.top = top;
            _ninePatch.bottom = bottom;
            _ninePatch.left = left;
            _ninePatch.right = right;
        }
    }

    override void draw() {
        if(!isActive)
            return;
        if(_texture is null)
            return;
        final switch(type) with(ImgType) {
        case SpriteType:
            _sprite.fit(size);
            _sprite.draw(center);
            break;
        case BorderedBrushType:
            _sprite.fit(size);
            _sprite.draw(center);
            break;
        case BorderlessBrushType:
            _sprite.fit(size);
            _sprite.draw(center);
            break;
        case TilesetType:
            _animation.tileset.fit(size);
            _animation.draw(center);
            break;
        case NinePatchType:
            _ninePatch.draw(center);
            break;
        }
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.white);
    }

    void setTexture(Texture tex) {
        _texture = tex;
        _sprite.texture = tex;
        _tileset.texture = tex;
        _ninePatch.texture = tex;
    }

    int getCurrentAnimFrame() {
		const float id = floor(lerp(0f, to!float(_tileset.maxtiles), _animation.timer.time));
        return to!uint(id);
    }
}