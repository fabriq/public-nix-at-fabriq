# Not putting any shebang here because this script is meant to either be sourced
# or passed to pkgs.writeShellApplication.

set -e

# This script prints to stdout all trusted certificates from the provided
# keychains.

keychains=("$@")

# Temporary directory to store certificates
DIR=$(/usr/bin/mktemp -d)

# Cleaning up the temporary directory on exit
function clear_tmp_dir() {
	/bin/rm -rf "$DIR"
}
trap clear_tmp_dir EXIT

# Listing all certificates in the provided keychain and turning each of them
# into a separate file.
/usr/bin/security find-certificate -a -p "${keychains[@]}" >"$DIR/all_certs"
number_of_begin_certificate=$(/usr/bin/grep -c '\-----BEGIN CERTIFICATE-----' "$DIR/all_certs")
number_of_certs=$((number_of_begin_certificate - 2))
/usr/bin/csplit -s -f "$DIR/cert-" -n 5 - '/-----BEGIN CERTIFICATE-----/' "{${number_of_certs}}" < "$DIR/all_certs"

# Building the keychain arguments for the verify-cert command.
keychain_args=()
for keychain in "${keychains[@]}"; do
	keychain_args+=("-k" "$keychain")
done

# Holds the filenames of verified certificates.
verified_certs=()

# For each certificate file, verify it and add it to the verified_certs array
while read -r file; do
	if /usr/bin/security verify-cert -q -C -l -L -R offline "${keychain_args[@]}" -c "$file"; then
		verified_certs+=("$file")
	fi
done < <(/usr/bin/find "$DIR" -type f -name 'cert-*')

# Print to stdout
/bin/cat "${verified_certs[@]}"
