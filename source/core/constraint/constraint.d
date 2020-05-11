module core.constraint.constraint;

import core.constraint.iconstraint;
import core.sudoku.cell;

public abstract class Constraint : IConstraint
{
	public abstract void connect(Cell cell);
	public abstract bool isValid(in int digit);
}
