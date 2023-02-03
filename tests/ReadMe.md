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

To run specific tests:
>> run(zapit_build_tests);
>> run(recipe_tests);


What if there are failures? For example, say we see:

Failure Summary:

     Name                                            Failed  Incomplete  Reason(s)
    =============================================================================================
     recipe_tests/checkTilePositions                   X                 Failed by verification.
    ---------------------------------------------------------------------------------------------
     recipe_tests/checkHandlingOfSystemSettingsLoad    X                 Failed by verification.



Run just one test:
 T=recipe_tests 
 T.checkTilePositions