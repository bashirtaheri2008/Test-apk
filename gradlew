#!/bin/sh
# Gradle wrapper script - delegates to gradle-wrapper.jar
# In CI, the gradle/actions/setup-gradle handles this
exec gradle "$@"
