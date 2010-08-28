package BaseStaticClassGroup;
use Logos::Group;
@ISA = "Group";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = Group->new();
	$self->name("_staticClass");
	$self->explicit(0);
	$self->{DECLAREDONLYCLASSES} = {};
	$self->{USEDCLASSES} = {};
	$self->{USEDMETACLASSES} = {};
	bless($self, $class);
	return $self;
}

sub addUsedClass {
	my $self = shift;
	my $class = shift;
	$self->{USEDCLASSES}{$class}++;
}

sub addUsedMetaClass {
	my $self = shift;
	my $class = shift;
	$self->{USEDMETACLASSES}{$class}++;
}

sub addDeclaredOnlyClass {
	my $self = shift;
	my $class = shift;
	$self->{DECLAREDONLYCLASSES}{$class}++;
}

sub declarations {
	::fileError(-1, "Generator hasn't implemented StaticClassGroup::declarations :(");
	return "";
}

sub initializers {
	::fileError(-1, "Generator hasn't implemented StaticClassGroup::initializers :(");
	return "";
}

1;
