module core.constraint.unique;

import std.algorithm : canFind, map;

import core.constraint.constraint;
import core.sudoku.cell;

/** Unique constraint
 *
 * Each Cell must be unique, no other Cell can have the same digit,
 *     in a given Cell[]
 */
public class UniqueConstraint : Constraint
{
	public this(Cell[] cells...)
	{
		foreach (cell; cells)
		{
			connect(cell);
		}
	}


	/** Connect a Cell to this Constraint
	 *
	 * Params:
	 *     cell = Cell to connect
	 */
	override
	public void connect(Cell cell)
	{
		if (cell is null || canFind(cells, cell))
			return;

		cells ~= cell;
		cell.connect(this);
	}

	/** Search for the same digit
	 *
	 * Used to find if the digit being inserted to a Cell is unique in a
	 *     group of cells
	 *
	 * Params:
	 *     digit = value to check
	 *
	 * Returns:
	 *     `true` if the value is unique \
	 *     `false` otherwise
	 */
	override
	public bool isValid(in int digit)
	{
		return !canFind(cells.map!(x => x.digit), digit);
	}

	public Cell[] cells;
}


version(unittest) { import aurorafw.unit; }

@("core:constraint:unique: ctor")
unittest
{
	Cell[] cells = [new Cell(4), new Cell(0)];
	auto constraint = new UniqueConstraint(cells);

	assertTrue(constraint.isValid(2));
	assertFalse(constraint.isValid(4));
}


@("core:constraint:unique: connect")
unittest
{
	Cell[] cells = [new Cell(4), new Cell(0)];
	auto constraint = new UniqueConstraint(cells);

	Cell cell = new Cell(2);
	constraint.connect(cell);

	assertTrue(canFind(constraint.cells, cell));
	assertTrue(constraint.isValid(1));
	assertFalse(constraint.isValid(2));

}
