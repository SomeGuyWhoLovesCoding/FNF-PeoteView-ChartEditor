package chart;

/**
 * This class handles all of the visual elements and stuff, all combined into one spritesheet which is onlt 144x40.
**/
@:publicFields
class ChartUIOverlay {
	static var uiBuf(default, null):Buffer<ChartUISprite>;
	static var uiProg(default, null):Program;

	static var display(default, null):CustomDisplay;
	static var underlyingData(default, null):ChartUIData;

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

		underlyingData = haxe.Json.parse(sys.io.File.getContent("manifest/tabs.json"));
		trace(underlyingData);
	}

	function convertToSixColors(col:Array<Int>) {
		if (col == null) return [for (i in 0...6) 0];
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

	// WIP!
	// Right now this results in incorrect colors so please be patient while this is fixed!
	function hexesToOpaqueColor(col:Array<String>) {
		if (col == null) return [for (i in 0...6) 0];
		var arr:Array<Int> = [];
		for (i in 0...col.length) {
			var str = col[i];
			//for (i in 0...6) {
				var char = str.charAt(i);
				var hexDigits = Color.getHexDigit(str.charAt(0)) >>
				Color.getHexDigit(str.charAt(1)) >>
				Color.getHexDigit(str.charAt(2)) >>
				Color.getHexDigit(str.charAt(3)) >>
				Color.getHexDigit(str.charAt(4)) >>
				Color.getHexDigit(str.charAt(5));
				if (i > str.length) throw "NOOOOOOOO";
			//}
			var argbColor:Color = Color.WHITE;
			argbColor.setRGB(hexDigits);
			arr.push((argbColor:Int));
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
	static var background2(default, null):ChartUISprite;

	function new() {
		if (background == null) {
			background = new ChartUISprite();
			background.changeID(0);
			background.c = 0xFFFFFFFF;
			if (uiBuf != null)
				uiBuf.addElement(background);
		}

		var colors = [0xFF0000FF,0x0000FFFF]/*[0xFF0000FF]*/; // was a placeholder color array, now is being used for nothing cuz they'll all be rendered out as the current visual representation of tabs.json

		for (i in 0...36) {
			var icon = icons[i] = new ChartUISprite();
			icon.gradientMode = 1;
			var cols = convertToSixColors(colors);
			icon.changeID(i % 2 == 0 ? 1 : 2);
			icon.setAllColors(cols);
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
			/*if (background2 != null) {
				background2.stretch_w(peoteView.width);
				uiBuf.updateElement(background);
			}*/
			if (icons != null) {
				for (i in 0...icons.length) {
					var icon = icons[i];
					var tab = underlyingData.tabs[i];
					if (tab != null) {
						icon.x = background.clipWidth + 4 + (i * (icon.w + 4));
						icon.y = 2;
						icon.changeID(tab.links.length != 1 ? 2 : 1);
						var hexToColor = hexesToOpaqueColor(tab.color);
						var cols = convertToSixColors(hexToColor);
						if (i == 1) trace(cols);
						icon.setAllColors(cols);
					} else {
						icon.x = -99999;
						icon.y = -99999;
					}
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
					icon.y = 2;
					uiBuf.updateElement(icon);
				}
			}
		}
	}

	static function save() {
		var underlyingDataString:String;
		if (underlyingData != null) {
			underlyingDataString = haxe.Json.stringify(underlyingData);
			underlyingData = null;
			sys.io.File.saveContent("manifest/tabs.json", underlyingDataString);
		}
	}
}