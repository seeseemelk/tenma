module tenma;

import onyx.serial;
public import onyx.serial : SerialPortException, SerialPortTimeOutException;

import std.conv;
import std.format;

version(unittest)
{
	struct SerialPort
	{
		bool opened = false;
		void delegate(string) onWrite;
		string delegate() onRead;

		void open()
		{
			opened = true;
		}

		void write(const(ubyte[]) str)
		{
			onWrite(cast(string) str);
		}

		const(ubyte[]) read(int, ReadMode readmode)
		{
			return cast(const(ubyte[])) onRead();
		}

		this(string, Speed, Parity, int) {}
	}
}
else
{
	alias SerialPort = OxSerialPort;
}


/**
A class that controls a TENMA power supply.
*/
final class Tenma
{
	private SerialPort _port;

	/**
	Opens a TENMA power supply.
	Parameters:
		path = Path to the serial port.
	*/
	this(string path)
	{
		_port = SerialPort(path, Speed.S115200, Parity.none, 50);
		_port.open();
	}

	version(unittest)
	{
		private static void validate(string send, string read, void delegate(scope Tenma) callback)
		{
			scope tenma = new Tenma("");
			bool called = false;
			tenma._port.onWrite = (str)
			{
				called = true;
				assert(str == send, "Incorrect data written");
			};
			tenma._port.onRead = () => read;
			callback(tenma);
			assert(called == true, "Write not called");
		}
	}

	/**
	Gets the ID of the power supply.
	*/
	string id() @safe
	{
		send("*IDN?");
		return read();
	}

	@("Can read device id")
	unittest
	{
		validate("*IDN?", "DeviceId", (tenma)
		{
			assert(tenma.id == "DeviceId", "Bad device identifier returned");
		});
	}

	/**
	Enables the output of the power supply.
	*/
	void on() @safe
	{
		send("OUT1");
		waitForTimeout();
		/*try
		{
			status();
		}
		catch (SerialPortTimeOutException ex)
		{
			// We ignore while waiting for the OUT1 command to finish.
		}*/
	}

	@("Can enable output")
	unittest
	{
		validate("OUT1", "", tenma => tenma.on);
	}

	/**
	Disables the output of the power supply.
	*/
	void off() @safe
	{
		send("OUT0");
		waitForTimeout();
	}

	@("Can disable output")
	unittest
	{
		validate("OUT0", "", tenma => tenma.off);
	}

	/**
	Checks whether the output of the power supply is enabled or not.
	*/
	bool isOn() @safe
	{
		return (status & 0x40) > 0;
	}

	@("Can get output state")
	unittest
	{
		validate("STATUS?", "A", (tenma)
		{
			assert(tenma.isOn == true, "Output was not detected as on");
		});
		validate("STATUS?", " ", (tenma)
		{
			assert(tenma.isOn == false, "Output was not detected as off");
		});
	}

	/**
	Get the status string of the power supply.
	*/
	ubyte status() @safe
	{
		send("STATUS?");
		return rawRead(1)[0];
	}

	/**
	Gets the target voltage of the power supply.
	*/
	float targetVoltage() @safe
	{
		send("VSET1?");
		return read().to!float;
	}

	@("Can read target voltage")
	unittest
	{
		validate("VSET1?", "1.23", (tenma)
		{
			const voltage = tenma.targetVoltage;
			assert(voltage > 1.229 && voltage < 1.231, "Voltage was not parsed correctly");
		});
	}

	/**
	Sets the target voltage of the power supply.
	*/
	void targetVoltage(float voltage) @safe
	{
		send(format!"VSET1=%.3f"(voltage));
	}

	@("Can read target voltage")
	unittest
	{
		validate("VSET1=1.234", "", (tenma)
		{
			tenma.targetVoltage = 1.234f;
		});
	}

	/**
	Gets the current voltage of the power supply.
	*/
	float voltage() @safe
	{
		send("VOUT1?");
		return read().to!float;
	}

	@("Can read output voltage")
	unittest
	{
		validate("VOUT1?", "1.23", (tenma)
		{
			const voltage = tenma.voltage;
			assert(voltage > 1.229 && voltage < 1.231, "Voltage was not parsed correctly");
		});
	}

	/**
	Gets the target current of the power supply.
	*/
	float targetCurrent() @safe
	{
		send("ISET1?");
		return read().to!float;
	}

	@("Can read target current")
	unittest
	{
		validate("ISET1?", "1.23", (tenma)
		{
			const voltage = tenma.targetCurrent;
			assert(voltage > 1.229 && voltage < 1.231, "Voltage was not parsed correctly");
		});
	}

	/**
	Sets the target current of the power supply.
	*/
	void targetCurrent(float current) @safe
	{
		send(format!"ISET1=%.3f"(current));
	}

	@("Can read target current")
	unittest
	{
		validate("ISET1=1.234", "", (tenma)
		{
			tenma.targetCurrent = 1.234f;
		});
	}

	/**
	Gets the current output of the power supply.
	*/
	float current() @safe
	{
		send("IOUT1?");
		return read().to!float;
	}

	@("Can read output current")
	unittest
	{
		validate("IOUT1?", "1.23", (tenma)
		{
			const current = tenma.current;
			assert(current > 1.229 && current < 1.231, "Current was not parsed correctly");
		});
	}

	/**
	Sends a command to the power supply.
	*/
	void send(string str) @safe
	{
		import std.string : representation;
		send(str.representation.dup);
	}

	private void send(ubyte[] data) @trusted
	{
		_port.write(data);
	}

	/**
	Reads a response from the power supply.
	*/
	string read() @safe
	{
		import std.string : assumeUTF;
		return rawRead().assumeUTF();
	}

	private const(ubyte[]) rawRead(int length = 100) @trusted
	{
		return _port.read(length, ReadMode.waitForTimeout);
	}

	private void waitForTimeout() @trusted
	{
		try
		{
			_port.read(1, ReadMode.waitForTimeout);
		}
		catch (SerialPortTimeOutException ex)
		{
			// Ignore.
		}
	}
}
