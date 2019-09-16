module farfadet.gui.tabs;

import atelier;

final class TabsGui: GuiElement {
    this() {
        size = Vec2f(screenHeight, 35f);
    }

    override void draw() {
        drawFilledRect(origin, size, Color.red);
    }
}