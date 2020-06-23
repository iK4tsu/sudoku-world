module controllers.createMenuController;

import std.conv : to;
import std.experimental.logger;

import gtk.Button;
import gtk.ComboBox;
import gtk.Switch;
import gtk.ToggleButton;

import controllers.sudokuController;
import controllers.sudokuWorld;
import core.sudoku.grid : SudokuType;
import extra;
import ui.menus.createMenu;
import ui.sudoku.gridUI;

public class CreateMenuController
{
	public this(CreateMenu createMenu, SudokuWorld sudokuWorld)
	{
		trace("Initializing CreateMenuController");
		this.createMenu = createMenu;
		this.sudokuWorld = sudokuWorld;
		auto sc = sudokuWorld.addSudokuController(GameState.Create, SudokuType.Sudoku4x4);
		createMenu.addGrid(GameState.Create, sc.gridUI);
		createMenu.showGrid(sc.gridUI);
		callbacks();
	}


	private void callbacks()
	{
		trace("Initializing CreateMenu callbacks...");
		createMenu.setOnBtnSaveClicked(&onBtnSaveClicked);
		createMenu.setOnCbSudokuTypeChanged(&onCbSudokuTypeChanged);
		createMenu.setOnCkBtnCreateSolutionToggled(&onCkBtnCreateSolutionToggled);
		createMenu.setOnCkBtnCustomSudokuToggled(&onCkBtnCustomSudokuToggled);
		createMenu.setOnRuleToggled(&onRuleToggled);
		createMenu.setOnSwitchSolutionstateSet(&onSwitchSolutionStateSet);
	}



// Callbacks

	// TODO: controllers:createMenuController: implement save button logic
	private void onBtnSaveClicked(Button)
	{
		// do stuff
	}


	/** Runs when cbSudokuType active item is changed
	 *
	 * Controlls the visible child on the middle `Stack` as well as the
	 *     the current `SolutionBoard`
	 */
	private void onCbSudokuTypeChanged(ComboBox cb)
	{
		// get the type in the combo box
		string typeName = createMenu.getActiveComboBoxString(cb);

		// delete existing grids
		sudokuWorld.deleteSudokuController(GameState.Solution);
		sudokuWorld.deleteSudokuController(GameState.Create);

		// get type by using the string
		SudokuType t = typeName.parseEnum!SudokuType;

		// create a new grid with the new type
		SudokuController sc = sudokuWorld.addSudokuController(GameState.Create, t);

		// add the grid created to the stack
		createMenu.addGrid(GameState.Create, sc.gridUI);

		// show grid
		createMenu.showGrid(sc.gridUI);
	}


	/** Runs when `ckBtnCustomSudoku` is toggled
	 *
	 * Calls a function which is responsible for rule management
	 *
	 * See_Also:
	 *     `updateRuleSensitivity(bool sentitive)`
	 */
	private void onCkBtnCustomSudokuToggled(ToggleButton btn)
	{
		createMenu.updateRuleSensitivity(!btn.getActive());
	}


	/** Runs when `cbBtnCreateSolution` is toggled
	 *
	 * Controlls `switchSolution`, if this button is active the user won't be
	 *     able to select the `activeSolution` as the `switchSolution`, will
	 *     be invisible.
	 */
	private void onCkBtnCreateSolutionToggled(ToggleButton btn)
	{
		if (!btn.getActive())
		{
			// turn off all input and visibility from switch
			createMenu.hideSwitchSolution();

			// set combo box sensitivity to true
			createMenu.setCbSudokuTypeSensitive(true);

			// show Create grid
			createMenu.showGrid(sudokuWorld.getSudokuController(GameState.Create).gridUI);

			// delete solution
			sudokuWorld.deleteSudokuController(GameState.Solution);
		}
		else
		{
			// turn on all input and visibility from switch
			createMenu.showSwitchSolution();
		}
	}


	// TODO: controllers:createMenuController: implement onRuleToggled
	private void onRuleToggled(ToggleButton btn)
	{
		if (btn.getActive())
		{
			// add rule to grid
		}
		else
		{
			// remove rule from grid
		}
	}


	/** Runs when switchSolution is clicked
	 *
	 * Controlls which `GridUI`, `activeBoard` or `activeSolution`, is visible
	 *     in the middle `Stack`
	 */
	private bool onSwitchSolutionStateSet(bool active, Switch s)
	{
		if (active)
		{
			// create a new solution
			SudokuController sc;
			sc = sudokuWorld.addSudokuController(GameState.Solution, sudokuWorld.getSudokuController(GameState.Create));

			// add the solution to the stack
			createMenu.addGrid(GameState.Solution, sc.gridUI);

			// show solution
			createMenu.showGrid(sc.gridUI);

			// update label text
			createMenu.setLblSwitchSolutionText("Solution Grid");
		}
		else
		{
			// show Create grid
			createMenu.showGrid(sudokuWorld.getSudokuController(GameState.Create).gridUI);

			// delete Solution grid
			sudokuWorld.deleteSudokuController(GameState.Solution);

			// update label text
			createMenu.setLblSwitchSolutionText("Puzzle Grid");
		}

		// update combo box sensitivity
		createMenu.setCbSudokuTypeSensitive(!active);

		// update switch
		s.setState(active);
		s.setActive(active);

		return true;
	}



// Functions

	private void switchGridType(SudokuType type)
	{
		sudokuWorld.addSudokuController(GameState.Create, type);
	}


	public void setCellInfoText(in int column, in int row, in int digit)
	{
		createMenu.setLblRowText(row.to!string);
		createMenu.setLblColumnText(column.to!string);
		createMenu.setLblDigitText(digit.to!string);
	}


	private CreateMenu createMenu;
	private SudokuWorld sudokuWorld;
}
