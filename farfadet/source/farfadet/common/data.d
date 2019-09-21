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
    /// Key name
    string name = "untitled";

    /// General type
    ElementType type = ElementType.SpriteType;

    /// Texture region
    Vec4i clip = Vec4i.zero;

    /// Tileset specific data
    int columns = 1, lines = 1, maxtiles;

    /// NinePatch specific data
    int top, bottom, left, right;
}

/// An entire image/json file containing all its elements.
final class TabData {
    private {
        ElementData[] _elements;
        string _dataPath, _texturePath, _title = "untitled";
        Texture _texture;
        bool _isTitleDirty =  true;
    }

    @property {
        ElementData[] elements() { return _elements; }
        Texture texture() { return _texture; }
        bool isTitleDirty() const { return _isTitleDirty; }
        string title() { _isTitleDirty = false; return _title;}
        string dataPath() const { return _dataPath; }
        string texturePath() const { return _texturePath; }
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
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
    auto tabData = _tabs[_currentTabIndex];
    tabData._isTitleDirty = true;
    if(tabData._dataPath) {
        tabData._title = baseName(tabData._dataPath);
        setWindowTitle("Farfadet - " ~ tabData._dataPath ~ " ~ (" ~ tabData._texturePath ~ ")");
    }
    else {
        tabData._title = baseName(tabData._texturePath);
        setWindowTitle("Farfadet - * ~ (" ~ tabData._texturePath ~ ")");
    }
}

TabData getCurrentTab() {
    if(_currentTabIndex >= _tabs.length)
        throw new Exception("Tab index out of bounds");
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

private void _loadData(TabData tabData) {
    JSONValue json = parseJSON(readText(tabData._dataPath));

    if(getJsonStr(json, "type") != "spritesheet")
        return;

    tabData._texturePath = buildNormalizedPath(dirName(tabData._dataPath), convertPathToImport(getJsonStr(json, "texture")));
    auto elementsNode = getJsonArray(json, "elements");

    tabData._elements.length = 0uL;
    foreach(JSONValue elementNode; elementsNode) {
        auto element = new ElementData;
        element.name = getJsonStr(elementNode, "name");

        switch(getJsonStr(elementNode, "type")) {
        case "sprite":
            element.type = ElementType.SpriteType;
            break;
        case "tileset":
            element.type = ElementType.TilesetType;
            break;
        case "bordered_brush":
            element.type = ElementType.BorderedBrushType;
            break;
        case "borderless_brush":
            element.type = ElementType.BorderlessBrushType;
            break;
        case "ninepatch":
            element.type = ElementType.NinePatchType;
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
        element.clip = clip;

        final switch(element.type) with(ElementType) {
        case SpriteType:
        case BorderedBrushType:
        case BorderlessBrushType:
            break;
        case TilesetType:
            element.columns = getJsonInt(elementNode, "columns");
            element.lines = getJsonInt(elementNode, "lines");
            element.maxtiles = getJsonInt(elementNode, "maxtiles");
            break;
        case NinePatchType:
            element.top = getJsonInt(elementNode, "top");
            element.bottom = getJsonInt(elementNode, "bottom");
            element.left = getJsonInt(elementNode, "left");
            element.right = getJsonInt(elementNode, "right");
            break;
        }
        tabData._elements ~= element;
    }
}

private void _saveData(TabData tabData) {
    JSONValue json;
    json["type"] = JSONValue("spritesheet");
    json["texture"] = JSONValue(convertPathToExport(relativePath(tabData._texturePath, dirName(tabData._dataPath))));
    JSONValue[] elementsNode;

    foreach(ElementData element; tabData._elements) {
        JSONValue elementNode;
        elementNode["name"] = JSONValue(element.name);

        final switch(element.type) with(ElementType) {
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
        clipNode["x"] = JSONValue(element.clip.x);
        clipNode["y"] = JSONValue(element.clip.y);
        clipNode["w"] = JSONValue(element.clip.z);
        clipNode["h"] = JSONValue(element.clip.w);
        elementNode["clip"] = clipNode;

        final switch(element.type) with(ElementType) {
        case SpriteType:
        case BorderedBrushType:
        case BorderlessBrushType:
            break;
        case TilesetType:
            elementNode["columns"] = JSONValue(element.columns);
            elementNode["lines"] = JSONValue(element.lines);
            elementNode["maxtiles"] = JSONValue(element.maxtiles);
            break;
        case NinePatchType:
            elementNode["top"] = JSONValue(element.top);
            elementNode["bottom"] = JSONValue(element.bottom);
            elementNode["left"] = JSONValue(element.left);
            elementNode["right"] = JSONValue(element.right);
            break;
        }

        elementsNode ~= elementNode;
    }
    json["elements"] = elementsNode;
    std.file.write(tabData._dataPath, toJSON(json, true));
}