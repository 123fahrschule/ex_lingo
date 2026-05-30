const DEFAULT_CONTEXT_PREFIXES = ["search", "page", "filter[", "sort["];

const parseJson = (value, fallback) => {
  if (!value) return fallback;

  try {
    return JSON.parse(value);
  } catch (_error) {
    return fallback;
  }
};

const contextPrefixes = (value) => {
  const parsed = parseJson(value, DEFAULT_CONTEXT_PREFIXES);

  if (Array.isArray(parsed) && parsed.every((entry) => typeof entry === "string")) {
    return parsed;
  }

  return DEFAULT_CONTEXT_PREFIXES;
};

const hasExplicitContext = (prefixes) => {
  const url = new URL(window.location.href);

  return [...url.searchParams.keys()].some((key) =>
    prefixes.some((prefix) => key === prefix || key.startsWith(prefix)),
  );
};

const isEmptyContext = (context) =>
  !context ||
  typeof context !== "object" ||
  Object.values(context).every((value) => {
    if (Array.isArray(value)) return value.length === 0;
    if (value && typeof value === "object") return Object.keys(value).length === 0;
    return value === null || value === undefined || value === "";
  });

const uiStorageKey = (storageKey) => `${storageKey}:ui`;

const readUiState = (storageKey) =>
  parseJson(window.localStorage.getItem(uiStorageKey(storageKey)), {});

const writeUiState = (storageKey, attrs) => {
  if (!storageKey) return;

  window.localStorage.setItem(
    uiStorageKey(storageKey),
    JSON.stringify({
      ...readUiState(storageKey),
      ...attrs,
      updatedAt: Date.now(),
    }),
  );
};

export const ExLingoListContext = {
  mounted() {
    this.restoreAttempted = false;
    this.scrollRestored = false;
    this.restoreScrollAfterUpdate = false;
    this.contextPrefixes = contextPrefixes(this.el.dataset.contextPrefixes);
    this.trackItemClick = this.trackItemClick.bind(this);
    this.trackScroll = this.trackScroll.bind(this);
    this.el.addEventListener("click", this.trackItemClick, true);
    window.addEventListener("scroll", this.trackScroll, { passive: true });

    if (!this.maybeRestore()) {
      this.syncStorage();
      this.restoreUiState();
    }
  },

  updated() {
    const restoreScroll = this.restoreScrollAfterUpdate;
    this.restoreScrollAfterUpdate = false;
    this.syncStorage();
    this.restoreUiState({ restoreScroll });
  },

  destroyed() {
    this.el.removeEventListener("click", this.trackItemClick, true);
    window.removeEventListener("scroll", this.trackScroll);
  },

  syncStorage() {
    const storageKey = this.el.dataset.storageKey;
    if (!storageKey) return;

    const context = parseJson(this.el.dataset.listContext, {});

    if (isEmptyContext(context)) {
      window.localStorage.removeItem(storageKey);
      return;
    }

    window.localStorage.setItem(storageKey, JSON.stringify(context));
  },

  maybeRestore() {
    if (this.restoreAttempted) return false;

    this.restoreAttempted = true;

    if (hasExplicitContext(this.contextPrefixes)) {
      return false;
    }

    const storageKey = this.el.dataset.storageKey;
    if (!storageKey) return false;

    const context = parseJson(window.localStorage.getItem(storageKey), {});
    if (isEmptyContext(context)) return false;

    this.restoreScrollAfterUpdate = true;
    this.pushEvent("restore-list-context", context);
    return true;
  },

  trackItemClick(event) {
    const item = event.target.closest("[data-list-item-id]");
    if (!item || !this.el.contains(item)) return;

    const storageKey = this.el.dataset.storageKey;
    if (!storageKey) return;

    writeUiState(storageKey, {
      lastItemId: item.dataset.listItemId,
      scrollY: window.scrollY,
      scrollX: window.scrollX,
    });
  },

  trackScroll() {
    if (this.scrollTimer) return;

    this.scrollTimer = window.requestAnimationFrame(() => {
      this.scrollTimer = null;

      const storageKey = this.el.dataset.storageKey;
      if (!storageKey) return;

      writeUiState(storageKey, {
        scrollY: window.scrollY,
        scrollX: window.scrollX,
      });
    });
  },

  restoreUiState(options = {}) {
    const { restoreScroll = true } = options;
    const storageKey = this.el.dataset.storageKey;
    if (!storageKey) return;

    const uiState = readUiState(storageKey);

    if (restoreScroll && !this.scrollRestored && Number.isFinite(uiState.scrollY)) {
      this.scrollRestored = true;
      window.requestAnimationFrame(() => {
        window.scrollTo(uiState.scrollX || 0, uiState.scrollY);
      });
    }
  },
};
