// This is yet another copy of UISprite, but with a different name and different properties, SPECIFICALLY for the chart UI tabbar.

package chart;

@:publicFields
class ChartUISprite implements Element {
	// position in pixel (relative to upper left corner of Display)
	@posX @formula("(_flip != 0.0 ? x - w : x)") var x:Float = 0.0;
	@posY var y:Float = 0.0;

	// size in pixel
	@sizeX @formula("(_flip != 0.0 ? -w : w)") var w:Float = 0.0;
	@sizeY var h:Float = 0.0;

	@tile var tileId:Int = 0;

	@color var c:Color = 0xFFFFFFFF;
	@color var c1:Color = 0xFFFFFFFF;
	@color var c2:Color = 0xFFFFFFFF;
	@color var c3:Color = 0xFFFFFFFF;
	@color var c4:Color = 0xFFFFFFFF;
	@color var c5:Color = 0xFFFFFFFF;
	@color var c6:Color = 0xFFFFFFFF;

	@color private var alphaColor:Color = 0xFFFFFFFF;

	var alpha(get, set):Float;

	inline function get_alpha() {
		return alphaColor.aF;
	}

	inline function set_alpha(value:Float) {
		value = Math.max(value, 0);
		alphaColor.luminanceF = value;
		return alphaColor.aF = value;
	}

	function setAllColors(colors:Array<Color>) {
		c1 = colors[0];
		c2 = colors[1];
		c3 = colors[2];
		c4 = colors[3];
		c5 = colors[4];
		c6 = colors[5];
	}

	@varying @custom private var _flip:Float = 0.0;
	@varying @custom var gradientMode:Float = 0.0;

	var flip(get, set):Bool;

	inline function get_flip() {
		return _flip != 0.0;
	}

	inline function set_flip(value:Bool) {
		_flip = value ? 1.0 : 0.0;
		return value;
	}

	var curID(default, null):Int;

	var OPTIONS = { texRepeatX: true, texRepeatY: false, blend: true };

	static var uniformRepeat:UniformFloat;

	static function init(program:Program, name:String, texture:Texture) {
		// creates a texture-layer named "name"
		texture.tilesX = 4;
		program.setTexture(texture, name, true);
		program.blendEnabled = true;
		program.blendSrc = program.blendSrcAlpha = BlendFactor.ONE;
		program.blendDst = program.blendDstAlpha = BlendFactor.ONE_MINUS_SRC_ALPHA;

		uniformRepeat = new UniformFloat("repeatHoriz", 1);

		program.injectIntoFragmentShader('
			vec4 gradientOf6(int textureID, float gradientMode, vec4 c, vec4 c1, vec4 c2, vec4 c3, vec4 c4, vec4 c5, vec4 c6) {
				vec2 coord = vTexCoord;
				coord.x *= repeatHoriz;

				if (gradientMode == 0.0) {
					return getTextureColor(textureID, coord);
				}

				float y = clamp(vTexCoord.y, 0.0, 1.0);

				// Scale to [0..5]
				float fy = y * 5.0;
				int segment = int(floor(fy));       // 0..4
				float t = fract(fy);                // fractional part

				vec4 colors[6];
				colors[0] = c1;
				colors[1] = c2;
				colors[2] = c3;
				colors[3] = c4;
				colors[4] = c5;
				colors[5] = c6;

				// Lerp between current and next color
				return getTextureColor(textureID, coord) * mix(colors[segment], colors[segment + 1], t);
			}
		', [uniformRepeat]);

		program.setColorFormula('gradientOf6(${name}_ID, gradientMode, c, c1, c2, c3, c4, c5, c6) * (c * alphaColor)');
	}

	function new() {
		w = 36;
		h = 40;
	}

    inline function changeID(id:Int) {
		tileId = id;

		curID = id;
    }

	function stretch_w(wValue:Float) {
		//w = wValue;
		/*clipWidth = 36;
		clipSizeX = 1 / (wValue / 36);*/
		w = wValue;
		//uniformRepeat.value = w / clipWidth;
		//trace(uniformRepeat.value);
		//trace(wValue, clipSizeX);
	}
}