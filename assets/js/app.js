import Alpine from "alpinejs";
import { ExLingoColorPicker } from "./components/color_picker";
import { ExLingoGlossaryCapture } from "./components/glossary_capture";
import { ExLingoInlineEdit } from "./components/inline_edit";
import { ExLingoListContext } from "./components/list_context";
import { ExLingoSaveIndicator } from "./components/save_indicator";
import { Select } from "./components/shared/select";
import { Toggle } from "./components/shared/toggle";
import { S3 } from "./uploaders/s3";
import { SaladUIHook } from "../../deps/cognit/assets/js/ui/core/hook";
import "../../deps/cognit/assets/js/ui/components/dialog.js";
import "../../deps/cognit/assets/js/ui/components/select.js";
import "../../deps/cognit/assets/js/ui/components/tabs.js";
import "../../deps/cognit/assets/js/ui/components/radio_group.js";
import "../../deps/cognit/assets/js/ui/components/popover.js";
import "../../deps/cognit/assets/js/ui/components/hover-card.js";
import "../../deps/cognit/assets/js/ui/components/collapsible.js";
import "../../deps/cognit/assets/js/ui/components/tooltip.js";
import "../../deps/cognit/assets/js/ui/components/accordion.js";
import "../../deps/cognit/assets/js/ui/components/slider.js";
import "../../deps/cognit/assets/js/ui/components/switch.js";
import "../../deps/cognit/assets/js/ui/components/dropdown_menu.js";
import "../../deps/cognit/assets/js/copy_button.js";
import { FlashMessage } from "../../deps/cognit/assets/js/hooks/flash_message.js";
import { Pagination } from "../../deps/cognit/assets/js/hooks/pagination.js";
import { Sidebar } from "../../deps/cognit/assets/js/hooks/sidebar.js";
import { SidebarMenu } from "../../deps/cognit/assets/js/hooks/sidebar_menu.js";
import { getCognitParams } from "../../deps/cognit/assets/js/connect_params.js";

let socketPath =
  document.querySelector("html").getAttribute("phx-socket") || "/live";
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

window.Alpine = Alpine;
Alpine.start();

let Hooks = {};

const LocaleSelect = {
  mounted() {
    this.el.addEventListener("set-locale", (event) => {
      this.setLocale(event.detail.locale);
    });
  },

  setLocale(locale) {
    const expiryDate = new Date();
    expiryDate.setTime(expiryDate.getTime() + 365 * 24 * 60 * 60 * 1000);
    document.cookie = `app_locale=${locale};expires=${expiryDate.toUTCString()};path=/`;

    const url = new URL(window.location.href);
    url.searchParams.set("locale", locale);
    window.location.assign(url.toString());
  },
};

Hooks.FlashMessage = FlashMessage;
Hooks.ExLingoColorPicker = ExLingoColorPicker;
Hooks.ExLingoGlossaryCapture = ExLingoGlossaryCapture;
Hooks.ExLingoInlineEdit = ExLingoInlineEdit;
Hooks.ExLingoListContext = ExLingoListContext;
Hooks.ExLingoSaveIndicator = ExLingoSaveIndicator;
Hooks.LocaleSelect = LocaleSelect;
Hooks.Pagination = Pagination;
Hooks.Sidebar = Sidebar;
Hooks.SidebarMenu = SidebarMenu;
Hooks.SaladUI = SaladUIHook;
Hooks.Select = Select;
Hooks.Toggle = Toggle;

let Uploaders = { S3 };

let liveSocket = new LiveView.LiveSocket(socketPath, Phoenix.Socket, {
  hooks: Hooks,
  uploaders: Uploaders,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
  params: () => {
    return {
      ...getCognitParams(),
      _csrf_token: csrfToken,
    };
  },
});

const socket = liveSocket.socket;
const originalOnConnError = socket.onConnError;
let fallbackToLongPoll = true;

socket.onOpen(() => {
  fallbackToLongPoll = false;
});

socket.onConnError = (...args) => {
  if (fallbackToLongPoll) {
    // No longer fallback to longpoll
    fallbackToLongPoll = false;
    // close the socket with an error code
    socket.disconnect(null, 3000);
    // fall back to long poll
    socket.transport = Phoenix.LongPoll;
    // reopen
    socket.connect();
  } else {
    originalOnConnError.apply(socket, args);
  }
};

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;
