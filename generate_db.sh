#!/bin/bash

# -----------------------------------------------------------------------------
# GeoIP2Fast Database Generator Helper Script
# -----------------------------------------------------------------------------
# This script simplifies the process of generating the binary database file (.dat.gz)
# required by fgeoip2fast. It provides an interactive menu to:
# 1. Download the latest GeoLite2 CSV files from MaxMind (requires credentials).
# 2. Convert the CSV files into the optimized format used by this library.
#
# The generated database will support:
# - IPv4 and IPv6 lookups
# - City-level details (including Latitude/Longitude)
# - ASN (Autonomous System Number) information
#
# Usage (Interactive):
#   ./generate_db.sh
#
# Usage (CLI):
#   ./generate_db.sh <path_to_city_csv_dir> <path_to_asn_csv_dir> [optional_args]
# -----------------------------------------------------------------------------

# Function to print section headers
print_header() {
    echo "================================================================================"
    echo "$1"
    echo "================================================================================"
}

# Function to check for required tools
check_dependencies() {
    local missing=0
    for tool in curl unzip python; do
        if ! command -v $tool &> /dev/null; then
            echo "Error: '$tool' is not installed or not in PATH."
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo "Please install missing dependencies (curl, unzip, python) and try again."
        exit 1
    fi
}

# Function to download files
download_files() {
    print_header "Download MaxMind GeoLite2 CSV Files"
    
    if [ -z "$MAXMIND_ACCOUNT_ID" ]; then
        read -p "Enter MaxMind Account ID: " MAXMIND_ACCOUNT_ID
    fi
    if [ -z "$MAXMIND_LICENSE_KEY" ]; then
        read -s -p "Enter MaxMind License Key: " MAXMIND_LICENSE_KEY
        echo ""
    fi

    if [ -z "$MAXMIND_ACCOUNT_ID" ] || [ -z "$MAXMIND_LICENSE_KEY" ]; then
        echo "Error: Account ID and License Key are required."
        return 1
    fi

    DOWNLOAD_DIR="maxmind_downloads"
    mkdir -p "$DOWNLOAD_DIR"
    
    # Save current directory
    pushd "$DOWNLOAD_DIR" > /dev/null
    
    echo "Downloading GeoLite2-City-CSV..."
    curl -O -J -L -u "$MAXMIND_ACCOUNT_ID:$MAXMIND_LICENSE_KEY" \
        "https://download.maxmind.com/geoip/databases/GeoLite2-City-CSV/download?suffix=zip"
        
    echo "Downloading GeoLite2-ASN-CSV..."
    curl -O -J -L -u "$MAXMIND_ACCOUNT_ID:$MAXMIND_LICENSE_KEY" \
        "https://download.maxmind.com/geoip/databases/GeoLite2-ASN-CSV/download?suffix=zip"
    
    echo "Extracting files..."
    unzip -o "*.zip"
    
    # Find the extracted directories (handling versioned folder names)
    # We look for directories starting with the expected prefix
    CITY_DIR_NAME=$(find . -maxdepth 1 -type d -name "GeoLite2-City-CSV_*" | head -n 1)
    ASN_DIR_NAME=$(find . -maxdepth 1 -type d -name "GeoLite2-ASN-CSV_*" | head -n 1)
    
    # Convert to absolute paths
    if [ -n "$CITY_DIR_NAME" ]; then
        CITY_DIR="$(pwd)/$CITY_DIR_NAME"
    fi
    if [ -n "$ASN_DIR_NAME" ]; then
        ASN_DIR="$(pwd)/$ASN_DIR_NAME"
    fi
    
    # Restore directory
    popd > /dev/null
    
    if [ -z "$CITY_DIR" ] || [ -z "$ASN_DIR" ]; then
        echo "Error: Could not locate extracted directories."
        return 1
    fi

    echo "Download and extraction complete."
    echo "City Dir: $CITY_DIR"
    echo "ASN Dir:  $ASN_DIR"
}

# Function to convert files
convert_files() {
    print_header "Convert CSV to .dat.gz"
    
    # Ask for the base directory where the user extracted the files
    read -e -p "Enter directory containing extracted folders (default: ./maxmind_downloads): " BASE_DIR
    BASE_DIR="${BASE_DIR:-./maxmind_downloads}"
    
    # Remove quotes if user added them
    BASE_DIR="${BASE_DIR%\"}"
    BASE_DIR="${BASE_DIR#\"}"

    if [ ! -d "$BASE_DIR" ]; then
        echo "Error: Directory does not exist: $BASE_DIR"
        return 1
    fi

    # --- Select City Directory ---
    echo "--------------------------------------------------------------------------------"
    echo "Searching for GeoLite2-City-CSV directories in: $BASE_DIR"
    
    # Find directories safely handling spaces
    IFS=$'\n' CITY_OPTIONS=($(find "$BASE_DIR" -maxdepth 2 -type d -name "GeoLite2-City-CSV_*"))
    unset IFS

    if [ ${#CITY_OPTIONS[@]} -eq 0 ]; then
        echo "No City directories found automatically."
        read -e -p "Enter full path to GeoLite2-City-CSV directory: " CITY_DIR
    elif [ ${#CITY_OPTIONS[@]} -eq 1 ]; then
        CITY_DIR="${CITY_OPTIONS[0]}"
        echo "Found: $CITY_DIR"
        read -p "Use this directory? [Y/n] " CONFIRM
        CONFIRM=${CONFIRM:-Y}
        if [[ "$CONFIRM" =~ ^[Nn] ]]; then
             read -e -p "Enter full path to GeoLite2-City-CSV directory: " CITY_DIR
        fi
    else
        echo "Multiple directories found:"
        for i in "${!CITY_OPTIONS[@]}"; do
            echo "$((i+1))) ${CITY_OPTIONS[$i]}"
        done
        read -p "Select directory [1-${#CITY_OPTIONS[@]}]: " SELECTION
        if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "${#CITY_OPTIONS[@]}" ]; then
            CITY_DIR="${CITY_OPTIONS[$((SELECTION-1))]}"
        else
            echo "Invalid selection."
            return 1
        fi
    fi

    # --- Select ASN Directory ---
    echo "--------------------------------------------------------------------------------"
    echo "Searching for GeoLite2-ASN-CSV directories in: $BASE_DIR"
    
    IFS=$'\n' ASN_OPTIONS=($(find "$BASE_DIR" -maxdepth 2 -type d -name "GeoLite2-ASN-CSV_*"))
    unset IFS

    if [ ${#ASN_OPTIONS[@]} -eq 0 ]; then
        echo "No ASN directories found automatically."
        read -e -p "Enter full path to GeoLite2-ASN-CSV directory: " ASN_DIR
    elif [ ${#ASN_OPTIONS[@]} -eq 1 ]; then
        ASN_DIR="${ASN_OPTIONS[0]}"
        echo "Found: $ASN_DIR"
        read -p "Use this directory? [Y/n] " CONFIRM
        CONFIRM=${CONFIRM:-Y}
        if [[ "$CONFIRM" =~ ^[Nn] ]]; then
             read -e -p "Enter full path to GeoLite2-ASN-CSV directory: " ASN_DIR
        fi
    else
        echo "Multiple directories found:"
        for i in "${!ASN_OPTIONS[@]}"; do
            echo "$((i+1))) ${ASN_OPTIONS[$i]}"
        done
        read -p "Select directory [1-${#ASN_OPTIONS[@]}]: " SELECTION
        if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le "${#ASN_OPTIONS[@]}" ]; then
            ASN_DIR="${ASN_OPTIONS[$((SELECTION-1))]}"
        else
            echo "Invalid selection."
            return 1
        fi
    fi

    # Final Validation
    # Remove quotes if user added them manually in the fallback prompts
    CITY_DIR="${CITY_DIR%\"}"
    CITY_DIR="${CITY_DIR#\"}"
    ASN_DIR="${ASN_DIR%\"}"
    ASN_DIR="${ASN_DIR#\"}"

    if [ ! -d "$CITY_DIR" ] || [ ! -d "$ASN_DIR" ]; then
        echo "Error: Invalid directories selected."
        return 1
    fi

    echo "--------------------------------------------------------------------------------"
    echo "Selected City Dir: $CITY_DIR"
    echo "Selected ASN Dir:  $ASN_DIR"
    echo "--------------------------------------------------------------------------------"
    echo "Running conversion..."
    
    # Run the python module
    python -m geoip2fast.geoip2dat --city-dir "$CITY_DIR" --asn-dir "$ASN_DIR" --with-ipv6 --output-dir .
}

# Main Logic
check_dependencies

# Check if arguments are provided (CLI mode)
if [ "$#" -ge 2 ]; then
    CITY_DIR="$1"
    ASN_DIR="$2"
    shift 2
    python -m geoip2fast.geoip2dat --city-dir "$CITY_DIR" --asn-dir "$ASN_DIR" --with-ipv6 --output-dir . "$@"
    exit $?
fi

# Interactive Menu
print_header "GeoIP2Fast Database Manager"
echo "1) Download GeoLite2 CSV files from MaxMind"
echo "2) Convert existing CSV files to .dat.gz"
echo "3) Download and Convert (All-in-one)"
echo "4) Exit"
echo ""
read -p "Select an option [1-4]: " OPTION

case $OPTION in
    1)
        download_files
        ;;
    2)
        convert_files
        ;;
    3)
        download_files
        if [ $? -eq 0 ]; then
            convert_files
        fi
        ;;
    4)
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac
