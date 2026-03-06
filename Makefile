README.md: README.pod
	pod2markdown README.pod | perl -pe 's/^\s+\*/*/; s/^\(/![example](/' > README.md
