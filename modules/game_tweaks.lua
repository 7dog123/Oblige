------------------------------------------------------------------------
--  MODULE: Gameplay Tweaks
------------------------------------------------------------------------
--
--  Copyright (C) 2014 Andrew Apted
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
------------------------------------------------------------------------

GAMEPLAY_TWEAKS = {}


GAMEPLAY_TWEAKS.YES_NO =
{
  "no",  "No"
  "yes", "Yes"
}


function GAMEPLAY_TWEAKS.begin_level(self)
  for name,opt in pairs(self.options) do
    local value = self.options[name].value

    if value == "no" or value == "none" then
      -- ignore it
    else
      LEVEL[name] = value
    end
  end
end


OB_MODULES["gameplay_tweaks"] =
{
  label = "Gameplay Tweaks"

  hooks =
  {
    begin_level = GAMEPLAY_TWEAKS.begin_level
  }

  options =
  {
    kept_weapons  = { label="Kept Weapons",   choices=GAMEPLAY_TWEAKS.YES_NO }
    quiet_start   = { label="Quiet Start",    choices=GAMEPLAY_TWEAKS.YES_NO }
  }
}

