module core.constraint.unique;

import std.algorithm : canFind, map;
import std.typecons : tuple;

import core.constraint.constraint;
import core.sudoku.cell;

/** Unique constraint
 *
 * Each Cell must be unique, no other Cell can have the same digit,
 *     in a given Cell[]
 */
public class UniqueConstraint : Constraint
{
	private this(Cell[] cells ...)
	{
		super (ConstraintType.Unique);
		this._cells ~= cells;
	}


	public static auto createSingle(Cell cell1, Cell cell2)
	{
		if (cell1 is null || cell2 is null) return;
		UniqueConstraint uc1 = new UniqueConstraint(cell1, cell2);
		uc1.connect(cell1);
		UniqueConstraint uc2 = new UniqueConstraint(cell1, cell2);
		uc2.connect(cell2);
	}


	public static auto createMultiSingle(Cell cell, Cell[] cells...)
	{
		if (cell is null) return;
		foreach (Cell c; cells)
		{
			if (c is null) return;
			if (c != cell)
				createSingle(cell, c);
		}
	}


	public static auto createInterconnected(Cell[] cells...)
	{
		foreach (Cell cell; cells)
		{
			if (cell is null) return;
			createMultiSingle(cell, cells);
		}
	}


	public static ConstraintType getStaticConstraintType()
	{
		return ConstraintType.Unique;
	}


	public static void createFromJSON(string jsonString, Cell[][] cells)
	{
		import std.json;
		JSONValue json = parseJSON(jsonString);

		if ("interconnected" in json)
		{
			interconnectedFromJSON(json["interconnected"].toString(), cells);
		}

		if ("multiSingle" in json)
		{
			multiSingleFromJSON(json["multiSingle"].toString(), cells);
		}

		if ("single" in json)
		{
			singleFromJSON(json["single"].toString(), cells);
		}
	}


	private static void singleFromJSON(string jsonString, Cell[][] c)
	{
		import std.json;
		JSONValue json = parseJSON(jsonString);

		foreach (JSONValue value; json.array)
		{
			Cell cell1 = c[value["cell1"]["row"].integer][value["cell1"]["column"].integer];
			Cell cell2 = c[value["cell2"]["row"].integer][value["cell2"]["column"].integer];
			createSingle(cell1, cell2);
		}
	}


	private static void multiSingleFromJSON(string jsonString, Cell[][] c)
	{
		import std.json;
		JSONValue json = parseJSON(jsonString);

		foreach (JSONValue value; json.array)
		{
			Cell cell = c[value["cell"]["row"].integer][value["cell"]["column"].integer];
			Cell[] cells;
			foreach (JSONValue group; value["group"].array)
			{
				cells ~= c[group["row"].integer][group["column"].integer];
			}
			createMultiSingle(cell, cells);
		}
	}


	private static void interconnectedFromJSON(string jsonString, Cell[][] c)
	{
		import std.json;
		JSONValue json = parseJSON(jsonString);

		foreach (JSONValue value; json.array)
		{
			Cell[] cells;
			foreach (JSONValue group; value["group"].array)
			{
				cells ~= c[group["row"].integer][group["column"].integer];
			}
			createInterconnected(cells);
		}
	}


	/** Connect a Cell to this Constraint
	 *
	 * Params:
	 *     cell = Cell to connect
	 */
	override
	public void connect(Cell cell)
	{
		cell.connect(this);
	}

	/** Search for the same digit
	 *
	 * Used to find if the digit being inserted to a Cell is unique in a
	 *     group of cells
	 *
	 * Params:
	 *     digit = value to check
	 *
	 * Returns:
	 *     `true` if the value is unique \
	 *     `false` otherwise
	 */
	override
	public bool isValid(in int digit)
	{
		return !canFind(cells.map!(x => x.digit), digit);
	}
}


version(unittest) { import aurorafw.unit; }

@("core:constraint:unique: ctor")
unittest
{
	Cell[] cells = [new Cell(4), new Cell(0)];
	UniqueConstraint.createInterconnected(cells);

	UniqueConstraint constraint = cells[0].get!UniqueConstraint;
	assertTrue(constraint !is null);
	assertTrue(constraint.isValid(2));
	assertFalse(constraint.isValid(4));
}


@("core:constraint:unique: connect")
unittest
{
	Cell[] cells = [new Cell(4), new Cell(0)];
	UniqueConstraint.createInterconnected(cells);

	Cell cell = new Cell(2);
	UniqueConstraint.createMultiSingle(cell, cells);

	UniqueConstraint uc0 = cells[0].get!UniqueConstraint;
	assertTrue(canFind(uc0.cells, cell));
	assertTrue(uc0.isValid(1));
	assertFalse(uc0.isValid(2));

	UniqueConstraint uc1 = cells[1].get!UniqueConstraint;
	UniqueConstraint uc2 = cell.get!UniqueConstraint;
	assertTrue(uc0 != uc1 && uc1 != uc2);


	assertTrue(uc0.cells == uc1.cells && uc1.cells && uc2.cells);
	assertTrue(uc0.cells == cells~cell);
}


@("core:constraint:unique: createSingle")
unittest
{
	Cell[] cells = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createSingle(cells[0], cells[1]);

	UniqueConstraint uc0 = cells[0].get!UniqueConstraint;

	UniqueConstraint uc1 = cells[1].get!UniqueConstraint;
	UniqueConstraint uc2 = cells[2].get!UniqueConstraint;
	assertTrue(uc0.cells == cells[0 .. 2]);
	assertTrue(uc1.cells == uc0.cells);
	assertTrue(uc2 is null);

	UniqueConstraint.createSingle(cells[1], cells[2]);
	uc2 = cells[2].get!UniqueConstraint;
	assertTrue(uc1.cells == cells);
	assertTrue(uc2.cells.length == uc0.cells.length);
}


@("core:constraint:unique: createMultiSingle")
unittest
{
	Cell[] cells1 = [new Cell(2), new Cell(3), new Cell(5)];
	Cell[] cells2 = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createMultiSingle(cells1[0], cells1[0 .. 3]);
	UniqueConstraint.createMultiSingle(cells2[0], cells2[1 .. 3]);

	UniqueConstraint uc1 = cells1[0].get!UniqueConstraint;
	UniqueConstraint uc2 = cells2[0].get!UniqueConstraint;

	import core.sudoku.grid : Grid;
	assertTrue(Grid.toDigit(uc1.cells) == Grid.toDigit(uc2.cells));
	assertTrue(uc1.cells.length == 3);

	UniqueConstraint uc3 = cells1[1].get!UniqueConstraint;
	assertTrue(uc3.cells == cells1[0 .. 2]);

	UniqueConstraint.createMultiSingle(cells1[0], new Cell(6), new Cell(7));
	assertTrue(uc1.cells.length == 5);
}


@("core:constraint:unique: createInterconnected")
unittest
{
	Cell[] cells1 = [new Cell(2), new Cell(3), new Cell(5)];
	UniqueConstraint.createInterconnected(cells1);

	UniqueConstraint uc0 = cells1[0].get!UniqueConstraint;
	UniqueConstraint uc1 = cells1[1].get!UniqueConstraint;
	UniqueConstraint uc2 = cells1[2].get!UniqueConstraint;

	import std.algorithm : sort;
	import std.array : array;
	assertTrue(uc0.cells == uc1.cells); // [2,3,5]
	// we need to sort for it to be considered the same array
	// the logic involved in the construction of the array doesn't sort Cells
	assertTrue(uc2.cells == [cells1[0], cells1[2], cells1[1]]); // [2,5,3]
	assertTrue(uc1.cells == sort!((a,b) => a.digit < b.digit)(uc2.cells).array);

	UniqueConstraint.createInterconnected(cells1 ~ new Cell(7));
	assertTrue(uc0.cells.length == 4);
	assertTrue(uc0.cells == uc1.cells && uc1.cells == uc2.cells); // [2,3,5,7]

	Cell cell = new Cell(10);
	UniqueConstraint.createInterconnected(cell ~ cells1[0 .. 2]); // [10,2,3]
	assertTrue(uc0.cells.length == uc1.cells.length); // 5
	assertTrue(uc0.cells != cell.get!UniqueConstraint.cells);
	assertTrue(cell.get!UniqueConstraint.cells == cell ~ cells1[0 .. 2]);
}
