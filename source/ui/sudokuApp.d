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
		btnBoxRules     =   cast(ButtonBox) builder.getObject("btnBoxRules");

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

		import core.ruleType;
		// update btnBoxRules values
		foreach (type; EnumMembers!RuleType)
		{
			auto cButton = new CheckButton(type);
			if (type == RuleType.CLASSIC)
				cButton.setActive(true);
			cButton.addOnToggled(&onRuleToggled);
			btnBoxRules.packEnd(cButton, true, true, 0);
		}

		btnBoxRules.showAll();
	}


	private void onRuleToggled(ToggleButton btn)
	{
		SudokuBoard board = cast(SudokuBoard) stkChoiceMiddle.getVisibleChild();

		if (btn.getActive())
		{
			board.addRule(btn.getLabel());
		}
		else
		{
			board.removeRule(btn.getLabel());
		}
	}


	/** Signal for the `save` button in Create menu
	 *
	 * This is responsible for making the first basic validations
	 *   * Checks if the `solution` exists
	 *   * Checks if the `solution` is complete \
	 *
	 * If the `solution` doesn't meet the requirements, then user can choose whether
	 *     or not he wants to proceed. \
	 *       * `YES`, the `board` is saved without a solution \
	 *       * `NO`, the action is cancelled
	 */
	private void onBtnSaveClicked(Button)
	{
		// TODO: ui:sudokuApp: implement board check when button save is pressed
		// board need at least a number filled
		// check if has solution
		if (solution is null || !solution.complete())
		{
			// solution doesn't exist?
			auto dialog = new Dialog(
									"No valid solution provided",
									cast(Window) window,
									DialogFlags.DESTROY_WITH_PARENT,
									["Yes","No"],
									[ResponseType.YES, ResponseType.NO]
									);
			dialog.setSizeRequest(480,272);

			auto label = new Label("Solution provided isn't valid.\n"
									~"Are you sure want to save?\n"
									~"Saving will not save the current solution.");

			label.setVisible(true);
			label.setJustify(GtkJustification.CENTER);
			label.setVexpand(true);

			dialog.addOnResponse(delegate void(int id, Dialog d)
								{
									final switch (id)
									{
										case ResponseType.YES:
											save();
											break;

										case ResponseType.NO:
											break;
									}

									d.destroy();
								});

			auto content = dialog.getContentArea();
			content.add(label);

			dialog.present();
		}
		else
			validateSolution();
	}


	public void validateSolution()
	in {
		assert(solution !is null);
	}
	body
	{
		import core.sudoku.sudoku;
		import std.algorithm : equal;
		auto board = lastVisibleBoard;
		Sudoku s = Sudoku.fromSudokuBoard(board);

		auto dialog = new Dialog(
								"",
								window,
								DialogFlags.DESTROY_WITH_PARENT,
								["OK"],
								[ResponseType.OK]
								);
		dialog.setSizeRequest(480,272);
		dialog.addOnResponse(delegate void(int,Dialog d) { d.destroy(); });
		Button btnOK = cast(Button) dialog.getWidgetForResponse(ResponseType.OK);
		btnOK.setSensitive(false);

		auto vbox = dialog.getContentArea();
		auto label = new Label("Solving puzzle and comparing to solution...");
		label.setVisible(true);
		label.setJustify(GtkJustification.CENTER);
		label.setVexpand(true);
		vbox.add(label);

		dialog.present();
		auto solved = s.solve();
		btnOK.setSensitive(true);

		if (!solution.toCells().equal(solved))
		{
			label.setText("An error ocurred!\n"
							~"The solution provided isn't valid!");
			return;
		}

		label.setText("The solution provided is valid!");
		save();
	}


	// TODO: SudokuApp: implement Json parser
	public void save()
	{
		import core.sudoku.sudoku;
		SudokuBoard board = lastVisibleBoard;
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
	private ButtonBox   btnBoxRules;
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
