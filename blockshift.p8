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

  g.default_state     = 'playing'
  g.frame_multiplier  = 1
  g.high_score        = 0
  g.high_score_beaten = false
  g.objects           = {}
  g.objects_order     = {}
  g.score             = 0
  g.state             = nil
  g.states            = {}

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

  g.draw = function()
    cls()
    g.objects_exec('draw')
    g.state.draw()
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

  g.init = function()
    cartdata('jonic_blockshift')
    -- dset(0, 0)
    g.go_to(g.default_state)
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

  if c < 0 then
    start_index = l + c + 1
  else
    start_index = c + 1
  end
  printh('start_index: ' .. start_index)
  new_t = {}

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

function rndint(min, max)
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

  s.init = function()
    printh('playing.init()')

    s.board = {}

    for x = 0, 5 do
      add(s.board, {})
      for y = 0, 10 do
        add(s.board[x + 1], rndint(1, 15))
        -- printh('s.board[x][y] = ' .. s.board[x + 1][y + 1])
      end
    end
  end

  s.update = function()
    if (btnp(0)) s.board = table_rotate(s.board, 1)
    if (btnp(1)) s.board = table_rotate(s.board, -1)

    if (btnp(2)) s.rotate_columns(1)
    if (btnp(3)) s.rotate_columns(-1)
  end

  s.draw = function()
    for x = 1, 5 do
      for y = 1, 10 do
        x_pos = x * 8
        y_pos = y * 8
        rectfill(x_pos, y_pos, x_pos + 8, y_pos + 8, s.board[x][y])
      end
    end
  end

  -- state methods

  s.rotate_columns = function(c)
    for x = 1, 5 do
      s.board[x] = table_rotate(s.board[x], c)
    end
  end

  return s
end)

-->8
-- game loop
function _init()
  game.init()
end

function _update60()
  game.update()
end

function _draw()
  game.draw()
end
__gfx__
00000000111ff1110777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001ff111117777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700f111111f7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700011111ff17700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111ff1117700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001ff111117700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f111111f7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000011111ff17700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
