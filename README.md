# Chess

Chess implementation in Odin and Raylib

Odin is a programming language created to be a modern alternative to C; Raylib is a rendering library that is a step above Graphics APIs such as OpenGL, while still being much more barebones and low-level than a game engine.

To run the program:

```bash
odin run board/src -out:out/debug/board
```

# Implementation Overview

The chess board is represented by a 2D array of integers with each integer representing a piece. The sign of the number represents whether a piece is white or black, and 0 represents an empty square.

6: Black King \
5: Black Queen \
4: Black Rook \
3: Black Knight \
2: Black Bishop \
1: Black Pawn \
-1: White Pawn \
-2: White Bishop \
-3: White Knight \
-4: White Rook \
-5: White Queen \
-6: White King

Each piece has a move generation function that generates all the pseudolegal moves possible in a position. Pseudolegal moves are moves that a piece can make that does not consider king attacks and checks.

When the player clicks on a piece, the move generation function for that particular piece is called. The program then loops through every move and checks if it is legal. Legality of a candidate move is checked by duplicating the board array, making that particular move, and checking if your king can be captured by the opponent. If the king can be captured, then the move was illegal. This strategy handles checks, double checks, discovered checks, checkmates, and stalemates, as all moves that do not directly handle a king attack are automatically discarded.

The board is rendered in an infinite loop that is ended when the program is closed. Raylib provides functions for rendering textures, squares, and text, which is all that this program needs.

En passant, Castling, Promotion are all properly handled and implemented.

