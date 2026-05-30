// Hook for the per-row save-state indicator in the inline message list.
//
// The server assigns a `data-save-state` of "saving" | "saved" | "error" |
// "idle". When a terminal state ("saved"/"error") appears, the indicator is
// shown and then faded back to neutral after ~1.5s — purely client-side, so it
// does not require a server round-trip. The green "Saved" / red "Error" text is
// the save cue; we intentionally do not also tint the whole row.
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
  },

  applyState() {
    const state = this.el.dataset.saveState;

    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }

    this.el.classList.remove("opacity-0");

    if (state === "saved" || state === "error") {
      this.timer = setTimeout(() => {
        this.el.classList.add("opacity-0");
      }, RESET_DELAY_MS);
    }
  },
};
