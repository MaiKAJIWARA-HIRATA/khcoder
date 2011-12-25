package gui_window::force_color;
use base qw(gui_window);
use strict;
use Tk;

#----------------------#
#   ���󥿡��ե�����   #
#----------------------#

#------------------#
#   Window�κ���   #

sub _new{
	my $self = shift;
	my %args = @_;
	$self->{parent} = $args{parent};
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # ��Ĵ�������

	# �ꥹ���ѥե졼��
	my $lf = $win->LabFrame(
		-label => 'List',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'y');

	$lf->Label(
		-text => kh_msg->get('desc'), # ���ʲ��θ��դ���˶�Ĵ����ޤ���
		-font => "TKFN",
	)->pack(
		-anchor =>'w',
		-padx   => 2,
	);

	my $plis = $lf->Scrolled(
		'HList',
		-scrollbars=> 'osoe',
		-header => 1,
		-width => 30,
		-itemtype => 'text',
		-font => 'TKFN',
		-columns => 2,
		-padx => 2,
		-background=> 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		-selectmode => 'extended',
	)->pack(-fill=>'both',-expand => 'yes',-pady => 2);
	$plis->header('create',0,-text => kh_msg->get('highlight_h')); # �����ա�
	$plis->header('create',1,-text => kh_msg->get('type_h')); # �����ࡡ

	$lf->Button(
		-text => kh_msg->get('delete'), # ���򤷤����դ���
		-font => "TKFN",
		-command => sub{$self->delete;}
	)->pack(-anchor => 'e');

	# �ɲ��ѥե졼��
	my $lf2 = $win->LabFrame(
		-label => 'Add',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	my $lf2a = $lf2->Frame()->pack(-fill => 'x',-expand => 'y');

	$lf2a->Label(
		-text => kh_msg->get('highlight'), # ���ա�
		-font => "TKFN",
	)->pack(
		-side => 'left',
		-pady => 2
	);
	$self->{entry} = $lf2a->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'left',-fill => 'x',-expand => 'y');
	$self->{entry}->bind(
		"<Key>",
		[\&gui_jchar::check_key_e,Ev('K'),\$self->{entry}]
	);
	$self->{entry}->bind("<Key-Return>",sub{$self->add;});

	$lf2->Label(
		-text => kh_msg->get('type'), # ���ࡧ
		-font => "TKFN",
	)->pack(
		-side => 'left'
	);
	$self->{menu} = gui_widget::optmenu->open(
		parent  => $lf2,
		width   => 6,
		pack    => {-side => 'left'},
		options => [
			[kh_msg->get('word'), '1'], # ��и�
			[kh_msg->get('string'), '0'], # ʸ����
		],
		variable => \$self->{type},
	);
	$lf2->Button(
		-text => kh_msg->get('add'), # �ɲ�
		-font => "TKFN",
		-command => sub{$self->add;}
	)->pack(-anchor => 'e');

	$win->Button(
		-text => kh_msg->gget('close'), # �Ĥ���
		#-width => 8,
		-font => "TKFN",
		-command => sub{$self->close;}
	)->pack(-anchor => 'c',);
	
	$self->{list}    = $plis;
	#$self->{win_obj} = $win;
	
	$self->refresh;
	return $self;
}

#----------------------#
#   ��Ĵ�ꥹ�Ȥι���   #

sub refresh{
	my $self = shift;
	$self->list->delete('all');
	my $row = 0;
	my $h = mysql_exec->select("
		SELECT name, type
		FROM d_force
		ORDER BY id
	",1)->hundle;
	while (my $i = $h->fetch){
		$self->list->add($row,-at => "$row");
		$self->list->itemCreate($row,0,-text => $self->gui_jchar($i->[0]));
		
		if ($i->[1]){
			$self->list->itemCreate(
				$row,
				1,
				-text => kh_msg->get('word') # ��и�
			);
		} else {
			$self->list->itemCreate(
				$row,
				1,
				-text => kh_msg->get('string') # ʸ����
			);
		}
		++$row;
	}
}

#--------------#
#   �����å�   #
#--------------#

#----------#
#   �ɲ�   #

sub add{
	my $self = shift;
	
	my ($word, $type) = (
		Jcode->new($self->gui_jg($self->{entry}->get),'sjis')->euc,
		$self->gui_jg($self->{type})
	);

	# ���Ϥ����뤫�ɤ���������å�
	unless (length($word)){
		gui_errormsg->open(
			msg    => kh_msg->get('no_word'),# ���դ����Ϥ���Ƥ��ޤ���
			type   => 'msg',
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	# Ʊ����Τ�����̵�����ɤ��������å�
	my $chk = mysql_exec->select("
		SELECT id FROM d_force WHERE name = \'$word\' AND type= $type
	",1)->hundle->rows;
	if ($chk){
		gui_errormsg->open(
			msg    => kh_msg->get('exists'),# ���θ��դϴ�����Ͽ����Ƥ��ޤ���
			type   => 'msg',
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	# �ɲ�
	mysql_exec->do("
		INSERT INTO d_force (name, type) VALUES (\'$word\', $type)
	",1);
	
	# ����ȥ�Υ��ꥢ
	$self->{entry}->delete(0,'end');

	# �ꥹ�ȹ���
	$self->refresh;
	$self->{edited} = 1;
	
	$self->{parent}->refresh;
	return $self;
}

#----------#
#   ���   #
sub delete{
	my $self = shift;
	
	# ���
	my @selected = $self->{list}->infoSelection;
	foreach my $i (@selected){
		my $word = Jcode->new(
			$self->gui_jg($self->list->itemCget($i,0,-text))
		)->euc;
		my $type = Jcode->new(
			$self->gui_jg($self->list->itemCget($i,1,-text))
		)->euc;
		if ($type eq '��и�' || $type eq 'word'){
			$type = 1;
		} else {
			$type = 0;
		}
		mysql_exec->do("
			DELETE FROM d_force
			WHERE
				name = \'$word\'
				AND type = $type
		",1);
		
	}
	
	# �ꥹ�ȹ���
	$self->refresh;
	$self->{edited} = 1;
	
	$self->{parent}->refresh;
	return $self;
}

#--------------#
#   ��������   #
#--------------#

sub list{
	my $self = shift;
	return $self->{list};
}

sub win_name{
	return 'w_force_color'; 
}
1;