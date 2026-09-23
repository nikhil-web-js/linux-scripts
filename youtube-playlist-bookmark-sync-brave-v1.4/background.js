const LOG = "[YT Playlist Sync]";
const STATE_PREFIX = "tab:";

// Per-tab state is persisted in storage.session so multiple YouTube tabs
// can independently track their own previous URL.
async function getTabState(tabId) {
  const key = `${STATE_PREFIX}${tabId}`;
  const result = await chrome.storage.session.get(key);
  return result[key] || null;
}

async function setTabState(tabId, state) {
  await chrome.storage.session.set({
    [`${STATE_PREFIX}${tabId}`]: state
  });
}

async function removeTabState(tabId) {
  await chrome.storage.session.remove(`${STATE_PREFIX}${tabId}`);
}

function parseYouTubeUrl(urlString) {
  try {
    const url = new URL(urlString);

    if (
      url.hostname !== "www.youtube.com" ||
      url.pathname !== "/watch"
    ) {
      return null;
    }

    const playlistId = url.searchParams.get("list");
    const videoId = url.searchParams.get("v");
    const index = url.searchParams.get("index");

    if (!playlistId || !videoId) {
      return null;
    }

    return {
      url: url.href,
      playlistId,
      videoId,
      index
    };
  } catch {
    return null;
  }
}

async function getBookmarksBar() {
  const tree = await chrome.bookmarks.getTree();

  function find(nodes) {
    for (const node of nodes) {
      if (node.id === "1" && node.children) {
        return node;
      }

      if (node.children) {
        const found = find(node.children);
        if (found) return found;
      }
    }

    return null;
  }

  return find(tree);
}

function findExactBookmark(nodes, target) {
  for (const node of nodes) {
    if (node.url) {
      const parsed = parseYouTubeUrl(node.url);

      if (
        parsed &&
        parsed.playlistId === target.playlistId &&
        parsed.videoId === target.videoId
      ) {
        return node;
      }
    }

    if (node.children) {
      const found = findExactBookmark(node.children, target);
      if (found) return found;
    }
  }

  return null;
}

function findPlaylistBookmarks(nodes, playlistId, result = []) {
  for (const node of nodes) {
    if (node.url) {
      const parsed = parseYouTubeUrl(node.url);

      if (parsed?.playlistId === playlistId) {
        result.push(node);
      }
    }

    if (node.children) {
      findPlaylistBookmarks(node.children, playlistId, result);
    }
  }

  return result;
}

async function updateBookmark(previous, current, tabId) {
  if (previous.playlistId !== current.playlistId) {
    console.log(LOG, "PLAYLIST CHANGED - no bookmark update", {
      tabId,
      previousPlaylist: previous.playlistId,
      currentPlaylist: current.playlistId
    });
    return;
  }

  if (previous.videoId === current.videoId) {
    console.debug(LOG, "SAME VIDEO - no update", {
      tabId,
      videoId: current.videoId
    });
    return;
  }

  console.log(LOG, "PLAYLIST VIDEO CHANGED", {
    tabId,
    previousVideo: previous.videoId,
    previousIndex: previous.index,
    currentVideo: current.videoId,
    currentIndex: current.index,
    playlistId: current.playlistId
  });

  const bar = await getBookmarksBar();

  if (!bar) {
    console.error(LOG, "Bookmarks Bar not found");
    return;
  }

  // Prefer the bookmark pointing to the exact video we just left.
  const exactBookmark = findExactBookmark(
    bar.children || [],
    previous
  );

  if (exactBookmark) {
    console.log(LOG, "MATCH FOUND - updating bookmark", {
      tabId,
      bookmarkId: exactBookmark.id,
      title: exactBookmark.title,
      oldUrl: exactBookmark.url,
      newUrl: current.url
    });

    await chrome.bookmarks.update(exactBookmark.id, {
      url: current.url
    });

    console.log(LOG, "BOOKMARK UPDATED successfully", {
      tabId,
      bookmarkId: exactBookmark.id
    });

    return;
  }

  // If there is no exact match, only fall back to the single playlist
  // bookmark. Never guess when multiple bookmarks exist.
  const playlistBookmarks = findPlaylistBookmarks(
    bar.children || [],
    current.playlistId
  );

  console.log(LOG, "No exact bookmark found", {
    tabId,
    playlistId: current.playlistId,
    playlistBookmarkCount: playlistBookmarks.length
  });

  if (playlistBookmarks.length === 0) {
    console.log(LOG, "NO BOOKMARK - creating", {
      tabId,
      url: current.url
    });

    const created = await chrome.bookmarks.create({
      parentId: bar.id,
      title: "YouTube Playlist",
      url: current.url
    });

    console.log(LOG, "BOOKMARK CREATED", {
      tabId,
      bookmarkId: created.id
    });

    return;
  }

  if (playlistBookmarks.length === 1) {
    const bookmark = playlistBookmarks[0];

    console.log(LOG, "ONE PLAYLIST BOOKMARK - updating", {
      tabId,
      bookmarkId: bookmark.id,
      oldUrl: bookmark.url,
      newUrl: current.url
    });

    await chrome.bookmarks.update(bookmark.id, {
      url: current.url
    });

    console.log(LOG, "BOOKMARK UPDATED successfully", {
      tabId,
      bookmarkId: bookmark.id
    });

    return;
  }

  console.warn(
    LOG,
    "MULTIPLE PLAYLIST BOOKMARKS - no exact match; NOT guessing",
    {
      tabId,
      playlistId: current.playlistId,
      count: playlistBookmarks.length
    }
  );
}

async function handleNavigation(tabId, url, eventName) {
  if (!url) return;

  console.debug(LOG, eventName, {
    tabId,
    url
  });

  const current = parseYouTubeUrl(url);

  if (!current) {
    console.debug(LOG, "URL ignored", {
      tabId,
      url
    });

    // Keep non-YouTube navigation as the latest tab URL, but do not
    // interpret it as a playlist transition.
    await setTabState(tabId, {
      url,
      processedUrl: url,
      isPlaylistVideo: false
    });

    return;
  }

  const state = await getTabState(tabId);

  // First YouTube playlist URL seen in this tab.
  if (!state?.url) {
    console.log(LOG, "INITIAL URL captured", {
      tabId,
      url: current.url,
      playlistId: current.playlistId,
      videoId: current.videoId,
      index: current.index
    });

    await setTabState(tabId, {
      url: current.url,
      processedUrl: current.url,
      isPlaylistVideo: true
    });

    return;
  }

  // Multiple browser events can describe the exact same URL change.
  // This is per-tab, so another tab can process the same URL independently.
  if (state.processedUrl === current.url) {
    console.debug(LOG, "DUPLICATE EVENT IGNORED", {
      tabId,
      url: current.url,
      event: eventName
    });
    return;
  }

  const previous = parseYouTubeUrl(state.url);

  console.log(LOG, "URL CHANGED", {
    tabId,
    event: eventName,
    from: state.url,
    to: current.url
  });

  // Mark this URL as processed BEFORE the async bookmark operation.
  // This prevents onHistoryStateUpdated + tabs.onUpdated from racing and
  // updating the same bookmark twice.
  await setTabState(tabId, {
    url: current.url,
    processedUrl: current.url,
    isPlaylistVideo: true
  });

  if (!previous) {
    console.debug(LOG, "Previous URL is not a playlist video", {
      tabId
    });
    return;
  }

  try {
    await updateBookmark(previous, current, tabId);
  } catch (e) {
    console.error(LOG, "BOOKMARK UPDATE FAILED", {
      tabId,
      error: e?.message || String(e)
    });
  }
}

// Primary event for YouTube SPA navigation.
chrome.webNavigation.onHistoryStateUpdated.addListener(
  details => {
    if (details.frameId !== 0) return;

    handleNavigation(
      details.tabId,
      details.url,
      "onHistoryStateUpdated"
    ).catch(e => {
      console.error(LOG, "history event handler failed", e);
    });
  },
  {
    url: [
      {
        hostEquals: "www.youtube.com",
        pathEquals: "/watch"
      }
    ]
  }
);

// Normal page load/navigation.
chrome.webNavigation.onCommitted.addListener(details => {
  if (details.frameId !== 0) return;

  handleNavigation(
    details.tabId,
    details.url,
    "onCommitted"
  ).catch(e => {
    console.error(LOG, "committed event handler failed", e);
  });
});

// Fallback for Chromium/Brave URL changes.
chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (!changeInfo.url) return;

  handleNavigation(
    tabId,
    changeInfo.url,
    "tabs.onUpdated"
  ).catch(e => {
    console.error(LOG, "tabs.onUpdated handler failed", e);
  });
});

// Important for multiple tabs: each tab has independent state.
chrome.tabs.onRemoved.addListener(tabId => {
  console.debug(LOG, "TAB CLOSED - cleaning state", {
    tabId
  });

  removeTabState(tabId).catch(e => {
    console.error(LOG, "Failed to remove tab state", {
      tabId,
      error: e?.message || String(e)
    });
  });
});

chrome.runtime.onInstalled.addListener(details => {
  console.log(LOG, "EXTENSION INSTALLED/UPDATED", {
    reason: details.reason,
    previousVersion: details.previousVersion || null,
    currentVersion: chrome.runtime.getManifest().version
  });
});

console.log(LOG, "SERVICE WORKER LOADED", {
  version: chrome.runtime.getManifest().version
});
