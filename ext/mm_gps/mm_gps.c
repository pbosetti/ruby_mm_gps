#include "mm_gps.h"

typedef unsigned char uchar;

typedef union { 
  ushort w;
  struct{
    uchar lo;
    uchar hi; 
  } b;
  uchar bs[2]; 
} bytes_t;

static ushort CRC16(const void *buf, ushort length) {
  uchar *arr = (uchar *)buf; 
  bytes_t crc;
  crc.w = 0xffff;
  while(length--) { 
    char i;
    ushort odd;
    crc.b.lo ^= *arr++; 
    for(i = 0; i< 8; i++) {
      odd = crc.w& 0x01; 
      crc.w >>= 1;
      if(odd)
        crc.w ^= 0xa001;
    }
  } 
  return (ushort)crc.w;
}

/* @overload crc16(buf)
 *   Calculate CRC16 checksum of a string
 *   
 *   @param buf [String] the string to be checksummed
 *   @return [Fixnum] the CRC16 value
 */
static VALUE mm_gps_CRC16(VALUE klass, VALUE str)
{
  Check_Type(str, T_STRING);
  return rb_fix_new(CRC16(RSTRING_PTR(str), RSTRING_LEN(str)));
}

/* @overload append_crc16(buf)
 *   Appends a CRC16 checksum to a string
 *   
 *   @param buf [String] the starting string
 *   @return [String] the original string plus its CRC16
 */
static VALUE mm_gps_add_CRC16(VALUE klass, VALUE str)
{
  union {
    ushort u;
    char   s[2];
  } crc;
  
  Check_Type(str, T_STRING);
  crc.u = CRC16(RSTRING_PTR(str), RSTRING_LEN(str));  
  return rb_str_buf_cat(str, crc.s, 2);
}


VALUE rb_mMmGPS;

void
Init_mm_gps(void)
{
  rb_mMmGPS = rb_define_module("MmGPS");
  rb_define_singleton_method(rb_mMmGPS, "crc16", mm_gps_CRC16, 1);
  rb_define_singleton_method(rb_mMmGPS, "append_crc16", mm_gps_add_CRC16, 1);
}
