module ui.sudokuBoard;

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
		auto regions = new Grid[][](regionRows, regionCols);
		for (int y; y < regionRows; y++)
		{
			for (int x; x < regionCols; x++)
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
				if (y == regionRows - 1)    grid.setMarginBottom(4);

				// left and right margins
				if (x == 0)                 grid.setMarginLeft(4);
				if (x == regionCols - 1)    grid.setMarginRight(4);

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
				auto cell = new SudokuCell(this, y, x, type);
				cells[y][x] = cell;
				regions[y / regionCols][x / regionRows].attach(cell, x % regionRows, y % regionCols, 1, 1);
			}
		}

		showAll();
	}

	/** Change the focused cell
	 *
	 * This is used internaly by SudokuCell on the KeyPress Event
	 */
	public void setCellFocus(int row, int column)
	{
		cells[row][column].grabFocus();
	}

	public auto type() @property
	{
		return _type;
	}

	// FIXME: ui: sudokuBoard: swap SUDOKU_6X6 region dimensions
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
				regionRows = 3;
				regionCols = 2;
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

	public int[][] toCells()
	{
		import std.conv : to;
		import std.array: empty;

		int[][] ret = new int[][](rows, cols);
		for (int y; y < rows; y++)
		{
			for (int x; x < cols; x++)
			{
				const string str = cells[y][x].getText();
				const int digit = str.empty ? 0 : str.to!int;
				ret[y][x] = digit;
			}
		}
		return ret;
	}

	public auto dimensions()
	{
		import std.typecons : tuple;
		return tuple!("rows","columns","regionRows","regionColumns")(rows,cols,regionRows,regionCols);
	}

	// TODO: ui: sudokuBoard: change region to box
	public int rows;
	public int cols;
	public int regionRows;
	public int regionCols;

	private SudokuType _type;
	private SudokuCell[][] cells;
}
