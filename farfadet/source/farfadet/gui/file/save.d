module farfadet.gui.file.save;

import std.file, std.path;
import atelier;
import farfadet.gui.file.editable_path;

final class SaveJsonGui: GuiElement {
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

        void add(string subDir) {
            addChildGui(new TextButton(getDefaultFont(), subDir));
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
		InputField _inputField;
        EditablePathGui _pathLabel;
        DirListGui _list;
		string _path;
        bool _hasPath;
    }

	this() {
        _path = dirName(thisExePath());

        size(Vec2f(500f, 500f));
        setAlign(GuiAlignX.Center, GuiAlignY.Center);

        Font font = getDefaultFont();

        { //Title
            auto title = new Label(font, "Save to Json:");
            title.setAlign(GuiAlignX.Left, GuiAlignY.Top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        {
            _pathLabel = new EditablePathGui(_path);
            _pathLabel.setAlign(GuiAlignX.Left, GuiAlignY.Top);
            _pathLabel.position = Vec2f(20f, 50f);
            addChildGui(_pathLabel);
        }

        { //Text Field
            auto box = new HContainer;
            box.setAlign(GuiAlignX.Center, GuiAlignY.Bottom);
            box.position = Vec2f(0f, 60f);
            addChildGui(box);

            _inputField = new InputField(Vec2f(300f, 25f), "", true);
            _inputField.setCallback(this, "apply");
            box.addChildGui(_inputField);

            box.addChildGui(new Label(font, ".json"));
        }

        { //Validation
            auto box = new HContainer;
            box.setAlign(GuiAlignX.Right, GuiAlignY.Bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton(font, "Save");
            applyBtn.size = Vec2f(80f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);

            auto cancelBtn = new TextButton(font, "Cancel");
            cancelBtn.size = Vec2f(80f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }

        { //List
            auto vbox = new VContainer;
            vbox.setAlign(GuiAlignX.Center, GuiAlignY.Center);
            vbox.position = Vec2f(0f, -50f);
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
                _list.setCallback(this, "sub_folder");
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
            easingFunction: getEasingFunction("sine-out")
        };
        addState("default", defaultState);

        setState("hidden");
        doTransitionState("default");
	}

    string getPath() {
        return _path;
    }

    bool hasPath() {
        return _hasPath;
    }

    override void onCallback(string id) {
        switch(id) {
        case "sub_folder":
            _path = buildNormalizedPath(_path, _list.getSubDir());
            reloadList();
            break;
        case "parent_folder":
            _path = dirName(_path);
            reloadList();
            break;
        case "apply":
            _path = buildNormalizedPath(_path, setExtension(_inputField.text, ".json"));
            if(!isValidPath(_path))
                break;
            if(!exists(dirName(_path)))
                break;
            _hasPath = true;
            triggerCallback();
            break;
        case "cancel":
            _hasPath = false;
            triggerCallback();
            break;
        default:
            break;
        }
    }

    void reloadList() {
        _pathLabel.text = _path;
        _list.reset();
        auto files = dirEntries(_path, SpanMode.shallow);
        foreach(file; files) {
            if(!file.isDir())
                continue;
            _list.add(baseName(file));
        }
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}