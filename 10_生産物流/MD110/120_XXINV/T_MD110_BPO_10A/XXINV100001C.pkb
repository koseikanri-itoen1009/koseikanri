CREATE OR REPLACE PACKAGE BODY XXINV100001C
AS
--
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100001C(body)
 * Description      : ���Y����(�v��)
 * MD.050           : �v��E�ړ��E�݌ɁE�̔��v��/����v�� T_MD050_BPO100
 * MD.070           : �v��E�ړ��E�݌ɁE�̔��v��/����v�� T_MD070_BPO10A
 * Version          : 1.19
 *
 * Program List
 * -------------------------------- ----------------------------------------------------------
 *  Name                            Description
 * -------------------------------- ----------------------------------------------------------
 *  if_data_disp                    �C���^�[�t�F�[�X�f�[�^�s���������ʃ��|�[�g�ɕ\������
 *  parameter_check_forecast        A-1-2-1 Forecast�`�F�b�N
 *  parameter_check_yyyymm          A-1-2-2 �N���`�F�b�N
 *  parameter_check_forecast_year   A-1-2-3 �N�x�`�F�b�N
 *  parameter_check_version         A-1-2-4 ����`�F�b�N
 *  parameter_check_forecast_date   A-1-2-5 �J�n���t�E�I�����t�`�F�b�N
 *  parameter_check_item_no         A-1-2-6 �i�ڃ`�F�b�N
 *  parameter_check_subinventory    A-1-2-7 �o�ɑq�Ƀ`�F�b�N
 *  parameter_check_account_number  A-1-2-8 ���_�`�F�b�N
 *  parameter_check_dept_code       A-1-2-9 �捞�����`�F�b�N
 *  get_profile_start_day           A-1-3   �v���t�@�C�����N�x�J�n�������擾
 *  get_start_end_day               A-1-4   �Ώ۔N�x�J�n���E�Ώ۔N�x�I�����̎擾
 *  get_keikaku_start_end_day       A-1-5   �v�揤�i�ΏۊJ�n�E�I���N�����擾
 *  get_dept_inf                    A-1-6   �������̎擾
 *  if_data_null_check              A-*-0   �C���^�[�t�F�[�X�f�[�^���ڕK�{�`�F�b�N
 *  get_hikitori_if_data            A-2-1   ����v��C���^�[�t�F�[�X�f�[�^���o
 *  get_hanbai_if_data              A-3-1   �̔��v��C���^�[�t�F�[�X�f�[�^���o
 *  get_keikaku_if_data             A-4-1   �v�揤�i�C���^�[�t�F�[�X�f�[�^���o
 *  get_seigen_a_if_data            A-5-1   �o�א�����A�C���^�[�t�F�[�X�f�[�^���o
 *  get_seigen_b_if_data            A-6-1   �o�א�����B�C���^�[�t�F�[�X�f�[�^���o
 *  shipped_date_start_check        1.      �o�ɑq�ɂ̓K�p���ƊJ�n���t�`�F�b�N
 *  shipped_class_check             2.      �o�ɑq�ɂ̏o�ɊǗ����敪�`�F�b�N
 *  base_code_exist_check           3.      ���_�̑��݃`�F�b�N
 *  item_abolition_code_check       4.      �i�ڂ̔p�~�敪�`�F�b�N
 *  item_class_check                5.      �i�ڂ̕i�ڋ敪�`�F�b�N
 *  item_date_start_check           6.      �i�ڂ̓K�p���ƊJ�n���t�`�F�b�N
 *  item_date_year_check            7.      �i�ڂ̓K�p���ƔN�x�x���`�F�b�N
 *  item_standard_year_check        8.      �i�ڂ̕W�������K�p���ƔN�x�x���`�F�b�N
 *  item_forecast_check             9.10.   �i�ڂ̕����\���\�v�揤�i�Ώەi�ڂƓ��t�`�F�b�N
 *  item_not_regist_check           11.     �i�ڂ̕����\���\���o�^�̌x���`�F�b�N
 *  date_month_check                12.     ���t�̑Ώی��`�F�b�N
 *  date_year_check                 13.     ���t�̑Ώ۔N�`�F�b�N
 *  date_past_check                 14.     ���t�̉ߋ��`�F�b�N
 *  start_date_range_check          15.     �J�n���t��1�����ȓ��`�F�b�N
 *  date_start_end_check            16.     ���t�̊J�n���I���`�F�b�N
 *  inventory_date_check            17.     �o�ɑq�ɋ��_�i�ړ��t�ł̏d���`�F�b�N
 *  base_code_date_check            18.     ���_�i�ړ��t�ł̏d���`�F�b�N
 *  quantity_num_check              19.     ���ʂ̃}�C�i�X���l�`�F�b�N
 *  price_num_check                 20.     ���z�̃}�C�i�X���l�x���`�F�b�N
 *  hikitori_data_check             A-2-2   ����v�撊�o�f�[�^�`�F�b�N
 *  hanbai_data_check               A-3-2   �̔��v�撊�o�f�[�^�`�F�b�N
 *  keikaku_data_check              A-4-2   �v�揤�i���o�f�[�^�`�F�b�N
 *  seigen_a_data_check             A-5-2   �o�א�����A���o�f�[�^�`�F�b�N
 *  seigen_b_data_check             A-6-2   �o�א�����B���o�f�[�^�`�F�b�N
 *  get_f_degi_hikitori             A-2-3   ����v��Forecast�����o
 *  get_f_degi_hanbai               A-3-3   �̔��v��Forecast�����o
 *  get_f_degi_keikaku              A-4-3   �v�揤�iForecast�����o
 *  get_f_degi_seigen_a             A-5-3   �o�א�����AForecast�����o
 *  get_f_degi_seigen_b             A-6-3   �o�א�����BForecast�����o
 *  get_f_dates_hikitori            A-2-4   ����v��Forecast���t���o
 *  get_f_dates_hanbai              A-3-4   �̔��v��Forecast���t���o
 *  get_f_dates_keikaku             A-4-4   �v�揤�iForecast���t���o
 *  get_f_dates_seigen_a            A-5-4   �o�א�����AForecast���t���o
 *  get_f_dates_seigen_b            A-6-4   �o�א�����BForecast���t���o
 *  put_forecast_hikitori           A-2-5   ����v��Forecast�o�^
 *  put_forecast_hanbai             A-3-5   �̔��v��Forecast�o�^
 *  put_forecast_keikaku            A-4-5   �v�揤�iForecast�o�^
 *  put_forecast_seigen_a           A-5-5   �o�א�����AForecast�o�^
 *  put_forecast_seigen_b           A-6-5   �o�א�����BForecast�o�^
 *  del_if_data                     A-X-6   ���� �C���^�[�t�F�[�X�e�[�u���폜����
 *  forecast_hikitori               A-2     ����v��
 *  forecast_hanbai                 A-3     �̔��v��
 *  forecast_keikaku                A-4     �v�揤�i
 *  forecast_seigen_a               A-5     �o�א�����A
 *  forecast_seigen_b               A-6     �o�א�����B
 *  submain                         A-1     �̔��v��/����v��̎捞���s���v���V�[�W��
 *  main                                    �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/11   1.0  Oracle �y�c ��     ����쐬
 *  2008/04/21   1.1  Oracle �y�c ��     �����ύX�v�� No27 �Ή�
 *  2008/04/24   1.2  Oracle �y�c ��     �����ύX�v�� No27�C��, No72 �Ή�
 *  2008/05/01   1.3  Oracle �y�c ��     �����e�X�g���̕s��Ή�
 *  2008/05/26   1.4  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(I/F�폜��̃R�~�b�g�ǉ�)
 *  2008/05/26   1.5  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(�G���[�����A�X�L�b�v�����̎Z�o���@�ύX)
 *  2008/05/26   1.6  Oracle �F�{ �a�Y   �K��ᔽ(varchar�g�p)�Ή�
 *  2008/05/29   1.7  Oracle �F�{ �a�Y   �����e�X�g��Q�Ή�(�̔��v���MD050.�@�\�t���[�ƃ��W�b�N�̕s��v�C��)
 *  2008/06/04   1.8  Oracle �F�{ �a�Y   �V�X�e���e�X�g��Q�Ή�(�̔��v��̍폜�Ώے��o��������ROWNUM=1�폜)
 *  2008/06/12   1.9  Oracle �勴 �F�Y   �����e�X�g��Q�Ή�(400_�s����O#115)
 *  2008/08/01   1.10 Oracle �R�� ��_   ST��QNo10,�ύX�v��No184�Ή�
 *  2008/09/01   1.11 Oracle �勴 �F�Y   PT 2-2_13 �w�E56,PT 2-2_14 �w�E58,���b�Z�[�W�o�͕s��Ή�
 *  2008/09/16   1.12 Oracle �勴 �F�Y   PT 2-2_14�w�E75,76,77�Ή�
 *  2008/11/07   1.13 Oracle Yuko Kawano �����w�E#585
 *  2008/11/11   1.14 Oracle ���c ����   �����w�E#589�Ή�
 *  2008/11/13   1.15 Oracle �勴 �F�Y   �w�E586,596�Ή�
 *  2008/12/01   1.16 Oracle �勴 �F�Y   �{��#155�Ή�
 *  2009/02/17   1.17 Oracle ���g�R����  �{�ԏ�Q#38�Ή�
 *  2009/02/27   1.18 Oracle �勴 �F�Y   �{��#1240�Ή�
 *  2009/04/08   1.19 Oracle �g�� ����   �{��#1352,1374�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';   --����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';   --�x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2';   --�G���[
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';   --�X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';   --�X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';   --�X�e�[�^�X(�G���[)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg              VARCHAR2(2000);
  gv_sep_msg              VARCHAR2(2000);
  gv_exec_user            VARCHAR2(100);          -- ���s���[�U��
  gv_conc_name            VARCHAR2(30);           -- ���s�R���J�����g��
  gn_target_cnt           NUMBER;                 -- �Ώی���
  gn_normal_cnt           NUMBER;                 -- ���팏��
  gn_warn_cnt             NUMBER;                 -- �x������
  gn_error_cnt            NUMBER;                 -- �G���[����
  gv_conc_status          VARCHAR2(30);           -- �I���X�e�[�^�X
-- add start 1.11
  gn_del_data_cnt         NUMBER := 0;  -- ���炢�����Ώۃf�[�^�̏����J�E���^
-- add end 1.11
-- add start ver1.15
  gn_del_data_cnt2         NUMBER := 0;  -- ���炢�����Ώۃf�[�^�̏����J�E���^2
-- add end ver1.15
--
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
  parameter_expt         EXCEPTION;     -- �p�����[�^��O
  quantity_expt          EXCEPTION;
  duplication            EXCEPTION;
  date_error             EXCEPTION;
  no_data                EXCEPTION;
  amount_expt            EXCEPTION;
  warning_expt           EXCEPTION;
  lock_expt              EXCEPTION;     -- ���b�N(�r�W�[)�G���[
  null_expt              EXCEPTION;
  warn_expt              EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name     CONSTANT VARCHAR2(100) := 'XXINV100001C';   -- �p�b�P�[�W��
  gv_msg_kbn_inv  CONSTANT VARCHAR2(5)   := 'XXINV';          -- ���b�Z�[�W�敪XXINV
  gv_msg_kbn_cmn  CONSTANT VARCHAR2(5)   := 'XXCMN';          -- ���b�Z�[�W�敪XXCMN
--
  --���b�Z�[�W�ԍ�
  gv_msg_10a_001  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00001'; --���[�U�[��
  gv_msg_10a_002  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00002'; --�R���J�����g��
  gv_msg_10a_003  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00003'; --�Z�p���[�^
  gv_msg_10a_004  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00005'; --�����f�[�^�i���o���j
  gv_msg_10a_005  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00006'; --�G���[�f�[�^�i���o���j
  gv_msg_10a_006  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00007'; --�X�L�b�v�f�[�^�i���o���j
  gv_msg_10a_007  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00008'; --��������
  gv_msg_10a_008  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00009'; --��������
  gv_msg_10a_009  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00010'; --�G���[����
  gv_msg_10a_010  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00011'; --�X�L�b�v����
  gv_msg_10a_011  CONSTANT VARCHAR2(15) := 'APP-XXCMN-00012'; --�����X�e�[�^�X
  gv_msg_10a_016  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10002'; -- �v���t�@�C���擾�G���[
  gv_msg_10a_043  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10001'; -- �Ώۃf�[�^�Ȃ�
  gv_msg_10a_044  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10053'; -- �e�[�u�����b�N�G���[
  gv_msg_10a_045  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018'; -- �`�o�h�G���[
  gv_msg_10a_046  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10118'; -- �N������
  gv_msg_10a_047  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10030'; -- �R���J�����g��^�G���[
  gv_msg_10a_060  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10121'; -- �N�C�b�N�R�[�h�擾�G���[
  gv_msg_10a_072  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10012'; -- ���t�s���G���[
--
  gv_msg_10a_014  CONSTANT VARCHAR2(15) := 'APP-XXINV-10015'; -- ���̓p�����[�^�G���[
  gv_msg_10a_012  CONSTANT VARCHAR2(15) := 'APP-XXINV-10072'; -- ���̓p�����[�^�K�{�G���[
  gv_msg_10a_013  CONSTANT VARCHAR2(15) := 'APP-XXINV-10073'; -- Forecast���ރG���[
  gv_msg_10a_015  CONSTANT VARCHAR2(15) := 'APP-XXINV-10074'; -- ���̓p�����[�^���t��r�G���[
  gv_msg_10a_017  CONSTANT VARCHAR2(15) := 'APP-XXINV-10075'; -- ����v��t�H�[�L���X�g���擾�G���[
  gv_msg_10a_018  CONSTANT VARCHAR2(15) := 'APP-XXINV-10076'; -- �̔��v��t�H�[�L���X�g���擾�G���[
                                                          -- �o�א������`�t�H�[�L���X�g���擾�G���[
  gv_msg_10a_019  CONSTANT VARCHAR2(15) := 'APP-XXINV-10077';
                                                          -- �o�א������a�t�H�[�L���X�g���擾�G���[
  gv_msg_10a_020  CONSTANT VARCHAR2(15) := 'APP-XXINV-10078';
  gv_msg_10a_021  CONSTANT VARCHAR2(15) := 'APP-XXINV-10079'; -- �t�H�[�L���X�g���t�X�V���[�j���O
  gv_msg_10a_022  CONSTANT VARCHAR2(15) := 'APP-XXINV-10080'; -- �i�ڑ��݃`�F�b�N�G���[
  gv_msg_10a_023  CONSTANT VARCHAR2(15) := 'APP-XXINV-10081'; -- �o�בq�ɑ��݃`�F�b�N�G���[
  gv_msg_10a_024  CONSTANT VARCHAR2(15) := 'APP-XXINV-10082'; -- ���_���݃`�F�b�N�G���[
  gv_msg_10a_025  CONSTANT VARCHAR2(15) := 'APP-XXINV-10083'; -- �����R�[�h�擾�G���[
  gv_msg_10a_026  CONSTANT VARCHAR2(15) := 'APP-XXINV-10084'; -- �o�בq�ɊǗ����敪�G���[
  gv_msg_10a_027  CONSTANT VARCHAR2(15) := 'APP-XXINV-10085'; -- �i�ڔp�~�G���[
  gv_msg_10a_028  CONSTANT VARCHAR2(15) := 'APP-XXINV-10086'; -- �i�ڋ敪�`�F�b�N���[�j���O
  gv_msg_10a_029  CONSTANT VARCHAR2(15) := 'APP-XXINV-10087'; -- �i�ڑ��݃`�F�b�N���[�j���O
  gv_msg_10a_030  CONSTANT VARCHAR2(15) := 'APP-XXINV-10088'; -- �i�ڔN�x�`�F�b�N���[�j���O
  gv_msg_10a_031  CONSTANT VARCHAR2(15) := 'APP-XXINV-10089'; -- �i�ڕW�������N�x�`�F�b�N���[�j���O
  gv_msg_10a_032  CONSTANT VARCHAR2(15) := 'APP-XXINV-10090'; -- �i�ڌv�揤�i���݃`�F�b�N�G���[
  gv_msg_10a_033  CONSTANT VARCHAR2(15) := 'APP-XXINV-10091'; -- �i�ڕ����\�����݃`�F�b�N���[�j���O
  gv_msg_10a_034  CONSTANT VARCHAR2(15) := 'APP-XXINV-10092'; -- �J�n���t�ߋ��N���G���[
  gv_msg_10a_035  CONSTANT VARCHAR2(15) := 'APP-XXINV-10093'; -- �J�n���t�ߋ��N�x�G���[
  gv_msg_10a_036  CONSTANT VARCHAR2(15) := 'APP-XXINV-10094'; -- ���t�ߋ��`�F�b�N���[�j���O
  gv_msg_10a_037  CONSTANT VARCHAR2(15) := 'APP-XXINV-10095'; -- ���t1�����ȓ��`�F�b�N���[�j���O
  gv_msg_10a_038  CONSTANT VARCHAR2(15) := 'APP-XXINV-10096'; -- ���t�召��r�G���[
  gv_msg_10a_039  CONSTANT VARCHAR2(15) := 'APP-XXINV-10097'; -- �d���`�F�b�N�G���[�P
  gv_msg_10a_040  CONSTANT VARCHAR2(15) := 'APP-XXINV-10098'; -- �d���`�F�b�N�G���[�Q
  gv_msg_10a_041  CONSTANT VARCHAR2(15) := 'APP-XXINV-10099'; -- ���l�`�F�b�N�G���[
  gv_msg_10a_042  CONSTANT VARCHAR2(15) := 'APP-XXINV-10100'; -- ���z�f�[�^����G���[
  gv_msg_10a_061  CONSTANT VARCHAR2(15) := 'APP-XXINV-10142'; -- ���i�敪�擾�G���[
--
  gv_msg_10a_059  CONSTANT VARCHAR2(15) := 'APP-XXINV-10143'; -- �P�[�X���萔�擾�G���[
  gv_msg_10a_058  CONSTANT VARCHAR2(15) := 'APP-XXINV-10144'; -- �v�揤�i�t�H�[�L���X�g���擾�G���[
--
  --�����擾���Ɏg�p
  gv_msg_10a_062  CONSTANT VARCHAR2(15) := 'APP-XXINV-10137'; -- ����v��t�H�[�L���X�g���d���G���[
  gv_msg_10a_063  CONSTANT VARCHAR2(15) := 'APP-XXINV-10141'; -- �̔��v��t�H�[�L���X�g���d���G���[
                                                          -- �o�א�����A�t�H�[�L���X�g���d���G���[
  gv_msg_10a_064  CONSTANT VARCHAR2(15) := 'APP-XXINV-10139';
                                                          -- �o�א�����B�t�H�[�L���X�g���d���G���[
  gv_msg_10a_065  CONSTANT VARCHAR2(15) := 'APP-XXINV-10140';
  gv_msg_10a_066  CONSTANT VARCHAR2(15) := 'APP-XXINV-10138'; -- �v�揤�i�t�H�[�L���X�g���d���G���[
  gv_msg_10a_067  CONSTANT VARCHAR2(15) := 'APP-XXINV-10132'; -- ����v��K�{�`�F�b�N�G���[
  gv_msg_10a_068  CONSTANT VARCHAR2(15) := 'APP-XXINV-10133'; -- �v�揤�i�K�{�`�F�b�N�G���[
  gv_msg_10a_069  CONSTANT VARCHAR2(15) := 'APP-XXINV-10134'; -- �o�א�����A�K�{�`�F�b�N�G���[
  gv_msg_10a_070  CONSTANT VARCHAR2(15) := 'APP-XXINV-10135'; -- �o�א�����B�K�{�`�F�b�N�G���[
  gv_msg_10a_071  CONSTANT VARCHAR2(15) := 'APP-XXINV-10136'; -- �̔��v��K�{�`�F�b�N�G���[
  gv_msg_10a_073  CONSTANT VARCHAR2(15) := 'APP-XXINV-10154'; -- ���z�}�C�i�X�G���[
--
  gv_cons_forecast_designator CONSTANT VARCHAR2(100) := 'Forecast����';       -- Forecast����
  gv_cons_forecast_yyyymm     CONSTANT VARCHAR2(100) := '�N��';               -- �N��
  gv_cons_forecast_year       CONSTANT VARCHAR2(100) := '�N�x';               -- �N�x
  gv_cons_forecast_version    CONSTANT VARCHAR2(100) := '����';               -- ����
  gv_cons_forecast_date       CONSTANT VARCHAR2(100) := '�J�n���t';           -- �J�n���t
  gv_cons_forecast_end_date   CONSTANT VARCHAR2(100) := '�I�����t';           -- �I�����t
  gv_cons_item_no             CONSTANT VARCHAR2(100) := '�i��';               -- �i��
  gv_cons_subinventory_code   CONSTANT VARCHAR2(100) := '�o�ɑq��';           -- �o�ɑq��
  gv_cons_account_number      CONSTANT VARCHAR2(100) := '���_';               -- ���_
  gv_cons_dept_code_flg       CONSTANT VARCHAR2(100) := '�捞�������o�t���O'; -- �捞�������o�t���O
  gv_cons_login_user          CONSTANT VARCHAR2(100) := '���O�C�����[�U';     -- ���O�C�����[�U
  gv_cons_dept_code           CONSTANT VARCHAR2(100) := '�捞����';           -- �捞����
  gv_cons_input_forecast      CONSTANT VARCHAR2(100) := 'Forecast����:';      -- Forecast����
  gv_cons_input_param         CONSTANT VARCHAR2(100) := '���̓p�����[�^�l:';  -- ���̓p�����[�^�l
-- add start ver1.15
  gv_object                   CONSTANT VARCHAR2(100) := '���炢�����Ώ�:';  -- ���炢�����O�f�[�^
-- add end ver1.15
--
  gv_cons_fc_type             CONSTANT VARCHAR2(100) := 'XXINV_FC_TYPE';-- loopup_type=Forecast����
--                                                        -- loopup_type=�v�揤�i�Ώۊ���
  gv_cons_type_keikaku_term        CONSTANT VARCHAR2(100) := 'XXINV_KEIKAKU_TERM';
  gv_custmer_class_code_kyoten     CONSTANT VARCHAR2(100) := '1';      -- �ڋq�敪(1:���_)
  gv_cons_flg_yes                  CONSTANT VARCHAR2(100) := 'Yes';
  gv_cons_flg_no                   CONSTANT VARCHAR2(100) := 'No';
  gv_ship_ctl_id_leaf        CONSTANT VARCHAR2(100) := '1';            -- '�o�׊Ǘ����E���[�t'
  gv_ship_ctl_id_drink       CONSTANT VARCHAR2(100) := '2';            -- '�o�׊Ǘ����E�h�����N'
  gv_ship_ctl_id_both        CONSTANT VARCHAR2(100) := '3';            -- '�o�׊Ǘ����E����'
  gv_cons_item_product       CONSTANT VARCHAR2(100) := '5';            -- '�i�ڋ敪�E���i'
--
  gv_cons_lang_ja            CONSTANT VARCHAR2(100) := 'JA';           -- 'JA'
  gv_cons_base_code          CONSTANT VARCHAR2(100) := '1';            -- '���_'
  gv_cons_product            CONSTANT VARCHAR2(100) := '���i';         -- '���i'
-- 2009/04/08 v1.19 T.Yoshimoto Mod Start �{��#1352
--  gv_cons_p_type_standard    CONSTANT VARCHAR2(100) := '1';            -- �}�X�^�敪���W����'1'
  gv_cons_p_type_standard    CONSTANT VARCHAR2(100) := '2';            -- �}�X�^�敪���W����'2'
-- 2009/04/08 v1.19 T.Yoshimoto Mod End �{��#1352
  gn_cons_p_item_flag        CONSTANT NUMBER        := 1;              -- �v�揤�i
--
  gv_cons_case_quantity      CONSTANT VARCHAR2(100) := '�P�[�X����';   -- '�P�[�X����'
  gv_cons_quantity           CONSTANT VARCHAR2(100) := '�o������';     -- '�o������'
  gv_cons_amount             CONSTANT VARCHAR2(100) := '���z';         -- '���z'
--
  gn_cons_no_data_found      CONSTANT NUMBER        := 0;              -- �f�[�^�Ȃ�
  gn_cons_data_found         CONSTANT NUMBER        := 1;              -- �f�[�^����
--
  gv_cons_fc_type_hikitori   CONSTANT VARCHAR2(100) := '01';            -- ����v��
  gv_cons_fc_type_keikaku    CONSTANT VARCHAR2(100) := '02';            -- �v�揤�i
  gv_cons_fc_type_seigen_a   CONSTANT VARCHAR2(100) := '03';            -- �o�א�����A
  gv_cons_fc_type_seigen_b   CONSTANT VARCHAR2(100) := '04';            -- �o�א�����B
  gv_cons_fc_type_hanbai     CONSTANT VARCHAR2(100) := '05';            -- �̔��v��
--
  gv_cons_keikaku_term       CONSTANT VARCHAR2(100) := '�v�揤�i�Ώۊ���';
  gv_cons_days               CONSTANT VARCHAR2(100) := '����';
-- mod start 1.11
--  gv_cons_api                CONSTANT VARCHAR2(100) := '�\��API';
  gv_cons_api                CONSTANT VARCHAR2(100) := '�\��';
-- mod end 1.11
-- �g�[�N��
  gv_tkn_status        CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_cnt           CONSTANT VARCHAR2(15) := 'CNT';
  gv_tkn_conc          CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user          CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_time          CONSTANT VARCHAR2(15) := 'TIME';
  gv_tkn_ng_profile    CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  gv_tkn_api_name      CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_par           CONSTANT VARCHAR2(15) := 'PAR';
  gv_tkn_sdate         CONSTANT VARCHAR2(15) := 'SDATE';
  gv_tkn_edate         CONSTANT VARCHAR2(15) := 'EDATE';
--
  gv_tkn_parameter     CONSTANT VARCHAR2(15) := 'PARAMETER';  -- ���̓p�����[�^
  gv_tkn_value         CONSTANT VARCHAR2(15) := 'VALUE';      -- �p�����[�^�l
  gv_tkn_profile       CONSTANT VARCHAR2(15) := 'PROFILE';    -- �v���t�@�C����
  gv_tkn_item          CONSTANT VARCHAR2(15) := 'ITEM';       -- �i�ڃR�[�h
  gv_tkn_soko          CONSTANT VARCHAR2(15) := 'SOKO';       -- �o�בq�ɃR�[�h
  gv_tkn_kyoten        CONSTANT VARCHAR2(15) := 'KYOTEN';     -- ���_�R�[�h
  gv_tkn_column        CONSTANT VARCHAR2(15) := 'COLUMN';     -- ���ږ�
  gv_tkn_table         CONSTANT VARCHAR2(15) := 'TABLE';      -- �e�[�u����
  gv_tkn_busho         CONSTANT VARCHAR2(15) := 'BUSHO';      -- �捞����
  gv_tkn_forcast       CONSTANT VARCHAR2(15) := 'FORCAST';    -- Forecast
  gv_tkn_lup_type      CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';-- LOOKUP_TYPE
  gv_tkn_meaning       CONSTANT VARCHAR2(15) := 'MEANING';    -- MEANING
  gv_tkn_amount        CONSTANT VARCHAR2(15) := 'AMOUNT';     -- ���z
  gv_tkn_nendo         CONSTANT VARCHAR2(15) := 'NENDO';      -- �N�x
  gv_tkn_sedai         CONSTANT VARCHAR2(15) := 'SEDAI';      -- ����
  gv_tkn_case          CONSTANT VARCHAR2(15) := 'CASE';       -- �P�[�X����
  gv_tkn_bara          CONSTANT VARCHAR2(15) := 'BARA';       -- �o������
  gv_tkn_key           CONSTANT VARCHAR2(15) := 'KEY';        -- �L�[
  gv_tkn_ng_table      CONSTANT VARCHAR2(15) := 'NG_TABLE';   -- NG�e�[�u��
--
  --�v���t�@�C��
  gv_prf_start_day     CONSTANT VARCHAR2(100) := 'XXCMN_PERIOD_START_DAY'; -- XXCMN:�N�x�J�n����
  gv_prf_item_div      CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV';         -- ���i�敪
  gv_prf_article_div   CONSTANT VARCHAR2(100) := 'XXCMN_ARTICLE_DIV';      -- �i�ڋ敪
--
  -- �g�pDB��
                                           -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u����
  gv_if_table     CONSTANT VARCHAR2(100) := 'XXINV_MRP_FORECAST_INTERFACE';
  gv_if_table_jp  CONSTANT VARCHAR2(100) := '�̔��v��/����v��C���^�[�t�F�[�X�e�[�u��';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���R�[�h��`�����L�q����
  -- �C���^�[�t�F�[�X�e�[�u���̃f�[�^���i�[���郌�R�[�h
  TYPE forecast_rec IS RECORD(
    txns_id              xxinv_mrp_forecast_interface.forecast_if_id%TYPE,      -- ���ID
    forecast_designator  xxinv_mrp_forecast_interface.forecast_designator%TYPE, -- Forecast����
    location_code        xxinv_mrp_forecast_interface.location_code%TYPE,       -- �o�בq��
    base_code            xxinv_mrp_forecast_interface.base_code%TYPE,           -- ���_
    dept_code            xxinv_mrp_forecast_interface.dept_code%TYPE,           -- �捞����
    item_code            xxinv_mrp_forecast_interface.item_code%TYPE,           -- �i��
    start_date_active    xxinv_mrp_forecast_interface.forecast_date%TYPE,       -- �J�n���t(DATE�^)
    end_date_active      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,   -- �I�����t(DATE�^)
    case_quantity        xxinv_mrp_forecast_interface.case_quantity%TYPE,       -- �P�[�X����
    quantity             xxinv_mrp_forecast_interface.indivi_quantity%TYPE,     -- �o������
    price                xxinv_mrp_forecast_interface.amount%TYPE               -- ���z
  );
  -- Forecast���t�e�[�u���ɓo�^���邽�߂̃f�[�^���i�[���錋���z��
  TYPE forecast_tbl IS TABLE OF forecast_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  gv_forecast_designator  VARCHAR2(100);      -- Forecast����
  gv_in_param             VARCHAR2(100);      -- ���̓p�����[�^�l
  gd_sysdate_yyyymmdd     DATE;               -- �V�X�e�����ݓ��t
  gv_in_yyyymm            VARCHAR2(10);       -- ���̓o�����[�^�̔N��
  gd_in_yyyymmdd_start    DATE;               -- ���̓o�����[�^�̔N���̌�����
  gd_in_yyyymmdd_end      DATE;               -- ���̓o�����[�^�̔N���̌�����
  gd_in_start_date        DATE;               -- ���̓o�����[�^�̊J�n���t
  gd_in_end_date          DATE;               -- ���̓o�����[�^�̏I�����t
  gv_in_start_date        VARCHAR2(10);               -- ���̓o�����[�^�̊J�n���t
  gv_in_end_date          VARCHAR2(10);               -- ���̓o�����[�^�̏I�����t
  gv_start_mmdd           VARCHAR2(5);        -- �N�x�J�n���t(A-1-3�ŃZ�b�g)
  gv_start_yyyymmdd       VARCHAR2(10);       -- �Ώ۔N�x�J�n�N����(A-1-4�ŃZ�b�g)
  gd_start_yyyymmdd       DATE;               -- �Ώ۔N�x�J�n�N����(A-1-4�ŃZ�b�g)
  gd_end_yyyymmdd         DATE;               -- �Ώ۔N�x�I���N����
--
  gd_keikaku_start_date   DATE;               -- �v�揤�i�J�n��
  gd_keikaku_end_date     DATE;               -- �v�揤�i�I����
  gn_login_user           NUMBER;             -- ���O�C�����[�U��
  gn_created_by           NUMBER;             -- ���O�C�����[�UID
  gv_forecast_year        VARCHAR2(10);       -- ���̓o�����[�^�̔N�x
  gv_forecast_version     VARCHAR2(10);       -- ���̓o�����[�^�̐���
--
  gv_item_div             VARCHAR2(10);       -- �v���t�@�C������擾���鏤�i�敪
  gv_article_div          VARCHAR2(10);       -- �v���t�@�C������擾����i���敪
  gn_araigae_cnt          NUMBER := 0;
  
--
  gv_in_item_code      xxinv_mrp_forecast_interface.item_code%TYPE;     -- ���̓o�����[�^�̕i��
  gv_in_base_code      xxinv_mrp_forecast_interface.base_code%TYPE;     -- ���̓o�����[�^�̋��_
  gv_in_location_code  xxinv_mrp_forecast_interface.location_code%TYPE; -- ���̓o�����[�^�̏o�בq��
  gv_in_dept_code_flg     VARCHAR2(10); -- �捞�������o�t���O
--
  gv_location_short_name xxcmn_locations_all.location_short_name%TYPE;  -- �S������
  gv_location_code       hr_locations_all.location_code%TYPE;  -- ���Ə��R�[�h
--
  -- A-*-3 �Ŏ擾����
  gv_3f_forecast_designator
             mrp_forecast_designators.forecast_designator%TYPE;       -- Forecast��
  gn_3f_organization_id
             mrp_forecast_designators.organization_id%TYPE;           -- �݌ɑg�D
  -- A-*-4 �Ŏ擾����
  TYPE araigae_rec IS RECORD(
    gv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE,                  -- ���ID
    gv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE,             -- Forecast��
    gv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE,                 -- �݌ɑg�D
    gv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE,               -- �i��
    gd_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE,                   -- �J�n���t
    gd_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE                   -- �I�����t
-- add start ver1.15
   ,gd_4f_item_no
             ic_item_mst_b.item_no%TYPE                              -- �i�ڃR�[�h
   ,gd_4f_quantity
             mrp_forecast_dates.current_forecast_quantity%TYPE       -- ����
   ,gd_4f_case_quantity
             mrp_forecast_dates.attribute6%TYPE                      -- ���P�[�X����
   ,gd_4f_bara_quantity
             mrp_forecast_dates.attribute4%TYPE                      -- ���o������
-- add end ver1.15
  );
--
  --�̔��v��p�O���[�o���ϐ�
  gv_4h_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- ���ID
  gv_4h_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast��
  gv_4h_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- �݌ɑg�D
  gv_4h_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- �i��
  gd_4h_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- �J�n���t
  gd_4h_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- �I�����t
--
  --�v�揤�i�p�O���[�o���ϐ�
  gd_4k_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- �J�n���t
  gd_4k_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- �I�����t
--
  -- Forecast���t�e�[�u�����폜���邽�߂̃f�[�^���i�[���錋���z��
  TYPE araigae_tbl IS TABLE OF araigae_rec INDEX BY PLS_INTEGER;
--
  gn_datadisp_no          NUMBER := 0;        -- data�s���o�͂����Y����ۑ�
  -- �����ɓY��������ꍇ�͂��łɁA�f�[�^�s��\�����Ă���̂Ń��b�Z�[�W�̂ݕ\������B
  gn_no_msg_disp          NUMBER := 0;        -- main�ɂď������ʃ��|�[�g�ɕ\�����Ȃ�
  -- A-2-2, A-3-2, A-4-2, A-5-2, A-6-2 �ŃG���[���b�Z�[�W��\�������ꍇ�́Amain�ōŌ��
  -- ���b�Z�[�W��\������K�v���Ȃ��̂ŁAmain�͂��̕ϐ��ŕ\���̐�������߂�
-- 2008/08/01 Add ��
-- WHO�J����
  gn_last_updated_by         NUMBER;
  gn_request_id              NUMBER;
  gn_program_application_id  NUMBER;
  gn_program_id              NUMBER;
  gd_who_sysdate             DATE;
-- 2008/08/01 Add ��
--
-- add start 1.11
  t_forecast_designator_tabl      MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
  -- Forecast�o�^�p���R�[�h
  t_forecast_interface_tab_inst   MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
-- add end 1.11
--
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD Start --
-- =======================================
--  �v���V�[�W���錾                    
-- =======================================
  -- A-2-3 ����v��Forecast�����o
  PROCEDURE get_f_degi_hikitori(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- A-4-3 �v�揤�iForecast�����o
  PROCEDURE get_f_degi_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- A-5-3 �o�א�����AForecast�����o
  PROCEDURE get_f_degi_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- A-6-3 �o�א�����BForecast�����o
  PROCEDURE get_f_degi_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD End   --
--
  /**********************************************************************************
   * Procedure Name   : if_data_disp
   * Description      : �C���^�[�t�F�[�X�f�[�^�s���������ʃ��|�[�g�ɕ\������
   ***********************************************************************************/
  PROCEDURE if_data_disp(
    in_if_data_tbl        IN  forecast_tbl,
    in_datadisp_no        IN  NUMBER)           -- ��������IF�f�[�^�J�E���^
  IS
    lv_databuf  VARCHAR2(5000);  -- �C���^�[�t�F�[�X�f�[�^�s
  BEGIN
    IF ( in_datadisp_no <> gn_datadisp_no ) THEN
      lv_databuf := in_if_data_tbl(in_datadisp_no).txns_id                || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).forecast_designator    || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).location_code          || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).base_code              || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).dept_code              || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).item_code              || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).start_date_active      || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).end_date_active        || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).case_quantity          || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).quantity               || gv_msg_pnt ||
                    in_if_data_tbl(in_datadisp_no).price;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_databuf);
      -- �C���^�[�t�F�[�X�f�[�^�s��\�������̂ŃO���[�o���ɓY������ۑ�����
      gn_datadisp_no := in_datadisp_no;
    END IF;
  END if_data_disp;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_forecast
   * Description      : ���̓p�����[�^�`�F�b�N�|Forecast�敪(A-1-2-1)
   ***********************************************************************************/
  PROCEDURE parameter_check_forecast(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_forecast'; -- �v���O������
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
    ln_count_num NUMBER;        -- Forecast���ޑ��݂��邩(1:����A0:�Ȃ��j
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
    -- Forecast���ނ̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_forecast_designator IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- ���̓p�����[�^�K�{�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_designator) -- 'Forecast����'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- ���̓p�����[�^��Forecast���ނ��N�C�b�N�R�[�h���ɑ��݂��邩(1:����A0:�Ȃ��j
    SELECT xlv_v.description
    INTO   gv_forecast_designator
    FROM   xxcmn_lookup_values_v xlv_v
    WHERE  xlv_v.lookup_type = gv_cons_fc_type
      AND  xlv_v.lookup_code = iv_forecast_designator
      AND  ROWNUM            = 1;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** NULL***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    WHEN NO_DATA_FOUND THEN                           --*** ���݂��Ȃ� ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_013)  -- Forecast���ރG���[
                                                    ,1
                                                    ,5000);
      gv_forecast_designator := iv_forecast_designator;
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
  END parameter_check_forecast;
--
--
/**********************************************************************************
   * Procedure Name   : parameter_check_yyyymm
   * Description      : ���̓p�����[�^�`�F�b�N�|�N��(A-1-2-2)
   ***********************************************************************************/
  PROCEDURE parameter_check_yyyymm(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    iv_forecast_yyyymm       IN  VARCHAR2,         -- �N��
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_yyyymm'; -- �v���O������
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
    -- �N���̃`�F�b�N��Forecast���ނ�'����v��'�̂ݍs��
    IF (iv_forecast_designator <> gv_cons_fc_type_hikitori) THEN
      RETURN;
    END IF;
--
    -- �N���̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_forecast_yyyymm IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- ���̓p�����[�^�K�{�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_yyyymm)   -- '�N��'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- �N�����V�X�e�����t���Â��ꍇ�̓G���[�Ƃ���
    IF (iv_forecast_yyyymm < TO_CHAR(gd_sysdate_yyyymmdd,'YYYYMM')) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- ���̓p�����[�^�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_yyyymm
                                                    ,gv_tkn_value     -- �g�[�N��'VALUE'
                                                    ,iv_forecast_yyyymm)   -- �N��
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END parameter_check_yyyymm;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_forecast_year
   * Description      : ���̓p�����[�^�`�F�b�N�|�N�x(A-1-2-3)
   ***********************************************************************************/
  PROCEDURE parameter_check_forecast_year(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    iv_forecast_year         IN  VARCHAR2,         -- �N�x
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_forecast_year'; -- �v���O������
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
    ld_yyyy_format          DATE;
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
    -- �N�x�̃`�F�b�N��Forecast���ނ�'�̔��v��'�̂ݍs��
    IF (iv_forecast_designator <> gv_cons_fc_type_hanbai) THEN
      RETURN;
    END IF;
--
    -- �N�x�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_forecast_year IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_012    -- ���̓p�����[�^�K�{�G���[
                                                    ,gv_tkn_parameter  -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_year) -- '�N�x'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- YYYY�̌^�ɕϊ�(NULL���A���Ă�����G���[�j
    ld_yyyy_format := FND_DATE.STRING_TO_DATE(iv_forecast_year, 'YYYY');
--
    -- YYYY�̓��t�^�ł͂Ȃ��ꍇ�̓G���[�Ƃ���
    IF (ld_yyyy_format IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv         -- 'XXINV'
                                                    ,gv_msg_10a_014         -- ���̓p�����[�^�G���[
                                                    ,gv_tkn_parameter       -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_year  -- '�N�x'
                                                    ,gv_tkn_value           -- �g�[�N��'VALUE'
                                                    ,iv_forecast_year)      -- �N�x
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END parameter_check_forecast_year;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_version
   * Description      : ���̓p�����[�^�`�F�b�N�|����(A-1-2-4)
   ***********************************************************************************/
  PROCEDURE parameter_check_version(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    iv_forecast_version      IN  VARCHAR2,         -- ����
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_version'; -- �v���O������
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
    ln_version      NUMBER;
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
    -- ����̃`�F�b�N��Forecast���ނ�'�̔��v��'�̂ݍs��
    IF (iv_forecast_designator <> gv_cons_fc_type_hanbai) THEN
      RETURN;
    END IF;
--
    -- ����̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_forecast_version IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- ���̓p�����[�^�K�{�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_version) -- '����'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- ���l�^�ɕϊ�(�ϊ��ł��Ȃ��ꍇ�͗�O�����ց��G���[�j
    ln_version := TO_NUMBER(iv_forecast_version);
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- TO_NUMBER()�ŕϊ��ł��Ȃ������ꍇ
    WHEN VALUE_ERROR THEN
      -- ���オ���l�^�ł͂Ȃ��ꍇ�̓G���[�Ƃ���
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- ���̓p�����[�^�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_version  -- '����'
                                                    ,gv_tkn_value              -- �g�[�N��'VALUE'
                                                    ,iv_forecast_version)      -- ����
                                                    ,1
                                                    ,5000);
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
  END parameter_check_version;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_forecast_date
   * Description      : ���̓p�����[�^�`�F�b�N�|�J�n�E�I�����t(A-1-2-5)
   ***********************************************************************************/
  PROCEDURE parameter_check_forecast_date(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    iv_forecast_date         IN  VARCHAR2,         -- �J�n���t
    iv_forecast_end_date     IN  VARCHAR2,         -- �I�����t
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_forecast_date'; -- �v���O������
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
    ld_yyyymmdd_format          DATE;
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
    -- �J�n�E�I�����t�̃`�F�b�N��Forecast���ނ�'�o�א�����A'�܂���'�o�א�����B'�̂ݍs��
    IF ((iv_forecast_designator <> gv_cons_fc_type_seigen_a)
      AND (iv_forecast_designator <> gv_cons_fc_type_seigen_b))
    THEN
      RETURN;
    END IF;
--
    -- �J�n���t�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_forecast_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- ���̓p�����[�^�K�{�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_date)   -- '�J�n���t'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- �I�����t�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_forecast_end_date IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- ���̓p�����[�^�K�{�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_end_date)   -- '�I�����t'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- �J�n���t��YYYYMMDD�̌^�ɕϊ�(NULL���A���Ă�����G���[�j
    ld_yyyymmdd_format := FND_DATE.STRING_TO_DATE(iv_forecast_date, 'YYYY/MM/DD');
--
    -- �J�n���t��YYYYMMDD�̓��t�^�ł͂Ȃ��ꍇ�̓G���[�Ƃ���
    IF (ld_yyyymmdd_format IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- ���̓p�����[�^�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_date -- '�J�n���t'
                                                    ,gv_tkn_value     -- �g�[�N��'VALUE'
                                                    ,iv_forecast_date)     -- �J�n���t
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- �I�����t��YYYYMMDD�̌^�ɕϊ�(NULL���A���Ă�����G���[�j
    ld_yyyymmdd_format := FND_DATE.STRING_TO_DATE(iv_forecast_end_date, 'YYYY/MM/DD');
--
    -- �I�����t��YYYYMMDD�̓��t�^�ł͂Ȃ��ꍇ�̓G���[�Ƃ���
    IF (ld_yyyymmdd_format IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- ���̓p�����[�^�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_forecast_end_date   -- '�I�����t'
                                                    ,gv_tkn_value     -- �g�[�N��'VALUE'
                                                    ,iv_forecast_end_date)         -- �I�����t
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- �J�n���t�ƏI�����t�̊֌W���s���ȏꍇ�̓G���[�Ƃ���
    IF (iv_forecast_date > iv_forecast_end_date) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv -- 'XXINV'
                                                                  -- ���̓p�����[�^���t��r�G���[
                                                    ,gv_msg_10a_015)
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END parameter_check_forecast_date;
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_item_no
   * Description      : ���̓p�����[�^�`�F�b�N�|�i��(A-1-2-6)
   ***********************************************************************************/
  PROCEDURE parameter_check_item_no(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    iv_item_no               IN  VARCHAR2,         -- �i��
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_item_no'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �i�ڂ̃`�F�b�N��Forecast���ނ�'�o�א�����A'�܂���'�o�א�����B'�œ��͎��̂ݍs��
    IF ((iv_forecast_designator <> gv_cons_fc_type_seigen_a)
      AND (iv_forecast_designator <> gv_cons_fc_type_seigen_b))
    THEN
      RETURN;
    END IF;
--
    -- �i�ڂ̓��͂��������ꍇ�̂݃`�F�b�N���s��
    IF (iv_item_no IS NOT NULL) THEN
--
      -- �i�ڂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ�̓G���[�Ƃ���
      SELECT COUNT(imv.item_id)
      INTO   ln_select_count
      FROM   xxcmn_item_mst_v  imv   -- OPM�i�ڏ��View
      WHERE  imv.item_no       = iv_item_no
        AND  ROWNUM            = 1;
--
      -- �i�ڂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
      IF (ln_select_count = 0) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                      ,gv_msg_10a_022    -- �i�ڑ��݃`�F�b�N�G���[
                                                      ,gv_tkn_item       -- �g�[�N��'ITEM'
                                                      ,iv_item_no)       -- �i��
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
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
  END parameter_check_item_no;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_subinventory
   * Description      : ���̓p�����[�^�`�F�b�N�|�o�ɑq��(A-1-2-7)
   ***********************************************************************************/
  PROCEDURE parameter_check_subinventory(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    iv_location_code         IN  VARCHAR2,         -- �o�ɑq��
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_subinventory'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �o�ɑq�ɂ̃`�F�b�N��Forecast���ނ�'�o�א�����B'�œ��͎��̂ݍs��
    IF (iv_forecast_designator <> gv_cons_fc_type_seigen_b) THEN
      RETURN;
    END IF;
--
    -- �o�ɑq�ɂ̓��͂��������ꍇ�̂݃`�F�b�N���s��
    IF (iv_location_code IS NOT NULL) THEN
--
      -- OPM�ۊǏꏊ���VIEW(XXCMN_ITEM_LOCATIONS_V)����ۊǑq��ID�𒊏o����
      -- �ۊǑq��ID�����݂��Ȃ��ꍇ�̓G���[�Ƃ���
      SELECT COUNT(ilv.inventory_location_id)
      INTO   ln_select_count
      FROM   xxcmn_item_locations_v ilv
      WHERE  ilv.segment1 = iv_location_code
        AND  ROWNUM        = 1;
--
      -- �o�ɑq�ɂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
      IF (ln_select_count = 0) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv -- 'XXINV'
                                                      ,gv_msg_10a_023 -- �o�בq�ɑ��݃`�F�b�N�G���[
                                                      ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                      ,iv_location_code)  -- �o�ɑq��
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
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
  END parameter_check_subinventory;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_account_number
   * Description      : ���̓p�����[�^�`�F�b�N�|���_(A-1-2-8)
   ***********************************************************************************/
  PROCEDURE parameter_check_account_number(
    iv_forecast_designator   IN  VARCHAR2,  -- Forecast�敪
    iv_account_number        IN  VARCHAR2,  -- ���_
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_account_number'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- ���_�̃`�F�b�N��Forecast���ނ�'�o�א�����A'�œ��͎��̂ݍs��
    IF (iv_forecast_designator <> gv_cons_fc_type_seigen_a) THEN
      RETURN;
    END IF;
--
    -- ���_�̓��͂��������ꍇ�̂݃`�F�b�N���s��
    IF (iv_account_number IS NOT NULL) THEN
--
      -- �ڋq�}�X�^(xxcmn_cust_accounts_v)�A�p�[�e�B�}�X�^(xxcmn_parties_v)�A
      -- �p�[�e�B�A�h�I���}�X�^(xxcmn_parties)����ڋqID�𒊏o����
      -- �ڋqID�����݂��Ȃ��ꍇ�̓G���[�Ƃ���
      SELECT COUNT(cpv.cust_account_id)
      INTO   ln_select_count
      FROM   xxcmn_parties2_v       cpv
      WHERE  cpv.account_number      =  iv_account_number
        AND  cpv.customer_class_code =  gv_custmer_class_code_kyoten
        AND  cpv.start_date_active  <= gd_sysdate_yyyymmdd
        AND  cpv.end_date_active    >= gd_sysdate_yyyymmdd
        AND  ROWNUM                  = 1;
--
    -- ���_���Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
      IF (ln_select_count = 0) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                      ,gv_msg_10a_024   -- ���_���݃`�F�b�N�G���[
                                                      ,gv_tkn_kyoten    -- �g�[�N��'KYOTEN'
                                                      ,iv_account_number)  -- ���_
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
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
  END parameter_check_account_number;
--
--
  /**********************************************************************************
   * Procedure Name   : parameter_check_dept_code
   * Description      : ���̓p�����[�^�`�F�b�N�|�捞����(A-1-2-9)
   ***********************************************************************************/
  PROCEDURE parameter_check_dept_code(
    iv_forecast_designator   IN  VARCHAR2,         -- Forecast�敪
    iv_dept_code_flg         IN  VARCHAR2,         -- �捞�������o�t���O
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'parameter_check_dept_code'; -- �v���O������
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
    -- �捞�����̃`�F�b�N��Forecast���ނ��o�א�����B'�̂ݍs��
    IF (iv_forecast_designator <> gv_cons_fc_type_seigen_b) THEN
      RETURN;
    END IF;
--
    -- �捞�������o�t���O�̓��͂��Ȃ��ꍇ�̓G���[�Ƃ���
    IF (iv_dept_code_flg IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_012   -- ���̓p�����[�^�K�{�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_dept_code_flg) -- '�捞�������o�t���O'
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    -- �捞�������o�t���O��'Yes'�܂���'No'�ȊO�̏ꍇ�̓G���[�Ƃ���
    IF ((iv_dept_code_flg <> gv_cons_flg_yes) AND (iv_dept_code_flg <> gv_cons_flg_no)) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_014   -- ���̓p�����[�^�G���[
                                                    ,gv_tkn_parameter -- �g�[�N��'PARAMETER'
                                                    ,gv_cons_dept_code_flg -- '�捞�������o�t���O'
                                                    ,gv_tkn_value      -- �g�[�N��'VALUE'
                                                    ,iv_dept_code_flg) -- �捞�������o�t���O
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END parameter_check_dept_code;
--
  /***********************************************************************************
   * Procedure Name   : get_profile_start_day
   * Description      : A-1-3 �v���t�@�C�����N�x�J�n�������擾����
   ***********************************************************************************/
  PROCEDURE get_profile_start_day(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_start_day'; -- �v���O������
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
    lv_start_day   VARCHAR2(10);
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
    --�N�x�J�n�����擾
    lv_start_day := SUBSTRB(FND_PROFILE.VALUE(gv_prf_start_day),1,5);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (lv_start_day IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_016   -- �v���t�@�C���擾�G���[
                                                    ,gv_tkn_profile   -- �g�[�N��'PROFILE'
                                                    ,gv_prf_start_day)-- XXCMN:�N�x�J�n����
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    gv_start_mmdd := lv_start_day; -- �N�x�J�n�����ɐݒ�
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
--#####################################  �Œ蕔 END   #############################################
--
  END get_profile_start_day;
--
  /***********************************************************************************
   * Procedure Name   : get_start_end_day
   * Description      : A-1-4 �N�x�J�n���E�I�������擾����
   ***********************************************************************************/
  PROCEDURE get_start_end_day(
    iv_forecast_year IN  VARCHAR2,            -- �N�x
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_start_end_day'; -- �v���O������
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
    -- ���͔N�x�{�N�x�J�n���t�őΏ۔N�x�J�n�N�������Z�o����
    gv_start_yyyymmdd := iv_forecast_year || '/' || gv_start_mmdd;
    gd_start_yyyymmdd := FND_DATE.STRING_TO_DATE(gv_start_yyyymmdd,'YYYY/MM/DD');
--
    -- �Ώ۔N�x�J�n�N������YYYYMMDD�̓��t�^�ł͂Ȃ��ꍇ�̓G���[�Ƃ���
    IF (gd_start_yyyymmdd IS NULL) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �Ώ۔N�x�J�n�N��������Ώ۔N�x�I���N�������Z�o����(+12����-1��)
    gd_end_yyyymmdd := ADD_MONTHS(gd_start_yyyymmdd,12)-1;
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
--#####################################  �Œ蕔 END   #############################################
--
  END get_start_end_day;
--
  /**********************************************************************************
   * Procedure Name   : get_keikaku_start_end_day
   * Description      : �v�揤�i�ΏۊJ�n�E�I���N�����擾(A-1-5)
   ***********************************************************************************/
  PROCEDURE get_keikaku_start_end_day(
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_keikaku_start_end_day'; -- �v���O������
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
    lv_keikaku_start_date    VARCHAR2(10);
    lv_keikaku_day           VARCHAR2(10);
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
    -- �N�C�b�N�R�[�h��񂩂�v�揤�i�Ώۊ��Ԃ��擾����
    SELECT xlv_v.meaning,          -- ���e
           xlv_v.description       -- �E�v
    INTO   lv_keikaku_start_date,  -- �J�n��
           lv_keikaku_day          -- ����
    FROM   xxcmn_lookup_values_v xlv_v
    WHERE  xlv_v.lookup_type = gv_cons_type_keikaku_term
      AND  ROWNUM            = 1;
--
    -- �v�揤�i�J�n��
    gd_keikaku_start_date := FND_DATE.STRING_TO_DATE(lv_keikaku_start_date,'YYYY/MM/DD');
--
    -- �s���ȓ��t���o�^����Ă�����G���[
    IF ( gd_keikaku_start_date IS NULL ) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_072   -- ���t�s���G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                                      -- '�v�揤�i�Ώۊ���'
                                                    ,gv_cons_keikaku_term
                                                    ,gv_tkn_value      -- �g�[�N��'VALUE'
                                                    ,lv_keikaku_start_date)  -- �J�n��
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v�揤�i�J�n���ɓ������v���X���Čv�揤�i�I�������Z�o����
    gd_keikaku_end_date := gd_keikaku_start_date + TO_NUMBER(lv_keikaku_day);
--
  EXCEPTION
    -- �N�C�b�N�R�[�h���擾�ł��Ȃ������ꍇ
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_060   -- �N�C�b�N�R�[�h�擾�G���[
                                                    ,gv_tkn_lup_type  -- �g�[�N��'LOOKUP_TYPE'
                                                    ,gv_cons_type_keikaku_term -- �v�揤�i�Ώۊ���
                                                    ,gv_tkn_meaning   -- �g�[�N��'MEANING'
                                                    ,gv_cons_keikaku_term)     -- �v�揤�i�Ώۊ���
                                                    ,1
                                                    ,5000);
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- TO_NUMBER()�ŕϊ��ł��Ȃ������ꍇ
    WHEN VALUE_ERROR THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                    ,gv_msg_10a_072   -- ���t�s���G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,gv_cons_days     -- '����'
                                                    ,gv_tkn_value     -- �g�[�N��'VALUE'
                                                    ,lv_keikaku_day)  -- ����
                                                    ,1
                                                    ,5000);
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END get_keikaku_start_end_day;
--
  /**********************************************************************************
   * Procedure Name   : get_dept_inf
   * Description      : �������̎擾(A-1-6)
   ***********************************************************************************/
  PROCEDURE get_dept_inf(
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_dept_inf'; -- �v���O������
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
    ln_login_user  NUMBER;  -- ���O�C�����[�U
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
    -- ���O�C�����[�U�̎擾
    ln_login_user := FND_GLOBAL.USER_ID;
--
    -- �S�������̎擾
    gv_location_short_name := xxcmn_common_pkg.get_user_dept(
                                ln_login_user);                           -- ���O�C�����[�U
--
    -- �G���[�̏ꍇ
    IF (gv_location_short_name IS NULL) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv       -- 'XXINV'
                                                    ,gv_msg_10a_025       -- �����R�[�h�擾�G���[
                                                    ,gv_tkn_user          -- �g�[�N��'USER'
                                                    ,ln_login_user)       -- ���O�C�����[�U�[
                                                    ,1
                                                    ,5000);
      RAISE parameter_expt;
    END IF;
--
    SELECT hla.location_code
    INTO  gv_location_code
    FROM  hr_locations_all hla
         ,FND_USER fu
         ,PER_ALL_PEOPLE_F papf
         ,PER_ALL_ASSIGNMENTS_F paaf
    WHERE fu.user_id       = ln_login_user
      AND fu.EMPLOYEE_ID   = papf.PERSON_ID
      AND papf.PERSON_ID   = paaf.PERSON_ID
      AND paaf.LOCATION_ID = hla.LOCATION_ID
      AND SYSDATE BETWEEN papf.effective_start_date AND NVL(papf.effective_end_date,SYSDATE)
      ;
--
  EXCEPTION
    WHEN parameter_expt THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  END get_dept_inf;
--
  /**********************************************************************************
   * Procedure Name   : if_data_null_check
   * Description      : A-*-0 �C���^�[�t�F�[�X�f�[�^���ڕK�{�`�F�b�N
   ***********************************************************************************/
  PROCEDURE if_data_null_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast����
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'if_data_null_check'; -- �v���O������
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
    ln_target_cnt  NUMBER;  -- �d�����Ă��錏��
    ln_loop_cnt    NUMBER;  -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ����v��p ############################################################################
    -- �C���^�[�t�F�[�X�e�[�u���d���f�[�^���o
    CURSOR forecast_if_cur1
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */               -- 2008/11/11 �����w�E#589 Add
             mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.location_code      IS NULL                    -- �o�׌��q��
        OR    mfi.base_code          IS NULL)                   -- ���_
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast����
        AND   mfi.created_by          = gn_created_by);         -- �쐬��=���O�C�����[�U
    -- *** ���[�J���E���R�[�h ***
    TYPE lr_forecast_if_rec1 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ���O�o�͂��邽�߂̃f�[�^���i�[���錋���z��
    TYPE forecast_tbl1 IS TABLE OF lr_forecast_if_rec1 INDEX BY PLS_INTEGER;
    lt_if_data1    forecast_tbl1;
--
    -- �v�揤�i�p ############################################################################
    -- �C���^�[�t�F�[�X�e�[�u���d���f�[�^���o
    CURSOR forecast_if_cur2
    IS
      SELECT mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.location_code      IS NULL                    -- �o�׌��q��
        OR    mfi.base_code          IS NULL)                   -- ���_
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast����
        AND   mfi.created_by          = gn_created_by);         -- �쐬��=���O�C�����[�U
    -- *** ���[�J���E���R�[�h ***
    TYPE lr_forecast_if_rec2 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ���O�o�͂��邽�߂̃f�[�^���i�[���錋���z��
    TYPE forecast_tbl2 IS TABLE OF lr_forecast_if_rec2 INDEX BY PLS_INTEGER;
    lt_if_data2    forecast_tbl2;
--
    -- �o�א�����A�p ###########################################################################
    -- �C���^�[�t�F�[�X�e�[�u���d���f�[�^���o
    CURSOR forecast_if_cur3
    IS
      SELECT mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE   mfi.base_code          IS NULL                    -- ���_
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast����
        AND   mfi.created_by          = gn_created_by);         -- �쐬��=���O�C�����[�U
    -- *** ���[�J���E���R�[�h ***
    TYPE lr_forecast_if_rec3 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ���O�o�͂��邽�߂̃f�[�^���i�[���錋���z��
    TYPE forecast_tbl3 IS TABLE OF lr_forecast_if_rec3 INDEX BY PLS_INTEGER;
    lt_if_data3    forecast_tbl3;
--
    -- �o�א�����B�p ###########################################################################
    -- �C���^�[�t�F�[�X�e�[�u���d���f�[�^���o
    CURSOR forecast_if_cur4
    IS
      SELECT mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.location_code      IS NULL                    -- �o�׌��q��
        OR    mfi.dept_code          IS NULL)                   -- �捞����
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast����
        AND   mfi.created_by          = gn_created_by);         -- �쐬��=���O�C�����[�U
    -- *** ���[�J���E���R�[�h ***
    TYPE lr_forecast_if_rec4 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ���O�o�͂��邽�߂̃f�[�^���i�[���錋���z��
    TYPE forecast_tbl4 IS TABLE OF lr_forecast_if_rec4 INDEX BY PLS_INTEGER;
    lt_if_data4    forecast_tbl4;
--
    -- �̔��v��p ###########################################################################
    -- �C���^�[�t�F�[�X�e�[�u���d���f�[�^���o
    CURSOR forecast_if_cur5
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */              -- 2008/11/11 �����w�E#589 Add
             mfi.forecast_if_id,
             mfi.forecast_designator,
             mfi.location_code,
             mfi.base_code,
             mfi.dept_code,
             mfi.item_code,
             mfi.forecast_date,
             mfi.forecast_end_date,
             mfi.case_quantity,
             mfi.indivi_quantity,
             mfi.amount,
             mfi.created_by,
             mfi.creation_date,
             mfi.last_updated_by,
             mfi.last_update_date,
             mfi.last_update_login,
             mfi.request_id,
             mfi.program_application_id,
             mfi.program_id,
             mfi.program_update_date
      FROM   xxinv_mrp_forecast_interface  mfi
      WHERE  (mfi.base_code          IS NULL                    -- ���_
        OR    mfi.amount             IS NULL)                   -- ���z
        AND  (mfi.forecast_designator = iv_forecast_designator  -- Forecast����
        AND   mfi.created_by          = gn_created_by);         -- �쐬��=���O�C�����[�U
    -- *** ���[�J���E���R�[�h ***
    TYPE lr_forecast_if_rec5 IS RECORD(
      forecast_if_id         xxinv_mrp_forecast_interface.forecast_if_id%TYPE,
      forecast_designator    xxinv_mrp_forecast_interface.forecast_designator%TYPE,
      location_code          xxinv_mrp_forecast_interface.location_code%TYPE,
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,
      dept_code              xxinv_mrp_forecast_interface.dept_code%TYPE,
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE,
      forecast_end_date      xxinv_mrp_forecast_interface.forecast_end_date%TYPE,
      case_quantity          xxinv_mrp_forecast_interface.case_quantity%TYPE,
      indivi_quantity        xxinv_mrp_forecast_interface.indivi_quantity%TYPE,
      amount                 xxinv_mrp_forecast_interface.amount%TYPE,
      created_by             xxinv_mrp_forecast_interface.created_by%TYPE,
      creation_date          xxinv_mrp_forecast_interface.creation_date%TYPE,
      last_updated_by        xxinv_mrp_forecast_interface.last_updated_by%TYPE,
      last_update_date       xxinv_mrp_forecast_interface.last_update_date%TYPE,
      last_update_login      xxinv_mrp_forecast_interface.last_update_login%TYPE,
      request_id             xxinv_mrp_forecast_interface.request_id%TYPE,
      program_application_id xxinv_mrp_forecast_interface.program_application_id%TYPE,
      program_id             xxinv_mrp_forecast_interface.program_id%TYPE,
      program_update_date    xxinv_mrp_forecast_interface.program_update_date%TYPE
    );
    -- ���O�o�͂��邽�߂̃f�[�^���i�[���錋���z��
    TYPE forecast_tbl5 IS TABLE OF lr_forecast_if_rec5 INDEX BY PLS_INTEGER;
    lt_if_data5    forecast_tbl5;
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
    -- Forecast���ނŕ��򂵂Ċe���ڂ̕K�{�`�F�b�N���s��
    -- ����v�� ############################################################################
    IF (iv_forecast_designator = gv_cons_fc_type_hikitori) THEN
      -- �J�[�\���I�[�v��
      OPEN forecast_if_cur1;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH forecast_if_cur1 BULK COLLECT INTO lt_if_data1;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_if_data1.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE forecast_if_cur1;
--
      -- NULL�f�[�^����̏ꍇ�̓f�[�^�����O�ɏo�͂���
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop1>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          -- �G���[�f�[�^�����̂��ďo��
          lv_errmsg := lt_if_data1(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data1(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_067)
                                                          -- ����v��K�{�`�F�b�N�G���[
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        END LOOP null_data_loop1;
        RAISE null_expt;
      END IF;
--
    -- �v�揤�i ############################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_keikaku) THEN
      -- �J�[�\���I�[�v��
      OPEN forecast_if_cur2;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH forecast_if_cur2 BULK COLLECT INTO lt_if_data2;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_if_data2.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE forecast_if_cur2;
--
      -- NULL�f�[�^����̏ꍇ�̓f�[�^�����O�ɏo�͂���
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop2>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data2(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data2(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_068)
                                                          -- �v�揤�i�K�{�`�F�b�N�G���[
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        END LOOP null_data_loop2;
        RAISE null_expt;
      END IF;
--
    -- �̔��v�� ###########################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
      -- �J�[�\���I�[�v��
      OPEN forecast_if_cur5;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH forecast_if_cur5 BULK COLLECT INTO lt_if_data5;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_if_data5.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE forecast_if_cur5;
--
      -- NULL�f�[�^����̏ꍇ�̓f�[�^�����O�ɏo�͂���
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop5>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data5(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data5(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_071)
                                                          -- �̔��v��K�{�`�F�b�N�G���[
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        END LOOP null_data_loop5;
        RAISE null_expt;
      END IF;
--
    -- �o�א�����A #########################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_a) THEN
      -- �J�[�\���I�[�v��
      OPEN forecast_if_cur3;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH forecast_if_cur3 BULK COLLECT INTO lt_if_data3;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_if_data3.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE forecast_if_cur3;
--
      -- NULL�f�[�^����̏ꍇ�̓f�[�^�����O�ɏo�͂���
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop3>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data3(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data3(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_069)
                                                          -- �o�א�����A�K�{�`�F�b�N�G���[
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        END LOOP null_data_loop3;
        RAISE null_expt;
      END IF;
--
    -- �o�א�����B #######################################################################
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_b) THEN
      -- �J�[�\���I�[�v��
      OPEN forecast_if_cur4;
--
      -- �f�[�^�̈ꊇ�擾
      FETCH forecast_if_cur4 BULK COLLECT INTO lt_if_data4;
--
      -- ���������̃Z�b�g
      ln_target_cnt := lt_if_data4.COUNT;
--
      -- �J�[�\���N���[�Y
      CLOSE forecast_if_cur4;
--
      -- NULL�f�[�^����̏ꍇ�̓f�[�^�����O�ɏo�͂���
      IF (ln_target_cnt > 0) THEN
        <<null_data_loop4>>
        FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
          lv_errmsg := lt_if_data4(ln_loop_cnt).forecast_if_id         || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).forecast_designator    || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).location_code          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).base_code              || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).dept_code              || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).item_code              || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).forecast_date          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).forecast_end_date      || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).case_quantity          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).indivi_quantity        || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).amount                 || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).created_by             || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).creation_date          || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).last_updated_by        || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).last_update_date       || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).last_update_login      || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).request_id             || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).program_application_id || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).program_id             || gv_msg_pnt ||
                       lt_if_data4(ln_loop_cnt).program_update_date;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                        ,gv_msg_10a_070)
                                                        -- �o�א�����B�K�{�`�F�b�N�G���[
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        END LOOP null_data_loop4;
        RAISE null_expt;
      END IF;
    END IF;
--
  EXCEPTION
    WHEN null_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END if_data_null_check;
--
  /**********************************************************************************
   * Procedure Name   : get_hikitori_if_data
   * Description      : ����v��C���^�[�t�F�[�X�f�[�^�擾(A-2-1)
   ***********************************************************************************/
  PROCEDURE get_hikitori_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hikitori_if_data'; -- �v���O������
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
    lr_forecast_tbl  forecast_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u���������v��f�[�^���o
    CURSOR forecast_if_cur
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */                      -- 2008/11/11 �����w�E#589 Add
             mfi.forecast_if_id         -- ���ID
            ,mfi.forecast_designator    -- Forecast����
            ,mfi.location_code          -- �o�בq��
            ,mfi.base_code              -- ���_
            ,mfi.dept_code              -- �捞����
            ,mfi.item_code              -- �i��
            ,mfi.forecast_date          -- �J�n���t
            ,mfi.forecast_end_date      -- �I�����t
            ,mfi.case_quantity          -- �P�[�X����
            ,mfi.indivi_quantity        -- �o������
            ,mfi.amount                 -- ���z
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_hikitori        -- '����v��'
        AND mfi.forecast_date BETWEEN gd_in_yyyymmdd_start AND gd_in_yyyymmdd_end   -- ���͔N��
        AND mfi.created_by = gn_created_by                            -- ���O�C�����[�U
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    lr_forecast_if_rec forecast_if_cur%ROWTYPE;
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
    -- ���������̏�����
    gn_target_cnt := 0;
--
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u���������v��f�[�^���o
    OPEN forecast_if_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
--
    -- ���������̃Z�b�g
    gn_target_cnt := io_if_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE forecast_if_cur;
--
    -- �f�[�^���Ȃ������ꍇ�͏I���X�e�[�^�X���x���Ƃ������𒆎~����
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- �Ώۃf�[�^�Ȃ�
                                                     ,gv_tkn_table      -- �g�[�N��'TABLE'
                                                     ,gv_if_table_jp
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,gv_tkn_key        -- �g�[�N��'KEY'
                                                     ,gv_cons_fc_type_hikitori)  -- '����v��'
                                                     ,1
                                                     ,5000);
-- add start 1.11
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- ���b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_ng_table   -- �g�[�N��'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** �Ώۃf�[�^�Ȃ� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- �x��
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
  END get_hikitori_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_hanbai_if_data
   * Description      : �̔��v��C���^�[�t�F�[�X�f�[�^���o(A-3-1)
   ***********************************************************************************/
  PROCEDURE get_hanbai_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hanbai_if_data'; -- �v���O������
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
    lr_forecast_tbl  forecast_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u������̔��v��f�[�^���o
    CURSOR forecast_if_cur
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n01 ) */                  -- 2008/11/11 �����w�E#589 Add
             mfi.forecast_if_id         -- ���ID
            ,mfi.forecast_designator    -- Forecast����
            ,mfi.location_code          -- �o�בq��
            ,mfi.base_code              -- ���_
            ,mfi.dept_code              -- �捞����
            ,mfi.item_code              -- �i��
            ,mfi.forecast_date          -- �J�n���t
            ,mfi.forecast_end_date      -- �I�����t
            ,mfi.case_quantity          -- �P�[�X����
            ,mfi.indivi_quantity        -- �o������
            ,mfi.amount                 -- ���z
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_hanbai      -- '�̔��v��'
        AND mfi.forecast_date      >= gd_start_yyyymmdd           -- �Ώ۔N�x�J�n��
        AND mfi.forecast_date      <= gd_end_yyyymmdd             -- �Ώ۔N�x�I����
-- 2009/04/08 v1.19 T.Yoshimoto Del Start �{��#1374
        --AND mfi.created_by          = gn_created_by               -- ���O�C�����[�U
-- 2009/04/08 v1.19 T.Yoshimoto Del End �{��#1374
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    lr_forecast_if_rec forecast_if_cur%ROWTYPE;
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
    -- ���������̏�����
    gn_target_cnt := 0;
--
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u���������v��f�[�^���o
    OPEN forecast_if_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
--
    -- ���������̃Z�b�g
    gn_target_cnt := io_if_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE forecast_if_cur;
--
    -- �f�[�^���Ȃ������ꍇ�͏I���X�e�[�^�X���x���Ƃ������𒆎~����
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- �Ώۃf�[�^�Ȃ�
                                                     ,gv_tkn_table      -- �g�[�N��'TABLE'
                                                     ,gv_if_table_jp
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,gv_tkn_key        -- �g�[�N��'KEY'
                                                     ,gv_cons_fc_type_hanbai) -- '�̔��v��'
                                                     ,1
                                                     ,5000);
-- add start 1.11
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_ng_table   -- �g�[�N��'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** �Ώۃf�[�^�Ȃ� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- �x��
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
  END get_hanbai_if_data;
--
--
  /**********************************************************************************
   * Procedure Name   : get_keikaku_if_data
   * Description      : A-4-1 �v�揤�i�C���^�[�t�F�[�X�f�[�^���o
   ***********************************************************************************/
  PROCEDURE get_keikaku_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_keikaku_if_data'; -- �v���O������
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
    lr_forecast_tbl  forecast_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u������v�揤�i�f�[�^���o
    CURSOR forecast_if_cur
    IS
      SELECT mfi.forecast_if_id         -- ���ID
            ,mfi.forecast_designator    -- Forecast����
            ,mfi.location_code          -- �o�בq��
            ,mfi.base_code              -- ���_
            ,mfi.dept_code              -- �捞����
            ,mfi.item_code              -- �i��
            ,mfi.forecast_date          -- �J�n���t
            ,mfi.forecast_end_date      -- �I�����t
            ,mfi.case_quantity          -- �P�[�X����
            ,mfi.indivi_quantity        -- �o������
            ,mfi.amount                 -- ���z
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_keikaku        -- '�v�揤�i'
        AND mfi.created_by          = gn_created_by                  -- ���O�C�����[�U
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    lr_forecast_if_rec forecast_if_cur%ROWTYPE;
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
    -- ���������̏�����
    gn_target_cnt := 0;
--
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u���������v��f�[�^���o
    OPEN forecast_if_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
--
    -- ���������̃Z�b�g
    gn_target_cnt := io_if_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE forecast_if_cur;
--
    -- �f�[�^���Ȃ������ꍇ�͏I���X�e�[�^�X���x���Ƃ������𒆎~����
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- �Ώۃf�[�^�Ȃ�
                                                     ,gv_tkn_table      -- �g�[�N��'TABLE'
                                                     ,gv_if_table_jp
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,gv_tkn_key        -- �g�[�N��'KEY'
                                                     ,gv_cons_fc_type_keikaku)  -- '�v�揤�i'
                                                     ,1
                                                     ,5000);
-- add start 1.11
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_ng_table   -- �g�[�N��'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** �Ώۃf�[�^�Ȃ� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- �x��
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
  END get_keikaku_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_seigen_a_if_data
   * Description      : A-5-1 �o�א�����A�C���^�[�t�F�[�X�f�[�^���o
   ***********************************************************************************/
  PROCEDURE get_seigen_a_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_seigen_a_if_data'; -- �v���O������
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
--    lr_forecast_tbl  forecast_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u������o�א�����A�f�[�^���o
    -- �i�ځ����_����
    CURSOR forecast_if_cur_i_b
    IS
      SELECT mfi.forecast_if_id         -- ���ID
            ,mfi.forecast_designator    -- Forecast����
            ,mfi.location_code          -- �o�בq��
            ,mfi.base_code              -- ���_
            ,mfi.dept_code              -- �捞����
            ,mfi.item_code              -- �i��
            ,mfi.forecast_date          -- �J�n���t
            ,mfi.forecast_end_date      -- �I�����t
            ,mfi.case_quantity          -- �P�[�X����
            ,mfi.indivi_quantity        -- �o������
            ,mfi.amount                 -- ���z
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '�o�א�����A'
--        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- ���̓p�����[�^�J�n���t
--        AND mfi.forecast_end_date = to_date(gv_in_end_date,'YYYY/MM/DD')-- ���̓p�����[�^�I�����t
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- ���̓p�����[�^�J�n���t
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- ���̓p�����[�^�I�����t
        AND mfi.item_code           = gv_in_item_code              -- ���̓p�����[�^�i��
        AND mfi.base_code           = gv_in_base_code              -- ���̓p�����[�^���_
        AND mfi.created_by          = gn_created_by                -- ���O�C�����[�U
      FOR UPDATE NOWAIT;
    -- �i�ڂ݂̂���
    CURSOR forecast_if_cur_i
    IS
      SELECT mfi.forecast_if_id         -- ���ID
            ,mfi.forecast_designator    -- Forecast����
            ,mfi.location_code          -- �o�בq��
            ,mfi.base_code              -- ���_
            ,mfi.dept_code              -- �捞����
            ,mfi.item_code              -- �i��
            ,mfi.forecast_date          -- �J�n���t
            ,mfi.forecast_end_date      -- �I�����t
            ,mfi.case_quantity          -- �P�[�X����
            ,mfi.indivi_quantity        -- �o������
            ,mfi.amount                 -- ���z
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '�o�א�����A'
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- ���̓p�����[�^�J�n���t
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- ���̓p�����[�^�I�����t
        AND mfi.item_code           = gv_in_item_code              -- ���̓p�����[�^�i��
        AND mfi.created_by          = gn_created_by                -- ���O�C�����[�U
      FOR UPDATE NOWAIT;
    -- ���_�݂̂���
    CURSOR forecast_if_cur_b
    IS
      SELECT mfi.forecast_if_id         -- ���ID
            ,mfi.forecast_designator    -- Forecast����
            ,mfi.location_code          -- �o�בq��
            ,mfi.base_code              -- ���_
            ,mfi.dept_code              -- �捞����
            ,mfi.item_code              -- �i��
            ,mfi.forecast_date          -- �J�n���t
            ,mfi.forecast_end_date      -- �I�����t
            ,mfi.case_quantity          -- �P�[�X����
            ,mfi.indivi_quantity        -- �o������
            ,mfi.amount                 -- ���z
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '�o�א�����A'
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- ���̓p�����[�^�J�n���t
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- ���̓p�����[�^�I�����t
        AND mfi.base_code           = gv_in_base_code              -- ���̓p�����[�^���_
        AND mfi.created_by          = gn_created_by                -- ���O�C�����[�U
      FOR UPDATE NOWAIT;
    -- �����Ȃ�
    CURSOR forecast_if_cur
    IS
      SELECT mfi.forecast_if_id         -- ���ID
            ,mfi.forecast_designator    -- Forecast����
            ,mfi.location_code          -- �o�בq��
            ,mfi.base_code              -- ���_
            ,mfi.dept_code              -- �捞����
            ,mfi.item_code              -- �i��
            ,mfi.forecast_date          -- �J�n���t
            ,mfi.forecast_end_date      -- �I�����t
            ,mfi.case_quantity          -- �P�[�X����
            ,mfi.indivi_quantity        -- �o������
            ,mfi.amount                 -- ���z
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.forecast_designator = gv_cons_fc_type_seigen_a     -- '�o�א�����A'
        AND mfi.forecast_date     = to_date(gv_in_start_date,'YYYY/MM/DD')-- ���̓p�����[�^�J�n���t
        AND mfi.forecast_end_date   = to_date(gv_in_end_date,'YYYY/MM/DD')-- ���̓p�����[�^�I�����t
        AND mfi.created_by          = gn_created_by                -- ���O�C�����[�U
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
    lr_forecast_if_rec_i_b forecast_if_cur_i_b%ROWTYPE;
    lr_forecast_if_rec_i   forecast_if_cur_i%ROWTYPE;
    lr_forecast_if_rec_b   forecast_if_cur_b%ROWTYPE;
    lr_forecast_if_rec     forecast_if_cur%ROWTYPE;
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
    -- ���������̏�����
    gn_target_cnt := 0;
--
    -- ���̓p�����[�^�C�Ӎ��ڂɂ��J�[�\�����g��������
    IF (( gv_in_item_code IS NOT NULL ) AND ( gv_in_base_code IS NOT NULL )) THEN
      OPEN  forecast_if_cur_i_b;
      FETCH forecast_if_cur_i_b BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur_i_b;
    ELSIF ( gv_in_item_code IS NOT NULL ) THEN
      OPEN  forecast_if_cur_i;
      FETCH forecast_if_cur_i BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur_i;
    ELSIF ( gv_in_base_code IS NOT NULL ) THEN
      OPEN  forecast_if_cur_b;
      FETCH forecast_if_cur_b BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur_b;
    ELSE
      OPEN  forecast_if_cur;
      FETCH forecast_if_cur BULK COLLECT INTO io_if_data;
      gn_target_cnt := io_if_data.COUNT;
      CLOSE forecast_if_cur;
    END IF;
--
    -- �f�[�^���Ȃ������ꍇ�͏I���X�e�[�^�X���x���Ƃ������𒆎~����
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_043    -- �Ώۃf�[�^�Ȃ�
                                                     ,gv_tkn_table      -- �g�[�N��'TABLE'
                                                     ,gv_if_table_jp
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,gv_tkn_key        -- �g�[�N��'KEY'
                                                     ,gv_cons_fc_type_seigen_a) -- '�o�א�����A'
                                                     ,1
                                                     ,5000);
-- add start 1.11
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_ng_table   -- �g�[�N��'NG_TABLE'
                                                     ,gv_if_table_jp)
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** �Ώۃf�[�^�Ȃ� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- �x��
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
  END get_seigen_a_if_data;
--
  /**********************************************************************************
   * Procedure Name   : get_seigen_b_if_data
   * Description      : A-6-1 �o�א�����B�C���^�[�t�F�[�X�f�[�^���o
   ***********************************************************************************/
  PROCEDURE get_seigen_b_if_data(
    io_if_data            IN OUT NOCOPY forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS 
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_seigen_b_if_data'; -- �v���O������
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
--mod start 1.6
--    lv_sql_buf VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf2 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf3 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf4 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf5 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf6 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf7 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf8 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf9 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf10 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
--    lv_sql_buf11 VARCHAR(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf2 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf3 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf4 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf5 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf6 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf7 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf8 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf9 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf10 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
    lv_sql_buf11 VARCHAR2(5000);  -- SQL���i�[�o�b�t�@
--mod end 1.6
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE cursor_type IS REF CURSOR;
    cur cursor_type;
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
    -- ���������̏�����
    gn_target_cnt := 0;
--
    -- ���ISQL�ɂ��A�捞�������o�t���O�E�C�ӓ��̓p�����[�^�̏�����t������
    lv_sql_buf := 'SELECT mfi.forecast_if_id, '              ||
                         'mfi.forecast_designator, '         ||
                         'mfi.location_code, '               ||
                         'mfi.base_code, '                   ||
                         'mfi.dept_code, '                   ||
                         'mfi.item_code, ';
    lv_sql_buf2 :=       'mfi.forecast_date, '               ||
                         'mfi.forecast_end_date, '           ||
                         'mfi.case_quantity, '               ||
                         'mfi.indivi_quantity, '             ||
                         'mfi.amount ';
    lv_sql_buf3 := 'FROM  xxinv_mrp_forecast_interface mfi ';
    lv_sql_buf5 :=  'WHERE mfi.forecast_designator = ' || '''' || gv_cons_fc_type_seigen_b || '''';
    lv_sql_buf6 :=   ' AND mfi.forecast_date       =
             to_date(' || '''' || gv_in_start_date || '''' || ',' || '''YYYY/MM/DD'')';
    lv_sql_buf7 :=   ' AND mfi.forecast_end_date   =
             to_date(' || '''' || gv_in_end_date   || '''' || ',' || '''YYYY/MM/DD'')';
--
    lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf5 || lv_sql_buf6 || lv_sql_buf7;
--
    -- �C�ӂ̓��̓p�����[�^�̓��͏�Ԃɂ�������t�����Ă���
    -- �i�ڂ����͂���Ă�����E�E�E
    IF (gv_in_item_code IS NOT NULL) THEN
      lv_sql_buf8 := --lv_sql_buf4 || 
                    ' AND mfi.item_code           = ' || '''' || gv_in_item_code || '''';
      lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf8;
    END IF;
    -- �o�ɑq�ɂ����͂���Ă�����E�E�E
    IF (gv_in_location_code IS NOT NULL) THEN
      lv_sql_buf9 := --lv_sql_buf4 || 
                    ' AND mfi.location_code       = ' || '''' || gv_in_location_code || '''';
      lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf9;
    END IF;
    -- ���̓p�����[�^�̎捞�������o�t���O��'Yes'�̏ꍇ�͎��Ə��R�[�h��t������
    IF (gv_in_dept_code_flg = gv_cons_flg_yes) THEN
      lv_sql_buf10 := --lv_sql_buf4 || 
                    ' AND mfi.dept_code           = ' || '''' || gv_location_code || '''';
      lv_sql_buf3 := lv_sql_buf3 || lv_sql_buf10;
    END IF;
   lv_sql_buf11 := ' AND mfi.created_by          = ' || gn_created_by ||
                  ' FOR UPDATE NOWAIT';
--
   lv_sql_buf := lv_sql_buf || lv_sql_buf2 ||lv_sql_buf3 || lv_sql_buf11;
--
    -- ******************************************************************
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u������o�א�����B�f�[�^���o
    -- ******************************************************************
    -- �J�[�\���I�[�v��
    OPEN cur FOR lv_sql_buf;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH cur BULK COLLECT INTO io_if_data;
--
    -- ���������̃Z�b�g
    gn_target_cnt := io_if_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE cur;
--
    -- �f�[�^���Ȃ������ꍇ�͏I���X�e�[�^�X���x���Ƃ������𒆎~����
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                    ,gv_msg_10a_043    -- �Ώۃf�[�^�Ȃ�
                                                    ,gv_tkn_table      -- �g�[�N��'TABLE'
                                                    ,gv_if_table_jp
                                                  -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                    ,gv_tkn_key        -- �g�[�N��'KEY'
                                                    ,gv_cons_fc_type_seigen_b) -- '�o�א�����B'
                                                    ,1
                                                    ,5000);
-- add start 1.11
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
      RAISE no_data;
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- �e�[�u�����b�N�ł��Ȃ�����
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn     -- 'XXCMN'
                                                     ,gv_msg_10a_044    -- �e�[�u�����b�N�G���[
                                                     ,gv_tkn_ng_table   -- �g�[�N��'NG_TABLE'
                                                     ,gv_if_table_jp)   
                                                    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u��
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN no_data THEN                           --*** �Ώۃf�[�^�Ȃ� ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;             -- �x��
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
  END get_seigen_b_if_data;
--
  /**********************************************************************************
   * Procedure Name   : shipped_date_start_check
   * Description      : 1.�o�ɑq�ɂ̓K�p���ƊJ�n���t�`�F�b�N
   ***********************************************************************************/
  PROCEDURE shipped_date_start_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast����
    iv_location_cd           IN  VARCHAR2,      -- �o�בq�ɃR�[�h 
    id_start_date_active     IN  DATE,          -- �J�n���t
    id_end_date_active       IN  DATE,          -- �I�����t
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'shipped_date_start_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
--
    -- OPM�ۊǏꏊ�}�X�^����ۊǑq��ID���擾����
    SELECT COUNT(xil_v.inventory_location_id)           -- �ۊǑq��ID
    INTO   ln_select_count
    FROM   xxcmn_item_locations2_v xil_v
    WHERE  xil_v.segment1 = iv_location_cd   -- �o�בq�ɃR�[�h
      AND  xil_v.date_from  <= id_start_date_active
      AND  ((xil_v.date_to  >= id_start_date_active) OR (xil_v.date_to IS NULL))
      AND  xil_v.disable_date IS NULL;
--
    -- �o�ɑq�ɂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv -- 'XXINV'
                                                    ,gv_msg_10a_023 -- �o�בq�ɑ��݃`�F�b�N�G���[
                                                    ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                    ,iv_location_cd) -- �o�ɑq��
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END shipped_date_start_check;
--
  /**********************************************************************************
   * Procedure Name   : shipped_class_check
   * Description      : 2.�o�ɑq�ɂ̏o�ɊǗ����敪�`�F�b�N
   ***********************************************************************************/
  PROCEDURE shipped_class_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast����
    iv_item_code             IN  VARCHAR2,      -- �i��
    iv_location_code         IN  VARCHAR2,        -- �o�בq�� 
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'shipped_class_check'; -- �v���O������
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
    lv_item_class    mtl_categories_b.segment1%TYPE;
    ln_select_count    NUMBER  := 0;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �i�ڂ̏��i�敪�𒊏o����
    SELECT icv.prod_class_code
    INTO   lv_item_class
    FROM   xxcmn_item_categories3_v icv
    WHERE  icv.item_no       = iv_item_code
      AND  ROWNUM            = 1;
--
    -- �i�ڂ̏��i�敪���h�����N�̏ꍇ
    IF (lv_item_class = gv_ship_ctl_id_drink) THEN
      SELECT COUNT(lv.location_id)              -- ���Ə�ID
      INTO   ln_select_count 
      FROM   xxcmn_item_locations_v       ilv,  -- OPM�ۊǏꏊ�}�X�^
             xxcmn_locations_v            lv    -- ���Ə����VIEW
      WHERE  ilv.segment1              = iv_location_code
        AND  ilv.location_id           = lv.location_id
        AND  lv.ship_mng_code         IN (gv_ship_ctl_id_drink, gv_ship_ctl_id_both)
        AND  ROWNUM                    = 1;
--
    -- �i�ڂ̏��i�敪�����[�t�̏ꍇ
    ELSIF (lv_item_class = gv_ship_ctl_id_leaf) THEN
      SELECT COUNT(lv.location_id)              -- ���Ə�ID
      INTO   ln_select_count 
      FROM   xxcmn_item_locations_v       ilv,  -- OPM�ۊǏꏊ�}�X�^
             xxcmn_locations_v            lv    -- ���Ə����VIEW
      WHERE  ilv.segment1              = iv_location_code
        AND  ilv.location_id           = lv.location_id
        AND  lv.ship_mng_code         IN (gv_ship_ctl_id_leaf, gv_ship_ctl_id_both)
        AND  ROWNUM                    = 1;
    END IF;
--
    -- �o�ɑq�ɂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ(Forecast���ނŏ������ʂɈႢ�͂Ȃ��j
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_026    -- �o�בq�ɊǗ����敪�G���[
                                                    ,gv_tkn_soko       -- �g�[�N��'SOKO'
                                                    ,iv_location_code  -- �o�ɑq��
                                                    ,gv_tkn_item       -- �g�[�N��'ITEM'
                                                    ,iv_item_code)     -- �i��
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- ���i�敪���擾�ł��Ȃ������ꍇ
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_061   -- ���i�敪�擾�G���[
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,iv_item_code)    -- �i�ڃR�[�h
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END shipped_class_check;
--
  /**********************************************************************************
   * Procedure Name   : base_code_exist_check
   * Description      : 3.���_�̑��݃`�F�b�N
   ***********************************************************************************/
  PROCEDURE base_code_exist_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast����
    iv_base_code             IN  VARCHAR2,      -- ���_ 
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'base_code_exist_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �ڋq�}�X�^����ڋqID���擾����
    SELECT COUNT(cca.cust_account_id)     -- �ڋqID
    INTO   ln_select_count
    FROM   xxcmn_cust_accounts_v  cca
    WHERE  cca.account_number      = iv_base_code
      AND  cca.customer_class_code = gv_cons_base_code
      AND  ROWNUM                  = 1;
--
    -- ���݂��Ȃ��ꍇ(Forecast���ނŏ������ʂɈႢ�͂Ȃ��j
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_024   -- ���_���݃`�F�b�N�G���[
                                                    ,gv_tkn_kyoten    -- �g�[�N��'KYOTEN'
                                                    ,iv_base_code)    -- ���_
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
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
  END base_code_exist_check;
--
--
  /**********************************************************************************
   * Procedure Name   : item_abolition_code_check
   * Description      : 4.�i�ڂ̔p�~�敪�`�F�b�N
   ***********************************************************************************/
  PROCEDURE item_abolition_code_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast����
    iv_item_code            IN  VARCHAR2,        -- �i��
    id_start_date_active    IN  DATE,            -- �J�n���t
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_abolition_code_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- OPM�i�ڃ}�X�^����i��ID���擾����
    SELECT COUNT(imv.item_id)     -- �i��ID
    INTO   ln_select_count
    FROM   xxcmn_item_mst2_v  imv  -- OPM�i�ڏ��view
    WHERE  imv.item_no            = iv_item_code
      AND  imv.start_date_active <= id_start_date_active
      AND  imv.end_date_active   >= id_start_date_active
      AND  ROWNUM                 = 1;
--
    -- �i�ڂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ(Forecast���ނŏ������ʂɈႢ�͂Ȃ��j
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_027  -- �i�ڋ敪�`�F�b�N���[�j���O
                                                    ,gv_tkn_item     -- �g�[�N��'ITEM'
                                                    ,iv_item_code)   -- �i��
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
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
  END item_abolition_code_check;
--
  /**********************************************************************************
   * Procedure Name   : item_class_check
   * Description      : 5.�i�ڂ̕i�ڋ敪�`�F�b�N
   ***********************************************************************************/
  PROCEDURE item_class_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast����
    iv_item_code             IN  VARCHAR2,      -- �i��
    id_start_date_active     IN  DATE,          -- �J�n���t
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_class_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �i��ID�𒊏o����
    SELECT COUNT(ic.item_id)
    INTO   ln_select_count
    FROM   xxcmn_item_categories_v  ic
    WHERE  ic.item_no         = iv_item_code
      AND  segment1           = gv_cons_item_product -- �i�ڋ敪���u���i�v
      AND  ROWNUM             = 1;

    -- �i�ڂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ(Forecast���ނŏ������ʂɈႢ�͂Ȃ��j
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_028  -- �i�ڋ敪�`�F�b�N���[�j���O
                                                    ,gv_tkn_item     -- �g�[�N��'ITEM'
                                                    ,iv_item_code)   -- �i��
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
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
  END item_class_check;
--
  /**********************************************************************************
   * Procedure Name   : item_date_start_check
   * Description      : 6.�i�ڂ̓K�p���ƊJ�n���t�`�F�b�N
   ***********************************************************************************/
  PROCEDURE item_date_start_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast����
    iv_item_code            IN  VARCHAR2,        -- �i��
    id_start_date_active    IN  DATE,            -- �J�n���t
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_date_start_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �i�ڃ}�X�^����i��ID���擾����
    SELECT COUNT(imv.item_id)
    INTO   ln_select_count
    FROM   xxcmn_item_mst2_v  imv   -- OPM�i�ڏ��View
    WHERE  imv.item_no            = iv_item_code
      AND  imv.start_date_active <= id_start_date_active
      AND  imv.end_date_active   >= id_start_date_active
      AND  ROWNUM                 = 1;
--
    -- �i�ڂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ(Forecast���ނŏ������ʂɈႢ�͂Ȃ��j
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_029  -- �i�ڑ��݃`�F�b�N���[�j���O
                                                    ,gv_tkn_item     -- �g�[�N��'ITEM'
                                                    ,iv_item_code)   -- �i��
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END item_date_start_check;
--
  /**********************************************************************************
   * Procedure Name   : item_date_year_check
   * Description      : 7.�i�ڂ̓K�p���ƔN�x�x���`�F�b�N
   ***********************************************************************************/
  PROCEDURE item_date_year_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast����
    iv_item_code            IN  VARCHAR2,        -- �i��
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_date_year_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �i��ID���擾����
    SELECT COUNT(imv.item_id)
    INTO   ln_select_count
    FROM   xxcmn_item_mst2_v  imv  -- OPM�i�ڏ��View2
    WHERE  imv.item_no             = iv_item_code
      AND  imv.start_date_active  <= gd_start_yyyymmdd
      AND  imv.end_date_active    >= gd_end_yyyymmdd
      AND  ROWNUM                  = 1;
--
    -- �i�ڂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �x���Ƃ��ă��^�[������
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_030  -- �i�ڔN�x�`�F�b�N���[�j���O
                                                    ,gv_tkn_item     -- �g�[�N��'ITEM'
                                                    ,iv_item_code)   -- �i��
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END item_date_year_check;
--
  /**********************************************************************************
   * Procedure Name   : item_standard_year_check
   * Description      : 8.�i�ڂ̕W�������K�p���ƔN�x�x���`�F�b�N
   ***********************************************************************************/
  PROCEDURE item_standard_year_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast����
    iv_item_code            IN  VARCHAR2,        -- �i��
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_standard_year_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �d��/�W�������w�b�_(�A�h�I��)����i��ID���擾����
--
    SELECT COUNT(pph.item_id)           -- �i��ID
    INTO   ln_select_count
    FROM   xxpo_price_headers   pph     -- �d��/�W�������w�b�_(�A�h�I��)
    WHERE  pph.price_type          = gv_cons_p_type_standard   -- '�W��'
      AND  pph.item_code           = iv_item_code
      AND  pph.start_date_active  <= gd_start_yyyymmdd
      AND  pph.end_date_active    >= gd_end_yyyymmdd
      AND  ROWNUM                  = 1;
--
    -- �i��ID���Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �x���Ƃ��ă��^�[������
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                             -- �i�ڕW�������N�x�`�F�b�N���[�j���O
                                                   ,gv_msg_10a_031
                                                   ,gv_tkn_item     -- �g�[�N��'ITEM'
                                                   ,iv_item_code)   -- �i��
                                                   ,1
                                                   ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END item_standard_year_check;
--
  /**********************************************************************************
   * Procedure Name   : item_forecast_check
   * Description      : 9.10.�i�ڂ̕����\���\�v�揤�i�Ώەi�ڂƓ��t�`�F�b�N
   ***********************************************************************************/
  PROCEDURE item_forecast_check(
    iv_forecast_designator   IN  VARCHAR2,      -- Forecast����
    iv_item_code             IN  VARCHAR2,      -- �i��
    iv_base_code             IN  VARCHAR2,      -- ���_
    iv_location_code         IN  VARCHAR2,      -- �o�בq��
    id_start_date_active     IN  DATE,          -- �J�n���t
    id_end_date_active       IN  DATE,          -- �I�����t
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_forecast_check'; -- �v���O������
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
    ln_select_count    NUMBER;          -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �����\���A�h�I���}�X�^����i�ڃR�[�h�𒊏o����
    SELECT COUNT(csr.item_code)             -- �i�ڃR�[�h
    INTO   ln_select_count
    FROM   xxcmn_sourcing_rules2_v   csr    -- �����\���A�h�I���}�X�^
    WHERE  csr.item_code          = iv_item_code
      AND  csr.base_code          = iv_base_code
      AND  csr.delivery_whse_code = iv_location_code
      AND  csr.plan_item_flag     = gn_cons_p_item_flag     -- 1(=�v�揤�i)
      AND  csr.start_date_active <= id_start_date_active
      AND  csr.end_date_active   >= id_end_date_active
      AND  ROWNUM                 = 1;
--
    -- �i��ID���Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �G���[�Ƃ��ă��^�[������
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv     -- 'XXINV'
                                                            -- �i�ڌv�揤�i���݃`�F�b�N���[�j���O
                                                    ,gv_msg_10a_032
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,iv_item_code)    -- �i��
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
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
  END item_forecast_check;
--
  /**********************************************************************************
   * Procedure Name   : item_not_regist_check
   * Description      : 11.�i�ڂ̕����\���\���o�^�̌x���`�F�b�N
   ***********************************************************************************/
  PROCEDURE item_not_regist_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    iv_item_code             IN  VARCHAR2,        -- �i��
    iv_base_code             IN  VARCHAR2,        -- ���_
    iv_location_code         IN  VARCHAR2,        -- �o�בq��
    id_start_date_active     IN  DATE,            -- �J�n���t
    id_end_date_active       IN  DATE,            -- �I�����t
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_not_regist_check'; -- �v���O������
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
    ln_select_count       NUMBER;     -- ���݃`�F�b�N�̂��߂̃J�E���^
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
    -- �����\���A�h�I���}�X�^���畨���\���A�h�I��ID���擾����
    SELECT COUNT(csr.sourcing_rules_id) -- �����\���A�h�I��ID
    INTO   ln_select_count
    FROM   xxcmn_sourcing_rules2_v  csr  -- �����\���A�h�I���}�X�^
    WHERE  csr.item_code          = iv_item_code
      AND  (csr.base_code          = NVL(iv_base_code,csr.base_code)
        OR
            csr.base_code          IS NULL )
      AND  (csr.delivery_whse_code = NVL(iv_location_code,csr.delivery_whse_code)  
        OR 
            csr.delivery_whse_code IS NULL )
      AND  csr.start_date_active <= id_start_date_active
      AND  csr.end_date_active   >= id_end_date_active
      AND  ROWNUM                 = 1;
--
    -- �i�ڂ��Ó��łȂ�(���݂��Ȃ�)�ꍇ(Forecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �x���Ƃ��ă��^�[������
    IF (ln_select_count = 0) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                           -- �i�ڕ����\�����݃`�F�b�N���[�j���O
                                                    ,gv_msg_10a_033
                                                    ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                    ,iv_item_code)    -- �i��
                                                    ,1
                                                    ,5000);
      RAISE warning_expt;
    END IF;
--
  EXCEPTION
    WHEN warning_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END item_not_regist_check;
--
  /**********************************************************************************
   * Procedure Name   : date_month_check
   * Description      : 12.���t�̑Ώی��`�F�b�N
   ***********************************************************************************/
  PROCEDURE date_month_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    id_start_date_active     IN  DATE,            -- �J�n���t
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_month_check'; -- �v���O������
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
    -- �N���̔�r�i���o�����J�n���t�̔N�����V�X�e�����t�̔N�����Â�������G���[�j
    IF (TO_CHAR(id_start_date_active,'YYYY/MM') < TO_CHAR(gd_sysdate_yyyymmdd,'YYYY/MM')) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- �J�n���t���Ó��łȂ��ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    WHEN date_error THEN                           --*** �N����r�G���[��O ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_034    -- �J�n���t�ߋ��N���G���[
                                                    ,gv_tkn_sdate      -- �g�[�N��'SDATE'
                                                    ,id_start_date_active)  -- �J�n���t
                                                    ,1
                                                    ,5000);
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
  END date_month_check;
--
  /**********************************************************************************
   * Procedure Name   : date_year_check
   * Description      : 13.���t�̑Ώ۔N�`�F�b�N
   ***********************************************************************************/
  PROCEDURE date_year_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    id_start_date_active     IN  DATE,            -- �J�n���t
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_year_check'; -- �v���O������
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
   ln_year     NUMBER;   -- �N�x
   ld_yyyymmdd DATE;
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
    -- ���̓p�����[�^�N�x�{�N�x�J�n����(�v���t�@�C��)���C���^�[�t�F�[�X�̊J�n���t��
    -- �Â�������G���[�Ƃ���B
    ld_yyyymmdd := FND_DATE.STRING_TO_DATE(gv_forecast_year || '/' || gv_start_mmdd, 'YYYY/MM/DD');
--
    IF (id_start_date_active < ld_yyyymmdd) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- �N���Ó��łȂ��ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �G���[�Ƃ��ă��^�[������
    WHEN date_error THEN                           --*** �N��r�G���[��O ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_035    -- �J�n���t�ߋ��N�x�G���[
                                                    ,gv_tkn_sdate      -- �g�[�N��'SDATE'
                                                    ,id_start_date_active)  -- �J�n���t
                                                    ,1
                                                    ,5000);
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
  END date_year_check;
--
  /**********************************************************************************
   * Procedure Name   : date_past_check
   * Description      : 14.���t�̉ߋ��`�F�b�N
   ***********************************************************************************/
  PROCEDURE date_past_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    id_start_date_active     IN  DATE,            -- �J�n���t
    id_end_date_active       IN  DATE,            -- �I�����t
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_past_check'; -- �v���O������
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
    -- �J�n���t�̉ߋ��`�F�b�N�i���o�����J�n���t�̂��V�X�e�����t���Â�������G���[�j
    IF (id_start_date_active < gd_sysdate_yyyymmdd) THEN
      RAISE date_error;
    END IF;
--
    -- �I�����t�̉ߋ��`�F�b�N�i���o�����I�����t�̂��V�X�e�����t���Â�������G���[�j
    IF (id_end_date_active < gd_sysdate_yyyymmdd) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- �N���Ó��łȂ��ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �x���Ƃ��ă��^�[������
    WHEN date_error THEN                           --*** �N��r�G���[��O ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                    ,gv_msg_10a_036  -- ���t�ߋ��`�F�b�N���[�j���O
                                                    ,gv_tkn_sdate    -- �g�[�N��'SDATE'
                                                    ,id_start_date_active -- �J�n���t
                                                    ,gv_tkn_edate    -- �g�[�N��'EDATE'
                                                    ,id_end_date_active)  -- �I�����t
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# �C�� #
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
  END date_past_check;
--
  /**********************************************************************************
   * Procedure Name   : start_date_range_check
   * Description      : 15.�J�n���t��1�����ȓ��`�F�b�N
   ***********************************************************************************/
  PROCEDURE start_date_range_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    id_start_date_active     IN  DATE,            -- �J�n���t
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_date_range_check'; -- �v���O������
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
    -- �J�n���t�̖����`�F�b�N�i���o�����J�n���t�̂��V�X�e�����t�{1������薢���Ȃ�x���j
    IF (id_start_date_active > ADD_MONTHS(gd_sysdate_yyyymmdd, 1)) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- �J�n���t���Ó��łȂ��ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �x���Ƃ��ă��^�[������
    WHEN date_error THEN                           --*** �N��r�G���[��O ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                              -- ���t1�����ȓ��`�F�b�N���[�j���O
                                                    ,gv_msg_10a_037
                                                    ,gv_tkn_sdate    -- �g�[�N��'SDATE'
                                                    ,id_start_date_active)    -- �J�n���t
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;                                            --# �C�� #
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
  END start_date_range_check;
--
  /**********************************************************************************
   * Procedure Name   : date_start_end_check
   * Description      : 16.���t�̊J�n���I���`�F�b�N
   ***********************************************************************************/
  PROCEDURE date_start_end_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    id_start_date_active     IN  DATE,            -- �J�n���t
    id_end_date_active       IN  DATE,            -- �I�����t
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'date_start_end_check'; -- �v���O������
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
    -- �J�n���t�ƏI�����t�̑召�`�F�b�N�i���o�����I�����t���J�n���t���ߋ��Ȃ�G���[�j
    IF (id_start_date_active > id_end_date_active) THEN
      RAISE date_error;
    END IF;
--
  EXCEPTION
    -- �J�n���t�ƏI�����t�̑召���Ó��łȂ��ꍇ�̌㏈���iForecast���ނŏ������ʂɈႢ�͂Ȃ��j
    -- �G���[�Ƃ��ă��^�[������
    WHEN date_error THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                    ,gv_msg_10a_038)   -- ���t�召��r�G���[
                                                    ,1
                                                    ,5000);
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
  END date_start_end_check;
--
--
  /**********************************************************************************
   * Procedure Name   : inventory_date_check
   * Description      : 17.�o�ɑq�ɋ��_�i�ړ��t�ł̏d���`�F�b�N
   ***********************************************************************************/
  PROCEDURE inventory_date_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast����
-- add start 1.11
    iv_item_code            IN  VARCHAR2,        -- �i��
-- add end 1.11
-- add start 1.12
    id_start_date           IN  DATE,            -- �J�n���t
-- add end 1.12
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inventory_date_check'; -- �v���O������
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
    ln_target_cnt  NUMBER;  -- �d�����Ă��錏��
    ln_loop_cnt    NUMBER;  -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �C���^�[�t�F�[�X�e�[�u���d���f�[�^���o
    CURSOR forecast_if_cur
    IS
-- mod start 1.12
--      SELECT mfi.location_code,              -- �o�בq��
--      SELECT /*+ INDEX(xxinv_mrp_forecast_interface,xxinv_mfi_n02) */           -- 2008/11/11 �����w�E#589 Del
      SELECT /*+ INDEX( mfi xxinv_mfi_n02 ) */                                    -- 2008/11/11 �����w�E#589 Add
            mfi.location_code,              -- �o�בq��
            mfi.base_code,                   -- ���_
            mfi.item_code,                   -- �i��
            mfi.forecast_date,               -- �J�n���t
            mfi.forecast_end_date            -- �I�����t
      FROM  xxinv_mrp_forecast_interface  mfi
      WHERE mfi.created_by          = gn_created_by   -- ���O�C�����[�U
--        AND mfi.forecast_designator = iv_forecast_designator
-- add start 1.11
        AND mfi.item_code           = iv_item_code
-- add end 1.11
        AND mfi.forecast_date       = id_start_date
        AND mfi.forecast_designator = iv_forecast_designator
-- mod end 1.12
      GROUP BY mfi.location_code,
            mfi.base_code,
            mfi.item_code,
            mfi.forecast_date,
            mfi.forecast_end_date
      HAVING COUNT(mfi.location_code) > 1;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE lr_forecast_if_rec IS RECORD(
      location_code         xxinv_mrp_forecast_interface.location_code%TYPE,    -- �o�בq��
      base_code             xxinv_mrp_forecast_interface.base_code%TYPE,        -- ���_
      item_code             xxinv_mrp_forecast_interface.item_code%TYPE,        -- �i��
      forecast_date         xxinv_mrp_forecast_interface.forecast_date%TYPE,    -- �J�n���t(DATE�^)
      forecast_end_date     xxinv_mrp_forecast_interface.forecast_end_date%TYPE -- �I�����t(DATE�^)
    );
--
    -- Forecast���t�e�[�u���ɓo�^���邽�߂̃f�[�^���i�[���錋���z��
    TYPE forecast_tbl IS TABLE OF lr_forecast_if_rec INDEX BY PLS_INTEGER;
    lt_if_data    forecast_tbl;
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
    -- �̔��v��/����v��C���^�[�t�F�[�X�e�[�u���ɍ쐬�ҁ����O�C�����[�U��
    -- �o�בq�ɁA���_�A�i�ځA�J�n���t�A�I�����t�ŏd�����Ă���f�[�^������΃G���[
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u������d���f�[�^���o
    OPEN forecast_if_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH forecast_if_cur BULK COLLECT INTO lt_if_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_if_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE forecast_if_cur;
--
    -- �d���f�[�^���Ȃ������ꍇ
    IF (ln_target_cnt = 0) THEN
      RAISE no_data;
      -- �d���f�[�^����̏ꍇ�̓f�[�^�����O�ɏo�͂���
    ELSE
      <<duplication_data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                      ,gv_msg_10a_039   -- �d���`�F�b�N�G���[�P
                                                      ,gv_tkn_soko      -- �g�[�N��'SOKO'
                                                      ,lt_if_data(ln_loop_cnt).location_code
                                                      ,gv_tkn_kyoten    -- �g�[�N��'KYOTEN'
                                                      ,lt_if_data(ln_loop_cnt).base_code
                                                      ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                      ,lt_if_data(ln_loop_cnt).item_code
                                                      ,gv_tkn_sdate     -- �g�[�N��'SDATE'
                                                      ,lt_if_data(ln_loop_cnt).forecast_date
                                                      ,gv_tkn_edate     -- �g�[�N��'EDATE'
                                                      ,lt_if_data(ln_loop_cnt).forecast_end_date)
                                                      ,1
                                                      ,5000);
      END LOOP duplication_data_loop;
      RAISE duplication;
    END IF;
--
  EXCEPTION
    WHEN duplication THEN  -- �d���f�[�^����̏ꍇ
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- �d�����Ă��Ȃ��̂Ő���I��
    WHEN no_data THEN
      NULL;
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
  END inventory_date_check;
--
  /**********************************************************************************
   * Procedure Name   : base_code_date_check
   * Description      : 18.���_�i�ړ��t�ł̏d���`�F�b�N
   ***********************************************************************************/
  PROCEDURE base_code_date_check(
    iv_forecast_designator  IN  VARCHAR2,        -- Forecast����
    iv_base_code            IN  VARCHAR2,        -- ���_
    iv_item_code            IN  VARCHAR2,        -- �i��
    id_start_date_active    IN  DATE,            -- �J�n���t
    ov_errbuf               OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'base_code_date_check'; -- �v���O������
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
    ln_target_cnt  NUMBER;  -- �d�����Ă��錏��
    ln_loop_cnt    NUMBER;  -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���_�A�i�ځA�J�n���t�ŏd�����Ă���f�[�^������΃G���[
    CURSOR forecast_if_cur
    IS
      SELECT /*+ INDEX( mfi xxinv_mfi_n03 ) */                         -- 2008/11/11 �����w�E#589 Add
             mfi.base_code,                    -- ���_
             mfi.item_code,                    -- �i��
             mfi.forecast_date                 -- �J�n���t
      FROM   xxinv_mrp_forecast_interface mfi
      WHERE  mfi.base_code     = iv_base_code
        AND  mfi.item_code     = iv_item_code
        AND  mfi.forecast_date = id_start_date_active
        AND  mfi.created_by    = gn_created_by   -- ���O�C�����[�U'
        AND mfi.forecast_designator = iv_forecast_designator
      GROUP BY mfi.base_code,                  -- ���_
               mfi.item_code,                  -- �i��
               mfi.forecast_date               -- �J�n���t
      HAVING COUNT(mfi.base_code) > 1;
--
    -- *** ���[�J���E���R�[�h ***
    TYPE lr_forecast_if_rec IS RECORD(
      base_code              xxinv_mrp_forecast_interface.base_code%TYPE,      -- ���_
      item_code              xxinv_mrp_forecast_interface.item_code%TYPE,      -- �i��
      forecast_date          xxinv_mrp_forecast_interface.forecast_date%TYPE   -- �J�n���t(DATE�^)
    );
--
    -- Forecast���t�e�[�u���ɓo�^���邽�߂̃f�[�^���i�[���錋���z��
    TYPE forecast_tbl IS TABLE OF lr_forecast_if_rec INDEX BY PLS_INTEGER;
    lt_if_data    forecast_tbl;
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
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u������d���f�[�^���o
    OPEN forecast_if_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH forecast_if_cur BULK COLLECT INTO lt_if_data;
--
    -- ���������̃Z�b�g
    ln_target_cnt := lt_if_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE forecast_if_cur;
--
    -- �d���f�[�^���Ȃ������ꍇ
    IF (ln_target_cnt = 0) THEN
      RAISE no_data;
      -- �d���f�[�^����̏ꍇ�̓f�[�^�����O�ɏo�͂���
    ELSE
      <<duplication_data_loop>>
      FOR ln_loop_cnt IN 1..ln_target_cnt LOOP
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                      ,gv_msg_10a_040   -- �d���`�F�b�N�G���[2
                                                      ,gv_tkn_kyoten    -- �g�[�N��'KYOTEN'
                                                      ,lt_if_data(ln_loop_cnt).base_code
                                                      ,gv_tkn_item      -- �g�[�N��'ITEM'
                                                      ,lt_if_data(ln_loop_cnt).item_code
                                                      ,gv_tkn_sdate     -- �g�[�N��'SDATE'
                                                      ,lt_if_data(ln_loop_cnt).forecast_date)
                                                      ,1
                                                      ,5000);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END LOOP duplication_data_loop;
      RAISE duplication;
    END IF;
--
  EXCEPTION
    WHEN duplication THEN                           --*** �d�����Ă���f�[�^���� ***
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- �d�����Ă��Ȃ��̂Ő���I��
    WHEN no_data THEN
      NULL;
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
  END base_code_date_check;
--
--
  /**********************************************************************************
   * Procedure Name   : quantity_num_check
   * Description      : 19.���ʂ̃}�C�i�X���l�`�F�b�N
   ***********************************************************************************/
  PROCEDURE quantity_num_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    in_case_quantity         IN  NUMBER,          -- �P�[�X����
    in_quantity              IN  NUMBER,          -- �o������
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'quantity_num_check'; -- �v���O������
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
    -- �P�[�X���ʂ��}�C�i�X��������G���[�Ƃ���
    IF (in_case_quantity < 0) THEN
      RAISE quantity_expt;
    END IF;
--
    -- �o�����ʂ��}�C�i�X��������G���[�Ƃ���
    IF (in_quantity < 0) THEN
      RAISE quantity_expt;
    END IF;
--
  EXCEPTION
--
   --*** �P�[�X���ʂ܂��̓o�����ʂ��}�C�i�X��O ***
    WHEN quantity_expt THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv       -- 'XXINV'
                                                    ,gv_msg_10a_041       -- ���l�`�F�b�N�G���[
                                                    ,gv_tkn_case          -- �g�[�N��'CASE'
                                                    ,in_case_quantity     -- �P�[�X����
                                                    ,gv_tkn_bara          -- �g�[�N��'BARA'
                                                    ,in_quantity)         -- �o������
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
--
    -- Forecast���ނ��u�̔��v��v�̂݃��[�j���O�Ƃ���i���̑��̓G���[�j
      IF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
        ov_retcode := gv_status_warn;
      ELSE
        ov_retcode := gv_status_error;
      END IF;
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
  END quantity_num_check;
--
  /**********************************************************************************
   * Procedure Name   : price_num_check
   * Description      : 20.���z�̃}�C�i�X���l�x���`�F�b�N
   ***********************************************************************************/
  PROCEDURE price_num_check(
    iv_forecast_designator   IN  VARCHAR2,        -- Forecast����
    in_amount                IN  NUMBER,          -- ���z
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'price_num_check'; -- �v���O������
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
    -- ���z���}�C�i�X��������G���[�Ƃ���
    IF (in_amount < 0) THEN
      RAISE amount_expt;
    END IF;
--
  EXCEPTION
    --*** ���z���}�C�i�X��O ***
    WHEN amount_expt THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                  ,gv_msg_10a_073)      -- ���l�`�F�b�N�G���[
                                                  ,1
                                                  ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END price_num_check;
--
  /**********************************************************************************
   * Procedure Name   : hikitori_data_check
   * Description      : ����v�撊�o�f�[�^�`�F�b�N(A-2-2)
   ***********************************************************************************/
  PROCEDURE hikitori_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- ��������IF�f�[�^�J�E���^
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'hikitori_data_check'; -- �v���O������
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
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
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
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 1.�o�ɑq�ɂ̓K�p���ƊJ�n���t�`�F�b�N
    shipped_date_start_check( -- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �o�בq��
                              in_if_data_tbl(in_if_data_cnt).location_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              -- �I�����t
                              in_if_data_tbl(in_if_data_cnt).end_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 2.�o�ɑq�ɂ̏o�ɊǗ����敪�`�F�b�N
   shipped_class_check( -- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- �i��
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- �o�בq��
                         in_if_data_tbl(in_if_data_cnt).location_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 3.���_�̑��݃`�F�b�N
    base_code_exist_check(-- Forecast����
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- ���_�R�[�h
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.�i�ڂ̔p�~�敪�`�F�b�N
    item_abolition_code_check(-- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �i��
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.�i�ڂ̕i�ڋ敪�`�F�b�N
    item_class_check( -- Forecast����
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- �i��
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- �J�n���t
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.�i�ڂ̓K�p���ƊJ�n���t�`�F�b�N
    item_date_start_check( -- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �i��
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 11.�i�ڂ̕����\���\���o�^�̌x���`�F�b�N
    item_not_regist_check( -- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �i��
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- ���_�R�[�h
                           in_if_data_tbl(in_if_data_cnt).base_code,
                           -- �o�בq��
                           in_if_data_tbl(in_if_data_cnt).location_code,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           -- �I�����t
                           in_if_data_tbl(in_if_data_cnt).end_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 12.���t�̑Ώی��`�F�b�N
    date_month_check( -- Forecast����
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- �J�n���t
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 17.�o�ɑq�ɋ��_�i�ړ��t�ł̏d���`�F�b�N
    inventory_date_check( -- Forecast����
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
-- add start 1.11
                          in_if_data_tbl(in_if_data_cnt).item_code,
-- add end 1.11
-- add start 1.12
                          in_if_data_tbl(in_if_data_cnt).start_date_active,
-- add end 1.12
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.���ʂ̃}�C�i�X���l�`�F�b�N
    quantity_num_check( -- Forecast����
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- �P�[�X����
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- �o������
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD Start --
    -- A-2-3 ����v��Forecast�����o
    -- (Forcast���`�F�b�N)
    get_f_degi_hikitori(    in_if_data_tbl  => in_if_data_tbl -- Forcast�o�^�p�z��
                          , in_if_data_cnt  => in_if_data_cnt -- �������̃f�[�^�J�E���^
                          , ov_errbuf       => lv_errbuf
                          , ov_retcode      => lv_retcode
                          , ov_errmsg       => lv_errmsg 
                        );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD End   --
    -- �e�`�F�b�N�ɂăG���[�܂��͌x�����������Ă����烊�^�[���l��
    -- �G���[�܂��͌x�����Z�b�g����B
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END hikitori_data_check;
--
  /**********************************************************************************
   * Procedure Name   : hanbai_data_check
   * Description      : �̔��v�撊�o�f�[�^�`�F�b�N(A-3-2)
   ***********************************************************************************/
  PROCEDURE hanbai_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- ��������IF�f�[�^�J�E���^
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'hanbai_data_check'; -- �v���O������
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
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
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
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 3.���_�̑��݃`�F�b�N
    base_code_exist_check(-- Forecast����
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- ���_�R�[�h
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.�i�ڂ̔p�~�敪�`�F�b�N
    item_abolition_code_check(-- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �i��
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.�i�ڂ̕i�ڋ敪�`�F�b�N
    item_class_check( -- Forecast����
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- �i��
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- �J�n���t
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 7.�i�ڂ̓K�p���ƔN�x�x���`�F�b�N
    item_date_year_check(-- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- �i��
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 8.�i�ڂ̕W�������K�p���ƔN�x�x���`�F�b�N
    item_standard_year_check(-- Forecast����
                             in_if_data_tbl(in_if_data_cnt).forecast_designator,
                             -- �i��
                             in_if_data_tbl(in_if_data_cnt).item_code,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 13.���t�̑Ώ۔N�`�F�b�N
    date_year_check(-- Forecast����
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- �J�n���t
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 18.���_�i�ړ��t�ł̏d���`�F�b�N
    base_code_date_check(-- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- ���_�R�[�h
                         in_if_data_tbl(in_if_data_cnt).base_code,
                         -- �i��
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- �J�n���t
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
-- mod start 1.11
--      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.���ʂ̃}�C�i�X���l�`�F�b�N
    quantity_num_check( -- Forecast����
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- �P�[�X���� 
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- �o������
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 20.���z�̃}�C�i�X���l�x���`�F�b�N
    price_num_check(-- Forecast����
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- ���z 
                    in_if_data_tbl(in_if_data_cnt).price,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- �e�`�F�b�N�ɂăG���[�܂��͌x�����������Ă����烊�^�[���l��
    -- �G���[�܂��͌x�����Z�b�g����B
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END hanbai_data_check;
--
  /**********************************************************************************
   * Procedure Name   : keikaku_data_check
   * Description      : �v�揤�i���o�f�[�^�`�F�b�N(A-4-2)
   ***********************************************************************************/
  PROCEDURE keikaku_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- ��������IF�f�[�^�J�E���^
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'keikaku_data_check'; -- �v���O������
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
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
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
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 1.�o�ɑq�ɂ̓K�p���ƊJ�n���t�`�F�b�N
    shipped_date_start_check( -- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �o�בq��
                              in_if_data_tbl(in_if_data_cnt).location_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              -- �I�����t
                              in_if_data_tbl(in_if_data_cnt).end_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 2.�o�ɑq�ɂ̏o�ɊǗ����敪�`�F�b�N
    shipped_class_check( -- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- �i��
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- �o�בq��
                         in_if_data_tbl(in_if_data_cnt).location_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 3.���_�̑��݃`�F�b�N
    base_code_exist_check(-- Forecast����
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- ���_�R�[�h
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.�i�ڂ̔p�~�敪�`�F�b�N
    item_abolition_code_check(-- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �i��
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.�i�ڂ̕i�ڋ敪�`�F�b�N
    item_class_check( -- Forecast����
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- �i��
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- �J�n���t
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.�i�ڂ̓K�p���ƊJ�n���t�`�F�b�N
    item_date_start_check( -- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �i��
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 9.10.�i�ڂ̕����\���\�v�揤�i�Ώەi�ڂƓ��t�`�F�b�N
    item_forecast_check(-- Forecast����
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- �i��
                        in_if_data_tbl(in_if_data_cnt).item_code,
                        -- ���_
                        in_if_data_tbl(in_if_data_cnt).base_code,
                        -- �o�בq��
                        in_if_data_tbl(in_if_data_cnt).location_code,
                        -- �J�n���t
                        in_if_data_tbl(in_if_data_cnt).start_date_active,
                        -- �I�����t
                        in_if_data_tbl(in_if_data_cnt).end_date_active,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 14.���t�̉ߋ��`�F�b�N
    date_past_check(-- Forecast����
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- �J�n���t
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    -- �I�����t
                    in_if_data_tbl(in_if_data_cnt).end_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 15.�J�n���t��1�����ȓ��`�F�b�N
    start_date_range_check(-- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 16.���t�̊J�n���I���`�F�b�N
    date_start_end_check(-- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- �J�n���t
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         -- �I�����t
                         in_if_data_tbl(in_if_data_cnt).end_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 17.�o�ɑq�ɋ��_�i�ړ��t�ł̏d���`�F�b�N
    inventory_date_check( -- Forecast����
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
-- add start 1.11
                          in_if_data_tbl(in_if_data_cnt).item_code,
-- add end 1.11
-- add start 1.12
                          in_if_data_tbl(in_if_data_cnt).start_date_active,
-- add end 1.12
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.���ʂ̃}�C�i�X���l�`�F�b�N
    quantity_num_check( -- Forecast����
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- �P�[�X����
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- �o������
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 �{�ԏ�Q#38 ADD Start --
    -- A-4-3 �v�揤�iForecast�����o
    -- (Forcast���̃`�F�b�N)
    get_f_degi_keikaku(   in_if_data_tbl  => in_if_data_tbl
                        , in_if_data_cnt  => in_if_data_cnt
                        , ov_errbuf       => lv_errbuf 
                        , ov_retcode      => lv_retcode
                        , ov_errmsg       => lv_errmsg 
                        );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 �{�ԏ�Q#38 ADD End   --

    -- �e�`�F�b�N�ɂăG���[�܂��͌x�����������Ă����烊�^�[���l��
    -- �G���[�܂��͌x�����Z�b�g����B
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END keikaku_data_check;
--
--
  /**********************************************************************************
   * Procedure Name   : seigen_a_data_check
   * Description      : �o�א�����A���o�f�[�^�`�F�b�N(A-5-2)
   ***********************************************************************************/
  PROCEDURE seigen_a_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- ��������IF�f�[�^�J�E���^
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'seigen_a_data_check'; -- �v���O������
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
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
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
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 3.���_�̑��݃`�F�b�N
    base_code_exist_check(-- Forecast����
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
                          -- ���_�R�[�h
                          in_if_data_tbl(in_if_data_cnt).base_code,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 4.�i�ڂ̔p�~�敪�`�F�b�N
    item_abolition_code_check(-- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �i��
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.�i�ڂ̕i�ڋ敪�`�F�b�N
    item_class_check( -- Forecast����
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- �i��
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- �J�n���t
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.�i�ڂ̓K�p���ƊJ�n���t�`�F�b�N
    item_date_start_check( -- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �i��
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 11.�i�ڂ̕����\���\���o�^�̌x���`�F�b�N
    item_not_regist_check( -- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �i��
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- ���_�R�[�h
                           in_if_data_tbl(in_if_data_cnt).base_code,
                           -- �o�בq��
                           in_if_data_tbl(in_if_data_cnt).location_code,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           -- �I�����t
                           in_if_data_tbl(in_if_data_cnt).end_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 14.���t�̉ߋ��`�F�b�N
    date_past_check(-- Forecast����
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- �J�n���t
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    -- �I�����t
                    in_if_data_tbl(in_if_data_cnt).end_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 15.�J�n���t��1�����ȓ��`�F�b�N
    start_date_range_check(-- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 16.���t�̊J�n���I���`�F�b�N
    date_start_end_check(-- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- �J�n���t
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         -- �I�����t
                         in_if_data_tbl(in_if_data_cnt).end_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 18.���_�i�ړ��t�ł̏d���`�F�b�N
    base_code_date_check(-- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- ���_�R�[�h
                         in_if_data_tbl(in_if_data_cnt).base_code,
                         -- �i��
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- �J�n���t
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.���ʂ̃}�C�i�X���l�`�F�b�N
    quantity_num_check( -- Forecast����
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- �P�[�X����
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- �o������
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�1
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD Start --
    -- A-5-3 �o�א�����AForecast�����o
    -- (Forcast���`�F�b�N)
    get_f_degi_seigen_a( in_if_data_tbl => in_if_data_tbl
                        ,in_if_data_cnt => in_if_data_cnt
                        ,ov_errbuf      => lv_errbuf
                        ,ov_retcode     => lv_retcode
                        ,ov_errmsg      => lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD End ----
--
    -- �e�`�F�b�N�ɂăG���[�܂��͌x�����������Ă����烊�^�[���l��
    -- �G���[�܂��͌x�����Z�b�g����B
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END seigen_a_data_check;
--
--
  /**********************************************************************************
   * Procedure Name   : seigen_b_data_check
   * Description      : �o�א�����B���o�f�[�^�`�F�b�N(A-6-2)
   ***********************************************************************************/
  PROCEDURE seigen_b_data_check(
    in_if_data_tbl        IN  forecast_tbl,
    in_if_data_cnt        IN  NUMBER,           -- ��������IF�f�[�^�J�E���^
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'seigen_b_data_check'; -- �v���O������
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
    ln_warn_cnt  NUMBER;
    ln_error_cnt NUMBER;
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
    ln_warn_cnt  := 0;
    ln_error_cnt := 0;
--
    -- 1.�o�ɑq�ɂ̓K�p���ƊJ�n���t�`�F�b�N
    shipped_date_start_check( -- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �o�בq�� 
                              in_if_data_tbl(in_if_data_cnt).location_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              -- �I�����t
                              in_if_data_tbl(in_if_data_cnt).end_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 2.�o�ɑq�ɂ̏o�ɊǗ����敪�`�F�b�N
    shipped_class_check( -- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- �i��
                         in_if_data_tbl(in_if_data_cnt).item_code,
                         -- �o�בq��
                         in_if_data_tbl(in_if_data_cnt).location_code,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 3.���_�̑��݃`�F�b�N
    IF (in_if_data_tbl(in_if_data_cnt).base_code IS NOT NULL) THEN
      base_code_exist_check(-- Forecast����
                            in_if_data_tbl(in_if_data_cnt).forecast_designator,
                            -- ���_�R�[�h
                            in_if_data_tbl(in_if_data_cnt).base_code,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg);
      -- �x������уG���[�ł���΃��O���o�͂��������s
      IF (lv_retcode <> gv_status_normal) THEN
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      END IF;
      -- �x������уG���[������ۑ�
      IF (lv_retcode = gv_status_warn) THEN
        ln_warn_cnt := 1;
      ELSIF (lv_retcode = gv_status_error) THEN
        ln_error_cnt := 1;
      END IF;
      -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
      IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
        -- �G���[������1�Ƃ��ė�O������
        gn_error_cnt := 1;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 4.�i�ڂ̔p�~�敪�`�F�b�N
    item_abolition_code_check(-- Forecast����
                              in_if_data_tbl(in_if_data_cnt).forecast_designator,
                              -- �i��
                              in_if_data_tbl(in_if_data_cnt).item_code,
                              -- �J�n���t
                              in_if_data_tbl(in_if_data_cnt).start_date_active,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 5.�i�ڂ̕i�ڋ敪�`�F�b�N
    item_class_check( -- Forecast����
                      in_if_data_tbl(in_if_data_cnt).forecast_designator,
                      -- �i��
                      in_if_data_tbl(in_if_data_cnt).item_code,
                      -- �J�n���t
                      in_if_data_tbl(in_if_data_cnt).start_date_active,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 6.�i�ڂ̓K�p���ƊJ�n���t�`�F�b�N
    item_date_start_check( -- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �i��
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 11.�i�ڂ̕����\���\���o�^�̌x���`�F�b�N
    item_not_regist_check( -- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �i��
                           in_if_data_tbl(in_if_data_cnt).item_code,
                           -- ���_�R�[�h
                           in_if_data_tbl(in_if_data_cnt).base_code,
                           -- �o�בq�� 
                           in_if_data_tbl(in_if_data_cnt).location_code,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           -- �I�����t 
                           in_if_data_tbl(in_if_data_cnt).end_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 14.���t�̉ߋ��`�F�b�N
    date_past_check(-- Forecast����
                    in_if_data_tbl(in_if_data_cnt).forecast_designator,
                    -- �J�n���t
                    in_if_data_tbl(in_if_data_cnt).start_date_active,
                    -- �I�����t
                    in_if_data_tbl(in_if_data_cnt).end_date_active,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 15.�J�n���t��1�����ȓ��`�F�b�N
    start_date_range_check(-- Forecast����
                           in_if_data_tbl(in_if_data_cnt).forecast_designator,
                           -- �J�n���t
                           in_if_data_tbl(in_if_data_cnt).start_date_active,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 16.���t�̊J�n���I���`�F�b�N
    date_start_end_check(-- Forecast����
                         in_if_data_tbl(in_if_data_cnt).forecast_designator,
                         -- �J�n���t
                         in_if_data_tbl(in_if_data_cnt).start_date_active,
                         -- �I�����t
                         in_if_data_tbl(in_if_data_cnt).end_date_active,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 17.�o�ɑq�ɋ��_�i�ړ��t�ł̏d���`�F�b�N
    inventory_date_check( -- Forecast����
                          in_if_data_tbl(in_if_data_cnt).forecast_designator,
-- add start 1.11
                          in_if_data_tbl(in_if_data_cnt).item_code,
-- add end 1.11
-- add start 1.12
                          in_if_data_tbl(in_if_data_cnt).start_date_active,
-- add end 1.12
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
    -- 19.���ʂ̃}�C�i�X���l�`�F�b�N
    quantity_num_check( -- Forecast����
                        in_if_data_tbl(in_if_data_cnt).forecast_designator,
                        -- �P�[�X����
                        in_if_data_tbl(in_if_data_cnt).case_quantity,
                        -- �o������
                        in_if_data_tbl(in_if_data_cnt).quantity,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
--
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD Start --
    -- A-6-3 �o�א�����BForecast�����o
    -- (Forcast���`�F�b�N)
    get_f_degi_seigen_b( in_if_data_tbl => in_if_data_tbl -- Forcast�o�^�p�z��
                        ,in_if_data_cnt => in_if_data_cnt -- �������̃f�[�^�J�E���^
                        ,ov_errbuf      => lv_errbuf
                        ,ov_retcode     => lv_retcode
                        ,ov_errmsg      => lv_errmsg
    );
    -- �x������уG���[�ł���΃��O���o�͂��������s
    IF (lv_retcode <> gv_status_normal) THEN
      if_data_disp( in_if_data_tbl, in_if_data_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
    END IF;
    -- �x������уG���[������ۑ�
    IF (lv_retcode = gv_status_warn) THEN
      ln_warn_cnt := 1;
    ELSIF (lv_retcode = gv_status_error) THEN
      ln_error_cnt := 1;
    END IF;
    -- �V�X�e���G���[(�I���N���G���[)�̏ꍇ�͂����ŏ����𒆎~���ăG���[���^�[������B
    IF ((lv_retcode = gv_status_error ) AND ( lv_errmsg IS NULL )) THEN
      -- �G���[������1�Ƃ��ė�O������
      gn_error_cnt := 1;
      RAISE global_api_expt;
    END IF;
-- 2009/02/17 �{�ԏ�Q#38�Ή� ADD End ----
--
    -- �e�`�F�b�N�ɂăG���[�܂��͌x�����������Ă����烊�^�[���l��
    -- �G���[�܂��͌x�����Z�b�g����B
    IF (ln_warn_cnt > 0) THEN
      ov_retcode := gv_status_warn;
      gn_warn_cnt := gn_warn_cnt + 1;
      gn_no_msg_disp := 1;
    END IF;
    IF (ln_error_cnt > 0) THEN
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      gn_no_msg_disp := 1;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END seigen_b_data_check;
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_hikitori
   * Description      : A-2-3 ����v��Forecast�����o
   ***********************************************************************************/
  PROCEDURE get_f_degi_hikitori(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_hikitori'; -- �v���O������
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
    -- Forecast���̒��o
    SELECT  mfd.forecast_designator,                   -- Forecast��
            mfd.organization_id                        -- �݌ɑg�DID
    INTO    gv_3f_forecast_designator,                 -- Forecast��
            gn_3f_organization_id                      -- �݌ɑg�D
    FROM    mrp_forecast_designators  mfd            -- Forecast���e�[�u��
    WHERE   mfd.attribute1 = gv_cons_fc_type_hikitori  -- Forecast����('����v��')
      AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code          -- �o�בq��
      AND   mfd.attribute3 = in_if_data_tbl(in_if_data_cnt).base_code;             -- ���_
--
  EXCEPTION
    -- Forecast�����Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- ����v��t�H�[�L���X�g���擾�G���[
                                                    ,gv_msg_10a_017
                                                    ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                                    -- �o�ɑq��
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_kyoten  -- �g�[�N��'KYOTEN'
                                                                    -- ���_
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- Forecast���������q�b�g�����ꍇ�̌㏈��
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- ����v��t�H�[�L���X�g���d���G���[
                                                    ,gv_msg_10a_062
                                                    ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                                    -- �o�ɑq��
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_kyoten  -- �g�[�N��'KYOTEN'
                                                                    -- ���_
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
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
  END get_f_degi_hikitori;
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_hanbai
   * Description      : A-3-3 �̔��v��Forecast�����o
   ***********************************************************************************/
  PROCEDURE get_f_degi_hanbai(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_hanbai'; -- �v���O������
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
    -- Forecast���̒��o
    SELECT  mfd.forecast_designator,                   -- Forecast��
            mfd.organization_id                        -- �݌ɑg�DID
    INTO    gv_3f_forecast_designator,                 -- Forecast��
            gn_3f_organization_id                      -- �݌ɑg�D
    FROM    mrp_forecast_designators  mfd            -- Forecast���e�[�u��
    WHERE   mfd.attribute1 = gv_cons_fc_type_hanbai    -- Forecast����('�̔��v��')
      AND   mfd.attribute6 = gv_forecast_year          -- �N�x
      AND   mfd.attribute5 = gv_forecast_version;      -- ����
--
  EXCEPTION
    -- Forecast�����Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
                                                             -- �̔��v��t�H�[�L���X�g���擾�G���[
                                                    ,gv_msg_10a_018)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- Forecast���������q�b�g�����ꍇ�̌㏈��
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- �̔��v��t�H�[�L���X�g���d���G���[
                                                    ,gv_msg_10a_063
                                                    ,gv_tkn_nendo    -- �g�[�N��'NENDO'
                                                                     -- �N�x
                                                    ,gv_forecast_year
                                                    ,gv_tkn_sedai    -- �g�[�N��'SEDAI'
                                                                     -- ����
                                                    ,gv_forecast_version)
                                                    ,1
                                                    ,5000);
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
  END get_f_degi_hanbai;
--
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_keikaku
   * Description      : A-4-3 �v�揤�iForecast�����o
   ***********************************************************************************/
  PROCEDURE get_f_degi_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_keikaku'; -- �v���O������
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
    -- Forecast���̒��o
    SELECT  mfd.forecast_designator,                      -- Forecast��
            mfd.organization_id                           -- �݌ɑg�DID
    INTO    gv_3f_forecast_designator,                    -- Forecast��
            gn_3f_organization_id                         -- �݌ɑg�D
    FROM    mrp_forecast_designators  mfd               -- Forecast���e�[�u��
    WHERE   mfd.attribute1 = gv_cons_fc_type_keikaku      -- Forecast����('�v�揤�i')
      AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code  -- �o�בq��
      AND   mfd.attribute3 = in_if_data_tbl(in_if_data_cnt).base_code;     -- ���_
--7
  EXCEPTION
    -- Forecast�����Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN                           --*** �f�[�^�Ȃ���O ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv    -- 'XXINV'
                                                            -- �v�揤�i�t�H�[�L���X�g���擾�G���[
                                                     ,gv_msg_10a_058
                                                     ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                                               -- �o�ɑq��
                                                     ,in_if_data_tbl(in_if_data_cnt).location_code
                                                     ,gv_tkn_kyoten  -- �g�[�N��'KYOTEN'
                                                                               -- ���_
                                                     ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- Forecast���������q�b�g�����ꍇ�̌㏈��
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                            -- �v�揤�i�t�H�[�L���X�g���d���G���[
                                                    ,gv_msg_10a_066
                                                    ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                                    -- �o�ɑq��
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_kyoten  -- �g�[�N��'KYOTEN'
                                                                    -- ���_
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
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
  END get_f_degi_keikaku;
--
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_seigen_a
   * Description      : A-5-3 �o�א�����AForecast�����o
   ***********************************************************************************/
  PROCEDURE get_f_degi_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_seigen_a'; -- �v���O������
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
    -- Forecast���̒��o
    SELECT  mfd.forecast_designator,                      -- Forecast��
            mfd.organization_id                           -- �݌ɑg�DID
    INTO    gv_3f_forecast_designator,                    -- Forecast��
            gn_3f_organization_id                         -- �݌ɑg�D
    FROM    mrp_forecast_designators  mfd               -- Forecast���e�[�u��
    WHERE   mfd.attribute1 = gv_cons_fc_type_seigen_a     -- Forecast����('�o�א�����A')
      AND   mfd.attribute3 = in_if_data_tbl(in_if_data_cnt).base_code;   -- ���_
--
  EXCEPTION
    -- Forecast�����Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                         -- �o�א�����A�t�H�[�L���X�g���擾�G���[
                                                    ,gv_msg_10a_019
                                                    ,gv_tkn_kyoten  -- �g�[�N��'KYOTEN'
                                                                    -- '���_'
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- Forecast���������q�b�g�����ꍇ�̌㏈��
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                          -- �o�א�����A�t�H�[�L���X�g���d���G���[
                                                    ,gv_msg_10a_064
                                                    ,gv_tkn_kyoten  -- �g�[�N��'KYOTEN'
                                                                    -- ���_
                                                    ,in_if_data_tbl(in_if_data_cnt).base_code)
                                                    ,1
                                                    ,5000);
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
  END get_f_degi_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : get_f_degi_seigen_b
   * Description      : A-6-3 �o�א�����BForecast�����o
   ***********************************************************************************/
  PROCEDURE get_f_degi_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_degi_seigen_b'; -- �v���O������
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
    -- ���̓p�����[�^�̎捞�������o�t���O��'Yes'�̏ꍇ
    IF (gv_in_dept_code_flg = gv_cons_flg_yes) THEN
--
      -- Forecast���̒��o
      SELECT  mfd.forecast_designator,                      -- Forecast��
              mfd.organization_id                           -- �݌ɑg�DID
      INTO    gv_3f_forecast_designator,                    -- Forecast��
              gn_3f_organization_id                         -- �݌ɑg�D
      FROM    mrp_forecast_designators  mfd               -- Forecast���e�[�u��
      WHERE   mfd.attribute1 = gv_cons_fc_type_seigen_b     -- Forecast����('�o�א�����B')
        AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code  -- �o�בq��
        AND   mfd.attribute4 = in_if_data_tbl(in_if_data_cnt).dept_code      -- �捞����
        AND   mfd.attribute4 = gv_location_code;            -- ���Ə��R�[�h
--
    -- ���̓p�����[�^�̎捞�������o�t���O��'No'�̏ꍇ
    ELSE
      -- Forecast���̒��o
      SELECT  mfd.forecast_designator,                      -- Forecast��
              mfd.organization_id                           -- �݌ɑg�DID
      INTO    gv_3f_forecast_designator,                    -- Forecast��
              gn_3f_organization_id                         -- �݌ɑg�D
      FROM    mrp_forecast_designators  mfd               -- Forecast���e�[�u��
      WHERE   mfd.attribute1 = gv_cons_fc_type_seigen_b     -- Forecast����('�o�א�����B')
        AND   mfd.attribute2 = in_if_data_tbl(in_if_data_cnt).location_code  -- �o�בq��
        AND   mfd.attribute4 = in_if_data_tbl(in_if_data_cnt).dept_code;     -- �捞����
    END IF;
--
  EXCEPTION
    -- Forecast�����Ó��łȂ�(���݂��Ȃ�)�ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN                           --*** �f�[�^�Ȃ���O ***
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                         -- �o�א�����B�t�H�[�L���X�g���擾�G���[
                                                    ,gv_msg_10a_020
                                                    ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                                    -- �o�ɑq��
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_busho   -- �g�[�N��'BUSHO'
                                                                    -- '�捞����'
                                                    ,in_if_data_tbl(in_if_data_cnt).dept_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
--
    -- Forecast���������q�b�g�����ꍇ�̌㏈��
    WHEN TOO_MANY_ROWS THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                          -- �o�א�����B�t�H�[�L���X�g���d���G���[
                                                    ,gv_msg_10a_065
                                                    ,gv_tkn_soko    -- �g�[�N��'SOKO'
                                                                    -- �o�ɑq��
                                                    ,in_if_data_tbl(in_if_data_cnt).location_code
                                                    ,gv_tkn_busho   -- �g�[�N��'BUSHO'
                                                                    -- �捞����
                                                    ,in_if_data_tbl(in_if_data_cnt).dept_code)
                                                    ,1
                                                    ,5000);
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
  END get_f_degi_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_hikitori
   * Description      : A-2-4 ����v��Forecast���t���o
   ***********************************************************************************/
  PROCEDURE get_f_dates_hikitori(
    ov_data_flg              OUT NUMBER,          -- �폜�Ώ�(1:����, 0:�Ȃ�)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_hikitori'; -- �v���O������
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
  lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- ���ID
  lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast��
  lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- �݌ɑg�D
  lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- �i��
  ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- �J�n���t
  ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- �I�����t
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
    -- �Ώۃf�[�^�L�薳���t���O�̏����f�[�^�Z�b�g�i����j
    ov_data_flg := gn_cons_data_found;
--
    -- ���炢�����Ώۃf�[�^�̒��o
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
            mfd.rate_end_date            -- �I�����t
    INTO    lv_4f_txns_id,               -- ���ID
            lv_4f_forecast_designator,   -- Forecast��
            lv_4f_organization_id,       -- �݌ɑg�D
            lv_4f_item_id,               -- �i��
            ld_4f_start_date_active,     -- �J�n���t
            ld_4f_end_date_active        -- �I�����t
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi    -- Forecast�i��
    WHERE   mfd.forecast_designator      = gv_3f_forecast_designator   -- Forecast��
      AND   mfd.organization_id          = gn_3f_organization_id       -- �݌ɑg�D
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gv_in_yyyymm  -- ���͔N��
      AND   mfd.organization_id          = mfi.organization_id
      AND   mfd.inventory_item_id        = mfi.inventory_item_id
      AND   ROWNUM                       = 1;
--
  EXCEPTION
    -- �폜�Ώۃf�[�^���Ȃ��ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN                        --*** �f�[�^�Ȃ���O ***
      ov_data_flg :=  gn_cons_no_data_found;       -- �Ώۃf�[�^�L�薳���t���O�Ɂu�Ȃ��v���Z�b�g
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
  END get_f_dates_hikitori;
--
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_hanbai
   * Description      : A-3-4 �̔��v��Forecast���t���o
   ***********************************************************************************/
  PROCEDURE get_f_dates_hanbai(
    ov_data_flg              OUT NUMBER,          -- �폜�Ώ�(1:����, 0:�Ȃ�)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_hanbai'; -- �v���O������
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
    lb_retcode                  BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--add start 1.8
    CURSOR cur_del_if IS
      SELECT  mfd.transaction_id,          -- ���ID
              mfd.forecast_designator,     -- Forecast��
              mfd.organization_id,         -- �݌ɑg�DID
              mfd.inventory_item_id,       -- �i��ID
              mfd.forecast_date,           -- �J�n���t
              mfd.rate_end_date            -- �I�����t
      FROM    mrp_forecast_dates  mfd,   -- Forecast���t
              mrp_forecast_items  mfi    -- Forecast�i��
      WHERE   mfd.forecast_designator        = gv_3f_forecast_designator   -- Forecast��
        AND   mfd.organization_id            = gn_3f_organization_id       -- �݌ɑg�D
        AND   mfd.forecast_designator        = mfi.forecast_designator
        AND   mfd.organization_id            = mfi.organization_id
        AND   mfd.inventory_item_id          = mfi.inventory_item_id
      ;
--
    TYPE lr_del_if IS RECORD(
      transaction_id       mrp_forecast_dates.transaction_id%TYPE
     ,forecast_designator  mrp_forecast_dates.forecast_designator%TYPE
     ,organization_id      mrp_forecast_dates.organization_id%TYPE
     ,inventory_item_id    mrp_forecast_dates.inventory_item_id%TYPE
     ,forecast_date        mrp_forecast_dates.forecast_date%TYPE
     ,rate_end_date        mrp_forecast_dates.rate_end_date%TYPE
    );
--
    TYPE lt_del_if_tbl IS TABLE OF lr_del_if INDEX BY BINARY_INTEGER;
    lt_del_if lt_del_if_tbl;
--add end 1.8
--
    -- *** ���[�J���E���R�[�h ***
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
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
    -- �Ώۃf�[�^�L�薳���t���O�̏����f�[�^�Z�b�g�i����j
    ov_data_flg := gn_cons_data_found;
--
--mod start 1.8
/*
    -- ���炢�����Ώۃf�[�^�̒��o
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
            mfd.rate_end_date            -- �I�����t
    INTO    gv_4h_txns_id,               -- ���ID
            gv_4h_forecast_designator,   -- Forecast��
            gv_4h_organization_id,       -- �݌ɑg�D
            gv_4h_item_id,               -- �i��
            gd_4h_start_date_active,     -- �J�n���t
            gd_4h_end_date_active        -- �I�����t
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi    -- Forecast�i��
    WHERE   mfd.forecast_designator        = gv_3f_forecast_designator   -- Forecast��
      AND   mfd.organization_id            = gn_3f_organization_id       -- �݌ɑg�D
and mfd.FORECAST_DESIGNATOR = mfi.FORECAST_DESIGNATOR
      AND   mfd.organization_id            = mfi.organization_id
      AND   mfd.inventory_item_id          = mfi.inventory_item_id
      AND   ROWNUM                         = 1;

--
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
      t_forecast_interface_tab_del(1).transaction_id        := gv_4h_txns_id;            -- ���ID
      t_forecast_interface_tab_del(1).forecast_designator   := gv_4h_forecast_designator;-- Forecast��
      t_forecast_interface_tab_del(1).organization_id       := gv_4h_organization_id;    -- �g�DID
      t_forecast_interface_tab_del(1).inventory_item_id     := gv_4h_item_id;            -- �i��ID
      t_forecast_interface_tab_del(1).quantity              := 0;                        -- ����
      t_forecast_interface_tab_del(1).forecast_date         := gd_4h_start_date_active;  -- �J�n���t
      t_forecast_interface_tab_del(1).forecast_end_date     := gd_4h_end_date_active;    -- �I�����t
      t_forecast_interface_tab_del(1).bucket_type           := 1;
      t_forecast_interface_tab_del(1).process_status        := 2;
      t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
*/
    OPEN cur_del_if;
    FETCH cur_del_if BULK COLLECT INTO lt_del_if;
    CLOSE cur_del_if;
--
    FOR i IN 1..lt_del_if.COUNT LOOP
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
      t_forecast_interface_tab_del(i).transaction_id        := lt_del_if(i).transaction_id;    -- ���ID
      t_forecast_interface_tab_del(i).forecast_designator   := gv_3f_forecast_designator;      -- Forecast��
      t_forecast_interface_tab_del(i).organization_id       := gn_3f_organization_id;          -- �g�DID
      t_forecast_interface_tab_del(i).inventory_item_id     := lt_del_if(i).inventory_item_id; -- �i��ID
      t_forecast_interface_tab_del(i).quantity              := 0;                              -- ����
      t_forecast_interface_tab_del(i).forecast_date         := lt_del_if(i).forecast_date;     -- �J�n���t
      t_forecast_interface_tab_del(i).forecast_end_date     := lt_del_if(i).rate_end_date;     -- �I�����t
      t_forecast_interface_tab_del(i).bucket_type           := 1;
      t_forecast_interface_tab_del(i).process_status        := 2;
      t_forecast_interface_tab_del(i).confidence_percentage := 100;
    END LOOP;
--mod end 1.8
      -- �o�^�ς݃f�[�^�̍폜
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del);
--                                            t_forecast_interface_tab_del,
--                                            t_forecast_designator_tab);
      -- �G���[�������ꍇ
-- mod start 1.11
--      IF (lb_retcode = FALSE )THEN
--      IF ( t_forecast_interface_tab_del(1).process_status <> 5 ) THEN
      FOR i IN 1..lt_del_if.COUNT LOOP
        IF ( t_forecast_interface_tab_del(i).process_status <> 5 ) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                        ,gv_msg_10a_045  -- API�G���[
                                                        ,gv_tkn_api_name
                                                        ,gv_cons_api)    -- �\��API
                                                        ,1
                                                        ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(i).error_message);
          RAISE global_api_expt;
        END IF;
      END LOOP;
-- mod end 1.11
--
  EXCEPTION
    -- �폜�Ώۃf�[�^���Ȃ��ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN                        --*** �f�[�^�Ȃ���O ***
      ov_data_flg :=  gn_cons_no_data_found;       -- �Ώۃf�[�^�L�薳���t���O�Ɂu�Ȃ��v���Z�b�g
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
  END get_f_dates_hanbai;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_keikaku
   * Description      : A-4-4 �v�揤�iForecast���t���o
   ***********************************************************************************/
  PROCEDURE get_f_dates_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_data_flg              OUT NUMBER,          -- �폜�Ώ�(1:����, 0:�Ȃ�)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_keikaku'; -- �v���O������
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
    lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- ���ID
    lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast��
    lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- �݌ɑg�D
    lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- �i��
    ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- �J�n���t
    ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- �I�����t
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
    -- �Ώۃf�[�^�L�薳���t���O�̏����f�[�^�Z�b�g�i����j
    ov_data_flg := gn_cons_data_found;
--
    -- ���炢�����Ώۃf�[�^�̒��o
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
            mfd.rate_end_date            -- �I�����t
    INTO    lv_4f_txns_id,               -- ���ID
            lv_4f_forecast_designator,   -- Forecast��
            lv_4f_organization_id,       -- �݌ɑg�D
            lv_4f_item_id,               -- �i��
            gd_4k_start_date_active,     -- �J�n���t
            gd_4k_end_date_active        -- �I�����t
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id                      -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id                    -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator                -- Forecast��
      AND   mfd.organization_id        = gn_3f_organization_id                    -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   mfd.attribute5             = in_if_data_tbl(in_if_data_cnt).base_code -- ���_
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1                              -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id                    -- �i��ID
      AND   ((gd_keikaku_start_date   >= mfd.forecast_date
              AND
              gd_keikaku_start_date   <= mfd.rate_end_date)
        OR   (gd_keikaku_end_date     >= mfd.forecast_date
              AND
              gd_keikaku_end_date     <= mfd.rate_end_date))
      AND   ROWNUM                     = 1;
--
  EXCEPTION
    -- �폜�Ώۃf�[�^���Ȃ��ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN                        --*** �f�[�^�Ȃ���O ***
      ov_data_flg :=  gn_cons_no_data_found;       -- �Ώۃf�[�^�L�薳���t���O�Ɂu�Ȃ��v���Z�b�g
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
  END get_f_dates_keikaku;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_seigen_a
   * Description      : A-5-4 �o�א�����AForecast���t���o
   ***********************************************************************************/
  PROCEDURE get_f_dates_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_data_flg              OUT NUMBER,          -- �폜�Ώ�(1:����, 0:�Ȃ�)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_seigen_a'; -- �v���O������
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
    lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- ���ID
    lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast��
    lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- �݌ɑg�D
    lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- �i��
    ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- �J�n���t
    ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- �I�����t
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
    -- �Ώۃf�[�^�L�薳���t���O�̏����f�[�^�Z�b�g�i����j
    ov_data_flg := gn_cons_data_found;
--
    -- ���炢�����Ώۃf�[�^�̒��o
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
            mfd.rate_end_date            -- �I�����t
    INTO    lv_4f_txns_id,               -- ���ID
            lv_4f_forecast_designator,   -- Forecast��
            lv_4f_organization_id,       -- �݌ɑg�D
            lv_4f_item_id,               -- �i��
            ld_4f_start_date_active,     -- �J�n���t
            ld_4f_end_date_active        -- �I�����t
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id       -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast��
      AND   mfd.organization_id        = gn_3f_organization_id     -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1               -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- �i��ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date))
      AND   ROWNUM                     = 1;
--
  EXCEPTION
    -- �폜�Ώۃf�[�^���Ȃ��ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN                        --*** �f�[�^�Ȃ���O ***
      ov_data_flg :=  gn_cons_no_data_found;       -- �Ώۃf�[�^�L�薳���t���O�Ɂu�Ȃ��v���Z�b�g
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
  END get_f_dates_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : get_f_dates_seigen_b
   * Description      : A-6-4 �o�א�����BForecast���t���o
   ***********************************************************************************/
  PROCEDURE get_f_dates_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    ov_data_flg              OUT NUMBER,          -- �폜�Ώ�(1:����, 0:�Ȃ�)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_f_dates_seigen_b'; -- �v���O������
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
    lv_4f_txns_id
             mrp_forecast_dates.transaction_id%TYPE;                  -- ���ID
    lv_4f_forecast_designator
             mrp_forecast_dates.forecast_designator%TYPE;             -- Forecast��
    lv_4f_organization_id
             mrp_forecast_dates.organization_id%TYPE;                 -- �݌ɑg�D
    lv_4f_item_id
             mrp_forecast_dates.inventory_item_id%TYPE;               -- �i��
    ld_4f_start_date_active
             mrp_forecast_dates.forecast_date%TYPE;                   -- �J�n���t
    ld_4f_end_date_active
             mrp_forecast_dates.rate_end_date%TYPE;                   -- �I�����t
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
    -- �Ώۃf�[�^�L�薳���t���O�̏����f�[�^�Z�b�g�i����j
    ov_data_flg := gn_cons_data_found;
--
    -- ���炢�����Ώۃf�[�^�̒��o
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
            mfd.rate_end_date            -- �I�����t
    INTO    lv_4f_txns_id,               -- ���ID
            lv_4f_forecast_designator,   -- Forecast��
            lv_4f_organization_id,       -- �݌ɑg�D
            lv_4f_item_id,               -- �i��
            ld_4f_start_date_active,     -- �J�n���t
            ld_4f_end_date_active        -- �I�����t
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id       -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast��
      AND   mfd.organization_id        = gn_3f_organization_id     -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1               -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- �i��ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date))
      AND   ROWNUM                     = 1;
--
  EXCEPTION
    -- �폜�Ώۃf�[�^���Ȃ��ꍇ�̌㏈��
    WHEN NO_DATA_FOUND THEN                        --*** �f�[�^�Ȃ���O ***
      ov_data_flg :=  gn_cons_no_data_found;       -- �Ώۃf�[�^�L�薳���t���O�Ɂu�Ȃ��v���Z�b�g
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
  END get_f_dates_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_hikitori
   * Description      : A-2-5 ����v��Forecast�o�^
   ***********************************************************************************/
  PROCEDURE put_forecast_hikitori(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    in_data_flg              IN  NUMBER,          -- �폜�f�[�^�L�薳���t���O(0:�Ȃ�, 1:����)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_hikitori'; -- �v���O������
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
    ln_number_of_case           NUMBER := 0;                          -- �P�[�X����(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- �P�[�X����(VARCHAR2)
    ln_inventory_item_id        NUMBER;      -- �i��ID
    ln_quantity                 NUMBER;      -- �S����
    t_forecast_interface_tab    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab   MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���炢�����Ώۃf�[�^�̒��o
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- mod start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,           -- �I�����t
            NULL,                          -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi    -- Forecast�i��
    WHERE   mfd.forecast_designator      = gv_3f_forecast_designator   -- Forecast��
      AND   mfd.organization_id          = gn_3f_organization_id       -- �݌ɑg�D
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gv_in_yyyymm  -- ���͔N��
      AND   mfd.organization_id          = mfi.organization_id
--mod start kumamoto
and mfd.FORECAST_DESIGNATOR = mfi.FORECAST_DESIGNATOR
--mod end kumamoto
      AND   mfd.inventory_item_id        = mfi.inventory_item_id;
--
    -- *** ���[�J���E���R�[�h ***
    lr_araigae_data     araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
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
    -- �o�^���鐔�ʂ��Z�o���邽�߂ɕi�ڃ}�X�^����P�[�X�����𒊏o����
    -- �����Ɏ�L�[�����邽��NO_DATA_FOUND�ɂ͂Ȃ�Ȃ�
    SELECT im.attribute11,             -- �P�[�X���萔
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM�i�ڃ}�X�^
           mtl_system_items_vl si      -- �i�ڃ}�X�^
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- �P�[�X���ʂ�>0 �̏ꍇ�̓P�[�X���萔��ϊ����遨�ϊ��G���[�̓G���[�Ƃ���
    -- �P�[�X���ʂ�>0 �̎������P�[�X���萔���K�v�ƂȂ�̂ŏ�LSQL�ł͈�UVARCHAR�^
    -- �Ŏ󂯎���Ă���(TO_NUMBER���Ȃ�)�A�����ŕϊ�����NULL�╶���ł���Η�O�ɂď�������
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULL��INVALID_NUMBER��O���������Ȃ����߂ɂ�����RAISE����
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
    -- �S���ʂ��Z�o����(�P�[�X����*�P�[�X����+�o������)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- �o�^�̂��߂̃f�[�^�Z�b�g
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                          in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                          in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ��
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ��
--
    -- �o�^�̂��߂̃f�[�^�Z�b�g
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator   := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id       := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id     := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity              := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date         :=
                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date     :=
                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5            :=
                                          in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6            :=
                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4            :=
                                          in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type           := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status        := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
--
    -- �G���[�������ꍇ
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn    -- 'XXCMN'
--                                                    ,gv_msg_10a_045
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- �\��API
--                                                   ,1
--                                                   ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- �P�[�X���萔���s��(TO_NUMBER()�ŃG���[)�ȏꍇ�̌㏈��
    WHEN VALUE_ERROR THEN                           --*** TO_NUMBER()�ŃG���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    -- �P�[�X���萔�擾�G���[
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
    WHEN null_expt THEN                                --*** �P�[�X���萔��NULL ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
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
  END put_forecast_hikitori;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_hanbai
   * Description      : A-3-5 �̔��v��Forecast�o�^
   ***********************************************************************************/
  PROCEDURE  put_forecast_hanbai(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    in_data_flg              IN  NUMBER,          -- �폜�f�[�^�L�薳���t���O(0:�Ȃ�, 1:����)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_hanbai'; -- �v���O������
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
    ln_inventory_item_id        NUMBER;      -- �i��ID
    ln_number_of_case           NUMBER := 0;                     -- �P�[�X����(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- �P�[�X����(VARCHAR2)
    ln_quantity                 NUMBER;      -- �S����
    lb_retcode                  BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab   MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
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
    -- ���t�f�[�^���������ꍇ�͓o�^�ς݃f�[�^�̍폜�������Ȃ�
/*
    IF (in_data_flg = gn_cons_data_found) THEN
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
      t_forecast_interface_tab_del(1).transaction_id        := gv_4h_txns_id;            -- ���ID
      t_forecast_interface_tab_del(1).forecast_designator   := gv_4h_forecast_designator;-- Forecast��
      t_forecast_interface_tab_del(1).organization_id       := gv_4h_organization_id;    -- �g�DID
      t_forecast_interface_tab_del(1).inventory_item_id     := gv_4h_item_id;            -- �i��ID
      t_forecast_interface_tab_del(1).quantity              := 0;                        -- ����
      t_forecast_interface_tab_del(1).forecast_date         := gd_4h_start_date_active;  -- �J�n���t
      t_forecast_interface_tab_del(1).forecast_end_date     := gd_4h_end_date_active;    -- �I�����t
      t_forecast_interface_tab_del(1).bucket_type           := 1;
      t_forecast_interface_tab_del(1).process_status        := 2;
      t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
      -- �o�^�ς݃f�[�^�̍폜
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- �G���[�������ꍇ
      IF ( t_forecast_interface_tab_del(1).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- API�G���[
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- �\��API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--
    -- �o�^���鐔�ʂ��Z�o���邽�߂ɕi�ڃ}�X�^����P�[�X�����𒊏o����
    -- �����Ɏ�L�[�����邽��NO_DATA_FOUND�ɂ͂Ȃ�Ȃ�
    SELECT im.attribute11,             -- �P�[�X���萔
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM�i�ڃ}�X�^
           mtl_system_items_vl si      -- �i�ڃ}�X�^
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- �P�[�X���ʂ�>0 �̏ꍇ�̓P�[�X���萔��ϊ����遨�ϊ��G���[�̓G���[�Ƃ���
    -- �P�[�X���ʂ�>0 �̎������P�[�X���萔���K�v�ƂȂ�̂ŏ�LSQL�ł͈�UVARCHAR�^
    -- �Ŏ󂯎���Ă���(TO_NUMBER���Ȃ�)�A�����ŕϊ�����NULL�╶���ł���Η�O�ɂď�������
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULL��VALUE_ERROR��O���������Ȃ����߂ɂ�����RAISE����
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- �S���ʂ��Z�o����(�P�[�X����*�P�[�X����+�o������)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- �o�^�̂��߂̃f�[�^�Z�b�g
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                         in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                         in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                         in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                         in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ��
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ��
--
    -- �o�^�̂��߂̃f�[�^�Z�b�g
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator    := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id        := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id      := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity               := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date          :=
                                         in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date      :=
                                         in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5             :=
                                         in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6             :=
                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4             :=
                                         in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2             := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type            := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status         := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage  := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- �G���[�������ꍇ
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- API�G���[
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- �\��API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- �P�[�X���萔���擾�ł��Ȃ��ꍇ�̌㏈��
    WHEN VALUE_ERROR THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
    WHEN null_expt THEN                                --*** �P�[�X���萔��NULL ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
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
  END  put_forecast_hanbai;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_keikaku
   * Description      : A-4-5 �v�揤�iForecast�o�^
   ***********************************************************************************/
  PROCEDURE  put_forecast_keikaku(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    in_data_flg              IN  NUMBER,          -- �폜�f�[�^�L�薳���t���O(0:�Ȃ�, 1:����)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_keikaku'; -- �v���O������
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
    ln_inventory_item_id        NUMBER;      -- �i��ID
    ln_number_of_case           NUMBER := 0;                     -- �P�[�X����(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- �P�[�X����(VARCHAR2)
    ln_quantity                 NUMBER;      -- �S����
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--add start 1.9
    ln_warning_count            NUMBER := 0;
--add end 1.9
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- mod start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,             -- �I�����t
            im.item_no,                    -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id                      -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id                    -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator                -- Forecast��
      AND   mfd.organization_id        = si.organization_id                       -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   mfd.attribute5             = in_if_data_tbl(in_if_data_cnt).base_code -- ���_
      AND   mfd.organization_id        = gn_3f_organization_id                    -- �݌ɑg�DID
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1                              -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id                    -- �i��ID
      AND   ((gd_keikaku_start_date   >= mfd.forecast_date
              AND
              gd_keikaku_start_date   <= mfd.rate_end_date)
        OR   (gd_keikaku_end_date     >= mfd.forecast_date
              AND
              gd_keikaku_end_date     <= mfd.rate_end_date));
--
    -- *** ���[�J���E���R�[�h ***
    lr_araigae_data                 araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
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
/*
    -- ���t�f�[�^���������ꍇ�͊J�n���t�E�I�����t�̔�r����ѓo�^�ς݃f�[�^�̍폜�������Ȃ�
    IF (in_data_flg = gn_cons_data_found) THEN
--
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<araigae_data_loop>>
      FOR ln_target_cnt IN 1..gn_araigae_cnt LOOP
--
      -- �J�n���t�̔�r
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_start_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- �I�����t�̔�r
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_end_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
      t_forecast_interface_tab_del(ln_target_cnt).transaction_id        :=
                             lr_araigae_data(ln_target_cnt).gv_4f_txns_id;            -- ���ID
      t_forecast_interface_tab_del(ln_target_cnt).forecast_designator   :=
                             lr_araigae_data(ln_target_cnt).gv_4f_forecast_designator;-- Forecast��
      t_forecast_interface_tab_del(ln_target_cnt).organization_id       :=
                             lr_araigae_data(ln_target_cnt).gv_4f_organization_id;    -- �g�DID
      t_forecast_interface_tab_del(ln_target_cnt).inventory_item_id     :=
                             lr_araigae_data(ln_target_cnt).gv_4f_item_id;            -- �i��ID
      t_forecast_interface_tab_del(ln_target_cnt).quantity              := 0;                        -- ����
      t_forecast_interface_tab_del(ln_target_cnt).forecast_date         :=
                             lr_araigae_data(ln_target_cnt).gd_4f_start_date_active;  -- �J�n���t
      t_forecast_interface_tab_del(ln_target_cnt).forecast_end_date     :=
                             lr_araigae_data(ln_target_cnt).gd_4f_end_date_active;    -- �I�����t
      t_forecast_interface_tab_del(ln_target_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(ln_target_cnt).process_status        := 2;
      t_forecast_interface_tab_del(ln_target_cnt).confidence_percentage := 100;
      END LOOP araigae_data_loop;
--
      -- �o�^�ς݃f�[�^�̍폜
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- �G���[�������ꍇ
      IF ( t_forecast_interface_tab_del(ln_target_cnt).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045 -- API�G���[
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- �\��API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
-- 2008/11/07 Y.Kawano Del Start
----add start 1.9
--    -- �J�n���t�̔�r
--    IF (TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active) <> -- �C���^�t�F�[�X�J�n���t
--      TRUNC(gd_keikaku_start_date))                                -- �v�揤�i�ΏۊJ�n���t
--    THEN
--      -- ���b�Z�[�W�Z�b�g
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
--                                                    ,gv_msg_10a_021) -- �t�H�[�L���X�g���t�X�V���[�j���O
--                                                    ,1
--                                                    ,5000);
--      -- �������ʃ��|�[�g�ɏo��
--      if_data_disp( in_if_data_tbl, in_if_data_cnt);
--      ln_warning_count := ln_warning_count + 1;
----
--      -- �v�揤�i�ΏۊJ�n�N�����擾��o�^�̂��߂̃f�[�^�Z�b�g�ɃZ�b�g
---- mod start 1.11
----      t_forecast_interface_tab_ins(1).forecast_date := gd_keikaku_start_date;
----      t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date := gd_keikaku_start_date;
----    ELSE
------      t_forecast_interface_tab_ins(1).forecast_date := 
----      t_forecast_interface_tab_ins(in_if_data_cnt).forecast_date := 
------ mod end 1.11
----                                      in_if_data_tbl(in_if_data_cnt).start_date_active;
--    END IF;
--    -- �I�����t�̔�r
--    IF (TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active) <> -- �C���^�t�F�[�X�I�����t
--      TRUNC(gd_keikaku_end_date))                                -- �v�揤�i�I����
--    THEN
--      -- ���b�Z�[�W�Z�b�g
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv  -- 'XXINV'
--                                                    ,gv_msg_10a_021) -- �t�H�[�L���X�g���t�X�V���[�j���O
--                                                    ,1
--                                                    ,5000);
--      -- �������ʃ��|�[�g�ɏo��
--      if_data_disp( in_if_data_tbl, in_if_data_cnt);
--      ln_warning_count := ln_warning_count + 1;
----
--      -- �v�揤�i�ΏۏI���N�����擾��o�^�̂��߂̃f�[�^�Z�b�g�ɃZ�b�g
---- mod start 1.11
----      t_forecast_interface_tab_ins(1).forecast_end_date := gd_keikaku_end_date;
--      t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date := gd_keikaku_end_date;
--    ELSE
----      t_forecast_interface_tab_ins(1).forecast_end_date := 
--      t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date := 
---- mod end 1.11
--                                      in_if_data_tbl(in_if_data_cnt).end_date_active;
--    END IF;
----add end 1.9
-- 2008/11/07 Y.Kawano Add End
--
    -- �o�^���鐔�ʂ��Z�o���邽�߂ɕi�ڃ}�X�^����P�[�X�����𒊏o����
    -- �����Ɏ�L�[�����邽��NO_DATA_FOUND�ɂ͂Ȃ�Ȃ�
    SELECT im.attribute11,             -- �P�[�X���萔
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM�i�ڃ}�X�^
           mtl_system_items_vl si      -- �i�ڃ}�X�^
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- �P�[�X���ʂ�>0 �̏ꍇ�̓P�[�X���萔��ϊ����遨�ϊ��G���[�̓G���[�Ƃ���
    -- �P�[�X���ʂ�>0 �̎������P�[�X���萔���K�v�ƂȂ�̂ŏ�LSQL�ł͈�UVARCHAR�^
    -- �Ŏ󂯎���Ă���(TO_NUMBER���Ȃ�)�A�����ŕϊ�����NULL�╶���ł���Η�O�ɂď�������
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULL��VALUE_ERROR��O���������Ȃ����߂ɂ�����RAISE����
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- �S���ʂ��Z�o����(�P�[�X����*�P�[�X����+�o������)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- �o�^�̂��߂̃f�[�^�Z�b�g
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--del start 1.9
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                         in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                         in_if_data_tbl(in_if_data_cnt).end_date_active;
--del end 1.9
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                         in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                         in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ��
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ��
--
    -- �o�^�̂��߂̃f�[�^�Z�b�g
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator    := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id        := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id      := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity               := ln_quantity;
-- 2008/11/07 Y.Kawano Add Start
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date          := gd_keikaku_start_date;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date      := gd_keikaku_end_date;
-- 2008/11/07 Y.Kawano Add End
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5             :=
                                         in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6             :=
                                         in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4             :=
                                         in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2             := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type            := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status         := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage  := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- �G���[�������ꍇ
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- API�G���[
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- �\��API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--add start 1.9
--    ELSE
      -- �x�������������ꍇ
--      IF (ln_warning_count > 0) THEN
--        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--        ov_retcode := gv_status_warn;
--      END IF;
--add end 1.9
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- �P�[�X���萔���擾�ł��Ȃ��ꍇ�̌㏈��
    WHEN VALUE_ERROR THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
    WHEN null_expt THEN                                --*** �P�[�X���萔��NULL ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
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
  END  put_forecast_keikaku;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_seigen_a
   * Description      : A-5-5 �o�א�����AForecast�o�^
   ***********************************************************************************/
  PROCEDURE  put_forecast_seigen_a(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    in_data_flg              IN  NUMBER,          -- �폜�f�[�^�L�薳���t���O(0:�Ȃ�, 1:����)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_seigen_a'; -- �v���O������
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
    ln_inventory_item_id        NUMBER;      -- �i��ID
    ln_number_of_case           NUMBER := 0;                     -- �P�[�X����(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- �P�[�X����(VARCHAR2)
    ln_quantity                 NUMBER := 0;      -- �S����
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- mod start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,             -- �I�����t
            im.item_no,                    -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id       -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast��
      AND   mfd.organization_id        = gn_3f_organization_id     -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1               -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- �i��ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
--
    -- *** ���[�J���E���R�[�h ***
    lr_araigae_data                 araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
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
/*
    -- ���t�f�[�^���������ꍇ�͊J�n���t�E�I�����t�̔�r����ѓo�^�ς݃f�[�^�̍폜�������Ȃ�
    IF (in_data_flg = gn_cons_data_found) THEN
--
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<araigae_data_loop>>
      FOR ln_target_cnt IN 1..gn_araigae_cnt LOOP

      -- �J�n���t�̔�r
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_start_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- �I�����t�̔�r
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_end_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
      t_forecast_interface_tab_del(ln_target_cnt).transaction_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_txns_id;            -- ���ID
      t_forecast_interface_tab_del(ln_target_cnt).forecast_designator
                         := lr_araigae_data(ln_target_cnt).gv_4f_forecast_designator;-- Forecast��
      t_forecast_interface_tab_del(ln_target_cnt).organization_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_organization_id;    -- �g�DID
      t_forecast_interface_tab_del(ln_target_cnt).inventory_item_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_item_id;            -- �i��ID
      t_forecast_interface_tab_del(ln_target_cnt).quantity              := 0;        -- ����
      t_forecast_interface_tab_del(ln_target_cnt).forecast_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_start_date_active;  -- �J�n���t
      t_forecast_interface_tab_del(ln_target_cnt).forecast_end_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_end_date_active;    -- �I�����t
      t_forecast_interface_tab_del(ln_target_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(ln_target_cnt).process_status        := 2;
      t_forecast_interface_tab_del(ln_target_cnt).confidence_percentage := 100;
      END LOOP araigae_data_loop;
--
      -- �o�^�ς݃f�[�^�̍폜
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- �G���[�������ꍇ
      IF ( t_forecast_interface_tab_del(ln_target_cnt).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045 -- API�G���[
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- �\��API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--
    -- �o�^���鐔�ʂ��Z�o���邽�߂ɕi�ڃ}�X�^����P�[�X�����𒊏o����
    -- �����Ɏ�L�[�����邽��NO_DATA_FOUND�ɂ͂Ȃ�Ȃ�
    SELECT im.attribute11,             -- �P�[�X���萔
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM�i�ڃ}�X�^
           mtl_system_items_vl si      -- �i�ڃ}�X�^
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- �P�[�X���ʂ�>0 �̏ꍇ�̓P�[�X���萔��ϊ����遨�ϊ��G���[�̓G���[�Ƃ���
    -- �P�[�X���ʂ�>0 �̎������P�[�X���萔���K�v�ƂȂ�̂ŏ�LSQL�ł͈�UVARCHAR�^
    -- �Ŏ󂯎���Ă���(TO_NUMBER���Ȃ�)�A�����ŕϊ�����NULL�╶���ł���Η�O�ɂď�������
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULL��VALUE_ERROR��O���������Ȃ����߂ɂ�����RAISE����
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- �S���ʂ��Z�o����(�P�[�X����*�P�[�X����+�o������)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- �o�^�̂��߂̃f�[�^�Z�b�g
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5         := in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4         := in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ��
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ��
    -- �o�^�̂��߂̃f�[�^�Z�b�g
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator   := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id       := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id     := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity              := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date         :=
                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date     :=
                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5         := in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6            :=
                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4         := in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type           := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status        := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- �G���[�������ꍇ
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- API�G���[
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- �\��API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- �P�[�X���萔���擾�ł��Ȃ��ꍇ�̌㏈��
    WHEN VALUE_ERROR THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
    WHEN null_expt THEN                                --*** �P�[�X���萔��NULL ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
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
  END  put_forecast_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : put_forecast_seigen_b
   * Description      : A-6-5 �o�א�����BForecast�o�^
   ***********************************************************************************/
  PROCEDURE  put_forecast_seigen_b(
    in_if_data_tbl           IN  forecast_tbl,
    in_if_data_cnt           IN  NUMBER,          -- ��������IF�f�[�^�J�E���^
    in_data_flg              IN  NUMBER,          -- �폜�f�[�^�L�薳���t���O(0:�Ȃ�, 1:����)
    ov_errbuf                OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_forecast_seigen_b'; -- �v���O������
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
    ln_inventory_item_id        NUMBER;      -- �i��ID
    ln_number_of_case           NUMBER := 0;                     -- �P�[�X����(NUMBER)
    lv_number_of_case           ic_item_mst_vl.attribute11%TYPE; -- �P�[�X����(VARCHAR2)
    ln_quantity                 NUMBER;      -- �S����
    lb_retcode                  BOOLEAN;
    ln_target_cnt               NUMBER := 0;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- mod start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,             -- �I�����t
            im.item_no,                    -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id       -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast��
      AND   mfd.organization_id        = gn_3f_organization_id     -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = in_if_data_tbl(in_if_data_cnt).item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1               -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- �i��ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
--
    -- *** ���[�J���E���R�[�h ***
    lr_araigae_data                 araigae_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
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
/*
    -- ���t�f�[�^���������ꍇ�͊J�n���t�E�I�����t�̔�r����ѓo�^�ς݃f�[�^�̍폜�������Ȃ�
    IF (in_data_flg = gn_cons_data_found) THEN
--
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<araigae_data_loop>>
      FOR ln_target_cnt IN 1..gn_araigae_cnt LOOP

      -- �J�n���t�̔�r
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_start_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).start_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- �I�����t�̔�r
      IF (TRUNC(lr_araigae_data(ln_target_cnt).gd_4f_end_date_active) <>
        TRUNC(in_if_data_tbl(in_if_data_cnt).end_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( in_if_data_tbl, in_if_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
--
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
      t_forecast_interface_tab_del(ln_target_cnt).transaction_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_txns_id;            -- ���ID
      t_forecast_interface_tab_del(ln_target_cnt).forecast_designator
                         := lr_araigae_data(ln_target_cnt).gv_4f_forecast_designator;-- Forecast��
      t_forecast_interface_tab_del(ln_target_cnt).organization_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_organization_id;    -- �g�DID
      t_forecast_interface_tab_del(ln_target_cnt).inventory_item_id
                         := lr_araigae_data(ln_target_cnt).gv_4f_item_id;            -- �i��ID
      t_forecast_interface_tab_del(ln_target_cnt).quantity              := 0;        -- ����
      t_forecast_interface_tab_del(ln_target_cnt).forecast_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_start_date_active;  -- �J�n���t
      t_forecast_interface_tab_del(ln_target_cnt).forecast_end_date
                         := lr_araigae_data(ln_target_cnt).gd_4f_end_date_active;    -- �I�����t
      t_forecast_interface_tab_del(ln_target_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(ln_target_cnt).process_status        := 2;
      t_forecast_interface_tab_del(ln_target_cnt).confidence_percentage := 100;
      END LOOP araigae_data_loop;
--
      -- �o�^�ς݃f�[�^�̍폜
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                            t_forecast_interface_tab_del,
                                            t_forecast_designator_tab);
      -- �G���[�������ꍇ
      IF ( t_forecast_interface_tab_del(ln_target_cnt).process_status <> 5 ) THEN
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- API�G���[
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api) -- �\��API
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--
    -- �o�^���鐔�ʂ��Z�o���邽�߂ɕi�ڃ}�X�^����P�[�X�����𒊏o����
    -- �����Ɏ�L�[�����邽��NO_DATA_FOUND�ɂ͂Ȃ�Ȃ�
    SELECT im.attribute11,             -- �P�[�X���萔
           si.inventory_item_id
    INTO   lv_number_of_case,
           ln_inventory_item_id
    FROM   ic_item_mst_vl      im,     -- OPM�i�ڃ}�X�^
           mtl_system_items_vl si      -- �i�ڃ}�X�^
    WHERE  im.item_no   = in_if_data_tbl(in_if_data_cnt).item_code
      AND  im.item_no   = si.segment1
      AND  ROWNUM       = 1;
--
    -- �P�[�X���ʂ�>0 �̏ꍇ�̓P�[�X���萔��ϊ����遨�ϊ��G���[�̓G���[�Ƃ���
    -- �P�[�X���ʂ�>0 �̎������P�[�X���萔���K�v�ƂȂ�̂ŏ�LSQL�ł͈�UVARCHAR�^
    -- �Ŏ󂯎���Ă���(TO_NUMBER���Ȃ�)�A�����ŕϊ�����NULL�╶���ł���Η�O�ɂď�������
    IF (in_if_data_tbl(in_if_data_cnt).case_quantity > 0) THEN
      ln_number_of_case := TO_NUMBER(lv_number_of_case);
      -- NULL��VALUE_ERROR��O���������Ȃ����߂ɂ�����RAISE����
      IF ( lv_number_of_case IS NULL ) THEN
        RAISE null_expt;
      END IF;
    END IF;
--
    -- �S���ʂ��Z�o����(�P�[�X����*�P�[�X����+�o������)
    ln_quantity := in_if_data_tbl(in_if_data_cnt).case_quantity * ln_number_of_case
                   + in_if_data_tbl(in_if_data_cnt).quantity;
--
-- mod start 1.11
    -- �o�^�̂��߂̃f�[�^�Z�b�g
--    t_forecast_interface_tab_ins(1).forecast_designator   := gv_3f_forecast_designator;
--    t_forecast_interface_tab_ins(1).organization_id       := gn_3f_organization_id;
--    t_forecast_interface_tab_ins(1).inventory_item_id     := ln_inventory_item_id;
--    t_forecast_interface_tab_ins(1).quantity              := ln_quantity;
--    t_forecast_interface_tab_ins(1).forecast_date         :=
--                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
--    t_forecast_interface_tab_ins(1).forecast_end_date     :=
--                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
--    t_forecast_interface_tab_ins(1).attribute5            :=
--                                          in_if_data_tbl(in_if_data_cnt).base_code;
--    t_forecast_interface_tab_ins(1).attribute6            :=
--                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
--    t_forecast_interface_tab_ins(1).attribute4            :=
--                                          in_if_data_tbl(in_if_data_cnt).quantity;
--    t_forecast_interface_tab_ins(1).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
--    t_forecast_interface_tab_ins(1).bucket_type           := 1;
--    t_forecast_interface_tab_ins(1).process_status        := 2;
--    t_forecast_interface_tab_ins(1).confidence_percentage := 100;
--
-- 2008/08/01 Add ��
--    t_forecast_interface_tab_ins(1).last_update_date       := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).last_updated_by        := gn_last_updated_by;
--    t_forecast_interface_tab_ins(1).creation_date          := gd_who_sysdate;
--    t_forecast_interface_tab_ins(1).created_by             := gn_created_by;
--    t_forecast_interface_tab_ins(1).last_update_login      := gn_login_user;
--    t_forecast_interface_tab_ins(1).request_id             := gn_request_id;
--    t_forecast_interface_tab_ins(1).program_application_id := gn_program_application_id;
--    t_forecast_interface_tab_ins(1).program_id             := gn_program_id;
--    t_forecast_interface_tab_ins(1).program_update_date    := gd_who_sysdate;
-- 2008/08/01 Add ��

    -- �o�^�̂��߂̃f�[�^�Z�b�g
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_designator   := gv_3f_forecast_designator;
    t_forecast_interface_tab_inst(in_if_data_cnt).organization_id       := gn_3f_organization_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).inventory_item_id     := ln_inventory_item_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).quantity              := ln_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_date         :=
                                          in_if_data_tbl(in_if_data_cnt).start_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).forecast_end_date     :=
                                          in_if_data_tbl(in_if_data_cnt).end_date_active;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute5            :=
                                          in_if_data_tbl(in_if_data_cnt).base_code;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute6            :=
                                          in_if_data_tbl(in_if_data_cnt).case_quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute4            :=
                                          in_if_data_tbl(in_if_data_cnt).quantity;
    t_forecast_interface_tab_inst(in_if_data_cnt).attribute2            := in_if_data_tbl(in_if_data_cnt).price;
    t_forecast_interface_tab_inst(in_if_data_cnt).bucket_type           := 1;
    t_forecast_interface_tab_inst(in_if_data_cnt).process_status        := 2;
    t_forecast_interface_tab_inst(in_if_data_cnt).confidence_percentage := 100;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_date       := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_updated_by        := gn_last_updated_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).creation_date          := gd_who_sysdate;
    t_forecast_interface_tab_inst(in_if_data_cnt).created_by             := gn_created_by;
    t_forecast_interface_tab_inst(in_if_data_cnt).last_update_login      := gn_login_user;
    t_forecast_interface_tab_inst(in_if_data_cnt).request_id             := gn_request_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_application_id := gn_program_application_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_id             := gn_program_id;
    t_forecast_interface_tab_inst(in_if_data_cnt).program_update_date    := gd_who_sysdate;
--
    -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_ins,
--                                           t_forecast_designator_tab);
    -- �G���[�������ꍇ
--    IF ( t_forecast_interface_tab_ins(1).process_status <> 5 ) THEN
--      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                    ,gv_msg_10a_045 -- API�G���[
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- �\��API
--                                                    ,1
--                                                    ,5000);
--add start 1.9
--      FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_ins(1).error_message);
--add end 1.9
--      RAISE global_api_expt;
--    END IF;
-- mod end 1.11
--
  EXCEPTION
    -- �P�[�X���萔���擾�ł��Ȃ��ꍇ�̌㏈��
    WHEN VALUE_ERROR THEN                           --*** �p�����[�^��O ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
    WHEN null_expt THEN                                --*** �P�[�X���萔��NULL ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                    ,gv_msg_10a_059  -- �P�[�X���萔�擾�G���[
                                                    ,gv_tkn_item    -- �g�[�N��'ITEM'
                                                                    -- �i�ڃR�[�h
                                                    ,in_if_data_tbl(in_if_data_cnt).item_code)
                                                    ,1
                                                    ,5000);
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
  END  put_forecast_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : del_if_data
   * Description      : A-X-6 �̔��v��/����v��C���^�[�t�F�[�X�f�[�^�폜
   *                    (A-2-6, A-3-6, A-4-6, A-5-6, A-6-6 ���ʏ���)
   ***********************************************************************************/
  PROCEDURE del_if_data(
    in_if_data_tbl        IN  forecast_tbl,
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_if_data'; -- �v���O������
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
    lb_retcd    BOOLEAN;   -- ���^�[���R�[�h
    ln_loop_cnt NUMBER;    -- ���[�v�J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    TYPE txns_type IS TABLE OF 
         xxinv_mrp_forecast_interface.forecast_if_id%TYPE INDEX BY PLS_INTEGER;
    t_txns_type txns_type;
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
    ln_loop_cnt := 0;
    -- FORALL�Ńf�[�^���폜���邽�߂ɍ폜��p���ID�e�[�u���Ƀf�[�^���Z�b�g����
    <<table_copy_loop>>
    FOR ln_loop_cnt IN 1..gn_target_cnt LOOP
      t_txns_type(ln_loop_cnt) := in_if_data_tbl(ln_loop_cnt).txns_id;
    END LOOP table_copy_loop;
--
    -- �̔��v��/����v��C���^�|�t�F�[�X�e�[�u������Ώۃf�[�^�폜
    ln_loop_cnt := 0;
    FORALL ln_loop_cnt IN 1..gn_target_cnt
      DELETE /*+ INDEX( xxinv_mrp_forecast_interface XXINV_MFI_PK ) */       -- 2008/11/11 �����w�E#589 Add
      FROM xxinv_mrp_forecast_interface
      WHERE  forecast_if_id = t_txns_type(ln_loop_cnt);
--
--add start 1.4
      COMMIT;
--add end 1.4
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
  END del_if_data;
--
/**********************************************************************************
   * Procedure Name   : forecast_hikitori
   * Description      : ����v��(A-2)
   ***********************************************************************************/
  PROCEDURE forecast_hikitori(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_hikitori'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_d  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_d VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_d  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_data_cnt   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    ln_data_cnt2   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    ln_data_flg   NUMBER;    -- ���t�f�[�^����Ȃ��t���O(0:�Ȃ��A1:����)
    ln_error_flg  NUMBER;    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O(0:�Ȃ�, 1:����)
    lb_retcode                  BOOLEAN;
--add start 1.11
    ln_warn_flg   NUMBER := 0; -- �C���^�|�t�F�[�X�f�[�^�x������t���O(0:�Ȃ�, 1:����)
--add end 1.11
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���炢�����Ώۃf�[�^�̒��o
    CURSOR forecast_araigae_cur
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- add start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,             -- �I�����t
            NULL,                          -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- add end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi    -- Forecast�i��
    WHERE   mfd.forecast_designator      = gv_3f_forecast_designator   -- Forecast��
      AND   mfd.organization_id          = gn_3f_organization_id       -- �݌ɑg�D
-- mod start 1.11
--      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = gv_in_yyyymm  -- ���͔N��
      AND   TO_CHAR(mfd.forecast_date,'YYYYMM') = TO_CHAR(TO_DATE(gv_in_yyyymm,'YYYYMM'),'YYYYMM')  -- ���͔N��
-- mod strart 1.11
      AND   mfd.organization_id          = mfi.organization_id
--mod start kumamoto
      AND mfd.FORECAST_DESIGNATOR = mfi.FORECAST_DESIGNATOR
--mod end kumamoto
      AND   mfd.inventory_item_id        = mfi.inventory_item_id;
--
    -- *** ���[�J���E���R�[�h ***
    lr_araigae_data     araigae_tbl;
--
    -- *** ���[�J���E���R�[�h ***
    lt_if_data    forecast_tbl;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
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
    -- A-*-0 IF�f�[�^���ڕK�{�`�F�b�N
    if_data_null_check( gv_cons_fc_type_hikitori,      -- Forecast����('����v��')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
    -- �G���[���������珈�����~
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-2-1 ����v��C���^�|�t�F�[�X�f�[�^���o
    get_hikitori_if_data( lt_if_data,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- �G���[���������珈�����~
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O������
    ln_error_flg :=0;
--
    -- ���o�f�[�^�`�F�b�N���[�v
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- ���o�����f�[�^���`�F�b�N����
      --   ����v�撊�o�f�[�^�`�F�b�N
      hikitori_data_check( lt_if_data,
                           ln_data_cnt,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg );
      -- �G���[���������ꍇ�́A�C���^�|�t�F�[�X�f�[�^�G���[����t���OON�ɂ��A
      -- ��������S�f�[�^������(�`�F�b�N)���āA�Ō�ɃG���[������Ώ����𒆎~����B
      -- �x���Ȃ�Ώ����͑��s����B
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.11
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.11
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-2-2 ����v�撊�o�f�[�^�`�F�b�N�ŃG���[���������ꍇ�́uForecast�����f�[�^���[�v�v
    -- �͏������Ȃ��ŃX�L�b�v����B
    IF (ln_error_flg = 0) THEN
--
    <<araigae_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
-- 2009/02/17 �{�ԏ�Q#38 DEL Start --
--        -- A-2-3 ����v��Forecast�����o
--        get_f_degi_hikitori( lt_if_data,
--                             ln_data_cnt,
--                             lv_errbuf,
--                             lv_retcode,
--                             lv_errmsg );
--        -- �G���[���������烋�[�v�������~
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
--
-- 2009/02/17 �{�ԏ�Q#38 DEL End    --
      OPEN forecast_araigae_cur;
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
        -- �폜�p�ϐ��ɃZ�b�g
-- mod start 1.11
        gn_del_data_cnt := gn_del_data_cnt + 1;
--
--        t_forecast_interface_tab_del(1).transaction_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- ���ID
--        t_forecast_interface_tab_del(1).forecast_designator
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;                    -- Forecast��
--        t_forecast_interface_tab_del(1).organization_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;                        -- �g�DID
--        t_forecast_interface_tab_del(1).inventory_item_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;           -- �i��ID
--        t_forecast_interface_tab_del(1).quantity              := 0;       -- ����
--        t_forecast_interface_tab_del(1).forecast_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- �J�n���t
--        t_forecast_interface_tab_del(1).forecast_end_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- �I�����t
--        t_forecast_interface_tab_del(1).bucket_type           := 1;
--        t_forecast_interface_tab_del(1).process_status        := 2;
--        t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
        t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- ���ID
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;                    -- Forecast��
        t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;                        -- �g�DID
        t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;           -- �i��ID
        t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;       -- ����
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- �J�n���t
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- �I�����t
        t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
        t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
        t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;
--
        -- Forecast���t�f�[�^�̃N���A
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
        -- �G���[�������ꍇ
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
--                                                        ,gv_msg_10a_045  -- API�G���[
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- �\��API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
     END LOOP del_loop;
-- add start ver1.15
     -- Forecast���t�f�[�^�̃N���A
     -- ���炢�����Ώۃf�[�^�̏����J�E���^��1000���𒴂����ꍇ
     IF (gn_del_data_cnt >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- �G���[�������ꍇ
       IF (lb_retcode = FALSE )THEN
         ln_error_flg := 1;
       END IF;
       -- ���炢�����Ώۃf�[�^�̏����J�E���^�̏�����
       gn_del_data_cnt := 0;
       t_forecast_interface_tab_del.delete;
     -- ���o�C���^�[�t�F�[�X�f�[�^���[�v���I������ꍇ
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       IF (lb_retcode = FALSE )THEN
         ln_error_flg := 1;
       END IF;
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
-- del start ver1.15
    -- Forecast���t�f�[�^�̃N���A
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                          t_forecast_interface_tab_del);
-- del end ver1.15
--
-- mod start 1.12
--    <<del_serch_error_loop>>
--    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
--      -- �G���[�������ꍇ
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
--        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
--                                                      ,gv_msg_10a_045  -- API�G���[
--                                                      ,gv_tkn_api_name
--                                                      ,gv_cons_api) -- �\��API
--                                                      ,1
--                                                      ,5000);
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
--        gn_error_cnt := gn_error_cnt + 1;
--        ln_error_flg := 1;
--        EXIT;
--      END IF;
--    END LOOP del_serch_error_loop;
-- mod start ver1.15
    -- �G���[�������ꍇ
--    IF (lb_retcode = FALSE )THEN
    IF (ln_error_flg = 1 )THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                    ,gv_msg_10a_045  -- API�G���[
                                                    ,gv_tkn_api_name
                                                    ,gv_cons_api)    -- �\��API
                                                    ,1
                                                    ,5000);
      gn_error_cnt := gn_error_cnt + 1;
--      ln_error_flg := 1;
    END IF;
-- mod end ver1.15
-- mod end 1.12
    -- ���炢�����Ώۃf�[�^�̏����J�E���^�̏�����
    gn_del_data_cnt := 0;
-- mod end 1.11
--
      -- Forecast�����f�[�^���[�v
/*
      <<forecast_del_set_loop>>
      FOR ln_data_cnt IN 1..gn_araigae_cnt LOOP
--
FND_FILE.PUT_LINE(FND_FILE.LOG,'forecast_del_set_loop...');
--
        -- A-2-3 ����v��Forecast�����o
        get_f_degi_hikitori( lt_if_data,
                             ln_data_cnt,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        -- �G���[���������烋�[�v�������~
        IF (lv_retcode = gv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
        -- �폜�p�ϐ��ɃZ�b�g
        t_forecast_interface_tab_del(1).transaction_id
                          := lr_araigae_data(ln_data_cnt).gv_4f_txns_id;            -- ���ID
        t_forecast_interface_tab_del(1).forecast_designator
                          := lr_araigae_data(ln_data_cnt).gv_4f_forecast_designator;                    -- Forecast��
        t_forecast_interface_tab_del(1).organization_id
                          := lr_araigae_data(ln_data_cnt).gv_4f_organization_id;                        -- �g�DID
        t_forecast_interface_tab_del(1).inventory_item_id
                          := lr_araigae_data(ln_data_cnt).gv_4f_item_id;           -- �i��ID
        t_forecast_interface_tab_del(1).quantity              := 0;       -- ����
        t_forecast_interface_tab_del(1).forecast_date
                          := lr_araigae_data(ln_data_cnt).gd_4f_start_date_active;  -- �J�n���t
        t_forecast_interface_tab_del(1).forecast_end_date
                          := lr_araigae_data(ln_data_cnt).gd_4f_end_date_active;    -- �I�����t
        t_forecast_interface_tab_del(1).bucket_type           := 1;
        t_forecast_interface_tab_del(1).process_status        := 2;
        t_forecast_interface_tab_del(1).confidence_percentage := 100;
--
        -- Forecast���t�f�[�^�̃N���A
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                              t_forecast_interface_tab_del);
        -- �G���[�������ꍇ
        IF (lb_retcode = FALSE )THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
                                                        ,gv_msg_10a_045)  -- API�G���[
                                                        ,1
                                                        ,5000);
          RAISE global_api_expt;
        END IF;
      END LOOP forecast_del_set_loop;
*/
/*
        -- A-2-4 ����v��Forecast���t���o
        get_f_dates_hikitori( ln_data_flg,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg );
        -- �G���[���������烋�[�v�������~
        IF (lv_retcode = gv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
*/
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        <<forecast_ins_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- A-2-3 ����v��Forecast�����o
          get_f_degi_hikitori( lt_if_data,
                               ln_data_cnt,
                               lv_errbuf,
                               lv_retcode,
                               lv_errmsg );
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
-- add start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
          -- A-2-5 ����v��Forecast�o�^
          put_forecast_hikitori( lt_if_data,
                                 ln_data_cnt,
                                 ln_data_flg,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg );
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
-- add start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
        END LOOP forecast_ins_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- �G���[�������ꍇ
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn    -- 'XXCMN'
                                                          ,gv_msg_10a_045
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api) -- �\��API
                                                         ,1
                                                         ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- �o�^�Ώۃf�[�^�̃��R�[�h�̏�����
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
    END IF;
    -- �G���[���Ȃ������ꍇ�̓R�~�b�g����
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6���� �C���^�[�t�F�[�X�e�[�u���폜����
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- �G���[���������珈�����~
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- �e�����ŃG���[���������Ă�����G���[���^�[�����邽�߂ɗ�O�𔭐�������
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
--add start 1.11
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.11
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END forecast_hikitori;
--
  /**********************************************************************************
   * Procedure Name   : forecast_hanbai
   * Description      : �̔��v��(A-3)
   ***********************************************************************************/
  PROCEDURE forecast_hanbai(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_hanbai'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_d  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_d VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_d  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_data_cnt   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    ln_data_flg   NUMBER;    -- ���t�f�[�^����Ȃ��t���O(0:�Ȃ��A1:����)
    ln_error_flg  NUMBER;    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O(0:�Ȃ�, 1:����)
-- add start 1.11
    lb_retcode    BOOLEAN;
-- add end 1.11
--
-- 2008/08/01 Add ��
    lv_errbuf_w  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_errmsg_w  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_warm_flg  NUMBER;
-- 2008/08/01 Add ��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_if_data    forecast_tbl;
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
    -- A-*-0 IF�f�[�^���ڕK�{�`�F�b�N
    if_data_null_check( gv_cons_fc_type_hanbai,      -- Forecast����('�̔��v��')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- �G���[���������珈�����~
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-3-1 �̔��v��C���^�|�t�F�[�X�f�[�^���o
    get_hanbai_if_data( lt_if_data,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- �f�[�^���擾�ł��Ȃ���΃G���[
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O������
    ln_error_flg :=0;
--
-- 2008/08/01 Add ��
    ln_warm_flg  := 0;
-- 2008/08/01 Add ��
--
    -- ���o�f�[�^�`�F�b�N���[�v
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- ���o�����f�[�^���`�F�b�N����
      -- A-3-2 �̔��v�撊�o�f�[�^�`�F�b�N
       hanbai_data_check( lt_if_data,
                          ln_data_cnt,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
      -- �G���[���������ꍇ�́A�C���^�|�t�F�[�X�f�[�^�G���[����t���OON�ɂ��A
      -- ��������S�f�[�^������(�`�F�b�N)���āA�Ō�ɃG���[������Ώ����𒆎~����B
      -- �x���Ȃ�Ώ����͑��s����B
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
-- 2008/08/01 Add ��
      ELSIF (lv_retcode = gv_status_warn) THEN
        lv_errbuf_w := lv_errbuf;
        lv_errmsg_w := lv_errmsg;
        ln_warm_flg := 1;
-- 2008/08/01 Add ��
      END IF;
--add start 1.7
    END LOOP if_data_check_loop;
--add end 1.7
--
    IF (ln_error_flg = 0) THEN
      -- A-3-3 �̔��v��Forecast�����o
      get_f_degi_hanbai( lt_if_data,
                         ln_data_cnt,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg );
--
      -- �G���[����������A-X-6�܂ŏ������Ƃ΂�
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
      END IF;
    END IF;
--add start 1.7
    IF (ln_error_flg = 0) THEN
--add end 1.7
      -- A-3-4 �̔��v��Forecast���t���o
      get_f_dates_hanbai( ln_data_flg,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- �G���[����������A-X-6�܂ŏ������Ƃ΂�
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
      END IF;
--
--add start 1.7
    END IF;
--add end 1.7
--del start 1.7
--    END LOOP if_data_check_loop;
--del end 1.7
--
    -- A-3-2 �̔��v�撊�o�f�[�^�`�F�b�N�ŃG���[���������ꍇ�́uForecast�����f�[�^���[�v�v
    -- �͏������Ȃ��ŃX�L�b�v����B
/*
    IF (ln_error_flg = 0) THEN
      -- A-3-3 �̔��v��Forecast�����o
FND_FILE.PUT_LINE(FND_FILE.LOG,'(A-3)-A-3-3 call....');
      get_f_degi_hanbai( lt_if_data,
                         ln_data_cnt,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg );
      -- �G���[����������A-X-6�܂ŏ������Ƃ΂�
      IF (lv_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
FND_FILE.PUT_LINE(FND_FILE.LOG,'(A-3)-A-3-3 error....');
      END IF;
    END IF;
*/
--
    --  A-3-3 ������I����������
--    IF (ln_error_flg = 0) THEN
--    END IF;
--
    -- A-3-4 ������I����������
    -- Forecast�����f�[�^���[�v
    IF (ln_error_flg = 0) THEN
      <<forecast_proc_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
        -- A-3-5 �̔��v��Forecast�o�^
        put_forecast_hanbai( lt_if_data,
                             ln_data_cnt,
                             ln_data_flg,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
--
        -- �G���[���������烋�[�v�������~
        IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
--
      -- �P�x�ڂœ��t�f�[�^�͍폜�ł��Ă���̂ŁA�Q��ڂ���̓f�[�^�Ȃ��Ƃ��ċN��
--      ln_data_flg := gn_cons_no_data_found;
      END LOOP forecast_proc_loop;
    END IF;
--
-- add start 1.11
    IF (ln_error_flg = 0) THEN
      -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
      lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_inst,
                                             t_forecast_designator_tabl);
--
      <<serch_error_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
        -- �G���[�������ꍇ
        IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                        ,gv_msg_10a_045
                                                        ,gv_tkn_api_name
                                                        ,gv_cons_api)    -- �\��API
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
      END LOOP serch_error_loop;
    END IF;
--
    -- �o�^�Ώۃf�[�^�̃��R�[�h�̏�����
    t_forecast_interface_tab_inst.delete;
    t_forecast_designator_tabl.delete;
-- add end 1.11
    -- �G���[���Ȃ������ꍇ�̓R�~�b�g����
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6���� �C���^�[�t�F�[�X�e�[�u���폜����
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
--
    -- �G���[���������珈�����~
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- A-3-2 �̔��v�撊�o�f�[�^�`�F�b�N�ŃG���[��������G���[���^�[�����邽�߂�
    -- ��O�𔭐�������
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
    END IF;
--
-- 2008/08/01 Add ��
    IF (ln_warm_flg = 1) THEN
      lv_errbuf := lv_errbuf_w;
      lv_errmsg := lv_errmsg_w;
      RAISE warn_expt;
    END IF;
-- 2008/08/01 Add ��
--
  EXCEPTION
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END forecast_hanbai;
--
  /**********************************************************************************
   * Procedure Name   : forecast_keikaku
   * Description      : �v�揤�i(A-4)
   ***********************************************************************************/
  PROCEDURE forecast_keikaku(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_keikaku'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_d  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_d VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_d  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_data_cnt   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    ln_data_flg   NUMBER;    -- ���t�f�[�^����Ȃ��t���O(0:�Ȃ��A1:����)
    ln_error_flg  NUMBER;    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O(0:�Ȃ�, 1:����)
    ln_data_cnt2   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    lb_retcode                  BOOLEAN;
--add start 1.9
    ln_warn_flg   NUMBER := 0; -- �C���^�|�t�F�[�X�f�[�^�x������t���O(0:�Ȃ�, 1:����)
--add end 1.9
-- add start ver1.15
    lv_err        VARCHAR2(5000);
-- add end ver1.15
--
    -- *** ���[�J���E���R�[�h ***
    lr_araigae_data                 araigae_tbl;

    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
-- mod start ver1.18
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
-- mod end ver1.18
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
    -- *** ���[�J���E���R�[�h ***
    lt_if_data    forecast_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR forecast_araigae_cur(pv_base_code in varchar2, pv_item_code in varchar2)
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- mod start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,             -- �I�����t
            im.item_no,                    -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id                      -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id                    -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator                -- Forecast��
      AND   mfd.organization_id        = si.organization_id                       -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   mfd.attribute5             = pv_base_code -- ���_
      AND   mfd.organization_id        = gn_3f_organization_id                    -- �݌ɑg�DID
      AND   im.item_no                 = pv_item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1                              -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id                    -- �i��ID
      AND   ((gd_keikaku_start_date   >= mfd.forecast_date
              AND
              gd_keikaku_start_date   <= mfd.rate_end_date)
        OR   (gd_keikaku_end_date     >= mfd.forecast_date
              AND
              gd_keikaku_end_date     <= mfd.rate_end_date));
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
    -- A-*-0 IF�f�[�^���ڕK�{�`�F�b�N
    if_data_null_check( gv_cons_fc_type_keikaku,      -- Forecast����('�v�揤�i')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- �G���[���������珈�����~
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-4-1 �v�揤�i�C���^�[�t�F�[�X�f�[�^���o
    get_keikaku_if_data( lt_if_data,
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg );
--    
    -- �f�[�^���擾�ł��Ȃ���΃G���[
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O������
    ln_error_flg :=0;
--
    -- ���o�f�[�^�`�F�b�N���[�v
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- ���o�����f�[�^���`�F�b�N����
      -- A-4-2 �v�揤�i���o�f�[�^�`�F�b�N
      keikaku_data_check( lt_if_data,
                          ln_data_cnt,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
      -- �G���[���������ꍇ�́A�C���^�|�t�F�[�X�f�[�^�G���[����t���OON�ɂ��A
      -- ��������S�f�[�^������(�`�F�b�N)���āA�Ō�ɃG���[������Ώ����𒆎~����B
      -- �x���Ȃ�Ώ����͑��s����B
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.9
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-4-2 �v�揤�i���o�f�[�^�`�F�b�N�ŃG���[���������ꍇ�́uForecast�����f�[�^���[�v�v
    -- �͏������Ȃ��ŃX�L�b�v����B
    IF (ln_error_flg = 0) THEN
--
    <<araigae_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
-- 2009/02/17 �{�ԏ�Q#38 DEL Start --
--        -- A-4-3 �v�揤�iForecast�����o
--        get_f_degi_keikaku( lt_if_data,
--                            ln_data_cnt,
--                            lv_errbuf,
--                            lv_retcode,
--                            lv_errmsg );
--        -- �G���[���������烋�[�v�������~
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
---- 2009/02/17 �{�ԏ�Q#38 DEL End   --
-- add start ver1.18
        -- A-4-3 �v�揤�iForecast�����o
        get_f_degi_keikaku( lt_if_data,
                            ln_data_cnt,
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg );
        -- �G���[���������烋�[�v�������~
        IF (lv_retcode = gv_status_error) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
-- add end ver1.18
--
      OPEN forecast_araigae_cur(lt_if_data(ln_data_cnt).base_code,lt_if_data(ln_data_cnt).item_code );
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
-- add start ver1.15
        -- �J�n���t�A�I�����t�̔�r
        IF   (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active) <>
              TRUNC(gd_keikaku_start_date))
          OR (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active) <>
              TRUNC(gd_keikaku_end_date))
        THEN
          -- ���b�Z�[�W�Z�b�g
          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
                                                        ,gv_msg_10a_021)
                                                                 -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                        ,1
                                                        ,5000);
          if_data_disp( lt_if_data, ln_data_cnt);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          -- ���炢�����O�f�[�^�Z�b�g
          lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- �t�H�[�L���X�g��
                    lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- �i��
                    lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- ����
                    lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- �J�n���t
                    lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- �I�����t
                    lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- ���o������
                    lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- ���P�[�X����
                    ;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
          gn_warn_cnt := gn_warn_cnt + 1;
          ln_warn_flg := 1;
        END IF;
-- add end ver1.15
        -- �폜�p�ϐ��ɃZ�b�g
-- mod start 1.11
        gn_del_data_cnt := gn_del_data_cnt + 1;
-- add start ver1.15
        gn_del_data_cnt2 := gn_del_data_cnt + 1;
-- add end ver1.15
--        t_forecast_interface_tab_del(1).transaction_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- ���ID
--        t_forecast_interface_tab_del(1).forecast_designator
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;                    -- Forecast��
--        t_forecast_interface_tab_del(1).organization_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;                        -- �g�DID
--        t_forecast_interface_tab_del(1).inventory_item_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;           -- �i��ID
--        t_forecast_interface_tab_del(1).quantity              := 0;       -- ����
--        t_forecast_interface_tab_del(1).forecast_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- �J�n���t
--        t_forecast_interface_tab_del(1).forecast_end_date
--                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- �I�����t
--        t_forecast_interface_tab_del(1).bucket_type           := 1;
--        t_forecast_interface_tab_del(1).process_status        := 2;
--        t_forecast_interface_tab_del(1).confidence_percentage := 100;
-- del start ver1.18
--        t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
--                          := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;             -- ���ID
-- del end ver1.18
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                          := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator; -- Forecast��
        t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;     -- �g�DID
        t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                          := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;             -- �i��ID
-- del start ver1.18
/*        t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;                   -- ����
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;   -- �J�n���t
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                          := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;     -- �I�����t
        t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
        t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
        t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;*/
-- del end ver1.18
--
--        -- Forecast���t�f�[�^�̃N���A
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
--        -- �G���[�������ꍇ
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn   -- 'XXCMN'
--                                                        ,gv_msg_10a_045  -- API�G���[
--                                                    ,gv_tkn_api_name
--                                                    ,gv_cons_api) -- �\��API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
     END LOOP del_loop;
-- add start ver1.15
      -- Forecast���t�f�[�^�̃N���A
     -- ���炢�����Ώۃf�[�^�̏����J�E���^��1000���𒴂����ꍇ
     IF (gn_del_data_cnt2 >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- ���炢�����Ώۃf�[�^�̏����J�E���^2�̏�����
       gn_del_data_cnt2 := 0;
       t_forecast_interface_tab_del.delete;
     -- ���o�C���^�[�t�F�[�X�f�[�^���[�v���I������ꍇ
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
--
-- del start ver1.15
    -- Forecast���t�f�[�^�̃N���A
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                          t_forecast_interface_tab_del);
-- del end ver1.15
--
    <<del_serch_error_loop>>
    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
      -- �G���[�������ꍇ
-- mod start ver1.18
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
      IF ( lb_retcode = FALSE ) THEN
-- mod end ver1.18
      FND_FILE.PUT_LINE(FND_FILE.LOG,'del_serch_error_loop');
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- API�G���[
                                                      ,gv_tkn_api_name
                                                      ,gv_cons_api)    -- �\��API
                                                      ,1
                                                      ,5000);
-- mod start ver1.18
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
-- mod end ver1.18
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
        EXIT;
      END IF;
    END LOOP del_serch_error_loop;
    -- ���炢�����Ώۃf�[�^�̏����J�E���^�̏�����
    gn_del_data_cnt := 0;
-- mod end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        -- Forecast�����f�[�^���[�v
        <<forecast_ins_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
  --
          -- A-4-3 �v�揤�iForecast�����o
          get_f_degi_keikaku( lt_if_data,
                              ln_data_cnt,
                              lv_errbuf,
                              lv_retcode,
                              lv_errmsg );
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
-- add start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- add end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
/*
        -- A-4-4 �v�揤�iForecast���t���o
        get_f_dates_keikaku( lt_if_data,
                             ln_data_cnt,
                             ln_data_flg,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        -- �G���[���������烋�[�v�������~
        IF (lv_retcode = gv_status_error) THEN
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
*/
--
          -- A-4-5 �v�揤�iForecast�o�^
          put_forecast_keikaku( lt_if_data,
                                ln_data_cnt,
                                ln_data_flg,
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg );
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
        END LOOP forecast_ins_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- �G���[�������ꍇ
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'serch_error_loop');
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                          ,gv_msg_10a_045  -- API�G���[
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api)    -- �\��API
                                                          ,1
                                                          ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
--            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- �o�^�Ώۃf�[�^�̃��R�[�h�̏�����
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
--
    END IF;
--
    -- �G���[���Ȃ������ꍇ�̓R�~�b�g����
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6���� �C���^�[�t�F�[�X�e�[�u���폜����
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- �G���[���������珈�����~
    IF (lv_retcode_d = gv_status_error) THEN
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- �e�����ŃG���[��������G���[���^�[�����邽�߂�
    -- ��O�𔭐�������
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
--add start 1.9
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.9
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
      ov_errmsg  := lv_errmsg;
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END forecast_keikaku;
--
  /**********************************************************************************
   * Procedure Name   : forecast_seigen_a
   * Description      : �o�א�����A(A-5)
   ***********************************************************************************/
  PROCEDURE forecast_seigen_a(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_seigen_a'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_d   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_d  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_d   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_data_cnt   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    ln_data_flg   NUMBER;    -- ���t�f�[�^����Ȃ��t���O(0:�Ȃ��A1:����)
    ln_error_flg  NUMBER;    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O(0:�Ȃ�, 1:����)
    lv_err_msg2  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_data_cnt2   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    lb_retcode                  BOOLEAN;
--add start 1.9
    ln_warn_flg   NUMBER := 0; -- �C���^�|�t�F�[�X�f�[�^�x������t���O(0:�Ȃ�, 1:����)
--add end 1.9
-- add start ver1.15
    lv_err        VARCHAR2(5000);
-- add end ver1.15
--
    -- *** ���[�J���E���R�[�h ***
    lt_if_data    forecast_tbl;
    lr_araigae_data                 araigae_tbl;
-- mod start ver1.18
--    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
-- mod end ver1.18
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR forecast_araigae_cur(pv_item_code in varchar2)
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- mod start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,             -- �I�����t
            im.item_no,                    -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id       -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast��
      AND   mfd.organization_id        = gn_3f_organization_id     -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
      AND   im.item_no                 = pv_item_code -- �i�ڃR�[�h
      AND   im.item_no                 = si.segment1               -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- �i��ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
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
    -- A-*-0 IF�f�[�^���ڕK�{�`�F�b�N
    if_data_null_check( gv_cons_fc_type_seigen_a,      -- Forecast����('�o�א�����A')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- �G���[���������珈�����~
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-5-1 �o�א�����A�C���^�[�t�F�[�X�f�[�^���o
    get_seigen_a_if_data( lt_if_data,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- �f�[�^���擾�ł��Ȃ���΃G���[
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O������
    ln_error_flg :=0;
    -- ���o�f�[�^�`�F�b�N���[�v
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- ���o�����f�[�^���`�F�b�N����
      -- A-5-2 �o�א�����A���o�f�[�^�`�F�b�N
      seigen_a_data_check( lt_if_data,
                          ln_data_cnt,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
      -- �G���[���������ꍇ�́A�C���^�|�t�F�[�X�f�[�^�G���[����t���OON�ɂ��A
      -- ��������S�f�[�^������(�`�F�b�N)���āA�Ō�ɃG���[������Ώ����𒆎~����B
      -- �x���Ȃ�Ώ����͑��s����B
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.9
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-5-2 �o�א�����A���o�f�[�^�`�F�b�N�ŃG���[���������ꍇ�́uForecast�����f�[�^���[�v�v
    -- �͏������Ȃ��ŃX�L�b�v����B
    IF (ln_error_flg = 0) THEN
--
      -- Forecast�����f�[�^���[�v
      <<araigae_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
-- 2009/02/17 �{�ԏ�Q#38�Ή� DEL Start --
--        -- A-5-3 �o�א�����AForecast�����o
--        get_f_degi_seigen_a( lt_if_data,
--                             ln_data_cnt,
--                             lv_errbuf,
--                             lv_retcode,
--                             lv_errmsg );
--        lv_err_msg2 := lv_errmsg;
--        -- �G���[���������烋�[�v�������~
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
-- 2009/02/17 �{�ԏ�Q#38�Ή� DEL End ----
-- add start ver1.18
        -- A-5-3 �o�א�����AForecast�����o
        get_f_degi_seigen_a( lt_if_data,
                             ln_data_cnt,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        lv_err_msg2 := lv_errmsg;
        -- �G���[���������烋�[�v�������~
        IF (lv_retcode = gv_status_error) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
-- add end ver1.18
--
      OPEN forecast_araigae_cur(lt_if_data(ln_data_cnt).item_code);
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
--
      -- �J�n���t�̔�r
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).start_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- ���炢�����O�f�[�^�Z�b�g
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- �t�H�[�L���X�g��
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- �i��
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- ����
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- �J�n���t
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- �I�����t
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- ���o������
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- ���P�[�X����
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
        gn_warn_cnt := gn_warn_cnt + 1;
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- �I�����t�̔�r
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).end_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- ���炢�����O�f�[�^�Z�b�g
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- �t�H�[�L���X�g��
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- �i��
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- ����
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- �J�n���t
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- �I�����t
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- ���o������
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- ���P�[�X����
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
        gn_warn_cnt := gn_warn_cnt + 1;
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
-- mod start 1.11
        gn_del_data_cnt := gn_del_data_cnt + 1;
-- add start ver1.15
        gn_del_data_cnt2 := gn_del_data_cnt + 1;
-- add end ver1.15
--      t_forecast_interface_tab_del(1).transaction_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- ���ID
--      t_forecast_interface_tab_del(1).forecast_designator
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast��
--      t_forecast_interface_tab_del(1).organization_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- �g�DID
--      t_forecast_interface_tab_del(1).inventory_item_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- �i��ID
--      t_forecast_interface_tab_del(1).quantity              := 0;        -- ����
--      t_forecast_interface_tab_del(1).forecast_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- �J�n���t
--      t_forecast_interface_tab_del(1).forecast_end_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- �I�����t
--      t_forecast_interface_tab_del(1).bucket_type           := 1;
--      t_forecast_interface_tab_del(1).process_status        := 2;
--      t_forecast_interface_tab_del(1).confidence_percentage := 100;
-- del start ver1.18
--        t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
--                           := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- ���ID
-- del end ver1.18
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                           := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast��
        t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                           := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- �g�DID
        t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                           := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- �i��ID
-- del start ver1.18
/*        t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;        -- ����
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                           := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- �J�n���t
        t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                           := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- �I�����t
        t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
        t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
        t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;*/
-- del end ver1.18
--
      -- �o�^�ς݃f�[�^�̍폜
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
        -- �G���[�������ꍇ
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                        ,gv_msg_10a_045 -- API�G���[
--                                                        ,gv_tkn_api_name
--                                                        ,gv_cons_api) -- �\��API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
      END LOOP del_loop;
-- add start ver1.15
      -- Forecast���t�f�[�^�̃N���A
     -- ���炢�����Ώۃf�[�^�̏����J�E���^��1000���𒴂����ꍇ
     IF (gn_del_data_cnt2 >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- ���炢�����Ώۃf�[�^�̏����J�E���^2�̏�����
       gn_del_data_cnt2 := 0;
       t_forecast_interface_tab_del.delete;
     -- ���o�C���^�[�t�F�[�X�f�[�^���[�v���I������ꍇ
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
-- del start ver1.15
    -- Forecast���t�f�[�^�̃N���A
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_del);
-- del end ver1.15
--
    <<del_serch_error_loop>>
    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
      -- �G���[�������ꍇ
-- mod start ver1.18
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
      IF ( lb_retcode = FALSE ) THEN
-- mod end ver1.18
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- API�G���[
                                                      ,gv_tkn_api_name
                                                      ,gv_cons_api)    -- �\��API
                                                      ,1
                                                      ,5000);
-- mod start ver1.18
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
-- mod end ver1.18
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
        EXIT;
      END IF;
    END LOOP del_serch_error_loop;
    -- ���炢�����Ώۃf�[�^�̏����J�E���^�̏�����
    gn_del_data_cnt := 0;
-- mod end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        <<forecast_ins_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
          -- A-5-3 �o�א�����AForecast�����o
          get_f_degi_seigen_a( lt_if_data,
                               ln_data_cnt,
                               lv_errbuf,
                               lv_retcode,
                               lv_errmsg );
          lv_err_msg2 := lv_errmsg;
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  --
  /*
          -- A-5-4 �o�א�����AForecast���t���o
          get_f_dates_seigen_a( lt_if_data,
                                ln_data_cnt,
                                ln_data_flg,
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg );
          lv_err_msg2 := lv_errmsg;
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  */
--
          -- A-5-5 �o�א�����AForecast�o�^
          put_forecast_seigen_a( lt_if_data,
                                 ln_data_cnt,
                                 ln_data_flg,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg );
          lv_err_msg2 := lv_errmsg;
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
--
        END LOOP forecast_ins_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- �G���[�������ꍇ
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                          ,gv_msg_10a_045  -- API�G���[
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api)    -- �\��API
                                                          ,1
                                                          ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- �o�^�Ώۃf�[�^�̃��R�[�h�̏�����
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
    END IF;
--
    -- �G���[���Ȃ������ꍇ�̓R�~�b�g����
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6���� �C���^�[�t�F�[�X�e�[�u���폜����
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- �G���[���������珈�����~
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- A-5-2 �o�א�����A���o�f�[�^�`�F�b�N�ŃG���[��������G���[���^�[�����邽�߂�
    -- ��O�𔭐�������
    IF (ln_error_flg = 1) THEN
      lv_errmsg := lv_err_msg2;
      RAISE global_api_expt;
--add start 1.9
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.9
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
--del start 1.9
--      ov_errmsg  := lv_errmsg;
--del end 1.9
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END forecast_seigen_a;
--
  /**********************************************************************************
   * Procedure Name   : forecast_seigen_b
   * Description      : �o�א�����B(A-6)
   ***********************************************************************************/
  PROCEDURE forecast_seigen_b(
    ov_errbuf                OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode               OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg                OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'forecast_seigen_b'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_d  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_d VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_d  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    ln_data_cnt   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    ln_data_flg   NUMBER;    -- ���t�f�[�^����Ȃ��t���O(0:�Ȃ��A1:����)
    ln_error_flg  NUMBER;    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O(0:�Ȃ�, 1:����)
    ln_data_cnt2   NUMBER;    -- ���o�C���^�[�t�F�[�X�f�[�^�̏����J�E���^
    lb_retcode                  BOOLEAN;
--add start 1.9
    ln_warn_flg   NUMBER := 0; -- �C���^�|�t�F�[�X�f�[�^�x������t���O(0:�Ȃ�, 1:����)
--add end 1.9
-- add start ver1.15
    lv_err        VARCHAR2(5000);
-- add end ver1.15
--
    -- *** ���[�J���E���R�[�h ***
    lr_araigae_data                 araigae_tbl;
-- mod start ver1.18
--    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_interface_tab_del    MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
-- mod end ver1.18
    t_forecast_interface_tab_ins    MRP_FORECAST_INTERFACE_PK.t_forecast_interface;
    t_forecast_designator_tab       MRP_FORECAST_INTERFACE_PK.t_forecast_designator;
    lt_if_data    forecast_tbl;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR forecast_araigae_cur(pv_item_code in varchar2)
    IS
    SELECT  mfd.transaction_id,          -- ���ID
            mfd.forecast_designator,     -- Forecast��
            mfd.organization_id,         -- �݌ɑg�DID
            mfd.inventory_item_id,       -- �i��ID
            mfd.forecast_date,           -- �J�n���t
-- mod start ver1.15
--            mfd.rate_end_date            -- �I�����t
            mfd.rate_end_date,             -- �I�����t
            im.item_no,                    -- �i�ڃR�[�h
            mfd.current_forecast_quantity, -- ����
            mfd.attribute6,                -- ���P�[�X����
            mfd.attribute4                 -- ���o������
-- mod end ver1.15
    FROM    mrp_forecast_dates  mfd,   -- Forecast���t
            mrp_forecast_items  mfi,   -- Forecast�i��
            ic_item_mst_vl        im,    -- OPM�i�ڃ}�X�^
            mtl_system_items_vl   si     -- �i�ڃ}�X�^
    WHERE   mfd.organization_id        = mfi.organization_id       -- �݌ɑg�DID
      AND   mfd.inventory_item_id      = mfi.inventory_item_id     -- �i��ID
      AND   mfd.forecast_designator    = gv_3f_forecast_designator -- Forecast��
      AND   mfd.organization_id        = gn_3f_organization_id     -- �݌ɑg�DID
      AND   mfi.forecast_designator    = mfd.forecast_designator
      AND   si.organization_id         = mfd.organization_id
AND (im.item_no = NVL(pv_item_code,im.item_no)
  OR
     im.item_no IS NULL )
      AND   im.item_no                 = si.segment1               -- �i�ڃR�[�h
      AND   si.inventory_item_id       = mfd.inventory_item_id     -- �i��ID
      AND   ((gd_in_start_date         >= mfd.forecast_date
              AND
              gd_in_start_date         <= mfd.rate_end_date)
        OR   (gd_in_end_date           >= mfd.forecast_date
              AND
              gd_in_end_date           <= mfd.rate_end_date));
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
    -- A-*-0 IF�f�[�^���ڕK�{�`�F�b�N
    if_data_null_check( gv_cons_fc_type_seigen_b,      -- Forecast����('�o�א�����B')
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg );
--
    -- �G���[���������珈�����~
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    END IF;
--
    -- A-6-1 �o�א�����B�C���^�[�t�F�[�X�f�[�^���o
    get_seigen_b_if_data( lt_if_data,
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg );
--
    -- �f�[�^���擾�ł��Ȃ���΃G���[
    IF (lv_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_api_expt;
    ELSIF (lv_retcode = gv_status_warn) THEN
--del start 1.5
--      gn_warn_cnt := gn_warn_cnt + 1;
--del end 1.5
      RAISE warn_expt;
    END IF;
--
    -- �C���^�|�t�F�[�X�f�[�^�G���[����t���O������
    ln_error_flg :=0;
--
    -- ���o�f�[�^�`�F�b�N���[�v
    <<if_data_check_loop>>
    FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
      -- ���o�����f�[�^���`�F�b�N����
      -- A-6-2 �o�א�����B���o�f�[�^�`�F�b�N
      seigen_b_data_check( lt_if_data,
                           ln_data_cnt,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg );
      -- �G���[���������ꍇ�́A�C���^�|�t�F�[�X�f�[�^�G���[����t���OON�ɂ��A
      -- ��������S�f�[�^������(�`�F�b�N)���āA�Ō�ɃG���[������Ώ����𒆎~����B
      -- �x���Ȃ�Ώ����͑��s����B
      IF (lv_retcode = gv_status_error) THEN
        ln_error_flg := 1;
--add start 1.9
      ELSIF (lv_retcode = gv_status_warn) THEN
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
    END LOOP if_data_check_loop;
--
    -- A-6-2 �o�א�����B���o�f�[�^�`�F�b�N�ŃG���[���������ꍇ�́uForecast�����f�[�^���[�v�v
    -- �͏������Ȃ��ŃX�L�b�v����B
    IF (ln_error_flg = 0) THEN
      -- Forecast�����f�[�^���[�v
      <<araigae_loop>>
      FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
-- 2009/02/17 �{�ԏ�Q#38�Ή� DEL Start --
--        -- A-6-3 �o�א�����BForecast�����o
--        get_f_degi_seigen_b( lt_if_data,
--                             ln_data_cnt,
--                             lv_errbuf,
--                             lv_retcode,
--                             lv_errmsg );
--        -- �G���[���������烋�[�v�������~
--        IF (lv_retcode = gv_status_error) THEN
---- mod start 1.11
--          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
---- mod end 1.11
--          gn_error_cnt := gn_error_cnt + 1;
--          ln_error_flg := 1;
--          EXIT;
--        END IF;
-- 2009/02/17 �{�ԏ�Q#38�Ή� DEL End ----
-- add start ver1.18
        -- A-6-3 �o�א�����BForecast�����o
        get_f_degi_seigen_b( lt_if_data,
                             ln_data_cnt,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg );
        -- �G���[���������烋�[�v�������~
        IF (lv_retcode = gv_status_error) THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          gn_error_cnt := gn_error_cnt + 1;
          ln_error_flg := 1;
          EXIT;
        END IF;
-- add end ver1.18
--
      OPEN forecast_araigae_cur(lt_if_data(ln_data_cnt).item_code);
--
      FETCH forecast_araigae_cur BULK COLLECT INTO lr_araigae_data;
--
      gn_araigae_cnt := lr_araigae_data.COUNT;
--
      CLOSE forecast_araigae_cur;
--
      <<del_loop>>
      FOR ln_data_cnt2 IN 1..gn_araigae_cnt LOOP
--
      -- �J�n���t�̔�r
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).start_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- ���炢�����O�f�[�^�Z�b�g
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- �t�H�[�L���X�g��
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- �i��
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- ����
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- �J�n���t
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- �I�����t
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- ���o������
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- ���P�[�X����
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- �I�����t�̔�r
      IF (TRUNC(lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active) <>
        TRUNC(lt_if_data(ln_data_cnt).end_date_active))
      THEN
        -- ���b�Z�[�W�Z�b�g
-- mod start ver1.15
--mod start 1.9
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--        ov_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_inv   -- 'XXINV'
--mod end 1.9
                                                               -- �t�H�[�L���X�g���t�X�V���[�j���O
                                                      ,gv_msg_10a_021)
                                                      ,1
                                                      ,5000);
        -- �������ʃ��|�[�g�ɏo��
        if_data_disp( lt_if_data, ln_data_cnt);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        -- ���炢�����O�f�[�^�Z�b�g
        lv_err := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator || ',' || -- �t�H�[�L���X�g��
                  lr_araigae_data(ln_data_cnt2).gd_4f_item_no             || ',' || -- �i��
                  lr_araigae_data(ln_data_cnt2).gd_4f_quantity            || ',' || -- ����
                  lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active   || ',' || -- �J�n���t
                  lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active     || ',' || -- �I�����t
                  lr_araigae_data(ln_data_cnt2).gd_4f_case_quantity       || ',' || -- ���o������
                  lr_araigae_data(ln_data_cnt2).gd_4f_bara_quantity                 -- ���P�[�X����
                  ;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_object || lv_err);
-- mod end ver1.15
--add start 1.9
        ln_warn_flg := 1;
--add end 1.9
      END IF;
--
      -- �o�^�ς݃f�[�^�̍폜�̂��߂̃f�[�^�Z�b�g
-- mod start 1.11
      gn_del_data_cnt := gn_del_data_cnt + 1;
-- add start ver1.15
      gn_del_data_cnt2 := gn_del_data_cnt + 1;
-- add end ver1.15
--      t_forecast_interface_tab_del(1).transaction_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- ���ID
--      t_forecast_interface_tab_del(1).forecast_designator
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast��
--      t_forecast_interface_tab_del(1).organization_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- �g�DID
--      t_forecast_interface_tab_del(1).inventory_item_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- �i��ID
--      t_forecast_interface_tab_del(1).quantity              := 0;        -- ����
--      t_forecast_interface_tab_del(1).forecast_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- �J�n���t
--      t_forecast_interface_tab_del(1).forecast_end_date
--                         := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- �I�����t
--      t_forecast_interface_tab_del(1).bucket_type           := 1;
--      t_forecast_interface_tab_del(1).process_status        := 2;
--      t_forecast_interface_tab_del(1).confidence_percentage := 100;
-- del start ver1.18
--      t_forecast_interface_tab_del(gn_del_data_cnt).transaction_id
--                         := lr_araigae_data(ln_data_cnt2).gv_4f_txns_id;            -- ���ID
-- del end ver1.18
      t_forecast_interface_tab_del(gn_del_data_cnt).forecast_designator
                         := lr_araigae_data(ln_data_cnt2).gv_4f_forecast_designator;-- Forecast��
      t_forecast_interface_tab_del(gn_del_data_cnt).organization_id
                         := lr_araigae_data(ln_data_cnt2).gv_4f_organization_id;    -- �g�DID
      t_forecast_interface_tab_del(gn_del_data_cnt).inventory_item_id
                         := lr_araigae_data(ln_data_cnt2).gv_4f_item_id;            -- �i��ID
-- del start ver1.18
/*      t_forecast_interface_tab_del(gn_del_data_cnt).quantity              := 0;        -- ����
      t_forecast_interface_tab_del(gn_del_data_cnt).forecast_date
                         := lr_araigae_data(ln_data_cnt2).gd_4f_start_date_active;  -- �J�n���t
      t_forecast_interface_tab_del(gn_del_data_cnt).forecast_end_date
                         := lr_araigae_data(ln_data_cnt2).gd_4f_end_date_active;    -- �I�����t
      t_forecast_interface_tab_del(gn_del_data_cnt).bucket_type           := 1;
      t_forecast_interface_tab_del(gn_del_data_cnt).process_status        := 2;
      t_forecast_interface_tab_del(gn_del_data_cnt).confidence_percentage := 100;*/
-- del end ver1.18
--
      -- �o�^�ς݃f�[�^�̍폜
--        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                              t_forecast_interface_tab_del);
        -- �G���[�������ꍇ
--        IF (lb_retcode = FALSE )THEN
--          lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
--                                                        ,gv_msg_10a_045 -- API�G���[
--                                                        ,gv_tkn_api_name
--                                                        ,gv_cons_api) -- �\��API
--                                                        ,1
--                                                        ,5000);
--          RAISE global_api_expt;
--        END IF;
      END LOOP del_loop;
-- add start ver1.15
      -- Forecast���t�f�[�^�̃N���A
     -- ���炢�����Ώۃf�[�^�̏����J�E���^��1000���𒴂����ꍇ
     IF (gn_del_data_cnt2 >= 1000) THEN
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
       -- ���炢�����Ώۃf�[�^�̏����J�E���^2�̏�����
       gn_del_data_cnt2 := 0;
       t_forecast_interface_tab_del.delete;
     -- ���o�C���^�[�t�F�[�X�f�[�^���[�v���I������ꍇ
-- mod start ver1.16
--     ELSIF (ln_data_cnt = gn_araigae_cnt) THEN
     ELSIF (ln_data_cnt = gn_target_cnt) THEN
-- mod end ver1.16
--
       lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                             t_forecast_interface_tab_del);
     END IF;
-- add end ver1.15
    END LOOP araigae_loop;
-- del start ver1.15
    -- Forecast���t�f�[�^�̃N���A
--    lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
--                                           t_forecast_interface_tab_del);
-- del end ver1.15
--
    <<del_serch_error_loop>>
    FOR ln_data_cnt IN 1..gn_del_data_cnt LOOP
      -- �G���[�������ꍇ
-- mod start ver1.18
--      IF ( t_forecast_interface_tab_del(ln_data_cnt).process_status <> 5 ) THEN
      IF ( lb_retcode = FALSE ) THEN
-- mod end ver1.18
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                      ,gv_msg_10a_045  -- API�G���[
                                                      ,gv_tkn_api_name
                                                      ,gv_cons_api)    -- �\��API
                                                      ,1
                                                      ,5000);
-- mod start ver1.18
--        FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_del(ln_data_cnt).error_message);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
-- mod end ver1.18
        gn_error_cnt := gn_error_cnt + 1;
        ln_error_flg := 1;
        EXIT;
      END IF;
    END LOOP del_serch_error_loop;
    -- ���炢�����Ώۃf�[�^�̏����J�E���^�̏�����
    gn_del_data_cnt := 0;
-- mod end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
-- add end 1.11
        <<forecast_proc_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
--
          -- A-6-3 �o�א�����BForecast�����o
          get_f_degi_seigen_b( lt_if_data,
                               ln_data_cnt,
                               lv_errbuf,
                               lv_retcode,
                               lv_errmsg );
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
-- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
-- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  --
  /*
          -- A-6-4 �o�א�����BForecast���t���o
          get_f_dates_seigen_b( lt_if_data,
                                ln_data_cnt,
                                ln_data_flg,
                                lv_errbuf,
                                lv_retcode,
                                lv_errmsg );
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  */
  --
          -- A-6-5 �o�א�����BForecast�o�^
          put_forecast_seigen_b( lt_if_data,
                                 ln_data_cnt,
                                 ln_data_flg,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg );
          -- �G���[���������烋�[�v�������~
          IF (lv_retcode = gv_status_error) THEN
  -- mod start 1.11
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
  -- mod end 1.11
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
            EXIT;
          END IF;
  --
        END LOOP forecast_proc_loop;
-- add start 1.11
      END IF;
-- add end 1.11
--
-- add start 1.11
      IF (ln_error_flg = 0) THEN
        -- Forecast�f�[�^�ɒ��o�����C���^�[�t�F�[�X�f�[�^��o�^
        lb_retcode := MRP_FORECAST_INTERFACE_PK.MRP_FORECAST_INTERFACE(
                                               t_forecast_interface_tab_inst,
                                               t_forecast_designator_tabl);
--
        <<serch_error_loop>>
        FOR ln_data_cnt IN 1..gn_target_cnt LOOP
          -- �G���[�������ꍇ
          IF ( t_forecast_interface_tab_inst(ln_data_cnt).process_status <> 5 ) THEN
            lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn  -- 'XXCMN'
                                                          ,gv_msg_10a_045  -- API�G���[
                                                          ,gv_tkn_api_name
                                                          ,gv_cons_api)    -- �\��API
                                                          ,1
                                                          ,5000);
            FND_FILE.PUT_LINE(FND_FILE.LOG,t_forecast_interface_tab_inst(ln_data_cnt).error_message);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
            gn_error_cnt := gn_error_cnt + 1;
            ln_error_flg := 1;
          END IF;
        END LOOP serch_error_loop;
      END IF;
--
      -- �o�^�Ώۃf�[�^�̃��R�[�h�̏�����
      t_forecast_interface_tab_inst.delete;
      t_forecast_designator_tabl.delete;
-- add end 1.11
    END IF;
--
    -- �G���[���Ȃ������ꍇ�̓R�~�b�g����
    IF (ln_error_flg = 0) THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
--
    -- A-X-6���� �C���^�[�t�F�[�X�e�[�u���폜����
    del_if_data( lt_if_data,
                 lv_errbuf_d,
                 lv_retcode_d,
                 lv_errmsg_d );
    -- �G���[���������珈�����~
    IF (lv_retcode_d = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      lv_errbuf    := lv_errbuf_d;
      lv_retcode   := lv_retcode_d;
      lv_errmsg    :=lv_errmsg_d;
      RAISE global_api_expt;
    END IF;
--
    -- A-6-2 �o�א�����B���o�f�[�^�`�F�b�N�ŃG���[��������G���[���^�[�����邽�߂�
    -- ��O�𔭐�������
    IF (ln_error_flg = 1) THEN
      RAISE global_api_expt;
--add start 1.9
    ELSIF (ln_warn_flg = 1) THEN
      RAISE warn_expt;
--add end 1.9
    END IF;
--
  EXCEPTION
    WHEN warn_expt THEN
--del start 1.9
--      ov_errmsg  := lv_errmsg;
--del end 1.9
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
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END forecast_seigen_b;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE submain(
    iv_forecast_designator IN  VARCHAR2,         -- Forecast�敪
    iv_forecast_yyyymm     IN  VARCHAR2,         -- �N��
    iv_forecast_year       IN  VARCHAR2,         -- �N�x
    iv_forecast_version    IN  VARCHAR2,         -- ����
    iv_forecast_date       IN  VARCHAR2,         -- �J�n���t
    iv_forecast_end_date   IN  VARCHAR2,         -- �I�����t
    iv_item_no             IN  VARCHAR2,         -- �i��
    iv_location_code       IN  VARCHAR2,         -- �o�ɑq��
    iv_account_number      IN  VARCHAR2,         -- ���_
    iv_dept_code_flg       IN  VARCHAR2,         -- �捞�������o�t���O
    ov_errbuf              OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lc_out_par    VARCHAR2(1000);   -- ���̓p�����[�^�̏������ʃ��|�[�g�o�͗p
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- ���̓p�����[�^�̔N����ۑ�
    gv_in_yyyymm := iv_forecast_yyyymm;
--
    -- �N�x
    gv_forecast_year := iv_forecast_year;
--
    -- ����
    gv_forecast_version := iv_forecast_version;
--
    -- �J�n���t
    -- �����ŕϊ��G���[�ɂȂ��Ă��X���[���Č�q�̓��̓p�����[�^�`�F�b�N�ŃG���[�ɂ���
    gd_in_start_date := FND_DATE.STRING_TO_DATE(iv_forecast_date,'YYYY/MM/DD');
    gv_in_start_date := iv_forecast_date;
--
    -- �I�����t
    -- �����ŕϊ��G���[�ɂȂ��Ă��X���[���Č�q�̓��̓p�����[�^�`�F�b�N�ŃG���[�ɂ���
    gd_in_end_date := FND_DATE.STRING_TO_DATE(iv_forecast_end_date,'YYYY/MM/DD');
    gv_in_end_date := iv_forecast_end_date;
--
    -- �i��
    gv_in_item_code := iv_item_no;
--
    -- �o�ɑq��
    gv_in_location_code := iv_location_code;
--
    -- ���_
    gv_in_base_code := iv_account_number;
--
    -- �捞�������o�t���O
    gv_in_dept_code_flg := iv_dept_code_flg;
--
    -- ===============================
    -- A-1-1 �V�X�e�����t�擾
    -- ===============================
    gd_sysdate_yyyymmdd := TRUNC(SYSDATE);
--
    -- ========================================================
    -- A-1-2 ���̓p�����[�^�`�F�b�N
    -- �e�p�����[�^�`�F�b�N�ł̓`�F�b�N���Ȃ����̂ł������Ԃ�
    -- ========================================================
    -- A-1-2-1 Forecast�`�F�b�N
    parameter_check_forecast(iv_forecast_designator,  -- Forecast�敪
                             ov_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
                             ov_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
                             ov_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- Forecast���ނ��o��
    lc_out_par := gv_cons_input_forecast || gv_forecast_designator ;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    -- ���̓p�����[�^�����̂��ďo��
    lc_out_par := gv_cons_input_param  || iv_forecast_designator || gv_msg_pnt ||
                  iv_forecast_yyyymm   || gv_msg_pnt || iv_forecast_year || gv_msg_pnt ||
                  iv_forecast_version  || gv_msg_pnt || iv_forecast_date || gv_msg_pnt ||
                  iv_forecast_end_date || gv_msg_pnt || iv_item_no       || gv_msg_pnt ||
                  iv_location_code     || gv_msg_pnt || iv_account_number|| gv_msg_pnt ||
                  iv_dept_code_flg;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-2 �N���`�F�b�N
    parameter_check_yyyymm(iv_forecast_designator,  -- Forecast�敪
                           iv_forecast_yyyymm,      -- �N��
                           ov_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
                           ov_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
                           ov_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- �N���Ȃ̂Ō������E���������Z�o���ĕۑ�(BETWEEN�Ɏg�p�ł���)=�`�F�b�N��Ȃ̂ŃG���[�͂Ȃ�
    gd_in_yyyymmdd_start := FND_DATE.STRING_TO_DATE(gv_in_yyyymm,'yyyymm');
    gd_in_yyyymmdd_end := ADD_MONTHS(FND_DATE.STRING_TO_DATE(gv_in_yyyymm,'yyyymm'),1)-1;
    -- A-1-2-3 �N�x�`�F�b�N
    parameter_check_forecast_year(iv_forecast_designator, -- Forecast�敪
                                  iv_forecast_year,       -- �N�x
                                  ov_errbuf,              -- �G���[�E���b�Z�[�W        --# �Œ� #
                                  ov_retcode,             -- ���^�[���E�R�[�h          --# �Œ� #
                                  ov_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-4 ����`�F�b�N
    parameter_check_version(iv_forecast_designator,  -- Forecast�敪
                            iv_forecast_version,     -- ����
                            ov_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
                            ov_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
                            ov_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-5 �J�n���t�E�I�����t�`�F�b�N
    parameter_check_forecast_date(iv_forecast_designator, -- Forecast�敪
                                  iv_forecast_date,       -- �J�n���t
                                  iv_forecast_end_date,   -- �I�����t
                                  ov_errbuf,              -- �G���[�E���b�Z�[�W        --# �Œ� #
                                  ov_retcode,             -- ���^�[���E�R�[�h          --# �Œ� #
                                  ov_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-6 �i�ڃ`�F�b�N
    parameter_check_item_no(iv_forecast_designator,  -- Forecast�敪
                            iv_item_no,              -- �i��
                            ov_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
                            ov_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
                            ov_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-7 �o�ɑq�Ƀ`�F�b�N
    parameter_check_subinventory(iv_forecast_designator, -- Forecast�敪
                                 iv_location_code,       -- �o�ɑq��
                                 ov_errbuf,              -- �G���[�E���b�Z�[�W        --# �Œ� #
                                 ov_retcode,             -- ���^�[���E�R�[�h          --# �Œ� #
                                 ov_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-8 ���_�`�F�b�N
    parameter_check_account_number(iv_forecast_designator,-- Forecast�敪
                                   iv_account_number,     -- ���_
                                   ov_errbuf,             -- �G���[�E���b�Z�[�W        --# �Œ� #
                                   ov_retcode,            -- ���^�[���E�R�[�h          --# �Œ� #
                                   ov_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W--# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- A-1-2-9 �捞�����`�F�b�N
    parameter_check_dept_code(iv_forecast_designator,  -- Forecast�敪
                              iv_dept_code_flg,        -- �捞�������o�t���O
                              ov_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ov_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
                              ov_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- A-1-3 �v���t�@�C���E�I�v�V�����l�̎擾
    -- =======================================
    get_profile_start_day(ov_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
                          ov_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
                          ov_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===========================================
    -- A-1-4 �Ώ۔N�x�J�n���E�Ώ۔N�x�I�����̎擾
    -- ===========================================
    -- �̔��v��̂ݎ��s�����
    IF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
      get_start_end_day(iv_forecast_year,     -- �N�x(���̓p�����[�^)
                        ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                        ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                        ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�Ȃ�Β��~
      IF (ov_retcode = gv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-1-5 �J�n���t�E�I�����t�̎擾
    -- ===============================
    get_keikaku_start_end_day(ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                              ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1-6 �������̎擾
    -- ===============================
    get_dept_inf(ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                 ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                 ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    -- �G���[�Ȃ�Β��~
    IF (ov_retcode = gv_status_error) THEN
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- Forecast���ނɂ��U������
    -- ===============================================
    IF (iv_forecast_designator = gv_cons_fc_type_hikitori) THEN
      -- ����v��
      forecast_hikitori(ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                        ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                        ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�Ȃ�Β��~
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_keikaku) THEN
      -- �v�揤�i
      forecast_keikaku(ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                       ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                       ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�Ȃ�Β��~
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_a) THEN
      -- �o�א�����A
      forecast_seigen_a(ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                        ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                        ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�Ȃ�Β��~
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_seigen_b) THEN
      -- �o�א�����B
      forecast_seigen_b(ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                        ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                        ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�Ȃ�Β��~
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    ELSIF (iv_forecast_designator = gv_cons_fc_type_hanbai) THEN
      -- �̔��v��
      forecast_hanbai(ov_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
                      ov_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
                      ov_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      -- �G���[�Ȃ�Β��~
      IF (ov_retcode = gv_status_error) THEN
        RAISE global_process_expt;
--add start 1.9
      ELSIF (ov_retcode = gv_status_warn) THEN
        RAISE warn_expt;
--add end 1.9
      END IF;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN warn_expt THEN
--del start 1.9
--      ov_errmsg  := lv_errmsg;
--del end 1.9
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--del start 1.7
--      ov_errmsg  := lv_errmsg;
--del end 1.7
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||ov_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
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
    errbuf                 OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h    --# �Œ� #
    iv_forecast_designator IN  VARCHAR2,         -- Forecast�敪
    iv_forecast_yyyymm     IN  VARCHAR2,         -- �N��('YYYYMM')
    iv_forecast_year       IN  VARCHAR2,         -- �N�x('YYYY')
    iv_forecast_version    IN  VARCHAR2,         -- ����
    iv_forecast_date       IN  VARCHAR2,         -- �J�n���t('YYYYMMDD')
    iv_forecast_end_date   IN  VARCHAR2,         -- �I�����t('YYYYMMDD')
    iv_item_no             IN  VARCHAR2,         -- �i��
    iv_location_code       IN  VARCHAR2,         -- �o�ɑq��
    iv_account_number      IN  VARCHAR2,         -- ���_
    iv_dept_code           IN  VARCHAR2)         -- �捞����
IS
--
--###########################  �Œ胍�[�J���萔�ϐ��錾�� START   ###########################
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
--#####################################  �Œ蕔 END   #######################################
--
  BEGIN
--
--#########################  �Œ�X�e�[�^�X�������� START  ########################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := FND_GLOBAL.USER_NAME;
    -- ���i�敪�擾
    gv_item_div := SUBSTR(FND_PROFILE.VALUE(gv_prf_item_div),1,10);
    -- �i�ڋ敪�擾
    gv_article_div := SUBSTR(FND_PROFILE.VALUE(gv_prf_article_div),1,10);
--
    --���s�R���J�����g���擾
    SELECT  fcp.concurrent_program_name
    INTO    gv_conc_name
    FROM    fnd_concurrent_programs fcp
    WHERE   fcp.application_id        = FND_GLOBAL.PROG_APPL_ID
      AND   fcp.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
      AND   ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_001, gv_tkn_user,
                                           gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_002, gv_tkn_conc,
                                           gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_046,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_003);
--
--###########################  �Œ蕔 END   #######################################################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;   -- �Ώی���
    gn_normal_cnt := 0;   -- ���팏��
    gn_warn_cnt   := 0;   -- �x������
    gn_error_cnt  := 0;   -- �G���[����
--
    -- ���O�C��ID�A���[�UID�̎擾
    gn_login_user := FND_GLOBAL.LOGIN_ID;
    gn_created_by := FND_GLOBAL.USER_ID;
--
-- 2008/08/01 Add ��
-- WHO�J�����Z�b�g
    gn_last_updated_by         := FND_GLOBAL.USER_ID;
    gn_request_id              := FND_GLOBAL.CONC_REQUEST_ID;
    gn_program_application_id  := FND_GLOBAL.QUEUE_APPL_ID;
    gn_program_id              := FND_GLOBAL.CONC_PROGRAM_ID;
    gd_who_sysdate             := SYSDATE;
-- 2008/08/01 Add ��
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(iv_forecast_designator, -- Forecast�敪
            iv_forecast_yyyymm,     -- �N��('YYYYMM')
            iv_forecast_year,       -- �N�x('YYYY')
            iv_forecast_version,    -- ����
            iv_forecast_date,       -- �J�n���t('YYYYMMDD')
            iv_forecast_end_date,   -- �I�����t('YYYYMMDD')
            iv_item_no,             -- �i��
            iv_location_code,       -- �o�ɑq��
            iv_account_number,      -- ���_
            iv_dept_code,           -- �捞����
            lv_errbuf,              -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,             -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ((lv_retcode = gv_status_error) OR (lv_retcode = gv_status_warn)) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_047);
      END IF;
      IF ( gn_no_msg_disp = 0 ) THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      END IF;
    END IF;
--
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    IF (gn_error_cnt > 0) THEN
      gn_normal_cnt := 0;
-- 2008/11/07 Y.Kawano Del Start
----add start 1.5
--      gn_error_cnt := gn_target_cnt;
----add end 1.5
-- 2008/11/07 Y.Kawano Del End
    ELSE
      gn_normal_cnt := gn_target_cnt;
--add start 1.5
      gn_error_cnt := 0;
--add end 1.5
    END IF;
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_007, gv_tkn_cnt,
                                           TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_008, gv_tkn_cnt,
                                           TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_009, gv_tkn_cnt,
                                           TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn, gv_msg_10a_010, gv_tkn_cnt,
                                           TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language              = userenv('LANG')
      AND    flv.view_application_id = 0
      AND    flv.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flv.lookup_type,
                                                                        flv.view_application_id)
      AND    flv.lookup_type         = 'CP_STATUS_CODE'
      AND    flv.lookup_code         = DECODE(lv_retcode,
                                              gv_status_normal,gv_sts_cd_normal,
                                              gv_status_warn,gv_sts_cd_warn,
                                              gv_sts_cd_error)
      AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_cmn,
                                           gv_msg_10a_011,
                                           gv_tkn_status,
                                           gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
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
      FND_FILE.PUT_LINE(FND_FILE.LOG,errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,errbuf);
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXINV100001C;
/
