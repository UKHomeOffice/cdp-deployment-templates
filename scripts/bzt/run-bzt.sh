#!/usr/bin/env sh

# runs Taurus and copies the test output to S3

# fail on error
set -e

PERF_TEST_CONF_GLOB=$1
export ARTIFACTS_DIR=bzt_artifacts
export DATE=$(date +%Y%m%d-%H%M%S)

echo running tests: ${PERF_TEST_CONF_GLOB}

# clean up any residuals from initial install
rm -rf bzt_artifacts/*

# run the performance tests, using the taurus jobs 
set +e
bzt -l bzt.log /bzt-config/${PERF_TEST_CONF_GLOB}
STATUS=$?
set -e

# install the aws cli so that we can copy to S3
# need to install in user mode as we are not running as root
virtualenv aws
source aws/bin/activate

pip install awscli

# IMPORTANT: when using environment variables below
# the format ${VARNAME-} is needed to avoid envsubst substituting
# the variable before its value is defined, when the job is run...

aws s3 cp ./jmeter.log s3://${PERF_TESTS_BUCKET-}/${DATE-}/jmeter.log
for test_out in ${ARTIFACTS_DIR-}/* ; do
    # get rid of the Bearer token in any files
    sed --in-place '/Bearer/d' ${test_out-}
    # copy the output files to S3
    aws s3 cp ${test_out-} s3://${PERF_TESTS_BUCKET-}/${DATE-}/${test_out-}
done

exit ${STATUS-}