create or replace
PACKAGE BODY      XX01_ASSET_INCRE_PKG
/*****************************************************************************
 * $ Header: XX01_ASSET_INCRE_PKG.pkb 11.5.2 0.0.0.0 2003/08/05 $
 * ���ʕ��̑S�Ă̒m�I���Y���͕��ЂɋA�����܂��B
 * ���ʕ��̎g�p�A�����A���ρE�|�ẮA���{�I���N���ЂƂ̌_��ɋL���ꂽ��������ɏ]�����̂Ƃ��܂��B
 * ORACLE��Oracle Corporation�̓o�^���W�ł��B
 * Copyright (c) 2003 Oracle Corporation Japan All Rights Reserved
 * �p�b�P�[�W�� :		XX01_ASSET_INCRE_PKG
 * �@�\�T�v     :		���Y���������\�o�̓��[�N�e�[�u���쐬
 * �o�[�W����   :		11.5.3
 * �쐬��       :
 * �쐬��       :		2001-10-12
 * �ύX��       :
 * �ŏI�ύX��   :		2010-12-29
 * �ύX����     :
 *		2003-08-05	UTF-8�Ή�
 * ------------- -------- ------------- -------------------------------------
 *  Date          Ver.     Editor        Description
 * ------------- -------- ------------- -------------------------------------
 *  2010-12-29    11.5.3   SCS �n��      [E_�{�ғ�_05184]
 *                                       ���[���[�N�o�͂ւ̃u���C�N�����C��
 *                                       �U�֑Ώۃ`�F�b�N(�ݎ؈�v�Z�O�����g��r)�폜
 ****************************************************************************/
IS
--- ******************
--- �O���[�o���ϐ���`
--- ******************
		gn_sequence_id								NUMBER(15);				--�V�[�P���X�ԍ�
		gn_created_by									NUMBER(15);				--�쐬�҂̃��[�U�h�c
		gd_creation_date							DATE;							--�쐬����
		gn_last_updated_by						NUMBER(15);				--�ŏI�ύX�҂̃��[�U�h�c
		gd_last_update_date						DATE;							--�ŏI�ύX����
		gn_last_update_login					NUMBER(15);				--�ŏI���O�C��
		gn_request_id									NUMBER(15);				--�v���h�c
		gn_program_application_id			NUMBER(15);				--�`�o�̂h�c
		gn_program_id									NUMBER(15);				--�o�f�̂h�c
		gd_program_update_date				DATE;							--�ŏI�ύX����

		gv_company_name								VARCHAR2(30);			--��Ж�
		gv_book_type_code							fa_books.book_type_code%type;		--�䒠��
		gv_asset_type_code						VARCHAR2(80);			--���Y�^�C�v�R�[�h
		gv_account_periods_from				VARCHAR2(15);			--���F��v���Ԗ���
		gv_account_periods_to					VARCHAR2(15);			--���F��v���Ԗ���
		gv_account_unit_code_from			VARCHAR2(150);		--���F��v�P��
		gv_account_unit_code_to				VARCHAR2(150);		--���F��v�P��

		gn_period_counter_from				NUMBER(15);				--���F��v����
		gn_period_counter_to					NUMBER(15);				--���F��v����
		gv_asset_type									VARCHAR2(80);			--���Y�^�C�v
		gn_accounting_flex_structure	NUMBER(15);				--��v�P�ʎ擾���

		gv_adjustment_type						VARCHAR2(15);
		gv_source_type_code_add				VARCHAR2(15);
		gv_source_type_code_adjust		VARCHAR2(15);
		gv_source_type_code_trans			VARCHAR2(15);

		USER_EXPT											EXCEPTION;				--��O����

--- ****************
--- �R���X�^���g��`
--- ****************
		--�f�[�^���
		gc_addition			CONSTANT NUMBER(1) := 1;
		gc_adjustment		CONSTANT NUMBER(1) := 2;
		gc_transfer			CONSTANT NUMBER(1) := 3;
		--�������R
-- Update 2003-08-05
--		gc_add_new_n		CONSTANT VARCHAR2(8) := '�V�K�擾';
--		gc_add_used_n		CONSTANT VARCHAR2(8) := '���Î擾';
--		gc_adjustment_n	CONSTANT VARCHAR2(8) := '�C��';
--		gc_transfer_n		CONSTANT VARCHAR2(8) := '�U��';
		gc_add_new_n		CONSTANT VARCHAR2(16) := '�V�K�擾';
		gc_add_used_n		CONSTANT VARCHAR2(16) := '���Î擾';
		gc_adjustment_n	CONSTANT VARCHAR2(16) := '�C��';
		gc_transfer_n		CONSTANT VARCHAR2(16) := '�U��';

--- ****************
--- �V�X�e���Ǘ����
--- ****************
		g_control_rec			fa_system_controls%rowtype;

--- **************
--- �o�͂q�n�v��`
--- **************
		g_incre_wk_rec		xx01_asset_increase_wk%rowtype;

--- ****************
--- �o�͌����J�E���^
--- ****************
		gn_count	NUMBER(38,0)		:=	0;

--- **************
--- �C�������𒊏o
--- **************
		CURSOR		g_adjust_cur IS
			--- ************************
			--- �V�K�擾�i���Î擾�܂ށj
			--- ************************
			SELECT	--�f�[�^��t���O
							gc_addition									data_type_flag,
							--�b�b�h�c�i��v�P�ʎ擾���g�p�j
							fdh.code_combination_id			c_code_combination_id,
							--�J�e�S���[�h�c�i��J�e�S���[�擾���g�p�j
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,	--���p���@
							fab.asset_number						asset_number,				--���Y�ԍ�
							fat.description							asset_description,	--���Y�E�v
							faj.period_counter_created	period_counter,			--��v����
							fdp.period_name							period_name,				--��v���Ԗ���
							faj.transaction_header_id		transaction_id,			--�g�����h�c
							fab.attribute2							acquisition_date,		--�擾��
							fb1.date_placed_in_service	placed_in_service,	--���Ƌ��p��
							fdh.units_assigned					increase_units,			--��������
							DECODE(fab.new_used,'NEW',
                     gc_add_new_n,
										 gc_add_used_n)				increase_reason,		--�������R
							0														before_cost,				--�����O�擾���z
							faj.adjustment_amount				addition_cost,			--�V�K�擾���z
							0														increase_cost,			--�C�����z
							faj.adjustment_amount				after_cost					--������擾���z
			FROM		fa_additions_tl					fat,
			    		fa_additions_b					fab,
							fa_books								fb1,
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_add
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'DR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			--- ********
			--- �C������
			--- ********
			UNION ALL
      SELECT  gc_adjustment								data_type_flag,
              fdh.code_combination_id     c_code_combination_id,
              fah.category_id         		category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							0														increase_units,
							gc_adjustment_n							increase_reason,
							fb2.cost										before_cost,
							0														addition_cost,
							faj.adjustment_amount				increase_cost,
							fb1.cost										after_cost
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,		--������擾���z�擾�p
							fa_books								fb2,		--�����O�擾���z�擾�p
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_adjust
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'DR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.transaction_header_id 	= fb1.transaction_header_id_in
			AND			faj.asset_id								=	fb2.asset_id
			AND			faj.transaction_header_id 	= fb2.transaction_header_id_out
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			--- ********
			--- �U�֑���
			--- ********
			UNION ALL
      SELECT  gc_transfer									data_type_flag,
							fdh.code_combination_id			c_code_combination_id,
							fah.category_id							category_id,
							fb1.deprn_method_code				deprn_method_code,
							fab.asset_number						asset_number,
							fat.description							asset_description,
							faj.period_counter_created	period_counter,
							fdp.period_name							period_name,
							faj.transaction_header_id		transaction_id,
							fab.attribute2							acquisition_date,
							fb1.date_placed_in_service	placed_in_service,
							fdh.units_assigned					increase_units,
							gc_transfer_n								increase_reason,
							0														before_cost,
							0														addition_cost,
							faj.adjustment_amount				increase_cost,
							faj.adjustment_amount				after_cost
			FROM		fa_additions_tl					fat,
							fa_additions_b					fab,
							fa_books								fb1,
							fa_distribution_history fdh,
							fa_deprn_periods 				fdp,
							fa_asset_history 				fah,
							fa_adjustments					faj
			WHERE		faj.book_type_code					=	gv_book_type_code
			AND			faj.period_counter_created	BETWEEN gn_period_counter_from
		 																					AND gn_period_counter_to
			AND			faj.source_type_code				=	gv_source_type_code_trans
			AND			faj.adjustment_type					=	gv_adjustment_type
			AND			faj.debit_credit_flag				=	'DR'
			AND			faj.asset_id								=	fat.asset_id
			AND			faj.asset_id								=	fab.asset_id
			AND			faj.asset_id								=	fb1.asset_id
			AND			faj.book_type_code					=	fb1.book_type_code
			AND			faj.transaction_header_id	>= fb1.transaction_header_id_in
			AND			faj.transaction_header_id  < nvl(fb1.transaction_header_id_out,
																														999999999999999)
			AND			faj.asset_id								=	fah.asset_id
			AND			fah.transaction_header_id_in =
     					(SELECT	MAX(fah2.transaction_header_id_in)
								FROM	fa_asset_history	fah2
								WHERE	fah2.asset_id	= faj.asset_id
								AND		fah2.transaction_header_id_in
										<= faj.transaction_header_id)
			AND			faj.distribution_id					=	fdh.distribution_id
			AND			faj.period_counter_created	=	fdp.period_counter
			AND  		fdp.book_type_code					=	gv_book_type_code
			AND			fat.language								=	userenv('LANG')
			AND 		fah.asset_type							=	gv_asset_type_code
			ORDER BY c_code_combination_id,category_id;

		g_adjust_rec	g_adjust_cur%rowtype;

------------------------------------------------------------------------------
	PROCEDURE initialize_proc(	ov_errbuf			OUT		VARCHAR2,
															on_retcode		OUT		NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE��	:		initialize_proc
 * �@�\�T�v			:		����������
 * �o�[�W����		:		1.0.0
 * ����					:		errbuf			�G���[�o�b�t�@
 * �߂�l				:		retcode			�G���[�R�[�h(����: 0,�x��: 1,�G���[: 2)
 * ���ӎ���			:		���ɖ���
 * �쐬��       :
 * �쐬��       :		2001-10-15
 * �ύX��       :
 * �ŏI�ύX��   :		YYYY-MM-DD
 * �ύX����     :		YYYY-MM-DD
 *								�m--------------------------------------------------------�m
 *								�m--------------------------------------------------------�m
 ****************************************************************************/
		lv_errbuf	VARCHAR2(2000)		:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
		ov_errbuf			:=		NULL;
		on_retcode		:=		0;
--- ************************************
--- �R���J�����g���O�t�@�C���o�͏�������
--- ************************************
		xx01_conc_util_pkg.conc_log_start;
--- ********************************
--- �R���J�����g���O�o�́i�薼�o�́j
--- ********************************
  	xx01_conc_util_pkg.conc_log_put( '���Y�������ו\�i�������j���o���O' );
		xx01_conc_util_pkg.conc_log_line( '=' );
--- ********************
--- �O���[�o���ϐ��Z�b�g
--- ********************
		gn_created_by							:= fnd_global.user_id;
		gd_creation_date					:= SYSDATE;
		gn_last_updated_by				:= fnd_global.user_id;
		gd_last_update_date				:= SYSDATE;
		gn_last_update_login			:= fnd_global.conc_login_id;
		gn_request_id							:= fnd_global.conc_request_id;
		gn_program_application_id	:= fnd_global.prog_appl_id;
		gn_program_id							:= fnd_global.conc_program_id;
		gd_program_update_date		:= SYSDATE;
--- **************************
--- �e�`�V�X�e���Ǘ��l��荞��
--- **************************
		SELECT	*
		INTO		g_control_rec
		FROM		fa_system_controls;
		gv_company_name := g_control_rec.company_name;
--- ************
--- ��v���Ԏ擾
--- ************
		get_period_counter(lv_errbuf,
											 ln_retcode,
											 gv_book_type_code,
											 gv_account_periods_from,
                       gn_period_counter_from);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
		get_period_counter(lv_errbuf,
											 ln_retcode,
											 gv_book_type_code,
											 gv_account_periods_to,
                       gn_period_counter_to);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
--- **************
--- ���Y�^�C�v�ϊ�
--- **************
		conv_asset_type(lv_errbuf,
										ln_retcode,
										gv_asset_type,
                    gv_asset_type_code);
		IF ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
		--�b�h�o�Ή�
		IF gv_asset_type_code = 'CIP' THEN
			gv_adjustment_type := 'CIP COST';
			gv_source_type_code_add := 'CIP ADDITION';
			gv_source_type_code_adjust := 'CIP ADJUSTMENT';
		ELSE
			gv_adjustment_type := 'COST';
			gv_source_type_code_add := 'ADDITION';
			gv_source_type_code_adjust := 'ADJUSTMENT';
		END IF;
		gv_source_type_code_trans := 'TRANSFER';
--- ********
--- ��O����
--- ********
	EXCEPTION
	WHEN USER_EXPT THEN
		ov_errbuf	:= lv_errbuf ;
		on_retcode	:= ln_retcode ;
	WHEN OTHERS THEN
		ov_errbuf	:= xx01_conc_util_pkg.get_message_others
									( 'xx01_asset_incre_pkg.initialize' ) ;
		on_retcode	:= 2;
	END initialize_proc;
------------------------------------------------------------------------------
	PROCEDURE insert_incre_wk(	ov_errbuf					OUT	VARCHAR2,
															on_retcode				OUT	NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE��	:		insert_incre_wk
 * �@�\�T�v			:		���[�N�c�a�o�͏���
 * �o�[�W����		:		1.0.0
 * �߂�l				:		ov_errbuf   				�G���[�o�b�t�@
 * �@�@�@				:		on_retcode					�G���[�R�[�h(����:0,�x��:1,�G���[:2)
 * ���ӎ���			:		���ɖ���
 * �쐬��       :
 * �쐬��       :		2001-10-19
 * �ύX��       :
 * �ŏI�ύX��   :		YYYY-MM-DD
 * �ύX����     :		YYYY-MM-DD
 *								�m--------------------------------------------------------�m
 *								�m--------------------------------------------------------�m
 ****************************************************************************/
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
--- **************
--- ���[�N�c�a�o��
--- **************
		INSERT INTO xx01_asset_increase_wk(
								asset_increase_wk_id,
								sequence_id,
								created_by,
								creation_date,
								last_updated_by,
								last_update_date,
								last_update_login,
								request_id,
								program_application_id,
								program_id,
								program_update_date,
								company_name,
								book_type_code,
								asset_type,
								account_periods_from,
								account_periods_to,
								account_unit_code,
								account_unit_name,
								category,
								asset_number,
								asset_description,
								period_counter,
								period_name,
								transaction_id,
								deprn_method_code,
								life,
								acquisition_date,
								date_placed_in_service,
								increase_units,
								increase_reason,
								before_cost,
								addition_cost,
								increase_cost,
								after_cost)
				VALUES
							 (
								xx01_asset_incre_wk_s.nextval,
								gn_sequence_id,
								gn_created_by,
								gd_creation_date,
								gn_last_updated_by,
								gd_last_update_date,
								gn_last_update_login,
								gn_request_id,
								gn_program_application_id,
								gn_program_id,
								gd_program_update_date,
								gv_company_name,
								gv_book_type_code,
								gv_asset_type,
								gv_account_periods_from,
								gv_account_periods_to,
								g_incre_wk_rec.account_unit_code,
								g_incre_wk_rec.account_unit_name,
								g_incre_wk_rec.category,
								g_incre_wk_rec.asset_number,
								g_incre_wk_rec.asset_description,
								g_incre_wk_rec.period_counter,
								g_incre_wk_rec.period_name,
								g_incre_wk_rec.transaction_id,
								g_incre_wk_rec.deprn_method_code,
								g_incre_wk_rec.life,
								g_incre_wk_rec.acquisition_date,
								g_incre_wk_rec.date_placed_in_service,
								g_incre_wk_rec.increase_units,
								g_incre_wk_rec.increase_reason,
								g_incre_wk_rec.before_cost,
								g_incre_wk_rec.addition_cost,
								g_incre_wk_rec.increase_cost,
								g_incre_wk_rec.after_cost
							 );

		gn_count		:= gn_count	+	1;

--- ********
--- ����I��
--- ********
		ov_errbuf		:= NULL;
		on_retcode	:= 0;
--- ********
--- ��O����
--- ********
	EXCEPTION
	WHEN OTHERS THEN
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_incre_pkg.insert_incre_wk' );
		on_retcode	:= 2;
	END insert_incre_wk;
------------------------------------------------------------------------------
	PROCEDURE get_adjustment(	ov_errbuf						OUT	VARCHAR2,
														on_retcode					OUT	NUMBER)
	IS
/*****************************************************************************
 * PROCEDURE��	:		get_adjustment
 * �@�\�T�v			:		�ύX�f�[�^�擾����
 * �o�[�W����		:		1.0.0
 * �߂�l				:		ov_errbuf   				�G���[�o�b�t�@
 * �@�@�@				:		on_retcode					�G���[�R�[�h(����:0,�x��:1,�G���[:2)
 * ���ӎ���			:		���ɖ���
 * �쐬��       :
 * �쐬��       :		2001-10-18
 * �ύX��       :
 * �ŏI�ύX��   :		YYYY-MM-DD
 * �ύX����     :		YYYY-MM-DD
 *								�m--------------------------------------------------------�m
 *								�m--------------------------------------------------------�m
 ****************************************************************************/
  	lv_errbuf								VARCHAR2(2000)	:= NULL;
  	ln_retcode							NUMBER(1)				:= 0;
		ln_sv_ccid							NUMBER(15)			:= 0;
		ln_sv_catid  						NUMBER(15)			:= 0;
		lb_range_flag 					BOOLEAN					:= TRUE;
		lb_write_flag 					BOOLEAN 				:= TRUE;
		lv_account_unit_code		VARCHAR2(150);
		lv_account_unit_name		VARCHAR2(240);
		lv_category							VARCHAR2(30);
		ln_life									NUMBER(3);
		ln_cr_ccid							NUMBER(15);
		lv_cr_account_unit_code	VARCHAR2(150);
--- ******************************
--- �U�֑Ώۃ`�F�b�N�p�J�[�\����`
--- ******************************
	CURSOR l_cr_ccid_cur IS
		SELECT	fdh.code_combination_id
		FROM		fa_distribution_history fdh,
						fa_adjustments					faj
		WHERE		faj.transaction_header_id	=	g_adjust_rec.transaction_id
		AND			faj.source_type_code			=	gv_source_type_code_trans
		AND			faj.adjustment_type				=	gv_adjustment_type
		AND			faj.debit_credit_flag			=	'CR'
		AND			faj.distribution_id				=	fdh.distribution_id;
		l_cr_ccid_rec	l_cr_ccid_cur%rowtype;

	BEGIN
--- **************
--- �ύX�f�[�^�擾
--- **************
	OPEN	g_adjust_cur;
	LOOP
		lb_write_flag := TRUE;
		FETCH	g_adjust_cur	INTO	g_adjust_rec;
			EXIT	WHEN	g_adjust_cur%notfound;
--- ****************
--- �b�b�h�c�`�F�b�N
--- ****************
			IF g_adjust_rec.c_code_combination_id != ln_sv_ccid THEN
				lb_range_flag := TRUE;
				--��v�P�ʎ擾
				BEGIN
					lv_account_unit_code	:=	fa_rx_flex_pkg.get_value(
																			g_control_rec.gl_application_id,
																			'GL#',
																			gn_accounting_flex_structure,
																			'GL_BALANCING',
																			g_adjust_rec.c_code_combination_id
																				);
				EXCEPTION
				WHEN OTHERS THEN
					lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00062');
					RAISE USER_EXPT;
				END;
				IF gv_account_unit_code_from IS NOT NULL THEN
					IF gv_account_unit_code_from > lv_account_unit_code THEN
						lb_range_flag := FALSE;
						lb_write_flag := FALSE;
					END IF;
				END IF;
				IF gv_account_unit_code_to IS NOT NULL AND
					 lb_write_flag	= TRUE	THEN
					IF gv_account_unit_code_to < lv_account_unit_code THEN
						lb_range_flag := FALSE;
						lb_write_flag := FALSE;
					END IF;
				END IF;
				--��v�P�ʖ��̎擾����
				IF lb_range_flag	= TRUE AND
					 lb_write_flag	= TRUE THEN
					BEGIN
						lv_account_unit_name := xx01_util_pkg.get_segdata(
																			g_control_rec.gl_application_id,
																			'GL#',
																			gn_accounting_flex_structure,
																			'GL_BALANCING',
																			lv_account_unit_code
																				);
					EXCEPTION
					WHEN OTHERS THEN
						lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00063');
						RAISE USER_EXPT;
					END;
				END IF;
				ln_sv_ccid := g_adjust_rec.c_code_combination_id;
			END IF;
--- **************************
--- �U�֑Ώۃ`�F�b�N
--- �i�ݎ؈�v�Z�O�����g��r�j
--- **************************
--
-- ************ 2010-12-29 11.5.3 M.Watanabe DEL START ************ --
--			IF g_adjust_rec.data_type_flag = gc_transfer AND
--				 lb_range_flag	= TRUE AND
--				 lb_write_flag	= TRUE THEN
--				--�P���Y�����������Y�ɂ��Ă͕ۏ؂ł��܂���B
--				OPEN l_cr_ccid_cur;
--				FETCH	l_cr_ccid_cur	INTO	l_cr_ccid_rec;
--					EXIT	WHEN	l_cr_ccid_cur%notfound;
--				ln_cr_ccid := l_cr_ccid_rec.code_combination_id;
--				CLOSE l_cr_ccid_cur;
--				--�U�֑O��v�P�ʎ擾
--				BEGIN
--					lv_cr_account_unit_code	:=	fa_rx_flex_pkg.get_value(
--																				g_control_rec.gl_application_id,
--																				'GL#',
--																				gn_accounting_flex_structure,
--																				'GL_BALANCING',
--																				ln_cr_ccid
--																				);
--				EXCEPTION
--				WHEN OTHERS THEN
--					lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00064');
--					RAISE USER_EXPT;
--				END;
--				--�ݎ؈�v�Z�O�����g�������Ȃ�ΏۊO
--				IF lv_account_unit_code = lv_cr_account_unit_code THEN
--					lb_write_flag := FALSE;
--				END IF;
--			END IF;
-- ************ 2010-12-29 11.5.3 M.Watanabe DEL END   ************ --
--
--- **********************
--- �J�e�S���[�h�c�`�F�b�N
--- **********************
			IF g_adjust_rec.category_id != ln_sv_catid AND
				 lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				--��J�e�S���[�擾
				BEGIN
					lv_category	:=	fa_rx_flex_pkg.get_value(
														g_control_rec.fa_application_id,
														'CAT#',
														g_control_rec.category_flex_structure,
														'BASED_CATEGORY',
														g_adjust_rec.category_id
															) ;
				EXCEPTION
				WHEN OTHERS THEN
					lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00032');
					RAISE USER_EXPT;
				END;
				ln_sv_catid := g_adjust_rec.category_id;
			END IF;
--- ************
--- �ϗp�N���擾
--- ************
			IF lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				xx01_util_pkg.get_life(lv_errbuf,
															 ln_retcode,
															 ln_life,
															 g_adjust_rec.deprn_method_code
																);
				IF ln_retcode != 0 THEN
						lv_errbuf := xx01_conc_util_pkg.get_message('APP_XX01_00065');
						RAISE USER_EXPT;
				END IF;
			END IF;
--- ****************
--- �o�͂q�n�v�Z�b�g
--- ****************
			IF lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				g_incre_wk_rec.account_unit_code 			:= lv_account_unit_code;
				g_incre_wk_rec.account_unit_name 			:= lv_account_unit_name;
				g_incre_wk_rec.category 							:= lv_category;
				g_incre_wk_rec.asset_number 					:= g_adjust_rec.asset_number;
				g_incre_wk_rec.asset_description 			:=
																					g_adjust_rec.asset_description;
				g_incre_wk_rec.period_counter 				:= g_adjust_rec.period_counter;
				g_incre_wk_rec.period_name 						:= g_adjust_rec.period_name;
				g_incre_wk_rec.transaction_id 				:= g_adjust_rec.transaction_id;
				g_incre_wk_rec.deprn_method_code 			:=
																					g_adjust_rec.deprn_method_code;
				g_incre_wk_rec.life 									:= ln_life;
				g_incre_wk_rec.acquisition_date 			:=
																					g_adjust_rec.acquisition_date;
				g_incre_wk_rec.date_placed_in_service :=
																					g_adjust_rec.placed_in_service;
				g_incre_wk_rec.increase_units 				:= g_adjust_rec.increase_units;
				g_incre_wk_rec.increase_reason 				:= g_adjust_rec.increase_reason;
				g_incre_wk_rec.before_cost 						:= g_adjust_rec.before_cost;
				g_incre_wk_rec.addition_cost 					:= g_adjust_rec.addition_cost;
				g_incre_wk_rec.increase_cost 					:= g_adjust_rec.increase_cost;
				g_incre_wk_rec.after_cost 						:= g_adjust_rec.after_cost;
			END IF;
--- **************
--- ���[�N�c�a�o��
--- **************
			IF lb_range_flag	= TRUE AND
				 lb_write_flag	= TRUE THEN
				insert_incre_wk(	ln_retcode,
													lv_errbuf);
				IF ln_retcode != 0 THEN
						RAISE USER_EXPT;
				END IF;
			END IF;
	END	LOOP;
	CLOSE	g_adjust_cur;

	xx01_conc_util_pkg.conc_log_line( '=' );

--- ********
--- ����I��
--- ********
		on_retcode	:= 0;
		ov_errbuf		:= NULL;
--- ********
--- ��O����
--- ********
	EXCEPTION
	WHEN	USER_EXPT	THEN
		IF g_adjust_cur%ISOPEN THEN
			CLOSE	g_adjust_cur;
		END IF;
		IF l_cr_ccid_cur%ISOPEN THEN
			CLOSE	l_cr_ccid_cur;
		END IF;
		ov_errbuf		:= lv_errbuf;
		on_retcode	:= 2;
	WHEN OTHERS THEN
		IF g_adjust_cur%ISOPEN THEN
			CLOSE	g_adjust_cur;
		END IF;
		IF l_cr_ccid_cur%ISOPEN THEN
			CLOSE	l_cr_ccid_cur;
		END IF;
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_incre_pkg.get_adjustment' );
		on_retcode	:= 2;
	END get_adjustment;
------------------------------------------------------------------------------
	PROCEDURE get_period_counter(	ov_errbuf					OUT	VARCHAR2,
																on_retcode				OUT	NUMBER,
																iv_book_type_code IN  VARCHAR2,
																iv_period_name		IN	VARCHAR2,
																on_period_counter OUT NUMBER )
	IS
/*****************************************************************************
 * PROCEDURE��	:		get_period_counter
 * �@�\�T�v			:		��v���Ԏ擾����
 * �o�[�W����		:		1.0.0
 * ����					:		iv_book_type_code		�䒠
 *   						:		iv_period_name			��v���Ԗ���
 * �߂�l				:		ov_errbuf   				�G���[�o�b�t�@
 * �@�@�@				:		on_retcode					�G���[�R�[�h(����:0,�x��:1,�G���[:2)
 * �@�@�@				:		on_period_counter		��v����
 * ���ӎ���			:		���ɖ���
 * �쐬��       :
 * �쐬��       :		2001-10-15
 * �ύX��       :
 * �ŏI�ύX��   :		YYYY-MM-DD
 * �ύX����     :		YYYY-MM-DD
 *								�m--------------------------------------------------------�m
 *								�m--------------------------------------------------------�m
 ****************************************************************************/
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
--- ************
--- ��v���Ԏ擾
--- ************
		SELECT 	period_counter
		INTO		on_period_counter
		FROM		fa_deprn_periods
		WHERE		book_type_code = iv_book_type_code
		AND			period_name = iv_period_name;
--- ********
--- ����I��
--- ********
		on_retcode	:= 0;
		ov_errbuf		:= NULL;
--- ********
--- ��O����
--- ********
	EXCEPTION
	WHEN OTHERS THEN
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_incre_pkg.get_period_counter' );
		on_retcode	:= 2;
	END get_period_counter;
------------------------------------------------------------------------------
	PROCEDURE conv_asset_type(	ov_errbuf						OUT	VARCHAR2,
															on_retcode					OUT	NUMBER,
															ov_asset_type				OUT VARCHAR2,
															iv_asset_type_code	IN VARCHAR2 )
	IS
/*****************************************************************************
 * PROCEDURE��	:		conv_asset_type
 * �@�\�T�v			:		���Y�^�C�v�ϊ�����
 * �o�[�W����		:		1.0.0
 * ����					:		iv_asset_type_code	���Y�^�C�v�R�[�h
 * �߂�l				:		ov_errbuf   				�G���[�o�b�t�@
 * �@�@�@				:		on_retcode					�G���[�R�[�h(����:0,�x��:1,�G���[:2)
 * �@�@�@				:		ov_asset_type				���Y�^�C�v
 * ���ӎ���			:		���ɖ���
 * �쐬��       :
 * �쐬��       :		2001-10-16
 * �ύX��       :
 * �ŏI�ύX��   :		YYYY-MM-DD
 * �ύX����     :		YYYY-MM-DD
 *								�m--------------------------------------------------------�m
 *								�m--------------------------------------------------------�m
 ****************************************************************************/
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
	BEGIN
--- **************
--- ���Y�^�C�v�擾
--- **************
		SELECT 	meaning
		INTO		ov_asset_type
		FROM		fa_lookups_tl
		WHERE		lookup_type = 'ASSET TYPE'
		AND			lookup_code = iv_asset_type_code
		AND			language = userenv('LANG');
--- ********
--- ����I��
--- ********
		on_retcode	:= 0;
		ov_errbuf		:= NULL;
--- ********
--- ��O����
--- ********
	EXCEPTION
	WHEN OTHERS THEN
		ov_errbuf		:= xx01_conc_util_pkg.get_message_others
										( 'xx01_asset_incre_pkg.conv_asset_type' );
		on_retcode	:= 2;
	END conv_asset_type;
------------------------------------------------------------------------------
	PROCEDURE	main_proc(		errbuf												OUT	VARCHAR2,
													retcode												OUT	NUMBER,
													iv_book_type_code							IN	VARCHAR2,
													in_accounting_flex_structure	IN	NUMBER,		--��\��
													iv_asset_type									IN	VARCHAR2,
													iv_account_periods_from				IN	VARCHAR2,
													iv_account_periods_to					IN	VARCHAR2,
													iv_account_unit_code_from			IN	VARCHAR2,
													iv_account_unit_code_to				IN	VARCHAR2,
													in_sequence_id								IN	NUMBER	)

	IS
/*****************************************************************************
 * PROCEDURE��	:		main_proc
 * �@�\�T�v			:		���Y�������ו\�i�������j�ɕK�v�ȃf�[�^�𒊏o���A
 * 									���[�N�e�[�u���ɏo�͂��܂��B
 * �o�[�W����		:		1.0.0
 * ����					:		IN	iv_book_type_code							���Y�䒠��
 *									IN	in_accounting_flex_structure	��v�e�e�̌n�i��\���j
 *									IN	iv_asset_type									���Y�^�C�v
 *									IN	iv_account_periods_from						���F��v����
 *									IN	iv_account_periods_to							���F��v����
 *									IN	iv_account_unit_code_from			���F��v�P��
 *									IN	iv_account_unit_code_to				���F��v�P��
 * �߂�l				:		OUT	errbuf				�G���[�o�b�t�@
 *									OUT	retcode				�G���[�R�[�h(����: 0,�x��: 1,�G���[: 2)
 * ���ӎ���			:		���ɖ���
 * �쐬��       :
 * �쐬��       :		2001-10-15
 * �ύX��       :
 * �ŏI�ύX��   :		YYYY-MM-DD
 * �ύX����     :		YYYY-MM-DD
 *								�m--------------------------------------------------------�m
 *								�m--------------------------------------------------------�m
 ****************************************************************************/
--
		lv_errbuf	VARCHAR2(2000)	:= NULL;
		ln_retcode	NUMBER(1)				:= 0;
--
	BEGIN
		errbuf		:=		NULL;
		retcode		:=		0;
--- **********************
--- �N���p�����[�^���O�o��
--- **********************
		xx01_conc_util_pkg.conc_log_line('=');
		xx01_conc_util_pkg.conc_log_param('�䒠',iv_book_type_code,1);
		xx01_conc_util_pkg.conc_log_param('���Y�^�C�v',iv_asset_type,2);
		xx01_conc_util_pkg.conc_log_param('���F��v����'
																						,iv_account_periods_from,3);
		xx01_conc_util_pkg.conc_log_param('���F��v����'
																						,iv_account_periods_to,4);
		xx01_conc_util_pkg.conc_log_param('���F��v�P��'
																						,iv_account_unit_code_from,5);
		xx01_conc_util_pkg.conc_log_param('���F��v�P��'
																						,iv_account_unit_code_TO,6);
		xx01_conc_util_pkg.conc_log_param('��v�E�t���b�N�X�̌n'
																						,in_accounting_flex_structure,7);
		xx01_conc_util_pkg.conc_log_param('�V�[�P���X�h�c',in_sequence_id,8);
		xx01_conc_util_pkg.conc_log_line('=');
--- ********************
--- �N���p�����[�^�Z�b�g
--- ********************
		gn_sequence_id								:=  in_sequence_id;
		gv_book_type_code							:=	iv_book_type_code;
		gn_accounting_flex_structure	:=	in_accounting_flex_structure;
		gv_asset_type_code						:=	iv_asset_type;
		gv_account_periods_from				:=	iv_account_periods_from;
		gv_account_periods_to					:=	iv_account_periods_to;
		gv_account_unit_code_from			:=	iv_account_unit_code_from;
		gv_account_unit_code_to				:=	iv_account_unit_code_to;
--- ********************
--- �R���J�����g��������
--- ********************
		initialize_proc(	lv_errbuf,
											ln_retcode
											);
		IF	ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
--- ****************
--- �C�����𒊏o����
--- ****************
		get_adjustment(lv_errbuf,
									 ln_retcode);
		IF	ln_retcode != 0 THEN
				RAISE USER_EXPT;
		END IF;
--- ************************
--- �R���J�����g�I�����O�o��
--- ************************
		xx01_conc_util_pkg.conc_log_put( '���o���� ' || gn_count || ' ��');
		xx01_conc_util_pkg.conc_log_end(fnd_global.conc_request_id);
--- ********
--- ��O����
--- ********
	EXCEPTION
	WHEN	USER_EXPT	THEN
				ROLLBACK;
				errbuf	:= lv_errbuf;
				retcode	:= 2;
  			xx01_conc_util_pkg.conc_log_param( 'errbuf', errbuf );
	WHEN	OTHERS	THEN
				ROLLBACK;
				errbuf	:= xx01_conc_util_pkg.get_message_others
																( 'XX01_ASSET_INCRE_PKG.MAIN_PROC' ) ;
				retcode	:= 2 ;
  			xx01_conc_util_pkg.conc_log_param( 'errbuf', errbuf );
	END	main_proc;

END;
/
