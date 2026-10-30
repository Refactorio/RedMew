# GUIs

How RedMew builds its GUIs, so that they look like Factorio's own and like each other. The
helpers are in `utils/gui.lua`; use them rather than building frames by hand, and use Factorio's
own styles rather than setting sizes and colours.

## Where a GUI goes

- **Top buttons** open everything else: `Gui.add_top_element` puts one in the row of buttons at
  the top left (mod-gui).
- **Side panels** are what a top button opens and leaves open while the player plays: polls,
  tasks, the player list, autofill. `Gui.add_panel` docks one in the column under the top
  buttons, with its title and a pin in a header. The pin floats the panel into a window the player
  can drag anywhere, and docks it back; each player's choice is remembered, and a floating panel
  reopens where the player last left it. Find a panel with `Gui.get_panel`, wherever it is, and
  change its title with `Gui.set_panel_caption`.
  - Width: `width = 'narrow'` (400) or `'wide'` (470), from `Styles.panel_width`. The production
    HUD's is `'minimap'` (256), the minimap's, so players can float it under the minimap as one.
    Leave it out only for compact panels sized by their contents (shortcuts, the player list's
    table, paint).
  - The panel's own buttons go in its header, through `add_header_buttons`, before the pin. The
    title gives way to them, so a longer translation is cut short rather than push them out; a
    panel with a fixed width wants a word that fits in every language (the HUD's "Stats").
  - Panels players keep open while they play stay compact: `deep = true` puts the content in a
    dark inner frame, which numbers read better on (the HUD), and with `side_dragger = true` a
    floating panel is dragged by a strip down its right side rather than its header, so it
    doesn't grow wider (Shortcuts, the HUD).
  - A panel made of sections, each with its own subheader (tasks), passes `sections = true`.
  - A setting the panel needs, such as notifications, goes in a footer along the bottom:
    `footer = true` returns one (a `subfooter_frame`) as `Gui.add_panel`'s third value.
    One whose elements bring their own frame, like the shortcuts' slot bar, passes
    `frameless = true`. A list that fills the inner frame (tags) sets the frame's padding to 0,
    uses a `naked_scroll_pane`, and puts anything under it in a `subfooter_frame`.
- **Windows** are everything opened for a moment: editors, confirmations, tools, markets.
  `Gui.add_window` opens one in the middle of the screen every time, like Factorio's own windows,
  with a title bar to drag it by and an X. `Gui.add_dialog` is a window with its content in a
  padded inner frame, and `Gui.add_dialog_buttons` adds the row of buttons below it.
- **The info window** that opens when a player joins is a window too, with no title: a bar to
  drag it by and an X above its tabs, and its Close button below. New GUIs don't use
  `gui.center` or `gui.left` directly; a few game modes' panels, toasts and the debug and test
  viewers still do.

## Closing

- Every panel and window has its own X, docked or floating, and no Close or Cancel button: the X
  closes it. A panel's top button still toggles it; its X and pin go through the top button's
  click handler.
- A window gets a row of buttons only when it has an action besides closing. In the row, the
  likes of Clear and Reset go on the left, the confirming button last on the right, and the
  likes of Delete just before it.

## One element for each job

| Job | Use |
| --- | --- |
| A panel, window or dialog | `Gui.add_panel`, `Gui.add_window`, `Gui.add_dialog` and `Gui.add_dialog_buttons` |
| Icon buttons in a header (pin, add, clear) | `frame_action_button` with a white sprite (`utility/add_white`), the dark one as `hovered_sprite` |
| Icon buttons in content (edit, delete, move, add, a count) | `tool_button`; `tool_button_red` when it deletes or punishes |
| Showing which one is the player's (their vote, their volunteering) | `toggled = true` on the button, not a font colour |
| Dialog buttons | `dialog_button` and `confirm_button` (the defaults of `Gui.add_dialog_buttons`), and `red_back_button` or `red_confirm_button` when they delete or punish |
| A section in a panel | `inside_shallow_frame` with a `subheader_frame` holding a `subheader_caption_label` and its `tool_button`s |
| Item, tile and signal slots | `slot_button` in a `filter_slot_table`, in an `inside_deep_frame`; `slot_sized_button` for a single slot on a shallow frame (the paint brush) |
| Text | a label with the default style; `bold_label` for names of fields, for a question and for a row's number (an experience level) |
| Column headings | `caption_label`, aligned like the column's cells |
| A choice from a short list (a time span) | a `drop-down` |
| Text to read but not edit | a `text-box` with the `notice_textbox` style, `read_only`: players can still select and copy it |
| Titles | `frame_title`, only through the helpers |

## Things that are easy to get wrong

- Set styles with `Gui.set_style(element, { ... })`, one table, not property by property
  (`element.style.width = ...`); a style several elements share is a table at the top of the file.
- Find elements by name, or keep them in the window's `Gui.set_data`; not by position
  (`element.parent.parent`, `frame.children[1]`), which breaks as soon as the layout changes.
- A label that wraps (`single_line = false`) in a table needs a definite width; left to stretch,
  it collapses to nothing.
- A text box doesn't grow to fit its text: give it a height (`minimal_height`).
- Vanilla dialog buttons are at least 112 wide: don't cap a dialog's width below what its
  buttons need.
- Player-facing text goes in `locale/` (see `docs/LOCALE.md`); reuse Factorio's own strings where
  they fit, such as `gui.close-instruction` for an X.
- GUI sizes are only worked out on a client, so a headless test can't see a layout. Tests that
  need a player's GUI are tagged `skip-headless` (see `docs/TESTS.md`); check the layout in game.
