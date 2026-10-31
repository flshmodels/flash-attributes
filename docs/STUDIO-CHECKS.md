# Studio checks

Status: not yet run in a live Studio session. Record the Studio version, date and result when you do this.

1. Install the packaged `FlashAttributes.rbxmx` as a local plugin in a separate test place. Confirm the toolbar button opens and closes the panel.
2. Check the panel in light and dark themes and with a narrow dock. Fields, status and the preview should remain readable and scrollable.
3. Preview a valid selection. Confirm it has made no place edits. Change an option or the selection; Apply should ask for another preview.
4. Preview again, then edit or remove a target in Explorer. Apply must refuse that stale preview without changing other targets.
5. Apply a small valid batch. Undo once, check every target, then Redo once. Check that an unchanged preview does not add an undo entry.
6. Start a play test with the panel open. Preview and Apply must refuse edits. Stop the test and verify the plugin still works.
7. Reload or disable the plugin. Its panel and toolbar should disappear without errors or leftover connections.
8. Try the invalid inputs listed in the README. Check that each rejected batch leaves the place unchanged.

The preview displays at most 100 rows, but Apply covers all changes in the plan, up to 500 selected targets. Use a smaller selection if you want to review every row on screen.
