# Flash Attributes

Set or remove one attribute across a Studio selection, with typed values and a preview.

## Install

1. Download this repository as a ZIP and extract it. No package installation is needed to use the plugin.
2. Open a separate Studio test place in edit mode. Use Explorer's **Insert from File** action to insert `FlashAttributes.rbxmx`.
3. The imported root is a Script named `FlashAttributes` with four child ModuleScripts. Select that root and choose **Save as Local Plugin**.
4. Remove the imported root from the place after saving the plugin. Open **Flash Attributes → Attributes** on the Plugins toolbar.

Changes happen only after Preview and Apply. Selection or option edits clear the preview. Apply is refused during a play test. A successful batch uses one Studio undo recording. If a write fails, the plugin asks Studio to cancel the batch. Start on a copy of your place and verify Undo and Redo before using it on important work.

## Use it

Select objects in Explorer. Enter an attribute name, choose a type, enter the value, and preview. Apply after reviewing the old and new values.

| Operation | Value field | Result |
| --- | --- | --- |
| String | `Door_Main` | Stores that exact string |
| Number | `12.5` | Stores a number |
| Boolean | `true` or `false` | Stores a boolean |
| Delete | Ignored | Removes the named attribute, leaving the object intact |

Existing attributes with another type block the entire preview. If changing the type is intentional, delete the attribute in one batch and set it in another. Missing attributes and empty strings are different; setting an empty String does not remove an attribute.

## Limits

- Select 1–500 objects inside services. Services themselves are refused. Descendants are not expanded.
- Names: 1–100 ASCII letters, digits, periods, hyphens, slashes or underscores. Names starting with `RBX` in any letter case are refused.
- String values: valid UTF-8, at most 1024 bytes. Numbers: finite, between -1e12 and 1e12. Booleans must be exactly `true` or `false`.
- Other Roblox attribute types can be deleted, but cannot be created by this version. It does not edit tags, properties, script source or DataStores.
- Apply rechecks the original value and parent. Preview again after other edits. Previews shorten long existing values to 120 Unicode code points for display; they do not shorten stored data.

## Code

`Rules.parse(name, kind, text)` returns a typed value (`nil` for Delete). `Rules.plan(rows, options)` returns changed attributes or rejects the whole batch on a type mismatch. `Adapter` reads and writes with `GetAttribute` and `SetAttribute`.

## Development and tests

The source is in `src`. There are no runtime dependencies, network requests or external assets. `Ui` creates a dock panel using Studio's theme. `Transaction` handles preflight checks and undo recordings; it does not create its own undo stack. These two modules are shared with the other Flash editing plugins, with a copy in each repository so each plugin can be installed on its own.

Rebuild after changing source (Python 3.11+):

```sh
python build.py
python -m unittest discover -s tests -v
```

Rule, adapter and transaction checks use Lune 0.11.1:

```sh
lune run tests/run
```

The tests compile every source file, exercise the real planner and adapter with fake Studio objects, and check commit/cancel behavior with a fake history service. Packaging tests compare the XML plugin against its source. GitHub Actions runs both sets of checks. The CI job installs Lune on its runner, not on your computer.

**Automated tests do not verify the dock widget, plugin installation, real constraints or Studio's undo engine.** See [Studio checks](docs/STUDIO-CHECKS.md) for the manual checklist. No live Studio pass is claimed here.

See Roblox's [plugin guide](https://create.roblox.com/docs/studio/plugins) and [ChangeHistoryService reference](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService). MIT licensed; see [LICENSE](LICENSE).
