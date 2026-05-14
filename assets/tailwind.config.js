module.exports = {
  presets: [require("../deps/cognit/assets/tailwind_preset.js")],
  darkMode: "class",
  content: [
    "./js/**/*.js",
    "../deps/cognit/**/*.*ex",
    "../deps/cognit/assets/js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
  ],
};
