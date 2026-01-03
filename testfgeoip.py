"""
testfgeoip.py

This script tests the functionality of the GeoIP2Fast library.
It initializes the GeoIP2Fast object and performs IP lookups.
It can be run with specific IP addresses as arguments or without arguments to run a default set of tests.

Usage:
    python testfgeoip.py [IP_ADDRESS_1] [IP_ADDRESS_2] ...
    python testfgeoip.py
"""
from geoip2fast.geoip2fast import GeoIP2Fast
import sys
import os

def test_functionality(ips=None):
    print("Initializing GeoIP2Fast...")
    try:
        # Try to load city database if available
        city_db = "geoip2fast-city.dat.gz"
        if os.path.exists(os.path.join("geoip2fast", city_db)):
             print(f"Loading {city_db}...")
             geoip = GeoIP2Fast(verbose=True, geoip2fast_data_file=os.path.join("geoip2fast", city_db))
        else:
             print("Loading default database...")
             geoip = GeoIP2Fast(verbose=True)
    except Exception as e:
        print(f"Failed to initialize: {e}")
        return

    print("\nTesting IP Lookups:")
    if ips:
        ips_to_test = ips
    else:
        ips_to_test = [
            '8.8.8.8',          # Google DNS (US)
            '1.1.1.1',          # Cloudflare DNS
            '200.204.0.10',     # Brazil IP
            '127.0.0.1',        # Localhost
            '10.0.0.1',         # Private
            'invalid_ip'        # Invalid
        ]

    for ip in ips_to_test:
        print(f"\nLookup for {ip}:")
        try:
            result = geoip.lookup(ip)
            print(f"  Country Code: {result.country_code}")
            print(f"  Country Name: {result.country_name}")
            print(f"  CIDR: {result.cidr}")
            print(f"  Is Private: {result.is_private}")
            
            # Check if city data is available
            if hasattr(result, 'city') and result.city:
                 if hasattr(result.city, 'name') and result.city.name and result.city.name != "||||":
                     print(f"  City: {result.city.name}")
                     print(f"  City Details: {result.city.to_dict()}")
                 else:
                     print(f"  City: N/A")

        except Exception as e:
            print(f"  Error during lookup: {e}")

    print("\nTesting Metadata:")
    try:
        if hasattr(geoip, 'get_database_info'):
            info = geoip.get_database_info()
            print(f"  Database Info: {info}")
        else:
            print("  get_database_info method not found.")
    except Exception as e:
        print(f"  Error getting info: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        test_functionality(sys.argv[1:])
    else:
        test_functionality()
