module farfadet.gui.file.open_modal;

import std.file, std.path, std.string;
import atelier;
import farfadet.common;
import farfadet.gui.file.editable_path_gui;

final class OpenModal: GuiElement {
    final class DirListGui: VList {
        private {
            string[] _subDirs;
        }

        this() {
            super(Vec2f(400f, 300f));
        }

        override void onCallback(string id) {
            super.onCallback(id);
            if(id == "list") {
                triggerCallback();
            }
        }

        override void draw() {
            drawFilledRect(origin, size, Color(.08f, .09f, .11f));
        }

        void add(string subDir, Color color) {
            auto btn = new TextButton(getDefaultFont(), subDir);
            btn.label.color = color;
            addChildGui(btn);
            _subDirs ~= subDir;
        }

        string getSubDir() {
            if(selected() >= _subDirs.length)
                throw new Exception("Subdirectory index out of range");
            return _subDirs[selected()];
        }

        void reset() {
            removeChildrenGuis();
            _subDirs.length = 0;
        }
    }

	private {
        EditablePathGui _pathLabel;
        DirListGui _list;
		string _path, _fileName;
        Label _filePathLabel;
        GuiElement _applyBtn;
    }

	this() {
        if(hasTab()) {
            auto tabData = getCurrentTab();
            if(tabData.hasSavePath())
                _path = dirName(tabData.dataPath());
            else if(hasTemplate())
                _path = getTemplateAssetsPath();
            else
                _path = dirName(tabData.texturePath());
        }
        else if(hasTemplate())
            _path = getTemplateAssetsPath();
        else {
            _path = dirName(getcwd());
        }

        size(Vec2f(500f, 500f));
        setAlign(GuiAlignX.center, GuiAlignY.center);

        Font font = getDefaultFont();

        { //Title
            auto title = new Label(font, "File to open:");
            title.setAlign(GuiAlignX.left, GuiAlignY.top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        {
            _pathLabel = new EditablePathGui(_path);
            _pathLabel.setAlign(GuiAlignX.left, GuiAlignY.top);
            _pathLabel.position = Vec2f(20f, 50f);
            _pathLabel.setCallback(this, "path");
            addChildGui(_pathLabel);
        }

        {
            _filePathLabel = new Label(font, "File: ---");
            _filePathLabel.setAlign(GuiAlignX.left, GuiAlignY.bottom);
            _filePathLabel.position = Vec2f(20f, 30f);
            addChildGui(_filePathLabel);
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.right, GuiAlignY.bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton(font, "Open");
            applyBtn.size = Vec2f(80f, 35f);
            applyBtn.setCallback(this, "apply");
            applyBtn.isLocked = true;
            box.addChildGui(applyBtn);
            _applyBtn = applyBtn;

            auto cancelBtn = new TextButton(font, "Cancel");
            cancelBtn.size = Vec2f(80f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }

        { //List
            auto vbox = new VContainer;
            vbox.setAlign(GuiAlignX.center, GuiAlignY.center);
            vbox.position = Vec2f.zero;
            addChildGui(vbox);

            {
                auto hbox = new HContainer;
                vbox.addChildGui(hbox);

                auto parentBtn = new TextButton(getDefaultFont(), "Parent");
                parentBtn.setCallback(this, "parent_folder");
                hbox.addChildGui(parentBtn);
            }
            {
                _list = new DirListGui;
                _list.setCallback(this, "file");
                vbox.addChildGui(_list);
            }
        }

        reloadList();

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
    
    string getPath() {
        return buildPath(_path, _fileName);
    }
    
    override void onCallback(string id) {
        switch(id) {
        case "path":
            if(!exists(_pathLabel.text)) {
                _pathLabel.text = _path;
            }
            else if(isDir(_pathLabel.text)) {
                _path = _pathLabel.text;
                reloadList();
            }
            else {
                _path = dirName(_pathLabel.text);
                _fileName = baseName(_pathLabel.text);
                _filePathLabel.text = "File: " ~ _fileName;
                _applyBtn.isLocked = false;
            }
            break;
        case "file":
            string path = buildPath(_path, _list.getSubDir());
            if(isDir(path)) {
                _path = path;
                reloadList();
            }
            else {
                _fileName = _list.getSubDir();
                _filePathLabel.text = "File: " ~ _fileName;
                _applyBtn.isLocked = false;
            }
            break;
        case "parent_folder":
            _path = dirName(_path);
            reloadList();
            break;
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

    
    
    private void reloadList() {
        _fileName = "";
        _filePathLabel.text = "File: ---";
        _applyBtn.isLocked = true;
        _pathLabel.text = _path;
        _list.reset();
        auto files = dirEntries(_path, SpanMode.shallow);
        foreach(file; files) {
            const auto type = getFileType(file);
            final switch(type) with(FileType) {
            case DirectoryType:
                _list.add(baseName(file), Color.gray);
                continue;
            case JsonFileType:
                _list.add(baseName(file), Color.green);
                continue;
            case ImageFileType:
                _list.add(baseName(file), Color.blue);
                continue;
            case InvalidType:
                continue;
            }
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}