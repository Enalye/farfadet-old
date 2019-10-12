module farfadet.gui.tabs;

import std.path;
import atelier;
import farfadet.common;

final private class TabButtonGui: GuiElement {
    private {
        Label _label;
        TabData _tabData;
        TabsGui _tabs;
        bool _isDeleted;
    }

    this(TabsGui tabs, TabData tabData) {
        _tabs = tabs;
        _tabData = tabData;
        _label = new Label("untitled");

        GuiState hiddenState = {
            color: Color(1f, 1f, 1f, 0f),
            scale: Vec2f(0f, 1f),
            time: .5f,
            easingFunction: getEasingFunction(EasingAlgorithm.sineInOut)
        };

        GuiState visibleState = {
            time: .5f,
            easingFunction: getEasingFunction(EasingAlgorithm.sineInOut)
        };

        _label.addState("hidden", hiddenState);
        _label.addState("visible", visibleState);
        _label.setState("hidden");


        _label.setAlign(GuiAlignX.center, GuiAlignY.center);
        addChildGui(_label);

        size(Vec2f(_label.size.x + 20f, 35f));

        GuiState startState = {
            scale: Vec2f(0f, 1f),
            time: .5f,
            easingFunction: getEasingFunction(EasingAlgorithm.sineInOut)
        };

        GuiState endState = {
            scale: Vec2f(0f, 1f),
            time: .5f,
            easingFunction: getEasingFunction(EasingAlgorithm.sineInOut),
            callbackId: "end"
        };

        GuiState defaultState = {
            time: .5f,
            easingFunction: getEasingFunction(EasingAlgorithm.sineInOut)
        };

        addState("start", startState);
        addState("default", defaultState);
        addState("end", endState);

        setState("start");
        doTransitionState("default");
        _label.doTransitionState("visible");
    }

    override void update(float deltaTime) {
        if(!hasTab())
            return;
        isSelected = getCurrentTab() == _tabData;
        if(isSelected) {
            if(_tabData.isTitleDirty) {
                _tabData.isTitleDirty = false;
                _label.text = _tabData.title;
                size(Vec2f(_label.size.x + 20f, 35f));
            }
        }
    }

    override void onSubmit() {
        if(isLocked)
            return;
        if(!isSelected) {
            setCurrentTab(_tabData);
            triggerCallback();
        }
    }

    override void draw() {
        drawFilledRect(origin, scaledSize, Color(.12f, .13f, .19f));
        if(isLocked)
            return;
        if(isHovered)
            drawFilledRect(origin, scaledSize, Color(.2f, .2f, .2f));
        if(isClicked)
            drawFilledRect(origin, scaledSize, Color(.5f, .5f, .5f));
        if(isSelected)
            drawFilledRect(origin, scaledSize, Color(.4f, .4f, .5f));
    }

    void close() {
        doTransitionState("end");
        _label.doTransitionState("hidden");
        isLocked = true;
    }
    
    override void onCallback(string id) {
        if(id == "end") {
            _isDeleted = true;
            _tabs._remove();
        }
    }
}

final class TabsGui: GuiElementCanvas {
    private {
        HContainer _box;
    }

    this() {
        size(Vec2f(screenHeight, 35f));
        setEventHook(true);

        _box = new HContainer;
        addChildGui(_box);
    }

    override void draw() {
        drawFilledRect(origin, size, Color(.11f, .09f, .18f));
    }

    override void onEvent(Event event) {
        if(event.type == EventType.mouseWheel) {
            const float delta = event.position.y - event.position.x;
            canvas.position.x -= delta * 50f;
            canvas.position = canvas.position.clamp(canvas.size / 2f, Vec2f(_box.size.x - canvas.size.x / 2f, canvas.size.y));
        }
    }

    override void onCallback(string id) {
        if(id == "tab") {
            triggerCallback();
        }
    }

    void addTab() {
        if(!hasTab())
            return;
        auto tabData = getCurrentTab();
        auto tabGui = new TabButtonGui(this, tabData);
        tabGui.setCallback(this, "tab");
        _box.addChildGui(tabGui);
    }

    void removeTab() {
        foreach(TabButtonGui tabGui; cast(TabButtonGui[])_box.children()) {
            if(tabGui._tabData == getCurrentTab()) {
                tabGui.close();
            }
        }
    }

    void _remove() {
        TabButtonGui[] tabs;
        foreach(TabButtonGui tabGui; cast(TabButtonGui[])_box.children()) {
            if(!tabGui._isDeleted) {
                tabs ~= tabGui;
            }
        }
        _box.removeChildrenGuis();
        foreach(TabButtonGui tabGui; tabs) {
            _box.addChildGui(tabGui);
        }
    }
}