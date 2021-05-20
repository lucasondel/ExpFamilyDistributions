# SPDX-License-Identifier: MIT

"""
    AbstractWishart{D} <: Distribution

Abstract type for Wishart distribution implementations.
"""
abstract type AbstractWishart{D} <: Distribution end

function DefaultWishartParameter(W, v)
    T = eltype(W)
    M = inv(W)
    η₁ = -T(.5)*vec(M)
    η₂ = T(.5)*v
    DefaultParameter(vcat(η₁, η₂))
end

"""
    struct Wishart{P<:AbstractParameter,D} <: AbstractWishart{D}
        param::P
    end

Wishart distribution.

# Constructors

    Wishart{D}()
    Wishart(W[, v])

where `T` is the encoding type of the parameters and `W` is a
positive definite DxD matrix.

# Examples
```jldoctest
julia> Wishart([1 0.5; 0.5 1], 2)
Wishart{DefaultParameter{Vector{Float64}}, 2}:
  W = [1.0 0.5; 0.5 1.0]
  v = 2.0
```
"""
struct Wishart{P<:AbstractParameter,D} <: AbstractWishart{D}
    param::P
end

function Wishart(W::AbstractMatrix, v)
    param = DefaultWishartParameter(W, v)
    P = typeof(param)
    D = size(W,1)
    Wishart{P,D}(param)
end

#######################################################################
# Distribution interface

function basemeasure(w::AbstractWishart, X::AbstractMatrix)
    D = size(X, 1)
    -.5*(D-1)*logdet(X) - .25*D*(D-1)log(pi)
end

function gradlognorm(w::AbstractWishart)
    W, v = stdparam(w, naturalform(w.param))
    D = size(W, 1)
    T = eltype(W)
    ∂η₁ = v * W
    ∂η₂ = sum([digamma((T(v+1-i)/2)) for i in 1:D]) + T(D*log(2)) + logdet(W)
    vcat(vec(∂η₁), ∂η₂)
end

function lognorm(w::AbstractWishart{D},
                 η::AbstractVector{T} = naturalform(w.param)) where {T,D}
    M = -T(2)*reshape(η[1:end-1], D, D)
    v = T(2)*η[end]
    retval = T(0.5)*(-v*logdet(M) + v*D*T(log(2)))
    retval += sum([loggamma(T(0.5)*(v+1-i)) for i in 1:D])
end

stats(w::AbstractWishart, X::AbstractMatrix) = vcat(vec(X), logdet(X))

function sample(w::AbstractWishart, size = 1)
    w_ = Dists.Wishart(w.v, PDMat(Matrix(w.W)))
    [rand(w_) for i in 1:size]
end

function splitgrad(w::AbstractWishart{D}, μ::AbstractVector{T}) where {T,D}
    reshape(μ[1:end-1], D, D), μ[end]
end

function stdparam(w::AbstractWishart{D},
                  η::AbstractVector{T} = naturalform(w.param)) where {T,D}
    M = -T(2)*reshape(η[1:end-1], D, D)
    W = inv(M)
    v = T(2)*η[end]
    (W = W, v = v)
end

