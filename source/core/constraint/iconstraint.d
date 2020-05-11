module core.constraint.iconstraint;

import core.sudoku.cell;

public interface IConstraint
{
    public void connect(Cell cell);
    public bool isValid(in int digit);
}