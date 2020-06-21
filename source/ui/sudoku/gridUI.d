module ui.sudoku.gridUI;

import std.algorithm : canFind;
import std.conv : to;
import std.experimental.logger;
import std.typecons : tuple;

import gtk.Builder;
import gtk.Grid;
import gtk.Label;
import gtk.StyleContext;

import core.sudoku.sudoku;
import core.rule.rule : RuleType;
import ui.sudoku.boxUI;
import ui.sudoku.cellUI;


// TODO: GridUI: implement game board
public class GridUI : Grid
{
	public this(SudokuType type)
	{
		setRowSpacing(4);
		setColumnSpacing(4);
		setRowHomogeneous(false);
		setColumnHomogeneous(false);

		setHalign(GtkAlign.CENTER);
		setValign(GtkAlign.CENTER);

		setSizeRequest(sizeRequest(type).expand);

		auto context = getStyleContext();
		context.addClass("sudoku");

		this._type = type;
		auto dimensions = Sudoku.dimension(type);
		setDimensions(dimensions.expand);
		buildBoxes(dimensions.boxRows, dimensions.boxColumns);

		showAll();
	}


	private void buildBoxes(int boxRows, int boxColumns)
	{
		// create boxes
		boxes = new Grid[][](boxColumns, boxRows);
		for (int y; y < boxCols; y++)
		{
			for (int x; x < boxRows; x++)
			{
				auto grid = new BoxUI(type);

				// top and bottom margins
				if (y == 0)
					grid.setMarginTop(4);
				if (y == boxCols - 1)
					grid.setMarginBottom(4);

				// left and right margins
				if (x == 0)
					grid.setMarginLeft(4);
				if (x == boxRows - 1)
					grid.setMarginRight(4);

				attach(grid, x, y, 1, 1);
				boxes[y][x] = grid;
			}
		}
	}


	public void buildCells(int[][] digits, int rows, int columns)
	{
		// all cells
		cells = new CellUI[][](rows, columns);
		for (int y; y < rows; y++)
		{
			for (int x; x < columns; x++)
			{
				auto cell = new CellUI(type, y, x, digits[y][x]);
				cells[y][x] = cell;
				boxes[y / boxRows][x / boxCols].attach(cell, x % boxCols, y % boxRows, 1, 1);
			}
		}
	}


	private auto sizeRequest(SudokuType type)
	{
		final switch(type)
		{
			case SudokuType.Sudoku_4X4:
			case SudokuType.Sudoku_6X6:
				return tuple(600,600);
			case SudokuType.Sudoku_9X9:
				return tuple(585,585);
		}
	}



// functions

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


	/** Updates the digit of all the focused cells
	 *
	 * If a cell is blocked it doesn't get updated
	 *
	 * Params:
	 *    digit = digit to insert
	 *
	 * Returns:
	 *     `CellUI[]` of all updated cells
	 */
	public CellUI[] cellHandleDigit(int digit)
	{
		CellUI[] ret;
		foreach (cell; focused)
		{
			if (!cell.isBlocked)
			{
				cell.digit = digit;
				ret ~= cell;
			}
		}
		return ret;
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



// getters/setters

	public auto boxCols() const @property
	{
		return _boxCols;
	}


	public auto boxRows() const @property
	{
		return _boxRows;
	}


	public auto cols() const @property
	{
		return _cols;
	}


	public auto rows() const @property
	{
		return _rows;
	}


	public auto type() const @property
	{
		return _type;
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
		auto cell = cells[row][column];
		cell.grabFocus();

		if (canFind(focused, cell))
			return;

		focused ~= cell;
		cell.selected = true;
	}


	/** Setter for all the board dimensions
	 *
	 * Params:
	 *     rows: height
	 *     cols: width
	 *     boxRows: box height
	 *     boxCols: box width
	 */
	private void setDimensions(int rows, int cols, int boxRows, int boxCols)
	in {
		assert(rows == cols, "rows must be equal to columns");
		assert(boxRows*boxCols == rows, "box area must be equal to rows and columns");
	}
	body
	{
		this._rows = rows;
		this._cols = cols;
		this._boxRows = boxRows;
		this._boxCols = boxCols;
	}


	private CellUI[] focused;
	private int _boxCols;
	private int _boxRows;
	private int _cols;
	private int _rows;
	private SudokuType _type;

	public CellUI[][] cells;
	public Grid[][] boxes;
}
