package chart;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

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
			uiBuf = new Buffer<ChartUISprite>(75);
			uiProg = new Program(uiBuf);
			var tex = TextureSystem.getTexture("chartUITex");
			ChartUISprite.init(uiProg, "chartUITex", tex);
		}

		underlyingData = haxe.Json.parse(sys.io.File.getContent("manifest/tabs.json"));
		trace(underlyingData);
	}

	inline function open() {
		active = opened = true;

		if (!uiProg.isIn(display)) {
			display.addProgram(uiProg);
		}

		var window = lime.app.Application.current.window;
		window.onKeyDown.add(controlState);
	}

	inline function close() {
		active = opened = false;

		if (uiProg.isIn(display)) {
			display.removeProgram(uiProg);
		}

		var window = lime.app.Application.current.window;
		window.onKeyDown.remove(controlState);
	}

	static var background(default, null):ChartUISprite;
	static var icons(default, null):Array<ChartUISprite> = [];
	static var leftButton(default, null):ChartUISprite;

	// subtab/tab group implementation
	static var tabGrpBackground(default, null):ChartUISprite;
	static var tabGrpIcons(default, null):Array<ChartUISprite> = [];
	var tabGrpY(default, null):Float;

	function new() {
		var colors = [0xFF0000FF,0x0000FFFF]/*[0xFF0000FF]*/; // was a placeholder color array, now is being used for nothing cuz they'll all be rendered out as the current visual representation of tabs.json

		if (background == null) {
			background = new ChartUISprite();
			background.changeID(0);
			background.c = 0xFFFFFFFF;
		}

		// This goes first due to ordering
		tabGrpY = background?.clipHeight;
		if (tabGrpBackground == null) {
			tabGrpBackground = new ChartUISprite();
			tabGrpBackground.changeID(0);
			tabGrpBackground.c = 0xFFFFFFFF;
			tabGrpBackground.y = tabGrpY;
			if (uiBuf != null)
				uiBuf.addElement(tabGrpBackground);
		}

		for (i in 0...36) {
			var icon = tabGrpIcons[i] = new ChartUISprite();
			icon.y = tabGrpY;
			icon.gradientMode = 1;
			var cols = Tools.convertToSixColors(colors);
			icon.changeID(i % 2 == 0 ? 1 : 2);
			icon.setAllColors(cols);
			if (uiBuf != null)
				uiBuf.addElement(icon);
		}

		if (background != null) {
			if (uiBuf != null)
				uiBuf.addElement(background);
		}

		for (i in 0...36) {
			var icon = icons[i] = new ChartUISprite();
			icon.gradientMode = 1;
			var cols = Tools.convertToSixColors(colors);
			icon.changeID(i % 2 == 0 ? 1 : 2);
			icon.setAllColors(cols);
			if (uiBuf != null)
				uiBuf.addElement(icon);
		}

		if (leftButton == null) {
			leftButton = new ChartUISprite();
			leftButton.changeID(3);
			leftButton.c = 0xFFFFFFFF;
			if (uiBuf != null)
				uiBuf.addElement(leftButton);
		}

		var peoteView = Main.current.peoteView;
		resize(peoteView.width, peoteView.height);
	}

	// This is where everything is controlled at.
	function controlState(keyCode:KeyCode, keyMod:KeyModifier) {
		var tabs = underlyingData.tabs.length;
		var activetab = underlyingData.activetabparent;
		var tabCur = underlyingData.tabs[activetab];
		var linksInTab = tabCur?.links.length;
		var activetabingrp = underlyingData.activetabchild;
		//if (activetabingrp > linksInTab) activetabingrp = linksInTab;
		var tabsInGrpCur = tabCur?.links[activetabingrp];

		switch (keyCode) {
			case KeyCode.LEFT:
				underlyingData.activetabparent--;
			case KeyCode.RIGHT:
				underlyingData.activetabparent++;
			default:
		}

		if (underlyingData.activetabparent < 0) {
			underlyingData.activetabparent = tabs - 1;
		}

		if (underlyingData.activetabparent >= tabs) {
			underlyingData.activetabparent = 0;
		}

		Sys.println(underlyingData.activetabparent);
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
		if (uiBuf != null) {
			updateMainParts(deltaTime);
		}
	}

	var tabGrpSectionY(default, null):Float;
	var tabGrpSectionYLerp(default, null):Float;
	function updateMainParts(deltaTime:Float) {
		var ratio = Math.min(deltaTime * 0.015, 1.0);
		if (ratio == 1) ratio = (1/lime.app.Application.current.window.frameRate) * 0.015;

		tabGrpSectionYLerp = Tools.lerp(tabGrpSectionYLerp, tabGrpSectionY, ratio);

		var peoteView = Main.current.peoteView;
		var tab = underlyingData.tabs[underlyingData.activetabparent];
		var isTabGrp = tab?.links.length != 1;
		Sys.println(isTabGrp);
		if (background != null) {
			background.stretch_w(peoteView.width);
			uiBuf.updateElement(background);
			if (leftButton != null) {
				leftButton.x = leftButton.y = 2;
				uiBuf.updateElement(leftButton);
			}
			if (tabGrpBackground != null) {
				tabGrpBackground.stretch_w(peoteView.width);
				tabGrpSectionY = !isTabGrp ? 0 : tabGrpY;
				tabGrpBackground.y = tabGrpSectionYLerp;
				uiBuf.updateElement(tabGrpBackground);
			}
			if (icons != null) {
				for (i in 0...icons.length) {
					var icon = icons[i];
					var tab = underlyingData.tabs[i];
					var isTabAGrp = tab?.links.length != 1;
					if (tab != null) {
						icon.x = (leftButton.clipWidth + leftButton.x + 8) + (i * (icon.w + 4));
						icon.y = 2;
						icon.changeID(isTabAGrp ? 2 : 1);
						var hexToColor = Tools.hexesToOpaqueColor(tab.color);
						var cols = Tools.convertToSixColors(hexToColor);
						icon.setAllColors(cols);
					} else {
						icon.x = -99999;
						icon.y = -99999;
					}
					uiBuf.updateElement(icon);
					if (tabGrpBackground != null && tabGrpIcons != null) {
						for (i in 0...tabGrpIcons.length) {
							var icon = tabGrpIcons[i];
							if (tab != null) {
								var tabLink = tab.links[i];
								if (tabLink != null && isTabGrp) {
									icon.x = (leftButton.clipWidth + leftButton.x + 8) + (i * (icon.w + 4));
									icon.y = tabGrpBackground.y;
									icon.changeID(1); // tabLink.path
									var hexToColor = Tools.hexesToOpaqueColor(tabLink.color);
									var cols = Tools.convertToSixColors(hexToColor);
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
			}
		}
	}

	function resize(w:Int, h:Int) {
		updateMainParts(0);
	}

	static function save() {
		var underlyingDataString:String;
		if (underlyingData != null) {
			underlyingDataString = haxe.Json.stringify(underlyingData, null, "\t");
			underlyingData = null;
			sys.io.File.saveContent("manifest/tabs.json", underlyingDataString);
		}
	}
}