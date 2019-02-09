module save;

import std.file, std.path;
import atelier;

class SaveJsonGui: GuiElement {
	private {
		string _path;
		InputField _inputField;
        bool _hasPath;
    }

	this() {
        size(Vec2f(400f, 150f));
        setAlign(GuiAlignX.Center, GuiAlignY.Center);

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.Center, GuiAlignY.Center);
            addChildGui(box);

            box.addChildGui(new Label("data/images/"));

            _inputField = new InputField(Vec2f(200f, 25f), "", true);
            _inputField.setCallback(this, "apply");
            box.addChildGui(_inputField);

            box.addChildGui(new Label(".json"));
        }

        {
            auto title = new Label("Save Json");
            title.setAlign(GuiAlignX.Left, GuiAlignY.Top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.Right, GuiAlignY.Bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton("Save");
            applyBtn.size = Vec2f(80f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);

            auto cancelBtn = new TextButton("Cancel");
            cancelBtn.size = Vec2f(80f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }


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

    void setPath(string path) {
        _inputField.text = path;
        _path = path;
    }

    string getPath() {
        return _path;
    }

    bool hasPath() {
        return _hasPath;
    }

    override void onCallback(string id) {
        switch(id) {
        case "apply":
            _path = buildPath("data/images/", setExtension(_inputField.text, ".json"));
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

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}

class LoadJsonGui: GuiElement {
	private {
		string _path;
        bool _hasPath;
        VList _list;
        string[] filesList;
    }

	this() {
        size(Vec2f(300f, 450f));
        setAlign(GuiAlignX.Center, GuiAlignY.Center);

        {
            _list = new VList(Vec2f(200f, 300f));
            _list.setAlign(GuiAlignX.Center, GuiAlignY.Center);
            auto files = dirEntries("data/images/", "{*.json}", SpanMode.depth);
            foreach(file; files) {
                filesList ~= file;
                auto filePath = stripExtension(relativePath(absolutePath(file), absolutePath("data/images/")));
                _list.addChildGui(new TextButton(filePath));
            }
            addChildGui(_list);
        }

        {
            auto title = new Label("Load Json");
            title.setAlign(GuiAlignX.Left, GuiAlignY.Top);
            title.position = Vec2f(20f, 10f);
            addChildGui(title);
        }

        {
            auto box = new HContainer;
            box.setAlign(GuiAlignX.Right, GuiAlignY.Bottom);
            box.spacing = Vec2f(25f, 15f);
            addChildGui(box);

            auto applyBtn = new TextButton("Load");
            applyBtn.size = Vec2f(80f, 35f);
            applyBtn.setCallback(this, "apply");
            box.addChildGui(applyBtn);

            auto cancelBtn = new TextButton("Cancel");
            cancelBtn.size = Vec2f(80f, 35f);
            cancelBtn.setCallback(this, "cancel");
            box.addChildGui(cancelBtn);
        }


        GuiState hiddenState = {
            offset: Vec2f(-50f, 0f),
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
        case "apply":
            if(!_list.getChildrenGuisCount())
                break;
            _path = filesList[_list.selected];
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

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .08f, .15f));
    }

    override void drawOverlay() {
        drawRect(origin, size, Color.gray);
    }
}
