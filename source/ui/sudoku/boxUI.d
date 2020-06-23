module ui.sudoku.boxUI;

import std.typecons : tuple;

import gtk.Grid;

import core.sudoku.grid : SudokuType;

public class BoxUI : Grid
{
	public this(SudokuType type)
	{
		setRowSpacing(1);
		setColumnSpacing(1);
		setRowHomogeneous(false);
		setColumnHomogeneous(false);
		setSizeRequest(sizeRequest(type).expand);
	}


	private auto sizeRequest(SudokuType type)
	{
		final switch (type)
		{
			case SudokuType.Sudoku4x4: return tuple(300,300);
			case SudokuType.Sudoku6x6: return tuple(300,200);
			case SudokuType.Sudoku9x9: return tuple(195,195);
		}
	}
}
