module ui.sudokuApp;

import core.stdc.stdlib : exit, EXIT_FAILURE;
import std.experimental.logger;

import gio.Application : GioApplication = Application;
import gtk.Application;
import gtk.ApplicationWindow;
import gtk.AccelGroup;
import gtk.Box;
import gtk.Builder;
import gtk.Button;
import gtk.CssProvider;
import gtk.Stack;
import gtk.StyleContext;
import gtk.Widget;
import gtk.Window;

import controllers.sudokuWorld;
import ui.menus.createMenu;

class SudokuApp : Application
{
	public this()
	{
		ApplicationFlags flags = ApplicationFlags.FLAGS_NONE;
		super("org.sudokuworld.ui", flags);
		this.addOnActivate(&onSudokuGUIActivate);
		this._window = null;
	}


	private void onSudokuGUIActivate(GioApplication app)
	{
		trace("Activate SudokuGUI Signal");

		// Detect if are any other instances running
		if (!app.getIsRemote() && window is null)
		{
			loadGlade();
			loadTopLevel();
			loadStyle();
			initGUI();
		}
		else
		{
			warning("Another instance already exists");
		}
		// show application
		window.present();
	}


	// load glade file
	private void loadGlade()
	{
		trace("Loading Glade...");
		_builder = new Builder();
		if (!builder.addFromFile("data/window.glade"))
		{
			critical("window.glade file cannot be found, aborting...");
			exit(EXIT_FAILURE);
		}
	}


	// top level
	private void loadTopLevel()
	{
		trace("Loading top level...");
		_window = cast(ApplicationWindow) builder.getObject("window");
		window.setApplication(this);
	}


	// load css style
	private void loadStyle()
	{
		trace("Loading CSS Style...");
		auto provider = new CssProvider();
		provider.loadFromPath("data/window.css");
		auto display = window.getDisplay();
		auto screen = display.getDefaultScreen();
		StyleContext.addProviderForScreen(screen, provider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
	}


	// GUI setup
	private void initGUI()
	{
		trace("Initializing GUI");
		btnCreate = cast(Button) builder.getObject("btnCreate");
		btnExit = cast(Button) builder.getObject("btnExit");
		btnPlay = cast(Button) builder.getObject("btnPlay");
		btnSettings = cast(Button) builder.getObject("btnSettings");
		stkMenu = cast(Stack) builder.getObject("stackMenu");
		boxMenu = cast(Box) builder.getObject("boxMenu");
		boxChoice = cast(Box) builder.getObject("boxChoice");

		sudokuWorld = new SudokuWorld(this);
	}



// signals

	public void setOnBtnCreateClicked(void delegate(Button) dg)
	{
		btnCreate.addOnClicked(dg);
	}


	public void setOnBtnExitClicked(void delegate(Button) dg)
	{
		btnExit.addOnClicked(dg);
	}


	public void setOnBtnPlayClicked(void delegate(Button) dg)
	{
		btnPlay.addOnClicked(dg);
	}


	public void setOnBtnSettingsClicked(void delegate(Button) dg)
	{
		btnSettings.addOnClicked(dg);
	}


	public void setOnButtonPress(bool delegate(GdkEventButton*, Widget) dg)
	{
		window.addOnButtonPress(dg);
	}



// functions

	public void showCreateMenu()
	{
		stkMenu.setVisibleChild(boxChoice);
	}



// getters/setters

	public auto builder() @property
	{
		return _builder;
	}


	public auto window() @property
	{
		return _window;
	}


	private ApplicationWindow _window;
	private Builder _builder;
	private SudokuWorld sudokuWorld;

	private Box boxMenu;
	private Box boxChoice;
	private Button btnCreate;
	private Button btnExit;
	private Button btnPlay;
	private Button btnSettings;
	private Stack stkMenu;
}
