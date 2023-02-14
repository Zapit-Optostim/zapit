# Zapit Tests

This directory contains software tests.
It should not be added to the MATLAB path.
Some tests are automated and run with MATLAB's testing framework.
Other tests are more interactive and are used for development or troubleshooting.


## How to run
To run the unit tests:

>> runtests

or 

>> table(runtests)

                        Name                        Passed    Failed    Incomplete    Duration       Details   
    ____________________________________________    ______    ______    __________    _________    ____________
    {'waveform_tests/checkWaveformsMatch'      }    true      false       false          1.0318    {1×1 struct}
    {'waveform_tests/checkWaveformsDoNotMatch' }    true      false       false        0.051651    {1×1 struct}
    {'zapit_build_tests/checkSimulated'        }    true      false       false          2.2722    {1×1 struct}
    {'zapit_build_tests/componentsPresent'     }    true      false       false       0.0089837    {1×1 struct}
    {'zapit_build_tests/componentsCorrectClass'}    true      false       false        0.060016    {1×1 struct}


To run specific tests:
>> run(zapit_build_tests);
>> run(waveform_tests);


What if there are failures? For example, say we see:

Failure Summary:

     Name                                            Failed  Incomplete  Reason(s)
    =============================================================================================
     waveform_tests/checkWaveformsMatch                 X               Failed by verification.
    ---------------------------------------------------------------------------------------------
     zapit_build_tests/componentsCorrectClass           X               Failed by verification.


