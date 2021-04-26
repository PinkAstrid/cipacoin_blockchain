def string_to_bytes32(data):
    if len(data) > 32:
        b32 = data[:32]
    else:
        b32 = data.ljust(32, '0')
    return bytes(b32, 'utf-8')
