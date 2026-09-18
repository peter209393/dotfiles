function myip --description "Show local and public IP addresses"
    echo "Local IPs:"
    hostname -I 2>/dev/null || ip addr show 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1

    echo -e "\nPublic IP:"
    curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to fetch public IP"
end
