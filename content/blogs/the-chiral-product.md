# The Chiral Product: An Algebraic Approach to Mutation in Linearly Typed Systems

> I will show that by adjoining a chiral product type to linear typing one can represent objects with channels between them like the disjunctive product,
> but with the added constraint that information only flows one way,
> that is to say that the behaviour of eliminating the past cannot depend on the elimination of the future.
> This produces a finer gradation of product types that I will demonstrate invaluable in constructing a purely algebraic approach to mutation handling.

*The reader should be familiar with programming using channels for concurrency or parallelism, and references in strongly typed systems*

<div class="horizontal container" style="gap: 1rem;">

*The symbol*

<details><summary>
<span class="attention material-symbols-outlined summary-icon">group_work</span>
</summary></details>

*will incidate a consise category-theory dense explanation for those so inclined*

</div>

## Introduction

Mutation handling in languages tend to have 3 main goals that up until now have formed an impossible triangle:

- Safety:
  Often in the form of memory aliasing rules, safety is important to ensure memory is not corrupted from the coexistence of incompatible reference types.
- Versatility:
  A solution to mutation handling can only be as effective as its domain of application is broad, at the end of the day all systems have their limits but a system that is too weak can lead its users to write against the language and not with it.
- Simplicity:
  Overbearing semantics can impose roadblocks on development by requiring large type-level refactors for behavioural changes to codebases.

Most languages have historically opted to ditch safety in favour of versatility and simplicity. This naively maximises the space of valid programs and in doing so diluting what it even means for a program to be valid.

Some languages provide safety and simplicity, usually by leveraging calling conventions. The downside of this is that because captures are not represented in the type system - they cannot be processed using custom data-structures - only with language provided control flow. It is important to note that this is often sufficient for a wide variety of use cases.

Finally, and gaining traction, are approaches that maximise versatility whilst maintaining safety. This includes type level abstractions like state monad transformers, lenses, and lifetimes. These approaches have a certain virality, often prompting and subsequently complicating large refactors by introducing a lot of book-keeping which can be hard to encapsulate.

I aim to solve the above problems whilst maintaining the deadlock free guarantee from linear typing, allowing for the writing of strongly normalising languages that are safe, versatile, and simple to use.

## Preface

Haskell syntax will be used for talking about the type system itself, specifically in terms of the operations we are allowed to do.
A rust inspired syntax will then be used to describe the programs we would like to represent.

The type `a -> b` represents a function from type `a` to type `b`.

The type `a ~= b` (with the same precedence as `->`) represents an [isomorphism](https://en.wikipedia.org/wiki/Isomorphism) between type `a` and type `b`
(meaning `a` and `b` can be swapped between by value without complication).

## Intro To Linear Logic

<div class="vertical container h2-content">

I will be using `~a` to refer to the type representing a consumer of type `a` that cannot be duplicated or discarded, specifically we have a function:
```hs
cut :: a, ~a -> ()
```
That combines the vaues together, satisfying the consumer.

### Product Types

The regular (conjunctive) product type will be written `a, b`. Its instances are comprised of two **entirely independent** values which you can do with as you please, this is the product type as you are used to it.

The parallel (disjunctive) product type will be written `a || b`. Its instances are comprised of two **arbitrarily dependent** values which you must handle with care, restricting your options significantly, as you are forced by the rules of linear logic to disallow any form of interaction lest you introduce a deadlock.

Both of these product types are commutative (there exists `a, b ~= b, a` and `a || b ~= b || a`).

<div>
<details><summary><div class="horizontal centering container" style="gap: 1rem;">
  <span class="attention material-symbols-outlined summary-icon">
    group_work
  </span>

**What constitutes a product type?**

</div></summary></details>
<div class="ramp detail attention-border"><div class="vertical container">

A bifunctor `P` is a **product type** iff:

- `P` is associative, satisfying the [pentagon identity](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- There is a lifting natural transformation from the *conjunctive* product (`,`) to `P` that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea)
- There is a lifting natural transformation from `P` to the *disjunctive* product (`||`) that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- `P` is [strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the *conjunctive* product (`,`) commuting with the associators and the lifting morphism.
- `P` is co-[strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the *disjunctive* product (`||`) commuting with the associators and the lifting morphism.

</div></div><div class="detail"><div class="vertical container">

A **product type** is:

- Associative.
- An inclusive super-type of (`,`) and an inclusive sub-type of (`||`).

</div></div>
</div>

There is however one thing you *are* allowed to do:
```hs
link :: a || b -> c || d -> (a, c) || b || d
```
Which provides a way to handle a pair of values with absolute freedom, so long as they originated as parts of independent products.
This is safe because, despite the fact that `b` and `d` can now potentially communicate, they are now composed in parallel, barring future communication and thus preventing a deadlock.

One of the most important uses of `||` is safely typing *channels*, for example:
```hs
oneshot :: ~a || a
```

### Continuations

In linear logic a `Future` is simply a consumer of a consumer:
```hs
type Future a = ~(~a)
```

Futures are important as they are the basis of how constructs like the parallel product operate, the values contained within are not merely stored by value, but are accessed by means of providing continuations.

For example, if you are left with but a single value in the parallel product you may extract it as a future:
```hs
extract_parallel :: a || () -> Future a
```

<div>
<details><summary><div class="horizontal centering container" style="gap: 1rem;">
  <span class="attention material-symbols-outlined summary-icon">
    group_work
  </span>

**How may you use a `Future`?**

</div></summary></details>
<div class="ramp detail attention-border"><div class="vertical container">

The covariant functor `Future` is a monad.

</div></div><div class="detail"><div class="vertical container">

The `Future` generic behaves more or less how it does in most languages with `async`.

Although it lacks the ability to be polled in custom ways.

</div></div>
</div>

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

## Chiral Linear Logic <span class="warning" title="Work in progress"><span class="material-symbols-outlined">construction</span></span>

<div class="vertical container h2-content">

### The Chiral Product

To fix this I will introduce a new chiral product type which will be written `a >> b`.

We will use this product type to describe *directed* flows of information. Where pairs of values in `a, b` must be independent, and those in `a || b` may be arbitrarily interdependent, pairs of values in `a >> b` can only be directionally dependent.

Specifically, the value on right right, which we will call the value in the *future*, may be dependent on the value on the left,
but the value on the left, which we will call the *present* may **not** depend on the value on the right.

*I call it the chiral product because unlike the disjunctive and conjunctive products, the chiral product is definitionally not commutative*

Said with our new terms:

- The *future* may depend on the *present*.
- But the *present* may **not** depend on the *future*.

### Purity <span class="warning" title="Work in progress"><span class="material-symbols-outlined">construction</span></span>

Having to worry about forming deadlocks by adding two `Int`s together seems overly paranoid, but how do we formalise this?

Let us define a new type `pure a` consisting of all instances of `a` that have no values depending on how they are used, if all instances of a type satisfy this property we call the type itself **pure**. 

In our example `Int` is a **pure** type.

<div>
<details><summary><div class="horizontal centering container" style="gap: 1rem;">
  <span class="attention material-symbols-outlined summary-icon">
    group_work
  </span>

**How can can you create `pure` values?**

</div></summary></details>
<div class="ramp detail attention-border"><div class="vertical container">

More autistic yap yap yap.

</div></div><div class="detail"><div class="vertical container">

Yap yap yap.

</div></div>
</div>

<div>
<details><summary><div class="horizontal centering container" style="gap: 1rem;">
  <span class="attention material-symbols-outlined summary-icon">
    group_work
  </span>

**Why is purity preserved in the future?**

...

</div></summary></details>
<div class="ramp detail attention-border"><div class="vertical container">

More autistic yap yap yap.

</div></div><div class="detail"><div class="vertical container">

Yap yap yap.

</div></div>
</div>

### Borrowing <span class="warning" title="Work in progress"><span class="material-symbols-outlined">construction</span></span>

...

```hs
mutate :: pure (a -> b >> a) -> &mut a -> b
```

...

<div>
<details><summary><div class="horizontal centering container" style="gap: 1rem;">
  <span class="attention material-symbols-outlined summary-icon">
    group_work
  </span>

**Why may a `&mut (pure a)` be safely treated as a `&mut a`?**

</div></summary></details>
<div class="ramp detail attention-border"><div class="vertical container">

More autistic yap yap yap.

</div></div><div class="detail"><div class="vertical container">

Yap yap yap.

</div></div>
</div>

</div>

## An Algebraic Approach to Mutation <span class="warning" title="Work in progress"><span class="material-symbols-outlined">construction</span></span>

We now have the tools to tackle our original problem (and a lot more).

