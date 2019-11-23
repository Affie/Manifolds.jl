using LinearAlgebra: diagm, diag, eigen, eigvals, eigvecs, Symmetric, Diagonal, factorize, tr, norm, cholesky, LowerTriangular

@doc doc"""
    SymmetricPositiveDefinite{N} <: Manifold

The manifold of symmetric positive definite matrices, i.e.

```math
\mathcal P(n) =
\bigl\{
    x \in \mathbb R^{n\\times n} :
    \xi^\mathrm{T}x\xi > 0 \text{ for all } \xi \in \mathbb R^{n}\backslash\{0\}
\bigr\}
```

# Constructor

    SymmetricPositiveDefinite(n)

generates the manifold $\mathcal P(n) \subset \mathbb R^{n\times n}$
"""
struct SymmetricPositiveDefinite{N} <: Manifold end
SymmetricPositiveDefinite(n::Int) = SymmetricPositiveDefinite{n}()

@doc doc"""
    manifold_dimension(::SymmetricPositiveDefinite{N})

returns the dimension of the manifold [`SymmetricPositiveDefinite`](@ref) $\mathcal P(n), N\in \mathbb N$, i.e.
```math
    \frac{n(n+1)}{2}    
```
"""
@generated manifold_dimension(::SymmetricPositiveDefinite{N}) where {N} = div(N*(N+1), 2)

@doc doc"""
    LinearAffineMetric <: Metric

The linear affine metric is the metric for symmetric positive definite matrices, that employs
matrix logarithms and exponentials, which yields a linear and affine metric.
"""
struct LinearAffineMetric <: RiemannianMetric end
# Make this metric default, i.e. automatically convert
convert(::Type{SymmetricPositiveDefinite{N}}, M::MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric}) where N = M.manifold
convert(::Type{SymmetricPositiveDefinite}, M::MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric}) where N = M.manifold
convert(::Type{MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric}}, M::SymmetricPositiveDefinite{N}) where N = MetricManifold(M, LinearAffineMetric())

@doc doc"""
    LogEuclideanMetric <: Metric

The LogEuclidean Metric consists of the Euclidean metric applied to all elements after mapping them
into the Lie Algebra, i.e. performing a matrix logarithm beforehand.
"""
struct LogEuclideanMetric <: RiemannianMetric end

@doc doc"""
    LogCholeskyMetric <: Metric

The Log-Cholesky metric imposes a metric based on the Cholesky decomposition as
introduced by
> Lin, Zenhua: "Riemannian Geometry of Symmetric Positive Definite Matrices via
> Cholesky Decomposition", arXiv: [1908.09326](https://arxiv.org/abs/1908.09326).
"""
struct LogCholeskyMetric <: RiemannianMetric end
cholesky_to_spd(l,w) = (l*l', w*l' + l*w')
tangent_cholesky_to_tangent_spd(l,w) = (w .= w*l' + l*w')
function spd_to_cholesky(x,v)
    l = cholesky(x).L
    a = l\v
    w = l * ( transpose(l\(a')) )
    return (l, LowerTriangular(w) + Diagonal(w)/2 )
end
function spd_to_cholesky(x,l,v)
    a = l\v
    w = l * ( transpose(l\(a')) )
    return (l, LowerTriangular(w) + Diagonal(w)/2 )
end

@doc doc"""
    distance(M,x,y)

computes the distance on the [`SymmetricPositiveDefinite`](@ref) manifold between `x` and `y`,
which defaults to the [`LinearAffineMetric`](@ref) induces distance.
"""
distance(M::SymmetricPositiveDefinite{N},x,y) where N = distance(MetricManifold(M,LinearAffineMetric()),x,y)

@doc doc"""
    distance(M,x,y)

computes the distance on the [`SymmetricPositiveDefinite`](@ref) manifold between `x` and `y`,
as a [`MetricManifold`](@ref) with [`LinearAffineMetric`](@ref). The formula reads

```math
d_{\mathcal P(n)}(x,y) = \lVert \operatorname{Log}(x^{-\frac{1}{2}}yx^{-\frac{1}{2}})\rVert_{\mathrm{F}}.,
```
where $\operatorname{Log}$ denotes the matrix logarithm and $\lVert\cdot\rVert_{\mathrm{F}}$ denotes the
matrix Frobenius norm.
"""
function distance(M::MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric},x,y) where N
    s = real.( eigvals( x,y ) )
    return any(s .<= eps() ) ? 0 : sqrt(  sum( abs.(log.(s)).^2 )  )
end

@doc doc"""
    distance(M,x,y)

computes the distance on the manifold of [`SymmetricPositiveDefinite`](@ref)
nmatrices, i.e. between two symmetric positive definite matrices `x` and `y`
with respect to the [`LogCholeskyMetric`](@ref). The formula reads

````math
    d_{\mathcal P(n)}(x,y) = 
````
"""
function distance(M::MetricManifold{SymmetricPositiveDefinite{N},LogCholeskyMetric},x,y) where N
 # TODO
end

@doc doc"""
    distance(M,x,y)

computes the distance on the [`SymmetricPositiveDefinite`](@ref) manifold between
`x` and `y` as a [`MetricManifold`](@ref) with [`LogEuclideanMetric`](@ref).
The formula reads

```math
    d_{\mathcal P(n)}(x,y) = \lVert \Log x - \Log y \rVert_{\mathrm{F}}
```
where $\operatorname{Log}$ denotes the matrix logarithm and $\lVert\cdot\rVert_{\mathrm{F}}$ denotes the
matrix Frobenius norm.
"""
function distance(M::MetricManifold{SymmetricPositiveDefinite{N},LogEuclideanMetric},x,y) where N
    eX = eigen(Symmetric(x))
    UX = eX.vectors
    SX = eX.values
    eY = eigen(Symmetric(y))
    UY = eY.vectors
    SY = eY.values
    return norm( UX*Diagonal(log.(SX))*transpose(UX) - UY*Diagonal(log.(SY))*transpose(UY))
end

@doc doc"""
    inner(M,x,v,w)

compute the inner product of `v`, `w` in the tangent space of `x` on the [`SymmetricPositiveDefinite`](@ref)
manifold `M`, which defaults to the [`LinearAffineMetric`](@ref).
"""
inner(M::SymmetricPositiveDefinite{N}, x, w, v) where N = inner(MetricManifold(M,LinearAffineMetric()),x,w,v)

@doc doc"""
    inner(M,x,v,w)

compute the inner product of `v`, `w` in the tangent space of `x` on
the [`SymmetricPositiveDefinite`](@ref) manifold `M`, as
a [`MetricManifold`](@ref) with [`LinearAffineMetric`](@ref). The formula reads

```math
( v, w)_x = \operatorname{tr}(x^{-1}\xi x^{-1}\nu ),
```
"""
function inner(M::MetricManifold{SymmetricPositiveDefinite{N}, LinearAffineMetric}, x, w, v) where N
    F = factorize(x)
    return tr( ( Symmetric(w) / F ) * ( Symmetric(v) / F ) )
end

@doc doc"""
    inner(M,x,v,w)

compute the inner product of two matrices `v`, `w` in the tangent space of `x`
on the [`SymmetricPositiveDefinite`](@ref) manifold `M`, as
a [`MetricManifold`](@ref) with [`LogCholeskyMetric`](@ref). The formula reads

````math
    ( v,w)_x = 
````
"""
function inner(M::MetricManifold{SymmetricPositiveDefinite{N},LogCholeskyMetric},x,v,w) where N
    (l,vl) = spd_to_cholesky(x,v)
    (l,wl) = spd_to_cholesky(x,l,w)
    return inner(CholeskySpace{N}(), l, vl, wl)
end

@doc doc"""
    exp!(M,y,x,v)

compute the exponential map from `x` with tangent vector `v` on the [`SymmetricPositiveDefinite`](@ref)
manifold with its default metric, [`LinearAffineMetric`](@ref) and modify `y`.
"""
exp!(M::SymmetricPositiveDefinite{N},y,x,v) where N = exp!(MetricManifold(M,LinearAffineMetric()),y,x,v)

@doc doc"""
    exp!(M,y,x,v)

compute the exponential map from `x` with tangent vector `v` on the [`SymmetricPositiveDefinite`](@ref)
as a [`MetricManifold`](@ref) with [`LinearAffineMetric`](@ref) and modify `y`. The formula reads

```math
    \exp_x v = x^{\frac{1}{2}}\operatorname{Exp}(x^{-\frac{1}{2}} v x^{-\frac{1}{2}})x^{\frac{1}{2}},
```
where $\operatorname{Exp}$ denotes to the matrix exponential.
"""
function exp!(M::MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric}, y, x, v) where N
    e = eigen(Symmetric(x))
    U = e.vectors
    S = e.values
    Ssqrt = Diagonal( sqrt.(S) )
    SsqrtInv = Diagonal( 1 ./ sqrt.(S) )
    xSqrt = Symmetric(U*Ssqrt*transpose(U))
    xSqrtInv = Symmetric(U*SsqrtInv*transpose(U))
    T = Symmetric(xSqrtInv * v * xSqrtInv)
    eig1 = eigen( T ) # numerical stabilization
    Se = Diagonal( exp.(eig1.values) )
    Ue = eig1.vectors
    xue = xSqrt*Ue
    copyto!(y, xue*Se*transpose(xue) )
    return y
end

@doc doc"""
    exp!(M,y,x,v)

compute the exponential map on the [`SymmetricPositiveDefinite`](@ref) `M` with
[`LogCholeskyMetric`](@ref) from `x` into direction `v` and store the result in
`y`. The formula reads

````math
\exp_x v = (\exp_l w)(\exp_l w)^\mathrm{T}
````
where $\exp_lw$ is the exponential map on [`CholeskySpace`](@ref), $l$ is the
cholesky decomposition of $x$  and $w = l(l^{-1}vl^\mathrm{T}$.
"""
function exp!(M::MetricManifold{SymmetricPositiveDefinite{N},LogCholeskyMetric}, y, x, v) where N
    (l,w) = spd_to_cholesky(x,v) 
    exp!(CholesySpace{N}(),y,l,w)
    y .= y*y'
    return y
end

@doc doc"""
    log!(M,v,x,y)

compute the logarithmic map at `x` to `y` on the [`SymmetricPositiveDefinite`](@ref)
manifold with its default metric, [`LinearAffineMetric`](@ref) and modify `v`.
"""
log!(M::SymmetricPositiveDefinite{N}, v, x, y) where N = log!(MetricManifold(M,LinearAffineMetric()),v, x, y)

@doc doc"""
    log!(M,v,x,y)

compute the exponential map from `x` to `y` on the [`SymmetricPositiveDefinite`](@ref)
as a [`MetricManifold`](@ref) with [`LinearAffineMetric`](@ref) and modify `v`. The formula reads

```math
\log_x y = x^{\frac{1}{2}}\operatorname{Log}(x^{-\frac{1}{2}} y x^{-\frac{1}{2}})x^{\frac{1}{2}},
```
where $\operatorname{Log}$ denotes to the matrix logarithm.
"""
function log!(M::MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric}, v, x, y) where N
    e = eigen(Symmetric(x))
    U = e.vectors
    S = e.values
    Ssqrt = Symmetric( Matrix( Diagonal( sqrt.(S) ) ) )
    SsqrtInv = Symmetric( Matrix( Diagonal( 1 ./ sqrt.(S) ) ) )
    xSqrt = Symmetric( U*Ssqrt*transpose(U) )
    xSqrtInv = Symmetric( U*SsqrtInv*transpose(U) )
    T = Symmetric( xSqrtInv * y * xSqrtInv )
    e2 = eigen( T )
    Se = Matrix( Diagonal( log.(max.(e2.values,eps()) ) ) )
    Ue = e2.vectors
    xue = xSqrt*Ue
    copyto!(v, Symmetric(xue*Se*transpose(xue)))
    return v
end

@doc doc"""
    log!(M,v,x,y)

computes the logarithmic map o [`SymmetricPositiveDefinite`](@ref) `M` with
respect to the [`LogCholeskyMetric`](@ref). The formula can be adapted from
the [`CholeskySpace`](@ref) as
````math
\log_xy = lw\mathrm{T} + wl^{\mathrm{T}},
````
where $l$ is the colesky factor of $x$ and $w=\log_lk$ for $k$ the cholesky factor
of $y$ and the just mentioned logarithmic map is the one on [`CholeskySpace`](@ref).
"""
function log(M::MetricManifold{SymmetricPositiveDefinite{N},LogCholeskyMetric},v,x,y) where N
    l = cholesky(x).L
    k = cholesky(y).L
    log!(CholeskySpace{N}(), v, l, k)
    tangent_cholesky_to_tangent_spd(l, v)
    return v
end
@doc doc"""
    representation_size(M)

returns the size of an array representing an element on the
[`SymmetricPositiveDefinite`](@ref) manifold `M`,
i.e. $n\times n$, the size of such a symmetric positive definite matrix on
$\mathcal M = \mathcal P(n)$.
"""
representation_size(::SymmetricPositiveDefinite{N}) where N = (N,N)

@doc doc"""
    vector_transport_to(M,vto,x,v,y,m::AbstractVectorTransportMethod=ParallelTransport())

compute the vector transport on the [`SymmetricPositiveDefinite`](@ref) with its
default metric, [`LinearAffineMetric`](@ref) and method `m`, which defaults to [`ParallelTransport`](@ref).
"""
vector_transport_to!(M::SymmetricPositiveDefinite{N},vto, x, v, y, m::AbstractVectorTransportMethod) where N = vector_transport_to!(MetricManifold(M,LinearAffineMetric()),vto, x, v, y, m)

@doc doc"""
    vector_transport_to!(M,vto,x,v,y,::ParallelTransport)

compute the parallel transport on the [`SymmetricPositiveDefinite`](@ref) as a
[`MetricManifold`](@ref) with the [`LinearAffineMetric`](@ref).
The formula reads

```math
P_{x\to y}(v) = x^{\frac{1}{2}}
\operatorname{Exp}\bigl(
\frac{1}{2}x^{-\frac{1}{2}}\log_x(y)x^{-\frac{1}{2}}
\bigr)
x^{-\frac{1}{2}}v x^{-\frac{1}{2}}
\operatorname{Exp}\bigl(
\frac{1}{2}x^{-\frac{1}{2}}\log_x(y)x^{-\frac{1}{2}}
\bigr)
x^{\frac{1}{2}},
```

where $\operatorname{Exp}$ denotes the matrix exponential
and `log` the logarithmic map on [`SymmetricPositiveDefinite`](@ref)
(again with respect to the metric mentioned).
"""
function vector_transport_to!(M::MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric}, vto, x, v, y, ::ParallelTransport) where N
    if distance(M,x,y)<2*eps(eltype(x))
        copyto!(vto, v)
        return vto
    end
    e = eigen(Symmetric(x))
    U = e.vectors
    S = e.values
    Ssqrt = sqrt.(S)
    SsqrtInv = Diagonal( 1 ./ Ssqrt )
    Ssqrt = Diagonal( Ssqrt )
    xSqrt = Symmetric(U*Ssqrt*transpose(U))
    xSqrtInv = Symmetric(U*SsqrtInv*transpose(U))
    tv = Symmetric(xSqrtInv * v * xSqrtInv)
    ty = Symmetric(xSqrtInv * y * xSqrtInv)
    e2 = eigen( ty )
    Se = Diagonal( log.(e2.values) )
    Ue = e2.vectors
    ty2 = Symmetric(Ue*Se*transpose(Ue))
    e3 = eigen( ty2 )
    Sf = Diagonal( exp.(e3.values) )
    Uf = e3.vectors
    xue = xSqrt*Uf*Sf*transpose(Uf)
    vtp = xue * ( 0.5*(tv + transpose(tv)) ) * transpose(xue) #symmetrize
    copyto!(vto, vtp)
    return vto
end

@doc doc"""
    [Ξ,κ] = tangent_orthonormal_basis(M,x,v)

returns a orthonormal basis `Ξ` in the tangent space of `x` on the
[`SymmetricPositiveDefinite`](@ref) manifold `M` with the defrault metric, the
[`LinearAffineMetric`](@ref) that diagonalizes the curvature tensor $R(u,v)w$
with eigenvalues `κ` and where the direction `v` has curvature `0`.
"""
tangent_orthonormal_basis(M::SymmetricPositiveDefinite{N},x,v) where N = tangent_orthonormal_basis(MetricManifold(M,LinearAffineMetric()),x,v)

@doc doc"""
    [Ξ,κ] = tangent_orthonormal_basis(M,x,v)

returns a orthonormal basis `Ξ` as a vector of tangent vectors (of length
[`manifold_dimension`](@ref) of `M`) in the tangent space of `x` on the
[`MetricManifold`](@ref of [`SymmetricPositiveDefinite`](@ref) manifold `M` with
[`LinearAffineMetric`](@ref) that diagonalizes the curvature tensor $R(u,v)w$
with eigenvalues `κ` and where the direction `v` has curvature `0`.
"""
function tangent_orthonormal_basis(M::MetricManifold{SymmetricPositiveDefinite{N},LinearAffineMetric},x,v) where N
    xSqrt = sqrt(x) 
    V = eigvecs(v)
    Ξ = [ (i==j ? 1/2 : 1/sqrt(2))*( V[:,i] * transpose(V[:,j])  +  V[:,j] * transpose(V[:,i]) )
        for i=1:N for j= i:N
    ]
    λ = eigvals(v)
    κ = [ -1/4 * (λ[i]-λ[j])^2 for i=1:N for j= i:N ]
  return Ξ,κ
end

@doc doc"""
    injectivity_radius(M)

return the injectivity radius of the [`SymmetricPositiveDefinite`](@ref). Since `M`  is a Hadamard manifold,
the injectivity radius is $\infty$.
"""
injectivity_radius(M::SymmetricPositiveDefinite{N}, args...) where N = Inf

@doc doc"""
    zero_tangent_vector(M,x)

returns the zero tangent vector in the tangent space of the symmetric positive
definite matrix `x` on the [`SymmetricPositiveDefinite`](@ref) manifold `M`.
"""
zero_tangent_vector(M::SymmetricPositiveDefinite{N}, x) where N = zero(x)

@doc doc"""
    zero_tangent_vector(M,v,x)

returns the zero tangent vector in the variable `v` from the tangent space of
the symmetric positive definite matrix `x` on
the [`SymmetricPositiveDefinite`](@ref) manifold `M`.
THe result is returned also in place in the variable `v`.
"""
zero_tangent_vector!(M::SymmetricPositiveDefinite{N}, v, x) where N = fill!(v, 0)

"""
    is_manifold_point(M,x; kwargs...)

checks, whether `x` is a valid point on the [`SymmetricPositiveDefinite`](@ref) `M`, i.e. is a matrix
of size `(N,N)`, symmetric and positive definite.
The tolerance for the second to last test can be set using the ´kwargs...`.
"""
function is_manifold_point(M::SymmetricPositiveDefinite{N},x; kwargs...) where N
    if size(x) != representation_size(M)
        throw(DomainError(size(x),"The point $(x) does not lie on $(M), since its size is not $(representation_size(M))."))
    end
    if !isapprox(norm(x-transpose(x)), 0.; kwargs...)
        throw(DomainError(norm(x), "The point $(x) does not lie on $(M) since its not a symmetric matrix:"))
    end
    if ! all( eigvals(x) .> 0 )
        throw(DomainError(norm(x), "The point $x does not lie on $(M) since its not a positive definite matrix."))
    end
    return true
end

"""
    is_tangent_vector(M,x,v; kwargs... )

checks whether `v` is a tangent vector to `x` on the [`SymmetricPositiveDefinite`](@ref) `M`, i.e.
atfer [`is_manifold_point`](@ref)`(M,x)`, `v` has to be of same dimension as `x`
and a symmetric matrix, i.e. this stores tangent vetors as elements of the corresponding Lie group.
The tolerance for the last test can be set using the ´kwargs...`.
"""
function is_tangent_vector(M::SymmetricPositiveDefinite{N},x,v; kwargs...) where N
    is_manifold_point(M,x)
    if size(v) != representation_size(M)
        throw(DomainError(size(v),
            "The vector $(v) is not a tangent to a point on $(M) since its size does not match $(representation_size(M))."))
    end
    if !isapprox(norm(v-transpose(v)), 0.; kwargs...)
        throw(DomainError(size(v),
            "The vector $(v) is not a tangent to a point on $(M) (represented as an element of the Lie algebra) since its not symmetric."))
    end
    return true
end