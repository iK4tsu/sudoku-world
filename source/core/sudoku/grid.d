module core.sudoku.grid;

import std.typecons : Tuple;

import core.sudoku.box;
import core.sudoku.cell;

public enum SudokuType
{
	Sudoku4x4,
	Sudoku6x6,
	Sudoku9x9,
}

public class Grid
{
	///
	public this(in SudokuType type)
	{
		this.type = type;
		const auto dim = dimensions(type);
		this.rows = dim.rows;
		this.columns = dim.columns;
		this.boxRows = dim.boxRows;
		this.boxColumns = dim.boxColumns;

		buildGrid();
	}


	private void buildGrid()
	{
		boxes = new Box[][](boxColumns, boxRows);
		cells = new Cell[][](rows, columns);

		for (int row; row < boxColumns; row++)
			for (int col; col < boxRows; col++)
				boxes[row][col] = new Box(boxRows, boxColumns);
	}


	/** Standard Sudoku dimensions
	 *
	 * Params:
	 *     type = SudokuType to process
	 *
	 * Returns: `tuple`***("rows","columns","boxRows","boxColumns")*** with the
	 *     dimensions of SudokuType
	 */
	public static Tuple!(int,"rows",
							int,"columns",
							int,"boxRows",
							int,"boxColumns")
	dimensions(in SudokuType type)
	{
		import std.typecons : tuple;

		final switch (type)
		{
			case SudokuType.Sudoku4x4:
				return tuple!("rows","columns","boxRows","boxColumns")(4,4,2,2);

			case SudokuType.Sudoku6x6:
				return tuple!("rows","columns","boxRows","boxColumns")(6,6,2,3);

			case SudokuType.Sudoku9x9:
				return tuple!("rows","columns","boxRows","boxColumns")(9,9,3,3);
		}
	}


	/** Get the Grid dimensions
	 *
	 * Returns: `tuple`***("rows","columns","boxRows","boxColumns")***
	 */
	public Tuple!(const int,"rows",
					const int,"columns",
					const int,"boxRows",
					const int,"boxColumns")
	dimensions() const
	{
		import std.typecons : tuple;
		return tuple!("rows","columns","boxRows","boxColumns")(rows,columns,boxRows,boxColumns);
	}


	/** Initialize every Cell to 0
	 *
	 * Creates a matrix of [`rows`][`columns`] size
	 *
	 * See_Also: void initialize(**int[][] digits**)
	 */
	public void initialize()
	{
		initialize(new int[][](rows, columns));
	}


	/** Initialize Cells to digits
	 *
	 * Be sure to pass a matrix of at least [`rows`][`columns`] in size \
	 * Only `rows*columns` will be read from digits starting from [0][0]
	 *
	 * Params:
	 *     digits: matrix with the data to initialize
	 */
	public void initialize(in int[][] digits)
	{
		import std.algorithm : map;
		import std.array : array;

		for (int row; row < columns; row++)
		{
			for (int col; col < rows; col++)
			{
				cells[row][col] = new Cell(digits[row][col]);
			}
		}

		// this must be inverted
		// a Sudoku of 6x6 is composed of a grid of 3x2 and boxes of 2x3
		// a Sudoku of 8x8 is composed of a grid of 4x2 and boxes of 2x4
		//     which means that the boxes inside the main grid are trasposed
		//     this is true to 4x4 and 9x9 as well (actualy it's true for all)
		for (int row; row < boxColumns; row++)
		{
			for (int col; col < boxRows; col++)
			{
				auto cellRow = row*boxRows;
				auto cellCol = col*boxColumns;
				Cell[][] _cells = cells.map!(x => x[cellCol .. cellCol + boxColumns])[cellRow .. cellRow + boxRows].array;
				boxes[row][col].initialize(_cells);
			}
		}
	}


	/** Get all Cell digits
	 *
	 * Returns:
	 *     `int[][]` with all the current digits stored in each Cell
	 */
	public int[][] toDigit()
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
	public static int[][] toDigit(Cell[][] cells)
	{
		import std.algorithm : map;
		import std.array : array;

		return cells.map!(row => row.map!(cell => cell.digit).array).array;
	}


	/** Get Cell digits
	 *
	 * Params:
	 *     cells = array of Cells to analyse
	 *
	 * Returns:
	 *     `int[]` with the current digits stored in each Cell of cells
	 */
	public static int[] toDigit(Cell[] cells)
	{
		import std.algorithm : map;
		import std.array : array;

		return cells.map!(cell => cell.digit).array;
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
		assert(index >= 0 && index < columns, "index out of bounds");
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
		assert(index >= 0 && index < rows, "index out of bounds");
	}
	body
	{
		import std.array : array;
		import std.range : transversal;

		return transversal(cells, index).array;
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
		assert(index >= 0 && index < columns, "index out of bounds");
	}
	body
	{
		import std.range : join;

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
		foreach (i; 0..rows)
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
		for (int i; i < columns; i++)
		{
			ret ~= cells[i][columns-i-1];
		}
		return ret;
	}


	/** Get the Cell contained in the correspondent coordenates
	 *
	 * Params:
	 *     row: row in the matrix
	 *     column: column in the matrix
	 *
	 * See_Also: auto opIndex(**int row, int column**)
	 */
	public Cell cell(in int row, in int column)
	{
		return cells[row][column];
	}


	/** Get the Cell contained in the correspondent coordenates
	 *
	 * Params:
	 *     row: row in the matrix
	 *     column: column in the matrix
	 *
	 * Examples:
	 * --------------------
	 * Grid grid = new Grid(SudokuType.Sudoku4x4);
	 * grid.initialize();
	 * Cell cell = grid[0,0];
	 * --------------------
	 */
	public auto opIndex(in int row, in int column)
	{
		return cell(row, column);
	}


	/** Converts Cell matrix to a Cell array
	 *
	 * Concatenates each Cell row
	 *
	 * Returns:
	 *     `Cell[]` with each Cell in cells
	 */
	public Cell[] toArray()
	{
		return toArray(cells);
	}


	public static Cell[] toArray(Cell[][] cells)
	{
		import std.range : join;

		return cells.join;
	}


	/** Get the transposed Cells
	 *
	 * Returns:
	 *     `Cell[][]`
	 */
	public Cell[][] transposed()
	{
		import std.array : array;
		import std.range : transversal;

		Cell[][] ret;
		foreach (i; 0..rows)
		{
			ret ~= transversal(cells, i).array;
		}
		return ret;
	}



	public Box[][] boxes;
	public Cell[][] cells;
	public const SudokuType type;
	public const int rows;
	public const int columns;
	public const int boxRows;
	public const int boxColumns;
}


version(unittest) { import aurorafw.unit; }
version(unittest)
{
	import std.algorithm : each, equal, reverse;
	int[][] digits4x4 =    [[1, 0, 0, 3],
							[0, 2, 1, 4],
							[4, 0, 0, 2],
							[0, 3, 4, 1]];

	int[][] transposed4x4 =    [[1, 0, 4, 0],
								[0, 2, 0, 3],
								[0, 1, 0, 4],
								[3, 4, 2, 1]];

	int[][] digits6x6 =    [[2, 0, 0, 0, 0, 0],
							[3, 0, 0, 4, 5, 2],
							[0, 5, 2, 3, 0, 6],
							[4, 6, 3, 0, 1, 0],
							[0, 2, 0, 0, 0, 4],
							[0, 0, 4, 5, 2, 0]];

	int[][] digits9x9 =    [[0, 0, 3, 2, 6, 0, 0, 0, 0],
							[0, 0, 7, 0, 0, 1, 0, 2, 3],
							[0, 8, 6, 0, 0, 0, 4, 0, 0],
							[5, 0, 0, 0, 0, 8, 0, 9, 0],
							[6, 4, 0, 3, 0, 7, 0, 1, 0],
							[0, 0, 0, 0, 0, 0, 0, 0, 5],
							[9, 2, 0, 0, 4, 0, 0, 0, 7],
							[0, 0, 0, 0, 0, 5, 9, 8, 0],
							[0, 0, 1, 6, 0, 0, 0, 3, 0]];
}

@("core:sudoku:grid: box")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku9x9);
	grid.initialize(digits9x9);

	Box b = grid.box(4);

	assertSame(b, grid.boxes[1][1]);
	assertTrue(grid.toDigit(b.cells).equal([[0,0,8],
											[3,0,7],
											[0,0,0]]));

}

@("core:sudoku:grid: cell")
unittest
{
	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize(digits4x4);

	assertSame(grid[0,0], grid.cells[0][0]);
	assertSame(grid.cell(0,0), grid.cells[0][0]);
}

@("core:sudoku:grid: columns")
unittest
{
	import std.algorithm : each, equal;
	import std.range : transposed;

	Grid grid = new Grid(SudokuType.Sudoku6x6);
	grid.initialize(digits6x6);

	grid.transposed().each!((i, ref row) => assertTrue(row.equal(grid.column(cast(int) i))));
	assertTrue(grid.toDigit(grid.column(0)).equal([2,3,0,4,0,0]));
}

@("core:sudoku:grid: diagonals")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize(digits4x4);

	Cell[] main = [grid[0,0],grid[1,1],grid[2,2],grid[3,3]];
	Cell[] anti = [grid[0,3],grid[1,2],grid[2,1],grid[3,0]];

	assertTrue(grid.mainDiagonal().equal(main));
	assertTrue(grid.antiDiagonal().equal(anti));
	assertTrue(grid.toDigit(grid.mainDiagonal()).equal([1,2,0,1]));
	assertTrue(grid.toDigit(grid.antiDiagonal()).equal([3,1,0,0]));
}

@("core:sudoku:grid: dimensions")
unittest
{
	Grid grid = new Grid(SudokuType.Sudoku4x4);

	auto dim = grid.dimensions();
	auto dim_ = Grid.dimensions(SudokuType.Sudoku4x4);

	assertEquals(dim, dim_);
}

@("core:sudoku:grid: initialize")
unittest
{
	Grid grid = new Grid(SudokuType.Sudoku4x4);

	assertNull(grid.cells[0][0]);

	grid.initialize(digits4x4);

	assertNotNull(grid.cells[0][0]);
	assertEquals(grid.cells[0][0].digit, 1);
}

@("core:sudoku:grid: rows")
unittest
{
	import std.algorithm : each, equal;

	Grid grid = new Grid(SudokuType.Sudoku6x6);
	grid.initialize(digits6x6);

	grid.cells.each!((i, ref row) => assertTrue(row.equal(grid.row(cast(int) i))));
	assertTrue(grid.toDigit(grid.row(0)).equal([2,0,0,0,0,0]));
}

@("core:sudoku:grid: toArray")
unittest
{
	import std.algorithm : equal;
	import std.range : join;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize(digits4x4);

	Cell[] cells = join(grid.cells[0 .. $]);

	assertTrue(grid.toArray().equal(cells));
	assertTrue(Grid.toDigit(grid.toArray()).equal([1,0,0,3,0,2,1,4,4,0,0,2,0,3,4,1]));
}

@("core:sudoku:grid: toDigit")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku9x9);
	grid.initialize(digits9x9);

	assertTrue(grid.toDigit().equal(digits9x9));
	assertTrue(Grid.toDigit(grid.cells).equal(digits9x9));
}

@("core:sudoku:grid: transposed")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize(digits4x4);

	assertTrue(Grid.toDigit(grid.transposed()).equal(transposed4x4));
}
