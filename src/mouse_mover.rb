# This class is used to move the mouse on screen, thanks to external tools such as xte or xdotool.
# It handles movements found by the Solver.
# If the mouse is moved by the user, the program stops.

class MouseMover
    def initialize
        @pWindow = Gdk::Window.default_root_window
        _, x, y, _= @pWindow.pointer
        @previous_point = [x,y]
    end

	# Movement : a pair of coordinates in pixels.
    def move_mouse(movement)
        _, x, y, _= @pWindow.pointer
        if [x, y] != @previous_point
            puts "Mouse pointer moved manualy from #{@previous_point[0]}, #{@previous_point[1]} to #{x}, #{y} ! Cancel all tasks."
            return false 
        end

        p1, p2 = movement
        xte=false
        if xte
            cmd = "xte \"mousemove #{p1[0].to_i} #{p1[1].to_i}\" " +
                "\"mousedown 1\" " +
                "\"mousemove #{p2[0].to_i} #{p2[1].to_i}\" " +
                "\"mouseup 1\""
        else
            cmd = "xdotool mousemove #{p1[0].to_i} #{p1[1].to_i} " +
                "click 1 sleep 0.25 " +
                "mousemove #{p2[0].to_i} #{p2[1].to_i} " +
                "click 1 sleep 0 "
        end
        puts "#{cmd}"
        IO.popen(cmd)		
        @previous_point = p2
        return true
    end
end
