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
import gtk.Switch;
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
		stkChoiceLeft   =   cast(Stack)     builder.getObject("stackChoiceLeft");
		cbSudokuType    =   cast(ComboBox)  builder.getObject("cbSudokuType");
		btnSave         =   cast(Button)    builder.getObject("btnSave");
		switchSolution  =   cast(Switch)    builder.getObject("switchSolution");

		gridCreate4x4   =   new SudokuBoard(SudokuType.SUDOKU_4X4);
		gridCreate6x6   =   new SudokuBoard(SudokuType.SUDOKU_6X6);
		gridCreate9x9   =   new SudokuBoard(SudokuType.SUDOKU_9X9);

		stkChoiceMiddle.addNamed(gridCreate4x4, "gridDynamic4x4");
		stkChoiceMiddle.addNamed(gridCreate6x6, "gridDynamic6x6");
		stkChoiceMiddle.addNamed(gridCreate9x9, "gridDynamic9x9");

			// callbacks
		cbSudokuType.addOnChanged(&onCbSudokuTypeChanged);
		btnSave.addOnClicked(&onBtnSaveClicked);
		switchSolution.addOnStateSet(&onSwitchSolutionStateSet);
	}


	// update widget values
	private void editGUI()
	{
		// Update cbSudokuType values
		import std.traits : EnumMembers;

		auto list = new ListStore([GType.STRING]);
		cbSudokuType.setModel(list);

		foreach (i, type; EnumMembers!SudokuType)
		{
			auto iter = list.createIter();
			list.setValue(iter, 0, type);

			if (i == 0)
				cbSudokuType.setActiveIter(iter);
		}
	}


	// convert to Json
	private void onBtnSaveClicked(Button)
	{
		auto board = lastVisibleBoard;

		// check if has solution


		// convert to json

		// TODO: SudokuApp: implement Json parser
		import core.sudoku.sudoku;
		import core.rule.classic;
		import gtk.Popover;

		auto label = new Label("A Solution was not privided, proceeding to auto solve");
		auto notification = new Popover(btnSave);
		notification.add(label);
		label.setVisible(true);
		notification.popup();

		auto iter = new TreeIter();
		cbSudokuType.getActiveIter(iter);
		auto model = cbSudokuType.getModel();
		auto str = model.getValueString(iter, 0);
		SudokuType st;

		import std.traits : EnumMembers;
		foreach (type; EnumMembers!SudokuType)
		{
			if (type == str) st = type;
		}

		Sudoku sudoku = new Sudoku(st);

		auto digits = board.toCells();


		sudoku.initialize(digits);
		sudoku.add(new ClassicRule());

		sudoku.solve();

		board.fill(sudoku.solution);

		Sudoku.toJson(board);
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
		auto const str = getActiveSudokuType();
		if (!(str is null))
		{
			final switch(str)
			{
				case SudokuType.SUDOKU_4X4:
					stkChoiceMiddle.setVisibleChild(gridCreate4x4);
					if (!(solution is null) && solution.type != str)
						solution = null;
					break;

				case SudokuType.SUDOKU_6X6:
					stkChoiceMiddle.setVisibleChild(gridCreate6x6);
					if (!(solution is null) && solution.type != str)
						solution = null;
					break;

				case SudokuType.SUDOKU_9X9:
					stkChoiceMiddle.setVisibleChild(gridCreate9x9);
					if (!(solution is null) && solution.type != str)
						solution = null;
					break;
			}
		}
	}


	private string getActiveSudokuType()
	{
		auto iter = new TreeIter();
		if (cbSudokuType.getActiveIter(iter))
		{
			auto model = cbSudokuType.getModel();
			auto str = model.getValueString(iter, 0);
			return str;
		}
		return null;
	}


	private bool onSwitchSolutionStateSet(bool active, Switch s)
	{
		if (active)
		{
			if (solution is null)
			{
				import core.sudoku.sudoku;
				SudokuType type = Sudoku.toSudokuType(getActiveSudokuType());
				if (type is null)
				{
					critical("SudokuType CONVERSION ERROR");
					return false;
				}
				solution = new SudokuBoard(type);
				stkChoiceMiddle.addNamed(solution, "gridCreateSolution");
			}
			lastVisibleBoard = cast(SudokuBoard) stkChoiceMiddle.getVisibleChild();
			solution.fill(lastVisibleBoard.toCells, true);
			stkChoiceMiddle.setVisibleChild(solution);
			s.setState(true);
			s.setActive(true);
			cbSudokuType.setSensitive(false);
		}
		else
		{
			if (lastVisibleBoard is null)
				return false;

			stkChoiceMiddle.setVisibleChild(lastVisibleBoard);
			s.setState(false);
			s.setActive(false);
			cbSudokuType.setSensitive(true);
		}

		return true;
	}


	private ApplicationWindow window;
	private Builder builder;

	// Widgets
		// Menu
	private Stack       stkMenu;
	private Box         boxMenu;
	private Box         boxChoice;

		// Choice
	private Stack       stkChoiceLeft;
	private Stack       stkChoiceRight;
	private Stack       stkChoiceMiddle;

		// Create Menu
	private Box         boxCreateRight;
	private ComboBox    cbSudokuType;
	private SudokuBoard gridCreate4x4;
	private SudokuBoard gridCreate6x6;
	private SudokuBoard gridCreate9x9;
	private SudokuBoard solution;
	private SudokuBoard lastVisibleBoard;
	private Button      btnSave;
	private Switch      switchSolution;
}
