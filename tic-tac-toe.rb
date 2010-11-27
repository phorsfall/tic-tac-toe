def game_loop(p1, p2, tree)
  draw_board(tree.first)
  loop do
    [p1, p2].each do |p|
      tree = turn(p, tree)
      draw_board(tree.first)
      if tree.last == :game_over
        puts "Game over!"
        return
      elsif tree.last.empty?
        puts "Game drawn!"
        return
      end
    end
  end
end

def human_player(name)
  ->(tree) do
    puts "Your move #{name} (Enter 1-9)"
    move = gets.chomp.to_i-1
    redo unless tree.last.keys.include?(move)
    move
  end
end

def computer_player(name)
  ->(tree) do
    puts "#{name} to move"
    player = tree[1] # 0/1
    pick_move(tree, player, true)
  end
end

def random_player(name)
  ->(tree) do
    puts "#{name} to move"
    tree.last.keys.sample
  end
end

def turn(player, tree)
  tree.last[player.call(tree)]
end

def draw_board(board)
  board.each_with_index do |cell, ix|
    print "  "
    draw_cell(cell)
    print "  "
    print (ix+1) % 3 == 0 ? "\n\n" : "|"
  end
end

def draw_cell(cell)
  print({ 1 => "X", 2 => "O" }[cell] || ".")
end

def init_board
  Array.new(9, nil)
end

def game_won?(board)
  lines = []
  lines << board[0..2] << board[3..5] << board[6..8]
  lines << [board[0], board[3], board[6]]
  lines << [board[1], board[4], board[7]]
  lines << [board[2], board[5], board[8]]
  lines << [board[0], board[4], board[8]]
  lines << [board[2], board[4], board[6]]
  lines.any? { |line| line.uniq.length == 1 && !line.first.nil? }
end

$tree_cache = Hash.new({})

def game_tree(board, player = 1)
  $tree_cache[player][board] ||= begin
    moves = if game_won?(board)
      :game_over
    else
      compute_moves(board, player)
    end
    [board, player, moves]
  end
end

def compute_moves(board, player)
  moves = {}
  board.each_with_index do |cell, ix|
    if cell.nil?
      next_board = board.dup
      next_board[ix] = player
      moves[ix] = game_tree(next_board, player == 1 ? 2 : 1)
    end
  end
  moves
end

def pick_move(tree, player, top = false)
  scored_moves = tree.last.map do |move, subtree|
    [move, score_position(subtree, player)]
  end
  puts scored_moves.inspect if top
  # Min/max.
  minmax = scored_moves.minmax_by(&:last)
  (tree[1] == player) ? minmax.last.first : minmax.first.first
end

def score_position(tree, player)
  if tree.last == :game_over
    if tree[1] == player
      0 # This player lost.
    else
      2 # This player one.
    end
  elsif tree.last.empty?
    1 # Draw
  else
    move = pick_move(tree, player)
    score_position(tree.last[move], player)
  end
end

p1 = human_player("Human")
p2 = computer_player("Computer")

tree = game_tree(init_board)
game_loop(p1, p2, tree)
