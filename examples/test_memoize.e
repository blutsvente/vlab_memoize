$Id:$
----------------------------------------------------------------------------

COPYRIGHT (c) 2013 by Verilab GmbH

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
package vlab_vlab_memoize;

define DEBUG_MEMOIZE;

import vlab_memoize/e/vlab_memoize_top;

-- dummy struct for testing the memoization
struct vec_s {
   %a: int;
   %b: int(bits: 40);
   print(): string is {
      result = appendf("(%s,%s)", a, b);
   };
};

extend vlab_memoize_manager_s {
   -- test the deep_is_physical method
   run() is also {
      check that not util.mz_manager.deep_is_physical("test_a");
      check that not util.mz_manager.deep_is_physical("test_b");
      check that not util.mz_manager.deep_is_physical("test_c");
      check that     util.mz_manager.deep_is_physical("test_d");
      check that     util.mz_manager.deep_is_physical("test_x");
      check that not util.mz_manager.deep_is_physical("test_e");
      check that     util.mz_manager.deep_is_physical("test_f");
      check that     util.mz_manager.deep_is_physical("test_g");
      check that     util.mz_manager.deep_is_physical("list of test_g");
      check that not util.mz_manager.deep_is_physical("list of test_a");
  };
};

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
   %a: int;
   %l: list of test_a;
};
struct test_f {
   %x: test_x;
   %a: int;
   %l: list of test_x;
};
struct test_g {
   %a: bool;
   %b: list of test_g;
};

extend sys {
   !s1: vec_s;
   !s2: vec_s;
   !s3: vec_s;

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
     
   run() is also {
      start go();
   };
   
   go()@sys.any is {
      out("-----------------\n");
      s3 = foo_compare(s1,s2);
      s3 = foo_compare(s3,s2);
      s3 = foo_compare(s1,s2);

      out("-----------------\n");
      
      stop_run();
   };
   
   -- core function
   foo_core(x: vec_s, y: vec_s): vec_s is {
      result = new with { .a = x.a + y.a; .b = x.b + y.b };
   };
   
   -- create a wrapper function for foo_core() that is memoized
   MEMOIZE MAX_ENTRIES = 500 PACKING = packing.low foo(x: vec_s, y: vec_s): vec_s@sys.any is {
      result = foo_core(x, y);
   };
   
   -- for testing, call memoized and original function and compare the results
   foo_compare(x: vec_s, y: vec_s): vec_s@sys.any is {
      var s: vec_s = foo(x, y);
      check that deep_compare(s, foo_core(x,y), 1).size() == 0;
      out( x.print(), " + ", y.print(), " = ", s.print(),"\n" );
      result = s;
   };
};


'>
