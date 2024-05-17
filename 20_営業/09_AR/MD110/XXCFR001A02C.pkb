CREATE OR REPLACE PACKAGE BODY XXCFR001A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR001A02C(body)
 * Description      : ������уf�[�^�A�g
 * MD.050           : MD050_CFR_001_A02_������уf�[�^�A�g
 * MD.070           : MD050_CFR_001_A02_������уf�[�^�A�g
 * Version          : 1.17
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p ��������                                (A-1)
 *  get_profile_value      p �v���t�@�C���擾����                    (A-2)
 *  get_process_date       p �Ɩ��������t�擾����                    (A-4)
 *  get_sales_data         p ������уf�[�^�擾                      (A-5)
 *  put_sales_data         p ������уf�[�^�b�r�u�쐬����            (A-6)
 *  insert_sales_data_reletes p ������јA�g�σe�[�u���o�^           (A-7)
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.00 SCS ���� ��      ����쐬
 *  2009/12/13    1.10 SCS �A�� �^���l  ��Q�Ή�[E_�{�ғ�_00366]
 *  2011/04/19    1.11 SCS ���� �T��    ��Q�Ή�[E_�{�ғ�_04976]
 *  2011/05/26    1.12 SCS �Γn ���a    �o�s�Ή�[E_�{�ғ�_07413]
 *  2018/04/03    1.13 SCSK���X�؍G�V   �ʂ̉c�ƈ��R�[�h�\��[E_�{�ғ�_14952]
 *  2019/09/11    1.14 SCSK�K�q �x��    ��Q�Ή�[E_�{�ғ�_15472]
 *  2019/10/07    1.15 SCSK���X�؍G�V   ��Q�Ή�[E_�{�ғ�_15472]��Q�Ή�
 *  2021/06/04    1.16 SCSK Y.Koh       [E_�{�ғ�_16026]
 *  2024/05/17    1.17 SCSK R.Oikawa    [E_�{�ғ�_19997]�Ή�
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR001A02C'; -- �p�b�P�[�W��
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- �A�v���P�[�V�����Z�k��(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- �A�v���P�[�V�����Z�k��(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- �A�v���P�[�V�����Z�k��(XXCFR)
--
  -- ���b�Z�[�W�ԍ�
--
  cv_msg_001a02_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --�v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_001a02_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00029'; --�t�@�C�����o�̓��b�Z�[�W
  cv_msg_001a02_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; --�Ώۃf�[�^��0�����b�Z�[�W
  cv_msg_001a02_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --�Ɩ��������t�擾�G���[���b�Z�[�W
  cv_msg_001a02_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00047'; --�t�@�C���̏ꏊ���������b�Z�[�W
  cv_msg_001a02_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00048'; --�t�@�C�����I�[�v���ł��Ȃ����b�Z�[�W
  cv_msg_001a02_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00049'; --�t�@�C���ɏ����݂ł��Ȃ����b�Z�[
  cv_msg_001a02_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00050'; --�t�@�C�������݂��Ă��郁�b�Z�[�W
  cv_msg_001a02_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00058'; --���i�R�[�h���ݒ胁�b�Z�[�W
--
-- �g�[�N��
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- �v���t�@�C����
  cv_tkn_file        CONSTANT VARCHAR2(15) := 'FILE_NAME';        -- �t�@�C����
  cv_tkn_trx_type    CONSTANT VARCHAR2(15) := 'TRX_TYPE';         -- ����^�C�v
--
  --�v���t�@�C��
  cv_org_id               CONSTANT VARCHAR2(30) := 'ORG_ID';           -- �g�DID
  cv_set_of_bks_id        CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- ��v����ID
  cv_sales_data_filename  CONSTANT VARCHAR2(35) := 'XXCFR1_SALES_DATA_FILENAME';
                                                                       -- XXCFR:������уf�[�^�t�@�C����
  cv_sales_data_filepath  CONSTANT VARCHAR2(35) := 'XXCFR1_SALES_DATA_FILEPATH';
                                                                       -- XXCFR:������уf�[�^�t�@�C���i�[�p�X
  cv_sd_sold_return_type  CONSTANT VARCHAR2(35) := 'XXCFR1_SD_SOLD_RETURN_TYPE';
                                                                       -- XXCFR:������уf�[�^����ԕi�敪
  cv_sd_sales_class       CONSTANT VARCHAR2(35) := 'XXCFR1_SD_SALES_CLASS';
                                                                       -- XXCFR:������уf�[�^����敪
  cv_sd_delivery_ptn_class CONSTANT VARCHAR2(35) := 'XXCFR1_SD_DELIVERY_PTN_CLASS';
                                                                       -- XXCFR:������уf�[�^�[�i�`�ԋ敪
--
--  2018/04/03 V1.13 Added START
  --  �Q�ƃ^�C�v
  cv_xxcfr1_disp_salesrep CONSTANT VARCHAR2(30) :=  'XXCFR1_DISP_SALESREP';   --  �Q�ƃ^�C�v�F�c�ƈ��\���ΏۃR�[�h�i������јA�g�j
  --
  cv_group_name_resource  CONSTANT VARCHAR2(8)  :=  'RESOURCE';               --  �O���[�v�^�C�v���FRESOURCE
--  2018/04/03 V1.13 Added END
--
--  2019/09/11 V1.14 Added START
  cv_discnt_item          CONSTANT VARCHAR2(30) :=  'XXCFR1_SALES_DISCOUNT_ITEM';   --�Q�ƃ^�C�v�F����l���i�ڑΏۃR�[�h�i������јA�g�j
  cv_receipt_discnt_item  CONSTANT VARCHAR2(30) :=  'XXCFR1_RECEIPT_DISCOUNT_ITEM'; --�Q�ƃ^�C�v�F�����l���i�ڑΏۃR�[�h�i������јA�g�j
--  2019/09/11 V1.14 Added END
--
  -- �t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ���O�o��
--
  cv_flag_yes        CONSTANT VARCHAR2(1)  := 'Y';         -- �t���O�i�x�j
  cv_flag_no         CONSTANT VARCHAR2(1)  := 'N';         -- �t���O�i�m�j
--
  cv_line_type_l     CONSTANT VARCHAR2(4)  := 'LINE';     -- ���׃^�C�v(=LINE)
  cn_period_months   CONSTANT NUMBER       := 12;         -- ���o�Ώۊ��ԁi���j
--
  cv_format_date_ymd  CONSTANT VARCHAR2(8)    := 'YYYYMMDD';         -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_date_ymdhns CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';  -- ���t�t�H�[�}�b�g�i�N���������b�j
--
  cv_object_code        CONSTANT VARCHAR2(10) := '0000000000'; -- �����R�[�h
  cv_hc_code            CONSTANT VARCHAR2(1)  := '1';          -- �g���b�i�R�[���h�j
  cv_score_member_code  CONSTANT VARCHAR2(5)  := '00000';      -- ���ю҃R�[�h
  cv_sales_card_type    CONSTANT VARCHAR2(1)  := '0';          -- �J�[�h����敪�i�����j
  cv_delivery_base_code CONSTANT VARCHAR2(4)  := '0000';       -- �[�i���_�R�[�h
  cv_unit_sales         CONSTANT VARCHAR2(1)  := '0';          -- ���㐔��
  cv_column_no          CONSTANT VARCHAR2(2)  := '00';         -- �R����No
-- Add 2011.04.19 Ver.1.11 Start
  cn_zero               CONSTANT NUMBER       := 0;            -- ��P���i�ō��j,������z�i�ō��j�o�͌Œ�l
-- Add 2011.04.19 Ver.1.11 End
-- Ver1.17 ADD Start
  cv_comp_code         CONSTANT VARCHAR2(3)  := '001';          -- ��ЃR�[�h
-- Ver1.17 ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_org_id                   NUMBER;            -- �g�DID
  gn_set_of_bks_id            NUMBER;            -- ��v����ID
  gv_sales_data_filename      VARCHAR2(100);     -- ������уf�[�^�t�@�C����
  gv_sales_data_filepath      VARCHAR2(500);     -- ������уf�[�^�t�@�C���i�[�p�X
  gv_sd_sold_return_type      VARCHAR2(10);      -- ������уf�[�^����ԕi�敪
  gv_sd_sales_class           VARCHAR2(10);      -- ������уf�[�^����敪
  gv_sd_delivery_ptn_class    VARCHAR2(10);      -- ������уf�[�^�[�i�`�ԋ敪
  gv_period_name              gl_period_statuses.period_name%TYPE;  -- ��v���Ԗ�
  gv_start_date_yymm          VARCHAR2(6);       -- ��v���ԔN��
  gd_process_date             DATE;              -- �Ɩ��������t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
    -- ���o
    CURSOR get_sales_data_cur
    IS
-- Mod 2011.05.26 Ver.1.12 Start
--      SELECT rcta.trx_number              trx_number,               -- �[�i�`�[No�iAR����ԍ��j
      SELECT /*+
                 LEADING(rcta) 
                 USE_NL( rcta rctta rctla rctlgda gcc hca_s hca_b avtab )
             */
             rcta.trx_number              trx_number,               -- �[�i�`�[No�iAR����ԍ��j
-- Mod 2011.05.26 Ver.1.12 End
             rcta.trx_date                trx_date,                 -- �[�i���i������j�i������j
             rcta.customer_trx_id         customer_trx_id,          -- ���ID
             rctla.line_number            line_number,              -- �[�i�`�[�sNo�iAR������הԍ��j
             rctla.customer_trx_line_id   customer_trx_line_id,     -- �������ID
             rctla.revenue_amount         rec_amount,               -- ������z
-- 2021/06/04 Ver1.16 MOD Start
             ( select NVL(SUM(rctla_t.extended_amount),0) FROM ra_customer_trx_lines_all rctla_t WHERE rctla_t.link_to_cust_trx_line_id = rctla.customer_trx_line_id )
                                          tax_amount,               -- �ŋ����z
--             rctla_t.extended_amount      tax_amount,               -- �ŋ����z
-- 2021/06/04 Ver1.16 MOD End
             avtab.tax_code               tax_code,                 -- AR�ŋ敪�iAR�ŋ��}�X�^�j
             gcc.segment1                 comp_code,                -- ��ЃR�[�h(AFF1)
             gcc.segment2                 dept_code,                -- ���㋒�_�R�[�h(AFF2)
-- 2021/06/04 Ver1.16 ADD Start
             xca.sale_base_code           sale_base_code,           -- ���㋒�_�R�[�h
             xca.past_sale_base_code      past_sale_base_code,      -- �O�����㋒�_�R�[�h
             gcc.segment3                 account_code,             -- ����ȖڃR�[�h(AFF3)
-- 2021/06/04 Ver1.16 ADD End
             hca_s.account_number         ship_to_account_number,   -- �ڋq�R�[�h�i�o�א�ڋq�R�[�h�j
             hca_b.account_number         bill_to_account_number,   -- ������ڋq�R�[�h�i������ڋq�R�[�h�j
             rctta.attribute3             item_code,                -- ���i�R�[�h
             rctlgda.gl_date              gl_date,                  -- GL�L����
             rctta.name                   trx_type_name             -- ����^�C�v��
--  2019/09/11 V1.14 Added START
            ,avtab.tax_rate               tax_rate                  -- �ŗ�
--  2019/09/11 V1.14 Added END
      FROM ra_customer_trx_all            rcta,       -- ����w�b�_
           ra_cust_trx_types_all          rctta,      -- ����^�C�v
           ra_customer_trx_lines_all      rctla,      -- ������ׁi�{�́j
-- 2021/06/04 Ver1.16 DEL Start
--           ra_customer_trx_lines_all      rctla_t,    -- ������ׁi�Ŋz�j
-- 2021/06/04 Ver1.16 DEL End
           ra_cust_trx_line_gl_dist_all   rctlgda,    -- ����z��
           gl_code_combinations           gcc,        -- ����Ȗڑg�����}�X�^
           hz_cust_accounts               hca_s,      -- �ڋq�}�X�^�i�o�א�j
           hz_cust_accounts               hca_b,      -- �ڋq�}�X�^�i������j
-- 2021/06/04 Ver1.16 ADD Start
           xxcmm_cust_accounts            xca,        -- �ڋq�ǉ����
-- 2021/06/04 Ver1.16 ADD End
           ar_vat_tax_all_b               avtab       -- AR�ŋ��}�X�^
      WHERE rcta.cust_trx_type_id         = rctta.cust_trx_type_id
        AND rctta.attribute2              = cv_flag_yes       -- ���n�A�g�t���O�i��Y)
        AND NOT EXISTS ( 
-- Mod 2011.05.26 Ver.1.12 Start
--            SELECT ROWNUM
            SELECT /*+ USE_NL(xsdr) */
                   1
-- Mod 2011.05.26 Ver.1.12 End
            FROM xxcfr_sales_data_reletes   xsdr
            WHERE xsdr.customer_trx_id = rcta.customer_trx_id
            )
        AND rcta.trx_date                 >= ADD_MONTHS ( gd_process_date, -1 * cn_period_months )
        AND rcta.set_of_books_id          = gn_set_of_bks_id
        AND rcta.org_id                   = gn_org_id
        AND rcta.customer_trx_id          = rctla.customer_trx_id
        AND rctla.line_type               = cv_line_type_l    -- ����
-- 2021/06/04 Ver1.16 DEL Start
--        AND rctla.customer_trx_line_id    = rctla_t.link_to_cust_trx_line_id(+)
-- 2021/06/04 Ver1.16 DEL End
        AND rctla.customer_trx_line_id    = rctlgda.customer_trx_line_id
        AND rctlgda.code_combination_id   = gcc.code_combination_id 
        AND rcta.bill_to_customer_id      = hca_b.cust_account_id
        AND rcta.ship_to_customer_id      = hca_s.cust_account_id(+)
-- 2021/06/04 Ver1.16 ADD Start
        AND xca.customer_code(+)          = hca_s.account_number
-- 2021/06/04 Ver1.16 ADD End
        AND rctla.vat_tax_id              = avtab.vat_tax_id(+)
      ORDER BY
        rcta.trx_number,                  -- �[�i�`�[No
        rctla.line_number                 -- �[�i�`�[�sNo�iAR������הԍ��j
    ;
--
    TYPE g_sales_data_ttype IS TABLE OF get_sales_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gt_sales_data           g_sales_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --==============================================================
    --�R���J�����g�p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- ���b�Z�[�W�o��
      ,ov_errbuf       => ov_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => ov_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => ov_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ���O�o��
      ,ov_errbuf       => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- �v���O������
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
    -- �v���t�@�C������g�DID�擾
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- �擾�G���[��
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- �g�DID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C�������v����ID�擾
    gn_set_of_bks_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
    -- �擾�G���[��
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                       -- ��v����ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:������уf�[�^�t�@�C�����擾
    gv_sales_data_filename := FND_PROFILE.VALUE(cv_sales_data_filename);
    -- �擾�G���[��
    IF (gv_sales_data_filename IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sales_data_filename))
                                                       -- XXCFR:������уf�[�^�t�@�C����
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR: ������уf�[�^�t�@�C���i�[�p�X�擾
    gv_sales_data_filepath := FND_PROFILE.VALUE(cv_sales_data_filepath);
    -- �擾�G���[��
    IF (gv_sales_data_filepath IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sales_data_filepath))
                                                       -- XXCFR:������уf�[�^�t�@�C���i�[�p�X
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:������уf�[�^����ԕi�敪�擾
    gv_sd_sold_return_type := FND_PROFILE.VALUE(cv_sd_sold_return_type);
    -- �擾�G���[��
    IF (gv_sd_sold_return_type IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sd_sold_return_type))
                                                       -- XXCFR:������уf�[�^����ԕi�敪
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:������уf�[�^����敪�擾
    gv_sd_sales_class := FND_PROFILE.VALUE(cv_sd_sales_class);
    -- �擾�G���[��
    IF (gv_sd_sales_class IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sd_sales_class))
                                                       -- XXCFR:������уf�[�^����敪
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C������XXCFR:������уf�[�^�[�i�`�ԋ敪�擾
    gv_sd_delivery_ptn_class := FND_PROFILE.VALUE(cv_sd_delivery_ptn_class);
    -- �擾�G���[��
    IF (gv_sd_delivery_ptn_class IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_010 -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof       -- �g�[�N��'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_sd_delivery_ptn_class))
                                                       -- XXCFR:������уf�[�^�[�i�`�ԋ敪
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
  END get_profile_value;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : �Ɩ��������t�擾���� (A-4)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ��������t�擾����
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- �擾�G���[��
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_013 -- �Ɩ��������t�擾�G���[
                                                    )
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
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_data
   * Description      : ������уf�[�^�擾 (A-5)
   ***********************************************************************************/
  PROCEDURE get_sales_data(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_data'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�[�\���I�[�v��
    OPEN get_sales_data_cur;
--
    -- �f�[�^�̈ꊇ�擾
    FETCH get_sales_data_cur BULK COLLECT INTO gt_sales_data;
--
    -- ���������̃Z�b�g
    gn_target_cnt := gt_sales_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_sales_data_cur;
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
  END get_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : put_sales_data
   * Description      : ������уf�[�^�b�r�u�쐬���� (A-6)
   ***********************************************************************************/
  PROCEDURE put_sales_data(
    ov_errbuf               OUT  VARCHAR2,            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT  VARCHAR2,            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT  VARCHAR2)            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_sales_data'; -- �v���O������
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
    cv_open_mode_w    CONSTANT VARCHAR2(10) := 'w';     -- �t�@�C���I�[�v�����[�h�i�㏑���j
    cv_delimiter      CONSTANT VARCHAR2(1)  := ',';     -- CSV��؂蕶��
    cv_enclosed       CONSTANT VARCHAR2(2)  := '"';     -- �P��͂ݕ���
--
    -- *** ���[�J���ϐ� ***
    ln_target_cnt   NUMBER := 0;    -- �Ώی���
    ln_loop_cnt     NUMBER;         -- ���[�v�J�E���^
    ln_trx_cnt      NUMBER;         -- ����^�C�v���[�v�J�E���^
    -- 
    -- �t�@�C���o�͊֘A
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- �t�@�C���E�n���h���̐錾
    lv_csv_text         VARCHAR2(32000) ;       -- 
    lb_fexists          BOOLEAN;                -- �t�@�C�������݂��邩�ǂ���
    ln_file_size        NUMBER;                 -- �t�@�C���̒���
    ln_block_size       NUMBER;                 -- �t�@�C���V�X�e���̃u���b�N�T�C�Y
--
    lv_sales_type       VARCHAR2(2);            -- ����敪
--  2018/04/03 V1.13 Added START
    lt_salesrep_code    hz_org_profiles_ext_b.c_ext_attr1%TYPE;     --  �S���c�ƈ�
    ln_dummy            NUMBER;                                     --  ���݃`�F�b�N�p�_�~�[�ϐ�
--  2018/04/03 V1.13 Added END
--  2019/09/11 V1.14 Added START
    ln_dummy2           fnd_lookup_values.lookup_type%TYPE;         --  ���݃`�F�b�N�p�_�~�[�ϐ�
--  2019/09/11 V1.14 Added END
--
    -- *** ���[�J���E�J�[�\�� ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �t�s�k�t�@�C�����݃`�F�b�N
    -- ====================================================
    UTL_FILE.FGETATTR(gv_sales_data_filepath,
                      gv_sales_data_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- �O��t�@�C�������݂��Ă���
    IF lb_fexists THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_017 -- �t�@�C�������݂��Ă���
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ====================================================
    -- �t�s�k�t�@�C���I�[�v��
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gv_sales_data_filepath
                       ,gv_sales_data_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ====================================================
    -- �o�̓f�[�^���o
    -- ====================================================
    IF ( gn_target_cnt > 0 ) THEN
      <<out_loop>>
      FOR ln_loop_cnt IN gt_sales_data.FIRST..gt_sales_data.LAST LOOP
--  2018/04/03 V1.13 Added START
        BEGIN
          --  �S���c�ƈ��擾�F�Ώ۔���
          SELECT  1
          INTO    ln_dummy
          FROM    fnd_lookup_values   flv
          WHERE   flv.lookup_type     =   cv_xxcfr1_disp_salesrep
          AND     flv.language        =   USERENV( 'LANG' )
          AND     flv.enabled_flag    =   cv_flag_yes
          AND     gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                                  AND     NVL( flv.end_date_active, gd_process_date )
          AND     flv.lookup_code     =   gt_sales_data(ln_loop_cnt).item_code
          ;
          --  �S���c�ƈ��擾
          SELECT  hopeb.c_ext_attr1   AS  sales_rep_code
          INTO    lt_salesrep_code
          FROM    hz_parties                  hp        --  �p�[�e�B
                , hz_cust_accounts            hca       --  �ڋq�}�X�^
                , hz_organization_profiles    hop       --  �g�D�v���t�@�C��
                , hz_org_profiles_ext_b       hopeb     --  �g�D�v���t�@�C���g��
                , ego_attr_groups_v           eagv      --  �g�D�v���t�@�C���g�������O���[�v
          WHERE   hca.party_id                  =   hp.party_id
          AND     hp.party_id                   =   hop.party_id
          AND     hop.effective_end_date IS NULL
          AND     hop.organization_profile_id   =   hopeb.organization_profile_id
          AND     hopeb.attr_group_id           =   eagv.attr_group_id
          AND     eagv.attr_group_name          =   cv_group_name_resource
          AND     ( hopeb.d_ext_attr1 <= gd_process_date OR hopeb.d_ext_attr1 IS NULL )
          AND     ( hopeb.d_ext_attr2 >= gd_process_date OR hopeb.d_ext_attr2 IS NULL )
          AND     hca.account_number            =   gt_sales_data(ln_loop_cnt).ship_to_account_number
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --  �Q�ƕ\���擾�ł��Ȃ��A�S���c�ƈ����擾�ł��Ȃ��ꍇ�A�Œ�l��ݒ�
            lt_salesrep_code  :=  cv_score_member_code;
          WHEN TOO_MANY_ROWS THEN
            --  �S���c�ƈ��������擾�����ꍇ�A�Œ�l���擾
            lt_salesrep_code  :=  cv_score_member_code;
        END;
--  2018/04/03 V1.13 Added END
--
--  2019/09/11 V1.14 Added START
        BEGIN
--  V1.15 Added START
          --  �Ώ۔���ϐ�������
          ln_dummy2 :=  NULL;
--  V1.15 Added END
          --  �l���i�ڐU�ցF�Ώ۔���
          SELECT flv.lookup_type  lookup_type
          INTO   ln_dummy2
          FROM   fnd_lookup_values  flv
          WHERE  flv.lookup_type    IN ( cv_discnt_item,cv_receipt_discnt_item )
          AND    flv.language        =   USERENV( 'LANG' )
          AND    flv.enabled_flag    =   cv_flag_yes
          AND    gd_process_date BETWEEN NVL( flv.start_date_active, gd_process_date )
                                 AND     NVL( flv.end_date_active, gd_process_date )
          AND    flv.lookup_code     =   gt_sales_data(ln_loop_cnt).item_code
          ;
        --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --  �Q�ƕ\�ɕi�ڂ��Ȃ�(�l���i�ڂłȂ�)�ꍇ
            NULL;
        END;
        --
        -- �l���i�ڂł���ꍇ
        IF ( ln_dummy2 IS NOT NULL ) THEN
          BEGIN
            -- �l���i�ڐU��
            SELECT flv.lookup_code   item_code
            INTO   gt_sales_data(ln_loop_cnt).item_code
            FROM   xxcos_reduced_tax_rate_v  xrtr
                  ,fnd_lookup_values         flv
            WHERE  xrtr.item_code      = flv.lookup_code
            AND    flv.lookup_type     = ln_dummy2
            AND    flv.language        = USERENV( 'LANG' )
            AND    flv.enabled_flag    = cv_flag_yes
            AND    gd_process_date  BETWEEN  NVL( flv.start_date_active, gd_process_date )
                                    AND      NVL( flv.end_date_active, gd_process_date )
            AND    gt_sales_data(ln_loop_cnt).trx_date  BETWEEN  NVL( xrtr.start_date,gt_sales_data(ln_loop_cnt).trx_date )
                                                        AND      NVL( xrtr.end_date,gt_sales_data(ln_loop_cnt).trx_date )
            AND    gt_sales_data(ln_loop_cnt).trx_date  BETWEEN  NVL( xrtr.start_date_histories,gt_sales_data(ln_loop_cnt).trx_date )
                                                        AND      NVL( xrtr.end_date_histories,gt_sales_data(ln_loop_cnt).trx_date )
            AND    xrtr.tax_rate       = gt_sales_data(ln_loop_cnt).tax_rate
            ;
          --
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                -- ��ېł̏ꍇ
                NULL;
              WHEN TOO_MANY_ROWS THEN
                -- �y���ŗ��K�p�O�̏ꍇ
                NULL;
          END;
        END IF;
--  2019/09/11 V1.14 Added END
--
-- 2021/06/04 Ver1.16 ADD Start
        IF  ln_dummy2 = cv_receipt_discnt_item  THEN
          -- ������p�̊m�F
          SELECT  COUNT(*)
          INTO    ln_dummy
          FROM    fnd_lookup_values flv
          WHERE   flv.lookup_type  = 'XXCOK1_DEDUCTION_DATA_TYPE'
          AND     flv.language     = 'JA'
          AND     flv.enabled_flag = 'Y'
          AND     flv.attribute10  = 'Y'
          AND     flv.attribute6   = gt_sales_data(ln_loop_cnt).account_code;
--
          IF  ln_dummy  >=1 THEN
            IF  TRUNC(gt_sales_data(ln_loop_cnt).trx_date,'MM')  = TRUNC(gd_process_date,'MM')  THEN
              gt_sales_data(ln_loop_cnt).dept_code  :=  gt_sales_data(ln_loop_cnt).sale_base_code;
            ELSE
              gt_sales_data(ln_loop_cnt).dept_code  :=  gt_sales_data(ln_loop_cnt).past_sale_base_code;
            END IF;
          END IF;
        END IF;
-- 2021/06/04 Ver1.16 ADD End
--
        -- �o�͕�����쐬
-- Ver1.17 MOD Start
--        lv_csv_text := cv_enclosed || gt_sales_data(ln_loop_cnt).comp_code || cv_enclosed || cv_delimiter
        lv_csv_text := cv_enclosed || cv_comp_code || cv_enclosed || cv_delimiter
-- Ver1.17 MOD End
-- Modify 2009.12.13 Ver.1.10 Start
--                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).trx_date, cv_format_date_ymd ) || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).gl_date, cv_format_date_ymd ) || cv_delimiter  -- �[�i��(GL�L����)
-- Modify 2009.12.13 Ver.1.10 End
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).trx_number || cv_enclosed || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).line_number ) || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).ship_to_account_number || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).item_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_object_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_hc_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).dept_code || cv_enclosed || cv_delimiter
--  2018/04/03 V1.13 Modified START
--                    || cv_enclosed || cv_score_member_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || lt_salesrep_code || cv_enclosed || cv_delimiter
--  2018/04/03 V1.13 Modified END
                    || cv_enclosed || cv_sales_card_type || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_delivery_base_code || cv_enclosed || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).rec_amount ) || cv_delimiter
                    || cv_unit_sales || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).tax_amount ) || cv_delimiter
                    || cv_enclosed || gv_sd_sold_return_type || cv_enclosed || cv_delimiter
                    || cv_enclosed || gv_sd_sales_class || cv_enclosed || cv_delimiter
                    || cv_enclosed || gv_sd_delivery_ptn_class || cv_enclosed || cv_delimiter
                    || cv_enclosed || cv_column_no || cv_enclosed || cv_delimiter
-- Modify 2009.12.13 Ver.1.10 Start
--                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).gl_date, cv_format_date_ymd ) || cv_delimiter
                    || TO_CHAR ( gt_sales_data(ln_loop_cnt).trx_date, cv_format_date_ymd ) || cv_delimiter  -- �����\���(�����)
-- Modify 2009.12.13 Ver.1.10 End
                    || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).tax_code || cv_enclosed || cv_delimiter
                    || cv_enclosed || gt_sales_data(ln_loop_cnt).bill_to_account_number || cv_enclosed || cv_delimiter
-- Add 2011.04.19 Ver.1.11 Start
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- �����`�[�ԍ�
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- �`�[�敪
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- �`�[���ރR�[�h
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- ��K�؂ꎞ��100�~
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- ��K�؂ꎞ��10�~
                    || cn_zero                    || cv_delimiter     -- ��P���i�ō��j
                    || cn_zero                    || cv_delimiter     -- ������z�i�ō��j
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- ���؋敪
                    || cv_enclosed || cv_enclosed || cv_delimiter     -- ���؎���
-- Add 2011.04.19 Ver.1.11 End
                    || TO_CHAR ( cd_last_update_date, cv_format_date_ymdhns)
        ;
--
        -- ====================================================
        -- �t�@�C����������
        -- ====================================================
        UTL_FILE.PUT_LINE( lf_file_hand, lv_csv_text ) ;
--
        -- ���i�R�[�h�����ݒ�̏ꍇ�A���b�Z�[�W�o��
        IF gt_sales_data(ln_loop_cnt).item_code IS NULL THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_001a02_018 -- ���i�R�[�h���ݒ胁�b�Z�[�W
                                                        ,cv_tkn_trx_type   -- TRX_TYPE
                                                        ,gt_sales_data(ln_loop_cnt).trx_type_name -- ����^�C�v��
                                                       )
                                                       ,1
                                                       ,5000);
          -- ���b�Z�[�W�o��
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- ====================================================
        -- ���������J�E���g�A�b�v
        -- ====================================================
        ln_target_cnt := ln_target_cnt + 1 ;
--
      END LOOP out_loop;
--
    END IF;
--
    -- ====================================================
    -- �t�s�k�t�@�C���N���[�Y
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_normal_cnt := ln_target_cnt;
--
    -- �Ώۃf�[�^���O�����b�Z�[�W
    IF gn_target_cnt = 0 THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_012 -- �Ώۃf�[�^��0��
                                                   )
                                                   ,1
                                                   ,5000);
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** �t�@�C���̏ꏊ�������ł� ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_014 -- �t�@�C���̏ꏊ������
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���ǂ���Ƀt�@�C�����I�[�v���ł��Ȃ����A�܂��͑���ł��܂��� ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_015 -- �t�@�C�����I�[�v���ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** �����ݑ��쒆�ɃI�y���[�e�B���O�E�V�X�e���̃G���[���������܂��� ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      gn_normal_cnt := ln_target_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_001a02_016 -- �t�@�C���ɏ����݂ł��Ȃ�
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      --���t�@�C���N���[�Y�֐���ǉ�
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) then
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_sales_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_sales_data_reletes
   * Description      : ������јA�g�σe�[�u���o�^ (A-7)
   ***********************************************************************************/
  PROCEDURE insert_sales_data_reletes(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_sales_data_reletes'; -- �v���O������
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
    ln_loop_cnt     NUMBER;           -- ���[�v�J�E���^
    ln_target_cnt   NUMBER := 0;      -- �Ώی���
    ln_customer_trx_id    ra_customer_trx_all.customer_trx_id%TYPE := 0;   -- ���ID
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
    -- =====================================================
    --  ������јA�g�σe�[�u���o�^ (A-7)
    -- =====================================================
    IF ( gn_target_cnt > 0 ) THEN
      <<insert_data_loop>>
      FOR ln_loop_cnt IN gt_sales_data.FIRST..gt_sales_data.LAST LOOP
--
        -- ====================================================
        -- ������јA�g�σe�[�u���o�^
        -- ====================================================
        IF ( ln_customer_trx_id <> gt_sales_data(ln_loop_cnt).customer_trx_id ) THEN
          INSERT INTO xxcfr_sales_data_reletes ( 
             customer_trx_id
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login 
            ,request_id
            ,program_application_id
            ,program_id
            ,program_update_date
          )
          VALUES ( 
             gt_sales_data(ln_loop_cnt).customer_trx_id
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
--
          -- ====================================================
          -- ���������J�E���g�A�b�v
          -- ====================================================
          ln_target_cnt := ln_target_cnt + 1;
--
        END IF;
--
        -- ====================================================
        -- �ϐ��F���ID�ւ̊i�[
        -- ====================================================
        ln_customer_trx_id := gt_sales_data(ln_loop_cnt).customer_trx_id;
--
      END LOOP insert_data_loop;
    END IF;
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
  END insert_sales_data_reletes;
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
    lv_retcode_out VARCHAR2(1);     -- ���^�[���E�R�[�h�i������уf�[�^�b�r�u�쐬�����j
    lv_errmsg_out  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W�i������уf�[�^�b�r�u�쐬�����j
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
    -- =====================================================
    --  ��������(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  �v���t�@�C���擾����(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ������уf�[�^�t�@�C����񃍃O����(A-3)
    -- =====================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                  ,cv_msg_001a02_011 -- �t�@�C�����o�̓��b�Z�[�W
                                                  ,cv_tkn_file       -- �g�[�N��'FILE_NAME'
                                                  ,gv_sales_data_filename)      -- �t�@�C����
                                                ,1
                                                ,5000);
    FND_FILE.PUT_LINE(
       FND_FILE.OUTPUT
      ,lv_errmsg
    );
--
    --�P�s���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
--
    -- =====================================================
    --  �Ɩ��������t�擾���� (A-4)
    -- =====================================================
    get_process_date(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ������уf�[�^�擾 (A-5)
    -- =====================================================
    get_sales_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ������уf�[�^�b�r�u�쐬���� (A-6)
    -- =====================================================
    put_sales_data(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    -- �߂�l�̊i�[
    lv_retcode_out := lv_retcode;
    lv_errmsg_out := lv_errmsg;
--
    -- =====================================================
    --  ������јA�g�σe�[�u���o�^ (A-7)
    -- =====================================================
    insert_sales_data_reletes(
       lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
--
    -- �߂�l�̕���
    ov_retcode := lv_retcode_out;
    ov_errmsg  := lv_errmsg_out;
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
    errbuf        OUT     VARCHAR2,         --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT     VARCHAR2          --    �G���[�R�[�h     #�Œ�#
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    lv_errbuf       VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode      VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg       VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code VARCHAR2(100);   --���b�Z�[�W�R�[�h
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�������A�e�����͈ȉ��ɓ��ꂵ�ďo�͂���
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  �Œ蕔 START   #####################################################
--
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�G���[���b�Z�[�W���ݒ肳��Ă���ꍇ�A�G���[�o��
    IF (lv_errmsg IS NOT NULL) THEN
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
    END IF;
    --�G���[�̏ꍇ�A�V�X�e���G���[���b�Z�[�W�o��
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�o�b�t�@�̃��b�Z�[�W�A��
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    --�P�s���s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
-- Add End   2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
-- Add Start 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
    --�P�s���s
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --���[�U�[�E�G���[���b�Z�[�W
    );
-- Add End 2008/11/18 SCS H.Nakamura �e���v���[�g���C��
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
    fnd_file.put_line(
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
END XXCFR001A02C;
/
