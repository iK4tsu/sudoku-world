module core.rule.rule;

import std.algorithm : each;
import std.range : iota;

import core.constraint;
import core.sudoku.grid;

public enum RuleType
{
	Classic,
	X,
}

version(unittest)
{
	import aurorafw.unit;
	import core.constraint;
	import core.sudoku.cell;
	import core.sudoku.sudoku;
	import std.algorithm : canFind;
}

public void addRule(Grid grid, RuleType rule)
{
	final switch(rule)
	{
		case RuleType.Classic: addRuleClassic(grid); break;
		case RuleType.X: addRuleX(grid); break;
	}
}

@("core:rule:rule: addRule")
unittest
{
	const auto dim = Sudoku.dimension(SudokuType.Sudoku_4X4);
	Grid grid = new Grid(dim.expand);
	grid.initialize(new int[][](dim.rows, dim.columns));
	grid.addRule(RuleType.Classic);

	assertTrue(grid.toArray().each!(cell => cell.get!UniqueConstraint.cells.length == 8));
}


/** Classic Rule initializer
 *
 * Runs and inits every Constraint which satisfacts this Rule:
 * * UniqueConstraint for every row
 * * UniqueConstraint for every column
 * * UniqueConstraint for every box
 */
public void addRuleClassic(Grid grid)
{
		// rows, columns, boxes
		iota(grid.height).each!(i => UniqueConstraint.createInterconnected(grid.row(i)));
		iota(grid.width).each!(i => UniqueConstraint.createInterconnected(grid.column(i)));
		iota(grid.height).each!(i => UniqueConstraint.createInterconnected(grid.box(i).toArray()));
}

@("core:rule:rule: addRuleClassic")
unittest
{
	const auto dim = Sudoku.dimension(SudokuType.Sudoku_4X4);
	Grid grid = new Grid(dim.expand);
	grid.initialize(new int[][](dim.rows,dim.columns));
	addRuleClassic(grid);

	auto cells = grid[0,0].get!UniqueConstraint.cells;
	assertTrue(cells.each!(c => canFind(grid.row(0), c)));
	assertTrue(cells.each!(c => canFind(grid.column(0), c)));
	assertTrue(cells.each!(c => canFind(grid.box(0).toArray(), c)));
	assertTrue(cells.length == 8);

	assertTrue(grid.toArray().each!(cell => cell.get!UniqueConstraint.cells.length == 8));
}


/** X Rule initializer
 *
 * Runs and inits every Constraint which satisfacts this Rule:
 * * UniqueConstraint for main diagonal
 * * UniqueConstraint for antidiagonal
 */
public void addRuleX(Grid grid)
{
	// both diagonals
	UniqueConstraint.createInterconnected(grid.mainDiagonal());
	UniqueConstraint.createInterconnected(grid.antiDiagonal());
}

@("core:rule:rule: addRuleX")
unittest
{
	const auto dim = Sudoku.dimension(SudokuType.Sudoku_4X4);
	Grid grid = new Grid(dim.expand);
	grid.initialize(new int[][](dim.rows,dim.columns));
	addRuleX(grid);

	auto cells = grid[0,0].get!UniqueConstraint.cells;
	assertTrue(cells.each!(c => canFind(grid.mainDiagonal(), c)));
	assertTrue(cells.length == 4);

	cells = grid[3,3].get!UniqueConstraint.cells;
	assertTrue(cells.each!(c => canFind(grid.antiDiagonal(), c)));
	assertTrue(cells.length == 4);

	assertTrue(grid[0,1].get!UniqueConstraint is null);
}
