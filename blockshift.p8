pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- blockshift
-- by jonic
-- v1.0.0

--[[
]]

-->8
-- game object
local game_init = function()
  local g = {}

  g.block_counter     = 0
  g.default_state     = 'playing'
  g.frame_multiplier  = 1
  g.high_score        = 0
  g.high_score_beaten = false
  g.objects           = {}
  g.objects_order     = {}
  g.score             = 0
  g.state             = nil
  g.states            = {}

  g.draw = function()
    cls()
    g.state.draw()
    g.objects_exec('draw')
  end

  g.go_to = function(name)
    printh('state: `' .. name .. '`')

    if g.state then
      g.skip_animations()
      g.state_unload()
    end

    g.state = g.states[name]
    g.state_init()
  end

  g.increment_block_counter = function()
    g.block_counter += 1

    if g.block_counter > 1000 then
      g.block_counter = 0
    end
  end

  g.init = function()
    cartdata('jonic_blockshift')
    -- dset(0, 0)
    g.go_to(g.default_state)
  end

  g.object_add = function(name, o)
    add(g.objects_order, name)
    g.objects[name] = o
    -- g.object_debug()
  end

  g.object_debug = function()
    local debug = ''

    foreach (g.objects_order, function(name)
      debug = debug .. name .. ', '
    end)

    printh(debug)
  end

  g.object_destroy = function(name)
    local index = g.object_get_order_index(name)
    local o     = g.objects[name]

    if (index ~= nil) then
      -- printh('remove object: `' .. name .. '`')
      g.objects_order[index] = nil
      del(g.objects, o)
    end

    -- g.object_debug()
  end

  g.object_get_order_index = function(name)
    for i, v in pairs(g.objects_order) do
      if (v == name) return i
    end
  end

  g.object_restack = function(name)
    local index = g.object_get_order_index(name)
    g.objects_order[index] = nil
    add(g.objects_order, name)
  end

  g.objects_destroy = function(objects_list)
    foreach (objects_list, g.object_destroy)
  end

  g.objects_destroy_all = function()
    g.objects_order = copy({})
    g.objects       = copy({})
  end

  g.objects_exec = function(fn)
    local obj

    for _, name in pairs(g.objects_order) do
      obj = g.objects[name]
      if (obj ~= nil) obj[fn]()
    end
  end

  g.objects_restack = function(objects_list)
    foreach (objects_list, g.object_restack)
  end

  g.reset = function()
    g.objects_destroy_all()
    g.reset_vars()
    g.state            = g.states[g.default_state]
    g.frame_multiplier = 2
  end

  g.reset_vars = function()
    g.high_score        = dget(0)
    g.high_score_beaten = false
    g.score             = 0
  end

  g.skip_animations = function()
    g.objects_exec('skip')
  end

  g.state_init = function()
    printh('g.state_init()')
    if (g.state.init) g.state.init()
  end

  g.state_unload = function()
    if (g.state.unload) g.state.unload()
  end

  g.update = function()
    g.objects_exec('update')
    g.state.update()
  end

  g.update_high_score = function()
    g.high_score        = g.score
    g.high_score_beaten = true
    dset(0, g.high_score)
  end

  g.update_score = function()
    g.score += 1
    if (g.score > g.high_score) g.update_high_score()
  end

  return g
end

local game = game_init()

--> 8
-- helpers functions

function table_rotate(t, c)
  l = #t
  new_t = {}

  if c < 0 then
    start_index = l + c + 1
  else
    start_index = c + 1
  end

  for index = start_index, l do
    add(new_t, t[index])
  end

  for index = 1, start_index - 1 do
    add(new_t, t[index])
  end

  return new_t
end

-- clone and copy from https://gist.github.com/MihailJP/3931841
function clone(t) -- deep-copy a table
  if type(t) ~= "table" then return t end
  local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      target[k] = clone(v)
    else
      target[k] = v
    end
  end
  setmetatable(target, meta)
  return target
end

function copy(t) -- shallow-copy a table
  if type(t) ~= "table" then return t end
  local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do target[k] = v end
  setmetatable(target, meta)
  return target
end

function draw_sprite(s, x, y)
  local i  = s.i
  local x  = s.x + (x or 0)
  local y  = s.y + (y or 0)
  local w  = s.w or 1
  local h  = s.h or 1
  local fx = s.fx or false
  local fy = s.fy or false

  spr(i, x, y, w, h, fx, fy)
end

function draw_sprites(sprites, x, y)
  foreach(sprites, draw_sprite, x, y)
end

function f(n)
  return n * game.frame_multiplier
end

function o(name)
  return game.objects[name]
end

function rnd_int(min, max)
  return flr(rnd(max)) + min
end

-- easing equations
-- https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua
local function linear(t, b, c, d)
  return c * t / d + b
end

local function outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end

local function outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end

local function inBounce(t, b, c, d)
  return c - outBounce(d - t, 0, c, d) + b
end

-->8
-- init objects and states
function object_define(name, props)
  game.object_destroy(name)
  -- printh('object: created `' .. name .. '`')

  local o = {}

  o.color       = props.color   or 7
  o.frame_count = 0
  o.name        = name
  o.outline     = props.outline or nil
  o.rects       = props.rects   or nil
  o.text        = props.text    or nil
  o.tiles       = props.tiles   or nil
  o.updated     = false
  o.x           = props.x       or 0
  o.y           = props.y       or 0

  o.center_x = function()
    local text = o.text .. ''
    return 64 - #text * 2
  end

  o.draw_rect = function(r)
    local x1    = (r.x or 0) + o.x
    local y1    = (r.y or 0) + o.y
    local x2    = x1 + r.w
    local y2    = y1 + r.h
    local color = r.color

    rectfill(x1, y1, x2, y2, color)
  end

  o.draw_rects = function(rects)
    foreach(rects, function(r)
      if (r.w == nil) return o.draw_rects(r)
      o.draw_rect(r)
    end)
  end

  o.draw_text = function()
    local color   = o.color
    local outline = o.outline
    local text    = o.text
    local x       = o.x
    local y       = o.y

    if outline ~= nil then
      print(text, x - 1, y, outline)
      print(text, x + 1, y, outline)
      print(text, x, y - 1, outline)
      print(text, x, y + 1, outline)
    end

    print(text, x, y, color)
  end

  o.draw_tile = function(t)
    local x  = (t.x or 0) + o.x
    local y  = (t.y or 0) + o.y
    local w  = t.w or 1
    local h  = t.h or 1
    local fx = t.fx or false
    local fy = t.fy or false

    spr(t.i, x, y, w, h, fx, fy)
  end

  o.draw_tiles = function(tiles)
    foreach(tiles, function(t)
      if (t.i == nil) return o.draw_tiles(t)
      o.draw_tile(t)
    end)
  end

  o.is_animating = function() return type(o.duration) == 'number' and o.frame_count < o.duration end
  o.is_text      = function() return o.type() == 'text'  end
  o.is_tiles     = function() return o.type() == 'tiles' end
  o.is_rects     = function() return o.type() == 'rects' end

  o.move  = function(props)
    o.delay    = f(props.delay    or 0)
    o.duration = f(props.duration or 0)
    o.easing   = props.easing   or nil
    o.new_x    = props.x        or o.x
    o.new_y    = props.y        or o.y
    o.old_x    = o.x
    o.old_y    = o.y

    o.complete    = false
    o.frame_count = 0
    o.updated     = false

    return o
  end

  o.pos = function(coords)
    o.x = coords.x or o.x
    o.y = coords.y or o.y
    return o
  end

  o.skip = function()
    if (not o.is_animating()) return
    o.duration = nil
    o.x        = o.new_x
    o.y        = o.new_y
  end

  o.tick = function()
    if o.delay > 0 then
      o.delay -= 1
      return
    end

    o.frame_count += 1
  end

  o.type = function()
    if (o.text  ~= nil) return 'text'
    if (o.tiles ~= nil) return 'tiles'
    if (o.rects ~= nil) return 'rects'
  end

  o.update_pos = function(pos_key)
    local pos1 = o['old_' .. pos_key]
    local pos2 = o['new_' .. pos_key]

    local t = o.frame_count -- elapsed time
    local b = pos1          -- begin
    local c = pos2 - pos1   -- change == ending - beginning
    local d = o.duration    -- duration (total time)
    local e = o.easing or linear

    if (type(e) == 'string') then
      if     e == 'inBack'    then e = inBack
      elseif e == 'outBack'   then e = outBack
      elseif e == 'inBounce'  then e = inBounce
      elseif e == 'outBounce' then e = outBounce
      else                         e = linear
      end
    end

    return flr(e(t, b, c, d))
  end

  o.update = function()
    o.updated = true
    if (not o.is_animating()) return

    o.tick()
    o.x = o.update_pos('x')
    o.y = o.update_pos('y')
  end

  o.draw = function()
    if (not o.updated) return
    if (o.is_text())   return o.draw_text()
    if (o.is_tiles())  return o.draw_tiles(o.tiles)
    if (o.is_rects())  return o.draw_rects(o.rects)
  end

  game.object_add(name, o)

  return o
end

function state_define(name, props)
  local s = {}

  s.frame_count = 0
  s.name        = name
  s.props       = props()

  s.draw = function()
    if (s.should_flash()) return s.draw_flash()
    if (s.props.draw) s.props.draw()
  end

  s.draw_flash = function()
    rectfill(0, 0, 127, 127, s.props.flash.color)
  end

  s.init = function()
    s.frame_count = 0
    if (s.props.init) s.props.init()
  end

  s.should_flash = function()
    return (s.props.flash ~= nil) and (s.props.flash.on == s.frame_count)
  end

  s.unload = function()
    if (s.props.unload) s.props.unload()
  end

  s.update = function()
    s.frame_count += 1

    if (s.props.transition ~= nil) then
      if (s.frame_count == f(s.props.transition.timeout)) then
        game.go_to(s.props.transition.destination)
      end
    end

    if (s.props.update) s.props.update()
  end

  game.states[name] = s

  return s
end

-->8
-- objects definitions
local rects = {}
local text = {}
local tiles = {}

-->8
-- state definitions

state_define('playing', function()
  local s = {}

  s.block_size = 8
  s.board      = {}
  s.board_x    = 8
  s.board_y    = 8
  s.destroying = false
  s.faller     = nil
  s.next       = nil
  s.grid_x     = 8
  s.grid_y     = 14

  s.init = function()
    printh('playing.init()')

    for x = 1, s.grid_x do
      add(s.board, {})
    end

    s.spawn_next()
  end

  s.update = function()
    if (s.destroying) return

    s.check_faller()

    if s.check_matches() then
      s.destroying = true
      return
    end

    s.check_input()
    s.update_blocks()
  end

  s.draw = function()
    s.draw_board()
    s.draw_next()
  end

  -- state methods

  s.add_block = function(x, y)
    local key = s.block_key()
    local tiles = {
      { i = s.rnd_block() }
    }

    object_define(key, { tiles = tiles })
    add(s.board[x], key)
  end

  s.block_key = function()
    game.increment_block_counter()
    return 'block_' .. game.block_counter
  end

  s.check_input = function()
    if (btnp(0)) then
      sfx(0)
      s.board = table_rotate(s.board, 1)
    end

    if (btnp(1)) then
      sfx(1)
      s.board = table_rotate(s.board, -1)
    end

    if (btnp(2)) then
      sfx(3)
      s.rotate_columns(1)
    end

    if (btnp(3)) then
      sfx(2)
      s.rotate_columns(-1)
    end
  end

  s.check_faller = function()
    if s.faller then
      s.spawn_faller()
    end
  end

  s.check_matches = function()
    return false
  end

  s.draw_board = function()
    map(0, 0)
    -- corners
    spr(2, 5,  5)
    spr(3, 67, 5)
    spr(4, 5,  115)
    spr(5, 67, 115)
    -- top line
    line(13, 5, 66, 5, 7)
    line(13, 6, 66, 6, 6)
    -- bottom line
    line(13, 121, 66, 121, 7)
    line(13, 122, 66, 122, 6)
    -- left line
    line(5, 13, 5, 114, 7)
    line(6, 13, 6, 114, 6)
    -- right line
    line(73, 13, 73, 114, 7)
    line(74, 13, 74, 114, 6)
    rectfill(7, 7, 72, 120, 0)
  end

  s.draw_next = function()
    rectfill(79, 7, 120, 34, 0)
    -- corners
    spr(2, 77, 5)
    spr(3, 115, 5)
    spr(4, 77,  29)
    spr(5, 115, 29)
    -- top line
    line(85, 5, 114, 5, 7)
    line(85, 6, 114, 6, 6)
    -- bottom line
    line(85, 35, 114, 35, 7)
    line(85, 36, 114, 36, 6)
    -- left line
    line(77, 13, 77, 28, 7)
    line(78, 13, 78, 28, 6)
    -- right line
    line(121, 13, 121, 28, 7)
    line(122, 13, 122, 28, 6)

    print('next:', 86, 18, 7)
  end

  s.get_block_pos = function(x, y)
    local blocks_count = #s.board[x]
    local vert_offset = (s.grid_y - blocks_count) * s.block_size

    pos_x = s.board_x + (x * s.block_size) - s.block_size
    pos_y = s.board_y + (y * s.block_size) - s.block_size + vert_offset

    return pos_x, pos_y
  end

  s.rnd_block = function()
    sprite = rnd_int(1, 6) + 15
    return sprite
  end

  s.rotate_columns = function(c)
    for x = 1, s.grid_x do
      s.board[x] = table_rotate(s.board[x], c)
    end
  end

  s.spawn_faller = function()

  end

  s.spawn_next = function()
    local pos_y_start = 1

    s.next = {}

    for i = 1, 3 do
      local key = 'next_' .. i
      local tiles = {
        { i = s.rnd_block() }
      }

      local pos_x = 111
      local pos_y = pos_y_start + (i * 8)

      object_define(key, { tiles = tiles, x = pos_x, y = pos_y })
      add(s.next, key)
    end
  end

  s.update_blocks = function()
    for x = 1, s.grid_x do
      local blocks_count = #s.board[x]

      for y = 1, blocks_count do
        local key = s.board[x][y]
        local pos_x, pos_y = s.get_block_pos(x, y)
        o(key).pos({ x = pos_x, y = pos_y })
      end
    end
  end

  return s
end)

-->8
-- game loop
function _init()
  game.init()
end

function _update()
  game.update()
end

function _draw()
  game.draw()
end
__gfx__
00000000111dd1110777777777777770760000000000007600000000000000760000000000000000000000000000000000000000000000000000000000000000
000000001dd111117666666666666676760000000000007600000000000000760000000000000000000000000000000000000000000000000000000000000000
00700700d111111d7600000000000076760000000000007600000000000000760000000000000000000000000000000000000000000000000000000000000000
0007700011111dd17600000000000076760000000000007600000000000000760000000000000000000000000000000000000000000000000000000000000000
00077000111dd1117600000000000076760000000000007600000000000000760000000000000000000000000000000000000000000000000000000000000000
007007001dd111117600000000000076760000000000007600000000000000760000000000000000000000000000000000000000000000000000000000000000
00000000d111111d7600000000000076777777777777777677777777000000760000000000000000000000000000000000000000000000000000000000000000
0000000011111dd17600000000000076066666666666666066666666000000760000000000000000000000000000000000000000000000000000000000000000
0888888000099000aaaaaaaa000bb000ccccccccee0000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000
888888880099990099aaaa9900bbbb00ccccccccee0000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000
888888880999999000aaaa000bbbbbb0cccccccceeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
888888889999999900aaaa00bbbbbbbbcccccccceeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
888888884999999400aaaa00bbbbbbbb1cccccc1eeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000
888888880499994000aaaa00bbbbbbbb01cccc10ee2222ee00000000000000000000000000000000000000000000000000000000000000000000000000000000
2888888200499400aaaaaaaabbbbbbbb001cc100ee0000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000
02222220000440009999999933333333000110002200002200000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002005023000020000000000000000000000000000000000000000000000000000000000000000100001000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002305003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002355000000000000000000000000000000007500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
