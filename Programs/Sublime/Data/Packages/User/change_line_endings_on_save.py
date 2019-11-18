import sublime
import sublime_plugin

# Options are: "Windows", "Unix", "CR" (don't use CR)
PREFERRED_LINE_ENDINGS = "Unix"

user_settings = sublime.load_settings("Preferences.sublime-settings")

change_line_endings_activated = user_settings.get('change_line_endings_on_save')

class SilentlyChangeLineEndingsListener(sublime_plugin.EventListener):
    def on_pre_save(self, view):
        if change_line_endings_activated and view.line_endings() != PREFERRED_LINE_ENDINGS:
            view.set_line_endings(PREFERRED_LINE_ENDINGS)
