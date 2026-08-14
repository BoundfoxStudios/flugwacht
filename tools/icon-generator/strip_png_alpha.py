import struct
import sys
import zlib

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


def paeth_predictor(left, above, upper_left):
    estimate = left + above - upper_left
    distance_left = abs(estimate - left)
    distance_above = abs(estimate - above)
    distance_upper_left = abs(estimate - upper_left)
    if distance_left <= distance_above and distance_left <= distance_upper_left:
        return left
    if distance_above <= distance_upper_left:
        return above
    return upper_left


def read_chunks(data):
    offset = len(PNG_SIGNATURE)
    while offset < len(data):
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        chunk_type = data[offset + 4:offset + 8]
        chunk_data = data[offset + 8:offset + 8 + length]
        yield chunk_type, chunk_data
        offset += 12 + length


def unfilter_rows(decompressed, width, height, bytes_per_pixel):
    stride = width * bytes_per_pixel
    previous_row = bytearray(stride)
    rows = []
    for row_index in range(height):
        start = row_index * (stride + 1)
        filter_type = decompressed[start]
        row = bytearray(decompressed[start + 1:start + 1 + stride])
        if filter_type == 1:
            for index in range(bytes_per_pixel, stride):
                row[index] = (row[index] + row[index - bytes_per_pixel]) & 0xff
        elif filter_type == 2:
            for index in range(stride):
                row[index] = (row[index] + previous_row[index]) & 0xff
        elif filter_type == 3:
            for index in range(stride):
                left = row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
                row[index] = (row[index] + (left + previous_row[index]) // 2) & 0xff
        elif filter_type == 4:
            for index in range(stride):
                left = row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
                upper_left = previous_row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
                row[index] = (row[index] + paeth_predictor(left, previous_row[index], upper_left)) & 0xff
        elif filter_type != 0:
            raise ValueError(f'unsupported PNG filter type {filter_type}')
        rows.append(row)
        previous_row = row
    return rows


def write_chunk(handle, chunk_type, chunk_data):
    handle.write(struct.pack('>I', len(chunk_data)))
    handle.write(chunk_type)
    handle.write(chunk_data)
    handle.write(struct.pack('>I', zlib.crc32(chunk_type + chunk_data) & 0xffffffff))


def strip_alpha(path):
    with open(path, 'rb') as handle:
        data = handle.read()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f'{path} is not a PNG file')

    header = None
    compressed = bytearray()
    for chunk_type, chunk_data in read_chunks(data):
        if chunk_type == b'IHDR':
            header = struct.unpack('>IIBBBBB', chunk_data)
        elif chunk_type == b'IDAT':
            compressed.extend(chunk_data)

    width, height, bit_depth, color_type, _, _, interlace = header
    if color_type == 2:
        return
    if bit_depth != 8 or color_type != 6 or interlace != 0:
        raise ValueError(f'{path}: only 8-bit non-interlaced RGBA is supported')

    rows = unfilter_rows(zlib.decompress(bytes(compressed)), width, height, 4)
    output_scanlines = bytearray()
    for row in rows:
        alpha_values = row[3::4]
        if alpha_values.count(255) != len(alpha_values):
            raise ValueError(f'{path} contains transparent pixels; refusing to strip its alpha channel')
        output_scanlines.append(0)
        for pixel_start in range(0, len(row), 4):
            output_scanlines.extend(row[pixel_start:pixel_start + 3])

    with open(path, 'wb') as handle:
        handle.write(PNG_SIGNATURE)
        write_chunk(handle, b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
        write_chunk(handle, b'IDAT', zlib.compress(bytes(output_scanlines), 9))
        write_chunk(handle, b'IEND', b'')


if __name__ == '__main__':
    for argument in sys.argv[1:]:
        strip_alpha(argument)
