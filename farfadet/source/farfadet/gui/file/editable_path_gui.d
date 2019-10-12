module farfadet.gui.file.editable_path_gui;

import atelier;

final class EditablePathGui: GuiElement {
    Label label;
    InputField inputField;
    bool isEditingName, isFirstClick = true;

    @property {
        string text() const { return label.text; }
        string text(string t) {
            label.text = t;
            size = Vec2f(400f, label.size.y);
            return label.text;
        }
    }

    this(string path = "untitled") {
        label = new Label(path);
        label.setAlign(GuiAlignX.left, GuiAlignY.center);
        addChildGui(label);
        size = label.size;
    }

    override void onCallback(string id) {
        if(id != "editname")
            return;
        applyEditedName();        
    }

    override void update(float deltaTime) {
        if(!hasFocus && isEditingName) {
            applyEditedName();
        }
        else if(!hasFocus) {
            isFirstClick = true;
        }
    }

    void applyEditedName() {
        if(!isEditingName)
            throw new Exception("The element is not in an editing state");
        isEditingName = false;
        isFirstClick = true;

        label.text = inputField.text;
        removeChildrenGuis();
        addChildGui(label);
        triggerCallback();
    }

    override void onFocus() {
        if(!hasCanvas) {
            isEditingName = false;
            isFirstClick = true;

            label.text = inputField.text;
            removeChildrenGuis();
            addChildGui(label);
        }
    }

    override void onSubmit() {
        if(!isEditingName) {
            if(!isFirstClick) {
                isEditingName = true;
                removeChildrenGuis();
                inputField = new InputField(size, label.text != "untitled" ? label.text : "");
                inputField.setAlign(GuiAlignX.center, GuiAlignY.center);
                inputField.setCallback(this, "editname");
                inputField.size = Vec2f(400f, label.size.y);
                inputField.hasFocus = true;
                addChildGui(inputField);
            }
            isFirstClick = false;
        }
        triggerCallback();
    }

    override void draw() {
        drawFilledRect(origin, size, Color.gray);
    }
}