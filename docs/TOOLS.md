# Official Autodesk Fusion desktop MCP tools

Verified against Autodesk Fusion MCP (`MCP Server Adapter 1.0.0`) and Grok connector `Fusion360`. Tool set is dynamic; re-run `tools/list` after Fusion updates.

## `fusion_mcp_read`

Read-only. Required: `queryType`.

| queryType | Extra args | Returns |
|---|---|---|
| `projects` | — | hub projects `{name, id}` |
| `document` + `operation=search` | `name` (required), `project` optional | file hits `{name, id}` |
| `document` + `operation=open` | — | open docs `{name, id, isActive, isModified}` |
| `document` + `operation=recent` | — | recent files |
| `apiDocumentation` | `searchPattern` required; `apiCategory`=`class\|member\|description\|all`; `filter` dotted namespace | classes/members |
| `screenshot` | `width`/`height` 32–4096; `antiAliasing`; `transparentBackground`; `direction` | PNG base64 |
| `activeCommand` | — | open command dialog + inputs, or null |

Screenshot `direction`: `current`, `front`, `back`, `bottom`, `top`, `left`, `right`, `iso-bottom-left`, `iso-bottom-right`, `iso-top-left`, `iso-top-right`.

## `fusion_mcp_execute`

Required: `featureType`, `object`.

### `featureType: script`

```json
{
  "featureType": "script",
  "object": {
    "script": "import adsk.core\n\ndef run(_context: str):\n    print(adsk.core.Application.get().version)\n"
  }
}
```

- Must define `def run(_context: str):` (one argument).
- `print()` is the tool output.
- Do **not** catch exceptions inside `run`.
- Fusion API units are **cm**.

### `featureType: document`

| operation | object fields |
|---|---|
| `open` | `fileId` from read/search |
| `close` | optional `userConfirmedSaveAndClose` or `userConfirmedCloseWithoutSave` |
| `save` | only when the user explicitly asks |

## `fusion_mcp_update`

`featureType`: `undo` | `redo`. Fails during interactive/preview commands.

## `fusion_mcp_electronics_read`

Requires an active Electronics document. `entity_type` = `electronics.<Class>` (49 classes). Optional `object.fields`, `object.filters` (`eq`/`lt`/`gt`), `object.pagination`.
