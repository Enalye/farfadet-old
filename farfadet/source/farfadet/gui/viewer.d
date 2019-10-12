module farfadet.gui.viewer;

import std.path;
import std.conv: to;
import atelier;
import farfadet.common;
import farfadet.gui.editor, farfadet.gui.previewer;

enum BrushType {
    NoType, SelectionType, MovingType, ResizeCornerType, ResizeBorderType
}

final class ViewerGui: GuiElementCanvas {
    private {
        TabData _currentTabData;
        Texture _texture;
        Sprite _sprite;
        Sprite _rect;
        Sprite[8] _resizeCursors;
        Vec2i _selectionStart, _selectionOrigin, _selectionSize, _selectionOldOrigin;
        bool _isSelecting;
        BrushType _brushType = BrushType.SelectionType;

        //Mouse control        
		Vec2f _startMovingCursorPosition, _cursorPosition = Vec2f.zero;
		bool _isGrabbed;
        float _scale = 1f;
        bool _isResizingRectRight, _isResizingRectBottom, _isResizingHorizontally;
        Timer _timer;
    }

    PreviewerGui previewerGui;
    BrushGui brushSelectGui, brushMoveGui, brushResizeCornerGui, brushResizeBorderGui;    

    ElementType elementType;
    bool isActive;

    //External settings for Tileset and NinePatch.
    int columns, lines, maxtiles;
    int top, bottom, left, right;
    int marginX, marginY;
    float duration = 1f;

    this() {
        size(Vec2f(screenHeight, screenHeight - 85));
        _rect = fetch!Sprite("editor.rect");

        _resizeCursors[0] = fetch!Sprite("editor.cursor-corner1");
        _resizeCursors[1] = fetch!Sprite("editor.cursor-corner2");
        _resizeCursors[2] = fetch!Sprite("editor.cursor-corner3");
        _resizeCursors[3] = fetch!Sprite("editor.cursor-corner4");
        _resizeCursors[4] = fetch!Sprite("editor.cursor-border1");
        _resizeCursors[5] = fetch!Sprite("editor.cursor-border2");
        _resizeCursors[6] = fetch!Sprite("editor.cursor-border3");
        _resizeCursors[7] = fetch!Sprite("editor.cursor-border4");

        int i = 8;
        while(i --) {
            _resizeCursors[i].size *= 2f;
        }

        _timer.start(5f, TimeMode.bounce);
    }

    override void onCallback(string id) {
        switch(id) {
        case "brush.select":
            toggleBrushSelect();
            break;
        case "brush.move":
            toggleBrushMove();
            break;
        case "brush.resize-corner":
            toggleBrushResizeCorner();
            break;
        case "brush.resize-border":
            toggleBrushResizeBorder();
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
            brushResizeCornerGui.isOn = false;
            brushResizeBorderGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
        else {
            _brushType = BrushType.SelectionType;
            brushSelectGui.isOn = true;
            brushMoveGui.isOn = false;
            brushResizeCornerGui.isOn = false;
            brushResizeBorderGui.isOn = false;

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
            brushResizeCornerGui.isOn = false;
            brushResizeBorderGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
        else {
            _brushType = BrushType.MovingType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = true;
            brushResizeCornerGui.isOn = false;
            brushResizeBorderGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor-move");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
    }

    void toggleBrushResizeCorner() {
        if(_brushType == BrushType.ResizeCornerType) {
            _brushType = BrushType.NoType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeCornerGui.isOn = false;
            brushResizeBorderGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
        else {
            _brushType = BrushType.ResizeCornerType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeCornerGui.isOn = true;
            brushResizeBorderGui.isOn = false;

            setResizeCursor();
        }
    }

    void toggleBrushResizeBorder() {
        if(_brushType == BrushType.ResizeBorderType) {
            _brushType = BrushType.NoType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeCornerGui.isOn = false;
            brushResizeBorderGui.isOn = false;

            auto cursor = fetch!Sprite("editor.cursor");
            cursor.size *= 2f;
            setWindowCursor(cursor);
        }
        else {
            _brushType = BrushType.ResizeBorderType;
            brushSelectGui.isOn = false;
            brushMoveGui.isOn = false;
            brushResizeCornerGui.isOn = false;
            brushResizeBorderGui.isOn = true;

            setResizeCursor();
        }
    }

    override void onEvent(Event event) {
        if(_texture is null)
            return;
        switch(event.type) with(EventType) {
        case mouseUpdate:
            _cursorPosition = event.position;
            Vec2i roundedPosition = to!Vec2i(event.position.round());
            roundedPosition = roundedPosition.clamp(Vec2i.zero, Vec2i(_texture.width, _texture.height));

            if(_isSelecting) {
                brushMouseUpdate(roundedPosition);
            }
            else {
                _isResizingRectRight = (_cursorPosition.x >= (_selectionOrigin.x + (_selectionSize.x >> 1)));
                _isResizingRectBottom = (_cursorPosition.y >= (_selectionOrigin.y + (_selectionSize.y >> 1)));
                _isResizingHorizontally = abs(_cursorPosition.x - (_selectionOrigin.x + (_selectionSize.x >> 1))) >= 
                    abs(_cursorPosition.y - (_selectionOrigin.y + (_selectionSize.y >> 1)));
                setResizeCursor();
            }
            if(_isGrabbed) {
				canvas.position += (_startMovingCursorPosition - event.position);
            }
            generateHint(roundedPosition);
            break;
        case mouseDown:
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
        case mouseUp:
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
        case mouseWheel:
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
        case ResizeCornerType:
            resize2Selection(cursorPosition);
            triggerCallback();
            break;
        case ResizeBorderType:
            resize3Selection(cursorPosition);
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
        case ResizeCornerType:
            _isResizingRectRight = (cursorPosition.x >= (_selectionOrigin.x + (_selectionSize.x >> 1)));
            _isResizingRectBottom = (cursorPosition.y >= (_selectionOrigin.y + (_selectionSize.y >> 1)));

            _selectionStart = Vec2i(_selectionOrigin.x + (_isResizingRectRight ? 0 : _selectionSize.x),
                _selectionOrigin.y + (_isResizingRectBottom ? 0 : _selectionSize.y));
            resize2Selection(cursorPosition);
            break;
        case ResizeBorderType:
            _isResizingRectRight = (cursorPosition.x >= (_selectionOrigin.x + (_selectionSize.x >> 1)));
            _isResizingRectBottom = (cursorPosition.y >= (_selectionOrigin.y + (_selectionSize.y >> 1)));

            _isResizingHorizontally = abs(_cursorPosition.x - (_selectionOrigin.x + (_selectionSize.x >> 1))) >= 
                abs(_cursorPosition.y - (_selectionOrigin.y + (_selectionSize.y >> 1)));

            _selectionStart = Vec2i(_selectionOrigin.x + (_isResizingRectRight ? 0 : _selectionSize.x),
                _selectionOrigin.y + (_isResizingRectBottom ? 0 : _selectionSize.y));
            resize3Selection(cursorPosition);
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
        case ResizeCornerType:
            resize2Selection(cursorPosition);
            triggerCallback();
            break;
        case ResizeBorderType:
            resize3Selection(cursorPosition);
            triggerCallback();
            break;
        case MovingType:
            _selectionOrigin = _selectionOldOrigin + (to!Vec2i(cursorPosition.round()) - _selectionStart);
            triggerCallback();
            break;
        }
    }

    void setResizeCursor() {
        if(_brushType == BrushType.ResizeCornerType) {
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
        else if(_brushType == BrushType.ResizeBorderType) {
            if(_isResizingHorizontally) {
                if(_isResizingRectRight) {
                    setWindowCursor(_resizeCursors[4]);
                }
                else {
                    setWindowCursor(_resizeCursors[5]);
                }
            }
            else {
                if(_isResizingRectBottom) {
                    setWindowCursor(_resizeCursors[6]);
                }
                else {
                    setWindowCursor(_resizeCursors[7]);
                }
            }
        }
    }
    
    void reload() {
        if(hasTab()) {
            auto tabData = getCurrentTab();
            if(_currentTabData && _currentTabData != tabData) {
                _currentTabData.hasViewerData = true;
                _currentTabData.viewerPosition = canvas.position;
                _currentTabData.viewerScale = _scale;
            }
            _currentTabData = tabData;

            _texture = tabData.texture;
            _sprite = new Sprite(_texture);
            _sprite.anchor = Vec2f.zero;

            if(!tabData.hasViewerData) {
                //Reset camera position
                canvas.position = canvas.size / 2f;
                _scale = 1f;
                canvas.size = size * _scale;
            }
            else {
                //Restore camera position
                canvas.position = tabData.viewerPosition;
                _scale = tabData.viewerScale;
                canvas.size = size * _scale;
            }
        }
        else {
            //Reset camera position
            canvas.position = canvas.size / 2f;
            _scale = 1f;
            canvas.size = size * _scale;
            _texture = null;
            _sprite = null;
            isActive = false;
        }
    }

    void setClip(Vec4i clip) {
        _selectionOrigin = clip.xy;
        _selectionSize = clip.zw;
    }

    override void update(float deltaTime) {
        _timer.update(deltaTime);

        if(!isHovered) {
            _isSelecting = false;
            _isGrabbed = false;
        }

        if(isKeyDown("lctrl") || isKeyDown("rctrl")) {
            if(getKeyDown("all")) {
                setClip(Vec4i(
                    0, 0,
                    _texture.width,
                    _texture.height
                ));
                triggerCallback();
            }
        }

        if(getKeyDown("select"))
            toggleBrushSelect();
        if(getKeyDown("move"))
            toggleBrushMove();
        if(getKeyDown("resize-corner"))
            toggleBrushResizeCorner();
        if(getKeyDown("resize-border"))
            toggleBrushResizeBorder();
    }

    Vec4i getClip() {
        return Vec4i(
            to!int(_selectionOrigin.x), to!int(_selectionOrigin.y), 
            to!int(_selectionSize.x), to!int(_selectionSize.y));
    }

    void generateHint(Vec2i cursorPosition) {
        if(_isSelecting) {
            setHint("[" ~ to!string(cursorPosition.x) ~ "; " ~ to!string(cursorPosition.y) ~ "]",
                "[" ~ to!string(_selectionOrigin.x) ~ "; " ~ to!string(_selectionOrigin.y) ~ "; "
                ~ to!string(_selectionSize.x) ~ "; " ~ to!string(_selectionSize.y) ~ "]");
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

    void resize3Selection(Vec2i cursorPosition) {
        if(_isResizingHorizontally) {
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
        }
        else {
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
        }
        setResizeCursor();
    }

    override void draw() {
        if(_texture !is null && _sprite !is null) {
            _sprite.draw(Vec2f.zero);
            drawRect(Vec2f.zero, _sprite.size, Color.white * easeInOutSine(lerp(.4f, .6f, _timer.time)));
        }

        if(!isActive)
            return;

        auto rectOrigin = to!Vec2f(_selectionOrigin);
        auto rectSize = to!Vec2f(_selectionSize);
            
        final switch(elementType) with(ElementType) {
        case SpriteType:
            _rect.size = rectSize;
            _rect.color = Color(0f, .5f, 1f, .35f);
            _rect.draw(rectOrigin + rectSize / 2f);
            drawRect(rectOrigin, rectSize, Color.white);
            drawCross(rectOrigin + rectSize / 2f, 5f, Color.white);
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
                    drawCross(p + s / 2f, 5f, Color.white);

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
        case AnimationType:
        case TilesetType:
            int i;
            drawLoop: foreach(int y; 0.. lines) {
                foreach(int x; 0.. columns) {
                    if(maxtiles != 0 && i >= maxtiles)
                        break drawLoop;

                    Vec2f p = rectOrigin + Vec2f((_selectionSize.x + marginX) * x, (_selectionSize.y + marginY) * y);
                    if(i == previewerGui.getCurrentAnimFrame()) {
                        _rect.size = rectSize;
                        _rect.color = Color(0f, .5f, 1f, .35f);
                        _rect.draw(p + rectSize / 2f);
                    }
                    drawRect(p, rectSize, (x == 0 && y == 0) ? (Color.white) : (Color.green));
                    drawCross(p + rectSize / 2f, 5f, Color.white);
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