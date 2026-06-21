function scloud
    set -l host $argv[1]
    set -l session ${argv[2]:-main}
    if test -z "$host"
        echo "Usage: scloud <hostname> [session_name]"
        return 1
    fi
    echo "Connecting to $host (session: $session) via shpool..."
    while true
        ssh -t $host "shpool attach $session"
        set -l exit_code $status
        # SSH exits with status 255 if the connection dropped/timed out.
        # If it exited with any other status, it means the remote shell exited normally.
        if test $exit_code -ne 255
            break
        end
        echo "⚠️ Connection lost (exit code $exit_code). Reconnecting in 3 seconds... (Press Ctrl+C to abort)"
        sleep 3
    end
end
