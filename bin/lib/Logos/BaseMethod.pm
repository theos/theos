package BaseMethod;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{CLASS} = undef;
	$self->{SCOPE} = undef;
	$self->{RETURN} = undef;
	$self->{GROUP_IDENTIFIER} = undef;
	$self->{SELECTOR_PARTS} = [];
	$self->{ARGNAMES} = [];
	$self->{ARGTYPES} = [];
	$self->{NUM_ARGS} = 0;
	$self->{GROUP} = "_ungrouped";
	$self->{NEW} = 0;
	$self->{TYPE} = "";
	bless($self, $class);
	return $self;
}

##################### #
# Setters and Getters #
# #####################
sub class {
	my $self = shift;
	if(@_) { $self->{CLASS} = shift; }
	return $self->{CLASS};
}

sub scope {
	my $self = shift;
	if(@_) { $self->{SCOPE} = shift; }
	return $self->{SCOPE};
}

sub return {
	my $self = shift;
	if(@_) { $self->{RETURN} = shift; }
	return $self->{RETURN};
}

sub groupIdentifier {
	my $self = shift;
	if(@_) { $self->{GROUP_IDENTIFIER} = shift; }
	return $self->{GROUP_IDENTIFIER};
}

sub selectorParts {
	my $self = shift;
	if(@_) { @{$self->{SELECTOR_PARTS}} = @_; }
	return @{$self->{SELECTOR_PARTS}};
}

sub group {
	my $self = shift;
	if(@_) { $self->{GROUP} = shift; }
	return $self->{GROUP};
}

sub setNew {
	my $self = shift;
	if(@_) { $self->{NEW} = shift; }
	return $self->{NEW};
}

sub isNew {
	my $self = shift;
	return $self->{NEW};
}

sub type {
	my $self = shift;
	if(@_) { $self->{TYPE} = shift; }
	return $self->{TYPE};
}

##### #
# END #
# #####

sub addArgument {
	my $self = shift;
	my ($type, $name) = @_;
	push(@{$self->{ARGTYPES}}, $type);	
	push(@{$self->{ARGNAMES}}, $name);
	$self->{NUM_ARGS}++;
}

sub selector {
	my $self = shift;
	if($self->{NUM_ARGS} == 0) {
		return $self->{SELECTOR_PARTS}[0];
	} else {
		return join(":", @{$self->{SELECTOR_PARTS}}).":";
	}
}

sub methodSignature {
	::fileError(-1, "Generator hasn't implemented Method::buildMethodSignature :(");
	return "";
}

sub originalCall {
	::fileError(-1, "Generator hasn't implemented Method::originalCall :(");
	return "";
}

sub initializers {
	::fileError(-1, "Generator hasn't implemented Method::initializers :(");
	return "";
}


sub buildLogCall {
	my $self = shift;
	# Log preamble
	my $build = "NSLog(\@\"".$self->{SCOPE}."[<".$self->class->name.": %p>";
	my $argnamelist = "";
	if($self->{NUM_ARGS} > 0) {
		# For each argument, add its keyword and a format char to the log string.
		map $build .= " ".$self->{SELECTOR_PARTS}[$_].":".formatCharForArgType($self->{ARGTYPES}[$_]), (0..$self->{NUM_ARGS} - 1);
		# This builds a list of args by making sure the format char isn't -- (or, what we're using for non-operational types)
		# Map (in list context) "format char == -- ? nothing : arg name" over the indices of the arg list.
		my @newarglist = map(printArgForArgType($self->{ARGTYPES}[$_], $self->{ARGNAMES}[$_]), (0..$self->{NUM_ARGS} - 1));
		my @existingargs = grep(defined($_), @newarglist);
		if(scalar(@existingargs) > 0) {
			$argnamelist = ", ".join(", ", grep(defined($_), @existingargs));
		}
	} else {
		# Space and then the only keyword in the selector.
		$build .= " ".$self->selector;
	}
	# Log postamble
	$build .= "]\", self".$argnamelist.")";
}

sub printArgForArgType {
	my $argtype = shift;
	my $argname = shift;
	return "NSStringFromSelector($argname)" if $argtype =~ /\bSEL\b/;
	return "$argname.location, $argname.length" if $argtype =~ /\bNSRange\b/;
	return "$argname.origin.x, $argname.origin.y, $argname.size.width, $argname.size.height" if $argtype =~ /\b(CG|NS)Rect\b/;
	return "$argname.x, $argname.y" if $argtype =~ /\b(CG|NS)Point\b/;
	return "$argname.width, $argname.height" if $argtype =~ /\b(CG|NS)Size\b/;
	return undef if formatCharForArgType($argtype) eq "--";
	return $argname;
}

sub formatCharForArgType {
	my $argtype = shift;

	# Integral Types
	# Straight characters get %c. Signed/Unsigned characters get %hhu/%hhd.
	return "'%c'" if $argtype =~ /^char$/;
	if($argtype =~ /\b(int|long|bool|unsigned|signed|char|short)\b/i) {
		my $conversion = "d";
		$conversion = "u" if $argtype =~ /\bunsigned\b/;

		my $length;
		$length = "" if $argtype =~ /\bint\b/;
		$length = "l" if $argtype =~ /\blong\b/;
		$length = "ll" if $argtype =~ /\blong long\b/;
		$length = "h" if $argtype =~ /\bshort\b/;
		$length = "hh" if $argtype =~ /\bchar\b/;

		return "%".$length.$conversion;
	}
	return "%d" if $argtype =~ /\bNS(U?Integer|SocketNativeHandle|StringEncoding|SortOptions|ComparisonResult|EnumerationOptions|(Hash|Map)TableOptions|SearchPath(Directory|DomainMask))\b/i;
	return "%d" if $argtype =~ /\bGS(FontTraitMask)\b/i;

	# Pointer Types
	return "%s" if $argtype =~ /\bchar\b\s*\*/;
	return "%p" if $argtype =~ /\bvoid\b\s*\*/;
	return "%p" if $argtype =~ /\bNS.*?(Pointer|Array)\b/;

	# Floating-Point Types
	return "%f" if $argtype =~ /\b(double|float|CGFloat|CGDouble)\b/;
	return "%f" if $argtype =~ /\bNS(TimeInterval)\b/;
	
	# Special Types (should also have an entry in printArgForArgType
	return "%@" if $argtype =~ /\bSEL\b/;

	# Even-more-special expanded types
	return "(%d:%d)" if $argtype =~ /\bNSRange\b/;
	return "{{%g, %g}, {%g, %g}}" if $argtype =~ /\b(CG|NS)Rect\b/;
	return "{%g, %g}" if $argtype =~ /\b(CG|NS)Point\b/;
	return "{%g, %g}" if $argtype =~ /\b(CG|NS)Size\b/;

	# Opaque Types (pointer)
	return "%p" if $argtype =~ /\bNSZone\b/;

	# Discarded Types
	return "--" if $argtype =~ /\b(CG\w*|CF\w*|void)\b/;
	return "--" if $argtype =~ /\bNS(HashTable(Callbacks)?|Map(Table((Key|Value)Callbacks)?|Enumerator))\b/;

	# Fallthrough
	return "%@";
}

1;
