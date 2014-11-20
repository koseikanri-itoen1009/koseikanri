CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A02C(body)
 * Description      : �P���}�X�^IF�o�́i�f�[�^���o�j
 * MD.050           : �P���}�X�^IF�o�́i�f�[�^���o�j MD050_COS_003_A02
 * Version          : 1.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   A-0�D��������
 *  proc_main_loop         A-1�D�f�[�^���o
 *  proc_upd_n_target_line A-8. �̔����і��בΏۊO�f�[�^�X�V
 *  proc_upd_skip_line     A-7. �̔����і��׃X�L�b�v�f�[�^�X�V
 *  proc_insert_upm_work   A-4�D�P���}�X�^���[�N�e�[�u���o�^
 *  proc_update_upm_work   A-3�D�P���}�X�^���[�N�e�[�u���X�V
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05   1.0    K.Okaguchi       �V�K�쐬
 *  2009/02/23   1.1    K.Okaguchi       [��QCOS_111] ��݌ɕi�ڂ𒊏o���Ȃ��悤�ɂ���B
 *  2009/02/24   1.2    T.Nakamura       [��QCOS_130] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/05/28   1.3    S.Kayahara       [��QT1_1176] �P���̓��o�ɒ[�������ǉ�
 *  2009/06/09   1.4    N.Maeda          [��QT1_1401] �[�������擾�e�[�u���C��
 *  2009/07/17   1.5    K.Shirasuna      [��QPT_00016]�u�P���}�X�^IF�o�́v�����̐��\���P
 *  2009/08/04   1.6    M.Sano           [��Q0000933] �w�P���}�X�^IF�o�́xPT�̍l��
 *  2009/08/17   1.7    M.Sano           [��Q0001044] �u�P���}�X�^IF�o�́v�����̐��\���P
 *  2009/08/25   1.8    K.Kiriu          [��Q0001163] �u�P���}�X�^IF�o�́v�����̐��\���P
 *                                       [��Q0000451] �P���̌����ӂ�Ή�
 *  2009/10/15   1.9    N.Maeda          [��Q0001524] �o�͋��z�擾���@�C��
 *  2009/12/13   1.10   K.Atsushiba      [E_�{�ғ�_00290] �[�iVD�ڋq�̒P�����A�g����Ȃ�
 *  2009/12/17   1.11   N.Maeda          [E_�{�ғ�_00489] �����Ώۊ���ʌ��������ǉ�
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
  gn_target_cnt    NUMBER DEFAULT 0;                    -- �Ώی���
  gn_normal_cnt    NUMBER DEFAULT 0;                    -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0;                    -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0;                    -- �X�L�b�v����
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
  global_data_check_expt    EXCEPTION;     -- �f�[�^�`�F�b�N���̃G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100):= 'XXCOS003A02C'; -- �p�b�P�[�W��
  cv_application          CONSTANT VARCHAR2(5)  := 'XXCOS';        -- �A�v���P�[�V������
  cv_appl_short_name      CONSTANT VARCHAR2(10) := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
  cv_tkn_table_name       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_data         CONSTANT VARCHAR2(20) := 'KEY_DATA';
/* 2009/08/25 Ver1.8 Add Start */
  cv_tkn_cust             CONSTANT VARCHAR2(20) := 'CUST_CODE';
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM_CODE';
  cv_tkn_dlv_date         CONSTANT VARCHAR2(20) := 'DLV_DATE';
  cv_tkn_unit_price       CONSTANT VARCHAR2(20) := 'UNIT_PRICE';
/* 2009/08/25 Ver1.8 Add End   */
  cv_flag_off             CONSTANT VARCHAR2(1)  := 'N';
  cv_flag_on              CONSTANT VARCHAR2(1)  := 'Y';
/* 2009/08/25 Ver1.8 Add Start */
  cv_flag_w               CONSTANT VARCHAR2(1)  := 'W';                   --�X�L�b�v
  cv_flag_s               CONSTANT VARCHAR2(1)  := 'S';                   --�ΏۊO
/* 2009/08/25 Ver1.8 Add End   */
  cv_correct              CONSTANT VARCHAR2(30) := '1';                   --��������敪�@=�@1�i�����j
  cv_invoice_class_dliv   CONSTANT VARCHAR2(1)  := '1';                   --�[�i�`�[�敪 = 1(�[�i)
  cv_invoice_class_d_co   CONSTANT VARCHAR2(1)  := '3';                   --�[�i�`�[�敪 = 3(�[�i����)
  cv_tkn_lock             CONSTANT VARCHAR2(20) := 'TABLE';               -- ���b�N�G���[
  cn_lock_error_code      CONSTANT NUMBER       := -54;
  cv_msg_lock             CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00001';    --���b�N�擾�G���[
  cv_msg_insert_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00010';    --�f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_update_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011';    --�f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_select_err       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00013';    --�f�[�^���o�G���[���b�Z�[�W
  cv_tkn_tm_w_tbl         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10852';    -- �P���}�X�^���[�N�e�[�u��
  cv_tkn_exp_l_tbl        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10701';    -- �̔����і��׃e�[�u��
  cv_tkn_cust_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10853';    -- �ڋq�R�[�h
  cv_tkn_item_code        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10854';    -- �i���R�[�h
  cv_tkn_exp_line_id      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10702';    -- �̔����і���ID
  cv_no_parameter         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';    -- �p�����[�^�Ȃ�
  cv_tkn_sales_cls_nml    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10703';    -- �ʏ�
  cv_tkn_sales_cls_sls    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10704';    -- ����
  cv_tkn_fnd_lookup_v     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00066';    -- �N�C�b�N�R�[�h�e�[�u��
  cv_tkn_lookup_type      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00075';    -- �N�C�b�N�R�[�h.�Q�ƃ^�C�v
  cv_tkn_meaning          CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00089';    -- �N�C�b�N�R�[�h.���e
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
  cv_tkn_customer_err     CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10705';    -- �ڋq�K�w�r���[�擾�G���[
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  cv_tkn_exp_header_id    CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10706';    -- �̔����уw�b�_ID
  cv_msg_n_target_upd_err CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10707';    -- �̔����בΏۊO�f�[�^�X�V�G���[
  cv_msg_edit_unit_price  CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10708';    -- �P���ҏW���b�Z�[�W
/* 2009/08/25 Ver1.8 Add End   */
  cv_lookup_type_gyotai   CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A02'; --�Q�ƃ^�C�v�@�Ƒԏ�����
  cv_lookup_type_no_inv   CONSTANT VARCHAR2(30) := 'XXCOS1_NO_INV_ITEM_CODE'; --�Q�ƃ^�C�v�@��݌ɕi��
  cv_lookup_type_sals_cls CONSTANT VARCHAR2(30) := 'XXCOS1_SALE_CLASS';   -- �Q�ƃ^�C�v�@����敪
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
----****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
--  cv_amount_up            CONSTANT VARCHAR2(5)  := 'UP';                  -- �����_�[��(�؏�)
--  cv_amount_down          CONSTANT VARCHAR(5)   := 'DOWN';                -- �����_�[��(�؎̂�)
--  cv_amount_nearest       CONSTANT VARCHAR(10)  := 'NEAREST';             -- �����_�[��(�l�̌ܓ�)
----****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
  cv_msg_comma            CONSTANT VARCHAR2(20) := ', ';                  -- �J���}
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  cv_fmt_date             CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';          -- ���t�t�H�[�}�b�g
/* 2009/08/25 Ver1.8 Add End   */
/* 2009/12/13 Ver1.10 Add Start */
  cv_lookup_cd_delivery_vd CONSTANT VARCHAR2(20) := 'XXCOS_003_A02_04';    -- �[�iVD
  cv_tkn_lookup_code       CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00078';    -- �N�C�b�N�R�[�h.�R�[�h
  cv_tkn_lookup_type1      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00077';    -- �N�C�b�N�R�[�h.�^�C�v
  cv_tkn_sales_cls_vd      CONSTANT VARCHAR2(20) := 'APP-XXCOS1-10709';    -- �x���_����
/* 2009/12/13 Ver1.10 Add End */
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
  cn_max_standard_qty      CONSTANT NUMBER := 5;                           -- ����ʎ擾�ő包��
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_key_info                 fnd_new_messages.message_text%TYPE   ;--���b�Z�[�W�o�͗p�L�[���
  gv_msg_tkn_tm_w_tbl         fnd_new_messages.message_text%TYPE   ;--'�P���}�X�^���[�N�e�[�u��'
  gv_msg_tkn_exp_l_tbl        fnd_new_messages.message_text%TYPE   ;--'�̔����і��׃e�[�u��'
  gv_msg_tkn_cust_code        fnd_new_messages.message_text%TYPE   ;--'�ڋq�R�[�h'
  gv_msg_tkn_item_code        fnd_new_messages.message_text%TYPE   ;--'�i���R�[�h'
  gv_msg_tkn_exp_line_id      fnd_new_messages.message_text%TYPE   ;--'�̔����і���ID'
  gv_msg_tkn_sales_cls_nml    fnd_new_messages.message_text%TYPE   ;--�ʏ�
  gv_msg_tkn_sales_cls_sls    fnd_new_messages.message_text%TYPE   ;--����
  gv_msg_tkn_fnd_lookup_v     fnd_new_messages.message_text%TYPE   ;--�N�C�b�N�R�[�h
  gv_msg_tkn_lookup_type      fnd_new_messages.message_text%TYPE   ;--�Q�ƃ^�C�v
  gv_msg_tkn_meaning          fnd_new_messages.message_text%TYPE   ;--���e
  gv_customer_number          xxcos_unit_price_mst_work.customer_number%TYPE;
  gv_item_code                xxcos_unit_price_mst_work.item_code%TYPE;
  gv_tkn_lock_table           fnd_new_messages.message_text%TYPE   ;
/* 2009/08/25 Ver1.8 Add Start */
  gv_msg_tkn_exp_header_id    fnd_new_messages.message_text%TYPE   ;--'�̔����уw�b�_ID'
/* 2009/08/25 Ver1.8 Add End   */
  gd_nml_prev_dlv_date        xxcos_unit_price_mst_work.nml_prev_dlv_date%TYPE;     --�ʏ� �O�� �[�i��
  gd_nml_bef_prev_dlv_date    xxcos_unit_price_mst_work.nml_bef_prev_dlv_date%TYPE; --�ʏ� �O�X�� �[�i��
  gd_sls_prev_dlv_date        xxcos_unit_price_mst_work.sls_prev_dlv_date%TYPE;     --���� �O�� �[�i��
  gd_sls_bef_prev_dlv_date    xxcos_unit_price_mst_work.sls_bef_prev_dlv_date%TYPE; --���� �O�X�� �[�i��
  gd_nml_prev_clt_date        xxcos_unit_price_mst_work.nml_prev_clt_date%TYPE;     --�ʏ� �O�� �쐬��
  gd_nml_bef_prev_clt_date    xxcos_unit_price_mst_work.nml_bef_prev_clt_date%TYPE; --�ʏ� �O�X�� �쐬��
  gd_sls_prev_clt_date        xxcos_unit_price_mst_work.sls_prev_clt_date%TYPE;     --���� �O�� �쐬��
  gd_sls_bef_prev_clt_date    xxcos_unit_price_mst_work.sls_bef_prev_clt_date%TYPE; --���� �O�X�� �쐬��
  gv_sales_cls_nml            fnd_lookup_values.lookup_code%TYPE;
  gv_sales_cls_sls            fnd_lookup_values.lookup_code%TYPE;
  gv_bf_sales_exp_header_id   xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
  gn_warn_tran_count          NUMBER DEFAULT 0;
  gn_new_warn_count           NUMBER DEFAULT 0;
  gn_tran_count               NUMBER DEFAULT 0;
  gn_unit_price               NUMBER;
  gn_skip_cnt                 NUMBER DEFAULT 0;                    -- �P���}�X�^�X�V�ΏۊO����
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
  gv_language                 fnd_lookup_values.language%TYPE;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  gv_edit_unit_price_flag     VARCHAR2(1);              --�P���ҏW�t���O
  gv_empty_line_flag          VARCHAR2(1) DEFAULT 'N';  --�I�����̋󔒍s����t���O
/* 2009/08/25 Ver1.8 Add End   */
/* 2009/12/13 Ver1.10 Add Start */
  gv_delivery_vd              VARCHAR2(2);
  gv_vd_sales_cls             VARCHAR2(2);
  gv_msg_lookup_code      fnd_new_messages.message_text%TYPE;   --�Q�ƃ^�C�v
  gv_msg_lookup_type      fnd_new_messages.message_text%TYPE;   --�Q�ƃ^�C�v
  gv_msg_sales_cls_vd     fnd_new_messages.message_text%TYPE;   --����
/* 2009/12/13 Ver1.10 Add Start */
--
--�J�[�\��
  CURSOR main_cur
  IS
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--    SELECT  xseh.sales_exp_header_id          sales_exp_header_id               --�̔����уw�b�_ID
    SELECT  /*+ leading(xsel) use_nl(xseh xsel) index(xsel xxcos_sales_exp_lines_n02) */
            xseh.sales_exp_header_id          sales_exp_header_id               --�̔����уw�b�_ID
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
           ,xseh.ship_to_customer_code        ship_to_customer_code             --�ڋq�y�[�i��z
           ,xseh.orig_delivery_date           delivery_date                     --�[�i���i�I���W�i���[�i���j
           ,xseh.tax_rate                     tax_rate                          --����ŗ�
           ,xsel.item_code                    item_code                         --�i�ڃR�[�h
           ,xsel.standard_unit_price_excluded standard_unit_price_excluded      --�Ŕ���P��
           ,xsel.standard_unit_price          standard_unit_price               --��P��
           ,xsel.standard_qty                 standard_qty                      --�����
           ,xsel.creation_date                creation_date                     --�쐬��
           ,xsel.sales_exp_line_id            sales_exp_line_id                 --�̔����і���ID
/* 2009/12/13 Ver1.10 Mod Start */
           ,CASE xseh.cust_gyotai_sho
               WHEN gv_delivery_vd THEN DECODE(xsel.sales_class ,gv_vd_sales_cls,gv_sales_cls_nml,xsel.sales_class)
               ELSE xsel.sales_class
            END                               sales_class
--           ,xsel.sales_class                  sales_class                       --����敪
/* 2009/12/13 Ver1.10 Mod End */
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hca.tax_rounding_rule             tax_round_rule                 --�ŋ�-�[������
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xchv.bill_tax_round_rule          tax_round_rule
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    FROM    xxcos_sales_exp_headers xseh
           ,xxcos_sales_exp_lines   xsel
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hz_cust_accounts                  hca
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xxcos_cust_hierarchy_v              xchv                           -- �ڋq�K�w�r���[
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    WHERE   (xseh.cancel_correct_class IS NULL
           OR
             xseh.order_no_hht         IS NULL )
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----    AND     hca.account_number           = xseh.ship_to_customer_code
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--    AND     xchv.ship_account_number   = xseh.ship_to_customer_code
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    AND     xseh.dlv_invoice_class = cv_invoice_class_dliv
    AND     xseh.sales_exp_header_id =  xsel.sales_exp_header_id
/* 2009/12/13 Ver1.10 Mod Start */
    AND    ( ( xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls))
              OR
             ( xseh.cust_gyotai_sho    = gv_delivery_vd ) AND ( xsel.sales_class = gv_vd_sales_cls ))
--    AND     xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls)
/* 2009/12/13 Ver1.10 Mod End */
    
/* 2009/08/25 Ver1.8 Mod Start */
--    AND     xsel.unit_price_mst_flag = cv_flag_off
    AND     xsel.unit_price_mst_flag IN ( cv_flag_off, cv_flag_w )
/* 2009/08/25 Ver1.8 Mod End   */
    AND     NOT EXISTS
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--            (SELECT NULL
            (SELECT /*+ use_nl(flvl) */
                    NULL
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
             FROM   fnd_lookup_values flvl
             WHERE  flvl.lookup_type         = cv_lookup_type_gyotai
/* 2009/12/13 Ver1.10 Add Start */
             AND    flvl.lookup_code         != cv_lookup_cd_delivery_vd
/* 2009/12/13 Ver1.10 Add End */
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--             AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--             AND    flvl.language            = USERENV('LANG')
             AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
             AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                              AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
             AND     flvl.enabled_flag        = cv_flag_on
             AND xseh.cust_gyotai_sho = meaning )
    AND     NOT EXISTS
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
---            (SELECT NULL
            (SELECT /*+ use_nl(flvl) */
                    NULL
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
             FROM   fnd_lookup_values flvl
             WHERE  flvl.lookup_type         = cv_lookup_type_no_inv
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--             AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--             AND    flvl.language            = USERENV('LANG')
             AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
             AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                              AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
             AND     flvl.enabled_flag        = cv_flag_on
             AND xsel.item_code = lookup_code )
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    AND LENGTH( ABS( xsel.standard_qty ) )  <= cn_max_standard_qty
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    UNION
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--    SELECT  xseh.sales_exp_header_id          sales_exp_header_id               --�̔����уw�b�_ID
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--    SELECT  /*+ leading(inl1.inl2.xsel) use_nl(inl1.inl2.xsel inl1.inl2.xseh) */
    SELECT  /*+ leading(inl1.inl2.xsel) use_nl(inl1 xseh xsel) */
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
            xseh.sales_exp_header_id          sales_exp_header_id               --�̔����уw�b�_ID
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
           ,xseh.ship_to_customer_code        ship_to_customer_code             --�ڋq�y�[�i��z
           ,xseh.orig_delivery_date           delivery_date                     --�[�i���i�I���W�i���[�i���j
           ,xseh.tax_rate                     tax_rate                          --����ŗ�
           ,xsel.item_code                    item_code                         --�i�ڃR�[�h
           ,xsel.standard_unit_price_excluded standard_unit_price_excluded      --�Ŕ���P��
           ,xsel.standard_unit_price          standard_unit_price               --��P��
           ,xsel.standard_qty                 standard_qty                      --�����
           ,xsel.creation_date                creation_date                     --�쐬��
           ,xsel.sales_exp_line_id            sales_exp_line_id                 --�̔����і���ID
/* 2009/12/13 Ver1.10 Mod Start */
           ,CASE xseh.cust_gyotai_sho
               WHEN gv_delivery_vd THEN DECODE(xsel.sales_class ,gv_vd_sales_cls,gv_sales_cls_nml,xsel.sales_class)
               ELSE xsel.sales_class
            END                              sales_class
--           ,xsel.sales_class                  sales_class                       --����敪
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hca.tax_rounding_rule             tax_round_rule                 --�ŋ�-�[������
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xchv.bill_tax_round_rule          tax_round_rule
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    FROM    xxcos_sales_exp_headers xseh
           ,xxcos_sales_exp_lines   xsel
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----           ,hz_cust_accounts                  hca
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--           ,xxcos_cust_hierarchy_v              xchv                           -- �ڋq�K�w�r���[
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--           ,(SELECT  MAX(xseh.digestion_ln_number) digestion_ln_number
           ,(SELECT  /*+ use_nl(inl2 xseh) */
                     MAX(xseh.digestion_ln_number) digestion_ln_number
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                    ,inl2.order_no_hht
             FROM   xxcos_sales_exp_headers xseh
--****************************** 2009/08/04 1.6  M.Sano MOD START ***********************************--
--                   ,(SELECT xseh.order_no_hht order_no_hht
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--                   ,(SELECT /*+ index(xsel xxcos_sales_exp_lines_n02) */
                   ,(SELECT /*+ index(xsel xxcos_sales_exp_lines_n02) use_nl(xsel xseh) */
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                             xseh.order_no_hht order_no_hht
--****************************** 2009/08/04 1.6  M.Sano MOD End   ***********************************--
                     FROM    xxcos_sales_exp_headers xseh
                            ,xxcos_sales_exp_lines   xsel
                     WHERE   xseh.cancel_correct_class = cv_correct
                     AND     xseh.digestion_ln_number  = 1
                     AND     xseh.dlv_invoice_class IN (cv_invoice_class_dliv,cv_invoice_class_d_co)
/* 2009/08/25 Ver1.8 Mod Start */
--                     AND     xsel.unit_price_mst_flag  = cv_flag_off
                     AND     xsel.unit_price_mst_flag IN ( cv_flag_off, cv_flag_w )
/* 2009/08/25 Ver1.8 Mod End   */
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--                     AND     NOT EXISTS(SELECT NULL
                     AND     NOT EXISTS(SELECT /*+ use_nl(flvl) */
                                               NULL
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                                        FROM   fnd_lookup_values       flvl
                                        WHERE  flvl.lookup_type       = cv_lookup_type_gyotai
/* 2009/12/13 Ver1.10 Add Start */
                                        AND    flvl.lookup_code       != cv_lookup_cd_delivery_vd
/* 2009/12/13 Ver1.10 Add End */
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--                                        AND    flvl.security_group_id = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type
--                                                                                                ,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--                                        AND     flvl.language             = USERENV('LANG')
                                        AND     flvl.language             = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
                                        AND     TRUNC(SYSDATE)            BETWEEN flvl.start_date_active
                                                                          AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
                                        AND     flvl.enabled_flag         = cv_flag_on
                                        AND     xseh.cust_gyotai_sho      = flvl.meaning)
                     AND     xseh.sales_exp_header_id  =  xsel.sales_exp_header_id
                   ) inl2
             WHERE   xseh.order_no_hht = inl2.order_no_hht
             GROUP BY inl2.order_no_hht
            ) inl1
    WHERE   inl1.order_no_hht        = xseh.order_no_hht
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/06/09 1.4  N.Maeda MOD START ******************************--
------****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
----    AND     hca.account_number           = xseh.ship_to_customer_code
------****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--    AND     xchv.ship_account_number   = xseh.ship_to_customer_code
----****************************** 2009/06/09 1.4  N.Maeda MOD END ******************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
    AND     inl1.digestion_ln_number = xseh.digestion_ln_number
    AND     xseh.sales_exp_header_id = xsel.sales_exp_header_id
/* 2009/12/13 Ver1.10 Mod Start */
    AND    ( ( xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls))
              OR
             ( xseh.cust_gyotai_sho    = gv_delivery_vd ) AND ( xsel.sales_class = gv_vd_sales_cls ))
--    AND     xsel.sales_class         IN(gv_sales_cls_nml,gv_sales_cls_sls)
/* 2009/12/13 Ver1.10 Mod End */
--****************************** 2009/08/17 1.7  M.Sano MOD START ***********************************--
--    AND     NOT EXISTS(SELECT NULL
    AND     NOT EXISTS(SELECT /*+ use_nl(flvl) */
                              NULL
--****************************** 2009/08/17 1.7  M.Sano MOD End   ***********************************--
                       FROM   fnd_lookup_values flvl
                       WHERE  flvl.lookup_type         = cv_lookup_type_no_inv
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--                       AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--                       AND    flvl.language            = USERENV('LANG')
                       AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
                       AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                                        AND NVL(flvl.end_date_active, TRUNC(SYSDATE))
                       AND     flvl.enabled_flag        = cv_flag_on
                       AND xsel.item_code = lookup_code )
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    AND LENGTH( ABS( xsel.standard_qty ) )  <= cn_max_standard_qty
--****************************** 2009/12/17 1.11 N.Maeda ADD START ****************************--
    ORDER BY sales_exp_header_id
    ;
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
    main_rec main_cur%ROWTYPE;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
--  TYPE gt_ship_account IS TABLE OF xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE
--                          INDEX BY xxcos_cust_hierarchy_v.ship_account_number%TYPE; -- �ŋ�-�[�������ێ��e�[�u���^
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
/* 2009/08/25 Ver1.8 Add Start */
  TYPE gt_upd_header   IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE
                          INDEX BY BINARY_INTEGER;                                  -- �X�V�p�w�b�_ID�ێ��e�[�u���^
  TYPE gt_upd_line     IS TABLE OF ROWID
                          INDEX BY BINARY_INTEGER;                                  -- �X�V�p����ID�ێ��e�[�u���^
/* 2009/08/25 Ver1.8 Add End   */
  -- ===============================
  -- ���[�U�[��`�O���[�o���\
  -- ===============================
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
--  gt_ship_account_tbl gt_ship_account;                                              -- �ŋ�-�[�������ێ��e�[�u��
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
/* 2009/08/25 Ver1.8 Add Start */
  gt_upd_header_tab   gt_upd_header;                                                -- �X�V�p�w�b�_ID�ێ��e�[�u���^
/* 2009/08/25 Ver1.8 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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

    -- *** ���[�J���ϐ� ***
    lv_msg_tkn_sales_cls fnd_new_messages.message_text%TYPE;
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

-- 2009/02/24 T.Nakamura Ver.1.2 add start
    --��s
    FND_FILE.PUT_LINE(which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- �u�R���J�����g���̓p�����[�^�Ȃ��v���b�Z�[�W���o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(iv_application  => cv_appl_short_name
                                          ,iv_name         => cv_no_parameter
                                          );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => gv_out_msg
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --��s
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add start
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG
                     ,buff   => ''
                     );
-- 2009/02/24 T.Nakamura Ver.1.2 add end
    --==============================================================
    -- �}���`�o�C�g�̌Œ�l�����b�Z�[�W���擾
    --==============================================================
    gv_msg_tkn_tm_w_tbl         := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_tm_w_tbl
                                                           );
    gv_msg_tkn_cust_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_cust_code
                                                           );
    gv_msg_tkn_item_code        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_item_code
                                                           );
    gv_msg_tkn_exp_l_tbl        := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_l_tbl
                                                           );
    gv_msg_tkn_exp_line_id      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_line_id
                                                           );
    gv_msg_tkn_sales_cls_nml    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_nml
                                                           );
    gv_msg_tkn_sales_cls_sls    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_sls
                                                           );
    gv_msg_tkn_fnd_lookup_v     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_fnd_lookup_v
                                                           );
    gv_msg_tkn_lookup_type      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lookup_type
                                                           );
    gv_msg_tkn_meaning          := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_meaning
                                                           );
/* 2009/08/25 Ver1.8 Add Start */
    gv_msg_tkn_exp_header_id    := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_exp_header_id
                                                           );
/* 2009/08/25 Ver1.8 Add End   */
/* 2009/12/13 Ver1.10 Add Start */
    gv_msg_lookup_code      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lookup_code);
    gv_msg_lookup_type      := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_lookup_type1);
    gv_msg_sales_cls_vd     := xxccp_common_pkg.get_msg(iv_application  => cv_application
                                                           ,iv_name         => cv_tkn_sales_cls_vd);
/* 2009/12/13 Ver1.10 Add Start */
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
    --==============================================================
    -- �g�p������擾
    --==============================================================
    gv_language                 := USERENV('LANG');
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
    --==============================================================
    -- ����敪���Q�ƃ^�C�v���擾
    --==============================================================
    BEGIN
   --�ʏ�
      lv_msg_tkn_sales_cls := gv_msg_tkn_sales_cls_nml; --���b�Z�[�W�p�ϐ��Ɋi�[
      SELECT flvl.lookup_code lookup_code
      INTO   gv_sales_cls_nml
      FROM   fnd_lookup_values       flvl
      WHERE  flvl.lookup_type         = cv_lookup_type_sals_cls
      AND    flvl.meaning             = gv_msg_tkn_sales_cls_nml
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--      AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--      AND    flvl.language            = USERENV('LANG')
      AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
      AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                      AND NVL(flvl.end_date_active,TRUNC(SYSDATE))
      AND    flvl.enabled_flag        = cv_flag_on
      ;

     --����
      lv_msg_tkn_sales_cls := gv_msg_tkn_sales_cls_sls; --���b�Z�[�W�p�ϐ��Ɋi�[
      SELECT flvl.lookup_code lookup_code
      INTO   gv_sales_cls_sls
      FROM   fnd_lookup_values flvl
      WHERE  flvl.lookup_type         = cv_lookup_type_sals_cls
      AND    flvl.meaning             = gv_msg_tkn_sales_cls_sls
--****************************** 2009/08/17 1.7  M.Sano DEL START ***********************************--
--      AND    flvl.security_group_id   = FND_GLOBAL.LOOKUP_SECURITY_GROUP(flvl.lookup_type,flvl.view_application_id)
--****************************** 2009/08/17 1.7  M.Sano DEL End   ***********************************--
--****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
--      AND    flvl.language            = USERENV('LANG')
      AND    flvl.language            = gv_language
--****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
      AND    TRUNC(SYSDATE)           BETWEEN flvl.start_date_active
                                      AND NVL(flvl.end_date_active,TRUNC(SYSDATE))
      AND    flvl.enabled_flag        = cv_flag_on
      ;
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info                    --�L�[���
                                        ,iv_item_name1  => gv_msg_tkn_lookup_type         --���ږ���1
                                        ,iv_data_value1 => cv_lookup_type_sals_cls        --�f�[�^�̒l1
                                        ,iv_item_name2  => gv_msg_tkn_meaning             --���ږ���2
                                        ,iv_data_value2 => lv_msg_tkn_sales_cls           --�f�[�^�̒l2
                                        );
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_select_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_fnd_lookup_v
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        RAISE;
    END;
/* 2009/12/13 Ver1.10 Add Start */
    -- �[�iVD�̋Ƒԏ����ރR�[�h�擾
    BEGIN
      SELECT flv.meaning
      INTO   gv_delivery_vd
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type  = cv_lookup_type_gyotai
      AND    flv.lookup_code  = cv_lookup_cd_delivery_vd
      AND    flv.enabled_flag = cv_flag_on
      AND    TRUNC(SYSDATE)   BETWEEN flv.start_date_active
                              AND NVL(flv.end_date_active,TRUNC(SYSDATE))
      AND    flv.language     = gv_language;
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info                    --�L�[���
                                        ,iv_item_name1  => gv_msg_lookup_type         --���ږ���1
                                        ,iv_data_value1 => cv_lookup_type_gyotai        --�f�[�^�̒l1
                                        ,iv_item_name2  => gv_msg_lookup_code             --���ږ���2gv_msg_tkn_meaning
                                        ,iv_data_value2 => cv_lookup_cd_delivery_vd       --�f�[�^�̒l2
                                        );
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_select_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_fnd_lookup_v
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        RAISE;
    END;
    --
    -- �x���_�[����̔���敪�擾
    BEGIN
      SELECT flv.lookup_code lookup_code
      INTO   gv_vd_sales_cls
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type         = cv_lookup_type_sals_cls
      AND    flv.meaning             = gv_msg_sales_cls_vd
      AND    flv.language            = gv_language
      AND    TRUNC(SYSDATE)           BETWEEN flv.start_date_active
                                      AND NVL(flv.end_date_active,TRUNC(SYSDATE))
      AND    flv.enabled_flag        = cv_flag_on
      ;
    EXCEPTION
      WHEN OTHERS THEN
        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info                    --�L�[���
                                        ,iv_item_name1  => gv_msg_lookup_type         --���ږ���1
                                        ,iv_data_value1 => cv_lookup_type_sals_cls        --�f�[�^�̒l1
                                        ,iv_item_name2  => gv_msg_tkn_meaning             --���ږ���2
                                        ,iv_data_value2 => gv_msg_sales_cls_vd        --�f�[�^�̒l2
                                        );
        ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_select_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_fnd_lookup_v
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        RAISE;
    END;
/* 2009/12/13 Ver1.10 Add End */
--
--
  EXCEPTION
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
/* 2009/08/25 Ver1.8 Add Start */
  /**********************************************************************************
   * Procedure Name   : proc_upd_n_target_line
   * Description      : A-8�D�̔����і��בΏۊO�f�[�^�X�V
   ***********************************************************************************/
  PROCEDURE proc_upd_n_target_line(
    ov_errbuf             OUT VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_n_target_line'; -- �v���O������
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
    -- *** ���[�J���E�e�[�u�� ***
    lt_upd_line_tab  gt_upd_line;  --���׍X�V�p
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
    BEGIN
--
      --�̔����і��׃��b�N(�ΏۊO�f�[�^�S��)
      SELECT /*+ INDEX(xsel xxcos_sales_exp_lines_n02) */
             xsel.ROWID row_id
      BULK COLLECT INTO
             lt_upd_line_tab
      FROM   xxcos_sales_exp_lines xsel
      WHERE  xsel.unit_price_mst_flag = cv_flag_off  --�������I�����"N"�Ŏc���Ă������
      FOR UPDATE OF
             xsel.sales_exp_line_id
      NOWAIT
      ;
--
      --�̔����і��׍X�V
      FORALL i IN 1..lt_upd_line_tab.COUNT
        UPDATE xxcos_sales_exp_lines xsel
        SET    xsel.unit_price_mst_flag        = cv_flag_s                  --�P���}�X�^�쐬�σt���O(�ΏۊO)
              ,xsel.last_updated_by            = cn_last_updated_by         --�ŏI�X�V��
              ,xsel.last_update_date           = cd_last_update_date        --�ŏI�X�V��
              ,xsel.last_update_login          = cn_last_update_login       --�ŏI�X�V���O�C��
              ,xsel.request_id                 = cn_request_id              --�v��ID
              ,xsel.program_application_id     = cn_program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              ,xsel.program_id                 = cn_program_id              --�R���J�����g�E�v���O����ID
              ,xsel.program_update_date        = cd_program_update_date     --�v���O�����X�V��
        WHERE  xsel.ROWID  = lt_upd_line_tab(i)
        ;
--
    EXCEPTION
      WHEN OTHERS THEN
--
        lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        --���b�N�G���[�̏ꍇ
        IF ( SQLCODE = cn_lock_error_code ) THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                           cv_application
                          ,cv_msg_lock
                          ,cv_tkn_lock
                          ,gv_msg_tkn_exp_l_tbl
                        );
        --���̑��̏ꍇ
        ELSE
          lv_errmsg := xxccp_common_pkg.get_msg(
                          cv_application
                         ,cv_msg_n_target_upd_err
                       );
        END IF;
        --�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --�G���[���b�Z�[�W
        );
        ov_retcode := cv_status_warn;
--
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
  END proc_upd_n_target_line;
--
  /**********************************************************************************
   * Procedure Name   : proc_upd_skip_line
   * Description      : A-7�D�̔����і��׃X�L�b�v�f�[�^�X�V
   ***********************************************************************************/
  PROCEDURE proc_upd_skip_line(
    it_sales_header_tab   IN  gt_upd_header,  --   �X�V�Ώۃw�b�_ID
    ov_errbuf             OUT VARCHAR2,       --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,       --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_upd_skip_line'; -- �v���O������
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
    lv_buf     VARCHAR2(5000);      --�G���[�E���b�Z�[�W(�L�[���ҏW�p)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    lt_upd_line_tab   gt_upd_line;  --���׍X�V�p(�w�b�_�P�ʂŕێ�)
    lt_upd_line_tab_f gt_upd_line;  --�������p
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
    FOR i IN 1..it_sales_header_tab.COUNT LOOP
--
      BEGIN
--
        --������
        lt_upd_line_tab := lt_upd_line_tab_f;
--
        --�̔����і��׃��b�N(�w�b�_�P��)
        SELECT xsel.ROWID row_id
        BULK COLLECT INTO
               lt_upd_line_tab
        FROM   xxcos_sales_exp_lines xsel
        WHERE  xsel.sales_exp_header_id = it_sales_header_tab(i)
        FOR UPDATE OF
               xsel.sales_exp_line_id
        NOWAIT
        ;
--
        --�̔����і��׍X�V(�w�b�_�P��)
        FORALL j IN 1..lt_upd_line_tab.COUNT
          UPDATE xxcos_sales_exp_lines xsel
          SET    unit_price_mst_flag        = cv_flag_w                  --�P���}�X�^�쐬�σt���O(�x��)
                ,last_updated_by            = cn_last_updated_by         --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date        --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login       --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id              --�v��ID
                ,program_application_id     = cn_program_application_id  --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id              --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date     --�v���O�����X�V��
          WHERE  xsel.ROWID  = lt_upd_line_tab(j)
          ;
--
      EXCEPTION
        WHEN OTHERS THEN
--
          lv_errbuf := SQLERRM;
          --���b�N�G���[�̏ꍇ
          IF ( SQLCODE = cn_lock_error_code ) THEN
            lv_errmsg  := xxccp_common_pkg.get_msg(
                             cv_application
                            ,cv_msg_lock
                            ,cv_tkn_lock
                            ,gv_msg_tkn_exp_l_tbl
                          );
          --���̑��̏ꍇ
          ELSE
            xxcos_common_pkg.makeup_key_info(
               ov_errbuf      => lv_buf                     --�G���[�E���b�Z�[�W
              ,ov_retcode     => lv_retcode                 --���^�[���E�R�[�h
              ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
              ,ov_key_info    => gv_key_info                --�L�[���
              ,iv_item_name1  => gv_msg_tkn_exp_header_id   --���ږ���1
              ,iv_data_value1 => it_sales_header_tab(i)     --�f�[�^�̒l1
            );
            lv_errmsg := xxccp_common_pkg.get_msg(
                            cv_application
                           ,cv_msg_update_err
                           ,cv_tkn_table_name
                           ,gv_msg_tkn_exp_l_tbl
                           ,cv_tkn_key_data
                           ,gv_key_info
                         );
          END IF;
--
          --�x���f�[�^��S�ăG���[�����Ƃ���
          gn_error_cnt := gn_warn_cnt;
--
          RAISE global_api_expt;
--
      END;
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
  END proc_upd_skip_line;
/* 2009/08/25 Ver1.8 Add End   */
--
  /**********************************************************************************
   * Procedure Name   : proc_insert_upm_work
   * Description      : A-4�D�P���}�X�^���[�N�e�[�u���o�^
   ***********************************************************************************/
  PROCEDURE proc_insert_upm_work(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_insert_upm_work'; -- �v���O������
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
      -- ===============================
      --A-4�D�P���}�X�^���[�N�e�[�u���o�^
      -- ===============================
        BEGIN
          CASE
            WHEN main_rec.sales_class   = gv_sales_cls_nml THEN
              INSERT INTO xxcos_unit_price_mst_work(
                 customer_number          --�ڋq�R�[�h
                ,item_code                --�i���R�[�h
                ,nml_prev_unit_price      --�ʏ�@�O��@�P��
                ,nml_prev_dlv_date        --�ʏ�@�O��@�[�i�N����
                ,nml_prev_qty             --�ʏ�@�O��@����
                ,nml_prev_clt_date        --�ʏ�@�O��@�쐬��
                ,file_output_flag         --�t�@�C���o�͍σt���O
                --WHO�J����
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )VALUES(
                 main_rec.ship_to_customer_code        --�ڋq�R�[�h
                ,main_rec.item_code                    --�i���R�[�h
                ,gn_unit_price                         --�ʏ�@�O��@�P��
                ,main_rec.delivery_date                --�ʏ�@�O��@�[�i�N����
                ,main_rec.standard_qty                 --�ʏ�@�O��@����
                ,main_rec.creation_date                --�ʏ�@�O��@�쐬��
                ,cv_flag_off                           --�t�@�C���o�͍σt���O
                ,cn_created_by
                ,cd_creation_date
                ,cn_last_updated_by
                ,cd_last_update_date
                ,cn_last_update_login
                ,cn_request_id
                ,cn_program_application_id
                ,cn_program_id
                ,cd_program_update_date
               );
            WHEN main_rec.sales_class   = gv_sales_cls_sls THEN
              INSERT INTO xxcos_unit_price_mst_work(
                 customer_number          --�ڋq�R�[�h
                ,item_code                --�i���R�[�h
                ,sls_prev_unit_price      --�����@�O��@�P��
                ,sls_prev_dlv_date        --�����@�O��@�[�i�N����
                ,sls_prev_qty             --�����@�O��@����
                ,sls_prev_clt_date        --�����@�O��@�쐬��
                ,file_output_flag         --�t�@�C���o�͍σt���O
                --WHO�J����
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date
                ,last_update_login
                ,request_id
                ,program_application_id
                ,program_id
                ,program_update_date
              )VALUES(
                 main_rec.ship_to_customer_code        --�ڋq�R�[�h
                ,main_rec.item_code                    --�i���R�[�h
                ,gn_unit_price                         --�����@�O��@�P��
                ,main_rec.delivery_date                --�����@�O��@�[�i�N����
                ,main_rec.standard_qty                 --�����@�O��@����
                ,main_rec.creation_date                --�����@�O��@�쐬��
                ,cv_flag_off                           --�t�@�C���o�͍σt���O
                ,cn_created_by
                ,cd_creation_date
                ,cn_last_updated_by
                ,cd_last_update_date
                ,cn_last_update_login
                ,cn_request_id
                ,cn_program_application_id
                ,cn_program_id
                ,cd_program_update_date
               );
          END CASE;
/* 2009/08/25 Ver1.8 Add Start */
          gv_edit_unit_price_flag := cv_flag_on; --�P���ҏW�t���O'Y'
/* 2009/08/25 Ver1.8 Add End   */
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                    --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_cust_code           --���ږ���1
                                            ,iv_data_value1 => main_rec.ship_to_customer_code --�f�[�^�̒l1
                                            ,iv_item_name2  => gv_msg_tkn_item_code           --���ږ���2
                                            ,iv_data_value2 => main_rec.item_code             --�f�[�^�̒l2
                                            );
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_insert_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_tm_w_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            ov_retcode := cv_status_warn;
            ov_errmsg  := lv_errmsg;
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
  END proc_insert_upm_work;

  /**********************************************************************************
   * Procedure Name   : proc_update_upm_work
   * Description      : A-3�D�P���}�X�^���[�N�e�[�u���X�V
   ***********************************************************************************/
  PROCEDURE proc_update_upm_work(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_update_upm_work'; -- �v���O������
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
    ln_update_pattern NUMBER;
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
    ln_update_pattern := '';
      -- ===============================
      --A-3�D�P���}�X�^���[�N�e�[�u���X�V
      -- ===============================
 --�@����敪���ʏ킩�A�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 --�����V�������R�[�h�����������ꍇ
    IF    (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date > gd_nml_prev_dlv_date)
    THEN
      ln_update_pattern := 1;

 --�A����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 --�����Â��A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date >  gd_nml_bef_prev_dlv_date)
    THEN
      ln_update_pattern := 2;

 --�B����敪���������A�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v
 --�����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date > gd_sls_prev_dlv_date)
    THEN
      ln_update_pattern := 3;

 --�C����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v
 --�����Â��A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date)
    THEN
      ln_update_pattern := 4;

 --�D����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���Ɂu�ʏ�@�O��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date > gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_prev_clt_date)
    THEN
      ln_update_pattern := 1;

 --�E����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date > gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date)
    THEN
      ln_update_pattern := 2;

 --�F����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_prev_clt_date)
    THEN
      ln_update_pattern := 1;

 --�G����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date
    AND    main_rec.creation_date > gd_nml_bef_prev_clt_date)
    THEN
      ln_update_pattern := 2;

 --�H����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date = gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_prev_clt_date
    AND    main_rec.creation_date < gd_nml_bef_prev_clt_date)
    THEN
      NULL;

 --�I����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_prev_clt_date)
    THEN
      ln_update_pattern := 3;

 --�J����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����V�����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date > gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date)
    THEN
      ln_update_pattern := 4;

 --�K����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_prev_clt_date)
    THEN
      ln_update_pattern := 3;

 --�L����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date
    AND    main_rec.creation_date > gd_sls_bef_prev_clt_date)
    THEN
      ln_update_pattern := 4;

 --�M����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�@�Ɠ����A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â��A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date = gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_prev_clt_date
    AND    main_rec.creation_date < gd_sls_bef_prev_clt_date)
    THEN
      NULL;

 --�N����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 --�����Â����R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml
    AND    main_rec.delivery_date   <  gd_nml_prev_dlv_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 2;

 --�O����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_nml_bef_prev_clt_date)
    THEN
      ln_update_pattern := 2;

 --�P����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_nml
    AND    main_rec.delivery_date < gd_nml_prev_dlv_date
    AND    main_rec.delivery_date = gd_nml_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_nml_bef_prev_clt_date)
    THEN
      NULL;

 --�Q����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v
 -- �����Â����R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   <  gd_sls_prev_dlv_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 4;

 --�R����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date > gd_sls_bef_prev_clt_date)
    THEN
      ln_update_pattern := 4;

 --�S����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v
 -- �����Â��A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�Ɠ����A
 -- ���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class   = gv_sales_cls_sls
    AND    main_rec.delivery_date < gd_sls_prev_dlv_date
    AND    main_rec.delivery_date = gd_sls_bef_prev_dlv_date
    AND    main_rec.creation_date < gd_sls_bef_prev_clt_date)
    THEN
      NULL;

 --21.����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����ݒ�A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml
    AND    main_rec.delivery_date   =  gd_nml_prev_dlv_date
    AND    main_rec.creation_date   >  gd_nml_prev_clt_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 1;

 --22.����敪���ʏ킩�A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O�X��@�[�i�N�����v�����ݒ�A
 -- ���P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_nml
    AND    main_rec.delivery_date   =  gd_nml_prev_dlv_date
    AND    main_rec.creation_date   <  gd_nml_prev_clt_date
    AND    gd_nml_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 2;

 --23.����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����ݒ�A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����V�������R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   =  gd_sls_prev_dlv_date
    AND    main_rec.creation_date   >  gd_sls_prev_clt_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 3;

 --24.����敪���������A�@�̔����уw�b�_�e�[�u��.�[�i���ɒP���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v
 -- �Ɠ������R�[�h���������A���P���}�X�^���[�N�e�[�u���́u�����@�O�X��@�[�i�N�����v�����ݒ�A
 --���P���}�X�^���[�N�e�[�u���́u�����@�O��@�쐬���v���̔����т̍쐬���̂ق����Â����R�[�h�����������ꍇ
    ELSIF (main_rec.sales_class     =  gv_sales_cls_sls
    AND    main_rec.delivery_date   =  gd_sls_prev_dlv_date
    AND    main_rec.creation_date   <  gd_sls_prev_clt_date
    AND    gd_sls_bef_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 4;

 --25.����敪���ʏ킩�A�P���}�X�^���[�N�e�[�u���́u�ʏ�@�O��@�[�i�N�����v�@�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class =  gv_sales_cls_nml
    AND    gd_nml_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 1;

 --26.����敪���������A�P���}�X�^���[�N�e�[�u���́u�����@�O��@�[�i�N�����v�@�����ݒ�̏ꍇ
    ELSIF (main_rec.sales_class =  gv_sales_cls_sls
    AND    gd_sls_prev_dlv_date IS NULL)
    THEN
      ln_update_pattern := 3;

  --��L�ȊO
    ELSE
      NULL;
    END IF;
    BEGIN
    --�p�^�[���P
      CASE
        WHEN ln_update_pattern = 1 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    nml_prev_unit_price        = gn_unit_price                         --�ʏ�@�O��@�P��
                ,nml_prev_dlv_date          = main_rec.delivery_date                --�ʏ�@�O��@�[�i�N����
                ,nml_prev_qty               = main_rec.standard_qty                 --�ʏ�@�O��@����
                ,nml_prev_clt_date          = main_rec.creation_date                --�ʏ�@�O��@�쐬��
                ,nml_bef_prev_dlv_date      = nml_prev_dlv_date                     --�ʏ�@�O�X��@�[�i�N����
                ,nml_bef_prev_qty           = nml_prev_qty                          --�ʏ�@�O�X��@����
                ,nml_bef_prev_clt_date      = nml_prev_clt_date                     --�ʏ�@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
/* 2009/08/25 Ver1.8 Add Start */
          gv_edit_unit_price_flag := cv_flag_on; --�P���ҏW�t���O'Y'
/* 2009/08/25 Ver1.8 Add End   */
        WHEN ln_update_pattern = 2 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    nml_bef_prev_dlv_date      = main_rec.delivery_date                --�ʏ�@�O�X��@�[�i�N����
                ,nml_bef_prev_qty           = main_rec.standard_qty                 --�ʏ�@�O�X��@����
                ,nml_bef_prev_clt_date      = main_rec.creation_date                --�ʏ�@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
        WHEN ln_update_pattern = 3 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    sls_prev_unit_price        = gn_unit_price                         --�����@�O��@�P��
                ,sls_prev_dlv_date          = main_rec.delivery_date                --�����@�O��@�[�i�N����
                ,sls_prev_qty               = main_rec.standard_qty                 --�����@�O��@����
                ,sls_prev_clt_date          = main_rec.creation_date                --�����@�O��@�쐬��
                ,sls_bef_prev_dlv_date      = sls_prev_dlv_date                     --�����@�O�X��@�[�i�N����
                ,sls_bef_prev_qty           = sls_prev_qty                          --�����@�O�X��@����
                ,sls_bef_prev_clt_date      = sls_prev_clt_date                     --�����@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
/* 2009/08/25 Ver1.8 Add Start */
          gv_edit_unit_price_flag := cv_flag_on; --�P���ҏW�t���O'Y'
/* 2009/08/25 Ver1.8 Add End   */
        WHEN ln_update_pattern = 4 THEN
          UPDATE xxcos_unit_price_mst_work
          SET    sls_bef_prev_dlv_date      = main_rec.delivery_date                --�����@�O�X��@�[�i�N����
                ,sls_bef_prev_qty           = main_rec.standard_qty                 --�����@�O�X��@����
                ,sls_bef_prev_clt_date      = main_rec.creation_date                --�����@�O�X��@�쐬��
                ,file_output_flag           = cv_flag_off                           --�t�@�C���o�͍σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  customer_number            = gv_customer_number
          AND    item_code                  = gv_item_code
          ;
        ELSE
          gn_skip_cnt := gn_skip_cnt + 1;
      END CASE;
    EXCEPTION
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

        xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                -- �G���[�E���b�Z�[�W
                                        ,ov_retcode     => lv_retcode               -- ���^�[���E�R�[�h
                                        ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
                                        ,ov_key_info    => gv_key_info              --�L�[���
                                        ,iv_item_name1  => gv_msg_tkn_cust_code     --���ږ���1
                                        ,iv_data_value1 => gv_customer_number       --�f�[�^�̒l1
                                        ,iv_item_name2  => gv_msg_tkn_item_code     --���ږ���2
                                        ,iv_data_value2 => main_rec.item_code       --�f�[�^�̒l2
                                        );
        lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                            , cv_msg_update_err
                                            , cv_tkn_table_name
                                            , gv_msg_tkn_tm_w_tbl
                                            , cv_tkn_key_data
                                            , gv_key_info
                                            );
        ov_retcode := cv_status_warn;
        ov_errmsg  := lv_errmsg;
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
  END proc_update_upm_work;
--
  /**********************************************************************************
   * Procedure Name   : proc_main_loop�i���[�v���j
   * Description      : A-1�f�[�^���o
   ***********************************************************************************/
  PROCEDURE proc_main_loop(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_main_loop'; -- ���C�����[�v����
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
    upm_work_exp      EXCEPTION;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
    get_tax_rule_exp  EXCEPTION;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message_code          VARCHAR2(20);
    ln_update_pattrun        NUMBER;
    lv_sales_exp_line_id     xxcos_sales_exp_lines.sales_exp_line_id%TYPE; --�����p�_�~�[�ϐ�
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
----****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
--    ln_unit_price            NUMBER;
----****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
----****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
--    lv_tax_round_rule        xxcos_cust_hierarchy_v.bill_tax_round_rule%TYPE; --�ŋ�-�[���������[��
----****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
/* 2009/08/25 Ver1.8 Add Start */
    ln_skip_seq              PLS_INTEGER := 0;  --�X�L�b�v�f�[�^�e�[�u���̓Y��
    ln_unit_price_length     NUMBER;            --�P���̐������̒����擾�ϐ�
    ln_unit_price_org        NUMBER;            --���b�Z�[�W�p�ҏW�O�P��
/* 2009/08/25 Ver1.8 Add End   */
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
    <<main_loop>>
    LOOP
      FETCH main_cur INTO main_rec;
      EXIT WHEN main_cur%NOTFOUND;
      BEGIN
        -- ===============================
        --�̔����уw�b�_ID�u���C�N����
        -- ===============================
        --�G���[�J�E���g
        gn_warn_tran_count     := gn_warn_tran_count + gn_new_warn_count;
        --1���[�v���G���[������
        gn_new_warn_count := 0;
/* 2009/08/25 Ver1.8 Add Start */
        gv_edit_unit_price_flag := cv_flag_off; --�P���ҏW�t���O������
        ln_unit_price_length    := NULL;        --�P���̐������̒����擾�ϐ��̏�����
        ln_unit_price_org       := NULL;        --���b�Z�[�W�p�ҏW�O�P���̏�����
/* 2009/08/25 Ver1.8 Add End   */
--
        IF (main_rec.sales_exp_header_id <> gv_bf_sales_exp_header_id) THEN
          IF (gn_warn_tran_count > 0) THEN
            ROLLBACK;
            gn_warn_cnt := gn_warn_cnt + gn_tran_count;
/* 2009/08/25 Ver1.8 Add Start */
            --�x���ɂȂ����̔����уw�b�_ID�ҏW
            ln_skip_seq                    := ln_skip_seq + 1;
            gt_upd_header_tab(ln_skip_seq) := gv_bf_sales_exp_header_id;
/* 2009/08/25 Ver1.8 Add End   */
          ELSE
            COMMIT;
            gn_normal_cnt := gn_normal_cnt + gn_tran_count;
          END IF;
          gn_warn_tran_count := 0;
          gn_tran_count      := 0;
        END IF;
--
        --�u���C�N����L�[����ւ�
        gv_bf_sales_exp_header_id := main_rec.sales_exp_header_id;
--
--
        --�����J�E���^
        gn_target_cnt := gn_target_cnt + 1;
        gn_tran_count := gn_tran_count + 1;
--
-- ***************** 2009/10/15 1.9 N.Maeda DEL START ***************** --
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
--        -- ===============================
--        -- �ŋ�-�[���������̎擾
--        -- ===============================
--        IF (gt_ship_account_tbl.EXISTS(main_rec.ship_to_customer_code)) THEN
--          lv_tax_round_rule := gt_ship_account_tbl(main_rec.ship_to_customer_code);
--        ELSE
--          BEGIN
--            SELECT xchv.bill_tax_round_rule
--            INTO   lv_tax_round_rule
--            FROM   xxcos_cust_hierarchy_v xchv -- �ڋq�K�w�r���[
--            WHERE  xchv.ship_account_number = main_rec.ship_to_customer_code;
--          EXCEPTION
--            WHEN OTHERS THEN
--              RAISE get_tax_rule_exp;
--          END;
--          --
--          IF lv_tax_round_rule IS NULL THEN
--            RAISE get_tax_rule_exp;
--          ELSE
--            gt_ship_account_tbl(main_rec.ship_to_customer_code) := lv_tax_round_rule;
--          END IF;
--        END IF;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
-- ***************** 2009/10/15 1.9 N.Maeda DEL  END  ***************** --
        -- ===============================
        --�P���̓��o
        -- ===============================
-- ***************** 2009/10/15 1.9 N.Maeda MOD START ***************** --
----****************************** 2009/05/27 1.3  S.Kayahara MOD START ******************************--
--        --�ϐ��̑��
--        ln_unit_price := main_rec.standard_unit_price_excluded * (1 + (main_rec.tax_rate / 100));
----****************************** 2009/05/27 1.3  S.Kayahara MOD END ******************************--
--        IF main_rec.standard_unit_price_excluded = main_rec.standard_unit_price THEN
----****************************** 2009/07/17 1.5  K.Shirasuna MOD START ******************************--
----****************************** 2009/05/28 1.3  S.Kayahara MOD START ******************************--
--   --       gn_unit_price := trunc(main_rec.standard_unit_price_excluded * (1 + (main_rec.tax_rate / 100)),0);
--          -- �؏グ
----          IF main_rec.tax_round_rule    = cv_amount_up THEN
--          IF lv_tax_round_rule    = cv_amount_up THEN
--            -- �����_�����݂���ꍇ
--            IF (ln_unit_price - TRUNC(ln_unit_price) <> 0 ) THEN
--              gn_unit_price := TRUNC(ln_unit_price,2) + 0.01;
--            ELSE gn_unit_price := ln_unit_price;
--            END IF;
--          -- �؎̂�
----          ELSIF main_rec.tax_round_rule = cv_amount_down THEN
--          ELSIF lv_tax_round_rule = cv_amount_down THEN
--            gn_unit_price := TRUNC(ln_unit_price,2);
--          -- �l�̌ܓ�
----          ELSIF main_rec.tax_round_rule = cv_amount_nearest THEN
--          ELSIF lv_tax_round_rule = cv_amount_nearest THEN
--            gn_unit_price := ROUND(ln_unit_price,2);
--          END IF;
----****************************** 2009/05/28 1.3  S.Kayahara MOD END ******************************--
----****************************** 2009/07/17 1.5  K.Shirasuna MOD END ********************************--
--        ELSE
--          gn_unit_price := main_rec.standard_unit_price;
--        END IF;
--
        gn_unit_price := main_rec.standard_unit_price;
--
-- ***************** 2009/10/15 1.9 N.Maeda MOD  END  ***************** --
/* 2009/08/25 Ver1.8 Add Start */
--
        --�P���̐������̒������擾
        ln_unit_price_length :=  LENGTHB( TO_CHAR( TRUNC(gn_unit_price) ) );
        --�P���̐�������4���𒴂���ꍇ
        IF ( ln_unit_price_length > 4 ) THEN
          --�ҏW�O�̒P����ޔ�
          ln_unit_price_org := gn_unit_price;
          --����������4���ɂȂ�悤�ɕҏW(�������͂��̂܂�)
          gn_unit_price     := TO_NUMBER( SUBSTRB( TO_CHAR(gn_unit_price), ln_unit_price_length -3 ) );
        END IF;
--
/* 2009/08/25 Ver1.8 Add End   */
        -- ===============================
        -- A-2�D�P���}�X�^���[�N�e�[�u�����R�[�h���b�N
        -- ===============================
        BEGIN
          gv_tkn_lock_table := gv_msg_tkn_tm_w_tbl;
          SELECT  xupm.customer_number       customer_number       --�ڋq�R�[�h
                 ,xupm.item_code             item_code             --�i�ڃR�[�h
                 ,xupm.nml_prev_dlv_date     nml_prev_dlv_date     --�ʏ�@�O��@�[�i�N����
                 ,xupm.nml_bef_prev_dlv_date nml_bef_prev_dlv_date --�ʏ�@�O�X��@�[�i�N����
                 ,xupm.sls_prev_dlv_date     sls_prev_dlv_date     --�����@�O��@�[�i�N����
                 ,xupm.sls_bef_prev_dlv_date sls_bef_prev_dlv_date --�����@�O�X��@�[�i�N����
                 ,xupm.nml_prev_clt_date     nml_prev_clt_date     --�ʏ�@�O��@�쐬��
                 ,xupm.nml_bef_prev_clt_date nml_bef_prev_clt_date --�ʏ�@�O�X��@�쐬��
                 ,xupm.sls_prev_clt_date     sls_prev_clt_date     --�����@�O��@�쐬��
                 ,xupm.sls_bef_prev_clt_date sls_bef_prev_clt_date --�����@�O�X��@�쐬��
          INTO    gv_customer_number       --�ڋq�R�[�h
                 ,gv_item_code             --�i�ڃR�[�h
                 ,gd_nml_prev_dlv_date     --�ʏ�@�O��@�[�i�N����
                 ,gd_nml_bef_prev_dlv_date --�ʏ�@�O�X��@�[�i�N����
                 ,gd_sls_prev_dlv_date     --�����@�O��@�[�i�N����
                 ,gd_sls_bef_prev_dlv_date --�����@�O�X��@�[�i�N����
                 ,gd_nml_prev_clt_date        --�ʏ�@�O��@�쐬��
                 ,gd_nml_bef_prev_clt_date    --�ʏ�@�O�X��@�쐬��
                 ,gd_sls_prev_clt_date        --�����@�O��@�쐬��
                 ,gd_sls_bef_prev_clt_date    --�����@�O�X��@�쐬��
          FROM    xxcos_unit_price_mst_work xupm
          WHERE   xupm.customer_number = main_rec.ship_to_customer_code
          AND     xupm.item_code       = main_rec.item_code
          FOR UPDATE NOWAIT
          ;

        -- ===============================
        --A-3�D�P���}�X�^���[�N�e�[�u���X�V
        -- ===============================
          proc_update_upm_work(
                               lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                              ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                              ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                              );
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE upm_work_exp;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
        -- ===============================
        --A-4�D�P���}�X�^���[�N�e�[�u���o�^
        -- ===============================
            proc_insert_upm_work(
                                 lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
                                ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
                                ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
                                );
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE upm_work_exp;
            END IF;
        END;
/* 2009/08/25 Ver1.8 Add Start */
        --�P����ݒ�(�X�V)����p�^�[���A���A�P�����ҏW����Ă���ꍇ
        IF ( ln_unit_price_length > 4 )
          AND
           ( gv_edit_unit_price_flag = cv_flag_on )
        THEN
          --�P���ҏW���b�Z�[�W��\������
          lv_errmsg := xxccp_common_pkg.get_msg(
                          cv_application
                         ,cv_msg_edit_unit_price
                         ,cv_tkn_cust
                         ,main_rec.ship_to_customer_code
                         ,cv_tkn_item
                         ,main_rec.item_code
                         ,cv_tkn_dlv_date
                         ,TO_CHAR(main_rec.delivery_date, cv_fmt_date)
                         ,cv_tkn_unit_price
                         ,TO_CHAR(ln_unit_price_org)
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => lv_errmsg
          );
          --�I�����b�Z�[�W�̋�s����p�Ƀt���O�𗧂Ă�
          gv_empty_line_flag := cv_flag_on;
        END IF;
/* 2009/08/25 Ver1.8 Add End   */
        BEGIN
          -- ===============================
          --A-5�D�̔����і��׃e�[�u�����R�[�h���b�N
          -- ===============================
          gv_tkn_lock_table := gv_msg_tkn_exp_l_tbl;
          SELECT  xsel.sales_exp_line_id sales_exp_line_id       --�̔����і���ID
          INTO    lv_sales_exp_line_id                           --�̔����і���ID
          FROM    xxcos_sales_exp_lines  xsel
          WHERE   xsel.sales_exp_line_id = main_rec.sales_exp_line_id
          FOR UPDATE NOWAIT
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                      -- �G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                     -- ���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                      --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                    --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_exp_line_id         --���ږ���1
                                            ,iv_data_value1 => main_rec.sales_exp_line_id     --�f�[�^�̒l1
                                            );
            lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_select_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_exp_l_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            RAISE;
        END;
--
        -- ===============================
        --A-6�D �̔����і��׃e�[�u���X�e�[�^�X�X�V
        -- ===============================
        BEGIN
          UPDATE xxcos_sales_exp_lines
          SET    unit_price_mst_flag        = cv_flag_on                            --�P���}�X�^�쐬�σt���O
                ,last_updated_by            = cn_last_updated_by                    --�ŏI�X�V��
                ,last_update_date           = cd_last_update_date                   --�ŏI�X�V��
                ,last_update_login          = cn_last_update_login                  --�ŏI�X�V���O�C��
                ,request_id                 = cn_request_id                         --�v��ID
                ,program_application_id     = cn_program_application_id             --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                ,program_id                 = cn_program_id                         --�R���J�����g�E�v���O����ID
                ,program_update_date        = cd_program_update_date                --�v���O�����X�V��
          WHERE  sales_exp_line_id          = main_rec.sales_exp_line_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;

            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf                  -- �G���[�E���b�Z�[�W
                                            ,ov_retcode     => lv_retcode                 -- ���^�[���E�R�[�h
                                            ,ov_errmsg      => lv_errmsg                  --���[�U�[�E�G���[�E���b�Z�[�W
                                            ,ov_key_info    => gv_key_info                --�L�[���
                                            ,iv_item_name1  => gv_msg_tkn_exp_line_id     --���ږ���1
                                            ,iv_data_value1 => main_rec.sales_exp_line_id --�f�[�^�̒l1
                                            );
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_update_err
                                                , cv_tkn_table_name
                                                , gv_msg_tkn_exp_l_tbl
                                                , cv_tkn_key_data
                                                , gv_key_info
                                                );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.OUTPUT
                             ,buff   => ov_errmsg --�G���[���b�Z�[�W
                             );
            FND_FILE.PUT_LINE(
                              which  => FND_FILE.LOG
                             ,buff   => ov_errbuf --�G���[���b�Z�[�W
                             );
            ov_retcode := cv_status_warn;
            gn_new_warn_count := gn_new_warn_count + 1;
        END;
--
      EXCEPTION
        WHEN upm_work_exp THEN
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_errmsg --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --�G���[���b�Z�[�W
                           );

          ov_errmsg  := lv_errmsg;
          ov_errbuf  := lv_errbuf;
          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD START ******************************--
        WHEN get_tax_rule_exp THEN
          lv_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_tkn_customer_err
                                                , cv_tkn_key_data
                                                , gv_msg_tkn_cust_code || cv_msg_part ||
                                                  main_rec.ship_to_customer_code || cv_msg_comma ||
                                                  gv_msg_tkn_exp_line_id || cv_msg_part ||
                                                  main_rec.sales_exp_line_id
                                                );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => lv_errmsg --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errmsg --�G���[���b�Z�[�W
                           );

          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
--****************************** 2009/07/17 1.5  K.Shirasuna ADD END ********************************--
        WHEN OTHERS THEN
          lv_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
          IF (SQLCODE = cn_lock_error_code) THEN
            ov_errmsg := xxccp_common_pkg.get_msg(cv_application
                                                , cv_msg_lock
                                                , cv_tkn_lock
                                                , gv_tkn_lock_table
                                                 );
          ELSE
            ov_errmsg  := NULL;
          END IF;
--
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.LOG
                           ,buff   => lv_errbuf --�G���[���b�Z�[�W
                           );
          FND_FILE.PUT_LINE(
                            which  => FND_FILE.OUTPUT
                           ,buff   => ov_errmsg --�G���[���b�Z�[�W
                           );
          ov_retcode := cv_status_warn;
          gn_new_warn_count := gn_new_warn_count + 1;
      END;
--
    END LOOP main_loop;
--
    --�G���[�J�E���g
    gn_warn_tran_count     := gn_warn_tran_count + gn_new_warn_count;
--
    IF (gn_warn_tran_count > 0) THEN
      ROLLBACK;
      gn_warn_cnt := gn_warn_cnt + gn_tran_count;
      ov_errmsg := NULL;
      ov_errbuf := NULL;
/* 2009/08/25 Ver1.8 Add Start */
      --�x���ɂȂ����̔����уw�b�_ID�ҏW
      ln_skip_seq                    := ln_skip_seq + 1;
      gt_upd_header_tab(ln_skip_seq) := gv_bf_sales_exp_header_id;
/* 2009/08/25 Ver1.8 Add End   */
    ELSE
      COMMIT;
      gn_normal_cnt := gn_normal_cnt + gn_tran_count;
    END IF;
--
/* 2009/08/25 Ver1.8 Add Start */
    -- ==================================
    --A-7�D�̔����і��׃X�L�b�v�f�[�^�X�V
    -- ==================================
    proc_upd_skip_line(
       gt_upd_header_tab  --�X�V�Ώۃw�b�_ID�e�[�u���^
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ================================
    --A-8�D�̔����і��בΏۊO�f�[�^�X�V
    -- ================================
    proc_upd_n_target_line(
       lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
/* 2009/08/25 Ver1.8 Add End   */
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
  END proc_main_loop;
--

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    -- ===============================
    -- Loop1 ���C���@A-1�f�[�^���o
    -- ===============================
    open main_cur;
    proc_main_loop(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );

    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    ELSE
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- A-0�D��������
    -- ===============================================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================================
      -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
      -- ===============================================
      submain(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;

--
    -- ===============================================
    -- A-7�D�I������
    -- ===============================================
    --�G���[�o��
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
        );
      END IF;
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
-- 2009/02/24 T.Nakamura Ver.1.2 mod start
--    END IF;
--    --��s�}��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
/* 2009/08/25 Ver1.8 Mod Start */
    --����I���Ń��b�Z�[�W���o�͂����ꍇ
    ELSIF ( gv_empty_line_flag = cv_flag_on ) THEN
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
/* 2009/08/25 Ver1.8 Mod End   */
    END IF;
-- 2009/02/24 T.Nakamura Ver.1.2 mod end
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
    --�X�L�b�v�����o��
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
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
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
END XXCOS003A02C;
/
