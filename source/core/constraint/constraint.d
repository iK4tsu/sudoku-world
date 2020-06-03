module core.constraint.constraint;

import std.algorithm : canFind;

import core.constraint.iconstraint;
import core.sudoku.cell;


public enum ConstraintType : string
{
	Unique = "Unique"
}

public abstract class Constraint : IConstraint
{
	protected this(ConstraintType constraintType)
	{
		_constraintType = constraintType;
	}

	public abstract void connect(Cell cell);
	public abstract bool isValid(in int digit);

	public ConstraintType constraintType() const @property
	{
		return _constraintType;
	}

	public bool add(Cell cell)
	{
		if (!canFind(cells, cell))
		{
			_cells ~= cell;
			return true;
		}
		return false;
	}

	public auto cells() @property
	{
		return _cells;
	}

	public static void createFromJSON(ConstraintType type, string jsonString, Cell[][] cells)
	{
		import core.constraint.unique : UniqueConstraint;
		final switch (type)
		{
			case UniqueConstraint.getStaticConstraintType(): UniqueConstraint.createFromJSON(jsonString, cells); break;
		}
	}

	protected Cell[] _cells;
	protected ConstraintType _constraintType;
}
