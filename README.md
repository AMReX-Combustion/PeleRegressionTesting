# Pele Regression Testing suite

The regression tests are managed using the regression testing tools
that are distributed as part of the AMReX Codes.  The tools are a custom set of
python scripts that orchestrate repository "pull" operations of AMReX
and the application codes built on top of it.  For each defined
test, an executable is built according to compile-time
parameters/defines, and is run in serial or parallel; the results of
the runs (in the form of plotfiles) are compared with "benchmark" reference
solutions.  The results of the tests are assembled, formatted in html.  If
any of the tests fail, an email is (optionally) generated and sent to a specified
list of recipients.

This repository contains configuration files for use with the AMReX regression test suite that
have been customized to the Pele project.  These regression tests are
also set up to be run on designated "runner" machines, triggered
on git merge requests, pushes, or other relevant events.

In order to run the tests (either manually/locally or on an automated runner),
a scratch area on the runner machine is designated for each cloned repository
needed to build the tests, and the regression test results (including the benchmark
results).  A key design feature of the regression suite is that the reference
solutions can be updated manually at any time.  This is necessary
when, for example, a bug is discovered or an algorithm change results
in improved solutions or modified error metrics.  For this reason, the
initial set of benchmarks need to be created manually before the first
test is executed.

## Setting up the test runner with an AMReX application

The following example commands will clone the required repositories into a scratch area, build the benchmarks
and run the tests.  The tests require a clone of the AMReX regression test suite,
the AMReX library, and the relevant `Pele` codes to test.  In this example, we are
testing `PeleC`, and so need `PelePhysics` and, of course, `PeleC`.  We assume that
the following environment variables are set for these steps

*  PELE_REGTEST_HOME: Location where this repository has been cloned
*  AMREX_HOME: Location of scratch repository for AMReX
*  AMREX_REGTEST_HOME: Location containing AMReX regression testing (cloned from 
`github.com:AMReX-Codes/regression_testing`)
*  PELEC_HOME: Location of scratch `PeleC` repository to be tested
*  PELE_PHYSICS_HOME: Location of scratch `PelePhysics` repository needed to support `PeleC`


1.  Move to the root of this repository and create the folder to contain the test results

    ```
    cd ${PELE_REGTEST_HOME}; mkdir -p TestData/PeleC
    ```

2.  Create a clone of `AMReX`, the AMReX `regression_testing` suite, `PeleC` and `PelePhysics`.  Note that the testing suite may optionally checkout specific branches or SHA1 commits of the needed repositories, but will always restore the repository to it's original state afterward.  Nevertheless, it is suggested to make a clone locally for the exclusive use of the regression test runners.

    ```
    git clone https://github.com/AMReX-Codes/amrex.git ${AMREX_HOME}
    git clone https://github.com/AMReX-Codes/regression_testing.git ${AMREX_REGTEST_HOME}
    git clone git@github.com:AMReX-Combustion/PeleC.git ${PELEC_HOME}
    git clone  git@github.com:AMReX-Combustion/PelePhysics.git ${PELE_PHYSICS_HOME}
    ```

3.  Generate the initial benchmark solution.  Rerunning this at any time will overwrite the previous versions of the benchmarks

    ```
    ${AMREX_REGTEST_HOME}/regtest.py --make_benchmarks "Benchmarks 20161012" ${PELE_REGTEST_HOME}/Scripts/PeleC-tests.ini
    ```

4. Upon some trigger event, re-run the tests and format the results in html.  In this case, the results will appear as TestData/PeleC/www/index.html

    ```
    ${AMREX_REGTEST_HOME}/regtest.py ${PELE_REGTEST_HOME}/Scripts/PeleC-tests.ini
    ```
