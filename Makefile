.PHONY: help publish

help:
	@echo "run make publish to upload"

publish:
	rm -fr build dist .egg snails.egg-info
	python setup.py sdist bdist_wheel
	twine check dist/*
	twine upload dist/*
