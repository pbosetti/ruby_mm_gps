#include "mm_gps.h"

typedef unsigned char uchar;

typedef union { 
  ushort w;
  struct{
    uchar lo;
    uchar hi; 
  } b;
  uchar bs[2]; 
} Bytes;

static ushort MMGPS_CRC16(const void *buf, ushort length) {
  uchar *arr = (uchar *)buf; 
  Bytes crc;
  crc.w = 0xffff;
  while(length--){ 
    char i;
    ushort odd;
    crc.b.lo ^= *arr++; 
    for(i = 0; i< 8; i++){
      odd = crc.w& 0x01; 
      crc.w >>= 1;
      if(odd)
      crc.w ^= 0xa001;
    }
  } 
  return (ushort)crc.w;
  
}

VALUE rb_mMmGps;

void
Init_mm_gps(void)
{
  rb_mMmGps = rb_define_module("MmGps");
}
