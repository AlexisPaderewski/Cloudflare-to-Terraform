#!/bin/sh

if [ -f ".env.local" ]; then
    CLOUDFLARE_API_TOKEN=$(grep -E '^CLOUDFLARE_API_TOKEN=' .env.local | cut -d '=' -f 2- | tr -d '"' | tr -d "'")
    CLOUDFLARE_ACCOUNT_ID=$(grep -E '^CLOUDFLARE_ACCOUNT_ID=' .env.local | cut -d '=' -f 2- | tr -d '"' | tr -d "'")
    echo "Loaded API token from .env.local"
fi

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "ERROR: CLOUDFLARE_API_TOKEN is missing from .env.local and environment." >&2
    exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    echo "ERROR: CLOUDFLARE_ACCOUNT_ID is missing from .env.local and environment." >&2
    exit 1
fi

export CLOUDFLARE_API_TOKEN
export CLOUDFLARE_ACCOUNT_ID

# Ensure the domains directory exists
mkdir -p domains

echo "1. Generating zones file..."
cf-terraforming generate --resource-type cloudflare_zone > zones.tf

echo "1.1. Generating root-level zone imports..."
awk '
    /resource "cloudflare_zone"/ {
        if (match($0, /terraform_managed_resource_[a-f0-9]{32}_[0-9]+/)) {
            resource_name = substr($0, RSTART, RLENGTH)
            token = substr($0, RSTART + 27, RLENGTH - 27)
            split(token, parts, "_")
            zone_id = parts[1]

            print "import {"
            print "  to = cloudflare_zone." resource_name
            print "  id = \"" zone_id "\""
            print "}"
            print ""
        }
    }
' "zones.tf" > "import_zones.tf"

echo "2. Processing zones and exporting DNS records to domains/ directory..."

awk '
  /resource "cloudflare_zone"/ {
    if (match($0, /terraform_managed_resource_[a-f0-9]+/)) {
      id = substr($0, RSTART + 27, RLENGTH - 27)
    }
  }
  /^[ \t]*zone[ \t]*=/ {
    if (match($0, /"[^"]+"/)) {
      domain = substr($0, RSTART + 1, RLENGTH - 2)
    }
    if (id != "" && domain != "") {
      print id "|" domain
      id = ""
      domain = ""
    }
  }
' "zones.tf" | while IFS='|' read -r zone_id domain_name; do
    if [ -n "$zone_id" ] && [ -n "$domain_name" ]; then
        DNS_FILE="domains/dns_${domain_name}.tf"
        IMPORTS_FILE="domains/import_dns_${domain_name}.tf"

        echo "Exporting DNS for: $domain_name -> $DNS_FILE"
        CLOUDFLARE_ACCOUNT_ID="" cf-terraforming generate --resource-type cloudflare_record --zone "$zone_id" > "$DNS_FILE"

        echo "Calculating imports for $domain_name (Zone ID: $zone_id)"
        awk -v zid="$zone_id" '
            /resource "cloudflare_record"/ {
                if (match($0, /terraform_managed_resource_[a-f0-9]{32}_[0-9]+/)) {
                  resource_name = substr($0, RSTART, RLENGTH)
                  token = substr($0, RSTART + 27, RLENGTH - 27)
                  split(token, parts, "_")
                  rec_id = parts[1]

                  print "import {"
                  print "  to = cloudflare_record." resource_name
                  print "  id = \"" zid "/" rec_id "\""
                  print "}"
                  print ""
                }
            }
        ' "$DNS_FILE" > "$IMPORTS_FILE"
    fi
done

echo "Done! Zones and files in domains/ are ready."
