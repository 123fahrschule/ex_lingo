const HEX_COLOR = /^#[0-9A-Fa-f]{6}$/;

const normalizeColor = (value) => {
  if (!value) return value;
  const trimmed = value.trim();
  return trimmed.startsWith("#") ? trimmed.toUpperCase() : `#${trimmed}`.toUpperCase();
};

const dispatchInput = (input) => {
  input.dispatchEvent(new Event("input", { bubbles: true }));
  input.dispatchEvent(new Event("change", { bubbles: true }));
};

export const ExLingoColorPicker = {
  mounted() {
    this.picker = this.el.querySelector("[data-color-picker]");
    this.text = this.el.querySelector("[data-color-text]");

    if (!this.picker || !this.text) return;

    this.syncTextFromPicker = this.syncTextFromPicker.bind(this);
    this.syncPickerFromText = this.syncPickerFromText.bind(this);

    this.picker.addEventListener("input", this.syncTextFromPicker);
    this.picker.addEventListener("change", this.syncTextFromPicker);
    this.text.addEventListener("input", this.syncPickerFromText);
    this.text.addEventListener("change", this.syncPickerFromText);
  },

  destroyed() {
    if (!this.picker || !this.text) return;

    this.picker.removeEventListener("input", this.syncTextFromPicker);
    this.picker.removeEventListener("change", this.syncTextFromPicker);
    this.text.removeEventListener("input", this.syncPickerFromText);
    this.text.removeEventListener("change", this.syncPickerFromText);
  },

  syncTextFromPicker() {
    const value = normalizeColor(this.picker.value);
    if (!HEX_COLOR.test(value)) return;

    this.text.value = value;
    dispatchInput(this.text);
  },

  syncPickerFromText() {
    const value = normalizeColor(this.text.value);
    this.text.value = value;

    if (HEX_COLOR.test(value)) {
      this.picker.value = value;
    }
  },
};
