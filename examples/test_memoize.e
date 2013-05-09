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

File            : test_memoize.e

Author          : Thorsten Dworzak

Organisation    : Verilab 

Project         : vlab_memoize

Creation Date   : 23.02.2013 

Description     : Example/sanity test for vlab_memoize package

       $Revision:$

----------------------------------------------------------------------------

<'
package vlab_memoize;

define DEBUG_MEMOIZE;

import vlab_memoize/e/vlab_memoize_top;
import test_memoize_h;

-- dummy structs for testing deep_is_physical()
struct test_a {
   %a : int;
   b: int;
};
struct test_b {
   %a: int;
   b: test_a;
};
struct test_c {
   %a: int;
   %b: test_a;
};
struct test_d {
   %x: test_x;
   %a: int;
   %l: list of test_x;
};
struct test_x {
   %c: string;
   %d: bool;
};
struct test_e {
   %x: test_x;
   %l: list of test_a;
   %a: int;
};
struct test_f {
   %x: test_x;
   %a: int;
   %l: list of test_x;
};
struct test_g {
   %a: bool;
   %b: list of test_g; -- recursive struct
   attribute b deep_copy = reference;
};


extend sys {
   !s1: vec_s;
   !s2: vec_s;
   !s3: vec_s;

   jim: complex_s;
   bob: complex_s;
   
   init() is also {
      s1 = new with {
         .a = 3141;
         .b = 42;
      };
      s2 = new with {
         .a = 859;
         .b = -42;
      };
   };
     
   setup() is also {
      set_config(print, radix, HEX);
   };
   
   run() is also {
      -- test the check_is_physical() method
      check that not util.mz_manager.check_is_physical("test_a");
      check that not util.mz_manager.check_is_physical("test_b");
      check that not util.mz_manager.check_is_physical("test_c");
      check that     util.mz_manager.check_is_physical("test_d");
      check that     util.mz_manager.check_is_physical("test_x");
      check that not util.mz_manager.check_is_physical("test_e");
      check that     util.mz_manager.check_is_physical("test_f");
      check that     util.mz_manager.check_is_physical("test_g");
      check that     util.mz_manager.check_is_physical("list of test_g");
      check that not util.mz_manager.check_is_physical("list of test_a");
      check that     util.mz_manager.check_is_physical("complex_s");
      
      -- test MEMOIZE macro
      start go();
   };
   
   go()@sys.any is {
      out("-----------------\n");
      s3 = foo_compare(s1,s2);
      s3 = foo_compare(s3,s2);
      s3 = foo_compare(s1,s2);

      out("-----------------\n");
 
      jimbob_compare(3141, jim);
      jimbob_compare(13, bob);
      bob = deep_copy(jim);
      jimbob_compare(13, jim);
      jimbob_compare(3141, bob);
      jimbob_compare(3141, jim);
     out("-----------------\n");
     
      stop_run();
   };
   
   ------ core functions that will be cached
   foo_core(x: vec_s, y: vec_s): vec_s is {
      result = new with { .a = x.a + y.a; .b = x.b + y.b };
   };
   jimbob_core(in1: uint, in2: complex_s): complex_s is {
      var r1: complex_s = new with {
         .a  = in1 << 4;
         .lc = in2.lc.reverse();
         .en = not in2.en;
      };
      result = r1;
   };
   
   
   -- create a wrapper function for *_core() that is memoized
   MEMOIZE MAX_ENTRIES = 500 PACKING = packing.low foo(x: vec_s, y: vec_s): vec_s@sys.any is {
      result = foo_core(x, y);
   };
   MEMOIZE jimbob(a: uint, b: complex_s): complex_s is {
      result = jimbob_core(a, b);
   };
   
   ------ for testing, call memoized and original function and compare the results
   foo_compare(x: vec_s, y: vec_s):vec_s@sys.any is {
      var s: vec_s = foo(x, y);
      check that deep_compare(s, foo_core(x, y), 1).size() == 0;
      out( x.display_str(), " + ", y.display_str(), " = ", s.display_str(),"\n" );
      result = s;
   };
   jimbob_compare(in1: uint, in2: complex_s) is {
      var s: complex_s = jimbob(in1,  in2);
      var j: complex_s = jimbob_core(in1, in2);
      check that deep_compare(s, j, 1).size() == 0;
      outf("in1: 0x%x\nin2: %s\nresult = {%s}\n", in1, in2.display_str(), s.display_str());
   };
};


'>
