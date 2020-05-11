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
	public void connect(Constraint constraint)
	{
		import std.algorithm : canFind;
		if (constraint is null || canFind(constraints, constraint))
			return;

		constraints ~= constraint;
		constraint.connect(this);
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