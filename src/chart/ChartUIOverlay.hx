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
			var tex = TextureSystem.getTexture("chartUITex");
			ChartUISprite.init(uiProg, "chartUITex", tex);
		}
	}

	function convertToSixColors(col:Array<Int>) {
		var arr:Array<Int> = [for (i in 0...6) 0];
		switch (col.length) {
			case 1:
				for (i in 0...6) arr[i] = col[0];
			case 2:
				for (i in 0...6) arr[i] = col[Std.int(i/3)];
			case 3:
				for (i in 0...6) arr[i] = col[Std.int(i/4)];
			case 4:
				for (i in 0...6) {
					var iCustom = 0;
					switch (i) {
						case 0 | 1:
							iCustom = 0;
						case 2:
							iCustom = 2;
						case 3:
							iCustom = 3;
						case 4 | 5:
							iCustom = 4;
					}
					arr[i] = col[iCustom];
				}
			default:
				arr = col;
		}
		return arr;
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
	static var icons(default, null):Array<ChartUISprite> = [];

	function new() {
		if (background == null) {
			background = new ChartUISprite();
			background.c = 0xFFFFFFFF;
			background.changeID(0);
			if (uiBuf != null)
				uiBuf.addElement(background);
		}

		var colors = [0xFF000000,0x0000FF00]; // placeholder color array

		for (i in 0...36) {
			var icon = icons[i] = new ChartUISprite();
			icon.gradientMode = 1;
			var cols = convertToSixColors(colors);
			icon.setAllColors(cols);
			icon.changeID(1);
			if (uiBuf != null)
				uiBuf.addElement(icon);
		}

		var peoteView = Main.current.peoteView;
		resize(peoteView.width, peoteView.height);
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
			if (icons != null) {
				for (i in 0...icons.length) {
					var icon = icons[i];
					icon.x = background.clipWidth + 4 + (i * (icon.w + 4));
					icon.y = 20;
					uiBuf.updateElement(icon);
				}
			}
		}
	}

	function resize(w:Int, h:Int) {
		if (uiBuf != null) {
			if (background != null) {
				background.stretch_w(w);
				uiBuf.updateElement(background);
			}
			if (icons != null) {
				for (i in 0...icons.length) {
					var icon = icons[i];
					icon.x = background.clipWidth + 4 + (i * (icon.w + 4));
					icon.y = 20;
					uiBuf.updateElement(icon);
				}
			}
		}
	}
}