module Promises

module 💛
include("./notebook.jl")
end

const Promise = 💛.Promise
const all = 💛.promise_all
const any = 💛.promise_any
const race = 💛.promise_race
const resolve = 💛.Promises.resolve
const reject = 💛.Promises.reject
const await_settled = 💛.await_settled
const Resolved = 💛.Resolved
const Rejected = 💛.Rejected
const PromiseSettledResult = 💛.PromiseSettledResult
const var"@await" = 💛.var"@await"
const var"@async_promise" = 💛.var"@async_promise"

export Promise,
    @await,
    @async_promise


end
