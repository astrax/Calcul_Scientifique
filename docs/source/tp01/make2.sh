#!/bin/bash
#
# Compile a French document to PDF and HTML
#

name=tp01
# doconce ipynb2doconce $name.ipynb

options="--encoding=utf-8"

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
  doconce replace Summary Résumé $1
  doconce replace Notice "À noter" $1
  doconce replace "Table of contents" "Table des matières" $1
  doconce replace Contents Contenu $1
  doconce replace "Project" "Projet" $1
  doconce replace "Example" "Exemple" $1
  doconce replace "Warning" "Attention" $1
  doconce replace "Hint" "Indication" $1
}

doconce pygmentize $name.do.txt perldoc
# ---------------------
# PDF avec solution
# ----------------------
system doconce format pdflatex $name --latex_code_style=pyg-gray $options --latex_font=palatino --latex_admon=grayicon --latex_style=std --latex_title_layout=std --latex_copyright=titlepages --latex_fancy_header --latex_section_headings=blue
# Tips: http://folk.uio.no/tobiasvl/latex.html
system common_replacements $name.tex

doconce replace '10pt]{' '10pt,french]{' $name.tex
# package [norsk]{label} requires texlive-lang-norwegian package
doconce subst '% insert custom LaTeX commands...' '\usepackage[french]{babel}\n\n% insert custom LaTeX commands...' $name.tex
cp $name.tex ${name}_corr.tex
system pdflatex -shell-escape ${name}_corr
#system bibtex $name
system makeindex ${name}_corr
pdflatex -shell-escape ${name}_corr
pdflatex -shell-escape ${name}_corr
#-------------------
# PDF sans solution
#---------------------
system doconce format pdflatex $name --latex_code_style=pyg-gray $options --without_solutions --list_of_exercises --latex_font=palatino --latex_admon=grayicon --latex_style=std --latex_title_layout=std --latex_copyright=titlepages --latex_fancy_header --latex_section_headings=blue
# Tips: http://folk.uio.no/tobiasvl/latex.html
system common_replacements $name.tex

doconce replace '10pt]{' '10pt,french]{' $name.tex
# package [norsk]{label} requires texlive-lang-norwegian package
doconce subst '% insert custom LaTeX commands...' '\usepackage[french]{babel}\n\n% insert custom LaTeX commands...' $name.tex
system pdflatex -shell-escape $name
#system bibtex $name
system makeindex $name
pdflatex -shell-escape $name
pdflatex -shell-escape $name

# HTML
system doconce format html $name --html_style=bootswatch_cyborg --pygments_html_style='monokai' --html_admon=bootstrap_alert $options --keep_pygments_html_bg --html_code_style=inherit --html_pre_style=inherit
common_replacements $name.html

# Publish
dest=../../pub/$name
if [ ! -d $dest ]; then
mkdir $dest
fi
cp -r *.pdf *.html $dest
cp -r imgs $dest
