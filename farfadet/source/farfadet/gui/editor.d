module farfadet.gui.editor;

import std.path, std.file;
import atelier;
import farfadet.common, farfadet.gui.file;
import farfadet.gui.viewer, farfadet.gui.elements, farfadet.gui.properties, farfadet.gui.previewer;
import farfadet.gui.tabs;

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
        _label.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(_label);

        size(Vec2f(_label.size.x + 20f, 50f));
    }

    override void draw() {
        _label.color = Color.white;
        if(isLocked) {
            drawFilledRect(origin, size, Color(.1f, .11f, .13f));
            _label.color = Color.grey;
            return;
        }
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
    TabsGui tabsGui;
    BrushGui brushSelectGui, brushMoveGui, brushResizeCornerGui, brushResizeBorderGui;
    
    private {
        TaskbarButtonGui _saveBtn, _saveAsBtn, _openBtn, _reloadBtn, _reloadTexBtn, _closeBtn;
        TaskbarButtonGui _addBtn, _dupBtn, _removeBtn, _upBtn, _downBtn;
    }

    this(string[] args) {
        setupData(this);
        setAlign(GuiAlignX.left, GuiAlignY.top);
        size = screenSize;

        viewerGui = new ViewerGui;
        propertiesGui = new PropertiesGui;
        propertiesGui.setAlign(GuiAlignX.right, GuiAlignY.top);
        addChildGui(propertiesGui);

        listGui = new ElementsListGui;
        previewerGui = new PreviewerGui;
        viewerGui.previewerGui = previewerGui;

        tabsGui = new TabsGui;
        tabsGui.setCallback(this, "tabs");

        viewerGui.setCallback(this, "selection");
        propertiesGui.setCallback(this, "properties");
        listGui.setCallback(this, "elements");

        auto cursor = fetch!Sprite("editor.cursor");
        cursor.size *= 2f;
        setWindowCursor(cursor);

        { // Previewer
            auto box = new VContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.bottom);
            box.setChildAlign(GuiAlignX.center);
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

        { // Taskbar
            auto box = new VContainer;
            box.setAlign(GuiAlignX.center, GuiAlignY.top);
            box.setChildAlign(GuiAlignX.right);
            {
                auto btns = new HContainer;

                _openBtn = new TaskbarButtonGui("Open");
                _openBtn.setCallback(this, "open");
                btns.addChildGui(_openBtn);

                _saveBtn = new TaskbarButtonGui("Save");
                _saveBtn.setCallback(this, "save");
                btns.addChildGui(_saveBtn);

                _saveAsBtn = new TaskbarButtonGui("Save As");
                _saveAsBtn.setCallback(this, "save-as");
                btns.addChildGui(_saveAsBtn);

                _reloadBtn = new TaskbarButtonGui("Reload");
                _reloadBtn.setCallback(this, "reload");
                btns.addChildGui(_reloadBtn);

                _reloadTexBtn = new TaskbarButtonGui("Update Texture");
                _reloadTexBtn.setCallback(this, "reload-texture");
                btns.addChildGui(_reloadTexBtn);

                _closeBtn = new TaskbarButtonGui("Close");
                _closeBtn.setCallback(this, "close");
                btns.addChildGui(_closeBtn);

                box.addChildGui(btns);
                box.addChildGui(tabsGui);
                box.addChildGui(viewerGui);
            }
            addChildGui(box);
        }

        { // Elements list
            auto box = new VContainer;
            box.setAlign(GuiAlignX.left, GuiAlignY.top);
            {
                auto btns = new HContainer;
                
                _addBtn = new TaskbarButtonGui("Add");
                _addBtn.setCallback(this, "add");
                btns.addChildGui(_addBtn);
                _dupBtn = new TaskbarButtonGui("Dup");
                _dupBtn.setCallback(this, "dup");
                btns.addChildGui(_dupBtn);
                _removeBtn = new TaskbarButtonGui("Remove");
                _removeBtn.setCallback(this, "remove");
                btns.addChildGui(_removeBtn);
                _upBtn = new TaskbarButtonGui("Up");
                _upBtn.setCallback(this, "up");
                btns.addChildGui(_upBtn);
                _downBtn = new TaskbarButtonGui("Down");
                _downBtn.setCallback(this, "down");
                btns.addChildGui(_downBtn);
                box.addChildGui(btns);
            }
            box.addChildGui(listGui);
            addChildGui(box);
        }

        { // Tools
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.position = Vec2f(5f, 40f);
            box.spacing = Vec2f(15f, 10f);

            { // Select tool
                auto vbox = new VContainer;
                vbox.addChildGui(new Label("1"));
                brushSelectGui = new BrushGui;
                brushSelectGui.offSprite = fetch!Sprite("editor.select-off");
                brushSelectGui.onSprite = fetch!Sprite("editor.select-on");
                brushSelectGui.setCallback(viewerGui, "brush.select");
                brushSelectGui.isOn = true;
                viewerGui.brushSelectGui = brushSelectGui;
                vbox.addChildGui(brushSelectGui);
                box.addChildGui(vbox);
            }
            { // Move tool
                auto vbox = new VContainer;
                vbox.addChildGui(new Label("2"));
                brushMoveGui = new BrushGui;
                brushMoveGui.offSprite = fetch!Sprite("editor.move-off");
                brushMoveGui.onSprite = fetch!Sprite("editor.move-on");
                brushMoveGui.setCallback(viewerGui, "brush.move");
                viewerGui.brushMoveGui = brushMoveGui;
                vbox.addChildGui(brushMoveGui);
                box.addChildGui(vbox);
            }
            { // Resize corner tool
                auto vbox = new VContainer;
                vbox.addChildGui(new Label("3"));
                brushResizeCornerGui = new BrushGui;
                brushResizeCornerGui.offSprite = fetch!Sprite("editor.resize-corner-off");
                brushResizeCornerGui.onSprite = fetch!Sprite("editor.resize-corner-on");
                brushResizeCornerGui.setCallback(viewerGui, "brush.resize-corner");
                viewerGui.brushResizeCornerGui = brushResizeCornerGui;
                vbox.addChildGui(brushResizeCornerGui);
                box.addChildGui(vbox);
            }
            { // Resize border tool
                auto vbox = new VContainer;
                vbox.addChildGui(new Label("4"));
                brushResizeBorderGui = new BrushGui;
                brushResizeBorderGui.offSprite = fetch!Sprite("editor.resize-border-off");
                brushResizeBorderGui.onSprite = fetch!Sprite("editor.resize-border-on");
                brushResizeBorderGui.setCallback(viewerGui, "brush.resize-border");
                viewerGui.brushResizeBorderGui = brushResizeBorderGui;
                vbox.addChildGui(brushResizeBorderGui);
                box.addChildGui(vbox);
            }
            addChildGui(box);
        }
    }

    override void update(float deltaTime) {
        super.update(deltaTime);

        if(isKeyDown("lctrl") || isKeyDown("rctrl")) {
            if(getKeyDown("open") || getKeyDown("open2"))
                onCallback("open");
            else if(getKeyDown("close"))
                onCallback("close");
            else if(getKeyDown("reload"))
                onCallback("reload");
            else if(getKeyDown("reload-texture"))
                onCallback("reload-texture");
            else if(getKeyDown("save")) {
                if(isKeyDown("lshift") || isKeyDown("rshift"))
                    onCallback("save-as");
                else
                    onCallback("save");
            }
            else if(getKeyDown("add") || getKeyDown("add2"))
                onCallback("add");
            else if(getKeyDown("remove"))
                onCallback("remove");
            else if(getKeyDown("dup"))
                onCallback("dup");
            else if(getKeyDown("up"))
                onCallback("up");
            else if(getKeyDown("down"))
                onCallback("down");
            else if(getKeyDown("left")) {
                setPreviousTab();
                reload();
            }
            else if(getKeyDown("right")) {
                setNextTab();
                reload();
            }
        }

        _saveBtn.isLocked = !hasTab();
        _saveAsBtn.isLocked = !hasTab();
        _reloadBtn.isLocked = !hasTab();
        _reloadTexBtn.isLocked = !hasTab();
        _closeBtn.isLocked = !hasTab();
        _addBtn.isLocked = !hasTab();
        _dupBtn.isLocked = !hasTab();
        _removeBtn.isLocked = !hasTab();
        _upBtn.isLocked = !hasTab();
        _downBtn.isLocked = !hasTab();

        if(listGui.isSelectingData()) {
            auto data = listGui.getSelectedData();
            auto clip = propertiesGui.getClip();

            data.clip = clip;
            
            auto type = propertiesGui.getImgType();
            viewerGui.elementType = type;
            data.type = type;
            
            data.flip = propertiesGui.getFlip();
            data.columns = propertiesGui.getColumns();
            data.lines = propertiesGui.getLines();
            data.maxtiles = propertiesGui.getMaxTiles();
            data.duration = propertiesGui.getDuration();
            data.marginX = propertiesGui.getMarginX();
            data.marginY = propertiesGui.getMarginY();
            data.top = propertiesGui.getTop();
            data.bottom = propertiesGui.getBottom();
            data.left = propertiesGui.getLeft();
            data.right = propertiesGui.getRight();

            viewerGui.columns = data.columns;
            viewerGui.lines = data.lines;
            viewerGui.maxtiles = data.maxtiles;
            viewerGui.duration = data.duration;
            viewerGui.marginX = data.marginX;
            viewerGui.marginY = data.marginY;
            viewerGui.top = data.top;
            viewerGui.bottom = data.bottom;
            viewerGui.left = data.left;
            viewerGui.right = data.right;

            previewerGui.type = data.type;
            previewerGui.flip = data.flip;
            previewerGui.clip = data.clip;
            previewerGui.columns = data.columns;
            previewerGui.lines = data.lines;
            previewerGui.maxtiles = data.maxtiles;
            previewerGui.duration = data.duration;
            previewerGui.marginX = data.marginX;
            previewerGui.marginY = data.marginY;
            previewerGui.top = data.top;
            previewerGui.bottom = data.bottom;
            previewerGui.left = data.left;
            previewerGui.right = data.right;
        }
    }

    override void onEvent(Event event) {
        super.onEvent(event);
        if(event.type == EventType.dropFile) {
            openTab(relativePath(event.str));
            reload();
            tabsGui.addTab();
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.08f, .10f, .13f));
        drawFilledRect(origin, origin + Vec2f(size.x - 280f, 50f), Color(.12f, .12f, .12f));
    }

    override void onCallback(string id) {
        switch(id) {
        case "close":
            if(!hasTab())
                break;
            if(getCurrentTab().isDirty) {
                auto gui = new WarningMessageGui("There are unsaved modifications. Do you want to close ?", "Close");
                gui.setCallback(this, "close.modal");
                setModalGui(gui);
            }
            else {
                tabsGui.removeTab();
                closeTab();
                reload();
            }
            break;
        case "save":
            if(!hasTab())
                break;
            save();
            break;
        case "save-as":
            if(!hasTab())
                break;
            saveAs();
            break;
        case "reload":
            if(!hasTab())
                break;
            reloadTab();
            reload();
            break;
        case "reload-texture":
            if(!hasTab())
                break;
            reloadTabTexture();
            reload();
            break;
        case "open":
            auto openModal = new OpenModal;
            openModal.setCallback(this, "open.modal");
            setModalGui(openModal);
            break;
        case "save.modal":
            stopModalGui();
            auto saveModal = getModalGui!SaveModal;
            setTabDataPath(saveModal.getPath());
            saveTab();
            break;
        case "open.modal":
            stopModalGui();
            auto loadGui = getModalGui!OpenModal;
            if(!openTab(loadGui.getPath())) {
                auto gui = new WarningMessageGui("Could not open this file", "", "Ok");
                setModalGui(gui);
            }
            else {
                reload();
                tabsGui.addTab();
            }
            break;
        case "close.modal":
            stopModalGui();
            tabsGui.removeTab();
            closeTab();
            reload();
            break;
        case "tabs":
            if(!hasTab())
                break;
            reload();
            break;
        case "add":
            if(!hasTab())
                break;
            listGui.addElement();
            break;
        case "dup":
            if(!hasTab())
                break;
            listGui.dupElement();
            break;
        case "remove":
            if(!hasTab())
                break;
            auto gui = new WarningMessageGui("Do you want to remove this key ?", "Remove");
            gui.setCallback(this, "remove.modal");
            setModalGui(gui);
            break;
        case "remove.modal":
            auto gui = getModalGui!WarningMessageGui;
            stopModalGui();
            listGui.removeElement();
            break;
        case "up":
            if(!hasTab())
                break;
            listGui.moveUpElement();
            break;
        case "down":
            if(!hasTab())
                break;
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
                viewerGui.elementType = type;
                data.type = type;
            }
            if(propertiesGui.areSettingsDirty) {
                data.flip = propertiesGui.getFlip();
                data.columns = propertiesGui.getColumns();
                data.lines = propertiesGui.getLines();
                data.maxtiles = propertiesGui.getMaxTiles();
                data.marginX = propertiesGui.getMarginX();
                data.marginY = propertiesGui.getMarginY();
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

                propertiesGui.setFlip(data.flip);
                propertiesGui.setColumns(data.columns);
                propertiesGui.setLines(data.lines);
                propertiesGui.setMaxTiles(data.maxtiles);
                propertiesGui.setMarginX(data.marginX);
                propertiesGui.setMarginY(data.marginY);
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

    void reload() {
        viewerGui.reload();
        previewerGui.reload();

        propertiesGui.removeChildrenGuis();

        viewerGui.isActive = false;
        propertiesGui.isActive = false;
        previewerGui.isActive = false;
        
        propertiesGui.setClip(Vec4i.zero);
        viewerGui.setClip(Vec4i.zero);

        propertiesGui.setImgType(ElementType.sprite);

        propertiesGui.setFlip(Flip.none);
        propertiesGui.setColumns(0);
        propertiesGui.setLines(0);
        propertiesGui.setMaxTiles(0);
        propertiesGui.setMarginX(0);
        propertiesGui.setMarginY(0);
        propertiesGui.setTop(0);
        propertiesGui.setBottom(0);
        propertiesGui.setLeft(0);
        propertiesGui.setRight(0);

        propertiesGui.load();
        listGui.reload();
    }

    /// Save an already saved project.
    void save() {
        if(!hasTab())
            return;
        auto tabData = getCurrentTab();
        if(tabData.hasSavePath())
            saveTab();
        else
            saveAs();
    }

    /// Select a new save file and save the project.
    void saveAs() {
        if(!hasTab())
            return;
        auto saveModal = new SaveModal;
        saveModal.setCallback(this, "save.modal");
        setModalGui(saveModal);
    }
}

private final class WarningMessageGui: GuiElement {
    this(string message, string action, string cancel = "Cancel") {
        setAlign(GuiAlignX.center, GuiAlignY.center);

        Font font = getDefaultFont();

        { //Title
            auto title = new Label(font, message);
            title.setAlign(GuiAlignX.left, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
            size(Vec2f(title.size.x + 40f, 100f));
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            if(action.length) {
                auto applyBtn = new TextButton(font, action);
                applyBtn.size = Vec2f(100f, 35f);
                applyBtn.setCallback(this, "apply");
                box.addChildGui(applyBtn);
            }

            auto cancelBtn = new TextButton(font, cancel);
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
            easingFunction: getEasingFunction(EasingAlgorithm.sineOut)
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