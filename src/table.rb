# Represents a Bejeweled table, composed of x*x squares containing jewels.
# This class performs screenshots and translates the pixmaps into a colorname matrix.
# This matrix can then be used by the solver.

class Table
    attr_accessor :matrix
    attr_reader :changed
	attr_reader :table_size

	# Intitialize the table:
	# - position of the table on screen (where the screenshot will be taken) : origin_x/y & width/height
	# - number of square per line
    def initialize(origin_x = 0, origin_y = 0, width = 0, height = 0, table_size = 8, debug = false, matrix = nil)
		@debug = debug
        @origin_x, @origin_y = origin_x, origin_y
        @width, @height = width, height
		@matrix = matrix
		@table_size = table_size

        @square_width, @square_height = @width/table_size, @height/table_size
		@squares = Array.new(table_size) {Array.new(table_size)}
        puts "Table: square_width=#{@square_width} square_height=#{@square_height}" if debug
		@flag = false
    end

	# Update the current table:
	# - takes a new screenshot
	# - extracts @table_size*@table_size pixmaps into the @squares matrix
	# - convert the pixmaps into a colorname matrix (@matrix)
    def update
        puts "Table: update" if @debug
		screenshot = get_screenshot
        if (@screenshot.nil?) or (screenshot.pixels != @screenshot.pixels)
            @screenshot = screenshot
			# Extract each jewel pixmap
			(0..@table_size-1).each do |line|
				(0..@table_size-1).each do |col|
					@squares[line][col] = Gdk::Pixbuf::new(Gdk::Pixbuf::ColorSpace::RGB, false, 8, 46, 46).fill!(0x0)
					@screenshot.copy_area(col*@square_width, line*@square_height, 46, 46, @squares[line][col], 0, 0)
				end
			end
            @changed = true	
            @matrix = extract_table_colors
			if @debug
				str = to_s
				puts "Table: matrix found:\n#{str}\n"
			end
        else
            @changed = false
            puts "Table: No change in the screenshot, no new computation" if @debug
        end
        puts "Table: uptate finished" if @debug
    end

    def get_screenshot
        puts "Table: get_screenshot" if @debug
        return Gdk::Pixbuf::from_drawable(nil,
                                          Gdk::Window.default_root_window,
                                          @origin_x, @origin_y, @width, @height,
                                          nil, 0, 0)
    end

	# Converts a pixmap matrix into a colorname matrix
    def extract_table_colors
        puts "Table: extract_table_colors" if @debug
		#format = "jpeg"
		#@screenshot.save("screenshot." + format, format)

		# Extract each jewel pixmap
		table_list = []
		(0..@table_size-1).each do |line|
			line_list = []
			(0..@table_size-1).each do |col|
				color = jewel_pixmap2color(@squares[line][col])
                line_list << color 
			end
			table_list << line_list
		end

        return table_list
	end

	# Convert a pixmap into a colorname.
	# - Pixels around the center of the pixmaps are converted from RGB to HSV
	# - Each HSV color is translated into a colorname
	# - Remove grey colornames of the list, sort the list to find the most frequent color
	def jewel_pixmap2color(pixmap)
        # reorganize the string array into an array of groups of 3 strings (r,g,b)
        i=1
        rows_of_pixels = []
        pixmap.pixels.bytes.each_slice(pixmap.rowstride) { |r|
			row = []
			r.each_slice(3) { |bytes3|
				row << bytes3 if bytes3.length==3
			}
			rows_of_pixels << row
		}

		# Check the colors of pixels nearby...
		xi = @square_width/2
		yi = @square_height/2

		near_pixels_colors = []
		[-10, -5, 0, 5, 10].each do |offset_y|
			[-10, -5, 0, 5, 10].each do |offset_x|
				colorbytes = rows_of_pixels[yi + offset_y][xi + offset_x]
				hsv = rgb2hsv(*colorbytes)
				color = hsv2color(*hsv)
				near_pixels_colors << color
				if @debug
					puts "X=#{xi + offset_x} Y=#{yi + offset_y}"
					puts "colorbytes=#{colorbytes}" 
					puts "hsv=#{hsv}"
					puts "color=#{color}"
				end
			end
		end
		puts "near_pixels_colors=#{near_pixels_colors}" if (@debug)

		# If all pixels are grey (screenshot taken during animation), exit
		return nil if near_pixels_colors.all? {|e| e == :grey }

		near_pixels_colors.delete_if { |e| e == :grey }
		#puts "near_pixels_colors: #{near_pixels_colors}\n" if @debug
		freqs = near_pixels_colors.inject(Hash.new(0)) { |h,v| h[v]+=1; h}
		# We want the more frequent nearby color
		sorted_colors = near_pixels_colors.sort_by {|v| freqs[v]}.uniq

		puts "sorted_colors=#{sorted_colors}" if @debug
		if sorted_colors.last == :white and sorted_colors[-2] == :blue
			final_color = :blue
		else
			final_color = sorted_colors.last
		end
		return final_color
	end

	# Converts a square coordinate on the table into pixels positions.
    def convert_squares_to_coords(square_x, square_y)
        return [@origin_x + square_x*@square_width + @square_width/2.0, 
            @origin_y + square_y*@square_height + @square_height/2.0,]
    end

    # Converts a square movement (square_x : 2, square_y : 3, direction, down)
    # to a pixel movement : 2 points (pixel coordinates) for the mouse
    def get_movement_coords(square_x, square_y, direction)
        puts "Table: get_movement_coords" if @debug
        p1 = convert_squares_to_coords(square_x, square_y)
        case direction
        when :up    then p2 = convert_squares_to_coords(square_x, square_y - 1)
        when :down  then p2 = convert_squares_to_coords(square_x, square_y + 1)
        when :left  then p2 = convert_squares_to_coords(square_x - 1, square_y)
        when :right then p2 = convert_squares_to_coords(square_x + 1, square_y)
        end
        return [p1, p2]
    end

	# Converts a RGB color to HSV
    def rgb2hsv(r, g, b)
        r = r/255.0
        g = g/255.0
        b = b/255.0
        max = [r, g, b].max
        min = [r, g, b].min
        if max == min
            h, s = 0, 0
        else
            if max == r 
                h = (60.0 *((g-b)/(max-min)) + 360.0 ).modulo(360)
            elsif max == g 
                h = (60.0 *((b-r)/(max-min)) + 120.0 )
            elsif max == b 
                h = (60.0 *((r-g)/(max-min)) + 240.0 )
            end
            s = 1 - min/max
        end
        v = max
        return [h, s, v]
    end

	# Identify a HSV color as a color name
    def hsv2color(h, s, v)
		if s < 0.55 and v < 0.5
			:grey
		elsif s < 0.5
        #if s < 0.55
            if v < 0.5
                :grey
            else
                :white
            end
        else
            case h
            when 0..20
                :red
            when 20..50
                :orange
            when 50..65
                :yellow
            when 65..160
                :green
            when 160..260
                :blue
            when 260..340
                :purple
            when 340..360
                :red
            end
        end
    end

	# Converts a table matrix to a string
	def to_s
		str=""
		@matrix.each do |line|
			line.each do |color|
				str += color2str(color) + ' '
			end
			str += "\n"
		end
		return str
	end
	
	# Converts a color name to a letter
	def color2str(color)
		case color
		when :white
			'W'
		when :gray
			'G'
		when :orange
			'O'
		when :yellow
			'Y'
		when :green
			'G'
		when :blue
			'B'
		when :purple
			'P'
		when :red
			'R'
		when nil
			'.'
		end
	end
end

