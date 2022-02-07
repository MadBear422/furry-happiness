package editors;

import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
#if desktop
import Discord.DiscordClient;
#end
import haxe.Json;
import flixel.util.FlxColor;
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
	public var curStage:String;
	public var stageData:StageFile;
	var _file:FileReference;

    public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	var newShader:ColorSwap = new ColorSwap();
	var oldShader:ColorSwap = new ColorSwap();

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	var gfCharacter:String = 'gf';
	var dadCharacter:String = 'dad';
	var bfCharacter:String = 'bf';

	public var defaultCamZoom:Float = 1.05;

	var camFollow:FlxObject;

	var bgLayer:FlxTypedGroup<BGSprite>;
	var bgLayerName:Array<String> = [];

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	private var camMenu:FlxCamera;

	var UI_box:FlxUITabMenu;
	
	var layerPosText:FlxText;
	var dadPosText:FlxText;
	var bfPosText:FlxText;
	var gfPosText:FlxText;
	var layerPosNum:FlxText;
	var dadPosNum:FlxText;
	var bfPosNum:FlxText;
	var gfPosNum:FlxText;
	var layerNum:FlxText;

	var newImage:String = "";
	var stageDropDown:FlxUIDropDownMenuCustom;
	var imageInputText:FlxUIInputText;
	var addImageButton:FlxButton;

	var layer:BGSprite;
	var layerName:String;

	var sillyLayer_X:Float;
	var sillyLayer_Y:Float;

	var sillyWidth:Float;
	var sillyHeight:Float;

	var deleted:Bool = false;

    override function create() {

		// Shader to indicate what layer is selected
		newShader.brightness = 1;
		oldShader.brightness = 0;

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
		var real:Int = 0;
		for (stuff in layerArray)
			{
				layerName = stuff.image;
				bgLayerName.push(layerName);
				layer = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
				layer.setGraphicSize(Std.int(layer.width * stuff.scale));
				layer.updateHitbox();
				layer.flipX = stuff.flipX;
				layer.ID = real;
				bgLayer.add(layer);
				real++;
			}

		defaultCamZoom = stageData.defaultZoom;
		//isPixelStage = stageData.isPixelStage; Do this shit later
		spawnCharacters();
        
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

		var tabs = [
			//{name: 'Offsets', label: 'Offsets'},
			{name: 'Settings', label: 'Settings'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(350, 250);
		UI_box.x = (FlxG.width - 275) - 100;
		UI_box.y = UI_box.y + UI_box.height;
		UI_box.scrollFactor.set();
		add(UI_box);
		addUI();

		layerNum = new FlxText(FlxG.width - 1200, FlxG.height - 700, 0,
			"Layer: " + curSelected, 12);
		layerNum.cameras = [camHUD];
		layerNum.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		layerNum.scrollFactor.set();
		layerNum.borderSize = 1;
		layerNum.x -= layerNum.width;
		layerNum.y -= layerNum.height - 10;
		add(layerNum);

		layerPosText = new FlxText(layerNum.x, layerNum.y + 25, 0,
			"Layer X:\nLayer Y:", 12);
		layerPosText.cameras = [camHUD];
		layerPosText.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		layerPosText.scrollFactor.set();
		layerPosText.borderSize = 1;
		add(layerPosText);

		dadPosText = new FlxText(layerPosText.x, layerPosText.y + 50, 0,
			"Dad X:\nDad Y:", 12);
		dadPosText.cameras = [camHUD];
		dadPosText.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dadPosText.scrollFactor.set();
		dadPosText.borderSize = 1;
		add(dadPosText);

		bfPosText = new FlxText(dadPosText.x, dadPosText.y + 50, 0,
			"Boyfriend X:\nBoyfriend Y:", 12);
		bfPosText.cameras = [camHUD];
		bfPosText.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		bfPosText.scrollFactor.set();
		bfPosText.borderSize = 1;
		add(bfPosText);

		gfPosText = new FlxText(bfPosText.x, bfPosText.y + 50, 0,
			"Girlfriend X:\nGirlfriend Y:", 12);
		gfPosText.cameras = [camHUD];
		gfPosText.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		gfPosText.scrollFactor.set();
		gfPosText.borderSize = 1;
		add(gfPosText);

		dadPosNum = new FlxText(dadPosText.x + 65, dadPosText.y, 0,
			"" + dad.x + "\n" + dad.y, 12);
		dadPosNum.cameras = [camHUD];
		dadPosNum.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dadPosNum.scrollFactor.set();
		dadPosNum.borderSize = 1;
		add(dadPosNum);

		layerPosNum = new FlxText(layerPosText.x + 80, layerPosText.y, 0,
			"" + sillyLayer_X + "\n" + sillyLayer_Y, 12);
		layerPosNum.cameras = [camHUD];
		layerPosNum.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		layerPosNum.scrollFactor.set();
		layerPosNum.borderSize = 1;
		add(layerPosNum);

		bfPosNum = new FlxText(bfPosText.x + 115, bfPosText.y, 0,
			"" + boyfriend.x + "\n" + boyfriend.y, 12);
		bfPosNum.cameras = [camHUD];
		bfPosNum.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		bfPosNum.scrollFactor.set();
		bfPosNum.borderSize = 1;
		add(bfPosNum);

		gfPosNum = new FlxText(gfPosText.x + 115, gfPosText.y, 0,
			"" + gf.x + "\n" + gf.y, 12);
		gfPosNum.cameras = [camHUD];
		gfPosNum.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		gfPosNum.scrollFactor.set();
		gfPosNum.borderSize = 1;
		add(gfPosNum);

		FlxG.camera.follow(camFollow);
    }

	var startMousePos:FlxPoint = new FlxPoint();
	var holdingObjectType:Null<Bool> = null;
	var startCharacterOffset:FlxPoint = new FlxPoint();
	var mousePos:FlxPoint;

	var characterMoved:String = "dad";

	function changeLayer(b:Int) {
		curSelected += b;

		if (curSelected < 0)
			{
				curSelected = 0;
			}
			else if (curSelected > stageData.layers.length-1)
			{
				curSelected = stageData.layers.length-1;
			}
		updateOffsetText();
		updateText();
	}

	function updateOffsetText()
		{
			bgLayer.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
					{
						layer.alpha = 1;
						layer.shader = newShader.shader;
		
						sillyLayer_X = layer.x;
						sillyLayer_Y = layer.y;
						sillyWidth = layer.width;
						sillyHeight = layer.height;
					}
				});
		}

	function updateText() {
		layerNum.text = "Layer: " + curSelected;
		layerPosNum.text = "" + sillyLayer_X + "\n" + sillyLayer_Y;
		dadPosNum.text = "" + dad.y + "\n" + dad.x;
		bfPosNum.text = "" + boyfriend.y + "\n" + boyfriend.x;
		gfPosNum.text = "" + gf.y + "\n" + gf.x;
	}

	public static var curSelected:Int = 0;

	override function update(elapsed:Float)
	{

		if (curSelected < 0)
			{
				curSelected = 0;
			}
			else if (curSelected > stageData.layers.length-1)
			{
				curSelected = stageData.layers.length-1;
			}

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

		if (FlxG.keys.justPressed.W)
		{
			changeLayer(1);
		}
		else if (FlxG.keys.justPressed.S)
		{
			changeLayer(-1);
		}
		bgLayer.forEach(function(layer:BGSprite)
		{
			if (layer.ID == curSelected)
			{

				bgLayer.forEach(function(layer:BGSprite)
					{
						if (layer.ID == curSelected)
						{
							layer.alpha = 1;
							layer.shader = newShader.shader;
			
							sillyLayer_X = layer.x;
							sillyLayer_Y = layer.y;
							sillyWidth = layer.width;
							sillyHeight = layer.height;
						}
					});
					
				// Delete Fuckin Layers
				if (FlxG.keys.justPressed.DELETE && !deleted)
				{
					deleted = true;
							for (stuff in stageData.layers)
								{
									if (bgLayerName[curSelected] == stuff.image)
										{
											stageData.layers.remove(stuff);
										}
								}
					trace("killed " + layer.ID);
					layer.kill();
					reloadStageData();
				}

			}
			else
				{
					layer.shader = newShader.shader;
					layer.alpha = 0.5;
				}
		});
		deleted = false;

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
		
		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(UI_box))
		{
			holdingObjectType = null;
			FlxG.mouse.getScreenPosition(camMenu, startMousePos);
			if (FlxG.mouse.overlaps(boyfriend))
			{
				holdingObjectType = true;
				characterMoved = 'bf';
			}
			else if (FlxG.mouse.overlaps(dad))
				{
					holdingObjectType = true;
					characterMoved = 'dad';
				}
			else if (FlxG.mouse.overlaps(gf))
			{
				holdingObjectType = true;
				characterMoved = 'gf';
			}
			else
				{
					bgLayer.forEach(function(layer:BGSprite)
						{
							if (layer.ID == curSelected)
								{
									if (FlxG.mouse.overlaps(layer))
										{
											holdingObjectType = true;
											characterMoved = 'layer';
										}
								}
						});
				}
			
		}
		if(FlxG.mouse.justReleased) {
			holdingObjectType = null;
			// Update Layer Offsets
			updateLayerData();
		}

		if(holdingObjectType != null)
		{
			if(FlxG.mouse.justMoved)
			{
				mousePos = FlxG.mouse.getScreenPosition();
				if (characterMoved == 'gf' || characterMoved == 'dad' || characterMoved == 'bf')
					repositionCharacters();
				else if (characterMoved == 'layer')
					{
						sillyLayer_X = Math.round(mousePos.x - sillyWidth/2);
						sillyLayer_Y = Math.round(mousePos.y - sillyHeight/2);
						moveLayer();
					}
			}
		}
		camMenu.zoom = FlxG.camera.zoom;
		super.update(elapsed);
	}

	function moveLayer() {
		bgLayer.forEach(function(layer:BGSprite)
			{
				if (layer.ID == curSelected)
					{
						layer.x = sillyLayer_X;
						layer.y = sillyLayer_Y;
					}
			});
			updateText();
	}

	function spawnCharacters() {
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
	}

	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];
	var stages:Array<String> = [];
	var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
	var tempMap:Map<String, Bool> = new Map<String, Bool>();

	function addUI()
		{
			var tab_group = new FlxUI(null, UI_box);
			tab_group.name = "Settings";

			var saveBGButton:FlxButton = new FlxButton(25, 15, "Save BG", function() {
				trace(stageData);
				saveBackground();
			});
			//saveBGButton.cameras = [camHUD];
	
			imageInputText = new FlxUIInputText(saveBGButton.x - 10, saveBGButton.y + 25, 200, 'stagefront', 8);
			addImageButton = new FlxButton(saveBGButton.x + 100, saveBGButton.y, "Add Image", function()
			{
				addImage(imageInputText.text);
				reloadStageData();
			});
			//imageInputText.cameras = [camHUD];
			//addImageButton.cameras = [camHUD];
			imageInputText.updateHitbox();
			addImageButton.updateHitbox();
			imageInputText.scrollFactor.set();
			addImageButton.scrollFactor.set();

			#if MODS_ALLOWED
			var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Paths.currentModDirectory + '/stages/'), Paths.getPreloadPath('stages/')];
			#else
			var directories:Array<String> = [Paths.getPreloadPath('stages/')];
			#end
	
			for (i in 0...stageFile.length) { //Prevent duplicates
				var stageToCheck:String = stageFile[i];
				if(!tempMap.exists(stageToCheck)) {
					stages.push(stageToCheck);
				}
				tempMap.set(stageToCheck, true);
			}

			stageDropDown = new FlxUIDropDownMenuCustom(225, 15, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true), function(character:String)
			{
				curStage = stages[Std.parseInt(character)];
				changeStage();
				reloadStageData();
			});
			stageDropDown.selectedLabel = curStage;
			blockPressWhileScrolling.push(stageDropDown);

			tab_group.add(saveBGButton);
			tab_group.add(imageInputText);
			tab_group.add(addImageButton);
			tab_group.add(stageDropDown);
			UI_box.addGroup(tab_group);
		}

	function repositionCharacters()
	{
		// Move the shitheads around
		if (characterMoved == 'dad')
		{
			dad.x = Math.round(mousePos.x - dad.width*2 + camFollow.x);
			dad.y = Math.round(mousePos.y - dad.height + camFollow.y);
		}
		else if (characterMoved == 'bf')
		{
			boyfriend.x = Math.round(mousePos.x - boyfriend.width*2 + camFollow.x);
			boyfriend.y = Math.round(mousePos.y - boyfriend.height + camFollow.y);
		}
		else if (characterMoved == 'gf')
		{
			gf.x = Math.round(mousePos.x - gf.width*1.5 + camFollow.x);
			gf.y = Math.round(mousePos.y - gf.height + camFollow.y);
		}
		
		//Make them save to json
		stageData.girlfriend[0] = gf.x;
		stageData.girlfriend[1] = gf.y;
		stageData.boyfriend[0] = boyfriend.x;
		stageData.boyfriend[1] = boyfriend.y;
		stageData.opponent[0] = dad.x;
		stageData.opponent[1] = dad.y;
		
		updateText();
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
		var real:Int = 0;
		for (layer in bgLayer)
			{
				layer.kill();
			}
		var layerArray = stageData.layers;
		bgLayerName = [];
		for (stuff in layerArray)
			{
				layerName = stuff.image;
				bgLayerName.push(layerName);
				layer = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
				layer.setGraphicSize(Std.int(layer.width * stuff.scale));
				layer.updateHitbox();
				layer.flipX = stuff.flipX;
				layer.ID = real;
				bgLayer.add(layer);
				real++;
			}
	}

	function changeStage() {
		stageData = StageData.getStageFile(curStage);
		remove(gf);
		remove(dad);
		remove(boyfriend);
		spawnCharacters();
	}

    function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function updateLayerData()
		{
			for (stuff in stageData.layers)
				{
					if (bgLayerName[curSelected] == stuff.image)
						{
							stuff.offset[0] = sillyLayer_X;
							stuff.offset[1] = sillyLayer_Y;
						}
				}
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

	function removeImage(file:String) {
		//attempted to add removing images but failed :(
		/*var funnyImage:LayerArray = {
			image: file,
			flipX: false,
			scale: 1,
			scrollfactor: [1.0, 1.0],
			offset: [0, 0],
		}
		stageData.layers.remove(funnyImage);*/
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