// External LiveView uploader: PUTs each file directly to a presigned S3 URL.
// The server returns `{ uploader: "S3", key, url }` from `presign_upload/2`;
// `url` is a presigned PUT URL. The bucket needs CORS allowing PUT from the
// dashboard origin.
export const S3 = function (entries, onViewError) {
  entries.forEach((entry) => {
    const { url } = entry.meta;
    const xhr = new XMLHttpRequest();

    onViewError(() => xhr.abort());

    xhr.onload = () =>
      xhr.status >= 200 && xhr.status < 300 ? entry.progress(100) : entry.error();
    xhr.onerror = () => entry.error();

    xhr.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable) {
        const percent = Math.round((event.loaded / event.total) * 100);
        // Reserve 100% for the onload handler so the entry is only marked done
        // once S3 confirms the upload.
        if (percent < 100) {
          entry.progress(percent);
        }
      }
    });

    xhr.open("PUT", url, true);
    if (entry.file.type) {
      xhr.setRequestHeader("Content-Type", entry.file.type);
    }
    xhr.send(entry.file);
  });
};
