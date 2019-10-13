module farfadet.gui.previewer;

import std.conv: to;
import atelier;
import farfadet.common;

class PreviewerGui: GuiElement {
    private {
        TabData _currentTabData;
        Sprite _sprite;
        Tileset _tileset;
        Animation _animation;
        NinePatch _ninePatch;
        Texture _texture;
        TimeMode _timeMode;
    }

    //General data
    ElementType type;

    Flip flip;

    Vec4i clip;

    //Tileset specific data
    int columns = 1, lines = 1, maxtiles;

    //NinePatch specific data
    int top, bottom, left, right;

    int marginX, marginY;
    float duration = 1f;
    bool isReverse = false;

    Slider playbackSpeedSlider;

    bool isActive;

    @property {
        TimeMode timeMode(TimeMode mode) {
            if(_timeMode == mode)
                return _timeMode;
            _timeMode = mode;
            if(_timeMode == TimeMode.bounce)
                _animation.start(duration, _timeMode);
            else
                _animation.start(duration, TimeMode.loop);
            return _timeMode;
        }
    }

    this() {
        size(Vec2f.one * (screenWidth - screenHeight) / 2f);
        _sprite = new Sprite;
        _tileset = new Tileset;
        _animation = new Animation;
        _animation.tileset = _tileset;
        _animation.start(duration, TimeMode.loop);
        _ninePatch = new NinePatch;
        _ninePatch.size = size;
    }

    override void onCallback(string id) {
        if(id == "speed") {
            _animation.timer.duration = 1f / playbackSpeedSlider.fvalue;
        }
    }

    override void update(float deltaTime) {
        if(type == ElementType.animation) {
            _animation.timer.duration = duration;
        }
        if(_sprite !is null) {
            _sprite.flip = flip;
            _sprite.clip = clip;
            _sprite.size = size;
        }
        if(_tileset !is null) {
            _tileset.flip = flip;
            _tileset.clip = clip;
            _tileset.columns = columns;
            _tileset.lines = lines;
            _tileset.maxtiles = maxtiles;
            _tileset.size = size;
            _tileset.margin = Vec2i(marginX, marginY);
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
        final switch(type) with(ElementType) {
        case sprite:
            _sprite.fit(size);
            _sprite.draw(center);
            break;
        case borderedBrush:
            _sprite.fit(size);
            _sprite.draw(center);
            break;
        case borderlessBrush:
            _sprite.fit(size);
            _sprite.draw(center);
            break;
        case animation:
        case tileset:
            _animation.tileset.fit(size);
            _animation.draw(center);
            break;
        case ninepatch:
            _ninePatch.draw(center);
            break;
        }
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.white);
    }

    void reload() {
        if(hasTab()) {
            auto tabData = getCurrentTab();
            if(_currentTabData && _currentTabData != tabData) {
                _currentTabData.hasPreviewerData = true;
                _currentTabData.previewerSpeed = playbackSpeedSlider.fvalue;
            }
            _currentTabData = tabData;
            playbackSpeedSlider.fvalue = tabData.hasPreviewerData ? _currentTabData.previewerSpeed : 0f;

            _texture = _currentTabData.texture;
            _sprite.texture = _texture;
            _tileset.texture = _texture;
            _ninePatch.texture = _texture;
        }
        else {
            isActive = false;
        }
    }

    int getCurrentAnimFrame() {
		const float id = floor(lerp(0f, to!float(_tileset.maxtiles), _animation.timer.time));
        return to!uint(id);
    }
}