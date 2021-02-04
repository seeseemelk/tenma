import std.stdio;
import std.string;

import tenma;

void main(string[] argv)
{
	string path = "/dev/ttyACM0";
	if (argv.length > 1)
		path = argv[1];
	Tenma tenma = new Tenma(path);
	for (;;)
	{
		write("> ");
		string[] input = readln().strip().split(' ');
		immutable command = input[0];
		string[] args = input[1..$];
		switch (command)
		{
			case "id":
				writeln("ID: " ~ tenma.id);
				break;
			case "raw":
				cmdRaw(tenma, args);
				break;
			case "on":
				tenma.on();
				break;
			case "off":
				tenma.off();
				break;
			case "targetVoltage":
				writefln!"Target voltage: %.03fV"(tenma.targetVoltage);
				break;
			case "voltage":
				writefln!"Voltage: %.03fV"(tenma.voltage);
				break;
			case "isOn":
				writefln!"Output state: %s"(tenma.isOn ? "on" : "off");
				break;
			case "state":
				cmdState(tenma);
				break;
			case "status":
				writefln!"Status: %s"(tenma.status);
				break;
			case "help":
				printUsage();
				break;
			default:
				writeln("Unknown command");
				printUsage();
		}
	}
}

private void printUsage()
{
	writeln("Commands:");
	writeln("  id - Print ID of the PSU");
	writeln("  on - Enable output");
	writeln("  off - Disable output");
	writeln("  isOn - Tests whether the PSU is on or not");
	writeln("  state - Print the entire state of the PSU");
	writeln("  status - Get the status");
	writeln("  voltage - Get the voltage of the PSU");
	writeln("  raw CMD - Send a raw command");
	writeln("  help - Print this help file");
}

private void cmdRaw(Tenma tenma, string[] args)
{
	if (args.length == 0)
		return;
	try
	{
		tenma.send(args[0]);
		writefln!`Response: "%s"`(tenma.read());
	}
	catch (SerialPortTimeOutException e)
	{
		writeln("Time out while waiting for response");
	}
}

private void cmdState(Tenma tenma)
{
	writefln!"Output state: %s"(tenma.isOn ? "on" : "off");
	writefln!"Voltage: %.03fV"(tenma.voltage);
	writefln!"Current: %.03fA"(tenma.current);
}
