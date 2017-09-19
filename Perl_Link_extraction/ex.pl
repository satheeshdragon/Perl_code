use strict;
use LWP;

my $browser = LWP::UserAgent->new;

my $responce = $browser->get("http://www.bing.com");
print $responce->content;
