module ui.sudoku.cellUI;

import std.algorithm : mean;
import std.array : join;
import std.conv : ConvException, to;
import std.experimental.logger;
import std.typecons : Tuple, tuple;

import cairo.Context;
import cairo.c.types;

import gdk.Device;
import gdk.DragContext;
import gdk.Event;
import gdk.Keymap;
import gdk.RGBA;
import gdk.Seat;

import gtk.Builder;
import gtk.DrawingArea;
import gtk.Label;
import gtk.Stack;
import gtk.Widget;

import core.sudoku.cell;
import core.sudoku.grid : SudokuType;
import ui.sudoku.gridUI;
import ui.sudoku.sudokuHelper;


public enum Color : Tuple!(double, double, double)
{
	DIGIT         = Color(0.957,0.263,0.212),
	DIGIT_BLOCKED = Color(0.000,0.000,0.000),
	SELECTED      = Color(0.961,0.876,0.702),
	FREE_CELL     = Color(0.267,0.282,0.298),
	BLOCKED_CELL  = Color(0.227,0.243,0.259),
}


public class CellUI : DrawingArea
{
	public this(SudokuType type, int row, int column, int digit, int maxDigit)
	{
		setHalign(GtkAlign.CENTER);
		setValign(GtkAlign.CENTER);
		setSizeRequest(sizeRequest(type).expand);

		setVisible(true);
		setCanFocus(true);
		setSensitive(true);

		pencilMark = new SudokuHelper();
		snyderNotation = new SudokuHelper();

		digitColor        = toRGB(Color.DIGIT.expand);
		digitBlockedColor = toRGB(Color.DIGIT_BLOCKED.expand);
		selectedColorBg   = toRGB(Color.SELECTED.expand);
		freeCellColor     = toRGB(Color.FREE_CELL.expand);
		blockCellColor    = toRGB(Color.BLOCKED_CELL.expand);

		this._row = row;
		this._column = column;
		this._maxDigit = maxDigit;
		this._digit = digit;
		this._isBlocked = _digit != 0;
	}


	private auto sizeRequest(SudokuType type)
	{
		final switch(type)
		{
			case SudokuType.Sudoku4x4: return tuple(150,150);
			case SudokuType.Sudoku6x6: return tuple(100,100);
			case SudokuType.Sudoku9x9: return tuple(65,65);
		}
	}



// functions


	public RGBA mixColors(RGBA color1, RGBA color2)
	{
		auto r = mean([color1.red, color2.red]);
		auto g = mean([color1.green, color2.green]);
		auto b = mean([color1.blue, color2.blue]);
		return new RGBA(r,g,b);
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
	public void printCentered(Context cr, string text, double height, double width)
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


	/** Prints pencilMark's digits
	 *
	 * This is used internaly by draw function
	 *
	 * Params:
	 *     cr = Cairo.Context
	 *     height = SudokuCell height
	 *     width = SudokuCell width
	 */
	public void printPencilMark(Context cr, double height, double width)
	{
		cr.setSourceRgb(Color.DIGIT.expand);
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
	public void printSnyderNotation(Context cr, double height, double width)
	{
		cr.setSourceRgb(Color.DIGIT.expand);
		cr.setFontSize(height * 0.15);
		string str = snyderNotation.digits.join(" ");
		printTopLeft(cr, str, height, width);
	}


	/** Prints text on the top left corner
	 *
	 * Params:
	 *     cr = Cairo.Context
	 *     text = text to print
	 *     height = SudokuCell height
	 *     width = SudokuCell width
	 */
	public void printTopLeft(Context cr, string text, double height, double width)
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


	/** RGB color
	 *
	 * Params:
	 *     r = red color
	 *     g = green color
	 *     b = blue color
	 *
	 * Returns:
	 *     `RGBA` class with a color corresponding to the values passed
	 */
	private RGBA toRGB(double r, double g, double b)
	{
		return new RGBA(r,g,b);
	}



// getters/setters

	public auto column() const @property
	{
		return _column;
	}


	public auto digit() const @property
	{
		return _digit;
	}


	public auto isBlocked() const @property
	{
		return _isBlocked;
	}


	public auto maxDigit() const @property
	{
		return _maxDigit;
	}


	public auto row() const @property
	{
		return _row;
	}


	public void digit(int digit) @property
	{
		_digit = digit;
		queueDraw();
	}


	private int _maxDigit;
	private int _row;
	private int _column;
	private int _digit;
	private bool _isBlocked = false;

	// notation which appears on the corners
	public SudokuHelper snyderNotation;

	// most known notation
	public SudokuHelper pencilMark;

	public bool selected;
	public bool highlighted;

	// FIXME: ui:cellUI: change to Color when the current bug is fixed
	public RGBA backgroundColor;
	public RGBA blockCellColor;
	public RGBA digitBlockedColor;
	public RGBA digitColor;
	public RGBA foregroundColor;
	public RGBA freeCellColor;
	public RGBA selectedColorBg;
}
