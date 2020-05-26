module core.sudoku.grid;

import core.sudoku.box;
import core.sudoku.cell;

public class Grid
{
	public this(int height, int width, int boxHeight, int boxWidth)
	{
		this.height = height;
		this.width = width;
		this.boxHeight = boxHeight;
		this.boxWidth = boxWidth;

		boxes = new Box[][](boxWidth, boxHeight);
		cells = new Cell[][](height, width);

		for (int row; row < boxWidth; row++)
			for (int col; col < boxHeight; col++)
				boxes[row][col] = new Box(boxHeight, boxWidth);
	}


	public void initialize(int[][] digits)
	{
		for (int row; row < width; row++)
		{
			for (int col; col < height; col++)
			{
				cells[row][col] = new Cell(digits[row][col]);
			}
		}

		import std.array : array;
		import std.algorithm : map;

		// this must be inverted
		// a Sudoku of 6x6 is composed of a grid of 3x2 and boxes of 2x3
		// a Sudoku of 8x8 is composed of a grid of 4x2 and boxes of 2x4
		//     which means that the boxes inside the main grid are trasposed
		//     this is true to 4x4 and 9x9 as well (actualy it's true for all)
		for (int row; row < boxWidth; row++)
		{
			for (int col; col < boxHeight; col++)
			{
				auto cellRow = row*boxHeight;
				auto cellCol = col*boxWidth;
				Cell[][] _cells = cells.map!(x => x[cellCol .. cellCol + boxWidth])[cellRow .. cellRow + boxHeight].array;
				boxes[row][col].initialize(_cells);
			}
		}
	}


	/** Get all Cell digits
	 *
	 * Returns:
	 *     `int[][]` with all the current digits stored in each Cell
	 */
	public auto toDigit()
	{
		return toDigit(cells);
	}


	/** Get Cell digits
	 *
	 * Params:
	 *     cells = matrix of Cells to analyse
	 *
	 * Returns:
	 *     `int[][]` with the current digits stored in each Cell of cells
	 */
	public auto toDigit(Cell[][] cells)
	{
		import std.algorithm : map;
		import std.array : array;
		int[][] ret;
		for (int i; i < cells.length; i++)
		{
			ret ~= cells[i].map!(x => x.digit).array;
		}
		return ret;
	}


	/** Get Cell digits
	 *
	 * Params:
	 *     cells = array of Cells to analyse
	 *
	 * Returns:
	 *     `int[]` with the current digits stored in each Cell of cells
	 */
	public auto toDigit(Cell[] cells)
	{
		import std.algorithm : map;
		import std.array : array;
		return cells.map!(x => x.digit).array;
	}


	/** Get a Grid row
	 *
	 * Params:
	 *     index = row index
	 *
	 * Returns:
	 *     `Cell[]` with the Cells of row[index]
	 */
	public Cell[] row(in int index)
	in
	{
		assert(index >= 0 && index < width, "index out of bounds");
	}
	body
	{
		return cells[index];
	}


	/** Get a Grid column
	 *
	 * Params:
	 *     index = column index
	 *
	 * Returns:
	 *     `Cell[]` with the Cells of column[index]
	 */
	public Cell[] column(in int index)
	in
	{
		assert(index >= 0 && index < height, "index out of bounds");
	}
	body
	{
		import std.algorithm: map;
		import std.array: array;

		return cells.map!(x => x[index]).array;
	}


	/** Get a Grid box
	 *
	 * Params:
	 *     index = box index *from top left, to bottom right*
	 *
	 * Returns:
	 *     `Box`
	 */
	public Box box(in int index)
	in
	{
		assert(index >= 0 && index < width, "index out of bounds");
	}
	body
	{
		import std.array : join;
		return boxes.join[index];
	}


	/** Get the main diagonal
	 *
	 * Returns:
	 *     `Cell[]` with the Cells of the main diagonal
	 */
	public Cell[] mainDiagonal()
	{
		Cell[] ret;
		for (int i; i < width; i++)
		{
			ret ~= cells[i][i];
		}
		return ret;
	}


	/** Get the antidiagonal
	 *
	 * Returns:
	 *     `Cell[]` with the Cells of the antidiagonal
	 */
	public Cell[] antiDiagonal()
	{
		Cell[] ret;
		for (int i; i < width; i++)
		{
			ret ~= cells[i][width-i-1];
		}
		return ret;
	}


	/** Position of the next cell
	 *
	 * This is used internaly by the backtrackAlgorithm
	 *
	 * Params:
	 *     row = current row int the Grid
	 *     column = current column int the Grid
	 *
	 * Returns:
	 *     `tuple`***("row","column")*** with the position of the next Cell \
	 *     `tuple`***("row","column")(-1,-1)*** if params correspond to the last Cell
	 */
	public auto nextCell(int row, int column)
	{
		import std.typecons : tuple;

		// last cell of grid
		if (row == height - 1 && column == width - 1)
			return tuple!("row","column")(-1,-1);

		// last cell of column
		else if (column == width - 1)
			return tuple!("row","column")(row + 1, 0);

		// cell in the middle
		else
			return tuple!("row","column")(row, column + 1);
	}

	public int height;
	public int width;
	public int boxHeight;
	public int boxWidth;

	public Box[][] boxes;
	public Cell[][] cells;
}


version(unittest) { import aurorafw.unit; }

@("core:sudoku:grid: getters")
unittest
{
	Grid grid = new Grid(9,9,3,3);

	auto digits =  [[0, 0, 3, 2, 6, 0, 0, 0, 0],
					[0, 0, 7, 0, 0, 1, 0, 2, 3],
					[0, 8, 6, 0, 0, 0, 4, 0, 0],
					[5, 0, 0, 0, 0, 8, 0, 9, 0],
					[6, 4, 0, 3, 0, 7, 0, 1, 0],
					[0, 0, 0, 0, 0, 0, 0, 0, 5],
					[9, 2, 0, 0, 4, 0, 0, 0, 7],
					[0, 0, 0, 0, 0, 5, 9, 8, 0],
					[0, 0, 1, 6, 0, 0, 0, 3, 0]];

	grid.initialize(digits);

	auto b = grid.box(4);
	assertTrue(grid.toDigit(b.cells) ==    [[0, 0, 8],
											[3, 0, 7],
											[0, 0, 0]]);

	auto arr = grid.mainDiagonal();
	assertTrue(grid.toDigit(arr) == [0,0,6,0,0,0,0,8,0]);

	arr = grid.antiDiagonal();
	assertTrue(grid.toDigit(arr) == [0,2,4,8,0,0,0,0,0]);


	grid = new Grid(6,6,2,3);

	digits =   [[2, 0, 0, 0, 0, 0],
				[3, 0, 0, 4, 5, 2],
				[0, 5, 2, 3, 0, 6],
				[4, 6, 3, 0, 1, 0],
				[0, 2, 0, 0, 0, 4],
				[0, 0, 4, 5, 2, 0]];

	grid.initialize(digits);

	b = grid.box(1);
	assertTrue(grid.toDigit(b.cells) ==    [[0, 0, 0],
											[4, 5, 2]]);
}
