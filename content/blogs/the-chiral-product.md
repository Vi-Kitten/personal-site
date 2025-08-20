# The Chiral Product: An Algebraic Approach to Mutation in Linearly Typed Systems

> I will show that by adjoining a chiral product type to linear typing one can represent objects with channels between them like the disjunctive product,
> but with the added constraint that information only flows one way,
> that is to say that the behaviour of eliminating the past cannot depend on the elimination of the future.
> This produces a finer gradation of product types that I will demonstrate invaluable in constructing a purely algebraic approach to mutation handling.

*The reader should be familiar with programming using channels for concurrency or parallelism, and references in strongly typed systems*

*It is not required for you to know about category theory or type theory but certain concise explanations and technical sections may require it*

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

--[h2_content[--

I will be using `~a` to refer to the type representing a consumer of type `a` that cannot be duplicated or discarded, specifically we have a function:
```hs
cut :: a, ~a -> ()
```
That combines the vaues together, satisfying the consumer.

### Product Types

The regular (conjunctive) product type will be written `a, b`. Its instances are comprised of two **entirely independent** values which you can do with as you please, this is the product type as you are used to it.

The parallel (disjunctive) product type will be written `a || b`. Its instances are comprised of two **arbitrarily dependent** values which you must handle with care, restricting your options significantly, as you are forced by the rules of linear logic to disallow any form of interaction lest you introduce a deadlock.

Both of these product types are commutative (there exists `a, b ~= b, a` and `a || b ~= b || a`).

--[details[--

**What constitutes a product type?**

--], [--

A bifunctor `P` is a **product type** iff:

- `P` is associative, satisfying the [pentagon identity](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- There is a lifting natural transformation from the *conjunctive* product (`,`) to `P` that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea)
- There is a lifting natural transformation from `P` to the *disjunctive* product (`||`) that respects the [pentagon identities](https://ncatlab.org/nlab/show/pentagon+identity#idea).
- `P` is [strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the *conjunctive* product (`,`) commuting with the associators and the lifting morphism.
- `P` is co-[strong](https://ncatlab.org/nlab/show/tensorial+strength#definition) over the *disjunctive* product (`||`) commuting with the associators and the lifting morphism.

--], [--

A **product type** is:

- Associative.
- An inclusive super-type of (`,`) and an inclusive sub-type of (`||`).

--]]--

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

<!-- --[details[--

**How may you use a `Future`?**

--], [--

The covariant functor `Future` is a monad.

--], [--

The `Future` generic behaves more or less how it does in most languages with `async`.

Although it lacks the ability to be polled in custom ways.

--]]-- -->

### Naive Mutation

The typical way to formulate a mutable reference in a linearly typed system is to model it as a value-consumer pair:
```hs
type InOut a = a, ~a
```
Allowing you to modify by value, and send the result to the owner once you are done.

In such a system borrowing has the following signature:
```hs
borrowInOut :: a -> InOut a || a
```

--]]--

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
- Next we can use `BorrowInOut` on each to get `(InOut Int || Int), (InOut Int || Int)`.
- Which we can feed into `link` getting `(InOut Int, InOut Int) || Int || Int`.
- Now that both mutable references can be used together we can swap them and we are left with `Int || Int`.
- And from here... from here we are stuck.

Our values are now in parallel and must be handled separately; there is no way to avoid this with current linear logic as the type system is blind to the following two things:

- The type `Int` has no way to *send* information to anything else in the program, and so there is no deadlock to be avoid by forcing them to be handled independently.
- The line `swap (&mut a) (&mut b)` depends in no way on the line `a + b` or anything following it, there is a sequence to these operations.

Current linear logic has no way to represent a *directed* flow of information and hence time.

> It is this issue that I have now fixed.

## The Ingredients --[wip]--

--[h2_content[--

### The Chiral Product

To fix this I will introduce a new chiral product type which will be written `a >> b`.

We will use this product type to describe *directed* flows of information. Where pairs of values in `a, b` must be independent, and those in `a || b` may be arbitrarily interdependent, pairs of values in `a >> b` can only be directionally dependent.

Specifically, the value on right right, which we will call the value in the *future*, may be dependent on the value on the left,
but the value on the left, which we will call the *present* may **not** depend on the value on the right.

*I call it the chiral product because unlike the disjunctive and conjunctive products, the chiral product is definitionally not commutative*

Said with our new terms:

- The *future* may depend on the *present*.
- But the *present* may **not** depend on the *future*.

This allows more freedom in composition then par (`||`) as directed channels better avoid directed cycles:
```hs
weave :: (a >> b) -> (c >> d) -> (a, c) >> (b, d)
```

### Purity --[wip]--

Having to worry about forming deadlocks by adding two `Int`s together seems overly paranoid, but how do we formalise this?

Let us define a new type `Pure a` consisting of all instances of `a` that have no capacity to *send* information to the rest of the program, if all instances of a type satisfy this property we call the type itself **pure**.

In our example `Int` is a **pure** type.

--[details[--

**How can can you create `Pure` values?**

--], [--

`Pure` is a comonadic modality that is strong monoidal over positive conjunctives.

--], [--

From smaller pure values and from pure processes that only take in pure values.

Non-trivial pure instances tend to require a decent amount of effort to construct.

--]]--

Importantly, purity can persist into the future, as by definition the future can have no effect on the present:
```hs
depend :: Pure (a >> b) -> a >> Pure b
```

This also goes the other way around, not only do product types tell us how we can use `Pure`, `Pure` can tell us how to refine the product types as so:
```hs
sequence :: a || Pure b -> a >> Pure b
isolate :: Pure a >> b -> a, b
```

### Borrowing --[wip]--

Finally we must replace our naive mutation type `InOut` with a primitive custom tailored to this system.

The idea is to leverage what we have already to provide both contet and constraint to properly define safe mutation:
```hs
borrow :: a -> &mut a >> a

mutate :: &mut a -> Pure (a -> b >> a) -> b
```

> Shockingly this only takes two axioms.

This signature of `mutate` ensures that impurities cannot be introduced to the value being modified, protecting the strict garuntees of the chiral product.
This also means it is safe to treat a `&mut (Pure a)` as a `&mut a`, removing a potential function colouring issue.

There is however one thing I must add as an axiom that I have not yet found a way to prove, and that is the swapping of pure values.
In general the system cannot analyse *mutual* mutation, if anyone reading would wish to ponder this I would be very greatful.
For now the following must be added as axiom:
```hs
swap :: &mut (Pure a), &mut (Pure a) -> ()
```

--[details[--

**My notes on mutual mutation.**

--], [--

It may perhaps be correct to generalise the `mutate` rule to accept a product of mutable references as input and force a certain structure to be preserved whilst emmiting a value. Intuitively such a rule *should* allow one handle 2 orthogonal mutations at the same time, returning a tuple of the result, whilst allowing room for some extra safe interaction.

The following allows orthogonal mutations:

```hs
mutate_pair :: &mut a0, &mut a1 -> Pure (a0, a1 -> b >> (a0, a1)) -> b
```

But introduces deadlocks, as one mutable reference may outlive the other with no way to tell.

We could introduce an alternative definition:

```hs
mutate_pair :: &mut a0, &mut a1 -> Pure (a0 || a1 -> b >> (a0 || a1)) -> b
```

However this, despite being more restrictive, this is still unsafe!

The issue is we have no clue how these mutable references relate to each other, it not safe to consume them assuming they are conjunctive and its not safe to update them assuming they are disjunctive, the only safe implementation is:

```hs
mutate_pair :: &mut a0, &mut a1 -> Pure (a0 || a1 -> b >> (a0, a1)) -> b
```

Which is so restrictive as to be a joke, nonetheless this is the best I can come up with.

--]]--

--]]--

## An Algebraic Approach to Mutation --[wip]--

We now ready to face our original problem:
```rs
let mut a = 1
let mut b = 2

swap (&mut a) (&mut b)

a + b
```

We will now construct this program with our new tools.

- We again start with a pair of values `1, 2` of type `Int, Int`.
- Then we can `bororw` each `(&mut Int >> Int), (&mut Int >> Int)`.
- Now we can `weave` them together, getting `(&mut Int, &mut Int) >> (Int, Int)`.
- We can leverage the fact that `Int` is always **pure** to get `(&mut (Pure Int), &mut (Pure Int)) >> (Int, Int)`.
- Letting us apply `swap` to the borrowed values, leaving `(Int, Int)`.
- And finally, our resulting values are no longer in parallel, and we can add them together, getting just `Int` remaining.
