#!/usr/bin/env ruby

require 'gtk2'
include Gtk
require 'time'
require 'optparse'

require File.expand_path(File.join(File.dirname(__FILE__), "table.rb"))
require File.expand_path(File.join(File.dirname(__FILE__), "solver.rb"))
require File.expand_path(File.join(File.dirname(__FILE__), "mouse_mover.rb"))


options = {}
optparse = OptionParser.new do|opts|
	# Set a banner, displayed at the top
	# of the help screen.
	opts.banner = "Usage: optparse1.rb [options] file1 file2 ..."

	# Define the options, and what they do
	options[:verbose] = false
	opts.on( '-v', '--verbose', 'Output more information' ) do
		options[:verbose] = true
	end

	options[:debug] = false
	opts.on( '-d', '--debug', 'Debug mode' ) do
		options[:debug] = true
	end

	options[:logfile] = nil
	opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do|file|
		options[:logfile] = file
	end

	options[:x] = 0
	opts.on( '-x', '--x_coordinate INTEGER', 'Top left coordinate of the table' ) do|x|
		options[:x] = x
	end

	options[:y] = 0
	opts.on( '-y', '--y_coordinate INTEGER', 'Top left coordinate of the table' ) do|y|
		options[:y] = y
	end

	options[:w] = 0
	opts.on( '-w', '--width INTEGER', 'Width of the table' ) do|w|
		options[:w] = w
	end

	opts.on( '-t', '--table coordinates X,Y,W,H', Array, 'Height of the table' ) do|t|
		options[:x] = t[0]
		options[:y] = t[1]
		options[:w] = t[2]
		options[:h] = t[3]
	end

	options[:n] = 8
	opts.on( '-n', '--number_cases INTEGER', 'Number of cases of the table (in each width)' ) do|n|
		options[:n] = n
	end

	# This displays the help screen, all programs are
	# assumed to have this option.
	opts.on( '-h', '--help', 'Display this screen' ) do
		puts opts
		exit
	end
end

optparse.parse!

# Initialize the table, take a screenshot
table = Table.new(options[:x].to_i, options[:y].to_i, options[:w].to_i, options[:h].to_i, options[:n].to_i, options[:debug])
table.update
if options[:debug]
	puts "Initial table:"
	str = table.to_s
	puts str
end

solver = Solver.new(table, options[:debug])
mover = MouseMover.new

Thread.new(solver, mover) do |solver, mover|
    stop = false
    while not stop do
        puts "loop begining ..." if options[:debug]
        mvt = solver.find_next_movement		
        res_ok = mover.move_mouse(mvt) unless mvt.nil?
        stop=true if not res_ok
        puts "sleeping ..." if options[:debug]
        sleep(1)		
    end
    puts "Program terminated"
    exit	
end

main

