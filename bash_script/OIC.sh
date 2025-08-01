#!/bin/bash
# Warning! this script was created by an LLM. qwen2.5-coder:14b
# by converting OIC.xsh to bash

# Dependency check
if ! command -v curl &> /dev/null || ! command -v ollama &> /dev/null; then
    echo "'curl' and 'ollama' are required for this script"
    exit 1
fi

# Editor check
if [[ -z "${VISUAL}" && -z "${EDITOR}" ]]; then
    read -p "$VISUAL and $EDITOR not found. please supply editor: " editor
elif [[ -n "${VISUAL}" ]]; then
    editor="${VISUAL}"
else
    editor="${EDITOR}"
fi

# Get file name
read -p "file name: " filename

# Touch the file
touch "$filename"

# Check if file size is 0 and add template if so
if [ $(stat --printf="%s" "$filename") -eq 0 ]; then
    echo '{"model": "filler_model", "stream": false, "messages": [{"role": "user", "content": "this is filler text"}]}' >> "$filename"
fi

status="started"

while true; do
    clear
    j=""
    echo "Ollama Interactive Context:"
    echo "status: $status"
    read -p "1: append user input template
2: open/edit file
3: choose model from list
4: send to server
5: quit
#? " todo

    case $todo in
        1)
            j=$(cat "$filename")
            j=$(echo "$j" | jq '.messages += [{"role": "user", "content": "filler"}]')
            echo "$j" > "$filename"
            status="template appended"
            ;;
        2)
            $editor "$filename"
            status="file opened"
            ;;
        3)
            if pgrep ollama &> /dev/null; then
                model_list=$(ollama list | tail -n +2 | awk '{print $1}')  # LLM originally over complicated this but fixed it in one extra try
                select model in $model_list; do
                    break
                done
                j=$(cat "$filename")
                j=$(echo "$j" | jq --arg model "$model" '.model = $model')
                echo "$j" > "$filename"
                status="model changed"
            else
                echo "ollama server not running?"
                break
            fi
            ;;
        4)
            if pgrep ollama &> /dev/null; then
                reply=$(curl http://localhost:11434/api/chat -d @"$filename")  # LLM repeatedly failed to explain what the @ does even though it generated it correctly the first time
                r=$(echo "$reply" | jq '.message')
                j=$(cat "$filename")
                j=$(echo "$j" | jq --argjson message "$r" '.messages += [$message]')
                echo "$j" > "$filename"
                status="query sent to server"
            else
                echo "ollama server not running?"
                break
            fi
            ;;
        5)
            break
            ;;
    esac
done

clear
