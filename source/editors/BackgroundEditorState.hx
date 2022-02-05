package editors;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
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
import flixel.util.FlxColor;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.text.FlxText;
import Character;
import StageData;
import FunkinLua;

#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class BackgroundEditorState extends MusicBeatState
{

	public var stageData:StageFile;

	public var curStage:String = 'stage';
	var _file:FileReference;

    public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	var gfCharacter:String = 'gf';
	var dadCharacter:String = 'dad';
	var bfCharacter:String = 'bf';

	public var defaultCamZoom:Float = 1.05;

	var camFollow:FlxObject;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	private var camMenu:FlxCamera;

    override function create() {
		FlxG.sound.playMusic(Paths.music('lilBitBack'));
		Conductor.changeBPM(125);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camMenu);

		FlxCamera.defaultCameras = [camGame];

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		//Character Pos
		//var stageData:StageFile = StageData.getStageFile(curStage);
		//if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				layers: [
					{
						image: "stageback",
						flipX: false,
						scale: 1,
						scrollfactor: [0.9, 0.9],
						offset: [-600, -200],
					},
					{
						image: "stagefront",
						flipX: false,
						scale: 1.1,
						scrollfactor: [0.9, 0.9],
						offset: [-650, 600],
					},
					{
						image: "stage_light",
						flipX: false,
						scale: 1.1,
						scrollfactor: [0.9, 0.9],
						offset: [-125, -100],
					},
					{
						image: "stage_light",
						flipX: true,
						scale: 1.1,
						scrollfactor: [0.9, 0.9],
						offset: [1225, -100],
					},
					{
						image: "stagecurtains",
						flipX: false,
						scale: 0.9,
						scrollfactor: [1.3, 1.3],
						offset: [-500, -300],
					}
				],
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		//}

		var layerArray = stageData.layers;
		for (stuff in layerArray)
			{
				var layer:BGSprite = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
				layer.setGraphicSize(Std.int(layer.width * stuff.scale));
				layer.updateHitbox();
				layer.flipX = stuff.flipX;
				add(layer);
			}

		defaultCamZoom = stageData.defaultZoom;
		//isPixelStage = stageData.isPixelStage; Do this shit later
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		// Characters
		gf = new Character(GF_X, GF_Y, gfCharacter);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		add(gf);

		dad = new Character(DAD_X, DAD_Y, dadCharacter);
		startCharacterPos(dad, true);
		add(dad);
		
		boyfriend = new Boyfriend(BF_X, BF_Y, bfCharacter);
		startCharacterPos(boyfriend);
		add(boyfriend);
        
		// Pro Tips
		var tipText:FlxText = new FlxText(FlxG.width - 20, FlxG.height, 0,
			"E/Q - Camera Zoom In/Out
			\nJKLI - Move Camera
			\nR - Reset Camera Zoom
			\nHold Shift to Move 10x faster\n", 12);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.x -= tipText.width;
		tipText.y -= tipText.height - 10;
		add(tipText);

		FlxG.camera.follow(camFollow);
    }

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.SPACE)
		{
			boyfriend.playAnim('hey', true);
			gf.playAnim('cheer', true);
		}

		if (boyfriend.animation.curAnim.finished)
		{
			boyfriend.dance();
		}
		if (gf.animation.curAnim.finished)
		{
			gf.dance();
		}
		if (dad.animation.curAnim.finished)
		{
			dad.dance();
		}

		// Return back to editor
		if (controls.BACK)
			{
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.music.stop();
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

		if (FlxG.keys.justPressed.P)
			{
				trace(stageData);
				saveBackground();
			}

		super.update(elapsed);
	}

	/*override function beatHit()
	{
		super.beatHit();

		if(curBeat % 2 == 0) {
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
			}
		}
		if (curBeat % 1 == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}
	}*/

    function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function onSaveComplete(_):Void
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			FlxG.log.notice("Successfully saved LEVEL DATA.");
		}
	
		/**
		 * Called when the save file dialog is cancelled.
		 */
		function onSaveCancel(_):Void
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
		}
	
		/**
		 * Called if there is an error while saving the gameplay recording.
		 */
		function onSaveError(_):Void
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			FlxG.log.error("Problem saving Level data");
		}

		function saveBackground() {
			var json = {
				"directory": stageData.directory,
				"defaultZoom": stageData.defaultZoom,
				"isPixelStage": stageData.isPixelStage,
	
				"layers": stageData.layers,
	
				"boyfriend": stageData.boyfriend,
				"girlfriend": stageData.girlfriend,
				"opponent": stageData.opponent
			};
	
			var data:String = Json.stringify(json, "\t");
	
			if (data.length > 0)
			{
				_file = new FileReference();
				_file.addEventListener(Event.COMPLETE, onSaveComplete);
				_file.addEventListener(Event.CANCEL, onSaveCancel);
				_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
				_file.save(data, curStage + ".json");
			}
		}
}