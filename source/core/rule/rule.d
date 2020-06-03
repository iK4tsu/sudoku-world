module core.rule.rule;

import core.ruleType : RuleType;
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

	public static void createFromJSON(RuleType type, Sudoku sudoku)
	{
		import core.rule.classic : ClassicRule;
		import core.rule.x : XRule;
		final switch (type)
		{
			case RuleType.CLASSIC: sudoku.add(new ClassicRule()); break;
			case RuleType.X: sudoku.add(new XRule()); break;
		}
	}

	public static RuleType toRuleType(string type)
	{
		import std.traits : EnumMembers;
		foreach (enum rule; EnumMembers!RuleType)
		{
			if (rule == type)
				return rule;
		}
		return null;
	}

	public abstract void initialize();

	public Sudoku sudoku;
}
