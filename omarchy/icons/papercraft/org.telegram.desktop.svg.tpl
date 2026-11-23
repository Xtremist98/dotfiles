<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>Telegram</title>
  <desc>A chat bubble seen from the front: a dark bubble with a tail and a paper plane in the main color, the plane with a fold line, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The tail; one hard shadow. -->
    <path d="M128 392L104 448L184 408Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M128 392L104 448L184 408Z" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3" stroke-linejoin="round"/>
    <!-- The bubble; one hard shadow, as Hype's slides. -->
    <rect x="88" y="88" width="336" height="336" rx="64" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <rect x="88" y="88" width="336" height="336" rx="64" fill="{{ icon_body }}" stroke="{{ icon_edge }}" stroke-width="3"/>
    <!-- The plane. -->
    <path d="M136 256L392 176L304 360L256 280Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M136 256L392 176L304 360L256 280Z" fill="url(#main)"/>
    <path d="M136 256L256 280L304 360Z" fill="{{ icon_shadow }}" opacity=".28"/>
    <path d="M136 256L256 280L392 176" fill="none" stroke="{{ icon_paper }}" stroke-width="4" opacity=".4"/>
  </g>
</svg>
