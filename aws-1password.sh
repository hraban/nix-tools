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

# Poor man’s aws-vault-for-1password. I was tired of waiting for
# "https://github.com/99designs/aws-vault/issues/404".

# Usage:
#
#     aws-1password.sh [-n] [--account foobar.1password.com] "op://My Vault/some item" -- aws-or-some-other-command ...
#
# The op:// link must be the prefix to an item in your 1password which contains
# the access key id and secret as two separate items by the names:
#
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY


set -euo pipefail
${DEBUGSH+set -x}

declare -a opargs
allargs=("$@")
n=0
session=true
for val in "${allargs[@]}"; do
	if [[ "$val" == "--" ]]; then
		break
	fi
	n=$((n+1))
	if [[ "$val" == "-n" || "$val" == "--no-session" ]]; then
		session=false
		continue
	fi
	opargs+=("$val")
done
if [[ "$#" -eq "$n" ]]; then
	>&2 echo "Missing required argument: --"
	exit 1
fi

base="${opargs[-1]}"
unset "opargs[-1]"
argv=("${allargs[@]:$((n+1))}")

AWS_ACCESS_KEY_ID="$(op "${opargs[@]}" read "${base}/AWS_ACCESS_KEY_ID")"
AWS_SECRET_ACCESS_KEY="$(op "${opargs[@]}" read "${base}/AWS_SECRET_ACCESS_KEY")"

if $session; then
	sts="$(AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" aws sts get-session-token --output text)"

	# Have to do 2-step to ensure set -e picks up child process
	AWS_ACCESS_KEY_ID="$(<<<"$sts" cut -f 2)"
	AWS_CREDENTIAL_EXPIRATION="$(<<<"$sts" cut -f 3)"
	AWS_SECRET_ACCESS_KEY="$(<<<"$sts" cut -f 4)"
	AWS_SESSION_TOKEN="$(<<<"$sts" cut -f 5)"
	export AWS_CREDENTIAL_EXPIRATION
	export AWS_SESSION_TOKEN
fi

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

exec "${argv[@]}"
