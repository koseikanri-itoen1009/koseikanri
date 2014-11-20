CREATE OR REPLACE PACKAGE BODY xxcmn800001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : XXCMN800001C(body)
 * Description      : �ڋq�C���^�t�F�[�X
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �ڋq�C���^�t�F�[�X   T_MD070_BPO_80A
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_profile            �v���t�@�C���擾�v���V�[�W��
 *  set_if_lock            �C���^�t�F�[�X�e�[�u���ɑ΂��郍�b�N�擾�v���V�[�W��
 *  set_error_status       �G���[������������Ԃɂ���v���V�[�W��
 *  set_warn_status        �x��������������Ԃɂ���v���V�[�W��
 *  init_status            �X�e�[�^�X�������v���V�[�W��
 *  is_file_status_nomal   �t�@�C�����x���Ő��킩�󋵂��m�F����t�@���N�V����
 *  init_row_status        �s���x���X�e�[�^�X�������v���V�[�W��
 *  is_row_status_nomal    �s���x���Ő��킩�󋵂��m�F����t�@���N�V����
 *  is_row_status_warn     �s���x���Ōx�����󋵂��m�F����t�@���N�V����
 *  chk_party_id           �ڋq�E�p�[�e�B�}�X�^�̏�Ԃ�Ԃ��t�@���N�V����
 *  add_p_report           ���|�[�g�p(���_)�f�[�^��ݒ肷��v���V�[�W��
 *  add_s_report           ���|�[�g�p(�z����)�f�[�^��ݒ肷��v���V�[�W��
 *  add_c_report           ���|�[�g�p(�ڋq)�f�[�^��ݒ肷��v���V�[�W��
 *  disp_p_report          ���|�[�g�p(���_)�f�[�^���o�͂���v���V�[�W��
 *  disp_s_report          ���|�[�g�p(�z����)�f�[�^���o�͂���v���V�[�W��
 *  disp_c_report          ���|�[�g�p(�ڋq)�f�[�^���o�͂���v���V�[�W��
 *  disp_report            ���|�[�g�p�f�[�^���o�͂���v���V�[�W��
 *  get_class_code         �ڋq�敪�̎擾���s���v���V�[�W��
 *  get_xxcmn_party_if     ���_�C���^�t�F�[�X�̈ȑO�̌����擾���s���v���V�[�W��
 *  get_xxcmn_site_if      �z����C���^�t�F�[�X�̈ȑO�̌����擾���s���v���V�[�W��
 *  get_hz_parties         �p�[�e�B�[�}�X�^�̎擾���s���v���V�[�W��
 *  get_hz_cust_accounts   �ڋq�}�X�^�̎擾���s���v���V�[�W��
 *  get_hz_party_sites     �p�[�e�B�[�T�C�g�}�X�^�̎擾���s���v���V�[�W��
 *  get_party_num          �ڋq�R�[�h�̎擾���s���v���V�[�W��
 *  get_party_id           �p�[�e�BID�̎擾���s���v���V�[�W��
 *  get_party_site_id      �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���v���V�[�W��
 *  get_party_site_id_2    �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���v���V�[�W��
 *  get_site_to_if         �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���v���V�[�W��
 *  get_site_number        �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���v���V�[�W��
 *  exists_party_id        �p�[�e�BID�̎擾���s���v���V�[�W��
 *  exists_xxcmn_site_if   �z����C���^�t�F�[�X�̑��݃`�F�b�N���s���v���V�[�W��
 *  chk_party_status       �p�[�e�B�}�X�^�E�ڋq�}�X�^�̃X�e�[�^�X�̃`�F�b�N���s���v���V�[�W��
 *  chk_site_status        �p�[�e�B�T�C�g�}�X�^�̃X�e�[�^�X�̃`�F�b�N���s���v���V�[�W��
 *  chk_party_num          �ڋq�R�[�h�̑��݃`�F�b�N���s���v���V�[�W��
 *  chk_party_num_if       �ڋq�R�[�h�̑��݃`�F�b�N���s���v���V�[�W��
 *  exists_party_number    �p�[�e�B�T�C�g�}�X�^�̑��݃`�F�b�N���s���v���V�[�W��
 *  check_proc_code        ����Ώۂ̃��R�[�h�ł��邱�Ƃ��`�F�b�N����v���V�[�W��
 *  check_base_code        ���_�R�[�h�`�F�b�N���s���v���V�[�W��
 *  check_party_num        �ڋq�R�[�h�̃`�F�b�N���s���v���V�[�W��
 *  check_ship_to_code     �z����R�[�h�̃`�F�b�N���s���v���V�[�W��
 *  proc_xxcmn_party       �p�[�e�B�A�h�I���}�X�^�̏������s���v���V�[�W��
 *  proc_xxcmn_party_site  �p�[�e�B�T�C�g�A�h�I���}�X�^�̏������s���v���V�[�W��
 *  create_party_account   �p�[�e�B�}�X�^�ƌڋq�}�X�^�̓o�^�������s���v���V�[�W��
 *  update_hz_parties      �p�[�e�B�}�X�^�̍X�V�������s���v���V�[�W��
 *  update_hz_cust_accounts�ڋq�}�X�^�̍X�V�������s���v���V�[�W��
 *  insert_hz_party_sites  �p�[�e�B�T�C�g�}�X�^�̓o�^�������s���v���V�[�W��
 *  update_hz_party_sites  �p�[�e�B�T�C�g�}�X�^�̍X�V�������s���v���V�[�W��
 *  proc_party             ���_���f�������s���v���V�[�W��
 *  proc_cust              �ڋq���f�������s���v���V�[�W��
 *  proc_site              �z���攽�f�������s���v���V�[�W��
 *  proc_party_main        ���_���f�����̐�����s���v���V�[�W��
 *  proc_cust_main         �ڋq���f�����̐�����s���v���V�[�W��
 *  proc_site_main         �z���攽�f�����̐�����s���v���V�[�W��
 *  init_proc              �����������s���v���V�[�W��
 *  term_proc              �C���^�t�F�[�X�̃f�[�^���폜����v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2007/12/11    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/17    1.1   Oracle �R�� ��_ �ύX�v��No61 �Ή�
 *  2008/05/15    1.2   Oracle �R�� ��_ �ύX�v��No66 �Ή�
 *  2008/05/27    1.3   Oracle �ۉ� ���� �����ύX�v��No122�Ή�
 *  2008/06/23    1.4   Oracle �R�� ��_ �s�No259�Ή�
 *  2008/07/07    1.5   Oracle �R�� ��_ I_S_192�Ή�
 *  2008/08/08    1.6   Oracle �R�� ��_ ST�s��C��
 *  2008/08/18    1.7   Oracle �R�� ��_ �ύX�v��No61 �s��C���Ή�
 *  2008/08/19    1.8   Oracle �R�� ��_ T_TE110_BPO_130-002 �w�E216�Ή�
 *  2008/08/25    1.9   Oracle �R�� ��_ T_S_442,T_S_548�Ή�
 *  2008/10/01    1.10  Oracle �Ŗ� ���\ ������Q#291�Ή�
 *  2008/10/07    1.11  Oracle �Ŗ� ���\ T_S_550�Ή�
 *  2009/01/09    1.12  Oracle �Ŗ� ���\ �{��#857�Ή�
 *  2009/02/25    1.13  Oracle �Ŗ� ���\ �{��#1235�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';    --����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';    --�x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2';    --���s
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';    --�X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';    --�X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';    --�X�e�[�^�X(���s)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);            -- ��؂蕶��
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- ���s����
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
  check_base_code_expt        EXCEPTION;     -- ���_�R�[�h�̃`�F�b�N�G���[
  check_party_num_expt        EXCEPTION;     -- �ڋq�R�[�h�̃`�F�b�N�G���[
  check_ship_to_code_expt     EXCEPTION;     -- �z����R�[�h�̃`�F�b�N�G���[
--
  lock_expt                   EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �C���^�t�F�[�X�f�[�^�̑�����
  gn_proc_insert CONSTANT NUMBER := 1;  -- �o�^
  gn_proc_s_ins  CONSTANT NUMBER := 11; -- �o�^(���_�R�t��)
  gn_proc_c_ins  CONSTANT NUMBER := 12; -- �o�^(�ڋq�R�t��)
--
  gn_proc_update CONSTANT NUMBER := 2;  -- �X�V
  gn_proc_s_upd  CONSTANT NUMBER := 21; -- �X�V(���_�R�t��)
  gn_proc_c_upd  CONSTANT NUMBER := 22; -- �X�V(�ڋq�R�t��)
--
  gn_proc_delete CONSTANT NUMBER := 9;  -- �폜
  gn_proc_s_del  CONSTANT NUMBER := 91; -- �폜/�o�^(���_�R�t��)
  gn_proc_c_del  CONSTANT NUMBER := 92; -- �폜/�o�^(�ڋq�R�t��)
  gn_proc_ds_del CONSTANT NUMBER := 93; -- �폜(���_�R�t��)
  gn_proc_dc_del CONSTANT NUMBER := 94; -- �폜(�ڋq�R�t��)
--
  -- �����󋵂�����킷�X�e�[�^�X
  gn_data_status_nomal CONSTANT NUMBER := 0; -- ����
  gn_data_status_error CONSTANT NUMBER := 1; -- ���s
  gn_data_status_warn  CONSTANT NUMBER := 2; -- �x��
--
  gv_msg_kbn           CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_party_if_name     CONSTANT VARCHAR2(100) := 'xxcmn_party_if';
  gv_site_if_name      CONSTANT VARCHAR2(100) := 'xxcmn_site_if';
--
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxcmn800001c';    --�p�b�P�[�W��
--
  --���b�Z�[�W�ԍ�
  gv_msg_80a_001       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001';  --���[�U�[��
  gv_msg_80a_002       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002';  --�R���J�����g��
  gv_msg_80a_003       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003';  --�Z�p���[�^
  gv_msg_80a_004       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005';  --�����f�[�^�i���o���j
  gv_msg_80a_005       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006';  --�G���[�f�[�^�i���o���j
  gv_msg_80a_006       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007';  --�X�L�b�v�f�[�^�i���o���j
  gv_msg_80a_007       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008';  --��������
  gv_msg_80a_008       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009';  --��������
  gv_msg_80a_009       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010';  --�G���[����
  gv_msg_80a_010       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011';  --�X�L�b�v����
  gv_msg_80a_011       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012';  --�����X�e�[�^�X
  gv_msg_80a_012       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00019';  --���_�f�[�^�i���o���j
  gv_msg_80a_013       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00020';  --�ڋq�f�[�^�i���o���j
  gv_msg_80a_014       CONSTANT VARCHAR2(15) := 'APP-XXCMN-00021';  --�z����f�[�^�i���o���j
  gv_msg_80a_015       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002';  --�v���t�@�C���擾�G���[
  gv_msg_80a_016       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --API�G���[(�R���J�����g)
  gv_msg_80a_017       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10019';  --���b�N�G���[
  gv_msg_80a_018       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10022';  --�e�[�u���폜�G���[
  gv_msg_80a_019       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10021';  --�͈͊O�f�[�^
  gv_msg_80a_020       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030';  --�R���J�����g��^�G���[
  gv_msg_80a_021       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118';  --�N������
  gv_msg_80a_022       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10036';  --�f�[�^�擾�G���[�P
--���_�`�F�b�N�p
  gv_msg_80a_030       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10070';  --�X�V�̑��݃`�F�b�N�G���[
  gv_msg_80a_031       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10071';  --�폜�̑��݃`�F�b�N���[�j���O
  gv_msg_80a_032       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10072';  --�o�^�̏d���`�F�b�N�G���[
  gv_msg_80a_033       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10073';  --�ΏۊO���R�[�h
--�ڋq�`�F�b�N�p
  gv_msg_80a_034       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10074';  --�X�V�̑��݃`�F�b�N�G���[
  gv_msg_80a_035       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10075';  --�폜�̑��݃`�F�b�N���[�j���O
  gv_msg_80a_036       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10076';  --�o�^�̏d���`�F�b�N�G���[
--�z����`�F�b�N�p
  gv_msg_80a_037       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10086';  --�X�V�̑��݃`�F�b�N�G���[
  gv_msg_80a_038       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10087';  --�폜�̑��݃`�F�b�N���[�j���O
  gv_msg_80a_039       CONSTANT VARCHAR2(15) := 'APP-XXCMN-10088';  --�o�^�̏d���`�F�b�N�G���[
--
  --�g�[�N��
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';
  gv_tkn_ng_kyoten     CONSTANT VARCHAR2(15) := 'NG_KYOTEN';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_ng_haisou     CONSTANT VARCHAR2(15) := 'NG_HAISOU';
  gv_tkn_ng_kokyaku    CONSTANT VARCHAR2(15) := 'NG_KOKYAKU';
--
  -- �g�pDB��
  gv_xxcmn_party_if_name    CONSTANT VARCHAR2(100) := '���_�C���^�t�F�[�X';
  gv_xxcmn_site_if_name     CONSTANT VARCHAR2(100) := '�z����C���^�t�F�[�X';
  gv_hz_parties_name        CONSTANT VARCHAR2(100) := '�p�[�e�B�}�X�^';
  gv_hz_party_sites_name    CONSTANT VARCHAR2(100) := '�p�[�e�B�T�C�g�}�X�^';
  gv_hz_cust_accounts_name  CONSTANT VARCHAR2(100) := '�ڋq�}�X�^';
  gv_hz_cust_site_name      CONSTANT VARCHAR2(100) := '�ڋq���ݒn�}�X�^';
  gv_xxcmn_parties_name     CONSTANT VARCHAR2(100) := '�p�[�e�B�A�h�I���}�X�^';
  gv_xxcmn_party_sites_name CONSTANT VARCHAR2(100) := '�p�[�e�B�T�C�g�A�h�I���}�X�^';
  gv_hz_cust_site_uses_name CONSTANT VARCHAR2(100) := '�ڋq�g�p�ړI�}�X�^';
  gv_hz_locations_name      CONSTANT VARCHAR2(100) := '�ڋq���Ə��}�X�^';
--
  --�v���t�@�C��
  gv_prf_max_date      CONSTANT VARCHAR2(15) := 'XXCMN_MAX_DATE';
  gv_prf_min_date      CONSTANT VARCHAR2(15) := 'XXCMN_MIN_DATE';
  gv_prf_module        CONSTANT VARCHAR2(25) := 'HZ_CREATED_BY_MODULE';
  gv_pfr_location_addr CONSTANT VARCHAR2(25) := 'XXCMN_LOCATION_ADDR';
  gv_prf_max_date_name CONSTANT VARCHAR2(50) := 'MAX���t';
  gv_prf_min_date_name CONSTANT VARCHAR2(50) := 'MIN���t';
  gv_prf_module_name   CONSTANT VARCHAR2(25) := '�쐬�����W���[��';
  gv_pfr_location_name CONSTANT VARCHAR2(25) := '���P�[�V�����A�h���X';
--
  gv_mode_on            CONSTANT VARCHAR2(1)  := '0';
  gv_status_on          CONSTANT VARCHAR2(1)  := 'A';    -- �L��
  gv_status_off         CONSTANT VARCHAR2(1)  := 'I';    -- ����
  gv_validated_flag_on  CONSTANT VARCHAR2(1)  := 'N';    -- �L��
  gv_validated_flag_off CONSTANT VARCHAR2(1)  := 'I';    -- ����
  gv_primary_flag_on    CONSTANT VARCHAR2(1)  := 'Y';
  gv_primary_flag_off   CONSTANT VARCHAR2(1)  := 'N';    -- 2008/04/17 �ύX�v��No61 �Ή�
--
  gv_meaning_party     CONSTANT VARCHAR2(100) := '���_';
  gv_meaning_cust      CONSTANT VARCHAR2(100) := '�ڋq';
  gv_lookup_type       CONSTANT VARCHAR2(100) := 'CUSTOMER CLASS';
--
  gn_data_init    CONSTANT NUMBER := 0;  -- �����l
  gn_data_nothing CONSTANT NUMBER := 1;  -- �f�[�^�Ȃ�
  gn_data_off     CONSTANT NUMBER := 2;  -- �f�[�^����(����)
  gn_data_on      CONSTANT NUMBER := 3;  -- �f�[�^����(�L��)
  gn_kbn_party    CONSTANT NUMBER := 1;  -- ���_
  gn_kbn_site     CONSTANT NUMBER := 2;  -- �z����
  gn_kbn_upd_site CONSTANT NUMBER := 1;  -- ���_�X�V
  gn_kbn_del_site CONSTANT NUMBER := 2;  -- ���_�폜
  gn_kbn_upd_cust CONSTANT NUMBER := 3;  -- �ڋq�X�V
  gn_kbn_del_cust CONSTANT NUMBER := 4;  -- �ڋq�폜
  gn_kbn_flg_on   CONSTANT NUMBER := 1;  -- �L��
  gn_kbn_flg_off  CONSTANT NUMBER := 2;  -- ����
--
  gv_def_party_num CONSTANT xxcmn_site_if.party_num%TYPE := '000000000';  -- 2008/08/25 Add
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �e�}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE masters_rec IS RECORD(
    tbl_kbn              NUMBER,
    seq_number           xxcmn_party_if.seq_number%TYPE,          -- SEQ�ԍ�
    proc_code            NUMBER,                                  -- �X�V�敪
    k_proc_code          NUMBER,                                  -- �X�V�敪(��)
    base_code            xxcmn_party_if.base_code%TYPE,           -- ���_�R�[�h
    ship_to_code         xxcmn_site_if.ship_to_code%TYPE,         -- �z����R�[�h
    party_name           xxcmn_party_if.party_name%TYPE,          -- ���_���E������
    party_short_name     xxcmn_party_if.party_short_name%TYPE,    -- ���_���E����
    party_name_alt       xxcmn_party_if.party_name_alt%TYPE,      -- ���_���E�J�i
    party_site_name1     xxcmn_site_if.party_site_name1%TYPE,     -- �z���於��1
    party_site_name2     xxcmn_site_if.party_site_name2%TYPE,     -- �z���於��2
    address              xxcmn_party_if.address%TYPE,             -- �Z��
    party_site_addr1     xxcmn_site_if.party_site_addr1%TYPE,     -- �z����Z��1
    party_site_addr2     xxcmn_site_if.party_site_addr2%TYPE,     -- �z����Z��2
    zip                  xxcmn_party_if.zip%TYPE,                 -- �X�֔ԍ�
    phone                xxcmn_party_if.phone%TYPE,               -- �d�b�ԍ�
    fax                  xxcmn_party_if.fax%TYPE,                 -- FAX�ԍ�
    old_division_code    xxcmn_party_if.old_division_code%TYPE,   -- ���E�{���R�[�h
    new_division_code    xxcmn_party_if.new_division_code%TYPE,   -- �V�E�{���R�[�h
    party_num            xxcmn_site_if.party_num%TYPE,            -- �ڋq�R�[�h
    zip2                 xxcmn_party_if.zip2%TYPE,                -- �X�֔ԍ�2
    division_start_date  xxcmn_party_if.division_start_date%TYPE, -- �K�p�J�n���i�{���R�[�h�j
    location_rel_code    xxcmn_party_if.location_rel_code%TYPE,   -- ���_���їL���敪
    customer_name1       xxcmn_site_if.customer_name1%TYPE,       -- �ڋq�E����1
    customer_name2       xxcmn_site_if.customer_name2%TYPE,       -- �ڋq�E����2
    ship_mng_code        xxcmn_party_if.ship_mng_code%TYPE,       -- �o�ɊǗ����敪
    district_code        xxcmn_party_if.district_code%TYPE,       -- �n�於�i�{���R�[�h�p�j
    sale_base_code       xxcmn_site_if.sale_base_code%TYPE,       -- �������㋒�_�R�[�h
    res_sale_base_code   xxcmn_site_if.res_sale_base_code%TYPE,   -- �\��i�����j���㋒�_�R�[�h
    warehouse_code       xxcmn_party_if.warehouse_code%TYPE,      -- �q�֑Ώۉۋ敪
    chain_store          xxcmn_site_if.chain_store%TYPE,          -- ����`�F�[���X
    chain_store_name     xxcmn_site_if.chain_store_name%TYPE,     -- ����`�F�[���X��
    terminal_code        xxcmn_party_if.terminal_code%TYPE,       -- �[���L���敪
    cal_cust_app_flg     xxcmn_site_if.cal_cust_app_flg%TYPE,     -- ���~�q�\���t���O
    direct_ship_code     xxcmn_site_if.direct_ship_code%TYPE,     -- �����敪
    shift_judg_flg       xxcmn_site_if.shift_judg_flg%TYPE,       -- �ڍs����t���O
    spare                xxcmn_party_if.spare%TYPE,               -- �\��
    --�p�[�e�B�}�X�^
    p_party_id           hz_parties.party_id%TYPE,                -- �p�[�e�B�[ID
    validated_flag       hz_parties.validated_flag%TYPE,          -- �L���t���O
    party_number         hz_parties.party_number%TYPE,            -- �g�D�ԍ�
    obj_party_number     hz_parties.object_version_number%TYPE,   -- �I�u�W�F�N�g�o�[�W�����ԍ�
    --�ڋq�}�X�^
    cust_account_id      hz_cust_accounts.cust_account_id%TYPE,   -- �ڋqID
    c_party_id           hz_cust_accounts.party_id%TYPE,          -- �p�[�e�B�[ID
    status               hz_cust_accounts.status%TYPE,            -- �L���X�e�[�^�X
    obj_cust_number      hz_cust_accounts.object_version_number%TYPE, -- �I�u�W�F�N�g�o�[�W�����ԍ�
    --�p�[�e�B�T�C�g�}�X�^
    party_site_id        hz_party_sites.party_site_id%TYPE,       -- �p�[�e�B�T�C�gID
    location_id          hz_party_sites.location_id%TYPE,         -- ���P�[�V����ID
    site_status          hz_party_sites.status%TYPE,              -- �X�e�[�^�X
    obj_site_number      hz_party_sites.object_version_number%TYPE,
    --�ڋq���ݒn�}�X�^
    cust_acct_site_id    hz_cust_acct_sites_all.cust_acct_site_id%TYPE,
    obj_acct_number      hz_cust_acct_sites_all.object_version_number%TYPE,
--
    --�ڋq���Ə��}�X�^
    hzl_location_id      hz_locations.location_id%TYPE,                 -- 2008/08/25 Add
    hzl_obj_number       hz_locations.object_version_number%TYPE,       -- 2008/08/25 Add
-- ���݂̃f�[�^�ȑO�ł̌���
    -- �o�ɊǗ����敪=0
    row_o_ins_cnt        NUMBER,                               -- �o�^����
    row_o_upd_cnt        NUMBER,                               -- �X�V����
    row_o_del_cnt        NUMBER,                               -- �폜����
    -- �o�ɊǗ����敪<>0
    row_z_ins_cnt        NUMBER,                               -- �o�^����
    row_z_upd_cnt        NUMBER,                               -- �X�V����
    row_z_del_cnt        NUMBER,                               -- �폜����
    -- �ڋq������
    row_c_ins_cnt        NUMBER,                               -- �o�^����
    row_c_upd_cnt        NUMBER,                               -- �X�V����
    row_c_del_cnt        NUMBER,                               -- �폜����
    -- �z���悪����
    row_s_ins_cnt        NUMBER,                               -- �o�^����
    row_s_upd_cnt        NUMBER,                               -- �X�V����
    row_s_del_cnt        NUMBER,                               -- �폜����
    -- �ڋq=NULL
    row_n_ins_cnt        NUMBER,                               -- �o�^����
    row_n_upd_cnt        NUMBER,                               -- �X�V����
    row_n_del_cnt        NUMBER,                               -- �폜����
    -- �ڋq<>NULL
    row_m_ins_cnt        NUMBER,                               -- �o�^����
    row_m_upd_cnt        NUMBER,                               -- �X�V����
    row_m_del_cnt        NUMBER                                -- �폜����
  );
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- �o�͂��郍�O���i�[���郌�R�[�h
  TYPE report_rec IS RECORD(
    seq_number           xxcmn_party_if.seq_number%TYPE,          -- SEQ�ԍ�
    proc_code            NUMBER,                                  -- �X�V�敪
    k_proc_code          NUMBER,                                  -- �X�V�敪
    base_code            xxcmn_party_if.base_code%TYPE,           -- ���_�R�[�h
    ship_to_code         xxcmn_site_if.ship_to_code%TYPE,         -- �z����R�[�h
    party_name           xxcmn_party_if.party_name%TYPE,          -- ���_���E������
    party_short_name     xxcmn_party_if.party_short_name%TYPE,    -- ���_���E����
    party_name_alt       xxcmn_party_if.party_name_alt%TYPE,      -- ���_���E�J�i
    party_site_name1     xxcmn_site_if.party_site_name1%TYPE,     -- �z���於��1
    party_site_name2     xxcmn_site_if.party_site_name2%TYPE,     -- �z���於��2
    address              xxcmn_party_if.address%TYPE,             -- �Z��
    party_site_addr1     xxcmn_site_if.party_site_addr1%TYPE,     -- �z����Z��1
    party_site_addr2     xxcmn_site_if.party_site_addr2%TYPE,     -- �z����Z��2
    zip                  xxcmn_party_if.zip%TYPE,                 -- �X�֔ԍ�
    phone                xxcmn_party_if.phone%TYPE,               -- �d�b�ԍ�
    fax                  xxcmn_party_if.fax%TYPE,                 -- FAX�ԍ�
    old_division_code    xxcmn_party_if.old_division_code%TYPE,   -- ���E�{���R�[�h
    new_division_code    xxcmn_party_if.new_division_code%TYPE,   -- �V�E�{���R�[�h
    party_num            xxcmn_site_if.party_num%TYPE,            -- �ڋq�R�[�h
    zip2                 xxcmn_party_if.zip2%TYPE,                -- �X�֔ԍ�2
    division_start_date  xxcmn_party_if.division_start_date%TYPE, -- �K�p�J�n���i�{���R�[�h�j
    location_rel_code    xxcmn_party_if.location_rel_code%TYPE,   -- ���_���їL���敪
    customer_name1       xxcmn_site_if.customer_name1%TYPE,       -- �ڋq�E����1
    customer_name2       xxcmn_site_if.customer_name2%TYPE,       -- �ڋq�E����2
    ship_mng_code        xxcmn_party_if.ship_mng_code%TYPE,       -- �o�ɊǗ����敪
    district_code        xxcmn_party_if.district_code%TYPE,       -- �n�於�i�{���R�[�h�p�j
    sale_base_code       xxcmn_site_if.sale_base_code%TYPE,       -- �������㋒�_�R�[�h
    res_sale_base_code   xxcmn_site_if.res_sale_base_code%TYPE,   -- �\��i�����j���㋒�_�R�[�h
    warehouse_code       xxcmn_party_if.warehouse_code%TYPE,      -- �q�֑Ώۉۋ敪
    chain_store          xxcmn_site_if.chain_store%TYPE,          -- ����`�F�[���X
    chain_store_name     xxcmn_site_if.chain_store_name%TYPE,     -- ����`�F�[���X��
    terminal_code        xxcmn_party_if.terminal_code%TYPE,       -- �[���L���敪
    cal_cust_app_flg     xxcmn_site_if.cal_cust_app_flg%TYPE,     -- ���~�q�\���t���O
    direct_ship_code     xxcmn_site_if.direct_ship_code%TYPE,     -- �����敪
    shift_judg_flg       xxcmn_site_if.shift_judg_flg%TYPE,       -- �ڍs����t���O
    spare                xxcmn_party_if.spare%TYPE,               -- �\��
    row_level_status     NUMBER,                                  -- 0.����,1.���s,2.�x��
    -- ���f��e�[�u���t���O(0:�� 1:��)
    hps_flg              NUMBER,                                  --�p�[�e�B�}�X�^
    hpss_flg             NUMBER,                                  --�p�[�e�B�T�C�g�}�X�^
    hca_flg              NUMBER,                                  --�ڋq�}�X�^
    hcas_flg             NUMBER,                                  --�ڋq���ݒn�}�X�^
    xps_flg              NUMBER,                                  --�p�[�e�B�A�h�I���}�X�^
    xpss_flg             NUMBER,                                  --�p�[�e�B�T�C�g�A�h�I���}�X�^
    hcsu_flg             NUMBER,                                  --�ڋq�g�p�ړI�}�X�^
-- 2008/08/25 Add
    hzl_flg              NUMBER,                                  --�ڋq���Ə��}�X�^
--
    message              VARCHAR2(1000)
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
  gv_min_date            VARCHAR2(10);                               -- �ŏ����t
  gv_max_date            VARCHAR2(10);                               -- �ő���t
  gv_created_by_module   VARCHAR2(50);                               -- �쐬���W���[����
  gv_location_addr       VARCHAR2(50);                               -- ���P�[�V�����A�h���X
  gv_customer_class_code VARCHAR2(30);
--
-- 2008/08/18 Mod ��
/*
  gn_created_by              NUMBER(15);
  gd_creation_date           DATE;
  gn_last_updated_by         NUMBER(15);
  gd_last_update_date        DATE;
  gn_last_update_login       NUMBER(15);
  gn_request_id              NUMBER(15);
  gn_program_application_id  NUMBER(15);
  gn_program_id              NUMBER(15);
*/
  gn_created_by              NUMBER;
  gd_creation_date           DATE;
  gn_last_updated_by         NUMBER;
  gd_last_update_date        DATE;
  gn_last_update_login       NUMBER;
  gn_request_id              NUMBER;
  gn_program_application_id  NUMBER;
  gn_program_id              NUMBER;
-- 2008/08/18 Mod ��
  gd_program_update_date     DATE;
  gd_min_date                DATE;
  gd_max_date                DATE;
  -- ===============================
  -- ���_�p
  -- ===============================
  gn_p_target_cnt    NUMBER;                    -- �Ώی���
  gn_p_normal_cnt    NUMBER;                    -- ���팏��
  gn_p_error_cnt     NUMBER;                    -- �G���[����
  gn_p_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_p_report_cnt    NUMBER;                    -- ���|�[�g����
  -- ===============================
  -- �z����p
  -- ===============================
  gn_s_target_cnt    NUMBER;                    -- �Ώی���
  gn_s_normal_cnt    NUMBER;                    -- ���팏��
  gn_s_error_cnt     NUMBER;                    -- �G���[����
  gn_s_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_s_report_cnt    NUMBER;                    -- ���|�[�g����
  -- ===============================
  -- �ڋq�p
  -- ===============================
  gn_c_target_cnt    NUMBER;                    -- �Ώی���
  gn_c_normal_cnt    NUMBER;                    -- ���팏��
  gn_c_error_cnt     NUMBER;                    -- �G���[����
  gn_c_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_c_report_cnt    NUMBER;                    -- ���|�[�g����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- �ڋq�}�X�^
  -- ���_IF���
  CURSOR gc_hca_party_cur
  IS
    SELECT hca.party_id
    FROM   hz_cust_accounts hca
    WHERE  EXISTS (
      SELECT xpi.base_code
      FROM   xxcmn_party_if xpi
      WHERE  hca.account_number = xpi.base_code
      AND    ROWNUM = 1)
    AND    hca.status = gv_status_on
    FOR UPDATE OF hca.party_id NOWAIT;
--
  -- �z����IF���
  CURSOR gc_hca_site_cur
  IS
    SELECT hca.party_id
    FROM   hz_cust_accounts hca
    WHERE  EXISTS (
      SELECT xsi.party_num
      FROM   xxcmn_site_if xsi
      WHERE  hca.account_number = xsi.party_num
      AND    ROWNUM = 1)
    AND    hca.status = gv_status_on
    FOR UPDATE OF hca.party_id NOWAIT;
--
  -- �p�[�e�B�}�X�^
  -- ���_IF���
  CURSOR gc_hp_party_cur
  IS
    SELECT hp.party_id
    FROM   hz_parties hp
    WHERE  EXISTS (
      SELECT xpi.base_code
      FROM   xxcmn_party_if xpi
      WHERE  hp.party_number = xpi.base_code
      AND    ROWNUM = 1)
    AND    hp.validated_flag = gv_validated_flag_on
    FOR UPDATE OF hp.party_id NOWAIT;
--
  -- �z����IF���
  CURSOR gc_hp_site_cur
  IS
    SELECT hp.party_id
    FROM   hz_parties hp
    WHERE  EXISTS (
      SELECT xsi.party_num
      FROM   xxcmn_site_if xsi
      WHERE  hp.party_number = xsi.party_num
      AND    ROWNUM = 1)
    AND    hp.validated_flag = gv_validated_flag_on
    FOR UPDATE OF hp.party_id NOWAIT;
--
  -- �p�[�e�B�[�A�h�I���}�X�^
  -- ���_IF���
  CURSOR gc_xp_party_cur
  IS
    SELECT xp.party_id
    FROM   xxcmn_parties xp
    WHERE  EXISTS (
      SELECT hps.party_id
      FROM   hz_parties hps
      WHERE  EXISTS (
        SELECT xpi.base_code
        FROM   xxcmn_party_if xpi
        WHERE  hps.party_number = xpi.base_code
        AND    ROWNUM = 1)
      AND    hps.validated_flag = gv_validated_flag_on
      AND    xp.party_id = hps.party_id
      AND    ROWNUM = 1)
    FOR UPDATE OF xp.party_id NOWAIT;
--
  -- �z����IF���
  CURSOR gc_xp_site_cur
  IS
    SELECT xp.party_id
    FROM   xxcmn_parties xp
    WHERE  EXISTS (
      SELECT hps.party_id
      FROM   hz_parties hps
      WHERE  EXISTS (
        SELECT xsi.party_num
        FROM   xxcmn_site_if xsi
        WHERE  hps.party_number = xsi.party_num
        AND    ROWNUM = 1)
      AND    hps.validated_flag = gv_validated_flag_on
      AND    xp.party_id = hps.party_id
      AND    ROWNUM = 1)
    FOR UPDATE OF xp.party_id NOWAIT;
--
  -- �p�[�e�B�T�C�g�}�X�^
  -- �z����IF���
  CURSOR gc_hps_site_cur
  IS
-- 2008/08/25 Mod ��
/*
    SELECT hps.party_site_id
    FROM   hz_party_sites hps
    WHERE  EXISTS (
      SELECT hcas.party_site_id
      FROM   hz_cust_acct_sites_all hcas
      WHERE  EXISTS (
        SELECT xsi.ship_to_code
        FROM   xxcmn_site_if xsi
        WHERE  hcas.attribute18 = xsi.ship_to_code
        AND    ROWNUM = 1)
      AND    hps.party_site_id = hcas.party_site_id
      AND    ROWNUM = 1)
    AND    hps.status = gv_status_on
*/
    SELECT hps.party_site_id
    FROM   hz_party_sites hps                     -- �p�[�e�B�T�C�g�}�X�^
    WHERE  EXISTS (
      SELECT hcas.location_id
      FROM   hz_locations hcas                    -- �ڋq���Ə��}�X�^
      WHERE  EXISTS (
        SELECT xsi.ship_to_code
        FROM   xxcmn_site_if xsi
        WHERE  hcas.province = xsi.ship_to_code
        AND    ROWNUM = 1)
      AND    hps.location_id = hcas.location_id
      AND    ROWNUM = 1)
    AND    hps.status = gv_status_on
-- 2008/08/25 Mod ��
    FOR UPDATE OF hps.party_site_id NOWAIT;
--
  -- �p�[�e�B�[�T�C�g�A�h�I���}�X�^
  CURSOR gc_xps_site_cur
  IS
-- 2008/08/25 Mod ��
/*
    SELECT xps.party_site_id
    FROM   xxcmn_party_sites xps
    WHERE  EXISTS (
      SELECT hcas.party_site_id
      FROM   hz_cust_acct_sites_all hcas
      WHERE  EXISTS (
        SELECT xsi.ship_to_code
        FROM   xxcmn_site_if xsi
        WHERE  hcas.attribute18 = xsi.ship_to_code
        AND    ROWNUM = 1)
      AND    xps.party_site_id = hcas.party_site_id
      AND    ROWNUM = 1)
*/
    SELECT xps.party_site_id
    FROM   xxcmn_party_sites xps                  -- �p�[�e�B�T�C�g�A�h�I���}�X�^
    WHERE  EXISTS (
      SELECT hcas.location_id
      FROM   hz_locations hcas                    -- �ڋq���Ə��}�X�^
      WHERE  EXISTS (
        SELECT xsi.ship_to_code
        FROM   xxcmn_site_if xsi
        WHERE  hcas.province = xsi.ship_to_code
        AND    ROWNUM = 1)
      AND    xps.location_id = hcas.location_id
      AND    ROWNUM = 1)
-- 2008/08/25 Mod ��
    FOR UPDATE OF xps.party_site_id NOWAIT;
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
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
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
                                            gv_tkn_ng_profile, gv_prf_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gd_min_date := FND_DATE.STRING_TO_DATE(gv_min_date,'YYYY/MM/DD');
--
    --�쐬�����W���[���擾
    gv_created_by_module := SUBSTR(FND_PROFILE.VALUE(gv_prf_module),1,50);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_created_by_module IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
                                            gv_tkn_ng_profile, gv_prf_module_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --���P�[�V�����A�h���X�擾
    gv_location_addr := SUBSTR(FND_PROFILE.VALUE(gv_pfr_location_addr),1,50);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_location_addr IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,        gv_msg_80a_015,
                                            gv_tkn_ng_profile, gv_pfr_location_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
   * Description      : ���_�C���^�t�F�[�X�̃e�[�u�����b�N���s���܂��B
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
    lb_retcd          BOOLEAN;
    ln_party_id       hz_parties.party_id%TYPE;
    ln_party_site_id  hz_party_sites.party_site_id%TYPE;
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
    -- �e�[�u�����b�N����(���_�C���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_party_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                            gv_tkn_table, gv_xxcmn_party_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- �e�[�u�����b�N����(�z����C���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock(gv_msg_kbn, gv_site_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                            gv_tkn_table, gv_xxcmn_site_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- �ڋq�}�X�^
    BEGIN
      -- ���_IF���
      OPEN gc_hca_party_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_cust_accounts_name);
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
    BEGIN
      -- �z����IF���
      OPEN gc_hca_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_cust_accounts_name);
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
    -- �p�[�e�B�}�X�^
    BEGIN
      -- ���_IF���
      OPEN gc_hp_party_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_parties_name);
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
    BEGIN
      -- �z����IF���
      OPEN gc_hp_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_parties_name);
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
    -- �p�[�e�B�[�A�h�I���}�X�^
    BEGIN
      -- ���_IF���
      OPEN gc_xp_party_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_xxcmn_parties_name);
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
    BEGIN
      -- �z����IF���
      OPEN gc_xp_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_xxcmn_parties_name);
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
    -- �p�[�e�B�T�C�g�}�X�^
    BEGIN
      -- �z����IF���
      OPEN gc_hps_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_hz_party_sites_name);
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
    -- �p�[�e�B�[�T�C�g�A�h�I���}�X�^
    BEGIN
      -- �z����IF���
      OPEN gc_xps_site_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_017,
                                              gv_tkn_table, gv_xxcmn_party_sites_name);
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
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
   * Procedure Name   : init_status
   * Description      : �X�e�[�^�X�����������܂��B
   ***********************************************************************************/
  PROCEDURE init_status(
    ir_status_rec IN OUT NOCOPY status_rec,  -- ������
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
    ov_errbuf        OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
   * Function Name    : chk_party_id
   * Description      : �ڋq�E�p�[�e�B�}�X�^�̏�Ԃ�Ԃ��܂��B
   ***********************************************************************************/
  FUNCTION chk_party_id(
    ir_masters_rec IN masters_rec)
    RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_id'; --�v���O������
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_kbn     NUMBER;
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
    ln_kbn := gn_data_init;
--
    -- �p�[�e�B�}�X�^���ڋq�}�X�^�ɑ��݂��Ȃ�
    IF ((ir_masters_rec.p_party_id IS NULL) AND (ir_masters_rec.c_party_id IS NULL)) THEN
      ln_kbn := gn_data_nothing;
--
    ELSE
      -- �p�[�e�B�}�X�^���ڋq�}�X�^�ɑ��݂���
      IF ((ir_masters_rec.p_party_id IS NOT NULL)
      AND (ir_masters_rec.c_party_id IS NOT NULL)) THEN
--
        -- �p�[�e�B�}�X�^.�p�[�e�B�[ID = �ڋq�}�X�^.�p�[�e�B�[ID
        IF (ir_masters_rec.p_party_id = ir_masters_rec.c_party_id) THEN
--
          -- �p�[�e�B�}�X�^.�L���t���O='I'(����)
          -- �ڋq�}�X�^.�X�e�[�^�X='I'(����)
          IF ((ir_masters_rec.validated_flag = gv_validated_flag_off)
          AND (ir_masters_rec.status = gv_status_off)) THEN
            ln_kbn := gn_data_off;
--
          -- �p�[�e�B�}�X�^.�L���t���O='N'(�L��)
          -- �ڋq�}�X�^.�X�e�[�^�X='A'(�L��)
          ELSIF ((ir_masters_rec.validated_flag = gv_validated_flag_on)
             AND (ir_masters_rec.status = gv_status_on)) THEN
            ln_kbn := gn_data_on;
          END IF;
        END IF;
      END IF;
    END IF;
--
    RETURN ln_kbn;
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
  END chk_party_id;
--
  /***********************************************************************************
   * Procedure Name   : add_p_report
   * Description      : ���|�[�g�p�f�[�^��ݒ肵�܂��B(���_�p)
   ***********************************************************************************/
  PROCEDURE add_p_report(
    ir_status_rec  IN            status_rec,   -- ������
    ir_masters_rec IN            masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    it_report_tbl  IN OUT NOCOPY report_tbl,   -- ���|�[�g�f�[�^
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_p_report'; -- �v���O������
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
    lr_report_rec.seq_number          := ir_masters_rec.seq_number;
    lr_report_rec.proc_code           := ir_masters_rec.proc_code;
    lr_report_rec.base_code           := ir_masters_rec.base_code;
    lr_report_rec.party_name          := ir_masters_rec.party_name;
    lr_report_rec.party_short_name    := ir_masters_rec.party_short_name;
    lr_report_rec.party_name_alt      := ir_masters_rec.party_name_alt;
    lr_report_rec.address             := ir_masters_rec.address;
    lr_report_rec.zip                 := ir_masters_rec.zip;
    lr_report_rec.phone               := ir_masters_rec.phone;
    lr_report_rec.fax                 := ir_masters_rec.fax;
    lr_report_rec.old_division_code   := ir_masters_rec.old_division_code;
    lr_report_rec.new_division_code   := ir_masters_rec.new_division_code;
    lr_report_rec.division_start_date := ir_masters_rec.division_start_date;
    lr_report_rec.location_rel_code   := ir_masters_rec.location_rel_code;
    lr_report_rec.ship_mng_code       := ir_masters_rec.ship_mng_code;
    lr_report_rec.district_code       := ir_masters_rec.district_code;
    lr_report_rec.warehouse_code      := ir_masters_rec.warehouse_code;
    lr_report_rec.terminal_code       := ir_masters_rec.terminal_code;
    lr_report_rec.zip2                := ir_masters_rec.zip2;
    lr_report_rec.spare               := ir_masters_rec.spare;
    lr_report_rec.row_level_status    := ir_status_rec.row_level_status;
    lr_report_rec.message             := ir_status_rec.row_err_message;
--
    lr_report_rec.hps_flg         := 0;
    lr_report_rec.hpss_flg        := 0;
    lr_report_rec.hca_flg         := 0;
    lr_report_rec.hcas_flg        := 0;
    lr_report_rec.xps_flg         := 0;
    lr_report_rec.xpss_flg        := 0;
    lr_report_rec.hcsu_flg        := 0;
    lr_report_rec.hzl_flg         := 0;      -- 2008/08/25 Add
--
    -- ���|�[�g�e�[�u���ɒǉ�
    it_report_tbl(gn_p_report_cnt) := lr_report_rec;
    gn_p_report_cnt := gn_p_report_cnt + 1;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END add_p_report;
--
  /***********************************************************************************
   * Procedure Name   : add_s_report
   * Description      : ���|�[�g�p�f�[�^��ݒ肵�܂��B(�z����p)
   ***********************************************************************************/
  PROCEDURE add_s_report(
    ir_status_rec  IN            status_rec,   -- ������
    ir_masters_rec IN            masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    it_report_tbl  IN OUT NOCOPY report_tbl,   -- ���|�[�g�f�[�^
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_s_report'; -- �v���O������
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
    lr_report_rec.seq_number         := ir_masters_rec.seq_number;
    lr_report_rec.proc_code          := ir_masters_rec.proc_code;
    lr_report_rec.k_proc_code        := ir_masters_rec.k_proc_code;
    lr_report_rec.ship_to_code       := ir_masters_rec.ship_to_code;
    lr_report_rec.base_code          := ir_masters_rec.base_code;
    lr_report_rec.party_site_name1   := ir_masters_rec.party_site_name1;
    lr_report_rec.party_site_name2   := ir_masters_rec.party_site_name2;
    lr_report_rec.party_site_addr1   := ir_masters_rec.party_site_addr1;
    lr_report_rec.party_site_addr2   := ir_masters_rec.party_site_addr2;
    lr_report_rec.phone              := ir_masters_rec.phone;
    lr_report_rec.fax                := ir_masters_rec.fax;
    lr_report_rec.zip                := ir_masters_rec.zip;
    lr_report_rec.party_num          := ir_masters_rec.party_num;
    lr_report_rec.zip2               := ir_masters_rec.zip2;
    lr_report_rec.customer_name1     := ir_masters_rec.customer_name1;
    lr_report_rec.customer_name2     := ir_masters_rec.customer_name2;
    lr_report_rec.sale_base_code     := ir_masters_rec.sale_base_code;
    lr_report_rec.res_sale_base_code := ir_masters_rec.res_sale_base_code;
    lr_report_rec.chain_store        := ir_masters_rec.chain_store;
    lr_report_rec.chain_store_name   := ir_masters_rec.chain_store_name;
    lr_report_rec.cal_cust_app_flg   := ir_masters_rec.cal_cust_app_flg;
    lr_report_rec.row_level_status   := ir_status_rec.row_level_status;
    lr_report_rec.message            := ir_status_rec.row_err_message;
--
    lr_report_rec.hps_flg         := 0;
    lr_report_rec.hpss_flg        := 0;
    lr_report_rec.hca_flg         := 0;
    lr_report_rec.hcas_flg        := 0;
    lr_report_rec.xps_flg         := 0;
    lr_report_rec.xpss_flg        := 0;
    lr_report_rec.hcsu_flg        := 0;
    lr_report_rec.hzl_flg         := 0;      -- 2008/08/25 Add
--
    -- ���|�[�g�e�[�u���ɒǉ�
    it_report_tbl(gn_s_report_cnt) := lr_report_rec;
    gn_s_report_cnt := gn_s_report_cnt + 1;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END add_s_report;
--
  /***********************************************************************************
   * Procedure Name   : add_c_report
   * Description      : ���|�[�g�p�f�[�^��ݒ肵�܂��B(�ڋq�p)
   ***********************************************************************************/
  PROCEDURE add_c_report(
    ir_status_rec  IN            status_rec,   -- ������
    ir_masters_rec IN            masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    it_report_tbl  IN OUT NOCOPY report_tbl,   -- ���|�[�g�f�[�^
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_c_report'; -- �v���O������
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
    lr_report_rec.seq_number         := ir_masters_rec.seq_number;
    lr_report_rec.proc_code          := ir_masters_rec.proc_code;
    lr_report_rec.k_proc_code        := ir_masters_rec.k_proc_code;
    lr_report_rec.ship_to_code       := ir_masters_rec.ship_to_code;
    lr_report_rec.base_code          := ir_masters_rec.base_code;
    lr_report_rec.party_site_name1   := ir_masters_rec.party_site_name1;
    lr_report_rec.party_site_name2   := ir_masters_rec.party_site_name2;
    lr_report_rec.party_site_addr1   := ir_masters_rec.party_site_addr1;
    lr_report_rec.party_site_addr2   := ir_masters_rec.party_site_addr2;
    lr_report_rec.phone              := ir_masters_rec.phone;
    lr_report_rec.fax                := ir_masters_rec.fax;
    lr_report_rec.zip                := ir_masters_rec.zip;
    lr_report_rec.party_num          := ir_masters_rec.party_num;
    lr_report_rec.zip2               := ir_masters_rec.zip2;
    lr_report_rec.customer_name1     := ir_masters_rec.customer_name1;
    lr_report_rec.customer_name2     := ir_masters_rec.customer_name2;
    lr_report_rec.sale_base_code     := ir_masters_rec.sale_base_code;
    lr_report_rec.res_sale_base_code := ir_masters_rec.res_sale_base_code;
    lr_report_rec.chain_store        := ir_masters_rec.chain_store;
    lr_report_rec.chain_store_name   := ir_masters_rec.chain_store_name;
    lr_report_rec.cal_cust_app_flg   := ir_masters_rec.cal_cust_app_flg;
    lr_report_rec.row_level_status   := ir_status_rec.row_level_status;
    lr_report_rec.message            := ir_status_rec.row_err_message;
--
    lr_report_rec.hps_flg         := 0;
    lr_report_rec.hpss_flg        := 0;
    lr_report_rec.hca_flg         := 0;
    lr_report_rec.hcas_flg        := 0;
    lr_report_rec.xps_flg         := 0;
    lr_report_rec.xpss_flg        := 0;
    lr_report_rec.hcsu_flg        := 0;
    lr_report_rec.hzl_flg         := 0;      -- 2008/08/25 Add
--
    -- ���|�[�g�e�[�u���ɒǉ�
    it_report_tbl(gn_c_report_cnt) := lr_report_rec;
    gn_c_report_cnt := gn_c_report_cnt + 1;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END add_c_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_p_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂��B(���_�p)
   ***********************************************************************************/
  PROCEDURE disp_p_report(
    it_report_tbl  IN            report_tbl,   -- ���|�[�g�f�[�^
    disp_kbn       IN            NUMBER,       -- �\���Ώۋ敪(0:����,1:�ُ�,2:�x��)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_p_report'; -- �v���O������
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
    lv_div_date   VARCHAR2(10);
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
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_004);
--
    -- �G���[
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_005);
--
    -- �x��
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �ݒ肳��Ă��郌�|�[�g�̏o��
    <<disp_p_report_loop>>
    FOR i IN 0..gn_p_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(i);
--
      lv_div_date := TO_CHAR(lr_report_rec.division_start_date,'YYYY/MM/DD');
--
      --���̓f�[�^�̍č\��
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number) || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.proc_code)  || gv_msg_pnt ||
                   lr_report_rec.base_code           || gv_msg_pnt ||
                   lr_report_rec.party_name          || gv_msg_pnt ||
                   lr_report_rec.party_short_name    || gv_msg_pnt ||
                   lr_report_rec.party_name_alt      || gv_msg_pnt ||
                   lr_report_rec.address             || gv_msg_pnt ||
                   lr_report_rec.zip                 || gv_msg_pnt ||
                   lr_report_rec.phone               || gv_msg_pnt ||
                   lr_report_rec.fax                 || gv_msg_pnt ||
                   lr_report_rec.old_division_code   || gv_msg_pnt ||
                   lr_report_rec.new_division_code   || gv_msg_pnt ||
                   lv_div_date                       || gv_msg_pnt ||
                   lr_report_rec.location_rel_code   || gv_msg_pnt ||
                   lr_report_rec.ship_mng_code       || gv_msg_pnt ||
                   lr_report_rec.district_code       || gv_msg_pnt ||
                   lr_report_rec.warehouse_code      || gv_msg_pnt ||
                   lr_report_rec.terminal_code       || gv_msg_pnt ||
                   lr_report_rec.zip2                || gv_msg_pnt ||
                   lr_report_rec.spare;
--
      -- �Ώ�
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- ����
        IF (disp_kbn = gn_data_status_nomal) THEN
          --�p�[�e�B�}�X�^
          IF (lr_report_rec.hps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_parties_name);
          END IF;
          --�p�[�e�B�T�C�g�}�X�^
          IF (lr_report_rec.hpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_party_sites_name);
          END IF;
          --�ڋq�}�X�^
          IF (lr_report_rec.hca_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_accounts_name);
          END IF;
          --�ڋq���ݒn�}�X�^
          IF (lr_report_rec.hcas_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_name);
          END IF;
          --�p�[�e�B�A�h�I���}�X�^
          IF (lr_report_rec.xps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_parties_name);
          END IF;
          --�p�[�e�B�T�C�g�A�h�I���}�X�^
          IF (lr_report_rec.xpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_party_sites_name);
          END IF;
          --�ڋq�g�p�ړI�}�X�^
          IF (lr_report_rec.hcsu_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_uses_name);
          END IF;
-- 2008/08/25 Add ��
          --�ڋq���Ə��}�X�^
          IF (lr_report_rec.hzl_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_locations_name);
          END IF;
-- 2008/08/25 Add ��
--
        -- ����ȊO
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_p_report_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END disp_p_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_s_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂��B(�z����p)
   ***********************************************************************************/
  PROCEDURE disp_s_report(
    it_report_tbl  IN            report_tbl,   -- ���|�[�g�f�[�^
    disp_kbn       IN            NUMBER,       -- �\���Ώۋ敪(0:����,1:�ُ�,2:�x��)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_s_report'; -- �v���O������
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
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_004);
--
    -- �G���[
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_005);
--
    -- �x��
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �ݒ肳��Ă��郌�|�[�g�̏o��
    <<disp_s_report_loop>>
    FOR i IN 0..gn_s_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(i);
--
      --���̓f�[�^�̍č\��
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number)  || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.k_proc_code) || gv_msg_pnt ||
                   lr_report_rec.ship_to_code         || gv_msg_pnt ||
                   lr_report_rec.base_code            || gv_msg_pnt ||
                   lr_report_rec.party_site_name1     || gv_msg_pnt ||
                   lr_report_rec.party_site_name2     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr1     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr2     || gv_msg_pnt ||
                   lr_report_rec.phone                || gv_msg_pnt ||
                   lr_report_rec.fax                  || gv_msg_pnt ||
                   lr_report_rec.zip                  || gv_msg_pnt ||
                   lr_report_rec.party_num            || gv_msg_pnt ||
                   lr_report_rec.zip2                 || gv_msg_pnt ||
                   lr_report_rec.customer_name1       || gv_msg_pnt ||
                   lr_report_rec.customer_name2       || gv_msg_pnt ||
                   lr_report_rec.sale_base_code       || gv_msg_pnt ||
                   lr_report_rec.res_sale_base_code   || gv_msg_pnt ||
                   lr_report_rec.chain_store          || gv_msg_pnt ||
                   lr_report_rec.chain_store_name     || gv_msg_pnt ||
                   lr_report_rec.cal_cust_app_flg;
--
      -- �Ώ�
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- ����
        IF (disp_kbn = gn_data_status_nomal) THEN
          --�p�[�e�B�}�X�^
          IF (lr_report_rec.hps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_parties_name);
          END IF;
          --�p�[�e�B�T�C�g�}�X�^
          IF (lr_report_rec.hpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_party_sites_name);
          END IF;
          --�ڋq�}�X�^
          IF (lr_report_rec.hca_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_accounts_name);
          END IF;
          --�ڋq���ݒn�}�X�^
          IF (lr_report_rec.hcas_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_name);
          END IF;
          --�p�[�e�B�A�h�I���}�X�^
          IF (lr_report_rec.xps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_parties_name);
          END IF;
          --�p�[�e�B�T�C�g�A�h�I���}�X�^
          IF (lr_report_rec.xpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_party_sites_name);
          END IF;
          --�ڋq�g�p�ړI�}�X�^
          IF (lr_report_rec.hcsu_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_uses_name);
          END IF;
-- 2008/08/25 Add ��
          --�ڋq���Ə��}�X�^
          IF (lr_report_rec.hzl_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_locations_name);
          END IF;
-- 2008/08/25 Add ��
--
        -- ����ȊO
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_s_report_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END disp_s_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_c_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂��B(�ڋq�p)
   ***********************************************************************************/
  PROCEDURE disp_c_report(
    it_report_tbl  IN            report_tbl,   -- ���|�[�g�f�[�^
    disp_kbn       IN            NUMBER,       -- �\���Ώۋ敪(0:����,1:�ُ�,2:�x��)
    ov_errbuf         OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_c_report'; -- �v���O������
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
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_004);
--
    -- �G���[
    ELSIF (disp_kbn = gn_data_status_error) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_005);
--
    -- �x��
    ELSIF (disp_kbn = gn_data_status_warn) THEN
      lv_dspbuf := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_006);
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dspbuf);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �ݒ肳��Ă��郌�|�[�g�̏o��
    <<disp_c_report_loop>>
    FOR i IN 0..gn_c_report_cnt-1 LOOP
      lr_report_rec := it_report_tbl(i);
--
      --���̓f�[�^�̍č\��
      lv_dspbuf := TO_CHAR(lr_report_rec.seq_number)  || gv_msg_pnt ||
                   TO_CHAR(lr_report_rec.k_proc_code) || gv_msg_pnt ||
                   lr_report_rec.ship_to_code         || gv_msg_pnt ||
                   lr_report_rec.base_code            || gv_msg_pnt ||
                   lr_report_rec.party_site_name1     || gv_msg_pnt ||
                   lr_report_rec.party_site_name2     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr1     || gv_msg_pnt ||
                   lr_report_rec.party_site_addr2     || gv_msg_pnt ||
                   lr_report_rec.phone                || gv_msg_pnt ||
                   lr_report_rec.fax                  || gv_msg_pnt ||
                   lr_report_rec.zip                  || gv_msg_pnt ||
                   lr_report_rec.party_num            || gv_msg_pnt ||
                   lr_report_rec.zip2                 || gv_msg_pnt ||
                   lr_report_rec.customer_name1       || gv_msg_pnt ||
                   lr_report_rec.customer_name2       || gv_msg_pnt ||
                   lr_report_rec.sale_base_code       || gv_msg_pnt ||
                   lr_report_rec.res_sale_base_code   || gv_msg_pnt ||
                   lr_report_rec.chain_store          || gv_msg_pnt ||
                   lr_report_rec.chain_store_name     || gv_msg_pnt ||
                   lr_report_rec.cal_cust_app_flg;
--
      -- �Ώ�
      IF (lr_report_rec.row_level_status = disp_kbn) THEN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_dspbuf);
--
        -- ����
        IF (disp_kbn = gn_data_status_nomal) THEN
          --�p�[�e�B�}�X�^
          IF (lr_report_rec.hps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_parties_name);
          END IF;
          --�p�[�e�B�T�C�g�}�X�^
          IF (lr_report_rec.hpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_party_sites_name);
          END IF;
          --�ڋq�}�X�^
          IF (lr_report_rec.hca_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_accounts_name);
          END IF;
          --�ڋq���ݒn�}�X�^
          IF (lr_report_rec.hcas_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_name);
          END IF;
          --�p�[�e�B�A�h�I���}�X�^
          IF (lr_report_rec.xps_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_parties_name);
          END IF;
          --�p�[�e�B�T�C�g�A�h�I���}�X�^
          IF (lr_report_rec.xpss_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_xxcmn_party_sites_name);
          END IF;
          --�ڋq�g�p�ړI�}�X�^
          IF (lr_report_rec.hcsu_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_cust_site_uses_name);
          END IF;
-- 2008/08/25 Add ��
          --�ڋq���Ə��}�X�^
          IF (lr_report_rec.hzl_flg = 1) THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_hz_locations_name);
          END IF;
-- 2008/08/25 Add ��
--
        -- ����ȊO
        ELSE
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lr_report_rec.message);
        END IF;
      END IF;
--
    END LOOP disp_c_report_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END disp_c_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂��B
   ***********************************************************************************/
  PROCEDURE disp_report(
    it_party_report_tbl IN            report_tbl,     -- �o�͗p�e�[�u��(���_)
    it_cust_report_tbl  IN            report_tbl,     -- �o�͗p�e�[�u��(�ڋq)
    it_site_report_tbl  IN            report_tbl,     -- �o�͗p�e�[�u��(�z����)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_out_msg       VARCHAR2(2000);
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
    -- ���_
    -- ===============================
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_012);
    IF (lv_out_msg IS NOT NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
    IF (gn_p_normal_cnt > 0) THEN
      -- ���O�o�͏���(����:0)
      disp_p_report(it_party_report_tbl,
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
    IF (gn_p_error_cnt > 0) THEN
      -- ���O�o�͏���(���s:1)
      disp_p_report(it_party_report_tbl,
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
    IF (gn_p_warn_cnt > 0) THEN
      -- ���O�o�͏���(�x��:2)
      disp_p_report(it_party_report_tbl,
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
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_p_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --���������o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_p_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --�G���[�����o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_p_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --�X�L�b�v�����o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_p_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================
    -- �ڋq
    -- ===============================
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_013);
    IF (lv_out_msg IS NOT NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
    IF (gn_c_normal_cnt > 0) THEN
      -- ���O�o�͏���(����:0)
      disp_c_report(it_cust_report_tbl,
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
    IF (gn_c_error_cnt > 0) THEN
      -- ���O�o�͏���(���s:1)
      disp_c_report(it_cust_report_tbl,
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
--    IF (gn_c_warn_cnt > 0) THEN
      -- ���O�o�͏���(�x��:2)
--      disp_c_report(it_cust_report_tbl, gn_data_status_warn,
--                    lv_errbuf,
--                    lv_retcode,
--                    lv_errmsg);
--
--      IF (lv_retcode = gv_status_error) THEN
--        RAISE global_api_expt;
--      END IF;
--    END IF;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_c_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --���������o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_c_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --�G���[�����o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_c_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --�X�L�b�v�����o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_c_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================
    -- �z����
    -- ===============================
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_014);
    IF (lv_out_msg IS NOT NULL) THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
    END IF;
--
    IF (gn_s_normal_cnt > 0) THEN
      -- ���O�o�͏���(����:0)
      disp_s_report(it_site_report_tbl,
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
    IF (gn_s_error_cnt > 0) THEN
      -- ���O�o�͏���(���s:1)
      disp_s_report(it_site_report_tbl,
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
    IF (gn_s_warn_cnt > 0) THEN
      -- ���O�o�͏���(�x��:2)
      disp_s_report(it_site_report_tbl,
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
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_s_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --���������o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_s_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --�G���[�����o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_s_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --�X�L�b�v�����o��
    lv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_s_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_out_msg);
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
   * Procedure Name   : get_class_code
   * Description      : �ڋq�敪�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_class_code(
    in_kbn          IN            NUMBER,      -- �����敪
    ov_class_code      OUT NOCOPY VARCHAR2,    -- �ڋq�敪
    ob_retcd           OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_class_code'; -- �v���O������
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
    ln_cnt        NUMBER;
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
    ob_retcd := TRUE;
--
    BEGIN
      -- ���_
      IF (in_kbn = gn_kbn_party) THEN
--
        SELECT xlvv.lookup_code
        INTO   ov_class_code
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type = gv_lookup_type
        AND    xlvv.meaning     = gv_meaning_party
        AND    ROWNUM           = 1;
--
      -- �ڋq
      ELSE
        SELECT xlvv.lookup_code
        INTO   ov_class_code
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type = gv_lookup_type
        AND    xlvv.meaning     = gv_meaning_cust
        AND    ROWNUM           = 1;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ov_class_code := NULL;
        ob_retcd := FALSE;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_class_code;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_party_if
   * Description      : ���_�C���^�t�F�[�X�̉ߋ��̌����擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_xxcmn_party_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_party_if'; -- �v���O������
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
      ir_masters_rec.row_o_ins_cnt := 0;
      ir_masters_rec.row_o_upd_cnt := 0;
      ir_masters_rec.row_o_del_cnt := 0;
--
      -- ���_�C���^�t�F�[�X
      SELECT SUM(NVL(DECODE(xpi.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_o_ins_cnt,
             ir_masters_rec.row_o_upd_cnt,
             ir_masters_rec.row_o_del_cnt
      FROM   xxcmn_party_if xpi
      WHERE  xpi.base_code = ir_masters_rec.base_code      -- ���_�R�[�h������
      AND    xpi.seq_number < ir_masters_rec.seq_number    -- SEQ�ԍ����ȑO�̃f�[�^
      AND    xpi.ship_mng_code = gv_mode_on                -- �o�ɊǗ����敪='0'
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_o_ins_cnt := 0;
        ir_masters_rec.row_o_upd_cnt := 0;
        ir_masters_rec.row_o_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    BEGIN
--
      ir_masters_rec.row_z_ins_cnt := 0;
      ir_masters_rec.row_z_upd_cnt := 0;
      ir_masters_rec.row_z_del_cnt := 0;
--
      -- ���_�C���^�t�F�[�X
      SELECT SUM(NVL(DECODE(xpi.proc_code,gn_proc_insert,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_update,1),0)),
             SUM(NVL(DECODE(xpi.proc_code,gn_proc_delete,1),0))
      INTO   ir_masters_rec.row_z_ins_cnt,
             ir_masters_rec.row_z_upd_cnt,
             ir_masters_rec.row_z_del_cnt
      FROM   xxcmn_party_if xpi
      WHERE  xpi.base_code = ir_masters_rec.base_code      -- ���_�R�[�h������
      AND    xpi.seq_number < ir_masters_rec.seq_number    -- SEQ�ԍ����ȑO�̃f�[�^
      AND    xpi.ship_mng_code <> gv_mode_on               -- �o�ɊǗ����敪<>'0'
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_z_ins_cnt := 0;
        ir_masters_rec.row_z_upd_cnt := 0;
        ir_masters_rec.row_z_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_xxcmn_party_if;
--
  /***********************************************************************************
   * Procedure Name   : get_xxcmn_site_if
   * Description      : �z����C���^�t�F�[�X�̉ߋ��̌����擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_xxcmn_site_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcmn_site_if'; -- �v���O������
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
    -- �z����R�[�h����������
    BEGIN
--
-- 2008/10/01 v1.10 DELETE START
/*
      ir_masters_rec.row_s_ins_cnt := 0;
      ir_masters_rec.row_s_upd_cnt := 0;
      ir_masters_rec.row_s_del_cnt := 0;
*/
-- 2008/10/01 v1.10 DELETE END
--
      -- �z����C���^�t�F�[�X
-- 2008/10/01 v1.10 UPDATE START
/*
      SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- �o�^
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- �X�V
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- �폜
*/
      SELECT NVL(SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)), 0),  -- �o�^
             NVL(SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)), 0),  -- �X�V
             NVL(SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0)), 0)   -- �폜
-- 2008/10/01 v1.10 UPDATE END
      INTO   ir_masters_rec.row_s_ins_cnt,
             ir_masters_rec.row_s_upd_cnt,
             ir_masters_rec.row_s_del_cnt
      FROM   xxcmn_site_if xsi
      WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- �z����R�[�h������
      AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ�ԍ����ȑO�̃f�[�^
-- 2008/10/01 v1.10 UPDATE START
--      GROUP BY base_code;
      ;
-- 2008/10/01 v1.10 UPDATE END
--
    EXCEPTION
/*
-- 2008/10/01 v1.10 DELETE START
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_s_ins_cnt := 0;
        ir_masters_rec.row_s_upd_cnt := 0;
        ir_masters_rec.row_s_del_cnt := 0;
*/
-- 2008/10/01 v1.10 DELETE END
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �ڋq�R�[�h���͂���
-- 2008/08/25 Mod ��
/*
    IF (ir_masters_rec.party_num IS NOT NULL) THEN
*/
    IF (ir_masters_rec.party_num <> gv_def_party_num) THEN
-- 2008/08/25 Mod ��
      -- �ڋq�R�[�h����������
      BEGIN
--
        ir_masters_rec.row_c_ins_cnt := 0;
        ir_masters_rec.row_c_upd_cnt := 0;
        ir_masters_rec.row_c_del_cnt := 0;
--
        -- �z����C���^�t�F�[�X
        SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- �o�^
               SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- �X�V
               SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- �폜
        INTO   ir_masters_rec.row_c_ins_cnt,
               ir_masters_rec.row_c_upd_cnt,
               ir_masters_rec.row_c_del_cnt
        FROM   xxcmn_site_if xsi
        WHERE  xsi.party_num = ir_masters_rec.party_num        -- �ڋq�R�[�h������
        AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ�ԍ����ȑO�̃f�[�^
        GROUP BY party_num;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ir_masters_rec.row_c_ins_cnt := 0;
          ir_masters_rec.row_c_upd_cnt := 0;
          ir_masters_rec.row_c_del_cnt := 0;
--
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
    -- �ڋq�R�[�h���͂Ȃ�
    ELSE
      ir_masters_rec.row_c_ins_cnt := 0;
      ir_masters_rec.row_c_upd_cnt := 0;
      ir_masters_rec.row_c_del_cnt := 0;
    END IF;
--
    -- �z����R�[�h�������Ōڋq���ݒ肳��Ă��Ȃ�
    BEGIN
--
      ir_masters_rec.row_n_ins_cnt := 0;
      ir_masters_rec.row_n_upd_cnt := 0;
      ir_masters_rec.row_n_del_cnt := 0;
--
      -- �z����C���^�t�F�[�X
      SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- �o�^
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- �X�V
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- �폜
      INTO   ir_masters_rec.row_n_ins_cnt,
             ir_masters_rec.row_n_upd_cnt,
             ir_masters_rec.row_n_del_cnt
      FROM   xxcmn_site_if xsi
      WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- �z����R�[�h������
      AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ�ԍ����ȑO�̃f�[�^
-- 2008/08/25 Mod ��
/*
      AND    xsi.party_num IS NULL                           -- �ڋq�R�[�h���ݒ肳��Ă��Ȃ�
*/
      AND    xsi.party_num    = gv_def_party_num
-- 2008/08/25 Mod ��
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_n_ins_cnt := 0;
        ir_masters_rec.row_n_upd_cnt := 0;
        ir_masters_rec.row_n_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �z����R�[�h�������Ōڋq���ݒ肳��Ă���
    BEGIN
--
      ir_masters_rec.row_m_ins_cnt := 0;
      ir_masters_rec.row_m_upd_cnt := 0;
      ir_masters_rec.row_m_del_cnt := 0;
--
      -- �z����C���^�t�F�[�X
      SELECT SUM(NVL(DECODE(xsi.proc_code,gn_proc_insert,1),0)),  -- �o�^
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_update,1),0)),  -- �X�V
             SUM(NVL(DECODE(xsi.proc_code,gn_proc_delete,1),0))   -- �폜
      INTO   ir_masters_rec.row_m_ins_cnt,
             ir_masters_rec.row_m_upd_cnt,
             ir_masters_rec.row_m_del_cnt
      FROM   xxcmn_site_if xsi
      WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- �z����R�[�h������
      AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ�ԍ����ȑO�̃f�[�^
-- 2008/08/25 Mod ��
/*
      AND    xsi.party_num IS NOT NULL                       -- �ڋq�R�[�h���ݒ肳��Ă���
*/
      AND    xsi.party_num <> gv_def_party_num
-- 2008/08/25 Mod ��
      GROUP BY base_code;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.row_m_ins_cnt := 0;
        ir_masters_rec.row_m_upd_cnt := 0;
        ir_masters_rec.row_m_del_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_xxcmn_site_if;
--
  /***********************************************************************************
   * Procedure Name   : get_hz_parties
   * Description      : �p�[�e�B�[�}�X�^�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_hz_parties(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    in_kbn          IN            NUMBER,      -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_parties'; -- �v���O������
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
    lv_account_number       hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- ���_
    IF (in_kbn = gn_kbn_party) THEN
      lv_account_number := ir_masters_rec.base_code;    -- ���_�R�[�h
    ELSE
      lv_account_number := ir_masters_rec.party_num;    -- �ڋq�R�[�h
    END IF;
--
    BEGIN
--
      SELECT hps.party_id                               -- �p�[�e�BID
            ,hps.validated_flag                         -- �L���t���O
            ,hps.object_version_number                  -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   ir_masters_rec.p_party_id
            ,ir_masters_rec.validated_flag
            ,ir_masters_rec.obj_party_number
      FROM   hz_parties       hps                       -- �p�[�e�B�}�X�^
            ,hz_cust_accounts hca                       -- �ڋq�}�X�^
      WHERE  hps.party_id       = hca.party_id
      AND    hca.account_number = lv_account_number
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id       := NULL;
        ir_masters_rec.validated_flag   := NULL;
        ir_masters_rec.obj_party_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_hz_parties;
--
  /***********************************************************************************
   * Procedure Name   : get_hz_cust_accounts
   * Description      : �ڋq�}�X�^�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_hz_cust_accounts(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    in_kbn          IN            NUMBER,      -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_cust_accounts'; -- �v���O������
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
    lv_account_number      hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- ���_
    IF (in_kbn = gn_kbn_party) THEN
      lv_account_number := ir_masters_rec.base_code;  -- ���_�R�[�h
--
    -- �ڋq
    ELSE
      lv_account_number := ir_masters_rec.party_num;  -- �ڋq�R�[�h
    END IF;
--
    BEGIN
--
      SELECT hca.cust_account_id,                         -- �ڋqID
             hca.party_id,                                -- �p�[�e�BID
             hca.status,                                  -- �L���X�e�C�^�X
             hca.object_version_number                    -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   ir_masters_rec.cust_account_id,
             ir_masters_rec.c_party_id,
             ir_masters_rec.status,
             ir_masters_rec.obj_cust_number
      FROM   hz_cust_accounts hca,                        -- �ڋq�}�X�^
             hz_parties       hps                         -- �p�[�e�B�}�X�^
      WHERE  hca.party_id       = hps.party_id
      AND    hca.account_number = lv_account_number
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.c_party_id      := NULL;
        ir_masters_rec.status          := NULL;
        ir_masters_rec.obj_cust_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_hz_cust_accounts;
--
  /***********************************************************************************
   * Procedure Name   : get_hz_party_sites
   * Description      : �p�[�e�B�[�T�C�g�}�X�^�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_hz_party_sites(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ob_retcd           OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_party_sites'; -- �v���O������
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
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := FALSE;
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- �o�^(���_�R�t��)
-- 2008/08/25 Mod ��
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
      lv_account_number := ir_masters_rec.base_code;      -- ���_�R�[�h
--
    -- �o�^(�ڋq�R�t��)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- �ڋq�R�[�h
    END IF;
--
    BEGIN
--
      -- �p�[�e�B�[�T�C�g�}�X�^
      SELECT hps.party_id,                               -- �p�[�e�BID
             hps.party_site_id,                          -- �p�[�e�B�T�C�gID
             hps.location_id,                            -- ���P�[�V����ID
             hps.status,                                 -- �X�e�[�^�X
             hp.party_number,                            -- �g�D�ԍ�
             hps.object_version_number                   -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number
-- 2008/08/25 Mod ��
/*
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_accounts       hca,                 -- �ڋq�}�X�^
             hz_cust_acct_sites_all hcas                 -- �ڋq���ݒn�}�X�^
      WHERE  hp.party_id        = hps.party_id
      AND    hps.party_id       = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hcas.attribute18   = ir_masters_rec.ship_to_code    -- �z����R�[�h
      AND    hps.status         = gv_status_on;
*/
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_accounts       hca,                 -- �ڋq�}�X�^
             hz_locations           hcas                 -- �ڋq���Ə��}�X�^
      WHERE  hp.party_id        = hps.party_id
      AND    hps.party_id       = hca.party_id
      AND    hps.location_id    = hcas.location_id
      AND    hca.account_number = lv_account_number
      AND    hcas.province      = ir_masters_rec.ship_to_code    -- �z����R�[�h
      AND    hps.status         = gv_status_on;
-- 2008/08/25 Mod ��
--      AND    ROWNUM             = 1;
--
      ob_retcd := TRUE;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_hz_party_sites;
--
  /***********************************************************************************
   * Procedure Name   : get_party_num
   * Description      : �ڋq�R�[�h�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_party_num(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    in_proc_code    IN            NUMBER,       -- �X�V�敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_num'; -- �v���O������
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
    lv_party_num    xxcmn_site_if.party_num%TYPE;     -- �ڋq�R�[�h
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
      ir_masters_rec.party_num := NULL;
--
      -- �z����C���^�t�F�[�X
      SELECT xsi.party_num
      INTO   lv_party_num
      FROM   xxcmn_site_if xsi
      WHERE  xsi.seq_number < ir_masters_rec.seq_number          -- SEQ�ԍ����ȑO
      AND    xsi.ship_to_code = ir_masters_rec.ship_to_code      -- �z����R�[�h
-- 2008/08/25 Mod ��
/*
      AND    xsi.party_num IS NOT NULL                           -- �ڋq�R�[�h�����݂���
*/
      AND    xsi.party_num <> gv_def_party_num
-- 2008/08/25 Mod ��
      AND    xsi.proc_code = in_proc_code
      AND    xsi.seq_number IN (
        SELECT MAX(xxsi.seq_number)
        FROM   xxcmn_site_if xxsi
        WHERE  xxsi.seq_number < ir_masters_rec.seq_number
        AND    xxsi.ship_to_code = ir_masters_rec.ship_to_code
        AND    xxsi.proc_code = in_proc_code
/*
        AND    xxsi.party_num IS NOT NULL)
*/
        AND    xxsi.party_num <> gv_def_party_num)
      AND    ROWNUM = 1;
--
      ir_masters_rec.party_num := lv_party_num;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_party_num;
--
  /***********************************************************************************
   * Procedure Name   : get_party_id
   * Description      : �p�[�e�BID�̎擾�������s���܂��B
   ***********************************************************************************/
  PROCEDURE get_party_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_id'; -- �v���O������
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
    lv_account_number     hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- �o�^(���_�R�t��)
-- 2008/08/25 Mod ��
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
      lv_account_number := ir_masters_rec.base_code;      -- ���_�R�[�h
--
    -- �o�^(�ڋq�R�t��)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- �ڋq�R�[�h
    END IF;
--
    BEGIN
--
      SELECT hp.party_id,                                    -- �p�[�e�BID
             hca.cust_account_id                             -- �ڋqID
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.cust_account_id
      FROM   hz_parties       hp,                            -- �p�[�e�B�}�X�^
             hz_cust_accounts hca                            -- �ڋq�}�X�^
      WHERE  hca.party_id       = hp.party_id
      AND    hca.account_number = lv_account_number
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.cust_account_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_party_id;
--
  /***********************************************************************************
   * Procedure Name   : get_party_site_id
   * Description      : �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_party_site_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_site_id'; -- �v���O������
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := TRUE;
--
/* 2008/08/18 Del ��
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- ���_�R�t��
    IF ((ir_masters_rec.proc_code = gn_proc_s_upd)
     OR (ir_masters_rec.proc_code = gn_proc_s_del)
     OR (ir_masters_rec.proc_code = gn_proc_ds_del)) THEN
      lv_account_number := ir_masters_rec.base_code;       -- ���_�R�[�h
--
    -- �ڋq�R�t��
    ELSIF ((ir_masters_rec.proc_code = gn_proc_c_upd)
     OR (ir_masters_rec.proc_code = gn_proc_c_del)
     OR (ir_masters_rec.proc_code = gn_proc_dc_del)) THEN
      lv_account_number := ir_masters_rec.party_num;       -- �ڋq�R�[�h
    END IF;
2008/08/18 Del �� */
--
    BEGIN
--
      SELECT hps.party_id,                               -- �p�[�e�BID
             hps.party_site_id,                          -- �p�[�e�B�T�C�gID
             hps.location_id,                            -- ���P�[�V����ID
             hps.status,                                 -- �X�e�[�^�X
             hp.party_number,                            -- �g�D�ԍ�
             hps.object_version_number,                  -- �I�u�W�F�N�g�o�[�W�����ԍ�
             hcas.cust_acct_site_id,                     -- �ڋq�T�C�gID
             hcas.object_version_number,                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
             hzl.location_id,                            -- ���P�[�V����ID             2008/08/25 Add
             hzl.object_version_number                   -- �I�u�W�F�N�g�o�[�W�����ԍ� 2008/08/25 Add
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number,
             ir_masters_rec.hzl_location_id,             -- 2008/08/25 Add
             ir_masters_rec.hzl_obj_number               -- 2008/08/25 Add
-- 2008/08/25 Mod ��
/*
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_cust_accounts       hca                  -- �ڋq�}�X�^
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
--      AND    hca.account_number = lv_account_number            -- 2008/08/18 Del
      AND    hps.status         = gv_status_on                   -- �L�� 2008/08/18 Add
      AND    hcas.attribute18   = ir_masters_rec.ship_to_code;   -- �z����R�[�h
--      AND    ROWNUM = 1;                                       -- 2008/08/18 Del
*/
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_cust_accounts       hca,                 -- �ڋq�}�X�^
             hz_locations           hzl                  -- �ڋq���Ə��}�X�^
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hps.location_id    = hzl.location_id
      AND    hps.status         = gv_status_on                   -- �L�� 2008/08/18 Add
      AND    hzl.province       = ir_masters_rec.ship_to_code;   -- �z����R�[�h
-- 2008/08/25 Mod ��
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
        ir_masters_rec.hzl_location_id := NULL;             -- 2008/08/25 Add
        ir_masters_rec.hzl_obj_number  := NULL;             -- 2008/08/25 Add
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_party_site_id;
--
  /***********************************************************************************
   * Procedure Name   : get_party_site_id_2
   * Description      : �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_party_site_id_2(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_party_site_id_2'; -- �v���O������
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := TRUE;
--
    -- �o�^(���_�R�t��)
-- 2008/08/25 Mod ��
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
      lv_account_number := ir_masters_rec.base_code;      -- ���_�R�[�h
--
    -- �o�^(�ڋq�R�t��)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- �ڋq�R�[�h
    END IF;
--
    BEGIN
--
      SELECT hps.party_id,                               -- �p�[�e�BID
             hps.party_site_id,                          -- �p�[�e�B�T�C�gID
             hps.location_id,                            -- ���P�[�V����ID
             hps.status,                                 -- �X�e�[�^�X
             hp.party_number,                            -- �g�D�ԍ�
             hps.object_version_number,                  -- �I�u�W�F�N�g�o�[�W�����ԍ�
             hcas.cust_acct_site_id,                     -- �ڋq�T�C�gID
             hcas.object_version_number,                 -- �I�u�W�F�N�g�o�[�W�����ԍ�
             hzl.location_id,                            -- ���P�[�V����ID             2008/08/25 Add
             hzl.object_version_number                   -- �I�u�W�F�N�g�o�[�W�����ԍ� 2008/08/25 Add
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number,
             ir_masters_rec.hzl_location_id,             -- 2008/08/25 Add
             ir_masters_rec.hzl_obj_number               -- 2008/08/25 Add
-- 2008/08/25 Mod ��
/*
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_cust_accounts       hca                  -- �ڋq�}�X�^
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hps.status         = gv_status_off                  -- ����
      AND    hcas.attribute18   = ir_masters_rec.ship_to_code;   -- �z����R�[�h
*/
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_cust_accounts       hca,                 -- �ڋq�}�X�^
             hz_locations           hzl                  -- �ڋq���Ə��}�X�^
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hps.location_id    = hzl.location_id
      AND    hca.account_number = lv_account_number
      AND    hps.status         = gv_status_off                  -- ����
      AND    hzl.province       = ir_masters_rec.ship_to_code;   -- �z����R�[�h
-- 2008/08/25 Mod ��
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
        ir_masters_rec.hzl_location_id := NULL;             -- 2008/08/25 Add
        ir_masters_rec.hzl_obj_number  := NULL;             -- 2008/08/25 Add
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_party_site_id_2;
--
  /***********************************************************************************
   * Procedure Name   : get_site_to_if
   * Description      : �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_site_to_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_site_to_if'; -- �v���O������
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := TRUE;
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- ���_�R�t��
    IF ((ir_masters_rec.proc_code = gn_proc_s_upd)
     OR (ir_masters_rec.proc_code = gn_proc_s_del)
     OR (ir_masters_rec.proc_code = gn_proc_ds_del)) THEN
      lv_account_number := ir_masters_rec.base_code;      -- ���_�R�[�h
--
    -- �ڋq�R�t��
    ELSIF ((ir_masters_rec.proc_code = gn_proc_c_upd)
     OR (ir_masters_rec.proc_code = gn_proc_c_del)
     OR (ir_masters_rec.proc_code = gn_proc_dc_del)) THEN
      lv_account_number := ir_masters_rec.party_num;      -- �ڋq�R�[�h
    END IF;
--
    BEGIN
      SELECT hps.party_id,                               -- �p�[�e�BID
             hps.party_site_id,                          -- �p�[�e�B�T�C�gID
             hps.location_id,                            -- ���P�[�V����ID
             hps.status,                                 -- �X�e�[�^�X
             hp.party_number,                            -- �g�D�ԍ�
             hps.object_version_number,                  -- �I�u�W�F�N�g�o�[�W�����ԍ�
             hcas.cust_acct_site_id,                     -- �ڋq�T�C�gID
             hcas.object_version_number                  -- �I�u�W�F�N�g�o�[�W�����ԍ�
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_cust_accounts       hca                  -- �ڋq�}�X�^
      WHERE  hp.party_id       = hps.party_id
      AND    hp.party_id       = hca.party_id
      AND    hps.party_site_id = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hp.party_number IN (
        SELECT xsi.base_code
        FROM   xxcmn_site_if xsi
        WHERE  xsi.seq_number < ir_masters_rec.seq_number
        AND    xsi.ship_to_code = ir_masters_rec.ship_to_code
        AND    xsi.seq_number IN (
          SELECT MAX(xsi.seq_number)
          FROM   xxcmn_site_if xsi
          WHERE  xsi.seq_number < ir_masters_rec.seq_number
          AND    xsi.ship_to_code = ir_masters_rec.ship_to_code))
      AND    ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_site_to_if;
--
  /***********************************************************************************
   * Procedure Name   : get_site_number
   * Description      : �p�[�e�B�T�C�g�}�X�^�̃T�C�gID�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_site_number(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ob_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_site_number'; -- �v���O������
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
    ln_cnt               NUMBER;
    lv_status            hz_party_sites.status%TYPE;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := TRUE;
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- �o�^(���_�R�t��)
-- 2008/08/25 Mod ��
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
      lv_account_number := ir_masters_rec.base_code;      -- ���_�R�[�h
--
    -- �o�^(�ڋq�R�t��)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- �ڋq�R�[�h
    END IF;
--
    BEGIN
--
      SELECT hps.party_id,
             hps.party_site_id,
             hps.location_id,
             hps.status,
             hp.party_number,
             hps.object_version_number,
             hcas.cust_acct_site_id,
             hcas.object_version_number
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.party_site_id,
             ir_masters_rec.location_id,
             ir_masters_rec.site_status,
             ir_masters_rec.party_number,
             ir_masters_rec.obj_site_number,
             ir_masters_rec.cust_acct_site_id,
             ir_masters_rec.obj_acct_number
      FROM   hz_parties             hp,                  -- �p�[�e�B�}�X�^
             hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_cust_accounts       hca                  -- �ڋq�}�X�^
      WHERE  hp.party_id        = hps.party_id
      AND    hp.party_id        = hca.party_id
      AND    hps.party_site_id  = hcas.party_site_id
      AND    hca.account_number = lv_account_number
      AND    hps.status         = gv_status_on
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ob_retcd := FALSE;
        ir_masters_rec.p_party_id      := NULL;
        ir_masters_rec.party_site_id   := NULL;
        ir_masters_rec.location_id     := NULL;
        ir_masters_rec.site_status     := NULL;
        ir_masters_rec.party_number    := NULL;
        ir_masters_rec.obj_site_number := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END get_site_number;
--
  /***********************************************************************************
   * Procedure Name   : exists_party_id
   * Description      : �p�[�e�BID�̎擾�������s���܂��B
   ***********************************************************************************/
  PROCEDURE exists_party_id(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    in_kbn          IN            NUMBER,       -- �����敪
    iv_status       IN            VARCHAR2,     -- �X�e�[�^�X
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_party_id'; -- �v���O������
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
    lb_retcd                        BOOLEAN;
    lv_account_number               hz_cust_accounts.account_number%TYPE;
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
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- ���_�P��
    IF (in_kbn = gn_kbn_party) THEN
      lv_account_number := ir_masters_rec.base_code;         -- ���_�R�[�h
--
    -- �ڋq�P��
    ELSE
      lv_account_number := ir_masters_rec.party_num;         -- �ڋq�R�[�h
    END IF;
--
    BEGIN
--
      SELECT hp.party_id,                               -- �p�[�e�BID
             hp.validated_flag,                         -- �L���t���O
             hp.object_version_number,                  -- �I�u�W�F�N�g�o�[�W�����ԍ�(�p�[�e�B)
             hp.party_number,                           -- �g�D�ԍ�
             hca.party_id,                              -- �p�[�e�BID
             hca.status,                                -- �L���X�e�C�^�X
             hca.cust_account_id,                       -- �ڋqID
             hca.object_version_number                  -- �I�u�W�F�N�g�o�[�W�����ԍ�(�ڋq)
      INTO   ir_masters_rec.p_party_id,
             ir_masters_rec.validated_flag,
             ir_masters_rec.obj_party_number,
             ir_masters_rec.party_number,
             ir_masters_rec.c_party_id,
             ir_masters_rec.status,
             ir_masters_rec.cust_account_id,
             ir_masters_rec.obj_cust_number
      FROM   hz_parties       hp,                       -- �p�[�e�B�}�X�^
             hz_cust_accounts hca                       -- �ڋq�}�X�^
      WHERE  hca.party_id       = hp.party_id
      AND    hca.account_number = lv_account_number
      AND    hca.status         = iv_status
      AND    ROWNUM             = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.p_party_id       := NULL;
        ir_masters_rec.c_party_id       := NULL;
        ir_masters_rec.validated_flag   := NULL;
        ir_masters_rec.status           := NULL;
        ir_masters_rec.obj_party_number := NULL;
        ir_masters_rec.cust_account_id  := NULL;
        ir_masters_rec.obj_cust_number  := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END exists_party_id;
--
  /***********************************************************************************
   * Procedure Name   : exists_xxcmn_site_if
   * Description      : �ڋq�R�[�h�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE exists_xxcmn_site_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    in_kbn          IN            NUMBER,      -- �����敪
    ob_retcd           OUT NOCOPY BOOLEAN,     -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_xxcmn_site_if'; -- �v���O������
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
    ln_cnt    NUMBER;
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
    ob_retcd := TRUE;
--
      -- ���_
      IF (in_kbn = gn_kbn_party) THEN
        SELECT COUNT(xsi.seq_number)
        INTO   ln_cnt
        FROM   xxcmn_site_if xsi
        WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- �z����R�[�h������
        AND    xsi.base_code    = ir_masters_rec.base_code     -- ���_�R�[�h������
        AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ�ԍ����ȑO�̃f�[�^
        AND    (xsi.proc_code = gn_proc_insert                 -- �o�^
        OR      xsi.proc_code = gn_proc_update)                -- �X�V
        AND    ROWNUM = 1;
--
      -- �ڋq
      ELSE
        SELECT COUNT(xsi.seq_number)
        INTO   ln_cnt
        FROM   xxcmn_site_if xsi
        WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- �z����R�[�h������
        AND    xsi.party_num    = ir_masters_rec.party_num     -- �ڋq�R�[�h������
        AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ�ԍ����ȑO�̃f�[�^
        AND    (xsi.proc_code = gn_proc_insert                 -- �o�^
        OR      xsi.proc_code = gn_proc_update)                -- �X�V
        AND    ROWNUM = 1;
      END IF;
--
    IF (ln_cnt < 1) THEN
      ob_retcd := FALSE;
    END IF;
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END exists_xxcmn_site_if;
--
  /***********************************************************************************
   * Procedure Name   : chk_party_status
   * Description      : �p�[�e�B�}�X�^�E�ڋq�}�X�^�̃X�e�[�^�X�̃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_party_status(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    on_kbn             OUT NOCOPY NUMBER,       -- �`�F�b�N����
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_status'; -- �v���O������
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
    ln_hca_on   NUMBER;
    ln_hca_off  NUMBER;
    ln_hp_on    NUMBER;
    ln_hp_off   NUMBER;
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
    on_kbn := gn_data_nothing;
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- �ڋq�}�X�^�E�X�e�[�^�X
    -- �p�[�e�B�}�X�^�E�L���t���O
    SELECT SUM(NVL(DECODE(hca.status,gv_status_on,1),0)),
           SUM(NVL(DECODE(hca.status,gv_status_off,1),0)),
           SUM(NVL(DECODE(hp.validated_flag,gv_validated_flag_on,1),0)),
           SUM(NVL(DECODE(hp.validated_flag,gv_validated_flag_off,1),0))
    INTO   ln_hca_on,
           ln_hca_off,
           ln_hp_on,
           ln_hp_off
    FROM   hz_parties       hp,                          -- �p�[�e�B�}�X�^
           hz_cust_accounts hca                          -- �ڋq�}�X�^
    WHERE  hca.party_id       = hp.party_id
    AND    hca.account_number = ir_masters_rec.party_num;                    -- �ڋq�R�[�h
--
    -- �L��
    IF ((ln_hca_on > 0) AND (ln_hp_on > 0)) THEN
      on_kbn := gn_data_on;
    ELSE
      -- ����
      IF((ln_hca_off > 0) AND (ln_hp_off > 0)) THEN
        on_kbn := gn_data_off;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END chk_party_status;
--
  /***********************************************************************************
   * Procedure Name   : chk_site_status
   * Description      : �p�[�e�B�T�C�g�}�X�^�̃X�e�[�^�X�̃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_site_status(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    on_kbn             OUT NOCOPY NUMBER,       -- �`�F�b�N����
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_site_status'; -- �v���O������
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
    ln_on_cnt            NUMBER;
    ln_off_cnt           NUMBER;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    on_kbn := gn_data_nothing;
-- 2008/08/18 Mod ��
/*
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- �o�^(���_�R�t��)
    IF (ir_masters_rec.party_num IS NULL) THEN
      lv_account_number := ir_masters_rec.base_code;      -- ���_�R�[�h
--
    -- �o�^(�ڋq�R�t��)
    ELSE
      lv_account_number := ir_masters_rec.party_num;      -- �ڋq�R�[�h
    END IF;

--
    SELECT SUM(NVL(DECODE(hps.status,gv_status_on,1),0)),          --�X�e�[�^�X�L��
           SUM(NVL(DECODE(hps.status,gv_status_off,1),0))          --�X�e�[�^�X����
    INTO   ln_on_cnt,
           ln_off_cnt
    FROM   hz_party_sites   hps,                         -- �p�[�e�B�T�C�g�}�X�^
           hz_cust_accounts hca                          -- �ڋq�}�X�^
    WHERE  hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number;
*/
    SELECT SUM(NVL(DECODE(hps.status,gv_status_on,1),0)),          --�X�e�[�^�X�L��
           SUM(NVL(DECODE(hps.status,gv_status_off,1),0))          --�X�e�[�^�X����
    INTO   ln_on_cnt,
           ln_off_cnt
-- 2008/08/25 Mod ��
/*
    FROM   hz_party_sites         hps,                   -- �p�[�e�B�T�C�g�}�X�^
           hz_cust_acct_sites_all hcas                   -- �ڋq���ݒn�}�X�^
    WHERE  hps.party_site_id  = hcas.party_site_id
    AND    hcas.attribute18   = ir_masters_rec.ship_to_code;   -- �z����R�[�h
*/
    FROM   hz_party_sites         hps,                   -- �p�[�e�B�T�C�g�}�X�^
           hz_locations           hzl                   -- �ڋq���Ə��}�X�^
    WHERE  hps.location_id  = hzl.location_id
    AND    hzl.province     = ir_masters_rec.ship_to_code;   -- �z����R�[�h
-- 2008/08/25 Mod ��
-- 2008/08/18 Mod ��
--
    -- �L������
    IF (ln_on_cnt > 0) THEN
      on_kbn := gn_data_on;
    ELSE
      -- ��������
      IF (ln_off_cnt > 0) THEN
        on_kbn := gn_data_off;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END chk_site_status;
--
  /***********************************************************************************
   * Procedure Name   : chk_party_num
   * Description      : �ڋq�R�[�h�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_party_num(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    iv_status       IN            VARCHAR2,     -- �X�e�[�^�X
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_num'; -- �v���O������
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
    -- 2008/04/17 �ύX�v��No61 �Ή�
    SELECT COUNT(hca.status)
    INTO   ln_cnt
    FROM   hz_cust_accounts hca
    WHERE  hca.account_number = ir_masters_rec.party_num       -- �ڋq�R�[�h
    AND    hca.status         = iv_status
    AND    ROWNUM             = 1;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END chk_party_num;
--
  /***********************************************************************************
   * Procedure Name   : chk_party_num_if
   * Description      : �ڋq�R�[�h�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE chk_party_num_if(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_party_num_if'; -- �v���O������
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
    SELECT COUNT(xsi.proc_code)
    INTO   ln_cnt
    FROM   xxcmn_site_if xsi
-- 2008/10/01 v1.10 UPDATE START
--    WHERE  xsi.ship_to_code = ir_masters_rec.ship_to_code  -- �z����R�[�h������
--    AND    xsi.party_num = ir_masters_rec.party_num        -- �ڋq�R�[�h������
    WHERE  xsi.party_num = ir_masters_rec.party_num        -- �ڋq�R�[�h������
-- 2008/10/01 v1.10 UPDATE END
    AND    (xsi.proc_code = gn_proc_insert                 -- �o�^
    OR      xsi.proc_code = gn_proc_update)                -- �X�V
    AND    xsi.seq_number < ir_masters_rec.seq_number      -- SEQ�ԍ����ȑO�̃f�[�^
    AND    ROWNUM = 1;
--
    IF (ln_cnt > 0) THEN
      ov_retcd := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END chk_party_num_if;
--
  /***********************************************************************************
   * Procedure Name   : exists_party_number
   * Description      : �p�[�e�B�T�C�g�}�X�^�̑��݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE exists_party_number(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    iv_status       IN            VARCHAR2,     -- �`�F�b�N�X�e�[�^�X
    ob_retcd           OUT NOCOPY BOOLEAN,      -- ��������
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exists_party_number'; -- �v���O������
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
    ln_cnt               NUMBER;
    lv_account_number    hz_cust_accounts.account_number%TYPE;
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
    ob_retcd := FALSE;
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
      lv_account_number := ir_masters_rec.base_code;       -- ���_�R�[�h
--
    -- �ڋq�R�[�h<>NULL
    ELSE
      lv_account_number := ir_masters_rec.party_num;       -- �ڋq�R�[�h
    END IF;
-- 2008/08/18 Mod ��
/*
    SELECT COUNT(hps.party_site_id)
    INTO   ln_cnt
    FROM   hz_party_sites   hps,                         -- �p�[�e�B�T�C�g�}�X�^
           hz_cust_accounts hca                          -- �ڋq�}�X�^
    WHERE  hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number
    AND    hps.status         = iv_status
    AND    ROWNUM             = 1;
*/
-- 2008/08/18 Mod ��
    SELECT COUNT(hps.party_site_id)
    INTO   ln_cnt
-- 2008/08/25 Mod ��
/*
    FROM   hz_party_sites         hps,                   -- �p�[�e�B�T�C�g�}�X�^
           hz_cust_accounts       hca,                   -- �ڋq�}�X�^
           hz_cust_acct_sites_all hcas                   -- �ڋq���ݒn�}�X�^
    WHERE  hps.party_site_id  = hcas.party_site_id
    AND    hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number
    AND    hcas.attribute18   = ir_masters_rec.ship_to_code    -- �z����R�[�h
    AND    hps.status         = iv_status;
*/
    FROM   hz_party_sites         hps,                   -- �p�[�e�B�T�C�g�}�X�^
           hz_cust_accounts       hca,                   -- �ڋq�}�X�^
           hz_locations           hzl                    -- �ڋq���Ə��}�X�^
    WHERE  hps.location_id    = hzl.location_id
    AND    hps.party_id       = hca.party_id
    AND    hca.account_number = lv_account_number
    AND    hzl.province       = ir_masters_rec.ship_to_code    -- �z����R�[�h
    AND    hps.status         = iv_status;
-- 2008/08/25 Mod ��
--
    IF (ln_cnt > 0) THEN
      ob_retcd := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END exists_party_number;
--
  /***********************************************************************************
   * Procedure Name   : check_proc_code
   * Description      : ����Ώۂ̃f�[�^�ł��邱�Ƃ��m�F���܂��B
   ***********************************************************************************/
  PROCEDURE check_proc_code(
    in_proc_code   IN            NUMBER,      -- �`�F�b�N�Ώۋ敪
    ir_status_rec  IN OUT NOCOPY status_rec,  -- ������
    ov_errbuf         OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --�����敪���i�o�^�E�X�V�E�폜�j�ȊO
    IF ((in_proc_code <> gn_proc_insert)
    AND (in_proc_code <> gn_proc_update)
    AND (in_proc_code <> gn_proc_delete)) THEN
--
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_019,
                                                'VALUE',    TO_CHAR(in_proc_code)),
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
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
   * Procedure Name   : check_base_code
   * Description      : ���_�R�[�h�`�F�b�N���s���܂��B(A-2)
   ***********************************************************************************/
  PROCEDURE check_base_code(
    ir_status_rec   IN OUT NOCOPY status_rec,   -- ������
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_base_code'; -- �v���O������
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
    ln_kbn     NUMBER;
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
    -- �p�[�e�B�}�X�^���݃`�F�b�N
    get_hz_parties(ir_masters_rec,
                   gn_kbn_party,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �ڋq�}�X�^���݃`�F�b�N
    get_hz_cust_accounts(ir_masters_rec,
                         gn_kbn_party,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    ln_kbn := gn_data_init;
--
    -- �ڋq�E�p�[�e�B�}�X�^�̃`�F�b�N
    ln_kbn := chk_party_id(ir_masters_rec);
--
    IF (ln_kbn = gn_data_init) THEN
--
        -- ���_�ΏۊO���R�[�h
      set_error_status(ir_status_rec,
                       xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                gv_msg_80a_033,
                                                gv_tkn_ng_kyoten,
                                                ir_masters_rec.base_code),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    -- ===============================
    -- �o�^
    -- ===============================
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
--
      -- �o�ɊǗ����敪 = '0'
      IF (ir_masters_rec.ship_mng_code = gv_mode_on) THEN
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^�Ȃ�
        IF (ln_kbn = gn_data_nothing) THEN
--
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- �o�^����
            ir_masters_rec.proc_code := gn_proc_insert;
--
          -- �ȑO�ɓ����f�[�^�����݂���
          ELSE
--
            -- �o�^���̏d���`�F�b�N�G���[
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80a_032,
                                                      gv_tkn_ng_kyoten,
                                                      ir_masters_rec.base_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(����)
        IF (ln_kbn = gn_data_off) THEN
--
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- �X�V�����ɕϊ�
            ir_masters_rec.proc_code := gn_proc_update;
            ir_masters_rec.validated_flag := gv_validated_flag_on;
            ir_masters_rec.status := gv_status_on;
--
          -- �ȑO�ɓ����f�[�^�����݂���
          ELSE
--
            -- �o�^���̏d���`�F�b�N�G���[
            set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80a_032,
                                                      gv_tkn_ng_kyoten,
                                                      ir_masters_rec.base_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(�L��)
        IF (ln_kbn = gn_data_on) THEN
--
            -- �o�^���̏d���`�F�b�N�G���[
          set_error_status(ir_status_rec,
                             xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                      gv_msg_80a_032,
                                                      gv_tkn_ng_kyoten,
                                                      ir_masters_rec.base_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
          RAISE check_base_code_expt;
        END IF;
      END IF;
--
      -- �o�ɊǗ����敪 <> '0'
      IF (ir_masters_rec.ship_mng_code <> gv_mode_on) THEN
--
        -- ���_�ΏۊO���R�[�h(���[�j���O)
        set_warn_status(ir_status_rec,
                        xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                 gv_msg_80a_033,
                                                 gv_tkn_ng_kyoten,
                                                 ir_masters_rec.base_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        RAISE check_base_code_expt;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    -- ===============================
    -- �X�V
    -- ===============================
    IF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
      -- �o�ɊǗ����敪 = '0'
      IF (ir_masters_rec.ship_mng_code = gv_mode_on) THEN
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^�Ȃ�
        IF (ln_kbn = 1) THEN
--
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- �o�^�����ɕϊ�
            ir_masters_rec.proc_code := gn_proc_insert;
--
          -- �ȑO�ɏo�ɊǗ����敪='0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
              -- �X�V����
              ir_masters_rec.proc_code := gn_proc_update;
--
          -- �ȑO�ɏo�ɊǗ����敪<>'0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
              -- �o�^����
              ir_masters_rec.proc_code := gn_proc_insert;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���
          ELSE
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(����)
        IF (ln_kbn = 2) THEN
          ir_masters_rec.validated_flag := gv_validated_flag_on;
          ir_masters_rec.status := gv_status_on;
        END IF;
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(�L��)
        IF (ln_kbn = gn_data_on) THEN
          -- �X�V����
          ir_masters_rec.proc_code := gn_proc_update;
        END IF;
      END IF;
--
      -- �o�ɊǗ����敪 <> '0'
      IF (ir_masters_rec.ship_mng_code <> gv_mode_on) THEN
        -- �ڋq���p�[�e�B�}�X�^�f�[�^�Ȃ�
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(����)
        IF ((ln_kbn = gn_data_nothing) OR (ln_kbn = gn_data_off)) THEN
--
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɏo�ɊǗ����敪='0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- �폜�����ɕϊ�
            ir_masters_rec.proc_code := gn_proc_delete;
--
            -- �ȑO�ɏo�ɊǗ����敪<>'0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���
          ELSE
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_033,
                                                    gv_tkn_ng_kyoten,
                                                    ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(�L��)
        IF (ln_kbn = gn_data_on) THEN
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- �폜�����ɕϊ�
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪='0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- �폜�����ɕϊ�
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪<>'0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���
          ELSE
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    -- ===============================
    -- �폜
    -- ===============================
    IF (ir_masters_rec.proc_code = gn_proc_delete) THEN
--
      -- �o�ɊǗ����敪 = '0'
      IF (ir_masters_rec.ship_mng_code = gv_mode_on) THEN
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^�Ȃ�
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(����)
        IF ((ln_kbn = gn_data_nothing) OR (ln_kbn = gn_data_off))THEN
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- �폜���̑��݃`�F�b�N���[�j���O
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_031,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɏo�ɊǗ����敪='0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- �폜����
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪<>'0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- �폜���̑��݃`�F�b�N���[�j���O
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_031,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���
          ELSE
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(�L��)
        IF (ln_kbn = gn_data_on) THEN
--
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- �폜����
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪='0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- �폜����
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪<>'0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- �폜���̑��݃`�F�b�N���[�j���O
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_031,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���
          ELSE
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
      END IF;
--
      -- �o�ɊǗ����敪 <> '0'
      IF (ir_masters_rec.ship_mng_code <> gv_mode_on) THEN
        -- �ڋq���p�[�e�B�}�X�^�f�[�^�Ȃ�
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(����)
        IF ((ln_kbn = gn_data_nothing) OR (ln_kbn = gn_data_off)) THEN
--
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɏo�ɊǗ����敪='0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- �폜����
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪<>'0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���
          ELSE
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
--
        -- �ڋq���p�[�e�B�}�X�^�f�[�^����(�L��)
        IF (ln_kbn = gn_data_on) THEN
--
          -- �ȑO�ɓ����f�[�^�����݂��Ȃ�
          IF (((ir_masters_rec.row_o_ins_cnt = 0)
           AND (ir_masters_rec.row_o_upd_cnt = 0) AND (ir_masters_rec.row_o_del_cnt = 0))
          AND ((ir_masters_rec.row_z_ins_cnt = 0)
           AND (ir_masters_rec.row_z_upd_cnt = 0) AND (ir_masters_rec.row_z_del_cnt = 0))) THEN
            -- �폜����
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪='0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_o_ins_cnt <> 0) OR (ir_masters_rec.row_o_upd_cnt <> 0)) THEN
            -- �폜����
            ir_masters_rec.proc_code := gn_proc_delete;
--
          -- �ȑO�ɏo�ɊǗ����敪<>'0'�̓o�^�E�X�V�f�[�^�����݂���
          ELSIF ((ir_masters_rec.row_z_ins_cnt <> 0) OR (ir_masters_rec.row_z_upd_cnt <> 0)) THEN
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
--
          -- �ȑO�ɍ폜�f�[�^�����݂���
          ELSE
--
            -- ���_�ΏۊO���R�[�h
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_033,
                                                     gv_tkn_ng_kyoten,
                                                     ir_masters_rec.base_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
            RAISE check_base_code_expt;
          END IF;
        END IF;
      END IF;
      RAISE check_base_code_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_base_code_expt THEN
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
  END check_base_code;
--
  /***********************************************************************************
   * Procedure Name   : check_party_num
   * Description      : �ڋq�R�[�h�̃`�F�b�N���s���܂��B(A-7)
   ***********************************************************************************/
  PROCEDURE check_party_num(
    ir_status_rec   IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_party_num'; -- �v���O������
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
    ln_kbn     NUMBER;
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
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
    IF (ir_masters_rec.party_num IS NULL) THEN
*/
    IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
      -- �����X�L�b�v
      set_warn_status(ir_status_rec,
                      NULL,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
--
    -- �X�e�[�^�X�`�F�b�N
    chk_party_status(ir_masters_rec,
                     ln_kbn,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
-- 2008/10/01 v1.10 UPDATE START
/*
    -- ===============================
    -- �o�^
    -- ===============================
    IF (ir_masters_rec.k_proc_code = gn_proc_insert) THEN
--
      -- �ڋq�E�p�[�e�B�}�X�^�f�[�^�Ȃ�
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- �ȑO�ɔz����R�[�h������̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0) AND (ir_masters_rec.row_s_upd_cnt = 0)) THEN
          ir_masters_rec.proc_code := gn_proc_insert;
--
        -- �ȑO�ɔz����R�[�h������̃f�[�^����
        ELSE
--
          -- �o�^���̏d���`�F�b�N�G���[
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_036,
                                                    gv_tkn_ng_kokyaku,
                                                    ir_masters_rec.party_num),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- �ڋq�E�p�[�e�B�}�X�^�f�[�^����(����)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- �ȑO�ɔz����R�[�h������̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0) AND (ir_masters_rec.row_s_upd_cnt = 0)) THEN
          ir_masters_rec.proc_code := gn_proc_update;
--
        -- �ȑO�ɔz����R�[�h������̃f�[�^����
        ELSE
--
          -- �o�^���̏d���`�F�b�N�G���[
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_036,
                                                    gv_tkn_ng_kokyaku,
                                                    ir_masters_rec.party_num),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- �ڋq�E�p�[�e�B�}�X�^�f�[�^����(�L��)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- �����X�L�b�v
        set_warn_status(ir_status_rec,
                        NULL,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
--
/* 2008.08.23 Mod ��
        -- �o�^���̏d���`�F�b�N�G���[
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80a_036,
                                                  gv_tkn_ng_kokyaku,
                                                  ir_masters_rec.party_num),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
2008.08.23 Mod ��*//*
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
--
    -- ===============================
    -- �X�V
    -- ===============================
    IF (ir_masters_rec.k_proc_code = gn_proc_update) THEN
--
      -- �z����IF�̑��݃`�F�b�N
      chk_party_num_if(ir_masters_rec,
                       lb_retcd,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �ڋq�E�p�[�e�B�}�X�^�f�[�^�Ȃ�
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- �ڋq�R�[�h�Ȃ�(�o�^�E�X�V)���L
        IF ((ir_masters_rec.row_n_ins_cnt > 0) OR (ir_masters_rec.row_n_upd_cnt > 0)) THEN
          ir_masters_rec.proc_code := gn_proc_insert;
--
        -- �ڋq�R�[�h����(�o�^�E�X�V)���L
        ELSIF ((ir_masters_rec.row_m_ins_cnt > 0) OR (ir_masters_rec.row_m_upd_cnt > 0)) THEN
--
          -- ���g����
          IF (lb_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_update;
--
          -- ���g�Ȃ�
          ELSE
            ir_masters_rec.proc_code := gn_proc_insert;
          END IF;
--
        -- �ȑO�ɔz����R�[�h������̃f�[�^�Ȃ�
        ELSE
--
          -- �����X�L�b�v
          set_warn_status(ir_status_rec,
                          NULL,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- �ڋq�E�p�[�e�B�}�X�^�f�[�^����(����)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- �ڋq�R�[�h�Ȃ�(�o�^�E�X�V)���L
        IF ((ir_masters_rec.row_n_ins_cnt > 0) OR (ir_masters_rec.row_n_upd_cnt > 0)) THEN
          ir_masters_rec.proc_code := gn_proc_update;
--
        -- �ڋq�R�[�h����(�o�^�E�X�V)���L
        ELSIF ((ir_masters_rec.row_m_ins_cnt > 0) OR (ir_masters_rec.row_m_upd_cnt > 0)) THEN
--
          -- ���g����
          IF (lb_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_update;
--
          -- ���g�Ȃ�
          ELSE
            ir_masters_rec.proc_code := gn_proc_insert;
          END IF;
--
        -- �ȑO�ɔz����R�[�h������̃f�[�^�Ȃ�
        ELSE
          ir_masters_rec.proc_code := gn_proc_update;
        END IF;
--
      -- �ڋq�E�p�[�e�B�}�X�^�f�[�^����(�L��)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- �ڋq�R�[�h�Ȃ�(�o�^�E�X�V)���L
        IF ((ir_masters_rec.row_n_upd_cnt > 0) OR (ir_masters_rec.row_n_ins_cnt > 0)) THEN
          ir_masters_rec.proc_code := gn_proc_update;
--
        -- �ڋq�R�[�h����(�o�^�E�X�V)���L
        ELSIF ((ir_masters_rec.row_m_upd_cnt > 0) OR (ir_masters_rec.row_m_ins_cnt > 0)) THEN
--
          -- ���g����
          IF (lb_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_update;
--
          -- ���g�Ȃ�
          ELSE
            ir_masters_rec.proc_code := gn_proc_insert;
          END IF;
--
        -- �ȑO�ɔz����R�[�h������̃f�[�^�Ȃ�
        ELSE
          ir_masters_rec.proc_code := gn_proc_update;
        END IF;
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
--
    -- ===============================
    -- �폜
    -- ===============================
    IF (ir_masters_rec.k_proc_code = gn_proc_delete) THEN
--
      -- �����X�L�b�v
      set_warn_status(ir_status_rec,
                      NULL,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      RAISE check_party_num_expt;
    END IF;
*/
      -- �z����IF�̑��݃`�F�b�N
      chk_party_num_if(ir_masters_rec,
                       lb_retcd,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
    -- �ڋq�E�p�[�e�B�}�X�^�f�[�^�Ȃ�
    IF ((ln_kbn = gn_data_nothing) AND (lb_retcd = FALSE)) THEN
      ir_masters_rec.proc_code := gn_proc_insert;  -- �o�^
    ELSE
      ir_masters_rec.proc_code := gn_proc_update;    -- �X�V
    END IF;
-- 2008/10/01 v1.10 UPDATE END
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_party_num_expt THEN
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
  END check_party_num;
--
  /***********************************************************************************
   * Procedure Name   : check_ship_to_code
   * Description      : �z����R�[�h�̃`�F�b�N���s���܂��B(A-10)
   ***********************************************************************************/
  PROCEDURE check_ship_to_code(
    ir_status_rec   IN OUT NOCOPY status_rec,  -- ������
    ir_masters_rec  IN OUT NOCOPY masters_rec, -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf       OUT    NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT    NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT    NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_ship_to_code'; -- �v���O������
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
    ln_kbn         NUMBER;
    ln_p_kbn       NUMBER;
    lb_on_retcd    BOOLEAN;           -- �L��
    lb_off_retcd   BOOLEAN;           -- ����
    lb_party_retcd BOOLEAN;           -- ���_
    lb_site_retcd  BOOLEAN;           -- �ڋq
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
    ln_kbn := gn_data_init;
--
    -- �p�[�e�B�[�T�C�g�}�X�^�̃X�e�[�^�X�̃`�F�b�N
    chk_site_status(ir_masters_rec,
                    ln_kbn,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ======================
    -- �o�^
    -- ======================
    IF (ir_masters_rec.k_proc_code = gn_proc_insert) THEN
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^�Ȃ�
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
            ir_masters_rec.proc_code := gn_proc_s_ins;   -- �o�^(���_�R�t��)
--
          -- �ڋq�R�[�h<>NULL
          ELSE
            ir_masters_rec.proc_code := gn_proc_c_ins;   -- �o�^(�ڋq�R�t��)
          END IF;
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^����
        ELSE
--
          -- �o�^���̏d���`�F�b�N�G���[
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_039,
                                                    gv_tkn_ng_haisou,
                                                    ir_masters_rec.ship_to_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^����(����)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
            ir_masters_rec.proc_code := gn_proc_s_upd;   -- �X�V(���_�R�t��)
            ir_masters_rec.status := gv_status_on;       -- �X�e�[�^�X��L��
--
          -- �ڋq�R�[�h<>NULL
          ELSE
            ir_masters_rec.proc_code := gn_proc_c_upd;   -- �X�V(�ڋq�R�t��)
            ir_masters_rec.status := gv_status_on;       -- �X�e�[�^�X��L��
          END IF;
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^����
        ELSE
--
          -- �o�^���̏d���`�F�b�N�G���[
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_039,
                                                    gv_tkn_ng_haisou,
                                                    ir_masters_rec.ship_to_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^����(�L��)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- �X�e�[�^�X�`�F�b�N
        chk_party_status(ir_masters_rec,
                         ln_p_kbn,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;

        -- �ڋq�E�p�[�e�B�}�X�^�f�[�^�Ȃ�
        IF (ln_p_kbn <> gn_data_on) THEN
--
          -- �����X�L�b�v
          set_warn_status(ir_status_rec,
                          NULL,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
        END IF;
--
/* 2008.08.23 Mod ��
        -- �o�^���̏d���`�F�b�N�G���[
        set_error_status(ir_status_rec,
                         xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                  gv_msg_80a_039,
                                                  gv_tkn_ng_haisou,
                                                  ir_masters_rec.ship_to_code),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
2008.08.23 Mod �� */
      END IF;
--
      RAISE check_ship_to_code_expt;
    END IF;
--
    -- ���݃`�F�b�N(����)
    exists_party_number(ir_masters_rec,
                        gv_status_off,
                        lb_off_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݃`�F�b�N(�L��)
    exists_party_number(ir_masters_rec,
                        gv_status_on,
                        lb_on_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݃`�F�b�N(���_�R�[�h)
    exists_xxcmn_site_if(ir_masters_rec,
                         gn_kbn_party,
                         lb_party_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���݃`�F�b�N(�ڋq�R�[�h)
    exists_xxcmn_site_if(ir_masters_rec,
                         gn_kbn_site,
                         lb_site_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ======================
    -- �X�V
    -- ======================
    IF (ir_masters_rec.k_proc_code = gn_proc_update) THEN
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^�Ȃ�
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- �X�V���̑��݃`�F�b�N�G���[
          set_error_status(ir_status_rec,
                           xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                    gv_msg_80a_037,
                                                    gv_tkn_ng_haisou,
                                                    ir_masters_rec.ship_to_code),
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^����
        ELSE
--
          -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
            -- �ȑO�ɓ������_�R�[�h�����݂��Ă���
            IF (lb_party_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_s_upd;   -- �X�V(���_�R�t��)
--
            -- �ȑO�ɓ������_�R�[�h�����݂��Ă��Ȃ�
            ELSE
              ir_masters_rec.proc_code := gn_proc_s_del;   -- �폜/�o�^(���_�R�t��)
            END IF;
--
          -- �ڋq�R�[�h<>NULL
          ELSE
--
            -- �ȑO�ɓ����ڋq�R�[�h�����݂��Ă���
            IF (lb_site_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_c_upd;   -- �X�V(�ڋq�R�t��)
--
            -- �ȑO�ɓ����ڋq�R�[�h�����݂��Ă��Ȃ�
            ELSE
              ir_masters_rec.proc_code := gn_proc_c_del;   -- �폜/�o�^(�ڋq�R�t��)
            END IF;
          END IF;
        END IF;
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^����(����)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
            -- ���_�R�[�h=�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            IF (lb_off_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_s_upd;   -- �X�V(���_�R�t��)
              ir_masters_rec.status := gv_status_on;       -- �X�e�[�^�X��L��
--
            -- ���_�R�[�h<>�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            ELSE
              ir_masters_rec.proc_code := gn_proc_s_ins;   -- �o�^(���_�R�t��)
            END IF;
--
          -- �ڋq�R�[�h<>NULL
          ELSE
--
            -- �ڋq�R�[�h=�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            IF (lb_off_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_c_upd;   -- �X�V(�ڋq�R�t��)
              ir_masters_rec.status := gv_status_on;       -- �X�e�[�^�X��L��
--
            -- �ڋq�R�[�h<>�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            ELSE
              ir_masters_rec.proc_code := gn_proc_c_ins;   -- �o�^(�ڋq�R�t��)
            END IF;
          END IF;
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^����
        ELSE
--
          -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
          IF (ir_masters_rec.party_num IS NULL) THEN
*/
          IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
            -- ���_�R�[�h=�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            IF (lb_off_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_s_upd;   -- �X�V(���_�R�t��)
              ir_masters_rec.status := gv_status_on;       -- �X�e�[�^�X��L��
--
            -- ���_�R�[�h<>�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            ELSE
              ir_masters_rec.proc_code := gn_proc_s_del;   -- �폜/�o�^(���_�R�t��)
            END IF;
--
          -- �ڋq�R�[�h<>NULL
          ELSE
--
            -- �ȑO�Ɍڋq�R�[�h�����݂��Ă���
            IF (lb_site_retcd) THEN
              ir_masters_rec.proc_code := gn_proc_c_upd;   -- �X�V(�ڋq�R�t��)
              ir_masters_rec.status := gv_status_on;       -- �X�e�[�^�X��L��
--
            -- �ȑO�Ɍڋq�R�[�h�����݂��Ă��Ȃ�
            ELSE
              ir_masters_rec.proc_code := gn_proc_c_del;   -- �폜/�o�^(�ڋq�R�t��)
            END IF;
          END IF;
        END IF;
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^����(�L��)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
        IF (ir_masters_rec.party_num IS NULL) THEN
*/
        IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
          -- ���_�R�[�h=�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
          IF (lb_on_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_s_upd;   -- �X�V(���_�R�t��)
--
          -- ���_�R�[�h<>�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
          ELSE
            ir_masters_rec.proc_code := gn_proc_s_del;   -- �폜/�o�^(���_�R�t��)
          END IF;
--
        -- �ڋq�R�[�h<>NULL
        ELSE
--
          -- �ڋq�R�[�h=�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
          IF (lb_on_retcd) THEN
            ir_masters_rec.proc_code := gn_proc_c_upd;   -- �X�V(�ڋq�R�t��)
--
          -- ���_�R�[�h<>�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
          ELSE
            ir_masters_rec.proc_code := gn_proc_c_del;   -- �폜/�o�^(�ڋq�R�t��)
          END IF;
        END IF;
      END IF;
--
      RAISE check_ship_to_code_expt;
    END IF;
--
    -- ======================
    -- �폜
    -- ======================
    IF (ir_masters_rec.k_proc_code = gn_proc_delete) THEN
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^�Ȃ�
      IF (ln_kbn = gn_data_nothing) THEN
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- �폜���̑��݃`�F�b�N���[�j���O
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                   gv_msg_80a_038,
                                                   gv_tkn_ng_haisou,
                                                   ir_masters_rec.ship_to_code),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^����
        ELSE
--
          -- �o�^�E�X�V������
          IF ((ir_masters_rec.row_s_ins_cnt > 0) OR (ir_masters_rec.row_s_upd_cnt > 0)) THEN
--
            -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
            IF (ir_masters_rec.party_num IS NULL) THEN
*/
            IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
              -- �ȑO�ɋ��_�R�[�h�����݂��Ă���
              IF (lb_party_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- �폜(���_�R�t��)
--
              -- �ȑO�ɋ��_�R�[�h�����݂��Ă��Ȃ�
              ELSE
--
                -- �폜���̑��݃`�F�b�N���[�j���O
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
--
            -- �ڋq�R�[�h<>NULL
            ELSE
--
              -- �ȑO�Ɍڋq�R�[�h�����݂��Ă���
              IF (lb_site_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- �폜(�ڋq�R�t��)
--
              -- �ȑO�Ɍڋq�R�[�h�����݂��Ă��Ȃ�
              ELSE
--
                -- �폜���̑��݃`�F�b�N���[�j���O
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
            END IF;
--
          -- �폜������
          ELSE
--
            -- �폜���̑��݃`�F�b�N���[�j���O
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_038,
                                                     gv_tkn_ng_haisou,
                                                     ir_masters_rec.ship_to_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^����(����)
      ELSIF (ln_kbn = gn_data_off) THEN
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
          -- �폜���̑��݃`�F�b�N���[�j���O
          set_warn_status(ir_status_rec,
                          xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                   gv_msg_80a_038,
                                                   gv_tkn_ng_haisou,
                                                   ir_masters_rec.ship_to_code),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_api_expt;
          END IF;
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^����
        ELSE
--
          -- �o�^�E�X�V������
          IF ((ir_masters_rec.row_s_ins_cnt > 0) OR (ir_masters_rec.row_s_upd_cnt > 0)) THEN
--
            -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
            IF (ir_masters_rec.party_num IS NULL) THEN
*/
            IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
              -- �ȑO�ɋ��_�R�[�h�����݂��Ă���
              IF (lb_party_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- �폜(���_�R�t��)
--
              -- �ȑO�ɋ��_�R�[�h�����݂��Ă��Ȃ�
              ELSE
--
                -- �폜���̑��݃`�F�b�N���[�j���O
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
--
            -- �ڋq�R�[�h<>NULL
            ELSE
--
              -- �ȑO�Ɍڋq�R�[�h�����݂��Ă���
              IF (lb_site_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- �폜(�ڋq�R�t��)
--
              -- �ȑO�ɋ��_�R�[�h�����݂��Ă��Ȃ�
              ELSE
--
                -- �폜���̑��݃`�F�b�N���[�j���O
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
            END IF;
--
          -- �폜������
          ELSE
--
            -- �폜���̑��݃`�F�b�N���[�j���O
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_038,
                                                     gv_tkn_ng_haisou,
                                                     ir_masters_rec.ship_to_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
--
      -- �p�[�e�B�T�C�g�}�X�^�f�[�^����(�L��)
      ELSIF (ln_kbn = gn_data_on) THEN
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^�Ȃ�
        IF ((ir_masters_rec.row_s_ins_cnt = 0)
        AND (ir_masters_rec.row_s_upd_cnt = 0)
        AND (ir_masters_rec.row_s_del_cnt = 0)) THEN
--
            -- ���_�R�[�h=�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            IF (lb_on_retcd) THEN
--
              -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
              IF (ir_masters_rec.party_num IS NULL) THEN
*/
              IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- �폜(���_�R�t��)
--
              -- �ڋq�R�[�h<>NULL
              ELSE
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- �폜(�ڋq�R�t��)
              END IF;
--
            -- ���_�R�[�h<>�p�[�e�B�T�C�g�}�X�^.�p�[�e�B�ԍ�
            ELSE
              -- �폜���̑��݃`�F�b�N���[�j���O
              set_warn_status(ir_status_rec,
                              xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                       gv_msg_80a_038,
                                                       gv_tkn_ng_haisou,
                                                       ir_masters_rec.ship_to_code),
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_api_expt;
              END IF;
            END IF;
--
        -- �ȑO�ɓ����z����R�[�h�̃f�[�^����
        ELSE
--
          -- �o�^�E�X�V������
          IF ((ir_masters_rec.row_s_ins_cnt > 0) OR (ir_masters_rec.row_s_upd_cnt > 0)) THEN
--
            -- �ڋq�R�[�h=NULL
-- 2008/08/25 Mod ��
/*
            IF (ir_masters_rec.party_num IS NULL) THEN
*/
            IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--
              -- �ȑO�ɋ��_�R�[�h�����݂��Ă���
              IF (lb_party_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_ds_del;   -- �폜(���_�R�t��)
--
              -- �ȑO�ɋ��_�R�[�h�����݂��Ă��Ȃ�
              ELSE
                -- �폜���̑��݃`�F�b�N���[�j���O
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
--
            -- �ڋq�R�[�h<>NULL
            ELSE
--
              -- �ȑO�Ɍڋq�R�[�h�����݂��Ă���
              IF (lb_site_retcd) THEN
                ir_masters_rec.proc_code := gn_proc_dc_del;   -- �폜(�ڋq�R�t��)
--
              -- �ȑO�Ɍڋq�R�[�h�����݂��Ă��Ȃ�
              ELSE
                -- �폜���̑��݃`�F�b�N���[�j���O
                set_warn_status(ir_status_rec,
                                xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                         gv_msg_80a_038,
                                                         gv_tkn_ng_haisou,
                                                         ir_masters_rec.ship_to_code),
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg);
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_api_expt;
                END IF;
              END IF;
            END IF;
--
          -- �폜������
          ELSE
--
            -- �폜���̑��݃`�F�b�N���[�j���O
            set_warn_status(ir_status_rec,
                            xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                                     gv_msg_80a_038,
                                                     gv_tkn_ng_haisou,
                                                     ir_masters_rec.ship_to_code),
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
            IF (lv_retcode = gv_status_error) THEN
              RAISE global_api_expt;
            END IF;
          END IF;
        END IF;
      END IF;
--
      RAISE check_ship_to_code_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_ship_to_code_expt THEN
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
  END check_ship_to_code;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxcmn_party
   * Description      : �p�[�e�B�A�h�I���}�X�^�̏������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_xxcmn_party(
    ir_masters_rec  IN            masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    in_proc_kbn     IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxcmn_party'; -- �v���O������
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
    lv_party_name      xxcmn_parties.party_name%TYPE;
    lv_address_line1   xxcmn_parties.address_line1%TYPE;
    lv_address_line2   xxcmn_parties.address_line2%TYPE;
--
-- 2009/02/25 v1.13 ADD START
    ln_lenb            NUMBER;
--
-- 2009/02/25 v1.13 ADD END
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
    -- �o�^����
    IF (in_proc_kbn = gn_proc_insert) THEN
--
      -- ���_�C���^�t�F�[�X
      IF (ir_masters_rec.tbl_kbn = gn_kbn_party) THEN
-- 2009/02/25 v1.13 ADD START
--        lv_address_line1 := SUBSTR(ir_masters_rec.address,1,15);
--        lv_address_line2 := SUBSTR(ir_masters_rec.address,31,15);
--
        lv_address_line1 := RTRIM(SUBSTRB(ir_masters_rec.address, 1, 30));
        ln_lenb          := TO_NUMBER(LENGTHB(lv_address_line1)) + 1;
        lv_address_line2 := RTRIM(SUBSTRB(ir_masters_rec.address, ln_lenb, 30));
--
-- 2009/02/25 v1.13 ADD END
        INSERT INTO xxcmn_parties
          (party_id
          ,start_date_active
          ,end_date_active
          ,party_name
          ,party_short_name
          ,party_name_alt
          ,zip
          ,address_line1
          ,address_line2
          ,phone
          ,fax
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date)
        VALUES (
           ir_masters_rec.p_party_id        --�p�[�e�BID
          ,gd_min_date                      --�K�p�J�n��
          ,gd_max_date                      --�K�p�I����
          ,ir_masters_rec.party_name        --������
          ,ir_masters_rec.party_short_name  --����
          ,ir_masters_rec.party_name_alt    --�J�i��
          ,ir_masters_rec.zip2              --�X�֔ԍ�2
          ,lv_address_line1                 --�Z��1
          ,lv_address_line2                 --�Z��2
          ,ir_masters_rec.phone             --�d�b�ԍ�
          ,ir_masters_rec.fax               --FAX�ԍ�
          ,gn_created_by
          ,gd_creation_date
          ,gn_last_updated_by
          ,gd_last_update_date
          ,gn_last_update_login
          ,gn_request_id
          ,gn_program_application_id
          ,gn_program_id
          ,gd_program_update_date);
--
      -- �z����C���^�t�F�[�X(�ڋq)
      ELSE
        lv_party_name := ir_masters_rec.customer_name1||ir_masters_rec.customer_name2;
--
        INSERT INTO xxcmn_parties
          (party_id
          ,start_date_active
          ,end_date_active
          ,party_name
          ,created_by
          ,creation_date
          ,last_updated_by
          ,last_update_date
          ,last_update_login
          ,request_id
          ,program_application_id
          ,program_id
          ,program_update_date)
        VALUES (
           ir_masters_rec.p_party_id         --�p�[�e�BID
          ,gd_min_date                       --�K�p�J�n��
          ,gd_max_date                       --�K�p�I����
          ,lv_party_name                     --������
          ,gn_created_by
          ,gd_creation_date
          ,gn_last_updated_by
          ,gd_last_update_date
          ,gn_last_update_login
          ,gn_request_id
          ,gn_program_application_id
          ,gn_program_id
          ,gd_program_update_date);
--
      END IF;
--
    -- �X�V����
    ELSE
--
      -- ���_�C���^�t�F�[�X
      IF (ir_masters_rec.tbl_kbn = gn_kbn_party) THEN
-- 2009/02/25 v1.13 ADD START
--        lv_address_line1 := SUBSTR(ir_masters_rec.address,1,15);
--        lv_address_line2 := SUBSTR(ir_masters_rec.address,31,15);
--
        lv_address_line1 := RTRIM(SUBSTRB(ir_masters_rec.address, 1, 30));
        ln_lenb          := TO_NUMBER(LENGTHB(lv_address_line1)) + 1;
        lv_address_line2 := RTRIM(SUBSTRB(ir_masters_rec.address, ln_lenb, 30));
--
-- 2009/02/25 v1.13 ADD END
--
        UPDATE xxcmn_parties SET
           party_name             = ir_masters_rec.party_name             --������
          ,party_short_name       = ir_masters_rec.party_short_name       --����
          ,party_name_alt         = ir_masters_rec.party_name_alt         --�J�i��
          ,zip                    = ir_masters_rec.zip2                   --�X�֔ԍ�2
          ,address_line1          = lv_address_line1                      --�Z��1
          ,address_line2          = lv_address_line2                      --�Z��2
          ,phone                  = ir_masters_rec.phone                  --�d�b�ԍ�
          ,fax                    = ir_masters_rec.fax                    --FAX�ԍ�
          ,last_updated_by        = gn_last_updated_by
          ,last_update_date       = gd_last_update_date
          ,last_update_login      = gn_last_update_login
          ,request_id             = gn_request_id
          ,program_application_id = gn_program_application_id
          ,program_id             = gn_program_id
          ,program_update_date    = gd_program_update_date
        WHERE party_id            = ir_masters_rec.p_party_id;
--
      -- �z����C���^�t�F�[�X(�ڋq)
      ELSE
        lv_party_name := ir_masters_rec.customer_name1||ir_masters_rec.customer_name2;
--
        UPDATE xxcmn_parties SET
           party_name             = lv_party_name                         --������
          ,last_updated_by        = gn_last_updated_by
          ,last_update_date       = gd_last_update_date
          ,last_update_login      = gn_last_update_login
          ,request_id             = gn_request_id
          ,program_application_id = gn_program_application_id
          ,program_id             = gn_program_id
          ,program_update_date    = gd_program_update_date
        WHERE party_id            = ir_masters_rec.p_party_id;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_xxcmn_party;
--
  /***********************************************************************************
   * Procedure Name   : proc_xxcmn_party_site
   * Description      : �p�[�e�B�T�C�g�A�h�I���}�X�^�̏������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_xxcmn_party_site(
    ir_masters_rec  IN            masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    in_proc_kbn     IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_xxcmn_party_site'; -- �v���O������
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
    cv_def_cond   CONSTANT VARCHAR2(2) := '00';
--
    -- *** ���[�J���ϐ� ***
    lv_site_name      xxcmn_party_sites.party_site_name%TYPE;
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
    lv_site_name := ir_masters_rec.party_site_name1 || ir_masters_rec.party_site_name2;
--
    -- �o�^����
    IF (in_proc_kbn = gn_proc_insert) THEN
--
      INSERT INTO xxcmn_party_sites
        (party_site_id
        ,party_id
        ,location_id
        ,start_date_active
        ,end_date_active
        ,base_code
        ,party_site_name
        ,zip
        ,address_line1
        ,address_line2
        ,phone
        ,fax
        ,freshness_condition                     -- 2008/08/19 Add
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date)
      VALUES (
         ir_masters_rec.party_site_id            --�p�[�e�B�[�T�C�gID
        ,ir_masters_rec.p_party_id               --�p�[�e�B�[ID
        ,ir_masters_rec.location_id              --���P�[�V����ID
        ,gd_min_date                             --�K�p�J�n��
        ,gd_max_date                             --�K�p�I����
        ,ir_masters_rec.base_code                --���_�R�[�h
        ,lv_site_name                            --������
        ,ir_masters_rec.zip2                     --�X�֔ԍ�2
        ,ir_masters_rec.party_site_addr1         --�Z���P
        ,ir_masters_rec.party_site_addr2         --�Z���Q
        ,ir_masters_rec.phone                    --�d�b�ԍ�
        ,ir_masters_rec.fax                      --�e�`�w�ԍ�
        ,cv_def_cond                             --�N�x���� 2008/08/19 Add
        ,gn_created_by
        ,gd_creation_date
        ,gn_last_updated_by
        ,gd_last_update_date
        ,gn_last_update_login
        ,gn_request_id
        ,gn_program_application_id
        ,gn_program_id
        ,gd_program_update_date);
--
    -- �X�V����
    ELSE
--
      UPDATE xxcmn_party_sites SET
         base_code              = ir_masters_rec.base_code           --���_�R�[�h
        ,party_site_name        = lv_site_name                       --������
        ,zip                    = ir_masters_rec.zip2                --�X�֔ԍ�2
        ,address_line1          = ir_masters_rec.party_site_addr1    --�Z��1
        ,address_line2          = ir_masters_rec.party_site_addr2    --�Z��2
        ,phone                  = ir_masters_rec.phone               --�d�b�ԍ�
        ,fax                    = ir_masters_rec.fax                 --FAX�ԍ�
        ,last_updated_by        = gn_last_updated_by
        ,last_update_date       = gd_last_update_date
        ,last_update_login      = gn_last_update_login
        ,request_id             = gn_request_id
        ,program_application_id = gn_program_application_id
        ,program_id             = gn_program_id
        ,program_update_date    = gd_program_update_date
      WHERE party_site_id       = ir_masters_rec.party_site_id
      AND   party_id            = ir_masters_rec.p_party_id
      AND   location_id         = ir_masters_rec.location_id;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_xxcmn_party_site;
--
  /***********************************************************************************
   * Procedure Name   : create_party_account
   * Description      : �p�[�e�B�}�X�^�ƌڋq�}�X�^�̓o�^�������s���܂��B
   ***********************************************************************************/
  PROCEDURE create_party_account(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    in_kbn          IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_party_account'; -- �v���O������
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
    lv_api_name                     VARCHAR2(200);
    lr_organization_rec             HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    lr_cust_account_rec             HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    lr_customer_profile_rec         HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    ln_party_id                     NUMBER;
    lv_party_number                 hz_parties.party_number%TYPE;
    ln_profile_id                   NUMBER;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    ln_cust_account_id              hz_cust_accounts.cust_account_id%TYPE;
    lv_account_number               hz_cust_accounts.account_number%TYPE;
    lv_class_code                   VARCHAR2(30);
    lb_retcd                        BOOLEAN;
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
    -- �ڋq�敪�̎擾
    get_class_code(in_kbn,
                   lv_class_code,
                   lb_retcd,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
    IF ((lv_retcode = gv_status_error) OR (NOT lb_retcd)) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �K�{����
    lr_organization_rec.created_by_module        := gv_created_by_module;
    lr_cust_account_rec.created_by_module        := gv_created_by_module;
    lr_cust_account_rec.status                   := gv_status_on;
    lr_organization_rec.party_rec.validated_flag := gv_validated_flag_on;
    lr_cust_account_rec.customer_class_code      := lv_class_code;
--
    -- �p�[�e�B�}�X�^.DFF24(�}�X�^��M����)
    lr_organization_rec.party_rec.attribute24 := TO_CHAR(SYSDATE,'YYYYMMDD');
--
    IF (in_kbn = gn_kbn_party) THEN
--
      -- �p�[�e�B��
      lr_organization_rec.organization_name := ir_masters_rec.party_name;
      -- �ڋq�ԍ�(���_�R�[�h)
      lr_cust_account_rec.account_number    := ir_masters_rec.base_code;
      -- �����P
      lr_cust_account_rec.attribute1        := ir_masters_rec.old_division_code;
      -- �����Q
      lr_cust_account_rec.attribute2        := ir_masters_rec.new_division_code;
      -- �����R
      lr_cust_account_rec.attribute3 := TO_CHAR(ir_masters_rec.division_start_date,'YYYY/MM/DD');
      -- �����S
      lr_cust_account_rec.attribute4        := ir_masters_rec.location_rel_code;
      -- �����T
      lr_cust_account_rec.attribute5        := ir_masters_rec.ship_mng_code;
      -- �����U
      lr_cust_account_rec.attribute6        := ir_masters_rec.warehouse_code;
      -- �����V
      lr_cust_account_rec.attribute7        := ir_masters_rec.terminal_code;
-- 2008/10/07 v1.11 DELETE START
--      -- �����P�R
--      lr_cust_account_rec.attribute13       := ir_masters_rec.district_code;
-- 2008/10/07 v1.11 DELETE END
--
    ELSE
--
      -- �p�[�e�B��
      lr_organization_rec.organization_name := ir_masters_rec.customer_name1||
                                               ir_masters_rec.customer_name2;
      -- �ڋq�ԍ�(�ڋq�R�[�h)
      lr_cust_account_rec.account_number    := ir_masters_rec.party_num;
      -- �����P�Q
      lr_cust_account_rec.attribute12       := ir_masters_rec.cal_cust_app_flg;
      -- �����P�T
      lr_cust_account_rec.attribute15       := ir_masters_rec.direct_ship_code;
-- 2008/10/07 v1.11 DELETE START
--      -- �����P�U
--      lr_cust_account_rec.attribute16       := ir_masters_rec.direct_ship_code;
-- 2008/10/07 v1.11 DELETE END
      -- �����P�V
      lr_cust_account_rec.attribute17       := ir_masters_rec.sale_base_code;
      -- �����P�W
      lr_cust_account_rec.attribute18       := ir_masters_rec.res_sale_base_code;
      -- �����P�X
      lr_cust_account_rec.attribute19       := ir_masters_rec.chain_store;
      -- �����Q�O
      lr_cust_account_rec.attribute20       := ir_masters_rec.chain_store_name;
    END IF;
--
    -- �ڋq�}�X�^(HZ_CUST_ACCOUNT_V2PUB)
    HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT (
        P_INIT_MSG_LIST        => FND_API.G_FALSE
       ,P_CUST_ACCOUNT_REC     => lr_cust_account_rec
       ,P_ORGANIZATION_REC     => lr_organization_rec
       ,P_CUSTOMER_PROFILE_REC => lr_customer_profile_rec
       ,P_CREATE_PROFILE_AMT   => FND_API.G_FALSE
       ,X_CUST_ACCOUNT_ID      => ln_cust_account_id
       ,X_ACCOUNT_NUMBER       => lv_account_number
       ,X_PARTY_ID             => ln_party_id
       ,X_PARTY_NUMBER         => lv_party_number
       ,X_PROFILE_ID           => ln_profile_id
       ,X_RETURN_STATUS        => lv_return_status
       ,X_MSG_COUNT            => ln_msg_count
       ,X_MSG_DATA             => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    ir_masters_rec.p_party_id   := ln_party_id;                     -- �p�[�e�BID
    ir_masters_rec.party_number := lv_party_number;                 -- �p�[�e�B�ԍ�
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END create_party_account;
--
  /***********************************************************************************
   * Procedure Name   : update_hz_parties
   * Description      : �p�[�e�B�}�X�^�̍X�V�������s���܂��B
   ***********************************************************************************/
  PROCEDURE update_hz_parties(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    in_kbn          IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_hz_parties'; -- �v���O������
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
    lv_api_name                     VARCHAR2(200);
    lr_organization_rec             HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    ln_profile_id                   NUMBER;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    ln_object_version_number        hz_parties.object_version_number%TYPE;
    lv_validated_flag               hz_parties.validated_flag%TYPE;
    ln_kbn                          NUMBER;
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
    -- ���_�P��
    IF ((in_kbn = gn_kbn_upd_site) OR (in_kbn = gn_kbn_del_site)) THEN
      ln_kbn := gn_kbn_party;
--
    -- �ڋq�P��
    ELSE
      ln_kbn := gn_kbn_site;
    END IF;
--
    -- �I�u�W�F�N�g�o�[�W�����ԍ��̎擾
    exists_party_id(ir_masters_rec,
                    ln_kbn,
                    gv_status_on,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (ir_masters_rec.p_party_id IS NULL) THEN
--s
      -- �I�u�W�F�N�g�o�[�W�����ԍ��̎擾
      exists_party_id(ir_masters_rec,
                      ln_kbn,
                      gv_status_off,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �K�{����
    ln_object_version_number                   := ir_masters_rec.obj_party_number;
    lr_organization_rec.party_rec.party_id     := ir_masters_rec.p_party_id;
    lr_organization_rec.party_rec.party_number := ir_masters_rec.party_number;
--
    -- �L���t���O
    IF (in_kbn = gn_kbn_upd_site) THEN
      lv_validated_flag := gv_validated_flag_on;
--
    ELSIF (in_kbn = gn_kbn_upd_cust) THEN
      lv_validated_flag := ir_masters_rec.validated_flag;
--
    ELSE
      lv_validated_flag := gv_validated_flag_off;
    END IF;
    lr_organization_rec.party_rec.validated_flag := lv_validated_flag;
--
    IF (in_kbn = gn_kbn_upd_cust) THEN
      -- �����Q�S
      lr_organization_rec.party_rec.attribute24 := TO_CHAR(SYSDATE,'YYYYMMDD');
    END IF;
--
    -- �p�[�e�B�}�X�^(HZ_PARTY_V2PUB)
    HZ_PARTY_V2PUB.UPDATE_ORGANIZATION (
        P_INIT_MSG_LIST               => FND_API.G_FALSE
       ,P_ORGANIZATION_REC            => lr_organization_rec
       ,P_PARTY_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_PROFILE_ID                  => ln_profile_id
       ,X_RETURN_STATUS               => lv_return_status
       ,X_MSG_COUNT                   => ln_msg_count
       ,X_MSG_DATA                    => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_PARTY_V2PUB.UPDATE_ORGANIZATION';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END update_hz_parties;
--
  /***********************************************************************************
   * Procedure Name   : update_hz_cust_accounts
   * Description      : �ڋq�}�X�^�̍X�V�������s���܂��B
   ***********************************************************************************/
  PROCEDURE update_hz_cust_accounts(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    in_kbn          IN            NUMBER,       -- �����敪
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_hz_cust_accounts'; -- �v���O������
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
    lv_api_name                     VARCHAR2(200);
    lr_cust_account_rec             HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    ln_object_version_number        hz_cust_accounts.object_version_number%TYPE;
    lv_status                       hz_cust_accounts.status%TYPE;
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
    -- �I�u�W�F�N�g�o�[�W�����ԍ��̎擾
    exists_party_id(ir_masters_rec,
                    gn_kbn_site,
                    gv_status_on,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (ir_masters_rec.obj_cust_number IS NULL) THEN
--
      -- �I�u�W�F�N�g�o�[�W�����ԍ��̎擾
      exists_party_id(ir_masters_rec,
                      gn_kbn_party,
                      gv_status_on,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (ir_masters_rec.obj_cust_number IS NULL) THEN
--
      -- �I�u�W�F�N�g�o�[�W�����ԍ��̎擾
      exists_party_id(ir_masters_rec,
                      gn_kbn_site,
                      gv_status_off,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF (ir_masters_rec.obj_cust_number IS NULL) THEN
--
      -- �I�u�W�F�N�g�o�[�W�����ԍ��̎擾
      exists_party_id(ir_masters_rec,
                      gn_kbn_party,
                      gv_status_off,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �K�{����
    ln_object_version_number            := ir_masters_rec.obj_cust_number;
    lr_cust_account_rec.cust_account_id := ir_masters_rec.cust_account_id;
--
    -- �X�e�[�^�X
    IF (in_kbn = gn_kbn_upd_site) THEN
      lv_status := gv_status_on;
--
    ELSIF (in_kbn = gn_kbn_upd_cust) THEN
      lv_status := ir_masters_rec.status;
--
    ELSE
      lv_status := gv_status_off;
    END IF;
    lr_cust_account_rec.status := lv_status;
--
    IF (in_kbn = gn_kbn_upd_site) THEN
      -- �����P
      lr_cust_account_rec.attribute1 := ir_masters_rec.old_division_code;
      -- �����Q
      lr_cust_account_rec.attribute2 := ir_masters_rec.new_division_code;
      -- �����R
      lr_cust_account_rec.attribute3 := TO_CHAR(ir_masters_rec.division_start_date,'YYYY/MM/DD');
      -- �����S
      lr_cust_account_rec.attribute4 := ir_masters_rec.location_rel_code;
      -- �����T
      lr_cust_account_rec.attribute5 := ir_masters_rec.ship_mng_code;
      -- �����U
      lr_cust_account_rec.attribute6 := ir_masters_rec.warehouse_code;
      -- �����V
      lr_cust_account_rec.attribute7 := ir_masters_rec.terminal_code;
--2008/10/07 v1.11 DELETE START
--      -- �����P�R
--      lr_cust_account_rec.attribute13 := ir_masters_rec.district_code;
--2008/10/07 v1.11 DELETE END
--
    ELSIF (in_kbn = gn_kbn_upd_cust) THEN
      ln_object_version_number        := ir_masters_rec.obj_cust_number;
      -- �����P�Q
      lr_cust_account_rec.attribute12 := ir_masters_rec.cal_cust_app_flg;
      -- �����P�T
      lr_cust_account_rec.attribute15 := ir_masters_rec.direct_ship_code;
--2008/10/07 v1.11 DELETE START
--      -- �����P�U
--      lr_cust_account_rec.attribute16 := ir_masters_rec.direct_ship_code;
--2008/10/07 v1.11 DELETE END
      -- �����P�V
      lr_cust_account_rec.attribute17 := ir_masters_rec.sale_base_code;
      -- �����P�W
      lr_cust_account_rec.attribute18 := ir_masters_rec.res_sale_base_code;
      -- �����P�X
      lr_cust_account_rec.attribute19 := ir_masters_rec.chain_store;
      -- �����Q�O
      lr_cust_account_rec.attribute20 := ir_masters_rec.chain_store_name;
    END IF;
--
    -- �ڋq�}�X�^(HZ_CUST_ACCOUNT_V2PUB)
    HZ_CUST_ACCOUNT_V2PUB.UPDATE_CUST_ACCOUNT (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_CUST_ACCOUNT_REC      => lr_cust_account_rec
       ,P_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_V2PUB.UPDATE_CUST_ACCOUNT';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END update_hz_cust_accounts;
--
  /***********************************************************************************
   * Procedure Name   : insert_hz_party_sites
   * Description      : �p�[�e�B�T�C�g�}�X�^�̓o�^�������s���܂��B
   ***********************************************************************************/
  PROCEDURE insert_hz_party_sites(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_hz_party_sites'; -- �v���O������
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
    lv_api_name                     VARCHAR2(200);
    lr_party_site_rec               HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
    lr_location_rec                 HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    lr_cust_site_rec                HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
    lr_cust_site_use_rec            HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
    lr_customer_profile_rec         HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    ln_location_id                  hz_party_sites.location_id%TYPE;
    ln_cust_site_id                 hz_cust_acct_sites_all.cust_acct_site_id%TYPE;
    ln_site_use_id                  hz_cust_site_uses_all.site_use_id%TYPE;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    lv_party_site_number            hz_party_sites.party_site_number%TYPE;
    ln_party_site_id                NUMBER;
--
    lv_county                       hz_locations.county%TYPE;
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    ln_cnt                          NUMBER;
    lv_primary_flag                 hz_cust_site_uses_all.primary_flag%TYPE;
--
-- 2009/01/09 v1.12 ADD START
    lv_account_number               hz_cust_accounts.account_number%TYPE;
-- 2009/01/09 v1.12 ADD END
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
    -- �p�[�e�BID�̎擾
    get_party_id(ir_masters_rec,
                 lv_errbuf,
                 lv_retcode,
                 lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    lr_location_rec.country := 'JP';
    IF (ir_masters_rec.party_site_addr1 IS NOT NULL) THEN
        lr_location_rec.address1 := ir_masters_rec.party_site_addr1;
--
    ELSE
        lr_location_rec.address1 := gv_location_addr;
    END IF;
--
    IF (ir_masters_rec.party_site_addr2 IS NOT NULL) THEN
      lr_location_rec.address2 := ir_masters_rec.party_site_addr2;
    END IF;
    lr_location_rec.created_by_module := gv_created_by_module;
-- 2008/08/25 Add
    lv_county := ir_masters_rec.party_site_name1 || ir_masters_rec.party_site_name2;
    lr_location_rec.province := ir_masters_rec.ship_to_code;
    lr_location_rec.county   := lv_county;
--
    -- �ڋq���Ə��}�X�^(HZ_LOCATION_V2PUB)
    HZ_LOCATION_V2PUB.CREATE_LOCATION (
        P_INIT_MSG_LIST => FND_API.G_FALSE
       ,P_LOCATION_REC  => lr_location_rec
       ,X_LOCATION_ID   => ln_location_id
       ,X_RETURN_STATUS => lv_return_status
       ,X_MSG_COUNT     => ln_msg_count
       ,X_MSG_DATA      => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_LOCATION_V2PUB.CREATE_LOCATION';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    lr_party_site_rec.party_id := ir_masters_rec.p_party_id;
    lr_party_site_rec.location_id := ln_location_id;
    lr_party_site_rec.created_by_module := gv_created_by_module;
--
    -- 2008/04/17 �ύX�v��No61 �Ή�
    lr_party_site_rec.party_site_number := NULL;
--
/* 2008/08/25 Del ��
    lr_party_site_rec.party_site_name   := ir_masters_rec.party_site_name1||
                                           ir_masters_rec.party_site_name2;
2008/08/25 Del �� */
    lr_party_site_rec.attribute20       := TO_CHAR(SYSDATE,'YYYYMMDD');
    lr_party_site_rec.status            := gv_status_on;
--
    -- �p�[�e�B�T�C�g�}�X�^(HZ_PARTY_SITE_V2PUB)
    HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE (
        P_INIT_MSG_LIST     => FND_API.G_FALSE
       ,P_PARTY_SITE_REC    => lr_party_site_rec
       ,X_PARTY_SITE_ID     => ln_party_site_id
       ,X_PARTY_SITE_NUMBER => lv_party_site_number
       ,X_RETURN_STATUS     => lv_return_status
       ,X_MSG_COUNT         => ln_msg_count
       ,X_MSG_DATA          => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    -- 2008/04/17 �ύX�v��No61 �Ή�
    -- �ڋq���ݒn�}�X�^�̌���
    BEGIN
-- 2009/01/09 v1.12 ADD START
--
      -- �ڋq�R�[�h=NULL
      IF (ir_masters_rec.party_num = gv_def_party_num) THEN
        lv_account_number := ir_masters_rec.base_code;       -- ���_�R�[�h
      -- �ڋq�R�[�h<>NULL
      ELSE
        lv_account_number := ir_masters_rec.party_num;       -- �ڋq�R�[�h
      END IF;
--
-- 2009/01/09 v1.12 ADD END
      SELECT COUNT(hcas.cust_acct_site_id)
      INTO   ln_cnt
-- 2008/08/25 Mod ��
/*
      FROM   hz_cust_acct_sites_all hcas
      WHERE  hcas.attribute18 = ir_masters_rec.ship_to_code
      AND    ROWNUM = 1;
*/
-- 2009/01/09 v1.12 UPDATE START
/*
      FROM   hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_locations           hzl                  -- �ڋq���Ə��}�X�^
      WHERE  hzl.location_id   = hps.location_id
      AND    hps.party_site_id = hcas.party_site_id
      AND    hps.status         = gv_status_on
      AND    hzl.province       = ir_masters_rec.ship_to_code;   -- �z����R�[�h
-- 2008/08/25 Mod ��
*/
      FROM   hz_party_sites         hps,                 -- �p�[�e�B�T�C�g�}�X�^
             hz_cust_acct_sites_all hcas,                -- �ڋq���ݒn�}�X�^
             hz_cust_accounts       hca                  -- �ڋq�}�X�^
      WHERE  hps.party_site_id  = hcas.party_site_id
      AND    hps.party_id       = hca.party_id
      AND    hps.status         = gv_status_on
      AND    hca.account_number = lv_account_number
      ;
-- 2009/01/09 v1.12 UPDATE END
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_cnt := 0;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    IF (ln_cnt = 0) THEN
      lv_primary_flag := gv_primary_flag_on;
--
    ELSE
      lv_primary_flag := gv_primary_flag_off;
    END IF;
--
    ir_masters_rec.party_site_id := ln_party_site_id;
    ir_masters_rec.location_id   := ln_location_id;
--
    lr_cust_site_rec.cust_account_id   := ir_masters_rec.cust_account_id; -- �ڋqID
    lr_cust_site_rec.party_site_id     := ln_party_site_id;               -- �p�[�e�B�T�C�gID
    lr_cust_site_rec.created_by_module := gv_created_by_module;           -- �쐬���W���[��
/* 2008/08/25 Del ��
    lr_cust_site_rec.attribute18       := ir_masters_rec.ship_to_code;    -- �����P�W
2008/08/25 Del �� */
-- 2008/08/18 Add
    lr_cust_site_rec.attribute_category := FND_PROFILE.VALUE('ORG_ID');
--
    -- �ڋq���ݒn�}�X�^(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE (
        P_INIT_MSG_LIST      => FND_API.G_FALSE
       ,P_CUST_ACCT_SITE_REC => lr_cust_site_rec
       ,X_CUST_ACCT_SITE_ID  => ln_cust_site_id
       ,X_RETURN_STATUS      => lv_return_status
       ,X_MSG_COUNT          => ln_msg_count
       ,X_MSG_DATA           => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    -- ������
    lr_cust_site_use_rec.cust_acct_site_id := ln_cust_site_id;
    lr_cust_site_use_rec.site_use_code     := 'BILL_TO';
    lr_cust_site_use_rec.primary_flag      := lv_primary_flag;
    lr_cust_site_use_rec.status            := gv_status_on;
    lr_cust_site_use_rec.location          := ln_cust_site_id;
    lr_cust_site_use_rec.created_by_module := gv_created_by_module;
--
    -- �ڋq�g�p�ړI�}�X�^(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(
        P_INIT_MSG_LIST        => FND_API.G_FALSE
       ,P_CUST_SITE_USE_REC    => lr_cust_site_use_rec
       ,P_CUSTOMER_PROFILE_REC => lr_customer_profile_rec
       ,P_CREATE_PROFILE       => FND_API.G_TRUE
       ,P_CREATE_PROFILE_AMT   => FND_API.G_TRUE
       ,X_SITE_USE_ID          => ln_site_use_id
       ,X_RETURN_STATUS        => lv_return_status
       ,X_MSG_COUNT            => ln_msg_count
       ,X_MSG_DATA             => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    -- �o�א�
    lr_cust_site_use_rec.cust_acct_site_id   := ln_cust_site_id;
    lr_cust_site_use_rec.site_use_code       := 'SHIP_TO';
    lr_cust_site_use_rec.primary_flag        := lv_primary_flag;
    lr_cust_site_use_rec.status              := gv_status_on;
    lr_cust_site_use_rec.location            := ln_cust_site_id;
    lr_cust_site_use_rec.bill_to_site_use_id := ln_site_use_id;
    lr_cust_site_use_rec.created_by_module   := gv_created_by_module;
--
    -- �ڋq�g�p�ړI�}�X�^(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE(
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_CUST_SITE_USE_REC     => lr_cust_site_use_rec
       ,P_CUSTOMER_PROFILE_REC  => lr_customer_profile_rec
       ,P_CREATE_PROFILE        => FND_API.G_TRUE
       ,P_CREATE_PROFILE_AMT    => FND_API.G_TRUE
       ,X_SITE_USE_ID           => ln_site_use_id
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END insert_hz_party_sites;
--
  /***********************************************************************************
   * Procedure Name   : update_hz_party_sites
   * Description      : �p�[�e�B�T�C�g�}�X�^�̍X�V�������s���܂��B
   ***********************************************************************************/
  PROCEDURE update_hz_party_sites(
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_hz_party_sites'; -- �v���O������
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
    lv_api_name                     VARCHAR2(200);
    lr_party_site_rec               HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
    lr_cust_site_rec                HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
    lv_return_status                VARCHAR2(30);
    ln_msg_count                    NUMBER;
    lv_msg_data                     VARCHAR2(2000);
    lv_party_site_number            hz_party_sites.party_site_number%TYPE;
    ln_party_site_id                hz_party_sites.party_site_id%TYPE;
    ln_object_version_number        hz_party_sites.object_version_number%TYPE;
    lb_retcd                        BOOLEAN;
-- 2008/08/25 Add ��
    lr_location_rec                 HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
    lv_county                       hz_locations.county%TYPE;
-- 2008/08/25 Add ��
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
    -- �p�[�e�B�T�C�gID�̎擾(�L��)
    get_party_site_id(ir_masters_rec,
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
      -- �p�[�e�B�T�C�gID�̎擾(����)
      get_party_site_id_2(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    END IF;
/*
--
    IF (NOT lb_retcd) THEN
      -- �p�[�e�B�T�C�gID�̎擾
      get_site_to_if(ir_masters_rec,
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
        -- �p�[�e�B�T�C�gID�̎擾
        get_site_number(ir_masters_rec,
                        lb_retcd,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
*/
--
    lr_party_site_rec.party_site_id := ir_masters_rec.party_site_id;
    lr_party_site_rec.party_id      := ir_masters_rec.p_party_id;
    lr_party_site_rec.location_id   := ir_masters_rec.location_id;
    ln_object_version_number        := ir_masters_rec.obj_site_number;
--
    -- �X�e�[�^�X
    lr_party_site_rec.status := ir_masters_rec.status;
--
    -- �p�[�e�B�T�C�g�}�X�^(HZ_PARTY_SITE_V2PUB)
    HZ_PARTY_SITE_V2PUB.UPDATE_PARTY_SITE (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_PARTY_SITE_REC        => lr_party_site_rec
       ,P_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_PARTY_SITE_V2PUB.UPDATE_PARTY_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
    lr_cust_site_rec.cust_acct_site_id := ir_masters_rec.cust_acct_site_id;
    lr_cust_site_rec.status := ir_masters_rec.status;
    ln_object_version_number := ir_masters_rec.obj_acct_number;
--
    -- �ڋq���ݒn�}�X�^(HZ_CUST_ACCOUNT_SITE_V2PUB)
    HZ_CUST_ACCOUNT_SITE_V2PUB.UPDATE_CUST_ACCT_SITE (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_CUST_ACCT_SITE_REC    => lr_cust_site_rec
       ,p_object_version_number => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    -- ���s
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_CUST_ACCOUNT_SITE_V2PUB.UPDATE_CUST_ACCT_SITE';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
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
-- 2008/08/25 Add ��
    lv_county := ir_masters_rec.party_site_name1 || ir_masters_rec.party_site_name2;
    lr_location_rec.location_id := ir_masters_rec.hzl_location_id;
    lr_location_rec.county      := lv_county;
    ln_object_version_number    := ir_masters_rec.hzl_obj_number;
--
    -- �ڋq���Ə��}�X�^(HZ_LOCATION_V2PUB)
    HZ_LOCATION_V2PUB.UPDATE_LOCATION (
        P_INIT_MSG_LIST         => FND_API.G_FALSE
       ,P_LOCATION_REC          => lr_location_rec
       ,P_OBJECT_VERSION_NUMBER => ln_object_version_number
       ,X_RETURN_STATUS         => lv_return_status
       ,X_MSG_COUNT             => ln_msg_count
       ,X_MSG_DATA              => lv_msg_data
    );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_api_name := 'HZ_LOCATION_V2PUB.UPDATE_LOCATION';
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,      gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
      lv_errbuf := lv_msg_data;
      RAISE global_api_expt;
    END IF;
-- 2008/08/25 Add ��
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END update_hz_party_sites;
--
  /***********************************************************************************
   * Procedure Name   : proc_party
   * Description      : ���_���f�������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_party(
    ir_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�f�[�^
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party'; -- �v���O������
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
    -- �o�^�ȊO
    IF (ir_masters_rec.proc_code <> gn_proc_insert) THEN
--
      -- �p�[�e�B�}�X�^���݃`�F�b�N
      get_hz_parties(ir_masters_rec,
                     gn_kbn_party,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �ڋq�}�X�^���݃`�F�b�N
      get_hz_cust_accounts(ir_masters_rec,
                           gn_kbn_party,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���_�o�^���
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
--
      -- �p�[�e�B�}�X�^�E�ڋq�}�X�^�o�^
      create_party_account(ir_masters_rec,
                           gn_kbn_party,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
      ir_report_rec.hca_flg := 1;
--
      -- �p�[�e�B�A�h�I���}�X�^(���ړo�^)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_insert,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- ���_�X�V���
    ELSIF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
      -- �p�[�e�B�}�X�^�X�V
      update_hz_parties(ir_masters_rec,
                        gn_kbn_upd_site,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- �ڋq�}�X�^�X�V
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_upd_site,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
--
      -- �p�[�e�B�A�h�I���}�X�^(���ڍX�V)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_update,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- ���_�폜���
    ELSIF (ir_masters_rec.proc_code = gn_proc_delete) THEN
--
      -- �p�[�e�B�}�X�^�X�V
      update_hz_parties(ir_masters_rec,
                        gn_kbn_del_site,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- �ڋq�}�X�^�X�V
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_del_site,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_party;
--
  /***********************************************************************************
   * Procedure Name   : proc_cust
   * Description      : �ڋq���f�������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_cust(
    ir_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�f�[�^
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust'; -- �v���O������
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
    lv_validated_flag       hz_parties.validated_flag%TYPE;          -- �L���t���O
    lv_status               hz_cust_accounts.status%TYPE;            -- �L���X�e�[�^�X
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
    -- �o�^�ȊO
    IF (ir_masters_rec.proc_code <> gn_proc_insert) THEN
--
      IF (ir_masters_rec.p_party_id IS NULL) THEN
--
        -- �p�[�e�B�}�X�^���݃`�F�b�N
        get_hz_parties(ir_masters_rec,
                       gn_kbn_site,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
--
      IF (ir_masters_rec.c_party_id IS NULL) THEN
--
        -- �ڋq�}�X�^���݃`�F�b�N
        get_hz_cust_accounts(ir_masters_rec,
                             gn_kbn_site,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    -- �ڋq�o�^���
    IF (ir_masters_rec.proc_code = gn_proc_insert) THEN
--
      -- �p�[�e�B�}�X�^�E�ڋq�}�X�^�o�^
      create_party_account(ir_masters_rec,
                           gn_kbn_site,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
      ir_report_rec.hca_flg := 1;
--
      -- �p�[�e�B�A�h�I���}�X�^(���ړo�^)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_insert,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- �ڋq�X�V���
    ELSIF (ir_masters_rec.proc_code = gn_proc_update) THEN
--
      -- �p�[�e�B�}�X�^�X�V
      update_hz_parties(ir_masters_rec,
                        gn_kbn_upd_cust,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- �ڋq�}�X�^�X�V
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_upd_cust,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
--
      -- �p�[�e�B�A�h�I���}�X�^(���ڍX�V)
      proc_xxcmn_party(ir_masters_rec,
                       gn_proc_update,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xps_flg := 1;
--
    -- �ڋq�폜���
    ELSIF (ir_masters_rec.proc_code = gn_proc_delete) THEN
--
      -- �p�[�e�B�}�X�^�X�V
      update_hz_parties(ir_masters_rec,
                        gn_kbn_del_cust,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hps_flg := 1;
--
      -- �ڋq�}�X�^�X�V
      update_hz_cust_accounts(ir_masters_rec,
                              gn_kbn_del_cust,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hca_flg := 1;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_cust;
--
  /***********************************************************************************
   * Procedure Name   : proc_site
   * Description      : �z���攽�f�������s���܂��B
   ***********************************************************************************/
  PROCEDURE proc_site(
    ir_report_rec   IN OUT NOCOPY report_rec,   -- ���|�[�g�f�[�^
    ir_masters_rec  IN OUT NOCOPY masters_rec,  -- �`�F�b�N�Ώۃf�[�^
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_site'; -- �v���O������
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
    lv_validated_flag       hz_parties.validated_flag%TYPE;          -- �L���t���O
    lv_status               hz_cust_accounts.status%TYPE;            -- �L���X�e�[�^�X
    lb_retcd   BOOLEAN;
    ln_kbn     NUMBER;
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
    -- �o�^�ȊO
    IF ((ir_masters_rec.proc_code <> gn_proc_insert)
      AND (ir_masters_rec.proc_code <> gn_proc_s_ins)
      AND (ir_masters_rec.proc_code <> gn_proc_c_ins)) THEN
--
      -- �p�[�e�B�[�T�C�g�}�X�^�̎擾
      get_hz_party_sites(ir_masters_rec,
                         lb_retcd,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
    -- �o�^
    ELSE
-- 2008/08/25 Mod ��
/*
      IF (ir_masters_rec.party_num IS NULL) THEN
*/
      IF (ir_masters_rec.party_num = gv_def_party_num) THEN
-- 2008/08/25 Mod ��
        ln_kbn := gn_kbn_party;
      ELSE
        ln_kbn := gn_kbn_site;
      END IF;
--
      lv_validated_flag := ir_masters_rec.validated_flag;
      lv_status         := ir_masters_rec.status;
--
      -- �p�[�e�B�}�X�^���݃`�F�b�N
      get_hz_parties(ir_masters_rec,
                     ln_kbn,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      IF (lv_validated_flag IS NOT NULL) THEN
        ir_masters_rec.validated_flag := lv_validated_flag;
      END IF;
--
      IF (lv_status IS NOT NULL) THEN
        ir_masters_rec.status := lv_status;
      END IF;
    END IF;
--
    -- �o�^
    -- �o�^(���_�R�t��)
    -- �o�^(�ڋq�R�t��)
    IF ((ir_masters_rec.proc_code = gn_proc_insert)
     OR (ir_masters_rec.proc_code = gn_proc_s_ins)
     OR (ir_masters_rec.proc_code = gn_proc_c_ins)) THEN
--
      -- �p�[�e�B�T�C�g�}�X�^�o�^
      insert_hz_party_sites(ir_masters_rec,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hpss_flg := 1;
      ir_report_rec.hcas_flg := 1;
      ir_report_rec.hcsu_flg := 1;
--
      ir_report_rec.hzl_flg  := 1;           -- 2008/08/25 Add
--
      -- �p�[�e�B�T�C�g�A�h�I���}�X�^(���ړo�^)
      proc_xxcmn_party_site(ir_masters_rec,
                            gn_proc_insert,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xpss_flg := 1;
    END IF;
--
    -- �X�V
    -- �X�V(���_�R�t��)
    -- �X�V(�ڋq�R�t��)
    IF ((ir_masters_rec.proc_code = gn_proc_update)
     OR (ir_masters_rec.proc_code = gn_proc_s_upd)
     OR (ir_masters_rec.proc_code = gn_proc_c_upd)) THEN
--
      ir_masters_rec.status := gv_status_on;
--
      -- �p�[�e�B�T�C�g�}�X�^�X�V
      update_hz_party_sites(ir_masters_rec,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.hpss_flg := 1;
      ir_report_rec.hcas_flg := 1;
      ir_report_rec.hzl_flg  := 1;           -- 2008/08/25 Add
--
      -- �p�[�e�B�T�C�g�A�h�I���}�X�^(���ڍX�V)
      proc_xxcmn_party_site(ir_masters_rec,
                            gn_proc_update,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
      ir_report_rec.xpss_flg := 1;
    END IF;
--
    -- �폜
    -- �폜/�o�^(���_�R�t��)
    -- �폜/�o�^(�ڋq�R�t��)
    -- �폜(���_�R�t��)
    -- �폜(�ڋq�R�t��)
    IF ((ir_masters_rec.proc_code = gn_proc_delete)
     OR (ir_masters_rec.proc_code = gn_proc_s_del)
     OR (ir_masters_rec.proc_code = gn_proc_c_del)
     OR (ir_masters_rec.proc_code = gn_proc_ds_del)
     OR (ir_masters_rec.proc_code = gn_proc_dc_del)) THEN
--
      ir_masters_rec.status := gv_status_off;
--
      -- �p�[�e�B�T�C�g�}�X�^�X�V
      update_hz_party_sites(ir_masters_rec,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- �폜/�o�^(���_�R�t��)
      -- �폜/�o�^(�ڋq�R�t��)
      IF ((ir_masters_rec.proc_code = gn_proc_s_del)
       OR (ir_masters_rec.proc_code = gn_proc_c_del)) THEN
        -- �p�[�e�B�T�C�g�}�X�^�o�^
        insert_hz_party_sites(ir_masters_rec,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        ir_report_rec.hcsu_flg := 1;
--
        -- �p�[�e�B�T�C�g�A�h�I���}�X�^(���ړo�^)
        proc_xxcmn_party_site(ir_masters_rec,
                              gn_proc_insert,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_api_expt;
        END IF;
        ir_report_rec.xpss_flg := 1;
      END IF;
    END IF;
    ir_report_rec.hpss_flg := 1;
    ir_report_rec.hcas_flg := 1;
--
    ir_report_rec.hzl_flg  := 1;             -- 2008/08/25 Add
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_site;
--
  /***********************************************************************************
   * Procedure Name   : proc_party_main
   * Description      : ���_���f�����𐧌䂵�܂��B(A-14)
   ***********************************************************************************/
  PROCEDURE proc_party_main(
    it_party_ins        IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֓o�^����f�[�^
    it_party_upd        IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֍X�V����f�[�^
    it_party_del        IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֍폜����f�[�^
    it_party_report_tbl IN OUT NOCOPY report_tbl,     -- ���|�[�g�o�͌����z��
    in_party_ins_cnt    IN            NUMBER,         -- �o�^����(���_)
    in_party_upd_cnt    IN            NUMBER,         -- �X�V����(���_)
    in_party_del_cnt    IN            NUMBER,         -- �폜����(���_)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_party_main'; -- �v���O������
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
    ln_exec_cnt     NUMBER;
    ln_log_cnt      NUMBER;
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
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_party_ins_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_p_report_cnt-1 LOOP
        -- �o�^
        IF (it_party_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
          -- SEQ�ԍ�������
          IF (it_party_report_tbl(ln_log_cnt).seq_number =
              it_party_ins(ln_exec_cnt).seq_number) THEN
--
            -- ���_���f����(�o�^)
            proc_party(it_party_report_tbl(ln_log_cnt),
                       it_party_ins(ln_exec_cnt),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP insert_proc_loop;
--
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_party_upd_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_p_report_cnt-1 LOOP
        -- �X�V
        IF (it_party_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
          -- SEQ�ԍ�������
          IF (it_party_report_tbl(ln_log_cnt).seq_number =
              it_party_upd(ln_exec_cnt).seq_number) THEN
--
            -- ���_���f����(�X�V)
            proc_party(it_party_report_tbl(ln_log_cnt),
                       it_party_upd(ln_exec_cnt),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP update_proc_loop;
--
    <<delete_proc_loop>>
    FOR ln_exec_cnt IN 0..in_party_del_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_p_report_cnt-1 LOOP
        -- �폜
        IF (it_party_report_tbl(ln_log_cnt).proc_code = gn_proc_delete) THEN
          -- SEQ�ԍ�������
          IF (it_party_report_tbl(ln_log_cnt).seq_number =
              it_party_del(ln_exec_cnt).seq_number) THEN
--
            -- ���_���f����(�폜)
            proc_party(it_party_report_tbl(ln_log_cnt),
                       it_party_del(ln_exec_cnt),
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP delete_proc_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_party_main;
--
  /***********************************************************************************
   * Procedure Name   : proc_cust_main
   * Description      : �ڋq���f�����𐧌䂵�܂��B(A-15)
   ***********************************************************************************/
  PROCEDURE proc_cust_main(
    it_cust_ins         IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֓o�^����f�[�^
    it_cust_upd         IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֍X�V����f�[�^
    it_cust_report_tbl  IN OUT NOCOPY report_tbl,     -- ���|�[�g�o�͌����z��
    in_cust_ins_cnt     IN            NUMBER,         -- �o�^����(�ڋq)
    in_cust_upd_cnt     IN            NUMBER,         -- �X�V����(�ڋq)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_cust_main'; -- �v���O������
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
    ln_exec_cnt     NUMBER;
    ln_log_cnt      NUMBER;
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
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_cust_ins_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_c_report_cnt-1 LOOP
        -- �o�^
        IF (it_cust_report_tbl(ln_log_cnt).proc_code = gn_proc_insert) THEN
          -- SEQ�ԍ�������
          IF (it_cust_report_tbl(ln_log_cnt).seq_number =
              it_cust_ins(ln_exec_cnt).seq_number) THEN
--
            -- �ڋq���f����(�o�^)
            proc_cust(it_cust_report_tbl(ln_log_cnt),
                      it_cust_ins(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP insert_proc_loop;
--
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_cust_upd_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_c_report_cnt-1 LOOP
        -- �X�V
        IF (it_cust_report_tbl(ln_log_cnt).proc_code = gn_proc_update) THEN
          -- SEQ�ԍ�������
          IF (it_cust_report_tbl(ln_log_cnt).seq_number =
              it_cust_upd(ln_exec_cnt).seq_number) THEN
--
            -- �ڋq���f����(�X�V)
            proc_cust(it_cust_report_tbl(ln_log_cnt),
                      it_cust_upd(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP update_proc_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_cust_main;
--
  /***********************************************************************************
   * Procedure Name   : proc_site_main
   * Description      : �z���攽�f�����𐧌䂵�܂��B(A-16)
   ***********************************************************************************/
  PROCEDURE proc_site_main(
    it_site_ins         IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֓o�^����f�[�^
    it_site_upd         IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֍X�V����f�[�^
    it_site_del         IN OUT NOCOPY masters_tbl,    -- �e�}�X�^�֍폜����f�[�^
    it_site_report_tbl  IN OUT NOCOPY report_tbl,     -- ���|�[�g�o�͌����z��
    in_site_ins_cnt     IN            NUMBER,         -- �o�^����(�z����)
    in_site_upd_cnt     IN            NUMBER,         -- �X�V����(�z����)
    in_site_del_cnt     IN            NUMBER,         -- �폜����(�z����)
    ov_errbuf              OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_site_main'; -- �v���O������
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
    ln_exec_cnt     NUMBER;
    ln_log_cnt      NUMBER;
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
    <<insert_proc_loop>>
    FOR ln_exec_cnt IN 0..in_site_ins_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_s_report_cnt-1 LOOP
        -- �o�^
        IF ((it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_insert)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_s_ins)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_c_ins)) THEN
          -- SEQ�ԍ�������
          IF (it_site_report_tbl(ln_log_cnt).seq_number =
              it_site_ins(ln_exec_cnt).seq_number) THEN
--
            -- �z���攽�f����(�o�^)
            proc_site(it_site_report_tbl(ln_log_cnt),
                      it_site_ins(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP insert_proc_loop;
--
    <<update_proc_loop>>
    FOR ln_exec_cnt IN 0..in_site_upd_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_s_report_cnt-1 LOOP
        -- �X�V
        IF ((it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_update)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_s_upd)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_c_upd)) THEN
          -- SEQ�ԍ�������
          IF (it_site_report_tbl(ln_log_cnt).seq_number =
              it_site_upd(ln_exec_cnt).seq_number) THEN
--
            -- �z���攽�f����(�X�V)
            proc_site(it_site_report_tbl(ln_log_cnt),
                      it_site_upd(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP update_proc_loop;
--
    <<delete_proc_loop>>
    FOR ln_exec_cnt IN 0..in_site_del_cnt-1 LOOP
      <<log_loop>>
      FOR ln_log_cnt IN 0..gn_s_report_cnt-1 LOOP
        -- �폜
        IF ((it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_delete)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_s_del)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_c_del)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_ds_del)
         OR (it_site_report_tbl(ln_log_cnt).proc_code = gn_proc_dc_del)) THEN
          -- SEQ�ԍ�������
          IF (it_site_report_tbl(ln_log_cnt).seq_number =
              it_site_del(ln_exec_cnt).seq_number) THEN
--
            -- �z���攽�f����(�폜)
            proc_site(it_site_report_tbl(ln_log_cnt),
                      it_site_del(ln_exec_cnt),
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE global_api_expt;
            END IF;
            EXIT log_loop;
          END IF;
        END IF;
      END LOOP log_loop;
    END LOOP delete_proc_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
  END proc_site_main;
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
  EXCEPTION
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
   * Description      : �I���������s���܂��B(A-17)
   ***********************************************************************************/
  PROCEDURE term_proc(
    it_party_report_tbl IN            report_tbl,   -- �o�͗p�e�[�u��(���_)
    it_cust_report_tbl  IN            report_tbl,   -- �o�͗p�e�[�u��(�ڋq)
    it_site_report_tbl  IN            report_tbl,   -- �o�͗p�e�[�u��(�z����)
    ov_errbuf              OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���O�o��
    disp_report(it_party_report_tbl,
                it_cust_report_tbl,
                it_site_report_tbl,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �J�[�\�����J���Ă����
    IF (gc_hca_party_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_hca_party_cur;
    END IF;
    -- �J�[�\�����J���Ă����
    IF (gc_hca_site_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_hca_site_cur;
    END IF;
    -- �J�[�\�����J���Ă����
    IF (gc_hp_party_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_hp_party_cur;
    END IF;
    -- �J�[�\�����J���Ă����
    IF (gc_hp_site_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_hp_site_cur;
    END IF;
    -- �J�[�\�����J���Ă����
    IF (gc_xp_party_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_xp_party_cur;
    END IF;
    -- �J�[�\�����J���Ă����
    IF (gc_xp_site_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_xp_site_cur;
    END IF;
    -- �J�[�\�����J���Ă����
    IF (gc_hps_site_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_hps_site_cur;
    END IF;
    -- �J�[�\�����J���Ă����
    IF (gc_xps_site_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
      CLOSE gc_xps_site_cur;
    END IF;
--
    -- �f�[�^�폜(���_�C���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_party_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_018,
                                            gv_tkn_table, gv_xxcmn_party_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- �f�[�^�폜(�z����C���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.del_all_data(gv_msg_kbn, gv_site_if_name);
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,   gv_msg_80a_018,
                                            gv_tkn_table, gv_xxcmn_site_if_name);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
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
    lr_masters_rec      masters_rec;        -- �����Ώۃf�[�^�i�[���R�[�h
--
    -- ===============================
    -- ���_�p
    -- ===============================
    lt_party_ins        masters_tbl;        -- �e�}�X�^�֓o�^����f�[�^
    lt_party_upd        masters_tbl;        -- �e�}�X�^�֍X�V����f�[�^
    lt_party_del        masters_tbl;        -- �e�}�X�^�֍폜����f�[�^
    lt_party_report_tbl report_tbl;         -- ���|�[�g�o�͌����z��
    ln_party_ins_cnt    NUMBER;             -- �o�^����(���_)
    ln_party_upd_cnt    NUMBER;             -- �X�V����(���_)
    ln_party_del_cnt    NUMBER;             -- �폜����(���_)
    lr_party_sts_rec    status_rec;         -- �����󋵊i�[���R�[�h(���_�p)
    -- ===============================
    -- �ڋq�p
    -- ===============================
    lt_cust_ins         masters_tbl;        -- �e�}�X�^�֓o�^����f�[�^
    lt_cust_upd         masters_tbl;        -- �e�}�X�^�֍X�V����f�[�^
    lt_cust_report_tbl  report_tbl;         -- ���|�[�g�o�͌����z��
    ln_cust_ins_cnt     NUMBER;             -- �o�^����(�ڋq)
    ln_cust_upd_cnt     NUMBER;             -- �X�V����(�ڋq)
    lr_cust_sts_rec     status_rec;         -- �����󋵊i�[���R�[�h(�ڋq�p)
    -- ===============================
    -- �z����p
    -- ===============================
    lt_site_ins         masters_tbl;        -- �e�}�X�^�֓o�^����f�[�^
    lt_site_upd         masters_tbl;        -- �e�}�X�^�֍X�V����f�[�^
    lt_site_del         masters_tbl;        -- �e�}�X�^�֍폜����f�[�^
    lt_site_report_tbl  report_tbl;         -- ���|�[�g�o�͌����z��
    ln_site_ins_cnt     NUMBER;             -- �o�^����(�z����)
    ln_site_upd_cnt     NUMBER;             -- �X�V����(�z����)
    ln_site_del_cnt     NUMBER;             -- �폜����(�z����)
    lr_site_sts_rec     status_rec;         -- �����󋵊i�[���R�[�h(�z����p)
--
    lb_retcd        BOOLEAN;         -- ��������
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���_�C���^�t�F�[�X
    CURSOR party_if_cur
    IS
      SELECT xpi.seq_number,                           --SEQ�ԍ�
             xpi.proc_code,                            --�X�V�敪
             xpi.base_code,                            --���_�R�[�h
             xpi.party_name,                           --���_���E������
             xpi.party_short_name,                     --���_���E����
             xpi.party_name_alt,                       --���_���E�J�i
             xpi.address,                              --�Z��
             xpi.zip,                                  --�X�֔ԍ�
             xpi.phone,                                --�d�b�ԍ�
             xpi.fax,                                  --FAX�ԍ�
             xpi.old_division_code,                    --���E�{���R�[�h
             xpi.new_division_code,                    --�V�E�{���R�[�h
             xpi.division_start_date,                  --�K�p�J�n��(�{���R�[�h)
             xpi.location_rel_code,                    --���_���їL���敪
             xpi.ship_mng_code,                        --�o�ɊǗ����敪
             xpi.district_code,                        --�n�於(�{���R�[�h�p)
             xpi.warehouse_code,                       --�q�֑Ώۉۋ敪
             xpi.terminal_code,                        --�[���L���敪
             xpi.zip2,                                 --�X�֔ԍ�2
             xpi.spare                                 --�\��
      FROM   xxcmn_party_if xpi
      ORDER BY seq_number;
--
    lr_party_if_rec party_if_cur%ROWTYPE;
--
    -- �z����C���^�t�F�[�X
    CURSOR site_if_cur
    IS
      SELECT xsi.seq_number,                           --SEQ�ԍ�
             xsi.proc_code,                            --�X�V�敪
             xsi.ship_to_code,                         --�z����R�[�h
             xsi.base_code,                            --���_�R�[�h
             xsi.party_site_name1,                     --�z���於��1
             xsi.party_site_name2,                     --�z���於��2
             xsi.party_site_addr1,                     --�z����Z��1
             xsi.party_site_addr2,                     --�z����Z��2
             xsi.phone,                                --�d�b�ԍ�
             xsi.fax,                                  --FAX�ԍ�
             xsi.zip,                                  --�X�֔ԍ�
             xsi.party_num,                            --�ڋq�R�[�h
             xsi.zip2,                                 --�X�֔ԍ�2
             xsi.customer_name1,                       --�ڋq�E����1
             xsi.customer_name2,                       --�ڋq�E����2
             xsi.sale_base_code,                       --�������㋒�_�R�[�h
             xsi.res_sale_base_code,                   --�\��(����)���㋒�_�R�[�h
             xsi.chain_store,                          --����`�F�[���X
             xsi.chain_store_name,                     --����`�F�[���X��
             xsi.cal_cust_app_flg,                     --���~�q�\���t���O
             xsi.direct_ship_code,                     --�����敪
             xsi.shift_judg_flg                        --�ڍs����t���O
      FROM   xxcmn_site_if xsi
      ORDER BY seq_number;
--
    lr_site_if_rec site_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
--
    gn_p_target_cnt := 0;
    gn_p_normal_cnt := 0;
    gn_p_error_cnt  := 0;
    gn_p_warn_cnt   := 0;
    gn_p_report_cnt := 0;
--
    gn_s_target_cnt := 0;
    gn_s_normal_cnt := 0;
    gn_s_error_cnt  := 0;
    gn_s_warn_cnt   := 0;
    gn_s_report_cnt := 0;
--
    gn_c_target_cnt := 0;
    gn_c_normal_cnt := 0;
    gn_c_error_cnt  := 0;
    gn_c_warn_cnt   := 0;
    gn_c_report_cnt := 0;
--
    ln_party_ins_cnt := 0;
    ln_party_upd_cnt := 0;
    ln_party_del_cnt := 0;
    ln_site_ins_cnt  := 0;
    ln_site_upd_cnt  := 0;
    ln_site_del_cnt  := 0;
    ln_cust_ins_cnt  := 0;
    ln_cust_upd_cnt  := 0;
--
    gn_created_by              := FND_GLOBAL.USER_ID;
    gd_creation_date           := SYSDATE;
    gn_last_updated_by         := FND_GLOBAL.USER_ID;
    gd_last_update_date        := SYSDATE;
    gn_last_update_login       := FND_GLOBAL.LOGIN_ID;
    gn_request_id              := FND_GLOBAL.CONC_REQUEST_ID;
--    gn_program_application_id  := FND_GLOBAL.QUEUE_APPL_ID;
    gn_program_application_id  := FND_GLOBAL.PROG_APPL_ID;
    gn_program_id              := FND_GLOBAL.CONC_PROGRAM_ID;
    gd_program_update_date     := SYSDATE;
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
    -- �t�@�C�����x���̃X�e�[�^�X��������(���_)
    init_status(lr_party_sts_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- ���_�C���^�t�F�[�X�擾����(A-1)
    -- ===============================
    OPEN party_if_cur;
--
    <<party_if_loop>>
    LOOP
      FETCH party_if_cur INTO lr_party_if_rec;
      EXIT WHEN party_if_cur%NOTFOUND;
--
      gn_p_target_cnt := gn_p_target_cnt + 1; -- ���������J�E���g�A�b�v(���_)
--
      -- �s���x���̃X�e�[�^�X��������
      init_row_status(lr_party_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- �擾�����l�����R�[�h�ɃR�s�[
      lr_masters_rec.tbl_kbn             := gn_kbn_party;
      lr_masters_rec.seq_number          := lr_party_if_rec.seq_number;
      lr_masters_rec.proc_code           := lr_party_if_rec.proc_code;
      lr_masters_rec.base_code           := lr_party_if_rec.base_code;
      lr_masters_rec.party_name          := lr_party_if_rec.party_name;
      lr_masters_rec.party_short_name    := lr_party_if_rec.party_short_name;
      lr_masters_rec.party_name_alt      := lr_party_if_rec.party_name_alt;
      lr_masters_rec.address             := lr_party_if_rec.address;
      lr_masters_rec.zip                 := lr_party_if_rec.zip;
      lr_masters_rec.phone               := lr_party_if_rec.phone;
      lr_masters_rec.fax                 := lr_party_if_rec.fax;
      lr_masters_rec.old_division_code   := lr_party_if_rec.old_division_code;
      lr_masters_rec.new_division_code   := lr_party_if_rec.new_division_code;
      lr_masters_rec.division_start_date := lr_party_if_rec.division_start_date;
      lr_masters_rec.location_rel_code   := lr_party_if_rec.location_rel_code;
      lr_masters_rec.ship_mng_code       := lr_party_if_rec.ship_mng_code;
      lr_masters_rec.district_code       := lr_party_if_rec.district_code;
      lr_masters_rec.warehouse_code      := lr_party_if_rec.warehouse_code;
      lr_masters_rec.terminal_code       := lr_party_if_rec.terminal_code;
      lr_masters_rec.zip2                := lr_party_if_rec.zip2;
      lr_masters_rec.spare               := lr_party_if_rec.spare;
--
      -- �����̏�����
      lr_masters_rec.row_o_ins_cnt       := 0;
      lr_masters_rec.row_o_upd_cnt       := 0;
      lr_masters_rec.row_o_del_cnt       := 0;
      lr_masters_rec.row_z_ins_cnt       := 0;
      lr_masters_rec.row_z_upd_cnt       := 0;
      lr_masters_rec.row_z_del_cnt       := 0;
--
      -- �X�V�敪�`�F�b�N(�o�^�E�X�V�E�폜)
      check_proc_code(lr_masters_rec.proc_code,
                      lr_party_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
--
        -- �ȑO�̏󋵂̎擾
        get_xxcmn_party_if(lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
--
        -- ���_�R�[�h�`�F�b�N(A-2)
        check_base_code(lr_party_sts_rec,
                        lr_masters_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
--
        -- ���_�o�^���i�[(A-3)
        IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
          lt_party_ins(ln_party_ins_cnt) := lr_masters_rec;
          ln_party_ins_cnt := ln_party_ins_cnt + 1;
--
        -- ���_�X�V���i�[(A-4)
        ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
          lt_party_upd(ln_party_upd_cnt) := lr_masters_rec;
          ln_party_upd_cnt := ln_party_upd_cnt + 1;
--
        -- ���_�폜���i�[(A-5)
        ELSIF (lr_masters_rec.proc_code = gn_proc_delete) THEN
          lt_party_del(ln_party_del_cnt) := lr_masters_rec;
          ln_party_del_cnt := ln_party_del_cnt + 1;
        END IF;
      END IF;
--
      -- ���팏�����J�E���g�A�b�v
      IF (is_row_status_nomal(lr_party_sts_rec)) THEN
        gn_p_normal_cnt := gn_p_normal_cnt + 1;
--
      ELSE
--
        -- �x���������J�E���g�A�b�v
        IF (is_row_status_warn(lr_party_sts_rec)) THEN
          gn_p_warn_cnt := gn_p_warn_cnt + 1;
--
        -- �ُ팏�����J�E���g�A�b�v
        ELSE
          gn_p_error_cnt := gn_p_error_cnt +1;
        END IF;
      END IF;
--
      -- ���O�o�͗p�f�[�^�̊i�[(���_)
      add_p_report(lr_party_sts_rec,
                   lr_masters_rec,
                   lt_party_report_tbl,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP party_if_loop;
--
    CLOSE party_if_cur;
--
    -- �t�@�C�����x���̃X�e�[�^�X��������(�z����)
    init_status(lr_site_sts_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- �t�@�C�����x���̃X�e�[�^�X��������(�ڋq)
    init_status(lr_cust_sts_rec,
                lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- �z����C���^�t�F�[�X�擾����(A-6)
    -- ===============================
    OPEN site_if_cur;
--
    <<site_if_loop>>
    LOOP
      FETCH site_if_cur INTO lr_site_if_rec;
      EXIT WHEN site_if_cur%NOTFOUND;
--
      gn_s_target_cnt := gn_s_target_cnt + 1; -- ���������J�E���g�A�b�v(�z����)
      gn_c_target_cnt := gn_c_target_cnt + 1; -- ���������J�E���g�A�b�v(�ڋq)
--
      -- �s���x���̃X�e�[�^�X��������
      init_row_status(lr_cust_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      -- �擾�����l�����R�[�h�ɃR�s�[
      lr_masters_rec.tbl_kbn            := gn_kbn_site;
      lr_masters_rec.seq_number         := lr_site_if_rec.seq_number;
      lr_masters_rec.proc_code          := lr_site_if_rec.proc_code;
      lr_masters_rec.k_proc_code        := lr_site_if_rec.proc_code;
      lr_masters_rec.ship_to_code       := lr_site_if_rec.ship_to_code;
      lr_masters_rec.base_code          := lr_site_if_rec.base_code;
      lr_masters_rec.party_site_name1   := lr_site_if_rec.party_site_name1;
      lr_masters_rec.party_site_name2   := lr_site_if_rec.party_site_name2;
      lr_masters_rec.party_site_addr1   := lr_site_if_rec.party_site_addr1;
      lr_masters_rec.party_site_addr2   := lr_site_if_rec.party_site_addr2;
      lr_masters_rec.phone              := lr_site_if_rec.phone;
      lr_masters_rec.fax                := lr_site_if_rec.fax;
      lr_masters_rec.zip                := lr_site_if_rec.zip;
      lr_masters_rec.party_num          := lr_site_if_rec.party_num;
      lr_masters_rec.zip2               := lr_site_if_rec.zip2;
      lr_masters_rec.customer_name1     := lr_site_if_rec.customer_name1;
      lr_masters_rec.customer_name2     := lr_site_if_rec.customer_name2;
      lr_masters_rec.sale_base_code     := lr_site_if_rec.sale_base_code;
      lr_masters_rec.res_sale_base_code := lr_site_if_rec.res_sale_base_code;
      lr_masters_rec.chain_store        := lr_site_if_rec.chain_store;
      lr_masters_rec.chain_store_name   := lr_site_if_rec.chain_store_name;
      lr_masters_rec.cal_cust_app_flg   := lr_site_if_rec.cal_cust_app_flg;
      lr_masters_rec.direct_ship_code   := lr_site_if_rec.direct_ship_code;
      lr_masters_rec.shift_judg_flg     := lr_site_if_rec.shift_judg_flg;
--
      -- �����̏�����
      lr_masters_rec.row_c_ins_cnt      := 0;
      lr_masters_rec.row_c_upd_cnt      := 0;
      lr_masters_rec.row_c_del_cnt      := 0;
      lr_masters_rec.row_s_ins_cnt      := 0;
      lr_masters_rec.row_s_upd_cnt      := 0;
      lr_masters_rec.row_s_del_cnt      := 0;
      lr_masters_rec.row_n_ins_cnt      := 0;
      lr_masters_rec.row_n_upd_cnt      := 0;
      lr_masters_rec.row_n_del_cnt      := 0;
      lr_masters_rec.row_m_ins_cnt      := 0;
      lr_masters_rec.row_m_upd_cnt      := 0;
      lr_masters_rec.row_m_del_cnt      := 0;
--
      -- �ȑO�̏󋵂̎擾
      get_xxcmn_site_if(lr_masters_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
-- 2008/10/01 v1.10 UPDATE START
/*
--2008/08/08 Add ��
      -- �ڋq�R�[�h���͂���
-- 2008/08/25 Mod ��
/*
      IF (lr_masters_rec.party_num IS NOT NULL) THEN
*//*
      IF (lr_masters_rec.party_num <> gv_def_party_num) THEN
-- 2008/08/25 Mod ��
--2008/08/08 Add ��
*/
      -- �ڋq�R�[�h���͂���ŁA�폜���R�[�h�łȂ��ꍇ
      IF (
           (lr_masters_rec.party_num <> gv_def_party_num)
             AND (lr_masters_rec.proc_code <> gn_proc_delete)
         ) THEN
-- 2008/10/01 v1.10 UPDATE END
        -- ===============================
        -- �ڋq�f�[�^�����J�n
        -- ===============================
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
--
          -- �ڋq�R�[�h�`�F�b�N(A-7)
          check_party_num(lr_cust_sts_rec,
                          lr_masters_rec,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
        END IF;
--
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
--
          -- �X�V�敪�`�F�b�N(�o�^�E�X�V�E�폜)
          check_proc_code(lr_masters_rec.k_proc_code,
                          lr_cust_sts_rec,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
        END IF;
--
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
--
          -- �ڋq�o�^���i�[(A-8)
          IF (lr_masters_rec.proc_code = gn_proc_insert) THEN
            lt_cust_ins(ln_cust_ins_cnt) := lr_masters_rec;
            ln_cust_ins_cnt := ln_cust_ins_cnt + 1;
--
          -- �ڋq�X�V���i�[(A-9)
          ELSIF (lr_masters_rec.proc_code = gn_proc_update) THEN
            lt_cust_upd(ln_cust_upd_cnt) := lr_masters_rec;
            ln_cust_upd_cnt := ln_cust_upd_cnt + 1;
          END IF;
        END IF;
--
        -- ���팏�����J�E���g�A�b�v
        IF (is_row_status_nomal(lr_cust_sts_rec)) THEN
          gn_c_normal_cnt := gn_c_normal_cnt + 1;
--
        ELSE
          -- �x���������J�E���g�A�b�v
          IF (is_row_status_warn(lr_cust_sts_rec)) THEN
            IF ((lr_masters_rec.k_proc_code = gn_proc_insert)
-- 2008/08/25 Mod ��
/*
             AND (lr_masters_rec.party_num IS NOT NULL)) THEN
*/
             AND (lr_masters_rec.party_num <> gv_def_party_num)) THEN
-- 2008/08/25 Mod ��
              lr_cust_sts_rec.file_level_status := gn_data_status_nomal;
              gn_c_normal_cnt := gn_c_normal_cnt + 1;
            ELSE
              gn_c_warn_cnt := gn_c_warn_cnt + 1;
            END IF;
--
          -- �ُ팏�����J�E���g�A�b�v
          ELSE
            gn_c_error_cnt := gn_c_error_cnt +1;
          END IF;
        END IF;
--
        -- ���O�ɐݒ肵�Ȃ�
        IF ((is_row_status_warn(lr_cust_sts_rec))
        AND (lr_cust_sts_rec.row_err_message IS NULL)) THEN
          NULL;
        ELSE
          -- ���O�o�͗p�f�[�^�̊i�[(�ڋq)
          add_c_report(lr_cust_sts_rec,
                       lr_masters_rec,
                       lt_cust_report_tbl,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE check_sub_main_expt;
          END IF;
        END IF;
--2008/08/08 Add ��
      END IF;
--2008/08/08 Add ��
--
      -- ===============================
      -- �z����f�[�^�����J�n
      -- ===============================
--
      -- �s���x���̃X�e�[�^�X��������
      init_row_status(lr_site_sts_rec,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
--
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
--
        -- �z����R�[�h�`�F�b�N(A-10)
        check_ship_to_code(lr_site_sts_rec,
                           lr_masters_rec,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
--
        -- �X�V�敪�`�F�b�N(�o�^�E�X�V�E�폜)
        check_proc_code(lr_masters_rec.k_proc_code,
                        lr_site_sts_rec,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
--
        -- �z����o�^���i�[(A-11)
        IF ((lr_masters_rec.proc_code = gn_proc_insert)
         OR (lr_masters_rec.proc_code = gn_proc_s_ins)
         OR (lr_masters_rec.proc_code = gn_proc_c_ins)) THEN
          lt_site_ins(ln_site_ins_cnt) := lr_masters_rec;
          ln_site_ins_cnt := ln_site_ins_cnt + 1;
        END IF;
--
        -- �z����X�V���i�[(A-12)
        IF ((lr_masters_rec.proc_code = gn_proc_update)
         OR (lr_masters_rec.proc_code = gn_proc_s_upd)
         OR (lr_masters_rec.proc_code = gn_proc_c_upd)) THEN
          lt_site_upd(ln_site_upd_cnt) := lr_masters_rec;
          ln_site_upd_cnt := ln_site_upd_cnt + 1;
        END IF;
--
        -- �z����폜���i�[(A-13)
        IF ((lr_masters_rec.proc_code = gn_proc_delete)
         OR (lr_masters_rec.proc_code = gn_proc_s_del)
         OR (lr_masters_rec.proc_code = gn_proc_c_del)
         OR (lr_masters_rec.proc_code = gn_proc_ds_del)
         OR (lr_masters_rec.proc_code = gn_proc_dc_del)) THEN
          lt_site_del(ln_site_del_cnt) := lr_masters_rec;
          ln_site_del_cnt := ln_site_del_cnt + 1;
        END IF;
      END IF;
--
      -- ���팏�����J�E���g�A�b�v
      IF (is_row_status_nomal(lr_site_sts_rec)) THEN
        gn_s_normal_cnt := gn_s_normal_cnt + 1;
--
      ELSE
        -- �x���������J�E���g�A�b�v
        IF (is_row_status_warn(lr_site_sts_rec)) THEN
          gn_s_warn_cnt := gn_s_warn_cnt + 1;
--
        -- �ُ팏�����J�E���g�A�b�v
        ELSE
          gn_s_error_cnt := gn_s_error_cnt +1;
        END IF;
      END IF;
--
      -- ���O�o�͗p�f�[�^�̊i�[(�z����)
      add_s_report(lr_site_sts_rec,
                   lr_masters_rec,
                   lt_site_report_tbl,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
    END LOOP site_if_loop;
--
    CLOSE site_if_cur;
--
    -- ===============================
    -- �G���[�`�F�b�N
    -- ===============================
--
    -- �f�[�^�̔��f(�G���[�Ȃ�)
/* 2008/08/08 Mod ��
    IF ((is_file_status_nomal(lr_party_sts_rec))
    AND (is_file_status_nomal(lr_cust_sts_rec))
    AND (is_file_status_nomal(lr_site_sts_rec))) THEN
2008/08/08 Mod �� */
--
    IF (is_file_status_nomal(lr_party_sts_rec)) THEN
      -- ===============================
      -- ���_���f����(A-14)
      -- ===============================
      proc_party_main(lt_party_ins,
                      lt_party_upd,
                      lt_party_del,
                      lt_party_report_tbl,
                      ln_party_ins_cnt,
                      ln_party_upd_cnt,
                      ln_party_del_cnt,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF (is_file_status_nomal(lr_cust_sts_rec)) THEN
      -- ===============================
      -- �ڋq���f����(A-15)
      -- ===============================
      proc_cust_main(lt_cust_ins,
                     lt_cust_upd,
                     lt_cust_report_tbl,
                     ln_cust_ins_cnt,
                     ln_cust_upd_cnt,
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
    END IF;
--
    IF ((is_file_status_nomal(lr_site_sts_rec))
    AND (is_file_status_nomal(lr_cust_sts_rec))) THEN
      -- ===============================
      -- �z���攽�f����(A-16)
      -- ===============================
      proc_site_main(lt_site_ins,
                     lt_site_upd,
                     lt_site_del,
                     lt_site_report_tbl,
                     ln_site_ins_cnt,
                     ln_site_upd_cnt,
                     ln_site_del_cnt,
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
    -- �I������(A-17)
    -- ===============================
    term_proc(lt_party_report_tbl,
              lt_cust_report_tbl,
              lt_site_report_tbl,
              lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    gn_target_cnt := gn_p_target_cnt+gn_s_target_cnt;
    gn_target_cnt := gn_target_cnt+gn_c_target_cnt;
--
    gn_normal_cnt := gn_p_normal_cnt+gn_s_normal_cnt;
    gn_normal_cnt := gn_normal_cnt+gn_c_normal_cnt;
--
    gn_error_cnt  := gn_p_error_cnt+gn_s_error_cnt;
    gn_error_cnt  := gn_error_cnt+gn_c_error_cnt;
--
    gn_warn_cnt   := gn_p_warn_cnt+gn_s_warn_cnt;
    gn_warn_cnt   := gn_warn_cnt+gn_c_warn_cnt;
--
    -- 2008/07/07 Add ��
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn,
                                             gv_msg_80a_022);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
    END IF;
    -- 2008/07/07 Add ��
--
    -- �G���[�A���[�j���O�f�[�^�L��̏ꍇ�̓��[�j���O�I������B
    IF ((gn_error_cnt + gn_warn_cnt) > 0) THEN
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
      IF (party_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE party_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (site_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE site_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hps_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xps_site_cur;
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
      IF (party_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE party_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (site_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE site_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hps_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xps_site_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (party_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE party_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (site_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE site_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hps_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xps_site_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (party_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE party_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (site_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE site_if_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hca_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hca_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_party_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_party_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xp_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xp_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_hps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_hps_site_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_xps_site_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_xps_site_cur;
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
    AND    fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80a_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80a_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_80a_021,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���擾
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_003);
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
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
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_020);
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_010, gv_tkn_cnt,
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
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_80a_011,
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
END xxcmn800001c;
/
