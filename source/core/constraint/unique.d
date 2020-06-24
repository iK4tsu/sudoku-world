module core.constraint.unique;

import std.algorithm : canFind, map;
import std.typecons : tuple;

import core.constraint.constraint;
import core.sudoku.cell;

/** Unique constraint
 *
 * Each Cell must be unique, no other Cell can have the same digit,
 *     in a given Cell[]
 */
public class UniqueConstraint : Constraint
{
	private this(Cell cell)
	{
		super (ConstraintType.Unique);
		this.cells ~= cell;
	}


	/** Connects two Cells
	 *
	 * Ensures `cell1` is connected to `cell2` and vice-versa \
	 * This means when a digit is checked for it's availability in `cell1`
	 *     the validation is dependent of the digit in `cell2` and vice-versa \
	 * A Cell cannot connect to itself \
	 * Null values are not processed
	 *
	 * Params:
	 *     cell1 = cell to connect
	 *     cell2 = cell to connect
	 *
	 * Examples:
	 * --------------------
	 * Cell cell1 = new Cell(0);
	 * Cell cell2 = new Cell(0);
	 * UniqueConstraint.createSingle(cell1,cell2);
	 * assert(cell1.get!UniqueConstraint.cells.equal([cell2]));
	 * assert(cell2.get!UniqueConstraint.cells.equal([cell1]));
	 * --------------------
	 */
	public static void createSingle(Cell cell1, Cell cell2)
	{
		if (cell1 is null || cell2 is null || cell1 == cell2)
			return;

		UniqueConstraint uc1 = new UniqueConstraint(cell2);
		uc1.connect(cell1);
		UniqueConstraint uc2 = new UniqueConstraint(cell1);
		uc2.connect(cell2);
	}


	/** Connects a Cell to a group of Cells
	 *
	 * Ensures `cell` is connected to `cells` and that each Cell in `cells` is
	 *     connected to `cell` \
	 * A Cell cannot connect to itself \
	 * Null values are not processed
	 *
	 * Params:
	 *     cell = cell to connect
	 *     cells = cells to be connected
	 *
	 * SeeAlso: void createSingle(**cell1**,**cell2**)
	 */
	public static void createMultiSingle(Cell cell, Cell[] cells...)
	{
		if (cell is null)
			return;

		foreach (Cell c; cells)
		{
			if (c is null)
				continue;

			if (c != cell)
				createSingle(cell, c);
		}
	}


	/** Connects group of Cells to each other
	 *
	 * Ensures all Cells in 'cells' are connected to each other \
	 * A Cell cannot connect to itself \
	 * Null values are not processed
	 *
	 * Params:
	 *     cells = cells to connect to each other
	 *
	 * SeeAlso: void createSingle(**cell1**,**cell2**)
	 */
	public static void createInterconnected(Cell[] cells...)
	{
		import std.array : array;
		import std.algorithm : filter;
		if (canFind(cells, null))
		{
			cells = cells.filter!(cell => cell !is null).array;
		}

		foreach (Cell cell; cells)
		{
			createMultiSingle(cell, cells);
		}
	}


	/** Removes a connection between two Cells
	 *
	 * A Cell cannot disconnect from itself \
	 * Null values are not processed
	 *
	 * Params:
	 *     cell1 = cell to disconnect
	 *     cell2 = cell to disconnect
	 */
	public static void removeSingle(Cell cell1, Cell cell2)
	{
		if (cell1 is null || cell2 is null || cell1 == cell2)
			return;

		cell1.disconnect!UniqueConstraint(cell2);
		cell2.disconnect!UniqueConstraint(cell1);
	}


	/** Removes a connection between a Cell and a group of Cells
	 *
	 * A Cell cannot disconnect from itself \
	 * Null values are not processed
	 *
	 * Params:
	 *     cell = cell to disconnect
	 *     cells = cells to disconnect from
	 */
	public static void removeMultiSingle(Cell cell, Cell[] cells...)
	{
		foreach (c; cells)
		{
			if (c is null)
				continue;

			if (c != cell)
				removeSingle(cell, c);
		}
	}


	/** Removes a connection between Cells
	 *
	 * A Cell cannot disconnect from itself \
	 * Null values are not processed
	 *
	 * Params:
	 *     cells = cells to disconnect from each other
	 */
	public static void removeInterconnected(Cell[] cells...)
	{
		import std.array : array;
		import std.algorithm : filter;
		if (canFind(cells, null))
		{
			cells = cells.filter!(cell => cell !is null).array;
		}

		foreach (Cell cell; cells)
		{
			removeMultiSingle(cell, cells);
		}
	}


	/** Removes a UniqueConstraint from a Cell
	 *
	 * Ensures all Cells connected to `cell` are disconnected from it aswell
	 *
	 * Params:
	 *     cell = cell to remove UniqueConstraint
	 */
	public static void takeOut(Cell cell)
	{
		foreach (c; cell.get!UniqueConstraint.cells)
		{
			removeSingle(c, cell);
		}
	}


	@safe pure
	public static ConstraintType getStaticConstraintType()
	{
		return ConstraintType.Unique;
	}


	/** Connect a Cell to this Constraint
	 *
	 * Params:
	 *     cell = Cell to connect
	 */
	override
	public void connect(Cell cell)
	{
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
}


version(unittest)
{
	import aurorafw.unit;
	import std.algorithm : equal;
}

@("core:constraint:unique: ctor")
unittest
{
	Cell[] cells = [new Cell(4), new Cell(0)];
	UniqueConstraint.createInterconnected(cells);

	UniqueConstraint constraint = cells[0].get!UniqueConstraint;
	assertTrue(constraint !is null);
	assertTrue(constraint.isValid(4));
	assertFalse(constraint.isValid(0));
}


@("core:constraint:unique: connect")
unittest
{
	Cell[] cells = [new Cell(4), new Cell(0)];
	UniqueConstraint.createInterconnected(cells);

	Cell cell = new Cell(2);
	UniqueConstraint.createMultiSingle(cell, cells);

	UniqueConstraint uc0 = cells[0].get!UniqueConstraint;
	assertTrue(canFind(uc0.cells, cell));
	assertTrue(uc0.isValid(1));
	assertFalse(uc0.isValid(2));

	UniqueConstraint uc1 = cells[1].get!UniqueConstraint;
	UniqueConstraint uc2 = cell.get!UniqueConstraint;
	assertTrue(uc0 != uc1 && uc1 != uc2);


	assertFalse(uc0.cells.equal(uc1.cells));
	assertTrue(uc0.cells.equal(cells[1..$] ~ cell));
}


@("core:constraint:unique: createSingle")
unittest
{
	import std.algorithm : filter;
	Cell[] cells = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createSingle(cells[0], cells[1]);

	UniqueConstraint uc0 = cells[0].get!UniqueConstraint;
	UniqueConstraint uc1 = cells[1].get!UniqueConstraint;
	UniqueConstraint uc2 = cells[2].get!UniqueConstraint;

	assertTrue(uc0.cells.equal([cells[1]]));
	assertTrue(uc1.cells.equal([cells[0]]));
	assertTrue(uc2 is null);

	UniqueConstraint.createSingle(cells[1], cells[2]);
	uc2 = cells[2].get!UniqueConstraint;
	assertTrue(uc1.cells.equal(cells.filter!(c => c != cells[1])));
	assertTrue(uc2.cells.length == uc0.cells.length);
}


@("core:constraint:unique: createMultiSingle")
unittest
{
	import core.sudoku.grid : Grid;
	Cell[] cells1 = [new Cell(2), new Cell(3), new Cell(5)];
	Cell[] cells2 = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createMultiSingle(cells1[0], cells1[0 .. $]);
	UniqueConstraint.createMultiSingle(cells2[0], cells2[1 .. $]);

	UniqueConstraint uc1 = cells1[0].get!UniqueConstraint;
	UniqueConstraint uc2 = cells2[0].get!UniqueConstraint;

	assertTrue(Grid.toDigit(uc1.cells).equal(Grid.toDigit(uc2.cells)));
	assertTrue(uc1.cells.length == 2);

	UniqueConstraint uc3 = cells1[1].get!UniqueConstraint;
	assertTrue(uc3.cells.equal([cells1[0]]));

	UniqueConstraint.createMultiSingle(cells1[0], new Cell(6), new Cell(7));
	assertTrue(uc1.cells.length == 4);
}


@("core:constraint:unique: createInterconnected")
unittest
{
	import std.range : back;
	Cell[] cells1 = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createInterconnected(cells1);

	UniqueConstraint uc0 = cells1[0].get!UniqueConstraint; // [3,5]
	UniqueConstraint uc1 = cells1[1].get!UniqueConstraint; // [2,5]
	UniqueConstraint uc2 = cells1[2].get!UniqueConstraint; // [2,3]

	assertFalse(uc0.cells.equal(uc1.cells));
	assertTrue(uc2.cells == [cells1[0],cells1[1]]);

	UniqueConstraint.createInterconnected(cells1 ~ new Cell(7));

	assertTrue(uc0.cells.length == 3);
	assertTrue(uc0.cells.back == uc1.cells.back); // [...,7]

	Cell cell = new Cell(10);
	UniqueConstraint.createInterconnected(cell ~ cells1[0 .. 2]);

	assertTrue(uc0.cells.length == uc1.cells.length); // 4
	assertFalse(uc0.cells.length == uc2.cells.length); // 4 != 3
	assertTrue(cell.get!UniqueConstraint.cells.equal(cells1[0 .. 2]));
}


@("core:constraint:unique: removeSingle")
unittest
{
	import std.range : front;
	Cell cell = new Cell(0);
	Cell[] cells = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createMultiSingle(cell, cells);
	UniqueConstraint.removeSingle(cell, cells.front);

	assertTrue(cell.get!UniqueConstraint.cells.equal(cells[1..$]));
	assertTrue(cells.front.get!UniqueConstraint is null);
}


@("core:constraint:unique: removeMultiSingle")
unittest
{
	import std.range : front;
	Cell cell = new Cell(0);
	Cell[] cells = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createMultiSingle(cell, cells);
	UniqueConstraint.removeMultiSingle(cell, cells);

	assertTrue(cell.get!UniqueConstraint is null);
	assertTrue(cells.front.get!UniqueConstraint is null);
}


@("core:constraint:unique: removeInterconnected")
unittest
{
	import std.algorithm : each;
	import std.range : back, front;
	Cell cell = new Cell(0);
	Cell[] cells = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createInterconnected(cell ~ cells);
	UniqueConstraint.removeInterconnected(cells);

	assertTrue(cell.get!UniqueConstraint.cells.equal(cells));
	assertTrue(cells.each!(c => c.get!UniqueConstraint.cells.equal([cell])));
}


@("core:constraint:unique: takeOut")
unittest
{
	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellThree = new Cell(0);
	UniqueConstraint.createMultiSingle(cellOne, [cellTwo, cellThree]);
	UniqueConstraint.takeOut(cellOne);

	assertTrue(cellOne.get!UniqueConstraint is null);
	assertTrue(cellTwo.get!UniqueConstraint is null);
	assertTrue(cellThree.get!UniqueConstraint is null);
}


@("core:constraint:unique: null parameters")
unittest
{
	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellThree = new Cell(0);
	UniqueConstraint.createInterconnected(cellOne, null, cellTwo, null, cellThree);

	assertTrue(cellOne.get!UniqueConstraint.cells.equal([cellTwo,cellThree]));
}
