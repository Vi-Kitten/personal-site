# The Chiral Product: An Algebraic Approach to Mutation in Linearly Typed Systems

\- By Violet Quinn

> I will show that by adjoining a chiral product type to linear typing one can represent objects with channels between them like the disjunctive product,
> but with the added constraint that information only flows one way,
> that is to say that the behaviour of eliminating the past cannot depend on the elimination of the future.
> This produces a finer gradation of product types that I will demonstrate invaluable in constructing a purely algebraic approach to mutation handling.

*The reader should be familiar with programming using channels and references in strongly typed systems*

## Introduction

Mutation handling in languages tend to have 3 main goals that up until now have formed an impossible triangle:

- Safety:
  Often in the form of memory aliasing rules, safety is important to ensure memory is not corrupted from the coexistence of incompatible reference types.
- Versatility:
  A solution to mutation handling can only be as effective as its domain of application is broad, at the end of the day all systems have their limits but a system that is too weak can lead its users to write against the language and not with it.
- Simplicity:
  Overbearing semantics can impose roadblocks on development by requiring large type-level refactors for behavioural changes to codebases.

Most languages have historically opted to ditch safety in favour of versatility and simplicity. This naively maximises the space of valid programs and in doing so dilouting what it even means for a program to be valid.

Some languages provide safety and simplicity, usually by leveraging calling conventions. The downside of this is that because captures are not represented in the type system - they cannot be processed using custom data-structures - only with language provided control flow. It is important to note that this is often sufficient for a wide variety of use cases.

Finally, and gaining traction, are approaches that maximise versatility whilst maintaining safety. This includes type level abstractions like state monad transformers, lenses, and lifetimes. These approaches have a certain virality, often prompting and subsequently complicating large refactors by introducing a lot of book-keeping which can be hard to encapsulate.

I aim to solve the above problems whilst maintaining the deadlock free guarantee from linear typing, allowing for the writing of strongly normalising languages that are safe, versatile, and simple to use.

## Preface

Haskell syntax will be used for talking about the type system itself, specifically in terms of the operations we are allowed to do.
A rust inspired syntax will then be used to describe the programs we would like to represent.

Drop down containing more concise but heavilly technical explanations will be provided for those with the knowledge, feel free to ignore these

## Intro To Linear Logic
<div class="vertical container h2-content">

I will be using `~a` to refer to the type representing a consumer of type `a` that cannot be duplicated or discarded.

### Product Types

<div>
<details><summary><div class="packed horizontal centering container">
  <span class="attention material-symbols-outlined summary-icon">
    group_work
  </span>
  <div class="spacer"></div>

**What constitutes a "product type"?**

</div></summary></details>
<div class="ramp detail attention-border"><div class="vertical container">

A bifunctor `P` is a **product type** iff:

- `P` is associative, satisfying the [pentagon identity](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- There is a lifting natural transformation from the conjunctive product (`,`) to `P` that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea)
- There is a lifting natural transformation from `P` to the disjunctive product (`||`) that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- `P` is [strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the conjunctive product (`,`) commuting with the associators and the lifting morphism.
- `P` is co-[strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the disjunctive product (`||`) commuting with the associators and the lifting morphism.

</div></div>
</div>

The regular (conjunctive) product type will be written `a, b` and is comprised of two **entirely independent** instances which you can do with as you please, this is the product type as you are used to it.

The parallel (disjunctive) product type will be written `a || b` and is comprised of two **arbitrarily dependent** instances which you must handle with care, restricting your options significantly, as you are forced by the rules of linear logic to disallow any form of interaction lest you introduce a deadlock.

There is however one thing you *are* allowed to do:
```hs
link :: a || b -> c || d -> (a, c) || b || d
```

Which provides a way to handle a pair of values with absolute freedom, so long as they originated as parts of independent products.

One of the most important uses of `||` is safely typing channels, for example:
```hs
oneshot :: ~a || a
```

### Continuations

In linear logic a `Future` is simply a consumer of a consumer:
```hs
type Future a = ~(~a)
```

Futures are important as they are the basis of how constructs like the parallel product operate, the values contained within are not merely stored by value, but are accessed by means of providing continuations.

### Naive Mutation

The typical way to formulate a mutable reference in a linearly typed system is to model it as a value-consumer pair:
```hs
type InOut a = a, ~a
```

Allowing you to modify by value, and send the result to the owner once you are done.

In such a system borrowing has the following signature:
```hs
borrowMut :: a -> InOut a || a
```

</div>
## Problem Statement

Now let us consider the following program:

```rs
let mut a = 1
let mut b = 2

swap (&mut a) (&mut b)

a + b
```

Let us try and construct this with the tools above.

- First we start with a pair of values `1, 2` of type `Int, Int`.
- Next we can borrow each to get `(InOut Int || Int), (InOut Int || Int)`.
- Which we can feed into `link` getting `(InOut Int, InOut Int) || Int || Int`.
- Now that both mutable references can be used together we can swap them and we are left with `Int || Int`.
- And from here... from here we are stuck.

Our values are now in parallel and must be handled separately; there is no way to avoid this with current linear logic as the type system is blind to the following two things:

- The type `Int` has no way to *send* information to anything else in the program, and so there is no deadlock to be avoid by forcing them to be handled independently.
- The line `swap (&mut a) (&mut b)` depends in no way on the line `a + b` or anything following it, there is a sequence to these operations.

Current linear logic has no way to represent a *directed* flow of information and hence time.

> It is this specific issue that I have now fixed.

## The Chiral Product

To solve this issue we need to extend the type system with a new product type `>>`, called *then*.

We will use this product type to encode a *directed* flow of information be defining it via the following property.
Where pairs in `a, b` are independent, and those in `a || b` are interdependent, pairs in `a >> b` are directionally dependent.

Specifically `a >> b` provides two instances `x: a` and `y: b` such that the value of `y` depends on how you use `x`, but `x` itself does not depend on `y`, or in other words, information only flows from left to right. When talking about these values we say `x` is the **present** value and `y` is the **future** value.

...

> And with this we can tackle mutation in a more effective manner.

## An Algebraic Approach to Mutation