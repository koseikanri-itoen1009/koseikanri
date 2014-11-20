CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A06C (body)
 * Description      : �̔����уw�b�_�f�[�^�A�̔����і��׃f�[�^���擾���āA�̔����уf�[�^�t�@�C����
 *                    �쐬����B
 * MD.050           : �̔����уf�[�^�쐬�iMD050_COS_011_A06�j
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  input_param_check      ���̓p�����[�^�`�F�b�N����(A-1)
 *  get_custom_data        �����Ώیڋq�擾����(A-2)
 *  init                   ��������(A-3)
 *  output_header          �t�@�C����������(A-4)
 *  get_sale_data          �̔����я�񒊏o(A-5)
 *  edit_sale_data         �f�[�^�ҏW(A-6,A-7)
 *  output_footer          �t�@�C���I������(A-8)
 *  upd_sale_exp_head_send �̔����уw�b�_TBL�t���O�X�V�i�쐬�j(A-9)
 *  upd_sale_exp_head_rep  �̔����уw�b�_TBL�t���O�X�V�i�����j(A-11)
 *  upd_no_target          �̔����ђ��o�ΏۊO�X�V(A-12)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   K.Watanabe      �V�K�쐬
 *  2009/03/10    1.1   K.Kiriu         [COS_157]�����J�n��NULL�l���̏C���A�͂���Z���s���C��
 *  2009/04/15    1.2   K.Kiriu         [T1_0495]JP1�N���̈׃p�����[�^�̒ǉ�
 *  2009/04/28    1.3   K.Kiriu         [T1_0756]���R�[�h���ύX�Ή�
 *  2009/05/28    1.4   T.Tominaga      [T1_0540]�̔����т̑Ώۃf�[�^�擾�J�[�\����ORDER BY��̕ύX
 *                                               �t�@�C���o�͂̍s�m���̃Z�b�g�l��A�ԂɕύX
 *  2009/06/12    1.5   N.Maeda         [T1_1356]�t�@�C��No�o�͍��ڏC��
 *  2009/06/25    1.5   M.Sano          [T1_1359]���ʊ��Z�Ή�
 *  2009/07/07    1.5   N.Maeda         [T1_1356]���r���[�w�E�Ή�
 *  2009/07/13    1.5   N.Maeda         [T1_1359]���r���[�w�E�Ή�
 *  2009/07/29    1.5   K.Kiriu         [T1_1359]���r���[�w�E�Ή�
 *  2009/09/03    1.6   N.Maeda         [0001199]�̔����і��ׂ̔r������폜
 *  2009/11/05    1.7   M.Sano          [E_T4_00088]�`�[�敪�̎Z�o���@�ύX
 *                                      [E_T4_00142]�ڋq�g�p�ړI�i������j�̃Z�b�g���ڏC��
 *  2009/11/24    1.8   K.Atsushiba     [E_�{��_00348]PT�Ή�
 *  2009/11/27    1.9   K.Kiriu         [E_�{��_00114]����攭���ԍ��ݒ�Ή�
 *  2010/03/16    1.10  K.Kiriu         [E_�{�ғ�_01153]EDI�̔����ёΏیڋq�ǉ����̑Ή�
 *                                      [E_�{�ғ�_01301]PT�Ή�(�ΏۊO�f�[�^�̍X�V�ǉ��j
 *                                                      �ڋq�}�X�^���f���̑Ή�
 *  2010/06/22    1.11  S.Arizumi       [E_�{�ғ�_02995] �H�HEDI�̔����т̃I�[�_�[No.�i�����`�[�ԍ��j�s��Ή�
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
  -- ���t
  cd_sysdate                CONSTANT DATE        := SYSDATE;                            -- �V�X�e�����t
  cd_process_date           CONSTANT DATE        := xxccp_common_pkg2.get_process_date; -- �Ɩ�������
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_data_check_expt    EXCEPTION;     -- init�`�F�b�N���̃G���[
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );  --���b�N�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOS011A06C'; -- �p�b�P�[�W��
--
  cv_application        CONSTANT VARCHAR2(10)  := 'XXCOS';        -- �A�v���P�[�V������
  -- �v���t�@�C��
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';             -- XXCCP:IF���R�[�h�敪_�w�b�_
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';               -- XXCCP:IF���R�[�h�敪_�f�[�^
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';             -- XXCCP:IF���R�[�h�敪_�t�b�^
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';      -- XXCOS:UTL_MAX�s�T�C�Y
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_OUTBOUND_OM_DIR';   -- XXCOS:EDI%�f�B���N�g���p�X(���̗�)
  cv_prf_dept_code      CONSTANT VARCHAR2(50)  := 'XXCOS1_BIZ_MAN_DEPT_CODE';     -- XXCOS:�Ɩ��Ǘ����R�[�h
  cv_prf_orga_code1     CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';     -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_def_item_rate  CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_DEFAULT_ITEM_RATE'; -- XXCOS:EDI�f�t�H���g����
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                       -- MO:�c�ƒP��
/* 2010/03/16 Ver1.10 Add Start */
  cv_prf_max_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';              -- XXCOS:MAX���t
  cv_prf_min_date       CONSTANT VARCHAR2(50)  := 'XXCOS1_MIN_DATE';              -- XXCOS:MIN���t
  cv_prf_trg_hold_m     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_TARGET_HOLD_MONTH'; -- XXCOS:EDI�̔����ёΏەێ�����
/* 2010/03/16 Ver1.10 Add End   */
  -- ���b�Z�[�W�R�[�h
  cv_msg_param_create   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12368';  -- �p�����[�^�[�o��(�쐬)
  cv_msg_param_cancel   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12352';  -- �p�����[�^�[�o��(����)
  cv_msg_file_name      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00044';  -- �t�@�C�����o��
  cv_msg_lock_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ���b�N�G���[
  cv_msg_date_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00171';  -- ���t�����G���[
  cv_msg_no_target_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^�Ȃ��G���[
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';  -- �v���t�@�C���擾�G���[
  cv_msg_param_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00006';  -- �K�{���̓p�����[�^���ݒ�G���[
  cv_msg_file_o_err     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';  -- �t�@�C���I�[�v���G���[
  cv_msg_data_get_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- �f�[�^���o�G���[
  cv_msg_in_param_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00019';  -- ���̓p�����[�^�s���G���[���b�Z�[�W
  cv_msg_base_code_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00035';  -- ���_���擾�G���[
  cv_msg_edi_c_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00036';  -- EDI�`�F�[���X���擾�G���[
  cv_msg_proc_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00037';  -- ���ʊ֐��G���[
  cv_msg_out_inf_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00038';  -- �o�͏��ҏW�G���[
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';  -- IF�t�@�C�����C�A�E�g��`���擾�G���[
  gv_msg_orga_id_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00091';  -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_mst_chk_err    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10002';  -- �}�X�^�`�F�b�N�G���[
  cv_msg_upd_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';  -- �f�[�^�X�V�G���[
  cv_msg_edi_m_class_c  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12308';  -- �N�C�b�N�R�[�h�擾����(EDI�}�̋敪)
  cv_msg_sales_class_c  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12369';  -- �N�C�b�N�R�[�h�擾����(����敪)
  cv_msg_prf_if_h       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';  -- XXCCP:IF���R�[�h�敪_�w�b�_(����)
  cv_msg_prf_if_d       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';  -- XXCCP:IF���R�[�h�敪_�f�[�^(����)
  cv_msg_prf_if_f       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';  -- XXCCP:IF���R�[�h�敪_�t�b�^(����)
  cv_msg_prf_utl_m      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00107';  -- XXCOS:UTL_MAX�s�T�C�Y(����)
  cv_msg_prf_out_d      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00145';  -- XXCOS:�󒍌n�A�E�g�o�E���h�p�f�B���N�g���p�X(����)
  cv_msg_prf_dept_c     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12358';  -- XXCOS:�Ɩ��Ǘ����R�[�h(����)
  cv_msg_prf_edi_r      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12359';  -- XXCOS:EDI�f�t�H���g����(����)
  cv_msg_orga_code      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12360';  -- XXCOI:�݌ɑg�D�R�[�h(����)
  cv_msg_org_id         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';  -- MO:�c�ƒP��
  cv_msg_table_tkn1     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00046';  -- �N�C�b�N�R�[�h(����)
  cv_msg_table_tkn2     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12364';  -- �̔����уw�b�_�e�[�u��(����)
  cv_msg_sales_class    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10046';  -- ����敪�i�����j
  cv_msg_create         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12353';  -- �쐬(����)
  cv_msg_cancel         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12354';  -- ����(����)
  cv_msg_bill_account   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12355';  -- ������ڋq�R�[�h(����)
  cv_msg_send_date      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12356';  -- ���M��(����)
  cv_msg_run_class      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12357';  -- ���s�敪(����)
  cv_msg_data_type_c    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12362';  -- �f�[�^��R�[�h(����)
  cv_msg_edi_m_class_n  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00110';  -- EDI�}�̋敪(����)
  cv_msg_in_file_name   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00109';  -- �t�@�C����(����)
  cv_msg_layout         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12367';  -- ���C�A�E�g��`���(����)
/* 2010/03/16 Ver1.10 Add Start */
  cv_msg_prf_min_d      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00120';  -- XXCOS:MIN���t(����)
  cv_msg_prf_max_d      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';  -- XXCOS:MAX���t(����)
  cv_msg_prf_hold_m     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12370';  -- XXCOS:EDI�̔����ёΏەێ�����(����)
  cv_msg_param_update   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-12371';  -- �p�����[�^�[�o��(�ΏۊO�X�V)
/* 2010/03/16 Ver1.10 Add End   */
  -- �g�[�N���R�[�h
  cv_tkn_parame1        CONSTANT VARCHAR2(20)  := 'PARAME1';           -- �p�����[�^�[�P
  cv_tkn_parame2        CONSTANT VARCHAR2(20)  := 'PARAME2';           -- �p�����[�^�[�Q
  cv_tkn_parame3        CONSTANT VARCHAR2(20)  := 'PARAME3';           -- �p�����[�^�[�R
  cv_tkn_para_d         CONSTANT VARCHAR2(20)  := 'PARA_DATE';         -- �p�����[�^�[���t
  cv_tkn_in_param       CONSTANT VARCHAR2(20)  := 'IN_PARAM';          -- �p�����[�^����
  cv_tkn_prf            CONSTANT VARCHAR2(20)  := 'PROFILE';           -- �v���t�@�C������
  cv_tkn_chain_s        CONSTANT VARCHAR2(20)  := 'CHAIN_SHOP_CODE';   -- �`�F�[���X
  cv_tkn_err_m          CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- �G���[���b�Z�[�W��
  cv_tkn_column         CONSTANT VARCHAR2(20)  := 'COLMUN';            -- �J������
  cv_tkn_table          CONSTANT VARCHAR2(20)  := 'TABLE';             -- �e�[�u����
  cv_tkn_file_n         CONSTANT VARCHAR2(20)  := 'FILE_NAME';         -- �t�@�C����
  cv_tkn_file_l         CONSTANT VARCHAR2(20)  := 'LAYOUT';            -- �t�@�C�����C�A�E�g���
  cv_tkn_table_n        CONSTANT VARCHAR2(20)  := 'TABLE_NAME';        -- �e�[�u����
  cv_tkn_key            CONSTANT VARCHAR2(20)  := 'KEY_DATA';          -- �L�[�f�[�^
  cv_base_code1         CONSTANT VARCHAR2(20)  := 'CODE';              -- ���_���擾
  cv_tkn_org_code       CONSTANT VARCHAR2(50)  := 'ORG_CODE_TOK';      -- �݌ɑg�D�R�[�h�i�݌ɑg�DID�j
  cv_tkn_profile        CONSTANT VARCHAR2(50)  := 'PROFILE';           --�v���t�@�C��
--
  -- �ڋq�}�X�^�擾�p�Œ�l
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                -- �ڋq�敪(�`�F�[���X)
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                 -- �X�e�[�^�X
  cv_cust_site_use_code CONSTANT VARCHAR2(10)  := 'SHIP_TO';           -- �ڋq�g�p�ړI�F�o�א�
/* 2009/11/05 Ver1.7 Add Start */
  cv_bill_to            CONSTANT VARCHAR2(10)  := 'BILL_TO';           -- �ڋq�g�p�ړI�F������
/* 2009/11/05 Ver1.7 Add End   */
  -- �N�C�b�N�R�[�h�^�C�v
  cv_lkt_edi_s_exe_type CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_SALES_EXP_EXE_TYPE'; --EDI�̔����э쐬���s�敪
  cv_lkt_sales_edi_cust CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_SALES_EXP_CUST';     --������ڋq�R�[�h
  cv_lkt_ship_to_pb     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PB_CHAIN_SHOP';      --�[�i��`�F�[���R�[�hPB
  cv_lkt_ship_to_nb     CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_NB_CHAIN_SHOP';      --�[�i��`�F�[���R�[�hNB
  cv_lkt_pb_item        CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_PB_ITEM';            --PB���i�R�[�h
  cv_lkt_edi_filename   CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_SALES_EXP_FILENAME'; --EDI�̔����уt�@�C����
  cv_lkt_edi_m_class    CONSTANT VARCHAR2(50)  := 'XXCOS1_EDI_MEDIA_CLASS';        --EDI�}�̋敪
  cv_lkt_data_type_code CONSTANT VARCHAR2(50)  := 'XXCOS1_DATA_TYPE_CODE';         --�f�[�^��
  cv_lkt_edi_sale_class CONSTANT VARCHAR2(50)  := 'XXCOS1_SALE_CLASS';             --����敪
  cv_lkt_no_inv_item    CONSTANT VARCHAR2(50)  := 'XXCOS1_NO_INV_ITEM_CODE';       --��݌ɕi�ڃR�[�h
  -- �N�C�b�N�R�[�h�l
  cv_lkc_data_type_code CONSTANT VARCHAR2(3)   := '180';                     --�̔�����
  -- ���̑��Œ�l
  cv_date_format        CONSTANT VARCHAR2(10)  := 'YYYYMMDD';          -- ���t�t�H�[�}�b�g(�N����)
  cv_d_format_yyyymm    CONSTANT VARCHAR2(10)  := 'YYYYMM';            -- ���t�t�H�[�}�b�g(��)
/* 2010/03/16 Ver1.10 Add Start */
  cv_date_format_sl     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- ���t�t�H�[�}�b�g(�N�����X���b�V���t��)
  cv_d_format_mm        CONSTANT VARCHAR2(10)  := 'MM';                -- TRUNC�p���t�t�H�[�}�b�g(��)
/* 2010/03/16 Ver1.10 Add End   */
  cv_d_format_dd        CONSTANT VARCHAR2(10)  := 'DD';                -- ���t�t�H�[�}�b�g(��)
  cv_time_format        CONSTANT VARCHAR2(10)  := 'HH24MISS';          -- ���t�t�H�[�}�b�g(����)
  cn_0                  CONSTANT NUMBER        := 0;                   -- �Œ�l:0(NUMBER)
  cn_1                  CONSTANT NUMBER        := 1;                   -- �Œ�l:1(NUMBER)
  cn_2                  CONSTANT NUMBER        := 2;                   -- �Œ�l:2(NUMBER)
  cn_4                  CONSTANT NUMBER        := 4;                   -- �Œ�l:4(NUMBER)
  cn_5                  CONSTANT NUMBER        := 5;                   -- �Œ�l:5(NUMBER)
  cn_8                  CONSTANT NUMBER        := 8;                   -- �Œ�l:8(NUMBER)
  cn_9                  CONSTANT NUMBER        := 9;                   -- �Œ�l:9(NUMBER)
  cn_15                 CONSTANT NUMBER        := 15;                  -- �Œ�l:15(NUMBER)
  cn_16                 CONSTANT NUMBER        := 16;                  -- �Œ�l:16(NUMBER)
  cn_32                 CONSTANT NUMBER        := 32;                  -- �Œ�l:32(NUMBER)
  cv_0                  CONSTANT VARCHAR2(1)   := '0';                 -- �Œ�l:0(VARCHAR2)
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                 -- �Œ�l:1(VARCHAR2)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                 -- �Œ�l:2(VARCHAR2)
  cv_3                  CONSTANT VARCHAR2(1)   := '3';                 -- �Œ�l:3(VARCHAR2)
  cv_4                  CONSTANT VARCHAR2(1)   := '4';                 -- �Œ�l:4(VARCHAR2)
  cv_5                  CONSTANT VARCHAR2(1)   := '5';                 -- �Œ�l:5(VARCHAR2)
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- �Œ�l:Y
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- �Œ�l:N
  cv_w                  CONSTANT VARCHAR2(1)   := 'W';                 -- �Œ�l:W
  cv_0000               CONSTANT VARCHAR2(4)   := '0000';              -- �q���敪����p
/* 2010/03/16 Ver1.10 Add Start */
  cv_s                  CONSTANT VARCHAR2(1)   := 'S';                 -- �Œ�l:S
  gv_run_class_cd_create CONSTANT VARCHAR2(1)  := '0';                 -- ���s�敪�F�u�쐬�v�R�[�h
  gv_run_class_cd_cancel CONSTANT VARCHAR2(1)  := '1';                 -- ���s�敪�F�u�����v�R�[�h
  gv_run_class_cd_update CONSTANT VARCHAR2(1)  := '2';                 -- ���s�敪�F�u�ΏۊO�X�V�v�R�[�h
/* 2010/03/16 Ver1.10 Add End   */
  -- �f�[�^���^���ʊ֐��p
  cv_medium_class             CONSTANT VARCHAR2(50)  := 'MEDIUM_CLASS';                  --�}�̋敪
  cv_data_type_code           CONSTANT VARCHAR2(50)  := 'DATA_TYPE_CODE';                --�f�[�^��R�[�h
  cv_file_no                  CONSTANT VARCHAR2(50)  := 'FILE_NO';                       --�t�@�C��No
  cv_info_class               CONSTANT VARCHAR2(50)  := 'INFO_CLASS';                    --���敪
  cv_process_date             CONSTANT VARCHAR2(50)  := 'PROCESS_DATE';                  --������
  cv_process_time             CONSTANT VARCHAR2(50)  := 'PROCESS_TIME';                  --��������
  cv_base_code                CONSTANT VARCHAR2(50)  := 'BASE_CODE';                     --���_(����)�R�[�h
  cv_base_name                CONSTANT VARCHAR2(50)  := 'BASE_NAME';                     --���_��(������)
  cv_base_name_alt            CONSTANT VARCHAR2(50)  := 'BASE_NAME_ALT';                 --���_��(�J�i)
  cv_edi_chain_code           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_CODE';                --EDI�`�F�[���X�R�[�h
  cv_edi_chain_name           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME';                --EDI�`�F�[���X��(����)
  cv_edi_chain_name_alt       CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME_ALT';            --EDI�`�F�[���X��(�J�i)
  cv_chain_code               CONSTANT VARCHAR2(50)  := 'CHAIN_CODE';                    --�`�F�[���X�R�[�h
  cv_chain_name               CONSTANT VARCHAR2(50)  := 'CHAIN_NAME';                    --�`�F�[���X��(����)
  cv_chain_name_alt           CONSTANT VARCHAR2(50)  := 'CHAIN_NAME_ALT';                --�`�F�[���X��(�J�i)
  cv_report_code              CONSTANT VARCHAR2(50)  := 'REPORT_CODE';                   --���[�R�[�h
  cv_report_show_name         CONSTANT VARCHAR2(50)  := 'REPORT_SHOW_NAME';              --���[�\����
  cv_cust_code                CONSTANT VARCHAR2(50)  := 'CUSTOMER_CODE';                 --�ڋq�R�[�h
  cv_cust_name                CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME';                 --�ڋq��(����)
  cv_cust_name_alt            CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME_ALT';             --�ڋq��(�J�i)
  cv_comp_code                CONSTANT VARCHAR2(50)  := 'COMPANY_CODE';                  --�ЃR�[�h
  cv_comp_name                CONSTANT VARCHAR2(50)  := 'COMPANY_NAME';                  --�Ж�(����)
  cv_comp_name_alt            CONSTANT VARCHAR2(50)  := 'COMPANY_NAME_ALT';              --�Ж�(�J�i)
  cv_shop_code                CONSTANT VARCHAR2(50)  := 'SHOP_CODE';                     --�X�R�[�h
  cv_shop_name                CONSTANT VARCHAR2(50)  := 'SHOP_NAME';                     --�X��(����)
  cv_shop_name_alt            CONSTANT VARCHAR2(50)  := 'SHOP_NAME_ALT';                 --�X��(�J�i)
  cv_delv_cent_code           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_CODE';          --�[���Z���^�[�R�[�h
  cv_delv_cent_name           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME';          --�[���Z���^�[��(����)
  cv_delv_cent_name_alt       CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME_ALT';      --�[����Z���^�[��(�J�i)
  cv_order_date               CONSTANT VARCHAR2(50)  := 'ORDER_DATE';                    --������
  cv_cent_delv_date           CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_DATE';          --�Z���^�[�[�i��
  cv_result_delv_date         CONSTANT VARCHAR2(50)  := 'RESULT_DELIVERY_DATE';          --���[�i��
  cv_shop_delv_date           CONSTANT VARCHAR2(50)  := 'SHOP_DELIVERY_DATE';            --�X�ܔ[�i��
  cv_dc_date_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_DATE_EDI_DATA';   --�f�[�^�쐬��(EDI�f�[�^��)
  cv_dc_time_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_TIME_EDI_DATA';   --�f�[�^�쐬����(EDI�f�[�^��)
  cv_invc_class               CONSTANT VARCHAR2(50)  := 'INVOICE_CLASS';                 --�`�[�敪
  cv_small_classif_code       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_CODE';     --�����ރR�[�h
  cv_small_classif_name       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_NAME';     --�����ޖ�
  cv_middle_classif_code      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_CODE';    --�����ރR�[�h
  cv_middle_classif_name      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_NAME';    --�����ޖ�
  cv_big_classif_code         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_CODE';       --�啪�ރR�[�h
  cv_big_classif_name         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_NAME';       --�啪�ޖ�
  cv_op_department_code       CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_DEPARTMENT_CODE';   --����敔��R�[�h
  cv_op_order_number          CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_ORDER_NUMBER';      --����攭���ԍ�
  cv_check_digit_class        CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT_CLASS';             --�`�F�b�N�f�W�b�g�L���敪
  cv_invc_number              CONSTANT VARCHAR2(50)  := 'INVOICE_NUMBER';                --�`�[�ԍ�
  cv_check_digit              CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT';                   --�`�F�b�N�f�W�b�g
  cv_close_date               CONSTANT VARCHAR2(50)  := 'CLOSE_DATE';                    --����
  cv_order_no_ebs             CONSTANT VARCHAR2(50)  := 'ORDER_NO_EBS';                  --��No(EBS)
  cv_ar_sale_class            CONSTANT VARCHAR2(50)  := 'AR_SALE_CLASS';                 --�����敪
  cv_delv_classe              CONSTANT VARCHAR2(50)  := 'DELIVERY_CLASSE';               --�z���敪
  cv_opportunity_no           CONSTANT VARCHAR2(50)  := 'OPPORTUNITY_NO';                --��No
  cv_contact_to               CONSTANT VARCHAR2(50)  := 'CONTACT_TO';                    --�A����
  cv_route_sales              CONSTANT VARCHAR2(50)  := 'ROUTE_SALES';                   --���[�g�Z�[���X
  cv_corporate_code           CONSTANT VARCHAR2(50)  := 'CORPORATE_CODE';                --�@�l�R�[�h
  cv_maker_name               CONSTANT VARCHAR2(50)  := 'MAKER_NAME';                    --���[�J�[��
  cv_area_code                CONSTANT VARCHAR2(50)  := 'AREA_CODE';                     --�n��R�[�h
  cv_area_name                CONSTANT VARCHAR2(50)  := 'AREA_NAME';                     --�n�於(����)
  cv_area_name_alt            CONSTANT VARCHAR2(50)  := 'AREA_NAME_ALT';                 --�n�於(�J�i)
  cv_vendor_code              CONSTANT VARCHAR2(50)  := 'VENDOR_CODE';                   --�����R�[�h
  cv_vendor_name              CONSTANT VARCHAR2(50)  := 'VENDOR_NAME';                   --����於(����)
  cv_vendor_name1_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME1_ALT';              --����於1(�J�i)
  cv_vendor_name2_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME2_ALT';              --����於2(�J�i)
  cv_vendor_tel               CONSTANT VARCHAR2(50)  := 'VENDOR_TEL';                    --�����TEL
  cv_vendor_charge            CONSTANT VARCHAR2(50)  := 'VENDOR_CHARGE';                 --�����S����
  cv_vendor_address           CONSTANT VARCHAR2(50)  := 'VENDOR_ADDRESS';                --�����Z��(����)
  cv_delv_to_code_itouen      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_ITOUEN';        --�͂���R�[�h(�ɓ���)
  cv_delv_to_code_chain       CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_CHAIN';         --�͂���R�[�h(�`�F�[���X)
  cv_delv_to                  CONSTANT VARCHAR2(50)  := 'DELIVER_TO';                    --�͂���(����)
  cv_delv_to1_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO1_ALT';               --�͂���1(�J�i)
  cv_delv_to2_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO2_ALT';               --�͂���2(�J�i)
  cv_delv_to_address          CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS';            --�͂���Z��(����)
  cv_delv_to_address_alt      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS_ALT';        --�͂���Z��(�J�i)
  cv_delv_to_tel              CONSTANT VARCHAR2(50)  := 'DELIVER_TO_TEL';                --�͂���TEL
  cv_bal_acc_code             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_CODE';         --������R�[�h
  cv_bal_acc_comp_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_COMPANY_CODE'; --������ЃR�[�h
  cv_bal_acc_shop_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_SHOP_CODE';    --������X�R�[�h
  cv_bal_acc_name             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME';         --�����於(����)
  cv_bal_acc_name_alt         CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME_ALT';     --�����於(�J�i)
  cv_bal_acc_address          CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS';      --������Z��(����)
  cv_bal_acc_address_alt      CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS_ALT';  --������Z��(�J�i)
  cv_bal_acc_tel              CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_TEL';          --������TEL
  cv_order_possible_date      CONSTANT VARCHAR2(50)  := 'ORDER_POSSIBLE_DATE';           --�󒍉\��
  cv_perm_possible_date       CONSTANT VARCHAR2(50)  := 'PERMISSION_POSSIBLE_DATE';      --���e�\��
  cv_forward_month            CONSTANT VARCHAR2(50)  := 'FORWARD_MONTH';                 --����N����
  cv_payment_settlement_date  CONSTANT VARCHAR2(50)  := 'PAYMENT_SETTLEMENT_DATE';       --�x�����ϓ�
  cv_handbill_start_date_act  CONSTANT VARCHAR2(50)  := 'HANDBILL_START_DATE_ACTIVE';    --�`���V�J�n��
  cv_billing_due_date         CONSTANT VARCHAR2(50)  := 'BILLING_DUE_DATE';              --��������
  cv_ship_time                CONSTANT VARCHAR2(50)  := 'SHIPPING_TIME';                 --�o�׎���
  cv_delv_schedule_time       CONSTANT VARCHAR2(50)  := 'DELIVERY_SCHEDULE_TIME';        --�[�i�\�莞��
  cv_order_time               CONSTANT VARCHAR2(50)  := 'ORDER_TIME';                    --��������
  cv_gen_date_item1           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM1';            --�ėp���t����1
  cv_gen_date_item2           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM2';            --�ėp���t����2
  cv_gen_date_item3           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM3';            --�ėp���t����3
  cv_gen_date_item4           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM4';            --�ėp���t����4
  cv_gen_date_item5           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM5';            --�ėp���t����5
  cv_arrival_ship_class       CONSTANT VARCHAR2(50)  := 'ARRIVAL_SHIPPING_CLASS';        --���o�׋敪
  cv_vendor_class             CONSTANT VARCHAR2(50)  := 'VENDOR_CLASS';                  --�����敪
  cv_invc_detailed_class      CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED_CLASS';        --�`�[����敪
  cv_unit_price_use_class     CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_USE_CLASS';          --�P���g�p�敪
  cv_sub_distb_cent_code      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_CODE';  --�T�u�����Z���^�[�R�[�h
  cv_sub_distb_cent_name      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_NAME';  --�T�u�����Z���^�[�R�[�h��
  cv_cent_delv_method         CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_METHOD';        --�Z���^�[�[�i���@
  cv_cent_use_class           CONSTANT VARCHAR2(50)  := 'CENTER_USE_CLASS';              --�Z���^�[���p�敪
  cv_cent_whse_class          CONSTANT VARCHAR2(50)  := 'CENTER_WHSE_CLASS';             --�Z���^�[�q�ɋ敪
  cv_cent_area_class          CONSTANT VARCHAR2(50)  := 'CENTER_AREA_CLASS';             --�Z���^�[�n��敪
  cv_cent_arrival_class       CONSTANT VARCHAR2(50)  := 'CENTER_ARRIVAL_CLASS';          --�Z���^�[���׋敪
  cv_depot_class              CONSTANT VARCHAR2(50)  := 'DEPOT_CLASS';                   --�f�|�敪
  cv_tcdc_class               CONSTANT VARCHAR2(50)  := 'TCDC_CLASS';                    --TCDC�敪
  cv_upc_flag                 CONSTANT VARCHAR2(50)  := 'UPC_FLAG';                      --UPC�t���O
  cv_simultaneously_class     CONSTANT VARCHAR2(50)  := 'SIMULTANEOUSLY_CLASS';          --��ċ敪
  cv_business_id              CONSTANT VARCHAR2(50)  := 'BUSINESS_ID';                   --�Ɩ�ID
  cv_whse_directly_class      CONSTANT VARCHAR2(50)  := 'WHSE_DIRECTLY_CLASS';           --�q���敪
  cv_premium_rebate_class     CONSTANT VARCHAR2(50)  := 'PREMIUM_REBATE_CLASS';          --���ڎ��
  cv_item_type                CONSTANT VARCHAR2(50)  := 'ITEM_TYPE';                     --�i�i���ߋ敪
  cv_cloth_house_food_class   CONSTANT VARCHAR2(50)  := 'CLOTH_HOUSE_FOOD_CLASS';        --�߉ƐH�敪
  cv_mix_class                CONSTANT VARCHAR2(50)  := 'MIX_CLASS';                     --���݋敪
  cv_stk_class                CONSTANT VARCHAR2(50)  := 'STK_CLASS';                     --�݌ɋ敪
  cv_last_modify_site_class   CONSTANT VARCHAR2(50)  := 'LAST_MODIFY_SITE_CLASS';        --�ŏI�C���ꏊ�敪
  cv_report_class             CONSTANT VARCHAR2(50)  := 'REPORT_CLASS';                  --���[�敪
  cv_addition_plan_class      CONSTANT VARCHAR2(50)  := 'ADDITION_PLAN_CLASS';           --�ǉ��E�v��敪
  cv_registration_class       CONSTANT VARCHAR2(50)  := 'REGISTRATION_CLASS';            --�o�^�敪
  cv_specific_class           CONSTANT VARCHAR2(50)  := 'SPECIFIC_CLASS';                --����敪
  cv_dealings_class           CONSTANT VARCHAR2(50)  := 'DEALINGS_CLASS';                --����敪
  cv_order_class              CONSTANT VARCHAR2(50)  := 'ORDER_CLASS';                   --�����敪
  cv_sum_line_class           CONSTANT VARCHAR2(50)  := 'SUM_LINE_CLASS';                --�W�v���׋敪
  cv_ship_guidance_class      CONSTANT VARCHAR2(50)  := 'SHIPPING_GUIDANCE_CLASS';       --�o�׈ē��ȊO�敪
  cv_ship_class               CONSTANT VARCHAR2(50)  := 'SHIPPING_CLASS';                --�o�׋敪
  cv_prod_code_use_class      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_USE_CLASS';        --���i�R�[�h�g�p�敪
  cv_cargo_item_class         CONSTANT VARCHAR2(50)  := 'CARGO_ITEM_CLASS';              --�ϑ��i�敪
  cv_ta_class                 CONSTANT VARCHAR2(50)  := 'TA_CLASS';                      --T�^A�敪
  cv_plan_code                CONSTANT VARCHAR2(50)  := 'PLAN_CODE';                     --��溰��
  cv_category_code            CONSTANT VARCHAR2(50)  := 'CATEGORY_CODE';                 --�J�e�S���[�R�[�h
  cv_category_class           CONSTANT VARCHAR2(50)  := 'CATEGORY_CLASS';                --�J�e�S���[�敪
  cv_carrier_means            CONSTANT VARCHAR2(50)  := 'CARRIER_MEANS';                 --�^����i
  cv_counter_code             CONSTANT VARCHAR2(50)  := 'COUNTER_CODE';                  --����R�[�h
  cv_move_sign                CONSTANT VARCHAR2(50)  := 'MOVE_SIGN';                     --�ړ��T�C��
  cv_eos_handwriting_class    CONSTANT VARCHAR2(50)  := 'EOS_HANDWRITING_CLASS';         --EOS�E�菑�敪
  cv_delv_to_section_code     CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_SECTION_CODE';      --�[�i��ۃR�[�h
  cv_invc_detailed            CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED';              --�`�[����
  cv_attach_qty               CONSTANT VARCHAR2(50)  := 'ATTACH_QTY';                    --�Y�t��
  cv_op_floor                 CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_FLOOR';             --�t���A
  cv_text_no                  CONSTANT VARCHAR2(50)  := 'TEXT_NO';                       --TEXTNo
  cv_in_store_code            CONSTANT VARCHAR2(50)  := 'IN_STORE_CODE';                 --�C���X�g�A�R�[�h
  cv_tag_data                 CONSTANT VARCHAR2(50)  := 'TAG_DATA';                      --�^�O
  cv_competition_code         CONSTANT VARCHAR2(50)  := 'COMPETITION_CODE';              --����
  cv_billing_chair            CONSTANT VARCHAR2(50)  := 'BILLING_CHAIR';                 --��������
  cv_chain_store_code         CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_CODE';              --�`�F�[���X�g�A�[�R�[�h
  cv_chain_store_short_name   CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_SHORT_NAME';        --���ݽı����ޗ�������
  cv_direct_delv_rcpt_fee     CONSTANT VARCHAR2(50)  := 'DIRECT_DELIVERY_RCPT_FEE';      --���z���^���旿
  cv_bill_info                CONSTANT VARCHAR2(50)  := 'BILL_INFO';                     --��`���
  cv_description              CONSTANT VARCHAR2(50)  := 'DESCRIPTION';                   --�E�v1
  cv_interior_code            CONSTANT VARCHAR2(50)  := 'INTERIOR_CODE';                 --�����R�[�h
  cv_order_info_delv_category CONSTANT VARCHAR2(50)  := 'ORDER_INFO_DELIVERY_CATEGORY';  --������� �[�i�J�e�S���[
  cv_purchase_type            CONSTANT VARCHAR2(50)  := 'PURCHASE_TYPE';                 --�d���`��
  cv_delv_to_name_alt         CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_NAME_ALT';          --�[�i�ꏊ��(�J�i)
  cv_shop_opened_site         CONSTANT VARCHAR2(50)  := 'SHOP_OPENED_SITE';              --�X�o�ꏊ
  cv_counter_name             CONSTANT VARCHAR2(50)  := 'COUNTER_NAME';                  --���ꖼ
  cv_extension_number         CONSTANT VARCHAR2(50)  := 'EXTENSION_NUMBER';              --�����ԍ�
  cv_charge_name              CONSTANT VARCHAR2(50)  := 'CHARGE_NAME';                   --�S���Җ�
  cv_price_tag                CONSTANT VARCHAR2(50)  := 'PRICE_TAG';                     --�l�D
  cv_tax_type                 CONSTANT VARCHAR2(50)  := 'TAX_TYPE';                      --�Ŏ�
  cv_consumption_tax_class    CONSTANT VARCHAR2(50)  := 'CONSUMPTION_TAX_CLASS';         --����ŋ敪
  cv_brand_class              CONSTANT VARCHAR2(50)  := 'BRAND_CLASS';                   --BR
  cv_id_code                  CONSTANT VARCHAR2(50)  := 'ID_CODE';                       --ID�R�[�h
  cv_department_code          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_CODE';               --�S�ݓX�R�[�h
  cv_department_name          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_NAME';               --�S�ݓX��
  cv_item_type_number         CONSTANT VARCHAR2(50)  := 'ITEM_TYPE_NUMBER';              --�i�ʔԍ�
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        --�E�v2(�S�ݓX)
  cv_price_tag_method         CONSTANT VARCHAR2(50)  := 'PRICE_TAG_METHOD';              --�l�D���@
  cv_reason_column            CONSTANT VARCHAR2(50)  := 'REASON_COLUMN';                 --���R��
  cv_a_column_header          CONSTANT VARCHAR2(50)  := 'A_COLUMN_HEADER';               --A���w�b�_
  cv_d_column_header          CONSTANT VARCHAR2(50)  := 'D_COLUMN_HEADER';               --D���w�b�_
  cv_brand_code               CONSTANT VARCHAR2(50)  := 'BRAND_CODE';                    --�u�����h�R�[�h
  cv_line_code                CONSTANT VARCHAR2(50)  := 'LINE_CODE';                     --���C���R�[�h
  cv_class_code               CONSTANT VARCHAR2(50)  := 'CLASS_CODE';                    --�N���X�R�[�h
  cv_a1_column                CONSTANT VARCHAR2(50)  := 'A1_COLUMN';                     --A�|1��
  cv_b1_column                CONSTANT VARCHAR2(50)  := 'B1_COLUMN';                     --B�|1��
  cv_c1_column                CONSTANT VARCHAR2(50)  := 'C1_COLUMN';                     --C�|1��
  cv_d1_column                CONSTANT VARCHAR2(50)  := 'D1_COLUMN';                     --D�|1��
  cv_e1_column                CONSTANT VARCHAR2(50)  := 'E1_COLUMN';                     --E�|1��
  cv_a2_column                CONSTANT VARCHAR2(50)  := 'A2_COLUMN';                     --A�|2��
  cv_b2_column                CONSTANT VARCHAR2(50)  := 'B2_COLUMN';                     --B�|2��
  cv_c2_column                CONSTANT VARCHAR2(50)  := 'C2_COLUMN';                     --C�|2��
  cv_d2_column                CONSTANT VARCHAR2(50)  := 'D2_COLUMN';                     --D�|2��
  cv_e2_column                CONSTANT VARCHAR2(50)  := 'E2_COLUMN';                     --E�|2��
  cv_a3_column                CONSTANT VARCHAR2(50)  := 'A3_COLUMN';                     --A�|3��
  cv_b3_column                CONSTANT VARCHAR2(50)  := 'B3_COLUMN';                     --B�|3��
  cv_c3_column                CONSTANT VARCHAR2(50)  := 'C3_COLUMN';                     --C�|3��
  cv_d3_column                CONSTANT VARCHAR2(50)  := 'D3_COLUMN';                     --D�|3��
  cv_e3_column                CONSTANT VARCHAR2(50)  := 'E3_COLUMN';                     --E�|3��
  cv_f1_column                CONSTANT VARCHAR2(50)  := 'F1_COLUMN';                     --F�|1��
  cv_g1_column                CONSTANT VARCHAR2(50)  := 'G1_COLUMN';                     --G�|1��
  cv_h1_column                CONSTANT VARCHAR2(50)  := 'H1_COLUMN';                     --H�|1��
  cv_i1_column                CONSTANT VARCHAR2(50)  := 'I1_COLUMN';                     --I�|1��
  cv_j1_column                CONSTANT VARCHAR2(50)  := 'J1_COLUMN';                     --J�|1��
  cv_k1_column                CONSTANT VARCHAR2(50)  := 'K1_COLUMN';                     --K�|1��
  cv_l1_column                CONSTANT VARCHAR2(50)  := 'L1_COLUMN';                     --L�|1��
  cv_f2_column                CONSTANT VARCHAR2(50)  := 'F2_COLUMN';                     --F�|2��
  cv_g2_column                CONSTANT VARCHAR2(50)  := 'G2_COLUMN';                     --G�|2��
  cv_h2_column                CONSTANT VARCHAR2(50)  := 'H2_COLUMN';                     --H�|2��
  cv_i2_column                CONSTANT VARCHAR2(50)  := 'I2_COLUMN';                     --I�|2��
  cv_j2_column                CONSTANT VARCHAR2(50)  := 'J2_COLUMN';                     --J�|2��
  cv_k2_column                CONSTANT VARCHAR2(50)  := 'K2_COLUMN';                     --K�|2��
  cv_l2_column                CONSTANT VARCHAR2(50)  := 'L2_COLUMN';                     --L�|2��
  cv_f3_column                CONSTANT VARCHAR2(50)  := 'F3_COLUMN';                     --F�|3��
  cv_g3_column                CONSTANT VARCHAR2(50)  := 'G3_COLUMN';                     --G�|3��
  cv_h3_column                CONSTANT VARCHAR2(50)  := 'H3_COLUMN';                     --H�|3��
  cv_i3_column                CONSTANT VARCHAR2(50)  := 'I3_COLUMN';                     --I�|3��
  cv_j3_column                CONSTANT VARCHAR2(50)  := 'J3_COLUMN';                     --J�|3��
  cv_k3_column                CONSTANT VARCHAR2(50)  := 'K3_COLUMN';                     --K�|3��
  cv_l3_column                CONSTANT VARCHAR2(50)  := 'L3_COLUMN';                     --L�|3��
  cv_chain_pec_area_header    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_HEADER';    --�`�F�[���X�ŗL�G���A(�w�b�_)
  cv_order_connection_number  CONSTANT VARCHAR2(50)  := 'ORDER_CONNECTION_NUMBER';       --�󒍊֘A�ԍ�(��)
  cv_line_no                  CONSTANT VARCHAR2(50)  := 'LINE_NO';                       --�sNo
  cv_stkout_class             CONSTANT VARCHAR2(50)  := 'STOCKOUT_CLASS';                --���i�敪
  cv_stkout_reason            CONSTANT VARCHAR2(50)  := 'STOCKOUT_REASON';               --���i���R
  cv_prod_code_itouen         CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITOUEN';           --���i�R�[�h(�ɓ���)
  cv_prod_code1               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE1';                 --���i�R�[�h1
  cv_prod_code2               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE2';                 --���i�R�[�h2
  cv_jan_code                 CONSTANT VARCHAR2(50)  := 'JAN_CODE';                      --JAN�R�[�h
  cv_itf_code                 CONSTANT VARCHAR2(50)  := 'ITF_CODE';                      --ITF�R�[�h
  cv_extension_itf_code       CONSTANT VARCHAR2(50)  := 'EXTENSION_ITF_CODE';            --����ITF�R�[�h
  cv_case_prod_code           CONSTANT VARCHAR2(50)  := 'CASE_PRODUCT_CODE';             --�P�[�X���i�R�[�h
  cv_ball_prod_code           CONSTANT VARCHAR2(50)  := 'BALL_PRODUCT_CODE';             --�{�[�����i�R�[�h
  cv_prod_code_item_type      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITEM_TYPE';        --���i�R�[�h�i��
  cv_prod_class               CONSTANT VARCHAR2(50)  := 'PROD_CLASS';                    --���i�敪
  cv_prod_name                CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME';                  --���i��(����)
  cv_prod_name1_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME1_ALT';             --���i��1(�J�i)
  cv_prod_name2_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME2_ALT';             --���i��2(�J�i)
  cv_item_standard1           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD1';                --�K�i1
  cv_item_standard2           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD2';                --�K�i2
  cv_qty_in_case              CONSTANT VARCHAR2(50)  := 'QTY_IN_CASE';                   --����
  cv_num_of_cases             CONSTANT VARCHAR2(50)  := 'NUM_OF_CASES';                  --�P�[�X����
  cv_num_of_ball              CONSTANT VARCHAR2(50)  := 'NUM_OF_BALL';                   --�{�[������
  cv_item_color               CONSTANT VARCHAR2(50)  := 'ITEM_COLOR';                    --�F
  cv_item_size                CONSTANT VARCHAR2(50)  := 'ITEM_SIZE';                     --�T�C�Y
  cv_expiration_date          CONSTANT VARCHAR2(50)  := 'EXPIRATION_DATE';               --�ܖ�������
  cv_prod_date                CONSTANT VARCHAR2(50)  := 'PRODUCT_DATE';                  --������
  cv_order_uom_qty            CONSTANT VARCHAR2(50)  := 'ORDER_UOM_QTY';                 --�����P�ʐ�
  cv_ship_uom_qty             CONSTANT VARCHAR2(50)  := 'SHIPPING_UOM_QTY';              --�o�גP�ʐ�
  cv_packing_uom_qty          CONSTANT VARCHAR2(50)  := 'PACKING_UOM_QTY';               --����P�ʐ�
  cv_deal_code                CONSTANT VARCHAR2(50)  := 'DEAL_CODE';                     --����
  cv_deal_class               CONSTANT VARCHAR2(50)  := 'DEAL_CLASS';                    --�����敪
  cv_collation_code           CONSTANT VARCHAR2(50)  := 'COLLATION_CODE';                --�ƍ�
  cv_uom_code                 CONSTANT VARCHAR2(50)  := 'UOM_CODE';                      --�P��
  cv_unit_price_class         CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_CLASS';              --�P���敪
  cv_parent_packing_number    CONSTANT VARCHAR2(50)  := 'PARENT_PACKING_NUMBER';         --�e����ԍ�
  cv_packing_number           CONSTANT VARCHAR2(50)  := 'PACKING_NUMBER';                --����ԍ�
  cv_prod_group_code          CONSTANT VARCHAR2(50)  := 'PRODUCT_GROUP_CODE';            --���i�Q�R�[�h
  cv_case_dismantle_flag      CONSTANT VARCHAR2(50)  := 'CASE_DISMANTLE_FLAG';           --�P�[�X��̕s�t���O
  cv_case_class               CONSTANT VARCHAR2(50)  := 'CASE_CLASS';                    --�P�[�X�敪
  cv_indv_order_qty           CONSTANT VARCHAR2(50)  := 'INDV_ORDER_QTY';                --��������(�o��)
  cv_case_order_qty           CONSTANT VARCHAR2(50)  := 'CASE_ORDER_QTY';                --��������(�P�[�X)
  cv_ball_order_qty           CONSTANT VARCHAR2(50)  := 'BALL_ORDER_QTY';                --��������(�{�[��)
  cv_sum_order_qty            CONSTANT VARCHAR2(50)  := 'SUM_ORDER_QTY';                 --��������(���v�A�o��)
  cv_indv_ship_qty            CONSTANT VARCHAR2(50)  := 'INDV_SHIPPING_QTY';             --�o�א���(�o��)
  cv_case_ship_qty            CONSTANT VARCHAR2(50)  := 'CASE_SHIPPING_QTY';             --�o�א���(�P�[�X)
  cv_ball_ship_qty            CONSTANT VARCHAR2(50)  := 'BALL_SHIPPING_QTY';             --�o�א���(�{�[��)
  cv_pallet_ship_qty          CONSTANT VARCHAR2(50)  := 'PALLET_SHIPPING_QTY';           --�o�א���(�p���b�g)
  cv_sum_ship_qty             CONSTANT VARCHAR2(50)  := 'SUM_SHIPPING_QTY';              --�o�א���(���v�A�o��)
  cv_indv_stkout_qty          CONSTANT VARCHAR2(50)  := 'INDV_STOCKOUT_QTY';             --���i����(�o��)
  cv_case_stkout_qty          CONSTANT VARCHAR2(50)  := 'CASE_STOCKOUT_QTY';             --���i����(�P�[�X)
  cv_ball_stkout_qty          CONSTANT VARCHAR2(50)  := 'BALL_STOCKOUT_QTY';             --���i����(�{�[��)
  cv_sum_stkout_qty           CONSTANT VARCHAR2(50)  := 'SUM_STOCKOUT_QTY';              --���i����(���v�A�o��)
  cv_case_qty                 CONSTANT VARCHAR2(50)  := 'CASE_QTY';                      --�P�[�X����
  cv_fold_container_indv_qty  CONSTANT VARCHAR2(50)  := 'FOLD_CONTAINER_INDV_QTY';       --�I���R��(�o��)����
  cv_order_unit_price         CONSTANT VARCHAR2(50)  := 'ORDER_UNIT_PRICE';              --���P��(����)
  cv_ship_unit_price          CONSTANT VARCHAR2(50)  := 'SHIPPING_UNIT_PRICE';           --���P��(�o��)
  cv_order_cost_amt           CONSTANT VARCHAR2(50)  := 'ORDER_COST_AMT';                --�������z(����)
  cv_ship_cost_amt            CONSTANT VARCHAR2(50)  := 'SHIPPING_COST_AMT';             --�������z(�o��)
  cv_stkout_cost_amt          CONSTANT VARCHAR2(50)  := 'STOCKOUT_COST_AMT';             --�������z(���i)
  cv_selling_price            CONSTANT VARCHAR2(50)  := 'SELLING_PRICE';                 --���P��
  cv_order_price_amt          CONSTANT VARCHAR2(50)  := 'ORDER_PRICE_AMT';               --�������z(����)
  cv_ship_price_amt           CONSTANT VARCHAR2(50)  := 'SHIPPING_PRICE_AMT';            --�������z(�o��)
  cv_stkout_price_amt         CONSTANT VARCHAR2(50)  := 'STOCKOUT_PRICE_AMT';            --�������z(���i)
  cv_a_column_department      CONSTANT VARCHAR2(50)  := 'A_COLUMN_DEPARTMENT';           --A��(�S�ݓX)
  cv_d_column_department      CONSTANT VARCHAR2(50)  := 'D_COLUMN_DEPARTMENT';           --D��(�S�ݓX)
  cv_standard_info_depth      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_DEPTH';           --�K�i���E���s��
  cv_standard_info_height     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_HEIGHT';          --�K�i���E����
  cv_standard_info_width      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WIDTH';           --�K�i���E��
  cv_standard_info_weight     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WEIGHT';          --�K�i���E�d��
  cv_gen_suc_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM1';       --�ėp���p������1
  cv_gen_suc_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM2';       --�ėp���p������2
  cv_gen_suc_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM3';       --�ėp���p������3
  cv_gen_suc_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM4';       --�ėp���p������4
  cv_gen_suc_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM5';       --�ėp���p������5
  cv_gen_suc_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM6';       --�ėp���p������6
  cv_gen_suc_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM7';       --�ėp���p������7
  cv_gen_suc_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM8';       --�ėp���p������8
  cv_gen_suc_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM9';       --�ėp���p������9
  cv_gen_suc_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM10';      --�ėp���p������10
  cv_gen_add_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM1';             --�ėp�t������1
  cv_gen_add_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM2';             --�ėp�t������2
  cv_gen_add_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM3';             --�ėp�t������3
  cv_gen_add_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM4';             --�ėp�t������4
  cv_gen_add_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM5';             --�ėp�t������5
  cv_gen_add_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM6';             --�ėp�t������6
  cv_gen_add_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM7';             --�ėp�t������7
  cv_gen_add_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM8';             --�ėp�t������8
  cv_gen_add_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM9';             --�ėp�t������9
  cv_gen_add_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM10';            --�ėp�t������10
  cv_chain_pec_area_line      CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_LINE';      --�`�F�[���X�ŗL�G���A(����)
  cv_invc_indv_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_ORDER_QTY';        --(�`�[�v)��������(�o��)
  cv_invc_case_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_ORDER_QTY';        --(�`�[�v)��������(�P�[�X)
  cv_invc_ball_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_ORDER_QTY';        --(�`�[�v)��������(�{�[��)
  cv_invc_sum_order_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_ORDER_QTY';         --(�`�[�v)��������(���v�A�o��)
  cv_invc_indv_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_SHIPPING_QTY';     --(�`�[�v)�o�א���(�o��)
  cv_invc_case_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_SHIPPING_QTY';     --(�`�[�v)�o�א���(�P�[�X)
  cv_invc_ball_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_SHIPPING_QTY';     --(�`�[�v)�o�א���(�{�[��)
  cv_invc_pallet_ship_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_PALLET_SHIPPING_QTY';   --(�`�[�v)�o�א���(�p���b�g)
  cv_invc_sum_ship_qty        CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_SHIPPING_QTY';      --(�`�[�v)�o�א���(���v�A�o��)
  cv_invc_indv_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_STOCKOUT_QTY';     --(�`�[�v)���i����(�o��)
  cv_invc_case_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_STOCKOUT_QTY';     --(�`�[�v)���i����(�P�[�X)
  cv_invc_ball_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_STOCKOUT_QTY';     --(�`�[�v)���i����(�{�[��)
  cv_invc_sum_stkout_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_STOCKOUT_QTY';      --(�`�[�v)���i����(���v�A�o��)
  cv_invc_case_qty            CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_QTY';              --(�`�[�v)�P�[�X����
  cv_invc_fold_container_qty  CONSTANT VARCHAR2(50)  := 'INVOICE_FOLD_CONTAINER_QTY';    --(�`�[�v)�I���R��(�o��)����
  cv_invc_order_cost_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_COST_AMT';        --(�`�[�v)�������z(����)
  cv_invc_ship_cost_amt       CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_COST_AMT';     --(�`�[�v)�������z(�o��)
  cv_invc_stkout_cost_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_COST_AMT';     --(�`�[�v)�������z(���i)
  cv_invc_order_price_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_PRICE_AMT';       --(�`�[�v)�������z(����)
  cv_invc_ship_price_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_PRICE_AMT';    --(�`�[�v)�������z(�o��)
  cv_invc_stkout_price_amt    CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_PRICE_AMT';    --(�`�[�v)�������z(���i)
  cv_t_indv_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_ORDER_QTY';          --(�����v)��������(�o��)
  cv_t_case_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_ORDER_QTY';          --(�����v)��������(�P�[�X)
  cv_t_ball_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_ORDER_QTY';          --(�����v)��������(�{�[��)
  cv_t_sum_order_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_ORDER_QTY';           --(�����v)��������(���v�A�o��)
  cv_t_indv_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_SHIPPING_QTY';       --(�����v)�o�א���(�o��)
  cv_t_case_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_SHIPPING_QTY';       --(�����v)�o�א���(�P�[�X)
  cv_t_ball_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_SHIPPING_QTY';       --(�����v)�o�א���(�{�[��)
  cv_t_pallet_ship_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_PALLET_SHIPPING_QTY';     --(�����v)�o�א���(�p���b�g)
  cv_t_sum_ship_qty           CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_SHIPPING_QTY';        --(�����v)�o�א���(���v�A�o��)
  cv_t_indv_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_STOCKOUT_QTY';       --(�����v)���i����(�o��)
  cv_t_case_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_STOCKOUT_QTY';       --(�����v)���i����(�P�[�X)
  cv_t_ball_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_STOCKOUT_QTY';       --(�����v)���i����(�{�[��)
  cv_t_sum_stkout_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_STOCKOUT_QTY';        --(�����v)���i����(���v�A�o��)
  cv_t_case_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_QTY';                --(�����v)�P�[�X����
  cv_t_fold_container_qty     CONSTANT VARCHAR2(50)  := 'TOTAL_FOLD_CONTAINER_QTY';      --(�����v)�I���R��(�o��)����
  cv_t_order_cost_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_COST_AMT';          --(�����v)�������z(����)
  cv_t_ship_cost_amt          CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_COST_AMT';       --(�����v)�������z(�o��)
  cv_t_stkout_cost_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_COST_AMT';       --(�����v)�������z(���i)
  cv_t_order_price_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_PRICE_AMT';         --(�����v)�������z(����)
  cv_t_ship_price_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_PRICE_AMT';      --(�����v)�������z(�o��)
  cv_t_stkout_price_amt       CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_PRICE_AMT';      --(�����v)�������z(���i)
  cv_t_line_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_LINE_QTY';                --�g�[�^���s��
  cv_t_invc_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_INVOICE_QTY';             --�g�[�^���`�[����
  cv_chain_pec_area_footer    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_FOOTER';    --�`�F�[���X�ŗL�G���A(�t�b�^)
/* 2009/04/28 Ver1.3 Add Start */
  cv_attribute                CONSTANT VARCHAR2(50)  := 'ATTRIBUTE';                     -- �\���G���A
/* 2009/04/28 Ver1.3 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  gt_f_handle                 UTL_FILE.FILE_TYPE;                              -- �t�@�C���n���h��
  gt_data_type_table          xxcos_common2_pkg.g_record_layout_ttype;         -- �t�@�C�����C�A�E�g
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --���������擾�p
  gn_no_inv_item_cnt          NUMBER DEFAULT 0;                        -- ��݌ɕi����
  gn_chain_store_cnt          NUMBER DEFAULT 0;                        -- �Ώی���(�`�F�[���X)
  gn_data_cnt                 NUMBER DEFAULT 0;                        -- �Ώی���(�`�F�[���X���̑Ώیڋq�̔�����)
  --�f�[�^�擾�p
  gv_prf_organization_code    VARCHAR2(50)  DEFAULT NULL;              -- XXCOI:�݌ɑg�D�R�[�h
  gv_prf_organization_id      VARCHAR2(50)  DEFAULT NULL;              -- XXCOS:�݌ɑg�DID
  gn_org_id                   NUMBER        DEFAULT NULL;              -- MO:�c�ƒP��
  -- �t�@�C���o�͍��ڗp
  gv_f_o_date                 CHAR(8);                                 -- ������
  gv_f_o_time                 CHAR(6);                                 -- ��������
  gt_edi_media_class          xxcos_lookup_values_v.lookup_code%TYPE;  -- EDI�}�̋敪
  gt_data_type_code           xxcos_lookup_values_v.lookup_code%TYPE;  -- �f�[�^��R�[�h
  gt_edi_seales_class         fnd_lookup_values_vl.lookup_code%TYPE;   -- ����敪�i���^�j
  -- ��������A���ʊ֐��p
  gt_from_series              xxcos_lookup_values_v.attribute1%TYPE;   -- IF���Ɩ��n��R�[�h
  gv_if_header                VARCHAR2(2)   DEFAULT NULL;              -- �w�b�_���R�[�h�敪
  gv_if_data                  VARCHAR2(2)   DEFAULT NULL;              -- �f�[�^���R�[�h�敪
  gv_if_footer                VARCHAR2(2)   DEFAULT NULL;              -- �t�b�^���R�[�h�敪
  gv_utl_m_line               VARCHAR2(100) DEFAULT NULL;              -- UTL_MAX�s�T�C�Y
  gv_outbound_d               VARCHAR2(100) DEFAULT NULL;              -- �A�E�g�o�E���h�p�f�B���N�g���p�X
  gv_dept_code                VARCHAR2(100) DEFAULT NULL;              -- �Ɩ��Ǘ����R�[�h
  gv_prf_def_item_rate        VARCHAR2(100) DEFAULT NULL;              -- XXCOS:EDI�f�t�H���g����
  gv_in_file_name             VARCHAR2(240) DEFAULT NULL;              -- �t�@�C����
/* 2010/03/16 Ver1.10 Del Start */
--  gv_run_class_create         VARCHAR2(50)  DEFAULT NULL;              -- ���s�敪�F�u�쐬�v����
--  gv_run_class_cancel         VARCHAR2(50)  DEFAULT NULL;              -- ���s�敪�F�u�����v����
--  gv_run_class_cd_create      VARCHAR2(2)   DEFAULT NULL;              -- ���s�敪�F�u�쐬�v�R�[�h
--  gv_run_class_cd_cancel      VARCHAR2(2)   DEFAULT NULL;              -- ���s�敪�F�u�����v�R�[�h
/* 2010/03/16 Ver1.10 Del End   */
/* 2010/03/16 Ver1.10 Add Start */
  gd_min_date                 DATE;                                    -- MIN���t
  gd_max_date                 DATE;                                    -- MAX���t
  gn_edi_trg_hold_m           NUMBER;                                  -- EDI�̔����ёΏەێ�����
/* 2010/03/16 Ver1.10 Add End   */
  --�t�@�C���w�b�_���
  gt_sales_base_name          hz_parties.party_name%TYPE;                   --���_��
  gt_edi_chain_name           hz_parties.party_name%TYPE;                   --EDI�`�F�[���X��
  gt_edi_chain_name_phonetic  hz_parties.organization_name_phonetic%TYPE;   --EDI�`�F�[���X�J�i
--****************�@2009/07/07   N.Maeda  Ver1.5   ADD   START  *********************************************--
  gt_parallel_num             xxcos_lookup_values_v.attribute1%TYPE;   -- �t�@�C��No
--****************�@2009/07/07   N.Maeda  Ver1.5   ADD    END   *********************************************--
  -- ===================================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===================================
  --�����Ώیڋq(�`�F�[���X�P��)
  TYPE g_chain_store_rtype IS RECORD(
    chain_store_code  fnd_lookup_values.description%TYPE,  --�`�F�[���X�R�[�h
    process_pattern   fnd_lookup_values.attribute1%TYPE    --�����p�^�[��
  );
  --�̔����я��
  TYPE g_edi_sales_data_rtype IS RECORD(
    sales_exp_header_id          xxcos_sales_exp_headers.sales_exp_header_id%TYPE,          --�̔����уw�b�_ID
    sales_exp_line_id            xxcos_sales_exp_lines.sales_exp_line_id%TYPE,              --�̔����і���ID
    sales_base_code              xxcos_sales_exp_headers.sales_base_code%TYPE,              --���_(����)�R�[�h
    sales_base_name              hz_parties.party_name%TYPE,                                --���_��(������)
    sales_base_phonetic          hz_parties.organization_name_phonetic%TYPE,                --���_��(�J�i)
/* 2009/11/27 Ver1.9 Add Start */
    order_invoice_number         xxcos_sales_exp_headers.order_invoice_number%TYPE,         --����攭���ԍ�
/* 2009/11/27 Ver1.9 Add End   */
    ship_to_customer_code        xxcos_sales_exp_headers.ship_to_customer_code%TYPE,        --�ڋq�R�[�h
    customer_name                hz_parties.party_name%TYPE,                                --�ڋq��(����)
    customer_phonetic            hz_parties.organization_name_phonetic%TYPE,                --�ڋq��(�J�i)
    orig_delivery_date           xxcos_sales_exp_headers.orig_delivery_date%TYPE,           --�X�ܔ[�i��
    invoice_class                xxcos_sales_exp_headers.invoice_class%TYPE,                --�`�[�敪
    invoice_classification_code  xxcos_sales_exp_headers.invoice_classification_code%TYPE,  --�啪�ރR�[�h
    dlv_invoice_number           xxcos_sales_exp_headers.dlv_invoice_number%TYPE,           --�`�[�ԍ�
    address                      VARCHAR2(255),                                             --�͂���Z��(����)
    sales_exp_day                ra_terms_vl.due_cutoff_day%TYPE,                           --�����J�n��*���������̕ҏW��*
    orig_inspect_date            xxcos_sales_exp_headers.orig_inspect_date%TYPE,            --�ėp���t���ڂP�A�Q
    dlv_invoice_class            xxcos_sales_exp_headers.dlv_invoice_class%TYPE,            --�o�׋敪
    bill_cred_rec_code2          hz_cust_site_uses_all.attribute5%TYPE,                     --�`�F�[���X�ŗL�G���A(�w�b�_�[)
    dlv_invoice_line_number      xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE,        --�sNo
    item_code                    xxcos_sales_exp_lines.item_code%TYPE,                      --���i�R�[�h(�ɓ���)
    jan_code                     ic_item_mst_b.attribute21%TYPE,                            --JAN�R�[�h
    itf_code                     ic_item_mst_b.attribute22%TYPE,                            --ITF�R�[�h
    item_div_code                mtl_categories_b.segment1%TYPE,                            --���i�敪
    item_name                    xxcmn_item_mst_b.item_name%TYPE,                           --���i��(����)
    item_phonetic1               VARCHAR2(15),                                              --���i���Q(�J�i)
    item_phonetic2               VARCHAR2(15),                                              --�K�i�Q
    case_inc_num                 ic_item_mst_b.attribute11%TYPE,                            --�P�[�X����
    bowl_inc_num                 xxcmm_system_items_b.bowl_inc_num%TYPE,                    --�{�[������
    standard_qty                 xxcos_sales_exp_lines.standard_qty%TYPE,                   --�o�א���(�o��),(���v�A�o��)
    standard_unit_price          xxcos_sales_exp_lines.standard_unit_price%TYPE,            --���P��(����)
    sale_amount                  xxcos_sales_exp_lines.sale_amount%TYPE,                    --�������z(�o��)
    sales_class                  xxcos_sales_exp_lines.sales_class%TYPE,                    --�ėp�t�����ڂQ
    sum_standard_qty             NUMBER(10,1),                                              --(�`�[�v)�o�א���(�o��),(���v�A�o��)
    sum_sale_amount              NUMBER(14,2),                                              --(�`�[�v)�������z(�o��)
    send_code1                    hz_cust_site_uses_all.attribute4%TYPE,                    --���|�R�[�h1(������)*���g�p
    send_code3                    hz_cust_site_uses_all.attribute6%TYPE,                    --���|�R�[�h3(���̑�)*���g�p
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
    edi_forward_number           xxcmm_cust_accounts.edi_forward_number%TYPE,               --EDI�`�[�ǔ�
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
-- 2009/06/25 M.Sano Ver.1.5 add Start
    standard_uom_code            xxcos_sales_exp_lines.standard_uom_code%TYPE               --�����
-- 2009/06/25 M.Sano Ver.1.5 add End
  );
--
/* 2009/07/29 Ver1.5 Add Start */
  --�`�[�v���
  TYPE g_sum_qty_rtype IS RECORD(
    invc_indv_qty_sum  NUMBER,  --(�`�[�v)�o�א���(�o��)
    invc_case_qty_sum  NUMBER,  --(�`�[�v)�o�א���(�P�[�X)
    invc_ball_qty_sum  NUMBER   --(�`�[�v)�o�א���(�{�[��)
  );
/* 2009/07/29 Ver1.5 Add End   */
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  --��݌ɕi���
  TYPE g_no_inv_item_ttype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE INDEX BY BINARY_INTEGER;
  gt_no_inv_item         g_no_inv_item_ttype;
  --�����Ώیڋq(�`�F�[���X�P��)
  TYPE g_chain_store_ttype IS TABLE OF g_chain_store_rtype INDEX BY BINARY_INTEGER;
  gt_chain_store         g_chain_store_ttype;
  --�̔����я��
  TYPE g_edi_sales_data_ttype IS TABLE OF g_edi_sales_data_rtype INDEX BY BINARY_INTEGER;
  gt_edi_sales_data      g_edi_sales_data_ttype;
  gt_edi_sales_data_c    g_edi_sales_data_ttype;  --�e�[�u���^�ϐ��������p
  --�̔����уw�b�_�X�V
  TYPE g_header_id_ttype IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE INDEX BY BINARY_INTEGER;
  gt_update_header_id    g_header_id_ttype;
  gt_update_header_id_c  g_header_id_ttype;  --�e�[�u���^�ϐ��������p
/* 2009/07/29 Ver1.5 Add Start */
  --�`�[�v��� �e�[�u���^
  TYPE g_sum_qty_ttype IS TABLE OF g_sum_qty_rtype INDEX BY VARCHAR2(21);
  gt_sum_qty             g_sum_qty_ttype;
/* 2009/07/29 Ver1.5 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : input_param_check
   * Description      : ���̓p�����^�`�F�b�N����(A-1)
   ***********************************************************************************/
  PROCEDURE input_param_check(
    iv_run_class        IN  VARCHAR2,  --   ���s�敪�F�u0:�쐬�v�u1:�����v�u2:�ΏۊO�X�V�v
    iv_inv_cust_code    IN  VARCHAR2,  --   ������ڋq�R�[�h
    iv_send_date        IN  VARCHAR2,  --   ���M��(YYYYMMDD)
/* 2009/04/15 Add Start */
    iv_sales_exp_ptn    IN VARCHAR2,   --   EDI�̔����я����p�^�[��
/* 2009/04/15 Add End   */
    ov_errbuf           OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_param_check'; -- �v���O������
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
    lv_param_msg      VARCHAR2(5000)  DEFAULT NULL;  --�p�����[�^�[�o�͗p
    lv_tkn_name       VARCHAR2(50)    DEFAULT NULL;  --�g�[�N���擾�p
    ld_date_value     DATE;
/* 2010/03/16 Ver1.10 Add Start */
    lv_run_class_chk  VARCHAR2(1);                   --���s�敪�`�F�b�N�p
/* 2010/03/16 Ver1.10 Add End   */
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
    --==============================================================
    --  �R���J�����g���͍��ڏo��
    --==============================================================
    IF  ( iv_run_class = cv_0 ) THEN
      --* -------------------------------------------------------------
      -- ���s�敪�F�u�쐬�v
      --* -------------------------------------------------------------
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --�A�v���P�[�V����
                        ,iv_name         => cv_msg_param_create  --�p�����[�^�[�o��(�쐬)
                        ,iv_token_name1  => cv_tkn_parame1       --�g�[�N���R�[�h�P
                        ,iv_token_value1 => iv_run_class         --���s�敪
                        ,iv_token_name2  => cv_tkn_parame2       --�g�[�N���R�[�h�Q
/* 2009/04/15 Mod Start */
--                        ,iv_token_value2 => iv_inv_cust_code     --������ڋq�R�[�h
                        ,iv_token_value2 => iv_sales_exp_ptn     --EDI�̔����я����p�^�[��
/* 2009/04/15 Mod Start */
                      );
    ELSIF ( iv_run_class = cv_1 ) THEN
      --* -------------------------------------------------------------
      -- ���s�敪�F�u�����v
      --* ------------------------------------------------------------- 
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --�A�v���P�[�V����
                        ,iv_name         => cv_msg_param_cancel  --�p�����[�^�[�o��(����)
                        ,iv_token_name1  => cv_tkn_parame1       --�g�[�N���R�[�h�P
                        ,iv_token_value1 => iv_run_class         --���s�敪
                        ,iv_token_name2  => cv_tkn_parame2       --�g�[�N���R�[�h�Q
                        ,iv_token_value2 => iv_inv_cust_code     --������ڋq�R�[�h
                        ,iv_token_name3  => cv_tkn_parame3       --�g�[�N���R�[�h�R
                        ,iv_token_value3 => iv_send_date         --���M��(YYYYMMDD)
                     );
/* 2010/03/16 Ver1.10 Add Start */
    ELSIF ( iv_run_class = cv_2 ) THEN
      --* -------------------------------------------------------------
      -- ���s�敪�F�u�ΏۊO�X�V�v
      --* ------------------------------------------------------------- 
      lv_param_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --�A�v���P�[�V����
                        ,iv_name         => cv_msg_param_update  --�p�����[�^�[�o��(�ΏۊO�X�V)
                        ,iv_token_name1  => cv_tkn_parame1       --�g�[�N���R�[�h�P
                        ,iv_token_value1 => iv_run_class         --���s�敪
                     );
/* 2010/03/16 Ver1.10 Add End   */
    END IF;
    --�p�����[�^�����b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --�p�����[�^�����O�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
  --
    --==============================================================
    --  �R���J�����g���͍��ڃ`�F�b�N
    --==============================================================
    --* -------------------------------------------------------------
    --  ���s�敪NULL�`�F�b�N
    --* -------------------------------------------------------------
    IF  ( iv_run_class  IS NULL ) THEN
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_application
                       ,iv_name         =>  cv_msg_run_class  --�u���s�敪�v
                     );
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                iv_application   =>  cv_application,
                iv_name          =>  cv_msg_param_err, --�K�{���̓p�����[�^���ݒ�G���[
                iv_token_name1   =>  cv_tkn_in_param,
                iv_token_value1  =>  lv_tkn_name
                );
      RAISE global_api_expt;
    END IF;
/* 2010/03/16 Ver1.10 Del Start */
--    --* -------------------------------------------------------------
--    --  �擾����EDI�̔����э쐬���s�敪�ƃp�����[�^�̃`�F�b�N
--    --* -------------------------------------------------------------
--    --�����擾
--    gv_run_class_create := xxccp_common_pkg.get_msg(
--                              iv_application  =>  cv_application
--                             ,iv_name         =>  cv_msg_create  --�u�쐬�v
--                           );
--    gv_run_class_cancel := xxccp_common_pkg.get_msg(
--                              iv_application  =>  cv_application --�A�v���P�[�V����
--                             ,iv_name         =>  cv_msg_cancel  --�u�����v
--                           );
/* 2010/03/16 Ver1.10 Del End   */
    -- EDI�̔����э쐬���s�敪�`�F�b�N
    BEGIN
/* 2010/03/16 Ver1.10 Mod Start */
--      SELECT xlvv.lookup_code lookup_code
--      INTO   gv_run_class_cd_create
      SELECT 'X'
      INTO   lv_run_class_chk
/* 2010/03/16 Ver1.10 Mod End   */
      FROM   xxcos_lookup_values_v  xlvv
      WHERE  xlvv.lookup_type   = cv_lkt_edi_s_exe_type -- EDI�̔����э쐬���s�敪
/* 2010/03/16 Ver1.10 Mod Start */
--      AND    xlvv.meaning       = gv_run_class_create   --�u�쐬�v
      AND    xlvv.lookup_code   = iv_run_class          -- ���s�敪
/* 2010/03/16 Ver1.10 Mod End   */
      AND    (
               ( xlvv.start_date_active IS NULL )
               OR
               ( xlvv.start_date_active <= cd_process_date )
             )
      AND    (
               ( xlvv.end_date_active   IS NULL )
               OR
               ( xlvv.end_date_active   >= cd_process_date )
             )  -- �Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_run_class  --�u���s�敪�v
                       );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_application
                       ,iv_name          =>  cv_msg_in_param_err  --���̓p�����[�^�s���G���[
                       ,iv_token_name1   =>  cv_tkn_in_param
                       ,iv_token_value1  =>  lv_tkn_name
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
/* 2010/03/16 Ver1.10 Del Start */
--    -- EDI�̔����э쐬���s�敪�擾(����)
--    BEGIN
--      SELECT xlvv.lookup_code lookup_code
--      INTO   gv_run_class_cd_cancel
--      FROM   xxcos_lookup_values_v  xlvv
--      WHERE  xlvv.lookup_type   = cv_lkt_edi_s_exe_type  -- EDI�̔����э쐬���s�敪
--      AND    xlvv.meaning       = gv_run_class_cancel    --�u�����v
--      AND    (
--               ( xlvv.start_date_active IS NULL )
--               OR
--               ( xlvv.start_date_active <= cd_process_date )
--             )
--      AND    (
--               ( xlvv.end_date_active   IS NULL )
--               OR
--               ( xlvv.end_date_active   >= cd_process_date )
--             )  -- �Ɩ����t��FROM-TO��
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        lv_tkn_name := xxccp_common_pkg.get_msg(
--                          iv_application  => cv_application
--                         ,iv_name         => cv_msg_run_class  --�u���s�敪�v
--                       );
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                        iv_application   =>  cv_application
--                       ,iv_name          =>  cv_msg_in_param_err  --���̓p�����[�^�s���G���[
--                       ,iv_token_name1   =>  cv_tkn_in_param
--                       ,iv_token_value1  =>  lv_tkn_name
--                     );
--        lv_errbuf  := SQLERRM;
--        RAISE global_api_expt;
--    END;
--    -- �`�F�b�N����
--    IF ( ( iv_run_class <> gv_run_class_cd_create )
--      AND ( iv_run_class <> gv_run_class_cd_cancel ) )
--    THEN
--      lv_tkn_name := xxccp_common_pkg.get_msg(
--                        iv_application  =>  cv_application
--                       ,iv_name         =>  cv_msg_run_class  --�u���s�敪�v
--                     );
--      lv_errmsg :=  xxccp_common_pkg.get_msg(
--                       iv_application   =>  cv_application
--                      ,iv_name          =>  cv_msg_in_param_err  --���̓p�����[�^�s���G���[
--                      ,iv_token_name1   =>  cv_tkn_in_param
--                      ,iv_token_value1  =>  lv_tkn_name
--                    );
--      RAISE global_api_expt;
--    END IF;
--
/* 2010/03/16 Ver1.10 Del End  */
    --�u�����v�̏ꍇ
    IF  ( iv_run_class = gv_run_class_cd_cancel ) THEN
      --* -------------------------------------------------------------
      --  ������ڋq�R�[�h�̕K�{�`�F�b�N
      --* -------------------------------------------------------------
      IF ( iv_inv_cust_code IS NULL ) THEN
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_application
                         ,iv_name         =>  cv_msg_bill_account  --�u������ڋq�R�[�h�v
                       );
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                        ,iv_name          =>  cv_msg_param_err  --�K�{���̓p�����[�^���ݒ�G���[
                        ,iv_token_name1   =>  cv_tkn_in_param
                        ,iv_token_value1  =>  lv_tkn_name
                      );
        RAISE global_api_expt;
      END IF;
      --* -------------------------------------------------------------
      --  ���M���̕K�{�`�F�b�N
      --* -------------------------------------------------------------
      IF ( iv_send_date IS NULL ) THEN
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_application
                         ,iv_name         =>  cv_msg_send_date  --�u���M���v
                       );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_application
                       ,iv_name          =>  cv_msg_param_err  --�K�{���̓p�����[�^���ݒ�G���[
                       ,iv_token_name1   =>  cv_tkn_in_param
                       ,iv_token_value1  =>  lv_tkn_name
                     );
        RAISE global_api_expt;
      END IF;
    END IF;
    --* -------------------------------------------------------------
    --  ���M���̏����`�F�b�N
    --* -------------------------------------------------------------
    IF ( iv_send_date IS NOT NULL ) THEN
      --���t(YYYYMMDD)���ǂ����̃`�F�b�N
      BEGIN
        SELECT  TO_DATE( iv_send_date, cv_date_format )
        INTO    ld_date_value
        FROM    DUAL;
      EXCEPTION
      -- *** OTHERS��O�n���h�� ***
        WHEN OTHERS THEN
          lv_tkn_name := xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_application
                           ,iv_name         =>  cv_msg_send_date  --�u���M���v
                         );
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_application
                         ,iv_name          =>  cv_msg_date_err  --���t�����G���[
                         ,iv_token_name1   =>  cv_tkn_para_d
                         ,iv_token_value1  =>  lv_tkn_name
                       );
          lv_errbuf  := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END input_param_check;
--
  /**********************************************************************************
   * Procedure Name   : get_custom_data
   * Description      : �����Ώیڋq�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_custom_data(
    iv_inv_cust_code    IN  VARCHAR2,     --   ������ڋq�R�[�h
/* 2009/04/15 Add Start */
    iv_sales_exp_ptn    IN  VARCHAR2,     --   EDI�̔����я����p�^�[��
/* 2009/04/15 Add End   */
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_custom_data'; -- �v���O������
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
    lv_tkn_name1  VARCHAR2(50)  DEFAULT NULL;  --�g�[�N���擾�p1
    lv_tkn_name2  VARCHAR2(50)  DEFAULT NULL;  --�g�[�N���擾�p2
--
    -- *** ���[�J���E�J�[�\�� ***
--
    --�Ώیڋq�擾�J�[�\��(�`�F�[���X�P��)
    CURSOR chain_store_cur
    IS
      SELECT  xlvv.description         chain_store_code  --�`�F�[���X
             ,MAX( xlvv.attribute1 )   process_pattern   --�����p�^�[��
      FROM    xxcos_lookup_values_v  xlvv
      WHERE   xlvv.lookup_type = cv_lkt_sales_edi_cust  --������ڋq�R�[�h
      AND     (
                ( xlvv.start_date_active IS NULL )
                OR
                ( xlvv.start_date_active <= cd_process_date )
              )
      AND     (
                ( xlvv.end_date_active   IS NULL )
                OR
                ( xlvv.end_date_active >= cd_process_date )
              )  -- �Ɩ����t��FROM-TO��
      AND     ( 
                ( iv_inv_cust_code IS NOT NULL AND xlvv.lookup_code = iv_inv_cust_code )
                OR
                ( iv_inv_cust_code IS NULL )
              )  --�p�����[�^�̐�����ڋq������ꍇ�̓N�C�b�N�R�[�h�Ɠ����l�̂�
/* 2009/04/15 Add Start */
      AND     (
                ( iv_sales_exp_ptn IS NOT NULL AND xlvv.attribute1 = iv_sales_exp_ptn )
                OR
                ( iv_sales_exp_ptn IS NULL )
              )  --�p�����[�^��EDI�̔����я����p�^�[��������ꍇ�͓���`�F�[���X�̂�(�쐬)
/* 2009/04/15 Add End   */
      GROUP BY
              xlvv.description
      ;
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
    OPEN chain_store_cur;
    FETCH chain_store_cur BULK COLLECT INTO gt_chain_store;
    gn_chain_store_cnt := chain_store_cur%ROWCOUNT;  --�Ώیڋq(�`�F�[���X)�����擾
    CLOSE chain_store_cur;
    --�擾�����̃`�F�b�N
    IF ( gn_chain_store_cnt = cn_0 ) THEN
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_bill_account  --�u������ڋq�R�[�h�v
                      );
      lv_tkn_name2 := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_table_tkn1  --�u�N�C�b�N�R�[�h�v
                      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_mst_chk_err --�}�X�^�`�F�b�N�G���[
                     ,iv_token_name1  => cv_tkn_column      --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_name1       --������ڋq�R�[�h
                     ,iv_token_name2  => cv_tkn_table       --�g�[�N���R�[�h�Q
                     ,iv_token_value2 => lv_tkn_name2       --�N�C�b�N�R�[�h�e�[�u��
                   );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_custom_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-3)
   ***********************************************************************************/
  PROCEDURE init(
/* 2010/03/16 Ver1.10 Add Start */
    iv_run_class        IN  VARCHAR2,     --   ���s�敪
/* 2010/03/16 Ver1.10 Add End   */
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    lv_param_msg      VARCHAR2(5000)  DEFAULT NULL;  --�p�����[�^�[�o�͗p
    lv_tkn_name1      VARCHAR2(50)    DEFAULT NULL;  --�g�[�N���擾�p1
    lv_tkn_name2      VARCHAR2(50)    DEFAULT NULL;  --�g�[�N���擾�p2
    ln_err_chk        NUMBER(1)       DEFAULT 0;     --�v���t�@�C���G���[�`�F�b�N�p
    lv_err_msg        VARCHAR2(5000)  DEFAULT NULL;  --�v���t�@�C���G���[�o�͗p(�擾�G���[���Ƃɏo�͂����)
    lv_l_meaning      xxcos_lookup_values_v.meaning%TYPE  DEFAULT NULL;  --�N�C�b�N�R�[�h�����擾�p
    lv_dummy          VARCHAR2(1)     DEFAULT NULL;  --���C�A�E�g��`��CSV�w�b�_�[�p(�t�@�C���^�C�v���Œ蒷�Ȃ̂Ŏg�p����Ȃ�)
--
    -- *** ���[�J���E�J�[�\�� ***
    --��݌ɕi�擾
    CURSOR no_inv_item_cur
    IS
      SELECT   xlvv.lookup_code lookup_code
/* 2010/03/16 Ver1.10 Mod Start */
--      FROM     fnd_lookup_values_vl  xlvv
      FROM     xxcos_lookup_values_v  xlvv
/* 2010/03/16 Ver1.10 Mod End   */
      WHERE    xlvv.lookup_type  = cv_lkt_no_inv_item
      AND      xlvv.attribute1   = cv_n  --�G���[�i�ڈȊO
/* 2010/03/16 Ver1.10 Add Start */
      AND      cd_process_date   BETWEEN NVL( xlvv.start_date_active, gd_min_date )
                                 AND     NVL( xlvv.end_date_active,   gd_max_date )
                                         -- �Ɩ����t��FROM-TO��
/* 2010/03/16 Ver1.10 Add End   */
      ;
--
    -- *** ���[�J���E���R�[�h ***
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
    --�V�X�e�����t�擾
    --==============================================================
    gv_f_o_date := TO_CHAR( cd_sysdate, cv_date_format );  --������
    gv_f_o_time := TO_CHAR( cd_sysdate, cv_time_format );  --��������
    --==============================================================
    --�v���t�@�C�����̎擾
    --==============================================================
    gv_if_header             := FND_PROFILE.VALUE( cv_prf_if_header );      --�w�b�_���R�[�h�敪
    gv_if_data               := FND_PROFILE.VALUE( cv_prf_if_data );        --�f�[�^���R�[�h�敪
    gv_if_footer             := FND_PROFILE.VALUE( cv_prf_if_footer );      --�t�b�^���R�[�h�敪
    gv_utl_m_line            := FND_PROFILE.VALUE( cv_prf_utl_m_line );     --EDI�ő僌�R�[�h��
    gv_outbound_d            := FND_PROFILE.VALUE( cv_prf_outbound_d );     --�f�B���N�g���p�X
    gv_dept_code             := FND_PROFILE.VALUE( cv_prf_dept_code );      --�Ɩ��Ǘ����R�[�h
    gv_prf_def_item_rate     := FND_PROFILE.VALUE( cv_prf_def_item_rate );  --EDI�f�t�H���g����
    gv_prf_organization_code := FND_PROFILE.VALUE( cv_prf_orga_code1  );    --�݌ɑg�D�R�[�h�̎擾
    gn_org_id                := FND_PROFILE.VALUE( cv_prf_org_id );         --�c�ƒP�ʂ̎擾
/* 2010/03/16 Ver1.10 Add Start */
    gd_min_date              := TO_DATE( FND_PROFILE.VALUE( cv_prf_min_date ), cv_date_format_sl ); --MAX���t
    gd_max_date              := TO_DATE( FND_PROFILE.VALUE( cv_prf_max_date ), cv_date_format_sl ); --MAX���t
    gn_edi_trg_hold_m        := ABS( TO_NUMBER( FND_PROFILE.VALUE( cv_prf_trg_hold_m ) ) ); --EDI�̔����ёΏەێ�����
--
    --���s�敪 �u�쐬�v�̏ꍇ
    IF ( iv_run_class = gv_run_class_cd_create ) THEN
/* 2010/03/16 Ver1.10 Add End   */
      --==================================
      --�v���t�@�C�����̃`�F�b�N
      --==================================
      --�w�b�_���R�[�h�敪�̃`�F�b�N
      IF ( gv_if_header IS NULL ) THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_if_h  --�uXXCCP:IF���R�[�h�敪_�w�b�_�v
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --�A�v���P�[�V����
                        ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                        ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --�f�[�^���R�[�h�敪�̃`�F�b�N
      IF ( gv_if_data IS NULL ) THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_if_d  --�uXXCCP:IF���R�[�h�敪_�f�[�^�v
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --�A�v���P�[�V����
                        ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                        ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --�t�b�^���R�[�h�敪�̃`�F�b�N
      IF ( gv_if_footer IS NULL ) THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_if_f  --�uXXCCP:IF���R�[�h�敪_�t�b�^�v
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --�A�v���P�[�V����
                        ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                        ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --EDI�ő僌�R�[�h���̃`�F�b�N
      IF ( gv_utl_m_line IS NULL ) THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_utl_m  --�uXXCOS:UTL_MAX�s�T�C�Y�v
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --�A�v���P�[�V����
                        ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                        ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --�f�B���N�g���p�X�̃`�F�b�N
      IF ( gv_outbound_d IS NULL ) THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_out_d  --�uXXCOS:�󒍌n�A�E�g�o�E���h�p�f�B���N�g���p�X�v
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --�A�v���P�[�V����
                        ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                        ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --�Ɩ��Ǘ����R�[�h�̃`�F�b�N
      IF ( gv_dept_code IS NULL ) THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_dept_c  --�uXXCOS:�Ɩ��Ǘ����R�[�h�v
                        );
        --���b�Z�[�W�擾
        lv_err_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application  --�A�v���P�[�V����
                    ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                    ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                   );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      -- �݌ɑg�D�R�[�h�̃`�F�b�N
      IF ( gv_prf_organization_code IS NULL ) THEN
        -- �݌ɑg�D�R�[�h
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application => cv_application
                          ,iv_name        => cv_msg_orga_code  --�uXXCOI:�݌ɑg�D�R�[�h�v
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_application  --�A�v���P�[�V����
                       ,iv_name         =>  cv_msg_prf_err  --�v���t�@�C���擾�G���[
                       ,iv_token_name1  =>  cv_tkn_prf      --�g�[�N���R�[�h�P
                       ,iv_token_value1 =>  lv_tkn_name1    --�v���t�@�C����
                     );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --EDI�f�t�H���g�����̃`�F�b�N
      IF ( gv_prf_def_item_rate IS NULL ) THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_prf_edi_r  --�uXXCOS:EDI�f�t�H���g�����v
                        );
        --���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application  --�A�v���P�[�V����
                        ,iv_name         => cv_msg_prf_err  --�v���t�@�C���擾�G���[
                        ,iv_token_name1  => cv_tkn_prf      --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1    --�v���t�@�C����
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --�c�ƒP�ʂ̃`�F�b�N
      IF  ( gn_org_id IS NULL )   THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application
                          ,iv_name         =>  cv_msg_org_id
                        );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                        ,iv_name          =>  cv_msg_prf_err
                        ,iv_token_name1   =>  cv_tkn_profile
                        ,iv_token_value1  =>  lv_tkn_name1
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
      -- MIN���t
      IF ( gd_min_date IS NULL ) THEN
        -- �g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application 
                           ,iv_name         => cv_msg_prf_min_d
                         );
        -- ���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_prf_err
                        ,iv_token_name1  => cv_tkn_profile
                        ,iv_token_value1 => lv_tkn_name1
                      );
        -- ���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- �G���[�L��
      END IF;
      -- MAX���t
      IF ( gd_max_date IS NULL ) THEN
        -- �g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_prf_max_d
                         );
        -- ���b�Z�[�W�擾
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_prf_err
                        ,iv_token_name1  => cv_tkn_profile
                        ,iv_token_value1 => lv_tkn_name1
                      );
        -- ���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  -- �G���[�L��
      END IF;
/* 2010/03/16 Ver1.10 Add End   */
      --==================================
      -- �f�[�^����(�}�X�^���擾)
      --==================================
      BEGIN
        SELECT  xlvv.meaning     meaning     --�f�[�^��
               ,xlvv.attribute1  attribute1  --IF���Ɩ��n��R�[�h
        INTO    gt_data_type_code
               ,gt_from_series
        FROM    xxcos_lookup_values_v xlvv
        WHERE   xlvv.lookup_type  = cv_lkt_data_type_code  --�f�[�^��
        AND     xlvv.lookup_code  = cv_lkc_data_type_code  --�u180�v
        AND     (
                  ( xlvv.start_date_active IS NULL )
                  OR
                  ( xlvv.start_date_active <= cd_process_date )
                )
        AND     (
                  ( xlvv.end_date_active   IS NULL )
                  OR
                  ( xlvv.end_date_active >= cd_process_date )
                )  -- �Ɩ����t��FROM-TO��
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_name1 := xxccp_common_pkg.get_msg(
                             iv_application =>  cv_application
                            ,iv_name        =>  cv_msg_data_type_c  --�u�f�[�^��R�[�h�v
                          );
          lv_tkn_name2 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_table_tkn1   --�u�N�C�b�N�R�[�h�v
                          );
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     --�A�v���P�[�V����
                          ,iv_name         => cv_msg_mst_chk_err --�}�X�^�`�F�b�N�G���[
                          ,iv_token_name1  => cv_tkn_column      --�g�[�N���R�[�h�P
                          ,iv_token_value1 => lv_tkn_name1       --�f�[�^��R�[�h
                          ,iv_token_name2  => cv_tkn_table       --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => lv_tkn_name2       --�N�C�b�N�R�[�h�e�[�u��
                        );
          --���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --�G���[�L��
      END;
      --==================================
      -- EDI�}�̋敪
      --==================================
      BEGIN
        --���b�Z�[�W�����e���擾
        lv_l_meaning := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_edi_m_class_c  --�N�C�b�N�R�[�h�擾����(EDI�}�̋敪)
                        );
        --�N�C�b�N�R�[�h�擾
        SELECT xlvv.lookup_code lookup_code
        INTO   gt_edi_media_class
        FROM   xxcos_lookup_values_v xlvv
        WHERE  xlvv.lookup_type   = cv_lkt_edi_m_class  --EDI�}�̋敪
        AND    xlvv.meaning       = lv_l_meaning        --�uEDI�v
        AND    (
                 ( xlvv.start_date_active IS NULL )
                 OR
                 ( xlvv.start_date_active <= cd_process_date )
               )
        AND    (
                 ( xlvv.end_date_active IS NULL )
                 OR
                 ( xlvv.end_date_active >= cd_process_date )
               )  -- �Ɩ����t��FROM-TO��
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_name1 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_edi_m_class_n  --�uEDI�}�̋敪�v
                          );
          lv_tkn_name2 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_table_tkn1     --�u�N�C�b�N�R�[�h�v
                          );
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     --�A�v���P�[�V����
                          ,iv_name         => cv_msg_mst_chk_err --�}�X�^�`�F�b�N�G���[
                          ,iv_token_name1  => cv_tkn_column      --�g�[�N���R�[�h�P
                          ,iv_token_value1 => lv_tkn_name1       --�f�[�^��R�[�h
                          ,iv_token_name2  => cv_tkn_table       --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => lv_tkn_name2       --�N�C�b�N�R�[�h�e�[�u��
                        );
          --���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --�G���[�L��
      END;
      --==================================
      -- ����敪�i���^���T�j�擾
      --==================================
      BEGIN
        --���b�Z�[�W�����e���擾
        lv_l_meaning := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_sales_class_c  --�N�C�b�N�R�[�h�擾����(����敪)
                        );
        --�N�C�b�N�R�[�h�擾
        SELECT xlvv.lookup_code lookup_code
        INTO   gt_edi_seales_class
/* 2010/03/16 Ver1.10 Mod Start */
--      FROM   fnd_lookup_values_vl xlvv
        FROM   xxcos_lookup_values_v xlvv
/* 2010/03/16 Ver1.10 Mod End   */
        WHERE  xlvv.lookup_type   = cv_lkt_edi_sale_class  --����敪
        AND    xlvv.meaning       = lv_l_meaning           --�u���^�v
/* 2010/03/16 Ver1.10 Add Start */
        AND     (
                  ( xlvv.start_date_active IS NULL )
                  OR
                  ( xlvv.start_date_active <= cd_process_date )
                )
        AND     (
                  ( xlvv.end_date_active   IS NULL )
                  OR
                  ( xlvv.end_date_active >= cd_process_date )
                )  -- �Ɩ����t��FROM-TO��
/* 2010/03/16 Ver1.10 Add End   */
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_tkn_name1 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_sales_class  --�u����敪�v
                          );
          lv_tkn_name2 := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => cv_msg_table_tkn1   --�u�N�C�b�N�R�[�h�v
                          );
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application      --�A�v���P�[�V����
                          ,iv_name         => cv_msg_mst_chk_err  --�}�X�^�`�F�b�N�G���[
                          ,iv_token_name1  => cv_tkn_column       --�g�[�N���R�[�h�P
                          ,iv_token_value1 => lv_tkn_name1        --�N�C�b�N�R�[�h
                          ,iv_token_name2  => cv_tkn_table        --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => lv_tkn_name2        --����敪
                        );
          --���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --�G���[�L��
      END;
      --==================================
      -- ��݌ɕi�擾
      --==================================
      OPEN no_inv_item_cur;
      FETCH no_inv_item_cur BULK COLLECT INTO gt_no_inv_item;
      gn_no_inv_item_cnt := no_inv_item_cur%ROWCOUNT;
      CLOSE no_inv_item_cur;
      --==================================
      --���_���̎擾
      --==================================
      BEGIN
        SELECT  hp.party_name  sales_base_name --���_��
        INTO    gt_sales_base_name
        FROM    hz_cust_accounts  hca  --���_(�ڋq)
               ,hz_parties        hp   --���_(�p�[�e�B)
        WHERE   hca.party_id             = hp.party_id   --����(���_(�ڋq) = ���_(�p�[�e�B))
        AND     hca.account_number       = gv_dept_code  --�Ɩ��Ǘ����R�[�h
        AND     hca.customer_class_code  = cv_1          --�ڋq�敪=1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --���b�Z�[�W�ҏW
          lv_err_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        --�A�v���P�[�V����
                          ,iv_name         => cv_msg_base_code_err --���_���擾�G���[
                          ,iv_token_name1  => cv_base_code1        --�g�[�N���R�[�h�P
                          ,iv_token_value1 => gv_dept_code         --�Ɩ��Ǘ����R�[�h
                        );
          --���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_err_msg
          );
          ln_err_chk := cn_1;  --�G���[�L��
      END;
      --==================================
      -- �݌ɑg�D�h�c�̎擾
      --==================================
      --�擾
      gv_prf_organization_id := xxcoi_common_pkg.get_organization_id( gv_prf_organization_code );
      --�擾�`�F�b�N
      IF ( gv_prf_organization_id  IS NULL )   THEN
        lv_err_msg :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_application            --�A�v���P�[�V����
                         ,iv_name         =>  gv_msg_orga_id_err        --�݌ɑg�DID�擾�G���[
                         ,iv_token_name1  =>  cv_tkn_org_code           --�g�[�N���R�[�h�P
                         ,iv_token_value1 =>  gv_prf_organization_code  --�݌ɑg�D�R�[�h
                       );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
      --==============================================================
      --�t�@�C�����C�A�E�g���̎擾
      --==============================================================
      xxcos_common2_pkg.get_layout_info(
         iv_file_type        => cv_0                --�t�@�C���`��(�Œ蒷)
        ,iv_layout_class     => cv_0                --���敪(�󒍌n)
        ,ov_data_type_table  => gt_data_type_table  --�f�[�^�^�\
        ,ov_csv_header       => lv_dummy            --CSV�w�b�_
        ,ov_errbuf           => lv_errbuf           --�G���[���b�Z�[�W
        ,ov_retcode          => lv_retcode          --���^�[���R�[�h
        ,ov_errmsg           => lv_errmsg           --���[�U�[�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application
                          ,iv_name         =>  cv_msg_layout    --�u���C�A�E�g��`���v
                        );
          --���b�Z�[�W�ҏW
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application       --�A�v���P�[�V����
                        ,iv_name         => cv_msg_file_inf_err  --���C�A�E�g��`���G���[
                        ,iv_token_name1  => cv_tkn_file_l        --�g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1         --���C�A�E�g��`���
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    ELSIF ( iv_run_class = gv_run_class_cd_update ) THEN
      --EDI�̔����ѕێ������̃`�F�b�N
      IF  ( gn_edi_trg_hold_m IS NULL )   THEN
        --�g�[�N���擾
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_application
                          ,iv_name         =>  cv_msg_prf_hold_m
                        );
        lv_err_msg := xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                        ,iv_name          =>  cv_msg_prf_err
                        ,iv_token_name1   =>  cv_tkn_profile
                        ,iv_token_value1  =>  lv_tkn_name1
                      );
        --���b�Z�[�W�ɏo��
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        ln_err_chk := cn_1;  --�G���[�L��
      END IF;
    END IF;
/* 2010/03/16 Ver1.10 Add End   */
    -- �G���[����
    IF ( ln_err_chk = cn_1 ) THEN
      RAISE global_data_check_expt;
    END IF;
--
  EXCEPTION
    -- *** �`�F�b�N�G���[ ****
    WHEN global_data_check_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
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
      IF ( no_inv_item_cur%ISOPEN ) THEN
         CLOSE no_inv_item_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_header
   * Description      : �t�@�C����������(A-4)
   ***********************************************************************************/
  PROCEDURE output_header(
    iv_chain_store_code  IN  fnd_lookup_values.description%TYPE,  --�����Ώیڋq�̃`�F�[���X�R�[�h
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_header'; -- �v���O������
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
    lv_file_name      fnd_lookup_values.meaning%TYPE;     --�t�@�C����
    lv_parallel_num   fnd_lookup_values.attribute1%TYPE;  --���񏈗��ԍ�
    lv_message        VARCHAR2(5000);                     --�t�@�C�������b�Z�[�W�p
/* 2009/04/28 Ver1.3 Mod Start */
--    lv_header_output  VARCHAR2(1000) DEFAULT NULL;        --IF�w�b�_�[�o�͗p
    lv_header_output  VARCHAR2(5000) DEFAULT NULL;        --IF�w�b�_�[�o�͗p
/* 2009/04/28 Ver1.3 Mod End   */
    lv_tkn_name1      VARCHAR2(50);                       --�g�[�N���擾�p�P
    lv_tkn_name2      VARCHAR2(50);                       --�g�[�N���擾�p�Q
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
    --==============================================================
    -- �t�@�C�����擾
    --==============================================================
    BEGIN
      --�N�C�b�N�R�[�h�擾
      SELECT  xlvv.meaning     meaning     --EDI�̔����уt�@�C����
             ,xlvv.attribute1  attribute1  --���񏈗��ԍ�
      INTO    lv_file_name
             ,lv_parallel_num
      FROM    xxcos_lookup_values_v xlvv
      WHERE   xlvv.lookup_type   = cv_lkt_edi_filename  --EDI�̔����уt�@�C����
      AND     xlvv.lookup_code   = iv_chain_store_code  --�`�F�[���X�R�[�h
      AND     (
                ( xlvv.start_date_active IS NULL )
                OR
                ( xlvv.start_date_active <= cd_process_date )
              )
      AND     (
                ( xlvv.end_date_active IS NULL )
                OR
                ( xlvv.end_date_active >= cd_process_date )
              )  -- �Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_in_file_name  --�u�t�@�C�����v
                        );
        lv_tkn_name2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application
                          ,iv_name         => cv_msg_table_tkn1    --�u�N�C�b�N�R�[�h�v
                        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      --�A�v���P�[�V����
                       ,iv_name         => cv_msg_mst_chk_err  --�}�X�^�`�F�b�N�G���[
                       ,iv_token_name1  => cv_tkn_column       --�g�[�N���R�[�h�P
                       ,iv_token_value1 => lv_tkn_name1        --�N�C�b�N�R�[�h
                       ,iv_token_name2  => cv_tkn_table          --�g�[�N���R�[�h�Q
                       ,iv_token_value2 => lv_tkn_name2        --�t�@�C����
                     );
        RAISE global_api_expt;
    END;
--
--****************�@2009/07/07   N.Maeda  Ver1.5   ADD   START  *********************************************--
   gt_parallel_num := lv_parallel_num;
--****************�@2009/07/07   N.Maeda  Ver1.5   ADD    END   *********************************************--
--
    --==============================================================
    -- �t�@�C�����o��
    --==============================================================
    lv_message := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application    --�A�v���P�[�V����
                    ,iv_name         => cv_msg_file_name  --�t�@�C�����o��
                    ,iv_token_name1  => cv_tkn_file_n     --�g�[�N���R�[�h�P
                    ,iv_token_value1 => lv_file_name      --�t�@�C����
                  );
    --�t�@�C���������b�Z�[�W�ɏo��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_message
    );
    --�󔒏o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
    --==============================================================
    --EDI�`�F�[���X���̎擾
    --==============================================================
    BEGIN
      SELECT  hp.party_name                  edi_chain_name      --EDI�`�F�[���X��
             ,hp.organization_name_phonetic  edi_chain_phonetic  --EDI�`�F�[���X���J�i
      INTO    gt_edi_chain_name
             ,gt_edi_chain_name_phonetic
      FROM    hz_cust_accounts     hca  -- �ڋq�}�X�^
             ,xxcmm_cust_accounts  xca  -- �ڋq�A�h�I���}�X�^
             ,hz_parties           hp   -- �p�[�e�B�}�X�^
      WHERE   hca.cust_account_id       =  xca.customer_id      -- ����(�ڋq = �ڋq�A�h�I��)
      AND     hca.party_id              =  hp.party_id          -- ����(�ڋq = �p�[�e�B)
      AND     xca.edi_chain_code        =  iv_chain_store_code  -- (�`�F�[���X)
      AND     hca.customer_class_code   =  cv_cust_code_chain   -- �ڋq�敪(�`�F�[���X)
      AND     hca.status                =  cv_status_a          --�X�e�[�^�X(�L��)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application        --�A�v���P�[�V����
                       ,iv_name         => cv_msg_edi_c_inf_err  --EDI�`�F�[���X���擾�G���[
                       ,iv_token_name1  => cv_tkn_chain_s        --�g�[�N���R�[�h�P
                       ,iv_token_value1 => iv_chain_store_code   --EDI�`�F�[���X�R�[�h
                     );
        RAISE global_api_expt;
    END;
    --==============================================================
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                        location      =>  gv_outbound_d  --�A�E�g�o�E���h�p�f�B���N�g���p�X
                       ,filename      =>  lv_file_name   --�t�@�C����
                       ,open_mode     =>  cv_w           --�I�[�v�����[�h
                       ,max_linesize  =>  gv_utl_m_line  --MAX�T�C�Y
                     );
    EXCEPTION
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application        --�A�v���P�[�V����
                       ,iv_name         => cv_msg_file_o_err     --�t�@�C���I�[�v���G���[
                       ,iv_token_name1  => cv_tkn_file_n         --�g�[�N���R�[�h�P
                       ,iv_token_value1 => lv_file_name          --�̔����уt�@�C��
                     );
        lv_errbuf  := SQLERRM;
        RAISE global_api_expt;
    END;
    --==============================================================
    --���ʊ֐��Ăяo��
    --==============================================================
    --EDI�w�b�_�E�t�b�^�t�^
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gv_if_header         --�t�^�敪
     ,iv_from_series     =>  gt_from_series       --IF���Ɩ��n��R�[�h
     ,iv_base_code       =>  gv_dept_code         --���_�R�[�h(�Ɩ��������R�[�h)
     ,iv_base_name       =>  gt_sales_base_name   --���_����
     ,iv_chain_code      =>  iv_chain_store_code  --�`�F�[���X�R�[�h
     ,iv_chain_name      =>  gt_edi_chain_name    --�`�F�[���X����
     ,iv_data_kind       =>  gt_data_type_code    --�f�[�^��R�[�h
     ,iv_row_number      =>  lv_parallel_num      --���񏈗��ԍ�
     ,in_num_of_records  =>  NULL                 --���R�[�h����
     ,ov_retcode         =>  lv_retcode
     ,ov_output          =>  lv_header_output
     ,ov_errbuf          =>  lv_errbuf
     ,ov_errmsg          =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --�A�v���P�[�V����
                     ,iv_name         => cv_msg_proc_err  --���ʊ֐��G���[
                     ,iv_token_name1  => cv_tkn_err_m     --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_errmsg        --���ʊ֐��̃G���[���b�Z�[�W
                   );
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --�t�@�C���o��
    --==============================================================
    --�w�b�_�o��
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --�t�@�C���n���h��
     ,buffer => lv_header_output  --�o�͕���(�w�b�_)
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END output_header;
--
  /**********************************************************************************
   * Procedure Name   : get_sale_data
   * Description      : �̔����я�񒊏o(A-5)
   ***********************************************************************************/
  PROCEDURE get_sale_data(
    iv_chain_store_code  IN  fnd_lookup_values.description%TYPE,  --�����Ώیڋq�̃`�F�[���X�R�[�h
/* 2009/04/15 Del Start */
--    iv_inv_cust_code     IN  VARCHAR2,                            --������ڋq�R�[�h
/* 2009/04/15 Del End   */
    ov_errbuf            OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sale_data'; -- �v���O������
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
    lv_tkn_name  VARCHAR2(50) DEFAULT NULL;  --�g�[�N���擾�p�P
/* 2009/07/29 Ver1.5 Add Start */
    lt_indv_shipping_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --�o�א���(�o��)
    lt_case_shipping_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --�o�א���(�P�[�X)
    lt_ball_shipping_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --�o�א���(�{�[��)
    lt_indv_stockout_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(�o��)
    lt_case_stockout_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(�P�[�X)
    lt_ball_stockout_qty  xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(�{�[��)
    lt_sum_stockout_qty   xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(���v�A�o��)
    lv_breck_key          VARCHAR2(21); --�`�[�v�u���[�N�L�[(�ڋq�y�[�i��z+�[�i�`�[�ԍ�)
    ln_no_inv_item_flag   NUMBER(1);    --��݌ɕi�t���O
/* 2009/07/29 Ver1.5 Add End   */
--
    -- *** ���[�J���E�J�[�\�� ***
    --==============================================================
    --�̔����т̑Ώۃf�[�^�擾�J�[�\��
    --==============================================================
    CURSOR sale_data_cur
    IS
/* 2009/11/24 Ver1.8 Mod Start */
      SELECT  /*+ 
                 LEADING(xlvv xcchv xseh xsel iimb)
                 INDEX(xseh XXCOS_SALES_EXP_HEADERS_N03)
                 USE_NL(xhpc.msib xhpc.mic xhpc.mp xhpc.mcsb xhpc.mcst xhpc.mcb xhpc.mct)
                 USE_NL(xseh xsel1)
                 USE_NL(xseh xsel)
                 USE_NL(xsel iimb msib ximb xhpc)
                 USE_NL(xseh hcam hcan)
                 USE_NL(xseh xlvv xcchv)
              */
              xseh.sales_exp_header_id                header_id                    --�̔����уw�b�_ID
--      SELECT  xseh.sales_exp_header_id                header_id                    --�̔����уw�b�_ID
/* 2009/11/24 Ver1.8 Mod End */
             ,xsel.sales_exp_line_id                  line_id                      --�̔����і���ID
             ,xseh.sales_base_code                    sales_base_code              --���㋒�_�R�[�h
             ,hcam.sales_base_name                    sales_base_name              --���㋒�_��
             ,hcam.sales_base_phonetic                sales_base_phonetic          --���㋒�_���J�i
-- 2010/06/22 S.Arizumi Ver1.11 Mod Start
--/* 2009/11/27 Ver1.9 Add Start */
--             ,xseh.order_invoice_number               order_invoice_number         --�����`�[�ԍ�
--/* 2009/11/27 Ver1.9 Add End   */
             ,CASE WHEN     xlvv.attribute1   <>  cv_5                            --�����p�^�[���F�X�}�C�� �ȊO
                        AND xseh.create_class IN( cv_3                            --�쐬���敪  �FVD�[�i�f�[�^�쐬
                                                 ,cv_4                            --�쐬���敪  �F�o�׊m�F����(HHT�[�i�f�[�^)
                                                 ,cv_5                            --�쐬���敪  �F�ԕi���уf�[�^�쐬(HHT)
                                              )
                THEN NVL( xseh.order_invoice_number
                         ,xseh.invoice_classification_code || xseh.invoice_class
                     )
                ELSE xseh.order_invoice_number
              END                                     order_invoice_number         --�����`�[�ԍ�
-- 2010/06/22 S.Arizumi Ver1.11 Mod End
             ,xseh.ship_to_customer_code              ship_to_customer_code        --�ڋq�y�[�i��z
             ,xcchv.ship_account_name                 ship_account_name            --�[�i��ڋq��
             ,hcan.organization_name_phonetic         organization_name_phonetic   --�[�i��ڋq���J�i
             ,xseh.orig_delivery_date                 orig_delivery_date           --�I���W�i���[�i��
             ,xseh.invoice_class                      invoice_class                --�`�[�敪
             ,xseh.invoice_classification_code        invoice_classification_code  --�`�[���ރR�[�h
             ,xseh.dlv_invoice_number                 dlv_invoice_number           --�[�i�`�[�ԍ�
             ,hcan.address                            address                      --�͂���Z��(����)
             ,rtv.due_cutoff_day                      sales_exp_day                --�����J�n��
             ,xseh.orig_inspect_date                  orig_inspect_date            --�I���W�i��������
             ,xseh.dlv_invoice_class                  dlv_invoice_class            --�[�i�`�[�敪
/* 2009/11/05 Ver1.7 Add Start */
--             ,xcchv.bill_cred_rec_code2               bill_cred_rec_code2          --���|�R�[�h�Q�i���Ə��j
             ,( SELECT ship_hsua.attribute5  attribute5
                FROM   hz_cust_acct_sites    ship_hasa                             --�ڋq���ݒn(�o�א�)
                     , hz_cust_site_uses     ship_hsua                             --�ڋq�g�p�ړI
                WHERE  ship_hasa.cust_account_id   = xcchv.ship_account_id
                AND    ship_hsua.cust_acct_site_id = ship_hasa.cust_acct_site_id
                AND    ship_hsua.site_use_code     = cv_bill_to --'BILL_TO'
                AND    ship_hsua.primary_flag      = cv_y       --'Y'
/* 2010/03/16 Ver1.10 Add Start */
                AND    ship_hasa.org_id            = gn_org_id
                AND    ship_hasa.status            = cv_status_a  --'A'
                AND    ship_hsua.status            = cv_status_a  --'A'
/* 2010/03/16 Ver1.10 Add End   */
              )                                       bill_cred_rec_code2          --���|�R�[�h�Q�i���Ə��j
/* 2009/11/05 Ver1.7 Add End   */
             ,xsel.dlv_invoice_line_number            dlv_invoice_line_number      --�[�i���הԍ�
             ,xsel.item_code                          item_code                    --�i�ڃR�[�h
             ,iimb.attribute21                        jan_code                     --JAN�R�[�h
             ,iimb.attribute22                        itf_code                     --ITF�R�[�h
             ,xhpc.item_div_h_code                    item_div_code                --�{�Џ��i�敪
             ,ximb.item_name                          item_name                    --�i�ړE�v
             ,SUBSTRB( ximb.item_name_alt, cn_1, cn_15 )
                                                      item_phonetic1               --�i�ږ��J�i�P
             ,SUBSTRB( ximb.item_name_alt, cn_16, cn_15 )
                                                      item_phonetic2               --�i�ږ��J�i�Q
             ,iimb.attribute11                        case_inc_num                 --�P�[�X����
             ,xsib.bowl_inc_num                       bowl_inc_num                 --�{�[������
             ,xsel.standard_qty                       standard_qty                 --�����
             ,xsel.standard_unit_price                standard_unit_price          --��P��
             ,xsel.sale_amount                        sale_amount                  --������z
             ,DECODE(  xsel.sales_class
                      ,gt_edi_seales_class, xsel.sales_class
                      ,TO_CHAR(NULL) )                sales_class                  --����敪
             ,xsel1.sum_standard_qty                  sum_standard_qty             --����ʃT�}���[
             ,xsel1.sum_sale_amount                   sum_sale_amount              --������z�T�}���[
             ,xcchv.bill_cred_rec_code1               bill_cred_rec_code1          --���|�R�[�h�P�i�������j
             ,xcchv.bill_cred_rec_code3               bill_cred_rec_code3          --���|�R�[�h�R�i���̑��j
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
             ,hcan.edi_forward_number                 edi_forward_number           --EDI�[�i�`�[�ǔ�
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
-- 2009/06/25 M.Sano Ver.1.5 add Start
             ,xsel.standard_uom_code                  standard_uom_code            --�����
-- 2009/06/25 M.Sano Ver.1.5 add End
      FROM    xxcos_lookup_values_v     xlvv   --������ڋq�R�[�h(�ڋq�P��)
             ,xxcfr_cust_hierarchy_v    xcchv  --�ڋq�}�X�^�K�w�r���[
             ,ra_terms_vl               rtv    --�x������
             ,xxcos_sales_exp_headers   xseh   --�̔����уw�b�_
/* 2009/11/24 Ver1.8 Mod Start */
             ,( SELECT  /*+ 
                          index(hca HZ_CUST_ACCOUNTS_U2)
                          USE_NL(hca hp xca_2 hcasa hcsua hps hl)
                        */
                        hca.account_number             account_number              --�[�i�ڋq�R�[�h
--             ,( SELECT  hca.account_number             account_number              --�[�i�ڋq�R�[�h
/* 2009/11/24 Ver1.8 Mod End */
                       ,hp.organization_name_phonetic  organization_name_phonetic  --�[�i��ڋq���J�i
                       ,hl.state || hl.city || hl.address1 || hl.address2
                                                       address                     --�s���{��+�s��+�Z��1+�Z��2
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
                       ,xca_2.edi_forward_number       edi_forward_number
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
                FROM    hz_cust_accounts       hca
                       ,hz_parties             hp
                       ,hz_cust_acct_sites_all hcasa
                       ,hz_cust_site_uses_all  hcsua
                       ,hz_party_sites         hps
                       ,hz_locations           hl
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
                       ,xxcmm_cust_accounts    xca_2
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
                WHERE   hca.party_id            =  hp.party_id
                AND     hca.cust_account_id     =  hcasa.cust_account_id
                AND     hcasa.org_id            =  gn_org_id
                AND     hcasa.cust_acct_site_id =  hcsua.cust_acct_site_id
                AND     hcasa.org_id            =  hcsua.org_id
                AND     hcsua.site_use_code     =  cv_cust_site_use_code
                AND     hcasa.party_site_id     =  hps.party_site_id
                AND     hps.location_id         =  hl.location_id
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
                AND     xca_2.customer_id         =  hca.cust_account_id
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
/* 2010/03/16 Ver1.10 Add Start */
                AND     hcsua.primary_flag      = cv_y         --'Y'
                AND     hcsua.status            = cv_status_a  --'A'
                AND     hcasa.status            = cv_status_a  --'A'
/* 2010/03/16 Ver1.10 Add End   */
              )                         hcan   --�[�i�ڋq
/* 2009/11/24 Ver1.8 Mod Start */
             ,( SELECT  /*+ 
                          index(hca HZ_CUST_ACCOUNTS_U2)
                          USE_NL(hca hp xca1)
                        */
                        hca.account_number             sales_base_code         --���㋒�_�R�[�h
--             ,( SELECT  hca.account_number             sales_base_code         --���㋒�_�R�[�h
/* 2009/11/24 Ver1.8 Mod End */
                       ,hp.party_name                  sales_base_name         --���㋒�_��
                       ,hp.organization_name_phonetic  sales_base_phonetic     --���㋒�_���J�i
                FROM    hz_cust_accounts        hca
                       ,hz_parties              hp
                       ,xxcmm_cust_accounts     xca1
                WHERE   hca.party_id            =  hp.party_id          --����(���_(�ڋq) = ���_(�p�[�e�B))
                AND     hca.customer_class_code =  cv_1                 --���㋒�_(�ڋq) �ڋq�敪=1
                AND     hca.cust_account_id     =  xca1.customer_id     --����(�ڋq = �ڋq�ǉ�)
              )                          hcam  --���㋒�_
/* 2010/03/16 Ver1.10 Mod Start */
/* 2009/11/24 Ver1.8 Mod Start */
--             ,( SELECT  /*+ 
--                          INDEX(xseh XXCOS_SALES_EXP_HEADERS_N03)
--                          USE_NL(xseh xsel xlvv)
--                        */
             ,( SELECT  /*+
                          LEADING(xlvv2 xcchv xseh xsel xlvv)
                          INDEX(xseh XXCOS_SALES_EXP_HEADERS_N03)
                          USE_NL(xlvv2 xcchv xseh xsel xlvv)
                        */
/* 2010/03/16 Ver1.10 Mod End   */
                        xseh.ship_to_customer_code   ship_to_customer_code
--             ,( SELECT  xseh.ship_to_customer_code   ship_to_customer_code
/* 2009/11/24 Ver1.8 Mod End */
                       ,xseh.dlv_invoice_number      dlv_invoice_number
                       ,SUM( DECODE(  xlvv.lookup_code
                                     ,'', xsel.standard_qty
                                     ,cn_0 )
                        )                            sum_standard_qty     --����ʃT�}���[(��݌ɕi��0�Ƃ���)
                       ,SUM( xsel.sale_amount )      sum_sale_amount      --������z�T�}���[
                FROM    xxcos_sales_exp_headers  xseh
                       ,xxcos_sales_exp_lines    xsel
/* 2010/03/16 Ver1.10 Mod Start */
--                       ,fnd_lookup_values_vl     xlvv
                       ,xxcos_lookup_values_v    xlvv
                       ,xxcos_lookup_values_v    xlvv2   --������ڋq�R�[�h(�ڋq�P��)
                       ,xxcfr_cust_hierarchy_v   xcchv   --�ڋq�}�X�^�K�w�r���[
/* 2010/03/16 Ver1.10 Mod End   */
                WHERE   xseh.sales_exp_header_id = xsel.sales_exp_header_id
                AND     xseh.edi_interface_flag  = cv_n                         --�����M�̂�
                AND     xlvv.lookup_type(+)      = cv_lkt_no_inv_item
                AND     xlvv.lookup_code(+)      = xsel.item_code
/* 2010/03/16 Ver1.10 Add Start */
                AND     cd_process_date BETWEEN NVL( xlvv.start_date_active(+), gd_min_date )
                                        AND     NVL( xlvv.end_date_active(+),   gd_max_date )
                AND     TRUNC( xseh.orig_delivery_date ) BETWEEN TO_DATE( xlvv2.attribute2, cv_date_format_sl )
                                                         AND     TO_DATE( xlvv2.attribute3, cv_date_format_sl )
                                                                                --�I���W�i���[�i�����f�[�^�擾���t�͈͓�
                AND     xcchv.ship_account_number = xseh.ship_to_customer_code
                AND     xlvv2.lookup_code         = xcchv.bill_account_number
                AND     TRUNC( xseh.orig_delivery_date ) BETWEEN NVL( xlvv2.start_date_active, gd_min_date )
                                                         AND     NVL( xlvv2.end_date_active,   gd_max_date )
                AND     xlvv2.lookup_type         = cv_lkt_sales_edi_cust       --�N�C�b�N�R�[�h�̐�����ڋq�R�[�h
                AND     xlvv2.description         = iv_chain_store_code         --�p�����[�^�̃`�F�[���X�R�[�h
/* 2010/03/16 Ver1.10 Add End   */
                GROUP BY
                        xseh.ship_to_customer_code
                       ,xseh.dlv_invoice_number
              )                         xsel1  --�̔����і���(�T�}��)
             ,xxcos_sales_exp_lines     xsel   --�̔����і���
             ,ic_item_mst_b             iimb   --OPM�i��
             ,xxcmn_item_mst_b          ximb   --OPM�i�ڃA�h�I��
             ,mtl_system_items_b        msib   --Disc�i��
             ,xxcmm_system_items_b      xsib   --Disc�i�ڃA�h�I��
             ,xxcos_head_prod_class_v   xhpc   --�{�Џ��i�敪�r���[
/* 2009/11/24 Ver1.8 Mod Start */
      WHERE   msib.inventory_item_id     = xhpc.inventory_item_id   --����(Disc�i��=�{�Џ��i�敪)
--      WHERE   msib.inventory_item_id     = xhpc.inventory_item_id(+)   --����(Disc�i��=�{�Џ��i�敪)
/* 2009/11/24 Ver1.8 Mod End */
      AND     msib.organization_id       = gv_prf_organization_id      --�݌ɑg�DID
      AND     msib.segment1              = xsib.item_code              --����(Disc�i��=Disc�i��A)
      AND     iimb.item_no               = msib.segment1               --����(OPM�i��=Disc�i��)
      AND     ( xseh.orig_delivery_date BETWEEN ximb.start_date_active AND  ximb.end_date_active )  --OPM�i��A�̓K�p��FROM-TO
      AND     iimb.item_id               = ximb.item_id                --����(OPM�i��=OPM�i��A)
      AND     xsel.item_code             = iimb.item_no                --����(����=OPM�i��)
      AND     xseh.sales_exp_header_id   = xsel.sales_exp_header_id    --����(�w�b�_=����)
      AND     xseh.ship_to_customer_code = xsel1.ship_to_customer_code --����(�w�b�_=���׃T�}���[1)
      AND     xseh.dlv_invoice_number    = xsel1.dlv_invoice_number    --����(�w�b�_=���׃T�}���[2)
      AND     xseh.sales_base_code       = hcam.sales_base_code        --����(�w�b�_=���㋒�_)
      AND     xseh.ship_to_customer_code = hcan.account_number         --����(�w�b�_=�[�i�ڋq)
/* 2010/03/16 Ver1.10 Add Start */
      AND     TRUNC( xseh.orig_delivery_date )  BETWEEN TO_DATE( xlvv.attribute2, cv_date_format_sl )
                                                AND     TO_DATE( xlvv.attribute3, cv_date_format_sl )
                                                                       --�I���W�i���[�i�����f�[�^�擾���t�͈͓�
      AND     TRUNC( xseh.orig_delivery_date )  BETWEEN NVL( xlvv.start_date_active, gd_min_date )
                                                AND     NVL( xlvv.end_date_active,   gd_max_date )
/* 2010/03/16 Ver1.10 Add End   */
      AND     xseh.edi_interface_flag    = cv_n                        --EDI���M�σt���O(�����M)
      AND     xcchv.ship_account_number  = xseh.ship_to_customer_code  --����(�ڋq�K�w=�w�b�_)
      AND     xcchv.bill_payment_term_id = rtv.term_id                 --����(�ڋq�K�w=�x������)
      AND     xlvv.lookup_code           = xcchv.bill_account_number   --����(���b�N�A�b�v=�ڋq�K�w)
      AND     xlvv.lookup_type           = cv_lkt_sales_edi_cust       --�N�C�b�N�R�[�h�̐�����ڋq�R�[�h
      AND     xlvv.description           = iv_chain_store_code         --�p�����[�^�̃`�F�[���X�R�[�h
/* 2009/04/15 Del Start */
--      AND     (
--                ( iv_inv_cust_code IS NULL )
--                OR
--                ( iv_inv_cust_code IS NOT NULL AND iv_inv_cust_code = xlvv.lookup_code )
--              )                                                        --�p�����[�^�̐����ڋq������ꍇ�͎w�肳�ꂽ�����ڋq�̂�
/* 2009/04/15 Del End   */
      ORDER BY
              xseh.ship_to_customer_code
             ,xseh.dlv_invoice_number
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD START ******************************************
--             ,xsel.dlv_invoice_line_number
             ,xseh.sales_exp_header_id
             ,xsel.sales_exp_line_id
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD END   ******************************************
      FOR UPDATE OF
-- ************ 2009/09/03 1.6 N.Maeda MOD START ********* --
              xseh.sales_exp_header_id NOWAIT
--              xseh.sales_exp_header_id
--             ,xsel.sales_exp_line_id NOWAIT
-- ************ 2009/09/03 1.6 N.Maeda MOD  END  ********* --
      ;
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
    --==============================================================
    --�̔����т̑Ώۃf�[�^���擾
    --==============================================================
    --1�`�F�[���X�������ϐ��̏�����
    gn_data_cnt       := cn_0;                 --����������
    gt_edi_sales_data := gt_edi_sales_data_c;  --�e�[�u���^������
    BEGIN
      --���b�N�m�F�A�f�[�^�̎擾
      OPEN  sale_data_cur;
      FETCH sale_data_cur BULK COLLECT INTO gt_edi_sales_data;
      --�Ώی����擾
      gn_data_cnt := sale_data_cur%ROWCOUNT;
      CLOSE sale_data_cur;
--
    EXCEPTION
      -- *** ���b�N�G���[ ***
      WHEN lock_expt THEN
        --�J�[�\���N���[�Y
        IF ( sale_data_cur%ISOPEN ) THEN
          CLOSE sale_data_cur;
        END IF;
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --�A�v���P�[�V����
                         ,iv_name         => cv_msg_table_tkn2  --�̔����уw�b�_�e�[�u��
                       );
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     --�A�v���P�[�V����
                       ,iv_name         => cv_msg_lock_err    --���b�N�G���[
                       ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                       ,iv_token_value1 => lv_tkn_name        --�̔����уw�b�_�e�[�u��
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
      --���̑���O
      WHEN OTHERS THEN
        --�g�[�N���P�擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --�A�v���P�[�V����
                         ,iv_name         => cv_msg_table_tkn2  --�̔����уw�b�_�e�[�u��
                       );
        --���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application       --�A�v���P�[�V����
                       ,iv_name         => cv_msg_data_get_err  --�f�[�^���o�G���[
                       ,iv_token_name1  => cv_tkn_table_n       --�g�[�N���R�[�h�P
                       ,iv_token_value1 => lv_tkn_name          --�̔����уw�b�_�e�[�u��
                       ,iv_token_name2  => cv_tkn_key           --�g�[�N���R�[�h�Q
                       ,iv_token_value2 => iv_chain_store_code  --�`�F�[���X�R�[�h
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
/* 2009/07/29 Ver1.5 Add Start */
--
    --�`�[�v�̎擾
    <<sum_qty_loop>>
    FOR i IN 1.. gn_data_cnt LOOP
--
      --���[�v���ϐ��̏�����
      ln_no_inv_item_flag  := cn_0;
      lt_indv_shipping_qty := cn_0;
      lt_case_shipping_qty := cn_0;
      lt_ball_shipping_qty := cn_0;
--
      --��݌ɕi�����݂���ꍇ
      IF ( gn_no_inv_item_cnt <> cn_0 ) THEN
        --��݌ɕi�ڂ̃`�F�b�N
        <<no_item_check_loop>>
        FOR i2 IN 1.. gn_no_inv_item_cnt LOOP
          --���וi�ڂ���݌ɕi�ڂ̏ꍇ
          IF ( gt_no_inv_item(i2) = gt_edi_sales_data(i).item_code ) THEN
            ln_no_inv_item_flag := cn_1;  --�t���O�𗧂Ă�
            EXIT;
          END IF;
        END LOOP no_item_check_loop;
      END IF;
--
      --��݌ɕi�ڈȊO�̏ꍇ
      IF ( ln_no_inv_item_flag = cn_0 ) THEN
--
        -- �o�א��ʂ��擾����B
        xxcos_common2_pkg.convert_quantity(
          iv_uom_code           => gt_edi_sales_data(i).standard_uom_code  --(IN)��P��
         ,in_case_qty           => gt_edi_sales_data(i).case_inc_num       --(IN)�P�[�X����
         ,in_ball_qty           => gt_edi_sales_data(i).bowl_inc_num       --(IN)�{�[������
         ,in_sum_indv_order_qty => gt_edi_sales_data(i).standard_qty       --(IN)��������(���v�E�o��)
         ,in_sum_shipping_qty   => gt_edi_sales_data(i).standard_qty       --(IN)�o�א���(���v�E�o��)
         ,on_indv_shipping_qty  => lt_indv_shipping_qty                    --(OUT)�o�א���(�o��)
         ,on_case_shipping_qty  => lt_case_shipping_qty                    --(OUT)�o�א���(�P�[�X)
         ,on_ball_shipping_qty  => lt_ball_shipping_qty                    --(OUT)�o�א���(�{�[��)
         ,on_indv_stockout_qty  => lt_indv_stockout_qty                    --(OUT)���i����(�o��)
         ,on_case_stockout_qty  => lt_case_stockout_qty                    --(OUT)���i����(�P�[�X)
         ,on_ball_stockout_qty  => lt_ball_stockout_qty                    --(OUT)���i����(�{�[��)
         ,on_sum_stockout_qty   => lt_sum_stockout_qty                     --(OUT)���i����(�o������v)
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
--
        IF  ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
--
      ELSE
        --���ʂ�0�ɐݒ肷��
        lt_indv_shipping_qty := cn_0;
        lt_case_shipping_qty := cn_0;
        lt_ball_shipping_qty := cn_0;
      END IF;
--
      --���[�v����A�������̓u���C�N�̏ꍇ
      IF ( lv_breck_key IS NULL )
        OR ( lv_breck_key <> gt_edi_sales_data(i).ship_to_customer_code || gt_edi_sales_data(i).dlv_invoice_number )
      THEN
        --�u���[�N�L�[�ݒ�A������
        lv_breck_key := gt_edi_sales_data(i).ship_to_customer_code || gt_edi_sales_data(i).dlv_invoice_number;
        gt_sum_qty(lv_breck_key).invc_indv_qty_sum := lt_indv_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_case_qty_sum := lt_case_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_ball_qty_sum := lt_ball_shipping_qty;
      ELSE
        --���ׂ̐��ʂ����Z����
        gt_sum_qty(lv_breck_key).invc_indv_qty_sum := gt_sum_qty(lv_breck_key).invc_indv_qty_sum + lt_indv_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_case_qty_sum := gt_sum_qty(lv_breck_key).invc_case_qty_sum + lt_case_shipping_qty;
        gt_sum_qty(lv_breck_key).invc_ball_qty_sum := gt_sum_qty(lv_breck_key).invc_ball_qty_sum + lt_ball_shipping_qty;
      END IF;
--
    END LOOP sum_qty_loop;
/* 2009/07/29 Ver1.5 Add End   */
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_sale_data;
--
--
  /**********************************************************************************
   * Procedure Name   : edit_sale_data
   * Description      : �f�[�^�ҏW(A-6)
   ***********************************************************************************/
  PROCEDURE edit_sale_data(
    iv_chain_store_code IN  fnd_lookup_values.description%TYPE,  --�����Ώیڋq�̃`�F�[���X�R�[�h
    iv_process_pattern  IN  fnd_lookup_values.attribute1%TYPE,   --�����Ώۂ̏����p�^�[��
    ov_errbuf           OUT VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_sale_data'; -- �v���O������
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
    lv_split_bill_cred_1    VARCHAR2(4);                                       --���|�R�[�h�Q�i���Ə��j�����P
    lv_split_bill_cred_2    VARCHAR2(4);                                       --���|�R�[�h�Q�i���Ə��j�����Q
    lv_split_bill_cred_3    VARCHAR2(4);                                       --���|�R�[�h�Q�i���Ə��j�����R
    lv_whse_directly_class  VARCHAR2(2);                                       --�q���敪
    ld_last_day             DATE;                                              --�[�i���̌��̍ŏI��
    ln_due_date_dd_num      NUMBER;                                            --�����J�n��-1(��������)
    lv_billing_due_date     VARCHAR2(8);                                       --��������
    lv_address              VARCHAR2(255);                                     --�͂���Z��(����)
    lv_bill_cred_rec_code2  VARCHAR2(200);                                     --�`�F�[���X�ŗL�G���A(�w�b�_�[)
    lv_pb_nb_rate           VARCHAR2(10);                                      --����
    lv_data_record          VARCHAR2(32767);                                   --�ҏW��̃f�[�^�擾�p
    ln_no_inv_item_flag     VARCHAR2(1);                                       --��݌ɕi�i�ڃt���O
    lt_standard_qty         xxcos_sales_exp_lines.standard_qty%TYPE;           --�o�א���(�o��),(���v�A�o��)
    lt_standard_unit_price  xxcos_sales_exp_lines.standard_unit_price%TYPE;    --���P��(����)
    lt_header_break         xxcos_sales_exp_headers.sales_exp_header_id%TYPE;  --�̔����уw�b�_�u���[�N�p(A-9�̏����p)
    ln_seq                  NUMBER;                                            --�Y���p(A-9�̏����p)
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD START ******************************************
    ln_line_no              NUMBER(3);                                         --�s�m��
    lv_ship_to_customer_code xxcos_sales_exp_headers.ship_to_customer_code%TYPE; --�ڋq�y�[�i��z�u���C�N�����p
    lv_dlv_invoice_number   xxcos_sales_exp_headers.dlv_invoice_number%TYPE;   --�[�i�`�[�ԍ��u���C�N�����p
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD END   ******************************************
-- 2009/06/25 M.Sano Ver.1.5 add Start
    lt_indv_shipping_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --�o�א���(�o��)
    lt_case_shipping_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --�o�א���(�P�[�X)
    lt_ball_shipping_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --�o�א���(�{�[��)
    lt_indv_stockout_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(�o��)
    lt_case_stockout_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(�P�[�X)
    lt_ball_stockout_qty    xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(�{�[��)
    lt_sum_stockout_qty     xxcos_sales_exp_lines.standard_qty%TYPE;           --���i����(���v�A�o��)
-- 2009/06/25 M.Sano Ver.1.5 add End
/* 2009/07/29 Ver1.5 Add Start */
    lv_sum_qty_seq          VARCHAR2(21);                                      --�`�[�v�p�ϐ��̓Y��(�ڋq�y�[�i��z+�[�i�`�[�ԍ�)
/* 2009/07/29 Ver1.5 Add End   */
/* 2009/11/05 Ver1.7 Add Start */
    lv_invoice_class        xxcos_sales_exp_headers.invoice_class%TYPE;        --�`�[�敪
/* 2009/11/05 Ver1.7 Add End   */
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    l_data_tab  xxcos_common2_pkg.g_layout_ttype;    --�o�̓f�[�^���
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
    --���[�v�O�ϐ��̏�����
    ln_seq               := cn_0;
    gt_update_header_id  := gt_update_header_id_c;
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD START ******************************************
    --�s�m���̕ҏW�p�ϐ��̏�����
    lv_ship_to_customer_code := NULL;
    lv_dlv_invoice_number    := NULL;
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD END   ******************************************
    --A-5�Ŏ擾�����f�[�^�̕ҏW�A�y�сA�t�@�C���o��
    <<output_loop>>
    FOR i IN 1.. gn_data_cnt LOOP
      --���[�v���ϐ��̏�����
      ln_no_inv_item_flag := cn_0;
-- 2009/06/25 M.Sano Ver.1.5 add Start
      --�o�א���,���i���ʊi�[�ϐ��̏�����
      lt_indv_shipping_qty  := cn_0;
      lt_case_shipping_qty  := cn_0;
      lt_ball_shipping_qty  := cn_0;
      lt_indv_stockout_qty  := cn_0;
      lt_case_stockout_qty  := cn_0;
      lt_ball_stockout_qty  := cn_0;
      lt_sum_stockout_qty   := cn_0;
-- 2009/06/25 M.Sano Ver.1.5 add End
/* 2009/07/29 Ver1.5 Add Start */
      --�`�[�v�p�ϐ��̓Y����ҏW
      lv_sum_qty_seq := gt_edi_sales_data(i).ship_to_customer_code || gt_edi_sales_data(i).dlv_invoice_number;
/* 2009/07/29 Ver1.5 Add Start */
      --==============================================================
      -- �X�V����(A-9)�Ŏg�p����ID�̕ҏW
      --==============================================================
      IF (
           ( lt_header_break IS NULL )
           OR 
           ( lt_header_break <> gt_edi_sales_data(i).sales_exp_header_id )
         )
      THEN
        ln_seq                      := ln_seq + 1;
        lt_header_break             := gt_edi_sales_data(i).sales_exp_header_id; --�u���[�N�ϐ�
        gt_update_header_id(ln_seq) := lt_header_break;
      END IF;
      --==============================================================
      -- ���ڂ̕ҏW
      --==============================================================
      -----------------------------------------------------------
      --���P��(����)�A�o�א���(�o��)�A�o�א���(�o���A���v)�̕ҏW
      -----------------------------------------------------------
      IF ( gn_no_inv_item_cnt <> cn_0 ) THEN
        --��݌ɕi�ڂ̃`�F�b�N
        <<no_item_check_loop>>
        FOR i2 IN 1.. gn_no_inv_item_cnt LOOP
          --���וi�ڂ���݌ɕi�ڂ̏ꍇ
          IF ( gt_no_inv_item(i2) = gt_edi_sales_data(i).item_code ) THEN
            ln_no_inv_item_flag := cn_1;  --�t���O�𗧂Ă�
            EXIT;
          END IF;
        END LOOP no_item_check_loop;
      END IF;
      --��݌ɕi�ڈȊO�̏ꍇ
      IF ( ln_no_inv_item_flag = cn_0 ) THEN
        lt_standard_qty        := gt_edi_sales_data(i).standard_qty;        --����ʂ�ݒ�
        lt_standard_unit_price := gt_edi_sales_data(i).standard_unit_price; --��P����ݒ�
-- 2009/06/25 M.Sano Ver.1.5 add Start
        -- �o�א��ʂ��擾����B
        xxcos_common2_pkg.convert_quantity(
          iv_uom_code           => gt_edi_sales_data(i).standard_uom_code   --(IN)��P��
         ,in_case_qty           => gt_edi_sales_data(i).case_inc_num        --(IN)�P�[�X����
         ,in_ball_qty           => gt_edi_sales_data(i).bowl_inc_num        --(IN)�{�[������
         ,in_sum_indv_order_qty => lt_standard_qty                          --(IN)�����
         ,in_sum_shipping_qty   => lt_standard_qty                          --(IN)�����
         ,on_indv_shipping_qty  => lt_indv_shipping_qty                     --(OUT)�o�א���(�o��)
         ,on_case_shipping_qty  => lt_case_shipping_qty                     --(OUT)�o�א���(�P�[�X)
         ,on_ball_shipping_qty  => lt_ball_shipping_qty                     --(OUT)�o�א���(�{�[��)
         ,on_indv_stockout_qty  => lt_indv_stockout_qty                     --(OUT)���i����(�o��)
         ,on_case_stockout_qty  => lt_case_stockout_qty                     --(OUT)���i����(�P�[�X)
         ,on_ball_stockout_qty  => lt_ball_stockout_qty                     --(OUT)���i����(�{�[��)
         ,on_sum_stockout_qty   => lt_sum_stockout_qty                      --(OUT)���i����(�o������v)
         ,ov_errbuf             => lv_errbuf
         ,ov_retcode            => lv_retcode
         ,ov_errmsg             => lv_errmsg
        );
        IF  ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_api_expt;
        END IF;
-- 2009/06/25 M.Sano Ver.1.5 add End
      ELSE
        lt_standard_qty        := cn_0;  --0��ݒ�
        lt_standard_unit_price := cn_0;  --0��ݒ�
      END IF;
      --���|�R�[�h�Q�i���Ə��j�𕪊�����(�q���̕ҏW�p)
      lv_split_bill_cred_1 := SUBSTRB( gt_edi_sales_data(i).bill_cred_rec_code2, cn_1, cn_4 );  --1�`4��
      lv_split_bill_cred_2 := SUBSTRB( gt_edi_sales_data(i).bill_cred_rec_code2, cn_5, cn_4 );  --5�`8��
      lv_split_bill_cred_3 := SUBSTRB( gt_edi_sales_data(i).bill_cred_rec_code2, cn_9, cn_4 );  --9�`12��
      --�[�i���̌��̍ŏI�����擾����(���������ҏW�p)
      ld_last_day          := LAST_DAY( gt_edi_sales_data(i).orig_delivery_date );
      --�����J�n��-1���擾����(���������ҏW�p)
      ln_due_date_dd_num   := gt_edi_sales_data(i).sales_exp_day - cn_1;
      --�X�}�C���ȊO�̏ꍇ
      IF ( iv_process_pattern <> cv_5 ) THEN
        --------------------------
        --���������̕ҏW
        --------------------------
        --�����J�n����NULL�ȊO�̏ꍇ
        IF (  gt_edi_sales_data(i).sales_exp_day IS NOT NULL ) THEN
          --�����J�n���������P���̐ݒ�̏ꍇ
          IF ( gt_edi_sales_data(i).sales_exp_day IN ( cn_1, cn_32 )  ) THEN
            lv_billing_due_date := TO_CHAR( ld_last_day, cv_date_format ); --������ݒ�
          ELSE
            -- �[�i���̌��̍ŏI���������J�n��-1�̓�(��������)��菬�����ꍇ
            IF ( TO_NUMBER( TO_CHAR( ld_last_day, cv_d_format_dd ) ) < ln_due_date_dd_num ) THEN
              lv_billing_due_date := TO_CHAR( ld_last_day, cv_date_format );  --������ݒ�
            ELSE
              lv_billing_due_date := TO_CHAR( ld_last_day, cv_d_format_yyyymm ) ||
                                       LPAD( TO_CHAR( ln_due_date_dd_num ), cn_2, cn_0 ); --�[�i���̌�+�����J�n��-1��ݒ�
            END IF;
          END IF;
        ELSE
          lv_billing_due_date := NULL;
        END IF;
        --------------------------
        --���̑��̕ҏW
        --------------------------
        lv_address             := gt_edi_sales_data(i).address;              --�͂���Z��(����)
        lv_bill_cred_rec_code2 := gt_edi_sales_data(i).bill_cred_rec_code2;  --�`�F�[���X�ŗL�G���A(�w�b�_�[)
        lv_pb_nb_rate          := NULL;                                      --����
      --�X�}�C���̏ꍇ
      ELSE
        --------------------------
        --�����̎擾
        --------------------------
        BEGIN
          SELECT  DECODE(  xlvv3.lookup_code
                          ,'', xlvv2.description  --PB���i�ȊO(NB�̕���)
                          ,xlvv1.description      --PB���i(PB�̕���)
                  )  rate
          INTO    lv_pb_nb_rate
          FROM    xxcos_sales_exp_lines    xsel
                 ,xxcos_sales_exp_headers  xseh
                 ,hz_cust_accounts         hca
                 ,xxcmm_cust_accounts      xca
                 ,xxcos_lookup_values_v    xlvv1 --�[����`�F�[���X�R�[�hPB
                 ,xxcos_lookup_values_v    xlvv2 --�[����`�F�[���X�R�[�hNB
                 ,xxcos_lookup_values_v    xlvv3 --PB���i�R�[�h
          WHERE   xsel.sales_exp_line_id      = gt_edi_sales_data(i).sales_exp_line_id
          AND     xsel.sales_exp_header_id    = xseh.sales_exp_header_id
          AND     xseh.ship_to_customer_code  = hca.account_number
          AND     hca.cust_account_id         = xca.customer_id
          AND     xlvv1.lookup_type           = cv_lkt_ship_to_pb
          AND     xlvv1.lookup_code           = xca.delivery_chain_code
          AND     xlvv2.lookup_type           = cv_lkt_ship_to_nb
          AND     xlvv2.lookup_code           = xca.delivery_chain_code
          AND     xlvv3.lookup_type(+)        = cv_lkt_pb_item
          AND     xlvv3.lookup_code(+)        = xsel.item_code
/* 2010/03/16 Ver1.10 Add Start */
          AND     TRUNC( gt_edi_sales_data(i).orig_delivery_date ) BETWEEN NVL( xlvv1.start_date_active, gd_min_date    )
                                                                   AND     NVL( xlvv1.end_date_active,   gd_max_date    )
          AND     TRUNC( gt_edi_sales_data(i).orig_delivery_date ) BETWEEN NVL( xlvv2.start_date_active, gd_min_date    )
                                                                   AND     NVL( xlvv2.end_date_active,   gd_max_date    )
          AND     TRUNC( gt_edi_sales_data(i).orig_delivery_date ) BETWEEN NVL( xlvv3.start_date_active(+), gd_min_date )
                                                                   AND     NVL( xlvv3.end_date_active(+),   gd_max_date )
/* 2010/03/16 Ver1.10 Add End   */
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --�X�}�C���̕����ΏۊO
            lv_pb_nb_rate := gv_prf_def_item_rate;  --�v���t�@�C���̕���
        END;
        --------------------------
        --���̑��̕ҏW
        --------------------------
        lv_billing_due_date    := NULL;  --��������
        lv_address             := NULL;  --�͂���Z��(����)
        lv_bill_cred_rec_code2 := NULL;  --�`�F�[���X�ŗL�G���A(�w�b�_�[)
      END IF;
      --------------------------
      --�q���̕ҏW
      --------------------------
      --�ɓ���(�����p�^�[���P)
      IF ( iv_process_pattern = cv_1 ) THEN
        IF (
             ( lv_split_bill_cred_1 <> cv_0000 )
             AND
             ( lv_split_bill_cred_2 <> cv_0000 )
           )
        THEN
          IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
            lv_whse_directly_class := cv_1;  --�q����
          ELSE
            lv_whse_directly_class := cv_2;  --����
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --�ݒ�Ȃ�
        END IF;
      --����(�����p�^�[���Q)
      ELSIF ( iv_process_pattern = cv_2 ) THEN
        IF ( lv_split_bill_cred_1 <> cv_0000 ) THEN
          IF ( lv_split_bill_cred_2 = cv_0000 ) THEN
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_1;  --�q����
            ELSE
              lv_whse_directly_class := NULL;  --�ݒ�Ȃ�
            END IF;
          ELSE
              lv_whse_directly_class := cv_2;  --����
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --�ݒ�Ȃ�
        END IF;
      --�H�H(�����p�^�[���R)
      ELSIF ( iv_process_pattern = cv_3 ) THEN
        IF ( lv_split_bill_cred_1 <> cv_0000 ) THEN
          IF ( lv_split_bill_cred_2 = cv_0000 ) THEN
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_1;  --�q����
            ELSE
              lv_whse_directly_class := NULL;  --�ݒ�Ȃ�
            END IF;
          ELSE
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_2;  --����
            ELSE
              lv_whse_directly_class := cv_3;  --���̑�
            END IF;
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --�ݒ�Ȃ�
        END IF;
      --�g�[�J��(�����p�^�[���S)
      ELSIF ( iv_process_pattern = cv_4 ) THEN
        IF ( lv_split_bill_cred_1 <> cv_0000 ) THEN
          IF ( lv_split_bill_cred_2 = cv_0000 ) THEN
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_1;  --�q����
            ELSE
              lv_whse_directly_class := NULL;  --�ݒ�Ȃ�
            END IF;
          ELSE
            IF ( lv_split_bill_cred_3 = cv_0000 ) THEN
              lv_whse_directly_class := cv_2;  --����
            ELSE
              lv_whse_directly_class := cv_3;  --���̑�
            END IF;
          END IF;
        ELSE
          lv_whse_directly_class := NULL;  --�ݒ�Ȃ�
        END IF;
      --�X�}�C��(�����p�^�[���T)
      ELSIF ( iv_process_pattern = cv_5 ) THEN
        lv_whse_directly_class  := NULL;
      END IF;
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD START ******************************************
      --------------------------
      --�s�m���̕ҏW
      --------------------------
      IF ( lv_ship_to_customer_code IS NULL AND lv_dlv_invoice_number IS NULL )
        OR ( lv_ship_to_customer_code <> gt_edi_sales_data(i).ship_to_customer_code )
        OR ( lv_dlv_invoice_number <> gt_edi_sales_data(i).dlv_invoice_number )
      THEN
        ln_line_no := 1;
        lv_ship_to_customer_code := gt_edi_sales_data(i).ship_to_customer_code;
        lv_dlv_invoice_number    := gt_edi_sales_data(i).dlv_invoice_number;
      ELSE
        ln_line_no := ln_line_no + 1;
      END IF;
/* 2009/11/05 Ver1.7 Add Start */
      --------------------------
      --�`�[�ԍ��̕ҏW
      --------------------------
      IF ( LENGTHB(gt_edi_sales_data(i).invoice_class) >= 2 ) THEN
        lv_invoice_class := SUBSTRB(gt_edi_sales_data(i).invoice_class, -2);
      ELSE
        lv_invoice_class := gt_edi_sales_data(i).invoice_class;
      END IF;
/* 2009/11/05 Ver1.7 Add End   */
--************************************* 2009/05/28 T.Tominaga Var1.4 ADD END   ******************************************
      --==============================================================
      --���ʊ֐��p�̕ϐ��ɒl��ݒ�
      --==============================================================
      -- �w�b�_�� --
      l_data_tab(cv_medium_class)             := gt_edi_media_class;                       -- �}�̋敪
      l_data_tab(cv_data_type_code)           := gt_data_type_code;                        -- �f�[�^��R�[�h
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD   START  *********************************************--
--****************�@2009/07/07   N.Maeda  Ver1.5   MOD   START  *********************************************--
      l_data_tab(cv_file_no)                  := gt_parallel_num;                          -- �t�@�C��No.
--      l_data_tab(cv_file_no)                  := gt_edi_sales_data(i).edi_forward_number;   -- �t�@�C��No.
--****************�@2009/07/07   N.Maeda  Ver1.5   MOD    END   *********************************************--
--      l_data_tab(cv_file_no)                  := TO_CHAR(NULL);
--****************�@2009/06/12   N.Maeda  Ver1.5   ADD    END   *********************************************--
      l_data_tab(cv_info_class)               := TO_CHAR(NULL);
      l_data_tab(cv_process_date)             := gv_f_o_date;                              -- ������
      l_data_tab(cv_process_time)             := gv_f_o_time;                              -- ��������
      l_data_tab(cv_base_code)                := gt_edi_sales_data(i).sales_base_code;     -- ���_�R�[�h
      l_data_tab(cv_base_name)                := gt_edi_sales_data(i).sales_base_name;     -- ���_���i�����j
      l_data_tab(cv_base_name_alt)            := gt_edi_sales_data(i).sales_base_phonetic; -- ���_���i�J�i�j
      l_data_tab(cv_edi_chain_code)           := iv_chain_store_code;                      -- EDI�`�F�[���X�R�[�h
      l_data_tab(cv_edi_chain_name)           := gt_edi_chain_name;                        -- EDI�`�F�[���X��
      l_data_tab(cv_edi_chain_name_alt)       := gt_edi_chain_name_phonetic;               -- EDI�`�F�[���X���i�J�i�j
      l_data_tab(cv_chain_code)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_report_code)              := TO_CHAR(NULL);
      l_data_tab(cv_report_show_name)         := TO_CHAR(NULL);
      l_data_tab(cv_cust_code)                := gt_edi_sales_data(i).ship_to_customer_code; -- �ڋq�R�[�h
      l_data_tab(cv_cust_name)                := gt_edi_sales_data(i).customer_name;         -- �ڋq���i�����j
      l_data_tab(cv_cust_name_alt)            := gt_edi_sales_data(i).customer_phonetic;     -- �ڋq���i�J�i�j
      l_data_tab(cv_comp_code)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_shop_code)                := TO_CHAR(NULL);
      l_data_tab(cv_shop_name)                := TO_CHAR(NULL);
      l_data_tab(cv_shop_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_code)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_name)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_name_alt)       := TO_CHAR(NULL);
      l_data_tab(cv_order_date)               := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_date)           := TO_CHAR(NULL);
      l_data_tab(cv_result_delv_date)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_delv_date)           := TO_CHAR(gt_edi_sales_data(i).orig_delivery_date, cv_date_format);  --�X�ܔ[�i��
      l_data_tab(cv_dc_date_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_dc_time_edi_data)         := TO_CHAR(NULL);
/* 2009/11/05 Ver1.7 Add Start */
--      l_data_tab(cv_invc_class)               := gt_edi_sales_data(i).invoice_class;  -- �`�[�敪
      l_data_tab(cv_invc_class)               := lv_invoice_class; -- �`�[�敪
/* 2009/11/05 Ver1.7 Mod End   */
      l_data_tab(cv_small_classif_code)       := TO_CHAR(NULL);
      l_data_tab(cv_small_classif_name)       := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_code)      := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_name)      := TO_CHAR(NULL);
      l_data_tab(cv_big_classif_code)         := gt_edi_sales_data(i).invoice_classification_code; -- �啪�ރR�[�h
      l_data_tab(cv_big_classif_name)         := TO_CHAR(NULL);
      l_data_tab(cv_op_department_code)       := TO_CHAR(NULL);
/* 2009/11/27 Ver1.9 Mod Start */
--      l_data_tab(cv_op_order_number)          := TO_CHAR(NULL);
      l_data_tab(cv_op_order_number)          := gt_edi_sales_data(i).order_invoice_number;  --����攭���ԍ�
/* 2009/11/27 Ver1.9 Mod End */
      l_data_tab(cv_check_digit_class)        := TO_CHAR(NULL);
      l_data_tab(cv_invc_number)              := gt_edi_sales_data(i).dlv_invoice_number;  --�`�[�ԍ�
      l_data_tab(cv_check_digit)              := TO_CHAR(NULL);
      l_data_tab(cv_close_date)               := TO_CHAR(NULL);
      l_data_tab(cv_order_no_ebs)             := TO_CHAR(NULL);
      l_data_tab(cv_ar_sale_class)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_classe)              := TO_CHAR(NULL);
      l_data_tab(cv_opportunity_no)           := TO_CHAR(NULL);
      l_data_tab(cv_contact_to)               := TO_CHAR(NULL);
      l_data_tab(cv_route_sales)              := TO_CHAR(NULL);
      l_data_tab(cv_corporate_code)           := TO_CHAR(NULL);
      l_data_tab(cv_maker_name)               := TO_CHAR(NULL);
      l_data_tab(cv_area_code)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_code)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name1_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name2_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_tel)               := TO_CHAR(NULL);
      l_data_tab(cv_vendor_charge)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_address)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_itouen)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_chain)       := TO_CHAR(NULL);
      l_data_tab(cv_delv_to)                  := TO_CHAR(NULL);
      l_data_tab(cv_delv_to1_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to2_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_address)          := lv_address;     --�͂���Z���i�����j
      l_data_tab(cv_delv_to_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_code)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_comp_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_shop_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address)          := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_order_possible_date)      := TO_CHAR(NULL);
      l_data_tab(cv_perm_possible_date)       := TO_CHAR(NULL);
      l_data_tab(cv_forward_month)            := TO_CHAR(NULL);
      l_data_tab(cv_payment_settlement_date)  := TO_CHAR(NULL);
      l_data_tab(cv_handbill_start_date_act)  := TO_CHAR(NULL);
      l_data_tab(cv_billing_due_date)         := lv_billing_due_date;  --��������
      l_data_tab(cv_ship_time)                := TO_CHAR(NULL);
      l_data_tab(cv_delv_schedule_time)       := TO_CHAR(NULL);
      l_data_tab(cv_order_time)               := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item1)           := TO_CHAR(gt_edi_sales_data(i).orig_inspect_date, cv_date_format); --�ėp���t����1
      l_data_tab(cv_gen_date_item2)           := TO_CHAR(gt_edi_sales_data(i).orig_inspect_date, cv_date_format); --�ėp���t����2
      l_data_tab(cv_gen_date_item3)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item4)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item5)           := TO_CHAR(NULL);
      l_data_tab(cv_arrival_ship_class)       := TO_CHAR(NULL);
      l_data_tab(cv_vendor_class)             := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed_class)      := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_use_class)     := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_code)      := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_name)      := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_method)         := TO_CHAR(NULL);
      l_data_tab(cv_cent_use_class)           := TO_CHAR(NULL);
      l_data_tab(cv_cent_whse_class)          := TO_CHAR(NULL);
      l_data_tab(cv_cent_area_class)          := TO_CHAR(NULL);
      l_data_tab(cv_cent_arrival_class)       := TO_CHAR(NULL);
      l_data_tab(cv_depot_class)              := TO_CHAR(NULL);
      l_data_tab(cv_tcdc_class)               := TO_CHAR(NULL);
      l_data_tab(cv_upc_flag)                 := TO_CHAR(NULL);
      l_data_tab(cv_simultaneously_class)     := TO_CHAR(NULL);
      l_data_tab(cv_business_id)              := TO_CHAR(NULL);
      l_data_tab(cv_whse_directly_class)      := lv_whse_directly_class;  --�q���敪
      l_data_tab(cv_premium_rebate_class)     := TO_CHAR(NULL);
      l_data_tab(cv_item_type)                := TO_CHAR(NULL);
      l_data_tab(cv_cloth_house_food_class)   := TO_CHAR(NULL);
      l_data_tab(cv_mix_class)                := TO_CHAR(NULL);
      l_data_tab(cv_stk_class)                := TO_CHAR(NULL);
      l_data_tab(cv_last_modify_site_class)   := TO_CHAR(NULL);
      l_data_tab(cv_report_class)             := TO_CHAR(NULL);
      l_data_tab(cv_addition_plan_class)      := TO_CHAR(NULL);
      l_data_tab(cv_registration_class)       := TO_CHAR(NULL);
      l_data_tab(cv_specific_class)           := TO_CHAR(NULL);
      l_data_tab(cv_dealings_class)           := TO_CHAR(NULL);
      l_data_tab(cv_order_class)              := TO_CHAR(NULL);
      l_data_tab(cv_sum_line_class)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_guidance_class)      := TO_CHAR(NULL);
      l_data_tab(cv_ship_class)               := gt_edi_sales_data(i).dlv_invoice_class;  --�o�׋敪
      l_data_tab(cv_prod_code_use_class)      := TO_CHAR(NULL);
      l_data_tab(cv_cargo_item_class)         := TO_CHAR(NULL);
      l_data_tab(cv_ta_class)                 := TO_CHAR(NULL);
      l_data_tab(cv_plan_code)                := TO_CHAR(NULL);
      l_data_tab(cv_category_code)            := TO_CHAR(NULL);
      l_data_tab(cv_category_class)           := TO_CHAR(NULL);
      l_data_tab(cv_carrier_means)            := TO_CHAR(NULL);
      l_data_tab(cv_counter_code)             := TO_CHAR(NULL);
      l_data_tab(cv_move_sign)                := TO_CHAR(NULL);
      l_data_tab(cv_eos_handwriting_class)    := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_section_code)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed)            := TO_CHAR(NULL);
      l_data_tab(cv_attach_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_op_floor)                 := TO_CHAR(NULL);
      l_data_tab(cv_text_no)                  := TO_CHAR(NULL);
      l_data_tab(cv_in_store_code)            := TO_CHAR(NULL);
      l_data_tab(cv_tag_data)                 := TO_CHAR(NULL);
      l_data_tab(cv_competition_code)         := TO_CHAR(NULL);
      l_data_tab(cv_billing_chair)            := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_code)         := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_short_name)   := TO_CHAR(NULL);
      l_data_tab(cv_direct_delv_rcpt_fee)     := TO_CHAR(NULL);
      l_data_tab(cv_bill_info)                := TO_CHAR(NULL);
      l_data_tab(cv_description)              := TO_CHAR(NULL);
      l_data_tab(cv_interior_code)            := TO_CHAR(NULL);
      l_data_tab(cv_order_info_delv_category) := TO_CHAR(NULL);
      l_data_tab(cv_purchase_type)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_opened_site)         := TO_CHAR(NULL);
      l_data_tab(cv_counter_name)             := TO_CHAR(NULL);
      l_data_tab(cv_extension_number)         := TO_CHAR(NULL);
      l_data_tab(cv_charge_name)              := TO_CHAR(NULL);
      l_data_tab(cv_price_tag)                := TO_CHAR(NULL);
      l_data_tab(cv_tax_type)                 := TO_CHAR(NULL);
      l_data_tab(cv_consumption_tax_class)    := TO_CHAR(NULL);
      l_data_tab(cv_brand_class)              := TO_CHAR(NULL);
      l_data_tab(cv_id_code)                  := TO_CHAR(NULL);
      l_data_tab(cv_department_code)          := TO_CHAR(NULL);
      l_data_tab(cv_department_name)          := TO_CHAR(NULL);
      l_data_tab(cv_item_type_number)         := TO_CHAR(NULL);
      l_data_tab(cv_description_department)   := TO_CHAR(NULL);
      l_data_tab(cv_price_tag_method)         := TO_CHAR(NULL);
      l_data_tab(cv_reason_column)            := TO_CHAR(NULL);
      l_data_tab(cv_a_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_d_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_brand_code)               := TO_CHAR(NULL);
      l_data_tab(cv_line_code)                := TO_CHAR(NULL);
      l_data_tab(cv_class_code)               := TO_CHAR(NULL);
      l_data_tab(cv_a1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_header)    := lv_bill_cred_rec_code2;  --�`�F�[���X�ŗL�G���A(�w�b�_�[)
      l_data_tab(cv_order_connection_number)  := TO_CHAR(NULL);
      --���ו� --
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD START ******************************************
--      l_data_tab(cv_line_no)                  := TO_CHAR(gt_edi_sales_data(i).dlv_invoice_line_number); --�sNO
      l_data_tab(cv_line_no)                  := TO_CHAR(ln_line_no); --�sNO
--************************************* 2009/05/28 T.Tominaga Var1.4 MOD END   ******************************************
      l_data_tab(cv_stkout_class)             := TO_CHAR(NULL);
      l_data_tab(cv_stkout_reason)            := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_itouen)         := gt_edi_sales_data(i).item_code;  --���i�R�[�h(�ɓ���)
      l_data_tab(cv_prod_code1)               := TO_CHAR(NULL);
      l_data_tab(cv_prod_code2)               := TO_CHAR(NULL);
      l_data_tab(cv_jan_code)                 := gt_edi_sales_data(i).jan_code;  --JAN�R�[�h
      l_data_tab(cv_itf_code)                 := gt_edi_sales_data(i).itf_code;  --ITF�R�[�h
      l_data_tab(cv_extension_itf_code)       := TO_CHAR(NULL);
      l_data_tab(cv_case_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_item_type)      := TO_CHAR(NULL);
      l_data_tab(cv_prod_class)               := gt_edi_sales_data(i).item_div_code;  --���i�敪
      l_data_tab(cv_prod_name)                := gt_edi_sales_data(i).item_name;  --���i��(����)
      l_data_tab(cv_prod_name1_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_name2_alt)           := gt_edi_sales_data(i).item_phonetic1;  --���i��(�J�i)
      l_data_tab(cv_item_standard1)           := TO_CHAR(NULL);
      l_data_tab(cv_item_standard2)           := gt_edi_sales_data(i).item_phonetic2;  --���i��(�J�i)
      l_data_tab(cv_qty_in_case)              := TO_CHAR(NULL);
      l_data_tab(cv_num_of_cases)             := gt_edi_sales_data(i).case_inc_num;  --�P�[�X����
      l_data_tab(cv_num_of_ball)              := TO_CHAR(gt_edi_sales_data(i).bowl_inc_num);  --�{�[������
      l_data_tab(cv_item_color)               := TO_CHAR(NULL);
      l_data_tab(cv_item_size)                := TO_CHAR(NULL);
      l_data_tab(cv_expiration_date)          := TO_CHAR(NULL);
      l_data_tab(cv_prod_date)                := TO_CHAR(NULL);
      l_data_tab(cv_order_uom_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_ship_uom_qty)             := TO_CHAR(NULL);
      l_data_tab(cv_packing_uom_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_deal_code)                := TO_CHAR(NULL);
      l_data_tab(cv_deal_class)               := TO_CHAR(NULL);
      l_data_tab(cv_collation_code)           := TO_CHAR(NULL);
      l_data_tab(cv_uom_code)                 := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_class)         := TO_CHAR(NULL);
      l_data_tab(cv_parent_packing_number)    := TO_CHAR(NULL);
      l_data_tab(cv_packing_number)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_group_code)          := TO_CHAR(NULL);
      l_data_tab(cv_case_dismantle_flag)      := TO_CHAR(NULL);
      l_data_tab(cv_case_class)               := TO_CHAR(NULL);
      l_data_tab(cv_indv_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_case_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_sum_order_qty)            := TO_CHAR(NULL);
-- 2009/06/25 M.Sano Ver.1.5 mod Start
--      l_data_tab(cv_indv_ship_qty)            := TO_CHAR(lt_standard_qty);  --�o�א���(�o��)
--      l_data_tab(cv_case_ship_qty)            := TO_CHAR(NULL);
--      l_data_tab(cv_ball_ship_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_indv_ship_qty)            := TO_CHAR(lt_indv_shipping_qty);  --�o�א���(�o��)
      l_data_tab(cv_case_ship_qty)            := TO_CHAR(lt_case_shipping_qty);  --�o�א���(�P�[�X)
      l_data_tab(cv_ball_ship_qty)            := TO_CHAR(lt_ball_shipping_qty);  --�o�א���(�{�[��)
-- 2009/06/25 M.Sano Ver.1.5 mod End
      l_data_tab(cv_pallet_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_ship_qty)             := TO_CHAR(lt_standard_qty);  --�o�א���(���v�A�o��)
-- 2009/06/25 M.Sano Ver.1.5 mod Start
--      l_data_tab(cv_indv_stkout_qty)          := TO_CHAR(NULL);
--      l_data_tab(cv_case_stkout_qty)          := TO_CHAR(NULL);
--      l_data_tab(cv_ball_stkout_qty)          := TO_CHAR(NULL);
--      l_data_tab(cv_sum_stkout_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_indv_stkout_qty)          := TO_CHAR(lt_indv_stockout_qty);   --���i����(�o��)
      l_data_tab(cv_case_stkout_qty)          := TO_CHAR(lt_case_stockout_qty);    --���i����(�P�[�X)
      l_data_tab(cv_ball_stkout_qty)          := TO_CHAR(lt_ball_stockout_qty);   --���i����(�{�[��)
      l_data_tab(cv_sum_stkout_qty)           := TO_CHAR(lt_sum_stockout_qty);     --���i����(���v�A�o��)
-- 2009/06/25 M.Sano Ver.1.5 mod End
      l_data_tab(cv_case_qty)                 := TO_CHAR(NULL);
      l_data_tab(cv_fold_container_indv_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_order_unit_price)         := TO_CHAR(lt_standard_unit_price); --���P��(����)
      l_data_tab(cv_ship_unit_price)          := TO_CHAR(NULL);
      l_data_tab(cv_order_cost_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_cost_amt)            := TO_CHAR(gt_edi_sales_data(i).sale_amount); --������z
      l_data_tab(cv_stkout_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_selling_price)            := TO_CHAR(NULL);
      l_data_tab(cv_order_price_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_ship_price_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_stkout_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_a_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_d_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_depth)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_height)     := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_width)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_weight)     := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item1)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item2)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item3)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item1)            := lv_pb_nb_rate ;                    --�ėp�t�����ڂP
      l_data_tab(cv_gen_add_item2)            := gt_edi_sales_data(i).sales_class;  --�ėp�t�����ڂQ
      l_data_tab(cv_gen_add_item3)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_line)      := TO_CHAR(NULL);
      --�t�b�^�� --
      l_data_tab(cv_invc_indv_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_order_qty)       := TO_CHAR(NULL);
/* 2009/07/29 Ver1.5 Mod Start */
--      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR(gt_edi_sales_data(i).sum_standard_qty);  --(�`�[�v)�o�א���(�o��)
--      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR(NULL);
--      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR(gt_sum_qty(lv_sum_qty_seq).invc_indv_qty_sum); --(�`�[�v)�o�א���(�o��)
      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR(gt_sum_qty(lv_sum_qty_seq).invc_case_qty_sum); --(�`�[�v)�o�א���(�P�[�X)
      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(gt_sum_qty(lv_sum_qty_seq).invc_ball_qty_sum); --(�`�[�v)�o�א���(�{�[��)
/* 2009/07/29 Ver1.5 Mod End   */
      l_data_tab(cv_invc_pallet_ship_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_ship_qty)        := TO_CHAR(gt_edi_sales_data(i).sum_standard_qty);  --(�`�[�v)�o�א���(�o��)
      l_data_tab(cv_invc_indv_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_stkout_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_invc_fold_container_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_cost_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_cost_amt)       := TO_CHAR(gt_edi_sales_data(i).sum_sale_amount);   --(�`�[�v)�������z(�o��)
      l_data_tab(cv_invc_stkout_cost_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_price_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_price_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_stkout_price_amt)    := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_order_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_case_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_pallet_ship_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_ship_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_case_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_stkout_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_fold_container_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_t_order_cost_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_cost_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_order_price_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_price_amt)       := TO_CHAR(NULL);
      l_data_tab(cv_t_line_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_invc_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_footer)    := TO_CHAR(NULL);
/* 2009/04/28 Ver1.3 Add Start */
      l_data_tab(cv_attribute)                := TO_CHAR(NULL);
/* 2009/04/28 Ver1.3 Add End   */
      --==============================================================
      --�f�[�^���^(A-6)
      --==============================================================
      BEGIN
        xxcos_common2_pkg.makeup_data_record(
           iv_edit_data        =>  l_data_tab          --�o�̓f�[�^���
          ,iv_file_type        =>  cv_0                --�t�@�C���`��(�Œ蒷)
          ,iv_data_type_table  =>  gt_data_type_table  --���C�A�E�g��`���
          ,iv_record_type      =>  gv_if_data          --�f�[�^���R�[�h���ʎq
          ,ov_data_record      =>  lv_data_record      --�f�[�^���R�[�h
          ,ov_errbuf           =>  lv_errbuf           --�G���[���b�Z�[�W
          ,ov_retcode          =>  lv_retcode          --���^�[���R�[�h
          ,ov_errmsg           =>  lv_errmsg           --���[�U�E�G���[���b�Z�[�W
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application      --�A�v���P�[�V����
                          ,iv_name         => cv_msg_out_inf_err  --�o�͏��ҏW�G���[
                          ,iv_token_name1  => cv_tkn_err_m        --�g�[�N���R�[�h�P
                         ,iv_token_value1  => lv_errmsg           --���ʊ֐��̃G���[���b�Z�[�W
                       );
        RAISE global_api_expt;
      END;
      --==============================================================
      --�t�@�C���o��(A-7)
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => gt_f_handle     --�t�@�C���n���h��
       ,buffer => lv_data_record  --�o�͕���(�f�[�^)
      );
--
    END LOOP output_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_sale_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : �t�@�C���I������(A-8)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_footer'; -- �v���O������
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
/* 2009/04/28 Ver1.3 Mod Start */
--    lv_footer_output  VARCHAR2(1000);  --�t�b�^�o�͗p
    lv_footer_output  VARCHAR2(5000);  --�t�b�^�o�͗p
/* 2009/04/28 Ver1.3 Mod End   */
    lv_dummy1         VARCHAR2(1);     --IF���Ɩ��n��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy2         VARCHAR2(1);     --���_�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy3         VARCHAR2(1);     --���_����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy4         VARCHAR2(1);     --�`�F�[���X�R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy5         VARCHAR2(1);     --�`�F�[���X����(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy6         VARCHAR2(1);     --�f�[�^��R�[�h(�t�b�^�ł͎g�p���Ȃ�)
    lv_dummy7         VARCHAR2(1);     --���񏈗��ԍ�(�t�b�^�ł͎g�p���Ȃ�)
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
    --==============================================================
    --���ʊ֐��Ăяo��
    --==============================================================
    --EDI�w�b�_�E�t�b�^�t�^
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gv_if_footer      --�t�^�敪
     ,iv_from_series     =>  lv_dummy1         --IF���Ɩ��n��R�[�h
     ,iv_base_code       =>  lv_dummy2         --���_�R�[�h
     ,iv_base_name       =>  lv_dummy3         --���_����
     ,iv_chain_code      =>  lv_dummy4         --�`�F�[���X�R�[�h
     ,iv_chain_name      =>  lv_dummy5         --�`�F�[���X����
     ,iv_data_kind       =>  lv_dummy6         --�f�[�^��R�[�h
     ,iv_row_number      =>  lv_dummy7         --���񏈗��ԍ�
     ,in_num_of_records  =>  gn_data_cnt       --���R�[�h����
     ,ov_retcode         =>  lv_retcode        --���^�[���R�[�h
     ,ov_output          =>  lv_footer_output  --�t�b�^���R�[�h
     ,ov_errbuf          =>  lv_errbuf         --�G���[���b�Z�[�W
     ,ov_errmsg          =>  lv_errmsg         --���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF  ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application   --�A�v���P�[�V����
                     ,iv_name         => cv_msg_proc_err  --���ʊ֐��G���[
                     ,iv_token_name1  => cv_tkn_err_m     --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_errmsg        --���ʊ֐��̃G���[���b�Z�[�W
                   );
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --�t�@�C���o��
    --==============================================================
    --�t�b�^�o��
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --�t�@�C���n���h��
     ,buffer => lv_footer_output  --�o�͕���(�t�b�^)
    );
    --==============================================================
    --�t�@�C���N���[�Y
    --==============================================================
    UTL_FILE.FCLOSE(
      file => gt_f_handle
    );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END output_footer;
--
  /**********************************************************************************
   * Procedure Name   : upd_sale_exp_head_send
   * Description      : �̔����уw�b�_TBL�t���O�X�V�i�쐬�j(A-9)
   ***********************************************************************************/
  PROCEDURE upd_sale_exp_head_send(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sale_exp_head_send'; -- �v���O������
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
    lv_tkn_name  VARCHAR2(50);  --�g�[�N���擾�p
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
    BEGIN
      -- �̔����уw�b�_TBL�t���O�X�V�i�쐬�j
      FORALL i IN  1.. gt_update_header_id.LAST
        UPDATE  xxcos_sales_exp_headers   xseh  --�̔����уw�b�_
        SET     xseh.edi_send_date           = cd_process_date            --EDI���M����
               ,xseh.edi_interface_flag      = cv_y                       --EDI���M�ς݃t���O
               ,xseh.last_updated_by         = cn_last_updated_by         --�ŏI�X�V��
               ,xseh.last_update_date        = cd_last_update_date        --�ŏI�X�V��
               ,xseh.last_update_login       = cn_last_update_login       --�ŏI�X�V���O�C��
               ,xseh.request_id              = cn_request_id              --�v��ID
               ,xseh.program_application_id  = cn_program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,xseh.program_id              = cn_program_id              --�R���J�����g�E�v���O����ID
               ,xseh.program_update_date     = cd_program_update_date     --�v���O�����X�V��
        WHERE   xseh.edi_interface_flag      = cv_n                       --EDI���M�σt���O(�����M)
        AND     xseh.sales_exp_header_id     = gt_update_header_id(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     --�A�v���P�[�V����
                         ,iv_name         => cv_msg_table_tkn2  --�̔����уw�b�_�e�[�u��
                       );
        --���b�Z�[�W�ҏW
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application  --�A�v���P�[�V����
                         ,iv_name         => cv_msg_upd_err  --�f�[�^�X�V�G���[
                         ,iv_token_name1  => cv_tkn_table_n  --�g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_tkn_name     --�̔����уw�b�_
                         ,iv_token_name2  => cv_tkn_key      --�g�[�N���R�[�h�Q
                         ,iv_token_value2 => NULL            --NULL
                       );
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_sale_exp_head_send;
--
  /**********************************************************************************
   * Procedure Name   : upd_sale_exp_head_rep
   * Description      : �̔����уw�b�_TBL�t���O�X�V�i�����j(A-11)
   ***********************************************************************************/
  PROCEDURE upd_sale_exp_head_rep(
    iv_inv_cust_code    IN  VARCHAR2,     -- ������ڋq�R�[�h
    iv_send_date        IN  VARCHAR2,     -- ���M��
    ov_errbuf           OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sale_exp_head_rep'; -- �v���O������
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
    lv_tkn_name   VARCHAR2(50);  --�g�[�N���擾�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���M�ς̔̔����я��
    CURSOR sale_data_cur
    IS
      SELECT  xseh.sales_exp_header_id  header_id   --�w�b�_ID
      FROM    xxcos_sales_exp_headers   xseh        --�̔����уw�b�_
      WHERE   xseh.edi_interface_flag  = cv_y                                     --EDI���M�σt���O(���M)
      AND     xseh.edi_send_date       = TO_DATE( iv_send_date, cv_date_format )  --EDI���M��
      AND     xseh.ship_to_customer_code IN
        ( SELECT  xxchv.ship_account_number
          FROM    xxcfr_cust_hierarchy_v  xxchv   --�ڋq�K�w�r���[
          WHERE   xxchv.bill_account_number  = iv_inv_cust_code
        ) 
      FOR UPDATE NOWAIT;
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
    -- ���b�N�擾�A�f�[�^�擾
    OPEN  sale_data_cur;
    FETCH sale_data_cur BULK COLLECT INTO gt_update_header_id;
    -- ���o�����擾
    gn_target_cnt := sale_data_cur%ROWCOUNT;
    CLOSE sale_data_cur;
--
    IF  ( gn_target_cnt <> cn_0 ) THEN
      BEGIN
        ----------------------
        --�̔����уw�b�_�X�V
        ----------------------
        FORALL i IN 1.. gn_target_cnt
          UPDATE  xxcos_sales_exp_headers   xseh  --�̔����уw�b�_
          SET     xseh.edi_interface_flag      = cv_n                       --EDI���M�ς݃t���O(�����M)
                 ,xseh.last_updated_by         = cn_last_updated_by         --�ŏI�X�V��
                 ,xseh.last_update_date        = cd_last_update_date        --�ŏI�X�V��
                 ,xseh.last_update_login       = cn_last_update_login       --�ŏI�X�V���O�C��
                 ,xseh.request_id              = cn_request_id              --�v��ID
                 ,xseh.program_application_id  = cn_program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                 ,xseh.program_id              = cn_program_id              --�R���J�����g�E�v���O����ID
                 ,xseh.program_update_date     = cd_program_update_date     --�v���O�����X�V��
          WHERE   xseh.sales_exp_header_id     = gt_update_header_id(i)
          ;
      EXCEPTION
        WHEN OTHERS THEN
          --�g�[�N���擾
          lv_tkn_name := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          ,iv_name          => cv_msg_table_tkn2  --�̔����уw�b�_�e�[�u��
                         );
          --���b�Z�[�W�ҏW
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application  --�A�v���P�[�V����
                         ,iv_name         => cv_msg_upd_err  --�f�[�^�X�V�G���[
                         ,iv_token_name1  => cv_tkn_table_n  --�g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_tkn_name     --�̔����уw�b�_
                         ,iv_token_name2  => cv_tkn_key      --�g�[�N���R�[�h�Q
                         ,iv_token_value2 => NULL            --NULL
                       );
          lv_errbuf := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
    ----------------------
    --���팏���̐ݒ�
    ----------------------
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN lock_expt THEN
      --�J�[�\���N���[�Y
      IF ( sale_data_cur%ISOPEN ) THEN
        CLOSE sale_data_cur;
      END IF;
      --�g�[�N���擾
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_table_tkn2  --�̔����уw�b�_�e�[�u��
                     );
      --���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_lock_err    --���b�N�G���[
                     ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_name        --�̔����уw�b�_�e�[�u��
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_sale_exp_head_rep;
/* 2010/03/16 Ver1.10 Add Start */
--
  /**********************************************************************************
   * Procedure Name   : upd_no_target
   * Description      : �̔����ђ��o�ΏۊO�X�V(A-12)
   ***********************************************************************************/
  PROCEDURE upd_no_target(
    ov_errbuf           OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_no_target'; -- �v���O������
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
    ln_data_chk   NUMBER(1)     := 0; --���݃`�F�b�N�p
    lv_tkn_name   VARCHAR2(50);       --�g�[�N���擾�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o�ΏۊO�̔̔����я��
    CURSOR no_taget_cur
    IS
      SELECT  /*+
                INDEX(xseh xxcos_sales_exp_headers_n03)
              */
              1                         data_chk    --���݃`�F�b�N
      FROM    xxcos_sales_exp_headers   xseh        --�̔����уw�b�_
      WHERE   xseh.edi_interface_flag  = cv_n       --EDI���M�σt���O(�����M)
      AND     xseh.business_date       < TRUNC( ADD_MONTHS( cd_process_date, - gn_edi_trg_hold_m ), cv_d_format_mm )
                                                    --�o�^�Ɩ����t���ێ����Ԃ��O
      FOR UPDATE OF
        xseh.sales_exp_header_id
      NOWAIT
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
    -- ���b�N�擾�A�f�[�^�擾
    OPEN no_taget_cur;
    FETCH no_taget_cur INTO ln_data_chk;
    CLOSE no_taget_cur;
--
    IF  ( ln_data_chk <> cn_0 ) THEN
      BEGIN
        ----------------------
        --�̔����уw�b�_�X�V
        ----------------------
        UPDATE  /*+
                  INDEX(xseh xxcos_sales_exp_headers_n03)
                */
                xxcos_sales_exp_headers   xseh  --�̔����уw�b�_
        SET     xseh.edi_interface_flag      = cv_s                       --EDI���M�ς݃t���O(�ΏۊO)
               ,xseh.last_updated_by         = cn_last_updated_by         --�ŏI�X�V��
               ,xseh.last_update_date        = cd_last_update_date        --�ŏI�X�V��
               ,xseh.last_update_login       = cn_last_update_login       --�ŏI�X�V���O�C��
               ,xseh.request_id              = cn_request_id              --�v��ID
               ,xseh.program_application_id  = cn_program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,xseh.program_id              = cn_program_id              --�R���J�����g�E�v���O����ID
               ,xseh.program_update_date     = cd_program_update_date     --�v���O�����X�V��
       WHERE    xseh.edi_interface_flag      = cv_n                       --EDI���M�σt���O(�����M)
       AND      xseh.business_date           < TRUNC( ADD_MONTHS( cd_process_date, - gn_edi_trg_hold_m ), cv_d_format_mm )
       ;
       --�����擾
       gn_target_cnt := SQL%ROWCOUNT;
      EXCEPTION
        WHEN OTHERS THEN
          --�g�[�N���擾
          lv_tkn_name := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          ,iv_name          => cv_msg_table_tkn2  --�̔����уw�b�_�e�[�u��
                         );
          --���b�Z�[�W�ҏW
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application  --�A�v���P�[�V����
                         ,iv_name         => cv_msg_upd_err  --�f�[�^�X�V�G���[
                         ,iv_token_name1  => cv_tkn_table_n  --�g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_tkn_name     --�̔����уw�b�_
                         ,iv_token_name2  => cv_tkn_key      --�g�[�N���R�[�h�Q
                         ,iv_token_value2 => NULL            --NULL
                       );
          lv_errbuf := SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
    ----------------------
    --���팏���̐ݒ�
    ----------------------
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
    -- *** ���b�N�G���[ ***
    WHEN lock_expt THEN
      --�J�[�\���N���[�Y
      IF ( no_taget_cur%ISOPEN ) THEN
        CLOSE no_taget_cur;
      END IF;
      --�g�[�N���擾
      lv_tkn_name := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_table_tkn2  --�̔����уw�b�_�e�[�u��
                     );
      --���b�Z�[�W�擾
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application     --�A�v���P�[�V����
                     ,iv_name         => cv_msg_lock_err    --���b�N�G���[
                     ,iv_token_name1  => cv_tkn_table       --�g�[�N���R�[�h�P
                     ,iv_token_value1 => lv_tkn_name        --�̔����уw�b�_�e�[�u��
                   );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_no_target;
/* 2010/03/16 Ver1.10 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_run_class      IN VARCHAR2,   -- ���s�敪�F�u0:�쐬�v�u1:�����v�u2:�ΏۊO�X�V�v
    iv_inv_cust_code  IN VARCHAR2,   -- ������ڋq�R�[�h
    iv_send_date      IN VARCHAR2,   -- ���M��(YYYYMMDD)
/* 2009/04/15 Add Start */
    iv_sales_exp_ptn  IN VARCHAR2,   -- EDI�̔����я����p�^�[��
/* 2009/04/15 Add End   */
    ov_errbuf         OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_no_target_msg      VARCHAR2(5000);  --�ΏۂȂ����b�Z�[�W�擾�p
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ���̓p�����^�`�F�b�N����(A-1)
    -- ===============================
    input_param_check(
      iv_run_class     -- ���s�敪�F�u0:�쐬�v�u1:�����v�u2:�ΏۊO�X�V�v
     ,iv_inv_cust_code -- ������ڋq�R�[�h
     ,iv_send_date     -- ���M��(YYYYMMDD)
/* 2009/04/15 Add Start */
     ,iv_sales_exp_ptn -- EDI�̔����я����p�^�[��
/* 2009/04/15 Add End   */
     ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
/* 2010/03/16 Ver1.10 Add Start */
    --�ΏۊO�X�V�����ȊO�̏ꍇ�̐�����擾�A���݃`�F�b�N�����s
    IF ( iv_run_class <> gv_run_class_cd_update ) THEN
/* 2010/03/16 Ver1.10 Add End   */
      -- ===============================
      -- �����Ώیڋq�擾����(A-2)
      -- ===============================
      get_custom_data(
        iv_inv_cust_code -- ������ڋq�R�[�h
/* 2009/04/15 Add Start */
       ,iv_sales_exp_ptn -- EDI�̔����я����p�^�[��
/* 2009/04/15 Add End   */
       ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    END IF;
/* 2010/03/16 Ver1.10 Add End   */
--
/* 2010/03/16 Ver1.10 Mod Start */
--    --==============================================================
--    --  �쐬�����̏ꍇ
--    --==============================================================
--    IF ( iv_run_class = gv_run_class_cd_create ) THEN
    IF ( iv_run_class <> gv_run_class_cd_cancel ) THEN
/* 2010/03/16 Ver1.10 Mod End   */
      -- ===============================
      -- ��������(A-3)
      -- ===============================
      init(
/* 2010/03/16 Ver1.10 Mod Start */
--        lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
        iv_run_class     -- ���s�敪
       ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
/* 2010/03/16 Ver1.10 Mod End   */
       ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    END IF;
--
    --==============================================================
    --  �쐬�����̏ꍇ
    --==============================================================
    IF ( iv_run_class = gv_run_class_cd_create ) THEN
/* 2010/03/16 Ver1.10 Add End   */
      --�����Ώیڋq(�`�F�[���X�P��)���[�v
      <<chain_store_loop>>
      FOR i IN 1.. gn_chain_store_cnt LOOP
        -- ===============================
        -- �t�@�C����������(A-4)
        -- ===============================
        output_header(
          gt_chain_store(i).chain_store_code  -- �����Ώیڋq�̃`�F�[���X
         ,lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          --�t�@�C����OPEN����Ă���ꍇ�N���[�Y(A-10)
          IF ( UTL_FILE.IS_OPEN(
                 file => gt_f_handle
               )
             )
          THEN
            UTL_FILE.FCLOSE(
              file => gt_f_handle
            );
          END IF;
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- �̔����я�񒊏o(A-5)
        -- ===============================
        get_sale_data(
          gt_chain_store(i).chain_store_code  -- �����Ώیڋq�̃`�F�[���X
/* 2009/04/15 Del Start */
--         ,iv_inv_cust_code                    -- �p�����[�^�̐�����ڋq�R�[�h
/* 2009/04/15 Del End   */
         ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF  ( lv_retcode <> cv_status_normal ) THEN
          --�t�@�C����OPEN����Ă���ꍇ�N���[�Y(A-10)
          IF ( UTL_FILE.IS_OPEN(
                 file => gt_f_handle
               )
             )
          THEN
            UTL_FILE.FCLOSE(
              file => gt_f_handle
            );
          END IF;
          RAISE global_process_expt;
        END IF;
        --1�`�F�[���X���̏����Ώ۔���
        IF  ( gn_data_cnt <> cn_0 ) THEN
          -- ===============================
          -- �f�[�^�ҏW(A-6),(A-7)
          -- ===============================
          edit_sale_data(
            gt_chain_store(i).chain_store_code  -- �����Ώیڋq�̃`�F�[���X
           ,gt_chain_store(i).process_pattern   --�����Ώۂ̏����p�^�[��
           ,lv_errbuf  -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            --�t�@�C����OPEN����Ă���ꍇ�N���[�Y(A-10)
            IF ( UTL_FILE.IS_OPEN(
                   file => gt_f_handle
                 )
               )
            THEN
              UTL_FILE.FCLOSE(
                file => gt_f_handle
              );
            END IF;
            RAISE global_process_expt;
          END IF;
          -- ===============================
          -- �t�@�C���I������(A-8)
          -- ===============================
          output_footer(
            lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            --�t�@�C����OPEN����Ă���ꍇ�N���[�Y(A-10)
            IF ( UTL_FILE.IS_OPEN(
                   file => gt_f_handle
                 )
               )
            THEN
              UTL_FILE.FCLOSE(
                file => gt_f_handle
              );
            END IF;
            RAISE global_process_expt;
          END IF;
          -- =========================================
          -- �̔����уw�b�_TBL�t���O�X�V�i�쐬�j(A-9)
          -- =========================================
          upd_sale_exp_head_send(
            lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          -- =========================================
          -- ���������̐ݒ�
          -- =========================================
          gn_target_cnt := gn_target_cnt + gn_data_cnt; --1�`�F�[���X���̑Ώۃf�[�^�𑫂�
        --�ΏۂȂ�
        ELSE
          --���b�Z�[�W�擾
          lv_no_target_msg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application        --�A�v���P�[�V����
                                ,iv_name         => cv_msg_no_target_err  --�p�����[�^�[�o��(�����ΏۂȂ�)
                              );
          --���b�Z�[�W�ɏo��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_no_target_msg
          );
          --�󔒏o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => ''
          );
          -- ===============================
          -- �t�@�C���I������(A-8)
          -- ===============================
          output_footer(
            lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF  ( lv_retcode <> cv_status_normal ) THEN
            --�t�@�C����OPEN����Ă���ꍇ�N���[�Y(A-10)
            IF ( UTL_FILE.IS_OPEN(
                   file => gt_f_handle
                 )
               )
            THEN
              UTL_FILE.FCLOSE(
                file => gt_f_handle
              );
            END IF;
            RAISE global_process_expt;
          END IF;
        END IF;
      END LOOP chain_store_loop;
      ----------------------
      --���팏���̐ݒ�
      ----------------------
      gn_normal_cnt := gn_target_cnt;
    --==============================================================
    --  ��������
    --==============================================================
    ELSIF ( iv_run_class = gv_run_class_cd_cancel ) THEN
      -- ==========================================
      -- �̔����уw�b�_TBL�t���O�X�V�i�����j(A-11)
      -- ==========================================
      upd_sale_exp_head_rep(
        iv_inv_cust_code -- ������ڋq�R�[�h
       ,iv_send_date     -- ���M��
       ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add Start */
    --==============================================================
    --  �ΏۊO�X�V����
    --==============================================================
    ELSIF ( iv_run_class = gv_run_class_cd_update ) THEN
      -- ==========================================
      -- �̔����ђ��o�ΏۊO�X�V(A-12)
      -- ==========================================
      upd_no_target(
        lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
       );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
/* 2010/03/16 Ver1.10 Add End   */
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
    errbuf            OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT  VARCHAR2,     --   ���^�[���E�R�[�h    --# �Œ� #
    iv_run_class      IN   VARCHAR2,     --   ���s�敪�F�u0:�쐬�v�u1:�����v�u2:�ΏۊO�X�V�v
    iv_inv_cust_code  IN   VARCHAR2,     --   ������ڋq�R�[�h
/* 2009/04/15 Mod Start */
--    iv_send_date      IN   VARCHAR2      --   ���M��(YYYYMMDD)
    iv_send_date      IN   VARCHAR2,     --   ���M��(YYYYMMDD)
    iv_sales_exp_ptn  IN   VARCHAR2      --   EDI�̔����я����p�^�[��
/* 2009/04/15 Mod End   */
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_run_class     -- ���s�敪�F�u0:�쐬�v�u1:�����v�u2:�ΏۊO�X�V�v
      ,iv_inv_cust_code -- ������ڋq�R�[�h
      ,iv_send_date     -- ���M��(YYYYMMDD)
/* 2009/04/15 Add Start */
      ,iv_sales_exp_ptn -- EDI�̔����я����p�^�[��
/* 2009/04/15 Add End   */
      ,lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF  ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --�G���[���b�Z�[�W������ꍇ
    IF ( lv_errmsg IS NOT NULL ) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => ''
      );
    END IF;
    -- ===============================
    -- �I������(A-12)
    -- ===============================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
               iv_application  => cv_appl_short_name
              ,iv_name         => cv_target_rec_msg
              ,iv_token_name1  => cv_cnt_token
              ,iv_token_value1 => TO_CHAR(gn_target_cnt)
              );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
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
      which  => FND_FILE.OUTPUT
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
      which  => FND_FILE.OUTPUT
     ,buff   => gv_out_msg
    );
    --
   --*------------------------------------------------------------
    --�I�����b�Z�[�W
    IF  ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF  ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF  ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
               iv_application  => cv_appl_short_name
              ,iv_name         => lv_message_code
              );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
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
END XXCOS011A06C;
/
