"""Receiver-local debug logging for native UI interaction tracing."""

import os
import time
from Components.ActionMap import ActionMap
from Components.MenuList import MenuList

LOG_PATH = "/var/log/enigma2-universal-panel-ui.log"
FALLBACK_LOG_PATH = "/tmp/enigma2-universal-panel-ui.log"
MAX_OUTPUT = 4096


def _write(line):
    payload = "%s %s\n" % (time.strftime("%Y-%m-%d %H:%M:%S"), line)
    for path in (LOG_PATH, FALLBACK_LOG_PATH):
        try:
            with open(path, "a") as handle:
                handle.write(payload)
            return
        except (IOError, OSError):
            continue


def log(event, **fields):
    parts = ["[UI] %s" % event]
    for key, value in fields.items():
        text = str(value).replace("\r", "\\r").replace("\n", "\\n")
        if len(text) > MAX_OUTPUT:
            text = text[:MAX_OUTPUT] + "...[truncated]"
        parts.append("%s=%s" % (key, text))
    _write(" ".join(parts))


class DebugActionMap(ActionMap):
    """ActionMap that records every mapped remote-control action and result."""

    def __init__(self, contexts, actions, prio=0, description=None):
        wrapped = {}
        for key, callback in actions.items():
            wrapped[key] = self._wrap(key, callback)
        ActionMap.__init__(self, contexts, wrapped, prio, description)

    @staticmethod
    def _wrap(key, callback):
        def handler(*args, **kwargs):
            log("key.press", key=key, callback=getattr(callback, "__name__", repr(callback)))
            try:
                result = callback(*args, **kwargs)
                log("key.result", key=key, result=result if result is not None else "None")
                return result
            except Exception as exc:
                log("key.error", key=key, error=repr(exc))
                raise
        handler.__name__ = getattr(callback, "__name__", "handler")
        return handler


class DebugMenuList(MenuList):
    """MenuList that records every selection movement/change."""

    def selectionChanged(self):
        try:
            index = self.getSelectionIndex()
        except Exception:
            index = "unknown"
        try:
            item = self.getCurrent()
        except Exception:
            item = None
        log("selection.changed", index=index, item=item)
        return MenuList.selectionChanged(self)
