module farfadet.startup.setup;

import atelier;
import farfadet.gui;
import farfadet.startup.loader;

void setupApplication(string[] args) {
	//Initialization
	createApplication(Vec2u(1280, 720), "Farfadet");

    setWindowIcon("media/logo.png");
    import derelict.sdl2.sdl;
    bindKey("select", SDL_SCANCODE_1);
    bindKey("move", SDL_SCANCODE_2);
    bindKey("resize-corner", SDL_SCANCODE_3);
    bindKey("resize-border", SDL_SCANCODE_4);
    bindKey("up", SDL_SCANCODE_UP);
    bindKey("down", SDL_SCANCODE_DOWN);
    bindKey("left", SDL_SCANCODE_LEFT);
    bindKey("right", SDL_SCANCODE_RIGHT);
    bindKey("lctrl", SDL_SCANCODE_LCTRL);
    bindKey("rctrl", SDL_SCANCODE_RCTRL);
    bindKey("lshift", SDL_SCANCODE_LSHIFT);
    bindKey("rshift", SDL_SCANCODE_RSHIFT);
    bindKey("all", SDL_SCANCODE_Q);
    bindKey("save", SDL_SCANCODE_S);
    bindKey("rename", SDL_SCANCODE_R);
    bindKey("open", SDL_SCANCODE_O);
    bindKey("open2", SDL_SCANCODE_I);
    bindKey("close", SDL_SCANCODE_P);
    bindKey("dup", SDL_SCANCODE_D);
    bindKey("remove", SDL_SCANCODE_DELETE);
    bindKey("add", SDL_SCANCODE_A);
    bindKey("add2", SDL_SCANCODE_N);
    bindKey("reload", SDL_SCANCODE_F);
    bindKey("reload-texture", SDL_SCANCODE_G);

    loadAssets();
    setDefaultFont(fetch!Font("VeraMono"));

	//Run
    onMainMenu(args);
	runApplication();
    destroyApplication();
}

private void onMainMenu(string[] args) {
	removeRootGuis();
    addRootGui(new GraphicEditorGui(args));
}