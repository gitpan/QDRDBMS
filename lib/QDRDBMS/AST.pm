=pod

=encoding utf8

=head1 NAME

QDRDBMS::AST -
Abstract syntax tree for the QDRDBMS D language

=head1 VERSION

This document describes QDRDBMS::AST version 0.0.0 for Perl 5.

It also describes the same-number versions for Perl 5 of [...].

=head1 SYNOPSIS

I<This documentation is pending.>

    use QDRDBMS::AST qw(newBoolLit newTextLit newBlobLit newIntLit
        newTupleSel newQuasiTupleSel newRelationSel newQuasiRelationSel
        newVarInvo newFuncInvo newProcInvo newFuncReturn newProcReturn
        newEntityName newTypeInvoNQ newTypeInvoAQ newTypeDictNQ
        newTypeDictAQ newExprDict newFuncDecl newProcDecl newHostGateRtn);

    my $truth_value = newBoolLit({ 'v' => (2 + 2 == 4) });
    my $planetoid = newTextLit({ 'v' => 'Ceres' });
    my $package = newBlobLit({ 'v' => (pack 'H2', 'P') });
    my $answer = newIntLit({ 'v' => 42 });

I<This documentation is pending.>

=head1 DESCRIPTION

The native command language of a L<QDRDBMS> DBMS (database management
system) / virtual machine is called B<QDRDBMS D>; see L<QDRDBMS::Language>
for the language's human readable authoritative design document.

QDRDBMS D has 3 closely corresponding main representation formats, which
are catalog relations (what routines inside the DBMS see), hierarchical AST
(abstract syntax tree) nodes (what the application driving the DBMS
typically sees), and string-form QDRDBMS D code that users interacting with
QDRDBMS via a shell interface would use.  The string-form would be parsed
into the AST, and the AST be flattened into the relations; similarly, the
relations can be unflattened into the AST, and string-form code be
generated from the AST if desired.

This library, QDRDBMS::AST ("AST"), provides a few dozen container classes
which collectively implement the AST representation format of QDRDBMS D;
each class is called an I<AST node type> or I<node type>, and an object of
one of these classes is called an I<AST node> or I<node>.

These are all of the roles and classes that QDRDBMS::AST defines (more will
be added in the future), which are visually arranged here in their "does"
or "isa" hierarchy, children indented under parents:

    QDRDBMS::AST::Node (dummy role)
        QDRDBMS::AST::Expr (dummy role)
            QDRDBMS::AST::Lit (dummy role)
                QDRDBMS::AST::BoolLit
                QDRDBMS::AST::TextLit
                QDRDBMS::AST::BlobLit
                QDRDBMS::AST::IntLit
            QDRDBMS::AST::_Tuple (implementing role)
                QDRDBMS::AST::TupleSel
                QDRDBMS::AST::QuasiTupleSel
            QDRDBMS::AST::_Relation (implementing role)
                QDRDBMS::AST::RelationSel
                QDRDBMS::AST::QuasiRelationSel
            QDRDBMS::AST::VarInvo
            QDRDBMS::AST::FuncInvo
        QDRDBMS::AST::Stmt (dummy role)
            QDRDBMS::AST::ProcInvo
            QDRDBMS::AST::FuncReturn
            QDRDBMS::AST::ProcReturn
            # more control-flow statement types would go here
        QDRDBMS::AST::EntityName
        QDRDBMS::AST::TypeInvo (implementing role)
            QDRDBMS::AST::TypeInvoNQ
            QDRDBMS::AST::TypeInvoAQ
        QDRDBMS::AST::TypeDict (implementing role)
            QDRDBMS::AST::TypeDictNQ
            QDRDBMS::AST::TypeDictAQ
        QDRDBMS::AST::ExprDict
        QDRDBMS::AST::FuncDecl
        QDRDBMS::AST::ProcDecl
        # more routine declaration types would go here
        QDRDBMS::AST::HostGateRtn

All QDRDBMS D abstract syntax trees are such in the compositional sense;
that is, every AST node is composed primarily of zero or more other AST
nodes, and so a node is a child of another iff the former is composed into
the latter.  All AST nodes are immutable objects; their values are
determined at construction time, and they can't be changed afterwards.
Therefore, constructing a tree is a bottom-up process, such that all child
objects have to be constructed prior to, and be passed in as constructor
arguments of, their parents.  The process is like declaring an entire
multi-dimensional Perl data structure at the time the variable holding it
is declared; the data structure is actually built from the inside to the
outside.  A consequence of the immutability is that it is feasible to
reuse AST nodes many times, since they won't change out from under you.

An AST node denotes an arbitrarily complex value, that value being defined
by the type of the node and what its attributes are (some of which are
themselves nodes, and some of which aren't).  A node can denote either a
scalar value, or a collection value, or an expression that would evaluate
into a value, or a statement or routine definition that could be later
executed to either return a value or have some side effect.  For all
intents and purposes, a node is a program, and can represent anything that
program code can represent, both values and actions.

The QDRDBMS framework uses QDRDBMS AST nodes for the dual purpose of
defining routines to execute and defining values to use as arguments to and
return values from the execution of said routines.  The C<prepare()> method
of a C<QDRDBMS::Interface::DBMS> object, and by extension the
C<QDRDBMS::Interface::HostGateRtn->new()> constructor function, takes a
C<QDRDBMS::AST::HostGateRtn> node as its primary argument, such that the
AST object defines the source code that is compiled to become the Interface
object.  The C<fetch_ast()> and C<store_ast()> methods of a
C<QDRDBMS::Interface::HostGateVar> object will get or set that object's
primary value attribute, which is any C<QDRDBMS::AST::Node>.  The C<Var>
objects are bound to C<Rtn> objects, and they are the means by which an
executed routine accepts input or provides output at C<execute()> time.

=head2 AST Node Values Versus Representations

In the general case, QDRDBMS AST nodes do not maintain canonical
representations of all QDRDBMS D values, meaning that it is possible and
common to have 2 given AST nodes that logically denote the same value, but
they have different actual compositions.  (Some node types are special
cases for which the aforementioned isn't true; see below.)

For example, a node whose value is just the number 5 can have any number of
representations, each of which is an expression that evaluates to the
number 5 (such as [C<5>, C<2+3>, C<10/2>]).  Another example is a node
whose value is the set C<{3,5,7}>; it can be represented, for example,
either by C<Set(5,3,7,7,7)> or C<Union(Set(3,5),Set(5,7))> or
C<Set(7,5,3)>.  I<These examples aren't actual QDRDBMS AST syntax.>

For various reasons, the QDRDBMS::AST classes themselves do not do any node
refactoring, and their representations differ little if any from the format
of their constructor arguments, which can contain extra information that is
not logically significant in determining the node value.  One reason is
that this allows a semblence of maintaining the actual syntax that the user
specified, which is useful for their debugging purposes.  Another reason is
the desire to keep this library as light-weight as possible, such that it
just implements the essentials; doing refactoring can require a code size
and complexity that is orders of magnitude larger than these essentials,
and that work isn't always helpful.  It should also be noted that any nodes
having references to externally user-defined entities can't be fully
refactored as each of those represents a free variable that a static node
analysis can't decompose; only nodes consisting of just system-defined or
literal entities (meaning zero free variables) can be fully refactored in a
static node analysys (though there are a fair number of those in practice,
particularly as C<Var> values).

A consequence of this is that the QDRDBMS::AST classes in general do not
include do not include any methods for comparing that 2 nodes denote the
same value; to reliably do that, you will have to use means not provided by
this library.  However, each class I<does> provide a C<equal_repr> method,
which compares that 2 nodes have the same representation.

It should be noted that a serialize/unserialize cycle on a node that is
done using the C<as_perl> routine to serialize, and having Perl eval that
to unserialize, is guaranteed to preserve the representation, so
C<equal_repr> will work as expected in that situation.

As an exception to the general case about nodes, the node classes
[C<BoolLit>, C<TextLit>, C<BlobLit>, C<IntLit>, C<EntityName>, C<VarInvo>,
C<ProcReturn>] are guaranteed to only ever have a single representation per
value, and so C<equal_repr> is guaranteed to indicate value equality of 2
nodes of those types.  In fact, to assist the consequence this point, these
node classes also have the C<equal_value> method which is an alias for
C<equal_repr>, so you can use C<equal_value> in your use code to make it
better self documenting; C<equal_repr> is still available for all node
types to assist automated use code that wants to treat all node types the
same.  It should also be noted that a C<BoolLit> node can only possibly be
of one of 2 values, and C<ProcReturn> is a singleton.

It is expected that multiple third party utility modules will become
available over time whose purpose is to refactor a QDRDBMS AST node, either
as part of a static analysis that considers only the node in isolation (and
any user-defined entity references have to be treated as free variables and
not generally be factored out), or as part of an Engine implementation that
also considers the current virtual machine environment and what
user-defined entities exist there (and depending on the context,
user-defined entity references don't have to be free variables).

=head1 INTERFACE

The interface of QDRDBMS::AST is fundamentally object-oriented; you use it
by creating objects from its member classes, usually invoking C<new()> on
the appropriate class name, and then invoking methods on those objects.
All of their attributes are private, so you must use accessor methods.

QDRDBMS::AST also provides wrapper subroutines for all member class
constructors, 1 per each, where each subroutine has identical parameters to
the constructor it wraps, and the name of each subroutine is equal to the
trailing part of the class name, specifically the C<Foo> of
C<QDRDBMS::AST::Foo>.  All of these subroutines are exportable, but are not
exported by default, and exist soley as syntactic sugar to allow user code
to have more brevity.  I<TODO:  Reimplement these as lexical aliases or
compile-time macros instead, to avoid the overhead of extra routine calls.>

The usual way that QDRDBMS::AST indicates a failure is to throw an
exception; most often this is due to invalid input.  If an invoked routine
simply returns, you can assume that it has succeeded, even if the return
value is undefined.

=head2 The QDRDBMS::AST::BoolLit Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::TextLit Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::BlobLit Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::IntLit Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::TupleSel Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::QuasiTupleSel Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::RelationSel Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::QuasiRelationSel Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::VarInvo Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::FuncInvo Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::ProcInvo Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::FuncReturn Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::ProcReturn Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::EntityName Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::TypeInvoNQ Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::TypeInvoAQ Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::TypeDictNQ Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::TypeDictAQ Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::ExprDict Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::FuncDecl Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::ProcDecl Class

I<This documentation is pending.>

=head2 The QDRDBMS::AST::HostGateRtn Class

I<This documentation is pending.>

=head1 DIAGNOSTICS

I<This documentation is pending.>

=head1 CONFIGURATION AND ENVIRONMENT

I<This documentation is pending.>

=head1 DEPENDENCIES

This file requires any version of Perl 5.x.y that is at least 5.8.1.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

Go to L<QDRDBMS> for the majority of distribution-internal references, and
L<QDRDBMS::SeeAlso> for the majority of distribution-external references.

=head1 BUGS AND LIMITATIONS

For design simplicity in the short term, all AST arguments that are
applicable must be explicitly defined by the user, even if it might be
reasonable for QDRDBMS to figure out a default value for them, such as
"same as self".  This limitation will probably be removed in the future.
All that said, a few arguments may be exempted from this limitation.

I<This documentation is pending.>

=head1 AUTHOR

Darren Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the QDRDBMS framework.

QDRDBMS is Copyright © 2002-2007, Darren Duncan.

See the LICENCE AND COPYRIGHT of L<QDRDBMS> for details.

=head1 ACKNOWLEDGEMENTS

The ACKNOWLEDGEMENTS in L<QDRDBMS> apply to this file too.

=cut
