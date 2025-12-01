package chart;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;

/**
 * This enum represents the chart UI state.
**/
enum abstract ChartUIMenu(Int) from Int to Int {
	var CURRENT_TABS = 0;
	var RECENTLY_CLOSED_TABS = 1;
	var AUTOSAVED_TABS = 2;
	var MENUS_TOTAL = 3;
}

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
		//trace(underlyingData);
	}

	function open() {
		if (opened) return;
		active = opened = true;

		if (!uiProg.isIn(display)) {
			display.addProgram(uiProg);
		}

		var window = lime.app.Application.current.window;
		window.onKeyDown.add(controlState);
		window.onMouseDown.add(controlState_mouse);
	}

	function close() {
		if (!opened) return;
		active = opened = false;

		if (uiProg.isIn(display)) {
			display.removeProgram(uiProg);
		}

		var window = lime.app.Application.current.window;
		window.onKeyDown.remove(controlState);
		window.onMouseDown.remove(controlState_mouse);
	}

	static var background(default, null):ChartUISprite;
	static var icons(default, null):Array<ChartUISprite> = [];
	static var leftButton(default, null):ChartUISprite;

	// subtab/tab group implementation
	static var tabGrpBackground(default, null):ChartUISprite;
	static var tabGrpIcons(default, null):Array<ChartUISprite> = [];
	var tabGrpY(default, null):Float;

	var currentMenu(default, null):ChartUIMenu = CURRENT_TABS;

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
		var tabs:Array<ChartUIData.ChartTab> = null;

		switch (currentMenu) {
			case ChartUIMenu.CURRENT_TABS:
				tabs = underlyingData.tabs;
			case ChartUIMenu.RECENTLY_CLOSED_TABS:
				tabs = underlyingData.recentlyclosedtabs;
			case ChartUIMenu.AUTOSAVED_TABS:
				tabs = underlyingData.autosavedtabs;
			default:
				tabs = underlyingData.tabs;
		}

		var tabsLen = tabs.length;
		var activetab = underlyingData.activetabparent;
		var tabCur = tabs[activetab];
		var linksInTab = tabCur?.links.length;
		var activetabingrp = underlyingData.activetabchild;
		//if (activetabingrp > linksInTab) activetabingrp = linksInTab;
		var tabsInGrpCur = tabCur?.links[activetabingrp];

		switch (keyCode) {
			case KeyCode.LEFT:
				underlyingData.activetabparent--;
			case KeyCode.RIGHT:
				underlyingData.activetabparent++;
			case KeyCode.DOWN:
				currentMenu--;
				if ((currentMenu:Int) < 0) {
					currentMenu = ChartUIMenu.AUTOSAVED_TABS;
				}
				tabGrpSectionYLerp = tabGrpSectionY = 0;
			case KeyCode.UP:
				currentMenu++;
				if ((currentMenu:Int) >= (ChartUIMenu.MENUS_TOTAL:Int)) {
					currentMenu = ChartUIMenu.CURRENT_TABS;
				}
				tabGrpSectionYLerp = tabGrpSectionY = 0;
			default:
		}

		if (underlyingData.activetabparent < 0) {
			underlyingData.activetabparent = tabsLen - 1;
		}

		if (underlyingData.activetabparent >= tabsLen) {
			underlyingData.activetabparent = 0;
		}

		Sys.println(underlyingData.activetabparent);
	}

	function controlState_mouse(mouseX:Float, mouseY:Float, mouseButton:MouseButton) {
		var tabs:Array<ChartUIData.ChartTab> = null;
		var tabbarcolor:String = "FFFFFF";

		switch (currentMenu) {
			case ChartUIMenu.CURRENT_TABS:
				tabs = underlyingData.tabs;
				tabbarcolor = underlyingData.color;
				tabGrpSectionYLerp = tabGrpSectionY = 0;
			case ChartUIMenu.RECENTLY_CLOSED_TABS:
				tabs = underlyingData.recentlyclosedtabs;
				tabbarcolor = "166E89";
				tabGrpSectionYLerp = tabGrpSectionY = 0;
			case ChartUIMenu.AUTOSAVED_TABS:
				tabs = underlyingData.autosavedtabs;
				tabbarcolor = "CCC816"; // was going to be 898716
				tabGrpSectionYLerp = tabGrpSectionY = 0;
			default:
				tabs = underlyingData.tabs;
				tabbarcolor = underlyingData.color;
		}
		
		var tabsLen = tabs.length;
		var activetab = underlyingData.activetabparent;
		var tabCur = tabs[activetab];
		var linksInTab = tabCur?.links.length;
		var activetabingrp = underlyingData.activetabchild;
		//if (activetabingrp > linksInTab) activetabingrp = linksInTab;
		var tabsInGrpCur = tabCur?.links[activetabingrp];
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
	function updateMainParts(deltaTime:Float, closeTabGrpBar:Bool = false) {
		var tabs:Array<ChartUIData.ChartTab> = null;
		var tabbarcolor:String = "FFFFFF";

		var ratio = Math.min(deltaTime * 0.015, 1.0);
		if (ratio == 1) ratio = (1/lime.app.Application.current.window.frameRate) * 0.015;

		switch (currentMenu) {
			case ChartUIMenu.CURRENT_TABS:
				tabs = underlyingData.tabs;
				tabbarcolor = underlyingData.color;
			case ChartUIMenu.RECENTLY_CLOSED_TABS:
				if (underlyingData.recentlyclosedtabs == null) underlyingData.recentlyclosedtabs = [];
				tabs = underlyingData.recentlyclosedtabs;
				tabbarcolor = "166E89";
			case ChartUIMenu.AUTOSAVED_TABS:
				if (underlyingData.autosavedtabs == null) underlyingData.autosavedtabs = [];
				tabs = underlyingData.autosavedtabs;
				tabbarcolor = "CCC816";
			default:
				tabs = underlyingData.tabs;
				tabbarcolor = underlyingData.color;
		}

		tabGrpSectionYLerp = Tools.lerp(tabGrpSectionYLerp, tabGrpSectionY, ratio);

		var peoteView = Main.current.peoteView;
		var tab = tabs[underlyingData.activetabparent];
		var isTabGrp = tab?.links.length >= 2;
		var tabGrp = tab?.links[underlyingData.activetabchild];
		if (background != null) {
			background.stretch_w(peoteView.width);
			background.c = Tools.hexesToOpaqueColor([tabbarcolor])[0];
			uiBuf.updateElement(background);
			if (leftButton != null) {
				leftButton.x = leftButton.y = 2;
				leftButton.c = background.c;
				uiBuf.updateElement(leftButton);
			}
			if (tabGrpBackground != null) {
				tabGrpBackground.stretch_w(peoteView.width);
				tabGrpSectionY = !isTabGrp ? 0 : tabGrpY;
				tabGrpBackground.y = tabGrpSectionYLerp;
				tabGrpBackground.c = Tools.hexesToOpaqueColor(tabGrp?.color)[0];
				background.c = Tools.hexesToOpaqueColor([tabbarcolor])[0];
				uiBuf.updateElement(tabGrpBackground);
			}
			if (icons != null) {
				for (i in 0...icons.length) {
					var icon = icons[i];
					var tab = tabs[i];
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
				}
			}
			if (tabGrpBackground != null && tabGrpIcons != null) {
				for (i in 0...tabGrpIcons.length) {
					var icon = tabGrpIcons[i];
					var tabLink = tab?.links[i];
					if (tabLink != null && isTabGrp) {
						icon.x = (leftButton.x + 4) + (i * (icon.w + 4));
						icon.y = tabGrpBackground.y + 2;
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