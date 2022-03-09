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

export Promise,
    @await


end
