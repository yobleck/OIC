# OIC
ollama interactive conxext plugin for sublime text 4

## Installation
drop the files in the sublime text ```Packages/User``` folder

often found in ```~/.config/sublime-text``` on Linux

copy keybinds
```
{
        "keys": ["ctrl+alt+shift+o"],
        "command": "ollama_interactive_context"
    },
    {
        "keys": ["ctrl+alt+shift+g"],
        "command": "generate_new_context"
    },
    {
        "keys": ["ctrl+alt+shift+a"],
        "command": "append_user_input"
    },
    {
        "keys": ["ctrl+alt+shift+l"],
        "command": "list_models"
    },
```

install [prettyjson](https://packagecontrol.io/packages/Pretty%20JSON) package from packagecontrol.io

## Usage
run ollama server

temporary: edit url variable in the ollama_interactive_context.py file if needed

open a new file with ctrl+n

ctrl+shift+p to open the command palette

run the generate new context command to format the file as a scratchpad and add the json template that ollama uses to send data to the server

use the list models command to get the model you want to use (this can be changed at any time)

use the interactive context command to send the data to the server

use the append user input command to add user input json template to the end of the messages list

edit any mistakes in the model output to avoid poisoned context

repeat
