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
	// The usual alpha for a simple visual indicator
	inline static var VISUAL_INDICATOR_ALPHA:Float = 0.3;
	inline static var VISUAL_INDICATOR_COLOR:Color = Color.BLACK;
	inline static var NUM_ICON_ELEMENTS:Int = 32;

	static var uiBuf(default, null):Buffer<ChartUISprite>;
	static var uiProg(default, null):Program;

	static var display(default, null):CustomDisplay;
	static var underlyingData(default, null):ChartUIData;

	static var text(default, null):Text;

	var active:Bool = false;

	var opened(default, null):Bool;

	static function init(disp:CustomDisplay) {
		display = disp;

		if (uiBuf == null) {
			uiBuf = new Buffer<ChartUISprite>(128);
			uiProg = new Program(uiBuf);
			var tex = TextureSystem.getTexture("chartUITex");
			ChartUISprite.init(uiProg, "chartUITex", tex);
		}

		if (text == null) {
			text = new Text("wow", 200, 200, display, "Hi", "arial");
			text.alpha = 0;
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

		if (text != null)
			text.alpha = 1;
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

		if (text != null)
			text.alpha = 0;
	}

	static var background(default, null):ChartUISprite;
	static var icons(default, null):Array<ChartUISprite> = [];
	static var leftButton(default, null):ChartUISprite;
	static var icon_visualIndicator(default, null):ChartUISprite;

	// subtab/tab group implementation
	static var tabGrpBackground(default, null):ChartUISprite;
	static var tabGrpIcons(default, null):Array<ChartUISprite> = [];
	static var tabGrpIcon_visualIndicator(default, null):ChartUISprite;
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

		for (i in 0...NUM_ICON_ELEMENTS) {
			var icon = tabGrpIcons[i] = new ChartUISprite();
			icon.y = tabGrpY;
			icon.gradientMode = 1;
			var cols = Tools.convertToSixColors(colors);
			icon.changeID(i % 2 == 0 ? 1 : 2);
			icon.setAllColors(cols);
			icon._mouse_click_chart_id = i;
			icon.mouseCallback = function(spr:ChartUISprite, mouseX:Float, mouseY:Float, id:Int) {
				trace("test_tab_group",id);
			};
			if (uiBuf != null)
				uiBuf.addElement(icon);
		}

		if (background != null) {
			if (uiBuf != null)
				uiBuf.addElement(background);
		}

		for (i in 0...NUM_ICON_ELEMENTS) {
			var icon = icons[i] = new ChartUISprite();
			icon.gradientMode = 1;
			var cols = Tools.convertToSixColors(colors);
			icon.changeID(i % 2 == 0 ? 1 : 2);
			icon.setAllColors(cols);
			icon._mouse_click_chart_id = i;
			icon.mouseCallback = function(spr:ChartUISprite, mouseX:Float, mouseY:Float, id:Int) {
				trace("test",id);
			};
			if (uiBuf != null)
				uiBuf.addElement(icon);
		}

		if (leftButton == null) {
			leftButton = new ChartUISprite();
			leftButton.changeID(3);
			leftButton.c = 0xFFFFFFFF;
			leftButton.mouseCallback = function(spr:ChartUISprite, mouseX:Float, mouseY:Float, id:Int) {
				currentMenu++;
				if ((currentMenu:Int) >= (ChartUIMenu.MENUS_TOTAL:Int)) {
					currentMenu = ChartUIMenu.CURRENT_TABS;
				}
				tabGrpAppearLerp = tapGrpAppear = 0;
				underlyingData.activetabchild = 0;
			}
			if (uiBuf != null)
				uiBuf.addElement(leftButton);
		}

		if (icon_visualIndicator == null) {
			icon_visualIndicator = new ChartUISprite();
			icon_visualIndicator.changeID(1);
			icon_visualIndicator.c = VISUAL_INDICATOR_COLOR;
			icon_visualIndicator.alpha = VISUAL_INDICATOR_ALPHA;
			if (uiBuf != null)
				uiBuf.addElement(icon_visualIndicator);
		}

		if (tabGrpIcon_visualIndicator == null) {
			tabGrpIcon_visualIndicator = new ChartUISprite();
			tabGrpIcon_visualIndicator.changeID(1);
			tabGrpIcon_visualIndicator.c = VISUAL_INDICATOR_COLOR;
			tabGrpIcon_visualIndicator.alpha = VISUAL_INDICATOR_ALPHA;
			if (uiBuf != null)
				uiBuf.addElement(tabGrpIcon_visualIndicator);
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
				switch (keyMod) {
					case KeyModifier.LEFT_CTRL | KeyModifier.RIGHT_CTRL:
						underlyingData.activetabparent--;
						if (underlyingData.activetabparent < 0) {
							underlyingData.activetabparent = tabsLen - 1;
						}
						if (underlyingData.activetabchild < 0) {
							underlyingData.activetabchild = linksInTab - 1;
						}
						if (underlyingData.activetabchild >= linksInTab) {
							underlyingData.activetabchild = 0;
						}
					case KeyModifier.LEFT_SHIFT | KeyModifier.RIGHT_SHIFT:
						underlyingData.activetabchild--;
						if (underlyingData.activetabchild < 0) {
							underlyingData.activetabchild = linksInTab - 1;
						}
					case KeyModifier.LEFT_ALT | KeyModifier.RIGHT_ALT:
						tabGrp_scrollX--;
						if (tabGrp_scrollX < 0) tabGrp_scrollX = 0;
					default:
						scrollX--;
						if (scrollX < 0) scrollX = 0;
				}
			case KeyCode.RIGHT:
				switch (keyMod) {
					case KeyModifier.LEFT_CTRL | KeyModifier.RIGHT_CTRL:
						underlyingData.activetabparent++;
						if (underlyingData.activetabparent >= tabsLen) {
							underlyingData.activetabparent = 0;
						}
						if (underlyingData.activetabchild < 0) {
							underlyingData.activetabchild = linksInTab - 1;
						}
						if (underlyingData.activetabchild >= linksInTab) {
							underlyingData.activetabchild = 0;
						}
					case KeyModifier.LEFT_SHIFT | KeyModifier.RIGHT_SHIFT:
						underlyingData.activetabchild++;
						if (underlyingData.activetabchild >= linksInTab) {
							underlyingData.activetabchild = 0;
						}
					case KeyModifier.LEFT_ALT | KeyModifier.RIGHT_ALT:
						tabGrp_scrollX++;
						var iconsLen = linksInTab - tabGrpIcons?.length + 1;
						if (iconsLen < 0) iconsLen = 0;
						if (tabGrp_scrollX >= iconsLen) tabGrp_scrollX = iconsLen;
					default:
						scrollX++;
						var iconsLen = tabsLen - icons?.length + 1;
						if (iconsLen < 0) iconsLen = 0;
						if (scrollX >= iconsLen) scrollX = iconsLen;
				}
			case KeyCode.DOWN:
				currentMenu--;
				if ((currentMenu:Int) < 0) {
					currentMenu = ChartUIMenu.AUTOSAVED_TABS;
				}
				tabGrpAppearLerp = tapGrpAppear = 0;
				underlyingData.activetabchild = 0;
			case KeyCode.UP:
				currentMenu++;
				if ((currentMenu:Int) >= (ChartUIMenu.MENUS_TOTAL:Int)) {
					currentMenu = ChartUIMenu.CURRENT_TABS;
				}
				tabGrpAppearLerp = tapGrpAppear = 0;
				underlyingData.activetabchild = 0;
			default:
		}

		//Sys.println(underlyingData.activetabparent);
		//Sys.println('${underlyingData.activetabchild},$scrollX');
	}

	function controlState_mouse(mouseX:Float, mouseY:Float, mouseButton:MouseButton) {
		var tabs:Array<ChartUIData.ChartTab> = null;
		var tabbarcolor:String = "FFFFFF";

		switch (currentMenu) {
			case ChartUIMenu.CURRENT_TABS:
				tabs = underlyingData.tabs;
				tabbarcolor = underlyingData.color;
			case ChartUIMenu.RECENTLY_CLOSED_TABS:
				tabs = underlyingData.recentlyclosedtabs;
				tabbarcolor = "166E89";
			case ChartUIMenu.AUTOSAVED_TABS:
				tabs = underlyingData.autosavedtabs;
				tabbarcolor = "CCC816"; // was going to be 898716
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

		if (leftButton != null) {
			leftButton.execute_mouse_callback(mouseX, mouseY);
		}

		if (icons != null) {
			for (i in 0...icons.length) {
				var icon = icons[i];
				icon.execute_mouse_callback(mouseX, mouseY);
			}
		}

		for (i in 0...tabGrpIcons.length) {
			var icon = tabGrpIcons[i];
			icon.execute_mouse_callback(mouseX, mouseY);
		}
	}

	var scrollX(default, null):Float;
	var scrollXLerp(default, null):Float;

	var tabGrp_scrollX(default, null):Float;
	var tabGrp_scrollXLerp(default, null):Float;

	function update(deltaTime:Float) {
		if (!opened) return;
		var ratio = Math.min(deltaTime * 0.015, 1.0);
		if (ratio == 1) ratio = (1/lime.app.Application.current.window.frameRate) * 0.015;

		scrollXLerp = Tools.lerp(scrollXLerp, scrollX, ratio);
		tabGrp_scrollXLerp = Tools.lerp(tabGrp_scrollXLerp, tabGrp_scrollX, ratio);
	}

	function render(deltaTime:Float) {
		if (!opened) return;
		if (uiBuf != null) {
			updateMainParts(deltaTime);
		}
	}

	function icon_X_formula(i:Float, lerpVal:Float, xOffset:Float) {
		//Sys.println('$xOffset + ($i * 40) - Std.int($lerpVal * 40.0) % 40)');
		return (xOffset + (i * 40)) - (Std.int(lerpVal * 40.0) % 40);
	}

	var tapGrpAppear(default, null):Float;
	var tabGrpAppearLerp(default, null):Float;
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

		tabGrpAppearLerp = Tools.lerp(tabGrpAppearLerp, tapGrpAppear, ratio);

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
				tapGrpAppear = !isTabGrp ? 0 : tabGrpY;
				tabGrpBackground.y = tabGrpAppearLerp;
				tabGrpBackground.c = Tools.hexesToOpaqueColor(tab?.color)[0];
				uiBuf.updateElement(tabGrpBackground);
			}
			if (icons != null) {
				for (i in 0...icons.length) {
					var icon = icons[i];
					var tab = tabs[i + Std.int(scrollXLerp)];
					var isTabAGrp = tab?.links.length != 1;
					if (tab != null) {
						icon.x = icon_X_formula(i, scrollXLerp, (leftButton.clipWidth + leftButton.x + 8));
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
				if (icon_visualIndicator != null) {
					icon_visualIndicator.x = icon_X_formula(underlyingData.activetabparent - scrollXLerp, 0, (leftButton.clipWidth + leftButton.x + 8));
					//Sys.println('$scrollX,${icon_visualIndicator.x}');
					icon_visualIndicator.y = 3;
					icon_visualIndicator.alpha = currentMenu != ChartUIMenu.CURRENT_TABS ? 0.0 : VISUAL_INDICATOR_ALPHA;
					uiBuf.updateElement(icon_visualIndicator);
				}
			}
			if (tabGrpBackground != null && tabGrpIcons != null) {
				for (i in 0...tabGrpIcons.length) {
					var icon = tabGrpIcons[i];
					var tabLink = tab?.links[i];
					if (tabLink != null && isTabGrp) {
						icon.x = icon_X_formula(i, tabGrp_scrollXLerp, (leftButton.x + 4));
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
				if (tabGrpIcon_visualIndicator != null) {
					tabGrpIcon_visualIndicator.x = icon_X_formula(underlyingData.activetabchild - tabGrp_scrollXLerp, 0, (leftButton.x + 4));
					tabGrpIcon_visualIndicator.alpha = currentMenu != ChartUIMenu.CURRENT_TABS ? 0.0 : (tabGrpAppearLerp / 40.0) * VISUAL_INDICATOR_ALPHA;
					//Sys.println('$scrollX,${tabGrpIcon_visualIndicator.x}');
					tabGrpIcon_visualIndicator.y = tabGrpBackground.y + 3;
					uiBuf.updateElement(tabGrpIcon_visualIndicator);
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