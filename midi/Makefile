
.PHONY: all

all: beat.ogg 1.ogg 2.ogg

%.ogg: %.mid
	timidity $< -Ow -o $<.wav
	sox $<.wav $<.loud.wav compand 0.3,1 6:-70,-60,-20 -5 -90 0.2
	oggenc -q 3 -o $@ $<.loud.wav

%.ogg: %.wav
	oggenc -q 3 -o $@ $<