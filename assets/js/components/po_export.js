// Exports DB translations back to .po files.
//
// Primary path (Chrome/Edge, secure context): the File System Access API lets
// the user pick their `priv/gettext` folder once; we then write every .po file
// directly into the matching subfolders, overwriting in place — no ZIP, no
// manual moving. Fallback (Firefox/Safari): the server returns a single ZIP we
// download.
export const PoExport = {
  mounted() {
    this.el.addEventListener("click", () => {
      const mode = window.showDirectoryPicker ? "fs" : "zip";
      this.pushEvent("export_po", { mode });
    });

    this.handleEvent("po_export_files", ({ files }) => this.writeFiles(files));
    this.handleEvent("po_export_zip", ({ data, filename }) =>
      this.downloadZip(data, filename),
    );
  },

  async writeFiles(files) {
    let root;
    try {
      root = await window.showDirectoryPicker({ mode: "readwrite" });
    } catch (error) {
      // User cancelled the directory picker — nothing to do.
      return;
    }

    try {
      for (const file of files) {
        const segments = file.path.split("/");
        const filename = segments.pop();

        let dir = root;
        for (const segment of segments) {
          dir = await dir.getDirectoryHandle(segment, { create: true });
        }

        const handle = await dir.getFileHandle(filename, { create: true });
        const writable = await handle.createWritable();
        await writable.write(file.content);
        await writable.close();
      }

      this.pushEvent("po_export_written", { count: files.length });
    } catch (error) {
      console.error("Failed to write PO files", error);
      window.alert("Failed to write PO files: " + error.message);
    }
  },

  downloadZip(data, filename) {
    const bytes = Uint8Array.from(atob(data), (char) => char.charCodeAt(0));
    const blob = new Blob([bytes], { type: "application/zip" });
    const url = URL.createObjectURL(blob);

    const link = document.createElement("a");
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    URL.revokeObjectURL(url);
  },
};
