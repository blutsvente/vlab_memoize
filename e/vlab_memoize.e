$Id:$
----------------------------------------------------------------------------

    Package vlab_memoize
    COPYRIGHT (c) 2012-2013 by Verilab GmbH

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

----------------------------------------------------------------------------
                  Design Information
----------------------------------------------------------------------------

File            : vlab_memoize.e

Author          : Thorsten Dworzak

Organisation    : Verilab 

Project         : vlab_memoize

Creation Date   : 23.02.2013 

Description     : Core package module of vlab_memoize

       $Revision:$

----------------------------------------------------------------------------
<'
package vlab_memoize;

-- Cache entry data type
struct vlab_memoize_cache_entries_s {
   !hash   : uint;
   !input  : list of byte;
   !output : list of byte;
   
   -- member access
   set_hash(val: uint) is { hash = val                           };
   calc_hash()         is { hash = util.mz_manager.DJBHash(input) };
};

-- Cache hit/miss statistics data type
struct vlab_memoize_stat_s {
   !name       : string;
   !hit_count  : uint;
   !miss_count : uint;
};

extend sn_util {
   -- create an instance of the manager struct (needs to be constructed before generation)
   !mz_manager: vlab_memoize_manager_s;
   init() is also { mz_manager = new };
};

-- Struct that holds global data and methods for meoization
struct vlab_memoize_manager_s like any_struct {

   -- Returns TRUE if a struct has only physical fields; prints a warning (and returns FALSE)
   -- if called with a non-struct or unknown type name
   deep_is_physical(name: string): bool is {
      var t: rf_type = rf_manager.get_type_by_name(name);
      if t is a rf_list (rl) {
         result = TRUE;
         var t_listelem := rl.get_element_type();
         if (t_listelem is a rf_struct) or (t_listelem is a rf_list) { -- field is a list of structs or list of lists
            result = deep_is_physical(t_listelem.get_qualified_name());
         };
      } else if t is a rf_struct (rs) {
         for each (field) in rs.get_fields() { -- iterate over all fields of the struct
            if field.is_physical() {
               var t_field := field.get_type();
               if t_field is a rf_struct (rsf) { -- field is a struct itself
                  if rsf != rs {
                     var t_struct := field.get_type();
                     result = deep_is_physical(t_struct.get_qualified_name());
                  };
               } else if t_field is a rf_list (rlf) { -- field is a list
                  result = deep_is_physical( rlf.get_element_type().get_qualified_name());
               };
            };
         };
      } else {
         result = FALSE;
         warning("method deep_is_physical() called with type name \"", name, "\" (expected a struct or list but got a \"", (t == NULL ? "unknown" : t.get_qualified_name()),"\")");
      };
   };
   
   -- DJB Hash method translation to e (c) 2012 Thorsten Dworzak.
   -- Original C function (c) DJ Bernstein, license: http://opensource.org/licenses/cpl1.0.php
   final DJBHash(str: list of byte) : uint is {
      var hash: uint = 5381;
      for i from 0 to str.size()-1 do { hash = ((hash << 5) + hash) + str[i] };
      return hash;
   };

     
   -- Statistics for the cache utilization rate
   incr_hit(name: string) is empty;
   incr_miss(name: string) is empty;
   
   #ifdef DEBUG_MEMOIZE {
      protected !stat_l: list (key: name) of vlab_memoize_stat_s;
      
      -- incremenent the cache hit-counter
      incr_hit(name: string) is { 
         if not stat_l.key_exists(name) {
            var stat_entry: vlab_memoize_stat_s = new with { .name = name };
            stat_l.add(stat_entry);
         };
         stat_l.key(name).hit_count += 1 ;
      };
      
      -- increment the cache miss-counter
      incr_miss(name: string) is { 
         if not stat_l.key_exists(name) {
            var stat_entry: vlab_memoize_stat_s = new with { .name = name };
            stat_l.add(stat_entry);
         };
         stat_l.key(name).miss_count += 1;
      };
      
      -- print the statistics
      print_stat() is {
         for each in stat_l {
            message(LOW, appendf("vlab_memoize_manager: report for function \"%s()\": %d miss(es), %d hit(s)", it.name, it.miss_count, it.hit_count));
         };
      };
   };
}; -- vlab_memoize_manager_s 

  
#ifdef DEBUG_MEMOIZE {
   extend sys {
      finalize() is also { util.mz_manager.print_stat() };
   };
};

-- MEMOIZE macro
define <vlab_memoize_pure_method_decorator'struct_member> "MEMOIZE[ [MAX_ENTRIES[ ]=[ ]]<max_entries'num>][ PACKING[ ]=[ ]<packing'any>]<org'name>[ ]\(<args'name>,...\)[ ]\:[ ]<ret'type>[ ][@<edge'any>] is <block>" as computed {
   var rl: list of string;
   
   -- extract the macro parameters
   var max_entries: uint = (str_len(<max_entries'num>) == 0 ? 1000 : <max_entries'num>.as_a(uint));
   var packing_option: string = (str_len(<packing'any>) == 0 ? "packing.low" : str_trim(str_expand_dots(<packing'any>)));  
   
   #ifdef DEBUG_MEMOIZE {
      outf(">>> max_entries %d\n", max_entries);
      outf(">>> packing_option: %s\n", packing_option);
      outf(">>> %s\n", <org'name>);
   };
   
   -- parse the method argument list
   var i_names: list of string;
   var i_types: list of string;
   for each in (<args'names>) {
      var arg: list of string;
      arg = str_split(it, ":"); 
      assert arg.size() == 2 else error("Invalid input parameter list in macro call.");
      arg = arg.apply(str_trim(it));
      #ifdef DEBUG_MEMOIZE {
         outf(">>> [%s]:[%s]\n", arg[0], arg[1]);
      };
      i_names.add(arg[0]); i_types.add(arg[1]);
   };
   
   -- validate the method input parameters
   for i from 0 to i_names.size() -1 {
      var i_t:  rf_type = rf_manager.get_type_by_name(i_types[i]);
      if (i_t is a rf_struct) or (i_t is a rf_list) {
         assert util.mz_manager.deep_is_physical(i_types[i])
           else error("Input parameter \"", i_names[i], "\" is not physical! Error in macro call.");
      };
   };
   -- validate the result parameter
   var ret: string = <ret'type>;
   var r_t: rf_type = rf_manager.get_type_by_name(ret);
   if (r_t is a rf_struct) or (r_t is a rf_list) {
      assert util.mz_manager.deep_is_physical(ret)
        else error("Output parameter \"", ret, "\" is not physical! Error in macro call.");
   };

   #ifdef DEBUG_MEMOIZE {
      outf(">>> result: %s\n", ret);
      outf(">>> edge  : %s\n", <edge'any>);
   };
   
   -- create code to instantiate the cache object
   rl.add(appendf("!%s_memoized_cache: list (key: hash) of vlab_memoize_cache_entries_s;", <org'name>));
   
   -- wrap the original function with the memoization code
   var ret_type: string = append(":", ret);
   var edge: string  = (str_len(<edge'any>) == 0 ? "" : appendf("@%s", <edge'any>));
   
   rl.add(appendf("final %s (%s)%s%s is {", <org'name>, str_join(<args'names>,","), ret_type, edge));
   rl.add(appendf("   var hit: bool = FALSE;                                                         "));                 
   rl.add(appendf("   var search_input: list of byte = pack(%s,%s);                                  ", packing_option, str_join(i_names,",")));
   rl.add(appendf("   var search_key: uint = util.mz_manager.DJBHash(search_input);                   "));
   rl.add(appendf("   var key_idx: int = %s_memoized_cache.key_index(search_key);                    ", <org'name>));
   rl.add(appendf("   if key_idx != UNDEF {                                                          "));
   rl.add(appendf("      var entry: vlab_memoize_cache_entries_s =  %s_memoized_cache[key_idx];      ", <org'name>));
   for i from 0 to i_names.size()-1 do {
      rl.add(appendf("      var %s0:%s;                                                              ", i_names[i], i_types[i]));
   };
   rl.add(appendf("      var r0%s;                                                                   ", ret_type));
   rl.add(appendf("      if entry.input == search_input {"));
                  rl.add(appendf("         unpack(%s, entry.output, r0);                                            ", packing_option));
   rl.add(appendf("         result = r0;                                                             "));
   rl.add(appendf("         hit    = TRUE;                                                           "));
   #ifdef DEBUG_MEMOIZE {
      rl.add(appendf("         util.mz_manager.incr_hit(\"%s\");                                         ", <org'name>));   
   };
   rl.add(appendf("      };                                                                          "));
   rl.add(appendf("   };                                                                             "));
   rl.add(appendf("   if not hit {                                                                   "));   
   rl.add(appendf("      %s;", str_expand_dots(<block>)));   
   rl.add(appendf("      var new_entry: vlab_memoize_cache_entries_s = new with {     "));    
   rl.add(appendf("         .input  = search_input;                                   "));
   rl.add(appendf("         .output = pack(packing.low, result);                      "));
   rl.add(appendf("      };                                                           "));
   rl.add(appendf("      new_entry.set_hash(search_key);                              "));
   rl.add(appendf("      if key_idx != UNDEF {                                        "));
   rl.add(appendf("         %s_memoized_cache[key_idx] = new_entry;                   ", <org'name>));
   rl.add(appendf("      } else {                                                     "));
   rl.add(appendf("         if %s_memoized_cache.size() >= %d { compute %s_memoized_cache.pop0() };", <org'name>, max_entries, <org'name>));
   rl.add(appendf("         %s_memoized_cache.push(new_entry);                        ", <org'name>));
   rl.add(appendf("      };                                                           "));
   #ifdef DEBUG_MEMOIZE {
      rl.add(appendf("      util.mz_manager.incr_miss(\"%s\");                         ", <org'name>));   
   };
   rl.add(appendf("   };"));
   rl.add(appendf("};"));

   #ifdef DEBUG_MEMOIZE {
      out(">>> expansion of MEMOIZE macro start <<<");
      for each in rl { out(it) };
      out(">>> expansion of MEMOIZE macro end   <<<");
   };
   
   result = appendf("{ %s }", str_join(rl, " "));
};

'>
