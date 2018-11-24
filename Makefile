.PHONY: run clean gym clean deepclean upload build view zip

TYPE ?= debug

run: build
	mkdir -p replays
	./halite --replay-directory replays/ -vvv \
		--width 30 --height 30 \
		"RUST_BACKTRACE=1 sample_bot/target/$(TYPE)/my_bot" \
		"RUST_BACKTRACE=1 sample_bot/target/$(TYPE)/my_bot" \
		"RUST_BACKTRACE=1 sample_bot/target/$(TYPE)/my_bot" \
		"RUST_BACKTRACE=1 sample_bot/target/$(TYPE)/my_bot"

build:
	./build_all.sh

release:
	./release_all.sh

clean:
	rm replays/* || true
	ls | grep "bot-\d.log" | xargs rm || true

deepclean:
	./deep_clean.sh

needs_name:
ifndef BOT
	$(error BOT must be defined, example: "BOT=sample_bot make zip")
endif

zip: needs_name clean deepclean
	./make_upload.sh $(BOT)

upload: zip
	# if you have authenticated the client you can uncomment this instead!
	# pipenv run python -m hlt_client bot -b packaged_$(BOT).zip upload
	open -a "Google Chrome" https://halite.io/play-programming-challenge
	open .

bootstrap:
	pipenv --three
	# needed for hlt_client
	pipenv install appdirs
	pipenv install trueskill
	# needed for parsing replay files
	pipenv install zstandard

view:
	# drag and drop your local replay file into the viewer
	open -a "Google Chrome" https://halite.io/watch-games
	open replays/

deregister: needs_name
	yes | pipenv run python -m hlt_client gym deregister "$(BOT)"

register: needs_name
	# for example
	# pipenv run python -m hlt_client gym register DistanceBasedGoalSetter(9.98) "RUST_BACKTRACE=1 DistanceBasedGoalSetter/target/debug/my_bot 9 98"
	pipenv run python -m hlt_client gym register $(BOT) "RUST_BACKTRACE=1 $(BOT)/target/debug/my_bot"

gym: release
	# time pipenv run python -m hlt_client gym --db-path ./pathfinding.db evaluate -b ./halite --output-dir gymming -i 20
	mkdir -p gymming
	time pipenv run python -m hlt_client gym evaluate -b ./halite --output-dir gymming -i 50

bots:
	# pipenv run python -m hlt_client gym --db-path ./pathfinding.db bots
	pipenv run python -m hlt_client gym bots

count_rust:
	./check_rust.sh | python -c 'import json, sys; d = json.loads(sys.stdin.read()); sys.stdout.write(str(len(d)) + "\n")'

# look at other rust users
rank_rust:
	./check_rust.sh | python3 -c 'import json, sys, pprint; d = json.loads(sys.stdin.read()); list(map(print, ["{0}\t{1: <16}{2:10.3f}".format(str(i+1), str(e["username"]), e["score"]) for i, e in enumerate(d)]))'
