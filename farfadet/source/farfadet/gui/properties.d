module farfadet.gui.properties;

import std.conv: to, ConvException;
import atelier;
import farfadet.gui.editor, farfadet.common;

final class PropertiesGui: VContainer {
    private {
        DropDownList _elementTypeSelector, _flipSelector, _animModeSelector, _easingSelector;
        InputField _fieldX, _fieldY, _fieldW, _fieldH, _fieldMarginX, _fieldMarginY;

        //Tileset/Animation parameters
        InputField _fieldColumns, _fieldLines, _fieldMaxTiles, _fieldDuration;

        //NinePatch parameters
        InputField _fieldTop, _fieldBottom, _fieldLeft, _fieldRight;
    }

    bool isClipDirty, isTypeDirty, areSettingsDirty;
    bool isActive;

    this() {
        spacing(Vec2f(10f, 12f));
        setChildAlign(GuiAlignX.center);
        minimalWidth(260f);

        _elementTypeSelector = new DropDownList(Vec2f(200f, 30f), 4);
        _elementTypeSelector.add("Sprite");
        _elementTypeSelector.add("Animation");
        _elementTypeSelector.add("Tileset");
        _elementTypeSelector.add("Brush (borders)");
        _elementTypeSelector.add("Brush (no border)");
        _elementTypeSelector.add("NinePatch");

        _flipSelector = new DropDownList(Vec2f(180f, 30f), 4);
        _flipSelector.add("None");
        _flipSelector.add("Horizontal");
        _flipSelector.add("Vertical");
        _flipSelector.add("Both");

        _animModeSelector = new DropDownList(Vec2f(180f, 30f), 3);
        _animModeSelector.add("Once");
        _animModeSelector.add("Reverse");
        _animModeSelector.add("Loop");
        _animModeSelector.add("Loop Reverse");
        _animModeSelector.add("Bounce");
        _animModeSelector.add("Bounce Reverse");

        _easingSelector = new DropDownList(Vec2f(180f, 30f), 4);
        _easingSelector.add("Linear");
        _easingSelector.add("Sine In");
        _easingSelector.add("Sine Out");
        _easingSelector.add("Sine In Out");
        _easingSelector.add("Quad In");
        _easingSelector.add("Quad Out");
        _easingSelector.add("Quad In Out");
        _easingSelector.add("Cubic In");
        _easingSelector.add("Cubic Out");
        _easingSelector.add("Cubic In Out");
        _easingSelector.add("Quart In");
        _easingSelector.add("Quart Out");
        _easingSelector.add("Quart In Out");
        _easingSelector.add("Quint In");
        _easingSelector.add("Quint Out");
        _easingSelector.add("Quint In Out");
        _easingSelector.add("Exp In");
        _easingSelector.add("Exp Out");
        _easingSelector.add("Exp In Out");
        _easingSelector.add("Circ In");
        _easingSelector.add("Circ Out");
        _easingSelector.add("Circ In Out");
        _easingSelector.add("Back In");
        _easingSelector.add("Back Out");
        _easingSelector.add("Back In Out");
        _easingSelector.add("Elastic In");
        _easingSelector.add("Elastic Out");
        _easingSelector.add("Elastic In Out");
        _easingSelector.add("Bounce In");
        _easingSelector.add("Bounce Out");
        _easingSelector.add("Bounce In Out");

        _fieldX = new InputField(Vec2f(50f, 25f), "0");
        _fieldY = new InputField(Vec2f(50f, 25f), "0");
        _fieldW = new InputField(Vec2f(50f, 25f), "0");
        _fieldH = new InputField(Vec2f(50f, 25f), "0");
        _fieldMarginX = new InputField(Vec2f(50f, 25f), "0");
        _fieldMarginY = new InputField(Vec2f(50f, 25f), "0");

        _fieldColumns = new InputField(Vec2f(50f, 25f), "1");
        _fieldLines = new InputField(Vec2f(50f, 25f), "1");
        _fieldMaxTiles = new InputField(Vec2f(50f, 25f), "0");
        _fieldDuration = new InputField(Vec2f(50f, 25f), "1");

        _fieldTop = new InputField(Vec2f(50f, 25f), "0");
        _fieldBottom = new InputField(Vec2f(50f, 25f), "0");
        _fieldLeft = new InputField(Vec2f(50f, 25f), "0");
        _fieldRight = new InputField(Vec2f(50f, 25f), "0");

        _fieldX.setAllowedCharacters("0123456789"d);
        _fieldY.setAllowedCharacters("0123456789"d);
        _fieldW.setAllowedCharacters("0123456789"d);
        _fieldH.setAllowedCharacters("0123456789"d);
        _fieldMarginX.setAllowedCharacters("0123456789"d);
        _fieldMarginY.setAllowedCharacters("0123456789"d);

        _fieldColumns.setAllowedCharacters("0123456789"d);
        _fieldLines.setAllowedCharacters("0123456789"d);
        _fieldMaxTiles.setAllowedCharacters("0123456789"d);
        _fieldDuration.setAllowedCharacters("0123456789."d);

        _fieldTop.setAllowedCharacters("0123456789"d);
        _fieldBottom.setAllowedCharacters("0123456789"d);
        _fieldLeft.setAllowedCharacters("0123456789"d);
        _fieldRight.setAllowedCharacters("0123456789"d);

        //Callbacks
        _elementTypeSelector.setCallback(this, "type");
        _flipSelector.setCallback(this, "flip");

        _fieldX.setCallback(this, "x");
        _fieldY.setCallback(this, "y");
        _fieldW.setCallback(this, "w");
        _fieldH.setCallback(this, "h");
        _fieldMarginX.setCallback(this, "x-margin");
        _fieldMarginY.setCallback(this, "y-margin");

        _fieldColumns.setCallback(this, "columns");
        _fieldLines.setCallback(this, "lines");
        _fieldMaxTiles.setCallback(this, "maxtiles");
        _fieldDuration.setCallback(this, "duration");
        _animModeSelector.setCallback(this, "anim-mode");
        _easingSelector.setCallback(this, "easing");

        _fieldTop.setCallback(this, "top");
        _fieldBottom.setCallback(this, "bottom");
        _fieldLeft.setCallback(this, "left");
        _fieldRight.setCallback(this, "right");

        load();
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.1f, .13f, .18f));
    }

    override void onCallback(string id) {
        switch(id) {
        case "type":
            isTypeDirty = true;
            triggerCallback();
            break;
        case "x":
        case "y":
        case "w":
        case "h":
            isClipDirty = true;
            triggerCallback();
            break;
        case "flip":
        case "columns":
        case "lines":
        case "maxtiles":
        case "duration":
        case "easing":
        case "anim-mode":
        case "x-margin":
        case "y-margin":
        case "top":
        case "bottom":
        case "left":
        case "right":
            areSettingsDirty = true;
            triggerCallback();
            break;
        default:
            break;
        }
    }

    void load() {
        removeChildrenGuis();

        if(!isActive)
            return;

        addChildGui(new Label("-- Properties --"));

        {
            auto box = new HContainer;
            box.addChildGui(new Label("type: "));
            box.addChildGui(_elementTypeSelector);
            addChildGui(box);
        }

        addChildGui(new Label("- Coordinates -"));
        {
            auto box = new HContainer;
            box.addChildGui(new Label("x: "));
            box.addChildGui(_fieldX);
            box.addChildGui(new Label(" y: "));
            box.addChildGui(_fieldY);
            addChildGui(box);
        }

        addChildGui(new Label("- Size -"));
        {
            auto box = new HContainer;
            box.addChildGui(new Label("w: "));
            box.addChildGui(_fieldW);
            box.addChildGui(new Label(" h: "));
            box.addChildGui(_fieldH);
            addChildGui(box);
        }

        {
            auto box = new HContainer;
            box.addChildGui(new Label("flip: "));
            box.addChildGui(_flipSelector);
            addChildGui(box);
        }

        if(_elementTypeSelector.selected == 1) {
            addChildGui(new Label("- Anim settings -"));
            {
                auto box = new HContainer;
                box.addChildGui(new Label("cols: "));
                box.addChildGui(_fieldColumns);
                box.addChildGui(new Label(" lines: "));
                box.addChildGui(_fieldLines);
                addChildGui(box);
            }
            {
                auto box = new HContainer;
                box.addChildGui(new Label("max (optional): "));
                box.addChildGui(_fieldMaxTiles);
                addChildGui(box);
            }
            addChildGui(new Label("- Margin -"));
            {
                auto box = new HContainer;
                box.addChildGui(new Label("x: "));
                box.addChildGui(_fieldMarginX);
                box.addChildGui(new Label(" y: "));
                box.addChildGui(_fieldMarginY);
                addChildGui(box);
            }
            {
                auto box = new HContainer;
                box.addChildGui(new Label("ease: "));
                box.addChildGui(_easingSelector);
                addChildGui(box);
            }
            {
                auto box = new HContainer;
                box.addChildGui(new Label("anim: "));
                box.addChildGui(_animModeSelector);
                addChildGui(box);
            }
            {
                auto box = new HContainer;
                box.addChildGui(new Label("duration: "));
                box.addChildGui(_fieldDuration);
                box.addChildGui(new Label(" secs"));
                addChildGui(box);
            }
        }
        else if(_elementTypeSelector.selected == 2) {
            addChildGui(new Label("- Tileset settings -"));
            {
                auto box = new HContainer;
                box.addChildGui(new Label("cols: "));
                box.addChildGui(_fieldColumns);
                box.addChildGui(new Label(" lines: "));
                box.addChildGui(_fieldLines);
                addChildGui(box);
            }
            {
                auto box = new HContainer;
                box.addChildGui(new Label("max (optional): "));
                box.addChildGui(_fieldMaxTiles);
                addChildGui(box);
            }
            addChildGui(new Label("- Margin -"));
            {
                auto box = new HContainer;
                box.addChildGui(new Label("x: "));
                box.addChildGui(_fieldMarginX);
                box.addChildGui(new Label(" y: "));
                box.addChildGui(_fieldMarginY);
                addChildGui(box);
            }
        }
        else if(_elementTypeSelector.selected == 5) {
            addChildGui(new Label("- NinePatch settings -"));
            {
                auto box = new HContainer;
                box.addChildGui(new Label("top: "));
                box.addChildGui(_fieldTop);
                box.addChildGui(new Label(" bottom: "));
                box.addChildGui(_fieldBottom);
                addChildGui(box);
            }
            {
                auto box = new HContainer;
                box.addChildGui(new Label("left: "));
                box.addChildGui(_fieldLeft);
                box.addChildGui(new Label(" right: "));
                box.addChildGui(_fieldRight);
                addChildGui(box);
            }
        }
    }

    void setClip(Vec4i clip) {
        _fieldX.text = to!string(clip.x);
        _fieldY.text = to!string(clip.y);
        _fieldW.text = to!string(clip.z);
        _fieldH.text = to!string(clip.w);
    }

    Vec4i getClip() {
        try {
            return Vec4i(
                _fieldX.text.length ? to!int(_fieldX.text) : 0,
                _fieldY.text.length ? to!int(_fieldY.text) : 0,
                _fieldW.text.length ? to!int(_fieldW.text) : 0,
                _fieldH.text.length ? to!int(_fieldH.text) : 0);
        }
        catch(ConvException e) {
            return Vec4i.zero;
        }
    }

    ElementType getImgType() {
        switch(_elementTypeSelector.selected) {
        case 0: return ElementType.sprite;
        case 1: return ElementType.animation;
        case 2: return ElementType.tileset;
        case 3: return ElementType.borderedBrush;
        case 4: return ElementType.borderlessBrush;
        case 5: return ElementType.ninepatch;
        default:
            throw new Exception("Invalid texture class property");
        }
    }

    void setImgType(ElementType type) {
        _elementTypeSelector.selected(type);
    }

    Flip getFlip() {
        switch(_flipSelector.selected) {
        case 0: return Flip.none;
        case 1: return Flip.horizontal;
        case 2: return Flip.vertical;
        case 3: return Flip.both;
        default:
            throw new Exception("Invalid flip type property");
        }
    }

    void setFlip(Flip flip) {
        _flipSelector.selected(flip);
    }

    Timer.Mode getAnimMode() {
        if(_animModeSelector.selected > Timer.Mode.bounceReverse)
            throw new Exception("Invalid animation mode");
        return cast(Timer.Mode) _animModeSelector.selected;
    }

    void setAnimMode(Timer.Mode mode) {
        _animModeSelector.selected = mode;
    }

    EasingAlgorithm getEasingAlgorithm() {
        if(_easingSelector.selected > EasingAlgorithm.bounceInOut)
            throw new Exception("Invalid easing algorithm");
        return cast(EasingAlgorithm) _easingSelector.selected;
    }

    void setEasingAlgorithm(EasingAlgorithm algorithm) {
        _easingSelector.selected = algorithm;
    }

    int getColumns() {
        try {
            const int cols = _fieldColumns.text.length ? to!int(_fieldColumns.text) : 1;
            return cols <= 0 ? 1 : cols;
        }
        catch(ConvException e) {
            return 1;
        }
    }
    
    void setColumns(int value) {
        if(value < 1)
            value = 1;
        _fieldColumns.text = to!string(value);
    }

    int getLines() {
        try {
            const int lines = _fieldLines.text.length ? to!int(_fieldLines.text) : 1;
            return lines <= 0 ? 1 : lines;
        }
        catch(ConvException e) {
            return 1;
        }
    }
    
    void setLines(int value) {
        if(value < 1)
            value = 1;
        _fieldLines.text = to!string(value);
    }

    int getMaxTiles() {
        try {
            return _fieldMaxTiles.text.length ? to!int(_fieldMaxTiles.text) : 0;
        }
        catch(ConvException e) {
            return 0;
        }
    }
    
    void setMaxTiles(int value) {
        _fieldMaxTiles.text = to!string(value);
    }

    float getDuration() {
        try {
            return _fieldDuration.text.length ? to!float(_fieldDuration.text) : 1f;
        }
        catch(ConvException e) {
            return 1f;
        }
    }
    
    void setDuration(float value) {
        _fieldDuration.text = to!string(value);
    }

    int getMarginX() {
        try {
            return _fieldMarginX.text.length ? to!int(_fieldMarginX.text) : 0;
        }
        catch(ConvException e) {
            return 0;
        }
    }
    
    void setMarginX(int value) {
        _fieldMarginX.text = to!string(value);
    }

    int getMarginY() {
        try {
            return _fieldMarginY.text.length ? to!int(_fieldMarginY.text) : 0;
        }
        catch(ConvException e) {
            return 0;
        }
    }
    
    void setMarginY(int value) {
        _fieldMarginY.text = to!string(value);
    }

    int getTop() {
        try {
            return _fieldTop.text.length ? to!int(_fieldTop.text) : 0;
        }
        catch(ConvException e) {
            return 0;
        }
    }
    
    void setTop(int value) {
        _fieldTop.text = to!string(value);
    }

    int getBottom() {
        try {
            return _fieldBottom.text.length ? to!int(_fieldBottom.text) : 0;
        }
        catch(ConvException e) {
            return 0;
        }
    }
    
    void setBottom(int value) {
        _fieldBottom.text = to!string(value);
    }

    int getLeft() {
        try {
            return _fieldLeft.text.length ? to!int(_fieldLeft.text) : 0;
        }
        catch(ConvException e) {
            return 0;
        }
    }
    
    void setLeft(int value) {
        _fieldLeft.text = to!string(value);
    }

    int getRight() {
        try {
            return _fieldRight.text.length ? to!int(_fieldRight.text) : 0;
        }
        catch(ConvException e) {
            return 0;
        }
    }
    
    void setRight(int value) {
        _fieldRight.text = to!string(value);
    }
}