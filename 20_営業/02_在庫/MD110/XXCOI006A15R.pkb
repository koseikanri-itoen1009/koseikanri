CREATE OR REPLACE
PACKAGE BODY XXCOI006A15R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI006A15R(body)
 * Description      : �q�ɖ��ɓ����܂��͌����A�����̎󕥎c�������󕥎c���\�ɏo�͂��܂��B
 *                    �a���斈�Ɍ����̎󕥎c�������󕥎c���\�ɏo�͂��܂��B
 * MD.050           : �󕥎c���\(�q�ɁE�a����)    MD050_COI_006_A15
 * Version          : 1.13
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  final_svf              SVF�N��                  (A-5)
 *                         ܰ�ð����ް��폜         (A-6)
 *  get_daily_data         �����f�[�^�擾           (A-3)
 *                         ܰ�ð����ް��o�^(����)   (A-4)
 *  get_month_data         �����f�[�^�擾           (A-3)
 *                         ܰ�ð����ް��o�^(����)   (A-4)
 *  init                   ��������                 (A-1)
 *                         �p�����[�^�`�F�b�N       (A-2)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/18    1.0   Sai.u            �V�K�쐬
 *  2009/03/05    1.1   T.Nakamura       [��QCOI_036] �����o�͂̕s��Ή�
 *  2009/05/13    1.2   T.Nakamura       [��QT1_0709] �o�͋敪�`�F�b�N���폜
 *  2009/06/19    1.3   H.Sasaki         [��QT1_1444] PT�Ή�
 *  2009/07/22    1.4   H.Sasaki         [0000685]�p�����[�^���t���ڂ�PT�Ή�
 *  2009/08/06    1.5   H.Sasaki         [0000893]PT�Ή�
 *  2009/08/10    1.6   N.Abe            [0000809]����VD�ۊǏꏊ�̏o�͑Ή�
 *  2009/08/19    1.7   N.Abe            [0001090]�o�͌����̏C��
 *  2009/09/11    1.8   N.Abe            [0001293]�Ǌ����_����̎擾���@�C��
 *                                       [0001266]OPM�i�ڃA�h�I���̎擾���@�C��
 *  2009/09/15    1.9   H.Sasaki         [0001346]PT�Ή�
 *  2009/12/22    1.10  N.Abe            [E_�{�ғ�_00222]�ڋq���̎擾���@�C��(�����̂�)
 *  2010/04/08    1.11  N.Abe            [E_�{�ғ�_02211]���_���r���[�g�p�����̏C��
 *  2013/01/08    1.12  K.Kiriu          [E_�{�ғ�_10389]�p�t�H�[�}���X�Ή�
 *  2013/08/12    1.13  S.Niki           [E_�{�ғ�_10957]�p�t�H�[�}���X�Ή�
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
  ov_cost_errbuf              VARCHAR2(5000);               -- �G���[�E���b�Z�[�W
  ov_cost_retcode             VARCHAR2(1);                  -- ���^�[���R�[�h
  ov_cost_errmsg              VARCHAR2(5000);               -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(99) := 'XXCOI006A15R';     -- �p�b�P�[�W��
  cv_xxcoi_sn        CONSTANT VARCHAR2(9)  := 'XXCOI';            -- SHORT_NAME_FOR_XXCOI
  -- ���b�Z�[�WID
  cv_msg_00005       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00005';
  cv_msg_00006       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006';
  cv_msg_00008       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00008';
  cv_msg_00011       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00011';
  cv_msg_10094       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10094';
  cv_msg_10102       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10102';
  cv_msg_10103       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10103';
  cv_msg_10104       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10104';
  cv_msg_10105       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10105';
  cv_msg_10113       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10113';
  cv_msg_10115       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10115';
  cv_msg_10116       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10116';
  cv_msg_10119       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10119';
  cv_msg_10197       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10197';
  cv_msg_10198       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10198';
  cv_msg_10264       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10264';
  cv_msg_10314       CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10314';
  -- �I���敪(10:���� 20:���� 30:����)
  cv_inv_kbn1        CONSTANT VARCHAR2(20) := '10';
  cv_inv_kbn2        CONSTANT VARCHAR2(20) := '20';
  cv_inv_kbn3        CONSTANT VARCHAR2(20) := '30';
  cv_inv_kbn4        CONSTANT VARCHAR2(20) := '1';
  cv_inv_kbn5        CONSTANT VARCHAR2(20) := '2';
  -- �o�͋敪(10:�q�� 20:�a����)
  cv_out_kbn1        CONSTANT VARCHAR2(20) := '10';
  cv_out_kbn2        CONSTANT VARCHAR2(20) := '20';
  -- �ۊǏꏊ�敪(1:�q��  2:�c�Ǝ�  3:�a����  4:���X  5:���̋@  8:����)
  cv_subinv_1        CONSTANT VARCHAR2(1)  :=  '1';
  cv_subinv_2        CONSTANT VARCHAR2(1)  :=  '2';
  cv_subinv_3        CONSTANT VARCHAR2(1)  :=  '3';
  cv_subinv_4        CONSTANT VARCHAR2(1)  :=  '4';
  cv_subinv_5        CONSTANT VARCHAR2(1)  :=  '5';
  cv_subinv_8        CONSTANT VARCHAR2(1)  :=  '8';
  -- �ۊǏꏊ����  7:���̋@(����)
  cv_subinv_7        CONSTANT VARCHAR2(1)  :=  '7';
  --
  cv_protok_sn       CONSTANT VARCHAR2(20) := 'PRO_TOK';
  cv_orgcode_sn      CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';
  cv_org_code_p      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';
  cv_output_div      CONSTANT VARCHAR2(30) := 'XXCOI1_IN_OUT_LIST_OUTPUT_DIV';
  cv_inv_div         CONSTANT VARCHAR2(30) := 'XXCOI1_INVENTORY_DIV';
  cv_p_token1        CONSTANT VARCHAR2(30) := 'P_OUTPUT_TYPE';
  cv_p_token2        CONSTANT VARCHAR2(30) := 'P_INVENTORY_TYPE';
  cv_p_token3        CONSTANT VARCHAR2(30) := 'P_INVENTORY_DATE';
  cv_p_token4        CONSTANT VARCHAR2(30) := 'P_INVENTORY_MONTH';
  cv_p_token5        CONSTANT VARCHAR2(30) := 'P_BASE_CODE';
  cv_p_token6        CONSTANT VARCHAR2(30) := 'P_STORE_CODE';
  cv_p_token7        CONSTANT VARCHAR2(30) := 'P_CUSTOMER_CODE';
-- == 2009/07/22 V1.4 Added START ===============================================================
  cv_replace_sign    CONSTANT VARCHAR2(1)  := '/';
-- == 2009/07/22 V1.4 Added END   ===============================================================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  cv_inv_kbn         fnd_lookup_values.description%TYPE;    -- �I���敪
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_out_msg                  VARCHAR2(5000);               -- �p�����[�^���b�Z�[�W
  gv_user_base                VARCHAR2(4);                  -- ���O�C�����[�U�[���_�R�[�h
  gv_base_short_name          VARCHAR2(8);                  -- ���_����
  gv_focus_base_flag          VARCHAR2(1);                  -- �Ǘ��ۋ��_�t���O
  gv_organization_code        VARCHAR2(30);                 -- �݌ɑg�D�R�[�h
  gn_organization_id          NUMBER;                       -- �݌ɑg�DID
  gn_target_cnt               NUMBER;                       -- �Ώی���
  gn_normal_cnt               NUMBER;                       -- ��������
  gn_error_cnt                NUMBER;                       -- �G���[����
  gn_warn_cnt                 NUMBER;                       -- �X�L�b�v����
  gd_business_date            DATE;                         -- �Ɩ����t
  gd_target_date              DATE;                         -- �Ώۓ�
  gd_inventory_date           DATE;                         -- �I����
  gd_inventory_month          DATE;                         -- �I����
  gv_inventory_date           VARCHAR2(8);                  -- �I����(CAHR)
  gv_inventory_month          VARCHAR2(6);                  -- �I����(CHAR)
  gv_out_kbn                  VARCHAR2(99);                 -- �o�͋敪
  gv_inv_kbn                  VARCHAR2(99);                 -- �I���敪
-- == 2009/08/10 V1.6 Modified START ===============================================================
--  gv_warehouse                VARCHAR2(99);                 -- �q��/�a���於��
-- == 2009/12/22 V1.10 Modified START ===============================================================
--  gv_warehouse                VARCHAR2(240);                -- �q��/�a���於��
  gv_warehouse                VARCHAR2(360);                -- �q��/�a���於��
-- == 2009/12/22 V1.10 Modified END   ===============================================================
-- == 2009/08/10 V1.6 Modified END   ===============================================================
--
  /**********************************************************************************
   * Procedure Name   : final_svf
   * Description      : SVF�N��(A-5)
   ***********************************************************************************/
  PROCEDURE final_svf(
    ov_errbuf             OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'final_svf'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);     -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);        -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);     -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_frm_file      CONSTANT VARCHAR2(100) := 'XXCOI006A15S.xml';
    lv_vrq_file      CONSTANT VARCHAR2(100) := 'XXCOI006A15S.vrq';
    lv_output_mode   CONSTANT VARCHAR2(100) := '1';
--
    -- *** ���[�J���ϐ� ***
    lv_file_name              VARCHAR2(100);      -- ���[�t�@�C����
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
    lv_file_name := cv_pkg_name
                 || TO_CHAR(SYSDATE,'YYYYMMDD')
                 || TO_CHAR(cn_request_id)
                 || '.pdf';
    -- A-5.SVF�N��
    xxccp_svfcommon_pkg.submit_svf_request(
         ov_retcode      => lv_retcode              -- ���^�[���R�[�h
        ,ov_errbuf       => lv_errbuf               -- �G���[���b�Z�[�W
        ,ov_errmsg       => lv_errmsg               -- ���[�U�[�E�G���[���b�Z�[�W
        ,iv_conc_name    => cv_pkg_name             -- �R���J�����g��
        ,iv_file_name    => lv_file_name            -- �o�̓t�@�C����
        ,iv_file_id      => cv_pkg_name             -- ���[ID
        ,iv_output_mode  => lv_output_mode          -- �o�͋敪
        ,iv_frm_file     => lv_frm_file             -- �t�H�[���l���t�@�C����
        ,iv_vrq_file     => lv_vrq_file             -- �N�G���[�l���t�@�C����
        ,iv_org_id       =>  fnd_global.org_id      -- ORG_ID
        ,iv_user_name    =>  fnd_global.user_name   -- ���O�C���E���[�U��
        ,iv_resp_name    =>  fnd_global.resp_name   -- ���O�C���E���[�U�̐E�Ӗ�
        ,iv_doc_name     => NULL                    -- ������
        ,iv_printer_name => NULL                    -- �v�����^��
        ,iv_request_id   => cn_request_id           -- �v��ID
        ,iv_nodata_msg   => NULL);                  -- �f�[�^�Ȃ����b�Z�[�W
    -- �߂�l����
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10119
                       );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- A-6.���[�N�e�[�u���f�[�^�폜
    DELETE
    FROM  xxcoi_rep_warehouse_rcpt
    WHERE request_id = cn_request_id;
    IF (gn_target_cnt <> 0) THEN
      gn_normal_cnt := SQL%ROWCOUNT;
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
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END final_svf;
--
  /**********************************************************************************
   * Procedure Name   : get_daily_data
   * Description      : �����f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_daily_data(
    iv_output_kbn         IN  VARCHAR2,      -- �o�͋敪
    iv_inventory_kbn      IN  VARCHAR2,      -- �I���敪
    iv_inventory_date     IN  VARCHAR2,      -- �I����
    iv_inventory_month    IN  VARCHAR2,      -- �I����
    iv_base_code          IN  VARCHAR2,      -- ���_
    iv_warehouse          IN  VARCHAR2,      -- �q��
    iv_left_base          IN  VARCHAR2,      -- �a����
    ov_errbuf             OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_daily_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message                VARCHAR2(500) := NULL;   -- ���b�Z�[�W
    ln_check_num              NUMBER        := 0;      -- �󕥎c���[ID
--
    -- *** ���[�J���E�J�[�\��(A-3-2) ***
    CURSOR daily_cur
    IS
      SELECT
-- == 2013/01/08 V1.12 Modified START ===============================================================
---- == 2009/08/06 V1.5 Added START ===============================================================
--              /*+ leading(biv msi ird) */
---- == 2009/08/06 V1.5 Added END   ===============================================================
              /*+ leading(msi biv ird) */
-- == 2013/01/08 V1.12 Modified END --===============================================================
              ird.practice_date                             ird_practice_date             -- �N����
             ,ird.base_code                                 ird_base_code                 -- ���_�R�[�h
             ,biv.base_short_name                           biv_base_short_name           -- ���_����
             ,SUBSTR(msi.secondary_inventory_name, 6, 2)    msi_warehouse_code            -- �q�ɃR�[�h
             ,msi.attribute4                                msi_left_base_code            -- �a����R�[�h
             ,msi.description                               msi_warehouse_name            -- �q�ɖ���
             ,hca.account_name                              hca_left_base_name            -- �a���於��
             ,SUBSTR(
                (CASE WHEN  TRUNC(TO_DATE(iib.attribute3, 'YYYY/MM/DD')) > TRUNC(gd_target_date)
                        THEN iib.attribute1                                               -- �Q�R�[�h(��)
                        ELSE iib.attribute2                                               -- �Q�R�[�h(�V)
                      END
                ), 1, 3
              )                                             iib_gun_code                  -- �Q�R�[�h
             ,iib.item_no                                   iib_item_no                   -- ���i�R�[�h
             ,imb.item_short_name                           imb_item_short_name           -- ���i����
             ,ird.operation_cost                            ird_operation_cost            -- �c�ƌ���
             ,ird.previous_inventory_quantity               ird_previous_inv_qua          -- �O���݌ɐ�
             ,ird.standard_cost                             ird_standard_cost             -- �W������
             ,ird.sales_shipped                             ird_sales_shipped             -- ����o��
             ,ird.sales_shipped_b                           ird_sales_shipped_b           -- ����o�ɐU��
             ,ird.return_goods                              ird_return_goods              -- �ԕi
             ,ird.return_goods_b                            ird_return_goods_b            -- �ԕi�U��
             ,ird.warehouse_ship                            ird_warehouse_ship            -- �q�ɂ֕Ԍ�
             ,ird.truck_ship                                ird_truck_ship                -- �c�ƎԂ֏o��
             ,ird.others_ship                               ird_others_ship               -- ���o�ɁQ���̑��o��
             ,ird.warehouse_stock                           ird_warehouse_stock           -- �q�ɂ�����
             ,ird.truck_stock                               ird_truck_stock               -- �c�ƎԂ�����
             ,ird.others_stock                              ird_others_stock              -- ���o�ɁQ���̑�����
             ,ird.change_stock                              ird_change_stock              -- �q�֓���
             ,ird.change_ship                               ird_change_ship               -- �q�֏o��
             ,ird.goods_transfer_old                        ird_goods_transfer_old        -- ���i�U��(�����i)
             ,ird.goods_transfer_new                        ird_goods_transfer_new        -- ���i�U��(�V���i)
             ,ird.sample_quantity                           ird_sample_quantity           -- ���{�o��
             ,ird.sample_quantity_b                         ird_sample_quantity_b         -- ���{�o�ɐU��
             ,ird.customer_sample_ship                      ird_customer_sample_ship      -- �ڋq���{�o��
             ,ird.customer_sample_ship_b                    ird_customer_sample_ship_b    -- �ڋq���{�o�ɐU��
             ,ird.customer_support_ss                       ird_customer_support_ss       -- �ڋq���^���{�o��
             ,ird.customer_support_ss_b                     ird_customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
             ,ird.ccm_sample_ship                           ird_ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
             ,ird.ccm_sample_ship_b                         ird_ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
             ,ird.vd_supplement_stock                       ird_vd_supplement_stock       -- ����VD��[����
             ,ird.vd_supplement_ship                        ird_vd_supplement_ship        -- ����VD��[�o��
             ,ird.inventory_change_in                       ird_inventory_change_in       -- ��݌ɕύX����
             ,ird.inventory_change_out                      ird_inventory_change_out      -- ��݌ɕύX�o��
             ,ird.factory_return                            ird_factory_return            -- �H��ԕi
             ,ird.factory_return_b                          ird_factory_return_b          -- �H��ԕi�U��
             ,ird.factory_change                            ird_factory_change            -- �H��q��
             ,ird.factory_change_b                          ird_factory_change_b          -- �H��q�֐U��
             ,ird.removed_goods                             ird_removed_goods             -- �p�p
             ,ird.removed_goods_b                           ird_removed_goods_b           -- �p�p�U��
             ,ird.factory_stock                             ird_factory_stock             -- �H�����
             ,ird.factory_stock_b                           ird_factory_stock_b           -- �H����ɐU��
             ,ird.wear_decrease                             ird_wear_decrease             -- �I�����Ց�
             ,ird.wear_increase                             ird_wear_increase             -- �I�����Ռ�
             ,ird.selfbase_ship                             ird_selfbase_ship             -- �ۊǏꏊ�ړ��Q�����_�o��
             ,ird.selfbase_stock                            ird_selfbase_stock            -- �ۊǏꏊ�ړ��Q�����_����
             ,ird.book_inventory_quantity                   ird_book_inventory_quantity   -- ����݌ɐ�
    FROM      xxcoi_inv_reception_daily         ird                                       -- �����݌Ɏ󕥕\ (����)
             ,mtl_secondary_inventories         msi                                       -- �ۊǏꏊ�}�X�^ (INV)
             ,hz_cust_accounts                  hca                                       -- �ڋq�}�X�^
             ,mtl_system_items_b                sib                                       -- Disc�i�ڃ}�X�^
             ,xxcmn_item_mst_b                  imb                                       -- OPM�i�ڃA�h�I��(XXCMN)
             ,ic_item_mst_b                     iib                                       -- OPM�i��        (GMI)
-- == 2009/08/06 V1.5 Modified START ===============================================================
--             ,xxcoi_base_info2_v                biv                                       -- ���_���r���[
             ,(SELECT  hca.account_number
                      ,SUBSTRB(hca.account_name,1,8)  base_short_name
               FROM    hz_cust_accounts    hca
                      ,xxcmm_cust_accounts xca
               WHERE   xca.management_base_code  =   NVL(iv_base_code, gv_user_base)
               AND     hca.status                =   'A'
               AND     hca.customer_class_code   =   '1'
               AND     hca.cust_account_id       =   xca.customer_id
               UNION
               SELECT  hca.account_number
                      ,SUBSTRB(hca.account_name,1,8)  base_short_name
               FROM    hz_cust_accounts    hca
                      ,xxcmm_cust_accounts xca
               WHERE   xca.customer_code         =   NVL(iv_base_code, gv_user_base)
               AND     hca.status                =   'A'
               AND     hca.customer_class_code   =   '1'
               AND     hca.cust_account_id       =   xca.customer_id
              )       biv
-- == 2009/08/06 V1.5 Modified END   ===============================================================
-- == 2009/08/06 V1.5 Modified START ===============================================================
--    WHERE     biv.focus_base_code       =   NVL(iv_base_code, gv_user_base)
--    AND       biv.base_code             =   ird.base_code
--    AND       ird.practice_date         =   gd_inventory_date
--    AND       ird.inventory_item_id     =   sib.inventory_item_id
--    AND       sib.organization_id       =   ird.organization_id
--    AND       sib.segment1              =   iib.item_no                                   -- OPM�i�ڃR�[�h
--    AND       iib.item_id               =   imb.item_id
--    AND       ird.organization_id       =   msi.organization_id
--    AND       ird.subinventory_code     =   msi.secondary_inventory_name
--    AND       msi.attribute4            =   hca.account_number(+)
--    AND       msi.attribute7            =   ird.base_code
---- == 2009/06/19 V1.3 Modified START ===============================================================
----    AND  ((iv_output_kbn             = cv_out_kbn1
----    AND    SUBSTR(msi.secondary_inventory_name,6,2)
----                                     = NVL(iv_warehouse,SUBSTR(msi.secondary_inventory_name,6,2)))
----    OR    (iv_output_kbn            <> cv_out_kbn1
----    AND    msi.attribute4            = NVL(iv_left_base,msi.attribute4)))
----    AND (((iv_output_kbn             = cv_out_kbn1
----    AND    msi.attribute1            = cv_subinv_1)
----    OR    (iv_output_kbn            <> cv_out_kbn1
----    AND    msi.attribute1            = cv_subinv_3))                 -- �ۊǏꏊ�敪(�a����)
----    OR  (((iv_output_kbn             = cv_out_kbn1
----    AND    msi.attribute1            = cv_subinv_1)
----    OR    (iv_output_kbn            <> cv_out_kbn1
----    AND    msi.attribute1            = cv_subinv_4))                 -- �ۊǏꏊ�敪(���X)
----    AND  ((msi.attribute13          <> cv_subinv_7                   -- �ۊǏꏊ����(����VD)
----    AND    iv_left_base IS NULL)
----    OR    (iv_left_base IS NOT NULL))))
----    ORDER BY
----           ird_base_code
----          ,DECODE(iv_output_kbn, cv_out_kbn1, msi_warehouse_code
----                                            , msi_left_base_code
----           )
----          ,iib_gun_code
----          ,iib_item_no;
--    AND       (
--               (iv_warehouse IS NULL)
--               OR
--               (iv_warehouse IS NOT NULL AND SUBSTR(msi.secondary_inventory_name, 6, 2) = iv_warehouse)
--              )
--    AND       msi.attribute1            =  cv_subinv_1                                       -- �����͑q�ɂ̂ݑΏ�
--    ORDER BY
--           ird_base_code
--          ,msi_warehouse_code
--          ,iib_gun_code
--          ,iib_item_no;
-- == 2009/06/19 V1.3 Modified END   ===============================================================
    WHERE     biv.account_number            =   msi.attribute7
    AND       msi.organization_id           =   gn_organization_id
    AND       msi.attribute7                =   ird.base_code
    AND       msi.organization_id           =   ird.organization_id
    AND       msi.secondary_inventory_name  =   ird.subinventory_code
    AND       msi.attribute4                =   hca.account_number(+)
    AND       ird.practice_date             =   gd_inventory_date
    AND       ird.inventory_item_id         =   sib.inventory_item_id
    AND       ird.organization_id           =   sib.organization_id
    AND       sib.segment1                  =   iib.item_no                                   -- OPM�i�ڃR�[�h
    AND       iib.item_id                   =   imb.item_id
-- == 2009/09/11 V1.8 Added START ===============================================================
    AND       TRUNC(gd_target_date) BETWEEN TRUNC(imb.start_date_active)
                                    AND     TRUNC(imb.end_date_active)
-- == 2009/09/11 V1.8 Added END   ===============================================================
    AND       (
               (iv_warehouse IS NULL)
               OR
               (iv_warehouse IS NOT NULL AND SUBSTR(msi.secondary_inventory_name, 6, 2) = iv_warehouse)
              )
    AND       msi.attribute1                =  cv_subinv_1;                                   -- �����͑q�ɂ̂ݑΏ�
-- == 2009/08/06 V1.5 Modified END ===============================================================
--
    -- *** ���[�J���E���R�[�h ***
    daily_rec daily_cur%ROWTYPE;
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
  -- �J�[�\���I�[�v��
  OPEN daily_cur;
  LOOP
    FETCH daily_cur INTO daily_rec;
    EXIT WHEN daily_cur%NOTFOUND;
    -- �󕥎c�����ID���J�E���g
    ln_check_num  := ln_check_num  + 1;
    -- �Ώی������J�E���g
    gn_target_cnt := gn_target_cnt + 1;
    -- A-4.���[�N�e�[�u���f�[�^�o�^
    INSERT INTO xxcoi_rep_warehouse_rcpt(
                slit_id                           -- �󕥎c�����ID
               ,inventory_kbn                     -- �I���敪
               ,output_kbn                        -- �o�͋敪
               ,in_out_year                       -- �N
               ,in_out_month                      -- ��
               ,in_out_dat                        -- ��
               ,base_code                         -- ���_�R�[�h
               ,base_name                         -- ���_����
               ,warehouse_code                    -- �q��/�a����R�[�h
               ,warehouse_name                    -- �q��/�a���於��
               ,gun_code                          -- �Q�R�[�h
               ,item_code                         -- ���i�R�[�h
               ,item_name                         -- ���i����
               ,first_inventory_qty               -- ����I����(����)
               ,factory_in_qty                    -- �H�����(����)
               ,kuragae_in_qty                    -- �q�֓���(����)
               ,car_in_qty                        -- �c�ƎԂ�����(����)
               ,hurikae_in_qty                    -- �U�֓���(����)
               ,car_ship_qty                      -- �c�ƎԂ֏o��(����)
               ,sales_qty                         -- ����o��(����)
               ,support_qty                       -- ���^���{(����)
               ,kuragae_ship_qty                  -- �q�֏o��(����)
               ,factory_return_qty                -- �H��ԕi(����)
               ,disposal_qty                      -- �p�p�o��(����)
               ,hurikae_ship_qty                  -- �U�֏o��(����)
               ,tyoubo_stock_qty                  -- ����݌�(����)
               ,inventory_qty                     -- �I����(����)
               ,genmou_qty                        -- �I������(����)
               ,first_inventory_money             -- ����I����(���z)
               ,factory_in_money                  -- �H�����(���z)
               ,kuragae_in_money                  -- �q�֓���(���z)
               ,car_in_money                      -- �c�ƎԂ�����(���z)
               ,hurikae_in_money                  -- �U�֓���(���z)
               ,car_ship_money                    -- �c�ƎԂ֏o��(���z)
               ,sales_money                       -- ����o��(���z)
               ,support_money                     -- ���^���{(���z)
               ,kuragae_ship_money                -- �q�֏o��(���z)
               ,factory_return_money              -- �H��ԕi(���z)
               ,disposal_money                    -- �p�p�o��(���z)
               ,hurikae_ship_money                -- �U�֏o��(���z)
               ,tyoubo_stock_money                -- ����݌�(���z)
               ,inventory_money                   -- �I����(���z)
               ,genmou_money                      -- �I������(���z)
               ,message                           -- ���b�Z�[�W
               ,last_update_date                  -- �ŏI�X�V��
               ,last_updated_by                   -- �ŏI�X�V��
               ,creation_date                     -- �쐬��
               ,created_by                        -- �쐬��
               ,last_update_login                 -- �ŏI�X�V���[�U
               ,request_id                        -- �v��ID
               ,program_application_id            -- �v���O�����A�v���P�[�V����ID
               ,program_id                        -- �v���O����ID
               ,program_update_date)              -- �v���O�����X�V��
        VALUES (ln_check_num                                              -- �󕥎c�����ID
               ,gv_inv_kbn                                                -- �I���敪
               ,gv_out_kbn                                                -- �o�͋敪
               ,SUBSTR(TO_CHAR(daily_rec.ird_practice_date
                              ,'YYYYMMDD'),3,2)                           -- �N
               ,SUBSTR(TO_CHAR(daily_rec.ird_practice_date
                              ,'YYYYMMDD'),5,2)                           -- ��
               ,SUBSTR(TO_CHAR(daily_rec.ird_practice_date
                              ,'YYYYMMDD'),7,2)                           -- ��
               ,daily_rec.ird_base_code                                   -- ���_�R�[�h
               ,daily_rec.biv_base_short_name                             -- ���_����
               ,DECODE(iv_output_kbn,cv_out_kbn1
               ,daily_rec.msi_warehouse_code
               ,daily_rec.msi_left_base_code)                             -- �q��/�a����R�[�h
-- == 2009/08/19 V1.7 Modified START ===============================================================
--               ,DECODE(iv_output_kbn,cv_out_kbn1
--               ,daily_rec.msi_warehouse_name
--               ,daily_rec.hca_left_base_name)
               ,SUBSTRB(DECODE(iv_output_kbn, cv_out_kbn1, daily_rec.msi_warehouse_name
                                                         , daily_rec.hca_left_base_name
                        ), 1, 50
                )                                                         -- �q��/�a���於��
-- == 2009/08/19 V1.7 Modified END   ===============================================================
               ,daily_rec.iib_gun_code                                    -- �Q�R�[�h
               ,daily_rec.iib_item_no                                     -- ���i�R�[�h
               ,daily_rec.imb_item_short_name                             -- ���i����
               ,daily_rec.ird_previous_inv_qua                            -- ����I����(����)
               ,daily_rec.ird_factory_stock                 -
                daily_rec.ird_factory_stock_b                             -- �H�����(����)
               ,daily_rec.ird_change_stock                  +
                daily_rec.ird_selfbase_stock                +
                daily_rec.ird_others_stock                  +
                daily_rec.ird_vd_supplement_stock           +
                daily_rec.ird_inventory_change_in                         -- �q�֓���(����)
               ,daily_rec.ird_truck_stock                                 -- �c�ƎԂ�����(����)
               ,daily_rec.ird_goods_transfer_new                          -- �U�֓���(����)
               ,daily_rec.ird_truck_ship                                  -- �c�ƎԂ֏o��(����)
               ,daily_rec.ird_sales_shipped                 -
                daily_rec.ird_sales_shipped_b               -
                daily_rec.ird_return_goods                  +
                daily_rec.ird_return_goods_b                              -- ����o��(����)
               ,daily_rec.ird_customer_sample_ship          -
                daily_rec.ird_customer_sample_ship_b        +
                daily_rec.ird_customer_support_ss           -
                daily_rec.ird_customer_support_ss_b         +
                daily_rec.ird_sample_quantity               -
                daily_rec.ird_sample_quantity_b             +
                daily_rec.ird_ccm_sample_ship               -
                daily_rec.ird_ccm_sample_ship_b                           -- ���^���{(����)
               ,daily_rec.ird_change_ship                   +
                daily_rec.ird_selfbase_ship                 +
                daily_rec.ird_others_ship                   +
                daily_rec.ird_vd_supplement_ship            +
                daily_rec.ird_inventory_change_out          +
                daily_rec.ird_factory_change                -
                daily_rec.ird_factory_change_b                            -- �q�֏o��(����)
               ,daily_rec.ird_factory_return                -
                daily_rec.ird_factory_return_b                            -- �H��ԕi(����)
               ,daily_rec.ird_removed_goods                 -
                daily_rec.ird_removed_goods_b                             -- �p�p�o��(����)
               ,daily_rec.ird_goods_transfer_old                          -- �U�֏o��(����)
               ,daily_rec.ird_book_inventory_quantity                     -- ����݌�(����)
               ,0                                                         -- �I����(����)
               ,0                                                         -- �I������(����)
               ,ROUND( daily_rec.ird_previous_inv_qua
                     * daily_rec.ird_operation_cost)                      -- ����I����(���z)
               ,ROUND((daily_rec.ird_factory_stock          -
                       daily_rec.ird_factory_stock_b)
                     * daily_rec.ird_operation_cost)                      -- �H�����(���z)
               ,ROUND((daily_rec.ird_change_stock           +
                       daily_rec.ird_selfbase_stock         +
                       daily_rec.ird_others_stock           +
                       daily_rec.ird_vd_supplement_stock    +
                       daily_rec.ird_inventory_change_in)
                     * daily_rec.ird_operation_cost)                      -- �q�֓���(���z)
               ,ROUND( daily_rec.ird_truck_stock
                     * daily_rec.ird_operation_cost)                      -- �c�ƎԂ�����(���z)
               ,ROUND( daily_rec.ird_goods_transfer_new
                     * daily_rec.ird_operation_cost)                      -- �U�֓���(���z)
               ,ROUND( daily_rec.ird_truck_ship
                     * daily_rec.ird_operation_cost)                      -- �c�ƎԂ֏o��(���z)
               ,ROUND((daily_rec.ird_sales_shipped          -
                       daily_rec.ird_sales_shipped_b        -
                       daily_rec.ird_return_goods           +
                       daily_rec.ird_return_goods_b)
                     * daily_rec.ird_operation_cost)                      -- ����o��(���z)
               ,ROUND((daily_rec.ird_customer_sample_ship   -
                       daily_rec.ird_customer_sample_ship_b +
                       daily_rec.ird_customer_support_ss    -
                       daily_rec.ird_customer_support_ss_b  +
                       daily_rec.ird_sample_quantity        -
                       daily_rec.ird_sample_quantity_b      +
                       daily_rec.ird_ccm_sample_ship        -
                       daily_rec.ird_ccm_sample_ship_b)
                     * daily_rec.ird_operation_cost)                      -- ���^���{(���z)
               ,ROUND((daily_rec.ird_change_ship            +
                       daily_rec.ird_selfbase_ship          +
                       daily_rec.ird_others_ship            +
                       daily_rec.ird_vd_supplement_ship     +
                       daily_rec.ird_inventory_change_out   +
                       daily_rec.ird_factory_change         -
                       daily_rec.ird_factory_change_b)
                     * daily_rec.ird_operation_cost)                      -- �q�֏o��(���z)
               ,ROUND((daily_rec.ird_factory_return         -
                       daily_rec.ird_factory_return_b)
                     * daily_rec.ird_operation_cost)                      -- �H��ԕi(���z)
               ,ROUND((daily_rec.ird_removed_goods          -
                       daily_rec.ird_removed_goods_b)
                     * daily_rec.ird_operation_cost)                      -- �p�p�o��(���z)
               ,ROUND( daily_rec.ird_goods_transfer_old
                     * daily_rec.ird_operation_cost)                      -- �U�֏o��(���z)
               ,ROUND( daily_rec.ird_book_inventory_quantity
                     * daily_rec.ird_operation_cost)                      -- ����݌�(���z)
               ,0                                                         -- �I����(���z)
               ,0                                                         -- �I������(���z)
               ,NULL                                                      -- ���b�Z�[�W
               ,SYSDATE                                                   -- �ŏI�X�V��
               ,cn_last_updated_by                                        -- �ŏI�X�V��
               ,SYSDATE                                                   -- �쐬��
               ,cn_created_by                                             -- �쐬��
               ,cn_last_update_login                                      -- �ŏI�X�V���[�U
               ,cn_request_id                                             -- �v��ID
               ,cn_program_application_id                                 -- �v���O�����A�v���P�[�V����ID
               ,cn_program_id                                             -- �v���O����ID
               ,SYSDATE);                                                 -- �v���O�����X�V��
  --
  END LOOP;
  CLOSE daily_cur;
  -- ����0���̏ꍇ
  IF (ln_check_num = 0) THEN
    -- ����0�����b�Z�[�W�擾
    lv_message := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcoi_sn
                      ,iv_name         => cv_msg_00008
                     );
    BEGIN
      IF (iv_output_kbn = cv_out_kbn1 AND iv_warehouse IS NOT NULL) THEN
        SELECT msi.description
        INTO   gv_warehouse
        FROM   mtl_secondary_inventories  msi     -- �ۊǏꏊ�}�X�^(INV)
        WHERE  msi.organization_id = gn_organization_id
        AND    SUBSTR(msi.secondary_inventory_name,6,2) = iv_warehouse
        AND    msi.attribute1 = cv_subinv_1
        AND    msi.attribute7 = iv_base_code;
      ELSIF (iv_output_kbn = cv_out_kbn2 AND iv_left_base IS NOT NULL) THEN
        SELECT hca.account_name
        INTO   gv_warehouse
        FROM   hz_cust_accounts     hca           -- �ڋq�}�X�^
        WHERE  hca.account_number = iv_left_base;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        gv_warehouse := NULL;
    END;
    --
    BEGIN
-- == 2010/04/08 V1.11 Modified START ===============================================================
--      SELECT SUBSTRB(account_name,1,8)            -- ���_����
--      INTO   gv_base_short_name
--      FROM   xxcoi_user_base_info_v               -- ���_�r���[
--      WHERE  account_number = iv_base_code
--      AND    ROWNUM = 1;
      SELECT SUBSTRB(hca.account_name, 1, 8)      -- ���_����
      INTO   gv_base_short_name
      FROM   hz_cust_accounts   hca
      WHERE  hca.account_number = iv_base_code
      AND    hca.customer_class_code = '1'
      AND    hca.status = 'A'
      ;
-- == 2010/04/08 V1.11 Modified END   ===============================================================
    EXCEPTION
      WHEN OTHERS THEN
        gv_base_short_name := NULL;
    END;
    -- ����0�����b�Z�[�W�o��
    INSERT INTO xxcoi_rep_warehouse_rcpt(
                slit_id                           -- �󕥎c�����ID
               ,inventory_kbn                     -- �I���敪
               ,output_kbn                        -- �o�͋敪
               ,in_out_year                       -- �N
               ,in_out_month                      -- ��
               ,in_out_dat                        -- ��
               ,base_code                         -- ���_�R�[�h
               ,base_name                         -- ���_����
               ,warehouse_code                    -- �q��/�a����R�[�h
               ,warehouse_name                    -- �q��/�a���於��
               ,message                           -- ���b�Z�[�W
               ,last_update_date                  -- �ŏI�X�V��
               ,last_updated_by                   -- �ŏI�X�V��
               ,creation_date                     -- �쐬��
               ,created_by                        -- �쐬��
               ,last_update_login                 -- �ŏI�X�V���[�U
               ,request_id                        -- �v��ID
               ,program_application_id            -- �v���O�����A�v���P�[�V����ID
               ,program_id                        -- �v���O����ID
               ,program_update_date)              -- �v���O�����X�V��
        VALUES (ln_check_num                      -- �󕥎c�����ID
               ,gv_inv_kbn                        -- �I���敪
               ,gv_out_kbn                        -- �o�͋敪
               ,SUBSTR(gv_inventory_date,3,2)     -- �N
               ,SUBSTR(gv_inventory_date,5,2)     -- ��
               ,SUBSTR(gv_inventory_date,7,2)     -- ��
               ,iv_base_code                      -- ���_�R�[�h
               ,gv_base_short_name                -- ���_����
-- == 2009/08/19 V1.7 Modified START ===============================================================
--               ,DECODE(iv_output_kbn,cv_out_kbn1
--               ,iv_warehouse
--               ,iv_left_base)                     -- �q��/�a����R�[�h
               ,SUBSTRB(DECODE(iv_output_kbn, cv_out_kbn1, iv_warehouse
                                                         , iv_left_base
                        ), 1, 50
                )                                 -- �q��/�a����R�[�h
-- == 2009/08/19 V1.7 Modified END   ===============================================================
               ,gv_warehouse                      -- �q��/�a���於��
               ,lv_message                        -- ���b�Z�[�W
               ,SYSDATE                           -- �ŏI�X�V��
               ,cn_last_updated_by                -- �ŏI�X�V��
               ,SYSDATE                           -- �쐬��
               ,cn_created_by                     -- �쐬��
               ,cn_last_update_login              -- �ŏI�X�V���[�U
               ,cn_request_id                     -- �v��ID
               ,cn_program_application_id         -- �v���O�����A�v���P�[�V����ID
               ,cn_program_id                     -- �v���O����ID
               ,SYSDATE);                         -- �v���O�����X�V��
  END IF;
  -- �R�~�b�g
  COMMIT;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN                                 --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF (daily_cur%ISOPEN) THEN
        CLOSE daily_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_daily_data;
--
  /**********************************************************************************
   * Procedure Name   : get_month_data
   * Description      : �����f�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_month_data(
    iv_output_kbn         IN  VARCHAR2,      -- �o�͋敪
    iv_inventory_kbn      IN  VARCHAR2,      -- �I���敪
    iv_inventory_date     IN  VARCHAR2,      -- �I����
    iv_inventory_month    IN  VARCHAR2,      -- �I����
    iv_base_code          IN  VARCHAR2,      -- ���_
    iv_warehouse          IN  VARCHAR2,      -- �q��
    iv_left_base          IN  VARCHAR2,      -- �a����
    ov_errbuf             OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'get_month_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf                 VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_message                VARCHAR2(500) := NULL;    -- ���b�Z�[�W
    ln_check_num              NUMBER        := 0;       -- �󕥎c���[ID
-- == 2009/08/10 V1.6 Modified START ===============================================================
--      lv_sql_str      VARCHAR2(4000);
      lv_sql_str              VARCHAR2(4500);
-- == 2009/08/10 V1.6 Modified END   ===============================================================
-- == 2009/09/15 V1.9 Added START ===============================================================
    ln_cnt                    NUMBER;                   -- �J�E���^
-- == 2009/09/15 V1.9 Added END   ===============================================================
-- == V1.13 Added START ===============================================================
    ln_cnt2                   NUMBER;                   -- �J�E���^2
-- == V1.13 Added END ===============================================================
--
    -- *** ���[�J���E�J�[�\��(A-2-2) ***
-- == 2009/06/19 V1.3 DELETE START ===============================================================
--    CURSOR month_cur
--    IS
--    SELECT  irm.practice_month          irm_practice_month            -- �N��
--           ,irm.practice_date           irm_practice_date             -- �N����
--           ,irm.base_code               irm_base_code                 -- ���_�R�[�h
--           ,biv.base_short_name         biv_base_short_name           -- ���_����
--           ,SUBSTR(msi.secondary_inventory_name,6,2)
--                                        msi_warehouse_code            -- �q�ɃR�[�h
--           ,msi.attribute4              msi_left_base_code            -- �a����R�[�h
--           ,msi.description             msi_warehouse_name            -- �q�ɖ���
--           ,hca.account_name            hca_left_base_name            -- �a���於��
--           ,SUBSTR((CASE                                              -- �Q���ޓK�p�J�n��
--                    WHEN TRUNC(TO_DATE(iib.attribute3,'YYYY/MM/DD')) > TRUNC(gd_target_date)
--                    THEN iib.attribute1                               -- �Q�R�[�h(��)
--                    ELSE iib.attribute2                               -- �Q�R�[�h(�V)
--                    END),1,3)           iib_gun_code                  -- �Q�R�[�h
--           ,iib.item_no                 iib_item_no                   -- ���i�R�[�h
--           ,imb.item_short_name         imb_item_short_name           -- ���i����
--           ,irm.operation_cost          irm_operation_cost            -- �c�ƌ���
--           ,irm.standard_cost           irm_standard_cost             -- �W������
--           ,irm.sales_shipped           irm_sales_shipped             -- ����o��
--           ,irm.sales_shipped_b         irm_sales_shipped_b           -- ����o�ɐU��
--           ,irm.return_goods            irm_return_goods              -- �ԕi
--           ,irm.return_goods_b          irm_return_goods_b            -- �ԕi�U��
--           ,irm.warehouse_ship          irm_warehouse_ship            -- �q�ɂ֕Ԍ�
--           ,irm.truck_ship              irm_truck_ship                -- �c�ƎԂ֏o��
--           ,irm.others_ship             irm_others_ship               -- ���o�ɁQ���̑��o��
--           ,irm.warehouse_stock         irm_warehouse_stock           -- �q�ɂ�����
--           ,irm.truck_stock             irm_truck_stock               -- �c�ƎԂ�����
--           ,irm.others_stock            irm_others_stock              -- ���o�ɁQ���̑�����
--           ,irm.change_stock            irm_change_stock              -- �q�֓���
--           ,irm.change_ship             irm_change_ship               -- �q�֏o��
--           ,irm.goods_transfer_old      irm_goods_transfer_old        -- ���i�U��(�����i)
--           ,irm.goods_transfer_new      irm_goods_transfer_new        -- ���i�U��(�V���i)
--           ,irm.sample_quantity         irm_sample_quantity           -- ���{�o��
--           ,irm.sample_quantity_b       irm_sample_quantity_b         -- ���{�o�ɐU��
--           ,irm.customer_sample_ship    irm_customer_sample_ship      -- �ڋq���{�o��
--           ,irm.customer_sample_ship_b  irm_customer_sample_ship_b    -- �ڋq���{�o�ɐU��
--           ,irm.customer_support_ss     irm_customer_support_ss       -- �ڋq���^���{�o��
--           ,irm.customer_support_ss_b   irm_customer_support_ss_b     -- �ڋq���^���{�o�ɐU��
--           ,irm.ccm_sample_ship         irm_ccm_sample_ship           -- �ڋq�L����`��A���Џ��i
--           ,irm.ccm_sample_ship_b       irm_ccm_sample_ship_b         -- �ڋq�L����`��A���Џ��i�U��
--           ,irm.vd_supplement_stock     irm_vd_supplement_stock       -- ����VD��[����
--           ,irm.vd_supplement_ship      irm_vd_supplement_ship        -- ����VD��[�o��
--           ,irm.inventory_change_in     irm_inventory_change_in       -- ��݌ɕύX����
--           ,irm.inventory_change_out    irm_inventory_change_out      -- ��݌ɕύX�o��
--           ,irm.factory_return          irm_factory_return            -- �H��ԕi
--           ,irm.factory_return_b        irm_factory_return_b          -- �H��ԕi�U��
--           ,irm.factory_change          irm_factory_change            -- �H��q��
--           ,irm.factory_change_b        irm_factory_change_b          -- �H��q�֐U��
--           ,irm.removed_goods           irm_removed_goods             -- �p�p
--           ,irm.removed_goods_b         irm_removed_goods_b           -- �p�p�U��
--           ,irm.factory_stock           irm_factory_stock             -- �H�����
--           ,irm.factory_stock_b         irm_factory_stock_b           -- �H����ɐU��
--           ,irm.wear_decrease           irm_wear_decrease             -- �I�����Ց�
--           ,irm.wear_increase           irm_wear_increase             -- �I�����Ռ�
--           ,irm.selfbase_ship           irm_selfbase_ship             -- �ۊǏꏊ�ړ��Q�����_�o��
--           ,irm.selfbase_stock          irm_selfbase_stock            -- �ۊǏꏊ�ړ��Q�����_����
--           ,irm.inv_result              irm_inv_result                -- �I������
--           ,irm.inv_result_bad          irm_inv_result_bad            -- �I������(�s�Ǖi)
--           ,irm.inv_wear                irm_inv_wear                  -- �I������
--           ,irm.month_begin_quantity    irm_month_begin_quantity      -- ����I����
--    FROM    xxcoi_inv_reception_monthly irm                           -- �����݌Ɏ󕥕\(����)
--           ,xxcoi_base_info2_v          biv                           -- ���_���r���[
--           ,mtl_secondary_inventories   msi                           -- �ۊǏꏊ�}�X�^ (INV)
--           ,hz_cust_accounts            hca                           -- �ڋq�}�X�^
--           ,mtl_system_items_b          sib                           -- Disc�i�ڃ}�X�^
--           ,xxcmn_item_mst_b            imb                           -- OPM�i�ڃA�h�I��(XXCMN)
--           ,ic_item_mst_b               iib                           -- OPM�i��        (GMI)
--    WHERE  biv.focus_base_code       = NVL(iv_base_code,gv_user_base)
--    AND    biv.base_code             = irm.base_code
--    AND    irm.organization_id       = msi.organization_id
--    AND    irm.subinventory_code     = msi.secondary_inventory_name
--    AND  ((iv_inventory_kbn          = cv_inv_kbn3
--    AND    irm.practice_month        = gv_inventory_month)
--    OR    (iv_inventory_kbn         <> cv_inv_kbn3
--    AND    irm.practice_date         = gd_inventory_date))
--    AND  ((iv_inventory_kbn          = cv_inv_kbn2
--    AND    irm.inventory_kbn         = cv_inv_kbn4)
--    OR    (iv_inventory_kbn         <> cv_inv_kbn2
--    AND    irm.inventory_kbn         = cv_inv_kbn5))
--    AND    irm.inventory_item_id     = sib.inventory_item_id
--    AND    sib.organization_id       = irm.organization_id
--    AND    sib.segment1              = iib.item_no                   -- OPM�i�ڃR�[�h
--    AND    iib.item_id               = imb.item_id
--    AND  ((iv_output_kbn             = cv_out_kbn1
--    AND    SUBSTR(msi.secondary_inventory_name,6,2)
--                                     = NVL(iv_warehouse,SUBSTR(msi.secondary_inventory_name,6,2)))
--    OR    (iv_output_kbn            <> cv_out_kbn1
--    AND    msi.attribute4            = NVL(iv_left_base,msi.attribute4)))
--    AND (((iv_output_kbn             = cv_out_kbn1
--    AND    msi.attribute1            = cv_subinv_1)
--    OR    (iv_output_kbn            <> cv_out_kbn1
--    AND    msi.attribute1            = cv_subinv_3))                 -- �ۊǏꏊ�敪(�a����)
--    OR  (((iv_output_kbn             = cv_out_kbn1
--    AND    msi.attribute1            = cv_subinv_1)
--    OR    (iv_output_kbn            <> cv_out_kbn1
--    AND    msi.attribute1            = cv_subinv_4))                 -- �ۊǏꏊ�敪(���X)
--    AND  ((msi.attribute13          <> cv_subinv_7                   -- �ۊǏꏊ����(����VD)
--    AND    iv_left_base IS NULL)
--    OR    (iv_left_base IS NOT NULL))))
--    AND    msi.attribute4            = hca.account_number(+)
--    AND    msi.attribute7            = irm.base_code
--    ORDER BY
--           irm_base_code
--          ,DECODE(iv_output_kbn
--          ,cv_out_kbn1
--          ,msi_warehouse_code
--          ,msi_left_base_code)
--          ,iib_gun_code
--          ,iib_item_no;
--
--    -- *** ���[�J���E���R�[�h ***
--    month_rec month_cur%ROWTYPE;
-- == 2009/06/19 V1.3 DELETE END   ===============================================================
--
-- == 2009/06/19 V1.3 Added START ===============================================================
      TYPE  cur_type  IS  REF CURSOR;
      month_cur        cur_type;
      --
      TYPE  rec_type  IS  RECORD(
        irm_practice_month            xxcoi_inv_reception_monthly.practice_month%TYPE               -- �N��
       ,irm_practice_date             xxcoi_inv_reception_monthly.practice_date%TYPE                -- �N����
       ,irm_base_code                 xxcoi_inv_reception_monthly.base_code%TYPE                    -- ���_�R�[�h
       ,biv_base_short_name           xxcoi_base_info2_v.base_short_name%TYPE                       -- ���_����
       ,msi_warehouse_code            mtl_secondary_inventories.secondary_inventory_name%TYPE       -- �q�ɃR�[�h
-- == 2009/08/10 V1.6 Modified START ===============================================================
--       ,msi_left_base_code            mtl_secondary_inventories.attribute4%TYPE                     -- �a����R�[�h
       ,msi_left_base_code            VARCHAR2(150)                                                 -- �a����R�[�h
-- == 2009/08/10 V1.6 Modified END   ===============================================================
       ,msi_warehouse_name            mtl_secondary_inventories.description%TYPE                    -- �q�ɖ���
-- == 2009/08/10 V1.6 Modified START ===============================================================
--       ,hca_left_base_name            hz_cust_accounts.account_name%TYPE                            -- �a���於��
-- == 2009/12/22 V1.10 Modified START ===============================================================
--       ,hca_left_base_name            VARCHAR2(240)                                                 -- �a���於��
       ,hca_left_base_name            VARCHAR2(360)                                                 -- �a���於��
-- == 2009/12/22 V1.10 Modified END   ===============================================================
-- == 2009/08/10 V1.6 Modified END   ===============================================================
       ,iib_gun_code                  ic_item_mst_b.attribute1%TYPE                                 -- �Q�R�[�h
       ,iib_item_no                   ic_item_mst_b.item_no%TYPE                                    -- ���i�R�[�h
       ,imb_item_short_name           xxcmn_item_mst_b.item_short_name%TYPE                         -- ���i����
       ,irm_operation_cost            xxcoi_inv_reception_monthly.operation_cost%TYPE               -- �c�ƌ���
       ,irm_standard_cost             xxcoi_inv_reception_monthly.standard_cost%TYPE                -- �W������
       ,irm_sales_shipped             xxcoi_inv_reception_monthly.sales_shipped%TYPE                -- ����o��
       ,irm_sales_shipped_b           xxcoi_inv_reception_monthly.sales_shipped_b%TYPE              -- ����o�ɐU��
       ,irm_return_goods              xxcoi_inv_reception_monthly.return_goods%TYPE                 -- �ԕi
       ,irm_return_goods_b            xxcoi_inv_reception_monthly.return_goods_b%TYPE               -- �ԕi�U��
       ,irm_warehouse_ship            xxcoi_inv_reception_monthly.warehouse_ship%TYPE               -- �q�ɂ֕Ԍ�
       ,irm_truck_ship                xxcoi_inv_reception_monthly.truck_ship%TYPE                   -- �c�ƎԂ֏o��
       ,irm_others_ship               xxcoi_inv_reception_monthly.others_ship%TYPE                  -- ���o�ɁQ���̑��o��
       ,irm_warehouse_stock           xxcoi_inv_reception_monthly.warehouse_stock%TYPE              -- �q�ɂ�����
       ,irm_truck_stock               xxcoi_inv_reception_monthly.truck_stock%TYPE                  -- �c�ƎԂ�����
       ,irm_others_stock              xxcoi_inv_reception_monthly.others_stock%TYPE                 -- ���o�ɁQ���̑�����
       ,irm_change_stock              xxcoi_inv_reception_monthly.change_stock%TYPE                 -- �q�֓���
       ,irm_change_ship               xxcoi_inv_reception_monthly.change_ship%TYPE                  -- �q�֏o��
       ,irm_goods_transfer_old        xxcoi_inv_reception_monthly.goods_transfer_old%TYPE           -- ���i�U��(�����i)
       ,irm_goods_transfer_new        xxcoi_inv_reception_monthly.goods_transfer_new%TYPE           -- ���i�U��(�V���i)
       ,irm_sample_quantity           xxcoi_inv_reception_monthly.sample_quantity%TYPE              -- ���{�o��
       ,irm_sample_quantity_b         xxcoi_inv_reception_monthly.sample_quantity_b%TYPE            -- ���{�o�ɐU��
       ,irm_customer_sample_ship      xxcoi_inv_reception_monthly.customer_sample_ship%TYPE         -- �ڋq���{�o��
       ,irm_customer_sample_ship_b    xxcoi_inv_reception_monthly.customer_sample_ship_b%TYPE       -- �ڋq���{�o�ɐU��
       ,irm_customer_support_ss       xxcoi_inv_reception_monthly.customer_support_ss%TYPE          -- �ڋq���^���{�o��
       ,irm_customer_support_ss_b     xxcoi_inv_reception_monthly.customer_support_ss_b%TYPE        -- �ڋq���^���{�o�ɐU��
       ,irm_ccm_sample_ship           xxcoi_inv_reception_monthly.ccm_sample_ship%TYPE              -- �ڋq�L����`��A���Џ��i
       ,irm_ccm_sample_ship_b         xxcoi_inv_reception_monthly.ccm_sample_ship_b%TYPE            -- �ڋq�L����`��A���Џ��i�U��
       ,irm_vd_supplement_stock       xxcoi_inv_reception_monthly.vd_supplement_stock%TYPE          -- ����VD��[����
       ,irm_vd_supplement_ship        xxcoi_inv_reception_monthly.vd_supplement_ship%TYPE           -- ����VD��[�o��
       ,irm_inventory_change_in       xxcoi_inv_reception_monthly.inventory_change_in%TYPE          -- ��݌ɕύX����
       ,irm_inventory_change_out      xxcoi_inv_reception_monthly.inventory_change_out%TYPE         -- ��݌ɕύX�o��
       ,irm_factory_return            xxcoi_inv_reception_monthly.factory_return%TYPE               -- �H��ԕi
       ,irm_factory_return_b          xxcoi_inv_reception_monthly.factory_return_b%TYPE             -- �H��ԕi�U��
       ,irm_factory_change            xxcoi_inv_reception_monthly.factory_change%TYPE               -- �H��q��
       ,irm_factory_change_b          xxcoi_inv_reception_monthly.factory_change_b%TYPE             -- �H��q�֐U��
       ,irm_removed_goods             xxcoi_inv_reception_monthly.removed_goods%TYPE                -- �p�p
       ,irm_removed_goods_b           xxcoi_inv_reception_monthly.removed_goods_b%TYPE              -- �p�p�U��
       ,irm_factory_stock             xxcoi_inv_reception_monthly.factory_stock%TYPE                -- �H�����
       ,irm_factory_stock_b           xxcoi_inv_reception_monthly.factory_stock_b%TYPE              -- �H����ɐU��
       ,irm_wear_decrease             xxcoi_inv_reception_monthly.wear_decrease%TYPE                -- �I�����Ց�
       ,irm_wear_increase             xxcoi_inv_reception_monthly.wear_increase%TYPE                -- �I�����Ռ�
       ,irm_selfbase_ship             xxcoi_inv_reception_monthly.selfbase_ship%TYPE                -- �ۊǏꏊ�ړ��Q�����_�o��
       ,irm_selfbase_stock            xxcoi_inv_reception_monthly.selfbase_stock%TYPE               -- �ۊǏꏊ�ړ��Q�����_����
       ,irm_inv_result                xxcoi_inv_reception_monthly.inv_result%TYPE                   -- �I������
       ,irm_inv_result_bad            xxcoi_inv_reception_monthly.inv_result_bad%TYPE               -- �I������(�s�Ǖi)
       ,irm_inv_wear                  xxcoi_inv_reception_monthly.inv_wear%TYPE                     -- �I������
       ,irm_month_begin_quantity      xxcoi_inv_reception_monthly.month_begin_quantity%TYPE         -- ����I����
      );
      month_rec       rec_type;
      --
-- == 2009/06/19 V1.3 Added END   ===============================================================
-- == 2009/09/15 V1.9 Added START ===============================================================
    -- ���_���擾
    CURSOR  acct_num_cur
    IS
      SELECT  hca.account_number                  account_number  -- ���_�R�[�h
             ,SUBSTRB(hca.account_name, 1, 8)     account_name    -- ���_����
      FROM    hz_cust_accounts      hca                           -- �ڋq�}�X�^
             ,xxcmm_cust_accounts   xca                           -- �ڋq�ǉ����
      WHERE   hca.cust_account_id       =   xca.customer_id
      AND     hca.customer_class_code   =   '1'
      AND     hca.status                =   'A'
      AND     xca.management_base_code  =   NVL(iv_base_code, gv_user_base);
    --
    acct_num_rec    acct_num_cur%ROWTYPE;
    --
    TYPE acct_data_rtype IS RECORD(
      account_number    hz_cust_accounts.account_number%TYPE
     ,account_name      hz_cust_accounts.account_name%TYPE
    );
    TYPE acct_data_ttype IS TABLE OF acct_data_rtype INDEX BY BINARY_INTEGER ;
    acct_data_tab                    acct_data_ttype;
-- == 2009/09/15 V1.9 Added END   ===============================================================
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
-- == 2009/09/15 V1.9 Modified START ===============================================================
---- == 2009/06/19 V1.3 Modified START ===============================================================
----  OPEN month_cur;
--  --
--  lv_sql_str  :=  NULL;
--  -- SQL�ݒ�
--  lv_sql_str  :=    'SELECT '
---- == 2009/08/06 V1.5 Added START ===============================================================
--                ||  '/*+ leading(biv msi irm) */'
---- == 2009/08/06 V1.5 Added START ===============================================================
--                ||  'irm.practice_month  irm_practice_month '
--                ||  ',irm.practice_date  irm_practice_date '
--                ||  ',irm.base_code  irm_base_code '
--                ||  ',biv.base_short_name  biv_base_short_name '
--                ||  ',SUBSTR(msi.secondary_inventory_name, 6, 2)  msi_warehouse_code '
---- == 2009/08/10 V1.6 Modified START ===============================================================
----                ||  ',msi.attribute4  msi_left_base_code '
--                ||  ',DECODE(msi.attribute13, ' || '''' || cv_subinv_7 || ''''
--                ||  ', msi.secondary_inventory_name, msi.attribute4)  msi_left_base_code '
---- == 2009/08/10 V1.6 Modified END   ===============================================================
--                ||  ',msi.description  msi_warehouse_name '
---- == 2009/08/10 V1.6 Modified START ===============================================================
----                ||  ',hca.account_name  hca_left_base_name '
--                ||  ',DECODE(msi.attribute13, ' || '''' || cv_subinv_7 || ''''
--                ||  ', msi.description, hca.account_name)  hca_left_base_name '
---- == 2009/08/10 V1.6 Modified END   ===============================================================
--                ||  ',SUBSTR((CASE '
--                ||  'WHEN TRUNC(TO_DATE(iib.attribute3,' || '''' || 'YYYY/MM/DD' || '''' || ')) > TRUNC(TO_DATE(' 
--                ||  '''' || TO_CHAR(gd_target_date, 'YYYY/MM/DD') || '''' || ',' || '''' || 'YYYY/MM/DD' || '''' || ')) '
--                ||  'THEN iib.attribute1 '
--                ||  'ELSE iib.attribute2 '
--                ||  'END),1,3)  iib_gun_code '
--                ||  ',iib.item_no  iib_item_no '
--                ||  ',imb.item_short_name  imb_item_short_name '
--                ||  ',irm.operation_cost  irm_operation_cost '
--                ||  ',irm.standard_cost  irm_standard_cost '
--                ||  ',irm.sales_shipped  irm_sales_shipped '
--                ||  ',irm.sales_shipped_b  irm_sales_shipped_b '
--                ||  ',irm.return_goods  irm_return_goods '
--                ||  ',irm.return_goods_b  irm_return_goods_b '
--                ||  ',irm.warehouse_ship  irm_warehouse_ship '
--                ||  ',irm.truck_ship  irm_truck_ship '
--                ||  ',irm.others_ship  irm_others_ship '
--                ||  ',irm.warehouse_stock  irm_warehouse_stock '
--                ||  ',irm.truck_stock  irm_truck_stock '
--                ||  ',irm.others_stock  irm_others_stock '
--                ||  ',irm.change_stock  irm_change_stock '
--                ||  ',irm.change_ship  irm_change_ship '
--                ||  ',irm.goods_transfer_old  irm_goods_transfer_old '
--                ||  ',irm.goods_transfer_new  irm_goods_transfer_new '
--                ||  ',irm.sample_quantity  irm_sample_quantity '
--                ||  ',irm.sample_quantity_b  irm_sample_quantity_b '
--                ||  ',irm.customer_sample_ship  irm_customer_sample_ship '
--                ||  ',irm.customer_sample_ship_b  irm_customer_sample_ship_b '
--                ||  ',irm.customer_support_ss  irm_customer_support_ss '
--                ||  ',irm.customer_support_ss_b  irm_customer_support_ss_b '
--                ||  ',irm.ccm_sample_ship  irm_ccm_sample_ship '
--                ||  ',irm.ccm_sample_ship_b  irm_ccm_sample_ship_b '
--                ||  ',irm.vd_supplement_stock  irm_vd_supplement_stock '
--                ||  ',irm.vd_supplement_ship  irm_vd_supplement_ship '
--                ||  ',irm.inventory_change_in  irm_inventory_change_in '
--                ||  ',irm.inventory_change_out  irm_inventory_change_out '
--                ||  ',irm.factory_return  irm_factory_return '
--                ||  ',irm.factory_return_b  irm_factory_return_b '
--                ||  ',irm.factory_change  irm_factory_change '
--                ||  ',irm.factory_change_b  irm_factory_change_b '
--                ||  ',irm.removed_goods  irm_removed_goods '
--                ||  ',irm.removed_goods_b  irm_removed_goods_b '
--                ||  ',irm.factory_stock  irm_factory_stock '
--                ||  ',irm.factory_stock_b  irm_factory_stock_b '
--                ||  ',irm.wear_decrease  irm_wear_decrease '
--                ||  ',irm.wear_increase  irm_wear_increase '
--                ||  ',irm.selfbase_ship  irm_selfbase_ship '
--                ||  ',irm.selfbase_stock  irm_selfbase_stock '
--                ||  ',irm.inv_result  irm_inv_result '
--                ||  ',irm.inv_result_bad  irm_inv_result_bad '
--                ||  ',irm.inv_wear  irm_inv_wear '
--                ||  ',irm.month_begin_quantity  irm_month_begin_quantity ';
--  --
--  -- FROM��
--  lv_sql_str  :=    lv_sql_str
--                ||  'FROM '
--                ||  'xxcoi_inv_reception_monthly  irm '
--                ||  ',mtl_secondary_inventories  msi '
--                ||  ',hz_cust_accounts  hca '
--                ||  ',mtl_system_items_b  sib '
--                ||  ',xxcmn_item_mst_b  imb '
--                ||  ',ic_item_mst_b  iib '
---- == 2009/08/06 V1.5 Modified START ===============================================================
----                ||  ',xxcoi_base_info2_v  biv ';
--                ||  ',(SELECT  hca.account_number '
--                ||  '         ,SUBSTRB(hca.account_name,1,8)  base_short_name '
--                ||  '  FROM    hz_cust_accounts    hca '
--                ||  '         ,xxcmm_cust_accounts xca ';
---- == 2009/08/10 V1.6 Modified START ===============================================================
--  IF (iv_base_code IS NOT NULL) THEN
--    --�p�����[�^.���_���ݒ肳��Ă���ꍇ
--    lv_sql_str  :=    lv_sql_str
----                ||  '  WHERE   xca.management_base_code  =   NVL(' || iv_base_code || ', ' || gv_user_base || ') '
--                ||  '  WHERE   xca.management_base_code  ='   || '''' || iv_base_code || ''' ';
--  ELSE
--    --�p�����[�^.���_���ݒ肳��Ă��Ȃ��ꍇ
--    lv_sql_str  :=    lv_sql_str
--                ||  '  WHERE   xca.management_base_code  ='   || '''' || gv_user_base || ''' ';
--  END IF;
--  lv_sql_str  :=    lv_sql_str
---- == 2009/08/10 V1.6 Modified END   ===============================================================
--                ||  '  AND     hca.status                ='   || '''' || 'A' || ''' '
--                ||  '  AND     hca.customer_class_code   ='   || '''' || '1' || ''' '
--                ||  '  AND     hca.cust_account_id       =   xca.customer_id '
--                ||  '  UNION '
--                ||  '  SELECT  hca.account_number '
--                ||  '         ,SUBSTRB(hca.account_name,1,8)  base_short_name '
--                ||  '  FROM    hz_cust_accounts    hca '
--                ||  '         ,xxcmm_cust_accounts xca ';
---- == 2009/08/10 V1.6 Modified START ===============================================================
--  IF (iv_base_code IS NOT NULL) THEN
--    --�p�����[�^.���_���ݒ肳��Ă���ꍇ
--    lv_sql_str  :=    lv_sql_str
----                ||  '  WHERE   xca.management_base_code  =   NVL(' || iv_base_code || ', ' || gv_user_base || ') '
---- == 2009/09/05 V1.8 Modified START ===============================================================
----                ||  '  WHERE   xca.management_base_code  ='   || '''' || iv_base_code || ''' ';
--                ||  '  WHERE   xca.customer_code  ='   || '''' || iv_base_code || ''' ';
---- == 2009/09/05 V1.8 Modified END   ===============================================================
--  ELSE
--    --�p�����[�^.���_���ݒ肳��Ă��Ȃ��ꍇ
--    lv_sql_str  :=    lv_sql_str
---- == 2009/09/05 V1.8 Modified START ===============================================================
----                ||  '  WHERE   xca.management_base_code  ='   || '''' || gv_user_base || ''' ';
--                ||  '  WHERE   xca.customer_code  ='   || '''' || gv_user_base || ''' ';
---- == 2009/09/05 V1.8 Modified END   ===============================================================
--  END IF;
--  lv_sql_str  :=    lv_sql_str
---- == 2009/08/10 V1.6 Modified END   ===============================================================
--                ||  '  AND     hca.status                ='   || '''' || 'A' || ''' '
--                ||  '  AND     hca.customer_class_code   ='   || '''' || '1' || ''' '
--                ||  '  AND     hca.cust_account_id       =   xca.customer_id '
--                ||  ' )       biv ';
---- == 2009/08/06 V1.5 Modified END   ===============================================================
--  -- WHERE��
--  --
---- == 2009/08/06 V1.5 Deleted START ===============================================================
----  IF (iv_base_code IS NOT NULL) THEN
----    -- �p�����[�^.���_���ݒ肳��Ă���ꍇ
----    lv_sql_str  :=    lv_sql_str
----                  ||  'WHERE biv.focus_base_code = ' || '''' || iv_base_code || '''' || ' ';
----  ELSE
----    -- �p�����[�^.���_���ݒ肳��Ă��Ȃ��ꍇ
----    lv_sql_str  :=    lv_sql_str
----                  ||  'WHERE biv.focus_base_code = ' || '''' || gv_user_base || '''' || ' ';
----  END IF;
---- == 2009/08/06 V1.5 Deleted END   ===============================================================
--  --
--  lv_sql_str  :=    lv_sql_str
---- == 2009/08/06 V1.5 Modified START ===============================================================
----                ||  'AND biv.base_code = irm.base_code '
----                ||  'AND irm.organization_id = msi.organization_id '
----                ||  'AND irm.subinventory_code = msi.secondary_inventory_name '
--                ||  'WHERE biv.account_number = msi.attribute7 '
--                ||  'AND   msi.organization_id = ' || gn_organization_id || ' '
--                ||  'AND   msi.attribute7 = irm.base_code '
--                ||  'AND   msi.organization_id = irm.organization_id '
--                ||  'AND   msi.secondary_inventory_name = irm.subinventory_code '
---- == 2009/08/06 V1.5 Modified END   ===============================================================
--                ||  'AND irm.inventory_item_id = sib.inventory_item_id '
--                ||  'AND sib.organization_id = irm.organization_id '
--                ||  'AND sib.segment1 = iib.item_no '
--                ||  'AND iib.item_id = imb.item_id '
---- == 2009/09/11 V1.8 Added START ===============================================================
--                ||  'AND TRUNC(TO_DATE(' 
--                ||  '''' || TO_CHAR(gd_target_date, 'YYYY/MM/DD') || '''' || ',' || '''' || 'YYYY/MM/DD' || '''' || ')) '
--                ||  'BETWEEN TRUNC(imb.start_date_active) AND TRUNC(imb.end_date_active) '
---- == 2009/09/11 V1.8 Added END   ===============================================================
--                ||  'AND msi.attribute4 = hca.account_number(+) '
--                ||  'AND msi.attribute7 = irm.base_code ';
--  --
--  IF (iv_inventory_kbn = cv_inv_kbn2) THEN
--    -- �����̏ꍇ
--    lv_sql_str  :=    lv_sql_str
--                  ||  'AND irm.practice_date = TO_DATE(' || '''' || TO_CHAR(gd_inventory_date, 'YYYY/MM/DD') || '''' || ',' || '''' || 'YYYY/MM/DD' || '''' || ') '
--                  ||  'AND irm.inventory_kbn = ' || '''' || cv_inv_kbn4 || '''' || ' ';
--  ELSE
--    -- �����̏ꍇ
--    lv_sql_str  :=    lv_sql_str
--                  ||  'AND irm.practice_month = ' || '''' || gv_inventory_month || '''' || ' '
--                  ||  'AND irm.inventory_kbn = ' || '''' || cv_inv_kbn5 || '''' || ' ';
--  END IF;
--  --
--  IF (iv_output_kbn = cv_out_kbn1)  THEN
--    -- �q�ɂ̏ꍇ
--    lv_sql_str  :=    lv_sql_str
--                  ||  'AND msi.attribute1 = ' || '''' || cv_subinv_1 || '''' || ' ';
--    IF (iv_warehouse IS NOT NULL) THEN
--      -- �q�ɂ��w�肳��Ă���ꍇ
--      lv_sql_str  :=    lv_sql_str
--                    ||  'AND SUBSTR(msi.secondary_inventory_name, 6, 2) = ' || '''' || iv_warehouse || '''' || ' ';
--    END IF;
--  ELSE
--    -- �a����̏ꍇ
--    lv_sql_str  :=    lv_sql_str
--                  ||  'AND msi.attribute1  IN(' || '''' || cv_subinv_3 || '''' || ',' || '''' || cv_subinv_4 || '''' || ') ';
---- == 2009/08/10 V1.6 Deleted START ===============================================================
----                  ||  'AND msi.attribute13 <> ' || '''' || cv_subinv_7 || '''' || ' ';
---- == 2009/08/10 V1.6 Deleted END   ===============================================================
--    IF (iv_left_base  IS NOT NULL)  THEN
--      -- �a���悪�w�肳��Ă���ꍇ
--      lv_sql_str  :=    lv_sql_str
---- == 2009/08/10 V1.6 Modified START ===============================================================
----                    ||  'AND msi.attribute4 = ' || '''' || iv_left_base || '''' || ' ';
--                    ||  'AND DECODE(msi.attribute13,  ' || '''' || cv_subinv_7 || ''''
--                    ||  ', msi.secondary_inventory_name, msi.attribute4) = ' || '''' || iv_left_base || '''' || ' ';
---- == 2009/08/10 V1.6 Modified END   ===============================================================
--    END IF;
--  END IF;
--  --
---- == 2009/08/06 V1.5 Deleted START ===============================================================
----  -- ORDER BY��̐ݒ�
----  lv_sql_str  :=    lv_sql_str
----                ||  'ORDER BY '
----                ||  'irm_base_code ';
----  IF (iv_output_kbn = cv_out_kbn1) THEN
----    -- �q�ɂ̏ꍇ
----    lv_sql_str  :=    lv_sql_str
----                  || ',msi_warehouse_code ';
----  ELSE
----    -- �a����̏ꍇ
----    lv_sql_str  :=    lv_sql_str
----                  || ',msi_left_base_code ';
----  END IF;
----  lv_sql_str  :=    lv_sql_str
----                ||  ',iib_gun_code '
----                ||  ',iib_item_no';
---- == 2009/08/06 V1.5 Deleted END   ===============================================================
--  --
--  -- �J�[�\��OPEN
--  OPEN  month_cur FOR lv_sql_str;
---- == 2009/06/19 V1.3 Modified END   ===============================================================
--
    -- ===================================
    --  �����Ώۋ��_�擾
    -- ===================================
    ln_cnt  :=  0;
    -- �Ǘ������_�̏ꍇ
    <<set_base_loop>>
    FOR acct_num_rec  IN  acct_num_cur LOOP
-- == V1.13 Modified START ===============================================================
--      -- �Ώۋ��_���Ǘ������_�̏ꍇ�A�Ǌ����_�S�Ă�ΏۂƂ���
--      ln_cnt  :=  ln_cnt + 1;
--      acct_data_tab(ln_cnt).account_number  :=  acct_num_rec.account_number;
--      acct_data_tab(ln_cnt).account_name    :=  acct_num_rec.account_name;
      -- �Ώۋ��_���Ǘ������_�̏ꍇ�A�Ǌ����_�S�Ă�ΏۂƂ���
      -- �������p�t�H�[�}���X����̂��߁A�󕥕\�ɑ��݂��鋒�_�݂̂ɍi��
      --
      -- ������
      ln_cnt2 := 0;
      --
      -- �����̏ꍇ
      IF (iv_inventory_kbn = cv_inv_kbn2) THEN
        SELECT  /*+ leading(msi irm) */
                COUNT(1)                     AS cnt
        INTO    ln_cnt2
        FROM    mtl_secondary_inventories    msi
               ,xxcoi_inv_reception_monthly  irm
        WHERE   msi.attribute7               = acct_num_rec.account_number
        AND     msi.organization_id          = irm.organization_id
        AND     msi.attribute7               = irm.base_code
        AND     msi.secondary_inventory_name = irm.subinventory_code
        AND     msi.organization_id          = gn_organization_id
        AND     irm.practice_date            = gd_inventory_date
        AND     irm.inventory_kbn            = cv_inv_kbn4
        AND     msi.attribute1               = cv_subinv_1
        ;
      -- �����̏ꍇ
      ELSE
        -- �q�ɂ̏ꍇ
        IF (iv_output_kbn = cv_out_kbn1)  THEN
          SELECT  /*+ leading(msi irm) */
                  COUNT(1)                     AS cnt
          INTO    ln_cnt2
          FROM    mtl_secondary_inventories    msi
                 ,xxcoi_inv_reception_monthly  irm
          WHERE   msi.attribute7               = acct_num_rec.account_number
          AND     msi.organization_id          = irm.organization_id
          AND     msi.attribute7               = irm.base_code
          AND     msi.secondary_inventory_name = irm.subinventory_code
          AND     msi.organization_id          = gn_organization_id
          AND     irm.practice_month           = gv_inventory_month
          AND     irm.inventory_kbn            = cv_inv_kbn5
          AND     msi.attribute1               = cv_subinv_1
          ;
        -- �a����̏ꍇ
        ELSE
          SELECT  /*+ leading(msi irm) */
                  COUNT(1)                     AS cnt
          INTO    ln_cnt2
          FROM    mtl_secondary_inventories    msi
                 ,xxcoi_inv_reception_monthly  irm
          WHERE   msi.attribute7               = acct_num_rec.account_number
          AND     msi.organization_id          = irm.organization_id
          AND     msi.attribute7               = irm.base_code
          AND     msi.secondary_inventory_name = irm.subinventory_code
          AND     msi.organization_id          = gn_organization_id
          AND     irm.practice_month           = gv_inventory_month
          AND     irm.inventory_kbn            = cv_inv_kbn5
          AND     msi.attribute1               IN (cv_subinv_3, cv_subinv_4)
          ;
        END IF;
      END IF;
      --
      IF ( ln_cnt2 > 0 ) THEN
        ln_cnt := ln_cnt + 1;
        acct_data_tab(ln_cnt).account_number  :=  acct_num_rec.account_number;
        acct_data_tab(ln_cnt).account_name    :=  acct_num_rec.account_name;
      END IF;
      --
-- == V1.13 Modified END ===============================================================
    END LOOP set_base_loop;
    --
    IF (ln_cnt = 0) THEN
      -- �Ǘ������_�ȊO�̏ꍇ
      ln_cnt  :=  1;
      --
      SELECT  hca.account_number
             ,SUBSTRB(hca.account_name, 1, 8)
      INTO    acct_data_tab(ln_cnt).account_number
             ,acct_data_tab(ln_cnt).account_name
      FROM    hz_cust_accounts    hca
      WHERE   hca.account_number        =   NVL(iv_base_code, gv_user_base)
      AND     hca.customer_class_code   =   '1'
      AND     hca.status                =   'A';
      --
    END IF;
    --
    -- ===================================
    --  ���[���[�N�e�[�u���쐬
    -- ===================================
    <<get_data_loop>>
    FOR ln_cnt IN  1 .. acct_data_tab.LAST LOOP
      -- ===================================
      --  SQL�ݒ�
      -- ===================================
      lv_sql_str  :=  NULL;
      --
-- == V1.13 Modified START ===============================================================
--      lv_sql_str  :=    'SELECT '
--                    ||  '/*+ leading(msi irm) */'
--                    ||  'irm.practice_month  irm_practice_month '
      lv_sql_str  :=    'SELECT ';
      IF (iv_inventory_kbn = cv_inv_kbn2) THEN
        -- �����̏ꍇ
        lv_sql_str  :=    lv_sql_str
                      ||  '/*+ leading(msi irm) INDEX(msi XXCOI_MSI_N01) INDEX(irm XXCOI_INV_RECEPTION_MONTH_N04) */';
      ELSE
        -- �����̏ꍇ
        lv_sql_str  :=    lv_sql_str
                      ||  '/*+ leading(msi irm) INDEX(msi XXCOI_MSI_N01) INDEX(irm XXCOI_INV_RECEPTION_MONTH_N02) */';
      END IF;
      --/
      lv_sql_str  :=    lv_sql_str
                    ||  ' irm.practice_month  irm_practice_month '
-- == V1.13 Modified END ===============================================================
                    ||  ',irm.practice_date  irm_practice_date '
                    ||  ',irm.base_code  irm_base_code '
                    ||  ',NULL '
                    ||  ',SUBSTR(msi.secondary_inventory_name, 6, 2)  msi_warehouse_code '
                    ||  ',DECODE(msi.attribute13, :bind_variables_1, msi.secondary_inventory_name '
                    ||  ', msi.attribute4 '
                    ||  ')  msi_left_base_code '
                    ||  ',msi.description  msi_warehouse_name '
                    ||  ',DECODE(msi.attribute13, :bind_variables_2, msi.description '
-- == 2009/12/22 V1.10 Modified START ===============================================================
--                    ||  ', hca.account_name '
                    ||  ', hp.party_name '
-- == 2009/12/22 V1.10 Modified END   ===============================================================
                    ||  ')  hca_left_base_name '
                    ||  ',SUBSTR((CASE WHEN (TO_DATE(iib.attribute3, :bind_variables_3)) > TRUNC(:bind_variables_4) '
                    ||  'THEN iib.attribute1 '
                    ||  'ELSE iib.attribute2 '
                    ||  'END),1,3)  iib_gun_code '
                    ||  ',iib.item_no  iib_item_no '
                    ||  ',imb.item_short_name  imb_item_short_name '
                    ||  ',irm.operation_cost  irm_operation_cost '
                    ||  ',irm.standard_cost  irm_standard_cost '
                    ||  ',irm.sales_shipped  irm_sales_shipped '
                    ||  ',irm.sales_shipped_b  irm_sales_shipped_b '
                    ||  ',irm.return_goods  irm_return_goods '
                    ||  ',irm.return_goods_b  irm_return_goods_b '
                    ||  ',irm.warehouse_ship  irm_warehouse_ship '
                    ||  ',irm.truck_ship  irm_truck_ship '
                    ||  ',irm.others_ship  irm_others_ship '
                    ||  ',irm.warehouse_stock  irm_warehouse_stock '
                    ||  ',irm.truck_stock  irm_truck_stock '
                    ||  ',irm.others_stock  irm_others_stock '
                    ||  ',irm.change_stock  irm_change_stock '
                    ||  ',irm.change_ship  irm_change_ship '
                    ||  ',irm.goods_transfer_old  irm_goods_transfer_old '
                    ||  ',irm.goods_transfer_new  irm_goods_transfer_new '
                    ||  ',irm.sample_quantity  irm_sample_quantity '
                    ||  ',irm.sample_quantity_b  irm_sample_quantity_b '
                    ||  ',irm.customer_sample_ship  irm_customer_sample_ship '
                    ||  ',irm.customer_sample_ship_b  irm_customer_sample_ship_b '
                    ||  ',irm.customer_support_ss  irm_customer_support_ss '
                    ||  ',irm.customer_support_ss_b  irm_customer_support_ss_b '
                    ||  ',irm.ccm_sample_ship  irm_ccm_sample_ship '
                    ||  ',irm.ccm_sample_ship_b  irm_ccm_sample_ship_b '
                    ||  ',irm.vd_supplement_stock  irm_vd_supplement_stock '
                    ||  ',irm.vd_supplement_ship  irm_vd_supplement_ship '
                    ||  ',irm.inventory_change_in  irm_inventory_change_in '
                    ||  ',irm.inventory_change_out  irm_inventory_change_out '
                    ||  ',irm.factory_return  irm_factory_return '
                    ||  ',irm.factory_return_b  irm_factory_return_b '
                    ||  ',irm.factory_change  irm_factory_change '
                    ||  ',irm.factory_change_b  irm_factory_change_b '
                    ||  ',irm.removed_goods  irm_removed_goods '
                    ||  ',irm.removed_goods_b  irm_removed_goods_b '
                    ||  ',irm.factory_stock  irm_factory_stock '
                    ||  ',irm.factory_stock_b  irm_factory_stock_b '
                    ||  ',irm.wear_decrease  irm_wear_decrease '
                    ||  ',irm.wear_increase  irm_wear_increase '
                    ||  ',irm.selfbase_ship  irm_selfbase_ship '
                    ||  ',irm.selfbase_stock  irm_selfbase_stock '
                    ||  ',irm.inv_result  irm_inv_result '
                    ||  ',irm.inv_result_bad  irm_inv_result_bad '
                    ||  ',irm.inv_wear  irm_inv_wear '
                    ||  ',irm.month_begin_quantity  irm_month_begin_quantity '
                    -- FROM��
                    ||  'FROM '
                    ||  'xxcoi_inv_reception_monthly  irm '
                    ||  ',mtl_secondary_inventories  msi '
                    ||  ',hz_cust_accounts  hca '
                    ||  ',mtl_system_items_b  sib '
                    ||  ',xxcmn_item_mst_b  imb '
                    ||  ',ic_item_mst_b  iib '
-- == 2009/12/22 V1.10 Added START ===============================================================
                    ||  ',hz_parties  hp '
-- == 2009/12/22 V1.10 Added END   ===============================================================
                    -- WHERE��
                    ||  'WHERE msi.attribute7 = :bind_variables_5 '
                    ||  'AND   msi.organization_id = :bind_variables_6 '
                    ||  'AND   msi.attribute7 = irm.base_code '
                    ||  'AND   msi.organization_id = irm.organization_id '
                    ||  'AND   msi.secondary_inventory_name = irm.subinventory_code '
                    ||  'AND   msi.attribute7 = irm.base_code '
                    ||  'AND   irm.inventory_item_id = sib.inventory_item_id '
                    ||  'AND   sib.organization_id = irm.organization_id '
                    ||  'AND   sib.segment1 = iib.item_no '
                    ||  'AND   iib.item_id = imb.item_id '
                    ||  'AND   TRUNC(:bind_variables_7) BETWEEN TRUNC(imb.start_date_active) AND TRUNC(imb.end_date_active) '
-- == 2009/12/22 V1.10 Modified START ===============================================================
--                    ||  'AND   msi.attribute4 = hca.account_number(+) ';
                    ||  'AND   msi.attribute4 = hca.account_number(+) '
                    ||  'AND   hca.party_id = hp.party_id(+) ';
-- == 2009/12/22 V1.10 Modified END   ===============================================================
      --
      IF (iv_inventory_kbn = cv_inv_kbn2) THEN
        -- �����̏ꍇ
        lv_sql_str  :=    lv_sql_str
                      ||  'AND irm.practice_date = :bind_variables_8 '
                      ||  'AND irm.inventory_kbn = :bind_variables_9 ';
      ELSE
        -- �����̏ꍇ
        lv_sql_str  :=    lv_sql_str
                      ||  'AND irm.practice_month = :bind_variables_10 '
                      ||  'AND irm.inventory_kbn = :bind_variables_11 ';
      END IF;
      --
      IF (iv_output_kbn = cv_out_kbn1)  THEN
        -- �q�ɂ̏ꍇ
        lv_sql_str  :=    lv_sql_str
                      ||  'AND msi.attribute1 = :bind_variables_12 ';
        IF (iv_warehouse IS NOT NULL) THEN
          -- �q�ɂ��w�肳��Ă���ꍇ
          lv_sql_str  :=    lv_sql_str
                        ||  'AND SUBSTR(msi.secondary_inventory_name, 6, 2) = :bind_variables_13 ';
        END IF;
      ELSE
        -- �a����̏ꍇ
        lv_sql_str  :=    lv_sql_str
                      ||  'AND msi.attribute1  IN(:bind_variables_14, :bind_variables_15) ';
        IF (iv_left_base  IS NOT NULL)  THEN
          -- �a���悪�w�肳��Ă���ꍇ
          lv_sql_str  :=    lv_sql_str
                        ||  'AND DECODE(msi.attribute13, :bind_variables_16, msi.secondary_inventory_name '
                        ||  ', msi.attribute4 '
                        ||  ' ) = :bind_variables_17';
        END IF;
      END IF;
      --
      -- =============================
      --  SQL�I�[�v��
      -- =============================
      IF  (iv_output_kbn = cv_out_kbn1) THEN
        IF (iv_warehouse IS NOT NULL) THEN
          IF (iv_inventory_kbn = cv_inv_kbn2) THEN
            -- �o�͋敪�F�q�ɁA�q�ɂ̎w��F����A�I���敪�F����
            OPEN  month_cur FOR lv_sql_str USING IN   cv_subinv_7                             --  1.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,cv_subinv_7                             --  2.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,'YYYY/MM/DD'                            --  3.���t�^
                                                     ,gd_target_date                          --  4.�p�����[�^     �F�I����
                                                     ,acct_data_tab(ln_cnt).account_number    --  5.�Ώۋ��_
                                                     ,gn_organization_id                      --  6.�݌ɑg�DID
                                                     ,gd_target_date                          --  7.�p�����[�^     �F�I����
                                                     ,gd_inventory_date                       --  8.�p�����[�^     �F�I����
                                                     ,cv_inv_kbn4                             --  9.�I���敪      1�F����
                                                     ,cv_subinv_1                             -- 12.�ۊǏꏊ�敪  1�F�q��
                                                     ,iv_warehouse                            -- 13.�p�����[�^     �F�q��
            ;
          ELSE
            -- �o�͋敪�F�q�ɁA�q�ɂ̎w��F����A�I���敪�F����
            OPEN  month_cur FOR lv_sql_str USING IN   cv_subinv_7                             --  1.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,cv_subinv_7                             --  2.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,'YYYY/MM/DD'                            --  3.���t�^
                                                     ,gd_target_date                          --  4.�p�����[�^     �F�I�����̌�����
                                                     ,acct_data_tab(ln_cnt).account_number    --  5.�Ώۋ��_
                                                     ,gn_organization_id                      --  6.�݌ɑg�DID
                                                     ,gd_target_date                          --  7.�p�����[�^     �F�I�����̌�����
                                                     ,gv_inventory_month                      -- 10.�p�����[�^     �F�I����
                                                     ,cv_inv_kbn5                             -- 11.�I���敪      2�F����
                                                     ,cv_subinv_1                             -- 12.�ۊǏꏊ�敪  1�F�q��
                                                     ,iv_warehouse                            -- 13.�p�����[�^     �F�q��
            ;
          END IF;
        ELSE
          IF (iv_inventory_kbn = cv_inv_kbn2) THEN
            -- �o�͋敪�F�q�ɁA�q�ɂ̎w��F�Ȃ��A�I���敪�F����
            OPEN  month_cur FOR lv_sql_str USING IN   cv_subinv_7                             --  1.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,cv_subinv_7                             --  2.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,'YYYY/MM/DD'                            --  3.���t�^
                                                     ,gd_target_date                          --  4.�p�����[�^     �F�I����
                                                     ,acct_data_tab(ln_cnt).account_number    --  5.�Ώۋ��_
                                                     ,gn_organization_id                      --  6.�݌ɑg�DID
                                                     ,gd_target_date                          --  7.�p�����[�^     �F�I����
                                                     ,gd_inventory_date                       --  8.�p�����[�^     �F�I����
                                                     ,cv_inv_kbn4                             --  9.�I���敪      1�F����
                                                     ,cv_subinv_1                             -- 12.�ۊǏꏊ�敪  1�F�q��
            ;
          ELSE
            -- �o�͋敪�F�q�ɁA�q�ɂ̎w��F�Ȃ��A�I���敪�F����
            OPEN  month_cur FOR lv_sql_str USING IN   cv_subinv_7                             --  1.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,cv_subinv_7                             --  2.�ۊǏꏊ����  7�F���̋@(����)
                                                     ,'YYYY/MM/DD'                            --  3.���t�^
                                                     ,gd_target_date                          --  4.�p�����[�^     �F�I�����̌�����
                                                     ,acct_data_tab(ln_cnt).account_number    --  5.�Ώۋ��_
                                                     ,gn_organization_id                      --  6.�݌ɑg�DID
                                                     ,gd_target_date                          --  7.�p�����[�^     �F�I�����̌�����
                                                     ,gv_inventory_month                      -- 10.�p�����[�^     �F�I����
                                                     ,cv_inv_kbn5                             -- 11.�I���敪      2�F����
                                                     ,cv_subinv_1                             -- 12.�ۊǏꏊ�敪  1�F�q��
            ;
          END IF;
        END IF;
      ELSE
        IF (iv_left_base  IS NOT NULL) THEN
          -- �a����̌��������͍s��Ȃ�
          -- �o�͋敪�F�a����A�a����̎w��F����A�I���敪�F����
          OPEN  month_cur FOR lv_sql_str USING IN   cv_subinv_7                             --  1.�ۊǏꏊ����  7�F���̋@(����)
                                                   ,cv_subinv_7                             --  2.�ۊǏꏊ����  7�F���̋@(����)
                                                   ,'YYYY/MM/DD'                            --  3.���t�^
                                                   ,gd_target_date                          --  4.�p�����[�^     �F�I�����̌�����
                                                   ,acct_data_tab(ln_cnt).account_number    --  5.�Ώۋ��_
                                                   ,gn_organization_id                      --  6.�݌ɑg�DID
                                                   ,gd_target_date                          --  7.�p�����[�^     �F�I�����̌�����
                                                   ,gv_inventory_month                      -- 10.�p�����[�^     �F�I����
                                                   ,cv_inv_kbn5                             -- 11.�I���敪      2�F����
                                                   ,cv_subinv_3                             -- 14.�ۊǏꏊ�敪  3�F�a����
                                                   ,cv_subinv_4                             -- 15.�ۊǏꏊ�敪  4�F���X
                                                   ,cv_subinv_7                             -- 16.�ۊǏꏊ����  7�F���̋@(����)
                                                   ,iv_left_base                            -- 17.�p�����[�^     �F�a����
          ;
        ELSE
          -- �o�͋敪�F�a����A�a����̎w��F�Ȃ��A�I���敪�F����
          OPEN  month_cur FOR lv_sql_str USING IN   cv_subinv_7                             --  1.�ۊǏꏊ����  7�F���̋@(����)
                                                   ,cv_subinv_7                             --  2.�ۊǏꏊ����  7�F���̋@(����)
                                                   ,'YYYY/MM/DD'                            --  3.���t�^
                                                   ,gd_target_date                          --  4.�p�����[�^     �F�I�����̌�����
                                                   ,acct_data_tab(ln_cnt).account_number    --  5.�Ώۋ��_
                                                   ,gn_organization_id                      --  6.�݌ɑg�DID
                                                   ,gd_target_date                          --  7.�p�����[�^     �F�I�����̌�����
                                                   ,gv_inventory_month                      -- 10.�p�����[�^     �F�I����
                                                   ,cv_inv_kbn5                             -- 11.�I���敪      2�F����
                                                   ,cv_subinv_3                             -- 14.�ۊǏꏊ�敪  3�F�a����
                                                   ,cv_subinv_4                             -- 15.�ۊǏꏊ�敪  4�F���X
          ;
        END IF;
      END IF;
      --
-- == 2009/09/15 V1.9 Modified END   ===============================================================
      <<output_data_loop>>
      LOOP
        FETCH month_cur INTO month_rec;
        EXIT WHEN month_cur%NOTFOUND;
    --
        -- �󕥎c���[ID���J�E���g
        ln_check_num  := ln_check_num  + 1;
        -- �Ώی������J�E���g
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ===================================
        --  ���[�N�e�[�u���f�[�^�o�^(A-4)
        -- ===================================
        INSERT INTO xxcoi_rep_warehouse_rcpt(
                    slit_id                           -- �󕥎c�����ID
                   ,inventory_kbn                     -- �I���敪
                   ,output_kbn                        -- �o�͋敪
                   ,in_out_year                       -- �N
                   ,in_out_month                      -- ��
                   ,in_out_dat                        -- ��
                   ,base_code                         -- ���_�R�[�h
                   ,base_name                         -- ���_����
                   ,warehouse_code                    -- �q��/�a����R�[�h
                   ,warehouse_name                    -- �q��/�a���於��
                   ,gun_code                          -- �Q�R�[�h
                   ,item_code                         -- ���i�R�[�h
                   ,item_name                         -- ���i����
                   ,first_inventory_qty               -- ����I����(����)
                   ,factory_in_qty                    -- �H�����(����)
                   ,kuragae_in_qty                    -- �q�֓���(����)
                   ,car_in_qty                        -- �c�ƎԂ�����(����)
                   ,hurikae_in_qty                    -- �U�֓���(����)
                   ,car_ship_qty                      -- �c�ƎԂ֏o��(����)
                   ,sales_qty                         -- ����o��(����)
                   ,support_qty                       -- ���^���{(����)
                   ,kuragae_ship_qty                  -- �q�֏o��(����)
                   ,factory_return_qty                -- �H��ԕi(����)
                   ,disposal_qty                      -- �p�p�o��(����)
                   ,hurikae_ship_qty                  -- �U�֏o��(����)
                   ,tyoubo_stock_qty                  -- ����݌�(����)
                   ,inventory_qty                     -- �I����(����)
                   ,genmou_qty                        -- �I������(����)
                   ,first_inventory_money             -- ����I����(���z)
                   ,factory_in_money                  -- �H�����(���z)
                   ,kuragae_in_money                  -- �q�֓���(���z)
                   ,car_in_money                      -- �c�ƎԂ�����(���z)
                   ,hurikae_in_money                  -- �U�֓���(���z)
                   ,car_ship_money                    -- �c�ƎԂ֏o��(���z)
                   ,sales_money                       -- ����o��(���z)
                   ,support_money                     -- ���^���{(���z)
                   ,kuragae_ship_money                -- �q�֏o��(���z)
                   ,factory_return_money              -- �H��ԕi(���z)
                   ,disposal_money                    -- �p�p�o��(���z)
                   ,hurikae_ship_money                -- �U�֏o��(���z)
                   ,tyoubo_stock_money                -- ����݌�(���z)
                   ,inventory_money                   -- �I����(���z)
                   ,genmou_money                      -- �I������(���z)
                   ,message                           -- ���b�Z�[�W
                   ,last_update_date                  -- �ŏI�X�V��
                   ,last_updated_by                   -- �ŏI�X�V��
                   ,creation_date                     -- �쐬��
                   ,created_by                        -- �쐬��
                   ,last_update_login                 -- �ŏI�X�V���[�U
                   ,request_id                        -- �v��ID
                   ,program_application_id            -- �v���O�����A�v���P�[�V����ID
                   ,program_id                        -- �v���O����ID
                   ,program_update_date)              -- �v���O�����X�V��
            VALUES (ln_check_num                                              -- �󕥎c�����ID
                   ,gv_inv_kbn                                                -- �I���敪
                   ,gv_out_kbn                                                -- �o�͋敪
                   ,DECODE(iv_inventory_kbn,cv_inv_kbn3
                   ,SUBSTR(month_rec.irm_practice_month,3,2)
                   ,SUBSTR(TO_CHAR(month_rec.irm_practice_date
                                  ,'YYYYMMDD'),3,2))                          -- �N
                   ,DECODE(iv_inventory_kbn,cv_inv_kbn3
                   ,SUBSTR(month_rec.irm_practice_month,5,2)
                   ,SUBSTR(TO_CHAR(month_rec.irm_practice_date
                                  ,'YYYYMMDD'),5,2))                          -- ��
                   ,DECODE(iv_inventory_kbn,cv_inv_kbn3
                   ,NULL
                   ,SUBSTR(TO_CHAR(month_rec.irm_practice_date
                                  ,'YYYYMMDD'),7,2))                          -- ��
                   ,month_rec.irm_base_code                                   -- ���_�R�[�h
-- == 2009/09/15 V1.9 Modified START ===============================================================
--                   ,month_rec.biv_base_short_name
                   ,acct_data_tab(ln_cnt).account_name                        -- ���_����
-- == 2009/09/15 V1.9 Modified END   ===============================================================
                   ,DECODE(iv_output_kbn,cv_out_kbn1
                   ,month_rec.msi_warehouse_code
                   ,month_rec.msi_left_base_code)                             -- �q��/�a����R�[�h
    -- == 2009/08/19 V1.7 Modified START ===============================================================
    --               ,DECODE(iv_output_kbn,cv_out_kbn1
    --               ,month_rec.msi_warehouse_name
    --               ,month_rec.hca_left_base_name)                             -- �q��/�a���於��
                   ,SUBSTRB(DECODE(iv_output_kbn,cv_out_kbn1
                   ,month_rec.msi_warehouse_name
                   ,month_rec.hca_left_base_name), 1, 50)                     -- �q��/�a���於��
    -- == 2009/08/19 V1.7 Modified END   ===============================================================
                   ,month_rec.iib_gun_code                                    -- �Q�R�[�h
                   ,month_rec.iib_item_no                                     -- ���i�R�[�h
                   ,month_rec.imb_item_short_name                             -- ���i����
                   ,month_rec.irm_month_begin_quantity                        -- ����I����(����)
                   ,month_rec.irm_factory_stock                 -
                    month_rec.irm_factory_stock_b                             -- �H�����(����)
                   ,month_rec.irm_change_stock                  +
                    month_rec.irm_selfbase_stock                +
                    month_rec.irm_others_stock                  +
                    month_rec.irm_vd_supplement_stock           +
                    month_rec.irm_inventory_change_in                         -- �q�֓���(����)
                   ,month_rec.irm_truck_stock                                 -- �c�ƎԂ�����(����)
                   ,month_rec.irm_goods_transfer_new                          -- �U�֓���(����)
                   ,month_rec.irm_truck_ship                                  -- �c�ƎԂ֏o��(����)
                   ,month_rec.irm_sales_shipped                 -
                    month_rec.irm_sales_shipped_b               -
                    month_rec.irm_return_goods                  +
                    month_rec.irm_return_goods_b                              -- ����o��(����)
                   ,month_rec.irm_customer_sample_ship          -
                    month_rec.irm_customer_sample_ship_b        +
                    month_rec.irm_customer_support_ss           -
                    month_rec.irm_customer_support_ss_b         +
                    month_rec.irm_sample_quantity               -
                    month_rec.irm_sample_quantity_b             +
                    month_rec.irm_ccm_sample_ship               -
                    month_rec.irm_ccm_sample_ship_b                           -- ���^���{(����)
                   ,month_rec.irm_change_ship                   +
                    month_rec.irm_selfbase_ship                 +
                    month_rec.irm_others_ship                   +
                    month_rec.irm_vd_supplement_ship            +
                    month_rec.irm_inventory_change_out          +
                    month_rec.irm_factory_change                -
                    month_rec.irm_factory_change_b                            -- �q�֏o��(����)
                   ,month_rec.irm_factory_return                -
                    month_rec.irm_factory_return_b                            -- �H��ԕi(����)
                   ,month_rec.irm_removed_goods                 -
                    month_rec.irm_removed_goods_b                             -- �p�p�o��(����)
                   ,month_rec.irm_goods_transfer_old                          -- �U�֏o��(����)
                   ,month_rec.irm_inv_result                    +
                    month_rec.irm_inv_result_bad                +
                    month_rec.irm_inv_wear                                    -- ����݌�(����)
                   ,month_rec.irm_inv_result                    +
                    month_rec.irm_inv_result_bad                              -- �I����(����)
                   ,month_rec.irm_inv_wear                                    -- �I������(����)
                   ,ROUND( month_rec.irm_month_begin_quantity
                         * month_rec.irm_operation_cost)                      -- ����I����(���z)
                   ,ROUND((month_rec.irm_factory_stock          -
                           month_rec.irm_factory_stock_b)
                         * month_rec.irm_operation_cost)                      -- �H�����(���z)
                   ,ROUND((month_rec.irm_change_stock           +
                           month_rec.irm_selfbase_stock         +
                           month_rec.irm_others_stock           +
                           month_rec.irm_vd_supplement_stock    +
                           month_rec.irm_inventory_change_in)
                         * month_rec.irm_operation_cost)                      -- �q�֓���(���z)
                   ,ROUND( month_rec.irm_truck_stock
                         * month_rec.irm_operation_cost)                      -- �c�ƎԂ�����(���z)
                   ,ROUND( month_rec.irm_goods_transfer_new
                         * month_rec.irm_operation_cost)                      -- �U�֓���(���z)
                   ,ROUND( month_rec.irm_truck_ship
                         * month_rec.irm_operation_cost)                      -- �c�ƎԂ֏o��(���z)
                   ,ROUND((month_rec.irm_sales_shipped          -
                           month_rec.irm_sales_shipped_b        -
                           month_rec.irm_return_goods           +
                           month_rec.irm_return_goods_b)
                         * month_rec.irm_operation_cost)                      -- ����o��(���z)
                   ,ROUND((month_rec.irm_customer_sample_ship   -
                           month_rec.irm_customer_sample_ship_b +
                           month_rec.irm_customer_support_ss    -
                           month_rec.irm_customer_support_ss_b  +
                           month_rec.irm_sample_quantity        -
                           month_rec.irm_sample_quantity_b      +
                           month_rec.irm_ccm_sample_ship        -
                           month_rec.irm_ccm_sample_ship_b)
                         * month_rec.irm_operation_cost)                      -- ���^���{(���z)
                   ,ROUND((month_rec.irm_change_ship            +
                           month_rec.irm_selfbase_ship          +
                           month_rec.irm_others_ship            +
                           month_rec.irm_vd_supplement_ship     +
                           month_rec.irm_inventory_change_out   +
                           month_rec.irm_factory_change         -
                           month_rec.irm_factory_change_b)
                         * month_rec.irm_operation_cost)                      -- �q�֏o��(���z)
                   ,ROUND((month_rec.irm_factory_return         -
                           month_rec.irm_factory_return_b)
                         * month_rec.irm_operation_cost)                      -- �H��ԕi(���z)
                   ,ROUND((month_rec.irm_removed_goods          -
                           month_rec.irm_removed_goods_b)
                         * month_rec.irm_operation_cost)                      -- �p�p�o��(���z)
                   ,ROUND( month_rec.irm_goods_transfer_old
                         * month_rec.irm_operation_cost)                      -- �U�֏o��(���z)
                   ,ROUND((month_rec.irm_inv_result             +
                           month_rec.irm_inv_result_bad         +
                           month_rec.irm_inv_wear)
                         * month_rec.irm_operation_cost)                      -- ����݌�(���z)
                   ,ROUND((month_rec.irm_inv_result             +
                           month_rec.irm_inv_result_bad)
                         * month_rec.irm_operation_cost)                      -- �I����(���z)
                   ,ROUND( month_rec.irm_inv_wear
                         * month_rec.irm_operation_cost)                      -- �I������(���z)
                   ,NULL                                                      -- ���b�Z�[�W
                   ,SYSDATE                                                   -- �ŏI�X�V��
                   ,cn_last_updated_by                                        -- �ŏI�X�V��
                   ,SYSDATE                                                   -- �쐬��
                   ,cn_created_by                                             -- �쐬��
                   ,cn_last_update_login                                      -- �ŏI�X�V���[�U
                   ,cn_request_id                                             -- �v��ID
                   ,cn_program_application_id                                 -- �v���O�����A�v���P�[�V����ID
                   ,cn_program_id                                             -- �v���O����ID
                   ,SYSDATE);                                                 -- �v���O�����X�V��
      --
      END LOOP output_data_loop;
-- == 2009/09/15 V1.9 Added START ===============================================================
    END LOOP get_data_loop;
-- == 2009/09/15 V1.9 Added END   ===============================================================
    --
    -- �J�[�\���N���[�Y
    CLOSE month_cur;
    --
    -- ===================================
    --  ����0���̏ꍇ
    -- ===================================
    IF (ln_check_num = 0) THEN
      -- ===================================
      --  0�����b�Z�[�W�擾
      -- ===================================
      lv_message := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcoi_sn
                        ,iv_name         => cv_msg_00008
                       );
      BEGIN
        IF (iv_output_kbn = cv_out_kbn1 AND iv_warehouse IS NOT NULL) THEN
          SELECT msi.description
          INTO   gv_warehouse
          FROM   mtl_secondary_inventories  msi     -- �ۊǏꏊ�}�X�^(INV)
          WHERE  msi.organization_id = gn_organization_id
          AND    SUBSTR(msi.secondary_inventory_name,6,2) = iv_warehouse
          AND    msi.attribute1 = cv_subinv_1
          AND    msi.attribute7 = iv_base_code;
        ELSIF (iv_output_kbn = cv_out_kbn2 AND iv_left_base IS NOT NULL) THEN
  -- == 2009/08/10 V1.6 Modified START ===============================================================
  --        SELECT hca.account_name
  --        INTO   gv_warehouse
  --        FROM   hz_cust_accounts     hca           -- �ڋq�}�X�^
  --        WHERE  hca.account_number = iv_left_base;
-- == 2009/12/22 V1.10 Modified START ===============================================================
--          SELECT DECODE(msi.attribute13, cv_subinv_7, msi.description, hca.account_name)
--          INTO   gv_warehouse
--          FROM   mtl_secondary_inventories msi
--                ,hz_cust_accounts          hca
--          WHERE  msi.attribute4 = hca.account_number(+)
--          AND    DECODE(msi.attribute13, cv_subinv_7, msi.secondary_inventory_name
--                                                    , hca.account_number) = iv_left_base;
          SELECT DECODE(msi.attribute13, cv_subinv_7, msi.description, hp.party_name)
          INTO   gv_warehouse
          FROM   mtl_secondary_inventories msi
                ,hz_cust_accounts          hca
                ,hz_parties                hp
          WHERE  msi.attribute4 = hca.account_number(+)
          AND    hca.party_id   = hp.party_id(+)
          AND    DECODE(msi.attribute13, cv_subinv_7, msi.secondary_inventory_name
                                                    , hca.account_number) = iv_left_base;
-- == 2009/12/22 V1.10 Modified END   ===============================================================
  -- == 2009/08/10 V1.6 Modified END   ===============================================================
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          gv_warehouse := NULL;
      END;
      --
      BEGIN
-- == 2010/04/08 V1.11 Modified START ===============================================================
--      SELECT SUBSTRB(account_name,1,8)            -- ���_����
--      INTO   gv_base_short_name
--      FROM   xxcoi_user_base_info_v               -- ���_�r���[
--      WHERE  account_number = iv_base_code
--      AND    ROWNUM = 1;
      SELECT SUBSTRB(hca.account_name, 1, 8)      -- ���_����
      INTO   gv_base_short_name
      FROM   hz_cust_accounts   hca
      WHERE  hca.account_number = iv_base_code
      AND    hca.customer_class_code = '1'
      AND    hca.status = 'A'
      ;
-- == 2010/04/08 V1.11 Modified END   ===============================================================
      EXCEPTION
        WHEN OTHERS THEN
          gv_base_short_name := NULL;
      END;
      -- ===================================
      --  0�����b�Z�[�W�o��
      -- ===================================
      INSERT INTO xxcoi_rep_warehouse_rcpt(
                  slit_id                           -- �󕥎c�����ID
                 ,inventory_kbn                     -- �I���敪
                 ,output_kbn                        -- �o�͋敪
                 ,in_out_year                       -- �N
                 ,in_out_month                      -- ��
                 ,in_out_dat                        -- ��
                 ,base_code                         -- ���_�R�[�h
                 ,base_name                         -- ���_����
                 ,warehouse_code                    -- �q��/�a����R�[�h
                 ,warehouse_name                    -- �q��/�a���於��
                 ,message                           -- ���b�Z�[�W
                 ,last_update_date                  -- �ŏI�X�V��
                 ,last_updated_by                   -- �ŏI�X�V��
                 ,creation_date                     -- �쐬��
                 ,created_by                        -- �쐬��
                 ,last_update_login                 -- �ŏI�X�V���[�U
                 ,request_id                        -- �v��ID
                 ,program_application_id            -- �v���O�����A�v���P�[�V����ID
                 ,program_id                        -- �v���O����ID
                 ,program_update_date)              -- �v���O�����X�V��
          VALUES (ln_check_num                      -- �󕥎c�����ID
                 ,gv_inv_kbn                        -- �I���敪
                 ,gv_out_kbn                        -- �o�͋敪
                 ,DECODE(iv_inventory_kbn,cv_inv_kbn3
                 ,SUBSTR(gv_inventory_month,3,2)
                 ,SUBSTR(gv_inventory_date,3,2))    -- �N
                 ,DECODE(iv_inventory_kbn,cv_inv_kbn3
                 ,SUBSTR(gv_inventory_month,5,2)
                 ,SUBSTR(gv_inventory_date,5,2))    -- ��
                 ,DECODE(iv_inventory_kbn,cv_inv_kbn3
                 ,NULL
                 ,SUBSTR(gv_inventory_date,7,2))    -- ��
                 ,iv_base_code                      -- ���_�R�[�h
                 ,gv_base_short_name                -- ���_����
                 ,DECODE(iv_output_kbn,cv_out_kbn1
                 ,iv_warehouse
                 ,iv_left_base)                     -- �q��/�a����R�[�h
  -- == 2009/08/19 V1.7 Modified START ===============================================================
  --               ,gv_warehouse                      -- �q��/�a���於��
                 ,SUBSTRB(gv_warehouse, 1, 50)      -- �q��/�a���於��
  -- == 2009/08/19 V1.7 Modified END   ===============================================================
                 ,lv_message                        -- ���b�Z�[�W
                 ,SYSDATE                           -- �ŏI�X�V��
                 ,cn_last_updated_by                -- �ŏI�X�V��
                 ,SYSDATE                           -- �쐬��
                 ,cn_created_by                     -- �쐬��
                 ,cn_last_update_login              -- �ŏI�X�V���[�U
                 ,cn_request_id                     -- �v��ID
                 ,cn_program_application_id         -- �v���O�����A�v���P�[�V����ID
                 ,cn_program_id                     -- �v���O����ID
                 ,SYSDATE);                         -- �v���O�����X�V��
    END IF;
    -- �R�~�b�g
    COMMIT;
    --
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    WHEN global_process_expt THEN                                 --*** <��O�R�����g> ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
      IF (month_cur%ISOPEN) THEN
        CLOSE month_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF (month_cur%ISOPEN) THEN
        CLOSE month_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_month_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   **********************************************************************************/
  PROCEDURE init(
    iv_output_kbn         IN  VARCHAR2,    -- �o�͋敪
    iv_inventory_kbn      IN  VARCHAR2,    -- �I���敪
    iv_inventory_date     IN  VARCHAR2,    -- �I����
    iv_inventory_month    IN  VARCHAR2,    -- �I����
    iv_base_code          IN  VARCHAR2,    -- ���_
    iv_warehouse          IN  VARCHAR2,    -- �q��
    iv_left_base          IN  VARCHAR2,    -- �a����
    ov_errbuf             OUT VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- A-1-1.���ʊ֐�(�Ɩ��������t�擾)���Ɩ����t���擾���܂��B
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_business_date IS NULL) THEN
      -- �Ɩ����t�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00011
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-3.�p�����[�^�̖��̂��ȉ��̂悤�Ɏ擾���܂��B
    -- �o�͋敪����(�q��/�a����)
    gv_out_kbn := xxcoi_common_pkg.get_meaning(cv_output_div,iv_output_kbn);
    --
    IF (gv_out_kbn IS NULL) THEN
      -- �p�����[�^.�o�͋敪���擾�G���[���b�Z�[�W(APP-XXCOI1-10113)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10113
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- �I���敪����(����/����/����)
    gv_inv_kbn := xxcoi_common_pkg.get_meaning(cv_inv_div,iv_inventory_kbn);
    --
    IF (gv_inv_kbn IS NULL) THEN
      -- �p�����[�^.�I���敪���擾�G���[���b�Z�[�W(APP-XXCOI1-10264)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10264
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
-- == 2009/05/13 V1.2 Deleted START ===============================================================
--    -- �o�͋敪�͑q�ɂ̏ꍇ�A�����ΏۊO�ɂȂ�
--    IF (iv_output_kbn = cv_out_kbn1 AND iv_inventory_kbn = cv_inv_kbn3) THEN
--      -- �o�͋敪�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10314)
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                    iv_application  => cv_xxcoi_sn
--                   ,iv_name         => cv_msg_10314
--                   );
--      lv_errbuf := lv_errmsg;
--      lv_retcode := cv_status_error;    -- �ُ�:2
--      gn_error_cnt := gn_error_cnt + 1;
--      RAISE global_process_expt;
--    END IF;
-- == 2009/05/13 V1.2 Deleted END   ===============================================================
    -- A-2-2.�I�����`�F�b�N
    IF (iv_inventory_kbn = cv_inv_kbn3) THEN
      -- NULL�`�F�b�N
      IF (iv_inventory_month IS NULL) THEN
        -- �I����Null�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10103)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10103
                     ,iv_token_name1  => cv_p_token2   -- �I���敪
                     ,iv_token_value1 => gv_inv_kbn
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- �ُ�:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- �^�`�F�b�N
      IF (LENGTH(iv_inventory_month) <> 6) THEN
        -- �I�����̌^(YYYYMM)�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10105)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10105
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- �ُ�:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      BEGIN
        gd_inventory_month := TO_DATE(iv_inventory_month,'YYYYMM');
        gv_inventory_month := TO_CHAR(gd_inventory_month,'YYYYMM');
      EXCEPTION
        WHEN OTHERS THEN
          -- �I�����̌^(YYYYMM)�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10105)
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10105
                       );
          lv_errbuf := lv_errmsg;
          lv_retcode := cv_status_error;    -- �ُ�:2
          gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END;
      -- �������`�F�b�N
      IF (TO_CHAR(gd_inventory_month,'YYYYMM') > TO_CHAR(gd_business_date,'YYYYMM')) THEN
        -- �I�����������`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10198)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10198
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- �ُ�:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- �Ώۓ��ݒ�
      gd_target_date := LAST_DAY(gd_inventory_month);   -- �N���̖���
    -- A-2-1.�I�����`�F�b�N
    ELSE
      -- NULL�`�F�b�N
      IF (iv_inventory_date IS NULL) THEN
        -- �I����Null�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10102)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10102
                     ,iv_token_name1  => cv_p_token2   -- �I���敪
                     ,iv_token_value1 => gv_inv_kbn
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- �ُ�:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- �^�`�F�b�N
      IF (LENGTH(iv_inventory_date) <> 8) THEN
        -- �I�����̌^(YYYYMMDD)�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10104)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10104
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- �ُ�:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      BEGIN
        gd_inventory_date := TO_DATE(iv_inventory_date,'YYYYMMDD');
        gv_inventory_date := TO_CHAR(gd_inventory_date,'YYYYMMDD');
      EXCEPTION
        WHEN OTHERS THEN
          -- �I�����̌^(YYYYMMDD)�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10104)
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcoi_sn
                       ,iv_name         => cv_msg_10104
                       );
          lv_errbuf := lv_errmsg;
          lv_retcode := cv_status_error;    -- �ُ�:2
          gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END;
      -- �������`�F�b�N
      IF (gd_inventory_date > gd_business_date) THEN
        -- �I�����������`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10197)
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcoi_sn
                     ,iv_name         => cv_msg_10197
                     );
        lv_errbuf := lv_errmsg;
        lv_retcode := cv_status_error;    -- �ُ�:2
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      END IF;
      -- �Ώۓ��ݒ�
      gd_target_date := gd_inventory_date;
    END IF;
    -- A-1-4.���O�C�����[�U���_�R�[�h���擾���܂��B
    gv_user_base := xxcoi_common_pkg.get_base_code(cn_created_by,cd_creation_date);
    --
    IF (gv_user_base IS NULL) THEN
      -- ���O�C�����[�U���_�R�[�h���o�G���[���b�Z�[�W(APP-XXCOI1-10116)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10116
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-1-5.�R���J�����g���̓p�����[�^�����O�ɏo��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcoi_sn
                    ,iv_name         => cv_msg_10094
                    ,iv_token_name1  => cv_p_token1   -- �o�͋敪
                    ,iv_token_value1 => gv_out_kbn
                    ,iv_token_name2  => cv_p_token2   -- �I���敪
                    ,iv_token_value2 => gv_inv_kbn
                    ,iv_token_name3  => cv_p_token3   -- �I����
                    ,iv_token_value3 => gv_inventory_date
                    ,iv_token_name4  => cv_p_token4   -- �I����
                    ,iv_token_value4 => gv_inventory_month
                    ,iv_token_name5  => cv_p_token5   -- ���_
                    ,iv_token_value5 => iv_base_code
                    ,iv_token_name6  => cv_p_token6   -- �q��
                    ,iv_token_value6 => iv_warehouse
                    ,iv_token_name7  => cv_p_token7   -- �a����
                    ,iv_token_value7 => iv_left_base
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    -- ���ʊ֐�(�݌ɑg�D�R�[�h�擾)���g�p���v���t�@�C�����݌ɑg�D�R�[�h���擾���܂��B
    gv_organization_code := FND_PROFILE.VALUE(cv_org_code_p);
    --
    IF (gv_organization_code IS NULL) THEN
      -- �v���t�@�C��:�݌ɑg�D�R�[�h( &PRO_TOK )�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00005
                   ,iv_token_name1  => cv_protok_sn
                   ,iv_token_value1 => cv_org_code_p
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- ��L�Ŏ擾�����݌ɑg�D�R�[�h�����Ƃɋ��ʕ��i(�݌ɑg�DID�擾)���݌ɑg�DID�擾���܂��B
    gn_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
    --
    IF (gn_organization_id IS NULL) THEN
      -- �݌ɑg�D�R�[�h( &ORG_CODE_TOK )�ɑ΂���݌ɑg�DID�̎擾�Ɏ��s���܂����B
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_00006
                   ,iv_token_name1  => cv_orgcode_sn
                   ,iv_token_value1 => gv_organization_code
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
    -- A-2-3.���_�`�F�b�N(�Ǘ��ۈȊO�K�{)
-- == 2010/04/08 V1.11 Modified START ===============================================================
--    SELECT management_base_flag                 -- �Ǘ������_�t���O
--    INTO   gv_focus_base_flag
--    FROM   xxcoi_user_base_info_v               -- ���_�r���[
--    WHERE  account_number = gv_user_base
--    AND    ROWNUM = 1;
    SELECT CASE WHEN xca.customer_code = xca.management_base_code
           THEN '1'
           ELSE '0'
           END  management_base_flag                 -- �Ǘ������_�t���O
    INTO   gv_focus_base_flag
    FROM   hz_cust_accounts     hca
          ,xxcmm_cust_accounts  xca
    WHERE  hca.account_number = gv_user_base
    AND    hca.customer_class_code = '1'
    AND    hca.status = 'A'
    AND    hca.cust_account_id = xca.customer_id
    ;
-- == 2010/04/08 V1.11 Modified END   ===============================================================
    --
    IF (gv_focus_base_flag <> '1' AND iv_base_code IS NULL) THEN
      -- ���_�R�[�hNull�`�F�b�N�G���[���b�Z�[�W(APP-XXCOI1-10115)
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcoi_sn
                   ,iv_name         => cv_msg_10115
                   );
      lv_errbuf := lv_errmsg;
      lv_retcode := cv_status_error;    -- �ُ�:2
      gn_error_cnt := gn_error_cnt + 1;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_output_kbn         IN  VARCHAR2,     -- �o�͋敪
    iv_inventory_kbn      IN  VARCHAR2,     -- �I���敪
    iv_inventory_date     IN  VARCHAR2,     -- �I����
    iv_inventory_month    IN  VARCHAR2,     -- �I����
    iv_base_code          IN  VARCHAR2,     -- ���_
    iv_warehouse          IN  VARCHAR2,     -- �q��
    iv_left_base          IN  VARCHAR2,     -- �a����
    ov_errbuf             OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_inv_name          VARCHAR2(200) := NULL;   -- �I���ꏊ��
    lv_base_code         VARCHAR2(200) := NULL;   -- ���_�R�[�h
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
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(init)
    -- ===============================
    init(
      iv_output_kbn      => iv_output_kbn         -- �o�͋敪
     ,iv_inventory_kbn   => iv_inventory_kbn      -- �I���敪
     ,iv_inventory_date  => iv_inventory_date     -- �I����
     ,iv_inventory_month => iv_inventory_month    -- �I����
     ,iv_base_code       => iv_base_code          -- ���_
     ,iv_warehouse       => iv_warehouse          -- �q��
     ,iv_left_base       => iv_left_base          -- �a����
     ,ov_errbuf          => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      ov_retcode := lv_retcode;
    END IF;
--
    -- ===============================
    -- �f�[�^�擾(A-3)
    -- ===============================
    IF (iv_inventory_kbn = cv_inv_kbn1) THEN
      -- �����f�[�^�擾
      get_daily_data(
        iv_output_kbn      => iv_output_kbn         -- �o�͋敪
       ,iv_inventory_kbn   => iv_inventory_kbn      -- �I���敪
       ,iv_inventory_date  => iv_inventory_date     -- �I����
       ,iv_inventory_month => iv_inventory_month    -- �I����
       ,iv_base_code       => iv_base_code          -- ���_
       ,iv_warehouse       => iv_warehouse          -- �q��
       ,iv_left_base       => iv_left_base          -- �a����
       ,ov_errbuf          => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    ELSE
      -- �����f�[�^�擾
      get_month_data(
        iv_output_kbn      => iv_output_kbn         -- �o�͋敪
       ,iv_inventory_kbn   => iv_inventory_kbn      -- �I���敪
       ,iv_inventory_date  => iv_inventory_date     -- �I����
       ,iv_inventory_month => iv_inventory_month    -- �I����
       ,iv_base_code       => iv_base_code          -- ���_
       ,iv_warehouse       => iv_warehouse          -- �q��
       ,iv_left_base       => iv_left_base          -- �a����
       ,ov_errbuf          => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode         => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg          => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      ov_retcode := lv_retcode;
    END IF;
    -- ===============================
    -- SVF�N���������ďo��(final_svf)
    -- ===============================
    final_svf(
        ov_errbuf  => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg  => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --�x������
      ov_retcode := lv_retcode;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    errbuf             OUT VARCHAR2,     -- �G���[���b�Z�[�W #�Œ�#
    retcode            OUT VARCHAR2,     -- �G���[�R�[�h     #�Œ�#
    iv_output_kbn      IN  VARCHAR2,     -- �o�͋敪
    iv_inventory_kbn   IN  VARCHAR2,     -- �I���敪
    iv_inventory_date  IN  VARCHAR2,     -- �I����
    iv_inventory_month IN  VARCHAR2,     -- �I����
    iv_base_code       IN  VARCHAR2,     -- ���_
    iv_warehouse       IN  VARCHAR2,     -- �q��
    iv_left_base       IN  VARCHAR2      -- �a����
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- �v���O������
    cv_log_name        CONSTANT VARCHAR2(100) := 'LOG';               -- �w�b�_���b�Z�[�W�o�͊֐��p�����[�^
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- �G���[�I���S���[���o�b�N
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);     -- �G���[�E���b�Z�[�W
    lv_retcode                VARCHAR2(1);        -- ���^�[���E�R�[�h
    lv_errmsg                 VARCHAR2(5000);     -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code           VARCHAR2(100);
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log_name
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
    -- submain�̌Ăяo��(���ۂ̏�����submain�ōs��)
    -- ===============================================
    submain(
       iv_output_kbn      => iv_output_kbn        -- �o�͋敪
      ,iv_inventory_kbn   => iv_inventory_kbn     -- �I���敪
-- == 2009/07/22 V1.4 Modified START ===============================================================
--      ,iv_inventory_date  => iv_inventory_date    -- �I����
      ,iv_inventory_date  => REPLACE(SUBSTRB(iv_inventory_date, 1, 10), cv_replace_sign)    -- �I����
-- == 2009/07/22 V1.4 Modified END   ===============================================================

      ,iv_inventory_month => iv_inventory_month   -- �I����
      ,iv_base_code       => iv_base_code         -- ���_
      ,iv_warehouse       => iv_warehouse         -- �q��
      ,iv_left_base       => iv_left_base         -- �a����
      ,ov_errbuf          => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode         => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg          => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
END XXCOI006A15R;
/
