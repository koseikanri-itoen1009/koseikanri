CREATE OR REPLACE PACKAGE BODY APPS.XXCOS001A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS001A07C (body)
 * Description      : ���o�Ɉꎞ�\�A�[�i�w�b�_�E���׃e�[�u���̃f�[�^�̒��o���s��
 * MD.050           : VD�R�����ʎ���f�[�^���o (MD050_COS_001_A07)
 * Version          : 1.19
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  inv_data_receive       ���o�Ƀf�[�^���o(A-1)
 *  inv_data_compute       ���o�Ƀf�[�^���o(A-2)
 *  inv_data_register      ���o�Ƀf�[�^�o�^(A-3)
 *  dlv_data_register      �[�i�f�[�^�o�^(A-4)
 *  data_update            �R�����ʓ]���σt���O�A�̔����јA�g�ς݃t���O�X�V(A-5)
 *  ins_err_msg            �G���[���o�^����(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   S.Miyakoshi      �V�K�쐬
 *  2009/02/16    1.1   S.Miyakoshi      [COS_062]�J�����ǉ�(VD_RESULTS_FORWARD_FLAG)
 *  2009/02/20    1.2   S.Miyakoshi      [COS_108]���ю҂��}�X�^���擾(���o�Ƀf�[�^�ɂ�����)
 *  2009/02/20    1.3   S.Miyakoshi      �p�����[�^�̃��O�t�@�C���o�͑Ή�
 *  2009/04/15    1.4   N.Maeda          [T1_0576]��[���P�[�X���ɑ΂���`�[�敪�ʏ����̒ǉ�
 *  2009/04/16    1.5   N.Maeda          [T1_0621]�]�ƈ��i���ݏ����̕ύX�A�o�̓P�[�X���̏C��
 *  2009/04/17    1.6   T.Kitajima       [T1_0601]���o�Ƀf�[�^�X�V�����C��
 *  2009/04/22    1.7   T.Kitajima       [T1_0728]���͋敪�Ή�
 *  2009/05/07    1.8   N.Maeda          [T1_0821]VD�R�����ʎ�����e�[�u��.�ΏۃI���W�i���`�[���ݎ��Ή�
 *  2009/05/21    1.9   T.Kitajima       [T1_1039]�̔����јA�g�ςݍX�V���@�C��
 *  2009/05/26    1.9   T.Kitajima       [T1_1177]��������C��
 *  2009/05/29    1.9   T.Kitajima       [T1_1120]org_id�ǉ�
 *  2009/06/02    1.10  N.Maeda          [T1_1192]�[������(�؏�)�̏C��
 *  2009/07/17    1.11  N.Maeda          [T1_1438]���b�N�P�ʂ̕ύX
 *  2009/08/10    1.12  N.Maeda          [0000425]PT�Ή�
 *  2009/09/04    1.13  N.Maeda          [0001211]����Ŋ֘A���ڎ擾����C��
 *  2009/11/27    1.14  K.Atsushiba      [E_�{�ғ�_00147]PT�Ή�
 *  2010/02/03    1.15  N.Maeda          [E_�{�ғ�_01441]���o�Ƀf�[�^�A�g��VD�R��������p�w�b�_�쐬�����C��
 *  2010/03/18    1.16  S.Miyakoshi      [E_�{�ғ�_01907]�ڋq�g�p�ړI�A�ڋq���ݒn����̒��o���ɗL�������ǉ�
 *  2012/04/24    1.17  Y.Horikawa       [E_�{�ғ�_09440]�u����l�����z�v�u�������Ŋz�v�̃}�b�s���O�s���̏C��
 *  2014/10/16    1.18  Y.Enokido        [E_�{�ғ�_09378]�[�i�҂̗L���`�F�b�N���s��
 *  2014/11/27    1.19  K.Nakatsu        [E_�{�ғ�_12599]�ėp�G���[���X�g�e�[�u���ւ̏o�͒ǉ�
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt,-20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���b�N�G���[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- �N�C�b�N�R�[�h�擾�G���[
  lookup_types_expt EXCEPTION;
  insert_err_expt   EXCEPTION;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  global_ins_key_expt       EXCEPTION;                        -- �ėp�G���[���X�g�o�^��O�isubmain�n���h�����O�p�j 
  global_bulk_ins_expt      EXCEPTION;                        -- �ėp�G���[���X�g�o�^��O
  PRAGMA EXCEPTION_INIT(global_bulk_ins_expt, -24381);
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCOS001A07C';           -- �p�b�P�[�W��
--
  cv_application     CONSTANT VARCHAR2(5)   := 'XXCOS';                  -- �A�v���P�[�V������
--
  -- �v���t�@�C��
  -- XXCOS:MAX���t
  cv_prf_max_date    CONSTANT VARCHAR2(50)  := 'XXCOS1_MAX_DATE';
  -- GL��v����ID
  cv_prf_bks_id      CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
  -- MO�c�ƒP��
  cv_pf_org_id       CONSTANT VARCHAR2(30)  := 'ORG_ID';              -- MO:�c�ƒP��
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
--
  -- �G���[�R�[�h
  cv_msg_lock        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';       -- ���b�N�G���[
  cv_msg_nodata      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';       -- �Ώۃf�[�^�����G���[
  cv_msg_pro         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';       -- �v���t�@�C���擾�G���[
  cv_msg_add         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00010';       -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_update      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00011';       -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_get         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';       -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_max_date    CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00056';       -- XXCOS:MAX���t
  cv_msg_lookup      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00066';       -- �Q�ƃR�[�h�}�X�^
  cv_msg_target      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';       -- �Ώی������b�Z�[�W
  cv_msg_success     CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';       -- �����������b�Z�[�W
  cv_msg_normal      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';       -- ����I�����b�Z�[�W
  cv_msg_warn        CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90005';       -- �x���I�����b�Z�[�W
  cv_msg_error       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';       -- �G���[�I���S���[���o�b�N���b�Z�[�W
--****************************** 2014/11/27 1.19 K.Nakatsu DEL START ******************************--
--  cv_msg_parameter   CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';       -- �R���J�����g���̓p�����[�^�Ȃ�
--****************************** 2014/11/27 1.19 K.Nakatsu DEL  END  ******************************--
-- *************** 2009/09/04 1.13 N.Maeda MOD START *****************************--
--  cv_msg_tax_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10352';       -- �Q�ƃR�[�h�}�X�^�y��AR����Ń}�X�^
  cv_msg_tax_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00190';       -- �����VIEW
-- *************** 2009/09/04 1.13 N.Maeda MOD  END  *****************************--
  cv_msg_inv_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10353';       -- ���o�Ɉꎞ�\
  cv_msg_vdh_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10354';       -- VD�R�����ʎ���w�b�_�e�[�u��
  cv_msg_vdl_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10355';       -- VD�R�����ʎ�����׃e�[�u��
  cv_msg_dlv_table   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10356';       -- �[�i�w�b�_�e�[�u���y�є[�i���׃e�[�u��
  cv_msg_dlv_h_table CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10357';       -- �[�i�w�b�_�e�[�u��
  cv_msg_inv_cnt     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10358';       -- ���o�ɏ�񒊏o����
  cv_msg_dlv_cnt     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00141';       -- �[�i�w�b�_��񒊏o����
  cv_msg_date        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10360';       -- �Ɩ��������擾�G���[
  cv_msg_bks_id      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10361';       -- GL��v����ID
  cv_msg_qck_error   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10362';       -- �N�C�b�N�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_invo_type   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10363';       -- �`�[�敪
  cv_msg_dlv_cnt_l   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10364';       -- �[�i���׏�񒊏o����
  cv_msg_h_nor_cnt   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10365';       -- �w�b�_��������
  cv_msg_l_nor_cnt   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10366';       -- ���א�������
  cv_msg_input       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10043';       -- ���͋敪
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
  cv_msg_mo          CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';       -- MO:�c�ƒP��
  cv_data_loc        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00184';     -- �Ώۃf�[�^���b�N��
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
--****************************** 2014/10/16 1.18 MOD START ******************************
  cv_empl_effect     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-10367';       -- �[�i�҃R�[�h�L�����`�F�b�N
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  cv_msg_cus_code    CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-00053';      -- �ڋq�R�[�h
  cv_msg_dlv         CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00080';      -- �[�i�҃R�[�h
  cv_msg_hht_inv_no  CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-00131';      -- HHT�`�[No.
  cv_msg_dlv_date    CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-10169';      -- �[�i��
  cv_msg_gen_errlst  CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-00213';      -- ���b�Z�[�W�p������
  cv_msg_err_out_flg CONSTANT VARCHAR2(30)  := 'APP-XXCOS1-10260';      -- �ėp�G���[���X�g�o�̓t���O
  cv_tkn_err_out_flg CONSTANT VARCHAR2(30)  := 'GEN_ERR_OUT_FLAG';      -- �ėp�G���[���X�g�o�̓t���O
  cv_status_err_ins  CONSTANT VARCHAR2(1)   := '3';                     -- ���^�[���R�[�h
  cv_key_data        CONSTANT VARCHAR2(20)  := 'KEY_DATA';              -- �ҏW���ꂽ�L�[���
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
  -- �g�[�N��
  cv_tkn_table       CONSTANT VARCHAR2(20)  := 'TABLE_NAME';             -- �e�[�u����
  cv_tkn_tab         CONSTANT VARCHAR2(20)  := 'TABLE';                  -- �e�[�u����
  cv_tkn_colmun      CONSTANT VARCHAR2(20)  := 'COLMUN';                 -- ���ږ�
  cv_tkn_type        CONSTANT VARCHAR2(20)  := 'TYPE';                   -- �N�C�b�N�R�[�h�^�C�v
  cv_tkn_key         CONSTANT VARCHAR2(20)  := 'KEY_DATA';               -- �L�[�f�[�^
  cv_tkn_count       CONSTANT VARCHAR2(20)  := 'COUNT';                  -- ����
  cv_tkn_profile     CONSTANT VARCHAR2(20)  := 'PROFILE';                -- �v���t�@�C����
  cv_tkn_yes         CONSTANT VARCHAR2(1)   := 'Y';                      -- ����:YES
  cv_tkn_no          CONSTANT VARCHAR2(1)   := 'N';                      -- ����:NO
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD START ******************************
  cv_tkn_a           CONSTANT VARCHAR2(1)   := 'A';                      -- ����:A(�L��)
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD END   ******************************
  cv_tkn_out         CONSTANT VARCHAR2(3)   := 'OUT';                    -- �o�ɑ�
  cv_tkn_in          CONSTANT VARCHAR2(2)   := 'IN';                     -- ���ɑ�
  cv_default         CONSTANT VARCHAR2(1)   := '0';                      -- �����l
  cv_one             CONSTANT VARCHAR2(1)   := '1';                      -- ����:1
  cv_input_class     CONSTANT VARCHAR2(1)   := '5';                      -- �e�[�u���E���b�N����
  cv_tkn_down        CONSTANT VARCHAR2(20)  := 'DOWN';                   -- �؎̂�
  cv_tkn_up          CONSTANT VARCHAR2(20)  := 'UP';                     -- �؏グ
  cv_tkn_nearest     CONSTANT VARCHAR2(20)  := 'NEAREST';                -- �l�̌ܓ�
  cv_tkn_bill_to     CONSTANT VARCHAR2(20)  := 'BILL_TO';                -- BILL_TO
--******************** 2009/07/17 Ver1.11  N.Maeda ADD START ******************************************
  cv_tkn_order_number  CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- �󒍔ԍ�
  cv_digestion_ln_number CONSTANT VARCHAR2(20)  := 'DIGESTION_LN_NUMBER';  -- �}��
  cv_invoice_no      CONSTANT VARCHAR2(20)  := 'INVOICE_NO';           -- HHT�`�[�ԍ�
--******************** 2009/07/17 Ver1.11  N.Maeda ADD  END  ******************************************
--****************************** 2014/10/16 1.18 MOD START ******************************
  cv_hht_invoice_no  CONSTANT VARCHAR2(20)  := 'HHT_INVOICE_NO';       -- HHT�`�[No.
  cv_customer_number CONSTANT VARCHAR2(20)  := 'CUSTOMER_NUMBER';      -- �ڋq�R�[�h
  cv_dlv_by_code     CONSTANT VARCHAR2(20)  := 'DLV_BY_CODE';          -- �[�i�҃R�[�h
  cv_dlv_date        CONSTANT VARCHAR2(20)  := 'DLV_DATE';             -- �[�i��
--****************************** 2014/10/16 1.18 MOD END   ******************************
--
  -- �N�C�b�N�R�[�h�^�C�v
  cv_qck_typ_tax     CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';    -- ����ŋ敪
  cv_qck_invo_type   CONSTANT VARCHAR2(30)  := 'XXCOS1_INVOICE_TYPE';             -- �`�[�敪
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  cv_qck_input_type  CONSTANT VARCHAR2(30)  := 'XXCOS1_VD_COL_INPUT_CLASS';       -- ���͋敪
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
  ct_user_lang       CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
--
  --�t�H�[�}�b�g
  cv_fmt_date        CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';                      -- DATE�`��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ����ŗ��i�[�p�ϐ�
  TYPE g_rec_tax_rate IS RECORD
    (
      rate                ar_vat_tax_all_b.tax_rate%TYPE,                     -- ����ŗ�
      code                ar_vat_tax_all_b.tax_code%TYPE,                     -- ����ŃR�[�h
      tax_class           fnd_lookup_values.attribute3%TYPE                   -- ����ŋ敪
-- *************** 2009/09/04 1.13 N.Maeda ADD START *****************************--
      ,qck_start_date_active  fnd_lookup_values.start_date_active%TYPE        -- �N�C�b�N�R�[�h�K�p�J�n��
      ,qck_end_date_active    fnd_lookup_values.end_date_active%TYPE          -- �N�C�b�N�R�[�h�K�p�I����
-- *************** 2009/09/04 1.13 N.Maeda ADD  END  *****************************--
    );
  TYPE g_tab_tax_rate IS TABLE OF g_rec_tax_rate INDEX BY PLS_INTEGER;
--
  -- �`�[�敪�i�[�p�ϐ�
  TYPE g_rec_qck_invoice_type IS RECORD
    (
      invoice_type        xxcoi_hht_inv_transactions.invoice_type%TYPE,       -- �`�[�敪
      form                VARCHAR(3),                                         -- �`�[�敪�ɂ��`��
      change              VARCHAR(1)                                          -- ���ʉ��H����
    );
  TYPE g_tab_qck_invoice_type IS TABLE OF g_rec_qck_invoice_type INDEX BY PLS_INTEGER;
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  -- ���͋敪�i�[�p�ϐ�
  TYPE g_rec_qck_input_type IS RECORD
    (
      slip_class          VARCHAR(1),                                         -- �`�[�敪
      input_class         VARCHAR(1)                                          -- ���͋敪
    );
  TYPE g_tab_qck_input_type IS TABLE OF g_rec_qck_input_type INDEX BY PLS_INTEGER;
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
  TYPE g_get_inv_data_type IS RECORD
    (
      row_id              ROWID                                               -- �sID
     ,order_no_hht        xxcos_dlv_headers.order_no_hht%TYPE                 -- ��No.(HHT)
     ,digestion_ln_number xxcos_dlv_headers.digestion_ln_number%TYPE          -- �}��
     ,hht_invoice_no      xxcos_dlv_headers.hht_invoice_no%TYPE               -- �`�[No.HHT
--****************************** 2014/10/16 1.18 MOD START ******************************
     ,customer_number     xxcos_dlv_headers.customer_number%TYPE              -- �ڋq�R�[�h
     ,dlv_by_code         xxcos_dlv_headers.dlv_by_code%TYPE                  -- �[�i�҃R�[�h
     ,dlv_date            xxcos_dlv_headers.dlv_date%TYPE                     -- �[�i��
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
     ,base_code           xxcos_dlv_headers.base_code%TYPE                    -- ���_�R�[�h
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
    );
  TYPE g_tab_inv_data_type IS TABLE OF g_get_inv_data_type INDEX BY PLS_INTEGER;
--
  TYPE g_get_lines_type IS TABLE OF xxcos_vd_column_lines%ROWTYPE
  INDEX BY PLS_INTEGER;
--  TYPE g_get_lines_tab IS TABLE OF g_get_lines_type INDEX BY PLS_INTEGER;
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
--
  -- ���o�Ɉꎞ�\�f�[�^�i�[�p�ϐ�
  TYPE g_rec_inv_data IS RECORD
    (
      base_code           xxcoi_hht_inv_transactions.base_code%TYPE,                  -- ���_�R�[�h
      employee_num        xxcoi_hht_inv_transactions.employee_num%TYPE,               -- �c�ƈ��R�[�h
      invoice_no          xxcoi_hht_inv_transactions.invoice_no%TYPE,                 -- �`�[No.
      item_code           xxcoi_hht_inv_transactions.item_code%TYPE,                  -- �i�ڃR�[�h�i�i���R�[�h�j
      case_quant          xxcoi_hht_inv_transactions.case_quantity%TYPE,              -- �P�[�X��
      case_in_quant       xxcoi_hht_inv_transactions.case_in_quantity%TYPE,           -- ����
      quantity            xxcoi_hht_inv_transactions.quantity%TYPE,                   -- �{��
      invoice_type        xxcoi_hht_inv_transactions.invoice_type%TYPE,               -- �`�[�敪
      outside_code        xxcoi_hht_inv_transactions.outside_code%TYPE,               -- �o�ɑ��R�[�h
      inside_code         xxcoi_hht_inv_transactions.inside_code%TYPE,                -- ���ɑ��R�[�h
      invoice_date        xxcoi_hht_inv_transactions.invoice_date%TYPE,               -- �`�[���t
      column_no           xxcoi_hht_inv_transactions.column_no%TYPE,                  -- �R����No.
      unit_price          xxcoi_hht_inv_transactions.unit_price%TYPE,                 -- �P��
      hot_cold_div        xxcoi_hht_inv_transactions.hot_cold_div%TYPE,               -- H/C
      total_quantity      xxcoi_hht_inv_transactions.total_quantity%TYPE,             -- ���{��
      item_id             xxcoi_hht_inv_transactions.inventory_item_id%TYPE,          -- �i��ID
      primary_code        xxcoi_hht_inv_transactions.primary_uom_code%TYPE,           -- ��P��
      out_bus_low_type    xxcoi_hht_inv_transactions.outside_business_low_type%TYPE,  -- �o�ɑ��Ƒԋ敪
      in_bus_low_type     xxcoi_hht_inv_transactions.inside_business_low_type%TYPE,   -- ���ɑ��Ƒԋ敪
      out_cus_code        xxcoi_hht_inv_transactions.outside_cust_code%TYPE,          -- �o�ɑ��ڋq�R�[�h
      in_cus_code         xxcoi_hht_inv_transactions.inside_cust_code%TYPE,           -- ���ɑ��ڋq�R�[�h
      tax_div             xxcmm_cust_accounts.tax_div%TYPE,                           -- ����ŋ敪
      tax_round_rule      hz_cust_site_uses_all.tax_rounding_rule%TYPE,               -- �ŋ��|�[������
      inv_price           xxcoi_mst_vd_column.price%TYPE,                             -- �P���FVD�R�����}�X�^���
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
--      perform_code        xxcos_vd_column_headers.performance_by_code%TYPE            -- ���ю҃R�[�h
      perform_code        xxcos_vd_column_headers.performance_by_code%TYPE,           -- ���ю҃R�[�h
      transaction_id      xxcoi_hht_inv_transactions.transaction_id%TYPE              -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
    );
  TYPE g_tab_inv_data IS TABLE OF g_rec_inv_data INDEX BY PLS_INTEGER;
  
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
  TYPE g_tab_set_clm_headers  IS TABLE OF      xxcos_vd_column_headers%ROWTYPE    INDEX BY PLS_INTEGER;
--
  TYPE g_rec_clm_headers IS RECORD
    (
     order_no_hht                    xxcos_vd_column_headers.order_no_hht%TYPE,            -- ��No.(HHT)
     digestion_ln_number             xxcos_vd_column_headers.digestion_ln_number%TYPE,     -- �}��
     order_no_ebs                    xxcos_vd_column_headers.order_no_ebs%TYPE,            -- ��No.(EBS)
     base_code                       xxcos_vd_column_headers.base_code%TYPE,               -- ���_�R�[�h
     performance_by_code             xxcos_vd_column_headers.performance_by_code%TYPE,     -- ���ю҃R�[�h
     dlv_by_code                     xxcos_vd_column_headers.dlv_by_code%TYPE,             -- �[�i�҃R�[�h
     hht_invoice_no                  xxcos_vd_column_headers.hht_invoice_no%TYPE,          -- HHT�`�[No.
     dlv_date                        xxcos_vd_column_headers.dlv_date%TYPE,                -- �[�i��
     inspect_date                    xxcos_vd_column_headers.inspect_date%TYPE,            -- ������
     sales_classification            xxcos_vd_column_headers.sales_classification%TYPE,    -- ���㕪�ދ敪
     sales_invoice                   xxcos_vd_column_headers.sales_invoice%TYPE,           -- ����`�[�敪
     card_sale_class                 xxcos_vd_column_headers.card_sale_class%TYPE,         -- �J�[�h���敪
     dlv_time                        xxcos_vd_column_headers.dlv_time%TYPE,                -- ����
     change_out_time_100             xxcos_vd_column_headers.change_out_time_100%TYPE,     -- ��K�؂ꎞ��100�~
     change_out_time_10              xxcos_vd_column_headers.change_out_time_10%TYPE,      -- ��K�؂ꎞ��10�~
     customer_number                 xxcos_vd_column_headers.customer_number%TYPE,         -- �ڋq�R�[�h
     dlv_form                        xxcos_vd_column_headers.dlv_form%TYPE,-- �[�i�`��
     system_class                    xxcos_vd_column_headers.system_class%TYPE,            -- �Ƒԋ敪
     invoice_type                    xxcos_vd_column_headers.invoice_type%TYPE,-- �`�[�敪
     input_class                     xxcos_vd_column_headers.input_class%TYPE,             -- ���͋敪
     consumption_tax_class           xxcos_vd_column_headers.consumption_tax_class%TYPE,   -- ����ŋ敪
     total_amount                    xxcos_vd_column_headers.total_amount%TYPE,            -- ���v���z
     sale_discount_amount            xxcos_vd_column_headers.sale_discount_amount%TYPE,    -- ����l���z
     sales_consumption_tax           xxcos_vd_column_headers.sales_consumption_tax%TYPE,   -- �������Ŋz
     tax_include                     xxcos_vd_column_headers.tax_include%TYPE,             -- �ō����z
     keep_in_code                    xxcos_vd_column_headers.keep_in_code%TYPE,            -- �a����R�[�h
     department_screen_class         xxcos_vd_column_headers.department_screen_class%TYPE, -- �S�ݓX��ʎ��
     digestion_vd_rate_maked_date    xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE,-- ����VD�|���쐬�N����
     red_black_flag                  xxcos_vd_column_headers.red_black_flag%TYPE,          -- �ԍ��t���O
     forward_flag                    xxcos_vd_column_headers.forward_flag%TYPE,-- �A�g�t���O
     forward_date                    xxcos_vd_column_headers.forward_date%TYPE,-- �A�g���t
     vd_results_forward_flag         xxcos_vd_column_headers.vd_results_forward_flag%TYPE,-- �x���_�[�i���я��A�g�σt���O
     cancel_correct_class            xxcos_vd_column_headers.cancel_correct_class%TYPE,     -- ����E�����敪
     created_by                      xxcos_vd_column_headers.created_by%TYPE,-- �쐬��
     creation_date                   xxcos_vd_column_headers.creation_date%TYPE,-- �쐬��
     last_updated_by                 xxcos_vd_column_headers.last_updated_by%TYPE,-- �ŏI�X�V��
     last_update_date                xxcos_vd_column_headers.last_update_date%TYPE,-- �ŏI�X�V��
     last_update_login               xxcos_vd_column_headers.last_update_login%TYPE,-- �ŏI�X�V���O�C��
     request_id                      xxcos_vd_column_headers.request_id%TYPE,-- �v��ID
     program_application_id          xxcos_vd_column_headers.program_application_id%TYPE,-- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     program_id                      xxcos_vd_column_headers.program_id%TYPE,-- �R���J�����g�E�v���O����ID
     program_update_date             xxcos_vd_column_headers.program_update_date%TYPE,-- �v���O�����X�V��
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
     h_rowid                         rowid                                                 -- ���R�[�hID
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************

    );
  TYPE g_tab_clm_headers IS TABLE OF g_rec_clm_headers INDEX BY PLS_INTEGER;
--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--
  -- VD�R�����ʎ���w�b�_�e�[�u���o�^�p�ϐ�
  TYPE g_tab_order_noh_hht         IS TABLE OF xxcos_vd_column_headers.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.(HHT)
  TYPE g_tab_base_code             IS TABLE OF xxcos_vd_column_headers.base_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���_�R�[�h
  TYPE g_tab_performance_by_code   IS TABLE OF xxcos_vd_column_headers.performance_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- ���ю҃R�[�h
  TYPE g_tab_dlv_by_code           IS TABLE OF xxcos_vd_column_headers.dlv_by_code%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i�҃R�[�h
  TYPE g_tab_hht_invoice_no        IS TABLE OF xxcos_vd_column_headers.hht_invoice_no%TYPE
    INDEX BY PLS_INTEGER;   -- HHT�`�[No.
  TYPE g_tab_dlv_date              IS TABLE OF xxcos_vd_column_headers.dlv_date%TYPE
    INDEX BY PLS_INTEGER;   -- �[�i��
  TYPE g_tab_inspect_date          IS TABLE OF xxcos_vd_column_headers.inspect_date%TYPE
    INDEX BY PLS_INTEGER;   -- ������
  TYPE g_tab_customer_number       IS TABLE OF xxcos_vd_column_headers.customer_number%TYPE
    INDEX BY PLS_INTEGER;   -- �ڋq�R�[�h
  TYPE g_tab_system_class          IS TABLE OF xxcos_vd_column_headers.system_class%TYPE
    INDEX BY PLS_INTEGER;   -- �Ƒԋ敪
  TYPE g_tab_invoice_type          IS TABLE OF xxcos_vd_column_headers.invoice_type%TYPE
    INDEX BY PLS_INTEGER;   -- �`�[�敪
  TYPE g_tab_consumption_tax_class IS TABLE OF xxcos_vd_column_headers.consumption_tax_class%TYPE
    INDEX BY PLS_INTEGER;   -- ����ŋ敪
  TYPE g_tab_total_amount          IS TABLE OF xxcos_vd_column_headers.total_amount%TYPE
    INDEX BY PLS_INTEGER;   -- ���v���z
  TYPE g_tab_sales_consumption_tax IS TABLE OF xxcos_vd_column_headers.sales_consumption_tax%TYPE
    INDEX BY PLS_INTEGER;   -- �������Ŋz
  TYPE g_tab_tax_include           IS TABLE OF xxcos_vd_column_headers.tax_include%TYPE
    INDEX BY PLS_INTEGER;   -- �ō����z
  TYPE g_tab_red_black_flag        IS TABLE OF xxcos_vd_column_headers.red_black_flag%TYPE
    INDEX BY PLS_INTEGER;   -- �ԍ��t���O
  TYPE g_tab_cancel_correct_class  IS TABLE OF xxcos_vd_column_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;   -- ����E�����敪
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  TYPE g_tab_gt_input_class        IS TABLE OF xxcos_vd_column_headers.input_class%TYPE
    INDEX BY PLS_INTEGER;   -- ���͋敪
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
  -- VD�R�����ʎ�����׃e�[�u���o�^�p�ϐ�
  TYPE g_tab_order_nol_hht         IS TABLE OF xxcos_vd_column_lines.order_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- ��No.(HHT)
  TYPE g_tab_line_no_hht           IS TABLE OF xxcos_vd_column_lines.line_no_hht%TYPE
    INDEX BY PLS_INTEGER;   -- �sNo.(HHT)
  TYPE g_tab_item_code_self        IS TABLE OF xxcos_vd_column_lines.item_code_self%TYPE
    INDEX BY PLS_INTEGER;   -- �i���R�[�h(����)
  TYPE g_tab_content               IS TABLE OF xxcos_vd_column_lines.content%TYPE
    INDEX BY PLS_INTEGER;   -- ����
  TYPE g_tab_inventory_item_id     IS TABLE OF xxcos_vd_column_lines.inventory_item_id%TYPE
    INDEX BY PLS_INTEGER;   -- �i��ID
  TYPE g_tab_standard_unit         IS TABLE OF xxcos_vd_column_lines.standard_unit%TYPE
    INDEX BY PLS_INTEGER;   -- ��P��
  TYPE g_tab_case_number           IS TABLE OF xxcos_vd_column_lines.case_number%TYPE
    INDEX BY PLS_INTEGER;   -- �P�[�X��
  TYPE g_tab_quantity              IS TABLE OF xxcos_vd_column_lines.quantity%TYPE
    INDEX BY PLS_INTEGER;   -- ����
  TYPE g_tab_wholesale_unit_ploce  IS TABLE OF xxcos_vd_column_lines.wholesale_unit_ploce%TYPE
    INDEX BY PLS_INTEGER;   -- ���P��
  TYPE g_tab_column_no             IS TABLE OF xxcos_vd_column_lines.column_no%TYPE
    INDEX BY PLS_INTEGER;   -- �R����No.
  TYPE g_tab_h_and_c               IS TABLE OF xxcos_vd_column_lines.h_and_c%TYPE
    INDEX BY PLS_INTEGER;   -- H/C
  TYPE g_tab_replenish_number      IS TABLE OF xxcos_vd_column_lines.replenish_number%TYPE
    INDEX BY PLS_INTEGER;   -- ��[��
--
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
  TYPE g_tab_transaction_id        IS TABLE OF xxcoi_hht_inv_transactions.transaction_id%TYPE
    INDEX BY PLS_INTEGER;   -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
  -- VD�R�����ʎ���w�b�_�e�[�u���o�^�p�ϐ�
  TYPE g_tab_digestion_ln_number         IS TABLE OF xxcos_vd_column_headers.digestion_ln_number%TYPE
    INDEX BY PLS_INTEGER;                --�}��
  TYPE g_tab_order_no_ebs                IS TABLE OF xxcos_vd_column_headers.order_no_ebs%TYPE
    INDEX BY PLS_INTEGER;                -- ��No.(EBS)
  TYPE g_tab_sales_classification        IS TABLE OF xxcos_vd_column_headers.sales_classification%TYPE
    INDEX BY PLS_INTEGER;                -- ���㕪�ދ敪
  TYPE g_tab_sales_invoice               IS TABLE OF xxcos_vd_column_headers.sales_invoice%TYPE
    INDEX BY PLS_INTEGER;                -- ����`�[�敪
  TYPE g_tab_card_sale_class             IS TABLE OF xxcos_vd_column_headers.card_sale_class%TYPE
    INDEX BY PLS_INTEGER;                -- �J�[�h���敪
  TYPE g_tab_dlv_time                    IS TABLE OF xxcos_vd_column_headers.dlv_time%TYPE
    INDEX BY PLS_INTEGER;                -- ����
  TYPE g_tab_change_out_time_100         IS TABLE OF xxcos_vd_column_headers.change_out_time_100%TYPE
    INDEX BY PLS_INTEGER;                -- ��K�؂ꎞ��100�~
  TYPE g_tab_change_out_time_10          IS TABLE OF xxcos_vd_column_headers.change_out_time_10%TYPE
    INDEX BY PLS_INTEGER;                -- ��K�؂ꎞ��10�~
  TYPE g_tab_dlv_form                    IS TABLE OF xxcos_vd_column_headers.dlv_form%TYPE
    INDEX BY PLS_INTEGER;                -- �[�i�`��
  TYPE g_tab_sale_discount_amount        IS TABLE OF xxcos_vd_column_headers.sale_discount_amount%TYPE
    INDEX BY PLS_INTEGER;                -- ����l���z
  TYPE g_tab_keep_in_code                IS TABLE OF xxcos_vd_column_headers.keep_in_code%TYPE
    INDEX BY PLS_INTEGER;                -- �a����R�[�h
  TYPE g_tab_department_screen_class     IS TABLE OF xxcos_vd_column_headers.department_screen_class%TYPE
    INDEX BY PLS_INTEGER;                -- �S�ݓX��ʎ��
  TYPE g_tab_digestion_vd_r_mak_d        IS TABLE OF xxcos_vd_column_headers.digestion_vd_rate_maked_date%TYPE--
    INDEX BY PLS_INTEGER;                -- ����VD�|���쐬�N����
  TYPE g_tab_forward_flag                IS TABLE OF xxcos_vd_column_headers.forward_flag%TYPE
    INDEX BY PLS_INTEGER;                -- �A�g�t���O
  TYPE g_tab_forward_date                IS TABLE OF xxcos_vd_column_headers.forward_date%TYPE
    INDEX BY PLS_INTEGER;                -- �A�g���t
  TYPE g_tab_vd_results_forward_f        IS TABLE OF xxcos_vd_column_headers.vd_results_forward_flag%TYPE--
    INDEX BY PLS_INTEGER;                 -- �x���_�[�i���я��A�g�σt���O
  TYPE g_tab_created_by                  IS TABLE OF xxcos_vd_column_headers.created_by%TYPE
    INDEX BY PLS_INTEGER;                -- �쐬��
  TYPE g_tab_creation_date               IS TABLE OF xxcos_vd_column_headers.creation_date%TYPE
    INDEX BY PLS_INTEGER;                -- �쐬��
  TYPE g_tab_last_updated_by             IS TABLE OF xxcos_vd_column_headers.last_updated_by%TYPE
    INDEX BY PLS_INTEGER;                -- �ŏI�X�V��
  TYPE g_tab_last_update_date            IS TABLE OF xxcos_vd_column_headers.last_update_date%TYPE 
    INDEX BY PLS_INTEGER;                -- �ŏI�X�V��
  TYPE g_tab_last_update_login           IS TABLE OF xxcos_vd_column_headers.last_update_login%TYPE
    INDEX BY PLS_INTEGER;                -- �ŏI�X�V���O�C��
  TYPE g_tab_request_id                  IS TABLE OF xxcos_vd_column_headers.request_id%TYPE 
    INDEX BY PLS_INTEGER;                -- �v��ID
  TYPE g_tab_program_appli_id            IS TABLE OF xxcos_vd_column_headers.program_application_id%TYPE
    INDEX BY PLS_INTEGER;                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  TYPE g_tab_program_id                  IS TABLE OF xxcos_vd_column_headers.program_id%TYPE
    INDEX BY PLS_INTEGER;                -- �R���J�����g�E�v���O����ID
  TYPE g_tab_program_update_date         IS TABLE OF xxcos_vd_column_headers.program_update_date%TYPE
    INDEX BY PLS_INTEGER;                -- �v���O�����X�V��
  --VD�R�����ʎ�����X�V�p�ϐ�
  TYPE g_tab_vd_row_id                   IS TABLE OF ROWID
    INDEX BY PLS_INTEGER;                -- �sID
  TYPE g_tab_vd_can_cor_class            IS TABLE OF xxcos_vd_column_headers.cancel_correct_class%TYPE
    INDEX BY PLS_INTEGER;                -- ��������敪
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  TYPE g_err_key_ttype                   IS TABLE OF xxcos_gen_err_list%ROWTYPE
    INDEX BY BINARY_INTEGER;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- VD�R�����ʎ���w�b�_�e�[�u���o�^�f�[�^
  gt_order_noh_hht      g_tab_order_noh_hht;            -- ��No.(HHT)
  gt_base_code          g_tab_base_code;                -- ���_�R�[�h
  gt_perform_code       g_tab_performance_by_code;      -- ���ю҃R�[�h
  gt_dlv_code           g_tab_dlv_by_code;              -- �[�i�҃R�[�h
  gt_invoice_no         g_tab_hht_invoice_no;           -- HHT�`�[No.
  gt_dlv_date           g_tab_dlv_date;                 -- �[�i��
  gt_inspect_date       g_tab_inspect_date;             -- ������
  gt_cus_number         g_tab_customer_number;          -- �ڋq�R�[�h
  gt_system_class       g_tab_system_class;             -- �Ƒԋ敪
  gt_invoice_type       g_tab_invoice_type;             -- �`�[�敪
  gt_tax_class          g_tab_consumption_tax_class;    -- ����ŋ敪
  gt_total_amount       g_tab_total_amount;             -- ���v���z
  gt_sales_tax          g_tab_sales_consumption_tax;    -- �������Ŋz
  gt_tax_include        g_tab_tax_include;              -- �ō����z
  gt_red_black_flag     g_tab_red_black_flag;           -- �ԍ��t���O
  gt_cancel_correct     g_tab_cancel_correct_class;     -- ����E�����敪
--
  -- VD�R�����ʎ�����׃e�[�u���o�^�f�[�^
  gt_order_nol_hht      g_tab_order_nol_hht;            -- ��No.(HHT)
  gt_line_no_hht        g_tab_line_no_hht;              -- �sNo.(HHT)
  gt_item_code_self     g_tab_item_code_self;           -- �i���R�[�h(����)
  gt_content            g_tab_content;                  -- ����
  gt_item_id            g_tab_inventory_item_id;        -- �i��ID
  gt_standard_unit      g_tab_standard_unit;            -- ��P��
  gt_case_number        g_tab_case_number;              -- �P�[�X��
  gt_quantity           g_tab_quantity;                 -- ����
  gt_wholesale          g_tab_wholesale_unit_ploce;     -- ���P��
  gt_column_no          g_tab_column_no;                -- �R����No.
  gt_h_and_c            g_tab_h_and_c;                  -- H/C
  gt_replenish_num      g_tab_replenish_number;         -- ��[��
--
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
  gt_transaction_id     g_tab_transaction_id;           --  ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
  gt_input_class        g_tab_gt_input_class;           --  ���͋敪
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ***************************************--
  gt_dev_set_order_noh_hht          g_tab_order_noh_hht;            -- ��No.(HHT)
  gt_dev_set_digestion_ln           g_tab_digestion_ln_number;      -- �}��
  gt_dev_set_order_no_ebs           g_tab_order_no_ebs;             -- ��No.(EBS)
  gt_dev_set_base_code              g_tab_base_code;                -- ���_�R�[�h
  gt_dev_set_perform_code           g_tab_performance_by_code;      -- ���ю҃R�[�h
  gt_dev_set_dlv_code               g_tab_dlv_by_code;              -- �[�i�҃R�[�h
  gt_dev_set_invoice_no             g_tab_hht_invoice_no;           -- HHT�`�[No.
  gt_dev_set_dlv_date               g_tab_dlv_date;                 -- �[�i��
  gt_dev_set_inspect_date           g_tab_inspect_date;             -- ������
  gt_dev_set_sales_classif          g_tab_sales_classification;     -- ���㕪�ދ敪
  gt_dev_set_sales_invoice          g_tab_sales_invoice;            -- ����`�[�敪
  gt_dev_set_card_sale_class        g_tab_card_sale_class;          -- �J�[�h���敪
  gt_dev_set_dlv_time               g_tab_dlv_time;                 -- ����
  gt_dev_set_out_time_100           g_tab_change_out_time_100;      -- ��K�؂ꎞ��100�~
  gt_dev_set_out_time_10            g_tab_change_out_time_10;       -- ��K�؂ꎞ��10�~
  gt_dev_set_cus_number             g_tab_customer_number;          -- �ڋq�R�[�h
  gt_dev_set_dlv_form               g_tab_dlv_form;                 -- �[�i�`��
  gt_dev_set_system_class           g_tab_system_class;             -- �Ƒԋ敪
  gt_dev_set_invoice_type           g_tab_invoice_type;             -- �`�[�敪
  gt_dev_set_input_class            g_tab_gt_input_class;           --  ���͋敪
  gt_dev_set_tax_class              g_tab_consumption_tax_class;    -- ����ŋ敪
  gt_dev_set_total_amount           g_tab_total_amount;             -- ���v���z
  gt_dev_set_sales_tax              g_tab_sales_consumption_tax;    -- �������Ŋz
  gt_dev_set_sale_discount_a        g_tab_sale_discount_amount;     -- �ō��l���z
  gt_dev_set_tax_include            g_tab_tax_include;              -- �ō����z
  gt_dev_set_keep_in_code           g_tab_keep_in_code;             -- �a����R�[�h
  gt_dev_set_depart_sc_clas         g_tab_department_screen_class;  -- �S�ݓX��ʎ��
  gt_dev_set_dig_vd_r_mak_d         g_tab_digestion_vd_r_mak_d;-- ����VD�|���쐬�N����
  gt_dev_set_red_black_flag         g_tab_red_black_flag;           -- �ԍ��t���O
  gt_dev_set_forward_flag           g_tab_forward_flag;             -- �A�g�t���O
  gt_dev_set_forward_date           g_tab_forward_date;             -- �A�g���t
  gt_dev_set_vd_results_for_f       g_tab_vd_results_forward_f;  -- �x���_�[�i���я��A�g�σt���O
  gt_dev_set_cancel_correct         g_tab_cancel_correct_class;     -- ����E�����敪
  gt_dev_set_created_by             g_tab_created_by;               -- �쐬��
  gt_dev_set_creation_date          g_tab_creation_date;            -- �쐬��
  gt_dev_set_last_updated_by        g_tab_last_updated_by;          -- �ŏI�X�V��
  gt_dev_set_last_update_date       g_tab_last_update_date;         -- �ŏI�X�V��
  gt_dev_set_last_update_logi       g_tab_last_update_login;        -- �ŏI�X�V���O�C��
  gt_dev_set_request_id             g_tab_request_id;               -- �v��ID
  gt_dev_set_program_appli_id       g_tab_program_appli_id;         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  gt_dev_set_program_id             g_tab_program_id;               -- �R���J�����g�E�v���O����ID
  gt_dev_set_program_update_d       g_tab_program_update_date;      -- �v���O�����X�V��
  gt_vd_row_id                      g_tab_vd_row_id;                 -- VD�J�����ʎ�����-�sID
  gt_vd_can_cor_class               g_tab_vd_can_cor_class;          -- VD�J�����ʎ�����-��������敪
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ***************************************--
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
  gt_dlv_headers_row_id             g_tab_vd_row_id;                 -- �[�i�w�b�_�e�[�u�����R�[�hID
--******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************
--
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  gt_err_key_msg_tab                g_err_key_ttype;                -- �ėp�G���[���X�g�pkey���b�Z�[�W
  gv_prm_gen_err_out_flag           VARCHAR2(1);                    -- �ėp�G���[���X�g�o�̓t���O
  gn_msg_cnt                        NUMBER;                         -- �ėp�G���[���X�g�p���b�Z�[�W����
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
  gn_inv_target_cnt     NUMBER;                         -- ���o�ɏ�񒊏o����
  gn_dlv_h_target_cnt   NUMBER;                         -- �[�i�w�b�_��񒊏o����
  gn_dlv_l_target_cnt   NUMBER;                         -- �[�i���׏�񒊏o����
  gn_h_normal_cnt       NUMBER;                         -- ���o�Ƀw�b�_��񐬌�����
  gn_l_normal_cnt       NUMBER;                         -- ���o�ɖ��׏�񐬌�����
  gn_dlv_h_nor_cnt      NUMBER;                         -- �[�i�w�b�_��񐬌�����
  gn_dlv_l_nor_cnt      NUMBER;                         -- �[�i���׏�񐬌�����
  gt_tax_rate           g_tab_tax_rate;                 -- ����ŗ�
  gt_qck_invoice_type   g_tab_qck_invoice_type;         -- �`�[�敪
  gt_qck_input_type     g_tab_qck_input_type;           -- ���͋敪
  gt_inv_data           g_tab_inv_data;                 -- ���o�Ɉꎞ�\���o�f�[�^
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
  gt_clm_headers        g_tab_clm_headers;              -- �[�i�w�b�_�f�[�^�i�[�p
  gt_set_clm_headers    g_tab_set_clm_headers;          -- 
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
  gt_inv_data_tab      g_tab_inv_data_type;            -- �Ώۓ`�[���i�[�p
  gt_lines_tab         g_get_lines_type;                 -- �[�i���׏��
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
  gd_process_date       DATE;                           -- �Ɩ�������
  gd_max_date           DATE;                           -- MAX���t
  gv_bks_id             VARCHAR2(50);                   -- GL��v����ID
  gv_tkn1               VARCHAR2(50);                   -- �G���[���b�Z�[�W�p�g�[�N���P
  gv_tkn2               VARCHAR2(50);                   -- �G���[���b�Z�[�W�p�g�[�N���Q
  gv_tkn3               VARCHAR2(50);                   -- �G���[���b�Z�[�W�p�g�[�N���R
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
  gv_tkn4               VARCHAR2(2000);                 -- �G���[���b�Z�[�W�p�g�[�N���S
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
  gt_org_id             fnd_profile_option_values.profile_option_value%TYPE;      -- MO:�c�ƒP��
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
  gt_tr_count           NUMBER := 0;
  gt_insert_h_count     NUMBER := 0;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_application_ccp CONSTANT VARCHAR2(5)   := 'XXCCP';                  -- �A�v���P�[�V������
--
    -- *** ���[�J���ϐ� ***
    ld_process_date  DATE;              -- �Ɩ�������
    lv_max_date      VARCHAR2(50);      -- MAX���t
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    lv_para_msg      VARCHAR2(100);     -- �p�����[�^�o��
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--****************************** 2014/11/27 1.19 K.Nakatsu MOD START ******************************--
--    --==============================================================
--    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
--    --==============================================================
--    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
--    );
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => ''
--    );
----
--    --==============================================================
--    --�u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W�����O�o��
--    --==============================================================
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
--    -- ���b�Z�[�W���O
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => xxccp_common_pkg.get_msg( cv_application_ccp, cv_msg_parameter )
--    );
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
    -- �p�����[�^�o��
    lv_para_msg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_application
                       , iv_name          =>  cv_msg_err_out_flg
                       , iv_token_name1   =>  cv_tkn_err_out_flg
                       , iv_token_value1  =>  gv_prm_gen_err_out_flag
                     );
--
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  lv_para_msg
    );
--
    --1�s��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  NULL
    );
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  NULL
    );
--
    -- ���b�Z�[�W���O
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.LOG
      , buff    =>  lv_para_msg
    );
--****************************** 2014/11/27 1.19 K.Nakatsu DEL  END  ******************************--
--
    --==============================================================
    -- ���ʊ֐����Ɩ��������擾���̌Ăяo��
    --==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    -- �Ɩ��������擾�G���[�̏ꍇ
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_date );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_process_date := TRUNC( ld_process_date );
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾(XXCOS:MAX���t)
    --==================================
    lv_max_date := FND_PROFILE.VALUE( cv_prf_max_date );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( lv_max_date IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_max_date );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    ELSE
      gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾(GL��v����ID)
    --==================================
    gv_bks_id := FND_PROFILE.VALUE( cv_prf_bks_id );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( gv_bks_id IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_bks_id );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
    -- ===============================
    --  MO:�c�ƒP�ʎ擾
    -- ===============================
    gt_org_id := FND_PROFILE.VALUE( cv_pf_org_id );
--
    -- �v���t�@�C���擾�G���[�̏ꍇ
    IF ( gt_org_id IS NULL ) THEN
      gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_mo );
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_pro, cv_tkn_profile, gv_tkn1 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
--
  EXCEPTION
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : inv_data_receive
   * Description      : ���o�Ƀf�[�^���o(A-1)
   ***********************************************************************************/
  PROCEDURE inv_data_receive(
    on_target_cnt OUT NUMBER,       --   ���o����
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inv_data_receive'; -- �v���O������
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
    -- ����ŗ� and �N�C�b�N�R�[�h�F����ŃR�[�h�A����ŋ敪
    CURSOR get_tax_rate_cur( gl_id VARCHAR2 )
    IS
-- *************** 2009/09/04 1.13 N.Maeda MOD START *****************************--
      SELECT  xtv.tax_rate        tax_rate      -- ����ŗ�
             ,xtv.tax_code        tax_code      -- �ŋ��R�[�h
             ,xtv.hht_tax_class   tax_class -- ����ŋ敪
             ,xtv.start_date_active start_date_active -- �K�p�J�n��
             ,xtv.end_date_active   end_date_active   -- �K�p�I����
      FROM   xxcos_tax_v xtv
      WHERE  xtv.set_of_books_id = gl_id
      ;
--      SELECT tax.tax_rate  tax_rate,  -- ����ŗ�
--             tax.tax_code  tax_code,  -- ����ŃR�[�h
--             qck.cla       cla        -- ����ŋ敪
--      FROM   ar_vat_tax_all_b tax,    -- �ŃR�[�h�}�X�^
--             (
---- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
--               SELECT look_val.attribute2   code,   -- ����ŃR�[�h
--                      look_val.attribute3   cla     -- ����ŋ敪
--               FROM   fnd_lookup_values     look_val
--               WHERE  look_val.lookup_type       = cv_qck_typ_tax       -- �^�C�v��XXCOS1_CONSUMPTION_TAX_CLASS
--               AND    look_val.enabled_flag      = cv_tkn_yes           -- �g�p�\��Y
--               AND    gd_process_date           >= NVL(look_val.start_date_active, gd_process_date)
--               AND    gd_process_date           <= NVL(look_val.end_date_active, gd_max_date)
--               AND    look_val.language          = ct_user_lang    -- ���ꁁJA
--               ORDER BY look_val.attribute3
----
----               SELECT look_val.attribute2   code,   -- ����ŃR�[�h
----                      look_val.attribute3   cla     -- ����ŋ敪
----               FROM   fnd_lookup_values     look_val,
----                      fnd_lookup_types_tl   types_tl,
----                      fnd_lookup_types      types,
----                      fnd_application_tl    appl,
----                      fnd_application       app
----               WHERE  app.application_short_name = cv_application       -- XXCOS
----               AND    look_val.lookup_type       = cv_qck_typ_tax       -- �^�C�v��XXCOS1_CONSUMPTION_TAX_CLASS
----               AND    look_val.enabled_flag      = cv_tkn_yes           -- �g�p�\��Y
----               AND    gd_process_date           >= NVL(look_val.start_date_active, gd_process_date)
----               AND    gd_process_date           <= NVL(look_val.end_date_active, gd_max_date)
----               AND    types_tl.language          = USERENV( 'LANG' )    -- ���ꁁJA
----               AND    look_val.language          = USERENV( 'LANG' )    -- ���ꁁJA
----               AND    appl.language              = USERENV( 'LANG' )    -- ���ꁁJA
----               AND    appl.application_id        = types.application_id
----               AND    app.application_id         = appl.application_id
----               AND    types_tl.lookup_type       = look_val.lookup_type
----               AND    types.lookup_type          = types_tl.lookup_type
----               AND    types.security_group_id    = types_tl.security_group_id
----               AND    types.view_application_id  = types_tl.view_application_id
----               ORDER BY look_val.attribute3
---- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
--             ) qck
--      WHERE  tax.tax_code        = qck.code
--      AND    tax.set_of_books_id = gl_id                -- GL��v����ID
--      AND    tax.enabled_flag    = cv_tkn_yes           -- �g�p�\��Y
--      AND    gd_process_date    >= NVL(tax.start_date, gd_process_date)
--      AND    gd_process_date    <= NVL(tax.end_date, gd_max_date)
--      ;
-- *************** 2009/09/04 1.13 N.Maeda MOD  END  *****************************--
--
    -- �N�C�b�N�R�[�h�F�`�[�敪
    CURSOR get_invoice_type_cur
    IS
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
      SELECT  look_val.lookup_code  lookup_code,  -- �`�[�敪
              look_val.attribute1   form,         -- �`�[�敪�ɂ��`��
              look_val.attribute2   judge         -- ���ʉ��H����
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.lookup_type  = cv_qck_invo_type
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.language     = ct_user_lang;
--
--      SELECT  look_val.lookup_code  lookup_code,  -- �`�[�敪
--              look_val.attribute1   form,         -- �`�[�敪�ɂ��`��
--              look_val.attribute2   judge         -- ���ʉ��H����
--      FROM    fnd_lookup_values     look_val
--             ,fnd_lookup_types_tl   types_tl
--             ,fnd_lookup_types      types
--             ,fnd_application_tl    appl
--             ,fnd_application       app
--      WHERE   app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_invo_type
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     types_tl.language     = USERENV( 'LANG' )
--      AND     look_val.language     = USERENV( 'LANG' )
--      AND     appl.language         = USERENV( 'LANG' )
--      AND     appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id;
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    -- �N�C�b�N�R�[�h�F���͋敪
    CURSOR get_input_type_cur
    IS
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
      SELECT  look_val.meaning      slip_class,         -- �`�[�敪
              look_val.attribute1   input_class         -- �`�[�敪�ɂ��`��
      FROM    fnd_lookup_values     look_val
      WHERE   look_val.lookup_type  = cv_qck_input_type
      AND     look_val.enabled_flag = cv_tkn_yes
      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
      AND     look_val.language     = ct_user_lang;
--
--      SELECT  look_val.meaning      slip_class,         -- �`�[�敪
--              look_val.attribute1   input_class         -- �`�[�敪�ɂ��`��
--      FROM    fnd_lookup_values     look_val
--             ,fnd_lookup_types_tl   types_tl
--             ,fnd_lookup_types      types
--             ,fnd_application_tl    appl
--             ,fnd_application       app
--      WHERE   app.application_short_name = cv_application
--      AND     look_val.lookup_type  = cv_qck_input_type
--      AND     look_val.enabled_flag = cv_tkn_yes
--      AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--      AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--      AND     types_tl.language     = USERENV( 'LANG' )
--      AND     look_val.language     = USERENV( 'LANG' )
--      AND     appl.language         = USERENV( 'LANG' )
--      AND     appl.application_id   = types.application_id
--      AND     app.application_id    = appl.application_id
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     types.lookup_type     = types_tl.lookup_type
--      AND     types.security_group_id   = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id;
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
    -- ���o�Ɉꎞ�\�Ώۃ��R�[�h���b�N
    CURSOR get_inv_lock_cur
    IS
      SELECT  
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
              /*+
                INDEX (inv XXCOI_HHT_INV_TRANSACTIONS_N06 )
              */
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
              inv.last_updated_by         last_up  -- �ŏI�X�V��
      FROM    xxcoi_hht_inv_transactions  inv      -- ���o�Ɉꎞ�\
      WHERE   inv.invoice_type IN (
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
                                    SELECT  look_val.lookup_code  code
                                    FROM    fnd_lookup_values     look_val
                                    WHERE   look_val.lookup_type  = cv_qck_invo_type
                                    AND     look_val.enabled_flag = cv_tkn_yes
                                    AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                                    AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                                    AND     look_val.language     = ct_user_lang
--
--                                    SELECT  look_val.lookup_code  code
--                                    FROM    fnd_lookup_values     look_val
--                                           ,fnd_lookup_types_tl   types_tl
--                                           ,fnd_lookup_types      types
--                                           ,fnd_application_tl    appl
--                                           ,fnd_application       app
--                                    WHERE   app.application_short_name = cv_application
--                                    AND     look_val.lookup_type  = cv_qck_invo_type
--                                    AND     look_val.enabled_flag = cv_tkn_yes
--                                    AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                                    AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                                    AND     types_tl.language     = USERENV( 'LANG' )
--                                    AND     look_val.language     = USERENV( 'LANG' )
--                                    AND     appl.language         = USERENV( 'LANG' )
--                                    AND     appl.application_id   = types.application_id
--                                    AND     app.application_id    = appl.application_id
--                                    AND     types_tl.lookup_type  = look_val.lookup_type
--                                    AND     types.lookup_type     = types_tl.lookup_type
--                                    AND     types.security_group_id   = types_tl.security_group_id
--                                    AND     types.view_application_id = types_tl.view_application_id
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
                                  )                               -- �`�[�敪��4,5,6,7
      AND    inv.column_if_flag = cv_tkn_no                       -- �R�����ʓ]���t���O��N
      AND    inv.status         = cv_one                          -- �����X�e�[�^�X��1
      FOR UPDATE NOWAIT;
--
    -- ���o�Ɉꎞ�\�f�[�^���o
    CURSOR get_inv_data_cur
    IS
      SELECT
         base_code                 base_code             -- ���_�R�[�h
        ,employee_num              employee_num          -- �c�ƈ��R�[�h
        ,invoice_no                invoice_no            -- �`�[No.
        ,item_code                 item_code             -- �i�ڃR�[�h�i�i���R�[�h�j
        ,case_quantity             case_quantity         -- �P�[�X��
        ,case_in_quantity          case_in_quantity      -- ����
        ,quantity                  quantity              -- �{��
        ,invoice_type              invoice_type          -- �`�[�敪
        ,outside_code              outside_code          -- �o�ɑ��R�[�h
        ,inside_code               inside_code           -- ���ɑ��R�[�h
        ,invoice_date              invoice_date          -- �`�[���t
        ,column_no                 column_no             -- �R����No.
        ,unit_price                unit_price            -- �P��
        ,hot_cold_div              hot_cold_div          -- H/C
        ,total_quantity            total_quantity        -- ���{��
        ,inventory_item_id         inventory_item_id     -- �i��ID
        ,primary_uom_code          primary_uom_code      -- ��P��
        ,outside_business_low_type out_busi_low_type     -- �o�ɑ��Ƒԋ敪
        ,inside_business_low_type  in_busi_low_type      -- ���ɑ��Ƒԋ敪
        ,outside_cust_code         outside_cust_code     -- �o�ɑ��ڋq�R�[�h
        ,inside_cust_code          inside_cust_code      -- ���ɑ��ڋq�R�[�h
        ,tax_div                   tax_div               -- ����ŋ敪
        ,tax_rounding_rule         tax_rounding_rule     -- �ŋ��|�[������
        ,price                     price                 -- �P��
        ,perform_code              perform_code          -- ���ю҃R�[�h
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
        ,transaction_id            transaction_id        -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
      FROM
        (
        SELECT
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
-- *************** 2009/11/27 1.14 K.Atsushiba Mod START *****************************--
             /*+
               INDEX ( vd XXCOI_MST_VD_COLUMN_U01 )
               INDEX (ACCT HZ_CUST_ACCT_SITES_N3)
             */
--             /*+
--               INDEX ( vd XXCOI_MST_VD_COLUMN_U01 )
--             */
-- *************** 2009/11/27 1.14 K.Atsushiba Mod End *****************************--
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
                 inv.base_code                 base_code                    -- ���_�R�[�h
                ,inv.employee_num              employee_num                 -- �c�ƈ��R�[�h
                ,inv.invoice_no                invoice_no                   -- �`�[No.
                ,inv.item_code                 item_code                    -- �i�ڃR�[�h�i�i���R�[�h�j
                ,inv.case_quantity             case_quantity                -- �P�[�X��
                ,inv.case_in_quantity          case_in_quantity             -- ����
                ,inv.quantity                  quantity                     -- �{��
                ,inv.invoice_type              invoice_type                 -- �`�[�敪
                ,inv.outside_code              outside_code                 -- �o�ɑ��R�[�h
                ,inv.inside_code               inside_code                  -- ���ɑ��R�[�h
                ,inv.invoice_date              invoice_date                 -- �`�[���t
                ,inv.column_no                 column_no                    -- �R����No.
                ,inv.unit_price                unit_price                   -- �P��
                ,inv.hot_cold_div              hot_cold_div                 -- H/C
                ,inv.total_quantity            total_quantity               -- ���{��
                ,inv.inventory_item_id         inventory_item_id            -- �i��ID
                ,inv.primary_uom_code          primary_uom_code             -- ��P��
                ,inv.outside_business_low_type outside_business_low_type    -- �o�ɑ��Ƒԋ敪
                ,inv.inside_business_low_type  inside_business_low_type     -- ���ɑ��Ƒԋ敪
                ,inv.outside_cust_code         outside_cust_code            -- �o�ɑ��ڋq�R�[�h
                ,inv.inside_cust_code          inside_cust_code             -- ���ɑ��ڋq�R�[�h
                ,cust.tax_div                  tax_div                      -- ����ŋ敪
                ,site.tax_rounding_rule        tax_rounding_rule            -- �ŋ��|�[������
                ,vd.price                      price                        -- �P��
                ,xsv.employee_number           perform_code                 -- ���ю҃R�[�h
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
                ,inv.transaction_id            transaction_id               -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
          FROM   xxcoi_hht_inv_transactions    inv     -- ���o�Ɉꎞ�\
                ,hz_cust_accounts              hz_cus  -- �A�J�E���g
                ,xxcmm_cust_accounts           cust    -- �ڋq�ǉ����
                ,hz_cust_acct_sites_all        acct    -- �ڋq���ݒn
                ,hz_cust_site_uses_all         site    -- �ڋq�g�p�ړI
                ,xxcoi_mst_vd_column           vd      -- VD�R�����}�X�^
                ,xxcos_salesreps_v             xsv     -- �S���c�ƈ�view
                ,(
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
                   SELECT  look_val.lookup_code  code
                   FROM    fnd_lookup_values     look_val
                   WHERE   look_val.lookup_type  = cv_qck_invo_type
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute1   = cv_tkn_out
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.language     = ct_user_lang
--
--                   SELECT  look_val.lookup_code  code
--                   FROM    fnd_lookup_values     look_val
--                          ,fnd_lookup_types_tl   types_tl
--                          ,fnd_lookup_types      types
--                          ,fnd_application_tl    appl
--                          ,fnd_application       app
--                   WHERE   app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_invo_type
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                   AND     look_val.attribute1   = cv_tkn_out
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     types_tl.language     = USERENV( 'LANG' )
--                   AND     look_val.language     = USERENV( 'LANG' )
--                   AND     appl.language         = USERENV( 'LANG' )
--                   AND     appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
                 ) qck_invo    -- �N�C�b�N�R�[�h�F�o�ɑ��`�[�敪
          WHERE  inv.invoice_type       = qck_invo.code           -- �`�[�敪���o�ɑ�
          AND    inv.column_if_flag     = cv_tkn_no               -- �R�����ʓ]���t���O��N
          AND    inv.status             = cv_one                  -- �����X�e�[�^�X��1
          AND    inv.outside_cust_code  = hz_cus.account_number   -- ���o�Ɉꎞ�\.�o�ɑ��ڋq�R�[�h���A�J�E���g.�ڋq
          AND    hz_cus.cust_account_id = cust.customer_id        -- �A�J�E���g.�ڋqID���ڋq�ǉ����.�ڋqID
          AND    inv.column_no          = vd.column_no            -- ���o�Ɉꎞ�\.�R����No.��VD�R�����}�X�^.�R����No.
          AND    vd.customer_id         = cust.customer_id        -- VD�R�����}�X�^.�ڋqID���ڋq�ǉ����.�ڋqID
          AND    cust.customer_id       = acct.cust_account_id    -- �ڋq�ǉ����.�ڋq�T�C�gID���ڋq���ݒn.�ڋq�T�C�gID
          AND    acct.cust_acct_site_id = site.cust_acct_site_id  -- �ڋq���ݒn.�ڋq�T�C�gID���ڋq�g�p�ړI.�ڋq�T�C�gID
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
          AND    acct.org_id            = gt_org_id               -- �ڋq���ݒn.ORG_ID��1145
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
          AND    site.site_use_code     = cv_tkn_bill_to          -- �ڋq�g�p�ړI.�g�p�ړI��BILL_TO
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD START ******************************
          AND    acct.status            = cv_tkn_a                --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
          AND    site.status            = cv_tkn_a                --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
          AND    site.primary_flag      = cv_tkn_yes              --�ڋq�g�p�ړI.��t���O   = 'Y'(�L��)
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD END   ******************************
--************************* 2009/04/16 N.Maeda Ver1.5 MOD START ****************************************************
--          AND    (
--                    xsv.account_number = inv.outside_cust_code    -- �S���c�ƈ�view.�ڋq�ԍ������o�Ɉꎞ�\.�o�ɑ��ڋq
--                  AND                                             -- ���t�̓K�p�͈�
--                    inv.invoice_date >= NVL(xsv.effective_start_date, gd_process_date)
--                  AND
--                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
--                 )
          AND    (
                    xsv.account_number = inv.outside_cust_code    -- �S���c�ƈ�view.�ڋq�ԍ������o�Ɉꎞ�\.�o�ɑ��ڋq
                  AND                                             -- ���t�̓K�p�͈�
                    inv.invoice_date >= NVL(xsv.effective_start_date, inv.invoice_date)
                  AND
                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
                 )
--************************* 2009/04/16 N.Maeda Ver1.5 MOD END ******************************************************
          ORDER BY  inv.base_code              -- ���_�R�[�h
                   ,inv.outside_cust_code      -- �o�ɑ��ڋq�R�[�h
                   ,inv.invoice_no             -- �`�[No.
                   ,inv.column_no              -- �R����No.
        )
--
      UNION ALL
--
      SELECT
-- *************** 2009/08/10 1.12 N.Maeda ADD START *****************************--
             /*+
               INDEX ( vd XXCOI_MST_VD_COLUMN_U01 )
             */
-- *************** 2009/08/10 1.12 N.Maeda ADD  END  *****************************--
         base_code                 base_code                      -- ���_�R�[�h
        ,employee_num              employee_num                   -- �c�ƈ��R�[�h
        ,invoice_no                invoice_no                     -- �`�[No.
        ,item_code                 item_code                      -- �i�ڃR�[�h�i�i���R�[�h�j
        ,case_quantity             case_quantity                  -- �P�[�X��
        ,case_in_quantity          case_in_quantity               -- ����
        ,quantity                  quantity                       -- �{��
        ,invoice_type              invoice_type                   -- �`�[�敪
        ,outside_code              outside_code                   -- �o�ɑ��R�[�h
        ,inside_code               inside_code                    -- ���ɑ��R�[�h
        ,invoice_date              invoice_date                   -- �`�[���t
        ,column_no                 column_no                      -- �R����No.
        ,unit_price                unit_price                     -- �P��
        ,hot_cold_div              hot_cold_div                   -- H/C
        ,total_quantity            total_quantity                 -- ���{��
        ,inventory_item_id         inventory_item_id              -- �i��ID
        ,primary_uom_code          primary_uom_code               -- ��P��
        ,outside_business_low_type out_busi_low_type              -- �o�ɑ��Ƒԋ敪
        ,inside_business_low_type  in_busi_low_type               -- ���ɑ��Ƒԋ敪
        ,outside_cust_code         outside_cust_code              -- �o�ɑ��ڋq�R�[�h
        ,inside_cust_code          inside_cust_code               -- ���ɑ��ڋq�R�[�h
        ,tax_div                   tax_div                        -- ����ŋ敪
        ,tax_rounding_rule         tax_rounding_rule              -- �ŋ��|�[������
        ,price                     price                          -- �P��
        ,perform_code              perform_code                   -- ���ю҃R�[�h
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
        ,transaction_id            transaction_id                 -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
      FROM
        (
-- *************** 2009/11/27 1.14 K.Atsushiba Mod START *****************************--
          SELECT
        /*+
          INDEX(XSV.hopeb HZ_ORG_PROFILES_EXT_B_N1)
          INDEX(XSV.hopeb hz_org_profiles_ext_b_n1)
          INDEX(INV XXCOI_HHT_INV_TRANSACTIONS_N06)
          INDEX(ACCT HZ_CUST_ACCT_SITES_N3)
        */
                 inv.base_code                 base_code                    -- ���_�R�[�h
--          SELECT inv.base_code                 base_code                    -- ���_�R�[�h
-- *************** 2009/11/27 1.14 K.Atsushiba Mod End *****************************--
                ,inv.employee_num              employee_num                 -- �c�ƈ��R�[�h
                ,inv.invoice_no                invoice_no                   -- �`�[No.
                ,inv.item_code                 item_code                    -- �i�ڃR�[�h�i�i���R�[�h
                ,inv.case_quantity             case_quantity                -- �P�[�X��
                ,inv.case_in_quantity          case_in_quantity             -- ����
                ,inv.quantity                  quantity                     -- �{��
                ,inv.invoice_type              invoice_type                 -- �`�[�敪
                ,inv.outside_code              outside_code                 -- �o�ɑ��R�[�h
                ,inv.inside_code               inside_code                  -- ���ɑ��R�[�h
                ,inv.invoice_date              invoice_date                 -- �`�[���t
                ,inv.column_no                 column_no                    -- �R����No.
                ,inv.unit_price                unit_price                   -- �P��
                ,inv.hot_cold_div              hot_cold_div                 -- H/C
                ,inv.total_quantity            total_quantity               -- ���{��
                ,inv.inventory_item_id         inventory_item_id            -- �i��ID
                ,inv.primary_uom_code          primary_uom_code             -- ��P��
                ,inv.outside_business_low_type outside_business_low_type    -- �o�ɑ��Ƒԋ敪
                ,inv.inside_business_low_type  inside_business_low_type     -- ���ɑ��Ƒԋ敪
                ,inv.outside_cust_code         outside_cust_code            -- �o�ɑ��ڋq�R�[�h
                ,inv.inside_cust_code          inside_cust_code             -- ���ɑ��ڋq�R�[�h
                ,cust.tax_div                  tax_div                      -- ����ŋ敪
                ,site.tax_rounding_rule        tax_rounding_rule            -- �ŋ��|�[������
                ,vd.price                      price                        -- �P��
                ,xsv.employee_number           perform_code                 -- ���ю҃R�[�h
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
                ,inv.transaction_id            transaction_id               -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
          FROM   xxcoi_hht_inv_transactions    inv     -- ���o�Ɉꎞ�\
                ,hz_cust_accounts              hz_cus  -- �A�J�E���g
                ,xxcmm_cust_accounts           cust    -- �ڋq�ǉ����
                ,hz_cust_acct_sites_all        acct    -- �ڋq���ݒn
                ,hz_cust_site_uses_all         site    -- �ڋq�g�p�ړI
                ,xxcoi_mst_vd_column           vd      -- VD�R�����}�X�^
                ,xxcos_salesreps_v             xsv     -- �S���c�ƈ�view
                ,(
-- *************** 2009/08/10 1.12 N.Maeda MOD START *****************************--
                   SELECT  look_val.lookup_code  code
                   FROM    fnd_lookup_values     look_val
                   WHERE   look_val.lookup_type  = cv_qck_invo_type
                   AND     look_val.enabled_flag = cv_tkn_yes
                   AND     look_val.attribute1   = cv_tkn_in
                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
                   AND     look_val.language     = ct_user_lang
--
--                   SELECT  look_val.lookup_code  code
--                   FROM    fnd_lookup_values     look_val
--                          ,fnd_lookup_types_tl   types_tl
--                          ,fnd_lookup_types      types
--                          ,fnd_application_tl    appl
--                          ,fnd_application       app
--                   WHERE   app.application_short_name = cv_application
--                   AND     look_val.lookup_type  = cv_qck_invo_type
--                   AND     look_val.enabled_flag = cv_tkn_yes
--                   AND     look_val.attribute1   = cv_tkn_in
--                   AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                   AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                   AND     types_tl.language     = USERENV( 'LANG' )
--                   AND     look_val.language     = USERENV( 'LANG' )
--                   AND     appl.language         = USERENV( 'LANG' )
--                   AND     appl.application_id   = types.application_id
--                   AND     app.application_id    = appl.application_id
--                   AND     types_tl.lookup_type  = look_val.lookup_type
--                   AND     types.lookup_type     = types_tl.lookup_type
--                   AND     types.security_group_id   = types_tl.security_group_id
--                   AND     types.view_application_id = types_tl.view_application_id
-- *************** 2009/08/10 1.12 N.Maeda MOD  END  *****************************--
                 ) qck_invo    -- �N�C�b�N�R�[�h�F���ɑ��`�[�敪
          WHERE  inv.invoice_type       = qck_invo.code           -- �`�[�敪�����ɑ�
          AND    inv.column_if_flag     = cv_tkn_no               -- �R�����ʓ]���t���O��N
          AND    inv.status             = cv_one                  -- �����X�e�[�^�X��1
          AND    inv.inside_cust_code   = hz_cus.account_number   -- ���o�Ɉꎞ�\.���ɑ��ڋq�R�[�h���A�J�E���g.�ڋq
          AND    hz_cus.cust_account_id = cust.customer_id        -- �A�J�E���g.�ڋqID���ڋq�ǉ����.�ڋqID
          AND    inv.column_no          = vd.column_no            -- ���o�Ɉꎞ�\.�R����No.��VD�R�����}�X�^.�R����No.
          AND    vd.customer_id         = cust.customer_id        -- VD�R�����}�X�^.�ڋqID���ڋq�ǉ����.�ڋqID
          AND    cust.customer_id       = acct.cust_account_id    -- �ڋq�ǉ����.�ڋq�T�C�gID���ڋq���ݒn.�ڋq�T�C�gID
          AND    acct.cust_acct_site_id = site.cust_acct_site_id  -- �ڋq���ݒn.�ڋq�T�C�gID���ڋq�g�p�ړI.�ڋq�T�C�gID
--****************************** 2009/05/29 1.9 T.Kitajima ADD START ******************************
          AND    acct.org_id            = gt_org_id               -- �ڋq���ݒn.ORG_ID��1145
--****************************** 2009/05/29 1.9 T.Kitajima ADD  END  ******************************
          AND    site.site_use_code     = cv_tkn_bill_to          -- �ڋq�g�p�ړI.�g�p�ړI��BILL_TO
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD START ******************************
          AND    acct.status            = cv_tkn_a                --�ڋq���ݒn.�X�e�[�^�X   = 'A'(�L��)
          AND    site.status            = cv_tkn_a                --�ڋq�g�p�ړI.�X�e�[�^�X = 'A'(�L��)
          AND    site.primary_flag      = cv_tkn_yes              --�ڋq�g�p�ړI.��t���O   = 'Y'(�L��)
--****************************** 2010/03/18 1.16 S.Miyakoshi ADD END   ******************************
--************************* 2009/04/16 N.Maeda Ver1.5 MOD START ****************************************************
--          AND    (
--                    xsv.account_number = inv.inside_cust_code     -- �S���c�ƈ�view.�ڋq�ԍ������o�Ɉꎞ�\.���ɑ��ڋq
--                  AND                                             -- ���t�̓K�p�͈�
--                    inv.invoice_date >= NVL(xsv.effective_start_date, gd_process_date)
--                  AND
--                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
--                 )
          AND    (
                    xsv.account_number = inv.inside_cust_code     -- �S���c�ƈ�view.�ڋq�ԍ������o�Ɉꎞ�\.���ɑ��ڋq
                  AND                                             -- ���t�̓K�p�͈�
                    inv.invoice_date >= NVL(xsv.effective_start_date, inv.invoice_date)
                  AND
                    inv.invoice_date <= NVL(xsv.effective_end_date, gd_max_date)
                 )
--************************* 2009/04/16 N.Maeda Ver1.5 MOD END ******************************************************
          ORDER BY  inv.base_code              -- ���_�R�[�h
                   ,inv.inside_cust_code       -- ���ɑ��ڋq�R�[�h
                   ,inv.invoice_no             -- �`�[No.
                   ,inv.column_no              -- �R����No.
        )
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
    -- ���o����������
    on_target_cnt := 0;
--
    --==============================================================
    -- ���o�Ɉꎞ�\�Ώۃ��R�[�h���b�N
    --==============================================================
    OPEN  get_inv_lock_cur;
    CLOSE get_inv_lock_cur;
--
    --==============================================================
    -- �f�[�^�̎擾
    --==============================================================
    -- ����ŗ��擾
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_tax_rate_cur( gv_bks_id );
      -- �o���N�t�F�b�`
      FETCH get_tax_rate_cur BULK COLLECT INTO gt_tax_rate;
      -- �J�[�\��CLOSE
      CLOSE get_tax_rate_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_tax_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_get,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
--
        IF ( get_tax_rate_cur%ISOPEN ) THEN
          CLOSE get_tax_rate_cur;
        END IF;
--
        RAISE global_api_expt;
    END;
--
    -- �`�[�敪�擾
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_invoice_type_cur;
      -- �o���N�t�F�b�`
      FETCH get_invoice_type_cur BULK COLLECT INTO gt_qck_invoice_type;
      -- �J�[�\��CLOSE
      CLOSE get_invoice_type_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�`�[�敪�擾
        IF ( get_invoice_type_cur%ISOPEN ) THEN
          CLOSE get_invoice_type_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_invo_type );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_invo_type );
--
        RAISE lookup_types_expt;
    END;
--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    -- ���͋敪�擾
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_input_type_cur;
      -- �o���N�t�F�b�`
      FETCH get_input_type_cur BULK COLLECT INTO gt_qck_input_type;
      -- �J�[�\��CLOSE
      CLOSE get_input_type_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �J�[�\��CLOSE�F�`�[�敪�擾
        IF ( get_input_type_cur%ISOPEN ) THEN
          CLOSE get_input_type_cur;
        END IF;
--
        gv_tkn2 := xxccp_common_pkg.get_msg( cv_application, cv_qck_input_type );
        gv_tkn3 := xxccp_common_pkg.get_msg( cv_application, cv_msg_input );
--
        RAISE lookup_types_expt;
    END;
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
--
    -- ���o�Ƀf�[�^�擾
    BEGIN
      -- �J�[�\��OPEN
      OPEN  get_inv_data_cur;
      -- �o���N�t�F�b�`
      FETCH get_inv_data_cur BULK COLLECT INTO gt_inv_data;
      -- ���o�����Z�b�g
      on_target_cnt := get_inv_data_cur%ROWCOUNT;
      -- �J�[�\��CLOSE
      CLOSE get_inv_data_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1   := xxccp_common_pkg.get_msg( cv_application, cv_msg_inv_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_get,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
        ov_retcode := cv_status_error;
--
      IF ( get_inv_data_cur%ISOPEN ) THEN
        CLOSE get_inv_data_cur;
      END IF;
--
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
    -- ���b�N�G���[
    WHEN lock_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_inv_table );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_tab, gv_tkn1 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
      IF ( get_inv_lock_cur%ISOPEN ) THEN
        CLOSE get_inv_lock_cur;
      END IF;
--
    -- �N�C�b�N�R�[�h�擾�G���[
    WHEN lookup_types_expt THEN
      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_lookup );
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_qck_error, cv_tkn_table,  gv_tkn1,
                                                                                cv_tkn_type,   gv_tkn2,
                                                                                cv_tkn_colmun, gv_tkn3 );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END inv_data_receive;
--
  /**********************************************************************************
   * Procedure Name   : inv_data_compute
   * Description      : ���o�Ƀf�[�^���o(A-2)
   ***********************************************************************************/
  PROCEDURE inv_data_compute(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inv_data_compute'; -- �v���O������
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
    -- ���o�ɒ��o�f�[�^�ϐ�
    lt_base_code           xxcoi_hht_inv_transactions.base_code%TYPE;                  -- ���_�R�[�h
    lt_employee_num        xxcoi_hht_inv_transactions.employee_num%TYPE;               -- �c�ƈ��R�[�h
    lt_invoice_no          xxcoi_hht_inv_transactions.invoice_no%TYPE;                 -- �`�[No.
    lt_item_code           xxcoi_hht_inv_transactions.item_code%TYPE;                  -- �i�ڃR�[�h�i�i���R�[�h�j
    lt_case_quant          xxcoi_hht_inv_transactions.case_quantity%TYPE;              -- �P�[�X��
    lt_case_in_quant       xxcoi_hht_inv_transactions.case_in_quantity%TYPE;           -- ����
    lt_quantity            xxcoi_hht_inv_transactions.quantity%TYPE;                   -- �{��
    lt_invoice_type        xxcoi_hht_inv_transactions.invoice_type%TYPE;               -- �`�[�敪
    lt_outside_code        xxcoi_hht_inv_transactions.outside_code%TYPE;               -- �o�ɑ��R�[�h
    lt_inside_code         xxcoi_hht_inv_transactions.inside_code%TYPE;                -- ���ɑ��R�[�h
    lt_invoice_date        xxcoi_hht_inv_transactions.invoice_date%TYPE;               -- �`�[���t
    lt_column_no           xxcoi_hht_inv_transactions.column_no%TYPE;                  -- �R����No.
    lt_unit_price          xxcoi_hht_inv_transactions.unit_price%TYPE;                 -- �P��
    lt_hot_cold_div        xxcoi_hht_inv_transactions.hot_cold_div%TYPE;               -- H/C
    lt_item_id             xxcoi_hht_inv_transactions.inventory_item_id%TYPE;          -- �i��ID
    lt_primary_code        xxcoi_hht_inv_transactions.primary_uom_code%TYPE;           -- ��P��
    lt_out_bus_low_type    xxcoi_hht_inv_transactions.outside_business_low_type%TYPE;  -- �o�ɑ��Ƒԋ敪
    lt_in_bus_low_type     xxcoi_hht_inv_transactions.inside_business_low_type%TYPE;   -- ���ɑ��Ƒԋ敪
    lt_out_cus_code        xxcoi_hht_inv_transactions.outside_cust_code%TYPE;          -- �o�ɑ��ڋq�R�[�h
    lt_in_cus_code         xxcoi_hht_inv_transactions.inside_cust_code%TYPE;           -- ���ɑ��ڋq�R�[�h
    lt_tax_div             xxcmm_cust_accounts.tax_div%TYPE;                           -- ����ŋ敪
    lt_tax_round_rule      hz_cust_site_uses_all.tax_rounding_rule%TYPE;               -- �ŋ��|�[������
    lt_inv_price           xxcoi_mst_vd_column.price%TYPE;                             -- �P���FVD�R�����}�X�^���
    lt_perform_code        xxcos_vd_column_headers.performance_by_code%TYPE;           -- ���ю҃R�[�h
--
    lt_order_no_hht        xxcos_vd_column_headers.order_no_hht%TYPE;                  -- ��No.(HHT)
    lt_customer_number     xxcos_vd_column_headers.customer_number%TYPE;               -- �ڋq�R�[�h
    lt_system_class        xxcos_vd_column_headers.system_class%TYPE;                  -- �Ƒԋ敪
    lt_total_amount        xxcos_vd_column_headers.total_amount%TYPE;                  -- ���v���z
    lt_sales_tax           xxcos_vd_column_headers.sales_consumption_tax%TYPE;         -- �������Ŋz
    lt_sales_tax_tempo     NUMBER;                                                     -- �������Ŋz�F�ꎞ�i�[�p
    lt_tax_include         xxcos_vd_column_headers.tax_include%TYPE;                   -- �ō����z
    lt_tax_include_tempo   xxcos_vd_column_headers.tax_include%TYPE;                   -- �ō����z�F�ꎞ�i�[�p
    lt_red_black_flag      xxcos_vd_column_headers.red_black_flag%TYPE;                -- �ԍ��t���O
    lt_cancel_correct      xxcos_vd_column_headers.cancel_correct_class%TYPE;          -- ����E�����敪
    lt_vd_quantity         xxcos_vd_column_lines.quantity%TYPE;                        -- ����
    lt_replenish_number    xxcos_vd_column_lines.replenish_number%TYPE;                -- ��[��
--************************* 2009/04/15 N.Maeda Ver1.4 ADD START ****************************************************
    lt_vd_replenish_number xxcos_vd_column_lines.replenish_number%TYPE;                -- ��[��(���ʉ��H�p)
    lt_vd_case_quant       xxcoi_hht_inv_transactions.case_quantity%TYPE;              -- �P�[�X��(���ʉ��H�p)
--************************* 2009/04/15 N.Maeda Ver1.4 ADD END ******************************************************
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
    lt_transaction_id      xxcoi_hht_inv_transactions.transaction_id%TYPE;             -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
    lt_input_class         xxcos_vd_column_headers.input_class%TYPE;                   -- ���͋敪
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
-- ************ 2010/02/03 1.15 N.Maeda MOD START ************ --
    lt_next_index_customer xxcos_vd_column_headers.customer_number%TYPE;               -- �w�b�_�쐬����p�ڋq�R�[�h
    lv_next_form           VARCHAR(3);                                                 -- �w�b�_�쐬����p�`�[�敪�ɂ��`��
-- ************ 2010/02/03 1.15 N.Maeda MOD  END  ************ --
    ln_inv_header_num      NUMBER DEFAULT  '1';                                        -- ���o�Ƀw�b�_�����i���o�[
    ln_inv_lines_num       NUMBER DEFAULT  '1';                                        -- ���o�ɖ��׌����i���o�[
    ln_line_no             NUMBER DEFAULT  '1';                                        -- �sNo.(HHT)
    lv_form                VARCHAR(3);                                                 -- �`�[�敪�ɂ��`��
    lv_change              VARCHAR(1);                                                 -- ���ʉ��H����
    ln_rate                NUMBER;                                                     -- �ŗ�
--
    -- ��No.(HHT)�擾�t���O�i0�F�擾�ς݁A1�F�擾�̕K�v����j
    lv_order_no_flag       VARCHAR(1) DEFAULT  '1';
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�v�J�n
    FOR inv_no IN 1..gn_inv_target_cnt LOOP
      -- ���o�f�[�^�擾
      lt_base_code        := gt_inv_data(inv_no).base_code;         -- ���_�R�[�h
      lt_employee_num     := gt_inv_data(inv_no).employee_num;      -- �c�ƈ��R�[�h
      lt_invoice_no       := gt_inv_data(inv_no).invoice_no;        -- �`�[No.
      lt_item_code        := gt_inv_data(inv_no).item_code;         -- �i�ڃR�[�h�i�i���R�[�h�j
      lt_case_quant       := gt_inv_data(inv_no).case_quant;        -- �P�[�X��
      lt_case_in_quant    := gt_inv_data(inv_no).case_in_quant;     -- ����
      lt_quantity         := gt_inv_data(inv_no).quantity;          -- �{��
      lt_invoice_type     := gt_inv_data(inv_no).invoice_type;      -- �`�[�敪
      lt_outside_code     := gt_inv_data(inv_no).outside_code;      -- �o�ɑ��R�[�h
      lt_inside_code      := gt_inv_data(inv_no).inside_code;       -- ���ɑ��R�[�h
      lt_invoice_date     := gt_inv_data(inv_no).invoice_date;      -- �`�[���t
      lt_column_no        := gt_inv_data(inv_no).column_no;         -- �R����No.
      lt_unit_price       := gt_inv_data(inv_no).unit_price;        -- �P��
      lt_hot_cold_div     := gt_inv_data(inv_no).hot_cold_div;      -- H/C
      lt_replenish_number := gt_inv_data(inv_no).total_quantity;    -- ��[��
      lt_item_id          := gt_inv_data(inv_no).item_id;           -- �i��ID
      lt_primary_code     := gt_inv_data(inv_no).primary_code;      -- ��P��
      lt_out_bus_low_type := gt_inv_data(inv_no).out_bus_low_type;  -- �o�ɑ��Ƒԋ敪
      lt_in_bus_low_type  := gt_inv_data(inv_no).in_bus_low_type;   -- ���ɑ��Ƒԋ敪
      lt_out_cus_code     := gt_inv_data(inv_no).out_cus_code;      -- �o�ɑ��ڋq�R�[�h
      lt_in_cus_code      := gt_inv_data(inv_no).in_cus_code;       -- ���ɑ��ڋq�R�[�h
      lt_tax_div          := gt_inv_data(inv_no).tax_div;           -- ����ŋ敪
      lt_tax_round_rule   := gt_inv_data(inv_no).tax_round_rule;    -- �ŋ��|�[������
      lt_inv_price        := gt_inv_data(inv_no).inv_price;         -- �P���FVD�R�����}�X�^���
      lt_perform_code     := gt_inv_data(inv_no).perform_code;      -- ���ю҃R�[�h
--****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
      lt_transaction_id   := gt_inv_data(inv_no).transaction_id;    -- ���o�Ɉꎞ�\ID
--****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--
      -- ��No.(HHT)���擾����ꍇ
      IF ( lv_order_no_flag = cv_one ) THEN
--
        --==============================================================
        -- ���v���z�A�ō����z�A�������Ŋz�A�sNo.(HHT)�̏�����
        --==============================================================
        lt_total_amount := 0;    -- ���v���z
        lt_tax_include  := 0;    -- �ō����z
        lt_sales_tax    := 0;    -- �������Ŋz
        ln_line_no      := 1;    -- �sNo.(HHT)
--
        --==============================================================
        -- ��No.(HHT)�擾
        --==============================================================
        SELECT
          xxcos_dlv_headers_s01.NEXTVAL
        INTO
          lt_order_no_hht
        FROM
          dual
        ;
--
        lv_order_no_flag  := cv_default;                        -- ��No.(HHT)�擾�t���O������
--
      END IF;
--
      --==============================================================
      -- �ڋq�R�[�h�A�Ƒԋ敪�A���ʂ̓��o�i�w�b�_���j
      --==============================================================
      --== �o�ɑ��A���ɑ����� ==--
      FOR i IN 1..gt_qck_invoice_type.COUNT LOOP
--
        IF ( gt_qck_invoice_type(i).invoice_type = lt_invoice_type ) THEN
          lv_form   := gt_qck_invoice_type(i).form;     -- �`�[�敪�ɂ��`�Ԃ��Z�b�g
          lv_change := gt_qck_invoice_type(i).change;   -- ���ʉ��H������Z�b�g
          EXIT;
        END IF;
--
      END LOOP;
--
      IF ( lv_form = cv_tkn_out ) THEN         -- �o�ɑ��̏ꍇ
--
        --== �ڋq�R�[�h�Z�b�g ==--
        lt_customer_number := lt_out_cus_code;
--
        --== �Ƒԋ敪�Z�b�g ==--
        lt_system_class := lt_out_bus_low_type;
--
      ELSIF ( lv_form = cv_tkn_in ) THEN       -- ���ɑ��̏ꍇ
--
        --== �ڋq�R�[�h�Z�b�g ==--
        lt_customer_number := lt_in_cus_code;
--
        --== �Ƒԋ敪�Z�b�g ==--
        lt_system_class := lt_in_bus_low_type;
--
      END IF;
--
      IF ( lt_quantity >= 0 ) THEN           -- ���ʂ�0�ȏ�̏ꍇ
--
        --== �ԍ��t���O�Z�b�g ==--
        lt_red_black_flag := cv_one;         -- 1���Z�b�g
--
        --== ����E�����敪�Z�b�g ==--
        lt_cancel_correct := NULL;           -- NULL���Z�b�g
--
      ELSIF ( lt_quantity < 0 ) THEN         -- ���ʂ��}�C�i�X�̏ꍇ
--
        --== �ԍ��t���O�Z�b�g ==--
        lt_red_black_flag := cv_default;     -- 0���Z�b�g
--
        --== ����E�����敪�Z�b�g ==--
        lt_cancel_correct := cv_one;         -- 1���Z�b�g
--
      END IF;
--
      --== ���ʉ��H ==--
      IF ( lv_change = cv_tkn_yes ) THEN
        lt_vd_quantity := lt_quantity * -1;
--************************* 2009/04/15 N.Maeda Ver1.4 ADD START ****************************************************
        lt_vd_replenish_number := lt_replenish_number * -1;
        lt_vd_case_quant       := lt_case_quant * -1;
--************************* 2009/04/15 N.Maeda Ver1.4 ADD END ******************************************************
      ELSE
        lt_vd_quantity := lt_quantity;
--************************* 2009/04/15 N.Maeda Ver1.4 ADD START ****************************************************
        lt_vd_replenish_number := lt_replenish_number;
        lt_vd_case_quant       := lt_case_quant;
--************************* 2009/04/15 N.Maeda Ver1.4 ADD END ******************************************************
      END IF;
--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
      --���͋敪
      --������
      lt_input_class := NULL;
      FOR i IN 1..gt_qck_input_type.COUNT LOOP
--
        IF ( gt_qck_input_type(i).slip_class = lt_invoice_type ) THEN
          lt_input_class   := gt_qck_input_type(i).input_class;     -- �`�[�敪�ɂ����͋敪���Z�b�g
          EXIT;
        END IF;
--
      END LOOP;
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
      --== �ŗ��̎Z�o ==--
      FOR i IN 1..gt_tax_rate.COUNT LOOP
--
-- *************** 2009/09/04 1.13 N.Maeda MOD START *****************************--
--        IF ( gt_tax_rate(i).tax_class = lt_tax_div ) THEN
        -- �N�C�b�N�R�[�h����ŋ敪 = ����ŋ敪
        IF  ( gt_tax_rate(i).tax_class = lt_tax_div )
        -- �`�[���t �� NVL( �N�C�b�N�R�[�h�K�p�J�n�� , �`�[���t )
        AND ( lt_invoice_date >= NVL( gt_tax_rate(i).qck_start_date_active,lt_invoice_date ) )
        -- �`�[���t �� NVL( �N�C�b�N�R�[�h�K�p�I���� , A-0�Ŏ擾����MAX���t )
        AND ( lt_invoice_date <= NVL( gt_tax_rate(i).qck_end_date_active, gd_max_date ) ) THEN
-- *************** 2009/09/04 1.13 N.Maeda MOD  END  *****************************--
          ln_rate := 1 + gt_tax_rate(i).rate / 100;     -- �ŗ����Z�b�g
          EXIT;
        END IF;
--
      END LOOP;
--
      --==============================================================
      -- ���v���z�̓��o�i�w�b�_���j
      --==============================================================
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      -- ��[���~�P��
--      lt_total_amount := lt_total_amount + lt_replenish_number * lt_unit_price;
      -- ��[���~�P��
      lt_total_amount := lt_total_amount + lt_vd_replenish_number * lt_unit_price;
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
--
      --==============================================================
      -- �ō��݋��z�̓��o�i�w�b�_���j
      --==============================================================
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      -- �{���~VD�R�����}�X�^�̒P��
--      lt_tax_include_tempo := lt_replenish_number * lt_inv_price;
      -- �{���~VD�R�����}�X�^�̒P��
      lt_tax_include_tempo := lt_vd_replenish_number * lt_inv_price;
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
--
      -- �w�b�_�ϐ��i�[�p�f�[�^�Z�o
      lt_tax_include := lt_tax_include + lt_tax_include_tempo;
--
      --==============================================================
      -- �������Ŋz�̓��o�i�w�b�_���j
      --==============================================================
      -- �ō����z������ŗ�
      lt_sales_tax_tempo := lt_tax_include_tempo - ( lt_tax_include_tempo / ln_rate );
--
--*************************** 2009/06/02 Ver1.10 N.Maeda MOD START *****************************--
      -- �[������������
      IF ( lt_sales_tax_tempo <> TRUNC(lt_sales_tax_tempo) ) THEN
--
        -- �����_�ȉ��̏���
        IF ( lt_tax_round_rule = cv_tkn_down ) THEN        -- �؎̂ď���
--
          lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo );
--
        ELSIF ( lt_tax_round_rule = cv_tkn_up ) THEN       -- �؏グ����
--
--          lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo + .9 );
--
          IF ( SIGN( lt_sales_tax_tempo ) <> -1 ) THEN
--
            lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo) + 1;
--
          ELSE
--
            lt_sales_tax_tempo := TRUNC( lt_sales_tax_tempo) - 1;
--
          END IF;
--
        ELSIF ( lt_tax_round_rule = cv_tkn_nearest ) THEN  -- �l�̌ܓ�����
--
          lt_sales_tax_tempo := ROUND( lt_sales_tax_tempo );
--
        END IF;
--
--*************************** 2009/06/02 Ver1.10 N.Maeda MOD  END  *****************************--
      END IF;
--
      -- �w�b�_�ϐ��i�[�p�f�[�^�Z�o
      lt_sales_tax := lt_sales_tax + lt_sales_tax_tempo;
--
      --==============================================================
      -- ���o�ɖ��ׂփf�[�^�i�[
      --==============================================================
      gt_order_nol_hht(ln_inv_lines_num)  := lt_order_no_hht;      -- ��No.(HHT)
      gt_line_no_hht(ln_inv_lines_num)    := ln_line_no;           -- �sNo.(HHT)
      gt_item_code_self(ln_inv_lines_num) := lt_item_code;         -- �i���R�[�h(����)
      gt_content(ln_inv_lines_num)        := lt_case_in_quant;     -- ����
      gt_item_id(ln_inv_lines_num)        := lt_item_id;           -- �i��ID
      gt_standard_unit(ln_inv_lines_num)  := lt_primary_code;      -- ��P��
--************************* 2009/04/16 N.Maeda Ver1.5 MOD START ****************************************************
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      gt_case_number(ln_inv_lines_num)    := lt_case_quant;        -- �P�[�X��
--      gt_case_number(ln_inv_lines_num)    := lt_vd_replenish_number;        -- �P�[�X��
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
      gt_case_number(ln_inv_lines_num)    := lt_vd_case_quant;        -- �P�[�X��
--************************* 2009/04/16 N.Maeda Ver1.5 MOD END ******************************************************
      gt_quantity(ln_inv_lines_num)       := lt_vd_quantity;       -- ����
      gt_wholesale(ln_inv_lines_num)      := lt_unit_price;        -- ���P��
      gt_column_no(ln_inv_lines_num)      := lt_column_no;         -- �R����No.
      gt_h_and_c(ln_inv_lines_num)        := lt_hot_cold_div;      -- H/C
--************************* 2009/04/15 N.Maeda Ver1.4 MOD START ****************************************************
--      gt_replenish_num(ln_inv_lines_num)  := lt_replenish_number;  -- ��[��
      gt_replenish_num(ln_inv_lines_num)  := lt_vd_replenish_number;  -- ��[��
--************************* 2009/04/15 N.Maeda Ver1.4 MOD END ******************************************************
----****************************** 2009/04/17 1.6 T.Kitajima ADD START ******************************--
      gt_transaction_id(ln_inv_lines_num) := lt_transaction_id;     -- ���o�Ɉꎞ�\ID
----****************************** 2009/04/17 1.6 T.Kitajima ADD  END  ******************************--
--****************************** 2009/04/22 1.7 T.Kitajima ADD START ******************************--
      gt_input_class(ln_inv_lines_num)    := lt_input_class;        -- ���͋敪
--****************************** 2009/04/22 1.7 T.Kitajima ADD  END  ******************************--
      ln_line_no := ln_line_no + 1;                                -- �sNo.(HHT)�X�V
      ln_inv_lines_num := ln_inv_lines_num + 1;                    -- ���o�ɖ��׌����i���o�[�X�V
--
-- ************ 2010/02/03 1.15 N.Maeda ADD START ************ --
--
      -- �ŏI���R�[�h�łȂ���Ύ��ڋq�����擾���܂��B
      IF ( inv_no != gn_inv_target_cnt ) THEN
        --== ���f�[�^�o�ɑ��A���ɑ����� ==--
        FOR i IN 1..gt_qck_invoice_type.COUNT LOOP
          IF ( gt_qck_invoice_type(i).invoice_type = gt_inv_data(inv_no + 1).invoice_type ) THEN
            lv_next_form   := gt_qck_invoice_type(i).form;     -- �`�[�敪�ɂ��`�Ԃ��Z�b�g
            EXIT;
          END IF;
        END LOOP;
--
        --== �ڋq�R�[�h�Z�b�g���� ==--
        IF ( lv_next_form = cv_tkn_out ) THEN         -- �o�ɑ��̏ꍇ
          lt_next_index_customer := gt_inv_data(inv_no + 1).out_cus_code;
        ELSIF ( lv_next_form = cv_tkn_in ) THEN       -- ���ɑ��̏ꍇ
          lt_next_index_customer := gt_inv_data(inv_no + 1).in_cus_code;
        END IF;
      END IF;
--
-- ************ 2010/02/03 1.15 N.Maeda ADD  END  ************ --
--
      IF ( inv_no = gn_inv_target_cnt ) THEN    -- ���[�v���Ō�̏ꍇ
--
        -- �w�b�_�Ώی����J�E���g�A�b�v
        gt_tr_count := gt_tr_count + 1;
        --==============================================================
        -- ���o�Ƀw�b�_�փf�[�^�i�[
        --==============================================================
        gt_order_noh_hht(ln_inv_header_num)  := lt_order_no_hht;       -- ��No.(HHT)
        gt_base_code(ln_inv_header_num)      := lt_base_code;          -- ���_�R�[�h
        gt_perform_code(ln_inv_header_num)   := lt_perform_code;       -- ���ю҃R�[�h
        gt_dlv_code(ln_inv_header_num)       := lt_employee_num;       -- �[�i�҃R�[�h
        gt_invoice_no(ln_inv_header_num)     := lt_invoice_no;         -- HHT�`�[No.
        gt_dlv_date(ln_inv_header_num)       := lt_invoice_date;       -- �[�i��
        gt_inspect_date(ln_inv_header_num)   := lt_invoice_date;       -- ������
        gt_cus_number(ln_inv_header_num)     := lt_customer_number;    -- �ڋq�R�[�h
        gt_system_class(ln_inv_header_num)   := lt_system_class;       -- �Ƒԋ敪
        gt_invoice_type(ln_inv_header_num)   := lt_invoice_type;       -- �`�[�敪
        gt_tax_class(ln_inv_header_num)      := lt_tax_div;            -- ����ŋ敪
        gt_total_amount(ln_inv_header_num)   := lt_total_amount;       -- ���v���z
        gt_sales_tax(ln_inv_header_num)      := lt_sales_tax;          -- �������Ŋz
        gt_tax_include(ln_inv_header_num)    := lt_tax_include;        -- �ō����z
        gt_red_black_flag(ln_inv_header_num) := lt_red_black_flag;     -- �ԍ��t���O
        gt_cancel_correct(ln_inv_header_num) := lt_cancel_correct;     -- ����E�����敪
        ln_inv_header_num := ln_inv_header_num + 1;                    -- ���o�Ƀw�b�_�����i���o�[�X�V
        lv_order_no_flag  := cv_one;                                   -- ��No.(HHT)�擾�t���O�X�V
--
-- ************ 2010/02/03 1.15 N.Maeda MOD START ************ --
--      ELSIF ( lt_invoice_no != gt_inv_data(inv_no + 1).invoice_no ) THEN
      ELSIF ( lt_invoice_no != gt_inv_data(inv_no + 1).invoice_no )
         OR ( lt_base_code  != gt_inv_data(inv_no + 1).base_code )
         OR ( lt_customer_number != lt_next_index_customer ) THEN
-- ************ 2010/02/03 1.15 N.Maeda MOD  END  ************ --
--
        -- �w�b�_�Ώی����J�E���g�A�b�v
        gt_tr_count := gt_tr_count + 1;
        --==============================================================
        -- ���o�Ƀw�b�_�փf�[�^�i�[
        --==============================================================
        gt_order_noh_hht(ln_inv_header_num)  := lt_order_no_hht;       -- ��No.(HHT)
        gt_base_code(ln_inv_header_num)      := lt_base_code;          -- ���_�R�[�h
        gt_perform_code(ln_inv_header_num)   := lt_perform_code;       -- ���ю҃R�[�h
        gt_dlv_code(ln_inv_header_num)       := lt_employee_num;       -- �[�i�҃R�[�h
        gt_invoice_no(ln_inv_header_num)     := lt_invoice_no;         -- HHT�`�[No.
        gt_dlv_date(ln_inv_header_num)       := lt_invoice_date;       -- �[�i��
        gt_inspect_date(ln_inv_header_num)   := lt_invoice_date;       -- ������
        gt_cus_number(ln_inv_header_num)     := lt_customer_number;    -- �ڋq�R�[�h
        gt_system_class(ln_inv_header_num)   := lt_system_class;       -- �Ƒԋ敪
        gt_invoice_type(ln_inv_header_num)   := lt_invoice_type;       -- �`�[�敪
        gt_tax_class(ln_inv_header_num)      := lt_tax_div;            -- ����ŋ敪
        gt_total_amount(ln_inv_header_num)   := lt_total_amount;       -- ���v���z
        gt_sales_tax(ln_inv_header_num)      := lt_sales_tax;          -- �������Ŋz
        gt_tax_include(ln_inv_header_num)    := lt_tax_include;        -- �ō����z
        gt_red_black_flag(ln_inv_header_num) := lt_red_black_flag;     -- �ԍ��t���O
        gt_cancel_correct(ln_inv_header_num) := lt_cancel_correct;     -- ����E�����敪
        ln_inv_header_num := ln_inv_header_num + 1;                    -- ���o�Ƀw�b�_�����i���o�[�X�V
        lv_order_no_flag  := cv_one;                                   -- ��No.(HHT)�擾�t���O�X�V
--
      END IF;
--
    END LOOP;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END inv_data_compute;
--
  /**********************************************************************************
   * Procedure Name   : inv_data_register
   * Description      : ���o�Ƀf�[�^�o�^(A-3)
   ***********************************************************************************/
  PROCEDURE inv_data_register(
    on_normal_cnt   OUT NUMBER,       --   �w�b�_��������
    on_normal_cnt_l OUT NUMBER,       --   ���א�������
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'inv_data_register'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ����������
    on_normal_cnt   := 0;
    on_normal_cnt_l := 0;
--
    --==============================================================
    -- VD�R�����ʎ���w�b�_�e�[�u���֓o�^
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_order_noh_hht.COUNT
        INSERT INTO xxcos_vd_column_headers
          (
            order_no_hht,                   -- ��No.(HHT)
            digestion_ln_number,            -- �}��
            order_no_ebs,                   -- ��No.(EBS)
            base_code,                      -- ���_�R�[�h
            performance_by_code,            -- ���ю҃R�[�h
            dlv_by_code,                    -- �[�i�҃R�[�h
            hht_invoice_no,                 -- HHT�`�[No.
            dlv_date,                       -- �[�i��
            inspect_date,                   -- ������
            sales_classification,           -- ���㕪�ދ敪
            sales_invoice,                  -- ����`�[�敪
            card_sale_class,                -- �J�[�h���敪
            dlv_time,                       -- ����
            change_out_time_100,            -- ��K�؂ꎞ��100�~
            change_out_time_10,             -- ��K�؂ꎞ��10�~
            customer_number,                -- �ڋq�R�[�h
            dlv_form,                       -- �[�i�`��
            system_class,                   -- �Ƒԋ敪
            invoice_type,                   -- �`�[�敪
            input_class,                    -- ���͋敪
            consumption_tax_class,          -- ����ŋ敪
            total_amount,                   -- ���v���z
            sale_discount_amount,           -- ����l���z
            sales_consumption_tax,          -- �������Ŋz
            tax_include,                    -- �ō����z
            keep_in_code,                   -- �a����R�[�h
            department_screen_class,        -- �S�ݓX��ʎ��
            digestion_vd_rate_maked_date,   -- ����VD�|���쐬�ϔN����
            red_black_flag,                 -- �ԍ��t���O
            forward_flag,                   -- �A�g�t���O
            forward_date,                   -- �A�g���t
            vd_results_forward_flag,        -- �x���_�[�i���я��A�g�σt���O
            cancel_correct_class,           -- ����E�����敪
            created_by,                     -- �쐬��
            creation_date,                  -- �쐬��
            last_updated_by,                -- �ŏI�X�V��
            last_update_date,               -- �ŏI�X�V��
            last_update_login,              -- �ŏI�X�V���O�C��
            request_id,                     -- �v��ID
            program_application_id,         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            program_id,                     -- �R���J�����g�E�v���O����ID
            program_update_date             -- �v���O�����X�V��
          )
        VALUES
          (
            gt_order_noh_hht(i),            -- ��No.(HHT)
            0,                              -- �}��
            NULL,                           -- ��No.(EBS)
            gt_base_code(i),                -- ���_�R�[�h
            gt_perform_code(i),             -- ���ю҃R�[�h
            gt_dlv_code(i),                 -- �[�i�҃R�[�h
            gt_invoice_no(i),               -- HHT�`�[No.
            gt_dlv_date(i),                 -- �[�i��
            gt_inspect_date(i),             -- ������
            NULL,                           -- ���㕪�ދ敪
            NULL,                           -- ����`�[�敪
            NULL,                           -- �J�[�h���敪
            NULL,                           -- ����
            NULL,                           -- ��K�؂ꎞ��100�~
            NULL,                           -- ��K�؂ꎞ��10�~
            gt_cus_number(i),               -- �ڋq�R�[�h
            NULL,                           -- �[�i�`��
            gt_system_class(i),             -- �Ƒԋ敪
            gt_invoice_type(i),             -- �`�[�敪
--****************************** 2009/04/22 1.7 T.Kitajima MOD START ******************************--
--            NULL,                           -- ���͋敪
            gt_input_class(i),              -- ���͋敪
--****************************** 2009/04/22 1.7 T.Kitajima MOD  END  ******************************--
            gt_tax_class(i),                -- ����ŋ敪
            gt_total_amount(i),             -- ���v���z
            NULL,                           -- ����l���z
            gt_sales_tax(i),                -- �������Ŋz
            gt_tax_include(i),              -- �ō����z
            NULL,                           -- �a����R�[�h
            NULL,                           -- �S�ݓX��ʎ��
            NULL,                           -- ����VD�|���쐬�ϔN����
            gt_red_black_flag(i),           -- �ԍ��t���O
            'N',                            -- �A�g�t���O
            NULL,                           -- �A�g���t
            'N',                            -- �x���_�[�i���я��A�g�σt���O
            gt_cancel_correct(i),           -- ����E�����敪
            cn_created_by,                  -- �쐬��
            cd_creation_date,               -- �쐬��
            cn_last_updated_by,             -- �ŏI�X�V��
            cd_last_update_date,            -- �ŏI�X�V��
            cn_last_update_login,           -- �ŏI�X�V���O�C��
            cn_request_id,                  -- �v��ID
            cn_program_application_id,      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                  -- �R���J�����g�E�v���O����ID
            cd_program_update_date          -- �v���O�����X�V��
          );
--
      -- �w�b�_���������Z�b�g
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD START ******************************************
--      on_normal_cnt := SQL%ROWCOUNT;
      on_normal_cnt := gt_order_noh_hht.COUNT;
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD  END  ******************************************
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- VD�R�����ʎ�����׃e�[�u���֓o�^
    --==============================================================
    BEGIN
      FORALL i IN 1..gt_order_nol_hht.COUNT
        INSERT INTO xxcos_vd_column_lines
          (
            order_no_hht,                   -- ��No.(HHT)
            line_no_hht,                    -- �sNo.(HHT)
            digestion_ln_number,            -- �}��
            order_no_ebs,                   -- ��No.(EBS)
            line_number_ebs,                -- ���הԍ�(EBS)
            item_code_self,                 -- �i���R�[�h(����)
            content,                        -- ����
            inventory_item_id,              -- �i��ID
            standard_unit,                  -- ��P��
            case_number,                    -- �P�[�X��
            quantity,                       -- ����
            sale_class,                     -- ����敪
            wholesale_unit_ploce,           -- ���P��
            selling_price,                  -- ���P��
            column_no,                      -- �R����No.
            h_and_c,                        -- H/C
            sold_out_class,                 -- ���؋敪
            sold_out_time,                  -- ���؎���
            replenish_number,               -- ��[��
            cash_and_card,                  -- �����E�J�[�h���p�z
            created_by,                     -- �쐬��
            creation_date,                  -- �쐬��
            last_updated_by,                -- �ŏI�X�V��
            last_update_date,               -- �ŏI�X�V��
            last_update_login,              -- �ŏI�X�V���O�C��
            request_id,                     -- �v��ID
            program_application_id,         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            program_id,                     -- �R���J�����g�E�v���O����ID
            program_update_date             -- �v���O�����X�V��
          )
        VALUES
          (
            gt_order_nol_hht(i),               -- ��No.(HHT)
            gt_line_no_hht(i),                 -- �sNo.(HHT)
            0,                              -- �}��
            NULL,                           -- ��No.(EBS)
            NULL,                           -- ���הԍ�(EBS)
            gt_item_code_self(i),              -- �i���R�[�h(����)
            gt_content(i),                     -- ����
            gt_item_id(i),                     -- �i��ID
            gt_standard_unit(i),               -- ��P��
            gt_case_number(i),                 -- �P�[�X��
            gt_quantity(i),                    -- ����
            NULL,                           -- ����敪
            gt_wholesale(i),                   -- ���P��
            NULL,                           -- ���P��
            gt_column_no(i),                   -- �R����No.
            gt_h_and_c(i),                     -- H/C
            NULL,                           -- ���؋敪
            NULL,                           -- ���؎���
            gt_replenish_num(i),               -- ��[��
            NULL,                           -- �����E�J�[�h���p�z
            cn_created_by,                  -- �쐬��
            cd_creation_date,               -- �쐬��
            cn_last_updated_by,             -- �ŏI�X�V��
            cd_last_update_date,            -- �ŏI�X�V��
            cn_last_update_login,           -- �ŏI�X�V���O�C��
            cn_request_id,                  -- �v��ID
            cn_program_application_id,      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            cn_program_id,                  -- �R���J�����g�E�v���O����ID
            cd_program_update_date          -- �v���O�����X�V��
          );
--
      -- ���א��������Z�b�g
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD START ******************************************
--      on_normal_cnt_l := SQL%ROWCOUNT;
      on_normal_cnt_l := gt_order_nol_hht.COUNT;
--******************** 2009/05/26 Ver1.9  T.Kitajima MOD  END  ******************************************
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdl_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END inv_data_register;
--
  /**********************************************************************************
   * Procedure Name   : dlv_data_register
   * Description      : �[�i�f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE dlv_data_register(
    on_target_cnt   OUT NUMBER,       --   �w�b�_���o����
    on_target_cnt_l OUT NUMBER,       --   ���ג��o����
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'dlv_data_register'; -- �v���O������
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
    lt_order_no_hht                    xxcos_vd_column_headers.order_no_hht%TYPE;      --�`�[No.(HHT)
    lt_cancel_correct_class            xxcos_vd_column_headers.cancel_correct_class%TYPE; --�}�ԍő�l�̎���������敪
    lt_min_digestion_ln_number         xxcos_vd_column_headers.digestion_ln_number%TYPE;  --�}�ԍŏ��l
    ln_vd_data_count                   NUMBER;
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
    lt_inv_row_id                      ROWID;                                             -- �Ώۃw�b�_�sID
    lt_inv_order_no_hht                xxcos_dlv_headers.order_no_hht%TYPE;               -- ��No.(HHT)
    lt_inv_digestion_ln_number         xxcos_dlv_headers.digestion_ln_number%TYPE;        -- �}��
    lt_inv_hht_invoice_no              xxcos_dlv_headers.hht_invoice_no%TYPE;             -- HHT�`�[No.
    lt_lock_brak_order_no_hht          xxcos_dlv_headers.order_no_hht%TYPE;               -- ���b�N�ςݎ�No.(HHT)
    lt_lock_err_order_no_hht          xxcos_dlv_headers.order_no_hht%TYPE;                -- ���b�N�G���[��No.(HHT)
    lt_data_count                      NUMBER;
    lt_dlv_line_count                  NUMBER;
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
--****************************** 2014/10/16 1.18 MOD START ******************************
    lt_inv_customer_number             xxcos_dlv_headers.customer_number%TYPE;            -- �ڋq�R�[�h
    lt_inv_dlv_by_code                 xxcos_dlv_headers.dlv_by_code%TYPE;                -- �[�i�҃R�[�h
    lt_inv_dlv_date                    xxcos_dlv_headers.dlv_date%TYPE;                   -- �[�i��
    lt_inv_dlv_date_yyyymmdd           VARCHAR2(10);                                      -- �[�i���i���b�Z�[�W�o�͗p�j
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    lt_inv_base_code                   xxcos_dlv_headers.base_code%TYPE;                  -- ���_�R�[�h
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
    -- *** ���[�J���E�J�[�\�� ***
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD START ******************************************--
    -- �Ώۓ`�[�擾�J�[�\��
    CURSOR get_inv_cur
    IS
      SELECT /*+
               leading (head)
               INDEX   ( HEAD XXCOS_DLV_HEADERS_N02 )
               USE_NL  (LINE)
             */
             DISTINCT
             head.ROWID                      row_id                    -- �sID
            ,head.order_no_hht               order_no_hht              -- ��No.(HHT)
            ,head.digestion_ln_number        digestion_ln_number       -- �}��
            ,head.hht_invoice_no             hht_invoice_no            -- HHT�`�[No.
--****************************** 2014/10/16 1.18 MOD START ******************************
            ,head.customer_number            customer_number           -- �ڋq�R�[�h
            ,head.dlv_by_code                dlv_by_code               -- �[�i�҃R�[�h
            ,head.dlv_date                   dlv_date                  -- �[�i��
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
            ,head.base_code                  base_code                 -- ���_�R�[�h
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
      FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_
            ,xxcos_dlv_lines    line         -- �[�i���׃e�[�u��
      WHERE  head.order_no_hht         = line.order_no_hht         -- �w�b�_.��No.(HHT)������.��No.(HHT)
      AND    head.digestion_ln_number  = line.digestion_ln_number  -- �w�b�_.�}�ԁ�����.�}��
      AND    head.results_forward_flag = cv_default                -- �̔����јA�g�ς݃t���O��0
      AND    head.input_class          = cv_input_class            -- ���͋敪��5
      ORDER BY 
             head.order_no_hht,head.digestion_ln_number;
--
    -- �Ώۓ`�[���b�N�擾�J�[�\��
    CURSOR get_inv_lock_cur
    IS
      SELECT 'Y'
      FROM   xxcos_dlv_headers  head
             ,xxcos_dlv_lines   line
      WHERE  head.order_no_hht         = line.order_no_hht         -- �w�b�_.��No.(HHT)������.��No.(HHT)
      AND    head.digestion_ln_number  = line.digestion_ln_number  -- �w�b�_.�}�ԁ�����.�}��
      AND    head.order_no_hht         = lt_inv_order_no_hht
      FOR UPDATE OF head.order_no_hht,line.order_no_hht NOWAIT;
--
    -- ���׏��擾�J�[�\��
    CURSOR get_line_cur
    IS
      SELECT line.order_no_hht           order_no_hht        -- ��No.(HHT)
             ,line.line_no_hht            line_no_hht         -- �sNo.(HHT)
             ,line.digestion_ln_number    digestion_ln_number -- �}��
             ,line.order_no_ebs           order_no_ebs        -- ��No.(EBS)
             ,line.line_number_ebs        line_number_ebs     -- ���הԍ�(EBS)
             ,line.item_code_self         item_code_self      -- �i���R�[�h(����)
             ,line.content                content             -- ����
             ,line.inventory_item_id      inventory_item_id   -- �i��ID
             ,line.standard_unit          standard_unit       -- ��P��
             ,line.case_number            case_number         -- �P�[�X��
             ,DECODE( head.red_black_flag, '0', line.quantity * -1, line.quantity )
                                         quantity            -- ����
             ,line.sale_class             sale_class          -- ����敪
             ,line.wholesale_unit_ploce   wholesale_unit_ploce  -- ���P��
             ,line.selling_price          selling_price       -- ���P��
             ,line.column_no              column_no           -- �R����No.
             ,line.h_and_c                h_and_c             -- H/C
             ,line.sold_out_class         sold_out_class      -- ���؋敪
             ,line.sold_out_time          sold_out_time       -- ���؎���
             ,DECODE( head.red_black_flag, '0', line.replenish_number * -1, line.replenish_number )
                                         replenish_number    -- ��[��
             ,line.cash_and_card          cash_and_card       -- �����E�J�[�h���p�z
             ,cn_created_by               cn_created_by       -- �쐬��
             ,cd_creation_date            creation_date       -- �쐬��
             ,cn_last_updated_by          last_updated_by     -- �ŏI�X�V��
             ,cd_last_update_date         last_update_date    -- �ŏI�X�V��
             ,cn_last_update_login        last_update_login   -- �ŏI�X�V���O�C��
             ,cn_request_id               request_id          -- �v��ID
             ,cn_program_application_id   program_application_id-- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,cn_program_id               program_id          -- �R���J�����g�E�v���O����ID
             ,cd_program_update_date      program_update_date -- �v���O�����X�V��
      FROM   xxcos_dlv_headers  head      -- �[�i�w�b�_�e�[�u��
             ,xxcos_dlv_lines    line      -- �[�i���׃e�[�u��
      WHERE  head.order_no_hht         = line.order_no_hht         -- �w�b�_.��No.(HHT)������.��No.(HHT)
      AND    head.digestion_ln_number  = line.digestion_ln_number  -- �w�b�_.�}�ԁ�����.�}��
      AND    head.order_no_hht         = lt_inv_order_no_hht
      AND    line.digestion_ln_number  = lt_inv_digestion_ln_number;
--
-- ******************* 2009/07/17 Ver1.11 N.Maeda ADD  END  ******************************************--
-- ******************* 2009/07/17 Ver1.11 N.Maeda DEL START ******************************************--
--    CURSOR headers_lock_cur
--    IS
----******************** 2009/05/07 Ver1.8  N.Maeda MOD START ******************************************
----      SELECT head.creation_date  creation_date
----      FROM   xxcos_dlv_headers   head                     -- �[�i�w�b�_�e�[�u��
----      WHERE  head.results_forward_flag = cv_default       -- �̔����јA�g�ς݃t���O��0
----      AND    head.input_class          = cv_input_class   -- ���͋敪��5
--      SELECT head.order_no_hht               order_no_hht,              -- ��No.(HHT)
--             head.digestion_ln_number        digestion_ln_number,       -- �}��
--             head.order_no_ebs               order_no_ebs,              -- ��No.(EBS)
--             head.base_code                  base_code,                 -- ���_�R�[�h
--             head.performance_by_code        performance_by_code,       -- ���ю҃R�[�h
--             head.dlv_by_code                dlv_by_code,               -- �[�i�҃R�[�h
--             head.hht_invoice_no             hht_invoice_no,            -- HHT�`�[No.
--             head.dlv_date                   dlv_date,                  -- �[�i��
--             head.inspect_date               inspect_date,              -- ������
--             head.sales_classification       sales_classification,      -- ���㕪�ދ敪
--             head.sales_invoice              sales_invoice,             -- ����`�[�敪
--             head.card_sale_class            card_sale_class,           -- �J�[�h���敪
--             head.dlv_time                   dlv_time,                  -- ����
--             head.change_out_time_100        change_out_time_100,       -- ��K�؂ꎞ��100�~
--             head.change_out_time_10         change_out_time_10,        -- ��K�؂ꎞ��10�~
--             head.customer_number            customer_number,           -- �ڋq�R�[�h
--             NULL                            dlv_form,                  -- �[�i�`��
--             head.system_class               system_class,              -- �Ƒԋ敪
--             NULL                            invoice_type,              -- �`�[�敪
--             head.input_class                input_class,               -- ���͋敪
--             head.consumption_tax_class      consumption_tax_class,     -- ����ŋ敪
--             head.total_amount               total_amount,              -- ���v���z
--             head.sale_discount_amount       sale_discount_amount,      -- ����l���z
--             head.sales_consumption_tax      sales_consumption_tax,     -- �������Ŋz
--             head.tax_include                tax_include,               -- �ō����z
--             head.keep_in_code               keep_in_code,              -- �a����R�[�h
--             head.department_screen_class    department_screen_class,   -- �S�ݓX��ʎ��
--             NULL                            digestion_vd_rate_maked_date, -- ����VD�|���쐬�N����
--             head.red_black_flag             red_black_flag,            -- �ԍ��t���O
--             'N'                             forward_flag,              -- �A�g�t���O
--             NULL                            forward_date,              -- �A�g���t
--             'N'                             vd_results_forward_flag,   -- �x���_�[�i���я��A�g�σt���O
--             head.cancel_correct_class       cancel_correct_class,       -- ����E�����敪
--             cn_created_by                   created_by,                  -- �쐬��
--             cd_creation_date                creation_date,               -- �쐬��
--             cn_last_updated_by              last_updated_by,             -- �ŏI�X�V��
--             cd_last_update_date             last_update_date,            -- �ŏI�X�V��
--             cn_last_update_login            last_update_login,           -- �ŏI�X�V���O�C��
--             cn_request_id                   request_id,                  -- �v��ID
--             cn_program_application_id       program_application_id,      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--             cn_program_id                   program_id,                  -- �R���J�����g�E�v���O����ID
--             cd_program_update_date          program_update_date,         -- �v���O�����X�V��
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
--             rowid                           h_rowid                       -- ���R�[�hID
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************
--      FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
--      WHERE  head.results_forward_flag = cv_default       -- �̔����јA�g�ς݃t���O��0
--      AND    head.input_class          = cv_input_class   -- ���͋敪��5
----******************** 2009/05/07 Ver1.8  N.Maeda MOD  END  ******************************************
----    FOR UPDATE NOWAIT;
----
--    CURSOR lines_lock_cur
--    IS
--      SELECT line.creation_date  creation_date
--      FROM   xxcos_dlv_headers   head,                             -- �[�i�w�b�_�e�[�u��
--             xxcos_dlv_lines     line                              -- �[�i���׃e�[�u��
--      WHERE  head.results_forward_flag = cv_default                -- �̔����јA�g�ς݃t���O��0
--      AND    head.input_class          = cv_input_class            -- ���͋敪��5
--      AND    head.order_no_hht         = line.order_no_hht         -- �w�b�_.��No.(HHT)������.��No.(HHT)
--      AND    head.digestion_ln_number  = line.digestion_ln_number  -- �w�b�_.�}�ԁ�����.�}��
--    FOR UPDATE NOWAIT;
----
-- ******************* 2009/07/17 Ver1.11 N.Maeda DEL  END  ******************************************--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
    CURSOR vd_lock_cur
    IS
      SELECT xvch.ROWID
      FROM   xxcos_vd_column_headers xvch
      WHERE  xvch.order_no_hht = lt_inv_order_no_hht
    FOR UPDATE OF xvch.order_no_hht NOWAIT;
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--
    -- *** ���[�J���E���R�[�h ***
--
--****************************** 2014/10/16 1.18 MOD START ******************************
    ln_rs_cnt              NUMBER;
    --�[�i�҃R�[�h��O
    dlv_by_code_expt       EXCEPTION;
--****************************** 2014/10/16 1.18 MOD END   ******************************
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
    -- ���o����������
    on_target_cnt   := 0;
    on_target_cnt_l := 0;
--****************************** 2014/10/16 1.18 MOD START ******************************
    ln_rs_cnt       := 0;
--****************************** 2014/10/16 1.18 MOD END   ******************************
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
    ln_vd_data_count:= 0;
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--
--******************** 2009/07/17 Ver1.11  N.Maeda MOD START ******************************************
--
    lt_data_count   := 0;
    lt_dlv_line_count := 0;
    lt_lock_brak_order_no_hht := 0;
    lt_lock_err_order_no_hht  := 0;
--
    --==============================================================
    -- �Ώۓ`�[���擾
    --==============================================================
    OPEN  get_inv_cur;
    FETCH get_inv_cur BULK COLLECT INTO gt_inv_data_tab;
    CLOSE get_inv_cur;
--
    <<get_inv_loop>>
    FOR i IN 1..gt_inv_data_tab.COUNT LOOP
--
      on_target_cnt   := gt_inv_data_tab.COUNT;
      -- �Ώۓ`�[���Z�b�g
      lt_inv_row_id                := gt_inv_data_tab(i).row_id;               -- �sID
      lt_inv_order_no_hht          := gt_inv_data_tab(i).order_no_hht;         -- ��No.(HHT)
      lt_inv_digestion_ln_number   := gt_inv_data_tab(i).digestion_ln_number;  -- �}��
      lt_inv_hht_invoice_no        := gt_inv_data_tab(i).hht_invoice_no;       -- HHT�`�[NO.
--****************************** 2014/10/16 1.18 MOD START ******************************
      lt_inv_customer_number       := gt_inv_data_tab(i).customer_number;      -- �ڋq�R�[�h
      lt_inv_dlv_by_code           := gt_inv_data_tab(i).dlv_by_code;          -- �[�i�҃R�[�h
      lt_inv_dlv_date              := gt_inv_data_tab(i).dlv_date;             -- �[�i��
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
      lt_inv_base_code             := gt_inv_data_tab(i).base_code;            -- ���_�R�[�h
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
      BEGIN
        -- ===================
        -- ���גP�ʃ��b�N�擾
        -- ===================
        IF ( lt_lock_err_order_no_hht  <> lt_inv_order_no_hht ) THEN
--
          IF ( lt_lock_brak_order_no_hht <> lt_inv_order_no_hht ) THEN
--
            OPEN  get_inv_lock_cur;
            CLOSE get_inv_lock_cur;
--
          END IF;
--
          --���b�N�ς݃L�[�f�[�^
          lt_lock_brak_order_no_hht := lt_inv_order_no_hht;
--****************************** 2014/10/16 1.18 MOD START ******************************
          -- ���o����������
          ln_rs_cnt       := 0;
          BEGIN
            SELECT COUNT(1)
            INTO   ln_rs_cnt
            FROM   xxcos_rs_info2_v  xriv
            WHERE  xriv.employee_number                                   =  lt_inv_dlv_by_code
            AND    NVL(xriv.effective_start_date      ,lt_inv_dlv_date)  <=  lt_inv_dlv_date
            AND    NVL(xriv.effective_end_date        ,lt_inv_dlv_date)  >=  lt_inv_dlv_date
            AND    NVL(xriv.per_effective_start_date  ,lt_inv_dlv_date)  <=  lt_inv_dlv_date
            AND    NVL(xriv.per_effective_end_date    ,lt_inv_dlv_date)  >=  lt_inv_dlv_date
            AND    NVL(xriv.paa_effective_start_date  ,lt_inv_dlv_date)  <=  lt_inv_dlv_date
            AND    NVL(xriv.paa_effective_end_date    ,lt_inv_dlv_date)  >=  lt_inv_dlv_date
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
          --
          IF (ln_rs_cnt = 0 ) THEN
            RAISE dlv_by_code_expt;
          END IF;
--****************************** 2014/10/16 1.18 MOD END   ******************************
          --�Y�����̃J�E���g�A�b�v
          lt_data_count := lt_data_count + 1;
--
--
          -- ========================
          -- �w�b�_�f�[�^�擾
          -- ========================
          SELECT head.order_no_hht               order_no_hht,              -- 1.��No.(HHT)
                 head.digestion_ln_number        digestion_ln_number,       -- 2.�}��
                 head.order_no_ebs               order_no_ebs,              -- 3.��No.(EBS)
                 head.base_code                  base_code,                 -- 4.���_�R�[�h
                 head.performance_by_code        performance_by_code,       -- 5.���ю҃R�[�h
                 head.dlv_by_code                dlv_by_code,               -- 6.�[�i�҃R�[�h
                 head.hht_invoice_no             hht_invoice_no,            -- 7.HHT�`�[No.
                 head.dlv_date                   dlv_date,                  -- 8.�[�i��
                 head.inspect_date               inspect_date,              -- 9.������
                 head.sales_classification       sales_classification,      -- 10.���㕪�ދ敪
                 head.sales_invoice              sales_invoice,             -- 11.����`�[�敪
                 head.card_sale_class            card_sale_class,           -- 12.�J�[�h���敪
                 head.dlv_time                   dlv_time,                  -- 13.����
                 head.change_out_time_100        change_out_time_100,       -- 14.��K�؂ꎞ��100�~
                 head.change_out_time_10         change_out_time_10,        -- 15.��K�؂ꎞ��10�~
                 head.customer_number            customer_number,           -- 16.�ڋq�R�[�h
                 NULL                            dlv_form,                  -- 17.�[�i�`��
                 head.system_class               system_class,              -- 18.�Ƒԋ敪
                 NULL                            invoice_type,              -- 19.�`�[�敪
                 head.input_class                input_class,               -- 20.���͋敪
                 head.consumption_tax_class      consumption_tax_class,     -- 21.����ŋ敪
                 head.total_amount               total_amount,              -- 22.���v���z
                 head.sale_discount_amount       sale_discount_amount,      -- 23.����l���z
                 head.sales_consumption_tax      sales_consumption_tax,     -- 24.�������Ŋz
                 head.tax_include                tax_include,               -- 25.�ō����z
                 head.keep_in_code               keep_in_code,              -- 26.�a����R�[�h
                 head.department_screen_class    department_screen_class,   -- 27.�S�ݓX��ʎ��
                 NULL                            digestion_vd_rate_maked_date, -- 28.����VD�|���쐬�N����
                 head.red_black_flag             red_black_flag,            -- 29.�ԍ��t���O
                 'N'                             forward_flag,              -- 30.�A�g�t���O
                 NULL                            forward_date,              -- 31.�A�g���t
                 'N'                             vd_results_forward_flag,   -- 32.�x���_�[�i���я��A�g�σt���O
                 head.cancel_correct_class       cancel_correct_class,      -- 33.����E�����敪
                 cn_created_by                   created_by,                -- 34.�쐬��
                 cd_creation_date                creation_date,             -- 35.�쐬��
                 cn_last_updated_by              last_updated_by,           -- 36.�ŏI�X�V��
                 cd_last_update_date             last_update_date,          -- 37.�ŏI�X�V��
                 cn_last_update_login            last_update_login,         -- 38.�ŏI�X�V���O�C��
                 cn_request_id                   request_id,                -- 39.�v��ID
                 cn_program_application_id       program_application_id,    -- 40.�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                 cn_program_id                   program_id,                -- 41.�R���J�����g�E�v���O����ID
                 cd_program_update_date          program_update_date,       -- 42.�v���O�����X�V��
                 lt_inv_row_id                   row_id                     -- 43.�sID
          INTO   gt_dev_set_order_noh_hht(lt_data_count)
                 ,gt_dev_set_digestion_ln(lt_data_count)
                 ,gt_dev_set_order_no_ebs(lt_data_count)
                 ,gt_dev_set_base_code(lt_data_count)
                 ,gt_dev_set_perform_code(lt_data_count)
                 ,gt_dev_set_dlv_code(lt_data_count)
                 ,gt_dev_set_invoice_no(lt_data_count)
                 ,gt_dev_set_dlv_date(lt_data_count)
                 ,gt_dev_set_inspect_date(lt_data_count)
                 ,gt_dev_set_sales_classif(lt_data_count)
                 ,gt_dev_set_sales_invoice(lt_data_count)
                 ,gt_dev_set_card_sale_class(lt_data_count)
                 ,gt_dev_set_dlv_time(lt_data_count)
                 ,gt_dev_set_out_time_100(lt_data_count)
                 ,gt_dev_set_out_time_10(lt_data_count)
                 ,gt_dev_set_cus_number(lt_data_count)
                 ,gt_dev_set_dlv_form(lt_data_count)
                 ,gt_dev_set_system_class(lt_data_count)
                 ,gt_dev_set_invoice_type(lt_data_count)
                 ,gt_dev_set_input_class(lt_data_count)
                 ,gt_dev_set_tax_class(lt_data_count)
                 ,gt_dev_set_total_amount(lt_data_count)
                 ,gt_dev_set_sale_discount_a(lt_data_count)
                 ,gt_dev_set_sales_tax(lt_data_count)
                 ,gt_dev_set_tax_include(lt_data_count)
                 ,gt_dev_set_keep_in_code(lt_data_count)
                 ,gt_dev_set_depart_sc_clas(lt_data_count)
                 ,gt_dev_set_dig_vd_r_mak_d(lt_data_count)
                 ,gt_dev_set_red_black_flag(lt_data_count)
                 ,gt_dev_set_forward_flag(lt_data_count)
                 ,gt_dev_set_forward_date(lt_data_count)
                 ,gt_dev_set_vd_results_for_f(lt_data_count)
                 ,gt_dev_set_cancel_correct(lt_data_count)
                 ,gt_dev_set_created_by(lt_data_count)
                 ,gt_dev_set_creation_date(lt_data_count)
                 ,gt_dev_set_last_updated_by(lt_data_count)
                 ,gt_dev_set_last_update_date(lt_data_count)
                 ,gt_dev_set_last_update_logi(lt_data_count)
                 ,gt_dev_set_request_id(lt_data_count)
                 ,gt_dev_set_program_appli_id(lt_data_count)
                 ,gt_dev_set_program_id(lt_data_count)
                 ,gt_dev_set_program_update_d(lt_data_count)
                 ,gt_dlv_headers_row_id(lt_data_count)
          FROM   xxcos_dlv_headers         head   -- �[�i�w�b�_
          WHERE  head.ROWID = lt_inv_row_id;
--
          -- ================================
          -- ��������敪�ŐV�l
          -- ================================
          BEGIN
            SELECT head.cancel_correct_class
            INTO   lt_cancel_correct_class
            FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
            WHERE  head.order_no_hht         = lt_inv_order_no_hht
            AND    head.results_forward_flag = cv_default       -- �̔����јA�g�ς݃t���O��0
            AND    head.input_class          = cv_input_class   -- ���͋敪��5
            AND    head.cancel_correct_class IS NOT NULL
            AND    head.digestion_ln_number  = ( SELECT
                                                 MAX( head.digestion_ln_number )
                                               FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
                                               WHERE  head.order_no_hht         = lt_inv_order_no_hht
                                               AND    head.results_forward_flag = cv_default
                                               AND    head.input_class          = cv_input_class );
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
--
          IF ( lt_cancel_correct_class IS NOT NULL ) THEN
            gt_dev_set_cancel_correct(lt_data_count) := lt_cancel_correct_class;
          END IF;
--
          BEGIN
            SELECT MIN( head.digestion_ln_number )
            INTO   lt_min_digestion_ln_number
            FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
            WHERE head.order_no_hht          = lt_inv_order_no_hht
            AND    head.results_forward_flag = cv_default
            AND    head.input_class          = cv_input_class;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
--
          IF ( lt_min_digestion_ln_number IS NOT NULL ) AND ( lt_min_digestion_ln_number <> '0' ) THEN
            <<vd_loop>>
            FOR vd_lock_rec IN vd_lock_cur LOOP
              ln_vd_data_count := ln_vd_data_count + 1;
              gt_vd_row_id(ln_vd_data_count)          := vd_lock_rec.ROWID;
              gt_vd_can_cor_class(ln_vd_data_count)   := lt_cancel_correct_class;
            END LOOP vd_loop;
          END IF;
--
          -- =============
          -- ���׏��擾
          -- =============
          <<get_line_loop>>
          FOR get_line_rec IN get_line_cur LOOP
--
            -- ���׏�񌏐��J�E���g�A�b�v
            lt_dlv_line_count := lt_dlv_line_count + 1;
            -- �ϐ��փf�[�^���Z�b�g
            gt_lines_tab(lt_dlv_line_count) := get_line_rec;
--
          END LOOP get_line_loop;
--
        ELSE
--
          -- �X�L�b�v�����J�E���g�A�b�v
          gn_warn_cnt := gn_warn_cnt + 1;
        END IF;
--
      EXCEPTION
        -- ���b�N�G���[
        WHEN lock_expt THEN
          -- �X�L�b�v�����J�E���g�A�b�v
          gn_warn_cnt := gn_warn_cnt + 1;
          -- ���b�N�G���[�E�L�[�f�[�^�Z�b�g
          lt_lock_err_order_no_hht := lt_inv_order_no_hht;
          -- ���b�N�G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application,            --�A�v���P�[�V�����Z�k��
                         iv_name          => cv_data_loc,               --���b�Z�[�W�R�[�h
                         iv_token_name1   => cv_tkn_order_number,       --�g�[�N���R�[�h1
                         iv_token_value1  => lt_inv_order_no_hht,       --��No.(HHT)
                         iv_token_name2   => cv_invoice_no,             --�g�[�N���R�[�h2
                         iv_token_value2  => lt_inv_hht_invoice_no);    --HHT�`�[NO.
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
--****************************** 2014/10/16 1.18 MOD START ******************************
--
        WHEN dlv_by_code_expt THEN
          -- �G���[���b�Z�[�W��ǉ����邱��
          gn_warn_cnt := gn_warn_cnt + 1;
          -- �\���p��DATE�^��VARCHAR�^��
          lt_inv_dlv_date_yyyymmdd  := TO_CHAR(lt_inv_dlv_date,'YYYY/MM/DD');
          -- �[�i�҃R�[�h�L�����`�F�b�N�E���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_application,                             --�A�v���P�[�V�����Z�k��
                         iv_name          => cv_empl_effect,                             --���b�Z�[�W�R�[�h
                         iv_token_name1   => cv_hht_invoice_no,                          -- �g�[�N���R�[�h1
                         iv_token_value1  => lt_inv_hht_invoice_no,                      -- HHT�`�[No.
                         iv_token_name2   => cv_customer_number,                         -- �g�[�N���R�[�h2
                         iv_token_value2  => lt_inv_customer_number,                     -- �ڋq�R�[�h
                         iv_token_name3   => cv_dlv_by_code,                             -- �g�[�N���R�[�h3
                         iv_token_value3  => lt_inv_dlv_by_code,                         -- �[�i�҃R�[�h
                         iv_token_name4   => cv_dlv_date,                                -- �g�[�N���R�[�h4
                         iv_token_value4  => lt_inv_dlv_date_yyyymmdd);                  -- �[�i���i���b�Z�[�W�o�͗p�j
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
          FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errmsg);
--
--****************************** 2014/10/16 1.18 MOD END   ******************************
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
          -- �L�[���ҏW
          xxcos_common_pkg.makeup_key_info(
              iv_item_name1     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv )         --  ���ږ��̂P
            , iv_item_name2     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_hht_inv_no )  --  ���ږ��̂Q
            , iv_item_name3     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_cus_code )    --  ���ږ��̂R
            , iv_item_name4     =>  xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_date )    --  ���ږ��̂S
            , iv_data_value1    =>  lt_inv_dlv_by_code                         --  �[�i�҃R�[�h
            , iv_data_value2    =>  lt_inv_hht_invoice_no                      --  HHT�`�[No.
            , iv_data_value3    =>  lt_inv_customer_number                     --  �ڋq�R�[�h
            , iv_data_value4    =>  lt_inv_dlv_date_yyyymmdd                   --  �[�i��
            , ov_key_info       =>  gv_tkn4                                    --  �L�[���
            , ov_errbuf         =>  lv_errbuf                                  --  �G���[�E���b�Z�[�W�G���[
            , ov_retcode        =>  lv_retcode                                 --  ���^�[���E�R�[�h
            , ov_errmsg         =>  lv_errmsg                                  --  ���[�U�[�E�G���[�E���b�Z�[�W
          );
          -- �ėp�G���[���X�g�p�L�[���ێ�
          IF (gv_prm_gen_err_out_flag = cv_tkn_yes) THEN
            --  �ėp�G���[���X�g�o�͗v�̏ꍇ
            gn_msg_cnt  :=  gn_msg_cnt + 1;
            --  �ėp�G���[���X�g�p�L�[���
            --  �[�i���_
            gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  lt_inv_base_code;
            --  �G���[���b�Z�[�W��
            gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  cv_empl_effect;
            --  �L�[���b�Z�[�W
            gt_err_key_msg_tab(gn_msg_cnt).message_text   :=  SUBSTRB(gv_tkn4, 1, 2000);
          END IF;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
      END;
--
    END LOOP get_inv_loop;
--
    BEGIN
      FORALL i IN 1..gt_dev_set_order_noh_hht.COUNT
        INSERT INTO
          xxcos_vd_column_headers
            (
                 order_no_hht,                   -- ��No.(HHT)
                 digestion_ln_number,            -- �}��
                 order_no_ebs,                   -- ��No.(EBS)
                 base_code,                      -- ���_�R�[�h
                 performance_by_code,            -- ���ю҃R�[�h
                 dlv_by_code,                    -- �[�i�҃R�[�h
                 hht_invoice_no,                 -- HHT�`�[No.
                 dlv_date,                       -- �[�i��
                 inspect_date,                   -- ������
                 sales_classification,           -- ���㕪�ދ敪
                 sales_invoice,                  -- ����`�[�敪
                 card_sale_class,                -- �J�[�h���敪
                 dlv_time,                       -- ����
                 change_out_time_100,            -- ��K�؂ꎞ��100�~
                 change_out_time_10,             -- ��K�؂ꎞ��10�~
                 customer_number,                -- �ڋq�R�[�h
                 dlv_form,                       -- �[�i�`��
                 system_class,                   -- �Ƒԋ敪
                 invoice_type,                   -- �`�[�敪
                 input_class,                    -- ���͋敪
                 consumption_tax_class,          -- ����ŋ敪
                 total_amount,                   -- ���v���z
                 sale_discount_amount,           -- ����l���z
                 sales_consumption_tax,          -- �������Ŋz
                 tax_include,                    -- �ō����z
                 keep_in_code,                   -- �a����R�[�h
                 department_screen_class,        -- �S�ݓX��ʎ��
                 digestion_vd_rate_maked_date,   -- ����VD�|���쐬�N����
                 red_black_flag,                 -- �ԍ��t���O
                 forward_flag,                   -- �A�g�t���O
                 forward_date,                   -- �A�g���t
                 vd_results_forward_flag,        -- �x���_�[�i���я��A�g�σt���O
                 cancel_correct_class,           -- ����E�����敪
                 created_by,                     -- �쐬��
                 creation_date,                  -- �쐬��
                 last_updated_by,                -- �ŏI�X�V��
                 last_update_date,               -- �ŏI�X�V��
                 last_update_login,              -- �ŏI�X�V���O�C��
                 request_id,                     -- �v��ID
                 program_application_id,         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                 program_id,                     -- �R���J�����g�E�v���O����ID
                 program_update_date             -- �v���O�����X�V��
            )
        VALUES
            (
                 gt_dev_set_order_noh_hht(i),
                 gt_dev_set_digestion_ln(i),
                 gt_dev_set_order_no_ebs(i),
                 gt_dev_set_base_code(i),
                 gt_dev_set_perform_code(i),
                 gt_dev_set_dlv_code(i),
                 gt_dev_set_invoice_no(i),
                 gt_dev_set_dlv_date(i),
                 gt_dev_set_inspect_date(i),
                 gt_dev_set_sales_classif(i),
                 gt_dev_set_sales_invoice(i),
                 gt_dev_set_card_sale_class(i),
                 gt_dev_set_dlv_time(i),
                 gt_dev_set_out_time_100(i),
                 gt_dev_set_out_time_10(i),
                 gt_dev_set_cus_number(i),
                 gt_dev_set_dlv_form(i),
                 gt_dev_set_system_class(i),
                 gt_dev_set_invoice_type(i),
                 gt_dev_set_input_class(i),
                 gt_dev_set_tax_class(i),
                 gt_dev_set_total_amount(i),
--****************************** 2012/04/24 1.17 MOD START ******************************
--                 gt_dev_set_sales_tax(i),
--                 gt_dev_set_sale_discount_a(i),
                 gt_dev_set_sale_discount_a(i),
                 gt_dev_set_sales_tax(i),
--****************************** 2012/04/24 1.17 MOD END   ******************************
                 gt_dev_set_tax_include(i),
                 gt_dev_set_keep_in_code(i),
                 gt_dev_set_depart_sc_clas(i),
                 gt_dev_set_dig_vd_r_mak_d(i),
                 gt_dev_set_red_black_flag(i),
                 gt_dev_set_forward_flag(i),
                 gt_dev_set_forward_date(i),
                 gt_dev_set_vd_results_for_f(i),
                 gt_dev_set_cancel_correct(i),
                 gt_dev_set_created_by(i),
                 gt_dev_set_creation_date(i),
                 gt_dev_set_last_updated_by(i),
                 gt_dev_set_last_update_date(i),
                 gt_dev_set_last_update_logi(i),
                 gt_dev_set_request_id(i),
                 gt_dev_set_program_appli_id(i),
                 gt_dev_set_program_id(i),
                 gt_dev_set_program_update_d(i)
                 );
         -- �w�b�_�o�^�����Z�b�g
         gt_insert_h_count := gt_dev_set_order_noh_hht.COUNT;
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE insert_err_expt;
    END;
--
     BEGIN
       FORALL l IN 1..gt_lines_tab.COUNT
         INSERT INTO
           xxcos_vd_column_lines
         VALUES
           gt_lines_tab(l);
     EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdl_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE insert_err_expt;
     END;
--
--
--    --==============================================================
--    -- �e�[�u�����b�N
--    --==============================================================
--    OPEN  headers_lock_cur;
----******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
--    FETCH headers_lock_cur BULK COLLECT INTO gt_clm_headers;
----******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--    CLOSE headers_lock_cur;
----
--    OPEN  lines_lock_cur;
--    CLOSE lines_lock_cur;
--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
--    <<headers_loop>>
--    FOR header_id IN 1..gt_clm_headers.COUNT LOOP
--      lt_order_no_hht   :=   gt_clm_headers( header_id ).order_no_hht;              -- ��No.(HHT)
----
--      BEGIN
--        SELECT head.cancel_correct_class
--        INTO   lt_cancel_correct_class
--        FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
--        WHERE  head.order_no_hht         = lt_order_no_hht
--        AND    head.results_forward_flag = cv_default       -- �̔����јA�g�ς݃t���O��0
--        AND    head.input_class          = cv_input_class   -- ���͋敪��5
--        AND    head.cancel_correct_class IS NOT NULL
--        AND    head.digestion_ln_number  = ( SELECT
--                                               MAX( head.digestion_ln_number )
--                                             FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
--                                             WHERE head.order_no_hht          = lt_order_no_hht
--                                             AND    head.results_forward_flag = cv_default
--                                             AND    head.input_class          = cv_input_class );
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--      END;
----
--      IF ( lt_cancel_correct_class IS NOT NULL ) THEN
--        gt_clm_headers( header_id ).cancel_correct_class := lt_cancel_correct_class;
--      END IF;
----
--      BEGIN
--        SELECT MIN( head.digestion_ln_number )
--        INTO   lt_min_digestion_ln_number
--        FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
--        WHERE head.order_no_hht          = lt_order_no_hht
--        AND    head.results_forward_flag = cv_default
--        AND    head.input_class          = cv_input_class;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          NULL;
--      END;
----
--      IF ( lt_min_digestion_ln_number IS NOT NULL ) AND ( lt_min_digestion_ln_number <> '0' ) THEN
--        <<vd_loop>>
--        FOR vd_lock_rec IN vd_lock_cur LOOP
--          ln_vd_data_count := ln_vd_data_count + 1;
--          gt_vd_row_id(ln_vd_data_count)          := vd_lock_rec.ROWID;
--          gt_vd_can_cor_class(ln_vd_data_count)   := lt_cancel_correct_class;
--        END LOOP vd_loop;
--      END IF;
----
--      gt_dev_set_order_noh_hht(header_id)       := gt_clm_headers(header_id).order_no_hht;
--      gt_dev_set_digestion_ln(header_id) := gt_clm_headers(header_id).digestion_ln_number;
--      gt_dev_set_order_no_ebs(header_id)        := gt_clm_headers(header_id).order_no_ebs;
--      gt_dev_set_base_code(header_id)           := gt_clm_headers(header_id).base_code;
--      gt_dev_set_perform_code(header_id)        := gt_clm_headers(header_id).performance_by_code;
--      gt_dev_set_dlv_code(header_id)            := gt_clm_headers(header_id).dlv_by_code;
--      gt_dev_set_invoice_no(header_id)          := gt_clm_headers(header_id).hht_invoice_no;
--      gt_dev_set_dlv_date(header_id)            := gt_clm_headers(header_id).dlv_date;
--      gt_dev_set_inspect_date(header_id)        := gt_clm_headers(header_id).inspect_date;
--      gt_dev_set_sales_classif(header_id) := gt_clm_headers(header_id).sales_classification;
--      gt_dev_set_sales_invoice(header_id)       := gt_clm_headers(header_id).sales_invoice;
--      gt_dev_set_card_sale_class(header_id)     := gt_clm_headers(header_id).card_sale_class;
--      gt_dev_set_dlv_time(header_id)            := gt_clm_headers(header_id).dlv_time;
--      gt_dev_set_out_time_100(header_id) := gt_clm_headers(header_id).change_out_time_100;
--      gt_dev_set_out_time_10(header_id)  := gt_clm_headers(header_id).change_out_time_10;
--      gt_dev_set_cus_number(header_id)          := gt_clm_headers(header_id).customer_number;
--      gt_dev_set_dlv_form(header_id)            := gt_clm_headers(header_id).dlv_form;
--      gt_dev_set_system_class(header_id)        := gt_clm_headers(header_id).system_class;
--      gt_dev_set_invoice_type(header_id)        := gt_clm_headers(header_id).invoice_type;
--      gt_dev_set_input_class(header_id)         := gt_clm_headers(header_id).input_class;
--      gt_dev_set_tax_class(header_id) := gt_clm_headers(header_id).consumption_tax_class;
--      gt_dev_set_total_amount(header_id)        := gt_clm_headers(header_id).total_amount;
--      gt_dev_set_sale_discount_a(header_id) := gt_clm_headers(header_id).sale_discount_amount;
--      gt_dev_set_sales_tax(header_id) := gt_clm_headers(header_id).sales_consumption_tax;
--      gt_dev_set_tax_include(header_id)         := gt_clm_headers(header_id).tax_include;
--      gt_dev_set_keep_in_code(header_id)        := gt_clm_headers(header_id).keep_in_code;
--      gt_dev_set_depart_sc_clas(header_id) := gt_clm_headers(header_id).department_screen_class;
--      gt_dev_set_dig_vd_r_mak_d(header_id) := gt_clm_headers(header_id).digestion_vd_rate_maked_date;
--      gt_dev_set_red_black_flag(header_id)      := gt_clm_headers(header_id).red_black_flag;
--      gt_dev_set_forward_flag(header_id)        := gt_clm_headers(header_id).forward_flag;
--      gt_dev_set_forward_date(header_id)        := gt_clm_headers(header_id).forward_date;
--      gt_dev_set_vd_results_for_f(header_id) := gt_clm_headers(header_id).vd_results_forward_flag;
--      gt_dev_set_cancel_correct(header_id)      := gt_clm_headers(header_id).cancel_correct_class;
--      gt_dev_set_created_by(header_id)          := gt_clm_headers(header_id).created_by;
--      gt_dev_set_creation_date(header_id)       := gt_clm_headers(header_id).creation_date;
--      gt_dev_set_last_updated_by(header_id)     := gt_clm_headers(header_id).last_updated_by;
--      gt_dev_set_last_update_date(header_id)    := gt_clm_headers(header_id).last_update_date;
--      gt_dev_set_last_update_logi(header_id)   := gt_clm_headers(header_id).last_update_login;
--      gt_dev_set_request_id(header_id)          := gt_clm_headers(header_id).request_id;
--      gt_dev_set_program_appli_id(header_id) := gt_clm_headers(header_id).program_application_id;
--      gt_dev_set_program_id(header_id)          := gt_clm_headers(header_id).program_id;
--      gt_dev_set_program_update_d(header_id) := gt_clm_headers(header_id).program_update_date;
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD START ******************************************
--      gt_dlv_headers_row_id(header_id)          := gt_clm_headers(header_id).h_rowid;
----******************** 2009/05/21 Ver1.9  T.Kitajima ADD  END  ******************************************
--    END LOOP headers_loop;
----
----
----******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
----
--    --==============================================================
--    -- VD�R�����ʎ���w�b�_�e�[�u���֓o�^
--    --==============================================================
--    BEGIN
----******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
--      FORALL i IN 1..gt_dev_set_order_noh_hht.COUNT
----******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
--        INSERT INTO
--          xxcos_vd_column_headers
--            (
--                 order_no_hht,                   -- ��No.(HHT)
--                 digestion_ln_number,            -- �}��
--                 order_no_ebs,                   -- ��No.(EBS)
--                 base_code,                      -- ���_�R�[�h
--                 performance_by_code,            -- ���ю҃R�[�h
--                 dlv_by_code,                    -- �[�i�҃R�[�h
--                 hht_invoice_no,                 -- HHT�`�[No.
--                 dlv_date,                       -- �[�i��
--                 inspect_date,                   -- ������
--                 sales_classification,           -- ���㕪�ދ敪
--                 sales_invoice,                  -- ����`�[�敪
--                 card_sale_class,                -- �J�[�h���敪
--                 dlv_time,                       -- ����
--                 change_out_time_100,            -- ��K�؂ꎞ��100�~
--                 change_out_time_10,             -- ��K�؂ꎞ��10�~
--                 customer_number,                -- �ڋq�R�[�h
--                 dlv_form,                       -- �[�i�`��
--                 system_class,                   -- �Ƒԋ敪
--                 invoice_type,                   -- �`�[�敪
--                 input_class,                    -- ���͋敪
--                 consumption_tax_class,          -- ����ŋ敪
--                 total_amount,                   -- ���v���z
--                 sale_discount_amount,           -- ����l���z
--                 sales_consumption_tax,          -- �������Ŋz
--                 tax_include,                    -- �ō����z
--                 keep_in_code,                   -- �a����R�[�h
--                 department_screen_class,        -- �S�ݓX��ʎ��
--                 digestion_vd_rate_maked_date,   -- ����VD�|���쐬�N����
--                 red_black_flag,                 -- �ԍ��t���O
--                 forward_flag,                   -- �A�g�t���O
--                 forward_date,                   -- �A�g���t
--                 vd_results_forward_flag,        -- �x���_�[�i���я��A�g�σt���O
--                 cancel_correct_class,           -- ����E�����敪
--                 created_by,                     -- �쐬��
--                 creation_date,                  -- �쐬��
--                 last_updated_by,                -- �ŏI�X�V��
--                 last_update_date,               -- �ŏI�X�V��
--                 last_update_login,              -- �ŏI�X�V���O�C��
--                 request_id,                     -- �v��ID
--                 program_application_id,         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--                 program_id,                     -- �R���J�����g�E�v���O����ID
--                 program_update_date             -- �v���O�����X�V��
--            )
--        VALUES
--          (
----******************** 2009/05/07 Ver1.8  N.Maeda MOD START ******************************************
----        SELECT head.order_no_hht,              -- ��No.(HHT)
----               head.digestion_ln_number,       -- �}��
----               head.order_no_ebs,              -- ��No.(EBS)
----               head.base_code,                 -- ���_�R�[�h
----               head.performance_by_code,       -- ���ю҃R�[�h
----               head.dlv_by_code,               -- �[�i�҃R�[�h
----               head.hht_invoice_no,            -- HHT�`�[No.
----               head.dlv_date,                  -- �[�i��
----               head.inspect_date,              -- ������
----               head.sales_classification,      -- ���㕪�ދ敪
----               head.sales_invoice,             -- ����`�[�敪
----               head.card_sale_class,           -- �J�[�h���敪
----               head.dlv_time,                  -- ����
----               head.change_out_time_100,       -- ��K�؂ꎞ��100�~
----               head.change_out_time_10,        -- ��K�؂ꎞ��10�~
----               head.customer_number,           -- �ڋq�R�[�h
----                 NULL,                           -- �[�i�`��
----               head.system_class,              -- �Ƒԋ敪
----                 NULL,                           -- �`�[�敪
----               head.input_class,               -- ���͋敪
----               head.consumption_tax_class,     -- ����ŋ敪
----               head.total_amount,              -- ���v���z
----               head.sale_discount_amount,      -- ����l���z
----               head.sales_consumption_tax,     -- �������Ŋz
----               head.tax_include,               -- �ō����z
----               head.keep_in_code,              -- �a����R�[�h
----               head.department_screen_class,   -- �S�ݓX��ʎ��
----                 NULL,                           -- ����VD�|���쐬�N����
----               head.red_black_flag,            -- �ԍ��t���O
----                 'N',                            -- �A�g�t���O
----                 NULL,                           -- �A�g���t
----                 'N',                            -- �x���_�[�i���я��A�g�σt���O
----               head.cancel_correct_class,      -- ����E�����敪
----                 gt_clm_headers.cancel_correct_class,      -- ����E�����敪
----                 cn_created_by,                  -- �쐬��
----                 cd_creation_date,               -- �쐬��
----                 cn_last_updated_by,             -- �ŏI�X�V��
----                 cd_last_update_date,            -- �ŏI�X�V��
----                 cn_last_update_login,           -- �ŏI�X�V���O�C��
----                 cn_request_id,                  -- �v��ID
----                 cn_program_application_id,      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
----                 cn_program_id,                  -- �R���J�����g�E�v���O����ID
----                 cd_program_update_date          -- �v���O�����X�V��
----        FROM   xxcos_dlv_headers  head         -- �[�i�w�b�_�e�[�u��
----        WHERE  head.results_forward_flag = cv_default       -- �̔����јA�g�ς݃t���O��0
----        AND    head.input_class          = cv_input_class;  -- ���͋敪��5
--                 gt_dev_set_order_noh_hht(i),
--                 gt_dev_set_digestion_ln(i),
--                 gt_dev_set_order_no_ebs(i),
--                 gt_dev_set_base_code(i),
--                 gt_dev_set_perform_code(i),
--                 gt_dev_set_dlv_code(i),
--                 gt_dev_set_invoice_no(i),
--                 gt_dev_set_dlv_date(i),
--                 gt_dev_set_inspect_date(i),
--                 gt_dev_set_sales_classif(i),
--                 gt_dev_set_sales_invoice(i),
--                 gt_dev_set_card_sale_class(i),
--                 gt_dev_set_dlv_time(i),
--                 gt_dev_set_out_time_100(i),
--                 gt_dev_set_out_time_10(i),
--                 gt_dev_set_cus_number(i),
--                 gt_dev_set_dlv_form(i),
--                 gt_dev_set_system_class(i),
--                 gt_dev_set_invoice_type(i),
--                 gt_dev_set_input_class(i),
--                 gt_dev_set_tax_class(i),
--                 gt_dev_set_total_amount(i),
--                 gt_dev_set_sales_tax(i),
--                 gt_dev_set_sale_discount_a(i),
--                 gt_dev_set_tax_include(i),
--                 gt_dev_set_keep_in_code(i),
--                 gt_dev_set_depart_sc_clas(i),
--                 gt_dev_set_dig_vd_r_mak_d(i),
--                 gt_dev_set_red_black_flag(i),
--                 gt_dev_set_forward_flag(i),
--                 gt_dev_set_forward_date(i),
--                 gt_dev_set_vd_results_for_f(i),
--                 gt_dev_set_cancel_correct(i),
--                 gt_dev_set_created_by(i),
--                 gt_dev_set_creation_date(i),
--                 gt_dev_set_last_updated_by(i),
--                 gt_dev_set_last_update_date(i),
--                 gt_dev_set_last_update_logi(i),
--                 gt_dev_set_request_id(i),
--                 gt_dev_set_program_appli_id(i),
--                 gt_dev_set_program_id(i),
--                 gt_dev_set_program_update_d(i)
--                 );
----******************** 2009/05/07 Ver1.8  N.Maeda MOD  END  ******************************************
----
--    -- �w�b�_���o�����Z�b�g
----******************** 2009/05/26 Ver1.9  T.Kitajima MOD START ******************************************
----    on_target_cnt := SQL%ROWCOUNT;
--    on_target_cnt := gt_dev_set_order_noh_hht.COUNT;
----******************** 2009/05/26 Ver1.9  T.Kitajima MOD  END  ******************************************
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
--        gv_tkn2    := NULL;
--        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
--                                                cv_tkn_table,   gv_tkn1,
--                                                cv_tkn_key,     gv_tkn2 );
--        lv_errbuf  := lv_errmsg;
--        RAISE global_api_expt;
--    END;
----
--    --==============================================================
--    -- VD�R�����ʎ�����׃e�[�u���֓o�^
--    --==============================================================
--    BEGIN
--      INSERT INTO
--        xxcos_vd_column_lines
--          (
--               order_no_hht,                -- ��No.(HHT)
--               line_no_hht,                 -- �sNo.(HHT)
--               digestion_ln_number,         -- �}��
--               order_no_ebs,                -- ��No.(EBS)
--               line_number_ebs,             -- ���הԍ�(EBS)
--               item_code_self,              -- �i���R�[�h(����)
--               content,                     -- ����
--               inventory_item_id,           -- �i��ID
--               standard_unit,               -- ��P��
--               case_number,                 -- �P�[�X��
--               quantity,                    -- ����
--               sale_class,                  -- ����敪
--               wholesale_unit_ploce,        -- ���P��
--               selling_price,               -- ���P��
--               column_no,                   -- �R����No.
--               h_and_c,                     -- H/C
--               sold_out_class,              -- ���؋敪
--               sold_out_time,               -- ���؎���
--               replenish_number,            -- ��[��
--               cash_and_card,               -- �����E�J�[�h���p�z
--               created_by,                  -- �쐬��
--               creation_date,               -- �쐬��
--               last_updated_by,             -- �ŏI�X�V��
--               last_update_date,            -- �ŏI�X�V��
--               last_update_login,           -- �ŏI�X�V���O�C��
--               request_id,                  -- �v��ID
--               program_application_id,      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--               program_id,                  -- �R���J�����g�E�v���O����ID
--               program_update_date          -- �v���O�����X�V��
--          )
--        SELECT line.order_no_hht,           -- ��No.(HHT)
--               line.line_no_hht,            -- �sNo.(HHT)
--               line.digestion_ln_number,    -- �}��
--               line.order_no_ebs,           -- ��No.(EBS)
--               line.line_number_ebs,        -- ���הԍ�(EBS)
--               line.item_code_self,         -- �i���R�[�h(����)
--               line.content,                -- ����
--               line.inventory_item_id,      -- �i��ID
--               line.standard_unit,          -- ��P��
--               line.case_number,            -- �P�[�X��
--               DECODE( head.red_black_flag, '0', line.quantity * -1, line.quantity ),
--                                            -- ����
--               line.sale_class,             -- ����敪
--               line.wholesale_unit_ploce,   -- ���P��
--               line.selling_price,          -- ���P��
--               line.column_no,              -- �R����No.
--               line.h_and_c,                -- H/C
--               line.sold_out_class,         -- ���؋敪
--               line.sold_out_time,          -- ���؎���
--               DECODE( head.red_black_flag, '0', line.replenish_number * -1, line.replenish_number ),
--                                            -- ��[��
--               line.cash_and_card,          -- �����E�J�[�h���p�z
--               cn_created_by,               -- �쐬��
--               cd_creation_date,            -- �쐬��
--               cn_last_updated_by,          -- �ŏI�X�V��
--               cd_last_update_date,         -- �ŏI�X�V��
--               cn_last_update_login,        -- �ŏI�X�V���O�C��
--               cn_request_id,               -- �v��ID
--               cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--               cn_program_id,               -- �R���J�����g�E�v���O����ID
--               cd_program_update_date       -- �v���O�����X�V��
--        FROM   xxcos_dlv_headers  head,     -- �[�i�w�b�_�e�[�u��
--               xxcos_dlv_lines    line      -- �[�i���׃e�[�u��
--        WHERE  head.results_forward_flag = cv_default                -- �̔����јA�g�ς݃t���O��0
--        AND    head.input_class          = cv_input_class            -- ���͋敪��5
--        AND    head.order_no_hht         = line.order_no_hht         -- �w�b�_.��No.(HHT)������.��No.(HHT)
--        AND    head.digestion_ln_number  = line.digestion_ln_number; -- �w�b�_.�}�ԁ�����.�}��
----
--    -- ���ג��o�����Z�b�g
--    on_target_cnt_l := SQL%ROWCOUNT;
--
--    EXCEPTION
--      WHEN OTHERS THEN
--        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdl_table );
--        gv_tkn2    := NULL;
--        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_add,
--                                                cv_tkn_table,   gv_tkn1,
--                                                cv_tkn_key,     gv_tkn2 );
--        lv_errbuf  := lv_errmsg;
--        RAISE insert_err_expt;
--    END;
--
--  EXCEPTION
--    -- ���b�N�G���[
--    WHEN lock_expt THEN
--      gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_table );
--      lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_lock, cv_tkn_tab, gv_tkn1 );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
--      ov_retcode := cv_status_error;
----
--      IF ( headers_lock_cur%ISOPEN ) THEN
--        CLOSE headers_lock_cur;
--      END IF;
----
--      IF ( lines_lock_cur%ISOPEN ) THEN
--        CLOSE lines_lock_cur;
--      END IF;
--
  EXCEPTION
--
    -- �C���T�[�g�G���[
    WHEN insert_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--******************** 2009/07/17 Ver1.11  N.Maeda MOD  END  ******************************************
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END dlv_data_register;
--
  /**********************************************************************************
   * Procedure Name   : data_update
   * Description      : �R�����ʓ]���σt���O�A�̔����јA�g�ς݃t���O�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE data_update(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_update'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==============================================================
    -- �R�����]���t���O�X�V
    --==============================================================
    BEGIN
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
--      UPDATE
--        xxcoi_hht_inv_transactions  inv   -- ���o�Ɉꎞ�\
--      SET
--        inv.column_if_flag         = cv_tkn_yes,                  -- �R�����]���t���O
--        inv.column_if_date         = cd_last_update_date,         -- �R�����ʓ]����
--        inv.last_updated_by        = cn_last_updated_by,          -- �ŏI�X�V��
--        inv.last_update_date       = cd_last_update_date,         -- �ŏI�X�V��
--        inv.last_update_login      = cn_last_update_login,        -- �ŏI�X�V���O�C��
--        inv.request_id             = cn_request_id,               -- �v��ID
--        inv.program_application_id = cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--        inv.program_id             = cn_program_id,               -- �R���J�����g�E�v���O����ID
--        inv.program_update_date    = cd_program_update_date       -- �v���O�����X�V��
--      WHERE  inv.invoice_type IN (
--                                     SELECT  look_val.lookup_code  code
--                                     FROM    fnd_lookup_values     look_val
--                                            ,fnd_lookup_types_tl   types_tl
--                                            ,fnd_lookup_types      types
--                                            ,fnd_application_tl    appl
--                                            ,fnd_application       app
--                                     WHERE   app.application_short_name = cv_application
--                                     AND     look_val.lookup_type  = cv_qck_invo_type
--                                     AND     look_val.enabled_flag = cv_tkn_yes
--                                     AND     gd_process_date      >= NVL(look_val.start_date_active, gd_process_date)
--                                     AND     gd_process_date      >= look_val.start_date_active
--                                     AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
--                                     AND     types_tl.language     = USERENV( 'LANG' )
--                                     AND     look_val.language     = USERENV( 'LANG' )
--                                     AND     appl.language         = USERENV( 'LANG' )
--                                     AND     appl.application_id   = types.application_id
--                                     AND     app.application_id    = appl.application_id
--                                     AND     types_tl.lookup_type  = look_val.lookup_type
--                                     AND     types.lookup_type     = types_tl.lookup_type
--                                     AND     types.security_group_id   = types_tl.security_group_id
--                                     AND     types.view_application_id = types_tl.view_application_id
--                                   )                              -- �`�[�敪��4,5,6,7
--      AND    inv.column_if_flag = cv_tkn_no                       -- �R�����ʓ]���t���O��N
--      AND    inv.status         = cv_one;                         -- �����X�e�[�^�X��1
      FORALL i in 1..gt_transaction_id.COUNT
        UPDATE xxcoi_hht_inv_transactions  inv   -- ���o�Ɉꎞ�\
           SET inv.column_if_flag         = cv_tkn_yes,                  -- �R�����]���t���O
               inv.column_if_date         = cd_last_update_date,         -- �R�����ʓ]����
               inv.last_updated_by        = cn_last_updated_by,          -- �ŏI�X�V��
               inv.last_update_date       = cd_last_update_date,         -- �ŏI�X�V��
               inv.last_update_login      = cn_last_update_login,        -- �ŏI�X�V���O�C��
               inv.request_id             = cn_request_id,               -- �v��ID
               inv.program_application_id = cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               inv.program_id             = cn_program_id,               -- �R���J�����g�E�v���O����ID
               inv.program_update_date    = cd_program_update_date       -- �v���O�����X�V��
         WHERE inv.transaction_id         = gt_transaction_id(i)
        ;
--****************************** 2009/04/17 1.6 T.Kitajima MOD START ******************************--
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_inv_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- �A�g�ς݃t���O�X�V
    --==============================================================
    BEGIN
--******************** 2009/05/21 Ver1.9  T.Kitajima MOD START ******************************************
--      UPDATE
--        xxcos_dlv_headers  head   -- �[�i�w�b�_�e�[�u��
--      SET
--        head.results_forward_flag   = cv_one,                      -- �̔����јA�g�ς݃t���O
--        head.results_forward_date   = cd_last_update_date,         -- �̔����јA�g�ςݓ��t
--        head.last_updated_by        = cn_last_updated_by,          -- �ŏI�X�V��
--        head.last_update_date       = cd_last_update_date,         -- �ŏI�X�V��
--        head.last_update_login      = cn_last_update_login,        -- �ŏI�X�V���O�C��
--        head.request_id             = cn_request_id,               -- �v��ID
--        head.program_application_id = cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
--        head.program_id             = cn_program_id,               -- �R���J�����g�E�v���O����ID
--        head.program_update_date    = cd_program_update_date       -- �v���O�����X�V��
--      WHERE  head.results_forward_flag = cv_default                -- �̔����јA�g�ς݃t���O��0
--      AND    head.input_class          = cv_input_class;           -- ���͋敪��5
--
      FORALL i in 1..gt_dlv_headers_row_id.COUNT
        UPDATE xxcos_dlv_headers  head   -- �[�i�w�b�_�e�[�u��
           SET head.results_forward_flag   = cv_one,                      -- �̔����јA�g�ς݃t���O
               head.results_forward_date   = cd_last_update_date,         -- �̔����јA�g�ςݓ��t
               head.last_updated_by        = cn_last_updated_by,          -- �ŏI�X�V��
               head.last_update_date       = cd_last_update_date,         -- �ŏI�X�V��
               head.last_update_login      = cn_last_update_login,        -- �ŏI�X�V���O�C��
               head.request_id             = cn_request_id,               -- �v��ID
               head.program_application_id = cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               head.program_id             = cn_program_id,               -- �R���J�����g�E�v���O����ID
               head.program_update_date    = cd_program_update_date       -- �v���O�����X�V��
         WHERE head.rowid                  = gt_dlv_headers_row_id(i)
      ;
--******************** 2009/05/21 Ver1.9  T.Kitajima MOD  END  ******************************************
--
    EXCEPTION
      WHEN OTHERS THEN
        gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_dlv_h_table );
        gv_tkn2    := NULL;
        lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update,
                                                cv_tkn_table,   gv_tkn1,
                                                cv_tkn_key,     gv_tkn2 );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
--******************** 2009/05/07 Ver1.8  N.Maeda ADD START ******************************************
    --==============================================================
    -- VD�J�����ʎ������������敪�X�V
    --==============================================================
    IF ( gt_vd_row_id.COUNT > 0 ) THEN
      BEGIN
        <<vd_update_loop>>
        FORALL i IN 1..gt_vd_row_id.COUNT
          UPDATE
            xxcos_vd_column_headers  head   -- �[�i�w�b�_�e�[�u��
          SET
            head.cancel_correct_class   = gt_vd_can_cor_class(i),      -- ��������敪
            head.last_updated_by        = cn_last_updated_by,          -- �ŏI�X�V��
            head.last_update_date       = cd_last_update_date,         -- �ŏI�X�V��
            head.last_update_login      = cn_last_update_login,        -- �ŏI�X�V���O�C��
            head.request_id             = cn_request_id,               -- �v��ID
            head.program_application_id = cn_program_application_id,   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            head.program_id             = cn_program_id,               -- �R���J�����g�E�v���O����ID
            head.program_update_date    = cd_program_update_date       -- �v���O�����X�V��
          WHERE  head.rowid             = gt_vd_row_id(i);
--
      EXCEPTION
        WHEN OTHERS THEN
          gv_tkn1    := xxccp_common_pkg.get_msg( cv_application, cv_msg_vdh_table );
          gv_tkn2    := NULL;
          lv_errmsg  := xxccp_common_pkg.get_msg( cv_application, cv_msg_update,
                                                  cv_tkn_table,   gv_tkn1,
                                                  cv_tkn_key,     gv_tkn2 );
          lv_errbuf  := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
--******************** 2009/05/07 Ver1.8  N.Maeda ADD  END  ******************************************
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END data_update;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
--
  /**********************************************************************************
   * Procedure Name   : ins_err_msg
   * Description      : �G���[���o�^����(A-6)
   ***********************************************************************************/
--
  PROCEDURE ins_err_msg(
    ov_errbuf       OUT     VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT     VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT     VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_err_msg'; -- �v���O������
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
    lv_outmsg       VARCHAR2(5000);   --  �G���[���b�Z�[�W
    lv_table_name   VARCHAR2(100);    --  �e�[�u������
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
    FOR ln_set_cnt  IN  1 .. gn_msg_cnt LOOP
      -- ===============================
      --  �L�[���ȊO�̐ݒ�
      -- ===============================
      --  �ėp�G���[���X�gID
      SELECT  xxcos_gen_err_list_s01.NEXTVAL
      INTO    gt_err_key_msg_tab(ln_set_cnt).gen_err_list_id
      FROM    dual;
      --
      gt_err_key_msg_tab(ln_set_cnt).concurrent_program_name  :=  cv_pkg_name;                  --  �R���J�����g��
      gt_err_key_msg_tab(ln_set_cnt).business_date            :=  gd_process_date;              --  �o�^�Ɩ����t
      gt_err_key_msg_tab(ln_set_cnt).created_by               :=  cn_created_by;                --  �쐬��
      gt_err_key_msg_tab(ln_set_cnt).creation_date            :=  SYSDATE;                      --  �쐬��
      gt_err_key_msg_tab(ln_set_cnt).last_updated_by          :=  cn_last_updated_by;           --  �ŏI�X�V��
      gt_err_key_msg_tab(ln_set_cnt).last_update_date         :=  SYSDATE;                      --  �ŏI�X�V��
      gt_err_key_msg_tab(ln_set_cnt).last_update_login        :=  cn_last_update_login;         --  �ŏI�X�V���O�C��
      gt_err_key_msg_tab(ln_set_cnt).request_id               :=  cn_request_id;                --  �v��ID
      gt_err_key_msg_tab(ln_set_cnt).program_application_id   :=  cn_program_application_id;    --  �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      gt_err_key_msg_tab(ln_set_cnt).program_id               :=  cn_program_id;                --  �R���J�����g�E�v���O����ID
      gt_err_key_msg_tab(ln_set_cnt).program_update_date      :=  SYSDATE;                      --  �v���O�����X�V��
    END LOOP;
    --
    -- ===============================
    --  �ėp�G���[���X�g�o�^
    -- ===============================
    FORALL ln_cnt IN 1 .. gn_msg_cnt  SAVE EXCEPTIONS
      INSERT  INTO  xxcos_gen_err_list VALUES gt_err_key_msg_tab(ln_cnt);
--
  EXCEPTION
    -- *** �o���N�C���T�[�g��O���� ***
    WHEN global_bulk_ins_expt THEN
      gn_error_cnt  :=  SQL%BULK_EXCEPTIONS.COUNT;        --  �G���[����
      ov_retcode    :=  cv_status_err_ins;                --  �X�e�[�^�X�i�G���[�j
      ov_errmsg     :=  NULL;                             --  ���[�U�[�E�G���[�E���b�Z�[�W
      ov_errbuf     :=  NULL;                             --  �G���[�E���b�Z�[�W
      --
      --  �e�[�u������
      lv_table_name :=  xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_application
                          , iv_name         =>  cv_msg_gen_errlst
                        );
      --
      <<output_error_loop>>
      FOR ln_cnt IN 1 .. gn_error_cnt  LOOP
        -- �G���[���b�Z�[�W����
        lv_outmsg :=  SUBSTRB(
                        xxccp_common_pkg.get_msg(
                            iv_application    =>  cv_application
                          , iv_name           =>  cv_msg_add
                          , iv_token_name1    =>  cv_tkn_table
                          , iv_token_value1   =>  lv_table_name
                          , iv_token_name2    =>  cv_key_data
                          , iv_token_value2   =>  cv_prg_name||cv_msg_part||SQLERRM(-SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_CODE)
                        ), 1, 5000
                      );
        -- �G���[���b�Z�[�W�o��
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_outmsg
        );
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.LOG
          , buff    =>  lv_outmsg
        );
      END LOOP output_error_loop;
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
  END ins_err_msg;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    iv_gen_err_out_flag  IN         VARCHAR2,     --  �ėp�G���[���X�g�o�̓t���O
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
    ov_errbuf            OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_warn_cnt         := 0;
    gn_inv_target_cnt   := 0;
    gn_dlv_h_target_cnt := 0;
    gn_dlv_l_target_cnt := 0;
    gn_h_normal_cnt     := 0;
    gn_l_normal_cnt     := 0;
    gn_dlv_h_nor_cnt    := 0;
    gn_dlv_l_nor_cnt    := 0;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
    gn_msg_cnt                :=  0;                                --  �ėp�G���[���X�g�o�͌���
    gv_prm_gen_err_out_flag   :=  iv_gen_err_out_flag;              --  �ėp�G���[���X�g�o�̓t���O
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-0)
    -- ===============================
    init(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���o�Ƀf�[�^���o(A-1)
    -- ===============================
    inv_data_receive(
      gn_inv_target_cnt,   -- ���o�ɏ�񒊏o����
      lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --== ���o�ɏ��1���ȏ゠��ꍇ�AA-2�AA-3�̏������s���܂��B ==--
    IF ( gn_inv_target_cnt >= 1 ) THEN
      -- ===============================
      -- ���o�Ƀf�[�^���o(A-2)
      -- ===============================
      inv_data_compute(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���o�Ƀf�[�^�o�^(A-3)
      -- ===============================
      inv_data_register(
        gn_h_normal_cnt,      -- ���o�Ƀw�b�_��񐬌�����
        gn_l_normal_cnt,      -- ���o�ɖ��׏�񐬌�����
        lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- �[�i�f�[�^�o�^(A-4)
    -- ===============================
    dlv_data_register(
      gn_dlv_h_target_cnt, -- �[�i�w�b�_��񒊏o����
      gn_dlv_l_target_cnt, -- �[�i���׏�񒊏o����
      lv_errbuf,           -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,          -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �[�i��񐬌������Z�b�g
    gn_dlv_h_nor_cnt    := gn_dlv_h_target_cnt;
    gn_dlv_l_nor_cnt    := gn_dlv_l_target_cnt;
--
    -- �G���[����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
      -- =======================================================
      -- �R�����ʓ]���σt���O�A�̔����јA�g�ς݃t���O�X�V(A-5)
      -- =======================================================
      data_update(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
--****************************** 2014/11/27 1.19 K.Nakatsu ADD START ******************************--
      -- =======================================================
      -- A-6.�G���[���o�^����
      -- =======================================================
    IF (gn_msg_cnt <> 0) THEN
      --  �ėp�G���[���X�g�o�͑ΏۗL��̏ꍇ
      ins_err_msg(
          ov_errbuf       =>  lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
        , ov_retcode      =>  lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
        , ov_errmsg       =>  lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF (lv_retcode = cv_status_err_ins) THEN
        -- INSERT���G���[
        RAISE global_ins_key_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
--****************************** 2014/11/27 1.19 K.Nakatsu ADD  END  ******************************--
    -- �X�L�b�v������
    IF ( gn_warn_cnt <> 0 ) THEN
      -- �X�e�[�^�X�x��
      ov_retcode := cv_status_warn;
    END IF;
    -- �x�������i�Ώۃf�[�^�����G���[�jgt_tr_count
    IF (  gn_inv_target_cnt + gn_dlv_h_target_cnt = 0  ) THEN
--    IF (  gn_inv_target_cnt + gn_dlv_h_target_cnt = 0  ) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg( cv_application, cv_msg_nodata );
      FND_FILE.PUT_LINE( FND_FILE.LOG, lv_errmsg );
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
--****************************** 2014/11/27 1.19 K.Nakatsu MOD START ******************************--
--    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_gen_err_out_flag  IN VARCHAR2 --  �ėp�G���[���X�g�o�̓t���O
--****************************** 2014/11/27 1.19 K.Nakatsu MOD  END  ******************************--
  )
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
       ov_retcode => lv_retcode
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
--****************************** 2014/11/27 1.19 K.Nakatsu MOD START ******************************--
--       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       NVL(iv_gen_err_out_flag, cv_tkn_no)         --  �ėp�G���[���X�g�o�̓t���O
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
--****************************** 2014/11/27 1.19 K.Nakatsu MOD  END  ******************************--
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- ��������������
      gn_h_normal_cnt  := 0;
      gn_l_normal_cnt  := 0;
      gn_dlv_h_nor_cnt := 0;
      gn_dlv_l_nor_cnt := 0;
      gn_warn_cnt      := 0;
--
      FND_FILE.PUT_LINE(
         which => FND_FILE.OUTPUT
        ,buff  => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which => FND_FILE.LOG
        ,buff  => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
--******************** 2009/07/17 Ver1.11  N.Maeda MOD START ******************************************
--    --���o�ɏ�񒊏o�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_inv_cnt
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR( gn_inv_target_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => gv_out_msg
--    );
----    --
    --�[�i�w�b�_��񒊏o�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_dlv_h_target_cnt + gt_tr_count )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
--    --�[�i���׏�񒊏o�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_dlv_cnt_l
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR( gn_dlv_l_target_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => gv_out_msg
--    );
    --
    --�w�b�_���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_h_nor_cnt
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_h_normal_cnt + gt_insert_h_count )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
--    --���א��������o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_application
--                    ,iv_name         => cv_msg_l_nor_cnt
--                    ,iv_token_name1  => cv_tkn_count
--                    ,iv_token_value1 => TO_CHAR( gn_l_normal_cnt + gn_dlv_l_nor_cnt )
--                   );
--    FND_FILE.PUT_LINE(
--       which => FND_FILE.OUTPUT
--      ,buff  => gv_out_msg
--    );
    --
    --
    --�X�L�b�v����
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    --
--******************** 2009/07/17 Ver1.11  N.Maeda MOD  END  ******************************************
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
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
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS001A07C;
/
