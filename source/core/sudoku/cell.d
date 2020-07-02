module core.sudoku.cell;

import core.constraint;

public class Cell
{
	public this(in int digit)
	{
		this.digit = digit;
		isBlocked = digit != 0;
	}


	/** Safely adds a constraint
	 *
	 * It filters any invalid data passed in `cells`, null values, duplicated objects,
	 *     same Cell as the being used
	 *
	 * Params:
	 *     C = Constraint to add
	 *     cells = cells to connect under C
	 */
	public void addConstraint(C : Constraint)(Cell[] cells...)
	{
		// remove null and repeated cells
		import std.algorithm : canFind, filter, uniq;
		import std.array : array;

		cells = uniq(cells.filter!(cell => cell !is null && cell != this)).array;
		ConstraintType type = C.getStaticConstraintType;

		// create a new instance if this Cell doesn't containt this ConstraintType
		if (type !in constraints)
		{
			constraints[type] = new C();
		}

		// add and connect to non existent Cells
		foreach (cell; cells)
		{
			if (!canFind(constraints[type].cells, cell))
			{
				constraints[type].cells ~= cell;
				cell.addConstraint!C(this);
			}
		}
	}


	/** safely adds a constraint
	 *
	 * Adds a constraint by its type \
	 * It filters any invalid data passed in `cells`, null values, duplicated objects,
	 *     same Cell as the being used
	 *
	 * Params:
	 *     type = ConstraintType to add
	 *     cells = Cells to connect
	 *
	 * SeeAlso: void addConstraint(**C : Constraint**)(**Cell[] cells...**)
	 */
	public void addConstraint(ConstraintType type, Cell[] cells...)
	{
		Constraint.createMultiSingle(type, this, cells);
	}


	/** Safely removes a constraint from a Cell
	 *
	 * It disconnects all the connected Cells from each other
	 *
	 * Params:
	 *     type = ContraintType to remove
	 *
	 * SeeAlso: void disconnect(**ConstraintType type, **Cell[] cells...**)
	 */
	public void removeConstraint(ConstraintType type)
	{
		if (type !in constraints)
			return;

		// safely cut the connection between both Cells
		disconnect(type, constraints[type].cells);
	}


	/** Safely removes a constraint from a Cell
	 *
	 * Params:
	 *     C = Contraint to remove
	 *
	 * SeeAlso: void removeConstraint(**ConstraintType type**)
	 */
	public void removeConstraint(C : Constraint)()
	{
		removeConstraint(C.getStaticConstraintType);
	}


	/** Safely disconnects Cells from each other
	 *
	 * It filters any invalid data passed in `cells`, null values, duplicated objects,
	 *     same Cell as the being used
	 *
	 * Params:
	 *     type = ConstraintType to use
	 *     cells = cells to disconnect
	 */
	public void disconnect(ConstraintType type, Cell[] cells...)
	{
		import std.algorithm : canFind, each, filter, remove, uniq;
		import std.array : array;
		import std.range : empty;

		cells = uniq(cells.filter!(cell => cell !is null && cell != this)).array;

		// check if Cell has this constraint
		if (type !in constraints)
			return;

		// safely disconnect existent cells from each other
		foreach (cell; cells)
		{
			if (type in constraints && canFind(constraints[type].cells, cell))
			{
				constraints[type].cells = constraints[type].cells.remove!(c => c == cell);
				cell.disconnect(type, this);
			}
		}

		// here we need to verify if the constraint has been removed already
		if (type in constraints && constraints[type].cells.empty)
		{
			constraints.remove(type);
		}
	}


	/** Safely disconnects Cells from each other
	 *
	 * Params:
	 *     C = Constraint to use
	 *     cells = cells to disconnect
	 *
	 * SeeAlso: void disconnect(**ConstraintType type, **Cell[] cells...**)
	 */
	public void disconnect(C : Constraint)(Cell[] cells...)
	{
		disconnect(C.getStaticConstraintType, cells);
	}


	@safe
	public C get(C : Constraint)()
	{
		if (C.getStaticConstraintType() !in constraints)
			return null;

		return cast(C) constraints[C.getStaticConstraintType];
	}


	@safe
	public auto get(ConstraintType type)
	{
		if (type !in constraints)
			return null;

		return constraints[type];
	}


	/** Check if digit is valid
	 *
	 * Sees for every constraint if the digit can be stored in this Cell
	 * It automatically updates the Cell's digit, whether it's true or false
	 *
	 * Params:
	 *     digit = digit to check
	 *
	 * Returns:
	 *     `true` if the digit can be stored in the Cell \
	 *     `false` otherwise
	 */
	public bool isValid(int digit)
	{
		foreach (constraint; constraints)
		{
			if (!constraint.isValid(digit))
			{
				digit = 0;
				return false;
			}
		}

		this.digit = digit;
		return true;
	}


	public const bool isBlocked;
	public int digit;

	public Constraint[ConstraintType] constraints;
}


version(unittest) { import aurorafw.unit; }

@("core:sudoku:cell: addConstraint")
unittest
{
	import std.algorithm : each, equal;
	import core.constraint : UniqueConstraint;

	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellTree = new Cell(0);

	cellOne.addConstraint!UniqueConstraint(cellTwo,cellTree);

	assertTrue(cellOne.get!UniqueConstraint.cells.equal([cellTwo, cellTree]));
	[cellTwo, cellTree].each!(cell => assertTrue(cell.get!UniqueConstraint.cells.equal([cellOne])));
}

@("core:sudoku:cell: addConstraint filters")
unittest
{
	import std.algorithm : equal;
	import core.constraint : UniqueConstraint;

	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	cellOne.addConstraint!UniqueConstraint(cellOne,null,cellTwo,null,cellTwo);

	assertTrue(cellOne.get!UniqueConstraint.cells.equal([cellTwo]));
	assertTrue(cellTwo.get!UniqueConstraint.cells.equal([cellOne]));
}

@("core:sudoku:cell: disconnect")
unittest
{
	import std.algorithm : equal;
	import core.constraint : UniqueConstraint;

	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellTree = new Cell(0);

	cellOne.addConstraint!UniqueConstraint(cellTwo,cellTree);
	cellOne.disconnect!UniqueConstraint(cellTwo);
	cellOne.disconnect!UniqueConstraint(cellTwo); // no error

	assertTrue(cellOne.get!UniqueConstraint.cells.equal([cellTree]));
	assertNull(cellTwo.get!UniqueConstraint);

	UniqueConstraint constraint = cellOne.get!UniqueConstraint;
	cellOne.disconnect!UniqueConstraint([cellTree]);

	assertNull(cellOne.get!UniqueConstraint);
	assertNull(cellTree.get!UniqueConstraint);
	assertEmpty(constraint.cells);
}

@("core:sudoku:cell: disconnect filters")
unittest
{
	import std.algorithm : equal;
	import core.constraint : UniqueConstraint;

	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellThree = new Cell(0);
	cellOne.addConstraint!UniqueConstraint(cellTwo);
	cellOne.disconnect!UniqueConstraint(cellOne,null,null,cellThree);

	assertTrue(cellOne.get!UniqueConstraint.cells.equal([cellTwo]));
	assertTrue(cellTwo.get!UniqueConstraint.cells.equal([cellOne]));

	cellOne.disconnect!UniqueConstraint(cellTwo,cellTwo,null,cellOne);

	assertNull(cellOne.get!UniqueConstraint);
	assertNull(cellTwo.get!UniqueConstraint);
}

@("core:sudoku:cell: get")
unittest
{
	import core.constraint : UniqueConstraint;

	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellTree = new Cell(0);

	cellOne.addConstraint!UniqueConstraint(cellTwo,cellTree);

	assertNotNull(cellOne.get!UniqueConstraint);
	assertSame(cellOne.get!UniqueConstraint, cellOne.get(ConstraintType.Unique));
}

@("core:sudoku:cell: isValid")
unittest
{
	import core.constraint : UniqueConstraint;

	Cell cellOne = new Cell(0);

	// cell doesn't have restrictions
	assertTrue(cellOne.isValid(4));

	cellOne.addConstraint!UniqueConstraint(new Cell(4));

	// now cellOne is connected to a Cell under the UniqueConstraint
	assertFalse(cellOne.isValid(4));
}

@("core:sudoku:cell: removeConstraint")
unittest
{
	import std.algorithm : each;
	import core.constraint : UniqueConstraint;

	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellThree = new Cell(0);

	cellOne.addConstraint!UniqueConstraint(cellTwo,cellThree);
	cellOne.removeConstraint!UniqueConstraint;

	[cellOne,cellTwo,cellThree].each!(cell => assertNull(cell.get!UniqueConstraint));
}
