# Handling Weak Monads Using Folds

> Linear and Affine typing introduce resources that are sensitive in their usage.
> Typical do blocks cannot accomoate these values for monads such as List that require duplication for any term not consumed as part of binding.
> My hope is to provide a extension to classical do block syntax to support logic with these types.

## What Is A Do Block? --[wip]--

--[h2_content[--

### What Is A Regular Block?

At any point in a do block the procedure state has a certain type, for example:
```rs
{
    let n: Nat = 4
    let mut message: String = "Hello!"
    ...
}
```

For example, at the ellipsis the state of the block is `(Nat, String)`.

We can view each statement a function of between these states, for example...
```rs
let mut message: String = "Hello!"
```

...can be seen as a function of signature `Nat -> (Nat, String)`.

In this case the chaining of these statements is just function composition!

Eventually defining a single complete process to get the desired result.

### What Makes Do Blocks Special? --[wip]--

Instead of talking about individual statements we can talk about all statements after a given point, the effect this has on the current state is called a *continuation*.

Just like individual statements we can view a *continuation* as a function, this time with signature `Current -> Return`.

In contrast `do` block continuations are of type `Current -> M Return` (where `M` is our monad).
This *on its own* changes nothing but **what makes do blocks special** is that the current state itself is of type `M Current` aswell.

nductively we can say the type of the *continuation* of the block at that point is `Current -> Ret` where `Ret` is the return type.

A `do` block in some monad `M` has *continuations* of type `Current -> M Ret`.

These can be safely composed because of `bind`, which allows `Current -> M Ret` to be called on a value of type `M Current` instead of just `Current`.

--]]--

## Whats The Problem? --[wip]--

When applying a continuation of type `Current -> M Ret` your current state has type `M Current`, but oftentimes you aren't applying a side effect to everything, the state as the programmer writes it is more like `Side, M Bound`, where `Bound` is the result of your bind statement and `Side` is whats left (*to the side*).

In intuitionistic systems (Haskell) this can be rectified with something like:
```hs
absorb :: Functor f => (a, f b) -> f (a, b)
absorb (x, fy) = (x,) <$> fy
```

Which current languages with `do` blocks utilise automatically behind the scenes to make the abstraction work.
But in linear logic there is no garuntee that `x: a` can safely captured by a function mapping across `fy: f b`.

### Tensorial Strength --[wip]--

--[details[--

**What is tensoral strength?**

--], [--

A functor `F: C -> D` between semigroupal categories (with connectives `**` and `&&` respectively) is called `W`-strong if there exists a natural transforation `(W A) && (F B) -> F (A ** B)`.

Typically `W` is a comonad.

--], [--

A functor `F` is `W`-strong with respect to some connective `**` if we can define:
```hs
absorb :: (W a) ** (F b) -> F (a ** b)
```

--]]--
