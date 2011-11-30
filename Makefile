NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

dev: js
	@coffee -wc --bare -o lib src

js:
	@coffee -o lib -c src

clean:
	@rm -fr lib/

all: js

.PHONY: all dev js clean
