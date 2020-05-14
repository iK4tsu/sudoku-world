module ui.sudokuHelper;

import std.algorithm : canFind, countUntil, remove, sort;
import std.experimental.logger;

import ui.sudokuCell;

public class SudokuHelper
{
	/** Adds a digit
	 *
	 * Used internaly by handle
	 */
	private void insert(string digit)
	{
		_digits ~= digit;
		digits.sort();
	}


	/** Removes a digit
	 *
	 * Used internaly by handle
	 */
	private void remove(string digit)
	{
		auto index = countUntil(digits, digit);
		_digits = digits.remove(index);
	}


	/** Process a digit
	 *
	 * If the digit already exists, then it'll be removed \
	 * Otherwise, it'll be added
	 *
	 * Params:
	 *     digit = digit to evaluate
	 */
	public void handle(string digit)
	{
		if (!canFind(digits, digit))
			insert(digit);
		else
			remove(digit);
	}


	/** Resets digits
	 *
	 */
	public void clear()
	{
		_digits = [];
	}


	public auto digits() @property
	{
		return _digits;
	}


	private string[] _digits;
}
