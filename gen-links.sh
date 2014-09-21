cd packages && ln -s ../lib ./web_play && cd -
cd tetris/slave && ln -s ../../packages ./packages && cd -
cd tetris/controller && ln -s ../../packages ./packages && cd -
cd snake/slave && ln -s ../../packages ./packages && cd -
cd snake/controller && ln -s ../../packages ./packages && cd -
cd server && ln -s ../packages ./packages && cd -
rm -rf lib/lib
