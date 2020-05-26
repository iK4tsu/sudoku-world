module core.rule.x;

import core.constraint.unique;
import core.rule.rule;
import core.sudoku.sudoku;


/** X Sudoku rule
 *
 * Both diagonals have unique constraints
 */
class XRule : Rule
{
	public this(Sudoku sudoku)
	{
		this.connect(sudoku);
	}

	public this() {}


	override
	public void initialize()
	{
		// both diagonals
		new UniqueConstraint(sudoku.grid.mainDiagonal());
		new UniqueConstraint(sudoku.grid.antiDiagonal());
	}
}


version(unittest) { import aurorafw.unit; }
@("core:rule:x: ctor")
unittest
{
	import core.sudokuType : SudokuType;

	Sudoku sudoku = new Sudoku(SudokuType.SUDOKU_9X9);
	Rule x = new XRule(sudoku);
	assertTrue(x.sudoku == sudoku);

	// this is the default call
	Rule _x = new XRule();
	_x.connect(sudoku);
	assertTrue(_x.sudoku == sudoku);
}


version(unittest)
{
	import core.sudokuType : SudokuType;
	import core.rule.classic;

	int[][] xPuzzle4x4 =   [[1,2,0,0],
							[0,0,0,0],
							[0,0,0,0],
							[0,0,4,3]];

	int[][] xSolution4x4 = [[1,2,3,4],
							[3,4,1,2],
							[4,3,2,1],
							[2,1,4,3]];

	int[][] xPuzzle6x6 =   [[0,0,1,0,0,0],
							[0,0,0,6,0,0],
							[1,0,0,0,3,0],
							[0,4,0,0,0,2],
							[0,0,2,0,0,0],
							[0,0,0,2,0,0]];

	int[][] xSolution6x6 = [[2,6,1,5,4,3],
							[5,3,4,6,2,1],
							[1,2,6,4,3,5],
							[3,4,5,1,6,2],
							[4,1,2,3,5,6],
							[6,5,3,2,1,4]];
}

@("core:rule:x: x solve 4x4")
unittest
{
	Sudoku s = new Sudoku(SudokuType.SUDOKU_4X4);
	s.initialize(xPuzzle4x4);
	s.add(new ClassicRule(s), new XRule(s));
	assertTrue(s.solve() == xSolution4x4);
}

@("core:rule:x: x solve 6x6")
unittest
{
	Sudoku s = new Sudoku(SudokuType.SUDOKU_6X6);
	s.initialize(xPuzzle6x6);
	s.add(new ClassicRule(s), new XRule(s));
	assertTrue(s.solve() == xSolution6x6);
}
