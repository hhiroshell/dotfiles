local lush = require "lush"
local base = require "zenbones"

-- Create some specs
local specs = lush.parse(function()
  return {
    Conceal { base.Conceal, gui = "bold" },
    Number { base.Number, gui = "NONE" },
    Constant { base.Constant, gui = "NONE" },
    Comment { base.Comment, gui = "NONE" },
  }
end)

-- Apply specs using lush tool-chain
lush.apply(lush.compile(specs))
