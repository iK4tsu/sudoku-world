module core.sudoku.box;

import std.array: join;

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
