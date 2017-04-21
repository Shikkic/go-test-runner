#!/bin/bash
EXIT_STATUS=0

# WIP
# Reference command environator integration_test go test -v -cover -coverprofile=coverage.out -covermode=count $pkg;
#GO_TEST_COMMAND_ARG='environator integration_test go test -v -cover -coverprofile=coverage.out -covermode=count $pkg'
#verbose='false'
file_path='.'

# Parse Flags
while getopts 'f:' flag; do
  case "${flag}" in
    #v) verbose='true' ;;
    f) file_path="${OPTARG}" ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

echo "${file_path} IS THE ARG";


COVERAGE_FILEPATH="${PWD}/coverage-all.out"
MOCK_ARR=() 

cd "$file_path"
echo "OUR PATH: $PWD"
echo "mode: count" > coverage-all.out

for pkg in $(find . -name *.go -print0 | xargs -0 -n1 dirname | sort --unique ); do
    # If the pkg filepath contains 'vendor' we do not want to test it.
    if ! [[ $pkg == *"vendor"* ]]; then
        echo "pkgs: $pkg";
        # Run the go cover and output results to 'coverage.out'.
        OUTPUT=$(environator integration_test go test -v -cover -coverprofile=coverage.out -covermode=count $pkg);
        if [[ $OUTPUT == *"[no test files]" ]]; then
            BASE_FOLDER_NAME=$(basename $pkg);
            MOCK_FILE_PATH="${PWD}/${pkg}/${BASE_FOLDER_NAME}_test.go";
            MOCK_ARR+=($MOCK_FILE_PATH)
            touch $MOCK_FILE_PATH;
            echo "package ${BASE_FOLDER_NAME}" > $MOCK_FILE_PATH;
            environator integration_test go test -v -cover -coverprofile=coverage.out -covermode=count $pkg;
        fi
        # Take the results of coverage.out and append them to coverage-all.out.
        tail -n +2 coverage.out >> coverage-all.out;
    fi
done

echo -e "\e[32m";
environator integration_test go tool cover -func=$COVERAGE_FILEPATH;
echo -e "\e[0m";

echo "Deleteing Mock Test Files";
for i in "${MOCK_ARR[@]}"
do
    echo -e "\e[31mDeleteing $i\e[0m";
    #rm $i;
done
echo "";

echo -e "\e[32mExiting with status code $EXIT_STATUS\e[0m";
exit $EXIT_STATUS;
