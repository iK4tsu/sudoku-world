module ui.sudokuCell;

import std.conv : parse, to, ConvException;
import std.experimental.logger;
import std.functional : toDelegate;
import std.uni : toLower;

import gdk.Keymap;

import gtk.EditableIF;
import gtk.Entry;
import gtk.Popover;
import gtk.StyleContext;
import gtk.Widget;

import core.sudokuType : SudokuType;
import ui.sudokuBoard;

public class SudokuCell : Entry
{
	public this(SudokuBoard board, int row, int column, SudokuType type)
	{
		setAlignment(0.5);
		setVisibility(true);
		setCanFocus(true);
		setMaxLength(1);
		setMaxWidthChars(1);
		setWidthChars(1);
		setHasFrame(false);
		setInputPurpose(InputPurpose.DIGITS);
		setEditable(true);
		this.board = board;

		this.row = row;
		this.column = column;

		auto context = getStyleContext();
		context.addClass("no_caret");
		context.addClass(type.toLower());

		maxDigit = parseSudokuType(type);

		// addOnChanged(&onCellChanged);
		addOnKeyPress(&onKeyPress);
	}

	/** Setter
	 *
	 * Sets certain properties based on SudokuType
	 */
	private int parseSudokuType(SudokuType type)
	{
		final switch (type)
		{
			case SudokuType.SUDOKU_4X4:
				setSizeRequest(150, 150);
				return 4;

			case SudokuType.SUDOKU_6X6:
				setSizeRequest(100, 100);
				return 6;

			case SudokuType.SUDOKU_9X9:
				setSizeRequest(65, 65);
				return 9;
		}
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

	private bool onKeyPress(GdkEventKey* ev, Widget sender)
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

		ModifierType modifier = ev.state;
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

		info("KEY PRESSED: " ~ keyName);

		if (keyNumber > 0 && keyNumber <= maxDigit)
		{
			// detect Shift + <Digit>
			bool needSnyderNotation =
			(
				(modifier & ModifierType.SHIFT_MASK) > 0
			);

			// detect Ctrl + <Digit>
			bool needPencilMark =
			(
				(modifier & ModifierType.CONTROL_MASK) > 0
			);

			// TODO: sudokuCell: enable/disable marks
			if (needSnyderNotation)
			{
				// TODO: snyder notation logic
				info("Ctrl modifier detected, writting \'" ~keyval.to!string~ "\' to snyderNotation...");
			}
			else if (needPencilMark)
			{
				// TODO: pencil mark logic
				info("Shift modifier detected, writting \'" ~keyName~ "\' to pencilMark...");
			}
			else
			{
				// write the number on the cell
				info("No modifiers detected, writing \'" ~ keyName ~ "\' to buffer...");
				updateText(keyNumber.to!string);
			}

			// key event was overriten, so there's no need for default call
			return true;
		}

		// don't process digts above the max, e.g Sudoku4x4 has a max of 4
		if (keyNumber > maxDigit)
		{
			warning("key number is higher than " ~ maxDigit.to!string);
			return true;
		}

		// Delete text
		if (keyNumber == 0 || keyName == "BackSpace" || keyName == "Delete")
		{
			updateText("");
			return true;
		}

		// modify Arrow Right behaviour
		if (keyName == "Right")
		{
			if (column == board.cols - 1)
				board.setCellFocus(row, 0);
			else
				board.setCellFocus(row, column + 1);
			return true;
		}

		// modify Arrow Left behaviour
		if (keyName == "Left")
		{
			if (column == 0)
				board.setCellFocus(row, board.cols - 1);
			else
				board.setCellFocus(row, column - 1);
			return true;
		}

		// add an extra behaviour to Arrow Down
		if (keyName == "Down")
		{
			if (row == board.rows - 1)
			{
				board.setCellFocus(0, column);
				return true;
			}
			else
				return false;
		}

		// add an extra behavior to Arrow Up
		if (keyName == "Up")
		{
			if (row == 0)
			{
				board.setCellFocus(board.rows - 1, column);
				return true;
			}
			else
				return false;
		}

		// Shift + Tab
		if (keyName == "Tab" && (modifier & ModifierType.SHIFT_MASK) > 0)
		{
			// default behaviour
			return false;
		}

		if (keyName == "Tab")
		{
			// default behaviour
			return false;
		}

		// the remaining keys aren't used, so no need to process them
		return true;
	}

	private void updateText(string text)
	{
		deleteText(0,0);
		getBuffer().setText(text, 1);
	}

	// TODO: implement popover logic
	private void onCellChanged(EditableIF txt)
	{
		if (txt.getChars(0,0).length > 0)
			hidePopovers();
		else
			showPopovers();
	}

	private void hidePopovers()
	{
		snyderNotation.hide();
		pencilMark.hide();
	}

	private void showPopovers()
	{
		snyderNotation.show();
		pencilMark.show();
	}

	private SudokuBoard board;

	// notation which appears on the corners
	private Popover snyderNotation;

	// most known notation
	private Popover pencilMark;

	private int maxDigit;
	private int row;
	private int column;
}
