import std.stdio: writeln;
import atelier;
import editor, loader;

void main(string[] args) {
    try {
        setupApplication(args);
    }
    catch(Exception e) {
        writeln(e.msg);
    }
}

void setupApplication(string[] args) {
	//Initialization
	createApplication(Vec2u(1280, 720), "Image Editor");

    setWindowIcon("media/logo.png");
    import derelict.sdl2.sdl;
    bindKey("select", SDL_SCANCODE_1);
    bindKey("move", SDL_SCANCODE_2);
    bindKey("resize", SDL_SCANCODE_3);
    bindKey("resize2", SDL_SCANCODE_4);
    bindKey("up", SDL_SCANCODE_UP);
    bindKey("down", SDL_SCANCODE_DOWN);

    loadAssets();
    setDefaultFont(fetch!Font("VeraMono"));

	//Run
    onMainMenu(args);
	runApplication();
    destroyApplication();
}

void onMainMenu(string[] args) {
	removeRootGuis();
    addRootGui(new GraphicEditorGui(args));
}