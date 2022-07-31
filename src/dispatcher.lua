function dispatch_task(task)
	if task.type == "group" then
		for _, v in ipairs(task.tasks) do dispatch_task(v) end
		return
	end

	local best_worker = false
	local best_time = 999999999999999999
	for _, v in pairs(global.workers) do
		local t = Worker.absolute_task_price(v, task)
		if t < best_time then
			best_time = t
			best_worker = v
		end
	end
	if not best_worker then
		le('dispatcher found no workers')
	else
		Worker.enqueue(best_worker, task)
	end
end
