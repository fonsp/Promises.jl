# Promises.jl: *JavaScript-inspired async*

> #### Summary:
>
> A **`Promise{T}`** is a container for a value **that will arrive in the future**. 
>
> You can **await** Promises, and you can **chain** processing steps with `.then` and `.catch`, each producing a new `Promise`.



Let's look at an example, using Promises.jl to download data in the background:


```julia
download_result = @async_promise begin

	# This will download the data, 
	#  write the result to a file, 
	#  and return the filename.
	Downloads.download("https://api.github.com/users/$(username)")
end

#=>  Promise{Any}( <pending> )
```

```
username = "JuliaLang"
```

The result is a *pending promise*: it might still running in the background! 


```julia
download_result

#=>  Promise{Any}( <pending> )
```

You can use `@await` to wait for it to finish, and get its value:


```julia
@await download_result

#=>  "/var/folders/v_/fhpj9jn151d4p9c2fdw2gv780000gn/T/jl_LqoUCC"
```

<br>


## Chaining with `then`

One cool feature of promises is **chaining**! Every promise has a `then` function, which can be used to add a new transformation to the chain, returning a new `Promise`.


```julia
download_result.then(
	filename -> read(filename, String)
).then(
	str -> JSON.parse(str)
)

#=>  
Promise{Dict{String, Any}}( <resolved>: Dict{String, Any} with 32 entries:
  "followers"         => 0
  "created_at"        => "2011-04-21T06:33:51Z"
  "repos_url"         => "https://api.github.com/users/JuliaLang/repos"
  "login"             => "JuliaLang"
  "gists_url"         => "https://api.github.com/users/JuliaLang/gists{/gist_id}"
  "public_repos"      => 36
  "following"         => 0
  "site_admin"        => false
  "name"              => "The Julia Programming Language"
  "location"          => nothing
  "blog"              => "https://julialang.org"
  "subscriptions_url" => "https://api.github.com/users/JuliaLang/subscriptions"
  "id"                => 743164
  ⋮                   => ⋮ )
```

Since the original Promise `download_result` was asynchronous, this newly created `Promise` is also asynchronous! By chaining the operations `read` and `JSON.parse`, you are "queing" them to run in the background.


<br>


## Error handling: rejected Promises

A Promise can finish in two ways: it can **✓ resolve** or it can **✗ reject**. In both cases, the `Promise{T}` will store a value, either the *resolved value* (of type `T`) or the *rejected value* (often an error message). 

When an error happens inside a Promise handler, it will reject:


```julia
bad_result = download_result.then(d -> sqrt(-1))

#=>  
Promise{Any}( <rejected>: 
DomainError with -1.0:
sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
Stacktrace:
 [1] throw_complex_domainerror(f::Symbol, x::Float64)
   @ Base.Math ./math.jl:33
 [2] sqrt
   @ ./math.jl:567 [inlined]
 [3] sqrt(x::Int64)
   @ Base.Math ./math.jl:1221
 [4] (::Main.var"#5#6"{typeof(sqrt)})(d::String)
   @ Main ~/Documents/Promises.jl/src/notebook.jl#==#34364f4d-e257-4c22-84ee-d8786a2c377c:1
 [5] promise_then(p::Promise{Any}, f::Main.var"#5#6"{typeof(sqrt)})
   @ Main.workspace#3 ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:63
 [6] #18
   @ ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:175 [inlined]
 )
```

If you `@await` a Promise that has rejected, the rejected value will be rethrown as an error:


```julia
@await bad_result

#=>  
DomainError with -1.0:
sqrt will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
Stacktrace:
 [1] throw_complex_domainerror(f::Symbol, x::Float64)
   @ Base.Math ./math.jl:33
 [2] sqrt
   @ ./math.jl:567 [inlined]
 [3] sqrt(x::Int64)
   @ Base.Math ./math.jl:1221
 [4] (::var"#5#6"{typeof(sqrt)})(d::String)
   @ Main ~/Documents/Promises.jl/src/notebook.jl#==#34364f4d-e257-4c22-84ee-d8786a2c377c:1
 [5] promise_then(p::Main.workspace#3.Promise{Any}, f::var"#5#6"{typeof(sqrt)})
   @ Main.workspace#3 ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:63
 [6] #18
   @ ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:175 [inlined]
Stacktrace:
 [1] fetch(p::Main.workspace#3.Promise{Any})
   @ Main.workspace#3 ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:112
```

<br>


## The `Promise` constructor

Remember that a promise can finish in two ways: it can **✓ resolve** or it can **✗ reject**. When creating a Promise by hand, this corresponds to the two functions passed in by the constructor, `resolve` and `reject`:

```julia
Promise{T=Any}(resolve, reject) -> begin

	if condition
		# Resolve the promise:
		resolve("Success!")
	else
		# Reject the promise
		reject("Something went wrong...")
	end
end)
```


```julia
yay_result = Promise((resolve, reject) -> resolve("🌟 yay!"))

#=>  Promise{Any}( <resolved>: "🌟 yay!" )
```

```julia
oopsie_result = Promise((res, rej) -> rej("oops!"))

#=>  Promise{Any}( <rejected>: "oops!" )
```

(A shorthand function is available to create promises that immediately reject or resolve, like we did above: `Promises.resolve(value)` and `Promises.reject(value)`.)


<br>


### Chaining errors with `.catch`

There are two special things about rejected values in chains:

1. The `.then` function of a rejected Promise will *immediately reject*, passing the value along.


```julia
Promise((res, rej) -> rej("oops!")).then(x -> x + 10).then(x -> x / 100)

#=>  Promise{Any}( <rejected>: "oops!" )
```

2. The `.catch` is the opposite of `.then`: it is used to handle rejected values.


```julia
Promise((res, rej) -> rej("oops!")).then(x -> x + 10).catch(x -> 123)

#=>  Promise{Any}( <resolved>: 123 )
```

Here is a little table:

|                            |   `.then` |  `.catch` |
| --------------------------:| ---------:| ---------:|
| On a **resolved** Promise: |      Runs | *Skipped* |
| On a **rejected** Promise: | *Skipped* |      Runs |


<br>


### `Promise{T}` is a parametric type

Like in TypeScript, the `Promise{T}` can specify its **resolve type**. For example, `Promise{String}` is guaranteed to resolve to a `String`.


```julia
Promise{String}((res,rej) -> res("asdf"))

#=>  Promise{String}( <resolved>: "asdf" )
```

This information is available to the Julia compiler, which means that it can do smart stuff!


```julia
Core.Compiler.return_type(fetch, (Promise{String},))

#=>  String
```

Trying to resolve to another type will reject the Promise:


```julia
Promise{String}((res,rej) -> res(12341234))

#=>  
Promise{String}( <rejected>: 
ArgumentError: Can only resolve with values of type String.
Stacktrace:
 [1] (::Main.workspace#3.var"#resolve#20"{String, Promise{String}})(val::Int64)
   @ Main.workspace#3 ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:21
 [2] (::Main.var"#25#26")(res::Main.workspace#3.var"#resolve#20"{String, Promise{String}}, rej::Function)
   @ Main ~/Documents/Promises.jl/src/notebook.jl#==#9d9179de-19b1-4f40-b816-454a8c071c3d:1
 [3] Promise{String}(f::Main.var"#25#26")
   @ Main.workspace#3 ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:38
 )
```

#### Automatic types

Julia is smart, and it can automatically determine the type of chained Promises using static analysis!


```julia
typeof(
	Promise{String}((res,rej) -> res("asdf")).then(first)
)

#=>  Promise{Char}
```


<br>

