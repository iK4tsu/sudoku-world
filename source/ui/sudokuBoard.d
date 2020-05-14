module ui.sudokuBoard;

import std.experimental.logger;

import gtk.Grid;
import gtk.StyleContext;

import core.sudokuType : SudokuType;
import ui.sudokuCell;

// TODO: SudokuBoard: implement game board
public class SudokuBoard : Grid
{
	public this(SudokuType type)
	{
		setRowSpacing(4);
		setColumnSpacing(4);
		setRowHomogeneous(false);
		setColumnHomogeneous(false);

		auto context = getStyleContext();
		context.addClass("sudoku");

		this.type = type;

		// create regions
		auto regions = new Grid[][](regionCols, regionRows);
		for (int y; y < regionCols; y++)
		{
			for (int x; x < regionRows; x++)
			{
				auto grid = new Grid();
				grid.setRowSpacing(1);
				grid.setColumnSpacing(1);
				grid.setRowHomogeneous(false);
				grid.setColumnHomogeneous(false);

				final switch (type)
				{
					case SudokuType.SUDOKU_4X4:
						setSizeRequest(300,300);
						break;

					case SudokuType.SUDOKU_6X6:
						setSizeRequest(300,200);
						break;

					case SudokuType.SUDOKU_9X9:
						setSizeRequest(195,195);
						break;
				}

				// top and bottom margins
				if (y == 0)                 grid.setMarginTop(4);
				if (y == regionCols - 1)    grid.setMarginBottom(4);

				// left and right margins
				if (x == 0)                 grid.setMarginLeft(4);
				if (x == regionRows - 1)    grid.setMarginRight(4);

				attach(grid, x, y, 1, 1);
				regions[y][x] = grid;
			}
		}

		// all cells
		cells = new SudokuCell[][](rows, cols);
		for (int y; y < rows; y++)
		{
			for (int x; x < cols; x++)
			{
				auto cell = new SudokuCell(this, y, x);
				cells[y][x] = cell;
				regions[y / regionRows][x / regionCols].attach(cell, x % regionCols, y % regionRows, 1, 1);
			}
		}

		showAll();
	}


	/** Set a cell to be focused
	 *
	 * Sets the Cell to be the one responding to keyboard events \
	 * It also adds the Cell to the group of focused Cells if it isn't already
	 *
	 * Params:
	 *     row = Cell row
	 *     column = Cell column
	 */
	public void setCellFocus(int row, int column)
	{
		import std.algorithm : canFind;

		auto cell = cells[row][column];
		cell.grabFocus();

		if (canFind(focused, cell))
			return;

		focused ~= cell;
		cell.selected = true;
	}


	/** Unfocus all cells
	 *
	 */
	public void cleanFocus()
	{
		foreach (cell; focused)
		{
			cell.selected = false;
			cell.queueDraw();
		}

		focused = [];
	}


	public auto type() @property
	{
		return _type;
	}


	// TODO: ui: sudokuBoard: make use of Sudoku.dimension()
	/** Setter
	 *
	 * Sets certains properties based on SudokuType
	 */
	private void type(SudokuType type) @property
	{
		_type = type;
		final switch (type)
		{
			case SudokuType.SUDOKU_4X4:
				rows = cols = 4;
				regionRows = regionCols = 2;
				setHalign(GtkAlign.CENTER);
				setValign(GtkAlign.CENTER);
				setSizeRequest(600, 600);
				break;

			case SudokuType.SUDOKU_6X6:
				rows = cols = 6;
				regionRows = 2;
				regionCols = 3;
				setHalign(GtkAlign.CENTER);
				setValign(GtkAlign.CENTER);
				setSizeRequest(600, 600);
				break;

			case SudokuType.SUDOKU_9X9:
				rows = cols = 9;
				regionRows = regionCols = 3;
				setHalign(GtkAlign.CENTER);
				setValign(GtkAlign.CENTER);
				setSizeRequest(585, 585);
				break;
		}
	}


	/** Fills the entire Grid with digits
	 *
	 * Used when the solving algorithm is called
	 *
	 * Params:
	 *     digits = matrix of digits
	 */
	public void fill(int[][] digits)
	{
		import std.conv : to;
		for (int i; i < rows; i++)
			for (int j; j < cols; j++)
				cells[i][j].digit = digits[i][j];
	}


	// TODO: ui:sudokuBoard: change function name to 'toDigits'
	/** Convert Grid Cells to digits
	 *
	 * Used when converting ui information to JSON file
	 *
	 * Params:
	 *     `int[][]` with every digit
	 */
	public int[][] toCells()
	{
		import std.conv : to;
		import std.array: empty;

		int[][] ret = new int[][](rows, cols);
		for (int y; y < rows; y++)
		{
			for (int x; x < cols; x++)
			{
				const string str = cells[y][x].digit.to!string;
				const int digit = str.empty ? 0 : str.to!int;
				ret[y][x] = digit;
			}
		}
		return ret;
	}


	/** Grid dimensions
	 *
	 * Used when converting ui information to JSON file
	 *
	 * Returns:
	 *     `tuple`***("rows","columns","regionRows","regionColumns")***
	 */
	public auto dimensions()
	{
		import std.typecons : tuple;
		return tuple!("rows","columns","regionRows","regionColumns")(rows,cols,regionRows,regionCols);
	}


	/** Updates the snyderNotation digit of all focused cells
	 *
	 */
	public void cellHandleSnyderNotation(string digit)
	{
		foreach (cell; focused)
		{
			cell.snyderNotation.handle(digit);
			cell.queueDraw();
		}
	}


	/** Updates the pencilMark digit of all focused cells
	 *
	 */
	public void cellHandlePencilMark(string digit)
	{
		foreach (cell; focused)
		{
			cell.pencilMark.handle(digit);
			cell.queueDraw();
		}
	}


	/** Updates the digit of all the focused cells
	 *
	 */
	public void cellHandleDigit(int digit)
	{
		foreach (cell; focused)
		{
			cell.digit = digit;
		}
	}


	/** Resets the snyderNotation of all the focused cells
	 *
	 */
	public void cellClearSnyderNotation()
	{
		foreach (cell; focused)
		{
			cell.snyderNotation.clear();
			cell.queueDraw();
		}
	}


	/** Resets the pencilMark of all the focused cells
	 *
	 */
	public void cellClearPencilMark()
	{
		foreach (cell; focused)
		{
			cell.pencilMark.clear();
			cell.queueDraw();
		}
	}


	// TODO: ui: sudokuBoard: change region to box
	public int rows;
	public int cols;
	public int regionRows;
	public int regionCols;

	private SudokuType _type;
	private SudokuCell[][] cells;
	public SudokuCell[] focused;
}
