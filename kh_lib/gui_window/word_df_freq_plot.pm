package gui_window::word_df_freq_plot;
use strict;
use Tk::PNG;
use base qw(gui_window);

#------------------#
#   Window�򳫤�   #
#------------------#

sub _new{
	my $self = shift;
	my %args = @_;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};

	$win->title($self->gui_jt('ʸ�����ʬ�ۡ��ץ��å�','euc'));
	
	$self->{img} = $win->Photo(-file => $args{images}->[1]->path);
	
	$self->{photo} = $win->Label(
		-image => $self->{img},
		-borderwidth => 2,
		-relief => 'sunken',
	)->pack(-anchor => 'c');

	my $f1 = $win->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 2);

	$f1->Label(
		-text => $self->gui_jchar(' �п����λ��ѡ�'),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');
	
	$self->{optmenu} = gui_widget::optmenu->open(
		parent  => $f1,
		pack    => {-anchor=>'e', -side => 'left', -padx => 0},
		options =>
			[
				[$self->gui_jchar('ʸ���(X)')  => 1],
				[$self->gui_jchar('ʸ���(X)���ٿ�(Y)') => 2],
				[$self->gui_jchar('�ʤ�') => 0],
			],
		variable => \$self->{ax},
		command  => sub {$self->renew;},
	);

	$f1->Button(
		-text => $self->gui_jchar('�Ĥ���'),
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub {
					$self->close();
				}
	)->pack(-side => 'right');

	$f1->Button(
		-text => $self->gui_jchar('��¸'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub {
					$self->save();
				}
	)->pack(-side => 'right', -padx => 4);

	$self->{images} = $args{images};
	return $self;
}

sub renew{
	my $self = shift;
	
	$self->{img}->read( $self->{images}[$self->{ax}]->path );
	
	$self->{photo}->update;
}

sub end{
	my $self = shift;
	$self->{images} = undef;
	$self->{img}->delete;
}

sub save{
	my $self = shift;

	# ��¸��λ���
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		#[ "Adobe PDF",[qw/.pdf/] ],
		[ "PNG",[qw/.png/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.eps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('�ץ��åȤ���¸'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{images}[$self->{ax}]->save($path) if $path;

	return 1;
}

#--------------#
#   Window̾   #

sub win_name{
	return 'w_word_df_freq_plot';
}

1;