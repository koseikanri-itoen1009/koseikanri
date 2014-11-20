CREATE OR REPLACE PACKAGE BODY xxcmn800002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800002c(body)
 * Description      : �i�ڃ}�X�^�C���^�t�F�[�X
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �i�ڃC���^�t�F�[�X T_MD070_BPO_80B
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_profile            �v���t�@�C���擾�v���V�[�W��
 *  set_if_lock            �C���^�t�F�[�X�e�[�u���ɑ΂��郍�b�N�擾�v���V�[�W��
 *  set_error_status       �G���[������������Ԃɂ���v���V�[�W��
 *  set_warn_status        �x��������������Ԃɂ���v���V�[�W��
 *  set_warok_status       �x��������������Ԃɂ���v���V�[�W��
 *  init_status            �X�e�[�^�X�������v���V�[�W��
 *  is_file_status_nomal   �t�@�C�����x���Ő��킩�󋵂��m�F����t�@���N�V����
 *  init_row_status        �s���x���X�e�[�^�X�������v���V�[�W��
 *  is_row_status_nomal    �s���x���Ő��킩�󋵂��m�F����t�@���N�V����
 *  is_row_status_warn     �s���x���Ōx�����󋵂��m�F����t�@���N�V����
 *  is_row_status_warok    �s���x���Ōx�����󋵂��m�F����t�@���N�V����
 *  add_report             ���|�[�g�p�f�[�^��ݒ肷��v���V�[�W��
 *  disp_report            ���|�[�g�p�f�[�^���o�͂���v���V�[�W��
 *  get_xxcmn_item_if      �i�ڃC���^�t�F�[�X�̈ȑO�̌����擾���s���v���V�[�W��
 *  chk_ic_item_mst_b      �i�ڃR�[�h�̑��݃`�F�b�N���s���v���V�[�W��(OPM�i�ڃ}�X�^)
 *  chk_xxcmn_item_mst_b   �i�ڃR�[�h�̑��݃`�F�b�N���s���v���V�[�W��(OPM�i�ڃA�h�I���}�X�^)
 *  chk_gmi_item_category  �i�ڃR�[�h�̑��݃`�F�b�N���s���v���V�[�W��(OPM�i�ڃJ�e�S������)
 *  chk_cm_cmpt_dtl        �i�ڃR�[�h�̑��݃`�F�b�N���s���v���V�[�W��(�i�ڌ����}�X�^)
 *  chk_parent_id          �e�i�ڃR�[�h�̑��݃`�F�b�N���s���v���V�[�W��
 *  check_proc_code        ����Ώۂ̃��R�[�h�ł��邱�Ƃ��`�F�b�N����v���V�[�W��
 *  init_cmpntcls_id       �R���|�[�l���g�敪ID�̏����擾���s���v���V�[�W��
 *  get_price              �P���̎擾���s���v���V�[�W��
 *  get_item_id            �i��ID�̎擾���s���v���V�[�W��
 *  get_parent_id          �e�i��ID�̎擾���s���v���V�[�W��
 *  get_period_code        ���Ԃ̎擾���s���v���V�[�W��
 *  get_uom_code           �P�ʂ̎擾���s���v���V�[�W��
 *  get_cmpnt_id           �����ڍ�ID�̎擾���s���v���V�[�W��
 *  proc_xxcmn_item_mst    OPM�i�ڃA�h�I���}�X�^�̏������s���v���V�[�W��
 *  proc_item_category     OPM�i�ڃJ�e�S�������̏������s���v���V�[�W��
 *  proc_ic_item_mst       OPM�i�ڃ}�X�^�̏������s���v���V�[�W��
 *  chk_price              �P���̃`�F�b�N���s���v���V�[�W��
 *  check_item_ins         �i�ړo�^�p�f�[�^���`�F�b�N����v���V�[�W��
 *  check_item_upd         �i�ڍX�V�p�f�[�^���`�F�b�N����v���V�[�W��
 *  check_item_del         �i�ڍ폜�p�f�[�^���`�F�b�N����v���V�[�W��
 *  check_cmpt_ins         �i�ڌ����o�^�p�f�[�^���`�F�b�N����v���V�[�W��
 *  check_cmpt_upd         �i�ڌ����X�V�p�f�[�^���`�F�b�N����v���V�[�W��
 *  item_insert_proc       �i�ړo�^�������s���v���V�[�W��
 *  item_update_proc       �i�ڍX�V�������s���v���V�[�W��
 *  item_delete_proc       �i�ڍ폜�������s���v���V�[�W��
 *  cmpt_insert_proc       �i�ڌ����o�^�������s���v���V�[�W��
 *  cmpt_update_proc       �i�ڌ����X�V�������s���v���V�[�W��
 *  proc_item              ���f�������s���v���V�[�W��
 *  init_proc              �����������s���v���V�[�W��
 *  term_proc              �I���������s���v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/16    1.0   Oracle �R�� ��_ ����쐬
 *  2008/02/05    1.0   Oracle �R�� ��_ �ύX�v��No�X�Ή�
 *  2008/04/24    1.1   Oracle �R�� ��_ �ύX�v��No60�Ή�
 *  2008/05/20    1.2   Oracle �ۉ� ���� OPM�i�ڃJ�e�S�������̏C��
 *  2008/05/27    1.3   Oracle �ۉ� ���� �����ύX�v��No122�Ή�
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_warok_cnt     NUMBER;                    -- �X�L�b�v����
  gn_report_cnt    NUMBER;                    -- ���|�[�g����
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
  check_sub_main_expt         EXCEPTION;     -- �T�u���C���̃G���[
  check_item_ins_expt         EXCEPTION;     -- �o�^�����̃G���[(�i��)
  check_item_upd_expt         EXCEPTION;     -- �X�V�����̃G���[(�i��)
  check_item_del_expt         EXCEPTION;     -- �폜�����̃G���[(�i��)
  check_cmpt_ins_expt         EXCEPTION;     -- �o�^�����̃G���[(�i�ڌ���)
  check_cmpt_upd_expt         EXCEPTION;     -- �X�V�����̃G���[(�i�ڌ���)
--
  lock_expt                   EXCEPTION;     -- �f�b�h���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �C���^�t�F�[�X�f�[�^�̑�����
  gn_proc_insert CONSTANT NUMBER := 1;  -- �o�^
  gn_proc_update CONSTANT NUMBER := 2;  -- �X�V
  gn_proc_delete CONSTANT NUMBER := 9;  -- �폜
--
  -- �����󋵂�����킷�X�e�[�^�X
  gn_data_status_nomal CONSTANT NUMBER := 0; -- ����
  gn_data_status_error CONSTANT NUMBER := 1; -- ���s
  gn_data_status_warn  CONSTANT NUMBER := 2; -- �x��
  gn_data_status_warok CONSTANT NUMBER := 3; -- �x��(����)
--
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn800002c'; -- �p�b�P�[�W��
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_item_if_name      CONSTANT VARCHAR2(100) := 'xxcmn_item_if';
--
  gv_lookup_type       CONSTANT VARCHAR2(100) := 'XXPO_PRICE_TYPE';
  gv_meaning           CONSTANT VARCHAR2(100) := '�W��';
  gv_description       CONSTANT VARCHAR2(100) := '�P�[�X';
  gv_lookup_code       CONSTANT VARCHAR2(1)   := '2';
  gv_lot_ctl_on        CONSTANT VARCHAR2(1)   := '1';
  gv_active_flag_mi    CONSTANT VARCHAR2(1)   := 'N';
  gv_inactive_ind_on   CONSTANT VARCHAR2(1)   := '0';
  gv_inactive_ind_off  CONSTANT VARCHAR2(1)   := '1';
  gv_language          CONSTANT VARCHAR2(10)  := userenv('LANG');
  gv_cost_level_on     CONSTANT VARCHAR2(1)   := '0';
  gv_def_item_um       CONSTANT VARCHAR2(2)   := 'CS';
  gv_autolot_on        CONSTANT NUMBER        := 1;
  gv_lot_suffix_on     CONSTANT NUMBER        := 0;
  gv_dot_pnt           CONSTANT NUMBER        := 2;
  gv_api_ver           CONSTANT NUMBER        := 2.0;
  gn_loct_ctl_on       CONSTANT NUMBER        := 1;
  gv_div_code_reef     CONSTANT VARCHAR2(1)   := '1';                    -- ���[�t
  gv_div_code_drink    CONSTANT VARCHAR2(1)   := '2';                    -- �h�����N
  gv_rate_code_reef    CONSTANT VARCHAR2(1)   := '2';                    -- �e��
  gv_rate_code_drink   CONSTANT VARCHAR2(1)   := '1';                    -- �d��
--
  --���b�Z�[�W�ԍ�
  gv_msg_80b_001       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';  --���[�U�[��
  gv_msg_80b_002       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';  --�R���J�����g��
  gv_msg_80b_003       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';  --�Z�p���[�^
  gv_msg_80b_004       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';  --�����f�[�^(���o��)
  gv_msg_80b_005       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';  --�G���[�f�[�^(���o��)
  gv_msg_80b_006       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';  --�X�L�b�v�f�[�^(���o��)
  gv_msg_80b_007       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';  --��������
  gv_msg_80b_008       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';  --��������
  gv_msg_80b_009       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';  --�G���[����
  gv_msg_80b_010       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';  --�X�L�b�v����
  gv_msg_80b_011       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';  --�����X�e�[�^�X
  gv_msg_80b_012       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  --�v���t�@�C���擾�G���[
  gv_msg_80b_013       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --API�G���[(�R���J�����g)
  gv_msg_80b_014       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';  --���b�N�G���[
  gv_msg_80b_015       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10020';  --�]�ƈ��ΏۊO���R�[�h
  gv_msg_80b_016       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10021';  --�͈͊O�f�[�^
  gv_msg_80b_017       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10022';  --�e�[�u���폜�G���[
  gv_msg_80b_018       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';  --�R���J�����g��^�G���[
  gv_msg_80b_019       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';  --�N������
  gv_msg_80b_020       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10148';  --�i�ڌ��������̓G���[
  gv_msg_80b_021       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00024';  --�����f�[�^�E�x������(���o��)
--�G���[�E���[�j���O
  gv_msg_80b_100       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10099';  --�i�ڌ����X�V�̌����`�F�b�N
  gv_msg_80b_101       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10100';  --�i�ڌ����o�^�̌����`�F�b�N
  gv_msg_80b_102       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10101';  --�i�ڍX�V�̑��݃`�F�b�N
  gv_msg_80b_103       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10102';  --�i�ڍ폜�̑��݃`�F�b�N
  gv_msg_80b_104       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10103';  --�i�ړo�^�̏d���`�F�b�N
  gv_msg_80b_105       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10104';  --�i�ڌ����X�V�̑��݃`�F�b�N
  gv_msg_80b_106       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10105';  --�i�ڌ����폜�̑��݃`�F�b�N
  gv_msg_80b_107       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10106';  --�i�ڌ����o�^�̏d���`�F�b�N
  gv_msg_80b_108       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10149';  --�e�i�ڑ��݃`�F�b�N
--
  --�g�[�N��
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_hinmoku    CONSTANT VARCHAR2(15) := 'NG_HINMOKU';
  gv_tkn_ng_genka      CONSTANT VARCHAR2(15) := 'NG_GENKA';
  gv_tkn_ng_item_cd    CONSTANT VARCHAR2(15) := 'NG_ITEM_CODE';
--
  -- �g�pDB��
  gv_xxcmn_item_if_name      CONSTANT VARCHAR2(100) := '�i�ڃC���^�t�F�[�X';
  gv_ic_item_mst_b_name      CONSTANT VARCHAR2(100) := 'OPM�i�ڃ}�X�^';
  gv_xxcmn_item_mst_b_name   CONSTANT VARCHAR2(100) := 'OPM�i�ڃA�h�I���}�X�^';
  gv_gmi_item_category_name  CONSTANT VARCHAR2(100) := 'OPM�i�ڃJ�e�S������';
  gv_cm_cmpt_dtl_name        CONSTANT VARCHAR2(100) := '�i�ڌ����}�X�^';
  gv_xxpo_price_headers_name CONSTANT VARCHAR2(100) := '�d��/�W�������}�X�^';
--
  --�v���t�@�C��
  gv_prf_max_date             CONSTANT VARCHAR2(50) := 'XXCMN_MAX_DATE';
  gv_prf_min_date             CONSTANT VARCHAR2(50) := 'XXCMN_MIN_DATE';
  gv_prf_category_name_otgun  CONSTANT VARCHAR2(50) := 'XXCMN_CATEGORY_NAME_OTGUN';
  gv_prf_policy_group_code    CONSTANT VARCHAR2(50) := 'XXCMN_POLICY_GROUP_CODE';
  gv_prf_marke_crowd_code     CONSTANT VARCHAR2(50) := 'XXCMN_MARKE_CROWD_CODE';
  gv_prf_product_div_code     CONSTANT VARCHAR2(50) := 'XXCMN_PRODUCT_DIV_CODE';
  gv_prf_arti_div_code        CONSTANT VARCHAR2(50) := 'XXCMN_ARTI_DIV_CODE';
  gv_prf_div_tea_code         CONSTANT VARCHAR2(50) := 'XXCMN_DIV_TEA_CODE';
  gv_prf_cost_price_whse_code CONSTANT VARCHAR2(50) := 'XXCMN_COST_PRICE_WHSE_CODE';
  gv_prf_item_cal             CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_CAL';
  gv_prf_cost_div             CONSTANT VARCHAR2(50) := 'XXCMN_COST_DIV';
  gv_prf_raw_material_cost    CONSTANT VARCHAR2(50) := 'XXCMN_RAW_MATERIAL_COST';
  gv_prf_agein_cost           CONSTANT VARCHAR2(50) := 'XXCMN_AGEIN_COST';
  gv_prf_material_cost        CONSTANT VARCHAR2(50) := 'XXCMN_MATERIAL_COST';
  gv_prf_pack_cost            CONSTANT VARCHAR2(50) := 'XXCMN_PACK_COST';
  gv_prf_out_order_cost       CONSTANT VARCHAR2(50) := 'XXCMN_OUT_ORDER_COST';
  gv_prf_safekeep_cost        CONSTANT VARCHAR2(50) := 'XXCMN_SAFEKEEP_COST';
  gv_prf_other_expense_cost   CONSTANT VARCHAR2(50) := 'XXCMN_OTHER_EXPENSE_COST';
  gv_prf_spare1               CONSTANT VARCHAR2(50) := 'XXCMN_SPARE1';
  gv_prf_spare2               CONSTANT VARCHAR2(50) := 'XXCMN_SPARE2';
  gv_prf_spare3               CONSTANT VARCHAR2(50) := 'XXCMN_SPARE3';
--
  gv_prf_max_date_name        CONSTANT VARCHAR2(50) := 'MAX���t';
  gv_prf_min_date_name        CONSTANT VARCHAR2(50) := 'MIN���t';
  gv_prf_crowd_code_name      CONSTANT VARCHAR2(50) := '�J�e�S���Z�b�g��(�Q�R�[�h)';
  gv_prf_policy_code_name     CONSTANT VARCHAR2(50) := '�J�e�S���Z�b�g��(����Q�R�[�h)';
  gv_prf_marke_code_name      CONSTANT VARCHAR2(50) := '�J�e�S���Z�b�g��(�}�[�P�p�Q�R�[�h)';
  gv_prf_product_code_name    CONSTANT VARCHAR2(50) := '�J�e�S���Z�b�g��(���i���i�敪)';
  gv_prf_arti_code_name       CONSTANT VARCHAR2(50) := '�J�e�S���Z�b�g��(�{�Џ��i�敪)';
  gv_prf_tea_code_name        CONSTANT VARCHAR2(50) := '�J�e�S���Z�b�g��(�o�����敪)';
  gv_prf_whse_code_name       CONSTANT VARCHAR2(50) := '�����q��';
  gv_prf_item_cal_name        CONSTANT VARCHAR2(50) := '�J�����_';
  gv_prf_cost_div_name        CONSTANT VARCHAR2(50) := '�������@';
  gv_prf_raw_mat_cost_name    CONSTANT VARCHAR2(50) := '����';
  gv_prf_agein_cost_name      CONSTANT VARCHAR2(50) := '�Đ���';
  gv_prf_material_cost_name   CONSTANT VARCHAR2(50) := '���ޔ�';
  gv_prf_pack_cost_name       CONSTANT VARCHAR2(50) := '���';
  gv_prf_out_order_cost_name  CONSTANT VARCHAR2(50) := '�O�����H��';
  gv_prf_safekeep_cost_name   CONSTANT VARCHAR2(50) := '�ۊǔ�';
  gv_prf_other_cost_name      CONSTANT VARCHAR2(50) := '���̑��o��';
  gv_prf_spare1_name          CONSTANT VARCHAR2(50) := '�\���P';
  gv_prf_spare2_name          CONSTANT VARCHAR2(50) := '�\���Q';
  gv_prf_spare3_name          CONSTANT VARCHAR2(50) := '�\���R';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �R���|�[�l���g�敪�}�X�^�̕K�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE cmpntcls_rec IS RECORD(
    cost_cmpntcls_id      cm_cmpt_mst_tl.cost_cmpntcls_id%TYPE,     -- �R���|�[�l���g�敪ID
    cost_cmpntcls_code    cm_cmpt_mst.cost_cmpntcls_code%TYPE,      -- �R���|�[�l���g�敪�R�[�h
    cost_cmpntcls_desc    cm_cmpt_mst_tl.cost_cmpntcls_desc%TYPE,   -- �R���|�[�l���g�敪��
    cost_price            NUMBER                                    -- ���z
  );
--
  -- �R���|�[�l���g�敪�}�X�^�̃f�[�^���i�[���錋���z��
  TYPE cmpntcls_tbl IS TABLE OF cmpntcls_rec INDEX BY PLS_INTEGER;
--
  -- �e�}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE masters_rec IS RECORD(
    seq_number            xxcmn_item_if.seq_number%TYPE,            --- SEQ�ԍ�
    proc_code             xxcmn_item_if.proc_code%TYPE,             --- �X�V�敪
    item_code             xxcmn_item_if.item_code%TYPE,             --- �i���R�[�h
    item_name             xxcmn_item_if.item_name%TYPE,             --- �i���E������
    item_short_name       xxcmn_item_if.item_short_name%TYPE,       --- �i���E����
    item_name_alt         xxcmn_item_if.item_name_alt%TYPE,         --- �i���E�J�i
    old_crowd_code        xxcmn_item_if.old_crowd_code%TYPE,        --- ���E�Q�R�[�h
    new_crowd_code        xxcmn_item_if.new_crowd_code%TYPE,        --- �V�E�Q�R�[�h
    crowd_start_date      xxcmn_item_if.crowd_start_date%TYPE,      --- �K�p�J�n��
    policy_group_code     xxcmn_item_if.policy_group_code%TYPE,     --- ����Q�R�[�h
    marke_crowd_code      xxcmn_item_if.marke_crowd_code%TYPE,      --- �}�[�P�p�Q�R�[�h
    old_price             xxcmn_item_if.old_price%TYPE,             --- ���E�艿
    new_price             xxcmn_item_if.new_price%TYPE,             --- �V�E�艿
    price_start_date      xxcmn_item_if.price_start_date%TYPE,      --- �K�p�J�n��
    old_standard_cost     xxcmn_item_if.old_standard_cost%TYPE,     --- ���E�W������
    new_standard_cost     xxcmn_item_if.new_standard_cost%TYPE,     --- �V�E�W������
    standard_start_date   xxcmn_item_if.standard_start_date%TYPE,   --- �K�p�J�n��
    old_business_cost     xxcmn_item_if.old_business_cost%TYPE,     --- ���E�c�ƌ���
    new_business_cost     xxcmn_item_if.new_business_cost%TYPE,     --- �V�E�c�ƌ���
    business_start_date   xxcmn_item_if.business_start_date%TYPE,   --- �K�p�J�n��
    old_tax               xxcmn_item_if.old_tax%TYPE,               --- ���E����ŗ�
    new_tax               xxcmn_item_if.new_tax%TYPE,               --- �V�E����ŗ�
    tax_start_date        xxcmn_item_if.tax_start_date%TYPE,        --- �K�p�J�n��
    rate_code             xxcmn_item_if.rate_code%TYPE,             --- ���敪
    case_num              xxcmn_item_if.case_num%TYPE,              --- �P�[�X����
    product_div_code      xxcmn_item_if.product_div_code%TYPE,      --- ���i���i�敪
    net                   xxcmn_item_if.net%TYPE,                   --- NET
    weight_volume         xxcmn_item_if.weight_volume%TYPE,         --- �d��/�̐�
    arti_div_code         xxcmn_item_if.arti_div_code%TYPE,         --- ���i�敪
    div_tea_code          xxcmn_item_if.div_tea_code%TYPE,          --- �o�����敪
    parent_item_code      xxcmn_item_if.parent_item_code%TYPE,      --- �e�i���R�[�h
    sale_obj_code         xxcmn_item_if.sale_obj_code%TYPE,         --- ����Ώۋ敪
    jan_code              xxcmn_item_if.jan_code%TYPE,              --- JAN�R�[�h
    sale_start_date       xxcmn_item_if.sale_start_date%TYPE,       --- �����J�n��(�����J�n��)
    abolition_code        xxcmn_item_if.abolition_code%TYPE,        --- �p�~�敪
    abolition_date        xxcmn_item_if.abolition_date%TYPE,        --- �p�~��(�������~��)
    raw_mate_consumption  xxcmn_item_if.raw_mate_consumption%TYPE,  --- �����g�p��
    raw_material_cost     xxcmn_item_if.raw_material_cost%TYPE,     --- ����
    agein_cost            xxcmn_item_if.agein_cost%TYPE,            --- �Đ���
    material_cost         xxcmn_item_if.material_cost%TYPE,         --- ���ޔ�
    pack_cost             xxcmn_item_if.pack_cost%TYPE,             --- ���
    out_order_cost        xxcmn_item_if.out_order_cost%TYPE,        --- �O�����H��
    safekeep_cost         xxcmn_item_if.safekeep_cost%TYPE,         --- �ۊǔ�
    other_expense_cost    xxcmn_item_if.other_expense_cost%TYPE,    --- ���̑��o��
    spare1                xxcmn_item_if.spare1%TYPE,                --- �\��1
    spare2                xxcmn_item_if.spare2%TYPE,                --- �\��2
    spare3                xxcmn_item_if.spare3%TYPE,                --- �\��3
    spare                 xxcmn_item_if.spare%TYPE,                 --- �\��
--
    item_id               ic_item_mst_b.item_id%TYPE,               --- �i��ID
    parent_item_id        ic_item_mst_b.item_id%TYPE,               --- �e�i��ID
    period_code           cm_cldr_dtl.period_code%TYPE,             --- ����
    cmpntcost_id          cm_cmpt_dtl.cmpntcost_id%TYPE,            --- �����ڍ�ID
    cost_id               cm_cmpt_mst_tl.cost_cmpntcls_id%TYPE,     --- �R���|�[�l���g�敪ID
--
    cmpntcls_mast         cmpntcls_tbl,                             --- �R���|�[�l���g�敪�}�X�^
--
    crowd_start_days      VARCHAR2(10),                             --- �Q�R�[�h�K�p�J�n��
    price_start_days      VARCHAR2(10),                             --- �艿�K�p�J�n��
    buis_start_days       VARCHAR2(10),                             --- �c�ƌ����K�p�J�n��
    sale_start_days       VARCHAR2(10),                             --- �����J�n��(�����J�n��)
--
    -- �ȑO�̌���
    row_ins_cnt           NUMBER,                                   -- �o�^����
    row_upd_cnt           NUMBER,                                   -- �X�V����
    row_del_cnt           NUMBER                                    -- �폜����
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- �o�͂��郍�O���i�[���郌�R�[�h
  TYPE report_rec IS RECORD(
    seq_number            xxcmn_item_if.seq_number%TYPE,            --- SEQ�ԍ�
    proc_code             xxcmn_item_if.proc_code%TYPE,             --- �X�V�敪
    item_code             xxcmn_item_if.item_code%TYPE,             --- �i���R�[�h
    item_name             xxcmn_item_if.item_name%TYPE,             --- �i���E������
    item_short_name       xxcmn_item_if.item_short_name%TYPE,       --- �i���E����
    item_name_alt         xxcmn_item_if.item_name_alt%TYPE,         --- �i���E�J�i
    old_crowd_code        xxcmn_item_if.old_crowd_code%TYPE,        --- ���E�Q�R�[�h
    new_crowd_code        xxcmn_item_if.new_crowd_code%TYPE,        --- �V�E�Q�R�[�h
    crowd_start_date      xxcmn_item_if.crowd_start_date%TYPE,      --- �K�p�J�n��
    policy_group_code     xxcmn_item_if.policy_group_code%TYPE,     --- ����Q�R�[�h
    marke_crowd_code      xxcmn_item_if.marke_crowd_code%TYPE,      --- �}�[�P�p�Q�R�[�h
    old_price             xxcmn_item_if.old_price%TYPE,             --- ���E�艿
    new_price             xxcmn_item_if.new_price%TYPE,             --- �V�E�艿
    price_start_date      xxcmn_item_if.price_start_date%TYPE,      --- �K�p�J�n��
    old_standard_cost     xxcmn_item_if.old_standard_cost%TYPE,     --- ���E�W������
    new_standard_cost     xxcmn_item_if.new_standard_cost%TYPE,     --- �V�E�W������
    standard_start_date   xxcmn_item_if.standard_start_date%TYPE,   --- �K�p�J�n��
    old_business_cost     xxcmn_item_if.old_business_cost%TYPE,     --- ���E�c�ƌ���
    new_business_cost     xxcmn_item_if.new_business_cost%TYPE,     --- �V�E�c�ƌ���
    business_start_date   xxcmn_item_if.business_start_date%TYPE,   --- �K�p�J�n��
    old_tax               xxcmn_item_if.old_tax%TYPE,               --- ���E����ŗ�
    new_tax               xxcmn_item_if.new_tax%TYPE,               --- �V�E����ŗ�
    tax_start_date        xxcmn_item_if.tax_start_date%TYPE,        --- �K�p�J�n��
    rate_code             xxcmn_item_if.rate_code%TYPE,             --- ���敪
    case_num              xxcmn_item_if.case_num%TYPE,              --- �P�[�X����
    product_div_code      xxcmn_item_if.product_div_code%TYPE,      --- ���i���i�敪
    net                   xxcmn_item_if.net%TYPE,                   --- NET
    weight_volume         xxcmn_item_if.weight_volume%TYPE,         --- �d��/�̐�
    arti_div_code         xxcmn_item_if.arti_div_code%TYPE,         --- ���i�敪
    div_tea_code          xxcmn_item_if.div_tea_code%TYPE,          --- �o�����敪
    parent_item_code      xxcmn_item_if.parent_item_code%TYPE,      --- �e�i���R�[�h
    sale_obj_code         xxcmn_item_if.sale_obj_code%TYPE,         --- ����Ώۋ敪
    jan_code              xxcmn_item_if.jan_code%TYPE,              --- JAN�R�[�h
    sale_start_date       xxcmn_item_if.sale_start_date%TYPE,       --- �����J�n��(�����J�n��)
    abolition_code        xxcmn_item_if.abolition_code%TYPE,        --- �p�~�敪
    abolition_date        xxcmn_item_if.abolition_date%TYPE,        --- �p�~��(�������~��)
    raw_mate_consumption  xxcmn_item_if.raw_mate_consumption%TYPE,  --- �����g�p��
    raw_material_cost     xxcmn_item_if.raw_material_cost%TYPE,     --- ����
    agein_cost            xxcmn_item_if.agein_cost%TYPE,            --- �Đ���
    material_cost         xxcmn_item_if.material_cost%TYPE,         --- ���ޔ�
    pack_cost             xxcmn_item_if.pack_cost%TYPE,             --- ���
    out_order_cost        xxcmn_item_if.out_order_cost%TYPE,        --- �O�����H��
    safekeep_cost         xxcmn_item_if.safekeep_cost%TYPE,         --- �ۊǔ�
    other_expense_cost    xxcmn_item_if.other_expense_cost%TYPE,    --- ���̑��o��
    spare1                xxcmn_item_if.spare1%TYPE,                --- �\��1
    spare2                xxcmn_item_if.spare2%TYPE,                --- �\��2
    spare3                xxcmn_item_if.spare3%TYPE,                --- �\��3
    spare                 xxcmn_item_if.spare%TYPE,                 --- �\��
--
    imb_flg               NUMBER,                                   -- OPM�i�ڃ}�X�^
    xmb_flg               NUMBER,                                   -- OPM�i�ڃA�h�I���}�X�^
    gic_flg               NUMBER,                                   -- OPM�i�ڃJ�e�S������
    ccd_flg               NUMBER,                                   -- �i�ڌ����}�X�^
--
    row_level_status      NUMBER,                                   -- 0.����,1.���s,2.�x��
    message               VARCHAR2(1000)
  );
--
  -- �o�͂��郌�|�[�g���i�[���錋���z��
  TYPE report_tbl IS TABLE OF report_rec INDEX BY PLS_INTEGER;
--
  -- �����󋵂��Ǘ����郌�R�[�h
  TYPE status_rec IS RECORD(
    file_level_status         NUMBER,                               -- 0.����,1.���s�E�x������
    row_level_status          NUMBER,                               -- 0.����,1.���s,2.�x��
    row_err_message           VARCHAR2(1000)                        -- �G���[���b�Z�[�W
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_min_date              VARCHAR2(10);    -- �ŏ����t
  gv_max_date              VARCHAR2(10);    -- �ő���t
  gv_crowd_code            VARCHAR2(20);    -- �Q�R�[�h
  gv_policy_group_code     VARCHAR2(20);    -- ����Q�R�[�h
  gv_marke_crowd_code      VARCHAR2(20);    -- �}�[�P�p�Q�R�[�h
  gv_product_div_code      VARCHAR2(20);    -- ���i���i�敪
  gv_arti_div_code         VARCHAR2(20);    -- ���i�敪
  gv_div_tea_code          VARCHAR2(20);    -- �o�����敪
  gv_whse_code             VARCHAR2(20);    -- �����q��
  gv_item_cal              VARCHAR2(20);    -- �J�����_
  gv_cost_div              VARCHAR2(20);    -- �������@
  gv_raw_material_cost     VARCHAR2(20);    -- ����
  gv_agein_cost            VARCHAR2(20);    -- �Đ���
  gv_material_cost         VARCHAR2(20);    -- ���ޔ�
  gv_pack_cost             VARCHAR2(20);    -- ���
  gv_out_order_cost        VARCHAR2(20);    -- �O�����H��
  gv_safekeep_cost         VARCHAR2(20);    -- �ۊǔ�
  gv_other_expense_cost    VARCHAR2(20);    -- ���̑��o��
  gv_spare1                VARCHAR2(20);    -- �\��1
  gv_spare2                VARCHAR2(20);    -- �\��2
  gv_spare3                VARCHAR2(20);    -- �\��3
--
  gd_sysdate               DATE;
  gn_user_id               NUMBER(15);
  gn_login_id              NUMBER(15);
  gn_request_id            NUMBER(15);
  gn_appl_id               NUMBER(15);
  gn_program_id            NUMBER(15);
  gd_min_date              DATE;
  gd_max_date              DATE;
  gv_user_name             VARCHAR2(100);
--
  gt_cmpntcls_mast cmpntcls_tbl; -- �R���|�[�l���g�敪�}�X�^�̃f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
    -- OPM�i�ڃ}�X�^(IC_ITEM_MST_B)
    CURSOR ic_item_mst_b_cur
    IS
      SELECT imb.item_id
      FROM   ic_item_mst_b imb
      WHERE  EXISTS (
        SELECT xif.item_code
        FROM   xxcmn_item_if xif
        WHERE  imb.item_no = xif.item_code
        AND    ROWNUM = 1)
      AND    imb.inactive_ind = gv_inactive_ind_on
      FOR UPDATE OF imb.item_id NOWAIT;
--
    -- OPM�i�ڃA�h�I���}�X�^(XXCMN_ITEM_MST_B)
    CURSOR xxcmn_item_mst_b_cur
    IS
      SELECT xmb.item_id
      FROM   xxcmn_item_mst_b xmb
      WHERE  EXISTS (
        SELECT imb.item_id
        FROM   ic_item_mst_b imb
        WHERE  EXISTS (
          SELECT xif.item_code
          FROM   xxcmn_item_if xif
          WHERE  imb.item_no = xif.item_code
          AND    ROWNUM = 1)
        AND    imb.inactive_ind = gv_inactive_ind_on
        AND    imb.item_id      = xmb.item_id
        AND    ROWNUM = 1)
      FOR UPDATE OF xmb.item_id NOWAIT;
--
    -- OPM�i�ڃJ�e�S������(GMI_ITEM_CATEGORIES)
    CURSOR gmi_item_categories_cur
    IS
      SELECT gic.item_id
      FROM   gmi_item_categories gic
      WHERE  EXISTS (
        SELECT imb.item_id
        FROM   ic_item_mst_b imb
        WHERE  EXISTS (
          SELECT xif.item_code
          FROM   xxcmn_item_if xif
          WHERE  imb.item_no = xif.item_code
          AND    ROWNUM = 1)
        AND    imb.inactive_ind = gv_inactive_ind_on
        AND    imb.item_id      = gic.item_id
        AND    ROWNUM = 1)
      FOR UPDATE OF gic.item_id NOWAIT;
--
    -- �i�ڌ����}�X�^(CM_CMPT_DTL)
    CURSOR cm_cmpt_dtl_cur
    IS
      SELECT ccd.item_id
      FROM   cm_cmpt_dtl ccd
      WHERE  EXISTS (
        SELECT imb.item_id
        FROM   ic_item_mst_b imb
        WHERE  EXISTS (
          SELECT xif.item_code
          FROM   xxcmn_item_if xif
          WHERE  imb.item_no = xif.item_code
          AND    ROWNUM = 1)
        AND    imb.item_id = ccd.item_id
        AND    imb.inactive_ind = gv_inactive_ind_on
        AND    ROWNUM = 1)
      AND    ccd.whse_code      = gv_whse_code
      AND    ccd.calendar_code  = gv_item_cal
      AND    ccd.cost_mthd_code = gv_cost_div
      AND    ccd.cost_level     = gv_cost_level_on
      FOR UPDATE OF ccd.item_id NOWAIT;
--
  /**********************************************************************************
   * Procedure Name   : put_api_log
   * Description      : �W��API���O�o��API�v���V�[�W��
   ***********************************************************************************/
  PROCEDURE put_api_log(
    ov_errbuf   OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_api_log'; -- �v���O������
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
    lv_msg            VARCHAR2(2000);
    ln_dummy_cnt      NUMBER(10);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
    <<count_msg_loop>>
    FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
IF (i <> 3) THEN
      -- ���b�Z�[�W�擾
      FND_MSG_PUB.GET(
             p_msg_index      => i
            ,p_encoded        => FND_API.G_FALSE
            ,p_data           => lv_msg
            ,p_msg_index_out  => ln_dummy_cnt
      );
      -- ���O�o��
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
END IF;
--
    END LOOP count_msg_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_api_log;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : �v���t�@�C�����MAX���t,MIN���t���擾���܂��B
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_min_date  VARCHAR2(10);
    lv_max_date  VARCHAR2(10);
    lv_role_id   VARCHAR2(1);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�ő���t�擾
    gv_max_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_max_date),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_max_date := FND_DATE.STRING_TO_DATE(gv_max_date,'YYYY/MM/DD');
--
    --�ŏ����t�擾
    gv_min_date := SUBSTR(FND_PROFILE.VALUE(gv_prf_min_date),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_min_date := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
--
    --�J�e�S���Z�b�g��(�Q�R�[�h)
    gv_crowd_code := FND_PROFILE.VALUE(gv_prf_category_name_otgun);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_crowd_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_crowd_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�J�e�S���Z�b�g��(����Q�R�[�h)
    gv_policy_group_code := FND_PROFILE.VALUE(gv_prf_policy_group_code);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_policy_group_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_policy_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�J�e�S���Z�b�g��(�}�[�P�p�Q�R�[�h)
    gv_marke_crowd_code := FND_PROFILE.VALUE(gv_prf_marke_crowd_code);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_marke_crowd_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_marke_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�J�e�S���Z�b�g��(���i���i�敪)
    gv_product_div_code := FND_PROFILE.VALUE(gv_prf_product_div_code);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_product_div_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_product_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�J�e�S���Z�b�g��(�{�Џ��i�敪)
    gv_arti_div_code := FND_PROFILE.VALUE(gv_prf_arti_div_code);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_arti_div_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_arti_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�J�e�S���Z�b�g��(�o�����敪)
    gv_div_tea_code := FND_PROFILE.VALUE(gv_prf_div_tea_code);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_div_tea_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_tea_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�����q��
    gv_whse_code := FND_PROFILE.VALUE(gv_prf_cost_price_whse_code);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_whse_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_whse_code_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�J�����_
    gv_item_cal := FND_PROFILE.VALUE(gv_prf_item_cal);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_item_cal IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_item_cal_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�������@
    gv_cost_div := FND_PROFILE.VALUE(gv_prf_cost_div);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_cost_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_cost_div_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --����
    gv_raw_material_cost := FND_PROFILE.VALUE(gv_prf_raw_material_cost);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_raw_material_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_raw_mat_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�Đ���
    gv_agein_cost := FND_PROFILE.VALUE(gv_prf_agein_cost);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_agein_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_agein_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --���ޔ�
    gv_material_cost := FND_PROFILE.VALUE(gv_prf_material_cost);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_material_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_material_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --���
    gv_pack_cost := FND_PROFILE.VALUE(gv_prf_pack_cost);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_pack_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_pack_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�O�����H��
    gv_out_order_cost := FND_PROFILE.VALUE(gv_prf_out_order_cost);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_out_order_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_out_order_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�ۊǔ�
    gv_safekeep_cost := FND_PROFILE.VALUE(gv_prf_safekeep_cost);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_safekeep_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_safekeep_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --���̑��o��
    gv_other_expense_cost := FND_PROFILE.VALUE(gv_prf_other_expense_cost);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_other_expense_cost IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_other_cost_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�\��1
    gv_spare1 := FND_PROFILE.VALUE(gv_prf_spare1);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_spare1 IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_spare1_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�\��2
    gv_spare2 := FND_PROFILE.VALUE(gv_prf_spare2);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_spare2 IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_spare2_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�\��3
    gv_spare3 := FND_PROFILE.VALUE(gv_prf_spare3);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_spare3 IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80b_012,
                                            gv_tkn_ng_profile, gv_prf_spare3_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_profile;
--
  /***********************************************************************************
   * Procedure Name   : set_if_lock
   * Description      : �i�ڃC���^�t�F�[�X�̃e�[�u�����b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE set_if_lock(
    ov_errbuf   OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_if_lock'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd    BOOLEAN;
    ln_item_id  ic_item_mst_b.item_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lb_retcd := TRUE;
--
    -- �e�[�u�����b�N����(�i�ڃC���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_item_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                            gv_tkn_table, gv_xxcmn_item_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- OPM�i�ڃ}�X�^(IC_ITEM_MST_B)
    BEGIN
--
      OPEN ic_item_mst_b_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_ic_item_mst_b_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- OPM�i�ڃA�h�I���}�X�^(XXCMN_ITEM_MST_B)
    BEGIN
--
      OPEN xxcmn_item_mst_b_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_xxcmn_item_mst_b_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- OPM�i�ڃJ�e�S������(GMI_ITEM_CATEGORIES)
    BEGIN
--
      OPEN gmi_item_categories_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_gmi_item_category_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- �i�ڌ����}�X�^(CM_CMPT_DTL)
    BEGIN
--
      OPEN cm_cmpt_dtl_cur;
--
    EXCEPTION
--
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_014,
                                              gv_tkn_table, gv_cm_cmpt_dtl_name);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_if_lock;
--
  /***********************************************************************************
   * Procedure Name   : set_error_status
   * Description      : �G���[������������Ԃɂ��܂��B
   ***********************************************************************************/
  PROCEDURE set_error_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    iv_message    IN            VARCHAR2,    -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_error_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.file_level_status := gn_data_status_error;
    ir_status_rec.row_level_status  := gn_data_status_error;
    ir_status_rec.row_err_message   := iv_message;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_error_status;
--
  /***********************************************************************************
   * Procedure Name   : set_warn_status
   * Description      : �x��������������Ԃɂ��܂��B
   ***********************************************************************************/
  PROCEDURE set_warn_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    iv_message    IN            VARCHAR2,    -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_warn_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.row_level_status  := gn_data_status_warn;
    ir_status_rec.row_err_message   := iv_message;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_warn_status;
--
  /***********************************************************************************
   * Procedure Name   : set_warok_status
   * Description      : �x��������������Ԃɂ��܂��B
   ***********************************************************************************/
  PROCEDURE set_warok_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    iv_message    IN            VARCHAR2,    -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_warok_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.row_level_status  := gn_data_status_warok;
    ir_status_rec.row_err_message   := iv_message;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_warok_status;
--
  /***********************************************************************************
   * Function Name    : is_file_status_nomal
   * Description      : �t�@�C�����x���Ő���ȏ�Ԃł��邩��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION is_file_status_nomal(
    ir_status_rec  IN status_rec)  -- ������
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_file_status_nomal'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.file_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END is_file_status_nomal;
--
  /***********************************************************************************
   * Procedure Name   : init_row_status
   * Description      : �s���x���̃X�e�[�^�X�����������܂��B
   ***********************************************************************************/
  PROCEDURE init_row_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_row_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_row_status;
--
  /***********************************************************************************
   * Function Name    : is_row_status_nomal
   * Description      : �s���x���Ő���ȏ�Ԃł��邩��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION is_row_status_nomal(
    ir_status_rec  IN status_rec)  -- ������
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_nomal'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_nomal) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END is_row_status_nomal;
--
  /***********************************************************************************
   * Function Name    : is_row_status_warn
   * Description      : �s���x���Ōx����Ԃł��邩��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION is_row_status_warn(
    ir_status_rec  IN status_rec)  -- ������
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_warn'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd    BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_warn) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END is_row_status_warn;
--
  /***********************************************************************************
   * Function Name    : is_row_status_warok
   * Description      : �s���x���Ōx����Ԃł��邩��Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION is_row_status_warok(
    ir_status_rec  IN status_rec)  -- ������
    RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'is_row_status_warok'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd    BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- ***************************************
    -- ***      �������W�b�N�̋L�q         ***
    -- ***************************************
    lb_retcd := FALSE;
--
    IF (ir_status_rec.row_level_status = gn_data_status_warok) THEN
      lb_retcd := TRUE;
    END IF;
--
    RETURN lb_retcd;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  �Œ蕔 END   #############################################
--
  END is_row_status_warok;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : ���|�[�g�p�f�[�^��ݒ肵�܂��B
   ***********************************************************************************/
  PROCEDURE add_report(
    ir_status_rec  IN            status_rec,
    ir_masters_rec IN            masters_rec,
    it_report_tbl  IN OUT NOCOPY report_tbl,
    ov_errbuf      OUT    NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_report_rec report_rec;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���|�[�g���R�[�h�ɒl��ݒ�
    lr_report_rec.seq_number           := ir_masters_rec.seq_number;
    lr_report_rec.proc_code            := ir_masters_rec.proc_code;
    lr_report_rec.item_code            := ir_masters_rec.item_code;
    lr_report_rec.item_name            := ir_masters_rec.item_name;
    lr_report_rec.item_short_name      := ir_masters_rec.item_short_name;
    lr_report_rec.item_name_alt        := ir_masters_rec.item_name_alt;
    lr_report_rec.old_crowd_code       := ir_masters_rec.old_crowd_code;
    lr_report_rec.new_crowd_code       := ir_masters_rec.new_crowd_code;
    lr_report_rec.crowd_start_date     := ir_masters_rec.crowd_start_date;
    lr_report_rec.policy_group_code    := ir_masters_rec.policy_group_code;
    lr_report_rec.marke_crowd_code     := ir_masters_rec.marke_crowd_code;
    lr_report_rec.old_price            := ir_masters_rec.old_price;
    lr_report_rec.new_price            := ir_masters_rec.new_price;
    lr_report_rec.price_start_date     := ir_masters_rec.price_start_date;
    lr_report_rec.old_standard_cost    := ir_masters_rec.old_standard_cost;
    lr_report_rec.new_standard_cost    := ir_masters_rec.new_standard_cost;
    lr_report_rec.standard_start_date  := ir_masters_rec.standard_start_date;
    lr_report_rec.old_business_cost    := ir_masters_rec.old_business_cost;
    lr_report_rec.new_business_cost    := ir_masters_rec.new_business_cost;
    lr_report_rec.business_start_date  := ir_masters_rec.business_start_date;
    lr_report_rec.old_tax              := ir_masters_rec.old_tax;
    lr_report_rec.new_tax              := ir_masters_rec.new_tax;
    lr_report_rec.tax_start_date       := ir_masters_rec.tax_start_date;
    lr_report_rec.rate_code            := ir_masters_rec.rate_code;
    lr_report_rec.case_num             := ir_masters_rec.case_num;
    lr_report_rec.product_div_code     := ir_masters_rec.product_div_code;
    lr_report_rec.net                  := ir_masters_rec.net;
    lr_report_rec.weight_volume        := ir_masters_rec.weight_volume;
    lr_report_rec.arti_div_code        := ir_masters_rec.arti_div_code;
    lr_report_rec.div_tea_code         := ir_masters_rec.div_tea_code;
    lr_report_rec.parent_item_code     := ir_masters_rec.parent_item_code;
    lr_report_rec.sale_obj_code        := ir_masters_rec.sale_obj_code;
    lr_report_rec.jan_code             := ir_masters_rec.jan_code;
    lr_report_rec.sale_start_date      := ir_masters_rec.sale_start_date;
    lr_report_rec.abolition_code       := ir_masters_rec.abolition_code;
    lr_report_rec.abolition_date       := ir_masters_rec.abolition_date;
    lr_report_rec.raw_mate_consumption := ir_masters_rec.raw_mate_consumption;
    lr_report_rec.raw_material_cost    := ir_masters_rec.raw_material_cost;
    lr_report_rec.agein_cost           := ir_masters_rec.agein_cost;
    lr_report_rec.material_cost        := ir_masters_rec.material_cost;
    lr_report_rec.pack_cost            := ir_masters_rec.pack_cost;
    lr_report_rec.out_order_cost       := ir_masters_rec.out_order_cost;
    lr_report_rec.safekeep_cost        := ir_masters_rec.safekeep_cost;
    lr_report_rec.other_expense_cost   := ir_masters_rec.other_expense_cost;
    lr_report_rec.spare1               := ir_masters_rec.spare1;
    lr_report_rec.spare2               := ir_masters_rec.spare2;
    lr_report_rec.spare3               := ir_masters_rec.spare3;
    lr_report_rec.spare                := ir_masters_rec.spare;
--
    lr_report_rec.row_level_status     := ir_status_rec.row_level_status;
    lr_report_rec.message              := ir_status_rec.row_err_message;
--
    lr_report_rec.imb_flg              := 0;
    lr_report_rec.xmb_flg              := 0;
    lr_report_rec.gic_flg              := 0;
    lr_report_rec.ccd_flg              := 0;
--
    -- ���|�[�g�e�[�u���ɒǉ�
    it_report_tbl(gn_report_cnt) := lr_report_rec;
    gn_report_cnt := gn_report_cnt + 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂��B
   ***********************************************************************************/
  PROCEDURE disp_report(
    it_report_tbl  IN         report_tbl,   -- ���b�Z�[�W�e�[�u��
    disp_kbn       IN         NUMBER,       -- �\���Ώۋ敪(0:����,1:�ُ�,2:�x��)
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_report_rec report_rec;
    ln_disp_cnt   NUMBER;
    lv_dspbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- ����
    IF (disp_kbn = gn_data_status_nomal) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_004);
--
    -- �G���[
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_005);
--
    -- �x��
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_006);
--
    -- ����E�x������
    ELSIF (disp_kbn = gn_data_status_warok) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_021);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �ݒ肳��Ă��郌�|�[�g�̏o��
    <<disp_report_loop>>
    FOR ln_disp_cnt IN 0..gn_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(ln_disp_cnt);
--
      --���̓f�[�^�̍č\��
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number)  || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.proc_code)   || gv_msg_pnt ||
                   lr_report_rec.item_code            || gv_msg_pnt ||
                   lr_report_rec.item_name            || gv_msg_pnt ||
                   lr_report_rec.item_short_name      || gv_msg_pnt ||
                   lr_report_rec.item_name_alt        || gv_msg_pnt ||
                   lr_report_rec.old_crowd_code       || gv_msg_pnt ||
                   lr_report_rec.new_crowd_code       || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.crowd_start_date,'YYYY/MM/DD')     || gv_msg_pnt ||
                   lr_report_rec.policy_group_code    || gv_msg_pnt ||
                   lr_report_rec.marke_crowd_code     || gv_msg_pnt ||
                   lr_report_rec.old_price            || gv_msg_pnt ||
                   lr_report_rec.new_price            || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.price_start_date,'YYYY/MM/DD')     || gv_msg_pnt ||
                   lr_report_rec.old_standard_cost    || gv_msg_pnt ||
                   lr_report_rec.new_standard_cost    || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.standard_start_date,'YYYY/MM/DD')  || gv_msg_pnt ||
                   lr_report_rec.old_business_cost    || gv_msg_pnt ||
                   lr_report_rec.new_business_cost    || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.business_start_date,'YYYY/MM/DD')  || gv_msg_pnt ||
                   lr_report_rec.old_tax              || gv_msg_pnt ||
                   lr_report_rec.new_tax              || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.tax_start_date,'YYYY/MM/DD')       || gv_msg_pnt ||
                   lr_report_rec.rate_code            || gv_msg_pnt ||
                   lr_report_rec.case_num             || gv_msg_pnt ||
                   lr_report_rec.product_div_code     || gv_msg_pnt ||
                   lr_report_rec.net                  || gv_msg_pnt ||
                   lr_report_rec.weight_volume        || gv_msg_pnt ||
                   lr_report_rec.arti_div_code        || gv_msg_pnt ||
                   lr_report_rec.div_tea_code         || gv_msg_pnt ||
                   lr_report_rec.parent_item_code     || gv_msg_pnt ||
                   lr_report_rec.sale_obj_code        || gv_msg_pnt ||
                   lr_report_rec.jan_code             || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.sale_start_date,'YYYY/MM/DD')      || gv_msg_pnt ||
                   lr_report_rec.abolition_code       || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.abolition_date,'YYYY/MM/DD')       || gv_msg_pnt ||
                   lr_report_rec.raw_mate_consumption || gv_msg_pnt ||
                   lr_report_rec.raw_material_cost    || gv_msg_pnt ||
                   lr_report_rec.agein_cost           || gv_msg_pnt ||
                   lr_report_rec.material_cost        || gv_msg_pnt ||
                   lr_report_rec.pack_cost            || gv_msg_pnt ||
                   lr_report_rec.out_order_cost       || gv_msg_pnt ||
                   lr_report_rec.safekeep_cost        || gv_msg_pnt ||
                   lr_report_rec.other_expense_cost   || gv_msg_pnt ||
                   lr_report_rec.spare1               || gv_msg_pnt ||
                   lr_report_rec.spare2               || gv_msg_pnt ||
                   lr_report_rec.spare3               || gv_msg_pnt || lr_report_rec.spare;
--
      -- �Ώ�
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        IF ((disp_kbn = gn_data_status_nomal) OR (disp_kbn = gn_data_status_warok)) THEN
          -- OPM�i�ڃ}�X�^
          IF (lr_report_rec.imb_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_ic_item_mst_b_name);
          END IF;
          -- OPM�i�ڃA�h�I���}�X�^
          IF (lr_report_rec.xmb_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_item_mst_b_name);
          END IF;
          -- OPM�i�ڃJ�e�S������
          IF (lr_report_rec.gic_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_gmi_item_category_name);
          END IF;
          -- �i�ڌ����}�X�^
          IF (lr_report_rec.ccd_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_cm_cmpt_dtl_name);
          END IF;
        END IF;
--
        -- ����ȊO
        IF (disp_kbn <> gn_data_status_nomal) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
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
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_item_if
   * Description      : �i�ڃC���^�t�F�[�X�̉ߋ��̌����擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_xxcmn_item_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_item_if'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      ir_masters_rec.row_ins_cnt := 0;
      ir_masters_rec.row_upd_cnt := 0;
      ir_masters_rec.row_del_cnt := 0;
--
      -- �Ј��C���^�t�F�[�X
      SELECT SUM(NVL(DECODE(xei.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xei.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_ins_cnt,
             ir_masters_rec.row_upd_cnt,
             ir_masters_rec.row_del_cnt
      FROM   xxcmn_item_if xei
      WHERE  xei.item_code = ir_masters_rec.item_code         -- �i�ڃR�[�h������
      AND    xei.seq_number < ir_masters_rec.seq_number       -- SEQ�ԍ����ȑO�̃f�[�^
      GROUP BY xei.item_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_ins_cnt := 0;
        ir_masters_rec.row_upd_cnt := 0;
        ir_masters_rec.row_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_xxcmn_item_if;
--
  /***********************************************************************************
   * Procedure Name   : chk_ic_item_mst_b
   * Description      : �i�ڃR�[�h�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_ic_item_mst_b(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_ic_item_mst_b'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    ov_retcd := FALSE;
--
    -- �o�^
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(iimb.item_id)
      INTO   ln_cnt
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no = ir_masters_rec.item_code
      AND    ROWNUM       = 1;
--
    -- �o�^�ȊO
    ELSE
      SELECT COUNT(iimb.item_id)
      INTO   ln_cnt
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no      = ir_masters_rec.item_code
      AND    iimb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM            = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END chk_ic_item_mst_b;
--
  /***********************************************************************************
   * Procedure Name   : chk_xxcmn_item_mst_b
   * Description      : �i�ڃR�[�h�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_xxcmn_item_mst_b(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_xxcmn_item_mst_b'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    ov_retcd := FALSE;
--
    -- �o�^
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(ximb.item_id)
      INTO   ln_cnt
      FROM   xxcmn_item_mst_b ximb,
             ic_item_mst_b iimb
      WHERE  iimb.item_no = ir_masters_rec.item_code
      AND    ximb.item_id = iimb.item_id
      AND    ROWNUM       = 1;
--
    -- �o�^�ȊO
    ELSE
      SELECT COUNT(ximb.item_id)
      INTO   ln_cnt
      FROM   xxcmn_item_mst_b ximb,
             ic_item_mst_b iimb
      WHERE  iimb.item_no      = ir_masters_rec.item_code
      AND    ximb.item_id      = iimb.item_id
      AND    iimb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM            = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END chk_xxcmn_item_mst_b;
--
  /***********************************************************************************
   * Procedure Name   : chk_gmi_item_category
   * Description      : �i�ڃR�[�h�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_gmi_item_category(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_gmi_item_category'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    ov_retcd := FALSE;
--
    -- �o�^
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(gic.item_id)
      INTO   ln_cnt
      FROM   gmi_item_categories gic,
             ic_item_mst_b iimb
      WHERE  iimb.item_no = ir_masters_rec.item_code
      AND    gic.item_id  = iimb.item_id
      AND    ROWNUM       = 1;
--
    -- �o�^�ȊO
    ELSE
      SELECT COUNT(gic.item_id)
      INTO   ln_cnt
      FROM   gmi_item_categories gic,
             ic_item_mst_b iimb
      WHERE  iimb.item_no      = ir_masters_rec.item_code
      AND    gic.item_id       = iimb.item_id
      AND    iimb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM            = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END chk_gmi_item_category;
--
  /***********************************************************************************
   * Procedure Name   : chk_cm_cmpt_dtl
   * Description      : �i�ڃR�[�h�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_cm_cmpt_dtl(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    lb_cmpnt_id     IN            NUMBER,       -- �R���|�[�l���g�敪ID
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cm_cmpt_dtl'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    ov_retcd := FALSE;
--
    -- �o�^
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
      SELECT COUNT(ccd.item_id)
      INTO   ln_cnt
      FROM   cm_cmpt_dtl ccd,
             ic_item_mst_b iimb
      WHERE  iimb.item_no = ir_masters_rec.item_code
      AND    ccd.item_id  = iimb.item_id
      AND    ROWNUM       = 1;
--
    -- �o�^�ȊO
    ELSE
      SELECT COUNT(ccd.item_id)
      INTO   ln_cnt
      FROM   cm_cmpt_dtl ccd,
             ic_item_mst_b iimb
      WHERE  iimb.item_no         = ir_masters_rec.item_code
      AND    ccd.item_id          = iimb.item_id
      AND    iimb.inactive_ind    = gv_inactive_ind_on
      AND    ccd.cost_cmpntcls_id = lb_cmpnt_id
      AND    ROWNUM               = 1;
    END IF;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END chk_cm_cmpt_dtl;
--
  /***********************************************************************************
   * Procedure Name   : chk_parent_id
   * Description      : �i��ID�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_parent_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_parent_id'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt   NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    ov_retcd := FALSE;
--
    -- OPM�i�ڃ}�X�^�̑��݃`�F�b�N
    SELECT COUNT(imb.item_id)
    INTO   ln_cnt
    FROM   ic_item_mst_b imb
    WHERE  imb.item_no      = ir_masters_rec.parent_item_code
    AND    imb.inactive_ind = gv_inactive_ind_on
    AND    ROWNUM           = 1;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
--
    ELSE
--
      -- �������g�̕i�ڃR�[�h�ƈ�v
      IF (ir_masters_rec.item_code = ir_masters_rec.parent_item_code) THEN
        ov_retcd := TRUE;
--
      ELSE
--
        -- �ȑO�ɑ��݂��Ă���
        SELECT COUNT(xif.seq_number)
        INTO   ln_cnt
        FROM   xxcmn_item_if xif
        WHERE  xif.item_code   = ir_masters_rec.parent_item_code
        AND    xif.seq_number <= ir_masters_rec.seq_number
        AND    (xif.proc_code  = gn_proc_insert
        OR      xif.proc_code  = gn_proc_update)
        AND    ROWNUM          = 1;
--
        IF (ln_cnt > 0) THEN
          ov_retcd := TRUE;
        END IF;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END chk_parent_id;
--
  /***********************************************************************************
   * Procedure Name   : check_proc_code
   * Description      : ����Ώۂ̃f�[�^�ł��邱�Ƃ��m�F���܂��B
   ***********************************************************************************/
  PROCEDURE check_proc_code(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN            masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_proc_code'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�����敪��(�o�^�E�X�V�E�폜)�ȊO
    IF ((ir_masters_rec.proc_code <> gn_proc_insert)
    AND (ir_masters_rec.proc_code <> gn_proc_update)
    AND (ir_masters_rec.proc_code <> gn_proc_delete)) THEN
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_016,
                                                'VALUE',    TO_CHAR(ir_masters_rec.proc_code)),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_proc_code;
--
  /***********************************************************************************
   * Procedure Name   : get_user_name
   * Description      : ���[�U�[���̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_user_name(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_name'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      SELECT user_name
      INTO   gv_user_name
      FROM   fnd_user
      WHERE  user_id = gn_user_id
      AND    ROWNUM  = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_user_name := NULL;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_user_name;
--
  /***********************************************************************************
   * Procedure Name   : init_cmpntcls_id
   * Description      : �R���|�[�l���g�敪ID�̏����擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE init_cmpntcls_id(
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_cmpntcls_id'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt      NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cmpnt_cur
    IS
      SELECT ccmt.cost_cmpntcls_id,
             ccm.cost_cmpntcls_code,
             ccmt.cost_cmpntcls_desc
      FROM   cm_cmpt_mst_tl ccmt,
             cm_cmpt_mst ccm
      WHERE  ccmt.cost_cmpntcls_id   = ccm.cost_cmpntcls_id
      AND    ccmt.language           = gv_language
      ORDER BY ccmt.cost_cmpntcls_id;
--
    -- *** ���[�J���E���R�[�h ***
    lr_cmpnt_rec cmpnt_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_cnt := 1;
--
    OPEN cmpnt_cur;
--
    <<cmpnt_loop>>
    LOOP
      FETCH cmpnt_cur INTO lr_cmpnt_rec;
      EXIT WHEN cmpnt_cur%NOTFOUND;
--
      gt_cmpntcls_mast(ln_cnt).cost_cmpntcls_id   := lr_cmpnt_rec.cost_cmpntcls_id;
      gt_cmpntcls_mast(ln_cnt).cost_cmpntcls_code := lr_cmpnt_rec.cost_cmpntcls_code;
      gt_cmpntcls_mast(ln_cnt).cost_cmpntcls_desc := lr_cmpnt_rec.cost_cmpntcls_desc;
--
      ln_cnt := ln_cnt + 1;
--
    END LOOP cmpnt_loop;
--
    CLOSE cmpnt_cur;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_cmpntcls_id;
--
  /***********************************************************************************
   * Procedure Name   : get_price
   * Description      : �P���̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_price(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    iv_expense_type IN            VARCHAR2,     -- �Ώ۔�ڋ敪
    on_price           OUT NOCOPY NUMBER,       -- �P��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_price'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_price      NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      SELECT SUM(xpl.unit_price)
      INTO   ln_price
      FROM   xxpo_price_headers xph,
             xxpo_price_lines xpl,
             fnd_lookup_values flv
      WHERE  xph.price_header_id   = xpl.price_header_id
      AND    xph.price_type        = flv.lookup_code
      AND    xph.item_code         = ir_masters_rec.item_code
      AND    xpl.expense_item_type = iv_expense_type
      AND    flv.lookup_type       = gv_lookup_type
      AND    flv.meaning           = gv_meaning
      AND    flv.language          = gv_language
      AND    flv.lookup_code       = gv_lookup_code;
--
      on_price := ln_price;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_price := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_price;
--
  /***********************************************************************************
   * Procedure Name   : get_item_id
   * Description      : �i��ID�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_item_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_id'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      SELECT imb.item_id
      INTO   ir_masters_rec.item_id
      FROM   ic_item_mst_b imb
      WHERE  imb.item_no      = ir_masters_rec.item_code
      AND    imb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM           = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.item_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_item_id;
--
  /***********************************************************************************
   * Procedure Name   : get_parent_id
   * Description      : �i��ID�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_parent_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_parent_id'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      SELECT imb.item_id
      INTO   ir_masters_rec.parent_item_id
      FROM   ic_item_mst_b imb
      WHERE  imb.item_no      = ir_masters_rec.parent_item_code
      AND    imb.inactive_ind = gv_inactive_ind_on
      AND    ROWNUM           = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.parent_item_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_parent_id;
--
  /***********************************************************************************
   * Procedure Name   : get_period_code
   * Description      : ���Ԃ̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_period_code(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_code'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      SELECT ccd.period_code
      INTO   ir_masters_rec.period_code
      FROM   cm_cldr_dtl ccd
      WHERE  ccd.calendar_code = gv_item_cal
      AND    ccd.start_date   <= ir_masters_rec.standard_start_date
      AND    ccd.end_date     >= ir_masters_rec.standard_start_date
      AND    ROWNUM            = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.period_code := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_period_code;
--
  /***********************************************************************************
   * Procedure Name   : get_uom_code
   * Description      : �P�ʂ̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_uom_code(
    on_uom_code        OUT NOCOPY VARCHAR2,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_uom_code'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      SELECT mum.uom_code
      INTO   on_uom_code
      FROM   msc_units_of_measure mum
      WHERE  mum.description = gv_description
      AND    ROWNUM          = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_uom_code := gv_def_item_um;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_uom_code;
--
  /***********************************************************************************
   * Procedure Name   : get_cmpnt_id
   * Description      : �����ڍ�ID���̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_cmpnt_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cmpnt_id'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
--
      SELECT ccd.cmpntcost_id
      INTO   ir_masters_rec.cmpntcost_id
      FROM   cm_cmpt_dtl ccd
      WHERE  ccd.item_id          = ir_masters_rec.item_id
      AND    ccd.cost_cmpntcls_id = ir_masters_rec.cost_id
      AND    ccd.period_code      = ir_masters_rec.period_code
      AND    ccd.whse_code        = gv_whse_code
      AND    ccd.calendar_code    = gv_item_cal
      AND    ccd.cost_mthd_code   = gv_cost_div
      AND    ROWNUM               = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.cmpntcost_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_cmpnt_id;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxcmn_item_mst
   * Description      : OPM�i�ڃA�h�I���}�X�^�̏������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_xxcmn_item_mst(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    in_kbn          IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxcmn_item_mst'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �e�i��ID�̎擾
    get_parent_id(ir_masters_rec,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �o�^
    IF (in_kbn = gn_proc_insert) THEN
      INSERT INTO xxcmn_item_mst_b
         (item_id
         ,start_date_active
         ,end_date_active
         ,active_flag
         ,item_name
         ,item_short_name
         ,item_name_alt
         ,parent_item_id
         ,obsolete_class
         ,obsolete_date
         ,rate_class
         ,raw_material_consumption
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,request_id
         ,program_application_id
         ,program_id
         ,program_update_date
      ) VALUES (
          ir_masters_rec.item_id                                      -- �i��ID
         ,gd_min_date                                                 -- �^�p�J�n��
         ,gd_max_date                                                 -- �^�p�I����
         ,gv_active_flag_mi                                           -- �K�p�σt���O
         ,ir_masters_rec.item_name                                    -- ������
         ,ir_masters_rec.item_short_name                              -- ����
         ,ir_masters_rec.item_name_alt                                -- �J�i��
         ,ir_masters_rec.parent_item_id                               -- �e�i��ID
         ,ir_masters_rec.abolition_code                               -- �p�~�敪
         ,ir_masters_rec.abolition_date                               -- �p�~��(�������~)
         ,ir_masters_rec.rate_code                                    -- ���敪
         ,ir_masters_rec.raw_mate_consumption                         -- �����g�p��
         ,gn_user_id
         ,gd_sysdate
         ,gn_user_id
         ,gd_sysdate
         ,gn_login_id
         ,gn_request_id
         ,gn_appl_id
         ,gn_program_id
         ,gd_sysdate
      );
--
    -- �X�V
    ELSIF (in_kbn = gn_proc_update) THEN
      UPDATE xxcmn_item_mst_b
      SET    item_name                = ir_masters_rec.item_name            -- ������
            ,item_short_name          = ir_masters_rec.item_short_name      -- ����
            ,item_name_alt            = ir_masters_rec.item_name_alt        -- �J�i��
            ,parent_item_id           = ir_masters_rec.parent_item_id       -- �e�i��ID
            ,obsolete_class           = ir_masters_rec.abolition_code       -- �p�~�敪
            ,obsolete_date            = ir_masters_rec.abolition_date       -- �p�~��(�������~)
            ,rate_class               = ir_masters_rec.rate_code            -- ���敪
            ,raw_material_consumption = ir_masters_rec.raw_mate_consumption -- �����g�p��
            ,last_updated_by          = gn_user_id
            ,last_update_date         = gd_sysdate
            ,last_update_login        = gn_login_id
            ,request_id               = gn_request_id
            ,program_application_id   = gn_appl_id
            ,program_id               = gn_program_id
            ,program_update_date      = gd_sysdate
      WHERE  item_id = ir_masters_rec.item_id;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_xxcmn_item_mst;
--
  /***********************************************************************************
   * Procedure Name   : proc_item_category
   * Description      : OPM�i�ڃJ�e�S�������̏������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_item_category(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    in_kbn          IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_item_category'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR category_cur
    IS
       SELECT mcsb.category_set_id,
              mcb.category_id
       FROM   mtl_category_sets_tl mcst,
              mtl_category_sets_b mcsb,
              mtl_categories_b mcb
       WHERE  mcsb.category_set_id = mcst.category_set_id
       AND    mcsb.structure_id    = mcb.structure_id
       AND    mcst.language        = gv_language
       AND    (mcst.description, mcb.segment1 ) IN 
              ((gv_crowd_code,        ir_masters_rec.old_crowd_code),    -- �Q�R�[�h
               (gv_policy_group_code, ir_masters_rec.policy_group_code), -- ����Q�R�[�h
               (gv_marke_crowd_code,  ir_masters_rec.marke_crowd_code),  -- �}�[�P�p�Q�R�[�h
               (gv_product_div_code,  ir_masters_rec.product_div_code),  -- ���i���i�敪
               (gv_arti_div_code,     ir_masters_rec.arti_div_code),     -- �{�Џ��i�敪
               (gv_div_tea_code,      ir_masters_rec.div_tea_code)       -- �o�����敪
              );
--
    -- *** ���[�J���E���R�[�h ***
    lr_category_rec category_cur%ROWTYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    OPEN category_cur;
--
    <<category_loop>>
    LOOP
      FETCH category_cur INTO lr_category_rec;
      EXIT WHEN category_cur%NOTFOUND;
--
      -- �o�^
      IF (in_kbn = gn_proc_insert) THEN
        INSERT INTO gmi_item_categories
           (item_id
           ,category_set_id
           ,category_id
           ,created_by
           ,creation_date
           ,last_updated_by
           ,last_update_date
           ,last_update_login)
        VALUES (
            ir_masters_rec.item_id
           ,lr_category_rec.category_set_id
           ,lr_category_rec.category_id
           ,gn_user_id
           ,gd_sysdate
           ,gn_user_id
           ,gd_sysdate
           ,gn_login_id);
--
      -- �X�V
      ELSIF (in_kbn = gn_proc_update) THEN
        UPDATE gmi_item_categories
        SET    category_id       = lr_category_rec.category_id
              ,last_updated_by   = gn_user_id
              ,last_update_date  = gd_sysdate
              ,last_update_login = gn_login_id
        WHERE  item_id         = ir_masters_rec.item_id
        AND    category_set_id = lr_category_rec.category_set_id;
      END IF;
--
    END LOOP category_loop;
--
    CLOSE category_cur;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (category_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE category_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (category_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE category_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (category_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE category_cur;
      END IF;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_item_category;
--
  /***********************************************************************************
   * Procedure Name   : proc_ic_item_mst
   * Description      : OPM�i�ڃ}�X�^�̏������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_ic_item_mst(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    in_kbn          IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ic_item_mst'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_attribute10             ic_item_mst_b.attribute10%TYPE;
    lv_attribute16             ic_item_mst_b.attribute16%TYPE;
    lv_attribute25             ic_item_mst_b.attribute25%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �X�V
    IF (in_kbn = gn_proc_update) THEN
--
      -- ���i�敪�����[�t
      IF (ir_masters_rec.arti_div_code = gv_div_code_reef) THEN
        lv_attribute10 := gv_rate_code_reef;
        lv_attribute16 := ir_masters_rec.weight_volume;
        lv_attribute25 := NULL;
      ELSE
        lv_attribute10 := gv_rate_code_drink;
        lv_attribute16 := NULL;
        lv_attribute25 := ir_masters_rec.weight_volume;
      END IF;
--
      UPDATE ic_item_mst_b
      SET    item_desc1             = ir_masters_rec.item_name
            ,attribute1             = ir_masters_rec.old_crowd_code
            ,attribute2             = ir_masters_rec.new_crowd_code
            ,attribute3             = ir_masters_rec.crowd_start_days
            ,attribute4             = ir_masters_rec.old_price
            ,attribute5             = ir_masters_rec.new_price
            ,attribute6             = ir_masters_rec.price_start_days
            ,attribute7             = ir_masters_rec.old_business_cost
            ,attribute8             = ir_masters_rec.new_business_cost
            ,attribute9             = ir_masters_rec.buis_start_days
            ,attribute10            = lv_attribute10
            ,attribute11            = ir_masters_rec.case_num
            ,attribute12            = ir_masters_rec.net
            ,attribute13            = ir_masters_rec.sale_start_days
            ,attribute16            = lv_attribute16
            ,attribute21            = ir_masters_rec.jan_code
            ,attribute25            = lv_attribute25
            ,attribute26            = ir_masters_rec.sale_obj_code
            ,inactive_ind           = gv_inactive_ind_on
            ,last_updated_by        = gn_user_id
            ,last_update_date       = gd_sysdate
            ,last_update_login      = gn_login_id
            ,request_id             = gn_request_id
            ,program_application_id = gn_appl_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_sysdate
      WHERE  item_id = ir_masters_rec.item_id;
--
    -- �폜
    ELSIF (in_kbn = gn_proc_delete) THEN
      UPDATE ic_item_mst_b
      SET    inactive_ind           = gv_inactive_ind_off
            ,last_updated_by        = gn_user_id
            ,last_update_date       = gd_sysdate
            ,last_update_login      = gn_login_id
            ,request_id             = gn_request_id
            ,program_application_id = gn_appl_id
            ,program_id             = gn_program_id
            ,program_update_date    = gd_sysdate
      WHERE  item_id = ir_masters_rec.item_id;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_ic_item_mst;
--
  /***********************************************************************************
   * Procedure Name   : chk_price
   * Description      : �P���̃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_price(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    ov_retmsg          OUT NOCOPY VARCHAR2,     -- �G���[���b�Z�[�W
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_price'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_price     NUMBER;
    lv_type      VARCHAR2(2);
    ln_flg       NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_flg := 0;
    ov_retcd := TRUE;
--
    <<chk_price_loop>>
    FOR i IN 1..10 LOOP
      lv_type := TO_CHAR(i);
--
      -- �P���̎擾
      get_price(ir_masters_rec,
                lv_type,
                ln_price,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      IF (lv_type = ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id) THEN
        -- ���͂���
        IF (ir_masters_rec.cmpntcls_mast(i).cost_price IS NOT NULL) THEN
          IF (NVL(ln_price,-1) <> ir_masters_rec.cmpntcls_mast(i).cost_price) THEN
            ln_flg := 1;
            ov_retmsg := ov_retmsg || ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_desc;
            IF (i <> 10) THEN
              ov_retmsg := ov_retmsg || gv_msg_pnt;
            END IF;
          END IF;
        END IF;
      END IF;
--
    END LOOP chk_price_loop;
--
    IF (ln_flg = 1) THEN
      ov_retcd := FALSE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END chk_price;
--
  /***********************************************************************************
   * Procedure Name   : check_item_ins
   * Description      : �i�ړo�^�p�f�[�^�̃`�F�b�N�������s���܂��B(B-2)
   ***********************************************************************************/
  PROCEDURE check_item_ins(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_ins'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ȑO�ɑ��݂��Ă��Ȃ�
    IF ((ir_masters_rec.row_ins_cnt > 0)
     OR (ir_masters_rec.row_upd_cnt > 0)
     OR (ir_masters_rec.row_del_cnt > 0)) THEN
--
      -- �d���G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃ}�X�^)
    chk_ic_item_mst_b(ir_masters_rec,
                      lb_retcd,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݂��Ă���
    IF (lb_retcd) THEN
--
      -- �d���G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃA�h�I���}�X�^)
    chk_xxcmn_item_mst_b(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݂��Ă���
    IF (lb_retcd) THEN
--
      -- �d���G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃJ�e�S������)
    chk_gmi_item_category(ir_masters_rec,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݂��Ă���
    IF (lb_retcd) THEN
--
      -- �d���G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_104,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    -- �e�i�ڂ̑��݃`�F�b�N
    chk_parent_id(ir_masters_rec,
                  lb_retcd,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݂��Ȃ�
    IF (NOT lb_retcd) THEN
--
      -- ���݃G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_108,
                                                gv_tkn_ng_item_cd,
                                                ir_masters_rec.parent_item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_ins_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_item_ins_expt THEN
      NULL;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_item_ins;
--
  /***********************************************************************************
   * Procedure Name   : check_item_upd
   * Description      : �i�ڍX�V�p�f�[�^�̃`�F�b�N�������s���܂��B(B-3)
   ***********************************************************************************/
  PROCEDURE check_item_upd(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_upd'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ȑO�ɑ��݂��Ă��Ȃ�
    IF (ir_masters_rec.row_del_cnt > 0) THEN
--
      -- ���݃G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_102,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_upd_expt;
    END IF;
--
    -- �ȑO�ɓo�^�f�[�^�����݂��Ȃ�
    IF (ir_masters_rec.row_ins_cnt = 0) THEN
--
      -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃ}�X�^)
      chk_ic_item_mst_b(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ă��Ȃ�
      IF (NOT lb_retcd) THEN
--
        -- ���݃G���[
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_102,
                                                  gv_tkn_ng_hinmoku,
                                                  ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
--
      -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃA�h�I���}�X�^)
      chk_xxcmn_item_mst_b(ir_masters_rec,
                           lb_retcd,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ă��Ȃ�
      IF (NOT lb_retcd) THEN
--
        -- ���݃G���[
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_102,
                                                  gv_tkn_ng_hinmoku,
                                                  ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
--
      -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃJ�e�S������)
      chk_gmi_item_category(ir_masters_rec,
                            lb_retcd,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ă��Ȃ�
      IF (NOT lb_retcd) THEN
--
        -- ���݃G���[
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_102,
                                                  gv_tkn_ng_hinmoku,
                                                  ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
--
      -- �e�i�ڂ̑��݃`�F�b�N
      chk_parent_id(ir_masters_rec,
                    lb_retcd,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ȃ�
      IF (NOT lb_retcd) THEN
--
        -- ���݃G���[
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80b_108,
                                                  gv_tkn_ng_item_cd,
                                                  ir_masters_rec.parent_item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_upd_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_item_upd_expt THEN
      NULL;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_item_upd;
--
  /***********************************************************************************
   * Procedure Name   : check_item_del
   * Description      : �i�ڍ폜�p�f�[�^�̃`�F�b�N�������s���܂��B(B-4)
   ***********************************************************************************/
  PROCEDURE check_item_del(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_del'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd     BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ȑO�ɑ��݂��Ă��Ȃ�
    IF (ir_masters_rec.row_del_cnt > 0) THEN
--
      -- ���݃��[�j���O
      set_warn_status(ir_status_rec,
                      xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                               gv_msg_80b_103,
                                               gv_tkn_ng_hinmoku,
                                               ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_item_del_expt;
    END IF;
--
    -- �ȑO�ɑ��݂��Ă��Ȃ�
    IF (ir_masters_rec.row_ins_cnt = 0) THEN
--
      -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃ}�X�^)
      chk_ic_item_mst_b(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ă��Ȃ�
      IF (NOT lb_retcd) THEN
--
        -- ���݃��[�j���O
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80b_103,
                                                 gv_tkn_ng_hinmoku,
                                                 ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_del_expt;
      END IF;
--
      -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃA�h�I���}�X�^)
      chk_xxcmn_item_mst_b(ir_masters_rec,
                           lb_retcd,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ă��Ȃ�
      IF (NOT lb_retcd) THEN
--
        -- ���݃��[�j���O
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80b_103,
                                                 gv_tkn_ng_hinmoku,
                                                 ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_del_expt;
      END IF;
--
      -- �i�ڂ̑��݃`�F�b�N(OPM�i�ڃJ�e�S������)
      chk_gmi_item_category(ir_masters_rec,
                            lb_retcd,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���݂��Ă��Ȃ�
      IF (NOT lb_retcd) THEN
--
        -- ���݃��[�j���O
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80b_103,
                                                 gv_tkn_ng_hinmoku,
                                                 ir_masters_rec.item_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        RAISE check_item_del_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_item_del_expt THEN
      NULL;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_item_del;
--
  /***********************************************************************************
   * Procedure Name   : check_cmpt_ins
   * Description      : �i�ڌ����o�^�p�f�[�^�̃`�F�b�N�������s���܂��B(B-8)
   ***********************************************************************************/
  PROCEDURE check_cmpt_ins(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cmpt_ins'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd     BOOLEAN;
    ln_price     NUMBER;
    lv_retmsg    VARCHAR2(500);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ȑO�ɑ��݂��Ă���
    IF ((ir_masters_rec.row_ins_cnt > 0)
     OR (ir_masters_rec.row_upd_cnt > 0)
     OR (ir_masters_rec.row_del_cnt > 0)) THEN
--
      -- �d���G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_107,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    -- �i�ڌ��������ׂĖ�����
    IF ((ir_masters_rec.raw_material_cost IS NULL)
    AND (ir_masters_rec.agein_cost IS NULL)
    AND (ir_masters_rec.material_cost IS NULL)
    AND (ir_masters_rec.pack_cost IS NULL)
    AND (ir_masters_rec.out_order_cost IS NULL)
    AND (ir_masters_rec.safekeep_cost IS NULL)
    AND (ir_masters_rec.other_expense_cost IS NULL)
    AND (ir_masters_rec.spare1 IS NULL)
    AND (ir_masters_rec.spare2 IS NULL)
    AND (ir_masters_rec.spare3 IS NULL)) THEN
--
      -- �i�ڌ��������̓G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_020,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    -- �i�ڂ̑��݃`�F�b�N(�i�ڌ����}�X�^)
    chk_cm_cmpt_dtl(ir_masters_rec,
                    NULL,
                    lb_retcd,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݂��Ă���
    IF (lb_retcd) THEN
--
      -- �d���G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_107,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    -- �P���̃`�F�b�N
    chk_price(ir_masters_rec,
              lv_retmsg,
              lb_retcd,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (NOT lb_retcd) THEN
      -- �P���`�F�b�N���[�j���O
      set_warok_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_101,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code,
                                                gv_tkn_ng_genka,
                                                lv_retmsg),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_ins_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_cmpt_ins_expt THEN
      NULL;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_cmpt_ins;
--
  /***********************************************************************************
   * Procedure Name   : check_cmpt_upd
   * Description      : �i�ڌ����X�V�p�f�[�^�̃`�F�b�N�������s���܂��B(B-9)
   ***********************************************************************************/
  PROCEDURE check_cmpt_upd(
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf      OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cmpt_upd'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    lb_retcd     BOOLEAN;
    ln_price     NUMBER;
    lv_retmsg    VARCHAR2(500);
    ln_type      NUMBER;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ȑO�ɑ��݂��Ă��Ȃ�
    IF (ir_masters_rec.row_del_cnt > 0) THEN
--
      -- ���݃G���[
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_105,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_upd_expt;
    END IF;
--
    -- �ȑO�ɓo�^�f�[�^�����݂��Ă��Ȃ�
    IF (ir_masters_rec.row_ins_cnt = 0) THEN
      <<check_cmpt_loop>>
      FOR i IN 1..10 LOOP
--
        ln_type := NULL;
--
        -- ����
        IF ((i = 1) AND (ir_masters_rec.raw_material_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- �Đ���
        ELSIF ((i = 2) AND (ir_masters_rec.agein_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- ���ޔ�
        ELSIF ((i = 3) AND (ir_masters_rec.material_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- ���
        ELSIF ((i = 4) AND (ir_masters_rec.pack_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- �O�����H��
        ELSIF ((i = 5) AND (ir_masters_rec.out_order_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- �ۊǔ�
        ELSIF ((i = 6) AND (ir_masters_rec.safekeep_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- ���̑��o��
        ELSIF ((i = 7) AND (ir_masters_rec.other_expense_cost IS NOT NULL)) THEN
          ln_type := i;
--
        -- �\��1
        ELSIF ((i = 8) AND (ir_masters_rec.spare1 IS NOT NULL)) THEN
          ln_type := i;
--
        -- �\��2
        ELSIF ((i = 9) AND (ir_masters_rec.spare2 IS NOT NULL)) THEN
          ln_type := i;
--
        -- �\��3
        ELSIF ((i = 10) AND (ir_masters_rec.spare3 IS NOT NULL)) THEN
          ln_type := i;
        END IF;
--
        -- �Ώۂ���
        IF (ln_type IS NOT NULL) THEN
--
          -- �i�ڂ̑��݃`�F�b�N(�i�ڌ����}�X�^)
          chk_cm_cmpt_dtl(ir_masters_rec,
                          ln_type,
                          lb_retcd,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
          -- ���݂��Ă��Ȃ�
          IF (NOT lb_retcd) THEN
--
            -- ���݃G���[
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80b_105,
                                                      gv_tkn_ng_hinmoku,
                                                      ir_masters_rec.item_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            RAISE check_cmpt_upd_expt;
          END IF;
        END IF;
--
      END LOOP check_cmpt_loop;
    END IF;
--
    -- �P���̃`�F�b�N
    chk_price(ir_masters_rec,
              lv_retmsg,
              lb_retcd,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (NOT lb_retcd) THEN
      -- �P���`�F�b�N���[�j���O
      set_warok_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80b_100,
                                                gv_tkn_ng_hinmoku,
                                                ir_masters_rec.item_code,
                                                gv_tkn_ng_genka,
                                                lv_retmsg),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_cmpt_upd_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_cmpt_upd_expt THEN
      NULL;
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END check_cmpt_upd;
--
  /***********************************************************************************
   * Procedure Name   : item_insert_proc
   * Description      : �i�ړo�^�������s���܂��B
   ***********************************************************************************/
  PROCEDURE item_insert_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�o�͌����z��
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_insert_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_api_name       VARCHAR2(200);
    lr_item_rec       GMI_ITEM_PUB.ITEM_REC_TYP;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lv_uom_code       msc_units_of_measure.uom_code%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �P�ʂ̎擾
    get_uom_code(lv_uom_code,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    lr_item_rec.item_no     := ir_masters_rec.item_code;           -- �i���R�[�h
    lr_item_rec.item_desc1  := ir_masters_rec.item_name;           -- �i���E������
    lr_item_rec.item_um     := lv_uom_code;
    lr_item_rec.lot_ctl     := gv_lot_ctl_on;
    lr_item_rec.attribute1  := ir_masters_rec.old_crowd_code;      -- ���E�Q�R�[�h
    lr_item_rec.attribute2  := ir_masters_rec.new_crowd_code;      -- �V�E�Q�R�[�h
    lr_item_rec.attribute3  := ir_masters_rec.crowd_start_days;    -- �K�p�J�n��
    lr_item_rec.attribute4  := ir_masters_rec.old_price;           -- ���E�艿
    lr_item_rec.attribute5  := ir_masters_rec.new_price;           -- �V�E�艿
    lr_item_rec.attribute6  := ir_masters_rec.price_start_days;    -- �K�p�J�n��
    lr_item_rec.attribute7  := ir_masters_rec.old_business_cost;   -- ���E�c�ƌ���
    lr_item_rec.attribute8  := ir_masters_rec.new_business_cost;   -- �V�E�c�ƌ���
    lr_item_rec.attribute9  := ir_masters_rec.buis_start_days;     -- �K�p�J�n��
--
    -- ���i�敪�����[�t
    IF (ir_masters_rec.arti_div_code = gv_div_code_reef) THEN
      lr_item_rec.attribute10 := gv_rate_code_reef;           -- �e��
    ELSE
      lr_item_rec.attribute10 := gv_rate_code_drink;          -- �d��
    END IF;
    lr_item_rec.attribute11 := ir_masters_rec.case_num;            -- �P�[�X����
    lr_item_rec.attribute12 := ir_masters_rec.net;                 -- NET
    lr_item_rec.attribute13 := ir_masters_rec.sale_start_days;     -- �K�p�J�n��
    lr_item_rec.attribute21 := ir_masters_rec.jan_code;            -- JAN�R�[�h
--
    -- ���i�敪���h�����N
    IF (ir_masters_rec.arti_div_code = gv_div_code_drink) THEN
      lr_item_rec.attribute25 := ir_masters_rec.weight_volume;       -- �d��/�̐�
    ELSE
      lr_item_rec.attribute16 := ir_masters_rec.weight_volume;       -- �d��/�̐�
    END IF;
    lr_item_rec.attribute26 := ir_masters_rec.sale_obj_code;       -- ����Ώۋ敪
    lr_item_rec.attribute30 := TO_CHAR(SYSDATE, 'YYYY/MM/DD');
--
    -- 2008/02/05 Mod
    lr_item_rec.loct_ctl := gn_loct_ctl_on;                        -- �ۊǏꏊ
--
    -- OPM�i�ڃ}�X�^(�o�^)
    GMI_ITEM_PUB.CREATE_ITEM(
        P_API_VERSION      => gv_api_ver
       ,P_INIT_MSG_LIST    => FND_API.G_FALSE
       ,P_COMMIT           => FND_API.G_FALSE
       ,P_VALIDATION_LEVEL => FND_API.G_VALID_LEVEL_FULL
       ,P_ITEM_REC         => lr_item_rec
       ,X_RETURN_STATUS    => lv_return_status
       ,X_MSG_COUNT        => ln_msg_count
       ,X_MSG_DATA         => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'GMI_ITEM_PUB.CREATE_ITEM';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80b_013,
                                            gv_tkn_api_name, lv_api_name);
--
      FND_MSG_PUB.GET( P_MSG_INDEX     => 1,
                       P_ENCODED       => FND_API.G_FALSE,
                       P_DATA          => lv_msg_data,
                       P_MSG_INDEX_OUT => ln_msg_count );
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.imb_flg := 1;
--
    -- �i��ID�̎擾
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �������b�g�̔ԗL���E���b�g�E�T�t�B�b�N�X�̍X�V
    BEGIN
      UPDATE ic_item_mst_b
      SET    autolot_active_indicator = gv_autolot_on
            ,lot_suffix               = gv_lot_suffix_on
      WHERE  item_id = ir_masters_rec.item_id;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- OPM�i�ڃA�h�I���}�X�^(����)
    proc_xxcmn_item_mst(ir_masters_rec,
                        gn_proc_insert,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.xmb_flg := 1;
--
    -- OPM�i�ڃJ�e�S������
    proc_item_category(ir_masters_rec,
                       gn_proc_insert,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.gic_flg := 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END item_insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : item_update_proc
   * Description      : �i�ڍX�V�������s���܂��B
   ***********************************************************************************/
  PROCEDURE item_update_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�o�͌����z��
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_update_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �i��ID�̎擾
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- OPM�i�ڃ}�X�^(����)
    proc_ic_item_mst(ir_masters_rec,
                     gn_proc_update,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.imb_flg := 1;
--
    -- OPM�i�ڃA�h�I���}�X�^(����)
    proc_xxcmn_item_mst(ir_masters_rec,
                        gn_proc_update,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.xmb_flg := 1;
--
    -- OPM�i�ڃJ�e�S������
    proc_item_category(ir_masters_rec,
                       gn_proc_update,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.gic_flg := 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END item_update_proc;
--
  /***********************************************************************************
   * Procedure Name   : item_delete_proc
   * Description      : �i�ڍ폜�������s���܂��B
   ***********************************************************************************/
  PROCEDURE item_delete_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�o�͌����z��
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_delete_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �i��ID�̎擾
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- OPM�i�ڃ}�X�^(����)
    proc_ic_item_mst(ir_masters_rec,
                     gn_proc_delete,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    it_report_rec.imb_flg := 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END item_delete_proc;
--
  /***********************************************************************************
   * Procedure Name   : cmpt_insert_proc
   * Description      : �i�ڌ����o�^�������s���܂��B
   ***********************************************************************************/
  PROCEDURE cmpt_insert_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�o�͌����z��
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cmpt_insert_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_api_name       VARCHAR2(200);
    lr_this_tbl       GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE;
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lr_head_rec       GMF_ITEMCOST_PUB.HEADER_REC_TYPE;
    lr_ids_tbl        GMF_ITEMCOST_PUB.COSTCMPNT_IDS_TBL_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(5000);
    lv_id             VARCHAR2(2);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �i��ID�̎擾
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���Ԃ̎擾
    get_period_code(ir_masters_rec,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ��{�ݒ�l
    lr_head_rec.item_id        := ir_masters_rec.item_id;
    lr_head_rec.item_no        := ir_masters_rec.item_code;
    lr_head_rec.whse_code      := gv_whse_code;
    lr_head_rec.calendar_code  := gv_item_cal;
    lr_head_rec.period_code    := ir_masters_rec.period_code;
    lr_head_rec.cost_mthd_code := gv_cost_div;
    lr_head_rec.user_name      := gv_user_name;
--
    <<cmpt_insert_loop>>
    FOR i IN 1..10 LOOP
      lv_id := TO_CHAR(i);
--
      -- ���͂���
      IF (ir_masters_rec.cmpntcls_mast(i).cost_price IS NOT NULL) THEN
        lr_this_tbl(i).cost_analysis_code := '0000';
        lr_this_tbl(i).burden_ind  := 0;
        lr_this_tbl(i).delete_mark := 0;
--
        IF (lv_id = ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id) THEN
          lr_this_tbl(i).cmpnt_cost       := ir_masters_rec.cmpntcls_mast(i).cost_price;
          lr_this_tbl(i).cost_cmpntcls_id := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
        END IF;
      END IF;
--
    END LOOP cmpt_insert_loop;
--
    -- �Ώۂ���
    IF (lr_this_tbl.count > 0) THEN
--
      -- �i�ڌ����}�X�^(�o�^)
      GMF_ITEMCOST_PUB.CREATE_ITEM_COST(
          P_API_VERSION         => gv_api_ver
         ,P_INIT_MSG_LIST       => FND_API.G_FALSE
         ,P_COMMIT              => FND_API.G_FALSE
         ,X_RETURN_STATUS       => lv_return_status
         ,X_MSG_COUNT           => ln_msg_count
         ,X_MSG_DATA            => lv_msg_data
         ,P_HEADER_REC          => lr_head_rec
         ,P_THIS_LEVEL_DTL_TBL  => lr_this_tbl
         ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
         ,X_COSTCMPNT_IDS       => lr_ids_tbl
      );
--
      -- ���s
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        lv_api_name := 'GMF_ITEMCOST_PUB.CREATE_ITEM_COST';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80b_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_msg_data := lv_errmsg;
--
        put_api_log(
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        lv_errmsg := lv_msg_data;
        lv_errbuf := lv_msg_data;
--
        RAISE global_api_expt;
      END IF;
--
      it_report_rec.ccd_flg := 1;
--
    END IF;
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END cmpt_insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : cmpt_update_proc
   * Description      : �i�ڌ����X�V�������s���܂��B
   ***********************************************************************************/
  PROCEDURE cmpt_update_proc(
    it_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�o�͌����z��
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �����Ώۃf�[�^�i�[���R�[�h
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cmpt_update_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_api_name       VARCHAR2(200);
    lr_this_tbl       GMF_ITEMCOST_PUB.THIS_LEVEL_DTL_TBL_TYPE;
    lr_low_tbl        GMF_ITEMCOST_PUB.LOWER_LEVEL_DTL_TBL_TYPE;
    lr_head_rec       GMF_ITEMCOST_PUB.HEADER_REC_TYPE;
    lv_return_status  VARCHAR2(30);
    ln_msg_count      NUMBER;
    lv_msg_data       VARCHAR2(2000);
    lv_id             VARCHAR2(2);
    ln_price          NUMBER;
    lv_desc           VARCHAR2(50);
    ln_cnt            NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �i��ID�̎擾
    get_item_id(ir_masters_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���Ԃ̎擾
    get_period_code(ir_masters_rec,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ��{�ݒ�l
    lr_head_rec.item_id        := ir_masters_rec.item_id;
    lr_head_rec.item_no        := NULL;
    lr_head_rec.whse_code      := gv_whse_code;
    lr_head_rec.calendar_code  := gv_item_cal;
    lr_head_rec.period_code    := ir_masters_rec.period_code;
    lr_head_rec.cost_mthd_code := gv_cost_div;
    lr_head_rec.user_name      := gv_user_name;
--
    <<cmpt_update_loop>>
    FOR i IN 1..10 LOOP
      lv_id := TO_CHAR(i);
--
      -- ���͂���
      IF (ir_masters_rec.cmpntcls_mast(i).cost_price IS NOT NULL) THEN
        lr_this_tbl(i).burden_ind  := 0;
        lr_this_tbl(i).delete_mark := 0;
--
        IF (lv_id = ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id) THEN
          ir_masters_rec.cost_id    := ir_masters_rec.cmpntcls_mast(i).cost_cmpntcls_id;
          lr_this_tbl(i).cmpnt_cost := ir_masters_rec.cmpntcls_mast(i).cost_price;
        END IF;
--
        -- �����ڍ�ID�̎擾
        get_cmpnt_id(ir_masters_rec,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
        lr_this_tbl(i).cmpntcost_id := ir_masters_rec.cmpntcost_id;
      END IF;
    END LOOP cmpt_update_loop;
--
    -- �Ώۂ���
    IF (lr_this_tbl.count > 0) THEN
--
      -- �i�ڌ����}�X�^(�X�V)
      GMF_ITEMCOST_PUB.UPDATE_ITEM_COST(
          P_API_VERSION         => gv_api_ver
         ,P_INIT_MSG_LIST       => FND_API.G_FALSE
         ,P_COMMIT              => FND_API.G_FALSE
         ,X_RETURN_STATUS       => lv_return_status
         ,X_MSG_COUNT           => ln_msg_count
         ,X_MSG_DATA            => lv_msg_data
         ,P_HEADER_REC          => lr_head_rec
         ,P_THIS_LEVEL_DTL_TBL  => lr_this_tbl
         ,P_LOWER_LEVEL_DTL_TBL => lr_low_tbl
      );
--
      -- ���s
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        lv_api_name := 'GMF_ITEMCOST_PUB.UPDATE_ITEM_COST';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80b_013,
                                              gv_tkn_api_name, lv_api_name);
        lv_msg_data := lv_errmsg;
--
        put_api_log(
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        lv_errmsg := lv_msg_data;
        lv_errbuf := lv_msg_data;
--
        RAISE global_api_expt;
      END IF;
--
      it_report_rec.ccd_flg := 1;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END cmpt_update_proc;
--
  /***********************************************************************************
   * Procedure Name   : proc_item
   * Description      : ���f�������s���܂��B(B-14)
   ***********************************************************************************/
  PROCEDURE proc_item(
    it_ins_mast_tbl IN OUT NOCOPY masters_tbl,  -- �Ώۃf�[�^(�o�^)
    it_upd_mast_tbl IN OUT NOCOPY masters_tbl,  -- �Ώۃf�[�^(�X�V)
    it_del_mast_tbl IN OUT NOCOPY masters_tbl,  -- �Ώۃf�[�^(�폜)
    it_report_tbl   IN OUT NOCOPY report_tbl,   -- ���|�[�g�o�͌����z��
    in_insert_cnt   IN            NUMBER,       -- �o�^����
    in_update_cnt   IN            NUMBER,       -- �X�V����
    in_delete_cnt   IN            NUMBER,       -- �폜����
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_item'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_exec_cnt   NUMBER;
    ln_log_cnt    NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �o�^�f�[�^�̔��f(B-14)
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_insert_cnt-1 LOOP
      <<insert_log_loop>>
      FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
        -- �o�^
        IF (it_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
          -- SEQ�ԍ�
          IF (it_report_tbl(ln_log_cnt).seq_number =
              it_ins_mast_tbl(ln_exec_cnt).seq_number) THEN
--
            -- �i�ړo�^����
            item_insert_proc(it_report_tbl(ln_log_cnt),
                             it_ins_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            -- �i�ڌ����o�^����
            cmpt_insert_proc(it_report_tbl(ln_log_cnt),
                             it_ins_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END LOOP insert_log_loop;
    END LOOP insert_proc_loop;
--
    -- �X�V�f�[�^�̔��f(B-14)
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_update_cnt-1 LOOP
      <<update_log_loop>>
      FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
        -- �X�V
        IF (it_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
          -- SEQ�ԍ�
          IF (it_report_tbl(ln_log_cnt).seq_number =
              it_upd_mast_tbl(ln_exec_cnt).seq_number) THEN
--
            -- �i�ڌ����X�V����
            cmpt_update_proc(it_report_tbl(ln_log_cnt),
                             it_upd_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
--
            -- �i�ڍX�V����
            item_update_proc(it_report_tbl(ln_log_cnt),
                             it_upd_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END LOOP update_log_loop;
    END LOOP update_proc_loop;
--
    -- �폜�f�[�^�̔��f(B-14)
    <<delete_proc_loop>>
    FOR ln_exec_cnt IN 0..in_delete_cnt-1 LOOP
      <<delete_log_loop>>
      FOR ln_log_cnt IN 0..gn_report_cnt-1 LOOP
        -- �폜
        IF (it_report_tbl(ln_log_cnt).proc_code = gn_proc_delete) THEN
          -- SEQ�ԍ�
          IF (it_report_tbl(ln_log_cnt).seq_number =
              it_del_mast_tbl(ln_exec_cnt).seq_number) THEN
--
            -- �폜����
            item_delete_proc(it_report_tbl(ln_log_cnt),
                             it_del_mast_tbl(ln_exec_cnt),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END LOOP delete_log_loop;
    END LOOP delete_proc_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_item;
--
  /***********************************************************************************
   * Procedure Name   : init_status
   * Description      : �X�e�[�^�X�����������܂��B
   ***********************************************************************************/
  PROCEDURE init_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ir_status_rec.file_level_status := gn_data_status_nomal;
    ir_status_rec.row_level_status  := gn_data_status_nomal;
    ir_status_rec.row_err_message   := NULL;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_status;
--
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �����������s���܂��B
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    get_profile(lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �e�[�u�����b�N����
    -- ===============================
    set_if_lock(lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �R���|�[�l���g�敪�̎擾
    -- ===============================
    init_cmpntcls_id(lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                     lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                     lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END init_proc;
--
  /***********************************************************************************
   * Procedure Name   : term_proc
   * Description      : �I���������s���܂��B(B-16)
   ***********************************************************************************/
  PROCEDURE term_proc(
    it_report_tbl IN            report_tbl,   -- �o�͗p�e�[�u��
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'term_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
 --#####################################  �Œ蕔 END   #############################################--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    lb_retcd := TRUE;
--
    IF (gn_normal_cnt > 0) THEN
      -- ���O�o�͏���(����:0)
      disp_report(it_report_tbl,
                  gn_data_status_nomal,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_error_cnt > 0) THEN
      -- ���O�o�͏���(���s:1)
      disp_report(it_report_tbl,
                  gn_data_status_error,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_warn_cnt > 0) THEN
      -- ���O�o�͏���(�x��:2)
      disp_report(it_report_tbl,
                  gn_data_status_warn,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (gn_warok_cnt > 0) THEN
      -- ���O�o�͏���(�x��:3)
      disp_report(it_report_tbl,
                  gn_data_status_warok,
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- OPM�i�ڃ}�X�^(IC_ITEM_MST_B)
    IF (ic_item_mst_b_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE ic_item_mst_b_cur;
    END IF;
    -- OPM�i�ڃA�h�I���}�X�^(XXCMN_ITEM_MST_B)
    IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE xxcmn_item_mst_b_cur;
    END IF;
    -- OPM�i�ڃJ�e�S������(GMI_ITEM_CATEGORIES)
    IF (gmi_item_categories_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gmi_item_categories_cur;
    END IF;
    -- �i�ڌ����}�X�^(CM_CMPT_DTL)
    IF (cm_cmpt_dtl_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE cm_cmpt_dtl_cur;
    END IF;
--
    -- �f�[�^�폜(�i�ڃC���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_item_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80b_017,
                                            gv_tkn_table, gv_xxcmn_item_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END term_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lr_masters_rec   masters_rec; -- �����Ώۃf�[�^�i�[���R�[�h
    lr_status_rec    status_rec;  -- �����󋵊i�[���R�[�h
--
    lt_report_tbl    report_tbl;  -- ���|�[�g�o�͌����z��
--
    ln_normal_cnt    NUMBER;
    ln_warn_cnt      NUMBER;
    ln_error_cnt     NUMBER;
--
    -- �i�ڗp
    lt_item_ins_mast masters_tbl; -- �e�}�X�^�֓o�^����f�[�^
    lt_item_upd_mast masters_tbl; -- �e�}�X�^�֍X�V����f�[�^
    lt_item_del_mast masters_tbl; -- �e�}�X�^�֍폜����f�[�^
    ln_item_ins_cnt  NUMBER;      -- �o�^����
    ln_item_upd_cnt  NUMBER;      -- �X�V����
    ln_item_del_cnt  NUMBER;      -- �폜����
--
    -- �i�ڌ����p
    lt_cmpt_ins_mast masters_tbl; -- �e�}�X�^�֓o�^����f�[�^
    lt_cmpt_upd_mast masters_tbl; -- �e�}�X�^�֍X�V����f�[�^
    ln_cmpt_ins_cnt  NUMBER;      -- �o�^����
    ln_cmpt_upd_cnt  NUMBER;      -- �X�V����
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    CURSOR item_if_cur
    IS
      SELECT xif.seq_number,            -- SEQ�ԍ�
             xif.proc_code,             -- �X�V�敪
             xif.item_code,             -- �i���R�[�h
             xif.item_name,             -- �i���E������
             xif.item_short_name,       -- �i���E����
             xif.item_name_alt,         -- �i���E�J�i
             xif.old_crowd_code,        -- ���E�Q�R�[�h
             xif.new_crowd_code,        -- �V�E�Q�R�[�h
             xif.crowd_start_date,      -- �K�p�J�n��
             xif.policy_group_code,     -- ����Q�R�[�h
             xif.marke_crowd_code,      -- �}�[�P�p�Q�R�[�h
             xif.old_price,             -- ���E�艿
             xif.new_price,             -- �V�E�艿
             xif.price_start_date,      -- �K�p�J�n��
             xif.old_standard_cost,     -- ���E�W������
             xif.new_standard_cost,     -- �V�E�W������
             xif.standard_start_date,   -- �K�p�J�n��
             xif.old_business_cost,     -- ���E�c�ƌ���
             xif.new_business_cost,     -- �V�E�c�ƌ���
             xif.business_start_date,   -- �K�p�J�n��
             xif.old_tax,               -- ���E����ŗ�
             xif.new_tax,               -- �V�E����ŗ�
             xif.tax_start_date,        -- �K�p�J�n��
             xif.rate_code,             -- ���敪
             xif.case_num,              -- �P�[�X����
             xif.product_div_code,      -- ���i���i�敪
             xif.net,                   -- NET
             xif.weight_volume,         -- �d��/�̐�
             xif.arti_div_code,         -- ���i�敪
             xif.div_tea_code,          -- �o�����敪
             xif.parent_item_code,      -- �e�i���R�[�h
             xif.sale_obj_code,         -- ����Ώۋ敪
             xif.jan_code,              -- JAN�R�[�h
             xif.sale_start_date,       -- �����J�n��(�����J�n��)
             xif.abolition_code,        -- �p�~�敪
             xif.abolition_date,        -- �p�~��(�������~��)
             xif.raw_mate_consumption,  -- �����g�p��
             xif.raw_material_cost,     -- ����
             xif.agein_cost,            -- �Đ���
             xif.material_cost,         -- ���ޔ�
             xif.pack_cost,             -- ���
             xif.out_order_cost,        -- �O�����H��
             xif.safekeep_cost,         -- �ۊǔ�
             xif.other_expense_cost,    -- ���̑��o��
             xif.spare1,                -- �\��1
             xif.spare2,                -- �\��2
             xif.spare3,                -- �\��3
             xif.spare                  -- �\��
      FROM   xxcmn_item_if xif
      ORDER BY seq_number;
--
    -- *** ���[�J���E���R�[�h ***
    lr_item_if_rec item_if_cur%ROWTYPE;
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_warok_cnt  := 0;
    gn_report_cnt := 0;
--
    ln_normal_cnt   := 0;
    ln_error_cnt    := 0;
    ln_warn_cnt     := 0;
    ln_item_ins_cnt := 0;
    ln_item_upd_cnt := 0;
    ln_item_del_cnt := 0;
    ln_cmpt_ins_cnt := 0;
    ln_cmpt_upd_cnt := 0;
--
    gn_user_id     := FND_GLOBAL.USER_ID;
    gd_sysdate     := SYSDATE;
    gn_login_id    := FND_GLOBAL.LOGIN_ID;
    gn_request_id  := FND_GLOBAL.CONC_REQUEST_ID;
    gn_appl_id     := FND_GLOBAL.QUEUE_APPL_ID;
    gn_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������
    -- �v���t�@�C���̎擾�A�e�[�u�����b�N
    -- ===============================
    init_proc(lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- �t�@�C�����x���̃X�e�[�^�X��������
    init_status(lr_status_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ���[�U���̎擾
    get_user_name(lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- �i�ڃC���^�t�F�[�X�擾(B-1)
    -- ===============================
--
    OPEN item_if_cur;
--
    <<item_if_loop>>
    LOOP
      FETCH item_if_cur INTO lr_item_if_rec;
      EXIT WHEN item_if_cur%NOTFOUND;
      gn_target_cnt := gn_target_cnt + 1; -- ���������J�E���g�A�b�v
--
      -- �s���x���̃X�e�[�^�X��������
      init_row_status(lr_status_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- �擾�����l�����R�[�h�ɃR�s�[
      lr_masters_rec.seq_number           := lr_item_if_rec.seq_number;
      lr_masters_rec.proc_code            := lr_item_if_rec.proc_code;
      lr_masters_rec.item_code            := lr_item_if_rec.item_code;
      lr_masters_rec.item_name            := lr_item_if_rec.item_name;
      lr_masters_rec.item_short_name      := lr_item_if_rec.item_short_name;
      lr_masters_rec.item_name_alt        := lr_item_if_rec.item_name_alt;
      lr_masters_rec.old_crowd_code       := lr_item_if_rec.old_crowd_code;
      lr_masters_rec.new_crowd_code       := lr_item_if_rec.new_crowd_code;
      lr_masters_rec.crowd_start_date     := lr_item_if_rec.crowd_start_date;
      lr_masters_rec.policy_group_code    := lr_item_if_rec.policy_group_code;
      lr_masters_rec.marke_crowd_code     := lr_item_if_rec.marke_crowd_code;
      lr_masters_rec.old_price            := lr_item_if_rec.old_price;
      lr_masters_rec.new_price            := lr_item_if_rec.new_price;
      lr_masters_rec.price_start_date     := lr_item_if_rec.price_start_date;
      lr_masters_rec.old_standard_cost    := lr_item_if_rec.old_standard_cost;
      lr_masters_rec.new_standard_cost    := lr_item_if_rec.new_standard_cost;
      lr_masters_rec.standard_start_date  := lr_item_if_rec.standard_start_date;
      lr_masters_rec.old_business_cost    := lr_item_if_rec.old_business_cost;
      lr_masters_rec.new_business_cost    := lr_item_if_rec.new_business_cost;
      lr_masters_rec.business_start_date  := lr_item_if_rec.business_start_date;
      lr_masters_rec.old_tax              := lr_item_if_rec.old_tax;
      lr_masters_rec.new_tax              := lr_item_if_rec.new_tax;
      lr_masters_rec.tax_start_date       := lr_item_if_rec.tax_start_date;
      lr_masters_rec.rate_code            := lr_item_if_rec.rate_code;
      lr_masters_rec.case_num             := lr_item_if_rec.case_num;
      lr_masters_rec.product_div_code     := lr_item_if_rec.product_div_code;
      lr_masters_rec.net                  := lr_item_if_rec.net;
      lr_masters_rec.weight_volume        := lr_item_if_rec.weight_volume;
      lr_masters_rec.arti_div_code        := lr_item_if_rec.arti_div_code;
      lr_masters_rec.div_tea_code         := lr_item_if_rec.div_tea_code;
      lr_masters_rec.parent_item_code     := lr_item_if_rec.parent_item_code;
      lr_masters_rec.sale_obj_code        := lr_item_if_rec.sale_obj_code;
      lr_masters_rec.jan_code             := lr_item_if_rec.jan_code;
      lr_masters_rec.sale_start_date      := lr_item_if_rec.sale_start_date;
      lr_masters_rec.abolition_code       := lr_item_if_rec.abolition_code;
      lr_masters_rec.abolition_date       := lr_item_if_rec.abolition_date;
      lr_masters_rec.raw_mate_consumption := lr_item_if_rec.raw_mate_consumption;
      lr_masters_rec.raw_material_cost    := lr_item_if_rec.raw_material_cost;
      lr_masters_rec.agein_cost           := lr_item_if_rec.agein_cost;
      lr_masters_rec.material_cost        := lr_item_if_rec.material_cost;
      lr_masters_rec.pack_cost            := lr_item_if_rec.pack_cost;
      lr_masters_rec.out_order_cost       := lr_item_if_rec.out_order_cost;
      lr_masters_rec.safekeep_cost        := lr_item_if_rec.safekeep_cost;
      lr_masters_rec.other_expense_cost   := lr_item_if_rec.other_expense_cost;
      lr_masters_rec.spare1               := lr_item_if_rec.spare1;
      lr_masters_rec.spare2               := lr_item_if_rec.spare2;
      lr_masters_rec.spare3               := lr_item_if_rec.spare3;
      lr_masters_rec.spare                := lr_item_if_rec.spare;
--
      -- �R���|�[�l���g�敪�̐ݒ�
      lr_masters_rec.cmpntcls_mast        := gt_cmpntcls_mast;
--
      -- ��������̐��l��
      lr_masters_rec.cmpntcls_mast(1).cost_price  := TO_NUMBER(lr_masters_rec.raw_material_cost);
      lr_masters_rec.cmpntcls_mast(2).cost_price  := TO_NUMBER(lr_masters_rec.agein_cost);
      lr_masters_rec.cmpntcls_mast(3).cost_price  := TO_NUMBER(lr_masters_rec.material_cost);
      lr_masters_rec.cmpntcls_mast(4).cost_price  := TO_NUMBER(lr_masters_rec.pack_cost);
      lr_masters_rec.cmpntcls_mast(5).cost_price  := TO_NUMBER(lr_masters_rec.out_order_cost);
      lr_masters_rec.cmpntcls_mast(6).cost_price  := TO_NUMBER(lr_masters_rec.safekeep_cost);
      lr_masters_rec.cmpntcls_mast(7).cost_price  := TO_NUMBER(lr_masters_rec.other_expense_cost);
      lr_masters_rec.cmpntcls_mast(8).cost_price  := TO_NUMBER(lr_masters_rec.spare1);
      lr_masters_rec.cmpntcls_mast(9).cost_price  := TO_NUMBER(lr_masters_rec.spare2);
      lr_masters_rec.cmpntcls_mast(10).cost_price := TO_NUMBER(lr_masters_rec.spare3);
--
      -- ���t�̕�����
      lr_masters_rec.crowd_start_days := TO_CHAR(lr_item_if_rec.crowd_start_date,'YYYY/MM/DD');
      lr_masters_rec.price_start_days := TO_CHAR(lr_item_if_rec.price_start_date,'YYYY/MM/DD');
      lr_masters_rec.buis_start_days  := TO_CHAR(lr_item_if_rec.business_start_date,'YYYY/MM/DD');
      lr_masters_rec.sale_start_days  := TO_CHAR(lr_item_if_rec.sale_start_date,'YYYY/MM/DD');
--
      -- �X�V�敪�`�F�b�N
      check_proc_code(lr_status_rec,
                      lr_masters_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- ����Ȃ�
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- �ȑO�̃f�[�^��Ԃ̎擾
        get_xxcmn_item_if(lr_masters_rec,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      -- ===============================
      -- �i�ڃ`�F�b�N
      -- ===============================
--
      -- ����Ȃ�
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- �o�^
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
          -- ===============================
          -- �i�ړo�^���`�F�b�N(B-2)
          -- ===============================
          check_item_ins(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF (is_row_status_nomal(lr_status_rec)) THEN
            -- ===============================
            -- �i�ړo�^���i�[(B-5)
            -- ===============================
            lt_item_ins_mast(ln_item_ins_cnt) := lr_masters_rec;
            ln_item_ins_cnt := ln_item_ins_cnt + 1;
          END IF;
--
        -- �X�V
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
          -- ===============================
          -- �i�ڍX�V���`�F�b�N(B-3)
          -- ===============================
          check_item_upd(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF (is_row_status_nomal(lr_status_rec)) THEN
            -- ===============================
            -- �i�ڍX�V���i�[(B-6)
            -- ===============================
            lt_item_upd_mast(ln_item_upd_cnt) := lr_masters_rec;
            ln_item_upd_cnt := ln_item_upd_cnt + 1;
          END IF;
--
        -- �폜
        ELSIF (lr_masters_rec.proc_code = gn_proc_delete) THEN
          -- ===============================
          -- �i�ڍ폜���`�F�b�N(B-4)
          -- ===============================
          check_item_del(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF (is_row_status_nomal(lr_status_rec)) THEN
            -- ===============================
            -- �i�ڍ폜���i�[(B-7)
            -- ===============================
            lt_item_del_mast(ln_item_del_cnt) := lr_masters_rec;
            ln_item_del_cnt := ln_item_del_cnt + 1;
          END IF;
        END IF;
      END IF;
--
      -- ===============================
      -- �i�ڌ����`�F�b�N
      -- ===============================
--
      -- ����Ȃ�
      IF (is_row_status_nomal(lr_status_rec)) THEN
--
        -- �o�^
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
          -- ===============================
          -- �i�ڌ����o�^���`�F�b�N(B-8)
          -- ===============================
          check_cmpt_ins(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF ((is_row_status_nomal(lr_status_rec))
           OR (is_row_status_warok(lr_status_rec))) THEN
            -- ===============================
            -- �i�ڌ����o�^���i�[(B-11)
            -- ===============================
            lt_cmpt_ins_mast(ln_cmpt_ins_cnt) := lr_masters_rec;
            ln_cmpt_ins_cnt := ln_cmpt_ins_cnt + 1;
          END IF;
--
        -- �X�V
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
          -- ===============================
          -- �i�ڌ����X�V���`�F�b�N(B-9)
          -- ===============================
          check_cmpt_upd(lr_status_rec,
                         lr_masters_rec,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
--
          IF ((is_row_status_nomal(lr_status_rec))
           OR (is_row_status_warok(lr_status_rec))) THEN
            -- ===============================
            -- �i�ڌ����X�V���i�[(B-12)
            -- ===============================
            lt_cmpt_upd_mast(ln_cmpt_upd_cnt) := lr_masters_rec;
            ln_cmpt_upd_cnt := ln_cmpt_upd_cnt + 1;
          END IF;
        END IF;
      END IF;
--
      -- ���팏�����J�E���g�A�b�v
      IF (is_row_status_nomal(lr_status_rec)) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
--
      ELSE
        -- �x���������J�E���g�A�b�v
        IF (is_row_status_warn(lr_status_rec)) THEN
          gn_warn_cnt := gn_warn_cnt + 1;
--
        -- �x���������J�E���g�A�b�v
        ELSIF (is_row_status_warok(lr_status_rec)) THEN
          gn_warok_cnt := gn_warok_cnt + 1;
--
        -- �ُ팏�����J�E���g�A�b�v
        ELSE
          gn_error_cnt := gn_error_cnt +1;
        END IF;
      END IF;
--
      -- ���O�o�͗p�f�[�^�̊i�[
      add_report(lr_status_rec,
                 lr_masters_rec,
                 lt_report_tbl,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP item_if_loop;
--
    CLOSE item_if_cur;
--
    -- ����Ȃ�
    IF (is_file_status_nomal(lr_status_rec)) THEN
      -- ===============================
      -- ���f����(B-14)
      -- ===============================
      proc_item(lt_item_ins_mast,
                lt_item_upd_mast,
                lt_item_del_mast,
                lt_report_tbl,
                ln_item_ins_cnt,
                ln_item_upd_cnt,
                ln_item_del_cnt,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- �I������(B-16)
    -- ===============================
    term_proc(lt_report_tbl,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    gn_normal_cnt := gn_normal_cnt + gn_warok_cnt;
--
        -- �G���[�A���[�j���O�f�[�^�L��̏ꍇ�̓��[�j���O�I������B
    IF ((gn_error_cnt + gn_warn_cnt + gn_warok_cnt) > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- �J�[�\�����J���Ă����
      IF (item_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE item_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gmi_item_categories_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE cm_cmpt_dtl_cur;
      END IF;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (item_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE item_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gmi_item_categories_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE cm_cmpt_dtl_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (item_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE item_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gmi_item_categories_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE cm_cmpt_dtl_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (item_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE item_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (ic_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE ic_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (xxcmn_item_mst_b_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE xxcmn_item_mst_b_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gmi_item_categories_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gmi_item_categories_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (cm_cmpt_dtl_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE cm_cmpt_dtl_cur;
      END IF;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT NOCOPY VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80b_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80b_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80b_019,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,gv_msg_80b_003);
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_018);
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
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_007,
                                           gv_tkn_cnt, TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_008,
                                           gv_tkn_cnt, TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_009,
                                           gv_tkn_cnt, TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80b_010,
                                           gv_tkn_cnt, TO_CHAR(gn_warn_cnt));
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80b_011,
                                           gv_tkn_status, gv_conc_status);
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
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn800002c;
/
