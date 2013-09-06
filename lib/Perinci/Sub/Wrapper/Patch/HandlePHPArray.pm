package Perinci::Sub::Wrapper::Patch::HandlePHPArray;

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

use parent qw(Module::Patch);

my $code = sub {
    my $ctx = shift;

    my ($self, %args) = @_;
    die "Sorry, this patch only works when normalize_schemas is turned on"
        unless $self->{_args}{normalize_schemas};

    $ctx->{orig}->(@_);

    $self->select_section('before_call_accept_args');

    my $args = $self->{_meta}{args};
    for my $an (sort keys %$args) {
        my $aspec = $args->{$an};
        next unless $aspec->{schema};
        if ($aspec->{schema}[0] eq 'array') {
            $self->push_lines("if (ref(\$args{$an}) eq 'HASH' && !keys(\%{\$args{$an}})) { \$args{$an} = [] }");
        }
        if ($aspec->{schema}[0] eq 'hash') {
            $self->push_lines("if (ref(\$args{$an}) eq 'ARRAY' && !\@{\$args{$an}}) { \$args{$an} = {} }");
        }
    }
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                sub_name => 'handle_args',
                code => $code,
            },
        ],
    };
}

=head1 SYNOPSIS

 use Perinci::Sub::Wrapper::HandlePHPArray;


=head1 DESCRIPTION

This module patches L<Perinci::Sub::Wrapper> so the generated function wrapper
code can convert argument C<{}> to C<[]> when function expects argument to be an
array, or vice versa C<[]> to C<{}> when function expects a hash argument. This
can help if function is being called by PHP clients, because in PHP C<Array()>
is ambiguous, it can be an empty hash or an empty array.

To make this work, you have to specify schema in your argument specification in
your Rinci metadata, and the type must be hash or array.

This is a temporary/stop-gap solution. The more "official" solution is to use
L<Perinci::Access::HTTP::Server> which has the C<deconfuse_php_clients> option
(by default turned on).

=cut
