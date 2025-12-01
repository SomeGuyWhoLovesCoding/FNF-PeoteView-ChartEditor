package;

import lime.graphics.RenderContext;
import lime.ui.MouseButton;
import sys.io.File;
import sys.io.FileOutput;
import haxe.CallStack;
import lime.app.Application;
import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

@:publicFields
class Main extends Application
{
	/**
	 * FNF's standard resolution is 720p.
	 * Resizing the window won't make the game look crispier
	 * unless you create a higher resolution version of your images.
	**/
	static inline var INITIAL_WIDTH = 1280;
	static inline var INITIAL_HEIGHT = 720;
	static var VARIABLE_WIDTH(get, never):Int;
	static var VARIABLE_HEIGHT(get, never):Int;

	inline static function get_VARIABLE_WIDTH() {
		return current.peoteView.width;
	}

	inline static function get_VARIABLE_HEIGHT() {
		return current.peoteView.height;
	}

	// Internal variable for checking if the game has booted up
	private var _started(default, null):Bool;

	override function onWindowCreate()
	{
		switch (window.context.type)
		{
			case WEBGL, OPENGL, OPENGLES:
				startSample(window);
			default: throw("Sorry, only works with OpenGL.");
		}
	}

	// STARTING POINT
	static var current:Main;
	var peoteView:PeoteView;

	// CHART EDITOR UI INTERFACE
	var chartUIOverlay:ChartUIOverlay;

	// DISPLAYS
	var uiOverlayDisplay:CustomDisplay;

	var mouseDown:(Float, Float, MouseButton)->Void;

	public function startSample(window:Window)
	{
		current = this;

		peoteView = new PeoteView(window);

		haxe.Timer.delay(function() {
			createTextures();
			createDisplays();

			peoteView.start();

			ChartUIOverlay.init(uiOverlayDisplay);
			chartUIOverlay = new ChartUIOverlay();

			addDisplays();

			resize(peoteView.width, peoteView.height);

			window.onResize.add(resize);
			window.onKeyDown.add(openChartEditorUI);
			window.onClose.add(Chart.destroy);
			window.onClose.add(ChartUIOverlay.save);

			#if FV_DEBUG
			DeveloperStuff.init(window, this);
			#end

			window.onMouseDown.add((x, y, button) -> {
				if (mouseDown != null) mouseDown(x, y, button);
			});

			_started = true;
		}, 100);
	}

	private function createTextures() {
		var stamp = haxe.Timer.stamp();
		Sys.println("Preloading textures...");
		TextureSystem.createTexture("chartUITex", "assets/images/charteditor/editorUISheet.png", false, true);
		Sys.println('Done! Took ${(haxe.Timer.stamp() - stamp) * 1000}ms');
	}

	private function createDisplays() {
		var stamp = haxe.Timer.stamp();
		Sys.println("Creating displays...");
		uiOverlayDisplay = new CustomDisplay(0, 0, window.width, window.height, /*0x111111FF*/0x00000000);
		Sys.println('Done! Took ${(haxe.Timer.stamp() - stamp) * 1000}ms');
	}

	private function addDisplays() {
		var stamp = haxe.Timer.stamp();
		Sys.println("Adding displays...");

		peoteView.addDisplay(uiOverlayDisplay);
		Sys.println('Done! Took ${(haxe.Timer.stamp() - stamp) * 1000}ms');
	}

	private function openChartEditorUI(keyCode:KeyCode, keyModifier:KeyModifier) {
		switch (keyCode) {
			case KeyCode.RETURN:
				chartUIOverlay.open();
			case KeyCode.ESCAPE:
				chartUIOverlay.close();
			default:
		}
	}

	var newDeltaTime:Float = 0;

	#if hxcpp
	var newTimestamp:Float = 0;
	#end
	override function update(deltaTime:Int) {
		Tools.profileFrame();

		if (_started) {
			#if FV_LIME_FORK
			newDeltaTime = deltaTime * 0.00001;
			#else
			newDeltaTime = 1000 / Application.current.window.frameRate;
			#end

			if (chartUIOverlay != null && chartUIOverlay.active) {
				chartUIOverlay.update(deltaTime);
			}
		}
	}

	override function render(context:RenderContext) {
		super.render(context);

		#if FV_LIME_FORK
		var renderFrameRate = Application.current.window.renderFrameRate;
		var refreshRate:Float = Application.current.window.displayMode.refreshRate;
		if (refreshRate == 0) refreshRate = 60;
		if (renderFrameRate == 0) renderFrameRate = Application.current.window.renderFrameRate = refreshRate;
		var renderRate = newDeltaTime; // Render is set directly after updating so this is the solution
		#else
		var renderFrameRate = Application.current.window.frameRate;
		var renderRate = 1000 / renderFrameRate;
		#end

		if (chartUIOverlay != null && chartUIOverlay.active) {
			chartUIOverlay.render(newDeltaTime);
		}
	}


	function resize(w:Int, h:Int) {
		peoteView.resize(w, h);

		centerDisplayOnWindow(uiOverlayDisplay, w, h);

		if (chartUIOverlay != null) {
			chartUIOverlay.resize(w, h);
		}
	}

	function centerDisplayOnWindow(display:CustomDisplay, w:Int, h:Int) {
		var scale = h / INITIAL_HEIGHT;

		display.width = w;
		display.height = h;
		display.scale = scale;
	}

	// ------------------------------------------------------------
	// ---------------------- GAME ENDS HERE ----------------------
	// ------------------------------------------------------------
}
