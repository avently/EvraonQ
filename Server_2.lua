if getScriptPath then
    package.path = package.path .. ";" .. getScriptPath() .."\\?.lua;"
end
require "Server"

-- Do not edit this file. Just copy it and save with a different name. Then write required params for it inside config.json file
-- Не редактируйте этой файл. Просто скопируйте и сохраните под другим именем. После этого укажите настройки для него в файле config.json

function main()
    setup(utils.script_file_name())
end

if not getScriptPath then main() end