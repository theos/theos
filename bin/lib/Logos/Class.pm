package Logos::Class;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{NAME} = undef;
	$self->{EXPR} = undef;
	$self->{METAEXPR} = undef;
	$self->{TYPE} = undef;
	$self->{META} = 0;
	$self->{INST} = 0;
	$self->{OVERRIDDEN} = 0;
	$self->{METHODS} = [];
	$self->{NUM_METHODS} = 0;
	$self->{GROUP} = undef;
	bless($self, $class);
	return $self;
}

##################### #
# Setters and Getters #
# #####################
sub name {
	my $self = shift;
	if(@_) { $self->{NAME} = shift; }
	return $self->{NAME};
}

sub expression {
	my $self = shift;
	if(@_) { $self->{EXPR} = shift; $self->type("id"); $self->{OVERRIDDEN} = 1; }
	return $self->variable if $self->{OVERRIDDEN};
	return "objc_getClass(\"".$self->{NAME}."\")";
}

sub metaexpression {
	my $self = shift;
	if(@_) { $self->{METAEXPR} = shift; $self->{OVERRIDDEN} = 1; }
	return $self->metaVariable if $self->{OVERRIDDEN};
	return "object_getClass(".$self->variable.")";
}

sub type {
	my $self = shift;
	if(@_) { $self->{TYPE} = shift; }
	return $self->{TYPE} if $self->{TYPE};
	return $self->{NAME}."*";
}

sub hasmetahooks {
	my $self = shift;
	if(@_) { $self->{META} = shift; }
	return $self->{META};
}

sub hasinstancehooks {
	my $self = shift;
	if(@_) { $self->{INST} = shift; }
	return $self->{INST};
}

sub group {
	my $self = shift;
	if(@_) { $self->{GROUP} = shift; }
	return $self->{GROUP};
}

##### #
# END #
# #####

sub addMethod {
	my $self = shift;
	my $hook = shift;
	push(@{$self->{METHODS}}, $hook);
	$self->{NUM_METHODS}++;
}

sub _initExpr {
	my $self = shift;
	return $self->{EXPR} if $self->{EXPR};
	return "objc_getClass(\"".$self->{NAME}."\")";
}

sub _metaInitExpr {
	my $self = shift;
	return $self->{METAEXPR} if $self->{METAEXPR};
	return "object_getClass(".$self->variable.")";
}

sub variable {
	my $self = shift;
	return Logos::sigil("class").$self->group->name."\$".$self->name;
}

sub metaVariable {
	my $self = shift;
	return Logos::sigil("metaclass").$self->group->name."\$".$self->name;
}

sub declarations {
	::fileError(-1, "Generator hasn't implemented Class::declarations :(");
	return "";
}

sub initializers {
	::fileError(-1, "Generator hasn't implemented Class::initializers :(");
	return "";
}

1;
