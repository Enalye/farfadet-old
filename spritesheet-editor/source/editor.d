module editor;

import std.path, std.file;
import atelier;
import viewer, elements, properties, previewer, imgelement, save;

private final class BrushGui: GuiElement {
    Sprite offSprite, onSprite;
    bool isOn;

    this() {
        size(Vec2f(50f, 50f));
    }

    override void onSubmit() {
        triggerCallback();
    }
    
    override void draw() {
        offSprite.fit(size);
        onSprite.fit(size);
        if(isOn)
            onSprite.draw(center);
        else
            offSprite.draw(center);
    }
}

private final class TaskbarButtonGui: Button {
    private Label _label;

    this(string text) {
        _label = new Label(text);
        _label.setAlign(GuiAlignX.Center, GuiAlignY.Center);
        addChildGui(_label);

        size(Vec2f(_label.size.x + 20f, 50f));
    }

    override void draw() {
        if(isHovered)
            drawFilledRect(origin, size, Color(.2f, .2f, .2f));
        if(isClicked)
            drawFilledRect(origin, size, Color(.5f, .5f, .5f));
    }
}

final class GraphicEditorGui: GuiElement {
    ViewerGui viewerGui;
    ElementsListGui listGui;
    PropertiesGui propertiesGui;
    PreviewerGui previewerGui;
    BrushGui brushSelectGui, brushMoveGui, brushResizeGui;

    string jsonPath, srcPath;

    this() {
        setAlign(GuiAlignX.Left, GuiAlignY.Top);
        size = screenSize;

        viewerGui = new ViewerGui;
        propertiesGui = new PropertiesGui;
        propertiesGui.setAlign(GuiAlignX.Right, GuiAlignY.Top);
        addChildGui(propertiesGui);

        listGui = new ElementsListGui;
        previewerGui = new PreviewerGui;
        viewerGui.previewerGui = previewerGui;

        viewerGui.setCallback(this, "selection");
        propertiesGui.setCallback(this, "properties");
        listGui.setCallback(this, "elements");

        auto cursor = fetch!Sprite("editor.cursor");
        cursor.size *= 2f;
        setWindowCursor(cursor);

        {
            auto box = new VContainer;
            box.setAlign(GuiAlignX.Left, GuiAlignY.Bottom);
            box.setChildAlign(GuiAlignX.Center);
            auto speedSlider = new HScrollbar;
            speedSlider.setHint("Playback speed");
            speedSlider.size = Vec2f(200f, 10f);
            speedSlider.min = .1f;
            speedSlider.max = 2f;
            speedSlider.step = 20;
            previewerGui.playbackSpeedSlider = speedSlider;
            speedSlider.setCallback(previewerGui, "speed");
            box.addChildGui(speedSlider);
            box.addChildGui(previewerGui);
            addChildGui(box);
        }

        {
            auto box = new VContainer;
            box.setAlign(GuiAlignX.Center, GuiAlignY.Top);
            box.setChildAlign(GuiAlignX.Right);
            {
                auto btns = new HContainer;

                auto saveBtn = new TaskbarButtonGui("Save");
                saveBtn.setCallback(this, "save");
                btns.addChildGui(saveBtn);

                auto saveAsBtn = new TaskbarButtonGui("Save As");
                saveAsBtn.setCallback(this, "save_as");
                btns.addChildGui(saveAsBtn);

                auto loadBtn = new TaskbarButtonGui("Load");
                loadBtn.setCallback(this, "load");
                btns.addChildGui(loadBtn);

                auto reloadBtn = new TaskbarButtonGui("Reload");
                reloadBtn.setCallback(this, "reload");
                btns.addChildGui(reloadBtn);

                box.addChildGui(btns);
                box.addChildGui(viewerGui);
            }
            addChildGui(box);
        }

        {
            auto box = new VContainer;
            box.setAlign(GuiAlignX.Left, GuiAlignY.Top);
            {
                auto btns = new HContainer;
                
                auto addBtn = new TaskbarButtonGui("Add");
                addBtn.setCallback(this, "add");
                btns.addChildGui(addBtn);
                auto dupBtn = new TaskbarButtonGui("Dup");
                dupBtn.setCallback(this, "dup");
                btns.addChildGui(dupBtn);
                auto removeBtn = new TaskbarButtonGui("Remove");
                removeBtn.setCallback(this, "remove");
                btns.addChildGui(removeBtn);
                auto upBtn = new TaskbarButtonGui("Up");
                upBtn.setCallback(this, "up");
                btns.addChildGui(upBtn);
                auto downBtn = new TaskbarButtonGui("Down");
                downBtn.setCallback(this, "down");
                btns.addChildGui(downBtn);
                box.addChildGui(btns);
            }
            box.addChildGui(listGui);
            addChildGui(box);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.Right, GuiAlignY.Bottom);
            box.position = Vec2f(75f, 40f);
            box.spacing = Vec2f(15f, 10f);

            {
                auto vbox = new VContainer;
                vbox.addChildGui(new Label("1"));
                brushSelectGui = new BrushGui;
                brushSelectGui.offSprite = fetch!Sprite("editor.select-off");
                brushSelectGui.onSprite = fetch!Sprite("editor.select-on");
                brushSelectGui.setCallback(viewerGui, "brush_select");
                brushSelectGui.isOn = true;
                viewerGui.brushSelectGui = brushSelectGui;
                vbox.addChildGui(brushSelectGui);
                box.addChildGui(vbox);
            }
            {
                auto vbox = new VContainer;
                vbox.addChildGui(new Label("2"));
                brushMoveGui = new BrushGui;
                brushMoveGui.offSprite = fetch!Sprite("editor.move-off");
                brushMoveGui.onSprite = fetch!Sprite("editor.move-on");
                brushMoveGui.setCallback(viewerGui, "brush_move");
                viewerGui.brushMoveGui = brushMoveGui;
                vbox.addChildGui(brushMoveGui);
                box.addChildGui(vbox);
            }
            {
                auto vbox = new VContainer;
                vbox.addChildGui(new Label("3"));
                brushResizeGui = new BrushGui;
                brushResizeGui.offSprite = fetch!Sprite("editor.resize-off");
                brushResizeGui.onSprite = fetch!Sprite("editor.resize-on");
                brushResizeGui.setCallback(viewerGui, "brush_resize");
                viewerGui.brushResizeGui = brushResizeGui;
                vbox.addChildGui(brushResizeGui);
                box.addChildGui(vbox);
            }
            addChildGui(box);
        }
    }

    override void update(float deltaTime) {
        super.update(deltaTime);

        if(listGui.isSelectingData()) {
            auto data = listGui.getSelectedData();
            auto clip = propertiesGui.getClip();

            data.clip = clip;
            
            auto type = propertiesGui.getImgType();
            viewerGui.imgType = type;
            data.type = type;
            
            data.columns = propertiesGui.getColumns();
            data.lines = propertiesGui.getLines();
            data.maxtiles = propertiesGui.getMaxTiles();
            data.top = propertiesGui.getTop();
            data.bottom = propertiesGui.getBottom();
            data.left = propertiesGui.getLeft();
            data.right = propertiesGui.getRight();

            viewerGui.columns = data.columns;
            viewerGui.lines = data.lines;
            viewerGui.maxtiles = data.maxtiles;
            viewerGui.top = data.top;
            viewerGui.bottom = data.bottom;
            viewerGui.left = data.left;
            viewerGui.right = data.right;

            previewerGui.type = data.type;
            previewerGui.clip = data.clip;
            previewerGui.columns = data.columns;
            previewerGui.lines = data.lines;
            previewerGui.maxtiles = data.maxtiles;
            previewerGui.top = data.top;
            previewerGui.bottom = data.bottom;
            previewerGui.left = data.left;
            previewerGui.right = data.right;
        }
    }

    override void onEvent(Event event) {
        super.onEvent(event);
        if(event.type == EventType.DropFile) {
            string path = relativePath(event.str);
            auto ext = extension(path);
            if(ext == ".png") {
                load(path);
            }
            else if(ext == ".json") {
                loadJson(path);
            }
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.08f, .10f, .13f));
        drawFilledRect(origin, origin + Vec2f(size.x - 280f, 50f), Color(.12f, .12f, .12f));
    }

    override void onCallback(string id) {
        switch(id) {
        case "save":
            save();
            break;
        case "save_as":
            saveAs();
            break;
        case "reload":
            reload();
            break;
        case "load":
            load();
            break;
        case "save_gui":
            stopModalGui();
            auto saveGui = getModalGui!SaveJsonGui;
            if(saveGui.hasPath()) {
                jsonPath = stripExtension(relativePath(absolutePath(saveGui.getPath()), absolutePath("data/images/")));                
                listGui.save(saveGui.getPath(), srcPath);
                setWindowTitle("Image Editor - " ~ jsonPath);
            }
            break;
        case "load_gui":
            stopModalGui();
            auto loadGui = getModalGui!LoadJsonGui;
            if(loadGui.hasPath()) {
                loadJson(loadGui.getPath());
            }
            break;
        case "add":
            listGui.addElement();
            break;
        case "dup":
            listGui.dupElement();
            break;
        case "remove":
            auto gui = new RemoveLayerGui;
            gui.setCallback(this, "remove.modal");
            setModalGui(gui);
            break;
        case "remove.modal":
            auto gui = getModalGui!RemoveLayerGui;
            stopModalGui();
            listGui.removeElement();
            break;
        case "up":
            listGui.moveUpElement();
            break;
        case "down":
            listGui.moveDownElement();
            break;
        case "selection":
            if(listGui.isSelectingData()) {
                auto clip = viewerGui.getClip();
                auto data = listGui.getSelectedData();
                propertiesGui.setClip(clip);
                data.clip = clip;
            }
            break;
        case "properties":
            if(!listGui.isSelectingData())
                break;
            auto data = listGui.getSelectedData();

            if(propertiesGui.isClipDirty) {
                propertiesGui.isClipDirty = false;
                auto clip = propertiesGui.getClip();
                viewerGui.setClip(clip);

                data.clip = clip;
            }
            if(propertiesGui.isTypeDirty) {
                auto type = propertiesGui.getImgType();
                viewerGui.imgType = type;
                data.type = type;
            }
            if(propertiesGui.areSettingsDirty) {
                data.columns = propertiesGui.getColumns();
                data.lines = propertiesGui.getLines();
                data.maxtiles = propertiesGui.getMaxTiles();
                data.top = propertiesGui.getTop();
                data.bottom = propertiesGui.getBottom();
                data.left = propertiesGui.getLeft();
                data.right = propertiesGui.getRight();
            }
            propertiesGui.load();
            break;
        case "elements":
            if(listGui.isSelectingData()) {
                auto data = listGui.getSelectedData();

                viewerGui.isActive = true;
                propertiesGui.isActive = true;
                previewerGui.isActive = true;
                propertiesGui.setClip(data.clip);
                viewerGui.setClip(data.clip);

                propertiesGui.setImgType(data.type);

                propertiesGui.setColumns(data.columns);
                propertiesGui.setLines(data.lines);
                propertiesGui.setMaxTiles(data.maxtiles);
                propertiesGui.setTop(data.top);
                propertiesGui.setBottom(data.bottom);
                propertiesGui.setLeft(data.left);
                propertiesGui.setRight(data.right);

                propertiesGui.load();
            }
            else {
                viewerGui.isActive = false;
                propertiesGui.isActive = false;
            }
            break;
        default:
            break;
        }
    }

    Texture texture;
    void load(string path) {
        jsonPath = "";
        srcPath = path;
        texture = new Texture(srcPath);
        viewerGui.setTexture(texture);
        previewerGui.setTexture(texture);

        listGui.removeChildrenGuis();
        propertiesGui.removeChildrenGuis();

        viewerGui.isActive = false;
        propertiesGui.isActive = false;
        previewerGui.isActive = false;
        
        propertiesGui.setClip(Vec4i.zero);
        viewerGui.setClip(Vec4i.zero);

        propertiesGui.setImgType(ImgType.SpriteType);

        propertiesGui.setColumns(0);
        propertiesGui.setLines(0);
        propertiesGui.setMaxTiles(0);
        propertiesGui.setTop(0);
        propertiesGui.setBottom(0);
        propertiesGui.setLeft(0);
        propertiesGui.setRight(0);

        propertiesGui.load();

        setWindowTitle("Image Editor - *");
    }
    
    void loadJson(string path) {
        jsonPath = stripExtension(relativePath(absolutePath(path), absolutePath("data/images/")));
        srcPath = listGui.load(path);
        texture = new Texture(srcPath);
        viewerGui.setTexture(texture);
        previewerGui.setTexture(texture);

        setWindowTitle("Image Editor - " ~ jsonPath);
    }

    void save() {
        if(!srcPath.length)
            return;
        if(!jsonPath.length) {
            saveAs();
            return;
        }
        auto path = buildPath("data/images/", setExtension(jsonPath, ".json"));
        if(!isValidPath(path)) {
            saveAs();
            return;
        }
        if(!exists(dirName(path)))  {
            saveAs();
            return;
        }
        listGui.save(path, srcPath);
        setWindowTitle("Image Editor - " ~ jsonPath);
    }

    void saveAs() {
        if(!srcPath.length)
            return;
        auto saveGui = new SaveJsonGui;
        saveGui.setCallback(this, "save_gui");
        saveGui.setPath(jsonPath);
        setModalGui(saveGui);
    }

    void reload() {
        if(!jsonPath.length)
            return;

        auto path = buildPath("data/images/", setExtension(jsonPath, ".json"));
        srcPath = listGui.load(path);
        texture = new Texture(srcPath);
        viewerGui.setTexture(texture);
        previewerGui.setTexture(texture);

        setWindowTitle("Image Editor - " ~ jsonPath);
    }

    void load() {
        auto loadGui = new LoadJsonGui;
        loadGui.setCallback(this, "load_gui");
        setModalGui(loadGui);
    }
}

private final class RemoveLayerGui: GuiElement {
    this() {
        size(Vec2f(400f, 100f));
        setAlign(GuiAlignX.Center, GuiAlignY.Center);

        { //Title
            auto title = new Label("Do you want to delete this layer ?");
            title.setAlign(GuiAlignX.Left, GuiAlignY.Top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.Right, GuiAlignY.Bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton("Remove");
            applyBtn.size = Vec2f(100f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);

            auto cancelBtn = new TextButton("Cancel");
            cancelBtn.size = Vec2f(100f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }

        //States
        GuiState hiddenState = {
            offset: Vec2f(0f, -50f),
            color: Color.clear
        };
        addState("hidden", hiddenState);

        GuiState defaultState = {
            time: .5f,
            easingFunction: getEasingFunction("sine-out")
        };
        addState("default", defaultState);

        setState("hidden");
        doTransitionState("default");
    }

    override void onCallback(string id) {
        switch(id) {
        case "apply":
            triggerCallback();
            break;
        case "cancel":
            stopModalGui();
            break;
        default:
            break;
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}