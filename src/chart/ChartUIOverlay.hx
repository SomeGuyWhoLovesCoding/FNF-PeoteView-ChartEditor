package chart;

@:publicFields
class ChartUIOverlay {
	static var uiBuf(default, null):Buffer<ChartUISprite>;
	static var uiProg(default, null):Program;

	static var display(default, null):CustomDisplay;

	var active:Bool = false;

	var opened(default, null):Bool;

	static function init(disp:CustomDisplay) {
		display = disp;

		if (uiBuf == null) {
			uiBuf = new Buffer<ChartUISprite>(64);
			uiProg = new Program(uiBuf);
			uiProg.blendEnabled = true;
			uiProg.blendSrc = uiProg.blendSrcAlpha = BlendFactor.ONE;
			uiProg.blendDst = uiProg.blendDstAlpha = BlendFactor.ONE_MINUS_SRC_ALPHA;

			var tex = TextureSystem.getTexture("chartUITex");
			ChartUISprite.init(uiProg, "chartUITex", tex);
		}
	}

	inline function open() {
		active = opened = true;

		if (!uiProg.isIn(display)) {
			display.addProgram(uiProg);
		}
	}

	inline function close() {
		active = opened = false;

		if (uiProg.isIn(display)) {
			display.removeProgram(uiProg);
		}
	}

	static var background(default, null):ChartUISprite;
	//var 

	function new() {
		if (background == null) {
			background = new ChartUISprite();
			background.c = 0xFFFFFFFF;
			background.changeID(0);
			if (uiBuf != null)
				uiBuf.addElement(background);

			var peoteView = Main.current.peoteView;
			resize(peoteView.width, peoteView.height);
		}
	}

	var scrollX(default, null):Float;
	var scrollXLerp(default, null):Float;
	function update(deltaTime:Float) {
		if (!opened) return;
		var ratio = Math.min(deltaTime * 0.015, 1.0);
		if (ratio == 1) ratio = (1/lime.app.Application.current.window.frameRate) * 0.015;

		scrollXLerp = Tools.lerp(scrollXLerp, scrollX, ratio);
		//Sys.println(scrollXLerp);
	}

	function render(deltaTime:Float) {
		if (!opened) return;
		var peoteView = Main.current.peoteView;
		if (uiBuf != null) {
			if (background != null) {
				background.stretch_w(peoteView.width);
				uiBuf.updateElement(background);
			}
		}
	}

	function resize(w:Int, h:Int) {
		if (uiBuf != null) {
			if (background != null) {
				background.stretch_w(w);
				uiBuf.updateElement(background);
			}
		}
	}
}