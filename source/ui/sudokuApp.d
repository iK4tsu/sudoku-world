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
import gtk.Window;

import ui.actions.createAction;

class SudokuApp : Application
{
	public this()
	{
		ApplicationFlags flags = ApplicationFlags.FLAGS_NONE;
		super("org.sudokuworld.ui", flags);
		this.addOnActivate(&onSudokuGUIActivate);
		this.window = null;
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
		builder = new Builder();
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
		window = cast(ApplicationWindow) builder.getObject("window");
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
		// Main menu
			// widgets
		auto btnExit   = cast(Button) builder.getObject("btnExit");
		auto btnCreate = cast(Button) builder.getObject("btnCreate");
		stkMenu        = cast(Stack)  builder.getObject("stackMenu");
		boxMenu        = cast(Box)    builder.getObject("boxMenu");
		boxChoice      = cast(Box)    builder.getObject("boxChoice");

			// callbacks
		btnExit.addOnClicked(delegate void(Button) { this.quit(); } );
		btnCreate.addOnClicked(&onBtnCreateClicked);

		// Create Menu
		this.createAction = new CreateAction(window, builder);
	}


	/** This is called when `btnCreate` is clicked in the main menu
	 *
	 * Makes the create menu content `Stack` visible
	 */
	private void onBtnCreateClicked(Button)
	{
		stkMenu.setVisibleChild(boxChoice);
	}


	private ApplicationWindow window;
	private Builder builder;

	// Actions
	private CreateAction createAction;

	// Widgets
		// Menu
	private Stack stkMenu;
	private Box boxMenu;
	private Box boxChoice;
}
