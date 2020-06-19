#!/usr/bin/luajit
--------------------------------------------------------------------
--     comment_out_ini_option.lua:
--      This terminal shell script enables or disables a single
--       configuration option in a standard ini configuration file.
--       The section heading must be preceeded by the option -s, if
--       applicable
--
--     Authors/maintainers: ciscorx@gmail.com
--
--     Commit date: 2020-06-18
--
--     License: GNU General Public License v3
---------------------------------------------------------------------

local os = require('os')

local function split(inputstr, sep) 
   sep=sep or '%s' 
   local t={} 
   for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
      table.insert(t,field)
      if s=="" then
	 return t
      end
   end
end

local function strQuote (str)
   if not str then return "" end
   local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
   return str:gsub(quotepattern, "%%%1")
end

local function escape_pattern(text)
   if not text then return "" end

   return text:gsub("([^%w])", "%%%1")
end

local function file_exists(filename)
   if filename==nil then return nil end
   if type(filename) ~= "string" then return nil end
   if filename=="" then return nil end
   local f=io.open(filename,"r")
   if f~=nil then io.close(f) return true else return false end
end

local function file_exists_and_can_be_written_to(name)
   local f=io.open(name,"w")
   if f~=nil then io.close(f) return true else return false end
end


-- arg_handler() is a quick and dirty command line argument handler
-- requiring minimal configuration, unlike the more refined lua
-- argparse function, and simply spits out a table of options to args,
-- with all the remaining args that are without options listed under
-- the "optionless" field of the table.  Instead of having to supply
-- the number of arguments expected for each respective option flag,
-- all the arguments after an option become associated with that
-- option, until the next option flag in the command line string is
-- encountered.  However, if there exists argumentless options then
-- they must first be specified in the parameters to this function,
-- either in the first parameter string or the second parameter table,
-- unless the argumentless option happens to be the last argument
-- passed, in which case its assumed to be argless.  Also, if argless
-- options are not specified in the parameters then they are to be
-- assumed, if multiple options appear consecutively in the command
-- line string.  The last option flag will only allow one argument to
-- be associated with it, all the remaining arguments considered
-- optionless.  Also, any arguments before the first flag are also
-- considered to be optionless, but listed under the
-- "preceeding_arguments" field.  The third parameter to this function
-- is a string which is to specify single character option flags that
-- are not to have spaces between the argument and the option flag.
-- Certain popular programs like to do this, such as, for example, the
-- -o option in 7zip, or the -I option for including libraries in gcc.
local function arg_handler ( tblArg , strSingle_character_argless_switches, tblArgless, strSpaceless_single_character)

   if not tblArg and arg then
      tblArg = arg
   elseif not arg then
      
      return nil
   end
   
   local function Set (list)
      local set = {}
      for _, l in ipairs(list) do
	 set[l] = true
      end
      return set
   end
   
   local function tblSlice_to_string ( tbl, start, finish )
      local return_val = ""
      if finish < 0 then
	 finish = #tbl + finish + 1
      end
      if start < 0 then
	 start = #tbl + start
      end
      for i = start,finish do
	 return_val = return_val..tbl[i].." "
      end
      if return_val:sub(-1,-1) == " " then
	 return_val = return_val:sub(1,-2)
      end
      return return_val
   end

   
   local function all_chars_in_str_are_in_set ( str, set)
      local i
      if not str or str == "" then
	 return false
      end
      
      for i = 1,#str do
	 if not set[str:sub(i,i)] then
	    return nil
	 end
      end
      return true
   end


   local flags = {}
   local latestflag = nil
   local latestflag_starting_arg = nil
   local flags_to_look_for = {}
   local argless_single_char_set
   local argless_set
   local spaceless_single_char_set
   local number_of_options_passed = 0
   local last_flag_was_argless = false
   flags["all"] = tblSlice_to_string(tblArg,1,-1)
   flags["prog"] = tblArg[0] 
   if strSingle_character_argless_switches then
      local argless_chars ={}
      for i = 1,#strSingle_character_argless_switches do
	 if strSingle_character_argless_switches:sub(i,i) ~= "~" then
	    table.insert (argless_chars, strSingle_character_argless_switches:sub(i,i))
	 end
      end
      argless_single_char_set = Set(argless_chars)
   end
   if tblArgless then
      argless_set = Set(tblArgless)
   end

   if strSpaceless_single_character then
      local spaceless_chars={}
      for i = 1,#strSpaceless_single_character do
	 if strSpaceless_single_character:sub(i,i) ~= "-" then
	    table.insert (spaceless_chars, strSpaceless_single_character:sub(i,i))
	 end
      end
      spaceless_single_char_set = Set(spaceless_chars)
   end
   
   for k,v in ipairs(tblArg) do
      if #v > 1 and v:sub(1,1) == "-" then
	 if latestflag then
	    if strSingle_character_argless_switches and all_chars_in_str_are_in_set( v:sub(2,-1), argless_single_char_set) or spaceless_single_char_set and spaceless_single_char_set[v:sub(2,2)] or argless_set and argless_set[v] then
	       
	       if last_flag_was_argless == false then  -- tie the last args with last flag
		  flags[latestflag] = tblSlice_to_string(tblArg,latestflag_starting_arg,k-1)
		  latestflag_starting_arg = k +1
	       end
	       
	       
	       last_flag_was_argless = true
	       if spaceless_single_char_set and spaceless_single_char_set[v:sub(2,2)] then
		  flags[v:sub(1,2)]= v:sub(3,-1)
		  number_of_options_passed = number_of_options_passed + 1
	       elseif argless_set and argless_set[v] then
		  flags[v] = true
		  number_of_options_passed = number_of_options_passed + 1
		  
	       else   -- single char argless
		  for i = 2,#v do
		     flags["-"..v:sub(i,i)] = true
		     number_of_options_passed = number_of_options_passed + 1
		  end
	       end
	       
		  latestflag_starting_arg = k +1
            elseif k == #arg then
	       if last_flag_was_argless == false then  -- tie the last args with last flag
		  flags[latestflag] = tblSlice_to_string(tblArg,latestflag_starting_arg,k-1)
	       end
	       
	       flags[v] = true
	    else   -- current flag is not argless
	       if last_flag_was_argless == false then  -- tie the last args with last flag
		  flags[latestflag] = tblSlice_to_string(tblArg,latestflag_starting_arg,k-1)
		  latestflag_starting_arg = k +1
		  
	       end
	       last_flag_was_argless = false
	       latestflag = v
	       number_of_options_passed = number_of_options_passed + 1
	    end
	    
	    latestflag_starting_arg = k +1
	    
	 else -- if k > 1 then  -- no latestflag and not first position, but proceeding args
	    if strSingle_character_argless_switches and all_chars_in_str_are_in_set( v:sub(2,-1), argless_single_char_set) or single_char_argless_set  and spaceless_single_char_set[v:sub(2,2)] or argless_set and argless_set[v] then
	       
	       
	       
	       last_flag_was_argless = true
	       if spaceless_single_char_set and spaceless_single_char_set[v:sub(2,2)] then
		  flags[v:sub(1,2)]= v:sub(3,-1)
		  number_of_options_passed = number_of_options_passed + 1
	       elseif argless_set and argless_set[v] then
		  flags[v] = true
		  number_of_options_passed = number_of_options_passed + 1
		  
	       else   -- single char argless
		  for i = 2,#v do
		     flags["-"..v:sub(i,i)] = true
		     number_of_options_passed = number_of_options_passed + 1
		  end
	       end
	       
            elseif k == #arg then
	       flags[v] = true
	    else      -- current flag is not argless

	       
	       number_of_options_passed = number_of_options_passed + 1
	       latestflag_starting_arg = k +1
	       latestflag = v
	       last_flag_was_argless = false
	    end
	    -- if k > 1 then 
	    --    flags["proceeding_arguments"]=tblSlice_to_string(tblArg,1,k-1)
	    -- end
		  latestflag_starting_arg = k +1
	 end
      -- These arguments are not flags	 
      elseif k == #arg then
	 if latestflag_starting_arg == k and not last_flag_was_argless then
	    flags[latestflag] = v
	 
	 elseif latestflag_starting_arg == k and last_flag_was_argless then
	    flags["optionless"] = v 
	 elseif not latestflag then  -- there were no flags at all
	    flags["optionless"] = tblSlice_to_string(tblArg,1,-1)
	 else -- if latestflag then
	    flags[latestflag] = tblArg[latestflag_starting_arg]  -- only allow last flag to have 1 argument
	    --flags[latestflag] = tblSlice_to_string(tblArg,latestflag_starting_arg,k-1)
	    if last_flag_was_argless then
	       flags["optionless"] = tblSlice_to_string(tblArg,latestflag_starting_arg,-1)
	    else
	       
	       flags["optionless"] = tblSlice_to_string(tblArg,latestflag_starting_arg + 1,-1)
	    end
	 
	    flags["optionless_assuming_last_flag_is_argumentless"] = tblSlice_to_string(tblArg,latestflag_starting_arg,-1)
	    flags["last_flag_that_may_be_argumentless"] = latestflag
	    if flags["proceeding_arguments"] then
	       flags["optionless_assuming_including_proceeding"] = flags["proceeding_arguments"].." "..flags["optionless_assuming_last_flag_is_argumentless"]
	       flags["optionless_including_proceeding"] = flags["proceeding_arguments"].." "..flags["optionless"]
	       flags["optionless"] = flags["proceeding_arguments"].." "..flags["optionless"]
	    else
	       flags["optionless_assuming_including_proceeding"] = flags["optionless_assuming_last_flag_is_argumentless"]
	       flags["optionless_including_proceeding"] = flags["optionless"]
	       flags["optionless_including_proceeding"] = flags["optionless"]
	    end
	 end
      end
   end    -- for loop ends here
   flags["number_of_options_passed"]= number_of_options_passed
   return flags
end

-------------- function definitions section ends here -----------


local arg_with_flags = arg_handler(arg, "deh")

if not arg_with_flags or arg_with_flags["-h"] or arg_with_flags["--help"] then
   print [[
Usage: Comments out an option in an ini file, if exists.  Pass the argument -e for enable and -d for comment out.  If there is a section header, it must be proceeded by the -s flag.  The filename must be proceeded with the flag -f.  Use -c to change the comment character from # to something else.  The arguments can follow any order.
   For example:
      comment_out_ini_options.lua -f FILE -e dtoverlay=disable-wifi
]]
      os.exit()
end

local filename = "/tmp/config.txt"
if arg_with_flags["-f"] then
   if file_exists(arg_with_flags["-f"]) then
      filename = arg_with_flags["-f"]
   else
      print("File does not exist.")
      os.exit()
   end
end

local disposition
local disposition_bool
if arg_with_flags["-d"] then
   disposition_bool = false
elseif arg_with_flags["-e"] then
   disposition_bool = true
else
   print("A disposition option must be present, -e for enable, or -d for disable.\nInclude the section heading after the option -s, if applicable.")
   os.exit()
end

local comment_char = "#"
if arg_with_flags["-c"] then
   comment_char = arg_with_flags["-c"]
end

local cfg_txt = arg_with_flags["optionless"]
local cfg_pattern = escape_pattern(cfg_txt).."%s*"
local cfg_pattern_contrapositive

local f = assert(io.open(filename, "r"))
fc = f:read("*all")
f:close()
result = split(fc, "\n")

local heading
local heading_found_linenum
local heading_delimiter
local heading_delimiter_pattern
local linenum_to_start_search = 1
local new_result ={}
if arg_with_flags["-s"] then
   heading=arg_with_flags["-s"]
   if heading:sub(1,1) ~= "[" and heading:sub(1,1) ~= "{" then
      heading_delimiter = "["
      heading="["..heading.."]"
   else
      heading_delimiter = heading:sub(1,1)  -- heading_delimiter can only be 1 character in length 
   end
   heading_delimiter_pattern =  "%s*"..escape_pattern(heading_delimiter).."%s*"

   local heading_pattern = "%s*"..escape_pattern(heading).."%s*"
   for k,v in ipairs(result) do
      if v:match(heading_pattern) then
	 heading_found_linenum = k 
	 linenum_to_start_search = k + 1
	 break
      end
   end
end



local size = #result
if size > 2 and result[size] == "" and result[size-1] == "" then
   result [size] = nil
end

local line_num_of_option 
if disposition_bool == true then    -- enabling or adding option
   cfg_pattern_contrapositive =  "^%s*"..cfg_pattern
   cfg_pattern =  "^%s*"..comment_char.."+%s*"..cfg_pattern
   

   if heading then 
      for k,v in ipairs(result) do
      
	 if k >= linenum_to_start_search then
	    if v:match(cfg_pattern) and #v>1 and not v:match(heading_delimiter_pattern) then
	       result[k]=cfg_txt
	       line_num_of_option = k
	    elseif #v>1 and v:match(heading_delimiter_pattern) then
	       line_num_of_heading_end_delimiter = k
	       break
	    elseif v:match(cfg_pattern_contrapositive) then
	       print'option already enabled'
	       os.exit()
	       
	    end
	 end
      end
      if not line_num_of_option and not heading_found_linenum then
	 table.insert(result, heading)
	 table.insert(result, cfg_txt)
      elseif not line_num_of_option and heading_found_linenum then
	 for k,v in ipairs(result) do
	    table.insert(new_result, v)
	    if k == heading_found_linenum then
	       table.insert(new_result, cfg_txt)
	    end
	 end
	 result = new_result
      else  -- line_num_of_option and heading_found_linenum
	 result[line_num_of_option] = cfg_txt
      end
		
   else  -- no heading, enable or adding option
      for k,v in ipairs(result) do
	 if v:match(cfg_pattern) then
	    line_num_of_option = k
	    break

	 elseif v:match(cfg_pattern_contrapositive) then
	    print'option already enabled'
	    os.exit()
	 end	       
      end
      if not line_num_of_option then
	 table.insert(result, cfg_txt)
      else
	 result[line_num_of_option] = cfg_txt
	 
      end
   end
     
else
   -- commenting out option

   cfg_pattern_contrapositive =  "^%s*"..comment_char.."+%s*"..cfg_pattern
   cfg_pattern = "^%s*"..cfg_pattern
   if heading and heading_found_linenum then
      for k,v in ipairs(result) do
	 if k > heading_found_linenum then
	    if v:match(heading_delimiter_pattern) then
	       print'no such line exists to disable'
	       os.exit()
	    end
	    if v:match(cfg_pattern) then
	       result[k]=comment_char..cfg_txt
	       line_num_of_option = k
	       break
	    elseif v:match(cfg_pattern_contrapositive) then
	       print'option already disabled'
	       os.exit()
	    end
	    
	 end
      end
   elseif heading and not heading_found_linenum then
      print'Section heading not found; nothing to disable'
      os.exit()
   else  -- no section heading
      for k,v in ipairs(result) do
	 if v:match(cfg_pattern) then
	    result[k]=comment_char..cfg_txt
	    line_num_of_option = k
	    break
	 elseif v:match(cfg_pattern_contrapositive) then
	    print'option already disabled'
	    os.exit()
	 end
      end
	 
   end
   
   if not line_num_of_option then
      print'no such option exists to disable'
      os.exit()
   end
end

local f = assert(io.open(filename, "w"))
for k,v in ipairs(result) do
   f:write(v,"\n")
end
f:close()


   
