package BaseMethod;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{CLASS} = undef;
	$self->{SCOPE} = undef;
	$self->{RETURN} = undef;
	$self->{SELECTOR_PARTS} = [];
	$self->{ARGNAMES} = [];
	$self->{ARGTYPES} = [];
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
	return $self->class->group->identifier;
}

sub selectorParts {
	my $self = shift;
	if(@_) { @{$self->{SELECTOR_PARTS}} = @_; }
	return @{$self->{SELECTOR_PARTS}};
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

sub numArgs {
	my $self = shift;
	return scalar @{$self->{ARGTYPES}};
}

sub addArgument {
	my $self = shift;
	my ($type, $name) = @_;
	push(@{$self->{ARGTYPES}}, $type);	
	push(@{$self->{ARGNAMES}}, $name);
}

sub selector {
	my $self = shift;
	if($self->numArgs == 0) {
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
	if($self->numArgs > 0) {
		# For each argument, add its keyword and a format char to the log string.
		map $build .= " ".$self->{SELECTOR_PARTS}[$_].":".formatCharForArgType($self->{ARGTYPES}[$_]), (0..$self->numArgs - 1);
		# This builds a list of args by making sure the format char isn't -- (or, what we're using for non-operational types)
		# Map (in list context) "format char == -- ? nothing : arg name" over the indices of the arg list.
		my @newarglist = map(printArgForArgType($self->{ARGTYPES}[$_], $self->{ARGNAMES}[$_]), (0..$self->numArgs - 1));
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

	$argtype =~ s/^\s+//g;
	$argtype =~ s/\s+$//g;

	return "NSStringFromSelector($argname)" if $argtype =~ /^SEL$/;
	return "$argname.location, $argname.length" if $argtype =~ /^NSRange$/;
	return "$argname.origin.x, $argname.origin.y, $argname.size.width, $argname.size.height" if $argtype =~ /^(CG|NS)Rect$/;
	return "$argname.x, $argname.y" if $argtype =~ /^(CG|NS)Point$/;
	return "$argname.width, $argname.height" if $argtype =~ /^(CG|NS)Size$/;

	return undef if formatCharForArgType($argtype) eq "--";

	return $argname;
}

sub formatCharForArgType {
	local $_ = shift;
	s/^\s+//g;
	s/\s+$//g;

	# Integral Types
	# Straight characters get %c. Signed/Unsigned characters get %hhu/%hhd.
	return "'%c'" if /^char$/;
	if(/^((signed|unsigned)\s+)?(unsigned|signed|int|long|long\s+long|bool|BOOL|_Bool|char|short)$/) {
		my $conversion = "d";
		$conversion = "u" if /\bunsigned\b/;

		my $length;
		$length = "" if /\bint\b/;
		$length = "l" if /\blong\b/;
		$length = "ll" if /\blong long\b/;
		$length = "h" if /\bshort\b/;
		$length = "hh" if /\bchar\b/;

		return "%".$length.$conversion;
	}
	return "%d" if /^NS(Integer|SocketNativeHandle|StringEncoding|SortOptions|ComparisonResult|EnumerationOptions|(Hash|Map)TableOptions|SearchPath(Directory|DomainMask))$/i;
	return "%u" if /^NSUInteger$/i;
	return "%d" if /^GS(FontTraitMask)$/i;

	# Pointer Types
	return "%s" if /^char\s*\*$/;
	return "%p" if /^void\s*\*$/;
	return "%p" if /^((unsigned|signed)\s+)?(unsigned|signed|int|long|long\s+long|bool|BOOL|_Bool|char|short|float|double)\s*\*+$/;
	return "%p" if /^NS.*?(Pointer|Array)$/;

	# Floating-Point Types
	return "%f" if /^(double|float|CGFloat|CGDouble|NSTimeInterval)$/;
	
	# Special Types (should also have an entry in printArgForArgType
	return "%@" if /^SEL$/;

	# Even-more-special expanded types
	return "(%d:%d)" if /^NSRange$/;
	return "{{%g, %g}, {%g, %g}}" if /^(CG|NS)Rect$/;
	return "{%g, %g}" if /^(CG|NS)Point$/;
	return "{%g, %g}" if /^(CG|NS)Size$/;

	# Opaque Types (pointer)
	return "%p" if /^NSZone$/;

	# Discarded Types
	return "--" if /^(CG\w*|CF\w*|void)$/;
	return "--" if /^NS(HashTable(Callbacks)?|Map(Table((Key|Value)Callbacks)?|Enumerator))$/;

	# Fallthrough
	return "%@";
}

sub typeEncodingForArgType {
	local $_ = shift;
	s/^\s+//g;
	s/\s+$//g;

	return "c" if /^char$/;
	return "i" if /^int$/;
	return "s" if /^short$/;
	return "l" if /^long$/;
	return "q" if /^long long$/;

	return "C" if /^unsigned\s+char$/;
	return "I" if /^unsigned\s+int$/;
	return "S" if /^unsigned\s+short$/;
	return "L" if /^unsigned\s+long$/;
	return "Q" if /^unsigned\s+long long$/;

	return "f" if /^float$/;
	return "d" if /^double$/;
	return "B" if /^(bool|_Bool)$/;

	return "v" if /^void$/;

	return "*" if /^char\s*\*$/;

	return "@" if /^id$/;
	return "#" if /^Class$/;
	return ":" if /^SEL$/;

	if(/^([^*\s]+)\s*\*$/) {
		my $subEncoding = typeEncodingForArgType($1);
		return undef if(!defined $subEncoding);
		return "^".$subEncoding;
	}

	return undef;
}

1;
