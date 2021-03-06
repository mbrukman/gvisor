#!/bin/bash

# Copyright 2018 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Fail on any error.
set -e
# Display commands to stderr.
set -x

# Install the latest version of Bazel.
use_bazel.sh latest

# Log the bazel path and version.
which bazel
bazel version

cd git/repo

# Build everything.
bazel build //...

# Run the tests and upload results.
#
# We turn off "-e" flag because we must move the log files even if the test
# fails.
set +e
bazel test --test_output=errors //...
exit_code=${?}
set -e

# Find and rename all test logs so that Sponge can pick them up.
for file in $(find -L "bazel-testlogs" -name "test.xml"); do
    newpath=${KOKORO_ARTIFACTS_DIR}/$(dirname ${file})
    # XML logs must be named sponge_log.xml for sponge to process them.
    mkdir -p "${newpath}" && cp "${file}" "${newpath}/sponge_log.xml"
done
for file in $(find -L "bazel-testlogs" -name "test.log"); do
    newpath=${KOKORO_ARTIFACTS_DIR}/$(dirname ${file})
    mkdir -p "${newpath}" && cp "${file}" "${newpath}"
done

exit ${exit_code}
