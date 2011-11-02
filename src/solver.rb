# This class find the solutions of a Bejeweled table.
# It uses a colorname matrix to find all the possible movements and the best movement to be played.

class Solver

    def initialize(table, debug)
        @table = table
		@debug = debug
    end

	# Find the next move to be played.
    def find_next_movement
        square_x, square_y, direction = find_next_square_movement
        puts "Solver: next mvt = square_x: #{square_x}, square_y: #{square_y} -> dir: #{direction}" if @debug
        return @table.get_movement_coords(square_x, square_y, direction)
    end

	# Simulate a movement on the table.
	# Generate new state matrix from the initial state where a move
	# in a specific direction occurs on position x,y.
	def generate_move(table, pos_x, pos_y, direction, debug)
		if debug
			str = table.to_s
			puts "generate_move #{pos_x},#{pos_y},#{direction} in \n#{str}"
		end
		vals = nil
        case direction
        when :right
			return nil unless pos_x.between?(0, @table.table_size - 2)
			vals = Marshal.load(Marshal.dump(table.matrix))
			vals[pos_y][pos_x], vals[pos_y][pos_x+1] = vals[pos_y][pos_x+1], vals[pos_y][pos_x] 
			
        when :left
			return nil unless pos_x.between?(1, @table.table_size - 1)
			vals = Marshal.load(Marshal.dump(table.matrix))
			vals[pos_y][pos_x], vals[pos_y][pos_x-1] = vals[pos_y][pos_x-1], vals[pos_y][pos_x] 

        when :down
			return nil unless pos_y.between?(0, @table.table_size - 2)
			vals = Marshal.load(Marshal.dump(table.matrix))
			vals[pos_y][pos_x], vals[pos_y+1][pos_x] = vals[pos_y+1][pos_x], vals[pos_y][pos_x] 

        when :up
			return nil unless pos_y.between?(1, @table.table_size - 1)
			vals = Marshal.load(Marshal.dump(table.matrix))
			vals[pos_y][pos_x], vals[pos_y-1][pos_x] = vals[pos_y-1][pos_x], vals[pos_y][pos_x] 
		end
		table = Table.new
		table.matrix = vals
		return table
	end

	# Compute the score of the current table 
	# - if the direction of the movement is :left or :right, look at jewels at columns x and x-1 or x+1,
	# - if the direction of the movement is :down or :up,    look at jewels at lines y and y+1 or y-1
	def compute_score(table, x, y, dir, debug)
		if debug
			str = table.to_s
			puts "compute score #{x} #{y} #{dir} de :\n#{str}\n"
		end
		score_max = 1
		color_max = nil

		# Find how many lines we have to look at
		lines_to_search = [y]
		if dir == :down
 			# Search bottom line if possible
			if y < @table.table_size - 1
				lines_to_search += [y+1]
			end
		elsif dir == :up
 			# Search up line if possible
			if y > 0
				lines_to_search += [y-1]
			end
		end

		# Look at every jewel in these lines
		lines_to_search.each do |j|
			current_color = nil
			current_score = 1
			for i in 0..(@table.table_size - 1)
				if table.matrix[j][i] != current_color
					if current_score > score_max
						score_max = current_score
						color_max = current_color
					end
					current_color = table.matrix[j][i]
					current_score = 1
				else
					current_score += 1
				end
				puts "current_color=#{current_color}, score=#{current_score}" if debug
			end
			if debug
				puts "ligne #{j} score #{current_score}"
			end
			#if current_score>=3 then exit end
			if current_score > score_max
				score_max = current_score
				color_max = current_color
			end
			puts "=>max = #{score_max}" if debug 	
		end

		# Find how many columns we have to look at

		cols_to_search = [x]
		if dir == :right
 			# Search the right col if possible
			if x < @table.table_size - 1
				cols_to_search += [x+1]
		end
		elsif dir == :left
 			# Search the left col if possible
			if x > 0
				cols_to_search += [x-1]
			end
		end
			
		# Look at every jewel in these columns
		cols_to_search.each do |i|
			current_color = nil
			current_score = 1
			for j in 0..(@table.table_size - 1)
				if table.matrix[j][i] != current_color
					if current_score > score_max
						score_max = current_score
						color_max = current_color
					end
					current_color = table.matrix[j][i]
					current_score = 1
					if current_score>3 and debug
						puts "gros score pour #{table.matrix} au #{i} #{j}"
					end
				else
					current_score += 1
				end
			end
			if debug
				puts "col #{i} score #{current_score}"
				if current_score>=3 then
					puts "#{table.matrix}"
				end
			end
			if current_score > score_max
				score_max = current_score
				color_max = current_color
			end
		end

		return [score_max, color_max]
	end 

	# Generates all the possible movements on each table square, and computes the score of these potential tables.
	# Returns the best movement found:
	# - best movement should be the one leading to the highest score
	# - however for now it is set to the movement with the lowest line position, 
	#   to minimize impacts of animations (the lowest part of the table is less likely to change
	#   when a correct movement is played. The highest part changes too often, leading to problems
	#   in the screenshots -> incorrect map -> incorrect movements in this area sometimes).
    def find_next_square_movement
        @table.update
        possible_movements = []
		
		if @debug
			puts "Solver: find_next_square_movement"
			str = @table.to_s
			puts "Initial state : \n#{str}\n"
		end
		
		debug = @debug
        (@table.table_size - 1).times do |j|
            (@table.table_size - 1).times do |i|
				# Computes the table obtained for the move i,j in the right direction
				next_table = generate_move(@table, i, j, :right, debug)
				if not next_table.nil?
					puts "next table:\n#{next_table.to_s}\n" if debug
					score, color = compute_score(next_table, i, j, :right, false)
					# The list of all possible movements is stored in the list possible_movements.
					possible_movements << {:i => i, :j => j, :dir => :right, :score => score, :color => color, :before => @table.matrix.clone, :after => next_table.matrix.clone} if score > 2
					if debug
						str = next_table.to_s
						puts "#{i},#{j} :right: \n#{str} #{score};#{color}\n\n"
					end
				end

				next_table = generate_move(@table, i, j, :down, false)
				if not next_table.nil?
					score, color = compute_score(next_table, i, j, :down, false)
					possible_movements << {:i => i, :j => j, :dir => :down, :score => score, :color => color, :before => @table.matrix.clone, :after => next_table.matrix.clone} if score > 2
					if @debug
						str = next_table.to_s
						puts "#{i},#{j} :down: \n#{str} #{score};#{color}\n\n"
					end
				end
            end
        end
				
		# Sort solution 1: by highest score
		# sorted_movements = possible_movements.sort_by {|element| element[:score]}

		# Sort solution 2: by lowest position (low line position)
		sorted_movements = possible_movements.sort_by {|element| element[:j]}
		if @debug then
			puts "Solver: solving finished. Movements found:"
			sorted_movements.each do |mvt|
				puts "Solver: mvt= #{mvt[:i]} #{mvt[:j]} #{mvt[:dir]} #{mvt[:color]} #{mvt[:score]} "
			end
		end

		# best move
		best_mvt = sorted_movements[-1]

		# Sort solution 3: random move
		#best_mvt = sorted_movements[rand(sorted_movements.length)]

		if @debug
			puts "Solver: best_mvt= #{best_mvt[:i]} #{best_mvt[:j]} #{best_mvt[:dir]} #{best_mvt[:color]} #{best_mvt[:score]} "
			#str = best_mvt[:before].to_s
			#puts " :before: \n#{str} \n" 
			#str = best_mvt[:after].to_s
			#puts " :after: \n#{str} \n" 
		end
		# returns the best move : its position (line,column) and direction
        return best_mvt[:i], best_mvt[:j], best_mvt[:dir]
    end
end

