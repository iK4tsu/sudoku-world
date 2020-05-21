module ui.sudokuBoard;

import std.experimental.logger;

import gtk.Grid;
import gtk.StyleContext;

import core.sudokuType : SudokuType;
import core.ruleType : RuleType;
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
		this.rules = [RuleType.CLASSIC];

		// create boxes
		auto boxes = new Grid[][](boxCols, boxRows);
		for (int y; y < boxCols; y++)
		{
			for (int x; x < boxRows; x++)
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
				if (y == boxCols - 1)    grid.setMarginBottom(4);

				// left and right margins
				if (x == 0)                 grid.setMarginLeft(4);
				if (x == boxRows - 1)    grid.setMarginRight(4);

				attach(grid, x, y, 1, 1);
				boxes[y][x] = grid;
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
				boxes[y / boxRows][x / boxCols].attach(cell, x % boxCols, y % boxRows, 1, 1);
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
				boxRows = boxCols = 2;
				setHalign(GtkAlign.CENTER);
				setValign(GtkAlign.CENTER);
				setSizeRequest(600, 600);
				break;

			case SudokuType.SUDOKU_6X6:
				rows = cols = 6;
				boxRows = 2;
				boxCols = 3;
				setHalign(GtkAlign.CENTER);
				setValign(GtkAlign.CENTER);
				setSizeRequest(600, 600);
				break;

			case SudokuType.SUDOKU_9X9:
				rows = cols = 9;
				boxRows = boxCols = 3;
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
	public void fill(int[][] digits, bool solution = false)
	{
		import std.conv : to;
		for (int i; i < rows; i++)
			for (int j; j < cols; j++)
			{
				cells[i][j].digit = digits[i][j];
				if (solution && digits[i][j])
					cells[i][j].blocked = true;
			}
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
	 *     `tuple`***("rows","columns","boxRows","boxColumns")***
	 */
	public auto dimensions()
	{
		import std.typecons : tuple;
		return tuple!("rows","columns","boxRows","boxColumns")(rows,cols,boxRows,boxCols);
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


	/** Check if all the cells are filled
	 *
	 * Returns:
	 *     `true` if every Cell has a valid digit \
	 *     `false` otherwise
	 */
	public bool complete()
	{
		for (int i; i < rows; i++)
			for (int j; j < cols; j++)
				if (!cells[i][j].digit)
					return false;

		return true;
	}


	public void addRule(string rule)
	in {
		import std.algorithm : canFind;
		assert(!canFind(rules, rule));
	}
	body
	{
		rules ~= rule;
		trace("Added RULE: ", rule);
	}


	public void removeRule(string rule)
	in {
		import std.algorithm : canFind;
		assert(canFind(rules, rule));
	}
	body
	{
		import std.algorithm : remove;
		rules = remove!(a => a == rule)(rules);
		trace("Removed RULE: ", rule);
	}


	public int rows;
	public int cols;
	public int boxRows;
	public int boxCols;

	private SudokuType _type;
	private SudokuCell[][] cells;
	public SudokuCell[] focused;
	public string[] rules;
}
