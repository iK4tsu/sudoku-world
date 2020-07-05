module core.sudoku.box;

import core.sudoku.cell;
import core.sudoku.grid;

public class Box
{
	public this(in int rows, in int columns)
	{
		this.columns = columns;
		this.rows = rows;

		cells = new Cell[][](rows, columns);
	}


	public void initialize(Cell[][] cells)
	{
		this.cells = cells;
	}


	/** Converts Cell matrix to a Cell array
	 *
	 * Joins every Cell row in one
	 *
	 * Returns:
	 *     `Cell[]` with each Cell in cells
	 */
	public Cell[] toArray()
	{
		return Grid.toArray(cells);
	}


	/** Get Cell digits
	 *
	 * Params:
	 *     cells = matrix of Cells to analyse
	 *
	 * Returns:
	 *     `int[][]` with the current digits stored in each Cell of cells
	 */
	public int[][] toDigit()
	{
		return Grid.toDigit(cells);
	}

	public Cell[][] cells;
	public const int columns;
	public const int rows;
}


version(unittest) { import aurorafw.unit; }

version(unittest)
{
	Cell[][] cells = [[new Cell(0),new Cell(1)],[new Cell(2),new Cell(3)]];
}


@("core:sudoku:box: initialize")
unittest
{
	import std.algorithm : each;
	import std.range : join;

	Box box = new Box(2,2);

	box.cells.join.each!(cell => assertNull(cell));

	box.initialize(cells);

	box.cells.join.each!(cell => assertNotNull(cell));
	assertSame(box.cells, cells);
}

@("core:sudoku:box: toArray")
unittest
{
	import std.algorithm : equal;
	import std.range : join;

	Box box = new Box(2,2);
	box.initialize(cells);

	assertTrue(box.toArray().equal(cells.join));
}

@("core:sudoku:box: toDigit")
unittest
{
	import std.algorithm : each;
	import std.range : join;

	Box box = new Box(2,2);
	box.initialize(cells);

	box.toDigit.join.each!((i, ref digit) => assertEquals(digit, cells.join[i].digit));
}
