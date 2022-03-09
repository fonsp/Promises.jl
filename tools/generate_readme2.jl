### A Pluto.jl notebook ###
# v0.18.1

using Markdown
using InteractiveUtils

# ╔═╡ 96c26596-9fef-11ec-351a-11ad73639906
begin
	
	const PROJECT_ROOT = dirname(@__DIR__)
	const TEST_DIR = joinpath(PROJECT_ROOT, "test")
	
	import Pkg

	new_env = mktempdir()
	cp(TEST_DIR, new_env; force=true)
	
	copy!(LOAD_PATH, ["@", PROJECT_ROOT])
	Pkg.activate(new_env)

	# development dependencies
	import Downloads
	import JSON
	using BenchmarkTools
	using PlutoTest


	using HypertextLiteral
	import AbstractPlutoDingetjes

	import Pluto
	using PlutoHooks
end

# ╔═╡ 72204279-d847-4bc6-9365-83a0299c8a38
s = Pluto.ServerSession(;options=Pluto.Configuration.from_flat_kwargs(;
	launch_browser=false,
	disable_writing_notebook_files=true,
	auto_reload_from_file=true,
	lazy_workspace_creation=true,
))

# ╔═╡ 1ee7d783-88c1-418f-ae18-d1a25049b467
const nb_path = joinpath(PROJECT_ROOT, "src", "notebook.jl")

# ╔═╡ a0deb59c-9fb1-4e3c-9761-690e3c42af76
begin
	for n in values(s.notebooks)
		Pluto.SessionActions.shutdown(s, n; keep_in_session=false)
	end
	const nb_original = Pluto.SessionActions.open(
		s, nb_path;
		run_async=false,
	)
end

# ╔═╡ 06c8d69c-16bd-4dc1-97ef-f3410c30e756


# ╔═╡ c7f642e6-0660-4bc0-948e-77fadd128b59


# ╔═╡ d6fe479d-0e08-4e1d-af57-deb1e78ce300


# ╔═╡ bf9e7649-6489-4464-adaf-a7e7b9d7c9c0
md"""
### Making sure all cells ran

Some cells skipped running because they were rendered server-side (markdown-only cells). Run them manually.
"""

# ╔═╡ c4d5f03c-3787-4d8d-afff-a324a76ad899
rendered_original = Pluto.WorkspaceManager.eval_fetch_in_workspace(
	(s, nb_original),
	:(PlutoRunner.cell_results |> keys |> collect)
)

# ╔═╡ 0d6a1a94-44a7-454f-ae42-8fde9c3c0977
begin
	to_render = setdiff([c.cell_id for c in nb_original.cells], rendered_original)
	Pluto.update_save_run!(s, nb_original, [nb_original.cells_dict[id] for id in to_render]; run_async=false)
	
	nb = nb_original
end;

# ╔═╡ 40212e56-3085-4425-a043-1d43fd9ded2c


# ╔═╡ 32a28dac-0ea8-4ba9-a708-37a30241e700
md"""
### Choosing the cells that we want to render
"""

# ╔═╡ 2f251c46-0c96-482b-acbb-2c98f342deff
selected_cell_indices = let
	match = findfirst(nb.cells) do c
		occursin("# Implementation", c.code)
	end

	match === nothing ? eachindex(nb.cells) : (1:match-1)
end

# ╔═╡ cbf5e7ce-8a58-4a83-a36a-2f2fb7830c0b
selected_cells = nb.cells[selected_cell_indices]

# ╔═╡ 40100b17-f1c3-410c-b5bd-572ee3587afa
length(selected_cells)

# ╔═╡ c6f9f70d-a0fd-4c7f-bfbe-f26e4df054cd


# ╔═╡ a3e2bf13-a0ed-4b58-a503-c6c81652db3c
md"""
### Render to Markdown functions
"""

# ╔═╡ 3aa0f01d-7cf9-45c2-af4d-2db45098c635
function cell_repr(cell::Pluto.Cell)::Tuple{String,MIME}
	ws = Pluto.WorkspaceManager.get_workspace((s, nb_original))
	Pluto.WorkspaceManager.eval_fetch_in_workspace(
		(s, nb_original),
		quote
			result = PlutoRunner.cell_results[$(cell.cell_id)]

			if result isa CapturedException
				val = result
				stack = [s for (s, _) in val.processed_bt]

			    function_wrap_index = findlast(f -> occursin("#==#", String(f.file)), stack)
			
			    if function_wrap_index === nothing
			        for _ in 1:2
			            until = findfirst(b -> b.func == :eval, reverse(stack))
			            stack = until === nothing ? stack : stack[1:end - until]
			        end
			    else
			        stack = stack[1:function_wrap_index]
			    end
				
				return (
					sprint(showerror, result.ex, stack), 
					MIME"text/plain"()
				)
			end

			if result isa Nothing
				return ("", MIME"text/plain"())
			end
			
			mime = if result isa Markdown.MD
				MIME"text/markdown"()
			else
				MIME"text/plain"()
			end
	
			repr(mime, result; context=IOContext(devnull,
				:color => false, :limit => true, :displaysize => (18, 88),
				:module => getfield(Main, $(QuoteNode(ws.module_name)))
			)), mime
		end
	)
end

# ╔═╡ 3293c088-653e-4ca4-9432-e01c12a1ed18
:(a + $(QuoteNode(:s)))

# ╔═╡ 699ebe9c-ff49-4a27-952a-e72eddd4dfa8
function cell_md_data(cell::Pluto.Cell)::String
	output = let
		prefix = let
			r = cell.output.rootassignee
			if r isa Symbol
				"$(r) = "
			else
				""
			end
		end
		
		data, mime = cell_repr(cell)
		if mime isa MIME"text/markdown" || mime isa MIME"text/html"
			prefix * data
		else
			isempty(data) ? prefix : "```\n$(prefix * data)\n```"
		end
	end
	input = let
		if cell.code_folded
			""
		else
			"```julia\n$(cell.code)\n```"
		end
	end
	

	if isempty(output) && isempty(input)
		"\n<br>\n\n"
	else
		output * "\n" * input * "\n"
	end
end

# ╔═╡ 13f47c9d-a2e6-4ebf-b483-001c6d2fa25e


# ╔═╡ 5c4a510e-c717-480e-9207-66059f206194
md"""
### Let's go!
"""

# ╔═╡ b8716356-2e56-4c0c-bf25-1d9bbe63c9c5
md_data = replace(
	join(cell_md_data.(selected_cells), "\n"),
	r"^@skip_as_script "m => ""
)

# ╔═╡ 2988531d-e94d-4cd9-aa87-f88a115d5f25
Text(md_data)

# ╔═╡ cf83c853-ba25-40db-a635-902f64779ffc
@htl """
<h1>Preview</h1>
<div style='max-height: 60vh; overflow-y: auto; border: 5px solid teal; padding: 1em; border-radius: 6px;'>
$(Markdown.parse(md_data))
</div>
"""

# ╔═╡ 013e190a-e119-414f-8898-972c994e1dcf
md"""
### Write to `README.md`
"""

# ╔═╡ d7a2b1da-95ae-408b-9531-0b0a4ce46054
const REAMDE_PATH = joinpath(PROJECT_ROOT, "README.md")

# ╔═╡ b81b8c8e-ba08-4d58-a502-663d93c32964
write(REAMDE_PATH, md_data)

# ╔═╡ Cell order:
# ╠═96c26596-9fef-11ec-351a-11ad73639906
# ╠═72204279-d847-4bc6-9365-83a0299c8a38
# ╠═1ee7d783-88c1-418f-ae18-d1a25049b467
# ╠═a0deb59c-9fb1-4e3c-9761-690e3c42af76
# ╠═06c8d69c-16bd-4dc1-97ef-f3410c30e756
# ╠═c7f642e6-0660-4bc0-948e-77fadd128b59
# ╟─d6fe479d-0e08-4e1d-af57-deb1e78ce300
# ╟─bf9e7649-6489-4464-adaf-a7e7b9d7c9c0
# ╠═c4d5f03c-3787-4d8d-afff-a324a76ad899
# ╠═0d6a1a94-44a7-454f-ae42-8fde9c3c0977
# ╟─40212e56-3085-4425-a043-1d43fd9ded2c
# ╟─32a28dac-0ea8-4ba9-a708-37a30241e700
# ╠═2f251c46-0c96-482b-acbb-2c98f342deff
# ╟─cbf5e7ce-8a58-4a83-a36a-2f2fb7830c0b
# ╠═40100b17-f1c3-410c-b5bd-572ee3587afa
# ╟─c6f9f70d-a0fd-4c7f-bfbe-f26e4df054cd
# ╟─a3e2bf13-a0ed-4b58-a503-c6c81652db3c
# ╠═3aa0f01d-7cf9-45c2-af4d-2db45098c635
# ╠═3293c088-653e-4ca4-9432-e01c12a1ed18
# ╠═699ebe9c-ff49-4a27-952a-e72eddd4dfa8
# ╟─13f47c9d-a2e6-4ebf-b483-001c6d2fa25e
# ╟─5c4a510e-c717-480e-9207-66059f206194
# ╟─b8716356-2e56-4c0c-bf25-1d9bbe63c9c5
# ╠═2988531d-e94d-4cd9-aa87-f88a115d5f25
# ╟─cf83c853-ba25-40db-a635-902f64779ffc
# ╠═013e190a-e119-414f-8898-972c994e1dcf
# ╠═d7a2b1da-95ae-408b-9531-0b0a4ce46054
# ╠═b81b8c8e-ba08-4d58-a502-663d93c32964
