module core.constraint.iconstraint;

import core.sudoku.cell;

public interface IConstraint
{
	public bool isValid(in int digit);
}
