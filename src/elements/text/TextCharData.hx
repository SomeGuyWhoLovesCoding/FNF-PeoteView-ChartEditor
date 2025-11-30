package elements.text;

/**
	The text character data.
**/
typedef TextCharData = {
	position:{
		x:Int,
		y:Int
	},
	sourceSize:{
		width:Int,
		height:Int
	},
	padding:Int,
	char:{
		advanceX:Int,
		offset:{x:Int, y:Int}
	}
}