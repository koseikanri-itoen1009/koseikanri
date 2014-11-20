CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO011A01C(body)
 * Description      : �����˗�����̗v���ɏ]���āA�������e���ƂɊ����\���`�F�b�N���s���A
 *                    ���̌��ʂ𔭒��˗��ɕԂ��܂��B
 * MD.050           : MD050_CSO_011_A01_��ƈ˗��i�����˗��j���̃C���X�g�[���x�[�X�`�F�b�N�@�\
 *
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      ��������(A-1)
 *  get_requisition_info      �����˗���񒊏o(A-2)
 *  input_check               ���̓`�F�b�N����(A-3)
 *  check_ib_existence        �����}�X�^���݃`�F�b�N����(A-4)
 *  check_ib_info             �ݒu�p�������`�F�b�N����(A-5)
 *  check_withdraw_ib_info    ���g�p�������`�F�b�N����(A-6)
 *  check_ablsh_appl_ib_info  �p���\���p�������`�F�b�N����(A-7)
 *  check_ablsh_aprv_ib_info  �p�����ٗp�������`�F�b�N����(A-8)
 *  check_mvmt_in_shp_ib_info �X���ړ��p�������`�F�b�N����(A-9)
 *  check_object_status       ���[�X�����X�e�[�^�X�`�F�b�N����(A-10)
 *  check_syozoku_mst         �����}�X�^���݃`�F�b�N����(A-11)
 *  check_cust_mst            �ڋq�}�X�^���݃`�F�b�N����(A-12)
 *  lock_ib_info              �������b�N����(A-13)
 *  update_ib_info            �ݒu�p�����X�V����(A-14)
 *  update_withdraw_ib_info   ���g�p�����X�V����(A-15)
 *  update_abo_appl_ib_info   �p���\���p�����X�V����(A-16)
 *  update_abo_aprv_ib_info   �p�����ٗp�����X�V����(A-17)
 *  chk_wk_req_proc           ��ƈ˗��^�������A�g�Ώۃe�[�u�����݃`�F�b�N����(A-18)
 *  insert_wk_req_proc        ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����(A-19)
 *  update_wk_req_proc        ��ƈ˗��^�������A�g�Ώۃe�[�u���X�V����(A-20)
 *  start_approval_wf_proc    ���F���[�N�t���[�N��(�G���[�ʒm)(A-21)
 *  submain                   ���C�������v���V�[�W��
 *  main_for_application      ���C�������i�����˗��\���p�j
 *  main_for_approval         ���C�������i�����˗����F�p�j
 *  main_for_denegation       ���C�������i�����˗��۔F�p�j
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   N.Yabuki         �V�K�쐬
 *  2009-03-05    1.1   N.Yabuki         ������Q�Ή�(�s�ID.46)
 *                                       �E�J�e�S���敪��NULL(�c��TM�ȊO)�̏ꍇ�A�㑱�������X�L�b�v���鏈����ǉ�
 *  2009-04-02    1.2   N.Yabuki         �yST��Q�Ή�177�z�ڋq�X�e�[�^�X�`�F�b�N�Ɂu25�FSP���F�ρv��ǉ�
 *  2009-04-03    1.3   N.Yabuki         �yST��Q�Ή�297�z�o��w���i�i�J�e�S���敪��NULL�j�𒊏o�ΏۊO�ɏC��
 *  2009-04-06    1.4   N.Yabuki         �yST��Q�Ή�101�z��ƈ˗��^�������A�g�Ώۃe�[�u���̑��݃`�F�b�N�A�X�V�����ǉ�
 *  2009-04-10    1.5   D.Abe            �yST��Q�Ή�108�z�G���[�ʒm�̋N��������ǉ��B
 *  2009-04-13    1.6   N.Yabuki         �yST��Q�Ή�170�z��Ɗ�]���ƈ˗����̃`�F�b�N�ǉ�
 *                                       �yST��Q�Ή�171�z�ݒu�ꏊ�敪���u1:���O�v�̏ꍇ�A�ݒu�ꏊ�K���s�v�̃`�F�b�N�ǉ�
 *                                       �yST��Q�Ή�198�z���[�X���̃`�F�b�N�����[�X�敪���u1:���Ѓ��[�X�v���݂̂ɏC��
 *                                       �yST��Q�Ή�527�z���g���̐ݒu��Ɖ�ЁA���Ə��̃`�F�b�N���폜
 *  2009-04-16    1.7   N.Yabuki         �yST��Q�Ή�398�z�۔F����IB�̍�ƈ˗����t���O��OFF�ɂ��鏈����ǉ�
 *                                       �yST��Q�Ή�549�z�p���\�����̋@���ԂR�A�p���t���O�X�V�����̃^�C�~���O�ύX
 *  2009-04-27    1.8   N.Yabuki         �yST��Q�Ή�505�z���g�����A�X���ړ������Ɛݒu��_�ڋq�R�[�h�̕R�t���`�F�b�N��ǉ�
 *                                       �yST��Q�Ή�517�z�ڋq�}�X�^���݃`�F�b�N�������C��
 *  2009-05-01    1.9   Tomoko.Mori      T1_0897�Ή�
 *****************************************************************************************/
  --
  --#######################  �Œ�O���[�o���萔�錾�� START   #######################
  --
  -- �X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- ����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- �x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- �ُ�:2
  --
  -- WHO�J����
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;          -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                     -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;          -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                     -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id;  -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                     -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
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
  gn_target_cnt    NUMBER; -- �Ώی���
  gn_normal_cnt    NUMBER; -- ���팏��
  gn_error_cnt     NUMBER; -- �G���[����
  gn_warn_cnt      NUMBER; -- �X�L�b�v����
  --
  --################################  �Œ蕔 END   ##################################
  --
  --##########################  �Œ苤�ʗ�O�錾�� START  ###########################
  --
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  --
  --################################  �Œ蕔 END   ##################################
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                  CONSTANT VARCHAR2(100) := 'XXCSO011A01C';  -- �p�b�P�[�W��
  cv_sales_appl_short_name     CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �c�Ɨp�A�v���P�[�V�����Z�k��
  cv_com_appl_short_name       CONSTANT VARCHAR2(5)   := 'XXCCP';         -- ���ʗp�A�v���P�[�V�����Z�k��
  --
  -- ��������
  cv_result_yes    CONSTANT VARCHAR2(1) := 'Y';
  cv_result_no     CONSTANT VARCHAR2(1) := 'N';
  --
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00469';  -- �p�����[�^�K�{�`�F�b�N�G���[
  cv_tkn_number_02  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00524';  -- ���[�N�t���[���擾�G���[
  cv_tkn_number_03  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_tkn_number_04  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00342';  -- ����^�C�vID�Ȃ��G���[
  cv_tkn_number_05  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00343';  -- ����^�C�vID���o�G���[
  cv_tkn_number_06  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- �ǉ�����ID���o�G���[
  cv_tkn_number_07  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00517';  -- �����Ώۃf�[�^�Ȃ��G���[
  cv_tkn_number_08  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00344';  -- �����˗����Ȃ��G���[
  cv_tkn_number_09  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00345';  -- �K�{���̓`�F�b�N�G���[
  cv_tkn_number_10  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00346';  -- ���̓`�F�b�N�G���[
  cv_tkn_number_11  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00347';  -- ��Ɗ�]���ԕK�{���̓`�F�b�N�G���[
  cv_tkn_number_12  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00348';  -- �ݒu�ꏊ�K���K�{���̓`�F�b�N�G���[
  cv_tkn_number_13  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00349';  -- �G���x�[�^�Ԍ��A���s���K�{���̓`�F�b�N�G���[
  cv_tkn_number_14  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00350';  -- �����R�[�h(m)���̓`�F�b�N�G���[
  cv_tkn_number_15  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00351';  -- �����}�X�^���݃`�F�b�N�G���[
  cv_tkn_number_16  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00352';  -- �����}�X�^���o�G���[
  cv_tkn_number_17  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00476';  -- ��ƈ˗����t���O_�ݒu�p�`�F�b�N�G���[
  cv_tkn_number_18  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00354';  -- �@���ԂP�i�ғ���ԁj_�ݒu�p�`�F�b�N�G���[
  cv_tkn_number_19  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00355';  -- �@���ԂR�i�p�����j_�ݒu�p�`�F�b�N�G���[
  cv_tkn_number_20  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00477';  -- ��ƈ˗����t���O_���g�p�`�F�b�N�G���[
  cv_tkn_number_21  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00357';  -- �@���ԂP�i�ғ���ԁj_���g�p�`�F�b�N�G���[
  cv_tkn_number_22  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00478';  -- ��ƈ˗����t���O_�p���p�`�F�b�N�G���[
  cv_tkn_number_23  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00359';  -- �@���ԂP�i�ғ���ԁj_�p���p�`�F�b�N�G���[
  cv_tkn_number_24  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00360';  -- �@���ԂR�i�p�����j_�p���\���p�`�F�b�N�G���[
  cv_tkn_number_25  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00361';  -- �@���ԂR�i�p�����j_�p�����ٗp�`�F�b�N�G���[
  cv_tkn_number_26  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00362';  -- ���[�X�����Ȃ��G���[
  cv_tkn_number_27  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00363';  -- ���[�X�����X�e�[�^�X�`�F�b�N�i�ݒu�p�j�G���[
  cv_tkn_number_28  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00364';  -- ���[�X�������o�G���[
  cv_tkn_number_29  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00365';  -- ���[�X�����X�e�[�^�X�`�F�b�N�i�p���p�j�G���[
  cv_tkn_number_30  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00366';  -- �����}�X�^���݃`�F�b�N�G���[
  cv_tkn_number_31  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00367';  -- �����}�X�^���o�G���[
  cv_tkn_number_32  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00368';  -- �ڋq�}�X�^���݃`�F�b�N�G���[
  cv_tkn_number_33  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00369';  -- �ڋq�}�X�^���o�G���[
  cv_tkn_number_34  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00370';  -- �ڋq�X�e�[�^�X�`�F�b�N�G���[
  cv_tkn_number_35  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00371';  -- �ݒu�p������񃍃b�N�G���[
  cv_tkn_number_36  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00372';  -- �ݒu�p������񒊏o�G���[
  cv_tkn_number_37  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00373';  -- �ݒu�p�������X�V�G���[
  cv_tkn_number_38  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00374';  -- ���g�p������񃍃b�N�G���[
  cv_tkn_number_39  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00375';  -- ���g�p������񒊏o�G���[
  cv_tkn_number_40  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00376';  -- ���g�p�������X�V�G���[
  cv_tkn_number_41  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00377';  -- �p���p������񃍃b�N�G���[
  cv_tkn_number_42  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00378';  -- �p���p������񒊏o�G���[
  cv_tkn_number_43  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00379';  -- �ǉ������lID���o�G���[
  cv_tkn_number_44  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00380';  -- �p���p�������X�V�G���[
  cv_tkn_number_45  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00516';  -- ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^�G���[
/*20090413_yabuki_ST170 START*/
  cv_tkn_number_46  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00561';  -- ��Ɗ�]�����̓`�F�b�N�G���[���b�Z�[�W
/*20090413_yabuki_ST170 END*/
/*20090413_yabuki_ST171 START*/
  cv_tkn_number_47  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00562';  -- �ݒu�ꏊ�K�����̓`�F�b�N�G���[���b�Z�[�W
/*20090413_yabuki_ST171 END*/
/*20090416_yabuki_ST549 START*/
  cv_tkn_number_48  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00563';  -- �X�e�[�^�XID�擾�G���[
  cv_tkn_number_49  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00564';  -- �X�e�[�^�XID���o�G���[
/*20090416_yabuki_ST549 END*/
/*20090427_yabuki_ST505_517 START*/
  cv_tkn_number_50  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00566';  -- �ݒu�����E�ڋq�֘A���`�F�b�N�G���[
  cv_tkn_number_51  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00567';  -- ���g�����E�ڋq�֘A���`�F�b�N�G���[
/*20090427_yabuki_ST505_517 END*/
  --
  -- �g�[�N���R�[�h
  cv_tkn_param_nm       CONSTANT VARCHAR2(20) := 'PARAM_NAME';
  cv_tkn_item           CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_value          CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_task_nm        CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_src_tran_type  CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';
  cv_tkn_err_msg        CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_add_attr_nm    CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_add_attr_cd    CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_bukken         CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_status1        CONSTANT VARCHAR2(20) := 'STATUS1';
  cv_tkn_status3        CONSTANT VARCHAR2(20) := 'STATUS3';
  cv_tkn_wk_company_cd  CONSTANT VARCHAR2(20) := 'WORK_COMPANY_CODE';
  cv_tkn_location_cd    CONSTANT VARCHAR2(20) := 'LOCATION_CODE';
  cv_tkn_kokyaku        CONSTANT VARCHAR2(20) := 'KOKYAKU';
  cv_tkn_cust_status    CONSTANT VARCHAR2(20) := 'CUST_STATUS';
  cv_tkn_api_err_msg    CONSTANT VARCHAR2(20) := 'API_ERR_MSG';
  cv_tkn_req_num        CONSTANT VARCHAR2(20) := 'REQUISITION_NUM';
  cv_tkn_req_line_num   CONSTANT VARCHAR2(20) := 'REQUISITION_LINE_NUM';
/*20090406_yabuki_ST297 START*/
  cv_tkn_req_header_num CONSTANT VARCHAR2(20) := 'REQ_HEADER_NUM';
/*20090406_yabuki_ST297 END*/
/*20090406_yabuki_ST101 START*/
  cv_tkn_process        CONSTANT VARCHAR2(20) := 'PROCESS';
/*20090406_yabuki_ST101 END*/
/*20090413_yabuki_ST170 START*/
  cv_tkn_req_date       CONSTANT VARCHAR2(20) := 'REQUEST_DATE';
/*20090413_yabuki_ST170 END*/
  --
/*20090416_yabuki_ST549 START*/
  -- �Q�ƃ^�C�v��IB�X�e�[�^�X�^�C�v�R�[�h
  cv_xxcso1_instance_status CONSTANT VARCHAR2(30)  := 'XXCSO1_INSTANCE_STATUS';
/*20090416_yabuki_ST549 END*/
  --
  -- �����G���[���b�Z�[�W�̋�؂蕶���i�J���}�j
  cv_msg_comma CONSTANT VARCHAR2(3) := ' , ';
  --
  -- ��؂蕶��
  cv_msg_part_only  CONSTANT VARCHAR2(1) := ':';
  --
  -- �����敪
  cv_proc_kbn_req_appl  CONSTANT VARCHAR2(1) := '1';  -- �����˗��\��
  cv_proc_kbn_req_aprv  CONSTANT VARCHAR2(1) := '2';  -- �����˗����F
/*20090416_yabuki_ST398 START*/
  cv_proc_kbn_req_dngtn CONSTANT VARCHAR2(1) := '3';  -- �����˗��۔F
/*20090416_yabuki_ST398 END*/
  --
  -- �J�e�S���敪
  cv_category_kbn_new_install  CONSTANT VARCHAR2(5) := '10';  -- �V��ݒu
  cv_category_kbn_new_replace  CONSTANT VARCHAR2(5) := '20';  -- �V����
  cv_category_kbn_old_install  CONSTANT VARCHAR2(5) := '30';  -- ����ݒu
  cv_category_kbn_old_replace  CONSTANT VARCHAR2(5) := '40';  -- ������
  cv_category_kbn_withdraw     CONSTANT VARCHAR2(5) := '50';  -- ���g
  cv_category_kbn_ablsh_appl   CONSTANT VARCHAR2(5) := '60';  -- �p���\��
  cv_category_kbn_ablsh_dcsn   CONSTANT VARCHAR2(5) := '70';  -- �p������
  cv_category_kbn_mvmt_in_shp  CONSTANT VARCHAR2(5) := '80';  -- �X���ړ�
  --
  -- �ǉ������R�[�h
  cv_attr_cd_jotai_kbn3      CONSTANT VARCHAR2(30) := 'JOTAI_KBN3';      -- �@���ԂR�i�p�����j
  cv_attr_cd_haikikessai_dt  CONSTANT VARCHAR2(30) := 'HAIKIKESSAI_DT';  -- �p�����ٓ�
  cv_attr_cd_ven_haiki_flg   CONSTANT VARCHAR2(30) := 'VEN_HAIKI_FLG';   -- �p���t���O
  -- �ǉ�������
  cv_attr_nm_jotai_kbn3      CONSTANT VARCHAR2(30) := '�@���ԂR�i�p�����j';
  cv_attr_nm_haikikessai_dt  CONSTANT VARCHAR2(30) := '�p�����ٓ�';
  cv_attr_nm_ven_haiki_flg   CONSTANT VARCHAR2(30) := '�p���t���O';
  --
  -- ���̓`�F�b�N�������̃`�F�b�N�敪�ԍ�
  cv_input_chk_kbn_01  CONSTANT VARCHAR2(2) := '01';  -- �@��R�[�h�K�{���̓`�F�b�N
  cv_input_chk_kbn_02  CONSTANT VARCHAR2(2) := '02';  -- �ݒu�p�����R�[�h�K�{���̓`�F�b�N
  cv_input_chk_kbn_03  CONSTANT VARCHAR2(2) := '03';  -- �ݒu�p�����R�[�h���̓`�F�b�N
  cv_input_chk_kbn_04  CONSTANT VARCHAR2(2) := '04';  -- ���g�p�����R�[�h���̓`�F�b�N
  cv_input_chk_kbn_05  CONSTANT VARCHAR2(2) := '05';  -- ���g�p�����R�[�h�K�{���̓`�F�b�N
  cv_input_chk_kbn_06  CONSTANT VARCHAR2(2) := '06';  -- �ݒu��_�ڋq�R�[�h�K�{���̓`�F�b�N
  cv_input_chk_kbn_07  CONSTANT VARCHAR2(2) := '07';  -- ��Ɗ֘A�����̓`�F�b�N
  cv_input_chk_kbn_08  CONSTANT VARCHAR2(2) := '08';  -- ���g�֘A�����̓`�F�b�N
  cv_input_chk_kbn_09  CONSTANT VARCHAR2(2) := '09';  -- �p��_�����R�[�h�K�{���̓`�F�b�N
/*20090413_yabuki_ST170_ST171 START*/
  cv_input_chk_kbn_10  CONSTANT VARCHAR2(2) := '10';  -- ���g�֘A�����̓`�F�b�N�Q
/*20090413_yabuki_ST170_ST171 END*/
  --
  -- ���[�X�����X�e�[�^�X�`�F�b�N�������̃`�F�b�N�敪�ԍ�
  cv_obj_sts_chk_kbn_01  CONSTANT VARCHAR2(2) := '01';  -- �`�F�b�N�ΏہF�ݒu�p����
  cv_obj_sts_chk_kbn_02  CONSTANT VARCHAR2(2) := '02';  -- �`�F�b�N�ΏہF�p���p����
  --
  -- �����֘A�̍��ڂ̌Œ�l
  cv_op_req_flag_on         CONSTANT VARCHAR2(1) := 'Y';  -- ��ƈ˗����t���O�u�n�m�v
/*20090416_yabuki_ST398 START*/
  cv_op_req_flag_off        CONSTANT VARCHAR2(1) := 'N';  -- ��ƈ˗����t���O�u�n�e�e�v
/*20090416_yabuki_ST398 END*/
  cv_jotai_kbn1_operate     CONSTANT VARCHAR2(1) := '1';  -- �@���ԂP�i�ғ���ԁj�u�ғ��v
  cv_jotai_kbn1_hold        CONSTANT VARCHAR2(1) := '2';  -- �@���ԂP�i�ғ���ԁj�u�ؗ��v
  cv_jotai_kbn3_non_schdl   CONSTANT VARCHAR2(1) := '0';  -- �@���ԂR�i�p�����j�u�\�薳�v
  cv_jotai_kbn3_ablsh_appl  CONSTANT VARCHAR2(1) := '2';  -- �@���ԂR�i�p�����j�u�p���\�����v
/*20090403_yabuki_ST297 START*/
  -- �Œ�̐��l
  cn_zero    CONSTANT NUMBER := 0;
  cn_one     CONSTANT NUMBER := 1;
/*20090403_yabuki_ST297 END*/
/*20090406_yabuki_ST101 START*/
  cv_interface_flg_off      CONSTANT VARCHAR2(1) := 'N';  -- �A�g�σt���O�u�n�e�e�v
/*20090406_yabuki_ST101 END*/
/*20090413_yabuki_ST198 START*/
  cv_own_company_lease      CONSTANT VARCHAR2(1) := '1';  -- ���[�X�敪�u���Ѓ��[�X�v
/*20090413_yabuki_ST198 END*/
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
/*20090413_yabuki_ST549 START*/
  gt_instance_status_id_1 csi_instance_statuses.instance_status_id%TYPE; -- �ғ���
  gt_instance_status_id_2 csi_instance_statuses.instance_status_id%TYPE; -- �g�p��
  gt_instance_status_id_3 csi_instance_statuses.instance_status_id%TYPE; -- ������
  gt_instance_status_id_4 csi_instance_statuses.instance_status_id%TYPE; -- �p���葱��
  gt_instance_status_id_5 csi_instance_statuses.instance_status_id%TYPE; -- �p��������
  gt_instance_status_id_6 csi_instance_statuses.instance_status_id%TYPE; -- �����폜��
/*20090413_yabuki_ST549 END*/
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- IB�ǉ�����ID
  TYPE g_ib_ext_attr_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- �@����3
    , abolishment_decision_date  NUMBER  -- �p�����ٓ�
    , abolishment_flag           NUMBER  -- �p���t���O
  );
  --
  -- IB�ǉ������lID
  TYPE g_ib_ext_attr_val_id_rtype IS RECORD(
      jotai_kbn3                 NUMBER  -- �@����3
    , abolishment_decision_date  NUMBER  -- �p�����ٓ�
    , abolishment_flag           NUMBER  -- �p���t���O
  );
  --
  -- �����˗����
  TYPE g_requisition_rtype IS RECORD(
      requisition_header_id     xxcso_requisition_lines_v.requisition_header_id%TYPE     -- �����˗��w�b�_ID
    , requisition_line_id       xxcso_requisition_lines_v.requisition_line_id%TYPE       -- �����˗�����ID
    , requisition_number        po_requisition_headers.segment1%TYPE                     -- �����˗��ԍ�
    , requisition_line_number   xxcso_requisition_lines_v.line_num%TYPE                  -- �����˗����הԍ�
    , category_kbn              xxcso_requisition_lines_v.category_kbn%TYPE              -- �J�e�S���敪
    , un_number                 po_un_numbers_vl.un_number%TYPE                          -- �@��R�[�h
    , install_code              xxcso_requisition_lines_v.install_code%TYPE              -- �ݒu�p�����R�[�h
    , withdraw_install_code     xxcso_requisition_lines_v.withdraw_install_code%TYPE     -- ���g�p�����R�[�h
    , install_at_customer_code  xxcso_requisition_lines_v.install_at_customer_code%TYPE  -- �ݒu��_�ڋq�R�[�h
    , work_hope_time_type       xxcso_requisition_lines_v.work_hope_time_type%TYPE       -- ��Ɗ�]���ԋ敪
    , work_hope_time_hour       xxcso_requisition_lines_v.work_hope_time_hour%TYPE       -- ��Ɗ�]��
    , work_hope_time_minute     xxcso_requisition_lines_v.work_hope_time_minute%TYPE     -- ��Ɗ�]��
    , install_place_type        xxcso_requisition_lines_v.install_place_type%TYPE        -- �ݒu�ꏊ�敪
    , install_place_floor       xxcso_requisition_lines_v.install_place_floor%TYPE       -- �ݒu�ꏊ�K��
    , elevator_frontage         xxcso_requisition_lines_v.elevator_frontage%TYPE         -- �G���x�[�^�Ԍ�
    , elevator_depth            xxcso_requisition_lines_v.elevator_depth%TYPE            -- �G���x�[�^���s��
    , extension_code_type       xxcso_requisition_lines_v.extension_code_type%TYPE       -- �����R�[�h�敪
    , extension_code_meter      xxcso_requisition_lines_v.extension_code_meter%TYPE      -- �����R�[�h�i���j
    , abolishment_install_code  xxcso_requisition_lines_v.abolishment_install_code%TYPE  -- �p��_�����R�[�h
    , work_company_code         xxcso_requisition_lines_v.work_company_code%TYPE         -- ��Ɖ�ЃR�[�h
    , work_location_code        xxcso_requisition_lines_v.work_location_code%TYPE        -- ���Ə��R�[�h
    , withdraw_company_code     xxcso_requisition_lines_v.withdraw_company_code%TYPE     -- ���g��ЃR�[�h
    , withdraw_location_code    xxcso_requisition_lines_v.withdraw_location_code%TYPE    -- ���g���Ə��R�[�h
/*20090413_yabuki_ST170 START*/
    , work_hope_year            xxcso_requisition_lines_v.work_hope_year%TYPE            -- ��Ɗ�]�N
    , work_hope_month           xxcso_requisition_lines_v.work_hope_month%TYPE           -- ��Ɗ�]��
    , work_hope_day             xxcso_requisition_lines_v.work_hope_day%TYPE             -- ��Ɗ�]��
    , request_date              xxcso_requisition_lines_v.creation_date%TYPE             -- �˗���
/*20090413_yabuki_ST170 END*/
/*20090427_yabuki_ST505_517 START*/
    , created_by                po_requisition_headers.created_by%TYPE                   -- �쐬��
/*20090427_yabuki_ST505_517 END*/
  );
  --
  -- �������
  TYPE g_instance_rtype IS RECORD(
      instance_id  xxcso_install_base_v.instance_id%TYPE            -- �C���X�^���XID
    , op_req_flag  xxcso_install_base_v.op_request_flag%TYPE        -- ��ƈ˗����t���O
    , jotai_kbn1   xxcso_install_base_v.jotai_kbn1%TYPE             -- �@���ԂP�i�ғ���ԁj
    , jotai_kbn3   xxcso_install_base_v.jotai_kbn3%TYPE             -- �@���ԂR�i�p�����j
    , obj_ver_num  xxcso_install_base_v.object_version_number%TYPE  -- �I�u�W�F�N�g�o�[�W�����ԍ�
/*20090413_yabuki_ST198 START*/
    , lease_kbn    xxcso_install_base_v.lease_kbn%TYPE              -- ���[�X�敪
/*20090413_yabuki_ST198 END*/
/*20090427_yabuki_ST505_517 START*/
    , owner_account_id  xxcso_install_base_v.install_account_id%TYPE  -- �ݒu��A�J�E���gID
/*20090427_yabuki_ST505_517 END*/
  );
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o����O
  -- ===============================
  g_lock_expt         EXCEPTION;  -- ���b�N��O
  --
  PRAGMA EXCEPTION_INIT( g_lock_expt, -54 );
  --
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_itemtype             IN         VARCHAR2
    , iv_itemkey              IN         VARCHAR2
    , iv_process_kbn          IN         VARCHAR2                                -- �����敪
    , ov_requisition_number   OUT NOCOPY po_requisition_headers.segment1%TYPE    -- �����˗��ԍ�
    , od_process_date         OUT NOCOPY DATE                                    -- �Ɩ��������t
    , on_transaction_type_id  OUT NOCOPY csi_txn_types.transaction_type_id%TYPE  -- ����^�C�vID
    , o_ib_ext_attr_id_rec    OUT NOCOPY g_ib_ext_attr_id_rtype                  -- IB�ǉ�����ID���
    , ov_errbuf               OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode              OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- �v���V�[�W����
    --
    --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
    --
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_itemtype    CONSTANT VARCHAR2(30) := 'ITEMTYPE';
    cv_itemkey     CONSTANT VARCHAR2(30) := 'ITEMKEY';
    cv_doc_number  CONSTANT VARCHAR2(30) := 'DOCUMENT_NUMBER';
    cv_ib_ui       CONSTANT VARCHAR2(30) := 'IB_UI';
    --
    -- �g�[�N���p
    cv_tkn_val_req_number     CONSTANT VARCHAR2(30)  := '�����˗��ԍ�';
    cv_tkn_val_process_kbn    CONSTANT VARCHAR2(30)  := '�����敪';
    cv_tkn_val_tran_type_id   CONSTANT VARCHAR2(30)  := '����^�C�v�̎���^�C�v�h�c';
    cv_tkn_val_ext_attr_id    CONSTANT VARCHAR2(30)  := '�ǉ������h�c';
/*20090416_yabuki_ST549 START*/
    cv_tkn_val_status_nm      CONSTANT VARCHAR2(30)  := '�X�e�[�^�X��';
/*20090416_yabuki_ST549 END*/
    --
/*20090416_yabuki_ST549 START*/
    -- �Q�ƃ^�C�v��IB�X�e�[�^�X�R�[�h
    cv_instance_status_1      CONSTANT VARCHAR2(1)   := '1';    -- �ғ���
    cv_instance_status_2      CONSTANT VARCHAR2(1)   := '2';    -- �g�p��
    cv_instance_status_3      CONSTANT VARCHAR2(1)   := '3';    -- ������
    cv_instance_status_4      CONSTANT VARCHAR2(1)   := '4';    -- �p���葱��
    cv_instance_status_5      CONSTANT VARCHAR2(1)   := '5';    -- �p��������
    cv_instance_status_6      CONSTANT VARCHAR2(1)   := '6';    -- �����폜��
    --
    -- �C���X�^���X�X�e�[�^�X��
    cv_status_name01          CONSTANT VARCHAR2(100) := '�ғ���';
    cv_status_name02          CONSTANT VARCHAR2(100) := '�g�p��';
    cv_status_name03          CONSTANT VARCHAR2(100) := '������';
    cv_status_name04          CONSTANT VARCHAR2(100) := '�p���葱��';
    cv_status_name05          CONSTANT VARCHAR2(100) := '�p��������';
    cv_status_name06          CONSTANT VARCHAR2(100) := '�����폜��';
    --
    -- ���o���e��
    cv_instance_status        CONSTANT VARCHAR2(100) := '�����̃X�e�[�^�XID';
/*20090416_yabuki_ST549 END*/
    --
    -- *** ���[�J���ϐ� ***
/*20090416_yabuki_ST549 START*/
    lt_status_name    csi_instance_statuses.name%TYPE;
/*20090416_yabuki_ST549 END*/
    --
    -- *** ���[�J����O ***
    input_parameter_expt  EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ======================
    -- ���̓p�����[�^�`�F�b�N
    -- ======================
    -- ���[�N�t���[��ITEMTYPE
    IF ( iv_itemtype IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_01          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_param_nm           -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_itemtype               -- �g�[�N���l1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ���[�N�t���[��ITEMKEY
    IF ( iv_itemkey IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_01          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_param_nm           -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_itemkey                -- �g�[�N���l1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ======================
    -- �����˗��ԍ��擾
    -- ======================
    ov_requisition_number := po_wf_util_pkg.getitemattrtext(
                                 itemtype => iv_itemtype
                               , itemkey  => iv_itemkey
                               , aname    => cv_doc_number
                             );
    --
    -- �����˗��ԍ����擾�ł��Ȃ������ꍇ�G���[
    IF ( ov_requisition_number IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_02          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_param_nm           -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_tkn_val_req_number     -- �g�[�N���l1
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- ======================
    -- �Ɩ��������t�擾
    -- ======================
    od_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( od_process_date IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_03          -- ���b�Z�[�W�R�[�h
                   );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    -- ======================
    -- ����^�C�vID���o
    -- ======================
    BEGIN
      SELECT transaction_type_id
      INTO   on_transaction_type_id
      FROM   csi_txn_types
      WHERE  source_transaction_type = cv_ib_ui
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_04           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_task_nm             -- �g�[�N�R�[�h1
                       , iv_token_value1 => cv_tkn_val_tran_type_id    -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_src_tran_type       -- �g�[�N�R�[�h2
                       , iv_token_value2 => cv_ib_ui                   -- �g�[�N���l2
                     );
        --
        RAISE input_parameter_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_05           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_task_nm             -- �g�[�N�R�[�h1
                       , iv_token_value1 => cv_tkn_val_tran_type_id    -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_src_tran_type       -- �g�[�N�R�[�h2
                       , iv_token_value2 => cv_ib_ui                   -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg             -- �g�[�N�R�[�h3
                       , iv_token_value3 => SQLERRM                    -- �g�[�N���l3
                     );
        --
        RAISE input_parameter_expt;
        --
    END;
    --
    -- ======================
    -- IB�ǉ�����ID�擾
    -- ======================
    -- �@���ԂR�i�p�����j
    o_ib_ext_attr_id_rec.jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           iv_attribute_code => cv_attr_cd_jotai_kbn3
                                         , id_standard_date  => od_process_date
                                       );
    --
    -- �@���ԂR�i�p�����j�̒ǉ�����ID���擾�ł��Ȃ������ꍇ�G���[
    IF ( o_ib_ext_attr_id_rec.jotai_kbn3 IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_06          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_task_nm            -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_tkn_val_ext_attr_id    -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_add_attr_nm        -- �g�[�N�R�[�h2
                     , iv_token_value2 => cv_attr_nm_jotai_kbn3     -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_add_attr_cd        -- �g�[�N�R�[�h3
                     , iv_token_value3 => cv_attr_cd_jotai_kbn3     -- �g�[�N���l3
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- �p�����ٓ�
    o_ib_ext_attr_id_rec.abolishment_decision_date := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                          iv_attribute_code => cv_attr_cd_haikikessai_dt
                                                        , id_standard_date  => od_process_date
                                                      );
    --
    -- �p�����ٓ��̒ǉ�����ID���擾�ł��Ȃ������ꍇ�G���[
    IF ( o_ib_ext_attr_id_rec.abolishment_decision_date IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_06           -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_task_nm             -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_tkn_val_ext_attr_id     -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_add_attr_nm         -- �g�[�N�R�[�h2
                     , iv_token_value2 => cv_attr_nm_haikikessai_dt  -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_add_attr_cd         -- �g�[�N�R�[�h3
                     , iv_token_value3 => cv_attr_cd_haikikessai_dt  -- �g�[�N���l3
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
    -- �p���t���O
    o_ib_ext_attr_id_rec.abolishment_flag := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                                 iv_attribute_code => cv_attr_cd_ven_haiki_flg
                                               , id_standard_date  => od_process_date
                                             );
    --
    -- �p���t���O�̒ǉ�����ID���擾�ł��Ȃ������ꍇ�G���[
    IF ( o_ib_ext_attr_id_rec.abolishment_flag IS NULL ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_06          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_task_nm            -- �g�[�N�R�[�h1
                     , iv_token_value1 => cv_tkn_val_ext_attr_id    -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_add_attr_nm        -- �g�[�N�R�[�h2
                     , iv_token_value2 => cv_attr_nm_ven_haiki_flg  -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_add_attr_cd        -- �g�[�N�R�[�h3
                     , iv_token_value3 => cv_attr_cd_ven_haiki_flg  -- �g�[�N���l3
                   );
      --
      RAISE input_parameter_expt;
      --
    END IF;
    --
/*20090416_yabuki_ST549 START*/
    -- ======================
    -- �C���X�^���X�X�e�[�^�XID�擾
    -- ======================
    -- ������
    lt_status_name := NULL;
    --
    -- �u�p���葱���v
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                            cv_xxcso1_instance_status
                          , cv_instance_status_4
                          , od_process_date
                        );
      SELECT cis.instance_status_id       -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_4
      FROM   csi_instance_statuses cis    -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lt_status_name
      AND    od_process_date
               BETWEEN TRUNC( NVL( cis.start_date_active, od_process_date ) )
               AND     TRUNC( NVL( cis.end_date_active, od_process_date ) )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_48          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_instance_status        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_status_name04          -- �g�[�N���l3
                     );
        RAISE input_parameter_expt;
        -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_49          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_instance_status        -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_tkn_val_status_nm      -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                       ,iv_token_value3 => cv_status_name04          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                   -- �g�[�N���l4
                     );
        RAISE input_parameter_expt;
    END;
    --
/*20090416_yabuki_ST549 END*/
    --
  EXCEPTION
    --
    WHEN input_parameter_expt THEN
      -- *** ���̓p�����[�^�`�F�b�N�G���[�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** ���ʊ֐���O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END init;
  --
  --
  /**********************************************************************************
   * Procedure Name   : get_requisition_info
   * Description      : �����˗���񒊏o(A-2)
   ***********************************************************************************/
  PROCEDURE get_requisition_info(
      iv_requisition_number  IN         po_requisition_headers.segment1%TYPE  -- �����˗��ԍ�
    , id_process_date        IN         DATE                                  -- �Ɩ��������t
/*20090403_yabuki_ST297 START*/
    , on_rec_count           OUT NOCOPY NUMBER               -- ���o����
/*20090403_yabuki_ST297 END*/
    , o_requisition_rec      OUT NOCOPY g_requisition_rtype  -- �����˗����
    , ov_errbuf              OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode             OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_requisition_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_val_requisition  CONSTANT VARCHAR2(100) := '�����˗�';
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    sql_expt  EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
/*20090403_yabuki_ST297 START*/
    -- ����������������
    on_rec_count := cn_zero;
/*20090403_yabuki_ST297 END*/
    --
    -- ============================
    -- �����˗���񒊏o
    -- ============================
    BEGIN
      SELECT xrlv.requisition_header_id     requisition_header_id     -- �����˗��w�b�_ID
           , xrlv.requisition_line_id       requisition_line_id       -- �����˗�����ID
           , prh.segment1                   requisition_number        -- �����˗��ԍ�
           , xrlv.line_num                  requisition_line_number   -- �����˗����הԍ�
           , xrlv.category_kbn              category_kbn              -- �J�e�S���敪
           , ( SELECT punv.un_number
               FROM   po_un_numbers_vl  punv
               WHERE  punv.un_number_id = xrlv.un_number_id
               AND    TRUNC( NVL( punv.inactive_date, id_process_date + 1 ) ) 
                       > TRUNC( id_process_date ) )  un_number    -- �@��R�[�h
           , xrlv.install_code              install_code              -- �ݒu�p�����R�[�h
           , xrlv.withdraw_install_code     withdraw_install_code     -- ���g�p�����R�[�h
           , xrlv.install_at_customer_code  install_at_customer_code  -- �ݒu��_�ڋq�R�[�h
           , xrlv.work_hope_time_type       work_hope_time_type       -- ��Ɗ�]���ԋ敪
           , xrlv.work_hope_time_hour       work_hope_time_hour       -- ��Ɗ�]��
           , xrlv.work_hope_time_minute     work_hope_time_minute     -- ��Ɗ�]��
           , xrlv.install_place_type        install_place_type        -- �ݒu�ꏊ�敪
           , xrlv.install_place_floor       install_place_floor       -- �ݒu�ꏊ�K��
           , xrlv.elevator_frontage         elevator_frontage         -- �G���x�[�^�Ԍ�
           , xrlv.elevator_depth            elevator_depth            -- �G���x�[�^���s��
           , xrlv.extension_code_type       extension_code_type       -- �����R�[�h�敪
           , xrlv.extension_code_meter      extension_code_meter      -- �����R�[�h�i���j
           , xrlv.abolishment_install_code  abolishment_install_code  -- �p��_�����R�[�h
           , xrlv.work_company_code         work_company_code         -- ��Ɖ�ЃR�[�h
           , xrlv.work_location_code        work_location_code        -- ���Ə��R�[�h
           , xrlv.withdraw_company_code     withdraw_company_code     -- ���g��ЃR�[�h
           , xrlv.withdraw_location_code    withdraw_location_code    -- ���g���Ə��R�[�h
           /*20090413_yabuki_ST170 START*/
           , xrlv.work_hope_year            work_hope_year            -- ��Ɗ�]�N
           , xrlv.work_hope_month           work_hope_month           -- ��Ɗ�]��
           , xrlv.work_hope_day             work_hope_day             -- ��Ɗ�]��
           , xrlv.creation_date             request_date              -- �˗����i�쐬���j
           /*20090413_yabuki_ST170 END*/
           /*20090427_yabuki_ST505_517 START*/
           , prh.created_by                 created_by                -- �쐬��
           /*20090427_yabuki_ST505_517 END*/
      INTO   o_requisition_rec.requisition_header_id     -- �����˗��w�b�_ID
           , o_requisition_rec.requisition_line_id       -- �����˗�����ID
           , o_requisition_rec.requisition_number        -- �����˗��ԍ�
           , o_requisition_rec.requisition_line_number   -- �����˗����הԍ�
           , o_requisition_rec.category_kbn              -- �J�e�S���敪
           , o_requisition_rec.un_number                 -- �@��R�[�h
           , o_requisition_rec.install_code              -- �ݒu�p�����R�[�h
           , o_requisition_rec.withdraw_install_code     -- ���g�p�����R�[�h
           , o_requisition_rec.install_at_customer_code  -- �ݒu��_�ڋq�R�[�h
           , o_requisition_rec.work_hope_time_type       -- ��Ɗ�]���ԋ敪
           , o_requisition_rec.work_hope_time_hour       -- ��Ɗ�]��
           , o_requisition_rec.work_hope_time_minute     -- ��Ɗ�]��
           , o_requisition_rec.install_place_type        -- �ݒu�ꏊ�敪
           , o_requisition_rec.install_place_floor       -- �ݒu�ꏊ�K��
           , o_requisition_rec.elevator_frontage         -- �G���x�[�^�Ԍ�
           , o_requisition_rec.elevator_depth            -- �G���x�[�^���s��
           , o_requisition_rec.extension_code_type       -- �����R�[�h�敪
           , o_requisition_rec.extension_code_meter      -- �����R�[�h�i���j
           , o_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
           , o_requisition_rec.work_company_code         -- ��Ɖ�ЃR�[�h
           , o_requisition_rec.work_location_code        -- ���Ə��R�[�h
           , o_requisition_rec.withdraw_company_code     -- ���g��ЃR�[�h
           , o_requisition_rec.withdraw_location_code    -- ���g���Ə��R�[�h
           /*20090413_yabuki_ST170 START*/
           , o_requisition_rec.work_hope_year            -- ��Ɗ�]�N
           , o_requisition_rec.work_hope_month           -- ��Ɗ�]��
           , o_requisition_rec.work_hope_day             -- ��Ɗ�]��
           , o_requisition_rec.request_date              -- �˗���
           /*20090413_yabuki_ST170 END*/
           /*20090427_yabuki_ST505_517 START*/
           , o_requisition_rec.created_by                -- �쐬��
           /*20090427_yabuki_ST505_517 END*/
      FROM   po_requisition_headers     prh
           , xxcso_requisition_lines_v  xrlv
      WHERE  prh.segment1               = iv_requisition_number
      AND    xrlv.requisition_header_id = prh.requisition_header_id
      /*20090403_yabuki_ST297 START*/
      AND    xrlv.category_kbn IS NOT NULL
      /*20090403_yabuki_ST297 END*/
      ;
      --
/*20090403_yabuki_ST297 START*/
    -- ����������ݒ�
    on_rec_count := cn_one;
/*20090403_yabuki_ST297 END*/
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
/*20090403_yabuki_ST297 START*/
        -- �����������Ȃ��i�����킩��������=0�j
        NULL;
--        lv_errbuf := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
--                       , iv_name         => cv_tkn_number_07          -- ���b�Z�[�W�R�[�h
--                       , iv_token_name1  => cv_tkn_req_num            -- �g�[�N���R�[�h1
--                       , iv_token_value1 => iv_requisition_number     -- �g�[�N���l1
--                    );
--        --
--        RAISE sql_expt;
/*20090403_yabuki_ST297 END*/
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_08          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table              -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_requisition    -- �g�[�N���l1
/*20090403_yabuki_ST297 START*/
                       , iv_token_name2  => cv_tkn_req_header_num     -- �g�[�N���R�[�h2
--                       , iv_token_name2  => cv_tkn_req_num            -- �g�[�N���R�[�h2
/*20090403_yabuki_ST297 END*/
                       , iv_token_value2 => iv_requisition_number     -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg            -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                   -- �g�[�N���l3
                    );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** �f�[�^�擾SQL��O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END get_requisition_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : input_check
   * Description      : ���̓`�F�b�N����(A-3)
   ***********************************************************************************/
  PROCEDURE input_check(
      iv_chk_kbn         IN         VARCHAR2             -- �`�F�b�N�敪
    , i_requisition_rec  IN         g_requisition_rtype  -- �����˗����
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'input_check';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_wk_hp_time_type_asgn      CONSTANT VARCHAR2(1) := '1';  -- ��Ɗ�]���ԋ敪=�u�w��v
    cv_inst_place_type_interior  CONSTANT VARCHAR2(1) := '2';  -- �ݒu�ꏊ�敪=�u�����v
/*20090413_yabuki_ST170 START*/
    cv_date_fmt                  CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
    cv_date_fmt2                 CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
/*20090413_yabuki_ST170 END*/
/*20090413_yabuki_ST171 START*/
    cv_inst_place_type_exterior  CONSTANT VARCHAR2(1) := '1';  -- �ݒu�ꏊ�敪=�u���O�v
/*20090413_yabuki_ST171 END*/
    --
    -- �g�[�N���p�萔
    cv_tkn_val_un_number         CONSTANT VARCHAR2(100) := '�@��R�[�h';
    cv_tkn_val_install_cd        CONSTANT VARCHAR2(100) := '�ݒu�p�����R�[�h';
    cv_tkn_val_wthdrw_inst_cd    CONSTANT VARCHAR2(100) := '���g�p�����R�[�h';
    cv_tkn_val_inst_at_cust_cd   CONSTANT VARCHAR2(100) := '�ݒu��_�ڋq�R�[�h';
    cv_tkn_val_wk_company_cd     CONSTANT VARCHAR2(100) := '��Ɖ�ЃR�[�h';
    cv_tkn_val_wk_location_cd    CONSTANT VARCHAR2(100) := '���Ə��R�[�h';
    cv_tkn_val_wthdrw_cmpny_cd   CONSTANT VARCHAR2(100) := '���g��ЃR�[�h';
    cv_tkn_val_wthdrw_loc_cd     CONSTANT VARCHAR2(100) := '���g���Ə��R�[�h';
    cv_tkn_val_ablsh_inst_cd     CONSTANT VARCHAR2(100) := '�p��_�����R�[�h';
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �`�F�b�N�敪���u�@��R�[�h�K�{���̓`�F�b�N�v�̏ꍇ
    IF ( iv_chk_kbn = cv_input_chk_kbn_01 ) THEN
      -- �@��R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.un_number IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_un_number      -- �g�[�N���l1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u�ݒu�p�����R�[�h�K�{���̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_02 ) THEN
      -- �ݒu�p�����R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.install_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_install_cd     -- �g�[�N���l1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u�ݒu�p�����R�[�h���̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_03 ) THEN
      -- �ݒu�p�����R�[�h�����͂���Ă���ꍇ
      IF ( i_requisition_rec.install_code IS NOT NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_10          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_install_cd     -- �g�[�N���l1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u���g�p�����R�[�h���̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_04 ) THEN
      -- ���g�p�����R�[�h�����͂���Ă���ꍇ
      IF ( i_requisition_rec.withdraw_install_code IS NOT NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_10           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item                -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_wthdrw_inst_cd  -- �g�[�N���l1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u���g�p�����R�[�h�K�{���̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_05 ) THEN
      -- ���g�p�����R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.withdraw_install_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_09           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item                -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_wthdrw_inst_cd  -- �g�[�N���l1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u�ݒu��_�ڋq�R�[�h�K�{���̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_06 ) THEN
      -- �ݒu��_�ڋq�R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.install_at_customer_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_09            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item                 -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_inst_at_cust_cd  -- �g�[�N���l1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u��Ɗ֘A�����̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_07 ) THEN
      -- ��Ɖ�ЃR�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.work_company_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                        , iv_token_value1 => cv_tkn_val_wk_company_cd  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ���Ə��R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.work_location_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_09           -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item                -- �g�[�N���R�[�h1
                        , iv_token_value1 => cv_tkn_val_wk_location_cd  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ��Ɗ�]���ԋ敪���u�w��v�̏ꍇ
      IF ( SUBSTRB( i_requisition_rec.work_hope_time_type, 1, 1 ) = cv_wk_hp_time_type_asgn ) THEN
        -- ��Ɗ�]���A��Ɗ�]���̂����ꂩ�������͂̏ꍇ
        IF ( i_requisition_rec.work_hope_time_hour IS NULL 
             OR i_requisition_rec.work_hope_time_minute IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_11          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
/*20090413_yabuki_ST170 START*/
      -- �˗��� �� ��Ɗ�]���i��Ɗ�]�N||��Ɗ�]��||��Ɗ�]���j�̏ꍇ
      IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
            > i_requisition_rec.work_hope_year
               || i_requisition_rec.work_hope_month
               || i_requisition_rec.work_hope_day ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_46          -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_req_date           -- �g�[�N���R�[�h1
                        , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
/*20090413_yabuki_ST170 END*/
      --
/*20090413_yabuki_ST171 START*/
      -- �ݒu�ꏊ�敪���u���O�v�̏ꍇ
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_exterior ) THEN
        -- �ݒu�ꏊ�K�������͂���Ă���ꍇ
        IF ( i_requisition_rec.install_place_floor IS NOT NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_47          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
/*20090413_yabuki_ST171 END*/
      --
      -- �ݒu�ꏊ�敪���u�����v�̏ꍇ
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_interior ) THEN
        -- �ݒu�ꏊ�K���������͂̏ꍇ
        IF ( i_requisition_rec.install_place_floor IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_12          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
      -- �G���x�[�^�Ԍ��A�G���x�[�^���s���̂ǂ��炩����̂ݓ��͂���Ă���ꍇ
      IF ( i_requisition_rec.elevator_frontage IS NULL AND i_requisition_rec.elevator_depth IS NOT NULL
           OR i_requisition_rec.elevator_frontage IS NOT NULL AND i_requisition_rec.elevator_depth IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_13          -- ���b�Z�[�W�R�[�h
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �����R�[�h�敪�����͂���Ă���ꍇ
      IF ( i_requisition_rec.extension_code_type IS NOT NULL ) THEN
        -- �����R�[�h(m)�������͂̏ꍇ
        IF ( i_requisition_rec.extension_code_meter IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_14          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u���g�֘A�����̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_08 ) THEN
      -- ���g��ЃR�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.withdraw_company_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_09            -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item                 -- �g�[�N���R�[�h1
                        , iv_token_value1 => cv_tkn_val_wthdrw_cmpny_cd  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ���g���Ə��R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.withdraw_location_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                        , iv_token_value1 => cv_tkn_val_wthdrw_loc_cd  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u�p��_�����R�[�h�K�{���̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_09 ) THEN
      -- �p��_�����R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.abolishment_install_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_ablsh_inst_cd  -- �g�[�N���l1
                     );
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
/*20090413_yabuki_ST170_ST171 START*/
    -- �`�F�b�N�敪���u���g�֘A�����̓`�F�b�N�Q�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_10 ) THEN
      -- ���g��ЃR�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.withdraw_company_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_09            -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item                 -- �g�[�N���R�[�h1
                        , iv_token_value1 => cv_tkn_val_wthdrw_cmpny_cd  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ���g���Ə��R�[�h�������͂̏ꍇ
      IF ( i_requisition_rec.withdraw_location_code IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                        , iv_token_value1 => cv_tkn_val_wthdrw_loc_cd  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ��Ɗ�]���ԋ敪���u�w��v�̏ꍇ
      IF ( SUBSTRB( i_requisition_rec.work_hope_time_type, 1, 1 ) = cv_wk_hp_time_type_asgn ) THEN
        -- ��Ɗ�]���A��Ɗ�]���̂����ꂩ�������͂̏ꍇ
        IF ( i_requisition_rec.work_hope_time_hour IS NULL 
             OR i_requisition_rec.work_hope_time_minute IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_11          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
      -- �˗��� �� ��Ɗ�]���i��Ɗ�]�N||��Ɗ�]��||��Ɗ�]���j�̏ꍇ
      IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
            > i_requisition_rec.work_hope_year
               || i_requisition_rec.work_hope_month
               || i_requisition_rec.work_hope_day ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_46          -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_req_date           -- �g�[�N���R�[�h1
                        , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- �g�[�N���l1
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu�ꏊ�敪���u���O�v�̏ꍇ
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_exterior ) THEN
        -- �ݒu�ꏊ�K�������͂���Ă���ꍇ
        IF ( i_requisition_rec.install_place_floor IS NOT NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_47          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
      -- �ݒu�ꏊ�敪���u�����v�̏ꍇ
      IF ( SUBSTRB( i_requisition_rec.install_place_type, 1, 1 ) = cv_inst_place_type_interior ) THEN
        -- �ݒu�ꏊ�K���������͂̏ꍇ
        IF ( i_requisition_rec.install_place_floor IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_12          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
      --
      -- �G���x�[�^�Ԍ��A�G���x�[�^���s���̂ǂ��炩����̂ݓ��͂���Ă���ꍇ
      IF ( i_requisition_rec.elevator_frontage IS NULL AND i_requisition_rec.elevator_depth IS NOT NULL
           OR i_requisition_rec.elevator_frontage IS NOT NULL AND i_requisition_rec.elevator_depth IS NULL ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_13          -- ���b�Z�[�W�R�[�h
                      );
        --
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �����R�[�h�敪�����͂���Ă���ꍇ
      IF ( i_requisition_rec.extension_code_type IS NOT NULL ) THEN
        -- �����R�[�h(m)�������͂̏ꍇ
        IF ( i_requisition_rec.extension_code_meter IS NULL ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_14          -- ���b�Z�[�W�R�[�h
                        );
          --
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
          --
        END IF;
        --
      END IF;
/*20090413_yabuki_ST170_ST171 END*/
      --
    END IF;
    --
    ov_errbuf := lv_errbuf;
    --
  EXCEPTION
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END input_check;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_ib_existence
   * Description      : �����}�X�^���݃`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE check_ib_existence(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , o_instance_rec   OUT NOCOPY g_instance_rtype  -- �������
    , ov_errbuf        OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ib_existence';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_wk_hp_time_type_asgn    CONSTANT VARCHAR2(1) := '1';  -- ��Ɗ�]���ԋ敪=�u�w��v
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2    VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    BEGIN
      SELECT xibv.instance_id                  instance_id            -- �C���X�^���XID
           , NVL( xibv.op_request_flag, 'N' )  op_request_flag        -- ��ƈ˗����t���O
           , xibv.jotai_kbn1                   jotai_kbn1             -- �@���ԂP�i�ғ���ԁj
           , xibv.jotai_kbn3                   jotai_kbn3             -- �@���ԂR�i�p�����j
           , xibv.object_version_number        object_version_number  -- �I�u�W�F�N�g�o�[�W�����ԍ�
           /*20090413_yabuki_ST198 START*/
           , xibv.lease_kbn                    lease_kbn              -- ���[�X�敪
           /*20090413_yabuki_ST198 END*/
           /*20090427_yabuki_ST505_517 START*/
           , xibv.install_account_id           owner_account_id       -- �ݒu��A�J�E���gID
           /*20090427_yabuki_ST505_517 END*/
      INTO   o_instance_rec.instance_id  -- �C���X�^���XID
           , o_instance_rec.op_req_flag  -- ��ƈ˗����t���O
           , o_instance_rec.jotai_kbn1   -- �@���ԂP�i�ғ���ԁj
           , o_instance_rec.jotai_kbn3   -- �@���ԂR�i�p�����j
           , o_instance_rec.obj_ver_num  -- �I�u�W�F�N�g�o�[�W�����ԍ�
           /*20090413_yabuki_ST198 START*/
           , o_instance_rec.lease_kbn    -- ���[�X�敪
           /*20090413_yabuki_ST198 END*/
           /*20090427_yabuki_ST505_517 START*/
           , o_instance_rec.owner_account_id  -- �ݒu��A�J�E���gID
           /*20090427_yabuki_ST505_517 END*/
      FROM   xxcso_install_base_v  xibv
      WHERE  xibv.install_code = iv_install_code
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_15          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_16          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** �f�[�^�擾SQL��O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_ib_existence;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_ib_info
   * Description      : �ݒu�p�������`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE check_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , i_instance_rec   IN         g_instance_rtype                        -- �������
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode2    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ��ƈ˗����t���O_�ݒu�p���n�m�̏ꍇ
    IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_17          -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                    );
      --
      lv_errbuf  := lv_errbuf2;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �@���ԂP�i�ғ���ԁj��NULL�܂��́u�ؗ��v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_hold )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_18           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken              -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code            -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_status1             -- �g�[�N���R�[�h2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- �g�[�N���l2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �@���ԂR�i�p�����j��NULL�܂��́u�\�薳�v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn3 IS NULL )
      OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_19           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken              -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code            -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_status3             -- �g�[�N���R�[�h2
                      , iv_token_value2 => i_instance_rec.jotai_kbn3  -- �g�[�N���l2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �`�F�b�N�ŃG���[���������ꍇ
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_withdraw_ib_info
   * Description      : ���g�p�������`�F�b�N����(A-6)
   ***********************************************************************************/
  PROCEDURE check_withdraw_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , i_instance_rec   IN         g_instance_rtype                        -- �������
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_withdraw_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode2    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ��ƈ˗����t���O���n�m�̏ꍇ
    IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_20          -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                    );
      --
      lv_errbuf  := lv_errbuf2;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �@���ԂP�i�ғ���ԁj��NULL�܂��́u�ғ��v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_operate )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_21           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken              -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code            -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_status1             -- �g�[�N���R�[�h2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- �g�[�N���l2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    --
    -- �`�F�b�N�ŃG���[���������ꍇ
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_withdraw_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_ablsh_appl_ib_info
   * Description      : �p���\���p�������`�F�b�N����(A-7)
   ***********************************************************************************/
  PROCEDURE check_ablsh_appl_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , i_instance_rec   IN         g_instance_rtype                        -- �������
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ablsh_appl_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode2    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ��ƈ˗����t���O���n�m�̏ꍇ
    IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_22          -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                    );
      --
      lv_errbuf  := lv_errbuf2;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �@���ԂP�i�ғ���ԁj��NULL�܂��́u�ؗ��v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_hold )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_23           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken              -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code            -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_status1             -- �g�[�N���R�[�h2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- �g�[�N���l2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �@���ԂR�i�p�����j��NULL�܂��́u�\�薳�v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn3 IS NULL )
      OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_24           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken              -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code            -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_status3             -- �g�[�N���R�[�h2
                      , iv_token_value2 => i_instance_rec.jotai_kbn3  -- �g�[�N���l2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �`�F�b�N�ŃG���[���������ꍇ
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_ablsh_appl_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_ablsh_aprv_ib_info
   * Description      : �p�����ٗp�������`�F�b�N����(A-8)
   ***********************************************************************************/
  PROCEDURE check_ablsh_aprv_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , i_instance_rec   IN         g_instance_rtype                        -- �������
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_ablsh_aprv_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode2    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �@���ԂP�i�ғ���ԁj��NULL�܂��́u�ؗ��v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn1 IS NULL )
      OR ( i_instance_rec.jotai_kbn1 <> cv_jotai_kbn1_hold )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_23           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken              -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code            -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_status1             -- �g�[�N���R�[�h2
                      , iv_token_value2 => i_instance_rec.jotai_kbn1  -- �g�[�N���l2
                    );
      --
      lv_errbuf  := lv_errbuf2;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �@���ԂR�i�p�����j��NULL�܂��́u�p���\�����v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn3 IS NULL )
      OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_appl )
    THEN
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_tkn_number_25           -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_bukken              -- �g�[�N���R�[�h1
                      , iv_token_value1 => iv_install_code            -- �g�[�N���l1
                      , iv_token_name2  => cv_tkn_status3             -- �g�[�N���R�[�h2
                      , iv_token_value2 => i_instance_rec.jotai_kbn3  -- �g�[�N���l2
                    );
      --
      lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                         THEN lv_errbuf2
                         ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      ov_retcode := cv_status_error;
      --
    END IF;
    --
    -- �`�F�b�N�ŃG���[���������ꍇ
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_ablsh_aprv_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_mvmt_in_shp_ib_info
   * Description      : �X���ړ��p�������`�F�b�N����(A-9)
   ***********************************************************************************/
  PROCEDURE check_mvmt_in_shp_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , i_instance_rec   IN         g_instance_rtype                        -- �������
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_mvmt_in_shp_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
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
    -- *** ���[�J����O ***
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ��ƈ˗����t���O���n�m�̏ꍇ
    IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_17          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                     , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                   );
      --
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    END IF;
    --
  EXCEPTION
    --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_mvmt_in_shp_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_object_status
   * Description      : ���[�X�����X�e�[�^�X�`�F�b�N����(A-10)
   ***********************************************************************************/
  PROCEDURE check_object_status(
      iv_chk_kbn       IN         VARCHAR2                                -- �`�F�b�N�敪
    , iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_object_status';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_obj_sts_contracted          CONSTANT VARCHAR2(3) := '102';  -- �_���
    cv_obj_sts_re_lease_cntrctd    CONSTANT VARCHAR2(3) := '104';  -- �ă��[�X�_���
    cv_obj_sts_canceled_cnvnnc     CONSTANT VARCHAR2(3) := '110';  -- ���r���i���ȓs���j
    cv_obj_sts_canceled_insurance  CONSTANT VARCHAR2(3) := '111';  -- ���r���i�ی��Ή��j
    cv_obj_sts_canceled_expired    CONSTANT VARCHAR2(3) := '112';  -- ���r���i�����j
    cv_obj_sts_expired             CONSTANT VARCHAR2(3) := '107';  -- ����
    --
    -- *** ���[�J���ϐ� ***
    lv_object_status    xxcff_object_headers.object_status%TYPE;    -- �����X�e�[�^�X
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ========================================
    -- ���[�X�����e�[�u�����o
    -- ========================================
    BEGIN
      SELECT xoh.object_status  object_status
      INTO   lv_object_status
      FROM   xxcff_object_headers  xoh
      WHERE  xoh.object_code = iv_install_code
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_26          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_28          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
    END;
    -- ========================================
    -- ���[�X�����X�e�[�^�X�`�F�b�N
    -- ========================================
    -- �`�F�b�N�Ώۂ��ݒu�p�����̏ꍇ
    IF ( iv_chk_kbn = cv_obj_sts_chk_kbn_01 ) THEN
      -- �����X�e�[�^�X��NULL�ȊO�ł��A�u�_��ρv�u�ă��[�X�_��ρv�ȊO�̏ꍇ
      IF ( lv_object_status IS NOT NULL
           AND lv_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd ) ) THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_27          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                         , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                       );
          --
          RAISE sql_expt;
          --
      END IF;
      --
    ELSE
      -- �����X�e�[�^�X��NULL�ȊO�ł��A
      -- �u�ă��[�X�_��ρv�u���r���i���ȓs���j�v�u���r���i�ی��Ή��j�v�u���r���i�����j�v�u�����v�ȊO�̏ꍇ
      IF ( lv_object_status IS NOT NULL
           AND lv_object_status NOT IN ( cv_obj_sts_re_lease_cntrctd, cv_obj_sts_canceled_cnvnnc, cv_obj_sts_canceled_insurance
                                         , cv_obj_sts_canceled_expired, cv_obj_sts_expired ) ) THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_29          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                         , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                       );
          --
          RAISE sql_expt;
          --
      END IF;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O���`�F�b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_object_status;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_syozoku_mst
   * Description      : �����}�X�^���݃`�F�b�N����(A-11)
   ***********************************************************************************/
  PROCEDURE check_syozoku_mst(
      iv_work_company_code   IN         VARCHAR2    -- ��Ɖ�ЃR�[�h
    , iv_work_location_code  IN         VARCHAR2    -- ���Ə��R�[�h
    , ov_errbuf              OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode             OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_syozoku_mst';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_lookup_cd_syozoku_mst    CONSTANT VARCHAR2(30) := 'XXCSO1_SYOZOKU_MST';  -- �Q�ƃ^�C�v�u�����}�X�^�v
    cv_enabled_flag_enabled     CONSTANT VARCHAR2(1)  := 'Y';                   -- �Q�ƃ^�C�v�̗L���t���O�u�L���v
    --
    -- *** ���[�J���ϐ� ***
    ln_cnt_rec    NUMBER;
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ========================================
    -- �����}�X�^���o
    -- ========================================
    BEGIN
      SELECT COUNT( flvv.lookup_code )  cnt
      INTO   ln_cnt_rec
      FROM   fnd_lookup_values_vl  flvv
      WHERE  flvv.lookup_type  = cv_lookup_cd_syozoku_mst
      AND    flvv.lookup_code  = iv_work_company_code || iv_work_location_code
      AND    TRUNC( SYSDATE ) BETWEEN TRUNC( NVL( flvv.start_date_active, SYSDATE ) )
                              AND     TRUNC( NVL( flvv.end_date_active, SYSDATE ) )
      AND    flvv.enabled_flag = cv_enabled_flag_enabled
      ;
      --
      -- �Y���f�[�^�����݂��Ȃ��ꍇ
      IF ( ln_cnt_rec = 0 ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_30            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_wk_company_cd        -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_work_company_code        -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_location_cd          -- �g�[�N���R�[�h2
                       , iv_token_value2 => iv_work_location_code       -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_31            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_wk_company_cd        -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_work_company_code        -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_location_cd          -- �g�[�N���R�[�h2
                       , iv_token_value2 => iv_work_location_code       -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O���`�F�b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_syozoku_mst;
  --
  --
  /**********************************************************************************
   * Procedure Name   : check_cust_mst
   * Description      : �ڋq�}�X�^���݃`�F�b�N����(A-12)
   ***********************************************************************************/
  PROCEDURE check_cust_mst(
      iv_account_number   IN         VARCHAR2    -- �ڋq�R�[�h
/*20090427_yabuki_ST505_517 START*/
    , id_process_date           IN   DATE        -- �Ɩ��������t
    , iv_install_code           IN   VARCHAR2    -- �ݒu�p�����R�[�h
    , iv_withdraw_install_code  IN   VARCHAR2    -- ���g�p�����R�[�h
    , in_owner_account_id       IN   NUMBER      -- �ݒu��A�J�E���gID
/*20090427_yabuki_ST505_517 END*/
    , ov_errbuf           OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode          OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_cust_mst';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_party_sts_active    CONSTANT VARCHAR2(1) := 'A';   -- �p�[�e�B�X�e�[�^�X�u�L���v
    cv_account_sts_active  CONSTANT VARCHAR2(1) := 'A';   -- �A�J�E���g�X�e�[�^�X�u�L���v
    /*20090427_yabuki_ST0505_0517 START*/
    cv_acct_site_sts_active   CONSTANT VARCHAR2(1) := 'A';   -- �ڋq���ݒn�X�e�[�^�X�u�L���v
    cv_party_site_sts_active  CONSTANT VARCHAR2(1) := 'A';   -- �p�[�e�B�T�C�g�X�e�[�^�X�u�L���v
    /*20090427_yabuki_ST0505_0517 END*/
    cv_cust_sts_approved   CONSTANT VARCHAR2(2) := '30';  -- �ڋq�X�e�[�^�X�u���F�ρv
    cv_cust_sts_customer   CONSTANT VARCHAR2(2) := '40';  -- �ڋq�X�e�[�^�X�u�ڋq�v
    cv_cust_sts_abeyance   CONSTANT VARCHAR2(2) := '50';  -- �ڋq�X�e�[�^�X�u�x�~�v
    /*20090402_yabuki_ST177 START*/
    cv_cust_sts_sp_aprvd   CONSTANT VARCHAR2(2) := '25';  -- �ڋq�X�e�[�^�X�uSP���F�ρv
    /*20090402_yabuki_ST177 END*/
    /*20090427_yabuki_ST0505_0517 START*/
    cv_cust_resources_v    CONSTANT VARCHAR2(30) := '�ڋq�S���c�ƈ����';
    cv_tkn_val_cust_cd     CONSTANT VARCHAR2(30) := '�ڋq�R�[�h';
    /*20090427_yabuki_ST0505_0517 END*/
    --
    -- *** ���[�J���ϐ� ***
    lv_customer_status    xxcso_cust_accounts_v.customer_status%TYPE;  -- �ڋq�X�e�[�^�X
    /*20090427_yabuki_ST0505_0517 START*/
    lt_cust_acct_id       xxcso_cust_accounts_v.cust_account_id%TYPE;  -- �A�J�E���gID
    ln_cnt_rec            NUMBER;                                      -- ���R�[�h����
    /*20090427_yabuki_ST0505_0517 END*/
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ========================================
    -- �ڋq�}�X�^���o
    -- ========================================
    BEGIN
/*20090427_yabuki_ST505_517 START*/
--      SELECT xcav.customer_status  customer_status
--      INTO   lv_customer_status
--      FROM   xxcso_cust_accounts_v  xcav
--      WHERE  xcav.account_number = iv_account_number
--      AND    xcav.account_status = cv_party_sts_active
--      AND    xcav.party_status   = cv_account_sts_active
--      ;
      SELECT casv.customer_status  customer_status    -- �ڋq�X�e�[�^�X
           , casv.cust_account_id  cust_account_id    -- �A�J�E���gID
      INTO   lv_customer_status
           , lt_cust_acct_id
      FROM   xxcso_cust_acct_sites_v  casv    -- �ڋq�}�X�^�T�C�g�r���[
      WHERE casv.account_number    = iv_account_number
      AND   casv.account_status    = cv_account_sts_active
      AND   casv.acct_site_status  = cv_acct_site_sts_active
      AND   casv.party_status      = cv_party_sts_active
      AND   casv.party_site_status = cv_party_site_sts_active
      ;
/*20090427_yabuki_ST505_517 END*/
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_32            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_kokyaku              -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_account_number           -- �g�[�N���l1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_33            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_kokyaku              -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_account_number           -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_err_msg              -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM                     -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    /*20090402_yabuki_ST177 START*/
    -- �擾�����ڋq�X�e�[�^�X���u���F�ρv�u�ڋq�v�u�x�~�v�uSP���F�ρv�ȊO�̏ꍇ
    IF ( lv_customer_status NOT IN ( cv_cust_sts_approved, cv_cust_sts_customer, cv_cust_sts_abeyance, cv_cust_sts_sp_aprvd ) ) THEN
--    -- �擾�����ڋq�X�e�[�^�X���u���F�ρv�u�ڋq�v�u�x�~�v�ȊO�̏ꍇ
--    IF ( lv_customer_status NOT IN ( cv_cust_sts_approved, cv_cust_sts_customer, cv_cust_sts_abeyance ) ) THEN
    /*20090402_yabuki_ST177 END*/
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_34            -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_kokyaku              -- �g�[�N���R�[�h1
                     , iv_token_value1 => iv_account_number           -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_cust_status          -- �g�[�N���R�[�h2
                     , iv_token_value2 => lv_customer_status          -- �g�[�N���l2
                   );
      --
      RAISE sql_expt;
      --
    END IF;
    --
/*20090427_yabuki_ST505_517 START*/
    BEGIN
      SELECT COUNT(1)
      INTO   ln_cnt_rec
      FROM   xxcso_employees_v       empv    -- �]�ƈ��}�X�^�r���[
           , xxcso_cust_resources_v  crsv    -- �ڋq�S���c�ƈ��r���[
      WHERE crsv.account_number    = iv_account_number
      AND   id_process_date
              BETWEEN TRUNC( NVL( crsv.start_date_active, id_process_date ) )
                  AND TRUNC( NVL( crsv.end_date_active, id_process_date ) )
      AND   crsv.employee_number   = empv.employee_number
      AND   id_process_date
              BETWEEN TRUNC( NVL( empv.start_date, id_process_date ) )
                  AND TRUNC( NVL( empv.end_date, id_process_date ) )
      AND   id_process_date
              BETWEEN TRUNC( NVL( empv.employee_start_date, id_process_date ) )
                  AND TRUNC( NVL( empv.employee_end_date, id_process_date ) )
      AND   id_process_date
              BETWEEN TRUNC( NVL( empv.assign_start_date, id_process_date ) )
                  AND TRUNC( NVL( empv.assign_end_date, id_process_date ) )
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_49          -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_cust_resources_v       -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_tkn_val_cust_cd        -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                       , iv_token_value3 => iv_account_number         -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_err_msg            -- �g�[�N���R�[�h4
                       , iv_token_value4 => SQLERRM                   -- �g�[�N���l4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- �Y���f�[�^�����݂��Ȃ��ꍇ
    IF ( ln_cnt_rec = 0 ) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_48          -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_cust_resources_v       -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_item               -- �g�[�N���R�[�h2
                     , iv_token_value2 => cv_tkn_val_cust_cd        -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_value              -- �g�[�N���R�[�h3
                     , iv_token_value3 => iv_account_number         -- �g�[�N���l3
                   );
      --
      RAISE sql_expt;
      --
    END IF;
    --
    -- �ݒu�p�����R�[�h���ݒ肳��Ă���ꍇ
    IF ( iv_install_code IS NOT NULL ) THEN
      -- �ݒu�p�����̐ݒu��A�J�E���gID�Ɛݒu��_�ڋq�R�[�h�̃A�J�E���gID���قȂ�ꍇ
      IF ( in_owner_account_id <> lt_cust_acct_id ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_50            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken               -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_install_code             -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_kokyaku              -- �g�[�N���R�[�h2
                       , iv_token_value2 => iv_account_number           -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    END IF;
    --
    -- ���g�p�����R�[�h���ݒ肳��Ă���ꍇ
    IF ( iv_withdraw_install_code IS NOT NULL ) THEN
      -- �ݒu�p�����̐ݒu��A�J�E���gID�Ɛݒu��_�ڋq�R�[�h�̃A�J�E���gID���قȂ�ꍇ
      IF ( in_owner_account_id <> lt_cust_acct_id ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_51            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken               -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_withdraw_install_code    -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_kokyaku              -- �g�[�N���R�[�h2
                       , iv_token_value2 => iv_account_number           -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
      END IF;
      --
    END IF;
/*20090427_yabuki_ST505_517 END*/
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O���`�F�b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END check_cust_mst;
  --
  --
  /**********************************************************************************
   * Procedure Name   : lock_ib_info
   * Description      : �������b�N����(A-13)
   ***********************************************************************************/
  PROCEDURE lock_ib_info(
      in_instance_id         IN         csi_item_instances.instance_id%TYPE    -- �C���X�^���XID
    , iv_install_code        IN         VARCHAR2    -- �����R�[�h
    , iv_lock_err_tkn_num    IN         VARCHAR2    -- ���b�N���s���̃G���[���b�Z�[�W�ԍ�
    , iv_others_err_tkn_num  IN         VARCHAR2    -- ���o���s���̃G���[���b�Z�[�W�ԍ�
    , ov_errbuf              OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode             OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'lock_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    --
    -- *** ���[�J���ϐ� ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    --
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ========================================
    -- �����̃��b�N
    -- ========================================
    BEGIN
      SELECT cii.instance_id  instance_id
      INTO   ln_instance_id
      FROM   csi_item_instances  cii
      WHERE  cii.instance_id = in_instance_id
      FOR UPDATE NOWAIT
      ;
      --
    EXCEPTION
      WHEN g_lock_expt THEN
        -- ���b�N�Ɏ��s�����ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => iv_lock_err_tkn_num         -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken               -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_install_code             -- �g�[�N���l1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => iv_others_err_tkn_num       -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_bukken               -- �g�[�N���R�[�h1
                       , iv_token_value1 => iv_install_code             -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_err_msg              -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM                     -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O�����b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END lock_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_ib_info
   * Description      : �ݒu�p�����X�V����(A-14)
   ***********************************************************************************/
  PROCEDURE update_ib_info(
/*20090416_yabuki_ST398 START*/
      iv_process_kbn          IN         VARCHAR2                                -- �����敪
    , i_instance_rec          IN         g_instance_rtype                        -- �������
--      i_instance_rec          IN         g_instance_rtype                        -- �������
/*20090416_yabuki_ST398 END*/
    , i_requisition_rec       IN         g_requisition_rtype                     -- �����˗����
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- ����^�C�vID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- ��ƈ˗����t���O�u�n�m�v
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- *** ���[�J���ϐ� ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    --
    -- API���͒l�i�[�p
    ln_validation_level    NUMBER;
    --
    -- API���o�̓��R�[�h�l�i�[�p
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- �߂�l�i�[�p
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ========================================
    -- A-10. �������b�N����
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_35
      , iv_others_err_tkn_num => cv_tkn_number_36
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- �������b�N����������I���łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- �����敪���u�����˗��\���v�̏ꍇ
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
/*20090416_yabuki_ST398 END*/
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- �����敪���u�����˗��۔F�v�̏ꍇ
    --------------------------------------------------
    ELSE
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
    END IF;
/*20090416_yabuki_ST398 END*/
    --
    ------------------------------
    -- ������R�[�h�ݒ�
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    ------------------------------
    -- �h�a�X�V�p�W��API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- API������I���łȂ��ꍇ
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O�����b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- API�ŃG���[�����������ꍇ
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                 -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_37                         -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_bukken                            -- �g�[�N���R�[�h1
                     , iv_token_value1 => i_requisition_rec.withdraw_install_code  -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_api_err_msg                       -- �g�[�N���R�[�h2
                     , iv_token_value2 => lv_msg_data                              -- �g�[�N���l2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END update_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_withdraw_ib_info
   * Description      : ���g�p�����X�V����(A-15)
   ***********************************************************************************/
  PROCEDURE update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
      iv_process_kbn          IN         VARCHAR2                                -- �����敪
    , i_instance_rec          IN         g_instance_rtype                        -- �������
--      i_instance_rec          IN         g_instance_rtype                        -- �������
/*20090416_yabuki_ST398 END*/
    , i_requisition_rec       IN         g_requisition_rtype                     -- �����˗����
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- ����^�C�vID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_withdraw_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- ��ƈ˗����t���O�u�n�m�v
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- *** ���[�J���ϐ� ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    --
    -- API���͒l�i�[�p
    ln_validation_level    NUMBER;
    --
    -- API���o�̓��R�[�h�l�i�[�p
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- �߂�l�i�[�p
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ========================================
    -- A-10. �������b�N����
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.withdraw_install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_38
      , iv_others_err_tkn_num => cv_tkn_number_39
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- �������b�N����������I���łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- �����敪���u�����˗��\���v�̏ꍇ
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
/*20090416_yabuki_ST398 END*/
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- �����敪���u�����˗��۔F�v�̏ꍇ
    --------------------------------------------------
    ELSE
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
    END IF;
/*20090416_yabuki_ST398 END*/
    --
    ------------------------------
    -- ������R�[�h�ݒ�
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    ------------------------------
    -- �h�a�X�V�p�W��API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- API������I���łȂ��ꍇ
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O�����b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- API�ŃG���[�����������ꍇ
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                 -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_40                         -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_bukken                            -- �g�[�N���R�[�h1
                     , iv_token_value1 => i_requisition_rec.withdraw_install_code  -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_api_err_msg                       -- �g�[�N���R�[�h2
                     , iv_token_value2 => lv_msg_data                              -- �g�[�N���l2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END update_withdraw_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_abo_appl_ib_info
   * Description      : �p���\���p�����X�V����(A-16)
   ***********************************************************************************/
  PROCEDURE update_abo_appl_ib_info(
      iv_process_kbn          IN         VARCHAR2                                -- �����敪
    , i_instance_rec          IN         g_instance_rtype                        -- �������
    , i_requisition_rec       IN         g_requisition_rtype                     -- �����˗����
    , i_ib_ext_attr_id_rec    IN         g_ib_ext_attr_id_rtype                  -- IB�ǉ�����ID���
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- ����^�C�vID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_abo_appl_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- ��ƈ˗����t���O�u�n�m�v
--    cv_op_req_flag_off     CONSTANT VARCHAR2(1)    := 'N';  -- ��ƈ˗����t���O�u�n�e�e�v
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- �����l
    cv_jotai_kbn3_ablsh_appl  CONSTANT VARCHAR2(1) := '2';  -- �@���ԂR�i�p�����j�u�p���\�����v
    cv_ablsh_flg_ablsh_appl   CONSTANT VARCHAR2(1) := '1';  -- �p���t���O�u�p���\�����v
    --
    -- *** ���[�J���f�[�^�^ ***
    TYPE l_iea_val_ttype IS TABLE OF csi_iea_values%ROWTYPE INDEX BY BINARY_INTEGER;
    --
    -- *** ���[�J���ϐ� ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    l_iea_val_rec     csi_iea_values%ROWTYPE;
    l_iea_val_tab     l_iea_val_ttype;
    --
    -- API���͒l�i�[�p
    ln_validation_level    NUMBER;
    --
    -- API���o�̓��R�[�h�l�i�[�p
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- �߂�l�i�[�p
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    --------------------------------------------------
    -- �����敪���u�����˗��\���v�̏ꍇ
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
/*20090416_yabuki_ST549 START*/
--      ------------------------------
--      -- �ǉ������l���擾
--      ------------------------------
--      -- �@���ԂR�i�p�����j
--      l_iea_val_tab(1)
--        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
--               in_instance_id    => i_instance_rec.instance_id  -- �C���X�^���XID
--             , iv_attribute_code => cv_attr_cd_jotai_kbn3       -- ������`
--           );
--      --
--      -- �p���t���O
--      l_iea_val_tab(2)
--        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
--               in_instance_id    => i_instance_rec.instance_id  -- �C���X�^���XID
--             , iv_attribute_code => cv_attr_cd_ven_haiki_flg    -- ������`
--           );
--      --
--      ------------------------------
--      -- �ǉ������l��񃌃R�[�h�ݒ�
--      ------------------------------
--      -- �@���ԂR�i�p�����j
--      l_ext_attrib_values_tab(1).attribute_value_id    := l_iea_val_tab(1).attribute_value_id;
--      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_appl;
--      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
--      --
--      -- �p���t���O
--      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
--        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
--        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
--        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_appl;
--        --
--      ELSE
--        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
--        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_appl;
--        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
--        --
--      END IF;
/*20090416_yabuki_ST549 END*/
      --
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- �����敪���u�����˗��۔F�v�̏ꍇ
    --------------------------------------------------
    ELSIF ( iv_process_kbn = cv_proc_kbn_req_dngtn ) THEN
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 END*/
      --
    --------------------------------------------------
    -- �����敪���u�����˗����F�v�̏ꍇ
    --------------------------------------------------
    ELSE
/*20090416_yabuki_ST549 START*/
      ------------------------------
      -- �ǉ������l���擾
      ------------------------------
      -- �@���ԂR�i�p�����j
      l_iea_val_tab(1)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- �C���X�^���XID
             , iv_attribute_code => cv_attr_cd_jotai_kbn3       -- ������`
           );
      --
      -- �p���t���O
      l_iea_val_tab(2)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- �C���X�^���XID
             , iv_attribute_code => cv_attr_cd_ven_haiki_flg    -- ������`
           );
      --
      ------------------------------
      -- �ǉ������l��񃌃R�[�h�ݒ�
      ------------------------------
      -- �@���ԂR�i�p�����j
      l_ext_attrib_values_tab(1).attribute_value_id    := l_iea_val_tab(1).attribute_value_id;
      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_appl;
      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
      --
      -- �p���t���O
      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_appl;
        --
      ELSE
        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_appl;
        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
        --
      END IF;
/*20090416_yabuki_ST549 END*/
      --
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST549 START*/
      l_instance_rec.instance_status_id     := gt_instance_status_id_4;    -- �C���X�^���X�X�e�[�^�XID�i�p���葱���j
/*20090416_yabuki_ST549 END*/
      --
    END IF;
    --
    ------------------------------
    -- ������R�[�h�ݒ�
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    -- ========================================
    -- A-10. �������b�N����
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.abolishment_install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_41
      , iv_others_err_tkn_num => cv_tkn_number_42
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- �������b�N����������I���łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
    ------------------------------
    -- �h�a�X�V�p�W��API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- API������I���łȂ��ꍇ
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O�����b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- API�ŃG���[�����������ꍇ
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_40                            -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_bukken                               -- �g�[�N���R�[�h1
                     , iv_token_value1 => i_requisition_rec.abolishment_install_code  -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_api_err_msg                          -- �g�[�N���R�[�h2
                     , iv_token_value2 => lv_msg_data                                 -- �g�[�N���l2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END update_abo_appl_ib_info;
  --
  --
  /**********************************************************************************
   * Procedure Name   : update_abo_aprv_ib_info
   * Description      : �p�����ٗp�����X�V����(A-17)
   ***********************************************************************************/
  PROCEDURE update_abo_aprv_ib_info(
      iv_process_kbn          IN         VARCHAR2                                -- �����敪
    , id_process_date         IN         DATE                                    -- �Ɩ��������t
    , i_instance_rec          IN         g_instance_rtype                        -- �������
    , i_requisition_rec       IN         g_requisition_rtype                     -- �����˗����
    , i_ib_ext_attr_id_rec    IN         g_ib_ext_attr_id_rtype                  -- IB�ǉ�����ID���
    , in_transaction_type_id  IN         csi_txn_types.transaction_type_id%TYPE  -- ����^�C�vID
    , ov_errbuf               OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode              OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_abo_aprv_ib_info';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
/*20090416_yabuki_ST398 START*/
--    cv_op_req_flag_on      CONSTANT VARCHAR2(1)    := 'Y';  -- ��ƈ˗����t���O�u�n�m�v
--    cv_op_req_flag_off     CONSTANT VARCHAR2(1)    := 'N';  -- ��ƈ˗����t���O�u�n�e�e�v
/*20090416_yabuki_ST398 END*/
    cn_api_version         CONSTANT NUMBER         := 1.0;
    cv_commit_false        CONSTANT VARCHAR2(1)    := 'F';
    cv_init_msg_list_true  CONSTANT VARCHAR2(2000) := 'T';
    cv_encoded_false       CONSTANT VARCHAR2(1)    := 'F';
    --
    -- �����l
    cv_jotai_kbn3_ablsh_desc  CONSTANT VARCHAR2(1) := '3';  -- �@���ԂR�i�p�����j�u�p�����ٍρv
    cv_ablsh_flg_ablsh_desc   CONSTANT VARCHAR2(1) := '9';  -- �p���t���O�u�p�����ٍρv
    --
    -- *** ���[�J���f�[�^�^ ***
    TYPE l_iea_val_ttype IS TABLE OF csi_iea_values%ROWTYPE INDEX BY BINARY_INTEGER;
    --
    -- *** ���[�J���ϐ� ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    l_iea_val_rec     csi_iea_values%ROWTYPE;
    l_iea_val_tab     l_iea_val_ttype;
    --
    -- API���͒l�i�[�p
    ln_validation_level    NUMBER;
    --
    -- API���o�̓��R�[�h�l�i�[�p
    l_instance_rec           csi_datastructures_pub.instance_rec;
    l_ext_attrib_values_tab  csi_datastructures_pub.extend_attrib_values_tbl;
    l_party_tab              csi_datastructures_pub.party_tbl;
    l_account_tab            csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab     csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab    csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab   csi_datastructures_pub.instance_asset_tbl;
    l_txn_rec                csi_datastructures_pub.transaction_rec;
    l_instance_id_tab        csi_datastructures_pub.id_tbl;
    --
    -- �߂�l�i�[�p
    lv_return_status    VARCHAR2(1);
    ln_msg_count        NUMBER;
    ln_msg_count2       NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lv_msg_data2        VARCHAR2(2000);
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    api_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    --------------------------------------------------
    -- �����敪���u�����˗��\���v�̏ꍇ
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
      --
/*20090416_yabuki_ST398 START*/
    --------------------------------------------------
    -- �����敪���u�����˗��۔F�v�̏ꍇ
    --------------------------------------------------
    ELSIF ( iv_process_kbn = cv_proc_kbn_req_dngtn ) THEN
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST398 END*/
      --
    --------------------------------------------------
    -- �����敪���u�����˗����F�v�̏ꍇ
    --------------------------------------------------
    ELSE
     ------------------------------
      -- �ǉ������l���擾
      ------------------------------
      -- �@���ԂR�i�p�����j
      l_iea_val_tab(1)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- �C���X�^���XID
             , iv_attribute_code => cv_attr_cd_jotai_kbn3       -- ������`
           );
      --
      -- �p���t���O
      l_iea_val_tab(2)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- �C���X�^���XID
             , iv_attribute_code => cv_attr_cd_ven_haiki_flg    -- ������`
           );
      --
      -- �p�����ٓ�
      l_iea_val_tab(3)
        := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(
               in_instance_id    => i_instance_rec.instance_id  -- �C���X�^���XID
             , iv_attribute_code => cv_attr_cd_haikikessai_dt   -- ������`
           );
      --
      ------------------------------
      -- �ǉ������l��񃌃R�[�h�ݒ�
      ------------------------------
      -- �@���ԂR�i�p�����j
      l_ext_attrib_values_tab(1).attribute_value_id    := l_iea_val_tab(1).attribute_value_id;
      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_desc;
      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
      --
      -- �p���t���O
      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_desc;
        --
      ELSE
        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_desc;
        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
        --
      END IF;
      --
      -- �p�����ٓ�
      IF ( l_iea_val_tab(3).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(3).attribute_id    := i_ib_ext_attr_id_rec.abolishment_decision_date;
        l_ext_attrib_values_tab(3).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(3).attribute_value := TRUNC( id_process_date );
        --
      ELSE
        l_ext_attrib_values_tab(3).attribute_value_id    := l_iea_val_tab(3).attribute_value_id;
        l_ext_attrib_values_tab(3).attribute_value       := TRUNC( id_process_date );
        l_ext_attrib_values_tab(3).object_version_number := l_iea_val_tab(3).object_version_number;
        --
      END IF;
      --
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST549 START*/
      l_instance_rec.instance_status_id     := gt_instance_status_id_4;    -- �C���X�^���X�X�e�[�^�XID�i�p���葱���j
/*20090416_yabuki_ST549 END*/
      --
    END IF;
    --
    ------------------------------
    -- ������R�[�h�ݒ�
    ------------------------------
    l_txn_rec.TRANSACTION_DATE        := SYSDATE;
    l_txn_rec.SOURCE_TRANSACTION_DATE := SYSDATE;
    l_txn_rec.TRANSACTION_TYPE_ID     := in_transaction_type_id;
    --
    -- ========================================
    -- A-10. �������b�N����
    -- ========================================
    lock_ib_info(
        in_instance_id        => i_instance_rec.instance_id
      , iv_install_code       => i_requisition_rec.abolishment_install_code
      , iv_lock_err_tkn_num   => cv_tkn_number_41
      , iv_others_err_tkn_num => cv_tkn_number_42
      , ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
    );
    --
    -- �������b�N����������I���łȂ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sql_expt;
      --
    END IF;
    --
    ------------------------------
    -- �h�a�X�V�p�W��API
    ------------------------------
    CSI_ITEM_INSTANCE_PUB.UPDATE_ITEM_INSTANCE(
        p_api_version           => cn_api_version
      , p_commit                => cv_commit_false
      , p_init_msg_list         => cv_init_msg_list_true
      , p_validation_level      => ln_validation_level
      , p_instance_rec          => l_instance_rec
      , p_ext_attrib_values_tbl => l_ext_attrib_values_tab
      , p_party_tbl             => l_party_tab
      , p_account_tbl           => l_account_tab
      , p_pricing_attrib_tbl    => l_pricing_attrib_tab
      , p_org_assignments_tbl   => l_org_assignments_tab
      , p_asset_assignment_tbl  => l_asset_assignment_tab
      , p_txn_rec               => l_txn_rec
      , x_instance_id_lst       => l_instance_id_tab
      , x_return_status         => lv_return_status
      , x_msg_count             => ln_msg_count
      , x_msg_data              => lv_msg_data
    );
    --
    -- API������I���łȂ��ꍇ
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE api_expt;
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O�����b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- API�ŃG���[�����������ꍇ
      ov_retcode := cv_status_error;
      --
      FOR i IN 1..fnd_msg_pub.count_msg LOOP
        fnd_msg_pub.get(
            p_msg_index     => i
          , p_encoded       => cv_encoded_false
          , p_data          => lv_msg_data2
          , p_msg_index_out => ln_msg_count2
        );
        lv_msg_data := lv_msg_data || lv_msg_data2;
        --
      END LOOP;
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name                    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_40                            -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_bukken                               -- �g�[�N���R�[�h1
                     , iv_token_value1 => i_requisition_rec.abolishment_install_code  -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_api_err_msg                          -- �g�[�N���R�[�h2
                     , iv_token_value2 => lv_msg_data                                 -- �g�[�N���l2
                   );
      --
      ov_errbuf := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END update_abo_aprv_ib_info;
  --
  --
/*20090406_yabuki_ST101 START*/
  /**********************************************************************************
   * Procedure Name   : chk_wk_req_proc
   * Description      : ��ƈ˗��^�������A�g�Ώۃe�[�u�����݃`�F�b�N����(A-18)
   ***********************************************************************************/
  PROCEDURE chk_wk_req_proc(
      i_requisition_rec  IN         g_requisition_rtype  -- �����˗����
    , on_rec_count       OUT        NUMBER               -- ���R�[�h�����i��ƈ˗��^�������A�g�Ώۃe�[�u���j
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_wk_req_proc';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_val_select_proc    CONSTANT VARCHAR2(100) := '���o';
    --
    -- *** ���[�J���f�[�^�^ ***
    --
    -- *** ���[�J���ϐ� ***
    ln_rec_count    NUMBER;    -- ���R�[�h����
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- ========================================
    -- ��ƈ˗��^�������A�g�Ώۃe�[�u�����o
    -- ========================================
    BEGIN
      SELECT COUNT(1)  cnt
      INTO   ln_rec_count
      FROM   xxcso_wk_requisition_proc  xwrp
      WHERE  xwrp.requisition_line_id = i_requisition_rec.requisition_line_id
      ;
      --
    EXCEPTION
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_45                           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_process                             -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_select_proc                     -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_req_num                             -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_requisition_rec.requisition_number       -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_req_line_num                        -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_requisition_rec.requisition_line_number  -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_err_msg                             -- �g�[�N���R�[�h4
                       , iv_token_value4 => SQLERRM                                    -- �g�[�N���l4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- ���R�[�h������OUT�p�����[�^�֐ݒ�
    on_rec_count := ln_rec_count;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O���`�F�b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END chk_wk_req_proc;
  --
  --
  /**********************************************************************************
   * Procedure Name   : insert_wk_req_proc
   * Description      : ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����(A-19)
   ***********************************************************************************/
--  /**********************************************************************************
--   * Procedure Name   : insert_wk_req_proc
--   * Description      : ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����(A-18)
--   ***********************************************************************************/
/*20090406_yabuki_ST101 END*/
  PROCEDURE insert_wk_req_proc(
      i_requisition_rec  IN         g_requisition_rtype  -- �����˗����
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'insert_wk_req_proc';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
/*20090406_yabuki_ST101 START*/
--    cv_interface_flg_off    CONSTANT VARCHAR2(1) := 'N';  -- �A�g�σt���O�u�n�e�e�v
    -- �g�[�N���p�萔
    cv_tkn_val_insert_proc    CONSTANT VARCHAR2(100) := '�o�^';
/*20090406_yabuki_ST101 END*/
    --
    -- *** ���[�J���f�[�^�^ ***
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    --------------------------------------------------
    -- ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^
    --------------------------------------------------
    BEGIN
      INSERT INTO xxcso_wk_requisition_proc(
          requisition_line_id     -- �����˗�����ID
        , requisition_header_id   -- �����˗��w�b�_ID
        , line_num                -- �����˗����הԍ�
        , interface_flag          -- �A�g�σt���O
        , interface_date          -- �A�g��
        , created_by              -- �쐬��
        , creation_date           -- �쐬��
        , last_updated_by         -- �ŏI�X�V��
        , last_update_date        -- �ŏI�X�V��
        , last_update_login       -- �ŏI�X�V���O�C��
        , request_id              -- �v��ID
        , program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id              -- �R���J�����g�E�v���O����ID
        , program_update_date     -- �v���O�����X�V��
      ) VALUES (
          i_requisition_rec.requisition_line_id      -- �����˗�����ID
        , i_requisition_rec.requisition_header_id    -- �����˗��w�b�_ID
        , i_requisition_rec.requisition_line_number  -- �����˗����הԍ�
        , cv_interface_flg_off                       -- �A�g�σt���O
        , NULL                                       -- �A�g��
        , fnd_global.user_id                         -- �쐬��
        , SYSDATE                                    -- �쐬��
        , fnd_global.user_id                         -- �ŏI�X�V��
        , SYSDATE                                    -- �ŏI�X�V��
        , fnd_global.login_id                        -- �ŏI�X�V���O�C��
        , fnd_global.conc_request_id                 -- �v��ID
        , fnd_global.prog_appl_id                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , fnd_global.conc_program_id                 -- �R���J�����g�E�v���O����ID
        , SYSDATE                                    -- �v���O�����X�V��
      );
    EXCEPTION
      WHEN OTHERS THEN
/*20090406_yabuki_ST101 START*/
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_45                           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_process                             -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_insert_proc                     -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_req_num                             -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_requisition_rec.requisition_number       -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_req_line_num                        -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_requisition_rec.requisition_line_number  -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_err_msg                             -- �g�[�N���R�[�h4
                       , iv_token_value4 => SQLERRM                                    -- �g�[�N���l4
                     );
--        lv_errbuf := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name                   -- �A�v���P�[�V�����Z�k��
--                       , iv_name         => cv_tkn_number_45                           -- ���b�Z�[�W�R�[�h
--                       , iv_token_name1  => cv_tkn_req_num                             -- �g�[�N���R�[�h1
--                       , iv_token_value1 => i_requisition_rec.requisition_number       -- �g�[�N���l1
--                       , iv_token_name2  => cv_tkn_req_line_num                        -- �g�[�N���R�[�h2
--                       , iv_token_value2 => i_requisition_rec.requisition_line_number  -- �g�[�N���l2
--                       , iv_token_name3  => cv_tkn_err_msg                             -- �g�[�N���R�[�h3
--                       , iv_token_value3 => SQLERRM                                    -- �g�[�N���l3
--                     );
/*20090406_yabuki_ST101 END*/
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL��O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END insert_wk_req_proc;
  --
  --
/*20090406_yabuki_ST101 START*/
  /**********************************************************************************
   * Procedure Name   : update_wk_req_proc
   * Description      : ��ƈ˗��^�������A�g�Ώۃe�[�u���X�V����(A-20)
   ***********************************************************************************/
  PROCEDURE update_wk_req_proc(
      i_requisition_rec  IN         g_requisition_rtype  -- �����˗����
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_wk_req_proc';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode    VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- �g�[�N���p�萔
    cv_tkn_val_update_proc    CONSTANT VARCHAR2(100) := '�X�V';
    --
    -- *** ���[�J���f�[�^�^ ***
    --
    -- *** ���[�J���ϐ� ***
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    --------------------------------------------------
    -- ��ƈ˗��^�������A�g�Ώۃe�[�u���X�V
    --------------------------------------------------
    BEGIN
      UPDATE xxcso_wk_requisition_proc
      SET line_num               = i_requisition_rec.requisition_line_number  -- �����˗����הԍ�
        , interface_flag         = cv_interface_flg_off                       -- �A�g�σt���O
        , interface_date         = NULL                                       -- �A�g��
        , last_updated_by        = fnd_global.user_id                         -- �ŏI�X�V��
        , last_update_date       = SYSDATE                                    -- �ŏI�X�V��
        , last_update_login      = fnd_global.login_id                        -- �ŏI�X�V���O�C��
        , request_id             = fnd_global.conc_request_id                 -- �v��ID
        , program_application_id = fnd_global.prog_appl_id                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id             = fnd_global.conc_program_id                 -- �R���J�����g�E�v���O����ID
        , program_update_date    = SYSDATE                                    -- �v���O�����X�V��
      WHERE
          requisition_line_id = i_requisition_rec.requisition_line_id    -- �����˗�����ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_45                           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_process                             -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_tkn_val_update_proc                     -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_req_num                             -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_requisition_rec.requisition_number       -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_req_line_num                        -- �g�[�N���R�[�h3
                       , iv_token_value3 => i_requisition_rec.requisition_line_number  -- �g�[�N���l3
                       , iv_token_name4  => cv_tkn_err_msg                             -- �g�[�N���R�[�h4
                       , iv_token_value4 => SQLERRM                                    -- �g�[�N���l4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL��O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END update_wk_req_proc;
/*20090406_yabuki_ST101 END*/
  --
/* 20090410_abe_T1_0108 START*/
  /**********************************************************************************
   * Procedure Name   : start_approval_wf_proc
   * Description      : ���F���[�N�t���[�N��(�G���[�ʒm)(A-21)
   ***********************************************************************************/
  PROCEDURE start_approval_wf_proc(
      iv_itemtype              IN         VARCHAR2
    , iv_itemkey               IN         VARCHAR2
    , iv_errmsg                IN         VARCHAR2
    , ov_errbuf                OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
    , ov_retcode               OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'start_approval_wf_proc';  -- �v���V�[�W����
    --
    --#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
    --
    lv_errbuf  VARCHAR2(5000); -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
    --
    --###########################  �Œ蕔 END   ####################################
    --
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_wf_itemtype              CONSTANT VARCHAR2(30) := 'XXCSO011';
    cv_wf_process               CONSTANT VARCHAR2(30) := 'XXCSO011A01P01';
    cv_wf_pkg_name              CONSTANT VARCHAR2(30) := 'wf_engine';
    cv_wf_createprocess         CONSTANT VARCHAR2(30) := 'createprocess';
    cv_wf_setitemattrtext       CONSTANT VARCHAR2(30) := 'setitemattrtext';
    cv_wf_startprocess          CONSTANT VARCHAR2(30) := 'startprocess';
    cv_wf_itemtype_reqpprv      CONSTANT VARCHAR2(30) := 'REQAPPRV';
    cv_wf_activity_status       CONSTANT VARCHAR2(30) := 'NOTIFIED';
    --
    -- ���[�N�t���[������
    cv_wf_xxcso_approver_user_name    CONSTANT VARCHAR2(30) := 'XXCSO_APPROVER_USER_NAME';
    cv_wf_xxcso_ib_chk_errmsg         CONSTANT VARCHAR2(30) := 'XXCSO_IB_CHK_ERRMSG';
    cv_wf_xxcso_notification_id       CONSTANT VARCHAR2(30) := 'XXCSO_APPROVAL_NOTIFICATION_ID';
    --
    cv_wf_approver_user_name          CONSTANT VARCHAR2(30) := 'APPROVER_USER_NAME';
    --
    -- �g�[�N���p�萔
    --
    -- *** ���[�J���ϐ� ***
    lv_itemkey                  VARCHAR2(100);
    lv_token_value              VARCHAR2(60);
    lv_wf_approver_user_name    VARCHAR2(2000);
    ln_approval_s               NUMBER;
    --
    -- *** ���[�J����O ***
    wf_api_others_expt          EXCEPTION;
    --
    PRAGMA EXCEPTION_INIT( wf_api_others_expt, -20002 );
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    SELECT xxcso_approval_s01.NEXTVAL
    INTO   ln_approval_s
    FROM   DUAL;
    lv_itemkey := cv_wf_itemtype
                    || TO_CHAR( SYSDATE, 'YYYYMMDD' )
                    || TO_CHAR(ln_approval_s);

    -- ���F���[�U�����擾
    lv_wf_approver_user_name := WF_ENGINE.GetItemAttrText(
        itemtype => iv_itemtype
      , itemkey  => iv_itemkey
      , aname    => cv_wf_approver_user_name
      , ignore_notfound => TRUE
    );
    IF (lv_wf_approver_user_name IS NULL) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- ==========================
    -- ���[�N�t���[�v���Z�X����
    -- ==========================
    lv_token_value := cv_wf_pkg_name || cv_wf_createprocess;
    --
    WF_ENGINE.CREATEPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , process  => cv_wf_process
    );
    --
    -- ==========================
    -- ���[�N�t���[�����ݒ�
    -- ==========================
    --
    -- ���F���[�U
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_xxcso_approver_user_name
      , avalue   => lv_wf_approver_user_name
    );
    --
    -- �G���[���b�Z�[�W
    WF_ENGINE.SETITEMATTRTEXT(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_xxcso_ib_chk_errmsg
      , avalue   => iv_errmsg
    );
    --
    -- ==========================
    -- ���[�N�t���[�v���Z�X�N��
    -- ==========================
    --
    WF_ENGINE.STARTPROCESS(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
    );
    --
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
     -- *** OTHERS��O�n���h�� ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      --
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END start_approval_wf_proc;
/* 20090410_abe_T1_0108 END*/
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
      iv_itemtype            IN         VARCHAR2
    , iv_itemkey             IN         VARCHAR2
    , iv_process_kbn         IN         VARCHAR2  -- �����敪
    , ov_errbuf              OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W  --# �Œ� #
    , ov_retcode             OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h    --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'submain'; -- �v���V�[�W����
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
    cv_inp_chk_prg_name  CONSTANT VARCHAR2(30) := 'input_check';
    --
    -- *** ���[�J���ϐ� ***
    lv_requisition_number   po_requisition_headers.segment1%TYPE;    -- �����˗��ԍ�
    ld_process_date         DATE;                                    -- �Ɩ��������t
    ln_transaction_type_id  csi_txn_types.transaction_type_id%TYPE;  -- ����^�C�vID
    lv_errbuf2              VARCHAR2(5000);                          -- �G���[�E���b�Z�[�W
    lv_retcode2             VARCHAR2(1);                             -- ���^�[���E�R�[�h
/*20090403_yabuki_ST297 START*/
    ln_rec_count            NUMBER;                                  -- ���o����
/*20090403_yabuki_ST297 END*/
    --
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J���E���R�[�h ***
    l_ib_ext_attr_id_rec        g_ib_ext_attr_id_rtype;  -- IB�ǉ�����ID���
    l_requisition_rec           g_requisition_rtype;     -- �����˗����
    l_instance_rec              g_instance_rtype;        -- �������i�ݒu�p�j
    l_withdraw_instance_rec     g_instance_rtype;        -- �������i���g�p�j
    l_abolishment_instance_rec  g_instance_rtype;        -- �������i�p���p�j
    --
    -- *** ���[�J����O ***
    input_check_expt      EXCEPTION;  -- ���̓`�F�b�N�����G���[�n���h��
    reg_upd_process_expt  EXCEPTION;  -- �o�^�E�X�V�����G���[�n���h��
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    --
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
        iv_itemtype            => iv_itemtype
      , iv_itemkey             => iv_itemkey
      , iv_process_kbn         => iv_process_kbn          -- �����敪
      , ov_requisition_number  => lv_requisition_number   -- �����˗��ԍ�
      , od_process_date        => ld_process_date         -- �Ɩ��������t
      , on_transaction_type_id => ln_transaction_type_id  -- ����^�C�vID
      , o_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec    -- IB�ǉ�����ID���
      , ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W --# �Œ� #
      , ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h   --# �Œ� #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ========================================
    -- A-2. �����˗���񒊏o
    -- ========================================
    get_requisition_info(
        iv_requisition_number => lv_requisition_number  -- �����˗��ԍ�
      , id_process_date       => ld_process_date        -- �Ɩ��������t
/*20090403_yabuki_ST297 START*/
      , on_rec_count          => ln_rec_count           -- ���o����
/*20090403_yabuki_ST297 END*/
      , o_requisition_rec     => l_requisition_rec      -- �����˗����
      , ov_errbuf             => lv_errbuf              -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode            => lv_retcode             -- ���^�[���E�R�[�h    --# �Œ� #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- �G���[���b�Z�[�W������
    lv_errbuf := NULL;
    --
/*20090403_yabuki_ST297 START*/
    --------------------------------------------------
    -- A-2�ł̒��o������0���̏ꍇ
    --------------------------------------------------
    IF ( ln_rec_count = 0 )  THEN
      -- �ȍ~�̏������X�L�b�v���܂�
      RETURN;
      --
    END IF;
--    --------------------------------------------------
--    -- �J�e�S���敪��NULL�i�c��TM�ȊO�j�̏ꍇ
--    --------------------------------------------------
--    IF ( l_requisition_rec.category_kbn IS NULL )  THEN
--      -- �ȍ~�̏������X�L�b�v���܂�
--      RETURN;
--      --
--    END IF;
/*20090403_yabuki_ST297 END*/
    --
    -- ========================================
    -- �Z�[�u�|�C���g�ݒ�
    -- ========================================
    SAVEPOINT save_point;
    --
    ----------------------------------------------------------------------
    -- �����敪���u�����˗��\���v�̏ꍇ
    ----------------------------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
      --------------------------------------------------
      -- �J�e�S���敪���u�V��ݒu�v�̏ꍇ
      --------------------------------------------------
      IF ( l_requisition_rec.category_kbn = cv_category_kbn_new_install ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �@��R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_01  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�p�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- �ݒu��_�ڋq�R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_06  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ��Ɗ֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- ��Ɖ�ЃR�[�h
          , iv_work_location_code => l_requisition_rec.work_location_code  -- ���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                             -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                            -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-12. �ڋq�}�X�^���݃`�F�b�N����
        -- ========================================
        check_cust_mst(
            iv_account_number => l_requisition_rec.install_at_customer_code  -- �ڋq�R�[�h�i�ݒu��_�ڋq�R�[�h�j
/*20090427_yabuki_ST505_517 START*/
          , id_process_date          => ld_process_date                      -- �Ɩ��������t
          , iv_install_code          => NULL                                 -- �ݒu�p�����R�[�h
          , iv_withdraw_install_code => NULL                                 -- ���g�p�����R�[�h
          , in_owner_account_id      => NULL                                 -- �ݒu��A�J�E���gID
/*20090427_yabuki_ST505_517 END*/
          , ov_errbuf         => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�V���ցv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_replace ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �@��R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_01  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�p�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_05  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ��Ɗ֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_08  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , o_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6. ���g�p�������`�F�b�N����
        -- ========================================
        check_withdraw_ib_info(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , i_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. �����}�X�^���݃`�F�b�N����
        -- ========================================
        ----------------------------------------
        -- �`�F�b�N�ΏہF�ݒu��Ɖ�ЁA���Ə�
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- ��Ɖ�ЃR�[�h
          , iv_work_location_code => l_requisition_rec.work_location_code  -- ���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                             -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                            -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- �`�F�b�N�ΏہF���g��Ɖ�ЁA���Ə�
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.withdraw_company_code   -- ���g��ЃR�[�h
          , iv_work_location_code => l_requisition_rec.withdraw_location_code  -- ���g���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                                 -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                                -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. �ڋq�}�X�^���݃`�F�b�N����
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- �ڋq�R�[�h�i�ݒu��_�ڋq�R�[�h�j
          , id_process_date          => ld_process_date                             -- �Ɩ��������t
          , iv_install_code          => NULL                                        -- �ݒu�p�����R�[�h
          , iv_withdraw_install_code => l_requisition_rec.withdraw_install_code     -- ���g�p�����R�[�h
          , in_owner_account_id      => l_withdraw_instance_rec.owner_account_id    -- �ݒu��A�J�E���gID
          , ov_errbuf                => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode               => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
        --
        -- ========================================
        -- A-15. ���g�p�����X�V����
        -- ========================================
        update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn           -- �����敪
          , i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
--            i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec        -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id   -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u����ݒu�v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_install ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �ݒu�p_�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_02  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�p�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- �ݒu��_�ڋq�R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_06  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ��Ɗ֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , o_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-5. �ݒu�p�������`�F�b�N����
        -- ========================================
        check_ib_info(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , i_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090413_yabuki_ST198 START*/
        -- ���[�X�敪���u���Ѓ��[�X�v�̏ꍇ
        IF ( l_instance_rec.lease_kbn = cv_own_company_lease ) THEN
/*20090413_yabuki_ST198 END*/
          -- ========================================
          -- A-10. ���[�X�����X�e�[�^�X�`�F�b�N����
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_01           -- �`�F�b�N�敪�i�`�F�b�N�ΏہF�ݒu�p�����j
            , iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
            , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
            , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
/*20090413_yabuki_ST198 START*/
        END IF;
/*20090413_yabuki_ST198 END*/
        --
        -- ========================================
        -- A-11. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- ��Ɖ�ЃR�[�h
          , iv_work_location_code => l_requisition_rec.work_location_code  -- ���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                             -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                            -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-12. �ڋq�}�X�^���݃`�F�b�N����
        -- ========================================
        check_cust_mst(
            iv_account_number => l_requisition_rec.install_at_customer_code  -- �ڋq�R�[�h�i�ݒu��_�ڋq�R�[�h�j
/*20090427_yabuki_ST505_517 START*/
          , id_process_date          => ld_process_date                      -- �Ɩ��������t
          , iv_install_code          => NULL                                 -- �ݒu�p�����R�[�h
          , iv_withdraw_install_code => NULL                                 -- ���g�p�����R�[�h
          , in_owner_account_id      => NULL                                 -- �ݒu��A�J�E���gID
/*20090427_yabuki_ST505_517 END*/
          , ov_errbuf         => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-13. �ݒu�p�����X�V����
        -- ========================================
        update_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn          -- �����敪
          , i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
--            i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec       -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id  -- ����^�C�vID
          , ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�����ցv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_replace ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �ݒu�p_�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_02  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�p�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_05  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ��Ɗ֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_08  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        ----------------------------------------
        -- �`�F�b�N�ΏہF�ݒu�p����
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , o_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- �`�F�b�N�ΏہF���g�p����
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , o_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-5. �ݒu�p�������`�F�b�N����
        -- ========================================
        check_ib_info(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , i_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6. ���g�p�������`�F�b�N����
        -- ========================================
        check_withdraw_ib_info(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , i_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090413_yabuki_ST198 START*/
        -- ���[�X�敪���u���Ѓ��[�X�v�̏ꍇ
        IF ( l_instance_rec.lease_kbn = cv_own_company_lease ) THEN
/*20090413_yabuki_ST198 END*/
          -- ========================================
          -- A-10. ���[�X�����X�e�[�^�X�`�F�b�N����
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_01           -- �`�F�b�N�敪�i�`�F�b�N�ΏہF�ݒu�p�����j
            , iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
            , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
            , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
/*20090413_yabuki_ST198 START*/
        END IF;
/*20090413_yabuki_ST198 END*/
        --
        -- ========================================
        -- A-11. �����}�X�^���݃`�F�b�N����
        -- ========================================
        ----------------------------------------
        -- �`�F�b�N�ΏہF�ݒu��Ɖ�ЁA���Ə�
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- ��Ɖ�ЃR�[�h
          , iv_work_location_code => l_requisition_rec.work_location_code  -- ���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                             -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                            -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- �`�F�b�N�ΏہF���g��Ɖ�ЁA���Ə�
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.withdraw_company_code   -- ���g��ЃR�[�h
          , iv_work_location_code => l_requisition_rec.withdraw_location_code  -- ���g���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                                 -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                                -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. �ڋq�}�X�^���݃`�F�b�N����
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- �ڋq�R�[�h�i�ݒu��_�ڋq�R�[�h�j
          , id_process_date          => ld_process_date                             -- �Ɩ��������t
          , iv_install_code          => NULL                                        -- �ݒu�p�����R�[�h
          , iv_withdraw_install_code => l_requisition_rec.withdraw_install_code     -- ���g�p�����R�[�h
          , in_owner_account_id      => l_withdraw_instance_rec.owner_account_id    -- �ݒu��A�J�E���gID
          , ov_errbuf                => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode               => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
        --
        -- ========================================
        -- A-13. �ݒu�p�����X�V����
        -- ========================================
        update_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn          -- �����敪
          , i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
--            i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec       -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id  -- ����^�C�vID
          , ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. ���g�p�����X�V����
        -- ========================================
        update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn           -- �����敪
          , i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
--            i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec        -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id   -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u���g�v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_withdraw ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �ݒu�p_�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_03  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�p�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_05  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
/*20090413_yabuki_ST170_171 START*/
            iv_chk_kbn        => cv_input_chk_kbn_10  -- �`�F�b�N�敪
--            iv_chk_kbn        => cv_input_chk_kbn_08  -- �`�F�b�N�敪
/*20090413_yabuki_ST170_171 END*/
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , o_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6. ���g�p�������`�F�b�N����
        -- ========================================
        check_withdraw_ib_info(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , i_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. �����}�X�^���݃`�F�b�N����
        -- ========================================
/*20090413_yabuki_ST527 START*/
--        ----------------------------------------
--        -- �`�F�b�N�ΏہF�ݒu��Ɖ�ЁA���Ə�
--        ----------------------------------------
--        check_syozoku_mst(
--            iv_work_company_code  => l_requisition_rec.work_company_code   -- ��Ɖ�ЃR�[�h
--          , iv_work_location_code => l_requisition_rec.work_location_code  -- ���Ə��R�[�h
--          , ov_errbuf             => lv_errbuf                             -- �G���[�E���b�Z�[�W  --# �Œ� #
--          , ov_retcode            => lv_retcode                            -- ���^�[���E�R�[�h    --# �Œ� #
--        );
--        --
--        IF ( lv_retcode <> cv_status_normal ) THEN
--          RAISE global_process_expt;
--          --
--        END IF;
/*20090413_yabuki_ST527 END*/
        --
        ----------------------------------------
        -- �`�F�b�N�ΏہF���g��Ɖ�ЁA���Ə�
        ----------------------------------------
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.withdraw_company_code   -- ���g��ЃR�[�h
          , iv_work_location_code => l_requisition_rec.withdraw_location_code  -- ���g���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                                 -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                                -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. �ڋq�}�X�^���݃`�F�b�N����
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- �ڋq�R�[�h�i�ݒu��_�ڋq�R�[�h�j
          , id_process_date          => ld_process_date                             -- �Ɩ��������t
          , iv_install_code          => NULL                                        -- �ݒu�p�����R�[�h
          , iv_withdraw_install_code => l_requisition_rec.withdraw_install_code     -- ���g�p�����R�[�h
          , in_owner_account_id      => l_withdraw_instance_rec.owner_account_id    -- �ݒu��A�J�E���gID
          , ov_errbuf                => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode               => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
        --
        -- ========================================
        -- A-15. ���g�p�����X�V����
        -- ========================================
        update_withdraw_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn           -- �����敪
          , i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
--            i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec        -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id   -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�p���\���v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_appl ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �ݒu�p_�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_03  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- ���g�p�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- �p��_�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_09  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-7. �p���\���p�������`�F�b�N����
        -- ========================================
        check_ablsh_appl_ib_info(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , i_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-16. �p���\���p�����X�V����
        -- ========================================
        update_abo_appl_ib_info(
            iv_process_kbn         => iv_process_kbn              -- �����敪
          , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
          , i_requisition_rec      => l_requisition_rec           -- �����˗����
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
          , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�p�����فv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_dcsn ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �ݒu�p_�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_03  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�p�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- �p��_�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_09  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-8. �p�����ٗp�������`�F�b�N����
        -- ========================================
        check_ablsh_aprv_ib_info(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , i_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-10. ���[�X�����X�e�[�^�X�`�F�b�N����
        -- ========================================
        check_object_status(
            iv_chk_kbn      => cv_obj_sts_chk_kbn_02                       -- �`�F�b�N�敪�i�`�F�b�N�ΏہF�p���p�����j
          , iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-17. �p�����ٗp�����X�V����
        -- ========================================
        update_abo_aprv_ib_info(
            iv_process_kbn         => iv_process_kbn              -- �����敪
          , id_process_date        => ld_process_date             -- �Ɩ��������t
          , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
          , i_requisition_rec      => l_requisition_rec           -- �����˗����
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
          , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�X���ړ��v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_mvmt_in_shp ) THEN
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �ݒu�p_�����R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_02  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := lv_errbuf2;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ���g�p�����R�[�h���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_04  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        ------------------------------
        -- ��Ɗ֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_07  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          , ov_errbuf         => lv_errbuf2           -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode2          -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF ( lv_retcode2 <> cv_status_normal ) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF ( lv_retcode2 = cv_status_error ) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ���̓`�F�b�N�������x���I���i�`�F�b�N�G���[����j�̏ꍇ
        IF ( lv_retcode = cv_status_warn ) THEN
          -- ���^�[���R�[�h�Ɂu�ُ�v��ݒ�
          ov_retcode := cv_status_error;
          RAISE input_check_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , o_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-9. �X���ړ��p�������`�F�b�N����
        -- ========================================
        check_mvmt_in_shp_ib_info(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , i_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-11. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_syozoku_mst(
            iv_work_company_code  => l_requisition_rec.work_company_code   -- ��Ɖ�ЃR�[�h
          , iv_work_location_code => l_requisition_rec.work_location_code  -- ���Ə��R�[�h
          , ov_errbuf             => lv_errbuf                             -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                            -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 START*/
        --
        -- ========================================
        -- A-12. �ڋq�}�X�^���݃`�F�b�N����
        -- ========================================
        check_cust_mst(
            iv_account_number        => l_requisition_rec.install_at_customer_code  -- �ڋq�R�[�h�i�ݒu��_�ڋq�R�[�h�j
          , id_process_date          => ld_process_date                             -- �Ɩ��������t
          , iv_install_code          => l_requisition_rec.install_code              -- �ݒu�p�����R�[�h
          , iv_withdraw_install_code => NULL                                        -- ���g�p�����R�[�h
          , in_owner_account_id      => l_instance_rec.owner_account_id             -- �ݒu��A�J�E���gID
          , ov_errbuf                => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode               => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/*20090427_yabuki_ST505_517 END*/
        --
        -- ========================================
        -- A-13. �ݒu�p�����X�V����
        -- ========================================
        update_ib_info(
/*20090416_yabuki_ST398 START*/
            iv_process_kbn         => iv_process_kbn          -- �����敪
          , i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
--            i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
/*20090416_yabuki_ST398 END*/
          , i_requisition_rec      => l_requisition_rec       -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id  -- ����^�C�vID
          , ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
      --
    ----------------------------------------------------------------------
    -- �����敪���u�����˗����F�v�̏ꍇ
    ----------------------------------------------------------------------
    ELSIF ( iv_process_kbn = cv_proc_kbn_req_aprv ) THEN
      --------------------------------------------------
      -- �J�e�S���敪���u�p���\���v�̏ꍇ
      --------------------------------------------------
      IF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_appl ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-16. �p���\���p�����X�V����
        -- ========================================
        update_abo_appl_ib_info(
            iv_process_kbn         => iv_process_kbn              -- �����敪
          , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
          , i_requisition_rec      => l_requisition_rec           -- �����˗����
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
          , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�p�����فv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_dcsn ) THEN
        --
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-17. �p�����ٗp�����X�V����
        -- ========================================
        update_abo_aprv_ib_info(
            iv_process_kbn         => iv_process_kbn              -- �����敪
          , id_process_date        => ld_process_date             -- �Ɩ��������t
          , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
          , i_requisition_rec      => l_requisition_rec           -- �����˗����
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
          , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
      --
/*20090406_yabuki_ST101 START*/
      -- ========================================
      -- A-18. ��ƈ˗��^�������A�g�Ώۃe�[�u�����݃`�F�b�N����
      -- ========================================
      chk_wk_req_proc(
          i_requisition_rec => l_requisition_rec  -- �����˗����
        , on_rec_count      => ln_rec_count       -- ���R�[�h�����i��ƈ˗��^�������A�g�Ώۃe�[�u���j
        , ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W  --# �Œ� #
        , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h    --# �Œ� #
      );
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE reg_upd_process_expt;
        --
      END IF;
      --
      -- ��ƈ˗��^�������A�g�Ώۃe�[�u���ɊY�����郌�R�[�h�����݂��Ȃ��ꍇ
      IF ( ln_rec_count = cn_zero ) THEN
        -- ========================================
        -- A-19. ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����
        -- ========================================
--        -- ========================================
--        -- A-18. ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����
--        -- ========================================
/*20090406_yabuki_ST101 END*/
        insert_wk_req_proc(
            i_requisition_rec => l_requisition_rec  -- �����˗����
          , ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
/*20090406_yabuki_ST101 START*/
      ELSE
        -- ========================================
        -- A-20. ��ƈ˗��^�������A�g�Ώۃe�[�u���X�V����
        -- ========================================
        update_wk_req_proc(
            i_requisition_rec => l_requisition_rec  -- �����˗����
          , ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
      --
/*20090406_yabuki_ST101 END*/
      --
/*20090416_yabuki_ST398 START*/
    ----------------------------------------------------------------------
    -- �����敪���u�����˗��۔F�v�̏ꍇ
    ----------------------------------------------------------------------
    ELSIF ( iv_process_kbn = cv_proc_kbn_req_dngtn ) THEN
      --------------------------------------------------
      -- �J�e�S���敪���u�V��ݒu�v�̏ꍇ
      --------------------------------------------------
      IF ( l_requisition_rec.category_kbn = cv_category_kbn_new_install ) THEN
        NULL;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�V���ցv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_replace ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , o_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. ���g�p�����X�V����
        -- ========================================
        update_withdraw_ib_info(
            iv_process_kbn         => iv_process_kbn           -- �����敪
          , i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
          , i_requisition_rec      => l_requisition_rec        -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id   -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u����ݒu�v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_install ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , o_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-13. �ݒu�p�����X�V����
        -- ========================================
        update_ib_info(
            iv_process_kbn         => iv_process_kbn          -- �����敪
          , i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
          , i_requisition_rec      => l_requisition_rec       -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id  -- ����^�C�vID
          , ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�����ցv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_old_replace ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        ----------------------------------------
        -- �`�F�b�N�ΏہF�ݒu�p����
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , o_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        ----------------------------------------
        -- �`�F�b�N�ΏہF���g�p����
        ----------------------------------------
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , o_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-13. �ݒu�p�����X�V����
        -- ========================================
        update_ib_info(
            iv_process_kbn         => iv_process_kbn          -- �����敪
          , i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
          , i_requisition_rec      => l_requisition_rec       -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id  -- ����^�C�vID
          , ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. ���g�p�����X�V����
        -- ========================================
        update_withdraw_ib_info(
            iv_process_kbn         => iv_process_kbn           -- �����敪
          , i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
          , i_requisition_rec      => l_requisition_rec        -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id   -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u���g�v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_withdraw ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.withdraw_install_code  -- ���g�p�����R�[�h
          , o_instance_rec  => l_withdraw_instance_rec                  -- �������i���g�p�j
          , ov_errbuf       => lv_errbuf                                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-15. ���g�p�����X�V����
        -- ========================================
        update_withdraw_ib_info(
            iv_process_kbn         => iv_process_kbn           -- �����敪
          , i_instance_rec         => l_withdraw_instance_rec  -- �������i���g�p�j
          , i_requisition_rec      => l_requisition_rec        -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id   -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode               -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�p���\���v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_appl ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-16. �p���\���p�����X�V����
        -- ========================================
        update_abo_appl_ib_info(
            iv_process_kbn         => iv_process_kbn              -- �����敪
          , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
          , i_requisition_rec      => l_requisition_rec           -- �����˗����
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
          , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�p�����فv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_dcsn ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
          , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-17. �p�����ٗp�����X�V����
        -- ========================================
        update_abo_aprv_ib_info(
            iv_process_kbn         => iv_process_kbn              -- �����敪
          , id_process_date        => ld_process_date             -- �Ɩ��������t
          , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
          , i_requisition_rec      => l_requisition_rec           -- �����˗����
          , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
          , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
          , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      --------------------------------------------------
      -- �J�e�S���敪���u�X���ړ��v�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_mvmt_in_shp ) THEN
        -- ========================================
        -- A-4. �����}�X�^���݃`�F�b�N����
        -- ========================================
        check_ib_existence(
            iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
          , o_instance_rec  => l_instance_rec                  -- �������i�ݒu�p�j
          , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-13. �ݒu�p�����X�V����
        -- ========================================
        update_ib_info(
            iv_process_kbn         => iv_process_kbn          -- �����敪
          , i_instance_rec         => l_instance_rec          -- �������i�ݒu�p�j
          , i_requisition_rec      => l_requisition_rec       -- �����˗����
          , in_transaction_type_id => ln_transaction_type_id  -- ����^�C�vID
          , ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
/*20090416_yabuki_ST398 END*/
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN input_check_expt THEN
      -- *** ���̓`�F�b�N�����G���[�n���h�� ***
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_inp_chk_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN reg_upd_process_expt THEN
      -- *** �o�^�E�X�V�����G���[�n���h�� ***
      ROLLBACK TO save_point;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --#################################  �Œ��O������ START   ####################################
    --
    WHEN global_process_expt THEN
      -- *** ���������ʗ�O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
      --
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    --
    --#####################################  �Œ蕔 END   ##########################################
    --
  END submain;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main_for_application
   * Description      : ���C�������i�����˗��\���p�j
   **********************************************************************************/
  --
  PROCEDURE main_for_application(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  )
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'main_for_application';  -- �v���O������
    cv_ib_chk_errmsg  CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_ERRMSG';
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
  BEGIN
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        iv_itemtype    => itemtype
      , iv_itemkey     => itemkey
      , iv_process_kbn => cv_proc_kbn_req_appl  -- �����敪�i�����˗��\���j
      , ov_errbuf      => lv_errbuf             -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode     => lv_retcode            -- ���^�[���E�R�[�h    --# �Œ� #
    );
    --
    -- submain������I���̏ꍇ
    IF lv_retcode = cv_status_normal THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_yes;
      --
    -- submain���ُ�I���̏ꍇ
    ELSIF lv_retcode = cv_status_error THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
  END main_for_application;
  --
  --
  /**********************************************************************************
   * Procedure Name   : main_for_approval
   * Description      : ���C�������i�����˗����F�p�j
   **********************************************************************************/
  --
  PROCEDURE main_for_approval(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  )
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'main_for_approval';  -- �v���O������
    cv_ib_chk_errmsg  CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_ERRMSG';
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf         VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode        VARCHAR2(1);     -- ���^�[���E�R�[�h
    /* 20090410_abe_T1_0108 START*/
    lv_errbuf_wf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    ln_notification_id NUMBER;
    /* 20090410_abe_T1_0108 END*/
    --
  BEGIN
    --
    /* 20090410_abe_T1_0108 START*/
    -- ������N������邽�߁A�ʒmID���擾�ł��Ȃ��ꍇ�͏I������B
    BEGIN
      SELECT wias.notification_id
      INTO   ln_notification_id
      FROM   wf_item_activity_statuses wias
      WHERE  wias.item_type = itemtype
      AND    wias.item_key  = itemkey
      AND    wias.notification_id IS NOT NULL;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    /* 20090410_abe_T1_0108 END*/
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        iv_itemtype    => itemtype
      , iv_itemkey     => itemkey
      , iv_process_kbn => cv_proc_kbn_req_aprv  -- �����敪�i�����˗����F�j
      , ov_errbuf      => lv_errbuf             -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode     => lv_retcode            -- ���^�[���E�R�[�h    --# �Œ� #
    );
    --
    -- submain������I���̏ꍇ
    IF lv_retcode = cv_status_normal THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_yes;
      --
    -- submain���ُ�I���̏ꍇ
    ELSIF lv_retcode = cv_status_error THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      /* 20090410_abe_T1_0108 START*/
      --
      lv_errbuf_wf := lv_errbuf;
      -- ========================================
      -- A-21. ���F���[�N�t���[�N��(�G���[�ʒm)
      -- ========================================
      start_approval_wf_proc(
        iv_itemtype    => itemtype
      , iv_itemkey     => itemkey
      , iv_errmsg      => lv_errbuf_wf          -- �G���[���b�Z�[�W
      , ov_errbuf      => lv_errbuf             -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode     => lv_retcode            -- ���^�[���E�R�[�h    --# �Œ� #
      );
      /* 20090410_abe_T1_0108 END*/
      --
    END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
  END main_for_approval;
  --
  --
/*20090416_yabuki_ST398 START*/
  /**********************************************************************************
   * Procedure Name   : main_for_denegation
   * Description      : ���C�������i�����˗��۔F�p�j
   **********************************************************************************/
  --
  PROCEDURE main_for_denegation(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  )
  --
  IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'main_for_denegation';  -- �v���O������
    cv_ib_chk_errmsg  CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_ERRMSG';
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode          VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errbuf_wf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    ln_notification_id  NUMBER;
    --
  BEGIN
    --
    -- ������N������邽�߁A�ʒmID���擾�ł��Ȃ��ꍇ�͏I������B
    BEGIN
      SELECT wias.notification_id
      INTO   ln_notification_id
      FROM   wf_item_activity_statuses wias
      WHERE  wias.item_type = itemtype
      AND    wias.item_key  = itemkey
      AND    wias.notification_id IS NOT NULL;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
        iv_itemtype    => itemtype
      , iv_itemkey     => itemkey
      , iv_process_kbn => cv_proc_kbn_req_dngtn  -- �����敪�i�����˗��۔F�j
      , ov_errbuf      => lv_errbuf              -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode     => lv_retcode             -- ���^�[���E�R�[�h    --# �Œ� #
    );
    --
    -- submain������I���̏ꍇ
    IF lv_retcode = cv_status_normal THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_yes;
      --
    -- submain���ُ�I���̏ꍇ
    ELSIF lv_retcode = cv_status_error THEN
      resultout   := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
      lv_errbuf_wf := lv_errbuf;
      -- ========================================
      -- A-21. ���F���[�N�t���[�N��(�G���[�ʒm)
      -- ========================================
      start_approval_wf_proc(
        iv_itemtype => itemtype
      , iv_itemkey  => itemkey
      , iv_errmsg   => lv_errbuf_wf    -- �G���[���b�Z�[�W
      , ov_errbuf   => lv_errbuf       -- �G���[�E���b�Z�[�W  --# �Œ� #
      , ov_retcode  => lv_retcode      -- ���^�[���E�R�[�h    --# �Œ� #
      );
      --
    END IF;
--
  EXCEPTION
    WHEN global_api_others_expt THEN
      -- *** ���ʊ֐�OTHERS��O�n���h�� ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
    WHEN OTHERS THEN
      -- *** OTHERS��O�n���h�� ***
      resultout := wf_engine.eng_completed || cv_msg_part_only || cv_result_no;
      lv_errbuf := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      --
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_errmsg
        , avalue   => lv_errbuf
      );
      --
  END main_for_denegation;
/*20090416_yabuki_ST398 END*/
--
END XXCSO011A01C;
/
