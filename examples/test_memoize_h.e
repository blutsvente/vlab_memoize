$Id:$
----------------------------------------------------------------------------

COPYRIGHT (c) 2013 by Verilab GmbH

----------------------------------------------------------------------------
                  Design Information
----------------------------------------------------------------------------

File            : test_memoize_h.e

Author          : Thorsten Dworzak

Organisation    : Verilab 

Project         : vlab_memoize

Creation Date   : 23.02.2013 

Description     : Data types for testing the vlab_memoize package

       $Revision:$

----------------------------------------------------------------------------

<'
package vlab_memoize;

-- dummy struct for testing the memoization
struct vec_s {
   %a: int;
   %b: int(bits: 40);
   display_str(): string is {
      result = appendf("(%s,%s)", a, b);
   };
};

-- a more complex type for testing the memoization
type color_t: [RED, GREEN, BLUE];
struct complex_s {
   %a  : uint;
   %lc[2] : list of color_t;
   %en : bool;
   
   display_str(): string is {
      result = appendf("a = 0x%0x / lc = {%s} / en = %s", a, str_join(lc.apply(it.as_a(string)), ";"), en.as_a(string));
   };
};

'>
