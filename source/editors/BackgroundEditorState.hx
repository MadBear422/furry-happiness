package editors;

import flixel.group.FlxGroup.FlxTypedGroup;
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
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import Character;
import StageData;
import FunkinLua;
import flixel.math.FlxPoint;

#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class BackgroundEditorState extends MusicBeatState
{
	public var curStage:String = 'stage';
	public var stageData:StageFile;
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

	var bgLayer:FlxTypedGroup<BGSprite>;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	private var camMenu:FlxCamera;

	var dadPosText:FlxText;
	var bfPosText:FlxText;

	var newImage:String = "";

    override function create() {

		bgLayer = new FlxTypedGroup<BGSprite>();
		add(bgLayer);

		FlxG.sound.playMusic(Paths.music('lilBitBack'));
		Conductor.changeBPM(125);

		FlxG.mouse.visible = true;
		FlxG.mouse.enabled = true;

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

		var saveBGButton:FlxButton = new FlxButton(1100, 400, "Save BG", function() {
			trace(stageData);
			saveBackground();
		});
		saveBGButton.cameras = [camHUD];
		add(saveBGButton);

		var imageInputText:FlxUIInputText = new FlxUIInputText(saveBGButton.x - 150, saveBGButton.y + 75, 200, 'stagefront', 8);
		var addImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Add Image", function()
		{
			addImage(imageInputText.text);
			reloadStageData();
		});
		imageInputText.cameras = [camHUD];
		addImage.cameras = [camHUD];
		imageInputText.updateHitbox();
		addImage.updateHitbox();
		add(imageInputText);
		add(addImage);

		//Character Pos
		stageData = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
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
		}
		
		var layerArray = stageData.layers;
		for (stuff in layerArray)
			{
				var real:Int = 0;
				var layer:BGSprite = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
				layer.setGraphicSize(Std.int(layer.width * stuff.scale));
				layer.updateHitbox();
				layer.flipX = stuff.flipX;
				layer.ID = real;
				bgLayer.add(layer);
				real++;
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

		dadPosText = new FlxText(FlxG.width - 20, FlxG.height, 0,
			"dad.y = " + dad.y + "\ndad.x" + dad.x, 12);
		dadPosText.cameras = [camHUD];
		dadPosText.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(dadPosText);

		FlxG.camera.follow(camFollow);
    }

	var startMousePos:FlxPoint = new FlxPoint();
	var holdingObjectType:Null<Bool> = null;
	var startCharacterOffset:FlxPoint = new FlxPoint();
	var mousePos:FlxPoint;

	var characterMoved:String = "dad";

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
		if (FlxG.keys.justPressed.ESCAPE)
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
		
		if (FlxG.mouse.justPressed)
		{
			holdingObjectType = null;
			FlxG.mouse.getScreenPosition(camHUD, startMousePos);
			if (FlxG.mouse.overlaps(dad))
			{
				holdingObjectType = true;
				characterMoved = 'dad';
			}
			else if (FlxG.mouse.overlaps(boyfriend))
			{
				holdingObjectType = true;
				characterMoved = 'bf';
			}
			else if (FlxG.mouse.overlaps(gf))
				{
					holdingObjectType = true;
					characterMoved = 'gf';
				}
		}
		if(FlxG.mouse.justReleased) {
			holdingObjectType = null;
		}

		if(holdingObjectType != null)
		{
			if(FlxG.mouse.justMoved)
			{
				mousePos = FlxG.mouse.getScreenPosition();
				repositionCharacters();
			}
		}

		super.update(elapsed);
	}

	function repositionCharacters()
	{
		// Move the shitheads around
		if (characterMoved == 'dad')
		{
			dad.x = mousePos.x - dad.width/2;
			dad.y = mousePos.y - dad.height/2;
		}
		else if (characterMoved == 'bf')
		{
			boyfriend.x = mousePos.x - boyfriend.width/2;
			boyfriend.y = mousePos.y - boyfriend.height/2;
		}
		else if (characterMoved == 'gf')
			{
				gf.x = mousePos.x - gf.width/2;
				gf.y = mousePos.y - gf.height/2;
			}
		
		//Make them save to json
		stageData.girlfriend[0] = gf.x;
		stageData.girlfriend[1] = gf.y;
		stageData.boyfriend[0] = boyfriend.x;
		stageData.boyfriend[1] = boyfriend.y;
		stageData.opponent[0] = dad.x;
		stageData.opponent[1] = dad.y;
		
		reloadText();
	}

	function reloadText() {
		dadPosText.text = "dad.y " + dad.y + "\ndad.x " + dad.x;
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

	function reloadStageData() {
		for (layer in bgLayer)
			{
				layer.kill();
			}
		var layerArray = stageData.layers;
		for (stuff in layerArray)
			{
				var real:Int = 0;
				var layer:BGSprite = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
				layer.setGraphicSize(Std.int(layer.width * stuff.scale));
				layer.updateHitbox();
				layer.flipX = stuff.flipX;
				layer.ID = real;
				bgLayer.add(layer);
				real++;
			}
	}

    function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function addImage(file:String)
		{
			var newImage:LayerArray = {
				image: file,
				flipX: false,
				scale: 1,
				scrollfactor: [1.0, 1.0],
				offset: [0, 0],
			}
			stageData.layers.push(newImage);
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