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
    SpriteType, TilesetType, BorderedBrushType, BorderlessBrushType, NinePatchType
}

/// Data describing a single element.
final class ElementData {
    private {
        string _name = "untitled";
        ElementType _type = ElementType.SpriteType;
        Vec4i _clip = Vec4i.zero;
        int _columns = 1, _lines = 1, _maxtiles;
        int _top, _bottom, _left, _right;
    }

    @property {
        /// Key name
        string name() const { return _name; }
        string name(string v) { _onDirty(); return _name = v; }

        /// General type
        ElementType type() const { return _type; }
        ElementType type(ElementType v) {
            if(v == _type)
                return v;
            _onDirty();
            return _type = v;
        }

        /// Texture region
        Vec4i clip() const { return _clip; }
        Vec4i clip(Vec4i v) {
            if(v == _clip)
                return v;
            _onDirty();
            return _clip = v;
        }

        /// Tileset specific data
        int columns() const { return _columns; }
        int columns(int v) {
            if(v == _columns)
                return v;
            _onDirty();
            return _columns = v;
        }

        int lines() const { return _lines; }
        int lines(int v) {
            if(v == _lines)
                return v;
            _onDirty();
            return _lines = v;
        }

        int maxtiles() const { return _maxtiles; }
        int maxtiles(int v) {
            if(v == _maxtiles)
                return v;
            _onDirty();
            return _maxtiles = v;
        }

        /// NinePatch specific data
        int top() const { return _top; }
        int top(int v) {
            if(v == _top)
                return v;
            _onDirty();
            return _top = v;
        }

        int bottom() const { return _bottom; }
        int bottom(int v) {
            if(v == _bottom)
                return v;
            _onDirty();
            return _bottom = v;
        }

        int left() const { return _left; }
        int left(int v) {
            if(v == _left)
                return v;
            _onDirty();
            return _left = v;
        }

        int right() const { return _right; }
        int right(int v) {
            if(v == _right)
                return v;
            _onDirty();
            return _right = v;
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
void openTab(string filePath) {
    auto tabData = new TabData;

    if(isValidImageFileType(filePath)) {
        tabData._texturePath = buildNormalizedPath(filePath);
    }        
    else if(isValidDataFileType(filePath)) {
        tabData._dataPath = buildNormalizedPath(filePath);
        _loadData(tabData);
    }
    tabData._texture = new Texture(tabData._texturePath);

    _tabs ~= tabData;
    setCurrentTab(tabData);
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
    if(_currentTabIndex >= _tabs.length) {
        assert(false, "bounds");
    }
        //throw new Exception("Tab index out of bounds5");
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
    auto elementsNode = getJsonArray(json, "elements");

    tabData._elements.length = 0uL;
    foreach(JSONValue elementNode; elementsNode) {
        auto element = new ElementData;
        element._name = getJsonStr(elementNode, "name");

        switch(getJsonStr(elementNode, "type")) {
        case "sprite":
            element._type = ElementType.SpriteType;
            break;
        case "tileset":
            element._type = ElementType.TilesetType;
            break;
        case "bordered_brush":
            element._type = ElementType.BorderedBrushType;
            break;
        case "borderless_brush":
            element._type = ElementType.BorderlessBrushType;
            break;
        case "ninepatch":
            element._type = ElementType.NinePatchType;
            break;
        default:
            throw new Exception("Invalid image type");
        }

        auto clipNode = getJson(elementNode, "clip");
        Vec4i clip;
        clip.x = getJsonInt(clipNode, "x");
        clip.y = getJsonInt(clipNode, "y");
        clip.z = getJsonInt(clipNode, "w");
        clip.w = getJsonInt(clipNode, "h");
        element._clip = clip;

        final switch(element._type) with(ElementType) {
        case SpriteType:
        case BorderedBrushType:
        case BorderlessBrushType:
            break;
        case TilesetType:
            element._columns = getJsonInt(elementNode, "columns");
            element._lines = getJsonInt(elementNode, "lines");
            element._maxtiles = getJsonInt(elementNode, "maxtiles");
            break;
        case NinePatchType:
            element._top = getJsonInt(elementNode, "top");
            element._bottom = getJsonInt(elementNode, "bottom");
            element._left = getJsonInt(elementNode, "left");
            element._right = getJsonInt(elementNode, "right");
            break;
        }
        tabData._elements ~= element;
    }
    tabData._isDirty = false;
}

private void _saveData(TabData tabData) {
    JSONValue json;
    json["type"] = JSONValue("spritesheet");
    json["texture"] = JSONValue(convertPathToExport(relativePath(tabData._texturePath, dirName(tabData._dataPath))));
    JSONValue[] elementsNode;

    foreach(ElementData element; tabData._elements) {
        JSONValue elementNode;
        elementNode["name"] = JSONValue(element._name);

        final switch(element._type) with(ElementType) {
        case SpriteType:
            elementNode["type"] = JSONValue("sprite");
            break;
        case TilesetType:
            elementNode["type"] = JSONValue("tileset");
            break;
        case BorderedBrushType:
            elementNode["type"] = JSONValue("bordered_brush");
            break;
        case BorderlessBrushType:
            elementNode["type"] = JSONValue("borderless_brush");
            break;
        case NinePatchType:
            elementNode["type"] = JSONValue("ninepatch");
            break;
        }

        JSONValue clipNode;
        clipNode["x"] = JSONValue(element._clip.x);
        clipNode["y"] = JSONValue(element._clip.y);
        clipNode["w"] = JSONValue(element._clip.z);
        clipNode["h"] = JSONValue(element._clip.w);
        elementNode["clip"] = clipNode;

        final switch(element._type) with(ElementType) {
        case SpriteType:
        case BorderedBrushType:
        case BorderlessBrushType:
            break;
        case TilesetType:
            elementNode["columns"] = JSONValue(element._columns);
            elementNode["lines"] = JSONValue(element._lines);
            elementNode["maxtiles"] = JSONValue(element._maxtiles);
            break;
        case NinePatchType:
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