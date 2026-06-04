#!/usr/bin/bash

PROGRESS_LOG_FILE="${PROGRESS_LOG_FILE:-/tmp/dtu_log.txt}"
PROGRESS_LOG_LINES="${PROGRESS_LOG_LINES:-13}"
PROGRESS_BOX_WIDTH="${PROGRESS_BOX_WIDTH:-84}"

progress_intro_title() {
    echo "Welcome to the DTU Python Installation Support setup."
}

progress_intro_lines() {
    cat <<'EOF'
This setup is for first-year DTU students.
It installs Conda, Python, the required course packages,
and Visual Studio Code.

It is intended for courses such as Mathematics 1a,
Mathematics 1b, Statistics, Physics,
and Computer Programming.

You do not need much coding experience to complete this setup.
The installation will begin in a moment.
EOF
}

# Params:
# - message: str
# - estimated time: int
# - command: str list
progress() {
    local msg=$1 mins=$2 log_file="$PROGRESS_LOG_FILE" start_line=1
    local requested_box_width="$PROGRESS_BOX_WIDTH"
    local requested_box_lines="$PROGRESS_LOG_LINES"
    local box_inner_width box_line_count footer_width term_cols term_rows max_inner_width max_box_lines
    local box_top box_bottom
    shift 2

    if [[ -f "$log_file" ]]; then
        start_line=$(($(wc -l <"$log_file")+1))
    else
        touch "$log_file" || return 1
    fi

    echo "[DTULOG]: $msg ($(date))" >> "$log_file"
    if [[ -t 1 ]] && test -w /dev/tty 2>/dev/null; then
        exec 4>/dev/tty
    else
        exec 4>&1
    fi

    cleanup() {
        tput smam >&4 2>/dev/null || printf '\033[?7h' >&4
        tput rmcup >&4 2>/dev/null || true
        tput cnorm >&4 2>/dev/null || true
    }

    type_line() {
        local line=$1 i
        for ((i = 0; i < ${#line}; i++)); do
            printf '%s' "${line:i:1}" >&4
            sleep 0.035
        done
        printf '\n' >&4
    }

    repeat_char() {
        local char=$1 count=$2 repeated=''
        while (( ${#repeated} < count )); do
            repeated+="$char"
        done
        printf '%s' "${repeated:0:count}"
    }

    setup_box_dimensions() {
        term_cols=$(tput cols 2>/dev/null || printf '100')
        if [[ ! "$term_cols" =~ ^[0-9]+$ ]]; then
            term_cols=100
        fi
        term_rows=$(tput lines 2>/dev/null || printf '30')
        if [[ ! "$term_rows" =~ ^[0-9]+$ ]]; then
            term_rows=30
        fi

        max_inner_width=$((term_cols - 6))
        if (( max_inner_width < 40 )); then
            max_inner_width=40
        fi
        max_box_lines=$((term_rows - 10))
        if (( max_box_lines < 6 )); then
            max_box_lines=6
        fi

        box_inner_width=$requested_box_width
        if (( box_inner_width > max_inner_width )); then
            box_inner_width=$max_inner_width
        fi
        box_line_count=$requested_box_lines
        if (( box_line_count > max_box_lines )); then
            box_line_count=$max_box_lines
        fi

        footer_width=$((box_inner_width + 4))
        box_top="$(repeat_char '━' "$footer_width")"
        box_bottom="$(repeat_char '━' "$footer_width")"
    }

    print_box_line() {
        local line=${1//$'\r'/}
        line=${line//$'\t'/    }
        printf '  %-*.*s\n' "$box_inner_width" "$box_inner_width" "$line" >&4
    }

    print_footer_line() {
        local line=$1
        printf '  %-*.*s\n' "$footer_width" "$footer_width" "$line" >&4
    }

    process_stream() {
        DTU_DISPLAY_FILE="$display_file" DTU_LOG_FILE="$log_file" perl -e '
            use strict;
            use warnings;

            my $display_file = $ENV{DTU_DISPLAY_FILE};
            my $log_file = $ENV{DTU_LOG_FILE};

            open my $log_fh, ">>", $log_file or die "Cannot open log file: $!";
            binmode STDIN;
            binmode $log_fh;
            select((select($log_fh), $| = 1)[0]);

            my @lines = ();
            my $current_line = "";

            sub clean_output {
                my ($text) = @_;
                $text =~ s/\e\][^\a]*(?:\a|\e\\)//g;
                $text =~ s/\e\[[0-9;?]*[ -\/]*[@-~]//g;
                $text =~ s/[\x00-\x07\x0B\x0C\x0E-\x1F\x7F]//g;
                return $text;
            }

            sub clean_display_line {
                my ($line) = @_;
                $line =~ s#/var/folders/[^[:space:]]*/T/dtu-install-test\.[^/[:space:]]+#<sandbox>#g;
                $line =~ s/^\s+//;
                $line =~ s/\s+$//;
                return "" if $line =~ /^%\s+Total\s+%/;
                return "" if $line =~ /^Dload\s+Upload\s+Total/;
                return "" if $line =~ /^\d{1,3}\s+(?:\d+|[0-9.]+[KMGT]?)\s+/;
                return $line;
            }

            sub write_display {
                open my $display_fh, ">", $display_file or die "Cannot open display file: $!";
                binmode $display_fh;

                my @display_lines = ();
                my %package_line_index = ();

                for my $line (@lines, $current_line) {
                    my $display_line = clean_display_line($line);
                    next if $display_line eq "";
                    next if $display_line eq "done";

                    if ($display_line =~ /^([A-Za-z0-9_.+-]+)\s+\|.*\|\s*\d+%$/) {
                        my $package_name = $1;
                        if (exists $package_line_index{$package_name}) {
                            $display_lines[$package_line_index{$package_name}] = $display_line;
                        } else {
                            $package_line_index{$package_name} = scalar @display_lines;
                            push @display_lines, $display_line;
                        }
                        next;
                    }

                    push @display_lines, $display_line;
                }

                for my $display_line (@display_lines) {
                    print {$display_fh} "$display_line\n";
                }

                close $display_fh;
            }

            while (sysread(STDIN, my $chunk, 4096)) {
                my $clean_chunk = clean_output($chunk);
                my $log_chunk = $clean_chunk;
                $log_chunk =~ s/\r/\n/g;
                print {$log_fh} $log_chunk;

                for my $char (split //, $clean_chunk) {
                    if ($char eq "\r") {
                        $current_line = "";
                    } elsif ($char eq "\n") {
                        push @lines, $current_line;
                        $current_line = "";
                    } elsif ($char eq "\b") {
                        chop $current_line;
                    } elsif ($char eq "\t") {
                        $current_line .= "    ";
                    } else {
                        $current_line .= $char;
                    }
                }

                shift @lines while @lines > 200;
                write_display();
            }

            write_display();
            close $log_fh;
        '
    }

    render_recent_output() {
        local -a recent_lines=()
        local line_count=0 recent_line
        mapfile -t recent_lines < <(tail -n "$box_line_count" "$display_file" 2>/dev/null)

        for recent_line in "${recent_lines[@]}"; do
            print_box_line "$recent_line"
        done

        line_count=${#recent_lines[@]}

        while (( line_count < box_line_count )); do
            print_box_line ''
            line_count=$((line_count + 1))
        done
    }

    format_duration() {
        if (( mins == 1 )); then
            printf '%d minute' "$mins"
        else
            printf '%d minutes' "$mins"
        fi
    }

    show_intro() {
        local intro_line
        printf '  \033[1m%s\033[0m\n\n' "$(progress_intro_title)" >&4

        while IFS= read -r intro_line || [[ -n "$intro_line" ]]; do
            if [[ -z "$intro_line" ]]; then
                printf '\n' >&4
            else
                type_line "  $intro_line"
            fi
        done < <(progress_intro_lines)

        sleep 5.5
    }

    trap cleanup EXIT TERM HUP

    tput smcup >&4 2>/dev/null || true
    tput civis >&4 2>/dev/null || true
    tput rmam >&4 2>/dev/null || printf '\033[?7l' >&4

    if (( start_line == 1 )); then
        show_intro
    fi

    setup_box_dimensions

    local display_file
    display_file=$(mktemp)
    local status_file
    status_file=$(mktemp)

    (
        set +e
        NO_COLOR=1 CLICOLOR=0 CLICOLOR_FORCE=0 "$@" 2>&1
        printf '%s' "$?" > "$status_file"
    ) | process_stream &
    local cmd_pid=$!
    local spin='-\|/' i=0
    local spinner_char progress_line info_line

    while kill -0 "$cmd_pid" 2>/dev/null; do
        spinner_char="${spin:i++%${#spin}:1}"
        progress_line="[$spinner_char] $msg"
        info_line="Please do not interrupt this step - it may take up to $(format_duration)."

        printf '\e[H\e[2J' >&4
        printf '  \033[1m%s\033[0m\n' "DTU installation in progress." >&4
        printf '%s\n' "$box_top" >&4
        render_recent_output
        printf '%s\n' "$box_bottom" >&4
        printf '  \033[1m%-*.*s\033[0m\n' "$footer_width" "$footer_width" "$progress_line" >&4
        print_footer_line "$info_line"
        sleep 0.1
    done

    local status=0
    wait "$cmd_pid" || true
    if [[ -s "$status_file" ]]; then
        status=$(<"$status_file")
        rm -f "$status_file"
        if [[ ! "$status" =~ ^[0-9]+$ ]]; then
            status=1
        fi
    else
        status=1
    fi
    rm -f "$status_file" "$display_file"

    cleanup
    trap - EXIT TERM HUP
    echo "$msg"

    if (( status != 0 )); then
        echo  "[DTULOG]: failure ($status)" >> "$log_file"
        printf ' ┗━ \033[1;31m%s\033[00m (error code %d).\n' Failure $status
        echo "    Contact us by email or Discord:"
        echo "    pythonsupport@dtu.dk | https://discord.gg/h8EVaV9ShP"
        echo "    https://pythonsupport.dtu.dk/#reach-us"
        printf '    \033[1m%s\033[0m\n' "Please include the file '$log_file'."
    else
        echo  "[DTULOG]: success" >> "$log_file"
        printf ' ┗━ \033[1;32m%s\033[0m\n' 'Success!'
    fi

    return "$status"
}

output0() {
    echo 1; sleep 1
    echo 2; sleep 1
    echo 3; sleep 1
    echo 4; sleep 1
    echo 5; sleep 1
    echo 6; sleep 1
    echo done >&2; sleep 0.5
    return 0
}

output1() {
    echo 1; sleep 0.5
    echo 2; sleep 0.5
    echo 3; sleep 0.5
    echo 4; sleep 0.5
    echo 5; sleep 0.5
    echo 6; sleep 0.5
    echo done >&2; sleep 0.5
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    progress "Step 1/1: Installing XYZ" 15 output1
fi
