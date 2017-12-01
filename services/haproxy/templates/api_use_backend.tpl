    use_backend __API_ID__ if { hdr(X-Forwarded-Remote-User) -f /root/haproxy_server_mappings/__MAPPING_FILE__ } or { hdr(Use-API) __API_ID__ }
