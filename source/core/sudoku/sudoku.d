module core.sudoku.sudoku;

import std.experimental.logger;
import std.json;
import std.typecons : tuple;

import core.rule.rule;
import core.sudoku.cell;
import core.sudoku.grid;


public class Sudoku
{
	public this(Grid grid)
	{
		this.grid = grid;
	}


	public auto solve()
	{
		backtrackAlgorithm(0,0);
		return grid.toDigit();
	}


	private int backtrackAlgorithm(in int row, in int column)
	{
		auto coords = nextCell(row, column);

		// if a cell is blocked (has a given number) we move foward
		if (grid.cells[row][column].isBlocked)
		{
			if (coords.row == -1) return grid.cells[row][column].digit;
			else return backtrackAlgorithm(coords.row, coords.column);
		}

		// let's try every number from 1 to our max digit
		// max digit is the row/column length
		for (int i = 1; i <= grid.rows; i++)
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


	/** Position of the next cell
	 *
	 * This is used internaly by the backtrackAlgorithm
	 *
	 * Params:
	 *     row = current row int the Grid
	 *     column = current column int the Grid
	 *
	 * Returns:
	 *     `tuple`***("row","column")*** with the position of the next Cell \
	 *     `tuple`***("row","column")(-1,-1)*** if params correspond to the last Cell
	 */
	private auto nextCell(int row, int column)
	{
		import std.typecons : tuple;

		// last cell of grid
		if (row == grid.rows - 1 && column == grid.columns - 1)
			return tuple!("row","column")(-1, -1);

		// last cell of column
		else if (column == grid.columns - 1)
			return tuple!("row","column")(row + 1, 0);

		// cell in the middle
		else
			return tuple!("row","column")(row, column + 1);
	}


	// TODO: core: Sudoku: finish toJson parsing
	public static void toJson(/*GridUI board*/)
	{
		// SudokuType sudokuType = board.type;
		// JSONValue j = ["sudokuType" : sudokuType];

		// auto cells = board.toDigits();
		// j.object["sudoku"] = ["grid" : cells];

		// auto rules = board.allRules;
		// j.object["sudoku"]["rules"] = rules;

		// import std.typecons : tuple;
		// auto dim = dimension(sudokuType);

		// j.object["rows"] = dim.rows;
		// j.object["columns"] = dim.columns;
		// j.object["boxRows"] = dim.boxRows;
		// j.object["boxColumns"] = dim.boxColumns;

		// // TODO: core:sudoku: implement file name
		// import std.file : write, exists, mkdir;
		// enum directory = "resources";
		// if (!directory.exists)
		// 	mkdir(directory);

		// auto f = directory~"/"~"puzzle"~sudokuType~".json";
		// write(f, j.toJSON(true));
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


	private Grid grid;
}


version(unittest) { import aurorafw.unit; }
version(unittest)
{
	import core.rule.classic;

	int[][] classic4x4 =   [[1, 0, 0, 3],
							[0, 2, 1, 4],
							[4, 0, 0, 2],
							[0, 3, 4, 1]];

	int[][] classicSolve4x4 =  [[1, 4, 2, 3],
								[3, 2, 1, 4],
								[4, 1, 3, 2],
								[2, 3, 4, 1]];

	int[][] classic6x6 =   [[0, 0, 3, 0, 1, 0],
							[5, 6, 0, 3, 2, 0],
							[0, 5, 4, 2, 0, 3],
							[2, 0, 6, 4, 5, 0],
							[0, 1, 2, 0, 4, 5],
							[0, 4, 0, 1, 0, 0]];

	int[][] classicSolve6x6 =  [[4, 2, 3, 5, 1, 6],
								[5, 6, 1, 3, 2, 4],
								[1, 5, 4, 2, 6, 3],
								[2, 3, 6, 4, 5, 1],
								[3, 1, 2, 6, 4, 5],
								[6, 4, 5, 1, 3, 2]];

	int[][] classic9x9 =   [[0, 0, 3, 2, 6, 0, 0, 0, 0],
							[0, 0, 7, 0, 0, 1, 0, 2, 3],
							[0, 8, 6, 0, 0, 0, 4, 0, 0],
							[5, 0, 0, 0, 0, 8, 0, 9, 0],
							[6, 4, 0, 3, 0, 7, 0, 1, 0],
							[0, 0, 0, 0, 0, 0, 0, 0, 5],
							[9, 2, 0, 0, 4, 0, 0, 0, 7],
							[0, 0, 0, 0, 0, 5, 9, 8, 0],
							[0, 0, 1, 6, 0, 0, 0, 3, 0]];

	int[][] classicSolve9x9 =  [[1, 5, 3, 2, 6, 4, 8, 7, 9],
								[4, 9, 7, 5, 8, 1, 6, 2, 3],
								[2, 8, 6, 7, 3, 9, 4, 5, 1],
								[5, 3, 2, 4, 1, 8, 7, 9, 6],
								[6, 4, 9, 3, 5, 7, 2, 1, 8],
								[7, 1, 8, 9, 2, 6, 3, 4, 5],
								[9, 2, 5, 8, 4, 3, 1, 6, 7],
								[3, 6, 4, 1, 7, 5, 9, 8, 2],
								[8, 7, 1, 6, 9, 2, 5, 3, 4]];
}

@("core:sudoku:sudoku: classic solve 4x4")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize(classic4x4);
	ClassicRule.create(grid);

	Sudoku sudoku = new Sudoku(grid);

	assertTrue(sudoku.solve().equal(classicSolve4x4));
}

@("core:sudoku:sudoku: classic solve 6x6")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku6x6);
	grid.initialize(classic6x6);
	ClassicRule.create(grid);

	Sudoku sudoku = new Sudoku(grid);

	assertTrue(sudoku.solve().equal(classicSolve6x6));
}

@("core:sudoku:sudoku: classic solve 9x9")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku9x9);
	grid.initialize(classic9x9);
	ClassicRule.create(grid);

	Sudoku sudoku = new Sudoku(grid);

	assertTrue(sudoku.solve().equal(classicSolve9x9));
}


version(unittest)
{
	import core.rule.x;

	int[][] x4x4 = [[1,2,0,0],
					[0,0,0,0],
					[0,0,0,0],
					[0,0,4,3]];

	int[][] xSolve4x4 =    [[1,2,3,4],
							[3,4,1,2],
							[4,3,2,1],
							[2,1,4,3]];

	int[][] x6x6 = [[0,0,1,0,0,0],
					[0,0,0,6,0,0],
					[1,0,0,0,3,0],
					[0,4,0,0,0,2],
					[0,0,2,0,0,0],
					[0,0,0,2,0,0]];

	int[][] xSolve6x6 =    [[2,6,1,5,4,3],
							[5,3,4,6,2,1],
							[1,2,6,4,3,5],
							[3,4,5,1,6,2],
							[4,1,2,3,5,6],
							[6,5,3,2,1,4]];
}

@("core:sudoku:sudoku: x solve 4x4")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku4x4);
	grid.initialize(x4x4);
	ClassicRule.create(grid);
	XRule.create(grid);

	Sudoku sudoku = new Sudoku(grid);

	assertTrue(sudoku.solve().equal(xSolve4x4));
}

@("core:sudoku:sudoku: x solve 6x6")
unittest
{
	import std.algorithm : equal;

	Grid grid = new Grid(SudokuType.Sudoku6x6);
	grid.initialize(x6x6);
	ClassicRule.create(grid);
	XRule.create(grid);

	Sudoku sudoku = new Sudoku(grid);

	assertTrue(sudoku.solve().equal(xSolve6x6));
}
