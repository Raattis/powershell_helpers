# Installation
* Put these in a folder on your PC and add the folder to your PATH.
* Restart any powershell windows for the changes to take effect.

# Usage
### `e` is for edit (with Notepad++)
* `e path/to/file.cpp` to open the file in Notepad++
  * Note the hardcoded path in `e.ps1` and change it as necessary
* `e path/to/file.cpp:123` to open at line 123
  * `e path/to/file.cpp 123` and `e path/to/file.cpp -line 123` work too

### `f` is for find
* `f` lists all files recursive starting from the current working directory
  * Some folders are excluded from the search by default (`.git`, `.vs`, `build`, etc.) see the sources for the list. Use `-ndx`/`-no_default_excludes` to disable this behavior
  * `-x Debug,Release` to exclude more folders
  * `-p[ath] ../other/path` to change the search root
* `f .cpp` filter files by extension
* `f .cpp,.h` filter supports comma-separated lists
* `f *test*.cpp` and wildcards
  * `f *` matches every file
* `f .cpp hello` find every `hello` inside `.cpp` files
* `f .cpp hello.*world` note that content search uses regex (not wildcards)
  * `f .cpp "hello|hiya"` remember to `"` quote if using special characters
  * ``f .cpp `"hello``/``f .cpp "`"hello"`` note that the escape character in powershell is the backtick `` ` ``
* `f .cpp hello.*world -open 1` same as before but open the first hit at the correct line
* `-pf \my_project\,\my_tests\` to filter by path

### `re` is for "rerun search and edit (with Notepad++)"
* `re` rerun the previous `f`ind command in your commandline history and append `-open 1` if the `f`ind didn't have it before
* `re 5` append `-open 5` instead
* If there was no `f` in the command-line history just run it without any extra arguments
* Hint: Because the `f`ind is rerun every time, if you are doing manual edits to the hits and saving them so that they don't match the `f`ind anymore, you can just rerun the `re` to edit the next result

## `help`
* See `help e/f/re` or source code for more arguments and switches
* `e [-filename] <string> [[-line] <string>]`
* `f [[-filters] <string[]>] [[-pattern] <string>] [-user_excludes|x <string[]>] [-no_default_excludes|ndx] [-path|p <string>] [-open|o <int>] [-path_filters|pf <string[]>]`
* `re [[-open] <int>]`

# Other stuff
 * [PowerShell-prompt](https://github.com/Raattis/PowerShell-prompt) - git-aware powershell prompt label
