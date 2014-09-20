cd packages && ln -s ../lib ./web_play && cd -
cd tetris/slave && ln -s ../../packages ./packages && ln -s ../shared ./shared && cd -
cd tetris/controller && ln -s ../../packages ./packages && ln -s ../shared ./shared && cd -
cd server && ln -s ../packages ./packages && cd -
