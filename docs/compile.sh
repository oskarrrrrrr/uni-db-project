#!/bin/bash

readonly ERD=erd

pdflatex ERD.tex -halt-on-error -draftmode
pdflatex ERD.tex -halt-on-error

