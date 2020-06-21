module controllers.sudokuWorld;

import std.experimental.logger;

import gtk.Button;
import gtk.Widget;

import controllers.createMenuController;
import controllers.sudokuController;
import core.sudoku.grid;
import core.sudoku.sudoku;
import ui.menus.createMenu;
import ui.sudoku.gridUI;
import ui.sudokuApp;


public class SudokuWorld
{
	public this(SudokuApp app)
	{
		trace("Initializing SudokuWorld");
		_app = app;
		_createMenuController = new CreateMenuController(new CreateMenu(app.builder), this);
		callbacks();
	}


	private void callbacks()
	{
		trace("Initializing SudokuWorld callbacks...");
		_app.setOnBtnCreateClicked(&onBtnCreateClicked);
		_app.setOnBtnExitClicked(&onBtnExitClicked);
		_app.setOnButtonPress(&onButtonPress);
	}


	/** This is called when `btnCreate` is clicked in the main menu
	 *
	 * Makes the create menu content `Stack` visible
	 */
	private void onBtnCreateClicked(Button)
	{
		_app.showCreateMenu();
	}


	/** Exit the program
	 */
	private void onBtnExitClicked(Button)
	{
		_app.quit();
	}


	// TODO: ui:sudokuWorld: implement Play Menu
	private void onBtnPlayClicked(Button)
	{
		// do something
	}


	// TODO: ui:sudokuWorld: implement Settings Menu
	private void onBtnSettingsClicked(Button)
	{
		// do something
	}


	private bool onButtonPress(GdkEventButton* ev, Widget widget)
	{
		if (ev.button != BUTTON_PRIMARY)
			return false;


		// clear focus in the active grid
		GridUI gridUI;
		if (GameState.Play in sudokuControllers)
		{
			gridUI = sudokuControllers[GameState.Play].gridUI;
		}
		else if (GameState.Solution in sudokuControllers)
		{
			gridUI = sudokuControllers[GameState.Solution].gridUI;
			_createMenuController.setCellInfoText(0,0,0);
		}
		else if (GameState.Create in sudokuControllers)
		{
			gridUI = sudokuControllers[GameState.Create].gridUI;
			_createMenuController.setCellInfoText(0,0,0);
		}
		gridUI.cleanFocus();
		return false;
	}



// functions

public void setCreateMenuCellInfoText(in int column, in int row, in int digit)
{
	_createMenuController.setCellInfoText(column, row, digit);
}


// Getters/Setters

	public void addSudokuController(SudokuController sudokuController)
	{
		sudokuControllers[sudokuController.gameState] = sudokuController;
	}


	public auto addSudokuController(GameState state, SudokuType type)
	{
		Grid grid = new Grid(Sudoku.dimension(type).expand);
		grid.initialize(new int[][](grid.height, grid.width));
		GridUI gridUI = new GridUI(type);
		SudokuController sd = new SudokuController(grid, gridUI, state, this);
		return sudokuControllers[state] = sd;
	}


	public auto addSudokuController(GameState state, SudokuController sudokuController)
	{
		SudokuType type = sudokuController.gridUI.type;
		Grid grid = new Grid(Sudoku.dimension(type).expand);
		int[][] digits = sudokuController.grid.toDigit();
		grid.initialize(digits);
		GridUI gridUI = new GridUI(type);
		SudokuController sd = new SudokuController(grid, gridUI, state, this);
		return sudokuControllers[state] = sd;
	}


	public void deleteSudokuController(GameState state)
	{
		// cannot remove directly from the associative array because of the
		// gridUI Gtk Widget object inside
		// removing this from the AA doesn't grant an immediate destruction of
		// gruidUI, causing conflicts with other Widgets associated with it
		// we need to destroy the widget manually to remove any dependency it might have
		SudokuController* p = (state in sudokuControllers);
		if (p !is null)
		{
			SudokuController sc = *p;
			sc.gridUI.destroy();
			sudokuControllers.remove(state);
		}
	}


	public auto getSudokuController(GameState state)
	{
		return sudokuControllers[state];
	}


	public auto createMenuController() const @property
	{
		return _createMenuController;
	}


	public auto app() const @property
	{
		return _app;
	}


	private CreateMenuController _createMenuController;
	private SudokuController[GameState] sudokuControllers;
	private SudokuApp _app;
}
