module core.rule.x;

import core.constraint.constraint : ConstraintType;
import core.rule.rule;
import core.sudoku.cell;
import core.sudoku.grid;

public class XRule : Rule
{
	private this(Cell[][ConstraintType] cells...)
	{
		super(RuleType.X, cells);
	}


	/** Adds XRule to a Grid
	 *
	 * X rule requires the following constraints:
	 * * each Cell in the main diagonal must be unique
	 * * each Cell in the antidiagonal must be unique
	 *
	 * Params:
	 *     grid = Grid in which this rule will be added
	 */
	public static void create(Grid grid)
	{
		import std.algorithm : canFind, filter, uniq;
		import std.array : array;
		import core.constraint.unique : UniqueConstraint;

		if (canFind(grid.toArray(), null))
			return;

		if (RuleType.X in grid[0,0].rules)
			return;

		Cell[] cells = grid.mainDiagonal();
		foreach (Cell cell; cells)
		{
			Cell[][ConstraintType] needed;
			needed[ConstraintType.Unique] = cells
											.filter!(c => c != cell)
											.array;

			cell.addConstraint!UniqueConstraint(needed[ConstraintType.Unique]);
			cell.rules[RuleType.X] = new XRule(needed);
		}

		cells = grid.antiDiagonal();
		foreach (Cell cell; cells)
		{
			Cell[][ConstraintType] needed;
			needed[ConstraintType.Unique] = cells
											.filter!(c => c != cell)
											.array;

			cell.addConstraint!UniqueConstraint(needed[ConstraintType.Unique]);
			cell.rules[RuleType.X] = new XRule(needed);
		}
	}


	public static RuleType getStaticRuleType()
	{
		return RuleType.X;
	}
}


version(unittest) { import aurorafw.unit; }

@("core:rule:xRule: create")
unittest
{
	import std.algorithm : canFind, each, filter;
	import std.array : array;
	import std.range : chain;
	import core.constraint.unique : UniqueConstraint;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize();

	XRule.create(grid);

	Cell[] connected = grid[0,0].get!UniqueConstraint.cells;
	Cell[] cells = grid.mainDiagonal();

	connected.each!(cell => assertTrue(canFind(cells, cell)));
	assertEquals(connected.length, 3);

	connected = grid[0,3].get!UniqueConstraint.cells;
	cells = grid.antiDiagonal();

	connected.each!(cell => assertTrue(canFind(cells, cell)));
	assertEquals(connected.length, 3);

	connected = chain(grid.mainDiagonal(),grid.antiDiagonal()).array;
	cells = grid.toArray().filter!(cell => !canFind(connected, cell)).array;

	// test every cell not in the diagonals
	cells.each!(cell => assertNull(cell.get!UniqueConstraint));
}
