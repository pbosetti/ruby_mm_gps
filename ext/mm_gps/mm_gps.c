#include "mm_gps.h"

#ifndef uchar
typedef unsigned char uchar;
#endif

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


#ifdef MRUBY_ENGINE
#include <mruby/string.h>

static mrb_value mrb_mm_gps_CRC16(mrb_state *mrb, mrb_value self)
{
  char *str = (char *)NULL;
  mrb_int str_len = 0;
  mrb_get_args(mrb, "s", &str, &str_len);
  return mrb_fixnum_value(CRC16(str, str_len));
}


static mrb_value mrb_mm_gps_add_CRC16(mrb_state *mrb, mrb_value self)
{
  mrb_value str;
  union {
    ushort u;
    char   s[2];
  } crc;
  
  mrb_get_args(mrb, "S", &str);
  crc.u = CRC16(RSTRING_PTR(str), RSTRING_LEN(str));
  mrb_str_cat(mrb, str, crc.s, 2);
  return str;
}


void mrb_mruby_mm_gps_gem_init(mrb_state *mrb) {
  struct RClass *mm_gps = mrb_define_module(mrb, "MmGPS");
  mrb_define_class_method(mrb, mm_gps, "crc16", mrb_mm_gps_CRC16, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, mm_gps, "append_crc16", mrb_mm_gps_add_CRC16, MRB_ARGS_REQ(1));
}

void mrb_mruby_mm_gps_gem_final(mrb_state *mrb) {}

#else

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



#endif