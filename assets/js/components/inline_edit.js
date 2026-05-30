// Hook for inline translation inputs in the message list.
//
// Keyboard shortcuts (poeditor-style):
//   * Cmd/Ctrl+Enter   -> save the current input (via its `phx-blur` auto-save)
//                         and jump to the next inline input in DOM order.
//
// Auto-save itself is handled server-side through the input's `phx-blur`
// binding; blurring the element on Cmd/Ctrl+Enter is what triggers the save.
export const ExLingoInlineEdit = {
  mounted() {
    this.handleKeydown = (event) => {
      if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
        event.preventDefault();
        this.saveAndAdvance();
      }
    };

    this.el.addEventListener("keydown", this.handleKeydown);
  },

  destroyed() {
    if (this.handleKeydown) {
      this.el.removeEventListener("keydown", this.handleKeydown);
    }
  },

  saveAndAdvance() {
    // Advance across rows within the same messages table, but don't reach for
    // unrelated inline inputs elsewhere on the page.
    const root = this.el.closest("table") || document;
    const inputs = Array.from(root.querySelectorAll("[data-inline-input]"));
    const index = inputs.indexOf(this.el);

    // Blurring fires the input's `phx-blur="save"`, persisting the value.
    this.el.blur();

    const next = index >= 0 ? inputs[index + 1] : null;
    if (next) {
      next.focus();
      if (typeof next.setSelectionRange === "function") {
        const end = next.value.length;
        next.setSelectionRange(end, end);
      }
    }
  },
};
