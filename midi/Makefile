
.PHONY: all

all: beat.ogg

%.ogg: %.mid
	timidity $< -Ow -o $<.wav
	oggenc -q 3 -o $@ $<.wav