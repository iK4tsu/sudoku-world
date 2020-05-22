module ui.sudokuApp;

import std.experimental.logger;
import std.functional : toDelegate;

import gdk.Keysyms;

import gio.Application : GioApplication = Application;

import gtk.Application;
import gtk.ApplicationWindow;
import gtk.AccelGroup;
import gtk.Box;
import gtk.Builder;
import gtk.Button;
import gtk.ButtonBox;
import gtk.CheckButton;
import gtk.ComboBox;
import gtk.CssProvider;
import gtk.Dialog;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Grid;
import gdk.Keymap;
import gtk.Label;
import gtk.ListStore;
import gtk.Stack;
import gtk.StyleContext;
import gtk.Switch;
import gtk.ToggleButton;
import gtk.TreeIter;
import gtk.VBox;
import gtk.Widget;
import gtk.Window;

import core.sudokuType : SudokuType;
import ui.actions.createAction;
import ui.sudokuBoard;

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
			trace("Loading UI");
			builder = new Builder();
			if (!builder.addFromFile("data/window.glade"))
			{
				trace("Window UI file cannot be found");
				return;
			}

			// GUI setup
			initGUI();

			// load css style
			auto provider = new CssProvider();
			provider.loadFromPath("data/window.css");
			auto display = window.getDisplay();
			auto screen = display.getDefaultScreen();
			StyleContext.addProviderForScreen(screen, provider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
		}
		else warning("Another instance already exists");

		// show application
		window.present();
	}


	private void initGUI()
	{
		trace("Initializing GUI");

		// top level
		window = cast(ApplicationWindow) builder.getObject("window");
		window.setApplication(this);

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


	// main menu button
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
	private Stack       stkMenu;
	private Box         boxMenu;
	private Box         boxChoice;
}
