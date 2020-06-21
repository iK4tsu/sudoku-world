module extra;

private import std.conv : parse, to;
private import std.traits : isType;

version(unittest) { import aurorafw.unit; }

public E parseEnum(E)(string str)
	if (is(E == enum))
{
	return parse!E(str);
}

@("extra: parseEnum")
unittest
{
	enum Foo { a,b,c }
	assertTrue(Foo.b == ("b".parseEnum!Foo));
}


public string toEnumString(E)(E enumType)
	if (is(E == enum))
{
	return enumType.to!string;
}

@("extra: toEnumString")
unittest
{
	enum Foo { a,b,c }
	assertTrue(Foo.a.toEnumString() == "a");
}
