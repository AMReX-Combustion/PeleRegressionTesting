# Pele Regression Testing suite

The regression tests are managed using the "RegressionTesting" tools
that are distributed as part of AMReX.  The tools are a custom set of
python scripts that orchestrate repository "pull" operations of AMReX
and the application codes built on top of AMReX.  For each defined
test, an executable is built according to compile-time
parameters/defines, and is run in serial or parallel; the results of
the runs are compared with "benchmark" reference solutions.  The
results of the tests are assembled, formatted in html and posted.  If
any of the tests fail, an email is generated and sent to a specified
list of recipients.

This folder contains configuration files for use with the tool set that
have been customized to the Pele project.  The regression tests should
be set up on a designated "runner" machine.  We are currently working
on several strategies to trigger the execution of the regression
tests, based on git merge requests, pushes, or other relevant events.

In order to run the tests, a scratch area on the runner machine is
designated for each cloned repository needed to build the tests, and
the regression test results (including the benchmark results).  A key
design feature of the AMReX regression suite is that the reference
solutions can be updated manually at any time.  This is necessary
when, for example, a bug is discovered or an algorithm change results
in improved solutions or modified error metrics.  For this reason, the
initial set of benchmarks need to be created manually before the first
test is executed.

## Setting up the test runner

The following commands setup the tests in the current folder, assuming
that AMREX_HOME is an environment variable that points to the
location of an existing AMReX git clone, and the file "PeleC-test.ini"
exists and is in the format of the example configuration files
provided with AMReX in the ${AMREX_HOME}/Tools/RegressionTesting
folder.

1.  Create the folder to contain the test results

    ```
    mkdir -p TestData/PeleC
    ```

2.  Create a clone of AMReX.  The testing suite may optionally checkout specific branches or SHA1 commits of AMReX, but will always restore the repository to it's original state afterward.  Nevertheless, it is suggested to make a clone locally for the exclusive use of the regression test runners:

    ```
    git clone https://github.com/AMReX-Codes/amrex.git Repositories/AMReX
    ```

3.  Similarly, create a clone of the application, and any supporting repositories

    ```
    git clone git@code.ornl.gov:Pele/PeleC.git Repositories/PeleC
    git clone git@code.ornl.gov:Pele/PelePhysics.git Repositories/PelePhysics
    ```

4.  Generate the initial benchmark solution.  Rerunning this at any time will overwrite the previous versions of the benchmarks

    ```
    ${AMREX_HOME}/Tools/RegressionTesting/regtest.py --make_benchmarks "Benchmarks 20161012" PeleC-tests.ini
    ```

5. Upon some trigger event, re-run the tests and post the results in html format.  In this case, the results will appear as TestData/PeleC/www/index.html

    ```
    ${AMREX_HOME}/Tools/RegressionTesting/regtest.py PeleC-tests.ini
    ```
