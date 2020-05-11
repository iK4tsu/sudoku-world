module core.rule.rule;

import core.sudoku.sudoku;

public abstract class Rule
{
	/** Connects a Sudoku to a Rule
	 *
	 * After connecting a Sudoku to a Rule it's initializer is called
	 *
	 * Params:
	 *     sudoku = Sudoku to connect
	 */
	public void connect(Sudoku sudoku)
	{
		this.sudoku = sudoku;
		initialize();
	}

	public abstract void initialize();

	public Sudoku sudoku;
}
