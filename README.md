# Cloudflare Infrastructure Manager & Importer

An automated toolkit to export existing Cloudflare zones and DNS records, structure them into a clean modular directory layout, and automatically generate the corresponding Terraform `import` blocks. 

Designed to simplify migrating manual Cloudflare setups into infrastructure-as-code (IaC) using Terraform.

---

## Features

* **Automated Discovery:** Automatically fetches all Cloudflare zones associated with your account.
* **Modular Code Generation:** Generates individual `dns_<domain>.tf` files for each zone inside a dedicated `domains/` folder.
* **Automated Import Blocks:** Generates companion `import_zones.tf` and `import_dns_<domain>.tf` files to instantly bind existing real-world resources to Terraform states.

---

## Prerequisites & Installation

You will need `terraform` and Cloudflare's `cf-terraforming` utility installed on your system.

### For Nix Users (NixOS / Nix Shell)
If you are on Nix, you can quickly spin up an environment with the required tooling:
```bash
nix-shell
```

### For Other Systems
Installation of `cf-terraforming` and `terraform` is on your own. Please refer to their respective installation guides:
* [Cloudflare cf-terraforming Documentation](https://github.com/cloudflare/cf-terraforming)
* [Terraform Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

---

## Configuration

1. Create a local environment file named `.env.local`:
   ```bash
   touch .env.local
   ```
2. Add your Cloudflare credentials to `.env.local`:
   ```env
   CLOUDFLARE_API_TOKEN="your_cloudflare_api_token"
   CLOUDFLARE_ACCOUNT_ID="your_cloudflare_account_id"
   ```

---

## Usage

1. **Make the export script executable:**
   ```bash
   chmod +x exportZones.sh
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Run the script:**
   ```bash
   ./exportZones.sh
   ```
   *This generates `zones.tf`, `import_zones.tf`, and populates the `domains/` directory with individual domain records and import files.*

4. **Review the Plan:**
   ```bash
   terraform plan -out "plan.tfplan"
   ```

5. **Apply the Import:**
   ```bash
   terraform apply "plan.tfplan"
   ```

---

## Project Structure

```text
.
├── .env.local             # Local API tokens (git ignored)
├── exportZones.sh         # Main export and import-generator script
├── zones.tf               # Generated cloudflare_zone resources
├── import_zones.tf        # Generated import blocks for zones
└── domains/               # Directory containing domain records & imports
    ├── dns_*.tf           # Cloudflare DNS records per domain
    └── import_dns_*.tf    # Import blocks for corresponding DNS records
```

---

## License

This project is open-source and available under the [MIT License](LICENSE).
