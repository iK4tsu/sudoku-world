module core.constraint.constraint;

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


	public abstract bool isValid(in int digit);


	public static void createSingle(ConstraintType type, Cell cell1, Cell cell2)
	{
		final switch(type)
		{
			case ConstraintType.Unique:
				import core.constraint.unique : UniqueConstraint;
				UniqueConstraint.createSingle(cell1, cell2);
		}
	}


	public static void createMultiSingle(ConstraintType type, Cell cell, Cell[] cells)
	{
		final switch(type)
		{
			case ConstraintType.Unique:
				import core.constraint.unique : UniqueConstraint;
				UniqueConstraint.createMultiSingle(cell, cells);
		}
	}


	public static void createInterconnected(ConstraintType type, Cell[] cells)
	{
		final switch(type)
		{
			case ConstraintType.Unique:
				import core.constraint.unique : UniqueConstraint;
				UniqueConstraint.createInterconnected(cells);
		}
	}


	@safe pure
	public ConstraintType constraintType() const @property
	{
		return _constraintType;
	}


	public bool add(Cell cell)
	{
		import std.algorithm : canFind;

		if (!canFind(cells, cell))
		{
			cells ~= cell;
			return true;
		}
		return false;
	}


	public Cell[] cells;
	protected ConstraintType _constraintType;
}
