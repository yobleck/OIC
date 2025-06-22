import json
import os
import subprocess
from urllib.parse import urlencode
from urllib.request import Request, urlopen

import requests  # see dependencies.json and run Satisfy Libraries cmd
import sublime
import sublime_plugin


"""Workflow
recommend use pretty json package
open new file
hit keybind to populate file with messages json template
user types in first message
hit keybind to send to ollama. popup to select model or use default?
stream results? and write them back to the file
save file or use scratch file?
user adds new message and edits old context
repeat
"""
# TODO add command palette https://docs.sublimetext.io/guide/extensibility/command_palette.html
# TODO auto open new scratch pad and populate with json
# TODO command to auto add user json template to messages list
# TODO get model list
# TODO make url a setting
# TODO move everything to a folder
# TODO stream data  https://nickherrig.com/posts/streaming-requests/
# TODO turn ollama server check into function


def try_prettyjson():
    if "Pretty JSON.sublime-package" in os.listdir(sublime.installed_packages_path()):
        sublime.active_window().active_view().run_command("pretty_json")
    else:
        print("recommend installing PrettyJSON")


def is_not_json_file():
    if sublime.active_window().active_view().syntax() != sublime.Syntax('Packages/JSON/JSON.sublime-syntax', 'JSON', False, 'source.json'):
        print("not json file, aborting")
        return True
    return False


class OllamaInteractiveContextCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        print(self.view.size())
        if is_not_json_file():
            return

        # check if ollama server is running
        proc = subprocess.run(["/bin/bash", "-c", "pgrep ollama"],
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE,
                              shell=False)
        # print(proc)
        if not proc.stdout.decode():
            print("ollama server not found, aborting")
            return
        elif not proc.stdout.decode().split("\n")[0].isdigit():
            print("pgrep output not integer, aborting")
            return

        # Send data to ollama server
        url: str = "http://localhost:11434/api/chat"
        model: str = "zshrc/llama-3some-8b:latest"

        js: dict = json.loads(self.view.substr(sublime.Region(0, self.view.size())))
        # print(js)
        js["model"] = model
        res = requests.post(url, json=js).json()  # TODO check for errors like 404
        # print(res)
        js["messages"].append(res["message"])
        self.view.erase(edit, sublime.Region(0, self.view.size()))
        self.view.insert(edit, 0, json.dumps(js))
        try_prettyjson()


class GenerateNewContextCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        # TODO open new view?
        print("generating new context")
        if self.view.size() > 0:
            print("can't edit existing , make sure file is empty")
            return

        self.view.set_scratch(True)
        self.view.set_name("scratch_ollama_context")
        self.view.assign_syntax("Packages/JSON/JSON.sublime-syntax")
        self.view.insert(edit, 0, '{"model": "filler_model", "stream": false, "messages": [{"role": "user", "content": "this is filler text"}]}')
        try_prettyjson()


class AppendUserInputCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        print("appending user input template")
        if is_not_json_file():
            return

        cursor = self.view.sel()
        # print(cursor)
        if len(cursor) == 1:
            self.view.replace(edit, cursor[0], ',{"role": "user", "content": "filler"}')
            temp = cursor[0].b
            cursor.clear()
            cursor.add(temp)
            try_prettyjson()
        else:
            print("no multi cursor support")


class ListModelsCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        if is_not_json_file():
            return

        # check if ollama server is running
        proc = subprocess.run(["/bin/bash", "-c", "pgrep ollama"],
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE,
                              shell=False)
        if not proc.stdout.decode():
            print("ollama server not found, aborting")
            return
        elif not proc.stdout.decode().split("\n")[0].isdigit():
            print("pgrep output not integer, aborting")
            return

        # get list of models from server
        proc = subprocess.run(["/bin/bash", "-c", "ollama list"],
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE,
                              shell=False)
        # print(proc)
        model_list = proc.stdout.decode().split("\n")[1:-1]
        # print(model_list)

        def handle_model_select(selected_model):
            """Awkward function that runs after an item is selected from the list.
            This function can only call another Command class because
            the edit object dies after this Command exits and the
            popup menu is non blocking"""
            # print(selected_model)
            self.view.run_command("insert_model", {"model_list": model_list, "model": selected_model})
        self.view.show_popup_menu(model_list, handle_model_select)


class InsertModelCommand(sublime_plugin.TextCommand):
    def run(self, edit, **kwargs):
        """This is the Command that actually inserts the
        selected model from the list into the text buffer"""
        # print(kwargs)
        if kwargs["model"] == -1:  # no model selected
            return
        # print(kwargs["model_list"][kwargs["model"]].split(" ")[0])
        cursor = self.view.sel()
        if len(cursor) == 1:
            self.view.replace(edit, cursor[0], kwargs["model_list"][kwargs["model"]].split(" ")[0])
            temp = cursor[0].b
            cursor.clear()
            cursor.add(temp)
