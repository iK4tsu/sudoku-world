module core.sudoku.box;

import core.sudoku.cell;

public class Box
{
	public this(int height, int width)
	{
		this.width = width;
		this.height = height;

		cells = new Cell[][](height, width);
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
		import std.array: join;
		return cells.join;
	}

	public int width;
	public int height;

	public Cell[][] cells;
}