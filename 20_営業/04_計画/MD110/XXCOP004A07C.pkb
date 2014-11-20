CREATE OR REPLACE PACKAGE BODY XXCOP004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A07C(body)
 * Description      : �e�R�[�h�o�׎��э쐬
 * MD.050           : �e�R�[�h�o�׎��э쐬 MD050_COP_004_A07
 * Version          : 1.4
 *
 * Program List
 * ----------------------   ----------------------------------------------------------
 *  Name                     Description
 * ----------------------   ----------------------------------------------------------
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  init                     ��������(A-1)
 *  del_shipment_results     �e�R�[�h�o�׎��щߋ��f�[�^�폜(A-2)
 *  renew_shipment_results   �o�בq�ɃR�[�h�ŐV��(A-3)
 *  get_shipment_results     �o�׎��я�񒊏o(A-4)
 *  get_latest_code          �ŐV�o�בq�Ɏ擾(A-5)
 *  ins_shipment_results     �e�R�[�h�o�׎��уf�[�^�쐬(A-7)
 *  upd_shipment_results     �e�R�[�h�o�׎��уf�[�^�X�V(A-8)
 *  upd_appl_contorols       �O�񏈗��������X�V(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   SCS.Tsubomatsu   �V�K�쐬
 *  2009/02/09    1.1   SCS.Kikuchi      �����s�No.004�Ή�(A-5.�Y���f�[�^�����̏ꍇ�̏����ύX)
 *  2009/02/16    1.2   SCS.Tsubomatsu   �����s�No.010�Ή�(A-3.�X�V����������)
 *  2009/04/13    1.3   SCS.Kikuchi      T1_0507�Ή�
 *  2009/05/12    1.4   SCS.Kikuchi      T1_0951�Ή�
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
  expt_XXCOP004A07          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOP004A07C';           -- �p�b�P�[�W��
  cv_date_format1           CONSTANT VARCHAR2(6)   := 'YYYYMM';                 -- ���t�t�H�[�}�b�g
  -- �v���t�@�C��
  cv_prof_retention_period  CONSTANT VARCHAR2(28)  := 'XXCOP1_DATA_RETENTION_PERIOD';   -- �e�R�[�h�o�׎��ѕێ�����
  cv_prof_itoe_ou_mfg       CONSTANT VARCHAR2(18)  := 'XXCOP1_ITOE_OU_MFG';             -- ���Y�c�ƒP�ʎ擾����
  cv_prof_whse_code         CONSTANT VARCHAR2(26)  := 'XXCMN_COST_PRICE_WHSE_CODE';     -- �����q��
  -- ���b�Z�[�W�E�A�v���P�[�V�������i�A�h�I���F�̕��E�v��̈�j
  cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP';
  -- ���b�Z�[�W��
  cv_message_00002          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00002';
  cv_message_00007          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00007';
  cv_message_00027          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00027';
  cv_message_00028          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00028';
  cv_message_00048          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-00048';
  cv_message_10017          CONSTANT VARCHAR2(16)  := 'APP-XXCOP1-10017';
  -- ���b�Z�[�W�g�[�N��
  cv_message_00002_token_1  CONSTANT VARCHAR2(9)   := 'PROF_NAME';
  cv_message_00007_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00027_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00028_token_1  CONSTANT VARCHAR2(5)   := 'TABLE';
  cv_message_00048_token_1  CONSTANT VARCHAR2(9)   := 'ITEM_NAME';
  -- �e�[�u����
  cv_table_xsr              CONSTANT VARCHAR2(100) := '�e�R�[�h�o�׎��ѕ\�A�h�I���e�[�u��';
  cv_table_xac              CONSTANT VARCHAR2(100) := '�v��p�R���g���[���e�[�u��';
  -- ���ږ�
  cv_last_process_date      CONSTANT VARCHAR2(100) := '�O�񏈗�����';
  cv_data_retention_period  CONSTANT VARCHAR2(100) := '�e�R�[�h�o�׎��ѕێ�����';
  cv_delete_start_date      CONSTANT VARCHAR2(100) := '�폜���';
  cv_itoe_ou_mfg            CONSTANT VARCHAR2(100) := '���Y�c�ƒP��';
  cv_org_id                 CONSTANT VARCHAR2(100) := '���Y�g�DID';
  -- �Œ�l
  cv_req_status             CONSTANT VARCHAR2(2)   := '04';           -- �󒍃w�b�_�A�h�I��.�X�e�[�^�X�i���ьv��ρj
  cv_wild_item_code         CONSTANT VARCHAR2(7)   := 'ZZZZZZZ';      -- �i�ڃ��C���h�J�[�h
  cv_chr_y                  CONSTANT VARCHAR2(1)   := 'Y';
  cv_chr_1                  CONSTANT VARCHAR2(1)   := '1';
  cv_chr_2                  CONSTANT VARCHAR2(1)   := '2';
  cv_order_categ_ord        CONSTANT VARCHAR2(5)   := 'ORDER';
  cv_order_categ_ret        CONSTANT VARCHAR2(6)   := 'RETURN';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_whse_code              VARCHAR2(3);    --   OPM�q�ɕʃJ�����_.�q�ɃR�[�h�i�����q�Ɂj
  gd_last_process_date      DATE;           --   �O�񏈗�����
  gn_data_retention_period  NUMBER;         --   �e�R�[�h�o�׎��ѕێ�����
  gd_delete_start_date      DATE;           --   �ߋ��f�[�^�폜���
  gv_itoe_ou_mfg            VARCHAR2(40);   --   ���Y�c�ƒP��
  gn_org_id                 NUMBER;         --   ���Y�g�DID
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��RECORD�^
  -- ===============================
  TYPE g_shipment_result_rtype IS RECORD (
    order_header_id       xxwsh_order_headers_all.order_header_id%TYPE      -- �󒍃w�b�_�A�h�I��.�󒍃w�b�_ID
   ,order_line_id         xxwsh_order_lines_all.order_line_id%TYPE          -- �󒍖��׃A�h�I��.�󒍖���ID
   ,shipping_item_code    xxwsh_order_lines_all.shipping_item_code%TYPE     -- �󒍖��׃A�h�I��.�o�וi��
   ,parent_item_no_ship   xxcop_item_categories1_v.parent_item_no%TYPE      -- �v��_�i�ڃJ�e�S���r���[1(�o�ד��).�e�i��No
   ,result_deliver_to     xxwsh_order_headers_all.result_deliver_to%TYPE    -- �󒍃w�b�_�A�h�I��.�o�א�_����
   ,deliver_from          xxwsh_order_headers_all.deliver_from%TYPE         -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
   ,head_sales_branch     xxwsh_order_headers_all.head_sales_branch%TYPE    -- �󒍃w�b�_�A�h�I��.�Ǌ����_
   ,shipped_date          xxwsh_order_headers_all.shipped_date%TYPE         -- �󒍃w�b�_�A�h�I��.�o�ד�
   ,shipped_quantity      xxwsh_order_lines_all.shipped_quantity%TYPE       -- �󒍖��׃A�h�I��.����
   ,uom_code              xxwsh_order_lines_all.uom_code%TYPE               -- �󒍖��׃A�h�I��.�P��
   ,parent_item_no_now    xxcop_item_categories1_v.parent_item_no%TYPE      -- �v��_�i�ڃJ�e�S���r���[1(�V�X�e�����t�).�e�i��No
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  TYPE g_shipment_result_ttype  IS TABLE OF g_shipment_result_rtype INDEX BY BINARY_INTEGER;  -- �o�׎��я��
  
  -- �f�o�b�O�o�͔���p
  gv_debug_mode                VARCHAR2(30);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
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
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg_wk      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ln_fiscal_year    NUMBER;          -- ���݉�v�N�x
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E���[�U��`��O ***
    init_expt EXCEPTION;
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
    --�����q�ɂ̎擾
    --==============================================================
    gv_whse_code := FND_PROFILE.VALUE( cv_prof_whse_code );
--
    --==============================================================
    --�O�񏈗������̎擾
    --==============================================================
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00048
                       ,iv_token_name1  => cv_message_00048_token_1
                       ,iv_token_value1 => cv_last_process_date
                      );
--
    BEGIN
      SELECT xac.last_process_date  last_process_date
      INTO   gd_last_process_date
      FROM   xxcop_appl_controls xac    -- �v��p�R���g���[���e�[�u��
      WHERE  xac.function_id = cv_pkg_name
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gd_last_process_date IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
    --==============================================================
    --�e�R�[�h�o�׎��ѕێ����Ԃ̎擾
    --==============================================================
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00002
                       ,iv_token_name1  => cv_message_00002_token_1
                       ,iv_token_value1 => cv_data_retention_period
                      );
--
    BEGIN
      gn_data_retention_period := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_retention_period ) );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_data_retention_period IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
    --==============================================================
    --�ߋ��f�[�^�폜����Z�o
    --==============================================================
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00048
                       ,iv_token_name1  => cv_message_00048_token_1
                       ,iv_token_value1 => cv_delete_start_date
                      );
--
    BEGIN
      -- ���݉�v�N�x�̎擾
      SELECT TO_NUMBER( icd.fiscal_year )
      INTO   ln_fiscal_year
      FROM   ic_cldr_dtl icd    -- OPM�݌ɃJ�����_�ڍ�
            ,ic_whse_sts iws    -- OPM�q�ɕʃJ�����_
      WHERE  TO_CHAR( icd.period_end_date, cv_date_format1 ) = TO_CHAR( SYSDATE, cv_date_format1 )
      AND    icd.period_id = iws.period_id
      AND    iws.whse_code = gv_whse_code
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF ( ln_fiscal_year IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
    BEGIN
      -- �ߋ��f�[�^�폜����̎擾
      SELECT MAX( icd.period_end_date )
      INTO   gd_delete_start_date
      FROM   ic_cldr_dtl icd    -- OPM�݌ɃJ�����_�ڍ�
            ,ic_whse_sts iws    -- OPM�q�ɕʃJ�����_
      WHERE  icd.fiscal_year = TO_CHAR( ln_fiscal_year - gn_data_retention_period )
      AND    icd.period_id   = iws.period_id
      AND    iws.whse_code   = gv_whse_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gd_delete_start_date IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
    --==============================================================
    --���Y�c�ƒP�ʑg�DID�擾
    --==============================================================
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00002
                       ,iv_token_name1  => cv_message_00002_token_1
                       ,iv_token_value1 => cv_itoe_ou_mfg
                      );
--
    BEGIN
      -- ���Y�c�ƒP�ʂ��擾
      gv_itoe_ou_mfg := FND_PROFILE.VALUE( cv_prof_itoe_ou_mfg );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_itoe_ou_mfg IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
    lv_errmsg_wk  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_application
                       ,iv_name         => cv_message_00048
                       ,iv_token_name1  => cv_message_00048_token_1
                       ,iv_token_value1 => cv_org_id
                      );
--
    BEGIN
      -- ���Y�g�DID���擾
      SELECT DISTINCT haou.organization_id
      INTO   gn_org_id
      FROM   hr_all_organization_units haou   -- �݌ɑg�D�}�X�^
      WHERE  haou.name = gv_itoe_ou_mfg
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := lv_errmsg_wk;
        lv_errbuf  := SQLERRM;
        RAISE init_expt;
    END;
--
    -- �擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg  := lv_errmsg_wk;
      RAISE init_expt;
    END IF;
--
  EXCEPTION
--
    WHEN init_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : del_shipment_results
   * Description      : �e�R�[�h�o�׎��щߋ��f�[�^�폜(A-2)
   ***********************************************************************************/
  PROCEDURE del_shipment_results(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_shipment_results'; -- �v���O������
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
    -- *** ���[�J��TABLE�^ ***
    TYPE l_xsr_rowid_ttype      IS TABLE OF ROWID INDEX BY BINARY_INTEGER;    -- �e�R�[�h�o�׎��уA�h�I���e�[�u��.ROWID
--
    -- *** ���[�J��PL/SQL�\ ***
    l_xsr_rowid_tab   l_xsr_rowid_ttype;  -- �e�R�[�h�o�׎��уA�h�I���e�[�u��.ROWID
--
    -- *** ���[�J���E���[�U��`��O ***
    del_shipment_results_expt EXCEPTION;
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
    --�e�R�[�h�o�׎��уA�h�I���e�[�u���̃��b�N
    --==============================================================
    BEGIN
      SELECT xsr.ROWID  xsr_rowid
      BULK COLLECT
      INTO   l_xsr_rowid_tab
      FROM   xxcop_shipment_results xsr   -- �e�R�[�h�o�׎��ѕ\�A�h�I��
      WHERE  xsr.shipment_date <= gd_delete_start_date  -- �o�ד� �� �ߋ��f�[�^�폜���
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE del_shipment_results_expt;
    END;
--
    --==============================================================
    --�e�R�[�h�o�׎��уA�h�I���e�[�u���̍폜
    --==============================================================
    DELETE xxcop_shipment_results xsr   -- �e�R�[�h�o�׎��ѕ\�A�h�I��
    WHERE  xsr.shipment_date <= gd_delete_start_date  -- �o�ד� �� �ߋ��f�[�^�폜���
    ;
--
--
  EXCEPTION
--
    WHEN del_shipment_results_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END del_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : renew_shipment_results
   * Description      : �o�בq�ɃR�[�h�ŐV��(A-3)
   ***********************************************************************************/
  PROCEDURE renew_shipment_results(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'renew_shipment_results'; -- �v���O������
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
    l_xsr_rowid   ROWID;  -- �e�R�[�h�o�׎��ѕ\�A�h�I��.ROWID
--��1.2 2009/02/16 ADD START
    lv_delivery_whse_code   xxcmn_sourcing_rules.delivery_whse_code%TYPE;   -- �o�וۊǑq�ɃR�[�h
    lb_exist                BOOLEAN;  -- �����\���\���݃t���O
    lb_update               BOOLEAN;  -- �ŐV�o�בq�ɍX�V�t���O
--��1.2 2009/02/16 ADD END
--
    -- *** ���[�J���E�J�[�\�� ***
--��1.2 2009/02/16 UPD START
--��    CURSOR renew_shipment_results_cur IS
--��      SELECT xsr.ROWID                  xsr_rowid                 -- �e�R�[�h�o�׎��ѕ\�A�h�I��.ROWID
--��            ,xsrl.delivery_whse_code    latest_deliver_from_new   -- �����\���\�A�h�I���}�X�^.�o�וۊǑq�ɃR�[�h
--��      FROM   xxcop_shipment_results xsr       -- �e�R�[�h�o�׎��ѕ\�A�h�I��
--��            ,xxcmn_sourcing_rules xsrl        -- �����\���\�A�h�I���}�X�^
--��      WHERE  xsr.item_no       = xsrl.item_code
--��      AND    xsr.base_code     = xsrl.base_code
--��      AND    xsr.deliver_to    = xsrl.ship_to_code
--��      AND    SYSDATE     BETWEEN xsrl.start_date_active
--��                         AND     xsrl.end_date_active
--��        -- �o�וۊǑq�ɃR�[�h���ς�����f�[�^�𒊏o
--��      AND      ( xsrl.delivery_whse_code             IS NOT NULL
--��      AND        NVL( xsr.latest_deliver_from, ' ' ) <> NVL( xsrl.delivery_whse_code, ' ' ) )
--��      ;
    -- �o�בq�ɃR�[�h�ŐV���Ώۃf�[�^���o
    CURSOR renew_data_cur IS
      -- ===================================================================================
      -- �ύX�̂����������\���\�A�h�I���}�X�^���猩�āA
      -- �ύX�𔽉f������\���̂���e�R�[�h�o�׎��ѕ\�A�h�I���̃f�[�^��S�Ē��o����B
      -- �i�ύX�𔽉f�����Ȃ��ꍇ�����݂���j
      -- ===================================================================================
      SELECT DISTINCT
             xsr.ROWID                  xsr_rowid             -- �e�R�[�h�o�׎��ѕ\�A�h�I��.ROWID
            ,xsr.item_no                item_no               -- �i�ڃR�[�h
            ,xsr.deliver_to             deliver_to            -- �z����R�[�h
            ,xsr.base_code              base_code             -- ���_�R�[�h
            ,xsr.latest_deliver_from    latest_deliver_from   -- �ŐV�o�בq�ɃR�[�h
      FROM   xxcop_shipment_results xsr       -- �e�R�[�h�o�׎��ѕ\�A�h�I��
            ,xxcmn_sourcing_rules   xsrl      -- �����\���\�A�h�I���}�X�^
        -- �V�X�e���������_�ŗL���ȃf�[�^
      WHERE  SYSDATE BETWEEN xsrl.start_date_active
                     AND     xsrl.end_date_active
          -- �O�񏈗���������V�X�e�������܂ł̊ԂɗL���J�n�ƂȂ�f�[�^
          -- �܂��͑O�񏈗������ȍ~�ɍX�V���ꂽ�f�[�^
      AND  ( ( xsrl.start_date_active BETWEEN TRUNC( gd_last_process_date )
                                      AND     SYSDATE )
      OR     ( xsrl.last_update_date >= gd_last_process_date ) )
          -- �z����܂��͋��_����v����f�[�^
      AND  ( xsr.deliver_to           = xsrl.ship_to_code
      OR     xsr.base_code            = xsrl.base_code )
          -- �i�ڂ���v����f�[�^(ZZZZZZZ(�i�ڃ��C���h�J�[�h)�̏ꍇ�͏���)
      AND    xsr.item_no              = DECODE( xsrl.item_code
                                               ,cv_wild_item_code
                                               ,xsr.item_no          -- �i�ڃ��C���h�J�[�h�̏ꍇ�͑S�i�ڑΏ�
                                               ,xsrl.item_code )     -- ����ȊO�̏ꍇ�͈�v����i�ڂ̂�
      ;
--
    -- �����\���\�A�h�I���Q�ƃp�^�[���P(�i�ڃR�[�h�{�z����R�[�h)
    CURSOR get_sourcing_rules_cur1(
      lv_item_code      xxcmn_sourcing_rules.item_code%TYPE
     ,lv_ship_to_code   xxcmn_sourcing_rules.ship_to_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
      FROM   xxcmn_sourcing_rules   xsrl  -- �����\���\�A�h�I���}�X�^
      WHERE  xsrl.item_code      = lv_item_code
      AND    xsrl.ship_to_code   = lv_ship_to_code
        -- �V�X�e���������_�ŗL���ȃf�[�^
      AND    SYSDATE BETWEEN xsrl.start_date_active
                     AND     xsrl.end_date_active
      ;
--
    -- �����\���\�A�h�I���Q�ƃp�^�[���Q(�i�ڃR�[�h�{���_�R�[�h)
    CURSOR get_sourcing_rules_cur2(
      lv_item_code      xxcmn_sourcing_rules.item_code%TYPE
     ,lv_base_code      xxcmn_sourcing_rules.base_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
      FROM   xxcmn_sourcing_rules   xsrl  -- �����\���\�A�h�I���}�X�^
      WHERE  xsrl.item_code      = lv_item_code
      AND    xsrl.base_code      = lv_base_code
        -- �V�X�e���������_�ŗL���ȃf�[�^
      AND    SYSDATE BETWEEN xsrl.start_date_active
                     AND     xsrl.end_date_active
      ;
--
    -- �����\���\�A�h�I���Q�ƃp�^�[���R(ZZZZZZZ(�i�ڃ��C���h�J�[�h)�{�z����R�[�h)
    CURSOR get_sourcing_rules_cur3(
      lv_ship_to_code   xxcmn_sourcing_rules.ship_to_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
      FROM   xxcmn_sourcing_rules   xsrl  -- �����\���\�A�h�I���}�X�^
      WHERE  xsrl.item_code      = cv_wild_item_code    -- �i�ڃ��C���h�J�[�h
      AND    xsrl.ship_to_code   = lv_ship_to_code
        -- �V�X�e���������_�ŗL���ȃf�[�^
      AND    SYSDATE BETWEEN xsrl.start_date_active
                     AND     xsrl.end_date_active
      ;
--
    -- �����\���\�A�h�I���Q�ƃp�^�[���S(ZZZZZZZ(�i�ڃ��C���h�J�[�h)�{���_�R�[�h)
    CURSOR get_sourcing_rules_cur4(
      lv_base_code      xxcmn_sourcing_rules.base_code%TYPE )
    IS
      SELECT xsrl.delivery_whse_code  delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
      FROM   xxcmn_sourcing_rules   xsrl  -- �����\���\�A�h�I���}�X�^
      WHERE  xsrl.item_code      = cv_wild_item_code    -- �i�ڃ��C���h�J�[�h
      AND    xsrl.base_code      = lv_base_code
        -- �V�X�e���������_�ŗL���ȃf�[�^
      AND    SYSDATE BETWEEN xsrl.start_date_active
                     AND     xsrl.end_date_active
      ;
--
--��1.2 2009/02/16 UPD END
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E���[�U��`��O ***
    renew_shipment_results_expt EXCEPTION;
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
    --�e�R�[�h�A�o�בq�ɃR�[�h�ŐV���Ώۃf�[�^�̃��[�v�J�n
    --==============================================================
--��1.2 2009/02/16 UPD START
--��    <<renew_shipment_results_loop>>
--��    FOR renew_shipment_results_rec IN renew_shipment_results_cur LOOP
--��--
--��      --==============================================================
--��      --�e�R�[�h�o�׎��уA�h�I���e�[�u���̃��b�N
--��      --==============================================================
--��      SELECT xsr.ROWID  xsr_rowid
--��      INTO   l_xsr_rowid
--��      FROM   xxcop_shipment_results xsr       -- �e�R�[�h�o�׎��ѕ\�A�h�I��
--��      WHERE  xsr.ROWID = renew_shipment_results_rec.xsr_rowid
--��      FOR UPDATE NOWAIT
--��      ;
--��--
--��      --==============================================================
--��      --�e�R�[�h�o�׎��т̃R�[�h�ŐV��
--��      --==============================================================
--��      UPDATE xxcop_shipment_results xsr
--��      SET    xsr.latest_deliver_from      = NVL( renew_shipment_results_rec.latest_deliver_from_new
--��                                                ,xsr.latest_deliver_from )  -- �ŐV�o�בq�ɃR�[�h
--��            ,xsr.last_updated_by          = cn_last_updated_by                          -- �ŏI�X�V��
--��            ,xsr.last_update_date         = cd_last_update_date                         -- �ŏI�X�V��
--��            ,xsr.last_update_login        = cn_last_update_login                        -- �ŏI�X�V���O�C��
--��            ,xsr.request_id               = cn_request_id                               -- �v��ID
--��            ,xsr.program_application_id   = cn_program_application_id                   -- �v���O�����A�v���P�[�V����ID
--��            ,xsr.program_id               = cn_program_id                               -- �v���O����ID
--��            ,xsr.program_update_date      = cd_program_update_date                      -- �v���O�����X�V��
--��      WHERE  xsr.ROWID = renew_shipment_results_rec.xsr_rowid
--��      ;
--��--
--��    END LOOP renew_shipment_results;
--��--
    --==============================================================
    --�o�בq�ɃR�[�h�ŐV���Ώۃf�[�^���o
    --==============================================================
    <<renew_data_loop>>
    FOR renew_data_rec IN renew_data_cur LOOP
--
      -- �ϐ�������
      lv_delivery_whse_code   := '';
      lb_exist                := FALSE;
      lb_update               := FALSE;
--
      --==============================================================
      --�����\���\�A�h�I���Q�ƃp�^�[���P(�i�ڃR�[�h�{�z����R�[�h)
      --==============================================================
      OPEN get_sourcing_rules_cur1(
        renew_data_rec.item_no
       ,renew_data_rec.deliver_to );
      FETCH get_sourcing_rules_cur1 INTO lv_delivery_whse_code;
      -- �Y���f�[�^�����݂���ꍇ
      IF ( get_sourcing_rules_cur1%FOUND ) THEN
        -- ���݃t���O���Z�b�g
        lb_exist := TRUE;
        -- �e�R�[�h�̍ŐV�o�בq�ɃR�[�h�ƕ����\���\�̏o�בq�ɃR�[�h���قȂ�ꍇ
        IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
          -- �X�V�t���O���Z�b�g
          lb_update := TRUE;
        END IF;
      END IF;
      CLOSE get_sourcing_rules_cur1;
--
      -- ��ʃp�^�[���ɊY���f�[�^�����݂��Ȃ��ꍇ
      IF NOT lb_exist THEN
        --==============================================================
        --�����\���\�A�h�I���Q�ƃp�^�[���Q(�i�ڃR�[�h�{���_�R�[�h)
        --==============================================================
        OPEN get_sourcing_rules_cur2(
          renew_data_rec.item_no
         ,renew_data_rec.base_code );
        FETCH get_sourcing_rules_cur2 INTO lv_delivery_whse_code;
        -- �Y���f�[�^�����݂���ꍇ
        IF ( get_sourcing_rules_cur2%FOUND ) THEN
          -- ���݃t���O���Z�b�g
          lb_exist := TRUE;
          -- �e�R�[�h�̍ŐV�o�בq�ɃR�[�h�ƕ����\���\�̏o�בq�ɃR�[�h���قȂ�ꍇ
          IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
            -- �X�V�t���O���Z�b�g
            lb_update := TRUE;
          END IF;
        END IF;
        CLOSE get_sourcing_rules_cur2;
      END IF;
--
      -- ��ʃp�^�[���ɊY���f�[�^�����݂��Ȃ��ꍇ
      IF NOT lb_exist THEN
        --==============================================================
        --�����\���\�A�h�I���Q�ƃp�^�[���R(ZZZZZZZ(�i�ڃ��C���h�J�[�h)�{�z����R�[�h)
        --==============================================================
        OPEN get_sourcing_rules_cur3( renew_data_rec.deliver_to );
        FETCH get_sourcing_rules_cur3 INTO lv_delivery_whse_code;
        -- �Y���f�[�^�����݂���ꍇ
        IF ( get_sourcing_rules_cur3%FOUND ) THEN
          -- ���݃t���O���Z�b�g
          lb_exist := TRUE;
          -- �e�R�[�h�̍ŐV�o�בq�ɃR�[�h�ƕ����\���\�̏o�בq�ɃR�[�h���قȂ�ꍇ
          IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
            -- �X�V�t���O���Z�b�g
            lb_update := TRUE;
          END IF;
        END IF;
        CLOSE get_sourcing_rules_cur3;
      END IF;
--
      -- ��ʃp�^�[���ɊY���f�[�^�����݂��Ȃ��ꍇ
      IF NOT lb_exist THEN
        --==============================================================
        --�����\���\�A�h�I���Q�ƃp�^�[���S(ZZZZZZZ(�i�ڃ��C���h�J�[�h)�{���_�R�[�h)
        --==============================================================
        OPEN get_sourcing_rules_cur4( renew_data_rec.base_code );
        FETCH get_sourcing_rules_cur4 INTO lv_delivery_whse_code;
        -- �Y���f�[�^�����݂���ꍇ
        IF ( get_sourcing_rules_cur4%FOUND ) THEN
          -- ���݃t���O���Z�b�g
          lb_exist := TRUE;
          -- �e�R�[�h�̍ŐV�o�בq�ɃR�[�h�ƕ����\���\�̏o�בq�ɃR�[�h���قȂ�ꍇ
          IF ( NVL( renew_data_rec.latest_deliver_from, ' ' ) <> NVL( lv_delivery_whse_code, ' ' ) ) THEN
            -- �X�V�t���O���Z�b�g
            lb_update := TRUE;
          END IF;
        END IF;
        CLOSE get_sourcing_rules_cur4;
      END IF;
--
      -- �X�V�Ώۂ̏ꍇ
      IF lb_update THEN
        --==============================================================
        --�e�R�[�h�o�׎��уA�h�I���e�[�u���̃��b�N
        --==============================================================
        SELECT xsr.ROWID  xsr_rowid
        INTO   l_xsr_rowid
        FROM   xxcop_shipment_results xsr       -- �e�R�[�h�o�׎��ѕ\�A�h�I��
        WHERE  xsr.ROWID = renew_data_rec.xsr_rowid
        FOR UPDATE NOWAIT
        ;
--
        --==============================================================
        --�e�R�[�h�o�׎��т̃R�[�h�ŐV��
        --==============================================================
        UPDATE xxcop_shipment_results xsr
        SET    xsr.latest_deliver_from      = lv_delivery_whse_code       -- �ŐV�o�בq�ɃR�[�h
              ,xsr.last_updated_by          = cn_last_updated_by          -- �ŏI�X�V��
              ,xsr.last_update_date         = cd_last_update_date         -- �ŏI�X�V��
              ,xsr.last_update_login        = cn_last_update_login        -- �ŏI�X�V���O�C��
              ,xsr.request_id               = cn_request_id               -- �v��ID
              ,xsr.program_application_id   = cn_program_application_id   -- �v���O�����A�v���P�[�V����ID
              ,xsr.program_id               = cn_program_id               -- �v���O����ID
              ,xsr.program_update_date      = cd_program_update_date      -- �v���O�����X�V��
        WHERE  xsr.ROWID = renew_data_rec.xsr_rowid
        ;
      END IF;
--
    END LOOP renew_data_loop;
--
--��1.2 2009/02/16 UPD END
  EXCEPTION
--
    WHEN renew_shipment_results_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END renew_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : get_shipment_results
   * Description      : �o�׎��я�񒊏o(A-4)
   ***********************************************************************************/
  PROCEDURE get_shipment_results(
    o_shipment_result_tab OUT g_shipment_result_ttype,  -- �o�׎��я��
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_shipment_results'; -- �v���O������
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
    -- *** ���[�J���E���[�U��`��O ***
    get_shipment_results_expt EXCEPTION;
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
    --�o�׎��я�񒊏o
    --==============================================================
    BEGIN
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_START
--      SELECT xoha.order_header_id             order_header_id       -- �󒍃w�b�_�A�h�I��.�󒍃w�b�_�A�h�I��ID
      SELECT /*+ ORDERED */
             xoha.order_header_id             order_header_id       -- �󒍃w�b�_�A�h�I��.�󒍃w�b�_�A�h�I��ID
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_END
            ,xola.order_line_id               order_line_id         -- �󒍖��׃A�h�I��.�󒍖��׃A�h�I��ID
            ,xola.shipping_item_code          shipping_item_code    -- �󒍖��׃A�h�I��.�o�וi��
            ,xicv_s.parent_item_no            parent_item_no_ship   -- �v��_�i�ڃJ�e�S���r���[1(�o�ד��).�e�i��No
            ,xoha.result_deliver_to           result_deliver_to     -- �󒍃w�b�_�A�h�I��.�o�א�_����
            ,xoha.deliver_from                deliver_from          -- �󒍃w�b�_�A�h�I��.�o�׌��ۊǏꏊ
            ,xoha.head_sales_branch           head_sales_branch     -- �󒍃w�b�_�A�h�I��.�Ǌ����_
            ,xoha.shipped_date                shipped_date          -- �󒍃w�b�_�A�h�I��.�o�ד�
--
            ,CASE
               WHEN ( otta.order_category_code = cv_order_categ_ord )
                 -- �󒍃^�C�v�}�X�^.�󒍃J�e�S���R�[�h��'ORDER'�̏ꍇ�͐��ʂ����̂܂܎擾
                 THEN NVL( xola.shipped_quantity, 0 )
               WHEN ( otta.order_category_code = cv_order_categ_ret )
                 -- �󒍃^�C�v�}�X�^.�󒍃J�e�S���R�[�h��'RETURN'�̏ꍇ�͐��ʁ~(-1)���擾
                 THEN NVL( xola.shipped_quantity, 0 ) * ( -1 )
             END                              quantity              -- �󒍖��׃A�h�I��.����
--
            ,xola.uom_code                    uom_code              -- �󒍖��׃A�h�I��.�P��
            ,xicv_n.parent_item_no            parent_item_no_now    -- �v��_�i�ڃJ�e�S���r���[1(�V�X�e�����t�).�e�i��No
      BULK COLLECT
      INTO   o_shipment_result_tab
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_START
--      FROM   xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
--            ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
--            ,xxcop_item_categories1_v   xicv_s    -- �i�ڃJ�e�S���r���[(�o�ד��)
--            ,xxcop_item_categories1_v   xicv_n    -- �i�ڃJ�e�S���r���[(�V�X�e�����t�)
--            ,oe_transaction_types_all   otta      -- �󒍃^�C�v�}�X�^
--            ,oe_transaction_types_tl    ottt      -- �󒍃^�C�v�}�X�^�ڍ�
      FROM   oe_transaction_types_tl    ottt      -- �󒍃^�C�v�}�X�^�ڍ�
            ,oe_transaction_types_all   otta      -- �󒍃^�C�v�}�X�^
            ,xxwsh_order_headers_all    xoha      -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all      xola      -- �󒍖��׃A�h�I��
            ,xxcop_item_categories1_v   xicv_n    -- �i�ڃJ�e�S���r���[(�V�X�e�����t�)
            ,xxcop_item_categories1_v   xicv_s    -- �i�ڃJ�e�S���r���[(�o�ד��)
--20090413_Ver1.3_T1_0507_SCS.Kikuchi_MOD_END
      WHERE  xoha.order_header_id = xola.order_header_id
--
        -- �i�ڃJ�e�S���r���[���o�ד���Ō���
      AND    xola.shipping_inventory_item_id     = xicv_s.inventory_item_id
      AND    xoha.shipped_date         BETWEEN     xicv_s.start_date_active
                                       AND         xicv_s.end_date_active
        -- �i�ڃJ�e�S���r���[���V�X�e�����t��Ō���
      AND    xola.shipping_inventory_item_id     = xicv_n.inventory_item_id
      AND    SYSDATE                   BETWEEN     xicv_n.start_date_active
                                       AND         xicv_n.end_date_active
--
      AND    xoha.req_status                     = cv_req_status
--20090512_Ver1.4_T1_0951_SCS.Kikuchi_MOD_START
--      AND    xola.shipping_result_if_flg         = cv_chr_y
      AND    xoha.actual_confirm_class           = cv_chr_y                -- ���ьv��ϋ敪
--20090512_Ver1.4_T1_0951_SCS.Kikuchi_MOD_END
      AND    xola.last_update_date              >= gd_last_process_date
      AND    otta.attribute1                     = cv_chr_1
      AND    NVL( otta.attribute4, cv_chr_1 )   <> cv_chr_2
      AND    otta.org_id                         = gn_org_id
      AND    otta.transaction_type_id            = ottt.transaction_type_id
      AND    ottt.language                       = USERENV( 'LANG' )
      AND    xoha.order_type_id                  = otta.transaction_type_id
      ;
    EXCEPTION
      -- �Ώۃf�[�^0���̏ꍇ�͐���I��
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
--
    WHEN get_shipment_results_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : get_latest_code
   * Description      : �ŐV�o�בq�Ɏ擾(A-5)
   ***********************************************************************************/
  PROCEDURE get_latest_code(
    i_shipment_result_rec IN  g_shipment_result_rtype,                        -- �o�׎��я��
    ov_delivery_whse_code OUT xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL    ov_base_code          OUT xxcmn_sourcing_rules.base_code%TYPE,            -- ���_�R�[�h
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_latest_code'; -- �v���O������
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
    -- *** ���[�J���E���[�U��`��O ***
    get_latest_code_expt EXCEPTION;
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
    --�i�ڃR�[�h �{ �z����R�[�h�Ō���
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- ���_�R�[�h
      INTO   ov_delivery_whse_code
--��1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- �����\���\�A�h�I���}�X�^
      WHERE  xsr.item_code          = i_shipment_result_rec.shipping_item_code    -- �󒍖��׃A�h�I��.�o�וi��
      AND    xsr.ship_to_code       = i_shipment_result_rec.result_deliver_to     -- �󒍃w�b�_�A�h�I��.�o�א�_����
      AND    SYSDATE          BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
      ;
--
      -- �f�[�^���擾�ł����ꍇ�͖߂�
      RETURN;
--
    EXCEPTION
      -- �Ώۃf�[�^0���̏ꍇ�͐���I��
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --�i�ڃR�[�h �{ ���_�R�[�h�Ō���
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- ���_�R�[�h
      INTO   ov_delivery_whse_code
--��1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- �����\���\�A�h�I���}�X�^
      WHERE  xsr.item_code          = i_shipment_result_rec.shipping_item_code    -- �󒍖��׃A�h�I��.�o�וi��
--��1.1 2009/02/09 UPD START
--��      AND    xsr.ship_to_code       = i_shipment_result_rec.head_sales_branch     -- �󒍃w�b�_�A�h�I��.�Ǌ����_
      AND    xsr.base_code          = i_shipment_result_rec.head_sales_branch     -- �󒍃w�b�_�A�h�I��.�Ǌ����_
--��1.1 2009/02/09 UPD END
      AND    SYSDATE          BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
      ;
--
      -- �f�[�^���擾�ł����ꍇ�͖߂�
      RETURN;
--
    EXCEPTION
      -- �Ώۃf�[�^0���̏ꍇ�͐���I��
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --ZZZZZZZ(�i�ڃ��C���h�J�[�h) �{ �z����R�[�h�Ō���
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- ���_�R�[�h
      INTO   ov_delivery_whse_code
--��1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- �����\���\�A�h�I���}�X�^
      WHERE  xsr.item_code          = cv_wild_item_code                           -- �i�ڃ��C���h�J�[�h
      AND    xsr.ship_to_code       = i_shipment_result_rec.result_deliver_to     -- �󒍃w�b�_�A�h�I��.�o�א�_����
      AND    SYSDATE          BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
      ;
--
      -- �f�[�^���擾�ł����ꍇ�͖߂�
      RETURN;
--
    EXCEPTION
      -- �Ώۃf�[�^0���̏ꍇ�͐���I��
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --ZZZZZZZ(�i�ڃ��C���h�J�[�h) �{ ���_�R�[�h�Ō���
    --==============================================================
    BEGIN
      SELECT xsr.delivery_whse_code   delivery_whse_code    -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL            ,xsr.base_code            base_code             -- ���_�R�[�h
      INTO   ov_delivery_whse_code
--��1.1 2009/02/09 DEL            ,ov_base_code
      FROM   xxcmn_sourcing_rules xsr   -- �����\���\�A�h�I���}�X�^
      WHERE  xsr.item_code          = cv_wild_item_code                           -- �i�ڃ��C���h�J�[�h
--��1.1 2009/02/09 UPD START
--��      AND    xsr.ship_to_code       = i_shipment_result_rec.head_sales_branch     -- �󒍃w�b�_�A�h�I��.�Ǌ����_
      AND    xsr.base_code          = i_shipment_result_rec.head_sales_branch     -- �󒍃w�b�_�A�h�I��.�Ǌ����_
--��1.1 2009/02/09 UPD END
      AND    SYSDATE          BETWEEN xsr.start_date_active
                              AND     xsr.end_date_active
      ;
--
      -- �f�[�^���擾�ł����ꍇ�͖߂�
      RETURN;
--
    EXCEPTION
      -- �Ώۃf�[�^0���̏ꍇ�͐���I��
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
--
    WHEN get_latest_code_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_latest_code;
--
  /**********************************************************************************
   * Procedure Name   : ins_shipment_results
   * Description      : �e�R�[�h�o�׎��уf�[�^�쐬(A-7)
   ***********************************************************************************/
  PROCEDURE ins_shipment_results(
    i_shipment_result_rec IN  g_shipment_result_rtype,                        -- �o�׎��я��
    iv_delivery_whse_code IN  xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL    iv_base_code          IN  xxcmn_sourcing_rules.base_code%TYPE,            -- ���_�R�[�h
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_shipment_results'; -- �v���O������
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
    -- *** ���[�J���E���[�U��`��O ***
    ins_shipment_results_expt EXCEPTION;
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
    --�e�R�[�h�o�׎��ѕ\�A�h�I���e�[�u���ւ̓o�^
    --==============================================================
    BEGIN
      INSERT INTO xxcop_shipment_results (
        order_header_id               -- �󒍃w�b�_�A�h�I��ID
       ,order_line_id                 -- �󒍖��׃A�h�I��ID
       ,item_no                       -- �q�i�ڃR�[�h
       ,parent_item_no                -- �e�i�ڃR�[�h
       ,deliver_to                    -- �z����R�[�h
       ,deliver_from                  -- �o�בq�ɃR�[�h
       ,base_code                     -- ���_�R�[�h
       ,shipment_date                 -- �o�ד�
       ,quantity                      -- ����
       ,uom_code                      -- �P��
       ,latest_parent_item_no         -- �ŐV�e�i�ڃR�[�h
       ,latest_deliver_from           -- �ŐV�o�בq�ɃR�[�h
       ,created_by                    -- �쐬��
       ,creation_date                 -- �쐬��
       ,last_updated_by               -- �ŏI�X�V��
       ,last_update_date              -- �ŏI�X�V��
       ,last_update_login             -- �ŏI�X�V���O�C��
       ,request_id                    -- �v��ID
       ,program_application_id        -- �v���O�����A�v���P�[�V����ID
       ,program_id                    -- �v���O����ID
       ,program_update_date           -- �v���O�����X�V��
      ) VALUES (
        i_shipment_result_rec.order_header_id         -- �󒍃w�b�_�A�h�I��ID
       ,i_shipment_result_rec.order_line_id           -- �󒍖��׃A�h�I��ID
       ,i_shipment_result_rec.shipping_item_code      -- �q�i�ڃR�[�h
       ,i_shipment_result_rec.parent_item_no_ship     -- �e�i�ڃR�[�h
       ,i_shipment_result_rec.result_deliver_to       -- �z����R�[�h
       ,i_shipment_result_rec.deliver_from            -- �o�בq�ɃR�[�h
--��1.1 2009/02/09 UPD START
--��       ,iv_base_code                                  -- ���_�R�[�h
       ,i_shipment_result_rec.head_sales_branch       -- ���_�R�[�h
--��1.1 2009/02/09 UPD END
       ,i_shipment_result_rec.shipped_date            -- �o�ד�
       ,i_shipment_result_rec.shipped_quantity        -- ����
       ,i_shipment_result_rec.uom_code                -- �P��
       ,NULL                                          -- �ŐV�e�i�ڃR�[�h
       ,iv_delivery_whse_code                         -- �ŐV�o�בq�ɃR�[�h
       ,cn_created_by                                 -- �쐬��
       ,cd_creation_date                              -- �쐬��
       ,cn_last_updated_by                            -- �ŏI�X�V��
       ,cd_last_update_date                           -- �ŏI�X�V��
       ,cn_last_update_login                          -- �ŏI�X�V���O�C��
       ,cn_request_id                                 -- �v��ID
       ,cn_program_application_id                     -- �v���O�����A�v���P�[�V����ID
       ,cn_program_id                                 -- �v���O����ID
       ,cd_program_update_date                        -- �v���O�����X�V��
      )
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00027
                        ,iv_token_name1  => cv_message_00027_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE ins_shipment_results_expt;
    END;
--
  EXCEPTION
--
    WHEN ins_shipment_results_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END ins_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : upd_shipment_results
   * Description      : �e�R�[�h�o�׎��уf�[�^�X�V(A-8)
   ***********************************************************************************/
  PROCEDURE upd_shipment_results(
    i_shipment_result_rec IN  g_shipment_result_rtype,                        -- �o�׎��я��
    iv_delivery_whse_code IN  xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL    iv_base_code          IN  xxcmn_sourcing_rules.base_code%TYPE,            -- ���_�R�[�h
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_shipment_results'; -- �v���O������
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
    l_xsr_rowid   ROWID;  -- �e�R�[�h�o�׎��ѕ\�A�h�I��.ROWID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E���[�U��`��O ***
    upd_shipment_results_expt EXCEPTION;
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
    --�e�R�[�h�o�׎��уA�h�I���e�[�u���̃��b�N
    --==============================================================
    BEGIN
      SELECT xsr.ROWID  xsr_rowid
      INTO   l_xsr_rowid
      FROM   xxcop_shipment_results xsr       -- �e�R�[�h�o�׎��ѕ\�A�h�I��
      WHERE  xsr.order_header_id = i_shipment_result_rec.order_header_id  -- �󒍃w�b�_�A�h�I��ID
      AND    xsr.order_line_id   = i_shipment_result_rec.order_line_id    -- �󒍖��׃A�h�I��ID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_shipment_results_expt;
    END;
--
    --==============================================================
    --�e�R�[�h�o�׎��ѕ\�A�h�I���e�[�u���̍X�V
    --==============================================================
    BEGIN
      UPDATE xxcop_shipment_results xsr   -- �e�R�[�h�o�׎��ѕ\�A�h�I��
      SET    xsr.item_no                  = i_shipment_result_rec.shipping_item_code    -- �q�i�ڃR�[�h
            ,xsr.parent_item_no           = i_shipment_result_rec.parent_item_no_ship   -- �e�i�ڃR�[�h
            ,xsr.deliver_to               = i_shipment_result_rec.result_deliver_to     -- �z����R�[�h
            ,xsr.deliver_from             = i_shipment_result_rec.deliver_from          -- �o�בq�ɃR�[�h
--��1.1 2009/02/09 UPD START
--��            ,xsr.base_code                = iv_base_code                                -- ���_�R�[�h
            ,xsr.base_code                = i_shipment_result_rec.head_sales_branch     -- ���_�R�[�h
--��1.1 2009/02/09 UPD END
            ,xsr.shipment_date            = i_shipment_result_rec.shipped_date          -- �o�ד�
            ,xsr.quantity                 = i_shipment_result_rec.shipped_quantity      -- ����
            ,xsr.uom_code                 = i_shipment_result_rec.uom_code              -- �P��
            ,xsr.latest_parent_item_no    = NULL                                        -- �ŐV�e�i�ڃR�[�h
            ,xsr.latest_deliver_from      = iv_delivery_whse_code                       -- �ŐV�o�בq�ɃR�[�h
            ,xsr.last_updated_by          = cn_last_updated_by                          -- �ŏI�X�V��
            ,xsr.last_update_date         = cd_last_update_date                         -- �ŏI�X�V��
            ,xsr.last_update_login        = cn_last_update_login                        -- �ŏI�X�V���O�C��
            ,xsr.request_id               = cn_request_id                               -- �v��ID
            ,xsr.program_application_id   = cn_program_application_id                   -- �v���O�����A�v���P�[�V����ID
            ,xsr.program_id               = cn_program_id                               -- �v���O����ID
            ,xsr.program_update_date      = cd_program_update_date                      -- �v���O�����X�V��
      WHERE  xsr.ROWID                    = l_xsr_rowid
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00028
                        ,iv_token_name1  => cv_message_00028_token_1
                        ,iv_token_value1 => cv_table_xsr
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_shipment_results_expt;
    END;
--
  EXCEPTION
--
    WHEN upd_shipment_results_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END upd_shipment_results;
--
  /**********************************************************************************
   * Procedure Name   : upd_appl_contorols
   * Description      : �O�񏈗��������X�V(A-9)
   ***********************************************************************************/
  PROCEDURE upd_appl_contorols(
    ov_errbuf             OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_appl_contorols'; -- �v���O������
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
    l_xac_rowid   ROWID;  -- �v��p�R���g���[���e�[�u��.ROWID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E���[�U��`��O ***
    upd_appl_contorols_expt EXCEPTION;
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
    --�v��p�R���g���[���e�[�u���̃��b�N
    --==============================================================
    BEGIN
      SELECT xac.ROWID  xac_rowid
      INTO   l_xac_rowid
      FROM   xxcop_appl_controls xac    -- �v��p�R���g���[���e�[�u��
      WHERE  xac.function_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_00007
                        ,iv_token_name1  => cv_message_00007_token_1
                        ,iv_token_value1 => cv_table_xac
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_appl_contorols_expt;
    END;
--
    --==============================================================
    --�v��p�R���g���[���e�[�u���̍X�V
    --==============================================================
    BEGIN
      UPDATE xxcop_appl_controls xac    -- �v��p�R���g���[���e�[�u��
      SET    xac.last_process_date        = SYSDATE                       -- �O�񏈗�����
            ,xac.last_updated_by          = cn_last_updated_by            -- �ŏI�X�V��
            ,xac.last_update_date         = cd_last_update_date           -- �ŏI�X�V��
            ,xac.last_update_login        = cn_last_update_login          -- �ŏI�X�V���O�C��
            ,xac.request_id               = cn_request_id                 -- �v��ID
            ,xac.program_application_id   = cn_program_application_id     -- �v���O�����A�v���P�[�V����ID
            ,xac.program_id               = cn_program_id                 -- �v���O����ID
            ,xac.program_update_date      = cd_program_update_date        -- �v���O�����X�V��
      WHERE  xac.ROWID                    = l_xac_rowid
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_application
                        ,iv_name         => cv_message_10017
                       );
        lv_errbuf  := SQLERRM;
        RAISE upd_appl_contorols_expt;
    END;
--
  EXCEPTION
--
    WHEN upd_appl_contorols_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END upd_appl_contorols;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    ln_idx                   NUMBER;  -- PL/SQL�\�F�o�׎��я�񒊏o�̃C���f�b�N�X�ԍ�
    ln_xsr_count             NUMBER;  -- �e�R�[�h�o�׎��ѕ\�A�h�I�����݃`�F�b�N�p
    lv_delivery_whse_code    xxcmn_sourcing_rules.delivery_whse_code%TYPE;  -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL    lv_base_code             xxcmn_sourcing_rules.base_code%TYPE;           -- ���_�R�[�h
--
    -- *** ���[�J�����R�[�h ***
--    l_ifdata_rec           g_ifdata_rtype;  -- �t�@�C���A�b�v���[�hI/F�e�[�u���v�f
--
    -- *** ���[�J��PL/SQL�\ ***
    l_shipment_result_tab    g_shipment_result_ttype;   -- �o�׎��я��
--
    -- *** ���[�J���E���[�U��`��O ***
    submain_expt EXCEPTION;
    no_data_expt EXCEPTION;   -- �����Ώۃf�[�^�Ȃ�
    loop_expt    EXCEPTION;   -- �Ώۃf�[�^�����G���[
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
    BEGIN
      -- ===============================
      -- A-1.��������
      -- ===============================
      init(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-2.�e�R�[�h�o�׎��щߋ��f�[�^�폜
      -- ===============================
      del_shipment_results(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-3.�e�R�[�h�A�o�בq�ɃR�[�h�ŐV��
      -- ===============================
      renew_shipment_results(
        ov_errbuf     => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- ===============================
      -- A-4.�o�׎��я�񒊏o
      -- ===============================
      get_shipment_results(
        o_shipment_result_tab  => l_shipment_result_tab   -- �o�׎��я�񒊏o
       ,ov_errbuf              => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode             => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg              => lv_errmsg);             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE submain_expt;
      END IF;
--
      -- �Ώی������擾
      gn_target_cnt := l_shipment_result_tab.COUNT;
--
      -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�͏������X�L�b�v����
      IF ( gn_target_cnt = 0 ) THEN
        RAISE no_data_expt;
      END IF;
--
      -- ===============================
      -- �o�׎��я��̃��[�v�J�n
      -- ===============================
      <<shipment_results_loop>>
      FOR ln_idx IN l_shipment_result_tab.FIRST..l_shipment_result_tab.LAST LOOP
--
        -- ===============================
        -- A-5.�ŐV�o�בq�Ɏ擾
        -- ===============================
        get_latest_code(
          i_shipment_result_rec  => l_shipment_result_tab( ln_idx )   -- �o�׎��я�񒊏o
         ,ov_delivery_whse_code  => lv_delivery_whse_code             -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL         ,ov_base_code           => lv_base_code                      -- ���_�R�[�h
         ,ov_errbuf              => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode             => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg              => lv_errmsg);                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE loop_expt;
        END IF;
--
--��1.1 2009/02/09 ADD START
        -- �ŐV�o�בq�ɂ��擾�ł��Ȃ��ꍇ�͌��̒l���g�p
        IF ( lv_delivery_whse_code IS NULL ) THEN
          lv_delivery_whse_code := l_shipment_result_tab( ln_idx ).deliver_from;
        END IF;
--
--��1.1 2009/02/09 ADD END
        -- ===============================
        -- A-6.�e�R�[�h�o�׎��уf�[�^���݃`�F�b�N
        -- ===============================
        SELECT COUNT( 'X' ) cnt
        INTO   ln_xsr_count
        FROM   xxcop_shipment_results xsr   -- �e�R�[�h�o�׎��ѕ\�A�h�I��
        WHERE  xsr.order_header_id = l_shipment_result_tab( ln_idx ).order_header_id  -- �󒍃w�b�_�A�h�I��ID
        AND    xsr.order_line_id   = l_shipment_result_tab( ln_idx ).order_line_id    -- �󒍖��׃A�h�I��ID
        ;
--
        -- �e�R�[�h�o�׎��тɃf�[�^�����݂��Ȃ��ꍇ
        IF ( ln_xsr_count = 0 ) THEN
--
          -- ===============================
          -- A-7.�e�R�[�h�o�׎��уf�[�^�쐬
          -- ===============================
          ins_shipment_results(
            i_shipment_result_rec  => l_shipment_result_tab( ln_idx )   -- �o�׎��я�񒊏o
           ,iv_delivery_whse_code  => lv_delivery_whse_code             -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL           ,iv_base_code           => lv_base_code                      -- ���_�R�[�h
           ,ov_errbuf              => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode             => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg              => lv_errmsg);                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE loop_expt;
          END IF;
--
        -- �e�R�[�h�o�׎��тɃf�[�^�����݂��Ȃ��ꍇ
        ELSE
--
          -- ===============================
          -- A-8.�e�R�[�h�o�׎��уf�[�^�X�V
          -- ===============================
          upd_shipment_results(
            i_shipment_result_rec  => l_shipment_result_tab( ln_idx )   -- �o�׎��я�񒊏o
           ,iv_delivery_whse_code  => lv_delivery_whse_code             -- �o�וۊǑq�ɃR�[�h
--��1.1 2009/02/09 DEL           ,iv_base_code           => lv_base_code                      -- ���_�R�[�h
           ,ov_errbuf              => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,ov_retcode             => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
           ,ov_errmsg              => lv_errmsg);                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE loop_expt;
          END IF;
--
        END IF;
--
        -- ���팏�����J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP shipment_results_loop;
--
    EXCEPTION
      WHEN no_data_expt THEN
        NULL;
      WHEN loop_expt THEN
        -- �G���[�������J�E���g
        gn_error_cnt := gn_error_cnt + 1;
        RAISE submain_expt;
    END;
--
    -- ===============================
    -- A-9.�O��N�������X�V
    -- ===============================
    upd_appl_contorols(
      ov_errbuf              => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              => lv_errmsg);                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE submain_expt;
    END IF;
--
    -- ===============================
    -- A-10.�I������/�G���[����
    -- ===============================
    -- main�ɂĎ��{
--
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
    WHEN submain_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf            OUT VARCHAR2,    --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2     --   ���^�[���E�R�[�h    --# �Œ� #
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
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      -- ���팏�����O�ɖ߂�
      gn_normal_cnt := 0;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
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
--    --�X�L�b�v�����o��
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
--    ELSIF(lv_retcode = cv_status_warn) THEN
--      lv_message_code := cv_warn_msg;
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOP004A07C;
/
