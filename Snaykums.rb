class Munchy
  attr_reader :x, :y, :fill
  attr_accessor :eaten
  
  def initialize x, y, unit
    @x, @y, @u = x, y, unit
    @stroke = $app.brown
    @fill = "rgb(#{rand(200)}, #{rand(255)}, #{rand(255)})"
    @eaten = false
  end
  
  def draw
    $app.stroke @stroke
		$app.fill @fill
		$app.rect :left => @x, :top => @y, :width => @u, :height => @u
  end
end

class Wigley
  attr_reader :x, :y, :last_x, :last_y, :last_dir, :last_fill
  UNIT = 10
  BEARING = {
    :x => { :right => UNIT, :up => 0, :left => -UNIT, :down => 0 },
    :y => { :right => 0, :up => -UNIT, :left => 0, :down => UNIT }
  }
  
  def initialize x, y, dir, fill = nil
    @x, @y, @u = x, y, UNIT
    @direction, @last_dir = dir, dir
    @last_x, @last_y = @x, @y
    @stroke = $app.red
    @fill = fill || "rgb(#{rand(200)}, #{rand(255)}, #{rand(255)})"
    @last_fill = @fill
  end
  
  def get_step direction
    [BEARING[:x][direction], BEARING[:y][direction]]
  end
  
  def set_direction dir
    @last_dir = @direction
    @direction = dir
  end
  
  def move dir
    set_direction dir
    pos = get_step dir
    @last_x, @last_y = @x, @y
    @x += pos[0]
    @y += pos[1]
    draw
  end
  
  def hit_something_in? game
    hit_wall?(game) or hit_wigley?(game)
  end
  
  def hit_wall? game
    @x > game.w - @u or @x < 0 or @y > game.h - @u or @y < 0
  end
  
  def hit_wigley? game
    game.wigleys.any? { |w| (@x == w.x and @y == w.y) unless w == self }
  end
  
  def ate? m
    if @x == m.x && @y == m.y
      m.eaten = true
      @last_fill = @fill
      @fill = m.fill
    end
  end
  
  def draw
    $app.stroke @stroke
		$app.fill @fill
		$app.rect :left => @x, :top => @y, :width => @u, :height => @u
  end
end

class Snaykums
  attr_accessor :direction
  attr_reader :wigleys, :munchies, :w, :h
  WIDTH, HEIGHT, UNIT = 400, 400, 10
  
  def initialize
    @w, @h = WIDTH, HEIGHT
    @board = [[0] * @w] * @h
    reset
  end
  
  def reset
    @direction = :left
    @score = 0
    @wigleys = [Wigley.new(@w/2, @h/2, @direction)]
    
    1.upto([1, rand(5)].max) do |i|
      (@munchies ||= []) << Munchy.new(rand_grid(:x), rand_grid(:y), UNIT)
    end
  end
  
  def rand_grid(xy)
    dim = xy == :x ? @w : @h
    rand(dim / UNIT) * UNIT
  end
  
  def wiggles_ate?
    @munchies.any? { |munchy| @wigleys.first.ate? munchy }
  end
  
  def more_wigleys_and_munchies
    @munchies.reject! { |m| m.eaten }
    @munchies << Munchy.new(rand_grid(:x), rand_grid(:y), UNIT)
    @wigleys << Wigley.new(@wigleys.last.last_x, @wigleys.last.last_y, @wigleys.last.last_dir, @wigleys.last.last_fill)
    @score += 1
  end
  
  def draw
    $app.clear do
      $app.para "Score: #{@score}"
      
      @wigleys.first.move @direction
      
      @wigleys[1, @wigleys.size-1].each do |w| 
        follow = @wigleys[@wigleys.index(w)-1]
        w.move follow.last_dir
      end
      @munchies.each { |m| m.draw }
    end
  end
end

Shoes.app :width => 400, :height => 400 do
  $app = self
  
  @speed = 10
  @game = Snaykums.new
  @wiggles = @game.wigleys.first
  @playing, @paused = true, false
  
  keypress do |key|
    if @playing
      case key when :up
        @paused = false
        @game.direction = :up
      when :right
        @paused = false
        @game.direction = :right
      when :left
        @paused = false
        @game.direction = :left
      when :down
        @paused = false
        @game.direction = :down
      when ' '
        @paused = !@paused
      end
    else
      @game = Snaykums.new
      @game.direction = key
      @wiggles = @game.wigleys.first
      @playing, @paused = true, false
    end
  end
  
  animate @speed do
    @game.draw if @playing and not @paused
    
    if @game.wiggles_ate?
      @game.more_wigleys_and_munchies
      @speed += 10
    end
    
    @playing = false if @wiggles.hit_something_in? @game
    
    unless @playing
      @game.reset
      @playing, @paused = true, false
      alert "LOSER!" if @paused
    end
  end
end