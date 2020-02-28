@doc raw"""
    SymmetricMatrices{n,𝔽} <: AbstractEmbeddedManifold{DefaultIsometricEmbedding}

The [`Manifold`](@ref) $ \operatorname{Sym}(n)$ consisting of the real- or complex-valued
symmetric matrices of size $n × n$, i.e. the set

````math
\operatorname{Sym}(n) = \bigl\{p  ∈ 𝔽^{n × n} \big| p^{\mathrm{H}} = p \bigr\},
````
where $\cdot^{\mathrm{H}}$ denotes the hermitian, i.e. complex conjugate transpose,
and the field $𝔽 ∈ \{ ℝ, ℂ\}$.

Though it is slightly redundant, usually the matrices are stored as $n × n$ arrays.

# Constructor

    SymmetricMatrices(n::Int, field::AbstractNumbers=ℝ)

Generate the manifold of $n × n$ symmetric matrices.
"""
struct SymmetricMatrices{n,𝔽} <: AbstractEmbeddedManifold{DefaultIsometricEmbedding} end

function SymmetricMatrices(n::Int, field::AbstractNumbers = ℝ)
    SymmetricMatrices{n,field}()
end

base_manifold(M::SymmetricMatrices) = M
decorated_manifold(M::SymmetricMatrices{N,𝔽}) where {N,𝔽} = Euclidean(N,N; field=𝔽)
get_embedding(M::SymmetricMatrices{N,𝔽}) where {N,𝔽} = Euclidean(N,N; field=𝔽)
@doc raw"""
    check_manifold_point(M::SymmetricMatrices{n,𝔽}, p; kwargs...)

Check whether `p` is a valid manifold point on the [`SymmetricMatrices`](@ref) `M`, i.e.
whether `p` is a symmetric matrix of size `(n,n)` with values from the corresponding
[`AbstractNumbers`](@ref) `𝔽`.

The tolerance for the symmetry of `p` can be set using `kwargs...`.
"""
function check_manifold_point(M::SymmetricMatrices{n,𝔽}, p; kwargs...) where {n,𝔽}
    if (𝔽 === ℝ) && !(eltype(p) <: Real)
        return DomainError(
            eltype(p),
            "The matrix $(p) does not lie on $M, since its values are not real.",
        )
    end
    if (𝔽 === ℂ) && !(eltype(p) <: Real) && !(eltype(p) <: Complex)
        return DomainError(
            eltype(p),
            "The matrix $(p) does not lie on $M, since its values are not complex.",
        )
    end
    if size(p) != (n, n)
        return DomainError(
            size(p),
            "The point $(p) does not lie on $M since its size ($(size(p))) does not match the representation size ($(representation_size(M))).",
        )
    end
    if !isapprox(norm(p - transpose(p)), 0.0; kwargs...)
        return DomainError(
            norm(p - transpose(p)),
            "The point $(p) does not lie on $M, since it is not symmetric.",
        )
    end
    return nothing
end

"""
    check_tangent_vector(M::SymmetricMatrices{n,𝔽}, p, X; check_base_point = true, kwargs... )

Check whether `X` is a tangent vector to manifold point `p` on the
[`SymmetricMatrices`](@ref) `M`, i.e. `X` has to be a symmetric matrix of size `(n,n)`
and its values have to be from the correct [`AbstractNumbers`](@ref).
The optional parameter `check_base_point` indicates, whether to call
 [`check_manifold_point`](@ref)  for `p`.
The tolerance for the symmetry of `p` and `X` can be set using `kwargs...`.
"""
function check_tangent_vector(
    M::SymmetricMatrices{n,𝔽},
    p,
    X;
    check_base_point = true,
    kwargs...
) where {n,𝔽}
    if check_base_point
        t = check_manifold_point(M, p; kwargs...)
        t === nothing || return t
    end
    if (𝔽 === ℝ) && !(eltype(X) <: Real)
        return DomainError(
            eltype(X),
            "The matrix $(X) is not a tangent to a point on $M, since its values are not real.",
        )
    end
    if (𝔽 === ℂ) && !(eltype(X) <: Real) && !(eltype(X) <: Complex)
        return DomainError(
            eltype(X),
            "The matrix $(X) is not a tangent to a point on $M, since its values are not complex.",
        )
    end
    if size(X) != (n, n)
        return DomainError(
            size(X),
            "The vector $(X) is not a tangent to a point on $(M) since its size ($(size(X))) does not match the representation size ($(representation_size(M))).",
        )
    end
    if !isapprox(norm(X - transpose(X)), 0.0; kwargs...)
        return DomainError(
            norm(X - transpose(X)),
            "The vector $(X) is not a tangent vector to $(p) on $(M), since it is not symmetric.",
        )
    end
    return nothing
end

embed!(M::SymmetricMatrices, q, p) = copyto!(q, p)

function get_basis(M::SymmetricMatrices, p, B::DiagonalizingOrthonormalBasis) where {n}
    vecs = get_basis(M, p, ArbitraryOrthonormalBasis()).vectors
    kappas = zeros(real(eltype(p)), manifold_dimension(M))
    return PrecomputedDiagonalizingOrthonormalBasis(vecs, kappas)
end

function get_coordinates(
    M::SymmetricMatrices{N,ℝ},
    p,
    X,
    B::ArbitraryOrthonormalBasis{ℝ},
) where {N}
    dim = manifold_dimension(M)
    Y = similar(X, dim)
    @assert size(X) == (N, N)
    @assert dim == div(N * (N + 1), 2)
    k = 1
    for i = 1:N, j = i:N
        scale = ifelse(i == j, 1, sqrt(2))
        @inbounds Y[k] = X[i, j] * scale
        k += 1
    end
    return Y
end
function get_coordinates(
    M::SymmetricMatrices{N,ℂ},
    p,
    X,
    B::ArbitraryOrthonormalBasis{ℝ},
) where {N}
    dim = manifold_dimension(M)
    Y = similar(X, dim)
    @assert size(X) == (N, N)
    @assert dim == N * (N + 1)
    k = 1
    for i = 1:N, j = i:N
        scale = ifelse(i == j, 1, sqrt(2))
        @inbounds Y[k] = real(X[i, j]) * scale
        k += 1
        @inbounds Y[k] = imag(X[i, j]) * scale
        k += 1
    end
    return Y
end

function get_vector(
    M::SymmetricMatrices{N,ℝ},
    p,
    X,
    B::ArbitraryOrthonormalBasis{ℝ},
) where {N}
    dim = manifold_dimension(M)
    Y = allocate_result(M, get_vector, p)
    @assert size(X) == (div(N * (N + 1), 2),)
    @assert size(Y) == (N, N)
    k = 1
    for i = 1:N, j = i:N
        scale = ifelse(i == j, 1, 1 / sqrt(2))
        @inbounds Y[i, j] = X[k] * scale
        @inbounds Y[j, i] = X[k] * scale
        k += 1
    end
    return Y
end
function get_vector(
    M::SymmetricMatrices{N,ℂ},
    p,
    X,
    B::ArbitraryOrthonormalBasis{ℝ},
) where {N}
    dim = manifold_dimension(M)
    Y = allocate_result(M, get_vector, p, p .* 1im)
    @assert size(X) == (N * (N + 1),)
    @assert size(Y) == (N, N)
    k = 1
    for i = 1:N, j = i:N
        scale = ifelse(i == j, 1, 1 / sqrt(2))
        @inbounds Y[i, j] = Complex(X[k], X[k+1]) * scale
        @inbounds Y[j, i] = Y[i, j]
        k += 2
    end
    return Y
end

@doc raw"""
manifold_dimension(M::SymmetricMatrices{n,𝔽})

Return the dimension of the [`SymmetricMatrices`](@ref) matrix `M` over the number system
`𝔽`, i.e.

````math
\dim \operatorname{Sym}(n,𝔽) = \frac{n(n+1)}{2} \dim_ℝ 𝔽,
````

where $\dim_ℝ 𝔽$ is the [`real_dimension`](@ref) of `𝔽`.
"""
function manifold_dimension(::SymmetricMatrices{N,𝔽}) where {N,𝔽}
    return div(N * (N + 1), 2) * real_dimension(𝔽)
end

@doc raw"""
    project_point(M::SymmetricMatrices, p)

Projects `p` from the embedding onto the [`SymmetricMatrices`](@ref) `M`, i.e.

````math
\operatorname{proj}_{\operatorname{Sym}(n)}(p) = \frac{1}{2} \bigl( p + p^{\mathrm{H}} \bigr),
````

where $\cdot^{\mathrm{H}}$ denotes the hermitian, i.e. complex conjugate transposed.
"""
project_point(::SymmetricMatrices, ::Any...)

project_point!(M::SymmetricMatrices, q, p) = copyto!(q, (p + p') ./ 2)

@doc raw"""
    project_tangent(M::SymmetricMatrices, p, X)

Project the matrix `X` onto the tangent space at `p` on the [`SymmetricMatrices`](@ref) `M`,

````math
\operatorname{proj}_p(X) = \frac{1}{2} \bigl( X + X^{\mathrm{H}} \bigr),
````

where $\cdot^{\mathrm{H}}$ denotes the hermitian, i.e. complex conjugate transposed.
"""
project_tangent(::SymmetricMatrices, ::Any...)

project_tangent!(M::SymmetricMatrices, Y, p, X) = (Y .= (X .+ transpose(X)) ./ 2)

function show(io::IO, ::SymmetricMatrices{n,F}) where {n,F}
    print(io, "SymmetricMatrices($(n), $(F))")
end
