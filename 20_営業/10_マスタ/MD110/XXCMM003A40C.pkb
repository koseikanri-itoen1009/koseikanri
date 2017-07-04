CREATE OR REPLACE PACKAGE BODY XXCMM003A40C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM003A40C(body)
 * Description      : �ڋq�ꊇ�o�^���[�N�e�[�u���Ɏ捞�ς̃f�[�^����ڋq���R�[�h��o�^���܂��B
 * MD.050           : �ڋq�ꊇ�o�^ MD050_CMM_003_A40
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  validate_cust_wk       �ڋq�ꊇ�o�^���[�N�f�[�^�Ó����`�F�b�N (A-4)
 *  add_report             �ڋq�o�^���ʂ��i�[����v���V�[�W��
 *  disp_report            �ڋq�o�^���ʂ��o�͂���v���V�[�W��
 *  ins_cust_acct_api      �ڋq�}�X�^�o�^���� (A-5)
 *  ins_location_api       �ڋq���ݒn�}�X�^�o�^���� (A-5)
 *  ins_party_site_api     �p�[�e�B�T�C�g�}�X�^�o�^���� (A-5)
 *  ins_cust_acct_site_api �ڋq�T�C�g�}�X�^�o�^���� (A-5)
 *  ins_bill_to_api        �ڋq�g�p�ړI�}�X�^(������)�o�^���� (A-5)
 *  ins_ship_to_api        �ڋq�g�p�ړI�}�X�^�o�^����(�o�א�) (A-5)
 *  ins_other_to_api       �ڋq�g�p�ړI�}�X�^�o�^����(���̑�) (A-5)
 *  regist_resource_no_api �g�D�v���t�@�C���g��(�S���c�ƈ�)�o�^���� (A-5)
 *  ins_cmm_cust_acct      �ڋq�ǉ����}�X�^�o�^����
 *  ins_cmm_mst_crprt      �ڋq�@�l���o�^����
 *  ins_rcpmia             �ڋq�x�����@OIF�o�^����
 *  submit_request_racust  �ڋq�C���^�t�F�[�X���s���� (A-7)
 *  loop_main              �ڋq�ꊇ�o�^���[�N�f�[�^�擾 (A-3)
 *  get_if_data            �t�@�C���A�b�v���[�hIF�f�[�^�擾 (A-2)
 *  proc_comp              �I������ (A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/10/05    1.0   Shigeto.Niki     �V�K�쐬
 *  2010/11/05    1.1   Shigeto.Niki     E_�{�ғ�_05492�Ή�  �S���c�ƈ��o�^���̃`�F�b�N�ǉ�
 *  2012/12/14    1.2   K.Furuyama       E_�{�ғ�_09963�Ή�  �ڋq�敪�F13�A14�ǉ�
 *  2013/04/18    1.3   K.Nakamura       E_�{�ғ�_09963�ǉ��Ή�  �x�����@�A�J�[�h��Ћ敪�ǉ�
 *  2015/03/10    1.4   S.Niki           E_�{�ғ�_12955�Ή�  ���������s�T�C�N���̃`�F�b�N�ǉ�
 *  2017/06/14    1.5   S.Niki           E_�{�ғ�_14271�Ή�  ���̋@�t�H���[�ϑ��Q���J��
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  --*** ���b�N�G���[��O ***
  global_check_lock_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM003A40C';                                      -- �p�b�P�[�W��
--
  -- ���b�Z�[�W
  cv_msg_xxcmm_00002     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';                                  -- �v���t�@�C���擾�G���[
  cv_msg_xxcmm_00012     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00012';                                  -- �f�[�^�폜�G���[
  cv_msg_xxcmm_00018     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';                                  -- �Ɩ����t�擾�G���[
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                                  -- �t�@�C���A�b�v���[�h���̃m�[�g
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                                  -- CSV�t�@�C�����m�[�g
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                                  -- FILE_ID�m�[�g
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                                  -- �t�H�[�}�b�g�m�[�g
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                                  -- �f�[�^���ڐ��G���[
-- Ver1.3 K.Nakamura add start
  cv_msg_xxcmm_00366     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00366';                                  -- �ڋq�x�����@OIF�o�^�G���[
  cv_msg_xxcmm_00367     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00367';                                  -- �ڋq�C���^�t�F�[�X�N���m�[�g
  cv_msg_xxcmm_00368     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00368';                                  -- �ڋq�C���^�t�F�[�X�N���G���[
  cv_msg_xxcmm_00369     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00369';                                  -- �ڋq�C���^�t�F�[�X�ҋ@�G���[
  cv_msg_xxcmm_00370     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00370';                                  -- �ڋq�C���^�t�F�[�X����I�����b�Z�[�W
  cv_msg_xxcmm_00371     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00371';                                  -- �ڋq�C���^�t�F�[�X�x���I�����b�Z�[�W
  cv_msg_xxcmm_00372     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00372';                                  -- �ڋq�C���^�t�F�[�X�G���[�I�����b�Z�[�W
-- Ver1.3 K.Nakamura add end
  --
  cv_msg_xxcmm_10323     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10323';                                  -- �p�����[�^NULL�G���[
  cv_msg_xxcmm_10324     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10324';                                  -- �擾���s�G���[
  cv_msg_xxcmm_10325     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10325';                                  -- �����_����G���[
  cv_msg_xxcmm_10326     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10326';                                  -- �S�p�����`�F�b�N�G���[
  cv_msg_xxcmm_10327     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10327';                                  -- ���p�����`�F�b�N�G���[
  cv_msg_xxcmm_10328     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10328';                                  -- �l�`�F�b�N�G���[
  cv_msg_xxcmm_10329     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10329';                                  -- �l�Z�b�g���݃`�F�b�N�G���[
  cv_msg_xxcmm_10330     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10330';                                  -- �Q�ƃR�[�h���݃`�F�b�N�G���[
  cv_msg_xxcmm_10331     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10331';                                  -- �X�֔ԍ��`�F�b�N�G���[
  cv_msg_xxcmm_10332     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10332';                                  -- �d�b�ԍ��`�F�b�N�G���[
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete start by Shigeto.Niki
--  cv_msg_xxcmm_10333     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10333';                                  -- �K�p�J�n�����̓`�F�b�N�G���[
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete end by Shigeto.Niki
  cv_msg_xxcmm_10334     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10334';                                  -- �S���c�ƈ����݃`�F�b�N�G���[
  cv_msg_xxcmm_10335     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10335';                                  -- �f�[�^�o�^�G���[
  cv_msg_xxcmm_10336     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10336';                                  -- �ڋq�ꊇ�o�^�pCSV�t�@�C���擾�G���[
  cv_msg_xxcmm_10337     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10337';                                  -- I/F�e�[�u�����b�N�擾�G���[
  cv_msg_xxcmm_10338     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10338';                                  -- �t�@�C�����ڃ`�F�b�N�G���[
  cv_msg_xxcmm_10339     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10339';                                  -- �W��API�G���[
  cv_msg_xxcmm_10340     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10340';                                  -- �ڋq�ǉ����}�X�^�o�^�G���[
  cv_msg_xxcmm_10341     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10341';                                  -- �ڋq�o�^���̃��O���o��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_msg_xxcmm_10344     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10344';                                  -- �ڋq�@�l���}�X�^�o�^�G���[
-- Ver1.3 K.Nakamura del start
--  cv_msg_xxcmm_10345     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10345';                                  -- ���ٓ��t�`�F�b�N�G���[
-- Ver1.3 K.Nakamura del end
  cv_msg_xxcmm_10346     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10346';                                  -- �f�[�^���݃`�F�b�N�G���[
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.4 SCSK S.Niki add start
  cv_msg_xxcmm_10356     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10356';                                  -- ���������s�T�C�N���`�F�b�N�G���[
-- Ver1.4 SCSK S.Niki add end
-- Ver1.5 add start
  cv_msg_xxcmm_10359     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10359';                                  -- ���E�p�ڋq�R�[�h���݃`�F�b�N�G���[
  cv_msg_xxcmm_10360     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-10360';                                  -- �����ڋq�R�[�h�d���`�F�b�N�G���[
-- Ver1.5 add end
  -- �g�[�N����
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                           -- �t�@�C��ID
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                       -- �t�@�C���A�b�v���[�h����
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                            -- �t�H�[�}�b�g
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                         -- �t�@�C����
  cv_file_upload_obj     CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';                            -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
  cv_tkn_param_name      CONSTANT VARCHAR2(20)  := 'PARAM_NAME';                                        -- �p�����[�^��
  cv_tkn_ng_profile      CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                                        -- �v���t�@�C����
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                             -- �l
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                             -- �e�[�u����
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                             -- ��������
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                     -- �C���^�t�F�[�X�̍s�ԍ�
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                           -- �G���[���e
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                             -- ����
  cv_tkn_apply_date      CONSTANT VARCHAR2(20)  := 'APPLY_DATE';                                        -- �K�p�J�n��
  cv_tkn_cust_code       CONSTANT VARCHAR2(20)  := 'CUST_CODE';                                         -- �ڋq�R�[�h
  cv_tkn_api_name        CONSTANT VARCHAR2(20)  := 'API_NAME';                                          -- �W��API��
  cv_tkn_seq_num         CONSTANT VARCHAR2(20)  := 'SEQ_NUM';                                           -- �V�[�P���X�ԍ�
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_tkn_cust_id         CONSTANT VARCHAR2(20)  := 'CUST_ID';                                           -- �ڋqID
-- Ver1.3 K.Nakamura del start
--  cv_tkn_approval_date   CONSTANT VARCHAR2(20)  := 'APPROVAL_DATE';                                     -- ���ٓ��t
-- Ver1.3 K.Nakamura del end
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
  cv_tkn_req_id          CONSTANT VARCHAR2(20)  := 'REQ_ID';                                            -- �v��ID
-- Ver1.3 K.Nakamura add end
  --
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';                                             -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';                                             -- �A�h�I���F���ʁEIF�̈�
-- Ver1.3 K.Nakamura add start
  cv_appl_name_ar        CONSTANT VARCHAR2(5)   := 'AR';                                                -- �A�v���P�[�V�����Z�k���FAR
-- Ver1.3 K.Nakamura add end
  cv_log                 CONSTANT VARCHAR2(5)   := 'LOG';                                               -- ���O
  cv_output              CONSTANT VARCHAR2(6)   := 'OUTPUT';                                            -- �A�E�g�v�b�g
  -- �v���t�@�C����
  cv_prf_resp_id         CONSTANT VARCHAR2(60)  := 'RESP_ID';                                           -- �v���t�@�C���u�E��ID�v
  cv_prf_org_id          CONSTANT VARCHAR2(60)  := 'ORG_ID';                                            -- �v���t�@�C���u�g�DID�v
  cv_prf_resp_key        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_MGR_RESP_KEY';                        -- �v���t�@�C���u�ڋq�ꊇ�o�^�Ǘ��ҐE�ӃL�[�v
  cv_prf_resp_key_n      CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�Ǘ��ҐE�ӃL�[';                  -- �v���t�@�C���u�ڋq�ꊇ�o�^�Ǘ��ҐE�ӃL�[�v����
  cv_prf_item_num_mc     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_MC_KOKYAKU_NUM';                      -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��iMC�ڋq�j�v
  cv_prf_item_num_mc_n   CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ��iMC�ڋq�j';          -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��iMC�ڋq�j�v����
  cv_prf_item_num_st     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_TENPO_EIGYO_NUM';                     -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��i�X�܉c�Ɓj�v
  cv_prf_item_num_st_n   CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ��i�X�܉c�Ɓj';        -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��i�X�܉c�Ɓj�v����
  cv_prf_output_form     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_INI_OUTPUT_FORM';                     -- �v���t�@�C���u�������o�͌`�������l�v
  cv_prf_output_form_n   CONSTANT VARCHAR2(60)  := 'XXCMM:�������o�͌`�������l';                        -- �v���t�@�C���u�������o�͌`�������l�v����
  cv_prf_prt_cycle       CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_INI_PRT_CYCLE';                       -- �v���t�@�C���u���������s�T�C�N�������l�v
  cv_prf_prt_cycle_n     CONSTANT VARCHAR2(60)  := 'XXCMM:���������s�T�C�N�������l';                    -- �v���t�@�C���u���������s�T�C�N�������l�v����
  cv_prf_inv_unit        CONSTANT VARCHAR2(60)  := 'XCMM1_003A02_INI_INV_UNIT';                         -- �v���t�@�C���u����������P�ʏ����l�v
  cv_prf_inv_unit_n      CONSTANT VARCHAR2(60)  := 'XXCMM:����������P�ʏ����l';                        -- �v���t�@�C���u����������P�ʏ����l�v����
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_prf_set_of_bks_id   CONSTANT VARCHAR2(60)  := 'GL_SET_OF_BKS_ID';                                   -- �v���t�@�C���u��v����ID�v
  cv_prf_set_of_bks_id_n CONSTANT VARCHAR2(60)  := '��v����ID';                                         -- �v���t�@�C���u��v����ID�v����
  cv_prf_item_num_ho     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_CUST_HOUJIN_NUM';                      -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��i�@�l�ڋq�j�v
  cv_prf_item_num_ho_n   CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ��i�@�l�ڋq�j';         -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��i�@�l�ڋq�j�v����
  cv_prf_item_num_ur     CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_CUST_URIKAKE_NUM';                     -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��i���|�Ǘ���ڋq�j�v
  cv_prf_item_num_ur_n   CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ��i���|�Ǘ���ڋq�j';   -- �v���t�@�C���u�ڋq�ꊇ�o�^�f�[�^���ڐ��i���|�Ǘ���ڋq�j�v����
  cv_prf_ur_kaisya       CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KAISYA';                       -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_��Ёv
  cv_prf_ur_kaisya_n     CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_���';        -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_��Ёv����
  cv_prf_ur_bumon        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_BUMON';                        -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����v
  cv_prf_ur_bumon_n      CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����';        -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����v����
  cv_prf_ur_kanjyou      CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KANJYOU';                      -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����Ȗځv
  cv_prf_ur_kanjyou_n    CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����Ȗ�';    -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����Ȗځv����
  cv_prf_ur_hojyo        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_HOJYO';                        -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�⏕�Ȗځv
  cv_prf_ur_hojyo_n      CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�⏕�Ȗ�';    -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�⏕�Ȗځv����
  cv_prf_ur_kokyaku      CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KOKYAKU';                      -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�ڋq�R�[�h�v
  cv_prf_ur_kokyaku_n    CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�ڋq�R�[�h';  -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�ڋq�R�[�h�v����
  cv_prf_ur_kigyou       CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_KIGYOU';                       -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_��ƃR�[�h�v
  cv_prf_ur_kigyou_n     CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_��ƃR�[�h';  -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_��ƃR�[�h�v����
  cv_prf_ur_yobi1        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_YOBI1';                        -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���P�v
  cv_prf_ur_yobi1_n      CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���P';      -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���P�v����
  cv_prf_ur_yobi2        CONSTANT VARCHAR2(60)  := 'XXCMM1_003A40_URIKAKE_YOBI2';                        -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���Q�v
  cv_prf_ur_yobi2_n      CONSTANT VARCHAR2(60)  := 'XXCMM:�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���Q';      -- �v���t�@�C���u�ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���Q�v����
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
  cv_prf_inter_racust    CONSTANT VARCHAR2(60)  := 'XXCMM1_INTERVAL_RACUST';                             -- �v���t�@�C���u�ҋ@�Ԋu�i�ڋq�C���^�t�F�[�X�j�v
  cv_prf_inter_racust_n  CONSTANT VARCHAR2(60)  := 'XXCMM:�ҋ@�Ԋu�i�ڋq�C���^�t�F�[�X�j';               -- �v���t�@�C���u�ҋ@�Ԋu�i�ڋq�C���^�t�F�[�X�j�v����
  cv_prf_max_racust      CONSTANT VARCHAR2(60)  := 'XXCMM1_MAX_WAIT_RACUST';                             -- �v���t�@�C���u�ő�ҋ@���ԁi�ڋq�C���^�t�F�[�X�j�v
  cv_prf_max_racust_n    CONSTANT VARCHAR2(60)  := 'XXCMM:�ő�ҋ@���ԁi�ڋq�C���^�t�F�[�X�j';           -- �v���t�@�C���u�ő�ҋ@���ԁi�ڋq�C���^�t�F�[�X�j�v����
-- Ver1.3 K.Nakamura add end
  -- �l�Z�b�g
  cv_aff_dept            CONSTANT VARCHAR2(15)  := 'XX03_DEPARTMENT';                                   -- LOOKUP�FAFF����}�X�^
  -- LOOKUP
  cv_xxcmm_chain_code    CONSTANT VARCHAR2(16)  := 'XXCMM_CHAIN_CODE';                                  -- LOOKUP�F�`�F�[���X
  cv_lookup_chiku_code   CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_CHIKU_CODE';                             -- LOOKUP�F�n��R�[�h
  cv_lookup_gyotai_sho   CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';                             -- LOOKUP�F�Ƒԏ�����
  cv_lookup_mcjuyodo     CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_MCJUYODO';                               -- LOOKUP�FMC:�d�v�x
  cv_lookup_mchotdo      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_MCHOTDO';                                -- LOOKUP�FMC:HOT�x
  cv_lookup_gyosyu       CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_KBN';                             -- LOOKUP�F�Ǝ�
  cv_lookup_torihiki     CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_TORIHIKI_KETAI';                         -- LOOKUP�F����`��
  cv_lookup_haiso        CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_HAISO_KETAI';                            -- LOOKUP�F�z���`��
  cv_lookup_cust_def_mc  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_MC';                         -- LOOKUP�F�ڋq�ꊇ�o�^�f�[�^���ڒ�`(MC)
  cv_lookup_cust_def_st  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_ST';                         -- LOOKUP�F�ڋq�ꊇ�o�^�f�[�^���ڒ�`(�X�܉c��)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_lookup_sohyo_kbn    CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_SOHYO_KBN';                              -- LOOKUP�F���]�敪
  cv_lookup_syohizei_kbn CONSTANT VARCHAR2(30)  := 'XXCMM_CSUT_SYOHIZEI_KBN';                           -- LOOKUP�F����ŋ敪
  cv_lookup_tax_rule     CONSTANT VARCHAR2(30)  := 'AR_TAX_ROUNDING_RULE';                              -- LOOKUP�F�ŋ��[������
  cv_lookup_invoice_grp  CONSTANT VARCHAR2(30)  := 'XXCMM_INVOICE_GRP_CODE';                            -- LOOKUP�F���|�R�[�h1�i�������j
  cv_lookup_sekyusyo_ksk CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_SEKYUSYO_SHUT_KSK';                      -- LOOKUP�F�������o�͌`��
  cv_lookup_invoice_cycl CONSTANT VARCHAR2(30)  := 'XXCMM_INVOICE_ISSUE_CYCLE';                         -- LOOKUP�F���������s�T�C�N��
  cv_lookup_cust_def_ho  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_HO';                         -- LOOKUP�F�ڋq�ꊇ�o�^�f�[�^���ڒ�`(�@�l)
  cv_lookup_cust_def_ur  CONSTANT VARCHAR2(30)  := 'XXCMM1_003A40_CUST_DEF_UR';                         -- LOOKUP�F�ڋq�ꊇ�o�^�f�[�^���ڒ�`(���|�Ǘ�)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
  cv_lookup_card_bkn     CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_CARD_COMPANY_KBN';                       -- LOOKUP�F�J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
  --
  cv_file_format_mc      CONSTANT VARCHAR2(3)   := '501';                                               -- �t�@�C���t�H�[�}�b�g(MC)
  cv_file_format_st      CONSTANT VARCHAR2(3)   := '502';                                               -- �t�@�C���t�H�[�}�b�g(�X�܉c��)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_file_format_ho      CONSTANT VARCHAR2(3)   := '503';                                               -- �t�@�C���t�H�[�}�b�g(�@�l)
  cv_file_format_ur      CONSTANT VARCHAR2(3)   := '504';                                               -- �t�@�C���t�H�[�}�b�g(���|�Ǘ�)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  cv_sales_ou            CONSTANT VARCHAR2(20)  := 'SALES-OU';                                          -- �c��OU
  cv_base_kbn            CONSTANT VARCHAR2(2)   := '1';                                                 -- �ڋq�敪(���_)
-- Ver1.5 add start
  cv_cust_kbn            CONSTANT VARCHAR2(2)   := '10';                                                -- �ڋq�敪(�ڋq)
-- Ver1.5 add end
  cv_tenpo_kbn           CONSTANT VARCHAR2(2)   := '15';                                                -- �ڋq�敪(�X�܉c��)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_hojin_kbn           CONSTANT VARCHAR2(2)   := '13';                                                -- �ڋq�敪(�@�l)
  cv_urikake_kbn         CONSTANT VARCHAR2(2)   := '14';                                                -- �ڋq�敪(���|�Ǘ�)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
  cv_cust_status_mc_cand CONSTANT VARCHAR2(2)   := '10';                                                -- �ڋq�X�e�[�^�X�FMC���
  cv_cust_status_mc      CONSTANT VARCHAR2(2)   := '20';                                                -- �ڋq�X�e�[�^�X�FMC
  cv_cust_status_except  CONSTANT VARCHAR2(2)   := '99';                                                -- �ڋq�X�e�[�^�X�F�ΏۊO
  cv_site_use_bill_to    CONSTANT VARCHAR2(10)  := 'BILL_TO';                                           -- �g�p�ړI�R�[�h(������)
  cv_site_use_ship_to    CONSTANT VARCHAR2(10)  := 'SHIP_TO';                                           -- �g�p�ړI�R�[�h(�o�א�)
  cv_site_use_other_to   CONSTANT VARCHAR2(10)  := 'OTHER_TO';                                          -- �g�p�ړI�R�[�h(���̑�)
  cv_ui_flag_new         CONSTANT VARCHAR2(1)   := '1';                                                 -- �V�K�^�X�V�t���O�i�V�K�j
  -- ITEM
  cv_file_id             CONSTANT VARCHAR2(30)  := 'FILE_ID';                                           -- �t�@�C��ID
  cv_format              CONSTANT VARCHAR2(30)  := '�t�H�[�}�b�g�p�^�[��';                              -- �t�H�[�}�b�g�p�^�[��
  cv_cust_upload         CONSTANT VARCHAR2(30)  := '�ڋq�ꊇ�o�^';                                      -- ���[�N�e�[�u����
  cv_upload_def_info     CONSTANT VARCHAR2(30)  := '�ڋq�ꊇ�o�^���[�N��`���';                        -- �ڋq�ꊇ�o�^���[�N��`���
  cv_file_upload_name    CONSTANT VARCHAR2(30)  := '�t�@�C���A�b�v���[�h����';                          -- �t�@�C���A�b�v���[�h����
  cv_user_resp_key       CONSTANT VARCHAR2(30)  := '�d�a�r���O�C�����[�U�[�E�ӃL�[';                    -- �d�a�r���O�C�����[�U�[�E�ӃL�[
  cv_sal_org_id          CONSTANT VARCHAR2(30)  := '�c�Ƒg�D�h�c';                                      -- �c�Ƒg�D�h�c
  cv_belong_base_code    CONSTANT VARCHAR2(30)  := '�������_�R�[�h';                                    -- �������_�R�[�h
  cv_customer_name       CONSTANT VARCHAR2(30)  := '�ڋq��';                                            -- �ڋq��
  cv_customer_name_kana  CONSTANT VARCHAR2(30)  := '�ڋq���i�J�i�j';                                    -- �ڋq���i�J�i�j
  cv_customer_name_ryaku CONSTANT VARCHAR2(30)  := '����';                                              -- ����
  cv_customer_class_code CONSTANT VARCHAR2(30)  := '�ڋq�敪';                                          -- �ڋq�敪
  cv_customer_status     CONSTANT VARCHAR2(30)  := '�ڋq�X�e�[�^�X';                                    -- �ڋq�X�e�[�^�X
  cv_sale_base_code      CONSTANT VARCHAR2(30)  := '���㋒�_';                                          -- ���㋒�_
  cv_s_chain_code        CONSTANT VARCHAR2(30)  := '�̔���`�F�[��';                                    -- �̔���`�F�[��
  cv_d_chain_code        CONSTANT VARCHAR2(30)  := '�[�i��`�F�[��';                                    -- �[�i��`�F�[��
  cv_postal_code         CONSTANT VARCHAR2(30)  := '�X�֔ԍ�';                                          -- �X�֔ԍ�
  cv_state               CONSTANT VARCHAR2(30)  := '�s���{��';                                          -- �s���{��
  cv_city                CONSTANT VARCHAR2(30)  := '�s�E��';                                            -- �s�E��
  cv_address1            CONSTANT VARCHAR2(30)  := '�Z���P';                                            -- �Z���P
  cv_address2            CONSTANT VARCHAR2(30)  := '�Z���Q';                                            -- �Z���Q
  cv_address3            CONSTANT VARCHAR2(30)  := '�n��R�[�h';                                        -- �n��R�[�h
  cv_tel_no              CONSTANT VARCHAR2(30)  := '�d�b�ԍ�';                                          -- �d�b�ԍ�
  cv_fax                 CONSTANT VARCHAR2(30)  := '�e�`�w';                                            -- �e�`�w
  cv_b_row_type_tmp      CONSTANT VARCHAR2(30)  := '�Ƒԏ����ށi���j';                                  -- �Ƒԏ����ށi���j
  cv_manager_name        CONSTANT VARCHAR2(30)  := '�X����';                                            -- �X����
  cv_rest_emp_name       CONSTANT VARCHAR2(30)  := '�S���ҋx��';                                        -- �S���ҋx��
  cv_mc_importance_deg   CONSTANT VARCHAR2(30)  := '�l�b�F�d�v�x';                                      -- �l�b�F�d�v�x
  cv_mc_hot_deg          CONSTANT VARCHAR2(30)  := '�l�b�F�g�n�s�x';                                    -- �l�b�F�g�n�s�x
  cv_mc_conf_info        CONSTANT VARCHAR2(30)  := '�l�b�F�������';                                    -- �l�b�F�������
  cv_mc_b_talk_details   CONSTANT VARCHAR2(30)  := '�l�b�F���k�o��';                                    -- �l�b�F���k�o��
  cv_resource_no         CONSTANT VARCHAR2(30)  := '�S���c�ƈ�';                                        -- �S���c�ƈ�
  cv_gyotai_sho          CONSTANT VARCHAR2(30)  := '�Ƒԁi�����ށj';                                    -- �Ƒԁi�����ށj
  cv_industry_div        CONSTANT VARCHAR2(30)  := '�Ǝ�';                                              -- �Ǝ�
  cv_torihiki_form       CONSTANT VARCHAR2(30)  := '����`��';                                          -- ����`��
  cv_delivery_form       CONSTANT VARCHAR2(30)  := '�z���`��';                                          -- �z���`��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_base_code           CONSTANT VARCHAR2(30)  := '�{���S�����_';                                      -- �{���S�����_
  cv_decide_div          CONSTANT VARCHAR2(30)  := '����敪';                                          -- ����敪
  cv_tax_div             CONSTANT VARCHAR2(30)  := '����ŋ敪';                                        -- ����ŋ敪
  cv_tax_rounding_rule   CONSTANT VARCHAR2(30)  := '�ŋ��[������';                                      -- �ŋ��[������
  cv_invoice_grp_code    CONSTANT VARCHAR2(30)  := '���|�R�[�h1�i�������j';                             -- ���|�R�[�h1�i�������j
  cv_output_form         CONSTANT VARCHAR2(30)  := '�������o�͌`��';                                    -- �������o�͌`��
  cv_prt_cycle           CONSTANT VARCHAR2(30)  := '���������s�T�C�N��';                                -- ���������s�T�C�N��
  cv_payment_term_id     CONSTANT VARCHAR2(30)  := '�x������';                                          -- �x������
  cv_delivery_base_code  CONSTANT VARCHAR2(30)  := '�[�i���_';                                          -- �[�i���_
  cv_bill_base_code      CONSTANT VARCHAR2(30)  := '�������_';                                          -- �������_
  cv_receiv_base_code    CONSTANT VARCHAR2(30)  := '�������_';                                          -- �������_
  cv_sales_head_base_cd  CONSTANT VARCHAR2(30)  := '�̔���{���S�����_';                                -- �̔���{���S�����_
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
  cv_receipt_methods     CONSTANT VARCHAR2(30)  := '�x�����@';                                          -- �x�����@
  cv_card_company_kbn    CONSTANT VARCHAR2(30)  := '�J�[�h��Ћ敪';                                    -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
  -- �W��API��
  cv_api_cust_acct       CONSTANT VARCHAR2(60)  := 'hz_cust_account_v2pub.create_cust_account';         -- �W��API�F�ڋq�}�X�^�쐬
  cv_api_location        CONSTANT VARCHAR2(60)  := 'hz_location_v2pub.create_location';                 -- �W��API�F�ڋq���ݒn�}�X�^�쐬
  cv_api_party_site      CONSTANT VARCHAR2(60)  := 'hz_party_site_v2pub.create_party_site';             -- �W��API�F�p�[�e�B�T�C�g�}�X�^�쐬
  cv_api_acct_site       CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.create_cust_acct_site';  -- �W��API�F�ڋq�T�C�g�}�X�^�쐬
  cv_api_cust_site_use   CONSTANT VARCHAR2(60)  := 'hz_cust_account_site_v2pub.create_cust_site_use';   -- �W��API�F�ڋq�g�p�ړI�}�X�^�쐬
  cv_api_regist_resource CONSTANT VARCHAR2(60)  := 'xxcso_rtn_rsrc_pkg.regist_resource_no';             -- �W��API�F���[�gNo/�S���c�ƈ��X�V�����֐�
  -- TABLE��
  cv_table_xwcu          CONSTANT VARCHAR2(30)  := '�ڋq�ꊇ�o�^���[�N';                                -- XXCMM_WK_CUST_UPLOAD
  cv_table_file_ul_if    CONSTANT VARCHAR2(30)  := '�t�@�C���A�b�v���[�hIF';                            -- XXCCP_MRP_FILE_UL_INTERFACE
  cv_table_cust_acct     CONSTANT VARCHAR2(30)  := '�ڋq�}�X�^';                                        -- �ڋq�}�X�^
  cv_table_location      CONSTANT VARCHAR2(30)  := '�ڋq���ݒn�}�X�^';                                  -- �ڋq���ݒn�}�X�^
  cv_table_party_site    CONSTANT VARCHAR2(30)  := '�p�[�e�B�T�C�g�}�X�^';                              -- �p�[�e�B�T�C�g�}�X�^
  cv_table_acct_site     CONSTANT VARCHAR2(30)  := '�ڋq�T�C�g�}�X�^';                                  -- �ڋq�T�C�g�}�X�^
  cv_table_bill_to       CONSTANT VARCHAR2(30)  := '�ڋq�g�p�ړI�}�X�^(������)';                        -- �ڋq�g�p�ړI�}�X�^(������)
  cv_table_ship_to       CONSTANT VARCHAR2(30)  := '�ڋq�g�p�ړI�}�X�^(�o�א�)';                        -- �ڋq�g�p�ړI�}�X�^(�o�א�)
  cv_table_other_to      CONSTANT VARCHAR2(30)  := '�ڋq�g�p�ړI�}�X�^(���̑�)';                        -- �ڋq�g�p�ړI�}�X�^(���̑�)
  cv_table_resource      CONSTANT VARCHAR2(30)  := '�S���c�ƈ�';                                        -- �S���c�ƈ�
  --
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';                                                 -- YES
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';                                                 -- NO
  cv_r                   CONSTANT VARCHAR2(1)   := 'R';                                                 -- �ڋq�^�C�v('R'�F�O��)
  cv_a                   CONSTANT VARCHAR2(1)   := 'A';                                                 -- �X�e�[�^�X('A'�F�L��)
  cv_y                   CONSTANT VARCHAR2(1)   := 'Y';                                                 -- �X�e�[�^�X('Y'�F�L��)
  cv_null_ok             CONSTANT VARCHAR2(10)  := 'NULL_OK';                                           -- �C�Ӎ���
  cv_null_ng             CONSTANT VARCHAR2(10)  := 'NULL_NG';                                           -- �K�{����
  cv_varchar             CONSTANT VARCHAR2(10)  := 'VARCHAR2';                                          -- ������
  cv_number              CONSTANT VARCHAR2(10)  := 'NUMBER';                                            -- ���l
  cv_date                CONSTANT VARCHAR2(10)  := 'DATE';                                              -- ���t
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := '0';                                                 -- �����񍀖�
  cv_number_cd           CONSTANT VARCHAR2(1)   := '1';                                                 -- ���l����
  cv_date_cd             CONSTANT VARCHAR2(1)   := '2';                                                 -- ���t����
  cv_not_null            CONSTANT VARCHAR2(1)   := '1';                                                 -- �K�{
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';                                                 -- �J���}
  cv_msg_comma_double    CONSTANT VARCHAR2(2)   := '�A';                                                -- �J���}(�S�p)
  cv_max_date            CONSTANT VARCHAR2(10)  := '9999/12/31';                                        -- MAX���t
  cv_date_fmt_std        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                                        -- YYYY/MM/DD
  cv_category            CONSTANT VARCHAR2(10)  := 'EMPLOYEE';                                          -- �J�e�S��
  cv_jp                  CONSTANT VARCHAR2(10)  := 'JP';                                                -- ��('JP'�F���{)
  cv_1                   CONSTANT VARCHAR2(1)   := '1';                                                 -- �Œ�l�P
  cv_vist_target         CONSTANT VARCHAR2(1)   := '1';                                                 -- �K��Ώ�
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  cv_summary             CONSTANT VARCHAR2(10)  := 'SUMMARY';                                           -- �v��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
  cv_rcpmia_start_date   CONSTANT VARCHAR2(10)  := '1900/01/01';                                        -- �ڋq�x�����@�� �L�����i���j
  -- �R���J�����g��
  cv_conc_racust         CONSTANT VARCHAR2(10)  := 'RACUST';                                            -- �R���J�����g�v���O�������F�ڋq�C���^�t�F�[�X
  -- �R���J�����gdev�X�e�[�^�X
  cv_dev_status_normal   CONSTANT VARCHAR2(10)  := 'NORMAL';                                            -- ����
  cv_dev_status_warn     CONSTANT VARCHAR2(10)  := 'WARNING';                                           -- �x��
-- Ver1.3 K.Nakamura add end
-- Ver1.4 SCSK S.Niki add start
  cv_output_form_4       CONSTANT VARCHAR2(10)  := '4';                                                 -- �������o�͌`���F�Ǝ҈ϑ�
  cv_prt_cycle_1         CONSTANT VARCHAR2(10)  := '1';                                                 -- ���������s�T�C�N���F���c�Ɠ�
-- Ver1.4 SCSK S.Niki add end
-- Ver1.5 add start
  cv_offset_cust_div_1   CONSTANT VARCHAR2(10)  := '1';                                                 -- ���E�p�ڋq�敪�F���E�p�ڋq
-- Ver1.5 add end
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_item_def_rtype    IS RECORD                                                                    -- ���R�[�h�^��錾
      (item_name               VARCHAR2(100)                                                            -- ���ږ�
      ,item_attribute          VARCHAR2(100)                                                            -- ���ڑ���
      ,item_essential          VARCHAR2(100)                                                            -- �K�{�t���O
      ,item_length             NUMBER                                                                   -- ���ڂ̒���(��������)
      ,decim                   NUMBER                                                                   -- ���ڂ̒���(�����_�ȉ�)
      );
  --
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;                    -- �e�[�u���^�̐錾
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)        INDEX BY BINARY_INTEGER;                    -- �e�[�u���^�̐錾
--
  -- �o�͂��郍�O���i�[���郌�R�[�h
  TYPE report_rec IS RECORD(
    line_no                    xxcmm_wk_cust_upload.line_no%TYPE                                        -- �s�ԍ�
   ,account_number             hz_cust_accounts.account_number%TYPE                                     -- �ڋq�R�[�h
   ,customer_status            xxcmm_wk_cust_upload.customer_status%TYPE                                -- �ڋq�X�e�[�^�X
   ,resource_no                xxcmm_wk_cust_upload.resource_no%TYPE                                    -- �S���c�ƈ�
   ,resource_s_date            xxcmm_wk_cust_upload.resource_s_date%TYPE                                -- �K�p�J�n��
   ,customer_name              xxcmm_wk_cust_upload.customer_name%TYPE                                  -- �ڋq��
  );
  -- �o�͂��郌�|�[�g���i�[���錋���z��
  TYPE report_tbl  IS TABLE OF report_rec   INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_file_id                    NUMBER;                                                                 -- �p�����[�^�i�[�p�ϐ�
  gv_format                     VARCHAR2(100);                                                          -- �p�����[�^�i�[�p�ϐ�
  gd_process_date               DATE;                                                                   -- �Ɩ����t
  gd_system_date                DATE;                                                                   -- �V�X�e�����t
  g_item_def_tab                g_item_def_ttype;                                                       -- �e�[�u���^�ϐ��̐錾
  --
  gn_user_id                    NUMBER;                                                                 -- EBS���O�C�����[�U�[ID
  gt_belong_base_code           per_all_assignments_f.ass_attribute3%TYPE;                              -- EBS���O�C�����[�U�[�������_�R�[�h
  gn_resp_id                    NUMBER;                                                                 -- EBS���O�C�����[�U�[�E��ID
  gt_responsibility_key         fnd_responsibility.responsibility_key%TYPE;                             -- EBS���O�C�����[�U�[�E�ӃL�[
  gn_resp_appl_id               NUMBER;                                                                 -- EBS���O�C�����[�U�[�E�ӃA�v���P�[�V����ID
  --
  gt_mgr_resp_key               fnd_profile_option_values.profile_option_value%TYPE;                    -- �Ǘ��ҐE�ӃL�[
  gn_item_num                   NUMBER;                                                                 -- �ڋq�ꊇ�o�^�f�[�^���ڐ�
  gv_output_form                VARCHAR2(1);                                                            -- �������o�͌`�������l
  gv_prt_cycle                  VARCHAR2(1);                                                            -- ���������s�T�C�N�������l
  gv_inv_unit                   VARCHAR2(1);                                                            -- ����������P�ʏ����l
  gv_sal_org_id                 hr_all_organization_units.organization_id%TYPE;                         -- �c�Ƒ��̑g�DID
  gd_apply_date                 DATE;                                                                   -- �K�p�J�n���F���t�^�ϊ���
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  gt_set_of_bks_id              gl_sets_of_books.set_of_books_id%TYPE;                                  -- ��v����ID
  gt_ur_kaisya                  gl_code_combinations.segment1%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_���
  gt_ur_bumon                   gl_code_combinations.segment2%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����
  gt_ur_kanjyou                 gl_code_combinations.segment3%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����Ȗ�
  gt_ur_hojyo                   gl_code_combinations.segment4%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�⏕�Ȗ�
  gt_ur_kokyaku                 gl_code_combinations.segment5%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�ڋq�R�[�h
  gt_ur_kigyou                  gl_code_combinations.segment6%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_��ƃR�[�h
  gt_ur_yobi1                   gl_code_combinations.segment7%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���P
  gt_ur_yobi2                   gl_code_combinations.segment8%TYPE;                                     -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���Q
  gt_urikake_misyuukin_id       gl_code_combinations.code_combination_id%TYPE;                          -- ���|��/������
  gt_autocash_hierarchy_id      ar_autocash_hierarchies.autocash_hierarchy_id%TYPE;                     -- ����������Z�b�gID
  gt_payment_term_id            ra_terms.term_id%TYPE;                                                  -- �x������ID
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
  gv_loop_main_retcode          VARCHAR2(1);                                                            -- LOOP_MAIN���^�[���E�R�[�h
  gn_inter_racust               NUMBER;                                                                 -- �ҋ@�Ԋu�i�ڋq�C���^�t�F�[�X�j
  gn_max_racust                 NUMBER;                                                                 -- �ő�ҋ@���ԁi�ڋq�C���^�t�F�[�X�j
  gn_rcpmia_cnt                 NUMBER;                                                                 -- �ڋq�x�����@OIF�o�^����
-- Ver1.3 K.Nakamura add end
  --
  gv_warning_prg_name           VARCHAR2(100);                                                          -- �x�������v���V�[�W����
  --
  gn_insert_cnt                 NUMBER;                                                                 -- INSERT����
  gn_update_cnt                 NUMBER;                                                                 -- UPDATE����
--
  gt_report_tbl                 report_tbl;                                                             -- �����z��̒�`
--
  -- ===============================
  -- �p�b�P�[�W�E�J�[�\��
  -- ===============================
  -- �A�b�v���[�h�t�@�C�����݊m�F�J�[�\��
  CURSOR check_upload_file_cur(
    in_file_id  IN NUMBER,
    iv_format   IN VARCHAR2)
  IS
    SELECT xmf.file_name  file_name
    FROM   xxccp_mrp_file_ul_interface  xmf
    WHERE  xmf.file_id           = in_file_id
    AND    xmf.file_content_type = iv_format
    ;
  -- �A�b�v���[�h�t�@�C�����݊m�F�J�[�\�����R�[�h�^
  check_upload_file_rec  check_upload_file_cur%ROWTYPE;
--
-- ===============================
-- �p�b�P�[�WRECORD�^
-- ===============================
  -- API�߂�l���R�[�h�^
  TYPE save_cust_key_info_rtype IS RECORD (
    ln_cust_account_id          hz_cust_accounts.cust_account_id%TYPE              -- �ޔ�_�ڋq�A�J�E���gID
   ,lv_account_number           hz_cust_accounts.account_number%TYPE               -- �ޔ�_�ڋq�R�[�h
   ,ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE      -- �ޔ�_�ڋq�T�C�gID
   ,ln_party_id                 hz_parties.party_id%TYPE                           -- �ޔ�_�p�[�e�BID
   ,ln_party_site_id            hz_party_sites.party_site_id%TYPE                  -- �ޔ�_�p�[�e�B�T�C�gID
   ,ln_location_id              hz_locations.location_id%TYPE                      -- �ޔ�_���Ə�ID
   ,lv_status                   VARCHAR2(1)                                        -- �ޔ�_�X�e�[�^�X
   ,ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE             -- �ޔ�_������_�g�p�ړIID
   ,lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE           -- �ޔ�_������_�g�p�ړI
   ,ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE  -- �ޔ�_�ڋq�v���t�@�C��ID
   ,ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE             -- �ޔ�_�o�א�_�g�p�ړIID
   ,lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE           -- �ޔ�_�o�א�_�g�p�ړI
   ,ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE             -- �ޔ�_���̑�_�g�p�ړIID
   ,lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE           -- �ޔ�_���̑�_�g�p�ړI
  );
-- ===============================
-- �p�b�P�[�WTABLE�^
-- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE init(
    iv_file_id    IN  VARCHAR2          -- �t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- �t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    cv_ccid          CONSTANT VARCHAR2(20) := 'CCID';                           -- CCID
    cv_hrrchy_name   CONSTANT VARCHAR2(20) := '���������01';                 -- ���������01
    cv_aut_hrrchy_id CONSTANT VARCHAR2(20) := '����������Z�b�gID';           -- ����������Z�b�gID
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
--
    -- *** ���[�J���ϐ� ***
    lv_step                   VARCHAR2(10);                                     -- �X�e�b�v
    lv_tkn_value              VARCHAR2(100);                                    -- �g�[�N���l
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM
    --
    lv_upload_obj             VARCHAR2(100);                                    -- �t�@�C���A�b�v���[�h����
    lv_up_name                VARCHAR2(1000);                                   -- �A�b�v���[�h���̏o�͗p
    lv_file_id                VARCHAR2(1000);                                   -- �t�@�C��ID�o�͗p
    lv_file_format            VARCHAR2(1000);                                   -- �t�H�[�}�b�g�o�͗p
    lv_file_name              VARCHAR2(1000);                                   -- �t�@�C�����o�͗p
    -- �t�@�C���A�b�v���[�hIF�e�[�u������
    lv_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- �t�@�C�����i�[�p
    ln_created_by             xxccp_mrp_file_ul_interface.created_by%TYPE;      -- �쐬�Ҋi�[�p
    ld_creation_date          xxccp_mrp_file_ul_interface.creation_date%TYPE;   -- �쐬���i�[�p
    ln_cnt                    NUMBER;                                           -- �J�E���^
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �f�[�^���ڒ�`�擾�p�J�[�\��
    CURSOR     get_def_info_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- ���e
              ,DECODE(flv.attribute1, cv_varchar ,cv_varchar_cd
                                    , cv_number  ,cv_number_cd
                                    , cv_date_cd)  AS item_attribute            -- ���ڑ���
              ,DECODE(flv.attribute2, cv_not_null, cv_null_ng
                                    , cv_null_ok)  AS item_essential            -- �K�{�t���O
              ,TO_NUMBER(flv.attribute3)           AS item_length               -- ���ڂ̒���(��������)
              ,TO_NUMBER(flv.attribute4)           AS decim                     -- ���ڂ̒���(�����_�ȉ�)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP�\
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
      WHERE  ((gv_format = cv_file_format_mc
        AND      flv.lookup_type = cv_lookup_cust_def_mc)                       -- �ڋq�ꊇ�o�^�f�[�^���ڒ�`(MC�ڋq)
      -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
      OR      (gv_format = cv_file_format_st
        AND      flv.lookup_type = cv_lookup_cust_def_st)                       -- �ڋq�ꊇ�o�^�f�[�^���ڒ�`(�X�܉c��)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
      OR      ( gv_format       = cv_file_format_ho
        AND     flv.lookup_type = cv_lookup_cust_def_ho )                      -- �ڋq�ꊇ�o�^�f�[�^���ڒ�`(�@�l)
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      OR      ( gv_format       = cv_file_format_ur
        AND     flv.lookup_type = cv_lookup_cust_def_ur ) )                    -- �ڋq�ꊇ�o�^�f�[�^���ڒ�`(���|�Ǘ�)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      AND      flv.enabled_flag = cv_yes                                        -- �g�p�\�t���O
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- �K�p�I����
      ORDER BY flv.lookup_code;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_param_expt            EXCEPTION;                              -- �p�����[�^NULL�G���[
    get_profile_expt          EXCEPTION;                              -- �v���t�@�C���擾�G���[
    process_date_expt         EXCEPTION;                              -- �Ɩ����t�擾���s�G���[
    select_expt               EXCEPTION;                              -- �擾���s�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-1.1 ���̓p�����[�^�iFILE_ID�A�t�H�[�}�b�g�j��NULL�`�F�b�N
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    -- ���̓p�����[�^��NULL�̏ꍇ
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_format;
      RAISE get_param_expt;
    END IF;
    --
    -- IN�p�����[�^���i�[
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 �v���t�@�C���擾
    --==============================================================
    lv_step := 'A-1.2';
    -- XXCMM:�ڋq�ꊇ�o�^�Ǘ��ҐE�ӃL�[
    gt_mgr_resp_key := FND_PROFILE.VALUE(cv_prf_resp_key);
    -- �擾�G���[��
    IF ( gt_mgr_resp_key IS NULL ) THEN
      lv_tkn_value := cv_prf_resp_key_n;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ�(MC�ڋq)
    -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
    IF ( gv_format = cv_file_format_mc ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_mc));
      -- �擾�G���[��
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_mc_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    -- XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ�(�X�܉c��)
    -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
    IF ( gv_format = cv_file_format_st ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_st));
      -- �擾�G���[��
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_st_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ�(�@�l�ڋq)
    -- �t�H�[�}�b�g�p�^�[���u503:�@�l�ڋq�v�̏ꍇ
    IF ( gv_format = cv_file_format_ho ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_ho));
      -- �擾�G���[��
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_ho_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
    -- XXCMM:�ڋq�ꊇ�o�^�f�[�^���ڐ�(���|�Ǘ���ڋq)
    -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ���ڋq�v�̏ꍇ
    IF ( gv_format = cv_file_format_ur ) THEN
      gn_item_num := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_item_num_ur));
      -- �擾�G���[��
      IF ( gn_item_num IS NULL ) THEN
        lv_tkn_value := cv_prf_item_num_ur_n;
        RAISE get_profile_expt;
      END IF;
    END IF;
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    -- XXCMM:�������o�͌`�������l
    gv_output_form := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_output_form));
    -- �擾�G���[��
    IF ( gv_output_form IS NULL ) THEN
      lv_tkn_value := cv_prf_output_form_n;
      RAISE get_profile_expt;
    END IF;
    --
    -- XXCMM:���������s�T�C�N�������l
    gv_prt_cycle := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_prt_cycle));
    -- �擾�G���[��
    IF ( gv_prt_cycle IS NULL ) THEN
      lv_tkn_value := cv_prf_prt_cycle_n;
      RAISE get_profile_expt;
    END IF;
    -- XXCMM:����������P�ʏ����l
    gv_inv_unit := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_inv_unit));
    -- �擾�G���[��
    IF ( gv_inv_unit IS NULL ) THEN
      lv_tkn_value := cv_prf_inv_unit_n;
      RAISE get_profile_expt;
    END IF;
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ���ڋq�v�̏ꍇ
    IF ( gv_format = cv_file_format_ur ) THEN
      --��v����ID
      gt_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_set_of_bks_id));
      -- �擾�G���[��
      IF ( gt_set_of_bks_id IS NULL ) THEN
        lv_tkn_value := cv_prf_set_of_bks_id_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_���
      gt_ur_kaisya := FND_PROFILE.VALUE(cv_prf_ur_kaisya);
      -- �擾�G���[��
      IF ( gt_ur_kaisya IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kaisya_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����
      gt_ur_bumon := FND_PROFILE.VALUE(cv_prf_ur_bumon);
      -- �擾�G���[��
      IF ( gt_ur_bumon IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_bumon_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_����Ȗ�
      gt_ur_kanjyou := FND_PROFILE.VALUE(cv_prf_ur_kanjyou);
      -- �擾�G���[��
      IF ( gt_ur_kanjyou IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kanjyou_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�⏕�Ȗ�
      gt_ur_hojyo := FND_PROFILE.VALUE(cv_prf_ur_hojyo);
      -- �擾�G���[��
      IF ( gt_ur_hojyo IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_hojyo_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�ڋq�R�[�h
      gt_ur_kokyaku := FND_PROFILE.VALUE(cv_prf_ur_kokyaku);
      -- �擾�G���[��
      IF ( gt_ur_kokyaku IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kokyaku_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_��ƃR�[�h
      gt_ur_kigyou := FND_PROFILE.VALUE(cv_prf_ur_kigyou);
      -- �擾�G���[��
      IF ( gt_ur_kigyou IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_kigyou_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���P
      gt_ur_yobi1 := FND_PROFILE.VALUE(cv_prf_ur_yobi1);
      -- �擾�G���[��
      IF ( gt_ur_yobi1 IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_yobi1_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ڋq�ꊇ�o�^�i���|�Ǘ���ڋq�j�p_�\���Q
      gt_ur_yobi2 := FND_PROFILE.VALUE(cv_prf_ur_yobi2);
      -- �擾�G���[��
      IF ( gt_ur_yobi2 IS NULL ) THEN
        lv_tkn_value := cv_prf_ur_yobi2_n;
        RAISE get_profile_expt;
      END IF;
      --
-- Ver1.3 K.Nakamura add start
      -- �ҋ@�Ԋu�i�ڋq�C���^�t�F�[�X�j
      gn_inter_racust := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_inter_racust));
      -- �擾�G���[��
      IF ( gn_inter_racust IS NULL ) THEN
        lv_tkn_value := cv_prf_inter_racust_n;
        RAISE get_profile_expt;
      END IF;
      --
      -- �ő�ҋ@���ԁi�ڋq�C���^�t�F�[�X�j
      gn_max_racust := TO_NUMBER(FND_PROFILE.VALUE(cv_prf_max_racust));
      -- �擾�G���[��
      IF ( gn_max_racust IS NULL ) THEN
        lv_tkn_value := cv_prf_max_racust_n;
        RAISE get_profile_expt;
      END IF;
-- Ver1.3 K.Nakamura add end
      --
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    --
    --==============================================================
    -- A-1.3 �Ɩ����t�̎擾
    --==============================================================
    lv_step := 'A-1.3';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULL�`�F�b�N
    IF ( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
    --
    --==============================================================
    -- A-1.4 �ڋq�ꊇ�o�^���[�N��`���̎擾
    --==============================================================
    lv_step := 'A-1.4';
    BEGIN
      -- �ϐ��̏�����
      ln_cnt := 0;
      -- �e�[�u����`�擾LOOP
      <<def_info_loop>>
      FOR get_def_info_rec IN get_def_info_cur LOOP
        ln_cnt := ln_cnt + 1;
        g_item_def_tab(ln_cnt).item_name      := get_def_info_rec.item_name;       -- ���ږ�
        g_item_def_tab(ln_cnt).item_attribute := get_def_info_rec.item_attribute;  -- ���ڑ���
        g_item_def_tab(ln_cnt).item_essential := get_def_info_rec.item_essential;  -- �K�{�t���O
        g_item_def_tab(ln_cnt).item_length    := get_def_info_rec.item_length;     -- ���ڂ̒���(��������)
        g_item_def_tab(ln_cnt).decim          := get_def_info_rec.decim;           -- ���ڂ̒���(�����_�ȉ�)
      END LOOP def_info_loop
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value := cv_upload_def_info;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.5 �t�@�C���A�b�v���[�h���̎擾
    --==============================================================
    lv_step := 'A-1.5';
    BEGIN
      SELECT   flv.meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type  = cv_file_upload_obj                            -- �t�@�C���A�b�v���[�h�I�u�W�F�N�g
      AND      flv.lookup_code  = gv_format                                     -- �t�@�C���t�H�[�}�b�g
      AND      flv.enabled_flag = cv_yes                                        -- �g�p�\�t���O
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- �K�p�J�n��
      AND      NVL(flv.end_date_active,   gd_process_date) >= gd_process_date   -- �K�p�I����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tkn_value := cv_file_upload_name;
        RAISE select_expt;
    END;
    --
    --==============================================================
    -- A-1.6 CSV�t�@�C�����̎擾�����b�N�擾
    --==============================================================
    lv_step := 'A-1.6';
    SELECT   fui.file_name                                                      -- �t�@�C����
            ,fui.created_by                                                     -- �쐬��
            ,fui.creation_date                                                  -- �쐬��
    INTO     lv_csv_file_name
            ,ln_created_by
            ,ld_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui                                   -- �t�@�C���A�b�v���[�hIF�e�[�u��
    WHERE    fui.file_id           = gn_file_id                                 -- �t�@�C��ID
      AND    fui.file_content_type = gv_format                                  -- �t�@�C���t�H�[�}�b�g
    FOR UPDATE NOWAIT
    ;
--
    --==============================================================
    -- A-1.7 EBS���O�C�����[�U�[�E�ӃL�[�擾
    --==============================================================
    lv_step := 'A-1.7';
    -- �E��ID���擾
    gn_resp_id      := fnd_profile.value(cv_prf_resp_id);
    -- �E�ӃA�v���P�[�V����ID���擾
    gn_resp_appl_id := fnd_global.resp_appl_id;
--
    -- EBS���O�C�����[�U�̐E�ӃL�[�擾
    SELECT  fr.responsibility_key                             -- �E�ӃL�[
    INTO    gt_responsibility_key                             -- �E�ӃL�[
    FROM    fnd_responsibility fr                             -- �E�Ӄ}�X�^
    WHERE   fr.responsibility_id  = gn_resp_id
    AND     fr.application_id     = gn_resp_appl_id;          -- �E�ӃA�v���P�[�V����ID
--
    -- NULL�`�F�b�N
    IF ( gt_responsibility_key IS NULL ) THEN
      lv_tkn_value := cv_user_resp_key;
      RAISE select_expt;
    END IF;
--
    --==============================================================
    -- A-1.8 �c��OU�̑g�DID�擾
    --==============================================================
    lv_step := 'A-1.8';
    -- �c��OU�̑g�DID�擾
      SELECT haou.organization_id                               -- �c�Ƒg�DID
      INTO   gv_sal_org_id
      FROM   hr_all_organization_units haou                     -- �l���g�D�}�X�^�e�[�u��
      WHERE  haou.name = cv_sales_ou
      AND    ROWNUM    = 1
      ;
--
    -- NULL�`�F�b�N
    IF ( gv_sal_org_id IS NULL ) THEN
      lv_tkn_value := cv_sal_org_id;
      RAISE select_expt;
    END IF;
-- 
    --==============================================================
    -- A-1.9 �������_�R�[�h�擾
    --==============================================================
    lv_step := 'A-1.9';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�A�u502:�X�܉c�Ɓv�̏ꍇ
    IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st )) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      -- ���_�S���҂̏ꍇ�A�������_�R�[�h���擾
      IF ( gt_responsibility_key <> gt_mgr_resp_key ) THEN
        -- EBS���O�C�����[�U�[ID���擾
        gn_user_id  := fnd_global.user_id;
  --
        -- EBS���O�C�����[�U�[ID���珊�����_�R�[�h�擾
        SELECT   paaf.ass_attribute5                                      -- �����R�[�h(�V)
        INTO     gt_belong_base_code                                      -- ���_�R�[�h
        FROM     per_all_people_f       papf                              -- �]�ƈ��}�X�^
                ,per_all_assignments_f  paaf                              -- �A�T�C�����g�}�X�^
                ,fnd_user               fu                                -- ���[�U�[�}�X�^
        WHERE    fu.user_id           = gn_user_id
        AND      fu.employee_id       = papf.person_id
        AND      papf.person_id       = paaf.person_id
        AND      TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)
                                    AND TRUNC(papf.effective_end_date)
        AND      TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date)
                                    AND TRUNC(paaf.effective_end_date);
        -- NULL�`�F�b�N
        IF ( gt_belong_base_code IS NULL ) THEN
          lv_tkn_value := cv_belong_base_code;
          RAISE select_expt;
        END IF;
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ���ڋq�v�̏ꍇ
    IF ( gv_format = cv_file_format_ur ) THEN
      --==============================================================
      -- A-1.10 CCID�擾
      --==============================================================
      lv_step := 'A-1.10';
      -- A-1-2�Ŏ擾������v����ID����CCID���擾
      BEGIN
        SELECT glcc.code_combination_id code_combination_id
        INTO   gt_urikake_misyuukin_id
        FROM   gl_code_combinations glcc   -- CCID���
              ,gl_sets_of_books     gsob   -- ����Ȗڑg����
        WHERE  gsob.set_of_books_id      = gt_set_of_bks_id           -- ��v����ID
        AND    glcc.chart_of_accounts_id = gsob.chart_of_accounts_id  --����Ȗڑg����ID
        AND    glcc.segment1             = gt_ur_kaisya
        AND    glcc.segment2             = gt_ur_bumon
        AND    glcc.segment3             = gt_ur_kanjyou
        AND    glcc.segment4             = gt_ur_hojyo
        AND    glcc.segment5             = gt_ur_kokyaku
        AND    glcc.segment6             = gt_ur_kigyou
        AND    glcc.segment7             = gt_ur_yobi1
        AND    glcc.segment8             = gt_ur_yobi2
        AND    gd_process_date BETWEEN NVL( glcc.start_date_active, gd_process_date )
                               AND     NVL( glcc.end_date_active,   gd_process_date )
        AND    glcc.enabled_flag         =  cv_yes
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_value := cv_ccid;
          RAISE select_expt;
      END;
      --
      --==============================================================
      -- A-1.11 ����������Z�b�gID�擾
      --==============================================================
      lv_step := 'A-1.11';
      BEGIN
        SELECT aah.autocash_hierarchy_id autocash_hierarchy_id
        INTO   gt_autocash_hierarchy_id
        FROM   ar_autocash_hierarchies aah
        WHERE  aah.hierarchy_name  =  cv_hrrchy_name
        AND    aah.status          =  cv_a             -- �L��
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_value := cv_aut_hrrchy_id;
          RAISE select_expt;
      END;
    --
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    --
    --==============================================================
    -- A-1.12 IN�p�����[�^�̏o��
    --==============================================================
    lv_step := 'A-1.13';
    lv_up_name     := xxccp_common_pkg.get_msg(                                 -- �A�b�v���[�h���̂̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00021                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_up_name                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_upload_obj                        -- �g�[�N���l1
                      );
    lv_file_name   := xxccp_common_pkg.get_msg(                                 -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00022                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_name                     -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_csv_file_name                     -- �g�[�N���l1
                      );
    lv_file_id     := xxccp_common_pkg.get_msg(                                 -- �t�@�C��ID�̏o��
                        iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcmm_00023                   -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_file_id                       -- �g�[�N���R�[�h1
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                  -- �g�[�N���l1
                      );
    lv_file_format := xxccp_common_pkg.get_msg(                                 -- �t�H�[�}�b�g�̏o��
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00024                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_file_format                    -- �g�[�N���R�[�h1
                      ,iv_token_value1 => gv_format                             -- �g�[�N���l1
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                                 -- �o�͂ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                                    -- ���O�ɕ\��
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** �p�����[�^NULL�G���[ ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10323            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_param_name             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �v���t�@�C���擾�G���[ ***
    WHEN get_profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00002            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_ng_profile             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �Ɩ����t�擾���s�G���[ ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00018            -- ���b�Z�[�W
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    --*** �擾���s�G���[ ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10324            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_value                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_tkn_value                  -- �g�[�N���l1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    --
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10337            -- ���b�Z�[�W
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : validate_cust_wk
   * Description      : �ڋq�ꊇ�o�^���[�N�f�[�^�Ó����`�F�b�N (A-4)
   ***********************************************************************************/
  PROCEDURE validate_cust_wk(
    i_wk_cust_rec  IN  xxcmm_wk_cust_upload%ROWTYPE                        -- �ڋq�ꊇ�o�^���[�N���
   ,ov_errbuf      OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_cust_wk';              -- �v���O������
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
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_tkn_value              VARCHAR2(100);                          -- �g�[�N���l
    ln_cnt                    NUMBER;                                 -- �J�E���g�p
    lv_check_status           VARCHAR2(1);                            -- �`�F�b�N�X�e�[�^�X
    lv_check_flag             VARCHAR2(1);                            -- �`�F�b�N�t���O
-- Ver1.5 add start
    lt_offset_cust_code       xxcmm_cust_accounts.offset_cust_code%TYPE;    -- ���E�p�ڋq�R�[�h
-- Ver1.5 add end
    l_validate_cust_tab       g_check_data_ttype;
    --
    ln_check_cnt              NUMBER;
    lv_required_item          VARCHAR2(2000);
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRM�ϐ��ޔ�p
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �`�F�b�N�X�e�[�^�X�̏�����
    lv_check_status := cv_status_normal;
-- Ver1.5 add start
    lt_offset_cust_code  := NULL;    -- ���E�p�ڋq�R�[�h
-- Ver1.5 add end
    --==============================================================
    -- ���C������LOOP
    --==============================================================
    lv_step := 'A-4.1';
    --
    -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
    IF ( gv_format = cv_file_format_mc ) THEN
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- �ڋq��
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- �ڋq���J�i
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- ����
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_status;                       -- �ڋq�X�e�[�^�X
      l_validate_cust_tab(5)  := i_wk_cust_rec.sale_base_code;                        -- ���㋒�_
      l_validate_cust_tab(6)  := i_wk_cust_rec.sales_chain_code;                      -- �̔���`�F�[��
      l_validate_cust_tab(7)  := i_wk_cust_rec.delivery_chain_code;                   -- �[�i��`�F�[��
      l_validate_cust_tab(8)  := i_wk_cust_rec.postal_code;                           -- �X�֔ԍ�
      l_validate_cust_tab(9)  := i_wk_cust_rec.state;                                 -- �s���{��
      l_validate_cust_tab(10) := i_wk_cust_rec.city;                                  -- �s�E��
      l_validate_cust_tab(11) := i_wk_cust_rec.address1;                              -- �Z���P
      l_validate_cust_tab(12) := i_wk_cust_rec.address2;                              -- �Z���Q
      l_validate_cust_tab(13) := i_wk_cust_rec.address3;                              -- �n��R�[�h
      l_validate_cust_tab(14) := i_wk_cust_rec.tel_no;                                -- �d�b�ԍ�
      l_validate_cust_tab(15) := i_wk_cust_rec.fax;                                   -- FAX
      l_validate_cust_tab(16) := i_wk_cust_rec.business_low_type_tmp;                 -- �Ƒԏ�����(��)
      l_validate_cust_tab(17) := i_wk_cust_rec.manager_name;                          -- �X����
      l_validate_cust_tab(18) := i_wk_cust_rec.emp_number;                            -- �Ј���
      l_validate_cust_tab(19) := i_wk_cust_rec.rest_emp_name;                         -- �S���ҋx��
      l_validate_cust_tab(20) := i_wk_cust_rec.mc_hot_deg;                            -- MC�FHOT�x
      l_validate_cust_tab(21) := i_wk_cust_rec.mc_importance_deg;                     -- MC�F�d�v�x
      l_validate_cust_tab(22) := i_wk_cust_rec.mc_conf_info;                          -- MC�F�������
      l_validate_cust_tab(23) := i_wk_cust_rec.mc_business_talk_details;              -- MC�F���k�o��
      l_validate_cust_tab(24) := i_wk_cust_rec.resource_no;                           -- �S���c�ƈ�
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete start by Shigeto.Niki
--      l_validate_cust_tab(25) := i_wk_cust_rec.resource_s_date;                       -- �K�p�J�n��(�S���c�ƈ�)
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete end by Shigeto.Niki
-- Ver1.5 add start
      l_validate_cust_tab(25) := i_wk_cust_rec.offset_cust_code;                      -- ���E�p�ڋq�R�[�h
      l_validate_cust_tab(26) := i_wk_cust_rec.bp_customer_code;                      -- �����ڋq�R�[�h
-- Ver1.5 add end
    --
    -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
    --ELSE
    ELSIF ( gv_format = cv_file_format_st ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- �ڋq��
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- �ڋq���J�i
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- ����
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_class_code;                   -- �ڋq�敪
      l_validate_cust_tab(5)  := i_wk_cust_rec.customer_status;                       -- �ڋq�X�e�[�^�X
      l_validate_cust_tab(6)  := i_wk_cust_rec.sale_base_code;                        -- ���㋒�_
      l_validate_cust_tab(7)  := i_wk_cust_rec.sales_chain_code;                      -- �̔���`�F�[��
      l_validate_cust_tab(8)  := i_wk_cust_rec.delivery_chain_code;                   -- �[�i��`�F�[��
      l_validate_cust_tab(9)  := i_wk_cust_rec.postal_code;                           -- �X�֔ԍ�
      l_validate_cust_tab(10) := i_wk_cust_rec.state;                                 -- �s���{��
      l_validate_cust_tab(11) := i_wk_cust_rec.city;                                  -- �s�E��
      l_validate_cust_tab(12) := i_wk_cust_rec.address1;                              -- �Z���P
      l_validate_cust_tab(13) := i_wk_cust_rec.address2;                              -- �Z���Q
      l_validate_cust_tab(14) := i_wk_cust_rec.address3;                              -- �n��R�[�h
      l_validate_cust_tab(15) := i_wk_cust_rec.tel_no;                                -- �d�b�ԍ�
      l_validate_cust_tab(16) := i_wk_cust_rec.fax;                                   -- FAX
      l_validate_cust_tab(17) := i_wk_cust_rec.business_low_type;                     -- �Ƒԏ�����
      l_validate_cust_tab(18) := i_wk_cust_rec.industry_div;                          -- �Ǝ�
      l_validate_cust_tab(19) := i_wk_cust_rec.torihiki_form;                         -- ����`��
      l_validate_cust_tab(20) := i_wk_cust_rec.delivery_form;                         -- �z���`��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
    ELSIF ( gv_format = cv_file_format_ho ) THEN
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- �ڋq��
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- �ڋq���J�i
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- ����
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_class_code;                   -- �ڋq�敪
      l_validate_cust_tab(5)  := i_wk_cust_rec.customer_status;                       -- �ڋq�X�e�[�^�X
      l_validate_cust_tab(6)  := i_wk_cust_rec.sale_base_code;                        -- ���㋒�_
      l_validate_cust_tab(7)  := i_wk_cust_rec.postal_code;                           -- �X�֔ԍ�
      l_validate_cust_tab(8)  := i_wk_cust_rec.state;                                 -- �s���{��
      l_validate_cust_tab(9)  := i_wk_cust_rec.city;                                  -- �s�E��
      l_validate_cust_tab(10) := i_wk_cust_rec.address1;                              -- �Z���P
      l_validate_cust_tab(11) := i_wk_cust_rec.address2;                              -- �Z���Q
      l_validate_cust_tab(12) := i_wk_cust_rec.address3;                              -- �n��R�[�h
      l_validate_cust_tab(13) := i_wk_cust_rec.tel_no;                                -- �d�b�ԍ�
      l_validate_cust_tab(14) := i_wk_cust_rec.fax;                                   -- FAX
      l_validate_cust_tab(15) := i_wk_cust_rec.tdb_code;                              -- TDB�R�[�h
      l_validate_cust_tab(16) := i_wk_cust_rec.base_code;                             -- �{���S�����_
      l_validate_cust_tab(17) := i_wk_cust_rec.credit_limit;                          -- �^�M���x�z
      l_validate_cust_tab(18) := i_wk_cust_rec.decide_div;                            -- ����敪
      l_validate_cust_tab(19) := i_wk_cust_rec.approval_date;                         -- ���ٓ��t
    --
    -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
    ELSIF ( gv_format = cv_file_format_ur ) THEN
      l_validate_cust_tab(1)  := i_wk_cust_rec.customer_name;                         -- �ڋq��
      l_validate_cust_tab(2)  := i_wk_cust_rec.customer_name_kana;                    -- �ڋq���J�i
      l_validate_cust_tab(3)  := i_wk_cust_rec.customer_name_ryaku;                   -- ����
      l_validate_cust_tab(4)  := i_wk_cust_rec.customer_class_code;                   -- �ڋq�敪
      l_validate_cust_tab(5)  := i_wk_cust_rec.customer_status;                       -- �ڋq�X�e�[�^�X
      l_validate_cust_tab(6)  := i_wk_cust_rec.sale_base_code;                        -- ���㋒�_
      l_validate_cust_tab(7)  := i_wk_cust_rec.sales_chain_code;                      -- �̔���`�F�[��
      l_validate_cust_tab(8)  := i_wk_cust_rec.delivery_chain_code;                   -- �[�i��`�F�[��
      l_validate_cust_tab(9)  := i_wk_cust_rec.postal_code;                           -- �X�֔ԍ�
      l_validate_cust_tab(10) := i_wk_cust_rec.state;                                 -- �s���{��
      l_validate_cust_tab(11) := i_wk_cust_rec.city;                                  -- �s�E��
      l_validate_cust_tab(12) := i_wk_cust_rec.address1;                              -- �Z���P
      l_validate_cust_tab(13) := i_wk_cust_rec.address2;                              -- �Z���Q
      l_validate_cust_tab(14) := i_wk_cust_rec.address3;                              -- �n��R�[�h
      l_validate_cust_tab(15) := i_wk_cust_rec.tel_no;                                -- �d�b�ԍ�
      l_validate_cust_tab(16) := i_wk_cust_rec.fax;                                   -- FAX
-- Ver1.3 K.Nakamura add start
      l_validate_cust_tab(17) := i_wk_cust_rec.receipt_method_name;                   -- �x�����@
-- Ver1.3 K.Nakamura add end
-- Ver1.3 K.Nakamura mod start
--      l_validate_cust_tab(17) := i_wk_cust_rec.business_low_type;                     -- �Ƒԏ�����
--      l_validate_cust_tab(18) := i_wk_cust_rec.industry_div;                          -- �Ǝ�
--      l_validate_cust_tab(19) := i_wk_cust_rec.tax_div;                               -- ����ŋ敪
--      l_validate_cust_tab(20) := i_wk_cust_rec.tax_rounding_rule;                     -- �ŋ��[������
--      l_validate_cust_tab(21) := i_wk_cust_rec.invoice_grp_code;                      -- ���|�R�[�h1�i�������j
--      l_validate_cust_tab(22) := i_wk_cust_rec.output_form;                           -- �������o�͌`��
--      l_validate_cust_tab(23) := i_wk_cust_rec.prt_cycle;                             -- ���������s�T�C�N��
--      l_validate_cust_tab(24) := i_wk_cust_rec.payment_term;                          -- �x������
--      l_validate_cust_tab(25) := i_wk_cust_rec.delivery_base_code;                    -- �[�i���_
--      l_validate_cust_tab(26) := i_wk_cust_rec.bill_base_code;                        -- �������_
--      l_validate_cust_tab(27) := i_wk_cust_rec.receiv_base_code;                      -- �������_
--      l_validate_cust_tab(28) := i_wk_cust_rec.sales_head_base_code;                  -- �̔���{���S�����_
      l_validate_cust_tab(18) := i_wk_cust_rec.business_low_type;                     -- �Ƒԏ�����
      l_validate_cust_tab(19) := i_wk_cust_rec.industry_div;                          -- �Ǝ�
      l_validate_cust_tab(20) := i_wk_cust_rec.tax_div;                               -- ����ŋ敪
      l_validate_cust_tab(21) := i_wk_cust_rec.tax_rounding_rule;                     -- �ŋ��[������
      l_validate_cust_tab(22) := i_wk_cust_rec.invoice_grp_code;                      -- ���|�R�[�h1�i�������j
      l_validate_cust_tab(23) := i_wk_cust_rec.output_form;                           -- �������o�͌`��
      l_validate_cust_tab(24) := i_wk_cust_rec.prt_cycle;                             -- ���������s�T�C�N��
      l_validate_cust_tab(25) := i_wk_cust_rec.payment_term;                          -- �x������
      l_validate_cust_tab(26) := i_wk_cust_rec.delivery_base_code;                    -- �[�i���_
      l_validate_cust_tab(27) := i_wk_cust_rec.bill_base_code;                        -- �������_
      l_validate_cust_tab(28) := i_wk_cust_rec.receiv_base_code;                      -- �������_
      l_validate_cust_tab(29) := i_wk_cust_rec.sales_head_base_code;                  -- �̔���{���S�����_
-- Ver1.3 K.Nakamura mod end
-- Ver1.3 K.Nakamura add start
      l_validate_cust_tab(30) := i_wk_cust_rec.card_company_kbn;                      -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
    --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    END IF;
    --
    -- �J�E���^�̏�����
    ln_check_cnt := 0;
    --
    <<validate_column_loop>>
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      -- �J�E���^�����Z
      ln_check_cnt := ln_check_cnt + 1;
      --
      lv_step := 'A-4.1�`3';
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => g_item_def_tab(ln_check_cnt).item_name                   -- ���ږ���
       ,iv_item_value   => l_validate_cust_tab(ln_check_cnt)                        -- ���ڂ̒l
       ,in_item_len     => g_item_def_tab(ln_check_cnt).item_length                 -- ���ڂ̒���(��������)
       ,in_item_decimal => g_item_def_tab(ln_check_cnt).decim                       -- ���ڂ̒����i�����_�ȉ��j
       ,iv_item_nullflg => g_item_def_tab(ln_check_cnt).item_essential              -- �K�{�t���O
       ,iv_item_attr    => g_item_def_tab(ln_check_cnt).item_attribute              -- ���ڂ̑���
       ,ov_errbuf       => lv_errbuf
       ,ov_retcode      => lv_retcode
       ,ov_errmsg       => lv_errmsg
      );
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN                                    -- �߂�l���ُ�̏ꍇ
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        gv_out_msg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name          =>  cv_msg_xxcmm_10338                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   =>  cv_tkn_input_line_no                  -- �g�[�N���R�[�h1
                        ,iv_token_value1  =>  i_wk_cust_rec.line_no                 -- �g�[�N���l1
                        ,iv_token_name2   =>  cv_tkn_errmsg                         -- �g�[�N���R�[�h2
                        ,iv_token_value2  =>  LTRIM(lv_errmsg)                      -- �g�[�N���l2
                       );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
      END IF;
    END LOOP validate_column_loop;
--
    -- �K�p�J�n����DATE�^�ɕϊ�
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete start by Shigeto.Niki
--    gd_apply_date := TO_DATE(i_wk_cust_rec.resource_s_date, cv_date_fmt_std);
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete end by Shigeto.Niki
--
    IF ( lv_check_status = cv_status_normal ) THEN
      --==============================================================
      -- A-4.2 �ڋq���`�F�b�N
      --==============================================================
      lv_step := 'A-4.2';
      -- �S�p�����`�F�b�N
      IF ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.customer_name ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �S�p�����`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10326          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_customer_name            -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.customer_name -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no        -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no       -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.3 ���̃`�F�b�N
      --==============================================================
      lv_step := 'A-4.3';
      -- �S�p�����`�F�b�N
      IF ( i_wk_cust_rec.customer_name_ryaku IS NOT NULL ) 
        AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.customer_name_ryaku ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �S�p�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_customer_name_ryaku                -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.customer_name_ryaku     -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.4 �ڋq���i�J�i�j�`�F�b�N
      --==============================================================
      lv_step := 'A-4.4';
      -- ���p�����`�F�b�N
      IF ( i_wk_cust_rec.customer_name_kana IS NOT NULL )
        AND ( xxccp_common_pkg.chk_single_byte( i_wk_cust_rec.customer_name_kana ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- ���p�����`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10327                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_customer_name_kana                 -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.customer_name_kana      -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.5 �ڋq�敪�`�F�b�N
      --==============================================================
      lv_step := 'A-4.5';
      -- �ڋq�敪�`�F�b�N
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
--      IF ( gv_format = cv_file_format_st )
--        AND ( i_wk_cust_rec.customer_class_code <> cv_tenpo_kbn ) THEN
      -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ�A�u15:�X�܉c�Ɓv�̂݋��e
      IF ( ( gv_format = cv_file_format_st ) AND ( i_wk_cust_rec.customer_class_code <> cv_tenpo_kbn ) )
        OR
      -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ�A�u13:�@�l�v�̂݋��e
         ( ( gv_format = cv_file_format_ho ) AND ( i_wk_cust_rec.customer_class_code <> cv_hojin_kbn ) )
        OR
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ�A�u14:���|�Ǘ��v�̂݋��e
         ( ( gv_format = cv_file_format_ur ) AND ( i_wk_cust_rec.customer_class_code <> cv_urikake_kbn ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �l�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10328                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_customer_class_code                -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.customer_class_code     -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.6 �ڋq�X�e�[�^�X�`�F�b�N
      --==============================================================
      lv_step := 'A-4.6';
      -- �ڋq�X�e�[�^�X�`�F�b�N
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ�A�u10:MC���v�u20:MC�v�̂݋��e
      IF (( gv_format = cv_file_format_mc ) AND ( i_wk_cust_rec.customer_status NOT IN ( cv_cust_status_mc_cand, cv_cust_status_mc )))
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        ---- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ�A�u99:�ΏۊO�v�̂݋��e
        --OR (( gv_format = cv_file_format_st ) AND ( i_wk_cust_rec.customer_status <> cv_cust_status_except )) THEN
        -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�A�u503:�@�l�v�A�u504:���|�Ǘ��v�̏ꍇ�A�u99:�ΏۊO�v�̂݋��e
        OR ( ( gv_format IN ( cv_file_format_st , cv_file_format_ho , cv_file_format_ur ) )
             AND ( i_wk_cust_rec.customer_status <> cv_cust_status_except ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �l�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10328                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_customer_status                    -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.customer_status         -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.7 ���㋒�_�`�F�b�N
      --==============================================================
      lv_step := 'A-4.7';
      -- ���㋒�_���݃`�F�b�N
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   fnd_flex_value_sets ffvs                                           -- �l�Z�b�g��`�}�X�^
            ,fnd_flex_values     ffv                                            -- �l�Z�b�g�}�X�^
      WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- �l�Z�b�gID
      AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF����(XX03_DEPARTMENT)
      AND    ffv.summary_flag         = cv_no                                   -- �q�l
      AND    ffv.flex_value           = i_wk_cust_rec.sale_base_code            -- ���㋒�_
      ;
      IF (ln_cnt = 0) THEN
        lv_check_status   := cv_status_error;
        ov_retcode      := cv_status_error;
        -- ���㋒�_���݃`�F�b�N�G���[���b�Z�[�W�擾
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10329                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_sale_base_code                     -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.sale_base_code          -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.8 �����_����
      --==============================================================
      lv_step := 'A-4.8';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�A�u502:�X�܉c�Ɓv�̏ꍇ
      IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st )) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        -- ���_�S���҂̏ꍇ�A�����_������s�Ȃ�
        IF ( gt_responsibility_key <> gt_mgr_resp_key ) THEN
          SELECT COUNT(1)
          INTO   ln_cnt
          FROM   xxcmm_cust_accounts xca                                            -- �ڋq�ǉ����}�X�^
          WHERE  xca.sale_base_code = i_wk_cust_rec.sale_base_code
          AND    (EXISTS (SELECT 'X'
                          FROM   hz_cust_accounts    hca1                           -- �ڋq�}�X�^
                                ,xxcmm_cust_accounts xca1                           -- �ڋq�ǉ����}�X�^
                          WHERE  hca1.cust_account_id      = xca1.customer_id
                            AND  hca1.cust_account_id      = xca.customer_id
                            AND  hca1.customer_class_code  = cv_base_kbn
                            AND  xca1.sale_base_code       = gt_belong_base_code
                         )
                     OR EXISTS (SELECT 'X'
                                FROM   hz_cust_accounts    hca2                     -- �ڋq�}�X�^
                                      ,xxcmm_cust_accounts xca2                     -- �ڋq�ǉ����}�X�^
                                WHERE  hca2.cust_account_id      = xca2.customer_id
                                  AND  hca2.cust_account_id      = xca.customer_id
                                  AND  hca2.customer_class_code  = cv_base_kbn
                                  AND  xca2.sale_base_code
                                   IN  (SELECT  hca3.account_number
                                         FROM   hz_cust_accounts    hca3            -- �ڋq�}�X�^
                                               ,xxcmm_cust_accounts xca3            -- �ڋq�ǉ����}�X�^
                                         WHERE  hca3.cust_account_id      = xca3.customer_id
                                           AND  hca3.customer_class_code  = cv_base_kbn
                                           AND  xca3.management_base_code = gt_belong_base_code
                                       )
                               )
                 )
           AND   ROWNUM = 1;
          -- �����_����G���[���b�Z�[�W�擾
          IF (ln_cnt = 0) THEN
            lv_check_status   := cv_status_error;
            ov_retcode        := cv_status_error;
            -- �����_����G���[���b�Z�[�W�擾
            gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_10325                    -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_cust_rec.line_no                 -- �g�[�N���l1
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
          END IF;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      --
      --==============================================================
      -- A-4.9 �̔���`�F�[���`�F�b�N
      --==============================================================
      lv_step := 'A-4.9';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- �t�H�[�}�b�g�p�^�[���u501:MC�v�A�u502:�X�܉c�Ɓv�A�u504:���|�Ǘ��v�̏ꍇ�A�̔���`�F�[�����݃`�F�b�N�����{
      IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        -- �̔���`�F�[�����݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_xxcmm_chain_code                         -- �`�F�[���X�R�[�h
        AND    flv.lookup_code        = i_wk_cust_rec.sales_chain_code              -- �̔���`�F�[��
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --�̔���`�F�[�����݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_s_chain_code                       -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.sales_chain_code        -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      --
      --==============================================================
      -- A-4.10 �[�i��`�F�[���`�F�b�N
      --==============================================================
      lv_step := 'A-4.10';
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      -- �t�H�[�}�b�g�p�^�[���u501:MC�v�A�u502:�X�܉c�Ɓv�A�u504:���|�Ǘ��v�̏ꍇ�A�̔���`�F�[�����݃`�F�b�N�����{
      IF ( gv_format IN ( cv_file_format_mc , cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        -- �[�i��`�F�[�����݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_xxcmm_chain_code                         -- �`�F�[���X�R�[�h
        AND    flv.lookup_code        = i_wk_cust_rec.delivery_chain_code           -- �[�i��`�F�[��
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --�[�i��`�F�[�����݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_d_chain_code                       -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.delivery_chain_code     -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      --
      --==============================================================
      -- A-4.11 �X�֔ԍ��`�F�b�N
      --==============================================================
      lv_step := 'A-4.11';
      -- �X�֔ԍ����p����7���`�F�b�N
      IF (xxccp_common_pkg.chk_number(i_wk_cust_rec.postal_code) <> TRUE)
        OR (LENGTHB(i_wk_cust_rec.postal_code) <> 7)
      THEN
        lv_check_status   := cv_status_error;
        ov_retcode        := cv_status_error;
        -- �X�֔ԍ��`�F�b�N�G���[���b�Z�[�W�擾
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10331                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_postal_code                        -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.postal_code             -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.12 �s���{���`�F�b�N
      --==============================================================
      lv_step := 'A-4.12';
      -- �S�p�����`�F�b�N
      IF (xxccp_common_pkg.chk_double_byte(i_wk_cust_rec.state) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �S�p�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_state                              -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.state                   -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.13 �s�E��`�F�b�N
      --==============================================================
      lv_step := 'A-4.13';
      -- �S�p�����`�F�b�N
      IF (xxccp_common_pkg.chk_double_byte(i_wk_cust_rec.city) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �S�p�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_city                               -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.city                    -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.14 �Z���P�`�F�b�N
      --==============================================================
      lv_step := 'A-4.14';
      -- �S�p�����`�F�b�N
      IF (xxccp_common_pkg.chk_double_byte(i_wk_cust_rec.address1) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �S�p�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_address1                           -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.address1                -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.15 �Z���Q�`�F�b�N
      --==============================================================
      lv_step := 'A-4.15';
      -- �S�p�����`�F�b�N
      IF ( i_wk_cust_rec.address2 IS NOT NULL ) 
        AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.address2 ) <> TRUE ) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �S�p�`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_address2                           -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.address2                -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.16 �n��R�[�h�`�F�b�N
      --==============================================================
      lv_step := 'A-4.16';
      -- �n��R�[�h���݃`�F�b�N
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
      WHERE  flv.lookup_type        = cv_lookup_chiku_code                        -- �n��R�[�h
      AND    flv.lookup_code        = i_wk_cust_rec.address3                      -- �n��R�[�h
      AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
      AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
      AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
      --
      IF (ln_cnt = 0) THEN
        lv_check_status   := cv_status_error;
        ov_retcode        := cv_status_error;
        -- �n��R�[�h���݃`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_address3                           -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.address3                -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.17 �d�b�ԍ��`�F�b�N
      --==============================================================
      lv_step := 'A-4.17';
      -- �d�b�ԍ��`�F�b�N
      IF (xxccp_common_pkg.chk_tel_format(i_wk_cust_rec.tel_no) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �d�b�ԍ��`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10332                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_tel_no                             -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.tel_no                  -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.18 FAX�`�F�b�N
      --==============================================================
      lv_step := 'A-4.18';
      -- FAX�`�F�b�N
      IF ( i_wk_cust_rec.fax IS NOT NULL ) 
        AND (xxccp_common_pkg.chk_tel_format(i_wk_cust_rec.fax) <> TRUE) THEN
        lv_check_status := cv_status_error;
        ov_retcode      := cv_status_error;
        -- �d�b�ԍ��`�F�b�N�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_10332                    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_fax                                -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                      ,iv_token_value2 => i_wk_cust_rec.fax                     -- �g�[�N���l2
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                      ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
        lv_check_flag := cv_status_error;
      END IF;
      --
-- Ver1.3 K.Nakamura add start
      --==============================================================
      -- A-4.19 �x�����@�`�F�b�N
      --==============================================================
      lv_step := 'A-4.19';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- �x�����@���݃`�F�b�N
        SELECT COUNT(1)           cnt
        INTO   ln_cnt
        FROM   ar_receipt_methods arm                                  -- �x�����@�}�X�^
        WHERE  arm.name = i_wk_cust_rec.receipt_method_name            -- ����
        AND    NVL(arm.start_date, gd_process_date) <= gd_process_date -- �J�n��
        AND    NVL(arm.end_date,   gd_process_date) >= gd_process_date -- �I����
        ;
        IF (ln_cnt = 0) THEN
            lv_check_status   := cv_status_error;
            ov_retcode        := cv_status_error;
            -- �x�����@���݃`�F�b�N�G���[
            gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_10346                    -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_receipt_methods                    -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_cust_rec.receipt_method_name     -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                          ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg);
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
        END IF;
      END IF;
-- Ver1.3 K.Nakamura add end
      --==============================================================
      -- A-4.20 �Ƒԏ�����(��)�`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.19';
      lv_step := 'A-4.20';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
      IF ( gv_format = cv_file_format_mc ) THEN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_gyotai_sho                        -- �Ƒԏ�����
        AND    flv.lookup_code        = i_wk_cust_rec.business_low_type_tmp         -- �Ƒԏ�����(��)
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �Ƒԏ�����(��)���݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_b_row_type_tmp                     -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.business_low_type_tmp   -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.21 �X�����`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.20';
      lv_step := 'A-4.21';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.manager_name IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.manager_name ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �S�p�`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_manager_name                       -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.manager_name            -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.22 �S���ҋx���`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.21';
      lv_step := 'A-4.22';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.rest_emp_name IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.rest_emp_name ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �S�p�`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_rest_emp_name                      -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.rest_emp_name           -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.23 MC:�d�v�x�`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.22';
      lv_step := 'A-4.23';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_importance_deg IS NOT NULL ) THEN
        -- MC:�d�v�x���݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_mcjuyodo                          -- MC:�d�v�x
        AND    flv.lookup_code        = i_wk_cust_rec.mc_importance_deg             -- MC:�d�v�x
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- MC:�d�v�x���݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_mc_importance_deg                  -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.mc_importance_deg       -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.24 MC:HOT�x�`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.23';
      lv_step := 'A-4.24';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_hot_deg IS NOT NULL ) THEN
        -- MC:HOT�x���݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_mchotdo                           -- MC:HOT�x
        AND    flv.lookup_code        = i_wk_cust_rec.mc_hot_deg                    -- MC:HOT�x
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- MC:HOT�x���݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_mc_hot_deg                         -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.mc_hot_deg              -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.25 MC:�������`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.24';
      lv_step := 'A-4.25';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_conf_info IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.mc_conf_info ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �S�p�`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10326                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_mc_conf_info                       -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.mc_conf_info            -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.26 MC:���k�o�܃`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.25';
      lv_step := 'A-4.26';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.mc_business_talk_details IS NOT NULL )
          AND ( xxccp_common_pkg.chk_double_byte( i_wk_cust_rec.mc_business_talk_details ) <> TRUE ) THEN
          lv_check_status := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �S�p�`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                     -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10326                     -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                           -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_mc_b_talk_details                   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                           -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.mc_business_talk_details -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                   -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                  -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-4.27 �S���c�ƈ��`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.26-1';
      lv_step := 'A-4.27';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
      IF ( gv_format = cv_file_format_mc ) THEN
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify start by Shigeto.Niki
--        -- �J�n�� < �Ɩ����t�̏ꍇ�̓G���[
--        IF (gd_apply_date < gd_process_date) THEN
--          lv_check_status   := cv_status_error;
--          ov_retcode        := cv_status_error;
--          -- �K�p�J�n�����̓`�F�b�N�G���[
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_msg_xxcmm_10333                    -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h1
--                        ,iv_token_value1 => i_wk_cust_rec.line_no                 -- �g�[�N���l1
--                        ,iv_token_name2  => cv_tkn_apply_date                     -- �g�[�N���R�[�h2
--                        ,iv_token_value2 => gd_apply_date                         -- �g�[�N���l2
--                       );
--          -- ���b�Z�[�W�o��
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.OUTPUT
--            ,buff   => gv_out_msg);
--          lv_check_flag := cv_status_error;
--          --
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--          lv_check_flag := cv_status_error;
--        END IF;
--        --
--        -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v���A�K�p�J�n�� => �Ɩ����t�̏ꍇ�A
--        -- �S���c�ƈ��̃��\�[�X�}�X�^���݃`�F�b�N�����{����
--        lv_step := 'A-4.26-2';
--        -- �S���c�ƈ����݃`�F�b�N
--        SELECT COUNT(1)
--        INTO   ln_cnt
--        FROM   jtf_rs_resource_extns   jrre         -- ���\�[�X�}�X�^
--              ,xxcso_employees_v3      xev3         -- �]�ƈ��}�X�^�i�ŐV�j�r���[3
--        WHERE  jrre.source_number    = xev3.employee_number
--        AND    jrre.category         = cv_category
--        AND    gd_apply_date BETWEEN jrre.start_date_active
--                                 AND NVL(jrre.end_date_active, TO_DATE(cv_max_date, cv_date_fmt_std))
--        AND    xev3.employee_number  = i_wk_cust_rec.resource_no
--        ;
        -- �S���c�ƈ����݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   jtf_rs_resource_extns_vl  jrre         -- ���\�[�X
              ,jtf_rs_group_members      jrgm         -- ���\�[�X�O���[�v�����o�[
              ,jtf_rs_groups_vl          jrgv         -- ���\�[�X�O���[�v
              ,per_all_people_f          papf         -- �]�ƈ��}�X�^
              ,per_all_assignments_f     paaf         -- �A�T�C�������g�}�X�^
              ,per_periods_of_service    ppos         -- �]�ƈ��T�[�r�X���ԃ}�X�^
        WHERE  papf.person_id               = jrre.source_id
        AND    papf.person_id               = paaf.person_id
        AND    papf.current_emp_or_apl_flag = cv_yes
        AND    paaf.period_of_service_id    = ppos.period_of_service_id
        AND    papf.effective_start_date    = ppos.date_start
        AND    ppos.actual_termination_date IS NULL
        AND    jrre.category                = cv_category
        AND    jrre.resource_id             = jrgm.resource_id
        AND    gd_process_date BETWEEN jrre.start_date_active 
                               AND NVL(jrre.end_date_active,TO_DATE(cv_max_date, cv_date_fmt_std))
        AND    jrgm.group_id                = jrgv.group_id
        AND    jrgm.delete_flag             = cv_no
        AND    gd_process_date BETWEEN jrgv.start_date_active 
                               AND NVL(jrgv.end_date_active,TO_DATE(cv_max_date, cv_date_fmt_std))
        AND    papf.employee_number         = i_wk_cust_rec.resource_no           -- �]�ƈ��ԍ�
        AND    jrgv.attribute1              = i_wk_cust_rec.sale_base_code        -- ���_�R�[�h
        AND    paaf.ass_attribute5          = i_wk_cust_rec.sale_base_code        -- ���_�R�[�h
        ;
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify end by Shigeto.Niki
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �S���c�ƈ����݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10334                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_value                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => i_wk_cust_rec.resource_no             -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.line_no                 -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_apply_date                     -- �g�[�N���R�[�h3
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify start by Shigeto.Niki
--                        ,iv_token_value3 => gd_apply_date                         -- �g�[�N���l3
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod start
--                        ,iv_token_value3 => gd_process_date                        -- �g�[�N���l3
                        ,iv_token_value3 => TO_CHAR( gd_process_date, cv_date_fmt_std )
                                                                                  -- �g�[�N���l3
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod end
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify end by Shigeto.Niki
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
        --
      END IF;
      --
      --==============================================================
      -- A-4.28 �Ƒԏ����ރ`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.27';
      lv_step := 'A-4.28';
-- Ver1.3 K.Nakamura add end
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
      ---- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
      --IF ( gv_format = cv_file_format_st ) THEN
      -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�������́u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format IN ( cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_gyotai_sho                        -- �Ƒԏ�����
        AND    flv.lookup_code        = i_wk_cust_rec.business_low_type             -- �Ƒԏ�����
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �Ƒԏ����ޑ��݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_gyotai_sho                         -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.business_low_type       -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.29 �Ǝ�`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.28';
      lv_step := 'A-4.29';
-- Ver1.3 K.Nakamura add end
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
      ---- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
      --IF ( gv_format = cv_file_format_st ) THEN
      -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�������́u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format IN ( cv_file_format_st , cv_file_format_ur ) ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_gyosyu                            -- �Ǝ�
        AND    flv.lookup_code        = i_wk_cust_rec.industry_div                  -- �Ǝ�
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �Ǝ푶�݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_industry_div                       -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.industry_div            -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.30 ����`�ԃ`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.29';
      lv_step := 'A-4.30';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
      IF ( gv_format = cv_file_format_st ) THEN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_torihiki                          -- ����`��
        AND    flv.lookup_code        = i_wk_cust_rec.torihiki_form                 -- ����`��
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- ����`�ԑ��݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_torihiki_form                      -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.torihiki_form           -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
      --==============================================================
      -- A-4.31 �z���`�ԃ`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.30';
      lv_step := 'A-4.31';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
      IF ( gv_format = cv_file_format_st ) THEN
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_haiso                             -- �z���`��
        AND    flv.lookup_code        = i_wk_cust_rec.delivery_form                 -- �z���`��
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �z���`�ԑ��݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_delivery_form                      -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.delivery_form           -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      --==============================================================
      -- A-4.32 �{���S�����_�`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.31';
      lv_step := 'A-4.32';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
      IF ( gv_format = cv_file_format_ho ) THEN
        -- �{���S�����_�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- �l�Z�b�g��`�}�X�^
              ,fnd_flex_values     ffv                                            -- �l�Z�b�g�}�X�^
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- �l�Z�b�gID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF����(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- �q�l
        AND    ffv.flex_value           = i_wk_cust_rec.base_code                 -- �{���S�����_
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- �J�n��
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- �I����
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �{���S�����_�`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10329                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_base_code                          -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.base_code               -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
    --
      --==============================================================
      -- A-4.33 ����敪�`�F�b�N
      --==============================================================
-- Ver1.3 K.Nakamura add start
--      lv_step := 'A-4.32';
      lv_step := 'A-4.33';
-- Ver1.3 K.Nakamura add end
      -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
      IF ( gv_format = cv_file_format_ho ) THEN
        -- ����敪�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_sohyo_kbn                         -- ���]�敪
        AND    flv.lookup_code        = i_wk_cust_rec.decide_div                    -- ����敪
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --����敪�`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_decide_div                         -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.decide_div              -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
-- Ver1.3 K.Nakamura del start
--      --==============================================================
--      -- A-4.33 ���ٓ��t�`�F�b�N
--      --==============================================================
--      lv_step := 'A-4.33';
--      -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
--      IF ( gv_format = cv_file_format_ho ) THEN
--        -- ���ٓ��t���Ɩ����t���ߋ��̓��t�̏ꍇ
--        IF ( TO_DATE(i_wk_cust_rec.approval_date, cv_date_fmt_std) < gd_process_date ) THEN
--          lv_check_status   := cv_status_error;
--          ov_retcode        := cv_status_error;
--          --���ٓ��t�`�F�b�N�G���[
--          gv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
--                        ,iv_name         => cv_msg_xxcmm_10345                    -- ���b�Z�[�W�R�[�h
--                        ,iv_token_name1  => cv_tkn_approval_date                  -- �g�[�N���R�[�h1
--                        ,iv_token_value1 => i_wk_cust_rec.approval_date           -- �g�[�N���l1
--                        ,iv_token_name2  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
--                        ,iv_token_value2 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
--                       );
--          -- ���b�Z�[�W�o��
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.OUTPUT
--            ,buff   => gv_out_msg);
--          lv_check_flag := cv_status_error;
--          --
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.LOG
--            ,buff   => gv_out_msg);
--          lv_check_flag := cv_status_error;
--        END IF;
--      END IF;
-- Ver1.3 K.Nakamura del end
      --==============================================================
      -- A-4.34 ����ŋ敪���݃`�F�b�N
      --==============================================================
      lv_step := 'A-4.34';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- ����ŋ敪���݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_syohizei_kbn                      -- ����ŋ敪
        AND    flv.lookup_code        = i_wk_cust_rec.tax_div                       -- ����ŋ敪
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --����ŋ敪���݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tax_div                            -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.tax_div                 -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.35 �ŋ��[�������`�F�b�N
      --==============================================================
      lv_step := 'A-4.35';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- �ŋ��[�������`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_tax_rule                          -- �ŋ��[������
        AND    flv.lookup_code        = i_wk_cust_rec.tax_rounding_rule             -- �ŋ��[������
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --�ŋ��[�������`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_tax_rounding_rule                  -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.tax_rounding_rule       -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.36 ���|�R�[�h1�i�������j���݃`�F�b�N
      --==============================================================
      lv_step := 'A-4.36';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- ���|�R�[�h1�i�������j���݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_invoice_grp                       -- ���|�R�[�h1�i�������j
        AND    flv.lookup_code        = i_wk_cust_rec.invoice_grp_code              -- ���|�R�[�h1�i�������j
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --���|�R�[�h1�i�������j���݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_invoice_grp_code                   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.invoice_grp_code        -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.37 �������o�͌`�����݃`�F�b�N
      --==============================================================
      lv_step := 'A-4.37';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- �������o�͌`�����݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_sekyusyo_ksk                      -- �������o�͌`��
        AND    flv.lookup_code        = i_wk_cust_rec.output_form                   -- �������o�͌`��
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --�������o�͌`�����݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_output_form                        -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.output_form             -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.38 ���������s�T�C�N�����݃`�F�b�N
      --==============================================================
      lv_step := 'A-4.38';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- ���������s�T�C�N�����݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                             -- LOOKUP�\
        WHERE  flv.lookup_type        = cv_lookup_invoice_cycl                      -- ���������s�T�C�N��
        AND    flv.lookup_code        = i_wk_cust_rec.prt_cycle                     -- ���������s�T�C�N��
        AND    flv.enabled_flag       = cv_yes                                      -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          --���������s�T�C�N�����݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_prt_cycle                          -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.prt_cycle               -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
-- Ver1.4 SCSK S.Niki add start
      --==============================================================
      -- A-4.38-2 ���������s�T�C�N���`�F�b�N
      --==============================================================
      lv_step := 'A-4.38-2';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        IF (i_wk_cust_rec.output_form = cv_output_form_4)
          AND (i_wk_cust_rec.prt_cycle <> cv_prt_cycle_1) THEN
          lv_check_status := cv_status_error;
          lv_check_flag   := cv_status_error;
          ov_retcode      := cv_status_error;
          --���������s�T�C�N���`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10356                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value1 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
        END IF;
      END IF;
-- Ver1.4 SCSK S.Niki add end
      --==============================================================
      -- A-4.39 �x�������`�F�b�N
      --==============================================================
      lv_step := 'A-4.39';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- �x�������`�F�b�N
        BEGIN
          SELECT rt.term_id
          INTO   gt_payment_term_id
          FROM   ra_terms rt                                             -- �x������
          WHERE  rt.name = i_wk_cust_rec.payment_term                    -- �x������
          AND    NVL( rt.start_date_active, gd_process_date ) <= gd_process_date     -- �K�p�J�n��
          AND    NVL( rt.end_date_active,   gd_process_date ) >= gd_process_date;    -- �K�p�I����
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_check_status   := cv_status_error;
            ov_retcode        := cv_status_error;
            --�x�������`�F�b�N�G���[
            gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_10346                    -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                          ,iv_token_value1 => cv_payment_term_id                    -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_cust_rec.payment_term            -- �g�[�N���l2
                          ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                          ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
            lv_check_flag := cv_status_error;
        END;
      END IF;
      --==============================================================
      -- A-4.40 �[�i���_�`�F�b�N
      --==============================================================
      lv_step := 'A-4.40';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- �[�i���_�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- �l�Z�b�g��`�}�X�^
              ,fnd_flex_values     ffv                                            -- �l�Z�b�g�}�X�^
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- �l�Z�b�gID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF����(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- �q�l
        AND    ffv.flex_value           = i_wk_cust_rec.delivery_base_code        -- �[�i���_
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- �J�n��
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- �I����
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �[�i���_�`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10329                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_delivery_base_code                 -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.delivery_base_code      -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.41 �������_�`�F�b�N
      --==============================================================
      lv_step := 'A-4.41';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- �������_�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- �l�Z�b�g��`�}�X�^
              ,fnd_flex_values     ffv                                            -- �l�Z�b�g�}�X�^
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- �l�Z�b�gID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF����(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- �q�l
        AND    ffv.flex_value           = i_wk_cust_rec.bill_base_code            -- �������_
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- �J�n��
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- �I����
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �������_�`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10329                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_bill_base_code                     -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.bill_base_code          -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.42 �������_�`�F�b�N
      --==============================================================
      lv_step := 'A-4.42';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      IF ( gv_format = cv_file_format_ur ) THEN
        -- �������_�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- �l�Z�b�g��`�}�X�^
              ,fnd_flex_values     ffv                                            -- �l�Z�b�g�}�X�^
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- �l�Z�b�gID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF����(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- �q�l
        AND    ffv.flex_value           = i_wk_cust_rec.receiv_base_code          -- �������_
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- �J�n��
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- �I����
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �������_�`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10329                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_receiv_base_code                   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.receiv_base_code        -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-4.43 �̔���{���S�����_�`�F�b�N
      --==============================================================
      lv_step := 'A-4.43';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
-- Ver1.3 K.Nakamura mod start
--      IF ( gv_format = cv_file_format_ur ) THEN
      IF ( gv_format = cv_file_format_ur )
        AND ( i_wk_cust_rec.sales_head_base_code IS NOT NULL ) THEN
-- Ver1.3 K.Nakamura mod end
        -- �̔���{���S�����_�`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_flex_value_sets ffvs                                           -- �l�Z�b�g��`�}�X�^
              ,fnd_flex_values     ffv                                            -- �l�Z�b�g�}�X�^
        WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id                   -- �l�Z�b�gID
        AND    ffvs.flex_value_set_name = cv_aff_dept                             -- AFF����(XX03_DEPARTMENT)
        AND    ffv.summary_flag         = cv_no                                   -- �q�l
        AND    ffv.flex_value           = i_wk_cust_rec.sales_head_base_code      -- �̔���{���S�����_
        AND    NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date   -- �J�n��
        AND    NVL( ffv.end_date_active,   gd_process_date ) >= gd_process_date   -- �I����
        ;
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode      := cv_status_error;
          -- �̔���{���S�����_�`�F�b�N�G���[���b�Z�[�W�擾
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10329                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_sales_head_base_cd                   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.sales_head_base_code    -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
-- Ver1.3 K.Nakamura add start
      --==============================================================
      -- A-4.44 �J�[�h��Ћ敪�`�F�b�N
      --==============================================================
      lv_step := 'A-4.44';
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_ur )
        AND ( i_wk_cust_rec.card_company_kbn IS NOT NULL ) THEN
        -- �J�[�h��Ћ敪���݃`�F�b�N
        SELECT COUNT(1)
        INTO   ln_cnt
        FROM   fnd_lookup_values_vl flv                                           -- LOOKUP�\
        WHERE  flv.lookup_type  = cv_lookup_card_bkn                              -- �^�C�v
        AND    flv.lookup_code  = i_wk_cust_rec.card_company_kbn                  -- �R�[�h
        AND    flv.enabled_flag = cv_yes                                          -- �g�p�\�t���O
        AND    NVL( flv.start_date_active, gd_process_date ) <= gd_process_date   -- �K�p�J�n��
        AND    NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date   -- �K�p�I����
        ;
        --
        IF (ln_cnt = 0) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �J�[�h��Ћ敪���݃`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                    -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10330                    -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input                          -- �g�[�N���R�[�h1
                        ,iv_token_value1 => cv_card_company_kbn                   -- �g�[�N���l1
                        ,iv_token_name2  => cv_tkn_value                          -- �g�[�N���R�[�h2
                        ,iv_token_value2 => i_wk_cust_rec.card_company_kbn        -- �g�[�N���l2
                        ,iv_token_name3  => cv_tkn_input_line_no                  -- �g�[�N���R�[�h3
                        ,iv_token_value3 => i_wk_cust_rec.line_no                 -- �g�[�N���l3
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
-- Ver1.3 K.Nakamura add end
-- Ver1.5 add start
      --==============================================================
      -- A-4.45 ���E�p�ڋq�R�[�h�`�F�b�N
      --==============================================================
      lv_step := 'A-4.45';
      -- �t�H�[�}�b�g�p�^�[���u501:MC�v���A�l�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( i_wk_cust_rec.offset_cust_code IS NOT NULL ) THEN
        BEGIN
          -- ���E�p�ڋq�R�[�h���݃`�F�b�N
          SELECT hca.account_number  AS offset_cust_code
          INTO   lt_offset_cust_code
          FROM   xxcmm_cust_accounts xca
                ,hz_cust_accounts    hca
          WHERE  xca.customer_id          = hca.cust_account_id
          AND    hca.customer_class_code  = cv_cust_kbn
          AND    xca.offset_cust_div      = cv_offset_cust_div_1
          AND    hca.account_number       = i_wk_cust_rec.offset_cust_code
          ;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_check_status := cv_status_error;
            lv_check_flag   := cv_status_error;
            ov_retcode      := cv_status_error;
            -- ���E�p�ڋq�R�[�h���݃`�F�b�N�G���[
            gv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm               -- �A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_msg_xxcmm_10359               -- ���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_value                     -- �g�[�N���R�[�h1
                          ,iv_token_value1 => i_wk_cust_rec.offset_cust_code   -- �g�[�N���l1
                          ,iv_token_name2  => cv_tkn_input_line_no             -- �g�[�N���R�[�h2
                          ,iv_token_value2 => i_wk_cust_rec.line_no            -- �g�[�N���l2
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => gv_out_msg);
            --
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg);
        END;
      END IF;
--
      --==============================================================
      -- A-4.46 �����ڋq�R�[�h�d���`�F�b�N
      --==============================================================
      lv_step := 'A-4.46';
      -- �t�H�[�}�b�g�p�^�[���u501:MC�v���A
      -- ���E�p�ڋq�R�[�h�A�����ڋq�R�[�h�ɒl�������Ă���ꍇ
      IF ( gv_format = cv_file_format_mc )
        AND ( lt_offset_cust_code IS NOT NULL )
        AND ( i_wk_cust_rec.bp_customer_code IS NOT NULL ) THEN
        -- �����ڋq�R�[�h�d���`�F�b�N
        SELECT COUNT(1) AS chk_cnt
        INTO   ln_cnt
        FROM   xxcmm_cust_accounts xca
              ,hz_cust_accounts    hca
        WHERE  xca.customer_id         =  hca.cust_account_id
        AND    xca.offset_cust_code    =  lt_offset_cust_code
        AND    xca.bp_customer_code    =  i_wk_cust_rec.bp_customer_code
        AND    ROWNUM                  =  1
        ;
        --
        IF ( ln_cnt <> 0 ) THEN
          lv_check_status   := cv_status_error;
          ov_retcode        := cv_status_error;
          -- �����ڋq�R�[�h�d���`�F�b�N�G���[
          gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm               -- �A�v���P�[�V�����Z�k��
                        ,iv_name         => cv_msg_xxcmm_10360               -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1  => cv_tkn_input_line_no             -- �g�[�N���R�[�h1
                        ,iv_token_value1 => i_wk_cust_rec.line_no            -- �g�[�N���l1
                       );
          -- ���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg);
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => gv_out_msg);
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
-- Ver1.5 add end
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    END IF;
  --
  -- �`�F�b�N�������ʂ��Z�b�g
  IF ( lv_check_flag = cv_status_normal )THEN
    ov_retcode := cv_status_normal;
  ELSIF ( lv_check_flag = cv_status_error ) THEN
    ov_retcode := cv_status_error;
  END IF;
  --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_cust_wk;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : �ڋq�o�^���ʂ����O�o�͗p�e�[�u���Ɋi�[���܂��B
   ***********************************************************************************/
  PROCEDURE add_report(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN  save_cust_key_info_rtype      -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���|�[�g���R�[�h�ɒl��ݒ�
    lr_report_rec.line_no                  := i_wk_cust_rec.line_no;                        -- �s�ԍ�
    lr_report_rec.account_number           := io_save_cust_key_info_rec.lv_account_number;  -- �ڋq�R�[�h
    lr_report_rec.customer_status          := i_wk_cust_rec.customer_status;                -- �ڋq�X�e�[�^�X
    lr_report_rec.resource_no              := i_wk_cust_rec.resource_no;                    -- �S���c�ƈ�
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify start by Shigeto.Niki
--    lr_report_rec.resource_s_date          := i_wk_cust_rec.resource_s_date;                -- �K�p�J�n��
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod start
--    lr_report_rec.resource_s_date          := gd_process_date;                              -- �Ɩ����t
    lr_report_rec.resource_s_date          := TO_CHAR( gd_process_date, cv_date_fmt_std );  -- �Ɩ����t
-- 2012/11/13 Ver1.2 SCSK K.Furuyama mod end
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify end by Shigeto.Niki
    lr_report_rec.customer_name            := i_wk_cust_rec.customer_name;                  -- �ڋq��
    --
    -- ���|�[�g�e�[�u���ɒǉ�
    gt_report_tbl(gn_normal_cnt+1)         := lr_report_rec;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂�
   ***********************************************************************************/
  PROCEDURE disp_report(
    ov_errbuf      OUT VARCHAR2    --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT VARCHAR2    --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT VARCHAR2)   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    cv_normal     CONSTANT VARCHAR2(20) := '<<���R�[�h���e>>';  -- ���o��
    lv_sep_com    CONSTANT VARCHAR2(1)  := ',';     -- �J���}
    --
    -- *** ���[�J���ϐ� ***
    lv_dspbuf     VARCHAR2(5000);    -- �G���[�E���b�Z�[�W
    --
    -- *** ���[�J���E�J�[�\�� ***
    --
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --
    -- �������ʌ��o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxcmm                   -- �A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_xxcmm_10341                   -- ���b�Z�[�W�R�[�h
                );
    --
    -- ���o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff => cv_normal --���o���P
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg --���o���Q
    );
    -- ���o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff => cv_normal --���o���P
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff => gv_out_msg --���o���Q
    );
    --
    <<report_loop>>
    FOR ln_disp_cnt IN 1..gn_normal_cnt LOOP
      lv_dspbuf := gt_report_tbl(ln_disp_cnt).line_no||lv_sep_com||            -- �s�ԍ�
                   gt_report_tbl(ln_disp_cnt).account_number||lv_sep_com||     -- �ڋq�R�[�h
                   gt_report_tbl(ln_disp_cnt).customer_status||lv_sep_com||    -- �ڋq�X�e�[�^�X
                   gt_report_tbl(ln_disp_cnt).resource_no||lv_sep_com||        -- �S���c�ƈ�
                   gt_report_tbl(ln_disp_cnt).resource_s_date||lv_sep_com||    -- �K�p�J�n��
                   gt_report_tbl(ln_disp_cnt).customer_name                    -- �ڋq��
                   ;
      -- �o�^���ʏo��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff => lv_dspbuf --����f�[�^���O
      );
      --
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => lv_dspbuf --����f�[�^���O
      );
    END LOOP report_loop;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_acct_api
   * Description      : �ڋq�}�X�^�o�^����
   ***********************************************************************************/
  PROCEDURE ins_cust_acct_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  OUT save_cust_key_info_rtype      -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cust_acct_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_party_number             VARCHAR2(200);
    ln_profile_id               NUMBER;
    lv_sql_errm                 VARCHAR2(2000); -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_p_create_profile_amt     VARCHAR2(200) := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    -- �ޔ�p
    ln_cust_account_id          NUMBER;                                                  -- �ޔ�_�ڋqID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_party_id                 hz_parties.party_id%TYPE;                                -- �ޔ�_�p�[�e�BID
--
    -- *** ���[�J���E�J�[�\�� ***
    -- hz_cust_account_v2pub.create_cust_account API
    l_cust_account_rec          hz_cust_account_v2pub.cust_account_rec_type;
    l_organization_rec          hz_party_v2pub.organization_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_party_rec                 hz_party_v2pub.party_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    lv_create_profile           VARCHAR2(1) := fnd_api.g_false;
    lv_create_profile_amt       VARCHAR2(1) := fnd_api.g_false;
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-1 �ڋq�}�X�^�o�^�p���R�[�h�쐬
    --==============================================================
    lv_step := 'A-5.1-1';
    -- �p�����[�^������
    l_cust_account_rec      := NULL;
    l_organization_rec      := NULL;
    l_customer_profile_rec  := NULL;
--
    -- �ڋq�}�X�^�o�^�p���R�[�h
    l_cust_account_rec.cust_account_id                := NULL;                                               -- �ڋq�A�J�E���gID
    l_cust_account_rec.account_number                 := NULL;                                               -- �ڋq�A�J�E���g�ԍ�
    l_cust_account_rec.account_name                   := i_wk_cust_rec.customer_name_ryaku;                  -- �A�J�E���g��
    l_cust_account_rec.customer_class_code            := i_wk_cust_rec.customer_class_code;                  -- �ڋq�敪
    l_cust_account_rec.customer_type                  := cv_r;                                               -- �ڋq�^�C�v('R':�O��)
    l_cust_account_rec.dormant_account_flag           := cv_no;                                              -- �x�~�t���O('N':No)
    l_cust_account_rec.arrivalsets_include_lines_flag := cv_no;                                              -- �����Z�b�g('N':No)
    l_cust_account_rec.sched_date_push_flag           := cv_no;                                              -- �v�b�V���E�O���[�v�\���('N':No)
    l_cust_account_rec.status                         := cv_a;                                               -- �X�e�[�^�X('A':�L��)
    l_cust_account_rec.created_by_module              := cv_pkg_name;                                        -- �v���O����ID
    -- �g�D���R�[�h�o�^�p���R�[�h
    l_organization_rec.organization_name              := i_wk_cust_rec.customer_name;                        -- �ڋq��
    l_organization_rec.duns_number_c                  := i_wk_cust_rec.customer_status;                      -- �ڋq�X�e�[�^�X
    l_organization_rec.organization_name_phonetic     := i_wk_cust_rec.customer_name_kana;                   -- �ڋq���J�i
    l_organization_rec.gsa_indicator_flag             := cv_no;                                              -- GSA�C���f�B�P�[�^('N':No)
    -- �p�[�e�B���R�[�h�o�^�p���R�[�h
    l_organization_rec.party_rec.validated_flag       := cv_no;                                              -- ���؍ς݃t���O('N':No)
    l_organization_rec.party_rec.attribute1           := i_wk_cust_rec.manager_name;                         -- �X����
    l_organization_rec.party_rec.attribute2           := i_wk_cust_rec.emp_number;                           -- �Ј���
    l_organization_rec.party_rec.attribute3           := i_wk_cust_rec.rest_emp_name;                        -- �S���ҋx��
    l_organization_rec.party_rec.attribute4           := i_wk_cust_rec.mc_hot_deg;                           -- MC�FHOT�x
    l_organization_rec.party_rec.attribute5           := i_wk_cust_rec.mc_importance_deg;                    -- MC�F�d�v�x
    l_organization_rec.party_rec.attribute6           := i_wk_cust_rec.mc_conf_info;                         -- MC�F�������
    l_organization_rec.party_rec.attribute7           := i_wk_cust_rec.mc_business_talk_details;             -- MC�F���k�o��
    l_organization_rec.party_rec.attribute8           := i_wk_cust_rec.business_low_type_tmp;                -- �Ƒԏ�����(��)

--
    --==============================================================
    -- A-5.1-2 �ڋq�}�X�^�o�^
    --==============================================================
    lv_step := 'A-5.1-2';
    -- �ڋq�}�X�^�쐬�̕W��API���R�[��
    hz_cust_account_v2pub.create_cust_account(
      p_init_msg_list         => lv_init_msg_list            -- �������b�Z�[�W���X�g
     ,p_cust_account_rec      => l_cust_account_rec          -- �ڋq�}�X�^�o�^�p���R�[�h
     ,p_organization_rec      => l_organization_rec          -- �g�D���R�[�h�o�^�p���R�[�h
     ,p_customer_profile_rec  => l_customer_profile_rec      -- �g�D�v���t�@�C���o�^�p���R�[�h
     ,p_create_profile_amt    => lv_p_create_profile_amt     -- 
     ,x_cust_account_id       => ln_cust_account_id          -- �ڋqID
     ,x_account_number        => lv_account_number           -- �ڋq�R�[�h
     ,x_party_id              => ln_party_id                 -- �p�[�e�BID
     ,x_party_number          => lv_party_number             -- �p�[�e�B�ԍ�
     ,x_profile_id            => ln_profile_id               -- �v���t�@�C��ID
     ,x_return_status         => lv_return_status            -- ���^�[���R�[�h
     ,x_msg_count             => ln_msg_count                -- ���^�[�����b�Z�[�W
     ,x_msg_data              => lv_msg_data                 -- ���^�[���f�[�^
    );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- �G���[���b�Z�[�W�擾
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_cust_acct;                -- �e�[�u����
      lv_api_nm        := cv_api_cust_acct;                  -- API��
      lv_sql_errm      := lv_msg_data;                       -- API�G���[���b�Z�[�W
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
--
    -- �ڋq�}�X�^�쐬���ʂ�KEY����ϐ��ɑޔ����܂��B
    io_save_cust_key_info_rec.ln_cust_account_id := ln_cust_account_id;  -- �ޔ�_�ڋq�A�J�E���gID
    io_save_cust_key_info_rec.lv_account_number  := lv_account_number;   -- �ޔ�_�ڋq�R�[�h
    io_save_cust_key_info_rec.ln_party_id        := ln_party_id;         -- �ޔ�_�p�[�e�BID
    --
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_sql_errm                   -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_cust_acct_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_location_api
   * Description      : �ڋq���ݒn�o�^����
   ***********************************************************************************/
  PROCEDURE ins_location_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_location_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    -- �ޔ�p
    ln_cust_account_id          NUMBER;                                                  -- �ޔ�_�ڋqID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_party_id                 hz_parties.party_id%TYPE;                                -- �ޔ�_�p�[�e�BID
    ln_location_id              hz_locations.location_id%TYPE;                           -- �ޔ�_���Ə�ID
--
    -- *** ���[�J���E�J�[�\�� ***
    -- hz_location_v2pub.create_cust_account
    l_location_rec              hz_location_v2pub.location_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-3 �ڋq���ݒn�}�X�^�o�^�p���R�[�h�쐬
    --==============================================================
    lv_step := 'A-5.1-3';
--
    -- �p�����[�^������
    ln_location_id       := NULL;   -- �ޔ�_���Ə�ID
    l_location_rec       := NULL;   -- ���ݒn���R�[�h
--
    l_location_rec       := NULL;
    -- ���b�Z�[�W�p
    lv_account_number                                 := io_save_cust_key_info_rec.lv_account_number;        -- �ڋq�R�[�h
    -- �ڋq���ݒn�}�X�^�o�^�p���R�[�h
    l_location_rec.location_id                        := NULL;                                               -- ���P�[�V����ID
    l_location_rec.country                            := cv_jp;                                              -- ��('JP'�F���{)
    l_location_rec.postal_code                        := RPAD(i_wk_cust_rec.postal_code,7,'0');              -- �X�֔ԍ�
    l_location_rec.state                              := i_wk_cust_rec.state;                                -- �s���{��
    l_location_rec.city                               := i_wk_cust_rec.city;                                 -- �s�E��
    l_location_rec.address1                           := i_wk_cust_rec.address1;                             -- �Z���P
    --
    IF ( i_wk_cust_rec.address2 IS NOT NULL ) THEN
      l_location_rec.address2                         := i_wk_cust_rec.address2;                             -- �Z���Q
    ELSE
      l_location_rec.address2                         := fnd_api.g_miss_char;
    END IF;
    --
    l_location_rec.address3                           := i_wk_cust_rec.address3;                             -- �n��R�[�h
    l_location_rec.address_lines_phonetic             := i_wk_cust_rec.tel_no;                               -- �d�b�ԍ�
    l_location_rec.address4                           := i_wk_cust_rec.fax;                                  -- FAX
    l_location_rec.validated_flag                     := cv_no;                                              -- ���؍ς݃t���O('N':No)
    l_location_rec.sales_tax_inside_city_limits       := cv_1;                                               -- ����œs�s�������
    l_location_rec.created_by_module                  := cv_pkg_name;                                        -- �v���O����ID
--
    --==============================================================
    -- A-5.1-4 �ڋq���ݒn�}�X�^�o�^
    --==============================================================
    lv_step := 'A-5.1-4';
    -- �ڋq���ݒn�}�X�^�쐬�̕W��API���R�[��
    hz_location_v2pub.create_location(
      p_init_msg_list         => lv_init_msg_list            -- �������b�Z�[�W���X�g
     ,p_location_rec          => l_location_rec              -- �ڋq���ݒn�}�X�^�o�^�p���R�[�h
     ,x_location_id           => ln_location_id              -- ���Ə�ID
     ,x_return_status         => lv_return_status            -- ���^�[���R�[�h
     ,x_msg_count             => ln_msg_count                -- ���^�[�����b�Z�[�W
     ,x_msg_data              => lv_msg_data                 -- ���^�[���f�[�^
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- �G���[���b�Z�[�W�擾
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_location;                 -- �e�[�u����
      lv_api_nm        := cv_api_location;                   -- API��
      lv_sql_errm      := lv_msg_data;                       -- API�G���[���b�Z�[�W
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
--
    -- �ڋq�}�X�^�쐬���ʂ�KEY����ϐ��ɑޔ����܂��B
    io_save_cust_key_info_rec.ln_location_id := ln_location_id; -- �ޔ�_���Ə�ID
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- �W��API�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_sql_errm                   -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_location_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_party_site_api
   * Description      : �p�[�e�B�T�C�g�}�X�^�o�^����
   ***********************************************************************************/
  PROCEDURE ins_party_site_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_party_site_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    -- �ޔ�p
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_location_id              hz_locations.location_id%TYPE;                           -- �ޔ�_���Ə�ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- �ޔ�_�p�[�e�B�T�C�gID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- �ޔ�_�p�[�e�B�T�C�g�ԍ�
--
    -- *** ���[�J���E�J�[�\�� ***
    -- hz_party_site_v2pub.create_party_site
    l_party_site_rec            hz_party_site_v2pub.party_site_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-5 �p�[�e�B�T�C�g�}�X�^�o�^���R�[�h�쐬
    --==============================================================
    lv_step := 'A-5.1-5';
--
    -- ���b�Z�[�W�p
    lv_account_number                                 := io_save_cust_key_info_rec.lv_account_number;       -- �ڋq�R�[�h
    -- �p�[�e�B�T�C�g�}�X�^�o�^�p���R�[�h
    l_party_site_rec.party_site_id                    := NULL;                                              -- �p�[�e�B�T�C�gID
    l_party_site_rec.party_id                         := io_save_cust_key_info_rec.ln_party_id;             -- �ޔ�_�p�[�e�BID
    l_party_site_rec.location_id                      := io_save_cust_key_info_rec.ln_location_id;          -- �ޔ�_���Ə�ID
    l_party_site_rec.status                           := cv_a;                                              -- �o�^�X�e�[�^�X
    l_party_site_rec.identifying_address_flag         := cv_y;                                              -- 
    l_party_site_rec.party_site_number                := NULL;                                              -- �p�[�e�B�T�C�g�ԍ�
    l_party_site_rec.created_by_module                := cv_pkg_name;                                       -- �v���O����ID
--
    --==============================================================
    -- A-5.1-6 �p�[�e�B�T�C�g�}�X�^�o�^
    --==============================================================
    lv_step := 'A-5.1-6';
    -- �p�[�e�B�T�C�g�}�X�^�쐬�̕W��API���R�[��
    hz_party_site_v2pub.create_party_site (
      p_init_msg_list         => lv_init_msg_list                -- �������b�Z�[�W���X�g
     ,p_party_site_rec        => l_party_site_rec                -- �p�[�e�B�T�C�g�}�X�^�o�^�p���R�[�h
     ,x_party_site_id         => ln_party_site_id                -- �p�[�e�B�T�C�gID
     ,x_party_site_number     => lv_party_site_number            -- �p�[�e�B�T�C�g�ԍ�
     ,x_return_status         => lv_return_status                -- ���^�[���R�[�h
     ,x_msg_count             => ln_msg_count                    -- ���^�[�����b�Z�[�W
     ,x_msg_data              => lv_msg_data                     -- ���^�[���f�[�^
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- �G���[���b�Z�[�W�擾
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_party_site;               -- �e�[�u����
      lv_api_nm        := cv_api_party_site;                 -- API��
      lv_sql_errm      := lv_msg_data;                       -- API�G���[���b�Z�[�W
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
--
    -- �p�[�e�B�T�C�g�쐬���ʂ�KEY����ϐ��ɑޔ����܂��B
    io_save_cust_key_info_rec.ln_party_site_id     := ln_party_site_id;     -- �ޔ�_�p�[�e�B�T�C�gID
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- �W��API�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_sql_errm                   -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_party_site_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_cust_acct_site_api
   * Description      : �ڋq�T�C�g�}�X�^�o�^����
   ***********************************************************************************/
  PROCEDURE ins_cust_acct_site_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cust_acct_site_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    -- �ޔ�p
    ln_cust_account_id          NUMBER;                                                  -- �ޔ�_�ڋqID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- �ޔ�_�p�[�e�B�T�C�gID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- �ޔ�_�p�[�e�B�T�C�g�ԍ�
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- �ޔ�_�ڋq�T�C�gID
--
    -- *** ���[�J���E�J�[�\�� ***
    -- hz_cust_account_site_v2pub.create_cust_site_use
    l_rec_cust_site_rec         hz_cust_account_site_v2pub.cust_acct_site_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-7 �ڋq�T�C�g�}�X�^�o�^���R�[�h�쐬
    --==============================================================
    lv_step := 'A-5.1-7';
--
    -- ���b�Z�[�W�p
    lv_account_number                                 := io_save_cust_key_info_rec.lv_account_number;       -- �ڋq�R�[�h
    -- �ڋq�T�C�g�}�X�^�o�^�p���R�[�h
    l_rec_cust_site_rec.cust_acct_site_id             := NULL;                                              -- �ڋq�T�C�gID
    l_rec_cust_site_rec.cust_account_id               := io_save_cust_key_info_rec.ln_cust_account_id;      -- �ޔ�_�ڋq�A�J�E���gID
    l_rec_cust_site_rec.party_site_id                 := io_save_cust_key_info_rec.ln_party_site_id;        -- �ޔ�_�p�[�e�B�T�C�gID
    l_rec_cust_site_rec.attribute_category            := gv_sal_org_id;                                     -- �A�g���r���[�g�J�e�S��(�c��OU)
    l_rec_cust_site_rec.status                        := cv_a;                                              -- �o�^�X�e�[�^�X
    l_rec_cust_site_rec.key_account_flag              := cv_no;                                             -- 
    l_rec_cust_site_rec.created_by_module             := cv_pkg_name;                                       -- �v���O����ID
--
    --==============================================================
    -- A-5.1-8 �ڋq�T�C�g�}�X�^�o�^
    --==============================================================
    lv_step := 'A-5.1-8';
    -- �ڋq�T�C�g�}�X�^�쐬�̕W��API���R�[��
    hz_cust_account_site_v2pub.create_cust_acct_site (
      p_init_msg_list         => lv_init_msg_list
     ,p_cust_acct_site_rec    => l_rec_cust_site_rec
     ,x_cust_acct_site_id     => ln_cust_acct_site_id
     ,x_return_status         => lv_return_status
     ,x_msg_count             => ln_msg_count
     ,x_msg_data              => lv_msg_data
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- �G���[���b�Z�[�W�擾
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_acct_site;                -- �e�[�u����
      lv_api_nm        := cv_api_acct_site;                  -- API��
      lv_sql_errm      := lv_msg_data;                       -- API�G���[���b�Z�[�W
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
--
    -- �ڋq�T�C�g�쐬���ʂ�KEY����ϐ��ɑޔ����܂��B
    io_save_cust_key_info_rec.ln_cust_acct_site_id := ln_cust_acct_site_id; -- �ڋq�T�C�gID
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- �W��API�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_sql_errm                   -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_cust_acct_site_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_bill_to_api
   * Description      : �ڋq�g�p�ړI�}�X�^(������)�o�^����
   ***********************************************************************************/
  PROCEDURE ins_bill_to_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bill_to_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_create_profile           VARCHAR2(1)   := fnd_api.g_true;
    lv_create_profile_amt       VARCHAR2(1)   := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    ln_cust_account_id          NUMBER;                                                  -- �ޔ�_�ڋqID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_party_id                 hz_parties.party_id%TYPE;                                -- �ޔ�_�p�[�e�BID
    ln_location_id              hz_locations.location_id%TYPE;                           -- �ޔ�_���Ə�ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- �ޔ�_�p�[�e�B�T�C�gID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- �ޔ�_�p�[�e�B�T�C�g�ԍ�
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- �ޔ�_�ڋq�T�C�gID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_������_�g�p�ړIID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_������_�g�p�ړI
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- �ޔ�_�ڋq�v���t�@�C��ID
--
    -- *** ���[�J���E�J�[�\�� ***
    -- hz_cust_account_v2pub.create_cust_account API
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-9 �ڋq�g�p�ړI�}�X�^(������)�o�^���R�[�h�쐬
    --==============================================================
    lv_step := 'A-5.1-9';
    --
    -- ���R�[�h�N���A
    l_cust_site_use_rec     := NULL; -- ���Ə����R�[�h
    l_customer_profile_rec  := NULL; -- �ڋq�v���t�@�C�����R�[�h
    --
    -- ���b�Z�[�W�p
    lv_account_number                                   := io_save_cust_key_info_rec.lv_account_number;        -- �ڋq�R�[�h
    -- �ڋq�g�p�ړI�}�X�^(������)�o�^�p���R�[�h
    l_cust_site_use_rec.site_use_id                     := NULL;                                               -- ���Ə�ID
    l_cust_site_use_rec.cust_acct_site_id               := io_save_cust_key_info_rec.ln_cust_acct_site_id;     -- �ޔ�_�ڋq�T�C�gID
    l_cust_site_use_rec.status                          := cv_a;                                               -- �o�^�X�e�[�^�X
    l_cust_site_use_rec.price_list_id                   := NULL;                                               -- ���i�\ID
    l_cust_site_use_rec.attribute_category              := gv_sal_org_id;                                      -- �A�g���r���[�g�J�e�S��
    l_cust_site_use_rec.primary_flag                    := cv_yes;                                             -- primary_flag
    l_cust_site_use_rec.gsa_indicator                   := cv_no;                                              -- GSA�C���f�B�P�[�^('N'�FNo)
-- 2012/12/14 Ver1.2 SCSK K.Furuyama del start
    --l_cust_site_use_rec.site_use_code                   := cv_site_use_bill_to;                                -- �g�p�ړI('BILL_TO'�F������)
    --l_cust_site_use_rec.attribute7                      := gv_output_form;                                     -- �������o�͌`��
    --l_cust_site_use_rec.attribute8                      := gv_prt_cycle;                                       -- ���������s�T�C�N��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama del end
    l_cust_site_use_rec.ship_sets_include_lines_flag    := cv_no;                                              -- ship_sets_include_lines_flag
    l_cust_site_use_rec.arrivalsets_include_lines_flag  := cv_no;                                              -- arrivalsets_include_lines_flag
    l_cust_site_use_rec.sched_date_push_flag            := cv_no;                                              -- sched_date_push_flag
    l_cust_site_use_rec.created_by_module               := cv_pkg_name;                                        -- �v���O����ID
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
    IF ( gv_format = cv_file_format_mc ) THEN
      l_cust_site_use_rec.site_use_code                 := cv_site_use_bill_to;                                -- �g�p�ړI('BILL_TO'�F������)
      l_cust_site_use_rec.attribute7                    := gv_output_form;                                     -- �������o�͌`��
      l_cust_site_use_rec.attribute8                    := gv_prt_cycle;                                       -- ���������s�T�C�N��
    -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
    ELSIF ( gv_format = cv_file_format_ur ) THEN
      l_cust_site_use_rec.site_use_code                 := cv_site_use_bill_to;                                -- �g�p�ړI('BILL_TO'�F������)
      l_cust_site_use_rec.attribute7                    := i_wk_cust_rec.output_form;                          -- �������o�͌`��
      l_cust_site_use_rec.attribute8                    := i_wk_cust_rec.prt_cycle;                            -- ���������s�T�C�N��
      l_cust_site_use_rec.tax_rounding_rule             := i_wk_cust_rec.tax_rounding_rule;                    -- �ŋ��[������
      l_cust_site_use_rec.attribute4                    := i_wk_cust_rec.invoice_grp_code;                     -- ���|�R�[�h1�i�������j
      l_cust_site_use_rec.payment_term_id               := gt_payment_term_id;                                 -- �x������
      l_cust_site_use_rec.gl_id_rec                     := gt_urikake_misyuukin_id;                            -- ���|��/������
      -- �ڋq�v���t�@�C�����R�[�h
      l_customer_profile_rec.autocash_hierarchy_id      := gt_autocash_hierarchy_id;                           -- ����������Z�b�g
      l_customer_profile_rec.cons_inv_flag              := cv_y;                                               -- �ꊇ���������s(Y:�g�p�\)
      l_customer_profile_rec.cons_inv_type              := cv_summary;                                         -- �ꊇ���������s�^�C�v(SUMMARY:�v��)
    END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
    -- �ڋq�v���t�@�C�����R�[�h
    l_customer_profile_rec.cust_account_profile_id      := NULL;                                               -- �ڋq�v���t�@�C��ID
    l_customer_profile_rec.cust_account_id              := io_save_cust_key_info_rec.ln_cust_account_id;       -- �ޔ�_�ڋq�A�J�E���gID
    --
    --==============================================================
    -- A-5.1-10 �ڋq�g�p�ړI�}�X�^(������)�o�^
    --==============================================================
    lv_step := 'A-5.1-10';
    -- ���Ə��i������j�쐬�̕W��API���R�[��
    hz_cust_account_site_v2pub.create_cust_site_use(
      p_init_msg_list        => lv_init_msg_list               -- �������b�Z�[�W���X�g
     ,p_cust_site_use_rec    => l_cust_site_use_rec            -- �ڋq�g�p�ړI�}�X�^(������)���R�[�h�ϐ�
     ,p_customer_profile_rec => l_customer_profile_rec         -- �ڋq�v���t�@�C�����R�[�h�ϐ�
     ,p_create_profile       => lv_create_profile
     ,p_create_profile_amt   => lv_create_profile_amt
     ,x_site_use_id          => ln_bill_to_site_use_id         -- ������_�g�p�ړIID
     ,x_return_status        => lv_return_status               -- ���^�[���R�[�h
     ,x_msg_count            => ln_msg_count                   -- ���^�[�����b�Z�[�W
     ,x_msg_data             => lv_msg_data                    -- ���^�[���f�[�^
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN
      -- �G���[���b�Z�[�W�擾
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_bill_to;                -- �e�[�u����
      lv_api_nm        := cv_api_cust_site_use;            -- API��
      lv_sql_errm      := lv_msg_data;                     -- API�G���[���b�Z�[�W
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
    --
    -- �ڋq�g�p�ړI�}�X�^(������)�쐬���ʂ�KEY����ϐ��ɑޔ����܂��B
    io_save_cust_key_info_rec.ln_bill_to_site_use_id   := ln_bill_to_site_use_id;             -- �ޔ�_������_�g�p�ړIID
    io_save_cust_key_info_rec.lv_bill_to_site_use_code := l_cust_site_use_rec.site_use_code;  -- �ޔ�_������_�g�p�ړI
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- �W��API�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_sql_errm                   -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_bill_to_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_ship_to_api
   * Description      : �ڋq�g�p�ړI�}�X�^(�o�א�)�o�^����
   ***********************************************************************************/
  PROCEDURE ins_ship_to_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ship_to_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_create_profile           VARCHAR2(1)   := fnd_api.g_false;
    lv_create_profile_amt       VARCHAR2(1)   := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    ln_cust_account_id          NUMBER;                                                  -- �ޔ�_�ڋqID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_party_id                 hz_parties.party_id%TYPE;                                -- �ޔ�_�p�[�e�BID
    ln_location_id              hz_locations.location_id%TYPE;                           -- �ޔ�_���Ə�ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- �ޔ�_�p�[�e�B�T�C�gID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- �ޔ�_�p�[�e�B�T�C�g�ԍ�
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- �ޔ�_�ڋq�T�C�gID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_������_�g�p�ړIID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_������_�g�p�ړI
    ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_�o�א�_�g�p�ړIID
    lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_�o�א�_�g�p�ړI
    ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_���̑�_�g�p�ړIID
    lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_���̑�_�g�p�ړI
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- �ޔ�_�ڋq�v���t�@�C��ID
--
    -- *** ���[�J���E�J�[�\�� ***
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-11 �ڋq�g�p�ړI�}�X�^(�o�א�)�o�^���R�[�h�쐬
    --==============================================================
    lv_step := 'A-5.1-11';
    --
    -- ���R�[�h�N���A
    l_cust_site_use_rec     := NULL; -- ���Ə����R�[�h
    --
    -- ���b�Z�[�W�p
    lv_account_number                                   := io_save_cust_key_info_rec.lv_account_number;        -- �ڋq�R�[�h
    -- �ڋq�g�p�ړI�}�X�^(�o�א�)�o�^�p���R�[�h
    l_cust_site_use_rec.site_use_id                     := NULL;                                               -- ���Ə�ID
    l_cust_site_use_rec.cust_acct_site_id               := io_save_cust_key_info_rec.ln_cust_acct_site_id;     -- �ޔ�_�ڋq�T�C�gID
    l_cust_site_use_rec.status                          := cv_a;                                               -- �o�^�X�e�[�^�X
    l_cust_site_use_rec.bill_to_site_use_id             := io_save_cust_key_info_rec.ln_bill_to_site_use_id;   -- �ޔ�_������_�g�p�ړIID
    l_cust_site_use_rec.price_list_id                   := NULL;                                               -- ���i�\ID
    l_cust_site_use_rec.attribute_category              := gv_sal_org_id;                                      -- �A�g���r���[�g�J�e�S��
    l_cust_site_use_rec.primary_flag                    := cv_yes;                                             -- primary_flag
    l_cust_site_use_rec.gsa_indicator                   := cv_no;                                              -- GSA�C���f�B�P�[�^('N'�FNo)
    l_cust_site_use_rec.site_use_code                   := cv_site_use_ship_to;                                -- �g�p�ړI('SHIP_TO'�F�o�א�)
    l_cust_site_use_rec.ship_sets_include_lines_flag    := cv_no;                                              -- ship_sets_include_lines_flag
    l_cust_site_use_rec.arrivalsets_include_lines_flag  := cv_no;                                              -- arrivalsets_include_lines_flag
    l_cust_site_use_rec.sched_date_push_flag            := cv_no;                                              -- sched_date_push_flag
    l_cust_site_use_rec.created_by_module               := cv_pkg_name;                                        -- �v���O����ID
    --
    --==============================================================
    -- A-5.1-12 �ڋq�g�p�ړI�}�X�^(�o�א�)�o�^
    --==============================================================
    lv_step := 'A-5.1-12';
    -- ���Ə��i�o�א�j�쐬�̕W��API���R�[��
    hz_cust_account_site_v2pub.create_cust_site_use(
      p_init_msg_list        => lv_init_msg_list               -- �������b�Z�[�W���X�g
     ,p_cust_site_use_rec    => l_cust_site_use_rec            -- �ڋq�g�p�ړI�}�X�^(�o�א惌�R�[�h�ϐ�)
     ,p_customer_profile_rec => l_customer_profile_rec         -- 
     ,p_create_profile       => lv_create_profile              -- 
     ,p_create_profile_amt   => lv_create_profile_amt          -- 
     ,x_site_use_id          => ln_ship_to_site_use_id         -- �o�א�_�g�p�ړIID
     ,x_return_status        => lv_return_status               -- ���^�[���R�[�h
     ,x_msg_count            => ln_msg_count                   -- ���^�[�����b�Z�[�W
     ,x_msg_data             => lv_msg_data                    -- ���^�[���f�[�^
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- �G���[���b�Z�[�W�擾
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_ship_to;                -- �e�[�u����
      lv_api_nm        := cv_api_cust_site_use;            -- API��
      lv_sql_errm      := lv_msg_data;                     -- API�G���[���b�Z�[�W
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
    -- �ڋq�g�p�ړI�}�X�^(������)�쐬���ʂ�KEY����ϐ��ɑޔ����܂��B
    io_save_cust_key_info_rec.ln_ship_to_site_use_id   := ln_ship_to_site_use_id;             -- �ޔ�_�o�א�_�g�p�ړIID
    io_save_cust_key_info_rec.lv_ship_to_site_use_code := l_cust_site_use_rec.site_use_code;  -- �ޔ�_�o�א�_�g�p�ړI
    --
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- �W��API�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_sql_errm                   -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_ship_to_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_other_to_api
   * Description      : �ڋq�g�p�ړI�}�X�^(���̑�)�o�^����
   ***********************************************************************************/
  PROCEDURE ins_other_to_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_other_to_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_party_number             VARCHAR2(200);
    ln_profile_id               NUMBER;
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_false;
    lv_create_profile           VARCHAR2(1)   := fnd_api.g_false;
    lv_create_profile_amt       VARCHAR2(1)   := fnd_api.g_false;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    ln_cust_account_id          NUMBER;                                                  -- �ޔ�_�ڋqID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_party_id                 hz_parties.party_id%TYPE;                                -- �ޔ�_�p�[�e�BID
    ln_location_id              hz_locations.location_id%TYPE;                           -- �ޔ�_���Ə�ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- �ޔ�_�p�[�e�B�T�C�gID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- �ޔ�_�p�[�e�B�T�C�g�ԍ�
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- �ޔ�_�ڋq�T�C�gID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_������_�g�p�ړIID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_������_�g�p�ړI
    ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_�o�א�_�g�p�ړIID
    lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_�o�א�_�g�p�ړI
    ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_���̑�_�g�p�ړIID
    lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_���̑�_�g�p�ړI
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- �ޔ�_�ڋq�v���t�@�C��ID
--
    -- *** ���[�J���E�J�[�\�� ***
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-13 �ڋq�g�p�ړI�}�X�^(���̑�)�o�^���R�[�h�쐬
    --==============================================================
    lv_step := 'A-5.1-13';
    --
    -- ���R�[�h�N���A
    l_cust_site_use_rec     := NULL; -- ���Ə����R�[�h
    --
    -- ���b�Z�[�W�p
    lv_account_number                                   := io_save_cust_key_info_rec.lv_account_number;        -- �ڋq�R�[�h
    -- �ڋq�g�p�ړI�}�X�^(���̑�)�o�^�p���R�[�h
    l_cust_site_use_rec.site_use_id                     := NULL;                                               -- ���Ə�ID
    l_cust_site_use_rec.cust_acct_site_id               := io_save_cust_key_info_rec.ln_cust_acct_site_id;     -- �ޔ�_�ڋq�T�C�gID
    l_cust_site_use_rec.status                          := cv_a;                                               -- �o�^�X�e�[�^�X
    l_cust_site_use_rec.attribute_category              := gv_sal_org_id;                                      -- �A�g���r���[�g�J�e�S��
    l_cust_site_use_rec.primary_flag                    := cv_yes;                                             -- primary_flag
    l_cust_site_use_rec.gsa_indicator                   := cv_no;                                              -- GSA�C���f�B�P�[�^('N'�FNo)
    l_cust_site_use_rec.site_use_code                   := cv_site_use_other_to;                               -- �g�p�ړI('OTHER_TO'�F���̑�)
    l_cust_site_use_rec.ship_sets_include_lines_flag    := cv_no;                                              -- ship_sets_include_lines_flag
    l_cust_site_use_rec.arrivalsets_include_lines_flag  := cv_no;                                              -- arrivalsets_include_lines_flag
    l_cust_site_use_rec.sched_date_push_flag            := cv_no;                                              -- sched_date_push_flag
    l_cust_site_use_rec.created_by_module               := cv_pkg_name;                                        -- �v���O����ID
    --
    --==============================================================
    -- A-5.1-14 �ڋq�g�p�ړI�}�X�^(���̑�)�o�^
    --==============================================================
    lv_step := 'A-5.1-14';
    -- �ڋq�g�p�ړI�}�X�^(���̑�)�쐬�̕W��API���R�[��
    hz_cust_account_site_v2pub.create_cust_site_use(
      p_init_msg_list        => lv_init_msg_list               -- �������b�Z�[�W���X�g
     ,p_cust_site_use_rec    => l_cust_site_use_rec            -- �ڋq�g�p�ړI�}�X�^(���̑����R�[�h�ϐ�)
     ,p_customer_profile_rec => l_customer_profile_rec         -- 
     ,p_create_profile       => lv_create_profile              -- 
     ,p_create_profile_amt   => lv_create_profile_amt          -- 
     ,x_site_use_id          => ln_other_to_site_use_id        -- ���̑�_�g�p�ړIID
     ,x_return_status        => lv_return_status               -- ���^�[���R�[�h
     ,x_msg_count            => ln_msg_count                   -- ���^�[�����b�Z�[�W
     ,x_msg_data             => lv_msg_data                    -- ���^�[���f�[�^
      );
    --
    IF ( lv_return_status <> fnd_api.g_ret_sts_success ) THEN 
      -- �G���[���b�Z�[�W�擾
      FND_MSG_PUB.GET(
        p_msg_index     => 1
       ,p_encoded       => fnd_api.g_false
       ,p_data          => lv_msg_data
       ,p_msg_index_out => ln_msg_count
        );
      --
      lv_table_nm      := cv_table_other_to     ;          -- �e�[�u����
      lv_api_nm        := cv_api_cust_site_use;            -- API��
      lv_sql_errm      := lv_msg_data;                     -- API�G���[���b�Z�[�W
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF;
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- �W��API�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_sql_errm                   -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_other_to_api;
--
  /**********************************************************************************
   * Procedure Name   : regist_resource_no_api
   * Description      : �g�D�v���t�@�C���g��(�S���c�ƈ�)�o�^����
   ***********************************************************************************/
  PROCEDURE regist_resource_no_api(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'regist_resource_no_api'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    -- �ޔ�p
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
--
    lv_resource_no              xxcmm_wk_cust_upload.resource_no%TYPE;                   -- �S���c�ƈ�
    ld_start_date               xxcmm_wk_cust_upload.resource_s_date%TYPE;               -- �K�p�J�n��
--
    -- *** ���[�J���E�J�[�\�� ***
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_api_expt     EXCEPTION;                                               -- �W��API�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.1-15 �g�D�v���t�@�C���g��(�S���c�ƈ�)�o�^
    --==============================================================
    lv_step := 'A-5.1-15';
    --
    -- �g�D�v���t�@�C���g��(�S���c�ƈ�)�o�^�p���R�[�h
--
    lv_account_number    := io_save_cust_key_info_rec.lv_account_number;              -- �ڋq�R�[�h
    lv_resource_no       := i_wk_cust_rec.resource_no;                                -- ���R�[�h�ϐ�.�S���c�ƈ�
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify start by Shigeto.Niki
--    gd_apply_date        := TO_DATE(i_wk_cust_rec.resource_s_date, cv_date_fmt_std);  -- ���R�[�h�ϐ�.�K�p�J�n��
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify end by Shigeto.Niki
    --
    -- �S���c�ƈ��o�^�̕W��API���R�[��
    xxcso_rtn_rsrc_pkg.regist_resource_no(
      iv_account_number    => lv_account_number     -- �ڋq�R�[�h
     ,iv_resource_no       => lv_resource_no        -- �S���c�ƈ��i�]�ƈ��R�[�h�j
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify start by Shigeto.Niki
--     ,id_start_date        => gd_apply_date         -- �K�p�J�n��
     ,id_start_date        => gd_process_date       -- �Ɩ����t
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 modify end by Shigeto.Niki
     ,ov_errbuf            => lv_errbuf             -- �V�X�e�����b�Z�[�W
     ,ov_retcode           => lv_retcode            -- ��������('0':����, '1':�x��, '2':�G���[)
     ,ov_errmsg            => lv_errmsg             -- ���[�U�[���b�Z�[�W
      );
    --
    IF ( lv_retcode <> xxcso_common_pkg.gv_status_normal ) THEN 
      lv_table_nm      := cv_table_resource;               -- �e�[�u����
      lv_api_nm        := cv_api_regist_resource;          -- API��
      -- 
      RAISE ins_xxcmm_cust_api_expt;
    END IF; 
--
  EXCEPTION
    -- *** �W��API�G���[ ***
    WHEN ins_xxcmm_cust_api_expt THEN
      -- �W��API�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10339            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_table_nm                   -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_api_name               -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_api_nm                     -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_seq_num                -- �g�[�N���R�[�h3
                    ,iv_token_value3 => i_wk_cust_rec.line_no         -- �g�[�N���l3
                    ,iv_token_name4  => cv_tkn_cust_code              -- �g�[�N���R�[�h4
                    ,iv_token_value4 => lv_account_number             -- �g�[�N���l4
                    ,iv_token_name5  => cv_tkn_errmsg                 -- �g�[�N���R�[�h5
                    ,iv_token_value5 => lv_errbuf                     -- �g�[�N���l5
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error; 
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END regist_resource_no_api;
--
  /**********************************************************************************
   * Procedure Name   : ins_cmm_cust_acct
   * Description      : �ڋq�ǉ����o�^����
   ***********************************************************************************/
  PROCEDURE ins_cmm_cust_acct(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cmm_cust_acct'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_tkn_value                VARCHAR2(100);                                           -- �g�[�N���l
    ln_cnt                      NUMBER;                                                  -- �J�E���g�p
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_init_msg_list            VARCHAR2(1)   := fnd_api.g_true;
    lv_return_status            VARCHAR2(200);
    ln_msg_count                NUMBER;
    lv_msg_data                 VARCHAR2(2000);
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    -- �ޔ�p
    ln_cust_account_id          NUMBER;                                                  -- �ޔ�_�ڋqID
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
    ln_party_id                 hz_parties.party_id%TYPE;                                -- �ޔ�_�p�[�e�BID
    ln_location_id              hz_locations.location_id%TYPE;                           -- �ޔ�_���Ə�ID
    ln_party_site_id            hz_party_sites.party_site_id%TYPE;                       -- �ޔ�_�p�[�e�B�T�C�gID
    lv_party_site_number        hz_party_sites.party_site_number%TYPE;                   -- �ޔ�_�p�[�e�B�T�C�g�ԍ�
    ln_cust_acct_site_id        hz_cust_acct_sites_all.cust_acct_site_id%TYPE;           -- �ޔ�_�ڋq�T�C�gID
    ln_bill_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_������_�g�p�ړIID
    lv_bill_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_������_�g�p�ړI
    ln_ship_to_site_use_id      hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_�o�א�_�g�p�ړIID
    lv_ship_to_site_use_code    hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_�o�א�_�g�p�ړI
    ln_other_to_site_use_id     hz_cust_site_uses_all.site_use_id%TYPE;                  -- �ޔ�_���̑�_�g�p�ړIID
    lv_other_to_site_use_code   hz_cust_site_uses_all.site_use_code%TYPE;                -- �ޔ�_���̑�_�g�p�ړI
    ln_cust_account_profile_id  hz_customer_profiles.cust_account_profile_id%TYPE;       -- �ޔ�_�ڋq�v���t�@�C��ID
--
    -- �ڋq�ǉ����o�^�p
    lv_business_low_type        xxcmm_cust_accounts.business_low_type%TYPE;              -- �Ƒԏ�����
    lv_industry_div             xxcmm_cust_accounts.industry_div%TYPE;                   -- �Ǝ�
    lv_torihiki_form            xxcmm_cust_accounts.torihiki_form%TYPE;                  -- ����`��
    lv_delivery_form            xxcmm_cust_accounts.delivery_form%TYPE;                  -- �z���`��
    lv_bill_base_code           xxcmm_cust_accounts.bill_base_code%TYPE;                 -- �������_�R�[�h
    lv_receiv_base_code         xxcmm_cust_accounts.receiv_base_code%TYPE;               -- �������_�R�[�h
    lv_invoice_printing_unit    xxcmm_cust_accounts.invoice_printing_unit%TYPE;          -- ����������P��
    lv_vist_target_div          xxcmm_cust_accounts.vist_target_div%TYPE;                -- �K��Ώۋ敪
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
    lv_delivery_base_code       xxcmm_cust_accounts.delivery_base_code%TYPE;             -- �[�i���_�R�[�h
    lv_sales_head_base_code     xxcmm_cust_accounts.sales_head_base_code%TYPE;           -- �̔���{���S�����_�R�[�h
    lv_sales_chain_code         xxcmm_cust_accounts.sales_chain_code%TYPE;               -- �̔���`�F�[���R�[�h
    lv_delivery_chain_code      xxcmm_cust_accounts.delivery_chain_code%TYPE;            -- �[�i��`�F�[���R�[�h
    lv_tax_div                  xxcmm_cust_accounts.tax_div%TYPE;                        -- ����ŋ敪
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
    lv_card_company_kbn         xxcmm_cust_accounts.card_company_div%TYPE;               -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
-- Ver1.5 add start
    lt_offset_cust_code         xxcmm_cust_accounts.offset_cust_code%TYPE;               -- ���E�p�ڋq�R�[�h
    lt_bp_customer_code         xxcmm_cust_accounts.bp_customer_code%TYPE;               -- �����ڋq�R�[�h
-- Ver1.5 add end
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_cust_acct_expt    EXCEPTION;                                               -- �ڋq�ǉ����}�X�^�o�^�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.2 �ڋq�ǉ����}�X�^�o�^
    --==============================================================
    lv_step := 'A-5.2';
    BEGIN
        lv_account_number        := io_save_cust_key_info_rec.lv_account_number; -- �ڋq�R�[�h
      -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
      IF ( gv_format = cv_file_format_mc ) THEN
        lv_business_low_type     := NULL;                                  -- �Ƒԏ�����
        lv_industry_div          := NULL;                                  -- �Ǝ�
        lv_torihiki_form         := NULL;                                  -- ����`��
        lv_delivery_form         := NULL;                                  -- �z���`��
        lv_bill_base_code        := i_wk_cust_rec.sale_base_code;          -- �������_�R�[�h
        lv_receiv_base_code      := i_wk_cust_rec.sale_base_code;          -- �������_�R�[�h
        lv_invoice_printing_unit := gv_inv_unit;                           -- ����������P��
        lv_vist_target_div       := NULL;                                  -- �K��Ώۋ敪
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
        lv_delivery_base_code    := NULL;                                  -- �[�i���_�R�[�h
        lv_sales_head_base_code  := NULL;                                  -- �̔���{���S�����_�R�[�h
        lv_sales_chain_code      := i_wk_cust_rec.sales_chain_code;        -- �̔���`�F�[���R�[�h
        lv_delivery_chain_code   := i_wk_cust_rec.delivery_chain_code;     -- �[�i��`�F�[���R�[�h
        lv_tax_div               := NULL;                                  -- ����ŋ敪
-- Ver1.5 add start
        lt_offset_cust_code      := i_wk_cust_rec.offset_cust_code;        -- ���E�p�ڋq�R�[�h
        lt_bp_customer_code      := i_wk_cust_rec.bp_customer_code;        -- �����ڋq�R�[�h
-- Ver1.5 add end
      --ELSE
      -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
      ELSIF ( gv_format = cv_file_format_st ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
        lv_business_low_type     := i_wk_cust_rec.business_low_type;       -- �Ƒԏ�����
        lv_industry_div          := i_wk_cust_rec.industry_div;            -- �Ǝ�
        lv_torihiki_form         := i_wk_cust_rec.torihiki_form;           -- ����`��
        lv_delivery_form         := i_wk_cust_rec.delivery_form;           -- �z���`��
        lv_bill_base_code        := NULL;                                  -- �������_�R�[�h
        lv_receiv_base_code      := NULL;                                  -- �������_�R�[�h
        lv_invoice_printing_unit := NULL;                                  -- ����������P��
        lv_vist_target_div       := cv_vist_target;                        -- �K��Ώۋ敪
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
        lv_delivery_base_code    := NULL;                                  -- �[�i���_�R�[�h
        lv_sales_head_base_code  := NULL;                                  -- �̔���{���S�����_�R�[�h
        lv_sales_chain_code      := i_wk_cust_rec.sales_chain_code;        -- �̔���`�F�[���R�[�h
        lv_delivery_chain_code   := i_wk_cust_rec.delivery_chain_code;     -- �[�i��`�F�[���R�[�h
        lv_tax_div               := NULL;                                  -- ����ŋ敪
      -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
      ELSIF ( gv_format = cv_file_format_ho ) THEN
        lv_business_low_type     := NULL;                                  -- �Ƒԏ�����
        lv_industry_div          := NULL;                                  -- �Ǝ�
        lv_torihiki_form         := NULL;                                  -- ����`��
        lv_delivery_form         := NULL;                                  -- �z���`��
        lv_bill_base_code        := NULL;                                  -- �������_�R�[�h
        lv_receiv_base_code      := NULL;                                  -- �������_�R�[�h
        lv_invoice_printing_unit := NULL;                                  -- ����������P��
        lv_vist_target_div       := NULL;                                  -- �K��Ώۋ敪
        lv_delivery_base_code    := NULL;                                  -- �[�i���_�R�[�h
        lv_sales_head_base_code  := NULL;                                  -- �̔���{���S�����_�R�[�h
        lv_sales_chain_code      := NULL;                                  -- �̔���`�F�[���R�[�h
        lv_delivery_chain_code   := NULL;                                  -- �[�i��`�F�[���R�[�h
        lv_tax_div               := NULL;                                  -- ����ŋ敪
      -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
      ELSIF ( gv_format = cv_file_format_ur ) THEN
        lv_business_low_type     := i_wk_cust_rec.business_low_type;       -- �Ƒԏ�����
        lv_industry_div          := i_wk_cust_rec.industry_div;            -- �Ǝ�
        lv_torihiki_form         := NULL;                                  -- ����`��
        lv_delivery_form         := NULL;                                  -- �z���`��
        lv_bill_base_code        := i_wk_cust_rec.bill_base_code;          -- �������_�R�[�h
        lv_receiv_base_code      := i_wk_cust_rec.receiv_base_code;        -- �������_�R�[�h
        lv_invoice_printing_unit := NULL;                                  -- ����������P��
        lv_vist_target_div       := NULL;                                  -- �K��Ώۋ敪
        lv_delivery_base_code    := i_wk_cust_rec.delivery_base_code;      -- �[�i���_�R�[�h
        lv_sales_head_base_code  := i_wk_cust_rec.sales_head_base_code;    -- �̔���{���S�����_�R�[�h
        lv_sales_chain_code      := i_wk_cust_rec.sales_chain_code;        -- �̔���`�F�[���R�[�h
        lv_delivery_chain_code   := i_wk_cust_rec.delivery_chain_code;     -- �[�i��`�F�[���R�[�h
        lv_tax_div               := i_wk_cust_rec.tax_div;                 -- ����ŋ敪
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
        lv_card_company_kbn      := i_wk_cust_rec.card_company_kbn;        -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
      END IF;
      --
      -- �ڋq�ǉ����e�[�u���̓o�^
      INSERT INTO xxcmm_cust_accounts
      (
        customer_id,                                    -- �ڋqID
        customer_code,                                  -- �ڋq�R�[�h
        cust_update_flag,                               -- �V�K�^�X�V�t���O
        business_low_type,                              -- �Ƒԁi�����ށj
        industry_div,                                   -- �Ǝ�
        selling_transfer_div,                           -- ������ѐU��
        torihiki_form,                                  -- ����`��
        delivery_form,                                  -- �z���`��
        wholesale_ctrl_code,                            -- �≮�Ǘ��R�[�h
        ship_storage_code,                              -- �o�׌��ۊǏꏊ(EDI)
        start_tran_date,                                -- ��������
        final_tran_date,                                -- �ŏI�����
        past_final_tran_date,                           -- �O���ŏI�����
        final_call_date,                                -- �ŏI�K���
        stop_approval_date,                             -- ���~���ٓ�
        stop_approval_reason,                           -- ���~���R
        vist_untarget_date,                             -- �ڋq�ΏۊO�ύX��
        vist_target_div,                                -- �K��Ώۋ敪
        party_representative_name,                      -- ��\�Җ��i�����j
        party_emp_name,                                 -- �S���ҁi�����j
        sale_base_code,                                 -- ���㋒�_�R�[�h
        past_sale_base_code,                            -- �O�����㋒�_�R�[�h
        rsv_sale_base_act_date,                         -- �\�񔄏㋒�_�L���J�n��
        rsv_sale_base_code,                             -- �\�񔄏㋒�_�R�[�h
        delivery_base_code,                             -- �[�i���_�R�[�h
        sales_head_base_code,                           -- �̔���{���S�����_
        chain_store_code,                               -- �`�F�[���X�R�[�h�iEDI�j
        store_code,                                     -- �X�܃R�[�h
        cust_store_name,                                -- �ڋq�X�ܖ���
        torihikisaki_code,                              -- �����R�[�h
        sales_chain_code,                               -- �̔���`�F�[���R�[�h
        delivery_chain_code,                            -- �[�i��`�F�[���R�[�h
        policy_chain_code,                              -- �����p�`�F�[���R�[�h
        intro_chain_code1,                              -- �Љ�҃`�F�[���R�[�h�P
        intro_chain_code2,                              -- �Љ�҃`�F�[���R�[�h�Q
        tax_div,                                        -- ����ŋ敪
        rate,                                           -- �����v�Z�p�|��
        receiv_discount_rate,                           -- �����l����
        conclusion_day1,                                -- �����v�Z���ߓ��P
        conclusion_day2,                                -- �����v�Z���ߓ��Q
        conclusion_day3,                                -- �����v�Z���ߓ��R
        contractor_supplier_code,                       -- �_��Ҏd����R�[�h
        bm_pay_supplier_code1,                          -- �Љ��BM�x���d����R�[�h�P
        bm_pay_supplier_code2,                          -- �Љ��BM�x���d����R�[�h�Q
        delivery_order,                                 -- �z�����iEDI)
        edi_district_code,                              -- EDI�n��R�[�h�iEDI)
        edi_district_name,                              -- EDI�n�於�iEDI)
        edi_district_kana,                              -- EDI�n�於�J�i�iEDI)
        center_edi_div,                                 -- �Z���^�[EDI�敪
        tsukagatazaiko_div,                             -- �ʉߍ݌Ɍ^�敪�iEDI�j
        establishment_location,                         -- �ݒu���P�[�V����
        open_close_div,                                 -- �����I�[�v���E�N���[�Y�敪
        operation_div,                                  -- �I�y���[�V�����敪
        change_amount,                                  -- �ޑK
        vendor_machine_number,                          -- �����̔��@�ԍ��i�����j
        established_site_name,                          -- �ݒu�於�i�����j
        cnvs_date,                                      -- �ڋq�l����
        cnvs_base_code,                                 -- �l�����_�R�[�h
        cnvs_business_person,                           -- �l���c�ƈ�
        new_point_div,                                  -- �V�K�|�C���g�敪
        new_point,                                      -- �V�K�|�C���g
        intro_base_code,                                -- �Љ�_�R�[�h
        intro_business_person,                          -- �Љ�c�ƈ�
        edi_chain_code,                                 -- �`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z
        latitude,                                       -- �ܓx
        longitude,                                      -- �o�x
        management_base_code,                           -- �Ǘ������_�R�[�h
        edi_item_code_div,                              -- EDI�A�g�i�ڃR�[�h�敪
        edi_forward_number,                             -- EDI�`���ǔ�
        handwritten_slip_div,                           -- EDI�菑�`�[�`���敪
        deli_center_code,                               -- EDI�[�i�Z���^�[�R�[�h
        deli_center_name,                               -- EDI�[�i�Z���^�[��
        dept_hht_div,                                   -- �S�ݓX�pHHT�敪
        bill_base_code,                                 -- �������_�R�[�h
        receiv_base_code,                               -- �������_�R�[�h
        child_dept_shop_code,                           -- �S�ݓX�`��R�[�h
        parnt_dept_shop_code,                           -- �S�ݓX�`��R�[�h�y�e���R�[�h�p�z
        past_customer_status,                           -- �O���ڋq�X�e�[�^�X
        card_company_div,                               -- �J�[�h��Ћ敪
        card_company,                                   -- �J�[�h���
        invoice_printing_unit,                          -- ����������P��
        invoice_code        ,                           -- �������p�R�[�h
        enclose_invoice_code,                           -- �����������p�R�[�h
        store_cust_code,                                -- �X�܉c�Ɨp�ڋq�R�[�h
-- Ver1.5 add start
        offset_cust_code,                               -- ���E�p�ڋq�R�[�h
        bp_customer_code,                               -- �����ڋq�R�[�h
-- Ver1.5 add end
        created_by,                                     -- �쐬��
        creation_date,                                  -- �쐬��
        last_updated_by,                                -- �ŏI�X�V��
        last_update_date,                               -- �ŏI�X�V��
        last_update_login,                              -- �ŏI�X�V۸޲�
        request_id,                                     -- �v��ID
        program_application_id,                         -- �R���J�����g��v���O������A�v���P�[�V����ID
        program_id,                                     -- �R���J�����g��v���O����ID
        program_update_date                             -- �v���O�����X�V��
      )
      VALUES
      (
        io_save_cust_key_info_rec.ln_cust_account_id,   -- �ڋqID
        io_save_cust_key_info_rec.lv_account_number,    -- �ڋq�R�[�h
        cv_ui_flag_new,                                 -- �V�K�^�X�V�t���O
        lv_business_low_type,                           -- �Ƒԁi�����ށj
        lv_industry_div,                                -- �Ǝ�
        NULL,                                           -- ������ѐU��
        lv_torihiki_form,                               -- ����`��
        lv_delivery_form,                               -- �z���`��
        NULL,                                           -- �≮�Ǘ��R�[�h
        NULL,                                           -- �o�׌��ۊǏꏊ(EDI)
        NULL,                                           -- ��������
        NULL,                                           -- �ŏI�����
        NULL,                                           -- �O���ŏI�����
        NULL,                                           -- �ŏI�K���
        NULL,                                           -- ���~���ٓ�
        NULL,                                           -- ���~���R
        NULL,                                           -- �ڋq�ΏۊO�ύX��
        lv_vist_target_div,                             -- �K��Ώۋ敪
        NULL,                                           -- ��\�Җ��i�����j
        NULL,                                           -- �S���ҁi�����j
        SUBSTRB(i_wk_cust_rec.sale_base_code, 1, 4),    -- ���㋒�_�R�[�h
        SUBSTRB(i_wk_cust_rec.sale_base_code, 1, 4),    -- �O�����㋒�_�R�[�h
        NULL,                                           -- �\�񔄏㋒�_�L���J�n��
        NULL,                                           -- �\�񔄏㋒�_�R�[�h
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        --NULL,                                           -- �[�i���_�R�[�h
        --NULL,                                           -- �̔���{���S�����_
        lv_delivery_base_code,                          -- �[�i���_�R�[�h
        lv_sales_head_base_code,                        -- �̔���{���S�����_
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        NULL,                                           -- �`�F�[���X�R�[�h�iEDI�j
        NULL,                                           -- �X�܃R�[�h
        NULL,                                           -- �ڋq�X�ܖ���
        NULL,                                           -- �����R�[�h
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        --i_wk_cust_rec.sales_chain_code,                 -- �̔���`�F�[���R�[�h
        --i_wk_cust_rec.delivery_chain_code,              -- �[�i��`�F�[���R�[�h
        lv_sales_chain_code,                            -- �̔���`�F�[���R�[�h
        lv_delivery_chain_code,                         -- �[�i��`�F�[���R�[�h
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        NULL,                                           -- �����p�`�F�[���R�[�h
        NULL,                                           -- �Љ�҃`�F�[���R�[�h�P
        NULL,                                           -- �Љ�҃`�F�[���R�[�h�Q
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
        --NULL,                                           -- ����ŋ敪
        lv_tax_div,                                     -- ����ŋ敪
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
        NULL,                                           -- �����v�Z�p�|��
        NULL,                                           -- �����l����
        NULL,                                           -- �����v�Z���ߓ��P
        NULL,                                           -- �����v�Z���ߓ��Q
        NULL,                                           -- �����v�Z���ߓ��R
        NULL,                                           -- �_��Ҏd����R�[�h
        NULL,                                           -- �Љ��BM�x���d����R�[�h�P
        NULL,                                           -- �Љ��BM�x���d����R�[�h�Q
        NULL,                                           -- �z�����iEDI)
        NULL,                                           -- EDI�n��R�[�h�iEDI)
        NULL,                                           -- EDI�n�於�iEDI)
        NULL,                                           -- EDI�n�於�J�i�iEDI)
        NULL,                                           -- �Z���^�[EDI�敪
        NULL,                                           -- �ʉߍ݌Ɍ^�敪�iEDI�j
        NULL,                                           -- �ݒu���P�[�V����
        NULL,                                           -- �����I�[�v���E�N���[�Y�敪
        NULL,                                           -- �I�y���[�V�����敪
        NULL,                                           -- �ޑK
        NULL,                                           -- �����̔��@�ԍ��i�����j
        NULL,                                           -- �ݒu�於�i�����j
        NULL,                                           -- �ڋq�l����
        NULL,                                           -- �l�����_�R�[�h
        NULL,                                           -- �l���c�ƈ�
        NULL,                                           -- �V�K�|�C���g�敪
        NULL,                                           -- �V�K�|�C���g
        NULL,                                           -- �Љ�_�R�[�h
        NULL,                                           -- �Љ�c�ƈ�
        NULL,                                           -- �`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z
        NULL,                                           -- �ܓx
        NULL,                                           -- �o�x
        NULL,                                           -- �Ǘ������_�R�[�h
        NULL,                                           -- EDI�A�g�i�ڃR�[�h�敪
        NULL,                                           -- EDI�`���ǔ�
        NULL,                                           -- EDI�菑�`�[�`���敪
        NULL,                                           -- EDI�[�i�Z���^�[�R�[�h
        NULL,                                           -- EDI�[�i�Z���^�[��
        NULL,                                           -- �S�ݓX�pHHT�敪
        lv_bill_base_code,                              -- �������_�R�[�h
        lv_receiv_base_code,                            -- �������_�R�[�h
        NULL,                                           -- �S�ݓX�`��R�[�h
        NULL,                                           -- �S�ݓX�`��R�[�h�y�e���R�[�h�p�z
        NULL,                                           -- �O���ڋq�X�e�[�^�X
-- Ver1.3 K.Nakamura mod start
--        NULL,                                           -- �J�[�h��Ћ敪
        lv_card_company_kbn,                            -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura mod end
        NULL,                                           -- �J�[�h���
        lv_invoice_printing_unit,                       -- ����������P��
        NULL,                                           -- �������p�R�[�h
        NULL,                                           -- �����������p�R�[�h
        NULL,                                           -- �X�܉c�Ɨp�ڋq�R�[�h
-- Ver1.5 add start
        lt_offset_cust_code,                            -- ���E�p�ڋq�R�[�h
        lt_bp_customer_code,                            -- �����ڋq�R�[�h
-- Ver1.5 add end
        cn_created_by,                                  -- �쐬��
        cd_creation_date,                               -- �쐬��
        cn_last_updated_by,                             -- �ŏI�X�V��
        cd_last_update_date,                            -- �ŏI�X�V��
        cn_last_update_login,                           -- �ŏI�X�V���O�C��
        cn_request_id,                                  -- �v��ID
        cn_program_application_id,                      -- �R���J�����g��v���O������A�v���P�[�V����ID
        cn_program_id,                                  -- �R���J�����g��v���O����ID
        cd_program_update_date                          -- �v���O�����X�V��
      )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN                   -- �ڋq�ǉ����o�^�G���[
        -- �G���[���b�Z�[�W�擾
        lv_api_nm        := cv_api_regist_resource;            -- API��
        lv_sql_errm      := SQLERRM;
        RAISE ins_xxcmm_cust_acct_expt;
    END;
--
  EXCEPTION
    --*** �ڋq�ǉ����}�X�^�o�^�G���[ ***
    WHEN ins_xxcmm_cust_acct_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10340            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_seq_num                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_cust_rec.line_no         -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_cust_code              -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_account_number             -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                    ,iv_token_value3 => lv_sql_errm                   -- �g�[�N���l3
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_cmm_cust_acct;
--
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
  /**********************************************************************************
   * Procedure Name   : ins_cmm_mst_crprt
   * Description      : �ڋq�@�l���o�^����
   ***********************************************************************************/
  PROCEDURE ins_cmm_mst_crprt(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_cmm_mst_crprt'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    lv_api_nm                   VARCHAR2(200);                                           -- API��
    lv_api_err_msg              VARCHAR2(2000);                                          -- API�G���[���b�Z�[�W
    lv_table_nm                 VARCHAR2(200);                                           -- �e�[�u����
--
    -- �ޔ�p
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_xxcmm_mst_crprt_expt    EXCEPTION;                                               -- �ڋq�@�l���}�X�^�o�^�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.3 �ڋq�@�l���}�X�^�o�^
    --==============================================================
    lv_step := 'A-5.3';
    BEGIN
      lv_account_number        := io_save_cust_key_info_rec.lv_account_number; -- �ڋq�R�[�h
      -- �ڋq�@�l���e�[�u���̓o�^
      INSERT INTO xxcmm_mst_corporate
      (
          customer_id                                            -- �ڋqID
         ,tdb_code                                               -- TDB�R�[�h
         ,base_code                                              -- �{���S�����_
         ,credit_limit                                           -- �^�M���x�z
         ,decide_div                                             -- ����敪
         ,approval_date                                          -- ���ٓ��t
         ,enterprise_group_code                                  -- ��ƃO���[�v�R�[�h
         ,representative_name                                    -- ��\�Җ�
         ,applicant_base_code                                    -- �\�����_
         ,created_by                                             -- �쐬��
         ,creation_date                                          -- �쐬��
         ,last_updated_by                                        -- �ŏI�X�V��
         ,last_update_date                                       -- �ŏI�X�V��
         ,last_update_login                                      -- �ŏI�X�V���O�C��
         ,request_id                                             -- �v��ID
         ,program_application_id                                 -- �R���J�����g��v���O������A�v���P�[�V����ID
         ,program_id                                             -- �R���J�����g��v���O����ID
         ,program_update_date                                    -- �v���O�����X�V��
      )
      VALUES
      (
          io_save_cust_key_info_rec.ln_cust_account_id           -- �ڋqID
         ,i_wk_cust_rec.tdb_code                                 -- TDB�R�[�h
         ,i_wk_cust_rec.base_code                                -- �{���S�����_
         ,TO_NUMBER(i_wk_cust_rec.credit_limit)                  -- �^�M���x�z
         ,i_wk_cust_rec.decide_div                               -- ����敪
         ,TO_DATE(i_wk_cust_rec.approval_date , cv_date_fmt_std) -- ���ٓ��t
         ,NULL                                                   -- ��ƃO���[�v�R�[�h
         ,NULL                                                   -- ��\�Җ�
         ,NULL                                                   -- �\�����_
         ,cn_created_by                                          -- �쐬��
         ,cd_creation_date                                       -- �쐬��
         ,cn_last_updated_by                                     -- �ŏI�X�V��
         ,cd_last_update_date                                    -- �ŏI�X�V��
         ,cn_last_update_login                                   -- �ŏI�X�V���O�C��
         ,cn_request_id                                          -- �v��ID
         ,cn_program_application_id                              -- �R���J�����g��v���O������A�v���P�[�V����ID
         ,cn_program_id                                          -- �R���J�����g��v���O����ID
         ,cd_program_update_date                                 -- �v���O�����X�V��
      )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN                   -- �ڋq�@�l���o�^�G���[
        -- �G���[���b�Z�[�W�擾
        lv_api_nm        := cv_api_regist_resource;            -- API��
        lv_sql_errm      := SQLERRM;
        RAISE ins_xxcmm_mst_crprt_expt;
    END;
--
  EXCEPTION
    --*** �ڋq�@�l���}�X�^�o�^�G���[ ***
    WHEN ins_xxcmm_mst_crprt_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_10344            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_seq_num                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_cust_rec.line_no         -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_cust_code              -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_account_number             -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                    ,iv_token_value3 => lv_sql_errm                   -- �g�[�N���l3
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_cmm_mst_crprt;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 SCSK K.Nakamura add start
  /**********************************************************************************
   * Procedure Name   : ins_rcpmia
   * Description      : �ڋq�x�����@OIF�o�^����
   ***********************************************************************************/
  PROCEDURE ins_rcpmia(
    i_wk_cust_rec              IN  xxcmm_wk_cust_upload%ROWTYPE  -- �ڋq�ꊇ�o�^���[�N���
   ,io_save_cust_key_info_rec  IN OUT save_cust_key_info_rtype   -- �ޔ�KEY��񃌃R�[�h
   ,ov_errbuf                  OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                 OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                  OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rcpmia'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_step                     VARCHAR2(10);                                            -- �X�e�b�v
    lv_sql_errm                 VARCHAR2(2000);                                          -- SQLERRM
--
    -- �ޔ�p
    lv_account_number           hz_cust_accounts.account_number%TYPE;                    -- �ޔ�_�ڋq�R�[�h
--
    lv_receipt_method_name      ra_cust_pay_method_int_all.payment_method_name%TYPE;     -- �x�����@
    ln_cust_acct_site_id        ra_cust_pay_method_int_all.orig_system_address_ref%TYPE; -- �ڋq�T�C�gID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    ins_rcpmia_expt             EXCEPTION;                                               -- �ڋq�x�����@OIF�o�^�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- A-5.4 �ڋq�x�����@OIF�o�^
    --==============================================================
    lv_step := 'A-5.4';
    BEGIN
      lv_account_number        := io_save_cust_key_info_rec.lv_account_number;    -- �ڋq�R�[�h
      lv_receipt_method_name   := i_wk_cust_rec.receipt_method_name;              -- �x�����@
      ln_cust_acct_site_id     := io_save_cust_key_info_rec.ln_cust_acct_site_id; -- �ޔ�_�ڋq�T�C�gID
      -- �ڋq�x�����@OIF�̓o�^
      INSERT INTO ra_cust_pay_method_int_all
      (
          orig_system_customer_ref                       -- �I���W�i���V�X�e���ڋqKEY
         ,payment_method_name                            -- �x�����@��
         ,primary_flag                                   -- ��t���O
         ,orig_system_address_ref                        -- �I���W�i���V�X�e���ڋq�T�C�gKEY
         ,start_date                                     -- �L�����i���j
         ,end_date                                       -- �L�����i���j
         ,request_id                                     -- �v��ID
         ,interface_status                               -- �C���^�[�t�F�[�X�X�e�[�^�X
         ,validated_flag                                 -- �L���t���O
         ,attribute_category                             -- ATTRIBUTE�J�e�S��
         ,attribute1                                     -- ATTRIBUTE1
         ,attribute2                                     -- ATTRIBUTE2
         ,attribute3                                     -- ATTRIBUTE3
         ,attribute4                                     -- ATTRIBUTE4
         ,attribute5                                     -- ATTRIBUTE5
         ,attribute6                                     -- ATTRIBUTE6
         ,attribute7                                     -- ATTRIBUTE7
         ,attribute8                                     -- ATTRIBUTE8
         ,attribute9                                     -- ATTRIBUTE9
         ,attribute10                                    -- ATTRIBUTE10
         ,attribute11                                    -- ATTRIBUTE11
         ,attribute12                                    -- ATTRIBUTE12
         ,attribute13                                    -- ATTRIBUTE13
         ,attribute14                                    -- ATTRIBUTE14
         ,attribute15                                    -- ATTRIBUTE15
         ,last_update_date                               -- �ŏI�X�V��
         ,last_updated_by                                -- �ŏI�X�V��
         ,created_by                                     -- �쐬��
         ,creation_date                                  -- �쐬��
         ,last_update_login                              -- �ŏI�X�V۸޲�
         ,org_id                                         -- �g�DID
      ) VALUES (
          io_save_cust_key_info_rec.ln_cust_account_id   -- �ڋq�A�J�E���gID
         ,lv_receipt_method_name                         -- �x�����@��
         ,cv_y                                           -- ��t���O
         ,ln_cust_acct_site_id                           -- �I���W�i���V�X�e���ڋq�T�C�gKEY
         ,TO_DATE(cv_rcpmia_start_date, cv_date_fmt_std) -- �L�����i���j
         ,NULL                                           -- �L�����i���j
         ,cn_request_id                                  -- �v��ID
         ,NULL                                           -- �C���^�[�t�F�[�X�X�e�[�^�X 
         ,NULL                                           -- �L���t���O
         ,NULL                                           -- ATTRIBUTE�J�e�S��
         ,NULL                                           -- ATTRIBUTE1
         ,NULL                                           -- ATTRIBUTE2
         ,NULL                                           -- ATTRIBUTE3
         ,NULL                                           -- ATTRIBUTE4
         ,NULL                                           -- ATTRIBUTE5
         ,NULL                                           -- ATTRIBUTE6
         ,NULL                                           -- ATTRIBUTE7
         ,NULL                                           -- ATTRIBUTE8
         ,NULL                                           -- ATTRIBUTE9
         ,NULL                                           -- ATTRIBUTE10
         ,NULL                                           -- ATTRIBUTE11
         ,NULL                                           -- ATTRIBUTE12
         ,NULL                                           -- ATTRIBUTE13
         ,NULL                                           -- ATTRIBUTE14
         ,NULL                                           -- ATTRIBUTE15
         ,cd_last_update_date                            -- �ŏI�X�V��
         ,cn_last_updated_by                             -- �ŏI�X�V��
         ,cn_created_by                                  -- �쐬��
         ,cd_creation_date                               -- �쐬��
         ,cn_last_update_login                           -- �ŏI�X�V���O�C��
         ,gv_sal_org_id                                  -- �g�DID
      )
      ;
      -- �x�����@OIF�o�^�����擾
      gn_rcpmia_cnt := SQL%ROWCOUNT;
    --
    EXCEPTION
      WHEN OTHERS THEN                   -- �ڋq�x�����@OIF�o�^�G���[
        -- �G���[���b�Z�[�W�擾
        lv_sql_errm := SQLERRM;
        RAISE ins_rcpmia_expt;
    END;
--
  EXCEPTION
    --*** �ڋq�x�����@OIF�o�^�G���[ ***
    WHEN ins_rcpmia_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00366            -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_seq_num                -- �g�[�N���R�[�h1
                    ,iv_token_value1 => i_wk_cust_rec.line_no         -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_cust_code              -- �g�[�N���R�[�h2
                    ,iv_token_value2 => lv_account_number             -- �g�[�N���l2
                    ,iv_token_name3  => cv_tkn_errmsg                 -- �g�[�N���R�[�h3
                    ,iv_token_value3 => lv_sql_errm                   -- �g�[�N���l3
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_rcpmia;
--
  /**********************************************************************************
   * Procedure Name   : submit_request_racust
   * Description      :�ڋq�C���^�t�F�[�X���s���� (A-7)
   ***********************************************************************************/
  PROCEDURE submit_request_racust(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_request_racust'; -- �v���O������
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
    lv_step                   VARCHAR2(10);   -- �X�e�b�v
    lv_phase                  VARCHAR2(50);   -- �v���t�F�[�Y
    lv_status                 VARCHAR2(50);   -- �v���X�e�[�^�X
    lv_dev_phase              VARCHAR2(50);   -- �v���t�F�[�Y�R�[�h
    lv_dev_status             VARCHAR2(50);   -- �v���X�e�[�^�X�R�[�h
    lv_message                VARCHAR2(5000); -- �������b�Z�[�W
    ln_request_id             NUMBER;         -- �v��ID
    lb_wait_request           BOOLEAN;        -- �I���ҋ@����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    racust_expt               EXCEPTION;                                        -- �ڋq�C���^�t�F�[�X�G���[
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    --==============================================================
    -- A-7  �ڋq�C���^�t�F�[�X���s����
    --  A-7.7-1  �ڋq�C���^�t�F�[�X���s
    --==============================================================
    lv_step := 'A-7.1';
    ln_request_id := fnd_request.submit_request(
                       application => cv_appl_name_ar -- �A�v���P�[�V�����Z�k��
                      ,program     => cv_conc_racust  -- �R���J�����g�v���O������
                      ,description => NULL            -- �E�v
                      ,start_time  => NULL            -- �J�n����
                      ,sub_request => FALSE           -- �T�u�v��
                      ,argument1   => cv_no           -- ���݊֘A�ڋq�A�J�E���g�֘A�̍쐬�ɑ΂��āANo
                     );
    -- �ڋq�C���^�t�F�[�X�N�����b�Z�[�W
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_appl_name_xxcmm -- �A�v���P�[�V�����Z�k��
                  ,iv_name        => cv_msg_xxcmm_00367 -- ���b�Z�[�W
                  ,iv_token_name1  => cv_tkn_req_id     -- �g�[�N���R�[�h1
                  ,iv_token_value1 => ln_request_id     -- �g�[�N���l1
                 );
    --
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_errmsg
    );
    -- ����ȊO�̏ꍇ
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00368 -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_errmsg      -- �g�[�N���R�[�h1
                    ,iv_token_value1 => SQLERRM            -- �g�[�N���l1
                   );
      -- �ڋq�C���^�t�F�[�X�G���[
      RAISE racust_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --==============================================================
    -- A-7  �ڋq�C���^�t�F�[�X���s����
    --  A-7.7-2  �I���ҋ@
    --==============================================================
    lv_step := 'A-7.2';
    lb_wait_request := fnd_concurrent.wait_for_request(
                         request_id => ln_request_id   -- �v��ID
                        ,interval   => gn_inter_racust -- �R���J�����g�Ď��Ԋu
                        ,max_wait   => gn_max_racust   -- �R���J�����g�Ď��ő厞��
                        ,phase      => lv_phase        -- �v���t�F�[�Y
                        ,status     => lv_status       -- �v���X�e�[�^�X
                        ,dev_phase  => lv_dev_phase    -- �v���t�F�[�Y�R�[�h
                        ,dev_status => lv_dev_status   -- �v���X�e�[�^�X�R�[�h
                        ,message    => lv_message      -- �������b�Z�[�W
                       );
    -- �߂�l��FALSE�̏ꍇ
    IF ( lb_wait_request = FALSE ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00369 -- ���b�Z�[�W
                    ,iv_token_name1  => cv_tkn_errmsg      -- �g�[�N���R�[�h1
                    ,iv_token_value1 => lv_message         -- �g�[�N���l1
                   );
      -- �ڋq�C���^�t�F�[�X�G���[
      RAISE racust_expt;
    ELSE
      -- ����I�����b�Z�[�W�o��
      IF ( lv_dev_status = cv_dev_status_normal ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm
                      ,iv_name         => cv_msg_xxcmm_00370
                     );
      -- �x���I�����b�Z�[�W�o��
      ELSIF ( lv_dev_status = cv_dev_status_warn ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcmm
                      ,iv_name         => cv_msg_xxcmm_00371
                      ,iv_token_name1  => cv_tkn_errmsg
                      ,iv_token_value1 => lv_message
                     );
        ov_retcode := cv_status_warn;
      -- �G���[�I�����b�Z�[�W�o��
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm
                      ,iv_name         => cv_msg_xxcmm_00372
                      ,iv_token_name1  => cv_tkn_errmsg
                      ,iv_token_value1 => lv_message
                     );
        -- �ڋq�C���^�t�F�[�X�G���[
        RAISE racust_expt;
      END IF;
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --
      --��s�}��
      FND_FILE.PUT_LINE(
         which => FND_FILE.OUTPUT
        ,buff  => ''
      );
    END IF;
--
  EXCEPTION
    --*** �ڋq�C���^�t�F�[�X�G���[ ***
    WHEN racust_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submit_request_racust;
-- Ver1.3 SCSK K.Nakamura add end
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : �ڋq�ꊇ�o�^���[�N�f�[�^�擾 (A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    iv_file_id    IN  VARCHAR2          -- 1.�t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- 2.�t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'loop_main'; -- �v���O������
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
    lv_step                   VARCHAR2(10);                                     -- �X�e�b�v
    ln_line_cnt               NUMBER;                                           -- �s�J�E���^
    lv_check_flag             VARCHAR2(1);                                      -- �`�F�b�N�t���O
    lv_error_flag             VARCHAR2(1);                                      -- �ޔ�p���^�[���E�R�[�h
    ln_request_id             NUMBER;                                           -- �v��ID
    lv_status_val             VARCHAR2(5000);                                   -- �X�e�[�^�X�l
--
    l_save_cust_key_info_rec  save_cust_key_info_rtype;                         -- �ޔ�KEY��񃌃R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �ڋq�ꊇ�o�^���[�N�f�[�^�擾�J�[�\��
    CURSOR get_data_cur
    IS
      SELECT     xwcu.file_id                             -- �t�@�C��ID
                ,xwcu.line_no                             -- �s�ԍ�
                ,xwcu.customer_name                       -- �ڋq��
                ,xwcu.customer_name_kana                  -- �ڋq���J�i
                ,xwcu.customer_name_ryaku                 -- ����
                ,xwcu.customer_class_code                 -- �ڋq�敪
                ,xwcu.customer_status                     -- �ڋq�X�e�[�^�X
                ,xwcu.sale_base_code                      -- ���㋒�_
                ,xwcu.sales_chain_code                    -- �̔���`�F�[��
                ,xwcu.delivery_chain_code                 -- �[�i��`�F�[��
                ,xwcu.postal_code                         -- �X�֔ԍ�
                ,xwcu.state                               -- �s���{��
                ,xwcu.city                                -- �s�E��
                ,xwcu.address1                            -- �Z���P
                ,xwcu.address2                            -- �Z���Q
                ,xwcu.address3                            -- �n��R�[�h
                ,xwcu.tel_no                              -- �d�b�ԍ�
                ,xwcu.fax                                 -- FAX
                ,xwcu.business_low_type_tmp               -- �Ƒԏ�����(��)
                ,xwcu.manager_name                        -- �X����
                ,xwcu.emp_number                          -- �Ј���
                ,xwcu.rest_emp_name                       -- �S���ҋx��
                ,xwcu.mc_hot_deg                          -- MC�FHOT�x
                ,xwcu.mc_importance_deg                   -- MC�F�d�v�x
                ,xwcu.mc_conf_info                        -- MC�F�������
                ,xwcu.mc_business_talk_details            -- MC�F���k�o��
                ,xwcu.resource_no                         -- �S���c�ƈ�
                ,xwcu.resource_s_date                     -- �K�p�J�n��(�S���c�ƈ�)
                ,xwcu.business_low_type                   -- �Ƒԏ�����
                ,xwcu.industry_div                        -- �Ǝ�
                ,xwcu.torihiki_form                       -- ����`��
                ,xwcu.delivery_form                       -- �z���`��
                ,xwcu.created_by                          -- �쐬��
                ,xwcu.creation_date                       -- �쐬��
                ,xwcu.last_updated_by                     -- �ŏI�X�V��
                ,xwcu.last_update_date                    -- �ŏI�X�V��
                ,xwcu.last_update_login                   -- �ŏI�X�V���O�C��ID
                ,xwcu.request_id                          -- �v��ID
                ,xwcu.program_application_id              -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
                ,xwcu.program_id                          -- �R���J�����g�E�v���O����ID
                ,xwcu.program_update_date                 -- �v���O�����ɂ��X�V��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
                ,xwcu.tdb_code                            -- TDB�R�[�h
                ,xwcu.base_code                           -- �{���S�����_
                ,xwcu.credit_limit                        -- �^�M���x�z
                ,xwcu.decide_div                          -- ����敪
                ,xwcu.approval_date                       -- ���ٓ��t
                ,xwcu.tax_div                             -- ����ŋ敪
                ,xwcu.tax_rounding_rule                   -- �ŋ��[������
                ,xwcu.invoice_grp_code                    -- ���|�R�[�h1�i�������j
                ,xwcu.output_form                         -- �������o�͌`��
                ,xwcu.prt_cycle                           -- ���������s�T�C�N��
                ,xwcu.payment_term                        -- �x������
                ,xwcu.delivery_base_code                  -- �[�i���_
                ,xwcu.bill_base_code                      -- �������_
                ,xwcu.receiv_base_code                    -- �������_
                ,xwcu.sales_head_base_code                -- �̔���{���S�����_
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
                ,xwcu.receipt_method_name                 -- �x�����@
                ,xwcu.card_company_kbn                    -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
-- Ver1.5 add start
                ,xwcu.offset_cust_code                    -- ���E�p�ڋq�R�[�h
                ,xwcu.bp_customer_code                    -- �����ڋq�R�[�h
-- Ver1.5 add end
      FROM       xxcmm_wk_cust_upload  xwcu               -- �ڋq�ꊇ�o�^���[�N
      WHERE      xwcu.request_id = cn_request_id          -- �v��ID
      ORDER BY   xwcu.line_no                             -- �t�@�C��SEQ
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    -- ������
    lv_check_flag            := cv_status_normal;
    ln_line_cnt              := 0;
    --
    <<main_loop>>
    FOR get_data_rec IN get_data_cur LOOP
      -- ������
      lv_error_flag := cv_status_normal;
      -- �s�J�E���^�A�b�v
      ln_line_cnt := ln_line_cnt + 1;
      --
      --==============================================================
      -- A-4  �f�[�^�Ó����`�F�b�N
      --==============================================================
      lv_step := 'A-4';
      validate_cust_wk(
        i_wk_cust_rec  => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
       ,ov_errbuf      => lv_errbuf                -- �G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               -- ���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      -- �������ʃ`�F�b�N
      IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-1  �ڋq�}�X�^�o�^�p���R�[�h�쐬
          --  A-5.1-2  �ڋq�}�X�^�o�^����
          --==============================================================
          lv_step := 'A-5';
          ins_cust_acct_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-3  �ڋq���ݒn�}�X�^�o�^�p���R�[�h�쐬
          --  A-5.1-4  �ڋq���ݒn�}�X�^�o�^����
          --==============================================================
          ins_location_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-5  �p�[�e�B�T�C�g�}�X�^�o�^�p���R�[�h�쐬
          --  A-5.1-6  �p�[�e�B�T�C�g�}�X�^�o�^����
          --==============================================================
          ins_party_site_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-7  �ڋq�T�C�g�}�X�^�o�^�p���R�[�h�쐬
          --  A-5.1-8  �ڋq�T�C�g�}�X�^�o�^����
          --==============================================================
          ins_cust_acct_site_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal )
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
          --AND ( gv_format = cv_file_format_mc ) THEN
          -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�������́u504:���|�Ǘ��v�̏ꍇ
          AND ( gv_format IN ( cv_file_format_mc , cv_file_format_ur ) )THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-9  �ڋq�g�p�ړI�}�X�^(������)�o�^�p���R�[�h�쐬
          --  A-5.1-10 �ڋq�g�p�ړI�}�X�^(������)�o�^����
          --==============================================================
          ins_bill_to_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal )
          AND ( gv_format = cv_file_format_mc ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-11 �ڋq�g�p�ړI�}�X�^(�o�א�)�o�^�p���R�[�h�쐬
          --  A-5.1-12 �ڋq�g�p�ړI�}�X�^(�o�א�)�o�^����
          --==============================================================
          ins_ship_to_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal )
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
          --AND ( gv_format = cv_file_format_st ) THEN
          -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�������́u503:�@�l�v�̏ꍇ
          AND ( gv_format IN ( cv_file_format_st , cv_file_format_ho )) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-13 �ڋq�g�p�ړI�}�X�^(���̑�)�o�^�p���R�[�h�쐬
          --  A-5.1-14 �ڋq�g�p�ړI�}�X�^(���̑�)�o�^����
          --==============================================================
          ins_other_to_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal )
          AND ( gv_format = cv_file_format_mc ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.1-15  �g�D�v���t�@�C���g��(�S���c�ƈ�)�o�^����
          --==============================================================
          regist_resource_no_api(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.2-1 �ڋq�ǉ����o�^����
          --==============================================================
          ins_cmm_cust_acct(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
        --
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal )
          -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
          AND ( gv_format = cv_file_format_ho ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.3-1 �ڋq�@�l���o�^����
          --==============================================================
          ins_cmm_mst_crprt(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal )
          -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
          AND ( gv_format = cv_file_format_ur ) THEN
          --==============================================================
          -- A-5  �f�[�^�o�^
          --  A-5.4-1 �ڋq�x�����@OIF�o�^����
          --==============================================================
          ins_rcpmia(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        ELSE
            lv_error_flag := lv_retcode;
        END IF;
-- Ver1.3 K.Nakamura add end
        -- �������ʃ`�F�b�N
        IF ( lv_retcode = cv_status_normal ) THEN
          -- �ڋq�o�^���ʂ����O�o�͗p�e�[�u���Ɋi�[����
          add_report(
            i_wk_cust_rec               => get_data_rec             -- �ڋq�ꊇ�o�^���[�N���
           ,io_save_cust_key_info_rec   => l_save_cust_key_info_rec -- �ޔ�KEY��񃌃R�[�h
           ,ov_errbuf                   => lv_errbuf                -- �G���[�E���b�Z�[�W
           ,ov_retcode                  => lv_retcode               -- ���^�[���E�R�[�h
           ,ov_errmsg                   => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W
          );
        END IF;
      ELSE
        -- �f�[�^�Ó����`�F�b�N�G���[�̏ꍇ
        -- �G���[�X�e�[�^�X�ޔ�
        lv_check_flag := cv_status_error;
        lv_error_flag := lv_retcode;
      END IF;
      --
      -- �������ʂ��Z�b�g
      lv_error_flag := lv_retcode;
      --
      --==============================================================
      -- �����������Z
      --==============================================================
      IF ( lv_error_flag = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt + 1;
        lv_check_flag := cv_status_error;
      END IF;
    END LOOP main_loop;
  --
  -- �Ó����A�o�^�G���[�̏ꍇ�A�G���[���Z�b�g
  IF ( lv_check_flag = cv_status_error ) THEN
    lv_retcode := cv_status_error;
  END IF;
  -- �������ʂ�����ł����COMMIT�A����ȊO�ł����ROLLBACK
  IF ( lv_retcode = cv_status_normal ) THEN
    COMMIT;
  ELSE
-- Ver1.3 K.Nakamura add start
    ov_retcode := cv_status_error;
-- Ver1.3 K.Nakamura add end
    ROLLBACK;
  END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';        -- �v���O������
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
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    --
    ln_line_cnt               NUMBER;                                 -- �s�J�E���^
    ln_item_num               NUMBER;                                 -- ���ڐ�
    ln_item_cnt               NUMBER;                                 -- ���ڐ��J�E���^
    lv_file_name              VARCHAR2(100);                          -- �t�@�C�����i�[�p
    ln_ins_item_cnt           NUMBER;                                 -- �o�^�����J�E���^
--
    l_wk_item_tab             g_check_data_ttype;                     -- �e�[�u���^�ϐ���錾(���ڕ���)
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      -- �e�[�u���^�ϐ���錾
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    get_if_data_expt          EXCEPTION;                              -- �f�[�^���ڐ��G���[��O
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    ln_ins_item_cnt := 0;
    --
    --==============================================================
    -- A-2.1 �Ώۃf�[�^�̕���(���R�[�h����)
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(          -- BLOB�f�[�^�ϊ����ʊ֐�
      in_file_id   => gn_file_id                 -- �t�@�C��ID
     ,ov_file_data => l_if_data_tab              -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    ------------------
    -- ���R�[�hLOOP
    ------------------
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..l_if_data_tab.COUNT LOOP
      ------------------
      -- �w�b�_���R�[�h
      -- 1�s�ځF�^�C�g���s
      ------------------
      IF ( ln_line_cnt > 1 ) THEN
        ------------------
        -- ���׃��R�[�h
        ------------------
        --==============================================================
        -- A-2.2 ���ڐ��̃`�F�b�N
        --==============================================================
        lv_step := 'A-2.2';
        -- �f�[�^���ڐ����i�[
        ln_item_num := ( LENGTHB(l_if_data_tab( ln_line_cnt))
                     - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '')))
                     + 1);
        -- ���ڐ�����v���Ȃ��ꍇ
        IF ( gn_item_num <> ln_item_num ) THEN
          RAISE get_if_data_expt;
        END IF;
        --
        --==============================================================
        -- A-2.3.1 �Ώۃf�[�^�̕���(���ڕ���)
        --==============================================================
        lv_step := 'A-2.3.1';
        <<get_column_loop>>
        FOR ln_item_cnt IN 1..gn_item_num LOOP
          -- �ϐ��ɍ��ڂ̒l���i�[
          l_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(  -- �f���~�^�����ϊ����ʊ֐�
                                          iv_char     => l_if_data_tab(ln_line_cnt)
                                         ,iv_delim    => cv_msg_comma
                                         ,in_part_num => ln_item_cnt
                                        );
        END LOOP get_column_loop;
        --
        --==============================================================
        -- A-2.4 �ڋq�ꊇ�o�^���[�N�֓o�^
        --==============================================================
        lv_step := 'A-2.4';
        BEGIN
          ln_ins_item_cnt := ln_ins_item_cnt + 1;
          --
          -- �t�H�[�}�b�g�p�^�[���u501:MC�ڋq�v�̏ꍇ
          IF ( gv_format = cv_file_format_mc ) THEN
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- �t�@�C��ID
             ,line_no                       -- �s�ԍ�
             ,customer_name                 -- �ڋq��
             ,customer_name_kana            -- �ڋq���J�i
             ,customer_name_ryaku           -- ����
             ,customer_class_code           -- �ڋq�敪
             ,customer_status               -- �ڋq�X�e�[�^�X
             ,sale_base_code                -- ���㋒�_
             ,sales_chain_code              -- �̔���`�F�[��
             ,delivery_chain_code           -- �[�i��`�F�[��
             ,postal_code                   -- �X�֔ԍ�
             ,state                         -- �s���{��
             ,city                          -- �s�E��
             ,address1                      -- �Z���P
             ,address2                      -- �Z���Q
             ,address3                      -- �n��R�[�h
             ,tel_no                        -- �d�b�ԍ�
             ,fax                           -- FAX
             ,business_low_type_tmp         -- �Ƒԏ�����(��)
             ,manager_name                  -- �X����
             ,emp_number                    -- �Ј���
             ,rest_emp_name                 -- �S���ҋx��
             ,mc_hot_deg                    -- MC�FHOT�x
             ,mc_importance_deg             -- MC�F�d�v�x
             ,mc_conf_info                  -- MC�F�������
             ,mc_business_talk_details      -- MC�F���k�o��
             ,resource_no                   -- �S���c�ƈ�
             ,resource_s_date               -- �K�p�J�n��(�S���c�ƈ�)
             ,business_low_type             -- �Ƒԏ�����
             ,industry_div                  -- �Ǝ�
             ,torihiki_form                 -- ����`��
             ,delivery_form                 -- �z���`��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,tdb_code                      -- TDB�R�[�h
             ,base_code                     -- �{���S�����_
             ,credit_limit                  -- �^�M���x�z
             ,decide_div                    -- ����敪
             ,approval_date                 -- ���ٓ��t
             ,tax_div                       -- ����ŋ敪
             ,tax_rounding_rule             -- �ŋ��[������
             ,invoice_grp_code              -- ���|�R�[�h1�i�������j
             ,output_form                   -- �������o�͌`��
             ,prt_cycle                     -- ���������s�T�C�N��
             ,payment_term                  -- �x������
             ,delivery_base_code            -- �[�i���_
             ,bill_base_code                -- �������_
             ,receiv_base_code              -- �������_
             ,sales_head_base_code          -- �̔���{���S�����_
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
             ,receipt_method_name           -- �x�����@
             ,card_company_kbn              -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
-- Ver1.5 add start
             ,offset_cust_code              -- ���E�p�ڋq�R�[�h
             ,bp_customer_code              -- �����ڋq�R�[�h
-- Ver1.5 add end
             ,created_by                    -- �쐬��
             ,creation_date                 -- �쐬��
             ,last_updated_by               -- �ŏI�X�V��
             ,last_update_date              -- �ŏI�X�V��
             ,last_update_login             -- �ŏI�X�V���O�C��ID
             ,request_id                    -- �v��ID
             ,program_application_id        -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
             ,program_id                    -- �R���J�����g�E�v���O����ID
             ,program_update_date           -- �v���O�����ɂ��X�V��
             ) VALUES (
              gn_file_id                    -- �t�@�C��ID
             ,ln_ins_item_cnt               -- �t�@�C��SEQ
             ,l_wk_item_tab(1)              -- �ڋq��
             ,l_wk_item_tab(2)              -- �ڋq���J�i
             ,l_wk_item_tab(3)              -- ����
             ,NULL                          -- �ڋq�敪
             ,l_wk_item_tab(4)              -- �ڋq�X�e�[�^�X
             ,l_wk_item_tab(5)              -- ���㋒�_
             ,l_wk_item_tab(6)              -- �̔���`�F�[��
             ,l_wk_item_tab(7)              -- �[�i��`�F�[��
             ,l_wk_item_tab(8)              -- �X�֔ԍ�
             ,l_wk_item_tab(9)              -- �s���{��
             ,l_wk_item_tab(10)             -- �s�E��
             ,l_wk_item_tab(11)             -- �Z���P
             ,l_wk_item_tab(12)             -- �Z���Q
             ,l_wk_item_tab(13)             -- �n��R�[�h
             ,l_wk_item_tab(14)             -- �d�b�ԍ�
             ,l_wk_item_tab(15)             -- FAX
             ,l_wk_item_tab(16)             -- �Ƒԏ�����(��)
             ,l_wk_item_tab(17)             -- �X����
             ,l_wk_item_tab(18)             -- �Ј���
             ,l_wk_item_tab(19)             -- �S���ҋx��
             ,l_wk_item_tab(20)             -- MC�FHOT�x
             ,l_wk_item_tab(21)             -- MC�F�d�v�x
             ,l_wk_item_tab(22)             -- MC�F�������
             ,l_wk_item_tab(23)             -- MC�F���k�o��
             ,l_wk_item_tab(24)             -- �S���c�ƈ�
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete start by Shigeto.Niki
--             ,l_wk_item_tab(25)             -- �K�p�J�n��(�S���c�ƈ�)
             ,gd_process_date               -- �Ɩ����t
-- 2010/11/05 Ver1.1 ��Q�FE_�{�ғ�_05492 delete end by Shigeto.Niki
             ,NULL                          -- �Ƒԏ�����
             ,NULL                          -- �Ǝ�
             ,NULL                          -- ����`��
             ,NULL                          -- �z���`��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,NULL                          -- TDB�R�[�h
             ,NULL                          -- �{���S�����_
             ,NULL                          -- �^�M���x�z
             ,NULL                          -- ����敪
             ,NULL                          -- ���ٓ��t
             ,NULL                          -- ����ŋ敪
             ,NULL                          -- �ŋ��[������
             ,NULL                          -- ���|�R�[�h1�i�������j
             ,NULL                          -- �������o�͌`��
             ,NULL                          -- ���������s�T�C�N��
             ,NULL                          -- �x������
             ,NULL                          -- �[�i���_
             ,NULL                          -- �������_
             ,NULL                          -- �������_
             ,NULL                          -- �̔���{���S�����_
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
             ,NULL                          -- �x�����@
             ,NULL                          -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
-- Ver1.5 add start
             ,l_wk_item_tab(25)             -- ���E�p�ڋq�R�[�h
             ,l_wk_item_tab(26)             -- �����ڋq�R�[�h
-- Ver1.5 add end
             ,cn_created_by                 -- �쐬��
             ,cd_creation_date              -- �쐬��
             ,cn_last_updated_by            -- �ŏI�X�V��
             ,cd_last_update_date           -- �ŏI�X�V��
             ,cn_last_update_login          -- �ŏI�X�V���O�C��ID
             ,cn_request_id                 -- �v��ID
             ,cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                 -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date        -- �v���O�����ɂ��X�V��
            );
          -- �t�H�[�}�b�g�p�^�[���u502:�X�܉c�Ɓv�̏ꍇ
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod start
          --ELSE
          ELSIF  ( gv_format = cv_file_format_st ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama mod end
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- �t�@�C��ID
             ,line_no                       -- �s�ԍ�
             ,customer_name                 -- �ڋq��
             ,customer_name_kana            -- �ڋq���J�i
             ,customer_name_ryaku           -- ����
             ,customer_class_code           -- �ڋq�敪
             ,customer_status               -- �ڋq�X�e�[�^�X
             ,sale_base_code                -- ���㋒�_
             ,sales_chain_code              -- �̔���`�F�[��
             ,delivery_chain_code           -- �[�i��`�F�[��
             ,postal_code                   -- �X�֔ԍ�
             ,state                         -- �s���{��
             ,city                          -- �s�E��
             ,address1                      -- �Z���P
             ,address2                      -- �Z���Q
             ,address3                      -- �n��R�[�h
             ,tel_no                        -- �d�b�ԍ�
             ,fax                           -- FAX
             ,business_low_type_tmp         -- �Ƒԏ�����(��)
             ,manager_name                  -- �X����
             ,emp_number                    -- �Ј���
             ,rest_emp_name                 -- �S���ҋx��
             ,mc_hot_deg                    -- MC�FHOT�x
             ,mc_importance_deg             -- MC�F�d�v�x
             ,mc_conf_info                  -- MC�F�������
             ,mc_business_talk_details      -- MC�F���k�o��
             ,resource_no                   -- �S���c�ƈ�
             ,resource_s_date               -- �K�p�J�n��(�S���c�ƈ�)
             ,business_low_type             -- �Ƒԏ�����
             ,industry_div                  -- �Ǝ�
             ,torihiki_form                 -- ����`��
             ,delivery_form                 -- �z���`��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,tdb_code                      -- TDB�R�[�h
             ,base_code                     -- �{���S�����_
             ,credit_limit                  -- �^�M���x�z
             ,decide_div                    -- ����敪
             ,approval_date                 -- ���ٓ��t
             ,tax_div                       -- ����ŋ敪
             ,tax_rounding_rule             -- �ŋ��[������
             ,invoice_grp_code              -- ���|�R�[�h1�i�������j
             ,output_form                   -- �������o�͌`��
             ,prt_cycle                     -- ���������s�T�C�N��
             ,payment_term                  -- �x������
             ,delivery_base_code            -- �[�i���_
             ,bill_base_code                -- �������_
             ,receiv_base_code              -- �������_
             ,sales_head_base_code          -- �̔���{���S�����_
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
             ,receipt_method_name           -- �x�����@
             ,card_company_kbn              -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
             ,created_by                    -- �쐬��
             ,creation_date                 -- �쐬��
             ,last_updated_by               -- �ŏI�X�V��
             ,last_update_date              -- �ŏI�X�V��
             ,last_update_login             -- �ŏI�X�V���O�C��ID
             ,request_id                    -- �v��ID
             ,program_application_id        -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
             ,program_id                    -- �R���J�����g�E�v���O����ID
             ,program_update_date           -- �v���O�����ɂ��X�V��
             ) VALUES (
              gn_file_id                    -- �t�@�C��ID
             ,ln_ins_item_cnt               -- �t�@�C��SEQ
             ,l_wk_item_tab(1)              -- �ڋq��
             ,l_wk_item_tab(2)              -- �ڋq���J�i
             ,l_wk_item_tab(3)              -- ����
             ,l_wk_item_tab(4)              -- �ڋq�敪
             ,l_wk_item_tab(5)              -- �ڋq�X�e�[�^�X
             ,l_wk_item_tab(6)              -- ���㋒�_
             ,l_wk_item_tab(7)              -- �̔���`�F�[��
             ,l_wk_item_tab(8)              -- �[�i��`�F�[��
             ,l_wk_item_tab(9)              -- �X�֔ԍ�
             ,l_wk_item_tab(10)             -- �s���{��
             ,l_wk_item_tab(11)             -- �s�E��
             ,l_wk_item_tab(12)             -- �Z���P
             ,l_wk_item_tab(13)             -- �Z���Q
             ,l_wk_item_tab(14)             -- �n��R�[�h
             ,l_wk_item_tab(15)             -- �d�b�ԍ�
             ,l_wk_item_tab(16)             -- FAX
             ,NULL                          -- �Ƒԏ�����(��)
             ,NULL                          -- �X����
             ,NULL                          -- �Ј���
             ,NULL                          -- �S���ҋx��
             ,NULL                          -- MC�FHOT�x
             ,NULL                          -- MC�F�d�v�x
             ,NULL                          -- MC�F�������
             ,NULL                          -- MC�F���k�o��
             ,NULL                          -- �S���c�ƈ�
             ,NULL                          -- �K�p�J�n��(�S���c�ƈ�)
             ,l_wk_item_tab(17)             -- �Ƒԏ�����
             ,l_wk_item_tab(18)             -- �Ǝ�
             ,l_wk_item_tab(19)             -- ����`��
             ,l_wk_item_tab(20)             -- �z���`��
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
             ,NULL                          -- TDB�R�[�h
             ,NULL                          -- �{���S�����_
             ,NULL                          -- �^�M���x�z
             ,NULL                          -- ����敪
             ,NULL                          -- ���ٓ��t
             ,NULL                          -- ����ŋ敪
             ,NULL                          -- �ŋ��[������
             ,NULL                          -- ���|�R�[�h1�i�������j
             ,NULL                          -- �������o�͌`��
             ,NULL                          -- ���������s�T�C�N��
             ,NULL                          -- �x������
             ,NULL                          -- �[�i���_
             ,NULL                          -- �������_
             ,NULL                          -- �������_
             ,NULL                          -- �̔���{���S�����_
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
-- Ver1.3 K.Nakamura add start
             ,NULL                          -- �x�����@
             ,NULL                          -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
             ,cn_created_by                 -- �쐬��
             ,cd_creation_date              -- �쐬��
             ,cn_last_updated_by            -- �ŏI�X�V��
             ,cd_last_update_date           -- �ŏI�X�V��
             ,cn_last_update_login          -- �ŏI�X�V���O�C��ID
             ,cn_request_id                 -- �v��ID
             ,cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                 -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date        -- �v���O�����ɂ��X�V��
            );
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
          -- �t�H�[�}�b�g�p�^�[���u503:�@�l�v�̏ꍇ
          ELSIF  ( gv_format = cv_file_format_ho ) THEN
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- �t�@�C��ID
             ,line_no                       -- �s�ԍ�
             ,customer_name                 -- �ڋq��
             ,customer_name_kana            -- �ڋq���J�i
             ,customer_name_ryaku           -- ����
             ,customer_class_code           -- �ڋq�敪
             ,customer_status               -- �ڋq�X�e�[�^�X
             ,sale_base_code                -- ���㋒�_
             ,sales_chain_code              -- �̔���`�F�[��
             ,delivery_chain_code           -- �[�i��`�F�[��
             ,postal_code                   -- �X�֔ԍ�
             ,state                         -- �s���{��
             ,city                          -- �s�E��
             ,address1                      -- �Z���P
             ,address2                      -- �Z���Q
             ,address3                      -- �n��R�[�h
             ,tel_no                        -- �d�b�ԍ�
             ,fax                           -- FAX
             ,business_low_type_tmp         -- �Ƒԏ�����(��)
             ,manager_name                  -- �X����
             ,emp_number                    -- �Ј���
             ,rest_emp_name                 -- �S���ҋx��
             ,mc_hot_deg                    -- MC�FHOT�x
             ,mc_importance_deg             -- MC�F�d�v�x
             ,mc_conf_info                  -- MC�F�������
             ,mc_business_talk_details      -- MC�F���k�o��
             ,resource_no                   -- �S���c�ƈ�
             ,resource_s_date               -- �K�p�J�n��(�S���c�ƈ�)
             ,business_low_type             -- �Ƒԏ�����
             ,industry_div                  -- �Ǝ�
             ,torihiki_form                 -- ����`��
             ,delivery_form                 -- �z���`��
             ,tdb_code                      -- TDB�R�[�h
             ,base_code                     -- �{���S�����_
             ,credit_limit                  -- �^�M���x�z
             ,decide_div                    -- ����敪
             ,approval_date                 -- ���ٓ��t
             ,tax_div                       -- ����ŋ敪
             ,tax_rounding_rule             -- �ŋ��[������
             ,invoice_grp_code              -- ���|�R�[�h1�i�������j
             ,output_form                   -- �������o�͌`��
             ,prt_cycle                     -- ���������s�T�C�N��
             ,payment_term                  -- �x������
             ,delivery_base_code            -- �[�i���_
             ,bill_base_code                -- �������_
             ,receiv_base_code              -- �������_
             ,sales_head_base_code          -- �̔���{���S�����_
-- Ver1.3 K.Nakamura add start
             ,receipt_method_name           -- �x�����@
             ,card_company_kbn              -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
             ,created_by                    -- �쐬��
             ,creation_date                 -- �쐬��
             ,last_updated_by               -- �ŏI�X�V��
             ,last_update_date              -- �ŏI�X�V��
             ,last_update_login             -- �ŏI�X�V���O�C��ID
             ,request_id                    -- �v��ID
             ,program_application_id        -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
             ,program_id                    -- �R���J�����g�E�v���O����ID
             ,program_update_date           -- �v���O�����ɂ��X�V��
             ) VALUES (
              gn_file_id                    -- �t�@�C��ID
             ,ln_ins_item_cnt               -- �t�@�C��SEQ
             ,l_wk_item_tab(1)              -- �ڋq��
             ,l_wk_item_tab(2)              -- �ڋq���J�i
             ,l_wk_item_tab(3)              -- ����
             ,l_wk_item_tab(4)              -- �ڋq�敪
             ,l_wk_item_tab(5)              -- �ڋq�X�e�[�^�X
             ,l_wk_item_tab(6)              -- ���㋒�_
             ,NULL                          -- �̔���`�F�[��
             ,NULL                          -- �[�i��`�F�[��
             ,l_wk_item_tab(7)              -- �X�֔ԍ�
             ,l_wk_item_tab(8)              -- �s���{��
             ,l_wk_item_tab(9)              -- �s�E��
             ,l_wk_item_tab(10)             -- �Z���P
             ,l_wk_item_tab(11)             -- �Z���Q
             ,l_wk_item_tab(12)             -- �n��R�[�h
             ,l_wk_item_tab(13)             -- �d�b�ԍ�
             ,l_wk_item_tab(14)             -- FAX
             ,NULL                          -- �Ƒԏ�����(��)
             ,NULL                          -- �X����
             ,NULL                          -- �Ј���
             ,NULL                          -- �S���ҋx��
             ,NULL                          -- MC�FHOT�x
             ,NULL                          -- MC�F�d�v�x
             ,NULL                          -- MC�F�������
             ,NULL                          -- MC�F���k�o��
             ,NULL                          -- �S���c�ƈ�
             ,NULL                          -- �K�p�J�n��(�S���c�ƈ�)
             ,NULL                          -- �Ƒԏ�����
             ,NULL                          -- �Ǝ�
             ,NULL                          -- ����`��
             ,NULL                          -- �z���`��
             ,l_wk_item_tab(15)             -- TDB�R�[�h
             ,l_wk_item_tab(16)             -- �{���S�����_
             ,l_wk_item_tab(17)             -- �^�M���x�z
             ,l_wk_item_tab(18)             -- ����敪
             ,l_wk_item_tab(19)             -- ���ٓ��t
             ,NULL                          -- ����ŋ敪
             ,NULL                          -- �ŋ��[������
             ,NULL                          -- ���|�R�[�h1�i�������j
             ,NULL                          -- �������o�͌`��
             ,NULL                          -- ���������s�T�C�N��
             ,NULL                          -- �x������
             ,NULL                          -- �[�i���_
             ,NULL                          -- �������_
             ,NULL                          -- �������_
             ,NULL                          -- �̔���{���S�����_
-- Ver1.3 K.Nakamura add start
             ,NULL                          -- �x�����@
             ,NULL                          -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
             ,cn_created_by                 -- �쐬��
             ,cd_creation_date              -- �쐬��
             ,cn_last_updated_by            -- �ŏI�X�V��
             ,cd_last_update_date           -- �ŏI�X�V��
             ,cn_last_update_login          -- �ŏI�X�V���O�C��ID
             ,cn_request_id                 -- �v��ID
             ,cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                 -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date        -- �v���O�����ɂ��X�V��
            );
          -- �t�H�[�}�b�g�p�^�[���u504:���|�Ǘ��v�̏ꍇ
          ELSIF  ( gv_format = cv_file_format_ur ) THEN
            INSERT INTO xxcmm_wk_cust_upload(
              file_id                       -- �t�@�C��ID
             ,line_no                       -- �s�ԍ�
             ,customer_name                 -- �ڋq��
             ,customer_name_kana            -- �ڋq���J�i
             ,customer_name_ryaku           -- ����
             ,customer_class_code           -- �ڋq�敪
             ,customer_status               -- �ڋq�X�e�[�^�X
             ,sale_base_code                -- ���㋒�_
             ,sales_chain_code              -- �̔���`�F�[��
             ,delivery_chain_code           -- �[�i��`�F�[��
             ,postal_code                   -- �X�֔ԍ�
             ,state                         -- �s���{��
             ,city                          -- �s�E��
             ,address1                      -- �Z���P
             ,address2                      -- �Z���Q
             ,address3                      -- �n��R�[�h
             ,tel_no                        -- �d�b�ԍ�
             ,fax                           -- FAX
             ,business_low_type_tmp         -- �Ƒԏ�����(��)
             ,manager_name                  -- �X����
             ,emp_number                    -- �Ј���
             ,rest_emp_name                 -- �S���ҋx��
             ,mc_hot_deg                    -- MC�FHOT�x
             ,mc_importance_deg             -- MC�F�d�v�x
             ,mc_conf_info                  -- MC�F�������
             ,mc_business_talk_details      -- MC�F���k�o��
             ,resource_no                   -- �S���c�ƈ�
             ,resource_s_date               -- �K�p�J�n��(�S���c�ƈ�)
-- Ver1.3 K.Nakamura add start
             ,receipt_method_name           -- �x�����@
-- Ver1.3 K.Nakamura add end
             ,business_low_type             -- �Ƒԏ�����
             ,industry_div                  -- �Ǝ�
             ,torihiki_form                 -- ����`��
             ,delivery_form                 -- �z���`��
             ,tdb_code                      -- TDB�R�[�h
             ,base_code                     -- �{���S�����_
             ,credit_limit                  -- �^�M���x�z
             ,decide_div                    -- ����敪
             ,approval_date                 -- ���ٓ��t
             ,tax_div                       -- ����ŋ敪
             ,tax_rounding_rule             -- �ŋ��[������
             ,invoice_grp_code              -- ���|�R�[�h1�i�������j
             ,output_form                   -- �������o�͌`��
             ,prt_cycle                     -- ���������s�T�C�N��
             ,payment_term                  -- �x������
             ,delivery_base_code            -- �[�i���_
             ,bill_base_code                -- �������_
             ,receiv_base_code              -- �������_
             ,sales_head_base_code          -- �̔���{���S�����_
-- Ver1.3 K.Nakamura add start
             ,card_company_kbn              -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
             ,created_by                    -- �쐬��
             ,creation_date                 -- �쐬��
             ,last_updated_by               -- �ŏI�X�V��
             ,last_update_date              -- �ŏI�X�V��
             ,last_update_login             -- �ŏI�X�V���O�C��ID
             ,request_id                    -- �v��ID
             ,program_application_id        -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
             ,program_id                    -- �R���J�����g�E�v���O����ID
             ,program_update_date           -- �v���O�����ɂ��X�V��
             ) VALUES (
              gn_file_id                    -- �t�@�C��ID
             ,ln_ins_item_cnt               -- �t�@�C��SEQ
             ,l_wk_item_tab(1)              -- �ڋq��
             ,l_wk_item_tab(2)              -- �ڋq���J�i
             ,l_wk_item_tab(3)              -- ����
             ,l_wk_item_tab(4)              -- �ڋq�敪
             ,l_wk_item_tab(5)              -- �ڋq�X�e�[�^�X
             ,l_wk_item_tab(6)              -- ���㋒�_
             ,l_wk_item_tab(7)              -- �̔���`�F�[��
             ,l_wk_item_tab(8)              -- �[�i��`�F�[��
             ,l_wk_item_tab(9)              -- �X�֔ԍ�
             ,l_wk_item_tab(10)             -- �s���{��
             ,l_wk_item_tab(11)             -- �s�E��
             ,l_wk_item_tab(12)             -- �Z���P
             ,l_wk_item_tab(13)             -- �Z���Q
             ,l_wk_item_tab(14)             -- �n��R�[�h
             ,l_wk_item_tab(15)             -- �d�b�ԍ�
             ,l_wk_item_tab(16)             -- FAX
             ,NULL                          -- �Ƒԏ�����(��)
             ,NULL                          -- �X����
             ,NULL                          -- �Ј���
             ,NULL                          -- �S���ҋx��
             ,NULL                          -- MC�FHOT�x
             ,NULL                          -- MC�F�d�v�x
             ,NULL                          -- MC�F�������
             ,NULL                          -- MC�F���k�o��
             ,NULL                          -- �S���c�ƈ�
             ,NULL                          -- �K�p�J�n��(�S���c�ƈ�)
-- Ver1.3 K.Nakamura add start
             ,l_wk_item_tab(17)             -- �x�����@
-- Ver1.3 K.Nakamura add end
-- Ver1.3 K.Nakamura mod start
--             ,l_wk_item_tab(17)             -- �Ƒԏ�����
--             ,l_wk_item_tab(18)             -- �Ǝ�
             ,l_wk_item_tab(18)             -- �Ƒԏ�����
             ,l_wk_item_tab(19)             -- �Ǝ�
-- Ver1.3 K.Nakamura mod end
             ,NULL                          -- ����`��
             ,NULL                          -- �z���`��
             ,NULL                          -- TDB�R�[�h
             ,NULL                          -- �{���S�����_
             ,NULL                          -- �^�M���x�z
             ,NULL                          -- ����敪
             ,NULL                          -- ���ٓ��t
-- Ver1.3 K.Nakamura mod start
--             ,l_wk_item_tab(19)             -- ����ŋ敪
--             ,l_wk_item_tab(20)             -- �ŋ��[������
--             ,l_wk_item_tab(21)             -- ���|�R�[�h1�i�������j
--             ,l_wk_item_tab(22)             -- �������o�͌`��
--             ,l_wk_item_tab(23)             -- ���������s�T�C�N��
--             ,l_wk_item_tab(24)             -- �x������
--             ,l_wk_item_tab(25)             -- �[�i���_
--             ,l_wk_item_tab(26)             -- �������_
--             ,l_wk_item_tab(27)             -- �������_
--             ,l_wk_item_tab(28)             -- �̔���{���S�����_
             ,l_wk_item_tab(20)             -- ����ŋ敪
             ,l_wk_item_tab(21)             -- �ŋ��[������
             ,l_wk_item_tab(22)             -- ���|�R�[�h1�i�������j
             ,l_wk_item_tab(23)             -- �������o�͌`��
             ,l_wk_item_tab(24)             -- ���������s�T�C�N��
             ,l_wk_item_tab(25)             -- �x������
             ,l_wk_item_tab(26)             -- �[�i���_
             ,l_wk_item_tab(27)             -- �������_
             ,l_wk_item_tab(28)             -- �������_
             ,l_wk_item_tab(29)             -- �̔���{���S�����_
-- Ver1.3 K.Nakamura mod end
-- Ver1.3 K.Nakamura add start
             ,l_wk_item_tab(30)             -- �J�[�h��Ћ敪
-- Ver1.3 K.Nakamura add end
             ,cn_created_by                 -- �쐬��
             ,cd_creation_date              -- �쐬��
             ,cn_last_updated_by            -- �ŏI�X�V��
             ,cd_last_update_date           -- �ŏI�X�V��
             ,cn_last_update_login          -- �ŏI�X�V���O�C��ID
             ,cn_request_id                 -- �v��ID
             ,cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id                 -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date        -- �v���O�����ɂ��X�V��
            );
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
          END IF;
        EXCEPTION
          -- *** �f�[�^�o�^��O�n���h�� ***
          WHEN OTHERS THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcmm       -- �A�v���P�[�V�����Z�k��
                           ,iv_name         => cv_msg_xxcmm_10335       -- ���b�Z�[�W�R�[�h
                           ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                           ,iv_token_value1 => cv_table_xwcu            -- �g�[�N���l1
                           ,iv_token_name2  => cv_tkn_input_line_no     -- �g�[�N���R�[�h2
                           ,iv_token_value2 => ln_ins_item_cnt          -- �g�[�N���l2
                           ,iv_token_name3  => cv_tkn_errmsg            -- �g�[�N���R�[�h4
                           ,iv_token_value3 => SQLERRM                  -- �g�[�N���l4
                          );
            lv_errbuf  := lv_errmsg;
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.LOG
             ,buff   => lv_errbuf --�G���[���b�Z�[�W
            );
            -- �G���[�����J�E���g�A�b�v
            gn_error_cnt := gn_error_cnt + 1;
        END;
        --
      END IF;
      --
    END LOOP ins_wk_loop;
    --
    -- �����Ώی������i�[(�w�b�_����������)
    gn_target_cnt := l_if_data_tab.COUNT - 1 ;
    --
  EXCEPTION
    -- *** �f�[�^���ڐ��G���[��O�n���h�� ***
    WHEN get_if_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_xxcmm_00028            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_cust_upload                -- �g�[�N���l1
                    ,iv_token_name2  => cv_tkn_count                  -- �g�[�N���R�[�h2
                    ,iv_token_value2 => ln_item_num                   -- �g�[�N���l2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : �I������ (A-6)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- �v���O������
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
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    lv_check_status           VARCHAR2(1);                            -- �`�F�b�N�X�e�[�^�X
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
--
  BEGIN
    --
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    -- �`�F�b�N�X�e�[�^�X�̏�����
    lv_check_status := cv_status_normal;
    --
    ov_retcode := cv_status_normal;
    --
--###########################  �Œ蕔 END   ############################
    --
    --==============================================================
    -- A-6.1 �ڋq�ꊇ�o�^�f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-6.1';
      DELETE FROM xxcmm_wk_cust_upload
      ;
      -- COMMIT���s
      COMMIT;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- �f�[�^�폜�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00012          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_xwcu               -- �g�[�N���l1
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
    --
    --==============================================================
    -- A-6.2 �t�@�C���A�b�v���[�hIF�e�[�u���f�[�^�폜
    --==============================================================
    BEGIN
      lv_step := 'A-6.2';
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      -- COMMIT���s
      COMMIT;
      --
    EXCEPTION
      -- *** �f�[�^�폜��O�n���h�� ***
      WHEN OTHERS THEN
        ov_retcode := cv_status_error;
        -- �f�[�^�폜�G���[
        gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- �A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_xxcmm_00012          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_table                -- �g�[�N���R�[�h1
                      ,iv_token_value1 => cv_table_file_ul_if         -- �g�[�N���l1
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg);
    END;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id    IN  VARCHAR2          -- �t�@�C��ID
   ,iv_format     IN  VARCHAR2          -- �t�H�[�}�b�g
   ,ov_errbuf     OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_step                   VARCHAR2(10);                           -- �X�e�b�v
    --
    ln_loop_cnt               NUMBER;                                 -- ���[�v�J�E���^�[
    --
    ln_target_cnt             NUMBER;                                 -- �Ώی���
    ln_insert_cnt             NUMBER;                                 -- INSERT����
    ln_update_cnt             NUMBER;                                 -- UPDATE����
    ln_warn_cnt               NUMBER;                                 -- �X�L�b�v����
--
    -- *** ���[�J���E�J�[�\�� ***
    l_save_cust_key_info_rec    save_cust_key_info_rtype;                                -- �ޔ�KEY��񃌃R�[�h
    l_cust_account_rec          hz_cust_account_v2pub.cust_account_rec_type;
    l_organization_rec          hz_party_v2pub.organization_rec_type;
    l_customer_profile_rec      hz_customer_profile_v2pub.customer_profile_rec_type;
    l_cmm_cust_acct_rec         xxcmm_cust_accounts%ROWTYPE;                             -- �ڋq�ǉ���񃌃R�[�h
    l_location_rec              hz_location_v2pub.location_rec_type;
    l_cust_site_use_rec         hz_cust_account_site_v2pub.cust_site_use_rec_type;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J�����[�U�[��`��O ***
    sub_proc_expt             EXCEPTION;                              -- �T�u�v���O�����G���[
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
    gn_insert_cnt := 0;
    gn_update_cnt := 0;
    --
    gn_normal_cnt := 0;
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
    --
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    --==============================================================
    -- A-1.  ��������
    --==============================================================
    lv_step := 'A-1';
    init(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      gn_error_cnt := 1;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  �t�@�C���A�b�v���[�hIF�f�[�^�擾
    --==============================================================
    lv_step := 'A-2';
    get_if_data(                        -- get_if_data���R�[��
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      gn_error_cnt := 1;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- A-3  �ڋq�ꊇ�o�^���[�N�f�[�^�擾
    --  A-4  �ڋq�ꊇ�o�^���[�N�e�[�u���f�[�^�Ó����`�F�b�N
    --  A-5  �ڋq�ꊇ�o�^����
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
-- Ver1.3 K.Nakamura add start
    -- loop_main�̃��^�[���R�[�h��ޔ�
    gv_loop_main_retcode := lv_retcode;
-- Ver1.3 K.Nakamura add end
    --
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
--
-- Ver1.3 K.Nakamura add start
    --
    -- �ڋq�x�����@OIF��1���ȏ�o�^�����ꍇ
    IF ( gn_rcpmia_cnt > 0 ) THEN
      --==============================================================
      -- A-7  �ڋq�C���^�[�t�F�[�X���s����
      --==============================================================
      lv_step := 'A-7';
      submit_request_racust(
        ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
       ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
       ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
      --
      -- �������ʃ`�F�b�N
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE sub_proc_expt;
      END IF;
    END IF;
-- Ver1.3 K.Nakamura add end
--
    --==============================================================
    -- A-6  �I������
    --==============================================================
    lv_step := 'A-6';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    -- �������ʃ`�F�b�N
    IF ( lv_retcode <> cv_status_normal ) THEN
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add start
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
-- 2012/12/14 Ver1.2 SCSK K.Furuyama add end
      RAISE sub_proc_expt;
    END IF;
    --
    -- �G���[������΃��^�[���E�R�[�h���G���[�A���팏����0���ŕԂ��܂�
    IF ( gn_error_cnt > 0 ) THEN
      gn_normal_cnt := 0;
      ov_retcode    := cv_status_error;
    END IF;
    --
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT    VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h        --# �Œ� #
   ,iv_file_id    IN     VARCHAR2       --   �t�@�C��ID
   ,iv_format     IN     VARCHAR2       --   �t�H�[�}�b�g
  )
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_target_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    --
    cv_cnt_token               CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                 VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code            VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
    lv_submain_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
  BEGIN
--
--###########################  �Œ蕔 END   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_log
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    -- ���b�Z�[�W(OUTPUT)�o��
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_file_id => iv_file_id          -- �t�@�C��ID
     ,iv_format  => iv_format           -- �t�H�[�}�b�g
     ,ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- submain�̃��^�[���R�[�h��ޔ�
    lv_submain_retcode := lv_retcode;
    --
    --�G���[�o��
    IF ( lv_submain_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --
-- Ver1.3 K.Nakamura mod start
--    --Submain�̃��^�[���R�[�h������ł���Όڋq�o�^���ʂ��o��
--    IF ( lv_submain_retcode = cv_status_normal ) THEN
    --loop_main�̃��^�[���R�[�h������ł���Όڋq�o�^���ʂ��o��
    IF ( gv_loop_main_retcode = cv_status_normal ) THEN
-- Ver1.3 K.Nakamura mod end
        disp_report(
          lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
    END IF;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_submain_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_submain_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_submain_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_submain_retcode;
    --�I���X�e�[�^�X������ȊO�̏ꍇ��ROLLBACK
    IF ( retcode <> cv_status_normal ) THEN
      ROLLBACK;
    ELSE
      -- COMMIT���s
      COMMIT;
    END IF;
    --
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCMM003A40C;
/
