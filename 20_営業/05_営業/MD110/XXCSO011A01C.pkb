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
 * Version          : 1.38
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                      ��������(A-1)
 *  get_requisition_info      �����˗���񒊏o(A-2)
 *  input_check               ���̓`�F�b�N����(A-3)
 *  check_ib_existence        �����}�X�^���݃`�F�b�N����(A-4)
 *  chk_authorization_status  �w���˗��X�e�[�^�X�`�F�b�N����(A-5-0)
 *  check_ib_info             �ݒu�p�������`�F�b�N����(A-5)
 *  check_withdraw_ib_info    ���g�p�������`�F�b�N����(A-6)
 *  check_ablsh_appl_ib_info  �p���\���p�������`�F�b�N����(A-7)
 *  check_ablsh_aprv_ib_info  �p�����ٗp�������`�F�b�N����(A-8)
 *  check_mvmt_in_shp_ib_info �X���ړ��p�������`�F�b�N����(A-9)
 *  check_object_status       �����X�e�[�^�X�`�F�b�N����(A-10)
 *  check_syozoku_mst         �����}�X�^���݃`�F�b�N����(A-11)
 *  check_cust_mst            �ڋq�}�X�^���݃`�F�b�N����(A-12)
 *  check_dclr_place_mst      �\���n�}�X�^���݃`�F�b�N����(A-27)
 *  lock_ib_info              �������b�N����(A-13)
 *  update_ib_info            �ݒu�p�����X�V����(A-14)
 *  update_withdraw_ib_info   ���g�p�����X�V����(A-15)
 *  update_abo_appl_ib_info   �p���\���p�����X�V����(A-16)
 *  update_abo_aprv_ib_info   �p�����ٗp�����X�V����(A-17)
 *  chk_wk_req_proc           ��ƈ˗��^�������A�g�Ώۃe�[�u�����݃`�F�b�N����(A-18)
 *  insert_wk_req_proc        ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����(A-19)
 *  update_wk_req_proc        ��ƈ˗��^�������A�g�Ώۃe�[�u���X�V����(A-20)
 *  start_approval_wf_proc    ���F���[�N�t���[�N��(�G���[�ʒm)(A-21)
 *  verifyauthority           ���F�Ҍ����i���i�j�`�F�b�N(A-22)
 *  update_po_req_line        �����˗����׍X�V����(A-23)
 *  check_maker_code          ���[�J�[�R�[�h�`�F�b�N����(A-24)
 *  check_business_low_type   �Ƒ�(������)�`�F�b�N����(A-25)
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
 *  2009-05-11    1.10  D.Abe            �yST��Q�Ή�965�z�p���\�����̋@���ԂR�A�p���t���O�X�V�����̃^�C�~���O�ύX
 *  2009-05-15    1.11  D.Abe            �yST��Q�Ή�669�z���F�Ҍ����i���i�j�`�F�b�N��ǉ�
 *  2009-07-01    1.12  D.Abe            �yST��Q�Ή�529�z�������ׂ̎���������X�V����悤�ɕύX
 *  2009-07-08    1.13  D.Abe            �y0000464�z�i�ڃJ�e�S���Ƌ@��R�[�h�̃��[�J�[�`�F�b�N��ǉ�
 *  2009-07-14    1.14  K.Satomura       �y0000476�z�@���ԂQ�̌̏ᒆ��4����9�֕ύX
 *  2009-07-16    1.15  K.Hosoi          �y0000375,0000419�z
 *  2009-08-10    1.16  K.Satomura       �y0000662�z�ڋq�S���c�ƈ����݃`�F�b�N���R�����g�A�E�g
 *  2009-09-10    1.17  K.Satomura       �y0001335�z�ڋq�`�F�b�N���ڋq�敪�ɂ���ĕύX����悤�C��
 *  2009-11-25    1.18  K.Satomura       �yE_�{�ғ�_00027�zMC�AMC�����G���[�Ƃ���悤�C��
 *  2009-11-30    1.19  K.Satomura       �yE_�{�ғ�_00204�z��Ɗ�]���̃`�F�b�N���ꎞ�I�ɊO��
 *  2009-11-30    1.20  T.Maruyama       �yE_�{�ғ�_00119�z�`�F�b�N�����Ή�
 *  2009-12-07    1.21  K.Satomura       �yE_�{�ғ�_00336�zE_�{�ғ�_00204�̑Ή������ɖ߂�
 *  2009-12-09    1.22  K.Satomura       �yE_�{�ғ�_00341�z���F���̃`�F�b�N��\�����̃`�F�b�N�Ɠ��l�ɂ���
 *  2009-12-16    1.23  D.Abe            �yE_�{�ғ�_00354�z�p�����ςŃ��[�X�������݃`�F�b�N�Ή�
 *                                       �yE_�{�ғ�_00498�z���[�X�����X�e�[�^�X�́u�ă��[�X�҂��v�Ή�
 *  2009-12-24    1.24  D.Abe            �yE_�{�ғ�_00563�z�b��Ή��i�@��R�[�h�A���[�J�[�R�[�h�̓��t�������폜�j
 *  2009-12-24    1.25  K.Hosoi          �yE_�{�ғ�_00563�z�ݒu��ڋq���A�ݒu��_�X�֔ԍ��A�ݒu��s���{���A�ݒu��s��A
 *                                        �ݒu��Z���P�A�ݒu��Z���Q�A�ݒu��d�b�ԍ��A�ݒu��S���Җ������͂���Ă���ꍇ
 *                                        �������̃`�F�b�N���s���悤������ǉ��B
 *                                        �����\�`�F�b�N�̒ǉ��B
 *  2010-01-25    1.26  K.Hosoi          �yE_�{�ғ�_00533,00319�z��ƈ˗����t���O��Y�ɂ���ہA���킹�čw���˗��ԍ�/�ڋqCD
 *                                        ��ATTRIBUTE8�ɐݒ肷�鏈����ǉ��B�܂��A�ڋq�̋Ƒԏ����ނ�24�`27�ȊO���A�ڋq��
 *                                        �ڋq�敪��10�Ŋ��A�@��̋@��敪�����̋@�̏ꍇ�ɂ͍w���˗������{�ł��Ȃ��悤��
 *                                        �C���B
 *  2010-03-08    1.27  K.Hosoi          �yE_�{�ғ�_01838,01839�z
 *                                        �E��ƈ˗����t���O���uY�v�̈˗����A�u���߁v�u����v�̏ꍇ�͐\���\�ƂȂ�悤�C��
 *                                        �E�V���ց^�����ց^���g�̏ꍇ�ɁA���g��i������j�Ó����`�F�b�N��ǉ�
 *                                        �E��Ɖ��CD�Ó����`�F�b�N��ǉ�
 *                                        �E��Ɗ�]���Ó����`�F�b�N��ǉ��B
 *  2010-04-01    1.28  T.maruyama       �yE_�{�ғ�_02133�z
 *                                        �E�Ƒԏ����ނƋ@��̃`�F�b�N�̍ہA�����Ƃ̏ꍇ��iPro�ŋ@��CD����͂��Ȃ�����
 *                                          �ݒu����CD����IB�̋@��CD���擾���Ďg�p����悤�ύX�B
 *                                        �E��Ɗ�]���`�F�b�N�̍ۂɁA�`�F�b�N���Ă�����t���o�͂���悤���O�ǉ��B
 *  2010-04-19    1.29  T.Maruyama       �yE_�{�ғ�_02251�z��Ɗ�]���`�F�b�N�Ŏg�p����J�����_���v���t�@�C���Ǘ�����p�ύX�B
 *  2010-07-29    1.30  M.Watanabe       �yE_�{�ғ�_03239�z
 *                                        �EVD�w���˗�����3�c�Ɠ����[����V��ݒu�^�V���ւ̏ꍇ�Ƀ`�F�b�N����悤�����ǉ��B
 *                                          (���̓`�F�b�N�敪=07 ��Ɗ֘A�����̓`�F�b�N)
 *                                        �E���g�̏ꍇ�Ƀ`�F�b�N���Ă���VD�w���˗�����3�c�Ɠ����[�����R�����g�A�E�g�B
 *                                          (���̓`�F�b�N�敪=10 ���g�֘A�����̓`�F�b�N2)
 *  2010-12-07    1.31 K.Kiriu           �yE_�{�ғ�_05751�z
 *                                        �E�p�����َ��̋@���ԂR�̃`�F�b�N���uNULL�A�\�薳���A�p���\��ȊO�̏ꍇ�G���[�v�ɕύX
 *  2013-04-04    1.32 T.Ishiwata        �yE_�{�ғ�_10321�z
 *                                        �E�V��ݒu�A�V���ւ̂Ƃ���APPS_SOURCE_CODE��NULL���ǂ����`�F�b�N����悤�ɕύX
 *  2013-12-05    1.33 T.Nakano          �yE_�{�ғ�_11082�z
 *                                        �E���̋@�A�V���[�P�[�X�p�����ϐ\���`�F�b�N��ǉ�
 *  2014-04-30    1.34 T.Nakano          �yE_�{�ғ�_11770�z
 *                                        �E���̋@�A�V���[�P�[�X�p�����ϐ\���`�F�b�N�̏����ύX
 *  2014-05-13    1.35 K.Nakamura        �yE_�{�ғ�_11853�z�x���_�[�w���Ή�
 *  2014-08-29    1.36 S.Yamashita       �yE_�{�ғ�_11719�z�x���_�[�w���Ή�(PH2)
 *  2014-12-15    1.37 K.Kanada          �yE_�{�ғ�_12775�z�p�����ق̏����ύX
 *  2015-01-13    1.38 T.Sano            �yE_�{�ғ�_12289�z�Ή�����E�S�����_�Ó����`�F�b�N��ǉ� 
 *
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
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
  gv_requisition_number po_requisition_headers.segment1%type;
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
/* 20090511_abe_ST965 START*/
  cv_tkn_number_52  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00193';  -- �������[�N�e�[�u���̋@���ԕs��
/* 20090511_abe_ST965 END*/
/* 20090701_abe_ST529 START*/
  cv_tkn_number_53  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00576';  -- �����˗����׍X�V�G���[
/* 20090701_abe_ST529 END*/
/* 20090708_abe_0000464 START*/
  cv_tkn_number_54  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00577';  -- ���[�J�[�R�[�h���݃`�F�b�N�G���[
/* 20090708_abe_0000464 END*/
  /* 2009.09.10 K.Satomura 0001335�Ή� START */
  cv_tkn_number_55  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00579';  -- �ڋq�X�e�[�^�X�`�F�b�N�G���[���b�Z�[�W
  /* 2009.09.10 K.Satomura 0001335�Ή� END */
  /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
  cv_tkn_number_56  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00582';  -- ��Ɗ�]���Ó����`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_57  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00583';  -- �����`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_58  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00584';  -- ��Ɖ�Ѓ��[�J�[�`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_59  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00585';  -- ���g����͕s�`�F�b�N�G���[���b�Z�[�W
  /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
  cv_tkn_number_60  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00588';  -- �������˗��G���[���b�Z�[�W
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
  /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
  cv_tkn_number_61  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- �f�[�^���o�G���[���b�Z�[�W
  cv_tkn_number_62  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00592';  -- �Ƒ�(������)�`�F�b�N�G���[���b�Z�[�W
  /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
  /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
  cv_tkn_number_63  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00598';  -- ���g��(������)�Ó����`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_64  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00599';  -- ��Ɖ�БÓ����`�F�b�N�G���[���b�Z�[�W
  cv_tkn_number_65  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00600';  -- ��Ɗ�]���Ó����`�F�b�N�G���[���b�Z�[�W
  /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
  /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� START */
  cv_tkn_number_66  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00647';  -- �A�v���P�[�V�����\�[�X�R�[�h�`�F�b�N�G���[���b�Z�[�W
  /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� END   */
  /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
  cv_tkn_number_67  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00657';  -- �p�����ϐ\���`�F�b�N�G���[
  cv_tkn_number_68  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00658';  -- ���p�`�F�b�N�f�[�^���o�G���[
  cv_tkn_number_69  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00659';  -- ���b�Z�[�W�p������(���[�X�_����)
  cv_tkn_number_70  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00660';  -- ���b�Z�[�W�p������(���p��)
  /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
  /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
  cv_tkn_number_71  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- �v���t�@�C���擾�G���[
  cv_tkn_number_72  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- ���݃G���[
  cv_tkn_number_73  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00055';  -- �f�[�^���o�G���[
  cv_tkn_number_74  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- ���b�Z�[�W�p������(�\���n)
  cv_tkn_number_75  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00663';  -- ���b�Z�[�W�p������(�\���n�}�X�^)
  cv_tkn_number_76  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00545';  -- �Q�ƃ^�C�v���e�擾�G���[���b�Z�[�W
  /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
  /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
  cv_tkn_number_77  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00717';  -- �Q�ƃ^�C�v���e�擾�G���[���b�Z�[�W
  /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
/* 20090511_abe_ST965 START*/
  cv_tkn_hazard_state1    CONSTANT VARCHAR2(20) := 'HAZARD_STATE1';
  cv_tkn_hazard_state2    CONSTANT VARCHAR2(20) := 'HAZARD_STATE2';
  cv_tkn_hazard_state3    CONSTANT VARCHAR2(20) := 'HAZARD_STATE3';
  /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
  cv_tkn_colname        CONSTANT VARCHAR2(20) := 'COLNAME';
  cv_tkn_format         CONSTANT VARCHAR2(20) := 'FORMAT';
  /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */  
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
  cv_tkn_sagyo          CONSTANT VARCHAR(20)  := 'SAGYO';
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
  /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
  cv_tkn_base_val       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_kisyucd        CONSTANT VARCHAR2(20) := 'KISYUCD';
  /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
  /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
  cv_tkn_prefix         CONSTANT VARCHAR2(20) := 'PREFIX';
  cv_tkn_prefix1        CONSTANT VARCHAR2(20) := 'PREFIX1';
  cv_tkn_prefix2        CONSTANT VARCHAR2(20) := 'PREFIX2';
  cv_tkn_date           CONSTANT VARCHAR2(20) := 'DATE';
  /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
  /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
  cv_tkn_base_value       CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_prof_name        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_lookup_type_name CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
  --
  cv_machinery_status       CONSTANT VARCHAR2(100) := '�����f�[�^���[�N�e�[�u���̋@����';
/* 20090511_abe_ST965 END*/
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
  cv_tkn_install            CONSTANT VARCHAR(20)  := '�ݒu';
  cv_tkn_withdraw           CONSTANT VARCHAR(20)  := '���g';
  cv_tkn_ablsh              CONSTANT VARCHAR(20)  := '�p��';
  cv_tkn_subject1           CONSTANT VARCHAR(20)  := '�w���˗� ';
  cv_tkn_subject2           CONSTANT VARCHAR(100) := ' �\�����̃`�F�b�N�����ŃG���[���������܂���';
  cv_tkn_subject3           CONSTANT VARCHAR(100) := ' ���F���̃`�F�b�N�����ŃG���[���������܂���';
  /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
  /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
  -- ��؂�L��
  cv_slash          CONSTANT VARCHAR2(1) := '/';
  /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
/* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
  cv_input_chk_kbn_11  CONSTANT VARCHAR2(2) := '11';  -- ��Ɖ�Ѓ��[�J�[�`�F�b�N
  cv_input_chk_kbn_12  CONSTANT VARCHAR2(2) := '12';  -- ���g����͕s�`�F�b�N
/* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
/* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
  cv_input_chk_kbn_13  CONSTANT VARCHAR2(2) := '13';  -- �ڋq�֘A�����̓`�F�b�N
/* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
/* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
  cv_input_chk_kbn_14  CONSTANT VARCHAR2(2) := '14';  -- ���g��(������)�Ó����`�F�b�N
  cv_input_chk_kbn_15  CONSTANT VARCHAR2(2) := '15';  -- ��Ɖ�БÓ����`�F�b�N
/* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
  cv_input_chk_kbn_16  CONSTANT VARCHAR2(2) := '16';  -- �\���n�K�{���̓`�F�b�N
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
/* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
  cv_input_chk_kbn_17  CONSTANT VARCHAR2(2) := '17';  -- ����E�S�����_�Ó����`�F�b�N
/* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
  --
  -- �����X�e�[�^�X�`�F�b�N�������̃`�F�b�N�敪�ԍ�
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
  /* 2009.11.25 K.Satomura E_�{�ғ�_00027�Ή� START */
  cv_jotai_kbn3_ablsh_pln   CONSTANT VARCHAR2(1) := '1';  -- �@���ԂR�i�p�����j�u�p���\��v
  /* 2009.11.25 K.Satomura E_�{�ғ�_00027�Ή� END */
  cv_jotai_kbn3_ablsh_appl  CONSTANT VARCHAR2(1) := '2';  -- �@���ԂR�i�p�����j�u�p���\�����v

  
/* 20090511_abe_ST965 START*/
  cn_num0                  CONSTANT NUMBER        := 0;
  cn_num1                  CONSTANT NUMBER        := 1;
  cn_num2                  CONSTANT NUMBER        := 2;
  cn_num3                  CONSTANT NUMBER        := 3;
  cn_num4                  CONSTANT NUMBER        := 4;
  cn_num9                  CONSTANT NUMBER        := 9;
/* 20090511_abe_ST965 END*/
/* 20090515_abe_ST669 START*/
  cv_VerifyAuthority_y        CONSTANT VARCHAR2(1) := 'Y';  -- ���F�����`�F�b�N�t���O(OK)
/* 20090515_abe_ST669 END*/

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
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
  cv_fixed_assets           CONSTANT VARCHAR2(1) := '4';  -- ���[�X�敪�u�Œ莑�Y�v
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
/* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
  cb_true                   CONSTANT BOOLEAN     := TRUE;
  cb_false                  CONSTANT BOOLEAN     := FALSE;
/* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
    , sold_charge_base          xxcso_requisition_lines_v.sold_charge_base%TYPE     -- ����E�S�����_
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
/* 20090708_abe_0000464 START*/
    , category_id               xxcso_requisition_lines_v.category_id%TYPE              -- �J�e�S��ID
    , maker_code                po_un_numbers_vl.attribute2%TYPE                        -- ���[�J�R�[�h
/* 20090708_abe_0000464 END*/
/* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� START */
    , apps_source_code          po_requisition_headers.apps_source_code%TYPE            -- �A�v���P�[�V�����\�[�X�R�[�h
/* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� END   */
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    , declaration_place         xxcso_requisition_lines_v.declaration_place%TYPE        -- �\���n
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
/* 20090511_abe_ST965 START*/
    ,jotai_kbn2    xxcso_install_base_v.jotai_kbn2%TYPE             -- �@���ԂQ�i��ԏڍׁj
    ,delete_flag   xxcso_install_base_v.sakujo_flg%TYPE             -- �폜�t���O
    ,install_code  xxcso_install_base_v.install_code%TYPE           -- �����R�[�h
/* 20090511_abe_ST965 END*/
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
    ,op_req_number_account_number xxcso_install_base_v.op_req_number_account_number%TYPE  -- ��ƈ˗����w���˗��ԍ�/�ڋqCD
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    ,instance_type_code           xxcso_install_base_v.instance_type_code%TYPE            -- �C���X�^���X�^�C�v�R�[�h
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    gv_requisition_number := ov_requisition_number;
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
/* 20090511_abe_ST965 START*/
    -- ������
    lt_status_name   := '';
    -- �u�g�p�v
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_2
                          ,od_process_date);
      SELECT cis.instance_status_id                                     -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_2
      FROM   csi_instance_statuses cis                                  -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lt_status_name
        AND  od_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, od_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, od_process_date))
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
                       ,iv_token_value3 => cv_status_name02          -- �g�[�N���l3
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
                       ,iv_token_value3 => cv_status_name02          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                   -- �g�[�N���l4
                     );
        RAISE input_parameter_expt;
    END;
--
    -- �u�������v
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_3
                          ,od_process_date);
      SELECT cis.instance_status_id                                   -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_3
      FROM   csi_instance_statuses cis                                -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lt_status_name
        AND  od_process_date 
             BETWEEN TRUNC(NVL(cis.start_date_active, od_process_date)) 
               AND TRUNC(NVL(cis.end_date_active, od_process_date))
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
                       ,iv_token_value3 => cv_status_name03          -- �g�[�N���l3
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
                       ,iv_token_value3 => cv_status_name03          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                   -- �g�[�N���l4
                     );
        RAISE input_parameter_expt;
    END;
--
--
    -- ������
    lt_status_name   := '';
    -- �u�����폜�ρv
    BEGIN
      lt_status_name := xxcso_util_common_pkg.get_lookup_meaning(
                           cv_xxcso1_instance_status
                          ,cv_instance_status_6
                          ,od_process_date);
      SELECT cis.instance_status_id                                   -- �C���X�^���X�X�e�[�^�XID
      INTO   gt_instance_status_id_6
      FROM   csi_instance_statuses cis                                -- �C���X�^���X�X�e�[�^�X�}�X�^
      WHERE  cis.name = lt_status_name
        AND  od_process_date 
               BETWEEN TRUNC(NVL(cis.start_date_active, od_process_date)) 
                 AND TRUNC(NVL(cis.end_date_active, od_process_date))
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
                       ,iv_token_value3 => cv_status_name06          -- �g�[�N���l3
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
                       ,iv_token_value3 => cv_status_name06          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_err_msg            -- �g�[�N���R�[�h4
                       ,iv_token_value4 => SQLERRM                   -- �g�[�N���l4
                     );
        RAISE input_parameter_expt;
    END;
/* 20090511_abe_ST965 END*/
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
           /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
           --    AND    TRUNC( NVL( punv.inactive_date, id_process_date + 1 ) ) 
           --            > TRUNC( id_process_date ) )  un_number    -- �@��R�[�h
              )  un_number    -- �@��R�[�h
           /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
           , xrlv.install_code              install_code              -- �ݒu�p�����R�[�h
           , xrlv.withdraw_install_code     withdraw_install_code     -- ���g�p�����R�[�h
           , xrlv.install_at_customer_code  install_at_customer_code  -- �ݒu��_�ڋq�R�[�h
           , xrlv.work_hope_time_type       work_hope_time_type       -- ��Ɗ�]���ԋ敪
           , xrlv.work_hope_time_hour       work_hope_time_hour       -- ��Ɗ�]��
           , xrlv.work_hope_time_minute     work_hope_time_minute     -- ��Ɗ�]��
           /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
           , xrlv.sold_charge_base          sold_charge_base          -- ����E�S�����_
           /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
/* 20090708_abe_0000464 START*/
           , xrlv.category_id               category_id               -- �J�e�S��ID
           , ( SELECT punv.attribute2
               FROM   po_un_numbers_vl  punv
               WHERE  punv.un_number_id = xrlv.un_number_id
           /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
           --    AND    TRUNC( NVL( punv.inactive_date, id_process_date + 1 ) ) 
           --            > TRUNC( id_process_date ) )  maker_code       -- ���[�J�[�R�[�h
              )  maker_code     -- ���[�J�[�R�[�h
           /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
/* 20090708_abe_0000464 END*/
           /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� START */
           , prh.apps_source_code           apps_source_code          -- �A�v���P�[�V�����\�[�X�R�[�h
           /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� END   */
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
           , xrlv.declaration_place         declaration_place         -- �\���n
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
           /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
           , o_requisition_rec.sold_charge_base          -- ����E�S�����_
           /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
/* 20090708_abe_0000464 START*/
           , o_requisition_rec.category_id               -- �J�e�S��ID
           , o_requisition_rec.maker_code                -- ���[�J�[�R�[�h
/* 20090708_abe_0000464 END*/
           /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� START */
           , o_requisition_rec.apps_source_code          -- �A�v���P�[�V�����\�[�X�R�[�h
           /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� END   */
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
           , o_requisition_rec.declaration_place         -- �\���n
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    , id_process_date    IN         DATE                 -- �Ɩ��������t
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
    cv_date_yymm_fmt             CONSTANT VARCHAR2(8)  := 'YYYYMM';
    cv_date_yymm_fmt_fx          CONSTANT VARCHAR2(10) := 'FXYYYYMMDD';
    cv_maker_prefix              CONSTANT VARCHAR2(2)  := '11';   --��Ɖ��CD�̓�2�����[�J�[��\��
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
/*20090413_yabuki_ST170 END*/
/*20090413_yabuki_ST171 START*/
    cv_inst_place_type_exterior  CONSTANT VARCHAR2(1) := '1';  -- �ݒu�ꏊ�敪=�u���O�v
/*20090413_yabuki_ST171 END*/
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    cv_working_day               CONSTANT VARCHAR2(100) := 'XXCSO1_WORKING_DAY'; -- �v���t�@�C���uXXCSO:�c�Ɠ����v
    cv_zero                      CONSTANT VARCHAR2(2)   := '0';
    cv_maker_prefix2             CONSTANT VARCHAR2(2)   := '10'; -- ��Ɖ��CD�̓�2�����[�J�[��\��
    cv_base_prefix               CONSTANT VARCHAR2(2)   := '02'; -- ��Ɖ��CD�̓�2�����_��\��
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    /* 2010.04.19 T.Maruyama E_�{�ғ�_02251 START */
    cv_prfl_hoped_chck_cal       CONSTANT VARCHAR2(100) := 'XXCSO1_HOPEDATE_CHECK_CAL'; -- �v���t�@�C���uXXCSO:��Ɗ�]���`�F�b�N���J�����_���v
    /* 2010.04.19 T.Maruyama E_�{�ғ�_02251 END */
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
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
    cv_tkn_val_inst_plc_flr      CONSTANT VARCHAR2(100) := '�ݒu�ꏊ�K��';
    cv_tkn_val_ele_maguchi       CONSTANT VARCHAR2(100) := '�G���x�[�^�Ԍ�';
    cv_tkn_val_ele_okuyuki       CONSTANT VARCHAR2(100) := '�G���x�[�^���s��';
    cv_tkn_val_hankaku_3_fmt     CONSTANT VARCHAR2(100) := '���p�p��3�����ȓ�';
    cv_tkn_val_num_3_fmt         CONSTANT VARCHAR2(100) := '���p����3�����ȓ�';    
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
    /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
    cv_hyphen                    CONSTANT VARCHAR2(1)   := '-';
    cv_tkn_val_cust_name         CONSTANT VARCHAR2(100) := '�ݒu��_�ڋq��';
    cv_tkn_val_zip               CONSTANT VARCHAR2(100) := '�ݒu��_�X�֔ԍ�';
    cv_tkn_val_prfcts            CONSTANT VARCHAR2(100) := '�ݒu��_�s���{��';
    cv_tkn_val_city              CONSTANT VARCHAR2(100) := '�ݒu��_�s�E��';
    cv_tkn_val_addr1             CONSTANT VARCHAR2(100) := '�ݒu��_�Z���P';
    cv_tkn_val_addr2             CONSTANT VARCHAR2(100) := '�ݒu��_�Z���Q';
    cv_tkn_val_phone             CONSTANT VARCHAR2(100) := '�ݒu��_�d�b�ԍ�';
    cv_tkn_val_emp_nm            CONSTANT VARCHAR2(100) := '�ݒu��_�S���Җ�';
    cv_tkn_val_cust_name_fmt     CONSTANT VARCHAR2(100) := '�S�p20�����ȓ�';
    cv_tkn_val_zip_fmt           CONSTANT VARCHAR2(100) := '���p����7�����ȓ�';
    cv_tkn_val_prfcts_fmt        CONSTANT VARCHAR2(100) := '�S�p4�����ȓ�';
    cv_tkn_val_city_fmt          CONSTANT VARCHAR2(100) := '�S�p10�����ȓ�';
    cv_tkn_val_addr1_fmt         CONSTANT VARCHAR2(100) := '�S�p10�����ȓ�';
    cv_tkn_val_addr2_fmt         CONSTANT VARCHAR2(100) := '�S�p20�����ȓ�';
    cv_tkn_val_phone_fmt         CONSTANT VARCHAR2(100) := '���p�����A�uXX-XXXX-XXXX�v�̌`���i�e6���ȓ��j';
    cv_tkn_val_emp_nm_fmt        CONSTANT VARCHAR2(100) := '�S�p10�����ȓ�';
    cv_temp_info                 CONSTANT VARCHAR2(100) := '���e���v���[�g';
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
    cv_cust_mast                 CONSTANT VARCHAR2(100) := '�ڋq�}�X�^';
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
    -- ���e���v���[�g�擾�p�p�����[�^
    cv_inst_at_cstmr_nm          CONSTANT VARCHAR2(100) :=  'INSTALL_AT_CUSTOMER_NAME';   -- �ݒu��ڋq��
    cv_inst_at_zp                CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ZIP';             -- �ݒu��_�X�֔ԍ�
    cv_inst_at_prfcturs          CONSTANT VARCHAR2(100) :=  'INSTALL_AT_PREFECTURES';     -- �ݒu��s���{��
    cv_inst_at_cty               CONSTANT VARCHAR2(100) :=  'INSTALL_AT_CITY';            -- �ݒu��s��
    cv_inst_at_addr1             CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ADDR1';           -- �ݒu��Z���P
    cv_inst_at_addr2             CONSTANT VARCHAR2(100) :=  'INSTALL_AT_ADDR2';           -- �ݒu��Z���Q
    cv_inst_at_phn               CONSTANT VARCHAR2(100) :=  'INSTALL_AT_PHONE';           -- �ݒu��d�b�ԍ�
    cv_inst_at_emply_nm          CONSTANT VARCHAR2(100) :=  'INSTALL_AT_EMPLOYEE_NAME';   -- �ݒu��S���Җ�
    /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
    ln_cnt_rec     NUMBER;
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
    ld_wk_date     DATE;
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    lv_working_day VARCHAR2(2000);
    ld_working_day DATE;
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
    ln_num1                      NUMBER;            -- 1��ڂ̃n�C�t���̈ʒu
    ln_num2                      NUMBER;            -- 2��ڂ̃n�C�t���̈ʒu
    lv_inst_at_phone1            VARCHAR2(100);     -- ������ �ݒu��d�b�ԍ�1
    lv_inst_at_phone2            VARCHAR2(100);     -- ������ �ݒu��d�b�ԍ�2
    lv_inst_at_phone3            VARCHAR2(100);     -- ������ �ݒu��d�b�ԍ�3
    --
    lv_inst_at_cust_name         VARCHAR2(4000);    -- �ݒu��ڋq��
    lv_inst_at_zip               VARCHAR2(4000);    -- �ݒu��_�X�֔ԍ�
    lv_inst_at_prfcturs          VARCHAR2(4000);    -- �ݒu��s���{��
    lv_inst_at_city              VARCHAR2(4000);    -- �ݒu��s��
    lv_inst_at_addr1             VARCHAR2(4000);    -- �ݒu��Z���P
    lv_inst_at_addr2             VARCHAR2(4000);    -- �ݒu��Z���Q
    lv_inst_at_phone             VARCHAR2(4000);    -- �ݒu��d�b�ԍ�
    lv_inst_at_emp_name          VARCHAR2(4000);    -- �ݒu��S���Җ�
    /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    lv_errbuf3     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
      -- ��Ɗ�]���̑Ó����`�F�b�N
      IF (i_requisition_rec.work_hope_year  ||
          i_requisition_rec.work_hope_month ||
          i_requisition_rec.work_hope_day) IS NOT NULL
      THEN
        BEGIN
          -- 1.���t�̑Ó����`�F�b�N
          SELECT TO_DATE(i_requisition_rec.work_hope_year
                      || i_requisition_rec.work_hope_month
                      || i_requisition_rec.work_hope_day, cv_date_yymm_fmt_fx)
          INTO   ld_wk_date
          FROM   DUAL
          ;
          --
          -- 2.�Q�����ȓ��`�F�b�N
          IF TO_CHAR(ADD_MONTHS(xxccp_common_pkg2.get_process_date,2),cv_date_yymm_fmt)
             < TO_CHAR(ld_wk_date,cv_date_yymm_fmt)
          THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                              iv_application => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                            , iv_name        => cv_tkn_number_56         -- ���b�Z�[�W�R�[�h
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
          END IF;
--
          /* 2010.07.29 M.Watanabe E_�{�ғ�_03239 START */
          -- 3�c�Ɠ����[���� �V��ݒu/�V���� �̂�
          --
          IF ( i_requisition_rec.category_kbn IN (  cv_category_kbn_new_install
                                                  , cv_category_kbn_new_replace ) ) THEN
          /* 2010.07.29 M.Watanabe E_�{�ғ�_03239 END */
--
            /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
            -- 3.�R�c�Ɠ����ォ�ǂ����`�F�b�N
            --
            -- �v���t�@�C���l�擾�iXXCSO:�c�Ɠ����j
            FND_PROFILE.GET(
                            cv_working_day
                           ,lv_working_day
                           );
            -- �擾�ł��Ȃ������ꍇ�́u0�v��ݒ�
            IF (lv_working_day IS NULL) THEN
              lv_working_day := cv_zero;
            END IF;
            --
            -- �Ɩ��������{�R�c�Ɠ����擾
            /* 2010.04.19 T.Maruyama E_�{�ғ�_02251 START */
            --ld_working_day := xxccp_common_pkg2.get_working_day(id_process_date,TO_NUMBER(lv_working_day));
            ld_working_day := xxccp_common_pkg2.get_working_day(id_date          => id_process_date
                                                               ,in_working_day   => TO_NUMBER(lv_working_day)
                                                               ,iv_calendar_code => FND_PROFILE.VALUE(cv_prfl_hoped_chck_cal));
            /* 2010.04.19 T.Maruyama E_�{�ғ�_02251 END */
            -- ��Ɗ�]�����A�Ɩ��������{�R�c�Ɠ��ȑO�̏ꍇ�̓G���[
            IF (ld_wk_date <= ld_working_day) THEN
              --
              lv_errbuf2 := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                              , iv_name         => cv_tkn_number_65         -- ���b�Z�[�W�R�[�h
                              , iv_token_name1  => cv_tkn_date              -- �g�[�N���R�[�h1
                              , iv_token_value1 => lv_working_day           -- �g�[�N���l1
                            );
              /* 2010.04.01 maruyama E_�{�ғ�_02133 �ꎞ�I�Ɋ�c�Ɠ����o�� start */
              lv_errbuf2 := lv_errbuf2 || '(' || to_char(ld_wk_date,'yyyy/mm/dd')|| '�F' || to_char(ld_working_day,'yyyy/mm/dd') || ')';
              /* 2010.04.01 maruyama E_�{�ғ�_02133 �ꎞ�I�Ɋ�c�Ɠ����o�� end */
              --
              lv_errbuf  := CASE
                              WHEN (lv_errbuf IS NULL) THEN
                                lv_errbuf2
                              ELSE
                                SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                            END;
              --
              ov_retcode := cv_status_warn;
              --
            END IF;
            /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
            --
--
          /* 2010.07.29 M.Watanabe E_�{�ғ�_03239 START */
          END IF;
          /* 2010.07.29 M.Watanabe E_�{�ғ�_03239 END */
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                              iv_application => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                            , iv_name        => cv_tkn_number_56         -- ���b�Z�[�W�R�[�h
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
        END;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
/*20090413_yabuki_ST170 START*/
      /* 2009.11.30 K.Satomura E_�{�ғ�_00204�Ή� START */
      -- �˗��� �� ��Ɗ�]���i��Ɗ�]�N||��Ɗ�]��||��Ɗ�]���j�̏ꍇ
      --IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
      --      > i_requisition_rec.work_hope_year
      --         || i_requisition_rec.work_hope_month
      --         || i_requisition_rec.work_hope_day ) THEN
      --  lv_errbuf2 := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
      --                  , iv_name         => cv_tkn_number_46          -- ���b�Z�[�W�R�[�h
      --                  , iv_token_name1  => cv_tkn_req_date           -- �g�[�N���R�[�h1
      --                  , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- �g�[�N���l1
      --                );
      --  --
      --  lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
      --                     THEN lv_errbuf2
      --                     ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      --  ov_retcode := cv_status_warn;
      --  --
      --END IF;
      /* 2009.11.30 K.Satomura E_�{�ғ�_00204�Ή� END */
      /* 2009.12.07 K.Satomura E_�{�ғ�_00336�Ή� START */
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
      /* 2009.12.07 K.Satomura E_�{�ғ�_00336�Ή� END */
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
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
        -- �ݒu�ꏊ�K�������`�F�b�N(���p�p���E3�o�C�g)
        IF (xxccp_common_pkg.chk_alphabet_number_only(i_requisition_rec.install_place_floor) = FALSE) 
          OR LENGTHB(i_requisition_rec.install_place_floor) > 3
        THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tkn_val_inst_plc_flr  -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                          ,iv_token_value2 => cv_tkn_val_hankaku_3_fmt -- �g�[�N���l2
                        );
          --
          lv_errbuf  := CASE
                          WHEN (lv_errbuf IS NULL) THEN
                            lv_errbuf2
                          ELSE
                            SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                        END;
          --
          ov_retcode := cv_status_warn;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
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
      
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
      -- �G���x�[�^�Ԍ������`�F�b�N(���p�����E3�o�C�g)
      IF (i_requisition_rec.elevator_frontage IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_frontage) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_frontage) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_ele_maguchi   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �G���x�[�^���s�����`�F�b�N(���p�����E3�o�C�g)
      IF (i_requisition_rec.elevator_depth IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_depth) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_depth) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_ele_okuyuki   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
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
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */ 
      -- ���g�̏ꍇ����Ɖ�ЁE��Ǝ��Ə��͎w�肷��K�v�L�B
      -- ��Ɖ�ЃR�[�h�������͂̏ꍇ
      IF (i_requisition_rec.work_company_code IS NULL) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_09         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_wk_company_cd -- �g�[�N���l1
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- ���Ə��R�[�h�������͂̏ꍇ
      IF (i_requisition_rec.work_location_code IS NULL) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_09          -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_item               -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_wk_location_cd -- �g�[�N���l1
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN 
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
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
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
      -- ��Ɗ�]���̑Ó����`�F�b�N
      IF (i_requisition_rec.work_hope_year || i_requisition_rec.work_hope_month
         || i_requisition_rec.work_hope_day ) IS NOT NULL
      THEN
        BEGIN
          -- 1.���t�̑Ó����`�F�b�N
          SELECT TO_DATE(i_requisition_rec.work_hope_year || i_requisition_rec.work_hope_month
                         || i_requisition_rec.work_hope_day, cv_date_yymm_fmt_fx)
          INTO   ld_wk_date
          FROM   DUAL;
          --
          -- 2.�Q�����ȓ��`�F�b�N
          IF TO_CHAR(ADD_MONTHS(xxccp_common_pkg2.get_process_date,2),cv_date_yymm_fmt) 
             < TO_CHAR(ld_wk_date,cv_date_yymm_fmt)
          THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                              iv_application => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                            , iv_name        => cv_tkn_number_56         -- ���b�Z�[�W�R�[�h
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
          END IF;
--
          /* 2010.07.29 M.Watanabe E_�{�ғ�_03239 START */
          -- ���g�̏ꍇ�A3�c�Ɠ����[���̃`�F�b�N�͎��{���Ȃ��B
          -- �R�����g�A�E�g�B
--
          -- /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          -- -- 3.�R�c�Ɠ����ォ�ǂ����`�F�b�N
          -- --
          -- -- �v���t�@�C���l�擾�iXXCSO:�c�Ɠ����j
          -- FND_PROFILE.GET(
          --                 cv_working_day
          --                ,lv_working_day
          --                );
          -- -- �擾�ł��Ȃ������ꍇ�́u0�v��ݒ�
          -- IF (lv_working_day IS NULL) THEN
          --   lv_working_day := cv_zero;
          -- END IF;
          -- --
          -- -- �Ɩ��������{�R�c�Ɠ����擾
          -- /* 2010.04.19 T.Maruyama E_�{�ғ�_02251 START */
          -- --ld_working_day := xxccp_common_pkg2.get_working_day(id_process_date,TO_NUMBER(lv_working_day));
          -- ld_working_day := xxccp_common_pkg2.get_working_day(id_date          => id_process_date
          --                                                    ,in_working_day   => TO_NUMBER(lv_working_day)
          --                                                    ,iv_calendar_code => FND_PROFILE.VALUE(cv_prfl_hoped_chck_cal));
          -- /* 2010.04.19 T.Maruyama E_�{�ғ�_02251 END */
          -- -- ��Ɗ�]�����A�Ɩ��������{�R�c�Ɠ��ȑO�̏ꍇ�̓G���[
          -- IF (ld_wk_date <= ld_working_day) THEN
          --   --
          --   lv_errbuf2 := xxccp_common_pkg.get_msg(
          --                     iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
          --                   , iv_name         => cv_tkn_number_65         -- ���b�Z�[�W�R�[�h
          --                   , iv_token_name1  => cv_tkn_date              -- �g�[�N���R�[�h1
          --                   , iv_token_value1 => lv_working_day           -- �g�[�N���l1
          --                 );
          --   /* 2010.04.01 maruyama E_�{�ғ�_02133 �ꎞ�I�Ɋ�c�Ɠ����o�� start */
          --   lv_errbuf2 := lv_errbuf2 || '(' || to_char(ld_wk_date,'yyyy/mm/dd')|| '�F' || to_char(ld_working_day,'yyyy/mm/dd') || ')';
          --   /* 2010.04.01 maruyama E_�{�ғ�_02133 �ꎞ�I�Ɋ�c�Ɠ����o�� end */
          --   --
          --   --
          --   lv_errbuf  := CASE
          --                   WHEN (lv_errbuf IS NULL) THEN
          --                     lv_errbuf2
          --                   ELSE
          --                     SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
          --                 END;
          --   --
          --   ov_retcode := cv_status_warn;
          --   --
          -- END IF;
          -- /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          --
--
          /* 2010.07.29 M.Watanabe E_�{�ғ�_03239 END */
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errbuf2 := xxccp_common_pkg.get_msg(
                             iv_application => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                            ,iv_name        => cv_tkn_number_56         -- ���b�Z�[�W�R�[�h
                          );
            --
            lv_errbuf  := CASE
                            WHEN (lv_errbuf IS NULL) THEN
                              lv_errbuf2
                            ELSE
                              SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                          END;
            --
            ov_retcode := cv_status_warn;
            --
        END;
        -- 
      END IF;
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */

      -- �˗��� �� ��Ɗ�]���i��Ɗ�]�N||��Ɗ�]��||��Ɗ�]���j�̏ꍇ
      /* 2009.11.30 K.Satomura E_�{�ғ�_00204�Ή� START */
      --IF ( TO_CHAR( i_requisition_rec.request_date, cv_date_fmt )
      --      > i_requisition_rec.work_hope_year
      --         || i_requisition_rec.work_hope_month
      --         || i_requisition_rec.work_hope_day ) THEN
      --  lv_errbuf2 := xxccp_common_pkg.get_msg(
      --                    iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
      --                  , iv_name         => cv_tkn_number_46          -- ���b�Z�[�W�R�[�h
      --                  , iv_token_name1  => cv_tkn_req_date           -- �g�[�N���R�[�h1
      --                  , iv_token_value1 => TO_CHAR( i_requisition_rec.request_date, cv_date_fmt2 )  -- �g�[�N���l1
      --                );
      --  --
      --  lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
      --                     THEN lv_errbuf2
      --                     ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
      --  ov_retcode := cv_status_warn;
      --  --
      --END IF;
      /* 2009.11.30 K.Satomura E_�{�ғ�_00204�Ή� END */
      /* 2009.12.07 K.Satomura E_�{�ғ�_00336�Ή� START */
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
      /* 2009.12.07 K.Satomura E_�{�ғ�_00336�Ή� END */
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
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
        -- �ݒu�ꏊ�K�������`�F�b�N(���p�p���E3�o�C�g)
        IF (xxccp_common_pkg.chk_alphabet_number_only(i_requisition_rec.install_place_floor) = FALSE)
          OR LENGTHB(i_requisition_rec.install_place_floor) > 3
        THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tkn_val_inst_plc_flr  -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                          ,iv_token_value2 => cv_tkn_val_hankaku_3_fmt -- �g�[�N���l2
                        );
          --
          lv_errbuf  := CASE
                          WHEN (lv_errbuf IS NULL) THEN
                            lv_errbuf2
                          ELSE
                            SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                        END;
          --
          ov_retcode := cv_status_warn;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
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
      
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
      -- �G���x�[�^�Ԍ������`�F�b�N(���p�����E3�o�C�g)
      IF (i_requisition_rec.elevator_frontage IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_frontage) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_frontage) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_ele_maguchi   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �G���x�[�^���s�����`�F�b�N(���p�����E3�o�C�g)
      IF (i_requisition_rec.elevator_depth IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(i_requisition_rec.elevator_depth) = FALSE)
            OR
              (LENGTHB(i_requisition_rec.elevator_depth) > 3)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_ele_okuyuki   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_num_3_fmt     -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
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
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
    -- �`�F�b�N�敪���u��Ɖ�Ѓ��[�J�[�`�F�b�N�v�̏ꍇ
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_11) THEN
      -- �V��ݒu�E�V���ւ̏ꍇ�Ɏ��{
      -- ��Ɖ�Ђ����[�J�[�łȂ��ꍇ�G���[����Ɖ��CD���Q����11�����[�J�[
      IF SUBSTRB(i_requisition_rec.work_company_code,1,2) <>  cv_maker_prefix THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name        => cv_tkn_number_58         -- ���b�Z�[�W�R�[�h
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    -- �`�F�b�N�敪���u���g����͕s�`�F�b�N�v�̏ꍇ
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_12) THEN
      -- �V��ݒu/����ݒu/�X���ړ��̏ꍇ�Ɏ��{
      -- ���g��͓��͕s��
      IF (i_requisition_rec.withdraw_company_code IS NOT NULL) 
        OR (i_requisition_rec.withdraw_location_code IS NOT NULL)
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name        => cv_tkn_number_59         -- ���b�Z�[�W�R�[�h
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
    /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
    -- �`�F�b�N�敪���u�ڋq�֘A�����̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_13 ) THEN
      -- =================
      -- �ڋq�֘A��񒊏o
      -- =================
      --�����˗����׏��r���[�̕s���ɂ��A�ݒu��Z���Q���擾�ł��Ȃ����A�r���[�̉��C�ɂ�鑼�ւ̉e�����傫���ׁA
      --�r���[�͏C�������֐��ɂ�蒼�ڏ��e���v���[�g�̒l���擾����B
      BEGIN
        SELECT xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_cstmr_nm)   -- �ݒu��ڋq��
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_zp)         -- �ݒu��_�X�֔ԍ�
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_prfcturs)   -- �ݒu��s���{��
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_cty)        -- �ݒu��s��
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_addr1)      -- �ݒu��Z���P
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_addr2)      -- �ݒu��Z���Q
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_phn)        -- �ݒu��d�b�ԍ�
              ,xxcso_ipro_common_pkg.get_temp_info(i_requisition_rec.requisition_line_id,cv_inst_at_emply_nm)   -- �ݒu��S���Җ�
        INTO   lv_inst_at_cust_name
              ,lv_inst_at_zip
              ,lv_inst_at_prfcturs
              ,lv_inst_at_city
              ,lv_inst_at_addr1
              ,lv_inst_at_addr2
              ,lv_inst_at_phone
              ,lv_inst_at_emp_name
        FROM  DUAL
        ;
      EXCEPTION
        -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                 -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_08                         -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                             -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_temp_info                             -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_req_header_num                    -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_requisition_rec.requisition_number     -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg                           -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                                  -- �g�[�N���l3
                    );
          RAISE global_api_others_expt;
      END;
      -- �ݒu��ڋq�������`�F�b�N(�S�p�����E40�o�C�g)
      IF (lv_inst_at_cust_name IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_cust_name) = FALSE)
            OR
              (LENGTHB(lv_inst_at_cust_name) > 40)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_cust_name     -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_cust_name_fmt -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu��_�X�֔ԍ������`�F�b�N(���p���l�E7�o�C�g)
      IF (lv_inst_at_zip IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_number(lv_inst_at_zip) = FALSE)
            OR
              (LENGTHB(lv_inst_at_zip) > 7)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_zip           -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_zip_fmt       -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu��s���{�������`�F�b�N(�S�p�����E8�o�C�g)
      IF (lv_inst_at_prfcturs IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_prfcturs) = FALSE)
            OR
              (LENGTHB(lv_inst_at_prfcturs) > 8)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_prfcts        -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_prfcts_fmt    -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu��s�揑���`�F�b�N(�S�p�����E20�o�C�g)
      IF (lv_inst_at_city IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_city) = FALSE)
            OR
              (LENGTHB(lv_inst_at_city) > 20)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_city          -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_city_fmt      -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu��Z���P�����`�F�b�N(�S�p�����E20�o�C�g)
      IF (lv_inst_at_addr1 IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_addr1) = FALSE)
            OR
              (LENGTHB(lv_inst_at_addr1) > 20)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_addr1         -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_addr1_fmt     -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu��Z���Q�����`�F�b�N(�S�p�����E40�o�C�g)
      IF (lv_inst_at_addr2 IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_addr2) = FALSE)
            OR
              (LENGTHB(lv_inst_at_addr2) > 40)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_addr2         -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_addr2_fmt     -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu��d�b�ԍ������`�F�b�N(���p���l�E�n�C�t����������18�o�C�g)
      IF (lv_inst_at_phone IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_tel_format(lv_inst_at_phone) = FALSE)
            OR
              (LENGTHB(REPLACE(lv_inst_at_phone,cv_hyphen,'')) > 18)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_phone         -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_phone_fmt     -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
      -- �ݒu��d�b�ԍ������㌅���`�F�b�N
      IF (lv_inst_at_phone IS NOT NULL) THEN
        -- �d�b�ԍ��̃n�C�t���̈ʒu���擾
        ln_num1    := INSTR(lv_inst_at_phone, cv_hyphen);
        ln_num2    := INSTR(lv_inst_at_phone, cv_hyphen, 1, 2);
        --
        -- �n�C�t�������݂���ꍇ�A�n�C�t���̈ʒu�œd�b�ԍ��𕪊�
        IF (ln_num1 > 0) THEN
          lv_inst_at_phone1 := SUBSTR(lv_inst_at_phone, 1
                                                          , (ln_num1-1));
        END IF;
        IF (ln_num2 > 0) THEN
          lv_inst_at_phone2 := SUBSTR(lv_inst_at_phone, ln_num1 + 1
                                                          , (ln_num2 - ln_num1 - 1));
          lv_inst_at_phone3 := SUBSTR(lv_inst_at_phone, ln_num2 + 1);
        END IF;
        --
        -- ������̐ݒu��d�b�ԍ���6���𒴂���ꍇ�̓G���[
        IF (NVL(LENGTHB(lv_inst_at_phone1), 0) > 6)
          OR
           (NVL(LENGTHB(lv_inst_at_phone2), 0) > 6)
          OR
           (NVL(LENGTHB(lv_inst_at_phone3), 0) > 6)
        THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tkn_val_phone         -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                          ,iv_token_value2 => cv_tkn_val_phone_fmt     -- �g�[�N���l2
                        );
         --
          lv_errbuf  := CASE
                          WHEN (lv_errbuf IS NULL) THEN
                            lv_errbuf2
                          ELSE
                            SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                        END;
          --
          ov_retcode := cv_status_warn;
          --
        END IF;
      END IF;
      --
      -- �ݒu��S���Җ������`�F�b�N(�S�p�����E20�o�C�g)
      IF (lv_inst_at_emp_name IS NOT NULL)
        AND (
              (xxccp_common_pkg.chk_double_byte(lv_inst_at_emp_name) = FALSE)
            OR
              (LENGTHB(lv_inst_at_emp_name) > 20)
            )
      THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_57         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_colname           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_val_emp_nm        -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_format            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_tkn_val_emp_nm_fmt    -- �g�[�N���l2
                      );
        --
        lv_errbuf  := CASE
                        WHEN (lv_errbuf IS NULL) THEN
                          lv_errbuf2
                        ELSE
                          SUBSTRB(lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000)
                      END;
        --
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    -- �`�F�b�N�敪���u���g��(������)�Ó����`�F�b�N�v�̏ꍇ
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_14) THEN
      -- �V����/������/���g�̏ꍇ�Ɏ��{
      -- ���g��(������)�ɓ��͂��ꂽCD�̓�2�����u10�v�A�u02�v�łȂ��ꍇ�̓G���[
      IF (SUBSTRB(i_requisition_rec.withdraw_company_code,1,2) <> cv_maker_prefix2) 
        AND (SUBSTRB(i_requisition_rec.withdraw_company_code,1,2) <> cv_base_prefix)
      THEN
        lv_errbuf  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_63         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prefix1           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_maker_prefix2         -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_prefix2           -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_base_prefix           -- �g�[�N���l2
                      );
        ov_retcode := cv_status_warn;
        --
      END IF;
    -- �`�F�b�N�敪���u��Ɖ�БÓ����`�F�b�N�v�̏ꍇ
    ELSIF (iv_chk_kbn = cv_input_chk_kbn_15) THEN
      --
      -- ��Ɖ��CD�̓�2�����u02�v�̏ꍇ�̓G���[
      IF (SUBSTRB(i_requisition_rec.work_company_code,1,2) = cv_base_prefix) THEN
        lv_errbuf  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_64         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_prefix            -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_base_prefix           -- �g�[�N���l1
                      );
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �`�F�b�N�敪���u�\���n�K�{���̓`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_16 ) THEN
      -- �\���n�������͂̏ꍇ
      IF ( i_requisition_rec.declaration_place IS NULL ) THEN
        lv_errbuf3 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_74         -- ���b�Z�[�W�R�[�h
                      );
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_09         -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_item              -- �g�[�N���R�[�h1
                        , iv_token_value1 => lv_errbuf3               -- �g�[�N���l1
                      );
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
        --
      END IF;
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
    -- �`�F�b�N�敪���u����E�S�����_�Ó����`�F�b�N�v�̏ꍇ
    ELSIF ( iv_chk_kbn = cv_input_chk_kbn_17 ) THEN
      -- ����E�S�����_�����p�p���ȊO�̏ꍇ
      IF ( xxccp_common_pkg.chk_number( i_requisition_rec.sold_charge_base ) = FALSE ) THEN
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_tkn_number_77         -- ���b�Z�[�W�R�[�h
                      );
        lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                           THEN lv_errbuf2
                           ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
        ov_retcode := cv_status_warn;
      -- ����E�S�����_���}�X�^�ɑ��݂��Ȃ��ꍇ
      ELSE
        BEGIN
          SELECT count(1)
          INTO   ln_cnt_rec
          FROM   hz_cust_accounts hca
          WHERE  hca.account_number      =  i_requisition_rec.sold_charge_base -- ����E�S�����_
          AND    hca.customer_class_code =  '1'                                --�y���ދ敪�z1:���_
          ;
        --
        EXCEPTION
          -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name                 -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_08                         -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table                             -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_cust_mast                             -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_req_header_num                    -- �g�[�N���R�[�h2
                         , iv_token_value2 => i_requisition_rec.requisition_number     -- �g�[�N���l2
                         , iv_token_name3  => cv_tkn_err_msg                           -- �g�[�N���R�[�h3
                         , iv_token_value3 => SQLERRM                                  -- �g�[�N���l3
                      );
            RAISE global_process_expt;
        END;
        --
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        IF ( ln_cnt_rec = 0 ) THEN
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_77          -- ���b�Z�[�W�R�[�h
                       );
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
    END IF;
    --
    ov_errbuf := lv_errbuf;
    --
  EXCEPTION
    --#################################  �Œ��O������ START   ####################################
    --
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
    WHEN global_process_expt THEN
      -- *** ���������ʗ�O�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
           /* 20090511_abe_ST965 START*/
           , xibv.jotai_kbn2                   jotai_kbn2             -- �@���ԂQ�i��ԏڍׁj
           , xibv.sakujo_flg                   sakujo_flg             -- �폜�t���O
           , xibv.install_code                 install_code           -- �����R�[�h
           /* 20090511_abe_ST965 END*/
           /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
           , xibv.op_req_number_account_number op_req_number_account_number -- ��ƈ˗����w���˗��ԍ�/�ڋqCD
           /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
           , xibv.instance_type_code           instance_type_code     -- �C���X�^���X�^�C�v�R�[�h
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
           /* 20090511_abe_ST965 START*/
           , o_instance_rec.jotai_kbn2   -- �@���ԂQ�i��ԏڍׁj
           , o_instance_rec.delete_flag  -- �폜�t���O
           , o_instance_rec.install_code -- �����R�[�h
           /* 20090511_abe_ST965 END*/
           /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
           , o_instance_rec.op_req_number_account_number -- ��ƈ˗����w���˗��ԍ�/�ڋqCD
           /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
           , o_instance_rec.instance_type_code -- �C���X�^���X�^�C�v�R�[�h
           /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
/* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
  --
  /**********************************************************************************
   * Procedure Name   : chk_authorization_status
   * Description      : �w���˗��X�e�[�^�X�`�F�b�N����(A-5-0)
   ***********************************************************************************/
  PROCEDURE chk_authorization_status(
      iv_op_req_num    IN         VARCHAR2                                -- ��ƈ˗����w���˗��ԍ�
    , ob_stts_chk_flg  OUT NOCOPY BOOLEAN                                 -- �w���˗��X�e�[�^�X�`�F�b�N�t���O
    , ov_errbuf        OUT NOCOPY VARCHAR2                                -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode       OUT NOCOPY VARCHAR2                                -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_authorization_status';  -- �v���V�[�W����
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
    cv_status_returned        CONSTANT VARCHAR2(10) := 'RETURNED';         -- �w���˗��X�e�[�^�X�u���߁v
    cv_status_cancelled       CONSTANT VARCHAR2(10) := 'CANCELLED';        -- �w���˗��X�e�[�^�X�u����ρv
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode2    VARCHAR2(1);     -- ���^�[���E�R�[�h
    lt_authorization_status  po_requisition_headers.authorization_status%TYPE;
    --
    -- *** ���[�J����O ***
    chk_authrztn_stts_expt       EXCEPTION;
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
      SELECT prh.authorization_status  authorization_status -- �w���˗��X�e�[�^�X
      INTO   lt_authorization_status
      FROM   po_requisition_headers prh
      WHERE  prh.segment1 = iv_op_req_num
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE chk_authrztn_stts_expt;
    END;
    -- �w���˗��X�e�[�^�X���u���߁v�A�u����ρv�̏ꍇ��TRUE
    IF ((lt_authorization_status = cv_status_returned)
         OR (lt_authorization_status = cv_status_cancelled)) THEN
      --
      ob_stts_chk_flg := cb_true;
    ELSE
    -- �w���˗��X�e�[�^�X���u���߁v�A�u����ρv�ȊO�̏ꍇ��FALSE
      ob_stts_chk_flg := cb_false;
    END IF;
      --
    --
  EXCEPTION
    WHEN chk_authrztn_stts_expt THEN
      -- *** SQL�f�[�^���o��O ***
      -- �w���˗��X�e�[�^�X�����o�ł��Ȃ�������FALSE
      ob_stts_chk_flg := cb_false;
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
  END chk_authorization_status;
  --
  --
/* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
  --
  /**********************************************************************************
   * Procedure Name   : check_ib_info
   * Description      : �ݒu�p�������`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE check_ib_info(
      iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    , i_instance_rec   IN         g_instance_rtype                        -- �������
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    lb_stts_chk_flg BOOLEAN;        -- �w���˗��X�e�[�^�X�`�F�b�N���� �߂�l
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
    -- *** ���[�J����O ***
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- �����敪���u�����˗��\���v�̏ꍇ
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        -- ��ƈ˗����t���O_�ݒu�p���n�m�̏ꍇ
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        -- ========================================
        -- A-5-0. �w���˗��X�e�[�^�X�`�F�b�N����
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- ��ƈ˗����w���˗��ԍ�
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- �w���˗��X�e�[�^�X�`�F�b�N�t���O
          , ov_errbuf        => lv_errbuf                      -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode       => lv_retcode                     -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- �w���˗��X�e�[�^�X�`�F�b�N�t���O��FALSE�̏ꍇ�A�`�F�b�N�G���[�Ƃ���
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_17          -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                          , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
                          , iv_token_name2  => cv_tkn_req_num                                -- �g�[�N���R�[�h2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- �g�[�N���R�[�h3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- �g�[�N���l3
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
      END IF;
      --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- �����敪���u�����˗����F�v�̏ꍇ
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- ��ƈ˗����t���O_�ݒu�p���n�e�e�̏ꍇ
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_60         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_sagyo             -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_install           -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_bukken            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => iv_install_code          -- �g�[�N���l2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    -- �@���ԂR�i�p�����j��NULL�܂��́u0:�\�薳�v����сu1:�p���\��v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn3 IS NULL )
      /* 2009.11.25 K.Satomura E_�{�ғ�_00027�Ή� START */
      OR (   
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
           AND
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_pln )
           )
      --OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
      /* 2009.11.25 K.Satomura E_�{�ғ�_00027�Ή� END */
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
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    WHEN chk_status_expt THEN
      -- *** SQL�f�[�^���o��O ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    lb_stts_chk_flg BOOLEAN;        -- �w���˗��X�e�[�^�X�`�F�b�N���� �߂�l
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
    -- *** ���[�J����O ***
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- �����敪���u�����˗��\���v�̏ꍇ
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        -- ��ƈ˗����t���O���n�m�̏ꍇ
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        -- ========================================
        -- A-5-0. �w���˗��X�e�[�^�X�`�F�b�N����
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- ��ƈ˗����w���˗��ԍ�
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- �w���˗��X�e�[�^�X�`�F�b�N�t���O
          , ov_errbuf        => lv_errbuf                      -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode       => lv_retcode                     -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- �w���˗��X�e�[�^�X�`�F�b�N�t���O��FALSE�̏ꍇ�A�`�F�b�N�G���[�Ƃ���
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_20          -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                          , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
                          , iv_token_name2  => cv_tkn_req_num                                -- �g�[�N���R�[�h2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- �g�[�N���R�[�h3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- �g�[�N���l3
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
      END IF;
      --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- �����敪���u�����˗����F�v�̏ꍇ
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- ��ƈ˗����t���O_�ݒu�p���n�e�e�̏ꍇ
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_60         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_sagyo             -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_withdraw          -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_bukken            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => iv_install_code          -- �g�[�N���l2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    WHEN chk_status_expt THEN
      -- *** SQL�f�[�^���o��O ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    lb_stts_chk_flg BOOLEAN;        -- �w���˗��X�e�[�^�X�`�F�b�N���� �߂�l
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
    -- *** ���[�J����O ***
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- �����敪���u�����˗��\���v�̏ꍇ
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
      -- ��ƈ˗����t���O���n�m�̏ꍇ
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        -- ========================================
        -- A-5-0. �w���˗��X�e�[�^�X�`�F�b�N����
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- ��ƈ˗����w���˗��ԍ�
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- �w���˗��X�e�[�^�X�`�F�b�N�t���O
          , ov_errbuf        => lv_errbuf                      -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode       => lv_retcode                     -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- �w���˗��X�e�[�^�X�`�F�b�N�t���O��FALSE�̏ꍇ�A�`�F�b�N�G���[�Ƃ���
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_22          -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                          , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
                          , iv_token_name2  => cv_tkn_req_num                                -- �g�[�N���R�[�h2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- �g�[�N���R�[�h3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- �g�[�N���l3
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
      END IF;
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- �����敪���u�����˗����F�v�̏ꍇ
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- ��ƈ˗����t���O_�ݒu�p���n�e�e�̏ꍇ
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_60         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_sagyo             -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_ablsh             -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_bukken            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => iv_install_code          -- �g�[�N���l2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- �����敪���u�����˗��\���v�̏ꍇ
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- �����敪���u�����˗����F�v�̏ꍇ
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
      END IF;
    END IF;
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    --
    -- �`�F�b�N�ŃG���[���������ꍇ
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    WHEN chk_status_expt THEN
      -- *** SQL�f�[�^���o��O ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
--    , id_process_date  IN         DATE                                    -- �Ɩ��������t
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
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
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
--    cv_zero                   CONSTANT VARCHAR2(1)  := '0';           -- ���[�X��ށuFin���[�X�v
--    cv_flag_yes               CONSTANT VARCHAR2(1)  := 'Y';           -- �Q�ƃ^�C�v�g�p�\�t���O�uYES�v
--    cv_date_fmt               CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';  -- DATE�^�t�H�[�}�b�g
--    cv_lookup_deprn_year      CONSTANT VARCHAR2(30) := 'XXCSO1_DEPRN_YEAR';  -- �Q�ƃ^�C�v�u���p�N���v
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode2    VARCHAR2(1);     -- ���^�[���E�R�[�h
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    lb_stts_chk_flg BOOLEAN;        -- �w���˗��X�e�[�^�X�`�F�b�N���� �߂�l
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
--    lv_msg                    VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W(�m�[�g)
--    ld_deprn_date             DATE;            -- ���p��
--    lv_end_deprn_date         VARCHAR2(10);    -- ���p���ԏI����(���b�Z�[�W�o�͗p)
--    lt_lease_start_date       xxcff_contract_headers.lease_start_date%TYPE;  -- ���[�X�J�n��
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
    --
    -- *** ���[�J����O ***
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
--    chk_target_data_expt  EXCEPTION;
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
--    
--    
    /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
    --�p�����َ��ɂ���ƈ˗����t���O�̔r���`�F�b�N��ǉ�
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- �����敪���u�����˗��\���v�̏ꍇ
      -- ��ƈ˗����t���O���n�m�̏ꍇ
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        -- ========================================
        -- A-5-0. �w���˗��X�e�[�^�X�`�F�b�N����
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- ��ƈ˗����w���˗��ԍ�
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- �w���˗��X�e�[�^�X�`�F�b�N�t���O
          , ov_errbuf        => lv_errbuf                      -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode       => lv_retcode                     -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- �w���˗��X�e�[�^�X�`�F�b�N�t���O��FALSE�̏ꍇ�A�`�F�b�N�G���[�Ƃ���
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          lv_errbuf2 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                          , iv_name         => cv_tkn_number_22          -- ���b�Z�[�W�R�[�h
                          , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                          , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                          , iv_token_name2  => cv_tkn_req_num                                -- �g�[�N���R�[�h2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- �g�[�N���R�[�h3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- �g�[�N���l3
                        );
          --
          lv_errbuf  := lv_errbuf2;
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
      END IF;
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- �����敪���u�����˗����F�v�̏ꍇ
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- ��ƈ˗����t���O_�ݒu�p���n�e�e�̏ꍇ
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_60         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_sagyo             -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_ablsh             -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_bukken            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => iv_install_code          -- �g�[�N���l2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
    -- �@���ԂR�i�p�����j��NULL�܂��́u�\�薳�v�u�p���\��v�ȊO�̏ꍇ
    IF ( i_instance_rec.jotai_kbn3 IS NULL )
    /* 2010.12.07 K.Kiriu E_�{�ғ�_05751�Ή� START */
--      OR ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_appl )
      OR (
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_non_schdl )
           AND
           ( i_instance_rec.jotai_kbn3 <> cv_jotai_kbn3_ablsh_pln )
         )
    /* 2010.12.07 K.Kiriu E_�{�ғ�_05751�Ή� END */
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
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
--    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
--    -- �����敪���u�����˗��\���v�̏ꍇ
--    --
--      -- �����R�[�h�̃��[�X�J�n�����擾
--      BEGIN
--        SELECT
--               /*+ USE_NL(xxoh xxcl xxch) 
--               INDEX(xxoh XXCFF_OBJECT_HEADERS_U01) */
--               xxch.lease_start_date  lease_start_date --���[�X�J�n��
--        INTO
--               lt_lease_start_date
--        FROM   
--               xxcff_object_headers    xxoh  --���[�X����
--              ,xxcff_contract_lines    xxcl  --���[�X�_�񖾍�
--              ,xxcff_contract_headers  xxch  --���[�X�_��w�b�_
--        WHERE
--               xxoh.object_code      = iv_install_code            --�����R�[�h
--        AND    xxoh.object_header_id = xxcl.object_header_id      --��������ID
--        AND    xxcl.lease_kind       = cv_zero                    --���[�X���(Fin)
--        AND    xxch.contract_header_id = xxcl.contract_header_id  --�_�����ID
--        ;
--      EXCEPTION
--        -- �Y���f�[�^�����݂��Ȃ��ꍇ
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--        -- ���o�Ɏ��s�����ꍇ
--        WHEN OTHERS THEN
--          lv_msg := xxccp_common_pkg.get_msg(
--                          iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
--                         ,iv_name        => cv_tkn_number_69           -- ���b�Z�[�W
--                       );
--          lv_errbuf := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
--                         ,iv_name         => cv_tkn_number_68          -- ���b�Z�[�W�R�[�h
--                         ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
--                         ,iv_token_value1 => lv_msg                    -- �g�[�N���l1
--                         ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
--                         ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
--                       );
--        RAISE chk_target_data_expt;
--      END;
--      --
--      -- ���[�X�J�n�����擾�����ꍇ�A���p���𒊏o����
--      IF ( lt_lease_start_date IS NOT NULL ) THEN
--      --
--        -- ���[�X�J�n�����珞�p�����擾
--        BEGIN
--          SELECT 
--                 ADD_MONTHS( lt_lease_start_date , flvv.attribute1 * 12 ) deprn_date  --���p��
--          INTO
--                 ld_deprn_date
--          FROM   fnd_lookup_values_vl flvv
--          WHERE  flvv.lookup_type  = cv_lookup_deprn_year
--          AND    flvv.enabled_flag = cv_flag_yes
--          AND    flvv.start_date_active <= lt_lease_start_date  --�L���J�n��
--          AND    flvv.end_date_active   >= lt_lease_start_date  --�L���I����
--          ;
--        EXCEPTION
--          -- �Y���f�[�^�����݂��Ȃ��ꍇ
--          WHEN NO_DATA_FOUND THEN
--            NULL;
--          -- ���o�Ɏ��s�����ꍇ
--          WHEN OTHERS THEN
--            lv_msg := xxccp_common_pkg.get_msg(
--                            iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
--                           ,iv_name        => cv_tkn_number_70           -- ���b�Z�[�W
--                         );
--            lv_errbuf := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
--                           ,iv_name         => cv_tkn_number_68          -- ���b�Z�[�W�R�[�h
--                           ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
--                           ,iv_token_value1 => lv_msg                    -- �g�[�N���l1
--                           ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
--                           ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
--                         );
--          RAISE chk_target_data_expt;
--        END;
--      --
--      END IF;
--      --
--      -- �Ɩ����t�����[�X�J�n���ȏ�A�����p�������̏ꍇ�A�`�F�b�N�G���[�Ƃ���
--      IF ( lt_lease_start_date <= id_process_date ) 
--        AND ( id_process_date < ld_deprn_date ) THEN
--        --
--        lv_end_deprn_date := TO_CHAR(ld_deprn_date - 1, cv_date_fmt);
--        lv_errbuf2 := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_tkn_number_67         -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_date              -- �g�[�N���R�[�h1
--                        ,iv_token_value1 => lv_end_deprn_date        -- �g�[�N���l1
--                      );
--        --
--        lv_errbuf  := lv_errbuf2;
--        ov_retcode := cv_status_error;
--        --
--      END IF;
--    END IF;
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
    --
    -- �`�F�b�N�ŃG���[���������ꍇ
    IF ( ov_retcode = cv_status_error ) THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      --
    END IF;
    --
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    WHEN chk_status_expt THEN
      -- *** SQL�f�[�^���o��O ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
--    WHEN chk_target_data_expt THEN
--      -- *** �Ώۃf�[�^���o��O ***
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
--    /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    , iv_process_kbn   IN         VARCHAR2
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    lv_errbuf2     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    lb_stts_chk_flg BOOLEAN;        -- �w���˗��X�e�[�^�X�`�F�b�N���� �߂�l
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
    -- *** ���[�J����O ***
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    chk_status_expt       EXCEPTION;
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
      -- �����敪���u�����˗��\���v�̏ꍇ
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
      -- ��ƈ˗����t���O���n�m�̏ꍇ
      IF ( i_instance_rec.op_req_flag = cv_op_req_flag_on ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        -- ========================================
        -- A-5-0. �w���˗��X�e�[�^�X�`�F�b�N����
        -- ========================================
        chk_authorization_status(
            iv_op_req_num    => SUBSTRB( i_instance_rec.op_req_number_account_number
                                  ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) )  -- ��ƈ˗����w���˗��ԍ�
          , ob_stts_chk_flg  => lb_stts_chk_flg                -- �w���˗��X�e�[�^�X�`�F�b�N�t���O
          , ov_errbuf        => lv_errbuf                      -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode       => lv_retcode                     -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE chk_status_expt;
          --
        END IF;
        --
        -- �w���˗��X�e�[�^�X�`�F�b�N�t���O��FALSE�̏ꍇ�A�`�F�b�N�G���[�Ƃ���
        IF ( lb_stts_chk_flg = cb_false ) THEN
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_17          -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
                         , iv_token_value1 => iv_install_code           -- �g�[�N���l1
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
                          , iv_token_name2  => cv_tkn_req_num                                -- �g�[�N���R�[�h2
                          , iv_token_value2 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,1,( INSTRB(i_instance_rec.op_req_number_account_number,'/')-1 ) ) -- �g�[�N���l2
                          , iv_token_name3  => cv_tkn_kokyaku                                -- �g�[�N���R�[�h3
                          , iv_token_value3 => SUBSTRB( i_instance_rec.op_req_number_account_number
                                                       ,( INSTRB(i_instance_rec.op_req_number_account_number,'/')+1) ) -- �g�[�N���l3
                          /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
                       );
          --
          ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
          ov_retcode := cv_status_error;
          --
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
      END IF;
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    END IF;
    --
    IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
      -- �����敪���u�����˗����F�v�̏ꍇ
      IF (i_instance_rec.op_req_flag = cv_op_req_flag_off) THEN
        -- ��ƈ˗����t���O_�ݒu�p���n�e�e�̏ꍇ
        lv_errbuf2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_60         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_sagyo             -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tkn_install           -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_bukken            -- �g�[�N���R�[�h2
                        ,iv_token_value2 => iv_install_code          -- �g�[�N���l2
                      );
        --
        lv_errbuf  := lv_errbuf2;
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
        --
      END IF;
      --
    END IF;
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
  EXCEPTION
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
    WHEN chk_status_expt THEN
      -- *** SQL�f�[�^���o��O ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;    
    /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
   * Description      : �����X�e�[�^�X�`�F�b�N����(A-10)
   ***********************************************************************************/
  PROCEDURE check_object_status(
      iv_chk_kbn       IN         VARCHAR2                                -- �`�F�b�N�敪
    , iv_install_code  IN         xxcso_install_base_v.install_code%TYPE  -- �����R�[�h
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
    , id_process_date  IN         DATE                                    -- �Ɩ��������t
    , iv_process_kbn   IN         VARCHAR2                                -- �����敪
    /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    , iv_lease_kbn          IN    VARCHAR2                                -- ���[�X�敪
    , iv_instance_type_code IN    VARCHAR2                                -- �C���X�^���X�^�C�v�R�[�h
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
    cv_obj_sts_uncontract          CONSTANT VARCHAR2(3) := '101';  -- ���_��
/* 2009.12.16 D.Abe E_�{�ғ�_00498�Ή� START */
    cv_obj_sts_lease_wait          CONSTANT VARCHAR2(3) := '103';  -- �ă��[�X��
/* 2009.12.16 D.Abe E_�{�ғ�_00498�Ή� END */
    -- ���[�X�敪
    cv_ls_tp_lease_cntrctd         CONSTANT VARCHAR2(1) := '1';    -- ���_��
    cv_ls_tp_re_lease_cntrctd      CONSTANT VARCHAR2(1) := '2';    -- �ă��[�X�_��
    -- �؏���̃t���O
    cv_bnd_accpt_flg_accptd        CONSTANT VARCHAR2(1) := '1';    -- ��̍�
    --
    cv_yes                         CONSTANT VARCHAR2(1) := 'Y';
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
    cv_zero                        CONSTANT VARCHAR2(1)  := '0';           -- ���[�X��ށuFin���[�X�v
    cv_flag_yes                    CONSTANT VARCHAR2(1)  := 'Y';           -- �Q�ƃ^�C�v�g�p�\�t���O�uYES�v
    cv_date_fmt                    CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';  -- DATE�^�t�H�[�}�b�g
    cv_lookup_deprn_year           CONSTANT VARCHAR2(30) := 'XXCSO1_DEPRN_YEAR';  -- �Q�ƃ^�C�v�u���p�N���v
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- �v���t�@�C��
    cv_prfl_fa_books               CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSETS_BOOKS'; -- XXCFF:�䒠��
    -- �Q�ƃ^�C�v
    cv_lookup_csi_type_code        CONSTANT VARCHAR2(30) := 'CSI_INST_TYPE_CODE';        -- �C���X�^���X�E�^�C�v�E�R�[�h
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    lv_object_status    xxcff_object_headers.object_status%TYPE;    -- �����X�e�[�^�X
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
    lt_lease_type            xxcff_object_headers.lease_type%TYPE;              -- ���[�X�敪
    lt_bond_acceptance_flag  xxcff_object_headers.bond_acceptance_flag%TYPE;    -- �؏���̃t���O
    lv_no_data_flg           VARCHAR2(1) DEFAULT 'N';
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
    lv_msg                   VARCHAR2(5000);      -- ���[�U�[�E���b�Z�[�W(�m�[�g)
    ld_deprn_date            DATE;                -- ���p��
    lv_end_deprn_date        VARCHAR2(10);        -- ���p���ԏI����(���b�Z�[�W�o�͗p)
    lv_no_chk_flag           VARCHAR2(1) := 'N';  -- ���p�`�F�b�N�t���O
    lt_lease_start_date      xxcff_contract_headers.lease_start_date%TYPE;  -- ���[�X�J�n��
    lt_lease_class           xxcff_contract_headers.lease_class%TYPE;       -- ���[�X���
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    lt_fa_book_type_code           fa_books.book_type_code%TYPE;            -- �䒠��
    lt_date_placed_in_service      fa_books.date_placed_in_service%TYPE;    -- ���Ƌ��p��
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
    --
    -- *** ���[�J����O ***
    sql_expt      EXCEPTION;
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
    chk_target_data_expt  EXCEPTION;
    chk_deprn_date_expt   EXCEPTION;
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
    --
  BEGIN
    --
    --##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  �Œ蕔 END   ############################
    --
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- ���[�X�敪���u���Ѓ��[�X�v�̏ꍇ
    IF ( iv_lease_kbn = cv_own_company_lease ) THEN
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
      -- ========================================
      -- ���[�X�����e�[�u�����o
      -- ========================================
      BEGIN
        SELECT xoh.object_status  object_status
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
              ,xoh.lease_type            lease_type
              ,xoh.bond_acceptance_flag  bond_acceptance_flag
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
        INTO   lv_object_status
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
              ,lt_lease_type
              ,lt_bond_acceptance_flag
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
        FROM   xxcff_object_headers  xoh
        WHERE  xoh.object_code = iv_install_code
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- �Y���f�[�^�����݂��Ȃ��ꍇ
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
--        lv_errbuf := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
--                       , iv_name         => cv_tkn_number_26          -- ���b�Z�[�W�R�[�h
--                       , iv_token_name1  => cv_tkn_bukken             -- �g�[�N���R�[�h1
--                       , iv_token_value1 => iv_install_code           -- �g�[�N���l1
--                     );
--        --
--        RAISE sql_expt;
--        --
            lv_object_status := NULL;         -- �����X�e�[�^�X
            lt_lease_type    := NULL;         -- ���[�X�敪
            lt_bond_acceptance_flag := NULL;  -- �؏���̃t���O
            --
            lv_no_data_flg   := cv_yes;
            --
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
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
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
--      -- �����X�e�[�^�X��NULL�ȊO�ł��A�u�_��ρv�u�ă��[�X�_��ρv�ȊO�̏ꍇ
        /* 2009.12.16 D.Abe E_�{�ғ�_00498�Ή� START */
        ---- �����X�e�[�^�X��NULL�ȊO�ł��A�u�_��ρv�u�ă��[�X�_��ρv�u���_��('101')�v�ȊO�̏ꍇ
        -- �����X�e�[�^�X��NULL�ȊO�ł��A�u�_��ρv�u�ă��[�X�_��ρv�u���_��('101')�v�u�ă��[�X�ҁv�ȊO�̏ꍇ
        /* 2009.12.16 D.Abe E_�{�ғ�_00498�Ή� END */
        IF ( lv_object_status IS NOT NULL
--           AND lv_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd ) ) THEN
             /* 2009.12.16 D.Abe E_�{�ғ�_00498�Ή� START */
             --AND lv_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd, cv_obj_sts_uncontract ) ) THEN
             AND lv_object_status NOT IN ( cv_obj_sts_contracted, cv_obj_sts_re_lease_cntrctd, cv_obj_sts_uncontract,
                                           cv_obj_sts_lease_wait ) ) THEN
           /* 2009.12.16 D.Abe E_�{�ғ�_00498�Ή� END */
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
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
        /* 2009.12.16 D.Abe E_�{�ғ�_00354�Ή� START */
        --  ���[�X���������݂��Ȃ��ꍇ
        IF  ( lv_no_data_flg = cv_yes ) THEN
          RETURN;
        END IF;
        --
        /* 2009.12.16 D.Abe E_�{�ғ�_00354�Ή� END */
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
--      -- �����X�e�[�^�X��NULL�ȊO�ł��A
--      -- �u�ă��[�X�_��ρv�u���r���i���ȓs���j�v�u���r���i�ی��Ή��j�v�u���r���i�����j�v�u�����v�ȊO�̏ꍇ
--      IF ( lv_object_status IS NOT NULL
--           AND lv_object_status NOT IN ( cv_obj_sts_re_lease_cntrctd, cv_obj_sts_canceled_cnvnnc, cv_obj_sts_canceled_insurance
--                                         , cv_obj_sts_canceled_expired, cv_obj_sts_expired ) ) THEN
        -- �����}�X�^�ɓo�^����Ă��Ȃ��ꍇ�܂���
        IF ( lv_no_data_flg = cv_yes )
          -- �����X�e�[�^�X���u�����v�A�u���r���i�����j�v�ȊO���A
          -- �w���[�X�敪���u���_��v�������X�e�[�^�X���u���r���(���ȓs��)�v���؏���̃t���O���u��̍ρv�x�ȊO���A
          -- �w���[�X�敪���u���_��v�������X�e�[�^�X���u���r���(�ی��Ή�)�v���؏���̃t���O���u��̍ρv�x�ȊO���A
          -- ���[�X�敪���u�ă��[�X�_��v�ȊO�̏ꍇ
          OR (         (       lv_object_status NOT IN ( cv_obj_sts_expired, cv_obj_sts_canceled_expired )  )
               AND NOT (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd     )
                         AND ( lv_object_status        = cv_obj_sts_canceled_cnvnnc )
                         AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd    )  )
               AND NOT (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd     )
                         AND ( lv_object_status        = cv_obj_sts_canceled_insurance )
                         AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd    )  )
               AND     (       lt_lease_type <> cv_ls_tp_re_lease_cntrctd           )         ) THEN
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
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
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
        -- �����敪���u�����˗��\���v�̏ꍇ
        IF (iv_process_kbn = cv_proc_kbn_req_appl) THEN
          -- �����X�e�[�^�X���u���r���(���ȓs��)�v���؏���̃t���O���u��̍ρv�x���A
          -- �����X�e�[�^�X���u���r���(�ی��Ή�)�v���؏���̃t���O���u��̍ρv�x
          IF (
/* 2014-12-15 K.Kanada E_�{�ғ�_12775�Ή� START */
--              (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd     )
--                AND ( lv_object_status        = cv_obj_sts_canceled_cnvnnc )
              (     ( lv_object_status        = cv_obj_sts_canceled_cnvnnc )
/* 2014-12-15 K.Kanada E_�{�ғ�_12775�Ή� END   */
                AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd    ) )
            OR
/* 2014-12-15 K.Kanada E_�{�ғ�_12775�Ή� START */
--              (     ( lt_lease_type           = cv_ls_tp_lease_cntrctd        )
--                AND ( lv_object_status        = cv_obj_sts_canceled_insurance )
              (     ( lv_object_status        = cv_obj_sts_canceled_insurance )
/* 2014-12-15 K.Kanada E_�{�ғ�_12775�Ή� END   */
                AND ( lt_bond_acceptance_flag = cv_bnd_accpt_flg_accptd       ) )
              ) THEN
                lv_no_chk_flag := 'Y'; -- ���p���ԃ`�F�b�N�ΏۊO
          END IF;
          --
          IF lv_no_chk_flag = 'N' THEN
            -- �����R�[�h�̃��[�X�_������擾
            BEGIN
              SELECT
                     /*+ USE_NL(xxoh xxcl xxch) 
                     INDEX(xxoh XXCFF_OBJECT_HEADERS_U01) */
                     xxch.lease_start_date  lease_start_date -- ���[�X�J�n��
                    ,xxch.lease_class       lease_class      -- ���[�X���
              INTO
                     lt_lease_start_date
                    ,lt_lease_class
              FROM   
                     xxcff_object_headers    xxoh  --���[�X����
                    ,xxcff_contract_lines    xxcl  --���[�X�_�񖾍�
                    ,xxcff_contract_headers  xxch  --���[�X�_��w�b�_
              WHERE
                     xxoh.object_code      = iv_install_code            -- �����R�[�h
              AND    xxoh.object_header_id = xxcl.object_header_id      -- ��������ID
              AND    xxcl.lease_kind       = cv_zero                    -- ���[�X���(Fin)
              AND    xxch.contract_header_id = xxcl.contract_header_id  -- �_�����ID
              ;
            EXCEPTION
              -- �Y���f�[�^�����݂��Ȃ��ꍇ
              WHEN NO_DATA_FOUND THEN
                NULL;
              -- ���o�Ɏ��s�����ꍇ
              WHEN OTHERS THEN
                lv_msg := xxccp_common_pkg.get_msg(
                                iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                               ,iv_name        => cv_tkn_number_69           -- ���b�Z�[�W
                          );
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                               ,iv_name         => cv_tkn_number_68          -- ���b�Z�[�W�R�[�h
                               ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                               ,iv_token_value1 => lv_msg                    -- �g�[�N���l1
                               ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                               ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                             );
                RAISE chk_target_data_expt;
            END;
            --
            -- ���[�X�J�n�����擾�����ꍇ�A���p���𒊏o����
            IF ( lt_lease_start_date IS NOT NULL ) THEN
            --
              -- ���[�X�J�n�����珞�p�����擾
              BEGIN
                SELECT 
                       ADD_MONTHS( lt_lease_start_date , flvv.attribute1 * 12 ) deprn_date  -- ���p��
                INTO
                       ld_deprn_date
                FROM   fnd_lookup_values_vl flvv
                WHERE  flvv.lookup_type  = cv_lookup_deprn_year
                AND    flvv.enabled_flag = cv_flag_yes
                AND    flvv.attribute2   = lt_lease_class
                AND    flvv.start_date_active <= lt_lease_start_date  -- �L���J�n��
                AND    flvv.end_date_active   >= lt_lease_start_date  -- �L���I����
                ;
              EXCEPTION
                -- �Y���f�[�^�����݂��Ȃ��ꍇ
                WHEN NO_DATA_FOUND THEN
                  NULL;
                -- ���o�Ɏ��s�����ꍇ
                WHEN OTHERS THEN
                  lv_msg := xxccp_common_pkg.get_msg(
                                  iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                                 ,iv_name        => cv_tkn_number_70           -- ���b�Z�[�W
                            );
                  lv_errbuf := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                                 ,iv_name         => cv_tkn_number_68          -- ���b�Z�[�W�R�[�h
                                 ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                                 ,iv_token_value1 => lv_msg                    -- �g�[�N���l1
                                 ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                                 ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                               );
                  RAISE chk_target_data_expt;
              END;
            --
            END IF;
            --
            -- �Ɩ����t�����[�X�J�n���ȏ�A�����p�������̏ꍇ�A�`�F�b�N�G���[�Ƃ���
            IF ( lt_lease_start_date <= id_process_date ) 
              AND ( id_process_date < ld_deprn_date ) THEN
              --
              lv_end_deprn_date := TO_CHAR(ld_deprn_date - 1, cv_date_fmt);
              lv_errbuf := xxccp_common_pkg.get_msg(
                               iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                              ,iv_name         => cv_tkn_number_67         -- ���b�Z�[�W�R�[�h
                              ,iv_token_name1  => cv_tkn_date              -- �g�[�N���R�[�h1
                              ,iv_token_value1 => lv_end_deprn_date        -- �g�[�N���l1
                           );
              RAISE chk_deprn_date_expt;
            END IF;
          --
          END IF;
        --
        END IF;
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
      END IF;
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
    -- ���[�X�敪���u�Œ莑�Y�v�̏ꍇ
    ELSIF ( iv_lease_kbn = cv_fixed_assets ) THEN
      -- �v���t�@�C���l�擾�iXXCFF:�䒠���j
      FND_PROFILE.GET( cv_prfl_fa_books ,lt_fa_book_type_code );
      -- �v���t�@�C���l���擾�ł��Ȃ��ꍇ
      IF ( lt_fa_book_type_code IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_71          -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_prof_name          -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_prfl_fa_books          -- �g�[�N���l1
                     );
        RAISE sql_expt;
      END IF;
      --
      -- ���[�X��ʎ擾
      lt_lease_class := xxcso_util_common_pkg.get_lookup_attribute(
                           cv_lookup_csi_type_code
                          ,iv_instance_type_code
                          ,1
                          ,id_process_date
                        );
      -- ���[�X��ʂ��擾�ł��Ȃ��ꍇ
      IF ( lt_lease_class IS NULL ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_tkn_number_76         -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_task_nm           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => iv_instance_type_code    -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                        ,iv_token_value2 => cv_lookup_csi_type_code  -- �g�[�N���l2
                     );
        RAISE sql_expt;
      END IF;
      --
      -- ���Ƌ��p���擾
      BEGIN
        SELECT fb.date_placed_in_service date_placed_in_service -- ���Ƌ��p��
        INTO   lt_date_placed_in_service
        FROM   fa_additions_b            fab -- ���Y�ڍ׏��
              ,fa_books                  fb  -- ���Y�䒠���
        WHERE  fab.asset_id      = fb.asset_id
        AND    fb.date_ineffective IS NULL
        AND    fb.book_type_code = lt_fa_book_type_code
        AND    fab.tag_number    = iv_install_code
        ;
      EXCEPTION
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        WHEN NO_DATA_FOUND THEN
          NULL;
        -- ���o�Ɏ��s�����ꍇ
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                          iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                         ,iv_name        => cv_tkn_number_70           -- ���b�Z�[�W
                    );
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_68          -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                         ,iv_token_value1 => lv_msg                    -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                         ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                       );
          RAISE chk_target_data_expt;
      END;
      --
      -- ���Ƌ��p�����擾�����ꍇ
      IF ( lt_date_placed_in_service IS NOT NULL ) THEN
        -- ���p�����擾
        BEGIN
          SELECT ADD_MONTHS( lt_date_placed_in_service , flvv.attribute1 * 12 ) deprn_date -- ���p��
          INTO   ld_deprn_date
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type        = cv_lookup_deprn_year
          AND    flvv.enabled_flag       = cv_flag_yes
          AND    flvv.attribute2         = lt_lease_class
          AND    flvv.start_date_active <= lt_date_placed_in_service  -- �L���J�n��
          AND    flvv.end_date_active   >= lt_date_placed_in_service  -- �L���I����
          ;
        EXCEPTION
          -- �Y���f�[�^�����݂��Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            NULL;
          -- ���o�Ɏ��s�����ꍇ
          WHEN OTHERS THEN
            lv_msg := xxccp_common_pkg.get_msg(
                            iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                           ,iv_name        => cv_tkn_number_70           -- ���b�Z�[�W
                      );
            lv_errbuf := xxccp_common_pkg.get_msg(
                            iv_application  => cv_sales_appl_short_name  -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_tkn_number_68          -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_task_nm            -- �g�[�N���R�[�h1
                           ,iv_token_value1 => lv_msg                    -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_err_msg            -- �g�[�N���R�[�h2
                           ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                         );
            RAISE chk_target_data_expt;
        END;
        --
        -- �Ɩ����t�����Ƌ��p���ȏ�A�����p�������̏ꍇ�A�`�F�b�N�G���[�Ƃ���
        IF ( lt_date_placed_in_service <= id_process_date )
          AND ( id_process_date < ld_deprn_date ) THEN
          --
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name                -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_67                        -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_date                             -- �g�[�N���R�[�h1
                         ,iv_token_value1 => TO_CHAR(ld_deprn_date - 1, cv_date_fmt) -- �g�[�N���l1
                       );
          RAISE chk_deprn_date_expt;
        END IF;
      END IF;
    END IF;
    /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
    --
  EXCEPTION
    --
    WHEN sql_expt THEN
      -- *** SQL�f�[�^���o��O���`�F�b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
      WHEN chk_target_data_expt THEN
        -- *** �Ώۃf�[�^���o��O ***
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
      --
      WHEN chk_deprn_date_expt THEN
        -- *** �Ώۃf�[�^���o��O ***
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
/* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
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
    /* 2009.09.10 K.Satomura 0001335�Ή� START */
    cv_cust_sts_check_off  CONSTANT VARCHAR2(2) := '99';  -- �ڋq�X�e�[�^�X�u�ΏۊO�v
    /* 2009.09.10 K.Satomura 0001335�Ή� END */
    /*20090402_yabuki_ST177 START*/
    cv_cust_sts_sp_aprvd   CONSTANT VARCHAR2(2) := '25';  -- �ڋq�X�e�[�^�X�uSP���F�ρv
    /*20090402_yabuki_ST177 END*/
    /*20090427_yabuki_ST0505_0517 START*/
    cv_cust_resources_v    CONSTANT VARCHAR2(30) := '�ڋq�S���c�ƈ����';
    cv_tkn_val_cust_cd     CONSTANT VARCHAR2(30) := '�ڋq�R�[�h';
    /*20090427_yabuki_ST0505_0517 END*/
    /* 2009.09.10 K.Satomura 0001335�Ή� START */
    ct_cust_cl_cd_cust     CONSTANT xxcso_cust_acct_sites_v.customer_class_code%TYPE := '10'; -- �ڋq�敪=�ڋq
    ct_cust_cl_cd_round    CONSTANT xxcso_cust_acct_sites_v.customer_class_code%TYPE := '15'; -- �ڋq�敪=����
    /* 2009.09.10 K.Satomura 0001335�Ή� END */
    --
    -- *** ���[�J���ϐ� ***
    lv_customer_status    xxcso_cust_accounts_v.customer_status%TYPE;  -- �ڋq�X�e�[�^�X
    /*20090427_yabuki_ST0505_0517 START*/
    lt_cust_acct_id       xxcso_cust_accounts_v.cust_account_id%TYPE;  -- �A�J�E���gID
    ln_cnt_rec            NUMBER;                                      -- ���R�[�h����
    /*20090427_yabuki_ST0505_0517 END*/
    /* 2009.09.10 K.Satomura 0001335�Ή� START */
    lt_customer_class_code xxcso_cust_acct_sites_v.customer_class_code%TYPE;
    /* 2009.09.10 K.Satomura 0001335�Ή� END */
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
            ,casv.cust_account_id  cust_account_id    -- �A�J�E���gID
            /* 2009.09.10 K.Satomura 0001335�Ή� START */
            ,casv.customer_class_code customer_class_code
            /* 2009.09.10 K.Satomura 0001335�Ή� END */
      INTO   lv_customer_status
            ,lt_cust_acct_id
            /* 2009.09.10 K.Satomura 0001335�Ή� START */
            ,lt_customer_class_code
            /* 2009.09.10 K.Satomura 0001335�Ή� END */
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
    /* 2009.09.10 K.Satomura 0001335�Ή� START */
    IF (lt_customer_class_code = ct_cust_cl_cd_cust) THEN
    /* 2009.09.10 K.Satomura 0001335�Ή� END */
      /*20090402_yabuki_ST177 START*/
      -- �擾�����ڋq�X�e�[�^�X���u���F�ρv�u�ڋq�v�u�x�~�v�uSP���F�ρv�ȊO�̏ꍇ
      IF ( lv_customer_status NOT IN ( cv_cust_sts_approved, cv_cust_sts_customer, cv_cust_sts_abeyance, cv_cust_sts_sp_aprvd ) ) THEN
      ---- �擾�����ڋq�X�e�[�^�X���u���F�ρv�u�ڋq�v�u�x�~�v�ȊO�̏ꍇ
      --IF ( lv_customer_status NOT IN ( cv_cust_sts_approved, cv_cust_sts_customer, cv_cust_sts_abeyance ) ) THEN
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
    /* 2009.09.10 K.Satomura 0001335�Ή� START */
    ELSIF (lt_customer_class_code = ct_cust_cl_cd_round) THEN
      -- �ڋq�敪��15�F����̏ꍇ�A�ڋq�X�e�[�^�X��99�ȊO�̓G���[
      IF (lv_customer_status <> cv_cust_sts_check_off) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_55            -- ���b�Z�[�W�R�[�h
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
    /* 2009.11.25 K.Satomura E_�{�ғ�_00027�Ή� START */
    ELSE
      -- ��L�ȊO�̏ꍇ�̓G���[
      lv_errbuf := xxccp_common_pkg.get_msg(
                      iv_application  => cv_sales_appl_short_name -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_34         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_kokyaku           -- �g�[�N���R�[�h1
                     ,iv_token_value1 => iv_account_number        -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_cust_status       -- �g�[�N���R�[�h2
                     ,iv_token_value2 => lv_customer_status       -- �g�[�N���l2
                   );
      --
      RAISE sql_expt;
      --
    /* 2009.11.25 K.Satomura E_�{�ғ�_00027�Ή� END */
    END IF;
    /* 2009.09.10 K.Satomura 0001335�Ή� END */
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
      /* 2009.08.11 K.Satomura 0000662�Ή� START */
      SELECT COUNT(1)
      INTO   ln_cnt_rec
      FROM   xxcmm_cust_accounts xca -- �ڋq�A�h�I���}�X�^
      WHERE  xca.customer_code        = iv_account_number
      AND    xca.cnvs_business_person IS NOT NULL
      ;
      --
      IF (ln_cnt_rec = 0) THEN
      /* 2009.08.11 K.Satomura 0000662�Ή� END */
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
      /* 2009.08.11 K.Satomura 0000662�Ή� START */
      END IF;
      /* 2009.08.11 K.Satomura 0000662�Ή� END */
    END IF;
    /* 2009.08.11 K.Satomura 0000662�Ή� END */
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
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
  /**********************************************************************************
   * Procedure Name   : check_dclr_place_mst
   * Description      : �\���n�}�X�^���݃`�F�b�N����(A-27)
   ***********************************************************************************/
  PROCEDURE check_dclr_place_mst(
      iv_declaration_place   IN         VARCHAR2    -- �\���n�R�[�h
    , id_process_date        IN         DATE        -- �Ɩ��������t
    , ov_errbuf              OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode             OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_dclr_place_mst';  -- �v���V�[�W����
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
    cv_declaration_place_mst    CONSTANT VARCHAR2(30) := 'XXCFF_DCLR_PLACE';  -- �l�Z�b�g�u�\���n�v
    cv_enabled_flag_enabled     CONSTANT VARCHAR2(1)  := 'Y';                 -- �l�Z�b�g�̗L���t���O�u�L���v
    --
    -- *** ���[�J���ϐ� ***
    lv_msg1       VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W(�m�[�g)
    lv_msg2       VARCHAR2(5000);  -- ���[�U�[�E���b�Z�[�W(�m�[�g)
    ln_cnt        NUMBER;
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
    -- �\���n�}�X�^���o
    -- ========================================
    BEGIN
      SELECT COUNT(1)             cnt
      INTO   ln_cnt
      FROM   fnd_flex_values      ffv
           , fnd_flex_values_tl   ffvt
           , fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_declaration_place_mst
      AND    id_process_date          BETWEEN TRUNC( NVL( ffv.start_date_active, id_process_date ) )
                                      AND     TRUNC( NVL( ffv.end_date_active,   id_process_date ) )
      AND    ffv.enabled_flag         = cv_enabled_flag_enabled
      AND    ffvt.language            = USERENV('LANG')
      AND    ffv.flex_value           = iv_declaration_place
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_msg2   := xxccp_common_pkg.get_msg(
                           iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                          ,iv_name        => cv_tkn_number_75           -- ���b�Z�[�W
                     );
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_73            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table                -- �g�[�N���R�[�h1
                       , iv_token_value1 => lv_msg2                     -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_err_msg              -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM                     -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- �Y���f�[�^�����݂��Ȃ��ꍇ
    IF ( ln_cnt = 0 ) THEN
      lv_msg1   := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                        ,iv_name        => cv_tkn_number_74           -- ���b�Z�[�W
                   );
      lv_msg2   := xxccp_common_pkg.get_msg(
                         iv_application => cv_sales_appl_short_name   -- �A�v���P�[�V�����Z�k��
                        ,iv_name        => cv_tkn_number_75           -- ���b�Z�[�W
                   );
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_72            -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_item                 -- �g�[�N���R�[�h1
                     , iv_token_value1 => lv_msg1                     -- �g�[�N���l1
                     , iv_token_name2  => cv_tkn_table                -- �g�[�N���R�[�h2
                     , iv_token_value2 => lv_msg2                     -- �g�[�N���l2
                     , iv_token_name3  => cv_tkn_base_value           -- �g�[�N���R�[�h3
                     , iv_token_value3 => iv_declaration_place        -- �g�[�N���l3
                   );
      --
      RAISE sql_expt;
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
  END check_dclr_place_mst;
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    --------------------------------------------------
    -- �����敪���u�����˗����F�v�̏ꍇ
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_aprv ) THEN
      RETURN;
    END IF;
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
    -- ========================================
    -- A-13. �������b�N����
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
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    --------------------------------------------------
    -- �����敪���u�����˗����F�v�̏ꍇ
    --------------------------------------------------
    IF ( iv_process_kbn = cv_proc_kbn_req_aprv ) THEN
      RETURN;
    END IF;
    --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
    -- ========================================
    -- A-13. �������b�N����
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
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
/* 20090511_abe_ST965 START*/
    cv_jotai_kbn3_ablsh_appl_0 CONSTANT VARCHAR2(1) := '0'; -- �@���ԂR�i�p�����j�u�\�薳���v
    cv_ablsh_flg_ablsh_appl_0  CONSTANT VARCHAR2(1) := '0'; -- �p���t���O�u���\���v
/* 20090511_abe_ST965 END*/
    --
    -- *** ���[�J���f�[�^�^ ***
    TYPE l_iea_val_ttype IS TABLE OF csi_iea_values%ROWTYPE INDEX BY BINARY_INTEGER;
    --
    -- *** ���[�J���ϐ� ***
    ln_instance_id    csi_item_instances.instance_id%TYPE;
    l_iea_val_rec     csi_iea_values%ROWTYPE;
    l_iea_val_tab     l_iea_val_ttype;
/* 20090511_abe_ST965 START*/
    ln_instance_status_id      NUMBER;                  -- �C���X�^���X�X�e�[�^�XID
    ln_machinery_status1       NUMBER;                  -- �@����1�i�ғ���ԁj
    ln_machinery_status2       NUMBER;                  -- �@����2�i��ԏڍׁj
    ln_machinery_status3       NUMBER;                  -- �@����3�i�p�����j
    ln_delete_flag             NUMBER;                  -- �폜�t���O
/* 20090511_abe_ST965 END*/
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
/* 20090511_abe_ST965 START*/
    chk_expt      EXCEPTION;
/* 20090511_abe_ST965 END*/
    
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
/* 20090511_abe_ST965 START*/
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
      l_instance_rec.instance_status_id     := gt_instance_status_id_4;    -- �C���X�^���X�X�e�[�^�XID�i�p���葱���j
/* 20090511_abe_ST965 END*/
/*20090416_yabuki_ST549 END*/
      --
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_on;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
/* 20090511_abe_ST965 START*/
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
      l_ext_attrib_values_tab(1).attribute_value       := cv_jotai_kbn3_ablsh_appl_0;
      l_ext_attrib_values_tab(1).object_version_number := l_iea_val_tab(1).object_version_number;
      --
      -- �p���t���O
      IF ( l_iea_val_tab(2).attribute_value_id IS NULL ) THEN
        l_ext_attrib_values_tab(2).attribute_id    := i_ib_ext_attr_id_rec.abolishment_flag;
        l_ext_attrib_values_tab(2).instance_id     := i_instance_rec.instance_id;
        l_ext_attrib_values_tab(2).attribute_value := cv_ablsh_flg_ablsh_appl_0;
        --
      ELSE
        l_ext_attrib_values_tab(2).attribute_value_id    := l_iea_val_tab(2).attribute_value_id;
        l_ext_attrib_values_tab(2).attribute_value       := cv_ablsh_flg_ablsh_appl_0;
        l_ext_attrib_values_tab(2).object_version_number := l_iea_val_tab(2).object_version_number;
        --
      END IF;

      ln_machinery_status1  := i_instance_rec.jotai_kbn1;
      ln_machinery_status2  := i_instance_rec.jotai_kbn2;
      ln_machinery_status3  := i_instance_rec.jotai_kbn3;
      ln_delete_flag        := i_instance_rec.delete_flag;
      -- ========================
      -- 2.�@���Ԑ������`�F�b�N
      -- ========================
      -- �폜�t���O���u�X�F�_���폜�v�̏ꍇ
      IF (ln_delete_flag = cn_num9) THEN
        ln_instance_status_id := gt_instance_status_id_6;
      -- �@���ԂP���u�Q�F�ؗ��v
      -- �@���ԂQ���u�O�F��񖳁v�܂��́u�P�F�����ρv
      ELSIF (ln_machinery_status1 = cn_num2
               AND (ln_machinery_status2 = cn_num0 OR ln_machinery_status2 = cn_num1))THEN
        ln_instance_status_id := gt_instance_status_id_2;
      -- �@���ԂP���u�Q�F�ؗ��v
      -- �@���ԂQ���u�Q�F�����\��v�܂��́u�R�F�ۊǁv�܂��́u�X�F�̏ᒆ�v
      ELSIF (ln_machinery_status1 = cn_num2
               AND (ln_machinery_status2 = cn_num2 OR
                      /* 2009.07.14 K.Satomura �����e�X�g��Q�Ή�(0000476) START */
                      --ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num4)) THEN
                      ln_machinery_status2 = cn_num3 OR ln_machinery_status2 = cn_num9)) THEN
                      /* 2009.07.14 K.Satomura �����e�X�g��Q�Ή�(0000476) END */
        ln_instance_status_id := gt_instance_status_id_3;
      -- �@���ԕs��
      ELSE
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_sales_appl_short_name      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_52              -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_task_nm                -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_machinery_status           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_bukken                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => i_instance_rec.install_code   -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_hazard_state1          -- �g�[�N���R�[�h3
                       ,iv_token_value3 => TO_CHAR(ln_machinery_status1) -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_hazard_state2          -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR(ln_machinery_status2) -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_hazard_state3          -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR(ln_machinery_status3) -- �g�[�N���l5
                     );
        RAISE chk_expt;
      END IF; 
      l_instance_rec.instance_status_id     := ln_instance_status_id;    -- �C���X�^���X�X�e�[�^�XID
/* 20090511_abe_ST965 END*/
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
/* 20090511_abe_ST965 START*/
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
/* 20090511_abe_ST965 END*/
/*20090416_yabuki_ST549 END*/
      --
      ------------------------------
      -- �C���X�^���X���R�[�h�ݒ�
      ------------------------------
      l_instance_rec.instance_id            := i_instance_rec.instance_id;
      l_instance_rec.attribute4             := cv_op_req_flag_off;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
      l_instance_rec.object_version_number  := i_instance_rec.obj_ver_num;
      l_instance_rec.request_id             := fnd_global.conc_request_id;
      l_instance_rec.program_application_id := fnd_global.prog_appl_id;
      l_instance_rec.program_id             := fnd_global.conc_program_id;
      l_instance_rec.program_update_date    := SYSDATE;
/*20090416_yabuki_ST549 START*/
/* 20090511_abe_ST965 START*/
--      l_instance_rec.instance_status_id     := gt_instance_status_id_4;    -- �C���X�^���X�X�e�[�^�XID�i�p���葱���j
/* 20090511_abe_ST965 END*/
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
    -- A-13. �������b�N����
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
/* 20090511_abe_ST965 START*/
    WHEN chk_expt THEN
      -- *** �`�F�b�N�G���[�n���h�� ***
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
/* 20090511_abe_ST965 END*/
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
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := i_requisition_rec.requisition_number
                                               || cv_slash || i_requisition_rec.install_at_customer_code;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
      l_instance_rec.attribute8             := NULL;
      /* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
    -- A-13. �������b�N����
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    cv_wf_xxcso_ib_chk_subject        CONSTANT VARCHAR2(30) := 'XXCSO_IB_CHK_SUBJECT';
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    -- ����
    wf_engine.setitemattrtext(
        itemtype => cv_wf_itemtype
      , itemkey  => lv_itemkey
      , aname    => cv_wf_xxcso_ib_chk_subject
      , avalue   => cv_tkn_subject1 || gv_requisition_number || cv_tkn_subject3
    );
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
/* 20090515_abe_ST669 START*/
  /**********************************************************************************
   * Procedure Name   : VerifyAuthority
   * Description      : ���F�Ҍ����i���i�j�`�F�b�N(A-22)
   ***********************************************************************************/
  FUNCTION VerifyAuthority(itemtype VARCHAR2, itemkey VARCHAR2) RETURN VARCHAR2 is

  L_DM_CALL_REC  PO_DOC_MANAGER_PUB.DM_CALL_REC_TYPE;

  x_progress varchar2(200);
  BEGIN


    L_DM_CALL_REC.Action := 'VERIFY_AUTHORITY_CHECK';

    L_DM_CALL_REC.Document_Type    :=  wf_engine.GetItemAttrText (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'DOCUMENT_TYPE');

    L_DM_CALL_REC.Document_Subtype :=  wf_engine.GetItemAttrText (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'DOCUMENT_SUBTYPE');

    L_DM_CALL_REC.Document_Id      :=  wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'DOCUMENT_ID');


    L_DM_CALL_REC.Line_Id          := NULL;
    L_DM_CALL_REC.Shipment_Id      := NULL;
    L_DM_CALL_REC.Distribution_Id  := NULL;
    L_DM_CALL_REC.Employee_id      := wf_engine.GetItemAttrNumber (itemtype => itemtype,
                                           itemkey  => itemkey,
                                           aname    => 'APPROVER_EMPID');

    L_DM_CALL_REC.New_Document_Status  := NULL;
    L_DM_CALL_REC.Offline_Code     := NULL;

    L_DM_CALL_REC.Note             := NULL;

    L_DM_CALL_REC.Approval_Path_Id := NULL;

    L_DM_CALL_REC.Forward_To_Id    := NULL;

    L_DM_CALL_REC.Action_date    := NULL;

    L_DM_CALL_REC.Override_funds    := NULL;

  -- Below are the output parameters

    L_DM_CALL_REC.Info_Request     := NULL;

    L_DM_CALL_REC.Document_Status  := NULL;

    L_DM_CALL_REC.Online_Report_Id := NULL;

    L_DM_CALL_REC.Return_Code      := NULL;

    L_DM_CALL_REC.Error_Msg        := NULL;

    /* This is the variable that contains the return value from the
    ** call to the DOC MANAGER:
    ** SUCCESS =0,  TIMEOUT=1,  NO MANAGER=2,  OTHER=3
    */
    L_DM_CALL_REC.Return_Value    := NULL;

    /* Call the API that calls the Document manager */

    PO_DOC_MANAGER_PUB.CALL_DOC_MANAGER(L_DM_CALL_REC);


    IF L_DM_CALL_REC.Return_Value = 0 THEN

       IF ( L_DM_CALL_REC.Return_Code is NULL )  THEN

          return('Y');

       ELSE

          return('N');

       END IF;

    ELSE
       return('F');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
       return('F');
  END VerifyAuthority;
/* 20090515_abe_ST669 END*/
/*20090701_abe_ST529 START*/
  --
  /**********************************************************************************
   * Procedure Name   : update_po_req_line
   * Description      : �����˗����׍X�V����(A-23)
   ***********************************************************************************/
  PROCEDURE update_po_req_line(
      i_requisition_rec  IN         g_requisition_rtype  -- �����˗����
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'update_po_req_line';  -- �v���V�[�W����
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
    -- �����˗����׍X�V����
    --------------------------------------------------
    BEGIN
      UPDATE po_requisition_lines_all
      SET    transaction_reason_code = i_requisition_rec.un_number
      WHERE  requisition_line_id     = i_requisition_rec.requisition_line_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                   -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_53                           -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_req_num                             -- �g�[�N���R�[�h1
                       , iv_token_value1 => i_requisition_rec.requisition_number       -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_req_line_num                        -- �g�[�N���R�[�h2
                       , iv_token_value2 => i_requisition_rec.requisition_line_number  -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_err_msg                             -- �g�[�N���R�[�h3
                       , iv_token_value3 => SQLERRM                                    -- �g�[�N���l3
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
  END update_po_req_line;
/*20090701_abe_ST529 END*/
  --
/* 20090708_abe_0000464 START*/
  /**********************************************************************************
   * Procedure Name   : check_maker_code
   * Description      : ���[�J�[�R�[�h�`�F�b�N����(A-24)
   ***********************************************************************************/
  PROCEDURE check_maker_code(
      id_process_date    IN  DATE                       -- �Ɩ��������t
    , i_requisition_rec  IN  g_requisition_rtype        -- �����˗����
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_maker_code';  -- �v���V�[�W����
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
    cv_lookup_cd_maker_code    CONSTANT VARCHAR2(30) := 'XXCSO1_PO_CATEGORY_TYPE';  -- �Q�ƃ^�C�v�u�i�ڃJ�e�S���i�c�Ɓj�v
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
    -- �i�ڃJ�e�S���i�c�Ɓj���o
    -- ========================================
    BEGIN
      SELECT COUNT( flvv.lookup_code )  cnt
      INTO   ln_cnt_rec
      FROM   fnd_lookup_values_vl  flvv
            ,mtl_categories_b     mcb
      WHERE  flvv.lookup_type  = cv_lookup_cd_maker_code
      AND    flvv.attribute2   = i_requisition_rec.maker_code
      AND    TRUNC( id_process_date ) BETWEEN TRUNC( NVL( flvv.start_date_active, id_process_date ) )
                              AND     TRUNC( NVL( flvv.end_date_active, id_process_date ) )
      AND    flvv.enabled_flag = cv_enabled_flag_enabled
      AND    flvv.meaning      = mcb.segment1
      AND    mcb.category_id   = i_requisition_rec.category_id
      AND    TRUNC( id_process_date ) BETWEEN TRUNC( NVL( mcb.start_date_active, id_process_date ) )
                              AND     TRUNC( NVL( mcb.end_date_active, id_process_date ) )
      AND    mcb.enabled_flag  = cv_enabled_flag_enabled
      ;
      --
      -- �Y���f�[�^�����݂��Ȃ��ꍇ
      IF ( ln_cnt_rec = 0 ) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_54            -- ���b�Z�[�W�R�[�h
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
                       , iv_name         => cv_tkn_number_54            -- ���b�Z�[�W�R�[�h
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
  END check_maker_code;
  --
/* 20090708_abe_0000464 END*/
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
  --
  /**********************************************************************************
   * Procedure Name   : check_business_low_type
   * Description      : �Ƒ�(������)�`�F�b�N����(A-25)
   ***********************************************************************************/
  PROCEDURE check_business_low_type(
      i_requisition_rec   IN         g_requisition_rtype   -- �����˗����
    , ov_errbuf           OUT NOCOPY VARCHAR2              -- �G���[�E���b�Z�[�W --# �Œ� #
    , ov_retcode          OUT NOCOPY VARCHAR2              -- ���^�[���E�R�[�h   --# �Œ� #
  ) IS
    --
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'check_business_low_type';  -- �v���V�[�W����
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
    cv_party_sts_active       CONSTANT VARCHAR2(1) := 'A';   -- �p�[�e�B�X�e�[�^�X�u�L���v
    cv_account_sts_active     CONSTANT VARCHAR2(1) := 'A';   -- �A�J�E���g�X�e�[�^�X�u�L���v
    cv_acct_site_sts_active   CONSTANT VARCHAR2(1) := 'A';   -- �ڋq���ݒn�X�e�[�^�X�u�L���v
    cv_party_site_sts_active  CONSTANT VARCHAR2(1) := 'A';   -- �p�[�e�B�T�C�g�X�e�[�^�X�u�L���v
    --
    ct_cust_cl_cd_cust        CONSTANT xxcso_cust_acct_sites_v.customer_class_code%TYPE := '10'; -- �ڋq�敪=�ڋq
    --
    ct_bsns_lwtp_fll_s_sk     CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '24';   -- 24�F�t���T�[�r�X�i�����jVD
    ct_bsns_lwtp_fll_s        CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '25';   -- 25�F�t���T�[�r�XVD
    ct_bsns_lwtp_nouhin       CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '26';   -- 26�F�[�iVD
    ct_bsns_lwtp_sk           CONSTANT xxcso_cust_acct_sites_v.business_low_type%TYPE := '27';   -- 27�F����VD
    --
    cv_hzrd_cls_jihanki       CONSTANT VARCHAR2(1) := '1';   -- �@��敪�i�댯�x�敪�j "1:�̔��@"
    --
    cv_po_un_num              CONSTANT VARCHAR2(100) := '�@��}�X�^��';
    cv_un_num                 CONSTANT VARCHAR2(100) := '�@��R�[�h';
    cv_hzrd_cls               CONSTANT VARCHAR2(100) := '�@��敪';
    -- *** ���[�J���ϐ� ***
    lt_business_low_type      xxcso_cust_acct_sites_v.business_low_type%TYPE;   -- �Ƒԁi�����ށj
    lt_customer_class_code    xxcso_cust_acct_sites_v.customer_class_code%TYPE; -- �ڋq�敪
/* 2014.08.29 S.Yamashita E_�{�ғ�_11719�Ή� START */
--    lv_hazard_class           VARCHAR2(1);                                      -- �@��敪�i�댯�x�敪�j
    lv_hazard_class           po_hazard_classes_tl.hazard_class%type;           -- �@��敪�i�댯�x�敪�j
/* 2014.08.29 S.Yamashita E_�{�ғ�_11719�Ή� end   */
    /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� start */  
    lv_un_number              po_un_numbers_vl.un_number%TYPE; --�@��CD
    /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� end */  
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
      SELECT casv.business_low_type    business_low_type      -- �Ƒԁi�����ށj
            ,casv.customer_class_code  customer_class_code    -- �ڋq�敪�R�[�h
      INTO   lt_business_low_type
            ,lt_customer_class_code
      FROM   xxcso_cust_acct_sites_v  casv    -- �ڋq�}�X�^�T�C�g�r���[
      WHERE casv.account_number    = i_requisition_rec.install_at_customer_code
      AND   casv.account_status    = cv_account_sts_active
      AND   casv.acct_site_status  = cv_acct_site_sts_active
      AND   casv.party_status      = cv_party_sts_active
      AND   casv.party_site_status = cv_party_site_sts_active
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_32                            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_kokyaku                              -- �g�[�N���R�[�h1
                       , iv_token_value1 => i_requisition_rec.install_at_customer_code  -- �g�[�N���l1
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name                    -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_33                            -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_kokyaku                              -- �g�[�N���R�[�h1
                       , iv_token_value1 => i_requisition_rec.install_at_customer_code  -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_err_msg                              -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM                                     -- �g�[�N���l2
                     );
        --
        RAISE sql_expt;
        --
    END;
    -- ========================================
    -- �@��}�X�^���o
    -- ========================================
    /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� start */ 
    IF i_requisition_rec.category_kbn in (cv_category_kbn_new_install, cv_category_kbn_new_replace) THEN
      --�V��ݒu�E�V���֥��iPro�w���˗��̋@��CD
      lv_un_number := i_requisition_rec.un_number;
    ELSE
      --����ݒu�E�����֥���ݒu�p����CD����擾�����@��CD
      BEGIN
        SELECT  attribute1              --�@��CD
        INTO    lv_un_number
        FROM    csi_item_instances cii
        WHERE   cii.external_reference = i_requisition_rec.install_code
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_un_number := NULL;
      END;
    --
    END IF; 
    /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� end */ 
    
    
    BEGIN
/* 2014.08.29 S.Yamashita E_�{�ғ�_11719�Ή� START */
--      SELECT SUBSTRB(phcv.hazard_class,1,1)         -- �@��敪�i�댯�x�敪�j
      SELECT SUBSTRB(phcv.hazard_class,1,INSTRB(phcv.hazard_class,cv_msg_part_only,1,1)-1)         -- �@��敪�i�댯�x�敪�j
/* 2014.08.29 S.Yamashita E_�{�ғ�_11719�Ή� END */
      INTO   lv_hazard_class
      FROM   po_un_numbers_vl     punv              -- ���A�ԍ��}�X�^�r���[
            ,po_hazard_classes_vl phcv              -- �댯�x�敪�}�X�^�r���[
      /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� start */
      --WHERE  punv.un_number        = i_requisition_rec.un_number
      WHERE  punv.un_number        = lv_un_number
      /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� end */
      AND    punv.hazard_class_id  = phcv.hazard_class_id
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �Y���f�[�^�����݂��Ȃ��ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name             -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_48                     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_task_nm                       -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_hzrd_cls                          -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_item                          -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_un_num                            -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_value                         -- �g�[�N���R�[�h3
                       /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� start */
                       --, iv_token_value3 => TO_CHAR(i_requisition_rec.un_number) -- �g�[�N���l3
                       , iv_token_value3 => lv_un_number -- �g�[�N���l3
                       /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� end */
                     );
        --
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        -- ���̑��̗�O�̏ꍇ
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application  => cv_sales_appl_short_name             -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_tkn_number_61                     -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_task_nm                       -- �g�[�N���R�[�h1
                       , iv_token_value1 => cv_po_un_num                         -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_item                          -- �g�[�N���R�[�h2
                       , iv_token_value2 => cv_un_num                            -- �g�[�N���l2
                       , iv_token_name3  => cv_tkn_base_val                      -- �g�[�N���R�[�h3
                       /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� start */
                       --, iv_token_value3 => TO_CHAR(i_requisition_rec.un_number) -- �g�[�N���l3
                       , iv_token_value3 => lv_un_number -- �g�[�N���l3
                       /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� end */
                       , iv_token_name4  => cv_tkn_err_msg                       -- �g�[�N���R�[�h4
                       , iv_token_value4 => SQLERRM                              -- �g�[�N���l4
                     );
        --
        RAISE sql_expt;
        --
    END;
    --
    -- �ڋq�̋Ƒԏ����ނ��u24�F�t���T�[�r�X�i�����jVD�v�u25�F�t���T�[�r�XVD�v�u26�F�[�iVD�v�u27�F����VD �v�ȊO�Ŋ��A
    -- �ڋq�̌ڋq�敪���u10�F�ڋq�v���A�@��敪�i�댯�x�敪�j��"1:�̔��@"�̏ꍇ�̓G���[
    IF (  ( lt_business_low_type   NOT IN ( ct_bsns_lwtp_fll_s_sk
                                           ,ct_bsns_lwtp_fll_s
                                           ,ct_bsns_lwtp_nouhin
                                           ,ct_bsns_lwtp_sk ))
      AND ( lt_customer_class_code = ct_cust_cl_cd_cust )
      AND ( lv_hazard_class        = cv_hzrd_cls_jihanki )  ) THEN
      --
      lv_errbuf := xxccp_common_pkg.get_msg(
                       iv_application  => cv_sales_appl_short_name             -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_tkn_number_62                     -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_kisyucd                       -- �g�[�N���R�[�h1
                     /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� start */
                     --, iv_token_value1 => TO_CHAR(i_requisition_rec.un_number) -- �g�[�N���l1
                     , iv_token_value1 => lv_un_number -- �g�[�N���l1
                     /* 2010.04.01 maruyama E_�{�ғ�_02133 ��Ƌ敪�ɂ���ċ@��̎擾���ύX���� end */
                   );
      --
      RAISE sql_expt;
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
  END check_business_low_type;
  --
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
    -- �����敪���u�����˗��\���v�u�����˗����F�v�̏ꍇ
    ----------------------------------------------------------------------
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    --IF ( iv_process_kbn = cv_proc_kbn_req_appl ) THEN
    IF ( iv_process_kbn = cv_proc_kbn_req_appl
      OR iv_process_kbn = cv_proc_kbn_req_aprv )
    THEN
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
      --------------------------------------------------
      -- �J�e�S���敪���u�V��ݒu�v�̏ꍇ
      --------------------------------------------------
      IF ( l_requisition_rec.category_kbn = cv_category_kbn_new_install ) THEN
        /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� START */
        -- ================================================
        -- A-26. �A�v���P�[�V�����\�[�X�R�[�h�`�F�b�N����
        -- ================================================
        -- �A�v���P�[�V�����\�[�X�R�[�h��NULL�Ȃ�΃G���[
        IF ( l_requisition_rec.apps_source_code IS NULL ) THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name             -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_66                     -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_req_num                       -- �g�[�N���R�[�h1
                         , iv_token_value1 => l_requisition_rec.requisition_number -- �g�[�N���l1
                       );
          RAISE global_process_expt;
        END IF;
        /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� END   */
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �@��R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_01  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
        ------------------------------
        -- ��Ɖ��CD���[�J�[�`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_11 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
        ------------------------------
        -- ���g����͕s�`�F�b�N�`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_12 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
        ------------------------------
        -- �ڋq�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        ------------------------------
        -- ��Ɖ�БÓ����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
        ------------------------------
        -- �\���n�K�{���̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_16 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
        ------------------------------
        -- ����E�S�����_�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
/* 20090708_abe_0000464 START*/
        -- ========================================
        -- A-24. ���[�J�[�R�[�h�`�F�b�N����
        -- ========================================
        check_maker_code(
            id_process_date       => ld_process_date      -- �Ɩ��������t
          , i_requisition_rec     => l_requisition_rec    -- �����˗����
          , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 20090708_abe_0000464 END*/
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
        -- ========================================
        -- A-25. �Ƒ�(������)�`�F�b�N����
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- �����˗����
          , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
        -- ========================================
        -- A-27. �\���n�}�X�^���݃`�F�b�N����
        -- ========================================
        check_dclr_place_mst(
            iv_declaration_place  => l_requisition_rec.declaration_place    -- �\���n
          , id_process_date       => ld_process_date                        -- �Ɩ��������t
          , ov_errbuf             => lv_errbuf                              -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                             -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
      --------------------------------------------------
      -- �J�e�S���敪���u�V���ցv�̏ꍇ
      --------------------------------------------------
      ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_replace ) THEN
        /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� START */
        -- ================================================
        -- A-26. �A�v���P�[�V�����\�[�X�R�[�h�`�F�b�N����
        -- ================================================
        -- �A�v���P�[�V�����\�[�X�R�[�h��NULL�Ȃ�΃G���[
        IF ( l_requisition_rec.apps_source_code IS NULL ) THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                           iv_application  => cv_sales_appl_short_name             -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_tkn_number_66                     -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_req_num                       -- �g�[�N���R�[�h1
                         , iv_token_value1 => l_requisition_rec.requisition_number -- �g�[�N���l1
                       );
          RAISE global_process_expt;
        END IF;
        /* 2013.04.04 T.Ishiwata E_�{�ғ�_10321�Ή� END   */
        --
        -- ========================================
        -- A-3. ���̓`�F�b�N����
        -- ========================================
        ------------------------------
        -- �@��R�[�h�K�{���̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_01  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date    => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date    => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date    => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
        ------------------------------
        -- ��Ɖ��CD���[�J�[�`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_11 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date    => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
        ------------------------------
        -- ���g�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
            iv_chk_kbn        => cv_input_chk_kbn_08  -- �`�F�b�N�敪
          , i_requisition_rec => l_requisition_rec    -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date    => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
        ------------------------------
        -- �ڋq�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date    => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        ------------------------------
        -- ���g��(������)�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_14 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- ��Ɖ�БÓ����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
        ------------------------------
        -- �\���n�K�{���̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_16 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
        ------------------------------
        -- ����E�S�����_�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                           -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
/* 20090708_abe_0000464 START*/
        -- ========================================
        -- A-24. ���[�J�[�R�[�h�`�F�b�N����
        -- ========================================
        check_maker_code(
            id_process_date       => ld_process_date      -- �Ɩ��������t
          , i_requisition_rec     => l_requisition_rec    -- �����˗����
          , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 20090708_abe_0000464 END*/
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� START */
        -- ========================================
        -- A-25. �Ƒ�(������)�`�F�b�N����
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- �����˗����
          , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
        -- ========================================
        -- A-27. �\���n�}�X�^���݃`�F�b�N����
        -- ========================================
        check_dclr_place_mst(
            iv_declaration_place  => l_requisition_rec.declaration_place    -- �\���n
          , id_process_date       => ld_process_date                        -- �Ɩ��������t
          , ov_errbuf             => lv_errbuf                              -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode                             -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
/* 2010.01.25 K.Hosoi E_�{�ғ�_00533,00319�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
        ------------------------------
        -- ���g����͕s�`�F�b�N�`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_12 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
        ------------------------------
        -- �ڋq�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        ------------------------------
        -- ��Ɖ�БÓ����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
        ------------------------------
        -- ����E�S�����_�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                  -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
          -- A-10. �����X�e�[�^�X�`�F�b�N����
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_01           -- �`�F�b�N�敪�i�`�F�b�N�ΏہF�ݒu�p�����j
            , iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
            /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
            , id_process_date => ld_process_date                 -- �Ɩ��������t
            , iv_process_kbn  => iv_process_kbn                  -- �����敪
            /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
            /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
            , iv_lease_kbn          => l_instance_rec.lease_kbn  -- ���[�X�敪
            , iv_instance_type_code => NULL                      -- �C���X�^���X�^�C�v�R�[�h
            /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
            , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
            , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
        -- ���[�X�敪���u�Œ莑�Y�v�̏ꍇ
        ELSIF ( l_instance_rec.lease_kbn = cv_fixed_assets ) THEN
          ------------------------------
          -- �\���n�K�{���̓`�F�b�N �������}�X�^�̏�񂪕K�v�ȈׁA�����Ń`�F�b�N
          ------------------------------
          input_check(
             iv_chk_kbn        => cv_input_chk_kbn_16 -- �`�F�b�N�敪
            ,i_requisition_rec => l_requisition_rec   -- �����˗����
            ,id_process_date   => ld_process_date     -- �Ɩ��������t
            ,ov_errbuf         => lv_errbuf           -- �G���[�E���b�Z�[�W  --# �Œ� #
            ,ov_retcode        => lv_retcode          -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          -- ����I���łȂ��ꍇ
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE input_check_expt;
          END IF;
          --
          -- ========================================
          -- A-27. �\���n�}�X�^���݃`�F�b�N����
          -- ========================================
          check_dclr_place_mst(
              iv_declaration_place  => l_requisition_rec.declaration_place    -- �\���n
            , id_process_date       => ld_process_date                        -- �Ɩ��������t
            , ov_errbuf             => lv_errbuf                              -- �G���[�E���b�Z�[�W  --# �Œ� #
            , ov_retcode            => lv_retcode                             -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        -- ========================================
        -- A-25. �Ƒ�(������)�`�F�b�N����
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- �����˗����
          , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
        ------------------------------
        -- �ڋq�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        ------------------------------
        -- ���g��(������)�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_14 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- ��Ɖ�БÓ����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
        ------------------------------
        -- ����E�S�����_�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                  -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                           -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
          -- A-10. �����X�e�[�^�X�`�F�b�N����
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_01           -- �`�F�b�N�敪�i�`�F�b�N�ΏہF�ݒu�p�����j
            , iv_install_code => l_requisition_rec.install_code  -- �ݒu�p�����R�[�h
            /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
            , id_process_date => ld_process_date                 -- �Ɩ��������t
            , iv_process_kbn  => iv_process_kbn                  -- �����敪
            /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
            /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
            , iv_lease_kbn          => l_instance_rec.lease_kbn  -- ���[�X�敪
            , iv_instance_type_code => NULL                      -- �C���X�^���X�^�C�v�R�[�h
            /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
            , ov_errbuf       => lv_errbuf                       -- �G���[�E���b�Z�[�W  --# �Œ� #
            , ov_retcode      => lv_retcode                      -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
        -- ���[�X�敪���u�Œ莑�Y�v�̏ꍇ
        ELSIF ( l_instance_rec.lease_kbn = cv_fixed_assets ) THEN
          ------------------------------
          -- �\���n�K�{���̓`�F�b�N �������}�X�^�i���[�X�敪�j���K�v�ȈׁA�����Ń`�F�b�N
          ------------------------------
          input_check(
             iv_chk_kbn        => cv_input_chk_kbn_16 -- �`�F�b�N�敪
            ,i_requisition_rec => l_requisition_rec   -- �����˗����
            ,id_process_date   => ld_process_date     -- �Ɩ��������t
            ,ov_errbuf         => lv_errbuf           -- �G���[�E���b�Z�[�W  --# �Œ� #
            ,ov_retcode        => lv_retcode          -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          -- ����I���łȂ��ꍇ
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE input_check_expt;
          END IF;
          --
          -- ========================================
          -- A-27. �\���n�}�X�^���݃`�F�b�N����
          -- ========================================
          check_dclr_place_mst(
              iv_declaration_place  => l_requisition_rec.declaration_place    -- �\���n
            , id_process_date       => ld_process_date                        -- �Ɩ��������t
            , ov_errbuf             => lv_errbuf                              -- �G���[�E���b�Z�[�W  --# �Œ� #
            , ov_retcode            => lv_retcode                             -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
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
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        -- ========================================
        -- A-25. �Ƒ�(������)�`�F�b�N����
        -- ========================================
        check_business_low_type(
            i_requisition_rec     => l_requisition_rec    -- �����˗����
          , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
        ------------------------------
        -- �ڋq�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        ------------------------------
        -- ���g��(������)�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_14 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        ------------------------------
        -- ��Ɖ�БÓ����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
        ------------------------------
        -- ����E�S�����_�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                           -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
         /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
         -- ���g������Ɖ�Ђ͎w�肷��K�v�����邽�߃`�F�b�N�𕜊�������
        ----------------------------------------
        -- �`�F�b�N�ΏہF�ݒu��Ɖ�ЁA���Ə�
        ----------------------------------------
        check_syozoku_mst(
           iv_work_company_code  => l_requisition_rec.work_company_code  -- ��Ɖ�ЃR�[�h
          ,iv_work_location_code => l_requisition_rec.work_location_code -- ���Ə��R�[�h
          ,ov_errbuf             => lv_errbuf                            -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode            => lv_retcode                           -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
          --
        END IF;
         /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                              -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                              -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
          /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
--          /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� START */
--          , id_process_date => ld_process_date                             -- �Ɩ��������t
--          /* 2013.12.05 T.Nakano E_�{�ғ�_11082�Ή� END */
          /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
          , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
          , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
--/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
--        -- ���[�X�敪���u���Ѓ��[�X�v�̏ꍇ
--        IF ( l_abolishment_instance_rec.lease_kbn = cv_own_company_lease ) THEN
--/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
        -- ���[�X�敪���u���Ѓ��[�X�v�A�u�Œ莑�Y�v�̏ꍇ
        IF ( l_abolishment_instance_rec.lease_kbn IN ( cv_own_company_lease, cv_fixed_assets ) ) THEN
/* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
          -- ========================================
          -- A-10. �����X�e�[�^�X�`�F�b�N����
          -- ========================================
          check_object_status(
              iv_chk_kbn      => cv_obj_sts_chk_kbn_02                       -- �`�F�b�N�敪�i�`�F�b�N�ΏہF�p���p�����j
            , iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
            /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� START */
            , id_process_date => ld_process_date                             -- �Ɩ��������t
            , iv_process_kbn  => iv_process_kbn                              -- �����敪
            /* 2014.04.30 T.Nakano E_�{�ғ�_11770�Ή� END */
            /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� START */
            , iv_lease_kbn          => l_abolishment_instance_rec.lease_kbn          -- ���[�X�敪
            , iv_instance_type_code => l_abolishment_instance_rec.instance_type_code -- �C���X�^���X�^�C�v�R�[�h
            /* 2014-05-13 K.Nakamura E_�{�ғ�_11853�Ή� END */
            , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
            , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
            --
          END IF;
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) START */
        END IF;
/* 2009.07.16 K.Hosoi �����e�X�g��Q�Ή�(0000375,0000419) END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          , id_process_date   => ld_process_date      -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
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
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� START */
        ------------------------------
        -- ���g����͕s�`�F�b�N�`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_12 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          --lv_errbuf  := lv_errbuf2;
          --lv_retcode := lv_retcode2;
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.11.25 K.Satomura E_�{�ғ�_00119�Ή� END */
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� START */
        ------------------------------
        -- �ڋq�֘A�����̓`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_13 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2009.12.24 K.Hosoi E_�{�ғ�_00563�Ή� END */
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� START */
        ------------------------------
        -- ��Ɖ�БÓ����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_15 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2010.03.08 K.Hosoi E_�{�ғ�_01838,01839�Ή� END */
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� START */
        ------------------------------
        -- ����E�S�����_�Ó����`�F�b�N
        ------------------------------
        input_check(
           iv_chk_kbn        => cv_input_chk_kbn_17 -- �`�F�b�N�敪
          ,i_requisition_rec => l_requisition_rec   -- �����˗����
          ,id_process_date   => ld_process_date     -- �Ɩ��������t
          ,ov_errbuf         => lv_errbuf2          -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode2         -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        -- ����I���łȂ��ꍇ
        IF (lv_retcode2 <> cv_status_normal) THEN
          lv_errbuf  := CASE WHEN ( lv_errbuf IS NULL )
                             THEN lv_errbuf2
                             ELSE SUBSTRB( lv_errbuf || cv_msg_comma ||  lv_errbuf2, 1, 5000 ) END;
          lv_retcode := lv_retcode2;
          --
          -- �ُ�I���̏ꍇ
          IF (lv_retcode2 = cv_status_error) THEN
            RAISE input_check_expt;
            --
          END IF;
          --
        END IF;
        /* 2015-01-13 T.Sano E_�{�ғ�_12289�Ή� END */
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
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
          , iv_process_kbn  => iv_process_kbn                  -- �����敪
          /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
      /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
      IF (iv_process_kbn = cv_proc_kbn_req_aprv) THEN
        -- �����敪���u�����˗����F�v�̏ꍇ
        -- ========================================
        -- A-18. ��ƈ˗��^�������A�g�Ώۃe�[�u�����݃`�F�b�N����
        -- ========================================
        chk_wk_req_proc(
           i_requisition_rec => l_requisition_rec -- �����˗����
          ,on_rec_count      => ln_rec_count      -- ���R�[�h�����i��ƈ˗��^�������A�g�Ώۃe�[�u���j
          ,ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
        -- ��ƈ˗��^�������A�g�Ώۃe�[�u���ɊY�����郌�R�[�h�����݂��Ȃ��ꍇ
        IF (ln_rec_count = cn_zero) THEN
          -- ========================================
          -- A-19. ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����
          -- ========================================
          insert_wk_req_proc(
             i_requisition_rec => l_requisition_rec -- �����˗����
            ,ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W  --# �Œ� #
            ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE reg_upd_process_expt;
            --
          END IF;
          --
        ELSE
          -- ========================================
          -- A-20. ��ƈ˗��^�������A�g�Ώۃe�[�u���X�V����
          -- ========================================
          update_wk_req_proc(
             i_requisition_rec => l_requisition_rec -- �����˗����
            ,ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W  --# �Œ� #
            ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h    --# �Œ� #
          );
          --
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE reg_upd_process_expt;
            --
          END IF;
          --
        END IF;
        --
        -- ========================================
        -- A-23. �����˗����׍X�V����
        -- ========================================
        update_po_req_line(
           i_requisition_rec => l_requisition_rec -- �����˗����
          ,ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W  --# �Œ� #
          ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h    --# �Œ� #
        );
        --
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE reg_upd_process_expt;
          --
        END IF;
        --
      END IF;
      --
      /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
    ----------------------------------------------------------------------
    -- �����敪���u�����˗����F�v�̏ꍇ
    ----------------------------------------------------------------------
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    --ELSIF ( iv_process_kbn = cv_proc_kbn_req_aprv ) THEN
    --  --------------------------------------------------
    --  -- �J�e�S���敪���u�p���\���v�̏ꍇ
    --  --------------------------------------------------
    --  IF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_appl ) THEN
    --    -- ========================================
    --    -- A-4. �����}�X�^���݃`�F�b�N����
    --    -- ========================================
    --    check_ib_existence(
    --        iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
    --      , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
    --      , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --    -- ========================================
    --    -- A-16. �p���\���p�����X�V����
    --    -- ========================================
    --    update_abo_appl_ib_info(
    --        iv_process_kbn         => iv_process_kbn              -- �����敪
    --      , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
    --      , i_requisition_rec      => l_requisition_rec           -- �����˗����
    --      , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
    --      , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
    --      , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --  --------------------------------------------------
    --  -- �J�e�S���敪���u�p�����فv�̏ꍇ
    --  --------------------------------------------------
    --  ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_ablsh_dcsn ) THEN
    --    --
    --    -- ========================================
    --    -- A-4. �����}�X�^���݃`�F�b�N����
    --    -- ========================================
    --    check_ib_existence(
    --        iv_install_code => l_requisition_rec.abolishment_install_code  -- �p��_�����R�[�h
    --      , o_instance_rec  => l_abolishment_instance_rec                  -- �������i�p���p�j
    --      , ov_errbuf       => lv_errbuf                                   -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode      => lv_retcode                                  -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --    -- ========================================
    --    -- A-17. �p�����ٗp�����X�V����
    --    -- ========================================
    --    update_abo_aprv_ib_info(
    --        iv_process_kbn         => iv_process_kbn              -- �����敪
    --      , id_process_date        => ld_process_date             -- �Ɩ��������t
    --      , i_instance_rec         => l_abolishment_instance_rec  -- �������i�p���p�j
    --      , i_requisition_rec      => l_requisition_rec           -- �����˗����
    --      , i_ib_ext_attr_id_rec   => l_ib_ext_attr_id_rec        -- IB�ǉ�����ID���
    --      , in_transaction_type_id => ln_transaction_type_id      -- ����^�C�vID
    --      , ov_errbuf              => lv_errbuf                   -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode             => lv_retcode                  -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --  /* 20090708_abe_0000464 START*/
    --  --------------------------------------------------
    --  -- �J�e�S���敪���u�V��ݒu�v�̏ꍇ
    --  --------------------------------------------------
    --  ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_install ) THEN
    --    -- ========================================
    --    -- A-24. ���[�J�[�R�[�h�`�F�b�N����
    --    -- ========================================
    --    check_maker_code(
    --        id_process_date       => ld_process_date      -- �Ɩ��������t
    --      , i_requisition_rec     => l_requisition_rec    -- �����˗����
    --      , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --  --------------------------------------------------
    --  -- �J�e�S���敪���u�V���ցv�̏ꍇ
    --  --------------------------------------------------
    --  ELSIF ( l_requisition_rec.category_kbn = cv_category_kbn_new_replace ) THEN
    --    -- ========================================
    --    -- A-24. ���[�J�[�R�[�h�`�F�b�N����
    --    -- ========================================
    --    check_maker_code(
    --        id_process_date       => ld_process_date      -- �Ɩ��������t
    --      , i_requisition_rec     => l_requisition_rec    -- �����˗����
    --      , ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE global_process_expt;
    --      --
    --    END IF;
    --    --
    --  /* 20090708_abe_0000464 END*/
    --  END IF;
    --  --
    --  /*20090406_yabuki_ST101 START*/
    --  -- ========================================
    --  -- A-18. ��ƈ˗��^�������A�g�Ώۃe�[�u�����݃`�F�b�N����
    --  -- ========================================
    --  chk_wk_req_proc(
    --      i_requisition_rec => l_requisition_rec  -- �����˗����
    --    , on_rec_count      => ln_rec_count       -- ���R�[�h�����i��ƈ˗��^�������A�g�Ώۃe�[�u���j
    --    , ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W  --# �Œ� #
    --    , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h    --# �Œ� #
    --  );
    --  --
    --  IF ( lv_retcode <> cv_status_normal ) THEN
    --    RAISE reg_upd_process_expt;
    --    --
    --  END IF;
    --  --
    --  -- ��ƈ˗��^�������A�g�Ώۃe�[�u���ɊY�����郌�R�[�h�����݂��Ȃ��ꍇ
    --  IF ( ln_rec_count = cn_zero ) THEN
    --    -- ========================================
    --    -- A-19. ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����
    --    -- ========================================
--  --      -- ========================================
--  --      -- A-18. ��ƈ˗��^�������A�g�Ώۃe�[�u���o�^����
--  --      -- ========================================
    --    /*20090406_yabuki_ST101 END*/
    --    insert_wk_req_proc(
    --        i_requisition_rec => l_requisition_rec  -- �����˗����
    --      , ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --    /*20090406_yabuki_ST101 START*/
    --  ELSE
    --    -- ========================================
    --    -- A-20. ��ƈ˗��^�������A�g�Ώۃe�[�u���X�V����
    --    -- ========================================
    --    update_wk_req_proc(
    --        i_requisition_rec => l_requisition_rec  -- �����˗����
    --      , ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W  --# �Œ� #
    --      , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h    --# �Œ� #
    --    );
    --    --
    --    IF ( lv_retcode <> cv_status_normal ) THEN
    --      RAISE reg_upd_process_expt;
    --      --
    --    END IF;
    --    --
    --  END IF;
    --  --
    --  /*20090406_yabuki_ST101 END*/
    --  /* 20090701_abe_ST529 START*/
    --  -- ========================================
    --  -- A-23. �����˗����׍X�V����
    --  -- ========================================
    --  update_po_req_line(
    --      i_requisition_rec => l_requisition_rec  -- �����˗����
    --    , ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W  --# �Œ� #
    --    , ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h    --# �Œ� #
    --  );
    --  --
    --  IF ( lv_retcode <> cv_status_normal ) THEN
    --    RAISE reg_upd_process_expt;
    --    --
    --  END IF;
    --  --
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
    /* 20090701_abe_ST529 END*/
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
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
    cv_ib_chk_subject CONSTANT VARCHAR2(30)  := 'XXCSO_IB_CHK_SUBJECT';
    /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
    --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf              VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode             VARCHAR2(1);     -- ���^�[���E�R�[�h
    --
  BEGIN
    --
        -- ========================================
        -- A-13. �ݒu�p�����X�V����
        -- ========================================
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
      /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_subject
        , avalue   => cv_tkn_subject1 || gv_requisition_number || cv_tkn_subject2
      );
      /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */

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
      /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� START */
      wf_engine.setitemattrtext(
          itemtype => itemtype
        , itemkey  => itemkey
        , aname    => cv_ib_chk_subject
        , avalue   => cv_tkn_subject1 || gv_requisition_number || cv_tkn_subject2
      );
      /* 2009.12.09 K.Satomura E_�{�ғ�_00341�Ή� END */
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
    /* 20090515_abe_ST669 START*/
    lv_proc_kbn_req_aprv    VARCHAR2(1);  --�����敪�i2:���F�A3:�۔F�j
    lv_doc_mgr_return_val   VARCHAR2(1);
    /* 20090515_abe_ST669 END*/
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

/* 20090515_abe_ST669 START*/
    -- ========================================
    -- A-22. ���F�Ҍ����i���i�j�`�F�b�N
    -- ========================================
    lv_doc_mgr_return_val := VerifyAuthority(
                                 itemtype    => itemtype
                               , itemkey     => itemkey
                             );
    -- 
    -- ���F�����`�F�b�N������I���̏ꍇ
    IF (lv_doc_mgr_return_val = cv_VerifyAuthority_y ) THEN
      lv_proc_kbn_req_aprv := cv_proc_kbn_req_aprv;
    -- ���F�����`�F�b�N���ُ�I���̏ꍇ
    ELSE
      lv_proc_kbn_req_aprv := cv_proc_kbn_req_dngtn;
    END IF;
/* 20090515_abe_ST669 END*/
    /* 20090410_abe_T1_0108 END*/
      -- ===============================================
      -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
      -- ===============================================
      submain(
          iv_itemtype    => itemtype
        , iv_itemkey     => itemkey
/* 20090515_abe_ST669 START*/
        , iv_process_kbn => lv_proc_kbn_req_aprv  -- �����敪�i�����˗����F�E�۔F�j
--        , iv_process_kbn => cv_proc_kbn_req_aprv  -- �����敪�i�����˗����F�j
/* 20090515_abe_ST669 END*/
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
