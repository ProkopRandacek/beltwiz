function dispatch_task(task)
    if task.type == "group" then
        for k, v in pairs(task) do dispatch_task(v) end
        return
    end

    lv("Dispatching", task, "between", global.workers)
    local best_worker = false
    local best_time = 999999999999999999
    for k, v in pairs(global.workers) do
        local t = Worker.absolute_task_price(v, task)
        lv("worker " ..  v.index .. " can do task in " .. t)
        if t < best_time then
            best_time = t
            best_worker = v
        end
    end
    if best_worker == false then
        le('dispatcher found no workers')
    else
        lv('choose worker', best_worker.index)
        Worker.enqueue(best_worker, task)
    end
end

