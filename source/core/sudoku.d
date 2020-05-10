module core.sudoku;

version(unittest) { import aurorafw.unit; }

import std.json;

import ui.sudokuBoard;

public class Sudoku
{
	// TODO: core: Sudoku: finish toJson parsing
	public static void toJson(SudokuBoard board)
	{
		string sudokuType = board.type;
		JSONValue j = ["sudokuType": sudokuType];

		auto cells = board.toCells();
		j.object["sudoku"] = ["grid" : cells];

		auto rules = ["SudokuClassic"];
		j.object["sudoku"]["rules"] = rules;

		import std.typecons : tuple;
		auto dim = board.dimensions();

		j.object["rows"] = dim.rows;
		j.object["columns"] = dim.columns;
		j.object["regionRows"] = dim.regionRows;
		j.object["regionColumns"] = dim.regionColumns;

		// TODO: core: Sudoku: implement file name
		import std.file : write, exists;
		auto f = "temp.json";

		write(f, j.toJSON(true));
	}

	// TODO: core: Sudoku: implement fromJson parsing
	public static bool fromJson(string file)
	{
		import std.file : FileException, exists, readText;
		import std.exception : enforce;

		if (!file.exists) return false;



		return true;
	}
}
