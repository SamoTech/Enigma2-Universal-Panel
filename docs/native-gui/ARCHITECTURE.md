# Native Enigma2 GUI Architecture

## Objective

Build the Universal Panel as a real Enigma2 plugin that runs on the receiver and is opened from the normal Plugins/Extensions menu.

The GUI is local-first and remote-control-first.

## Runtime boundary

The plugin is loaded by Enigma2 and owns only presentation and interaction. It does not own package-resolution rules, compatibility guesses, or unrestricted command execution.

Recommended separation:

- plugin.py: Enigma2 registration and entry point
- screens/: native Screen/List/ConfigList/MessageBox views
- controllers/: translation between GUI events and registered actions
- models/: normalized state presented to screens
- resources/: skin/assets/local metadata
- shared receiver runtime: existing detection, compatibility, resolver and action policy layer

## Entry point

The plugin must register through the native Enigma2 plugin mechanism and expose a callable main entry point.

The registration must make the panel visible in the normal Plugins/Extensions menu.

The exact PluginDescriptor API and menu placement must be validated against supported Enigma2 source versions rather than guessed.

## Remote-control contract

Minimum navigation:

- UP/DOWN: move selection
- LEFT/RIGHT: change applicable values
- OK: open/execute
- EXIT: back/close
- MENU: contextual options
- RED/GREEN/YELLOW/BLUE: contextual actions only where useful

Long-running operations require a progress/result screen and must not block the GUI event loop.

## Screen model

Dashboard
  -> category menu
     -> capability-aware screen
        -> preview
           -> confirmation
              -> action
                 -> postcondition
                    -> result

Unavailable operations should be hidden or clearly disabled with an explanation derived from capability state.

## Security model

The GUI is never an arbitrary shell front end.

A GUI action must:

1. identify a registered action;
2. validate parameters;
3. check capabilities;
4. run preflight where required;
5. request explicit confirmation for destructive operations;
6. execute through the approved adapter;
7. verify the postcondition;
8. write an audit record.

## Compatibility

The GUI must remain usable across supported Enigma2 families without assuming identical screen APIs or package layouts.

Where a required GUI API is unavailable, the plugin must fail safely and report the unsupported capability rather than importing a guessed compatibility layer.

## Testing

CI should validate:

- plugin package structure;
- Python syntax;
- registration metadata;
- forbidden arbitrary-shell GUI paths;
- action registration usage;
- policy compliance;
- mocked controller behavior.

Real receiver testing must additionally validate:

- plugin discovery in the normal Plugins/Extensions menu;
- launch;
- remote-control navigation;
- screen rendering;
- package operations;
- restart/reboot confirmation behavior.

Mock validation is not equivalent to real receiver validation.
