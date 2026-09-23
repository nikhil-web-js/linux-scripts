# YouTube Playlist Bookmark Sync v1.4

Event-driven. No polling.

## Multiple YouTube tabs

State is maintained independently per tab.

Example:

Tab 101:
  playlist X / video 6
Tab 202:
  playlist X / video 15

If Tab 202 moves:
  video 15 -> video 16

the extension searches for the bookmark pointing to video 15 and updates it.
Tab 101's previous state is not affected.

## Duplicate navigation events

Brave/YouTube can emit multiple events for one URL transition.

The extension stores `processedUrl` per tab and ignores duplicate events:

  onHistoryStateUpdated -> process
  tabs.onUpdated        -> DUPLICATE EVENT IGNORED

The URL is marked as processed before the bookmark update starts, preventing
two events from racing and updating the same bookmark twice.

## Multiple bookmarks in one playlist

Exact previous-video match has priority.

If:

  Bookmark A -> playlist X / video 6
  Bookmark B -> playlist X / video 15

and the tab navigates:

  video 15 -> video 16

only Bookmark B is updated.

If multiple playlist bookmarks exist but none matches the video just left,
nothing is changed.

## Debugging

Open:

  brave://extensions

Then:

  YouTube Playlist Bookmark Sync
  -> Inspect views / Service worker
  -> Console

Useful logs:

  SERVICE WORKER LOADED
  INITIAL URL captured
  URL CHANGED
  PLAYLIST VIDEO CHANGED
  MATCH FOUND - updating bookmark
  BOOKMARK UPDATED successfully
  DUPLICATE EVENT IGNORED
  MULTIPLE PLAYLIST BOOKMARKS - no exact match; NOT guessing

## Install

1. Remove the previous version.
2. Extract this ZIP.
3. Open `brave://extensions`.
4. Enable Developer mode.
5. Click Load unpacked.
6. Select the extracted `youtube-playlist-bookmark-sync-brave-v1.4` folder.
7. Reload your YouTube tabs.
