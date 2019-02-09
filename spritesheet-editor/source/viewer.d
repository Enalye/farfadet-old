module viewer;

import std.path;
import std.conv: to;
import atelier;
import editor, imgelement, previewer;

enum BrushType {
    NoType, SelectionType, MovingType, ResizeType
}

final class ViewerGui: GuiElementCanvas {
    private {
        Texture _texture;
        Sprite _sprite;
        Sprite _rect;
        Sprite[4] _resizeCursors;
        Vec2i _selectionStart, _selectionOrigin, _selectionSize, _selectionOldOrigin;
        bool _isSelecting;
        BrushType _brushType = BrushType.SelectionType;

        //Mouse control        
		Vec2f _startMovingCursorPosition, _cursorPosition = Vec2f.zero;
		bool _isGrabbed;
        float _scale = 1f;
        bool _isResizingRectRight, _isResizingRectBottom;
    }

    PreviewerGui previewerGui;
    BrushGui brushSelectGui, brushMoveGui, brushResizeGui;    

    ImgType imgType;
    bool isActive;

    //External settings for Tileset and NinePatch.
    int columns, lines, maxtiles;
    int top, bottom, left, right;

    this() {
        size(Vec2f(screenHeight, screenHeight - 50));
        _rect = fetch!Sprite("editor.rect");

        _resizeCursors[0] = fetch!Sprite("editor.cursor-resize1");
        _resizeCursors[1] = fetch!Sprite("editor.cursor-resize2");
        _resizeCursors[2] = fetch!Sprite("editor.cursor-resize3");
        _resizeCursors[3] = fetch!Sprite("editor.cursor-resize4");
        _resizeCursors[0].size *= 2f;
        _resizeCursors[1].size *= 2f;
        _resizeCursors[2].size *= 2f;
        _resizeCursors[3].size *= 2f;
    }

    override void onCallback(string id) {
        switch(id) {
        case "brush_select":
            toggleBrushSelect();
            break;
        case "brush_move":
            toggleBrushMove();
            break;
        case "brush_resize":
            toggleBrushResize();
            break;
        default:
            break;
        }
    }

    void toggleBrushSelect() {
        if(_brushType == BrushType.SelectionType) {
            _brushType = BrushType.NoType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
        else {
            _brushType = BrushType.SelectionType;
            brushSelectGui.isOn = true;
            brushMoveGui.isOn = false;
            brushResizeGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
    }

    void toggleBrushMove() {
        if(_brushType == BrushType.MovingType) {
            _brushType = BrushType.NoType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
        else {
            _brushType = BrushType.MovingType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = true;
            brushResizeGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor-move");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
    }

    void toggleBrushResize() {
        if(_brushType == BrushType.ResizeType) {
            _brushType = BrushType.NoType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
        else {
            _brushType = BrushType.ResizeType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeGui.isOn = true;

            setResizeCursor();
        }
    }

    override void onEvent(Event event) {
        if(_texture is null)
            return;
        switch(event.type) with(EventType) {
        case MouseUpdate:
            _cursorPosition = event.position;
            Vec2i roundedPosition = to!Vec2i(event.position.round());
            roundedPosition = roundedPosition.clamp(Vec2i.zero, Vec2i(_texture.width, _texture.height));

            if(_isSelecting) {
                brushMouseUpdate(roundedPosition);
            }
            else {
                _isResizingRectRight = (_cursorPosition.x >= (_selectionOrigin.x + (_selectionSize.x >> 1)));
                _isResizingRectBottom = (_cursorPosition.y >= (_selectionOrigin.y + (_selectionSize.y >> 1)));
                setResizeCursor();
            }
            if(_isGrabbed) {
				canvas.position += (_startMovingCursorPosition - event.position);
            }
            generateHint(roundedPosition);
            break;
        case MouseDown:
            _cursorPosition = event.position;
            Vec2i roundedPosition = to!Vec2i(event.position.round());
            roundedPosition = roundedPosition.clamp(Vec2i.zero, Vec2i(_texture.width, _texture.height));

            if(!_isSelecting && isButtonDown(1u)) {
                _isSelecting = true;
                brushMouseDown(roundedPosition);
                generateHint(roundedPosition);
            }
            if(!_isGrabbed && isButtonDown(3u)) {
                _isGrabbed = true;
				_startMovingCursorPosition = event.position;
            }
            break;
        case MouseUp:
            _cursorPosition = event.position;
            Vec2i roundedPosition = to!Vec2i(event.position.round());
            roundedPosition = roundedPosition.clamp(Vec2i.zero, Vec2i(_texture.width, _texture.height));

            if(_isSelecting && !isButtonDown(1u)) {
                brushMouseUp(roundedPosition);
                _isSelecting = false;
                generateHint(roundedPosition);
            }
            if(_isGrabbed && !isButtonDown(3u)) {
				_isGrabbed = false;
                canvas.position += (_startMovingCursorPosition - event.position);
            }
            break;
        case MouseWheel:
            const Vec2f delta = (_cursorPosition - canvas.position) / (canvas.size);
            if(event.position.y > 0f) {
                if(_scale > 0.01f)
                    _scale *= 0.9f;
            }
            else {
                if(_scale < 10f)
                    _scale /= 0.9f;
            }
            canvas.size = size * _scale;
            const Vec2f delta2 = (_cursorPosition - canvas.position) / (canvas.size);
            canvas.position += (delta2 - delta) * canvas.size;
            break;
        default:
            break;
        }
        canvas.position =
            (_texture is null) ? canvas.size / 2f :
            canvas.position.clamp(Vec2f.zero, Vec2f(_texture.width, _texture.height));
    }

    void brushMouseUpdate(Vec2i cursorPosition) {
        final switch(_brushType) with(BrushType) {
        case NoType:
            break;
        case SelectionType:
            resizeSelection(cursorPosition);
            triggerCallback();
            break;
        case ResizeType:
            resize2Selection(cursorPosition);
            triggerCallback();
            break;
        case MovingType:
            _selectionOrigin = _selectionOldOrigin + (cursorPosition - _selectionStart);
            triggerCallback();
            break;
        }
    }

    void brushMouseDown(Vec2i cursorPosition) {
        final switch(_brushType) with(BrushType) {
        case NoType:
            break;
        case SelectionType:
            _selectionStart = cursorPosition;
            _selectionOrigin = _selectionStart;
            _selectionSize = Vec2i.zero;
            triggerCallback();
            break;
        case MovingType:
            if(!cursorPosition.isBetween(_selectionOrigin, _selectionOrigin + _selectionSize)) {
                _isSelecting = false;
                break;
            }
            _selectionStart = cursorPosition;
            _selectionOldOrigin = _selectionOrigin;
            triggerCallback();
            break;
        case ResizeType:
            _isResizingRectRight = (cursorPosition.x >= (_selectionOrigin.x + (_selectionSize.x >> 1)));
            _isResizingRectBottom = (cursorPosition.y >= (_selectionOrigin.y + (_selectionSize.y >> 1)));

            _selectionStart = Vec2i(_selectionOrigin.x + (_isResizingRectRight ? 0 : _selectionSize.x),
                _selectionOrigin.y + (_isResizingRectBottom ? 0 : _selectionSize.y));
            resize2Selection(cursorPosition);
            break;
        }
    }

    void brushMouseUp(Vec2i cursorPosition) {
        final switch(_brushType) with(BrushType) {
        case NoType:
            break;
        case SelectionType:
            resizeSelection(cursorPosition);
            triggerCallback();
            break;
        case ResizeType:
            resize2Selection(cursorPosition);
            triggerCallback();
            break;
        case MovingType:
            _selectionOrigin = _selectionOldOrigin + (to!Vec2i(cursorPosition.round()) - _selectionStart);
            triggerCallback();
            break;
        }
    }

    void setResizeCursor() {
        if(_brushType == BrushType.ResizeType) {
            if(_isResizingRectRight && _isResizingRectBottom) {
                setWindowCursor(_resizeCursors[0]);
            }
            else if(_isResizingRectRight) {
                setWindowCursor(_resizeCursors[1]);
            }
            else if(_isResizingRectBottom) {
                setWindowCursor(_resizeCursors[2]);
            }
            else {
                setWindowCursor(_resizeCursors[3]);
            }
        }
    }

    void setTexture(Texture tex) {
        _texture = tex;
        _sprite = new Sprite(tex);
        _sprite.anchor = Vec2f.zero;

        //Reset camera position
        canvas.position = canvas.size / 2f;
    }

    void setClip(Vec4i clip) {
        _selectionOrigin = clip.xy;
        _selectionSize = clip.zw;
    }

    override void update(float deltaTime) {
        if(!isHovered) {
            _isSelecting = false;
            _isGrabbed = false;
        }

        if(getKeyDown("select"))
            toggleBrushSelect();
        if(getKeyDown("move"))
            toggleBrushMove();
        if(getKeyDown("resize"))
            toggleBrushResize();
    }

    Vec4i getClip() {
        return Vec4i(
            to!int(_selectionOrigin.x), to!int(_selectionOrigin.y), 
            to!int(_selectionSize.x), to!int(_selectionSize.y));
    }

    void generateHint(Vec2i cursorPosition) {
        if(_isSelecting) {
            setHint("[" ~ to!string(cursorPosition.x) ~ "; " ~ to!string(cursorPosition.y) ~ "]",
                "[" ~ to!string(_selectionOrigin.x) ~ "; " ~ to!string(_selectionOrigin.y) ~ "]{n}"
                ~ "[" ~ to!string(_selectionSize.x) ~ "; " ~ to!string(_selectionSize.y) ~ "]");
        }
        else {
            setHint("[" ~ to!string(cursorPosition.x) ~ "; " ~ to!string(cursorPosition.y) ~ "]");
        }
    }

    void resizeSelection(Vec2i cursorPosition) {
        _selectionSize = cursorPosition - _selectionOrigin;
        if(_selectionStart.x > cursorPosition.x) {
            _selectionSize.x = _selectionStart.x - cursorPosition.x;
            _selectionOrigin.x = cursorPosition.x;
        }
        if(_selectionStart.y > cursorPosition.y) {
            _selectionSize.y = _selectionStart.y - cursorPosition.y;
            _selectionOrigin.y = cursorPosition.y;
        }
    }

    void resize2Selection(Vec2i cursorPosition) {
        if(_isResizingRectRight) {
            _selectionSize.x = cursorPosition.x - _selectionStart.x;
            if(cursorPosition.x < _selectionStart.x) {
                _selectionSize.x = _selectionStart.x - cursorPosition.x;
                _selectionOrigin.x = cursorPosition.x;
                _isResizingRectRight = false;
            }
        }
        else {
            _selectionOrigin.x = cursorPosition.x;
            _selectionSize.x = _selectionStart.x - _selectionOrigin.x;
            if(cursorPosition.x > _selectionStart.x) {
                _selectionSize.x = cursorPosition.x - _selectionStart.x;
                _selectionOrigin.x = _selectionStart.x;
                _isResizingRectRight = true;
            }
        }
        if(_isResizingRectBottom) {
            _selectionSize.y = cursorPosition.y - _selectionStart.y;
            if(cursorPosition.y < _selectionStart.y) {
                _selectionSize.y = _selectionStart.y - cursorPosition.y;
                _selectionOrigin.y = cursorPosition.y;
                _isResizingRectBottom = false;
            }
        }
        else {
            _selectionOrigin.y = cursorPosition.y;
            _selectionSize.y = _selectionStart.y - _selectionOrigin.y;
            if(cursorPosition.y > _selectionStart.y) {
                _selectionSize.y = cursorPosition.y - _selectionStart.y;
                _selectionOrigin.y = _selectionStart.y;
                _isResizingRectBottom = true;
            }
        }
        setResizeCursor();
    }

    override void draw() {
        if(_texture !is null && _sprite !is null)
            _sprite.draw(Vec2f.zero);

        if(!isActive)
            return;

        auto rectOrigin = to!Vec2f(_selectionOrigin);
        auto rectSize = to!Vec2f(_selectionSize);
            
        final switch(imgType) with(ImgType) {
        case SpriteType:
            _rect.size = rectSize;
            _rect.color = Color(0f, .5f, 1f, .35f);
            _rect.draw(rectOrigin + rectSize / 2f);
            drawRect(rectOrigin, rectSize, Color.white);
            break;
        case BorderedBrushType:
        case BorderlessBrushType:
            int i;
            enum int[4][15] borders = [
                [1, 1, 0, 0],
                [0, 1, 1, 0],
                [1, 1, 0, 1],
                [1, 1, 1, 0],
                [0, 0, 0, 1],
                [0, 0, 1, 0],
                [1, 0, 1, 0],
                [1, 1, 1, 1],
                [1, 0, 0, 1],
                [0, 0, 1, 1],
                [0, 1, 1, 1],
                [1, 0, 1, 1],
                [0, 1, 0, 0],
                [1, 0, 0, 0],
                [0, 1, 0, 1]
            ];

            _rect.size = rectSize;
            _rect.color = Color(0f, .5f, 1f, .35f);
            _rect.draw(rectOrigin + rectSize / 2f);

            foreach(int y; 0.. 2) {
                foreach(int x; 0.. 8) {
                    Vec2f p = rectOrigin + Vec2f(_selectionSize.x * x, _selectionSize.y * y);
                    Vec2f s = rectSize;

                    drawRect(p, s, (x == 0 && y == 0) ? (Color.white) : (Color.gray));

                    if(x == 0 && y == 0)
                        continue;

                    const Vec2f c = p + (s / 2f);
                    s /= 2f;
                    p = c - s / 2f;

                    drawLine(p, p + Vec2f(0f, s.y), borders[i][0] ? Color.green: Color.blue);
                    drawLine(p, p + Vec2f(s.x, 0f), borders[i][1] ? Color.green: Color.blue);
                    drawLine(p + Vec2f(s.x, 0f), p + s, borders[i][2] ? Color.green: Color.blue);
                    drawLine(p + Vec2f(0f, s.y), p + s, borders[i][3] ? Color.green: Color.blue);
                    i ++;
                }
            }
            break;
        case TilesetType:
            int i;
            drawLoop: foreach(int y; 0.. lines) {
                foreach(int x; 0.. columns) {
                    if(maxtiles != 0 && i >= maxtiles)
                        break drawLoop;

                    if(i == previewerGui.getCurrentAnimFrame()) {
                        _rect.size = rectSize;
                        _rect.color = Color(0f, .5f, 1f, .35f);
                        _rect.draw(rectOrigin + Vec2f(_selectionSize.x * x, _selectionSize.y * y)
                            + rectSize / 2f);
                    }
                    drawRect(
                        rectOrigin + Vec2f(_selectionSize.x * x, _selectionSize.y * y),
                        rectSize,
                        (x == 0 && y == 0) ? (Color.white) : (Color.green));
                    i ++;
                }
            }
            break;
        case NinePatchType:
            _rect.size = rectSize;
            _rect.color = Color(0f, .5f, 1f, .35f);
            _rect.draw(rectOrigin + rectSize / 2f);
            drawLine(rectOrigin + Vec2f(left, 0f), rectOrigin + Vec2f(left, rectSize.y), Color.blue);
            drawLine(rectOrigin + Vec2f(rectSize.x - right, 0f), rectOrigin + Vec2f(rectSize.x - right, rectSize.y), Color.green);
            drawLine(rectOrigin + Vec2f(0f, top), rectOrigin + Vec2f(rectSize.x, top), Color.red);
            drawLine(rectOrigin + Vec2f(0f, rectSize.y - bottom), rectOrigin + Vec2f(rectSize.x, rectSize.y - bottom), Color.yellow);
            drawRect(rectOrigin, rectSize, Color.white);
            break;
        }
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.white);
    }
}