// Hook for the "Add to glossary" button inside a translation editor.
// On click it inspects the active text selection inside the source block and
// the target input, then pushes an `open_glossary_for_selection` event with the
// captured terms so the LiveComponent can navigate to the prefilled glossary form.
export const ExLingoGlossaryCapture = {
  mounted() {
    this.el.addEventListener("click", () => {
      const sourceTerm = readSourceSelection();
      const targetTerm = readTargetSelection();

      this.pushEventTo(this.el, "open_glossary_for_selection", {
        source_term: sourceTerm,
        target_term: targetTerm,
      });
    });
  },
};

function readSourceSelection() {
  const sourceEl = document.querySelector("[data-glossary-source]");
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

function readTargetSelection() {
  const targetEl = document.querySelector("[data-glossary-target]");
  if (!targetEl || typeof targetEl.selectionStart !== "number") {
    return "";
  }

  if (targetEl.selectionStart === targetEl.selectionEnd) {
    return "";
  }

  return targetEl.value
    .substring(targetEl.selectionStart, targetEl.selectionEnd)
    .trim();
}
