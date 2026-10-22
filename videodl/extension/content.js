// Video Grabber - floating download button anchored to <video> elements.
// The button opens a quality panel (video heights + audio-only streams) and asks
// the background service worker to relay the choice to the videodl native host.

(() => {
  "use strict";

  if (window.__videodlLoaded) return;
  window.__videodlLoaded = true;

  const MIN_W = 220;
  const MIN_H = 120;
  const BTN = 34;

  let hostEl = null;
  let shadow = null;
  let btn = null;
  let card = null;
  let currentVideo = null;
  let panelOpen = false;
  let formats = null; // last successful enumeration
  let formatsUrl = "";
  let panelUrl = ""; // target resolved when the panel was opened
  let busy = false;
  let savingDir = false;
  let pickingDir = false; // a native folder chooser is open
  let savedDir = ""; // folder the host will use
  let dirOverride = ""; // non-empty when VIDEODL_DIR forces a folder

  // Per-download post-processing choices. yt-dlp does both by default, so the
  // panel starts with them on and remembers whatever the user picks.
  const OPT_KEY = "videodl.embed";
  let embedThumb = true;
  let embedMeta = true;

  const cache = new Map(); // url -> formats payload

  // Codec pills offered under the video list.
  const CODEC_ORDER = ["h264", "vp9", "av1", "hevc", "vp8"];
  const CODEC_LABELS = {
    h264: "H.264",
    vp9: "VP9",
    av1: "AV1",
    hevc: "HEVC",
    vp8: "VP8",
  };
  const codecRank = (k) => {
    const i = CODEC_ORDER.indexOf(k);
    return i === -1 ? 99 : i;
  };
  let codecSel = "auto"; // "auto" or a codec key such as "h264"

  // ---------------------------------------------------------------- utilities
  const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);
  const isHttp = (u) => typeof u === "string" && /^https?:\/\//i.test(u);

  // ------------------------------------------------------------------- links
  // The button floats on the biggest <video> of the page. On feed and SPA
  // sites (X home, Reddit, Instagram, TikTok) that player sits inside a feed,
  // so the page address is the feed root and yt-dlp refuses it with
  // "Unsupported URL". The post's own permalink is an <a href> right next to
  // the player, so look for it around the video before falling back.
  const PERMALINK_RES = [
    /\/status\/\d{5,}/, // x / twitter
    /\/@[^/]+\/\d{8,}/, // mastodon style
    /\/comments\/[A-Za-z0-9]{4,}/, // reddit
    /\/(?:p|reel|reels|tv)\/[A-Za-z0-9_-]{5,}/, // instagram
    /\/@[^/]+\/video\/\d{4,}/, // tiktok
    /\/video\/[A-Za-z0-9_-]{3,}/, // dailymotion, vk, rumble
    /\/watch\?v=[A-Za-z0-9_-]{6,}/, // youtube
    /\/shorts\/[A-Za-z0-9_-]{6,}/, // youtube shorts
    /\/(?:videos|reel)\/\d{4,}/, // facebook
    /\/v\/\d{4,}/, // vk video
    /\/pin\/\d{4,}/, // pinterest
  ];

  // Containers that hold exactly one post. Inside them a media link belongs
  // to that post.
  const POST_ROOT_SEL =
    "article, shreddit-post, [data-testid='tweet'], [data-testid='quoteTweet'], [role='article'], [data-test-id='post-content']";

  // Plain media files the player may point at directly.
  const MEDIA_FILE_RE =
    /\.(?:mp4|m4v|webm|mkv|mov|m4a|mp3|ogg|opus|flac|wav)(?:[?#]|$)/i;

  // Page paths that are a feed listing rather than a single post.
  const FEED_PATH_RES = [
    /^\/(?:home|explore|search|notifications|messages|i\/(?:home|explore|search|notifications|messages))?\/?$/i,
    /^\/(?:r|u)\/[^/]+\/?$/i, // reddit listing
    /^\/(?:home|explore|popular|all|foryou|following|feed)\/?$/i,
    /^\/(?:reels|explore|direct|stories)\/?$/i, // instagram
    /^\/@[^/]+\/?$/i, // tiktok profile
    /^\/?$/i, // site root
  ];

  function mediaLink(href) {
    if (!href) return null;
    let u;
    try {
      u = new URL(href, location.href);
    } catch (_) {
      return null;
    }
    if (u.protocol !== "http:" && u.protocol !== "https:") return null;
    if (/\/analytics(?:[/?#]|$)/i.test(u.pathname)) return null;
    const s = u.pathname + u.search;
    for (const re of PERMALINK_RES) if (re.test(s)) return u.href;
    return null;
  }

  function isPostUrl(url) {
    return mediaLink(url) !== null;
  }

  function isFeedRoot(url) {
    let p;
    try {
      p = new URL(url);
    } catch (_) {
      return false;
    }
    return FEED_PATH_RES.some((re) => re.test(p.pathname));
  }

  function permalinkFor(video) {
    if (!video) return null;

    // The player may be wrapped in the post link itself.
    const owner = video.closest("a[href]");
    if (owner) {
      const link = mediaLink(owner.getAttribute("href"));
      if (link) return link;
    }

    // Search the post container first, then a few levels around the player.
    const scopes = [];
    const root = video.closest(POST_ROOT_SEL);
    if (root) scopes.push(root);

    let node = video.parentElement;
    for (let depth = 0; node && depth < 6; depth++, node = node.parentElement) {
      if (
        node === document.body ||
        node === document.documentElement ||
        node.tagName === "MAIN"
      )
        break;
      scopes.push(node);
    }

    for (const scope of scopes) {
      const cands = [];
      for (const a of scope.querySelectorAll("a[href]")) {
        const link = mediaLink(a.getAttribute("href"));
        if (!link) continue;

        // Which post owns this link? A quoted or reposted post carries its
        // own container, and the player usually belongs to the post around
        // it rather than to the quote.
        const post = a.closest(POST_ROOT_SEL) || scope;
        const owns = post.contains(video);

        // How deep the link sits in the scope: the post's own link is closer
        // to the surface than a nested quote's.
        let depth = 0;
        let n = a.parentElement;
        while (n && n !== scope) {
          depth++;
          n = n.parentElement;
        }
        if (n !== scope) continue; // not inside this scope after all

        cands.push({ link, owns, depth });
      }
      if (!cands.length) continue;

      // Prefer the post that actually holds the player, then the link that
      // sits closest to the surface.
      const owners = cands.filter((c) => c.owns);
      const pool = owners.length ? owners : cands;
      let best = pool[0].depth;
      for (const c of pool) if (c.depth < best) best = c.depth;
      return pool.find((c) => c.depth === best).link;
    }
    return null;
  }

  function pageUrl(video) {
    const v = video || currentVideo;
    const here = location.href;

    // Embedded players live on their own URL; rewrite those to the post.
    const yt = here.match(/youtube(?:-nocookie)?\.com\/embed\/([A-Za-z0-9_-]{6,})/);
    if (yt) return "https://www.youtube.com/watch?v=" + yt[1];

    const vm = here.match(/player\.vimeo\.com\/video\/(\d+)/);
    if (vm) return "https://vimeo.com/" + vm[1];

    const tw = here.match(/platform\.twitter\.com\/embed\/[^#]*[?&]id=(\d+)/);
    if (tw) return "https://x.com/i/status/" + tw[1];

    const ig = here.match(
      /instagram\.com\/(p|reel|reels|tv)\/([A-Za-z0-9_-]{5,})\/embed/
    );
    if (ig) return "https://www.instagram.com/" + ig[1] + "/" + ig[2] + "/";

    // The address of the top frame: on most sites this is the post page.
    let page = here;
    try {
      const t = window.top;
      if (t && isHttp(t.location.href)) page = t.location.href;
    } catch (_) {
      /* cross-origin frame */
    }

    // A post page is already what yt-dlp wants.
    if (isPostUrl(page)) return page;

    // Feed and SPA pages: find the post this player belongs to.
    const permalink = permalinkFor(v);
    if (permalink) return permalink;

    // The page itself, unless it is only a feed listing.
    if (!isFeedRoot(page)) return page;

    // A plain media file in the player is the last resort.
    const src = v && (v.currentSrc || v.src);
    if (isHttp(src) && MEDIA_FILE_RE.test(src)) return src;

    return isHttp(page) ? page : null;
  }

  function pickVideo() {
    const vids = Array.from(document.querySelectorAll("video"));
    let best = null;
    let bestArea = 0;

    for (const v of vids) {
      if (!v.isConnected) continue;
      const r = v.getBoundingClientRect();
      if (r.width < MIN_W || r.height < MIN_H) continue;
      if (r.bottom < 0 || r.top > innerHeight || r.right < 0 || r.left > innerWidth)
        continue;

      const cs = getComputedStyle(v);
      if (cs.display === "none" || cs.visibility === "hidden") continue;
      if (parseFloat(cs.opacity) < 0.05) continue;

      // Skip decorative background loops (muted, looping, very short).
      if (v.muted && v.loop && v.duration && v.duration < 30) continue;

      const area = r.width * r.height;
      if (area > bestArea) {
        best = v;
        bestArea = area;
      }
    }
    return best;
  }

  // --------------------------------------------------------------------- host
  function ensureHost() {
    if (hostEl && hostEl.isConnected) return shadow;

    hostEl = document.createElement("div");
    hostEl.id = "__videodl_root";
    hostEl.style.cssText =
      "all:initial;position:fixed;left:0;top:0;width:0;height:0;z-index:2147483647;pointer-events:none;";
    shadow = hostEl.attachShadow({ mode: "open" });

    shadow.innerHTML = `
      <style>
        :host { all: initial; }
        * { box-sizing: border-box; }
        .btn {
          position: fixed; width: ${BTN}px; height: ${BTN}px; border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          background: rgba(26,23,19,.92); color: #A7C080; cursor: pointer;
          border: 1px solid rgba(167,192,128,.38);
          box-shadow: 0 4px 14px rgba(0,0,0,.45);
          opacity: .55; transition: opacity .15s ease, transform .15s ease;
          pointer-events: auto; padding: 0; margin: 0;
        }
        .btn:hover, .btn.on { opacity: 1; transform: translateY(-1px); }
        .btn svg { width: 18px; height: 18px; display: block; }
        .card {
          position: fixed; width: 304px; max-height: 72vh; overflow: auto;
          background: #1a1713; color: #d1c4a9;
          border: 1px solid rgba(167,192,128,.30); border-radius: 12px;
          box-shadow: 0 14px 40px rgba(0,0,0,.55);
          font: 13px/1.45 system-ui, -apple-system, "Segoe UI", sans-serif;
          pointer-events: auto; padding: 0;
        }
        .card[hidden] { display: none; }
        .card::-webkit-scrollbar { width: 8px; }
        .card::-webkit-scrollbar-track { background: transparent; }
        .card::-webkit-scrollbar-thumb {
          background: rgba(167,192,128,.28); border-radius: 8px;
          border: 2px solid #1a1713;
        }
        .card::-webkit-scrollbar-thumb:hover { background: rgba(167,192,128,.5); }
        .head {
          display: flex; gap: 8px; align-items: flex-start;
          padding: 11px 12px 9px; border-bottom: 1px solid rgba(209,196,169,.12);
          position: sticky; top: 0; background: #1a1713; z-index: 2;
        }
        .title {
          flex: 1; font-weight: 600; font-size: 12.5px; color: #d1c4a9;
          overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2;
          -webkit-box-orient: vertical; word-break: break-word;
        }
        .x {
          flex: none; width: 20px; height: 20px; border-radius: 6px; cursor: pointer;
          background: transparent; border: 0; color: #7c7468; font-size: 16px;
          line-height: 1; padding: 0;
        }
        .x:hover { color: #d1c4a9; background: rgba(209,196,169,.08); }
        .body { padding: 8px 12px 4px; }
        .status { color: #7c7468; font-size: 12px; padding: 6px 0 8px; }
        .status.err { color: #E67E80; }
        .sect { margin-bottom: 10px; }
        .sect[hidden] { display: none; }
        .lbl {
          font-size: 10.5px; letter-spacing: .07em; text-transform: uppercase;
          color: #7c7468; margin: 0 0 5px;
        }
        .opt {
          display: flex; align-items: center; gap: 8px; padding: 5px 7px;
          border-radius: 7px; cursor: pointer; color: #d1c4a9;
        }
        .opt:hover { background: rgba(209,196,169,.07); }
        .opt input { accent-color: #A7C080; margin: 0; flex: none; }
        .opt span { flex: 1; font-size: 12.5px; }
        .opt em { color: #7c7468; font-style: normal; font-size: 11px; }
        .conv {
          display: flex; align-items: center; gap: 8px; padding: 7px 7px 2px;
          color: #92a08a; font-size: 12px;
        }
        .conv.off { opacity: .45; pointer-events: none; }
        .conv select {
          flex: 1; min-width: 0; color-scheme: dark; cursor: pointer;
          background: rgba(209,196,169,.06); color: #d1c4a9;
          border: 1px solid rgba(167,192,128,.22); border-radius: 7px;
          padding: 4px 6px; font: inherit; font-size: 12px;
        }
        .conv select:focus { outline: 1px solid rgba(167,192,128,.55); }
        .conv option { background: #1a1713; color: #d1c4a9; }
        .codecs { padding: 1px 7px 0; }
        .codecs[hidden] { display: none; }
        .pills { display: flex; flex-wrap: wrap; gap: 6px; padding: 1px 0 5px; }
        .pill {
          border: 1px solid rgba(167,192,128,.26); background: transparent;
          color: #8d9784; font: inherit; font-size: 11.5px; line-height: 1.35;
          padding: 3px 10px; border-radius: 999px; cursor: pointer;
        }
        .pill:hover { border-color: rgba(167,192,128,.5); color: #d1c4a9; }
        .pill.on {
          background: rgba(167,192,128,.18); border-color: rgba(167,192,128,.55);
          color: #A7C080; font-weight: 600;
        }
        .chkrow { display: flex; align-items: center; gap: 4px; margin: 0 0 1px -7px; }
        .chk {
          display: flex; align-items: center; gap: 6px; padding: 2px 7px;
          border-radius: 7px; cursor: pointer; color: #b9ae97;
        }
        .chk:hover { background: rgba(209,196,169,.08); color: #d1c4a9; }
        .chk input {
          margin: 0; flex: none; accent-color: #A7C080;
          width: 12px; height: 12px; cursor: pointer;
        }
        .chk span { flex: 1; min-width: 0; font-size: 11.5px; line-height: 1.4; }
        .foot {
          display: flex; flex-direction: column; gap: 7px;
          padding: 9px 12px 11px; border-top: 1px solid rgba(209,196,169,.12);
          position: sticky; bottom: 0; background: #1a1713;
        }
        .dirline { display: flex; align-items: center; gap: 6px; }
        .dir {
          flex: 1; min-width: 0; font: inherit; font-size: 11.5px;
          color: #d1c4a9; background: rgba(209,196,169,.06);
          border: 1px solid rgba(167,192,128,.22); border-radius: 7px;
          padding: 4px 7px;
        }
        .dir:focus { outline: 1px solid rgba(167,192,128,.55); }
        .dir:disabled { opacity: .55; }
        .dir::placeholder { color: #7c7468; }
        .set {
          flex: none; border: 1px solid rgba(167,192,128,.4); background: transparent;
          color: #A7C080; font: inherit; font-size: 11.5px; font-weight: 600;
          padding: 4px 9px; border-radius: 7px; cursor: pointer;
        }
        .set:hover { background: rgba(167,192,128,.16); }
        .set:disabled { opacity: .45; cursor: default; }
        .pick {
          flex: none; display: flex; align-items: center; justify-content: center;
          width: 26px; height: 26px; padding: 0; border-radius: 7px;
          cursor: pointer; background: transparent; color: #A7C080;
          border: 1px solid rgba(167,192,128,.35);
        }
        .pick:hover { background: rgba(167,192,128,.16); }
        .pick:disabled { opacity: .45; cursor: default; background: transparent; }
        .pick svg { width: 14px; height: 14px; }
        .footrow { display: flex; align-items: center; gap: 8px; }
        .note { flex: 1; font-size: 11px; color: #7c7468; word-break: break-all; }
        .note.err { color: #E67E80; }
        .go {
          border: 1px solid rgba(167,192,128,.5); background: rgba(167,192,128,.16);
          color: #A7C080; font-weight: 600; font-size: 12px; padding: 6px 12px;
          border-radius: 8px; cursor: pointer;
        }
        .go:hover { background: rgba(167,192,128,.26); }
        .go:disabled { opacity: .45; cursor: default; }
      </style>
      <button class="btn" title="Download this video">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M12 3v11"></path>
          <path d="M7.5 10.5 12 15l4.5-4.5"></path>
          <path d="M4 18.5h16"></path>
        </svg>
      </button>
      <div class="card" hidden>
        <div class="head">
          <div class="title"></div>
          <button class="x" title="Close">&times;</button>
        </div>
        <div class="body">
          <div class="status">Reading available formats&hellip;</div>
          <div class="sect video"><div class="lbl">Video</div><div class="opts"></div>
            <div class="codecs" hidden>
              <div class="lbl">Codec</div>
              <div class="pills"></div>
            </div>
          </div>
          <div class="sect audio"><div class="lbl">Audio only</div><div class="opts"></div>
            <div class="conv off">
              <span>Format</span>
              <select class="afmt" title="Re-encode the audio stream">
                <option value="">Original</option>
                <option value="mp3">MP3 (320k)</option>
                <option value="m4a">M4A (AAC)</option>
                <option value="flac">FLAC</option>
              </select>
            </div>
          </div>
        </div>
        <div class="foot">
          <div class="chkrow">
            <label class="chk" title="Put the video thumbnail in the file as cover art">
              <input type="checkbox" class="cthumb" checked>
              <span>Thumbnail</span>
            </label>
            <label class="chk" title="Write the title and source tags into the file">
              <input type="checkbox" class="cmeta" checked>
              <span>Metadata</span>
            </label>
          </div>
          <div class="dirline">
            <input class="dir" type="text" spellcheck="false" autocomplete="off"
                   placeholder="/mnt/media/Downloads" title="Where to save the file" />
            <button class="pick" type="button" title="Choose a folder…">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor"
                   stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                   aria-hidden="true">
                <path d="M3 7.5A1.5 1.5 0 0 1 4.5 6h4l2 2.5h7A1.5 1.5 0 0 1 19 10v7a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 3 17z"></path>
              </svg>
            </button>
            <button class="set" type="button" title="Save to this folder">Set</button>
          </div>
          <div class="footrow">
            <span class="note">Saved to ~/Videos</span>
            <button class="go" disabled>Download</button>
          </div>
        </div>
      </div>
    `;

    btn = shadow.querySelector(".btn");
    card = shadow.querySelector(".card");

    btn.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      if (panelOpen) closePanel();
      else openPanel();
    });
    shadow.querySelector(".x").addEventListener("click", (e) => {
      e.stopPropagation();
      closePanel();
    });
    shadow.querySelector(".go").addEventListener("click", (e) => {
      e.stopPropagation();
      startDownload();
    });
    shadow.querySelector(".set").addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      saveDir();
    });
    shadow.querySelector(".pick").addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      pickDir();
    });
    shadow.querySelector(".dir").addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        e.stopPropagation();
        saveDir();
      }
    });
    shadow.querySelector(".cthumb").addEventListener("change", (e) => {
      embedThumb = !!e.target.checked;
      saveEmbedOpts();
    });
    shadow.querySelector(".cmeta").addEventListener("change", (e) => {
      embedMeta = !!e.target.checked;
      saveEmbedOpts();
    });
    // Any change inside the panel (radio picks included) keeps the panels in sync.
    shadow.querySelector(".card").addEventListener("change", syncAudioOpts);
    shadow.querySelector(".pills").addEventListener("click", (e) => {
      const pill = e.target.closest && e.target.closest(".pill");
      if (!pill) return;
      e.preventDefault();
      e.stopPropagation();
      codecSel = pill.dataset.c || "auto";
      updateCodecs();
    });

    document.documentElement.appendChild(hostEl);
    return shadow;
  }

  // ---------------------------------------------------------------- rendering
  function heightLabel(h) {
    if (h >= 2160) return `${h}p <em>4K</em>`;
    if (h >= 1440) return `${h}p <em>QHD</em>`;
    if (h >= 1080) return `${h}p <em>Full HD</em>`;
    if (h >= 720) return `${h}p <em>HD</em>`;
    return `${h}p`;
  }

  function renderFormats(data) {
    const videoBox = shadow.querySelector(".sect.video .opts");
    const audioBox = shadow.querySelector(".sect.audio .opts");
    const status = shadow.querySelector(".status");
    const go = shadow.querySelector(".go");
    const videoSect = shadow.querySelector(".sect.video");
    const audioSect = shadow.querySelector(".sect.audio");

    const videoList = Array.isArray(data.video) ? data.video : [];
    const heights = (videoList.length
      ? videoList.map((v) => v.height)
      : data.heights || []
    ).slice(0, 8);
    const audio = data.audio || [];

    let html = `<label class="opt"><input type="radio" name="vdq" value="v:0" checked>
                  <span>Best available <em>${heights.length ? heights[0] + "p" : ""}</em></span></label>`;

    for (const h of heights) {
      if (h === heights[0]) continue; // "Best" already covers it
      html += `<label class="opt"><input type="radio" name="vdq" value="v:${h}">
                 <span>${heightLabel(h)}</span></label>`;
    }
    videoBox.innerHTML = html;
    videoSect.hidden = !data.has_video && heights.length === 0;

    let ahtml = `<label class="opt"><input type="radio" name="vdq" value="a:">
                   <span>Best audio <em>native format</em></span></label>`;
    for (const a of audio) {
      ahtml += `<label class="opt"><input type="radio" name="vdq" value="a:${a.id}">
                  <span>${a.ext} <em>${a.abr}k &middot; ${a.codec || "audio"}</em></span></label>`;
    }
    audioBox.innerHTML = ahtml;
    audioSect.hidden = audio.length === 0 && !data.has_video;

    status.textContent = "";
    status.hidden = true;
    go.disabled = false;
    syncAudioOpts();
    positionPanel();
  }

  // Draw the codec pills for a given set of codec keys.
  function renderCodecPills(keys) {
    const wrap = shadow.querySelector(".codecs");
    const box = shadow.querySelector(".pills");
    if (!keys.length) {
      wrap.hidden = true;
      box.innerHTML = "";
      return;
    }
    wrap.hidden = false;
    if (codecSel !== "auto" && !keys.includes(codecSel)) codecSel = "auto";

    let html =
      `<button type="button" class="pill${codecSel === "auto" ? " on" : ""}"` +
      ` data-c="auto" title="Let yt-dlp choose the best codec">Auto</button>`;
    for (const k of keys) {
      html +=
        `<button type="button" class="pill${codecSel === k ? " on" : ""}"` +
        ` data-c="${k}" title="${k}">${CODEC_LABELS[k] || k.toUpperCase()}</button>`;
    }
    box.innerHTML = html;
  }

  // Codecs actually offered at the height that is currently selected.
  function updateCodecs() {
    const wrap = shadow.querySelector(".codecs");
    const picked = shadow.querySelector('input[name="vdq"]:checked');
    if (!picked || picked.value.startsWith("a:")) {
      wrap.hidden = true;
      return;
    }

    const data = formats;
    if (!data || !Array.isArray(data.video) || !data.video.length) {
      // Enumeration failed: still let the user express a preference.
      renderCodecPills(["h264", "vp9", "av1"]);
      return;
    }

    const height = Number(picked.value.slice(2)) || 0;
    const row = height
      ? data.video.find((v) => v.height === height) || data.video[0]
      : data.video[0];
    const keys = [];
    for (const c of row.codecs || []) {
      if (c && c.key && !keys.includes(c.key)) keys.push(c.key);
    }
    keys.sort((a, b) => codecRank(a) - codecRank(b));
    renderCodecPills(keys);
  }

  function syncAudioOpts() {
    const box = shadow.querySelector(".conv");
    const picked = shadow.querySelector('input[name="vdq"]:checked');
    const isAudio = picked && picked.value.startsWith("a:");
    box.classList.toggle("off", !isAudio);
    updateCodecs();
  }

  // -------------------------------------------------------------- save folder
  // The destination lives in the native host's config (single source of truth),
  // so the panel mirrors it here instead of keeping its own copy.
  function setNote(text, isError) {
    const note = shadow.querySelector(".note");
    if (!note) return;
    note.textContent = text;
    note.classList.toggle("err", !!isError);
  }

  // Post-processing choices live in chrome.storage so they stick per browser
  // profile; every extra guard is for contexts where storage is unavailable.
  function applyEmbedOpts() {
    if (!shadow) return;
    const t = shadow.querySelector(".cthumb");
    const m = shadow.querySelector(".cmeta");
    if (t) t.checked = embedThumb;
    if (m) m.checked = embedMeta;
  }

  function saveEmbedOpts() {
    try {
      const store = chrome.storage && chrome.storage.local;
      if (store) store.set({ [OPT_KEY]: { thumb: embedThumb, meta: embedMeta } });
    } catch (_) {
      /* storage unavailable — the choice still applies to this session */
    }
  }

  function loadEmbedOpts() {
    applyEmbedOpts();
    try {
      const store = chrome.storage && chrome.storage.local;
      if (!store) return;
      store.get(OPT_KEY, (v) => {
        const s = (v && v[OPT_KEY]) || {};
        if (typeof s.thumb === "boolean") embedThumb = s.thumb;
        if (typeof s.meta === "boolean") embedMeta = s.meta;
        applyEmbedOpts();
      });
    } catch (_) {
      /* ignore */
    }
  }

  function applyConfig(cfg) {
    if (!panelOpen || !shadow || !cfg || !cfg.ok) return;
    savedDir = cfg.dir || "";
    dirOverride = cfg.override || "";

    const input = shadow.querySelector(".dir");
    const setBtn = shadow.querySelector(".set");
    const pickBtn = shadow.querySelector(".pick");
    input.value = savedDir;
    input.title = savedDir;

    if (dirOverride) {
      input.disabled = true;
      setBtn.disabled = true;
      if (pickBtn) pickBtn.disabled = true;
      setBtn.title = "VIDEODL_DIR is set in the environment and wins over the setting";
      setNote(`Saved to ${savedDir} (VIDEODL_DIR is set)`);
    } else {
      input.disabled = false;
      setBtn.disabled = savingDir;
      if (pickBtn) pickBtn.disabled = pickingDir;
      setBtn.title = "Save to this folder";
      setNote(`Saved to ${savedDir}`);
    }
  }

  function loadConfig() {
    try {
      chrome.runtime.sendMessage(
        { type: "videodl", payload: { action: "config" } },
        (resp) => {
          if (chrome.runtime.lastError) return;
          applyConfig(resp);
        }
      );
    } catch (_) {
      /* extension reloaded — the next panel open retries */
    }
  }

  function saveDir() {
    if (!shadow || savingDir) return;
    const input = shadow.querySelector(".dir");
    const setBtn = shadow.querySelector(".set");
    const raw = (input.value || "").trim();

    if (!raw) {
      setNote("Enter a folder path first", true);
      return;
    }

    savingDir = true;
    setBtn.disabled = true;
    setNote("Checking folder…");

    const done = (resp) => {
      savingDir = false;
      if (!panelOpen || !shadow) return;
      setBtn.disabled = !!dirOverride;
      if (resp && resp.ok) {
        savedDir = resp.dir;
        input.value = resp.dir;
        input.title = resp.dir;
        setNote(`Saved to ${resp.dir}`);
      } else {
        setNote((resp && resp.error) || "Could not use that folder", true);
      }
    };

    try {
      chrome.runtime.sendMessage(
        { type: "videodl", payload: { action: "setdir", dir: raw } },
        (resp) => {
          if (chrome.runtime.lastError) {
            done({ ok: false, error: chrome.runtime.lastError.message });
            return;
          }
          done(resp);
        }
      );
    } catch (_) {
      done({ ok: false, error: "Extension reloaded — refresh the page." });
    }
  }

  // The folder glyph asks the native host for a real chooser (zenity/kdialog),
  // because typing an absolute path is no way to reach a folder on another disk.
  // The host stores whatever comes back, exactly like "Set" does.
  function pickDir() {
    if (!shadow || savingDir || pickingDir) return;

    const input = shadow.querySelector(".dir");
    const pickBtn = shadow.querySelector(".pick");
    if (dirOverride) {
      setNote(`Saved to ${savedDir} (VIDEODL_DIR is set)`, true);
      return;
    }

    pickingDir = true;
    if (pickBtn) pickBtn.disabled = true;
    setNote("Waiting for the folder chooser…");

    const done = (resp) => {
      pickingDir = false;
      if (!panelOpen || !shadow) return;
      if (pickBtn) pickBtn.disabled = false;
      if (resp && resp.ok && resp.cancelled) {
        setNote(`Saved to ${savedDir}`); // dialog dismissed — nothing changed
      } else if (resp && resp.ok && resp.dir) {
        savedDir = resp.dir;
        input.value = resp.dir;
        input.title = resp.dir;
        setNote(`Saved to ${resp.dir}`);
      } else {
        setNote(
          (resp && resp.error) || "Could not open the folder chooser",
          true
        );
      }
    };

    try {
      chrome.runtime.sendMessage(
        { type: "videodl", payload: { action: "pick-dir" } },
        (resp) => {
          if (chrome.runtime.lastError) {
            done({ ok: false, error: chrome.runtime.lastError.message });
            return;
          }
          done(resp);
        }
      );
    } catch (_) {
      done({ ok: false, error: "Extension reloaded — refresh the page." });
    }
  }

  // ------------------------------------------------------------------- panel
  function openPanel() {
    if (!currentVideo) return;
    ensureHost();

    panelOpen = true;
    btn.classList.add("on");
    card.hidden = false;

    // Resolve the target once: the probe and the download must agree, even if
    // the page scrolls and the button moves to another player in the meantime.
    const url = pageUrl(currentVideo);
    panelUrl = url || "";
    shadow.querySelector(".title").textContent =
      (document.title || "Video").slice(0, 120);
    shadow.querySelector(".status").hidden = false;
    shadow.querySelector(".status").classList.remove("err");
    shadow.querySelector(".status").textContent = "Reading available formats…";
    shadow.querySelector(".sect.video .opts").innerHTML = "";
    shadow.querySelector(".sect.audio .opts").innerHTML = "";
    shadow.querySelector(".codecs").hidden = true;
    shadow.querySelector(".pills").innerHTML = "";
    shadow.querySelector(".afmt").value = "";
    codecSel = "auto";
    shadow.querySelector(".go").disabled = true;

    positionPanel();
    loadConfig();
    loadEmbedOpts();

    if (!url) {
      setError("Could not determine this page's address.");
      return;
    }

    if (cache.has(url)) {
      renderFormats(cache.get(url));
      return;
    }

    loadFormats(url);
  }

  function closePanel() {
    panelOpen = false;
    panelUrl = "";
    if (btn) btn.classList.remove("on");
    if (card) card.hidden = true;
  }

  function setError(text) {
    const s = shadow.querySelector(".status");
    s.hidden = false;
    s.classList.add("err");
    s.textContent = text;
  }

  // Turn a yt-dlp complaint into something a person can act on.
  function probeMessage(error, url) {
    const e = String(error || "");
    if (/unsupported url/i.test(e))
      return "No video on this address that yt-dlp can read — open the video's own post and try again.";
    if (/private video/i.test(e)) return "This video is private.";
    if (/geo|country|not available in your region/i.test(e))
      return "This video is blocked in this region.";
    if (/sign in|login|cookies|confirm your age|age.restricted/i.test(e))
      return "This video needs a signed-in session — try it in the browser you are signed in to.";
    if (isFeedRoot(url))
      return "This is a feed page — open the video's own post and try again.";
    return "Quality list unavailable — the best available version will be downloaded.";
  }

  function loadFormats(url) {
    const token = url;
    formatsUrl = token;

    try {
      chrome.runtime.sendMessage(
        { type: "videodl", payload: { action: "formats", url } },
        (resp) => {
          if (formatsUrl !== token || !panelOpen) return;
          if (!resp || !resp.ok) {
            // yt-dlp cannot introspect every page (drm players, auth walls,
            // plain embeds). Say why in plain words and keep the button useful.
            console.debug("[videodl] formats lookup failed:", resp && resp.error);
            const s = shadow.querySelector(".status");
            s.hidden = false;
            s.classList.remove("err");
            s.textContent = probeMessage(resp && resp.error, url);
            const go = shadow.querySelector(".go");
            go.disabled = false;
            // No honest height list exists, so offer the best quality only
            // instead of inventing resolutions this page may not have.
            shadow.querySelector(".sect.video .opts").innerHTML =
              `<label class="opt"><input type="radio" name="vdq" value="v:0" checked>` +
              `<span>Best available</span></label>`;
            shadow.querySelector(".sect.audio .opts").innerHTML =
              `<label class="opt"><input type="radio" name="vdq" value="a:">` +
              `<span>Best audio <em>native format</em></span></label>`;
            shadow.querySelector(".sect.audio").hidden = false;
            formats = null;
            syncAudioOpts();
            positionPanel();
            return;
          }
          cache.set(token, resp);
          formats = resp;
          renderFormats(resp);
        }
      );
    } catch (err) {
      setError("Extension reloaded — refresh the page.");
    }
  }

  // -------------------------------------------------------------- positioning
  function positionButton(rect) {
    const x = clamp(rect.right - BTN - 10, 8, innerWidth - BTN - 8);
    const y = clamp(rect.top + 10, 8, innerHeight - BTN - 8);
    btn.style.left = x + "px";
    btn.style.top = y + "px";
    return { x, y };
  }

  function positionPanel() {
    if (!panelOpen || !card || card.hidden) return;
    const r = currentVideo ? currentVideo.getBoundingClientRect() : null;
    if (!r) return;

    const bw = card.offsetWidth || 304;
    const bh = card.offsetHeight || 320;

    const anchorX = clamp(r.right - BTN - 10, 8, innerWidth - BTN - 8);
    const anchorY = clamp(r.top + 10, 8, innerHeight - BTN - 8);

    let left = clamp(anchorX + BTN - bw, 8, innerWidth - bw - 8);
    let top = anchorY + BTN + 8;
    if (top + bh > innerHeight - 8) {
      top = Math.max(8, anchorY - bh - 8);
    }

    card.style.left = left + "px";
    card.style.top = top + "px";
  }

  function update() {
    const v = pickVideo();
    if (v !== currentVideo) {
      // A different player is now the biggest one on screen: the open panel
      // belongs to the old one, so drop its target.
      panelUrl = "";
      formats = null;
    }
    currentVideo = v;

    if (!v) {
      if (hostEl && hostEl.isConnected) hostEl.remove();
      hostEl = null;
      shadow = null;
      btn = null;
      card = null;
      panelOpen = false;
      return;
    }

    ensureHost();
    const rect = v.getBoundingClientRect();
    positionButton(rect);
    positionPanel();
  }

  // --------------------------------------------------------------- download
  function startDownload() {
    if (busy) return;
    const picked = shadow.querySelector('input[name="vdq"]:checked');
    if (!picked) return;

    const url = panelUrl || pageUrl(currentVideo);
    if (!url) {
      setError("Could not determine this page's address.");
      return;
    }

    const value = picked.value;
    let payload;

    if (value.startsWith("a:")) {
      const id = value.slice(2);
      const convert = shadow.querySelector(".afmt").value;
      payload = {
        action: "download",
        url,
        mode: "audio",
        format_id: id,
        convert: convert || "",
      };
    } else {
      payload = {
        action: "download",
        url,
        mode: "video",
        height: Number(value.slice(2)) || 0,
        codec: codecSel === "auto" ? "" : codecSel,
      };
    }

    // Jobs carry the title/site/thumbnail so the bar panel can show a job card
    // without re-probing the network; the host fills in whatever is missing.
    const meta = formats || {};
    payload.embed_thumbnail = embedThumb;
    payload.embed_metadata = embedMeta;
    payload.title = String(meta.title || document.title || "").slice(0, 200);
    payload.site = String(meta.site || "");
    payload.thumb = String(meta.thumbnail || "");

    busy = true;
    const go = shadow.querySelector(".go");
    go.disabled = true;
    go.textContent = "Starting…";

    const done = (resp) => {
      busy = false;
      go.textContent = "Download";
      if (resp && resp.ok) {
        setNote("Queued — follow it in the Video Grabber bar panel");
        setTimeout(closePanel, 1400);
      } else {
        go.disabled = false;
        setNote((resp && resp.error) || "Could not start the download", true);
      }
    };

    try {
      chrome.runtime.sendMessage({ type: "videodl", payload }, (resp) => {
        if (chrome.runtime.lastError) {
          done({ ok: false, error: chrome.runtime.lastError.message });
          return;
        }
        done(resp);
      });
    } catch (err) {
      done({ ok: false, error: "Extension reloaded — refresh the page." });
    }
  }

  // ------------------------------------------------------------------ events
  function onPointerDown(e) {
    if (!panelOpen || !hostEl) return;
    const path = e.composedPath ? e.composedPath() : [];
    if (path.includes(hostEl)) return;
    closePanel();
  }

  function onKey(e) {
    if (e.key === "Escape" && panelOpen) closePanel();
  }

  document.addEventListener("pointerdown", onPointerDown, true);
  document.addEventListener("keydown", onKey, true);
  window.addEventListener("scroll", () => update(), { capture: true, passive: true });
  window.addEventListener("resize", () => update(), { passive: true });
  document.addEventListener("fullscreenchange", () => update());

  // Video elements come and go; re-scan cheaply instead of observing everything.
  const timer = setInterval(update, 400);
  window.addEventListener("pagehide", () => clearInterval(timer), { once: true });

  update();
})();
