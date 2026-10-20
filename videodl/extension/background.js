// Relay between content scripts and the videodl native messaging host.
// Content scripts cannot call sendNativeMessage themselves, so they message us.

const HOST = "com.linuxer.videodl";

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (!msg || msg.type !== "videodl") return;

  try {
    chrome.runtime.sendNativeMessage(HOST, msg.payload, (resp) => {
      if (chrome.runtime.lastError) {
        sendResponse({ ok: false, error: chrome.runtime.lastError.message });
        return;
      }
      sendResponse(resp || { ok: false, error: "no response from download host" });
    });
  } catch (err) {
    sendResponse({ ok: false, error: String(err) });
  }

  return true; // keep the channel open for the async reply
});
