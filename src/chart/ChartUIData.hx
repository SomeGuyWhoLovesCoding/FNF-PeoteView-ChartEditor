package chart;

/**
 * This class handles all of the under-the-hood stuff which modifies the behavior of a `ChartUIOverlay`.
 */
@:publicFields
typedef ChartUIData = {
	var activetabparent:Int;
	var activetabchild:Int;
	var color:String;
	var tabs:Array<ChartTab>;
	@:optional var recentlyclosedtabs:Array<ChartTab>;
	@:optional var autosavedtabs:Array<ChartTab>;
}

@:publicFields
typedef ChartTab = {
	var links:Array<ChartTabLink>;
	var color:Array<String>;
	@:optional var name:String;
}

@:publicFields
typedef ChartTabLink = {
	var path:String;
	var color:Array<String>;
}