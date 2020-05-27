module core.rule.classic;

import std.array : join;

import core.constraint.unique;
import core.rule.rule;
import core.sudoku.box;
import core.sudoku.grid;
import core.sudoku.sudoku;

/** Classic Sudoku rule
 *
 * Each row, column and box must have an UniqueConstraint
 */
public class ClassicRule : Rule
{
	public this(Sudoku sudoku)
	{
		connect(sudoku);
	}

	public this() {}


	/** Classic Rule initializer
	 *
	 * Runs and inits every Constraint which satisfacts this Rule:
	 * * UniqueConstraint for every row
	 * * UniqueConstraint for every column
	 * * UniqueConstraint for every box
	 */
	override
	public void initialize()
	{
		// rows
		for (int i; i < sudoku.rows; i++)
		{
			UniqueConstraint.createInterconnected(sudoku.grid.row(i));
		}

		// columns
		for (int i; i < sudoku.columns; i++)
		{
			UniqueConstraint.createInterconnected(sudoku.grid.column(i));
		}

		// boxes
		for (int i; i < sudoku.rows; i++)
		{
			UniqueConstraint.createInterconnected(sudoku.grid.box(i).toArray());
		}
	}
}

version(unittest) { import aurorafw.unit; }
@("core:rule:classic: ctor")
unittest
{
	import core.sudokuType;

	Sudoku sudoku = new Sudoku(SudokuType.SUDOKU_4X4);
	Rule classic = new ClassicRule(sudoku);

	assertTrue(classic.sudoku == sudoku);

	// this is the default call
	Rule _classic = new ClassicRule();
	_classic.connect(sudoku);

	assertTrue(_classic.sudoku == sudoku);
}
