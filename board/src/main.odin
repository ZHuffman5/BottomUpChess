package board

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

import core "../../core/src"

// Configure square size depending on operating system
when ODIN_OS == .Windows
{
    square_size :: 144
    piece_size :: 128
} else
{
    square_size :: 92
    piece_size :: 80
}

padding :: (square_size - piece_size) / 2
screen_width  :: square_size * 8
screen_hieght :: square_size * 8

// The offsets of the piece sprites on the texture atlas
// Check assets/chess_pieces.png to see the texture atlas
b_rook_offsets   :: [2]int{ 0, 1 }
b_knight_offsets :: [2]int{ 1, 1 }
b_bishop_offsets :: [2]int{ 2, 1 }
b_queen_offsets  :: [2]int{ 3, 1 }
b_king_offsets   :: [2]int{ 4, 1 }
b_pawn_offsets   :: [2]int{ 5, 1 }

w_rook_offsets   :: [2]int{ 0, 0 }
w_knight_offsets :: [2]int{ 1, 0 }
w_bishop_offsets :: [2]int{ 2, 0 }
w_queen_offsets  :: [2]int{ 3, 0 }
w_king_offsets   :: [2]int{ 4, 0 }
w_pawn_offsets   :: [2]int{ 5, 0 }

empty_offset :: [2]int{ 6, 0 }

promotion_screen := false
promotion_move   : core.move

// Get the corresponding texture offset from a piece
get_offset_vals :: proc(piece_val: int) -> [2]int
{
    offset_vector : [2]int

    switch piece_val
    {
        case 1: offset_vector = b_pawn_offsets
        case 2: offset_vector = b_bishop_offsets
        case 3: offset_vector = b_knight_offsets
        case 4: offset_vector = b_rook_offsets
        case 5: offset_vector = b_queen_offsets
        case 6: offset_vector = b_king_offsets

        case -1: offset_vector = w_pawn_offsets
        case -2: offset_vector = w_bishop_offsets
        case -3: offset_vector = w_knight_offsets
        case -4: offset_vector = w_rook_offsets
        case -5: offset_vector = w_queen_offsets
        case -6: offset_vector = w_king_offsets

        case: offset_vector = empty_offset
    }
    
    return { (offset_vector.x) * 16, (offset_vector.y) * 16 }
}

// Get the draw coordinates of a square
get_draw_coords :: proc(x: int, y: int) -> [2]f32
{
    x_coord : f32 = f32((x - 1) * square_size) + padding
    y_coord : f32 = f32((y - 1) * square_size) + padding

    return { x_coord, y_coord }
}

mouse_down := false
legal_state := false
highlight_x := 0
highlight_y := 0

moves: [dynamic]core.move

main :: proc()
{
    rl.InitWindow(i32(screen_width), i32(screen_hieght), "chess")
    
    rl.SetTargetFPS(60)

    // Load texture
    chess_texture := rl.LoadTexture("assets/chess_pieces.png")

    piece_width  : f32 = f32(chess_texture.width  / 7)
    piece_height : f32 = f32(chess_texture.height / 5)
    
    // Render loop
    for !rl.WindowShouldClose()
    {
        // Get cursor position
        cursor_pos := rl.GetMousePosition()
        
        current_square_x := int(cursor_pos.x / square_size)
        current_square_y := int(cursor_pos.y / square_size)
        
        rl.BeginDrawing()
        defer rl.EndDrawing()
        
        // Shows this screen if the player has just made a promotion move
        // and needs to choose a piece to promote to
        if promotion_screen == true
        {
            rl.DrawText("Press Q for Queen", 20, 20, 20, rl.WHITE)
            rl.DrawText("Press N for Knight", 20, 50, 20, rl.WHITE)
            rl.DrawText("Press B for Bishop", 20, 80, 20, rl.WHITE)
            rl.DrawText("Press R for Rook", 20, 110, 20, rl.WHITE)
            rl.ClearBackground(rl.BLACK)
            
            destination_piece := 0
            
            if rl.IsKeyPressed(rl.KeyboardKey.Q)
            {
                destination_piece = 5
            } else if rl.IsKeyPressed(rl.KeyboardKey.N)
            {
                destination_piece = 3
            } else if rl.IsKeyPressed(rl.KeyboardKey.B)
            {
                destination_piece = 2
            } else if rl.IsKeyPressed(rl.KeyboardKey.R)
            {
                destination_piece = 4
            }
            
            if destination_piece != 0
            {
                destination_piece *= promotion_move.piece_type / math.abs(promotion_move.piece_type)
                
                using core

                board[row(promotion_move.target)][col(promotion_move.target)] = destination_piece
                board[row(promotion_move.origin)][col(promotion_move.origin)] = 0
                
                promotion_move.piece_type = destination_piece
                state.turn = board_sides(int(state.turn) * -1)

                append(&state.moves, promotion_move)
                
                promotion_screen = false
                mouse_down = false
                legal_state = false

                clear(&moves)
            }

            continue
        }
        
        if rl.IsKeyPressed(rl.KeyboardKey.L)
        {
            core.print_board(core.board)
        }
        
        // Reset the board on the press of the R key
        if rl.IsKeyPressed(rl.KeyboardKey.R)
        {
            core.board = [8][8]int{
                {  4,  3,  2,  5,  6,  2,  3,  4 },
                {  1,  1,  1,  1,  1,  1,  1,  1 },
                {  0,  0,  0,  0,  0,  0,  0,  0 },
                {  0,  0,  0,  0,  0,  0,  0,  0 },
                {  0,  0,  0,  0,  0,  0,  0,  0 },
                {  0,  0,  0,  0,  0,  0,  0,  0 },
                { -1, -1, -1, -1, -1, -1, -1, -1 },
                { -4, -3, -2, -5, -6, -2, -3, -4 },
            }
            
            core.state = core.board_state {
                w_castle_rights = {true, true},
                b_castle_rights = {true, true},
                repetitions = 0,
                turn = core.board_sides.white,
                moves = {
                    (core.move) {
                        origin = u16(core.board_squares.e2),
                        target = u16(core.board_squares.e4),
                        double_push = true,
                    }
                },
            }

            mouse_down = false
            legal_state = false
            highlight_x = 0
            highlight_y = 0
            clear(&moves)
        }

        // If the player has clicked on square
        mouse_event: if rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
        {
            highlight_x = current_square_x
            highlight_y = current_square_y

            // Get the piece corresponding to the square the player has clicked on
            if core.get_piece(u16(highlight_y * 8 + highlight_x), core.board) != 0
            {
                mouse_down = true
            } else
            {
                mouse_down = false
            }
            
            if legal_state == true
            {
                // Loop through moves and checks if the square a player has clicked on
                // is a possible move
                for move in moves
                {
                    // fmt.printf("{:d}\n", move.target)
                    if u16(highlight_y * 8 + highlight_x) == move.target
                    {
                        // If it is a promotion, show the promotion screen
                        if move.promotion == true
                        {
                            promotion_screen = true
                            promotion_move = move
                            mouse_down = false
                            legal_state = false

                            clear(&moves)
                            break mouse_event
                        } else
                        {
                            core.make_move(move)
                        }

                        mouse_down = false
                        legal_state = false

                        clear(&moves)
                        
                        break mouse_event
                    }
                }

                clear(&moves)
            }

            if core.get_piece(u16(highlight_y * 8 + highlight_x), core.board) * int(core.state.turn) > 0
            {
                clear(&moves)
                append(&moves, ..core.gen_moves(u16(highlight_y * 8 + highlight_x))[:])
            }

            if len(moves) > 0
            {
                legal_state = true
            }
            
            // fmt.printf("SQUARE: {:d}\n", u8(highlight_y * 8 + highlight_x))
            // fmt.printf("LEN: {:d}\n", len(moves))
        }

        // Draw all board squares and pieces by looping through the board
        for i := 0; i < 8; i += 1
        {
            for j := 0; j < 8; j += 1
            {
                rl.DrawRectangle(
                    i32(square_size * i),
                    i32(square_size * j),
                    i32(square_size), i32(square_size),
                    hex_to_rgba(0xeeeed2ff) if (i % 2 == j % 2) else hex_to_rgba(0x769656ff))

                // Highlight the piece current clicked on
                if mouse_down == true &&
                    i == highlight_x &&
                    j == highlight_y
                {
                    rl.DrawRectangle(
                        i32(square_size * i),
                        i32(square_size * j),
                        i32(square_size), i32(square_size),
                        hex_to_rgba(0x4d65b4ff))
                }
                
                // Highlight all legal moves
                for move in moves
                {
                    if mouse_down == true &&
                        u16(i) == core.col(move.target) &&
                        u16(j) == core.row(move.target)
                    {
                        rl.DrawRectangle(
                            i32(square_size * i),
                            i32(square_size * j),
                            i32(square_size), i32(square_size),
                            hex_to_rgba(0x425289ff))
                    }
                }
                    
                offset := get_offset_vals(core.board[j][i])
                draw_coords := get_draw_coords(i + 1, j + 1)
                
                source_x : f32 = f32(offset.x)
                source_y : f32 = f32(offset.y)
                
                dest_x, dest_y: f32
                if math.abs(core.board[j][i]) == 1
                {
                    dest_x = f32(draw_coords.x)
                    dest_y = f32(draw_coords.y - 2)
                } else
                {
                    dest_x = f32(draw_coords.x)
                    dest_y = f32(draw_coords.y)
                }
                
                source_rect := rl.Rectangle { source_x, source_y, piece_width, piece_height }
                dest_rect := rl.Rectangle { dest_x, dest_y, f32(piece_size), f32(piece_size) }

                rl.DrawTexturePro(chess_texture, source_rect, dest_rect, { 0, 0 }, 0, rl.WHITE)
            }
        }
    }
    
    rl.CloseWindow()
}

// Convenience function for converting a hexidecimal color value to a Raylib compatible RGB Color struct
hex_to_rgba :: proc(hex_val: int) -> rl.Color
{
    rl_color := rl.Color {
        u8(((hex_val >> 24) & 0xff)),
        u8(((hex_val >> 16) & 0xff)),
        u8(((hex_val >> 8)  & 0xff)),
        u8(((hex_val)       & 0xff)),
    }
    
    return rl_color
}


