file_path="/home/shunsuke/sueda_lab/siryou/shuron/suzuki"
all:
	cd $(file_path)
	platex -interaction=nonstopmode main.tex
	dvipdfmx main
	firefox main.pdf &
p:
	cd $(file_path)
	platex main.tex
d:
	cd $(file_path)
	dvipdfmx main
pdf:
	cd $(file_path)
	acroread main.pdf &