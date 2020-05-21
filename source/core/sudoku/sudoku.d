module core.sudoku.sudoku;

import std.experimental.logger;
import std.json;
import std.typecons : tuple;

import core.rule.rule;
import core.sudoku.cell;
import core.sudoku.grid;
import core.sudokuType;
import ui.sudokuBoard;

public class Sudoku
{
	public this(SudokuType type)
	{
		auto dim = dimension(type);
		this.type = type;
		this.rows = dim.rows;
		this.columns = dim.columns;
		this.boxRows = dim.boxRows;
		this.boxColumns = dim.boxColumns;

		grid = new Grid(rows, columns, boxRows, boxColumns);
	}


	public void initialize(int[][] digits)
	{
		grid.initialize(digits);
	}


	public void add(Rule rule)
	{
		import std.algorithm : canFind;
		if (rule is null || canFind(rules,rule))
			return;

		rules ~= rule;
		rule.connect(this);
	}


	public void add(Rule[] rules...)
	{
		foreach (rule; rules)
		{
			add(rule);
		}
	}


	public auto solve()
	{
		trace("Trying to find a solution...");
		if (backtrackAlgorithm(0,0))
			trace("A solution was found!");
		else
			critical("Something went wrong! No solution found.");
		return solution = grid.toDigit();
	}


	public int backtrackAlgorithm(in int row, in int column)
	{
		auto coords = grid.nextCell(row, column);

		// if a cell is blocked (has a given number) we move foward
		if (grid.cells[row][column].isBlocked)
		{
			if (coords.row == -1) return grid.cells[row][column].digit;
			else return backtrackAlgorithm(coords.row, coords.column);
		}

		// let's try every number from 1 to our max digit
		// max digit is the row/column length
		for (int i = 1; i <= rows; i++)
		{
			if (grid.cells[row][column].isValid(i))
			{
				int ret;
				if (coords.row == -1) return i;
				else ret = backtrackAlgorithm(coords.row, coords.column);

				if (ret == 0) grid.cells[row][column].digit = 0;
				else return ret;
			}
		}

		// end of cicle?
		// no digit was valid
		return 0;
	}


	/** SudokuType from string
	 *
	 * Gets a SudokuType based on the input string.
	 * SudokuType is of type string so it's easy to compare it's value.
	 * This is useful when using the GtkComboBox value strings.
	 *
	 * Params:
	 *     typeString = string to compare
	 *
	 * Returns:
	 *     `SudokuType` if typeString is a valid string \
	 *     `null` otherwise
	 */
	public static SudokuType toSudokuType(string typeString)
	{
		import std.traits : EnumMembers;
		foreach (type; EnumMembers!SudokuType)
			if (type == typeString)
				return type;

		return null;
	}


	/** Standard Sudoku dimensions
	 *
	 * Params:
	 *     type = SudokuType to process
	 *
	 * Returns: `tuple`***("rows","columns","boxRows","boxColumns")*** with the
	 *     dimensions of SudokuType
	 */
	public static auto dimension(SudokuType type)
	{
		final switch (type)
		{
			case SudokuType.SUDOKU_4X4:
				return tuple!("rows","columns","boxRows","boxColumns")(4,4,2,2);

			case SudokuType.SUDOKU_6X6:
				return tuple!("rows","columns","boxRows","boxColumns")(6,6,2,3);

			case SudokuType.SUDOKU_9X9:
				return tuple!("rows","columns","boxRows","boxColumns")(9,9,3,3);
		}
	}


	// TODO: core: Sudoku: finish toJson parsing
	public static void toJson(SudokuBoard board)
	{
		string sudokuType = board.type;
		JSONValue j = ["sudokuType" : sudokuType];

		auto cells = board.toCells();
		j.object["sudoku"] = ["grid" : cells];

		auto rules = board.rules;
		j.object["sudoku"]["rules"] = rules;

		import std.typecons : tuple;
		auto dim = board.dimensions();

		j.object["rows"] = dim.rows;
		j.object["columns"] = dim.columns;
		j.object["boxRows"] = dim.boxRows;
		j.object["boxColumns"] = dim.boxColumns;

		// TODO: core:sudoku: implement file name
		import std.file : write, exists, mkdir;
		enum directory = "resources";
		if (!directory.exists)
			mkdir(directory);

		auto f = directory~"/"~"puzzle"~sudokuType~".json";
		write(f, j.toJSON(true));
	}

	// TODO: core: sudoku: implement fromJson parsing
	// FIXME: core: sudoku: change return type to Sudoku
	public static bool fromJson(string file)
	{
		import std.file : FileException, exists, readText;
		import std.exception : enforce;

		if (!file.exists) return false;



		return true;
	}


	public int rows;
	public int columns;
	public int boxRows;
	public int boxColumns;

	public SudokuType type;
	public Grid grid;
	public Rule[] rules;
	public int[][] solution;
}


version(unittest) { import aurorafw.unit; }

@("core:sudoku:sudoku: classic solve 4x4")
unittest
{
	import core.rule.classic;

	Sudoku sudoku = new Sudoku(SudokuType.SUDOKU_4X4);

	int[][] digits =   [[1, 0, 0, 3],
						[0, 2, 1, 4],
						[4, 0, 0, 2],
						[0, 3, 4, 1]];

	sudoku.initialize(digits);
	sudoku.add(new ClassicRule());

	assertTrue(sudoku.solve() ==   [[1, 4, 2, 3],
									[3, 2, 1, 4],
									[4, 1, 3, 2],
									[2, 3, 4, 1]]);
}

@("core:sudoku:sudoku: classic solve 6x6")
unittest
{
	import core.rule.classic;

	Sudoku sudoku = new Sudoku(SudokuType.SUDOKU_6X6);

	int[][] digits =   [[0, 0, 3, 0, 1, 0],
						[5, 6, 0, 3, 2, 0],
						[0, 5, 4, 2, 0, 3],
						[2, 0, 6, 4, 5, 0],
						[0, 1, 2, 0, 4, 5],
						[0, 4, 0, 1, 0, 0]];

	sudoku.initialize(digits);
	sudoku.add(new ClassicRule());

	assertTrue(sudoku.solve() ==   [[4, 2, 3, 5, 1, 6],
									[5, 6, 1, 3, 2, 4],
									[1, 5, 4, 2, 6, 3],
									[2, 3, 6, 4, 5, 1],
									[3, 1, 2, 6, 4, 5],
									[6, 4, 5, 1, 3, 2]]);
}


@("core:sudoku:sudoku: classic solve 6x6")
unittest
{
	import core.rule.classic;

	Sudoku sudoku = new Sudoku(SudokuType.SUDOKU_6X6);

	int[][] digits =   [[2, 0, 0, 0, 0, 0],
						[3, 0, 0, 4, 5, 2],
						[0, 5, 2, 3, 0, 6],
						[4, 6, 3, 0, 1, 0],
						[0, 2, 0, 0, 0, 4],
						[0, 0, 4, 5, 2, 0]];

	sudoku.initialize(digits);
	sudoku.add(new ClassicRule());

	assertTrue(sudoku.solve() ==   [[2, 4, 5, 1, 6, 3],
									[3, 1, 6, 4, 5, 2],
									[1, 5, 2, 3, 4, 6],
									[4, 6, 3, 2, 1, 5],
									[5, 2, 1, 6, 3, 4],
									[6, 3, 4, 5, 2, 1]]);
}


@("core:sudoku:sudoku: classic solve 9x9")
unittest
{
	import core.rule.classic;

	Sudoku sudoku = new Sudoku(SudokuType.SUDOKU_9X9);

	auto digits =  [[0, 0, 3, 2, 6, 0, 0, 0, 0],
					[0, 0, 7, 0, 0, 1, 0, 2, 3],
					[0, 8, 6, 0, 0, 0, 4, 0, 0],
					[5, 0, 0, 0, 0, 8, 0, 9, 0],
					[6, 4, 0, 3, 0, 7, 0, 1, 0],
					[0, 0, 0, 0, 0, 0, 0, 0, 5],
					[9, 2, 0, 0, 4, 0, 0, 0, 7],
					[0, 0, 0, 0, 0, 5, 9, 8, 0],
					[0, 0, 1, 6, 0, 0, 0, 3, 0]];

	sudoku.initialize(digits);
	sudoku.add(new ClassicRule());

	assertTrue(sudoku.solve() ==   [[1, 5, 3, 2, 6, 4, 8, 7, 9],
									[4, 9, 7, 5, 8, 1, 6, 2, 3],
									[2, 8, 6, 7, 3, 9, 4, 5, 1],
									[5, 3, 2, 4, 1, 8, 7, 9, 6],
									[6, 4, 9, 3, 5, 7, 2, 1, 8],
									[7, 1, 8, 9, 2, 6, 3, 4, 5],
									[9, 2, 5, 8, 4, 3, 1, 6, 7],
									[3, 6, 4, 1, 7, 5, 9, 8, 2],
									[8, 7, 1, 6, 9, 2, 5, 3, 4]]);
}
