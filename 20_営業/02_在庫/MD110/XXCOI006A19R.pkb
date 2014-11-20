CREATE OR REPLACE PACKAGE BODY XXCOI006A19R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A19R(body)
 * Description      : ���o���ו\�i���_�ʌv�j
 * MD.050           : ���o���ו\�i���_�ʌv�j <MD050_XXCOI_006_A19>
 * Version          : V1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  del_svf_data           ���[�N�e�[�u���f�[�^�폜             (A-6)
 *  call_output_svf        SVF�N��                              (A-5)
 *  ins_svf_data           ���[�N�e�[�u���f�[�^�o�^             (A-4)
 *  valid_param_value      �p�����[�^�`�F�b�N                   (A-2)
 *  init                   ��������                             (A-1)
 *  submain                ���C�������v���V�[�W��
 *                         �f�[�^�擾                           (A-3)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/14    1.0   H.Sasaki         ���ō쐬
 *  2009/02/19    1.1   H.Sasaki         [��QCOI_022]�ڋq�}�X�^�̃X�e�[�^�X�����������ɒǉ�
 *                                                    �����݌ɂ̌��������ɒI���X�e�[�^�X��ǉ�
 *  2009/06/26    1.2   H.Sasaki         [0000258]���ʌv�Z�ɒI�����Ր������Z���Ȃ�
 *                                                ���o���v�Ɋ�݌ɕύX���ɂ�ǉ�
 *  2009/07/21    1.3   H.Sasaki         [0000807]VD�o�ɐ��ʂ��A��݌ɕύX���ɐ��ʂ����Z
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOI006A19R'; -- �p�b�P�[�W��
  -- ���b�Z�[�W�֘A
  cv_short_name_xxcoi       CONSTANT VARCHAR2(5)  :=  'XXCOI';                  -- �A�v���P�[�V�����Z�k��
  cv_msg_xxcoi1_00008       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00008';       -- �Ώۃf�[�^�������b�Z�[�W
  cv_msg_xxcoi1_00011       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-00011';       -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10107       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10107';       -- �p�����[�^�󕥔N���l���b�Z�[�W
  cv_msg_xxcoi1_10108       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10108';       -- �p�����[�^�����敪�l���b�Z�[�W
  cv_msg_xxcoi1_10110       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10110';       -- �󕥔N���^�`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10111       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10111';       -- �󕥔N���������`�F�b�N�G���[���b�Z�[�W
  cv_msg_xxcoi1_10114       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10114';       -- �����敪���擾�G���[���b�Z�[�W
  cv_msg_xxcoi1_10119       CONSTANT VARCHAR2(16) :=  'APP-XXCOI1-10119';       -- SVF�N��API�G���[���b�Z�[�W
  cv_token_10107_1          CONSTANT VARCHAR2(30) :=  'P_INVENTORY_MONTH';      -- APP-XXCOI1-10107�p�g�[�N��
  cv_token_10108_1          CONSTANT VARCHAR2(30) :=  'P_COST_TYPE';            -- APP-XXCOI1-10108�p�g�[�N��
  -- �I���敪�i1:����  2:�����j
  cv_inv_kbn_2              CONSTANT VARCHAR2(1)  :=  '2';
  -- �ڋq
  cv_cust_cls_1             CONSTANT VARCHAR2(1)  :=  '1';                      -- �ڋq�敪�i1:���_�j
  cv_status_active          CONSTANT VARCHAR2(1)  :=  'A';                      -- �X�e�[�^�X�FActive
  -- ���t�^
  cv_type_month             CONSTANT VARCHAR2(6)  :=  'YYYYMM';                 -- DATE�^ �N���iYYYYMM�j
  cv_type_date              CONSTANT VARCHAR2(8)  :=  'YYYYMMDD';               -- DATE�^ �N�����iYYYYMMDD�j
  -- LOOKUP_TYPE
  cv_xxcoi_cost_price_div   CONSTANT VARCHAR2(30) :=  'XXCOI1_COST_PRICE_DIV';  -- LOOKUP_TYPE�i�����敪�j
  -- ���̑�
  cv_log                    CONSTANT VARCHAR2(3)  :=  'LOG';                    -- �R���J�����g�w�b�_�o�͐�
  cv_space                  CONSTANT VARCHAR2(1)  :=  ' ';                      -- ���p�X�y�[�X
  -- SVF�N���֐��p�����[�^�p
  cv_conc_name              CONSTANT VARCHAR2(30) :=  'XXCOI006A19R';           -- �R���J�����g��
  cv_type_pdf               CONSTANT VARCHAR2(4)  :=  '.pdf';                   -- �g���q�iPDF�j
  cv_file_id                CONSTANT VARCHAR2(30) :=  'XXCOI006A19R';           -- ���[ID
  cv_output_mode            CONSTANT VARCHAR2(30) :=  '1';                      -- �o�͋敪
  cv_frm_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A19S.xml';       -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(30) :=  'XXCOI006A19S.vrq';       -- �N�G���[�l���t�@�C����
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �N���p�����[�^
  gv_param_reception_date   VARCHAR2(6);                        -- �󕥔N���iYYYYMM�j
  gv_param_cost_type        VARCHAR2(2);                        -- �����敪�i10:�c�ƌ����A20:�W�������j
  -- ���̑�
  gd_f_process_date         DATE;                               -- �Ɩ����t
  gt_cost_type_name         fnd_lookup_values.meaning%TYPE;     -- �����敪��
--
  -- ===============================
  -- ���[�U�[��`�J�[�\��
  -- ===============================
  CURSOR  svf_data_cur
  IS
    SELECT  xirm.base_code                      base_code                 -- ���_�R�[�h
           ,SUBSTRB(hca.account_name, 1, 8)     account_name              -- ���_����
           ,CASE WHEN gv_param_cost_type = '10' THEN  xirm.operation_cost
                 ELSE  xirm.standard_cost
            END                                 cost_amt                  -- ����
           ,xirm.sales_shipped                  sales_shipped             -- ����o��
           ,xirm.sales_shipped_b                sales_shipped_b           -- ����o�ɐU��
           ,xirm.return_goods                   return_goods              -- �ԕi
           ,xirm.return_goods_b                 return_goods_b            -- �ԕi�U��
           ,xirm.change_ship                    change_ship               -- �q�֏o��
           ,xirm.goods_transfer_old             goods_transfer_old        -- ���i�U��(�����i)
           ,xirm.sample_quantity                sample_quantity           -- ���{�o��
           ,xirm.sample_quantity_b              sample_quantity_b         -- ���{�o�ɐU��
           ,xirm.customer_sample_ship           customer_sample_ship      -- �ڋq���{�o��
           ,xirm.customer_sample_ship_b         customer_sample_ship_b    -- �ڋq���{�o�ɐU��
           ,xirm.customer_support_ss            customer_support_ss       -- �ڋq���^���{�o��
           ,xirm.customer_support_ss_b          customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
           ,xirm.ccm_sample_ship                ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
           ,xirm.ccm_sample_ship_b              ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
           ,xirm.inventory_change_out           inventory_change_out      -- ��݌ɕύX�o��
-- == 2009/06/26 V1.2 Added START ===============================================================
           ,xirm.inventory_change_in            inventory_change_in       -- ��݌ɕύX����
-- == 2009/06/26 V1.2 Added END   ===============================================================
           ,xirm.factory_return                 factory_return            -- �H��ԕi
           ,xirm.factory_return_b               factory_return_b          -- �H��ԕi�U��
           ,xirm.factory_change                 factory_change            -- �H��q��
           ,xirm.factory_change_b               factory_change_b          -- �H��q�֐U��
           ,xirm.removed_goods                  removed_goods             -- �p�p
           ,xirm.removed_goods_b                removed_goods_b           -- �p�p�U��
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--           ,xirm.wear_increase                  wear_increase             -- �I�����Ռ�
-- == 2009/06/26 V1.2 Deleted END   ===============================================================
    FROM    xxcoi_inv_reception_monthly         xirm                      -- �����݌Ɏ󕥕\�i�����j
           ,hz_cust_accounts                    hca                       -- �ڋq�}�X�^
    WHERE   xirm.practice_month     =   gv_param_reception_date
    AND     xirm.inventory_kbn      =   cv_inv_kbn_2
    AND     xirm.base_code          =   hca.account_number
    AND     hca.customer_class_code =   cv_cust_cls_1
    AND     hca.status              =   cv_status_active
    ORDER BY  xirm.base_code;
  --
  svf_data_rec    svf_data_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : del_svf_data
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-6)
   ***********************************************************************************/
  PROCEDURE del_svf_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_svf_data'; -- �v���O������
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
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    -- ===============================
    --  1.���[�N�e�[�u���폜
    -- ===============================
    DELETE  FROM xxcoi_rep_base_expend
    WHERE   request_id  = cn_request_id;
    --
  EXCEPTION
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
  END del_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : call_output_svf
   * Description      : SVF�N��(A-5)
   ***********************************************************************************/
  PROCEDURE call_output_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_output_svf'; -- �v���O������
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
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    -- ===============================
    --  1.SVF�N��
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
       iv_conc_name         =>  cv_conc_name            -- �R���J�����g��
      ,iv_file_name         =>  cv_file_id || TO_CHAR(SYSDATE, cv_type_date) || TO_CHAR(cn_request_id) || cv_type_pdf       -- �o�̓t�@�C����
      ,iv_file_id           =>  cv_file_id              -- ���[ID
      ,iv_output_mode       =>  cv_output_mode          -- �o�͋敪
      ,iv_frm_file          =>  cv_frm_file             -- �t�H�[���l���t�@�C����
      ,iv_vrq_file          =>  cv_vrq_file             -- �N�G���[�l���t�@�C����
      ,iv_org_id            =>  fnd_global.org_id       -- ORG_ID
      ,iv_user_name         =>  fnd_global.user_name    -- ���O�C���E���[�U��
      ,iv_resp_name         =>  fnd_global.resp_name    -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name          =>  NULL                    -- ������
      ,iv_printer_name      =>  NULL                    -- �v�����^��
      ,iv_request_id        =>  cn_request_id           -- �v��ID
      ,iv_nodata_msg        =>  NULL                    -- �f�[�^�Ȃ����b�Z�[�W
      ,ov_retcode           =>  lv_retcode              -- ���^�[���R�[�h
      ,ov_errbuf            =>  lv_errbuf               -- �G���[���b�Z�[�W
      ,ov_errmsg            =>  lv_errmsg               -- ���[�U�[�E�G���[���b�Z�[�W
    );
    -- �I���p�����[�^����
    IF (lv_retcode  <>  cv_status_normal) THEN
      -- SVF�N��API�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10119
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF; 
--
  EXCEPTION
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
  END call_output_svf;
--
  /**********************************************************************************
   * Procedure Name   : ins_svf_data
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE ins_svf_data(
    ir_svf_data   IN  svf_data_cur%ROWTYPE,   -- 1.CSV�o�͑Ώۃf�[�^
    in_slit_id    IN  NUMBER,                 -- 2.�����A��
    iv_message    IN  VARCHAR2,               -- 3.�O�����b�Z�[�W
    ov_errbuf     OUT VARCHAR2,               --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,               --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)               --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_svf_data'; -- �v���O������
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
    lv_base_code              VARCHAR2(4);    -- ���_�R�[�h
    lv_base_name              VARCHAR2(8);    -- ���_����
    ln_sales_ship_qty         NUMBER;         -- ����o�ɐ���
    ln_sales_ship_money       NUMBER;         -- ����o�ɋ��z
    ln_vd_ship_qty            NUMBER;         -- VD�o�ɐ���
    ln_vd_ship_money          NUMBER;         -- VD�o�ɋ��z
    ln_support_qty            NUMBER;         -- ���^���{����
    ln_support_money          NUMBER;         -- ���^���{���z
    ln_sample_qty             NUMBER;         -- ���{�o�ɐ���
    ln_sample_money           NUMBER;         -- ���{�o�ɋ��z
    ln_disposal_qty           NUMBER;         -- �p�p�o�ɐ���
    ln_disposal_money         NUMBER;         -- �p�p�o�ɋ��z
    ln_kuragae_ship_qty       NUMBER;         -- �q�֏o�ɐ���
    ln_kuragae_ship_money     NUMBER;         -- �q�֏o�ɋ��z
    ln_hurikae_ship_qty       NUMBER;         -- �U�֏o�ɐ���
    ln_hurikae_ship_money     NUMBER;         -- �U�֏o�ɋ��z
    ln_factry_change_qty      NUMBER;         -- �H��q�֐���
    ln_factry_change_money    NUMBER;         -- �H��q�֋��z
    ln_factry_return_qty      NUMBER;         -- �H��ԕi����
    ln_factry_return_money    NUMBER;         -- �H��ԕi���z
    ln_payment_total_qty      NUMBER;         -- ���o���v����
    ln_payment_total_money    NUMBER;         -- ���o���v���z
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    -- ===============================
    --  1.���[�N�e�[�u���쐬
    -- ===============================
    -- �f�[�^�ݒ�
    IF (iv_message IS NOT NULL) THEN
      lv_base_code              :=  NULL;     -- 05.���_�R�[�h
      lv_base_name              :=  NULL;     -- 06.���_����
      ln_sales_ship_qty         :=  NULL;     -- 07.����o�ɐ���
      ln_sales_ship_money       :=  NULL;     -- 08.����o�ɋ��z
      ln_vd_ship_qty            :=  NULL;     -- 09.VD�o�ɐ���
      ln_vd_ship_money          :=  NULL;     -- 10.VD�o�ɋ��z
      ln_support_qty            :=  NULL;     -- 11.���^���{����
      ln_support_money          :=  NULL;     -- 12.���^���{���z
      ln_sample_qty             :=  NULL;     -- 13.���{�o�ɐ���
      ln_sample_money           :=  NULL;     -- 14.���{�o�ɋ��z
      ln_disposal_qty           :=  NULL;     -- 15.�p�p�o�ɐ���
      ln_disposal_money         :=  NULL;     -- 16.�p�p�o�ɋ��z
      ln_kuragae_ship_qty       :=  NULL;     -- 17.�q�֏o�ɐ���
      ln_kuragae_ship_money     :=  NULL;     -- 18.�q�֏o�ɋ��z
      ln_hurikae_ship_qty       :=  NULL;     -- 19.�U�֏o�ɐ���
      ln_hurikae_ship_money     :=  NULL;     -- 20.�U�֏o�ɋ��z
      ln_factry_change_qty      :=  NULL;     -- 21.�H��q�֐���
      ln_factry_change_money    :=  NULL;     -- 22.�H��q�֋��z
      ln_factry_return_qty      :=  NULL;     -- 23.�H��ԕi����
      ln_factry_return_money    :=  NULL;     -- 24.�H��ԕi���z
      ln_payment_total_qty      :=  NULL;     -- 25.���o���v����
      ln_payment_total_money    :=  NULL;     -- 26.���o���v���z
      --
    ELSE
      lv_base_code              :=   ir_svf_data.base_code;                               -- 05.���_�R�[�h
      lv_base_name              :=   ir_svf_data.account_name;                            -- 06.���_����
      ln_sales_ship_qty         :=   ir_svf_data.sales_shipped
                                   - ir_svf_data.sales_shipped_b
                                   - ir_svf_data.return_goods
                                   + ir_svf_data.return_goods_b;                          -- 07.����o�ɐ���
      ln_sales_ship_money       :=  ROUND(ir_svf_data.cost_amt * ln_sales_ship_qty);      -- 08.����o�ɋ��z
-- == 2009/07/21 V1.3 Modified START ===============================================================
--      ln_vd_ship_qty            :=   ir_svf_data.inventory_change_out;
      ln_vd_ship_qty            :=   ir_svf_data.inventory_change_out
                                   - ir_svf_data.inventory_change_in;                     -- 09.VD�o�ɐ���
-- == 2009/07/21 V1.3 Modified END   ===============================================================
      ln_vd_ship_money          :=  ROUND(ir_svf_data.cost_amt * ln_vd_ship_qty);         -- 10.VD�o�ɋ��z
      ln_support_qty            :=   ir_svf_data.customer_support_ss
                                   - ir_svf_data.customer_support_ss_b
                                   + ir_svf_data.ccm_sample_ship
                                   - ir_svf_data.ccm_sample_ship_b;                       -- 11.���^���{����
      ln_support_money          :=  ROUND(ir_svf_data.cost_amt * ln_support_qty);         -- 12.���^���{���z
      ln_sample_qty             :=   ir_svf_data.customer_sample_ship
                                   - ir_svf_data.customer_sample_ship_b
                                   + ir_svf_data.sample_quantity
                                   - ir_svf_data.sample_quantity_b;                       -- 13.���{�o�ɐ���
      ln_sample_money           :=  ROUND(ir_svf_data.cost_amt * ln_sample_qty);          -- 14.���{�o�ɋ��z
      ln_disposal_qty           :=   ir_svf_data.removed_goods
                                   - ir_svf_data.removed_goods_b;                         -- 15.�p�p�o�ɐ���
      ln_disposal_money         :=  ROUND(ir_svf_data.cost_amt * ln_disposal_qty);        -- 16.�p�p�o�ɋ��z
-- == 2009/06/26 V1.2 Modified START ===============================================================
--      ln_kuragae_ship_qty       :=   ir_svf_data.change_ship + ir_svf_data.wear_increase; -- 17.�q�֏o�ɐ���
      ln_kuragae_ship_qty       :=   ir_svf_data.change_ship;                             -- 17.�q�֏o�ɐ���
-- == 2009/06/26 V1.2 Modified END ===============================================================
      ln_kuragae_ship_money     :=  ROUND(ir_svf_data.cost_amt * ln_kuragae_ship_qty);    -- 18.�q�֏o�ɋ��z
      ln_hurikae_ship_qty       :=   ir_svf_data.goods_transfer_old;                      -- 19.�U�֏o�ɐ���
      ln_hurikae_ship_money     :=  ROUND(ir_svf_data.cost_amt * ln_hurikae_ship_qty);    -- 20.�U�֏o�ɋ��z
      ln_factry_change_qty      :=   ir_svf_data.factory_change
                                   - ir_svf_data.factory_change_b;                        -- 21.�H��q�֐���
      ln_factry_change_money    :=  ROUND(ir_svf_data.cost_amt * ln_factry_change_qty);   -- 22.�H��q�֋��z
      ln_factry_return_qty      :=   ir_svf_data.factory_return
                                   - ir_svf_data.factory_return_b;                        -- 23.�H��ԕi����
      ln_factry_return_money    :=  ROUND(ir_svf_data.cost_amt * ln_factry_return_qty);   -- 24.�H��ԕi���z
      ln_payment_total_qty      :=   ir_svf_data.sales_shipped
                                   - ir_svf_data.sales_shipped_b
                                   - ir_svf_data.return_goods
                                   + ir_svf_data.return_goods_b
                                   + ir_svf_data.change_ship
-- == 2009/06/26 V1.2 Deleted START ===============================================================
--                                   + ir_svf_data.wear_increase
-- == 2009/06/26 V1.2 Deleted START ===============================================================
                                   + ir_svf_data.goods_transfer_old
                                   + ir_svf_data.sample_quantity
                                   - ir_svf_data.sample_quantity_b
                                   + ir_svf_data.customer_sample_ship
                                   - ir_svf_data.customer_sample_ship_b
                                   + ir_svf_data.customer_support_ss
                                   - ir_svf_data.customer_support_ss_b
                                   + ir_svf_data.ccm_sample_ship
                                   - ir_svf_data.ccm_sample_ship_b
                                   + ir_svf_data.inventory_change_out
-- == 2009/06/26 V1.2 Added START ===============================================================
                                   - ir_svf_data.inventory_change_in
-- == 2009/06/26 V1.2 Added END   ===============================================================
                                   + ir_svf_data.factory_return
                                   - ir_svf_data.factory_return_b
                                   + ir_svf_data.factory_change
                                   - ir_svf_data.factory_change_b
                                   + ir_svf_data.removed_goods
                                   - ir_svf_data.removed_goods_b;                         -- 25.���o���v����
      ln_payment_total_money    :=  ROUND(ir_svf_data.cost_amt * ln_payment_total_qty);   -- 26.���o���v���z
    END IF;
    --
    -- �}������
    INSERT INTO xxcoi_rep_base_expend(
       slit_id                                  -- 01.���o�c�����ID
      ,in_out_year                              -- 02.�N
      ,in_out_month                             -- 03.��
      ,cost_kbn                                 -- 04.�����敪
      ,base_code                                -- 05.���_�R�[�h
      ,base_name                                -- 06.���_����
      ,sales_ship_qty                           -- 07.����o�ɐ���
      ,sales_ship_money                         -- 08.����o�ɋ��z
      ,vd_ship_qty                              -- 09.VD�o�ɐ���
      ,vd_ship_money                            -- 10.VD�o�ɋ��z
      ,support_qty                              -- 11.���^���{����
      ,support_money                            -- 12.���^���{���z
      ,sample_qty                               -- 13.���{�o�ɐ���
      ,sample_money                             -- 14.���{�o�ɋ��z
      ,disposal_qty                             -- 15.�p�p�o�ɐ���
      ,disposal_money                           -- 16.�p�p�o�ɋ��z
      ,kuragae_ship_qty                         -- 17.�q�֏o�ɐ���
      ,kuragae_ship_money                       -- 18.�q�֏o�ɋ��z
      ,hurikae_ship_qty                         -- 19.�U�֏o�ɐ���
      ,hurikae_ship_money                       -- 20.�U�֏o�ɋ��z
      ,factry_change_qty                        -- 21.�H��q�֐���
      ,factry_change_money                      -- 22.�H��q�֋��z
      ,factry_return_qty                        -- 23.�H��ԕi����
      ,factry_return_money                      -- 24.�H��ԕi���z
      ,payment_total_qty                        -- 25.���o���v����
      ,payment_total_money                      -- 26.���o���v���z
      ,message                                  -- 27.���b�Z�[�W
      ,created_by                               -- 28.�쐬��
      ,creation_date                            -- 29.�쐬��
      ,last_updated_by                          -- 30.�ŏI�X�V��
      ,last_update_date                         -- 31.�ŏI�X�V��
      ,last_update_login                        -- 32.�ŏI�X�V���[�U
      ,request_id                               -- 33.�v��ID
      ,program_application_id                   -- 34.�v���O�����A�v���P�[�V����ID
      ,program_id                               -- 35.�v���O����ID
      ,program_update_date                      -- 36.�v���O�����X�V��
    )VALUES(
       in_slit_id                               -- 01
      ,SUBSTRB(gv_param_reception_date, 3, 2)   -- 02
      ,SUBSTRB(gv_param_reception_date, 5, 2)   -- 03
      ,gt_cost_type_name                        -- 04
      ,lv_base_code                             -- 05
      ,lv_base_name                             -- 06
      ,ln_sales_ship_qty                        -- 07
      ,ln_sales_ship_money                      -- 08
      ,ln_vd_ship_qty                           -- 09
      ,ln_vd_ship_money                         -- 10
      ,ln_support_qty                           -- 11
      ,ln_support_money                         -- 12
      ,ln_sample_qty                            -- 13
      ,ln_sample_money                          -- 14
      ,ln_disposal_qty                          -- 15
      ,ln_disposal_money                        -- 16
      ,ln_kuragae_ship_qty                      -- 17
      ,ln_kuragae_ship_money                    -- 18
      ,ln_hurikae_ship_qty                      -- 19
      ,ln_hurikae_ship_money                    -- 20
      ,ln_factry_change_qty                     -- 21
      ,ln_factry_change_money                   -- 22
      ,ln_factry_return_qty                     -- 23
      ,ln_factry_return_money                   -- 24
      ,ln_payment_total_qty                     -- 25
      ,ln_payment_total_money                   -- 26
      ,iv_message                               -- 27
      ,cn_created_by                            -- 28
      ,SYSDATE                                  -- 29
      ,cn_last_updated_by                       -- 30
      ,SYSDATE                                  -- 31
      ,cn_last_update_login                     -- 32
      ,cn_request_id                            -- 33
      ,cn_program_application_id                -- 34
      ,cn_program_id                            -- 35
      ,SYSDATE                                  -- 36
    );
--
  EXCEPTION
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
  END ins_svf_data;
--
  /**********************************************************************************
   * Procedure Name   : valid_param_value
   * Description      : �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE valid_param_value(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'valid_param_value'; -- �v���O������
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
    ld_dummy    DATE;       -- �_�~�[�ϐ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
    -- <�J�[�\����>���R�[�h�^
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
--
    -- ===============================
    --  1.�󕥔N���`�F�b�N
    -- ===============================
    BEGIN
      ld_dummy  :=  TO_DATE(gv_param_reception_date, cv_type_month);
    EXCEPTION
      WHEN OTHERS THEN
        -- �󕥔N���^�`�F�b�N�G���[���b�Z�[�W
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => cv_short_name_xxcoi
                        ,iv_name         => cv_msg_xxcoi1_10110
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_process_expt;
    END;
    --
    IF (TO_CHAR(gd_f_process_date, 'YYYYMM') <= gv_param_reception_date) THEN
      -- �󕥔N���������`�F�b�N�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10111
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
   --
  EXCEPTION
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
  END valid_param_value;
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
    -- ===============================
    --  ������
    -- ===============================
    ov_retcode          :=  cv_status_normal;     -- �I���p�����[�^
    gd_f_process_date   :=  NULL;                 -- �Ɩ����t
    gt_cost_type_name   :=  NULL;                 -- �����敪��
    --
    -- ===============================
    --  1.�Ɩ����t�擾
    -- ===============================
    gd_f_process_date   :=  xxccp_common_pkg2.get_process_date;
    --
    IF  (gd_f_process_date  IS NULL) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_00011
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  2.WHO�J�����ݒ�
    -- ===============================
    -- �O���[�o���萔�Ƃ��āA�錾���Őݒ肵�Ă��܂��B
    --
    -- ===============================
    --  3.�����敪���擾
    -- ===============================
    gt_cost_type_name   :=  xxcoi_common_pkg.get_meaning(cv_xxcoi_cost_price_div, gv_param_cost_type);
    --
    IF  (gt_cost_type_name  IS NULL) THEN
      -- �����敪���擾�G���[���b�Z�[�W
      lv_errmsg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_short_name_xxcoi
                      ,iv_name         => cv_msg_xxcoi1_10114
                     );
      lv_errbuf   := lv_errmsg;
      --
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  4.�N���p�����[�^���O�o��
    -- ===============================
    -- �󕥔N��
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10107
                    ,iv_token_name1  => cv_token_10107_1
                    ,iv_token_value1 => gv_param_reception_date
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- �����敪
    gv_out_msg   := xxccp_common_pkg.get_msg(
                     iv_application  => cv_short_name_xxcoi
                    ,iv_name         => cv_msg_xxcoi1_10108
                    ,iv_token_name1  => cv_token_10108_1
                    ,iv_token_value1 => gt_cost_type_name
                   );
    --
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
    );
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_reception_date IN  VARCHAR2,     -- 1.�󕥔N��
    iv_cost_type      IN  VARCHAR2,     -- 2.�����敪
    ov_errbuf         OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_zero_message     VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
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
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    --  ������
    -- ===============================
    -- ���̓p�����[�^
    gv_param_reception_date   :=  iv_reception_date;    -- �󕥔N��
    gv_param_cost_type        :=  iv_cost_type;         -- �����敪
    --
    lv_zero_message   :=  NULL;
    --
    -- ===============================
    --  A-1.��������
    -- ===============================
    init(
       ov_errbuf    =>  lv_errbuf     --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode    --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-2.�p�����[�^�`�F�b�N
    -- ===============================
    valid_param_value(
       ov_errbuf    =>  lv_errbuf     --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode    --   ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    --
    -- ===============================
    --  A-3.�f�[�^�擾�i�J�[�\���j
    -- ===============================
    OPEN  svf_data_cur;
    FETCH svf_data_cur  INTO  svf_data_rec;
    --
    IF (svf_data_cur%NOTFOUND) THEN
      -- �o�͑Ώۃf�[�^�O��
      lv_zero_message := xxccp_common_pkg.get_msg(
                           iv_application  => cv_short_name_xxcoi
                          ,iv_name         => cv_msg_xxcoi1_00008
                         );
      --
    END IF;
    --
    <<work_ins_loop>>
    LOOP
      -- �Ώی����J�E���g
      gn_target_cnt :=  gn_target_cnt + 1;
      --
      -- ===============================
      --  A-4.���[�N�e�[�u���f�[�^�o�^
      -- ===============================
      ins_svf_data(
         ir_svf_data  =>  svf_data_rec    -- CSV�o�͗p�f�[�^
        ,in_slit_id   =>  gn_target_cnt   -- �����A��
        ,iv_message   =>  lv_zero_message -- �O�����b�Z�[�W
        ,ov_errbuf    =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,ov_retcode   =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg    =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- �I���p�����[�^����
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[����
        RAISE global_process_expt;
      END IF;
      --
      EXIT  work_ins_loop WHEN  lv_zero_message IS NOT NULL;
      FETCH svf_data_cur  INTO  svf_data_rec;
      EXIT  work_ins_loop WHEN  svf_data_cur%NOTFOUND;
      --
    END LOOP work_ins_loop;
    --
    CLOSE svf_data_cur;
    -- �R�~�b�g����
    COMMIT;
    --
    -- ===============================
    --  A-5.SVF�N��
    -- ===============================
    call_output_svf(
       ov_errbuf    =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    -- ===============================
    --  A-6.���[�N�e�[�u���f�[�^�폜
    -- ===============================
    del_svf_data(
       ov_errbuf    =>  lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode   =>  lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg    =>  lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
    --
    -- ����I������
    IF (lv_zero_message IS NOT NULL) THEN
      gn_target_cnt :=  0;
    ELSE
      gn_normal_cnt := gn_target_cnt - gn_warn_cnt;
    END IF;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- ��������
      gn_error_cnt  :=  gn_error_cnt + 1;
      IF (svf_data_cur%ISOPEN) THEN
        CLOSE svf_data_cur;
      END IF;
      --
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
    errbuf            OUT VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_reception_date IN  VARCHAR2,      -- 1.�󕥔N��
    iv_cost_type      IN  VARCHAR2       -- 2.�����敪
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
       iv_which   =>  cv_log
      ,ov_retcode =>  lv_retcode
      ,ov_errbuf  =>  lv_errbuf
      ,ov_errmsg  =>  lv_errmsg
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
       iv_reception_date  =>  iv_reception_date   -- 1.�󕥔N��
      ,iv_cost_type       =>  iv_cost_type        -- 2.�����敪
      ,ov_errbuf          =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          =>  lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_errbuf <> cv_status_normal) THEN
      --�G���[�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      -- ��s�o��
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_space
      );
    END IF;
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_space
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
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
END XXCOI006A19R;
/
