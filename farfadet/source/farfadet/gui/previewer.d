module farfadet.gui.previewer;

import std.conv: to;
import atelier;
import farfadet.common;

class PreviewerGui: GuiElement {
    private {
        TabData _currentTabData;
        Sprite _sprite;
        Animation _animation;
        NinePatch _ninePatch;
        Texture _texture;
        Timer.Mode _timeMode = Timer.Mode.loop;

        Vec4i _clip;

        //Tileset specific data
        int _columns = 1, _lines = 1, _maxtiles;
        int _marginX, _marginY;
        float _duration = 1f;
    }

    //General data
    ElementType type;

    Flip flip;

    EasingAlgorithm easing = EasingAlgorithm.linear;

    Vec4i clip(Vec4i v) {
        _clip = v;
        makeAnimation();
        return _clip;
    }

    int columns(int v) {
        _columns = v;
        makeAnimation();
        return _columns;
    }

    int lines(int v) {
        _lines = v;
        makeAnimation();
        return _lines;
    }

    int maxtiles(int v) {
        _maxtiles = v;
        makeAnimation();
        return _maxtiles;
    }

    int marginX(int v) {
        _marginX = v;
        makeAnimation();
        return _marginX;
    }

    int marginY(int v) {
        _marginY = v;
        makeAnimation();
        return _marginY;
    }

    private void makeAnimation() {
        _animation.frames.length = 0uL;
		
        int count;
        for(int y; y < _lines; y ++) {
            for(int x; x < _columns; x ++) {
                Vec4i currentClip = Vec4i(
                    _clip.x + x * (_clip.z + _marginX),
                    _clip.y + y * (_clip.w + _marginY),
                    _clip.z,
                    _clip.w);
                _animation.frames ~= currentClip;

                if(_maxtiles > 0) {
                    count ++;
                    if(count >= _maxtiles)
                        return;
                }
            }
        }
    }

    float duration(float v) {
        _duration = v;
        if(_duration <= 0)
            _duration = 1f;
        return _duration;
    }

    //NinePatch specific data
    int top, bottom, left, right;


    Slider playbackSpeedSlider;

    bool isActive;

    @property {
        Timer.Mode animMode(Timer.Mode mode) {
            if(_timeMode == mode)
                return _timeMode;
            _timeMode = mode;
            final switch(_timeMode) with(Timer.Mode) {
            case once:
            case loop:
                _animation.mode = Timer.Mode.loop;
                break;
            case reverse:
            case loopReverse:
                _animation.mode = Timer.Mode.loopReverse;
                break;
            case bounce:
                _animation.mode = Timer.Mode.bounce;
                break;
            case bounceReverse:
                _animation.mode = Timer.Mode.bounceReverse;
                break;
            }
            return _timeMode;
        }
    }

    this() {
        size(Vec2f.one * (screenWidth - screenHeight) / 2f);
        _sprite = new Sprite;
        _animation = new Animation;
        _animation.mode = _timeMode;
        _animation.start();
        _ninePatch = new NinePatch;
        _ninePatch.size = size;
    }

    override void onCallback(string id) {
        if(id == "speed") {
            _animation.duration = 1f / playbackSpeedSlider.fvalue;
        }
    }

    override void update(float deltaTime) {
        if(type == ElementType.animation) {
            _animation.duration = _duration;
            _animation.easing = easing;
        }
        if(_sprite !is null) {
            _sprite.flip = flip;
            _sprite.clip = _clip;
            _sprite.size = size;
        }
        if(_animation !is null) {
            _animation.flip = flip;
            _animation.size = size;
            _animation.update(deltaTime);
        }
        if(_ninePatch !is null) {
            _ninePatch.clip = _clip;
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
            if(_animation.frames.length)
                _animation.size = to!Vec2f(_animation.frames[0].zw).fit(size);
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
            _animation.texture = _texture;
            _ninePatch.texture = _texture;
        }
        else {
            isActive = false;
        }
    }

    int getCurrentAnimFrame() {
		return _animation.currentFrameID;
    }
}