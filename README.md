# Promises.jl: *JavaScript-inspired async*


You can use Promises.jl to run code in the background:


```julia
download_result = Promise((resolve, reject) -> begin

	filename = Downloads.download("https://api.github.com/users/$(username)")

	# call `resolve` with the result
	resolve(filename)
	
end)

#=>  Promise{Any}( <resolved>: "/var/folders/v_/fhpj9jn151d4p9c2fdw2gv780000gn/T/jl_VNrh2x" )
```

```
username = "JuliaLang"
```

The result is a *pending promise*: it might still running in the background! 


```julia
download_result

#=>  Promise{Any}( <resolved>: "/var/folders/v_/fhpj9jn151d4p9c2fdw2gv780000gn/T/jl_VNrh2x" )
```

You can use `@await` to wait for it to finish, and get its value:


```julia
@await download_result

#=>  "/var/folders/v_/fhpj9jn151d4p9c2fdw2gv780000gn/T/jl_VNrh2x"
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
Promise{Any}( <resolved>: Dict{String, Any} with 32 entries:
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

<br>


## Error handling: `reject` and `.catch`

A promise can finish in two ways: it can **resolve** or it can **reject**. This corresponds to the two functions in the constructor, `resolve` and `reject`:

```julia
Promise((resolve, reject) -> begin

	if condition
		# Resolve the promise:
		resolve("Success!")
	else
		# Reject the promise
		reject("Something went wrong...")
	end
end)
```

If you `@await` a promise that has rejected, the rejected value will be rethrown as an error:


```julia
oopsie_result = Promise((res, rej) -> rej("oops!"))

#=>  Promise{Any}( <rejected>: "oops!" )
```

```julia
@await oopsie_result

#=>  
"oops!"
Stacktrace:
 [1] fetch(p::Main.workspace#3.Promise{Any})
   @ Main.workspace#3 ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:78
```

In addition, when an exception occurs inside a Promise body, the Promise will reject, with the error message as rejected value:


```julia
Promise((res, rej) -> res(sqrt(-1)))

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
 [4] (::Main.var"#9#10"{typeof(sqrt)})(res::Main.workspace#3.var"#resolve#11"{Any, Promise{Any}}, rej::Function)
   @ Main ~/Documents/Promises.jl/src/notebook.jl#==#34364f4d-e257-4c22-84ee-d8786a2c377c:1
 [5] macro expansion
   @ ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:33 [inlined]
 [6] (::Main.workspace#3.var"#3#10"{Any, Main.var"#9#10"{typeof(sqrt)}, Promise{Any}})()
   @ Main.workspace#3 ./task.jl:423
 )
```

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

Trying to resolve to another type will reject the Promise:


```julia
Promise{String}((res,rej) -> res(12341234))

#=>  
Promise{String}( <rejected>: 
ArgumentError: Can only resolve with values of type String.
Stacktrace:
 [1] (::Main.workspace#3.var"#resolve#11"{String, Promise{String}})(val::Int64)
   @ Main.workspace#3 ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:16
 [2] #25
   @ ~/Documents/Promises.jl/src/notebook.jl#==#9d9179de-19b1-4f40-b816-454a8c071c3d:1 [inlined]
 [3] macro expansion
   @ ~/Documents/Promises.jl/src/notebook.jl#==#49a8beb7-6a97-4c46-872e-e89822108f39:33 [inlined]
 [4] (::Main.workspace#3.var"#3#10"{String, Main.var"#25#26", Promise{String}})()
   @ Main.workspace#3 ./task.jl:423
 )
```

This information is available to the Julia compiler, which means that it can do smart stuff!


```julia
Core.Compiler.return_type(fetch, (Promise{String},))

#=>  String
```


<br>

