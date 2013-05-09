$Id:$
----------------------------------------------------------------------------

COPYRIGHT (c) 2013 by Verilab GmbH

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

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
