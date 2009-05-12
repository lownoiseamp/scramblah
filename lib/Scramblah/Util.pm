package Scramblah::Util;


sub new {
	my ($class) = shift;
	return bless({}, $class);
}

sub error {
	my ($self, $msg, $pkg) = @_;
	print STDERR  "-- $pkg -> $msg \n";
	return 1;
}

1;
