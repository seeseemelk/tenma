module api.tenma;

import models;
import vibe.vibe;
import tenma;

/**
An interface describing the functionality of a Tenma power supply.
*/
@path("api")
@safe interface ITenmaAPI
{
    /**
    Get information about the power supply.
    */
    PSUInfo getInfo();

    /**
    Get information about the state of the power supply.
    */
    PSUState getState();

    /**
    Changes the state of the power supply.
    */
    @bodyParam("state")
    PSUState postState(Json state);
}

/**
Implements the `ITenmaAPI` interface using libtenma.
*/
class TenmaAPI : ITenmaAPI
{
    private Tenma _tenma;

    /**
    Creates a new TenmaAPI object with a given Tenma power supply.
    */
    this(Tenma tenma)
    {
        _tenma = tenma;
    }

    /**
    Creates a new TenmaAPI object with a given serial port.
    */
    this(string serialPort)
    {
        this(new Tenma(serialPort));
    }

    override PSUInfo getInfo()
    {
        PSUInfo info;
        info.id = _tenma.id;
        return info;
    }

    override PSUState getState()
    {
        PSUState state;
        state.outputEnabled = _tenma.isOn;
        state.targetCurrent = _tenma.targetCurrent;
        state.actualCurrent = _tenma.current;
        state.targetVoltage = _tenma.targetVoltage;
        state.actualVoltage = _tenma.voltage;
        return state;
    }

    override PSUState postState(Json state)
    {
        const outputEnabled = state["outputEnabled"];
        if (outputEnabled.type() != Json.Type.undefined)
            _tenma.setOn(outputEnabled.to!bool);

        const targetCurrent = state["targetCurrent"];
        if (targetCurrent.type() != Json.Type.undefined)
            _tenma.targetCurrent = targetCurrent.to!float;

        const targetVoltage = state["targetVoltage"];
        if (targetVoltage.type() != Json.Type.undefined)
            _tenma.targetVoltage = targetVoltage.to!float;

        return getState();
    }
}

private void setOn(Tenma tenma, bool state) @safe
{
    if (state)
    {
        logInfo("Turning on PSU");
        tenma.on();
    }
    else
    {
        logInfo("Turning off PSU");
        tenma.off();
    }
}
