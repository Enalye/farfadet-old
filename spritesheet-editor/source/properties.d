module properties;

import std.conv: to;
import atelier;
import editor, imgelement;

final class PropertiesGui: VContainer {
    private {
        DropDownList _elementTypeSelector;
        InputField _fieldX, _fieldY, _fieldW, _fieldH;

        //Tileset parameters
        InputField _fieldColumns, _fieldLines, _fieldMaxTiles;

        //NinePatch parameters
        InputField _fieldTop, _fieldBottom, _fieldLeft, _fieldRight;
    }

    bool isClipDirty, isTypeDirty, areSettingsDirty;
    bool isActive;

    this() {
        spacing(Vec2f(10f, 20f));
        setChildAlign(GuiAlignX.Center);
        minimalWidth(260f);

        _elementTypeSelector = new DropDownList(Vec2f(200f, 30f), 4);
        _elementTypeSelector.add("Sprite");
        _elementTypeSelector.add("Tileset");
        _elementTypeSelector.add("Brush (borders)");
        _elementTypeSelector.add("Brush (no border)");
        _elementTypeSelector.add("NinePatch");

        _fieldX = new InputField(Vec2f(50f, 25f), "0");
        _fieldY = new InputField(Vec2f(50f, 25f), "0");
        _fieldW = new InputField(Vec2f(50f, 25f), "0");
        _fieldH = new InputField(Vec2f(50f, 25f), "0");

        _fieldColumns = new InputField(Vec2f(50f, 25f), "1");
        _fieldLines = new InputField(Vec2f(50f, 25f), "1");
        _fieldMaxTiles = new InputField(Vec2f(50f, 25f), "0");

        _fieldTop = new InputField(Vec2f(50f, 25f), "0");
        _fieldBottom = new InputField(Vec2f(50f, 25f), "0");
        _fieldLeft = new InputField(Vec2f(50f, 25f), "0");
        _fieldRight = new InputField(Vec2f(50f, 25f), "0");

        _fieldX.setAllowedCharacters("0123456789"d);
        _fieldY.setAllowedCharacters("0123456789"d);
        _fieldW.setAllowedCharacters("0123456789"d);
        _fieldH.setAllowedCharacters("0123456789"d);

        _fieldColumns.setAllowedCharacters("0123456789"d);
        _fieldLines.setAllowedCharacters("0123456789"d);
        _fieldMaxTiles.setAllowedCharacters("0123456789"d);

        _fieldTop.setAllowedCharacters("0123456789"d);
        _fieldBottom.setAllowedCharacters("0123456789"d);
        _fieldLeft.setAllowedCharacters("0123456789"d);
        _fieldRight.setAllowedCharacters("0123456789"d);

        //Callbacks
        _elementTypeSelector.setCallback(this, "type");

        _fieldX.setCallback(this, "x");
        _fieldY.setCallback(this, "y");
        _fieldW.setCallback(this, "w");
        _fieldH.setCallback(this, "h");

        _fieldColumns.setCallback(this, "columns");
        _fieldLines.setCallback(this, "lines");
        _fieldMaxTiles.setCallback(this, "maxtiles");

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
        case "columns":
        case "lines":
        case "maxtiles":
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
            box.addChildGui(new Label("Type: "));
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

        if(_elementTypeSelector.selected == 1) {
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
        }
        else if(_elementTypeSelector.selected == 4) {
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
        return Vec4i(
            _fieldX.text.length ? to!int(_fieldX.text) : 0,
            _fieldY.text.length ? to!int(_fieldY.text) : 0,
            _fieldW.text.length ? to!int(_fieldW.text) : 0,
            _fieldH.text.length ? to!int(_fieldH.text) : 0);
    }

    ImgType getImgType() {
        switch(_elementTypeSelector.selected) {
        case 0: return ImgType.SpriteType;
        case 1: return ImgType.TilesetType;
        case 2: return ImgType.BorderedBrushType;
        case 3: return ImgType.BorderlessBrushType;
        case 4: return ImgType.NinePatchType;
        default:
            throw new Exception("Invalid texture class property");
        }
    }

    void setImgType(ImgType type) {
        _elementTypeSelector.selected(type);
    }

    int getColumns() {
        return _fieldColumns.text.length ? to!int(_fieldColumns.text) : 0;
    }
    
    void setColumns(int value) {
        _fieldColumns.text = to!string(value);
    }

    int getLines() {
        return _fieldLines.text.length ? to!int(_fieldLines.text) : 0;
    }
    
    void setLines(int value) {
        _fieldLines.text = to!string(value);
    }

    int getMaxTiles() {
        return _fieldMaxTiles.text.length ? to!int(_fieldMaxTiles.text) : 0;
    }
    
    void setMaxTiles(int value) {
        _fieldMaxTiles.text = to!string(value);
    }

    int getTop() {
        return _fieldTop.text.length ? to!int(_fieldTop.text) : 0;
    }
    
    void setTop(int value) {
        _fieldTop.text = to!string(value);
    }

    int getBottom() {
        return _fieldBottom.text.length ? to!int(_fieldBottom.text) : 0;
    }
    
    void setBottom(int value) {
        _fieldBottom.text = to!string(value);
    }

    int getLeft() {
        return _fieldLeft.text.length ? to!int(_fieldLeft.text) : 0;
    }
    
    void setLeft(int value) {
        _fieldLeft.text = to!string(value);
    }

    int getRight() {
        return _fieldRight.text.length ? to!int(_fieldRight.text) : 0;
    }
    
    void setRight(int value) {
        _fieldRight.text = to!string(value);
    }
}