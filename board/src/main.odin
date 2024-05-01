package board

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

import core "../../core/src"

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

    chess_texture := rl.LoadTexture("assets/chess_pieces.png")

    piece_width  : f32 = f32(chess_texture.width  / 7)
    piece_height : f32 = f32(chess_texture.height / 5)
    
    for !rl.WindowShouldClose()
    {
        cursor_pos := rl.GetMousePosition()
        
        current_square_x := int(cursor_pos.x / square_size)
        current_square_y := int(cursor_pos.y / square_size)
        
        rl.BeginDrawing()
        defer rl.EndDrawing()
        
        if rl.IsKeyPressed(rl.KeyboardKey.L)
        {
            core.print_board(core.board)
        }
        
        mouse_event: if rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
        {
            highlight_x = current_square_x
            highlight_y = current_square_y

            if core.get_piece(u16(highlight_y * 8 + highlight_x), core.board) != 0
            {
                mouse_down = true
            } else
            {
                mouse_down = false
            }
            
            if legal_state == true
            {
                for move in moves
                {
                    // fmt.printf("{:d}\n", move.target)
                    if u16(highlight_y * 8 + highlight_x) == move.target
                    {
                        core.make_move(move)
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

        for i := 0; i < 8; i += 1
        {
            for j := 0; j < 8; j += 1
            {
                rl.DrawRectangle(
                    i32(square_size * i),
                    i32(square_size * j),
                    i32(square_size), i32(square_size),
                    hex_to_rgba(0xeeeed2ff) if (i % 2 == j % 2) else hex_to_rgba(0x769656ff))

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


