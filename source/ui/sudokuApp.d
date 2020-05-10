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
import gtk.ComboBox;
import gtk.CssProvider;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Grid;
import gdk.Keymap;
import gtk.Label;
import gtk.ListStore;
import gtk.Stack;
import gtk.StyleContext;
import gtk.TreeIter;
import gtk.Widget;

import core.sudokuType : SudokuType;
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
			editGUI();

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
		auto btnExit    =   cast(Button)    builder.getObject("btnExit");
		auto btnCreate  =   cast(Button)    builder.getObject("btnCreate");
		stkMenu         =   cast(Stack)     builder.getObject("stackMenu");
		boxMenu         =   cast(Box)       builder.getObject("boxMenu");
		boxChoice       =   cast(Box)       builder.getObject("boxChoice");

			// callbacks
		btnExit.addOnClicked(delegate void(Button) { this.quit(); } );
		btnCreate.addOnClicked(&onBtnCreateClicked);

		// Create Menu
			// widgets
		boxCreateRight  =   cast(Box)       builder.getObject("boxCreateRight");
		stkChoiceRight  =   cast(Stack)     builder.getObject("stackChoiceRight");
		stkChoiceMiddle =   cast(Stack)     builder.getObject("stackChoiceMiddle");
		cbSudokuType    =   cast(ComboBox)  builder.getObject("cbSudokuType");
		btnSave         =   cast(Button)    builder.getObject("btnSave");

		gridCreate4x4   =   new SudokuBoard(SudokuType.SUDOKU_4X4);
		gridCreate6x6   =   new SudokuBoard(SudokuType.SUDOKU_6X6);
		gridCreate9x9   =   new SudokuBoard(SudokuType.SUDOKU_9X9);

		stkChoiceMiddle.addNamed(gridCreate4x4, "gridDynamic4x4");
		stkChoiceMiddle.addNamed(gridCreate6x6, "gridDynamic6x6");
		stkChoiceMiddle.addNamed(gridCreate9x9, "gridDynamic9x9");


			// callbacks
		cbSudokuType.addOnChanged(&onCbSudokuTypeChanged);
		btnSave.addOnClicked(&onBtnSaveClicked);
	}

	// update widget values
	private void editGUI()
	{
		// Update cbSudokuType values
		import std.traits : EnumMembers;

		auto list = new ListStore([GType.STRING]);
		cbSudokuType.setModel(list);

		foreach (type; EnumMembers!SudokuType)
		{
			auto iter = list.createIter();
			list.setValue(iter, 0, type);
		}
	}

	// convert to Json
	private void onBtnSaveClicked(Button)
	{
		auto board = stkChoiceMiddle.getVisibleChild();
		// TODO: SudokuApp: implement Json parser
		import core.sudoku;
		Sudoku.toJson(cast(SudokuBoard)board);
	}

	// main menu button
	private void onBtnCreateClicked(Button)
	{
		stkMenu.setVisibleChild(boxChoice);
		stkChoiceRight.setVisibleChild(boxCreateRight);
	}

	// update sudoku grid on create menu
	private void onCbSudokuTypeChanged(ComboBox cb)
	{
		auto iter = new TreeIter();
		if (cb.getActiveIter(iter))
		{
			auto model = cb.getModel();
			auto str = model.getValueString(iter, 0);
			final switch(str)
			{
				case SudokuType.SUDOKU_4X4:
					stkChoiceMiddle.setVisibleChild(gridCreate4x4);
					break;

				case SudokuType.SUDOKU_6X6:
					stkChoiceMiddle.setVisibleChild(gridCreate6x6);
					break;

				case SudokuType.SUDOKU_9X9:
					stkChoiceMiddle.setVisibleChild(gridCreate9x9);
					break;
			}
		}
	}

	private ApplicationWindow window;
	private Builder builder;

	// Widgets
		// Menu
	private Stack       stkMenu;
	private Box         boxMenu;
	private Box         boxChoice;

		// Choice
	private Stack       stkChoiceRight;
	private Stack       stkChoiceMiddle;

		// Create Menu
	private Box         boxCreateRight;
	private ComboBox    cbSudokuType;
	private Grid        gridCreate4x4;
	private Grid        gridCreate6x6;
	private Grid        gridCreate9x9;
	private Button      btnSave;
}
