#!/bin/bash
INPUT=$1
PASSED_TESTS=`grep 'PASSED ' $INPUT | wc -l`
NEW_XPATHS=`grep 'NEW BETTER XPATH ' $INPUT | wc -l`
MISSED_TESTS=`grep -E 'MISSED other|MISSED enco' $INPUT | wc -l`
FAILED_TESTS=`grep 'FAIL http' $INPUT | wc -l`
N_TESTS=$(($FAILED_TESTS + $MISSED_TESTS + $NEW_XPATHS + $PASSED_TESTS))
PASSED_TESTS_PERCENT=$(echo "$PASSED_TESTS/$N_TESTS*100" | bc -l)
NEW_XPATHS_PERCENT=$(echo "$NEW_XPATHS/$N_TESTS*100" | bc -l)
MISSED_TESTS_PERCENT=$(echo "$MISSED_TESTS/$N_TESTS*100" | bc -l)
FAILED_TESTS_PERCENT=$(echo "$FAILED_TESTS/$N_TESTS*100" | bc -l)
echo -e "Passed tests:\t $PASSED_TESTS \t $PASSED_TESTS_PERCENT"
echo -e "New xpaths:\t $NEW_XPATHS \t $NEW_XPATHS_PERCENT"
echo -e "Missed tests:\t $MISSED_TESTS \t $MISSED_TESTS_PERCENT"
echo -e "Failed tests:\t $FAILED_TESTS \t $FAILED_TESTS_PERCENT"
echo -e "Total tests:\t $N_TESTS \t 100.0"
