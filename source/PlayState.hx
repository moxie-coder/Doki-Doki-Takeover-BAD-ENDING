package;

#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import motion.easing.*;
import haxe.Json;
import lime.utils.Assets;
import openfl.filters.ShaderFilter;
import openfl.geom.Point;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 49;
	public static var STRUM_X_MIDDLESCROLL = -272;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var BFCAM_X:Float = 0;
	public var BFCAM_Y:Float = 0;
	public var DADCAM_X:Float = 0;
	public var DADCAM_Y:Float = 0;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var extra1:Character;
	public var extra2:Character;

	var daStatic:BGSprite;
	var stagstatic:BGSprite;
	var screenPulse:BGSprite;
	var holylight:BGSprite;
	var redStatic:BGSprite;
	var inthenotepad:BGSprite;
	var notepadoverlay:BGSprite;
	var stageStatic:BGSprite;
	var bgwindo:FlxBackdrop;
	var bgwindo2:FlxBackdrop;
	var cambgwindo:FlxBackdrop;
	var cambgwindo2:FlxBackdrop;
	var bakaOverlay:BGSprite;
	var funnyEyes:BGSprite;
	var staticlol:StaticShader;
	private var staticAlpha:Float = 0;
	var bloodDrips:Bool = false;

	var swagShader:ColorSwap;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var bloodStrums:FlxTypedGroup<FlxSprite>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	private var grpUnderlay:FlxTypedGroup<FlxSprite>;

	public var camZooming:Bool = false;
	var forcecamZooming:Bool = true;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;

	public var healthBar:FlxBar;

	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;

	public var timeBar:FlxBar;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;

	private var startingSong:Bool = false;
	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camCache:FlxCamera;
	public var cameraSpeed:Float = 1;
	public var camNoteExtend:Float = 15; // How powerful the camnote stuff is

	// Bad Ending specific variables
	var pixelShitPart1:String = "";
	var pixelShitPart2:String = '';

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var vignette:FlxSprite;
	var imdead:FlxSprite;
	var darkScreen:FlxSprite;
	var titleCard:FlxSprite;
	var darkoverlay:FlxSprite;

	var heyTimer:Float;

	var closet:BGSprite;
	var clubroom:BGSprite;
	var deskfront:BGSprite;
	var evilSpace:FlxBackdrop;
	var clouds:FlxBackdrop;
	var fancyclouds:FlxBackdrop;
	var windowlight:BGSprite;
	var clubroomdark:BGSprite;
	var evilClubBG:BGSprite;
	var evilClubBGScribbly:BGSprite;
	var ruinedClubBG:BGSprite;
	var glitchfront:BGSprite;
	var glitchback:BGSprite;
	var evilPoem:BGSprite;
	var bloodyBG:BGSprite;
	var poemTransition:BGSprite;
	var closetCloseUp:BGSprite;

	var floatshit:Float = 0;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	var defaultStageZoom:Float = 1.05;
	
	//Thank you Holofunk dev team. Y'all the greatest
	var noteCam:Bool = false;
	public var camNoteX:Float = 0;
	public var camNoteY:Float = 0;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;

	var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;

	public var luaArray:Array<FunkinLua> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	// Precaching shit
	var precacheList:Map<String, String> = new Map<String, String>();

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camCache = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camCache.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camGame.filtersEnabled = false;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camCache);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		// FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: BAD ENDING";
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = PlayState.SONG.stage;

		if (PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1)
		{
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],

				boyfriend_camera: [0, 0],
				opponent_camera: [0, 0]
			};
		}

		defaultStageZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		if (stageData.boyfriend_camera != null)
		{
			BFCAM_X = stageData.boyfriend_camera[0];
			BFCAM_Y = stageData.boyfriend_camera[1];
		}
		if (stageData.opponent_camera != null)
		{
			DADCAM_X = stageData.opponent_camera[0];
			DADCAM_Y = stageData.opponent_camera[1];
		}
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		defaultCamZoom = defaultStageZoom;

		switch (curStage)
		{
			case 'stage': // Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'dokiclubroom': // DDTO
				closet = new BGSprite('clubroom/DDLCfarbg', -700, -520, 0.9, 0.9);
				closet.setGraphicSize(Std.int(closet.width * 1.6));
				closet.updateHitbox();
				add(closet);

				clubroom = new BGSprite('clubroom/DDLCbg', -700, -520, 1, 0.9);
				clubroom.setGraphicSize(Std.int(clubroom.width * 1.6));
				clubroom.updateHitbox();
				add(clubroom);

				if (!ClientPrefs.lowQuality)
				{
					deskfront = new BGSprite('clubroom/DesksFront', -700, -520, 1.3, 0.9);
					deskfront.setGraphicSize(Std.int(deskfront.width * 1.6));
					deskfront.updateHitbox();
				}

			case 'clubroomevil': // DDTO BAD ENDING
				if (!ClientPrefs.lowQuality)
				{
					evilSpace = new FlxBackdrop(Paths.image('bigmonika/Sky'));
					evilSpace.scrollFactor.set(0.1, 0.1);
					evilSpace.velocity.set(-10, 0);
					evilSpace.antialiasing = ClientPrefs.globalAntialiasing;
					add(evilSpace);
				}

				evilClubBG = new BGSprite('bigmonika/BG', -220, -110, 1, 1);
				evilClubBG.setGraphicSize(Std.int(evilClubBG.width * 1.3));
				add(evilClubBG);

			case 'stagnant': // hueh
				closet = new BGSprite('clubroom/DDLCfarbg', -700, -520, 0.9, 0.9);
				closet.setGraphicSize(Std.int(closet.width * 1.6));
				closet.updateHitbox();
				add(closet);

				clubroom = new BGSprite('clubroom/DDLCbg', -700, -520, 1, 0.9);
				clubroom.setGraphicSize(Std.int(clubroom.width * 1.6));
				clubroom.updateHitbox();
				add(clubroom);

				if (!ClientPrefs.lowQuality)
				{
					deskfront = new BGSprite('clubroom/DesksFront', -700, -520, 1.3, 0.9);
					deskfront.setGraphicSize(Std.int(deskfront.width * 1.6));
					deskfront.updateHitbox();

					evilSpace = new FlxBackdrop(Paths.image('bigmonika/Sky'));
					evilSpace.scrollFactor.set(0.1, 0.1);
					evilSpace.velocity.set(-10, 0);
					evilSpace.y -= 300;
					evilSpace.antialiasing = ClientPrefs.globalAntialiasing;
					evilSpace.visible = false;
					add(evilSpace);

					clouds = new FlxBackdrop(Paths.image('bigmonika/Clouds', 'doki'));
					clouds.scrollFactor.set(0.1, 0.1);
					clouds.velocity.set(-13, 0);
					clouds.y -= 300;
					clouds.antialiasing = ClientPrefs.globalAntialiasing;
					clouds.scale.set(0.7, 0.7);
					clouds.visible = false;
					add(clouds);

					fancyclouds = new FlxBackdrop(Paths.image('bigmonika/mask', 'doki'));
					fancyclouds.scrollFactor.set(0.1, 0.1);
					fancyclouds.velocity.set(-13, 0);
					fancyclouds.y -= 300;
					fancyclouds.antialiasing = ClientPrefs.globalAntialiasing;
					fancyclouds.scale.set(0.7, 0.7);
					fancyclouds.alpha = 1;
					fancyclouds.visible = false;
					add(fancyclouds);
				}

				evilClubBG = new BGSprite('bigmonika/BG', -220, -110, 1, 1);
				evilClubBG.setGraphicSize(Std.int(evilClubBG.width * 1.3));
				evilClubBG.visible = false;
				add(evilClubBG);

				if (!ClientPrefs.lowQuality)
				{
					clubroomdark = new BGSprite('bigmonika/shadow', -220, -110, 1, 1);
					clubroomdark.visible = false;
					clubroomdark.setGraphicSize(Std.int(clubroomdark.width * 1.3));

					windowlight = new BGSprite('bigmonika/WindowLight', -220, -110, 1, 1);
					windowlight.visible = false;
					windowlight.setGraphicSize(Std.int(windowlight.width * 1.3));
					add(windowlight);
				}

				evilClubBGScribbly = new BGSprite('BGsketch', -220, -110, 1, 1, ['BGSketch'], true);
				evilClubBGScribbly.setGraphicSize(Std.int(evilClubBGScribbly.width * 1.3));
				evilClubBGScribbly.visible = false;
				evilClubBGScribbly.alpha = 0.0001;
				add(evilClubBGScribbly);

				evilPoem = new BGSprite('PaperBG', -220, -110, 1, 1, ['PaperBG'], true);
				evilPoem.setGraphicSize(Std.int(evilPoem.width * 1.3));
				evilPoem.visible = false;
				add(evilPoem);

				poemTransition = new BGSprite('PoemTransition', 0, 0, 1, 1, ['poemtransition']);
				poemTransition.cameras = [camHUD];
				poemTransition.screenCenter();
				poemTransition.visible = false;
				add(poemTransition);

			case 'markov':
				if (!ClientPrefs.lowQuality)
				{
					evilSpace = new FlxBackdrop(Paths.image('bigmonika/Sky'));
					evilSpace.scrollFactor.set(0.1, 0.1);
					evilSpace.velocity.set(-10, 0);
					evilSpace.y -= 300;
					evilSpace.antialiasing = ClientPrefs.globalAntialiasing;
					add(evilSpace);

					clouds = new FlxBackdrop(Paths.image('bigmonika/Clouds', 'doki'));
					clouds.scrollFactor.set(0.1, 0.1);
					clouds.velocity.set(-13, 0);
					clouds.y -= 300;
					clouds.antialiasing = ClientPrefs.globalAntialiasing;
					clouds.scale.set(0.7, 0.7);
					add(clouds);

					fancyclouds = new FlxBackdrop(Paths.image('bigmonika/mask', 'doki'));
					fancyclouds.scrollFactor.set(0.1, 0.1);
					fancyclouds.velocity.set(-13, 0);
					fancyclouds.y -= 300;
					fancyclouds.antialiasing = ClientPrefs.globalAntialiasing;
					fancyclouds.scale.set(0.7, 0.7);
					fancyclouds.alpha = 1;
					add(fancyclouds);
				}

				evilClubBG = new BGSprite('bigmonika/BG', -220, -110, 1, 1);
				evilClubBG.setGraphicSize(Std.int(evilClubBG.width * 1.3));
				add(evilClubBG);

				if (!ClientPrefs.lowQuality)
				{
					clubroomdark = new BGSprite('bigmonika/shadow', -220, -110, 1, 1);
					clubroomdark.setGraphicSize(Std.int(clubroomdark.width * 1.3));

					windowlight = new BGSprite('bigmonika/WindowLight', -220, -110, 1, 1);
					windowlight.setGraphicSize(Std.int(windowlight.width * 1.3));
					add(windowlight);
				}

				evilClubBGScribbly = new BGSprite('BGsketch', -220, -110, 1, 1, ['BGSketch'], true);
				evilClubBGScribbly.setGraphicSize(Std.int(evilClubBGScribbly.width * 1.3));
				evilClubBGScribbly.visible = false;
				evilClubBGScribbly.alpha = 0;
				add(evilClubBGScribbly);

				evilPoem = new BGSprite('markovend', -220, -110, 1, 1);
				evilPoem.setGraphicSize(Std.int(evilPoem.width * 1.3));
				evilPoem.visible = false;
				add(evilPoem);

				bloodyBG = new BGSprite('bgBlood', -220, 0, 1, 1, ['bgBlood'], false);
				bloodyBG.animation.addByPrefix('bgBlood', 'bgBlood', 12, false);
				bloodyBG.setGraphicSize(Std.int(bloodyBG.width * 1.3));
				bloodyBG.alpha = 0.001;
				add(bloodyBG);

				closetCloseUp = new BGSprite('ClosetBG', -250, 0, 1, 1);
				closetCloseUp.setGraphicSize(Std.int(closetCloseUp.width * 0.85));
				closetCloseUp.updateHitbox();
				closetCloseUp.visible = false;
				add(closetCloseUp);

				funnyEyes = new BGSprite('EyeMidwayBG', 0, 0, 1, 1, ['Midway'], true);
				funnyEyes.antialiasing = ClientPrefs.globalAntialiasing;
				funnyEyes.alpha = 0.0001;
				funnyEyes.cameras = [camHUD];
				funnyEyes.setGraphicSize(Std.int(FlxG.width));
				funnyEyes.updateHitbox();
				funnyEyes.screenCenter();
				add(funnyEyes);
				addCharacterToList('gameover-markov', 0); //Not a thingie
			case 'home':
				swagShader = new ColorSwap();
				swagShader.saturation = -100;

				stageStatic = new BGSprite('ruinedclub/HomeStatic', 0, 0, 0, 0, ['HomeStatic'], true);
				stageStatic.screenCenter();
				stageStatic.y = -140;
				stageStatic.visible = false;
				add(stageStatic);

				if (!ClientPrefs.lowQuality)
				{
					bgwindo = new FlxBackdrop(Paths.image('ruinedclub/bgwindows2'));
					bgwindo.velocity.set(-40, 0);
					bgwindo.scrollFactor.set(0.5, 0.5);
					bgwindo.antialiasing = ClientPrefs.globalAntialiasing;
					add(bgwindo);

					bgwindo2 = new FlxBackdrop(Paths.image('ruinedclub/bgwindows'));
					bgwindo2.velocity.set(-60, 0);
					bgwindo2.scrollFactor.set(0.8, 0.8);
					bgwindo2.antialiasing = ClientPrefs.globalAntialiasing;
					add(bgwindo2);

					evilSpace = new FlxBackdrop(Paths.image('bigmonika/Sky'));
					evilSpace.scrollFactor.set(0.1, 0.1);
					evilSpace.velocity.set(-10, 0);
					evilSpace.y -= 300;
					evilSpace.antialiasing = ClientPrefs.globalAntialiasing;
					add(evilSpace);

					clouds = new FlxBackdrop(Paths.image('bigmonika/Clouds', 'doki'));
					clouds.scrollFactor.set(0.1, 0.1);
					clouds.velocity.set(-13, 0);
					clouds.y -= 300;
					clouds.antialiasing = ClientPrefs.globalAntialiasing;
					clouds.scale.set(0.7, 0.7);
					add(clouds);

					fancyclouds = new FlxBackdrop(Paths.image('bigmonika/mask', 'doki'));
					fancyclouds.scrollFactor.set(0.1, 0.1);
					fancyclouds.velocity.set(-13, 0);
					fancyclouds.y -= 300;
					fancyclouds.antialiasing = ClientPrefs.globalAntialiasing;
					fancyclouds.scale.set(0.7, 0.7);
					fancyclouds.alpha = 1;
					add(fancyclouds);
				}

				bakaOverlay = new BGSprite('BakaBGDoodles', 0, 0, 1, 1, ['Normal Overlay'], true);
				bakaOverlay.animation.addByPrefix('hueh', 'HOME Overlay', 24, false);
				bakaOverlay.antialiasing = ClientPrefs.globalAntialiasing;
				bakaOverlay.visible = true;
				bakaOverlay.alpha = 0.0001;
				bakaOverlay.cameras = [camHUD];
				bakaOverlay.setGraphicSize(Std.int(FlxG.width));
				bakaOverlay.updateHitbox();
				bakaOverlay.screenCenter();
				add(bakaOverlay);

				inthenotepad = new BGSprite('notepad', 0, 0, 1, 1);
				inthenotepad.visible = false;
				add(inthenotepad);

				notepadoverlay = new BGSprite('notepad_overlay', 0, 0, 1, 1);
				notepadoverlay.visible = false;

				closet = new BGSprite('clubroom/DDLCfarbg', -700, -520, 0.9, 0.9);
				closet.setGraphicSize(Std.int(closet.width * 1.6));
				closet.updateHitbox();
				closet.shader = swagShader.shader;
				add(closet);

				clubroom = new BGSprite('clubroom/DDLCbg', -700, -520, 1, 0.9);
				clubroom.setGraphicSize(Std.int(clubroom.width * 1.6));
				clubroom.updateHitbox();
				clubroom.shader = swagShader.shader;
				add(clubroom);

				evilClubBG = new BGSprite('bigmonika/BG', -220, -110, 1, 1);
				evilClubBG.setGraphicSize(Std.int(evilClubBG.width * 1.3));
				evilClubBG.visible = false;
				add(evilClubBG);

				if (!ClientPrefs.lowQuality)
				{
					clubroomdark = new BGSprite('bigmonika/shadow', -220, -110, 1, 1);
					clubroomdark.setGraphicSize(Std.int(clubroomdark.width * 1.3));
					clubroomdark.visible = false;

					windowlight = new BGSprite('bigmonika/WindowLight', -220, -110, 1, 1);
					windowlight.setGraphicSize(Std.int(windowlight.width * 1.3));
					windowlight.visible = false;
					add(windowlight);
				}

				evilPoem = new BGSprite('PaperBG', -220, -110, 1, 1, ['PaperBG'], true);
				evilPoem.setGraphicSize(Std.int(evilPoem.width * 1.3));
				evilPoem.visible = false;
				add(evilPoem);

				glitchback = new BGSprite('ruinedclub/glitchback1', -220, -110, 0.6, 1);
				glitchback.setGraphicSize(Std.int(glitchback.width * 1.3));
				glitchback.visible = false;
				add(glitchback);

				ruinedClubBG = new BGSprite('ruinedclub/BG', -220, -110, 1, 1);
				ruinedClubBG.setGraphicSize(Std.int(ruinedClubBG.width * 1.3));
				ruinedClubBG.visible = false;
				add(ruinedClubBG);

				glitchfront = new BGSprite('ruinedclub/glitchfront1', -220, -110, 1.2, 1);
				glitchfront.setGraphicSize(Std.int(glitchfront.width * 1.3));
				glitchfront.visible = false;

				evilClubBGScribbly = new BGSprite('BGsketch', -220, -110, 1, 1, ['BGSketch'], true);
				evilClubBGScribbly.setGraphicSize(Std.int(evilClubBGScribbly.width * 1.3));
				evilClubBGScribbly.visible = false;
				evilClubBGScribbly.alpha = 0;
				add(evilClubBGScribbly);
				

				if (!ClientPrefs.lowQuality)
				{
					deskfront = new BGSprite('clubroom/DesksFront', -700, -520, 1.3, 0.9);
					deskfront.setGraphicSize(Std.int(deskfront.width * 1.6));
					deskfront.updateHitbox();
					deskfront.shader = swagShader.shader;
				}

		}

		// shaders right here lol
		// funny static for all stages
		if (ClientPrefs.shaders)
		{
			staticlol = new StaticShader();
			camGame.filters = [new ShaderFilter(staticlol)];
			camCache.filters = [new ShaderFilter(staticlol)];
			staticlol.alpha.value = [staticAlpha];
		}

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		extra1 = new Character(-150, 70, 'sil_sayori');
		extra1.scrollFactor.set(0.95, 0.95);
		extra1.alpha = 0.0001;
		extra1.color = FlxColor.GRAY;
		add(extra1);

		extra2 = new Character(1050, 10, 'sil_yuri', true, true);
		extra2.scrollFactor.set(0.95, 0.95);
		extra2.alpha = 0.0001;
		extra2.color = FlxColor.GRAY;
		add(extra2);

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		switch (curStage)
		{
			case 'home':
				if (!ClientPrefs.lowQuality)
				{
					add(clubroomdark);
				}
				add(notepadoverlay);
				add(glitchfront);
			case 'stagnant' | 'markov':
				if (!ClientPrefs.lowQuality) add(clubroomdark);
		}

		//stealing this from DDTO
		vignette = new FlxSprite(0, 0).loadGraphic(Paths.image('vignette', 'doki'));
		vignette.scrollFactor.set();
		vignette.cameras = [camHUD];
		vignette.alpha = 0.00001;
		add(vignette);

		screenPulse = new BGSprite('vignetteend', 0, 0, 1, 1);
		screenPulse.cameras = [camHUD];
		screenPulse.setGraphicSize(FlxG.width, FlxG.height);
		screenPulse.screenCenter();
		screenPulse.alpha = 0.0001;
		add(screenPulse);

		daStatic = new BGSprite('daSTAT', 0, 0, 1.0, 1.0, ['staticFLASH'], true);
		daStatic.cameras = [camHUD];	
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.alpha = 0.0001;
		add(daStatic);

		redStatic = new BGSprite('ruinedclub/HomeStatic', 0, 0, 1, 1, ['HomeStatic'], true);
		redStatic.cameras = [camHUD];
		redStatic.setGraphicSize(FlxG.width, FlxG.height);
		redStatic.screenCenter();
		redStatic.alpha = 0.0001;
		add(redStatic);

		cambgwindo = new FlxBackdrop(Paths.image('ruinedclub/bgwindows2'));
		cambgwindo.velocity.set(-40, 0);
		cambgwindo.antialiasing = ClientPrefs.globalAntialiasing;
		cambgwindo.alpha = 0.0001;
		add(cambgwindo);

		cambgwindo2 = new FlxBackdrop(Paths.image('ruinedclub/bgwindows'));
		cambgwindo2.velocity.set(-60, 0);
		cambgwindo2.antialiasing = ClientPrefs.globalAntialiasing;
		cambgwindo2.alpha = 0.0001;
		add(cambgwindo2);

		stagstatic = new BGSprite('stagnant_glitch', 0, 0, 1.0, 1.0, ['sadface 2'], false);
		stagstatic.cameras = [camHUD];
		stagstatic.setGraphicSize(FlxG.width, FlxG.height);
		stagstatic.screenCenter();
		stagstatic.alpha = 0.0001;
		add(stagstatic);

		// just incase
		precacheList.set('stagnant_glitch', 'image');

		holylight = new BGSprite('deadlight', 0, 0, 1, 1);
		holylight.cameras = [camHUD];
		holylight.setGraphicSize(FlxG.width, FlxG.height);
		holylight.screenCenter();
		holylight.alpha = 0.0001;
		add(holylight);


		trace(boyfriendGroup);
		trace(dadGroup);
		trace(gfGroup);

		if (deskfront != null && !ClientPrefs.lowQuality)
			add(deskfront);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		gf = new Character(0, 0, gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterLua(gf.curCharacter);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);


		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
		}

		darkoverlay = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		darkoverlay.alpha = 0.0001;
		darkoverlay.scrollFactor.set(0, 0);
		add(darkoverlay);

		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 150;

		grpUnderlay = new FlxTypedGroup<FlxSprite>();
		add(grpUnderlay);

		bloodStrums = new FlxTypedGroup<FlxSprite>();
		add(bloodStrums);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var showTime:Bool = ClientPrefs.timeBarType != 'Disabled';

		timeTxt = new FlxText(0, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("Aller_Rg.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.screenCenter(X);
		timeTxt.antialiasing = ClientPrefs.globalAntialiasing;
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;

		if (ClientPrefs.downScroll)
			timeTxt.y = FlxG.height - 44;

		if (ClientPrefs.timeBarType == 'Song Name')
			timeTxt.text = SONG.song;

		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		if (ClientPrefs.timeBarType == 'Song Name' || ClientPrefs.timeBarType == 'Combined')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("Aller_Rg.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.antialiasing = ClientPrefs.globalAntialiasing;
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(0, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("riffic.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.antialiasing = ClientPrefs.globalAntialiasing;
		botplayTxt.screenCenter(X);
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if (ClientPrefs.downScroll)
		{
			botplayTxt.y = timeBarBG.y - 78;
		}

		grpUnderlay.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		bloodStrums.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);

		switch (daSong)
		{
			case 'stagnant' | 'markov' | 'home': //This is for the dark start thing
				imdead = new FlxSprite(0, 0).loadGraphic(Paths.image('everyoneisdead', 'doki'));
				imdead.scrollFactor.set();
				imdead.cameras = [camHUD];
				imdead.alpha = 0.00001;
				add(imdead);

				darkScreen = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				add(darkScreen);
				darkScreen.cameras = [camHUD];

				titleCard = new FlxSprite();
				titleCard.frames = Paths.getSparrowAtlas('titlecards/${daSong}', 'doki'); // curSong
				titleCard.animation.addByPrefix('idle', 'card', 24, true);
				titleCard.animation.play('idle');
				titleCard.antialiasing = ClientPrefs.globalAntialiasing;
				titleCard.cameras = [camOther];
				titleCard.screenCenter();
				titleCard.alpha = 0.001;
				titleCard.scale.set(0.8,0.8);
				add(titleCard);
		}

		
		if (isStoryMode && !seenCutscene)
		{
			seenCutscene = true;
			switch (daSong)
			{
				case 'stagnant':
					startVideo('intro');
				default:
					startCountdown();
			}
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0)
			precacheList.set('hitsound', 'sound');

		for (i in 1...4)
			precacheList.set('missnote$i', 'sound');

		precacheList.set('alphabet', 'image');

		// Bad Ending specific caching
		precacheList.set('ghost', 'music');
		precacheList.set('MARKOVNOTE_assets', 'image');
		precacheList.set('NOTE_splashes_doki', 'image');
		precacheList.set('poemUI/NOTE_assets', 'image');
		precacheList.set('poemUI/NOTE_assets', 'image');
		precacheList.set('poemUI/MARKOVNOTE_assets', 'image');
		precacheList.set('stab', 'sound');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter());
		#end

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		super.create();

		cachePopUpScore();

		for (key => type in precacheList)
		{
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		Paths.clearUnusedMemory();
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		return value;
	}

	public function addTextToDebug(text:String)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34)
		{
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarGraphic(?prefix:String = '', ?suffix:String = '', ?offsetX:Float = 0, ?offsetY:Float = 0)
	{
		var path:String = prefix + 'healthBar' + suffix;
		var gamePath:String = Paths.getPath('images/$path.png', IMAGE);

		if (#if MODS_ALLOWED !FileSystem.exists(Paths.modsImages(path)) && #end !OpenFlAssets.exists(gamePath, IMAGE))
			path = 'healthBar';

		var xmlPath:String = 'images/' + path + '.xml';
		var modpath = '';
		var isAnimated = false;
		#if MODS_ALLOWED
		modpath = Paths.modFolders(xmlPath);
		if (!FileSystem.exists(path))
			modpath = Paths.getPreloadPath(xmlPath);
		if (FileSystem.exists(modpath))
			isAnimated = true;
		#else
		modpath = Paths.getPreloadPath(xmlPath);
		if (Assets.exists(modpath))
			isAnimated = true;
		#end

		if (isAnimated)
		{
			healthBarBG.frames = Paths.getSparrowAtlas(path);
			healthBarBG.animation.addByPrefix('idle', 'healthBar', 24, true);
			healthBarBG.animation.play('idle');
		}
		else
			healthBarBG.loadGraphic(Paths.image(path));

		healthBarBG.offset.set(offsetX, offsetY);
	}

	public function reloadHealthBarColors()
	{
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function reloadTimeBarGraphic(?prefix:String = '', ?suffix:String = '', ?offsetX:Float = 0, ?offsetY:Float = 0)
	{
		var path:String = prefix + 'timeBar' + suffix;
		var gamePath:String = Paths.getPath('images/$path.png', IMAGE);

		if (#if MODS_ALLOWED !FileSystem.exists(Paths.modsImages(path)) && #end !OpenFlAssets.exists(gamePath, IMAGE))
			path = 'timeBar';

		var xmlPath:String = 'images/' + path + '.xml';
		var modpath = '';
		var isAnimated = false;
		#if MODS_ALLOWED
		modpath = Paths.modFolders(xmlPath);
		if (!FileSystem.exists(path))
			modpath = Paths.getPreloadPath(xmlPath);
		if (FileSystem.exists(modpath))
			isAnimated = true;
		#else
		modpath = Paths.getPreloadPath(xmlPath);
		if (Assets.exists(modpath))
			isAnimated = true;
		#end

		if (isAnimated)
		{
			timeBarBG.frames = Paths.getSparrowAtlas(path);
			timeBarBG.animation.addByPrefix('idle', 'timeBar', 24, true);
			timeBarBG.animation.play('idle');
		}
		else
			timeBarBG.loadGraphic(Paths.image(path));

		timeBarBG.offset.set(offsetX, offsetY);
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					trace(newCharacter);
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);

					if (newBoyfriend.gameoverchara != null && boyfriend.gameoverchara != '' && !boyfriendMap.exists(newBoyfriend.gameoverchara))
						addCharacterToList(newBoyfriend.gameoverchara, 0);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (doPush)
		{
			for (lua in luaArray)
			{
				if (lua.scriptName == luaFile)
					return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void
	{
	#if VIDEOS_ALLOWED
	var foundFile:Bool = false;
	var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
	#if sys
	if (FileSystem.exists(fileName))
	{
		foundFile = true;
	}
	#end

	if (!foundFile)
	{
		fileName = Paths.video(name);
		#if sys
		if (FileSystem.exists(fileName))
		{
		#else
		if (OpenFlAssets.exists(fileName))
		{
		#end
			foundFile = true;
		}
		} if (foundFile)
		{
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function()
			{
				remove(bg);
				if (endingSong)
				{
					endSong();
				}
				else
				{
					startCountdown();
				}
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
		}
		#end
		if (endingSong)
		{
			endSong();
		}
		else
		{
			startCountdown();
		}
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();
			if (endingSong)
			{
				doof.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				doof.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras = [camHUD];
			add(doof);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if (ret != FunkinLua.Function_Stop)
		{
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				// if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}
			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (tmr.loopsLeft % gfSpeed == 0
					&& !gf.stunned
					&& gf.animation.curAnim.name != null
					&& !gf.animation.curAnim.name.startsWith("sing"))
				{
					gf.dance();
				}
				if (tmr.loopsLeft % 2 == 0)
				{
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
					{
						boyfriend.dance();
					}
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance();
					}
				}
				else if (dad.danceIdle
					&& dad.animation.curAnim != null
					&& !dad.stunned
					&& !dad.curCharacter.startsWith('gf')
					&& !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();

				switch (Paths.formatToSongPath(curSong))
				{
					case 'stagnant' | 'home' | 'markov':
						introSoundsSuffix = '-ddto';
						introAssets.set('default', ['blank', 'blank', 'blank']);
					default:
						introAssets.set('default', ['ready', 'set', 'go']);
				}
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if (isPixelStage)
				{
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				switch (swagCounter)
				{
					case 0:
						if (titleCard != null)
						{
							FlxTween.tween(titleCard, {alpha: 1, 'scale.x': 1, 'scale.y': 1}, 3, {
								ease: FlxEase.cubeOut,
								onComplete: function(twn:FlxTween)
								{
									FlxTween.tween(titleCard, {alpha: 0}, 2, {
										ease: FlxEase.cubeOut,
										startDelay: 1,
										onComplete: function(twn:FlxTween)
										{
											remove(titleCard);
											titleCard.destroy();
										}
									});
								}
							});
						}
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);

						// disable filters on the caching camera
						camCache.filtersEnabled = false;
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note)
				{
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if (ClientPrefs.middleScroll && !note.mustPress)
					{
						note.alpha *= 0.5;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function startNextDialogue()
	{
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue()
	{
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2], event[1][i][3]];
					var subEvent:Array<Dynamic> = [
						newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote),
						newEventNote[1],
						newEventNote[2],
						newEventNote[3],
						newEventNote[4]
					];
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var noteStyle:String = isPixelStage ? 'pixel' : '';

				if (section.noteStyle != '' || section.noteStyle != null)
					noteStyle = section.noteStyle;

				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}
				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, noteStyle);

				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				var floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime
							+ (Conductor.stepCrochet * susNote)
							+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote,
							true, false, noteStyle);

						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1)
							{ // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2], event[1][i][3]];
				var subEvent:Array<Dynamic> = [
					newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote),
					newEventNote[1],
					newEventNote[2],
					newEventNote[3],
					newEventNote[4]
				];
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;
		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>)
	{
		switch (event[1])
		{
			case 'Change Character':
				var charType:Int = 0;
				switch (event[2].toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event[2]);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event[3];
				addCharacterToList(newCharacter, charType);

			case 'Change Combo UI':
				cachePopUpScore(event[2], event[3]);

			case 'Change Health Graphic':
				if (event[2].length > 0)
				{
					var split:Array<String> = event[2].split(',');
					Paths.image(split[0].trim() + 'healthBar' + split[1].trim());
				}

			case 'Change Time Graphic':
				if (event[2].length > 0)
				{
					var split:Array<String> = event[2].split(',');
					Paths.image(split[0].trim() + 'timeBar' + split[1].trim());
				}

			case 'Eye Popup':
				Paths.image('MarkovEyes', 'doki');

			case 'Play SFX':
				Paths.sound(event[2]);

			case 'Glitch Effect':
				if (event[3].length > 0)
					Paths.sound(event[3]);
		}

		if (!eventPushedMap.exists(event[1]))
			eventPushedMap.set(event[1], true);
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float
	{
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[1]]);
		if (returnedValue != 0)
		{
			return returnedValue;
		}

		switch (event[1])
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function generateStaticArrows(player:Int, ?noteStyle:String, ?tween:Bool = true):Void
	{
		if (noteStyle == '' || noteStyle == null)
		{
			if (isPixelStage)
				noteStyle = 'pixel';
		}

		if (ClientPrefs.noteUnderlay > 0)
		{
			if (!ClientPrefs.middleScroll)
			{
				if (player >= 0)
				{
					var underlay = new FlxSprite(70 + ((FlxG.width / 2) * player), 0).makeGraphic(500, FlxG.height, FlxColor.BLACK);
					underlay.alpha = ClientPrefs.noteUnderlay;
					underlay.screenCenter(Y);
					underlay.ID = player;
					grpUnderlay.add(underlay);
				}
			}
			else
			{
				if (player == 1)
				{
					var underlay = new FlxSprite(0, 0).makeGraphic(500, FlxG.height, FlxColor.BLACK);
					underlay.alpha = ClientPrefs.noteUnderlay;
					underlay.screenCenter();
					underlay.ID = 1;
					grpUnderlay.add(underlay);
				}
			}
		}

		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll)
				targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player, noteStyle);
			if (!isStoryMode && tween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if (ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();

			if (player == 0)
			{
				//Create blood stuff here
				var offsetx:Float = babyArrow.x + -270;
				var offsety:Float = babyArrow.y + -25;

				var blood:FlxSprite = new FlxSprite(offsetx, offsety);
				blood.frames = Paths.getSparrowAtlas('blooddrip', 'preload');
				blood.antialiasing = ClientPrefs.globalAntialiasing;
				blood.animation.addByPrefix('idle', 'gone', 24, false);
				blood.animation.addByPrefix('drip', 'blood', 24, false);
				blood.animation.play('idle');
				blood.scale.set(1.3, 1.3);
				blood.alpha = targetAlpha;
				blood.ID = i; 
				bloodStrums.add(blood);
			}
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
				{
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = false;
			}
			for (timer in modchartTimers)
			{
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				FlxG.sound.music.time = Conductor.songPosition;
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
				{
					chars[i].colorTween.active = true;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = true;
			}
			for (timer in modchartTimers)
			{
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song, iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused && FlxG.autoPause)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song, iconP2.getCharacter());
		}
		#end

		if (!FlxG.autoPause && !paused && canPause && startedCountdown && !cpuControlled && !inCutscene)
		{
			pauseState();
		}

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();
		FlxG.sound.music.play();

		if (FlxG.sound.music.time <= vocals.length)
			vocals.time = FlxG.sound.music.time;

		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var prevMusicTime:Float = 0;
	var iTime:Float = 0;
	#if debug
	var debugScale:Float = 1.0;
	#end

	override public function update(elapsed:Float)
	{
		if (staticlol != null && ClientPrefs.shaders && camGame.filtersEnabled)
		{
			iTime += elapsed;
			staticlol.alpha.value = [staticAlpha];
			staticlol.iTime.value = [iTime];
		}

		#if debug
		if (FlxG.keys.pressed.CONTROL
			&& (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L || FlxG.keys.pressed.U))
		{
			isCameraOnForcedPos = !FlxG.keys.pressed.U;

			if (FlxG.keys.pressed.I)
			{
				if (FlxG.keys.pressed.SHIFT)
					camFollow.y += -50;
				else
					camFollow.y += -10;
			}
			else if (FlxG.keys.pressed.K)
			{
				if (FlxG.keys.pressed.SHIFT)
					camFollow.y += 50;
				else
					camFollow.y += 10;
			}

			if (FlxG.keys.pressed.J)
			{
				if (FlxG.keys.pressed.SHIFT)
					camFollow.x += -50;
				else
					camFollow.x += -10;
			}
			else if (FlxG.keys.pressed.L)
			{
				if (FlxG.keys.pressed.SHIFT)
					camFollow.x += 50;
				else
					camFollow.x += 10;
			}
		}

		FlxG.watch.addQuick("camFollow", [camFollow.x, camFollow.y]);
		#end

		if (startedCountdown && !paused)
		{
			if (FlxG.sound.music.time == prevMusicTime || startingSong)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
			}
			else
			{
				Conductor.songPosition = FlxG.sound.music.time;
				prevMusicTime = Conductor.songPosition;
			}
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if (ClientPrefs.timeBarType == 'Time Elapsed')
				songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if (secondsTotal < 0) secondsTotal = 0;

			if (ClientPrefs.timeBarType.startsWith('Time'))
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);

			if (ClientPrefs.timeBarType == 'Combined')
				timeTxt.text = '${SONG.song} (${FlxStringUtil.formatTime(secondsTotal, false)})';
		}

		callOnLuas('onUpdate', [elapsed]);

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if (!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if (!ClientPrefs.lowQuality && fancyclouds != null && fancyclouds.visible)//if one is visible all of them are anyway
		{
			floatshit += 0.007 / FramerateTools.timeMultiplier();
			fancyclouds.alpha += Math.sin(floatshit) / FramerateTools.timeMultiplier() / 5;
			clubroomdark.alpha -= Math.sin(floatshit) / FramerateTools.timeMultiplier() / 5;
			windowlight.alpha += Math.sin(floatshit) / FramerateTools.timeMultiplier() / 5;
		}

		if (ratingName == '?')
		{
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
		}
		else
		{
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' ('
				+ Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC; // peeps wanted no integer rating
		}

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			pauseState();
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene && ClientPrefs.storycomplete)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			+ (150 * iconP1.scale.x - 150) / 2
			- iconOffset;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (150 * iconP2.scale.x) / 2
			- iconOffset * 2;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.updateIconAnim(true);
		else
			iconP1.updateIconAnim(false);

		if (healthBar.percent > 80)
			iconP2.updateIconAnim(true);
		else
			iconP2.updateIconAnim(false);

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene && ClientPrefs.storycomplete)
		{
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(songSpeed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if (roundedSpeed < 1)
				time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				/* 				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
			}*/

				// i am so fucking sorry for this if condition
				var strumX:Float = 0;
				var strumY:Float = 0;
				var strumAngle:Float = 0;
				var strumAlpha:Float = 0;
				if (daNote.mustPress)
				{
					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
					strumAngle = playerStrums.members[daNote.noteData].angle;
					strumAlpha = playerStrums.members[daNote.noteData].alpha;
				}
				else
				{
					strumX = opponentStrums.members[daNote.noteData].x;
					strumY = opponentStrums.members[daNote.noteData].y;
					strumAngle = opponentStrums.members[daNote.noteData].angle;
					strumAlpha = opponentStrums.members[daNote.noteData].alpha;
				}

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				var center:Float = strumY + Note.swagWidth / 2;

				if (!endingSong && !isCameraOnForcedPos)
					moveCameraSection(Std.int(curStep / 16));

				if (daNote.copyX)
				{
					daNote.x = strumX;
				}
				if (daNote.copyAngle)
				{
					daNote.angle = strumAngle;
				}
				if (daNote.copyAlpha)
				{
					daNote.alpha = strumAlpha;
				}
				if (daNote.copyY)
				{
					if (ClientPrefs.downScroll)
					{
						daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
						if (daNote.isSustainNote && !ClientPrefs.keSustains)
						{
							// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if (daNote.animation.curAnim.name.endsWith('end'))
							{
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
								if (daNote.noteStyle == 'pixel')
								{
									daNote.y += 8;
								}
								else
								{
									daNote.y -= 19;
								}
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

							if (daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
									swagRect.height = (center - daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
						}
					}
					else
					{
						daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

						if (!ClientPrefs.keSustains)
						{
							if (daNote.mustPress || !daNote.ignoreNote)
							{
								if (daNote.isSustainNote
									&& daNote.y + daNote.offset.y * daNote.scale.y <= center
									&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
								{
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (center - daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if (daNote.mustPress && cpuControlled)
				{
					if (daNote.isSustainNote)
					{
						if (daNote.canBeHit)
						{
							goodNoteHit(daNote);
						}
					}
					else if (daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress))
					{
						goodNoteHit(daNote);
					}
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * songSpeed));

				var doKill:Bool = daNote.y < -daNote.height;
				if (ClientPrefs.downScroll)
					doKill = daNote.y > FlxG.height;

				if (ClientPrefs.keSustains && daNote.isSustainNote && daNote.wasGoodHit)
					doKill = true;

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
					{
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		if (!inCutscene)
		{
			if (!cpuControlled)
			{
				keyShit();
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}
		}

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime + 800 < Conductor.songPosition)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length)
				{
					var daNote:Note = unspawnNotes[0];
					if (daNote.strumTime + 800 >= Conductor.songPosition)
					{
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		CustomFadeTransition.nextCamera = camOther;
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	function pauseState()
	{
		var ret:Dynamic = callOnLuas('onPause', []);

		if (ret != FunkinLua.Function_Stop)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				cancelMusicFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				MusicBeatState.switchState(new GitarooPause());
			}
			else
			{
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.pause();
					vocals.pause();
				}

				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}

			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song, iconP2.getCharacter());
			#end
		}
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if (ret != FunkinLua.Function_Stop)
			{
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens)
				{
					tween.active = true;
				}
				for (timer in modchartTimers)
				{
					timer.active = true;
				}
				if (boyfriend.gameoverchara != null && boyfriend.gameoverchara != '')
					GameOverSubstate.characterName = boyfriend.gameoverchara;
				if (boyfriend.deathsound != null && boyfriend.gameoverchara != '')
					GameOverSubstate.deathSoundName = boyfriend.deathsound;
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
					boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song, iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0][0];
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			var value1:String = '';
			if (eventNotes[0][2] != null)
				value1 = eventNotes[0][2];

			var value2:String = '';
			if (eventNotes[0][3] != null)
				value2 = eventNotes[0][3];

			var value3:String = '';
			if (eventNotes[0][4] != null)
				value3 = eventNotes[0][4];

			triggerEventNote(eventNotes[0][1], value1, value2, value3);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, value3:String)
	{
		switch (eventName)
		{
			case 'remove darkScreen':
				if (darkScreen != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);

					if (Math.isNaN(val1) || val1 == 0)
					{
						val1 = 0.0001;
					}
					if (Math.isNaN(val2) || val2 == 0)
					{
						val2 = 0.0001;
					}
					
					if (val1 != 0)
					{
						FlxTween.tween(darkScreen, {alpha: val2}, val1, {ease: FlxEase.linear});
					}
				}
			case 'Screen in Darkness':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1) || val1 == 0)
				{
					val1 = 0.0001;
				}
				if (Math.isNaN(val2) || val2 == 0)
				{
					val2 = 0.0001;
				}
				if (val1 >= 1)
				{
					val1 = 1;
				}
				FlxTween.cancelTweensOf(darkoverlay);
				FlxTween.tween(darkoverlay, {alpha: val1}, val2, {ease: FlxEase.linear});

			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (value1)
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							boyfriend.dance(false);
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf)
								{
									gf.visible = true;
								}
							}
							else
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							dad.dance(false);
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if (gf.curCharacter != value2)
						{
							if (!gfMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = gf.alpha;
							gf.alpha = 0.00001;
							gf = gfMap.get(value2);
							gf.alpha = lastAlpha;
							gf.dance(false);
						}
						setOnLuas('gfName', gf.curCharacter);
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;

				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Change Combo UI':
				pixelShitPart1 = value1;
				pixelShitPart2 = value2;

			case 'Change Health Graphic':
				var stringArray:Array<String> = value1.trim().split(',');
				var offsetArray:Array<String> = value2.trim().split(',');
				if (value2 == '') offsetArray = ['0', '0'];

				reloadHealthBarGraphic(stringArray[0], stringArray[1], Std.parseFloat(offsetArray[0]), Std.parseFloat(offsetArray[1]));
			
			case 'Change Time Graphic':
				var stringArray:Array<String> = value1.trim().split(',');
				var offsetArray:Array<String> = value2.trim().split(',');
				if (value2 == '') offsetArray = ['0', '0'];

				reloadTimeBarGraphic(stringArray[0], stringArray[1], Std.parseFloat(offsetArray[0]), Std.parseFloat(offsetArray[1]));

			case 'Change HUD Font':
				switch (value1)
				{
					default: // ddto
						timeTxt.font = Paths.font("Aller_Rg.ttf");
						scoreTxt.font = Paths.font("Aller_Rg.ttf");
						botplayTxt.font = Paths.font("riffic.ttf");

						scoreTxt.borderSize = 1.25;
						botplayTxt.borderSize = 1.25;

					case 'fnf':
						timeTxt.font = Paths.font("vcr.ttf");
						scoreTxt.font = Paths.font("vcr.ttf");
						botplayTxt.font = Paths.font("vcr.ttf");

						scoreTxt.borderSize = 1.25;
						botplayTxt.borderSize = 1.25;

					case 'poem':
						timeTxt.font = Paths.font("VTKS_ANIMAL_2.ttf");
						scoreTxt.font = Paths.font("VTKS_ANIMAL_2.ttf");
						botplayTxt.font = Paths.font("VTKS_ANIMAL_2.ttf");

						scoreTxt.borderSize = 2;
						botplayTxt.borderSize = 2;
				}

			case 'Change Stagnant Stage':
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val2))
					val2 = 0;

				defaultCamZoom = defaultStageZoom;
				FlxG.camera.zoom = defaultStageZoom;
				
				//Considering all songs this should be shared
				evilClubBG.visible = false;
				evilClubBGScribbly.visible = false;
				evilPoem.visible = false;
				
				isCameraOnForcedPos = false;

				switch (curStage)//per stage stuff
				{
					case 'home':
						if (!ClientPrefs.lowQuality)
						{
							deskfront.visible = false;
							evilSpace.visible = false;
							clouds.visible = false;
							fancyclouds.visible = false;
							windowlight.visible = false;
							clubroomdark.visible = false;
							bgwindo.visible = false;
							bgwindo2.visible = false;
						}
						stageStatic.visible = false;
						ruinedClubBG.visible = false;
						glitchfront.visible = false;
						glitchback.visible = false;
						closet.visible = false;
						clubroom.visible = false;
						inthenotepad.visible = false;
						notepadoverlay.visible = false;
						boyfriendGroup.x = BF_X;
						boyfriendGroup.y = BF_Y;
					case 'markov':
						closetCloseUp.visible = false;
						GameOverSubstate.markovGameover = false;
					case 'stagnant':
						if (!ClientPrefs.lowQuality)
						{
							deskfront.visible = false;
							evilSpace.visible = false;
							clouds.visible = false;
							fancyclouds.visible = false;
							windowlight.visible = false;
							clubroomdark.visible = false;
						}
						closet.visible = false;
						clubroom.visible = false;
				}
				
				evilClubBGScribbly.alpha = 0.0001;

				switch (value1)
				{
					default:
						closet.visible = true;
						clubroom.visible = true;
						if (!ClientPrefs.lowQuality) deskfront.visible = true;
					case 'evil':
						defaultCamZoom = 0.8;
						FlxG.camera.zoom = 0.8;
						if (!ClientPrefs.lowQuality)
						{
							evilSpace.visible = true;
							clouds.visible = true;
							fancyclouds.visible = true;
							windowlight.visible = true;
							clubroomdark.visible = true;
						}
						evilClubBG.visible = true;
						evilClubBGScribbly.visible = true;
					case 'poem':
						defaultCamZoom = 0.9;
						FlxG.camera.zoom = 0.9;
						evilPoem.visible = true;
					case 'markovpoem':
						defaultCamZoom = 0.9;
						FlxG.camera.zoom = 0.9;
						evilPoem.visible = true;
						bloodyBG.alpha = 1;
						bloodyBG.animation.play('bgBlood');
						screenPulse.alpha = 1;
						funnyEyes.setGraphicSize(Std.int(bloodyBG.width * 1.3));
						funnyEyes.cameras = [camGame];
						funnyEyes.alpha = 1;
						GameOverSubstate.markovGameover = true;
					case 'closet':
						defaultCamZoom = 1.0;
						FlxG.camera.zoom = 1.0;
						closetCloseUp.visible = true;
						GameOverSubstate.markovGameover = true;
					case 'ruined' | 'ruinedclub':
						defaultCamZoom = 0.8;
						FlxG.camera.zoom = 0.8;
						stageStatic.visible = true;
						if (!ClientPrefs.lowQuality)
						{
							bgwindo.visible = true;
							bgwindo2.visible = true;
						}
						ruinedClubBG.visible = true;
						glitchfront.visible = true;
						glitchback.visible = true;
					case 'notepad':
						//fates are written, cause pandora didn't listen, time will march here with me, the screams of last you'll ever see
						//I will kill you, I am marty the armidillou,the stinky smells won't deter me, I will drink all your pee
						defaultCamZoom = 1.0;
						FlxG.camera.zoom = 1.0;
						//We are going to lock the camera for this event
						stageStatic.visible = true;
						if (!ClientPrefs.lowQuality)
						{
							bgwindo.visible = true;
							bgwindo2.visible = true;
						}
						inthenotepad.visible = true;
						notepadoverlay.visible = true;
						isCameraOnForcedPos = true;
						camFollow.set(650, 360);
						camFollowPos.setPosition(650, 360);
						boyfriendGroup.x = 430;
						boyfriendGroup.y = -140;
					case 'void':
						defaultCamZoom = 0.9;
						FlxG.camera.zoom = 0.9;
						//basically don't unhide anything lmao
					case 'redstatic':
						defaultCamZoom = 0.9;
						FlxG.camera.zoom = 0.9;
						stageStatic.visible = true;
				}

				if (val2 > 0)
				{
					FlxTween.tween(evilClubBGScribbly, {alpha: 1}, val2, {
						ease: FlxEase.sineIn,
						onComplete: function(twn:FlxTween)
						{
							evilClubBGScribbly.alpha = 1;
						}
					});
				}
			case 'Glitch Effect':
				var val1:Float = Std.parseFloat(value1);
				if (Math.isNaN(val1))
					val1 = 0.5;

				funnyGlitch(val1, value2);
			case 'Glitch increase':
				switch (Std.parseFloat(value1))
				{
					case 1:
						FlxTween.tween(daStatic, {alpha: 0.65}, 3.5, {ease: FlxEase.circOut});
					case 2:
						FlxTween.cancelTweensOf(daStatic);
						daStatic.visible = false;
					case 3:
						FlxTween.cancelTweensOf(daStatic);
						daStatic.visible = true;
					case 4:
						FlxTween.cancelTweensOf(daStatic);
						remove(daStatic);
				}
			case 'Stagnant Glitch':
				stagstatic.dance();
				stagstatic.alpha = 1;
			case 'Character Visibility':
				var charType:Int = 0;
				var val2:Float = Std.parseFloat(value2);
				var val3:Float = Std.parseFloat(value3);

				if (Math.isNaN(val2))
					val2 = 1;
				else if (val2 == 0)
					val2 = 0.0001;

				if (Math.isNaN(val3) || val3 == 0)
					val3 = 0.0001;

				if (value2 == 'true')
					val2 = 1;
				else if (value2 == 'false')
					val2 = 0.0001;
				
				trace(value1 + ' & ' + value2 + ' & ' + value3);
				switch (value1)
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						FlxTween.cancelTweensOf(boyfriend);
						FlxTween.tween(boyfriend, {alpha: val2}, val3, {ease: FlxEase.circOut});
					case 1:
						FlxTween.cancelTweensOf(dad);
						FlxTween.tween(dad, {alpha: val2}, val3, {ease: FlxEase.circOut});
					case 2:
						FlxTween.cancelTweensOf(gf);
						FlxTween.tween(gf, {alpha: val2}, val3, {ease: FlxEase.circOut});
				}
			case 'Move Character':
				var charType:Int = 0;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				switch (value3)
				{
					case 'dad' | 'Dad' | 'DAD':
						charType = 1;
					case 'gf' | 'GF' | 'girlfriend' | 'Girlfriend':
						charType = 2;
					default:
						charType = 0;
				}

				switch (charType)
				{
					case 1:
						if (Math.isNaN(val1)) dadGroup.x = DAD_X;
						else dadGroup.x = val1;

						if (Math.isNaN(val2)) dadGroup.y = DAD_Y;
						else dadGroup.y = val2;
					case 2:
						if (Math.isNaN(val1)) gfGroup.x = GF_X;
						else gfGroup.x = val1;
						
						if (Math.isNaN(val2)) gfGroup.y = GF_Y;
						else gfGroup.y = val2;
					default:
						if (Math.isNaN(val1)) boyfriendGroup.x = BF_X;
						else boyfriendGroup.x = val1;

						if (Math.isNaN(val2)) boyfriendGroup.y = BF_Y;
						else boyfriendGroup.y = val2;
				}
			case 'Toggle Note Camera Movement':
				if (ClientPrefs.noteCamera > 0)
				{
					var val2:Float = Std.parseFloat(value2);

					switch (value1.toLowerCase().trim())
					{
						case 'true' | '1':
							noteCam = true;
						default:
							noteCam = false;
					}
	
					if (Math.isNaN(val2))
						camNoteExtend = 15 * ClientPrefs.noteCamera;
					else
						camNoteExtend = val2 * ClientPrefs.noteCamera;
				}
			case 'Move Opponent Tween':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				var val3:Float = Std.parseFloat(value3);
			
				if (Math.isNaN(val3) || val3 == 0)
					val3 = 0.0001;

				if (Math.isNaN(val1))
					val1 = DAD_X;
				if (Math.isNaN(val2))
					val2 = DAD_Y;

				FlxTween.cancelTweensOf(dadGroup);
				FlxTween.tween(dadGroup, {x: val1, y: val2}, val3, {ease: FlxEase.circOut});

			case 'Move Boyfriend Tween':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				var val3:Float = Std.parseFloat(value3);

				if (Math.isNaN(val3) || val3 == 0)
					val3 = 0.0001;

				if (Math.isNaN(val1))
					val1 = BF_X;
				if (Math.isNaN(val2))
					val2 = BF_Y;

				FlxTween.cancelTweensOf(boyfriendGroup);
				FlxTween.tween(boyfriendGroup, {x: val1, y: val2}, val3, {ease: FlxEase.circOut});

			case 'Change Strumline':
				if (value1 == '' || value1 == null)
					return;

				var tweenBool:Bool = false;
				if (value2 == 'true')
					tweenBool = true;

				remove(grpUnderlay);
				grpUnderlay = new FlxTypedGroup<FlxSprite>();
				grpUnderlay.cameras = [camHUD];
				add(grpUnderlay);

				remove(strumLineNotes);
				strumLineNotes = new FlxTypedGroup<StrumNote>();
				strumLineNotes.cameras = [camHUD];
				add(strumLineNotes);

				playerStrums = new FlxTypedGroup<StrumNote>();
				opponentStrums = new FlxTypedGroup<StrumNote>();

				generateStaticArrows(0, value1, tweenBool);
				generateStaticArrows(1, value1, tweenBool);
			case 'Change Camera Zoom':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				if (Math.isNaN(val1))
					val1 = defaultStageZoom;

				// if value2 isn't a numerical value, then rely on defaultCamZoom
				if (Math.isNaN(val2))
				{
					var forceBool:Bool = false;
					if (value2 == 'true')
						forceBool = true;
	
					defaultCamZoom = val1;
					if (forceBool)
						FlxG.camera.zoom = val1;
				}
				else
				{
					FlxTween.tween(FlxG.camera, {zoom: val1}, val2, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							defaultCamZoom = val1;
						}
					});
				}

			case 'Add/Remove Vignette':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				// Value 1 for alpha
				// Value 2 for speed it appears
				FlxTween.cancelTweensOf(vignette);

				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2) || val2 == 0)
					val2 = 0.0001;
			
				trace(val1 + ' & ' + val2);

				if (val2 != 0)
					FlxTween.tween(vignette, {alpha: val1}, val2, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){}});
			case 'Red Static':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				// Value 1 for alpha
				// Value 2 for speed it appears
				FlxTween.cancelTweensOf(redStatic);

				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2) || val2 == 0)
					val2 = 0.0001;
			
				trace(val1 + ' & ' + val2);

				if (val2 != 0)
					FlxTween.tween(redStatic, {alpha: val1}, val2, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){}});
			case 'Show death screen':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				if (value1 == null || value1 == 'false')
					val1 = 0.00001;

				if (Math.isNaN(val2) || val2 == 0)
					val2 = 0.0001;
				forcecamZooming = false;
				camZooming = false;
				FlxTween.tween(imdead, {alpha: val1}, val2, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){}});
				FlxTween.tween(cambgwindo, {alpha: val1}, val2, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){}});
				FlxTween.tween(cambgwindo2, {alpha: val1}, val2, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){}});

			case 'UI visibilty':
				if (value1 == null || value1 == 'false')
				{
					iconP1.visible = false;
					healthBar.visible = false;
					healthBarBG.visible = false;
					iconP1.visible = false;
					iconP2.visible = false;
					scoreTxt.visible = false;
					botplayTxt.visible = false;
					timeBar.visible = false;
					timeBarBG.visible = false;
					timeTxt.visible = false;
				}
				if (value1 == 'true')
				{
					iconP1.visible = true;
					healthBar.visible = true;
					healthBarBG.visible = true;
					iconP1.visible = true;
					iconP2.visible = true;
					scoreTxt.visible = true;

					if (cpuControlled)
						botplayTxt.visible = true;

					timeBar.visible = true;
					timeBarBG.visible = true;
					timeTxt.visible = true;
				}
			case 'Force Dance':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.specialAnim = false;
				char.dance();
			case 'Poem Transition':
				var tweenBool:Bool = true;
				if (value1 == 'false')
					tweenBool = false;

				if (tweenBool)
				{
					poemTransition.visible = true;
					poemTransition.alpha = 1;
					poemTransition.animation.play('poemtransition', true);
				}
				else
				{
					FlxTween.tween(poemTransition, {alpha: 0}, 0.25, {
						ease: FlxEase.sineOut,
						onComplete: function(twn:FlxTween)
						{
							poemTransition.alpha = 0;
							poemTransition.visible = false;
						}
					});
				}

			case 'Tint Character':
				//Only used for home but might as well make it universal
				var char:Character = boyfriend;
				var val3:Int = FlxColor.fromString('#' + value3);
				switch (value2.toLowerCase().trim())
				{
					default:
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad':
						char = dad;
					case 'yuri':
						char = extra2;
					case 'sayori':
						char = extra1;
				}

				if (Math.isNaN(val3))
					val3 = 0xFFFFFFFF;
				
				switch (value1.toLowerCase())
				{
					case 'red':
						char.color = FlxColor.RED;
					case 'black':
						char.color = FlxColor.BLACK;
					case 'gray' | 'grey':
						char.color = FlxColor.GRAY;
					case 'white' | 'default':
						char.color = FlxColor.WHITE;
					default:
						char.color = val3;
				}

			case 'Eye Popup':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				trace(value3);
				var eye:FlxSprite = new FlxSprite(val1, val2);
				eye.frames = Paths.getSparrowAtlas('MarkovEyes', 'doki');
				eye.animation.addByPrefix('idle', 'MarkovWindow', 24, false);
				eye.animation.play('idle');
				eye.antialiasing = ClientPrefs.globalAntialiasing;
				eye.scrollFactor.set();
				eye.cameras = [camHUD];
				add(eye);

				// goku goes super saiyan
				new FlxTimer().start(4.61, function(tmr:FlxTimer)
				{
					remove(eye);
					eye.destroy();
				});

			case 'Summon Sayori or Yuri':
				var char:Character = extra1;
				var val2:Float = Std.parseFloat(value2);
				switch (value1)
				{
					case 'sayori' | 'sayo' | 'Sayori':
						char = extra1;
					case 'yuri' | 'Yuri':
						char = extra2;
				}

				if (Math.isNaN(val2) || val2 == 0)
					val2 = 0.0001;

				FlxTween.tween(char, {alpha: 1}, val2, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){}});
			case 'Cat Doodles Stuff':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				//value 1 handles alpha
				//value 2 speed
				//value 3 kills the cats

				if (Math.isNaN(val1) || val1 == 0)
					val1 = 0.00001;

				if (Math.isNaN(val2) || val2 == 0)
					val2 = 0.0001;

				if (value3 == null || value3 == '')
					FlxTween.tween(bakaOverlay, {alpha: val1}, val2, {ease: FlxEase.linear, onComplete: function(twn:FlxTween){}});

				if (value3 != null && value3 != '')
				{
					bakaOverlay.animation.play('hueh');
					new FlxTimer().start(4, function(tmr:FlxTimer)
					{
						bakaOverlay.alpha = 0;
					});
				}
			case 'Strumline Visibility':
				
				var strum:FlxTypedGroup<StrumNote>;
				var underlay:FlxSprite;
				var val2:Float = Std.parseFloat(value2);
				var val3:Float = Std.parseFloat(value3);

				if (Math.isNaN(val2))
					val2 = 1;
				else if (val2 == 0)
					val2 = 0.0001;

				if (Math.isNaN(val3) || val3 <= 0)
					val3 = 0.01;

				trace(value1 + ' & ' + value2 + ' & ' + value3);
				var includeBlood:Bool = false;
				switch (value1)
				{
					case 'dad' | 'opponent':
					{
						strum = opponentStrums;
						underlay = grpUnderlay.members[0];
						if (bloodDrips) includeBlood = true;
						if (ClientPrefs.middleScroll)
							val2 *= 0.35;
					}
					default:
						strum = playerStrums;
						underlay = grpUnderlay.members[1];
				}

				for (i in 0...4)
				{
					FlxTween.cancelTweensOf(strum.members[i]);
					FlxTween.tween(strum.members[i], {alpha: val2}, val3, {ease: FlxEase.circOut});
					if (includeBlood)
					{
						FlxTween.cancelTweensOf(bloodStrums.members[i]);
						FlxTween.tween(bloodStrums.members[i], {alpha: val2}, val3, {ease: FlxEase.circOut});
					}
				
				}

				if (underlay != null)
				{
					FlxTween.cancelTweensOf(underlay);
					FlxTween.tween(underlay, {alpha: val2 * ClientPrefs.noteUnderlay}, val3, {ease: FlxEase.circOut});
				}

			case 'Play SFX':
				var val2:Float = Std.parseFloat(value2);

				if (Math.isNaN(val2))
					val2 = 1;

				FlxG.sound.play(Paths.sound(value1), val2);
			case 'Markov note spawns blood':
				switch (value1.toLowerCase().trim())
				{
					case 'true':
						bloodDrips = true;
					default:
						bloodDrips = false;
				}
			case 'Spawn Red Eyes':
				if (funnyEyes != null)
				{
					switch (value1.toLowerCase().trim())
					{
						default: // Spawn the eyes here	
							funnyEyes.alpha = 1;
							FlxG.camera.flash(FlxColor.RED, 0.5);
						case 'fadeout': // make em disappear here
							var val2:Float = Std.parseFloat(value2);
							if (Math.isNaN(val2))
								val2 = 1;
							FlxTween.tween(funnyEyes, {alpha: 0.001}, val2, {ease: FlxEase.circOut});
					}
				}
			case 'Stab Border':
				var val1:Float = Std.parseFloat(value1);
				if (Math.isNaN(val1))
					val1 = 0.5;
				FlxTween.cancelTweensOf(screenPulse);
				screenPulse.alpha = 1;
				FlxTween.tween(screenPulse, {alpha: 0.001}, val1, {ease: FlxEase.circOut});
			case 'Tween in the holy light':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val1 = 0.1;

				FlxTween.cancelTweensOf(holylight);
				FlxTween.tween(holylight, {alpha: val1}, val2, {ease: FlxEase.linear});
		}
		callOnLuas('onEvent', [eventName, value1, value2, value3]);
	}

	function funnyGlitch(duration:Float, sound:String):Void
	{
		if (sound.length > 0)
			FlxG.sound.play(Paths.sound(sound));

		// don't do anything if the user decided to be funny
		if (!ClientPrefs.shaders || duration <= 0)
			return;

		camGame.filtersEnabled = true;
		FlxTween.tween(this, {staticAlpha: 1}, 0.5, {ease:FlxEase.circOut});

		new FlxTimer().start(duration, function(tmr:FlxTimer)
		{
			camGame.filtersEnabled = false;
		});
	}

	function moveCameraSection(?id:Int = 0):Void
	{
		if (SONG.notes[id] == null)
			return;

		if (SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0];
			camFollow.y += gf.cameraPosition[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			tweenCamIn();

			if (dad.facing != dad.initFacing)
			{
				camFollow.x += 150;
			}

			camFollow.x += camNoteX;
			camFollow.y += camNoteY;

			noteCamera(dad, false);
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			camFollow.x -= boyfriend.cameraPosition[0] + BFCAM_X;
			camFollow.y += boyfriend.cameraPosition[1] + BFCAM_Y;

			if (boyfriend.facing != boyfriend.initFacing)
			{
				camFollow.x -= 450;
			}

			camFollow.x += camNoteX;
			camFollow.y += camNoteY;

			noteCamera(boyfriend, true);
		}
	}

	private function noteCamera(focusedChar:Character, mustHit:Bool)
	{
		if (noteCam)
		{
			if ((focusedChar == boyfriend && mustHit) || (focusedChar == dad && !mustHit))
			{
				camNoteX = 0;
				if (focusedChar.animation.curAnim.name.startsWith('singLEFT'))
					camNoteX -= camNoteExtend;
				if (focusedChar.animation.curAnim.name.startsWith('singRIGHT'))
					camNoteX += camNoteExtend;
				if (focusedChar.animation.curAnim.name.startsWith('idle'))
					camNoteX = 0;

				camNoteY = 0;
				if (focusedChar.animation.curAnim.name.startsWith('singDOWN'))
					camNoteY += camNoteExtend;
				if (focusedChar.animation.curAnim.name.startsWith('singUP'))
					camNoteY -= camNoteExtend;
				if (focusedChar.animation.curAnim.name.startsWith('idle'))
					camNoteY = 0;
			}
		}
	}

	function tweenCamIn()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = beforeEndSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if (ClientPrefs.noteOffset <= 0)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	function beforeEndSong()
	{
		trace('beforeEndSong');
		endingSong = true;
		if (isStoryMode)
		{
			trace('story mode check hueh');
			switch (Paths.formatToSongPath(curSong))
			{
				case 'home':
					ClientPrefs.storycomplete = true;
					ClientPrefs.saveSettings();
					trace('home check');
					FlxG.camera.fade(FlxColor.BLACK, 0.1, false);
					startVideo('ending');
				default:
					endSong();
			}
		}
		else
		{
			switch (curSong)
			{
				default:
					endSong();
			}
		}
	}

	public var transitioning = false;

	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck())
			{
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null)
		{
			return;
		}
		else
		{
			var achieve:String = checkForAchievement([
				'week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss', 'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad', 'ur_good', 'hype',
				'two_keys', 'toastie', 'debugger'
			]);

			if (achieve != null)
			{
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if (ret != FunkinLua.Function_Stop && !transitioning && !inCutscene)
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					CustomFadeTransition.nextCamera = camOther;
					if (FlxTransitionableState.skipNextTransIn)
					{
						CustomFadeTransition.nextCamera = null;
					}
					changedDifficulty = false;
					MusicBeatState.switchState(new CreditsState());
				}
				else
				{
					var difficulty:String = '-hard';

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	function startAchievement(achieve:String)
	{
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}

	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene)
		{
			endSong();
		}
	}
	#end

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	private function cachePopUpScore(prefix:String = '', suffix:String = '')
	{
		if (isPixelStage)
		{
			if (prefix != '') prefix = 'pixelUI/';
			if (suffix != '') suffix = '-pixel';
		}

		Paths.image(prefix + "sick" + suffix);
		Paths.image(prefix + "good" + suffix);
		Paths.image(prefix + "bad" + suffix);
		Paths.image(prefix + "shit" + suffix);
		Paths.image(prefix + "combo" + suffix);

		for (i in 0...10)
			Paths.image(prefix + 'num' + i + suffix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		// trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		// tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				bads++;
			case "good": // good
				totalNotesHit += 0.75;
				goods++;
			case "sick": // sick
				totalNotesHit += 1;
				sicks++;
		}

		if (daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			songHits++;
			totalPlayed++;
			RecalculateRating();

			if (ClientPrefs.scoreZoom)
			{
				if (scoreTxtTween != null)
				{
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween)
					{
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
			daRating = 'sick';
		else if (combo > 12)
			daRating = 'good'
		else if (combo > 4)
			daRating = 'bad';
	 */

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
		trace(combo);
		trace(seperatedScore);
	 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				// var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if (daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							// notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else if (canMiss)
				{
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		// trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong)
			{
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth * healthLoss;
		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		// For testing purposes
		// trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if (!practiceMode)
			songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if (daNote.gfNote)
		{
			char = gf;
		}

		if (char.hasMissAnimations)
		{
			var daAlt = '';
			if (daNote.noteType == 'Alt Animation')
				daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote
		]);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (ClientPrefs.ghostTapping)
				return;

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if (!practiceMode)
				songScore -= 10;
			if (!endingSong)
			{
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
		});*/

			if (boyfriend.hasMissAnimations)
			{
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial' && forcecamZooming)
			camZooming = true;

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation')
				{
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if (note.gfNote)
			{
				char = gf;
			}

			if (note.extrachar1Note)
			{
				char = extra1;
			}

			if (note.extrachar2Note)
			{
				char = extra2;
			}

			if (note.noteType == 'Note of Markov (Play anim)' && bloodDrips && !note.isSustainNote)
			{
				FlxG.sound.play(Paths.sound('stab'));
				var spr:FlxSprite;
				spr = bloodStrums.members[Std.int(Math.abs(note.noteData))];
				if (spr.animation.curAnim.name.startsWith('idle'))
				{
					spr.animation.play('drip');
				}
			}

			if (storyDifficultyText == 'Unfair' && !note.isSustainNote && health >= 0.3)
			{
				health -= 0.01;
			}

			char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
		{
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);

			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}

				switch (note.noteType)
				{
					case 'Hurt Note': // Hurt note
						if (boyfriend.animation.getByName('hurt') != null)
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if (combo > 9999)
					combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if (!note.noAnimation)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation')
					daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				// if (note.isSustainNote){ wouldn't this be fun : P. i think it would be swell

				// if(note.gfNote) {
				//  var anim = animToPlay +"-hold" + daAlt;
				//	if(gf.animation.getByName(anim) == null)anim = animToPlay + daAlt;
				//	gf.playAnim(anim, true);
				//	gf.holdTimer = 0;
				// } else {
				//  var anim = animToPlay +"-hold" + daAlt;
				//	if(boyfriend.animation.getByName(anim) == null)anim = animToPlay + daAlt;
				//	boyfriend.playAnim(anim, true);
				//	boyfriend.holdTimer = 0;
				// }
				// }else{
				if (note.gfNote)
				{
					gf.playAnim(animToPlay + daAlt, true);
					gf.holdTimer = 0;
				}
				else
				{
					boyfriend.playAnim(animToPlay + daAlt, true);
					boyfriend.holdTimer = 0;
				}
				// }
				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String;

		if (note != null)
		{
			switch (note.noteStyle)
			{
				case 'poem':
					skin = 'poemUI/noteSplashes';
				default:
					skin = 'noteSplashes';
			}
		}
		else
		{
			skin = 'noteSplashes';
		}

		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if (note != null)
		{
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt, note.noteStyle);
		grpNoteSplashes.add(splash);
	}

	private var preventLuaRemove:Bool = false;

	override function destroy()
	{
		preventLuaRemove = true;
		for (i in 0...luaArray.length)
		{
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
			FlxG.sound.music.fadeTween.cancel();

		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua)
	{
		if (luaArray != null && !preventLuaRemove)
			luaArray.remove(lua);
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		if (FlxG.sound.music.time >= -ClientPrefs.noteOffset)
		{
			if (Conductor.songPosition <= vocals.length && Math.abs(vocals.time - FlxG.sound.music.time) > 15)
				resyncVocals();
		}

		super.stepHit();

		if (curStep == lastStepHit)
			return;

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.bpm = SONG.notes[Math.floor(curStep / 16)].bpm;
				// FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.bpm = SONG.bpm;
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);


		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			//moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 2 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0
			&& !gf.stunned
			&& gf.animation.curAnim.name != null
			&& !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}

		if (curBeat % 2 == 0)
		{
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
			}
			if (extra1.animation.curAnim.name != null && !extra1.animation.curAnim.name.startsWith("sing") && !extra1.stunned)
			{
				extra1.dance();
			}
			if (extra2.animation.curAnim.name != null && !extra2.animation.curAnim.name.startsWith("sing"))
			{
				extra2.dance();
			}
		}
		else if (dad.danceIdle
			&& dad.animation.curAnim.name != null
			&& !dad.curCharacter.startsWith('gf')
			&& !dad.animation.curAnim.name.startsWith("sing")
			&& !dad.stunned)
		{
			dad.dance();
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var ret:Dynamic = luaArray[i].call(event, args);
			if (ret != FunkinLua.Function_Continue)
			{
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length)
		{
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = opponentStrums.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating()
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10)
				ratingFC = "SDCB";
			else if (songMisses >= 10)
				ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String>):String
	{
		if (chartingMode)
			return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length)
		{
			var achievementName:String = achievesToCheck[i];
			if (!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled)
			{
				var unlock:Bool = false;
				switch (achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if (isStoryMode
							&& campaignMisses + songMisses < 1
							&& CoolUtil.difficultyString() == 'HARD'
							&& storyPlaylist.length <= 1
							&& !changedDifficulty
							&& !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch (weekName) // I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if (achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if (achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if (achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if (achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if (achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if (achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if (achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if (ratingPercent < 0.2 && !practiceMode)
						{
							unlock = true;
						}
					case 'ur_good':
						if (ratingPercent >= 1 && !usedPractice)
						{
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if (Achievements.henchmenDeath >= 100)
						{
							unlock = true;
						}
					case 'oversinging':
						if (boyfriend.holdTimer >= 10 && !usedPractice)
						{
							unlock = true;
						}
					case 'hype':
						if (!boyfriendIdled && !usedPractice)
						{
							unlock = true;
						}
					case 'two_keys':
						if (!usedPractice)
						{
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length)
							{
								if (keysPressed[j])
									howManyPresses++;
							}

							if (howManyPresses <= 2)
							{
								unlock = true;
							}
						}
					case 'toastie':
						if (/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist)
						{
							unlock = true;
						}
					case 'debugger':
						if (Paths.formatToSongPath(SONG.song) == 'erb' && !usedPractice)
						{
							unlock = true;
						}
				}

				if (unlock)
				{
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
