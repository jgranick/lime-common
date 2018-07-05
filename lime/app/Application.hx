package lime.app;


import lime.system.System;
import lime.ui.Window;
import lime.utils.Preloader;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


/** 
 * The Application class forms the foundation for most Lime projects.
 * It is common to extend this class in a main class. It is then possible
 * to override "on" functions in the class in order to handle standard events
 * that are relevant.
 */
class Application extends Module {
	
	
	/**
	 * The current Application instance that is executing
	**/
	public static var current (default, null):Application;
	
	
	/**
	 * Configuration values for the application, such as window options or a package name
	**/
	public var config (default, null):Config;
	
	/**
	 * The current frame rate (measured in frames-per-second) of the application.
	 *
	 * On some platforms, a frame rate of 60 or greater may imply vsync, which will
	 * perform more quickly on displays with a higher refresh rate
	**/
	public var frameRate (get, set):Float;
	
	/**
	 * A list of currently attached Module instances
	**/
	public var modules (default, null):Array<IModule>;
	
	/**
	 * The Preloader for the current Application
	**/
	public var preloader (get, null):Preloader;
	
	/**
	 * Update events are dispatched each frame (usually just before rendering)
	 */
	public var onUpdate = new Event<Int->Void> ();
	
	/**
	 * The Window associated with this Application, or the first Window
	 * if there are multiple Windows active
	**/
	public var window (get, null):Window;
	
	/**
	 * A list of active Window instances associated with this Application
	**/
	public var windows (get, null):Array<Window>;
	
	@:noCompletion private var __backend:ApplicationBackend;
	@:noCompletion private var __windowByID:Map<Int, Window>;
	
	
	private static function __init__ () {
		
		var init = ApplicationBackend;
		#if commonjs
		var p = untyped Application.prototype;
		untyped Object.defineProperties (p, {
			"frameRate": { get: p.get_frameRate, set: p.set_frameRate },
			"preloader": { get: p.get_preloader },
			"window": { get: p.get_window },
			"windows": { get: p.get_windows }
		});
		#end
		
	}
	
	
	/**
	 * Creates a new Application instance
	**/
	public function new () {
		
		super ();
		
		if (Application.current == null) {
			
			Application.current = this;
			
		}
		
		modules = new Array ();
		__windowByID = new Map ();
		
		__backend = new ApplicationBackend (this);
		
		registerModule (this);
		
	}
	
	
	/**
	 * Adds a new module to the Application
	 * @param	module	A module to add
	 */
	public function addModule (module:IModule):Void {
		
		module.registerModule (this);
		modules.push (module);
		
		if (__windows.length > 0) {
			
			for (window in __windows) {
				
				module.addWindow (window);
				
			}
			
		}
		
		module.setPreloader (__preloader);
		
	}
	
	
	/**
	 * Initializes the Application, using the settings defined in
	 * the config instance. By default, this is called automatically
	 * when building the project using Lime's command-line tools
	 * @param	config	A Config object
	 */
	public function create (config:Config):Void {
		
		this.config = config;
		
		__backend.create (config);
		
		if (config != null) {
			
			if (Reflect.hasField (config, "fps")) {
				
				frameRate = config.fps;
				
			}
			
			if (Reflect.hasField (config, "windows")) {
				
				for (windowConfig in config.windows) {
					
					var window = new Window (windowConfig);
					createWindow (window);
					
					#if ((flash && !air) || html5)
					break;
					#end
					
				}
				
			}
			
			if (__preloader == null || __preloader.complete) {
				
				setPreloader (__preloader);
				
				for (module in modules) {
					
					setPreloader (__preloader);
					
				}
				
			}
			
		}
		
	}
	
	
	/**
	 * Adds a new Window to the Application. By default, this is
	 * called automatically by create()
	 * @param	window	A Window object to add
	 */
	public function createWindow (window:Window):Void {
		
		super.addWindow (window);
		
		for (module in modules) {
			
			module.addWindow (window);
			
		}
		
		window.create (this);
		//__windows.push (window);
		__windowByID.set (window.id, window);
		
		window.onCreate.dispatch ();
		
	}
	
	
	/**
	 * Execute the Application. On native platforms, this method
	 * blocks until the application is finished running. On other 
	 * platforms, it will return immediately
	 * @return An exit code, 0 if there was no error
	 */
	public function exec ():Int {
		
		Application.current = this;
		
		return __backend.exec ();
		
	}
	
	
	public override function onModuleExit (code:Int):Void {
		
		__backend.exit ();
		
	}
	
	
	public override function onWindowClose (window:Window):Void {
		
		removeWindow (window);
		
	}
	
	
	/**
	 * Removes a module from the Application
	 * @param	module	A module to remove
	 */
	public function removeModule (module:IModule):Void {
		
		if (module != null) {
			
			module.unregisterModule (this);
			modules.remove (module);
			
		}
		
	}
	
	
	@:noCompletion public override function removeWindow (window:Window):Void {
		
		if (window != null && __windowByID.exists (window.id)) {
			
			__windows.remove (window);
			__windowByID.remove (window.id);
			window.close ();
			
			if (this.window == window) {
				
				this.window = null;
				
			}
			
			if (__windows.length == 0) {
				
				System.exit (0);
				
			}
			
		}
		
	}
	
	
	@:noCompletion public override function setPreloader (preloader:Preloader):Void {
		
		super.setPreloader (preloader);
		
		for (module in modules) {
			
			module.setPreloader (preloader);
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private inline function get_frameRate ():Float {
		
		return __backend.getFrameRate ();
		
	}
	
	
	@:noCompletion private inline function set_frameRate (value:Float):Float {
		
		return __backend.setFrameRate (value);
		
	}
	
	
	@:noCompletion private inline function get_preloader ():Preloader {
		
		return __preloader;
		
	}
	
	
	@:noCompletion private inline function get_window ():Window {
		
		return __windows[0];
		
	}
	
	
	@:noCompletion private inline function get_windows ():Array<Window> {
		
		return __windows;
		
	}
	
	
}


#if kha
@:noCompletion private typedef ApplicationBackend = lime._internal.backend.kha.KhaApplication;
#elseif air
@:noCompletion private typedef ApplicationBackend = lime._internal.backend.air.AIRApplication;
#elseif flash
@:noCompletion private typedef ApplicationBackend = lime._internal.backend.flash.FlashApplication;
#elseif (js && html5)
@:noCompletion private typedef ApplicationBackend = lime._internal.backend.html5.HTML5Application;
#else
@:noCompletion private typedef ApplicationBackend = lime._internal.backend.native.NativeApplication;
#end