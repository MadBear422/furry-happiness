package editors;

#if desktop
import Discord.DiscordClient;
#end
import haxe.Json;
import haxe.format.JsonParser;
import flixel.ui.FlxSpriteButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class BackgroundEditorState extends MusicBeatState
{
    public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

    override function create() {
        
    }
    function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}
}