#
##  Rd2dvi -- Convert man pages (*.Rd help files) via LaTeX to DVI/PDF.
##
## Examples:
##  Rcmd Rd2dvi.sh /path/to/Rsrc/src/library/base/man/Normal.Rd
##  Rcmd Rd2dvi.sh `grep -l "\\keyword{distr" \
##                  /path/to/Rsrc/src/library/base/man/*.Rd | sort | uniq`

R_PAPERSIZE=${R_PAPERSIZE-a4}

revision='$Revision: 1.8.2.1 $'
version=`set - ${revision}; echo ${2}`
version="Rd2dvi.sh ${version}

Copyright (C) 2000 The R Core Development Team.
This is free software; see the GNU General Public Licence version 2
or later for copying conditions.  There is NO warranty." 

usage="Usage: R CMD Rd2dvi [options] files

Generate DVI (or PDF) output from the Rd sources specified by files, by
either giving the paths to the files, or the path to a directory with
the sources of a package.

Options:
  -h, --help		print short help message and exit
  -v, --version		print version info and exit  
      --debug		turn on shell debugging (set -x)
      --no-clean	do not remove created temporary files
      --no-preview	do not preview generated output file
  -o, --output=FILE	write output to FILE
      --pdf		generate PDF output
      --title=NAME	use NAME as the title of the document
  -V, --verbose		report on what is done

Report bugs to <r-bugs@r-project.org>."

start_dir=`pwd`

clean=true
debug=false
out_ext="dvi"
output=""
preview=${xdvi-xdvi.bat}
verbose=false

TEXINPUTS=.:${R_HOME}/doc/manual:${TEXINPUTS}

file_sed='s/[_$]/\\&/g'

while test -n "${1}"; do
  case ${1} in
    -h|--help)
      echo "${usage}"; exit 0 ;;
    -v|--version)
      echo "${version}"; exit 0 ;;
    --debug)
      debug=true ;;
    --no-clean)
      clean=false ;;
    --no-preview)
      preview=false ;;
    --pdf)
      out_ext="pdf";
      preview=false;
      R_RD4DVI=${R_RD4PDF-"ae,hyper"};
      R_LATEXCMD=${PDFLATEX-pdflatex};;
    --title=*)
      title=`echo "${1}" | sed -e 's/[^=]*=//'` ;;
    -o)
      if test -n "`echo ${2} | sed 's/^-.*//'`"; then      
	output="${2}"; shift
      else
	echo "ERROR: option \`${1}' requires an argument"
	exit 1
      fi
      ;;
    --output=*)
      output=`echo "${1}" | sed -e 's/[^=]*=//'` ;;
    -V|--verbose)
      verbose=echo ;;
    --|*)
      break ;;
  esac
  shift
done

if test -z "${output}"; then
  output=Rd2.${out_ext}
fi

if ${debug}; then set -x; fi

toc="\\Rdcontents{\\R{} topics documented:}"
if [ ${#} -eq 1 -a -d "${1}" ]; then
  if test -d ${1}/man; then
    dir=${1}/man
  else
    dir=${1}
  fi
  ${verbose} "Rd2dvi: \`Rdconv -t latex' ${dir}/ Rd files ..."
  files=`LC_ALL=C find ${dir} -name "*.[Rr]d" -print | \
    sed -e '/unix\//d' | sort`
  subj="all in \\file{`echo ${dir} | sed ${file_sed}`}"
  ${verbose} "files = ${files}"
else
  files="${@}"
  if [ ${#} -gt 1 ]; then
    subj=" etc.";
  else
    subj=
    toc=
  fi
  subj="\\file{`echo ${1} | sed ${file_sed}`}${subj}"
fi

${verbose} ""
${verbose} "subj: ${subj}"
${verbose} ""

if test -f ${output}; then
  echo "file \`${output}' exists; please remove first"
  exit 1
fi
# pid is always 1000 on Windows sh.exe
#build_dir=.Rd2dvi${$}
build_dir=.Rd2dvi
if test -d ${build_dir}; then
  rm -rf ${build_dir} || echo "cannot write to build dir" && exit 2
fi
mkdir ${build_dir}

sed 's/markright{#1}/markboth{#1}{#1}/' \
  ${R_HOME}/doc/manual/Rd.sty > ${build_dir}/Rd.sty

title=${title-"\\R{} documentation}} \\par\\bigskip{{\\Large of ${subj}"}

cat > ${build_dir}/Rd2.tex <<EOF
\\documentclass[${R_PAPERSIZE}paper]{book}
\\usepackage[${R_RD4DVI-ae}]{Rd}
\\usepackage{makeidx}
\\makeindex
\\begin{document}
\\chapter*{}
\\begin{center}
{\\textbf{\\huge ${title}}}
\\par\\medskip{\\large \\today}
\\end{center}
${toc}
EOF

echo "Converting Rd files to LaTeX ..."
for f in ${files}; do
  echo ${f}
  Rcmd Rdconv -t latex ${f} >> ${build_dir}/Rd2.tex
done

cat >> ${build_dir}/Rd2.tex <<EOF
\\printindex
\\end{document}
EOF

echo "Creating ${out_ext} output from LaTeX ..."
cd ${build_dir}
${R_LATEXCMD-latex} Rd2
${R_MAKEINDEXCMD-makeindex} Rd2
${R_LATEXCMD-latex} Rd2
cd ${start_dir}
cp ${build_dir}/Rd2.${out_ext} ${output}
if ${clean}; then
  rm -rf ${build_dir}
else
  echo "You may want to clean up by \`rm -rf ${build_dir}'"
fi
${preview} ${output}
exit 0

### Local Variables: ***
### mode: sh ***
### sh-indentation: 2 ***
### End: ***
