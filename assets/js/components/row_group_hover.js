// Highlights a message and its related rows (source positions, image panel) as
// one unit on hover. They are separate <tr> elements so the table's per-row
// hover would otherwise light them up independently; CSS can't reach a previous
// sibling, so we toggle a shared class via event delegation.
const GROUP_CLASS = "ex-lingo-row-group-hover";

export const ExLingoRowGroupHover = {
  mounted() {
    this.activeGroup = null;

    this.onOver = (event) => {
      const row = event.target.closest("[data-row-group]");
      const group = row && row.dataset.rowGroup;

      if (group === this.activeGroup) return;

      this.clear();

      if (group) {
        this.activeGroup = group;
        this.rowsFor(group).forEach((el) => el.classList.add(GROUP_CLASS));
      }
    };

    this.onLeave = () => this.clear();

    this.el.addEventListener("mouseover", this.onOver);
    this.el.addEventListener("mouseleave", this.onLeave);
  },

  destroyed() {
    this.el.removeEventListener("mouseover", this.onOver);
    this.el.removeEventListener("mouseleave", this.onLeave);
  },

  rowsFor(group) {
    return this.el.querySelectorAll(`[data-row-group="${CSS.escape(group)}"]`);
  },

  clear() {
    if (!this.activeGroup) return;

    this.el
      .querySelectorAll(`.${GROUP_CLASS}`)
      .forEach((el) => el.classList.remove(GROUP_CLASS));

    this.activeGroup = null;
  },
};
