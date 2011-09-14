#!/usr/bin/env bash
#

TREMA_DEST=/usr/share/axsh/trema/
echo "Installing Trema to '$TREMA_DEST'."

git clone git://github.com/trema/trema $TREMA_DEST
cd $TREMA_DEST && ./build.rb

echo
echo "Test that Trema runs properly with:"
echo "(cd $TREMA_DEST && ./trema run ./src/examples/learning_switch/learning-switch.rb)"
