# comment_out_ini_option
Enables or disables a single configuration option in a standard ini configuration file.

Usage:
Comments out an option in an ini file, if exists.  Pass the argument -u for uncomment and -c for comment out.  If there is a section header, it must be preceded by the -s flag.  The filename must be preceded with the flag -f.  Use -x to change the comment character from # to something else.  The arguments can follow any order.  Any spaces or parenthesis in the target text must be escaped if the argument is not delimited by quotes.
   For examples:
   
      sudo comment_out_ini_option.lua -f /boot/config.txt -u dtoverlay=disable-wifi

      sudo comment_out_ini_option.lua -f /etc/exports -u /srv\ 192.168.0.0/24\(rw,sync,no_subtree_check\)
