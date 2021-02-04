module models.state;

import std.typecons;

/**
Contains state information that can change often.
*/
struct PSUState
{
    /// `true` if the power supply is enabled, `false` if it is off.
    bool outputEnabled;

    /// The target voltage to output.
    float targetVoltage;

    /// The voltage that is actually being put out.
    float actualVoltage;

    /// Thet target current to output.
    float targetCurrent;

    /// The  current that is actually being consumed.
    float actualCurrent;
}
