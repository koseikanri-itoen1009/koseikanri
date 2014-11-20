CREATE OR REPLACE PACKAGE BODY xxwsh930001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930001c(body)
 * Description      : ���Y����(�����A�z��)
 * MD.050           : �o�ׁE�ړ��C���^�t�F�[�X         T_MD050_BPO_930
 * MD.070           : �O���q�ɓ��o�Ɏ��уC���^�t�F�[�X T_MD070_BPO_93A
 * Version          : 1.14
 *
 * Program List
 * ------------------------------------ -------------------------------------------------
 *  Name                                Description
 * ------------------------------------ -------------------------------------------------
 *  set_deliveryno_unit_errflg          �w��z��No�AEOS�f�[�^��ʒP�ʂ�flag=1���Z�b�g���� �v���V�[�W��
 *  set_header_unit_reserveflg          �w�b�_�P��(�z��No�A�˗�No�E�ړ��ԍ��AEOS�f�[�^���)��flag=1���Z�b�g���� �v���V�[�W��
 *  set_movreqno_unit_reserveflg        �w��ړ�/�˗�No�P�ʂ�flag=1���Z�b�g���� �v���V�[�W��
 *  master_data_get                     �}�X�^(view)�f�[�^�擾 �v���V�[�W��
 *  upd_line_items_set                  �d�ʗe�Ϗ������ݒ� �v���V�[�W��
 *  ord_results_quantity_set            �󒍎��ѐ��ʂ̐ݒ� �v���V�[�W��
 *  mov_results_quantity_set            �o�׈˗����ѐ��ʂ̐ݒ� �v���V�[�W��
 *  get_freight_charge_type             �^���`�Ԏ擾 �v���V�[�W��
 *  carriers_schedule_inup              �z�Ԕz���v��A�h�I���쐬 �v���V�[�W��
 *  chk_param                           �p�����[�^�`�F�b�N �v���V�[�W�� (A-0)
 *  get_profile                         �v���t�@�C���l�擾 �v���V�[�W�� (A-1)
 *  purge_processing                    �p�[�W���� �v���V�[�W�� (A-2)
 *  get_warehouse_results_info          �O���q�ɓ��o�Ɏ��я�񒊏o �v���V�[�W�� (A-3)
 *  out_warehouse_number_check          �O���q�ɔ��ԃ`�F�b�N �v���V�[�W�� (A-4)
 *  err_chk_delivno                     �G���[�`�F�b�N_�z��No�P�� �v���V�[�W�� (A-5-1)
 *  err_chk_delivno_ordersrcref         �G���[�`�F�b�N_�z��No�󒍃\�[�X�Q�ƒP�� �v���V�[�W��(A-5-2)
 *  err_chk_line                        �G���[�`�F�b�N_���גP�� �v���V�[�W�� (A-5-3)
 *  appropriate_check                   �Ó��`�F�b�N �v���V�[�W�� (A-6)
 *  mov_table_outpout                   �ړ��˗�/�w���A�h�I���o�� �v���V�[�W�� (A-7)
 *  mov_req_instr_head_ins              �ړ��˗�/�w���w�b�_�A�h�I��(�O���q�ɕҏW)�v���V�[�W��(A-7-1)
 *  mov_req_instr_head_upd              �ړ��˗�/�w���w�b�_�A�h�I��(���ьv��ҏW)�v���V�[�W��(A-7-2)
 *  mov_req_instr_head_inup             �ړ��˗�/�w���w�b�_�A�h�I��(���ђ����ҏW)�v���V�[�W��(A-7-3)
 *  mov_req_instr_lines_ins             �ړ��˗�/�w�����׃A�h�I��INSERT �v���V�[�W��(A-7-4)
 *  mov_req_instr_lines_upd             �ړ��˗�/�w�����׃A�h�I��UPDATE �v���V�[�W��(A-7-5)
 *  mov_movlot_detail_ins               �ړ��˗�/�w���f�[�^�ړ����b�g�ڍ�INSERT �v���V�[�W��(A-7-6)
 *  movlot_detail_upd                   �ړ����b�g�ڍ�UPDATE �v���V�[�W��(A-7-7)
 *  order_table_outpout                 �󒍃A�h�I���o�� �v���V�[�W�� (A-8)
 *  order_headers_upd                   �󒍃w�b�_�A�h�I��(���ьv��ҏW) �v���V�[�W�� (A-8-1)
 *  order_headers_ins                   �󒍃w�b�_�A�h�I��(�O���q�ɕҏW) �v���V�[�W�� (A-8-2)
 *  order_headers_inup                  �󒍃w�b�_�A�h�I��(���ђ������ҏW) �v���V�[�W�� (A-8-3,4)
 *  order_lines_upd                     �󒍖��׃A�h�I��UPDATE �v���V�[�W��(A-8-5)
 *  order_lines_ins                     �󒍖��׃A�h�I��INSERT �v���V�[�W��(A-8-6)
 *  order_movlot_detail_ins             �󒍃f�[�^�ړ����b�g�ڍ�INSERT �v���V�[�W��(A-8-7)
 *  order_movlot_detail_up              �󒍃f�[�^�ړ����b�g�ڍ�UPDATE �v���V�[�W��(A-8-8)
 *  lot_reversal_prevention_check       ���b�g�t�]�h�~�`�F�b�N �v���V�[�W�� (A-9)
 *  drawing_enable_check                �����\�`�F�b�N �v���V�[�W�� (A-10)
 *  origin_record_delete                ���o�����R�[�h�폜 �v���V�[�W�� (A-11)
 *  status_update                       �X�e�[�^�X�X�V �v���V�[�W�� (A-12)
 *  err_check_delete                    �G���[�������x���ɂ�背�R�[�h�폜�v���V�[�W�� (A-13)
 *  err_output                          �G���[���e�o�̓v���V�[�W�� (A-14)
 *  ins_upd_del_processing              �o�^�X�V�폜�����v���V�[�W�� (A-15)
 *  ship_results_regist_process         �o�׎��ѓo�^�����v���V�[�W�� (A-16)
 *  move_results_regist_process         ���o�Ɏ��ѓo�^�����v���V�[�W�� (A-17)
 *  submain                             ���C�������v���V�[�W��
 *  main                                �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0  Oracle �V�� �r��  ����쐬
 *  2008/05/19    1.1  Oracle �{�c ���j  �w�E����Seq262�C263�C
 *  2008/06/05    1.2  Oracle �{�c ���j  �����e�X�g���{�ɔ������C
 *  2008/06/13    1.3  Oracle �{�c ���j  �����e�X�g���{�ɔ������C
 *  2008/06/23    1.4  Oracle �{�c ���j  ST�s�#230�Ή�
 *  2008/06/24    1.5  Oracle �{�c ���j  ST�s�#230�Ή�(2)
 *  2008/06/27    1.6  Oracle �{�c ���j  ST�s�#299�Ή�
 *  2008/07/01    1.7  Oracle �{�c ���j  ST�s�#333�Ή�
 *  2008/07/02    1.8  Oracle �{�c ���j  ST�s�#365�Ή�
 *  2008/07/03    1.9  Oracle �{�c ���j  ST�s�#392�Ή�
 *  2008/07/04    1.10 Oracle �{�c ���j  TE080�w�E����#26�Ή�
 *  2008/07/07    1.11 Oracle �{�c ���j  TE080�w�E����#1�Ή�
 *  2008/07/11    1.12 Oracle �{�c ���j  TE080�w�E����400#72�Ή�
 *                                       TE080�w�E����930#13,17�Ή�
 *                                       ST�s�420-001#195�Ή�
 *                                       ST�s�440-002#374�Ή�
 *                                       �����ύX#168�Ή�
 *                                       T_S_426�Ή�
 *                                       I_S_192�Ή�
 *                                       T_TE110_BPO_280#363�Ή�
 *                                       �ۑ�#32,�����ύX#173,174
 *  2008/08/01    1.13 Oracle �Ŗ� ���\  ��o�א棃}�X�^�`�F�b�N�G���[���b�Z�[�W���ږ��C��
 *  2008/08/06    1.14 Oracle ���c ����  �ő�z���敪�Z�o�֐�(get_max_ship_method)���̓p�����[�^�R�[�h�敪�Q
 *                                       �x���̏ꍇ�̐ݒ�l�s��(��������11�Ȃ̂�9���Z�b�g���Ă���)
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) :=',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- �I���X�e�[�^�X
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  parameter_expt      EXCEPTION;     -- �p�����[�^��O
  get_prof_expt       EXCEPTION;     -- �v���t�@�C���擾�G���[
  check_lock_expt     EXCEPTION;     -- ���b�N�擾�G���[
  no_data_expt        EXCEPTION;     -- �Ώۏ��Ȃ�
  no_insert_expt      EXCEPTION;     -- �����ΏۊO
  no_record_expt      EXCEPTION;     -- �������R�[�h�擾�G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxwsh930001c';     -- �p�b�P�[�W��
  gv_msg_kbn              CONSTANT VARCHAR2(100) := 'XXWSH';            -- �A�v���P�[�V�����Z�k��
--
  -- ���b�Z�[�W�ԍ�
  -- �K�{�p�����[�^�����̓��b�Z�[�W
  gv_msg_93a_001                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13101';
  -- �v���t�@�C���擾�G���[���b�Z�[�W
  gv_msg_93a_002                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13102';
  -- ���b�N�G���[���b�Z�[�W
  gv_msg_93a_003                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13103';
  -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  gv_msg_93a_004                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13104';
  -- ����˗�No/�ړ�No��ɓ���i�ڂ��������݃G���[���b�Z�[�W
  gv_msg_93a_005                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13105';
  -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)�񑶍݃G���[���b�Z�[�W
  gv_msg_93a_006                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13106';
  -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�񑶍݃G���[���b�Z�[�W
  gv_msg_93a_007                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13107';
  -- �Ɩ���ʃX�e�[�^�X�`�F�b�N�G���[���b�Z�[�W
  gv_msg_93a_008                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13108';
  -- ����z��No���R�[�h�l�`�F�b�N�G���[���b�Z�[�W
  gv_msg_93a_009                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13109';
  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
  gv_msg_93a_010                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13110';
  -- �g�����Ǝw���`�F�b�N�G���[���b�Z�[�W
  gv_msg_93a_011                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13111';
  -- �d�ʗe�ϋ敪���݃G���[���b�Z�[�W
  gv_msg_93a_012                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13112';
  -- ���i�敪���݃G���[���b�Z�[�W
  gv_msg_93a_013                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13113';
  -- �i�ڋ敪���݃G���[���b�Z�[�W
  gv_msg_93a_014                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13114';
  -- �L�����z�m��敪�m��G���[���b�Z�[�W
  gv_msg_93a_015                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13115';
  -- �݌ɉ�v����CLOSE�G���[
  gv_msg_93a_016                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13116';
  -- �Ó��`�F�b�N�G���[���b�Z�[�W(�ړ��\����ьx��)
  gv_msg_93a_017                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13117';
  -- �Ó��`�F�b�N�G���[���b�Z�[�W(�o�׎x���\����ьx��)
  gv_msg_93a_018                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13118';
  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
  gv_msg_93a_019                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13119';
  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���b�g�x��)
  gv_msg_93a_020                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13120';
  -- �Ó��`�F�b�N�G���[���b�Z�[�W(�i���x��)
  gv_msg_93a_021                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13121';
  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ʍ��ڃG���[)
  gv_msg_93a_022                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13122';
  -- �ő�p���b�g�����Z�o�֐��G���[
  gv_msg_93a_025                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13125';
  -- ���b�g�t�]�h�~�`�F�b�N�G���[���b�Z�[�W
  gv_msg_93a_026                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13126';
  -- ���b�g�t�]�h�~�`�F�b�N�����G���[
  gv_msg_93a_027                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13127';
  -- �����\�`�F�b�N�G���[���b�Z�[�W
  gv_msg_93a_028                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13128';
  -- �o�׎��ѓo�^�����G���[���b�Z�[�W
  gv_msg_93a_029                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13129';
  -- ���o�Ɏ��ѓo�^�����G���[���b�Z�[�W
  gv_msg_93a_030                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13130';
  -- ���̓p�����[�^(�����Ώۏ��)
  gv_msg_93a_031                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13131';
  -- ���̓p�����[�^(�񍐕���)
  gv_msg_93a_032                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13132';
  -- ���̓p�����[�^(�Ώۑq��)
  gv_msg_93a_033                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13133';
  -- ��������(���͌���)
  gv_msg_93a_034                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13134';
  -- ��������(�V�K�󒍍쐬����)
  gv_msg_93a_035                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13135';
  -- ��������(�����󒍍쐬����)
  gv_msg_93a_036                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13136';
  -- ��������(�����񌏐�)
  gv_msg_93a_037                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13137';
  -- ��������(�ُ팏��)
  gv_msg_93a_038                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13138';
  -- ��������(�x������)
  gv_msg_93a_039                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13139';
  -- �e�������ʌ���
  gv_msg_93a_040                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13140';
  -- ���i�敪���݃G���[
  gv_msg_93a_142                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13142';
  -- �������G���[���b�Z�[�W
  gv_msg_93a_143                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13143';
  -- �o�Ɍ������s�G���[���b�Z�[�W
  gv_msg_93a_144                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13144';
  -- ���b�g�Ǘ��i�̃��b�g���ʖ��ݒ�G���[���b�Z�[�W
  gv_msg_93a_146                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13146';
  -- �^���`�Ԏ擾�x�����b�Z�[�W
  gv_msg_93a_147                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13147';
  -- �z��No-�^���敪�g�����G���[���b�Z�[�W
  gv_msg_93a_148                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13148';
  -- ���b�g�Ǘ��i�̕K�{���ږ��ݒ�G���[
  gv_msg_93a_149                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13149';
  -- ���b�g�}�X�^�擾�G���[
  gv_msg_93a_150                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13150';
  -- ���b�g�}�X�^�擾�������G���[
  gv_msg_93a_151                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13151';
  -- �ő�z���敪�Z�o�֐��G���[
  gv_msg_93a_152                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13152';
  -- �z��No-�˗�/�ړ�No�֘A�G���[���b�Z�[�W
  gv_msg_93a_153                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13153';
  -- ���ьv��^�����s�G���[���b�Z�[�W
  gv_msg_93a_154                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13154';
  -- �d�ʗe�Ϗ������X�V�֐��G���[���b�Z�[�W
  gv_msg_93a_308                 CONSTANT VARCHAR2(15) := 'APP-XXWSH-13308';
  -- �o�f�ł̃R���J�����g�Ăяo���G���[
  gv_msg_93a_102                 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10135';
  -- �o�f�ł̃R���J�����g�ҋ@�G���[
  gv_msg_93a_103                 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10136';
  -- �P�[�X�����G���[
  gv_msg_93a_604                 CONSTANT VARCHAR2(15) := 'APP-XXCMN-10604';
--
  -- �g�[�N��
  gv_tkn_cnt                     CONSTANT VARCHAR2(3)  := 'CNT';         -- �J�E���g�g�[�N��
  gv_tkn_input_item              CONSTANT VARCHAR2(10) := 'INPUT_ITEM';  -- �p�����[�^�l�g�[�N��
  gv_tkn_item                    CONSTANT VARCHAR2(4)  := 'ITEM';        -- ���ڒl�g�[�N��
  gv_prof_token                  CONSTANT VARCHAR2(9)  := 'PROF_NAME';   -- �v���t�@�C�����g�[�N��
  gv_table_token                 CONSTANT VARCHAR2(10) := 'TABLE_NAME';  -- �e�[�u�����g�[�N��
  gv_date_token                  CONSTANT VARCHAR2(10) := 'PARA_DATE';   -- ���t���g�[�N��
  gv_param1_token                CONSTANT VARCHAR2(6)  := 'PARAM1';      -- �Q�ƒl�g�[�N��
  gv_param2_token                CONSTANT VARCHAR2(6)  := 'PARAM2';      -- �Q�ƒl�g�[�N��
  gv_param3_token                CONSTANT VARCHAR2(6)  := 'PARAM3';      -- �Q�ƒl�g�[�N��
  gv_param4_token                CONSTANT VARCHAR2(6)  := 'PARAM4';      -- �Q�ƒl�g�[�N��
  gv_param5_token                CONSTANT VARCHAR2(6)  := 'PARAM5';      -- �Q�ƒl�g�[�N��
  gv_param6_token                CONSTANT VARCHAR2(6)  := 'PARAM6';      -- �Q�ƒl�g�[�N��
  gv_param7_token                CONSTANT VARCHAR2(6)  := 'PARAM7';      -- �Q�ƒl�g�[�N��
  gv_param8_token                CONSTANT VARCHAR2(6)  := 'PARAM8';      -- �Q�ƒl�g�[�N��
  gv_param9_token                CONSTANT VARCHAR2(6)  := 'PARAM9';      -- �Q�ƒl�g�[�N��
  gv_param10_token               CONSTANT VARCHAR2(7)  := 'PARAM10';     -- �Q�ƒl�g�[�N��
  gv_param11_token               CONSTANT VARCHAR2(7)  := 'PARAM11';     -- �Q�ƒl�g�[�N��
  gv_param1_token01_nm           CONSTANT VARCHAR2(30) := '�p���b�g�������';
  gv_param1_token02_nm           CONSTANT VARCHAR2(30) := '�p���b�g�g�p����';
  gv_param1_token03_nm           CONSTANT VARCHAR2(30) := '�o�׎��ѐ���';
  gv_param1_token04_nm           CONSTANT VARCHAR2(30) := '���󐔗�(�C���^�t�F�[�X�p)';
  gv_param1_token05_nm           CONSTANT VARCHAR2(30) := '�o�׌�';
  gv_param1_token06_nm           CONSTANT VARCHAR2(30) := '�^���Ǝ�';
  gv_param1_token07_nm           CONSTANT VARCHAR2(30) := '�󒍕i��';
  gv_param1_token08_nm           CONSTANT VARCHAR2(30) := '���ɑq��';
  gv_param1_token09_nm           CONSTANT VARCHAR2(30) := '�z���敪';
--********** 2008/08/01 ********** ADD    START ***
  gv_param1_token10_nm           CONSTANT VARCHAR2(30) := '�o�א�';
--********** 2008/08/01 ********** ADD    END   ***
  gv_table_token01_nm            CONSTANT VARCHAR2(30) := '�󒍃w�b�_(�A�h�I��)';
  gv_table_token02_nm            CONSTANT VARCHAR2(30) := '�ړ��˗�/�w���w�b�_(�A�h�I��)';
  gv_date_para_1                 CONSTANT VARCHAR2(6)  := '�o�ד�';
  gv_date_para_2                 CONSTANT VARCHAR2(6)  := '���ד�';
  gv_request_no_token            CONSTANT VARCHAR2(10) := 'REQUEST_NO';
  gv_item_no_token               CONSTANT VARCHAR2(7)  := 'ITEM_NO';
--
  -- ���b�Z�[�WPARAM1�F����������
  gv_c_file_id_name             CONSTANT VARCHAR2(50)   := '�󒍃w�b�_�X�V�쐬����(���ьv��)';
--
--********** 2008/07/07 ********** ADD    START ***
  -- �V�K�p�̌�������
  gv_ord_new_shikyu_cnt_nm       CONSTANT VARCHAR2(50) := '�V�K�󒍁i�x���j�쐬';
  gv_ord_new_syukka_cnt_nm       CONSTANT VARCHAR2(50) := '�V�K�󒍁i�o�ׁj�쐬';
  gv_mov_new_cnt_nm              CONSTANT VARCHAR2(50) := '�V�K�ړ��@�@�@�@�쐬';
  -- �����p�̌�������
  gv_ord_correct_shikyu_cnt_nm   CONSTANT VARCHAR2(50) := '�����󒍁i�x���j�쐬';
  gv_ord_correct_syukka_cnt_nm   CONSTANT VARCHAR2(50) := '�����󒍁i�o�ׁj�쐬';
  gv_mov_correct_cnt_nm          CONSTANT VARCHAR2(50) := '�����ړ��@�@�@�@�쐬';
--********** 2008/07/07 ********** ADD    START ***
--
--********** 2008/07/07 ********** DELETE START ***
--*  -- �󒍃w�b�_
--*  gv_ord_h_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '�󒍃w�b�_�X�V�쐬(���ьv��)';
--*  gv_ord_h_ins_cnt_nm     CONSTANT VARCHAR2(50) := '�󒍃w�b�_�o�^�쐬(�O���q�ɔ���)';
--*  gv_ord_h_upd_y_cnt_nm   CONSTANT VARCHAR2(50) := '�󒍃w�b�_�X�V�쐬(���ђ���)';
--*  -- �󒍖���
--*  gv_ord_l_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '�󒍖��׍X�V�쐬(���ьv��i�ڂ���)';
--*  gv_ord_l_ins_n_cnt_nm   CONSTANT VARCHAR2(50) := '�󒍖��דo�^�쐬(���ьv��i�ڂȂ�)';
--*  gv_ord_l_ins_cnt_nm     CONSTANT VARCHAR2(50) := '�󒍖��דo�^�쐬(�O���q�ɔ���)';
--*  gv_ord_l_ins_y_cnt_nm   CONSTANT VARCHAR2(50) := '�󒍖��דo�^�쐬(���яC��)';
--*  -- ���b�g�ڍ�
--*  gv_ord_mov_ins_n_cnt_nm CONSTANT VARCHAR2(50) := '���b�g�ڍאV�K�쐬(��_���ьv��)';
--*  gv_ord_mov_ins_cnt_nm   CONSTANT VARCHAR2(50) := '���b�g�ڍאV�K�쐬(��_�O���q�ɔ���)';
--*  gv_ord_mov_ins_y_cnt_nm CONSTANT VARCHAR2(50) := '���b�g�ڍאV�K�쐬(��_���яC��)';
--*  -- �ړ��˗�/�w���w�b�_
--*  gv_mov_h_ins_cnt_nm     CONSTANT VARCHAR2(50) := '�ړ��˗�/�w���w�b�_�o�^�쐬(�O���q�ɔ���)';
--*  gv_mov_h_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '�ړ��˗�/�w���w�b�_�X�V�쐬(���ьv��)';
--*  gv_mov_h_upd_y_cnt_nm   CONSTANT VARCHAR2(50) := '�ړ��˗�/�w���w�b�_�X�V�쐬(���ђ���)';
--*  -- �ړ��˗�/�w������
--*  gv_mov_l_upd_n_cnt_nm   CONSTANT VARCHAR2(50) := '�ړ��˗�/�w�����׍X�V�쐬(���ьv��i�ڂ���)';
--*  gv_mov_l_ins_n_cnt_nm   CONSTANT VARCHAR2(50) := '�ړ��˗�/�w�����דo�^�쐬(���ьv��i�ڂȂ�)';
--*  gv_mov_l_ins_cnt_nm     CONSTANT VARCHAR2(50) := '�ړ��˗�/�w�����דo�^�쐬(�O���q�ɔ���)';
--*  gv_mov_l_upd_y_cnt_nm   CONSTANT VARCHAR2(50) := '�ړ��˗�/�w�����דo�^�쐬(�������i�ڂ���)';
--*  gv_mov_l_ins_y_cnt_nm   CONSTANT VARCHAR2(50) := '�ړ��˗�/�w�����דo�^�쐬(�������i�ڂȂ�)';
--*  -- ���b�g�ڍ�
--*  gv_mov_mov_ins_n_cnt_nm CONSTANT VARCHAR2(50) := '���b�g�ڍאV�K�쐬(�ړ��˗�_���ьv��)';
--*  gv_mov_mov_ins_cnt_nm   CONSTANT VARCHAR2(50) := '���b�g�ڍאV�K�쐬(�ړ��˗�_�O���q�ɔ���)';
--*  gv_mov_mov_upd_y_cnt_nm CONSTANT VARCHAR2(50) := '���b�g�ڍאV�K�쐬(�ړ��˗�_�������b�g����)';
--*  gv_mov_mov_ins_y_cnt_nm CONSTANT VARCHAR2(50) := '���b�g�ڍאV�K�쐬(�ړ��˗�_�������b�g�Ȃ�)';
--*  -- IF�w�b�_�E����
--*  gv_header_cnt_nm        CONSTANT VARCHAR2(50) := '�o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�폜';
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** MODIFY START ***
--*  gv_lines_cnt_nm         CONSTANT VARCHAR2(50) := '�o�׈˗��C���^�t�F�[�X����(�A�h�I��)�폜';
  gv_lines_cnt_nm         CONSTANT VARCHAR2(50) := '�o�׈˗��C���^�t�F�[�X�p�[�W�폜';
--********** 2008/07/07 ********** MODIFY END   ***
  --
--********** 2008/07/07 ********** MODIFY START ***
--*  -- �G���[�f�[�^�폜����
--*  gv_err_data_del_cnt_nm         CONSTANT VARCHAR2(50) := '�G���[�f�[�^�폜';
  -- �o�׈˗��C���^�t�F�[�X�G���[�폜
  gv_err_data_del_cnt_nm         CONSTANT VARCHAR2(50) := '�o�׈˗��C���^�t�F�[�X�G���[�폜';
--********** 2008/07/07 ********** MODIFY END   ***
--
  gv_err_code_token    CONSTANT VARCHAR2(8)  := 'ERR_CODE'; -- �V�X�e���G���[�R�[�h�g�[�N��
  gv_err_msg_token     CONSTANT VARCHAR2(7)  := 'ERR_MSG';  -- �V�X�e���G���[���b�Z�[�W�g�[�N��
  -- �v���t�@�C��(�p�[�W��������)
  gn_purge_period      NUMBER; -- �v���t�@�C���p�[�W��������
  gv_purge_period_930  CONSTANT VARCHAR2(22) := 'XXWSH_PURGE_PERIOD_930';
  gv_parge_period_jp   CONSTANT VARCHAR2(50) := 'XXWSH:�p�[�W��������(���o�Ɏ��уC���^�t�F�[�X)';
  -- �v���t�@�C��(�}�X�^�g�DID)
  gv_master_org_id               VARCHAR2(100);
  gv_master_org_id_type          CONSTANT VARCHAR2(19) := 'XXCMN_MASTER_ORG_ID';
  gv_master_org_id_jp            CONSTANT VARCHAR2(24) := 'XXCMN:�}�X�^�g�D';
  -- �p�[�W����
  gv_if_table_jp                 CONSTANT VARCHAR2(18) := '�o�׈˗�IF�e�[�u��';
  -- �󒍃^�C�v
  order_type_name_001            CONSTANT VARCHAR2(30) := '�U�֏o��';
  -- �N�C�b�N�R�[�h�FEOS�f�[�^���
  gv_eos_data_type               CONSTANT VARCHAR2(9)  := 'XXCMN_D17';
  gv_eos_data_cd_200             CONSTANT VARCHAR2(3)  := '200';  -- 200 �L���o�ו�
  gv_eos_data_cd_210             CONSTANT VARCHAR2(3)  := '210';  -- 210 ���_�o�׊m���
  gv_eos_data_cd_215             CONSTANT VARCHAR2(3)  := '215';  -- 215 ���o�׊m���
  gv_eos_data_cd_220             CONSTANT VARCHAR2(3)  := '220';  -- 220 �ړ��o�Ɋm���
  gv_eos_data_cd_230             CONSTANT VARCHAR2(3)  := '230';  -- 230 �ړ����Ɋm���
  -- �N�C�b�N�R�[�h�F�L�����z�m��敪
  gv_amount_fix_type             CONSTANT VARCHAR2(22) := 'XXWSH_AMOUNT_FIX_CLASS';
  gv_amount_fix_1                CONSTANT VARCHAR2(1)  := '1';    -- �m��
  gv_amount_fix_2                CONSTANT VARCHAR2(1)  := '2';    -- ���m��
  -- �N�C�b�N�R�[�h�F�X�e�[�^�X(�ړ��X�e�[�^�X)
  gv_mov_status_type             CONSTANT VARCHAR2(17) := 'XXINV_MOVE_STATUS';
  gv_mov_status_01               CONSTANT VARCHAR2(2)  := '01';   -- �˗���
  gv_mov_status_02               CONSTANT VARCHAR2(2)  := '02';   -- �˗���
  gv_mov_status_03               CONSTANT VARCHAR2(2)  := '03';   -- ������
  gv_mov_status_04               CONSTANT VARCHAR2(2)  := '04';   -- �o�ɕ񍐗L
  gv_mov_status_05               CONSTANT VARCHAR2(2)  := '05';   -- ���ɕ񍐗L
  gv_mov_status_06               CONSTANT VARCHAR2(2)  := '06';   -- ���o�ɕ񍐗L
  gv_mov_status_99               CONSTANT VARCHAR2(2)  := '99';   -- ���
  -- �N�C�b�N�R�[�h�F�X�e�[�^�X(�o�׈˗�/�x���˗��X�e�[�^�X)
  gv_req_status_type             CONSTANT VARCHAR2(25) := 'XXWSH_TRANSACTION_STATUS';
  gv_req_status_01               CONSTANT VARCHAR2(2)  := '01';   -- ���͒�
  gv_req_status_02               CONSTANT VARCHAR2(2)  := '02';   -- ���_�m��
  gv_req_status_03               CONSTANT VARCHAR2(2)  := '03';   -- ���ߍς�
  gv_req_status_04               CONSTANT VARCHAR2(2)  := '04';   -- �o�׎��ьv���
  gv_req_status_05               CONSTANT VARCHAR2(2)  := '05';   -- ���͒�
  gv_req_status_06               CONSTANT VARCHAR2(2)  := '06';   -- ���͊���
  gv_req_status_07               CONSTANT VARCHAR2(2)  := '07';   -- ��̍�
  gv_req_status_08               CONSTANT VARCHAR2(2)  := '08';   -- �o�׎��ьv���
  gv_req_status_99               CONSTANT VARCHAR2(2)  := '99';   -- ���
  -- �N�C�b�N�R�[�h�F�ʒm�X�e�[�^�X(�O��ʒm�X�e�[�^�X)
  gv_notif_status_type           CONSTANT VARCHAR2(18) := 'XXWSH_NOTIF_STATUS';
  gv_notif_status_10             CONSTANT VARCHAR2(2)  := '10';   -- ���ʒm
  gv_notif_status_20             CONSTANT VARCHAR2(2)  := '20';   -- �Ēʒm�v
  gv_notif_status_40             CONSTANT VARCHAR2(2)  := '40';   -- �m��ʒm��
  -- �i�ڋ敪
  gv_item_kbn_cd_1                CONSTANT VARCHAR2(1)  := '1';   -- ����
  gv_item_kbn_cd_4                CONSTANT VARCHAR2(1)  := '4';   -- �����i
  gv_item_kbn_cd_5                CONSTANT VARCHAR2(1)  := '5';   -- ���i
  -- ���i�敪
  gv_prod_kbn_cd_1               CONSTANT VARCHAR2(1)  := '1';    -- ���[�t
  gv_prod_kbn_cd_2               CONSTANT VARCHAR2(1)  := '2';    -- �h�����N
  -- OPM�i�ڃ}�X�^.���b�g�Ǘ��敪
  gv_lotkr_kbn_cd_0              CONSTANT VARCHAR2(1)  := '0';    -- ��(���b�g�Ǘ��i�ΏۊO)
  gv_lotkr_kbn_cd_1              CONSTANT VARCHAR2(1)  := '1';    -- �L(���b�g�Ǘ��i)
  -- �N�C�b�N�R�[�h:���b�g�X�e�[�^�X
  gv_lot_status_type             CONSTANT VARCHAR2(16) := 'XXCMN_LOT_STATUS';
  gv_lot_status_01               CONSTANT VARCHAR2(2)  := '10';   -- ������
  gv_lot_status_02               CONSTANT VARCHAR2(2)  := '20';   -- �ꕔ���i
  gv_lot_status_03               CONSTANT VARCHAR2(2)  := '30';   -- �����t�Ǖi
  gv_lot_status_04               CONSTANT VARCHAR2(2)  := '40';   -- �[�i�N�x�؂�
  gv_lot_status_05               CONSTANT VARCHAR2(2)  := '50';   -- ���i
  gv_lot_status_06               CONSTANT VARCHAR2(2)  := '60';   -- �s���i
  gv_lot_status_07               CONSTANT VARCHAR2(2)  := '70';   -- �ۗ�
  -- �N�C�b�N�R�[�h�F�ړ��^�C�v
  gv_move_type                   CONSTANT VARCHAR2(15) := 'XXINV_MOVE_TYPE';
  gv_move_type_1                 CONSTANT VARCHAR2(1)  := '1';    -- �ϑ�����
  gv_move_type_2                 CONSTANT VARCHAR2(1)  := '2';    -- �ϑ��Ȃ�
  -- �N�C�b�N�R�[�h�F�L���敪
  gv_presence_class_type         CONSTANT VARCHAR2(20) := 'XXINV_PRESENCE_CLASS';
  gv_presence_class_0            CONSTANT VARCHAR2(1)  := '0';    -- ��
  gv_presence_class_1            CONSTANT VARCHAR2(1)  := '1';    -- �L
  -- �N�C�b�N�R�[�h�F�Ώ�_�ΏۊO�敪
  gv_include_exclude_type        CONSTANT VARCHAR2(21) := 'XXCMN_INCLUDE_EXCLUDE';
  gv_include_exclude_0           CONSTANT VARCHAR2(1)  := '0';    -- �ΏۊO
  gv_include_exclude_1           CONSTANT VARCHAR2(1)  := '1';    -- �Ώ�
  -- �N�C�b�N�R�[�h�F�z���敪
  gv_ship_method_type            CONSTANT VARCHAR2(17) := 'XXCMN_SHIP_METHOD';
  gv_ship_method_11              CONSTANT VARCHAR2(2)  := '11';   -- �����a
  gv_ship_method_12              CONSTANT VARCHAR2(2)  := '12';   -- �����`
  gv_ship_method_13              CONSTANT VARCHAR2(2)  := '13';   -- ���^
  gv_ship_method_14              CONSTANT VARCHAR2(2)  := '14';   -- ���^����
  gv_ship_method_21              CONSTANT VARCHAR2(2)  := '21';   -- �S�Ԏ�
  gv_ship_method_22              CONSTANT VARCHAR2(2)  := '22';   -- �S�Ԏԍ���
  gv_ship_method_31              CONSTANT VARCHAR2(2)  := '31';   -- ���^��
  gv_ship_method_32              CONSTANT VARCHAR2(2)  := '32';   -- ���^�ԍ���
  gv_ship_method_41              CONSTANT VARCHAR2(2)  := '41';   -- ��^��
  gv_ship_method_42              CONSTANT VARCHAR2(2)  := '42';   -- ��^�ԍ���
  gv_ship_method_51              CONSTANT VARCHAR2(2)  := '51';   -- ���Ԏ�
  gv_ship_method_52              CONSTANT VARCHAR2(2)  := '52';   -- ���Ԏԍ���
  gv_ship_method_61              CONSTANT VARCHAR2(2)  := '61';   -- �g���[���[
  gv_ship_method_62              CONSTANT VARCHAR2(2)  := '62';   -- �g���[���[����
  gv_ship_method_81              CONSTANT VARCHAR2(2)  := '81';   -- �R���e�i
  gv_ship_method_82              CONSTANT VARCHAR2(2)  := '82';   -- �C��R���e�i
  gv_ship_method_91              CONSTANT VARCHAR2(2)  := '91';   -- ����ԗ�
  -- �N�C�b�N�R�[�h�F���׎���
  gv_arrival_time_type           CONSTANT VARCHAR2(18) := 'XXWSH_ARRIVAL_TIME';
  -- �N�C�b�N�R�[�h�F�d�ʗe�ϋ敪
  gv_weight_capacity_class_type  CONSTANT VARCHAR2(27) := 'XXCMN_WEIGHT_CAPACITY_CLASS';
  gv_weight_capacity_class_1     CONSTANT VARCHAR2(1)  := '1';    -- �d��
  gv_weight_capacity_class_2     CONSTANT VARCHAR2(1)  := '2';    -- �e��
  -- �N�C�b�N�R�[�h�FYES_NO�敪
  gv_yesno_type                  CONSTANT VARCHAR2(27) := 'XXCMN_YESNO';
  gv_yesno_n                     CONSTANT VARCHAR2(27) := 'N';
  gv_yesno_y                     CONSTANT VARCHAR2(27) := 'Y';
  -- �N�C�b�N�R�[�h�F�����^�C�v
  gv_document_type               CONSTANT VARCHAR2(19) := 'XXINV_DOCUMENT_TYPE';
  gv_document_type_10            CONSTANT VARCHAR2(2)  := '10';   -- �o�׈˗�
  gv_document_type_20            CONSTANT VARCHAR2(2)  := '20';   -- �ړ�
  gv_document_type_30            CONSTANT VARCHAR2(2)  := '30';   -- �x���w��
  gv_document_type_40            CONSTANT VARCHAR2(2)  := '40';   -- ���Y�w��
  gv_document_type_50            CONSTANT VARCHAR2(2)  := '50';   -- ����
  -- �N�C�b�N�R�[�h�F���R�[�h�^�C�v
  gv_record_type                 CONSTANT VARCHAR2(19) := 'XXINV_RECORD_TYPE';
  gv_record_type_10              CONSTANT VARCHAR2(2)  := '10';   -- �w��
  gv_record_type_20              CONSTANT VARCHAR2(2)  := '20';   -- �o�Ɏ���
  gv_record_type_30              CONSTANT VARCHAR2(2)  := '30';   -- ���Ɏ���
  gv_record_type_40              CONSTANT VARCHAR2(2)  := '40';   -- ������
  -- �N�C�b�N�R�[�h�F���i���ʋ敪
  gv_product_class_type          CONSTANT VARCHAR2(19) := 'XXINV_PRODUCT_CLASS';
  gv_product_class_1             CONSTANT VARCHAR2(1)  := '1';    -- ���i
  gv_product_class_2             CONSTANT VARCHAR2(1)  := '2';    -- ���i�ȊO
--
  gv_reserved_status             CONSTANT VARCHAR2(1)  := '1';    -- �X�e�[�^�X�F�ۗ�
  gv_flg_on                      CONSTANT VARCHAR2(1)  := '1';    -- �t���OON
  gv_flg_off                     CONSTANT VARCHAR2(1)  := '0';    -- �t���OOFF
--
  gv_err_class                   CONSTANT VARCHAR2(1)  := '1';    -- �G���[����
  gv_reserved_class              CONSTANT VARCHAR2(1)  := '0';    -- �ۗ�����
  gv_logonly_class               CONSTANT VARCHAR2(1)  := '9';    -- ���O�̂ݏo��
--
  -- VIEW�X�e�[�^�X
  gv_view_status                 CONSTANT VARCHAR2(1)  := 'A';    -- �L��
  gv_view_disable                CONSTANT VARCHAR2(1)  := '1';    -- ����
  gn_view_disable                CONSTANT NUMBER(1)    := 1;      -- ����
--
  gv_code_class_01               CONSTANT VARCHAR2(2)  := '1';    -- ���_
  gv_code_class_04               CONSTANT VARCHAR2(2)  := '4';    -- �q��
  gv_code_class_09               CONSTANT VARCHAR2(2)  := '9';    -- �z����
  gv_code_class_11               CONSTANT VARCHAR2(2)  := '11';   -- �x����
--
  gv_prev_deliv_no_zero          CONSTANT VARCHAR2(1)  := '0';    -- �O��z��No
--
  gv_shipping_class_01           CONSTANT VARCHAR2(10)  := '�o�׈˗�';
  gv_shipping_class_08           CONSTANT VARCHAR2(10)  := '���o��';
  -- ���b�g�t�]�������
  gv_lot_biz_class_2             CONSTANT VARCHAR2(1)  := '2';   -- �o�ׂ̎��ьv��
  gv_lot_biz_class_6             CONSTANT VARCHAR2(2)  := '6';   -- �ړ��̎��ьv��
  -- �d�ʗe�Ϗ������X�V�֐� �Ɩ����
  gv_biz_type_1                  CONSTANT VARCHAR2(1)  := '1';   -- �Ɩ����:1�o��
  gv_biz_type_2                  CONSTANT VARCHAR2(1)  := '2';   -- �Ɩ����:2�x��
  gv_biz_type_3                  CONSTANT VARCHAR2(1)  := '3';   -- �Ɩ����:3�ړ�
  -- ���t�`�F�b�N�p�^�[��
  gv_date_chk_0                  CONSTANT VARCHAR2(1)  := '0';   -- ����
  gv_date_chk_1                  CONSTANT VARCHAR2(1)  := '1';   -- �o�ד��G���[
  gv_date_chk_2                  CONSTANT VARCHAR2(1)  := '2';   -- ���ד��G���[
  gv_date_chk_3                  CONSTANT VARCHAR2(1)  := '3';   -- �o�ד�/���ד��G���[
  -- �����f�[�^�����p�^�[��
  gv_cnt_kbn_1                   CONSTANT VARCHAR2(1)  := '1';   -- �w���i��=���ѕi��
  gv_cnt_kbn_2                   CONSTANT VARCHAR2(1)  := '2';   -- �w���i�ځ����ѕi��
  gv_cnt_kbn_3                   CONSTANT VARCHAR2(1)  := '3';   -- �O���q��(�w���Ȃ�)
  gv_cnt_kbn_4                   CONSTANT VARCHAR2(1)  := '4';   -- ���яC��
  gv_cnt_kbn_5                   CONSTANT VARCHAR2(1)  := '5';   -- ���ьv��
  gv_cnt_kbn_6                   CONSTANT VARCHAR2(1)  := '6';   -- �������i�ڂ���
  gv_cnt_kbn_7                   CONSTANT VARCHAR2(1)  := '7';   -- �������i�ڂȂ�
  gv_cnt_kbn_8                   CONSTANT VARCHAR2(1)  := '8';   -- �������b�g����
  gv_cnt_kbn_9                   CONSTANT VARCHAR2(1)  := '9';   -- �������b�g�Ȃ�
  -- �������(�z��)
  gv_carrier_trn_type_1          CONSTANT VARCHAR2(1)  := '1';  -- �o�׈˗�
  gv_carrier_trn_type_2          CONSTANT VARCHAR2(1)  := '2';  -- �x���w��
  gv_carrier_trn_type_3          CONSTANT VARCHAR2(1)  := '3';  -- �ړ��w��
  -- �����z�ԑΏۋ敪
  gv_lv_auto_process_type_0      CONSTANT VARCHAR2(1)  := '0';  -- �ΏۊO
  -- ���ڎ��
  gv_mixed_type_1                CONSTANT VARCHAR2(1)  := '1';  -- �W��
  -- �^���`��
  gv_frt_chrg_type_set           CONSTANT VARCHAR2(1)  := '1';  -- �ݒ�U��
  gv_frt_chrg_type_act           CONSTANT VARCHAR2(1)  := '2';  -- ����U��
--
  gv_delivery_no_null            CONSTANT VARCHAR2(1)  := 'X';  -- �z��No��NULL���̕ϊ�����
--
  gn_normal                      NUMBER := 0;
  gn_warn                        NUMBER := 1;
  gn_error                       NUMBER := -1;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���R�[�h��`�����L�q����
--
  -- �C���^�[�t�F�[�X�e�[�u���̃f�[�^���i�[���郌�R�[�h
  TYPE interface_rec IS RECORD(
    -- IF_H.�o�א�
    party_site_code             xxwsh_shipping_headers_if.party_site_code%TYPE,
    -- IF_H.�^���Ǝ�
    freight_carrier_code        xxwsh_shipping_headers_if.freight_carrier_code%TYPE,
    -- IF_H.�z���敪
    shipping_method_code        xxwsh_shipping_headers_if.shipping_method_code%TYPE,
    -- IF_H.�ڋq����
    cust_po_number              xxwsh_shipping_headers_if.cust_po_number%TYPE,
    -- IF_H.�󒍃\�[�X�Q��
    order_source_ref            xxwsh_shipping_headers_if.order_source_ref%TYPE,
    -- IF_H.�z��No
    delivery_no                 xxwsh_shipping_headers_if.delivery_no%TYPE,
    -- IF_H.�^���敪
    freight_charge_class        xxwsh_shipping_headers_if.filler14%TYPE,
    -- IF_H.�p���b�g�������
    collected_pallet_qty        xxwsh_shipping_headers_if.collected_pallet_qty%TYPE,
    -- IF_H.�o�׌�
    location_code               xxwsh_shipping_headers_if.location_code%TYPE,
    -- IF_H.���׎���FROM
    arrival_time_from           xxwsh_shipping_headers_if.arrival_time_from%TYPE,
    -- IF_H.���׎���TO
    arrival_time_to             xxwsh_shipping_headers_if.arrival_time_to%TYPE,
    -- IF_H.EOS�f�[�^���
    eos_data_type               xxwsh_shipping_headers_if.eos_data_type%TYPE,
    -- IF_H.���ɑq��
    ship_to_location            xxwsh_shipping_headers_if.ship_to_location%TYPE,
    -- IF_H.�o�ד�
    shipped_date                xxwsh_shipping_headers_if.shipped_date%TYPE,
    -- IF_H.���ד�
    arrival_date                xxwsh_shipping_headers_if.arrival_date%TYPE,
    -- IF_H.�󒍃^�C�v
    order_type                  xxwsh_shipping_headers_if.order_type%TYPE,
    -- IF_H.�p���b�g�g�p����
    used_pallet_qty             xxwsh_shipping_headers_if.used_pallet_qty%TYPE,
    -- IF_H.�񍐕���
    report_post_code            xxwsh_shipping_headers_if.report_post_code%TYPE,
    -- IF_L.�w�b�_ID
    header_id                   xxwsh_shipping_lines_if.header_id%TYPE,
    -- IF_L.����ID
    line_id                     xxwsh_shipping_lines_if.line_id%TYPE,
    -- IF_L.���הԍ�
    line_number                 xxwsh_shipping_lines_if.line_number%TYPE,
    -- IF_L.�󒍕i��
    orderd_item_code            xxwsh_shipping_lines_if.orderd_item_code%TYPE,
    -- IF_L.����
    orderd_quantity             xxwsh_shipping_lines_if.orderd_quantity%TYPE,
    -- IF_L.�o�׎��ѐ���
    shiped_quantity             xxwsh_shipping_lines_if.shiped_quantity%TYPE,
    -- IF_L.���Ɏ��ѐ���
    ship_to_quantity            xxwsh_shipping_lines_if.ship_to_quantity%TYPE,
    -- IF_L.���b�gNo
    lot_no                      xxwsh_shipping_lines_if.lot_no%TYPE,
    -- IF_L.������
    designated_production_date  xxwsh_shipping_lines_if.designated_production_date%TYPE,
    -- IF_L.�ܖ�����
    use_by_date                 xxwsh_shipping_lines_if.use_by_date%TYPE,
    -- IF_L.�ŗL�L��
    original_character          xxwsh_shipping_lines_if.original_character%TYPE,
    -- IF_L.���󐔗�
    detailed_quantity           xxwsh_shipping_lines_if.detailed_quantity%TYPE,
    -- OPM�i�ڃJ�e�S���������VIEW4.�i�ڋ敪
    item_kbn_cd                 mtl_categories_b.segment1%TYPE,
    -- OPM�i�ڃJ�e�S���������VIEW4���i�敪
    prod_kbn_cd                 mtl_categories_b.segment1%TYPE,
    -- OPM�i�ڏ��VIEW2.���b�g�Ǘ��敪
    lot_ctl                     xxcmn_item_mst2_v.lot_ctl%TYPE,
    -- OPM�i�ڏ��VIEW2.�d�ʗe�ϋ敪
    weight_capacity_class       xxcmn_item_mst2_v.weight_capacity_class%TYPE,
    -- OPM�i�ڏ��VIEW2.�i��ID
    item_id                     xxcmn_item_mst2_v.item_id%TYPE,
    -- OPM�i�ڏ��VIEW2.�i��
    item_no                     xxcmn_item_mst2_v.item_no%TYPE,
    -- OPM�i�ڏ��VIEW2.�P�[�X����
    num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE,
    -- OPM�i�ڏ��VIEW2.���o�Ɋ��Z�P��
    conv_unit                   xxcmn_item_mst2_v.conv_unit%TYPE,
    -- �P��
    item_um                     xxcmn_item_mst2_v.item_um%TYPE,
    -- OPM�i�ڏ��VIEW2.�q�ɕi��
    whse_item_id                ic_item_mst_b.whse_item_id%TYPE,
    -- �ڋqID
    customer_id                 xxcmn_cust_accounts2_v.party_id%TYPE,
    -- �ڋq
    customer_code               xxcmn_cust_accounts2_v.party_number%TYPE,
    -- �o�א�ID
    deliver_to_id               xxcmn_party_sites.party_site_id%TYPE,
    -- �o�א�_����ID
    result_deliver_to_id        xxcmn_party_sites_v.party_site_id%TYPE,
    -- �^���Ǝ�ID
    career_id                   xxcmn_carriers_v.party_id%TYPE,
    -- �^���Ǝ�_����ID
    result_freight_carrier_id   xxcmn_carriers_v.party_id%TYPE,
    -- ���b�gID
    lot_id                      ic_lots_mst.lot_id%TYPE,
    -- �o�׌�ID
    deliver_from_id             xxcmn_item_locations_v.inventory_location_id%TYPE,
    -- �o�Ɍ�ID
    shipped_locat               xxcmn_item_locations_v.inventory_location_id%TYPE,
    -- ���ɐ�ID
    ship_to_locat               xxcmn_item_locations_v.inventory_location_id%TYPE,
    -- �o�׈����Ώۃt���O
    allow_pickup_flag           xxcmn_item_locations_v.allow_pickup_flag%TYPE,
    -- �Ǌ����_
    base_code                   xxcmn_party_sites.base_code%TYPE,
    -- �d����T�C�gID
    vendor_site_id              xxcmn_vendor_sites2_v.vendor_site_id%TYPE,
    -- �d����ID
    vendor_id                   xxcmn_vendor_sites2_v.vendor_id%TYPE,
    -- �d����T�C�g��
    vendor_site_code            xxcmn_vendor_sites2_v.vendor_site_code%TYPE,
    -- �O���q��flag (1:�O���q�ɂ̏ꍇ�A0�F�O���q�ɂłȂ�)
    out_warehouse_flg           VARCHAR2(1),
    -- �G���[flag (1:�G���[�̏ꍇ�A0:����)
    err_flg                     VARCHAR2(1),
    -- �ۗ�flag (1:�G���[�̏ꍇ�A0:����)
    reserve_flg                 VARCHAR2(1),
    -- ���O�̂ݏo��flag (1:���O�̂ݏo�͂̏ꍇ)
    logonly_flg                 VARCHAR2(1),
    -- ���b�Z�[�W
    message                     VARCHAR2(5000),
    -- INV�i��ID
    inventory_item_id           mtl_system_items_b.inventory_item_id%TYPE,
    -- INV�q�ɕi��ID
    whse_inventory_item_id      mtl_system_items_b.inventory_item_id%TYPE,
    -- INV�q�ɕi��
    whse_inventory_item_no      xxcmn_item_mst2_v.item_no%TYPE,
    -- �ڋq�敪(�o�א�)
    customer_class_code         hz_cust_accounts.customer_class_code%TYPE
  );
--
  -- �ړ����b�g�ڍ�(�A�h�I��)
  TYPE movlot_detail_rec IS RECORD(
     mov_lot_dtl_id          xxinv_mov_lot_details.mov_lot_dtl_id%TYPE            --���b�g�ڍ�ID
    ,mov_line_id             xxinv_mov_lot_details.mov_line_id%TYPE               --����ID
    ,document_type_code      xxinv_mov_lot_details.document_type_code%TYPE        --�����^�C�v
    ,record_type_code        xxinv_mov_lot_details.record_type_code%TYPE          --���R�[�h�^�C�v
    ,item_id                 xxinv_mov_lot_details.item_id%TYPE                   --opm�i��ID
    ,item_code               xxinv_mov_lot_details.item_code%TYPE                 --�i��
    ,lot_id                  xxinv_mov_lot_details.lot_id%TYPE                    --���b�gID
    ,lot_no                  xxinv_mov_lot_details.lot_no%TYPE                    --���b�gNO
    ,actual_date             xxinv_mov_lot_details.actual_date%TYPE               --���ѓ�
    ,actual_quantity         xxinv_mov_lot_details.actual_quantity%TYPE           --���ѐ���
    ,automanual_reserve_class xxinv_mov_lot_details.automanual_reserve_class%TYPE --�����蓮�����敪
  );
--
  -- �ړ��˗�/�w���w�b�_(�A�h�I��)
  TYPE mov_req_instr_h_rec IS RECORD(
     mov_hdr_id                  xxinv_mov_req_instr_headers.mov_hdr_id%TYPE                  --�ړ��w�b�_ID
    ,mov_num                     xxinv_mov_req_instr_headers.mov_num%TYPE                     --�ړ��ԍ�
    ,mov_type                    xxinv_mov_req_instr_headers.mov_type%TYPE                    --�ړ��^�C�v
    ,entered_date                xxinv_mov_req_instr_headers.entered_date%TYPE                --���͓�
    ,instruction_post_code       xxinv_mov_req_instr_headers.instruction_post_code%TYPE       --�w������
    ,status                      xxinv_mov_req_instr_headers.status%TYPE                      --�X�e�[�^�X
    ,notif_status                xxinv_mov_req_instr_headers.notif_status%TYPE                --�ʒm�X�e�[�^�X
    ,shipped_locat_id            xxinv_mov_req_instr_headers.shipped_locat_id%TYPE            --�o�Ɍ�ID
    ,shipped_locat_code          xxinv_mov_req_instr_headers.shipped_locat_code%TYPE          --�o�Ɍ��ۊǏꏊ
    ,ship_to_locat_id            xxinv_mov_req_instr_headers.ship_to_locat_id%TYPE            --���ɐ�ID
    ,ship_to_locat_code          xxinv_mov_req_instr_headers.ship_to_locat_code%TYPE          --���ɐ�ۊǏꏊ
    ,schedule_ship_date          xxinv_mov_req_instr_headers.schedule_ship_date%TYPE          --�o�ɗ\���
    ,schedule_arrival_date       xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE       --���ɗ\���
    ,freight_charge_class        xxinv_mov_req_instr_headers.freight_charge_class%TYPE        --�^���敪
    ,collected_pallet_qty        xxinv_mov_req_instr_headers.collected_pallet_qty%TYPE        --�p���b�g�������
    ,out_pallet_qty              xxinv_mov_req_instr_headers.out_pallet_qty%TYPE              --�p���b�g����(�o)
    ,in_pallet_qty               xxinv_mov_req_instr_headers.in_pallet_qty%TYPE               --�p���b�g����(��)
    ,no_cont_freight_class       xxinv_mov_req_instr_headers.no_cont_freight_class%TYPE       --�_��O�^���敪
    ,delivery_no                 xxinv_mov_req_instr_headers.delivery_no%TYPE                 --�z��no
    ,description                 xxinv_mov_req_instr_headers.description%TYPE                 --�E�v
    ,loading_efficiency_weight   xxinv_mov_req_instr_headers.loading_efficiency_weight%TYPE   --�ύڗ�(�d��)
    ,loading_efficiency_capacity xxinv_mov_req_instr_headers.loading_efficiency_capacity%TYPE --�ύڗ�(�e��)
    ,organization_id             xxinv_mov_req_instr_headers.organization_id%TYPE             --�g�DID
    ,career_id                   xxinv_mov_req_instr_headers.career_id%TYPE                   --�^���Ǝ�_ID
    ,freight_carrier_code        xxinv_mov_req_instr_headers.freight_carrier_code%TYPE        --�^���Ǝ�
    ,shipping_method_code        xxinv_mov_req_instr_headers.shipping_method_code%TYPE        --�z���敪
    ,actual_career_id            xxinv_mov_req_instr_headers.actual_career_id%TYPE            --�^���Ǝ�_ID_����
    ,actual_freight_carrier_code xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE --�^���Ǝ�_����
    ,actual_shipping_method_code xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE --�z���敪_����
    ,arrival_time_from           xxinv_mov_req_instr_headers.arrival_time_from%TYPE           --���׎���from
    ,arrival_time_to             xxinv_mov_req_instr_headers.arrival_time_to%TYPE             --���׎���to
    ,slip_number                 xxinv_mov_req_instr_headers.slip_number%TYPE                 --�����no
    ,sum_quantity                xxinv_mov_req_instr_headers.sum_quantity%TYPE                --���v����
    ,small_quantity              xxinv_mov_req_instr_headers.small_quantity%TYPE              --������
    ,label_quantity              xxinv_mov_req_instr_headers.label_quantity%TYPE              --���x������
    ,based_weight                xxinv_mov_req_instr_headers.based_weight%TYPE                --��{�d��
    ,based_capacity              xxinv_mov_req_instr_headers.based_capacity%TYPE              --��{�e��
    ,sum_weight                  xxinv_mov_req_instr_headers.sum_weight%TYPE                  --�ύڏd�ʍ��v
    ,sum_capacity                xxinv_mov_req_instr_headers.sum_capacity%TYPE                --�ύڗe�ύ��v
    ,sum_pallet_weight           xxinv_mov_req_instr_headers.sum_pallet_weight%TYPE           --���v�p���b�g�d��
    ,pallet_sum_quantity         xxinv_mov_req_instr_headers.pallet_sum_quantity%TYPE         --�p���b�g���v����
    ,mixed_ratio                 xxinv_mov_req_instr_headers.mixed_ratio%TYPE                 --���ڗ�
    ,weight_capacity_class       xxinv_mov_req_instr_headers.weight_capacity_class%TYPE       --�d�ʗe�ϋ敪
    ,actual_ship_date            xxinv_mov_req_instr_headers.actual_ship_date%TYPE            --�o�Ɏ��ѓ�
    ,actual_arrival_date         xxinv_mov_req_instr_headers.actual_arrival_date%TYPE         --���Ɏ��ѓ�
    ,mixed_sign                  xxinv_mov_req_instr_headers.mixed_sign%TYPE                  --���ڋL��
    ,batch_no                    xxinv_mov_req_instr_headers.batch_no%TYPE                    --��zno
    ,item_class                  xxinv_mov_req_instr_headers.item_class%TYPE                  --���i�敪
    ,product_flg                 xxinv_mov_req_instr_headers.product_flg%TYPE                 --���i���ʋ敪
    ,no_instr_actual_class       xxinv_mov_req_instr_headers.no_instr_actual_class%TYPE       --�w���Ȃ����ы敪
    ,comp_actual_flg             xxinv_mov_req_instr_headers.comp_actual_flg%TYPE             --���ьv��σt���O
    ,correct_actual_flg          xxinv_mov_req_instr_headers.correct_actual_flg%TYPE          --���ђ����t���O
    ,prev_notif_status           xxinv_mov_req_instr_headers.prev_notif_status%TYPE           --�O��ʒm�X�e�[�^�X
    ,notif_date                  xxinv_mov_req_instr_headers.notif_date%TYPE                  --�m��ʒm���{����
    ,prev_delivery_no            xxinv_mov_req_instr_headers.prev_delivery_no%TYPE            --�O��z��no
    ,new_modify_flg              xxinv_mov_req_instr_headers.new_modify_flg%TYPE              --�V�K�C���t���O
    ,screen_update_by            xxinv_mov_req_instr_headers.screen_update_by%TYPE            --��ʍX�V��
    ,screen_update_date          xxinv_mov_req_instr_headers.screen_update_date%TYPE          --��ʍX�V����
  );
--
  -- �ړ��˗�/�w������(�A�h�I��)
  TYPE mov_req_instr_l_rec IS RECORD(
    mov_line_id                  xxinv_mov_req_instr_lines.mov_line_id%TYPE                 --�ړ�����ID
    ,mov_hdr_id                  xxinv_mov_req_instr_lines.mov_hdr_id%TYPE                  --�ړ��w�b�_ID
    ,line_number                 xxinv_mov_req_instr_lines.line_number%TYPE                 --���הԍ�
    ,organization_id             xxinv_mov_req_instr_lines.organization_id%TYPE             --�g�DID
    ,item_id                     xxinv_mov_req_instr_lines.item_id%TYPE                     --opm�i��ID
    ,item_code                   xxinv_mov_req_instr_lines.item_code%TYPE                   --�i��
    ,request_qty                 xxinv_mov_req_instr_lines.request_qty%TYPE                 --�˗�����
    ,pallet_quantity             xxinv_mov_req_instr_lines.pallet_quantity%TYPE             --�p���b�g��
    ,layer_quantity              xxinv_mov_req_instr_lines.layer_quantity%TYPE              --�i��
    ,case_quantity               xxinv_mov_req_instr_lines.case_quantity%TYPE               --�P�[�X��
    ,instruct_qty                xxinv_mov_req_instr_lines.instruct_qty%TYPE                --�w������
    ,reserved_quantity           xxinv_mov_req_instr_lines.reserved_quantity%TYPE           --������
    ,uom_code                    xxinv_mov_req_instr_lines.uom_code%TYPE                    --�P��
    ,designated_production_date  xxinv_mov_req_instr_lines.designated_production_date%TYPE  --�w�萻����
    ,pallet_qty                  xxinv_mov_req_instr_lines.pallet_qty%TYPE                  --�p���b�g����
    ,move_num                    xxinv_mov_req_instr_lines.move_num%TYPE                    --�Q�ƈړ��ԍ�
    ,po_num                      xxinv_mov_req_instr_lines.po_num%TYPE                      --�Q�Ɣ����ԍ�
    ,first_instruct_qty          xxinv_mov_req_instr_lines.first_instruct_qty%TYPE          --����w������
    ,shipped_quantity            xxinv_mov_req_instr_lines.shipped_quantity%TYPE            --�o�Ɏ��ѐ���
    ,ship_to_quantity            xxinv_mov_req_instr_lines.ship_to_quantity%TYPE            --���Ɏ��ѐ���
    ,weight                      xxinv_mov_req_instr_lines.weight%TYPE                      --�d��
    ,capacity                    xxinv_mov_req_instr_lines.capacity%TYPE                    --�e��
    ,pallet_weight               xxinv_mov_req_instr_lines.pallet_weight%TYPE               --�p���b�g�d��
    ,automanual_reserve_class    xxinv_mov_req_instr_lines.automanual_reserve_class%TYPE    --�����蓮�����敪
    ,delete_flg                  xxinv_mov_req_instr_lines.delete_flg%TYPE                  --����t���O
    ,warning_date                xxinv_mov_req_instr_lines.warning_date%TYPE                --�x�����t
    ,warning_class               xxinv_mov_req_instr_lines.warning_class%TYPE               --�x���敪
  );
--
  -- �󒍃w�b�_(�A�h�I��)
  TYPE order_h_rec IS RECORD(
    order_header_id              xxwsh_order_headers_all.order_header_id%TYPE             --�󒍃w�b�_�A�h�I��ID
    ,order_type_id               xxwsh_order_headers_all.order_type_id%TYPE               --�󒍃^�C�vID
    ,organization_id             xxwsh_order_headers_all.organization_id%TYPE             --�g�DID
    ,header_id                   xxwsh_order_headers_all.header_id%TYPE                   --�󒍃w�b�_ID
    ,latest_external_flag        xxwsh_order_headers_all.latest_external_flag%TYPE        --�ŐV�t���O
    ,ordered_date                xxwsh_order_headers_all.ordered_date%TYPE                --�󒍓�
    ,customer_id                 xxwsh_order_headers_all.customer_id%TYPE                 --�ڋqID
    ,customer_code               xxwsh_order_headers_all.customer_code%TYPE               --�ڋq
    ,deliver_to_id               xxwsh_order_headers_all.deliver_to_id%TYPE               --�o�א�ID
    ,deliver_to                  xxwsh_order_headers_all.deliver_to%TYPE                  --�o�א�
    ,shipping_instructions       xxwsh_order_headers_all.shipping_instructions%TYPE       --�o�׎w��
    ,career_id                   xxwsh_order_headers_all.career_id%TYPE                   --�^���Ǝ�ID
    ,freight_carrier_code        xxwsh_order_headers_all.freight_carrier_code%TYPE        --�^���Ǝ�
    ,shipping_method_code        xxwsh_order_headers_all.shipping_method_code%TYPE        --�z���敪
    ,cust_po_number              xxwsh_order_headers_all.cust_po_number%TYPE              --�ڋq����
    ,price_list_id               xxwsh_order_headers_all.price_list_id%TYPE               --���i�\
    ,request_no                  xxwsh_order_headers_all.request_no%TYPE                  --�˗�no
    ,req_status                  xxwsh_order_headers_all.req_status%TYPE                  --�X�e�[�^�X
    ,delivery_no                 xxwsh_order_headers_all.delivery_no%TYPE                 --�z��no
    ,prev_delivery_no            xxwsh_order_headers_all.prev_delivery_no%TYPE            --�O��z��no
    ,schedule_ship_date          xxwsh_order_headers_all.schedule_ship_date%TYPE          --�o�ח\���
    ,schedule_arrival_date       xxwsh_order_headers_all.schedule_arrival_date%TYPE       --���ח\���
    ,mixed_no                    xxwsh_order_headers_all.mixed_no%TYPE                    --���ڌ�no
    ,collected_pallet_qty        xxwsh_order_headers_all.collected_pallet_qty%TYPE        --�p���b�g�������
    ,confirm_request_class       xxwsh_order_headers_all.confirm_request_class%TYPE       --�����S���m�F�˗��敪
    ,freight_charge_class        xxwsh_order_headers_all.freight_charge_class%TYPE        --�^���敪
    ,shikyu_instruction_class    xxwsh_order_headers_all.shikyu_instruction_class%TYPE    --�x���o�Ɏw���敪
    ,shikyu_inst_rcv_class       xxwsh_order_headers_all.shikyu_inst_rcv_class%TYPE       --�x���w����̋敪
    ,amount_fix_class            xxwsh_order_headers_all.amount_fix_class%TYPE            --�L�����z�m��敪
    ,takeback_class              xxwsh_order_headers_all.takeback_class%TYPE              --����敪
    ,deliver_from_id             xxwsh_order_headers_all.deliver_from_id%TYPE             --�o�׌�ID
    ,deliver_from                xxwsh_order_headers_all.deliver_from%TYPE                --�o�׌��ۊǏꏊ
    ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch%TYPE           --�Ǌ����_
    ,po_no                       xxwsh_order_headers_all.po_no%TYPE                       --����no
    ,prod_class                  xxwsh_order_headers_all.prod_class%TYPE                  --���i�敪
    ,item_class                  xxwsh_order_headers_all.item_class%TYPE                  --�i�ڋ敪
    ,no_cont_freight_class       xxwsh_order_headers_all.no_cont_freight_class%TYPE       --�_��O�^���敪
    ,arrival_time_from           xxwsh_order_headers_all.arrival_time_from%TYPE           --���׎���from
    ,arrival_time_to             xxwsh_order_headers_all.arrival_time_to%TYPE             --���׎���to
    ,designated_item_id          xxwsh_order_headers_all.designated_item_id%TYPE          --�����i��ID
    ,designated_item_code        xxwsh_order_headers_all.designated_item_code%TYPE        --�����i��
    ,designated_production_date  xxwsh_order_headers_all.designated_production_date%TYPE  --������
    ,designated_branch_no        xxwsh_order_headers_all.designated_branch_no%TYPE        --�����}��
    ,slip_number                 xxwsh_order_headers_all.slip_number%TYPE                 --�����no
    ,sum_quantity                xxwsh_order_headers_all.sum_quantity%TYPE                --���v����
    ,small_quantity              xxwsh_order_headers_all.small_quantity%TYPE              --������
    ,label_quantity              xxwsh_order_headers_all.label_quantity%TYPE              --���x������
    ,loading_efficiency_weight   xxwsh_order_headers_all.loading_efficiency_weight%TYPE   --�d�ʐύڌ���
    ,loading_efficiency_capacity xxwsh_order_headers_all.loading_efficiency_capacity%TYPE --�e�ϐύڌ���
    ,based_weight                xxwsh_order_headers_all.based_weight%TYPE                --��{�d��
    ,based_capacity              xxwsh_order_headers_all.based_capacity%TYPE              --��{�e��
    ,sum_weight                  xxwsh_order_headers_all.sum_weight%TYPE                  --�ύڏd�ʍ��v
    ,sum_capacity                xxwsh_order_headers_all.sum_capacity%TYPE                --�ύڗe�ύ��v
    ,mixed_ratio                 xxwsh_order_headers_all.mixed_ratio%TYPE                 --���ڗ�
    ,pallet_sum_quantity         xxwsh_order_headers_all.pallet_sum_quantity%TYPE         --�p���b�g���v����
    ,real_pallet_quantity        xxwsh_order_headers_all.real_pallet_quantity%TYPE        --�p���b�g���і���
    ,sum_pallet_weight           xxwsh_order_headers_all.sum_pallet_weight%TYPE           --���v�p���b�g�d��
    ,order_source_ref            xxwsh_order_headers_all.order_source_ref%TYPE            --�󒍃\�[�X�Q��
    ,result_freight_carrier_id   xxwsh_order_headers_all.result_freight_carrier_id%TYPE   --�^���Ǝ�_����ID
    ,result_freight_carrier_code xxwsh_order_headers_all.result_freight_carrier_code%TYPE --�^���Ǝ�_����
    ,result_shipping_method_code xxwsh_order_headers_all.result_shipping_method_code%TYPE --�z���敪_����
    ,result_deliver_to_id        xxwsh_order_headers_all.result_deliver_to_id%TYPE        --�o�א�_����ID
    ,result_deliver_to           xxwsh_order_headers_all.result_deliver_to%TYPE           --�o�א�_����
    ,shipped_date                xxwsh_order_headers_all.shipped_date%TYPE                --�o�ד�
    ,arrival_date                xxwsh_order_headers_all.arrival_date%TYPE                --���ד�
    ,weight_capacity_class       xxwsh_order_headers_all.weight_capacity_class%TYPE       --�d�ʗe�ϋ敪
    ,actual_confirm_class        xxwsh_order_headers_all.actual_confirm_class%TYPE        --���ьv��ϋ敪
    ,notif_status                xxwsh_order_headers_all.notif_status%TYPE                --�ʒm�X�e�[�^�X
    ,prev_notif_status           xxwsh_order_headers_all.prev_notif_status%TYPE           --�O��ʒm�X�e�[�^�X
    ,notif_date                  xxwsh_order_headers_all.notif_date%TYPE                  --�m��ʒm���{����
    ,new_modify_flg              xxwsh_order_headers_all.new_modify_flg%TYPE              --�V�K�C���t���O
    ,process_status              xxwsh_order_headers_all.process_status%TYPE              --�����o�߃X�e�[�^�X
    ,performance_management_dept xxwsh_order_headers_all.performance_management_dept%TYPE --���ъǗ�����
    ,instruction_dept            xxwsh_order_headers_all.instruction_dept%TYPE            --�w������
    ,transfer_location_id        xxwsh_order_headers_all.transfer_location_id%TYPE        --�U�֐�ID
    ,transfer_location_code      xxwsh_order_headers_all.transfer_location_code%TYPE      --�U�֐�
    ,mixed_sign                  xxwsh_order_headers_all.mixed_sign%TYPE                  --���ڋL��
    ,screen_update_date          xxwsh_order_headers_all.screen_update_date%TYPE          --��ʍX�V����
    ,screen_update_by            xxwsh_order_headers_all.screen_update_by%TYPE            --��ʍX�V��
    ,tightening_date             xxwsh_order_headers_all.tightening_date%TYPE             --�o�׈˗����ߓ���
    ,vendor_id                   xxwsh_order_headers_all.vendor_id%TYPE                   --�����ID
    ,vendor_code                 xxwsh_order_headers_all.vendor_code%TYPE                 --�����
    ,vendor_site_id              xxwsh_order_headers_all.vendor_site_id%TYPE              --�����T�C�gID
    ,vendor_site_code            xxwsh_order_headers_all.vendor_site_code%TYPE            --�����T�C�g
    ,registered_sequence         xxwsh_order_headers_all.registered_sequence%TYPE         --�o�^����
    ,tightening_program_id       xxwsh_order_headers_all.tightening_program_id%TYPE       --���߃R���J�����gID
    ,corrected_tighten_class     xxwsh_order_headers_all.corrected_tighten_class%TYPE     --���ߌ�C���敪
  );
--
  -- �󒍖���(�A�h�I��)
  TYPE order_l_rec IS RECORD(
    order_line_id                xxwsh_order_lines_all.order_line_id%TYPE               --�󒍖��׃A�h�I��ID
    ,order_header_id             xxwsh_order_lines_all.order_header_id%TYPE             --�󒍃w�b�_�A�h�I��ID
    ,order_line_number           xxwsh_order_lines_all.order_line_number%TYPE           --���הԍ�
    ,header_id                   xxwsh_order_lines_all.header_id%TYPE                   --�󒍃w�b�_ID
    ,line_id                     xxwsh_order_lines_all.line_id%TYPE                     --�󒍖���ID
    ,request_no                  xxwsh_order_lines_all.request_no%TYPE                  --�˗�no
    ,shipping_inventory_item_id  xxwsh_order_lines_all.shipping_inventory_item_id%TYPE  --�o�וi��ID
    ,shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE          --�o�וi��
    ,quantity                    xxwsh_order_lines_all.quantity%TYPE                    --����
    ,uom_code                    xxwsh_order_lines_all.uom_code%TYPE                    --�P��
    ,unit_price                  xxwsh_order_lines_all.unit_price%TYPE                  --�P��
    ,shipped_quantity            xxwsh_order_lines_all.shipped_quantity%TYPE            --�o�׎��ѐ���
    ,designated_production_date  xxwsh_order_lines_all.designated_production_date%TYPE  --�w�萻����
    ,based_request_quantity      xxwsh_order_lines_all.based_request_quantity%TYPE      --���_�˗�����
    ,request_item_id             xxwsh_order_lines_all.request_item_id%TYPE             --�˗��i��ID
    ,request_item_code           xxwsh_order_lines_all.request_item_code%TYPE           --�˗��i��
    ,ship_to_quantity            xxwsh_order_lines_all.ship_to_quantity%TYPE            --���Ɏ��ѐ���
    ,futai_code                  xxwsh_order_lines_all.futai_code%TYPE                  --�t�уR�[�h
    ,designated_date             xxwsh_order_lines_all.designated_date%TYPE             --�w����t(���[�t)
    ,move_number                 xxwsh_order_lines_all.move_number%TYPE                 --�ړ�no
    ,po_number                   xxwsh_order_lines_all.po_number%TYPE                   --����no
    ,cust_po_number              xxwsh_order_lines_all.cust_po_number%TYPE              --�ڋq����
    ,pallet_quantity             xxwsh_order_lines_all.pallet_quantity%TYPE             --�p���b�g��
    ,layer_quantity              xxwsh_order_lines_all.layer_quantity%TYPE              --�i��
    ,case_quantity               xxwsh_order_lines_all.case_quantity%TYPE               --�P�[�X��
    ,weight                      xxwsh_order_lines_all.weight%TYPE                      --�d��
    ,capacity                    xxwsh_order_lines_all.capacity%TYPE                    --�e��
    ,pallet_qty                  xxwsh_order_lines_all.pallet_qty%TYPE                  --�p���b�g����
    ,pallet_weight               xxwsh_order_lines_all.pallet_weight%TYPE               --�p���b�g�d��
    ,reserved_quantity           xxwsh_order_lines_all.reserved_quantity%TYPE           --������
    ,automanual_reserve_class    xxwsh_order_lines_all.automanual_reserve_class%TYPE    --�����蓮�����敪
    ,delete_flag                 xxwsh_order_lines_all.delete_flag%TYPE                 --�폜�t���O
    ,warning_class               xxwsh_order_lines_all.warning_class%TYPE               --�x���敪
    ,warning_date                xxwsh_order_lines_all.warning_date%TYPE                --�x�����t
    ,line_description            xxwsh_order_lines_all.line_description%TYPE            --�E�v
    ,rm_if_flg                   xxwsh_order_lines_all.rm_if_flg%TYPE                   --�q�֕ԕiIF�σt���O
    ,shipping_request_if_flg     xxwsh_order_lines_all.shipping_request_if_flg%TYPE     --�o�׈˗�IF�σt���O
    ,shipping_result_if_flg      xxwsh_order_lines_all.shipping_result_if_flg%TYPE      --�o�׎���IF�σt���O
  );
--
  -- �f�[�^���i�[���錋���z��
  TYPE interface_tbl IS TABLE OF interface_rec INDEX BY PLS_INTEGER;
--
  -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)
  TYPE ship_header_id_del
    IS TABLE OF xxwsh_shipping_headers_if.header_id%TYPE INDEX BY BINARY_INTEGER;     --IF_H.�w�b�_ID\
  TYPE ship_line_id_del
    IS TABLE OF xxwsh_shipping_lines_if.line_id  %TYPE INDEX BY BINARY_INTEGER;       --IF_L.����ID
  -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)
  TYPE ship_line_id_upd
    IS TABLE OF xxwsh_shipping_lines_if.line_id%TYPE INDEX BY BINARY_INTEGER;         --IF_L.����ID(�X�V�p)
  TYPE ship_reserv_sts
    IS TABLE OF xxwsh_shipping_lines_if.reserved_status%TYPE INDEX BY BINARY_INTEGER; --IF_L.�ۗ��X�e�[�^�X(�X�V�p)
  TYPE request_id
    IS TABLE OF xxwsh_shipping_lines_if.request_id%TYPE INDEX BY BINARY_INTEGER;      --IF_L.�v��ID
  TYPE ship_order_source_ref
    IS TABLE OF xxwsh_shipping_headers_if.order_source_ref%TYPE INDEX BY BINARY_INTEGER; --IF_H.�󒍃\�[�X�Q�Ɓi���b�Z�[�W�\���p�j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_sysdate            DATE;                 -- �V�X�e�����ݓ��t
  gn_target_cnt         NUMBER;               -- ���͌���
--
--********** 2008/07/07 ********** ADD    START ***
  -- �V�K�p�̃J�E���g
  gn_ord_new_shikyu_cnt     NUMBER;               -- �V�K�󒍁i�x���j�쐬����
  gn_ord_new_syukka_cnt     NUMBER;               -- �V�K�󒍁i�o�ׁj�쐬����
  gn_mov_new_cnt            NUMBER;               -- �V�K�ړ��쐬����
  -- �����p�̃J�E���g
  gn_ord_correct_shikyu_cnt NUMBER;               -- �����󒍁i�x���j�쐬����
  gn_ord_correct_syukka_cnt NUMBER;               -- �����󒍁i�o�ׁj�쐬����
  gn_mov_correct_cnt        NUMBER;               -- �����ړ��쐬����
--********** 2008/07/07 ********** ADD    END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--*  -- �󒍃w�b�_
--*  gn_ord_h_upd_n_cnt    NUMBER;               -- �󒍃w�b�_�X�V�쐬����(���ьv��)
--*  gn_ord_h_ins_cnt      NUMBER;               -- �󒍃w�b�_�o�^�쐬����(�O���q�ɔ���)
--*  gn_ord_h_upd_y_cnt    NUMBER;               -- �󒍃w�b�_�X�V�쐬����(���ђ���)
--*  -- �󒍖���
--*  gn_ord_l_upd_n_cnt    NUMBER;               -- �󒍖��׍X�V�쐬����(���ьv��i�ڂ���)
--*  gn_ord_l_ins_n_cnt    NUMBER;               -- �󒍖��דo�^�쐬����(���ьv��i�ڂȂ�)
--*  gn_ord_l_ins_cnt      NUMBER;               -- �󒍖��דo�^�쐬����(�O���q�ɔ���)
--*  gn_ord_l_ins_y_cnt    NUMBER;               -- �󒍖��דo�^�쐬����(���яC��)
--*  -- ���b�g�ڍ�
--*  gn_ord_mov_ins_n_cnt  NUMBER;               -- ���b�g�ڍאV�K�쐬����(��_���ьv��)
--*  gn_ord_mov_ins_cnt    NUMBER;               -- ���b�g�ڍאV�K�쐬����(��_�O���q�ɔ���)
--*  gn_ord_mov_ins_y_cnt  NUMBER;               -- ���b�g�ڍאV�K�쐬����(��_���яC��)
--*  -- �ړ��˗�/�w���w�b�_
--*  gn_mov_h_ins_cnt      NUMBER;               -- �ړ��˗�/�w���w�b�_�o�^�쐬����(�O���q�ɔ���)
--*  gn_mov_h_upd_n_cnt    NUMBER;               -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ьv��)
--*  gn_mov_h_upd_y_cnt    NUMBER;               -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ђ���)
--*--
--*  -- �ړ��˗�/�w������
--*  gn_mov_l_upd_n_cnt    NUMBER;               -- �ړ��˗�/�w�����׍X�V�쐬����(���ьv��i�ڂ���)
--*  gn_mov_l_ins_n_cnt    NUMBER;               -- �ړ��˗�/�w�����דo�^�쐬����(���ьv��i�ڂȂ�)
--*  gn_mov_l_ins_cnt      NUMBER;               -- �ړ��˗�/�w�����דo�^�쐬����(�O���q�ɔ���)
--*  gn_mov_l_upd_y_cnt    NUMBER;               -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂ���)
--*  gn_mov_l_ins_y_cnt    NUMBER;               -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂȂ�)
--*  -- ���b�g�ڍ�
--*  gn_mov_mov_ins_n_cnt  NUMBER;               -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_���ьv��)
--*  gn_mov_mov_ins_cnt    NUMBER;               -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�O���q�ɔ���)
--*  gn_mov_mov_upd_y_cnt  NUMBER;               -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����)
--*  gn_mov_mov_ins_y_cnt  NUMBER;               -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g�Ȃ�)
--*  --
--*
--*  gn_del_headers_cnt    NUMBER;               -- IF�w�b�_�����񌏐�
--********** 2008/07/07 ********** DELETE END   ***
--
  gn_del_lines_cnt      NUMBER;               -- IF���׎����񌏐�
  --
  gn_del_errdata_cnt    NUMBER;               -- �G���[�f�[�^�폜����
  --
  gn_warn_cnt           NUMBER;               -- �x������
--
--********** 2008/07/07 ********** DELETE START ***
--*  gn_error_cnt          NUMBER;               -- �ُ팏��
--********** 2008/07/07 ********** DELETE END   ***
--
  gr_interface_info_rec    interface_tbl;             -- �C���^�[�t�F�[�X�e�[�u���̃f�[�^
  gr_movlot_detail_rec     movlot_detail_rec;         -- �ړ����b�g�ڍׂ̃f�[�^
  gr_mov_req_instr_h_rec   mov_req_instr_h_rec;       -- �ړ��˗�/�w���w�b�_�̃f�[�^
  gr_mov_req_instr_l_rec   mov_req_instr_l_rec;       -- �ړ��˗�/�w������(�A�h�I��)
  gr_order_h_rec           order_h_rec;               -- �󒍃w�b�_(�A�h�I��)�̃f�[�^
  gr_order_l_rec           order_l_rec;               -- �󒍖���(�A�h�I��)�̃f�[�^
--
  gr_movlot_detail_ini     movlot_detail_rec;         -- �ړ����b�g�ڍׂ̃f�[�^�������p
  gr_mov_req_instr_h_ini   mov_req_instr_h_rec;       -- �ړ��˗�/�w���w�b�_�̃f�[�^�������p
  gr_mov_req_instr_l_ini   mov_req_instr_l_rec;       -- �ړ��˗�/�w������(�A�h�I��)�������p
  gr_order_h_ini           order_h_rec;               -- �󒍃w�b�_(�A�h�I��)�̃f�[�^�������p
  gr_order_l_ini           order_l_rec;               -- �󒍖���(�A�h�I��)�̃f�[�^�������p
--
  -- �o�׈˗�IF�w�b�_/����
  gr_line_not_header       ship_header_id_del;        -- IF�w�b�_.�w�b�_ID
  gr_header_id             ship_header_id_del;        -- IF�w�b�_.�w�b�_ID
  gr_line_id               ship_line_id_del;          -- IF����.����ID
  gr_request_id            request_id;                -- IF����.�v��ID
  gr_order_source_ref      ship_order_source_ref;     -- IF�w�b�_.�󒍃\�[�X�Q��
  -- ���o���G���[���R�[�h�폜�p
  gr_header_id_del         ship_header_id_del;        -- IF�w�b�_.�w�b�_ID
  gr_line_id_del           ship_line_id_del;          -- IF����.����ID
  -- ���o���ۗ����R�[�h�X�V�p
  gr_line_id_upd           ship_line_id_upd;          -- IF����.����ID
  gr_reserv_sts            ship_reserv_sts;           -- IF����.�ۗ��X�e�[�^�X
--
  gb_mov_header_flg       BOOLEAN;      -- �ړ�(A-7) �O���q��(�w���Ȃ�)���� �w�b�_�p
  gb_mov_line_flg         BOOLEAN;      -- �ړ�(A-7) �O���q��(�w���Ȃ�)���� ���חp
--
  gb_ord_header_flg       BOOLEAN;      -- ��(A-8) �O���q��(�w���Ȃ�)���� �w�b�_�p
  gb_ord_line_flg         BOOLEAN;      -- ��(A-8) �O���q��(�w���Ȃ�)���� ���חp
--
  gb_mov_header_data_flg  BOOLEAN;      -- �ړ�(A-7) �w�b�_�����ϔ���
  gb_mov_line_data_flg    BOOLEAN;      -- �ړ�(A-7) ���׏����ϔ���
--
  gb_ord_header_data_flg  BOOLEAN;      -- ��(A-8) �w�b�_�����ϔ���
  gb_ord_line_data_flg    BOOLEAN;      -- ��(A-8) ���׏����ϔ���
--
  gb_mov_cnt_a7_flg       BOOLEAN;      -- �ړ�(A-7) �����\���Ōv�ォ���������f����̂��߂̃t���O
  gb_ord_cnt_a8_flg       BOOLEAN;      -- ��(A-8) �����\���Ōv�ォ���������f����̂��߂̃t���O
--
  -- WHO�J����
  gt_user_id         xxinv_mov_lot_details.created_by%TYPE;             -- �쐬��(�ŏI�X�V��)
  gt_sysdate         xxinv_mov_lot_details.creation_date%TYPE;          -- �쐬��(�ŏI�X�V��)
  gt_login_id        xxinv_mov_lot_details.last_update_login%TYPE;      -- �ŏI�X�V���O�C��
  gt_conc_request_id xxinv_mov_lot_details.request_id%TYPE;             -- �v��ID
  gt_prog_appl_id    xxinv_mov_lot_details.program_application_id%TYPE; -- �A�v���P�[�V����ID
  gt_conc_program_id xxinv_mov_lot_details.program_id%TYPE;             -- �R���J�����g�E�v���O����ID
--
  -- �f�o�b�O�p
  gb_debug    BOOLEAN DEFAULT FALSE;    --�f�o�b�O���O�o�͗p�X�C�b�`
--
  /**********************************************************************************
   * Procedure Name   : set_debug_switch
   * Description      : �f�o�b�O�p���O�o�͗p�؂�ւ��X�C�b�`�擾����
   ***********************************************************************************/
  PROCEDURE set_debug_switch 
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_debug_switch'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_debug_switch_prof_name CONSTANT VARCHAR2(30) := 'XXWSH_93A_DEBUG_SWITCH';  -- ���ޯ���׸�
    cv_debug_switch_ON        CONSTANT VARCHAR2(1)  := '1';   --�f�o�b�O�o�͂���
    cv_debug_switch_OFF       CONSTANT VARCHAR2(1)  := '0';   --�f�o�b�O�o�͂��Ȃ�
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�o�b�O�؂�ւ��v���t�@�C���擾
    IF (FND_PROFILE.VALUE(cv_debug_switch_prof_name) = cv_debug_switch_ON ) THEN
      gb_debug := TRUE;
    END IF;
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      gb_debug := FALSE;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_debug_switch;
--
  /**********************************************************************************
   * Procedure Name   : debug_log
   * Description      : �f�o�b�O�p���O�o�͏���
   ***********************************************************************************/
  PROCEDURE debug_log(in_which in number,       -- �o�͐�FFND_FILE.LOG or FND_FILE.OUTPUT
                      iv_msg   in varchar2 )    -- ���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'debug_log'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E�J�[�\�� ***
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
    --�f�o�b�OON�Ȃ�o��
    IF (gb_debug) THEN
      FND_FILE.PUT_LINE(in_which, iv_msg);
    END IF;
--
  EXCEPTION
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      NULL ;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END debug_log;
--
  /**********************************************************************************
   * Procedure Name   : set_deliveryno_unit_errflg
   * Description      : �w��z��No�AEOS�f�[�^��ʒP�ʂ�flag=1���Z�b�g���� �v���V�[�W��
   ***********************************************************************************/
  PROCEDURE set_deliveryno_unit_errflg(
    iv_delivery_no          IN  xxwsh_shipping_headers_if.delivery_no%TYPE,  -- �z��No
    iv_eos_data_type        IN  xxwsh_shipping_headers_if.eos_data_type%TYPE,  -- EOF�f�[�^���
    in_level                IN  VARCHAR2,            -- �G���[���
    iv_message              IN  VARCHAR2,            -- �G���[���b�Z�[�W
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_deliveryno_unit_errflg'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<deliveryno_unit_errflg_set>>
    FOR j IN 1..gr_interface_info_rec.COUNT LOOP
--
      IF ((NVL(iv_delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(j).delivery_no,gv_delivery_no_null)) AND
          (iv_eos_data_type = gr_interface_info_rec(j).eos_data_type))
      THEN
--
        IF (in_level = 1) THEN
          gr_interface_info_rec(j).err_flg := gv_flg_on;
        ELSE
          gr_interface_info_rec(j).reserve_flg := gv_flg_on;
        END IF;
--
        gr_interface_info_rec(j).message := iv_message;
--
      END IF;
--
    END LOOP deliveryno_unit_errflg_set;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_deliveryno_unit_errflg;
--
  /**********************************************************************************
   * Procedure Name   : set_header_unit_reserveflg
   * Description      : �w�b�_�P��(�z��No�A�˗�No�E�ړ��ԍ��AEOS�f�[�^���)��flag=1���Z�b�g���� �v���V�[�W��
   ***********************************************************************************/
  PROCEDURE set_header_unit_reserveflg(
    iv_delivery_no          IN  xxwsh_shipping_headers_if.delivery_no%TYPE,  -- �z��No
    iv_movreqno             IN  VARCHAR2,            -- �ړ��ԍ��A�˗�No
    iv_eos_data_type        IN  xxwsh_shipping_headers_if.eos_data_type%TYPE,  -- EOS�f�[�^���
    in_level                IN  VARCHAR2,            -- �G���[���
    iv_message              IN  VARCHAR2,            -- �G���[���b�Z�[�W
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_header_unit_reserveflg'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<header_unit_reserveflg_set>>
    FOR j IN 1..gr_interface_info_rec.COUNT LOOP
--
      IF ((NVL(iv_delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(j).delivery_no,gv_delivery_no_null)) AND
          (iv_movreqno = gr_interface_info_rec(j).order_source_ref)  AND
          (iv_eos_data_type = gr_interface_info_rec(j).eos_data_type))
      THEN
--
        IF (in_level = gv_err_class) THEN                     -- �G���[����
          gr_interface_info_rec(j).err_flg := gv_flg_on;
        ELSIF (in_level = gv_reserved_class) THEN            -- �ۗ�����
          gr_interface_info_rec(j).reserve_flg := gv_flg_on;
        ELSIF (in_level = gv_logonly_class) THEN             -- ���O�̂ݏo�͏���
          gr_interface_info_rec(j).logonly_flg := gv_flg_on;
        END IF;
--
        gr_interface_info_rec(j).message := iv_message;
--
      END IF;
--
    END LOOP header_unit_reserveflg_set;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_header_unit_reserveflg;
--
  /**********************************************************************************
   * Procedure Name   : master_data_get
   * Description      : �}�X�^(view)�f�[�^�擾 �v���V�[�W��
   ***********************************************************************************/
  PROCEDURE master_data_get(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'master_data_get'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    lt_customer_id                 xxcmn_cust_accounts2_v.party_id%TYPE;                --�p�[�e�B�[�T�C�gID
    lt_customer_code               xxcmn_cust_accounts2_v.party_number%TYPE;            --�p�[�e�B�[�T�C�gID
    lt_party_site_id               xxcmn_party_sites2_v.party_site_id%TYPE;             --�p�[�e�B�[�T�C�gID
    lt_base_code                   xxcmn_party_sites2_v.base_code%TYPE;                 --�Ǌ����_
    lt_inventory_location_id       xxcmn_item_locations2_v.inventory_location_id%TYPE;  --�q��ID
    lt_allow_pickup_flag           xxcmn_item_locations2_v.allow_pickup_flag%TYPE;      --�o�׈����Ώۃt���O
    lt_career_id                   xxcmn_carriers2_v.party_id%TYPE;         --�^���Ǝҏ��VIEW.�p�[�e�B�[ID
    lt_lot_id                      ic_lots_mst.lot_id%TYPE;                             -- ���b�gID
    lt_item_class_code             xxcmn_item_categories5_v.item_class_code%TYPE;       -- �i�ڋ敪
    lt_prod_class_code             xxcmn_item_categories5_v.prod_class_code%TYPE;       -- ���i�敪
    lt_lot_ctl                     xxcmn_item_mst2_v.lot_ctl%TYPE;                      -- ���b�g�Ǘ��敪
    lt_weight_capacity_class       xxcmn_item_mst2_v.weight_capacity_class%TYPE;        -- �d�ʗe�ϋ敪
    lt_item_id                     xxcmn_item_mst2_v.item_id%TYPE;                      -- �i��ID
    lt_item_no                     xxcmn_item_mst2_v.item_no%TYPE;                      -- �i��
    lt_num_of_cases                xxcmn_item_mst2_v.num_of_cases%TYPE;                 -- �P�[�X����
    lt_conv_unit                   xxcmn_item_mst2_v.conv_unit%TYPE;                    -- ���o�Ɋ��Z�P��
    lt_item_um                     xxcmn_item_mst2_v.item_um%TYPE;                      -- �P��
    lt_whse_item_id                xxcmn_item_mst2_v.whse_item_id%TYPE;                 -- �q�ɕi��
    lt_vendor_site_id              xxcmn_vendor_sites2_v.vendor_site_id%TYPE;           -- �d����T�C�gID
    lt_vendor_id                   xxcmn_vendor_sites2_v.vendor_id%TYPE;                -- �d����ID
    lt_vendor_site_code            xxcmn_vendor_sites2_v.vendor_site_code%TYPE;         -- �d����T�C�g��
    lt_inventory_item_id           xxcmn_item_mst2_v.inventory_item_id%TYPE;            -- INV�i��ID
    lt_whse_inventory_item_id      xxcmn_item_mst2_v.inventory_item_id%TYPE;            -- INV�q�ɕi��ID
    lt_whse_inventory_item_no      xxcmn_item_mst2_v.item_no%TYPE;                      -- INV�q�ɕi��
    lt_customer_class_code         xxcmn_cust_accounts2_v.customer_class_code%TYPE;     -- �ڋq�敪
--
    lv_msg_buff                    VARCHAR2(5000);
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �Ɩ���ʔ���
    -- EOS�f�[�^��� = 200 �L���o�ו�, 210 ���_�o�׊m���, 215 ���o�׊m���, 220 �ړ��o�Ɋm���
    -- �K�p�J�n���E�I�������o�ד��ɂĔ���
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220))
    THEN
--
      ----�ڋq�T�C�g���VIEW�E�ڋq���VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcav.party_id
                 ,xcav.party_number
                 ,xcav.customer_class_code
          INTO    lt_customer_id
                 ,lt_customer_code
                 ,lt_customer_class_code
          FROM    xxcmn_cust_acct_sites2_v   xcas2v      -- �ڋq�T�C�g���VIEW
                 ,xxcmn_cust_accounts2_v     xcav        -- �ڋq���VIEW
          WHERE   xcas2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xcas2v.party_site_status     = gv_view_status     -- �T�C�g�X�e�[�^�X = '�L��'
          AND     xcas2v.cust_acct_site_status = gv_view_status     -- �ڋq�T�C�g�X�e�[�^�X = '�L��'
          AND     xcas2v.cust_site_uses_status = gv_view_status     -- �g�p�ړI�X�e�[�^�X   = '�L��'
          AND     xcas2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �K�p�J�n�� <= IF_H.�o�ד�
          AND     xcas2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �K�p�I���� >= IF_H.�o�ד�
          AND     xcas2v.party_id     = xcav.party_id    -- �p�[�e�B�[ID=�p�[�e�B�[ID
          AND     xcav.party_status   = gv_view_status   -- �g�D�X�e�[�^�X = '�L��'
          AND     xcav.account_status = gv_view_status   -- �ڋq�X�e�[�^�X = '�L��'
          AND     xcav.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)  -- �K�p�J�n�� <= �o�ד�
          AND     xcav.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)  -- �K�p�I���� >= �o�ד�
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).customer_id     := lt_customer_id;
          gr_interface_info_rec(in_idx).customer_code   := lt_customer_code;
          gr_interface_info_rec(in_idx).customer_class_code := lt_customer_class_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).customer_id     := NULL;
          gr_interface_info_rec(in_idx).customer_code   := NULL;
          gr_interface_info_rec(in_idx).customer_class_code := NULL;
--
        END ;
--
      END IF;
--
      --�p�[�e�B�T�C�g���VIEW(IF_H.�o�א���擾)
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xps2v.party_site_id
                 ,xps2v.base_code
          INTO    lt_party_site_id
                 ,lt_base_code
          FROM    xxcmn_party_sites2_v       xps2v
          WHERE   xps2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xps2v.party_site_status     = gv_view_status     -- �T�C�g�X�e�[�^�X = '�L��'
          AND     xps2v.cust_site_uses_status = gv_view_status     -- �g�p�ړI�X�e�[�^�X = '�L��'
          AND     xps2v.cust_acct_site_status = gv_view_status     -- �ڋq�T�C�g�X�e�[�^�X= '�L��'
          AND     xps2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �K�p�J�n�� <= �o�ד�
          AND     xps2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �K�p�I���� >= �o�ד�
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_to_id         := lt_party_site_id;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := lt_party_site_id;
          gr_interface_info_rec(in_idx).base_code             := lt_base_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_to_id         := NULL;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := NULL;
          gr_interface_info_rec(in_idx).base_code             := NULL;
--
        END ;
--
      END IF;
--
      --�^���Ǝҏ��VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).freight_carrier_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcv.party_id
          INTO    lt_career_id
          FROM    xxcmn_carriers2_v          xcv
          WHERE   xcv.party_number       =  gr_interface_info_rec(in_idx).freight_carrier_code
          AND     xcv.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �K�p�J�n�� <= �o�ד�
          AND     xcv.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �K�p�I���� >= �o�ד�
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).career_id                 := lt_career_id;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := lt_career_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).career_id                 := NULL;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := NULL;
--
        END ;
--
      END IF;
--
      --OPM�ۊǏꏊ���VIEW(IF_H.�o�׌����擾)
      IF (TRIM(gr_interface_info_rec(in_idx).location_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).location_code
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �g�D�L���J�n��
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)))  -- �g�D�L���I����
            AND   xil2v_a.disable_date  IS NULL   -- ������
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_from_id := lt_inventory_location_id; -- �o�׌�ID
          gr_interface_info_rec(in_idx).shipped_locat   := lt_inventory_location_id; -- �o�Ɍ�ID
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_from_id := NULL;  -- �o�׌�ID
          gr_interface_info_rec(in_idx).shipped_locat   := NULL;  -- �o�Ɍ�ID
--          gr_interface_info_rec(in_idx).err_flg         := gv_flg_on;
--
        END ;
--
      END IF;
--
      --OPM�ۊǏꏊ���VIEW(IF_H.���ɑq�ɂ��擾)
      IF (TRIM(gr_interface_info_rec(in_idx).ship_to_location) IS NOT NULL) THEN
--
        BEGIN
          lt_inventory_location_id := NULL;
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).ship_to_location
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �g�D�L���J�n��
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)))  -- �g�D�L���I����
            AND   xil2v_a.disable_date  IS NULL   -- ������
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).ship_to_locat := lt_inventory_location_id; -- ���ɐ�ID
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).ship_to_locat := NULL; -- ���ɐ�ID
--
        END ;
--
      END IF;
--
      --OPM�ۊǏꏊ���VIEW(IF_H.�o�׌����擾)
      IF (TRIM(gr_interface_info_rec(in_idx).location_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xil2v_a.allow_pickup_flag       -- �o�׈����Ώۃt���O(attribute4)
          INTO    lt_allow_pickup_flag
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).location_code
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).shipped_date) -- �g�D�L���J�n��
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)))  -- �g�D�L���I����
            AND   xil2v_a.disable_date  IS NULL   -- ������
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).allow_pickup_flag := lt_allow_pickup_flag;  -- �o�׈����Ώۃt���O
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
            gr_interface_info_rec(in_idx).allow_pickup_flag := NULL;
--
        END ;
--
      END IF;
--
      -- OPM�i�ڏ��VIEW(IF_L.�󒍕i�ڂ��擾)
      IF (TRIM(gr_interface_info_rec(in_idx).orderd_item_code) IS NOT NULL) THEN
--
        BEGIN
--
          -- EOS�f�[�^��� = 210 ���_�o�׊m���, 215 ���o�׊m��񍐂̏ꍇ
          -- IF���ꂽ�i�ڂ͑q�ɕi�ڂƂ��Č�������
          IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
              (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215)) THEN
--
            SELECT xic5v.item_class_code                                     -- �i�ڋ敪
                  ,xic5v.prod_class_code                                     -- ���i�敪
                  ,xim2v_whse.lot_ctl                                        -- ���b�g�Ǘ��敪
                  ,xim2v_whse.weight_capacity_class                          -- �d�ʗe�ϋ敪
                  ,xim2v_whse.item_id                                        -- �i��ID
                  ,xim2v_whse.item_no                                        -- �i��
                  ,xim2v_whse.num_of_cases                                   -- �P�[�X����
                  ,xim2v_whse.conv_unit                                      -- ���o�Ɋ��Z�P��
                  ,xim2v_whse.item_um                                        -- �P��
                  ,xim2v_whse.whse_item_id                                   -- �q�ɕi��
                  ,xim2v_whse.inventory_item_id                              -- INV�i��ID
                  ,NVL(xim2v.inventory_item_id,xim2v_whse.inventory_item_id) -- INV�q�ɕi��ID(�o�וi��(�˗��i��))
                  ,NVL(xim2v.item_no,xim2v_whse.item_no)                     -- INV�q�ɕi��  (�o�וi��(�˗��i��))
            INTO  lt_item_class_code
                 ,lt_prod_class_code
                 ,lt_lot_ctl
                 ,lt_weight_capacity_class
                 ,lt_item_id
                 ,lt_item_no
                 ,lt_num_of_cases
                 ,lt_conv_unit
                 ,lt_item_um
                 ,lt_whse_item_id
                 ,lt_inventory_item_id
                 ,lt_whse_inventory_item_id
                 ,lt_whse_inventory_item_no
            FROM  (SELECT  item_id                        -- �i��ID
                          ,item_no                        -- �i��
                          ,whse_item_id                   -- �q�ɕi��
                          ,inventory_item_id              -- INV�i��ID
                   FROM    xxcmn_item_mst2_v
                   WHERE   item_id           <> whse_item_id                         -- �i�ڂƑq�ɕi�ڂ��Ⴄ����
                   AND     inactive_ind      <> gn_view_disable                      -- �����t���O
                   AND     obsolete_class    <> gv_view_disable                      -- �p�~�敪
                   AND     start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
                   AND     end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
                  )                         xim2v         -- �o�וi�ڃr���[
                 ,xxcmn_item_mst2_v         xim2v_whse    -- �q�ɕi�ڃr���[
                 ,xxcmn_item_categories5_v  xic5v
            WHERE xim2v_whse.item_no            = gr_interface_info_rec(in_idx).orderd_item_code
            AND   xim2v_whse.item_id            = xim2v.whse_item_id(+)              -- IF�i�ڂ��q�ɕi�ڂɐݒ肳��Ă���o�וi��(�˗��i��)
            AND   xim2v_whse.inactive_ind      <> gn_view_disable                    -- �����t���O
            AND   xim2v_whse.obsolete_class    <> gv_view_disable                    -- �p�~�敪
            AND   xim2v_whse.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v_whse.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v_whse.item_id            = xic5v.item_id
            AND   ROWNUM                        = 1;
--
          -- EOS�f�[�^��� = 200 �L���o�ו�, 220 �ړ��o�Ɋm��񍐂̏ꍇ
          ELSE
--
            SELECT xic5v.item_class_code              -- �i�ڋ敪
                  ,xic5v.prod_class_code              -- ���i�敪
                  ,xim2v.lot_ctl                      -- ���b�g�Ǘ��敪
                  ,xim2v.weight_capacity_class        -- �d�ʗe�ϋ敪
                  ,xim2v.item_id                      -- �i��ID
                  ,xim2v.item_no                      -- �i��
                  ,xim2v.num_of_cases                 -- �P�[�X����
                  ,xim2v.conv_unit                    -- ���o�Ɋ��Z�P��
                  ,xim2v.item_um                      -- �P��
                  ,xim2v.whse_item_id                 -- �q�ɕi��
                  ,xim2v.inventory_item_id            -- INV�i��ID
                  ,xim2v_whse.inventory_item_id       -- INV�q�ɕi��ID
                  ,xim2v_whse.item_no                 -- INV�q�ɕi��
            INTO  lt_item_class_code
                 ,lt_prod_class_code
                 ,lt_lot_ctl
                 ,lt_weight_capacity_class
                 ,lt_item_id
                 ,lt_item_no
                 ,lt_num_of_cases
                 ,lt_conv_unit
                 ,lt_item_um
                 ,lt_whse_item_id
                 ,lt_inventory_item_id
                 ,lt_whse_inventory_item_id
                 ,lt_whse_inventory_item_no
            FROM  xxcmn_item_mst2_v         xim2v
                 ,xxcmn_item_mst2_v         xim2v_whse
                 ,xxcmn_item_categories5_v  xic5v
            WHERE xim2v.item_no            = gr_interface_info_rec(in_idx).orderd_item_code
            AND   xim2v.inactive_ind      <> gn_view_disable                    -- �����t���O
            AND   xim2v.obsolete_class    <> gv_view_disable                    -- �p�~�敪
            AND   xim2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).shipped_date)
            AND   xim2v.item_id            = xic5v.item_id
            AND   xim2v_whse.item_id       = xim2v.whse_item_id  -- �q�ɕi��ID(OPM)
            AND   ROWNUM                   = 1;
--
          END IF;
--
          gr_interface_info_rec(in_idx).item_kbn_cd            := lt_item_class_code;
          gr_interface_info_rec(in_idx).prod_kbn_cd            := lt_prod_class_code;
          gr_interface_info_rec(in_idx).lot_ctl                := lt_lot_ctl;
          gr_interface_info_rec(in_idx).weight_capacity_class  := lt_weight_capacity_class;
          gr_interface_info_rec(in_idx).item_id                := lt_item_id;
          gr_interface_info_rec(in_idx).item_no                := lt_item_no;
          gr_interface_info_rec(in_idx).num_of_cases           := lt_num_of_cases;
          gr_interface_info_rec(in_idx).conv_unit              := lt_conv_unit;
          gr_interface_info_rec(in_idx).item_um                := lt_item_um;
          gr_interface_info_rec(in_idx).whse_item_id           := lt_whse_item_id;
          gr_interface_info_rec(in_idx).inventory_item_id      := lt_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_id := lt_whse_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_no := lt_whse_inventory_item_no;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
--
            gr_interface_info_rec(in_idx).item_kbn_cd            := NULL;
            gr_interface_info_rec(in_idx).prod_kbn_cd            := NULL;
            gr_interface_info_rec(in_idx).lot_ctl                := NULL;
            gr_interface_info_rec(in_idx).weight_capacity_class  := NULL;
            gr_interface_info_rec(in_idx).item_id                := NULL;
            gr_interface_info_rec(in_idx).item_no                := NULL;
            gr_interface_info_rec(in_idx).num_of_cases           := NULL;
            gr_interface_info_rec(in_idx).conv_unit              := NULL;
            gr_interface_info_rec(in_idx).item_um                := NULL;
            gr_interface_info_rec(in_idx).whse_item_id           := NULL;
            gr_interface_info_rec(in_idx).inventory_item_id      := NULL;
            gr_interface_info_rec(in_idx).whse_inventory_item_id := NULL;
            gr_interface_info_rec(in_idx).whse_inventory_item_no := NULL;
--
        END ;
--
      END IF;
--
    END IF;
--
    -- EOS�f�[�^��� = 230:�ړ����Ɋm���
    -- �K�p�J�n���E�I�����𒅉ד��ɂĔ���
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230)
    THEN
--
      ----�ڋq�T�C�g���VIEW�E�ڋq���VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcav.party_id
                 ,xcav.party_number
                 ,xcav.customer_class_code
          INTO    lt_customer_id
                 ,lt_customer_code
                 ,lt_customer_class_code
          FROM    xxcmn_cust_acct_sites2_v   xcas2v      -- �ڋq�T�C�g���VIEW
                 ,xxcmn_cust_accounts2_v     xcav        -- �ڋq���VIEW
          WHERE   xcas2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xcas2v.party_site_status     = gv_view_status     -- �T�C�g�X�e�[�^�X = '�L��'
          AND     xcas2v.cust_acct_site_status = gv_view_status     -- �ڋq�T�C�g�X�e�[�^�X = '�L��'
          AND     xcas2v.cust_site_uses_status = gv_view_status     -- �g�p�ړI�X�e�[�^�X   = '�L��'
          AND     xcas2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �K�p�J�n�� <= IF_H.���ד�
          AND     xcas2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �K�p�I���� >= IF_H.���ד�
          AND     xcas2v.party_id     = xcav.party_id    -- �p�[�e�B�[ID=�p�[�e�B�[ID
          AND     xcav.party_status   = gv_view_status   -- �g�D�X�e�[�^�X = '�L��'
          AND     xcav.account_status = gv_view_status   -- �ڋq�X�e�[�^�X = '�L��'
          AND     xcav.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date)  -- �K�p�J�n�� <= IF_H.���ד�
          AND     xcav.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)  -- �K�p�I���� >= IF_H.���ד�
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).customer_id     := lt_customer_id;
          gr_interface_info_rec(in_idx).customer_code   := lt_customer_code;
          gr_interface_info_rec(in_idx).customer_class_code := lt_customer_class_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).customer_id     := NULL;
          gr_interface_info_rec(in_idx).customer_code   := NULL;
          gr_interface_info_rec(in_idx).customer_class_code := NULL;
--
        END ;
--
      END IF;
--
      IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
        --�p�[�e�B�T�C�g���VIEW(IF_H.�o�א���擾)
        BEGIN
--
          SELECT  xps2v.party_site_id
                 ,xps2v.base_code
          INTO    lt_party_site_id
                 ,lt_base_code
          FROM    xxcmn_party_sites2_v       xps2v
          WHERE   xps2v.party_site_number     = gr_interface_info_rec(in_idx).party_site_code
          AND     xps2v.party_site_status     = gv_view_status     -- �T�C�g�X�e�[�^�X = '�L��'
          AND     xps2v.cust_site_uses_status = gv_view_status     -- �g�p�ړI�X�e�[�^�X = '�L��'
          AND     xps2v.cust_acct_site_status = gv_view_status     -- �ڋq�T�C�g�X�e�[�^�X= '�L��'
          AND     xps2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �K�p�J�n�� <= IF_H.���ד�
          AND     xps2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �K�p�I���� >= IF_H.���ד�
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_to_id         := lt_party_site_id;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := lt_party_site_id;
          gr_interface_info_rec(in_idx).base_code             := lt_base_code;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_to_id         := NULL;
          gr_interface_info_rec(in_idx).result_deliver_to_id  := NULL;
          gr_interface_info_rec(in_idx).base_code             := NULL;
--
        END ;
--
      END IF;
--
      --�^���Ǝҏ��VIEW
      IF (TRIM(gr_interface_info_rec(in_idx).freight_carrier_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xcv.party_id
          INTO    lt_career_id
          FROM    xxcmn_carriers2_v xcv
          WHERE   xcv.party_number       =  gr_interface_info_rec(in_idx).freight_carrier_code
          AND     xcv.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �K�p�J�n�� <= IF_H.���ד�
          AND     xcv.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �K�p�I���� >= IF_H.���ד�
          AND     ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).career_id                 := lt_career_id;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := lt_career_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).career_id                 := NULL;
          gr_interface_info_rec(in_idx).result_freight_carrier_id := NULL;
--
        END ;
--
      END IF;
--
      --OPM�ۊǏꏊ���VIEW(IF_H.�o�׌����擾)
      IF (TRIM(gr_interface_info_rec(in_idx).location_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).location_code
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �g�D�L���J�n��
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)))  -- �g�D�L���I����
            AND   xil2v_a.disable_date  IS NULL   -- ������
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).deliver_from_id := lt_inventory_location_id;
          gr_interface_info_rec(in_idx).shipped_locat   := lt_inventory_location_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).deliver_from_id := NULL;
          gr_interface_info_rec(in_idx).shipped_locat   := NULL;
--
        END ;
--
      END IF;
--
      --OPM�ۊǏꏊ���VIEW(IF_H.���ɑq�ɂ��擾)
      IF (TRIM(gr_interface_info_rec(in_idx).ship_to_location) IS NOT NULL) THEN
--
        BEGIN
          lt_inventory_location_id := NULL;
--
          SELECT  xil2v_a.inventory_location_id
          INTO    lt_inventory_location_id
          FROM    xxcmn_item_locations2_v    xil2v_a
          WHERE   xil2v_a.segment1      =  gr_interface_info_rec(in_idx).ship_to_location
            AND   xil2v_a.date_from  <=  TRUNC(gr_interface_info_rec(in_idx).arrival_date) -- �g�D�L���J�n��
            AND   ((xil2v_a.date_to IS NULL)
             OR   (xil2v_a.date_to >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)))  -- �g�D�L���I����
            AND   xil2v_a.disable_date  IS NULL   -- ������
            AND   ROWNUM          = 1;
--
          gr_interface_info_rec(in_idx).ship_to_locat := lt_inventory_location_id;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).ship_to_locat := NULL;
--
        END ;
--
      END IF;
--
      -- OPM�i�ڏ��VIEW(IF_L.�󒍕i�ڂ��擾)
      IF (TRIM(gr_interface_info_rec(in_idx).orderd_item_code) IS NOT NULL) THEN
--
        BEGIN
--
          SELECT xic5v.item_class_code              -- �i�ڋ敪
                ,xic5v.prod_class_code              -- ���i�敪
                ,xim2v.lot_ctl                      -- ���b�g�Ǘ��敪
                ,xim2v.weight_capacity_class        -- �d�ʗe�ϋ敪
                ,xim2v.item_id                      -- �i��ID
                ,xim2v.item_no                      -- �i��
                ,xim2v.num_of_cases                 -- �P�[�X����
                ,xim2v.conv_unit                    -- ���o�Ɋ��Z�P��
                ,xim2v.item_um                      -- �P��
                ,xim2v.whse_item_id                 -- �q�ɕi��
                ,xim2v.inventory_item_id            -- INV�i��ID
                ,xim2v_whse.inventory_item_id       -- INV�q�ɕi��ID
                ,xim2v_whse.item_no                 -- INV�q�ɕi��
          INTO  lt_item_class_code
               ,lt_prod_class_code
               ,lt_lot_ctl
               ,lt_weight_capacity_class
               ,lt_item_id
               ,lt_item_no
               ,lt_num_of_cases
               ,lt_conv_unit
               ,lt_item_um
               ,lt_whse_item_id
               ,lt_inventory_item_id
               ,lt_whse_inventory_item_id
               ,lt_whse_inventory_item_no
          FROM  xxcmn_item_mst2_v         xim2v
               ,xxcmn_item_mst2_v         xim2v_whse
               ,xxcmn_item_categories5_v  xic5v
          WHERE xim2v.item_no            = gr_interface_info_rec(in_idx).orderd_item_code
          AND   xim2v.inactive_ind      <> gn_view_disable                    -- �����t���O
          AND   xim2v.obsolete_class    <> gv_view_disable                    -- �p�~�敪
          AND   xim2v.start_date_active <= TRUNC(gr_interface_info_rec(in_idx).arrival_date)
          AND   xim2v.end_date_active   >= TRUNC(gr_interface_info_rec(in_idx).arrival_date)
          AND   xim2v.item_id            = xic5v.item_id
          AND   xim2v_whse.item_id       = xim2v.whse_item_id  -- �q�ɕi��ID(OPM)
          AND   ROWNUM                   = 1;
--
          gr_interface_info_rec(in_idx).item_kbn_cd            := lt_item_class_code;
          gr_interface_info_rec(in_idx).prod_kbn_cd            := lt_prod_class_code;
          gr_interface_info_rec(in_idx).lot_ctl                := lt_lot_ctl;
          gr_interface_info_rec(in_idx).weight_capacity_class  := lt_weight_capacity_class;
          gr_interface_info_rec(in_idx).item_id                := lt_item_id;
          gr_interface_info_rec(in_idx).item_no                := lt_item_no;
          gr_interface_info_rec(in_idx).num_of_cases           := lt_num_of_cases;
          gr_interface_info_rec(in_idx).conv_unit              := lt_conv_unit;
          gr_interface_info_rec(in_idx).item_um                := lt_item_um;
          gr_interface_info_rec(in_idx).whse_item_id           := lt_whse_item_id;
          gr_interface_info_rec(in_idx).inventory_item_id      := lt_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_id := lt_whse_inventory_item_id;
          gr_interface_info_rec(in_idx).whse_inventory_item_no := lt_whse_inventory_item_no;
--
        EXCEPTION
--
          WHEN NO_DATA_FOUND THEN
--
          gr_interface_info_rec(in_idx).item_kbn_cd            := NULL;
          gr_interface_info_rec(in_idx).prod_kbn_cd            := NULL;
          gr_interface_info_rec(in_idx).lot_ctl                := NULL;
          gr_interface_info_rec(in_idx).weight_capacity_class  := NULL;
          gr_interface_info_rec(in_idx).item_id                := NULL;
          gr_interface_info_rec(in_idx).item_no                := NULL;
          gr_interface_info_rec(in_idx).num_of_cases           := NULL;
          gr_interface_info_rec(in_idx).conv_unit              := NULL;
          gr_interface_info_rec(in_idx).item_um                := NULL;
          gr_interface_info_rec(in_idx).whse_item_id           := NULL;
          gr_interface_info_rec(in_idx).inventory_item_id      := NULL;
          gr_interface_info_rec(in_idx).whse_inventory_item_id := NULL;
          gr_interface_info_rec(in_idx).whse_inventory_item_no := NULL;
--
        END ;
--
      END IF;
--
    END IF;
--
    -- EOS�f�[�^��ʂɊ֌W�Ȃ��擾
    -- ���b�gID�̎擾
    IF (TRIM(gr_interface_info_rec(in_idx).lot_no) IS NOT NULL) THEN
--
      BEGIN
--
        SELECT  ilm.lot_id
        INTO    lt_lot_id
        FROM    ic_lots_mst     ilm         -- ���b�g�}�X�^
        WHERE   ilm.lot_no      =  gr_interface_info_rec(in_idx).lot_no
          AND   ilm.item_id     =  gr_interface_info_rec(in_idx).item_id
          AND   inactive_ind    = gn_normal
          AND   delete_mark     = gn_normal
          AND   ROWNUM          = 1;
--
        gr_interface_info_rec(in_idx).lot_id := lt_lot_id;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).lot_id  := 0;
--
      END ;
--
    ELSE
      gr_interface_info_rec(in_idx).lot_id  := 0;
--
    END IF;
--
    -- �d����T�C�g�}�X�^�̎擾
    IF (TRIM(gr_interface_info_rec(in_idx).party_site_code) IS NOT NULL) THEN
--
      --�d����T�C�g���VIEW2(IF_H.�o�א���擾)
      BEGIN
--
        SELECT xvsv.vendor_site_id          -- �d����T�C�gID
              ,xvsv.vendor_id               -- �d����ID
              ,xvsv.vendor_site_code        -- �d����T�C�g��
        INTO   lt_vendor_site_id
              ,lt_vendor_id
              ,lt_vendor_site_code
        FROM   xxcmn_vendor_sites2_v xvsv
        WHERE  xvsv.vendor_site_code = gr_interface_info_rec(in_idx).party_site_code  --�d����T�C�g���VIEW2
        AND    xvsv.start_date_active <= gr_interface_info_rec(in_idx).shipped_date   --�K�p�J�n��<=�o�ד�
        AND    xvsv.end_date_active   >= gr_interface_info_rec(in_idx).shipped_date   --�K�p�I����>=�o�ד�
        AND     ROWNUM          = 1;
--
        gr_interface_info_rec(in_idx).vendor_site_id   := lt_party_site_id;
        gr_interface_info_rec(in_idx).vendor_id        := lt_party_site_id;
        gr_interface_info_rec(in_idx).vendor_site_code := lt_base_code;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          gr_interface_info_rec(in_idx).vendor_site_id   := NULL;
          gr_interface_info_rec(in_idx).vendor_id        := NULL;
          gr_interface_info_rec(in_idx).vendor_site_code := NULL;
--
      END ;
--
    END IF;
--
    -- ���Z�����{����
    -- EOS�f�[�^��� = 210�F���_�o�׊m��� or 215�F���o�׊m���
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      -- ���ѐ��ʂ̐ݒ���s���B
      IF ((gr_interface_info_rec(in_idx).conv_unit  IS NOT NULL) AND         --���o�Ɋ��Z�P�ʂ��ݒ�ς�
          (gr_interface_info_rec(in_idx).item_kbn_cd = gv_item_kbn_cd_5) AND --���i
          ((gr_interface_info_rec(in_idx).prod_kbn_cd = gv_prod_kbn_cd_1) OR --���[�t���̓h�����N
           (gr_interface_info_rec(in_idx).prod_kbn_cd = gv_prod_kbn_cd_2)))
      THEN
--
        IF (NVL(gr_interface_info_rec(in_idx).num_of_cases,0) > 0)
        THEN
--
          --���� x �P�[�X������ݒ�
          gr_interface_info_rec(in_idx).orderd_quantity
            := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
          --���󐔗� x �P�[�X������ݒ�
          gr_interface_info_rec(in_idx).detailed_quantity
            := NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
        ELSE
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         'XXCMN'
                        ,gv_msg_93a_604                                 -- �P�[�X���萔�G���[
                        ,gv_request_no_token
                        ,gr_interface_info_rec(in_idx).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                        ,gv_item_no_token
                        ,gr_interface_info_rec(in_idx).orderd_item_code      -- IF_L.�󒍕i��
                       )
                        ,1
                        ,5000);
--
          --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
          set_header_unit_reserveflg(
            gr_interface_info_rec(in_idx).delivery_no,         -- �z��No
            gr_interface_info_rec(in_idx).order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
            gr_interface_info_rec(in_idx).eos_data_type,       -- EOS�f�[�^���
            gv_err_class,           -- �G���[��ʁF�G���[
            lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          -- �����X�e�[�^�X�F�x��
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
    -- EOS�f�[�^��� = 220�F�ړ��o�Ɋm��� or 230�F�ړ����Ɋm���
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230)
    THEN
--
      -- ���ѐ��ʂ̐ݒ���s���B
      IF ((gr_interface_info_rec(in_idx).conv_unit  IS NOT NULL) AND         --���o�Ɋ��Z�P�ʂ��ݒ�ς�
          (gr_interface_info_rec(in_idx).item_kbn_cd = gv_item_kbn_cd_5) AND --���i
          (gr_interface_info_rec(in_idx).prod_kbn_cd = gv_prod_kbn_cd_2))    --�h�����N
      THEN
--
        IF (NVL(gr_interface_info_rec(in_idx).num_of_cases,0) > 0)
        THEN
--
          --���� x �P�[�X������ݒ�
          gr_interface_info_rec(in_idx).orderd_quantity
            := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
          --���󐔗� x �P�[�X������ݒ�
          gr_interface_info_rec(in_idx).detailed_quantity
            := NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) * gr_interface_info_rec(in_idx).num_of_cases;
--
        ELSE
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         'XXCMN'
                        ,gv_msg_93a_604                                 -- �P�[�X���萔�G���[
                        ,gv_request_no_token
                        ,gr_interface_info_rec(in_idx).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                        ,gv_item_no_token
                        ,gr_interface_info_rec(in_idx).orderd_item_code      -- IF_L.�󒍕i��
                       )
                        ,1
                        ,5000);
--
          --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
          set_header_unit_reserveflg(
            gr_interface_info_rec(in_idx).delivery_no,         -- �z��No
            gr_interface_info_rec(in_idx).order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
            gr_interface_info_rec(in_idx).eos_data_type,       -- EOS�f�[�^���
            gv_err_class,           -- �G���[��ʁF�G���[
            lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          -- �����X�e�[�^�X�F�x��
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ���b�g�Ǘ��O�̏ꍇ�A���ʂ܂��͓��󐔗ʂ̏�Ԃɂ��ǂ��炩�����ѐ��ʍ��ڂ֐ݒ肷��
    -- ���b�g�Ǘ��敪 = 0:���b�g�Ǘ��O
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
--
      -- EOS�f�[�^��� = 200:�L���o�ו� or 210�F���_�o�׊m��� or 215�F���o�׊m��� or 220�F�ړ��o�Ɋm���
      IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215)  OR
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220)) THEN
--
        IF NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0 THEN
--
          -- ���ʂ��o�׎��ѐ��ʂ֐ݒ�
          gr_interface_info_rec(in_idx).shiped_quantity := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0);
--
        ELSE
--
          -- ���󐔗ʂ��o�׎��ѐ��ʂ֐ݒ�
          gr_interface_info_rec(in_idx).shiped_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
        END IF;
--
      -- EOS�f�[�^��� = 230�F�ړ����Ɋm���
      ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
        IF NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0 THEN
--
          -- ���ʂ���Ɏ��ѐ��ʂ֐ݒ�
          gr_interface_info_rec(in_idx).ship_to_quantity := NVL(gr_interface_info_rec(in_idx).orderd_quantity,0);
--
        ELSE
--
          -- ���󐔗ʂ���Ɏ��ѐ��ʂ֐ݒ�
          gr_interface_info_rec(in_idx).ship_to_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
        END IF;
--
      END IF;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END master_data_get;
--
  /**********************************************************************************
   * Procedure Name   : upd_line_items_set
   * Description      : �d�ʗe�Ϗ������ݒ� �v���V�[�W��
   ***********************************************************************************/
  PROCEDURE upd_line_items_set(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_line_items_set'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_biz_type             VARCHAR2(1);     -- �Ɩ����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �Ɩ���ʔ���
    -- EOS�f�[�^��� = 210 ���_�o�׊m���,215 ���o�׊m��񍐂̏ꍇ
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      lv_biz_type     := gv_biz_type_1; --�o��
--
    -- EOS�f�[�^��� = 200 �L���o�ו񍐂̏ꍇ
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      lv_biz_type     := gv_biz_type_2; --�x��
--
    ELSE
--
      lv_biz_type     := gv_biz_type_3; --�ړ�
--
    END IF;
--
    -- �d�ʗe�Ϗ������X�V�֐����{
    lv_retcode := xxwsh_common_pkg.update_line_items(
                         lv_biz_type            -- �Ɩ����
                        ,gr_interface_info_rec(in_idx).order_source_ref    -- �ϊ��O�˗�No
                       );
--
    -- �d�ʗe�Ϗ������X�V�֐��̏������ʔ���
    IF (lv_retcode <> gn_normal) THEN
--
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
           gv_msg_kbn                 -- 'XXWSH'
          ,gv_msg_93a_308             -- �d�ʗe�Ϗ������X�V�֐��G���[���b�Z�[�W
          )
          ,1
          ,5000);
--
      RAISE global_api_expt;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_line_items_set;
--
  /**********************************************************************************
   * F Name   : ord_results_quantity_set
   * Description      : �󒍎��ѐ��ʂ̐ݒ� �v���V�[�W��
   ***********************************************************************************/
  PROCEDURE ord_results_quantity_set(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ord_results_quantity_set'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    lt_order_header_id     xxwsh_order_headers_all.order_header_id%TYPE;          --�󒍃w�b�_�A�h�I��ID
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR ord_results_quantity_cur
      (
      in_order_header_id          xxwsh_order_headers_all.order_header_id%TYPE,   -- �󒍃w�b�_�A�h�I��ID
      in_item_id                  xxinv_mov_lot_details.item_id%TYPE              -- OPM�i��ID
      )
    IS
      SELECT xola.order_line_id
            ,xmld.item_id
            ,SUM(NVL(xmld.actual_quantity,0))
      FROM  xxwsh_order_headers_all xoha,
            xxwsh_order_lines_all   xola,
            xxinv_mov_lot_details   xmld
      WHERE xoha.order_header_id      = in_order_header_id    -- �󒍃w�b�_ID
      AND   xoha.order_header_id      = xola.order_header_id  -- �󒍃w�b�_ID
      AND   xola.order_line_id        = xmld.mov_line_id      -- �󒍖���ID
      AND   xmld.item_id              = in_item_id            -- OPM�i��ID
      AND   xoha.latest_external_flag = gv_yesno_y            -- �ŐV�t���O
      AND   xmld.record_type_code     = gv_record_type_20     -- ���R�[�h�^�C�v = �o�Ɏ���(20)
      AND   ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))  -- �폜�t���O
      GROUP BY
                xola.order_line_id
                ,xmld.item_id
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    --�o�Ɏ��ѐ��ʎ擾�p
    -- ����ID
    TYPE order_line_id_type_rec IS TABLE OF
      xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
    -- �i��ID
    TYPE item_id_rec IS TABLE OF
      xxinv_mov_lot_details.item_id%TYPE INDEX BY BINARY_INTEGER;
    -- �o�Ɏ��ѐ���
    TYPE sum_actual_quantity IS TABLE OF
      xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
--
    lt_order_line_id         order_line_id_type_rec;     -- ����ID
    lt_item_id               item_id_rec;                -- �i��ID
    lt_sum_actual_quantity   sum_actual_quantity;        -- �o�Ɏ��ѐ���
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lt_order_header_id     := gr_order_h_rec.order_header_id; --�󒍃w�b�_ID
--
    --  �ړ����b�g�ڍׂ��������ʂ̍��v���擾����
    OPEN ord_results_quantity_cur
      (
        lt_order_header_id
        ,gr_interface_info_rec(in_idx).item_id
      );
--
    --�t�F�b�`
    FETCH ord_results_quantity_cur BULK COLLECT
     INTO lt_order_line_id
          ,lt_item_id
          ,lt_sum_actual_quantity;
--
    --�N���[�Y
    CLOSE ord_results_quantity_cur;
--
    -- �X�V����(�o���N����)
    <<sum_actual_quantity_upd_loop>>
    FORALL i IN 1 .. lt_order_line_id.COUNT
      -- **************************************************
      -- *** �󒍖���(�A�h�I��)�X�V���s��
      -- **************************************************
      UPDATE
        xxwsh_order_lines_all    xola    -- �󒍖���(�A�h�I��)
      SET
         xola.shipped_quantity        = lt_sum_actual_quantity(i)               -- �o�Ɏ��ѐ���
        ,xola.last_updated_by         = gt_user_id                              -- �ŏI�X�V��
        ,xola.last_update_date        = gt_sysdate                              -- �ŏI�X�V��
        ,xola.last_update_login       = gt_login_id                             -- �ŏI�X�V���O�C��
        ,xola.request_id              = gt_conc_request_id                      -- �v��ID
        ,xola.program_application_id  = gt_prog_appl_id                         -- �A�v���P�[�V����ID
        ,xola.program_id              = gt_conc_program_id                      -- �v���O����ID
        ,xola.program_update_date     = gt_sysdate                              -- �v���O�����X�V��
      WHERE xola.order_line_id = lt_order_line_id(i) -- �󒍖���ID
      AND   ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))
      ;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ord_results_quantity_set;
--
  /**********************************************************************************
   * F Name   : mov_results_quantity_set
   * Description      : �o�׈˗����ѐ��ʂ̐ݒ� �v���V�[�W��
   ***********************************************************************************/
  PROCEDURE mov_results_quantity_set(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_results_quantity_set'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    lt_mov_hdr_id     xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;       --�ړ��w�b�_ID
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mov_results_quantity_cur
      (
      in_mov_hdr_id        xxinv_mov_req_instr_headers.mov_hdr_id%TYPE,      -- �ړ��w�b�_ID
      in_item_id           xxinv_mov_lot_details.item_id%TYPE,                -- OPM�i��ID
      in_record_type       xxinv_mov_lot_details.record_type_code%TYPE       -- ���R�[�h�^�C�v
      )
    IS
      SELECT xmrql.mov_line_id
            ,xmld.item_id
            ,SUM(NVL(xmld.actual_quantity,0))
      FROM  xxinv_mov_req_instr_headers xmrif,
            xxinv_mov_req_instr_lines   xmrql,
            xxinv_mov_lot_details   xmld
      WHERE xmrif.mov_hdr_id        = in_mov_hdr_id       -- �ړ��w�b�_ID
      AND   xmrif.mov_hdr_id        = xmrql.mov_hdr_id   -- �ړ��w�b�_ID
      AND   xmrql.mov_line_id       = xmld.mov_line_id    -- �ړ�����ID
      AND   xmld.item_id            = in_item_id -- OPM�i��ID
      AND   xmld.record_type_code   = in_record_type      -- ���R�[�h�^�C�v
      AND   xmrif.status           <> gv_mov_status_99    -- �X�e�[�^�X<>����ȊO
      AND   ((xmrql.delete_flg = gv_yesno_n) OR (xmrql.delete_flg IS NULL))
      GROUP BY
                xmrql.mov_line_id
                ,xmld.item_id
      ;
    -- *** ���[�J���E���R�[�h ***
--
    -- �o�Ɏ��ѐ��ʎ擾�p
    -- ����ID
    TYPE mov_line_rec IS TABLE OF
      xxinv_mov_req_instr_lines.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
    -- �i��ID
    TYPE item_id_rec IS TABLE OF
      xxinv_mov_req_instr_lines.item_id%TYPE INDEX BY BINARY_INTEGER;
    -- �o�Ɏ��ѐ���
    TYPE sum_actual_quantity IS TABLE OF
      xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
--
    -- �������p
    lt_mov_line_rec_ini        mov_line_rec;               -- �ړ�����ID
    lt_item_id_ini             item_id_rec;                -- �i��ID
    lt_sum_actual_quantity_ini sum_actual_quantity;        -- �o�Ɏ��ѐ���
--
    lt_mov_line_rec            mov_line_rec;               -- �ړ�����ID
    lt_item_id                 item_id_rec;                -- �i��ID
    lt_sum_actual_quantity     sum_actual_quantity;        -- �o�Ɏ��ѐ���
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lt_mov_hdr_id          := gr_mov_req_instr_h_rec.mov_hdr_id; --�ړ��w�b�_ID
--
    -- ������
    lt_mov_line_rec        := lt_mov_line_rec_ini;
    lt_item_id             := lt_item_id_ini;
    lt_sum_actual_quantity := lt_sum_actual_quantity_ini;
--
    -- �ړ��o�Ɋm��񍐂̏ꍇ�A�o�Ɏ��ѐ��ʂ̐ݒ���s��
    IF gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220 THEN
      --  �ړ����b�g�ڍׂ��������ʂ̍��v���擾����
      OPEN mov_results_quantity_cur
        (
          lt_mov_hdr_id
          ,gr_interface_info_rec(in_idx).item_id
          ,gv_record_type_20                      -- ���R�[�h�^�C�v = �o�Ɏ���(20)
        );
--
      --�t�F�b�`
      FETCH mov_results_quantity_cur BULK COLLECT
       INTO lt_mov_line_rec
            ,lt_item_id
            ,lt_sum_actual_quantity;
--
      --�N���[�Y
      CLOSE mov_results_quantity_cur;
--
      -- �X�V����(�o���N����)
      <<sum_actual_quantity_upd_loop>>
      FORALL i IN 1 .. lt_mov_line_rec.COUNT
        -- **************************************************
        -- *** �˗�����(�A�h�I��)�X�V���s��
        -- **************************************************
        UPDATE
          xxinv_mov_req_instr_lines    xmrql    -- �ړ�����(�A�h�I��)
        SET
           xmrql.shipped_quantity        = lt_sum_actual_quantity(i) -- �o�Ɏ��ѐ���
          ,xmrql.last_updated_by         = gt_user_id                     -- �ŏI�X�V��
          ,xmrql.last_update_date        = gt_sysdate                     -- �ŏI�X�V��
          ,xmrql.last_update_login       = gt_login_id                    -- �ŏI�X�V���O�C��
          ,xmrql.request_id              = gt_conc_request_id             -- �v��ID
          ,xmrql.program_application_id  = gt_prog_appl_id                -- �A�v���P�[�V����ID
          ,xmrql.program_id              = gt_conc_program_id             -- �v���O����ID
          ,xmrql.program_update_date     = gt_sysdate                     -- �v���O�����X�V��
        WHERE 
              xmrql.mov_line_id = lt_mov_line_rec(i)                         -- �ړ�����ID
        AND ((xmrql.delete_flg = gv_yesno_n) OR (xmrql.delete_flg IS NULL)) -- �폜�t���O=���폜
        ;
--
    END IF;
--
    -- �ړ����Ɋm��񍐂̏ꍇ�A���Ɏ��ѐ��ʂ̐ݒ���s��
    IF gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230 THEN
--
      --  �ړ����b�g�ڍׂ��������ʂ̍��v���擾����
      OPEN mov_results_quantity_cur
        (
          lt_mov_hdr_id
          ,gr_interface_info_rec(in_idx).item_id
          ,gv_record_type_30                      -- ���R�[�h�^�C�v = ���Ɏ���(30)
        );
--
      --�t�F�b�`
      FETCH mov_results_quantity_cur BULK COLLECT
       INTO lt_mov_line_rec
            ,lt_item_id
            ,lt_sum_actual_quantity;
--
      --�N���[�Y
      CLOSE mov_results_quantity_cur;
--
      -- �X�V����(�o���N����)
      <<sum_actual_quantity_upd_loop>>
      FORALL i IN 1 .. lt_mov_line_rec.COUNT
        -- **************************************************
        -- *** �ړ��˗�/�w������(�A�h�I��)�X�V���s��
        -- **************************************************
--
        UPDATE
          xxinv_mov_req_instr_lines    xmrql    -- �ړ��˗�/�w������(�A�h�I��)
        SET
           xmrql.ship_to_quantity        = lt_sum_actual_quantity(i)       -- ���Ɏ��ѐ���
          ,xmrql.last_updated_by         = gt_user_id                      -- �ŏI�X�V��
          ,xmrql.last_update_date        = gt_sysdate                      -- �ŏI�X�V��
          ,xmrql.last_update_login       = gt_login_id                     -- �ŏI�X�V���O�C��
          ,xmrql.request_id              = gt_conc_request_id              -- �v��ID
          ,xmrql.program_application_id  = gt_prog_appl_id                 -- �A�v���P�[�V����ID
          ,xmrql.program_id              = gt_conc_program_id              -- �v���O����ID
          ,xmrql.program_update_date     = gt_sysdate                      -- �v���O�����X�V��
        WHERE 
              xmrql.mov_line_id = lt_mov_line_rec(i)                        -- �ړ�����ID
        AND ((xmrql.delete_flg = gv_yesno_n) OR (xmrql.delete_flg IS NULL)) -- �폜�t���O=���폜
        ;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_results_quantity_set;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�`�F�b�N �v���V�[�W�� (A-0)
   ***********************************************************************************/
  PROCEDURE chk_param(
    iv_process_object_info  IN  VARCHAR2,            -- �����Ώۏ��
    iv_report_post          IN  VARCHAR2,            -- �񍐕���
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_process_object_info   CONSTANT VARCHAR2(20) := '�����Ώۏ��'; -- �p�����[�^���F�����Ώۏ��
    cv_report_post           CONSTANT VARCHAR2(20) := '�񍐕���';     -- �p�����[�^���F�񍐕���
--
    -- *** ���[�J���ϐ� ***
    lv_process_object_info            VARCHAR2(2) := iv_process_object_info;   -- �����Ώۏ��
    lv_report_post                    VARCHAR2(4) := iv_report_post;           -- �񍐕���
    ln_01_cnt                         NUMBER;                                 -- ���[�t����
    ln_02_cnt                         NUMBER;                                 -- �h�����N����
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ***************************************
    -- ***     �K�{�`�F�b�N(�����Ώۏ��)    ***
    -- ***************************************
    --
    IF (lv_process_object_info IS NULL) THEN
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                     gv_msg_kbn,            -- �A�v���P�[�V�����Z�k���FXXWSH
                     gv_msg_93a_001,        -- ���b�Z�[�W�FAPP-XXWSH-13101 �K�{�p�����[�^�G���[
                     gv_tkn_item,           -- �g�[�N���FITEM
                     cv_process_object_info -- �p�����[�^�F�����Ώۏ��
                   ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE parameter_expt;
--
    END IF;
--
    -- ***************************************
    -- ***      �K�{�`�F�b�N(�񍐕���)     ***
    -- ***************************************
    --
    IF (lv_report_post IS NULL) THEN
--
      -- �G���[���b�Z�[�W�擾
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                     gv_msg_kbn,            -- �A�v���P�[�V�����Z�k���FXXWSH
                     gv_msg_93a_001,        -- ���b�Z�[�W�FAPP-XXWSH-13101 �K�{�p�����[�^�G���[
                     gv_tkn_item,           -- �g�[�N���FITEM
                     cv_report_post         -- �p�����[�^�F�����Ώۏ��
                   ),1,5000);
      lv_errbuf := lv_errmsg;
--
      RAISE parameter_expt;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_param;
--
 /**********************************************************************************
  * Procedure Name   : get_profile
  * Description      : �v���t�@�C���l�擾 �v���V�[�W�� (A-1)
  ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_parge_period    VARCHAR2(100); -- �p�[�W�Ώۊ���
    lv_master_org_id   VARCHAR2(100); -- �g�DID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �v���t�@�C���u�p�[�W�Ώۊ��ԁv�擾
    lv_parge_period := FND_PROFILE.VALUE(gv_purge_period_930);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_parge_period IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                 gv_msg_kbn,               -- 'XXWSH'
                     gv_msg_93a_002,           -- �v���t�@�C���擾�G���[���b�Z�[�W
                     gv_prof_token,            -- �g�[�N��'PROF_NAME'
                     gv_parge_period_jp);      -- �p�[�W��������(���o�Ɏ��уC���^�t�F�[�X)
--
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
--
    END IF;
--
    BEGIN
--
      gn_purge_period := TO_NUMBER(lv_parge_period);
--
    EXCEPTION
--
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                       gv_msg_kbn,             -- 'XXWSH'
                       gv_msg_93a_002,         -- �v���t�@�C���擾�G���[���b�Z�[�W
                       gv_prof_token,          -- �g�[�N��'PROF_NAME'
                       gv_parge_period_jp);    -- XXWSH:�p�[�W��������(���o�Ɏ��уC���^�t�F�[�X)
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- �v���t�@�C���u�V�X�e���v���t�@�C���g�DID�v�擾
    gv_master_org_id := FND_PROFILE.VALUE(gv_master_org_id_type);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_master_org_id IS NULL) THEN
--
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                 gv_msg_kbn,               -- 'XXWSH'
                     gv_msg_93a_002,           -- �v���t�@�C���擾�G���[���b�Z�[�W
                     gv_prof_token,            -- �g�[�N��'PROF_NAME'
                     gv_master_org_id_jp);     -- XXCMN:�}�X�^�g�D
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile;
--
 /**********************************************************************************
  * Procedure Name   : purge_processing
  * Description      : �p�[�W���� �v���V�[�W�� (A-2)
  ***********************************************************************************/
  PROCEDURE purge_processing(
    iv_process_object_info  IN  VARCHAR2,            -- �����Ώۏ��
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'purge_processing'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_no_lock          VARCHAR2(1);                         -- ���b�N�擾�X�e�[�^�X
    In_not_cnt          NUMBER;                              -- IF�w�b�_�폜�f�[�^�i�[�p�J�E���g
    ln_count            NUMBER;                              -- IF���ב��݃f�[�^�����i�[
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^
    -- �����b(00:00:00)���l�����ăp�[�W�Ώۊ��Ԃ��-1���������Ԃ�Ώۓ��t��������쐬���Ɣ�r���s���B
    CURSOR xshli_cur
    IS
      SELECT xshi.header_id
            ,xsli.line_id
      FROM   xxwsh_shipping_headers_if xshi   --IF_H
            ,xxwsh_shipping_lines_if   xsli   --IF_L
      WHERE  xsli.reserved_status = gv_reserved_status    --�ۗ��X�e�[�^�X = �ۗ�
      AND    xshi.header_id  = xsli.header_id
      AND    xshi.data_type = iv_process_object_info      --�f�[�^�^�C�v
      AND    xshi.creation_date < (TRUNC(gd_sysdate) - (gn_purge_period -1))
      ORDER BY xshi.header_id,xsli.line_id
      FOR UPDATE OF xshi.header_id NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �C���^�t�F�[�X�f�[�^�擾
    BEGIN
--
      -- ���b�N�擾����
      OPEN  xshli_cur;
--
    EXCEPTION
--
      WHEN check_lock_expt THEN  -- ���b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn         -- 'XXWSH'
                                                       ,gv_msg_93a_003    -- �e�[�u�����b�N�G���[
                                                       ,gv_table_token    -- �g�[�N��'TABLE'
                                                       ,gv_if_table_jp)   -- �o�׈˗�IF�e�[�u��
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- �ϐ�������
    In_not_cnt := 0;             -- IF�w�b�_�폜�f�[�^�i�[�p�J�E���g
    gr_line_not_header.delete;
    gr_header_id.delete;
    gr_line_id.delete;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH xshli_cur BULK COLLECT INTO gr_header_id,gr_line_id;
--
    gn_del_lines_cnt := gn_del_lines_cnt + gr_line_id.COUNT;
--
     -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)�폜
    <<if_purge_line_del_loop>>
    FORALL i IN 1 .. gr_line_id.COUNT
--
      DELETE FROM xxwsh_shipping_lines_if   xsli
      WHERE xsli.line_id = gr_line_id(i);
--
     -- IF�w�b�_.�w�b�_ID�ɕR�Â�IF���׃f�[�^�����݂��邩�ۂ��̊m�F���s���B
     -- ���݂��Ȃ��ꍇ�A�폜�ΏۂƂ���B
    <<if_purge_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id.COUNT LOOP
      IF (i < gr_header_id.COUNT) THEN
        -- IF.�w�b�_ID�̔�r
        IF ((gr_header_id(i)) <> (gr_header_id(i+1))) THEN
--
          -- IF���ב��݃`�F�b�N���s���B
          SELECT COUNT(xsli.line_id) cnt
          INTO   ln_count
          FROM   xxwsh_shipping_lines_if   xsli
          WHERE  xsli.header_id =  gr_header_id(i)
          ;
          -- ���݂��Ȃ��ꍇ�́AIF�w�b�_���폜�Ώۂ��A�폜�f�[�^�i�[�̈�Ɋi�[����B
          IF (ln_count = 0) THEN
--
             In_not_cnt :=In_not_cnt + 1;
             gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*          gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
          END IF;
--
        END IF;
--
      ELSE
        -- �ŏI�f�[�^�̏���
        -- IF���ב��݃`�F�b�N���s���B
        SELECT COUNT(xsli.line_id) cnt
        INTO   ln_count
        FROM   xxwsh_shipping_lines_if   xsli
        WHERE  xsli.header_id =  gr_header_id(i)
        ;
        -- ���݂��Ȃ��ꍇ�́AIF�w�b�_���폜�Ώۂ��A�폜�f�[�^�i�[�̈�Ɋi�[����B
        IF (ln_count = 0) THEN
--
           In_not_cnt :=In_not_cnt + 1;
           gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*        gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
        END IF;
--
      END IF;
--
    END LOOP if_purge_ifm_not_loop;
--
    -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�폜
    <<if_purge_headers_del_loop>>
    FORALL i IN 1 .. gr_line_not_header.COUNT
--
      DELETE FROM xxwsh_shipping_headers_if xshi  --IF_H
      WHERE xshi.header_id = gr_line_not_header(i);
--
    CLOSE xshli_cur;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( xshli_cur%ISOPEN ) THEN
        CLOSE xshli_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( xshli_cur%ISOPEN ) THEN
        CLOSE xshli_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( xshli_cur%ISOPEN ) THEN
        CLOSE xshli_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END purge_processing;
--
 /**********************************************************************************
  * Procedure Name   : get_warehouse_results_info
  * Description      : �O���q�ɓ��o�Ɏ��я�񒊏o �v���V�[�W�� (A-3)
  ***********************************************************************************/
  PROCEDURE get_warehouse_results_info(
    iv_process_object_info  IN  VARCHAR2,            -- �����Ώۏ��
    iv_report_post          IN  VARCHAR2,            -- �񍐕���
    iv_object_warehouse     IN  VARCHAR2,            -- �Ώۑq��
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_warehouse_results_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_no_lock          VARCHAR2(1);        -- ���b�N�擾�X�e�[�^�X
    In_not_cnt          NUMBER;             -- IF�w�b�_�폜�f�[�^�i�[�p�J�E���g
    ln_count            NUMBER;             -- IF���ב��݃f�[�^�����i�[
    lv_dspbuf           VARCHAR2(5000);     -- �f�[�^�E�_���v
    wk_sql              VARCHAR2(15000);
    ln_idx              NUMBER;             -- �f�[�^index
    lv_warn_flg         VARCHAR2(1);        -- �x�����ʃt���O
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ����z��No-�󒍃\�[�X�Q��-EOS�f�[�^��ʒP�ʂŃv���O�����X�V�����ŐV�̏��ȊO�͍폜
    CURSOR not_latest_request_id_cur
    IS
    SELECT  xshi_a.header_id                            --IF_H.�w�b�_ID
           ,xshi_a.request_id                           --IF_L.�v��ID
    FROM    xxwsh_shipping_headers_if xshi_a            --IF_H
           ,xxwsh_shipping_lines_if   xsli_a            --IF_L
           ,(SELECT xshi.delivery_no                    --IF_H.�z��No
                   ,xshi.order_source_ref               --IF_H.�󒍃\�[�X�Q��
                   ,xshi.eos_data_type                  --IF_H.EOS�f�[�^���
                   ,MAX(xshi.program_update_date) max_program_update_date --IF_H.�v���O�����X�V��
              FROM  xxwsh_shipping_headers_if  xshi     --IF_H
              GROUP BY xshi.delivery_no                 --IF_H.�z��No
                      ,xshi.order_source_ref            --IF_H.�󒍃\�[�X�Q��
                      ,xshi.eos_data_type               --IF_H.EOS�f�[�^���
            ) xshi_b
    WHERE   xshi_a.header_id = xsli_a.header_id
    AND     NVL(xshi_a.delivery_no,gv_delivery_no_null) = NVL(xshi_b.delivery_no,gv_delivery_no_null)
    AND     xshi_a.order_source_ref = xshi_b.order_source_ref
    AND     xshi_a.eos_data_type = xshi_b.eos_data_type
    AND     xshi_a.program_update_date <> xshi_b.max_program_update_date
    ORDER BY xshi_a.header_id
    FOR UPDATE OF xshi_a.header_id NOWAIT
    ;
--
    --IF�w�b�_�͑��݂��邪�AIF���ׂ����݂��Ȃ��ꍇ�A�x�����Z�b�g�����O�o�͂��܂��B
    CURSOR ifh_exists_ifm_not_cur
    IS
    SELECT xshi.header_id
          ,xshi.order_source_ref
    FROM   xxwsh_shipping_headers_if xshi
    WHERE NOT EXISTS (SELECT 'X'
                        FROM xxwsh_shipping_lines_if xsli
                       WHERE xshi.header_id = xsli.header_id)
    ;
--
    --IF���ׂ͑��݂��邪�A�w�b�_�����݂��Ȃ��ꍇ�A�x�����Z�b�g�����O�o�͂��܂��B
    CURSOR ifm_exists_ifh_not_cur
    IS
    SELECT xsli.line_id
          ,xsli.header_id
    FROM   xxwsh_shipping_lines_if xsli
    WHERE NOT EXISTS (SELECT 'X'
                        FROM xxwsh_shipping_headers_if xshi
                       WHERE xshi.header_id = xsli.header_id)
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- �ϐ�������
    In_not_cnt := 0;
    gr_line_not_header.delete;
    gr_header_id.delete;
    gr_request_id.delete;
    gr_order_source_ref.delete;
--
    BEGIN
      -- =============================================================
      -- ����z��No-�󒍃\�[�X�Q�ƒP�ʂŗv��ID���ŐV�̏��ȊO�͍폜
      -- =============================================================
      -- ���b�N�擾����
      OPEN not_latest_request_id_cur;
--
    EXCEPTION
--
      WHEN check_lock_expt THEN  -- ���b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn         -- 'XXWSH'
                                                       ,gv_msg_93a_003    -- �e�[�u�����b�N�G���[
                                                       ,gv_table_token    -- �g�[�N��'TABLE'
                                                       ,gv_if_table_jp)   -- �o�׈˗�IF�e�[�u��
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH not_latest_request_id_cur BULK COLLECT INTO gr_header_id,gr_request_id;
--
    gn_del_lines_cnt := gn_del_lines_cnt + gr_header_id.COUNT;
--
    -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)�폜
    <<not_latest_request_id_loop>>
    FORALL i IN 1 .. gr_header_id.COUNT
--
      DELETE FROM xxwsh_shipping_lines_if   xsli           --IF_L
      WHERE  xsli.header_id = gr_header_id(i)                 --IF_H.�w�b�_ID
      AND    xsli.request_id = gr_request_id(i)               --IF_L.�v��ID
      ;
--
     -- IF�w�b�_.�w�b�_ID�ɕR�Â�IF���׃f�[�^�����݂��邩�ۂ��̊m�F���s���B
     -- ���݂��Ȃ��ꍇ�A�폜�ΏۂƂ���B
    <<if_purge_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id.COUNT LOOP
--
      IF (i < gr_header_id.COUNT) THEN
        -- IF.�w�b�_ID�̔�r
        IF ((gr_header_id(i)) <> (gr_header_id(i+1))) THEN
--
            In_not_cnt :=In_not_cnt + 1;
            gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*         gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
        END IF;
--
      ELSE
          -- �ŏI�f�[�^�̏���
          In_not_cnt :=In_not_cnt + 1;
          gr_line_not_header(In_not_cnt) := gr_header_id(i);
--
--********** 2008/07/07 ********** DELETE START ***
--*       gn_del_headers_cnt := gn_del_headers_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
      END IF;
--
    END LOOP if_purge_ifm_not_loop;
--
    -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�폜
    <<if_purge_headers_del_loop>>
    FORALL i IN 1 .. gr_line_not_header.COUNT
--
      DELETE FROM xxwsh_shipping_headers_if xshi  --IF_H
      WHERE xshi.header_id = gr_line_not_header(i);
--
    -- �J�[�\���N���[�Y
    CLOSE not_latest_request_id_cur;
--
    -- =============================================================
    -- IF�w�b�_�ɑ��݂��邪�AIF���ׂɑ��݂��Ȃ��ꍇ
    -- �x�����Z�b�g�����O�o�͂��܂��B
    -- =============================================================
--
    gr_header_id.delete;
--
    OPEN ifh_exists_ifm_not_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH ifh_exists_ifm_not_cur BULK COLLECT INTO gr_header_id,gr_order_source_ref;
--
    <<ifh_exists_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id.COUNT LOOP
--
      lv_dspbuf := SUBSTRB( xxcmn_common_pkg.get_msg(
                     gv_msg_kbn          -- 'XXWSH'
                    ,gv_msg_93a_006 -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)�񑶍݃G���[���b�Z�[�W
                    ,gv_param1_token     -- �g�[�N��'param1'
                    ,gr_header_id(i)     -- �w�b�_ID
                    ,gv_param2_token          -- �g�[�N��'param2'
                    ,gr_order_source_ref(i))  -- IF_H.�󒍃\�[�X�Q��
                    ,1
                    ,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
      lv_warn_flg := gv_status_warn;
--
    END LOOP ifh_exists_ifm_not_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE ifh_exists_ifm_not_cur;
--
    -- =============================================================
    -- IF���ׂɑ��݂��邪�AIF�w�b�_�����݂��Ȃ��ꍇ
    -- �x�����Z�b�g�����O�o�͂��܂��B
    -- =============================================================
--
    -- ������
    gr_line_id.delete;
    gr_header_id.delete;
--
    OPEN ifm_exists_ifh_not_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH ifm_exists_ifh_not_cur BULK COLLECT INTO gr_line_id,gr_header_id;
--
    <<ifm_exists_ifh_not_loop>>
    FOR i IN 1 .. gr_line_id.COUNT LOOP
--
      lv_dspbuf := SUBSTRB( xxcmn_common_pkg.get_msg(
                     gv_msg_kbn          -- 'XXWSH'
                    ,gv_msg_93a_007 -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�񑶍݃G���[���b�Z�[�W
                    ,gv_param1_token     -- �g�[�N��'param1'
                    ,gr_line_id(i)          -- ����ID
                    ,gv_param2_token     -- �g�[�N��'param1'
                    ,gr_header_id(i))       -- �w�b�_ID
                    ,1
                    ,5000);
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
      lv_warn_flg := gv_status_warn;
--
    END LOOP ifm_exists_ifh_not_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE ifm_exists_ifh_not_cur;
--
    -- =============================================================
    -- �O���q�ɓ��o�Ɏ��я��擾
    -- =============================================================
    BEGIN
      -- ���b�N�擾����
      wk_sql := NULL;
      wk_sql := wk_sql || '  SELECT  ';
      wk_sql := wk_sql || '           xshi.party_site_code       AS party_site_code       ';  -- IF_H.�o�א�
      wk_sql := wk_sql || '          ,xshi.freight_carrier_code  AS freight_carrier_code  ';  -- IF_H.�^���Ǝ�
      wk_sql := wk_sql || '          ,xshi.shipping_method_code  AS shipping_method_code  ';  -- IF_H.�z���敪
      wk_sql := wk_sql || '          ,xshi.cust_po_number        AS cust_po_number        ';  -- IF_H.�ڋq����
      wk_sql := wk_sql || '          ,xshi.order_source_ref      AS order_source_ref      ';  -- IF_H.�󒍃\�[�X�Q��
      wk_sql := wk_sql || '          ,xshi.delivery_no           AS delivery_no           ';  -- IF_H.�z��No
      wk_sql := wk_sql || '          ,xshi.filler14              AS freight_charge_class  ';  -- IF_H.�^���敪
      wk_sql := wk_sql || '          ,xshi.collected_pallet_qty  AS collected_pallet_qty  ';  -- IF_H.�p���b�g�������
      wk_sql := wk_sql || '          ,xshi.location_code         AS location_code         ';  -- IF_H.�o�׌�
      wk_sql := wk_sql || '          ,xshi.arrival_time_from     AS arrival_time_from     ';  -- IF_H.���׎���FROM
      wk_sql := wk_sql || '          ,xshi.arrival_time_to       AS arrival_time_to       ';  -- IF_H.���׎���TO
      wk_sql := wk_sql || '          ,xshi.eos_data_type         AS eos_data_type         ';  -- IF_H.EOS�f�[�^���
      wk_sql := wk_sql || '          ,xshi.ship_to_location      AS ship_to_location      ';  -- IF_H.���ɑq��
      wk_sql := wk_sql || '          ,xshi.shipped_date          AS shipped_date          ';  -- IF_H.�o�ד�
      wk_sql := wk_sql || '          ,xshi.arrival_date          AS arrival_date          ';  -- IF_H.���ד�
      wk_sql := wk_sql || '          ,xshi.order_type            AS order_type            ';  -- IF_H.�󒍃^�C�v
      wk_sql := wk_sql || '          ,xshi.used_pallet_qty       AS used_pallet_qty       ';  -- IF_H.�p���b�g�g�p����
      wk_sql := wk_sql || '          ,xshi.report_post_code      AS report_post_code      ';  -- IF_H.�񍐕���
      wk_sql := wk_sql || '          ,xshi.header_id             AS header_id             ';  -- IF_H.�w�b�_ID
      wk_sql := wk_sql || '          ,xsli.line_id               AS line_id               ';  -- IF_L.����ID
      wk_sql := wk_sql || '          ,xsli.line_number           AS line_number           ';  -- IF_L.���הԍ�
      wk_sql := wk_sql || '          ,xsli.orderd_item_code      AS orderd_item_code      ';  -- IF_L.�󒍕i��
      wk_sql := wk_sql || '          ,xsli.orderd_quantity       AS orderd_quantity       ';  -- IF_L.����
      wk_sql := wk_sql || '          ,xsli.shiped_quantity       AS shiped_quantity       ';  -- IF_L.�o�׎��ѐ���
      wk_sql := wk_sql || '          ,xsli.ship_to_quantity      AS ship_to_quantity      ';  -- IF_L.���Ɏ��ѐ���
      wk_sql := wk_sql || '          ,xsli.lot_no                AS lot_no                ';  -- IF_L.���b�gNo
      wk_sql := wk_sql || '          ,xsli.designated_production_date AS designated_production_date   ';  -- IF_L.������
      wk_sql := wk_sql || '          ,xsli.use_by_date           AS use_by_date           ';  -- IF_L.�ܖ�����
      wk_sql := wk_sql || '          ,xsli.original_character    AS original_character    ';  -- IF_L.�ŗL�L��
      wk_sql := wk_sql || '          ,xsli.detailed_quantity     AS detailed_quantity     ';  -- IF_L.���󐔗�
      wk_sql := wk_sql || '          ,NULL                               ';  -- �i�ڋ敪
      wk_sql := wk_sql || '          ,NULL                               ';  -- ���i�敪
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.���b�g(���b�g�Ǘ��敪)
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.�d�ʗe�ϋ敪
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.�i��ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.�i�ڃR�[�h(�i��)
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.�P�[�X����
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.���o�Ɋ��Z�P��
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڃ}�X�^.�P��(�P��)
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.�q�ɕi��
      wk_sql := wk_sql || '          ,NULL                               ';  -- �ڋqID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �ڋq
      wk_sql := wk_sql || '          ,NULL                               ';  -- �o�א�ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �o�א�_����ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �^���Ǝ�ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �^���Ǝ�_����ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- ���b�gID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �o�׌�ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �o�Ɍ�ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- ���ɐ�ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �o�׈����Ώۃt���O
      wk_sql := wk_sql || '          ,NULL                               ';  -- �Ǌ����_
      wk_sql := wk_sql || '          ,NULL                               ';  -- �d����T�C�gID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �d����ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- �d����T�C�g��
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- �O���q��flag
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- �G���[flag
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- �ۗ�flag
      wk_sql := wk_sql || '          ,''' || gv_flg_off || ''''           ;  -- ���O�̂ݏo��flag
      wk_sql := wk_sql || '          ,NULL                               ';  -- ���b�Z�[�W
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.INV�i��ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.INV�i��ID
      wk_sql := wk_sql || '          ,NULL                               ';  -- OPM�i�ڏ��VIEW2.INV�i��(�q�ɕi��)
      wk_sql := wk_sql || '          ,NULL                               ';  -- �ڋq�敪(�o�א�)
      wk_sql := wk_sql || '     FROM  ';
      wk_sql := wk_sql || '           xxwsh_shipping_headers_if   xshi       ';  -- IF_H
      wk_sql := wk_sql || '           ,xxwsh_shipping_lines_if    xsli       ';  -- IF_L
      wk_sql := wk_sql || '     WHERE ';
      wk_sql := wk_sql || '           xshi.header_id = xsli.header_id        ';
      wk_sql := wk_sql || '     AND   xshi.data_type =  '''       || iv_process_object_info || '''';  -- IF_H.�f�[�^�^�C�v���p�����[�^.�����Ώۏ��
      IF TRIM(iv_report_post) IS NOT NULL THEN
        wk_sql := wk_sql || '     AND   xshi.report_post_code = ''' || iv_report_post || '''';          -- IF_H.�񍐕������p�����[�^.�񍐕���
      END IF;
         --200:�L���o�ו�,210:���_�o�׊m���,215:���o�׊m���,220:�ړ��o�Ɋm���  �̏ꍇ�A
         --IF_H.�o�׌�=�p�����[�^.�Ώۑq��
      wk_sql := wk_sql || '     AND  ((xshi.eos_data_type = ''' || gv_eos_data_cd_200 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_210 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_215 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_220 || ''')';
      wk_sql := wk_sql || '      OR  (xshi.eos_data_type = ''' || gv_eos_data_cd_230 || '''))';
         --IF_H.�o�׌�=�p�����[�^.�Ώۑq��
      IF TRIM(iv_object_warehouse) IS NOT NULL THEN
        wk_sql := wk_sql || '   AND  (xshi.location_code = ''' || iv_object_warehouse || ''')';
      END IF;
      wk_sql := wk_sql || '  ORDER BY ';
      wk_sql := wk_sql || '           delivery_no ';        -- IF H.�z��No
      wk_sql := wk_sql || '          ,order_source_ref ';   -- IF_H.�󒍃\�[�X�Q��
      wk_sql := wk_sql || '          ,eos_data_type ';      -- IF_H.EOS�f�[�^���
      wk_sql := wk_sql || '          ,header_id ';          -- IF_L.�w�b�_ID
      wk_sql := wk_sql || '          ,orderd_item_code ';   -- IF_L.�󒍕i��
      wk_sql := wk_sql || '          ,lot_no ';             -- IF_L.���b�gNo
      wk_sql := wk_sql || '  FOR UPDATE OF xsli.line_id,xshi.header_id NOWAIT ';
--
      EXECUTE IMMEDIATE wk_sql BULK COLLECT INTO gr_interface_info_rec ;
--
    EXCEPTION
--
      WHEN check_lock_expt THEN  -- ���b�N�ł��Ȃ�����
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn         -- 'XXWSH'
                                                       ,gv_msg_93a_003    -- �e�[�u�����b�N�G���[
                                                       ,gv_table_token    -- �g�[�N��'TABLE'
                                                       ,gv_if_table_jp)   -- �o�׈˗�IF�e�[�u��
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
--
    -- ���������̃Z�b�g
    gn_target_cnt := gr_interface_info_rec.COUNT;
--
    -- �f�[�^���Ȃ������ꍇ�͏I���X�e�[�^�X���G���[�Ƃ������𒆎~����
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn        -- 'XXWSH'
                                                    ,gv_msg_93a_004    -- �Ώۃf�[�^�Ȃ�
                                                    ,NULL              -- �g�[�N�� �Ȃ�
                                                    ,NULL)             --  �Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
--
    END IF;
--
    <<get_master_data_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      ln_idx := i;
      --------------------------
      -- �}�X�^(view)�f�[�^�擾
      --------------------------
      master_data_get(
        ln_idx,                   -- �f�[�^index
        lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       );
--
       IF (lv_retcode = gv_status_error) THEN
         RAISE global_api_expt;
       END IF;
--
    END LOOP get_master_data_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
    IF (lv_warn_flg = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
--
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN no_data_expt THEN                      --*** �Ώۃf�[�^�Ȃ� ***
      ov_errmsg  := lv_errmsg;                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( not_latest_request_id_cur%ISOPEN ) THEN
        CLOSE not_latest_request_id_cur;
      END IF;
      IF ( ifh_exists_ifm_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
      IF ( ifm_exists_ifh_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( not_latest_request_id_cur%ISOPEN ) THEN
        CLOSE not_latest_request_id_cur;
      END IF;
      IF ( ifh_exists_ifm_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
      IF ( ifm_exists_ifh_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( not_latest_request_id_cur%ISOPEN ) THEN
        CLOSE not_latest_request_id_cur;
      END IF;
      IF ( ifh_exists_ifm_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
      IF ( ifm_exists_ifh_not_cur%ISOPEN ) THEN
        CLOSE ifh_exists_ifm_not_cur;
      END IF;
--
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_warehouse_results_info;
--
 /**********************************************************************************
  * Procedure Name   : out_warehouse_number_check
  * Description      : �O���q�ɔ��ԃ`�F�b�N �v���V�[�W�� (A-4)
  ***********************************************************************************/
  PROCEDURE out_warehouse_number_check(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_warehouse_number_check'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    <<out_warehouse_number_check>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      -- �Ɩ���ʔ���
      -- EOS�f�[�^��� = 200 �L���o�ו�, 210 ���_�o�׊m���, 215 ���o�׊m���, 220 �ړ��o�Ɋm���
      -- �K�p�J�n���E�I�������o�ד��ɂĔ���
      IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
          (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
          (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
          (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
      THEN
--
        -- OPM�ۊǏꏊ�}�X�^�^�ۊǑq�ɃR�[�h���`�F�b�N
        SELECT COUNT(xilv2.inventory_location_id) cnt
        INTO   ln_count
        FROM   xxcmn_item_locations2_v xilv2
        WHERE  xilv2.segment1 = SUBSTRB(gr_interface_info_rec(i).order_source_ref, 1, 4)
        AND    xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).shipped_date) -- �g�D�L���J�n��
        AND    ((xilv2.date_to IS NULL)
         OR    (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).shipped_date)))  -- �g�D�L���I����
        AND    xilv2.disable_date IS NULL   -- ������
        ;
--
      END IF;
--
      -- EOS�f�[�^��� = 230:�ړ����Ɋm���
      -- �K�p�J�n���E�I�����𒅉ד��ɂĔ���
      IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
        -- OPM�ۊǏꏊ�}�X�^�^�ۊǑq�ɃR�[�h���`�F�b�N
        SELECT COUNT(xilv2.inventory_location_id) cnt
        INTO   ln_count
        FROM   xxcmn_item_locations2_v xilv2
        WHERE  xilv2.segment1 = SUBSTRB(gr_interface_info_rec(i).order_source_ref, 1, 4)
        AND    xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).arrival_date) -- �g�D�L���J�n��
        AND    ((xilv2.date_to IS NULL)
         OR    (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).arrival_date)))  -- �g�D�L���I����
        AND    xilv2.disable_date IS NULL   -- ������
        ;
--
      END IF;
--
      -- ���݂���ꍇ�́A�O���q�ɔ��ԂƂȂ�
      IF (ln_count > 0) THEN
--
        gr_interface_info_rec(i).out_warehouse_flg := gv_flg_on;
--
      END IF;
--
    END LOOP out_warehouse_number_check;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_warehouse_number_check;
--
 /**********************************************************************************
  * Procedure Name   : err_chk_delivno
  * Description      : �G���[�`�F�b�N_�z��No�P�� �v���V�[�W�� (A-5-1)
  ***********************************************************************************/
  PROCEDURE err_chk_delivno(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_delivno'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_delivery_no          xxwsh_shipping_headers_if.delivery_no%TYPE;          --IF_H.�z��No
    lt_order_source_ref     xxwsh_shipping_headers_if.order_source_ref%TYPE;     --IF_H.�󒍃\�[�X�Q��
    lt_freight_carrier_code xxwsh_shipping_headers_if.freight_carrier_code%TYPE; --IF_H.�^���Ǝ�
    lt_shipping_method_code xxwsh_shipping_headers_if.shipping_method_code%TYPE; --IF_H.�z���敪
    lt_shipped_date         xxwsh_shipping_headers_if.shipped_date%TYPE;         --IF_H.�o�ד�
    lt_arrival_date         xxwsh_shipping_headers_if.arrival_date%TYPE;         --IF_H.���ד�
    lt_freight_charge_class xxwsh_shipping_headers_if.filler14%TYPE;             --IF_H.�^���敪
    lv_msg_buff             VARCHAR2(5000);
    lv_dterr_flg            VARCHAR2(1) := '0';
    lv_date_msg             VARCHAR2(15);
    lv_error_flg            VARCHAR2(1);                          --�G���[flag
    ln_err_flg              NUMBER := 0;
--
    lt_product_date         ic_lots_mst.attribute1%TYPE;          --IF_L.�����N����
    lt_expiration_day       ic_lots_mst.attribute3%TYPE;          --IF_L.�ܖ�����
    lt_original_sign        ic_lots_mst.attribute2%TYPE;          --IF_L.�ŗL�L��
    lt_lot_no               ic_lots_mst.lot_no%TYPE;              --IF_L.���b�gNo
    lt_lot_id               ic_lots_mst.lot_id%TYPE;              --IF_L.���b�gid
    ld_search_date          DATE;                                 --IF_H.�o�ד�or���ד�
--
    ln_count                NUMBER;                               -- ���b�g�}�X�^�f�[�^�����i�[ 
--
    lv_search_product_date  ic_lots_mst.attribute1%TYPE;          --IF_L.�����N����
    ln_warehouse_count      NUMBER;
    ln_data_count           NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --����z��No�ŕ����̈ړ�No(�˗�No)�������R�[�h�̒l�`�F�b�N
    --�^���Ǝ�
    --�z���敪
    --�o�ד�
    --���ד�
    --���قȂ郌�R�[�h�����݂���ꍇ�G���[�Ƃ��܂��B
    <<deliveryno_many_move_id>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lt_delivery_no          := gr_interface_info_rec(i).delivery_no;           --IF_H.�z��No
      lt_freight_carrier_code := gr_interface_info_rec(i).freight_carrier_code;  --IF_H.�^���Ǝ�
      lt_shipping_method_code := gr_interface_info_rec(i).shipping_method_code;  --IF_H.�z���敪
      lt_shipped_date         := gr_interface_info_rec(i).shipped_date;          --IF_H.�o�ד�
      lt_arrival_date         := gr_interface_info_rec(i).arrival_date;          --IF_H.���ד�
      lt_freight_charge_class := NVL(gr_interface_info_rec(i).freight_charge_class,gv_include_exclude_0);  --IF_H.�^���敪
      lv_error_flg            := gr_interface_info_rec(i).err_flg;               -- �G���[�t���O
      lt_order_source_ref     := gr_interface_info_rec(i).order_source_ref;      --�󒍃\�[�X�Q��(�˗�/�ړ�No)
--
      IF (lv_error_flg = '0') THEN
--
        ln_err_flg := 0;
--
        -- �z��No���ݒ肳��Ă����ꍇ�A�󒍃\�[�X�Ɣz��No�̔��ԓ��e���`�F�b�N
        IF (gr_interface_info_rec(i).delivery_no IS NOT NULL)
        THEN
          -- �Ɩ���ʔ���
          -- EOS�f�[�^��� = 200 �L���o�ו�, 210 ���_�o�׊m���, 215 ���o�׊m���, 220 �ړ��o�Ɋm���
          -- �K�p�J�n���E�I�������o�ד��ɂĔ���
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
          THEN
            -- �o�ד����Z�b�g���܂��B
            ld_search_date := gr_interface_info_rec(i).shipped_date;
--
          -- EOS�f�[�^��� = 230:�ړ����Ɋm���
          ELSE
            -- ���ד����Z�b�g���܂��B
            ld_search_date := gr_interface_info_rec(i).arrival_date;
--
          END IF;
--
          -- OPM�ۊǏꏊ�}�X�^�^�ۊǑq�ɃR�[�h���`�F�b�N
          SELECT COUNT(xilv2.inventory_location_id) cnt
          INTO   ln_warehouse_count
          FROM   xxcmn_item_locations2_v xilv2
          WHERE  xilv2.segment1 = SUBSTRB(gr_interface_info_rec(i).delivery_no, 1, 4)
          AND    xilv2.date_from  <=  TRUNC(ld_search_date) -- �o��or���ד�
          AND    ((xilv2.date_to IS NULL)
           OR    (xilv2.date_to >= TRUNC(ld_search_date)))  -- �o��or���ד�
          AND    xilv2.disable_date IS NULL   -- ������
          ;
--
          -- �󒍃\�[�X�i�ƎҔ��ԁj�Ɣz��No            �̖���������ׁA�G���[
          -- �󒍃\�[�X            �Ɣz��No�i�ƎҔ��ԁj�̖���������ׁA�G���[
          IF ((ln_warehouse_count = 0) AND (gr_interface_info_rec(i).out_warehouse_flg =  gv_flg_on)) OR
             ((ln_warehouse_count > 0) AND (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on)) 
          THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                 -- 'XXWSH'
                          ,gv_msg_93a_153                             -- �z��No-�˗�/�ړ�No�֘A�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,gr_interface_info_rec(i).delivery_no       -- IF_H.�z��No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref  -- IF_H.�󒍃\�[�X�Q��(�˗�/�ړ�No)
                                                             )
                                                             ,1
                                                             ,5000);
--
            --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
            set_header_unit_reserveflg(
              gr_interface_info_rec(i).delivery_no,         -- �z��No
              gr_interface_info_rec(i).order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
              gr_interface_info_rec(i).eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- ���ьv��^�����������\�ȃf�[�^�����݂��邩�`�F�b�N
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- �O���q�Ɂi�w���Ȃ��j�ȊO�̏ꍇ�A�����\�ȃf�[�^�����݂��邩�`�F�b�N���s���B
        IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on)
        THEN
--
          -- �o��or�x��
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR        -- ���_�o�׊m���
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR        -- ���o�׊m���
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200))          -- �L���o�ו�
          THEN
--
            SELECT COUNT(xoha.request_no) item_cnt
            INTO   ln_data_count
            FROM   xxwsh_order_headers_all xoha
            -- ��H.�˗�No=���o����:�󒍃\�[�X�Q��
            WHERE  xoha.request_no = gr_interface_info_rec(i).order_source_ref
            -- �o�ׁF���ߍς� or �o�׎��ьv��ρ@�x���F��̍� or �x�����ьv���
            AND    xoha.req_status IN(gv_req_status_03,gv_req_status_04,gv_req_status_07,gv_req_status_08)
            AND    xoha.notif_status = gv_notif_status_40  -- �m��ʒm��
            AND    xoha.latest_external_flag = gv_yesno_y  -- �ŐV�t���O
            ;
--
          -- �ړ�
          ELSE
--
            SELECT COUNT(xmrih.mov_num) item_cnt
            INTO   ln_data_count
            FROM   xxinv_mov_req_instr_headers xmrih
            --�ړ�H.�ړ��ԍ�=���o����:�󒍃\�[�X�Q��
            WHERE  xmrih.mov_num = gr_interface_info_rec(i).order_source_ref
            --�˗��� or ������ or �o�ɕ񍐗L or ���ɕ񍐗L or ���o�ɕ񍐗L
            AND    xmrih.status IN(gv_mov_status_02,gv_mov_status_03,gv_mov_status_04,gv_mov_status_05,gv_mov_status_06)
            AND    xmrih.notif_status = gv_notif_status_40 --�m��ʒm��
            ;
--
          END IF;
--
          --�����\�Ȏw���f�[�^�����݂��Ȃ��ꍇ�A�G���[
          IF (ln_data_count = 0) THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                 -- 'XXWSH'
                          ,gv_msg_93a_154                             -- ���ьv��^�����s�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,gr_interface_info_rec(i).delivery_no       -- IF_H.�z��No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref  -- IF_H.�󒍃\�[�X�Q��(�˗�/�ړ�No)
                                                             )
                                                             ,1
                                                             ,5000);
--
            --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
            set_header_unit_reserveflg(
              gr_interface_info_rec(i).delivery_no,         -- �z��No
              gr_interface_info_rec(i).order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
              gr_interface_info_rec(i).eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- �ȉ��g�ݍ��킹�ȊO���G���[�Ƃ���
        -- �E�z��No��NULL�A�^���敪���ΏۊO(0)
        -- �E�z��No��NULL�A�^���敪���Ώ�  (1)
        IF NOT ((lt_delivery_no IS NULL)     AND (lt_freight_charge_class = gv_include_exclude_0)  OR
                (lt_delivery_no IS NOT NULL) AND (lt_freight_charge_class = gv_include_exclude_1)) THEN
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                                 -- 'XXWSH'
                        ,gv_msg_93a_148                             -- �z��No-�^���敪�g�����G���[���b�Z�[�W
                        ,gv_param1_token
                        ,lt_delivery_no                             -- IF_H.�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(i).order_source_ref  -- IF_H.�󒍃\�[�X�Q��(�˗�/�ړ�No)
                        ,gv_param3_token
                        ,lt_freight_charge_class                    -- IF_H.�^���敪
                                                           )
                                                           ,1
                                                           ,5000);
--
          --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
          set_header_unit_reserveflg(
            lt_delivery_no,         -- �z��No
            lt_order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
            gr_interface_info_rec(i).eos_data_type,  -- EOS�f�[�^���
            gv_err_class,           -- �G���[��ʁF�G���[
            lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          -- �G���[�t���O
          ln_err_flg := 1;
          -- �����X�e�[�^�X�F�x��
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
      --���b�g�Ǘ��i�̕K�{�`�F�b�N
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- �`�F�b�N�Ώۂ̓��b�g�Ǘ��i
        IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) THEN   --���b�g:�L(���b�g�Ǘ��i)
--
        -- �ȉ��̃p�^�[���ŕK�{���ڂɒl���Ȃ��ꍇ�A�G���[�Ƃ���
        -- �E���i�敪�����[�t   ���� �i�ڋ敪�����i�F                 IF_L.�ܖ����� ���� IF_L.�ŗL�L�� ���K�{
        -- �E���i�敪���h�����N ���� �i�ڋ敪�����i�FIF_L.������ ���� IF_L.�ܖ����� ���� IF_L.�ŗL�L�� ���K�{
        -- �E                        �i�ڋ敪�����i�FIF_L.���b�gNo ���K�{
          IF  ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)       AND   --���i�敪:���[�t
               (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5)       AND   --�i�ڋ敪�����i
               ((gr_interface_info_rec(i).use_by_date IS NULL)                 OR    --�ܖ�����
                (gr_interface_info_rec(i).original_character IS NULL)))              --�ŗL�L��
             OR
              ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2)       AND   --���i�敪:�h�����N
               (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5)       AND   --�i�ڋ敪�����i
               ((gr_interface_info_rec(i).designated_production_date IS NULL)  OR    --������
                (gr_interface_info_rec(i).use_by_date IS NULL)                 OR    --�ܖ�����
                (gr_interface_info_rec(i).original_character IS NULL)))              --�ŗL�L��
             OR
              ((gr_interface_info_rec(i).item_kbn_cd <> gv_item_kbn_cd_5)      AND   --�i�ڋ敪�����i
               (gr_interface_info_rec(i).lot_no IS NULL))                            --���b�gNo
          THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                 -- 'XXWSH'
                          ,gv_msg_93a_149                             -- ���b�g�Ǘ��i�̕K�{���ږ��ݒ�G���[
                          ,gv_param1_token
                          ,lt_delivery_no                             -- IF_H.�z��No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref  -- IF_H.�󒍃\�[�X�Q��(�˗�/�ړ�No)
                                                             )
                                                             ,1
                                                             ,5000);
--
            --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
            set_header_unit_reserveflg(
              lt_delivery_no,         -- �z��No
              lt_order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
              gr_interface_info_rec(i).eos_data_type,  -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
      --���b�g�}�X�^�����擾
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        -- �Ώۂ̓��b�g�Ǘ��i
        IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) THEN   --���b�g:�L(���b�g�Ǘ��i)
--
          -- �����Ɏg�p������t��ݒ�
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR  -- �L���o�ו�
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR  -- ���_�o�׊m���
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR  -- ���o�׊m���
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))    -- �ړ��o�Ɋm���
          THEN
--
            -- IF_H.�o�ד���ݒ�
            ld_search_date := gr_interface_info_rec(i).shipped_date;
--
          ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN  -- �ړ����Ɋm���
--
            -- IF_H.���ד���ݒ�
            ld_search_date := gr_interface_info_rec(i).arrival_date;
--
          END IF;
--
          -- �����ɊY�����錏�����擾
          -- ���i�敪�����[�t  �A�i�ڋ敪�����i�F            �ܖ������A�ŗL�L����KEY
          -- ���i�敪���h�����N�A�i�ڋ敪�����i�F�����N�����A�ܖ������A�ŗL�L����KEY
          --                     �i�ڋ敪�����i�F���b�gNo��KEY
          SELECT COUNT(ilm.lot_id) cnt
          INTO   ln_count
          FROM   ic_lots_mst ilm,
                 xxcmn_item_mst2_v ximv
          WHERE  ximv.item_id   = ilm.item_id                                -- �i��id
          AND    ximv.item_no   = gr_interface_info_rec(i).orderd_item_code  -- �󒍕i��
          AND    ximv.lot_ctl   = gv_lotkr_kbn_cd_1                          -- ���b�g�Ǘ��i
          AND    ((gr_interface_info_rec(i).designated_production_date IS NULL)   -- �����N����
                  OR
                  ((gr_interface_info_rec(i).designated_production_date IS NOT NULL)
                   AND (ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD'))))
          AND    ((gr_interface_info_rec(i).use_by_date IS NULL)                  -- �ܖ�����
                  OR
                  ((gr_interface_info_rec(i).use_by_date IS NOT NULL)
                  AND (ilm.attribute3 = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD'))))
          AND    ilm.attribute2 = NVL(gr_interface_info_rec(i).original_character,ilm.attribute2) -- �ŗL�L��   
          AND    ilm.lot_no     = NVL(gr_interface_info_rec(i).lot_no,ilm.lot_no)                 -- ���b�gNo
          AND    ximv.inactive_ind      <> gn_view_disable             -- �����t���O
          AND    ximv.obsolete_class    <> gv_view_disable             -- �p�~�敪
          AND    ximv.start_date_active <= TRUNC(ld_search_date)       -- �o��/���ד�
          AND    ximv.end_date_active   >= TRUNC(ld_search_date)       -- �o��/���ד�
          ;
--
          -- ���̒l�擾�r�p�k��KEY�Ɏg�p���邽�߃Z�b�g
          IF (gr_interface_info_rec(i).designated_production_date IS NULL)
          THEN
--
            lv_search_product_date := NULL;
          ELSE
--
            lv_search_product_date := TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD');
          END IF;
--
          -- �������ʂ�0���̏ꍇ
          IF (ln_count = 0) THEN
--
            -- ���[�t���i�̏ꍇ�A�����N����������KEY���O���čČ���
            IF  ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)       AND   --���i�敪:���[�t
                 (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5))            --�i�ڋ敪�����i
            THEN
--
              SELECT COUNT(ilm.lot_id) cnt
              INTO   ln_count
              FROM   ic_lots_mst ilm,
                     xxcmn_item_mst2_v ximv
              WHERE  ximv.item_id   = ilm.item_id                                -- �i��id
              AND    ximv.item_no   = gr_interface_info_rec(i).orderd_item_code  -- �󒍕i��
              AND    ximv.lot_ctl   = gv_lotkr_kbn_cd_1                          -- ���b�g�Ǘ��i
              AND    ((gr_interface_info_rec(i).use_by_date IS NULL)             -- �ܖ�����
                      OR
                      ((gr_interface_info_rec(i).use_by_date IS NOT NULL)
                      AND (ilm.attribute3 = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD'))))
              AND    ilm.attribute2 = NVL(gr_interface_info_rec(i).original_character,ilm.attribute2) -- �ŗL�L��   
              AND    ilm.lot_no     = NVL(gr_interface_info_rec(i).lot_no,ilm.lot_no)                 -- ���b�gNo
              AND    ximv.inactive_ind      <> gn_view_disable             -- �����t���O
              AND    ximv.obsolete_class    <> gv_view_disable             -- �p�~�敪
              AND    ximv.start_date_active <= TRUNC(ld_search_date)       -- �o��/���ד�
              AND    ximv.end_date_active   >= TRUNC(ld_search_date)       -- �o��/���ד�
              ;
--
              -- ���̒l�擾�r�p�k��KEY�Ɏg�p���邽�߃��Z�b�g
              lv_search_product_date := NULL;
--
            END IF;
--
          END IF;
--
          IF (ln_count = 0) THEN
--
            -- �f�[�^���擾�ł��Ȃ������ꍇ
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                           -- 'XXWSH'
                          ,gv_msg_93a_150                                       -- ���b�g�}�X�^�擾�G���[
                          ,gv_param1_token
                          ,lt_delivery_no                                       -- IF_H.�z��No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref            -- IF_H.�󒍃\�[�X�Q��(�˗�/�ړ�No)
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).orderd_item_code            -- IF_L.�󒍕i��
                          ,gv_param4_token
                          ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  -- IF_L.������
                          ,gv_param5_token
                          ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 -- IF_L.�ܖ�����
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).original_character          -- IF_L.�ŗL�L��
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).lot_no                      -- IF_L.���b�gNo
                                                             )
                                                             ,1
                                                             ,5000);
--
            --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
            set_header_unit_reserveflg(
              lt_delivery_no,         -- �z��No
              lt_order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
              gr_interface_info_rec(i).eos_data_type,  -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          ELSIF(ln_count > 1) THEN
--
            -- �������擾�����ꍇ
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn                                           -- 'XXWSH'
                            ,gv_msg_93a_151                                       -- ���b�g�}�X�^�擾�������G���[
                            ,gv_param1_token
                            ,lt_delivery_no                                       -- IF_H.�z��No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref            -- IF_H.�󒍃\�[�X�Q��(�˗�/�ړ�No)
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).orderd_item_code            -- IF_L.�󒍕i��
                            ,gv_param4_token
                            ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  -- IF_L.������
                            ,gv_param5_token
                            ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 -- IF_L.�ܖ�����
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).original_character          -- IF_L.�ŗL�L��
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).lot_no                      -- IF_L.���b�gNo
                                                               )
                                                               ,1
                                                               ,5000);
--
            --�z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
            set_header_unit_reserveflg(
              lt_delivery_no,         -- �z��No
              lt_order_source_ref,    -- �󒍃\�[�X�Q��(�˗�/�ړ�No)
              gr_interface_info_rec(i).eos_data_type,  -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          ELSE
--
            -- 1���������ꍇ�A���b�g�}�X�^�̓o�^�����擾
            SELECT ilm.attribute1  product_date    -- �����N����
                  ,ilm.attribute3  expiration_day  -- �ܖ�����
                  ,ilm.attribute2  original_sign   -- �ŗL�L��
                  ,ilm.lot_no      lot_no          -- ���b�gNo 
                  ,ilm.lot_id      lot_id          -- ���b�gID
            INTO   lt_product_date
                  ,lt_expiration_day
                  ,lt_original_sign
                  ,lt_lot_no
                  ,lt_lot_id
            FROM   ic_lots_mst ilm,
                   xxcmn_item_mst2_v ximv
            WHERE  ximv.item_id   = ilm.item_id                                -- �i��id
            AND    ximv.item_no   = gr_interface_info_rec(i).orderd_item_code  -- �󒍕i��
            AND    ximv.lot_ctl   = gv_lotkr_kbn_cd_1                          -- ���b�g�Ǘ��i
            AND    ((lv_search_product_date IS NULL)   -- �����N����
                    OR
                    ((lv_search_product_date IS NOT NULL)
                     AND (ilm.attribute1 = lv_search_product_date)))
            AND    ((gr_interface_info_rec(i).use_by_date IS NULL)                  -- �ܖ�����
                    OR
                    ((gr_interface_info_rec(i).use_by_date IS NOT NULL)
                    AND (ilm.attribute3 = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD'))))
            AND    ilm.attribute2 = NVL(gr_interface_info_rec(i).original_character,ilm.attribute2) -- �ŗL�L��   
            AND    ilm.lot_no     = NVL(gr_interface_info_rec(i).lot_no,ilm.lot_no)                 -- ���b�gNo
            AND    ximv.inactive_ind      <> gn_view_disable             -- �����t���O
            AND    ximv.obsolete_class    <> gv_view_disable             -- �p�~�敪
            AND    ximv.start_date_active <= TRUNC(ld_search_date)       -- �o��/���ד�
            AND    ximv.end_date_active   >= TRUNC(ld_search_date)       -- �o��/���ד�
            ;
--
            IF (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) THEN
--
              -- �i�ڋ敪�����i�̏ꍇ�A���b�gNo���擾
              gr_interface_info_rec(i).lot_no := lt_lot_no ;  -- ���b�gNo
              gr_interface_info_rec(i).lot_id := lt_lot_id ;  -- ���b�gID
--
            ELSE
--
              -- �i�ڋ敪�����i�̏ꍇ�A�������^�ܖ������^�ŗL�L�����擾
              gr_interface_info_rec(i).designated_production_date := FND_DATE.STRING_TO_DATE(lt_product_date,'YYYY/MM/DD') ;    -- ������
              gr_interface_info_rec(i).use_by_date                := FND_DATE.STRING_TO_DATE(lt_expiration_day,'YYYY/MM/DD') ;  -- �ܖ�����
              gr_interface_info_rec(i).original_character         := lt_original_sign ;            -- �ŗL�L��
              gr_interface_info_rec(i).lot_id                     := lt_lot_id ;                   -- ���b�gID
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      --�o�ד��^���ד��̖������t�`�F�b�N
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        ln_err_flg := 0;
--
        IF ((TRUNC(lt_shipped_date) > TRUNC(gd_sysdate)) AND (TRUNC(lt_arrival_date) > TRUNC(gd_sysdate))) THEN
--
          lv_dterr_flg := gv_date_chk_3;
--
        ELSIF (TRUNC(lt_shipped_date) > TRUNC(gd_sysdate)) THEN
--
          lv_dterr_flg := gv_date_chk_1;
--
        ELSIF (TRUNC(lt_arrival_date) > TRUNC(gd_sysdate)) THEN
--
          lv_dterr_flg := gv_date_chk_2;
--
        END IF;
--
        IF (lv_dterr_flg <> gv_date_chk_0) THEN
--
          CASE lv_dterr_flg
            WHEN gv_date_chk_1 THEN
              lv_date_msg := gv_date_para_1;
            WHEN gv_date_chk_2 THEN
              lv_date_msg := gv_date_para_2;
            WHEN gv_date_chk_3 THEN
              lv_date_msg := gv_date_para_1 || '/' || gv_date_para_2;
          END CASE;
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn         -- 'XXWSH'
                        ,gv_msg_93a_143     -- �������G���[���b�Z�[�W
                        ,gv_date_token
                        ,lv_date_msg
                        ,gv_param1_token
                        ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                        ,gv_param3_token
                        ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')  --IF_H.�o�ד�
                        ,gv_param4_token
                        ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')  --IF_H.���ד�
                                                           )
                                                           ,1
                                                           ,5000);
--
          --�z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
          set_deliveryno_unit_errflg(
            lt_delivery_no,         -- �z��No
            gr_interface_info_rec(i).eos_data_type,  -- EOS�f�[�^���
            gv_err_class,           -- �G���[��ʁF�G���[
            lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          -- �G���[�t���O
          ln_err_flg := 1;
          -- �����X�e�[�^�X�F�x��
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
--
--
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN

            --IF_H.�z��No�̓���`�F�b�N
            IF (lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) THEN
--
              IF ((lt_freight_carrier_code <> gr_interface_info_rec(i-1).freight_carrier_code) OR --IF_H.�^���Ǝ�
                  (lt_shipping_method_code <> gr_interface_info_rec(i-1).shipping_method_code) OR --IF_H.�z���敪
                  (lt_shipped_date         <> gr_interface_info_rec(i-1).shipped_date)         OR --IF_H.�o�ד�
                  (lt_arrival_date         <> gr_interface_info_rec(i-1).arrival_date))           --IF_H.���ד�
              THEN
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn         -- 'XXWSH'
                              ,gv_msg_93a_009  -- ����z��No���R�[�h�l�`�F�b�N�G���[���b�Z�[�W
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                              ,gv_param6_token
                              ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.�o�ד�
                              ,gv_param7_token
                              ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.���ד�
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                              ,gv_param9_token
                              ,gr_interface_info_rec(i).item_kbn_cd           --�i�ڋ敪
                                                                 )
                                                                 ,1
                                                                 ,5000);
--
                --�z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- �z��No
                  gr_interface_info_rec(i).eos_data_type,  -- EOS�f�[�^���
                  gv_err_class,           -- �G���[��ʁF�G���[
                  lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �G���[�t���O
                ln_err_flg := 1;
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP deliveryno_many_move_id;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END err_chk_delivno;
--
 /**********************************************************************************
  * Procedure Name   : err_chk_delivno_ordersrcref
  * Description      : �G���[�`�F�b�N_�z��No�󒍃\�[�X�Q�ƒP�� �v���V�[�W�� (A-5-2)
  ***********************************************************************************/
  PROCEDURE err_chk_delivno_ordersrcref(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_delivno_ordersrcref'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_delivery_no            xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.�z��No
    lt_order_source_ref       xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.�󒍃\�[�X�Q��
    lt_freight_charge_class   xxwsh_shipping_headers_if.filler14%TYPE;         --IF_H.�^���敪
    lt_orderd_item_code       xxwsh_shipping_lines_if.orderd_item_code%TYPE;   --IF_L.�󒍕i��
    lt_eos_data_type          xxwsh_shipping_headers_if.eos_data_type%TYPE;    --IF_H.EOS�f�[�^���
    lt_lot_no                 xxwsh_shipping_lines_if.lot_no%TYPE;             --IF_L.���b�gNo
    lt_weight_capacity_class  xxcmn_item_mst2_v.weight_capacity_class%TYPE;    --OPM�i�ڏ��VIEW2.�d�ʗe�ϋ敪
    lt_prod_kbn_cd            mtl_categories_b.segment1%TYPE;                  --���i�敪
    lt_item_kbn_cd            mtl_categories_b.segment1%TYPE;                  --�i�ڋ敪
    lv_product_cd             VARCHAR2(1);                                     --���i�̕i�ڃR�[�h
    lv_error_flg              VARCHAR2(1);                                     --�G���[flag
    ln_err_flg                NUMBER := 0;
    lv_msg_buff               VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ����z��No-�󒍃\�[�X�Q��-EOS�f�[�^��ʒP�ʂŁA�����̎󒍕i��-���b�gNo�����݂���ꍇ�A�G���[�Ƃ��x�����O�o�͂��܂��B
    <<deliveryno_src_manyitem>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lt_delivery_no           := gr_interface_info_rec(i).delivery_no;           -- IF_H.�z��No
      lt_order_source_ref      := gr_interface_info_rec(i).order_source_ref;      -- IF_H.�󒍃\�[�X�Q��
      lt_freight_charge_class  := gr_interface_info_rec(i).freight_charge_class;  -- IF_H.�^���敪
      lt_orderd_item_code      := gr_interface_info_rec(i).orderd_item_code;      -- IF_L.�󒍕i��
      lt_lot_no                := gr_interface_info_rec(i).lot_no;                -- IF_L.���b�gNo
      lt_eos_data_type         := gr_interface_info_rec(i).eos_data_type;         -- IF_H.EOS�f�[�^���
      lt_weight_capacity_class := gr_interface_info_rec(i).weight_capacity_class; -- �d�ʗe�ϋ敪
      lv_error_flg             := gr_interface_info_rec(i).err_flg;               -- �G���[�t���O
--
      IF (lv_error_flg = '0') THEN
--
        ln_err_flg := 0;
--
        --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN
--
            IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND        -- IF_H.�z��No
                (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND -- IF_H.�󒍃\�[�X�Q��
                (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type))       -- IF_H.EOS�f�[�^���
            THEN
--
              IF ((lt_orderd_item_code = gr_interface_info_rec(i-1).orderd_item_code) AND -- IF_L.�󒍕i��
                  (lt_lot_no = gr_interface_info_rec(i-1).lot_no))
              THEN
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn         -- 'XXWSH'
                              ,gv_msg_93a_005 -- ����˗�No/�ړ�No��ɓ���i�ڂ��������݃G���[���b�Z�[�W
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           -- IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.�󒍕i��
                              )
                              ,1
                              ,5000);
--
                -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- �z��No
                  lt_eos_data_type,       -- EOS�f�[�^���
                  gv_err_class,           -- �G���[��ʁF�G���[
                  lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �G���[�t���O
                ln_err_flg := 1;
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- ����z��No-�󒍃\�[�X�Q��-EOS�f�[�^��ʒP�ʂŁA���o���ځF�󒍕i�ڂɕR�Â�OPM�i�ڃ}�X�^.�d�ʗe�ϋ敪�̏d�ʂ�
      -- �e�ς����݂��Ă���΃G���[�Ƃ��܂��B
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN
--
            IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND        -- IF_H.�z��No
                (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND -- IF_H.�󒍃\�[�X�Q��
                (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type))       -- IF_H.EOS�f�[�^���
            THEN
              -- �d�ʗe�ϋ敪
              IF (lt_weight_capacity_class <> gr_interface_info_rec(i-1).weight_capacity_class) THEN
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_012  -- �d�ʗe�ϋ敪���݃G���[���b�Z�[�W
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           -- IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.�󒍕i��
                              )
                              ,1
                              ,5000);
--
                -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- �z��No
                  lt_eos_data_type,       -- EOS�f�[�^���
                  gv_err_class,           -- �G���[��ʁF�G���[
                  lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �G���[�t���O
                ln_err_flg := 1;
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- ����z��No-�󒍃\�[�X�Q��-EOS�f�[�^��ʒP�ʂŁA���o���ځF���i�敪�����݂��Ă���΃G���[�Ƃ��܂��B
--
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        lt_delivery_no          := gr_interface_info_rec(i).delivery_no;      -- IF_H.�z��No
        lt_order_source_ref     := gr_interface_info_rec(i).order_source_ref; -- IF_H.�󒍃\�[�X�Q��
        lt_eos_data_type        := gr_interface_info_rec(i).eos_data_type;    -- IF_H.EOS�f�[�^���
        lt_freight_charge_class := gr_interface_info_rec(i).freight_charge_class;  -- IF_H.�^���敪
        lt_orderd_item_code     := gr_interface_info_rec(i).orderd_item_code; -- IF_L.�󒍕i��
        lt_prod_kbn_cd          := gr_interface_info_rec(i).prod_kbn_cd;      -- ���i�敪
--
        --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
        IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
          IF (i >= 2) THEN
--
            IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND -- IF_H.�z��No
                (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND -- IF_H.�󒍃\�[�X�Q��
                (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type)) -- IF_H.EOS�f�[�^���
--
            THEN
--
              IF (lt_prod_kbn_cd <> gr_interface_info_rec(i-1).prod_kbn_cd) THEN   -- ���i�敪
--
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_013  -- ���i�敪���݃G���[���b�Z�[�W
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           -- IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.�󒍕i��
                              )
                              ,1
                              ,5000);
--
                -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- �z��No
                  lt_eos_data_type,       -- EOS�f�[�^���
                  gv_err_class,           -- �G���[��ʁF�G���[
                  lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �G���[�t���O
                ln_err_flg := 1;
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- EOS�f�[�^��ʁ��ړ��o�ɂ܂��͈ړ����ɂ̏ꍇ�A
      -- ����z��No-�󒍃\�[�X�Q�ƒP�ʂŁA���o���ځF�i�ڋ敪���A
      -- ���i�Ɛ��i�ȊO�����݂��Ă���΃G���[�Ƃ��܂��B
      -- ���i�̕i�ڋ敪�R�[�h���擾
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
        IF ((lt_eos_data_type = gv_eos_data_cd_220)  OR
            (lt_eos_data_type = gv_eos_data_cd_230))
        THEN
--
          lt_delivery_no        := gr_interface_info_rec(i).delivery_no;      --IF_H.�z��No
          lt_order_source_ref   := gr_interface_info_rec(i).order_source_ref; --IF_H.�󒍃\�[�X�Q��
          lt_eos_data_type      := gr_interface_info_rec(i).eos_data_type;    --IF_H.EOS�f�[�^���
          lt_freight_charge_class := gr_interface_info_rec(i).freight_charge_class;  -- IF_H.�^���敪
          lt_orderd_item_code   := gr_interface_info_rec(i).orderd_item_code; --IF_L.�󒍕i��
          lt_prod_kbn_cd        := gr_interface_info_rec(i).prod_kbn_cd;      --���i�敪
          lt_item_kbn_cd        := gr_interface_info_rec(i).item_kbn_cd;      --�i�ڋ敪
--
          --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
          IF (lt_freight_charge_class = gv_include_exclude_1) THEN
--
            IF (i >= 2) THEN
--
              IF ((lt_delivery_no = gr_interface_info_rec(i-1).delivery_no) AND    --IF_H.�z��No
                  (lt_order_source_ref = gr_interface_info_rec(i-1).order_source_ref) AND --IF_H.�󒍃\�[�X�Q��
                  (lt_eos_data_type = gr_interface_info_rec(i-1).eos_data_type)) --IF_H.EOS�f�[�^���
              THEN
--
                IF (((lt_item_kbn_cd = gv_item_kbn_cd_5) AND
                     (gr_interface_info_rec(i-1).item_kbn_cd <> gv_item_kbn_cd_5)) OR
                    ((lt_item_kbn_cd <> gv_item_kbn_cd_5) AND
                     (gr_interface_info_rec(i-1).item_kbn_cd = gv_item_kbn_cd_5)))
                THEN
--
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_014  -- �i�ڋ敪���݃G���[���b�Z�[�W
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).delivery_no           -- IF_H.�z��No
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.�󒍕i��
                                )
                                ,1
                                ,5000);
--
                  --�z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                  set_deliveryno_unit_errflg(
                    lt_delivery_no,         -- �z��No
                    lt_eos_data_type,       -- EOS�f�[�^���
                    gv_err_class,           -- �G���[��ʁF�G���[
                    lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                    lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
                  -- �G���[�t���O
                  ln_err_flg := 1;
                  -- �����X�e�[�^�X�F�x��
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      -- �o�Ɍ��������\�q�ɂłȂ���΃G���[�ɂ���
      IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
        IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
            (lt_eos_data_type = gv_eos_data_cd_215)) THEN    -- �o�ׂ̂݃`�F�b�N����
--
          IF (gr_interface_info_rec(i).allow_pickup_flag = '0') OR         -- �����s��
             (gr_interface_info_rec(i).allow_pickup_flag IS NULL) THEN
--
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                     -- 'XXWSH'
                          ,gv_msg_93a_144          -- �o�Ɍ������s�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,gr_interface_info_rec(i).delivery_no           -- IF_H.�z��No
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).location_code         -- IF_H.�o�Ɍ�
                          )
                          ,1
                          ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- �z��No
              lt_eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP deliveryno_src_manyitem;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END err_chk_delivno_ordersrcref;
--
 /**********************************************************************************
  * Procedure Name   : err_chk_line
  * Description      : �G���[�`�F�b�N_���גP�� �v���V�[�W�� (A-5-3)
  ***********************************************************************************/
  PROCEDURE err_chk_line(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_chk_line'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_eos_data_type           xxwsh_shipping_headers_if.eos_data_type%TYPE; -- IF_H.EOS�f�[�^���
    lt_delivery_no             xxwsh_shipping_headers_if.delivery_no%TYPE;   -- IF_H.�z��No
    lv_error_flg               VARCHAR2(1);                                  -- �G���[flag
    ln_cnt                     NUMBER;
    lv_inv_close_period        NUMBER;
    ln_err_flg                 NUMBER := 0;
    lv_msg_buff                VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<line_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lt_eos_data_type := gr_interface_info_rec(i).eos_data_type;         -- EOS�f�[�^���
      lt_delivery_no   := gr_interface_info_rec(i).delivery_no;           -- IF_H.�z��No
      lv_error_flg     := gr_interface_info_rec(i).err_flg;               -- �G���[�t���O
--
      IF (lv_error_flg = '0') THEN
--
        ln_err_flg := 0;
--
        -- �x�����O���q�ɔ��Ԃ̏ꍇ�G���[�Ƃ��܂��B
        IF ((lt_eos_data_type = gv_eos_data_cd_200) AND
            (gr_interface_info_rec(i).out_warehouse_flg = gv_flg_on))
        THEN
--
          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn          -- 'XXWSH'
                        ,gv_msg_93a_008  -- �Ɩ���ʃX�e�[�^�X�`�F�b�N�G���[���b�Z�[�W
                        ,gv_param1_token
                        ,gr_interface_info_rec(i).delivery_no           -- IF_H.�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(i).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                        )
                        ,1
                        ,5000);
--
          -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
          set_deliveryno_unit_errflg(
            lt_delivery_no,         -- �z��No
            lt_eos_data_type,       -- EOS�f�[�^���
            gv_err_class,           -- �G���[��ʁF�G���[
            lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          -- �G���[�t���O
          ln_err_flg := 1;
          -- �����X�e�[�^�X�F�x��
          ov_retcode := gv_status_warn;
--
        END IF;
--
      END IF;
--
      -- �ړ��o�ɂ܂��͈ړ����ɂ̏ꍇ�A�}�X�^�`�F�b�N�A�z��No-�ړ�No�̑g�ݍ��킹�̃`�F�b�N
      IF ((lt_eos_data_type = gv_eos_data_cd_220)  OR
          (lt_eos_data_type = gv_eos_data_cd_230))
      THEN
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          IF (lt_eos_data_type = gv_eos_data_cd_220) THEN
--
            --�}�X�^�`�F�b�N[�o�׌�]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɃR�[�h
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).location_code
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).shipped_date)   -- �g�D�L���J�n��
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).shipped_date))) -- �g�D�L���I����
              AND  xil2v_a.disable_date  IS NULL   -- ������
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN
--
            --�}�X�^�`�F�b�N[�o�׌�]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɃR�[�h
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).location_code
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).arrival_date)   -- �g�D�L���J�n��
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).arrival_date))) -- �g�D�L���I����
              AND  xil2v_a.disable_date  IS NULL   -- ������
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,gv_param1_token05_nm                           --�G���[���ږ�
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                          )
                          ,1
                          ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- �z��No
              lt_eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- �^���Ǝҁ�NULL�̏ꍇ�̂݃`�F�b�N���܂��B
          IF (TRIM(gr_interface_info_rec(i).freight_carrier_code) IS NOT NULL) THEN
--
            -- �}�X�^�`�F�b�N[�^���Ǝ�]
            IF (lt_eos_data_type = gv_eos_data_cd_220) THEN     -- �ړ��o��
--
              SELECT COUNT(xcv.party_number) item_cnt
              INTO   ln_cnt
              FROM   xxcmn_carriers2_v xcv
              WHERE  xcv.party_number = gr_interface_info_rec(i).freight_carrier_code --�^���Ǝҏ��VIEW2.�g�D�ԍ�
              AND    xcv.start_date_active <= gr_interface_info_rec(i).shipped_date   --�K�p�J�n��<=�o�ד�
              AND    xcv.end_date_active >= gr_interface_info_rec(i).shipped_date     --�K�p�I����>=�o�ד�
              ;
--
            ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN  -- �ړ�����
--
              SELECT COUNT(xcv.party_number) item_cnt
              INTO   ln_cnt
              FROM   xxcmn_carriers2_v xcv
              WHERE  xcv.party_number = gr_interface_info_rec(i).freight_carrier_code --�^���Ǝҏ��VIEW2.�g�D�ԍ�
              AND    xcv.start_date_active <= gr_interface_info_rec(i).arrival_date   --�K�p�J�n��<=���ד�
              AND    xcv.end_date_active >= gr_interface_info_rec(i).arrival_date     --�K�p�I����>=���ד�
              ;
--
            END IF;
--
            IF (ln_cnt = 0) THEN
--
              -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                            ,gv_param1_token
                            ,gv_param1_token06_nm                           --�G���[���ږ�
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                            )
                            ,1
                            ,5000);
--
              -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- �z��No
                lt_eos_data_type,       -- EOS�f�[�^���
                gv_err_class,           -- �G���[��ʁF�G���[
                lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �G���[�t���O
              ln_err_flg := 1;
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          --�}�X�^�`�F�b�N[�󒍕i��]
          IF (lt_eos_data_type = gv_eos_data_cd_220) THEN     --�ړ��o��
--
            SELECT COUNT(ximv.item_no) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_mst2_v ximv
            WHERE  ximv.item_no = gr_interface_info_rec(i).orderd_item_code --OPM�i�ڏ��VIEW2.�i�ڃR�[�h
            AND    ximv.start_date_active <= gr_interface_info_rec(i).shipped_date --�K�p�J�n��<=�o�ד�
            AND    ximv.end_date_active >= ximv.end_date_active                    --�K�p�I����>=�o�ד�
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN  --�ړ�����
--
            SELECT COUNT(ximv.item_no) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_mst2_v ximv
            WHERE  ximv.item_no = gr_interface_info_rec(i).orderd_item_code --OPM�i�ڏ��VIEW2.�i�ڃR�[�h
            AND ximv.start_date_active <= gr_interface_info_rec(i).arrival_date --�K�p�J�n��<=���ד�
            AND ximv.end_date_active >= gr_interface_info_rec(i).arrival_date   --�K�p�I����>=���ד�
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,gv_param1_token07_nm                           --�G���[���ږ�
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                          )
                          ,1
                          ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- �z��No
              lt_eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          IF (lt_eos_data_type = gv_eos_data_cd_220) THEN
--
            -- �}�X�^�`�F�b�N[���ɑq��]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɃR�[�h
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).ship_to_location
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).shipped_date)   -- �g�D�L���J�n��
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).shipped_date))) -- �g�D�L���I����
              AND  xil2v_a.disable_date  IS NULL   -- ������
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_230) THEN
--
            -- �}�X�^�`�F�b�N[���ɑq��]
            SELECT COUNT(xil2v_a.segment1) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_item_locations2_v    xil2v_a
            -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɃR�[�h
            WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).ship_to_location
              AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).arrival_date)   -- �g�D�L���J�n��
              AND  ((xil2v_a.date_to IS NULL)
               OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).arrival_date))) -- �g�D�L���I����
              AND  xil2v_a.disable_date  IS NULL   -- ������
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                            gv_msg_kbn          -- 'XXWSH'
                           ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                           ,gv_param1_token
                           ,gv_param1_token08_nm                           --�G���[���ږ�
                           ,gv_param2_token
                           ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                           ,gv_param3_token
                           ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                           ,gv_param4_token
                           ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                           ,gv_param5_token
                           ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                           ,gv_param6_token
                           ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                           ,gv_param7_token
                           ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                           ,gv_param8_token
                           ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                           ,gv_param9_token
                           ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                           ,gv_param10_token
                           ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                           )
                           ,1
                           ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- �z��No
              lt_eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
          IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
            -- �}�X�^�`�F�b�N[�z���敪]
            SELECT COUNT(xlvv.lookup_code) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_lookup_values_v  xlvv
            WHERE  xlvv.lookup_type = gv_ship_method_type
            AND    xlvv.lookup_code = gr_interface_info_rec(i).shipping_method_code
            ;
--
            IF (ln_cnt = 0) THEN
--
              -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                            ,gv_param1_token
                            ,gv_param1_token09_nm                           --�G���[���ږ�
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                            )
                            ,1
                            ,5000);
--
              -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- �z��No
                lt_eos_data_type,       -- EOS�f�[�^���
                gv_err_class,           -- �G���[��ʁF�G���[
                lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �G���[�t���O
              ln_err_flg := 1;
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- �z��No�ƈړ�No�̑g�ݍ��킹�`�F�b�N�B(�O���q�ɔ��Ԃ̏ꍇ���{���Ȃ�)
          IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on) THEN
--
            --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
            IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
              SELECT COUNT(xmrih.mov_num) item_cnt
              INTO   ln_cnt
              FROM   xxinv_mov_req_instr_headers  xmrih
              WHERE  xmrih.mov_num = gr_interface_info_rec(i).order_source_ref --�ړ�H.�ړ��ԍ�
              AND    xmrih.shipped_locat_code = gr_interface_info_rec(i).location_code    --�ړ�H.�o�Ɍ��ۊǏꏊ
              AND    xmrih.ship_to_locat_code = gr_interface_info_rec(i).ship_to_location --�ړ�H.���ɐ�ۊǏꏊ
              AND    xmrih.delivery_no = gr_interface_info_rec(i).delivery_no  --�ړ�H.�z��No
              AND    xmrih.status     <> gv_mov_status_99                      --�ړ�H.�X�e�[�^�X<>���
              ;
--
              IF (ln_cnt = 0) THEN
--
                -- ���݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_011  -- �g�����Ǝw���`�F�b�N�G���[���b�Z�[�W
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                              )
                              ,1
                              ,5000);
--
                -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- �z��No
                  lt_eos_data_type,       -- EOS�f�[�^���
                  gv_err_class,           -- �G���[��ʁF�G���[
                  lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �G���[�t���O
                ln_err_flg := 1;
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF; -- �ړ��o�ɂ܂��͈ړ����ɂ̏ꍇ�A�}�X�^�`�F�b�N�A�z��No-�ړ�No�̑g�ݍ��킹�̃`�F�b�N
--
      -- �o�ɂ܂��͎x���̏ꍇ�A�}�X�^�`�F�b�N�A�z��No-�˗�No�̑g�ݍ��킹�̃`�F�b�N
      IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
          (lt_eos_data_type = gv_eos_data_cd_215)  OR
          (lt_eos_data_type = gv_eos_data_cd_200))
      THEN
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- �}�X�^�`�F�b�N[�o�׌�]
          SELECT COUNT(xil2v_a.segment1) item_cnt
          INTO   ln_cnt
          FROM   xxcmn_item_locations2_v    xil2v_a
          -- OPM�ۊǏꏊ���VIEW.�ۊǑq�ɃR�[�h
          WHERE  xil2v_a.segment1   = gr_interface_info_rec(i).location_code
            AND  xil2v_a.date_from <= TRUNC(gr_interface_info_rec(i).shipped_date)   -- �g�D�L���J�n��
            AND  ((xil2v_a.date_to IS NULL)
             OR  (xil2v_a.date_to  >= TRUNC(gr_interface_info_rec(i).shipped_date))) -- �g�D�L���I����
            AND  xil2v_a.disable_date  IS NULL   -- ������
          ;
--
          IF (ln_cnt = 0) THEN
--
            -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn                                     -- 'XXWSH'
                          ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,gv_param1_token05_nm                           --�G���[���ږ�
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                          )
                          ,1
                          ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- �z��No
              lt_eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- �}�X�^�`�F�b�N[�o�א�]
          IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
              (lt_eos_data_type = gv_eos_data_cd_215))
          THEN
--
            SELECT COUNT(xpsv.party_site_id) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_party_sites2_v xpsv
            WHERE  xpsv.party_site_number = gr_interface_info_rec(i).party_site_code --�p�[�e�B�T�C�g���VIEW2.�p�[�e�B�T�C�gID
            AND    xpsv.start_date_active <= gr_interface_info_rec(i).shipped_date   --�K�p�J�n��<=�o�ד�
            AND    xpsv.end_date_active   >= gr_interface_info_rec(i).shipped_date   --�K�p�I����>=�o�ד�
            ;
--
          ELSIF (lt_eos_data_type = gv_eos_data_cd_200) THEN  --�x��
--
            SELECT COUNT(xvsv.vendor_site_code) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_vendor_sites2_v xvsv
            WHERE  xvsv.vendor_site_code = gr_interface_info_rec(i).party_site_code  --�d����T�C�g���VIEW2
            AND    xvsv.start_date_active <= gr_interface_info_rec(i).shipped_date   --�K�p�J�n��<=�o�ד�
            AND    xvsv.end_date_active   >= gr_interface_info_rec(i).shipped_date   --�K�p�I����>=�o�ד�
            ;
--
          END IF;
--
          IF (ln_cnt = 0) THEN
--
            -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                          ,gv_param1_token
--********** 2008/08/01 ********** MODIFY START ***
--                          ,gv_param1_token05_nm                           --�G���[���ږ�
                          ,gv_param1_token10_nm                           --�G���[���ږ�
--********** 2008/08/01 ********** MODIFY START ***
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_H����.�󒍕i��
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                          )
                          ,1
                          ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- �z��No
              lt_eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- �^���Ǝҁ�NULL�̏ꍇ�̂݃`�F�b�N���܂��B
          IF (TRIM(gr_interface_info_rec(i).freight_carrier_code) IS NOT NULL) THEN
--
            -- �}�X�^�`�F�b�N[�^���Ǝ�]
            SELECT COUNT(xcv.party_number) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_carriers2_v xcv
            WHERE  xcv.party_number = gr_interface_info_rec(i).freight_carrier_code  --�^���Ǝҏ��VIEW2.�g�D�ԍ�
            AND    xcv.start_date_active <= gr_interface_info_rec(i).shipped_date    --�K�p�J�n��<=�o�ד�
            AND    xcv.end_date_active   >= gr_interface_info_rec(i).shipped_date    --�K�p�I����>=�o�ד�
            ;
--
            IF (ln_cnt = 0) THEN
--
              -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                            ,gv_param1_token
                            ,gv_param1_token06_nm                           --�G���[���ږ�
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L����.�󒍕i��
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                            )
                            ,1
                            ,5000);
--
              -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- �z��No
                lt_eos_data_type,       -- EOS�f�[�^���
                gv_err_class,           -- �G���[��ʁF�G���[
                lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �G���[�t���O
              ln_err_flg := 1;
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- �}�X�^�`�F�b�N[�󒍕i��]
          SELECT COUNT(ximv.item_no) item_cnt
          INTO   ln_cnt
          FROM   xxcmn_item_mst2_v ximv
          WHERE  ximv.item_no = gr_interface_info_rec(i).orderd_item_code --OPM�i�ڏ��VIEW2.�i�ڃR�[�h
          AND    ximv.start_date_active <= gr_interface_info_rec(i).shipped_date  --�K�p�J�n��<=�o�ד�
          AND    ximv.end_date_active   >= gr_interface_info_rec(i).shipped_date  --�K�p�I����>=�o�ד�
          ;
--
          IF (ln_cnt = 0) THEN
--
            -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,gv_param1_token07_nm                           --�G���[���ږ�
                          ,gv_param2_token
                          ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                          ,gv_param6_token
                          ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                          ,gv_param7_token
                          ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                          ,gv_param8_token
                          ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                          ,gv_param9_token
                          ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                          ,gv_param10_token
                          ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                          )
                          ,1
                          ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_deliveryno_unit_errflg(
              lt_delivery_no,         -- �z��No
              lt_eos_data_type,       -- EOS�f�[�^���
              gv_err_class,           -- �G���[��ʁF�G���[
              lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �G���[�t���O
            ln_err_flg := 1;
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
          IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
            -- �}�X�^�`�F�b�N[�z���敪]
            SELECT COUNT(xlvv.lookup_code) item_cnt
            INTO   ln_cnt
            FROM   xxcmn_lookup_values_v  xlvv
            WHERE  xlvv.lookup_type = gv_ship_method_type
            AND    xlvv.lookup_code = gr_interface_info_rec(i).shipping_method_code
            ;
--
            IF (ln_cnt = 0) THEN
--
              -- �}�X�^�ɑ��݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_010  -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
                            ,gv_param1_token
                            ,gv_param1_token09_nm                           --�G���[���ږ�
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                            ,gv_param6_token
                            ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                            ,gv_param7_token
                            ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                            ,gv_param8_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                            ,gv_param9_token
                            ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                            ,gv_param10_token
                            ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                            )
                            ,1
                            ,5000);
--
              -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- �z��No
                lt_eos_data_type,       -- EOS�f�[�^���
                gv_err_class,           -- �G���[��ʁF�G���[
                lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �G���[�t���O
              ln_err_flg := 1;
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
--
          -- �z��No�ƈړ�No�̑g�ݍ��킹�`�F�b�N�B(�O���q�ɔ��Ԃ̏ꍇ���{���Ȃ�)
          IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on) THEN
--
            --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
            IF (gr_interface_info_rec(i).freight_charge_class = gv_include_exclude_1) THEN
--
              SELECT COUNT(xoha.request_no) item_cnt
              INTO   ln_cnt
              FROM   xxwsh_order_headers_all  xoha
              WHERE  xoha.request_no   = gr_interface_info_rec(i).order_source_ref  --��H.�˗�No
              AND    xoha.deliver_from = gr_interface_info_rec(i).location_code     --��H.�o�׌��ۊǏꏊ
              AND    xoha.delivery_no  = gr_interface_info_rec(i).delivery_no       --��H.�z��No
              AND    xoha.latest_external_flag = gv_yesno_y                         --�ŐV�t���O
              ;
--
              IF (ln_cnt = 0) THEN
--
                -- ���݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_011  -- �g�����Ǝw���`�F�b�N�G���[���b�Z�[�W
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).location_code         --IF_H.�o�׌�
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).ship_to_location      --IF_H.���ɑq��
                              )
                              ,1
                              ,5000);
--
                -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- �z��No
                  lt_eos_data_type,       -- EOS�f�[�^���
                  gv_err_class,           -- �G���[��ʁF�G���[
                  lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �G���[�t���O
                ln_err_flg := 1;
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- ���o���ځFEOS�f�[�^��ʁ��L���o�ו񍐁@����
          -- �󒍃w�b�_�A�h�I��.�L�����z�m��敪=�m��̏ꍇ�A�G���[�Ƃ��܂��B
          IF (lt_eos_data_type = gv_eos_data_cd_200) THEN  --�x��
--
            IF (gr_interface_info_rec(i).out_warehouse_flg <> gv_flg_on) THEN
--
              SELECT COUNT(xoha.request_no) item_cnt
              INTO   ln_cnt
              FROM   xxwsh_order_headers_all  xoha
              --��H.�˗�No
              WHERE  xoha.request_no           = gr_interface_info_rec(i).order_source_ref
              AND    xoha.amount_fix_class     = gv_amount_fix_1  --��H.�L�����z�m��敪=�m��
              AND    xoha.latest_external_flag = gv_yesno_y       --�ŐV�t���O
              ;
--
              IF (ln_cnt <> 0) THEN
--
                -- ���݂��Ȃ���΁A�z��No�P�ʂɃG���[flag���Z�b�g
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_015  -- �L�����z�m��敪�m��G���[���b�Z�[�W
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.�󒍕i��
                              )
                              ,1
                              ,5000);
--
                -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
                set_deliveryno_unit_errflg(
                  lt_delivery_no,         -- �z��No
                  lt_eos_data_type,       -- EOS�f�[�^���
                  gv_err_class,           -- �G���[��ʁF�G���[
                  lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �G���[�t���O
                ln_err_flg := 1;
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
        --OPM�݌ɉ�v����CLOSE�N���`�F�b�N
        lv_inv_close_period := xxcmn_common_pkg.get_opminv_close_period;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- �o��or�x��
          IF ((lt_eos_data_type = gv_eos_data_cd_200) OR
              (lt_eos_data_type = gv_eos_data_cd_210) OR
              (lt_eos_data_type = gv_eos_data_cd_215))
          THEN
--
            --�o�ד�
            IF (FND_DATE.STRING_TO_DATE(lv_inv_close_period,'YYYY/MM') >= gr_interface_info_rec(i).shipped_date)
            THEN
--
              -- �݌ɉ�v���Ԃ�CLOSE�Ȃ̂ŁA���O���o�͂��A�z��No�P�ʂɃG���[���Z�b�g
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_016  -- �݌ɉ�v����CLOSE�G���[
                            ,gv_param1_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                            ,gv_param3_token
                            ,lv_inv_close_period          --OPM�݌ɉ�v����CLOSE�N���擾�֐��̖߂�l
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                            ,gv_param5_token
                            ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.�o�ד�
                            ,gv_param6_token
                            ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.���ד�
                            )
                            ,1
                            ,5000);
--
              -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- �z��No
                lt_eos_data_type,       -- EOS�f�[�^���
                gv_err_class,           -- �G���[��ʁF�G���[
                lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �G���[�t���O
              ln_err_flg := 1;
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        IF ((ln_err_flg = 0) AND (lv_error_flg = '0')) THEN
          -- �ړ��o��or�ړ�����
          IF ((lt_eos_data_type = gv_eos_data_cd_220)  OR
              (lt_eos_data_type = gv_eos_data_cd_230))
          THEN
--
            -- �o�ד�/���ד�
            IF ((FND_DATE.STRING_TO_DATE(lv_inv_close_period,'YYYY/MM') >= gr_interface_info_rec(i).shipped_date) OR
                (FND_DATE.STRING_TO_DATE(lv_inv_close_period,'YYYY/MM') >= gr_interface_info_rec(i).arrival_date))
            THEN
--
              -- �݌ɉ�v���Ԃ�CLOSE�Ȃ̂ŁA���O���o�͂��A�z��No�P�ʂɃG���[���Z�b�g
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_016  -- �݌ɉ�v����CLOSE�G���[
                            ,gv_param1_token
                            ,gr_interface_info_rec(i).delivery_no      --IF_H.�z��No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref --IF_H.�󒍃\�[�X�Q��
                            ,gv_param3_token
                            ,lv_inv_close_period                    --OPM�݌ɉ�v����CLS�N���擾�ߒl
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type    --IF_H.EOS�f�[�^���
                            ,gv_param5_token
                            ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')     --IF_H.�o�ד�
                            ,gv_param6_token
                            ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')     --IF_H.���ד�
                            )
                            ,1
                            ,5000);
--
              -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
              set_deliveryno_unit_errflg(
                lt_delivery_no,         -- �z��No
                lt_eos_data_type,       -- EOS�f�[�^���
                gv_err_class,           -- �G���[��ʁF�G���[
                lv_msg_buff,            -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �G���[�t���O
              ln_err_flg := 1;
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF; --�o�ɂ܂��͎x���̏ꍇ�A�}�X�^�`�F�b�N�A�z��No-�˗�No�̑g�ݍ��킹�̃`�F�b�N
--
    END LOOP line_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END err_chk_line;
--
 /**********************************************************************************
  * Procedure Name   : appropriate_check
  * Description      : �Ó��`�F�b�N �v���V�[�W�� (A-6)
  ***********************************************************************************/
  PROCEDURE appropriate_check(
    ov_errbuf               OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'appropriate_check'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt                         NUMBER;
    ln_cnt2                        NUMBER;
    ln_errflg                      NUMBER;
    wk_sql                         VARCHAR2(9000);
    lv_error_flg                   VARCHAR2(1);                    --�G���[flag
    ld_todate_1                    DATE;             -- DATE�^�`�F�b�N�p
    ld_todate_2                    DATE;             -- DATE�^�`�F�b�N�p
    lv_msg_buff                    VARCHAR2(5000);
--
    -- IF_H.EOS�f�[�^���
    lt_eos_data_type               xxwsh_shipping_headers_if.eos_data_type%TYPE;
    -- �o�ɗ\���
    lt_mov_schedule_ship_date      xxinv_mov_req_instr_headers.schedule_ship_date%TYPE;
    -- �o�Ɏ��ѓ�
    lt_mov_actual_ship_date        xxinv_mov_req_instr_headers.actual_ship_date%TYPE;
    -- ���ɗ\���
    lt_mov_schedule_arrival_date   xxinv_mov_req_instr_headers.schedule_arrival_date%TYPE;
    -- ���Ɏ��ѓ�
    lt_mov_actual_arrival_date     xxinv_mov_req_instr_headers.actual_arrival_date%TYPE;
    -- �^���Ǝ�
    lt_mov_freight_code            xxinv_mov_req_instr_headers.freight_carrier_code%TYPE;
    -- �^���Ǝ�_����
    lt_mov_actual_freight_code     xxinv_mov_req_instr_headers.actual_freight_carrier_code%TYPE;
    -- �z���敪
    lt_mov_shipping_code           xxinv_mov_req_instr_headers.shipping_method_code%TYPE;
    -- �z���敪_����
    lt_mov_actual_shipping_code    xxinv_mov_req_instr_headers.actual_shipping_method_code%TYPE;
    -- �z��No
    lt_mov_delivery_no             xxinv_mov_req_instr_headers.delivery_no%TYPE;
    -- �ړ��ԍ�
    lt_mov_num                     xxinv_mov_req_instr_headers.mov_num%TYPE;
    -- �o�ח\���
    lt_req_schedule_ship_date      xxwsh_order_headers_all.schedule_ship_date%TYPE;
    -- �o�ד�
    lt_req_shipped_date            xxwsh_order_headers_all.shipped_date%TYPE;
    -- ���ח\���
    lt_req_schedule_arrival_date   xxwsh_order_headers_all.schedule_arrival_date%TYPE;
    -- ���ד�
    lt_req_arrival_date            xxwsh_order_headers_all.arrival_date%TYPE;
    -- �^���Ǝ�
    lt_req_freight_code            xxwsh_order_headers_all.freight_carrier_code%TYPE;
    -- �^���Ǝ�_����
    lt_req_result_freight_code     xxwsh_order_headers_all.result_freight_carrier_code%TYPE;
    -- �z���敪
    lt_req_shipping_code           xxwsh_order_headers_all.shipping_method_code%TYPE;
    -- �z���敪_����
    lt_req_result_shipping_code    xxwsh_order_headers_all.result_shipping_method_code%TYPE;
    -- �o�א�
    lt_req_deliver_to              xxwsh_order_headers_all.deliver_to%TYPE;
    -- �o�א�_����ID
    lt_req_result_deliver_to       xxwsh_order_headers_all.result_deliver_to%TYPE;
    -- �z��No
    lt_req_delivery_no             xxwsh_order_headers_all.delivery_no%TYPE;
    -- �˗�No
    lt_request_no                  xxwsh_order_headers_all.request_no%TYPE;
    -- IF_H.�p���b�g�������
    lt_collected_pallet_qty        xxwsh_shipping_headers_if.collected_pallet_qty%TYPE;
    -- IF_H.�p���b�g�g�p����
    lt_used_pallet_qty             xxwsh_shipping_headers_if.used_pallet_qty%TYPE;
    -- IF_L.�o�׎��ѐ���
    lt_shiped_quantity             xxwsh_shipping_lines_if.shiped_quantity%TYPE;
    -- IF_L.���󐔗�(�C���^�t�F�[�X�p)
    lt_detailed_quantity           xxwsh_shipping_lines_if.detailed_quantity%TYPE;
--
    lt_product_date                ic_lots_mst.attribute1%TYPE;                     --�����N����
    lt_expiration_day              ic_lots_mst.attribute3%TYPE;                     --�ܖ�����
    lt_original_sign               ic_lots_mst.attribute2%TYPE;                     --�ŗL�L��
    lt_lot_status                  ic_lots_mst.attribute23%TYPE;                    --���b�g�X�e�[�^�X
--
    lt_delivery_no                 xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.�z��No
    lt_order_source_ref            xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.�󒍃\�[�X�Q��
--
    lt_vendor_site_code            xxwsh_order_headers_all.vendor_site_code%TYPE;   --�����T�C�g
    lt_pay_provision_rel           xxcmn_lot_status_v.pay_provision_rel%TYPE;       --�L���x��(����)
    lt_move_inst_rel               xxcmn_lot_status_v.move_inst_rel%TYPE;           --�ړ��w��(����)
    lt_ship_req_rel                xxcmn_lot_status_v.ship_req_rel%TYPE;            --�o�׈˗�(����)
    ln_lot_err_flg                 NUMBER;
    lv_error_flag                  VARCHAR2(1) := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_lots_product_check
      (
      iv_orderd_item_code         xxwsh_shipping_lines_if.orderd_item_code%TYPE,    -- �󒍕i��
      iv_lot_no                   xxwsh_shipping_lines_if.lot_no%TYPE,              -- ���b�gNo
      iv_prod_kbn_cd              VARCHAR2,                                         -- ���i�敪
      iv_item_kbn_cd              VARCHAR2,                                         -- �i�ڋ敪
      id_date                     DATE                                              -- �o��/���ד�
      )
    IS
      SELECT ilm.attribute1  product_date    --�����N����
            ,ilm.attribute3  expiration_day  --�ܖ�����
            ,ilm.attribute2  original_sign   --�ŗL�L��
      FROM   xxcmn_item_categories5_v xicv,
             ic_lots_mst ilm,
             xxcmn_item_mst2_v ximv
      WHERE  xicv.item_id = ilm.item_id
      AND    xicv.item_id = ximv.item_id
      AND    ximv.item_no = iv_orderd_item_code         -- �󒍕i��
      AND    ilm.lot_no   = iv_lot_no                   -- ���b�gNo
      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1           -- ���b�g�Ǘ��i
      AND    xicv.prod_class_code = iv_prod_kbn_cd      -- ���i�敪
      AND    xicv.item_class_code = iv_item_kbn_cd      -- �i�ڋ敪
      AND    ximv.inactive_ind   <> gn_view_disable     -- �����t���O
      AND    ximv.obsolete_class <> gv_view_disable     -- �p�~�敪
      AND    ximv.start_date_active <= TRUNC(id_date)   -- �o��/���ד�
      AND    ximv.end_date_active   >= TRUNC(id_date)   -- �o��/���ד�
      ;
--
/*
--  3.4.��p
    CURSOR cur_lots_product_check2
      (
      iv_orderd_item_code         xxwsh_shipping_lines_if.orderd_item_code%TYPE,    -- �󒍕i��
      iv_lot_no                   xxwsh_shipping_lines_if.lot_no%TYPE,              -- ���b�gNo
      iv_prod_kbn_cd              VARCHAR2,                                         -- ���i�敪
      iv_item_kbn_cd              VARCHAR2,                                         -- �i�ڋ敪
      id_date                     DATE                                              -- �o��/���ד�
      )
    IS
      SELECT ilm.attribute1  product_date    --�����N����
            ,ilm.attribute3  expiration_day  --�ܖ�����
            ,ilm.attribute2  original_sign   --�ŗL�L��
      FROM   xxcmn_item_categories5_v xicv,
             ic_lots_mst ilm,
             xxcmn_item_mst2_v ximv
      WHERE  xicv.item_id = ilm.item_id
      AND    xicv.item_id = ximv.item_id
      AND    ximv.item_no = iv_orderd_item_code         -- �󒍕i��
      AND    ilm.lot_no   = iv_lot_no                   -- ���b�gNo
      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1           -- ���b�g�Ǘ��i
      AND    xicv.prod_class_code = iv_prod_kbn_cd      -- ���i�敪
      AND    xicv.item_class_code <> iv_item_kbn_cd     -- �i�ڋ敪       --<>�ɂȂ��Ă���
      AND    ximv.inactive_ind   <> gn_view_disable     -- �����t���O
      AND    ximv.obsolete_class <> gv_view_disable     -- �p�~�敪
      AND    ximv.start_date_active <= TRUNC(id_date)   -- �o��/���ד�
      AND    ximv.end_date_active   >= TRUNC(id_date)   -- �o��/���ד�
      ;
*/
--
    CURSOR cur_lots_status_check
      (
      iv_orderd_item_code             xxwsh_shipping_lines_if.orderd_item_code%TYPE,            -- �󒍕i��
      iv_lot_no                       xxwsh_shipping_lines_if.lot_no%TYPE,                      -- ���b�gNo
      id_designated_production_date   xxwsh_shipping_lines_if.designated_production_date%TYPE,  -- ������
      iv_original_character           xxwsh_shipping_lines_if.original_character%TYPE,          -- �ŗL�L��
      id_date                         DATE                                                      -- �o��/���ד�
      )
    IS
      SELECT ilm.attribute3  expiration_day    --�ܖ�����
            ,ilm.attribute2  original_sign     --�ŗL�L��
            ,ilm.attribute23 lot_status        --���b�g�X�e�[�^�X
      FROM   xxcmn_item_categories5_v xicv,
             ic_lots_mst ilm,
             xxcmn_item_mst2_v ximv
      WHERE  xicv.item_id = ilm.item_id
      AND    xicv.item_id = ximv.item_id
      AND    ximv.item_no = iv_orderd_item_code                                     -- �󒍕i��
      AND    ilm.lot_no   = iv_lot_no                                               -- ���b�gNo
      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                       -- ���b�g�Ǘ��i
      AND    ilm.attribute1 = TO_CHAR(id_designated_production_date,'YYYY/MM/DD')   -- ������
      AND    ilm.attribute2 = iv_original_character                                 -- �ŗL�L��
      AND    ximv.inactive_ind   <> gn_view_disable                                 -- �����t���O
      AND    ximv.obsolete_class <> gv_view_disable                                 -- �p�~�敪
      AND    ximv.start_date_active <= TRUNC(id_date)                               -- �o��/���ד�
      AND    ximv.end_date_active   >= TRUNC(id_date)                               -- �o��/���ד�
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
--     AA VARCHAR2(30) ;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<appropriate_chk_line_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
--      AA := gr_interface_info_rec(i).orderd_item_code;
--
      lt_eos_data_type    := gr_interface_info_rec(i).eos_data_type;
      lv_error_flg        := gr_interface_info_rec(i).err_flg;                  --�G���[�t���O
      lt_delivery_no      := gr_interface_info_rec(i).delivery_no;              --�z��No
      lt_order_source_ref := gr_interface_info_rec(i).order_source_ref;         --�󒍃\�[�X�Q��
--
      IF (lv_error_flg = '0') THEN
--
        ln_errflg := 0;
--
        -- 1.
        -- 1.1 �w���̍��ڂƎ��т̍��ڂ��r���A�w����̎��э��ڂɒl���ݒ肳��Ă���ꍇ�́A
        --     �w���f�[�^��̎w�����ڂƎ��э��ڂ��r���܂��B(�ړ��o��or�ړ�����)
        IF ((lt_eos_data_type = gv_eos_data_cd_220) OR (lt_eos_data_type = gv_eos_data_cd_230)) THEN
--
          SELECT COUNT(xmrih.mov_num) item_cnt
          INTO   ln_cnt
          FROM   xxinv_mov_req_instr_headers xmrih
          WHERE  xmrih.mov_num = gr_interface_info_rec(i).order_source_ref --�ړ�H.�ړ��ԍ�=���o����:�󒍃\�[�X�Q��
          --������or�˗���
          AND    ((xmrih.status = gv_mov_status_03) OR (xmrih.status = gv_mov_status_02))
          --�m��ʒm��
          AND    xmrih.notif_status = gv_notif_status_40
          ;
--
          -- �w�b�_���x���Ȃ̂łP��
          IF (ln_cnt > 0) THEN
--
            SELECT xmrih.schedule_ship_date           --�o�ɗ\���
                  ,xmrih.actual_ship_date             --�o�Ɏ��ѓ�
                  ,xmrih.schedule_arrival_date        --���ɗ\���
                  ,xmrih.actual_arrival_date          --���Ɏ��ѓ�
                  ,xmrih.freight_carrier_code         --�^���Ǝ�
                  ,xmrih.actual_freight_carrier_code  --�^���Ǝ�_����
                  ,xmrih.shipping_method_code         --�z���敪
                  ,xmrih.actual_shipping_method_code  --�z���敪_����
                  ,xmrih.delivery_no                  --�z��No
                  ,xmrih.mov_num                      --�ړ��ԍ�
            INTO   lt_mov_schedule_ship_date          --�o�ɗ\���
                  ,lt_mov_actual_ship_date            --�o�Ɏ��ѓ�
                  ,lt_mov_schedule_arrival_date       --���ɗ\���
                  ,lt_mov_actual_arrival_date         --���Ɏ��ѓ�
                  ,lt_mov_freight_code                --�^���Ǝ�
                  ,lt_mov_actual_freight_code         --�^���Ǝ�_����
                  ,lt_mov_shipping_code               --�z���敪
                  ,lt_mov_actual_shipping_code        --�z���敪_����
                  ,lt_mov_delivery_no                 --�z��No
                  ,lt_mov_num                         --�ړ��ԍ�
            FROM  xxinv_mov_req_instr_headers xmrih
            -- �ړ�H.�ړ��ԍ�=���o����:�󒍃\�[�X�Q��
            WHERE xmrih.mov_num = gr_interface_info_rec(i).order_source_ref
            -- ������or�˗���
            AND   ((xmrih.status = gv_mov_status_03) OR (xmrih.status = gv_mov_status_02))
            -- �m��ʒm��
            AND   xmrih.notif_status = gv_notif_status_40
            AND   ROWNUM=1
            ;
--
            -- �o�ɗ\����A���o����:�o�ד��A�o�Ɏ��ѓ��̔�r
            IF (lt_mov_schedule_ship_date <> gr_interface_info_rec(i).shipped_date) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_ship_date IS NOT NULL) THEN
--
              IF (lt_mov_schedule_ship_date <> lt_mov_actual_ship_date) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            -- ���ɗ\����A���o����:���ד��A���Ɏ��ѓ��̔�r
            IF (lt_mov_schedule_arrival_date <> gr_interface_info_rec(i).arrival_date) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_arrival_date IS NOT NULL) THEN
--
              IF (lt_mov_schedule_arrival_date <> lt_mov_actual_arrival_date) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            -- �^���ƎҁA���o����:�^���ƎҁA�^���Ǝ�_���т̔�r
            IF (lt_mov_freight_code <> gr_interface_info_rec(i).freight_carrier_code) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_freight_code IS NOT NULL) THEN
--
              IF (lt_mov_freight_code <> lt_mov_actual_freight_code) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            -- �z���敪�A���o����:�z���敪�A�z���敪_���т̔�r
            IF (NVL(lt_mov_shipping_code,gv_delivery_no_null) <> NVL(gr_interface_info_rec(i).shipping_method_code,gv_delivery_no_null)) THEN
--
              ln_errflg := 1;
--
            ELSIF (lt_mov_actual_shipping_code IS NOT NULL) THEN
--
              IF (lt_mov_shipping_code <> lt_mov_actual_shipping_code) THEN
                ln_errflg := 1;
              END IF;
--
            END IF;
--
            IF (ln_errflg = 1) THEN
--
              -- ���O�o��
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                              gv_msg_kbn          -- 'XXWSH'
                             ,gv_msg_93a_017  -- �Ó��`�F�b�N�G���[���b�Z�[�W(�ړ��\����ьx��)
                             ,gv_param1_token
                             ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                             ,gv_param2_token
                             ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                             ,gv_param3_token
                             ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                             ,gv_param4_token
                             ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.�o�ד�
                             ,gv_param5_token
                             ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.���ד�
                             ,gv_param6_token
                             ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                             ,gv_param7_token
                             ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                             )
                             ,1
                             ,5000);
--
              -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
              set_header_unit_reserveflg(
                lt_delivery_no,       -- �z��No
                lt_order_source_ref,  -- �ړ�No/�˗�No
                lt_eos_data_type,     -- EOS�f�[�^���
                gv_reserved_class,    -- �G���[��ʁF�ۗ�
                lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
        -- 2.
        -- 2.1 �w���̍��ڂƎ��т̍��ڂ��r���A�w����̎��э��ڂɒl���ݒ肳��Ă���ꍇ�́A
        --     �w���f�[�^��̎w�����ڂƎ��э��ڂ��r���܂��B(�o��or�x��)
--
        IF (ln_errflg = 0) THEN
--
          -- �o��or�x��
          IF ((lt_eos_data_type = gv_eos_data_cd_210) OR        -- ���_�o�׊m���
              (lt_eos_data_type = gv_eos_data_cd_215) OR        -- ���o�׊m���
              (lt_eos_data_type = gv_eos_data_cd_200))          -- �L���o�ו�
          THEN
--
            SELECT COUNT(xoha.request_no) item_cnt
            INTO   ln_cnt
            FROM   xxwsh_order_headers_all xoha
            -- ��H.�˗�No=���o����:�󒍃\�[�X�Q��
            WHERE  xoha.request_no = gr_interface_info_rec(i).order_source_ref
            -- ���ߍς�or��̍ς�
            AND    ((xoha.req_status = gv_req_status_03) OR (xoha.req_status = gv_req_status_07))
            AND    xoha.notif_status = gv_notif_status_40 -- �m��ʒm��
            AND    xoha.latest_external_flag = gv_yesno_y -- �ŐV�t���O
            ;
--
            -- �w�b�_���x���Ȃ̂łP��
            IF (ln_cnt > 0) THEN
--
              SELECT xoha.schedule_ship_date             --�o�ח\���
                    ,xoha.shipped_date                   --�o�ד�
                    ,xoha.schedule_arrival_date          --���ח\���
                    ,xoha.arrival_date                   --���ד�
                    ,xoha.freight_carrier_code           --�^���Ǝ�
                    ,xoha.result_freight_carrier_code    --�^���Ǝ�_����
                    ,xoha.shipping_method_code           --�z���敪
                    ,xoha.result_shipping_method_code    --�z���敪_����
                    ,xoha.deliver_to                     --�o�א�
                    ,xoha.result_deliver_to              --�o�א�_����
                    ,xoha.delivery_no                    --�z��No
                    ,xoha.request_no                     --�˗�No
                    ,xoha.vendor_site_code               --�����T�C�g
              INTO   lt_req_schedule_ship_date           --�o�ח\���
                    ,lt_req_shipped_date                 --�o�ד�
                    ,lt_req_schedule_arrival_date        --���ח\���
                    ,lt_req_arrival_date                 --���ד�
                    ,lt_req_freight_code                 --�^���Ǝ�
                    ,lt_req_result_freight_code          --�^���Ǝ�_����
                    ,lt_req_shipping_code                --�z���敪
                    ,lt_req_result_shipping_code         --�z���敪_����
                    ,lt_req_deliver_to                   --�o�א�
                    ,lt_req_result_deliver_to            --�o�א�_����
                    ,lt_req_delivery_no                  --�z��No
                    ,lt_request_no                       --�˗�No
                    ,lt_vendor_site_code                 --�����T�C�g
              FROM   xxwsh_order_headers_all xoha
              -- ��H.�˗�No=���o����:�󒍃\�[�X�Q��
              WHERE  xoha.request_no = gr_interface_info_rec(i).order_source_ref
              -- ���ߍς�or��̍ς�
              AND    ((xoha.req_status = gv_req_status_03) OR (xoha.req_status = gv_req_status_07))
              AND    xoha.notif_status = gv_notif_status_40 -- �m��ʒm��
              AND    xoha.latest_external_flag = gv_yesno_y -- �ŐV�t���O
              AND    ROWNUM=1
              ;
--
              -- �o�ח\����A���o����:�o�ד��A�o�ד��̔�r
              IF (lt_req_schedule_ship_date <> gr_interface_info_rec(i).shipped_date) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_shipped_date IS NOT NULL) THEN
--
                IF (lt_req_schedule_ship_date <> lt_req_shipped_date) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- ���ח\����A���o����:���ד��A���ד��̔�r
              IF (lt_req_schedule_arrival_date <> gr_interface_info_rec(i).arrival_date) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_arrival_date IS NOT NULL) THEN
--
                IF (lt_req_schedule_arrival_date <> lt_req_arrival_date) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- �^���ƎҁA���o����:�^���ƎҁA�^���Ǝ�_���т̔�r
              IF (lt_req_freight_code <> gr_interface_info_rec(i).freight_carrier_code) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_result_freight_code IS NOT NULL) THEN
--
                IF (lt_req_freight_code <> lt_req_result_freight_code) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- �z���敪�A���o����:�z���敪�A�z���敪_���т̔�r
              IF (NVL(lt_req_shipping_code,gv_delivery_no_null) <> NVL(gr_interface_info_rec(i).shipping_method_code,gv_delivery_no_null)) THEN
--
                ln_errflg := 1;
--
              ELSIF (lt_req_result_shipping_code IS NOT NULL) THEN
--
                IF (lt_req_shipping_code <> lt_req_result_shipping_code) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              -- �o�א�A���o����:�o�א�A�o�א�_���т̔�r
              -- �o��
              -- ���_�o�׊m��� or ���o�׊m���
              IF ((lt_eos_data_type = gv_eos_data_cd_210)  OR
                  (lt_eos_data_type = gv_eos_data_cd_215)) THEN
--
                IF (lt_req_deliver_to <> gr_interface_info_rec(i).party_site_code) THEN
--
                  ln_errflg := 1;
--
                ELSIF (lt_req_result_deliver_to IS NOT NULL) THEN
--
                  IF (lt_req_deliver_to <> lt_req_result_deliver_to) THEN
                    ln_errflg := 1;
                  END IF;
--
                END IF;
--
              END IF;
--
              -- �x�����̔�r
              IF (lt_eos_data_type <> gv_eos_data_cd_200) THEN  -- �L���o�ו�
--
                IF (lt_vendor_site_code <> gr_interface_info_rec(i).party_site_code) THEN
                  ln_errflg := 1;
                END IF;
--
              END IF;
--
              IF (ln_errflg = 1) THEN
--
                -- ���O�o��
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_018 -- �Ó��`�F�b�N�G���[���b�Z�[�W(�o�׎x���\����ьx��)
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                              ,gv_param4_token
                              ,TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD')          --IF_H.�o�ד�
                              ,gv_param5_token
                              ,TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD')          --IF_H.���ד�
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).freight_carrier_code  --IF_H.�^���Ǝ�
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).shipping_method_code  --IF_H.�z���敪
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).party_site_code       --IF_H.�o�א�
                              )
                              ,1
                              ,5000);
--
                -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- �z��No
                  lt_order_source_ref,  -- �ړ�No/�˗�No
                  lt_eos_data_type,     -- EOS�f�[�^���
                  gv_reserved_class,    -- �G���[��ʁF�ۗ�
                  lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF; --err
--
            END IF;
--
          END IF; --EOS
--
        END IF;
--
        IF (ln_errflg = 0) THEN
--
          -- 4.���ʍ��ڂ̑Ó����`�F�b�N
          -- IF_H.�p���b�g�������
          lt_collected_pallet_qty := gr_interface_info_rec(i).collected_pallet_qty;
          -- IF_H.�p���b�g�g�p����
          lt_used_pallet_qty      := gr_interface_info_rec(i).used_pallet_qty;
          -- IF_L.�o�׎��ѐ���
          lt_shiped_quantity      := gr_interface_info_rec(i).shiped_quantity;
          -- IF_L.���󐔗�(�C���^�t�F�[�X�p)
          lt_detailed_quantity    := gr_interface_info_rec(i).detailed_quantity;
--
          -- �p���b�g�������
          IF (lt_collected_pallet_qty IS NOT NULL) THEN
--
            IF (lt_collected_pallet_qty < 0) THEN
--
              ln_errflg := 1;
--
              -- ���O�o��
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn          -- 'XXWSH'
                            ,gv_msg_93a_022  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ʍ��ڃG���[)
                            ,gv_param1_token
                            ,gv_param1_token01_nm
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                            ,gv_param5_token
                            ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                            )
                            ,1
                            ,5000);
--
              -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
              set_header_unit_reserveflg(
                lt_delivery_no,       -- �z��No
                lt_order_source_ref,  -- �ړ�No/�˗�No
                lt_eos_data_type,     -- EOS�f�[�^���
                gv_reserved_class,    -- �G���[��ʁF�ۗ�
                lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
          IF (ln_errflg = 0) THEN
--
            -- �p���b�g�g�p����
            IF (lt_used_pallet_qty IS NOT NULL) THEN
--
              IF (lt_used_pallet_qty < 0) THEN
--
                ln_errflg := 1;
--
                -- ���O�o��
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_022  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ʍ��ڃG���[)
                              ,gv_param1_token
                              ,gv_param1_token02_nm
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                              )
                              ,1
                              ,5000);
--
                -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- �z��No
                  lt_order_source_ref,  -- �ړ�No/�˗�No
                  lt_eos_data_type,     -- EOS�f�[�^���
                  gv_reserved_class,    -- �G���[��ʁF�ۗ�
                  lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
          IF (ln_errflg = 0) THEN
--
            -- �o�׎��ѐ���
            IF (lt_shiped_quantity IS NOT NULL) THEN
--
              IF (lt_shiped_quantity < 0) THEN
--
                ln_errflg := 1;
--
                -- ���O�o��
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_022  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ʍ��ڃG���[)
                              ,gv_param1_token
                              ,gv_param1_token03_nm
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                              )
                              ,1
                              ,5000);
--
                -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- �z��No
                  lt_order_source_ref,  -- �ړ�No/�˗�No
                  lt_eos_data_type,     -- EOS�f�[�^���
                  gv_reserved_class,    -- �G���[��ʁF�ۗ�
                  lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
          IF (ln_errflg = 0) THEN
--
            -- ���󐔗�(�C���^�t�F�[�X�p)
            IF (lt_detailed_quantity IS NOT NULL) THEN
--
              IF (lt_detailed_quantity < 0) THEN
--
                ln_errflg := 1;
--
                -- ���O�o��
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_022  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ʍ��ڃG���[)
                              ,gv_param1_token
                              ,gv_param1_token04_nm
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).delivery_no           --IF_H.�z��No
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).order_source_ref      --IF_H.�󒍃\�[�X�Q��
                              ,gv_param4_token
                              ,gr_interface_info_rec(i).eos_data_type         --IF_H.EOS�f�[�^���
                              ,gv_param5_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                              )
                              ,1
                              ,5000);
--
                -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- �z��No
                  lt_order_source_ref,  -- �ړ�No/�˗�No
                  lt_eos_data_type,     -- EOS�f�[�^���
                  gv_reserved_class,    -- �G���[��ʁF�ۗ�
                  lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;
--
          END IF;
--
        END IF;
--
        -- 3.  ���b�g���o�A�X�e�[�^�X�`�F�b�N
        -- 3.1 �h�����N,���i,���b�g�Ǘ��i
--
        IF (ln_errflg = 0) THEN
--
          IF ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2) AND --���i�敪:�h�����N
              (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) AND --�i�ڋ敪:���i
              (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1))   --���b�g:�L(���b�g�Ǘ��i)
          THEN
--
            IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
            THEN
              OPEN cur_lots_product_check
              (
               gr_interface_info_rec(i).orderd_item_code
              ,gr_interface_info_rec(i).lot_no
              ,gv_prod_kbn_cd_2
              ,gv_item_kbn_cd_5
              ,gr_interface_info_rec(i).shipped_date
              );
            ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
              OPEN cur_lots_product_check
              (
               gr_interface_info_rec(i).orderd_item_code
              ,gr_interface_info_rec(i).lot_no
              ,gv_prod_kbn_cd_2
              ,gv_item_kbn_cd_5
              ,gr_interface_info_rec(i).arrival_date
              );
            END IF;
--
            <<cur_lots_product_loop>>
            LOOP
              -- �����N�����A�ܖ������A�ŗL�L��
              FETCH cur_lots_product_check INTO lt_product_date, lt_expiration_day, lt_original_sign;
              EXIT WHEN cur_lots_product_check%NOTFOUND;
--
              IF (ln_errflg = 0) THEN
--
                -- 3.1.1 �����N����=0 or �ܖ�����=0 or �ŗL�L��=0 �̃`�F�b�N
                IF ((lt_product_date = '0') OR        --�����N����
                    (lt_expiration_day = '0') OR      --�ܖ�����
                    (lt_original_sign = '0'))         --�ŗL�L��
                THEN
--
                  ln_errflg := 1;
--
                  -- (���ڑÓ��`�F�b�N�G���[)
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_019 -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
                                ,gv_param7_token
                                ,gr_interface_info_rec(i).delivery_no      --�z��No
                                ,gv_param8_token
                                ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).lot_ctl      --���b�g
                                ,gv_param4_token
                                ,lt_product_date                       --�����N����
                                ,gv_param5_token
                                ,lt_expiration_day                     --�ܖ�����
                                ,gv_param6_token
                                ,lt_original_sign                      --�ŗL�L��
                                )
                                ,1
                                ,5000);
--
                  -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                  set_header_unit_reserveflg(
                    lt_delivery_no,       -- �z��No
                    lt_order_source_ref,  -- �ړ�No/�˗�No
                    lt_eos_data_type,     -- EOS�f�[�^���
                    gv_reserved_class,    -- �G���[��ʁF�ۗ�
                    lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                    lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
                  -- �����X�e�[�^�X�F�x��
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
              IF (ln_errflg = 0) THEN
--
                -- 3.1.2 �����N����='YYYY/MM/DD'�`�� or �ܖ�����='YYYY/MM/DD' �̃`�F�b�N
                ld_todate_1 := FND_DATE.STRING_TO_DATE(lt_product_date, 'RR/MM/DD');
                ld_todate_2 := FND_DATE.STRING_TO_DATE(lt_expiration_day, 'RR/MM/DD');
--
                IF (ld_todate_1 IS NULL) OR
                   (ld_todate_2 IS NULL)
                THEN
--
                  ln_errflg := 1;
--
                  -- (���ڑÓ��`�F�b�N�G���[)
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_019  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
                                ,gv_param7_token
                                ,gr_interface_info_rec(i).delivery_no      --�z��No
                                ,gv_param8_token
                                ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).lot_ctl      --���b�g
                                ,gv_param4_token
                                ,lt_product_date                       --�����N����
                                ,gv_param5_token
                                ,lt_expiration_day                     --�ܖ�����
                                ,gv_param6_token
                                ,lt_original_sign                      --�ŗL�L��
                                )
                                ,1
                                ,5000);
--
                  -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                  set_header_unit_reserveflg(
                    lt_delivery_no,       -- �z��No
                    lt_order_source_ref,  -- �ړ�No/�˗�No
                    lt_eos_data_type,     -- EOS�f�[�^���
                    gv_reserved_class,    -- �G���[��ʁF�ۗ�
                    lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                    lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
                  -- �����X�e�[�^�X�F�x��
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
            END LOOP cur_lots_product_loop;
--
            CLOSE cur_lots_product_check;
--
            IF (ln_errflg = 0) THEN
--
              -- 3.1.3 �i�ڌ���
              IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
              THEN
--
                SELECT COUNT(xicv.item_id) item_cnt
                INTO   ln_cnt
                FROM   xxcmn_item_categories5_v xicv,
                       ic_lots_mst ilm,
                       xxcmn_item_mst2_v ximv
                WHERE  xicv.item_id = ilm.item_id
                AND    xicv.item_id = ximv.item_id
                AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --�󒍕i��
                AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --���b�gNo
                AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --���b�g�Ǘ��i
                                                                                            --�����N����
                AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')
                AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --�ŗL�L��
                AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                ;
--
              ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                SELECT COUNT(xicv.item_id) item_cnt
                INTO   ln_cnt
                FROM   xxcmn_item_categories5_v xicv,
                       ic_lots_mst ilm,
                       xxcmn_item_mst2_v ximv
                WHERE  xicv.item_id = ilm.item_id
                AND    xicv.item_id = ximv.item_id
                AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --�󒍕i��
                AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --���b�gNo
                AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --���b�g�Ǘ��i
                                                                                            --�����N����
                AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')
                AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --�ŗL�L��
                AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                ;
--
              END IF;
--
              -- 3.1.3.1 �������q�b�g
              IF (ln_cnt > 0) THEN
--
                IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                THEN
                  OPEN cur_lots_status_check
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).designated_production_date
                  ,gr_interface_info_rec(i).original_character
                  ,gr_interface_info_rec(i).shipped_date
                  );
                ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
                  OPEN cur_lots_status_check
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).designated_production_date
                  ,gr_interface_info_rec(i).original_character
                  ,gr_interface_info_rec(i).arrival_date
                  );
                END IF;
--
                <<cur_lots_status_loop>>
                LOOP
                  -- �ܖ������A�ŗL�L���A���b�g�X�e�[�^�X
                  FETCH cur_lots_status_check INTO lt_expiration_day, lt_original_sign, lt_lot_status;
                  EXIT WHEN cur_lots_status_check%NOTFOUND;
--
                  IF (ln_errflg = 0) THEN
--
                    -- �ܖ�����=���o����:�ܖ�����
                    IF (lt_expiration_day = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')) THEN
--
                      -- �X�e�[�^�X������
                      lt_pay_provision_rel := NULL;
                      lt_move_inst_rel     := NULL;
                      lt_ship_req_rel      := NULL;
--
                      -- ���b�g�X�e�[�^�X���擾
                      SELECT xlsv.pay_provision_rel                                       -- �L���x��(����)
                            ,xlsv.move_inst_rel                                           -- �ړ��w��(����)
                            ,xlsv.ship_req_rel                                            -- �o�׈˗�(����)
                      INTO  lt_pay_provision_rel
                           ,lt_move_inst_rel
                           ,lt_ship_req_rel
                      FROM  xxcmn_lot_status_v xlsv
                      WHERE xlsv.prod_class_code = gr_interface_info_rec(i).prod_kbn_cd   -- ���i�敪
                      AND   xlsv.lot_status      = lt_lot_status;                         -- ���b�g�X�e�[�^�X
--
                      ln_lot_err_flg := 0;    -- ������
--
                      -- ���b�g�X�e�[�^�X����
                      -- �L���o�ו񍐂̏ꍇ
                      IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) THEN
--
                        -- �ۗ��ݒ�
                        IF (lt_pay_provision_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- ���_�o�׊m���/���o�׊m��񍐂̏ꍇ
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
                      THEN
--
                        -- �ۗ��ݒ�
                        IF (lt_ship_req_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- �ړ��o�Ɋm���/�ړ����Ɋm��񍐂̏ꍇ
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
                      THEN
--
                        -- �ۗ��ݒ�
                        IF (lt_move_inst_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      END IF;
--
                      IF (ln_lot_err_flg = 1) THEN
--
                        ln_errflg := 1;
--
                        -- (�i���x��)
                        lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_msg_kbn          -- 'XXWSH'
                                      ,gv_msg_93a_021  -- �Ó��`�F�b�N�G���[���b�Z�[�W(�i���x��)
                                      ,gv_param7_token
                                      ,gr_interface_info_rec(i).delivery_no      --�z��No
                                      ,gv_param8_token
                                      ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                      ,gv_param1_token
                                      ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                      ,gv_param2_token
                                      ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                      ,gv_param3_token
                                      ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                      ,gv_param4_token
                                      ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --�����N����
                                      ,gv_param5_token
                                      ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --�ܖ�����
                                      ,gv_param6_token
                                      ,gr_interface_info_rec(i).original_character          --�ŗL�L��
                                      )
                                      ,1
                                      ,5000);
--
                        -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                        set_header_unit_reserveflg(
                          lt_delivery_no,       -- �z��No
                          lt_order_source_ref,  -- �ړ�No/�˗�No
                          lt_eos_data_type,     -- EOS�f�[�^���
                          gv_reserved_class,    -- �G���[��ʁF�ۗ�
                          lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                          lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                        );
--
                        -- �����X�e�[�^�X�F�x��
                        ov_retcode := gv_status_warn;
--
                      END IF;
--
                    ELSE
--
                      ln_errflg := 1;
--
                      -- (���b�g�x��)
                      lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_msg_kbn          -- 'XXWSH'
                                    ,gv_msg_93a_020  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���b�g�x��)
                                    ,gv_param7_token
                                    ,gr_interface_info_rec(i).delivery_no      --�z��No
                                    ,gv_param8_token
                                    ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                    ,gv_param1_token
                                    ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                    ,gv_param2_token
                                    ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                    ,gv_param3_token
                                    ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                    ,gv_param4_token
                                    ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --�����N����
                                    ,gv_param5_token
                                    ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --�ܖ�����
                                    ,gv_param6_token
                                    ,gr_interface_info_rec(i).original_character          --�ŗL�L��
                                    )
                                    ,1
                                    ,5000);
--
                      -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                      set_header_unit_reserveflg(
                        lt_delivery_no,       -- �z��No
                        lt_order_source_ref,  -- �ړ�No/�˗�No
                        lt_eos_data_type,     -- EOS�f�[�^���
                        gv_reserved_class,    -- �G���[��ʁF�ۗ�
                        lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                        lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                      );
--
                      -- �����X�e�[�^�X�F�x��
                      ov_retcode := gv_status_warn;
--
                    END IF;
--
                  END IF;
--
                END LOOP cur_lots_status_loop;
--
                CLOSE cur_lots_status_check;
--
              -- 3.1.3.2 �������q�b�g���Ȃ������ꍇ
              ELSE
--
                ln_errflg := 1;
--
                -- (���b�g�x��)
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_020  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���b�g�x��)
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).delivery_no      --�z��No
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                              ,gv_param4_token
                              ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --�����N����
                              ,gv_param5_token
                              ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --�ܖ�����
                              ,gv_param6_token
                              ,gr_interface_info_rec(i).original_character          --�ŗL�L��
                              )
                              ,1
                              ,5000);
--
                -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- �z��No
                  lt_order_source_ref,  -- �ړ�No/�˗�No
                  lt_eos_data_type,     -- EOS�f�[�^���
                  gv_reserved_class,    -- �G���[��ʁF�ۗ�
                  lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
            END IF;  -- �h�����N,���i,���b�g�Ǘ��i
--
          END IF;
--
          -- 3.  ���b�g���o�A�X�e�[�^�X�`�F�b�N
          -- 3.2 ���[�t,���i,���b�g�Ǘ��i
          IF (ln_errflg = 0) THEN
--
            IF ((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1) AND   --���i�敪:���[�t
                (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) AND   --�i�ڋ敪:���i
                (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1)) --���b�g:�L(���b�g�Ǘ��i)
            THEN
--
              IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                  (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
              THEN
                OPEN cur_lots_product_check
                (
                 gr_interface_info_rec(i).orderd_item_code --�󒍕i��
                ,gr_interface_info_rec(i).lot_no           --���b�gNo
                ,gv_prod_kbn_cd_1                          --���i�敪
                ,gv_item_kbn_cd_5                          --�i�ڋ敪
                ,gr_interface_info_rec(i).shipped_date
                );
              ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                OPEN cur_lots_product_check
                (
                 gr_interface_info_rec(i).orderd_item_code --�󒍕i��
                ,gr_interface_info_rec(i).lot_no           --���b�gNo
                ,gv_prod_kbn_cd_1                          --���i�敪
                ,gv_item_kbn_cd_5                          --�i�ڋ敪
                ,gr_interface_info_rec(i).arrival_date
                );
              END IF;
--
              <<cur_lots_product_r_loop>>
              LOOP
                -- �����N�����A�ܖ������A�ŗL�L���擾
                FETCH cur_lots_product_check INTO lt_product_date, lt_expiration_day, lt_original_sign;
                EXIT WHEN cur_lots_product_check%NOTFOUND;
--
                  -- 3.2.1 �����N����=0 or �ܖ�����=0 or �ŗL�L��=0 �̃`�F�b�N
                IF (ln_errflg = 0) THEN
--
                  IF ((lt_expiration_day = '0') OR    --�ܖ�����
                      (lt_original_sign = '0'))       --�ŗL�L��
                  THEN
--
                    ln_errflg := 1;
--
                    -- (���ڑÓ��`�F�b�N�G���[)
                    lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                   gv_msg_kbn          -- 'XXWSH'
                                  ,gv_msg_93a_019 -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
                                  ,gv_param7_token
                                  ,gr_interface_info_rec(i).delivery_no      --�z��No
                                  ,gv_param8_token
                                  ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                  ,gv_param1_token
                                  ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                  ,gv_param2_token
                                  ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                  ,gv_param3_token
                                  ,gr_interface_info_rec(i).lot_ctl      --���b�g
                                  ,gv_param4_token
                                  ,lt_product_date                       --�����N����
                                  ,gv_param5_token
                                  ,lt_expiration_day                     --�ܖ�����
                                  ,gv_param6_token
                                  ,lt_original_sign                      --�ŗL�L��
                                  )
                                  ,1
                                  ,5000);
--
                    -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                    set_header_unit_reserveflg(
                      lt_delivery_no,       -- �z��No
                      lt_order_source_ref,  -- �ړ�No/�˗�No
                      lt_eos_data_type,     -- EOS�f�[�^���
                      gv_reserved_class,    -- �G���[��ʁF�ۗ�
                      lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                      lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                    );
--
                    -- �����X�e�[�^�X�F�x��
                    ov_retcode := gv_status_warn;
--
                  END IF;
--
                END IF;
--
                  -- 3.2.2 �ܖ�����='YYYY/MM/DD' �̃`�F�b�N
                IF (ln_errflg = 0) THEN
--
                  ld_todate_1 := FND_DATE.STRING_TO_DATE(lt_expiration_day, 'RR/MM/DD');
--
                  IF (ld_todate_1 IS NULL) THEN
--
                    ln_errflg := 1;
--
                    -- (���ڑÓ��`�F�b�N�G���[)
                    lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                   gv_msg_kbn          -- 'XXWSH'
                                  ,gv_msg_93a_019  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
                                  ,gv_param7_token
                                  ,gr_interface_info_rec(i).delivery_no      --�z��No
                                  ,gv_param8_token
                                  ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                  ,gv_param1_token
                                  ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                  ,gv_param2_token
                                  ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                  ,gv_param3_token
                                  ,gr_interface_info_rec(i).lot_ctl      --���b�g
                                  ,gv_param4_token
                                  ,lt_product_date                       --�����N����
                                  ,gv_param5_token
                                  ,lt_expiration_day                     --�ܖ�����
                                  ,gv_param6_token
                                  ,lt_original_sign                      --�ŗL�L��
                                  )
                                  ,1
                                  ,5000);
--
                    -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                    set_header_unit_reserveflg(
                      lt_delivery_no,       -- �z��No
                      lt_order_source_ref,  -- �ړ�No/�˗�No
                      lt_eos_data_type,     -- EOS�f�[�^���
                      gv_reserved_class,    -- �G���[��ʁF�ۗ�
                      lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                      lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                    );
--
                    -- �����X�e�[�^�X�F�x��
                    ov_retcode := gv_status_warn;
--
                  END IF;
--
                END IF;
--
                IF (ln_errflg = 0) THEN
--
                  -- 3.2.3 ����
                  IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                      (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                      (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                      (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                  THEN
                    SELECT COUNT(xicv.item_id) item_cnt
                    INTO   ln_cnt
                    FROM   xxcmn_item_categories5_v xicv,
                           ic_lots_mst ilm,
                           xxcmn_item_mst2_v ximv
                    WHERE  xicv.item_id = ilm.item_id
                    AND    xicv.item_id = ximv.item_id
                    AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --�󒍕i��
                    AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --���b�gNo
                    AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --���b�g�Ǘ��i
                    AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --�����N����
                    AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --�ŗL�L��
                    AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                    AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                    AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                    AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                    ;
--
                  ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                    SELECT COUNT(xicv.item_id) item_cnt
                    INTO   ln_cnt
                    FROM   xxcmn_item_categories5_v xicv,
                           ic_lots_mst ilm,
                           xxcmn_item_mst2_v ximv
                    WHERE  xicv.item_id = ilm.item_id
                    AND    xicv.item_id = ximv.item_id
                    AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code             --�󒍕i��
                    AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                       --���b�gNo
                    AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                                     --���b�g�Ǘ��i
                    AND    ilm.attribute1 = TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --�����N����
                    AND    ilm.attribute2 = gr_interface_info_rec(i).original_character         --�ŗL�L��
                    AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                    AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                    AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                    AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                    ;
                  END IF;
--
                  -- 3.2.3.1 �������q�b�g
                  IF (ln_cnt > 0) THEN  --*E
--
                    IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                    THEN
--
                      OPEN cur_lots_status_check
                      (
                       gr_interface_info_rec(i).orderd_item_code             --�󒍕i��
                      ,gr_interface_info_rec(i).lot_no                       --���b�gNo
                      ,gr_interface_info_rec(i).designated_production_date   --�����N����
                      ,gr_interface_info_rec(i).original_character           --�ŗL�L��
                      ,gr_interface_info_rec(i).shipped_date
                      );
--
                    ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                      OPEN cur_lots_status_check
                      (
                       gr_interface_info_rec(i).orderd_item_code             --�󒍕i��
                      ,gr_interface_info_rec(i).lot_no                       --���b�gNo
                      ,gr_interface_info_rec(i).designated_production_date   --�����N����
                      ,gr_interface_info_rec(i).original_character           --�ŗL�L��
                      ,gr_interface_info_rec(i).arrival_date
                      );
                    END IF;
--
                    <<cur_lots_status_r_loop>>
                    LOOP
                     --�ܖ������A�ŗL�L���A���b�g�X�e�[�^�X�擾
                      FETCH cur_lots_status_check INTO lt_expiration_day, lt_original_sign, lt_lot_status;
                      EXIT WHEN cur_lots_status_check%NOTFOUND;
--
                      -- �ܖ�����=���o����:�ܖ�����
                      IF (lt_expiration_day = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')) THEN  --*Y
--
                        -- �X�e�[�^�X������
                        lt_pay_provision_rel := NULL;
                        lt_move_inst_rel     := NULL;
                        lt_ship_req_rel      := NULL;
--
                        -- ���b�g�X�e�[�^�X���擾
                        SELECT xlsv.pay_provision_rel                                       -- �L���x��(����)
                              ,xlsv.move_inst_rel                                           -- �ړ��w��(����)
                              ,xlsv.ship_req_rel                                            -- �o�׈˗�(����)
                        INTO  lt_pay_provision_rel
                             ,lt_move_inst_rel
                             ,lt_ship_req_rel
                        FROM  xxcmn_lot_status_v xlsv
                        WHERE xlsv.prod_class_code = gr_interface_info_rec(i).prod_kbn_cd   -- ���i�敪
                        AND   xlsv.lot_status      = lt_lot_status;                         -- ���b�g�X�e�[�^�X
--
                        ln_lot_err_flg := 0;    -- ������
--
                        -- ���b�g�X�e�[�^�X����
                        -- �L���o�ו񍐂̏ꍇ
                        IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) THEN
--
                          -- �ۗ��ݒ�
                          IF (lt_pay_provision_rel = gv_yesno_n) THEN
                            ln_lot_err_flg := 1;
                          END IF;
--
                        -- ���_�o�׊m���/���o�׊m��񍐂̏ꍇ
                        ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
                               (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
                        THEN
--
                          -- �ۗ��ݒ�
                          IF (lt_ship_req_rel = gv_yesno_n) THEN
                            ln_lot_err_flg := 1;
                          END IF;
--
                        -- �ړ��o�Ɋm���/�ړ����Ɋm��񍐂̏ꍇ
                        ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                               (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
                        THEN
--
                          -- �ۗ��ݒ�
                          IF (lt_move_inst_rel = gv_yesno_n) THEN
                            ln_lot_err_flg := 1;
                          END IF;
--
                        END IF;
--
                        IF (ln_lot_err_flg = 1) THEN
--
                          ln_errflg := 1;
--
                          -- (�i���x��)
                          lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                         gv_msg_kbn          -- 'XXWSH'
                                        ,gv_msg_93a_021  -- �Ó��`�F�b�N�G���[���b�Z�[�W(�i���x��)
                                        ,gv_param7_token
                                        ,gr_interface_info_rec(i).delivery_no      --�z��No
                                        ,gv_param8_token
                                        ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                        ,gv_param1_token
                                        ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                        ,gv_param2_token
                                        ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                        ,gv_param3_token
                                        ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                        ,gv_param4_token
                                        ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --�����N����
                                        ,gv_param5_token
                                        ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                --�ܖ�����
                                        ,gv_param6_token
                                        ,gr_interface_info_rec(i).original_character         --�ŗL�L��
                                        )
                                        ,1
                                        ,5000);
--
                          -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                          set_header_unit_reserveflg(
                            lt_delivery_no,       -- �z��No
                            lt_order_source_ref,  -- �ړ�No/�˗�No
                            lt_eos_data_type,     -- EOS�f�[�^���
                            gv_reserved_class,    -- �G���[��ʁF�ۗ�
                            lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                            lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                            lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                            lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                          );
--
                          -- �����X�e�[�^�X�F�x��
                          ov_retcode := gv_status_warn;
--
                        END IF;
--
                      -- �ܖ�����<>���o����:�ܖ�����
                      ELSE  --*Y
--
                        ln_errflg := 1;
--
                        -- (���b�g�x��)
                        lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_msg_kbn          -- 'XXWSH'
                                      ,gv_msg_93a_020  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���b�g�x��)
                                      ,gv_param7_token
                                      ,gr_interface_info_rec(i).delivery_no      --�z��No
                                      ,gv_param8_token
                                      ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                      ,gv_param1_token
                                      ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                      ,gv_param2_token
                                      ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                      ,gv_param3_token
                                      ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                      ,gv_param4_token
                                      ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') --�����N����
                                      ,gv_param5_token
                                      ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                --�ܖ�����
                                      ,gv_param6_token
                                      ,gr_interface_info_rec(i).original_character         --�ŗL�L��
                                      )
                                      ,1
                                      ,5000);
--
                        -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                        set_header_unit_reserveflg(
                          lt_delivery_no,       -- �z��No
                          lt_order_source_ref,  -- �ړ�No/�˗�No
                          lt_eos_data_type,     -- EOS�f�[�^���
                          gv_reserved_class,    -- �G���[��ʁF�ۗ�
                          lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                          lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                        );
--
                        -- �����X�e�[�^�X�F�x��
                        ov_retcode := gv_status_warn;
--
                      END IF;
--
                    END LOOP cur_lots_status_r_loop;
--
                    CLOSE cur_lots_status_check;
--
                  -- 3.2.3.2 �������q�b�g���Ȃ������ꍇ
                  ELSE
--
                    IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                        (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                    THEN
--
                      SELECT COUNT(xicv.item_id) item_cnt
                      INTO   ln_cnt2
                      FROM   xxcmn_item_categories5_v xicv,
                             ic_lots_mst ilm,
                             xxcmn_item_mst2_v ximv
                      WHERE  xicv.item_id = ilm.item_id
                      AND    xicv.item_id = ximv.item_id
                      AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --�󒍕i��
                      AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --���b�gNo
                      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --���b�g�Ǘ��i
                      AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --�ܖ�����
                      AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --�ŗL�L��
                      AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                      AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                      AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                      AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                      ;
--
                      IF (ln_cnt2 = 1) THEN
                        SELECT ilm.attribute23 lot_status      --���b�g�X�e�[�^�X
                        INTO   lt_lot_status
                        FROM   xxcmn_item_categories5_v xicv,
                               ic_lots_mst ilm,
                               xxcmn_item_mst2_v ximv
                        WHERE  xicv.item_id = ilm.item_id
                        AND    xicv.item_id = ximv.item_id
                        AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --�󒍕i��
                        AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --���b�gNo
                        AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --���b�g�Ǘ��i
                        AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --�ܖ�����
                        AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --�ŗL�L��
                        AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                        AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                        ;
                      END IF;
--
                    ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                      -- �����Ȃ�-->�������q�b�g
                      SELECT COUNT(xicv.item_id) item_cnt
                      INTO   ln_cnt2
                      FROM   xxcmn_item_categories5_v xicv,
                             ic_lots_mst ilm,
                             xxcmn_item_mst2_v ximv
                      WHERE  xicv.item_id = ilm.item_id
                      AND    xicv.item_id = ximv.item_id
                      AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --�󒍕i��
                      AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --���b�gNo
                      AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --���b�g�Ǘ��i
                      AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --�ܖ�����
                      AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --�ŗL�L��
                      AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                      AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                      AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                      AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                      ;
--
                      IF (ln_cnt2 = 1) THEN
                        SELECT ilm.attribute23 lot_status      --���b�g�X�e�[�^�X
                        INTO   lt_lot_status
                        FROM   xxcmn_item_categories5_v xicv,
                               ic_lots_mst ilm,
                               xxcmn_item_mst2_v ximv
                        WHERE  xicv.item_id = ilm.item_id
                        AND    xicv.item_id = ximv.item_id
                        AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code       --�󒍕i��
                        AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no                 --���b�gNo
                        AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                               --���b�g�Ǘ��i
                        AND    ilm.attribute3  = TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') --�ܖ�����
                        AND    ilm.attribute2  = gr_interface_info_rec(i).original_character  --�ŗL�L��
                        AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                        AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                        ;
                      END IF;
--
                    END IF;
--
                    -- 3.2.3.2.1 �P���q�b�g
                    IF (ln_cnt2 = 1) THEN
--
                      -- �X�e�[�^�X������
                      lt_pay_provision_rel := NULL;
                      lt_move_inst_rel     := NULL;
                      lt_ship_req_rel      := NULL;
--
                      -- ���b�g�X�e�[�^�X���擾
                      SELECT xlsv.pay_provision_rel                                       -- �L���x��(����)
                            ,xlsv.move_inst_rel                                           -- �ړ��w��(����)
                            ,xlsv.ship_req_rel                                            -- �o�׈˗�(����)
                      INTO  lt_pay_provision_rel
                           ,lt_move_inst_rel
                           ,lt_ship_req_rel
                      FROM  xxcmn_lot_status_v xlsv
                      WHERE xlsv.prod_class_code = gr_interface_info_rec(i).prod_kbn_cd   -- ���i�敪
                      AND   xlsv.lot_status      = lt_lot_status;                         -- ���b�g�X�e�[�^�X
--
                      ln_lot_err_flg := 0;    -- ������
--
                      -- ���b�g�X�e�[�^�X����
                      -- �L���o�ו񍐂̏ꍇ
                      IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) THEN
--
                        -- �ۗ��ݒ�
                        IF (lt_pay_provision_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- ���_�o�׊m���/���o�׊m��񍐂̏ꍇ
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
                      THEN
--
                        -- �ۗ��ݒ�
                        IF (lt_ship_req_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      -- �ړ��o�Ɋm���/�ړ����Ɋm��񍐂̏ꍇ
                      ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                             (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
                      THEN
--
                        -- �ۗ��ݒ�
                        IF (lt_move_inst_rel = gv_yesno_n) THEN
                          ln_lot_err_flg := 1;
                        END IF;
--
                      END IF;
--
                      IF (ln_lot_err_flg = 1) THEN
--
                        ln_errflg := 1;
--
                        -- (�i���x��)
                        lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                       gv_msg_kbn          -- 'XXWSH'
                                      ,gv_msg_93a_021  -- �Ó��`�F�b�N�G���[���b�Z�[�W(�i���x��)
                                      ,gv_param7_token
                                      ,gr_interface_info_rec(i).delivery_no      --�z��No
                                      ,gv_param8_token
                                      ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                      ,gv_param1_token
                                      ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                      ,gv_param2_token
                                      ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                      ,gv_param3_token
                                      ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                      ,gv_param4_token
                                      ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --�����N����
                                      ,gv_param5_token
                                      ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --�ܖ�����
                                      ,gv_param6_token
                                      ,gr_interface_info_rec(i).original_character          --�ŗL�L��
                                      )
                                      ,1
                                      ,5000);
--
                        -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                        set_header_unit_reserveflg(
                          lt_delivery_no,       -- �z��No
                          lt_order_source_ref,  -- �ړ�No/�˗�No
                          lt_eos_data_type,     -- EOS�f�[�^���
                          gv_reserved_class,    -- �G���[��ʁF�ۗ�
                          lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                          lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                          lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                          lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                        );
--
                        -- �����X�e�[�^�X�F�x��
                        ov_retcode := gv_status_warn;
--
                      END IF;
--
                    -- 3.2.3.2.2 �������q�b�g
                    ELSIF (ln_cnt2 > 1) THEN
--
                      ln_errflg := 1;
--
                      -- (���b�g�x��)
                      lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_msg_kbn          -- 'XXWSH'
                                    ,gv_msg_93a_020  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���b�g�x��)
                                    ,gv_param7_token
                                    ,gr_interface_info_rec(i).delivery_no      --�z��No
                                    ,gv_param8_token
                                    ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                    ,gv_param1_token
                                    ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                    ,gv_param2_token
                                    ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                    ,gv_param3_token
                                    ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                    ,gv_param4_token
                                    ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --�����N����
                                    ,gv_param5_token
                                    ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --�ܖ�����
                                    ,gv_param6_token
                                    ,gr_interface_info_rec(i).original_character          --�ŗL�L��
                                    )
                                    ,1
                                    ,5000);
--
                      -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                      set_header_unit_reserveflg(
                        lt_delivery_no,       -- �z��No
                        lt_order_source_ref,  -- �ړ�No/�˗�No
                        lt_eos_data_type,     -- EOS�f�[�^���
                        gv_reserved_class,    -- �G���[��ʁF�ۗ�
                        lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                        lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                      );
--
                      -- �����X�e�[�^�X�F�x��
                      ov_retcode := gv_status_warn;
--
                    -- 3.2.3.2.3 �q�b�g�Ȃ�
                    ELSIF (ln_cnt2 = 0) THEN
--
                     ln_errflg := 1;
--
                      -- (���b�g�x��)
                      lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                     gv_msg_kbn          -- 'XXWSH'
                                    ,gv_msg_93a_020  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���b�g�x��)
                                    ,gv_param7_token
                                    ,gr_interface_info_rec(i).delivery_no      --�z��No
                                    ,gv_param8_token
                                    ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                    ,gv_param1_token
                                    ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                    ,gv_param2_token
                                    ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                    ,gv_param3_token
                                    ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                    ,gv_param4_token
                                    ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --�����N����
                                    ,gv_param5_token
                                    ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --�ܖ�����
                                    ,gv_param6_token
                                    ,gr_interface_info_rec(i).original_character          --�ŗL�L��
                                    )
                                    ,1
                                    ,5000);
--
                      -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                      set_header_unit_reserveflg(
                        lt_delivery_no,       -- �z��No
                        lt_order_source_ref,  -- �ړ�No/�˗�No
                        lt_eos_data_type,     -- EOS�f�[�^���
                        gv_reserved_class,    -- �G���[��ʁF�ۗ�
                        lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                        lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                      );
--
                      -- �����X�e�[�^�X�F�x��
                      ov_retcode := gv_status_warn;
--
                    END IF;
--
                  END IF;
--
                END IF;
--
              END LOOP cur_lots_product_r_loop;
--
              CLOSE cur_lots_product_check;
--
            END IF;  --���[�t,���i,���b�g�Ǘ��i
--
          END IF;
--
          -- 3.  ���b�g���o�A�X�e�[�^�X�`�F�b�N
          -- 3.3 �h�����Nor���[�t,���i�ȊO,���b�g�Ǘ��i
          IF (ln_errflg = 0) THEN
--
            IF (((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2) OR   --���i�敪:�h�����Nor���[�t
                 (gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)) AND
                (gr_interface_info_rec(i).item_kbn_cd <> gv_item_kbn_cd_5)  AND --�i�ڋ敪:���i�ȊO
                (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1))         --���b�g:�L(���b�g�Ǘ��i)
            THEN
--
              -- 3.3.1 ���o����:���b�gID=0
              IF (gr_interface_info_rec(i).lot_id = 0) THEN
--
                ln_errflg := 1;
--
                -- (���ڑÓ��`�F�b�N�G���[)
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_019 -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).delivery_no      --�z��No
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).lot_ctl      --���b�g
                              ,gv_param4_token
                              ,lt_product_date                       --�����N����
                              ,gv_param5_token
                              ,lt_expiration_day                     --�ܖ�����
                              ,gv_param6_token
                              ,lt_original_sign                      --�ŗL�L��
                              )
                              ,1
                              ,5000);
--
                -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- �z��No
                  lt_order_source_ref,  -- �ړ�No/�˗�No
                  lt_eos_data_type,     -- EOS�f�[�^���
                  gv_reserved_class,    -- �G���[��ʁF�ۗ�
                  lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              ELSE
--
                -- 3.3.2 ����
                IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                THEN
--
                  SELECT COUNT(xicv.item_id) item_cnt
                  INTO   ln_cnt
                  FROM   xxcmn_item_categories5_v xicv,
                         ic_lots_mst ilm,
                         xxcmn_item_mst2_v ximv
                  WHERE  xicv.item_id = ilm.item_id
                  AND    xicv.item_id = ximv.item_id
                  AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code  --�󒍕i��
                  AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                          --���b�g�Ǘ��i
                  AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no            --���b�gNo
                  AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                  AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                  AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                  AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).shipped_date) -- �o�ד�
                  ;
--
                ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
                  SELECT COUNT(xicv.item_id) item_cnt
                  INTO   ln_cnt
                  FROM   xxcmn_item_categories5_v xicv,
                         ic_lots_mst ilm,
                         xxcmn_item_mst2_v ximv
                  WHERE  xicv.item_id = ilm.item_id
                  AND    xicv.item_id = ximv.item_id
                  AND    ximv.item_no = gr_interface_info_rec(i).orderd_item_code  --�󒍕i��
                  AND    ximv.lot_ctl = gv_lotkr_kbn_cd_1                          --���b�g�Ǘ��i
                  AND    ilm.lot_no   = gr_interface_info_rec(i).lot_no            --���b�gNo
                  AND    ximv.inactive_ind   <> gn_view_disable                               -- �����t���O
                  AND    ximv.obsolete_class <> gv_view_disable                               -- �p�~�敪
                  AND    ximv.start_date_active <= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                  AND    ximv.end_date_active   >= TRUNC(gr_interface_info_rec(i).arrival_date) -- ���ד�
                  ;
--
                END IF;
--
                -- �q�b�g���Ȃ������ꍇ
                IF (ln_cnt = 0) THEN
--
                  ln_errflg := 1;
--
                  -- (���b�g�x��)
                  lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                 gv_msg_kbn          -- 'XXWSH'
                                ,gv_msg_93a_020  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���b�g�x��)
                                ,gv_param7_token
                                ,gr_interface_info_rec(i).delivery_no      --�z��No
                                ,gv_param8_token
                                ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                ,gv_param1_token
                                ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                ,gv_param2_token
                                ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                ,gv_param3_token
                                ,gr_interface_info_rec(i).orderd_item_code      --IF_L.�󒍕i��
                                ,gv_param4_token
                                ,TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD')  --�����N����
                                ,gv_param5_token
                                ,TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD')                 --�ܖ�����
                                ,gv_param6_token
                                ,gr_interface_info_rec(i).original_character          --�ŗL�L��
                                )
                                ,1
                                ,5000);
--
                  -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                  set_header_unit_reserveflg(
                    lt_delivery_no,       -- �z��No
                    lt_order_source_ref,  -- �ړ�No/�˗�No
                    lt_eos_data_type,     -- EOS�f�[�^���
                    gv_reserved_class,    -- �G���[��ʁF�ۗ�
                    lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                    lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
                  -- �����X�e�[�^�X�F�x��
                  ov_retcode := gv_status_warn;
--
                END IF;
--
              END IF;
--
            END IF;
--
          END IF;
--
          -- 3.  ���b�g���o�A�X�e�[�^�X�`�F�b�N
          -- 3.4 �h�����Nor���[�t,���i�ȊO,���b�g�Ǘ��i�ΏۊO
          IF (ln_errflg = 0) THEN
--
            IF (((gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_2) OR   --���i�敪:�h�����Nor���[�t
                 (gr_interface_info_rec(i).prod_kbn_cd = gv_prod_kbn_cd_1)) AND
                (gr_interface_info_rec(i).item_kbn_cd <> gv_item_kbn_cd_5)  AND --�i�ڋ敪:���i�ȊO
                (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_0))         --���b�g:���L(���b�g�Ǘ��i�ΏۊO)
            THEN
              -- 3.4.1 ���b�gID<>0�̏ꍇ�G���[
              IF (gr_interface_info_rec(i).lot_id <> 0) THEN
--
                ln_errflg := 1;
--
                -- (���ڑÓ��`�F�b�N�G���[)
                lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                               gv_msg_kbn          -- 'XXWSH'
                              ,gv_msg_93a_019  -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
                              ,gv_param7_token
                              ,gr_interface_info_rec(i).delivery_no      --�z��No
                              ,gv_param8_token
                              ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                              ,gv_param1_token
                              ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                              ,gv_param2_token
                              ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                              ,gv_param3_token
                              ,gr_interface_info_rec(i).lot_ctl      --���b�g
                              ,gv_param4_token
                              ,lt_product_date                       --�����N����
                              ,gv_param5_token
                              ,lt_expiration_day                     --�ܖ�����
                              ,gv_param6_token
                              ,lt_original_sign                      --�ŗL�L��
                              )
                              ,1
                              ,5000);
--
                -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                set_header_unit_reserveflg(
                  lt_delivery_no,       -- �z��No
                  lt_order_source_ref,  -- �ړ�No/�˗�No
                  lt_eos_data_type,     -- EOS�f�[�^���
                  gv_reserved_class,    -- �G���[��ʁF�ۗ�
                  lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                  lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
                -- �����X�e�[�^�X�F�x��
                ov_retcode := gv_status_warn;
--
              END IF;
--
              /*----------------------------------------------------------------------------------
              ���b�g�Ǘ��i�O������`�F�b�N�s�v�H
--
--            -- �����N�����A�ܖ������A�ŗL�L���̃`�F�b�N
              IF (ln_errflg = 0) THEN
--
                IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215) OR
                    (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220))
                THEN
                  OPEN cur_lots_product_check2
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).prod_kbn_cd
                  ,gv_item_kbn_cd_5
                  ,gr_interface_info_rec(i).shipped_date
                  );
                ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
                  OPEN cur_lots_product_check2
                  (
                   gr_interface_info_rec(i).orderd_item_code
                  ,gr_interface_info_rec(i).lot_no
                  ,gr_interface_info_rec(i).prod_kbn_cd
                  ,gv_item_kbn_cd_5
                  ,gr_interface_info_rec(i).arrival_date
                  );
                END IF;
--
                <<cur_lots_product_loop2>>
                LOOP
                  -- �����N�����A�ܖ������A�ŗL�L��
                  FETCH cur_lots_product_check2 INTO lt_product_date, lt_expiration_day, lt_original_sign;
                  EXIT WHEN cur_lots_product_check%NOTFOUND;
--
                  -- 3.4.2
                  IF ((lt_product_date <> '0') OR       --�����N����
                      (lt_expiration_day <> '0') OR     --�ܖ�����
                      (lt_original_sign <> '0'))        --�ŗL�L��
                  THEN
--
                    ln_errflg := 1;
--
                    -- (���ڑÓ��`�F�b�N�G���[)
                    lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                   gv_msg_kbn         -- 'XXWSH'
                                  ,gv_msg_93a_019 -- �Ó��`�F�b�N�G���[���b�Z�[�W(���ڑÓ��`�F�b�N�G���[)
                                  ,gv_param7_token
                                  ,gr_interface_info_rec(i).delivery_no      --�z��No
                                  ,gv_param8_token
                                  ,gr_interface_info_rec(i).order_source_ref --�󒍃\�[�X�Q��
                                  ,gv_param1_token
                                  ,gr_interface_info_rec(i).prod_kbn_cd  --���i�敪
                                  ,gv_param2_token
                                  ,gr_interface_info_rec(i).item_kbn_cd  --�i�ڋ敪
                                  ,gv_param3_token
                                  ,gr_interface_info_rec(i).lot_ctl      --���b�g
                                  ,gv_param4_token
                                  ,lt_product_date                       --�����N����
                                  ,gv_param5_token
                                  ,lt_expiration_day                     --�ܖ�����
                                  ,gv_param6_token
                                  ,lt_original_sign                      --�ŗL�L��
                                  )
                                  ,1
                                  ,5000);
--
                    -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
                    set_header_unit_reserveflg(
                      lt_delivery_no,       -- �z��No
                      lt_order_source_ref,  -- �ړ�No/�˗�No
                      lt_eos_data_type,     -- EOS�f�[�^���
                      gv_reserved_class,    -- �G���[��ʁF�ۗ�
                      lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                      lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                    );
--
                    -- �����X�e�[�^�X�F�x��
                    ov_retcode := gv_status_warn;
--
                  END IF;
--
                END LOOP cur_lots_product_loop2;
--
                CLOSE cur_lots_product_check2;
--
              END IF;
              ---------------------------------------------------------------------------------*/
--
            END IF;
--
          END IF;
--
        END IF;
--
        -- 5.
        -- 5.1 ���b�g�Ǘ��i�̃`�F�b�N
        IF (ln_errflg = 0) THEN
--
        -- ���b�g�Ǘ��i�̏ꍇ
          IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) THEN
--
            -- ���b�g���ʂ��ݒ肳��Ă��Ȃ��ꍇ
            IF (gr_interface_info_rec(i).detailed_quantity IS NULL) THEN
--
              ln_errflg := 1;
--
              -- (���󐔗ʖ��ݒ�G���[)
              lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                             gv_msg_kbn                                     -- 'XXWSH'
                            ,gv_msg_93a_146          -- ���b�g�Ǘ��i�̓��󐔗ʖ��ݒ�G���[���b�Z�[�W
                            ,gv_param1_token
                            ,gr_interface_info_rec(i).delivery_no           -- IF_H.�z��No
                            ,gv_param2_token
                            ,gr_interface_info_rec(i).order_source_ref      -- IF_H.�󒍃\�[�X�Q��
                            ,gv_param3_token
                            ,gr_interface_info_rec(i).orderd_item_code      -- IF_L.�󒍕i��
                            ,gv_param4_token
                            ,gr_interface_info_rec(i).lot_no                -- IF_L.���b�gNo
                            )
                            ,1
                            ,5000);
--
              -- �z��No/�ړ�No-EOS�f�[�^��ʒP�ʂőÓ��`�F�b�N�G���[flag���Z�b�g
              set_header_unit_reserveflg(
                lt_delivery_no,       -- �z��No
                lt_order_source_ref,  -- �ړ�No/�˗�No
                lt_eos_data_type,     -- EOS�f�[�^���
                gv_reserved_class,    -- �G���[��ʁF�ۗ�
                lv_msg_buff,          -- �G���[�E���b�Z�[�W(�o�͗p)
                lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
--
              -- �����X�e�[�^�X�F�x��
              ov_retcode := gv_status_warn;
--
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP appropriate_chk_line_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END appropriate_check;
--
 /**********************************************************************************
  * Procedure Name   : order_headers_ins
  * Description      : �󒍃w�b�_�A�h�I��(�O���q�ɕҏW) �v���V�[�W��(A-8-2)
  ***********************************************************************************/
  PROCEDURE order_headers_ins(
    in_index                IN  NUMBER,                 -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_headers_ins'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_time_def                   CONSTANT VARCHAR2(1) := ':';
--
    -- *** ���[�J���ϐ� ***
    -- �󒍃w�b�_�A�h�I��ID
    lt_order_header_id             xxwsh_order_headers_all.order_header_id%TYPE;
    -- ���ъǗ�����
    lt_location_code               xxwsh_order_headers_all.performance_management_dept%TYPE;
    -- ����^�C�vID
    lt_transaction_type_id         xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
--
    -- �ő�p���b�g�����Z�o�֐��p�����[�^
    lv_code_class1                VARCHAR2(2);                -- 1.�R�[�h�敪�P
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.���o�ɏꏊ�R�[�h�P
    lv_code_class2                VARCHAR2(2);                -- 3.�R�[�h�敪�Q
    lv_entering_despatching_code2 VARCHAR2(9);                -- 4.���o�ɏꏊ�R�[�h�Q
    ld_standard_date              DATE;                       -- 5.���(�K�p�����)
    lv_ship_methods               VARCHAR2(2);                -- 6.�z���敪
    on_drink_deadweight           NUMBER;                     -- 7.�h�����N�ύڏd��
    on_leaf_deadweight            NUMBER;                     -- 8.���[�t�ύڏd��
    on_drink_loading_capacity     NUMBER;                     -- 9.�h�����N�ύڗe��
    on_leaf_loading_capacity      NUMBER;                     -- 10.���[�t�ύڗe��
    on_palette_max_qty            NUMBER;                     -- 11.�p���b�g�ő喇��
--
    --���׎���FROM,TO
    lv_arrival_time_from          VARCHAR2(4);
    lv_arrival_time_to            VARCHAR2(4);
    lv_arrival_from               VARCHAR2(5);
    lv_arrival_to                 VARCHAR2(5);
--
    ln_ret_code                   NUMBER;                     -- ���^�[���E�R�[�h
--
    lv_shipping_class             VARCHAR2(10);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_order_h_rec := gr_order_h_ini;
--
    -- �󒍃w�b�_ID�擾(�V�[�P���X)
    SELECT xxwsh_order_headers_all_s1.NEXTVAL
    INTO   lt_order_header_id
    FROM   dual;
--
    -- �󒍃w�b�_�A�h�I���ҏW����
    -- �󒍃w�b�_ID
    gr_order_h_rec.order_header_id          := lt_order_header_id;
--
    -- �󒍃^�C�vID
    -- �݌Ɏ���p(�󒍃J�e�S��=�ԕi)�̎���^�C�vID���擾
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) THEN
      lv_shipping_class := gv_shipping_class_01;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215) THEN
      lv_shipping_class := gv_shipping_class_08;
    END IF;
--
    BEGIN
      SELECT xtv.transaction_type_id         -- ����^�C�vID
      INTO   lt_transaction_type_id
      FROM   xxwsh_oe_transaction_types_v  xtv  -- �󒍃^�C�vView
      WHERE  xtv.transaction_type_name = lv_shipping_class;  -- ����^�C�v��
--
      gr_order_h_rec.order_type_id   := lt_transaction_type_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_api_expt;     -- �󒍃^�C�v���擾�ł��Ȃ��ꍇ��ABEND�ɂ���ROLLBACK������
    END;
--
    -- �g�DID
    gr_order_h_rec.organization_id          := gv_master_org_id;
    -- �ŐV�t���O
    gr_order_h_rec.latest_external_flag     := gv_yesno_y;
    -- �󒍓�
    gr_order_h_rec.ordered_date             := gd_sysdate;
    -- �ڋqID
    gr_order_h_rec.customer_id              := gr_interface_info_rec(in_index).customer_id;
    -- �ڋq
    gr_order_h_rec.customer_code            := gr_interface_info_rec(in_index).customer_code;
    -- �o�א�ID
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.deliver_to_id          := gr_interface_info_rec(in_index).deliver_to_id;
    END IF;
    -- �o�א�
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.deliver_to             := gr_interface_info_rec(in_index).party_site_code;
    END IF;
    -- �^���Ǝ�_ID
    gr_order_h_rec.career_id                := gr_interface_info_rec(in_index).career_id;
    -- �^���Ǝ�
    gr_order_h_rec.freight_carrier_code     := gr_interface_info_rec(in_index).freight_carrier_code;
    -- �ڋq����
    gr_order_h_rec.cust_po_number           := gr_interface_info_rec(in_index).cust_po_number;
    -- �˗�No
    gr_order_h_rec.request_no               := gr_interface_info_rec(in_index).order_source_ref;
    -- �X�e�[�^�X
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.req_status             := gv_req_status_04;
    END IF;
    -- �z��No
    gr_order_h_rec.delivery_no              := gr_interface_info_rec(in_index).delivery_no;
    -- �O��z��no
    gr_order_h_rec.prev_delivery_no         := gv_prev_deliv_no_zero;
    -- �o�ח\���
    gr_order_h_rec.schedule_ship_date       := gr_interface_info_rec(in_index).shipped_date;
    -- ���ח\���
    gr_order_h_rec.schedule_arrival_date    := gr_interface_info_rec(in_index).arrival_date;
    -- �p���b�g�������
    gr_order_h_rec.collected_pallet_qty     := gr_interface_info_rec(in_index).collected_pallet_qty;
    -- �^���敪
    IF (NVL(gr_interface_info_rec(in_index).delivery_no,'0') <> '0') THEN
      gr_order_h_rec.freight_charge_class   := gv_include_exclude_1;
    ELSE
      gr_order_h_rec.freight_charge_class   := gv_include_exclude_0;
    END IF;
    -- �o�׌�ID
    gr_order_h_rec.deliver_from_id          := gr_interface_info_rec(in_index).deliver_from_id;
    -- �o�׌��ۊǏꏊ
    gr_order_h_rec.deliver_from             := gr_interface_info_rec(in_index).location_code;
    -- �Ǌ����_
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.head_sales_branch      := gr_interface_info_rec(in_index).base_code;
    END IF;
    -- ���i�敪
    gr_order_h_rec.prod_class               := gr_interface_info_rec(in_index).prod_kbn_cd;
--
    lv_arrival_from := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 1, 2)
                    || lv_time_def
                    || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 3, 2);
--
    lv_arrival_to := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 1, 2)
                  || lv_time_def
                  || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 3, 2);
--
    BEGIN
--
      SELECT  xlvv1.lookup_code arrival_time_from
             ,xlvv2.lookup_code arrival_time_to
      INTO    lv_arrival_time_from
             ,lv_arrival_time_to
      FROM    xxcmn_lookup_values_v  xlvv1
             ,xxcmn_lookup_values_v  xlvv2
      WHERE   xlvv1.lookup_type = gv_arrival_time_type
      AND     xlvv2.lookup_type = gv_arrival_time_type
      AND     xlvv1.meaning = lv_arrival_from
      AND     xlvv2.meaning = lv_arrival_to
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_arrival_time_from := '0000';
        lv_arrival_time_to := '0000';
    END;
--
    -- ���׎���from
    gr_order_h_rec.arrival_time_from       := lv_arrival_time_from;
    -- ���׎���to
    gr_order_h_rec.arrival_time_to         := lv_arrival_time_to;
--
    --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      -- ��{�d��
      -- �p�����[�^���擾
      -- 1.�R�[�h�敪�P
      lv_code_class1                := gv_code_class_04;
      -- 2.���o�ɏꏊ�R�[�h�P
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.�R�[�h�敪�Q
      -- 2008/08/06 Start --------------------------------------------------------
      --lv_code_class2                := gv_code_class_09;
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200) THEN
        lv_code_class2                := gv_code_class_11;  -- �x���̏ꍇ(200)
      ELSE
        lv_code_class2                := gv_code_class_09;  -- �o�ׂ̏ꍇ(210,215)
      END IF;
      -- 2008/08/06 End ----------------------------------------------------------
      -- 4.���o�ɏꏊ�R�[�h�Q
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).party_site_code;
      -- 5.���(�K�p�����)
      ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      -- 6.�z���敪
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- �z���敪��NULL�̏ꍇ�A�ő�z���敪���擾���čő�p���b�g�������擾����B
      IF (lv_ship_methods IS NULL) THEN
--
        -- �ő�z���敪�Z�o�֐�
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:�R�[�h�敪1
                                  ,lv_entering_despatching_code1                         -- IN:���o�ɏꏊ�R�[�h1
                                  ,lv_code_class2                                        -- IN:�R�[�h�敪2
                                  ,lv_entering_despatching_code2                         -- IN:���o�ɏꏊ�R�[�h2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:���i�敪
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:�d�ʗe�ϋ敪
                                  ,NULL                                                  -- IN:�����z�ԑΏۋ敪
                                  ,ld_standard_date                                      -- IN:���
                                  ,lv_ship_methods                -- OUT:�ő�z���敪
                                  ,on_drink_deadweight            -- OUT:�h�����N�ύڏd��
                                  ,on_leaf_deadweight             -- OUT:���[�t�ύڏd��
                                  ,on_drink_loading_capacity      -- OUT:�h�����N�ύڗe��
                                  ,on_leaf_loading_capacity       -- OUT:���[�t�ύڗe��
                                  ,on_palette_max_qty);           -- OUT:�p���b�g�ő喇��
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- �ő�z���敪�Z�o�֐��G���[
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --�󒍃\�[�X�Q��
                        ,gv_table_token                                        -- �g�[�N���FTABLE_NAME
                        ,gv_table_token01_nm                                   -- �e�[�u�����F�󒍃w�b�_(�A�h�I��)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- �p�����[�^�F�R�[�h�敪�P
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                        ,gv_param5_token
                        ,lv_code_class2                                        -- �p�����[�^�F�R�[�h�敪�Q
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- �p�����[�^�F���i�敪
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- �p�����[�^�F�d�ʗe�ϋ敪
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- �p�����[�^�F���
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- �ő�z���敪�Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- �ő�p���b�g�����擾
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.�R�[�h�敪�P
                                lv_entering_despatching_code1,  -- 2.���o�ɏꏊ�R�[�h�P
                                lv_code_class2,                 -- 3.�R�[�h�敪�Q
                                lv_entering_despatching_code2,  -- 4.���o�ɏꏊ�R�[�h�Q
                                ld_standard_date,               -- 5.���(�K�p�����)
                                lv_ship_methods,                -- 6.�z���敪
                                on_drink_deadweight,            -- 7.�h�����N�ύڏd��
                                on_leaf_deadweight,             -- 8.���[�t�ύڏd��
                                on_drink_loading_capacity,      -- 9.�h�����N�ύڗe��
                                on_leaf_loading_capacity,       -- 10.���[�t�ύڗe��
                                on_palette_max_qty);            -- 11.�p���b�g�ő喇��
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- �ő�p���b�g�����Z�o�֐��G���[
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --�z��No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --�󒍃\�[�X�Q��
                      ,gv_table_token                   -- �g�[�N���FTABLE_NAME
                      ,gv_table_token01_nm              -- �e�[�u�����F�󒍃w�b�_(�A�h�I��)
                      ,gv_param1_token
                      ,lv_code_class1                   -- �p�����[�^�F�R�[�h�敪�P
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                      ,gv_param3_token
                      ,lv_code_class2                   -- �p�����[�^�F�R�[�h�敪�Q
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD') -- �p�����[�^�F���
                      ,gv_param6_token
                      ,lv_ship_methods                  -- �p�����[�^�F�z���敪
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;   -- �ő�p���b�g�����Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        -- �h�����N�ύ�
        gr_order_h_rec.based_weight              := on_drink_deadweight;
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        -- ���[�t�ύ�
        gr_order_h_rec.based_weight              := on_leaf_deadweight;
      END IF;
--
      -- ��{�e��
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        -- �h�����N�e��
        gr_order_h_rec.based_capacity            := on_drink_loading_capacity;
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        -- ���[�t�e��
        gr_order_h_rec.based_capacity            := on_leaf_loading_capacity;
--
      END IF;
--
      -- �z���敪
      gr_order_h_rec.shipping_method_code     := gr_interface_info_rec(in_index).shipping_method_code;
      -- �z���敪_����
      gr_order_h_rec.result_shipping_method_code := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    -- �p���b�g���і���
    gr_order_h_rec.real_pallet_quantity        := gr_interface_info_rec(in_index).used_pallet_qty;
    -- �^���Ǝ�_ID_����
    gr_order_h_rec.result_freight_carrier_id   := gr_interface_info_rec(in_index).result_freight_carrier_id;
    -- �^���Ǝ�_����
    gr_order_h_rec.result_freight_carrier_code := gr_interface_info_rec(in_index).freight_carrier_code;
    -- �o�א�_����ID
    gr_order_h_rec.result_deliver_to_id        := gr_interface_info_rec(in_index).result_deliver_to_id;
    -- �o�א�_����
    gr_order_h_rec.result_deliver_to           := gr_interface_info_rec(in_index).party_site_code;
    -- �o�ד�
    gr_order_h_rec.shipped_date                := gr_interface_info_rec(in_index).shipped_date;
    -- ���ד�
    gr_order_h_rec.arrival_date                := gr_interface_info_rec(in_index).arrival_date;
    -- �d�ʗe�ϋ敪
    gr_order_h_rec.weight_capacity_class       := gr_interface_info_rec(in_index).weight_capacity_class;
    -- �ʒm�X�e�[�^�X
    gr_order_h_rec.notif_status                := gv_notif_status_40;
    -- �O��ʒm�X�e�[�^�X
    gr_order_h_rec.prev_notif_status           := gv_notif_status_10;
    -- �m��ʒm���{����
    gr_order_h_rec.notif_date                  := gd_sysdate;
--
    -- ���ъǗ�����
    -- (210)���_�o�׊m��񍐁E(215)���o�׊m��񍐂̏ꍇ�̂݃Z�b�g
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
       (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215) THEN
--
      BEGIN
        SELECT xlv2.location_code
        INTO   lt_location_code
        FROM  fnd_user fu
             ,per_all_assignments_f paaf
             ,xxcmn_locations2_v xlv2
        WHERE fu.user_id        = gt_user_id
        AND   paaf.person_id    = fu.employee_id
        AND   paaf.primary_flag = gv_yesno_y
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN paaf.effective_start_date AND paaf.effective_end_date
        AND   paaf.location_id  = xlv2.location_id
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN xlv2.start_date_active AND xlv2.end_date_active;
--
        gr_order_h_rec.performance_management_dept := lt_location_code;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            gr_order_h_rec.performance_management_dept := NULL;
      END;
--
    END IF;
--
    -- �w������
    gr_order_h_rec.instruction_dept := gr_interface_info_rec(in_index).report_post_code;
--
    -- �L���o�ו񍐂̏ꍇ�ɂ̂݃Z�b�g
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200) THEN
      -- �����ID
      gr_order_h_rec.vendor_id        := gr_interface_info_rec(in_index).vendor_id;
      -- �����
      gr_order_h_rec.vendor_code      := gr_interface_info_rec(in_index).vendor_site_code;
      -- �����T�C�gID
      gr_order_h_rec.vendor_site_id   := gr_interface_info_rec(in_index).vendor_site_id;
      -- �����T�C�g
      gr_order_h_rec.vendor_site_code := gr_interface_info_rec(in_index).party_site_code;
--
   ELSE
      gr_order_h_rec.vendor_id        := NULL;      -- �����ID
      gr_order_h_rec.vendor_code      := NULL;      -- �����
      gr_order_h_rec.vendor_site_id   := NULL;      -- �����T�C�gID
      gr_order_h_rec.vendor_site_code := NULL;      -- �����T�C�g
   END iF;
--
    -- ��ʍX�V����
    gr_order_h_rec.screen_update_date          := gd_sysdate;
    -- ��ʍX�V��
    gr_order_h_rec.screen_update_by            := gt_user_id;
--
    -- �o�^�������{
    INSERT INTO xxwsh_order_headers_all
      ( order_header_id                             -- �󒍃w�b�_�A�h�I��ID
       ,order_type_id                               -- �󒍃^�C�vID
       ,organization_id                             -- �g�DID
       ,latest_external_flag                        -- �ŐV�t���O
       ,ordered_date                                -- �󒍓�
       ,customer_id                                 -- �ڋqID
       ,customer_code                               -- �ڋq
       ,deliver_to_id                               -- �o�א�ID
       ,deliver_to                                  -- �o�א�
       ,career_id                                   -- �^���Ǝ�ID
       ,freight_carrier_code                        -- �^���Ǝ�
       ,shipping_method_code                        -- �z���敪
       ,cust_po_number                              -- �ڋq����
       ,request_no                                  -- �˗�No
       ,req_status                                  -- �X�e�[�^�X
       ,delivery_no                                 -- �z��no
       ,prev_delivery_no                            -- �O��z��no
       ,schedule_ship_date                          -- �o�ח\���
       ,schedule_arrival_date                       -- ���ח\���
       ,collected_pallet_qty                        -- �p���b�g�������
       ,confirm_request_class                       -- �����S���m�F�˗��敪
       ,freight_charge_class                        -- �^���敪
       ,deliver_from_id                             -- �o�׌�ID
       ,deliver_from                                -- �o�׌��ۊǏꏊ
       ,head_sales_branch                           -- �Ǌ����_
       ,prod_class                                  -- ���i�敪
       ,no_cont_freight_class                       -- �_��O�^���敪
       ,arrival_time_from                           -- ���׎���from
       ,arrival_time_to                             -- ���׎���to
       ,based_weight                                -- ��{�d��
       ,based_capacity                              -- ��{�e��
       ,real_pallet_quantity                        -- �p���b�g���і���
       ,result_freight_carrier_id                   -- �^���Ǝ�_����ID
       ,result_freight_carrier_code                 -- �^���Ǝ�_����
       ,result_shipping_method_code                 -- �z���敪_����
       ,result_deliver_to_id                        -- �o�א�_����ID
       ,result_deliver_to                           -- �o�א�_����
       ,shipped_date                                -- �o�ד�
       ,arrival_date                                -- ���ד�
       ,weight_capacity_class                       -- �d�ʗe�ϋ敪
       ,notif_status                                -- �ʒm�X�e�[�^�X
       ,prev_notif_status                           -- �O��ʒm�X�e�[�^�X
       ,notif_date                                  -- �m��ʒm���{����
       ,new_modify_flg                              -- �V�K�C���t���O
       ,performance_management_dept                 -- ���ъǗ�����
       ,instruction_dept                            -- �w������
       ,vendor_id                                   -- �����ID
       ,vendor_code                                 -- �����
       ,vendor_site_id                              -- �����T�C�gID
       ,vendor_site_code                            -- �����T�C�g
       ,screen_update_date                          -- ��ʍX�V����
       ,screen_update_by                            -- ��ʍX�V��
       ,corrected_tighten_class                     -- ���ߌ�C���敪
       ,created_by                                  -- �쐬��
       ,creation_date                               -- �쐬��
       ,last_updated_by                             -- �ŏI�X�V��
       ,last_update_date                            -- �ŏI�X�V��
       ,last_update_login                           -- �ŏI�X�V���O�C��
       ,request_id                                  -- �v��id
       ,program_application_id                      -- �A�v���P�[�V����id
       ,program_id                                  -- �R���J�����g�E�v���O����id
       ,program_update_date                         -- �v���O�����X�V��
      )
      VALUES
      ( gr_order_h_rec.order_header_id              -- �󒍃w�b�_�A�h�I��ID
       ,gr_order_h_rec.order_type_id                -- �󒍃^�C�vID
       ,gr_order_h_rec.organization_id              -- �g�DID
       ,gr_order_h_rec.latest_external_flag         -- �ŐV�t���O
       ,gr_order_h_rec.ordered_date                 -- �󒍓�
       ,gr_order_h_rec.customer_id                  -- �ڋqID
       ,gr_order_h_rec.customer_code                -- �ڋq
       ,gr_order_h_rec.deliver_to_id                -- �o�א�ID
       ,gr_order_h_rec.deliver_to                   -- �o�א�
       ,gr_order_h_rec.career_id                    -- �^���Ǝ�ID
       ,gr_order_h_rec.freight_carrier_code         -- �^���Ǝ�
       ,gr_order_h_rec.shipping_method_code         -- �z���敪
       ,gr_order_h_rec.cust_po_number               -- �ڋq����
       ,gr_order_h_rec.request_no                   -- �˗�No
       ,gr_order_h_rec.req_status                   -- �X�e�[�^�X
       ,gr_order_h_rec.delivery_no                  -- �z��no
       ,gr_order_h_rec.prev_delivery_no             -- �O��z��no
       ,gr_order_h_rec.schedule_ship_date           -- �o�ח\���
       ,gr_order_h_rec.schedule_arrival_date        -- ���ח\���
       ,gr_order_h_rec.collected_pallet_qty         -- �p���b�g�������
       ,gv_include_exclude_0                        -- �����S���m�F�˗��敪
       ,gr_order_h_rec.freight_charge_class         -- �^���敪
       ,gr_order_h_rec.deliver_from_id              -- �o�׌�ID
       ,gr_order_h_rec.deliver_from                 -- �o�׌��ۊǏꏊ
       ,gr_order_h_rec.head_sales_branch            -- �Ǌ����_
       ,gr_order_h_rec.prod_class                   -- ���i�敪
       ,gv_include_exclude_0                        -- �����S���m�F�˗��敪
       ,gr_order_h_rec.arrival_time_from            -- ���׎���from
       ,gr_order_h_rec.arrival_time_to              -- ���׎���to
       ,gr_order_h_rec.based_weight                 -- ��{�d��
       ,gr_order_h_rec.based_capacity               -- ��{�e��
       ,gr_order_h_rec.real_pallet_quantity         -- �p���b�g���і���
       ,gr_order_h_rec.result_freight_carrier_id    -- �^���Ǝ�_����ID
       ,gr_order_h_rec.result_freight_carrier_code  -- �^���Ǝ�_����
       ,gr_order_h_rec.result_shipping_method_code  -- �z���敪_����
       ,gr_order_h_rec.result_deliver_to_id         -- �o�א�_����ID
       ,gr_order_h_rec.result_deliver_to            -- �o�א�_����
       ,gr_order_h_rec.shipped_date                 -- �o�ד�
       ,gr_order_h_rec.arrival_date                 -- ���ד�
       ,gr_order_h_rec.weight_capacity_class        -- �d�ʗe�ϋ敪
       ,gr_order_h_rec.notif_status                 -- �ʒm�X�e�[�^�X
       ,gr_order_h_rec.prev_notif_status            -- �O��ʒm�X�e�[�^�X
       ,gr_order_h_rec.notif_date                   -- �m��ʒm���{����
       ,gv_yesno_n                                  -- �V�K�C���t���O
       ,gr_order_h_rec.performance_management_dept  -- ���ъǗ�����
       ,gr_order_h_rec.instruction_dept             -- �w������
       ,gr_order_h_rec.vendor_id                    -- �����ID
       ,gr_order_h_rec.vendor_code                  -- �����
       ,gr_order_h_rec.vendor_site_id               -- �����T�C�gID
       ,gr_order_h_rec.vendor_site_code             -- �����T�C�g
       ,gr_order_h_rec.screen_update_date           -- ��ʍX�V����
       ,gr_order_h_rec.screen_update_by             -- ��ʍX�V��
       ,gv_yesno_n                                  -- ���ߌ�C���敪
       ,gt_user_id                                  -- �쐬��
       ,gt_sysdate                                  -- �쐬��
       ,gt_user_id                                  -- �ŏI�X�V��
       ,gt_sysdate                                  -- �ŏI�X�V��
       ,gt_login_id                                 -- �ŏI�X�V���O�C��
       ,gt_conc_request_id                          -- �v��ID
       ,gt_prog_appl_id                             -- �A�v���P�[�V����ID
       ,gt_conc_program_id                          -- �R���J�����g�E�v���O����ID
       ,gt_sysdate                                  -- �v���O�����X�V��
      );
--
--********** 2008/07/07 ********** DELETE START ***
--*     --�󒍃w�b�_�o�^�쐬����(�O���q�ɔ���)
--*     gn_ord_h_ins_cnt := gn_ord_h_ins_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_headers_ins;
--
 /**********************************************************************************
  * Procedure Name   : order_headers_upd
  * Description      : �󒍃w�b�_�A�h�I��(���ьv��ҏW) �v���V�[�W��(A-8-1)
  ***********************************************************************************/
  PROCEDURE order_headers_upd(
    in_index                IN  NUMBER,                 -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_headers_upd'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    --�󒍃w�b�_ID
    lt_order_header_id            xxwsh_order_headers_all.order_header_id%TYPE;
    --�˗�No
    lt_request_no                 xxwsh_order_headers_all.request_no%TYPE;
    --�z��no
    lt_delivery_no                xxwsh_order_headers_all.delivery_no%TYPE;
    --���ъǗ�����
    lt_location_code              xxwsh_order_headers_all.performance_management_dept%TYPE;
--
    -- �ő�p���b�g�����Z�o�֐��p�����[�^
    lv_code_class1                VARCHAR2(2);                -- 1.�R�[�h�敪�P
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.���o�ɏꏊ�R�[�h�P
    lv_code_class2                VARCHAR2(2);                -- 3.�R�[�h�敪�Q
    lv_entering_despatching_code2 VARCHAR2(9);                -- 4.���o�ɏꏊ�R�[�h�Q
    ld_standard_date              DATE;                       -- 5.���(�K�p�����)
    lv_ship_methods               VARCHAR2(2);                -- 6.�z���敪
    on_drink_deadweight           NUMBER;                     -- 7.�h�����N�ύڏd��
    on_leaf_deadweight            NUMBER;                     -- 8.���[�t�ύڏd��
    on_drink_loading_capacity     NUMBER;                     -- 9.�h�����N�ύڗe��
    on_leaf_loading_capacity      NUMBER;                     -- 10.���[�t�ύڗe��
    on_palette_max_qty            NUMBER;                     -- 11.�p���b�g�ő喇��
--
    ln_ret_code                   NUMBER;                     -- ���^�[���E�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_order_h_rec := gr_order_h_ini;
--
    -- �󒍃w�b�_�A�h�I���ҏW����
    -- �˗�No
    gr_order_h_rec.request_no           := gr_interface_info_rec(in_index).order_source_ref;
    -- �z��no
    gr_order_h_rec.delivery_no          := gr_interface_info_rec(in_index).delivery_no;
    -- �X�e�[�^�X
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.req_status         := gv_req_status_04;
    END IF;
    -- �p���b�g�������
    gr_order_h_rec.collected_pallet_qty := gr_interface_info_rec(in_index).collected_pallet_qty;
--
    --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      -- ��{�d��
      -- �p�����[�^���擾
      -- 1.�R�[�h�敪�P
      lv_code_class1                := gv_code_class_04;
      -- 2.���o�ɏꏊ�R�[�h�P
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
--
      -- 3.�R�[�h�敪�Q
      -- 2008/08/06 Start --------------------------------------------------------
      --lv_code_class2                := gv_code_class_09;
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200) THEN
        lv_code_class2                := gv_code_class_11;  -- �x���̏ꍇ(200)
      ELSE
        lv_code_class2                := gv_code_class_09;  -- �o�ׂ̏ꍇ(210,215)
      END IF;
      -- 2008/08/06 End ----------------------------------------------------------
      -- 4.���o�ɏꏊ�R�[�h�Q
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).party_site_code;
      -- 5.���(�K�p�����)
      ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      -- 6.�z���敪
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- �z���敪��NULL�̏ꍇ�A�ő�z���敪���擾���čő�p���b�g�������擾����B
      IF (lv_ship_methods IS NULL) THEN
--
        -- �ő�z���敪�Z�o�֐�
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:�R�[�h�敪1
                                  ,lv_entering_despatching_code1                         -- IN:���o�ɏꏊ�R�[�h1
                                  ,lv_code_class2                                        -- IN:�R�[�h�敪2
                                  ,lv_entering_despatching_code2                         -- IN:���o�ɏꏊ�R�[�h2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:���i�敪
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:�d�ʗe�ϋ敪
                                  ,NULL                                                  -- IN:�����z�ԑΏۋ敪
                                  ,ld_standard_date                                      -- IN:���
                                  ,lv_ship_methods                -- OUT:�ő�z���敪
                                  ,on_drink_deadweight            -- OUT:�h�����N�ύڏd��
                                  ,on_leaf_deadweight             -- OUT:���[�t�ύڏd��
                                  ,on_drink_loading_capacity      -- OUT:�h�����N�ύڗe��
                                  ,on_leaf_loading_capacity       -- OUT:���[�t�ύڗe��
                                  ,on_palette_max_qty);           -- OUT:�p���b�g�ő喇��
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- �ő�z���敪�Z�o�֐��G���[
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --�󒍃\�[�X�Q��
                        ,gv_table_token                                        -- �g�[�N���FTABLE_NAME
                        ,gv_table_token01_nm                                   -- �e�[�u�����F�󒍃w�b�_(�A�h�I��)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- �p�����[�^�F�R�[�h�敪�P
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                        ,gv_param5_token
                        ,lv_code_class2                                        -- �p�����[�^�F�R�[�h�敪�Q
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- �p�����[�^�F���i�敪
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- �p�����[�^�F�d�ʗe�ϋ敪
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- �p�����[�^�F���
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- �ő�z���敪�Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- �ő�p���b�g�����擾
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.�R�[�h�敪�P
                                lv_entering_despatching_code1,  -- 2.���o�ɏꏊ�R�[�h�P
                                lv_code_class2,                 -- 3.�R�[�h�敪�Q
                                lv_entering_despatching_code2,  -- 4.���o�ɏꏊ�R�[�h�Q
                                ld_standard_date,               -- 5.���(�K�p�����)
                                lv_ship_methods,                -- 6.�z���敪
                                on_drink_deadweight,            -- 7.�h�����N�ύڏd��
                                on_leaf_deadweight,             -- 8.���[�t�ύڏd��
                                on_drink_loading_capacity,      -- 9.�h�����N�ύڗe��
                                on_leaf_loading_capacity,       -- 10.���[�t�ύڗe��
                                on_palette_max_qty);            -- 11.�p���b�g�ő喇��
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- �ő�p���b�g�����Z�o�֐��G���[
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --�z��No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --�󒍃\�[�X�Q��
                      ,gv_table_token                   -- �g�[�N���FTABLE_NAME
                      ,gv_table_token01_nm              -- �e�[�u�����F�󒍃w�b�_(�A�h�I��)
                      ,gv_param1_token
                      ,lv_code_class1                   -- �p�����[�^�F�R�[�h�敪�P
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                      ,gv_param3_token
                      ,lv_code_class2                   -- �p�����[�^�F�R�[�h�敪�Q
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                 -- �p�����[�^�F���
                      ,gv_param6_token
                      ,lv_ship_methods                  -- �p�����[�^�F�z���敪
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;    -- �ő�p���b�g�����Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_order_h_rec.based_weight       := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_order_h_rec.based_weight       := on_leaf_deadweight;
      END IF;
--
      -- ��{�e��
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_order_h_rec.based_capacity     := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_order_h_rec.based_capacity     := on_leaf_loading_capacity;
      END IF;
--
      -- �z���敪_����
      gr_order_h_rec.result_shipping_method_code := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    -- �p���b�g���і���
    gr_order_h_rec.real_pallet_quantity := gr_interface_info_rec(in_index).used_pallet_qty;
    -- �^���Ǝ�_ID_����
    gr_order_h_rec.result_freight_carrier_id   := gr_interface_info_rec(in_index).result_freight_carrier_id;
    -- �^���Ǝ�_����
    gr_order_h_rec.result_freight_carrier_code := gr_interface_info_rec(in_index).freight_carrier_code;
    -- �o�א�_����ID
    gr_order_h_rec.result_deliver_to_id := gr_interface_info_rec(in_index).result_deliver_to_id;
    -- �o�א�_����
    gr_order_h_rec.result_deliver_to    := gr_interface_info_rec(in_index).party_site_code;
    -- �o�ד�
    gr_order_h_rec.shipped_date         := gr_interface_info_rec(in_index).shipped_date;
    -- ���ד�
    gr_order_h_rec.arrival_date         := gr_interface_info_rec(in_index).arrival_date;
--
    -- ���ъǗ�����
    -- (210)���_�o�׊m��񍐁E(215)���o�׊m��񍐂̏ꍇ�̂݃Z�b�g
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210) OR
       (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215) THEN
--
      BEGIN
        SELECT xlv2.location_code
        INTO   lt_location_code
        FROM  fnd_user fu
             ,per_all_assignments_f paaf
             ,xxcmn_locations2_v xlv2
        WHERE fu.user_id        = gt_user_id
        AND   paaf.person_id    = fu.employee_id
        AND   paaf.primary_flag = gv_yesno_y
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN paaf.effective_start_date AND paaf.effective_end_date
        AND   paaf.location_id  = xlv2.location_id
        AND   gr_interface_info_rec(in_index).shipped_date
          BETWEEN xlv2.start_date_active AND xlv2.end_date_active;
--
        gr_order_h_rec.performance_management_dept := lt_location_code;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gr_order_h_rec.performance_management_dept := NULL;
      END;
--
    ELSE
      gr_order_h_rec.performance_management_dept := NULL;
    END IF;
--
     -- (210)���_�o�׊m��񍐁E(215)���o�׊m��񍐈ȊO�̏ꍇ
     -- (210)���_�o�׊m��񍐁E(215)���o�׊m��񍐂̏ꍇ�ŁA���ъǗ��������Ȃ��ꍇ
    IF (gr_order_h_rec.performance_management_dept IS NULL) THEN
      UPDATE xxwsh.xxwsh_order_headers_all xoha
      SET xoha.req_status                   = gr_order_h_rec.req_status
         ,xoha.collected_pallet_qty         = gr_order_h_rec.collected_pallet_qty
         ,xoha.based_weight                 = gr_order_h_rec.based_weight
         ,xoha.based_capacity               = gr_order_h_rec.based_capacity
         ,xoha.real_pallet_quantity         = gr_order_h_rec.real_pallet_quantity
         ,xoha.result_freight_carrier_id    = gr_order_h_rec.result_freight_carrier_id
         ,xoha.result_freight_carrier_code  = gr_order_h_rec.result_freight_carrier_code
         ,xoha.result_shipping_method_code  = gr_order_h_rec.result_shipping_method_code
         ,xoha.result_deliver_to_id         = gr_order_h_rec.result_deliver_to_id
         ,xoha.result_deliver_to            = gr_order_h_rec.result_deliver_to
         ,xoha.shipped_date                 = gr_order_h_rec.shipped_date
         ,xoha.arrival_date                 = gr_order_h_rec.arrival_date
         ----,xoha.performance_management_dept  = gr_order_h_rec.performance_management_dept --���ъǗ�����
         ,xoha.last_updated_by              = gt_user_id
         ,xoha.last_update_date             = gt_sysdate
         ,xoha.last_update_login            = gt_login_id
         ,xoha.request_id                   = gt_conc_request_id
         ,xoha.program_application_id       = gt_prog_appl_id
         ,xoha.program_id                   = gt_conc_program_id
         ,xoha.program_update_date          = gt_sysdate
      WHERE xoha.request_no           = gr_order_h_rec.request_no
      AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec.delivery_no,gv_delivery_no_null)
      AND   xoha.latest_external_flag = gv_yesno_y;
--
     -- (210)���_�o�׊m��񍐁E(215)���o�׊m��񍐂̏ꍇ�ŁA���ъǗ�����������ꍇ
    ELSE
      UPDATE xxwsh.xxwsh_order_headers_all xoha
      SET xoha.req_status                   = gr_order_h_rec.req_status
         ,xoha.collected_pallet_qty         = gr_order_h_rec.collected_pallet_qty
         ,xoha.based_weight                 = gr_order_h_rec.based_weight
         ,xoha.based_capacity               = gr_order_h_rec.based_capacity
         ,xoha.real_pallet_quantity         = gr_order_h_rec.real_pallet_quantity
         ,xoha.result_freight_carrier_id    = gr_order_h_rec.result_freight_carrier_id
         ,xoha.result_freight_carrier_code  = gr_order_h_rec.result_freight_carrier_code
         ,xoha.result_shipping_method_code  = gr_order_h_rec.result_shipping_method_code
         ,xoha.result_deliver_to_id         = gr_order_h_rec.result_deliver_to_id
         ,xoha.result_deliver_to            = gr_order_h_rec.result_deliver_to
         ,xoha.shipped_date                 = gr_order_h_rec.shipped_date
         ,xoha.arrival_date                 = gr_order_h_rec.arrival_date
         ,xoha.performance_management_dept  = gr_order_h_rec.performance_management_dept --���ъǗ�����
         ,xoha.last_updated_by              = gt_user_id
         ,xoha.last_update_date             = gt_sysdate
         ,xoha.last_update_login            = gt_login_id
         ,xoha.request_id                   = gt_conc_request_id
         ,xoha.program_application_id       = gt_prog_appl_id
         ,xoha.program_id                   = gt_conc_program_id
         ,xoha.program_update_date          = gt_sysdate
      WHERE xoha.request_no           = gr_order_h_rec.request_no
      AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec.delivery_no,gv_delivery_no_null)
      AND   xoha.latest_external_flag = gv_yesno_y;
--
    END IF;
--
    -- �󒍃w�b�_ID�̎擾
    SELECT order_header_id
    INTO lt_order_header_id
    FROM xxwsh_order_headers_all xoha
    WHERE xoha.request_no           = gr_order_h_rec.request_no
    AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec.delivery_no,gv_delivery_no_null)
    AND   xoha.latest_external_flag = gv_yesno_y;
--
    gr_order_h_rec.order_header_id := lt_order_header_id;
--
--********** 2008/07/07 ********** DELETE START ***
--* -- �󒍃w�b�_�X�V�쐬����(���ьv��)���Z
--* gn_ord_h_upd_n_cnt := gn_ord_h_upd_n_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_headers_upd;
--
 /**********************************************************************************
  * Procedure Name   : order_headers_inup
  * Description      : �󒍃w�b�_�A�h�I��(���ђ������ҏW) �v���V�[�W��(A-8-3,4)
  ***********************************************************************************/
  PROCEDURE order_headers_inup(
    in_index                IN  NUMBER,                 -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_headers_inup'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    --�ŐV�t���O
    lt_latest_external_flag        xxwsh_order_headers_all.latest_external_flag%TYPE;
    lt_order_header_id             xxwsh_order_headers_all.order_header_id%TYPE;
--
    lv_ret_code                    VARCHAR2(1);     -- OUT 11.���^�[���R�[�h
    lv_err_msg_code                VARCHAR2(100);   -- OUT 12.�G���[���b�Z�[�W�R�[�h
    lv_err_msg                     VARCHAR2(5000);  -- OUT 13.�G���[���b�Z�[�W
    lv_msg_buff                    VARCHAR2(5000);
--
    TYPE order_h_up_rec IS RECORD(
      request_no                   xxwsh_order_headers_all.request_no%TYPE        --�˗�no
      ,delivery_no                 xxwsh_order_headers_all.delivery_no%TYPE       --�z��no
      ,latest_external_flag        xxwsh_order_headers_all.latest_external_flag%TYPE  --�ŐV�t���O
    );
    -- �f�[�^���i�[���錋���z��
    TYPE order_h_up_tbl IS TABLE OF order_h_up_rec INDEX BY PLS_INTEGER;
--
    gr_order_h_rec_up2      order_h_up_tbl;
    gr_order_h_rec_up2_ini  order_h_up_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    lr_order_h_rec_ins      order_h_rec;
    lr_order_h_rec_ins_ini  order_h_rec;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_order_h_rec     := gr_order_h_ini;
    gr_order_h_rec_up2 := gr_order_h_rec_up2_ini;
    lr_order_h_rec_ins := lr_order_h_rec_ins_ini;
--
    -- �󒍃w�b�_�A�h�I���ҏW����
    -- �˗�No
    gr_order_h_rec_up2(in_index).request_no           := gr_interface_info_rec(in_index).order_source_ref;
    -- �z��no
    gr_order_h_rec_up2(in_index).delivery_no          := gr_interface_info_rec(in_index).delivery_no;
    -- �ŐV�t���O
    gr_order_h_rec_up2(in_index).latest_external_flag := gv_yesno_n;
--
--********** 2008/07/11 ********** ADD    START ***
    BEGIN
--********** 2008/07/11 ********** ADD    END   ***
--
      SELECT xoha.order_header_id             --�󒍃w�b�_�A�h�I��ID
            ,xoha.order_type_id               --�󒍃^�C�vID
            ,xoha.organization_id             --�g�DID
            ,xoha.header_id                   --�󒍃w�b�_ID
            ,xoha.latest_external_flag        --�ŐV�t���O
            ,xoha.ordered_date                --�󒍓�
            ,xoha.customer_id                 --�ڋqID
            ,xoha.customer_code               --�ڋq
            ,xoha.deliver_to_id               --�o�א�ID
            ,xoha.deliver_to                  --�o�א�
            ,xoha.shipping_instructions       --�o�׎w��
            ,xoha.career_id                   --�^���Ǝ�ID
            ,xoha.freight_carrier_code        --�^���Ǝ�
            ,xoha.shipping_method_code        --�z���敪
            ,xoha.cust_po_number              --�ڋq����
            ,xoha.price_list_id               --���i�\
            ,xoha.request_no                  --�˗�no
            ,xoha.req_status                  --�X�e�[�^�X
            ,xoha.delivery_no                 --�z��no
            ,xoha.prev_delivery_no            --�O��z��no
            ,xoha.schedule_ship_date          --�o�ח\���
            ,xoha.schedule_arrival_date       --���ח\���
            ,xoha.mixed_no                    --���ڌ�no
            ,xoha.collected_pallet_qty        --�p���b�g�������
            ,xoha.confirm_request_class       --�����S���m�F�˗��敪
            ,xoha.freight_charge_class        --�^���敪
            ,xoha.shikyu_instruction_class    --�x���o�Ɏw���敪
            ,xoha.shikyu_inst_rcv_class       --�x���w����̋敪
            ,xoha.amount_fix_class            --�L�����z�m��敪
            ,xoha.takeback_class              --����敪
            ,xoha.deliver_from_id             --�o�׌�ID
            ,xoha.deliver_from                --�o�׌��ۊǏꏊ
            ,xoha.head_sales_branch           --�Ǌ����_
            ,xoha.po_no                       --����no
            ,xoha.prod_class                  --���i�敪
            ,xoha.item_class                  --�i�ڋ敪
            ,xoha.no_cont_freight_class       --�_��O�^���敪
            ,xoha.arrival_time_from           --���׎���from
            ,xoha.arrival_time_to             --���׎���to
            ,xoha.designated_item_id          --�����i��ID
            ,xoha.designated_item_code        --�����i��
            ,xoha.designated_production_date  --������
            ,xoha.designated_branch_no        --�����}��
            ,xoha.slip_number                 --�����no
            ,xoha.sum_quantity                --���v����
            ,xoha.small_quantity              --������
            ,xoha.label_quantity              --���x������
            ,xoha.loading_efficiency_weight   --�d�ʐύڌ���
            ,xoha.loading_efficiency_capacity --�e�ϐύڌ���
            ,xoha.based_weight                --��{�d��
            ,xoha.based_capacity              --��{�e��
            ,xoha.sum_weight                  --�ύڏd�ʍ��v
            ,xoha.sum_capacity                --�ύڗe�ύ��v
            ,xoha.mixed_ratio                 --���ڗ�
            ,xoha.pallet_sum_quantity         --�p���b�g���v����
            ,xoha.real_pallet_quantity        --�p���b�g���і���
            ,xoha.sum_pallet_weight           --���v�p���b�g�d��
            ,xoha.order_source_ref            --�󒍃\�[�X�Q��
            ,xoha.result_freight_carrier_id   --�^���Ǝ�_����ID
            ,xoha.result_freight_carrier_code --�^���Ǝ�_����
            ,xoha.result_shipping_method_code --�z���敪_����
            ,xoha.result_deliver_to_id        --�o�א�_����ID
            ,xoha.result_deliver_to           --�o�א�_����
            ,xoha.shipped_date                --�o�ד�
            ,xoha.arrival_date                --���ד�
            ,xoha.weight_capacity_class       --�d�ʗe�ϋ敪
            ,xoha.actual_confirm_class        --���ьv��ϋ敪
            ,xoha.notif_status                --�ʒm�X�e�[�^�X
            ,xoha.prev_notif_status           --�O��ʒm�X�e�[�^�X
            ,xoha.notif_date                  --�m��ʒm���{����
            ,xoha.new_modify_flg              --�V�K�C���t���O
            ,xoha.process_status              --�����o�߃X�e�[�^�X
            ,xoha.performance_management_dept --���ъǗ�����
            ,xoha.instruction_dept            --�w������
            ,xoha.transfer_location_id        --�U�֐�ID
            ,xoha.transfer_location_code      --�U�֐�
            ,xoha.mixed_sign                  --���ڋL��
            ,xoha.screen_update_date          --��ʍX�V����
            ,xoha.screen_update_by            --��ʍX�V��
            ,xoha.tightening_date             --�o�׈˗����ߓ���
            ,xoha.vendor_id                   --�����ID
            ,xoha.vendor_code                 --�����
            ,xoha.vendor_site_id              --�����T�C�gID
            ,xoha.vendor_site_code            --�����T�C�g
            ,xoha.registered_sequence         --�o�^����
            ,xoha.tightening_program_id       --���߃R���J�����gID
            ,xoha.corrected_tighten_class     --���ߌ�C���敪
      INTO  lr_order_h_rec_ins
      FROM  xxwsh_order_headers_all xoha
      WHERE xoha.request_no           = gr_order_h_rec_up2(in_index).request_no
      AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec_up2(in_index).delivery_no,gv_delivery_no_null)
      AND   xoha.latest_external_flag = gv_yesno_y
      -- �o�ׁF�o�׎��ьv��ρ@�x���F�x�����ьv���
      AND    xoha.req_status IN(gv_req_status_04,gv_req_status_08);
--    WHERE xoha.request_no           = gr_order_h_rec.request_no
--    AND   xoha.delivery_no          = gr_order_h_rec.delivery_no
--    AND   xoha.latest_external_flag = gv_yesno_y;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
      --�����\�Ȏw���f�[�^�����݂��Ȃ��ꍇ�A�G���[
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                                 -- 'XXWSH'
                      ,gv_msg_93a_154                             -- ���ьv��^�����s�G���[���b�Z�[�W
                      ,gv_param1_token
                      ,gr_interface_info_rec(in_index).delivery_no       -- IF_H.�z��No
                      ,gv_param2_token
                      ,gr_interface_info_rec(in_index).order_source_ref  -- IF_H.�󒍃\�[�X�Q��(�˗�/�ړ�No)
                                                         )
                                                         ,1
                                                         ,5000);
--
        RAISE no_record_expt;   -- A-8�������ׁ̈AABEND�����Ă��ׂ�ROLLBACK����
--
    END ;
--
    UPDATE xxwsh_order_headers_all xoha
    SET xoha.latest_external_flag   = gr_order_h_rec_up2(in_index).latest_external_flag
       ,xoha.last_updated_by        = gt_user_id
       ,xoha.last_update_date       = gt_sysdate
       ,xoha.last_update_login      = gt_login_id
       ,xoha.request_id             = gt_conc_request_id
       ,xoha.program_application_id = gt_prog_appl_id
       ,xoha.program_id             = gt_conc_program_id
       ,xoha.program_update_date    = gt_sysdate
    WHERE xoha.request_no           = gr_order_h_rec_up2(in_index).request_no
    AND   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_order_h_rec_up2(in_index).delivery_no,gv_delivery_no_null)
    AND   xoha.latest_external_flag = gv_yesno_y;
--
    -- �󒍃w�b�_ID�擾(�V�[�P���X)
    SELECT xxwsh_order_headers_all_s1.NEXTVAL
    INTO lt_order_header_id
    FROM dual;
--
    gr_order_h_rec.order_header_id             := lt_order_header_id;
    gr_order_h_rec.order_type_id               := lr_order_h_rec_ins.order_type_id;
    gr_order_h_rec.organization_id             := lr_order_h_rec_ins.organization_id;
    gr_order_h_rec.latest_external_flag        := gv_yesno_y;
    gr_order_h_rec.ordered_date                := lr_order_h_rec_ins.ordered_date;
    gr_order_h_rec.customer_id                 := lr_order_h_rec_ins.customer_id;
    gr_order_h_rec.customer_code               := lr_order_h_rec_ins.customer_code;
    gr_order_h_rec.deliver_to_id               := lr_order_h_rec_ins.deliver_to_id;
    gr_order_h_rec.deliver_to                  := lr_order_h_rec_ins.deliver_to;
    gr_order_h_rec.shipping_instructions       := lr_order_h_rec_ins.shipping_instructions;
    gr_order_h_rec.career_id                   := lr_order_h_rec_ins.career_id;
    gr_order_h_rec.freight_carrier_code        := lr_order_h_rec_ins.freight_carrier_code;
    gr_order_h_rec.shipping_method_code        := lr_order_h_rec_ins.shipping_method_code;
    gr_order_h_rec.cust_po_number              := lr_order_h_rec_ins.cust_po_number;
    gr_order_h_rec.price_list_id               := lr_order_h_rec_ins.price_list_id;
    gr_order_h_rec.request_no                  := lr_order_h_rec_ins.request_no;
    IF ((gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_215))
    THEN
      gr_order_h_rec.req_status                  := gv_req_status_04;
    END IF;
    gr_order_h_rec.delivery_no                 := lr_order_h_rec_ins.delivery_no;
    gr_order_h_rec.schedule_ship_date          := lr_order_h_rec_ins.schedule_ship_date;
    gr_order_h_rec.schedule_arrival_date       := lr_order_h_rec_ins.schedule_arrival_date;
    gr_order_h_rec.mixed_no                    := lr_order_h_rec_ins.mixed_no;
    gr_order_h_rec.collected_pallet_qty        := lr_order_h_rec_ins.collected_pallet_qty;
    gr_order_h_rec.confirm_request_class       := lr_order_h_rec_ins.confirm_request_class;
    gr_order_h_rec.freight_charge_class        := lr_order_h_rec_ins.freight_charge_class;
    gr_order_h_rec.shikyu_instruction_class    := lr_order_h_rec_ins.shikyu_instruction_class;
    gr_order_h_rec.shikyu_inst_rcv_class       := lr_order_h_rec_ins.shikyu_inst_rcv_class;
    gr_order_h_rec.deliver_from_id             := lr_order_h_rec_ins.deliver_from_id;
    gr_order_h_rec.deliver_from                := lr_order_h_rec_ins.deliver_from;
    gr_order_h_rec.head_sales_branch           := lr_order_h_rec_ins.head_sales_branch;
    gr_order_h_rec.po_no                       := lr_order_h_rec_ins.po_no;
    gr_order_h_rec.prod_class                  := lr_order_h_rec_ins.prod_class;
    gr_order_h_rec.no_cont_freight_class       := lr_order_h_rec_ins.no_cont_freight_class;
    gr_order_h_rec.arrival_time_from           := lr_order_h_rec_ins.arrival_time_from;
    gr_order_h_rec.arrival_time_to             := lr_order_h_rec_ins.arrival_time_to;
    gr_order_h_rec.designated_item_id          := lr_order_h_rec_ins.designated_item_id;
    gr_order_h_rec.designated_item_code        := lr_order_h_rec_ins.designated_item_code;
    gr_order_h_rec.designated_production_date  := lr_order_h_rec_ins.designated_production_date;
    gr_order_h_rec.designated_branch_no        := lr_order_h_rec_ins.designated_branch_no;
    gr_order_h_rec.slip_number                 := lr_order_h_rec_ins.slip_number;
    gr_order_h_rec.sum_quantity                := lr_order_h_rec_ins.sum_quantity;
    gr_order_h_rec.small_quantity              := lr_order_h_rec_ins.small_quantity;
    gr_order_h_rec.label_quantity              := lr_order_h_rec_ins.label_quantity;
    gr_order_h_rec.loading_efficiency_weight   := lr_order_h_rec_ins.loading_efficiency_weight;
    gr_order_h_rec.loading_efficiency_capacity := lr_order_h_rec_ins.loading_efficiency_capacity;
    gr_order_h_rec.based_weight                := lr_order_h_rec_ins.based_weight;
    gr_order_h_rec.based_capacity              := lr_order_h_rec_ins.based_capacity;
    gr_order_h_rec.mixed_ratio                 := lr_order_h_rec_ins.mixed_ratio;
    gr_order_h_rec.pallet_sum_quantity         := lr_order_h_rec_ins.pallet_sum_quantity;
    gr_order_h_rec.real_pallet_quantity        := gr_interface_info_rec(in_index).used_pallet_qty;
    gr_order_h_rec.result_freight_carrier_id   := gr_interface_info_rec(in_index).result_freight_carrier_id;
    gr_order_h_rec.result_freight_carrier_code := gr_interface_info_rec(in_index).freight_carrier_code;
    gr_order_h_rec.result_shipping_method_code := gr_interface_info_rec(in_index).shipping_method_code;
    gr_order_h_rec.result_deliver_to_id        := gr_interface_info_rec(in_index).result_deliver_to_id;
    gr_order_h_rec.result_deliver_to           := gr_interface_info_rec(in_index).party_site_code;
    gr_order_h_rec.shipped_date                := gr_interface_info_rec(in_index).shipped_date;
    gr_order_h_rec.arrival_date                := gr_interface_info_rec(in_index).arrival_date;
    gr_order_h_rec.weight_capacity_class       := lr_order_h_rec_ins.weight_capacity_class;
    gr_order_h_rec.notif_status                := lr_order_h_rec_ins.notif_status;
    gr_order_h_rec.performance_management_dept := lr_order_h_rec_ins.performance_management_dept;
    gr_order_h_rec.instruction_dept            := lr_order_h_rec_ins.instruction_dept;
    gr_order_h_rec.transfer_location_id        := lr_order_h_rec_ins.transfer_location_id;
    gr_order_h_rec.transfer_location_code      := lr_order_h_rec_ins.transfer_location_code;
    gr_order_h_rec.mixed_sign                  := lr_order_h_rec_ins.mixed_sign;
    gr_order_h_rec.screen_update_date          := lr_order_h_rec_ins.screen_update_date;
    gr_order_h_rec.screen_update_by            := lr_order_h_rec_ins.screen_update_by;
    gr_order_h_rec.tightening_date             := lr_order_h_rec_ins.tightening_date;
    gr_order_h_rec.vendor_id                   := lr_order_h_rec_ins.vendor_id;
    gr_order_h_rec.vendor_code                 := lr_order_h_rec_ins.vendor_code;
    gr_order_h_rec.vendor_site_id              := lr_order_h_rec_ins.vendor_site_id;
    gr_order_h_rec.vendor_site_code            := lr_order_h_rec_ins.vendor_site_code;
--
    INSERT INTO xxwsh_order_headers_all
      ( order_header_id                              -- �󒍃w�b�_�A�h�I��ID
       ,order_type_id                                -- �󒍃^�C�vID
       ,organization_id                              -- �g�DID
       ,latest_external_flag                         -- �ŐV�t���O
       ,ordered_date                                 -- �󒍓�
       ,customer_id                                  -- �ڋqID
       ,customer_code                                -- �ڋq
       ,deliver_to_id                                -- �o�א�ID
       ,deliver_to                                   -- �o�א�
       ,shipping_instructions                        -- �o�׎w��
       ,career_id                                    -- �^���Ǝ�ID
       ,freight_carrier_code                         -- �^���Ǝ�
       ,shipping_method_code                         -- �z���敪
       ,cust_po_number                               -- �ڋq����
       ,price_list_id                                -- ���i�\
       ,request_no                                   -- �˗�No
       ,req_status                                   -- �X�e�[�^�X
       ,delivery_no                                  -- �z��no
       ,schedule_ship_date                           -- �o�ח\���
       ,schedule_arrival_date                        -- ���ח\���
       ,mixed_no                                     -- ���ڌ�No
       ,collected_pallet_qty                         -- �p���b�g�������
       ,confirm_request_class                        -- �����S���m�F�˗��敪
       ,freight_charge_class                         -- �^���敪
       ,shikyu_instruction_class                     -- �x���o�Ɏw���敪
       ,shikyu_inst_rcv_class                        -- �x���w����̋敪
       ,deliver_from_id                              -- �o�׌�ID
       ,deliver_from                                 -- �o�׌��ۊǏꏊ
       ,head_sales_branch                            -- �Ǌ����_
       ,po_no                                        -- ����No
       ,prod_class                                   -- ���i�敪
       ,no_cont_freight_class                        -- �_��O�^���敪
       ,arrival_time_from                            -- ���׎���from
       ,arrival_time_to                              -- ���׎���to
       ,designated_item_id                           -- �����i��ID
       ,designated_item_code                         -- �����i��
       ,designated_production_date                   -- ������
       ,designated_branch_no                         -- �����}��
       ,slip_number                                  -- �����No
       ,sum_quantity                                 -- ���v����
       ,small_quantity                               -- ������
       ,label_quantity                               -- ���x������
       ,loading_efficiency_weight                    -- �d�ʐύڌ���
       ,loading_efficiency_capacity                  -- �e�ϐύڌ���
       ,based_weight                                 -- ��{�d��
       ,based_capacity                               -- ��{�e��
       ,mixed_ratio                                  -- ���ڗ�
       ,pallet_sum_quantity                          -- �p���b�g���v����
       ,real_pallet_quantity                         -- �p���b�g���і���
       ,result_freight_carrier_id                    -- �^���Ǝ�_����ID
       ,result_freight_carrier_code                  -- �^���Ǝ�_����
       ,result_shipping_method_code                  -- �z���敪_����
       ,result_deliver_to_id                         -- �o�א�_����ID
       ,result_deliver_to                            -- �o�א�_����
       ,shipped_date                                 -- �o�ד�
       ,arrival_date                                 -- ���ד�
       ,weight_capacity_class                        -- �d�ʗe�ϋ敪
       ,notif_status                                 -- �ʒm�X�e�[�^�X
       ,new_modify_flg                               -- �V�K�C���t���O
       ,performance_management_dept                  -- ���ъǗ�����
       ,instruction_dept                             -- �w������
       ,transfer_location_id                         -- �U�֐�ID
       ,transfer_location_code                       -- �U�֐�
       ,mixed_sign                                   -- ���ڋL��
       ,screen_update_date                           -- ��ʍX�V����
       ,screen_update_by                             -- ��ʍX�V��
       ,tightening_date                              -- �o�׈˗����ߓ���
       ,vendor_id                                    -- �����ID
       ,vendor_code                                  -- �����
       ,vendor_site_id                               -- �����T�C�gID
       ,vendor_site_code                             -- �����T�C�g
       ,corrected_tighten_class                      -- ���ߌ�C���敪
       ,created_by                                   -- �쐬��
       ,creation_date                                -- �쐬��
       ,last_updated_by                              -- �ŏI�X�V��
       ,last_update_date                             -- �ŏI�X�V��
       ,last_update_login                            -- �ŏI�X�V���O�C��
       ,request_id                                   -- �v��id
       ,program_application_id                       -- �A�v���P�[�V����id
       ,program_id                                   -- �R���J�����g�E�v���O����id
       ,program_update_date                          -- �v���O�����X�V��
      )
      VALUES
      ( gr_order_h_rec.order_header_id               -- �󒍃w�b�_�A�h�I��ID
       ,gr_order_h_rec.order_type_id                 -- �󒍃^�C�vID
       ,gr_order_h_rec.organization_id               -- �g�DID
       ,gr_order_h_rec.latest_external_flag          -- �ŐV�t���O
       ,gr_order_h_rec.ordered_date                  -- �󒍓�
       ,gr_order_h_rec.customer_id                   -- �ڋqID
       ,gr_order_h_rec.customer_code                 -- �ڋq
       ,gr_order_h_rec.deliver_to_id                 -- �o�א�ID
       ,gr_order_h_rec.deliver_to                    -- �o�א�
       ,gr_order_h_rec.shipping_instructions         -- �o�׎w��
       ,gr_order_h_rec.career_id                     -- �^���Ǝ�ID
       ,gr_order_h_rec.freight_carrier_code          -- �^���Ǝ�
       ,gr_order_h_rec.shipping_method_code          -- �z���敪
       ,gr_order_h_rec.cust_po_number                -- �ڋq����
       ,gr_order_h_rec.price_list_id                 -- ���i�\
       ,gr_order_h_rec.request_no                    -- �˗�No
       ,gr_order_h_rec.req_status                    -- �X�e�[�^�X
       ,gr_order_h_rec.delivery_no                   -- �z��no
       ,gr_order_h_rec.schedule_ship_date            -- �o�ח\���
       ,gr_order_h_rec.schedule_arrival_date         -- ���ח\���
       ,gr_order_h_rec.mixed_no                      -- ���ڌ�No
       ,gr_order_h_rec.collected_pallet_qty          -- �p���b�g�������
       ,gr_order_h_rec.confirm_request_class         -- �����S���m�F�˗��敪
       ,gr_order_h_rec.freight_charge_class          -- �^���敪
       ,gr_order_h_rec.shikyu_instruction_class      -- �x���o�Ɏw���敪
       ,gr_order_h_rec.shikyu_inst_rcv_class         -- �x���w����̋敪
       ,gr_order_h_rec.deliver_from_id               -- �o�׌�ID
       ,gr_order_h_rec.deliver_from                  -- �o�׌��ۊǏꏊ
       ,gr_order_h_rec.head_sales_branch             -- �Ǌ����_
       ,gr_order_h_rec.po_no                         -- ����No
       ,gr_order_h_rec.prod_class                    -- ���i�敪
       ,gr_order_h_rec.no_cont_freight_class         -- �_��O�^���敪
       ,gr_order_h_rec.arrival_time_from             -- ���׎���from
       ,gr_order_h_rec.arrival_time_to               -- ���׎���to
       ,gr_order_h_rec.designated_item_id            -- �����i��ID
       ,gr_order_h_rec.designated_item_code          -- �����i��
       ,gr_order_h_rec.designated_production_date    -- ������
       ,gr_order_h_rec.designated_branch_no          -- �����}��
       ,gr_order_h_rec.slip_number                   -- �����No
       ,gr_order_h_rec.sum_quantity                  -- ���v����
       ,gr_order_h_rec.small_quantity                -- ������
       ,gr_order_h_rec.label_quantity                -- ���x������
       ,gr_order_h_rec.loading_efficiency_weight     -- �d�ʐύڌ���
       ,gr_order_h_rec.loading_efficiency_capacity   -- �e�ϐύڌ���
       ,gr_order_h_rec.based_weight                  -- ��{�d��
       ,gr_order_h_rec.based_capacity                -- ��{�e��
       ,gr_order_h_rec.mixed_ratio                   -- ���ڗ�
       ,gr_order_h_rec.pallet_sum_quantity           -- �p���b�g���v����
       ,gr_order_h_rec.real_pallet_quantity          -- �p���b�g���і���
       ,gr_order_h_rec.result_freight_carrier_id     -- �^���Ǝ�_����ID
       ,gr_order_h_rec.result_freight_carrier_code   -- �^���Ǝ�_����
       ,gr_order_h_rec.result_shipping_method_code   -- �z���敪_����
       ,gr_order_h_rec.result_deliver_to_id          -- �o�א�_����ID
       ,gr_order_h_rec.result_deliver_to             -- �o�א�_����
       ,gr_order_h_rec.shipped_date                  -- �o�ד�
       ,gr_order_h_rec.arrival_date                  -- ���ד�
       ,gr_order_h_rec.weight_capacity_class         -- �d�ʗe�ϋ敪
       ,gr_order_h_rec.notif_status                  -- �ʒm�X�e�[�^�X
       ,gv_yesno_n                                   -- �V�K�C���t���O
       ,gr_order_h_rec.performance_management_dept   -- ���ъǗ�����
       ,gr_order_h_rec.instruction_dept              -- �w������
       ,gr_order_h_rec.transfer_location_id          -- �U�֐�ID
       ,gr_order_h_rec.transfer_location_code        -- �U�֐�
       ,gr_order_h_rec.mixed_sign                    -- ���ڋL��
       ,gr_order_h_rec.screen_update_date            -- ��ʍX�V����
       ,gr_order_h_rec.screen_update_by              -- ��ʍX�V��
       ,gr_order_h_rec.tightening_date               -- �o�׈˗����ߓ���
       ,gr_order_h_rec.vendor_id                     -- �����ID
       ,gr_order_h_rec.vendor_code                   -- �����
       ,gr_order_h_rec.vendor_site_id                -- �����T�C�gID
       ,gr_order_h_rec.vendor_site_code              -- �����T�C�g
       ,gv_yesno_n                                   -- ���ߌ�C���敪
       ,gt_user_id                                   -- �쐬��
       ,gt_sysdate                                   -- �쐬��
       ,gt_user_id                                   -- �ŏI�X�V��
       ,gt_sysdate                                   -- �ŏI�X�V��
       ,gt_login_id                                  -- �ŏI�X�V���O�C��
       ,gt_conc_request_id                           -- �v��ID
       ,gt_prog_appl_id                              -- �A�v���P�[�V����ID
       ,gt_conc_program_id                           -- �R���J�����g�E�v���O����ID
       ,gt_sysdate                                   -- �v���O�����X�V��
      );
--
--********** 2008/07/07 ********** DELETE START ***
--* -- �󒍃w�b�_�X�V�쐬����(���ђ���)���Z
--* gn_ord_h_upd_y_cnt := gn_ord_h_upd_y_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN no_record_expt THEN                           --*** �Ώۃf�[�^�Ȃ� ***
      ov_errmsg  := lv_errmsg;                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_headers_inup;
--
--
 /**********************************************************************************
  * F Name   : order_lines_upd
  * Description      : �󒍖��׃A�h�I��UPDATE �v���V�[�W��(A-8-5)
  ***********************************************************************************/
  PROCEDURE order_lines_upd(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    in_order_line_id        IN  NUMBER,              -- �󒍖��׃A�h�I��ID
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_lines_upd'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    lt_order_header_id         xxwsh_order_headers_all.order_header_id%TYPE;
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_order_l_rec     := gr_order_l_ini;
--
    -- �o�׎��ѐ��ʂ̐ݒ���s���B
    -- ���b�g�Ǘ��敪 = 0:���b�g�Ǘ��i�ΏۊO
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
--
      -- �o�׈˗�IF����.�o�׎��ѐ��ʂ�ݒ�
      gr_order_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity;
--
      -- **************************************************
      -- *** �󒍖���(�A�h�I��)�X�V���s��
      -- **************************************************
      UPDATE
        xxwsh_order_lines_all    xola    -- �󒍖���(�A�h�I��)
      SET
         xola.shipped_quantity        = gr_order_l_rec.shipped_quantity   -- �o�Ɏ��ѐ���
        ,xola.last_updated_by         = gt_user_id                        -- �ŏI�X�V��
        ,xola.last_update_date        = gt_sysdate                        -- �ŏI�X�V��
        ,xola.last_update_login       = gt_login_id                       -- �ŏI�X�V���O�C��
        ,xola.request_id              = gt_conc_request_id                -- �v��ID
        ,xola.program_application_id  = gt_prog_appl_id                   -- �A�v���P�[�V����ID
        ,xola.program_id              = gt_conc_program_id                -- �v���O����ID
        ,xola.program_update_date     = gt_sysdate                        -- �v���O�����X�V��
      WHERE xola.order_line_id = in_order_line_id                  -- �󒍖��׃A�h�I��ID
      AND   ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))
      ;
--
    END IF;
--
--********** 2008/07/07 ********** MODIFY START ***
--* --�󒍖��׍X�V�쐬����(���ьv��i�ڂ���)���Z
--* gn_ord_l_upd_n_cnt := gn_ord_l_upd_n_cnt + 1;
--
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)
    THEN
      -- �x���̏ꍇ
      gn_ord_new_shikyu_cnt := gn_ord_new_shikyu_cnt + 1;
--
    ELSE
      -- �o�ׂ̏ꍇ
      gn_ord_new_syukka_cnt := gn_ord_new_syukka_cnt + 1;
--
    END IF;
--********** 2008/07/07 ********** MODIFY END   ***
--
    -- �󒍖���ID��ݒ�
    gr_order_l_rec.order_line_id := in_order_line_id;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_lines_upd;
--
 /**********************************************************************************
  * Procedure Name   : order_lines_ins
  * Description      : �󒍖��׃A�h�I��INSERT �v���V�[�W��(A-8-6)
  ***********************************************************************************/
  PROCEDURE order_lines_ins(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    iv_cnt_kbn              IN  VARCHAR2,            -- �f�[�^�����J�E���g�敪
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_lines_ins'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --�󒍖��׃A�h�I��ID
    lt_order_line_id_s1         xxwsh_order_lines_all.order_line_id%TYPE;
    -- *** ���[�J���ϐ� ***
    ln_order_line_seq           NUMBER;  --��L.����IDseq
    ln_line_number              NUMBER;  --���הԍ�
    ln_sum_actual_quantity      xxinv_mov_lot_details.actual_quantity%TYPE;
--
    ln_order_header_id          xxwsh_order_headers_all.order_header_id%TYPE;        --�����O�̎󒍃w�b�_�A�h�I��ID
    ln_based_request_quantity   xxwsh_order_lines_all.based_request_quantity%TYPE;   --���_�˗�����
    ln_reserved_quantity        xxwsh_order_lines_all.reserved_quantity%TYPE;        --������
    lv_automanual_reserve_class xxwsh_order_lines_all.automanual_reserve_class%TYPE; --�����蓮�����敪
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_order_l_rec     := gr_order_l_ini;
--
    -- �󒍖��ׂ̖���ID�擾
    SELECT xxwsh_order_lines_all_s1.NEXTVAL
    INTO   lt_order_line_id_s1
    FROM   dual;
--
    -- �󒍖��׃A�h�I��ID
     gr_order_l_rec.order_line_id   := lt_order_line_id_s1;
--
    -- �󒍃w�b�_�A�h�I��ID
    gr_order_l_rec.order_header_id  := gr_order_h_rec.order_header_id;
    -- ���הԍ�
    -- ����w�b�_��MAX(���הԍ�) + 1���擾
    SELECT NVL( MAX(order_line_number), 0 ) + 1
    INTO   ln_line_number
    FROM   xxwsh_order_lines_all xora
    WHERE  xora.order_header_id   = gr_order_h_rec.order_header_id   --�󒍃w�b�_ID
            ;
--
    gr_order_l_rec.order_line_number := ln_line_number; -- ����w�b�_��MAX(���הԍ�) + 1
    -- �˗�No  (IF_H.�˗�No)
    gr_order_l_rec.request_no        := gr_order_h_rec.request_no;
    -- �o�וi��ID  (OPM�i�ڃ}�X�^.OPM�i��ID)
    gr_order_l_rec.shipping_inventory_item_id := gr_interface_info_rec(in_idx).inventory_item_id;
    -- �o�וi��  (IF_L.�󒍕i��)
    gr_order_l_rec.shipping_item_code := gr_interface_info_rec(in_idx).orderd_item_code;
    -- �P��  (OPM�i�ڃ}�X�^.OPM�i��ID)
    gr_order_l_rec.uom_code           := gr_interface_info_rec(in_idx).item_um;
--
    --�˗��i��ID�E�˗��i�ڂ̐ݒ���s���B
    --(EOS�f�[�^��� = 210 ���_�o�׊m��� ���� EOS�f�[�^��� = 215 ���o�׊m��񍐂̏ꍇ
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
      --�i�ڋ敪�Őݒ�l��؂�ւ���
      IF  (gr_interface_info_rec(in_idx).item_kbn_cd <> gv_item_kbn_cd_5) THEN
--
        -- �˗��i��ID
        gr_order_l_rec.request_item_id   := gr_interface_info_rec(in_idx).whse_inventory_item_id;--OPM�i�ڃ}�X�^.�q�ɕi��ID
        -- �˗��i��
        gr_order_l_rec.request_item_code := gr_interface_info_rec(in_idx).whse_inventory_item_no;--OPM�i�ڃ}�X�^.�i��(�q�ɕi��)
--
      ELSE
--
        -- �˗��i��ID
        gr_order_l_rec.request_item_id   := gr_interface_info_rec(in_idx).inventory_item_id;--INV�i�ڃ}�X�^.�i��ID
        -- �˗��i��
        gr_order_l_rec.request_item_code := gr_interface_info_rec(in_idx).orderd_item_code; --IF_L.�󒍕i��
--
      END IF;
--
    END IF;
--
    --(EOS�f�[�^��� = 200 �L���o�ו񍐂̏ꍇ)
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      -- �˗��i��ID
      gr_order_l_rec.request_item_id   := gr_interface_info_rec(in_idx).whse_inventory_item_id; --OPM�q�ɕi��ID
      -- �˗��i��
      gr_order_l_rec.request_item_code := gr_interface_info_rec(in_idx).whse_inventory_item_no; --OPM�i�ڃ}�X�^.�i��(�q�ɕi��)
--
    END IF;
--
    -- �o�׎��ѐ��ʂ̐ݒ���s���B
    -- ���b�g�Ǘ��敪 = 0:���b�g�Ǘ��i�ΏۊO
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
--
      -- �o�׈˗�IF����.�o�׎��ѐ��ʂ�ݒ�
      gr_order_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity;
    END IF;
--
    -- �����N���A�@NULL�Z�b�g
    gr_order_l_rec.based_request_quantity   := 0;        --���_�˗�����
    gr_order_l_rec.reserved_quantity        := 0;        --������
    gr_order_l_rec.automanual_reserve_class := NULL;     --�����蓮�����敪
--
    -- �����i���i�ځj�̏ꍇ�A�h�e�ɂȂ����ڂ̒l������O���R�[�h���󂯌p��
    IF (iv_cnt_kbn = gv_cnt_kbn_4) THEN
--
      BEGIN
        -- ���ьv��ς݂�MAX�w�b�_ID�擾
        SELECT    MAX(xoha.order_header_id) order_header_id
        INTO      ln_order_header_id       -- �w�b�_ID
        FROM      xxwsh_order_headers_all   xoha    -- �󒍃w�b�_(�A�h�I��)
        WHERE     NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null)
        AND       xoha.request_no = gr_interface_info_rec(in_idx).order_source_ref
        AND       actual_confirm_class = gv_yesno_y
        GROUP BY  xoha.delivery_no                 --�z��No
                 ,xoha.order_source_ref            --�󒍃\�[�X�Q��
        ;
--
        -- �����O�̖��׏����擾
        SELECT   xola.based_request_quantity
                ,xola.reserved_quantity
                ,xola.automanual_reserve_class
        INTO     ln_based_request_quantity                      -- ���_�˗�����
                ,ln_reserved_quantity                           -- ������
                ,lv_automanual_reserve_class                    -- �����蓮�����敪
        FROM    xxwsh_order_lines_all     xola                  -- �󒍖���(�A�h�I��)
        WHERE   xola.order_header_id = ln_order_header_id       -- �󒍃w�b�_�A�h�I��ID
        AND     xola.shipping_item_code = gr_interface_info_rec(in_idx).orderd_item_code -- �o�וi��
        AND     ((xola.delete_flag = gv_yesno_n) OR (xola.delete_flag IS NULL))
        ;
--
        -- �擾�����l���Z�b�g
        gr_order_l_rec.based_request_quantity   := ln_based_request_quantity;   --���_�˗�����
        gr_order_l_rec.reserved_quantity        := ln_reserved_quantity;        --������
        gr_order_l_rec.automanual_reserve_class := lv_automanual_reserve_class; --�����蓮�����敪
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
          gr_order_l_rec.based_request_quantity   := 0;        --���_�˗�����
          gr_order_l_rec.reserved_quantity        := 0;        --������
          gr_order_l_rec.automanual_reserve_class := NULL;     --�����蓮�����敪
--
      END;
--
    END IF;
--
    -- **************************************************
    -- *** �󒍖���(�A�h�I��)�o�^���s��
    -- **************************************************
    INSERT INTO xxwsh_order_lines_all
      (order_line_id                               -- �󒍖��׃A�h�I��ID
      ,order_header_id                             -- �󒍃w�b�_�A�h�I��ID
      ,order_line_number                           -- ���הԍ�
      ,request_no                                  -- �˗�No
      ,shipping_inventory_item_id                  -- �o�וi��ID
      ,shipping_item_code                          -- �o�וi��
      ,uom_code                                    -- �P��
      ,request_item_id                             -- �˗��i��ID
      ,request_item_code                           -- �˗��i��
      ,shipped_quantity                            -- �o�Ɏ��ѐ���
      ,based_request_quantity                      -- ���_�˗�����
      ,reserved_quantity                           -- ������
      ,automanual_reserve_class                    -- �����蓮�����敪
      ,delete_flag                                 -- �폜�t���O
      ,rm_if_flg                                   -- �q�֕ԕi�C���^�t�F�[�X�σt���O
      ,shipping_request_if_flg                     -- �o�׈˗��C���^�t�F�[�X�σt���O
      ,shipping_result_if_flg                      -- �o�׎��уC���^�t�F�[�X�σt���O
      ,created_by                                  -- �쐬��
      ,creation_date                               -- �쐬��
      ,last_updated_by                             -- �ŏI�X�V��
      ,last_update_date                            -- �ŏI�X�V��
      ,last_update_login                           -- �ŏI�X�V���O�C��
      ,request_id                                  -- �v��ID
      ,program_application_id                      -- �A�v���P�[�V����ID
      ,program_id                                  -- �R���J�����g�E�v���O����ID
      ,program_update_date                         -- �v���O�����X�V��
      )
    VALUES
      (gr_order_l_rec.order_line_id                --�󒍖��׃A�h�I��ID
      ,gr_order_l_rec.order_header_id              --�󒍃w�b�_�A�h�I��ID
      ,gr_order_l_rec.order_line_number            --���הԍ�
      ,gr_order_l_rec.request_no                   --�˗�no
      ,gr_order_l_rec.shipping_inventory_item_id   --�o�וi��ID
      ,gr_order_l_rec.shipping_item_code           --�o�וi��
      ,gr_order_l_rec.uom_code                     --�P��
      ,gr_order_l_rec.request_item_id              --�˗��i��ID
      ,gr_order_l_rec.request_item_code            --�˗��i��
      ,gr_order_l_rec.shipped_quantity             --�o�Ɏ��ѐ���
      ,gr_order_l_rec.based_request_quantity       --���_�˗�����
      ,gr_order_l_rec.reserved_quantity            --������
      ,gr_order_l_rec.automanual_reserve_class     --�����蓮�����敪
      ,gv_yesno_n                                  --�폜�t���O
      ,gv_yesno_n                                  --�q�֕ԕi�C���^�t�F�[�X�σt���O
      ,gv_yesno_n                                  --�o�׈˗��C���^�t�F�[�X�σt���O
      ,gv_yesno_n                                  --�o�׎��уC���^�t�F�[�X�σt���O
      ,gt_user_id                                  --�쐬��
      ,gt_sysdate                                  --�쐬��
      ,gt_user_id                                  --�ŏI�X�V��
      ,gt_sysdate                                  --�ŏI�X�V��
      ,gt_login_id                                 --�ŏI�X�V���O�C��
      ,gt_conc_request_id                          --�v��ID
      ,gt_prog_appl_id                             --�A�v���P�[�V����ID
      ,gt_conc_program_id                          --�R���J�����g�E�v���O����ID
      ,gt_sysdate                                  --�v���O�����X�V��
     );
--
    --�������Z
--********** 2008/07/07 ********** MODIFY START ***
--* IF (iv_cnt_kbn = gv_cnt_kbn_2) -- �w���i�ځ����ѕi�ڂɉ��Z
--* THEN
--*
--*   gn_ord_l_ins_n_cnt := gn_ord_l_ins_n_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_3) -- �O���q��(�w���Ȃ�)�ɉ��Z
--*  THEN
--*
--*       gn_ord_l_ins_cnt := gn_ord_l_ins_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_4) -- ���яC���ɉ��Z
--*  THEN
--*
--*   gn_ord_l_ins_y_cnt := gn_ord_l_ins_y_cnt + 1;
--*
--* END IF;
--*
--
    IF ((iv_cnt_kbn = gv_cnt_kbn_2) OR
        (iv_cnt_kbn = gv_cnt_kbn_3))
    THEN
      -- �w������i���ьv��j�^�w���Ȃ��i�O���q�Ɂj�̏ꍇ
--
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)
      THEN
        -- �x���̏ꍇ
        gn_ord_new_shikyu_cnt := gn_ord_new_shikyu_cnt + 1;
--
      ELSE
        -- �o�ׂ̏ꍇ
        gn_ord_new_syukka_cnt := gn_ord_new_syukka_cnt + 1;
--
      END IF;
--
    ELSIF (iv_cnt_kbn = gv_cnt_kbn_4) THEN
      -- �����̏ꍇ
--
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)
      THEN
        -- �x���̏ꍇ
        gn_ord_correct_shikyu_cnt := gn_ord_correct_shikyu_cnt + 1;
--
      ELSE
        -- �o�ׂ̏ꍇ
        gn_ord_correct_syukka_cnt := gn_ord_correct_syukka_cnt + 1;
--
      END IF;
--
    END IF;
--
--********** 2008/07/07 ********** MODIFY END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN no_insert_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                             --# �C�� #
--
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                             --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_lines_ins;
--
 /**********************************************************************************
  * Procedure Name   : order_movlot_detail_ins
  * Description      : �󒍃f�[�^�ړ����b�g�ڍ�INSERT �v���V�[�W��(A-8-7)
  ***********************************************************************************/
  PROCEDURE order_movlot_detail_ins(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    iv_cnt_kbn              IN  VARCHAR2,            -- �f�[�^�����J�E���g�敪
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_movlot_detail_ins'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_mov_lot_seq       NUMBER;  --�ړ����b�g�ڍ�(�A�h�I��).���b�g�ڍ�IDseq
    ln_order_header_id        xxwsh_order_headers_all.order_header_id%TYPE;  -- �����O�̎󒍃w�b�_�A�h�I��ID
    lr_movlot_detail_ins      movlot_detail_rec;
    lr_movlot_detail_ins_ini  movlot_detail_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����̏ꍇ�A�����O�̏�񂩂�V�K�w�����R�[�h���쐬����B
    IF (iv_cnt_kbn = gv_cnt_kbn_4) THEN
--
      -- ������
      lr_movlot_detail_ins := lr_movlot_detail_ins_ini;
--
      BEGIN 
--
        -- ���ьv��ς݂�MAX�w�b�_ID�擾
        SELECT    MAX(xoha.order_header_id) order_header_id
        INTO      ln_order_header_id       -- �w�b�_ID
        FROM      xxwsh_order_headers_all   xoha    -- �󒍃w�b�_(�A�h�I��)
        WHERE     NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null)
        AND       xoha.request_no = gr_interface_info_rec(in_idx).order_source_ref
        AND       actual_confirm_class = gv_yesno_y
        GROUP BY  xoha.delivery_no                 --�z��No
                 ,xoha.order_source_ref            --�󒍃\�[�X�Q��
        ;
--
        -- �����O�̈ړ����b�g���i�w���j���擾����B
        SELECT  xmld.mov_lot_dtl_id               -- ���b�g�ڍ�ID
              , xmld.mov_line_id                  -- ����ID
              , xmld.document_type_code           -- �����^�C�v
              , xmld.record_type_code             -- ���R�[�h�^�C�v
              , xmld.item_id                      -- opm�i��ID
              , xmld.item_code                    -- �i��
              , xmld.lot_id                       -- ���b�gID
              , xmld.lot_no                       -- ���b�gNO
              , xmld.actual_date                  -- ���ѓ�
              , xmld.actual_quantity              -- ���ѐ���
              , xmld.automanual_reserve_class     -- �����蓮�����敪
        INTO  lr_movlot_detail_ins
        FROM    xxwsh_order_headers_all   xoha    -- �󒍃w�b�_(�A�h�I��)
              , xxwsh_order_lines_all     xola    -- �󒍖���(�A�h�I��)
              , xxinv_mov_lot_details     xmld    -- �ړ����b�g�ڍ�(�A�h�I��)
        WHERE   xoha.order_header_id      = ln_order_header_id
        AND     xoha.order_header_id      = xola.order_header_id
        AND     ((xola.delete_flag        = gv_yesno_n) OR (xola.delete_flag IS NULL))
        AND     xola.order_line_id        = xmld.mov_line_id
        AND     xmld.document_type_code  IN (gv_document_type_10,gv_document_type_30)
        AND     xmld.record_type_code     = gv_record_type_10
        AND     xmld.item_id              = gr_interface_info_rec(in_idx).item_id
        AND     NVL(xmld.lot_no,'X')      = NVL(gr_interface_info_rec(in_idx).lot_no,'X')
        ;
--
      EXCEPTION
--
        WHEN NO_DATA_FOUND THEN
        lr_movlot_detail_ins.mov_lot_dtl_id := NULL;
--
      END;
--
      -- �����O�̈ړ����b�g�ڍׂ��������ꍇ
      IF (lr_movlot_detail_ins.mov_lot_dtl_id IS NOT NULL) THEN
--
        -- ���b�g�ڍ�ID�擾
        SELECT xxinv_mov_lot_s1.nextval
        INTO   ln_mov_lot_seq
        FROM   dual
        ;
--
        lr_movlot_detail_ins.mov_lot_dtl_id     := ln_mov_lot_seq;
--
        lr_movlot_detail_ins.mov_line_id        := gr_order_l_rec.order_line_id;
--
      -- ������̈ړ����b�g���i�w���j���쐬����B
      -- **************************************************
      -- *** �ړ����b�g�ڍ�(�A�h�I��)�o�^���s��
      -- **************************************************
        INSERT INTO xxinv_mov_lot_details                   -- �ړ����b�g�ڍ�(�A�h�I��)
        (  mov_lot_dtl_id                                   -- ���b�g�ڍ�ID
          ,mov_line_id                                      -- ����ID
          ,document_type_code                               -- �����^�C�v
          ,record_type_code                                 -- ���R�[�h�^�C�v
          ,item_id                                          -- opm�i��ID
          ,item_code                                        -- �i��
          ,lot_id                                           -- ���b�gID
          ,lot_no                                           -- ���b�gNO
          ,actual_date                                      -- ���ѓ�
          ,actual_quantity                                  -- ���ѐ���
          ,created_by                                       -- �쐬��
          ,creation_date                                    -- �쐬��
          ,last_updated_by                                  -- �ŏI�X�V��
          ,last_update_date                                 -- �ŏI�X�V��
          ,last_update_login                                -- �ŏI�X�V���O�C��
          ,request_id                                       -- �v��ID
          ,program_application_id                           -- �A�v���P�[�V����ID
          ,program_id                                       -- �R���J�����g�E�v���O����ID
          ,program_update_date                              -- �v���O�����X�V��
        )
        VALUES
        (  lr_movlot_detail_ins.mov_lot_dtl_id              -- ���b�g�ڍ�ID
          ,lr_movlot_detail_ins.mov_line_id                 -- ����ID
          ,lr_movlot_detail_ins.document_type_code          -- �����^�C�v
          ,lr_movlot_detail_ins.record_type_code            -- ���R�[�h�^�C�v
          ,lr_movlot_detail_ins.item_id                     -- opm�i��id
          ,lr_movlot_detail_ins.item_code                   -- �i��
          ,lr_movlot_detail_ins.lot_id                      -- ���b�gID
          ,lr_movlot_detail_ins.lot_no                      -- ���b�gno
          ,lr_movlot_detail_ins.actual_date                 -- ���ѓ�
          ,lr_movlot_detail_ins.actual_quantity             -- ���ѐ���
          ,gt_user_id                                       -- �쐬��
          ,gt_sysdate                                       -- �쐬��
          ,gt_user_id                                       -- �ŏI�X�V��
          ,gt_sysdate                                       -- �ŏI�X�V��
          ,gt_login_id                                      -- �ŏI�X�V���O�C��
          ,gt_conc_request_id                               -- �v��ID
          ,gt_prog_appl_id                                  -- �A�v���P�[�V����ID
          ,gt_conc_program_id                               -- �R���J�����g�E�v���O����ID
          ,gt_sysdate                                       -- �v���O�����X�V��
        );
--
      END IF;
--
    END IF; 
--
    --  ������
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    --
    -- �V�K�ړ����b�g�ڍ׍쐬
    --
--
    -- ���b�g�ڍ�ID
    SELECT xxinv_mov_lot_s1.nextval
    INTO   ln_mov_lot_seq
    FROM   dual
    ;
--
    gr_movlot_detail_rec.mov_lot_dtl_id     := ln_mov_lot_seq;
--
    -- �ړ�����ID��ݒ�
    gr_movlot_detail_rec.mov_line_id        := gr_order_l_rec.order_line_id;
--
    --�����^�C�v��ݒ�
    -- EOS�f�[�^��� = ���_�o�׊m��� ���� ���o�׊m��񍐂̏ꍇ
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      gr_movlot_detail_rec.document_type_code := gv_document_type_10; --�o�׈˗�
--
    --  EOS�f�[�^��� = 200 �L���o�ו�
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      gr_movlot_detail_rec.document_type_code := gv_document_type_30; --�x���w��
--
    END IF;
--
    --���R�[�h�^�C�v��ݒ�
    -- EOS�f�[�^��� = �L���o�ו� ���� EOS�f�[�^��� = ���_�o�׊m��� ���͒��o�׊m��񍐂̏ꍇ
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      gr_movlot_detail_rec.record_type_code := gv_record_type_20;   -- �o�Ɏ���
--
    END IF;
--
    -- OPM�i��ID��ݒ�
    gr_movlot_detail_rec.item_id      := gr_interface_info_rec(in_idx).item_id;  -- �i��ID
    -- �i�ڂ�ݒ�
    gr_movlot_detail_rec.item_code    := gr_interface_info_rec(in_idx).orderd_item_code; -- �󒍕i��
    -- ���b�gID��ݒ�
    gr_movlot_detail_rec.lot_id       := gr_interface_info_rec(in_idx).lot_id;     -- ���b�gID
    -- ���b�gNo��ݒ�
    gr_movlot_detail_rec.lot_no       := gr_interface_info_rec(in_idx).lot_no;     -- ���b�gNo
    -- ���ѓ���ݒ�
    gr_movlot_detail_rec.actual_date  := gr_interface_info_rec(in_idx).shipped_date; -- �o�ד�
--
    -- ���ѐ��ʂ̐ݒ���s��
    -- EOS�f�[�^��� = ���_�o�׊m��� ���� ���o�׊m��񍐂̏ꍇ
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      --���󐔗ʂ�ݒ�
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ���b�g����0�̑Ή�
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.�o�׎��ѐ��� ��ݒ�
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    --  EOS�f�[�^��� = 200 �L���o�ו�
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      --���󐔗ʂ�ݒ�
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ���b�g����0�̑Ή�
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.�o�׎��ѐ��� ��ݒ�
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** �ړ����b�g�ڍ�(�A�h�I��)�o�^���s��
    -- **************************************************
      INSERT INTO xxinv_mov_lot_details                   -- �ړ����b�g�ڍ�(�A�h�I��)
        (mov_lot_dtl_id                                   -- ���b�g�ڍ�ID
        ,mov_line_id                                      -- ����ID
        ,document_type_code                               -- �����^�C�v
        ,record_type_code                                 -- ���R�[�h�^�C�v
        ,item_id                                          -- opm�i��ID
        ,item_code                                        -- �i��
        ,lot_id                                           -- ���b�gID
        ,lot_no                                           -- ���b�gNO
        ,actual_date                                      -- ���ѓ�
        ,actual_quantity                                  -- ���ѐ���
        ,created_by                                       -- �쐬��
        ,creation_date                                    -- �쐬��
        ,last_updated_by                                  -- �ŏI�X�V��
        ,last_update_date                                 -- �ŏI�X�V��
        ,last_update_login                                -- �ŏI�X�V���O�C��
        ,request_id                                       -- �v��ID
        ,program_application_id                           -- �A�v���P�[�V����ID
        ,program_id                                       -- �R���J�����g�E�v���O����ID
        ,program_update_date                              -- �v���O�����X�V��
        )
      VALUES
        (gr_movlot_detail_rec.mov_lot_dtl_id              -- ���b�g�ڍ�ID
        ,gr_movlot_detail_rec.mov_line_id                 -- ����ID
        ,gr_movlot_detail_rec.document_type_code          -- �����^�C�v
        ,gr_movlot_detail_rec.record_type_code            -- ���R�[�h�^�C�v
        ,gr_movlot_detail_rec.item_id                     -- opm�i��id
        ,gr_movlot_detail_rec.item_code                   -- �i��
        ,gr_movlot_detail_rec.lot_id                      -- ���b�gID
        ,gr_movlot_detail_rec.lot_no                      -- ���b�gno
        ,gr_movlot_detail_rec.actual_date                 -- ���ѓ�
        ,gr_movlot_detail_rec.actual_quantity             -- ���ѐ���
        ,gt_user_id                                       -- �쐬��
        ,gt_sysdate                                       -- �쐬��
        ,gt_user_id                                       -- �ŏI�X�V��
        ,gt_sysdate                                       -- �ŏI�X�V��
        ,gt_login_id                                      -- �ŏI�X�V���O�C��
        ,gt_conc_request_id                               -- �v��ID
        ,gt_prog_appl_id                                  -- �A�v���P�[�V����ID
        ,gt_conc_program_id                               -- �R���J�����g�E�v���O����ID
        ,gt_sysdate                                       -- �v���O�����X�V��
       );
--
--********** 2008/07/07 ********** DELETE START ***
--* --�������Z
--* IF (iv_cnt_kbn = gv_cnt_kbn_3) -- �O���q��(�w���Ȃ�)�ɉ��Z
--* THEN
--*
--*   gn_ord_mov_ins_cnt := gn_ord_mov_ins_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_4) -- ���яC���ɉ��Z
--*  THEN
--*
--*       gn_ord_mov_ins_y_cnt := gn_ord_mov_ins_y_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_5) -- ���ьv��ɉ��Z
--*  THEN
--*
--*   gn_ord_mov_ins_n_cnt := gn_ord_mov_ins_n_cnt + 1;
--*
--* END IF;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_movlot_detail_ins;
--
 /**********************************************************************************
  * Procedure Name   : order_movlot_detail_up
  * Description      : �󒍃f�[�^�ړ����b�g�ڍ�UPDATE �v���V�[�W�� (A-8-8)
  ***********************************************************************************/
  PROCEDURE order_movlot_detail_up(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    in_mov_lot_dtl_id       IN  NUMBER,              -- ���b�g�ڍ�ID
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_movlot_detail_up'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--  ������
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    -- ���ѓ���ݒ�
    gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).shipped_date; -- �o�ד�
--
    -- ���ѐ��ʂ̐ݒ���s��
    -- EOS�f�[�^��� = ���_�o�׊m��� ���� ���o�׊m��񍐂̏ꍇ
    IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
        (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
    THEN
--
      --���󐔗ʂ�ݒ�
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ���b�g����0�̑Ή�
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.�o�׎��ѐ��� ��ݒ�
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    --  EOS�f�[�^��� = 200 �L���o�ו�
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
      --���󐔗ʂ�ݒ�
      gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
      -- ���b�g����0�̑Ή�
      IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
         (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
         --IF_L.�o�׎��ѐ��� ��ݒ�
         gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** �ړ����b�g�ڍ�(�A�h�I��)�X�V���s��
    -- **************************************************
    UPDATE
      xxinv_mov_lot_details    xmld     -- �ړ����b�g�ڍ�(�A�h�I��)
    SET
       xmld.actual_date             = gr_movlot_detail_rec.actual_date        -- ���ѓ�
      ,xmld.actual_quantity         = gr_movlot_detail_rec.actual_quantity    -- ���ѐ���
      ,xmld.last_updated_by         = gt_user_id                              -- �ŏI�X�V��
      ,xmld.last_update_date        = gt_sysdate                              -- �ŏI�X�V��
      ,xmld.last_update_login       = gt_login_id                             -- �ŏI�X�V���O�C��
      ,xmld.request_id              = gt_conc_request_id                      -- �v��ID
      ,xmld.program_application_id  = gt_prog_appl_id                         -- �A�v���P�[�V����ID
      ,xmld.program_id              = gt_conc_program_id                      -- �v���O����ID
      ,xmld.program_update_date     = gt_sysdate                              -- �v���O�����X�V��
    WHERE
        xmld.mov_lot_dtl_id         = in_mov_lot_dtl_id      -- ���b�g�ڍ�ID
    ;
--
--********** 2008/07/07 ********** DELETE START ***
--* --���b�g�ڍאV�K�쐬����(��_���ьv��) ���Z
--* gn_ord_mov_ins_n_cnt := gn_ord_mov_ins_n_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_movlot_detail_up;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_head_ins
  * Description      : �ړ��˗�/�w���w�b�_�A�h�I��(�O���q�ɕҏW) �v���V�[�W��(A-7-1)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_head_ins(
    in_index                IN  NUMBER,                 -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_head_ins'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_time_def                   CONSTANT VARCHAR2(1) := ':';
--
    -- *** ���[�J���ϐ� ***
    --�ړ��w�b�_ID
    lt_mov_hdr_id                 xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
--
    -- �ő�p���b�g�����Z�o�֐��p�����[�^
    lv_code_class1                VARCHAR2(2);                -- 1.�R�[�h�敪�P
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.���o�ɏꏊ�R�[�h�P
    lv_code_class2                VARCHAR2(2);                -- 3.�R�[�h�敪�Q
    lv_entering_despatching_code2 VARCHAR2(4);                -- 4.���o�ɏꏊ�R�[�h�Q
    ld_standard_date              DATE;                       -- 5.���(�K�p�����)
    lv_ship_methods               VARCHAR2(2);                -- 6.�z���敪
    on_drink_deadweight           NUMBER;                     -- 7.�h�����N�ύڏd��
    on_leaf_deadweight            NUMBER;                     -- 8.���[�t�ύڏd��
    on_drink_loading_capacity     NUMBER;                     -- 9.�h�����N�ύڗe��
    on_leaf_loading_capacity      NUMBER;                     -- 10.���[�t�ύڗe��
    on_palette_max_qty            NUMBER;                     -- 11.�p���b�g�ő喇��
--
    -- ���׎���FROM,TO
    lv_arrival_time_from          VARCHAR2(4);
    lv_arrival_time_to            VARCHAR2(4);
    lv_arrival_from               VARCHAR2(5);
    lv_arrival_to                 VARCHAR2(5);
--
    ln_ret_code                   NUMBER;                     -- ���^�[���E�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--  ������
    gr_mov_req_instr_h_rec := gr_mov_req_instr_h_ini;
--
    -- �ړ��w�b�_ID�擾(�V�[�P���X)
    SELECT xxinv_mov_hdr_s1.NEXTVAL
    INTO lt_mov_hdr_id
    FROM dual;
    -- �ړ��˗�/�w���w�b�_�A�h�I���ҏW����
    -- �ړ��w�b�_ID
    gr_mov_req_instr_h_rec.mov_hdr_id       := lt_mov_hdr_id;
    -- �ړ��ԍ�
    gr_mov_req_instr_h_rec.mov_num          := gr_interface_info_rec(in_index).order_source_ref;
    -- �ړ��^�C�v
    gr_mov_req_instr_h_rec.mov_type         := gv_move_type_1;
    -- ���͓�
    gr_mov_req_instr_h_rec.entered_date     := gd_sysdate;
    -- �w������
    gr_mov_req_instr_h_rec.instruction_post_code
                                            := gr_interface_info_rec(in_index).report_post_code;
    -- �X�e�[�^�X
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      gr_mov_req_instr_h_rec.status         := gv_mov_status_04;  -- �o�ɕ񍐗L
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      gr_mov_req_instr_h_rec.status         := gv_mov_status_05;  -- ���ɕ񍐗L
    END IF;
    -- �ʒm�X�e�[�^�X
    gr_mov_req_instr_h_rec.notif_status     := gv_notif_status_40;
    -- �o�Ɍ�ID
    gr_mov_req_instr_h_rec.shipped_locat_id := gr_interface_info_rec(in_index).shipped_locat;
    -- �o�Ɍ��ۊǏꏊ
    gr_mov_req_instr_h_rec.shipped_locat_code
                                            := gr_interface_info_rec(in_index).location_code;
    -- ���ɐ�ID
    gr_mov_req_instr_h_rec.ship_to_locat_id := gr_interface_info_rec(in_index).ship_to_locat;
    -- ���ɐ�ۊǏꏊ
    gr_mov_req_instr_h_rec.ship_to_locat_code
                                            := gr_interface_info_rec(in_index).ship_to_location;
    -- �o�ɗ\���
    gr_mov_req_instr_h_rec.schedule_ship_date
                                            := gr_interface_info_rec(in_index).shipped_date;
    -- ���ɗ\���
    gr_mov_req_instr_h_rec.schedule_arrival_date
                                            := gr_interface_info_rec(in_index).arrival_date;
    -- �^���敪
    IF (NVL(gr_interface_info_rec(in_index).delivery_no,'0') <> '0') THEN
      gr_mov_req_instr_h_rec.freight_charge_class
                                            := gv_include_exclude_1;
    ELSE
      gr_mov_req_instr_h_rec.freight_charge_class
                                            := gv_include_exclude_0;
    END IF;
    -- �p���b�g�������
    gr_mov_req_instr_h_rec.collected_pallet_qty
                                            := gr_interface_info_rec(in_index).collected_pallet_qty;
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      -- �p���b�g����(�o)
      gr_mov_req_instr_h_rec.out_pallet_qty
                                            := gr_interface_info_rec(in_index).used_pallet_qty;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      -- �p���b�g����(��)
      gr_mov_req_instr_h_rec.in_pallet_qty  := gr_interface_info_rec(in_index).used_pallet_qty;
    END IF;
    -- �z��No
    gr_mov_req_instr_h_rec.delivery_no      := gr_interface_info_rec(in_index).delivery_no;
    -- �g�DID
    gr_mov_req_instr_h_rec.organization_id  := gv_master_org_id;
    -- �^���Ǝ�_ID
    gr_mov_req_instr_h_rec.career_id        := gr_interface_info_rec(in_index).career_id;
    -- �^���Ǝ�
    gr_mov_req_instr_h_rec.freight_carrier_code
                                            := gr_interface_info_rec(in_index).freight_carrier_code;
    -- �^���Ǝ�_ID_����
    gr_mov_req_instr_h_rec.actual_career_id := gr_interface_info_rec(in_index).result_freight_carrier_id;
    -- �^���Ǝ�_����
    gr_mov_req_instr_h_rec.actual_freight_carrier_code
                                            := gr_interface_info_rec(in_index).freight_carrier_code;
--
    lv_arrival_from := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 1, 2)
                    || lv_time_def
                    || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_from, 3, 2);
--
    lv_arrival_to := SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 1, 2)
                  || lv_time_def
                  || SUBSTRB(gr_interface_info_rec(in_index).arrival_time_to, 3, 2);
--
    BEGIN
--
      SELECT  xlvv1.lookup_code arrival_time_from
             ,xlvv2.lookup_code arrival_time_to
      INTO    lv_arrival_time_from
             ,lv_arrival_time_to
      FROM    xxcmn_lookup_values_v  xlvv1
             ,xxcmn_lookup_values_v  xlvv2
      WHERE   xlvv1.lookup_type = gv_arrival_time_type
      AND     xlvv2.lookup_type = gv_arrival_time_type
      AND     xlvv1.meaning = lv_arrival_from
      AND     xlvv2.meaning = lv_arrival_to
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_arrival_time_from := '0000';
        lv_arrival_time_to := '0000';
    END;
--
    -- ���׎���from
    gr_mov_req_instr_h_rec.arrival_time_from
                                            := lv_arrival_time_from;
    -- ���׎���to
    gr_mov_req_instr_h_rec.arrival_time_to  := lv_arrival_time_to;
--
    --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
      -- ��{�d��
--
      -- �p�����[�^���擾
      -- 1.�R�[�h�敪�P
      lv_code_class1                := gv_code_class_04;
      -- 2.���o�ɏꏊ�R�[�h�P
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.�R�[�h�敪�Q
      lv_code_class2                := gv_code_class_04;
      -- 4.���o�ɏꏊ�R�[�h�Q
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).ship_to_location;
      -- 5.���(�K�p�����)
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        ld_standard_date := gr_interface_info_rec(in_index).arrival_date;
      END IF;
      -- 6.�z���敪
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- �z���敪��NULL�̏ꍇ�A�ő�z���敪���擾���čő�p���b�g�������擾����B
      IF (lv_ship_methods IS NULL) THEN
--
        -- �ő�z���敪�Z�o�֐�
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:�R�[�h�敪1
                                  ,lv_entering_despatching_code1                         -- IN:���o�ɏꏊ�R�[�h1
                                  ,lv_code_class2                                        -- IN:�R�[�h�敪2
                                  ,lv_entering_despatching_code2                         -- IN:���o�ɏꏊ�R�[�h2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:���i�敪
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:�d�ʗe�ϋ敪
                                  ,NULL                                                  -- IN:�����z�ԑΏۋ敪
                                  ,ld_standard_date                                      -- IN:���
                                  ,lv_ship_methods                -- OUT:�ő�z���敪
                                  ,on_drink_deadweight            -- OUT:�h�����N�ύڏd��
                                  ,on_leaf_deadweight             -- OUT:���[�t�ύڏd��
                                  ,on_drink_loading_capacity      -- OUT:�h�����N�ύڗe��
                                  ,on_leaf_loading_capacity       -- OUT:���[�t�ύڗe��
                                  ,on_palette_max_qty);           -- OUT:�p���b�g�ő喇��
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- �ő�z���敪�Z�o�֐��G���[
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --�󒍃\�[�X�Q��
                        ,gv_table_token                                        -- �g�[�N���FTABLE_NAME
                        ,gv_table_token02_nm                                   -- �e�[�u�����F�ړ��˗�/�w���w�b�_(�A�h�I��)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- �p�����[�^�F�R�[�h�敪�P
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                        ,gv_param5_token
                        ,lv_code_class2                                        -- �p�����[�^�F�R�[�h�敪�Q
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- �p�����[�^�F���i�敪
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- �p�����[�^�F�d�ʗe�ϋ敪
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- �p�����[�^�F���
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- �ő�z���敪�Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- �ő�p���b�g�����擾
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.�R�[�h�敪�P
                                lv_entering_despatching_code1,  -- 2.���o�ɏꏊ�R�[�h�P
                                lv_code_class2,                 -- 3.�R�[�h�敪�Q
                                lv_entering_despatching_code2,  -- 4.���o�ɏꏊ�R�[�h�Q
                                ld_standard_date,               -- 5.���(�K�p�����)
                                lv_ship_methods,                -- 6.�z���敪
                                on_drink_deadweight,            -- 7.�h�����N�ύڏd��
                                on_leaf_deadweight,             -- 8.���[�t�ύڏd��
                                on_drink_loading_capacity,      -- 9.�h�����N�ύڗe��
                                on_leaf_loading_capacity,       -- 10.���[�t�ύڗe��
                                on_palette_max_qty);            -- 11.�p���b�g�ő喇��
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- �ő�p���b�g�����Z�o�֐��G���[
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --�z��No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --�󒍃\�[�X�Q��
                      ,gv_table_token                   -- �g�[�N���FTABLE_NAME
                      ,gv_table_token02_nm              -- �e�[�u�����F�ړ��˗�/�w���w�b�_(�A�h�I��)
                      ,gv_param1_token
                      ,lv_code_class1                   -- �p�����[�^�F�R�[�h�敪�P
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                      ,gv_param3_token
                      ,lv_code_class2                   -- �p�����[�^�F�R�[�h�敪�Q
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                 -- �p�����[�^�F���
                      ,gv_param6_token
                      ,lv_ship_methods                  -- �p�����[�^�F�z���敪
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;   -- �ő�p���b�g�����Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_leaf_deadweight;
      END IF;
      -- ��{�e��
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_leaf_loading_capacity;
      END IF;
--
      -- �z���敪
      gr_mov_req_instr_h_rec.shipping_method_code
                                            := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- �z���敪_����
      gr_mov_req_instr_h_rec.actual_shipping_method_code
                                            := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    -- �d�ʗe�ϋ敪
    gr_mov_req_instr_h_rec.weight_capacity_class
                                            := gr_interface_info_rec(in_index).weight_capacity_class;
    -- �o�Ɏ��ѓ�
    gr_mov_req_instr_h_rec.actual_ship_date := gr_interface_info_rec(in_index).shipped_date;
    -- ���Ɏ��ѓ�
    gr_mov_req_instr_h_rec.actual_arrival_date
                                            := gr_interface_info_rec(in_index).arrival_date;
    -- ���i�敪
    gr_mov_req_instr_h_rec.item_class       := gr_interface_info_rec(in_index).prod_kbn_cd;
    -- ���i���ʋ敪
    IF (gr_interface_info_rec(in_index).item_kbn_cd = gv_item_kbn_cd_5) THEN
      gr_mov_req_instr_h_rec.product_flg    := gv_product_class_1;
    ELSE
      gr_mov_req_instr_h_rec.product_flg    := gv_product_class_2;
    END IF;
    -- ���ђ����t���O
    gr_mov_req_instr_h_rec.correct_actual_flg
                                            := gv_yesno_n;
    -- �O��ʒm�X�e�[�^�X
    gr_mov_req_instr_h_rec.prev_notif_status
                                            := gv_notif_status_10;
    -- �m��ʒm���{����
    gr_mov_req_instr_h_rec.notif_date       := gd_sysdate;
    -- �O��z��no
    gr_mov_req_instr_h_rec.prev_delivery_no := gv_prev_deliv_no_zero;
    -- ��ʍX�V��
    gr_mov_req_instr_h_rec.screen_update_by := gt_user_id;
    -- ��ʍX�V����
    gr_mov_req_instr_h_rec.screen_update_date
                                            := gd_sysdate;
--
    -- �o�^�������{
    INSERT INTO xxinv_mov_req_instr_headers
      ( mov_hdr_id                                          -- �ړ��w�b�_id
       ,mov_num                                             -- �ړ��ԍ�
       ,mov_type                                            -- �ړ��^�C�v
       ,entered_date                                        -- ���͓�
       ,instruction_post_code                               -- �w������
       ,status                                              -- �X�e�[�^�X
       ,notif_status                                        -- �ʒm�X�e�[�^�X
       ,shipped_locat_id                                    -- �o�Ɍ�ID
       ,shipped_locat_code                                  -- �o�Ɍ��ۊǏꏊ
       ,ship_to_locat_id                                    -- ���ɐ�ID
       ,ship_to_locat_code                                  -- ���ɐ�ۊǏꏊ
       ,schedule_ship_date                                  -- �o�ɗ\���
       ,schedule_arrival_date                               -- ���ɗ\���
       ,freight_charge_class                                -- �^���敪
       ,collected_pallet_qty                                -- �p���b�g�������
       ,out_pallet_qty                                      -- �p���b�g����(�o)
       ,in_pallet_qty                                       -- �p���b�g����(��)
       ,no_cont_freight_class                               -- �_��O�^���敪
       ,delivery_no                                         -- �z��No
       ,organization_id                                     -- �g�DID
       ,career_id                                           -- �^���Ǝ�_ID
       ,freight_carrier_code                                -- �^���Ǝ�
       ,shipping_method_code                                -- �z���敪
       ,actual_career_id                                    -- �^���Ǝ�_ID_����
       ,actual_freight_carrier_code                         -- �^���Ǝ�_����
       ,actual_shipping_method_code                         -- �z���敪_����
       ,arrival_time_from                                   -- ���׎���FROM
       ,arrival_time_to                                     -- ���׎���TO
       ,based_weight                                        -- ��{�d��
       ,based_capacity                                      -- ��{�e��
       ,weight_capacity_class                               -- �d�ʗe�ϋ敪
       ,actual_ship_date                                    -- �o�Ɏ��ѓ�
       ,actual_arrival_date                                 -- ���Ɏ��ѓ�
       ,item_class                                          -- ���i�敪
       ,product_flg                                         -- ���i���ʋ敪
       ,no_instr_actual_class                               -- �w���Ȃ����ы敪
       ,comp_actual_flg                                     -- ���ьv��σt���O
       ,correct_actual_flg                                  -- ���ђ����t���O
       ,prev_notif_status                                   -- �O��ʒm�X�e�[�^�X
       ,notif_date                                          -- �m��ʒm���{����
       ,prev_delivery_no                                    -- �O��z��No
       ,screen_update_by                                    -- ��ʍX�V��
       ,screen_update_date                                  -- ��ʍX�V����
       ,created_by                                          -- �쐬��
       ,creation_date                                       -- �쐬��
       ,last_updated_by                                     -- �ŏI�X�V��
       ,last_update_date                                    -- �ŏI�X�V��
       ,last_update_login                                   -- �ŏI�X�V���O�C��
       ,request_id                                          -- �v��id
       ,program_application_id                              -- �A�v���P�[�V����id
       ,program_id                                          -- �R���J�����g�E�v���O����id
       ,program_update_date                                 -- �v���O�����X�V��
      )
      VALUES
      ( gr_mov_req_instr_h_rec.mov_hdr_id                   -- �ړ��w�b�_ID
       ,gr_mov_req_instr_h_rec.mov_num                      -- �ړ��ԍ�
       ,gr_mov_req_instr_h_rec.mov_type                     -- �ړ��^�C�v
       ,gr_mov_req_instr_h_rec.entered_date                 -- ���͓�
       ,gr_mov_req_instr_h_rec.instruction_post_code        -- �w������
       ,gr_mov_req_instr_h_rec.status                       -- �X�e�[�^�X
       ,gr_mov_req_instr_h_rec.notif_status                 -- �ʒm�X�e�[�^�X
       ,gr_mov_req_instr_h_rec.shipped_locat_id             -- �o�Ɍ�ID
       ,gr_mov_req_instr_h_rec.shipped_locat_code           -- �o�Ɍ��ۊǏꏊ
       ,gr_mov_req_instr_h_rec.ship_to_locat_id             -- ���ɐ�ID
       ,gr_mov_req_instr_h_rec.ship_to_locat_code           -- ���ɐ�ۊǏꏊ
       ,gr_mov_req_instr_h_rec.schedule_ship_date           -- �o�ɗ\���
       ,gr_mov_req_instr_h_rec.schedule_arrival_date        -- ���ɗ\���
       ,gr_mov_req_instr_h_rec.freight_charge_class         -- �^���敪
       ,gr_mov_req_instr_h_rec.collected_pallet_qty         -- �p���b�g�������
       ,gr_mov_req_instr_h_rec.out_pallet_qty               -- �p���b�g����(�o)
       ,gr_mov_req_instr_h_rec.in_pallet_qty                -- �p���b�g����(��)
       ,gv_include_exclude_0                                -- �_��O�^���敪
       ,gr_mov_req_instr_h_rec.delivery_no                  -- �z��No
       ,gr_mov_req_instr_h_rec.organization_id              -- �g�DID
       ,gr_mov_req_instr_h_rec.career_id                    -- �^���Ǝ�_ID
       ,gr_mov_req_instr_h_rec.freight_carrier_code         -- �^���Ǝ�
       ,gr_mov_req_instr_h_rec.shipping_method_code         -- �z���敪
       ,gr_mov_req_instr_h_rec.actual_career_id             -- �^���Ǝ�_ID_����
       ,gr_mov_req_instr_h_rec.actual_freight_carrier_code  -- �^���Ǝ�_����
       ,gr_mov_req_instr_h_rec.actual_shipping_method_code  -- �z���敪_����
       ,gr_mov_req_instr_h_rec.arrival_time_from            -- ���׎���FROM
       ,gr_mov_req_instr_h_rec.arrival_time_to              -- ���׎���TO
       ,gr_mov_req_instr_h_rec.based_weight                 -- ��{�d��
       ,gr_mov_req_instr_h_rec.based_capacity               -- ��{�e��
       ,gr_mov_req_instr_h_rec.weight_capacity_class        -- �d�ʗe�ϋ敪
       ,gr_mov_req_instr_h_rec.actual_ship_date             -- �o�Ɏ��ѓ�
       ,gr_mov_req_instr_h_rec.actual_arrival_date          -- ���Ɏ��ѓ�
       ,gr_mov_req_instr_h_rec.item_class                   -- ���i�敪
       ,gr_mov_req_instr_h_rec.product_flg                  -- ���i���ʋ敪
       ,gv_yesno_y                                          -- �w���Ȃ����ы敪
       ,gv_yesno_n                                          -- ���ьv��σt���O
       ,gr_mov_req_instr_h_rec.correct_actual_flg           -- ���ђ����t���O
       ,gr_mov_req_instr_h_rec.prev_notif_status            -- �O��ʒm�X�e�[�^�X
       ,gr_mov_req_instr_h_rec.notif_date                   -- �m��ʒm���{����
       ,gr_mov_req_instr_h_rec.prev_delivery_no             -- �O��z��NO
       ,gr_mov_req_instr_h_rec.screen_update_by             -- ��ʍX�V��
       ,gr_mov_req_instr_h_rec.screen_update_date           -- ��ʍX�V����
       ,gt_user_id                                          -- �쐬��
       ,gt_sysdate                                          -- �쐬��
       ,gt_user_id                                          -- �ŏI�X�V��
       ,gt_sysdate                                          -- �ŏI�X�V��
       ,gt_login_id                                         -- �ŏI�X�V���O�C��
       ,gt_conc_request_id                                  -- �v��ID
       ,gt_prog_appl_id                                     -- �A�v���P�[�V����ID
       ,gt_conc_program_id                                  -- �R���J�����g�E�v���O����ID
       ,gt_sysdate                                          -- �v���O�����X�V��
      );
--
--********** 2008/07/07 ********** DELETE START ***
--* -- �ړ��˗�/�w���w�b�_�o�^�쐬����(�O���q�ɔ���) �ɉ��Z
--* gn_mov_h_ins_cnt := gn_mov_h_ins_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_req_instr_head_ins;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_head_upd
  * Description      : �ړ��˗�/�w���w�b�_�A�h�I��(���ьv��ҏW) �v���V�[�W��(A-7-2)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_head_upd(
    in_index                IN  NUMBER,                 -- �f�[�^index
    iv_status               IN  VARCHAR2,               -- �X�e�[�^�X
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_head_upd'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    --�ړ��ԍ�
    lt_mov_num                    xxinv_mov_req_instr_headers.mov_num%TYPE;
--
    -- �ő�p���b�g�����Z�o�֐��p�����[�^
    lv_code_class1                VARCHAR2(2);                -- 1.�R�[�h�敪�P
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.���o�ɏꏊ�R�[�h�P
    lv_code_class2                VARCHAR2(2);                -- 3.�R�[�h�敪�Q
    lv_entering_despatching_code2 VARCHAR2(4);                -- 4.���o�ɏꏊ�R�[�h�Q
    ld_standard_date              DATE;                       -- 5.���(�K�p�����)
    lv_ship_methods               VARCHAR2(2);                -- 6.�z���敪
    on_drink_deadweight           NUMBER;                     -- 7.�h�����N�ύڏd��
    on_leaf_deadweight            NUMBER;                     -- 8.���[�t�ύڏd��
    on_drink_loading_capacity     NUMBER;                     -- 9.�h�����N�ύڗe��
    on_leaf_loading_capacity      NUMBER;                     -- 10.���[�t�ύڗe��
    on_palette_max_qty            NUMBER;                     -- 11.�p���b�g�ő喇��
--
    ln_ret_code                   NUMBER;                     -- ���^�[���E�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_mov_hdr_id                 xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_mov_req_instr_h_rec := gr_mov_req_instr_h_ini;
--
    -- �ړ��˗�/�w���w�b�_�A�h�I���ҏW����
    -- �ړ��ԍ�
    gr_mov_req_instr_h_rec.mov_num        := gr_interface_info_rec(in_index).order_source_ref;
    -- �z��No
    gr_mov_req_instr_h_rec.delivery_no    := gr_interface_info_rec(in_index).delivery_no;
--
    -- �X�e�[�^�X
    gr_mov_req_instr_h_rec.status := iv_status;   -- �܂��͍������Ă��铯���l���Z�b�g���Ă���
--
    IF (iv_status = gv_mov_status_01) OR      -- �˗���
       (iv_status = gv_mov_status_03) THEN    -- ������
--
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_04; -- �o�ɕ񍐗L���Z�b�g
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_05; -- ���ɕ񍐗L���Z�b�g
      END IF;
--
    ELSIF (iv_status = gv_mov_status_05) THEN  -- ���ɕ񍐗L
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_06; -- ���o�ɕ񍐗L���Z�b�g
      END IF;
--
    ELSIF (iv_status = gv_mov_status_04) THEN  -- �o�ɕ񍐗L
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        gr_mov_req_instr_h_rec.status := gv_mov_status_06; -- ���o�ɕ񍐗L���Z�b�g
      END IF;
    END IF;
--
    IF (gr_interface_info_rec(in_index).out_warehouse_flg = gv_flg_on)
    THEN
      --�o�ɗ\���
      gr_mov_req_instr_h_rec.schedule_ship_date
                                            := gr_interface_info_rec(in_index).shipped_date;
      --���ɗ\���
      gr_mov_req_instr_h_rec.schedule_arrival_date
                                            := gr_interface_info_rec(in_index).arrival_date;
    END IF;
--
    --�p���b�g�������
    gr_mov_req_instr_h_rec.collected_pallet_qty
                                          := gr_interface_info_rec(in_index).collected_pallet_qty;
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      --�p���b�g����(�o)
      gr_mov_req_instr_h_rec.out_pallet_qty
                                          := gr_interface_info_rec(in_index).used_pallet_qty;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      --�p���b�g����(��)
      gr_mov_req_instr_h_rec.in_pallet_qty
                                          := gr_interface_info_rec(in_index).used_pallet_qty;
    END IF;
    --�^���Ǝ�_ID_����
    gr_mov_req_instr_h_rec.actual_career_id
                                          := gr_interface_info_rec(in_index).result_freight_carrier_id;
    --�^���Ǝ�_����
    gr_mov_req_instr_h_rec.actual_freight_carrier_code
                                          := gr_interface_info_rec(in_index).freight_carrier_code;
--
    --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      --��{�d��
      -- �p�����[�^���擾
      -- 1.�R�[�h�敪�P
      lv_code_class1                := gv_code_class_04;
      -- 2.���o�ɏꏊ�R�[�h�P
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.�R�[�h�敪�Q
      lv_code_class2                := gv_code_class_04;
      -- 4.���o�ɏꏊ�R�[�h�Q
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).ship_to_location;
      -- 5.���(�K�p�����)
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        ld_standard_date := gr_interface_info_rec(in_index).arrival_date;
      END IF;
      -- 6.�z���敪
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- �z���敪��NULL�̏ꍇ�A�ő�z���敪���擾���čő�p���b�g�������擾����B
      IF (lv_ship_methods IS NULL) THEN
--
        -- �ő�z���敪�Z�o�֐�
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:�R�[�h�敪1
                                  ,lv_entering_despatching_code1                         -- IN:���o�ɏꏊ�R�[�h1
                                  ,lv_code_class2                                        -- IN:�R�[�h�敪2
                                  ,lv_entering_despatching_code2                         -- IN:���o�ɏꏊ�R�[�h2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:���i�敪
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:�d�ʗe�ϋ敪
                                  ,NULL                                                  -- IN:�����z�ԑΏۋ敪
                                  ,ld_standard_date                                      -- IN:���
                                  ,lv_ship_methods                -- OUT:�ő�z���敪
                                  ,on_drink_deadweight            -- OUT:�h�����N�ύڏd��
                                  ,on_leaf_deadweight             -- OUT:���[�t�ύڏd��
                                  ,on_drink_loading_capacity      -- OUT:�h�����N�ύڗe��
                                  ,on_leaf_loading_capacity       -- OUT:���[�t�ύڗe��
                                  ,on_palette_max_qty);           -- OUT:�p���b�g�ő喇��
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- �ő�z���敪�Z�o�֐��G���[
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --�󒍃\�[�X�Q��
                        ,gv_table_token                                        -- �g�[�N���FTABLE_NAME
                        ,gv_table_token02_nm                                   -- �e�[�u�����F�ړ��˗�/�w���w�b�_(�A�h�I��)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- �p�����[�^�F�R�[�h�敪�P
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                        ,gv_param5_token
                        ,lv_code_class2                                        -- �p�����[�^�F�R�[�h�敪�Q
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- �p�����[�^�F���i�敪
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- �p�����[�^�F�d�ʗe�ϋ敪
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- �p�����[�^�F���
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- �ő�z���敪�Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
        END IF;
--
        gr_interface_info_rec(in_index).shipping_method_code := lv_ship_methods;
--
      END IF;
--
      -- �ő�p���b�g�����擾
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.�R�[�h�敪�P
                                lv_entering_despatching_code1,  -- 2.���o�ɏꏊ�R�[�h�P
                                lv_code_class2,                 -- 3.�R�[�h�敪�Q
                                lv_entering_despatching_code2,  -- 4.���o�ɏꏊ�R�[�h�Q
                                ld_standard_date,               -- 5.���(�K�p�����)
                                lv_ship_methods,                -- 6.�z���敪
                                on_drink_deadweight,            -- 7.�h�����N�ύڏd��
                                on_leaf_deadweight,             -- 8.���[�t�ύڏd��
                                on_drink_loading_capacity,      -- 9.�h�����N�ύڗe��
                                on_leaf_loading_capacity,       -- 10.���[�t�ύڗe��
                                on_palette_max_qty);            -- 11.�p���b�g�ő喇��
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- �ő�p���b�g�����Z�o�֐��G���[
                      ,gv_param7_token
                      ,gr_interface_info_rec(in_index).delivery_no      --�z��No
                      ,gv_param8_token
                      ,gr_interface_info_rec(in_index).order_source_ref --�󒍃\�[�X�Q��
                      ,gv_table_token                   -- �g�[�N���FTABLE_NAME
                      ,gv_table_token02_nm              -- �e�[�u�����F�ړ��˗�/�w���w�b�_(�A�h�I��)
                      ,gv_param1_token
                      ,lv_code_class1                   -- �p�����[�^�F�R�[�h�敪�P
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                      ,gv_param3_token
                      ,lv_code_class2                   -- �p�����[�^�F�R�[�h�敪�Q
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                 -- �p�����[�^�F���
                      ,gv_param6_token
                      ,lv_ship_methods                  -- �p�����[�^�F�z���敪
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;   -- �ő�p���b�g�����Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_weight := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_weight := on_leaf_deadweight;
      END IF;
      --��{�e��
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_capacity
                                            := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_capacity
                                            := on_leaf_loading_capacity;
      END IF;
--
      --�z���敪_����
      gr_mov_req_instr_h_rec.actual_shipping_method_code
                                            := gr_interface_info_rec(in_index).shipping_method_code;
--
    END IF;
--
    --�o�Ɏ��ѓ�
    gr_mov_req_instr_h_rec.actual_ship_date
                                          := gr_interface_info_rec(in_index).shipped_date;
    --���Ɏ��ѓ�
    gr_mov_req_instr_h_rec.actual_arrival_date
                                          := gr_interface_info_rec(in_index).arrival_date;
--
    -- �O���q�Ɂi�w���Ȃ��j�̏ꍇ�A�o�Ɂ^���ɗ\������o�Ɂ^���Ɏ��ѓ��ōX�V����B
    IF (gr_interface_info_rec(in_index).out_warehouse_flg = gv_flg_on)
    THEN
--
      UPDATE xxinv_mov_req_instr_headers xmrih
      SET xmrih.status                      = gr_mov_req_instr_h_rec.status
         ,xmrih.schedule_ship_date          = gr_mov_req_instr_h_rec.schedule_ship_date
         ,xmrih.schedule_arrival_date       = gr_mov_req_instr_h_rec.schedule_arrival_date
         ,xmrih.collected_pallet_qty        = gr_mov_req_instr_h_rec.collected_pallet_qty
         ,xmrih.out_pallet_qty              = DECODE(gr_mov_req_instr_h_rec.out_pallet_qty,NULL,xmrih.out_pallet_qty,gr_mov_req_instr_h_rec.out_pallet_qty)
         ,xmrih.in_pallet_qty               = DECODE(gr_mov_req_instr_h_rec.in_pallet_qty,NULL,xmrih.in_pallet_qty,gr_mov_req_instr_h_rec.in_pallet_qty)  
         ,xmrih.actual_career_id            = gr_mov_req_instr_h_rec.actual_career_id
         ,xmrih.actual_freight_carrier_code = gr_mov_req_instr_h_rec.actual_freight_carrier_code
         ,xmrih.actual_shipping_method_code = gr_mov_req_instr_h_rec.actual_shipping_method_code
         ,xmrih.based_weight                = gr_mov_req_instr_h_rec.based_weight
         ,xmrih.based_capacity              = gr_mov_req_instr_h_rec.based_capacity
         ,xmrih.actual_ship_date            = gr_mov_req_instr_h_rec.actual_ship_date
         ,xmrih.actual_arrival_date         = gr_mov_req_instr_h_rec.actual_arrival_date
         ,xmrih.last_updated_by             = gt_user_id
         ,xmrih.last_update_date            = gt_sysdate
         ,xmrih.last_update_login           = gt_login_id
         ,xmrih.request_id                  = gt_conc_request_id
         ,xmrih.program_application_id      = gt_prog_appl_id
         ,xmrih.program_id                  = gt_conc_program_id
         ,xmrih.program_update_date         = gt_sysdate
      WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- �ړ�No
      AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- �z��No
      AND   xmrih.status     <> gv_mov_status_99                    -- �X�e�[�^�X<>���
      ;
--
    ELSE
--
      UPDATE xxinv_mov_req_instr_headers xmrih
      SET xmrih.status                      = gr_mov_req_instr_h_rec.status
         ,xmrih.collected_pallet_qty        = gr_mov_req_instr_h_rec.collected_pallet_qty
         ,xmrih.out_pallet_qty              = DECODE(gr_mov_req_instr_h_rec.out_pallet_qty,NULL,xmrih.out_pallet_qty,gr_mov_req_instr_h_rec.out_pallet_qty)
         ,xmrih.in_pallet_qty               = DECODE(gr_mov_req_instr_h_rec.in_pallet_qty,NULL,xmrih.in_pallet_qty,gr_mov_req_instr_h_rec.in_pallet_qty)  
         ,xmrih.actual_career_id            = gr_mov_req_instr_h_rec.actual_career_id
         ,xmrih.actual_freight_carrier_code = gr_mov_req_instr_h_rec.actual_freight_carrier_code
         ,xmrih.actual_shipping_method_code = gr_mov_req_instr_h_rec.actual_shipping_method_code
         ,xmrih.based_weight                = gr_mov_req_instr_h_rec.based_weight
         ,xmrih.based_capacity              = gr_mov_req_instr_h_rec.based_capacity
         ,xmrih.actual_ship_date            = gr_mov_req_instr_h_rec.actual_ship_date
         ,xmrih.actual_arrival_date         = gr_mov_req_instr_h_rec.actual_arrival_date
         ,xmrih.last_updated_by             = gt_user_id
         ,xmrih.last_update_date            = gt_sysdate
         ,xmrih.last_update_login           = gt_login_id
         ,xmrih.request_id                  = gt_conc_request_id
         ,xmrih.program_application_id      = gt_prog_appl_id
         ,xmrih.program_id                  = gt_conc_program_id
         ,xmrih.program_update_date         = gt_sysdate
      WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- �ړ�No
      AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- �z��No
      AND   xmrih.status     <> gv_mov_status_99                    -- �X�e�[�^�X<>���
      ;
--
    END IF;
--
    -- �ړ��˗�/�w���w�b�_ID�̎擾
    SELECT mov_hdr_id
    INTO lt_mov_hdr_id
    FROM xxinv_mov_req_instr_headers xmrih
    WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- �ړ�No
    AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- �z��No
    AND   xmrih.status     <> gv_mov_status_99                    -- �X�e�[�^�X<>���
    ;
--
    gr_mov_req_instr_h_rec.mov_hdr_id := lt_mov_hdr_id;
--
--********** 2008/07/07 ********** DELETE START ***
--* -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ьv��) ���Z
--* gn_mov_h_upd_n_cnt := gn_mov_h_upd_n_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_req_instr_head_upd;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_head_inup
  * Description      : �ړ��˗�/�w���w�b�_�A�h�I��(���ђ����ҏW) �v���V�[�W��(A-7-3)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_head_inup(
    in_index                IN  NUMBER,                 -- �f�[�^index
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_head_inup'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    --�ړ��ԍ�
    lt_mov_num                      xxinv_mov_req_instr_headers.mov_num%TYPE;
--
    -- �ő�p���b�g�����Z�o�֐��p�����[�^
    lv_code_class1                VARCHAR2(2);                -- 1.�R�[�h�敪�P
    lv_entering_despatching_code1 VARCHAR2(4);                -- 2.���o�ɏꏊ�R�[�h�P
    lv_code_class2                VARCHAR2(2);                -- 3.�R�[�h�敪�Q
    lv_entering_despatching_code2 VARCHAR2(4);                -- 4.���o�ɏꏊ�R�[�h�Q
    ld_standard_date              DATE;                       -- 5.���(�K�p�����)
    lv_ship_methods               VARCHAR2(2);                -- 6.�z���敪
    on_drink_deadweight           NUMBER;                     -- 7.�h�����N�ύڏd��
    on_leaf_deadweight            NUMBER;                     -- 8.���[�t�ύڏd��
    on_drink_loading_capacity     NUMBER;                     -- 9.�h�����N�ύڗe��
    on_leaf_loading_capacity      NUMBER;                     -- 10.���[�t�ύڗe��
    on_palette_max_qty            NUMBER;                     -- 11.�p���b�g�ő喇��
--
    ln_ret_code                   NUMBER;                     -- ���^�[���E�R�[�h
--
    lt_mov_hdr_id                 xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--  ������
    gr_mov_req_instr_h_rec := gr_mov_req_instr_h_ini;
--
    -- �ړ��˗�/�w���w�b�_�A�h�I���ҏW����
    --�ړ��ԍ�
    gr_mov_req_instr_h_rec.mov_num          := gr_interface_info_rec(in_index).order_source_ref;
    --�z��No
    gr_mov_req_instr_h_rec.delivery_no      := gr_interface_info_rec(in_index).delivery_no;
    --�p���b�g�������
    gr_mov_req_instr_h_rec.collected_pallet_qty
                                            := gr_interface_info_rec(in_index).collected_pallet_qty;
    IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
      --�p���b�g����(�o)
      gr_mov_req_instr_h_rec.out_pallet_qty := gr_interface_info_rec(in_index).used_pallet_qty;
    ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
      --�p���b�g����(��)
      gr_mov_req_instr_h_rec.in_pallet_qty  := gr_interface_info_rec(in_index).used_pallet_qty;
    END IF;
--
    --�`�F�b�N�L����IF_H.�^���敪�Ŕ���
    IF (gr_interface_info_rec(in_index).freight_charge_class = gv_include_exclude_1) THEN
--
      --��{�d��
      -- �p�����[�^���擾
      -- 1.�R�[�h�敪�P
      lv_code_class1                := gv_code_class_04;
      -- 2.���o�ɏꏊ�R�[�h�P
      lv_entering_despatching_code1 := gr_interface_info_rec(in_index).location_code;
      -- 3.�R�[�h�敪�Q
      lv_code_class2                := gv_code_class_04;
      -- 4.���o�ɏꏊ�R�[�h�Q
      lv_entering_despatching_code2 := gr_interface_info_rec(in_index).ship_to_location;
      -- 5.���(�K�p�����)
      IF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_220) THEN
        ld_standard_date := gr_interface_info_rec(in_index).shipped_date;
      ELSIF (gr_interface_info_rec(in_index).eos_data_type = gv_eos_data_cd_230) THEN
        ld_standard_date := gr_interface_info_rec(in_index).arrival_date;
      END IF;
      -- 6.�z���敪
      lv_ship_methods               := gr_interface_info_rec(in_index).shipping_method_code;
--
      -- �z���敪��NULL�̏ꍇ�A�ő�z���敪���擾���čő�p���b�g�������擾����B
      IF (lv_ship_methods IS NULL) THEN
--
        -- �ő�z���敪�Z�o�֐�
        ln_ret_code := xxwsh_common_pkg.get_max_ship_method(
                                   lv_code_class1                                        -- IN:�R�[�h�敪1
                                  ,lv_entering_despatching_code1                         -- IN:���o�ɏꏊ�R�[�h1
                                  ,lv_code_class2                                        -- IN:�R�[�h�敪2
                                  ,lv_entering_despatching_code2                         -- IN:���o�ɏꏊ�R�[�h2
                                  ,gr_interface_info_rec(in_index).prod_kbn_cd           -- IN:���i�敪
                                  ,gr_interface_info_rec(in_index).weight_capacity_class -- IN:�d�ʗe�ϋ敪
                                  ,NULL                                                  -- IN:�����z�ԑΏۋ敪
                                  ,ld_standard_date                                      -- IN:���
                                  ,lv_ship_methods                -- OUT:�ő�z���敪
                                  ,on_drink_deadweight            -- OUT:�h�����N�ύڏd��
                                  ,on_leaf_deadweight             -- OUT:���[�t�ύڏd��
                                  ,on_drink_loading_capacity      -- OUT:�h�����N�ύڗe��
                                  ,on_leaf_loading_capacity       -- OUT:���[�t�ύڗe��
                                  ,on_palette_max_qty);           -- OUT:�p���b�g�ő喇��
--
        IF (ln_ret_code = gn_warn) THEN
--
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                         gv_msg_kbn                       -- 'XXWSH'
                        ,gv_msg_93a_152                   -- �ő�z���敪�Z�o�֐��G���[
                        ,gv_param1_token
                        ,gr_interface_info_rec(in_index).delivery_no           --�z��No
                        ,gv_param2_token
                        ,gr_interface_info_rec(in_index).order_source_ref      --�󒍃\�[�X�Q��
                        ,gv_table_token                                        -- �g�[�N���FTABLE_NAME
                        ,gv_table_token02_nm                                   -- �e�[�u�����F�ړ��˗�/�w���w�b�_(�A�h�I��)
                        ,gv_param3_token
                        ,lv_code_class1                                        -- �p�����[�^�F�R�[�h�敪�P
                        ,gv_param4_token
                        ,lv_entering_despatching_code1                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                        ,gv_param5_token
                        ,lv_code_class2                                        -- �p�����[�^�F�R�[�h�敪�Q
                        ,gv_param6_token
                        ,lv_entering_despatching_code2                         -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                        ,gv_param7_token
                        ,gr_interface_info_rec(in_index).prod_kbn_cd           -- �p�����[�^�F���i�敪
                        ,gv_param8_token
                        ,gr_interface_info_rec(in_index).weight_capacity_class -- �p�����[�^�F�d�ʗe�ϋ敪
                        ,gv_param9_token
                        ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')                -- �p�����[�^�F���
                        )
                        ,1
                        ,5000);
--
          RAISE global_api_expt;   -- �ő�z���敪�Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
        END IF;
--
      END IF;
--
      -- �ő�p���b�g�����擾
      ln_ret_code := xxwsh_common_pkg.get_max_pallet_qty(
                                lv_code_class1,                 -- 1.�R�[�h�敪�P
                                lv_entering_despatching_code1,  -- 2.���o�ɏꏊ�R�[�h�P
                                lv_code_class2,                 -- 3.�R�[�h�敪�Q
                                lv_entering_despatching_code2,  -- 4.���o�ɏꏊ�R�[�h�Q
                                ld_standard_date,               -- 5.���(�K�p�����)
                                lv_ship_methods,                -- 6.�z���敪
                                on_drink_deadweight,            -- 7.�h�����N�ύڏd��
                                on_leaf_deadweight,             -- 8.���[�t�ύڏd��
                                on_drink_loading_capacity,      -- 9.�h�����N�ύڗe��
                                on_leaf_loading_capacity,       -- 10.���[�t�ύڗe��
                                on_palette_max_qty);            -- 11.�p���b�g�ő喇��
--
      IF (ln_ret_code = gn_warn) THEN
--
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(
                       gv_msg_kbn                       -- 'XXWSH'
                      ,gv_msg_93a_025                   -- �ő�p���b�g�����Z�o�֐��G���[
                      ,gv_param7_token
                      ,gr_mov_req_instr_h_rec.delivery_no --�z��No
                      ,gv_param8_token
                      ,gr_mov_req_instr_h_rec.mov_num   --�󒍃\�[�X�Q��(�ړ��ԍ�)
                      ,gv_table_token                   -- �g�[�N���FTABLE_NAME
                      ,gv_table_token02_nm              -- �e�[�u�����F�ړ��˗�/�w���w�b�_(�A�h�I��)
                      ,gv_param1_token
                      ,lv_code_class1                   -- �p�����[�^�F�R�[�h�敪�P
                      ,gv_param2_token
                      ,lv_entering_despatching_code1    -- �p�����[�^�F���o�ɏꏊ�R�[�h�P
                      ,gv_param3_token
                      ,lv_code_class2                   -- �p�����[�^�F�R�[�h�敪�Q
                      ,gv_param4_token
                      ,lv_entering_despatching_code2    -- �p�����[�^�F���o�ɏꏊ�R�[�h�Q
                      ,gv_param5_token
                      ,TO_CHAR(ld_standard_date,'YYYY/MM/DD')    -- �p�����[�^�F���
                      ,gv_param6_token
                      ,lv_ship_methods                  -- �p�����[�^�F�z���敪
                      )
                      ,1
                      ,5000);
--
        RAISE global_api_expt;  -- �ő�p���b�g�����Z�o�֐��G���[�̏ꍇ��ABEND�����Ă��ׂ�ROLLBACK����
--
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_drink_deadweight;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_weight   := on_leaf_deadweight;
      END IF;
      --��{�e��
      IF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_2))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_drink_loading_capacity;
      ELSIF ((ln_ret_code = gn_normal) AND (gr_interface_info_rec(in_index).prod_kbn_cd = gv_prod_kbn_cd_1))
      THEN
        gr_mov_req_instr_h_rec.based_capacity := on_leaf_loading_capacity;
      END IF;
--
    END IF;
--
    --���ђ����t���O
    gr_mov_req_instr_h_rec.correct_actual_flg := gv_yesno_y;
--
    UPDATE xxinv_mov_req_instr_headers xmrih
    SET xmrih.collected_pallet_qty        = gr_mov_req_instr_h_rec.collected_pallet_qty
       ,xmrih.out_pallet_qty              = DECODE(gr_mov_req_instr_h_rec.out_pallet_qty,NULL,xmrih.out_pallet_qty,gr_mov_req_instr_h_rec.out_pallet_qty)
       ,xmrih.in_pallet_qty               = DECODE(gr_mov_req_instr_h_rec.in_pallet_qty,NULL,xmrih.in_pallet_qty,gr_mov_req_instr_h_rec.in_pallet_qty)  
       ,xmrih.based_weight                = gr_mov_req_instr_h_rec.based_weight
       ,xmrih.based_capacity              = gr_mov_req_instr_h_rec.based_capacity
       ,xmrih.correct_actual_flg          = gr_mov_req_instr_h_rec.correct_actual_flg
       ,xmrih.last_updated_by             = gt_user_id
       ,xmrih.last_update_date            = gt_sysdate
       ,xmrih.last_update_login           = gt_login_id
       ,xmrih.request_id                  = gt_conc_request_id
       ,xmrih.program_application_id      = gt_prog_appl_id
       ,xmrih.program_id                  = gt_conc_program_id
       ,xmrih.program_update_date         = gt_sysdate
    WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- �ړ�No
    AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- �z��No
    AND   xmrih.status     <> gv_mov_status_99                    -- �X�e�[�^�X<>���
    ;
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- �ړ��˗�/�w���w�b�_ID�̎擾
    SELECT mov_hdr_id
    INTO lt_mov_hdr_id
    FROM xxinv_mov_req_instr_headers xmrih
    WHERE xmrih.mov_num     = gr_mov_req_instr_h_rec.mov_num      -- �ړ�No
    AND   NVL(xmrih.delivery_no,gv_delivery_no_null) = NVL(gr_mov_req_instr_h_rec.delivery_no,gv_delivery_no_null)  -- �z��No
    AND   xmrih.status     <> gv_mov_status_99                    -- �X�e�[�^�X<>���
    ;
--
    gr_mov_req_instr_h_rec.mov_hdr_id := lt_mov_hdr_id;
--
--********** 2008/07/07 ********** DELETE START ***
--* gn_mov_h_upd_y_cnt := gn_mov_h_upd_y_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_req_instr_head_inup;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_lines_ins
  * Description      : �ړ��˗�/�w�����׃A�h�I��INSERT �v���V�[�W��(A-7-4)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_lines_ins(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    iv_cnt_kbn              IN  VARCHAR2,            -- �f�[�^�����J�E���g�敪
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_lines_ins'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    lt_mov_hdr_id                               xxinv_mov_req_instr_headers.mov_hdr_id%TYPE;
    -- *** ���[�J���ϐ� ***
    ln_mov_line_seq                             NUMBER;
    ln_sum_actual_quantity                      xxinv_mov_lot_details.actual_quantity%TYPE;
    ln_line_number                              NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_mov_req_instr_l_rec := gr_mov_req_instr_l_ini;
--
    -- �ړ��˗�/�w���w�b�_�A�h�I���ҏW����
--
    -- �ړ�����ID�̎擾(�V�[�P���X)
    SELECT xxinv_mov_line_s1.NEXTVAL
    INTO ln_mov_line_seq
    FROM dual;
    gr_mov_req_instr_l_rec.mov_line_id := ln_mov_line_seq;
--
    --�ړ��w�b�_ID
    gr_mov_req_instr_l_rec.mov_hdr_id := gr_mov_req_instr_h_rec.mov_hdr_id;
--
    -- ���הԍ�
    -- ����w�b�_��MAX(���הԍ�) + 1���擾
    SELECT NVL(MAX(line_number), 0 ) + 1
    INTO   ln_line_number
    FROM   xxinv_mov_req_instr_lines xmril
    WHERE  xmril.mov_hdr_id = gr_mov_req_instr_h_rec.mov_hdr_id  --�ړ��w�b�_ID
    ;
--
    gr_mov_req_instr_l_rec.line_number     := ln_line_number;
    -- �g�DID    (�V�X�e���v���t�@�C���I�v�V����)
    gr_mov_req_instr_l_rec.organization_id := TO_NUMBER(gv_master_org_id);
    -- OPM�i��ID  (OPM�i�ڃ}�X�^.OPM�i��ID��ݒ�)
    gr_mov_req_instr_l_rec.item_id         := gr_interface_info_rec(in_idx).item_id;
    -- �i��  (IF_L.�󒍕i��)
    gr_mov_req_instr_l_rec.item_code       := gr_interface_info_rec(in_idx).orderd_item_code;
    -- �P��  (OPM�i�ڃ}�X�^.�P��)
    gr_mov_req_instr_l_rec.uom_code        := gr_interface_info_rec(in_idx).item_um;
--
    -- �o�Ɏ��ѐ��ʁE���Ɏ��ѐ��ʂ̐ݒ���s���B
    -- ���b�g�Ǘ��敪 = 0:���b�g�Ǘ��i�ΏۊO
    IF gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0 THEN
--
      -- �o�׈˗�IF����.�o�׎��ѐ��ʂ�ݒ�
      gr_mov_req_instr_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity; -- �o�Ɏ��ѐ���
      -- �o�׈˗�IF����.���Ɏ��ѐ��ʂ�ݒ�
      gr_mov_req_instr_l_rec.ship_to_quantity
             := gr_interface_info_rec(in_idx).ship_to_quantity; -- ���Ɏ��ѐ���
--
    END IF;
--
    gr_mov_req_instr_l_rec.delete_flg                  := gv_yesno_n;  --����t���O:'N'
--
    -- **************************************************
    -- *** �ړ��˗�/�w������(�A�h�I��)�o�^���s��
    -- **************************************************
    INSERT INTO xxinv_mov_req_instr_lines
      (mov_line_id                                        -- �ړ�����ID
      ,mov_hdr_id                                         -- �ړ��w�b�_ID
      ,line_number                                        -- ���הԍ�
      ,organization_id                                    -- �g�DID
      ,item_id                                            -- opm�i��ID
      ,item_code                                          -- �i��
      ,uom_code                                           -- �P��
      ,shipped_quantity                                   -- �o�Ɏ��ѐ���
      ,ship_to_quantity                                   -- ���Ɏ��ѐ���
      ,delete_flg                                         -- ����t���O
      ,created_by                                         -- �쐬��
      ,creation_date                                      -- �쐬��
      ,last_updated_by                                    -- �ŏI�X�V��
      ,last_update_date                                   -- �ŏI�X�V��
      ,last_update_login                                  -- �ŏI�X�V���O�C��
      ,request_id                                         -- �v��ID
      ,program_application_id                             -- �A�v���P�[�V����ID
      ,program_id                                         -- �R���J�����g�E�v���O����ID
      ,program_update_date                                -- �v���O�����X�V��
      )
    VALUES
      (gr_mov_req_instr_l_rec.mov_line_id                 -- �ړ�����ID
      ,gr_mov_req_instr_l_rec.mov_hdr_id                  -- �ړ��w�b�_ID
      ,gr_mov_req_instr_l_rec.line_number                 -- ���הԍ�
      ,gr_mov_req_instr_l_rec.organization_id             -- �g�DID
      ,gr_mov_req_instr_l_rec.item_id                     -- OPM�i��ID
      ,gr_mov_req_instr_l_rec.item_code                   -- �i��
      ,gr_mov_req_instr_l_rec.uom_code                    -- �P��
      ,gr_mov_req_instr_l_rec.shipped_quantity            -- �o�Ɏ��ѐ���
      ,gr_mov_req_instr_l_rec.ship_to_quantity            -- ���Ɏ��ѐ���
      ,gr_mov_req_instr_l_rec.delete_flg                  -- ����t���O
      ,gt_user_id                                         -- �쐬��
      ,gt_sysdate                                         -- �쐬��
      ,gt_user_id                                         -- �ŏI�X�V��
      ,gt_sysdate                                         -- �ŏI�X�V��
      ,gt_login_id                                        -- �ŏI�X�V���O�C��
      ,gt_conc_request_id                                 -- �v��ID
      ,gt_prog_appl_id                                    -- �A�v���P�[�V����ID
      ,gt_conc_program_id                                 -- �R���J�����g�E�v���O����ID
      ,gt_sysdate                                         -- �v���O�����X�V��
     );
--
    --�������Z
--********** 2008/07/07 ********** DELETE START ***
--* IF (iv_cnt_kbn = gv_cnt_kbn_2) -- �w���i�ځ����ѕi�ڂɉ��Z
--* THEN
--*   gn_mov_l_ins_n_cnt := gn_mov_l_ins_n_cnt + 1;
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_3) -- �O���q��(�w���Ȃ�)�ɉ��Z
--*  THEN
--*       gn_mov_l_ins_cnt := gn_mov_l_ins_cnt + 1;
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_7) -- �������i�ڂȂ��ɉ��Z
--*  THEN
--*       gn_mov_l_ins_y_cnt := gn_mov_l_ins_y_cnt + 1;
--* END IF;
--
    IF ((iv_cnt_kbn = gv_cnt_kbn_2) OR
        (iv_cnt_kbn = gv_cnt_kbn_3))
    THEN
      -- �w������i���ьv��j�^�w���Ȃ��i�O���q�Ɂj�̏ꍇ
      gn_mov_new_cnt := gn_mov_new_cnt + 1;
--
    ELSIF (iv_cnt_kbn = gv_cnt_kbn_7) THEN
      -- �����̏ꍇ
      gn_mov_correct_cnt := gn_mov_correct_cnt + 1;
--
    END IF;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_req_instr_lines_ins;
--
 /**********************************************************************************
  * Procedure Name   : mov_req_instr_lines_upd
  * Description      : �ړ��˗�/�w�����׃A�h�I��UPDATE �v���V�[�W��(A-7-5)
  ***********************************************************************************/
  PROCEDURE mov_req_instr_lines_upd(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    in_mov_line_id          IN  NUMBER,              -- �ړ�����ID
    iv_cnt_kbn              IN  VARCHAR2,            -- �f�[�^�����J�E���g�敪
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_req_instr_lines_upd'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_sum_actual_quantity     xxinv_mov_lot_details.actual_quantity%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_mov_req_instr_l_rec := gr_mov_req_instr_l_ini;
--
    -- �ړ�����ID��ݒ�
    -- ���b�g�ڍׂ�INSERT������Ƃ�(A-7-6)�ɕK�v�ȃL�[���ڂȂ̂ł����ŕK���Z�b�g����
    gr_mov_req_instr_l_rec.mov_line_id := in_mov_line_id;
--
    -- �o�Ɏ��ѐ��ʁE���Ɏ��ѐ��ʂ̐ݒ���s���B
    -- ���b�g�Ǘ��敪 = 0:���b�g�Ǘ��i�ΏۊO
    IF gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0 THEN
--
      -- �o�׈˗�IF����.�o�׎��ѐ��ʂ�ݒ�
      gr_mov_req_instr_l_rec.shipped_quantity
             := gr_interface_info_rec(in_idx).shiped_quantity;-- �o�Ɏ��ѐ���
      -- �o�׈˗�IF����.���Ɏ��ѐ��ʂ�ݒ�
      gr_mov_req_instr_l_rec.ship_to_quantity
             := gr_interface_info_rec(in_idx).ship_to_quantity;-- ���Ɏ��ѐ���
--
      -- **************************************************
      -- *** �ړ��˗�/�w������(�A�h�I��)�X�V���s��
      -- **************************************************
      UPDATE
        xxinv_mov_req_instr_lines    xmrl     -- �ړ��˗�/�w������(�A�h�I��)
      SET
         xmrl.shipped_quantity        = NVL(gr_mov_req_instr_l_rec.shipped_quantity,xmrl.shipped_quantity) -- �o�Ɏ��ѐ���
        ,xmrl.ship_to_quantity        = NVL(gr_mov_req_instr_l_rec.ship_to_quantity,xmrl.ship_to_quantity) -- ���Ɏ��ѐ���
        ,xmrl.last_updated_by         = gt_user_id                              -- �ŏI�X�V��
        ,xmrl.last_update_date        = gt_sysdate                              -- �ŏI�X�V��
        ,xmrl.last_update_login       = gt_login_id                             -- �ŏI�X�V���O�C��
        ,xmrl.request_id              = gt_conc_request_id                      -- �v��ID
        ,xmrl.program_application_id  = gt_prog_appl_id                         -- �A�v���P�[�V����ID
        ,xmrl.program_id              = gt_conc_program_id                      -- �v���O����ID
        ,xmrl.program_update_date     = gt_sysdate                              -- �v���O�����X�V��
      WHERE
          xmrl.mov_line_id   = in_mov_line_id                                   -- �ړ��w�b�_ID
      AND xmrl.item_code     = gr_interface_info_rec(in_idx).orderd_item_code   -- �i��
      AND ((xmrl.delete_flg = gv_yesno_n) OR (xmrl.delete_flg IS NULL))       -- �폜�t���O=���폜
      ;
--
    END IF;
--
    --�������Z
--********** 2008/07/07 ********** MODIFY START ***
--* IF (iv_cnt_kbn = gv_cnt_kbn_1)     -- �w���i��=���ѕi�ڂɉ��Z
--* THEN
--*   gn_mov_l_upd_n_cnt := gn_mov_l_upd_n_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_6) -- �������i�ڂ���ɉ��Z
--*  THEN
--*       gn_mov_l_upd_y_cnt := gn_mov_l_upd_y_cnt + 1;
--* END IF;
--
    IF (iv_cnt_kbn = gv_cnt_kbn_1)
    THEN
      -- �w������i���ьv��j�̏ꍇ
      gn_mov_new_cnt := gn_mov_new_cnt + 1;
--
    ELSIF (iv_cnt_kbn = gv_cnt_kbn_6) THEN
      -- �����̏ꍇ
      gn_mov_correct_cnt := gn_mov_correct_cnt + 1;
--
    END IF;
--********** 2008/07/07 ********** MODIFY END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_req_instr_lines_upd;
--
 /**********************************************************************************
  * Procedure Name   : mov_movlot_detail_ins
  * Description      : �ړ��˗�/�w���f�[�^�ړ����b�g�ڍ�INSERT �v���V�[�W��(A-7-6)
  ***********************************************************************************/
  PROCEDURE mov_movlot_detail_ins(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    iv_cnt_kbn              IN  VARCHAR2,            -- �f�[�^�����J�E���g�敪
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_movlot_detail_ins'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_mov_lot_seq       NUMBER;  --�ړ����b�g�ڍ�(�A�h�I��).���b�g�ڍ�IDseq
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
--  ������
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    -- ���b�g�ڍ�ID
    SELECT xxinv_mov_lot_s1.nextval
    INTO   ln_mov_lot_seq
    FROM   dual
    ;
--
    gr_movlot_detail_rec.mov_lot_dtl_id     := ln_mov_lot_seq;
--
    -- �ړ�����ID��ݒ�
    gr_movlot_detail_rec.mov_line_id        := gr_mov_req_instr_l_rec.mov_line_id;
--
    -- �����^�C�v��ݒ�
    gr_movlot_detail_rec.document_type_code := gv_document_type_20; --�ړ�
--
    -- EOS�f�[�^��� = �ړ��o�Ɋm��񍐂̏ꍇ
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
      -- ���R�[�h�^�C�v��ݒ�
      gr_movlot_detail_rec.record_type_code := gv_record_type_20;   -- �o�Ɏ���
      -- ���ѓ���ݒ�
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).shipped_date; -- �o�ד�
--
    -- EOS�f�[�^��� = �ړ����Ɋm��񍐂̏ꍇ
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
      -- ���R�[�h�^�C�v��ݒ�
      gr_movlot_detail_rec.record_type_code := gv_record_type_30;   -- ���Ɏ���
      -- ���ѓ���ݒ�
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).arrival_date; -- ���ד�
    END IF;
--
    -- OPM�i��ID��ݒ�
    gr_movlot_detail_rec.item_id            := gr_interface_info_rec(in_idx).item_id;
    -- �i�ڂ�ݒ�
    gr_movlot_detail_rec.item_code          := gr_interface_info_rec(in_idx).orderd_item_code;
    -- ���b�g�֘A�̕ҏW
    IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_0) THEN
      -- ���b�gID��ݒ�
      gr_movlot_detail_rec.lot_id             := 0;
      -- ���b�gNo��ݒ�
      gr_movlot_detail_rec.lot_no             := NULL;
    ELSE
      -- ���b�gID��ݒ�
      gr_movlot_detail_rec.lot_id             := gr_interface_info_rec(in_idx).lot_id;
      -- ���b�gNo��ݒ�
      gr_movlot_detail_rec.lot_no             := gr_interface_info_rec(in_idx).lot_no;
    END IF;
--
    --���ѐ��ʂ̐ݒ���s���B
    --���󐔗ʂ�ݒ�
    gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
    -- ���b�g����0�̑Ή�
    IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
       (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
      -- EOS�f�[�^��� = �ړ��o�Ɋm��񍐂̏ꍇ
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
        --IF_L.�o�׎��ѐ��� ��ݒ�
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      -- EOS�f�[�^��� = �ړ����Ɋm��񍐂̏ꍇ
      ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
        --IF_L.���Ɏ��ѐ��� ��ݒ�
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).ship_to_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** �ړ����b�g�ڍ�(�A�h�I��)�o�^���s��
    -- **************************************************
      INSERT INTO xxinv_mov_lot_details                   -- �ړ����b�g�ڍ�(�A�h�I��)
        (mov_lot_dtl_id                                   -- ���b�g�ڍ�ID
        ,mov_line_id                                      -- ����ID
        ,document_type_code                               -- �����^�C�v
        ,record_type_code                                 -- ���R�[�h�^�C�v
        ,item_id                                          -- opm�i��ID
        ,item_code                                        -- �i��
        ,lot_id                                           -- ���b�gID
        ,lot_no                                           -- ���b�gNO
        ,actual_date                                      -- ���ѓ�
        ,actual_quantity                                  -- ���ѐ���
        ,created_by                                       -- �쐬��
        ,creation_date                                    -- �쐬��
        ,last_updated_by                                  -- �ŏI�X�V��
        ,last_update_date                                 -- �ŏI�X�V��
        ,last_update_login                                -- �ŏI�X�V���O�C��
        ,request_id                                       -- �v��ID
        ,program_application_id                           -- �A�v���P�[�V����ID
        ,program_id                                       -- �R���J�����g�E�v���O����ID
        ,program_update_date                              -- �v���O�����X�V��
        )
      VALUES
        (gr_movlot_detail_rec.mov_lot_dtl_id              -- ���b�g�ڍ�ID
        ,gr_movlot_detail_rec.mov_line_id                 -- ����ID
        ,gr_movlot_detail_rec.document_type_code          -- �����^�C�v
        ,gr_movlot_detail_rec.record_type_code            -- ���R�[�h�^�C�v
        ,gr_movlot_detail_rec.item_id                     -- opm�i��id
        ,gr_movlot_detail_rec.item_code                   -- �i��
        ,gr_movlot_detail_rec.lot_id                      -- ���b�gID
        ,gr_movlot_detail_rec.lot_no                      -- ���b�gno
        ,gr_movlot_detail_rec.actual_date                 -- ���ѓ�
        ,gr_movlot_detail_rec.actual_quantity             -- ���ѐ���
        ,gt_user_id                                       -- �쐬��
        ,gt_sysdate                                       -- �쐬��
        ,gt_user_id                                       -- �ŏI�X�V��
        ,gt_sysdate                                       -- �ŏI�X�V��
        ,gt_login_id                                      -- �ŏI�X�V���O�C��
        ,gt_conc_request_id                               -- �v��ID
        ,gt_prog_appl_id                                  -- �A�v���P�[�V����ID
        ,gt_conc_program_id                               -- �R���J�����g�E�v���O����ID
        ,gt_sysdate                                       -- �v���O�����X�V��
       );
--
--********** 2008/07/07 ********** DELETE START ***
--* --�������Z
--* IF (iv_cnt_kbn = gv_cnt_kbn_5) -- ���ьv��ɉ��Z
--* THEN
--*   gn_mov_mov_ins_n_cnt := gn_mov_mov_ins_n_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_3) -- �O���q��(�w���Ȃ�)�ɉ��Z
--*  THEN
--*       gn_mov_mov_ins_cnt := gn_mov_mov_ins_cnt + 1;
--*
--* ELSIF  (iv_cnt_kbn = gv_cnt_kbn_9) -- �������b�g�Ȃ��ɉ��Z
--*  THEN
--*   gn_mov_mov_ins_y_cnt := gn_mov_mov_ins_y_cnt + 1;
--* END IF;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_movlot_detail_ins;
--
 /**********************************************************************************
  * Procedure Name   : movlot_detail_upd
  * Description      : �ړ����b�g�ڍ�UPDATE �v���V�[�W��(A-7-7)
  ***********************************************************************************/
  PROCEDURE movlot_detail_upd(
    in_idx                  IN  NUMBER,              -- �f�[�^index
    in_mov_lot_dtl_id       IN  NUMBER,              -- ���b�g�ڍ�ID
    ov_errbuf               OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'movlot_detail_upd'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--  ������
    gr_movlot_detail_rec := gr_movlot_detail_ini;
--
    -- EOS�f�[�^��� = �ړ��o�Ɋm��񍐂̏ꍇ
    IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
      -- ���ѓ���ݒ�
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).shipped_date; -- �o�ד�
--
    -- EOS�f�[�^��� = �ړ����Ɋm��񍐂̏ꍇ
    ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
      -- ���ѓ���ݒ�
      gr_movlot_detail_rec.actual_date      := gr_interface_info_rec(in_idx).arrival_date; -- ���ד�
    END IF;
--
    --���ѐ��ʂ̐ݒ���s���B
    --���󐔗ʂ�ݒ�
    gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).detailed_quantity;
--
    -- ���b�g����0�̑Ή�
    IF (gr_interface_info_rec(in_idx).lot_ctl <> gv_lotkr_kbn_cd_1) AND
       (NVL(gr_interface_info_rec(in_idx).detailed_quantity,0) = 0) THEN
--
      -- EOS�f�[�^��� = �ړ��o�Ɋm��񍐂̏ꍇ
      IF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
--
        --IF_L.�o�׎��ѐ��� ��ݒ�
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).shiped_quantity;
--
      -- EOS�f�[�^��� = �ړ����Ɋm��񍐂̏ꍇ
      ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
--
        --IF_L.���Ɏ��ѐ��� ��ݒ�
        gr_movlot_detail_rec.actual_quantity := gr_interface_info_rec(in_idx).ship_to_quantity;
--
      END IF;
--
    END IF;
--
    -- **************************************************
    -- *** �ړ����b�g�ڍ�(�A�h�I��)�X�V���s��
    -- **************************************************
    UPDATE
      xxinv_mov_lot_details    xmld     -- �ړ����b�g�ڍ�(�A�h�I��)
    SET
       xmld.actual_date             = gr_movlot_detail_rec.actual_date        -- ���ѓ�
      ,xmld.actual_quantity         = gr_movlot_detail_rec.actual_quantity    -- ���ѐ���
      ,xmld.last_updated_by         = gt_user_id                              -- �ŏI�X�V��
      ,xmld.last_update_date        = gt_sysdate                              -- �ŏI�X�V��
      ,xmld.last_update_login       = gt_login_id                             -- �ŏI�X�V���O�C��
      ,xmld.request_id              = gt_conc_request_id                      -- �v��ID
      ,xmld.program_application_id  = gt_prog_appl_id                         -- �A�v���P�[�V����ID
      ,xmld.program_id              = gt_conc_program_id                      -- �v���O����ID
      ,xmld.program_update_date     = gt_sysdate                              -- �v���O�����X�V��
    WHERE
        xmld.mov_lot_dtl_id         = in_mov_lot_dtl_id      -- ���b�g�ڍ�ID
    ;
--
--********** 2008/07/07 ********** DELETE START ***
--* --���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����) ���Z
--* gn_mov_mov_upd_y_cnt := gn_mov_mov_upd_y_cnt + 1;
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END movlot_detail_upd;
--
 /**********************************************************************************
  * Procedure Name   : get_freight_charge_type
  * Description      : �^���`�Ԏ擾 �v���V�[�W��
  ***********************************************************************************/
  PROCEDURE get_freight_charge_type(
    iv_transaction_type     IN  VARCHAR2,            --   �������(�z��)
    iv_prod_kbn_cd          IN  VARCHAR2,            --   ���i�敪
    id_ship_date            IN  DATE,                --   ���
    iv_delivery_no          IN  VARCHAR2,            --   �z��No
    iv_request_no           IN  VARCHAR2,            --   �˗�No
    ov_freight_charge_type  OUT NOCOPY VARCHAR2,     --   �^���`��
    ov_errbuf               OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_freight_charge_type'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_transfer_standard_drink  xxcmn_cust_accounts2_v.drink_transfer_std%TYPE;     -- �h�����N�^���U�֊
    lv_transfer_standard_leaf   xxcmn_cust_accounts2_v.leaf_transfer_std%TYPE;      -- ���[�t�^���U�֊
    lv_party_number             xxcmn_cust_accounts2_v.party_number%TYPE;           -- �g�D�ԍ�
    lv_delivery_no              xxwsh_mixed_carriers_tmp.delivery_no%TYPE;          -- �z��No
    lv_default_line_number      xxwsh_mixed_carriers_tmp.default_line_number%TYPE;  -- �����No
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �������(�z��)�ɂ���ď�����U�蕪����
    IF iv_transaction_type = gv_carrier_trn_type_1 THEN
      -- �o�׈˗�(1)�̏ꍇ
      -- �����ɂ�苁�߂�
      BEGIN
--
        SELECT  xca.drink_transfer_std                               -- �h�����N�^���U�֊
               ,xca.leaf_transfer_std                                -- ���[�t�^���U�֊
               ,xca.party_number                                     -- �g�D�ԍ�
        INTO    lv_transfer_standard_drink
               ,lv_transfer_standard_leaf
               ,lv_party_number
        FROM    xxcmn_cust_accounts2_v    xca                        -- �ڋq���VIEW2
               ,xxwsh_order_headers_all   xoha                       -- �󒍃w�b�_�A�h�I��
        WHERE   xca.party_number          = xoha.head_sales_branch
        AND     xca.start_date_active <= TRUNC(id_ship_date)         -- ���
        AND     (xca.end_date_active IS NULL OR
                 xca.end_date_active  >= TRUNC(id_ship_date))
        AND     xoha.delivery_no          = iv_delivery_no           -- �z��No
        AND     xoha.latest_external_flag = gv_yesno_y
        AND     xca.party_status          = gv_view_status
        AND     xca.account_status        = gv_view_status
        AND     ROWNUM = 1                                           -- ���ڒP��<->�W��No�P�ʂł̏d����r��
        ;
--
      EXCEPTION
        -- �f�[�^�擾���s��
        WHEN OTHERS THEN
          --�擾�l��NULL�ɃZ�b�g
          ov_freight_charge_type     := NULL;    -- �^���`�Ԃ�NULL�ݒ�
          lv_transfer_standard_drink := NULL;    -- �h�����N�^���U�֊
          lv_transfer_standard_leaf  := NULL;    -- ���[�t�^���U�֊
--
      END;
--
      --�擾�ł�����
      IF (iv_prod_kbn_cd = gv_prod_kbn_cd_1 AND lv_transfer_standard_leaf  IS NULL) OR
         (iv_prod_kbn_cd = gv_prod_kbn_cd_2 AND lv_transfer_standard_drink IS NULL) THEN
--
          --�擾�l��NULL�̏ꍇ�A�G���[���b�Z�[�W�o��
          ov_retcode := gv_status_warn;
          ov_freight_charge_type := NULL;                                   -- �^���`�Ԃ�NULL�ݒ�
          ov_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg( gv_msg_kbn        -- 'XXWSH'
                                                         ,gv_msg_93a_147    -- ���b�Z�[�W�FAPP-XXWSH-13147 �^���`�Ԏ擾�x��
                                                         ,gv_param1_token   -- �g�[�N���F�z��No
                                                         ,iv_delivery_no
                                                         ,gv_param2_token   -- �g�[�N���F�����No(�˗�No)
                                                         ,iv_request_no
                                                         ,gv_param3_token   -- �g�[�N���F�ڋq
                                                         ,lv_party_number
                                                          ),1,255);
--
      ELSE
--
        --�^���U�֊�ݒ�
        IF ( iv_prod_kbn_cd = gv_prod_kbn_cd_1 ) THEN
          --���[�t
          ov_freight_charge_type := lv_transfer_standard_leaf;      -- ���[�t�^���U�֊
        ELSE
          --�h�����N
          ov_freight_charge_type := lv_transfer_standard_drink;     -- �h�����N�^���U�֊
        END IF;
--
      END IF;
--
    ELSE
      -- ���̑�(�x���w��(2),�ړ��w��(3))�̏ꍇ
      -- ����U�ւ��Œ�Őݒ肷��
      ov_freight_charge_type := gv_frt_chrg_type_act; -- ����U��
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_freight_charge_type;
--
 /**********************************************************************************
  * Procedure Name   : carriers_schedule_inup
  * Description      : �z�Ԕz���v��A�h�I���쐬 �v���V�[�W��
  ***********************************************************************************/
  PROCEDURE carriers_schedule_inup(
    in_idx        IN  NUMBER,              --   �f�[�^index
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'carriers_schedule_inup'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- �z�Ԕz���v��(�A�h�I��)����
    lv_transaction_type             xxwsh_carriers_schedule.transaction_type%TYPE;             -- �������(�z��)
    lv_mixed_type                   xxwsh_carriers_schedule.mixed_type%TYPE;                   -- ���ڎ��
    lv_delivery_no                  xxwsh_carriers_schedule.delivery_no%TYPE;                  -- �z��No
    lv_default_line_number          xxwsh_carriers_schedule.default_line_number%TYPE;          -- �����No
    ln_carrier_id                   xxwsh_carriers_schedule.carrier_id%TYPE;                   -- �^���Ǝ�ID
    lv_carrier_code                 xxwsh_carriers_schedule.carrier_code%TYPE;                 -- �^���Ǝ�
    lv_deliver_to_code_class        xxwsh_carriers_schedule.deliver_to_code_class%TYPE;        -- �z����R�[�h�敪
    lv_delivery_type                xxwsh_carriers_schedule.delivery_type%TYPE;                -- �z���敪
    lv_auto_process_type            xxwsh_carriers_schedule.auto_process_type%TYPE;            -- �����z�ԑΏۋ敪
    ld_schedule_ship_date           xxwsh_carriers_schedule.schedule_ship_date%TYPE;           -- �o�ɗ\���
    ld_schedule_arrival_date        xxwsh_carriers_schedule.schedule_arrival_date%TYPE;        -- ���ח\���
    lv_payment_freight_flag         xxwsh_carriers_schedule.payment_freight_flag%TYPE;         -- �x���^���v�Z�Ώۃt���O
    lv_demand_freight_flag          xxwsh_carriers_schedule.demand_freight_flag%TYPE;          -- �����^���v�Z�Ώۃt���O
    ln_result_freight_carrier_id    xxwsh_carriers_schedule.result_freight_carrier_id%TYPE;    -- �^���Ǝ�_����ID
    lv_result_freight_carrier_code  xxwsh_carriers_schedule.result_freight_carrier_code%TYPE;  -- �^���Ǝ�_����
    lv_result_shipping_method_code  xxwsh_carriers_schedule.result_shipping_method_code%TYPE;  -- �z���敪_����
    ld_shipped_date                 xxwsh_carriers_schedule.shipped_date%TYPE;                 -- �o�ד�
    ld_arrival_date                 xxwsh_carriers_schedule.arrival_date%TYPE;                 -- ���ד�
    lv_weight_capacity_class        xxwsh_carriers_schedule.weight_capacity_class%TYPE;        -- �d�ʗe�ϋ敪
    lv_prod_kbn_cd                  xxwsh_order_headers_all.prod_class%TYPE;                   -- ���i�敪
    lv_freight_charge_type          xxwsh_carriers_schedule.freight_charge_type%TYPE;          -- �^���`��
    -- �z�Ԕz���v��(�A�h�I��)����
    ln_carriers_schedule_cnt        NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    BEGIN
      -- �����̔z�Ԕz���v��(�A�h�I��)�f�[�^����������
      SELECT  COUNT(1)
      INTO    ln_carriers_schedule_cnt
      FROM    xxwsh_carriers_schedule
      WHERE   delivery_no = gr_interface_info_rec(in_idx).delivery_no
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_carriers_schedule_cnt := 0;
    END;
--
    IF ln_carriers_schedule_cnt < 1 THEN
    -- �z�Ԕz���v��(�A�h�I��)�f�[�^�������ꍇ�A�쐬����
--
      -- �쐬���邽�߂̊e���ڒl�Z�b�g
      -- �������(�z��)
      -- EOS�f�[�^��ʂ�蔻�肷��
      IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210) OR      --210 ���_�o�׊m���
          (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))        --215 ���o�׊m���
      THEN
        -- 210 ���_�o�׊m��� or 215 ���o�׊m���
        -- �o�׈˗�(1)��ݒ肷��
        lv_transaction_type := gv_carrier_trn_type_1;
--
      ELSIF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) OR   --220 �ړ��o�Ɋm���
             (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230))     --230 �ړ����Ɋm���
      THEN
        -- 220 �ړ��o�Ɋm��� or 230 �ړ����Ɋm���
         -- �ړ��w��(3)��ݒ肷��
        lv_transaction_type := gv_carrier_trn_type_3;
      ELSE                                                                           --200 �L���o�ו�
        -- 200 �L���o�ו�
        -- �x���w��(2)��ݒ肷��
        lv_transaction_type := gv_carrier_trn_type_2;
      END IF;
--
      -- ���ڎ��
      -- �W��(1)��ݒ肷��
      lv_mixed_type := gv_mixed_type_1;
--
      -- �z��No
      -- IF�̔z��No��ݒ肷��
      lv_delivery_no := gr_interface_info_rec(in_idx).delivery_no;
--
      -- �����No
      -- IF�̈˗�No(�󒍃\�[�X�Q��)��ݒ肷��
      lv_default_line_number := gr_interface_info_rec(in_idx).order_source_ref;
--
      -- �^���Ǝ�ID
      -- IF�̉^���Ǝ�ID��ݒ肷��
      ln_carrier_id := gr_interface_info_rec(in_idx).career_id;
--
      -- �^���Ǝ�CD
      -- IF�̉^���Ǝ�CD��ݒ肷��
      lv_carrier_code := gr_interface_info_rec(in_idx).freight_carrier_code;
--
      -- �z����R�[�h�敪
      -- IF�z����̌ڋq�敪��ݒ肷��
      lv_deliver_to_code_class := gr_interface_info_rec(in_idx).customer_class_code;
--
      -- �z���敪
      -- IF�̔z���敪��ݒ肷��
      lv_delivery_type := gr_interface_info_rec(in_idx).shipping_method_code;
--
      -- �����z�ԑΏۋ敪
      -- �ΏۊO(0)��ݒ肷��
      lv_auto_process_type := gv_lv_auto_process_type_0;
--
      -- �o�ɗ\���
      -- IF�̏o�ד���ݒ肷��
      ld_schedule_ship_date := gr_interface_info_rec(in_idx).shipped_date;
--
      -- ���ח\���
      -- IF�̒��ד���ݒ肷��
      ld_schedule_arrival_date := gr_interface_info_rec(in_idx).arrival_date;
--
      -- �x���^���v�Z�Ώۃt���O
      --ON(1)��ݒ肷��B
      lv_payment_freight_flag := gv_flg_on;
--
      -- �����^���v�Z�Ώۃt���O
      --ON(1)��ݒ肷��B
      lv_demand_freight_flag := gv_flg_on;
--
      -- �^���Ǝ�_����ID
      -- IF�̉^���Ǝ�ID��ݒ肷��
      ln_result_freight_carrier_id := gr_interface_info_rec(in_idx).result_freight_carrier_id;
--
      -- �^���Ǝ�_����
      -- IF�̉^���Ǝ҂�ݒ肷��
      lv_result_freight_carrier_code := gr_interface_info_rec(in_idx).freight_carrier_code;
--
      -- �z���敪_����
      -- IF�̔z���敪��ݒ肷��
      lv_result_shipping_method_code := gr_interface_info_rec(in_idx).shipping_method_code;
--
      -- �o�ד�
      -- IF�̏o�ד���ݒ肷��
      ld_shipped_date := gr_interface_info_rec(in_idx).shipped_date;
--
      -- ���ד�
      -- IF�̒��ד���ݒ肷��
      ld_arrival_date := gr_interface_info_rec(in_idx).arrival_date;
--
      -- �d�ʗe�ϋ敪
      -- IF�f�[�^����擾�����d�ʗe�ϋ敪��ݒ肷��
      lv_weight_capacity_class := gr_interface_info_rec(in_idx).weight_capacity_class;
      -- ���i�敪
      lv_prod_kbn_cd := gr_interface_info_rec(in_idx).prod_kbn_cd;
--
      -- �^���`��
      -- �֐��ɂ��擾
      get_freight_charge_type( lv_transaction_type      --   �������(�z��)
                              ,lv_prod_kbn_cd           --   ���i�敪
                              ,ld_shipped_date          --   ���(�o�ד�)
                              ,lv_delivery_no           --   �z��No
                              ,lv_default_line_number   --   �����No(�˗�No)
                              ,lv_freight_charge_type   --   �^���`��
                              ,lv_errbuf                --   �G���[�E���b�Z�[�W
                              ,lv_retcode               --   ���^�[���E�R�[�h
                              ,lv_errmsg                --   ���[�U�[�E�G���[�E���b�Z�[�W
                             );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      IF (lv_retcode = gv_status_warn) THEN
        gr_interface_info_rec(in_idx).logonly_flg := gv_flg_on;  -- ���O�̂ݏo��flag
        gr_interface_info_rec(in_idx).message     := lv_errmsg;  -- ���b�Z�[�W(�x��)
        ov_retcode := gv_status_warn;
      END IF;
--
      -- �z�Ԕz���v��A�h�I���ɓo�^����
      INSERT INTO xxwsh_carriers_schedule
      (
         transaction_id                     -- �g�����U�N�V����ID
        ,transaction_type                   -- �������(�z��)
        ,mixed_type                         -- ���ڎ��
        ,delivery_no                        -- �z��No
        ,default_line_number                -- �����No
        ,carrier_id                         -- �^���Ǝ�ID
        ,carrier_code                       -- �^���Ǝ�
        ,deliver_to_code_class              -- �z����R�[�h�敪
        ,delivery_type                      -- �z���敪
        ,auto_process_type                  -- �����z�ԑΏۋ敪
        ,schedule_ship_date                 -- �o�ɗ\���
        ,schedule_arrival_date              -- ���ח\���
        ,payment_freight_flag               -- �x���^���v�Z�Ώۃt���O
        ,demand_freight_flag                -- �����^���v�Z�Ώۃt���O
        ,result_freight_carrier_id          -- �^���Ǝ�_����ID
        ,result_freight_carrier_code        -- �^���Ǝ�_����
        ,result_shipping_method_code        -- �z���敪_����
        ,shipped_date                       -- �o�ד�
        ,arrival_date                       -- ���ד�
        ,weight_capacity_class              -- �d�ʗe�ϋ敪
        ,freight_charge_type                -- �^���`��
        ,created_by                         -- �쐬��
        ,creation_date                      -- �쐬��
        ,last_updated_by                    -- �ŏI�X�V��
        ,last_update_date                   -- �ŏI�X�V��
        ,last_update_login                  -- �ŏI�X�V���O�C��
        ,request_id                         -- �v��ID
        ,program_application_id             -- �A�v���P�[�V����ID
        ,program_id                         -- �R���J�����g�E�v���O����ID
        ,program_update_date                -- �v���O�����X�V��
      )
      VALUES
      (
         xxwsh_careers_schedule_s1.NEXTVAL  -- �g�����U�N�V����ID
        ,lv_transaction_type                -- �������(�z��)
        ,lv_mixed_type                      -- ���ڎ��
        ,lv_delivery_no                     -- �z��No
        ,lv_default_line_number             -- �����No
        ,ln_carrier_id                      -- �^���Ǝ�ID
        ,lv_carrier_code                    -- �^���Ǝ�
        ,lv_deliver_to_code_class           -- �z����R�[�h�敪
        ,lv_delivery_type                   -- �z���敪
        ,lv_auto_process_type               -- �����z�ԑΏۋ敪
        ,ld_schedule_ship_date              -- �o�ɗ\���
        ,ld_schedule_arrival_date           -- ���ח\���
        ,lv_payment_freight_flag            -- �x���^���v�Z�Ώۃt���O
        ,lv_demand_freight_flag             -- �����^���v�Z�Ώۃt���O
        ,ln_result_freight_carrier_id       -- �^���Ǝ�_����ID
        ,lv_result_freight_carrier_code     -- �^���Ǝ�_����
        ,lv_result_shipping_method_code     -- �z���敪_����
        ,ld_shipped_date                    -- �o�ד�
        ,ld_arrival_date                    -- ���ד�
        ,lv_weight_capacity_class           -- �d�ʗe�ϋ敪
        ,lv_freight_charge_type             -- �^���`��
        ,gt_user_id                         -- �쐬��
        ,gt_sysdate                         -- �쐬��
        ,gt_user_id                         -- �ŏI�X�V��
        ,gt_sysdate                         -- �ŏI�X�V��
        ,gt_login_id                        -- �ŏI�X�V���O�C��
        ,gt_conc_request_id                 -- �v��ID
        ,gt_prog_appl_id                    -- �A�v���P�[�V����ID
        ,gt_conc_program_id                 -- �R���J�����g�E�v���O����ID
        ,gt_sysdate                         -- �v���O�����X�V��
      );
--
    ELSE
    -- �z�Ԕz���v��(�A�h�I��)�f�[�^���L��ꍇ�A�X�V����
--
      -- �o�ד�
      -- IF�̏o�ד���ݒ肷��
      ld_shipped_date := gr_interface_info_rec(in_idx).shipped_date;
--
      -- ���ד�
      -- IF�̒��ד���ݒ肷��
      ld_arrival_date := gr_interface_info_rec(in_idx).arrival_date;
--
      -- �^���Ǝ�_����ID
      -- IF�̉^���Ǝ�ID��ݒ肷��
      ln_result_freight_carrier_id := gr_interface_info_rec(in_idx).result_freight_carrier_id;
--
      -- �^���Ǝ�_����
      -- IF�̉^���Ǝ҂�ݒ肷��
      lv_result_freight_carrier_code := gr_interface_info_rec(in_idx).freight_carrier_code;
--
      -- �z���敪_����
      -- IF�̔z���敪��ݒ肷��
      lv_result_shipping_method_code := gr_interface_info_rec(in_idx).shipping_method_code;
--
      -- �z�Ԕz���v��A�h�I���ɓo�^����
      UPDATE xxwsh_carriers_schedule
      SET shipped_date                = ld_shipped_date
         ,arrival_date                = ld_arrival_date
         ,result_freight_carrier_id   = ln_result_freight_carrier_id
         ,result_freight_carrier_code = lv_result_freight_carrier_code
         ,result_shipping_method_code = lv_result_shipping_method_code
         ,last_updated_by             = gt_user_id
         ,last_update_date            = gt_sysdate
         ,last_update_login           = gt_login_id
         ,request_id                  = gt_conc_request_id
         ,program_application_id      = gt_prog_appl_id
         ,program_id                  = gt_conc_program_id
         ,program_update_date         = gt_sysdate
      WHERE   delivery_no = gr_interface_info_rec(in_idx).delivery_no;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END carriers_schedule_inup;
--
 /**********************************************************************************
  * Procedure Name   : mov_table_outpout
  * Description      : �ړ��˗�/�w���A�h�I���o�� �v���V�[�W�� (A-7)
  ***********************************************************************************/
  PROCEDURE mov_table_outpout(
    in_idx        IN  NUMBER,              --   �f�[�^index
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mov_table_outpout'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_data_cnt             NUMBER;                 -- �擾�f�[�^����
--
    lb_line_upd_flg         BOOLEAN := FALSE;       -- ���ב��ݔ���
    lb_lot_upd_flg          BOOLEAN := FALSE;       -- ���b�g���ݔ���t���O
--
    lb_break_flg            BOOLEAN := FALSE;       -- �u���C�N����
    lb_header_warn          BOOLEAN := FALSE;       -- �w�b�_�������[�j���O
--
    ln_cnt_kbn              VARCHAR2(1);     -- �f�[�^�����J�E���g�敪
--
    -- ���ьv��ϋ敪
    lt_actual_confirm_class xxwsh_order_headers_all.actual_confirm_class%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR mov_data_get_cur
      (
       in_delivery_no         xxwsh_shipping_headers_if.delivery_no%TYPE      -- �z��No
      ,in_order_source_ref    xxwsh_shipping_headers_if.order_source_ref%TYPE -- �󒍃\�[�X�Q��
      )
    IS
      SELECT  xmrif.mov_hdr_id                  -- �ړ��w�b�_ID
              ,xmrif.delivery_no                -- �z��no
              ,xmrif.mov_num                    -- �ړ��ԍ�
              ,xmrif.comp_actual_flg            -- ���ьv��σt���O
              ,xmrif.status                     -- �X�e�[�^�X
              ,xmrql.mov_line_id                -- �ړ�����ID
              ,xmrql.item_code                  -- �i��
              ,xmrql.item_id                    -- opm�i��ID
              ,xmld.mov_line_id                 -- ���b�g�ڍׂ̖���ID
              ,xmld.mov_lot_dtl_id              -- ���b�g�ڍ�ID
              ,xmld.document_type_code          -- �����^�C�v
              ,xmld.record_type_code            -- ���R�[�h�^�C�v
              ,xmld.item_id                     -- opm�i��ID
              ,xmld.lot_no                      -- ���b�gNo
      FROM    xxinv_mov_req_instr_headers xmrif    -- �ړ��˗�/�w���w�b�_(�A�h�I��)
            , xxinv_mov_req_instr_lines   xmrql    -- �ړ��˗�/�w������(�A�h�I��)
            , xxinv_mov_lot_details       xmld     -- �ړ����b�g�ڍ�(�A�h�I��)
      WHERE   NVL(xmrif.delivery_no,gv_delivery_no_null) = NVL(in_delivery_no,gv_delivery_no_null) -- �z��No=�z��No
      AND     xmrif.mov_num          = in_order_source_ref  -- �˗�No=�󒍃\�[�X�Q��
      AND     xmrif.mov_hdr_id       = xmrql.mov_hdr_id     -- �ړ��w�b�_�A�h�I��ID=�ړ��w�b�_�A�h�I��ID
      AND     xmrif.status          <> gv_mov_status_99     -- �X�e�[�^�X<>���
      AND     ((xmrql.delete_flg     = gv_yesno_n)          -- �폜�t���O=���폜
       OR      (xmrql.delete_flg IS NULL))
      AND     xmrql.mov_line_id      = xmld.mov_line_id(+)  -- �ړ����׃A�h�I��ID=����ID
      ORDER BY
              xmrif.mov_hdr_id
              ,xmrql.mov_line_id
              ,xmld.mov_lot_dtl_id
    ;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE rec_data IS RECORD
      (
        mov_hdr_id         xxinv_mov_req_instr_headers.mov_hdr_id%TYPE      -- �ړ��w�b�_ID
       ,delivery_no        xxinv_mov_req_instr_headers.delivery_no%TYPE     -- �z��no
       ,mov_num            xxinv_mov_req_instr_headers.mov_num%TYPE         -- �ړ��ԍ�
       ,comp_actual_flg    xxinv_mov_req_instr_headers.comp_actual_flg%TYPE -- ���ьv��σt���O
       ,status             xxinv_mov_req_instr_headers.status%TYPE          -- �X�e�[�^�X
       ,mov_line_id        xxinv_mov_req_instr_lines.mov_line_id%TYPE       -- �ړ�����ID
       ,item_code          xxinv_mov_req_instr_lines.item_code%TYPE         -- �i��
       ,lines_item_code    xxinv_mov_req_instr_lines.item_id%TYPE           -- �ړ�����.opm�i��ID
       ,lot_mov_line_id    xxinv_mov_lot_details.mov_line_id%TYPE           -- ���b�g�ڍׂ̖���ID
       ,mov_lot_dtl_id     xxinv_mov_lot_details.mov_lot_dtl_id%TYPE        -- ���b�g�ڍ�ID
       ,document_type_code xxinv_mov_lot_details.document_type_code%TYPE    -- �����^�C�v
       ,record_type_code   xxinv_mov_lot_details.record_type_code%TYPE      -- ���R�[�h�^�C�v
       ,item_id            xxinv_mov_lot_details.item_id%TYPE               -- opm�i��ID
       ,lot_no             xxinv_mov_lot_details.lot_no%TYPE                -- ���b�gNo
      );
    TYPE tab_data IS TABLE OF rec_data INDEX BY BINARY_INTEGER ;
--
    lr_tab_data              tab_data;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�y�ړ������@�J�n�z�F' || in_idx || '����');
debug_log(FND_FILE.LOG,'�@�@�z��No�F' || gr_interface_info_rec(in_idx).delivery_no);
debug_log(FND_FILE.LOG,'�@�@�ړ�No�F' || gr_interface_info_rec(in_idx).order_source_ref);
--********** debug_log ********** END   ***

--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ����������
    ln_data_cnt := 0;
    -------------------------------------------------------------------------
    -- �z��No�A�˗�No�ɊY������f�[�^���擾
    -------------------------------------------------------------------------
    -- �J�[�\���I�[�v��
    OPEN mov_data_get_cur
      (
        gr_interface_info_rec(in_idx).delivery_no
       ,gr_interface_info_rec(in_idx).order_source_ref
      );
--
    --�t�F�b�`
    FETCH mov_data_get_cur BULK COLLECT INTO lr_tab_data;
--
    ln_data_cnt := mov_data_get_cur%ROWCOUNT;    -- �J�[�\�����R�[�h����
--
    --�N���[�Y
    CLOSE mov_data_get_cur;
--
    -------------------------------------------------------------------------
    -- �擾�f�[�^���A�ړ��˗�/�w���w�b�_(�A�h�I��)�A�ړ��˗�/�w������(�A�h�I��)�A
    -- �ړ����b�g�ڍ�(�A�h�I��)�̓o�^�E�X�V���s��
    --------------------------------------------------------------------------
    IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --�G���[flag�F0(����)
        (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --�ۗ�flag  �F0(����)
    THEN
--
      IF (ln_data_cnt > 0 ) THEN
        -- �擾�f�[�^�����݂���ꍇ
        lb_line_upd_flg    := FALSE;
        lb_lot_upd_flg     := FALSE;
--
        <<order_data_get_loop>>
        FOR i IN 1 .. ln_data_cnt LOOP
          -- ���ьv��ϋ敪�ޔ�
          lt_actual_confirm_class := lr_tab_data(i).comp_actual_flg;
--
--        ******-- ����̕i�ڂ����׃f�[�^�ɑ��݂���ꍇ
--        ******--IF (gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).item_code) THEN
--
            -- �O���q��(�w���Ȃ�)�ȊO�̏ꍇ
          IF (gb_mov_header_flg = FALSE) THEN
--
            --------------------------------------
            -- �ړ��˗�/�w���w�b�_(�A�h�I��)�̍X�V
            --------------------------------------
            -- �w�b�_ID������Ńf�[�^��1���ڂ̏ꍇ(�K���Ǎ��f�[�^1����)
            IF (gb_mov_header_data_flg = FALSE) THEN
--
               -- ���ьv��ϋ敪��'N'�̏ꍇ
              IF (lr_tab_data(i).comp_actual_flg = gv_yesno_n) OR
                 (lr_tab_data(i).comp_actual_flg IS NULL) THEN
--
                 gb_mov_cnt_a7_flg := TRUE;      -- �ړ�(A-7) �����\���Ōv�ォ���������f����̂��߂̃t���O
--
                -- �ړ��˗�/�w���w�b�_�A�h�I��  (A-7-2)���{
                mov_req_instr_head_upd(
                  in_idx,                   -- �f�[�^index
                  lr_tab_data(i).status,    -- �X�e�[�^�X
                  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                 );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w���w�b�_�A�h�I��  (A-7-2)���{�Fmov_req_instr_head_upd');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
--
              ELSE -- ���ьv��ϋ敪��'Y'
--
                  -- �ړ��˗�/�w���w�b�_�A�h�I�� (A-7-3)���{
                mov_req_instr_head_inup(
                  in_idx,                   -- �f�[�^index
                  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w���w�b�_�A�h�I�� (A-7-3)���{�Fmov_req_instr_head_inup');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
--
              END IF;
              gb_mov_header_data_flg := TRUE;  -- �ړ��˗�/�w���w�b�_�������ςɐݒ�
            END IF;
--
          END IF;
          -- �O���q��(�w���Ȃ�)�ȊO�ŁA���w�b�_�o�^�E�X�V����������I���̏ꍇ
          IF ((gb_mov_line_flg = FALSE) AND
             (lb_header_warn = FALSE))
          THEN
            --------------------------------------
            -- �ړ��˗�/�w������(�A�h�I��)�̍X�V
            --------------------------------------
            -- �i�ڂ�����A�����׃f�[�^�������̏ꍇ
            IF ((gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).item_code) AND
                (gb_mov_line_data_flg = FALSE))
            THEN
              -- ���ьv��ϋ敪���A'N'�̏ꍇ
              IF (lr_tab_data(i).comp_actual_flg = gv_yesno_n) OR
                 (lr_tab_data(i).comp_actual_flg IS NULL) THEN
--
                -- �ړ��˗�/�w�����׃A�h�I�� (A-7-5) ���{
                mov_req_instr_lines_upd(
                  in_idx,                     -- �f�[�^index
                  lr_tab_data(i).mov_line_id,  --�ړ�����ID
                  gv_cnt_kbn_1,               -- �f�[�^�����J�E���g�敪
                  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�i�ځF' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w�����׃A�h�I�� (A-7-5) ���{�Fmov_req_instr_lines_upd');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
                lb_line_upd_flg  := TRUE; --�ړ��˗�/�w�����ׂ����݂ɐݒ�
                gb_mov_line_data_flg := TRUE; --�ړ��˗�/�w�����ׂ������ςɐݒ�
--
              ELSIF  (lt_actual_confirm_class = gv_yesno_y) THEN
--
                -- �ړ��˗�/�w�����׃A�h�I�� (A-7-5) ���{
                mov_req_instr_lines_upd(
                  in_idx,                 -- �f�[�^index
                  lr_tab_data(i).mov_line_id,  --�ړ�����ID
                  gv_cnt_kbn_6,             -- �f�[�^�����J�E���g�敪
                  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�i�ځF' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w�����׃A�h�I�� (A-7-5) ���{�Fmov_req_instr_lines_upd');
--********** debug_log ********** END   ***
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
                lb_line_upd_flg  := TRUE; --�ړ��˗�/�w�����ׂ����݂ɐݒ�
                gb_mov_line_data_flg := TRUE; --�ړ��˗�/�w�����׃f�[�^��������
              END IF;
--
            END IF;
--
          END IF;
--
          --------------------------------------
          -- �ړ����b�g�ڍ�(�A�h�I��)�̍X�V
          --------------------------------------
          -- �w�b�_�o�^�E�X�V����������I���̏ꍇ
--********** 2008/06/27 ********** MODIFY START ***
--*         IF  (lt_actual_confirm_class = gv_yesno_y) AND
--*             (lb_header_warn = FALSE) THEN
          IF  (lb_header_warn = FALSE) THEN
--********** 2008/06/27 ********** MODIFY END   ***
--
            -- EOS�f�[�^��ʂ��A220:�ړ����Ɋm��񍐂̏ꍇ
            IF  (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_220) THEN
              -- �������b�g�����݂���ꍇ
              IF (((gr_interface_info_rec(in_idx).lot_no = lr_tab_data(i).lot_no) OR
                  (gr_interface_info_rec(in_idx).lot_no IS NULL)) AND
                  (gr_interface_info_rec(in_idx).item_id = lr_tab_data(i).item_id) AND
                  (lr_tab_data(i).document_type_code = gv_document_type_20) AND
                  (lr_tab_data(i).record_type_code = gv_record_type_20))
              THEN
--
--********** 2008/06/27 ********** DELETE START ***
--*             -- ���b�g�Ǘ��i�݈̂ړ����b�g�ڍ�UPDATE�������s��
--*             IF  (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1) 
--*             THEN
--********** 2008/06/27 ********** DELETE END   ***
--
                  -- �ړ����b�g�ڍ�UPDATE �v���V�[�W�� (A-7-7) ���{
                  movlot_detail_upd(
                    in_idx,                         -- �f�[�^index
                    lr_tab_data(i).mov_lot_dtl_id,  --���b�g�ڍ�ID
                    lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
--********** 2008/07/07 ********** DELETE START ***
--*--ZANTEI 2008/06/27 ADD START
--*                  IF (lt_actual_confirm_class <> gv_yesno_y) THEN
--*--
--*                    --���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����) ���Z
--*                    gn_mov_mov_upd_y_cnt := gn_mov_mov_upd_y_cnt - 1;
--*--
--*                    --���b�g�ڍאV�K�쐬����(�ړ��˗�_���ьv��) ���Z
--*                    gn_mov_mov_ins_n_cnt := gn_mov_mov_ins_n_cnt + 1;
--*                  END IF;
--*--ZANTEI 2008/06/27 ADD END
--********** 2008/07/07 ********** DELETE END   ***
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�ړ����b�g�ڍ�UPDATE �v���V�[�W�� (A-7-7) ���{�Fmovlot_detail_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
--********** 2008/06/27 ********** DELETE START ***
--*             END IF;
--********** 2008/06/27 ********** DELETE END   ***
--
                lb_lot_upd_flg := TRUE; --���b�g�f�[�^�������ςɐݒ�(���b�g�Ǘ��i�O�ł��A�������b�g�����݂���̂ōςɐݒ�)
--
              END IF;
            -- EOS�f�[�^��ʂ��A230:�ړ����Ɋm��񍐂̏ꍇ
            ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_230) THEN
              -- �������b�g�����݂���ꍇ
              IF (((gr_interface_info_rec(in_idx).lot_no = lr_tab_data(i).lot_no) OR
                  (gr_interface_info_rec(in_idx).lot_no IS NULL)) AND
                  (gr_interface_info_rec(in_idx).item_id = lr_tab_data(i).item_id) AND
                  (lr_tab_data(i).document_type_code = gv_document_type_20) AND
                  (lr_tab_data(i).record_type_code = gv_record_type_30))
              THEN
--
--********** 2008/06/27 ********** DELETE START ***
--*             -- ���b�g�Ǘ��i�݈̂ړ����b�g�ڍ�UPDATE�������s��
--*             IF  (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1) 
--*             THEN
--********** 2008/06/27 ********** DELETE END   ***
--
                  -- �ړ����b�g�ڍ�UPDATE �v���V�[�W�� (A-7-7) ���{
                  movlot_detail_upd(
                    in_idx,                         -- �f�[�^index
                    lr_tab_data(i).mov_lot_dtl_id,  -- ���b�g�ڍ�ID
                    lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
--********** 2008/07/07 ********** DELETE START ***
--*--ZANTEI 2008/06/27 ADD START
--*                  IF (lt_actual_confirm_class <> gv_yesno_y) THEN
--*--
--*                    --���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����) ���Z
--*                    gn_mov_mov_upd_y_cnt := gn_mov_mov_upd_y_cnt - 1;
--*--
--*                    --���b�g�ڍאV�K�쐬����(�ړ��˗�_���ьv��) ���Z
--*                    gn_mov_mov_ins_n_cnt := gn_mov_mov_ins_n_cnt + 1;
--*                  END IF;
--*--ZANTEI 2008/06/27 ADD END
--********** 2008/07/07 ********** DELETE END   ***
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�ړ����b�g�ڍ�UPDATE �v���V�[�W�� (A-7-7) ���{�Fmovlot_detail_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--

--********** 2008/06/27 ********** DELETE START ***
--*             END IF;
--********** 2008/06/27 ********** DELETE END   ***
--
                lb_lot_upd_flg := TRUE; --���b�g�f�[�^�������ςɐݒ�(���b�g�Ǘ��i�O�ł��A�������b�g�����݂���̂ōςɐݒ�)
--
              END IF;
--
            END IF;
--
          END IF;
--
        END LOOP order_data_get_loop;
--
        --------------------------------------
        -- �ړ��˗�/�w������(�A�h�I��)�̓o�^
        --------------------------------------
        -- �w�b�_�͑��݂��邪�A���׃f�[�^���݂��Ȃ��A���w�b�_�o�^�E�X�V����������I���̏ꍇ
        IF ((gb_mov_line_flg = FALSE)     AND
           (lb_line_upd_flg = FALSE)      AND
           (gb_mov_line_data_flg = FALSE) AND
           (lb_header_warn = FALSE))
        THEN
          -- �f�[�^�敪�̔���
          IF (gb_mov_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3; -- �O���q��(�w���Ȃ�)
          ELSE
            IF (gb_mov_cnt_a7_flg = TRUE) THEN
               ln_cnt_kbn := gv_cnt_kbn_2; -- ���ьv��̎w���i�ځ����ѕi��
            ELSE
               ln_cnt_kbn := gv_cnt_kbn_7; -- �������i�ڂȂ�
            END IF;
          END IF;
--
          -- �ړ��˗�/�w�����׃A�h�I�� (A-7-4)���{ (INSERT)
          mov_req_instr_lines_ins(
            in_idx,                   -- �f�[�^index
            ln_cnt_kbn,               -- �f�[�^�����J�E���g�敪
            lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�i�ځF' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w�����׃A�h�I�� (A-7-4)���{ (INSERT)�Fmov_req_instr_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          gb_mov_line_flg  := TRUE;
          gb_mov_line_data_flg := TRUE;
        END IF;
--
        --------------------------------------
        -- �ړ����b�g�ڍ�(�A�h�I��)�̓o�^
        --------------------------------------
        -- �w�b�_�o�^�E�X�V����������I���̏ꍇ
        IF ((lb_lot_upd_flg = FALSE) AND (lb_header_warn = FALSE)) THEN
--
           -- �f�[�^�敪�̔�����s��
          IF (gb_mov_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3;  -- �O���q��(�w���Ȃ�)
          ELSE
            IF (gb_mov_cnt_a7_flg = TRUE) THEN
               ln_cnt_kbn := gv_cnt_kbn_5;  -- ���ьv��
            ELSE
               ln_cnt_kbn := gv_cnt_kbn_9;  -- �������b�g�Ȃ�
            END IF;
          END IF;
--
          -- �ړ��˗�/�w���f�[�^�ړ����b�g�ڍ� (A-7-6)���{(INSERT)
          mov_movlot_detail_ins(
            in_idx,                   -- �f�[�^index
            ln_cnt_kbn,               -- �f�[�^�����J�E���g�敪
            lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w���f�[�^�ړ����b�g�ڍ� (A-7-6)���{(INSERT)�Fmov_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- �z�Ԕz���v��A�h�I���쐬
            carriers_schedule_inup(
              in_idx,                   -- �f�[�^index
              lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�z�Ԕz���v��A�h�I���쐬�Fcarriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
        END IF;
--
      ELSE  --�f�[�^�����݂��Ȃ��ꍇ
        --------------------------------------
        -- �ړ��˗�/�w���w�b�_(�A�h�I��)�̓o�^
        --------------------------------------
--
        -- �ړ��˗�/�w���w�b�_�A�h�I��(�O���q�ɕҏW) (A-7-1)���{(INSERT)
        mov_req_instr_head_ins(
          in_idx,                   -- �f�[�^index
          lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w���w�b�_�A�h�I��(�O���q�ɕҏW) (A-7-1)���{(INSERT)�Fmov_req_instr_head_ins');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �w�b�_�o�^�E�X�V����������I���̏ꍇ
        IF (lb_header_warn = FALSE) THEN
          --------------------------------------
          -- �ړ��˗�/�w������(�A�h�I��)�̓o�^
          --------------------------------------
          ln_cnt_kbn := gv_cnt_kbn_3; -- �f�[�^�敪�ݒ�F�O���q��(�w���Ȃ�)
--
          -- �ړ��˗�/�w�����׃A�h�I�� (A-7-4)���{(INSERT)
          mov_req_instr_lines_ins(
            in_idx,                   -- �f�[�^index
            ln_cnt_kbn,               -- �f�[�^�����J�E���g�敪
            lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�i�ځF' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w�����׃A�h�I�� (A-7-4)���{(INSERT)�Fmov_req_instr_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          --------------------------------------
          -- �ړ����b�g�ڍ�(�A�h�I��)�̓o�^
          --------------------------------------
--
          -- �ړ��˗�/�w���f�[�^�ړ����b�g�ڍ� (A-7-6)���{(INSERT)
          ln_cnt_kbn := gv_cnt_kbn_3;  -- �f�[�^�敪�ݒ�F�O���q��(�w���Ȃ�)
          mov_movlot_detail_ins(
            in_idx,                   -- �f�[�^index
            ln_cnt_kbn,               -- �f�[�^�����J�E���g�敪
            lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�ړ��˗�/�w���f�[�^�ړ����b�g�ڍ� (A-7-6)���{(INSERT)�Fmov_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- �z�Ԕz���v��A�h�I���쐬
            carriers_schedule_inup(
              in_idx,                   -- �f�[�^index
              lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�z�Ԕz���v��A�h�I���쐬�Fcarriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
          gb_mov_header_flg  := TRUE;
          gb_mov_line_flg    := TRUE;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -------------------------------------------------------------------------
    -- ���גP�ʂ̏���
    -- �ŏI�f�[�^����
    -- �O��̔z��No�ƑO��̎󒍃\�[�X�Q�ƂƑO���EOS�f�[�^��ʂ��قȂ�ꍇ(�w�b�_�u���C�N)����
    -- �O��̔z��No�ƑO��̎󒍃\�[�X�Q�ƂƑO���EOS�f�[�^��ʂ�����ŕi�ڂ����Ⴗ��ꍇ
    --------------------------------------------------------------------------
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
          (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref) OR
          (gr_interface_info_rec(in_idx).eos_data_type <> gr_interface_info_rec(in_idx + 1).eos_data_type))
      OR
         ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) AND
          (gr_interface_info_rec(in_idx).order_source_ref = gr_interface_info_rec(in_idx + 1).order_source_ref) AND
          (gr_interface_info_rec(in_idx).eos_data_type = gr_interface_info_rec(in_idx + 1).eos_data_type) AND
          (gr_interface_info_rec(in_idx).orderd_item_code <> gr_interface_info_rec(in_idx + 1).orderd_item_code))
      THEN
--
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF ((lb_break_flg = TRUE) AND (lv_retcode = gv_status_normal)) THEN
      -- �o�Ɏ��ѐ��ʂ̐ݒ���s���B
      -- ���b�g�Ǘ��敪 = 1:�L(���b�g�Ǘ��i)
      IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1) THEN
--
        -- ===============================
        -- �o�׈˗����ѐ��ʂ̐ݒ� �v���V�[�W��
        -- ===============================
        mov_results_quantity_set(
          in_idx,                 -- �f�[�^index
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�o�׈˗����ѐ��ʂ̐ݒ� �v���V�[�W���Fmov_results_quantity_set');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- ��������ϐ���������
      gb_mov_line_data_flg := FALSE; -- ���׏����ϔ���
      lb_line_upd_flg      := FALSE; -- ���ב��ݔ���
      lb_lot_upd_flg       := FALSE; -- ���b�g�����ϔ��蔻��
--
      gb_mov_line_flg      := FALSE; -- �O���q��(�w���Ȃ�)���� ���חp
--
      lb_break_flg := FALSE;
--
    END IF;
    -------------------------------------------------------------------------
    -- �w�b�_�P�ʂ̏���
    -- �O��̔z��No�ƑO��̎󒍃\�[�X�Q�ƂƑO���EOS�f�[�^��ʂ��قȂ�ꍇ(�w�b�_�u���C�N)���� ����1���ڈȊO�̏ꍇ
    --------------------------------------------------------------------------
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
--
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
          (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref) OR
          (gr_interface_info_rec(in_idx).eos_data_type <> gr_interface_info_rec(in_idx + 1).eos_data_type))
      THEN
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF ((lb_break_flg = TRUE) AND (lv_retcode = gv_status_normal)) THEN
--
      IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --�G���[flag�F0(����)
          (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --�ۗ�flag  �F0(����)
      THEN
--
        -- �d�ʗe�Ϗ������X�V�֐������{
        -- ===============================
        -- �d�ʗe�Ϗ������ݒ� �v���V�[�W��
        -- ===============================
        upd_line_items_set(
          in_idx,                   -- �f�[�^index
          lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- �߂�l = �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ��������ϐ���������
      gb_mov_header_data_flg   := FALSE; -- �w�b�_�����ϔ���
      gb_mov_line_data_flg     := FALSE; -- ���׏����ϔ���
      lb_line_upd_flg          := FALSE; -- ���ב��ݔ���
      lb_lot_upd_flg           := FALSE; -- ���b�g�����ϔ��蔻��
      gb_mov_header_flg        := FALSE; -- �O���q��(�w���Ȃ�)���� �w�b�_�p
      gb_mov_line_flg          := FALSE; -- �O���q��(�w���Ȃ�)���� ���חp
      gb_mov_cnt_a7_flg        := FALSE; -- �ړ�(A-7) �����\���Ōv�ォ���������f����̂��߂̃t���O
      lb_break_flg             := FALSE;
      gb_mov_cnt_a7_flg        := FALSE; -- �ړ�(A-7) �����\���Ōv�ォ���������f����̂��߂̃t���O
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( mov_data_get_cur%ISOPEN ) THEN
        CLOSE mov_data_get_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( mov_data_get_cur%ISOPEN ) THEN
        CLOSE mov_data_get_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( mov_data_get_cur%ISOPEN ) THEN
        CLOSE mov_data_get_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END mov_table_outpout;
--
--
 /**********************************************************************************
  * Procedure Name   : order_table_outpout
  * Description      : �󒍃A�h�I���o�� �v���V�[�W�� (A-8)
  ***********************************************************************************/
  PROCEDURE order_table_outpout(
    in_idx        IN  NUMBER,              --   �f�[�^index
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_table_outpout'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- *** ���[�J���ϐ� ***
    ln_data_cnt             NUMBER;                 -- �擾�f�[�^����
--
    lb_line_upd_flg         BOOLEAN := FALSE;       -- ���ב��ݔ���p
    lb_lot_upd_flg          BOOLEAN := FALSE;       -- ���b�g���ݔ���t���O
--
    lb_break_flg            BOOLEAN := FALSE;       -- �u���C�N����
    lb_header_warn          BOOLEAN := FALSE;       -- �w�b�_�������[�j���O
--
    lv_document_type_code   VARCHAR2(2);            -- �h�L�������g�^�C�v
--
    ln_cnt_kbn              VARCHAR2(1);   -- �f�[�^�����J�E���g�敪
--
    -- ���ьv��ϋ敪
    lt_actual_confirm_class xxwsh_order_headers_all.actual_confirm_class%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR order_data_get_cur
      (
       in_delivery_no         xxwsh_shipping_headers_if.delivery_no%TYPE      -- �z��No
      ,in_order_source_ref    xxwsh_shipping_headers_if.order_source_ref%TYPE -- �󒍃\�[�X�Q��
      )
    IS
      SELECT  xoha.order_header_id              -- �󒍃w�b�_�A�h�I��ID
              ,xoha.delivery_no                 -- �z��no
              ,xoha.actual_confirm_class        -- ���ьv��σt���O
              ,xola.order_line_id               -- �󒍖��׃A�h�I��ID
              ,xola.shipping_item_code          -- �o�וi��
              ,xmld.mov_lot_dtl_id              -- ���b�g�ڍ�ID
              ,xmld.document_type_code          -- �����^�C�v
              ,xmld.record_type_code            -- ���R�[�h�^�C�v
              ,xmld.item_id                     -- opm�i��ID
              ,xmld.lot_no                      -- ���b�gNo
      FROM    xxwsh_order_headers_all   xoha    -- �󒍃w�b�_(�A�h�I��)
            , xxwsh_order_lines_all     xola    -- �󒍖���(�A�h�I��)
            , xxinv_mov_lot_details     xmld    -- �ړ����b�g�ڍ�(�A�h�I��)
      WHERE   NVL(xoha.delivery_no,gv_delivery_no_null) = NVL(in_delivery_no,gv_delivery_no_null)
      AND     xoha.request_no           = in_order_source_ref
      AND     xoha.order_header_id      = xola.order_header_id
      AND     xoha.latest_external_flag = gv_yesno_y
      AND     ((xola.delete_flag        = gv_yesno_n) OR (xola.delete_flag IS NULL))
      AND     xola.order_line_id        = xmld.mov_line_id(+)
      ORDER BY xoha.order_header_id
              ,xola.order_line_id
              ,xmld.mov_lot_dtl_id
    ;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE rec_data IS RECORD
      (
        order_header_id       xxwsh_order_headers_all.order_header_id%TYPE       -- �󒍃w�b�_�A�h�I��ID
       ,delivery_no           xxwsh_order_headers_all.delivery_no%TYPE           -- �z��no
       ,actual_confirm_class  xxwsh_order_headers_all.actual_confirm_class%TYPE  -- ���ьv��σt���O
       ,order_line_id         xxwsh_order_lines_all.order_line_id%TYPE           -- �󒍖��׃A�h�I��ID
       ,shipping_item_code    xxwsh_order_lines_all.shipping_item_code%TYPE      -- �o�וi��
       ,mov_lot_dtl_id        xxinv_mov_lot_details.mov_lot_dtl_id%TYPE          -- ���b�g�ڍ�ID
       ,document_type_code    xxinv_mov_lot_details.document_type_code%TYPE      -- �����^�C�v
       ,record_type_code      xxinv_mov_lot_details.record_type_code%TYPE        -- ���R�[�h�^�C�v
       ,item_id               xxinv_mov_lot_details.item_id%TYPE                 -- opm�i��ID
       ,lot_no                xxinv_mov_lot_details.lot_no%TYPE                  -- ���b�gNo
      );
--
    TYPE tab_data IS TABLE OF rec_data INDEX BY BINARY_INTEGER ;
--
    lr_tab_data               tab_data;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�y�󒍏����@�J�n�z�F' || in_idx || '����');
debug_log(FND_FILE.LOG,'�@�@�z��No�F' || gr_interface_info_rec(in_idx).delivery_no);
debug_log(FND_FILE.LOG,'�@�@�˗�No�F' || gr_interface_info_rec(in_idx).order_source_ref);
--********** debug_log ********** END   ***
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_data_cnt := 0;
    -------------------------------------------------------------------------
    -- �z��No�A�˗�No�ɊY������f�[�^���擾
    -------------------------------------------------------------------------
    -- �J�[�\���I�[�v��
    OPEN order_data_get_cur
      (
        gr_interface_info_rec(in_idx).delivery_no
       ,gr_interface_info_rec(in_idx).order_source_ref
      );
--
    --�t�F�b�`
    FETCH order_data_get_cur BULK COLLECT INTO lr_tab_data;
--
    --�N���[�Y
    ln_data_cnt := order_data_get_cur%ROWCOUNT;    -- �J�[�\�����R�[�h����
--
    CLOSE order_data_get_cur;
--
    -------------------------------------------------------------------------
    -- �擾�f�[�^���A�󒍃w�b�_(�A�h�I��)�A�󒍖���(�A�h�I��)�A�ړ����b�g�ڍ�(�A�h�I��)��
    -- �o�^�E�X�V���s��
    --------------------------------------------------------------------------
    IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --�G���[flag�F0(����)
        (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --�ۗ�flag  �F0(����)
    THEN
--
      IF (ln_data_cnt > 0 ) THEN
        -- �擾�f�[�^�����݂���ꍇ
        lb_line_upd_flg    := FALSE;
        lb_lot_upd_flg     := FALSE;
--
        <<order_data_get_loop>>
        FOR i IN 1 .. ln_data_cnt LOOP
          -- ���ьv��ϋ敪�ޔ�
          lt_actual_confirm_class := lr_tab_data(i).actual_confirm_class;
--
--        *****-- ����̕i�ڂ��󒍖��׃f�[�^�ɑ��݂���ꍇ
--        *****  IF (gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).shipping_item_code) THEN
--
            -- �O���q��(�w���Ȃ�)�ȊO�̏ꍇ
            IF (gb_ord_header_flg = FALSE) THEN
--
              --------------------------------------
              -- �󒍃w�b�_(�A�h�I��)�̍X�V
              --------------------------------------
              -- �w�b�_ID������Ńf�[�^��1���ڂ̏ꍇ(�K���Ǎ��f�[�^1����)
              IF (gb_ord_header_data_flg = FALSE) THEN
--
                 -- ���ьv��ϋ敪��'N' ���� NULL�̏ꍇ
                IF  ((lr_tab_data(i).actual_confirm_class = gv_yesno_n) OR
                     (lr_tab_data(i).actual_confirm_class IS NULL))
                THEN
--
                  -- ��(A-8-6) �����\���Ōv�ォ���������f����̂��߂̃t���O
                  gb_ord_cnt_a8_flg := TRUE;
--
                  -- �󒍃w�b�_�A�h�I�� ���ьv�� (A-8-1)���{ (UPDATE)
                  order_headers_upd(
                    in_idx,                   -- �f�[�^index
                    lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                   );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�󒍃w�b�_�A�h�I�� ���ьv�� (A-8-1)���{ (UPDATE)�Forder_headers_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  gb_ord_header_data_flg := TRUE;  -- �󒍃w�b�_�f�[�^�������ςɐݒ�
                ELSE -- ���ьv��ϋ敪��'Y'
--
                  -- �󒍃w�b�_�A�h�I�� ���ђ��� (A-8-3,4)���{
                  order_headers_inup(
                    in_idx,                   -- �f�[�^index
                    lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�󒍃w�b�_�A�h�I�� ���ђ��� (A-8-3,4)���{�Forder_headers_inup');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_warn) THEN
                    lb_header_warn := TRUE;
                    RAISE global_api_expt;
                  END IF;
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  gb_ord_header_data_flg := TRUE;  -- �󒍃w�b�_�������ςɐݒ�
                END IF;
--
              END IF;
--
            END IF;
--
            -- �O���q��(�w���Ȃ�)�ȊO�ŁA���w�b�_�o�^�E�X�V����������I���̏ꍇ
            IF ((gb_ord_line_flg = FALSE) AND
                (lb_header_warn = FALSE))
            THEN
--
              --------------------------------------
              -- �󒍖���(�A�h�I��)�̍X�V
              --------------------------------------
              -- �i�ڂ�����A�����׃f�[�^�������̏ꍇ
              IF ((gr_interface_info_rec(in_idx).orderd_item_code = lr_tab_data(i).shipping_item_code) AND
                  (gb_ord_line_data_flg = FALSE))
              THEN
                 -- ���ьv��ϋ敪��'N' ���� NULL�̏ꍇ
                IF  ((lr_tab_data(i).actual_confirm_class = gv_yesno_n) OR
                     (lr_tab_data(i).actual_confirm_class IS NULL))
                THEN
--
                  -- �󒍖��׃A�h�I�� �w���i�ځ����ѕi�� (A-8-5)���{(UPDATE)
                  order_lines_upd(
                    in_idx,                       -- �f�[�^index
                    lr_tab_data(i).order_line_id, -- �󒍖��׃A�h�I��ID
                    lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�i�ځF' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'�@�@�@�󒍖��׃A�h�I�� �w���i�ځ����ѕi�� (A-8-5)���{(UPDATE)�Forder_lines_upd');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  lb_line_upd_flg  := TRUE; --�󒍖��ׂ����݂ɐݒ�
                  gb_ord_line_data_flg := TRUE; --�󒍖��ׂ������ςɐݒ�
--
                END IF;
--
--              *****END IF;
--
            END IF;
--
--********** 2008/06/27 ********** ADD    START ***
            --------------------------------------
            -- �ړ����b�g�ڍ�(�A�h�I��)�̍X�V
            --------------------------------------
            -- �w�b�_�o�^�E�X�V����������I���̏ꍇ
            IF  (lb_header_warn = FALSE) THEN
--
                -- ���ьv��ϋ敪��'N' ���� NULL�̏ꍇ
              IF  ((lr_tab_data(i).actual_confirm_class = gv_yesno_n) OR
                   (lr_tab_data(i).actual_confirm_class IS NULL))
              THEN
--
                --�����^�C�v��ݒ�
                -- EOS�f�[�^��� = ���_�o�׊m��� ���� ���o�׊m��񍐂̏ꍇ
                lv_document_type_code := NULL;
--
                IF ((gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_210)  OR
                    (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_215))
                THEN
--
                  lv_document_type_code := gv_document_type_10; --�o�׈˗�
--
                --  EOS�f�[�^��� = 200 �L���o�ו�
                ELSIF (gr_interface_info_rec(in_idx).eos_data_type = gv_eos_data_cd_200) THEN
--
                  lv_document_type_code := gv_document_type_30; --�x���w��
--
                END IF;
--
                -- �������b�g�����݂���ꍇ
                IF (((gr_interface_info_rec(in_idx).lot_no = lr_tab_data(i).lot_no) OR
                    (gr_interface_info_rec(in_idx).lot_no IS NULL)) AND
                    (gr_interface_info_rec(in_idx).item_id = lr_tab_data(i).item_id) AND
                    (lr_tab_data(i).document_type_code = lv_document_type_code) AND
                    (lr_tab_data(i).record_type_code = gv_record_type_20))
                THEN
--
                  -- �󒍃f�[�^�ړ����b�g�ڍ�UPDATE �v���V�[�W�� (A-8-8) ���{
                  order_movlot_detail_up(
                    in_idx,                         -- �f�[�^index
                    lr_tab_data(i).mov_lot_dtl_id,  -- ���b�g�ڍ�ID
                    lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
                    lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
                    lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                  );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�󒍃f�[�^�ړ����b�g�ڍ�UPDATE �v���V�[�W�� (A-8-8) ���{�Forder_movlot_detail_up');
--********** debug_log ********** END   ***
--
                  IF (lv_retcode = gv_status_error) THEN
                    RAISE global_api_expt;
                  END IF;
--
                  lb_lot_upd_flg := TRUE; --���b�g�f�[�^�������ςɐݒ�(���b�g�Ǘ��i�O�ł��A�������b�g�����݂���̂ōςɐݒ�)
--
                END IF;
--
              END IF;
--
            END IF;
--********** 2008/06/27 ********** ADD    END   ***
--
          END IF;
--
        END LOOP order_data_get_loop;
--
        --------------------------------------
        -- �󒍖���(�A�h�I��)�̓o�^
        --------------------------------------
        -- �w�b�_�͑��݂��邪�A���׃f�[�^���݂��Ȃ��A���w�b�_�o�^�E�X�V����������I���̏ꍇ
        IF ((gb_ord_line_flg = FALSE)      AND
            (lb_line_upd_flg = FALSE)      AND
            (gb_ord_line_data_flg = FALSE) AND
            (lb_header_warn = FALSE))
        THEN
--
          -- �f�[�^�敪�̔���
          IF (gb_ord_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3; -- �O���q��(�w���Ȃ�)
          ELSE
            IF (gb_ord_cnt_a8_flg = TRUE) THEN
              ln_cnt_kbn := gv_cnt_kbn_2; -- ���ьv��̎w���i�ځ����ѕi��
            ELSE
              ln_cnt_kbn := gv_cnt_kbn_4; -- ���яC��
            END IF;
          END IF;
--
          -- �󒍖��׃A�h�I�� �w���i�ځ����ѕi�� (A-8-6)���{ (INSERT)
          order_lines_ins(
            in_idx,                                   -- �f�[�^index
            ln_cnt_kbn,                               -- �f�[�^�����J�E���g�敪
            lv_errbuf,                                -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,                               -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg                                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�i�ځF' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'�@�@�@�󒍖��׃A�h�I�� �w���i�ځ����ѕi�� (A-8-6)���{ (INSERT)�Forder_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          gb_ord_line_flg := TRUE;
          gb_ord_line_data_flg := TRUE;
        END IF;
--
        --------------------------------------
        -- �ړ����b�g�ڍ�(�A�h�I��)�̓o�^
        --------------------------------------
        -- �w�b�_�o�^�E�X�V����������I���̏ꍇ
        IF ((lb_lot_upd_flg = FALSE) AND (lb_header_warn = FALSE)) THEN
--
          -- �f�[�^�敪�̔���
          IF (gb_ord_header_flg = TRUE)  THEN
             ln_cnt_kbn := gv_cnt_kbn_3; -- �O���q��(�w���Ȃ�)
          ELSE
            IF (gb_ord_cnt_a8_flg = TRUE) THEN
              ln_cnt_kbn := gv_cnt_kbn_5; -- ���ьv��
            ELSE
              ln_cnt_kbn := gv_cnt_kbn_4; -- ���яC��
            END IF;
          END IF;
--
          -- �󒍃f�[�^�ړ����b�g�ڍ� (A-8-7)���{(INSERT)
          order_movlot_detail_ins(
            in_idx,                 -- �f�[�^index
            ln_cnt_kbn,             -- �f�[�^�����J�E���g�敪
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�󒍃f�[�^�ړ����b�g�ڍ� (A-8-7)���{(INSERT)�Forder_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- �z�Ԕz���v��A�h�I���쐬
            carriers_schedule_inup(
              in_idx,                   -- �f�[�^index
              lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�z�Ԕz���v��A�h�I���쐬�Fcarriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
        END IF;
--
      ELSE  --�f�[�^�����݂��Ȃ��ꍇ
--
        --------------------------------------
        -- �󒍃w�b�_(�A�h�I��)�̓o�^
        --------------------------------------
        -- �󒍃w�b�_�A�h�I�� �O���q��(�w���Ȃ�) (A-8-2)���{(INSERT)
        order_headers_ins(
          in_idx,                   -- �f�[�^index
          lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�󒍃w�b�_�A�h�I�� �O���q��(�w���Ȃ�) (A-8-2)���{(INSERT)�Forder_headers_ins');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �w�b�_�o�^�E�X�V����������I���̏ꍇ
        IF (lb_header_warn = FALSE) THEN
          --------------------------------------
          -- �󒍖��׃A�h�I��(�A�h�I��)�̓o�^
          --------------------------------------
          ln_cnt_kbn := gv_cnt_kbn_3; -- �f�[�^�敪�ݒ�F�O���q��(�w���Ȃ�)
--
          -- �󒍖��׃A�h�I�� ���яC�� (A-8-6)���{(INSERT)
          order_lines_ins(
            in_idx,                   -- �f�[�^index
            ln_cnt_kbn,               -- �f�[�^�����J�E���g�敪
            lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�i�ځF' || gr_interface_info_rec(in_idx).orderd_item_code);
debug_log(FND_FILE.LOG,'�@�@�@�󒍖��׃A�h�I�� ���яC�� (A-8-6)���{(INSERT)�Forder_lines_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          --------------------------------------
          -- �ړ����b�g�ڍ�(�A�h�I��)�̓o�^
          --------------------------------------
          -- ���ьv��ϋ敪�ɂăf�[�^�敪�̔���
          ln_cnt_kbn := gv_cnt_kbn_3; -- �O���q��(�w���Ȃ�)
--
          -- �󒍃f�[�^�ړ����b�g�ڍ� (A-8-7)���{(INSERT)
          order_movlot_detail_ins(
            in_idx,                   -- �f�[�^index
            ln_cnt_kbn,               -- �f�[�^�����J�E���g�敪
            lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�󒍃f�[�^�ړ����b�g�ڍ� (A-8-7)���{(INSERT)�Forder_movlot_detail_ins');
--********** debug_log ********** END   ***
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          IF gr_interface_info_rec(in_idx).freight_charge_class = gv_include_exclude_1 THEN
--
            -- �z�Ԕz���v��A�h�I���쐬
            carriers_schedule_inup(
              in_idx,                   -- �f�[�^index
              lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�z�Ԕz���v��A�h�I���쐬�Fcarriers_schedule_inup');
--********** debug_log ********** END   ***
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            IF (lv_retcode = gv_status_warn) THEN
              ov_retcode := gv_status_warn;
            END IF;
--
          END IF;
--
          gb_ord_header_flg  := TRUE;
          gb_ord_line_flg    := TRUE;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -------------------------------------------------------------------------
    -- ���גP�ʂ̏���(�����R�[�h�Ɣ�r)
    -- �ŏI�f�[�^����
    -- �z��No�Ǝ󒍃\�[�X�Q�Ƃ��قȂ�ꍇ(�w�b�_�u���C�N)����
    -- �z��No�Ǝ󒍃\�[�X�Q�Ƃ�����Ŏ󒍕i�ڂ����Ⴗ��ꍇ
    --------------------------------------------------------------------------
--
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
          (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref))
      OR
         ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) = NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) AND
          (gr_interface_info_rec(in_idx).order_source_ref = gr_interface_info_rec(in_idx + 1).order_source_ref) AND
          (gr_interface_info_rec(in_idx).orderd_item_code <> gr_interface_info_rec(in_idx + 1).orderd_item_code))
      THEN
--
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- �o�Ɏ��ѐ��ʂ̐ݒ���s���B
      -- ���b�g�Ǘ��敪 = 1:�L(���b�g�Ǘ��i)
      IF (gr_interface_info_rec(in_idx).lot_ctl = gv_lotkr_kbn_cd_1)  THEN
--
        -- ===============================
        -- �󒍎��ѐ��ʂ̐ݒ� �v���V�[�W��
        -- ===============================
        ord_results_quantity_set(
          in_idx,                 -- �f�[�^index
          lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
--********** debug_log ********** START ***
debug_log(FND_FILE.LOG,'�@�@�@�󒍎��ѐ��ʂ̐ݒ� �v���V�[�W���Ford_results_quantity_set');
--********** debug_log ********** END   ***
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- ��������ϐ���������
      gb_ord_line_data_flg     := FALSE; -- ���׏����ϔ���
      lb_line_upd_flg      := FALSE; -- ���ב��ݔ���
      lb_lot_upd_flg       := FALSE; -- ���b�g�����ϔ��蔻��
--
      gb_ord_line_flg      := FALSE; -- ��(A-8) �O���q��(�w���Ȃ�)���� ���חp
--
      lb_break_flg         := FALSE;
--
    END IF;
    -------------------------------------------------------------------------
    -- �w�b�_�P�ʂ̏���(�����R�[�h�Ɣ�r)
    -- �ŏI�f�[�^����
    -- �z��No�Ǝ󒍃\�[�X�Q�Ƃ��قȂ�ꍇ(�w�b�_�u���C�N)
    --------------------------------------------------------------------------
    IF (in_idx = gn_target_cnt) THEN
        lb_break_flg := TRUE;
--
    ELSE
--
      IF ((NVL(gr_interface_info_rec(in_idx).delivery_no,gv_delivery_no_null) <> NVL(gr_interface_info_rec(in_idx + 1).delivery_no,gv_delivery_no_null)) OR
         (gr_interface_info_rec(in_idx).order_source_ref <> gr_interface_info_rec(in_idx + 1).order_source_ref))
      THEN
        lb_break_flg := TRUE;
--
      END IF;
--
    END IF;
--
    IF ((lb_break_flg = TRUE) AND (lv_retcode = gv_status_normal)) THEN
--
      IF ((gr_interface_info_rec(in_idx).err_flg = gv_flg_off) AND         --�G���[flag�F0(����)
          (gr_interface_info_rec(in_idx).reserve_flg = gv_flg_off))        --�ۗ�flag  �F0(����)
      THEN
--
        -- �d�ʗe�Ϗ������X�V�֐������{
        -- ===============================
        -- �d�ʗe�Ϗ������ݒ� �v���V�[�W��
        -- ===============================
        upd_line_items_set(
          in_idx,                   -- �f�[�^index
          lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END IF;
--
    IF (lb_break_flg = TRUE) THEN
      -- �߂�l = �G���[�̏ꍇ
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ��������ϐ���������
      gb_ord_header_data_flg   := FALSE; -- �w�b�_�����ϔ���
      gb_ord_line_data_flg     := FALSE; -- ���׏����ϔ���
      lb_line_upd_flg      := FALSE; -- ���ב��ݔ���
      lb_lot_upd_flg       := FALSE; -- ���b�g�����ϔ��蔻��
      gb_ord_header_flg    := FALSE; -- �O���q��(�w���Ȃ�)���� �w�b�_�p
      gb_ord_line_flg      := FALSE; -- �O���q��(�w���Ȃ�)���� ���חp
      lb_break_flg         := FALSE;
      gb_ord_cnt_a8_flg    := FALSE;      -- ��(A-8) �����\���Ōv�ォ���������f����̂��߂̃t���O
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( order_data_get_cur%ISOPEN ) THEN
        CLOSE order_data_get_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( order_data_get_cur%ISOPEN ) THEN
        CLOSE order_data_get_cur;
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END order_table_outpout;
--
 /**********************************************************************************
  * Procedure Name   : origin_record_delete
  * Description      : ���o�����R�[�h�폜 �v���V�[�W�� (A-11)
  ***********************************************************************************/
  PROCEDURE origin_record_delete(
    in_idx        IN  NUMBER,              --   �f�[�^index
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'origin_record_delete'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���탌�R�[�h�ɑ΂��ďo�׈˗�IF�w�b�_�y�і��ׂ���Ώۃf�[�^�̍폜���s��
--
    -- IF���׍폜����
    DELETE FROM xxwsh_shipping_lines_if   xsli
     WHERE xsli.line_id = gr_interface_info_rec(in_idx).line_id;
--
    -- �R�Â�IF���׃f�[�^�����݂��Ȃ��ꍇ�AIF�w�b�_�̍폜���s���B
--
    -- IF�w�b�_�폜����
--
    -- IF���ב��݃`�F�b�N���s���B
    SELECT COUNT(xsli.line_id) cnt
    INTO   ln_count
    FROM   xxwsh_shipping_lines_if   xsli
    WHERE  xsli.header_id = gr_interface_info_rec(in_idx).header_id
    ;
    -- ���݂��Ȃ��ꍇ�́A�R�Â�IF�w�b�_�̍폜���s���B
    IF (ln_count = 0) THEN
--
      DELETE FROM xxwsh_shipping_headers_if xshi   --IF_H
      WHERE xshi.header_id = gr_interface_info_rec(in_idx).header_id;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END origin_record_delete;
--
 /**********************************************************************************
  * Procedure Name   : lot_reversal_prevention_check
  * Description      : ���b�g�t�]�h�~�`�F�b�N �v���V�[�W�� (A-9)
  ***********************************************************************************/
  PROCEDURE lot_reversal_prevention_check(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lot_reversal_prevention_check'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_party_site_id        NUMBER;                                          --�p�[�e�B�T�C�gID
    lv_error_flg            VARCHAR2(1);                                     --�G���[flag
    lv_reserve_flg          VARCHAR2(1);                                     --�ۗ�flag
    lt_delivery_no          xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.�z��No
    lt_order_source_ref     xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.�󒍃\�[�X�Q��
    ln_inventory_location_id  mtl_item_locations.inventory_location_id%TYPE;
    iv_lot_biz_class        VARCHAR2(1);
    iv_item_no              xxcmn_item_mst_v.item_no%TYPE;
    iv_lot_no               ic_lots_mst.lot_no%TYPE;
    iv_move_to_id           xxcmn_party_sites2_v.party_site_id%TYPE;
    in_move_to_code         NUMBER;
    id_arrival_date         DATE;
    id_standard_date        DATE;
    on_result               NUMBER;
    on_reversal_date        DATE;
    lv_msg_buff             VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���b�g�t�]�h�~�`�F�b�N
    <<lot_reversal_prevention_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lv_error_flg        := gr_interface_info_rec(i).err_flg;                  --�G���[�t���O
      lv_reserve_flg      := gr_interface_info_rec(i).reserve_flg;              --�ۗ��t���O
      lt_delivery_no      := gr_interface_info_rec(i).delivery_no;              --�z��No
      lt_order_source_ref := gr_interface_info_rec(i).order_source_ref;         --�󒍃\�[�X�Q��
--
      IF (lv_error_flg = '0') AND (lv_reserve_flg = '0') THEN
--
        -- ���b�g�Ǘ��i�ŁAEOS�f�[�^��ʂ��u�L���o�ו񍐁v�ȊO�̂��̂�ΏۂƂ���
        IF ((gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_1) AND
            (gr_interface_info_rec(i).item_kbn_cd = gv_item_kbn_cd_5) AND
            (gr_interface_info_rec(i).eos_data_type <> gv_eos_data_cd_200))
        THEN
--
          IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR
              (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))
          THEN
--
            -- �o�ׂ̎��ьv�㎞�̃`�F�b�N
            iv_lot_biz_class := gv_lot_biz_class_2;        -- 1.���b�g�t�]�������
            ln_party_site_id := gr_interface_info_rec(i).deliver_to_id;
            iv_move_to_id    := ln_party_site_id;          -- 4.�z����ID/�����T�C�gID/���ɐ�ID
            in_move_to_code  := gr_interface_info_rec(i).party_site_code;
--
          ELSIF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220)  OR
                (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))
          THEN
--
            -- �ړ��̎��ьv�㎞�̃`�F�b�N
            iv_lot_biz_class := gv_lot_biz_class_6;        -- 1.���b�g�t�]�������
--
            IF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220) THEN
--
              SELECT xilv2.inventory_location_id
              INTO   ln_inventory_location_id
              FROM   xxcmn_item_locations2_v xilv2
              WHERE  xilv2.segment1 = gr_interface_info_rec(i).ship_to_location
                AND  xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).shipped_date) -- �g�D�L���J�n��
                AND  ((xilv2.date_to IS NULL)
                 OR  (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).shipped_date)))  -- �g�D�L���I����
                AND  xilv2.disable_date  IS NULL   -- ������
                  ;
--
            ELSIF (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230) THEN
--
              SELECT xilv2.inventory_location_id
              INTO   ln_inventory_location_id
              FROM   xxcmn_item_locations2_v xilv2
              WHERE  xilv2.segment1 = gr_interface_info_rec(i).ship_to_location
                AND  xilv2.date_from  <=  TRUNC(gr_interface_info_rec(i).arrival_date) -- �g�D�L���J�n��
                AND  ((xilv2.date_to IS NULL)
                 OR  (xilv2.date_to >= TRUNC(gr_interface_info_rec(i).arrival_date)))  -- �g�D�L���I����
                AND  xilv2.disable_date  IS NULL   -- ������
                  ;
--
            END IF;
--
            iv_move_to_id    := ln_inventory_location_id;     -- 4.�z����ID/�����T�C�gID/���ɐ�ID
            in_move_to_code  := gr_interface_info_rec(i).ship_to_location;
--
          END IF;
--
          iv_item_no        := gr_interface_info_rec(i).orderd_item_code; -- 2.�i�ڃR�[�h
          iv_lot_no         := gr_interface_info_rec(i).lot_no;           -- 3.���b�gNo
          id_arrival_date   := gr_interface_info_rec(i).arrival_date;     -- 5.����
          id_standard_date  := SYSDATE;                                   -- 6.���(�K�p�����)
--
          xxwsh_common910_pkg.check_lot_reversal(iv_lot_biz_class,        -- 1.���b�g�t�]�������
                                                 iv_item_no,              -- 2.�i�ڃR�[�h
                                                 iv_lot_no,               -- 3.���b�gNo
                                                 iv_move_to_id,           -- 4.�z����ID/�����T�C�gID/���ɐ�ID
                                                 id_arrival_date,         -- 5.����
                                                 id_standard_date,        -- 6.���(�K�p�����)
                                                 ov_retcode,              -- 7.���^�[���R�[�h
                                                 lv_retcode,              -- 8.�G���[���b�Z�[�W�R�[�h
                                                 lv_errbuf,               -- 9.�G���[���b�Z�[�W
                                                 on_result,               -- 10.��������
                                                 on_reversal_date);       -- 11.�t�]���t
--
          IF (ov_retcode = 1) THEN
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                gv_msg_kbn              -- 'XXWSH'
                               ,gv_msg_93a_027          -- ���b�g�t�]�h�~�`�F�b�N�����G���[���b�Z�[�W
                               ,gv_err_code_token
                               ,lv_retcode              -- �G���[���b�Z�[�W�R�[�h
                               ,gv_err_msg_token
                               ,lv_errbuf               -- �G���[���b�Z�[�W
                               )
                               ,1
                               ,5000);
--
            -- �z��No/�˗�No-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_header_unit_reserveflg(
              lt_delivery_no,                     -- �z��No
              lt_order_source_ref,                -- �ړ�No/�˗�No
              gr_interface_info_rec(i).eos_data_type, -- EOS�f�[�^���
              gv_logonly_class,                   -- �G���[��ʁF���O�̂ݏo��
              lv_msg_buff,                        -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,                          -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,                         -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
          IF ((ov_retcode = 0) AND (on_result = 1)) THEN
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                                gv_msg_kbn              -- 'XXWSH'
                               ,gv_msg_93a_026          -- ���b�g�t�]�h�~�`�F�b�N�G���[���b�Z�[�W
                               ,gv_param1_token
                               ,iv_lot_biz_class
                               ,gv_param2_token
                               ,iv_item_no
                               ,gv_param3_token
                               ,iv_lot_no
                               ,gv_param4_token
                               ,in_move_to_code
                               ,gv_param5_token
                               ,gr_interface_info_rec(i).delivery_no
                               ,gv_param6_token
                               ,gr_interface_info_rec(i).order_source_ref
                               )
                               ,1
                               ,5000);
--
            -- �z��NO-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_header_unit_reserveflg(
              lt_delivery_no,                     -- �z��No
              lt_order_source_ref,                -- �ړ�No/�˗�No
              gr_interface_info_rec(i).eos_data_type, -- EOS�f�[�^���
              gv_logonly_class,                   -- �G���[��ʁF���O�̂ݏo��
              lv_msg_buff,                        -- �G���[�E���b�Z�[�W(�o�͗p)
              lv_errbuf,                          -- �G���[�E���b�Z�[�W           --# �Œ� #
              lv_retcode,                         -- ���^�[���E�R�[�h             --# �Œ� #
              lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
--
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP lot_reversal_prevention_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lot_reversal_prevention_check;
--
 /**********************************************************************************
  * Procedure Name   : drawing_enable_check
  * Description      : �����\�`�F�b�N �v���V�[�W�� (A-10)
  ***********************************************************************************/
  PROCEDURE drawing_enable_check(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'drawing_enable_check'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    lt_inventory_location_id     xxcmn_item_locations_v.inventory_location_id%TYPE; --OPM�ۊǑq��ID
    ln_act_date_hikiate          NUMBER;     -- �L�����x�[�X�����\��
    ln_act_total_hikiate         NUMBER;     -- �������\��
    ln_act_hikiate               NUMBER;     -- �����\��
    ln_shiped_quantity           NUMBER;     -- �o�׎��ѐ�
    lv_msg_buff                  VARCHAR2(5000);
--
    lv_error_flg                 VARCHAR2(1);                                     --�G���[flag
    lv_reserve_flg               VARCHAR2(1);                                     --�ۗ�flag
    lt_delivery_no               xxwsh_shipping_headers_if.delivery_no%TYPE;      --IF_H.�z��No
    lt_order_source_ref          xxwsh_shipping_headers_if.order_source_ref%TYPE; --IF_H.�󒍃\�[�X�Q��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ϐ�������
    ln_act_date_hikiate      := 0;    -- �L�����x�[�X�����\��
    ln_act_total_hikiate     := 0;    -- �������\��
    ln_act_hikiate           := 0;    -- �����\��
    ln_shiped_quantity       := 0;    -- �o�׎��ѐ�
--
     <<status_update_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      lv_error_flg        := gr_interface_info_rec(i).err_flg;                  --�G���[�t���O
      lv_reserve_flg      := gr_interface_info_rec(i).reserve_flg;              --�ۗ��t���O
      lt_delivery_no      := gr_interface_info_rec(i).delivery_no;              --�z��No
      lt_order_source_ref := gr_interface_info_rec(i).order_source_ref;         --�󒍃\�[�X�Q��
--
      IF (lv_error_flg = '0') AND (lv_reserve_flg = '0') THEN
--
        -- EOS�f�[�^��� <> 230:�ړ����Ɋm���
        IF (gr_interface_info_rec(i).eos_data_type <> gv_eos_data_cd_230)
        THEN
--
          --���ʊ֐��F�L�����x�[�X�����\���Z�oAPI
          ln_act_date_hikiate := xxcmn_common_pkg.get_can_enc_in_time_qty(
                                 gr_interface_info_rec(i).shipped_locat  -- OPM�ۊǑq��ID
                               , gr_interface_info_rec(i).item_id        -- OPM�i��ID
                               , gr_interface_info_rec(i).lot_id         -- ���b�gID
                               , gd_sysdate );                           -- �L����
--
          -- �������\���擾--
          -- ���ʊ֐��F�������\���Z�oAPI
          ln_act_total_hikiate := xxcmn_common_pkg.get_can_enc_total_qty(
                                  gr_interface_info_rec(i).shipped_locat  -- OPM�ۊǑq��ID
                                , gr_interface_info_rec(i).item_id        -- OPM�i��ID
                                , gr_interface_info_rec(i).lot_id);       -- ���b�gID
--
          -- �������\���ƗL�����x�[�X�����\���̂�����������������\���Ƃ���
          ln_act_hikiate := LEAST( ln_act_date_hikiate, ln_act_total_hikiate );
--
          -- �����\���Ɣ�r����o�׎��ѐ��ʂ��Z�o
          -- ���b�g�Ǘ��敪�̔���
          IF (gr_interface_info_rec(i).lot_ctl = gv_lotkr_kbn_cd_0)
          THEN
            --���b�g�Ǘ��O�̏ꍇ�A�o�׎��ѐ��ʂ��g�p
            ln_shiped_quantity := gr_interface_info_rec(i).shiped_quantity;
          ELSE
            --���b�g�Ǘ��̏ꍇ�A���󐔗ʂ��g�p
            ln_shiped_quantity := gr_interface_info_rec(i).detailed_quantity;
          END IF;
--
          -- �����\�� < �o�׎��ѐ��ʂ̏ꍇ�A�x���Ƃ��āA�X�e�[�^�X��ۗ��ɂ���B
          IF (ln_act_hikiate < ln_shiped_quantity) THEN
--
            -- �x�����b�Z�[�W�o��
            lv_msg_buff := SUBSTRB( xxcmn_common_pkg.get_msg(
                           gv_msg_kbn          -- 'XXWSH'
                          ,gv_msg_93a_028                         -- �����\�`�F�b�N�G���[���b�Z�[�W
                          ,gv_param1_token
                          ,lt_delivery_no                             -- �z��No
                          ,gv_param2_token
                          ,lt_order_source_ref                        -- �󒍃\�[�X�Q��
                          ,gv_param3_token
                          ,gr_interface_info_rec(i).item_no           -- �i��
                          ,gv_param4_token
                          ,gr_interface_info_rec(i).lot_no            -- ���b�gNo
                          ,gv_param5_token
                          ,gr_interface_info_rec(i).location_code     -- �o�׌�
                          ,gv_param6_token
                          ,ln_act_hikiate                             -- �����\��
                          ,gv_param7_token
                          ,ln_shiped_quantity                         -- �o�׎��ѐ���
                          )
                          ,1
                          ,5000);
--
            -- �X�e�[�^�X��ۗ�
            --�z��No/�˗�No-EOS�f�[�^��ʒP�ʂɃG���[flag�Z�b�g
            set_header_unit_reserveflg(
                                       lt_delivery_no,       -- �z��No
                                       lt_order_source_ref,  -- �ړ�No/�˗�No
                                       gr_interface_info_rec(i).eos_data_type, -- EOS�f�[�^���
                                       gv_logonly_class,     -- �G���[��ʁF���O�̂ݏo��
                                       lv_msg_buff,        -- �G���[�E���b�Z�[�W(�o�͗p)
                                       lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
                                       lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
                                       lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                        );
--
            -- �����X�e�[�^�X�F�x��
            ov_retcode := gv_status_warn;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP status_update_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END drawing_enable_check;
--
 /**********************************************************************************
  * Procedure Name   : status_update
  * Description      :�X�e�[�^�X�X�V �v���V�[�W�� (A-12)
  ***********************************************************************************/
  PROCEDURE status_update(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'status_update'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt  NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
     <<status_update_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      -- �Ó����`�F�b�N�̌��ʁA�󒍃\�[�X�Q�ƂɕR�Â��ۗ��X�e�[�^�X�̌�������������
      -- �e�ۗ����x���ɉ�����PL/SQL�\�̍X�V���s���܂��B
      IF (gr_interface_info_rec(i).reserve_flg = gv_flg_on) THEN
        ln_cnt := ln_cnt + 1;
        gr_line_id_upd(ln_cnt)           := gr_interface_info_rec(i).line_id;     -- ����ID
        gr_reserv_sts(ln_cnt)            := gv_reserved_status;   --�ۗ��X�e�[�^�X = 1:�ۗ�
      END IF;
--
    END LOOP status_update_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END status_update;
--
 /**********************************************************************************
  * Procedure Name   : err_check_delete
  * Description      : �G���[�������x���ɂ�背�R�[�h�폜�v���V�[�W�� (A-13)
  ***********************************************************************************/
  PROCEDURE err_check_delete(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_check_delete'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_head_cnt  NUMBER := 0;
    ln_line_cnt  NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<err_check_delete_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      -- �Ó����`�F�b�N�̌��ʁA�󒍃\�[�X�Q�ƂɕR�Â��ۗ��X�e�[�^�X�̌�������������
      -- �e�ۗ����x���ɉ�����PL/SQL�\�̍X�V���s���܂��B
      IF (gr_interface_info_rec(i).err_flg = gv_flg_on) THEN
--
        IF (i < gr_interface_info_rec.COUNT) THEN
--
          IF (gr_interface_info_rec(i).header_id <> gr_interface_info_rec(i+1).header_id) THEN
            ln_head_cnt := ln_head_cnt + 1;
            gr_header_id_del(ln_head_cnt) := gr_interface_info_rec(i).header_id;
          END IF;
--
        ELSE
          ln_head_cnt := ln_head_cnt + 1;
          gr_header_id_del(ln_head_cnt) := gr_interface_info_rec(i).header_id;
        END IF;
--
        ln_line_cnt := ln_line_cnt + 1;
        gr_line_id_del(ln_line_cnt) := gr_interface_info_rec(i).line_id;
      END IF;
--
    END LOOP err_check_delete_loop;
--
  EXCEPTION
--
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END err_check_delete;
--
 /**********************************************************************************
  * Procedure Name   : err_output
  * Description      : �G���[���e�o�̓v���V�[�W�� (A-14)
  ***********************************************************************************/
  PROCEDURE err_output(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'err_output'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_dspbuf     VARCHAR2(5000);     -- �f�[�^�E�_���v
    lv_dspmsg     VARCHAR2(5000);     -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    <<disp_report_loop>>
    FOR i IN 1..gr_interface_info_rec.COUNT LOOP
--
      IF (gr_interface_info_rec(i).err_flg     = gv_flg_on)
      OR (gr_interface_info_rec(i).reserve_flg = gv_flg_on)
      OR (gr_interface_info_rec(i).logonly_flg = gv_flg_on) THEN
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
        lv_dspbuf := '';
        lv_dspbuf := gr_interface_info_rec(i).party_site_code                         || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).freight_carrier_code       || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).shipping_method_code       || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).cust_po_number             || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).order_source_ref           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).delivery_no                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).collected_pallet_qty       || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).location_code              || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).arrival_time_from          || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).arrival_time_to            || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).eos_data_type              || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).ship_to_location           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).shipped_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).arrival_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).order_type                 || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).used_pallet_qty            || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).report_post_code           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).header_id                  || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).line_id                    || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).line_number                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).orderd_item_code           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).shiped_quantity            || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).ship_to_quantity           || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).lot_no                     || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).designated_production_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || TO_CHAR(gr_interface_info_rec(i).use_by_date,'YYYY/MM/DD') || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).original_character         || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).detailed_quantity          || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).item_kbn_cd                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).prod_kbn_cd                || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).weight_capacity_class      || gv_msg_pnt;
        lv_dspbuf := lv_dspbuf || gr_interface_info_rec(i).lot_ctl;
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        lv_dspmsg := gr_interface_info_rec(i).message;
--
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspmsg);
--
      END IF;
--
    END LOOP disp_report_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END err_output;
--
 /**********************************************************************************
  * Procedure Name   : ins_upd_del_processing
  * Description      : �o�^�X�V�폜�����v���V�[�W�� (A-15)
  ***********************************************************************************/
  PROCEDURE ins_upd_del_processing(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_del_processing'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    In_not_cnt          NUMBER;                            -- IF�w�b�_�폜�f�[�^�i�[�p�J�E���g
    ln_count            NUMBER;                            -- IF���ב��݃f�[�^�����i�[
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ϐ��̏�����
    In_not_cnt  := 0;                          -- IF�w�b�_�폜�f�[�^�i�[�p�J�E���g
    gr_line_not_header.delete;
--
    -- ========================================
    -- �o��IF�e�[�u��(�A�h�I��)  �X�e�[�^�X�X�V
    -- ========================================
--
    <<upd_sli_lot_loop>>
    FORALL i IN 1 .. gr_line_id_upd.COUNT
      UPDATE
        xxwsh_shipping_lines_if    xsli     -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)
      SET
         xsli.reserved_status        = gr_reserv_sts(i)              -- �ۗ��X�e�[�^�X
        ,xsli.last_updated_by        = gt_user_id                    -- �ŏI�X�V��
        ,xsli.last_update_date       = gt_sysdate                    -- �ŏI�X�V��
        ,xsli.last_update_login      = gt_login_id                   -- �ŏI�X�V���O�C��
        ,xsli.request_id             = gt_conc_request_id            -- �v��ID
        ,xsli.program_application_id = gt_prog_appl_id               -- �A�v���P�[�V����ID
        ,xsli.program_id             = gt_conc_program_id            -- �R���J�����g�E�v���O����ID
        ,xsli.program_update_date    = gt_sysdate                    -- �v���O�����X�V��
      WHERE
         xsli.line_id                = gr_line_id_upd(i);            -- ����ID
--
    -- �����ړ��쐬�����̃Z�b�g
    gn_warn_cnt := gr_line_id_upd.COUNT;
--
    -- ==============================================
    -- �o��IF�e�[�u��(�A�h�I��)  �G���[�����f�[�^�폜
    -- ==============================================
--
     -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)
    <<if_l_data_delete_loop>>
    FORALL i IN 1 .. gr_line_id_del.COUNT
--
      DELETE FROM xxwsh_shipping_lines_if   xsli
      WHERE xsli.line_id = gr_line_id_del(i);
--
    gn_del_errdata_cnt := gn_del_errdata_cnt + gr_line_id_del.COUNT;  -- �폜�������Z
--
     -- IF�w�b�_ID�ɕR�Â�IF���׃f�[�^�����݂��邩�ۂ��̊m�F���s���B
     -- ���݂��Ȃ��ꍇ�A�폜�ΏۂƂ���B
    <<if_ifm_not_loop>>
    FOR i IN 1 .. gr_header_id_del.COUNT LOOP
--
      -- IF���ב��݃`�F�b�N���s���B
      SELECT COUNT(xsli.line_id) cnt
      INTO   ln_count
      FROM   xxwsh_shipping_lines_if   xsli
      WHERE  xsli.header_id =  gr_header_id_del(i)
      ;
      -- ���݂��Ȃ��ꍇ�́AIF�w�b�_���폜�Ώۂ��A�폜�f�[�^�i�[�̈�Ɋi�[����B
      IF (ln_count = 0) THEN
        In_not_cnt :=In_not_cnt + 1;
        gr_line_not_header(In_not_cnt) := gr_header_id_del(i);
      END IF;
--
    END LOOP if_ifm_not_loop;
--
     -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�f�[�^�폜
    <<if_h_data_delete_loop>>
    FORALL i IN 1 .. gr_line_not_header.COUNT
--
      DELETE FROM xxwsh_shipping_headers_if xshi  --IF_H
      WHERE xshi.header_id = gr_line_not_header(i);
--
--********** 2008/07/07 ********** DELETE START ***
--* gn_del_errdata_cnt := gn_del_errdata_cnt + gr_line_not_header.COUNT;  -- �폜�������Z
--********** 2008/07/07 ********** DELETE END   ***
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_upd_del_processing;
--
 /**********************************************************************************
  * Procedure Name   : ship_results_regist_process
  * Description      : �o�׎��ѓo�^�����v���V�[�W�� (A-16)
  ***********************************************************************************/
  PROCEDURE ship_results_regist_process(
    iv_object_warehouse     IN  VARCHAR2,            -- �Ώۑq��
    ov_errbuf               OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ship_results_regist_process'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_pkg_name             CONSTANT VARCHAR2(20) := 'xxwsh420001c' ;   -- �p�b�P�[�W��
--
    -- *** ���[�J���ϐ� ***
    ln_req_id               NUMBER ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �o�׈˗��o�׎��э쐬�����̌Ăяo�����s���B
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                  application       => gv_msg_kbn           -- �A�v���P�[�V�����Z�k��
                 ,program           => cv_pkg_name          -- �v���O������
                 ,argument1         => NULL                 -- �p�����[�^�O�P(�u���b�N)
                 ,argument2         => iv_object_warehouse  -- �p�����[�^�O�Q(�o�׌�)
                 ,argument3         => NULL                 -- �p�����[�^�O�R(�˗�No)
                 );
--
    -- �G���[�̏ꍇ
    IF (ln_req_id = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                gv_msg_kbn,               -- 'XXWSH'
                    gv_msg_93a_029,           -- �o�׎��ѓo�^�����G���[���b�Z�[�W
                    gv_param1_token,          -- �g�[�N��'PARAM1'
                    NULL,                     -- �p�����[�^(�u���b�N)
                    gv_param2_token,          -- �g�[�N��'PARAM2'
                    iv_object_warehouse,      -- �p�����[�^(�o�׌�)
                    gv_param3_token,          -- �g�[�N��'PARAM3'
                    NULL);                    -- �p�����[�^(�˗���)
--
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
--
    END IF ;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ship_results_regist_process;
--
 /**********************************************************************************
  * Procedure Name   : move_results_regist_process
  * Description      : ���o�Ɏ��ѓo�^�����v���V�[�W�� (A-17)
  ***********************************************************************************/
  PROCEDURE move_results_regist_process(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'move_results_regist_process'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_pkg_name             CONSTANT VARCHAR2(20)  := 'xxinv570001c' ;   -- �p�b�P�[�W��
    cv_appl_name            CONSTANT VARCHAR2(100) := 'XXINV';           -- �A�v���P�[�V�����Z�k��
--
    -- *** ���[�J���ϐ� ***
    ln_req_id               NUMBER ;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ړ����o�Ɏ��ѓo�^�����̌Ăяo�����s���B
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                  application       => cv_appl_name         -- �A�v���P�[�V�����Z�k��
                 ,program           => cv_pkg_name          -- �v���O������
                 ,argument1         => NULL                 -- �p�����[�^�O�P(�ړ��ԍ�)
                 ) ;
--
    -- �G���[�̏ꍇ
    IF (ln_req_id = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
	                gv_msg_kbn,               -- 'XXINV'
                    gv_msg_93a_030,           -- ���o�Ɏ��ѓo�^�����G���[���b�Z�[�W
                    gv_param1_token,          -- �g�[�N��'PARAM1'
                    NULL
                    );                        -- �p�����[�^(�˗���)
--
      lv_errbuf := lv_errmsg;
--
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END move_results_regist_process;
--
 /**********************************************************************************
  * Procedure Name   : submain
  * Description      : ���C�������v���V�[�W��
  **********************************************************************************/
  PROCEDURE submain(
    iv_process_object_info  IN  VARCHAR2,            -- �����Ώۏ��
    iv_report_post          IN  VARCHAR2,            -- �񍐕���
    iv_object_warehouse     IN  VARCHAR2,            -- �Ώۑq��
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    in_idx                  NUMBER;          -- �f�[�^index
    lv_warn_flg             VARCHAR2(1);     -- �x�����ʃt���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������
    -- ===============================
--
    lv_warn_flg := gv_status_normal;
--
    -- �J�n���̃V�X�e�����ݓ��t����
    gd_sysdate := SYSDATE;
--
    -- WHO�J�����̐ݒ�
    gt_user_id          := FND_GLOBAL.USER_ID;         -- �쐬��(�ŏI�X�V��)
    gt_sysdate          := gd_sysdate;                 -- �쐬��(�ŏI�X�V��)
    gt_login_id         := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �A�v���P�[�V����ID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    -- �O���[�o���ϐ��̏�����
    gn_purge_period := 0;              -- �v���t�@�C���p�[�W��������
    -- ���������̏�����
    gn_target_cnt             := 0;              -- ���͌���
--
--********** 2008/07/07 ********** ADD    START ***
    -- �V�K�p�̃J�E���g
    gn_ord_new_shikyu_cnt     := 0;              -- �V�K�󒍁i�x���j�쐬����
    gn_ord_new_syukka_cnt     := 0;              -- �V�K�󒍁i�o�ׁj�쐬����
    gn_mov_new_cnt            := 0;              -- �V�K�ړ��쐬����
    -- �����p�̃J�E���g
    gn_ord_correct_shikyu_cnt := 0;              -- �����󒍁i�x���j�쐬����
    gn_ord_correct_syukka_cnt := 0;              -- �����󒍁i�o�ׁj�쐬����
    gn_mov_correct_cnt        := 0;              -- �����ړ��쐬����
--********** 2008/07/07 ********** ADD    END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--* -- �󒍃w�b�_
--* gn_ord_h_upd_n_cnt        := 0;              -- �󒍃w�b�_�X�V�쐬����(���ьv��)
--* gn_ord_h_ins_cnt          := 0;              -- �󒍃w�b�_�o�^�쐬����(�O���q�ɔ���)
--* gn_ord_h_upd_y_cnt        := 0;              -- �󒍃w�b�_�X�V�쐬����(���ђ���)
--* -- �󒍖���
--* gn_ord_l_upd_n_cnt        := 0;              -- �󒍖��׍X�V�쐬����(���ьv��i�ڂ���)
--* gn_ord_l_ins_n_cnt        := 0;              -- �󒍖��דo�^�쐬����(���ьv��i�ڂȂ�)
--* gn_ord_l_ins_cnt          := 0;              -- �󒍖��דo�^�쐬����(�O���q�ɔ���)
--* gn_ord_l_ins_y_cnt        := 0;              -- �󒍖��דo�^�쐬����(���яC��)
--* -- ���b�g�ڍ�
--* gn_ord_mov_ins_n_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(��_���ьv��)
--* gn_ord_mov_ins_cnt        := 0;              -- ���b�g�ڍאV�K�쐬����(��_�O���q�ɔ���)
--* gn_ord_mov_ins_y_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(��_���яC��)
--* -- �ړ��˗�/�w���w�b�_
--* gn_mov_h_ins_cnt          := 0;              -- �ړ��˗�/�w���w�b�_�o�^�쐬����(�O���q�ɔ���)
--* gn_mov_h_upd_n_cnt        := 0;              -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ьv��)
--* gn_mov_h_upd_y_cnt        := 0;              -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ђ���)
--* -- �ړ��˗�/�w������
--* gn_mov_l_upd_n_cnt        := 0;              -- �ړ��˗�/�w�����׍X�V�쐬����(���ьv��i�ڂ���)
--* gn_mov_l_ins_n_cnt        := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(���ьv��i�ڂȂ�)
--* gn_mov_l_ins_cnt          := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(�O���q�ɔ���)
--* gn_mov_l_upd_y_cnt        := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂ���)
--* gn_mov_l_ins_y_cnt        := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂȂ�)
--* -- ���b�g�ڍ�
--* gn_mov_mov_ins_n_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_���ьv��)
--* gn_mov_mov_ins_cnt        := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�O���q�ɔ���)
--* gn_mov_mov_upd_y_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����)
--* gn_mov_mov_ins_y_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g�Ȃ�)
--* --
--* gn_del_headers_cnt        := 0;              -- IF�w�b�_�����񌏐�
--********** 2008/07/07 ********** DELETE END   ***
    gn_del_lines_cnt          := 0;              -- IF���׎����񌏐�
    --
    gn_del_errdata_cnt        := 0;              -- �G���[�f�[�^�폜����
    --
    gn_warn_cnt               := 0;              -- �x������
--********** 2008/07/07 ********** DELETE START ***
--* gn_error_cnt              := 0;              -- �ُ팏��
--********** 2008/07/07 ********** DELETE END   ***
--
    -- ================================
    -- �p�����[�^�`�F�b�N (A-0)
    -- ================================
    chk_param(
      iv_process_object_info,    -- �����Ώۏ��
      iv_report_post,            -- �񍐕���
      lv_errbuf,                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾 �v���V�[�W�� (A-1)
    -- ===============================
    get_profile(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �p�[�W���� �v���V�[�W�� (A-2)
    -- ===============================
    purge_processing(
      iv_process_object_info, -- �����Ώۏ��
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �O���q�ɓ��o�Ɏ��я�񒊏o �v���V�[�W�� (A-3)
    -- ===============================
    get_warehouse_results_info(
      iv_process_object_info, -- �����Ώۏ��
      iv_report_post,         -- �񍐕���
      iv_object_warehouse,    -- �Ώۑq��
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (gr_interface_info_rec.COUNT = 0) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      ov_retcode := gv_status_warn;
      RETURN;
    END IF;
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �O���q�ɔ��ԃ`�F�b�N �v���V�[�W�� (A-4)
    -- ===============================
    out_warehouse_number_check(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �G���[�`�F�b�N_�z��No�P�� �v���V�[�W�� (A-5-1)
    -- ===============================
    err_chk_delivno(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �G���[�`�F�b�N_�z��No�󒍃\�[�X�Q�ƒP�� �v���V�[�W�� (A-5-2)
    -- ===============================
    err_chk_delivno_ordersrcref(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �G���[�`�F�b�N_���גP�� �v���V�[�W�� (A-5-3)
    -- ===============================
    err_chk_line(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ó��`�F�b�N �v���V�[�W�� (A-6)
    -- ===============================
    appropriate_check(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -----------------------------------------------------------------
    -- �O���q�ɓ��o�Ɏ��я�񒊏o�f�[�^�o�׈˗�/�w���f�[�^1�����̏���
    -----------------------------------------------------------------
--
    -- �t���O������
    gb_mov_header_flg      := FALSE;      -- �ړ�(A-7) �O���q��(�w���Ȃ�)���� �w�b�_�p
    gb_mov_line_flg        := FALSE;      -- �ړ�(A-7) �O���q��(�w���Ȃ�)���� ���חp
--
    gb_mov_header_data_flg := FALSE;      -- �ړ�(A-7) �w�b�_�����ϔ���
    gb_mov_line_data_flg   := FALSE;      -- �ړ�(A-7) ���׏����ϔ���
--
    gb_mov_cnt_a7_flg      := FALSE;      -- �ړ�(A-7) �����\���Ōv�ォ���������f����̂��߂̃t���O
--
  <<mov_gr_interface_info_rec_loop>>
    FOR i IN gr_interface_info_rec.FIRST .. gr_interface_info_rec.LAST LOOP
--
      --index�ޔ�
      in_idx := i;
      --EOS�f�[�^��ʂ�蔻����s���A�o�׈˗�/�w���̃f�[�^�쐬���s���B
      IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_220) OR   --220 �ړ��o�Ɋm���
         (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_230))      --230 �ړ����Ɋm���
      THEN
        --
          -- ===============================
          -- �ړ��˗�/�w���A�h�I���o�� �v���V�[�W�� (A-7)
          -- ===============================
          mov_table_outpout(
            in_idx,                 -- �f�[�^index
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = gv_status_warn) THEN
            lv_warn_flg := gv_status_warn;
          END IF;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        --
        -- A-6,A-7�ɂăG���[�E�ۗ����m�肵�Ă�f�[�^�͏����ΏۊO�Ƃ���B
        --
        IF ((gr_interface_info_rec(i).err_flg = gv_flg_off) AND      --�G���[flag�F'0'(����)
           (gr_interface_info_rec(i).reserve_flg = gv_flg_off))      --�ۗ�flag  �F'0'(����)
        THEN
          -- ===============================
          -- ���o�����R�[�h�폜 �v���V�[�W��(A-11)
          -- ===============================
          origin_record_delete(
            in_idx,                 -- �f�[�^index
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP mov_gr_interface_info_rec_loop;
--
    -----------------------------------------------------------------
    -- �O���q�ɓ��o�Ɏ��я�񒊏o�f�[�^�󒍃f�[�^1�����̏���
    -----------------------------------------------------------------
--
    -- �t���O������
    gb_ord_header_flg      := FALSE;      -- ��(A-8) �O���q��(�w���Ȃ�)���� �w�b�_�p
    gb_ord_line_flg        := FALSE;      -- ��(A-8) �O���q��(�w���Ȃ�)���� ���חp
--
    gb_ord_header_data_flg := FALSE;      -- ��(A-8) �w�b�_�����ϔ���
    gb_ord_line_data_flg   := FALSE;      -- ��(A-8) ���׏����ϔ���
--
    gb_ord_cnt_a8_flg      := FALSE;      -- ��(A-8) �����\���Ōv�ォ���������f����̂��߂̃t���O
--
    <<ord_gr_interface_info_rec_loop>>
    FOR i IN gr_interface_info_rec.FIRST .. gr_interface_info_rec.LAST LOOP
--
      --index�ޔ�
      in_idx := i;
      --EOS�f�[�^��ʂ�蔻����s���A�󒍃f�[�^�쐬���s���B
      IF ((gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_200) OR   --200 �L���o�ו�
         (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_210)  OR   --210 ���_�o�׊m���
         (gr_interface_info_rec(i).eos_data_type = gv_eos_data_cd_215))      --215 ���o�׊m���
      THEN
        --
          -- ===============================
          -- �󒍃A�h�I���o�� �v���V�[�W�� (A-8)
          -- ===============================
          order_table_outpout(
            in_idx,                 -- �f�[�^index
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = gv_status_warn) THEN
            lv_warn_flg := gv_status_warn;
          END IF;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        --
        -- A-6,A-7�ɂăG���[�E�ۗ����m�肵�Ă�f�[�^�͏����ΏۊO�Ƃ���B
        --
        IF ((gr_interface_info_rec(i).err_flg = gv_flg_off) AND      --�G���[flag�F'0'(����)
           (gr_interface_info_rec(i).reserve_flg = gv_flg_off))      --�ۗ�flag  �F'0'(����)
        THEN
          -- ===============================
          -- ���o�����R�[�h�폜 �v���V�[�W��(A-11)
          -- ===============================
          origin_record_delete(
            in_idx,                 -- �f�[�^index
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP ord_gr_interface_info_rec_loop;
--
    -- ===============================
    -- ���b�g�t�]�h�~�`�F�b�N �v���V�[�W��(A-9)
    -- ===============================
    lot_reversal_prevention_check(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �����\�`�F�b�N �v���V�[�W��(A-10)
    -- ===============================
    drawing_enable_check(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_warn) THEN
      lv_warn_flg := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �G���[�������x���ɂ�背�R�[�h�폜�v���V�[�W��(A-13)
    -- ===============================
    err_check_delete(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �X�e�[�^�X�X�V �v���V�[�W��(A-12)
    -- ===============================
    status_update(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �o�^�X�V�폜�����v���V�[�W�� (A-15)
    -- ===============================
    ins_upd_del_processing(
      lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �G���[���e�o�̓v���V�[�W�� (A-14)
    -- ===============================
      err_output(
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    -- ===============================
    -- �o�׎��ѓo�^�����v���V�[�W�� (A-16)
    -- ===============================
--  �󒍃A�h�I���֓o�^���͍X�V����f�[�^��1���ȏ㑶�݂����ꍇ
--
--********** 2008/07/07 ********** MODIFY START ***
--* IF ((gn_ord_h_upd_n_cnt > 0) OR
--*    (gn_ord_h_ins_cnt > 0)    OR
--*    (gn_ord_h_upd_y_cnt > 0))
--
    IF ((gn_ord_new_shikyu_cnt     > 0) OR
        (gn_ord_new_syukka_cnt     > 0) OR
        (gn_ord_correct_shikyu_cnt > 0) OR
        (gn_ord_correct_syukka_cnt > 0))
--********** 2008/07/07 ********** MODIFY END   ***
--
    THEN
--
      ship_results_regist_process(
        iv_object_warehouse,    -- �Ώۑq��
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���o�Ɏ��ѓo�^�����v���V�[�W�� (A-17)
    -- ===============================
--  �ړ��˗�/�w���A�h�I���֓o�^���͍X�V����f�[�^��1���ȏ㑶�݂����ꍇ
--
--********** 2008/07/07 ********** MODIFY START ***
--* IF ((gn_mov_h_ins_cnt > 0) OR
--*   (gn_mov_h_upd_n_cnt > 0) OR
--*   (gn_mov_h_upd_y_cnt > 0))
--* THEN
--
    IF ((gn_mov_new_cnt     > 0) OR
        (gn_mov_correct_cnt > 0))
    THEN
--********** 2008/07/07 ********** MODIFY END   ***
--
      move_results_regist_process(
        lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    END IF;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (lv_warn_flg = gv_status_warn) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
 /**********************************************************************************
  * Procedure Name   : main
  * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
  **********************************************************************************/
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT NOCOPY VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_process_object_info    IN  VARCHAR2,            -- �����Ώۏ��
    iv_report_post            IN  VARCHAR2,            -- �񍐕���
    iv_object_warehouse       IN  VARCHAR2             -- �Ώۑq��
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
    -- ���O�o�̓t���O�ݒ�
    set_debug_switch();
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --���̓p�����[�^(�����Ώۏ��)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_031, gv_tkn_input_item,
                                           iv_process_object_info);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���̓p�����[�^(�񍐕���)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_032, gv_tkn_input_item,
                                           iv_report_post);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���̓p�����[�^(�Ώۑq��)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_033, gv_tkn_input_item,
                                           iv_object_warehouse);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
      iv_process_object_info,     -- �����Ώۏ��
      iv_report_post,             -- �񍐕���
      iv_object_warehouse,        -- �Ώۑq��
      lv_errbuf,                  -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                 -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���͌����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_034,gv_tkn_cnt,
                                           TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    IF (lv_retcode = gv_status_error) THEN
--
--********** 2008/07/07 ********** DELETE START ***
--*   -- �󒍃w�b�_
--*   gn_ord_h_upd_n_cnt        := 0;              -- �󒍃w�b�_�X�V�쐬����(���ьv��)
--*   gn_ord_h_ins_cnt          := 0;              -- �󒍃w�b�_�o�^�쐬����(�O���q�ɔ���)
--*   gn_ord_h_upd_y_cnt        := 0;              -- �󒍃w�b�_�X�V�쐬����(���ђ���)
--*   -- �󒍖���
--*   gn_ord_l_upd_n_cnt        := 0;              -- �󒍖��׍X�V�쐬����(���ьv��i�ڂ���)
--*   gn_ord_l_ins_n_cnt        := 0;              -- �󒍖��דo�^�쐬����(���ьv��i�ڂȂ�)
--*   gn_ord_l_ins_cnt          := 0;              -- �󒍖��דo�^�쐬����(�O���q�ɔ���)
--*   gn_ord_l_ins_y_cnt        := 0;              -- �󒍖��דo�^�쐬����(���яC��)
--*   -- ���b�g�ڍ�
--*   gn_ord_mov_ins_n_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(��_���ьv��)
--*   gn_ord_mov_ins_cnt        := 0;              -- ���b�g�ڍאV�K�쐬����(��_�O���q�ɔ���)
--*   gn_ord_mov_ins_y_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(��_���яC��)
--*   -- �ړ��˗�/�w���w�b�_
--*   gn_mov_h_ins_cnt          := 0;              -- �ړ��˗�/�w���w�b�_�o�^�쐬����(�O���q�ɔ���)
--*   gn_mov_h_upd_n_cnt        := 0;              -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ьv��)
--*   gn_mov_h_upd_y_cnt        := 0;              -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ђ���)
--*   -- �ړ��˗�/�w������
--*   gn_mov_l_upd_n_cnt        := 0;              -- �ړ��˗�/�w�����׍X�V�쐬����(���ьv��i�ڂ���)
--*   gn_mov_l_ins_n_cnt        := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(���ьv��i�ڂȂ�)
--*   gn_mov_l_ins_cnt          := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(�O���q�ɔ���)
--*   gn_mov_l_upd_y_cnt        := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂ���)
--*   gn_mov_l_ins_y_cnt        := 0;              -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂȂ�)
--*   -- ���b�g�ڍ�
--*   gn_mov_mov_ins_n_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_���ьv��)
--*   gn_mov_mov_ins_cnt        := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�O���q�ɔ���)
--*   gn_mov_mov_upd_y_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����)
--*   gn_mov_mov_ins_y_cnt      := 0;              -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g�Ȃ�)
--*   --
--*   gn_del_headers_cnt        := 0;              -- IF�w�b�_�����񌏐�
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** ADD    START ***
    -- �V�K�p�̃J�E���g
    gn_ord_new_shikyu_cnt     := 0;                -- �V�K�󒍁i�x���j�쐬����
    gn_ord_new_syukka_cnt     := 0;                -- �V�K�󒍁i�o�ׁj�쐬����
    gn_mov_new_cnt            := 0;                -- �V�K�ړ��쐬����
    -- �����p�̃J�E���g
    gn_ord_correct_shikyu_cnt := 0;                -- �����󒍁i�x���j�쐬����
    gn_ord_correct_syukka_cnt := 0;                -- �����󒍁i�o�ׁj�쐬����
    gn_mov_correct_cnt        := 0;                -- �����ړ��쐬����
--********** 2008/07/07 ********** ADD    END   ***
--
      gn_del_lines_cnt          := 0;              -- IF���׎����񌏐�
      --
      gn_del_errdata_cnt        := 0;              -- �G���[�f�[�^�폜����
      --
      gn_warn_cnt               := 0;              -- �x������
    END IF;
--
--********** 2008/07/07 ********** DELETE START ***
--*--�󒍃w�b�_�X�V�쐬����(���ьv��) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_h_upd_n_cnt_nm,   -- �󒍃w�b�_�X�V�쐬����(���ьv��)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_h_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �󒍃w�b�_�o�^�쐬����(�O���q�ɔ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_h_ins_cnt_nm,     -- �󒍃w�b�_�o�^�쐬����(�O���q�ɔ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_h_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �󒍃w�b�_�X�V�쐬����(���ђ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_h_upd_y_cnt_nm,   -- �󒍃w�b�_�X�V�쐬����(���ђ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_h_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �󒍖��׍X�V�쐬����(���ьv��i�ڂ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_l_upd_n_cnt_nm,   -- �󒍖��׍X�V�쐬����(���ьv��i�ڂ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_l_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �󒍖��דo�^�쐬����(���ьv��i�ڂȂ�) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_l_ins_n_cnt_nm,   -- �󒍖��דo�^�쐬����(���ьv��i�ڂȂ�)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_l_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �󒍖��דo�^�쐬����(�O���q�ɔ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_l_ins_cnt_nm,     -- �󒍖��דo�^�쐬����(�O���q�ɔ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_l_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �󒍖��דo�^�쐬����(���яC��) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_l_ins_y_cnt_nm,   -- �󒍖��דo�^�쐬����(���яC��)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_l_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ���b�g�ڍאV�K�쐬����(��_���ьv��) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_mov_ins_n_cnt_nm, -- ���b�g�ڍאV�K�쐬����(��_���ьv��)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_mov_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ���b�g�ڍאV�K�쐬����(��_�O���q�ɔ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_mov_ins_cnt_nm,   -- ���b�g�ڍאV�K�쐬����(��_�O���q�ɔ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_mov_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ���b�g�ڍאV�K�쐬����(��_���яC��) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_ord_mov_ins_y_cnt_nm, -- ���b�g�ڍאV�K�쐬����(��_���яC��)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_ord_mov_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w���w�b�_�o�^�쐬����(�O���q�ɔ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_h_ins_cnt_nm, -- �ړ��˗�/�w���w�b�_�o�^�쐬����(�O���q�ɔ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_h_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ьv��) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_h_upd_n_cnt_nm,   -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ьv��)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_h_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ђ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_h_upd_y_cnt_nm,   -- �ړ��˗�/�w���w�b�_�X�V�쐬����(���ђ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_h_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w�����׍X�V�쐬����(���ьv��i�ڂ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_l_upd_n_cnt_nm,   -- �ړ��˗�/�w�����׍X�V�쐬����(���ьv��i�ڂ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_l_upd_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w�����דo�^�쐬����(���ьv��i�ڂȂ�) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_l_ins_n_cnt_nm,   -- �ړ��˗�/�w�����דo�^�쐬����(���ьv��i�ڂȂ�)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_l_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w�����דo�^�쐬����(�O���q�ɔ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_l_ins_cnt_nm,     -- �ړ��˗�/�w�����דo�^�쐬����(�O���q�ɔ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_l_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_l_upd_y_cnt_nm,   -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_l_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂȂ�) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_l_ins_y_cnt_nm,   -- �ړ��˗�/�w�����דo�^�쐬����(�������i�ڂȂ�)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_l_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_���ьv��) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_mov_ins_n_cnt_nm, -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_���ьv��)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_mov_ins_n_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�O���q�ɔ���) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_mov_ins_cnt_nm,   -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�O���q�ɔ���)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_mov_ins_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_mov_upd_y_cnt_nm, -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g����)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_mov_upd_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--*
--* -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g�Ȃ�) �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_mov_mov_ins_y_cnt_nm, -- ���b�g�ڍאV�K�쐬����(�ړ��˗�_�������b�g�Ȃ�)
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_mov_mov_ins_y_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** ADD    START ***
    -- �V�K�󒍁i�x���j�쐬 �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                 -- 'XXWSH'
                        gv_msg_93a_040,             -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,            -- �g�[�N��'PARAM1'
                        gv_ord_new_shikyu_cnt_nm,   -- �V�K�󒍁i�x���j�쐬
                        gv_tkn_cnt,                 -- �g�[�N��'CNT'
                        TO_CHAR(gn_ord_new_shikyu_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �V�K�󒍁i�o�ׁj�쐬 �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                 -- 'XXWSH'
                        gv_msg_93a_040,             -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,            -- �g�[�N��'PARAM1'
                        gv_ord_new_syukka_cnt_nm,   -- �V�K�󒍁i�o�ׁj�쐬
                        gv_tkn_cnt,                 -- �g�[�N��'CNT'
                        TO_CHAR(gn_ord_new_syukka_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �V�K�ړ��쐬 �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,         -- �g�[�N��'PARAM1'
                        gv_mov_new_cnt_nm,       -- �V�K�ړ��쐬
                        gv_tkn_cnt,              -- �g�[�N��'CNT'
                        TO_CHAR(gn_mov_new_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �����󒍁i�x���j�쐬 �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                   -- 'XXWSH'
                        gv_msg_93a_040,               -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,              -- �g�[�N��'PARAM1'
                        gv_ord_correct_shikyu_cnt_nm, -- �����󒍁i�x���j�쐬
                        gv_tkn_cnt,                   -- �g�[�N��'CNT'
                        TO_CHAR(gn_ord_correct_shikyu_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�����󒍁i�o�ׁj�쐬 �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,                   -- 'XXWSH'
                        gv_msg_93a_040,               -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,              -- �g�[�N��'PARAM1'
                        gv_ord_correct_syukka_cnt_nm, -- �����󒍁i�o�ׁj�쐬
                        gv_tkn_cnt,                   -- �g�[�N��'CNT'
                        TO_CHAR(gn_ord_correct_syukka_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�����ړ��쐬 �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,         -- �g�[�N��'PARAM1'
                        gv_mov_correct_cnt_nm,   -- �����ړ��쐬
                        gv_tkn_cnt,              -- �g�[�N��'CNT'
                        TO_CHAR(gn_mov_correct_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
--********** 2008/07/07 ********** ADD    END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--* -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�폜���� �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_header_cnt_nm,        -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�폜
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_del_headers_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** DELETE END   ***
--
--********** 2008/07/07 ********** MODIFY START ***
--* -- �o�׈˗��C���^�t�F�[�X�w�b�_(�A�h�I��)�폜���� �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_lines_cnt_nm,         -- �o�׈˗��C���^�t�F�[�X����(�A�h�I��)�폜
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_del_lines_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �o�׈˗��C���^�t�F�[�X�p�[�W�폜���� �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,         -- �g�[�N��'PARAM1'
                        gv_lines_cnt_nm,         -- �o�׈˗��C���^�t�F�[�X�p�[�W�폜
                        gv_tkn_cnt,              -- �g�[�N��'CNT'
                        TO_CHAR(gn_del_lines_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** MODIFY END   ***
--
--********** 2008/07/07 ********** MODIFY START ***
--* -- �G���[�f�[�^�폜���� �o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(
--*                     gv_msg_kbn,              -- 'XXWSH'
--*                     gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
--*                     gv_param1_token,         -- �g�[�N��'PARAM1'
--*                     gv_err_data_del_cnt_nm,  -- �G���[�f�[�^�폜
--*                     gv_tkn_cnt,              -- �g�[�N��'CNT'
--*                     TO_CHAR(gn_del_errdata_cnt));
--*
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �o�׈˗��C���^�t�F�[�X�G���[�폜���� �o��
    gv_out_msg := xxcmn_common_pkg.get_msg(
                        gv_msg_kbn,              -- 'XXWSH'
                        gv_msg_93a_040,          -- �e�������ʌ������b�Z�[�W
                        gv_param1_token,         -- �g�[�N��'PARAM1'
                        gv_err_data_del_cnt_nm,  -- �o�׈˗��C���^�t�F�[�X�G���[�폜
                        gv_tkn_cnt,              -- �g�[�N��'CNT'
                        TO_CHAR(gn_del_errdata_cnt));
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** MODIFY END   ***
--
--********** 2008/07/07 ********** DELETE START ***
--* --�ُ팏���o��
--* gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_038,gv_tkn_cnt,
--*                                        TO_CHAR(gn_error_cnt));
--* FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--********** 2008/07/07 ********** DELETE END   ***
--
    --�x�������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_93a_039,gv_tkn_cnt,
                                           TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh930001c;
/
