<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>qBittorrent</title>
  <desc>A magnet in the main color with pale pole tips and a pale download arrow inside it, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The magnet; one hard shadow. -->
    <path d="M160 120V260A96 96 0 0 0 352 260V120" fill="none" stroke="{{ icon_shadow }}" stroke-width="56" stroke-linecap="round" transform="translate(0 8)"/>
    <path d="M160 120V260A96 96 0 0 0 352 260V120" fill="none" stroke="url(#main)" stroke-width="56" stroke-linecap="round"/>
    <!-- The pole tips. -->
    <rect x="132" y="96" width="56" height="52" rx="8" fill="{{ icon_paper }}"/>
    <rect x="324" y="96" width="56" height="52" rx="8" fill="{{ icon_paper }}"/>
    <rect x="148" y="112" width="24" height="20" rx="4" fill="{{ icon_red }}"/>
    <rect x="340" y="112" width="24" height="20" rx="4" fill="{{ icon_red }}"/>
    <!-- The download arrow inside the magnet. -->
    <g transform="translate(0 8)" fill="{{ icon_shadow }}" opacity=".35">
      <rect x="240" y="200" width="32" height="82" rx="8"/>
      <path d="M208 280L256 340L304 280Z"/>
    </g>
    <rect x="240" y="200" width="32" height="82" rx="8" fill="{{ icon_paper }}"/>
    <path d="M208 280L256 340L304 280Z" fill="{{ icon_paper }}"/>
  </g>
</svg>
