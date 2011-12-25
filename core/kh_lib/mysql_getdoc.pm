package mysql_getdoc;
use strict;
use mysql_exec;

use mysql_getdoc::bun;
use mysql_getdoc::dan;
use mysql_getdoc::h1;
use mysql_getdoc::h2;
use mysql_getdoc::h3;
use mysql_getdoc::h4;
use mysql_getdoc::h5;

sub get{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	$class .= '::'."$args{tani}";
	bless $self, $class;
	my $debug = 0;

	# ʸ�������
	print "id..." if $debug;
	unless ( defined($self->{doc_id}) && length($self->{doc_id}) ){
		$self->{doc_id} = $self->get_doc_id;
	}

	# ��ʸ�μ��Ф�
	print "body..." if $debug;
	my $d = $self->get_body;

	print "color1..." if $debug;
	my %for_color = ();                           # ��Ĵ����ν���
	foreach my $i (@{$self->{w_force}}){               # ����¾�Υ�����
		$for_color{$i} = "force";
	}
	foreach my $i (@{$self->{w_other}}){               # ����¾�Υ�����
		$for_color{$i} = "CodeW";
	}
	foreach my $i (@{$self->{w_search}}){              # ������
		$for_color{$i} = "search";
	}
	my $html = mysql_exec->select("                    # HTML����
		select hyoso.id
		from  hselection,
			genkei LEFT JOIN hyoso ON hyoso.genkei_id = genkei.id
		where
			genkei.khhinshi_id = hselection.khhinshi_id
			AND (
				   hselection.name = 'HTML����'
				|| hselection.name = 'HTML_TAG'
			)
	",1)->hundle;
	while (my $i = $html->fetch){
		$for_color{$i->[0]} = 'html';
	}
	
	print "color2..." if $debug;
	my @body = (); my $last = -1;                 # �����ղá������춯Ĵ
	my $lastw = '';
	foreach my $i (@{$d}){
		unless ($i->[2] == $last){
			$last = $i->[2];
			push @body, ["\n",''];
		}
		
		my $c = "$lastw"."$i->[0]";
		if ($c =~ /^<\/[Hh][1-5]><[Hh][1-5]>$/o){ push @body, ["\n",'']; }
		
		my $k = ''; if ($for_color{$i->[1]}){$k = $for_color{$i->[1]};}
		push @body, [Jcode->new("$i->[0]",'euc')->sjis, $k];
		$lastw = $i->[0];
		
	}
	$self->{body} = \@body;
	
	# ��̸��Ф��μ��Ф�
	print "header..." if $debug;
	$self->{header} = $self->get_header;
	
	print "done...\n" if $debug;
	return $self;
}

#----------------#
#   ��ʸ�μ���   #

sub get_body{
	my $self = shift;
	my $tani = $self->{tani};
	
	my $sql = "SELECT hyoso.name, hyoso.id, hyosobun.dan_id\n";
	$sql   .= "FROM hyoso, hyosobun, $tani\n";
	$sql   .= "WHERE\n";
	$sql   .= "    $tani.id = $self->{doc_id}\n";
	$sql   .= "    AND hyosobun.hyoso_id = hyoso.id\n";
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$sql .= "    AND hyosobun.$i"."_id = $tani.$i"."_id\n";
		if ($tani eq $i){last;}
	}
	$sql   .= "ORDER BY hyosobun.id";
	# print "$sql\n";
	return mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
}


#----------------#
#   ʸ�������   #

sub get_doc_id{
	my $self = shift;
	my $tani = $self->{tani};
	
	my $sql = "SELECT $tani.id\n";
	$sql   .= "FROM hyosobun, $tani\n";
	$sql   .= "WHERE\n";
	$sql   .= "    hyosobun.id = $self->{hyosobun_id}\n";
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$sql .= "    AND hyosobun.$i"."_id = $tani.$i"."_id\n";
		if ($tani eq $i){last;}
	}
	if (my $check = mysql_exec->select($sql,1)->hundle->fetch){
		return $check->[0]
	} else {
		my $n = 1;
		while (1){
			my $try = $self->{hyosobun_id} + $n;
			my $sql = "SELECT $tani.id\n";
			$sql   .= "FROM hyosobun, $tani\n";
			$sql   .= "WHERE\n";
			$sql   .= "    hyosobun.id = $try\n";
			foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				$sql .= "    AND hyosobun.$i"."_id = $tani.$i"."_id\n";
				if ($tani eq $i){last;}
			}
			if (my $check = mysql_exec->select($sql,1)->hundle->fetch){
				#print "$n tries\n";
				return $check->[0];
			}
			++$n;
			if ($n > 1000){
				return 1;
			}
		}
	}
}


#----------------------#
#   ��̸��Ф��μ���   #

sub get_header{
	my $self = shift;
	my $tani = $self->{tani};
	my @possible_header = ('h1','h2','h3','h4','h5');
	my $headers = '';
	
	my $sql = "SELECT id,";
	foreach my $i (@possible_header){
		$sql .= "$i"."_id,";
		if ($i eq $tani){last;}
	}
	chop $sql;
	$sql .= "\n";
	$sql .= "FROM $tani\n";
	$sql .= "WHERE id = $self->{doc_id}";
	my $id_info = mysql_exec->select($sql,1)->hundle->fetch;

	my %possible;
	foreach my $i (@possible_header){
		if ($i eq $tani){last;}                   # ��̤��ɤ��������å�
		if (                                      # ���������뤫�����å�
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			#print "getting $i header...\n";
			my $sql = "SELECT rowtxt\n";
			$sql   .= "FROM bun_r, bun\n";
			$sql   .= "WHERE\n";
			$sql   .= "    bun_r.id = bun.id\n";
			$sql   .= "    AND bun_id = 0\n";
			$sql   .= "    AND dan_id = 0\n";
			my $frag = 0; my $n = 5;
			foreach my $h ('h5','h4','h3','h2','h1'){
				if ($i eq $h){$frag = 1}
				if ($frag){
					$sql .= "    AND $h"."_id = $id_info->[$n]\n";
				} else {
					$sql .= "    AND $h"."_id = 0\n";
				}
				--$n;
			}
			$sql   .= "LIMIT 1";
			my $h = mysql_exec->select("$sql",1)->hundle->fetch->[0];
			$h = Jcode->new($h,'euc')->sjis;
			$headers .= "$h\n";
		}
	}
	return $headers;
}

sub if_next{
	my $self = shift;
	my $max = mysql_exec->select("
		SELECT max(id)
		FROM $self->{tani}
	",1)->hundle->fetch->[0];
	if ($self->{doc_id} < $max){
		return 1;
	} else {
		return 0;
	}
}


sub doc_id{
	my $self = shift;
	return $self->{doc_id};
}
sub body{
	my $self = shift;
	return $self->{body};
}
sub header{
	my $self = shift;
	return $self->{header};
}

sub id_for_print{
	my $self = shift;
	my $debug = 0;
	print "doc_id: $self->{doc_id}\n" if $debug;
	
	# ʸ��ΰ��־�������
	my $sql = 'SELECT ';
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$sql .= $i.'_id,';
		last if $i eq $self->{tani};
	}
	chop $sql;
	$sql .= "\n";
	$sql .= "FROM $self->{tani}\n";
	$sql .= "WHERE id = $self->{doc_id}";
	$sql = mysql_exec->select($sql,1)->hundle->fetch;
	
	my $r;
	my $n = 0;
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$r .= "$i = $sql->[$n],  ";
		last if $i eq $self->{tani};
		++$n;
	}
	chop $r;
	chop $r;
	chop $r;
	
	# �����ѿ��μ���
	my @vars;                           # �����ѿ��Υꥹ�Ⱥ���
	my %tani_check = ();
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$tani_check{$i} = 1;
		last if ($self->{tani} eq $i);
	}
	my $h = mysql_outvar->get_list;
	foreach my $i (@{$h}){
		if ($tani_check{$i->[0]}){      # �Ȥ��볰���ѿ����ɤ��������å�
			push @vars, mysql_outvar::a_var->new($i->[1],$i->[2]);
		}
	}
	if (@vars){
		$r .= "\n  ";
	} else {
		return $r;
	}
	foreach my $i (@vars){              # �ͤμ���
		my $val = $i->doc_val(
			doc_id => $self->{doc_id},
			tani   => $self->{tani}
		);
		$val = $i->print_val($val);
		$r .= Jcode->new($i->{name},'euc')->sjis;
		$r .= " = ".Jcode->new($val,'euc')->sjis.",  ";
	}
	chop $r;
	chop $r;
	chop $r;
	
	return $r;
}



1;