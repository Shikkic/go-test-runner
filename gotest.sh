#!/bin/bash
#
# Evaluate total Golag test coverage for a given filepath. Optionally returns an error if test coverage is below a passed in threshold.
#
# (Written using Google's shell styleguide https://google.github.io/styleguide/shell.xml, for modifications to this script,
# please consult styling guide).

main () {
    #if [[ $(whoami) != "vagrant" ]]; then
    #    exit 1;
    #fi

    # Set globle variable defaults.
    EXIT_STATUS=0
    MIN_COVERAGE_NUM=0
    VERBOSE_FLAG='false'
    file_path='.'
    MOCK_ARR=(); 

    # Parse flags and assign to global variables.
    while getopts ':n:f:v' flag; do
    case "${flag}" in
        n) MIN_COVERAGE_NUM="${OPTARG}" ;;
        v) VERBOSE_FLAG="true" ;;
        f) file_path="${OPTARG}" ;;
        *) error "Unexpected option ${flag}" ;;
    esac
    done

    # Change our working directory to the file path provided.
    cd "$file_path";

    # Create a new coverage-all.out file.
    echo "mode: count" > coverage-all.out

    # Generate coverage numbers for all go files in the given file_path.
    generate_test_coverage

    # Generate test report, and parse the total coverage number.
    test_coverage_number=$(generate_test_coverage_number);
    print_handler "\e[32mTest Coverage Percentage: $test_coverage_number\e[0m";

    # Initiate clean up of any    
    clean_up

    print_handler "\e[32mExiting with status code $EXIT_STATUS\e[0m";
    exit $EXIT_STATUS;
}

generate_test_coverage () {
    # For each go file found. 
    for pkg in $(find . -name *.go -print0 | xargs -0 -n1 dirname | sort --unique ); do
        # If the pkg filepath contains 'vendor' we do not want to test it.
        if ! [[ $pkg == *"vendor"* ]]; then
            # Run the go cover and output results to 'coverage.out'.
            OUTPUT=$(environator integration_test go test -v -cover -coverprofile=coverage.out -covermode=count $pkg);
            if [[ $OUTPUT == *"[no test files]" ]]; then
                BASE_FOLDER_NAME=$(basename $pkg);
                MOCK_FILE_PATH="${PWD}/${pkg}/${BASE_FOLDER_NAME}_test.go";
                MOCK_ARR+=($MOCK_FILE_PATH)
                touch $MOCK_FILE_PATH;
                echo "package ${BASE_FOLDER_NAME}" > $MOCK_FILE_PATH;
                k=$(environator integration_test go test -v -cover -coverprofile=coverage.out -covermode=count $pkg);
            fi
            # Take the results of coverage.out and append them to coverage-all.out.
            tail -n +2 coverage.out >> coverage-all.out;
        fi
    done
}



generate_test_coverage_number ()  {
    local golang_test_coverage_report;
    golang_test_coverage_report=$(environator integration_test go tool cover -func="${PWD}/coverage-all.out");

    local test_coverage_number;
    test_coverage_number=$(parse_test_coverage_number "$golang_test_coverage_report");

    echo $test_coverage_number;
}

parse_test_coverage_number() {
    local tail_of_report_string;
    tail_of_report_string=$(echo $1 | tail -1);

    local report_string_array;
    report_string_array=($tail_of_report_string);

    local total_test_coverage_percentage;
    total_test_coverage_percentage=${report_string_array[-1]};
    
    local total_test_coverage_number;
    total_test_coverage_number=$(echo $total_test_coverage_percentage | sed 's/%//');

    echo $total_test_coverage_number;
}

clean_up () {
    print_handler "Deleteing Mock Test Files";
    for i in "${MOCK_ARR[@]}"
    do
        print_handler "\e[31mDeleteing $i\e[0m";
        #rm $i;
    done
    print_handler "";
}

print_handler () {
    if [[ "$VERBOSE_FLAG" = "true" ]]; then
        echo -e $1
    fi
}

# Run the main method.
main "$@"