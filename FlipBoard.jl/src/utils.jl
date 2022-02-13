function _log_board(expr; wait_sec=missing, label=missing)
    ismissing(label) ? println("Trying `$expr`...") :  println(label, "...")
    eval(expr)
    println("")
    ismissing(wait_sec) ? Base.prompt("Press any key to continue") : sleep(wait_sec)
    return nothing
end

macro log_board(expr)
    return _log_board(expr)
end
