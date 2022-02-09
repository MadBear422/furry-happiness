package editors;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
#if desktop
import Discord.DiscordClient;
#end
import openfl.utils.Assets;
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
	var bgLayerInFront:FlxTypedGroup<BGSprite>;
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
	var layerDropDown:FlxUIDropDownMenuCustom;
	var imageInputText:FlxUIInputText;
	var nameInputText:FlxUIInputText;
	var addImageButton:FlxButton;

	var layer:BGSprite;
	var layerName:String;

	var sillyLayer_X:Float;
	var sillyLayer_Y:Float;

	var sillyWidth:Float;
	var sillyHeight:Float;

	var sillyScrollFactor:Float;
	var sillyScale:Float;

	var deleted:Bool = false;
	var hide:Bool = false;
	var lockPos:Bool = false;

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
		FlxG.cameras.add(camMenu);
		FlxG.cameras.add(camHUD);

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
						name: "wall",
						image: "stageback",
						animation: "",
						flipX: false,
						scale: 1,
						scrollfactor: [0.9, 0.9],
						offset: [-600, -200],
						onFront: false,
					},
					{
						name: "floor",
						image: "stagefront",
						animation: "",
						flipX: false,
						scale: 1.1,
						scrollfactor: [0.9, 0.9],
						offset: [-650, 600],
						onFront: false,
					},
					{
						name: "light",
						image: "stage_light",
						animation: "",
						flipX: false,
						scale: 1.1,
						scrollfactor: [0.9, 0.9],
						offset: [-125, -100],
						onFront: false,
					},
					{
						name: "light_extra",
						image: "stage_light",
						animation: "",
						flipX: true,
						scale: 1.1,
						scrollfactor: [0.9, 0.9],
						offset: [1225, -100],
						onFront: false,
					},
					{
						name: "curtains",
						image: "stagecurtains",
						animation: "",
						flipX: false,
						scale: 0.9,
						scrollfactor: [1.3, 1.3],
						offset: [-500, -300],
						onFront: false,
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
				layerName = stuff.name;
				if (!bgLayerName.contains(stuff.name))
				bgLayerName.push(layerName);
				layer = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
				layer.setGraphicSize(Std.int(layer.width * stuff.scale));
				layer.updateHitbox();
				layer.flipX = stuff.flipX;
				layer.ID = real;
				bgLayer.add(layer);
				real++;
				sillyScale = stuff.scale;
			}

		defaultCamZoom = stageData.defaultZoom;
		//isPixelStage = stageData.isPixelStage; Do this shit later
		spawnCharacters();

		bgLayerInFront = new FlxTypedGroup<BGSprite>();
		add(bgLayerInFront);

		var layerArray = stageData.layers;
		var real:Int = 0;
		for (stuff in layerArray)
		{
			layerName = stuff.name;
				if (!bgLayerName.contains(stuff.name))
				bgLayerName.push(layerName);
			layer = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
			if (stuff.animation != "")
			{
				layer.frames = Paths.getSparrowAtlas(stuff.image);
				layer.animation.addByPrefix('anim', stuff.animation, 24, true);
				layer.animation.play('anim', true);
			}
			layer.setGraphicSize(Std.int(layer.width * stuff.scale));
			layer.updateHitbox();
			layer.flipX = stuff.flipX;
			layer.ID = real;
			if (stuff.onFront)
			{
				bgLayerInFront.add(layer);
			}
			else
			{
				bgLayer.add(layer);
			}
			real++;
			sillyScale = stuff.scale;
		}
        
		// Pro Tips
		var tipText:FlxText = new FlxText(FlxG.width - 20, FlxG.height, 0,
			"Click and Drag the Assets to Move
			\nQ/E - Change Layers
			\nH - Toggle BG Opcaity
			\nL - Toggle Character Pos Change
			\nDELETE - Delete Selected Layer
			\nMouse Wheel - Camera Zoom In/Out
			\nMiddle Mouse - Move Camera
			\nR - Reset Camera Zoom
			\nHold Shift to Zoom Camera Faster\n", 12);
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
		UI_box.y = UI_box.y + 25;
		UI_box.scrollFactor.set();
		add(UI_box);
		addUI();

		layerNum = new FlxText(FlxG.width - 1180, FlxG.height - 700, 0,
			"Layer: " + bgLayerName[curSelected], 12);
			trace(layerNum.x);
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
			"" + stageData.opponent[0] + "\n" + stageData.opponent[1], 12);
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
			"" + stageData.boyfriend[0] + "\n" + stageData.boyfriend[1], 12);
		bfPosNum.cameras = [camHUD];
		bfPosNum.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		bfPosNum.scrollFactor.set();
		bfPosNum.borderSize = 1;
		add(bfPosNum);

		gfPosNum = new FlxText(gfPosText.x + 115, gfPosText.y, 0,
			"" + stageData.girlfriend[0] + "\n" + stageData.girlfriend[1], 12);
		gfPosNum.cameras = [camHUD];
		gfPosNum.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		gfPosNum.scrollFactor.set();
		gfPosNum.borderSize = 1;
		add(gfPosNum);

		FlxG.camera.follow(camFollow);
		changeLayer(0);
		highlightLayer();
    }

	var startMousePos:FlxPoint = new FlxPoint();
	var startOffset:FlxPoint = new FlxPoint();
	var startCam:FlxPoint = new FlxPoint();
	var holdingObjectType:Null<Bool> = null;
	var moveCam:Null<Bool> = null;
	var mousePos:FlxPoint;

	var characterMoved:String = "dad";

	function updateSettingData() {
		for (stuff in stageData.layers)
			{
				if (bgLayerName[curSelected] == stuff.name)
					{
						scaleStepper.value = stuff.scale;
						scrollStepperX.value = stuff.scrollfactor[0];
						scrollStepperY.value = stuff.scrollfactor[1];
						if (stuff.flipX == false)
							{
								flipXCheckBox.checked = false;
							}
						else
							{
								flipXCheckBox.checked = true;
							}
						if (stuff.onFront == false)
							{
								addImageOnTopCheck.checked = false;
							}
						else
							{
								addImageOnTopCheck.checked = true;
							}
					}
			}
	}

	function highlightLayer()
		{
			bgLayer.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
					layer.shader = newShader.shader;
			});
			bgLayerInFront.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
					layer.shader = newShader.shader;
			});
		}

	function unhighlightLayer()
		{
			bgLayer.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
					{
						layer.shader = oldShader.shader;
					}
				});

			bgLayerInFront.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
					{
						layer.shader = oldShader.shader;
					}
				});
		}

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
		layerDropDown.selectedId = '' + curSelected;
		updateOffsetText();
		updateText();
		updateSettingData();
		//reloadStageData();
	}

	function updateOffsetText()
		{
			bgLayer.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
					{
						//layer.alpha = 1;
		
						sillyLayer_X = layer.x;
						sillyLayer_Y = layer.y;
						sillyWidth = layer.width;
						sillyHeight = layer.height;
					}
				});
			bgLayerInFront.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
					{
						//layer.alpha = 1;
		
						sillyLayer_X = layer.x;
						sillyLayer_Y = layer.y;
						sillyWidth = layer.width;
						sillyHeight = layer.height;
					}
				});
		}

	function reloadText () {
		layerNum.text = "Layer: " + bgLayerName[curSelected];
		layerPosNum.text = "" + sillyLayer_X + "\n" + sillyLayer_Y;
		dadPosNum.text = "" + stageData.opponent[0] + "\n" + stageData.opponent[1];
		bfPosNum.text = "" + stageData.boyfriend[0] + "\n" + stageData.boyfriend[1];
		gfPosNum.text = "" + stageData.girlfriend[0] + "\n" + stageData.girlfriend[1];
	}

	function updateText() {
		var offsetPosDad:Array<Dynamic> = updatePosArrayText(stageData.opponent, dad.positionArray);
		var offsetPosGf:Array<Dynamic> = updatePosArrayText(stageData.girlfriend, gf.positionArray);
		var offsetPosBf:Array<Dynamic> = updatePosArrayText(stageData.boyfriend, boyfriend.positionArray);

		layerNum.text = "Layer: " + bgLayerName[curSelected];
		layerPosNum.text = "" + sillyLayer_X + "\n" + sillyLayer_Y;
		dadPosNum.text = "" + offsetPosDad[0] + "\n" + offsetPosDad[1];
		bfPosNum.text = "" + offsetPosBf[0] + "\n" + offsetPosBf[1];
		gfPosNum.text = "" + offsetPosGf[0] + "\n" + offsetPosGf[1];
	}

	public static var curSelected:Int = 0;

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == scaleStepper)
			{
				updateLayerData();
				reloadStageData();
			}
			else if (sender == scrollStepperX || sender == scrollStepperY)
				{
					updateLayerData();
					reloadStageData();
				}
		}
	}

	override function update(elapsed:Float)
	{
		if (imageInputText.hasFocus || nameInputText.hasFocus)
			{
				if(FlxG.keys.justPressed.ENTER) {
					imageInputText.hasFocus = false;
				}
			}

		else {
			if (hide)
				camGame.alpha = 0.5;
			else
				camGame.alpha = 1;
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

		if (FlxG.keys.justPressed.H)
			{
				hide = !hide;
			}
		if (FlxG.keys.justPressed.L)
			{
				lockPos = !lockPos;
			}
	

		if (FlxG.keys.justPressed.E)
		{
			if (curSelected < stageData.layers.length-1)
			unhighlightLayer();
			changeLayer(1);
			highlightLayer();
		}
		else if (FlxG.keys.justPressed.Q)
		{
			if (curSelected > 0)
			unhighlightLayer();
			changeLayer(-1);
			highlightLayer();
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
									if (bgLayerName[curSelected] == stuff.name)
									{
										if (!stuff.onFront)
										{
											stageData.layers.remove(stuff);
										}
									}
								}
					trace("killed " + layer.ID);
					layer.kill();
					reloadStageData();
				}

			}
			else
				{
					//layer.alpha = 0.25;
				}
		});
		bgLayerInFront.forEach(function(layer:BGSprite)
		{
			if (layer.ID == curSelected)
			{

				bgLayer.forEach(function(layer:BGSprite)
					{
						if (layer.ID == curSelected)
						{
							//layer.alpha = 1;
			
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
									if (bgLayerName[curSelected] == stuff.name)
										{
											if (stuff.onFront)
											{
												stageData.layers.remove(stuff);
											}
										}
								}
					trace("killed " + layer.ID);
					layer.kill();
					reloadStageData();
				}

			}
			else
				{
					//layer.alpha = 0.5;
				}
		});
		deleted = false;

		if (holdingObjectType != null || !FlxG.mouse.overlaps(UI_box))
			{
				FlxTween.cancelTweensOf(UI_box);
				FlxTween.tween(UI_box, {alpha: 0.25}, 0.1, {
					ease: FlxEase.cubeOut
				});
				//UI_box.alpha = 0.25;
			}
		else
			{
				FlxTween.cancelTweensOf(UI_box);
				FlxTween.tween(UI_box, {alpha: 1}, 0.1, {
					ease: FlxEase.cubeOut
				});
				//UI_box.alpha = 1;
			}

		// Return back to editor
		if (FlxG.keys.justPressed.ESCAPE)
			{
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.music.stop();
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}

		// Navigate camera position
		if (FlxG.mouse.pressedMiddle && moveCam == null)
			{
				FlxG.mouse.getScreenPosition(camMenu, startMousePos);
				startCam.x = camFollow.x;
				startCam.y = camFollow.y;
				moveCam = true;
			}
			if (FlxG.mouse.justMoved && moveCam != null)
				{
					mousePos = FlxG.mouse.getScreenPosition();
					camFollow.x = Math.round(mousePos.x - startMousePos.x) + startCam.x;
					camFollow.y = Math.round(mousePos.y - startMousePos.y) + startCam.y;
				}

			if (!FlxG.mouse.pressedMiddle)
				{
					moveCam = null;
				}
		
		// Camera Zoom
		if (FlxG.mouse.wheel != 0)
			{
				if (FlxG.keys.pressed.SHIFT)
					{
						FlxG.camera.zoom += (FlxG.mouse.wheel / 25);
					}
					FlxG.camera.zoom += (FlxG.mouse.wheel / 100);
			}
		if (FlxG.keys.justPressed.R)
			{
				FlxG.camera.zoom = 0;
			}
		
		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(UI_box))
		{
			holdingObjectType = null;
			FlxG.mouse.getScreenPosition(camMenu, startMousePos);
			if (FlxG.mouse.overlaps(boyfriend) && !lockPos)
			{
				holdingObjectType = true;
				characterMoved = 'bf';
				startOffset.x = boyfriend.x; startOffset.y = boyfriend.y;
			}
			else if (FlxG.mouse.overlaps(dad) && !lockPos)
				{
					holdingObjectType = true;
					characterMoved = 'dad';
					startOffset.x = dad.x; startOffset.y = dad.y;
				}
			else if (FlxG.mouse.overlaps(gf) && !lockPos)
			{
				holdingObjectType = true;
				characterMoved = 'gf';
				startOffset.x = gf.x; startOffset.y = gf.y;
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
											startOffset.x = layer.x; startOffset.y = layer.y;
										}
								}
						});
					bgLayerInFront.forEach(function(layer:BGSprite)
						{
							if (layer.ID == curSelected)
								{
									if (FlxG.mouse.overlaps(layer))
										{
											holdingObjectType = true;
											characterMoved = 'layer';
											startOffset.x = layer.x; startOffset.y = layer.y;
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
						sillyLayer_X = Math.round(mousePos.x - startMousePos.x) + startOffset.x;
						sillyLayer_Y = Math.round(mousePos.y - startMousePos.y) + startOffset.y;
						moveLayer();
					}
			}
		}
		camMenu.zoom = FlxG.camera.zoom;
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
		bgLayerInFront.forEach(function(layer:BGSprite)
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
	var tempLayers:Array<String> = [];
	var tempMapLayer:Map<String, Bool> = new Map<String, Bool>();
	var stageFile:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
	var tempMap:Map<String, Bool> = new Map<String, Bool>();

	var scaleStepper:FlxUINumericStepper;
	var scrollStepperX:FlxUINumericStepper;
	var scrollStepperY:FlxUINumericStepper;
	var flipXCheckBox:FlxUICheckBox;
	var addImageOnTopCheck:FlxUICheckBox;

	function addUI()
		{
			var tab_group = new FlxUI(null, UI_box);
			tab_group.name = "Settings";

			var saveBGButton:FlxButton = new FlxButton(25, 15, "Save BG", function() {
				trace(stageData);
				saveBackground();
			});
			//saveBGButton.cameras = [camHUD];

			imageInputText = new FlxUIInputText(saveBGButton.x - 10, saveBGButton.y + 25, 200, 'backgrounds/image_name');
			nameInputText = new FlxUIInputText(imageInputText.x, imageInputText.y + 25, 200, 'asset_name');
			addImageButton = new FlxButton(saveBGButton.x + 100, saveBGButton.y, "Add Image", function()
			{
					addImage(nameInputText.text, imageInputText.text, false);
					reloadStageData();
			});
			scaleStepper = new FlxUINumericStepper(saveBGButton.x - 10, saveBGButton.y + 100, 0.1, 1, 0.05, 10, 1);
			scrollStepperX = new FlxUINumericStepper(scaleStepper.x + 75, saveBGButton.y + 100, 0.1, 1, 0.05, 10, 1);
			scrollStepperY = new FlxUINumericStepper(scrollStepperX.x, scrollStepperX.y + 40, 0.1, 1, 0.05, 10, 1);
			flipXCheckBox = new FlxUICheckBox(scaleStepper.x, scaleStepper.y + 20, null, null, "Flip X", 50);
			addImageOnTopCheck = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 20, null, null, "Front", 50);
			bgLayer.forEach(function(layer:BGSprite)
				{
					if (layer.ID == curSelected)
						flipXCheckBox.checked = layer.flipX;
				});
			flipXCheckBox.callback = function(){
				for (stuff in stageData.layers)
					{
						if (bgLayerName[curSelected] == stuff.name)
							{
								stuff.flipX = !stuff.flipX;
							}
					}
				updateLayerData();
				reloadStageData();
				highlightLayer();
			};

			addImageOnTopCheck.callback = function(){
				for (stuff in stageData.layers)
					{
						if (bgLayerName[curSelected] == stuff.name)
							{
								stuff.onFront = !stuff.onFront;
							}
					}
				//changeStage();
				updateLayerData();
				reloadStageData();
				highlightLayer();
			};

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

			for (i in 0...bgLayerName.length) // Prevent Dupes
				{
					var layerToCheck:String = bgLayerName[i];
					if (!tempMapLayer.exists(layerToCheck))
						{
							tempLayers.push(''+i);
						}
						tempMapLayer.set(layerToCheck, true);
				}
			
			stageDropDown = new FlxUIDropDownMenuCustom(225, 15, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true), function(character:String)
			{
				unhighlightLayer();
				curStage = stages[Std.parseInt(character)];
				stageData = StageData.getStageFile(curStage);
				changeStage();
				reloadStageData();
				layerDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(bgLayerName, true));
				highlightLayer();
			});
			stageDropDown.selectedLabel = curStage;
			blockPressWhileScrolling.push(stageDropDown);

			layerDropDown = new FlxUIDropDownMenuCustom(stageDropDown.x, stageDropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(bgLayerName, true), function(layR:String)
				{
					unhighlightLayer();
					curSelected = Std.parseInt(layerDropDown.selectedId);
					changeLayer(0);
					highlightLayer();
				});
			layerDropDown.selectedId = '' + curSelected;

			tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
			tab_group.add(new FlxText(scrollStepperX.x, scrollStepperX.y - 18, 0, 'Scroll X:'));
			tab_group.add(new FlxText(scrollStepperY.x, scrollStepperY.y - 18, 0, 'Scroll Y:'));
			tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 0, 'Stages:'));
			tab_group.add(new FlxText(layerDropDown.x, layerDropDown.y - 18, 0, 'Layers:'));
			tab_group.add(scaleStepper);
			tab_group.add(scrollStepperX);
			tab_group.add(scrollStepperY);
			tab_group.add(flipXCheckBox);
			tab_group.add(saveBGButton);
			tab_group.add(imageInputText);
			tab_group.add(nameInputText);
			tab_group.add(addImageButton);
			tab_group.add(addImageOnTopCheck);
			tab_group.add(layerDropDown);
			tab_group.add(stageDropDown);
			UI_box.addGroup(tab_group);
		}

	function repositionCharacters()
	{
		// Move the shitheads around
		if (characterMoved == 'dad')
		{
			dad.x = Math.round(mousePos.x - startMousePos.x) + startOffset.x;
			dad.y = Math.round(mousePos.y - startMousePos.y) + startOffset.y;
		}
		else if (characterMoved == 'bf')
		{
			boyfriend.x = Math.round(mousePos.x - startMousePos.x) + startOffset.x;
			boyfriend.y = Math.round(mousePos.y - startMousePos.y) + startOffset.y;
		}
		else if (characterMoved == 'gf')
		{
			gf.x =  Math.round(mousePos.x - startMousePos.x) + startOffset.x;
			gf.y =  Math.round(mousePos.y - startMousePos.y) + startOffset.y;
		}
		
		//Make them save to json
		stageData.girlfriend[0] = gf.x;
		stageData.girlfriend[1] = gf.y;
		stageData.boyfriend[0] = boyfriend.x;
		stageData.boyfriend[1] = boyfriend.y;
		stageData.opponent[0] = dad.x;
		stageData.opponent[1] = dad.y;
		updateOffsetText();
		updateText();
		reloadText();
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
		for (layer in bgLayerInFront)
		{
			layer.kill();
		}
		var layerArray = stageData.layers;
		bgLayerName = [];
		for (stuff in layerArray)
			{
				//scaleStepper.value = stuff.scale;
				layerName = stuff.name;
				if (!bgLayerName.contains(stuff.name))
				bgLayerName.push(layerName);
				layer = new BGSprite(stuff.image, stuff.offset[0], stuff.offset[1], stuff.scrollfactor[0], stuff.scrollfactor[1]);
				if (stuff.animation != "")
				{
					layer.frames = Paths.getSparrowAtlas(stuff.image);
					layer.animation.addByPrefix('anim', stuff.animation, 24, true);
					layer.animation.play('anim', true);
				}
				layer.setGraphicSize(Std.int(layer.width * stuff.scale));
				layer.updateHitbox();
				layer.flipX = stuff.flipX;
				layer.ID = real;
				if (stuff.onFront)
				{
					bgLayerInFront.add(layer);
				}
				else
				{
					bgLayer.add(layer);
				}
				real++;
			}
			reloadText();
	}

	function changeStage() {
		remove(gf);
		remove(dad);
		remove(boyfriend);
		spawnCharacters();
		curSelected = 0;
		for (stuff in stageData.layers)
			{
				if (bgLayerName[curSelected] == stuff.name)
					{
						flipXCheckBox.checked = stuff.flipX;
						addImageOnTopCheck.checked = stuff.onFront;
					}
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

	// ASSIGNS LAYER DATA FROM SELECTED LAYER TO JSON
	function updateLayerData()
		{
			for (stuff in stageData.layers)
				{
					if (bgLayerName[curSelected] == stuff.name)
						{
							stuff.offset[0] = sillyLayer_X;
							stuff.offset[1] = sillyLayer_Y;
							stuff.scale = scaleStepper.value;
							stuff.scrollfactor[0] = scrollStepperX.value;
							stuff.scrollfactor[1] = scrollStepperY.value;
						}
				}
		}

	function addImage(named:String, file:String, front:Bool, ?animation:String = "")
		{
			var newImage:LayerArray = {
				name: named,
				image: file,
				animation: animation,
				flipX: false,
				scale: 1,
				scrollfactor: [1.0, 1.0],
				offset: [0, 0],
				onFront: front,
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

		function updatePosArray(char:Character, pos:Array<Float>)
			{
				var outcome:Array<Dynamic> = [0,0];
				outcome[0] = char.x - pos[0];
				outcome[1] = char.y - pos[1];
				return outcome;
			}
		
		function updatePosArrayText(char:Array<Dynamic>, pos:Array<Float>)
			{
				var outcome:Array<Dynamic> = [0,0];
				outcome[0] = char[0] - pos[0];
				outcome[1] = char[1] - pos[1];
				return outcome;
			}

		function saveBackground() {
			var json = {
				"directory": stageData.directory,
				"defaultZoom": stageData.defaultZoom,
				"isPixelStage": stageData.isPixelStage,
	
				"layers": stageData.layers,
	
				"boyfriend": updatePosArray(boyfriend, boyfriend.positionArray),
				"girlfriend": updatePosArray(gf, gf.positionArray),
				"opponent": updatePosArray(dad, dad.positionArray)
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