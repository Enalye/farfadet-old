module farfadet.startup.setup;

import atelier;
import farfadet.gui;
import farfadet.startup.loader;

void setupApplication(string[] args) {
	//Initialization
	createApplication(Vec2u(1280, 720), "Farfadet");

    setWindowIcon("media/logo.png");

    loadAssets();
    setDefaultFont(fetch!TrueTypeFont("VeraMono"));

	//Run
    onMainMenu(args);
	runApplication();
    destroyApplication();
}

private void onMainMenu(string[] args) {
	removeRootGuis();
    addRootGui(new GraphicEditorGui(args));
}