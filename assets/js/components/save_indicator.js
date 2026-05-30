// Hook for the per-row save-state indicator in the inline message list.
//
// The server assigns a `data-save-state` of "saving" | "saved" | "error" |
// "idle". When a terminal state ("saved"/"error") appears, we briefly flash a
// highlight on the enclosing row and then fade the indicator back to neutral
// after ~1.5s — purely client-side, so it does not require a server round-trip.
const RESET_DELAY_MS = 1500;

export const ExLingoSaveIndicator = {
  mounted() {
    this.applyState();
  },

  updated() {
    this.applyState();
  },

  destroyed() {
    if (this.timer) {
      clearTimeout(this.timer);
    }
    if (this.flashTimer) {
      clearTimeout(this.flashTimer);
    }
  },

  applyState() {
    const state = this.el.dataset.saveState;

    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }

    this.el.classList.remove("opacity-0");

    if (state === "saved" || state === "error") {
      if (state === "saved") {
        this.flashRow();
      }

      this.timer = setTimeout(() => {
        this.el.classList.add("opacity-0");
      }, RESET_DELAY_MS);
    }
  },

  flashRow() {
    const row = this.el.closest("[data-inline-row]");
    if (!row) {
      return;
    }

    if (this.flashTimer) {
      clearTimeout(this.flashTimer);
    }

    row.classList.add("ex-lingo-list-highlight");
    this.flashTimer = setTimeout(() => {
      row.classList.remove("ex-lingo-list-highlight");
      this.flashTimer = null;
    }, RESET_DELAY_MS);
  },
};
