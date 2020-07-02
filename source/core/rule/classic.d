module core.rule.classic;

import core.constraint.constraint : ConstraintType;
import core.rule.rule;
import core.sudoku.cell;
import core.sudoku.grid;

public class ClassicRule : Rule
{
	private this(Cell[][ConstraintType] cells...)
	{
		super (RuleType.Classic, cells);
	}


	/** Adds ClassicRule to a Grid
	 *
	 * Classic rule requires the following constraints:
	 * * each Cell in a row must be unique
	 * * each Cell in a column must be unique
	 * * each Cell in a box must be unique
	 *
	 * Params:
	 *     grid = Grid in which this rule will be added
	 */
	public static void create(Grid grid)
	{
		import std.algorithm : canFind, filter, uniq;
		import std.array : array;
		import core.constraint.unique : UniqueConstraint;

		Cell[] cells = grid.toArray();
		if (canFind(cells, null))
			return;

		if (RuleType.Classic in grid[0,0].rules)
			return;

		for (int y; y < grid.rows; y++)
		{
			Cell[] rows = grid.row(y);
			for (int x; x < grid.columns; x++)
			{
				Cell[] columns = grid.column(x);
				Cell[] box = grid.boxes[y/grid.boxRows][x/grid.boxColumns].toArray();

				Cell[][ConstraintType] needed;
				needed[ConstraintType.Unique] = uniq(rows~columns~box)
												.filter!(c => c != grid[y,x] && c !is null)
												.array;

				grid[y,x].addConstraint!UniqueConstraint(needed[ConstraintType.Unique]);
				grid[y,x].rules[RuleType.Classic] = new ClassicRule(needed);
			}
		}
	}


	public static RuleType getStaticRuleType()
	{
		return RuleType.Classic;
	}
}


version(unittest) { import aurorafw.unit; }

@("core:rule:ruleClassic: create")
unittest
{
	import std.algorithm : canFind, each, uniq;
	import std.array : array;
	import std.range : chain;
	import core.constraint.unique : UniqueConstraint;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize();

	ClassicRule.create(grid);
	Cell[] connected = grid[0,0].get!UniqueConstraint.cells;
	Cell[] cells = uniq(chain(grid.row(0),grid.column(0),grid.box(0).toArray())).array;

	connected.each!(cell => assertTrue(canFind(cells, cell)));
	assertEquals(connected.length, 7);

	grid.toArray().each!(cell => assertEquals(cell.get!UniqueConstraint.cells.length, 7));
}
