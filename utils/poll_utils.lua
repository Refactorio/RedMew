local Public = {}

--- Returns the index for the answer with the most votes.
-- If there is a tie one index from the ties is picked randomly usign rng
-- Returns nil if passed in zero answers.
-- rng defaults to math.random if not provided.
function Public.get_poll_winner(answers, rng)
    local rand = rng or math.random
    local vote_counts = {}
    for i, answer_data in pairs(answers) do
        vote_counts[i] = answer_data.voted_count or 0
    end

    local max_count = -math.huge
    for i = 1, #vote_counts do
        local count = vote_counts[i]
        if count > max_count then
            max_count = count
        end
    end

    if max_count == -math.huge then
        return nil
    end

    local max_indexes = {}
    for i = 1, #vote_counts do
        local count = vote_counts[i]
        if count == max_count then
            max_indexes[#max_indexes + 1] = i
        end
    end

    return max_indexes[rand(#max_indexes)]
end

return Public
