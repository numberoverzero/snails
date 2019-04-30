.PHONY: help clean build check publish

help:
	@echo "make check: validate packaging before upload"
	@echo "make publish: release to pypi"

clean:
	rm -fr build dist .egg snails.egg-info

build: clean
	python setup.py sdist bdist_wheel

check: build
	twine check dist/*

publish: check
	twine upload dist/*
