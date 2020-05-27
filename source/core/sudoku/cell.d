module core.sudoku.cell;

import core.constraint.constraint;

public class Cell
{
	public this(int digit)
	{
		this.digit = digit;
		isBlocked = !digit ? false : true;
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
				c.add(cell);
			}
		}

		return c;
	}


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

	public bool isBlocked;
	public int digit;

	public Constraint[] constraints;
}
