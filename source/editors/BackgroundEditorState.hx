package editors;

#if desktop
import Discord.DiscordClient;
#end
import haxe.Json;
import haxe.format.JsonParser;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import Character;
import StageData;
import FunkinLua;

#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class BackgroundEditorState extends MusicBeatState
{
    public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	var camFollow:FlxObject;

    override function create() {

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		// Characters
		gf = new Character(400, 130, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		add(gf);

		dad = new Character(100, 100, 'dad');
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];
		add(dad);

		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);


		var stageData:StageFile = StageData.getStageFile(PlayState.curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}
        
    }

	override function update(elapsed:Float)
		{
			// Return back to editor
			if (controls.BACK)
				{
					MusicBeatState.switchState(new editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}

			// Navigate camera position
			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
				{
					var addToCam:Float = 500 * elapsed;
					if (FlxG.keys.pressed.SHIFT)
						addToCam *= 4;
	
					if (FlxG.keys.pressed.I)
						camFollow.y -= addToCam;
					else if (FlxG.keys.pressed.K)
						camFollow.y += addToCam;
	
					if (FlxG.keys.pressed.J)
						camFollow.x -= addToCam;
					else if (FlxG.keys.pressed.L)
						camFollow.x += addToCam;
				}
			
			// Camera Zoom
			if (FlxG.keys.justPressed.R) {
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
			}




			super.update(elapsed);
		}

    function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	/*override public function beatHit()
		{
			super.beatHit();
			dad.dance();
			boyfriend.dance();
		}*/

}