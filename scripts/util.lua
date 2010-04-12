----------------------------------------------------------------
-- UTILITY FUNCTIONS
----------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2006-2010 Andrew Apted
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
----------------------------------------------------------------


----====| GENERAL STUFF |====----

function int(val)
  return math.floor(val)
end

function sel(cond, yes_val, no_val)
  -- a poor man's ?: operator
  -- NOTE: both expressions are evaluated!
  if cond then return yes_val end
  return no_val
end

function math.low_high(a, b)
  if b < a then return b, a end
  return a, b
end

function string.bool(n)
  if n == nil   then return "nil"   end
  if n == false then return "false" end
  return "TRUE"
end

function string.is_digit(ch)
  return ch == '0' or ch == '1' or ch == '2' or
         ch == '3' or ch == '4' or ch == '5' or
         ch == '6' or ch == '7' or ch == '8' or
         ch == '9'
end

function read_text_file(filename)
  local file = io.open(filename, "r")

  if not file then
    return nil
  end

  local lines = {}

  for L in file:lines() do
    table.insert(lines, L .. "\n")
  end

  file:close()
  
  return lines
end

function style_sel(name, v_none, v_few, v_some, v_heaps)
  local keyword = STYLE[name]

  if keyword == "none"  then return v_none  end
  if keyword == "few"   then return v_few   end
  if keyword == "heaps" then return v_heaps end

  return v_some
end


----====| TABLE UTILITIES |====----

-- special value for deep_merge() and deep_copy()
REMOVE_ME = "__REMOVE__"

function table.size(t)
  local count = 0;
  for k,v in pairs(t) do count = count+1 end
  return count
end

function table.empty(t)
  return not next(t)
end

function table.contains(t, v)
  for _,value in ipairs(t) do
    if v == value then return true end
  end
  return false
end

function table.numbers(count)
  local t = {}
  for i = 1,count do t[i] = i end
  return t
end

function table.find_unused(t, start)
  if not start then start = 1 end

  while t[start] do
    start = start + 1
  end

  return start
end

function table.reverse(t)
  if not t then return nil end

  for x = 1, int(#t / 2) do
    local y = #t - (x-1)
    -- swap 'em
    t[x], t[y] = t[y], t[x]
  end
end

function table.subset(t, predicate)
  local new_t = {}

  if t then
    for _,e in ipairs(t) do
      if predicate(e) then
        table.insert(new_t, e)
      end
    end
  end

  return new_t
end

function table.subset_w_field(t, field, value)
  local new_t = {}

  if t then
    for _,e in ipairs(t) do
      if e[field] == value then
        table.insert(new_t, e)
      end
    end
  end

  return new_t
end

function table.tostr(t, depth, prefix)
  if not t then return "NIL" end
  if table.empty(t) then return "{}" end

  depth = depth or 1
  prefix = prefix or ""

  local keys = {}
  for k,v in pairs(t) do
    table.insert(keys, k)
  end

  table.sort(keys, function (A,B) return tostring(A) < tostring(B) end)

  local result = "{\n"

  for idx,k in ipairs(keys) do
    local v = t[k]
    result = result .. prefix .. "  " .. tostring(k) .. " = "
    if type(v) == "table" and depth > 1 then
      result = result .. table.tostr(v, depth-1, prefix .. "  ")
    else
      result = result .. tostring(v)
    end
    result = result .. "\n"
  end

  result = result .. prefix .. "}"

  return result
end

function table.pick_best(list, comp)
  assert(list)

  if not comp then
    comp = function(A,B) return (A < B) end
  end

  if #list == 0 then
    return nil
  end

  local cur = 1

  for idx = 2,#list do
    if not comp(list[cur], list[idx]) then
      cur = idx
    end
  end

  return list[cur], cur
end

function table.merge(dest, src)  -- shallow
  for k,v in pairs(src) do
    if v == REMOVE_ME then
      dest[k] = nil
    else
      dest[k] = v
    end
  end

  return dest
end

function table.copy(t)  -- shallow
  return t and table.merge({}, t)
end

function table.merge_missing(dest, src)
  for k,v in pairs(src) do
    if not dest[k] then dest[k] = v end
  end
  return dest
end

function table.deep_merge(dest, src, _curdepth)
  _curdepth = _curdepth or 1

  if _curdepth > 10 then
    error("deep_copy failure: loop detected")
  end

  for k,v in pairs(src) do
    if v == REMOVE_ME then
      dest[k] = nil
    elseif type(v) == "table" then
      -- the type check handles non-existing fields too.
      -- the # checks mean we merely copy a list (NOT merge it).
      if type(dest[k]) == "table" and #v == 0 and #dest[k] == 0 then
        table.deep_merge(dest[k], v, _curdepth+1)
      else
        dest[k] = table.deep_merge({}, v, _curdepth+1)
      end
    else
      dest[k] = v
    end
  end

  return dest
end

function table.deep_copy(t)
  return t and table.deep_merge({}, t)
end

function table.deepish_merge(dest, src)
  for k,v in pairs(src) do
    if v == REMOVE_ME then
      dest[k] = nil
    elseif type(v) == "table" then
      dest[k] = table.deep_copy(v)
    else
      dest[k] = v
    end
  end

  return dest
end

function table.name_up(t)
  for name,info in pairs(t) do
    info.name = name
  end
end

function table.expand_copies(t)

  local function expand_it(name, sub)
    if not sub.copy then return end

    if sub.__expanding then
      error("Cyclic copy ref in: " .. name)
    end

    local orig = t[sub.copy]
    if not orig then
      error("Unknown copy ref: " .. tostring(sub.copy) .. " in: " .. name)
    end

    sub.__expanding = true

    -- recursively expand the original
    expand_it(sub.copy, orig)

    table.merge_missing(sub, orig)

    sub.__expanding = nil
    sub.copy = nil
  end

  --| expand_copies |--

  for name,sub in pairs(t) do
    expand_it(name, sub)
  end
end

function table.array_2D(w, h)
  local array = { w=w, h=h }
  for x = 1,w do
    array[x] = {}
  end
  return array
end

table.INHERIT_META =
{
  __index = function(t, k)
    if t.__parent then return t.__parent[k] end
  end
}

function table.set_class(child, parent)
  child.__parent = parent
  setmetatable(child, table.INHERIT_META)
end


----====| RANDOM NUMBERS |====----

rand = { }

function rand.range(L,H)
  return L + gui.random() * (H-L)
end

function rand.irange(L,H)
  return math.floor(L + gui.random() * (H-L+0.9999))
end

function rand.skew()
  return gui.random() - gui.random()
end

function rand.dir()
  return rand.irange(1, 4) * 2
end

function rand.odds(chance)
  return (gui.random() * 100) <= chance
end

function rand.sel(chance, yes_val, no_val)
  if (gui.random() * 100) <= chance then
    return yes_val
  else
    return no_val
  end
end

function rand.pick(list)
  if #list > 0 then
    return list[rand.irange(1, #list)]
  else
    return nil
  end
end

function rand.shuffle(t)
  -- implements Knuth's random shuffle algorithm.

  if #t > 1 then
    for i = 1,(#t-1) do
      local k = rand.irange(i,#t)
      -- swap the pair of values
      t[i], t[k] = t[k], t[i]
    end
  end

  return t
end

function rand.index_by_probs(p)
  -- each element in the table is a probability.
  -- returns a random index based on the probabilities
  -- (e.g. the highest value is returned more often).
  assert(#p > 0)

  local total = 0
  for _,prob in ipairs(p) do
    total = total + prob
  end

  if total > 0 then
    local value = gui.random() * total

    for idx, prob in ipairs(p) do
      value = value - prob
      if (value <= 0) then return idx end
    end
  end

  -- should not get here, but if we do, return a valid index
  return 1
end

function rand.key_by_probs(tab)
  -- each element in the table has the form: KEY = PROB.
  -- This function returns one of the keys.
  local key_list  = {}
  local prob_list = {}

  for key,prob in pairs(tab) do
    table.insert(key_list,  key)
    table.insert(prob_list, prob)
  end

  local idx = rand.index_by_probs(prob_list)

  return key_list[idx]
end


----====| GEOMETRY |====----

geom = { }

-- rotate tables : Right = CLOCKWISE, Left = ANTI-CLOCKWISE

geom.ROTATE =
{
  [0] = { 1,2,3, 4,5,6, 7,8,9 },
  [1] = { 4,1,2, 7,5,3, 8,9,6 },
  [2] = { 7,4,1, 8,5,2, 9,6,3 },
  [3] = { 8,7,4, 9,5,1, 6,3,2 },
  [4] = { 9,8,7, 6,5,4, 3,2,1 },
  [5] = { 6,9,8, 3,5,7, 2,1,4 },
  [6] = { 3,6,9, 2,5,8, 1,4,7 },
  [7] = { 2,3,6, 1,5,9, 4,7,8 },
}

geom.RIGHT = geom.ROTATE[2]
geom.LEFT  = geom.ROTATE[6]

function geom.dist(x1,y1, x2,y2)
  return math.sqrt( (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) )
end

function geom.delta(dir)
  if dir == 1 then return -1, -1 end
  if dir == 2 then return  0, -1 end
  if dir == 3 then return  1, -1 end

  if dir == 4 then return -1, 0 end
  if dir == 5 then return  0, 0 end
  if dir == 6 then return  1, 0 end

  if dir == 7 then return -1, 1 end
  if dir == 8 then return  0, 1 end
  if dir == 9 then return  1, 1 end

  error("geom.delta: bad dir: " .. tostring(dir))
end

function geom.nudge(x, y, dir, dist)
  if not dist then dist = 1 end
  local dx, dy = geom.delta(dir)
  return x + dx * dist, y + dy * dist
end

function geom.is_horiz(dir)
  return (dir == 4) or (dir == 6)
end

function geom.is_vert(dir)
  return (dir == 2) or (dir == 8)
end

function geom.is_parallel(dir1, dir2)
  return (dir1 == 2 or dir1 == 8) == (dir2 == 2 or dir2 == 8)
end

function geom.is_perpendic(dir1, dir2)
  return (dir1 == 2 or dir1 == 8) == (dir2 == 4 or dir2 == 6)
end


DIR_ANGLES = { 225,270,315, 180,0,0, 135,90,45 }

function dir_to_angle(dir)
  assert(1 <= dir and dir <= 9)
  return DIR_ANGLES[dir]
end

function delta_to_angle(dx,dy)
  if math.abs(dy) < math.abs(dx)/2 then
    return sel(dx < 0, 180, 0)
  end
  if math.abs(dx) < math.abs(dy)/2 then
    return sel(dy < 0, 270, 90)
  end
  if dy > 0 then
    return sel(dx < 0, 135, 45)
  else
    return sel(dx < 0, 225, 315)
  end
end

function geom.rough_dir(dx, dy)
  if math.abs(dx) > math.abs(dy) then
    if dx > 0 then return 6 else return 4 end
  else
    if dy > 0 then return 8 else return 2 end
  end
end


function box_size(x1, y1, x2, y2)
  return (x2-x1+1), (y2-y1+1)
end

function box_aspect(w, h)
  assert(w > 0 and h > 0)
  return math.max(w, h) / math.min(w, h)
end

function box_contains_point(x1,y1,x2,y2, tx,ty)
  return (x1 <= tx) and (tx <= x2) and
         (y1 <= ty) and (ty <= y2)
end

function boxes_overlap(x1,y1,x2,y2,  x3,y3,x4,y4)
  assert(x2 >= x1 and y2 >= y1)
  assert(x4 >= x3 and y4 >= y3)

  if x3 > x2 or x4 < x1 then return false end
  if y3 > y2 or y4 < y1 then return false end

  return true
end

function boxes_touch_sides(x1,y1,x2,y2,  x3,y3,x4,y4)

  if x3 > x2+1 or x4 < x1-1 then return false end
  if y3 > y2+1 or y4 < y1-1 then return false end

  if not (x3 > x2+1 or x4 < x1-1) and not (y3 > y2 or y4 < y1)
  then return true end

  if not (y3 > y2+1 or y4 < y1-1) and not (x3 > x2 or x4 < x1)
  then return true end

  return false
end

function get_long_deep(dir, w, h)
  if (dir == 2) or (dir == 8) then
    return w, h
  else
    return h, w
  end
end

function side_coords(side, x1,y1, x2,y2, ofs)
  if not ofs then ofs = 0 end

  if side == 2 then return x1,y1+ofs, x2,y1+ofs end
  if side == 8 then return x1,y2-ofs, x2,y2-ofs end
  if side == 4 then return x1+ofs,y1, x1+ofs,y2 end
  if side == 6 then return x2-ofs,y1, x2-ofs,y2 end

  error ("side_coords: bad side " .. side)
end

function corner_coords(side, x1,y1, x2,y2)
  if side == 1 then return x1,y1 end
  if side == 3 then return x2,y1 end
  if side == 7 then return x1,y2 end
  if side == 9 then return x2,y2 end

  error ("corner_coords: bad side " .. side)
end

