# The Chiral Product: An Algebraic Approach to Mutation in Linearly Typed Systems

By Violet Quinn

> I will show that by adjoining a chiral product type to linear typing one can represent objects with channels between them like the disjunctive product,
> but with the added constraint that information only flows one way,
> that is to say that the behaviour of eliminating the past cannot depend on the elimination of the future.
> This produces a finer gradation of product types that I will demonstrate invaluable in constructing a purely algebraic approach to mutation handling.

*This paper will make reference to category theory although an understanding is not required.*
*It is however expected that the reader is aware of linear logic and its common syntax before reading.*

## Introduction

Mutation handling in languages tend to have 3 main goals that up until now have formed an impossible triangle:
- Safety:
    Often in the form of memory aliasing rules, safety is important to ensure memory is not corrupted from the coexistence of incompatible reference types.
- Versatility:
    A solution to mutation handling can only be as effective as its domain of application is broad, at the end of the day all systems have their limits but a system that is too weak can lead its users to write against the language and not with it.
- Simplicity:
    Overbearing semantics can impose roadblocks on development by requiring large type-level refactors for behavioural changes to codebases.

Most languages have historically opted to ditch safety in favour of maximising versatility and simplicity. This naively maximises the space of valid programs, falling for same trap of properties like Turing completeness, where the insistence that everything be possible provides the opportunity to accidentally blow ones own leg off.

Some languages provide safety and simplicity, usually by leveraging calling conventions. The most advanced approach to calling conventions I have seen thus-far is that of [Hylo](https://www.hylo-lang.org/) which provides 4 conventions: "let", "inout", "set", and "sink" which correspond to immutable capture, mutable capture, uninitialised capture, and move respectively. The downside of this is that because captures are not represented in the type system - they cannot be processed using custom data-structures - only with language provided control flow. It is important to note that this is often sufficient for a wide variety of use cases.

Finally, and gaining traction, are approaches that maximise versatility whilst maintaining safety. This includes type level abstractions like state monad transformers, lenses, and lifetimes. These approaches have a certain virality, often prompting and subsequently complicating large refactors. Additionally these approaches often undercut the ability in functional languages for function signatures to concisely convey the general behaviour of a function by instead introducing book-keeping; I believe we can do better.

I aim to solve the above problems whilst maintaining the deadlock free guarantee from linear typing, allowing for the writing of strongly normalising programs.

## Problem Statement

I will be using $\bar{a}$ to refer to the type representing a consumer of type $a$ that cannot be duplicated of discarded.

The typical way to formulate a mutable reference in a linearly typed system is to model it as a value-consumer pair:
$$\mathbb{M}a := a \times \bar{a}$$
In such a system borrowing has the following signature:
$$a \rightarrow \mathbb{M}a \otimes a$$
Importantly these definitions above use two different product types.
- The conjunctive product $\times$ provides two entirely independent instances which you can do with as you please (this is the product type as you are used to it).
- The disjunctive product $\otimes$ provides two arbitrarily dependent instances which you must handle independently.
They are related by De-Morgans laws over product types:
- $\overline{a \times b} \cong \bar{a} \otimes \bar{b}$
- $\overline{a \otimes b} \cong \bar{a} \times \bar{b}$
The interaction between these different product types and their limitations is why linear logic is deadlock safe, specifically, this interaction looks like the following axiom:
$$(a \otimes b) \times (c \otimes d) \implies a \otimes (b \times c) \otimes d$$
Which allows the linking of disjunctive products together, personally this reminds me of the simple running stitch, especially when visualising the way the information flow alternates between the conjunctive and disjunctive products.

Now let us consider the following program (in rust inspired pseudo-code):

```
let mut a = 1
let mut b = 2

swap (&mut a) (&mut b)

a + b
```

Intuitively this should be fine, and with lifetime parameters it is, although the goal is to not rely on them for something this straight forward.

- First start with a pair of values $\mathbb{N}\times\mathbb{N}$
- Then borrow each to get a pair of borrows $(\mathbb{B}\mathbb{N}\otimes \mathbb{N}) \times (\mathbb{B}\mathbb{N}\otimes \mathbb{N})$
- Apply the linking rule to place the mutable references together $(\mathbb{B}\mathbb{N} \times \mathbb{B}\mathbb{N}) \otimes \mathbb{N} \otimes \mathbb{N}$
- And swap our values, annihilating the mutable references and leaving us with $\mathbb{N} \otimes \mathbb{N}$
- Finally we can... combine... oh.

Our values are now disjunctively combined and must be handled separately, and there is no way to avoid this with current linear logic as our code does combine **both** the mutable references and the resultant values together, it is blind to the following two things:
- The type $\mathbb{N}$ has no way to *send* information to anything involved in its creation, and so there is no deadlock to avoid by forcing them to be handled independently.
- The line `swap (&mut a) (&mut b)` depends in no way on the line $a + b$ or anything following for that matter there is a sequence to these operations.

Current linear logic has no way to represent a *directed* flow of information and hence time.

**It is this specific issue that I have now fixed.**

## The Chiral Product

Let us introduce a new *associative* but *chiral* product type $a \ltimes b$ that provides two directionally dependent instances such that the value on the right (which we will call the future) depends on the value of the left (which we will call the present) and never the other way around.

Notably this directional flow of information allows us to define it as its own conjugate as no directed cycle of dependency could arise:
$$\overline{a \ltimes b} \cong \bar{a} \ltimes \bar{b}$$
By the same argument such a product can be interwoven with itself:
$$(a \ltimes b) \times (c \ltimes d) \implies (a \times c) \ltimes (b \times d)$$
> The safety of these axioms will be proven later.

Finally to make this usable we shall introduce a new modality **pure** $\mathbb{P}$ which disallows instances that have other values dependent on how they are used. This modality has the following axioms involving the product types:
$$\mathbb{P}(a \times b) \cong \mathbb{P}a \times \mathbb{P}b$$
$$\mathbb{P}(a \ltimes b) \implies a \ltimes \mathbb{P}b $$ 
Just as one may conjure a channel of type $\bar{a} \otimes a$ one may also conjure a *directed* channel of type $\overline{\mathbb{P}a} \ltimes \mathbb{P}a$.

**And with this we can tackle mutation in a more effective manner.**

## An Algebraic Approach to Mutation