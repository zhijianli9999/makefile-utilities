# makefile-utilities

This repo is a loose collection of notes and code for using makefiles, mostly written with economics research in mind. It's a work in progress so please let me know if you have any suggestions or questions.

In this repo:

- This tutorial.
- Code to check Stata logs and return an informative exit status.
- Code to help make a makefile dependency graph.
- [To be added later:] Code for converting Stata master files to a makefile.

## Why use makefiles?

You've seen a Stata master do-file. It looks something like this:

```stata
global codedir "/path/to/repo"

do $codedir/make_globals.do

do $codedir/datawork/clean_raw.do
do $codedir/datawork/make_analysis.do
do $codedir/analysis/regressions.do
do $codedir/analysis/plot.do
```

The makefile does the same job: it runs all of your project's code from start to finish. But it has a few advantages:

- It allows you to encode the dependency relationships between the components of your project.
- It knows the last-modified timestamp of each file, so it can tell what's up to date and what needs to be run.

Thus, if you make changes, it will only run whatever code is downstream of the change.

## How to use makefiles

### Rules

Makefiles consist of a series of _rules_. Each rule has 3 components:

- _targets_: the files the rule creates.
- _dependencies_: the prerequisites for creating the target.
- _recipe_: the shell commands that are actually run to create the target.

They are arranged like this:

```make
targets: dependencies
    recipe
```

Here's an example. This rule corresponds to `do $codedir/datawork/clean_raw.do` in the Stata master do-file above.

```make
/path/to/data/analysis_data.dta: /path/to/repo/datawork/clean_raw.do /path/to/data/raw_data.dta
    stata -b do /path/to/repo/datawork/clean_raw.do
```

#### What's in a rule?

- You can have multiple dependencies in a rule. If any of the dependencies are more recent than the target, the code will be run. It's common to have the code file as the first dependency.
- Having folders as dependencies is tricky: if you change a file in the folder (but don't change its name or the file structure), the folder's timestamp doesn't change and the makefile won't know to run the code again.
- If your recipe creates multiple files, you can list all of them as targets, separated by a space. This is equivalent to writing single-target rules (with the same dependencies and recipe) for each target listed.

##### Advanced use

- An alternative to multiple targets is _grouped targets_, which specifies explicitly that running the recipe creates all the targets. To specify a grouped target, simply list multiple targets as usual, but replace the `:` with `&:`. Assuming your code does indeed create all the targets, this is equivalent to listing all the targets separately, but it's more informative, and robust to parallel execution (with the `-j` flag).
- If, say, your code doesn't output a file, you can use the `touch` command to create an empty file (known as a _stamp_ file) with the correct name and timestamp every time the code is run. We can set up the makefile to `touch` (create or update) a corresponding `.stamp` file when the code is run, or alternatively do it at the end of your code script. This is also useful if a piece of code produces a lot of outputs and you don't want to specify all of them as targets.
<!-- TODO:
- Wildcards/pattern rules:
 -->

#### Syntax notes

- Line breaks are significant. The targets and dependencies must be on the same line, and the recipe must be on the next line.
- The recipe is indented with a tab, not spaces. (Advanced use: if you don't like having tabs, you can change this with the `.RECIPEPREFIX` variable.)
- You can break up long lines with `\` at the end of the line. Make sure there are no spaces after the `\`.
- You can define variables, e.g. as shorthand for paths and common commands. These are defined with `VARNAME = value` and used with `$(VARNAME)`.
- It's conventional to define the `all` target at the start of the makefile to represent all the final output in the project. The default target is the first target in the makefile, so if you define `all` first, the makefile knows to run your entire project.
- **Phony targets** are targets that don't correspond to files. To declare a target as phony, add `.PHONY: targetname` to the makefile. Then, you can define a rule for the phony target like any other target: `targetname: dependency1 dependency2 dependency3`. This is helpful for referring to a collection of targets that you might want to `make` as a group, or for targets that don't correspond to files.
- **Shorthands**
  - `$@` is the target.
  - `$^` is the list of dependencies.
  - `$<` is the first dependency. Usually the code file.
- `#` starts a comment.

### Example makefile

With these in mind, here's a makefile that runs the code in the Stata master do-file above.

```make
datadir = /path/to/data
codedir = /path/to/repo
statado = stata -b do

all: \
$(datadir)/table1.tex \
$(datadir)/figure1.tex

.PHONY: data

# I've declared `data` as a phony target. 
# Think of `data` as a handle to refer to $(datadir)/analysis_data.dta. When you run `make data`, it runs the code to create $(datadir)/analysis_data.dta.

data \
: \
$(datadir)/analysis_data.dta

$(datadir)/cleaned_data.dta
: \
$(codedir)/datawork/clean_raw.do \
$(datadir)/raw_data.dta
    $(statado) $<

$(datadir)/analysis_data.dta
: \
$(codedir)/datawork/make_analysis.do \
$(datadir)/cleaned_data.dta
    $(statado) $<

$(datadir)/output/table1.tex \
$(datadir)/output/table2.tex \
: \
$(codedir)/analysis/regressions.do \
$(datadir)/analysis_data.dta
    mkdir -p $(datadir)/output
    $(statado) $<

$(datadir)/output/figure1.tex \
: \
$(codedir)/analysis/plot.do \
$(datadir)/analysis_data.dta
    mkdir -p $(datadir)/output
    $(statado) $<
```

### Running make

Conventionally, the makefile is saved as `Makefile` in the root directory of the project. To run it, open a terminal, navigate to the root directory, and run `make`. This invokes the GNU make program, which processes the makefile and runs the code. If you just run `make` with no additional arguments, it will run the first target in the makefile, which is usually `all`.  

When `make` is run, it parses the makefile. Given a target, it finds all the dependencies, and all the dependencies of those dependencies, and so on. It then runs the code for each target in the correct order. If a target is up to date (i.e., its timestamp in the file system is more recent than all its dependencies), it doesn't run the code.

If you're not ready to make the `all` target, you can specify an intermediate target. In the example above, `make $(datadir)/table1.tex` will run everything except `plot.do`, and `make data` will just run `clean_raw.do` and `make_analysis.do`.

The makefile might contradict your coding instincts in a few ways. The order of the rules in the makefile doesn't matter since the order of what's run is determined by the dependencies. Also, if you run `make` twice in a row, the second time runs nothing since all the targets are up to date. If you want to run the code again, you can delete the output files or run `make -B` (or `make --always-make`).

#### Debugging

- To print debugging information when running the makefile, you can instead do something like
  `nohup make --debug=b > make.log &`.

  - The `--debug=b` flag prints out the commands that are run and the results of the dependency checks.
  - The `> make.log` redirects the output to a log file.
  - The `nohup ... &` runs make in the background, so you can close the terminal and it will keep running.
- The makefile can detect simple errors like if a file is a dependency of itself, or if you set a non-existent file as a dependency. Common errors can be found [here](https://www.gnu.org/software/make/manual/html_node/Error-Messages.html).
- You can run make with a bunch of options. For example, run `make -n` to see what commands would be run, but not actually run them. A list of options can be found [here](https://www.gnu.org/software/make/manual/html_node/Options-Summary.html).

### Stata-specific notes

- Unlike a master do-file, the makefile runs the do-files in separate Stata sessions. Since globals don't carry over between sessions, you should have each do-file run a `make_globals.do` script at the start (or set up your `profile.do` in an equivalent way).

- What if your Stata do-file runs into an error? If the output of the do-file is needed for a later step, the makefile will break since the output file won't be made. However, if the output file isn't specified in the makefile, the Stata file can break silently and the makefile will keep running. This is because Stata returns an exit status of `0` to the system even if it runs into an error. To fix this, you can use the `process_stata_log` script in this repo. It checks the log file for errors and returns an exit status of 1 if there are errors. It can also move the log file from the current directory (which is where Stata places its log files when run in batch mode) to a log directory. You can use it like this:
  
```make
target: dependencies
    $(statado) $<
    ./process_stata_log $(notdir $(<:.do=.log))
```

### Common workflows

#### Adding a new do-file

Add a new rule to the makefile with the corresponding targets and dependencies. If the do-file produces output files that are needed by other rules, add them as dependencies of the other rules. If the do-file produces output files that aren't needed by other rules, add them as targets of the `all` rule.

#### Modifying a do-file

If you modify a do-file, the makefile will automatically detect that the output files are out of date and run the code again when you next run `make`. If you made a frivolous change and don't want to run the code again, you can run `touch` on the output files to update their timestamps.

### Converting an existing Stata master do-file

[To be completed]
<!-- If you already have a project with a Stata master do-file and a lot of do-files, the `stata_to_makefile.py` script in this repo might save you some time when making a makefile. It takes a Stata master do-file, identifies the do-files that are run, reads the do-files to find the dependencies and targets, and writes a makefile. It's not perfect, but it should save you some time. -->

### Visualizing the dependency graph

[To be completed]
