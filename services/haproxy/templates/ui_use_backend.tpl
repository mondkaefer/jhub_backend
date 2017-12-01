    use_backend __UI_ID__ if { hdr(X-Forwarded-Remote-User) -f /root/haproxy_server_mappings/__MAPPING_FILE__ }
