
-- require pattern
-- module for storing the require pattern used to find requires in scripts

return "local%s+%w+%s*=%s*require%s*%(%-?%-?%-?[\"'`](.-)[\"'`]%)"