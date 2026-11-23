<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <title>iloader</title>
  <desc>A green corner bracket around a pale download arrow dropping into a small box, each piece with a hard shadow.</desc>
  <defs>
    <linearGradient id="main" x1="0" y1="0" x2="1" y2="1">
      <stop stop-color="{{ accent }}"/>
      <stop offset="1" stop-color="{{ accent }}"/>
    </linearGradient>
  </defs>
  <g transform="translate(256 256) scale(1.2) translate(-256 -256)">
    <!-- The corner bracket; one hard shadow. -->
    <path d="M96 96H224V144H144V368H416V416H96Z" fill="{{ icon_shadow }}" transform="translate(0 8)"/>
    <path d="M96 96H224V144H144V368H416V416H96Z" fill="url(#main)"/>
    <!-- The arrow, raised off the bracket. -->
    <g transform="translate(0 8)" fill="{{ icon_shadow }}" opacity=".35">
      <rect x="240" y="128" width="32" height="104" rx="8"/>
      <path d="M196 232L256 304L316 232Z"/>
    </g>
    <rect x="240" y="128" width="32" height="104" rx="8" fill="{{ icon_paper }}"/>
    <path d="M196 232L256 304L316 232Z" fill="{{ icon_paper }}"/>
    <!-- The package waiting below. -->
    <rect x="216" y="320" width="80" height="40" rx="10" fill="{{ icon_shadow }}" transform="translate(0 6)"/>
    <rect x="216" y="320" width="80" height="40" rx="10" fill="{{ icon_mark }}"/>
  </g>
</svg>
