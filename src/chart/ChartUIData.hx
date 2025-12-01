package chart;

/**
 * This class handles all of the under-the-hood stuff which modifies the behavior of a `ChartUIOverlay`.
 */
@:publicFields
//@:structInit
typedef ChartUIData = {
	var activetabparent:Int;
	var activetabchild:Int;
	var color:String;
	var tabs:Array<ChartTab>;
}

@:publicFields
//@:structInit
typedef ChartTab = {
	var links:Array<ChartTabLink>;
	var color:Array<String>;
	@:optional var name:String;
}

@:publicFields
//@:structInit
typedef ChartTabLink = {
	var path:String;
	var color:Array<String>;
}