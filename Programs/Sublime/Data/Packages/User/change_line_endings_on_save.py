import sublime_plugin

# Options are: "Windows", "Unix", "CR" (don't use CR)
PREFERRED_LINE_ENDINGS = "Unix"

class SilentlyChangeLineEndingsListener(sublime_plugin.EventListener):
    def on_pre_save(self, view):
        if view.line_endings() != PREFERRED_LINE_ENDINGS:
            view.set_line_endings(PREFERRED_LINE_ENDINGS)
