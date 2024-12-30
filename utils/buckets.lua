local DEFAULT_INTERVAL = 60

local Buckets = {}

---@param interval? number
function Buckets.new(interval)
  return { list = {}, interval = interval or DEFAULT_INTERVAL }
end

---@param bucket table
---@param id number|string
---@param data any
function Buckets.add(bucket, id, data)
  local bucket_id = id % bucket.interval
  bucket.list[bucket_id] = bucket.list[bucket_id] or {}
  bucket.list[bucket_id][id] = data or {}
end

---@param bucket table
---@param id number|string
function Buckets.get(bucket, id)
  if not id then return end
  local bucket_id = id % bucket.interval
  return bucket.list[bucket_id] and bucket.list[bucket_id][id]
end

---@param bucket table
---@param id number|string
function Buckets.remove(bucket, id)
  if not id then return end
  local bucket_id = id % bucket.interval
  if bucket.list[bucket_id] then
    bucket.list[bucket_id][id] = nil
  end
end

---@param bucket table
---@param id number|string
function Buckets.get_bucket(bucket, id)
  local bucket_id = id % bucket.interval
  bucket.list[bucket_id] = bucket.list[bucket_id] or {}
  return bucket.list[bucket_id]
end

-- Redistributes current buckets content over a new time interval
---@param bucket table
---@param new_interval number
function Buckets.reallocate(bucket, new_interval)
  new_interval = new_interval or DEFAULT_INTERVAL
  if bucket.interval == new_interval then
    return
  end
  local tmp = {}

  -- Collect data from existing buckets
  for b_id = 0, bucket.interval - 1 do
    for id, data in pairs(bucket.list[b_id] or {}) do
      tmp[id] = data
    end
  end

  -- Clear old buckets
  bucket.list = {}

  -- Update interval and reinsert data
  bucket.interval = new_interval
  for id, data in pairs(tmp) do
    Buckets.add(bucket, id, data)
  end
end

-- Distributes a table's content over a time interval
---@param tbl table
---@param interval? number
function Buckets.migrate(tbl, interval)
  local bucket = Buckets.new(interval)
  for id, data in pairs(tbl) do
    Buckets.add(bucket, id, data)
  end
  return bucket
end

return Buckets
