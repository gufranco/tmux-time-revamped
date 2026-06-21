#!/usr/bin/env bash
#
# geoip.sh: resolve the current city from the public IP address.
#
# The parse is pure. The HTTP request lives behind a seam and only runs inside the
# cache's background worker, so a slow or unreachable endpoint never blocks the
# status render. This is opt-in: it sends the public IP to an external service.

[[ -n "${_TIME_REVAMPED_GEOIP_LOADED:-}" ]] && return 0
_TIME_REVAMPED_GEOIP_LOADED=1

# Seconds before the HTTP request is abandoned.
GEOIP_TIMEOUT="${GEOIP_TIMEOUT:-3}"

# Longest city string accepted, to reject error pages and junk.
GEOIP_MAX_CITY_LEN=64

# Host-probe seam. Tests override this.
_read_geoip() {
  curl -fsS --max-time "${GEOIP_TIMEOUT}" "${1}" 2>/dev/null
}

# geoip_parse_city BODY -> the city name from a response, empty when none.
# Handles a JSON body carrying "city":"X" and a plain-text body that is the bare
# city. Rejects empty, HTML-looking, or over-long values.
geoip_parse_city() {
  local body="${1}" city
  case "${body}" in
    *'"city"'*)
      city=$(printf '%s' "${body}" | sed -n 's/.*"city"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
      ;;
    *)
      city=$(printf '%s' "${body}" | head -n1 | tr -d '\r')
      ;;
  esac
  case "${city}" in
    "" | *"<"* | *">"* | *"{"*) echo "" ;;
    *) [[ "${#city}" -le "${GEOIP_MAX_CITY_LEN}" ]] && printf '%s' "${city}" || echo "" ;;
  esac
}

export -f _read_geoip
export -f geoip_parse_city
