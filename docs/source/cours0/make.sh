#!/bin/bash
#
# Compile a French document to PDF and HTML
#

name=cours0
# doconce ipynb2doconce $name.ipynb

#doconce ipynb2doconce $name.ipynb

options="--encoding=utf-8"
opt2="--without_solutions --without_answers"
function system {
  "$@"
  if [ $? -ne 0 ]; then
    echo "make.sh: unsuccessful command $@"
    echo "abort!"
    exit 1
  fi
}

function common_replacements {
  filename=$1
  # Replace English phrases
  # __Summary.__ is needed for identifying the abstract
  doconce replace "Summary" "Résumé" $1
  doconce replace "Notice" "Note" $1
  doconce replace "Table of contents" "Table des matières" $1
  doconce replace "Contents" "Contenu" $1
  doconce replace "Project" "Projet" $1
  doconce replace "Example" "Exemple" $1
  doconce replace "Warning" "Avertissement" $1
  doconce replace "Hint" "Indication" $1
}
# Note: since Doconce syntax is demonstrated inside !bc/!ec
# blocks we need a few fixes

function editfix {
# Fix selected backslashes inside verbatim envirs that doconce has added
# (only a problem when we want to show full doconce code with
# labels in !bc-!ec envirs as in this presentation).
doconce replace '\label{this:section}' 'label{this:section}' $1
doconce replace '\label{fig1}' 'label{fig1}' $1
doconce replace '\label{demo' 'label{demo' $1
doconce replace '\eqref{eq1}' '(ref{eq1})' $1
doconce replace '\eqref{myeq}' '(ref{myeq})' $1
doconce replace '\eqref{mysec:eq:Dudt}' '(ref{mysec:eq:Dudt})' $1
}

doconce pygmentize $name.do.txt perldoc
system doconce format pdflatex $name --latex_code_style=pyg-gray $options --latex_admon=grayicon --latex_admon_title_no_period --latex_style=std --latex_copyright=Springer_collection
# Tips: http://folk.uio.no/tobiasvl/latex.html
system common_replacements $name.tex
# Auto edits
# With t4/svmono linewidth has some too large value before \mymainmatter
# is called, so the box width as linewidth+2mm is wrong, it must be
# explicitly set to 120mm.
doconce replace '\setlength{\lstboxwidth}{\linewidth+2mm}' '\setlength{\lstboxwidth}{120mm}' $name.tex # lst
system doconce replace 'linecolor=black,' 'linecolor=darkblue,' $name.tex
system doconce subst 'frametitlebackgroundcolor=.*?,' 'frametitlebackgroundcolor=blue!5,' $name.tex
system doconce replace '\maketitle' '\subtitle{Modeling, Algorithms, Analysis, Programming, and Verification}\maketitle' $name.te
doconce replace 'texttt{>>>}' 'Verb!>>>!' $name.tex # require fix for latex

doconce replace '11pt]{' '11pt,french]{' $name.tex
system common_replacements $name.tex
# package [norsk]{label} requires texlive-lang-norwegian package
doconce subst '% insert custom LaTeX commands...' '\usepackage[french]{babel}\n\n% insert custom LaTeX commands...' $name.tex

system pdflatex -shell-escape $name
#system bibtex $name
system makeindex $name
pdflatex -shell-escape $name
pdflatex -shell-escape $name

# LaTeX Beamer slides
beamertheme=metropolis
system doconce format pdflatex $name --latex_title_layout=beamer --latex_admon_title_no_period -DBEAMER
editfix ${name}.p.tex
system doconce ptex2tex $name envir=minted
system doconce slides_beamer $name --beamer_slide_theme=$beamertheme
cp $name.tex ${name}-beamer.tex
system common_replacements ${name}-beamer.tex
system pdflatex -shell-escape ${name}-beamer
system pdflatex -shell-escape ${name}-beamer


rawgit="--html_raw_github_url=raw.github"
## deck
html=${name}-deck
system doconce format html $name --pygments_html_style='monokai' --keep_pygments_html_bg --html_links_in_new_window --html_output=$html $rawgit $options
common_replacements $html.html
system doconce slides_html $html deck --html_slide_theme=sandstone.aurora --copyright=everypage
editfix $html.html

# Remark slides
system doconce format pandoc $name --github_md SLIDE_TYPE=remark SLIDE_THEME=light $options
system doconce slides_markdown $name remark --slide_theme=light
cp $name.html ${name}_remark_light.html
common_replacements ${name}_remark_light.html

system doconce format pandoc $name --github_md SLIDE_TYPE=remark SLIDE_THEME=dark $options
system doconce slides_markdown $name remark --slide_theme=dark
cp $name.html ${name}_remark_dark.html
common_replacements ${name}_remark_dark.html

# Plain HTML documents
html=${name}-solarized
system doconce format html $name --pygments_html_style=perldoc --html_style=solarized3 --html_links_in_new_window --html_output=$html $options
system doconce split_html $html.html --method=space10
common_replacements $html.html

# HTML bootstrap
html=${name}-bs
system doconce format html $name --html_style=bootswatch_cyborg --pygments_html_style='monokai' --html_admon=bootstrap_alert --html_output=$html $options --keep_pygments_html_bg --html_code_style=inherit --html_pre_style=inherit
common_replacements $html.html
#system doconce split_html $html.html --pagination


# Jupyter notebook
doconce format ipynb $name

# Publish
dest=../../pub/$name
if [ ! -d $dest ]; then
mkdir $dest
fi
cp -r imgs scripts *.pdf *.html *.ipynb *.tar.gz $dest

#./clean.sh
