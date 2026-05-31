import Alpine from "alpinejs";
import { ExLingoColorPicker } from "./components/color_picker";
import { ExLingoGlossaryCapture } from "./components/glossary_capture";
import { ExLingoInlineEdit } from "./components/inline_edit";
import { ExLingoListContext } from "./components/list_context";
import { ExLingoRowGroupHover } from "./components/row_group_hover";
import { ExLingoSaveIndicator } from "./components/save_indicator";
import { PoExport } from "./components/po_export";
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
import { LocaleSelect } from "../../deps/cognit/assets/js/hooks/locale_select.js";
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

// Cognit (>= 0.2.x) namespaces its LiveView hooks under "Cognit.*"; SaladUI
// stays unprefixed. These names must match what the cognit components render.
Hooks["Cognit.FlashMessage"] = FlashMessage;
Hooks["Cognit.LocaleSelect"] = LocaleSelect;
Hooks["Cognit.Pagination"] = Pagination;
Hooks["Cognit.Sidebar"] = Sidebar;
Hooks["Cognit.SidebarMenu"] = SidebarMenu;
Hooks.SaladUI = SaladUIHook;

Hooks.ExLingoColorPicker = ExLingoColorPicker;
Hooks.ExLingoGlossaryCapture = ExLingoGlossaryCapture;
Hooks.ExLingoInlineEdit = ExLingoInlineEdit;
Hooks.ExLingoListContext = ExLingoListContext;
Hooks.ExLingoRowGroupHover = ExLingoRowGroupHover;
Hooks.ExLingoSaveIndicator = ExLingoSaveIndicator;
Hooks.PoExport = PoExport;
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
