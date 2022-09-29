#include <iostream>
using namespace std;

int main() {
  for (long long x = 0; x < 1LL << 32; x++) {
    long long a = ((((x & 0xffff00) >> 0x08) << 0x07) + 0x0d) * 0x02;
    long long b = ((x >> 0x18) & 0xff) * 0x0101;
    long long c = ((x & 0xff) * 0x02) & 0xff;
    if ((a ^ b) == 0 && c > 0xf0) {
      cout << x << " " << a << " " << b << " " << c << endl;
      break;
    }
  }
  return 0;
}