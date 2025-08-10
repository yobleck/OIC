#!/usr/bin/env xonsh
import json

# $OLLAMA_FLASH_ATTENTION=1  # ollama server not started here
# $OLLAMA_KV_CACHE_TYPE="q8_0"

if not $(which curl) and not $(which ollama):  # dep check
    print("'curl' and 'ollama' are required for this script")

if "VISUAL" not in ${...} and "EDITOR" not in ${...}:  # ${...} check list of env vars for text editor
    editor = input("$VISUAL and $EDITOR not found. please supply editor:\n")
elif "VISUAL" in ${...}:  # NOTE allow user to pick editor? config file?
    editor = $VISUAL
elif "EDITOR" in ${...}:
    editor = $EDITOR

files = $(ls | grep json).split("\n")[:-1]
print("0 new file")
[print(i + 1, f) for i, f in enumerate(files)]
file_num = input("choose json file:\n")
if int(file_num) == 0:  # TODO overwrite existing? search subfolders?
    filename = input("file name:\n")
    touch @(filename)
    if int($(stat --printf="%s" @(filename)).replace("\"", "")) == 0:  # only add template if file size == 0
        echo '{"model": "filler_model", "stream": false, "temp_options": {"num_ctx": 4096}, "messages": [{"role": "user", "content": "this is filler text"}]}' >> @(filename)
else:
    filename = files[int(file_num) - 1].rstrip("\n")

status = "started"
while True:
    clear
    j = None
    print("Ollama Interactive Context:\nstatus:", status)
    todo = input("""1: append user input template
2: open/edit file
3: choose model from list
4: send to server
5: quit
""")
    if int(todo) == 1:
        with open(filename, "r") as f:
            j = json.load(f)
        j["messages"].append({"role":"user", "content":"filler"})
        with open(filename, "w") as f:
            json.dump(j, f, indent=4)
        status = "template appended"
    
    elif int(todo) == 2:
        @(editor) @(filename)
        status = "file opened"
    
    elif int(todo) == 3:
        if $(pgrep ollama):
            model_list = $(ollama list).split("\n")[1:-1]
            model_list = [m.split(" ")[0] for m in model_list]
            [print(i, m) for i, m in enumerate(model_list)]
            model = input("select model:\n")
            with open(filename, "r") as f:
                j = json.load(f)
            j["model"] = model_list[int(model)]
            with open(filename, "w") as f:
                json.dump(j, f, indent=4)
            status = "model changed"
        else:
            print("ollama server not running?")
            break
    
    elif int(todo) == 4:
        pass
        if $(pgrep ollama):
            reply = $(curl http://localhost:11434/api/chat -d $(cat @(filename)))
            # print(reply)
            r = json.loads(reply)
            # print(r["message"])
            # exit()
            with open(filename, "r") as f:
                j = json.load(f)
            j["messages"].append(r["message"])
            # print(j)
            with open(filename, "w") as f:
                json.dump(j, f, indent=4)
            status = f"input sent to server. total time taken: {r['total_duration'] / 1e9:.1f}. input token count: {r['prompt_eval_count']}"
        else:
            print("ollama server not running?")
            break
    
    elif int(todo) == 5:
        break

clear
