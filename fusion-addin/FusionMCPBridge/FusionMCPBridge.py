# Fusion add-in helpers used with Autodesk Fusion MCP Server (port 27182).
# Official HTTP MCP is hosted by Fusion itself once enabled in Preferences.
import os
import traceback

import adsk.core
import adsk.fusion

_app = None
_ui = None
_mcp_tools = []


def run(context):
    global _app, _ui
    try:
        _app = adsk.core.Application.get()
        _ui = _app.userInterface
        register_mcp_tools()
        adsk.core.Application.log("Fusion MCP Bridge loaded for Grok.")
    except Exception:
        if _ui:
            _ui.messageBox("Failed:\n{}".format(traceback.format_exc()))


def stop(context):
    global _ui
    try:
        unregister_mcp_tools()
        adsk.core.Application.log("Fusion MCP Bridge unloaded.")
    except Exception:
        if _ui:
            _ui.messageBox("Failed:\n{}".format(traceback.format_exc()))


def register_mcp_tools():
    _mcp_tools.clear()
    _mcp_tools.append({"name": "fusion_mcp_execute", "handler": mcp_execute_script})
    _mcp_tools.append({"name": "fusion_mcp_screenshot", "handler": mcp_screenshot_viewport})


def unregister_mcp_tools():
    _mcp_tools.clear()


def mcp_execute_script(args: dict):
    script = args.get("script", "")
    if not script:
        return {"ok": False, "error": "No script provided"}

    local_env = {
        "adsk": adsk,
        "app": _app,
        "ui": _ui,
    }
    try:
        exec(script, local_env, local_env)
        result = local_env.get("result")
        return {"ok": True, "result": result}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def mcp_screenshot_viewport(args: dict):
    try:
        width = int(args.get("width", 1280))
        height = int(args.get("height", 720))
        vp = _app.activeViewport
        if not vp:
            return {"ok": False, "error": "No active viewport"}

        temp_folder = os.path.join(os.path.expanduser("~"), ".grok", "mcp", "fusion")
        os.makedirs(temp_folder, exist_ok=True)
        file_path = os.path.join(temp_folder, "fusion_viewport.png")

        ok = vp.saveAsImageFile(file_path, width, height)
        if not ok:
            return {"ok": False, "error": "saveAsImageFile failed"}
        return {"ok": True, "path": file_path}
    except Exception as e:
        return {"ok": False, "error": str(e)}
