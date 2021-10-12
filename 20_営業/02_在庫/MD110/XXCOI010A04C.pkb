CREATE OR REPLACE PACKAGE BODY APPS.XXCOI010A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A04C(body)
 * Description      : ���_�ň����i�ڂ̑g�������𒊏o��CSV�t�@�C�����쐬���ĘA�g����B
 * MD.050           : ���_�i�ڏ��HHT�A�g MD050_COI_010_A04
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_item_record        ���_�i��CSV�쐬����(A-4)
 *  create_tmp             ���_�i�ڎ擾����(A-3)
 *  init                   ��������(A-1)
 *  submain                ���C�������v���V�[�W��
 *                           �E�t�@�C���̃I�[�v������(A-2)
 *                           �E�I������(A-5)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/04/05    1.0   H.Sekine         main�V�K�쐬
 *  2011/09/05    1.1   K.Nakamura       [E_�{�ғ�_08224]�Ǘ������_�̎擾����ǉ�
 *  2018/01/11    1.2   H.Sasaki         [E_�{�ғ�_14486]�A�g���ڂɏo�Ɍ��q�ɂ�ǉ�
 *  2021/09/24    1.3   K.Tomie          [E_�{�ғ�_17549]���_�i�ڏ��HHT�A�g�̏o�Ɍ��q�ɂ�1�ɂ���
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################

--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                                            -- �Ώی���
  gn_normal_cnt    NUMBER;                                            -- ���팏��
  gn_error_cnt     NUMBER;                                            -- �G���[����
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
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(20)  := 'XXCOI010A04C';               -- �p�b�P�[�W��
  cv_application             CONSTANT VARCHAR2(10)  := 'XXCCP';                      -- �A�v���P�[�V������
  cv_xxcos_appl_short_name   CONSTANT VARCHAR2(10)  := 'XXCOI';                      -- �݌ɒZ�k�A�v����
  -- ���b�Z�[�W
  cv_target_rec_msg          CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';           -- �Ώی������b�Z�[�W
  cv_success_rec_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';           -- �����������b�Z�[�W
  cv_error_rec_msg           CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';           -- �G���[�������b�Z�[�W
  cv_normal_msg              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90004';           -- ����I�����b�Z�[�W
  cv_error_msg               CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90006';           -- �G���[�I���S���[���o�b�N
  cv_msg_parameter_note      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10316';           -- �p�����[�^�o�̓��b�Z�[�W
  cv_conc_not_parm_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';           -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_not_found_data_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00008';           -- �Ώۃf�[�^����
  cv_date_err_msg            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10240';           -- ���t�p�����[�^�G���[
  cv_future_date_err_msg     CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10400';           -- �Ώۓ����������b�Z�[�W
  cv_prf_org_err_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';           -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_prf_ship_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10168';           -- �o�׈˗��X�e�[�^�X�R�[�h�擾�G���[���b�Z�[�W
  cv_bulk_cnt_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00032';           -- �v���t�@�C���l�擾�G���[���b�Z�[�W
  cv_org_id_err_msg          CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';           -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_prf_itou_ou_mfg_err_msg CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10338';           -- ���Y�c�ƒP�ʎ擾���̎擾�G���[���b�Z�[�W
  cv_prf_no_file_msg         CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00027';           -- �t�@�C�����݃`�F�b�N�G���[
  cv_prf_file_name_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';           -- �t�@�C�����o�̓��b�Z�[�W
  cv_prf_dire_err_msg        CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00003';           -- �f�B���N�g�����擾�G���[
  cv_prf_file_name_err_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00004';           -- �t�@�C�����擾�G���[
  cv_full_path_err_msg       CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';           -- �f�B���N�g���t���p�X�擾�G���[
  cv_prf_notice_err_msg      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10169';           -- �ʒm�X�e�[�^�X�R�[�h�擾�G���[���b�Z�[�W
  cv_process_date_expt_msg   CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';           -- �Ɩ����t�擾�G���[���b�Z�[�W
  --�g�[�N��
  cv_cnt_token               CONSTANT VARCHAR2(20)  := 'COUNT';                      -- ����
  cv_tkn_para_date           CONSTANT VARCHAR2(20)  := 'P_DATE';                     -- �Ɩ����t
  cv_tkn_pro                 CONSTANT VARCHAR2(20)  := 'PRO_TOK';                    -- �v���t�@�C����
  cv_tkn_org                 CONSTANT VARCHAR2(20)  := 'ORG_CODE_TOK';               -- �݌ɑg�D
  cv_tkn_dir                 CONSTANT VARCHAR2(20)  := 'DIR_TOK';                    -- �f�B���N�g����
  cv_tkn_file_name           CONSTANT VARCHAR2(20)  := 'FILE_NAME';                  -- �t�@�C����
  -- �v���t�@�C���I�v�V����
  cv_prf_org                 CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';   -- XXCOI:�݌ɑg�D�R�[�h
  cv_prf_ship_status_close   CONSTANT VARCHAR2(30)  := 'XXCOI1_SHIP_STATUS_CLOSE';   -- XXCOI:�o�׈˗��X�e�[�^�X_���ߍς�
  cv_prf_ship_status_result  CONSTANT VARCHAR2(30)  := 'XXCOI1_SHIP_STATUS_RESULTS'; -- XXCOI:�o�׈˗��X�e�[�^�X_�o�׎��ьv���
  cv_prf_notice_status       CONSTANT VARCHAR2(30)  := 'XXCOI1_NOTICE_STATUS_CLOSE'; -- XXCOI:�ʒm�X�e�[�^�X_�m��ʒm��
  cv_prf_itou_ou_mfg         CONSTANT VARCHAR2(30)  := 'XXCOI1_ITOE_OU_MFG';         -- XXCOI:���Y�c�ƒP�ʎ擾����
  cv_prf_dire_out_hht        CONSTANT VARCHAR2(30)  := 'XXCOI1_DIRE_OUT_HHT';        -- XXCOI:HHT_OUTBOUND�i�[�f�B���N�g���p�X
  cv_prf_file_base_item      CONSTANT VARCHAR2(30)  := 'XXCOI1_FILE_BASE_ITEM';      -- XXCOI:���_�i��IF�o�̓t�@�C����
  cv_base_code_item_bulk_cnt CONSTANT VARCHAR2(30)  := 'XXCOI1_BASE_CODE_ITEM_BULK_CNT';
                                                                                     -- XXCOI:���_�i�ڏ��擾����(�o���N)
  cv_prf_base_code_item_term CONSTANT VARCHAR2(30)  := 'XXCOI1_BASE_CODE_ITEM_TERM'; -- XXCOI:���_�i�ڏ��擾����        --  V1.2 2018/01/11 Added
  --
  cv_y                       CONSTANT VARCHAR2(1)   := 'Y';                          -- �t���O�l:Y
  cv_n                       CONSTANT VARCHAR2(1)   := 'N';                          -- �t���O�l:N
  cv_status_a                CONSTANT VARCHAR2(1)   := 'A';                          -- �t���O�l:A
  cv_class_code_1            CONSTANT VARCHAR2(1)   := '1';                          -- �ڋq�敪:1�i���_�j
  cv_shukka_shikyuu_kbn_1    CONSTANT VARCHAR2(1)   := '1';                          -- �o�׎x���敪:1
  cv_zaiko_chousei_kbn_1     CONSTANT VARCHAR2(1)   := '1';                          -- �݌ɒ����敪:1
-- == 2011/09/05 V1.1 Added START    ===============================================================
  cv_dept_hht_div_1          CONSTANT VARCHAR2(1)   := '1';                          -- �S�ݓXHHT�敪:1�i���_���j
-- == 2011/09/05 V1.1 Added END      ===============================================================
  cv_date_mask_1             CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';      -- ���t�����}�X�N(YYYY/MM/DD HH24:MM:SS)
  cv_date_mask_2             CONSTANT VARCHAR2(10)  := 'YYYYMM';                     -- ���t�����}�X�N(YYYYMM)
  cv_file_slash              CONSTANT VARCHAR2(1)   := '/';                          -- �t�@�C����؂�p
  cv_csv_com                 CONSTANT VARCHAR2(1)   := ',';                          -- CSV�f�[�^��؂�p
  cv_csv_encloser            CONSTANT VARCHAR2(1)   := '"';                          -- CSV�f�[�^����p
  cv_file_mode_w             CONSTANT VARCHAR2(1)   := 'W';                          -- �I�[�v�����[�h:W
  cv_deliver_from_null       CONSTANT VARCHAR2(4)   := '9999';                       -- �o�Ɍ��q�ɌŒ�l                  --  V1.2 2018/01/11 Added
  cv_deliver_from_name_null  CONSTANT VARCHAR2(20)  := '�Y���Ȃ�';                   -- �o�Ɍ��q�ɖ��Œ�l                --  V1.2 2018/01/11 Added
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_org_code                 mtl_parameters.organization_code%TYPE;      -- �݌ɑg�D�R�[�h
  gt_org_id                   mtl_parameters.organization_id%TYPE;        -- �݌ɑg�DID
  gt_ship_status_close        xxwsh_order_headers_all.req_status%TYPE;    -- �o�׈˗��X�e�[�^�X_���ߍς�
  gt_ship_status_result       xxwsh_order_headers_all.req_status%TYPE;    -- �o�׈˗��X�e�[�^�X_�o�׎��ьv���
  gt_notice_status            xxwsh_order_headers_all.notif_status%TYPE;  -- �ʒm�X�e�[�^�X_�m��ʒm��;
  gt_seisan_org_name          hr_organization_units.name%TYPE;            -- ���Y�c�ƒP�ʖ���
  gt_itou_ou_id               hr_organization_units.organization_id%TYPE; -- ���Y�g�DID
  gv_dire_name                VARCHAR2(100);                              -- �f�B���N�g������
  gv_dire_out_hht             VARCHAR2(150);                              -- HHT_OUTBOUND�i�[�f�B���N�g���p�X
  gv_file_base_item           VARCHAR2(100);                              -- ���_�i��IF�o�̓t�@�C����
  gv_full_path                VARCHAR2(150);                              -- �t�@�C���p�X���擾�p
  gf_activ_file_h             UTL_FILE.FILE_TYPE;                         -- �t�@�C���n���h���擾�p
  gd_process_date             DATE;                                       -- �Ɩ����t
  gd_target_date              DATE;                                       -- �����Ώۓ�
  gv_limit_num                VARCHAR2(100);                              -- �o���N�p���~�b�g����(�_�~�[)
  gn_limit_num                NUMBER;                                     -- �o���N�p���~�b�g����
  gn_target_term              NUMBER;                                     -- ���_�i�ڏ��擾����                 --  V1.2 2018/01/11 Added
--
  /**********************************************************************************
   * Procedure Name   : get_item_record
   * Description      : ���_�i��CSV�쐬����(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_record(
      ov_errbuf      OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode     OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg      OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_record';                   -- �v���O������
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
    lv_base_code_item_csv     VARCHAR2(500);                          -- CSV�o�͗p�ϐ�
    lv_sysdate                VARCHAR2(30);                           -- SYSDATE(CSV�p)
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���_�i�ڏ��擾
    CURSOR base_code_item_cur
    IS
--  V1.2 2018/01/11 Modified START
--      -- �����݌Ɏ󕥕\(�݌v)
---- == 2011/09/05 V1.1 Modified START ===============================================================
----      SELECT   xirs.base_code                  base_code              -- ���_�R�[�h
--      SELECT   DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, xirs.base_code)
--                                               base_code              -- ���_�R�[�h
---- == 2011/09/05 V1.1 Modified END   ===============================================================
--             , msib.segment1                   item_no                -- �i�ڃR�[�h
--      FROM     xxcoi_inv_reception_sum         xirs                   -- �����݌Ɏ󕥕\�i�݌v�j
--             , mtl_system_items_b              msib                   -- Disc�i�ڃ}�X�^
---- == 2011/09/05 V1.1 Added START    ===============================================================
--             , hz_cust_accounts                hca                    -- �ڋq�}�X�^
--             , xxcmm_cust_accounts             xca                    -- �ڋq�ǉ����}�X�^
---- == 2011/09/05 V1.1 Added END      ===============================================================
--      WHERE    msib.inventory_item_id = xirs.inventory_item_id
--      AND      msib.organization_id   = xirs.organization_id
--      AND      xirs.organization_id   = gt_org_id
--      AND      xirs.practice_date     = TO_CHAR(gd_target_date, cv_date_mask_2 )
---- == 2011/09/05 V1.1 Added START    ===============================================================
--      AND      hca.cust_account_id     = xca.customer_id
--      AND      hca.customer_class_code = cv_class_code_1
--      AND      hca.account_number      = xirs.base_code
---- == 2011/09/05 V1.1 Added END      ===============================================================
---- == 2011/09/05 V1.1 Modified START ===============================================================
----      GROUP by xirs.base_code
--      GROUP by DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, xirs.base_code)
---- == 2011/09/05 V1.1 Modified END   ===============================================================
--             , msib.segment1
--      --
--      UNION
--      --
--      -- �o�׈˗�/����
---- == 2011/09/05 V1.1 Modified START ===============================================================
----      SELECT  hca.account_number               base_code              -- ���_�R�[�h
--      SELECT  DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number)
--                                               base_code              -- ���_�R�[�h
---- == 2011/09/05 V1.1 Modified END   ===============================================================
--            , imbp.item_no                     item_no                -- �i�ڃR�[�h
--      FROM    xxwsh_order_headers_all          xoha                   -- �󒍃w�b�_�A�h�I��
--            , xxwsh_order_lines_all            xola                   -- �󒍖��׃A�h�I��
--            , ic_item_mst_b                    imbc                   -- OPM�i�ڃ}�X�^�i�q�j
--            , ic_item_mst_b                    imbp                   -- OPM�i�ڃ}�X�^�i�e�j
--            , xxcmn_item_mst_b                 ximb                   -- OPM�i�ڃA�h�I���}�X�^
--            , mtl_system_items_b               msib                   -- Disc�i�ڃ}�X�^
--            , hz_cust_accounts                 hca                    -- �ڋq�}�X�^
---- == 2011/09/05 V1.1 Added START    ===============================================================
--            , xxcmm_cust_accounts              xca                    -- �ڋq�ǉ����}�X�^
---- == 2011/09/05 V1.1 Added END      ===============================================================
--            , oe_transaction_types_all         otta                   -- �󒍃^�C�v�}�X�^
--            , hz_party_sites                   hps                    -- �p�[�e�B�T�C�g�}�X�^
--      WHERE  xoha.order_header_id   =   xola.order_header_id
--      AND    xola.request_item_id   =   msib.inventory_item_id
--      AND    imbc.item_no           =   msib.segment1
--      AND    imbc.item_id           =   ximb.item_id
--      AND    imbp.item_id           =   ximb.parent_item_id
--      AND    msib.organization_id   =   gt_org_id
--      AND ( (  -- ���ߍς݁A�m��ʒm�Ϗo�׈˗�
--                  xoha.req_status            = gt_ship_status_close
--              AND xoha.notif_status          = gt_notice_status
--              AND xoha.schedule_arrival_date = gd_target_date + 1
--              AND xoha.deliver_to_id         = hps.party_site_id
--              AND 
--              xoha.schedule_arrival_date BETWEEN ximb.start_date_active
--                                         AND     NVL(ximb.end_date_active, xoha.schedule_arrival_date )
--            )
--         OR (  -- �o�׎��ьv��Ϗo�׎���
--                  xoha.req_status            = gt_ship_status_result
--              AND xoha.actual_confirm_class  = cv_y
--              AND xoha.arrival_date          = gd_target_date + 1
--              AND xoha.result_deliver_to_id  = hps.party_site_id
--              AND
--              xoha.arrival_date BETWEEN ximb.start_date_active
--                                         AND     NVL(ximb.end_date_active, xoha.arrival_date )
--            ) )
--      AND     NVL(xola.delete_flag, cv_n ) = cv_n
--      AND     otta.attribute1              = cv_shukka_shikyuu_kbn_1
--      AND     NVL(otta.attribute4, cv_zaiko_chousei_kbn_1 ) = cv_zaiko_chousei_kbn_1
--      AND     hps.party_id                 = hca.party_id
--      AND     otta.org_id                  = gt_itou_ou_id 
--      AND     xoha.order_type_id           = otta.transaction_type_id
--      AND     hca.customer_class_code      = cv_class_code_1
--      AND     hca.status                   = cv_status_a
--      AND     xoha.latest_external_flag    = cv_y
---- == 2011/09/05 V1.1 Added START    ===============================================================
--      AND     hca.cust_account_id          = xca.customer_id
---- == 2011/09/05 V1.1 Added END      ===============================================================
---- == 2011/09/05 V1.1 Modified START ===============================================================
----      GROUP BY hca.account_number
--      GROUP BY DECODE(xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number)
---- == 2011/09/05 V1.1 Modified END   ===============================================================
--             , imbp.item_no
--      ORDER BY base_code
--             , item_no;
    --
      SELECT  xbit.base_code              AS  "BASE_CODE"                 --  ���_�R�[�h
            , xbit.item_number            AS  "ITEM_NUMBER"               --  �i��
            , xbit.deliver_from           AS  "DELIVER_FROM"              --  �o�Ɍ��q�ɃR�[�h
            , xbit.deliver_from_name      AS  "DELIVER_FROM_NAME"         --  �o�Ɍ��q�ɖ�
      FROM    xxcoi_base_item_tmp   xbit                                  --  ���_�i�ڏ��A�g�ꎞ�\
      ORDER BY  xbit.base_code
              , xbit.item_number
              , xbit.deliver_from
      ;
--  V1.2 2018/01/11 Modified END
--
    -- *** ���[�J���E���R�[�h ***
    --
    TYPE l_base_code_item_ttype IS TABLE OF base_code_item_cur%ROWTYPE INDEX BY PLS_INTEGER;
    l_base_code_item_tab        l_base_code_item_ttype;
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
    -- SYSDATE(CSV�p)�ϐ���SYSDATE��ݒ肷��
    lv_sysdate := TO_CHAR(SYSDATE, cv_date_mask_1 );
    --
    -- CSV�o�͗p�ϐ���������
    lv_base_code_item_csv := NULL;
    --
    -- ���_�i�ڏ��J�[�\���I�[�v��
    OPEN base_code_item_cur;
    --
    LOOP
      --
      EXIT WHEN base_code_item_cur%NOTFOUND;
      --
      --�e�[�u���ϐ��̏�����
      l_base_code_item_tab.DELETE;
      --
      --���R�[�h�ǂݍ���
      FETCH base_code_item_cur BULK COLLECT INTO l_base_code_item_tab LIMIT gn_limit_num;
      --
      --���[�v�̊J�n
      <<base_code_item_loop>>
      FOR ln_index IN 1..l_base_code_item_tab.COUNT LOOP
        -- ===============================
        -- A-4.���_�i��CSV�쐬����
        -- ===============================
        --
        -- �Ώی����擾
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- �J�[�\���Ŏ擾�����l��CSV�t�@�C���Ɋi�[
--  V1.2 2018/01/11 Modified START
--        lv_base_code_item_csv :=                cv_csv_encloser || l_base_code_item_tab( ln_index ).base_code || cv_csv_encloser ||
--                                 cv_csv_com ||  cv_csv_encloser || l_base_code_item_tab( ln_index ).item_no   || cv_csv_encloser ||
--                                 cv_csv_com ||  cv_csv_encloser || lv_sysdate                                 || cv_csv_encloser;
        lv_base_code_item_csv :=
                          cv_csv_encloser ||  l_base_code_item_tab( ln_index ).base_code          ||  cv_csv_encloser ||          --  ���_�R�[�h
          cv_csv_com  ||  cv_csv_encloser ||  l_base_code_item_tab( ln_index ).item_number        ||  cv_csv_encloser ||          --  ���i�R�[�h
          cv_csv_com  ||  cv_csv_encloser ||  l_base_code_item_tab( ln_index ).deliver_from       ||  cv_csv_encloser ||          --  �o�Ɍ��q�ɃR�[�h
          cv_csv_com  ||  cv_csv_encloser ||  l_base_code_item_tab( ln_index ).deliver_from_name  ||  cv_csv_encloser ||          --  �o�Ɍ��q�ɖ�
          cv_csv_com  ||  cv_csv_encloser ||  lv_sysdate                                          ||  cv_csv_encloser             --  �A�g����
        ;
--  V1.2 2018/01/11 Modified END
        --
        -- CSV�t�@�C�����o��
        UTL_FILE.PUT_LINE(
            gf_activ_file_h       -- �t�@�C���n���h��
          , lv_base_code_item_csv -- CSV�o�͍���
          );
        --
        -- ���팏���ɉ��Z
        gn_normal_cnt := gn_normal_cnt + 1;
      --
      --���[�v�̏I��
      END LOOP base_code_item_loop;
    --
    END LOOP;
    --
    --�J�[�\���̃N���[�Y
    CLOSE base_code_item_cur;
    --
    -- �Ώۃf�[�^��0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
      --
      -- �Ώۃf�[�^�������b�Z�[�W
      gv_out_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_name
                      , iv_name         => cv_not_found_data_msg
                      );
      --
      -- ��s���o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => NULL
      );
      --
      -- ���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
        , buff   => gv_out_msg
      );
    --
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END get_item_record;
--
--  V1.2 2018/01/11 Added START
  /**********************************************************************************
   * Procedure Name   : create_tmp
   * Description      : ���_�i�ڎ擾����(A-3)
   ***********************************************************************************/
  PROCEDURE create_tmp(
      ov_errbuf      OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode     OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg      OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_tmp';                   -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
  BEGIN
    --  ==============================================================
    --  �󒍏��i�o�׎��ьv��ρj���o
    --  ==============================================================
    --  �o�׎��ьv��ς̃f�[�^�����_�i�ڏ��A�g�ꎞ�\�ɓo�^����
    --  ���o�͈͂́Agn_target_term���O����Ɩ����t�̗����܂�
    INSERT INTO xxcoi_base_item_tmp(
        base_code                       --  ���_�R�[�h
      , item_number                     --  �i�ڃR�[�h
      , deliver_from                    --  �o�Ɍ��q��
      , deliver_from_name               --  �o�Ɍ��q�ɖ�
    )
--Ver1.3 Del start
--      SELECT  /*+ INDEX( ximb XXCMN_IMB_N01 ) */
--              DISTINCT
--              DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
--                                          AS  "BASE_CODE"             --  ���_�R�[�h
--            , imbp.item_no                AS  "ITEM_NUMBER"           --  �i�ڃR�[�h
--            , xoha.deliver_from           AS  "DELIVER_FROM"          --  �o�Ɍ��q��
--            , xilv.description            AS  "DELIVER_FROM_NAME"     --  �o�Ɍ��q�ɖ�
--      FROM    xxwsh_order_headers_all   xoha                          --  �󒍃w�b�_�A�h�I��
--            , xxwsh_order_lines_all     xola                          --  �󒍖��׃A�h�I��
--            , oe_transaction_types_all  otta                          --  �󒍃^�C�v�}�X�^
--            , mtl_system_items_b        msib                          --  DISC�i�ڃ}�X�^
--            , ic_item_mst_b             imbc                          --  OPM�i�ڃ}�X�^�i�q�j
--            , xxcmn_item_mst_b          ximb                          --  OPM�i�ڃA�h�I���}�X�^
--            , ic_item_mst_b             imbp                          --  OPM�i�ڃ}�X�^�i�e�j
--            , hz_party_sites            hps                           --  �p�[�e�B�T�C�g
--            , hz_cust_accounts          hca                           --  �ڋq�}�X�^
--            , xxcmm_cust_accounts       xca                           --  �ڋq�ǉ����}�X�^
--            , xxcmn_item_locations2_v   xilv                          --  OPM�ۊǏꏊ
--      WHERE   xoha.req_status                                 =   gt_ship_status_result         --  �o�׎��ьv���
--      AND     xoha.actual_confirm_class                       =   cv_y
--      AND     xoha.arrival_date                               >=  TRUNC( gd_target_date ) - gn_target_term
--      AND     xoha.arrival_date                               <   TRUNC( gd_target_date + 1 ) + 1
--      AND     xoha.latest_external_flag                       =   cv_y
--      AND     xoha.order_header_id                            =   xola.order_header_id
--      AND     NVL( xola.delete_flag, cv_n )                   =   cv_n
--      AND     xoha.order_type_id                              =   otta.transaction_type_id
--      AND     otta.org_id                                     =   gt_itou_ou_id
--      AND     otta.attribute1                                 =   cv_shukka_shikyuu_kbn_1
--      AND     NVL( otta.attribute4, cv_zaiko_chousei_kbn_1 )  =   cv_zaiko_chousei_kbn_1
--      AND     xola.request_item_id                            =   msib.inventory_item_id
--      AND     msib.organization_id                            =   gt_org_id
--      AND     msib.segment1                                   =   imbc.item_no
--      AND     imbc.item_id                                    =   ximb.item_id
--      AND     xoha.arrival_date BETWEEN ximb.start_date_active AND NVL( ximb.end_date_active, xoha.arrival_date )
--      AND     ximb.parent_item_id                             =   imbp.item_id
--      AND     xoha.result_deliver_to_id                       =   hps.party_site_id
--      AND     hps.party_id                                    =   hca.party_id
--      AND     hca.customer_class_code                         =   cv_class_code_1
--      AND     hca.status                                      =   cv_status_a
--      AND     hca.cust_account_id                             =   xca.customer_id
--      AND     xoha.deliver_from                               =   xilv.segment1
--Ver1.3 Del end
--Ver1.3 Add start
      SELECT
         BASE_CODE
        ,ITEM_NUMBER
        ,DELIVER_FROM
        ,DELIVER_FROM_NAME
      FROM
        (
          SELECT  /*+ INDEX( ximb XXCMN_IMB_N01 ) */
                  DISTINCT
                  DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
                                              AS  "BASE_CODE"             --  ���_�R�[�h
                , imbp.item_no                AS  "ITEM_NUMBER"           --  �i�ڃR�[�h
                , xoha.deliver_from           AS  "DELIVER_FROM"          --  �o�Ɍ��q��
                , xilv.description            AS  "DELIVER_FROM_NAME"     --  �o�Ɍ��q�ɖ�
                , xoha.arrival_date           AS "ARRIVAL_DATE"           --  ����
                , row_number() over( 
                    partition by              -- �W�v�L�[�F���_�A�i�ڕ�
                        DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
                      , imbp.item_no
                    order by                  -- �\�[�g�F�����~���A�o�Ɍ��q��
                        xoha.arrival_date desc
                      , xoha.deliver_from  
                    )                         AS row_number               -- ���я�
          FROM    xxwsh_order_headers_all   xoha                          --  �󒍃w�b�_�A�h�I��
                , xxwsh_order_lines_all     xola                          --  �󒍖��׃A�h�I��
                , oe_transaction_types_all  otta                          --  �󒍃^�C�v�}�X�^
                , mtl_system_items_b        msib                          --  DISC�i�ڃ}�X�^
                , ic_item_mst_b             imbc                          --  OPM�i�ڃ}�X�^�i�q�j
                , xxcmn_item_mst_b          ximb                          --  OPM�i�ڃA�h�I���}�X�^
                , ic_item_mst_b             imbp                          --  OPM�i�ڃ}�X�^�i�e�j
                , hz_party_sites            hps                           --  �p�[�e�B�T�C�g
                , hz_cust_accounts          hca                           --  �ڋq�}�X�^
                , xxcmm_cust_accounts       xca                           --  �ڋq�ǉ����}�X�^
                , xxcmn_item_locations2_v   xilv                          --  OPM�ۊǏꏊ
          WHERE   xoha.req_status                                 =   gt_ship_status_result         --  �o�׎��ьv���
          AND     xoha.actual_confirm_class                       =   cv_y
          AND     xoha.arrival_date                               >=  TRUNC( gd_target_date ) - gn_target_term
          AND     xoha.arrival_date                               <   TRUNC( gd_target_date + 1 ) + 1
          AND     xoha.latest_external_flag                       =   cv_y
          AND     xoha.order_header_id                            =   xola.order_header_id
          AND     NVL( xola.delete_flag, cv_n )                   =   cv_n
          AND     xoha.order_type_id                              =   otta.transaction_type_id
          AND     otta.org_id                                     =   gt_itou_ou_id
          AND     otta.attribute1                                 =   cv_shukka_shikyuu_kbn_1
          AND     NVL( otta.attribute4, cv_zaiko_chousei_kbn_1 )  =   cv_zaiko_chousei_kbn_1
          AND     xola.request_item_id                            =   msib.inventory_item_id
          AND     msib.organization_id                            =   gt_org_id
          AND     msib.segment1                                   =   imbc.item_no
          AND     imbc.item_id                                    =   ximb.item_id
          AND     xoha.arrival_date BETWEEN ximb.start_date_active AND NVL( ximb.end_date_active, xoha.arrival_date )
          AND     ximb.parent_item_id                             =   imbp.item_id
          AND     xoha.result_deliver_to_id                       =   hps.party_site_id
          AND     hps.party_id                                    =   hca.party_id
          AND     hca.customer_class_code                         =   cv_class_code_1
          AND     hca.status                                      =   cv_status_a
          AND     hca.cust_account_id                             =   xca.customer_id
          AND     xoha.deliver_from                               =   xilv.segment1
        )
      WHERE  row_number = 1
--Ver1.3 Add end
    ;
    --  ==============================================================
    --  �󒍏��i���ߍρE�m��ʒm�ρj���o
    --  ==============================================================
    --  ���ߍρE�m��ʒm�ς̃f�[�^�����_�i�ڏ��A�g�ꎞ�\�ɓo�^����
    --  �������A���_�A�i�ځA�o�׌��q�ɂŊ��ɓo�^�ς݂̏ꍇ�͏��O����
    INSERT INTO xxcoi_base_item_tmp(
        base_code                       --  ���_�R�[�h
      , item_number                     --  �i�ڃR�[�h
      , deliver_from                    --  �o�Ɍ��q��
      , deliver_from_name               --  �o�Ɍ��q�ɖ�
    )
--Ver1.3 Del start
--      SELECT  /*+ INDEX( imbc IC_ITEM_MST_B_UNQ1 )
--                  INDEX( ximb XXCMN_IMB_N01 )
--              */
--              DISTINCT
--              DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
--                                          AS  "BASE_CODE"             --  ���_�R�[�h
--            , imbp.item_no                AS  "ITEM_NUMBER"           --  �i�ڃR�[�h
--            , xoha.deliver_from           AS  "DELIVER_FROM"          --  �o�Ɍ��q��
--            , xilv.description            AS  "DELIVER_FROM_NAME"     --  �o�Ɍ��q�ɖ�
--      FROM    xxwsh_order_headers_all   xoha                          --  �󒍃w�b�_�A�h�I��
--            , xxwsh_order_lines_all     xola                          --  �󒍖��׃A�h�I��
--            , oe_transaction_types_all  otta                          --  �󒍃^�C�v�}�X�^
--            , mtl_system_items_b        msib                          --  DISC�i�ڃ}�X�^
--            , ic_item_mst_b             imbc                          --  OPM�i�ڃ}�X�^�i�q�j
--            , xxcmn_item_mst_b          ximb                          --  OPM�i�ڃA�h�I���}�X�^
--            , ic_item_mst_b             imbp                          --  OPM�i�ڃ}�X�^�i�e�j
--            , hz_party_sites            hps                           --  �p�[�e�B�T�C�g
--            , hz_cust_accounts          hca                           --  �ڋq�}�X�^
--            , xxcmm_cust_accounts       xca                           --  �ڋq�ǉ����}�X�^
--            , xxcmn_item_locations2_v   xilv                          --  OPM�ۊǏꏊ
--      WHERE   xoha.req_status                                 =   gt_ship_status_close          --  ���ߍς�
--      AND     xoha.notif_status                               =   gt_notice_status              --  �m��ʒm�ς�
--      AND     xoha.schedule_arrival_date                      >=  TRUNC( gd_target_date ) - gn_target_term
--      AND     xoha.schedule_arrival_date                      <   TRUNC( gd_target_date + 1 ) + 1
--      AND     xoha.latest_external_flag                       =   cv_y
--      AND     xoha.order_header_id                            =   xola.order_header_id
--      AND     NVL( xola.delete_flag, cv_n )                   =   cv_n
--      AND     xoha.order_type_id                              =   otta.transaction_type_id
--      AND     otta.org_id                                     =   gt_itou_ou_id
--      AND     otta.attribute1                                 =   cv_shukka_shikyuu_kbn_1
--      AND     NVL( otta.attribute4, cv_zaiko_chousei_kbn_1 )  =   cv_zaiko_chousei_kbn_1
--      AND     xola.request_item_id                            =   msib.inventory_item_id
--      AND     msib.organization_id                            =   gt_org_id
--      AND     msib.segment1                                   =   imbc.item_no
--      AND     imbc.item_id                                    =   ximb.item_id
--      AND     xoha.schedule_arrival_date BETWEEN ximb.start_date_active AND NVL( ximb.end_date_active, xoha.schedule_arrival_date )
--      AND     ximb.parent_item_id                             =   imbp.item_id
--      AND     xoha.deliver_to_id                              =   hps.party_site_id
--      AND     hps.party_id                                    =   hca.party_id
--      AND     hca.customer_class_code                         =   cv_class_code_1
--      AND     hca.status                                      =   cv_status_a
--      AND     hca.cust_account_id                             =   xca.customer_id
--      AND     xoha.deliver_from                               =   xilv.segment1
--      AND NOT EXISTS( SELECT  1
--                      FROM    xxcoi_base_item_tmp     tmp     --  ���_�i�ڏ��A�g�ꎞ�\
--                      WHERE   tmp.base_code       =   DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
--                      AND     tmp.item_number     =   imbp.item_no
--                      AND     tmp.deliver_from    =   xoha.deliver_from
--              )
--Ver1.3 Del end
--Ver1.3 Add start
      SELECT
         BASE_CODE
        ,ITEM_NUMBER
        ,DELIVER_FROM
        ,DELIVER_FROM_NAME
      FROM
        (
          SELECT  /*+ INDEX( imbc IC_ITEM_MST_B_UNQ1 )
                      INDEX( ximb XXCMN_IMB_N01 )
                  */
                  DISTINCT
                  DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
                                              AS  "BASE_CODE"             --  ���_�R�[�h
                , imbp.item_no                AS  "ITEM_NUMBER"           --  �i�ڃR�[�h
                , xoha.deliver_from           AS  "DELIVER_FROM"          --  �o�Ɍ��q��
                , xilv.description            AS  "DELIVER_FROM_NAME"     --  �o�Ɍ��q�ɖ�
                , xoha.schedule_arrival_date  AS  "SCHEDULE_ARRIVAL_DATE" --  ���ח\���
                , row_number() over( 
                    partition by              -- �W�v�L�[�F���_�A�i�ڕ�
                        DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
                      , imbp.item_no
                    order by                  -- �\�[�g�F���ח\����~���A�o�Ɍ��q��
                        xoha.schedule_arrival_date desc
                      , xoha.deliver_from  
                    )                         AS row_number               -- ���я�
          FROM    xxwsh_order_headers_all   xoha                          --  �󒍃w�b�_�A�h�I��
                , xxwsh_order_lines_all     xola                          --  �󒍖��׃A�h�I��
                , oe_transaction_types_all  otta                          --  �󒍃^�C�v�}�X�^
                , mtl_system_items_b        msib                          --  DISC�i�ڃ}�X�^
                , ic_item_mst_b             imbc                          --  OPM�i�ڃ}�X�^�i�q�j
                , xxcmn_item_mst_b          ximb                          --  OPM�i�ڃA�h�I���}�X�^
                , ic_item_mst_b             imbp                          --  OPM�i�ڃ}�X�^�i�e�j
                , hz_party_sites            hps                           --  �p�[�e�B�T�C�g
                , hz_cust_accounts          hca                           --  �ڋq�}�X�^
                , xxcmm_cust_accounts       xca                           --  �ڋq�ǉ����}�X�^
                , xxcmn_item_locations2_v   xilv                          --  OPM�ۊǏꏊ
          WHERE   xoha.req_status                                 =   gt_ship_status_close          --  ���ߍς�
          AND     xoha.notif_status                               =   gt_notice_status              --  �m��ʒm�ς�
          AND     xoha.schedule_arrival_date                      >=  TRUNC( gd_target_date ) - gn_target_term
          AND     xoha.schedule_arrival_date                      <   TRUNC( gd_target_date + 1 ) + 1
          AND     xoha.latest_external_flag                       =   cv_y
          AND     xoha.order_header_id                            =   xola.order_header_id
          AND     NVL( xola.delete_flag, cv_n )                   =   cv_n
          AND     xoha.order_type_id                              =   otta.transaction_type_id
          AND     otta.org_id                                     =   gt_itou_ou_id
          AND     otta.attribute1                                 =   cv_shukka_shikyuu_kbn_1
          AND     NVL( otta.attribute4, cv_zaiko_chousei_kbn_1 )  =   cv_zaiko_chousei_kbn_1
          AND     xola.request_item_id                            =   msib.inventory_item_id
          AND     msib.organization_id                            =   gt_org_id
          AND     msib.segment1                                   =   imbc.item_no
          AND     imbc.item_id                                    =   ximb.item_id
          AND     xoha.schedule_arrival_date BETWEEN ximb.start_date_active AND NVL( ximb.end_date_active, xoha.schedule_arrival_date )
          AND     ximb.parent_item_id                             =   imbp.item_id
          AND     xoha.deliver_to_id                              =   hps.party_site_id
          AND     hps.party_id                                    =   hca.party_id
          AND     hca.customer_class_code                         =   cv_class_code_1
          AND     hca.status                                      =   cv_status_a
          AND     hca.cust_account_id                             =   xca.customer_id
          AND     xoha.deliver_from                               =   xilv.segment1
          AND NOT EXISTS( SELECT  1
                          FROM    xxcoi_base_item_tmp     tmp     --  ���_�i�ڏ��A�g�ꎞ�\
                          WHERE   tmp.base_code       =   DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, hca.account_number )
                          AND     tmp.item_number     =   imbp.item_no
                  )
        )
      WHERE  row_number = 1
--Ver1.3 Add end
    ;
    --  ==============================================================
    --  �󕥗݌v���o
    --  ==============================================================
    --  �󕥗݌v�����ꎞ�\�ɓo�^����
    --  �������A���_�A�i�ڂŊ��ɓo�^�ς݂̏ꍇ�͏��O����
    INSERT INTO xxcoi_base_item_tmp(
        base_code                       --  ���_�R�[�h
      , item_number                     --  �i�ڃR�[�h
      , deliver_from                    --  �o�Ɍ��q��
      , deliver_from_name               --  �o�Ɍ��q�ɖ�
    )
      SELECT  DISTINCT
              DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, xirs.base_code )
                                          AS  "BASE_CODE"             --  ���_�R�[�h
            , msib.segment1               AS  "ITEM_NUMBER"           --  �i�ڃR�[�h
            , cv_deliver_from_null        AS  "DELIVER_FROM"          --  �Œ�l�F'9999'
            , cv_deliver_from_name_null   AS  "DELIVER_FROM_NAME"     --  �Œ�l�F'�Y���Ȃ�'
      FROM    xxcoi_inv_reception_sum     xirs                        --  �����݌Ɏ󕥕\�i�݌v�j
            , mtl_system_items_b          msib                        --  DISC�i�ڃ}�X�^
            , hz_cust_accounts            hca                         --  �ڋq�}�X�^
            , xxcmm_cust_accounts         xca                         --  �ڋq�ǉ����}�X�^
      WHERE   xirs.practice_date        =   TO_CHAR( gd_target_date, cv_date_mask_2 )
      AND     xirs.organization_id      =   gt_org_id
      AND     xirs.inventory_item_id    =   msib.inventory_item_id
      AND     xirs.organization_id      =   msib.organization_id
      AND     xirs.base_code            =   hca.account_number
      AND     hca.customer_class_code   =   cv_class_code_1
      AND     hca.cust_account_id       =   xca.customer_id
      AND NOT EXISTS( SELECT  /*+ INDEX( tmp XXCOI_BASE_ITEM_TMP_N01 ) */
                              1
                      FROM    xxcoi_base_item_tmp     tmp             --  ���_�i�ڏ��A�g�ꎞ�\
                      WHERE   tmp.base_code       =   DECODE( xca.dept_hht_div, cv_dept_hht_div_1, xca.management_base_code, xirs.base_code )
                      AND     tmp.item_number     =   msib.segment1
              )
    ;
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
  END create_tmp;
--  V1.2 2018/01/11 Added END
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      iv_target_date IN  VARCHAR2      --   �����Ώۓ�
    , ov_errbuf      OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode     OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg      OUT VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                   -- �v���O������
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
    lv_para_msg               VARCHAR2(1000);                         -- ���b�Z�[�W�p
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
    --==================================
    -- �e�ϐ��̏�����
    --==================================
    gt_org_code           := NULL;
    gt_seisan_org_name    := NULL;
    gv_dire_out_hht       := NULL;
    gt_ship_status_close  := NULL;
    gt_ship_status_result := NULL;
    gt_notice_status      := NULL;
    gt_itou_ou_id         := NULL;
    gt_org_id             := NULL;
    gd_process_date       := NULL;
    gn_target_term        := NULL;    --  V1.2 2018/01/11 Added
--
    --
    --==================================
    -- �Ɩ����t�擾
    --==================================
    -- ���ʊ֐����A�Ɩ����t���擾���܂��B
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    --
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_appl_short_name
                        , iv_name        => cv_process_date_expt_msg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --==================================
    -- �p�����[�^�o��
    --==================================
    IF ( iv_target_date IS NOT NULL ) THEN
      --���̓p�����[�^�u�����Ώۓ��v���ݒ肳��Ă���ꍇ�A���̓p�����[�^�u�����Ώۓ��v�����b�Z�[�W�o��
      lv_para_msg  :=  xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_xxcos_appl_short_name
                          , iv_name          =>  cv_msg_parameter_note
                          , iv_token_name1   =>  cv_tkn_para_date
                          , iv_token_value1  =>  iv_target_date  -- �����Ώۓ�
                         );
      -- ��s�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      --
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.OUTPUT
        ,buff   =>  lv_para_msg
      );
      --
      BEGIN
        -- ���̓p�����[�^�u�����Ώۓ��v�������Ώۓ��Ƃ���B
        gd_target_date := TO_DATE(iv_target_date , cv_date_mask_1);
      EXCEPTION
        WHEN OTHERS THEN
          -- ���t�^�ɕϊ��ł��Ȃ������ꍇ�́A���t�p�����[�^�G���[�Ƃ���B
          lv_errmsg   := xxccp_common_pkg.get_msg(
                            iv_application  => cv_xxcos_appl_short_name
                          , iv_name         => cv_date_err_msg
                         );
          lv_errbuf   := lv_errmsg;
          --
          RAISE global_api_expt;
      END;
      --
      -- ���̓p�����[�^�u�����Ώۓ��v���Ɩ����t��薢�����̏ꍇ
      IF (TO_DATE(iv_target_date, cv_date_mask_1 ) > gd_process_date) THEN
        lv_errbuf   :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_xxcos_appl_short_name
                          , iv_name         => cv_future_date_err_msg
                        );
        lv_errmsg   :=  lv_errbuf;
        RAISE global_api_expt;
      END IF;
    --
    ELSE
      -- ���̓p�����[�^�u�����Ώۓ��v���ݒ肳��Ă��Ȃ��ꍇ�A�R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W���o��
      gv_out_msg   :=  xxccp_common_pkg.get_msg(
                            iv_application   =>  cv_application
                          , iv_name          =>  cv_conc_not_parm_msg
                          );
      --
      -- ��s�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => NULL
      );
      --
      FND_FILE.PUT_LINE(
         which  =>  FND_FILE.OUTPUT
        ,buff   =>  gv_out_msg
      );
      --
      -- �Ɩ����t�������Ώۓ��Ƃ��܂��B
      gd_target_date := gd_process_date;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����݌ɑg�D�R�[�h�擾
    --==============================================================
    gt_org_code := fnd_profile.value( cv_prf_org );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_org_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_org
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C����萶�Y�c�ƒP�ʖ��̎擾
    --==============================================================
    gt_seisan_org_name := fnd_profile.value( cv_prf_itou_ou_mfg );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_seisan_org_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_itou_ou_mfg_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_itou_ou_mfg
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����HHT_OUTBOUND�i�[�f�B���N�g���p�X�擾
    --==============================================================
    gv_dire_name := fnd_profile.value( cv_prf_dire_out_hht );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_dire_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_dire_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_dire_out_hht
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C����苒�_�i��IF�o�̓t�@�C�����擾
    --==============================================================
    gv_file_base_item := fnd_profile.value( cv_prf_file_base_item );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_file_base_item IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_file_name_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_file_base_item
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����o�׈˗��X�e�[�^�X_���ߍςݎ擾
    --==============================================================
    gt_ship_status_close := fnd_profile.value( cv_prf_ship_status_close );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_ship_status_close IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_close
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����o�׈˗��X�e�[�^�X_�o�׎��ьv��ώ擾
    --==============================================================
    gt_ship_status_result := fnd_profile.value( cv_prf_ship_status_result );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_ship_status_result IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_ship_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_ship_status_result
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C�����ʒm�X�e�[�^�X_�m��ʒm�ώ擾
    --==============================================================
    gt_notice_status := fnd_profile.value( cv_prf_notice_status );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gt_notice_status IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_notice_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_notice_status
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�v���t�@�C����苒�_�i�ڏ��擾����(�o���N)�擾
    --==============================================================
    gv_limit_num := fnd_profile.value( cv_base_code_item_bulk_cnt );
    --
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
    IF ( gv_limit_num IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_bulk_cnt_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_base_code_item_bulk_cnt
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    BEGIN
      --
      -- ���l�^�ɕϊ�
      gn_limit_num := TO_NUMBER( gv_limit_num );
    --
    EXCEPTION
      WHEN OTHERS THEN
        --
        -- ���l�^�ɕϊ��ł��Ȃ������ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_appl_short_name
                       , iv_name         => cv_bulk_cnt_err_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_base_code_item_bulk_cnt
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
--  V1.2 2018/01/11 Added START
    --==============================================================
    --�v���t�@�C����苒�_�i�ڏ��擾���Ԃ��擾
    --==============================================================
    BEGIN
      gn_target_term  :=  TO_NUMBER( fnd_profile.value( cv_prf_base_code_item_term ) );
      --
      IF ( gn_target_term IS NULL ) THEN
        -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_appl_short_name
                       , iv_name         => cv_bulk_cnt_err_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_prf_base_code_item_term
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- �^�ϊ��Ɏ��s�����ꍇ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_appl_short_name
                       , iv_name         => cv_bulk_cnt_err_msg
                       , iv_token_name1  => cv_tkn_pro
                       , iv_token_value1 => cv_prf_base_code_item_term
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--  V1.2 2018/01/11 Added END
--
    --==============================================================
    --���ʊ֐����݌ɑg�DID�擾
    --==============================================================
    gt_org_id := xxcoi_common_pkg.get_organization_id(
                   iv_organization_code => gt_org_code
                 );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_org_id_err_msg
                     , iv_token_name1  => cv_tkn_org
                     , iv_token_value1 => gt_org_code
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���Y�c�ƒP�ʖ��̂�萶�Y�g�DID�擾
    --==============================================================
    BEGIN
      SELECT hou.organization_id   organization_id
      INTO   gt_itou_ou_id 
      FROM   hr_organization_units hou
      WHERE  hou.name = gt_seisan_org_name;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_itou_ou_mfg_err_msg
                     , iv_token_name1  => cv_tkn_pro
                     , iv_token_value1 => cv_prf_itou_ou_mfg
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --�f�B���N�g�����擾
    --==============================================================
    BEGIN
      SELECT ad.directory_path   directory_path
      INTO   gv_dire_out_hht
      FROM   all_directories     ad   -- �f�B���N�g�����
      WHERE  directory_name = gv_dire_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_appl_short_name
                        , iv_name         => cv_full_path_err_msg
                        , iv_token_name1  => cv_tkn_dir
                        , iv_token_value1 => gv_dire_name
                       );
        lv_errbuf   := lv_errmsg;
        --
        RAISE global_api_expt;
    END;
    --
    -- IF�t�@�C�����iIF�t�@�C���̃t���p�X���j���o��
    -- '�f�B���N�g���p�X'��'/'�Ɓe�t�@�C����'������
    gv_full_path  := gv_dire_out_hht || cv_file_slash || gv_file_base_item;
    --
    --�t�@�C�����o�̓��b�Z�[�W
    gv_out_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_name
                     , iv_name         => cv_prf_file_name_msg
                     , iv_token_name1  => cv_tkn_file_name
                     , iv_token_value1 => gv_full_path
                    );
    --
    -- 1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
    --
    -- ���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => gv_out_msg
      );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      iv_target_date    IN  VARCHAR2      --  �������t
    , ov_errbuf         OUT VARCHAR2      --  �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode        OUT VARCHAR2      --  ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg         OUT VARCHAR2      --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cn_max_linesize   CONSTANT BINARY_INTEGER := 32767; -- �t�@�C���T�C�Y
--
    -- *** ���[�J���ϐ� ***
    -- �t�@�C���̑��݃`�F�b�N�p�ϐ�
    lb_exists       BOOLEAN         DEFAULT NULL;       -- �t�@�C�����ݔ���p�ϐ�
    ln_file_length  NUMBER          DEFAULT NULL;       -- �t�@�C���̒���
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;       -- �u���b�N�T�C�Y
    lv_message_code VARCHAR2(100);                      -- �I�����b�Z�[�W�R�[�h
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J����O       ***
    remain_file_expt           EXCEPTION;
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
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    --
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1.��������
    -- ===============================
    init(
        iv_target_date                                  -- �����Ώۓ�
      , lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.�t�@�C���̃I�[�v������
    -- ========================================
    -- �t�@�C���̑��݃`�F�b�N
    UTL_FILE.FGETATTR( 
        location     =>  gv_dire_name
      , filename     =>  gv_file_base_item
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    --
    -- ����t�@�C�������݂����ꍇ�̓G���[
    IF( lb_exists = TRUE ) THEN
      RAISE remain_file_expt;
    --
    ELSE
      -- �t�@�C���I�[�v���������s
      gf_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_dire_name        -- �f�B���N�g���p�X
                          , filename     => gv_file_base_item      -- �t�@�C����
                          , open_mode    => cv_file_mode_w         -- �I�[�v�����[�h
                          , max_linesize => cn_max_linesize        -- �t�@�C���T�C�Y
                         );
    END IF;
--
    -- ========================================
    -- A-3.���_�i�ڎ擾����,A-4.���_�i��CSV�쐬����
    -- ========================================
--  V1.2 2018/01/11 Added START
    create_tmp(
        lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--  V1.2 2018/01/11 Added END
    get_item_record(
        lv_errbuf                                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                                      -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-5.�I������
    -- ========================================
    --
    -- �t�@�C���̃N���[�Y����
    UTL_FILE.FCLOSE(
      file => gf_activ_file_h
      );
--
  EXCEPTION
    -- �t�@�C�����݃`�F�b�N�G���[
    WHEN remain_file_expt THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_appl_short_name
                        , iv_name         => cv_prf_no_file_msg
                        , iv_token_name1  => cv_tkn_file_name
                        , iv_token_value1 => gv_full_path
                      );
      lv_errbuf    := lv_errmsg;
      --
      ov_errmsg    := lv_errmsg;
      ov_errbuf    := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode   := cv_status_error;
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
      errbuf          OUT VARCHAR2       --   �G���[�E���b�Z�[�W  --# �Œ� #
    , retcode         OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
    , iv_target_date  IN  VARCHAR2       --   �y�C�Ӂz�����Ώۓ�
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        iv_target_date      --  �y�C�Ӂz�����Ώۓ�
      , lv_errbuf           --  �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode          --  ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg           --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �G���[���͐��������o�͂�0�ɃZ�b�g
    --           �G���[�����o�͂�1�ɃZ�b�g
    IF( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      fnd_file.put_line(
          which => fnd_file.output
        , buff  => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
          which => fnd_file.log
        , buff  => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_target_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_normal_cnt )
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR ( gn_error_cnt )
                   );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                    , iv_name        => lv_message_code
                   );
    fnd_file.put_line(
        which => fnd_file.output
      , buff  => gv_out_msg
    );
    --
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
END XXCOI010A04C;
/
