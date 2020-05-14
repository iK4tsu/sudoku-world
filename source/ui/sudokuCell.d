module ui.sudokuCell;

import std.array : join;
import std.conv : ConvException, to;
import std.experimental.logger;

import cairo.Context;
import cairo.c.types;

import gdk.DragContext;
import gdk.Event;
import gdk.Keymap;
import gdk.RGBA;

import gtk.DrawingArea;
import gtk.Label;
import gtk.Widget;

import core.sudokuType;
import ui.sudokuBoard;
import ui.sudokuHelper;


public class SudokuCell : DrawingArea
{
	public this(SudokuBoard board, int row, int column)
	{
		int width, height;

		final switch(board.type)
		{
			case SudokuType.SUDOKU_4X4:
				width = height = 150;
				break;

			case SudokuType.SUDOKU_6X6:
				width = height = 100;
				break;

			case SudokuType.SUDOKU_9X9:
				width = height = 65;
				break;
		}

		setSizeRequest(width, height);

		setVisible(true);
		setHalign(GtkAlign.CENTER);
		setValign(GtkAlign.CENTER);
		setCanFocus(true);
		setSensitive(true);

		setEvents(
			GdkEventMask.EXPOSURE_MASK
			| GdkEventMask.ENTER_NOTIFY_MASK
			| GdkEventMask.LEAVE_NOTIFY_MASK
			| GdkEventMask.BUTTON1_MOTION_MASK
			| GdkEventMask.BUTTON_PRESS_MASK
			| GdkEventMask.KEY_PRESS_MASK
		);

		this.board = board;
		this.row = row;
		this.column = column;
		this.maxDigit = board.rows;

		pencilMark = new SudokuHelper();
		snyderNotation = new SudokuHelper();

		digitColor      = new RGBA(0.957,0.263,0.212);
		selectedColorBg = new RGBA(0.961,0.876,0.702);
		freeCellColor   = new RGBA(0.267,0.282,0.298);
		blockCellColor  = new RGBA(0.227,0.243,0.259);

		addOnDraw(&draw);
		addOnButtonPress(&onButtonPress);
		addOnKeyPress(&onKeyPress);
	}


	private bool onButtonPress(GdkEventButton* ev, Widget w)
	{
		if (ev.button != 1)
			return false;

		if ((ev.state & ModifierType.CONTROL_MASK) == 0)
		{
			// clear all other focused cells
			board.cleanFocus();
		}

		// focus this cell
		// add this cell to the focused list
		board.setCellFocus(row, column);

		return false;
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

		info("KEY PRESSED: ", keyName);

		if (keyNumber > 0 && keyNumber <= maxDigit)
		{
			// detect Shift + <Digit>
			bool needSnyderNotation = (modifier & ModifierType.SHIFT_MASK) > 0;

			// detect Ctrl + <Digit>
			bool needPencilMark = (modifier & ModifierType.CONTROL_MASK) > 0;

			if (needSnyderNotation)
			{
				info("Shift modifier, updating snyderNotation: \'",keyNumber,"\'");

				// notify and update every focused cell
				board.cellHandleSnyderNotation(keyNumber.to!string);
			}
			else if (needPencilMark)
			{
				info("Ctrl modifier, updating pencilMark: \'",keyNumber,"\'");

				// notify and update every focused cell
				board.cellHandlePencilMark(keyNumber.to!string);
			}
			else
			{
				info("No modifiers, updating digit: \'",keyNumber,"\'");

				// notify and update every focused cell
				board.cellHandleDigit(keyNumber);
			}

			// key event was overriten, so there's no need for default call
			return true;
		}

		// don't process digts above the max, e.g Sudoku4x4 has a max of 4
		if (keyNumber > maxDigit)
		{
			critical("DIGIT HIGHER THAN: ", maxDigit, ". Aborting...");
			return true;
		}

		// delete digit
		if (!keyNumber || keyName == "BackSpace" || keyName == "Delete")
		{
			if ((modifier & ModifierType.CONTROL_MASK) > 0)
			{
				trace("Ctrl modifier, deleting pencilMark digits");

				// delete all digits from pencilMark
				board.cellClearPencilMark();
			}
			else if ((modifier & ModifierType.SHIFT_MASK) > 0)
			{
				trace("Shift modifier, deleting snyderNotation digits");

				// delete all digits from snyderNotation
				board.cellClearSnyderNotation();
			}
			else
			{
				trace("No modifiers, deleting digit");

				board.cellHandleDigit(0);
			}
			return true;
		}

		// modify Arrow Right behaviour
		if (keyName == "Right")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					board.cleanFocus();

			if (column == board.cols - 1)
				board.setCellFocus(row, 0);
			else
				board.setCellFocus(row, column + 1);

			queueDraw();
			return true;
		}

		// modify Arrow Left behaviour
		if (keyName == "Left")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					board.cleanFocus();

			if (column == 0)
				board.setCellFocus(row, board.cols - 1);
			else
				board.setCellFocus(row, column - 1);
			return true;
		}

		// add an extra behaviour to Arrow Down
		if (keyName == "Down")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					board.cleanFocus();

			if (row == board.rows - 1)
				board.setCellFocus(0, column);
			else
				board.setCellFocus(row + 1, column);
			return true;
		}

		// add an extra behavior to Arrow Up
		if (keyName == "Up")
		{
			if ((modifier & ModifierType.CONTROL_MASK) == 0)
					board.cleanFocus();

			if (row == 0)
				board.setCellFocus(board.rows - 1, column);
			else
				board.setCellFocus(row - 1, column);
			return true;
		}

		// Shift + Tab
		if (keyName == "Tab" && (modifier & ModifierType.SHIFT_MASK) > 0)
		{
			board.cleanFocus();
			return false;
		}

		if (keyName == "Tab")
		{
			board.cleanFocus();
			return false;
		}

		// the remaining keys aren't used, so no need to process them
		return true;
	}


	private bool draw(Context cr, Widget w)
	{
		// TODO: ui:sudokuCell: implement highlighted color logic
		// check cell states by order of priority SELECTED, HIGHLIGHTED, BLOCKED
		if (selected)
			backgroundColor = selectedColorBg;
		// else if (highlighted)
		else if (blocked)
			backgroundColor = blockCellColor;
		else
			backgroundColor = freeCellColor;

		// TODO: ui:sudokuCell: change to tuples and implement a function to do setSourceRgb
		// set the color
		cr.setSourceRgb(backgroundColor.red, backgroundColor.green, backgroundColor.blue);

		// draw cell background
		cr.paint();

		// draw digit if exists and hide helpers
		if (digit)
		{
			cr.setSourceRgb(digitColor.red, digitColor.green, digitColor.blue);
			string text = digit.to!string;
			auto height = getAllocatedHeight().to!double;
			auto width = getAllocatedWidth().to!double;
			cr.setFontSize(height * 0.75);
			printCentered(cr,text,height,width);
			return false;
		}

		// delete existing number and draw helpers
		else
		{
			auto height = getAllocatedHeight().to!double;
			auto width = getAllocatedWidth().to!double;
			cr.setFontSize(height * 0.75);
			printCentered(cr, "", height, width);

			if (!(pencilMark is null))
				printPencilMark(cr, height, width);

			if (!(snyderNotation is null))
				printSnyderNotation(cr, height, width);

			return false;
		}
	}


	/** Prints pencilMark's digits
	 *
	 * This is used internaly by draw function
	 *
	 * Params:
	 *     cr = Cairo.Context
	 *     height = SudokuCell height
	 *     width = SudokuCell width
	 */
	private void printPencilMark(Context cr, double height, double width)
	{
		cr.setSourceRgb(digitColor.red, digitColor.green, digitColor.blue);
		cr.setFontSize(height * 0.15);
		string str = pencilMark.digits.join(" ");
		printCentered(cr, str, height, width);
	}


	/** Prints snyderNotation's digits
	 *
	 * This is used internaly by draw function
	 *
	 * Params:
	 *     cr = Cairo.Context
	 *     height = SudokuCell height
	 *     width = SudokuCell width
	 */
	private void printSnyderNotation(Context cr, double height, double width)
	{
		cr.setSourceRgb(digitColor.red, digitColor.green, digitColor.blue);
		cr.setFontSize(height * 0.15);
		string str = snyderNotation.digits.join(" ");
		printTopLeft(cr, str, height, width);
	}


	/** Prints text in the center position
	 *
	 * Used internaly by draw function
	 *
	 * This function was used from the *Gnome Sudoku* project
	 *
	 * Authors: GNOME staff
	 *
	 * Params:
	 *     cr = Cairo.Context
	 *     text = text to print
	 *     height = SudokuCell height
	 *     width = SudokuCell width
	 *
	 * See_Also: https://gitlab.gnome.org/GNOME/gnome-sudoku
	 */
	private void printCentered(Context cr, string text, double height, double width)
	{
		cairo_text_extents_t textExtents;
		cr.textExtents(text, &textExtents);

		cairo_font_extents_t fontExtents;
		cr.fontExtents(&fontExtents);

		cr.moveTo
		(
			(width - textExtents.width) / 2 - textExtents.xBearing,
			(height + fontExtents.height) / 2 - fontExtents.descent
		);

		cr.showText(text);
	}


	/** Prints text on the top left corner
	 *
	 * Params:
	 *     cr = Cairo.Context
	 *     text = text to print
	 *     height = SudokuCell height
	 *     width = SudokuCell width
	 */
	private void printTopLeft(Context cr, string text, double height, double width)
	{
		cairo_text_extents_t textExtents;
		cr.textExtents(text, &textExtents);

		cairo_font_extents_t fontExtents;
		cr.fontExtents(&fontExtents);

		cr.moveTo
		(
			width * 0.02,
			height * 0.15
		);

		cr.showText(text);
	}


	public void digit(int digit) @property
	{
		_digit = digit;
		queueDraw();
	}


	public auto digit() @property
	{
		return _digit;
	}


	public auto blocked() @property
	{
		return _blocked;
	}


	private SudokuBoard  board;
	private RGBA backgroundColor;

	private int _digit;
	private int maxDigit;
	private int row;
	private int column;
	private bool _blocked;
	private bool mouseHover;

	// notation which appears on the corners
	public SudokuHelper snyderNotation;

	// most known notation
	public SudokuHelper pencilMark;

	public bool selected;
	public bool highlighted;

	public RGBA digitColor;
	public RGBA selectedColorBg;
	public RGBA freeCellColor;
	public RGBA blockCellColor;

}
