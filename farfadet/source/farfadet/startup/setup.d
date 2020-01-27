module farfadet.startup.setup;

import std.file: exists, thisExePath;
import std.path: buildNormalizedPath, dirName;
import atelier;
import farfadet.gui;
import farfadet.startup.loader;

void setupApplication(string[] args) {
	//Initialization
	createApplication(Vec2u(1280, 720), "Farfadet");

    const string iconPath = buildNormalizedPath(dirName(thisExePath()), "assets", "media", "logo.png");
	if(exists(iconPath))
		setWindowIcon(iconPath);

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