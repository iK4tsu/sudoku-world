module core.rule.rule;

import core.constraint;
import core.sudoku.cell;
import core.sudoku.grid;

public enum RuleType
{
	Classic,
	X,
}

public class Rule
{
	protected this(RuleType type, Cell[][ConstraintType] cells...)
	{
		_ruleType = ruleType;
		this.cells = cells;
	}


	/** Adds a rule to a grid
	 *
	 * Calls the create method from the RuleType passed.\
	 * A rule is nothing more than a group of Constraints. \
	 * Rules are stored individualy in each Cell with only the Cells that are
	 *     connected by that Cell. \
	 * This means that each Cell of a 4x4 sudoku with the Classic rule,
	 *     will have a Classic rule containing only the 3 other Cells in that row,
	 *     column and the left one in that box under the UniqueConstraint.
	 *
	 * Params:
	 *     type = RuleType to add
	 *     grid = Grid to in which type will be added
	 */
	public static void create(RuleType type, Grid grid)
	{
		final switch(type)
		{
			case RuleType.Classic:
				import core.rule.classic : ClassicRule;
				ClassicRule.create(grid);
				break;

			case RuleType.X:
				import core.rule.x : XRule;
				XRule.create(grid);
				break;
		}
	}


	/** Removes a rule from a grid
	 *
	 * Safely removes a rule from each Cell \
	 * It checks if this type's cells are common to other rules in the same
	 *     Cell under the same Constraint and preserves them \
	 * \
	 * For example, let's a Grid has the Classic and X rules, this means every
	 *     Cell in the grid has the UniqueConstraint for every row,
	 *     column and in which they exist, and adicionaly diagonal Cells have
	 *     the UniqueConstraint for the diagonal in which they exist. \
	 * This creates dependencies or common Cells between this two rules, every
	 *     diagonal Cell is common between them. \
	 * If we only remove the rule without searching for these common Cells,
	 *     the remaining rules will be broken. \
	 * If we a 4x4 sudoku with these rules and remove X, leaving only Classic,
	 *     it'll disconnect every diagonal Cell from each other, leaving the
	 *     Classic rule broken beacause of missing constraints in some Cells,
	 *     the diagonal Cells in the same box.
	 *
	 * Params:
	 *     type = RuleType to remove
	 *     grid = Grid in which type will be removed
	 */
	public static void remove(RuleType type, Grid grid)
	in
	{
		static import std.algorithm;
		import aurorafw.unit.assertion : assertFalse;

		assertFalse(std.algorithm.canFind(grid.toArray(), null));
	}
	do
	{
		import std.algorithm : canFind, filter, setIntersection, map;
		import std.array : array;
		import std.range : empty;

		Cell[] cells = grid.toArray();

		// get cells with rule
		Cell[] cellsWithRule = cells.filter!(cell => type in cell.rules).array;

		foreach (cell; cellsWithRule)
		{
			// get the cells within the rule
			Cell[][ConstraintType] ruleCells = cell.rules[type].cells;

			// get other rules
			RuleType[] ruleTypes = cell.rules.keys.filter!(key => key != type).array;

			if (ruleTypes.empty)
			{
				foreach (ConstraintType constraint; ruleCells.keys)
				{
					cell.disconnect(constraint, ruleCells[constraint]);
				}
				cell.rules.remove(type);
				continue;
			}

			foreach (ruleType; ruleTypes)
			{
				// loop ruleCells constraints
				foreach (ConstraintType constraint; ruleCells.keys)
				{
					if (!canFind(cell.rules[ruleType].cells.keys, constraint))
					{
						cell.disconnect(constraint, ruleCells[constraint]);
					}
					else
					{
						Cell[] difference = ruleCells[constraint]
												.filter!(c => !canFind(cell.rules[ruleType].cells[constraint], c))
												.array;
						cell.disconnect(constraint, difference);
					}
				}
			}

			cell.rules.remove(type);
		}
	}

	public RuleType ruleType() const @property
	{
		return _ruleType;
	}


	public Cell[][ConstraintType] cells;
	protected RuleType _ruleType;
}


version(unittest) import aurorafw.unit;

@("core:rule:rule: remove")
unittest
{
	import std.algorithm : each;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize();

	Rule.create(RuleType.Classic, grid);
	Rule.remove(RuleType.Classic, grid);

	grid.toArray().each!(cell => assertNull(cell.get!UniqueConstraint));

	Rule.create(RuleType.X, grid);
	Rule.remove(RuleType.X, grid);

	grid.toArray().each!(cell => assertNull(cell.get!UniqueConstraint));
}

@("core:rule:rule: remove with dependencies")
unittest
{
	import std.algorithm : canFind, each, equal, filter;
	import std.array : array;
	import std.range : chain;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize();

	Rule.create(RuleType.Classic, grid);
	Rule.create(RuleType.X, grid);

	// removing this rule only disconnects the cells not common
	//  to other rules with the same constraints
	Rule.remove(RuleType.Classic, grid);

	Cell[] cells = grid.mainDiagonal();

	cells.each!(cell => cell.get(ConstraintType.Unique).cells.equal(cells.filter!(c => c != cell)));
	cells.each!(cell => assertEquals(cell.get(ConstraintType.Unique).cells.length, 3));

	cells = grid.antiDiagonal();

	cells.each!(cell => cell.get(ConstraintType.Unique).cells.equal(cells.filter!(c => c != cell)));
	cells.each!(cell => assertEquals(cell.get(ConstraintType.Unique).cells.length, 3));

	Cell[] connected = chain(grid.mainDiagonal(),grid.antiDiagonal()).array;
	cells = grid.toArray().filter!(cell => !canFind(connected, cell)).array;

	// test every cell not in the diagonals
	cells.each!(cell => assertNull(cell.get!UniqueConstraint));
}
