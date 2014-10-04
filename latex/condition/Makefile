all: long short

.PHONY: long

.PHONY: short

.PHONY: clean

long: ex_cond_1_long.pdf ex_cond_2_long.pdf

short: ex_cond_1_short.pdf ex_cond_2_short.pdf

ex_cond_1_long.pdf: ex_cond_1.tex
	[ ! -f toggle.tex ] || rm -f toggle.tex 
	echo "\\\\toggletrue{long}" > toggle.tex
	pdflatex -jobname ex_cond_1_long ex_cond_1.tex

ex_cond_1_short.pdf: ex_cond_1.tex
	[ ! -f toggle.tex ] || rm -f toggle.tex 
	echo "\\\\togglefalse{long}" > toggle.tex
	pdflatex -jobname ex_cond_1_short ex_cond_1.tex

ex_cond_2_long.pdf: ex_cond_2.tex
	pdflatex -jobname ex_cond_2_long ex_cond_2.tex

ex_cond_2_short.pdf: ex_cond_2.tex
	pdflatex -jobname ex_cond_2_short ex_cond_2.tex

clean:
	$(RM) ex_cond_1_long.aux ex_cond_1_long.log ex_cond_1_long.pdf \
          ex_cond_1_short.aux ex_cond_1_short.log ex_cond_1_short.pdf \
          ex_cond_2_long.aux ex_cond_2_long.log ex_cond_2_long.pdf \
          ex_cond_2_short.aux ex_cond_2_short.log ex_cond_2_short.pdf \
          toggle.tex
