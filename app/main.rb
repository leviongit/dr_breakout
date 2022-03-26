$gtk.reset

def vec2(x = 0.0, y = 0.0)
  { x: x, y: y }
end

XPADDING = 10
YPADDING = 10
BLOCK_XNUM = 20
BLOCK_YNUM = 10
BLOCK_WIDTH = ((1280 - 2 * XPADDING - (XPADDING / 2) * (BLOCK_XNUM - 1)) / BLOCK_XNUM)
BLOCK_HEIGHT = 20

PADDLE_WIDTH = 150
PADDLE_HEIGHT = BLOCK_HEIGHT

BALL_DIAMETER = 20
CHECK_DEPTH = 10

COLOURS = [
  {
    r: 255
  },
  {
    g: 255
  },
  {
    b: 255
  },
  {
    r: 255,
    g: 255
  },
  {
    r: 255,
    b: 255
  },
  {
    g: 255,
    b: 255
  },
  {
    r: 255,
    g: 255,
    b: 255,
  }
]

def tick(args)
  $gtk.reset if args.inputs.keyboard.key_down.r

  args.outputs.background_color = [0x23] * 3

  args.state.lives ||= 3
  args.state.blocks ||= BLOCK_XNUM.times.map do |x|
    BLOCK_YNUM.times.map do |y|
      {
        x: ((BLOCK_WIDTH * x) + XPADDING + (XPADDING / 2) * x),
        y: 720 - (YPADDING + BLOCK_HEIGHT * y + (YPADDING / 2) * y) - BLOCK_HEIGHT,
        w: BLOCK_WIDTH,
        h: BLOCK_HEIGHT,
        **COLOURS[y.clamp_wrap(0, COLOURS.length - 1)]
      }
    end
  end.flatten!

  args.state.paddle ||= {
    x: 1280 / 2 - PADDLE_WIDTH / 2,
    y: YPADDING,
    w: PADDLE_WIDTH,
    h: PADDLE_HEIGHT,
    r: 255,
    g: 255,
    b: 255
  }

  args.state.ball ||= {
    x: 1280 / 2 - BALL_DIAMETER / 2,
    y: 720 / 3,
    w: BALL_DIAMETER,
    h: BALL_DIAMETER,
    r: 255,
    g: 255,
    b: 255,
    dx: 0,
    dy: -5
  }

  input(args)
  calc(args)

  args.outputs.solids.concat(args.state.blocks)
  args.outputs.solids << args.state.paddle
  args.outputs.solids << args.state.ball

  if args.state.game_state == :lost
    args.outputs.labels << [{
      x: 1280 / 2,
      y: 720 / 2,
      text: 'You lost :(',
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 10
    }, {
      x: 1280 / 2,
      y: 720 / 2 - 40,
      text: 'Press `r` to restart',
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 6
    }]
  elsif args.state.game_state == :win
    args.outputs.labels << [{
      x: 1280 / 2,
      y: 720 / 2,
      text: 'You won! :)',
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 10
    }, {
      x: 1280 / 2,
      y: 720 / 2 - 40,
      text: 'Press `r` to restart',
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 6
    }]
  end
end

def input(args)
  return if args.state.game_state == :lost

  args.state.paddle[:x] =
    (args.state.paddle[:x] + args.inputs.left_right * 10).clamp(XPADDING, 1280 - XPADDING - PADDLE_WIDTH)
end

def calc(args)
  return if args.state.game_state == :lost

  ball = args.state.ball

  ball[:x] += ball[:dx]
  ball[:y] += ball[:dy]

  if ball.intersect_rect?(args.state.paddle)
    ball[:dx] = (
      ((ball[:x] + BALL_DIAMETER / 2) - (args.state.paddle[:x] + PADDLE_WIDTH / 2)) / (PADDLE_WIDTH / 2)
    ) * 5
    ball[:dy] *= -1
  end

  ball[:hitx] = false
  ball[:hity] = false
  args.state.blocks.each do |block|
    next unless ball.intersect_rect?(block)

    block[:hit] = true

    if (ball[:x] < block[:x] + block[:w] && ball[:x] > block[:x] + block[:y] - CHECK_DEPTH) ||
       (ball[:x] + ball[:w] > block[:x] && ball[:x] + ball[:w] < block[:x] + CHECK_DEPTH)
      ball[:dx] *= -1 unless ball[:hitx]
      ball[:hitx] = true
    end

    next unless (ball[:y] < block[:y] + block[:h] && ball[:y] > block[:y] + block[:h] - CHECK_DEPTH) ||
                (ball[:y] + ball[:h] > block[:y] && ball[:y] + ball[:h] < block[:y] + CHECK_DEPTH)

    ball[:dy] *= -1 unless ball[:hity]
    ball[:hity] = true
  end

  ball[:dx] *= -1 if ball[:x] < 0 || ball[:x] + ball[:w] > 1280
  ball[:dy] *= -1 if ball[:y] + ball[:h] > 720
  if ball[:y] < 0
    args.state.lives -= 1

    if args.state.lives == 0
      ball.merge!(dy: 0, dx: 0)

      args.state.game_state = :lost
    else
      ball.merge!(
        x: 1280 / 2 - BALL_DIAMETER / 2,
        y: 720 / 2 - BALL_DIAMETER / 2,
        dx: 0,
        dy: -5
      )
    end
  end

  args.state.game_state = :win if args.state.blocks.length == 0
  
  args.state.blocks.reject! { _1[:hit] }
end
