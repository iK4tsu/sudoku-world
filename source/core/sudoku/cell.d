module core.sudoku.cell;

import core.constraint.constraint;

public class Cell
{
	public this(in int digit)
	{
		this.digit = digit;
		isBlocked = digit != 0;
	}


	/** Connects Cell to a Constraint
	 *
	 * Params:
	 *     constraint = constraint to connect
	 */
	public auto connect(C : Constraint)(C constraint)
	{
		import std.algorithm : canFind;
		if (constraint is null)
			return null;

		C c = get!C;
		if (c is null)
		{
			constraints ~= constraint;
			c = constraint;
		}
		else
		{
			foreach (Cell cell; constraint.cells)
			{
				if (cell != this)
					c.add(cell);
			}
		}

		return c;
	}


	public void disconnect(C : Constraint)(Cell[] cells...)
	{
		import std.algorithm : each, remove;
		import std.range : empty;
		C constraint = get!C;
		if (constraint is null)
			return;

		foreach (cell; cells)
		{
			constraint.cells = constraint.cells.remove!(c => c == cell);
		}

		if (constraint.cells.empty)
		{
			constraints = constraints.remove!(c => c == constraint);
		}
	}


	public void takeOut(C : Constraint)()
	{
		C constraint = get!C;
		if (constraint !is null)
		{
			C.takeOut(this);
		}
	}


	@safe
	public C get(C : Constraint)()
	{
		foreach (Constraint c; constraints)
		{
			if (c.constraintType == C.getStaticConstraintType())
				return cast(C) c;
		}
		return null;
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

	public Constraint[] constraints;
}


version(unittest) { import aurorafw.unit; }

@("core:sudoku:cell: disconnect")
unittest
{
	import std.algorithm : equal;
	import std.range : empty;
	import core.constraint : UniqueConstraint;
	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellTree = new Cell(0);
	UniqueConstraint.createMultiSingle(cellOne, [cellTwo, cellTree]);
	cellOne.disconnect!UniqueConstraint([cellTwo]);
	cellOne.disconnect!UniqueConstraint([cellTwo]); // no error

	assertTrue(cellOne.get!UniqueConstraint.cells.equal([cellTree]));

	UniqueConstraint constraint = cellOne.get!UniqueConstraint;
	cellOne.disconnect!UniqueConstraint([cellTree]);

	assertTrue(cellOne.get!UniqueConstraint is null);
	assertTrue(constraint.cells.empty);
}

@("core:sudoku:cell: takeOut")
unittest
{
	import core.constraint : UniqueConstraint;
	Cell cellOne = new Cell(0);
	Cell cellTwo = new Cell(0);
	Cell cellThree = new Cell(0);
	UniqueConstraint.createMultiSingle(cellOne, [cellTwo, cellThree]);
	cellOne.takeOut!UniqueConstraint;

	assertTrue(cellOne.get!UniqueConstraint is null);
	assertTrue(cellTwo.get!UniqueConstraint is null);
	assertTrue(cellThree.get!UniqueConstraint is null);
}


