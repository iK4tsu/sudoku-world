module ui.actions.createAction;

import std.algorithm : equal;
import std.experimental.logger;
import std.traits : EnumMembers;

import gtk.ApplicationWindow;
import gtk.Box;
import gtk.Builder;
import gtk.Button;
import gtk.ButtonBox;
import gtk.CheckButton;
import gtk.ComboBox;
import gtk.Dialog;
import gtk.Label;
import gtk.ListStore;
import gtk.Stack;
import gtk.StackSwitcher;
import gtk.Switch;
import gtk.ToggleButton;
import gtk.TreeIter;
import gtk.Window;

import core.ruleType;
import core.sudoku.sudoku;
import core.sudokuType;
import ui.sudokuBoard;

class CreateAction
{
	public this(ApplicationWindow window, Builder builder)
	{
		this.builder = builder;
		this.activeBoard = new SudokuBoard(SudokuType.SUDOKU_4X4);
		this.activeSolution = new SudokuBoard(SudokuType.SUDOKU_4X4);
		initUIConfig();
		editUIConfig();
		initUICallbacks();
	}


	private void initUIConfig()
	{
		stkLeft = cast(Stack) builder.getObject("stackChoiceLeft");
		stkMiddle = cast(Stack) builder.getObject("stackChoiceMiddle");
		stkRight = cast(Stack) builder.getObject("stackChoiceRight");

		btnSave = cast(Button) builder.getObject("btnSave");
		btnBoxConstraints = cast(ButtonBox) builder.getObject("btnBoxConstraints");
		btnBoxRules = cast(ButtonBox) builder.getObject("btnBoxRules");
		ckBtnCreateSolution = cast(CheckButton) builder.getObject("ckBtnCreateSolution");
		ckBtnCustomSudoku = cast(CheckButton) builder.getObject("ckBtnCustomSudoku");
		cbSudokuType = cast(ComboBox) builder.getObject("cbSudokuType");
		lblSwitchSolution = cast(Label) builder.getObject("lblSwitchSolution");
		switchSolution = cast(Switch) builder.getObject("switchSolution");
		stkRules = cast(Stack) builder.getObject("stackRules");
		stkSwitcherRules = cast(StackSwitcher) builder.getObject("stkSwitcherRules");
	}


	private void editUIConfig()
	{
		initCbSudokuType();
		initBtnBoxRules();

		stkMiddle.addNamed(activeBoard, SudokuType.SUDOKU_4X4);
	}


	private void initUICallbacks()
	{
		cbSudokuType.addOnChanged(&onCbSudokuTypeChanged);
		ckBtnCreateSolution.addOnToggled(&onCbBtnCreateSolutionToggled);
		btnSave.addOnClicked(&onBtnSaveClicked);
		switchSolution.addOnStateSet(&onSwitchSolutionStateSet);
	}


	// update cbSudokuType values
	private void initCbSudokuType()
	{
		auto list = new ListStore([GType.STRING]);
		cbSudokuType.setModel(list);
		foreach (i, type; EnumMembers!SudokuType)
		{
			auto iter = list.createIter();
			list.setValue(iter, 0, type);
			if (i == 0)
			{
				cbSudokuType.setActiveIter(iter);
			}
		}
	}


	// update btnBoxRules values
	private void initBtnBoxRules()
	{
		foreach (type; EnumMembers!RuleType)
		{
			auto ckBtn = new CheckButton(type);
			if (type == RuleType.CLASSIC)
			{
				ckBtn.setActive(true);
			}
			ckBtn.addOnToggled(&onRuleToggled);
			btnBoxRules.packEnd(ckBtn, true, true, 0);
		}
		btnBoxRules.showAll();
	}


	// signal to update Sudoku rules
	private void onRuleToggled(ToggleButton btn)
	{
		if (btn.getActive())
		{
			activeBoard.addRule(btn.getLabel());
		}
		else
		{
			activeBoard.removeRule(btn.getLabel());
		}
	}


	/** Runs when `cbBtnCreateSolution`
	 *
	 * Controlls `switchSolution`, if this button is active the user won't be
	 *     able to select the `activeSolution` as the `switchSolution`, will
	 *     be invisible.
	 */
	private void onCbBtnCreateSolutionToggled(ToggleButton btn)
	{
		if (!btn.getActive())
		{
			switchSolution.setSensitive(false);
			switchSolution.setVisible(false);
			switchSolution.setState(false);
			switchSolution.setActive(false);
			cbSudokuType.setSensitive(true);
			stkMiddle.setVisibleChild(activeBoard);
			activeSolution = null;
		}
		else
		{
			switchSolution.setSensitive(true);
			switchSolution.setVisible(true);
			activeSolution = new SudokuBoard(activeBoard.type);
		}
	}


	/** Active item in `cbSudokuType`
	 *
	 * Returns:
	 *     `string` with the current active item \
	 *     `null` otherwise
	 */
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


	/** Checks if the `ckBtnCreateSolution` is active
	 *
	 * Returns:
	 *     `SudokuBoard` if `ckBtnCreateSolution` is active \
	 *     `null` otherwise
	 */
	private SudokuBoard getCreateSolution(SudokuType type)
	{
		if (ckBtnCreateSolution.getActive())
			return new SudokuBoard(type);
		return null;
	}


	/** Runs when cbSudokuType active item is changed
	 *
	 * Controlls the visible child on the middle `Stack` as well as the
	 *     the current `SolutionBoard`
	 */
	private void onCbSudokuTypeChanged(ComboBox)
	{
		string typeName = getActiveSudokuType();
		SudokuType t;
		if (stkMiddle.getChildByName(typeName) is null)
		{
			t = Sudoku.toSudokuType(typeName);
			stkMiddle.addNamed(new SudokuBoard(t), typeName);
		}
		activeSolution = getCreateSolution(t);
		activeBoard = cast(SudokuBoard) stkMiddle.getChildByName(typeName);
		stkMiddle.setVisibleChild(activeBoard);
		trace("CHANGED TYPE: ",typeName);
	}


	/** Runs when switchSolution is clicked
	 *
	 * Controlls which `SudokuBoard`, `activeBoard` or `activeSolution`, is visible
	 *     in the middle `Stack`
	 */
	private bool onSwitchSolutionStateSet(bool active, Switch s)
	{
		if (active)
		{
			if (activeSolution is null)
			{
				activeSolution = new SudokuBoard(activeBoard.type);
			}
			if (stkMiddle.getChildByName("solution"~activeBoard.type) is null)
			{
				stkMiddle.addNamed(activeSolution, "solution"~activeBoard.type);
			}
			activeSolution = cast(SudokuBoard) stkMiddle.getChildByName("solution"~activeBoard.type);
			activeSolution.fill(activeBoard.toDigits(), true);
			stkMiddle.setVisibleChild(activeSolution);
			s.setState(true);
			s.setActive(true);
			cbSudokuType.setSensitive(false);
			lblSwitchSolution.setText("Solution Grid");
		}
		else
		{
			stkMiddle.setVisibleChild(activeBoard);
			s.setState(false);
			s.setActive(false);
			lblSwitchSolution.setText("Puzzle Grid");
			cbSudokuType.setSensitive(true);
		}
		return true;
	}


	// TODO: SudokuApp: finish JSON conversion
	public void save()
	{
		if (dialogSolver is null)
		{
			dialogSolver = new DialogSolver(this);
			dialogSolver.present();
		}
		dialogSolver.savingMessage();
		Sudoku.toJson(activeBoard);
		dialogSolver.savedMessage();
		dialogSolver.finished();
		dialogSolver = null;
	}


	/** Validates `activeBoard` as an eligible puzzle
	 *
	 * Checks if the solution of 'activeBoard' returned by the solver is equal
	 *     to the `activeSolution`
	 */
	private void validateSolution()
	in {
		assert(activeSolution !is null);
	}
	body
	{
		dialogSolver = new DialogSolver(this);
		Sudoku s = Sudoku.fromSudokuBoard(activeBoard);
		dialogSolver.present();
		auto solved = s.solve();

		if (!activeSolution.toDigits().equal(solved))
		{
			dialogSolver.errorMessage();
			dialogSolver.finished();
			return;
		}

		dialogSolver.successMessage();
		save();
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
		if (activeSolution is null)
		{
			// ckBtnCreateSolution is checked out?
			save();
		}
		else if (!activeSolution.complete())
		{
			// solution isn't filled?
			dialogSave = new DialogSave(this);
			dialogSave.present();
		}
		else
			validateSolution();
	}


	// main properties;
	private ApplicationWindow window;
	private Builder builder;
	private DialogSave dialogSave;
	private DialogSolver dialogSolver;

	// every box item is a stack
	private Stack stkLeft;
	private Stack stkMiddle;
	private Stack stkRight;

	// widgets
	private Button btnSave;
	private ButtonBox btnBoxConstraints;
	private ButtonBox btnBoxRules;
	private CheckButton ckBtnCreateSolution;
	private CheckButton ckBtnCustomSudoku;
	private ComboBox cbSudokuType;
	private Label lblSwitchSolution;
	private Switch switchSolution;
	private Stack stkRules;
	private StackSwitcher stkSwitcherRules;

	// boards
	private SudokuBoard activeBoard;
	private SudokuBoard activeSolution;
}


private class DialogSave : Dialog
{
	public this(CreateAction action)
	{
		this.action = action;
		super("No valid solution provided",
				action.window,
				DialogFlags.DESTROY_WITH_PARENT,
				["Yes","No"],
				[ResponseType.YES, ResponseType.NO]);
		setSizeRequest(480,272);

		auto label = new Label("Solution provided isn't valid.\n"
								~"Are you sure want to save?\n"
								~"Saving will not save the current solution.");
		label.setVisible(true);
		label.setJustify(GtkJustification.CENTER);
		label.setVexpand(true);

		addOnResponse(&onResponse);

		auto vbox = getContentArea();
		vbox.add(label);
	}


	private void onResponse(int id, Dialog)
	{
		final switch (id)
		{
			case ResponseType.YES:
				action.save();
				break;
			case ResponseType.NO:
				break;
		}
		destroy();
	}

	private CreateAction action;
}


private class DialogSolver : Dialog
{
	public this(CreateAction action)
	{
		super("",
				action.window,
				DialogFlags.DESTROY_WITH_PARENT,
				["OK"],
				[ResponseType.OK]);
		setSizeRequest(480,272);

		addOnResponse(delegate void(int,Dialog) { destroy(); });
		button = cast(Button) getWidgetForResponse(ResponseType.OK);
		button.setSensitive(false);

		auto vbox = getContentArea();
		label = new Label("Solving puzzle and comparing to solution...");
		label.setVisible(true);
		label.setJustify(GtkJustification.CENTER);
		label.setVexpand(true);
		vbox.add(label);
	}


	public void labelText(string text)
	{
		label.setText(text);
	}


	public void finished()
	{
		button.setSensitive(true);
	}


	public void errorMessage()
	{
		labelText("An error ocurred!\nThe solution provided isn't valid!");
	}


	public void successMessage()
	{
		labelText("The solution provided is valid!");
	}


	public void savingMessage()
	{
		labelText("Saving...");
	}


	public void savedMessage()
	{
		labelText("Saved!");
	}


	private Button button;
	private Label label;
}
