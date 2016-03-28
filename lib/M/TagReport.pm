use strict;
use 5.010;

package M::TagReport;

use verbose;

use M::IO qw( _open_output _close_output );

################################################################################
#
# Scan for tags, and report a summary and list of anomalies
#

sub generate_tag_report($$;$) {
    my $out = shift;
    my $rr = shift;
    my $in_name = shift || '(stdin)';

    warn sprintf "DUMP: checking tags on %u records from %s\n", scalar @$rr, $in_name if $verbose;

    ( $out, my $out_name, my $close_when_done ) = _open_output $out;
    my @records = @$rr;
    RECORD: for my $r (@records) {
        my $errors = 0;
        #
        # Check #all vs #admin #attender etc
        #
        {
        my @t = $r->gtags(qw( admin attenders enquirer child inactive meeting members newsletter-only role ));
        if (@t == 0) {
            if ( $r->gtags('all') ) {
                _dump_one $out, $r, [] if !$errors++;
                print $out "* #all without other #tags\n";
            }
        } else {
            if ( !$r->gtags('all') ) {
                _dump_one $out, $r, [] if !$errors++;
                print $out "* #tags without #all\n";
            }
            if (@t > 1) {
                _dump_one $out, $r, [] if !$errors++;
                print $out "* multiple #tags (@t)\n";
            }
        }
        }

        #
        # Check #member vs @member - xx
        #
        {
        my @t = $r->gtags(qr(^member[- ]+(\w{2,3})[- ]+));
        if ( $r->gtags('member') ) {
            if (@t == 0) {
                _dump_one $out, $r, [] if !$errors++;
                print $out "* #member without \@member-*\n";
            }
        } else {
            if (@t > 0) {
                _dump_one $out, $r, [] if !$errors++;
                print $out "* \@member-* without #member\n";
            }
        }
        }

        #
        # Check that children are under 16
        #
        {
        my $b = $r->birthdate =~ s/\D//gr;
        my $age = die;
        if ( $r->gtags('child') ) {

                _dump_one $out, $r, [] if !$errors++;
                print $out "Birthday is $b\n";
                die;

            if ($age >= 16) {
                _dump_one $out, $r, [] if !$errors++;
                print $out "* too old to be child, age=$age\n";
            }
        } else {
            if ($b) {
                if ($age < 16) {
                    _dump_one $out, $r, [] if !$errors++;
                    print $out "* too yound to be adult, age=$age\n";
                }
            }
        }
        }

        print $out "\n" if $errors;
    }
    _close_output $out, $out_name, $close_when_done;
}

1;
