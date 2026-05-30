// Hook for the "Add to glossary" button inside a translation editor.
// On click it inspects the active text selection inside the source block and
// the target input, then pushes an `open_glossary_for_selection` event with the
// captured terms so the LiveComponent can navigate to the prefilled glossary form.
//
// Source/target lookups are scoped to the button's enclosing
// `[data-glossary-scope]` container (e.g. a table row in the inline message
// list) and fall back to the enclosing form, so multiple editors on the same
// page cannot cross-pollinate selections.
export const ExLingoGlossaryCapture = {
  mounted() {
    this.handleClick = () => {
      const root =
        this.el.closest("[data-glossary-scope]") ||
        this.el.closest("form") ||
        this.el.parentElement ||
        this.el;
      const sourceTerm = readSourceSelection(root);
      const targetTerm = readTargetSelection(root);

      this.pushEventTo(this.el, "open_glossary_for_selection", {
        source_term: sourceTerm,
        target_term: targetTerm,
      });
    };

    this.el.addEventListener("click", this.handleClick);
  },

  destroyed() {
    if (this.handleClick) {
      this.el.removeEventListener("click", this.handleClick);
    }
  },
};

function readSourceSelection(root) {
  const sourceEl = root.querySelector("[data-glossary-source]");
  if (!sourceEl) {
    return "";
  }

  const selection = window.getSelection();
  if (selection && selection.rangeCount > 0) {
    const range = selection.getRangeAt(0);
    if (sourceEl.contains(range.commonAncestorContainer)) {
      const marked = selection.toString().trim();
      if (marked.length > 0) {
        return marked;
      }
    }
  }

  return "";
}

function readTargetSelection(root) {
  // A row may contain several target inputs (one per plural form); pick the
  // one that currently has a non-empty selection.
  const targets = root.querySelectorAll("[data-glossary-target]");

  for (const targetEl of targets) {
    if (typeof targetEl.selectionStart !== "number") {
      continue;
    }

    if (targetEl.selectionStart === targetEl.selectionEnd) {
      continue;
    }

    const marked = targetEl.value
      .substring(targetEl.selectionStart, targetEl.selectionEnd)
      .trim();

    if (marked.length > 0) {
      return marked;
    }
  }

  return "";
}
