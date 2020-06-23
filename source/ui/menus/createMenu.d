module ui.menus.createMenu;

import std.algorithm : equal;
import std.conv : to;
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
import gtk.Entry;
import gtk.Label;
import gtk.ListStore;
import gtk.Stack;
import gtk.StackSwitcher;
import gtk.Switch;
import gtk.ToggleButton;
import gtk.TreeIter;
import gtk.Window;

import controllers.sudokuController : GameState;
import core.rule.rule : RuleType;
import core.sudoku.grid : SudokuType;
import extra : toEnumString;
import ui.sudoku.gridUI;

class CreateMenu
{
	public this(Builder builder)
	{
		trace("Loading CreateMenu widgets...");
		btnBoxRules = cast(ButtonBox) builder.getObject("btnBoxRules");
		btnSave = cast(Button) builder.getObject("btnSave");
		cbSudokuType = cast(ComboBox) builder.getObject("cbSudokuType");
		ckBtnCreateSolution = cast(CheckButton) builder.getObject("ckBtnCreateSolution");
		ckBtnCustomSudoku = cast(CheckButton) builder.getObject("ckBtnCustomSudoku");
		lblColumn = cast(Label) builder.getObject("lblColumn");
		lblDigit = cast(Label) builder.getObject("lblDigit");
		lblRow = cast(Label) builder.getObject("lblRow");
		lblSwitchSolution = cast(Label) builder.getObject("lblSwitchSolution");
		stkMiddle = cast(Stack) builder.getObject("stackChoiceMiddle");
		stkRules = cast(Stack) builder.getObject("stackRules");
		stkSwitcherRules = cast(StackSwitcher) builder.getObject("stkSwitcherRules");
		switchSolution = cast(Switch) builder.getObject("switchSolution");
		txtDescription = cast(Entry) builder.getObject("txtDescription");
		txtSudokuTitle = cast(Entry) builder.getObject("txtSudokuTitle");
		txtUsername = cast(Entry) builder.getObject("txtUsername");
		initCbSudokuType();
		initBtnBoxRules();
	}


	// update cbSudokuType values
	private void initCbSudokuType()
	{
		auto list = new ListStore([GType.STRING]);
		cbSudokuType.setModel(list);
		foreach (i, type; EnumMembers!SudokuType)
		{
			auto iter = list.createIter();
			list.setValue(iter, 0, type.toEnumString());
			static if (i == 0)
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
			auto ckBtn = new CheckButton(type.toEnumString());
			btnBoxRules.packStart(ckBtn, true, true, 0);
		}
		btnBoxRules.showAll();
	}



// signals

	public void setOnBtnSaveClicked(void delegate(Button) dg)
	{
		btnSave.addOnClicked(dg);
	}


	public void setOnCbSudokuTypeChanged(void delegate(ComboBox) dg)
	{
		cbSudokuType.addOnChanged(dg);
	}


	public void setOnCkBtnCreateSolutionToggled(void delegate(ToggleButton) dg)
	{
		ckBtnCreateSolution.addOnToggled(dg);
	}


	public void setOnCkBtnCustomSudokuToggled(void delegate(ToggleButton) dg)
	{
		ckBtnCustomSudoku.addOnToggled(dg);
	}


	public void setOnRuleToggled(void delegate(ToggleButton) dg)
	{
		foreach (child; getBtnBoxRulesChildren())
		{
			child.addOnToggled(dg);
		}
	}


	public void setOnSwitchSolutionstateSet(bool delegate(bool, Switch) dg)
	{
		switchSolution.addOnStateSet(dg);
	}



// functions

	public void addGrid(GameState state, GridUI gridUI)
	{
		stkMiddle.addNamed(gridUI, state.to!string);
	}


	public void hideSwitchSolution()
	{
		switchSolution.setVisible(false);
	}


	public void showGrid(GridUI gridUI)
	{
		stkMiddle.setVisibleChild(gridUI);
	}


	public void showSwitchSolution()
	{
		switchSolution.setVisible(true);
	}


	/** Update rules
	 *
	 * Responsible for switching the ability to be resposive to the user input \
	 * If `sensitive` all, but Classic, rules will be sensitive to the user input \
	 * Otherwise all won't be sensitive to the user input \
	 * If a rule is active and `sensitive` is `false`, the respective rule will
	 *     be removed from the `activeBoard` rules and it's *activeness* will be
	 *     set to `false`; this doesn't apply to Classic
	 *
	 * Params:
	 *     sensitive = the state to be changed to
	 */
	public void updateRuleSensitivity(bool sentitive)
	{
		foreach (CheckButton child; getBtnBoxRulesChildren())
		{
			if (child.getLabel() == RuleType.Classic.toEnumString())
			{
				continue;
			}

			if (child.getActive() && !sentitive)
			{
				child.setActive(false);
			}
			child.setSensitive(sentitive);
		}
	}



// getters/setters

	public string getActiveComboBoxString(ComboBox cb)
	{
		auto iter = new TreeIter();
		if (cb.getActiveIter(iter))
		{
			auto model = cb.getModel();
			auto str = model.getValueString(iter, 0);
			return str;
		}
		return null;
	}


	private auto getBtnBoxRulesChildren()
	{
		return btnBoxRules.getChildren().toArray!(CheckButton);
	}


	public void setCbSudokuTypeSensitive(bool sensitive)
	{
		cbSudokuType.setSensitive(sensitive);
	}


	public void setLblColumnText(string text)
	{
		lblColumn.setText(text);
	}


	public void setLblDigitText(in string text)
	{
		lblDigit.setText(text);
	}


	public void setLblRowText(in string text)
	{
		lblRow.setText(text);
	}


	public void setLblSwitchSolutionText(in string text)
	{
		lblSwitchSolution.setText(text);
	}


	// TODO: SudokuApp: finish JSON conversion
	// public void save()
	// {
	// 	if (dialogSolver is null)
	// 	{
	// 		dialogSolver = new DialogSolver(this);
	// 		dialogSolver.present();
	// 	}
	// 	dialogSolver.savingMessage();
	// 	Sudoku.toJson(activeBoard);
	// 	dialogSolver.savedMessage();
	// 	dialogSolver.finished();
	// 	dialogSolver = null;
	// }


	/** Validates `activeBoard` as an eligible puzzle
	 *
	 * Checks if the solution of 'activeBoard' returned by the solver is equal
	 *     to the `activeSolution`
	 */
	// private void validateSolution()
	// in {
	// 	assert(activeSolution !is null);
	// }
	// body
	// {
	// 	dialogSolver = new DialogSolver(this);
	// 	Sudoku s = Sudoku.fromGridUI(activeBoard);
	// 	dialogSolver.present();
	// 	auto solved = s.solve();

	// 	if (!activeSolution.toDigits().equal(solved))
	// 	{
	// 		dialogSolver.errorMessage();
	// 		dialogSolver.finished();
	// 		return;
	// 	}

	// 	dialogSolver.successMessage();
	// 	save();
	// }


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
	// private void onBtnSaveClicked(Button)
	// {
	// 	// TODO: ui:sudokuApp: implement board check when button save is pressed
	// 	// board need at least a number filled
	// 	if (activeSolution is null)
	// 	{
	// 		// ckBtnCreateSolution is checked out?
	// 		save();
	// 	}
	// 	else if (!activeSolution.complete())
	// 	{
	// 		// solution isn't filled?
	// 		dialogSave = new DialogSave(this);
	// 		dialogSave.present();
	// 	}
	// 	else
	// 		validateSolution();
	// }


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
	private Entry txtDescription;
	private Entry txtSudokuTitle;
	private Entry txtUsername;
	private Label lblColumn;
	private Label lblDigit;
	private Label lblRow;
	private Label lblSwitchSolution;
	private Switch switchSolution;
	private Stack stkRules;
	private StackSwitcher stkSwitcherRules;
}


// private class DialogSave : Dialog
// {
// 	public this(CreateMenu action)
// 	{
// 		this.action = action;
// 		super("No valid solution provided",
// 				action.window,
// 				DialogFlags.DESTROY_WITH_PARENT,
// 				["Yes","No"],
// 				[ResponseType.YES, ResponseType.NO]);
// 		setSizeRequest(480,272);

// 		auto label = new Label("Solution provided isn't valid.\n"
// 								~"Are you sure want to save?\n"
// 								~"Saving will not save the current solution.");
// 		label.setVisible(true);
// 		label.setJustify(GtkJustification.CENTER);
// 		label.setVexpand(true);

// 		addOnResponse(&onResponse);

// 		auto vbox = getContentArea();
// 		vbox.add(label);
// 	}


// 	private void onResponse(int id, Dialog)
// 	{
// 		final switch (id)
// 		{
// 			case ResponseType.YES:
// 				action.save();
// 				break;
// 			case ResponseType.NO:
// 				break;
// 		}
// 		destroy();
// 	}

// 	private CreateMenu action;
// }


// private class DialogSolver : Dialog
// {
// 	public this(CreateMenu action)
// 	{
// 		super("",
// 				action.window,
// 				DialogFlags.DESTROY_WITH_PARENT,
// 				["OK"],
// 				[ResponseType.OK]);
// 		setSizeRequest(480,272);

// 		addOnResponse(delegate void(int,Dialog) { destroy(); });
// 		button = cast(Button) getWidgetForResponse(ResponseType.OK);
// 		button.setSensitive(false);

// 		auto vbox = getContentArea();
// 		label = new Label("Solving puzzle and comparing to solution...");
// 		label.setVisible(true);
// 		label.setJustify(GtkJustification.CENTER);
// 		label.setVexpand(true);
// 		vbox.add(label);
// 	}


// 	public void labelText(string text)
// 	{
// 		label.setText(text);
// 	}


// 	public void finished()
// 	{
// 		button.setSensitive(true);
// 	}


// 	public void errorMessage()
// 	{
// 		labelText("An error ocurred!\nThe solution provided isn't valid!");
// 	}


// 	public void successMessage()
// 	{
// 		labelText("The solution provided is valid!");
// 	}


// 	public void savingMessage()
// 	{
// 		labelText("Saving...");
// 	}


// 	public void savedMessage()
// 	{
// 		labelText("Saved!");
// 	}


// 	private Button button;
// 	private Label label;
// }
