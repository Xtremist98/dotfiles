<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Btrfs Assistant</title>
  <desc>A gear in the theme's orange holding a filesystem tree in the main color, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The gear; one hard shadow. -->
    <g fill="{{ icon_shadow }}" transform="translate(0 8)">
      <rect x="238" y="76" width="36" height="60" rx="12"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(45 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(90 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(135 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(180 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(225 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(270 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(315 256 256)"/>
      <circle cx="256" cy="256" r="150"/>
    </g>
    <g fill="{{ icon_orange }}">
      <rect x="238" y="76" width="36" height="60" rx="12"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(45 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(90 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(135 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(180 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(225 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(270 256 256)"/>
      <rect x="238" y="76" width="36" height="60" rx="12" transform="rotate(315 256 256)"/>
      <circle cx="256" cy="256" r="150"/>
    </g>
    <circle cx="256" cy="256" r="104" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The filesystem tree. -->
    <g stroke="{{ accent }}" stroke-width="8" stroke-linecap="round">
      <path d="M256 330V270M256 270L200 220M256 270L312 220M256 270V210"/>
    </g>
    <circle cx="256" cy="330" r="18" fill="{{ accent }}"/>
    <circle cx="200" cy="220" r="16" fill="{{ icon_paper }}"/>
    <circle cx="312" cy="220" r="16" fill="{{ icon_paper }}"/>
    <circle cx="256" cy="210" r="18" fill="{{ icon_mark }}"/>
  </g>
</svg>
