CREATE OR REPLACE PACKAGE BODY XXCFO019A03C  
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A03C(body)
 * Description      : �d�q����̔����т̏��n�V�X�e���A�g
 * MD.050           : �d�q����̔����т̏��n�V�X�e���A�g <MD050_CFO_019_A03>
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_sales_exp_wait     ���A�g�f�[�^�擾����(A-2)
 *  get_sales_exp_control  �Ǘ��e�[�u���f�[�^�擾����(A-3)
 *  get_flex_information   �t�����擾����(A-5)
 *  chk_item               ���ڃ`�F�b�N����(A-6)
 *  out_csv                �b�r�u�o�͏���(A-7)
 *  out_sales_exp_wait     ���A�g�e�[�u���o�^����(A-8)
 *  get_sales_exp          �Ώۃf�[�^���o(A-4)
 *  upd_sales_exp_control  �Ǘ��e�[�u���o�^�E�X�V����(A-9)
 *  del_sales_exp_control  ���A�g�e�[�u���폜����(A-10)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/27    1.0   T.Osawa          �V�K�쐬
 *  2012/10/31    1.1   N.Sugiura        [�����e�X�g��QNo29] �G���[���e���o�̓t�@�C���ɏo�͂���
 *  2012/11/28    1.2   T.Osawa          �Ǘ��e�[�u���X�V�A�`�q����擾�G���[
 *  2012/12/18    1.3   T.Ishiwata       ���\���P�Ή�
 *  2013/08/06    1.4   S.Niki           E_�{�ғ�_10960�Ή�(����ő��őΉ�)
 *  2014/01/29    1.5   S.Niki           E_�{�ғ�_11449�Ή� ����ŋ敪���̂̎擾������[�i���˃I���W�i���[�i���ɕύX
 *  2015/08/21    1.6   Y.Shoji          E_�{�ғ�_13255�Ή�(��ԃo�b�`�x��_�d�q����̔����т̏��n�V�X�e���A�g)
 *  2016/10/21    1.7   K.Kiriu          E_�{�ғ�_13879�Ή�(VD�Ɩ��ϑ��Ή�)
 *  2019/07/16    1.8   N.Abe            E_�{�ғ�_15472�Ή�(�y���ŗ��Ή�)
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
  gn_warn_cnt               NUMBER;                    -- �X�L�b�v����
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
  -- *** ���b�N�G���[�n���h�� ***
  global_lock_fail          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                           CONSTANT VARCHAR2(100) := 'XXCFO019A03C';         -- �p�b�P�[�W��
  --�v���t�@�C��
  cv_data_filepath                      CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- �d�q����̔����уf�[�^�t�@�C���i�[�p�X
  cv_add_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_SALES_EXP_I_FILENAME';  -- �d�q����̔����ђǉ��t�@�C����
  cv_upd_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_SALES_EXP_U_FILENAME';  -- �d�q����̔����эX�V�t�@�C����
  cv_organization_code                  CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';                   -- �݌ɑg�DID
  cv_org_id                             CONSTANT VARCHAR2(100) := 'ORG_ID';                                     -- �c�ƒP��
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
  cv_sales_exp_upper_limit              CONSTANT VARCHAR2(100) := 'XXCFO1_SALES_EXP_UPPER_LIMIT';               -- �̔����уf�[�^_����l
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
  -- ���b�Z�[�W
  cv_msg_cff_00165                      CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00165';   --�擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_cfo_00001                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --�v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00002                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_cfo_00015                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --�Ɩ����t�擾�G���[
  cv_msg_cfo_00019                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --���b�N�G���[���b�Z�[�W
  cv_msg_cfo_00020                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00020';   --�X�V�G���[���b�Z�[�W
  cv_msg_cfo_00024                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00024';   --�o�^�G���[���b�Z�[�W
  cv_msg_cfo_00025                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00025';   --�폜�G���[���b�Z�[�W
  cv_msg_cfo_00027                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00027';   --����t�@�C�����݃G���[���b�Z�[�W
  cv_msg_cfo_00029                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00029';   --�t�@�C���I�[�v���G���[���b�Z�[�W
  cv_msg_cfo_00030                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00030';   --�t�@�C���������݃G���[���b�Z�[�W
  cv_msg_cfo_00031                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00031';   --�N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_cfo_10001                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10001';   --�Ώی����i�A�g���j���b�Z�[�W
  cv_msg_cfo_10002                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10002';   --�Ώی����i�������A�g���j���b�Z�[�W
  cv_msg_cfo_10003                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10003';   --���A�g�������b�Z�[�W
  cv_msg_cfo_10006                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10006';   --�͈͎w��G���[���b�Z�[�W
  cv_msg_cfo_10007                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --���A�g�f�[�^�o�^���b�Z�[�W
  cv_msg_cfo_10008                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10008';   --�p�����[�^ID���͕s�����b�Z�[�W
  cv_msg_cfo_10010                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --���A�g�f�[�^�`�F�b�NID�G���[���b�Z�[�W
  cv_msg_cfo_10011                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --�������߃X�L�b�v���b�Z�[�W
  cv_msg_cfo_10012                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10012';   --�c�ƃV�X�e���ғ��J�n�O�X�L�b�v���b�Z�[�W
  cv_msg_cfo_11008                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   --���ڂ��s��
  cv_msg_cfo_11012                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11012';   --�̔����і��A�g�e�[�u��
  cv_msg_cfo_11013                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11013';   --�̔����ъǗ��e�[�u��
  cv_msg_cfo_11014                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11014';   --AR�C���^�[�t�F�[�X�t���O�ΏۊO
  cv_msg_cfo_11015                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11015';   --GL���^�[�t�F�[�X�t���O�ΏۊO
  cv_msg_cfo_11016                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11016';   --INV�C���^�[�t�F�[�X�t���O�ΏۊO
  cv_msg_cfo_11038                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11038';   --�C���^�[�t�F�[�X�ΏۊO
  cv_msg_cfo_11042                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11042';   --AR������擾�G���[
  cv_msg_cfo_11043                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11043';   --INV����^�C�v�擾�G���[
  cv_msg_cfr_00002                      CONSTANT VARCHAR2(500) := 'APP-XXCFR1-00002';   --�p�����[�^�o�̓��b�Z�[�W
  cv_msg_coi_00006                      CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00006';   --�݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_coi_00029                      CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_msg_cos_00013                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00013';   --�f�[�^���o�G���[���b�Z�[�W
  cv_msg_cos_00066                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00066';   --�N�C�b�N�R�[�h�}�X�^
  cv_msg_cos_00086                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00086';   --�̔����уw�b�_
  cv_msg_cos_00087                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00087';   --�̔����і���
  cv_msg_cos_10702                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-10702';   --�̔����і���ID
  cv_msg_cos_10706                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-10706';   --�̔����уw�b�_ID
  cv_msg_cos_13303                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-13303';   --�̔�����
  cv_msg_cos_13304                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-13304';   --AR������
  --  
  --�g�[�N��
  cv_token_param_name                   CONSTANT VARCHAR2(10)  := 'PARAM_NAME';         --�g�[�N����(PARAM_NAME)
  cv_token_param_val                    CONSTANT VARCHAR2(10)  := 'PARAM_VAL';          --�g�[�N����(PARAM_VAL)
  cv_token_lookup_type                  CONSTANT VARCHAR2(15)  := 'LOOKUP_TYPE';        --�g�[�N����(LOOKUP_TYPE)
  cv_token_lookup_code                  CONSTANT VARCHAR2(15)  := 'LOOKUP_CODE';        --�g�[�N����(LOOKUP_CODE)
  cv_token_prof_name                    CONSTANT VARCHAR2(10)  := 'PROF_NAME';          --�g�[�N����(PROF_NAME)
  cv_token_dir_tok                      CONSTANT VARCHAR2(10)  := 'DIR_TOK';            --�g�[�N����(DIR_TOK)
  cv_token_file_name                    CONSTANT VARCHAR2(10)  := 'FILE_NAME';          --�g�[�N����(FILE_NAME)
  cv_token_errmsg                       CONSTANT VARCHAR2(10)  := 'ERRMSG';             --�g�[�N����(ERRMSG)
  cv_token_max_id                       CONSTANT VARCHAR2(10)  := 'MAX_ID';             --�g�[�N����(MAX_ID)
  cv_token_param1                       CONSTANT VARCHAR2(10)  := 'PARAM1';             --�g�[�N����(PARAM1)
  cv_token_param2                       CONSTANT VARCHAR2(10)  := 'PARAM2';             --�g�[�N����(PARAM2)
  cv_token_doc_data                     CONSTANT VARCHAR2(10)  := 'DOC_DATA';           --�g�[�N����(DOC_DATA)
  cv_token_doc_dist_id                  CONSTANT VARCHAR2(15)  := 'DOC_DIST_ID';        --�g�[�N����(DOC_DIST_ID)
  cv_token_get_data                     CONSTANT VARCHAR2(10)  := 'GET_DATA';           --�g�[�N����(GET_DATA)
  cv_token_table                        CONSTANT VARCHAR2(10)  := 'TABLE';              --�g�[�N����(TABLE)
  cv_token_cause                        CONSTANT VARCHAR2(10)  := 'CAUSE';              --�g�[�N����(CAUSE)
  cv_token_target                       CONSTANT VARCHAR2(10)  := 'TARGET';             --�g�[�N����(TARGET)
  cv_token_meaning                      CONSTANT VARCHAR2(10)  := 'MEANING';            --�g�[�N����(MEANING)
  cv_token_key_data                     CONSTANT VARCHAR2(10)  := 'KEY_DATA';           --�g�[�N����(KEY_DATA)
  cv_token_table_name                   CONSTANT VARCHAR2(10)  := 'TABLE_NAME';         --�g�[�N����(TABLE_NAME)
  cv_token_count                        CONSTANT VARCHAR2(10)  := 'COUNT';              --�g�[�N����(COUNT)
  cv_token_org_code                     CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';       --�g�[�N����(ORG_CODE)
  --�Q�ƃ^�C�v
  cv_lookup_book_date                   CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      --�d�q���돈�����s��
  cv_lookup_item_chk_exp                CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_EXP';   --�d�q���덀�ڃ`�F�b�N�i�̔����сj
  cv_lookup_cust_gyotai_sho             CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';          --�Ƒԏ����ޖ���                                                                         
  cv_lookup_consumption_tax             CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';   --����ŋ敪
  cv_lookup_delivery_slip               CONSTANT VARCHAR2(30)  := 'XXCOS1_DELIVERY_SLIP_CLASS';     --�[�i�`�[�敪                                                                         
  cv_lookup_card_sale_class             CONSTANT VARCHAR2(30)  := 'XXCOS1_CARD_SALE_CLASS';         --�J�[�h����敪����
  cv_lookup_input_class                 CONSTANT VARCHAR2(30)  := 'XXCOS1_INPUT_CLASS';             --���͋敪����
  cv_lookup_sale_class                  CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS';              --����敪����
  cv_lookup_delivery_pattern            CONSTANT VARCHAR2(30)  := 'XXCOS1_DELIVERY_PATTERN';        --�[�i�`�ԋ敪����
  cv_lookup_red_black_flag              CONSTANT VARCHAR2(30)  := 'XXCOS1_RED_BLACK_FLAG';          --�ԍ��t���O����
  cv_lookup_hc_class                    CONSTANT VARCHAR2(30)  := 'XXCOS1_HC_CLASS';                --�g���b����
  cv_lookup_sold_out_class              CONSTANT VARCHAR2(30)  := 'XXCOS1_SOLD_OUT_CLASS';          --���؋敪����
  cv_lookup_inv_txn_jor_cls             CONSTANT VARCHAR2(30)  := 'XXCOS1_INV_TXN_JOR_CLS_013_A02'; --����^�C�v�E�d��p�^�[������敪_013_A02
  cv_lookup_dlv_slp_cls_mst             CONSTANT VARCHAR2(30)  := 'XXCOS1_DLV_SLP_CLS_MST_013_A02'; --�[�i�`�[�敪����}�X�^_013_A02
  cv_lookup_dlv_ptn_mst                 CONSTANT VARCHAR2(30)  := 'XXCOS1_DLV_PTN_MST_013_A02';     --�[�i�`�ԋ敪����}�X�^_013_A02
  cv_lookup_sale_class_mst              CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS_MST_013_A02';  --����敪����}�X�^_013_A02
  cv_lookup_mk_org_cls_mst              CONSTANT VARCHAR2(30)  := 'XXCOS1_MK_ORG_CLS_MST_013_A01';  --�쐬���敪   
  --�A�v���P�[�V��������
  cv_xxcff_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFF';                --����
  cv_xxcfo_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFO';                --��v
  cv_xxcfr_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFR';                --AR
  cv_xxcoi_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOI';                --�݌�
  cv_xxcok_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOK';                --��
  cv_xxcos_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOS';                --�̔�
  --
  cn_zero                               CONSTANT NUMBER        := 0;
  cv_all_zero                           CONSTANT VARCHAR2(10)  := '0000000000';           --�_�~�[�i'0')
  cv_all_z                              CONSTANT VARCHAR2(10)  := 'ZZZZZZZZZZ';           --�_�~�[�i'Z')
  --���b�Z�[�W�o�͐�
  cv_file_output                        CONSTANT VARCHAR2(30)  := 'OUTPUT';               --���b�Z�[�W�o�͐�i�t�@�C���j
  cv_file_log                           CONSTANT VARCHAR2(30)  := 'LOG';                  --���b�Z�[�W�o�͐�i���O�j
  cv_file_type_out                      CONSTANT NUMBER        := FND_FILE.OUTPUT;        --���b�Z�[�W�o�͐�
  cv_file_type_log                      CONSTANT NUMBER        := FND_FILE.LOG;           --���b�Z�[�W�o�͐�
  cv_file_mode                          CONSTANT VARCHAR2(30)  := 'w';
  --�b�r�u�o�̓t�H�[�}�b�g
  cv_date_format1                       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           --���t����1
  cv_date_format2                       CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';--���t����2
  cv_date_format3                       CONSTANT VARCHAR2(30)  := 'YYYYMMDD';             --���t����3
  cv_date_format4                       CONSTANT VARCHAR2(30)  := 'YYYYMMDDHH24MISS';     --���t����4
  --CSV
  cv_delimit                            CONSTANT VARCHAR2(1)   := ',';                    --�J���}
  cv_quot                               CONSTANT VARCHAR2(1)   := '"';                    --��������
  cv_comma                              CONSTANT VARCHAR2(1)   := ',';                    --�J���}
  cv_dbl_quot                           CONSTANT VARCHAR2(1)   := '"';                    --�_�u���N�I�[�e�[�V����
  cv_space                              CONSTANT VARCHAR2(1)   := ' ';                    --�X�y�[�X
  cv_cr                                 CONSTANT VARCHAR2(1)   := CHR(10);                --���s
  --�ǉ��X�V�敪
  cv_ins_upd_0                          CONSTANT VARCHAR2(1)   := '0';                    --�ǉ�
  cv_ins_upd_1                          CONSTANT VARCHAR2(1)   := '1';                    --�X�V
  --���s���[�h
  cv_exec_fixed_period                  CONSTANT VARCHAR2(1)   := '0';                    --������s
  cv_exec_manual                        CONSTANT VARCHAR2(1)   := '1';                    --�蓮���s
  --�t���O
  cv_flag_y                             CONSTANT VARCHAR2(01)  := 'Y';                    --�t���O('Y')
  cv_flag_n                             CONSTANT VARCHAR2(01)  := 'N';                    --�t���O('N')
  cv_lang                               CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --����
  cn_max_linesize                       CONSTANT BINARY_INTEGER := 32767;
  cv_dlv_ptn_code                       CONSTANT VARCHAR2(50)  := 'XXCOS_013_A02%';       --�R�[�h
  cv_line_type                          CONSTANT VARCHAR2(10)  := 'LINE';                 --AR����^�C�v
  --�C���^�[�t�F�[�X�t���O
  cv_interface_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                    --�C���^�[�t�F�[�X�t���O('N')
  cv_interface_flag_w                   CONSTANT VARCHAR2(1)   := 'W';                    --�C���^�[�t�F�[�X�t���O('W')
  --�G���[���x��
  cv_errlevel_header                    CONSTANT VARCHAR2(10)  := 'HEAD';                 --����w�b�_ID���X�L�b�v
  cv_errlevel_line                      CONSTANT VARCHAR2(10)  := 'LINE';                 --���̖��ׂɃX�L�b�v
  cv_errlevel_program                   CONSTANT VARCHAR2(10)  := 'PROGRAM';              --�v���O�����I��
--
  -- ���ڑ���
  cv_attr_vc2                           CONSTANT VARCHAR2(1)   := '0';                    --VARCHAR2�i�����`�F�b�N�Ȃ��j
  cv_attr_num                           CONSTANT VARCHAR2(1)   := '1';                    --NUMBER  �i���l�`�F�b�N�j
  cv_attr_dat                           CONSTANT VARCHAR2(1)   := '2';                    --DATE    �i���t�^�`�F�b�N�j
  cv_attr_ch2                           CONSTANT VARCHAR2(1)   := '3';                    --CHAR2   �i�`�F�b�N�j
  --
  cv_slash                              CONSTANT VARCHAR2(1)   := '/';                    --�X���b�V��
  --�̔����э��ڈʒu
  cn_tbl_header_id                      CONSTANT NUMBER        := 1;                      --�̔����уw�b�_ID
  cn_tbl_line_id                        CONSTANT NUMBER        := 49;                     --�̔����і���ID
  cn_tbl_hht_dlv_date                   CONSTANT NUMBER        := 12;                     --HHT�[�i���͓���
-- 2016/10/21 Ver.1.7 Add Start
  --���o�Ώۏ���
  cv_create_class                       CONSTANT VARCHAR2(1)   := '0';                    --�쐬���敪
-- 2016/10/21 Ver.1.7 Add End
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �̔�����
  TYPE g_layout_ttype                   IS TABLE OF VARCHAR2(200)             
                                        INDEX BY PLS_INTEGER;
  TYPE g_sales_exp                      IS TABLE OF g_layout_ttype 
                                        INDEX BY PLS_INTEGER;
  --
  gt_data_tab                           g_layout_ttype;              --�o�̓f�[�^���
  gt_sales_exp_tab                      g_sales_exp;
  -- ���ڃ`�F�b�N
  TYPE g_item_name_ttype                IS TABLE OF fnd_lookup_values.attribute1%TYPE  
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype                 IS TABLE OF fnd_lookup_values.attribute2%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype             IS TABLE OF fnd_lookup_values.attribute3%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype             IS TABLE OF fnd_lookup_values.attribute4%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype                IS TABLE OF fnd_lookup_values.attribute5%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype              IS TABLE OF fnd_lookup_values.attribute6%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_sales_exp_header_id_ttype      IS TABLE OF xxcfo_sales_exp_wait_coop.sales_exp_header_id%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_sales_exp_rowid_ttype          IS TABLE OF UROWID
                                        INDEX BY PLS_INTEGER;
  TYPE g_control_header_id_ttype        IS TABLE OF xxcfo_sales_exp_control.sales_exp_header_id%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_control_rowid_ttype            IS TABLE OF UROWID
                                        INDEX BY PLS_INTEGER;
  --���ʊ֐��`�F�b�N�p
  gt_item_name                          g_item_name_ttype;                                --���ږ���
  gt_item_len                           g_item_len_ttype;                                 --���ڂ̒���
  gt_item_decimal                       g_item_decimal_ttype;                             --���ځi�����_�ȉ��̒����j
  gt_item_nullflg                       g_item_nullflg_ttype;                             --�K�{���ڃt���O
  gt_item_attr                          g_item_attr_ttype;                                --���ڑ���
  gt_item_cutflg                        g_item_cutflg_ttype;                              --�؎̂ăt���O
  --�̔����і��A�g�e�[�u��
  gt_sales_exp_rowid_tbl                g_sales_exp_rowid_ttype;                          --���A�g�e�[�u��ROWID 
  gt_sales_exp_header_id_tbl            g_sales_exp_header_id_ttype;                      --�̔����уw�b�_ID 
  --�̔����ъǗ��e�[�u��
  gt_control_rowid_tbl                  g_control_rowid_ttype;                            --�Ǘ��e�[�u��ROWID 
  gt_control_header_id_tbl              g_control_header_id_ttype;                        --�Ǘ��e�[�u��ID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_ins_upd_kbn                        VARCHAR2(1);                                      --�ǉ��X�V�敪
  gv_exec_mode                          VARCHAR2(1)   DEFAULT cv_exec_fixed_period;       --�������s���[�h
  gv_file_path                          all_directories.directory_name%TYPE   DEFAULT NULL; --�f�B���N�g����
  gv_directory_path                     all_directories.directory_path%TYPE   DEFAULT NULL; --�f�B���N�g��
  gv_full_name                          VARCHAR2(200) DEFAULT NULL;                       --�d�q����̔����уf�[�^�ǉ��t�@�C��
  gv_file_name                          VARCHAR2(100) DEFAULT NULL;                       --�d�q����̔����уf�[�^�ǉ��t�@�C��
  gn_electric_exec_days                 NUMBER;                                           --����
  gd_prdate                             DATE;                                             --�Ɩ����t
  gv_coop_date                          VARCHAR2(14);                                     --�A�g���t
  gv_activ_file_h                       UTL_FILE.FILE_TYPE;                               -- �t�@�C���n���h���擾�p
  gt_sales_exp_header_id                xxcos_sales_exp_headers.sales_exp_header_id%TYPE DEFAULT NULL;
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
  gn_sales_exp_upper_limit              NUMBER;                                           --�̔����уf�[�^����l
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
  --�Ώۃf�[�^
  gt_data_type                          VARCHAR2(1);                                      --�f�[�^����
  gt_ar_interface_flag                  xxcos_sales_exp_headers.ar_interface_flag%TYPE;   --AR�C���^�[�t�F�[�X�t���O
  gt_gl_interface_flag                  xxcos_sales_exp_headers.gl_interface_flag%TYPE;   --GL�C���^�[�t�F�[�X�t���O
  gt_inv_interface_flag                 xxcos_sales_exp_lines.inv_interface_flag%TYPE;    --INV�C���^�[�t�F�[�X�t���O
  --�t�@�C��
  gv_file_data                          VARCHAR2(30000);                                  --�t�@�C���T�C�Y
  gb_fileopen                           BOOLEAN;
  --  
  gt_org_code                           mtl_parameters.organization_code%TYPE;            --�݌ɑg�D�R�[�h
  gt_organization_id                    mtl_parameters.organization_id%TYPE;              --�݌ɑg�DID
  gt_org_id                             mtl_parameters.organization_id%TYPE;              --�g�DID
  --�p�����[�^
  gt_id_from                            xxcos_sales_exp_headers.sales_exp_header_id%TYPE; --�̔����уw�b�_(From)
  gt_id_to                              xxcos_sales_exp_headers.sales_exp_header_id%TYPE; --�̔����уw�b�_(To)
  gt_date_from                          xxcfo_sales_exp_control.business_date%TYPE;       --�Ɩ����t�iTo�j
  gt_date_to                            xxcfo_sales_exp_control.business_date%TYPE;       --�Ɩ����t�iTo�j
  gt_row_id_to                          UROWID;                                           --�Ǘ��e�[�u���X�VROWID
  --
  gd_business_date                      xxcos_sales_exp_headers.business_date%TYPE;       --�Ɩ����t
  gn_coop_cnt                           NUMBER;                                           --���A�g���[�v�J�E���g
  gb_csv_out                            BOOLEAN := FALSE;                                 --CSV�t�@�C���o��
  gb_status_warn                        BOOLEAN := FALSE;                                 --�x������
  gb_coop_out                           BOOLEAN := FALSE;                                 --���A�g�o��
  gb_get_sales_exp                      BOOLEAN := FALSE;                                 --�Ώۃf�[�^���o
  --���ږ�
  gv_sales_class_msg                    fnd_lookup_values.description%TYPE ;              --�̔�����
  gv_artxn_name                         fnd_lookup_values.description%TYPE;               --AR���
  gv_sales_exp_control                  fnd_new_messages.message_text%TYPE;               --�̔����ъǗ��e�[�u��
  gv_sales_exp_wait                     fnd_new_messages.message_text%TYPE;               --�̔����і��A�g�e�[�u��
  gv_quickcode                          fnd_new_messages.message_text%TYPE;               --�N�C�b�N�R�[�h�}�X�^
  gv_interface_flag_name                fnd_new_messages.message_text%TYPE;               --�C���^�[�t�F�[�X
  gv_ar_interface_flag_name             fnd_new_messages.message_text%TYPE;               --AR�C���^�[�t�F�[�X�t���O
  gv_gl_interface_flag_name             fnd_new_messages.message_text%TYPE;               --GL�C���^�[�t�F�[�X�t���O
  gv_inv_interface_flag_name            fnd_new_messages.message_text%TYPE;               --INV�C���^�[�t�F�[�X�t���O
  gv_sales_exp_header_id                fnd_new_messages.message_text%TYPE;               --�̔����уw�b�_ID
  gv_sales_exp_line_id                  fnd_new_messages.message_text%TYPE;               --�̔����і���ID
  gv_ar_type                            fnd_new_messages.message_text%TYPE;               --AR����^�C�v�擾�G���[
  gv_inv_type                           fnd_new_messages.message_text%TYPE;               --INV����^�C�v�擾�G���[
  --����
  gn_target_coop_cnt                    NUMBER;                                           --���A�g�f�[�^�Ώی���
  gn_out_coop_cnt                       NUMBER;                                           --���A�g�o�͌���
  gn_item_cnt                           NUMBER;                                           --�`�F�b�N���ڌ���
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̔����уw�b�_ID(From)
    iv_id_to            IN  VARCHAR2,             --�̔����уw�b�_ID(To)
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lb_retcode                BOOLEAN;
    -- *** �t�@�C�����݃`�F�b�N�p ***
    lb_exists                 BOOLEAN         DEFAULT NULL;  -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length            NUMBER          DEFAULT NULL;  -- �t�@�C���̒���
    ln_block_size             BINARY_INTEGER  DEFAULT NULL;  -- �u���b�N�T�C�Y
    lv_msg                    VARCHAR2(3000);
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �d�q���덀�ڃ`�F�b�N�i�̔����сj�p�J�[�\��
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             AS  item_name                           --���ږ���
              , flv.attribute1          AS  item_len                            --���ڂ̒���
              , NVL(flv.attribute2, cn_zero)
                                        AS  item_decimal                        --���ڂ̒����i�����_�ȉ��j
              , flv.attribute3          AS  item_nullflag                       --�K�{�t���O
              , flv.attribute4          AS  item_attr                           --����
              , flv.attribute5          AS  item_cutflag                        --�؎̂ăt���O
      FROM      fnd_lookup_values       flv                                     --�N�C�b�N�R�[�h
      WHERE     flv.lookup_type         =         cv_lookup_item_chk_exp        --�d�q���덀�ڃ`�F�b�N�i�̔����сj
      AND       gd_prdate               BETWEEN   flv.start_date_active
                                        AND       NVL(flv.end_date_active, gd_prdate)
      AND       flv.enabled_flag        =         cv_flag_y
      AND       flv.language            =         cv_lang
      ORDER BY  flv.lookup_type 
              , flv.lookup_code;
--
  BEGIN
--
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
    --==============================================================
    -- 1.(1)  �p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>  cv_file_output            -- ���b�Z�[�W�o��
      , iv_conc_param1                  =>  iv_ins_upd_kbn            -- �ǉ��X�V�敪
      , iv_conc_param2                  =>  iv_file_name              -- �t�@�C����
      , iv_conc_param3                  =>  iv_id_from                -- �̔����уw�b�_ID�iFrom�j
      , iv_conc_param4                  =>  iv_id_to                  -- �̔����уw�b�_ID�iTo�j
      , ov_errbuf                       =>  lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      =>  lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     --
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>  cv_file_log               -- ���O�o��
      , iv_conc_param1                  =>  iv_ins_upd_kbn            -- �ǉ��X�V�敪
      , iv_conc_param2                  =>  iv_file_name              -- �t�@�C����
      , iv_conc_param3                  =>  iv_id_from                -- �̔����уw�b�_ID�iFrom�j
      , iv_conc_param4                  =>  iv_id_to                  -- �̔����уw�b�_ID�iTo�j
      , ov_errbuf                       =>  lv_errbuf                 -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      =>  lv_retcode                -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     --
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    --==============================================================
    -- 1.(2)  �Ɩ��������t�擾
    --==============================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_prdate            IS    NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00015
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --==============================================================
    -- 1.(3)  �A�g�����p���t�擾
    --==============================================================
    gv_coop_date  :=  TO_CHAR(SYSDATE, cv_date_format4);
--
    --==============================================================
    -- 1.(4) �N�C�b�N�R�[�h�擾
    --==============================================================
    --�d�q���돈�����s�������
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)         AS      electric_exec_date_cnt          --�d�q���돈�����s����
      INTO      gn_electric_exec_days
      FROM      fnd_lookup_values       flv                                               --�N�C�b�N�R�[�h
      WHERE     flv.lookup_type         =         cv_lookup_book_date                     --�d�q���돈�����s����
      AND       flv.lookup_code         =         cv_pkg_name                             --�d�q����̔�����
      AND       gd_prdate               BETWEEN   NVL(flv.start_date_active, gd_prdate)
                                        AND       NVL(flv.end_date_active, gd_prdate)
      AND       flv.enabled_flag        =         cv_flag_y
      AND       flv.language            =         cv_lang;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    => cv_xxcfo_appl_name
                    , iv_name           => cv_msg_cfo_00031
                    , iv_token_name1    => cv_token_lookup_type
                    , iv_token_name2    => cv_token_lookup_code
                    , iv_token_value1   => cv_lookup_book_date
                    , iv_token_value2   => cv_pkg_name
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END;
    --==============================================================
    -- 1.(5) �N�C�b�N�R�[�h�\�擾
    --==============================================================
    -- �d�q���덀�ڃ`�F�b�N�i�̔����сj�p�J�[�\���I�[�v��
    OPEN get_chk_item_cur;
    -- �d�q���덀�ڃ`�F�b�N�i�̔����сj�p�z��ɑޔ�
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name                                  --���ږ�
            , gt_item_len                                   --���ڂ̒���
            , gt_item_decimal                               --���ڂ̒����i�����_�ȉ��j
            , gt_item_nullflg                               --�K�{�t���O
            , gt_item_attr                                  --���ڑ���
            , gt_item_cutflg;                               --�؎̃t���O
    -- �Ώی����̃Z�b�g
    gn_item_cnt   := gt_item_name.COUNT;
    -- �d�q���덀�ڃ`�F�b�N�i�̔����сj�p�J�[�\���N���[�Y
    CLOSE get_chk_item_cur;
    -- �d�q���덀�ڃ`�F�b�N�i�̔����сj�̃��R�[�h���擾�ł��Ȃ������ꍇ�A�G���[�I��
    IF ( gn_item_cnt          =     0 )   THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00031
                    , iv_token_name1    =>  cv_token_lookup_type
                    , iv_token_name2    =>  cv_token_lookup_code
                    , iv_token_value1   =>  cv_lookup_item_chk_exp
                    , iv_token_value2   =>  NULL
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END IF;
    --
    --==============================================================
    -- 1.(6) �v���t�@�C���擾
    --==============================================================
    --�t�@�C���p�X
    gv_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gv_file_path IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_data_filepath
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --�݌ɑg�D
    gt_org_code :=  FND_PROFILE.VALUE(cv_organization_code);
    --
    IF ( gt_org_code IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_organization_code
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    -- �c�ƒP�ʂ̎擾
    gt_org_id   :=  FND_PROFILE.VALUE(cv_org_id);
    IF ( gt_org_id IS NULL ) THEN
       lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_org_id
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --�p�����^�i�t�@�C�����j��NULL�ȊO�̏ꍇ�A�p�����^�i�t�@�C�����j���g�p����
    IF  ( iv_file_name        IS NOT    NULL )    THEN
      gv_file_name  :=  iv_file_name;
    END IF;
    --�p�����^�i�t�@�C�����j��NULL���A�p�����^�i�ǉ��X�V�敪�j���ǉ��̏ꍇ
    IF  ( iv_file_name        IS        NULL )
    AND ( iv_ins_upd_kbn      =         cv_ins_upd_0 )
    THEN
      --�ǉ��t�@�C�������v���t�@�C������擾
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      --
      IF ( gv_file_name IS NULL ) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  cv_xxcfo_appl_name
                      , iv_name           =>  cv_msg_cfo_00001
                      , iv_token_name1    =>  cv_token_prof_name
                      , iv_token_value1   =>  cv_add_filename
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
    END IF;
    --�p�����^�i�t�@�C�����j��NULL���A�p�����^�i�ǉ��X�V�敪�j���X�V�̏ꍇ
    IF  ( iv_file_name        IS        NULL )
    AND ( iv_ins_upd_kbn      =         cv_ins_upd_1 )
    THEN
      --�X�V�t�@�C�������v���t�@�C������擾
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      --
      IF ( gv_file_name IS NULL ) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcfo_appl_name
                      , iv_name         =>  cv_msg_cfo_00001
                      , iv_token_name1  =>  cv_token_prof_name
                      , iv_token_value1 =>  cv_upd_filename
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
    END IF;
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
    --�̔����уf�[�^_����l
    gn_sales_exp_upper_limit := TO_NUMBER(FND_PROFILE.VALUE(cv_sales_exp_upper_limit));
    --
    IF ( gn_sales_exp_upper_limit IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_sales_exp_upper_limit
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
    --
    --==============================================================
    -- 1.(7) �݌ɑg�DID�擾
    --==============================================================
    gt_organization_id    :=  xxcoi_common_pkg.get_organization_id(gt_org_code);
    IF ( gt_organization_id IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcoi_appl_name
                    , iv_name           =>  cv_msg_coi_00006
                    , iv_token_name1    =>  cv_token_org_code
                    , iv_token_value1   =>  gt_org_code
                    );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
    END IF;
    --==============================================================
    -- 1.(8) �f�B���N�g���p�X�擾
    --==============================================================
    BEGIN
      SELECT    ad.directory_path       AS  directory_path                      --�f�B���N�g���p�X
      INTO      gv_directory_path
      FROM      all_directories         ad                                      --�f�B���N�g���e�[�u��
      WHERE     ad.directory_name       =         gv_file_path
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcoi_appl_name
                    , iv_name           =>  cv_msg_coi_00029
                    , iv_token_name1    =>  cv_token_dir_tok
                    , iv_token_value1   =>  gv_file_path
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END;
    --==============================================================
    -- 1.(9) �t�@�C�����o��
    --==============================================================
    --�t�@�C�����ҏW���A�f�B���N�g���̍Ō�ɃX���b�V�������Ă��邩�����ăt�@�C������ҏW
    IF ( SUBSTRB(gv_directory_path, -1, 1)        =     cv_slash )  THEN   
      --�I���ɃX���b�V�������Ă����ꍇ�A�X���b�V����t�����Ȃ�
      gv_full_name    :=  gv_directory_path || gv_file_name;
    ELSE
      --�I���ɃX���b�V�������Ă����ꍇ�A�X���b�V����t������
      gv_full_name    :=  gv_directory_path || cv_slash || gv_file_name;
    END IF;
    --�t�@�C���������O�ɏo��
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application          =>  cv_xxcfo_appl_name
              , iv_name                 =>  cv_msg_cfo_00002
              , iv_token_name1          =>  cv_token_file_name
              , iv_token_value1         =>  gv_full_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which            =>  cv_file_type_out         --�o�͋敪
                  , iv_message          =>  lv_msg                   --���b�Z�[�W
                  , in_new_line         =>  0                        --���s
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which            =>  cv_file_type_log         --�o�͋敪
                  , iv_message          =>  lv_msg                   --���b�Z�[�W
                  , in_new_line         =>  0                        --���s
                  );
    --==============================================================
    -- 2 ����t�@�C�����݃`�F�b�N
    --==============================================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location              =>  gv_file_path
      , filename              =>  gv_file_name
      , fexists               =>  lb_exists
      , file_length           =>  ln_file_length
      , block_size            =>  ln_block_size
    );
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00027
                    );
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --
    --==============================================================
    -- 3 ���ږ��̎擾
    --==============================================================
    --�X�V�敪
    gv_ins_upd_kbn  :=  iv_ins_upd_kbn;
    --�N�C�b�N�R�[�h�}�X�^
    gv_quickcode :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_00066
                  );
    --�̔�����
    gv_sales_class_msg :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_13303
                  );
    --AR������
    gv_artxn_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_13304
                  );
    --�̔����ъǗ��e�[�u��
    gv_sales_exp_control :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11013
                  );
    --�̔����і��A�g�e�[�u��
    gv_sales_exp_wait :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11012
                  );
    --AR�C���^�[�t�F�[�X�t���O
    gv_ar_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11014
                  );
    --GL�C���^�[�t�F�[�X�t���O
    gv_gl_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11015
                  );
    --INV�C���^�[�t�F�[�X�t���O
    gv_inv_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11016
                  );
    --�̔����уw�b�_ID
    gv_sales_exp_header_id :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_10706
                  );
    --�̔����і���ID
    gv_sales_exp_line_id :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_10702
                  );
    --�C���^�t�F�[�X�t���O�ΏۊO
    gv_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11038
                  );
    --AR����^�C�v�擾�G���[
    gv_ar_type :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11042
                  );
                  
    --INV����^�C�v�擾�G���[
    gv_inv_type :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11043
                  );
--
  EXCEPTION
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
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( get_chk_item_cur%ISOPEN )  THEN
        CLOSE   get_chk_item_cur;
      END IF;
      --
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_wait
   * Description      : ���A�g�f�[�^�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_wait(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̔����уw�b�_ID(From)
    iv_id_to            IN  VARCHAR2,             --�̔����уw�b�_ID(To)
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_wait'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    --�̔����і��A�g�e�[�u���擾�p�J�[�\���i�蓮���s�p�j
    CURSOR  sales_exp_wait_manual_cur  
    IS
      SELECT    xsewc.rowid                       AS  row_id                    --ROWID
              , xsewc.sales_exp_header_id         AS  sales_exp_header_id       --�̔����уw�b�_ID
      FROM      xxcfo_sales_exp_wait_coop         xsewc
      ORDER BY  xsewc.sales_exp_header_id
      ;
    --�̔����і��A�g�e�[�u���擾�p�J�[�\���i������s�p�j���b�N�擾�t��
    CURSOR  sales_exp_wait_fixed_cur  
    IS
      SELECT    xsewc.rowid                       AS  row_id                    --ROWID
              , xsewc.sales_exp_header_id         AS  sales_exp_header_id       --�̔����уw�b�_ID
      FROM      xxcfo_sales_exp_wait_coop         xsewc
      ORDER BY  xsewc.sales_exp_header_id
      FOR UPDATE NOWAIT
      ;
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
    --==============================================================
    -- A-2 ���s���[�h��ݒ�
    --==============================================================
    --�p�����^�u�̔�����(From)�v�u�̔�����(To)�v�������͂̏ꍇ�A�蓮���s
    IF  ( iv_id_from          IS  NULL )
    AND ( iv_id_to            IS  NULL ) 
    THEN
      gv_exec_mode  :=    cv_exec_fixed_period;             --������s
    ELSE
      gv_exec_mode  :=    cv_exec_manual;                   --�蓮���s
    END IF ;
    --
    --==============================================================
    --�蓮���s�̏ꍇ
    --==============================================================
    IF ( gv_exec_mode         =         cv_exec_manual )  THEN
      --�̔����і��A�g�e�[�u���J�[�\���I�[�v��
      OPEN  sales_exp_wait_manual_cur;
      --�̔����і��A�g�e�[�u���f�[�^�擾
      FETCH sales_exp_wait_manual_cur BULK COLLECT INTO 
          gt_sales_exp_rowid_tbl
        , gt_sales_exp_header_id_tbl;
      --�̔����і��A�g�e�[�u���J�[�\���N���[�Y
      CLOSE sales_exp_wait_manual_cur;
    --==============================================================
    --������s�̏ꍇ
    --==============================================================
    ELSE
      --�̔����і��A�g�e�[�u���J�[�\���I�[�v��
      OPEN  sales_exp_wait_fixed_cur;
      --�̔����і��A�g�e�[�u���f�[�^�擾
      FETCH sales_exp_wait_fixed_cur BULK COLLECT INTO 
          gt_sales_exp_rowid_tbl
        , gt_sales_exp_header_id_tbl;
      --�̔����і��A�g�e�[�u���J�[�\���N���[�Y
      CLOSE sales_exp_wait_fixed_cur;
    END IF;
    --
    --�̔����і��A�g�e�[�u�����R�[�h����
--
  EXCEPTION
    -- *** ���b�N�̎擾�G���[ ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_sales_exp_wait
                    );
      ov_errmsg  := lv_errbuf;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( sales_exp_wait_manual_cur%ISOPEN ) THEN
        CLOSE   sales_exp_wait_manual_cur;
      END IF;
      --
      IF ( sales_exp_wait_fixed_cur%ISOPEN )  THEN
        CLOSE   sales_exp_wait_fixed_cur;
      END IF;
      --
  END get_sales_exp_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_control
   * Description      : �Ǘ��e�[�u���f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_control(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̔����уw�b�_ID(From)
    iv_id_to            IN  VARCHAR2,             --�̔����уw�b�_ID(To)
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_control'; -- �v���O������
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �̔����ъǗ��e�[�u���擾�P�iFrom�擾�p�j
    CURSOR sales_exp_control1_cur
    IS                                                                          
      SELECT    xsec.sales_exp_header_id          AS  sales_exp_header_id       --�̔����уw�b�_ID
              , xsec.business_date                AS  business_date             --�Ɩ����t
      FROM      xxcfo_sales_exp_control           xsec                          --�̔����ъǗ��e�[�u��
      WHERE     xsec.process_flag                 =         cv_flag_y
      ORDER BY  xsec.business_date                DESC
              , xsec.creation_date                DESC
      ;
    --
    -- ���R�[�h�^
    TYPE sales_exp_control1_rec IS RECORD (
        sales_exp_header_id             xxcfo_sales_exp_control.sales_exp_header_id%TYPE  --�̔����уw�b�_ID
      , business_date                   xxcfo_sales_exp_control.business_date%TYPE        --�Ɩ����t
    );
    -- �e�[�u���^
    TYPE sales_exp_control1_ttype       IS TABLE OF sales_exp_control1_rec 
                                        INDEX BY BINARY_INTEGER;
    sales_exp_control1_tab              sales_exp_control1_ttype;
    --
    -- �̔����ъǗ��e�[�u���擾�Q�iTo�擾�p�j
    CURSOR sales_exp_control2_cur
    IS
      SELECT    xsec.rowid                        AS  row_id                    --ROWID
              , xsec.sales_exp_header_id          AS  sales_exp_header_id       --�̔����уw�b�_ID
              , xsec.business_date                AS  business_date             --�Ɩ����t
      FROM      xxcfo_sales_exp_control           xsec                          --�̔����ъǗ��e�[�u��
      WHERE     xsec.process_flag                 =         cv_flag_n
      ORDER BY  xsec.business_date                DESC
              , xsec.creation_date                DESC
      ;
    -- �̔����ъǗ��e�[�u���擾3(���b�N�擾�p)
    CURSOR sales_exp_control3_cur
    IS
      SELECT    xsec.rowid                        AS  row_id                    --ROWID
      FROM      xxcfo_sales_exp_control           xsec                          --�̔����ъǗ��e�[�u��
      WHERE     xsec.process_flag                 =         cv_flag_n           --������
      AND       xsec.rowid                        =         gt_row_id_to        --�̔����ъǗ��e�[�u���擾�Q�iTo�擾�p�j��ROWID
      FOR UPDATE NOWAIT
      ;
    -- ���R�[�h�^
    TYPE sales_exp_control_rec IS RECORD(
        row_id                          UROWID                                            --ROWID
      , sales_exp_header_id             xxcfo_sales_exp_control.sales_exp_header_id%TYPE  --�̔����уw�b�_ID
      , business_date                   xxcfo_sales_exp_control.business_date%TYPE        --�Ɩ����t
    );
    -- �e�[�u���^
    TYPE sales_exp_control_ttype        IS TABLE OF sales_exp_control_rec 
                                        INDEX BY BINARY_INTEGER;
    sales_exp_control_tab               sales_exp_control_ttype;
    --
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
    --==============================================================
    -- 1.(1) �̔����ъǗ��e�[�u���̃f�[�^�擾
    --==============================================================
    --�̔����ъǗ��e�[�u���擾�P�iFrom�擾�p�j�I�[�v��
    OPEN    sales_exp_control1_cur;
    --�̔����ъǗ��e�[�u���擾�P�iFrom�擾�p�j�f�[�^�擾
    FETCH   sales_exp_control1_cur      BULK COLLECT INTO sales_exp_control1_tab;
    --�̔����ъǗ��e�[�u���擾�P�iFrom�擾�p�j�N���[�Y
    CLOSE   sales_exp_control1_cur;
    --
    --�̔����ъǗ��e�[�u���擾�P�iFrom�擾�p�j���R�[�h���擾�ł��Ȃ��ꍇ�A�G���[
    IF ( sales_exp_control1_tab.COUNT   =   0 ) THEN    
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcff_appl_name
                    , iv_name         => cv_msg_cff_00165
                    , iv_token_name1  => cv_token_get_data
                    , iv_token_value1 => gv_sales_exp_control
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE   global_process_expt;
    ELSE
      --1���ڂ̃��R�[�h���擾
      gt_id_from        :=  sales_exp_control1_tab(1).sales_exp_header_id;
      gt_date_from      :=  sales_exp_control1_tab(1).business_date;
    END IF;
    --
    --==============================================================
    -- 1.(2) �蓮���s�̏ꍇ
    --==============================================================
    IF ( gv_exec_mode         =   cv_exec_manual )  THEN
      --�p�����^�u�̔����уw�b�_ID(From)�v���p�����^�u�̔����уw�b�_ID(To)�v�̏ꍇ�A�G���[
      IF ( TO_NUMBER(iv_id_from)        >   TO_NUMBER(iv_id_to) )  THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10008
                      , iv_token_name1  => cv_token_param1
                      , iv_token_name2  => cv_token_param2
                      , iv_token_value1 => gv_sales_exp_header_id || '(From)'
                      , iv_token_value2 => gv_sales_exp_header_id || '(To)'
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
      --�p�����^�u�̔����уw�b�_ID(To)�v���擾�����̔����уw�b�_ID(From)�̏ꍇ�A������
      --������ȍ~�ŁA�G���[�����������ꍇ�A�[���o�C�g�t�@�C�����쐬����B
      gb_get_sales_exp    :=  TRUE;
      --
      IF ( TO_NUMBER(iv_id_to)          >   gt_id_from )  THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10006
                      , iv_token_name1  => cv_token_max_id
                      , iv_token_value1 => gt_id_from
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
      --
      --�p�����^���O���[�o���ϐ��ɑޔ�
      gt_id_from        :=  TO_NUMBER(iv_id_from);
      gt_id_to          :=  TO_NUMBER(iv_id_to);
      --
    END IF;
    --
    --==============================================================
    -- 1.(3) ������s�̏ꍇ
    --==============================================================
    IF ( gv_exec_mode         =     cv_exec_fixed_period )  THEN
      --�̔����ъǗ��e�[�u���擾�Q�iTo�擾�p�j�I�[�v��
      OPEN  sales_exp_control2_cur;
      --�̔����ъǗ��e�[�u���擾�Q�iTo�擾�p�j�f�[�^�擾
      FETCH sales_exp_control2_cur BULK COLLECT INTO sales_exp_control_tab;
      --�̔����ъǗ��e�[�u���擾�Q�iTo�擾�p�j�N���[�Y
      CLOSE sales_exp_control2_cur;
      --
      --�w��������A�擾�������������Ȃ��܂��́A
      IF  ( sales_exp_control_tab.COUNT <     gn_electric_exec_days )
      OR  ( sales_exp_control_tab.COUNT =     0 
      AND   gn_electric_exec_days       =     0 ) 
      THEN
        --�擾�����Ǘ��f�[�^�������A�d�q���돈�����s�������傫���ꍇ�A�d��w�b�_ID(To)��NULL��ݒ肷��
        gt_id_to        :=  NULL;
        --
        gb_status_warn  :=  TRUE;
        --
      ELSE
        --���o�����l���O���[�o���ϐ��ɐݒ�
        gt_row_id_to  :=  sales_exp_control_tab( gn_electric_exec_days ).row_id;
        gt_id_to      :=  sales_exp_control_tab( gn_electric_exec_days ).sales_exp_header_id;
        gt_date_to    :=  sales_exp_control_tab( gn_electric_exec_days ).business_date;
      END IF;
      --==============================================================
      -- 1.(4) �Ō�Ɏ擾�������R�[�h�����b�N
      --==============================================================
      IF ( gt_id_to           IS NOT    NULL )    THEN
        --�̔����уw�b�_ID(To)���擾�ł����ꍇ�A���b�N���擾����
        OPEN  sales_exp_control3_cur;
        CLOSE sales_exp_control3_cur;
      END IF;
    --
    END IF;
    --
    --==============================================================
    -- 2 �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_file_path        -- �f�B���N�g���p�X
                          , filename     => gv_file_name        -- �t�@�C����
                          , open_mode    => cv_file_mode        -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                         );
      --
      gb_fileopen   :=  TRUE;
      --
    EXCEPTION    --
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00029
                      , iv_token_name1  => cv_token_max_id
                      , iv_token_value1 => gt_id_from
                      );
        --
        ov_errmsg :=  lv_errbuf;
        RAISE global_api_others_expt;    
    END;
    --
--
  EXCEPTION
    -- *** ���b�N�̎擾�G���[ ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_sales_exp_control
                    );
      ov_errmsg  := lv_errbuf;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      --��O�������A�J�[�\�����I�[�v������Ă����ꍇ�A�J�[�\�����N���[�Y����B
      IF ( sales_exp_control1_cur%ISOPEN )  THEN
        CLOSE   sales_exp_control1_cur;
      END IF;
      IF ( sales_exp_control2_cur%ISOPEN )  THEN
        CLOSE   sales_exp_control2_cur;
      END IF;
      --
  END get_sales_exp_control;
--
  /**********************************************************************************
   * Procedure Name   : get_flex_information
   * Description      : �t�����擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_flex_information(
    ov_errlevel         OUT VARCHAR2,             --�G���[���x��
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_flex_information'; -- �v���O������
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
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    interface_error_expt      EXCEPTION;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    -- 1.(1)  �`�q�̏ꍇ
    --==============================================================
    --AR�C���^�[�t�F�[�X�t���O��'Y'�̏ꍇ�AAR������̎擾���s���B
    IF ( gt_ar_interface_flag           =     cv_flag_y ) THEN
      BEGIN
        SELECT    rcta.customer_trx_id            AS  customer_trx_id           --AR���ID
                , rcta.trx_number                 AS  trx_number                --AR�������i����j�ԍ�
                , rcta.doc_sequence_value         AS  doc_sequence_value        --�����������ԍ�
                , rctta.name                      AS  name                      --����^�C�v��
                , hp.party_name                   AS  party_name                --�ڋq��
        INTO      gt_data_tab(84)                                               --AR���ID
                , gt_data_tab(85)                                               --AR�������i����j�ԍ�
                , gt_data_tab(86)                                               --�����������ԍ�
                , gt_data_tab(87)                                               --����^�C�v��
                , gt_data_tab(88)                                               --�ڋq��
        FROM      ra_customer_trx_all             rcta      --AR��������w�b�_        
                , ra_customer_trx_lines_all       rctla     --AR�����������
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--              , ra_batch_sources_all            rbsa      --�o�b�`�\�[�X
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
                , ra_cust_trx_types_all           rctta     --AR����^�C�v
                , hz_cust_accounts                hca       --�ڋq�}�X�^
                , hz_parties                      hp        --�p�[�e�B
        WHERE     rcta.customer_trx_id            =         rctla.customer_trx_id
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--      AND       rcta.batch_source_id            =         rbsa.batch_source_id
--      AND       rcta.org_id                     =         rbsa.org_id
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
        AND       rcta.cust_trx_type_id           =         rctta.cust_trx_type_id
        AND       rcta.org_id                     =         rctta.org_id
        AND       rcta.bill_to_customer_id        =         hca.cust_account_id
        AND       hca.party_id                    =         hp.party_id
        AND       rctla.line_type                 =         cv_line_type
        AND       rctla.interface_line_attribute7 =         gt_data_tab(cn_tbl_header_id) --�̔����уw�b�_ID
        AND       rcta.org_id                     =         gt_org_id                     --�c�ƒP��
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--      AND       rbsa.name                       =         gv_sales_class_msg            --�̔�����
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
        GROUP BY  rcta.customer_trx_id                      --AR���ID
                , rcta.trx_number                           --AR�������i����j�ԍ�
                , rcta.doc_sequence_value                   --�����������ԍ�
                , rctta.name                                --����^�C�v��
                , hp.party_name                             --�ڋq��
        ;
      EXCEPTION
        WHEN TOO_MANY_ROWS  THEN
          gt_data_tab(84)     :=  cv_all_zero;              --AR���ID
          gt_data_tab(85)     :=  cv_all_z;                 --AR�������i����j�ԍ�
          gt_data_tab(86)     :=  cv_all_zero;              --�����������ԍ�
          gt_data_tab(87)     :=  cv_all_z;                 --����^�C�v��
          gt_data_tab(88)     :=  cv_all_z;                 --�ڋq��
        WHEN NO_DATA_FOUND THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause 
                        , iv_token_name2  => cv_token_target
                        , iv_token_name3  => cv_token_meaning
                        , iv_token_value1 => gv_ar_type
                        , iv_token_value2 => gv_sales_exp_header_id || cv_msg_part || gt_data_tab(cn_tbl_header_id)
                        , iv_token_value3 => SQLERRM 
                        );
          --
          IF ( gv_exec_mode             =   cv_exec_fixed_period )  THEN
            --
            gb_status_warn    :=  TRUE;
            ov_errlevel       :=  cv_errlevel_header;
            --
            FND_FILE.PUT_LINE(
               which  => cv_file_type_log
              ,buff   => lv_errbuf
              );
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
            FND_FILE.PUT_LINE(
               which  => cv_file_type_out
              ,buff   => lv_errbuf
            );
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
            --
          END IF;
          --
          RAISE interface_error_expt;
      END;
    END IF;
    --==============================================================
    -- 1.(2)  �h�m�u�̏ꍇ
    --==============================================================
    --INV�C���^�[�t�F�[�X�t���O��'Y'�̏ꍇ�AINV����^�C�v�̎擾���s���B
    IF ( gt_inv_interface_flag          =     cv_flag_y )   THEN
      BEGIN
        SELECT    flv1.attribute7                 AS  inv_trx_type              --INV����^�C�v
        INTO      gt_data_tab(83)
        FROM      fnd_lookup_values               flv1      --���������
                , fnd_lookup_values               flv2      --�ԍ����
                , fnd_lookup_values               flv3      --�[�i�`�[�敪���
                , fnd_lookup_values               flv4      --�[�i�`�ԋ敪���
                , fnd_lookup_values               flv5      --����敪���
        WHERE     flv1.lookup_type                =         cv_lookup_inv_txn_jor_cls
        AND       flv1.enabled_flag               =         cv_flag_y
        AND       flv1.attribute12                =         cv_flag_y
        AND       flv1.language                   =         cv_lang
        AND       NVL(flv1.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv1.end_date_active, gd_prdate)    >=  gd_prdate
        --�ԍ����
        AND       flv2.lookup_type                =         cv_lookup_red_black_flag
        AND       flv2.enabled_flag               =         cv_flag_y
        AND       flv2.language                   =         cv_lang
        AND       NVL(flv2.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv2.end_date_active, gd_prdate)    >=  gd_prdate
        --�[�i�`�[�敪���
        AND       flv3.lookup_type                =         cv_lookup_dlv_slp_cls_mst
        AND       flv3.enabled_flag               =         cv_flag_y
        AND       flv3.language                   =         cv_lang
        AND       flv3.lookup_code                LIKE      cv_dlv_ptn_code
        AND       NVL(flv3.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv3.end_date_active, gd_prdate)    >=  gd_prdate
        --�[�i�`�ԋ敪���
        AND       flv4.lookup_type                =         cv_lookup_dlv_ptn_mst
        AND       flv4.enabled_flag               =         cv_flag_y
        AND       flv4.language                   =         cv_lang
        AND       flv4.lookup_code                LIKE      cv_dlv_ptn_code
        AND       NVL(flv4.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv4.end_date_active, gd_prdate)    >=  gd_prdate
        --����敪���
        AND       flv5.lookup_type                =         cv_lookup_sale_class_mst
        AND       flv5.enabled_flag               =         cv_flag_y
        AND       flv5.language                   =         cv_lang
        AND       flv5.lookup_code                LIKE      cv_dlv_ptn_code
        AND       NVL(flv5.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv5.end_date_active, gd_prdate)    >=  gd_prdate
        --���������Ƃ̌���
        AND       flv1.attribute1                 =         flv2.lookup_code    --�ԍ��t���O
        AND       flv1.attribute2                 =         flv3.attribute1     --�[�i�`�[�敪
        AND       flv1.attribute3                 =         flv4.attribute1     --�[�i�`�ԋ敪
        AND       flv1.attribute4                 =         flv5.attribute1     --����敪���
        --
        AND       flv2.lookup_code                =         gt_data_tab(76)     --�ԍ��t���O
        AND       flv3.meaning                    =         gt_data_tab(35)     --�[�i�`�[�敪
        AND       flv4.meaning                    =         gt_data_tab(74)     --�[�i�`�ԋ敪
        AND       flv5.meaning                    =         gt_data_tab(72)     --����敪
        --
        GROUP BY  flv1.attribute7                                               --INV����^�C�v
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause 
                        , iv_token_name2  => cv_token_target
                        , iv_token_name3  => cv_token_meaning
                        , iv_token_value1 => gv_inv_type
                        , iv_token_value2 => gv_sales_exp_line_id || cv_msg_part || gt_data_tab(49)
                        , iv_token_value3 => SQLERRM 
                        );
          --
          IF ( gv_exec_mode             =   cv_exec_fixed_period )    THEN
            --
            gb_status_warn    :=  TRUE;
            ov_errlevel       :=  cv_errlevel_line;
            --
            FND_FILE.PUT_LINE(
               which  => cv_file_type_log
              ,buff   => lv_errbuf
              );
            --
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
            FND_FILE.PUT_LINE(
               which  => cv_file_type_out
              ,buff   => lv_errbuf
            );
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
          END IF;
          --
          RAISE interface_error_expt;
      END;
    END IF;
--
  EXCEPTION
    WHEN interface_error_expt THEN
      ov_errmsg  := lv_errbuf;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END get_flex_information;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : ���ڃ`�F�b�N����(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_errlevel         OUT VARCHAR2,             --�G���[���x��   
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item'; -- �v���O������
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
    lv_err_flag               VARCHAR2(1);
    ln_coop_cnt               NUMBER;
    ln_coop_start             NUMBER;
    lv_item_value             VARCHAR2(200);
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
    interface_data_skip_expt  EXCEPTION;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    -- 2 �蓮���s�̏ꍇ
    --==============================================================
    IF ( gv_exec_mode         =   cv_exec_manual )  THEN
      lv_err_flag := cv_flag_n;
      ln_coop_start   :=  NVL(gn_coop_cnt, 1);
      --���A�g�e�[�u���ɑ��݂��邩�`�F�b�N���s��
      <<check_wait_coop_loop>>
      FOR  ln_coop_cnt IN ln_coop_start..gt_sales_exp_header_id_tbl.COUNT LOOP
        IF ( gt_sales_exp_header_id_tbl(ln_coop_cnt)   =   gt_data_tab(cn_tbl_header_id) )  THEN
          --���A�g�e�[�u���ɔ̔����уw�b�_ID�����݂���ꍇ�A�G���[
          gn_coop_cnt   :=    ln_coop_cnt;                            --�z��̈ʒu��ޔ�
          ov_errlevel   :=    cv_errlevel_header;                     --�w�b�_�P�ʂŃX�L�b�v
          --
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10010
                        , iv_token_name1  => cv_token_doc_data 
                        , iv_token_name2  => cv_token_doc_dist_id
                        , iv_token_value1 => gv_sales_exp_header_id
                        , iv_token_value2 => gt_data_tab(cn_tbl_header_id)
                        );
          --
          RAISE interface_data_skip_expt;
        ELSIF ( gt_sales_exp_header_id_tbl(ln_coop_cnt)     >   gt_data_tab(cn_tbl_header_id) )   THEN
          --���A�g�e�[�u���ɔ̔����уw�b�_ID�����݂��Ȃ��ꍇ�A���[�v���I��
          gn_coop_cnt   :=    ln_coop_cnt;                            --�z��̈ʒu��ޔ�
          EXIT check_wait_coop_loop;
        END IF;
      END LOOP check_wait_coop_loop;
    --==============================================================
    -- 3 ������s�̏ꍇ
    --==============================================================
    ELSIF ( gv_exec_mode      =   cv_exec_fixed_period )    THEN
      gt_sales_exp_header_id          :=  gt_data_tab(cn_tbl_header_id);
      --==============================================================
      -- AR�C���^�[�t�F�[�X�t���O��('N','W')�Ȃ疢�A�g
      --==============================================================
      IF ( gt_ar_interface_flag         IN  (cv_interface_flag_n, cv_interface_flag_w) )  THEN
        ov_errlevel   :=  cv_errlevel_header;
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10007
                      , iv_token_name1  => cv_token_cause 
                      , iv_token_name2  => cv_token_target
                      , iv_token_name3  => cv_token_meaning
                      , iv_token_value1 => gv_ar_interface_flag_name
                      , iv_token_value2 => gv_sales_exp_header_id || cv_msg_part || gt_data_tab(cn_tbl_header_id)
                      , iv_token_value3 => NULL
                      );
        --
        RAISE interface_data_skip_expt;
      END IF;
      --==============================================================
      -- GL�C���^�[�t�F�[�X�t���O��('N','W')�Ȃ疢�A�g
      --==============================================================
      IF  ( gt_gl_interface_flag        IN  (cv_interface_flag_n, cv_interface_flag_w) )  THEN
        ov_errlevel   :=  cv_errlevel_header;
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10007
                      , iv_token_name1  => cv_token_cause 
                      , iv_token_name2  => cv_token_target
                      , iv_token_name3  => cv_token_meaning
                      , iv_token_value1 => gv_gl_interface_flag_name
                      , iv_token_value2 => gv_sales_exp_header_id || cv_msg_part || gt_data_tab(cn_tbl_header_id)
                      , iv_token_value3 => NULL
                      );
       --
        RAISE  interface_data_skip_expt;
      END IF;
      --==============================================================
      -- 4 INV�C���^�[�t�F�[�X�t���O��('N','W')�Ȃ疢�A�g
      --==============================================================
      IF ( gt_inv_interface_flag        IN  (cv_interface_flag_n, cv_interface_flag_w) )  THEN
        ov_errlevel   :=  cv_errlevel_line;
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10007
                      , iv_token_name1  => cv_token_cause 
                      , iv_token_name2  => cv_token_target
                      , iv_token_name3  => cv_token_meaning
                      , iv_token_value1 => gv_inv_interface_flag_name
                      , iv_token_value2 => gv_sales_exp_line_id || cv_msg_part || gt_data_tab(49)
                      , iv_token_value3 => NULL
                      );
        --
        RAISE  interface_data_skip_expt;
      END IF;
    END IF;
    --==============================================================
    -- ���ڌ��`�F�b�N
    --==============================================================
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      IF ( ln_cnt             =     cn_tbl_hht_dlv_date )   THEN
        --HHT�[�i���͓���
        lv_item_value   :=  SUBSTRB(gt_data_tab(ln_cnt), 1, 10);
      ELSE
        lv_item_value   :=  gt_data_tab(ln_cnt);
      END IF;
      --���ڌ��`�F�b�N�֐��ďo
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --���ږ���
        , iv_item_value                 =>        lv_item_value                     --�ύX�O�̒l
        , in_item_len                   =>        gt_item_len(ln_cnt)               --���ڂ̒���
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --���ڂ̒���(�����_�ȉ�)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --�K�{�t���O
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --���ڑ���
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --�؎̂ăt���O
        , ov_item_value                 =>        lv_item_value                     --���ڂ̒l
        , ov_errbuf                     =>        lv_errbuf                         --�G���[���b�Z�[�W
        , ov_retcode                    =>        lv_retcode                        --���^�[���R�[�h
        , ov_errmsg                     =>        lv_errmsg                         --���[�U�[�E�G���[���b�Z�[�W
        );
      --
      IF ( lv_retcode                   =     cv_status_normal )    THEN
        IF ( ln_cnt                     =     cn_tbl_hht_dlv_date ) THEN
          --HHT�[�i���͓���
          gt_data_tab(ln_cnt)   :=  lv_item_value || SUBSTRB(gt_data_tab(ln_cnt), 11, 9);
        ELSE
          gt_data_tab(ln_cnt)   :=  lv_item_value;
        END IF;
      ELSIF ( lv_retcode                =     cv_status_warn )    THEN
        -- ���̏���
        IF  ( gv_exec_mode              =     cv_exec_fixed_period )  THEN
          --������s�̏ꍇ�A�w�b�_�P�ʂŃX�L�b�v
          ov_errlevel         :=     cv_errlevel_header;  
        ELSIF ( gv_exec_mode            =     cv_exec_manual )    
        AND   ( gv_ins_upd_kbn          =     cv_ins_upd_1   )    
        THEN
          --�蓮���s���ǉ��X�V�敪���X�V�̏ꍇ�A�������I��
          ov_errlevel         :=     cv_errlevel_program;  
        ELSE
          --�蓮���s���ǉ��X�V�敪���ǉ��̏ꍇ�A�w�b�_�P�ʂŏ������X�L�b�v
          ov_errlevel         :=     cv_errlevel_header;  
        END IF;
        --
        IF ( lv_errbuf                  =     cv_msg_cfo_10011 )    THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10011
                        , iv_token_name1  => cv_token_key_data
                        , iv_token_value1 => gt_item_name(49) || cv_msg_part || gt_data_tab(49) 
                        );
          gb_coop_out   :=  FALSE;
        ELSE
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause   
                        , iv_token_name2  => cv_token_target  
                        , iv_token_name3  => cv_token_meaning 
                        , iv_token_value1 => cv_msg_cfo_11008
                        , iv_token_value2 => gt_item_name(49) || cv_msg_part || gt_data_tab(49)
                        , iv_token_value3 => lv_errmsg
                        );
        END IF;
        --
        --�蓮���s���ǉ��X�V�敪���X�V�̏ꍇ�A�������I��������
        IF  ( gv_exec_mode              =     cv_exec_manual )  
        AND ( gv_ins_upd_kbn            =     cv_ins_upd_1   )  
        THEN
          lv_errbuf   :=  lv_errmsg;
          RAISE   global_process_expt;
        ELSE 
          --�蓮���s�ȊO�͏����X�L�b�v
          RAISE   interface_data_skip_expt;
        END IF;
      ELSIF ( lv_retcode                =     cv_status_error )   THEN
        RAISE  global_api_others_expt;
      END IF;
      --
    END LOOP;
--  
  EXCEPTION
--  --�f�[�^�X�L�b�v
    WHEN interface_data_skip_expt THEN
      --
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_log
        , buff                =>  lv_errmsg --�G���[���b�Z�[�W
      );
      --
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
      -- �o�̓t�@�C���ɂ��G���[���e���o�͂���
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_out
        , buff                =>  lv_errmsg --�G���[���b�Z�[�W
      );
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : �b�r�u�o�͏���(A-7)
   ***********************************************************************************/
  PROCEDURE out_csv(
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- �v���O������
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
    lv_delimit                VARCHAR2(1);
    ln_line_cnt               NUMBER;
    ln_item_cnt               NUMBER;
--
    -- *** ���[�J���ϐ� ***
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    -- �s�P�ʂŃ��[�v
    --==============================================================
    <<sales_exp_item_loop>>
    FOR ln_line_cnt IN  1..gt_sales_exp_tab.COUNT LOOP
      --==============================================================
      -- ���ڂ̃��[�v
      --==============================================================
      --�f�[�^�ҏW�G���A������
      gv_file_data  :=  NULL;
      lv_delimit    :=  NULL;
      --�f�[�^�A�����[�v
      <<sales_exp_item_loop>>
      FOR ln_item_cnt  IN 1..gt_item_name.COUNT LOOP
        --�������Ƃɏ������s��
        IF ( gt_item_attr(ln_item_cnt)  IN    (cv_attr_vc2, cv_attr_ch2) )   THEN
          --VARCHAR2,CHAR2
          gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || 
                              REPLACE(
                                REPLACE(
                                  REPLACE(gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt), cv_cr, cv_space)
                                    , cv_dbl_quot, cv_space)
                                      , cv_comma, cv_space) || cv_quot;
        ELSIF ( gt_item_attr(ln_item_cnt)         =     cv_attr_num )  THEN
          --NUMBER
          gv_file_data  :=  gv_file_data || lv_delimit  || gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt);
        ELSIF ( gt_item_attr(ln_item_cnt)         =     cv_attr_dat )  THEN
          --DATE
          IF ( ln_item_cnt              =     cn_tbl_hht_dlv_date )   THEN
            --HHT�[�i���͓���
            gv_file_data  :=  gv_file_data || lv_delimit  || TO_CHAR(TO_DATE(gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt), cv_date_format2), cv_date_format4);
          ELSE
            gv_file_data  :=  gv_file_data || lv_delimit  || TO_CHAR(TO_DATE(gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt), cv_date_format1), cv_date_format3);
          END IF;
        END IF;
        --�f���~�^�ɃJ���}���Z�b�g
        lv_delimit  :=  cv_delimit;               
        --
      END LOOP sales_exp_item_loop;
      --�A�g����������
      gv_file_data  :=  gv_file_data || lv_delimit  || gv_coop_date; --gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt + 1);
      --
      --==============================================================
      -- �t�@�C���o��
      --==============================================================
      BEGIN
        UTL_FILE.PUT_LINE(gv_activ_file_h
                         ,gv_file_data
                         );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_00030
                        );
          --
          lv_errmsg :=  lv_errbuf;
          RAISE  global_api_others_expt;
      END;
      --�b�r�u�o�͌����J�E���g�A�b�v
      gn_normal_cnt   :=  gn_normal_cnt   +   1;
      --
    END LOOP sales_exp_item_loop;
    --
  EXCEPTION
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
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : ins_sales_exp_coop
   * Description      : ���A�g�e�[�u���o�^����(A-8)
   ***********************************************************************************/
  PROCEDURE ins_sales_exp_coop(
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_sales_exp_coop'; -- �v���O������
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
    lt_sales_exp_header_id              xxcfo_sales_exp_wait_coop.sales_exp_header_id%TYPE;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    --����̔̔����уw�b�_ID���A�̔����і��A�g�e�[�u���ɑ��݂���ꍇ�͒ǉ����Ȃ�
    BEGIN
      SELECT    xsewc.sales_exp_header_id         AS        sales_exp_header_id --�̔����уw�b�_ID
      INTO      lt_sales_exp_header_id
      FROM      xxcfo_sales_exp_wait_coop         xsewc                         --�̔����і��A�g�e�[�u��  
      WHERE     xsewc.request_id                  =         cn_request_id       --���ݏ������̗v��ID
      AND       xsewc.sales_exp_header_id         =         gt_data_tab(cn_tbl_header_id)      
                                                                                --�̔����уw�b�_ID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      
        BEGIN
          INSERT INTO xxcfo_sales_exp_wait_coop (
              sales_exp_header_id                 --�̔����уw�b�_ID
            , created_by                          --�쐬��
            , creation_date                       --�쐬��
            , last_updated_by                     --�ŏI�X�V��
            , last_update_date                    --�ŏI�X�V��
            , last_update_login                   --�ŏI�X�V���O�C��
            , request_id                          --�v��ID
            , program_application_id              --�v���O�����A�v���P�[�V����ID
            , program_id                          --�v���O����ID
            , program_update_date                 --�v���O�����X�V��
          ) VALUES ( 
              gt_data_tab(cn_tbl_header_id)                      --�̔����уw�b�_ID
            , cn_created_by                       --�쐬��
            , cd_creation_date                    --�쐬��
            , cn_last_updated_by                  --�ŏI�X�V��
            , cd_last_update_date                 --�ŏI�X�V��
            , cn_last_update_login                --�ŏI�X�V���O�C��
            , cn_request_id                       --�v��ID
            , cn_program_application_id           --�v���O�����A�v���P�[�V����ID
            , cn_program_id                       --�v���O����ID
            , cd_program_update_date              --�v���O�����X�V��
          );
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        --���A�g�o�͌������J�E���g�A�b�v
        gn_out_coop_cnt   :=  gn_out_coop_cnt   +   1;
    END;
--
  EXCEPTION
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
  END ins_sales_exp_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp
   * Description      : �Ώۃf�[�^���o(A-4)
   ***********************************************************************************/
  PROCEDURE get_sales_exp(
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp'; -- �v���O������
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
    lv_errlevel               VARCHAR2(10);
    lt_sales_exp_header_id    xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �̔����сi�蓮���s�j
    CURSOR get_sales_exp_manual_cur
    IS
      SELECT    '1'                                     AS  data_type                           --�f�[�^�^�C�v
              -- XXCOS_SALES_EXP_LINE�i�̔����уw�b�_�j
              , xseh.sales_exp_header_id                AS  sales_exp_header_id                 --�̔����уw�b�_ID
              , xseh.dlv_invoice_number                 AS  dlv_invoice_number                  --�[�i�`�[�ԍ�
              , xseh.order_invoice_number               AS  order_invoice_number                --�����`�[�ԍ�
              , xseh.order_number                       AS  order_number                        --�󒍔ԍ�
              , xseh.order_no_hht                       AS  order_no_hht                        --��No�iHHT)
              , xseh.digestion_ln_number                AS  digestion_ln_number                 --��No�iHHT�j�}��
              , xseh.order_connection_number            AS  order_connection_number             --�󒍊֘A�ԍ�
              , TO_CHAR(xseh.delivery_date, cv_date_format1)
                                                        AS  delivery_date                       --�[�i��
              , TO_CHAR(xseh.orig_delivery_date, cv_date_format1)
                                                        AS  orig_delivery_date                  --�I���W�i���[�i��
              , TO_CHAR(xseh.inspect_date, cv_date_format1)
                                                        AS  inspect_date                        --������
              , TO_CHAR(xseh.orig_inspect_date, cv_date_format1)
                                                        AS  orig_inspect_date                   --�I���W�i��������
              , TO_CHAR(xseh.hht_dlv_input_date, cv_date_format2) 
                                                        AS  hht_dlv_input_date                  --HHT�[�i���͓���
              , TO_CHAR(xseh.business_date, cv_date_format1)                      
                                                        AS  business_date                       --�o�^�Ɩ����t
              , xseh.cust_gyotai_sho                    AS  cust_gyotai_sho                     --�Ƒԏ�����
              ,(SELECT    flv.meaning                   AS  cust_gyotai_sho_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_cust_gyotai_sho
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date        
                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       flv.lookup_code               =         xseh.cust_gyotai_sho)
                                                        AS  cust_gyotai_sho_name                --�Ƒԏ����ޖ���
              , xseh.ship_to_customer_code                                                      --�ڋq�y�[�i��z
              ,(SELECT    hp.party_name                 AS  ship_to_customer_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.ship_to_customer_code )
                                                        AS  ship_to_customer_name               --�ڋq�y�[�i��z����
              , xseh.sale_amount_sum                    AS  sale_amount_sum                     --������z���v
              , xseh.pure_amount_sum                    AS  pure_amount_sum                     --�{�̋��z���v
              , xseh.tax_amount_sum                     AS  tax_amount_sum                      --����ŋ��z���v
              , xseh.consumption_tax_class              AS  consumption_tax_class               --����ŋ敪
              ,(SELECT    flv.meaning                   AS  consumption_tax_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_consumption_tax
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
-- Ver.1.5 Mod Start
--                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date          
--                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.orig_delivery_date
                AND       NVL(flv.end_date_active  , gd_prdate)   >=  xseh.orig_delivery_date
-- Ver.1.5 Mod End
-- Ver.1.4 Mod Start
--                AND       flv.lookup_code               =         xseh.consumption_tax_class)
                AND       flv.attribute3                =         xseh.consumption_tax_class)
-- Ver.1.4 Mod End
                                                        AS  consumption_tax_class_name          --����ŋ敪��
-- 2019/07/16 Ver.1.8 Mod Start
--              , xseh.tax_code                           AS  tax_code                            --�ŋ��R�[�h
--              , xseh.tax_rate                           AS  tax_rate                            --����ŗ�
              , NVL(xsel.tax_code, xseh.tax_code)       AS  tax_code                            --�ŋ��R�[�h
              , NVL(xsel.tax_rate, xseh.tax_rate)       AS  tax_rate                            --����ŗ�
-- 2019/07/16 Ver.1.8 Mod End
              , xseh.results_employee_code              AS  results_employee_code               --���ьv��҃R�[�h
              ,(SELECT    papf.full_name                AS  employee_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.results_employee_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  results_employee_name               --���ьv��Җ�
              , xseh.dlv_by_code                        AS  dlv_by_code                         --�[�i�҃R�[�h
              ,(SELECT    papf.full_name                AS  dlv_by_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.dlv_by_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  dlv_by_name                         --�[�i�Җ� 
              , xseh.sales_base_code                    AS  sales_base_code                     --���㋒�_�R�[�h
              ,(SELECT    hp.party_name                 AS  sales_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.sales_base_code )
                                                        AS  sales_base_name                     --���㋒�_����
              , xseh.receiv_base_code                   AS  receiv_base_code                    --�������_�R�[�h
              ,(SELECT    hp.party_name                 AS  reveiv_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.receiv_base_code )
                                                        AS  reveiv_base_name                    --�������_����
              , xseh.head_sales_branch                  AS  head_sales_branch                   --�Ǌ����_
              ,(SELECT    hp.party_name                 AS  head_sales_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.head_sales_branch )
                                                        AS  head_sales_name                     --�Ǌ����_����
              , xseh.dlv_invoice_class                  AS  dlv_invoice_class                   --�[�i�`�[�敪
              ,(SELECT    flv.meaning                   AS  dlv_invoice_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_slip
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.dlv_invoice_class)
                                                        AS  dlv_invoice_class_name              --�[�i�`�[�敪��
              , xseh.card_sale_class                    AS  card_sale_class                     --�J�[�h����敪
              ,(SELECT    flv.meaning                   AS  card_sale_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_card_sale_class
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.card_sale_class)
                                                        AS  card_sale_class_name                --�J�[�h����敪��
              , xseh.invoice_class                      AS  invoice_class                       --�`�[�敪
              , xseh.invoice_classification_code        AS  invoice_classification_code         --�`�[���ރR�[�h
              , xseh.input_class                        AS  input_class                         --���͋敪
              ,(SELECT    flv.meaning                   AS  input_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_input_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.input_class)
                                                        AS  input_class_name                    --���͋敪��
              , xseh.order_source_id                    AS  order_source_id                     --�󒍃\�[�XID
              , NULL                                    AS  order_source_name                   --�󒍃\�[�X����
              , xseh.change_out_time_100                AS  change_out_time_100                 --��K�؂ꎞ�ԂP�O�O�~
              , xseh.change_out_time_10                 AS  change_out_time_10                  --��K�؂ꎞ�ԂP�O�~
              , xseh.create_class                       AS  create_class                        --�쐬���敪
              ,(SELECT    flv.meaning                   AS  create_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_mk_org_cls_mst
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.create_class)              
                                                        AS  create_class_name                   --�쐬���敪��
              -- XXCOS_SALES_EXP_LINE�i�̔����і��ׁj
              , xsel.sales_exp_line_id                  AS  sales_exp_line_id                   --�̔����і���ID
              , xsel.dlv_invoice_line_number            AS  dlv_invoice_line_number             --�[�i���הԍ�
              , xsel.order_invoice_line_number          AS  order_invoice_line_number           --�������הԍ�
              , xsel.column_no                          AS  column_no                           --�R����No
              , xsel.item_code                          AS  item_code                           --�i�ڃR�[�h
              ,(SELECT      xim.item_name               AS  item_name
                FROM        mtl_system_items_b          msib    --DISC�i�ڃ}�X�^
                          , ic_item_mst_b               iimb    --OPM�i�ڃ}�X�^
                          , xxcmn_item_mst_b            xim     --OPM�i�ڃA�h�I���}�X�^
                WHERE       msib.segment1               =         xsel.item_code
                AND         msib.organization_id        =         gt_organization_id
                AND         msib.segment1               =         iimb.item_no
                AND         iimb.item_id                =         xim.item_id
                AND         xim.start_date_active       <=        xseh.delivery_date
                AND         xim.end_date_active         >=        xseh.delivery_date  )
                                                        AS  item_name                           --�i�ږ���
              , xsel.goods_prod_cls                     AS  goods_prod_cls                      --�i�ڋ敪
              , xsel.dlv_qty                            AS  dlv_qty                             --�[�i����
              , xsel.standard_qty                       AS  standard_qty                        --�����
              , xsel.dlv_uom_code                       AS  dlv_uom_code                        --�[�i�P��
              , xsel.standard_uom_code                  AS  standard_uom_code                   --��P��
              , xsel.dlv_unit_price                     AS  dlv_unit_price                      --�[�i�P��
              , xsel.standard_unit_price                AS  standard_unit_price                 --��P��
              , xsel.standard_unit_price_excluded       AS  standard_unit_price_excluded        --�Ŕ���P��
              , xsel.business_cost                      AS  business_cost                       --�c�ƌ���
              , xsel.sale_amount                        AS  sale_amount                         --������z
              , xsel.pure_amount                        AS  pure_amount                         --�{�̋��z
              , xsel.tax_amount                         AS  tax_amount                          --����ŋ��z
              , xsel.cash_and_card                      AS  cash_and_card                       --�����E�J�[�h���p�z
              , xsel.ship_from_subinventory_code        AS  ship_from_subinventory_code         --�o�׌��ۊǏꏊ
              ,(SELECT    msi.description               AS  ship_from_subinventory_name
                FROM      mtl_secondary_inventories     msi
                WHERE     msi.secondary_inventory_name  =       xsel.ship_from_subinventory_code
                AND       msi.organization_id           =       gt_organization_id)         
                                                        AS  ship_from_subinventory_name         --�o�׌��ۊǏꏊ����
              , xsel.delivery_base_code                 AS  delivery_base_code                  --�[�i���_�R�[�h
              ,(SELECT    hp.party_name                 AS  delivery_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xsel.delivery_base_code )
                                                        AS  delivery_base_name                  --�[�i���_����
              , xsel.sales_class                        AS  sales_class                         --����敪
              ,(SELECT    flv.meaning                   AS  sales_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sale_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sales_class) 
                                                        AS  sales_class_name                    --����敪����
              , xsel.delivery_pattern_class             AS  delivery_pattern_class              --�[�i�`�ԋ敪
              ,(SELECT    flv.meaning                   AS  delivery_pattern
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_pattern
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.delivery_pattern_class)
                                                        AS  delivery_pattern                    --�[�i�`�ԋ敪����
              , xsel.red_black_flag                     AS  red_black_flag                      --�ԍ��t���O
              ,(SELECT    flv.meaning                   AS  red_black_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_red_black_flag
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.red_black_flag)
                                                        AS  red_black_name                      --�ԍ�����
              , xsel.hot_cold_class                     AS  hot_cold_class                      --�g���b
              ,(SELECT    flv.meaning                   AS  hot_cold_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_hc_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.hot_cold_class)
                                                        AS  hot_cold_class_name                 --�g���b����
              , xsel.sold_out_class                     AS  sold_out_class                      --���؋敪
              ,(SELECT    flv.meaning                   AS  sold_out_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sold_out_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sold_out_class)
                                                        AS  sold_out_class_name                 --���؋敪����
              , xsel.sold_out_time                      AS  sold_out_time                       --���؎���
              , NULL                                    AS  inv_txn_type                        --INV����^�C�v
              , NULL                                    AS  customer_trx_id                     --AR���ID
              , NULL                                    AS  trx_number                          --AR�������i����j�ԍ�
              , NULL                                    as  doc_sequence_value                  --�����������ԍ�
              , NULL                                    as  trx_type                            --AR����^�C�v
              , NULL                                    as  bill_to_customer_name               --�ڋq�����掖�Ə���
              , gv_coop_date                            AS  coop_date                           --�A�g����
              , xseh.ar_interface_flag                  AS  ar_interface_flag                   --AR�C���^�t�F�[�X�σt���O
              , xseh.gl_interface_flag                  AS  gl_interface_flag                   --GL�C���^�t�F�[�X�σt���O
              , xsel.inv_interface_flag                 AS  inv_interface_flag                  --INV�C���^�t�F�[�X�σt���O
      FROM      xxcos_sales_exp_headers                 xseh                                    --�̔����уw�b�_
              , xxcos_sales_exp_lines                   xsel                                    --�̔����і���
      WHERE     xseh.sales_exp_header_id                =         xsel.sales_exp_header_id
      AND       xseh.sales_exp_header_id                >=        gt_id_from
      AND       xseh.sales_exp_header_id                <=        gt_id_to
-- 2016/10/21 Ver.1.7 Add Start
      AND       xseh.create_class                       <>        cv_create_class               --�ϑ��̔����шȊO
-- 2016/10/21 Ver.1.7 Add End
      ORDER BY  data_type
              , sales_exp_header_id
    ;
    -- �̔����сi������s�j
    CURSOR get_sales_exp_fixed_cur
    IS
-- 2012/12/18 Ver.1.3 Mod Start
--      SELECT    '1'                                     AS  data_type                           --�f�[�^�^�C�v
      -- �Ǘ��e�[�u������̑Ώۃf�[�^
      SELECT  /*+ LEADING(xseh) USE_NL(xseh xsel) INDEX(xseh XXCOS_SALES_EXP_HEADERS_PK) */
                '1'                                     AS  data_type                           --�f�[�^�^�C�v
-- 2012/12/18 Ver.1.3 Mod End
              -- XXCOS_SALES_EXP_LINE�i�̔����уw�b�_�j
              , xseh.sales_exp_header_id                AS  sales_exp_header_id                 --�̔����уw�b�_ID
              , xseh.dlv_invoice_number                 AS  dlv_invoice_number                  --�[�i�`�[�ԍ�
              , xseh.order_invoice_number               AS  order_invoice_number                --�����`�[�ԍ�
              , xseh.order_number                       AS  order_number                        --�󒍔ԍ�
              , xseh.order_no_hht                       AS  order_no_hht                        --��No�iHHT)
              , xseh.digestion_ln_number                AS  digestion_ln_number                 --��No�iHHT�j�}��
              , xseh.order_connection_number            AS  order_connection_number             --�󒍊֘A�ԍ�
              , TO_CHAR(xseh.delivery_date, cv_date_format1)
                                                        AS  delivery_date                       --�[�i��
              , TO_CHAR(xseh.orig_delivery_date, cv_date_format1)
                                                        AS  orig_delivery_date                  --�I���W�i���[�i��
              , TO_CHAR(xseh.inspect_date, cv_date_format1)
                                                        AS  inspect_date                        --������
              , TO_CHAR(xseh.orig_inspect_date, cv_date_format1)
                                                        AS  orig_inspect_date                   --�I���W�i��������
              , TO_CHAR(xseh.hht_dlv_input_date, cv_date_format2) 
                                                        AS  hht_dlv_input_date                  --HHT�[�i���͓���
              , TO_CHAR(xseh.business_date, cv_date_format1)                      
                                                        AS  business_date                       --�o�^�Ɩ����t
              , xseh.cust_gyotai_sho                    AS  cust_gyotai_sho                     --�Ƒԏ�����
              ,(SELECT    flv.meaning                   AS  cust_gyotai_sho_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_cust_gyotai_sho
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date        
                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       flv.lookup_code               =         xseh.cust_gyotai_sho)
                                                        AS  cust_gyotai_sho_name                --�Ƒԏ����ޖ���
              , xseh.ship_to_customer_code                                                      --�ڋq�y�[�i��z
              ,(SELECT    hp.party_name                 AS  ship_to_customer_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.ship_to_customer_code )
                                                        AS  ship_to_customer_name               --�ڋq�y�[�i��z����
              , xseh.sale_amount_sum                    AS  sale_amount_sum                     --������z���v
              , xseh.pure_amount_sum                    AS  pure_amount_sum                     --�{�̋��z���v
              , xseh.tax_amount_sum                     AS  tax_amount_sum                      --����ŋ��z���v
              , xseh.consumption_tax_class              AS  consumption_tax_class               --����ŋ敪
              ,(SELECT    flv.meaning                   AS  consumption_tax_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_consumption_tax
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
-- Ver.1.5 Mod Start
--                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date          
--                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.orig_delivery_date
                AND       NVL(flv.end_date_active  , gd_prdate)   >=  xseh.orig_delivery_date
-- Ver.1.5 Mod End
-- Ver.1.4 Mod Start
--                AND       flv.lookup_code               =         xseh.consumption_tax_class)
                AND       flv.attribute3                =         xseh.consumption_tax_class)
-- Ver.1.4 Mod End
                                                        AS  consumption_tax_class_name          --����ŋ敪��
-- 2019/07/16 Ver.1.8 Mod Start
--              , xseh.tax_code                           AS  tax_code                            --�ŋ��R�[�h
--              , xseh.tax_rate                           AS  tax_rate                            --����ŗ�
              , NVL(xsel.tax_code, xseh.tax_code)       AS  tax_code                            --�ŋ��R�[�h
              , NVL(xsel.tax_rate, xseh.tax_rate)       AS  tax_rate                            --����ŗ�
-- 2019/07/16 Ver.1.8 Mod End
              , xseh.results_employee_code              AS  results_employee_code               --���ьv��҃R�[�h
              ,(SELECT    papf.full_name                AS  employee_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.results_employee_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  results_employee_name               --���ьv��Җ�
              , xseh.dlv_by_code                        AS  dlv_by_code                         --�[�i�҃R�[�h
              ,(SELECT    papf.full_name                AS  dlv_by_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.dlv_by_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  dlv_by_name                         --�[�i�Җ� 
              , xseh.sales_base_code                    AS  sales_base_code                     --���㋒�_�R�[�h
              ,(SELECT    hp.party_name                 AS  sales_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.sales_base_code )
                                                        AS  sales_base_name                     --���㋒�_����
              , xseh.receiv_base_code                   AS  receiv_base_code                    --�������_�R�[�h
              ,(SELECT    hp.party_name                 AS  reveiv_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.receiv_base_code )
                                                        AS  reveiv_base_name                    --�������_����
              , xseh.head_sales_branch                  AS  head_sales_branch                   --�Ǌ����_
              ,(SELECT    hp.party_name                 AS  head_sales_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.head_sales_branch )
                                                        AS  head_sales_name                     --�Ǌ����_����
              , xseh.dlv_invoice_class                  AS  dlv_invoice_class                   --�[�i�`�[�敪
              ,(SELECT    flv.meaning                   AS  dlv_invoice_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_slip
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.dlv_invoice_class)
                                                        AS  dlv_invoice_class_name              --�[�i�`�[�敪��
              , xseh.card_sale_class                    AS  card_sale_class                     --�J�[�h����敪
              ,(SELECT    flv.meaning                   AS  card_sale_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_card_sale_class
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.card_sale_class)
                                                        AS  card_sale_class_name                --�J�[�h����敪��
              , xseh.invoice_class                      AS  invoice_class                       --�`�[�敪
              , xseh.invoice_classification_code        AS  invoice_classification_code         --�`�[���ރR�[�h
              , xseh.input_class                        AS  input_class                         --���͋敪
              ,(SELECT    flv.meaning                   AS  input_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_input_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.input_class)
                                                        AS  input_class_name                    --���͋敪��
              , xseh.order_source_id                    AS  order_source_id                     --�󒍃\�[�XID
              , NULL                                    AS  order_source_name                   --�󒍃\�[�X����
              , xseh.change_out_time_100                AS  change_out_time_100                 --��K�؂ꎞ�ԂP�O�O�~
              , xseh.change_out_time_10                 AS  change_out_time_10                  --��K�؂ꎞ�ԂP�O�~
              , xseh.create_class                       AS  create_class                        --�쐬���敪
              ,(SELECT    flv.meaning                   AS  create_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_mk_org_cls_mst
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.create_class)              
                                                        AS  create_class_name                   --�쐬���敪��
              -- XXCOS_SALES_EXP_LINE�i�̔����і��ׁj
              , xsel.sales_exp_line_id                  AS  sales_exp_line_id                   --�̔����і���ID
              , xsel.dlv_invoice_line_number            AS  dlv_invoice_line_number             --�[�i���הԍ�
              , xsel.order_invoice_line_number          AS  order_invoice_line_number           --�������הԍ�
              , xsel.column_no                          AS  column_no                           --�R����No
              , xsel.item_code                          AS  item_code                           --�i�ڃR�[�h
              ,(SELECT      xim.item_name               AS  item_name
                FROM        mtl_system_items_b          msib    --DISC�i�ڃ}�X�^
                          , ic_item_mst_b               iimb    --OPM�i�ڃ}�X�^
                          , xxcmn_item_mst_b            xim     --OPM�i�ڃA�h�I���}�X�^
                WHERE       msib.segment1               =         xsel.item_code
                AND         msib.organization_id        =         gt_organization_id
                AND         msib.segment1               =         iimb.item_no
                AND         iimb.item_id                =         xim.item_id
                AND         xim.start_date_active       <=        xseh.delivery_date
                AND         xim.end_date_active         >=        xseh.delivery_date  )
                                                        AS  item_name                           --�i�ږ���
              , xsel.goods_prod_cls                     AS  goods_prod_cls                      --�i�ڋ敪
              , xsel.dlv_qty                            AS  dlv_qty                             --�[�i����
              , xsel.standard_qty                       AS  standard_qty                        --�����
              , xsel.dlv_uom_code                       AS  dlv_uom_code                        --�[�i�P��
              , xsel.standard_uom_code                  AS  standard_uom_code                   --��P��
              , xsel.dlv_unit_price                     AS  dlv_unit_price                      --�[�i�P��
              , xsel.standard_unit_price                AS  standard_unit_price                 --��P��
              , xsel.standard_unit_price_excluded       AS  standard_unit_price_excluded        --�Ŕ���P��
              , xsel.business_cost                      AS  business_cost                       --�c�ƌ���
              , xsel.sale_amount                        AS  sale_amount                         --������z
              , xsel.pure_amount                        AS  pure_amount                         --�{�̋��z
              , xsel.tax_amount                         AS  tax_amount                          --����ŋ��z
              , xsel.cash_and_card                      AS  cash_and_card                       --�����E�J�[�h���p�z
              , xsel.ship_from_subinventory_code        AS  ship_from_subinventory_code         --�o�׌��ۊǏꏊ
              ,(SELECT    msi.description               AS  ship_from_subinventory_name
                FROM      mtl_secondary_inventories     msi
                WHERE     msi.secondary_inventory_name  =       xsel.ship_from_subinventory_code
                AND       msi.organization_id           =       gt_organization_id)         
                                                        AS  ship_from_subinventory_name         --�o�׌��ۊǏꏊ����
              , xsel.delivery_base_code                 AS  delivery_base_code                  --�[�i���_�R�[�h
              ,(SELECT    hp.party_name                 AS  delivery_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xsel.delivery_base_code )
                                                        AS  delivery_base_name                  --�[�i���_����
              , xsel.sales_class                        AS  sales_class                         --����敪
              ,(SELECT    flv.meaning                   AS  sales_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sale_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sales_class) 
                                                        AS  sales_class_name                    --����敪����
              , xsel.delivery_pattern_class             AS  delivery_pattern_class              --�[�i�`�ԋ敪
              ,(SELECT    flv.meaning                   AS  delivery_pattern
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_pattern
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.delivery_pattern_class)
                                                        AS  delivery_pattern                    --�[�i�`�ԋ敪����
              , xsel.red_black_flag                     AS  red_black_flag                      --�ԍ��t���O
              ,(SELECT    flv.meaning                   AS  red_black_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_red_black_flag
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.red_black_flag)
                                                        AS  red_black_name                      --�ԍ�����
              , xsel.hot_cold_class                     AS  hot_cold_class                      --�g���b
              ,(SELECT    flv.meaning                   AS  hot_cold_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_hc_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.hot_cold_class)
                                                        AS  hot_cold_class_name                 --�g���b����
              , xsel.sold_out_class                     AS  sold_out_class                      --���؋敪
              ,(SELECT    flv.meaning                   AS  sold_out_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sold_out_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sold_out_class)
                                                        AS  sold_out_class_name                 --���؋敪����
              , xsel.sold_out_time                      AS  sold_out_time                       --���؎���
              , NULL                                    AS  inv_txn_type                        --INV����^�C�v
              , NULL                                    AS  customer_trx_id                     --AR���ID
              , NULL                                    AS  trx_number                          --AR�������i����j�ԍ�
              , NULL                                    as  doc_sequence_value                  --�����������ԍ�
              , NULL                                    as  trx_type                            --AR����^�C�v
              , NULL                                    as  bill_to_customer_name               --�ڋq�����掖�Ə���
              , gv_coop_date                            AS  coop_date                           --�A�g����
              , xseh.ar_interface_flag                  AS  ar_interface_flag                   --AR�C���^�t�F�[�X�σt���O
              , xseh.gl_interface_flag                  AS  gl_interface_flag                   --GL�C���^�t�F�[�X�σt���O
              , xsel.inv_interface_flag                 AS  inv_interface_flag                  --INV�C���^�t�F�[�X�σt���O
      FROM      xxcos_sales_exp_headers                 xseh                                    -- �̔����уw�b�_
              , xxcos_sales_exp_lines                   xsel                                    -- �̔����і���
      WHERE     xseh.sales_exp_header_id                =         xsel.sales_exp_header_id
      AND       xseh.sales_exp_header_id                >=        gt_id_from + 1
      AND       xseh.sales_exp_header_id                <=        gt_id_to  
-- 2016/10/21 Ver.1.7 Add Start
      AND       xseh.create_class                       <>        cv_create_class               -- �ϑ��̔����шȊO
-- 2016/10/21 Ver.1.7 Add End
      UNION ALL
-- 2012/12/18 Ver.1.3 Mod Start
--      SELECT    '2'                                     AS  data_type                           --�f�[�^�^�C�v�i���A�g�j
      -- ���A�g�e�[�u������̑Ώۃf�[�^
      SELECT  /*+ LEADING(xsew xseh xsel) USE_NL(xsew xseh xsel)   */
                '2'                                     AS  data_type                           --�f�[�^�^�C�v�i���A�g�j
-- 2012/12/18 Ver.1.3 Mod End
              -- XXCOS_SALES_EXP_LINE�i�̔����уw�b�_�j
              , xseh.sales_exp_header_id                AS  sales_exp_header_id                 --�̔����уw�b�_ID
              , xseh.dlv_invoice_number                 AS  dlv_invoice_number                  --�[�i�`�[�ԍ�
              , xseh.order_invoice_number               AS  order_invoice_number                --�����`�[�ԍ�
              , xseh.order_number                       AS  order_number                        --�󒍔ԍ�
              , xseh.order_no_hht                       AS  order_no_hht                        --��No�iHHT)
              , xseh.digestion_ln_number                AS  digestion_ln_number                 --��No�iHHT�j�}��
              , xseh.order_connection_number            AS  order_connection_number             --�󒍊֘A�ԍ�
              , TO_CHAR(xseh.delivery_date, cv_date_format1)
                                                        AS  delivery_date                       --�[�i��
              , TO_CHAR(xseh.orig_delivery_date, cv_date_format1)
                                                        AS  orig_delivery_date                  --�I���W�i���[�i��
              , TO_CHAR(xseh.inspect_date, cv_date_format1)
                                                        AS  inspect_date                        --������
              , TO_CHAR(xseh.orig_inspect_date, cv_date_format1)
                                                        AS  orig_inspect_date                   --�I���W�i��������
              , TO_CHAR(xseh.hht_dlv_input_date, cv_date_format2) 
                                                        AS  hht_dlv_input_date                  --HHT�[�i���͓���
              , TO_CHAR(xseh.business_date, cv_date_format1)                      
                                                        AS  business_date                       --�o�^�Ɩ����t
              , xseh.cust_gyotai_sho                    AS  cust_gyotai_sho                     --�Ƒԏ�����
              ,(SELECT    flv.meaning                   AS  cust_gyotai_sho_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_cust_gyotai_sho
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date        
                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       flv.lookup_code               =         xseh.cust_gyotai_sho)
                                                        AS  cust_gyotai_sho_name                --�Ƒԏ����ޖ���
              , xseh.ship_to_customer_code                                                      --�ڋq�y�[�i��z
              ,(SELECT    hp.party_name                 AS  ship_to_customer_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.ship_to_customer_code )
                                                        AS  ship_to_customer_name               --�ڋq�y�[�i��z����
              , xseh.sale_amount_sum                    AS  sale_amount_sum                     --������z���v
              , xseh.pure_amount_sum                    AS  pure_amount_sum                     --�{�̋��z���v
              , xseh.tax_amount_sum                     AS  tax_amount_sum                      --����ŋ��z���v
              , xseh.consumption_tax_class              AS  consumption_tax_class               --����ŋ敪
              ,(SELECT    flv.meaning                   AS  consumption_tax_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_consumption_tax
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
-- Ver.1.5 Mod Start
--                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date          
--                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.orig_delivery_date
                AND       NVL(flv.end_date_active  , gd_prdate)   >=  xseh.orig_delivery_date
-- Ver.1.5 Mod End
-- Ver.1.4 Mod Start
--                AND       flv.lookup_code               =         xseh.consumption_tax_class)
                AND       flv.attribute3                =         xseh.consumption_tax_class)
-- Ver.1.4 Mod End
                                                        AS  consumption_tax_class_name          --����ŋ敪��
-- 2019/07/16 Ver.1.8 Mod Start
--              , xseh.tax_code                           AS  tax_code                            --�ŋ��R�[�h
--              , xseh.tax_rate                           AS  tax_rate                            --����ŗ�
              , NVL(xsel.tax_code, xseh.tax_code)       AS  tax_code                            --�ŋ��R�[�h
              , NVL(xsel.tax_rate, xseh.tax_rate)       AS  tax_rate                            --����ŗ�
-- 2019/07/16 Ver.1.8 Mod End
              , xseh.results_employee_code              AS  results_employee_code               --���ьv��҃R�[�h
              ,(SELECT    papf.full_name                AS  employee_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.results_employee_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  results_employee_name               --���ьv��Җ�
              , xseh.dlv_by_code                        AS  dlv_by_code                         --�[�i�҃R�[�h
              ,(SELECT    papf.full_name                AS  dlv_by_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.dlv_by_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  dlv_by_name                         --�[�i�Җ� 
              , xseh.sales_base_code                    AS  sales_base_code                     --���㋒�_�R�[�h
              ,(SELECT    hp.party_name                 AS  sales_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.sales_base_code )
                                                        AS  sales_base_name                     --���㋒�_����
              , xseh.receiv_base_code                   AS  receiv_base_code                    --�������_�R�[�h
              ,(SELECT    hp.party_name                 AS  reveiv_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.receiv_base_code )
                                                        AS  reveiv_base_name                    --�������_����
              , xseh.head_sales_branch                  AS  head_sales_branch                   --�Ǌ����_
              ,(SELECT    hp.party_name                 AS  head_sales_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.head_sales_branch )
                                                        AS  head_sales_name                     --�Ǌ����_����
              , xseh.dlv_invoice_class                  AS  dlv_invoice_class                   --�[�i�`�[�敪
              ,(SELECT    flv.meaning                   AS  dlv_invoice_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_slip
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.dlv_invoice_class)
                                                        AS  dlv_invoice_class_name              --�[�i�`�[�敪��
              , xseh.card_sale_class                    AS  card_sale_class                     --�J�[�h����敪
              ,(SELECT    flv.meaning                   AS  card_sale_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_card_sale_class
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.card_sale_class)
                                                        AS  card_sale_class_name                --�J�[�h����敪��
              , xseh.invoice_class                      AS  invoice_class                       --�`�[�敪
              , xseh.invoice_classification_code        AS  invoice_classification_code         --�`�[���ރR�[�h
              , xseh.input_class                        AS  input_class                         --���͋敪
              ,(SELECT    flv.meaning                   AS  input_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_input_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.input_class)
                                                        AS  input_class_name                    --���͋敪��
              , xseh.order_source_id                    AS  order_source_id                     --�󒍃\�[�XID
              , NULL                                    AS  order_source_name                   --�󒍃\�[�X����
              , xseh.change_out_time_100                AS  change_out_time_100                 --��K�؂ꎞ�ԂP�O�O�~
              , xseh.change_out_time_10                 AS  change_out_time_10                  --��K�؂ꎞ�ԂP�O�~
              , xseh.create_class                       AS  create_class                        --�쐬���敪
              ,(SELECT    flv.meaning                   AS  create_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_mk_org_cls_mst
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.create_class)              
                                                        AS  create_class_name                   --�쐬���敪��
              -- XXCOS_SALES_EXP_LINE�i�̔����і��ׁj
              , xsel.sales_exp_line_id                  AS  sales_exp_line_id                   --�̔����і���ID
              , xsel.dlv_invoice_line_number            AS  dlv_invoice_line_number             --�[�i���הԍ�
              , xsel.order_invoice_line_number          AS  order_invoice_line_number           --�������הԍ�
              , xsel.column_no                          AS  column_no                           --�R����No
              , xsel.item_code                          AS  item_code                           --�i�ڃR�[�h
              ,(SELECT      xim.item_name               AS  item_name
                FROM        mtl_system_items_b          msib    --DISC�i�ڃ}�X�^
                          , ic_item_mst_b               iimb    --OPM�i�ڃ}�X�^
                          , xxcmn_item_mst_b            xim     --OPM�i�ڃA�h�I���}�X�^
                WHERE       msib.segment1               =         xsel.item_code
                AND         msib.organization_id        =         gt_organization_id
                AND         msib.segment1               =         iimb.item_no
                AND         iimb.item_id                =         xim.item_id
                AND         xim.start_date_active       <=        xseh.delivery_date
                AND         xim.end_date_active         >=        xseh.delivery_date  )
                                                        AS  item_name                           --�i�ږ���
              , xsel.goods_prod_cls                     AS  goods_prod_cls                      --�i�ڋ敪
              , xsel.dlv_qty                            AS  dlv_qty                             --�[�i����
              , xsel.standard_qty                       AS  standard_qty                        --�����
              , xsel.dlv_uom_code                       AS  dlv_uom_code                        --�[�i�P��
              , xsel.standard_uom_code                  AS  standard_uom_code                   --��P��
              , xsel.dlv_unit_price                     AS  dlv_unit_price                      --�[�i�P��
              , xsel.standard_unit_price                AS  standard_unit_price                 --��P��
              , xsel.standard_unit_price_excluded       AS  standard_unit_price_excluded        --�Ŕ���P��
              , xsel.business_cost                      AS  business_cost                       --�c�ƌ���
              , xsel.sale_amount                        AS  sale_amount                         --������z
              , xsel.pure_amount                        AS  pure_amount                         --�{�̋��z
              , xsel.tax_amount                         AS  tax_amount                          --����ŋ��z
              , xsel.cash_and_card                      AS  cash_and_card                       --�����E�J�[�h���p�z
              , xsel.ship_from_subinventory_code        AS  ship_from_subinventory_code         --�o�׌��ۊǏꏊ
              ,(SELECT    msi.description               AS  ship_from_subinventory_name
                FROM      mtl_secondary_inventories     msi
                WHERE     msi.secondary_inventory_name  =       xsel.ship_from_subinventory_code
                AND       msi.organization_id           =       gt_organization_id)         
                                                        AS  ship_from_subinventory_name         --�o�׌��ۊǏꏊ����
              , xsel.delivery_base_code                 AS  delivery_base_code                  --�[�i���_�R�[�h
              ,(SELECT    hp.party_name                 AS  delivery_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xsel.delivery_base_code )
                                                        AS  delivery_base_name                  --�[�i���_����
              , xsel.sales_class                        AS  sales_class                         --����敪
              ,(SELECT    flv.meaning                   AS  sales_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sale_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sales_class) 
                                                        AS  sales_class_name                    --����敪����
              , xsel.delivery_pattern_class             AS  delivery_pattern_class              --�[�i�`�ԋ敪
              ,(SELECT    flv.meaning                   AS  delivery_pattern
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_pattern
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.delivery_pattern_class)
                                                        AS  delivery_pattern                    --�[�i�`�ԋ敪����
              , xsel.red_black_flag                     AS  red_black_flag                      --�ԍ��t���O
              ,(SELECT    flv.meaning                   AS  red_black_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_red_black_flag
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.red_black_flag)
                                                        AS  red_black_name                      --�ԍ�����
              , xsel.hot_cold_class                     AS  hot_cold_class                      --�g���b
              ,(SELECT    flv.meaning                   AS  hot_cold_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_hc_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.hot_cold_class)
                                                        AS  hot_cold_class_name                 --�g���b����
              , xsel.sold_out_class                     AS  sold_out_class                      --���؋敪
              ,(SELECT    flv.meaning                   AS  sold_out_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sold_out_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sold_out_class)
                                                        AS  sold_out_class_name                 --���؋敪����
              , xsel.sold_out_time                      AS  sold_out_time                       --���؎���
              , NULL                                    AS  inv_txn_type                        --INV����^�C�v
              , NULL                                    AS  customer_trx_id                     --AR���ID
              , NULL                                    AS  trx_number                          --AR�������i����j�ԍ�
              , NULL                                    as  doc_sequence_value                  --�����������ԍ�
              , NULL                                    as  trx_type                            --AR����^�C�v
              , NULL                                    as  bill_to_customer_name               --�ڋq�����掖�Ə���
              , gv_coop_date                            AS  coop_date                           --�A�g����
              , xseh.ar_interface_flag                  AS  ar_interface_flag                   --AR�C���^�t�F�[�X�σt���O
              , xseh.gl_interface_flag                  AS  gl_interface_flag                   --GL�C���^�t�F�[�X�σt���O
              , xsel.inv_interface_flag                 AS  inv_interface_flag                  --INV�C���^�t�F�[�X�σt���O
      FROM      xxcos_sales_exp_headers                 xseh                                    -- �̔����уw�b�_
              , xxcos_sales_exp_lines                   xsel                                    -- �̔����і���
              ,(SELECT    DISTINCT
                          xsewc.sales_exp_header_id
                FROM      xxcfo_sales_exp_wait_coop     xsewc)    xsew
      WHERE     xseh.sales_exp_header_id                =         xsel.sales_exp_header_id
      AND       xseh.sales_exp_header_id                =         xsew.sales_exp_header_id
-- 2016/10/21 Ver.1.7 Add Start
      AND       xseh.create_class                       <>        cv_create_class               -- �ϑ��̔����шȊO
-- 2016/10/21 Ver.1.7 Add End
      ORDER BY  data_type
              , sales_exp_header_id
    ;
    --
    skip_record_manual_expt   EXCEPTION;
    skip_record_fixed_expt    EXCEPTION;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    gt_sales_exp_tab.DELETE;
    gb_csv_out              :=  TRUE;             --CSV�o��
    lt_sales_exp_header_id  :=  NULL;             --�̔����уw�b�_ID
    --==============================================================
    -- 1 �蓮���s�̏ꍇ
    --==============================================================
    IF ( gv_exec_mode         =     cv_exec_manual )  THEN  
      OPEN  get_sales_exp_manual_cur;   
      <<get_ales_exp_manual_loop>>   
      LOOP
        FETCH   get_sales_exp_manual_cur      INTO      
            gt_data_type                          --�f�[�^�^�C�v
          , gt_data_tab(1)                        --�̔����уw�b�_ID
          , gt_data_tab(2)                        --�[�i�`�[�ԍ�
          , gt_data_tab(3)                        --�����`�[�ԍ�
          , gt_data_tab(4)                        --�󒍔ԍ�
          , gt_data_tab(5)                        --��No�iHHT)
          , gt_data_tab(6)                        --��No�iHHT�j�}��
          , gt_data_tab(7)                        --�󒍊֘A�ԍ�
          , gt_data_tab(8)                        --�[�i��
          , gt_data_tab(9)                        --�I���W�i���[�i��
          , gt_data_tab(10)                       --������
          , gt_data_tab(11)                       --�I���W�i��������
          , gt_data_tab(12)                       --HHT�[�i���͓���
          , gt_data_tab(13)                       --�o�^�Ɩ����t
          , gt_data_tab(14)                       --�Ƒԏ�����
          , gt_data_tab(15)                       --�Ƒԏ����ޖ���
          , gt_data_tab(16)                       --�ڋq�y�[�i��z
          , gt_data_tab(17)                       --�ڋq���y�[�i��z
          , gt_data_tab(18)                       --������z���v
          , gt_data_tab(19)                       --�{�̋��z���v
          , gt_data_tab(20)                       --����ŋ��z���v
          , gt_data_tab(21)                       --����ŋ敪
          , gt_data_tab(22)                       --����ŋ敪��
          , gt_data_tab(23)                       --�ŋ��R�[�h
          , gt_data_tab(24)                       --����ŗ�
          , gt_data_tab(25)                       --���ьv��҃R�[�h
          , gt_data_tab(26)                       --���ьv��Җ�
          , gt_data_tab(27)                       --�[�i�҃R�[�h
          , gt_data_tab(28)                       --�[�i�Җ�
          , gt_data_tab(29)                       --���㋒�_�R�[�h
          , gt_data_tab(30)                       --���㋒�_����
          , gt_data_tab(31)                       --�������_�R�[�h
          , gt_data_tab(32)                       --�������_����
          , gt_data_tab(33)                       --�Ǌ����_�R�[�h
          , gt_data_tab(34)                       --�Ǌ����_����
          , gt_data_tab(35)                       --�[�i�`�[�敪
          , gt_data_tab(36)                       --�[�i�`�[�敪����
          , gt_data_tab(37)                       --�J�[�h����敪
          , gt_data_tab(38)                       --�J�[�h����敪����
          , gt_data_tab(39)                       --�`�[�敪
          , gt_data_tab(40)                       --�`�[���ރR�[�h
          , gt_data_tab(41)                       --���͋敪
          , gt_data_tab(42)                       --���͋敪����
          , gt_data_tab(43)                       --�󒍃\�[�XID
          , gt_data_tab(44)                       --�󒍃\�[�X����
          , gt_data_tab(45)                       --��K�؂ꎞ�ԂP�O�O�~
          , gt_data_tab(46)                       --��K�؂ꎞ�ԂP�O�~
          , gt_data_tab(47)                       --�쐬���敪
          , gt_data_tab(48)                       --�쐬���敪����
          , gt_data_tab(49)                       --�̔����і���ID
          , gt_data_tab(50)                       --�[�i���הԍ�
          , gt_data_tab(51)                       --�������הԍ�
          , gt_data_tab(52)                       --�R����No
          , gt_data_tab(53)                       --�i�ڃR�[�h
          , gt_data_tab(54)                       --�i�ږ���
          , gt_data_tab(55)                       --�i�ڋ敪
          , gt_data_tab(56)                       --�[�i����
          , gt_data_tab(57)                       --�����
          , gt_data_tab(58)                       --�[�i�P��
          , gt_data_tab(59)                       --��P��
          , gt_data_tab(60)                       --�[�i�P��
          , gt_data_tab(61)                       --��P��
          , gt_data_tab(62)                       --�Ŕ���P��
          , gt_data_tab(63)                       --�c�ƌ���
          , gt_data_tab(64)                       --������z
          , gt_data_tab(65)                       --�{�̋��z
          , gt_data_tab(66)                       --����ŋ��z
          , gt_data_tab(67)                       --�����E�J�[�h���p�z
          , gt_data_tab(68)                       --�o�׌��ۊǏꏊ
          , gt_data_tab(69)                       --�ۊǏꏊ����
          , gt_data_tab(70)                       --�[�i���_�R�[�h
          , gt_data_tab(71)                       --�[�i���_����
          , gt_data_tab(72)                       --����敪
          , gt_data_tab(73)                       --����敪����
          , gt_data_tab(74)                       --�[�i�`�ԋ敪
          , gt_data_tab(75)                       --�[�i�`�ԋ敪����
          , gt_data_tab(76)                       --�ԍ��t���O
          , gt_data_tab(77)                       --�ԍ��t���O����
          , gt_data_tab(78)                       --�g���b
          , gt_data_tab(79)                       --�g���b����
          , gt_data_tab(80)                       --���؋敪
          , gt_data_tab(81)                       --���؋敪����
          , gt_data_tab(82)                       --���؎���
          , gt_data_tab(83)                       --INV����^�C�v
          , gt_data_tab(84)                       --AR���ID
          , gt_data_tab(85)                       --AR�������i����j�ԍ�
          , gt_data_tab(86)                       --�����������ԍ�
          , gt_data_tab(87)                       --AR����^�C�v
          , gt_data_tab(88)                       --�ڋq�����掖�Ə���
          , gt_data_tab(89)                       --�A�g����
          , gt_ar_interface_flag                  --AR�C���^�[�t�F�[�X�t���O
          , gt_gl_interface_flag                  --GL�C���^�[�t�F�[�X�t���O
          , gt_inv_interface_flag                 --INV�C���^�[�t�F�[�X�t���O
          ;
        EXIT WHEN get_sales_exp_manual_cur%NOTFOUND;        
        --
        gn_target_cnt   :=  gn_target_cnt   +   1;
        --
        IF ( gt_sales_exp_header_id     <>    gt_data_tab(cn_tbl_header_id) )   THEN
          IF  ( gt_sales_exp_tab.COUNT  >       0    ) 
          AND ( gb_csv_out              =       TRUE )  
          THEN
            --==============================================================
            -- CSV�o�͏���(A-7)  �̔����уw�b�_���قȂ�ꍇ
            --==============================================================
            out_csv (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode             <>        cv_status_normal )  THEN
              RAISE   global_process_expt;
            END IF;
          END IF;
          --
          gt_sales_exp_tab.DELETE;
          gb_csv_out    :=  TRUE;
          lv_errlevel   :=  NULL;
          --
        END IF;
        --
        gt_sales_exp_header_id  :=  gt_data_tab(cn_tbl_header_id);
        --
        IF  ( lv_errlevel               IS        NULL )                        --����̏ꍇ
        OR  ( lv_errlevel               =         cv_errlevel_header            --�w�b�_�P�ʂŃX�L�b�v
        AND   lt_sales_exp_header_id    <>        gt_data_tab(cn_tbl_header_id) )
        OR  ( lv_errlevel               =         cv_errlevel_line )            --���ׂ̏����͍s��
        THEN    
          lv_errlevel   :=  NULL;
          --==============================================================
          -- �t�����擾����(A-5)
          --==============================================================
          get_flex_information (
              ov_errlevel               =>        lv_errlevel
            , ov_errbuf                 =>        lv_errbuf
            , ov_retcode                =>        lv_retcode
            , ov_errmsg                 =>        lv_errmsg
            );
          --
          IF ( lv_retcode               <>        cv_status_normal )  THEN
            RAISE   global_process_expt;
          END IF;
          --==============================================================
          -- ���ڃ`�F�b�N����(A-6)
          --==============================================================
          chk_item (
              ov_errlevel               =>        lv_errlevel
            , ov_errbuf                 =>        lv_errbuf
            , ov_retcode                =>        lv_retcode
            , ov_errmsg                 =>        lv_errmsg
            );
          --
          IF ( lv_retcode               =         cv_status_normal )  THEN
            --==============================================================
            -- ����ȃf�[�^��ޔ�
            --==============================================================
            gt_sales_exp_tab(NVL(gt_sales_exp_tab.COUNT, 0) + 1)  :=  gt_data_tab;
            --
          ELSIF ( lv_retcode            =         cv_status_warn )  THEN
            gb_status_warn  :=  TRUE;             --�I���X�e�[�^�X���x����
            gb_csv_out      :=  FALSE;            --CSV�o�͂�}�~
          ELSIF ( lv_retcode            =         cv_status_error )   THEN    
            RAISE   global_process_expt ;
          END IF;   
        END IF;
        --
      END LOOP geet_sales_exp_manual_loop;
      --
      IF ( gn_target_cnt      =       0 )   THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcff_appl_name
                      , iv_name         => cv_msg_cff_00165
                      , iv_token_name1  => cv_token_get_data
                      , iv_token_value1 => gv_sales_class_msg
                      );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
        gb_status_warn        :=  TRUE;           --�x���I����
      END IF;
      --
      IF  ( gt_sales_exp_tab.COUNT      >     0     ) 
      AND ( gb_csv_out                  =     TRUE  ) 
      THEN
        --==============================================================
        -- CSV�o�͏���(A-7)  �̔����уw�b�_���قȂ�ꍇ
        --==============================================================
        out_csv (
            ov_errbuf                   =>        lv_errbuf
          , ov_retcode                  =>        lv_retcode
          , ov_errmsg                   =>        lv_errmsg
          );
        --
        IF ( lv_retcode                 <>        cv_status_normal )  THEN
          RAISE   global_process_expt;
        END IF;
      END IF;
      --
      CLOSE get_sales_exp_manual_cur;   
    --==============================================================
    -- 2 ������s�̏ꍇ
    --==============================================================
    ELSIF ( gv_exec_mode      =   cv_exec_fixed_period )  THEN
      OPEN  get_sales_exp_fixed_cur;   
      <<get_sales_exp_fixed_loop>>   
      LOOP
        FETCH   get_sales_exp_fixed_cur           INTO      
            gt_data_type                          --�f�[�^�^�C�v
          , gt_data_tab(1)                        --�̔����уw�b�_ID
          , gt_data_tab(2)                        --�[�i�`�[�ԍ�
          , gt_data_tab(3)                        --�����`�[�ԍ�
          , gt_data_tab(4)                        --�󒍔ԍ�
          , gt_data_tab(5)                        --��No�iHHT)
          , gt_data_tab(6)                        --��No�iHHT�j�}��
          , gt_data_tab(7)                        --�󒍊֘A�ԍ�
          , gt_data_tab(8)                        --�[�i��
          , gt_data_tab(9)                        --�I���W�i���[�i��
          , gt_data_tab(10)                       --������
          , gt_data_tab(11)                       --�I���W�i��������
          , gt_data_tab(12)                       --HHT�[�i���͓���
          , gt_data_tab(13)                       --�o�^�Ɩ����t
          , gt_data_tab(14)                       --�Ƒԏ�����
          , gt_data_tab(15)                       --�Ƒԏ����ޖ���
          , gt_data_tab(16)                       --�ڋq�y�[�i��z
          , gt_data_tab(17)                       --�ڋq���y�[�i��z
          , gt_data_tab(18)                       --������z���v
          , gt_data_tab(19)                       --�{�̋��z���v
          , gt_data_tab(20)                       --����ŋ��z���v
          , gt_data_tab(21)                       --����ŋ敪
          , gt_data_tab(22)                       --����ŋ敪��
          , gt_data_tab(23)                       --�ŋ��R�[�h
          , gt_data_tab(24)                       --����ŗ�
          , gt_data_tab(25)                       --���ьv��҃R�[�h
          , gt_data_tab(26)                       --���ьv��Җ�
          , gt_data_tab(27)                       --�[�i�҃R�[�h
          , gt_data_tab(28)                       --�[�i�Җ�
          , gt_data_tab(29)                       --���㋒�_�R�[�h
          , gt_data_tab(30)                       --���㋒�_����
          , gt_data_tab(31)                       --�������_�R�[�h
          , gt_data_tab(32)                       --�������_����
          , gt_data_tab(33)                       --�Ǌ����_�R�[�h
          , gt_data_tab(34)                       --�Ǌ����_����
          , gt_data_tab(35)                       --�[�i�`�[�敪
          , gt_data_tab(36)                       --�[�i�`�[�敪����
          , gt_data_tab(37)                       --�J�[�h����敪
          , gt_data_tab(38)                       --�J�[�h����敪����
          , gt_data_tab(39)                       --�`�[�敪
          , gt_data_tab(40)                       --�`�[���ރR�[�h
          , gt_data_tab(41)                       --���͋敪
          , gt_data_tab(42)                       --���͋敪����
          , gt_data_tab(43)                       --�󒍃\�[�XID
          , gt_data_tab(44)                       --�󒍃\�[�X����
          , gt_data_tab(45)                       --��K�؂ꎞ�ԂP�O�O�~
          , gt_data_tab(46)                       --��K�؂ꎞ�ԂP�O�~
          , gt_data_tab(47)                       --�쐬���敪
          , gt_data_tab(48)                       --�쐬���敪����
          , gt_data_tab(49)                       --�̔����і���ID
          , gt_data_tab(50)                       --�[�i���הԍ�
          , gt_data_tab(51)                       --�������הԍ�
          , gt_data_tab(52)                       --�R����No
          , gt_data_tab(53)                       --�i�ڃR�[�h
          , gt_data_tab(54)                       --�i�ږ���
          , gt_data_tab(55)                       --�i�ڋ敪
          , gt_data_tab(56)                       --�[�i����
          , gt_data_tab(57)                       --�����
          , gt_data_tab(58)                       --�[�i�P��
          , gt_data_tab(59)                       --��P��
          , gt_data_tab(60)                       --�[�i�P��
          , gt_data_tab(61)                       --��P��
          , gt_data_tab(62)                       --�Ŕ���P��
          , gt_data_tab(63)                       --�c�ƌ���
          , gt_data_tab(64)                       --������z
          , gt_data_tab(65)                       --�{�̋��z
          , gt_data_tab(66)                       --����ŋ��z
          , gt_data_tab(67)                       --�����E�J�[�h���p�z
          , gt_data_tab(68)                       --�o�׌��ۊǏꏊ
          , gt_data_tab(69)                       --�ۊǏꏊ����
          , gt_data_tab(70)                       --�[�i���_�R�[�h
          , gt_data_tab(71)                       --�[�i���_����
          , gt_data_tab(72)                       --����敪
          , gt_data_tab(73)                       --����敪����
          , gt_data_tab(74)                       --�[�i�`�ԋ敪
          , gt_data_tab(75)                       --�[�i�`�ԋ敪����
          , gt_data_tab(76)                       --�ԍ��t���O
          , gt_data_tab(77)                       --�ԍ��t���O����
          , gt_data_tab(78)                       --�g���b
          , gt_data_tab(79)                       --�g���b����
          , gt_data_tab(80)                       --���؋敪
          , gt_data_tab(81)                       --���؋敪����
          , gt_data_tab(82)                       --���؎���
          , gt_data_tab(83)                       --INV����^�C�v
          , gt_data_tab(84)                       --AR���ID
          , gt_data_tab(85)                       --AR�������i����j�ԍ�
          , gt_data_tab(86)                       --�����������ԍ�
          , gt_data_tab(87)                       --AR����^�C�v
          , gt_data_tab(88)                       --�ڋq�����掖�Ə���
          , gt_data_tab(89)                       --�A�g����
          , gt_ar_interface_flag                  --AR�C���^�[�t�F�[�X�t���O
          , gt_gl_interface_flag                  --GL�C���^�[�t�F�[�X�t���O
          , gt_inv_interface_flag                 --INV�C���^�[�t�F�[�X�t���O
          ;
        EXIT WHEN get_sales_exp_fixed_cur%NOTFOUND;        
        --
        IF ( gt_data_type               =         '1' )   THEN
          gn_target_cnt       :=  gn_target_cnt       +   1;
        ELSE
          gn_target_coop_cnt  :=  gn_target_coop_cnt  +   1;
        END IF;
        --
        IF ( gt_sales_exp_header_id     <>    gt_data_tab(cn_tbl_header_id) )   THEN
          IF  ( gt_sales_exp_tab.COUNT  >     0     ) 
          AND ( gb_csv_out              =     TRUE  ) THEN
            --==============================================================
            -- CSV�o�͏���(A-7)  �̔����уw�b�_���قȂ�ꍇ
            --==============================================================
            out_csv (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode             <>        cv_status_normal )  THEN
              RAISE   global_process_expt;
            END IF;
          END IF;
          --
          gt_sales_exp_tab.DELETE;
          gb_csv_out    :=  TRUE;
          --
        END IF;
        --
        gt_sales_exp_header_id  :=  gt_data_tab(cn_tbl_header_id);
        --
        IF  ( lv_errlevel               IS        NULL )   
        OR  ( lv_errlevel               =         cv_errlevel_header 
        AND   lt_sales_exp_header_id    <>        gt_data_tab(cn_tbl_header_id))
        OR  ( lv_errlevel               =         cv_errlevel_line )    THEN
          lv_errlevel             :=  NULL;       --�G���[���x��
          lt_sales_exp_header_id  :=  NULL;       --�̔����уw�b�_ID
          gb_coop_out             :=  TRUE;       --�̔����і��A�g�e�[�u���o�̓t���O
          BEGIN
            --==============================================================
            -- �t�����擾����(A-5)
            --==============================================================
            get_flex_information (
                ov_errlevel             =>        lv_errlevel
              , ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            IF ( lv_retcode             =         cv_status_warn )    THEN
              RAISE   skip_record_fixed_expt;
            ELSIF ( lv_retcode          =         cv_status_error )   THEN
              RAISE   global_process_expt;
            END IF;          
            --==============================================================
            -- ���ڃ`�F�b�N����(A-6)
            --==============================================================
            chk_item (
                ov_errlevel             =>        lv_errlevel
              , ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode             =         cv_status_normal )  THEN
              --==============================================================
              -- ����ȃf�[�^��ޔ�
              --==============================================================
              gt_sales_exp_tab(NVL(gt_sales_exp_tab.COUNT, 0) + 1)  :=  gt_data_tab;
              --
            ELSIF ( lv_retcode          =         cv_status_warn )   THEN
              RAISE   skip_record_fixed_expt;
            ELSIF ( lv_retcode          =         cv_status_error )  THEN    
              RAISE   global_process_expt ;
            END IF;   
          EXCEPTION
            WHEN skip_record_fixed_expt THEN
              --==============================================================
              -- ���A�g�e�[�u���o�^����(A-8)
              --==============================================================
              IF ( gb_coop_out          =     TRUE )  THEN
                ins_sales_exp_coop (
                    ov_errbuf               =>        lv_errbuf
                  , ov_retcode              =>        lv_retcode
                  , ov_errmsg               =>        lv_errmsg
                  );
                --
              END IF;
              lt_sales_exp_header_id  :=  gt_data_tab(cn_tbl_header_id);
              --
              gb_status_warn  :=  TRUE;           --�x���I����
              gb_csv_out      :=  FALSE;          --CSV�t�@�C�����o�͂��Ȃ�
              --
          END;
          --
        END IF;
      END LOOP get_sales_exp_fixed_loop;
      --
      IF ( gn_target_cnt      =     0 )   THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcff_appl_name
                      , iv_name         => cv_msg_cff_00165
                      , iv_token_name1  => cv_token_get_data
                      , iv_token_value1 => gv_sales_class_msg
                      );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2012/10/31 [�����e�X�g��QNo29] N.Sugiura ADD
        --
        gb_status_warn        :=  TRUE;           --�x���I����
      END IF;
      --
      --CSV�o�͑Ώۃ��R�[�h�����݂��ACSV�o�͑Ώۂ̏ꍇ
      IF  ( gt_sales_exp_tab.COUNT       >     0     ) 
      AND ( gb_csv_out                   =     TRUE  ) 
      THEN
        --==============================================================
        -- CSV�o�͏���(A-7)  �̔����уw�b�_���قȂ�ꍇ
        --==============================================================
        out_csv (
            ov_errbuf                   =>        lv_errbuf
          , ov_retcode                  =>        lv_retcode
          , ov_errmsg                   =>        lv_errmsg
          );
        --
        IF ( lv_retcode             <>        cv_status_normal )  THEN
          RAISE   global_process_expt;
        END IF;
      END IF;
      --
      CLOSE get_sales_exp_fixed_cur;
    END IF;
--
  EXCEPTION
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
  END get_sales_exp;
--
  /**********************************************************************************
   * Procedure Name   : upd_sales_exp_control
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-9)
   ***********************************************************************************/
  PROCEDURE upd_sales_exp_control(
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sales_exp_control'; -- �v���O������
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
    lt_sales_exp_header_id_max          xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    ln_ctl_max_sales_exp_header_id      xxcfo_sales_exp_control.sales_exp_header_id%TYPE;
-- 2012/11/28 Ver.1.2 T.Osawa Add End
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    IF ( gv_exec_mode         =         cv_exec_fixed_period )    THEN
      BEGIN
        UPDATE    xxcfo_sales_exp_control         xsec
        SET       xsec.process_flag               =     cv_flag_y                         --�����σt���O
                , xsec.last_updated_by            =     cn_last_updated_by                --�ŏI�X�V��
                , xsec.last_update_date           =     cd_last_update_date               --�ŏI�X�V��
                , xsec.last_update_login          =     cn_last_update_login              --�ŏI�X�V���O�C��
                , xsec.request_id                 =     cn_request_id                     --�v��ID
                , xsec.program_application_id     =     cn_program_application_id         --�v���O�����A�v���P�[�V����ID
                , xsec.program_id                 =     cn_program_id                     --�v���O����ID
                , xsec.program_update_date        =     cd_program_update_date            --�v���O�����X�V��
        WHERE     xsec.rowid                      =     gt_row_id_to
        ;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
      BEGIN
        SELECT    MAX(xsec.sales_exp_header_id)
        INTO      ln_ctl_max_sales_exp_header_id
        FROM      xxcfo_sales_exp_control         xsec
        ;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      BEGIN
-- 2012/11/28 Ver.1.2 T.Osawa Modify Start
--      SELECT    MAX(xseh.sales_exp_header_id)   AS    max_sales_exp_header_id
--      INTO      lt_sales_exp_header_id_max
--      FROM      xxcos_sales_exp_headers         xseh
--      WHERE     xseh.business_date              <=      gd_prdate
-- 2012/12/18 Ver.1.3 Mod Start
--        SELECT    NVL(MAX(xseh.sales_exp_header_id), ln_ctl_max_sales_exp_header_id)   
--                                                  AS    max_sales_exp_header_id
        SELECT /*+ INDEX(xseh XXCOS_SALES_EXP_HEADERS_PK) */
                  NVL(MAX(xseh.sales_exp_header_id), ln_ctl_max_sales_exp_header_id)   
                                                  AS    max_sales_exp_header_id
-- 2012/12/18 Ver.1.3 Mod End
        INTO      lt_sales_exp_header_id_max
        FROM      xxcos_sales_exp_headers         xseh
        WHERE     xseh.sales_exp_header_id        >       ln_ctl_max_sales_exp_header_id
        AND       xseh.business_date              <=      gd_prdate
-- 2012/11/28 Ver.1.2 T.Osawa Modify End
        ;
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
      END;
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
      -- �̔����т�MAX�������A����l�𒴂����ꍇ
      IF ( lt_sales_exp_header_id_max > ln_ctl_max_sales_exp_header_id + gn_sales_exp_upper_limit ) THEN
        -- ����l���o�^����
        lt_sales_exp_header_id_max := ln_ctl_max_sales_exp_header_id + gn_sales_exp_upper_limit;
      END IF;
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
      --
      BEGIN
        INSERT INTO xxcfo_sales_exp_control (
            business_date                         --�Ɩ����t
          , sales_exp_header_id                   --�̔����уw�b�_ID
          , process_flag                          --�����t���O
          , created_by                            --�쐬��
          , creation_date                         --�쐬��
          , last_updated_by                       --�ŏI�X�V��
          , last_update_date                      --�ŏI�X�V��
          , last_update_login                     --�ŏI�X�V���O�C��
          , request_id                            --�v��ID
          , program_application_id                --�v���O�����A�v���P�[�V����ID
          , program_id                            --�v���O�����X�V��
          , program_update_date                   --�v���O�����X�V��
        ) VALUES ( 
            gd_prdate                             --�Ɩ����t
          , lt_sales_exp_header_id_max            --�̔����уw�b�_ID
          , cv_flag_n                             --�����t���O
          , cn_created_by                         --�쐬��
          , cd_creation_date                      --�쐬��
          , cn_last_updated_by                    --�ŏI�X�V��
          , cd_last_update_date                   --�ŏI�X�V��
          , cn_last_update_login                  --�ŏI�X�V���O�C��
          , cn_request_id                         --�v��ID
          , cn_program_application_id             --�v���O�����A�v���P�[�V����ID
          , cn_program_id                         --�v���O����ID
          , cd_program_update_date                --�v���O�����X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
--
  EXCEPTION
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
  END upd_sales_exp_control;
--
  /**********************************************************************************
   * Procedure Name   : del_sales_exp_wait
   * Description      : ���A�g�e�[�u���폜����(A-10)
   ***********************************************************************************/
  PROCEDURE del_sales_exp_wait (
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_sales_exp_wait'; -- �v���O������
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
    ln_del_cnt                NUMBER;   
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
    BEGIN
      FORALL ln_del_cnt IN 1..gt_sales_exp_rowid_tbl.COUNT  
        DELETE 
        FROM      xxcfo_sales_exp_wait_coop         xsewc
        WHERE     xsewc.rowid                       =         gt_sales_exp_rowid_tbl(ln_del_cnt)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00025
                      , iv_token_name1  => cv_token_table
                      , iv_token_name2  => cv_token_errmsg
                      , iv_token_value1 => gv_sales_exp_wait
                      , iv_token_value2 => NULL
                      );
        --
        lv_errbuf :=lv_errmsg;
        RAISE  global_process_expt;
        --
    END;
--
  EXCEPTION
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
  END del_sales_exp_wait;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn      IN  VARCHAR2,             --�ǉ��X�V�敪
    iv_file_name        IN  VARCHAR2,             --�t�@�C����
    iv_id_from          IN  VARCHAR2,             --�̔����уw�b�_ID(From)
    iv_id_to            IN  VARCHAR2,             --�̔����уw�b�_ID(To)
    ov_errbuf           OUT VARCHAR2,             --�G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode          OUT VARCHAR2,             --���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg           OUT VARCHAR2)             --���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt       :=  0;          --�Ώی���
    gn_normal_cnt       :=  0;          --�o�͌���
    gn_error_cnt        :=  0;          --�G���[����
    gn_warn_cnt         :=  0;          --�x������
    gn_target_coop_cnt  :=  0;          --���A�g�f�[�^�Ώی���
    gn_out_coop_cnt     :=  0;          --���A�g�o�͌���
    gb_fileopen         :=  FALSE;      --�t�@�C���I�[�v���t���O
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- �ǉ��X�V�敪
      iv_file_name            =>  iv_file_name,             -- �t�@�C����
      iv_id_from              =>  iv_id_from,               -- �̔����уw�b�_ID(From)
      iv_id_to                =>  iv_id_to,                 -- �̔����уw�b�_ID(To)
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���A�g�f�[�^�擾����(A-2)
    -- ===============================
    get_sales_exp_wait(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- �ǉ��X�V�敪
      iv_file_name            =>  iv_file_name,             -- �t�@�C����
      iv_id_from              =>  iv_id_from,               -- �̔����уw�b�_ID(From)
      iv_id_to                =>  iv_id_to,                 -- �̔����уw�b�_ID(To)
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ǘ��e�[�u���f�[�^�擾����(A-3)
    -- ===============================
    get_sales_exp_control(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- �ǉ��X�V�敪
      iv_file_name            =>  iv_file_name,             -- �t�@�C����
      iv_id_from              =>  iv_id_from,               -- �̔����уw�b�_ID(From)
      iv_id_to                =>  iv_id_to,                 -- �̔����уw�b�_ID(To)
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �Ώۃf�[�^���o(A-5)
    -- ===============================
    get_sales_exp(
      ov_errbuf               =>  lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode              =>  lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg               =>  lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- �Ǘ��e�[�u���o�^�E�X�V����(A-9)
    --==============================================================
    --
    upd_sales_exp_control (
        ov_errbuf             =>        lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode            =>        lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg             =>        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    --==============================================================
    -- ���A�g�e�[�u���폜����(A-10)
    --==============================================================
    --������s�̏ꍇ�A�̔����і��A�g�e�[�u���̍폜���s��
    IF ( gv_exec_mode         =     cv_exec_fixed_period )    THEN
      del_sales_exp_wait (
          ov_errbuf           =>        lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode          =>        lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg           =>        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
      --
      IF (lv_retcode            =     cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf              OUT VARCHAR2              --�G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode             OUT VARCHAR2              --���^�[���E�R�[�h    --# �Œ� #
   ,iv_ins_upd_kbn      IN  VARCHAR2              --�ǉ��X�V�敪
   ,iv_file_name        IN  VARCHAR2              --�t�@�C����
   ,iv_id_from          IN  VARCHAR2              --�̔����уw�b�_ID�iFrom�j
   ,iv_id_to            IN  VARCHAR2              --�̔����уw�b�_ID�iTo�j
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
        ov_retcode            =>  lv_retcode
      , ov_errbuf             =>  lv_errbuf
      , ov_errmsg             =>  lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_ins_upd_kbn          =>        iv_ins_upd_kbn      --�ǉ��X�V�敪
      ,iv_file_name           =>        iv_file_name        --�t�@�C����
      ,iv_id_from             =>        iv_id_from          --�̔����уw�b�_ID(From)
      ,iv_id_to               =>        iv_id_to            --�̔����уw�b�_ID(To)
      ,ov_errbuf              =>        lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             =>        lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              =>        lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --==============================================================
    -- �t�@�C���N���[�Y
    --==============================================================
    --�t�@�C�����I�[�v������Ă���ꍇ�A�t�@�C�����N���[�Y����
    IF ( gb_fileopen          =     TRUE )    THEN
      BEGIN
        UTL_FILE.FCLOSE (
          file                =>        gv_activ_file_h);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_00029
                        , iv_token_name1  => cv_token_max_id
                        , iv_token_value1 => gt_id_from
                        );
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
          RAISE global_api_others_expt;      
      END;
    END IF;
    --�蓮���s���ɁA�G���[���������Ă����ꍇ�A�t�@�C����0�o�C�g�ɂ���
    IF ( gv_exec_mode         =         cv_exec_manual )   THEN
      IF  ( lv_retcode        =         cv_status_error )
      AND ( gb_get_sales_exp  =         TRUE )             
      THEN
        --�I�[�v��
        gv_activ_file_h := UTL_FILE.FOPEN(
                              location     => gv_file_path        -- �f�B���N�g���p�X
                            , filename     => gv_file_name        -- �t�@�C����
                            , open_mode    => cv_file_mode        -- �I�[�v�����[�h
                            , max_linesize => cn_max_linesize     -- �t�@�C���T�C�Y
                           );
        --�N���[�Y
        UTL_FILE.FCLOSE (
          file                    =>    gv_activ_file_h);
        --
      END IF;
    END IF;
    --�G���[�o��
    IF (lv_retcode                      =         cv_status_error) THEN
      --
      gn_normal_cnt       :=  0;    --�o�͌�����0���ɂ���
      gn_target_cnt       :=  0;    --���o������0���ɂ���
      gn_target_coop_cnt  :=  0;    --�̔����і��A�g������0����
      gn_out_coop_cnt     :=  0;    --CSV�o�͌���
      --
      gn_error_cnt  :=  gn_error_cnt    +   1;
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_out
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_log
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => ''
    );
    --�Ώی����o�́i�̔����сj
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o�́i�̔����і��A�g�e�[�u���j
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
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
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --���A�g�e�[�u���o�͌���
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_out_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
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
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode            = cv_status_normal) THEN
      lv_message_code   := cv_normal_msg;
      IF ( gb_status_warn     =   TRUE )  THEN
        lv_retcode            :=  cv_status_warn;
        lv_message_code :=  cv_warn_msg;
      END IF;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code   := cv_warn_msg;
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code   := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFO019A03C;
/
