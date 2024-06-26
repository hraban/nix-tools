#!/usr/bin/env bash

# Copyright © 2024  Hraban Luyat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -euo pipefail
${DEBUGSH+set -x}

d=/nix/var/nix/gcroots/rotating
expiry_days=30
db=/nix/var/nix/db/db.sqlite

dryrun=
if [[ "${1-}" == --dry-run ]]; then
	dryrun="echo"
fi

$dryrun mkdir -p "$d"
$dryrun cd "$d"

expiry_secs=$((60 * 60 * 24 * expiry_days))
# Keep
sqlite3 "$db" <<SQL | while read -r f; do if [[ ! -e "${f##*/}" ]]; then $dryrun ln -fs "$f"; fi; done
select path
from validpaths
where registrationTime > (unixepoch() - $expiry_secs)
and path not like '%.drv'
SQL

# Discard
# yes race condition but it doesnt matter at all
sqlite3 "$db" <<SQL | xargs -r -n 1 basename | xargs -r $dryrun rm -f
select path
from validpaths
where registrationTime < (unixepoch() - $expiry_secs)
and path not like '%.drv'
SQL

$dryrun nix-collect-garbage --delete-older-than "${expiry_days}d"
