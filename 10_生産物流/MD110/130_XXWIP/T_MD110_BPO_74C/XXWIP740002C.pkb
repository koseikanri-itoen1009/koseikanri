CREATE OR REPLACE PACKAGE BODY xxwip740002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP740004(body)
 * Description      : ������
 * MD.050/070       : ������(T_MD050_BPO_740)
 *                    ������(T_MD070_BPO_74C)
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  prc_chk_param               PROCEDURE : �p�����[�^�`�F�b�N (C-1)
 *  prc_get_data                PROCEDURE : �f�[�^�擾 (C-2)
 *  prc_create_xml_data         PROCEDURE : �w�l�k�f�[�^�ҏW (C-3)
 *  convert_into_xml            FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  submain                     PROCEDURE : ���C�������v���V�[�W��
 *  main                        PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/25    1.0   Yusuke Tabata   �V�K�쐬
 *  2008/07/02    1.1   Satoshi Yunba   �֑������Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ===============================================================================================
  -- ���[�U�[�錾��
  -- ===============================================================================================
  -- ==================================================
  -- �O���[�o���萔
  -- ==================================================
  gc_pkg_name             CONSTANT VARCHAR2(20) := 'xxwip740004C' ;         -- �p�b�P�[�W��
  gc_report_id            CONSTANT VARCHAR2(20) := 'xxwip740004T' ;         -- ���[ID
  gc_application          CONSTANT VARCHAR2(5)  := 'XXCMN' ;                -- �A�v���P�[�V����
  gc_application_wip      CONSTANT VARCHAR2(5)  := 'XXWIP' ;                -- �A�v���P�[�V����
  gc_err_code_no_data     CONSTANT VARCHAR2(15) := 'APP-XXCMN-10122' ;      -- �f�[�^�O�����b�Z�[�W
  gc_err_code_date_false  CONSTANT VARCHAR2(15) := 'APP-XXCMN-10012' ;      -- ���t�s���G���[���b�Z�[�W
  gc_err_code_future_date CONSTANT VARCHAR2(15) := 'APP-XXWIP-10020' ;      -- �������G���[
  gc_msg_item             CONSTANT VARCHAR2(4)  := 'ITEM' ;
  gc_msg_value            CONSTANT VARCHAR2(5)  := 'VALUE';
  gc_column_billing_date  CONSTANT VARCHAR2(8) := '�����N��';
--
  -- �N�����}�X�N
  gc_date_mask_s          CONSTANT VARCHAR2(7)  := 'YYYY/MM' ;
  gc_date_mask            CONSTANT VARCHAR2(10) := 'YYYY/MM/DD' ;
  -- �N����(JA)�}�X�N
  gc_date_mask_ja         CONSTANT VARCHAR2(30) := 'YYYY"�N"MM"��"DD"��"' ;
  -- �N����(JA)�}�X�N�󔒗L
  gc_date_mask_ja_l       CONSTANT VARCHAR2(40) := 'YYYY"  �N  "MM"  ��  "DD"  ��"';
  -- �o��
  gc_tag_type_t           CONSTANT VARCHAR2(1)  := 'T' ;
  gc_tag_type_d           CONSTANT VARCHAR2(1)  := 'D' ;
--
  -- ==================================================
  -- ���[�U�[��`�O���[�o���^
  -- ==================================================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD
    (
       billing_code   VARCHAR2(15)  -- 01 : ������
      ,billing_date   VARCHAR2(6)   -- 02 : �����N��
    ) ;
--
  -- ���o�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl IS RECORD
    (
       post_no                  xxwip_billing_mst.post_no%TYPE                  -- �X�֔ԍ�
      ,address                  xxwip_billing_mst.address%TYPE                  -- �Z��
      ,billing_name             xxwip_billing_mst.billing_name%TYPE             -- �����於
      ,billing_date             xxwip_billing_mst.billing_date%TYPE             -- �����N��
      ,last_month_charge_amount xxwip_billing_mst.last_month_charge_amount%TYPE -- �O�������z
      ,amount_receipt_money     xxwip_billing_mst.amount_receipt_money%TYPE     -- ����������z
      ,amount_adjustment        xxwip_billing_mst.amount_adjustment%TYPE        -- �����z
      ,balance_carried_forward  xxwip_billing_mst.balance_carried_forward%TYPE  -- �J�z�z
      ,charged_amount           xxwip_billing_mst.charged_amount%TYPE           -- ���񐿋����z
      ,charged_amount_total     xxwip_billing_mst.charged_amount_total%TYPE     -- �������z���v
      ,month_sales              xxwip_billing_mst.month_sales%TYPE              -- ��������z
      ,consumption_tax          xxwip_billing_mst.consumption_tax%TYPE          -- �����
      ,congestion_charge        xxwip_billing_mst.congestion_charge%TYPE        -- �ʍs����
      ,condition_setting_date   xxwip_billing_mst.condition_setting_date%TYPE   -- �x�������ݒ��
    ) ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gr_param              rec_param_data ;      -- �p�����[�^
  gr_dtl_data           rec_data_type_dtl ;   -- ���o�f�[�^
  gn_data_cnt           NUMBER DEFAULT 0 ;    -- �����f�[�^�J�E���^
--
  gt_xml_data_table     XML_DATA ;            -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx            NUMBER  := 0 ;        -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /************************************************************************************************
   * Procedure Name   : prc_chk_param
   * Description      : �p�����[�^�`�F�b�N(C-1)
   ************************************************************************************************/
  PROCEDURE prc_chk_param
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_chk_param' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    ln_cnt          NUMBER DEFAULT 0    ;
    ld_billing_date DATE   DEFAULT NULL ;
        -- *** ���[�J���E��O���� ***
    date_false_expt      EXCEPTION ;     -- ���t�s���G���[
    future_date_expt     EXCEPTION ;     -- �������`�F�b�N�G���[
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    ld_billing_date := FND_DATE.STRING_TO_DATE(gr_param.billing_date,gc_date_mask_s);
    -- ���t�Ó����`�F�b�N
    IF (ld_billing_date IS NULL) THEN
      RAISE date_false_expt;
    -- �������`�F�b�N
    ELSIF (LAST_DAY(SYSDATE) < ld_billing_date) THEN
      RAISE future_date_expt;
    END IF ;
--
  EXCEPTION
    WHEN date_false_expt THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_date_false
                                             ,gc_msg_item
                                             ,gc_column_billing_date
                                             ,gc_msg_value
                                             ,gr_param.billing_date) ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    WHEN future_date_expt THEN
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_wip
                                             ,gc_err_code_future_date
                                             ,gc_msg_item
                                             ,gc_column_billing_date
                                             ,gc_msg_value
                                             ,gr_param.billing_date) ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_chk_param ;
--
  /************************************************************************************************
   * Procedure Name   : prc_get_data(C-2)
   * Description      : �f�[�^�擾
   ************************************************************************************************/
  PROCEDURE prc_get_data
    (
      ov_errbuf             OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ==================================================
    -- �Œ胍�[�J���萔
    -- ==================================================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_data' ; -- �v���O������
--
--##### �Œ胍�[�J���ϐ��錾�� START #################################
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--##### �Œ胍�[�J���ϐ��錾�� END   #################################
--
    -- ==================================================
    -- �ϐ��錾
    -- ==================================================
    lr_get_data   rec_data_type_dtl;
    -- *** ���[�J���E��O���� ***
    dtldata_notfound_expt      EXCEPTION ;     -- �Ώۃf�[�^0����O
--
  BEGIN
--
--##### �Œ�X�e�[�^�X�������� START #################################
    ov_retcode := gv_status_normal;
--##### �Œ�X�e�[�^�X�������� END   #################################
--
    -- �f�[�^�擾�Ώۂ̑��݃`�F�b�N
    SELECT
    COUNT(xbm.billing_mst_id)
    INTO gn_data_cnt
    FROM
    xxwip_billing_mst xbm
    WHERE
        xbm.billing_code = gr_param.billing_code
    AND xbm.billing_date = gr_param.billing_date
    ;
--
    IF (gn_data_cnt <> 0) THEN
      SELECT
       xbm.post_no                  -- �X�֔ԍ�
      ,xbm.address                  -- �Z��
      ,xbm.billing_name             -- �����於
      ,xbm.billing_date             -- �����N��
      ,xbm.last_month_charge_amount -- �O�������z
      ,xbm.amount_receipt_money     -- ����������z
      ,xbm.amount_adjustment        -- �����z
      ,xbm.balance_carried_forward  -- �J�z�z
      ,xbm.charged_amount           -- ���񐿋����z
      ,xbm.charged_amount_total     -- �������z���v
      ,xbm.month_sales              -- ��������z
      ,xbm.consumption_tax          -- �����
      ,xbm.congestion_charge        -- �ʍs����
      ,xbm.condition_setting_date   -- �x�������ݒ��
      INTO
       gr_dtl_data.post_no                  -- �X�֔ԍ�
      ,gr_dtl_data.address                  -- �Z��
      ,gr_dtl_data.billing_name             -- �����於
      ,gr_dtl_data.billing_date             -- �����N��
      ,gr_dtl_data.last_month_charge_amount -- �O�������z
      ,gr_dtl_data.amount_receipt_money     -- ����������z
      ,gr_dtl_data.amount_adjustment        -- �����z
      ,gr_dtl_data.balance_carried_forward  -- �J�z�z
      ,gr_dtl_data.charged_amount           -- ���񐿋����z
      ,gr_dtl_data.charged_amount_total     -- �������z���v
      ,gr_dtl_data.month_sales              -- ��������z
      ,gr_dtl_data.consumption_tax          -- �����
      ,gr_dtl_data.congestion_charge        -- �ʍs����
      ,gr_dtl_data.condition_setting_date   -- �x�������ݒ��
      FROM
      xxwip_billing_mst xbm             --������A�h�I���}�X�^
      WHERE
          xbm.billing_code = gr_param.billing_code
      AND xbm.billing_date = gr_param.billing_date
      ;
    END IF;
--
  EXCEPTION
--
    -- *** �Ώۃf�[�^0����O�n���h�� ***
    WHEN dtldata_notfound_expt THEN
      ov_retcode := gv_status_warn ;
--##### �Œ��O������ START #######################################################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--##### �Œ��O������ END   #######################################################################
  END prc_get_data ;
--
   /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(C-3)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ov_errbuf         OUT NOCOPY VARCHAR2         -- �G���[�E���b�Z�[�W
     ,ov_retcode        OUT NOCOPY VARCHAR2         -- ���^�[���E�R�[�h
     ,ov_errmsg         OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_addrress_01     VARCHAR2(30) DEFAULT NULL ;
    lv_addrress_02     VARCHAR2(31) DEFAULT NULL ;
    lv_billing_name_01 VARCHAR2(30) DEFAULT NULL ;
    lv_billing_name_02 VARCHAR2(31) DEFAULT NULL ;
    ld_billing_date    DATE         DEFAULT NULL ;
--
  BEGIN
--
    -- ---------------------------------
    -- ��������
    -- ---------------------------------
    -- �Z����30Byte�ŕ���
    lv_addrress_01     := SUBSTRB(gr_dtl_data.address,1,30) ;
    lv_addrress_02     := SUBSTR(gr_dtl_data.address,LENGTH(lv_addrress_01)+1,60);
    -- �����於��30Byte�ŕ���
    lv_billing_name_01 := SUBSTRB(gr_dtl_data.billing_name,1,30) ;
    lv_billing_name_02 := SUBSTR(gr_dtl_data.billing_name,LENGTH(lv_billing_name_01)+1,60) ;
    -- ���������琿���J�n���֒u��
    ld_billing_date    := FND_DATE.STRING_TO_DATE(gr_param.billing_date,'YYYY/MM') ;
--
    -- ���s�N����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(SYSDATE,gc_date_mask_ja_l);
    -- ������X�֔ԍ�
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'post_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.post_no;
    -- ������Z���P
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'address_01';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_addrress_01;
    -- ������Z���Q
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'address_02';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_addrress_02;
    -- �����於�P
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_name_01';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_billing_name_01;
    -- �����於�Q
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_name_02';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_billing_name_02;
    -- ���ؔN����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(LAST_DAY(ld_billing_date),gc_date_mask_ja_l);
    -- �O�������c��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'last_month_charge_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.last_month_charge_amount;
    -- ��������z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_receipt_money';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.amount_receipt_money;
    -- �����z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'amount_adjustment';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.amount_adjustment;
    -- �J�z�z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'balance_carried_forward';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.balance_carried_forward;
    -- ���񐿋��z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charged_amount';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.charged_amount;
    -- ���v�����z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'charged_amount_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.charged_amount_total;
    -- �����N����FROM
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_date_from';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(ld_billing_date,gc_date_mask_ja);
    -- �����N����TO
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'billing_date_to';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(LAST_DAY(ld_billing_date),gc_date_mask_ja);
    -- ��������z
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'month_sales';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.month_sales;
    -- ����Ŋz
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'consumption_tax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.consumption_tax;
    -- �ʍs����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'congestion_charge';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gr_dtl_data.congestion_charge;
    -- �U���N����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'condition_setting_date';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value
      := TO_CHAR(gr_dtl_data.condition_setting_date,gc_date_mask_ja);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Function Name    : convert_into_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION convert_into_xml
    (
      iv_name              IN        VARCHAR2   --   �^�O�l�[��
     ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
     ,ic_type              IN        CHAR       --   �^�O�^�C�v
    ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'convert_into_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF ( ic_type = 'D' ) THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END convert_into_xml ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_billing_code        IN   VARCHAR2  -- 01 : ������R�[�h
     ,iv_billing_date        IN   VARCHAR2  -- 02 : �����N��
     ,ov_errbuf              OUT  VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT  VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT  VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    lv_xml_string           VARCHAR2(32000) ;
    lv_err_code             VARCHAR2(10) ;
    ln_retcode              VARCHAR2(1) ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- -----------------------------------------------------
    -- �p�����[�^�i�[
    -- -----------------------------------------------------
    gr_param.billing_code := iv_billing_code ;   -- 01 : ������R�[�h
    gr_param.billing_date := iv_billing_date ;   -- 02 : �����N��
--
    -- =====================================================
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_chk_param
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �f�[�^�擾
    -- =====================================================
    prc_get_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �w�l�k�t�@�C���f�[�^�ҏW
    -- =====================================================
    -- --------------------------------------------------
    -- ���X�g�O���[�v�J�n�^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- --------------------------------------------------
    -- �w�l�k�f�[�^�ҏW�������Ăяo���B
    -- --------------------------------------------------
    prc_create_xml_data
      (
        ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- --------------------------------------------------
    -- ���X�g�O���[�v�I���^�O
    -- --------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/data_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ==================================================
    -- ���[�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF ( gn_data_cnt = 0 ) THEN
--
      -- --------------------------------------------------
      -- �O�����b�Z�[�W�̎擾
      -- --------------------------------------------------
      ov_retcode := gv_status_warn ;
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,gc_err_code_no_data ) ;
--
      -- --------------------------------------------------
      -- ���b�Z�[�W�̐ݒ�
      -- --------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  <data_info>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '  </data_info>' ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- --------------------------------------------------
      -- �w�l�k�o��
      -- --------------------------------------------------
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := convert_into_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name  -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value  -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type  -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_xml_string) ;
      END LOOP xml_data_table ;
--
    END IF ;
--
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main
    (
      errbuf              OUT    VARCHAR2   -- �G���[���b�Z�[�W
     ,retcode             OUT    VARCHAR2   -- �G���[�R�[�h
     ,iv_billing_code     IN     VARCHAR2   -- 01 : ������R�[�h
     ,iv_billing_date     IN     VARCHAR2   -- 02 : �����N��
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'xxwip740002c.main' ;  -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain
      (
        iv_billing_code        -- 01 : ������R�[�h
       ,iv_billing_date        -- 02 : �����N��
       ,lv_errbuf             -- �G���[�E���b�Z�[�W
       ,lv_retcode             -- ���^�[���E�R�[�h
       ,lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gc_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
--
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwip740002c ;
/
