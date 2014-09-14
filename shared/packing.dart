library web_play_packing;

/**
 * Encode an integer as a 48-bit little-endian value.
 */
List<int> encodeInteger(int i) {
  return [i & 0xff, (i >> 8) & 0xff, (i >> 16) & 0xff, (i >> 24) & 0xff,
          (i >> 32) & 0xff, (i >> 40) & 0xff];
}

/**
 * Decode an integer from a 48-bit little-endian value.
 */
int decodeInteger(List<int> data) {
  return data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24) |
      (data[4] << 32) | (data[5] << 40);
}

List<int> buildPacket(int command, int intField, List<int> data) {
  assert(command >= 0 && command < 0xff);
  List<int> result = [command];
  result.addAll(encodeInteger(intField));
  result.addAll(data);
  return result;
}
