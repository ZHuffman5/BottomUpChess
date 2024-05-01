package core

import "core:fmt"
import "core:math"

red    :: "\x1B[38;2;247;118;142m"
blue   :: "\x1B[38;2;125;207;255m"
green  :: "\x1B[38;2;158;206;106m"
yellow :: "\x1B[38;2;224;175;104m"
reset  :: "\x1B[0m"

board := [8][8]int{
    {  4,  3,  2,  5,  6,  2,  3,  4 },
    {  1,  1,  1,  1,  1,  1,  1,  1 },
    {  0,  0,  0,  0,  0,  0,  0,  0 },
    {  0,  0,  0,  0,  0,  0,  0,  0 },
    {  0,  0,  0,  0,  0,  0,  0,  0 },
    {  0,  0,  0,  0,  0,  0,  0,  0 },
    { -1, -1, -1, -1, -1, -1, -1, -1 },
    { -4, -3, -2, -5, -6, -2, -3, -4 },
}

get_piece :: proc(idx: u16, b: [8][8]int) -> int
{
    return b[row(idx)][col(idx)]
}

board_squares :: enum u16 {
    a8, b8, c8, d8, e8, f8, g8, h8,
    a7, b7, c7, d7, e7, f7, g7, h7,
    a6, b6, c6, d6, e6, f6, g6, h6,
    a5, b5, c5, d5, e5, f5, g5, h5,
    a4, b4, c4, d4, e4, f4, g4, h4,
    a3, b3, c3, d3, e3, f3, g3, h3,
    a2, b2, c2, d2, e2, f2, g2, h2,
    a1, b1, c1, d1, e1, f1, g1, h1,
}

board_sides :: enum
{
    black =  1,
    white = -1,
}

move :: struct
{
    origin: u16,
    target: u16,

    double_push: bool,

    piece_type: int,

    en_passant: bool,
    /*
    castle: bool,
    */
}

board_state :: struct
{
    w_castle_rights: [2]bool,
    b_castle_rights: [2]bool,
    
    repetitions: int,
    moves: [dynamic]move,

    turn: board_sides
}

state := board_state {
    w_castle_rights = {true, true},
    b_castle_rights = {true, true},
    repetitions = 0,
    turn = board_sides.white,
    moves = {
        (move) {
            origin = u16(board_squares.e2),
            target = u16(board_squares.e4),
            double_push = true,
        }
    },
}

sum :: proc(s1: u16, s2: u16) -> u16
{
    if s1 + s2 > 7
    {
        return s1
    } else
    {
        return s1 + s2
    }
}

diff :: proc(s1: u16, s2: u16) -> u16
{
    if s1 - s2 < 0
    {
        return s1
    } else
    {
        return s1 - s2
    }
}

col :: proc(s: u16) -> u16
{
    return s % 8
}

row :: proc(s: u16) -> u16
{
    return s / 8
}

bit_val :: proc(bitboard: u64, square: board_squares) -> u64
{
    return bitboard & (u64(1) << u16(square))
}

files := [8]int{ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', }
ranks := [8]int{  1,   2,   3,   4,   5,   6,   7,   8,  }

pawn_moves :: proc(b: [8][8]int, side: board_sides, square: u16) -> [dynamic]u16
{
    targets: [dynamic]u16
    last_move := state.moves[len(state.moves) - 1]
    
    switch side
    {
        case .black:
        {
            assert(row(square) != 7, "Illegal position: black pawn at 1st rank")

            if col(square) != 0 &&
                get_piece(square + 7, b) < 0
            {
                append(&targets, square + 7)
            }
            
            if col(square) != 7 &&
                get_piece(square + 9, b) < 0
            {
                append(&targets, square + 9)
            }
            
            if get_piece(square + 8, b) == 0
            {
                append(&targets, square + 8)
            }

            if row(square) == 4 &&
                last_move.double_push == true
            {
                if int(col(last_move.target)) == int(col(square) + 1)
                {
                    append(&targets, square + 9 + 200)
                }

                if int(col(last_move.target)) == int(col(square) - 1)
                {
                    append(&targets, square + 7 + 200)
                }
            }
            
            if row(square) == 1
            {
                if get_piece(square + 8, b) == 0 &&
                    get_piece(square + 16, b) == 0
                {
                    append(&targets, square + 16 + 100)
                }
            }
        }

        case .white:
        {
            assert(row(square) != 0, "Illegal position: white pawn at 7th rank")

            if col(square) != 0 &&
                get_piece(square - 9, b) > 0
            {
                append(&targets, square - 9)
            }
            
            if col(square) != 7 &&
                get_piece(square - 7, b) > 0
            {
                append(&targets, square - 7)
            }
            
            if get_piece(square - 8, b) == 0
            {
                append(&targets, square - 8)
            }

            if row(square) == 3 &&
                last_move.double_push == true
            {
                if int(col(last_move.target)) == int(col(square) + 1)
                {
                    append(&targets, square - 7 + 200)
                }

                if int(col(last_move.target)) == int(col(square) - 1)
                {
                    append(&targets, square - 9 + 200)
                }
            }
            
            if row(square) == 6
            {
                if get_piece(square - 8, b) == 0 &&
                    get_piece(square - 16, b) == 0
                {
                    append(&targets, square - 16 + 100)
                }
            }
        }
    }
    
    return targets
}

pawn_attacks :: proc(side: board_sides, square: u16) -> [dynamic]u16
{
    targets: [dynamic]u16
    last_move := state.moves[len(state.moves) - 1]
    
    switch side
    {
        case .black:
        {
            assert(row(square) != 7, "Illegal position: black pawn at 1st rank")

            if col(square) != 0
            {
                append(&targets, square + 7)
            }
            
            if col(square) != 7
            {
                append(&targets, square + 9)
            }
        }

        case .white:
        {
            assert(row(square) != 0, "Illegal position: white pawn at 7th rank")

            if col(square) != 0
            {
                append(&targets, square - 9)
            }

            if col(square) != 7
            {
                append(&targets, square - 7)
            }
        }
    }
    
    return targets
}

knight_moves :: proc(b: [8][8]int, side: board_sides, square: u16) -> [dynamic]u16
{
    targets: [dynamic]u16
    last_move := state.moves[len(state.moves) - 1]
    
    if col(square) != 0
    {
        if row(square) > 1
        {
            if get_piece(square - 17, b) * int(side) <= 0
            {
                append(&targets, square - 17)
            }
        }

        if row(square) < 6
        {
            if get_piece(square + 15, b) * int(side) <= 0
            {
                append(&targets, square + 15)
            }
        }
        
        if col(square) != 1
        {
            if row(square) != 0
            {
                if get_piece(square - 10, b) * int(side) <= 0
                {
                    append(&targets, square - 10)
                }
            }

            if row(square) != 7
            {
                if get_piece(square + 6, b) * int(side) <= 0
                {
                    append(&targets, square + 6)
                }
            }
        }
    }

    if col(square) != 7
    {
        if row(square) > 1
        {
            if get_piece(square - 15, b) * int(side) <= 0
            {
                append(&targets, square - 15)
            }
        }

        if row(square) < 6
        {
            if get_piece(square + 17, b) * int(side) <= 0
            {
                append(&targets, square + 17)
            }
        }
        
        if col(square) != 6 
        {
            if row(square) != 0
            {
                if get_piece(square - 6, b) * int(side) <= 0
                {
                    append(&targets, square - 6)
                }
            }

            if row(square) != 7
            {
                if get_piece(square + 10, b) * int(side) <= 0
                {
                    append(&targets, square + 10)
                }
            }
        }
    }
    
    return targets
}

bishop_moves :: proc(b: [8][8]int, side: board_sides, square: u16) -> [dynamic]u16
{
    targets: [dynamic]u16
    last_move := state.moves[len(state.moves) - 1]
    
    origin_row := row(square)
    origin_col := col(square)
    
    if row(square) != 7 && col(square) != 7
    {
        target_row := int(origin_row + 1)
        target_col := int(origin_col + 1)
        for target_row < 8 && target_col < 8
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_row += 1
            target_col += 1
        }
    }
    
    if row(square) != 0 && col(square) != 0
    {
        target_row := int(origin_row - 1)
        target_col := int(origin_col - 1)
        for target_row >= 0 && target_col >= 0
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_row -= 1
            target_col -= 1
        }
    }
    
    if row(square) != 7 && col(square) != 0
    {
        target_row := int(origin_row + 1)
        target_col := int(origin_col - 1)
        for target_row < 8 && target_col >= 0
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_row += 1
            target_col -= 1
        }
    }

    if row(square) != 0 && col(square) != 7
    {
        target_row := int(origin_row - 1)
        target_col := int(origin_col + 1)
        for target_row >= 0 && target_col < 8
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_row -= 1
            target_col += 1
        }
    }
    
    return targets
}

rook_moves :: proc(b: [8][8]int, side: board_sides, square: u16) -> [dynamic]u16
{
    targets: [dynamic]u16
    last_move := state.moves[len(state.moves) - 1]
    
    origin_row := row(square)
    origin_col := col(square)
    
    if row(square) != 7 
    {
        target_row := int(origin_row + 1)
        target_col := int(origin_col)
        for target_row < 8
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_row += 1
        }
    }
    
    if row(square) != 0
    {
        target_row := int(origin_row - 1)
        target_col := int(origin_col)
        for target_row >= 0
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_row -= 1
        }
    }
    
    if col(square) != 0
    {
        target_row := int(origin_row)
        target_col := int(origin_col - 1)
        for target_col >= 0
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_col -= 1
        }
    }

    if col(square) != 7
    {
        target_row := int(origin_row)
        target_col := int(origin_col + 1)
        for target_col < 8
        {
            current_idx := target_row * 8 + target_col
            current_piece := get_piece(u16(current_idx), b)
            
            if current_piece * int(side) > 0
            {
                break
            }
            
            append(&targets, u16(current_idx))
            
            if current_piece * int(side) < 0
            {
                break
            }

            target_col += 1
        }
    }
    
    return targets
}

queen_moves :: proc(b: [8][8]int, side: board_sides, square: u16) -> [dynamic]u16
{
    targets: [dynamic]u16
    last_move := state.moves[len(state.moves) - 1]
    
    rook_targets   := rook_moves(b, side, square)
    bishop_targets := bishop_moves(b, side, square)
    
    append(&targets, ..rook_targets[:])
    append(&targets, ..bishop_targets[:])

    return targets
}

king_moves :: proc(b: [8][8]int, side: board_sides, square: u16) -> [dynamic]u16
{
    targets: [dynamic]u16
    last_move := state.moves[len(state.moves) - 1]
    
    if row(square) != 0
    {
        if get_piece(square - 8, b) * int(side) <= 0
        {
            append(&targets, square - 8)
        }
        
        if col(square) != 0
        {
            if get_piece(square - 9, b) * int(side) <= 0
            {
                append(&targets, square - 9)
            }
        }
        
        if col(square) != 7
        {
            if get_piece(square - 7, b) * int(side) <= 0
            {
                append(&targets, square - 7)
            }
        }
    }

    if col(square) != 0
    {
        if get_piece(square - 1, b) * int(side) <= 0
        {
            append(&targets, square - 1)
        }
    }

    if col(square) != 7
    {
        if get_piece(square + 1, b) * int(side) <= 0
        {
            append(&targets, square + 1)
        }
    }

    if row(square) != 7
    {
        if get_piece(square + 8, b) * int(side) <= 0
        {
            append(&targets, square + 8)
        }
        
        if col(square) != 0
        {
            if get_piece(square + 7, b) * int(side) <= 0
            {
                append(&targets, square + 7)
            }
        }

        if col(square) != 7
        {
            if get_piece(square + 9, b) * int(side) <= 0
            {
                append(&targets, square + 9)
            }
        }
    }
    
    /*
    switch side
    {
        case .black: {
            if state.b_castle_rights[0] == true
            {
                if get_piece(1, b) == 0 &&
                    get_piece(2, b) == 0 &&
                    get_piece(3, b) == 0
                {
                    castling_targets : u64 = 0x1e
                    attacks := sum_attack(side, board)
                    
                    if castling_targets & attacks == 0
                    {
                        append(&targets, square - 2 + 300)
                    }
                }
            }
            
            if state.b_castle_rights[1] == true
            {
                if get_piece(5, b) == 0 &&
                    get_piece(6, b) == 0
                {
                    castling_targets : u64 = 0x70
                    attacks := sum_attack(side, board)
                    
                    if castling_targets & attacks == 0
                    {
                        append(&targets, square + 2 + 300)
                    }
                }
            }
        }
        case .white: {
            if state.w_castle_rights[0] == true
            {
                if get_piece(57, b) == 0 &&
                    get_piece(58, b) == 0 &&
                    get_piece(59, b) == 0
                {
                    castling_targets : u64 = 0x1e00000000000000
                    attacks := sum_attack(side, board)
                    
                    if castling_targets & attacks == 0
                    {
                        append(&targets, square - 2 + 300)
                    }
                }
            }
            
            if state.b_castle_rights[1] == true
            {
                if get_piece(61, b) == 0 &&
                    get_piece(62, b) == 0
                {
                    castling_targets : u64 = 0x7000000000000000
                    attacks := sum_attack(side, board)
                    
                    if castling_targets & attacks == 0
                    {
                        append(&targets, square + 2 + 300)
                    }
                }
            }
        }
    }
    */
    
    return targets
}

sum_attack :: proc(side: board_sides, p_board: [8][8]int) -> u64
{
    targets: [dynamic]u16
    opposing_side := board_sides(int(side) * -1)
    
    // fmt.printf("[11] Piece: {:d}\n", p_board[1][3])
    // fmt.printf("Test: {:d}\n", p_board[1][3] * int(side))
    for i := 0; i < 8; i += 1
    {
        for j := 0; j < 8; j += 1
        {
            if p_board[i][j] * int(side) < 0
            {
                // fmt.printf("LOG: index {:d}, type {:d}\n", i * 8 + j, p_board[i][j])

                switch math.abs(p_board[i][j])
                {
                    case 1: {
                        append(&targets, ..pawn_attacks(opposing_side, u16(i * 8 + j))[:])
                    }
                    case 2: {
                        append(&targets, ..bishop_moves(p_board, opposing_side, u16(i * 8 + j))[:])
                    }
                    case 3: {
                        append(&targets, ..knight_moves(p_board, opposing_side, u16(i * 8 + j))[:])
                    }
                    case 4: {
                        append(&targets, ..rook_moves(p_board, opposing_side, u16(i * 8 + j))[:])
                    }
                    case 5: {
                        append(&targets, ..queen_moves(p_board, opposing_side, u16(i * 8 + j))[:])
                    }
                    case 6: {
                        append(&targets, ..king_moves(p_board, opposing_side, u16(i * 8 + j))[:])
                    }

                    case: {}
                }
            }
        }
    }

    bitboard: u64 = 0
    
    for square in targets
    {
        bitboard |= u64(1) << u16(square % 100)
    }
    
    return bitboard
}

test_position :: proc(side: board_sides, p_board: [8][8]int) -> bool
{
    attacks := sum_attack(side, p_board)
    print_bitboard(attacks)
    king_pos: int
    
    for i := 0; i < 8; i += 1
    {
        for j := 0; j < 8; j += 1
        {
            if p_board[i][j] == int(side) * 6
            {
                king_pos = i * 8 + j
            }
        }
    }
    
    king_bitboard := u64(1) << u16(king_pos)
    print_bitboard(king_bitboard)
    
    if king_bitboard & attacks == 0
    {
        return true
    } else
    {
        return false
    }
}

square_to_moves :: proc(
    targets:   [dynamic]u16,
    piece_val: int,
    origin:    u16,
) -> [dynamic]move
{
    moves: [dynamic]move

    for target in targets
    {
        append(&moves, (move) {
            origin = origin,
            target = target % 100,
            piece_type = piece_val,

            /*
            castle = true if (target / 100 == 3) else false,
            */

            en_passant = true if (target / 100 == 2) else false,
            double_push = true if (target / 100 == 1) else false,
        })
    }
    
    return moves
}

gen_pseudo_legal :: proc(square: u16, side: board_sides) -> [dynamic]move
{
    moves: [dynamic]move
    
    if get_piece(square, board) * int(side) > 0
    {
        switch math.abs(get_piece(square, board))
        {
            case 1: {
                squares := pawn_moves(board, side, square)
                append(&moves, ..square_to_moves(squares, get_piece(square, board), square)[:])
            }
            case 2: {
                squares := bishop_moves(board, side, square)
                append(&moves, ..square_to_moves(squares, get_piece(square, board), square)[:])
            }
            case 3: {
                squares := knight_moves(board, side, square)
                append(&moves, ..square_to_moves(squares, get_piece(square, board), square)[:])
            }
            case 4: {
                squares := rook_moves(board, side, square)
                append(&moves, ..square_to_moves(squares, get_piece(square, board), square)[:])
            }
            case 5: {
                squares := queen_moves(board, side, square)
                append(&moves, ..square_to_moves(squares, get_piece(square, board), square)[:])
            }
            case 6: {
                squares := king_moves(board, side, square)
                print_targets(squares)
                append(&moves, ..square_to_moves(squares, get_piece(square, board), square)[:])
            }

            case: {}
        }
    }
    
    return moves
}

test_move :: proc(m: move) -> bool
{
    temp_board := board
    
    temp_board[row(m.target)][col(m.target)] = temp_board[row(m.origin)][col(m.origin)]
    temp_board[row(m.origin)][col(m.origin)] = 0

    if m.en_passant == true
    {
        last_move := state.moves[len(state.moves) - 1]
        temp_board[row(last_move.target)][col(last_move.target)] = 0
    }
    
    return test_position(board_sides(m.piece_type / math.abs(m.piece_type)), temp_board)
}

gen_moves :: proc(square: u16) -> [dynamic]move
{
    moves: [dynamic]move
    
    append(&moves, 
        ..gen_pseudo_legal(square, board_sides(get_piece(square, board) / math.abs(get_piece(square, board))))[:],
    )
    
    fmt.printf("{:s}LEN: {:d}\n{:s}", green, len(moves), reset)
    
    for i := 0; i < len(moves); i += 1
    {
        fmt.printf("{:s}Index: {:d}{:s}\n", yellow, i, reset)
        fmt.printf("{:s}Move Origin: {:d}{:s}\n", yellow, moves[i].origin, reset)
        fmt.printf("{:s}Move Target: {:d}{:s}\n", yellow, moves[i].target, reset)
        if test_move(moves[i]) == false
        {
            ordered_remove(&moves, i)
            i -= 1
        }
    }
    
    return moves
}

make_move :: proc(m: move)
{
    if m.en_passant == true
    {
        last_move := state.moves[len(state.moves) - 1]
        board[row(last_move.target)][col(last_move.target)] = 0
    }
    
    /*
    if m.castle == true
    {
        if m.piece_type < 0
        {
            if int(m.origin) - int(m.target) == -2
            {
                board[0][0] = 0
                board[0][3] = -4
            } else if m.origin - m.target == 2
            {
                board[0][7] = 0
                board[0][5] = -4
            }
        } else if m.piece_type > 0
        {
            if int(m.origin) - int(m.target) == -2
            {
                board[7][0] = 0
                board[7][3] = 4
            } else if m.origin - m.target == 2
            {
                board[7][7] = 0
                board[7][5] = 4
            }
        }
    }
    
    switch m.piece_type
    {
        case 4: {
            if m.origin == 0
            {
                state.b_castle_rights[0] = false
            } else if m.origin == 7
            {
                state.b_castle_rights[1] = false
            }
        }
        case -4: {
            if m.origin == 56
            {
                state.w_castle_rights[0] = false
            } else if m.origin == 63
            {
                state.w_castle_rights[1] = false
            }
        }
        case -6: {
            state.b_castle_rights[0] = false
            state.b_castle_rights[1] = false
        }
        case 6: {
            state.w_castle_rights[0] = false
            state.w_castle_rights[1] = false
        }
        case: {}
    }

    if state.b_castle_rights[0] == true &&
        m.target == 0 
    {
        state.w_castle_rights[0] = false
    }

    if state.b_castle_rights[1] == true &&
        m.target == 7
    {
        state.w_castle_rights[1] = false
    }
    
    if state.w_castle_rights[0] == true &&
        m.target == 56
    {
        state.w_castle_rights[0] = false
    }

    if state.w_castle_rights[1] == true &&
        m.target == 63
    {
        state.w_castle_rights[1] = false
    }
    */
    
    board[row(m.target)][col(m.target)] = board[row(m.origin)][col(m.origin)]
    board[row(m.origin)][col(m.origin)] = 0

    append(&state.moves, m)
    
    state.turn = board_sides(int(state.turn) * -1)
}

print_bitboard :: proc(bitboard: u64)
{
    fmt.printf("{:s}{:s}{:s}{:s}{:s}",
        "   ",
        "+ --- + --- + --- + --- ",
        "+ --- + --- + --- + --- +",
        "\n", "8  |  ",
    )

    for shift in 0..=63
    {
        if bit_val(bitboard, cast(board_squares) shift) == 0
        {
            fmt.printf("{:s}0{:s}", blue, reset);
        } else
        {
            fmt.printf("{:s}1{:s}", red, reset);
        }

        fmt.printf("  |  ")

        if (shift + 1) % 8 == 0
        {
            fmt.printf("{:s}{:s}{:s}{:s}",
                "\n   ",
                "+ --- + --- + --- + --- ",
                "+ --- + --- + --- + --- +",
                "\n",
            )

            if shift != 63
            {
                fmt.printf("{:d}  ", ranks[7 - shift / 8 - 1])
                fmt.printf("|  ")
            }
        }
    }

    fmt.printf("    ")
    for col_idx in 0..=7
    {
        fmt.printf("  ")
        fmt.printf("{:c}", files[col_idx])
        fmt.printf("   ")
    }
    fmt.printf("\n")

    fmt.printf("\n")
    fmt.printf("Bitboard: {:s}{:d}{:s}\n", green, bitboard, reset)
    fmt.printf("Bitboard: {:s}0x{:16x}{:s}\n", yellow, bitboard, reset)
}

print_targets :: proc(targets: [dynamic]u16)
{
    fmt.printf("{:s}{:s}{:s}{:s}{:s}",
        "   ",
        "+ --- + --- + --- + --- ",
        "+ --- + --- + --- + --- +",
        "\n", "8  |  ",
    )
    
    board: [64]int
    
    for target in targets
    {
        board[target % 100] = 1
    }

    for shift in 0..=63
    {
        if board[shift] == 0
        {
            fmt.printf("{:s}0{:s}", blue, reset);
        } else
        {
            fmt.printf("{:s}1{:s}", red, reset);
        }

        fmt.printf("  |  ")

        if (shift + 1) % 8 == 0
        {
            fmt.printf("{:s}{:s}{:s}{:s}",
                "\n   ",
                "+ --- + --- + --- + --- ",
                "+ --- + --- + --- + --- +",
                "\n",
            )

            if shift != 63
            {
                fmt.printf("{:d}  ", ranks[7 - shift / 8 - 1])
                fmt.printf("|  ")
            }
        }
    }

    fmt.printf("    ")
    for col_idx in 0..=7
    {
        fmt.printf("  ")
        fmt.printf("{:c}", files[col_idx])
        fmt.printf("   ")
    }
    fmt.printf("\n")

    fmt.printf("\n")
}

print_board :: proc(p_board: [8][8]int)
{
    fmt.printf("{:s}{:s}{:s}{:s}{:s}",
        "   ",
        "+ --- + --- + --- + --- ",
        "+ --- + --- + --- + --- +",
        "\n", "8  |  ",
    )
    
    b: [64]int
    
    for i := 0; i < 8; i += 1
    {
        for j := 0; j < 8; j += 1
        {
            b[i * 8 + j] = p_board[i][j]
        }
    }

    for shift in 0..=63
    {
        switch b[shift]
        {
            case 1: {
                fmt.printf("{:s}P{:s}", red, reset);
            }
            case 2: {
                fmt.printf("{:s}B{:s}", red, reset);
            }
            case 3: {
                fmt.printf("{:s}N{:s}", red, reset);
            }
            case 4: {
                fmt.printf("{:s}R{:s}", red, reset);
            }
            case 5: {
                fmt.printf("{:s}Q{:s}", red, reset);
            }
            case 6: {
                fmt.printf("{:s}K{:s}", red, reset);
            }

            case -1: {
                fmt.printf("{:s}p{:s}", red, reset);
            }
            case -2: {
                fmt.printf("{:s}b{:s}", red, reset);
            }
            case -3: {
                fmt.printf("{:s}n{:s}", red, reset);
            }
            case -4: {
                fmt.printf("{:s}r{:s}", red, reset);
            }
            case -5: {
                fmt.printf("{:s}q{:s}", red, reset);
            }
            case -6: {
                fmt.printf("{:s}q{:s}", red, reset);
            }

            case: {
                fmt.printf("{:s}0{:s}", blue, reset);
            }
        }

        fmt.printf("  |  ")

        if (shift + 1) % 8 == 0
        {
            fmt.printf("{:s}{:s}{:s}{:s}",
                "\n   ",
                "+ --- + --- + --- + --- ",
                "+ --- + --- + --- + --- +",
                "\n",
            )

            if shift != 63
            {
                fmt.printf("{:d}  ", ranks[7 - shift / 8 - 1])
                fmt.printf("|  ")
            }
        }
    }

    fmt.printf("    ")
    for col_idx in 0..=7
    {
        fmt.printf("  ")
        fmt.printf("{:c}", files[col_idx])
        fmt.printf("   ")
    }
    fmt.printf("\n")

    fmt.printf("\n")
}

main :: proc()
{
    moves: [dynamic]move
    
    append(&moves, ..gen_moves(52)[:])
    
    fmt.printf("FINAL: {:d}\n", len(moves))
    for m in moves
    {
        fmt.printf("FINAL: {:d}\n", m.target)
    }
}

