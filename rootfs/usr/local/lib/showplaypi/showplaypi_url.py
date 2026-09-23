"""URL handling shared by the ShowPlayPI services.

normalize_url() turns any URL a user may enter – in showplaypi.ini, in the configurator or via OSC –
into plain ASCII, so that Chromium, the watchdog (curl) and the idle service all see the same address:

  http://müller.de/über uns?q=größe  ->  http://xn--mller-kva.de/%C3%BCber%20uns?q=gr%C3%B6%C3%9Fe

- host names are converted to IDNA ("punycode")
- non-ASCII characters and spaces in path, query and fragment are percent-encoded (UTF-8)
- existing %XX escapes are kept, so already encoded URLs are not encoded twice
"""

from urllib.parse import quote, urlsplit, urlunsplit

try:
    # IDNA 2008 / UTS 46 like Chromium: "straße.de" -> "xn--strae-oqa.de"
    import idna as _idna
except ImportError:  # pragma: no cover – python3-idna is part of the image
    _idna = None

SCHEMES = ("http", "https", "file")

# Characters that may stay as they are in path, query and fragment (RFC 3986 pchar + "/" + "?"),
# plus "%" so existing escapes are not encoded again.
_SAFE = "/?:@!$&'()*+,;=-._~%"


def decode_text(data):
    """Bytes from OSC, the INI file or the command line: UTF-8, else Latin-1/Windows-1252."""
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        try:
            return data.decode("cp1252")
        except UnicodeDecodeError:
            return data.decode("latin-1")


def _idna_host(host):
    if not host or host.startswith("[") or host.isascii():
        return host
    if _idna is not None:
        try:
            return _idna.encode(host, uts46=True, transitional=False).decode("ascii")
        except _idna.IDNAError as error:
            raise UnicodeError(str(error))
    # Fallback (IDNA 2003 – differs from browsers for e.g. "ß")
    labels = []
    for label in host.split("."):
        labels.append(label.encode("idna").decode("ascii") if label and not label.isascii() else label)
    return ".".join(labels)


def normalize_url(url):
    """Return the ASCII form of url, or raise ValueError if it is not an http, https or file URL."""
    url = url.strip()
    parts = urlsplit(url)
    scheme = parts.scheme.lower()

    if scheme not in SCHEMES:
        raise ValueError("URL must begin with http://, https:// or file://")

    netloc = parts.netloc
    if scheme in ("http", "https"):
        if not parts.hostname:
            raise ValueError("The URL does not contain a host name")
        userinfo, _, hostport = netloc.rpartition("@")
        if hostport.startswith("["):
            host, port = hostport, ""
        else:
            host, _, port = hostport.partition(":")
        try:
            host = _idna_host(host)
        except UnicodeError:
            raise ValueError("The host name is not valid")
        netloc = host + (":" + port if port else "")
        if userinfo:
            netloc = quote(userinfo, safe=":%!$&'()*+,;=-._~") + "@" + netloc

    return urlunsplit((
        scheme,
        netloc,
        quote(parts.path, safe=_SAFE),
        quote(parts.query, safe=_SAFE),
        quote(parts.fragment, safe=_SAFE),
    ))
