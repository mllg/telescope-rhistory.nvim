local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local hist_file = '~/.Rhistory'
local match_min_chars = 1
local match_whitelist = '%w+'
local match_blacklist = '# %[history skip%]$'


local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require'telescope.utils'
local Path = require("plenary.path")

local get_rhistory = function(opts)
    opts = opts or {}
    opts.hist_file = utils.get_default(opts.hist_file, '~/.Rhistory')
        
    
    pickers.new(opts, {
        prompt_title = "R history",
        finder = finders.new_table {
            results = (function()
                local fn = Path:new(opts.hist_file)
                if not fn:is_file() then
                    return {}
                end

                local hash = {}
                local results = {}
                for line in io.lines(fn:expand()) do
                    local str = vim.trim(line)
                    if (
                        #str >= match_min_chars and 
                        not hash[str] and 
                        str:match(match_whitelist) and 
                        not str:match(match_blacklist)
                    ) then
                        hash[str] = true
                        results[#results + 1] = str
                    end
                end
                
                return results
            end)(),
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                vim.cmd("call g:SendCmdToR('" .. selection[1] .. "')")
            end)
            return true
        end
    }):find()
end

return require("telescope").register_extension {
  setup = function(config)
  end,
  exports = { rhistory = get_rhistory }
}
