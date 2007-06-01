=pod

=encoding utf8

=head1 NAME

QDRDBMS::Engine::Example::PhysType -
Physical representations of all core data types

=head1 VERSION

This document describes QDRDBMS::Engine::Example::PhysType version 0.0.0
for Perl 5.

It also describes the same-number versions for Perl 5 of ::Bool, ::Text,
::Blob, ::Int, ::Tuple, and ::Relation.

=head1 DESCRIPTION

This file is used internally by L<QDRDBMS::Engine::Example>; it is not
intended to be used directly in user code.

It provides physical representations of data types that this Example Engine
uses to implement QDRDBMS D.  The API of these is expressly not intended to
match the API that the language itself specifies as possible
representations for system-defined data types.

Specifically, this file represents the core system-defined data types that
all QDRDBMS D implementations must have, namely: Bool, Text, Blob, Int,
Tuple, Relation, and the Cat.* types.

By contast, the optional data types are given physical representations by
other files: L<QDRDBMS::Engine::Example::PhysType::Num>,
L<QDRDBMS::Engine::Example::PhysType::Temporal>,
L<QDRDBMS::Engine::Example::PhysType::Spatial>.

=head1 BUGS AND LIMITATIONS

This file assumes that it will only be invoked by other components of
Example, and that they will only be feeding it arguments that are exactly
what it requires.  For reasons of performance, it does not do any of its
own basic argument validation, as doing so should be fully redundant.  Any
invoker should be validating any arguments that it in turn got from user
code.  Moreover, this file will often take or return values by reference,
also for performance, and the caller is expected to know that they should
not be modifying said then-shared values afterwards.

=head1 AUTHOR

Darren Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENCE AND COPYRIGHT

This file is part of the QDRDBMS framework.

QDRDBMS is Copyright © 2002-2007, Darren Duncan.

See the LICENCE AND COPYRIGHT of L<QDRDBMS> for details.

=cut
