module controllers.sudokuController;

import std.conv : ConvException, to;
import std.experimental.logger;

import cairo.Context;
import gdk.Device;
import gdk.Event;
import gdk.Keymap;
import gtk.Widget;

import controllers.createMenuController;
import controllers.sudokuWorld;
import core.sudoku.grid;
import ui.menus.createMenu;
import ui.sudoku.gridUI;
import ui.sudoku.cellUI;


enum GameState {
	Create,
	Play,
	Solution,
}


public class SudokuController
{
	public this(Grid grid, GridUI gridUI, GameState gameState, SudokuWorld sudokuWorld)
	{
		_grid = grid;
		_gridUI = gridUI;
		this.sudokuWorld = sudokuWorld;
		_gameState = gameState;

		gridUI.buildCells(grid.toDigit(), grid.rows, grid.columns);
		callbacks();
	}


	private void callbacks()
	{
		foreach (CellUI[] array; gridUI.cells)
		{
			foreach (CellUI cell; array)
			{
				cell.setEvents(
					GdkEventMask.EXPOSURE_MASK
					| GdkEventMask.ENTER_NOTIFY_MASK
					| GdkEventMask.LEAVE_NOTIFY_MASK
					| GdkEventMask.BUTTON1_MOTION_MASK
					| GdkEventMask.BUTTON_PRESS_MASK
					| GdkEventMask.KEY_PRESS_MASK
				);

				cell.addOnEnterNotify(&onCellEnterNotify);
				cell.addOnButtonPress(&onCellButtonPress);
				cell.addOnKeyPress(&onCellKeyPress);
				cell.addOnDraw(&onCellDraw);
			}
		}
	}


// Callbacks

	/** Runs when the mouse enter the `Widget's` area
	 */
	private bool onCellEnterNotify(GdkEventCrossing* event, Widget widget)
	{
		if (event.state & ModifierType.BUTTON1_MASK)
		{
			trace("Enter with button 1 pressed");
			CellUI cell = cast(CellUI) widget;
			gridUI.setCellFocus(cell.row, cell.column);
		}
		return true;
	}


	private bool onCellButtonPress(GdkEventButton* ev, Widget widget)
	{
		if (ev.button != BUTTON_PRIMARY)
			return false;

		trace("BUTTON_1 Pressed");
		CellUI cell = cast(CellUI) widget;
		// focus this cell
		// add this cell to the focused list
		gridUI.setCellFocus(cell.row, cell.column);
		cell.queueDraw();

		// removes grab from this device
		// alows other widgets to receive event signals while the mouse button 1
		//   is pressed
		Device device = new Device(ev.device);
		device.getSeat().ungrab();

		if ((ev.state & ModifierType.CONTROL_MASK) == 0)
		{
			// clear all other focused cells
			gridUI.cleanFocus();

			// update left bar
			if (gameState != GameState.Play)
			{
				createMenuController.setCellInfoText(cell.row, cell.column, cell.digit);
			}
		}

		return true;
	}


	/** Checks if the pressed key belongs to keypad
	 *
	 * Params:
	 *     keyName = key name to be evaluated
	 *
	 * Returns:
	 *     `1` to `9` value if has the name **KP_1** to **KP_9** \
	 *     `-1` otherwise
	 */
	private int keypadVal(string keyName)
	{
		for (int i; i <= 9; i++)
			if (keyName == ("KP_" ~ i.to!string))
				return i;

		return -1;
	}


	private bool onCellKeyPress(GdkEventKey* ev, Widget widget)
	{
		uint keyval;
		int _group;
		int _level;
		ModifierType _consumed;

		// check if numerical values are being pressed with SHIFT modifier
		// this must be done because of the way gtk interprets inputs
		// with common chars a simple keyvalToLower check is enough as it converts
		//     'A'   (Shift +    'a') to 'a', but that's is not the case with other keys
		//     '!'   (Shift +    '1') does convert to '1' and
		//     'END' (Shift + 'KP_1') does convert to 'KP_1'
		// however the hardwareKeycode is the same
		// so we can use that factor to our advantage and check if the current
		//     keyval is just the normal with Shift

		auto keymap = Keymap.getDefault();
		keymap.translateKeyboardState (
			ev.hardwareKeycode,             // actual key pressed
			ModifierType.MOD2_MASK
				| ModifierType.SHIFT_MASK,  // modifiers pressed
			ev.group,                       // key group
			keyval,                         // returned keyval calculated
			_group,                         // returned group
			_level,                         // returned level
			_consumed                       // returned modifiers
		);

		// if the result if the same as the current keyval, then Shift is being pressed
		// we want lower case, e.g. (Shift + 1) == '!', we want '1'
		if (ev.keyval == keyval)
		{
			keymap.translateKeyboardState (
				ev.hardwareKeycode,
				ModifierType.MOD2_MASK,
				ev.group,
				keyval,
				_group,
				_level,
				_consumed
			);
		}
		else
		{
			keyval = ev.keyval;
		}

		const ModifierType modifier = ev.state;
		string keyName = Keymap.keyvalName(keyval);
		int keyNumber;

		// convert to number
		try {
			keyNumber = to!int(keyName);
		}
		catch (ConvException e)
		{
			// in case of error check keypad values
			// if it's not a number keyNumber is set to -1
			keyNumber = keypadVal(keyName);
		}

		info("KEY PRESSED: ", keyName);

		CellUI cell = cast(CellUI) widget;
		if (keyNumber > 0 && keyNumber <= cell.maxDigit)
		{
			// detect Shift + <Digit>
			const bool needSnyderNotation = (modifier & ModifierType.SHIFT_MASK) > 0;

			// detect Ctrl + <Digit>
			const bool needPencilMark = (modifier & ModifierType.CONTROL_MASK) > 0;

			if (needSnyderNotation)
			{
				info("Shift modifier, updating snyderNotation: \'",keyNumber,"\'");

				// notify and update every focused cell
				gridUI.cellHandleSnyderNotation(keyNumber.to!string);
			}
			else if (needPencilMark)
			{
				info("Ctrl modifier, updating pencilMark: \'",keyNumber,"\'");

				// notify and update every focused cell
				gridUI.cellHandlePencilMark(keyNumber.to!string);
			}
			else
			{
				info("No modifiers, updating digit: \'",keyNumber,"\'");

				// notify and update every focused cell
				auto cells = gridUI.cellHandleDigit(keyNumber);
				foreach (CellUI cellUI; cells)
				{
					_grid[cellUI.row, cellUI.column].digit = keyNumber;
				}
			}

			// key event was overriten, so there's no need for default call
			return true;
		}

		// don't process digts above the max, e.g Sudoku4x4 has a max of 4
		if (keyNumber > cell.maxDigit)
		{
			critical("DIGIT HIGHER THAN: ", cell.maxDigit, ". Aborting...");
			return true;
		}

		// delete digit
		if (!keyNumber || keyName == "BackSpace" || keyName == "Delete")
		{
			if ((modifier & ModifierType.CONTROL_MASK) > 0)
			{
				trace("Ctrl modifier, deleting pencilMark digits");

				// delete all digits from pencilMark
				gridUI.cellClearPencilMark();
			}
			else if ((modifier & ModifierType.SHIFT_MASK) > 0)
			{
				trace("Shift modifier, deleting snyderNotation digits");

				// delete all digits from snyderNotation
				gridUI.cellClearSnyderNotation();
			}
			else
			{
				trace("No modifiers, deleting digit");

				gridUI.cellHandleDigit(0);
			}
			return true;
		}

		// modify Arrow Right behaviour
		if (keyName == "Right")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					gridUI.cleanFocus();

			const int column = (cell.column + 1) % gridUI.cols;
			gridUI.setCellFocus(cell.row, column);

			cell.queueDraw();
			return true;
		}

		// modify Arrow Left behaviour
		if (keyName == "Left")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					gridUI.cleanFocus();

			const int column = (cell.column + gridUI.cols - 1) % gridUI.cols;
			gridUI.setCellFocus(cell.row, column);

			cell.queueDraw();
			return true;
		}

		// add an extra behaviour to Arrow Down
		if (keyName == "Down")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					gridUI.cleanFocus();

			const int row = (cell.row + 1) % gridUI.cols;
			gridUI.setCellFocus(row, cell.column);

			cell.queueDraw();
			return true;
		}

		// add an extra behavior to Arrow Up
		if (keyName == "Up")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					gridUI.cleanFocus();

			const int row = (cell.row + gridUI.rows - 1) % gridUI.rows;
			gridUI.setCellFocus(row, cell.column);

			cell.queueDraw();
			return true;
		}

		// Shift + Tab
		if (keyName == "Tab" && (modifier & ModifierType.SHIFT_MASK) > 0)
		{
			gridUI.cleanFocus();

			const int row = cell.column == 0 ? (cell.row + gridUI.rows - 1) % gridUI.rows : cell.row;
			const int column = (cell.column + gridUI.cols - 1) % gridUI.cols;
			gridUI.setCellFocus(row, column);

			cell.queueDraw();
			return true;
		}

		if (keyName == "Tab")
		{
			gridUI.cleanFocus();

			const int column = (cell.column + 1) % gridUI.cols;
			const int row = column == 0 ? (cell.row + 1) % gridUI.rows : cell.row;
			gridUI.setCellFocus(row, column);

			cell.queueDraw();
			return true;
		}

		// the remaining keys aren't used, so no need to process them
		return true;
	}


	private bool onCellDraw(Context cr, Widget widget)
	{
		CellUI cell = cast(CellUI) widget;
		// TODO: ui:sudokuCell: implement highlighted color logic
		// check cell states by order of priority SELECTED, HIGHLIGHTED, BLOCKED
		if (cell.selected)
			cell.backgroundColor = cell.selectedColorBg;
		// else if (highlighted)
		else
			cell.backgroundColor = cell.freeCellColor;

		// foreground
		if (cell.isBlocked)
			cell.foregroundColor = cell.digitBlockedColor;
		else
			cell.foregroundColor = cell.digitColor;

		// set the color
		cr.setSourceRgb(cell.backgroundColor.red, cell.backgroundColor.green, cell.backgroundColor.blue);

		// draw cell background
		cr.paint();

		// draw digit if exists and hide helpers
		if (cell.digit)
		{
			cr.setSourceRgb(cell.foregroundColor.red, cell.foregroundColor.green, cell.foregroundColor.blue);
			string text = cell.digit.to!string;
			auto height = cell.getAllocatedHeight().to!double;
			auto width = cell.getAllocatedWidth().to!double;
			cr.setFontSize(height * 0.75);
			cell.printCentered(cr,text,height,width);
			return false;
		}

		// delete existing number and draw helpers
		else
		{
			auto height = cell.getAllocatedHeight().to!double;
			auto width = cell.getAllocatedWidth().to!double;
			cr.setFontSize(height * 0.75);
			cell.printCentered(cr, "", height, width);

			if (!(cell.pencilMark is null))
				cell.printPencilMark(cr, height, width);

			if (!(cell.snyderNotation is null))
				cell.printSnyderNotation(cr, height, width);

			return false;
		}
	}



// Getters/Setters

	private CreateMenuController createMenuController() @property
	{
		return sudokuWorld.createMenuController;
	}


	public auto gameState() const @property
	{
		return _gameState;
	}


	public auto grid() @property
	{
		return _grid;
	}


	public auto gridUI() @property
	{
		return _gridUI;
	}


	private GameState _gameState;
	private Grid _grid;
	private GridUI _gridUI;
	private SudokuWorld sudokuWorld;
}
