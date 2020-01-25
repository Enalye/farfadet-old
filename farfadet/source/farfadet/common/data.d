module farfadet.common.data;


import std.path, std.file;
import atelier;
import farfadet.gui;
import farfadet.common.util;

private {
    TabData[] _tabs;
    uint _currentTabIndex;
    GraphicEditorGui _editor;
}

/// General type of an element.
enum ElementType {
    sprite, animation, tileset, borderedBrush, borderlessBrush, ninepatch
}

/// Data describing a single element.
final class ElementData {
    private {
        string _name = "untitled";
        ElementType _type = ElementType.sprite;
        Vec4i _clip = Vec4i.zero;
        int _columns = 1, _lines = 1, _maxtiles;
        int _top, _bottom, _left, _right;
        int _marginX, _marginY;
        float _duration = 1f;
        bool _isReverse = false;
        Animation.Mode _animMode = Animation.Mode.once;
        Flip _flip = Flip.none;
        EasingAlgorithm _easingAlgorithm = EasingAlgorithm.linear;
    }

    @property {
        /// Key name
        string name() const { return _name; }
        /// Ditto
        string name(string v) { _onDirty(); return _name = v; }

        /// General type
        ElementType type() const { return _type; }
        /// Ditto
        ElementType type(ElementType v) {
            if(v == _type)
                return v;
            _onDirty();
            return _type = v;
        }

        /// Texture region
        Vec4i clip() const { return _clip; }
        /// Ditto
        Vec4i clip(Vec4i v) {
            if(v == _clip)
                return v;
            _onDirty();
            return _clip = v;
        }

        /// Flip
        Flip flip() const { return _flip; }
        /// Ditto
        Flip flip(Flip v) {
            if(v == _flip)
                return v;
            _onDirty();
            return _flip = v;
        }

        /// Loop mode
        Animation.Mode animMode() const { return _animMode; }
        /// Ditto
        Animation.Mode animMode(Animation.Mode v) {
            if(v == _animMode)
                return v;
            _onDirty();
            return _animMode = v;
        }

        /// Easing used on the animation.
        EasingAlgorithm easingAlgorithm() const { return _easingAlgorithm; }
        /// Ditto
        EasingAlgorithm easingAlgorithm(EasingAlgorithm v) {
            if(v == _easingAlgorithm)
                return v;
            _onDirty();
            return _easingAlgorithm = v;
        }

        /// Tileset specific data
        int columns() const { return _columns; }
        /// Ditto
        int columns(int v) {
            if(v == _columns)
                return v;
            _onDirty();
            return _columns = v;
        }

        int lines() const { return _lines; }
        /// Ditto
        int lines(int v) {
            if(v == _lines)
                return v;
            _onDirty();
            return _lines = v;
        }

        int maxtiles() const { return _maxtiles; }
        /// Ditto
        int maxtiles(int v) {
            if(v == _maxtiles)
                return v;
            _onDirty();
            return _maxtiles = v;
        }

        float duration() const { return _duration; }
        /// Ditto
        float duration(float v) {
            if(v == _duration)
                return v;
            _onDirty();
            return _duration = v;
        }

        // NinePatch specific data
        /// Top border of a ninepatch.
        int top() const { return _top; }
        /// Ditto
        int top(int v) {
            if(v == _top)
                return v;
            _onDirty();
            return _top = v;
        }

        /// Bottom border of a ninepatch.
        int bottom() const { return _bottom; }
        /// Ditto
        int bottom(int v) {
            if(v == _bottom)
                return v;
            _onDirty();
            return _bottom = v;
        }

        /// Left border of a ninepatch.
        int left() const { return _left; }
        /// Ditto
        int left(int v) {
            if(v == _left)
                return v;
            _onDirty();
            return _left = v;
        }

        /// Right border of a ninepatch.
        int right() const { return _right; }
        /// Ditto
        int right(int v) {
            if(v == _right)
                return v;
            _onDirty();
            return _right = v;
        }

        /// Horizontal margin between tiles.
        int marginX() const { return _marginX; }
        /// Ditto
        int marginX(int v) {
            if(v == _marginX)
                return v;
            _onDirty();
            return _marginX = v;
        }

        /// Vertical margin between tiles.
        int marginY() const { return _marginY; }
        /// Ditto
        int marginY(int v) {
            if(v == _marginY)
                return v;
            _onDirty();
            return _marginY = v;
        }
    }
}

/// An entire image/json file containing all its elements.
final class TabData {
    private {
        ElementData[] _elements;
        string _dataPath, _texturePath, _title = "untitled";
        Texture _texture;
        bool _isTitleDirty =  true, _isDirty = true;
    }

    @property {
        ElementData[] elements() { return _elements; }
        Texture texture() { return _texture; }
        bool isTitleDirty(bool v) { return _isTitleDirty = v; }
        bool isTitleDirty() const { return _isTitleDirty; }
        string title() { _isTitleDirty = false; return _title;}
        string dataPath() const { return _dataPath; }
        string texturePath() const { return _texturePath; }
        bool isDirty() const { return _isDirty; }
    }

    bool hasSavePath() {
        return _dataPath.length > 0uL;   
    }

    bool canReload() {
        return false;
    }

    //Temporary data, not saved
    bool hasViewerData;
    float viewerScale = 1f;
    Vec2f viewerPosition = Vec2f.zero;

    bool hasPreviewerData;
    float previewerSpeed;

    bool hasElementsListData;
    uint elementsListIndex;
}

void setupData(GraphicEditorGui editor) {
    _editor = editor;
}

/// Open either an image or a json file format in a new tab.
bool openTab(string filePath) {
    auto tabData = new TabData;

    if(isValidImageFileType(filePath)) {
        tabData._texturePath = buildNormalizedPath(filePath);
    }        
    else if(isValidDataFileType(filePath)) {
        tabData._dataPath = buildNormalizedPath(filePath);
        try {
            _loadData(tabData);
        }
        catch(Exception e) {
            return false;
        }
    }
    else {
        return false;
    }
    tabData._texture = new Texture(tabData._texturePath);

    _tabs ~= tabData;
    setCurrentTab(tabData);
    return true;
}

void reloadTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    auto tabData = _tabs[_currentTabIndex];
    if(!exists(tabData._dataPath))
        return;
    _loadData(tabData);
    _updateTitle();
}

void reloadTabTexture() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    auto tabData = _tabs[_currentTabIndex];
    if(!exists(tabData._texturePath))
        return;
    tabData._texture = new Texture(tabData._texturePath);    
}

void setTabDataPath(string filePath) {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    auto tabData = _tabs[_currentTabIndex];
    tabData._dataPath = filePath;
    _updateTitle();
}

void saveTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _saveData(_tabs[_currentTabIndex]);
    _updateTitle();
}

void closeTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");

    if((_currentTabIndex + 1) == _tabs.length) {
        _tabs.length --;
        _currentTabIndex = (_currentTabIndex == 0) ? 0 : (_currentTabIndex - 1);
    }
    else if(_currentTabIndex == 0) {
        _tabs = _tabs[1.. $];
        _currentTabIndex = 0;
    }
    else {
        _tabs = _tabs[0.. _currentTabIndex] ~ _tabs[(_currentTabIndex + 1).. $];
        _currentTabIndex --;
    }
    _updateTitle();
}

void setCurrentTab(TabData tabData) {
    _currentTabIndex = cast(uint)_tabs.length;
    for(int i; i < _tabs.length; i ++) {
        if(tabData == _tabs[i]) {
            _currentTabIndex = i;
            break;
        }
    }
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab no found");
    _updateTitle();
}

void setPreviousTab() {
    if(!hasTab())
        return;
    _currentTabIndex = (_currentTabIndex == 0u) ? (cast(int)_tabs.length - 1) : (_currentTabIndex - 1);
    _updateTitle();
}

void setNextTab() {
    if(!hasTab())
        return;
    _currentTabIndex = ((_currentTabIndex + 1) >= _tabs.length) ? 0u : (_currentTabIndex + 1u);
    _updateTitle();
}

private void _updateTitle() {
    if(_currentTabIndex >= _tabs.length) {
        setWindowTitle("Farfadet");
    }
    else {
        auto tabData = _tabs[_currentTabIndex];
        tabData._isTitleDirty = true;
        string dirtyString = (tabData._isDirty ? " *" : "");
        if(tabData._dataPath.length) {
            tabData._title = baseName(tabData._dataPath) ~ dirtyString;
            setWindowTitle("Farfadet - " ~ tabData._dataPath ~ " ~ (" ~ tabData._texturePath ~ ")" ~ dirtyString);
        }
        else {
            tabData._title = baseName(tabData._texturePath) ~ tabData._isDirty ? " *" : "";
            setWindowTitle("Farfadet - * ~ (" ~ tabData._texturePath ~ ")" ~ dirtyString);
        }
    }
}

TabData getCurrentTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds5");
    return _tabs[_currentTabIndex];
}

bool hasTab() {
    return _tabs.length > 0uL;
}

ElementData[] getCurrentElements() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    return _tabs[_currentTabIndex]._elements;
}

void setCurrentElements(ElementData[] elements) {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _tabs[_currentTabIndex]._elements = elements;
    _onDirty();
}

void setSavePath(string filePath) {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _tabs[_currentTabIndex]._dataPath = filePath;
}

private void _onDirty() {
    if(_tabs[_currentTabIndex]._isDirty)
        return;
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    _tabs[_currentTabIndex]._isDirty = true;
    _updateTitle();
}

private void _loadData(TabData tabData) {
    JSONValue json = parseJSON(readText(tabData._dataPath));

    if(getJsonStr(json, "type") != "spritesheet")
        return;

    tabData._texturePath = buildNormalizedPath(dirName(tabData._dataPath), convertPathToImport(getJsonStr(json, "texture")));
    if(!exists(tabData._texturePath))
        throw new Exception("Texture path not valid");
    auto elementsNode = getJsonArray(json, "elements");

    tabData._elements.length = 0uL;
    foreach(JSONValue elementNode; elementsNode) {
        auto element = new ElementData;
        element._name = getJsonStr(elementNode, "name");

        switch(getJsonStr(elementNode, "type")) {
        case "sprite":
            element._type = ElementType.sprite;
            break;
        case "animation":
            element._type = ElementType.animation;
            break;
        case "tileset":
            element._type = ElementType.tileset;
            break;
        case "bordered_brush":
            element._type = ElementType.borderedBrush;
            break;
        case "borderless_brush":
            element._type = ElementType.borderlessBrush;
            break;
        case "ninepatch":
            element._type = ElementType.ninepatch;
            break;
        default:
            throw new Exception("Invalid image type");
        }

        switch(getJsonStr(elementNode, "flip", "none")) {
        case "none":
            element._flip = Flip.none;
            break;
        case "horizontal":
            element._flip = Flip.horizontal;
            break;
        case "vertical":
            element._flip = Flip.vertical;
            break;
        case "both":
            element._flip = Flip.both;
            break;
        default:
            throw new Exception("Invalid flip type");
        }

        auto clipNode = getJson(elementNode, "clip");
        Vec4i clip;
        clip.x = getJsonInt(clipNode, "x");
        clip.y = getJsonInt(clipNode, "y");
        clip.z = getJsonInt(clipNode, "w");
        clip.w = getJsonInt(clipNode, "h");
        element._clip = clip;

        final switch(element._type) with(ElementType) {
        case sprite:
        case borderedBrush:
        case borderlessBrush:
            break;
        case animation:
            element._duration = getJsonFloat(elementNode, "duration", 1f);
            element._isReverse = getJsonBool(elementNode, "reverse", false);

            switch(getJsonStr(elementNode, "mode", "once")) {
            case "once":
                element._animMode = Animation.Mode.once;
                break;
            case "reverse":
                element._animMode = Animation.Mode.reverse;
                break;
            case "loop":
                element._animMode = Animation.Mode.loop;
                break;
            case "loop_reverse":
                element._animMode = Animation.Mode.loopReverse;
                break;
            case "bounce":
                element._animMode = Animation.Mode.bounce;
                break;
            case "bounce_reverse":
                element._animMode = Animation.Mode.bounceReverse;
                break;
            default:
                throw new Exception("Invalid animation mode");
            }
            goto case tileset;
        case tileset:
            element._columns = getJsonInt(elementNode, "columns", 1);
            element._lines = getJsonInt(elementNode, "lines", 1);
            element._maxtiles = getJsonInt(elementNode, "maxtiles", 0);

            if(hasJson(elementNode, "margin")) {
                auto marginNode = getJson(elementNode, "margin");
                element._marginX = getJsonInt(marginNode, "x", 0);
                element._marginY = getJsonInt(marginNode, "y", 0);
            }
            else {
                element._marginX = 0;
                element._marginY = 0;
            }
            break;
        case ninepatch:
            element._top = getJsonInt(elementNode, "top", 0);
            element._bottom = getJsonInt(elementNode, "bottom", 0);
            element._left = getJsonInt(elementNode, "left", 0);
            element._right = getJsonInt(elementNode, "right", 0);
            break;
        }
        tabData._elements ~= element;
    }
    tabData._isDirty = false;
}

private void _saveData(TabData tabData) {
    JSONValue json;
    json["type"] = JSONValue("spritesheet");
    // relativePath() expects both arguments being absolute AND normalized,
    // Otherwise, the path is complètement aux fraises.
    json["texture"] = JSONValue(
        convertPathToExport(
            relativePath(
                buildNormalizedPath(absolutePath(tabData._texturePath)),
                buildNormalizedPath(absolutePath(dirName(tabData._dataPath)))
                )
            )
        );
    JSONValue[] elementsNode;

    foreach(ElementData element; tabData._elements) {
        JSONValue elementNode;
        elementNode["name"] = JSONValue(element._name);

        final switch(element._type) with(ElementType) {
        case sprite:
            elementNode["type"] = JSONValue("sprite");
            break;
        case animation:
            elementNode["type"] = JSONValue("animation");
            break;
        case tileset:
            elementNode["type"] = JSONValue("tileset");
            break;
        case borderedBrush:
            elementNode["type"] = JSONValue("bordered_brush");
            break;
        case borderlessBrush:
            elementNode["type"] = JSONValue("borderless_brush");
            break;
        case ninepatch:
            elementNode["type"] = JSONValue("ninepatch");
            break;
        }

        final switch(element._flip) with(Flip) {
        case none:
            elementNode["flip"] = JSONValue("none");
            break;
        case horizontal:
            elementNode["flip"] = JSONValue("horizontal");
            break;
        case vertical:
            elementNode["flip"] = JSONValue("vertical");
            break;
        case both:
            elementNode["flip"] = JSONValue("both");
            break;
        }

        JSONValue clipNode;
        clipNode["x"] = JSONValue(element._clip.x);
        clipNode["y"] = JSONValue(element._clip.y);
        clipNode["w"] = JSONValue(element._clip.z);
        clipNode["h"] = JSONValue(element._clip.w);
        elementNode["clip"] = clipNode;

        final switch(element._type) with(ElementType) {
        case sprite:
        case borderedBrush:
        case borderlessBrush:
            break;
        case animation:
            elementNode["duration"] = JSONValue(element._duration);
            elementNode["reverse"] = JSONValue(element._isReverse);

            final switch(element._animMode) with(Animation.Mode) {
            case once:
                elementNode["mode"] = JSONValue("once");
                break;
            case reverse:
                elementNode["mode"] = JSONValue("reverse");
                break;
            case loop:
                elementNode["mode"] = JSONValue("loop");
                break;
            case loopReverse:
                elementNode["mode"] = JSONValue("loop_reverse");
                break;
            case bounce:
                elementNode["mode"] = JSONValue("bounce");
                break;
            case bounceReverse:
                elementNode["mode"] = JSONValue("bounce_reverse");
                break;
            }

            __easingNode: final switch(element._easingAlgorithm) with(EasingAlgorithm) {
            static foreach(value; [
                "linear",
                "sineIn", "sineOut", "sineInOut",
                "quadIn", "quadOut", "quadInOut",
                "cubicIn", "cubicOut", "cubicInOut",
                "quartIn", "quartOut", "quartInOut",
                "quintIn", "quintOut", "quintInOut",
                "expIn", "expOut", "expInOut",
                "circIn", "circOut", "circInOut",
                "backIn", "backOut", "backInOut",
                "elasticIn", "elasticOut", "elasticInOut",
                "bounceIn", "bounceOut", "bounceInOut"]) {
                mixin("
                case " ~ value ~ ":
                    elementNode[\"easing\"] = JSONValue(\"" ~ value ~ "\");
                    break __easingNode;
                    ");
                }
            }
            goto case tileset;
        case tileset:
            elementNode["columns"] = JSONValue(element._columns);
            elementNode["lines"] = JSONValue(element._lines);
            elementNode["maxtiles"] = JSONValue(element._maxtiles);

            JSONValue marginNode;
            marginNode["x"] = JSONValue(element._marginX);
            marginNode["y"] = JSONValue(element._marginY);
            elementNode["margin"] = marginNode;
            break;
        case ninepatch:
            elementNode["top"] = JSONValue(element._top);
            elementNode["bottom"] = JSONValue(element._bottom);
            elementNode["left"] = JSONValue(element._left);
            elementNode["right"] = JSONValue(element._right);
            break;
        }
        elementsNode ~= elementNode;
    }
    json["elements"] = elementsNode;
    std.file.write(tabData._dataPath, toJSON(json, true));
    tabData._isDirty = false;
}