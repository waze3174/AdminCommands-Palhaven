local FGuid = {}

---@param Userdata FGuid
---@return table
function FGuid.translate(Userdata)
    local self = {}

    self.A = Userdata.A
    self.B = Userdata.B
    self.C = Userdata.C
    self.D = Userdata.D

    return self
end

---@param Userdata FGuid
---@return string
function FGuid.toString(Userdata)
    return string.format("%08X-%08X-%08X-%08X", Userdata.A or 0, Userdata.B or 0, Userdata.C or 0, Userdata.D or 0)
end

return FGuid