function loadenv
    # Check if a file was provided as argument
    if test (count $argv) -ne 1
        echo "Usage: loadenv <.env file>"
        return 1
    end

    # Check if file exists
    if not test -f $argv[1]
        echo "Error: File '$argv[1]' does not exist"
        return 1
    end

    # Read each line from the file
    for line in (cat $argv[1])
        # Skip comments and empty lines
        if string match -qr '^\s*#' $line; or test -z (string trim $line)
            continue
        end

        # Remove any comments at the end of the line
        set line (string split '#' $line)[1]

        # Split into key and value
        set pair (string split -m 1 '=' $line)
        if test (count $pair) -eq 2
            # Trim whitespace and quotes
            set key (string trim -c ' "'\''' $pair[1])
            set value (string trim -c ' "'\''' $pair[2])

            # Set the environment variable
            set -gx $key $value
        end
    end
end
