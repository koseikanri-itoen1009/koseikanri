create or replace
PACKAGE BODY xxpo940003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940003c(body)
 * Description      : ���b�g�݌ɏ�񒊏o����
 * MD.050           : ���Y��������                  T_MD050_BPO_940
 * MD.070           : ���b�g�݌ɏ�񒊏o����        T_MD070_BPO_94C
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  parameter_disp         �p�����[�^�̏o��
 *  get_inv_stock_vol      �莝�݌ɐ��擾
 *  get_supply_stock_plan  ���ɗ\�萔�擾
 *  get_lot_inf_proc       ���b�g�݌ɏ��擾����           (C-1)
 *  csv_file_proc          CSV�t�@�C���o��                  (C-2)
 *  workflow_start         ���[�N�t���[�ʒm����             (C-3)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/18    1.0   Oracle �勴 �F�Y ����쐬
 *  2008/08/01    1.1   Oracle �g�c �Ď� ST�s��Ή�
 *  2008/08/04    1.2   Oracle �g�c �Ď� PT�Ή�
 *  2008/08/19    1.3   Oracle �R�� ��_ �d�l�s���E�w�E15
 *  2008/09/17    1.4   Oracle �勴 �F�Y T_S_460�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
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
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxpo940003c'; -- �p�b�P�[�W��
  gv_app_name      CONSTANT VARCHAR2(5)   := 'XXPO';        -- �A�v���P�[�V�����Z�k��
  gv_com_name      CONSTANT VARCHAR2(5)   := 'XXCMN';       -- �A�v���P�[�V�����Z�k��
--
  -- �f�[�^���
  gv_data_class    CONSTANT VARCHAR2(3) := '510';
--
  -- �`���p�}��
  gv_transmission_no CONSTANT VARCHAR2(2) := '00';
--
  gv_sec_class_home CONSTANT VARCHAR2(1) := '1';   -- �ɓ������[�U�[�^�C�v
  gv_sec_class_vend CONSTANT VARCHAR2(1) := '2';   -- ����惆�[�U�[�^�C�v
  gv_sec_class_extn CONSTANT VARCHAR2(1) := '3';   -- �O���q�Ƀ��[�U�[�^�C�v
  gv_sec_class_quay CONSTANT VARCHAR2(1) := '4';   -- ���m�u�����[�U�[�^�C�v
--
  gv_company_name   CONSTANT VARCHAR2(10) := 'ITOEN';
--
  -- �g�[�N��
  gv_tkn_xxpo_10026       CONSTANT VARCHAR2(15) := 'APP-XXPO-10026';  -- �f�[�^���擾���b�Z�[�W
  gv_tkn_xxpo_30022       CONSTANT VARCHAR2(15) := 'APP-XXPO-30022';  -- �p�����[�^���
  gv_tkn_xxcmn_10113      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10113'; -- �t�@�C���p�X�s���װ
  gv_tkn_xxcmn_10114      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10114'; -- �t�@�C�����s���װ
  gv_tkn_xxcmn_10115      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10115'; -- �t�@�C���A�N�Z�X�����װ
  gv_tkn_xxcmn_10119      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10119'; -- �t�@�C���p�XNULL�װ
  gv_tkn_xxcmn_10120      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10120'; -- �t�@�C����NULL�װ
  gv_tkn_xxcmn_10117      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10117'; -- Workflow�N���װ
--
  gv_tkn_name             CONSTANT VARCHAR2(15) := 'NAME';
  gv_tkn_param_name       CONSTANT VARCHAR2(15) := 'PARAM_NAME';
  gv_tkn_param_value      CONSTANT VARCHAR2(15) := 'PARAM_VALUE';
  gv_tkn_error_param      CONSTANT VARCHAR2(15) := 'ERROR_PARAM';
  gv_tkn_error_value      CONSTANT VARCHAR2(15) := 'ERROR_VALUE';
  gv_tkn_param            CONSTANT VARCHAR2(15) := 'PARAM';
  gv_tkn_data             CONSTANT VARCHAR2(15) := 'DATA';
  gv_tkn_table            CONSTANT VARCHAR2(15) := 'TABLE';
--
  gv_sep_com         CONSTANT VARCHAR2(1)  := ',';
  gv_lot_code0       CONSTANT VARCHAR2(1)  := '0';                 -- �񃍃b�g�Ǘ��敪�R�[�h
  gv_lot_code1       CONSTANT VARCHAR2(1)  := '1';                 -- ���b�g�Ǘ��敪�R�[�h
  gv_date_format     CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***************************************
  -- ***    �擾���i�[���R�[�h�^��`   ***
  -- ***************************************
--
  TYPE masters_rec IS RECORD(
    segment1              VARCHAR2(40),  -- �ۊǑq�ɃR�[�h
    inventory_location_id NUMBER,        -- �ۊǑq��ID
    loct_onhand           NUMBER,        -- �莝����
    vendor_code           VARCHAR2(240), -- �����(DFF8)
    vendor_full_name      VARCHAR2(60),  -- ������(�d����)
    vendor_short_name     VARCHAR2(20),  -- ����(�d����)
    item_id               VARCHAR2(7),   -- �i��ID
    item_no               VARCHAR2(10),  -- �i�ڃR�[�h
    item_name             VARCHAR2(40),  -- �i���E������
    item_short_name       VARCHAR2(20),  -- �i���E����
    lot_id                VARCHAR2(10),  -- ���b�gID
    lot_no                VARCHAR2(10),  -- ���b�gNo
    product_date          VARCHAR2(10),  -- �����N����(DFF1)
    use_by_date           VARCHAR2(240), -- �ܖ�����(DFF3)
    original_char         VARCHAR2(240), -- �ŗL�L��(DFF2)
    manu_factory          VARCHAR2(240), -- �����H��(DFF20)
    manu_lot              VARCHAR2(240), -- �������b�g(DFF21)
    home                  VARCHAR2(240), -- �Y�n(DFF12)
    rank1                 VARCHAR2(240), -- �����N1(DFF14)
    rank2                 VARCHAR2(240), -- �����N2(DFF15)
    description           VARCHAR2(240), -- �E�v(DFF18)
    qt_inspect_req_no     VARCHAR2(240), -- �����˗��ԍ�(DFF22)
    inspect_due_date1     VARCHAR2(10),  -- �����\���1
    test_date1            VARCHAR2(10),  -- ������1
    qt_effect1            VARCHAR2(10),  -- ����1
    inspect_due_date2     VARCHAR2(10),  -- �����\���2
    test_date2            VARCHAR2(10),  -- ������2
    qt_effect2            VARCHAR2(10),  -- ����2
    inspect_due_date3     VARCHAR2(10),  -- �����\���3
    test_date3            VARCHAR2(10),  -- ������3
    qt_effect3            VARCHAR2(10)   -- ����3
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl  IS TABLE OF masters_rec  INDEX BY PLS_INTEGER;
--
  -- ***************************************
  -- ***      �o�^�p���ڃe�[�u���^       ***
  -- ***************************************
--
  gt_master_tbl                masters_tbl;     -- �e�}�X�^�֓o�^����f�[�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_wf_ope_div               VARCHAR2(150); --  1.�����敪          (�K�{)
  gv_wf_class                 VARCHAR2(150); --  2.�Ώ�              (�K�{)
  gv_wf_notification          VARCHAR2(150); --  3.����              (�K�{)
  gv_prod_class               VARCHAR2(20);  --  4.���i�敪          (�K�{)
  gv_item_class               VARCHAR2(20);  --  5.�i�ڋ敪          (�K�{)
  gv_frequent_whse_div        VARCHAR2(20);  --  6.��\�q�ɋ敪      (�C��)
  gv_whse                     VARCHAR2(20);  --  7.�q��              (�C��)
  gv_vendor_id                VARCHAR2(20);  --  8.�����            (�C��)
  gv_item_no                  VARCHAR2(20);  --  9.�i��              (�C��)
  gv_lot_no                   VARCHAR2(20);  --  10.���b�g           (�C��)
  gv_manufacture_date         VARCHAR2(10);  --  11.������           (�C��)
  gv_expiration_date          VARCHAR2(10);  --  12.�ܖ�����         (�C��)
  gv_uniqe_sign               VARCHAR2(20);  --  13.�ŗL�L��         (�C��)
  gv_mf_factory               VARCHAR2(20);  --  14.�����H��         (�C��)
  gv_mf_lot                   VARCHAR2(20);  --  15.�������b�g       (�C��)
  gv_home                     VARCHAR2(20);  --  16.�Y�n             (�C��)
  gv_r1                       VARCHAR2(20);  --  17.R1               (�C��)
  gv_r2                       VARCHAR2(20);  --  18.R2               (�C��)
  gv_sec_class                VARCHAR2(20);  --  19.�Z�L�����e�B�敪  (�K�{)
--
  gd_manufacture_date         DATE;          -- ������
  gd_expiration_date          DATE;          -- �ܖ�����
--
  gv_sch_file_name            VARCHAR2(2000);          -- �Ώۃt�@�C����
--
  gn_user_id                  NUMBER;                  -- ���[�UID
  gd_sys_date                 DATE;                    -- �������t
--
--
  gr_outbound_rec             xxcmn_common_pkg.outbound_rec; -- outbound�֘A�f�[�^
--
  /**********************************************************************************
   * Procedure Name   : parameter_disp
   * Description      : �p�����[�^�̏o��
   ***********************************************************************************/
  PROCEDURE parameter_disp(
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_prod_class        IN            VARCHAR2,  --  4.���i�敪          (�K�{)
    iv_item_class        IN            VARCHAR2,  --  5.�i�ڋ敪          (�K�{)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.��\�q�ɋ敪      (�C��)
    iv_whse              IN            VARCHAR2,  --  7.�q��              (�C��)
    iv_vendor_id         IN            VARCHAR2,  --  8.�����            (�C��)
    iv_item_no           IN            VARCHAR2,  --  9.�i��              (�C��)
    iv_lot_no            IN            VARCHAR2,  -- 10.���b�g            (�C��)
    iv_manufacture_date  IN            VARCHAR2,  -- 11.������            (�C��)
    iv_expiration_date   IN            VARCHAR2,  -- 12.�ܖ�����          (�C��)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.�ŗL�L��          (�C��)
    iv_mf_factory        IN            VARCHAR2,  -- 14.�����H��          (�C��)
    iv_mf_lot            IN            VARCHAR2,  -- 15.�������b�g        (�C��)
    iv_home              IN            VARCHAR2,  -- 16.�Y�n              (�C��)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (�C��)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (�C��)
    iv_sec_class         IN            VARCHAR2,  -- 19.�Z�L�����e�B�敪  (�K�{)
    ov_errbuf            OUT NOCOPY    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY    VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'parameter_disp';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_wf_ope_div_n           CONSTANT VARCHAR2(100) := '�����敪';
    lv_wf_class_n             CONSTANT VARCHAR2(100) := '�Ώ�';
    lv_wf_notification_n      CONSTANT VARCHAR2(100) := '����';
    lv_prod_class_n           CONSTANT VARCHAR2(100) := '���i�敪';
    lv_item_class_n           CONSTANT VARCHAR2(100) := '�i�ڋ敪';
    lv_frequent_whse_div_n    CONSTANT VARCHAR2(100) := '��\�q�ɋ敪';
    lv_whse_n                 CONSTANT VARCHAR2(100) := '�q��';
    lv_vendor_id_n            CONSTANT VARCHAR2(100) := '�����';
    lv_item_no_n              CONSTANT VARCHAR2(100) := '�i��';
    lv_lot_no_n               CONSTANT VARCHAR2(100) := '���b�g';
    lv_manufacture_date_n     CONSTANT VARCHAR2(100) := '������';
    lv_expiration_date_n      CONSTANT VARCHAR2(100) := '�ܖ�����';
    lv_uniqe_sign_n           CONSTANT VARCHAR2(100) := '�ŗL�L��';
    lv_mf_factory_n           CONSTANT VARCHAR2(100) := '�����H��';
    lv_mf_lot_n               CONSTANT VARCHAR2(100) := '�������b�g';
    lv_home_n                 CONSTANT VARCHAR2(100) := '�Y�n';
    lv_r1_n                   CONSTANT VARCHAR2(100) := 'R1';
    lv_r2_n                   CONSTANT VARCHAR2(100) := 'R2';
    lv_sec_class_n            CONSTANT VARCHAR2(100) := '�Z�L�����e�B�敪';
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
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �p�����[�^���O���[�o���ϐ��֊i�[
    gv_wf_ope_div        := iv_wf_ope_div;        --  1.�����敪
    gv_wf_class          := iv_wf_class;          --  2.�Ώ�
    gv_wf_notification   := iv_wf_notification;   --  3.����
    gv_prod_class        := iv_prod_class;        --  4.���i�敪
    gv_item_class        := iv_item_class;        --  5.�i�ڋ敪
    gv_frequent_whse_div := iv_frequent_whse_div; --  6.��\�q�ɋ敪
    gv_whse              := iv_whse;              --  7.�q��
    gv_vendor_id         := iv_vendor_id;         --  8.�����
    gv_item_no           := iv_item_no;           --  9.�i��
    gv_lot_no            := iv_lot_no;            -- 10.���b�g
    gv_manufacture_date  := iv_manufacture_date;  -- 11.������
    gv_expiration_date   := iv_expiration_date;   -- 12.�ܖ�����
    gv_uniqe_sign        := iv_uniqe_sign;        -- 13.�ŗL�L��
    gv_mf_factory        := iv_mf_factory;        -- 14.�����H��
    gv_mf_lot            := iv_mf_lot;            -- 15.�������b�g
    gv_home              := iv_home;              -- 16.�Y�n
    gv_r1                := iv_r1;                -- 17.R1
    gv_r2                := iv_r2;                -- 18.R2
    gv_sec_class         := iv_sec_class;         -- 19.�Z�L�����e�B�敪
--
    -- ����������t�^�֕ύX
    gd_manufacture_date := FND_DATE.STRING_TO_DATE(gv_manufacture_date,'YYYY/MM/DD');
--
    -- �ܖ���������t�^�֕ύX
    gd_expiration_date  := FND_DATE.STRING_TO_DATE(gv_expiration_date,'YYYY/MM/DD');
--
    -- WF�Ɋ֘A��������擾
    xxcmn_common_pkg.get_outbound_info(
      gv_wf_ope_div,               -- �����敪
      gv_wf_class,                 -- �Ώ�
      gv_wf_notification,          -- ����
      gr_outbound_rec,             -- outbound�֘A�f�[�^
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �p�����[�^�o��
    -- �����敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_wf_ope_div_n,
                                          gv_tkn_data,
                                          gv_wf_ope_div);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �Ώ�
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_wf_class_n,
                                          gv_tkn_data,
                                          gv_wf_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_wf_notification_n,
                                          gv_tkn_data,
                                          gv_wf_notification);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ���i�敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_prod_class_n,
                                          gv_tkn_data,
                                          gv_prod_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �i�ڋ敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_item_class_n,
                                          gv_tkn_data,
                                          gv_item_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ��\�q�ɋ敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_frequent_whse_div_n,
                                          gv_tkn_data,
                                          gv_frequent_whse_div);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �q��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_whse_n,
                                          gv_tkn_data,
                                          gv_whse);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_vendor_id_n,
                                          gv_tkn_data,
                                          gv_vendor_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �i��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_item_no_n,
                                          gv_tkn_data,
                                          gv_item_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ���b�g
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_lot_no_n,
                                          gv_tkn_data,
                                          gv_lot_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- ������
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_manufacture_date_n,
                                          gv_tkn_data,
                                          gv_manufacture_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �ܖ�����
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_expiration_date_n,
                                          gv_tkn_data,
                                          gv_expiration_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �ŗL�L��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_uniqe_sign_n,
                                          gv_tkn_data,
                                          gv_uniqe_sign);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �����H��
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_mf_factory_n,
                                          gv_tkn_data,
                                          gv_mf_factory);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �������b�g
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_mf_lot_n,
                                          gv_tkn_data,
                                          gv_mf_lot);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �Y�n
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_home_n,
                                          gv_tkn_data,
                                          gv_home);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- R1
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_r1_n,
                                          gv_tkn_data,
                                          gv_r1);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- R2
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_r2_n,
                                          gv_tkn_data,
                                          gv_r2);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
    -- �Z�L�����e�B�敪
    lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                          gv_tkn_xxpo_30022,
                                          gv_tkn_param,
                                          lv_sec_class_n,
                                          gv_tkn_data,
                                          gv_sec_class);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END parameter_disp;
--
  /***********************************************************************************
   * Function Name    : get_inv_stock_vol
   * Description      : �莝�݌ɐ��擾
   ***********************************************************************************/
  FUNCTION  get_inv_stock_vol(
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- �ϐ��錾
    ln_temp_inv_stock_vol           NUMBER;
    ln_lot_id                       ic_lots_mst.lot_id%TYPE;
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- ���b�g�Ǘ��敪�擾
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- �莝�݌ɐ��ʎZ�oAPI����.���b�gID�̐ݒ�
    IF (lv_lot_ctl = gv_lot_code1) THEN
      -- ���b�g�Ǘ��i�̏ꍇ�A���o�������b�gID��ݒ�
      ln_lot_id := in_lot_id;
    ELSE
      -- �񃍃b�g�Ǘ��i�̏ꍇ�ANULL��ݒ�
      ln_lot_id := NULL;
    END IF;
--
    -- ���ʊ֐���莝�݌ɐ��ʎZ�oAPI��R�[��
    ln_temp_inv_stock_vol := xxcmn_common2_pkg.get_stock_qty(
                               in_whse_id => in_inventory_location_id,  -- OPM�ۊǑq��ID
                               in_item_id => in_item_id,                -- OPM�i��ID
                               in_lot_id  => ln_lot_id);                -- ���b�gID
--
    RETURN ln_temp_inv_stock_vol;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_inv_stock_vol;
--
  /***********************************************************************************
   * Function Name    : get_supply_stock_plan
   * Description      : ���ɗ\�萔�擾
   ***********************************************************************************/
  FUNCTION  get_supply_stock_plan(
              iv_segment1               IN xxcmn_item_locations_v.segment1%TYPE,
              in_inventory_location_id  IN xxcmn_item_locations_v.inventory_location_id%TYPE,
              iv_item_no                IN xxcmn_item_mst_v.item_no%TYPE,
              in_item_id                IN xxcmn_item_mst_v.item_id%TYPE,
              iv_lot_no                 IN ic_lots_mst.lot_no%TYPE,
              in_lot_id                 IN ic_lots_mst.lot_id%TYPE,
              in_loct_onhand            IN ic_loct_inv.loct_onhand%TYPE)
              RETURN NUMBER
  IS
--
    -- �ϐ��錾
    lv_errbuf                       VARCHAR2(2000);
    lv_retcode                      VARCHAR2(1);
    lv_errmsg                       VARCHAR2(2000);
    ln_hacchu_ukeire_yotei          NUMBER;    -- ���ɗ\�萔(7-2:��������\��)
    ln_idou_nyuuko_yotei_shiji      NUMBER;    -- ���ɗ\�萔(7-3:�ړ����ɗ\�� �w��)
    ln_idou_nyuuko_yotei_shukko     NUMBER;    -- ���ɗ\�萔(7-4:�ړ����ɗ\�� �o�ɕ񍐗L)
    ln_seisan_yotei                 NUMBER;    -- ���ɗ\�萔(7-5:���Y�\��)
    ln_temp_supply_stock_plan       NUMBER;    -- ���ɗ\�萔�ޔ�
    ld_max_date                     DATE;      -- �ő���t�i�[�ϐ�
    lv_lot_ctl                      xxcmn_item_mst_v.lot_ctl%TYPE;
  BEGIN
--
    -- �ϐ�������
    ln_hacchu_ukeire_yotei      := 0;
    ln_idou_nyuuko_yotei_shiji  := 0;
    ln_idou_nyuuko_yotei_shukko := 0;
    ln_seisan_yotei             := 0;
--
    -- ���t�͈͂Ȃ��ɐ��ʂ��擾����
    ld_max_date := FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), gv_date_format);
--
    -- ���b�g�Ǘ��敪�擾
    BEGIN
      SELECT ximv.lot_ctl
      INTO   lv_lot_ctl
      FROM   xxcmn_item_mst_v ximv
      WHERE  ximv.item_id = in_item_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    IF (lv_lot_ctl = gv_lot_code1) THEN
      -- �����b�g�i��
      -- ���ɗ\�萔(7-2:��������\��)
      xxcmn_common2_pkg.get_sup_lot_order_qty(
        iv_whse_code => iv_segment1,             -- �ۊǑq�ɃR�[�h
        iv_item_code => iv_item_no,              -- �i�ڃR�[�h
        iv_lot_no    => iv_lot_no,               -- ���b�gNO
        id_eff_date  => ld_max_date,             -- �L�����t
        on_qty       => ln_hacchu_ukeire_yotei,  -- ����
        ov_errbuf    => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-3:�ړ����ɗ\�� �w��)
      xxcmn_common2_pkg.get_sup_lot_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-4:�ړ����ɗ\�� �o�ɕ񍐗L)
      xxcmn_common2_pkg.get_sup_lot_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        in_lot_id   => in_lot_id,                      -- ���b�gID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-5:���Y�\��)
      xxcmn_common2_pkg.get_sup_lot_produce_qty(
        iv_whse_code => iv_segment1,             -- �ۊǑq�ɃR�[�h
        in_item_id   => in_item_id,              -- �i��ID
        in_lot_id    => in_lot_id,               -- ���b�gID
        id_eff_date  => ld_max_date,             -- �L�����t
        on_qty       => ln_seisan_yotei,         -- ����
        ov_errbuf    => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
      -- �����b�g�iEND��
    ELSIF (lv_lot_ctl = gv_lot_code0) THEN
--
      -- ���񃍃b�g�i��
      -- ���ɗ\�萔(7-2:��������\��)
      xxcmn_common2_pkg.get_sup_order_qty(
        iv_whse_code => iv_segment1,             -- �ۊǑq�ɃR�[�h
        iv_item_code => iv_item_no,              -- �i�ڃR�[�h
        id_eff_date  => ld_max_date,             -- �L�����t
        on_qty       => ln_hacchu_ukeire_yotei,  -- ����
        ov_errbuf    => lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode   => lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg    => lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      --���ɗ\�萔(7-3:�ړ����ɗ\�� �w��)
      xxcmn_common2_pkg.get_sup_inv_in_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shiji,     -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
--
      -- ���ɗ\�萔(7-4:�ړ����ɗ\�� �o�ɕ񍐗L)
      xxcmn_common2_pkg.get_sup_inv_out_qty(
        in_whse_id  => in_inventory_location_id,       -- �ۊǑq��ID
        in_item_id  => in_item_id,                     -- �i��ID
        id_eff_date => ld_max_date,                    -- �L�����t
        on_qty      => ln_idou_nyuuko_yotei_shukko,    -- ����
        ov_errbuf   => lv_errbuf,                      -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode  => lv_retcode,                     -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg   => lv_errmsg);                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- ���ʊ֐��������ʃ`�F�b�N
      IF (lv_retcode = gv_status_error) THEN
        RETURN NULL;
      END IF;
      -- ���񃍃b�g�iEND��
    END IF;
--
    -- �e���ʊ֐��ɂĎ擾�����l���T�}�� = ���ɗ\�萔
    ln_temp_supply_stock_plan := ln_hacchu_ukeire_yotei
                               + ln_idou_nyuuko_yotei_shiji
                               + ln_idou_nyuuko_yotei_shukko
                               + ln_seisan_yotei;
--
    RETURN ln_temp_supply_stock_plan;
--
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_supply_stock_plan;
--
--
  /**********************************************************************************
   * Procedure Name   : get_lot_inf_proc
   * Description      : ���b�g�݌ɏ��擾����(C-1)
   ***********************************************************************************/
  PROCEDURE get_lot_inf_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_inf_proc'; -- �v���O������
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
		cn_zero            CONSTANT NUMBER       := 0;
--
    -- *** ���[�J���ϐ� ***
    mst_rec              masters_rec;
    ln_cnt               NUMBER;
    lv_prof_xdfw         VARCHAR2(4);         -- �_�~�[��\�q��
    ld_target_date       DATE;                -- �Ώۓ��t
    ln_prof_xtt          NUMBER;              -- �݌ɏƉ�Ώ�
    lv_target_flg        VARCHAR2(1);         -- �Ώۃf�[�^�t���O
    ln_stock_vol         NUMBER;              -- �莝�݌ɐ�
    ln_supply_stock_plan NUMBER;              -- ���ɗ\�萔
-- 2008/08/01 PT�Ή� 1.1 modify start
    ln_vendor_code       VARCHAR2(4);         -- �����R�[�h(�u���C�N�p)
    ln_item_no           VARCHAR2(7);         -- �i�ڃR�[�h(�u���C�N�p)
    ln_lot_no            VARCHAR2(10);        -- ���b�gNo.(�u���C�N�p)
-- 2008/08/01 PT�Ή� 1.1 modify end
--
    -- *** ���[�J���E�J�[�\�� ***
    
-- 2008/08/03 PT�Ή� 1.2 modify start
/*
    CURSOR mst_data_cur
    IS
      SELECT  iiim.segment1                                            AS segment1          -- �ۊǑq�ɃR�[�h
             ,iiim.inventory_location_id                               AS inventory_location_id -- �ۊǑq��ID
             ,NVL(ili.loct_onhand, cn_zero)                            AS loct_onhand       -- �莝����
             ,iiim.attribute8                                          AS vendor_code       -- �����(DFF8)
             ,REPLACE(xvv.vendor_full_name,gv_sep_com)                 AS vendor_full_name  -- ������(�d����)
             ,REPLACE(xvv.vendor_short_name,gv_sep_com)                AS vendor_short_name -- ����(�d����)
             ,iiim.item_id                                             AS item_id           -- �i��ID
             ,iiim.item_no                                             AS item_no           -- �i�ڃR�[�h
             ,REPLACE(iiim.item_name,gv_sep_com)                       AS item_name         -- �i���E������
             ,REPLACE(iiim.item_short_name,gv_sep_com)                 AS item_short_name   -- �i���E����
             ,iiim.lot_id                                              AS lot_id            -- ���b�gID
             ,DECODE(iiim.lot_ctl, gv_lot_code0, NULL, iiim.lot_no)    AS lot_no            -- ���b�gNo
             ,FND_DATE.STRING_TO_DATE(iiim.attribute1, gv_date_format) AS product_date      -- �����N����(DFF1)
             ,FND_DATE.STRING_TO_DATE(iiim.attribute3, gv_date_format) AS use_by_date       -- �ܖ�����(DFF3)
             ,iiim.attribute2                                          AS original_char     -- �ŗL�L��(DFF2)
             ,iiim.attribute20                                         AS manu_factory      -- �����H��(DFF20)
             ,iiim.attribute21                                         AS manu_lot          -- �������b�g(DFF21)
             ,iiim.attribute12                                         AS home              -- �Y�n(DFF12)
             ,iiim.attribute14                                         AS rank1             -- �����N1(DFF14)
             ,iiim.attribute15                                         AS rank2             -- �����N2(DFF15)
             ,REPLACE(iiim.attribute18,gv_sep_com)                     AS description       -- �E�v(DFF18)
             ,iiim.attribute22                                         AS qt_inspect_req_no -- �����˗��ԍ�(DFF22)
             ,FND_DATE.STRING_TO_DATE(xqi.inspect_due_date1, gv_date_format) AS inspect_due_date1 -- �����\���1
             ,FND_DATE.STRING_TO_DATE(xqi.test_date1, gv_date_format)        AS test_date1        -- ������1
             ,xqi.qt_effect1                                           AS qt_effect1        -- ����1
             ,FND_DATE.STRING_TO_DATE(xqi.inspect_due_date2, gv_date_format) AS inspect_due_date2 -- �����\���2
             ,FND_DATE.STRING_TO_DATE(xqi.test_date2, gv_date_format)  AS test_date2        -- ������2
             ,xqi.qt_effect2                                           AS qt_effect2        -- ����2
             ,FND_DATE.STRING_TO_DATE(xqi.inspect_due_date3, gv_date_format) AS inspect_due_date3 -- �����\���3
             ,FND_DATE.STRING_TO_DATE(xqi.test_date3, gv_date_format)        AS test_date3        -- ������3
             ,xqi.qt_effect3                                           AS qt_effect3        -- ����3
      FROM   ic_loct_inv                ili,     -- OPM�莝����
             (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_name,             -- �i���E������
                     ximv.item_short_name,       -- �i���E����
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute8,
                     ilm.attribute12,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute18,
                     ilm.attribute20,
                     ilm.attribute21,
                     ilm.attribute22
              FROM   xxcmn_item_mst_v ximv,          -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst ilm,                -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v  xilv,   -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories5_v xicv   -- OPM�i�ڃJ�e�S���������VIEW5
-- 2008/08/01 PT�Ή� 1.1 modify(�J�e�S��VIEW�폜)
              WHERE  ximv.item_id            = ilm.item_id
              -- �i�ڋ敪(�K�{)
              AND    xicv.item_class_code    = gv_item_class
              -- ���i�敪(�K�{)
              AND    xicv.prod_class_code    = gv_prod_class
              AND    xicv.item_id            = ximv.item_id
              AND  ((ximv.lot_ctl            = gv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = gv_lot_code0)) iiim,
             xxcmn_item_locations_v  xilv_fr,       -- OPM�ۊǏꏊ���VIEW(��\�q��)
             xxwip_qt_inspection    xqi,            -- �i�������˗����
             xxcmn_vendors_v            xvv         -- �d������
      -- �i��(�ۊǏꏊ)�Ǝ莝���ʂ̊֘A�t��
      WHERE  iiim.item_id                = ili.item_id(+)
      AND    iiim.segment1               = ili.location(+)
      AND    iiim.lot_id                 = ili.lot_id(+)
      -- ���̎擾
      AND    iiim.attribute8             = xvv.segment1(+)
      AND    TO_NUMBER(iiim.attribute22) = xqi.qt_inspect_req_no(+)
      -- �莝����.�ŏI�X�V���F�݌ɂ��Ȃ��ꍇ(EBS�W���̃}�X�^�����f��)�̓V�X�e�����t�Ƃ���
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- �Z�L�����e�B�敪
      AND    (
      -- �ɓ������[�U�[�^�C�v
                   (gv_sec_class = gv_sec_class_home
                    AND (
                          -- ���������F�q�ɂ����͍�
                          (gv_whse IS NOT NULL
                        AND (
                             -- ���������F��\�q�ɋ敪��'Y'
                             (gv_frequent_whse_div = 'Y'
                                AND ( (iiim.frequent_whse      = xilv_fr.segment1)
                                    OR(   (iiim.frequent_whse     = lv_prof_xdfw)  -- �_�~�[��\�q��
                                      AND ( xilv_fr.segment1 = (SELECT xfil.frq_item_location_code
                                                                FROM  xxwsh_frq_item_locations xfil -- �i�ڕʕۊǑq��
                                                                WHERE xfil.item_location_code = iiim.segment1
                                                                AND   xfil.item_id = iiim.item_id))))
                                AND xilv_fr.frequent_whse   = gv_whse)
                             -- ���������F��\�q�ɋ敪��'N'
                             OR (gv_frequent_whse_div = 'N'
                                AND (iiim.segment1 = gv_whse)
                                AND (xilv_fr.segment1 = iiim.segment1))
                            )
                          )
                        -- ���������F�q�ɂ�������
                        OR (gv_whse IS NULL
-- 2008/08/01 PT�Ή� 1.1 modify start
                        AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT�Ή� 1.1 modify end)
                        )
                   )
      -- �d���惆�[�U�[�^�C�v
               OR  (gv_sec_class = gv_sec_class_vend
                    AND iiim.attribute8 IN
                      (SELECT papf.attribute4            -- �����R�[�h(�d����R�[�h)
                       FROM   fnd_user           fu      -- ���[�U�[�}�X�^
                             ,per_all_people_f   papf    -- �]�ƈ��}�X�^
                       WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                       AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                       AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                       AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                       AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                         OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                       AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
                    AND (
                          -- ���������F�q�ɂ����͍�
                          (gv_whse IS NOT NULL
                      AND xilv_fr.segment1 = gv_whse
-- 2008/08/01 PT�Ή� 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT�Ή� 1.1 modify end
                      -- ���������F�q�ɂ�������
                      OR (gv_whse IS NULL
-- 2008/08/01 PT�Ή� 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT�Ή� 1.1 modify end
                        )
                   )
      -- �O���q�Ƀ��[�U�[�^�C�v
               OR     (gv_sec_class = gv_sec_class_extn
                    AND (
                          iiim.segment1 IN
                            (SELECT xilv.segment1                      -- �ۊǑq�ɃR�[�h
                             FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                   ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                   ,xxcmn_item_locations_v xilv        -- OPM�ۊǏꏊ���VIEW
                             WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xilv.purchase_code         = papf.attribute4        -- �d����R�[�h
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                        OR iiim.segment1 IN
                            (SELECT xvs.vendor_stock_whse              -- �����݌ɓ��ɐ�
                             FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                   ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                   ,xxcmn_vendor_sites_v   xvs         -- �d����T�C�g���VIEW
                             WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xvs.vendor_id              = papf.attribute4        -- �d����R�[�h
                             AND    xvs.vendor_site_code       = papf.attribute6        -- �d����T�C�g��
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                        )
                    AND ( 
                            -- ���������F�q�ɂ����͍�
                            (gv_whse IS NOT NULL 
                          AND (
                               -- ���������F��\�q�ɋ敪��'Y'
                               (gv_frequent_whse_div = 'Y'
                                AND ( (iiim.frequent_whse      = xilv_fr.segment1)
                                    OR(   (iiim.frequent_whse     = lv_prof_xdfw)  -- �_�~�[��\�q��
                                      AND ( xilv_fr.segment1 = (SELECT xfil.frq_item_location_code
                                                                FROM  xxwsh_frq_item_locations xfil -- �i�ڕʕۊǑq��
                                                                WHERE xfil.item_location_code = iiim.segment1
                                                                AND   xfil.item_id = iiim.item_id))))
                                AND xilv_fr.frequent_whse   = gv_whse)
                               -- ���������F��\�q�ɋ敪��'N'
                               OR (gv_frequent_whse_div = 'N'
                                  AND (iiim.segment1 = gv_whse)
                                  AND (xilv_fr.segment1 = iiim.segment1))
                              )
                            )
                         -- ���������F�q�ɂ�������
                          OR( gv_whse IS NULL
-- 2008/08/01 PT�Ή� 1.1 modify start
                          AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT�Ή� 1.1 modify end
                        )
                   )
      -- ���m�u�����[�U�[�^�C�v
               OR     (gv_sec_class = gv_sec_class_quay
                    AND (
                          iiim.attribute8 IN
                            (SELECT papf.attribute4            -- �����R�[�h(�d����R�[�h)
                             FROM   fnd_user           fu      -- ���[�U�[�}�X�^
                                   ,per_all_people_f   papf    -- �]�ƈ��}�X�^
                             WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                        OR iiim.attribute8 IN
                            (SELECT xv.segment1                -- �����R�[�h(�d����R�[�h)
                             FROM   fnd_user           fu      -- ���[�U�[�}�X�^
                                   ,per_all_people_f   papf    -- �]�ƈ��}�X�^
                                   ,xxcmn_vendors_v    xv      -- �d������VIEW
                             WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xv.spare3                  = papf.attribute4        -- �����R�[�h(�֘A���)
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                        )
                    AND (
                          -- ���������F�q�ɂ����͍�
                          (gv_whse IS NOT NULL
                      AND xilv_fr.segment1 = gv_whse
-- 2008/08/01 PT�Ή� 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1
-- 2008/08/01 PT�Ή� 1.1 modify end
                          )
                      -- ���������F�q�ɂ�������
                      OR (gv_whse IS NULL
-- 2008/08/01 PT�Ή� 1.1 modify start
                      AND xilv_fr.segment1 = iiim.segment1)
-- 2008/08/01 PT�Ή� 1.1 modify end
                        )
                   )
             )
      -- ���o����(�����l)
      -- �����
      AND   ((gv_vendor_id IS NULL) OR (iiim.attribute8 = gv_vendor_id))
      -- �i��
      AND   ((gv_item_no IS NULL) OR (iiim.item_no = gv_item_no))
      -- ���b�g
      AND   ((gv_lot_no IS NULL) OR (iiim.lot_no = gv_lot_no))
      -- ������
      AND   ((gv_manufacture_date IS NULL) OR (iiim.attribute1 = gv_manufacture_date))
      -- �ܖ�����
      AND   ((gv_expiration_date IS NULL) OR (iiim.attribute3 = gv_expiration_date))
      -- �ŗL�L��
      AND   ((gv_uniqe_sign IS NULL) OR (iiim.attribute2 = gv_uniqe_sign))
      -- �����H��
      AND   ((gv_mf_factory IS NULL) OR (iiim.attribute20 = gv_mf_factory))
      -- �������b�g�ԍ�
      AND   ((gv_mf_lot IS NULL) OR (iiim.attribute21 = gv_mf_lot))
      -- �Y�n
      AND   ((gv_home IS NULL) OR (iiim.attribute12 = gv_home))
      -- R1
      AND   ((gv_r1 IS NULL) OR (iiim.attribute14 = gv_r1))
      -- R2
      AND   ((gv_r2 IS NULL) OR (iiim.attribute15 = gv_r2))
      ORDER BY TO_NUMBER(iiim.attribute8),
               iiim.item_no,
-- 2008/08/01 PT�Ή� 1.1 modify start
               --TO_NUMBER(iiim.lot_id);
               TO_NUMBER(DECODE(iiim.lot_ctl, gv_lot_code0, '0', iiim.lot_no));
-- 2008/08/01 PT�Ή� 1.1 modify end
*/
    CURSOR mst_data_cur
    IS
      SELECT  iiim.segment1                                            AS segment1          -- �ۊǑq�ɃR�[�h
             ,iiim.inventory_location_id                               AS inventory_location_id -- �ۊǑq��ID
             ,NVL(ili.loct_onhand, cn_zero)                            AS loct_onhand       -- �莝����
             ,iiim.attribute8                                          AS vendor_code       -- �����(DFF8)
             ,REPLACE(iiim.vendor_full_name,gv_sep_com)                AS vendor_full_name  -- ������(�d����)
             ,REPLACE(iiim.vendor_short_name,gv_sep_com)               AS vendor_short_name -- ����(�d����)
             ,iiim.item_id                                             AS item_id           -- �i��ID
             ,iiim.item_no                                             AS item_no           -- �i�ڃR�[�h
             ,REPLACE(iiim.item_name,gv_sep_com)                       AS item_name         -- �i���E������
             ,REPLACE(iiim.item_short_name,gv_sep_com)                 AS item_short_name   -- �i���E����
             ,iiim.lot_id                                              AS lot_id            -- ���b�gID
             ,DECODE(iiim.lot_ctl, gv_lot_code0, NULL, iiim.lot_no)    AS lot_no            -- ���b�gNo
/* 2008/08/19 Mod ��
             ,FND_DATE.STRING_TO_DATE(iiim.attribute1, gv_date_format) AS product_date      -- �����N����(DFF1)
             ,FND_DATE.STRING_TO_DATE(iiim.attribute3, gv_date_format) AS use_by_date       -- �ܖ�����(DFF3)
2008/08/19 Mod �� */
             ,iiim.attribute1                                          AS product_date      -- �����N����(DFF1)
             ,iiim.attribute3                                          AS use_by_date       -- �ܖ�����(DFF3)
             ,iiim.attribute2                                          AS original_char     -- �ŗL�L��(DFF2)
             ,iiim.attribute20                                         AS manu_factory      -- �����H��(DFF20)
             ,iiim.attribute21                                         AS manu_lot          -- �������b�g(DFF21)
             ,iiim.attribute12                                         AS home              -- �Y�n(DFF12)
             ,iiim.attribute14                                         AS rank1             -- �����N1(DFF14)
             ,iiim.attribute15                                         AS rank2             -- �����N2(DFF15)
             ,REPLACE(iiim.attribute18,gv_sep_com)                     AS description       -- �E�v(DFF18)
             ,iiim.attribute22                                         AS qt_inspect_req_no -- �����˗��ԍ�(DFF22)
/* 2008/08/19 Mod ��
             ,FND_DATE.STRING_TO_DATE(iiim.inspect_due_date1, gv_date_format) AS inspect_due_date1 -- �����\���1
             ,FND_DATE.STRING_TO_DATE(iiim.test_date1, gv_date_format)        AS test_date1        -- ������1
2008/08/19 Mod �� */
             ,TO_CHAR(iiim.inspect_due_date1, gv_date_format)          AS inspect_due_date1 -- �����\���1
             ,TO_CHAR(iiim.test_date1, gv_date_format)                 AS test_date1        -- ������1
             ,iiim.qt_effect1                                          AS qt_effect1        -- ����1
/* 2008/08/19 Mod ��
             ,FND_DATE.STRING_TO_DATE(iiim.inspect_due_date2, gv_date_format) AS inspect_due_date2 -- �����\���2
             ,FND_DATE.STRING_TO_DATE(iiim.test_date2, gv_date_format)  AS test_date2        -- ������2
2008/08/19 Mod �� */
             ,TO_CHAR(iiim.inspect_due_date2, gv_date_format)          AS inspect_due_date2 -- �����\���2
             ,TO_CHAR(iiim.test_date2, gv_date_format)                 AS test_date2        -- ������2
             ,iiim.qt_effect2                                          AS qt_effect2        -- ����2
/* 2008/08/19 Mod ��
             ,FND_DATE.STRING_TO_DATE(iiim.inspect_due_date3, gv_date_format) AS inspect_due_date3 -- �����\���3
             ,FND_DATE.STRING_TO_DATE(iiim.test_date3, gv_date_format)        AS test_date3        -- ������3
2008/08/19 Mod �� */
             ,TO_CHAR(iiim.inspect_due_date3, gv_date_format)          AS inspect_due_date3 -- �����\���3
             ,TO_CHAR(iiim.test_date3, gv_date_format)                 AS test_date3        -- ������3
             ,iiim.qt_effect3                                          AS qt_effect3        -- ����3
      FROM   (SELECT xilv.segment1,              -- �ۊǑq��
                     xilv.inventory_location_id, -- �ۊǑq��ID
                     xilv.mtl_organization_id,   -- �݌ɑg�DID
                     xilv.frequent_whse,         -- ��\�q��
                     xilv.customer_stock_whse,   -- �q�ɖ��`
                     ximv.item_id,               -- �i��ID
                     ximv.item_name,             -- �i���E������
                     ximv.item_short_name,       -- �i���E����
                     ximv.item_no,               -- �i�ڃR�[�h
                     ximv.lot_ctl,               -- ���b�g�Ǘ��敪
                     ilm.lot_id,                 -- ���b�gID
                     ilm.lot_no,                 -- ���b�gNo
                     ilm.attribute1,
                     ilm.attribute2,
                     ilm.attribute3,
                     ilm.attribute8,
                     ilm.attribute12,
                     ilm.attribute14,
                     ilm.attribute15,
                     ilm.attribute18,
                     ilm.attribute20,
                     ilm.attribute21,
                     ilm.attribute22,
                     xvv.vendor_full_name,       -- ������(�d����)
                     xvv.vendor_short_name,      -- ����(�d����)
                     xqi.inspect_due_date1,      -- �����\���1
                     xqi.test_date1,             -- ������1
                     xqi.qt_effect1,             -- ����1
                     xqi.inspect_due_date2,      -- �����\���2
                     xqi.test_date2,             -- ������2
                     xqi.qt_effect2,             -- ����2
                     xqi.inspect_due_date3,      -- �����\���3
                     xqi.test_date3,             -- ������3
                     xqi.qt_effect3              -- ����3
              FROM   xxcmn_item_mst_v         ximv,    -- OPM�i�ڃ}�X�^���VIEW
                     ic_lots_mst              ilm,     -- OPM���b�g�}�X�^
                     xxcmn_item_locations_v   xilv,    -- OPM�ۊǏꏊ���VIEW
                     xxcmn_item_categories5_v xicv,    -- OPM�i�ڃJ�e�S���������VIEW5
                     xxwip_qt_inspection      xqi,     -- �i�������˗����
                     xxcmn_vendors_v          xvv      -- �d������
              WHERE  ximv.item_id            = ilm.item_id
              -- �i�ڋ敪(�K�{)
              AND    xicv.item_class_code    = gv_item_class
              -- ���i�敪(�K�{)
              AND    xicv.prod_class_code    = gv_prod_class
              AND    xicv.item_id            = ximv.item_id
              AND  ((ximv.lot_ctl            = gv_lot_code1
                AND  ilm.lot_id             <> cn_zero)
                OR   ximv.lot_ctl            = gv_lot_code0)
              AND    ilm.attribute8          = xvv.segment1(+)
              AND    TO_NUMBER(ilm.attribute22) = xqi.qt_inspect_req_no(+)
              -- �Z�L�����e�B�敪
              AND    (
                -- �ɓ������[�U�[�^�C�v
                   (gv_sec_class = gv_sec_class_home
                     AND (
                          (gv_whse IS NULL)
                        OR (
                             -- ���������F��\�q�ɋ敪��'Y'
                             (gv_frequent_whse_div = 'Y'
                                AND ( EXISTS (SELECT '1'
                                             FROM   xxcmn_item_locations_v xilv_fr1
                                             WHERE  xilv.frequent_whse     = xilv_fr1.segment1
                                             AND    xilv_fr1.frequent_whse = gv_whse)
                                    OR( (xilv.frequent_whse     = lv_prof_xdfw)      -- �_�~�[��\�q��
                                      AND ( EXISTS (SELECT '1'
                                                   FROM  xxwsh_frq_item_locations xfil -- �i�ڕʕۊǑq��
                                                        ,xxcmn_item_locations_v xilv_fr2
                                                   WHERE xfil.item_location_code     = xilv.segment1
                                                   AND   xfil.item_id                = ximv.item_id
                                                   AND   xfil.frq_item_location_code = xilv_fr2.segment1
                                                   AND   xilv_fr2.frequent_whse      = gv_whse)))))
                                -- ���������F��\�q�ɋ敪��'N'
                                OR (gv_frequent_whse_div = 'N'
                                   AND xilv.segment1 = gv_whse)
                           )
                         )
                   )
                -- �d���惆�[�U�[�^�C�v
               OR  (gv_sec_class = gv_sec_class_vend
                      AND ilm.attribute8 IN
                        (SELECT papf.attribute4            -- �����R�[�h(�d����R�[�h)
                         FROM   fnd_user           fu      -- ���[�U�[�}�X�^
                               ,per_all_people_f   papf    -- �]�ƈ��}�X�^
                         WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                         AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                         AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                         AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                         AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                           OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                         AND    fu.user_id                 = gn_user_id)            -- ���[�U�[ID
                      AND (
                         -- ���������F�q�ɂ����͍�
                            (gv_whse IS NULL)
                         OR (xilv.segment1 = gv_whse)
                          )
                   )
                -- �O���q�Ƀ��[�U�[�^�C�v
               OR  (gv_sec_class = gv_sec_class_extn
                      AND (
                          xilv.segment1 IN
                            (SELECT xilv2.segment1                     -- �ۊǑq�ɃR�[�h
                             FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                   ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                   ,xxcmn_item_locations_v xilv2       -- OPM�ۊǏꏊ���VIEW
                             WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xilv.purchase_code         = papf.attribute4        -- �d����R�[�h
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                        OR xilv.segment1 IN
                            (SELECT xvs.vendor_stock_whse              -- �����݌ɓ��ɐ�
                             FROM   fnd_user               fu          -- ���[�U�[�}�X�^
                                   ,per_all_people_f       papf        -- �]�ƈ��}�X�^
                                   ,xxcmn_vendor_sites_v   xvs         -- �d����T�C�g���VIEW
                             WHERE  fu.employee_id             = papf.person_id         -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xvs.vendor_id              = papf.attribute4        -- �d����R�[�h
                             AND    xvs.vendor_site_code       = papf.attribute6        -- �d����T�C�g��
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                         )
                      AND (
                            -- ���������F�q�ɂ����͍�
                            (gv_whse IS NULL)
                          OR (
                               -- ���������F��\�q�ɋ敪��'Y'
                             (gv_frequent_whse_div = 'Y'
                                AND ((EXISTS (SELECT '1'
                                             FROM   xxcmn_item_locations_v xilv_fr3
                                             WHERE  xilv.frequent_whse     = xilv_fr3.segment1
                                             AND    xilv_fr3.frequent_whse = gv_whse))
                                    OR(   (xilv.frequent_whse     = lv_prof_xdfw)      -- �_�~�[��\�q��
                                      AND ( EXISTS (SELECT '1'
                                                   FROM  xxwsh_frq_item_locations xfil -- �i�ڕʕۊǑq��
                                                        ,xxcmn_item_locations_v xilv_fr4
                                                   WHERE xfil.item_location_code     = xilv.segment1
                                                   AND   xfil.item_id                = ximv.item_id
                                                   AND   xfil.frq_item_location_code = xilv_fr4.segment1
                                                   AND   xilv_fr4.frequent_whse      = gv_whse)))))
                             -- ���������F��\�q�ɋ敪��'N'
                             OR (gv_frequent_whse_div = 'N'
                                AND xilv.segment1 = gv_whse)
                            )
                          )
                   )
                -- ���m�u�����[�U�[�^�C�v
                   OR     (gv_sec_class = gv_sec_class_quay
                     AND (
                          ilm.attribute8 IN
                            (SELECT papf.attribute4            -- �����R�[�h(�d����R�[�h)
                             FROM   fnd_user           fu      -- ���[�U�[�}�X�^
                                   ,per_all_people_f   papf    -- �]�ƈ��}�X�^
                             WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                        OR ilm.attribute8 IN
                            (SELECT xv.segment1                -- �����R�[�h(�d����R�[�h)
                             FROM   fnd_user           fu      -- ���[�U�[�}�X�^
                                   ,per_all_people_f   papf    -- �]�ƈ��}�X�^
                                   ,xxcmn_vendors_v    xv      -- �d������VIEW
                             WHERE  fu.employee_id   = papf.person_id                   -- �]�ƈ�ID
                             AND    papf.effective_start_date <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND    papf.effective_end_date   >= TRUNC(gd_sys_date)     -- �K�p�I����
                             AND    fu.start_date             <= TRUNC(gd_sys_date)     -- �K�p�J�n��
                             AND  ((fu.end_date               IS NULL)                  -- �K�p�I����
                               OR  (fu.end_date               >= TRUNC(gd_sys_date)))
                             AND    xv.spare3                  = papf.attribute4        -- �����R�[�h(�֘A���)
                             AND    fu.user_id                 = gn_user_id             -- ���[�U�[ID
                            )
                        )
                    AND (
                          -- ���������F�q�ɂ����͍�
                         ((gv_whse IS NULL)
                      OR  (xilv.segment1 = gv_whse))
                        )
                   )
             )) iiim,
            ic_loct_inv              ili     -- OPM�莝����
      -- ���o����(�����l)
      WHERE  
             iiim.item_id            = ili.item_id(+)
      AND    iiim.segment1           = ili.location(+)
      AND    iiim.lot_id             = ili.lot_id(+)
      AND    NVL(ili.last_update_date, SYSDATE) >= ld_target_date
      -- �����
      AND   ((gv_vendor_id IS NULL) OR (iiim.attribute8 = gv_vendor_id))
      -- �i��
      AND   ((gv_item_no IS NULL) OR (iiim.item_no = gv_item_no))
      -- ���b�g
      AND   ((gv_lot_no IS NULL) OR (iiim.lot_no = gv_lot_no))
      -- ������
      AND   ((gv_manufacture_date IS NULL) OR (iiim.attribute1 = gv_manufacture_date))
      -- �ܖ�����
      AND   ((gv_expiration_date IS NULL) OR (iiim.attribute3 = gv_expiration_date))
      -- �ŗL�L��
      AND   ((gv_uniqe_sign IS NULL) OR (iiim.attribute2 = gv_uniqe_sign))
      -- �����H��
      AND   ((gv_mf_factory IS NULL) OR (iiim.attribute20 = gv_mf_factory))
      -- �������b�g�ԍ�
      AND   ((gv_mf_lot IS NULL) OR (iiim.attribute21 = gv_mf_lot))
      -- �Y�n
      AND   ((gv_home IS NULL) OR (iiim.attribute12 = gv_home))
      -- R1
      AND   ((gv_r1 IS NULL) OR (iiim.attribute14 = gv_r1))
      -- R2
      AND   ((gv_r2 IS NULL) OR (iiim.attribute15 = gv_r2))
      ORDER BY TO_NUMBER(iiim.attribute8),
               iiim.item_no,
               TO_NUMBER(DECODE(iiim.lot_ctl, gv_lot_code0, '0', iiim.lot_no));
-- 2008/08/03 PT�Ή� 1.2 modify end
--
    -- *** ���[�J���E���R�[�h ***
    lr_mst_data_rec mst_data_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_cnt := 1;
-- 2008/08/01 PT�Ή� 1.1 modify start
    ln_vendor_code := NULL;
    ln_item_no := NULL;
    ln_lot_no := NULL;
-- 2008/08/01 PT�Ή� 1.1 modify end
    -- �v���t�@�C���l�擾
--
    gn_user_id             := FND_GLOBAL.USER_ID;
    gd_sys_date            := SYSDATE;
--
    lv_prof_xdfw := FND_PROFILE.VALUE('XXCMN_DUMMY_FREQUENT_WHSE');
    ln_prof_xtt  := FND_PROFILE.VALUE('XXINV_TARGET_TERM');
    -- �v���t�@�C�����擾������������A�݌ɏƉ�Ώۓ��t���Z�o
    ld_target_date := TRUNC(SYSDATE) - ln_prof_xtt;
--
    OPEN mst_data_cur;
--
    <<mst_data_loop>>
    LOOP
      FETCH mst_data_cur INTO lr_mst_data_rec;
      EXIT WHEN mst_data_cur%NOTFOUND;
--
-- 2008/08/01 PT�Ή� 1.1 modify start
      IF ( (ln_vendor_code IS NULL AND ln_item_no IS NULL AND ln_lot_no IS NULL)
        OR (NOT (ln_vendor_code = lr_mst_data_rec.vendor_code
        AND ln_item_no     = lr_mst_data_rec.item_no
        AND ln_lot_no      = lr_mst_data_rec.lot_no))) THEN
--
        ln_stock_vol := 0;
        ln_supply_stock_plan := 0;
        lv_target_flg := '0';
--
        -- �莝�݌ɐ��A���ɗ\�萔�`�F�b�N����
        IF ((gv_sec_class IN(gv_sec_class_home,gv_sec_class_vend,gv_sec_class_quay)
               AND (gv_whse IS NOT NULL))
             OR (gv_sec_class = gv_sec_class_extn)) THEN
          -- �莝�݌ɐ��`�F�b�N
          ln_stock_vol := get_inv_stock_vol(
                            lr_mst_data_rec.inventory_location_id,
                            lr_mst_data_rec.item_no,
                            lr_mst_data_rec.item_id,
                            lr_mst_data_rec.lot_id,
                            lr_mst_data_rec.loct_onhand);
--
          -- �莝�݌ɐ���0�ȊO�̏ꍇ
          IF (ln_stock_vol = 0) THEN
--
            -- ���ɗ\�萔�`�F�b�N
            ln_supply_stock_plan := get_supply_stock_plan(
                                      lr_mst_data_rec.segment1,
                                      lr_mst_data_rec.inventory_location_id,
                                      lr_mst_data_rec.item_no,
                                      lr_mst_data_rec.item_id,
                                      lr_mst_data_rec.lot_no,
                                      lr_mst_data_rec.lot_id,
                                      lr_mst_data_rec.loct_onhand);
--
            -- ���ɗ\�萔��0�ȊO�̏ꍇ
            IF (ln_supply_stock_plan != 0) THEN
              -- �Ώۃf�[�^�敪��'1'(�Ώ�)��ݒ�
              lv_target_flg := '1';
            END IF;
          ELSE
            -- �Ώۃf�[�^�敪��'1'(�Ώ�)��ݒ�
            lv_target_flg := '1';
          END IF;
        ELSE
          -- �Ώۃf�[�^�敪��'1'(�Ώ�)��ݒ�
          lv_target_flg := '1';
        END IF;
--
        -- �Ώۃf�[�^�敪��'1'(�Ώ�)�̏ꍇ
        IF (lv_target_flg = '1') THEN
          mst_rec.segment1          := lr_mst_data_rec.segment1;           -- �ۊǑq�ɃR�[�h
          mst_rec.vendor_code       := lr_mst_data_rec.vendor_code;        -- �����
          mst_rec.vendor_full_name  := lr_mst_data_rec.vendor_full_name;   -- ������(�d����)
          mst_rec.vendor_short_name := lr_mst_data_rec.vendor_short_name;  -- ����(�d����)
          mst_rec.item_id           := lr_mst_data_rec.item_id;            -- �i��ID
          mst_rec.item_no           := lr_mst_data_rec.item_no;            -- �i�ڃR�[�h
          mst_rec.item_name         := lr_mst_data_rec.item_name;          -- �i���E������
          mst_rec.item_short_name   := lr_mst_data_rec.item_short_name;    -- �i���E����
          mst_rec.lot_id            := lr_mst_data_rec.lot_id;             -- ���b�gID
          mst_rec.lot_no            := lr_mst_data_rec.lot_no;             -- ���b�gNo
          mst_rec.product_date      := lr_mst_data_rec.product_date;       -- �����N����
          mst_rec.use_by_date       := lr_mst_data_rec.use_by_date;        -- �ܖ�����
          mst_rec.original_char     := lr_mst_data_rec.original_char;      -- �ŗL�L��
          mst_rec.manu_factory      := lr_mst_data_rec.manu_factory;       -- �����H��
          mst_rec.manu_lot          := lr_mst_data_rec.manu_lot;           -- �������b�g
          mst_rec.home              := lr_mst_data_rec.home;               -- �Y�n
          mst_rec.rank1             := lr_mst_data_rec.rank1;              -- �����N1
          mst_rec.rank2             := lr_mst_data_rec.rank2;              -- �����N2
          mst_rec.description       := lr_mst_data_rec.description;        -- �E�v
          mst_rec.qt_inspect_req_no := lr_mst_data_rec.qt_inspect_req_no;  -- �����˗��ԍ�
          mst_rec.inspect_due_date1 := lr_mst_data_rec.inspect_due_date1;  -- �����\���1
          mst_rec.test_date1        := lr_mst_data_rec.test_date1;         -- ������1
          mst_rec.qt_effect1        := lr_mst_data_rec.qt_effect1;         -- ����1
          mst_rec.inspect_due_date2 := lr_mst_data_rec.inspect_due_date2;  -- �����\���2
          mst_rec.test_date2        := lr_mst_data_rec.test_date2;         -- ������2
          mst_rec.qt_effect2        := lr_mst_data_rec.qt_effect2;         -- ����2
          mst_rec.inspect_due_date3 := lr_mst_data_rec.inspect_due_date3;  -- �����\���3
          mst_rec.test_date3        := lr_mst_data_rec.test_date3;         -- ������3
          mst_rec.qt_effect3        := lr_mst_data_rec.qt_effect3;         -- ����3
--
          gt_master_tbl(ln_cnt) := mst_rec;
          ln_cnt := ln_cnt + 1;
        END IF;
--
      END IF;
--
      ln_vendor_code := lr_mst_data_rec.vendor_code;
      ln_item_no     := lr_mst_data_rec.item_no;
      ln_lot_no      := lr_mst_data_rec.lot_no;
-- 2008/08/01 PT�Ή� 1.1 modify end
--
    END LOOP mst_data_loop;
--
    CLOSE mst_data_cur;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (mst_data_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE mst_data_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lot_inf_proc;
--
  /***********************************************************************************
   * Procedure Name   : csv_file_proc
   * Description      : CSV�t�@�C���o��(C-2)
   ***********************************************************************************/
  PROCEDURE csv_file_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'csv_file_proc';           -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
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
    lv_head_seq       CONSTANT VARCHAR2(2)  := '10';
    lv_line_seq       CONSTANT VARCHAR2(2)  := '20';
--
    lv_joint_word     CONSTANT VARCHAR2(4)   := '_';
    lv_extend_word    CONSTANT VARCHAR2(4)   := '.csv';
--
    gv_sep_com        CONSTANT VARCHAR2(1)  := ',';
-- add start ver1.4
    lv_crlf           CONSTANT VARCHAR2(1)  := CHR(13); -- ���s�R�[�h
-- add end ver1.4
--
    -- *** ���[�J���ϐ� ***
    mst_rec         masters_rec;
    lv_data         VARCHAR2(5000);
    lf_file_hand    UTL_FILE.FILE_TYPE;         -- �t�@�C���E�n���h���̐錾
--
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    ln_tbl_id       NUMBER;
    ln_len          NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �t�@�C���p�XNULL
    IF (gr_outbound_rec.directory IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_xxcmn_10119);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �t�@�C����NULL
    IF (gr_outbound_rec.file_name IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_xxcmn_10120);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ln_len := length(gr_outbound_rec.file_name);
    -- �t�@�C�����̉��H(�t�@�C����-'.CSV'+'_'+'YYYYMMDDHH24MISS'+'.CSV')
    gv_sch_file_name := substr(gr_outbound_rec.file_name,1,ln_len-4)
                        || lv_joint_word
                        || TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
                        || lv_extend_word;
--
    -- �t�@�C�����݃`�F�b�N
    UTL_FILE.FGETATTR(gr_outbound_rec.directory,
                      gv_sch_file_name,
                      lb_retcd,
                      ln_file_size,
                      ln_block_size);
--
    -- �t�@�C������
    IF (lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                            gv_tkn_xxcmn_10114);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    BEGIN
--
      -- �t�@�C���I�[�v��
      lf_file_hand := UTL_FILE.FOPEN(gr_outbound_rec.directory,
                                     gv_sch_file_name,
                                     'w');
--
      ln_tbl_id := NULL;
--
      <<file_put_loop>>
      FOR i IN gt_master_tbl.FIRST .. gt_master_tbl.LAST LOOP
        mst_rec := gt_master_tbl(i);
--
        -- �f�[�^�쐬
        lv_data := gv_company_name           || gv_sep_com ||  -- ��Ж�
                   gv_data_class             || gv_sep_com ||  -- �f�[�^���
                   gv_transmission_no        || gv_sep_com ||  -- �`���p�}��
                   mst_rec.vendor_code       || gv_sep_com ||  -- �����
                   mst_rec.vendor_full_name  || gv_sep_com ||  -- ������(�d����)
                   mst_rec.vendor_short_name || gv_sep_com ||  -- ����(�d����)
                   mst_rec.item_no           || gv_sep_com ||  -- �i�ڃR�[�h
                   mst_rec.item_name         || gv_sep_com ||  -- �i���E������
                   mst_rec.item_short_name   || gv_sep_com ||  -- �i���E����
                   mst_rec.lot_no            || gv_sep_com ||  -- ���b�gNo
                   mst_rec.product_date      || gv_sep_com ||  -- �����N����
                   mst_rec.use_by_date       || gv_sep_com ||  -- �ܖ�����
                   mst_rec.original_char     || gv_sep_com ||  -- �ŗL�L��
                   mst_rec.manu_factory      || gv_sep_com ||  -- �����H��
                   mst_rec.manu_lot          || gv_sep_com ||  -- �������b�g
                   mst_rec.home              || gv_sep_com ||  -- �Y�n
                   mst_rec.rank1             || gv_sep_com ||  -- �����N1
                   mst_rec.rank2             || gv_sep_com ||  -- �����N2
                   mst_rec.description       || gv_sep_com ||  -- �E�v
                   mst_rec.qt_inspect_req_no || gv_sep_com ||  -- �����˗��ԍ�
                   mst_rec.inspect_due_date1 || gv_sep_com ||  -- �����\���1
                   mst_rec.test_date1        || gv_sep_com ||  -- ������1
                   mst_rec.qt_effect1        || gv_sep_com ||  -- ����1
                   mst_rec.inspect_due_date2 || gv_sep_com ||  -- �����\���2
                   mst_rec.test_date2        || gv_sep_com ||  -- ������2
                   mst_rec.qt_effect2        || gv_sep_com ||  -- ����2
                   mst_rec.inspect_due_date3 || gv_sep_com ||  -- �����\���3
                   mst_rec.test_date3        || gv_sep_com ||  -- ������3
-- mod start ver1.4
--                   mst_rec.qt_effect3;                         -- ����3
                   mst_rec.qt_effect3        || lv_crlf;       -- ����3
-- mod end ver1.4
--
        -- �f�[�^�o��
        UTL_FILE.PUT_LINE(lf_file_hand,lv_data);
--
        gn_normal_cnt := gn_normal_cnt + 1;
--
      END LOOP file_put_loop;
--
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE(lf_file_hand);
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN       -- �t�@�C���p�X�s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_xxcmn_10113);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.INVALID_FILENAME THEN   -- �t�@�C�����s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_xxcmn_10114);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN UTL_FILE.ACCESS_DENIED OR        -- �t�@�C���A�N�Z�X�����G���[
           UTL_FILE.WRITE_ERROR THEN        -- �������݃G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_xxcmn_10115);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END csv_file_proc;
--
  /**********************************************************************************
   * Procedure Name   : workflow_start
   * Description      : ���[�N�t���[�ʒm����(C-3)
   ***********************************************************************************/
  PROCEDURE workflow_start(
    ov_errbuf             OUT NOCOPY VARCHAR2,          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'workflow_start'; -- �v���O������
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
    lv_itemkey                VARCHAR2(30);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    gr_outbound_rec.file_name := gv_sch_file_name;
--
    --WF�^�C�v�ň�ӂƂȂ�WF�L�[���擾
    SELECT TO_CHAR(xxcmn_wf_key_s1.NEXTVAL)
    INTO   lv_itemkey
    FROM   DUAL;
--
    BEGIN
--
      --WF�v���Z�X���쐬
      WF_ENGINE.CREATEPROCESS(gr_outbound_rec.wf_name, lv_itemkey, gr_outbound_rec.wf_name);
--
      --WF�I�[�i�[��ݒ�
      WF_ENGINE.SETITEMOWNER(gr_outbound_rec.wf_name, lv_itemkey, gr_outbound_rec.wf_owner);
--
      --WF������ݒ�
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_NAME',
                                  gr_outbound_rec.directory|| ',' ||gr_outbound_rec.file_name );
      -- �ʒm�惆�[�U�[01
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD01',
                                  gr_outbound_rec.user_cd01);
      -- �ʒm�惆�[�U�[02
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD02',
                                  gr_outbound_rec.user_cd02);
      -- �ʒm�惆�[�U�[03
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD03',
                                  gr_outbound_rec.user_cd03);
      -- �ʒm�惆�[�U�[04
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD04',
                                  gr_outbound_rec.user_cd04);
      -- �ʒm�惆�[�U�[05
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD05',
                                  gr_outbound_rec.user_cd05);
      -- �ʒm�惆�[�U�[06
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD06',
                                  gr_outbound_rec.user_cd06);
      -- �ʒm�惆�[�U�[07
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD07',
                                  gr_outbound_rec.user_cd07);
      -- �ʒm�惆�[�U�[08
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD08',
                                  gr_outbound_rec.user_cd08);
      -- �ʒm�惆�[�U�[09
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD09',
                                  gr_outbound_rec.user_cd09);
      -- �ʒm�惆�[�U�[10
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'USER_CD10',
                                  gr_outbound_rec.user_cd10);
--
      WF_ENGINE.SETITEMATTRTEXT(gr_outbound_rec.wf_name,
                                  lv_itemkey,
                                  'FILE_DISP_NAME',
                                  gr_outbound_rec.file_display_name);
--
      --WF�v���Z�X���N��
      WF_ENGINE.STARTPROCESS(gr_outbound_rec.wf_name, lv_itemkey);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_com_name,
                                              gv_tkn_xxcmn_10117);
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END workflow_start;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_prod_class        IN            VARCHAR2,  --  4.���i�敪          (�K�{)
    iv_item_class        IN            VARCHAR2,  --  5.�i�ڋ敪          (�K�{)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.��\�q�ɋ敪      (�C��)
    iv_whse              IN            VARCHAR2,  --  7.�q��              (�C��)
    iv_vendor_id         IN            VARCHAR2,  --  8.�����            (�C��)
    iv_item_no           IN            VARCHAR2,  --  9.�i��              (�C��)
    iv_lot_no            IN            VARCHAR2,  -- 10.���b�g            (�C��)
    iv_manufacture_date  IN            VARCHAR2,  -- 11.������            (�C��)
    iv_expiration_date   IN            VARCHAR2,  -- 12.�ܖ�����          (�C��)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.�ŗL�L��          (�C��)
    iv_mf_factory        IN            VARCHAR2,  -- 14.�����H��          (�C��)
    iv_mf_lot            IN            VARCHAR2,  -- 15.�������b�g        (�C��)
    iv_home              IN            VARCHAR2,  -- 16.�Y�n              (�C��)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (�C��)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (�C��)
    iv_sec_class         IN            VARCHAR2,  -- 19.�Z�L�����e�B�敪  (�K�{)
    ov_errbuf               OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tbl_name    CONSTANT VARCHAR2(200) := '���b�g�݌ɏ��';
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
    ov_retcode := gv_status_normal;
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
    -- �p�����[�^�o��
    parameter_disp(
      iv_wf_ope_div,        --  1.�����敪
      iv_wf_class,          --  2.�Ώ�
      iv_wf_notification,   --  3.����
      iv_prod_class,        --  4.���i�敪
      iv_item_class,        --  5.�i�ڋ敪
      iv_frequent_whse_div, --  6.��\�q�ɋ敪
      iv_whse,              --  7.�q��
      iv_vendor_id,         --  8.�����
      iv_item_no,           --  9.�i��
      iv_lot_no,            -- 10.���b�g
      iv_manufacture_date,  -- 11.������
      iv_expiration_date,   -- 12.�ܖ�����
      iv_uniqe_sign,        -- 13.�ŗL�L��
      iv_mf_factory,        -- 14.�����H��
      iv_mf_lot,            -- 15.�������b�g
      iv_home,              -- 16.�Y�n
      iv_r1,                -- 17.R1
      iv_r2,                -- 18.R2
      iv_sec_class,         -- 19.�Z�L�����e�B�敪
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      ���b�g�݌ɏ��擾����(C-1)      ***
    --*********************************************
    get_lot_inf_proc(
      lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �f�[�^�擾���ꂽ�ꍇ
    IF (gt_master_tbl.COUNT > 0) THEN
      --*********************************************
      --***        CSV�t�@�C���o��(C-2)           ***
      --*********************************************
      csv_file_proc(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    -- �f�[�^�擾����Ȃ������ꍇ
    ELSE
--
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_app_name,
                                            gv_tkn_xxpo_10026,
                                            gv_tkn_table,
                                            lv_tbl_name);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
      lv_retcode := gv_status_warn;
    END IF;
--
    IF (lv_retcode = gv_status_normal) THEN
      --*********************************************
      --***       Workflow�ʒm����(C-3)           ***
      --*********************************************
      workflow_start(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    ELSE
      ov_retcode := lv_retcode;
    END IF;
--
    gn_target_cnt := gt_master_tbl.COUNT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf                  OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                 OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h    --# �Œ� #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.�����敪          (�K�{)
    iv_wf_class          IN            VARCHAR2,  --  2.�Ώ�              (�K�{)
    iv_wf_notification   IN            VARCHAR2,  --  3.����              (�K�{)
    iv_prod_class        IN            VARCHAR2,  --  4.���i�敪          (�K�{)
    iv_item_class        IN            VARCHAR2,  --  5.�i�ڋ敪          (�K�{)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.��\�q�ɋ敪      (�C��)
    iv_whse              IN            VARCHAR2,  --  7.�q��              (�C��)
    iv_vendor_id         IN            VARCHAR2,  --  8.�����            (�C��)
    iv_item_no           IN            VARCHAR2,  --  9.�i��              (�C��)
    iv_lot_no            IN            VARCHAR2,  -- 10.���b�g            (�C��)
    iv_manufacture_date  IN            VARCHAR2,  -- 11.������            (�C��)
    iv_expiration_date   IN            VARCHAR2,  -- 12.�ܖ�����          (�C��)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.�ŗL�L��          (�C��)
    iv_mf_factory        IN            VARCHAR2,  -- 14.�����H��          (�C��)
    iv_mf_lot            IN            VARCHAR2,  -- 15.�������b�g        (�C��)
    iv_home              IN            VARCHAR2,  -- 16.�Y�n              (�C��)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (�C��)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (�C��)
    iv_sec_class         IN            VARCHAR2   -- 19.�Z�L�����e�B�敪  (�K�{)
    )
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
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_wf_ope_div,        --  1.�����敪
      iv_wf_class,          --  2.�Ώ�
      iv_wf_notification,   --  3.����
      iv_prod_class,        --  4.���i�敪
      iv_item_class,        --  5.�i�ڋ敪
      iv_frequent_whse_div, --  6.��\�q�ɋ敪
      iv_whse,              --  7.�q��
      iv_vendor_id,         --  8.�����
      iv_item_no,           --  9.�i��
      iv_lot_no,            -- 10.���b�g
      iv_manufacture_date,  -- 11.������
      iv_expiration_date,   -- 12.�ܖ�����
      iv_uniqe_sign,        -- 13.�ŗL�L��
      iv_mf_factory,        -- 14.�����H��
      iv_mf_lot,            -- 15.�������b�g
      iv_home,              -- 16.�Y�n
      iv_r1,                -- 17.R1
      iv_r2,                -- 18.R2
      iv_sec_class,         -- 19.�Z�L�����e�B�敪
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type,
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxpo940003c;
/
