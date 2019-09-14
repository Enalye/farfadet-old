module farfadet.gui.file.editable_path;

import atelier;

final class EditablePathGui: GuiElement {
    Label label;
    InputField inputField;
    bool isEditingName, isFirstClick = true;

    @property {
        string text() const { return label.text; }
        string text(string t) {
            label.text = t;
            size = label.size;
            return label.text;
        }
    }

    this(string path = "untitled") {
        label = new Label(path);
        label.setAlign(GuiAlignX.Center, GuiAlignY.Center);
        addChildGui(label);
        size = label.size;
    }

    override void onCallback(string id) {
        if(id != "editname")
            return;
        applyEditedName();        
    }

    override void update(float deltaTime) {
        if(!isSelected && isEditingName) {
            applyEditedName();
        }
        else if(!isSelected) {
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
    }

    override void onSubmit() {
        if(isSelected && !isEditingName) {
            if(!isFirstClick) {
                isEditingName = true;
                removeChildrenGuis();
                inputField = new InputField(size, label.text != "untitled" ? label.text : "");
                inputField.setAlign(GuiAlignX.Center, GuiAlignY.Center);
                inputField.setCallback(this, "editname");
                inputField.hasFocus = true;
                addChildGui(inputField);
            }
            isFirstClick = false;
        }
        triggerCallback();
    }
}